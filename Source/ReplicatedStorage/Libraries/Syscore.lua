local RunService = game:GetService("RunService")

local INIT_FUNCTION_NAME = "Init"
local METHOD_TIMEOUT_SECONDS = 5

export type Syscore = {
	Icon: string?,
	Name: string,
	Priority: number,
	[any]: any,
}

local addedModules: { { moduleScript: ModuleScript, sysModule: Syscore?, failedOnce: boolean } } = {}
local errors: { [string]: { { sysModule: Syscore, response: string } } } = {}
local isInitialized = false

local Syscore = {
	ShowLoadOrder = true,
	LoadTime = nil,
}

local function runWithTimeout(func: () -> any, timeout: number): (boolean, any)
	local result
	local errorMessage
	local done = false
	local timeoutFired = false

	local timeoutThread = task.delay(timeout, function()
		timeoutFired = true
	end)

	task.spawn(function()
		local success, res = pcall(func)
		if not success then
			errorMessage = res
		else
			result = res
		end
		done = true
	end)

	while not done and not timeoutFired do
		task.wait()
	end

	if timeoutThread then
		task.cancel(timeoutThread)
	end

	if timeoutFired then
		return false, `took more than {timeout} seconds to complete (timeout)`
	elseif errorMessage then
		return false, errorMessage
	else
		return true, result
	end
end

local function prioritySortAddedModules()
	table.sort(addedModules, function(a, b)
		return a.sysModule.Priority < b.sysModule.Priority
	end)

	if Syscore.ShowLoadOrder then
		warn(`[Syscore] {RunService:IsServer() and "Server" or "Client"} load order:`)
		for loadOrder, data in addedModules do
			local iconString = data.sysModule.Icon and `{data.sysModule.Icon} ` or "🔴"
			warn(`[Syscore] {loadOrder} - [{iconString}{data.sysModule.Name}] :: {data.sysModule.Priority}`)
		end
	end
end

local function initializeSyscore(methodName: string)
	methodName = if typeof(methodName) == "string" then methodName else INIT_FUNCTION_NAME

	if not errors[methodName] then
		errors[methodName] = {}
	end

	-- Group modules by priority
	local priorityGroups = {}
	for _, data in addedModules do
		if data.sysModule and not data.failedOnce then
			local priority = data.sysModule.Priority
			if not priorityGroups[priority] then
				priorityGroups[priority] = {}
			end
			table.insert(priorityGroups[priority], data)
		end
	end

	-- Process each priority group in ascending order
	local sortedPriorities = {}
	for priority in pairs(priorityGroups) do
		table.insert(sortedPriorities, priority)
	end
	table.sort(sortedPriorities)

	for _, priority in sortedPriorities do
		local group = priorityGroups[priority]
		local groupCoroutines = {}

		-- Spawn Init calls for this priority group in parallel
		for _, data in group do
			local co = coroutine.create(function()
				local success, response = runWithTimeout(function()
					if typeof(data.sysModule[methodName]) == "function" then
						data.sysModule[methodName](data.sysModule)
					end
				end, METHOD_TIMEOUT_SECONDS)

				if not success then
					table.insert(errors[methodName], { sysModule = data.sysModule, response = response })
					warn(
						`[Syscore] Module {data.sysModule.Name}:{methodName} failed to initialize: {response}\n{debug.traceback()}`
					)
					data.failedOnce = true
				end
			end)
			table.insert(groupCoroutines, co)
			coroutine.resume(co)
		end

		-- Wait for all coroutines in this priority group to complete
		for _, co in groupCoroutines do
			while coroutine.status(co) ~= "dead" do
				task.wait()
			end
		end
	end
end

local function ModuleWithSameNameExists(module: ModuleScript)
	for _, data in addedModules do
		if data.moduleScript.Name == module.Name or data.moduleScript:GetFullName() == module:GetFullName() then
			warn(`[Syscore] {data.moduleScript.Name} is already in the sysModules list.`)
			return true
		end
	end

	return false
end

local function addModule(module: ModuleScript)
	if isInitialized then
		warn(`[Syscore] Cannot add {module.Name} after Syscore has started.`)
		return
	end

	if not module:IsA("ModuleScript") then
		return
	end

	if ModuleWithSameNameExists(module) then
		return
	end

	table.insert(addedModules, { moduleScript = module, sysModule = nil, failedOnce = false })
end

function Syscore.AddFolderOfModules(folder: Folder)
	assert(folder and folder:IsA("Folder"), `[Syscore] {folder.Name} is not a folder.`)

	if isInitialized then
		warn(`[Syscore] Cannot add {folder.Name} after Syscore has started.`)
		return
	end

	for _, module in folder:GetChildren() do
		addModule(module)
	end
end

function Syscore.AddModule(module: ModuleScript)
	assert(module and module:IsA("ModuleScript"), `[Syscore] {module.Name} is not a ModuleScript.`)

	if isInitialized then
		warn(`[Syscore] Cannot add {module.Name} after Syscore has started.`)
		return
	end

	addModule(module)
end

function Syscore.AddTableOfModules(modules: { ModuleScript })
	if type(modules) ~= "table" then
		error(`[Syscore] {modules} is not a table.`)
	end

	if isInitialized then
		warn(`[Syscore] Cannot add {#modules} after Syscore has started.`)
		return
	end

	for _, systemModule in modules do
		addModule(systemModule)
	end
end

function Syscore.Start(): { [string]: { { sysModule: Syscore, response: string } } }
	local runtimeStart = os.clock()

	-- Require all modules in parallel
	local loadedModules = {}
	local requireCoroutines = {}

	for _, data in addedModules do
		local co = coroutine.create(function()
			local success, response = runWithTimeout(function()
				return require(data.moduleScript)
			end, METHOD_TIMEOUT_SECONDS)

			if success then
				if typeof(response) == "table" then
					response.Icon = response.Icon or "🔴"
					response.Name = response.Name or data.moduleScript:GetFullName()
					response.Priority = response.Priority or math.huge
					table.insert(
						loadedModules,
						{ moduleScript = data.moduleScript, sysModule = response, failedOnce = false }
					)
				end
			else
				warn(
					`[Syscore] Failed to add/require "{data.moduleScript.Name}" ModuleScript: {response}\n{debug.traceback()}`
				)
			end
		end)
		table.insert(requireCoroutines, co)
		coroutine.resume(co)
	end

	-- Wait for all require coroutines to complete
	for _, co in requireCoroutines do
		while coroutine.status(co) ~= "dead" do
			task.wait()
		end
	end

	addedModules = loadedModules

	prioritySortAddedModules()

	initializeSyscore(INIT_FUNCTION_NAME)

	for methodName, methodErrorGroup in errors do
		if #methodErrorGroup > 0 then
			for _, errorMessage in methodErrorGroup do
				warn(
					`[Syscore] {errorMessage.sysModule.Name}:{methodName} failed to initialize: {errorMessage.response}`
				)
			end
		end
	end

	local loadTime = os.clock() - runtimeStart
	if Syscore.ShowLoadOrder then
		warn(
			`[Syscore] {RunService:IsClient() and "Client" or "Server"} Modules loaded in {string.format(
				"%.6f",
				loadTime
			)} seconds`
		)
		Syscore.LoadTime = loadTime
	end

	isInitialized = true

	return errors
end

return Syscore
