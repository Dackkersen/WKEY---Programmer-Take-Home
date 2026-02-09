--[[
    createViewportPreview(
        viewport: ViewportFrame,
        source: Model | BasePart,
        options: table? -- optional
    ) -> controller

    controller fields / methods:
        controller.Camera      :: Camera
        controller.Model       :: Model (clone inside the viewport)
        controller:SetRotation(rotationCFrame: CFrame)
        controller:SetOffset(offsetCFrame: CFrame)
        controller:SetDistance(multiplier: number)
        controller:SetBaseCFrame(cf: CFrame) -- if you want to pivot around a new center
        controller:Destroy()
]]

local function createViewportPreview(viewport, source, options)
	options = options or {}

	local fov = options.FOV or 40
	local initialRotation = options.Rotation or CFrame.new()
	local distanceMult = options.DistanceMultiplier or 1

	-- Create camera for this viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = fov
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	----------------------------------------------------------------
	-- Clone object into a model in the viewport
	----------------------------------------------------------------
	local newModel

	if source:IsA("Model") then
		newModel = source:Clone()
	elseif source:IsA("BasePart") then
		newModel = Instance.new("Model")
		local partClone = source:Clone()
		partClone.Parent = newModel
	else
		error("createViewportPreview: 'source' must be a Model or BasePart")
	end

	newModel.Parent = viewport

	----------------------------------------------------------------
	-- Compute bounding box and ideal camera distance
	----------------------------------------------------------------
	local bboxCFrame, size = newModel:GetBoundingBox()

	-- Use the largest dimension to compute a "radius" that fits in view
	local maxSize = math.max(size.X, size.Y, size.Z)
	local radius = maxSize / 2

	-- Distance from center to camera based on FOV
	local distance = (radius / math.tan(math.rad(fov / 2))) * distanceMult

	----------------------------------------------------------------
	-- Controller object
	----------------------------------------------------------------
	local controller = {
		Camera = camera,
		Model = newModel,
		_baseCf = bboxCFrame, -- center of the model
		_dist = distance,
		_rot = initialRotation, -- rotation around the model
		_offset = CFrame.new(), -- extra offset for fine tuning
	}

	local function updateCamera()
		-- Camera looks at the model center (_baseCf), then gets rotated and pushed back
		controller.Camera.CFrame = controller._baseCf
			* controller._rot
			* CFrame.new(0, 0, controller._dist)
			* controller._offset

		controller.Camera.Focus = controller._baseCf
	end

	function controller:SetRotation(rotCf)
		self._rot = rotCf or CFrame.new()
		updateCamera()
	end

	-- Offset can be used to “slide” the camera around after the rotation
	function controller:SetOffset(offsetCf)
		self._offset = offsetCf or CFrame.new()
		updateCamera()
	end

	-- Adjust how far the camera is from the model
	function controller:SetDistance(multiplier)
		multiplier = multiplier or 1
		self._dist = distance * multiplier
		updateCamera()
	end

	-- If you want to pivot around something else later
	function controller:SetBaseCFrame(cf)
		self._baseCf = cf
		updateCamera()
	end

	function controller:Destroy()
		if viewport.CurrentCamera == self.Camera then
			viewport.CurrentCamera = nil
		end
		if self.Camera then
			self.Camera:Destroy()
		end
		if self.Model then
			self.Model:Destroy()
		end
		-- optional cleanup
		for k in pairs(self) do
			self[k] = nil
		end
	end

	-- Initial position
	updateCamera()

	return controller
end

return createViewportPreview
