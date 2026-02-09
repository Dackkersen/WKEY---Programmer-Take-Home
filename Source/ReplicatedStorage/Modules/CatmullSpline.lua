local CatmullSpline = {}
CatmullSpline.__index = CatmullSpline

export type Spline = {
	Points: { Vector3 },
	Alpha: number,
	Closed: boolean,
	SegmentLengths: { number },
	TotalLength: number,
}

local function toNumberName(inst: Instance): number?
	local n = tonumber(inst.Name)
	return n
end

local function getOrderedPoints(pathFolder: Instance): { Vector3 }
	assert(pathFolder and pathFolder:IsA("Folder"), "CatmullSpline.new expects a Folder")

	local numbered: { [number]: Vector3 } = {}
	local maxIndex = 0

	for _, child in ipairs(pathFolder:GetChildren()) do
		if child:IsA("BasePart") then
			local idx = toNumberName(child)
			if idx then
				numbered[idx] = child.Position
				if idx > maxIndex then
					maxIndex = idx
				end
			end
		end
	end

	assert(maxIndex >= 2, "Path folder must contain at least 2 numbered parts (1..X)")

	local points: { Vector3 } = {}
	for i = 1, maxIndex do
		local p = numbered[i]
		assert(p ~= nil, ("Missing path point part named '%d'"):format(i))
		table.insert(points, p)
	end

	return points
end

-- Uniform Catmull-Rom basis (alpha parameter affects parameterization; we keep it for future extension)
local function catmullRom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	-- Standard Catmull-Rom (t in [0,1])
	local t2 = t * t
	local t3 = t2 * t

	return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
end

local function catmullRomTangent(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	-- Derivative of standard Catmull-Rom
	local t2 = t * t
	return 0.5 * ((-p0 + p2) + 2 * (2 * p0 - 5 * p1 + 4 * p2 - p3) * t + 3 * (-p0 + 3 * p1 - 3 * p2 + p3) * t2)
end

local function clamp01(x: number): number
	if x < 0 then
		return 0
	end
	if x > 1 then
		return 1
	end
	return x
end

local function buildArcLengthTable(
	points: { Vector3 },
	closed: boolean,
	samplesPerSegment: number
): ({ number }, number)
	-- Approximates length per segment by sampling.
	samplesPerSegment = math.max(5, samplesPerSegment)

	local n = #points
	local segmentCount = closed and n or (n - 1)
	local segLengths: { number } = table.create(segmentCount, 0)
	local total = 0

	for seg = 1, segmentCount do
		local i1 = seg
		local i2 = (seg % n) + 1

		local p1 = points[i1]
		local p2 = points[i2]
		local p0 = points[(i1 - 2) % n + 1] -- i1-1
		local p3 = points[i2 % n + 1] -- i2+1

		-- For open splines, clamp the endpoints by duplicating
		if not closed then
			p0 = (i1 == 1) and p1 or points[i1 - 1]
			p3 = (i2 == n) and p2 or points[i2 + 1]
		end

		local last = catmullRom(p0, p1, p2, p3, 0)
		local segLen = 0
		for s = 1, samplesPerSegment do
			local t = s / samplesPerSegment
			local cur = catmullRom(p0, p1, p2, p3, t)
			segLen += (cur - last).Magnitude
			last = cur
		end

		segLengths[seg] = segLen
		total += segLen
	end

	return segLengths, total
end

-- Public API

function CatmullSpline.new(
	pathFolder: Instance,
	opts: { Closed: boolean?, SamplesPerSegment: number?, Alpha: number? }?
): Spline
	opts = opts or {}
	local closed = opts.Closed == true
	local samplesPerSegment = opts.SamplesPerSegment or 20

	local points = getOrderedPoints(pathFolder)
	local segLengths, totalLen = buildArcLengthTable(points, closed, samplesPerSegment)

	local self: any = setmetatable({}, CatmullSpline)
	self.Points = points
	self.Closed = closed
	self.Alpha = opts.Alpha or 0.5
	self.SegmentLengths = segLengths
	self.TotalLength = totalLen

	return self
end

function CatmullSpline:GetPointCount(): number
	return #self.Points
end

function CatmullSpline:GetLength(): number
	return self.TotalLength
end

function CatmullSpline:GetPositionAtDistance(distance: number): Vector3
	-- Clamp distance to path bounds
	if distance < 0 then
		distance = 0
	end
	if distance > self.TotalLength then
		distance = self.TotalLength
	end

	local n = #self.Points
	local segmentCount = self.Closed and n or (n - 1)

	-- Find which segment this distance lands in
	local distSoFar = 0
	local seg = 1
	for i = 1, segmentCount do
		local len = self.SegmentLengths[i]
		if distSoFar + len >= distance then
			seg = i
			break
		end
		distSoFar += len
	end

	local segLen = self.SegmentLengths[seg]
	local localT = (segLen > 0) and ((distance - distSoFar) / segLen) or 0

	-- Resolve control points for this segment
	local i1 = seg
	local i2 = (seg % n) + 1

	local p1 = self.Points[i1]
	local p2 = self.Points[i2]
	local p0 = self.Points[(i1 - 2) % n + 1]
	local p3 = self.Points[i2 % n + 1]

	if not self.Closed then
		p0 = (i1 == 1) and p1 or self.Points[i1 - 1]
		p3 = (i2 == n) and p2 or self.Points[i2 + 1]
	end

	return catmullRom(p0, p1, p2, p3, localT)
end

function CatmullSpline:GetPosition(t: number): Vector3
	t = clamp01(t)

	local n = #self.Points
	local segmentCount = self.Closed and n or (n - 1)

	-- Map normalized t onto segments by arc-length so speed feels even.
	local targetDist = t * self.TotalLength
	local dist = 0
	local seg = 1

	for i = 1, segmentCount do
		local len = self.SegmentLengths[i]
		if dist + len >= targetDist then
			seg = i
			break
		end
		dist += len
	end

	local segLen = self.SegmentLengths[seg]
	local localT = (segLen > 0) and ((targetDist - dist) / segLen) or 0

	local i1 = seg
	local i2 = (seg % n) + 1

	local p1 = self.Points[i1]
	local p2 = self.Points[i2]
	local p0 = self.Points[(i1 - 2) % n + 1]
	local p3 = self.Points[i2 % n + 1]

	if not self.Closed then
		p0 = (i1 == 1) and p1 or self.Points[i1 - 1]
		p3 = (i2 == n) and p2 or self.Points[i2 + 1]
	end

	return catmullRom(p0, p1, p2, p3, localT)
end

function CatmullSpline:GetTangent(t: number): Vector3
	t = clamp01(t)

	local n = #self.Points
	local segmentCount = self.Closed and n or (n - 1)

	local targetDist = t * self.TotalLength
	local dist = 0
	local seg = 1

	for i = 1, segmentCount do
		local len = self.SegmentLengths[i]
		if dist + len >= targetDist then
			seg = i
			break
		end
		dist += len
	end

	local segLen = self.SegmentLengths[seg]
	local localT = (segLen > 0) and ((targetDist - dist) / segLen) or 0

	local i1 = seg
	local i2 = (seg % n) + 1

	local p1 = self.Points[i1]
	local p2 = self.Points[i2]
	local p0 = self.Points[(i1 - 2) % n + 1]
	local p3 = self.Points[i2 % n + 1]

	if not self.Closed then
		p0 = (i1 == 1) and p1 or self.Points[i1 - 1]
		p3 = (i2 == n) and p2 or self.Points[i2 + 1]
	end

	local tan = catmullRomTangent(p0, p1, p2, p3, localT)
	if tan.Magnitude < 1e-6 then
		return Vector3.new(0, 0, -1)
	end
	return tan.Unit
end

function CatmullSpline:GetCFrame(t: number, up: Vector3?): CFrame
	local pos = self:GetPosition(t)
	local look = self:GetTangent(t)
	up = up or Vector3.yAxis

	-- Handle near-parallel up/look by picking a fallback up
	if math.abs(look:Dot(up)) > 0.999 then
		up = Vector3.xAxis
	end

	return CFrame.lookAt(pos, pos + look, up)
end

function CatmullSpline:GetCFrameAtDistance(distance: number, up: Vector3?): CFrame
	local pos = self:GetPositionAtDistance(distance)

	-- Sample slightly ahead to approximate tangent
	local eps = 0.05
	local pos2 = self:GetPositionAtDistance(math.min(distance + eps, self.TotalLength))
	local look = (pos2 - pos)

	if look.Magnitude < 1e-6 then
		look = Vector3.new(0, 0, -1)
	else
		look = look.Unit
	end

	up = up or Vector3.yAxis
	if math.abs(look:Dot(up)) > 0.999 then
		up = Vector3.xAxis
	end

	return CFrame.lookAt(pos, pos + look, up)
end

function CatmullSpline:SamplePositions(sampleCount: number): { Vector3 }
	sampleCount = math.max(2, sampleCount)
	local out: { Vector3 } = table.create(sampleCount)

	for i = 0, sampleCount - 1 do
		local t = i / (sampleCount - 1)
		out[i + 1] = self:GetPosition(t)
	end

	return out
end

function CatmullSpline:DebugDraw(parent: Instance?, sampleCount: number?, radius: number?): { BasePart }
	-- Creates small anchored parts along the curve
	parent = parent or workspace
	sampleCount = sampleCount or 50
	radius = radius or 0.3

	local pts = self:SamplePositions(sampleCount)
	local created: { BasePart } = {}

	for _, p in ipairs(pts) do
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(radius, radius, radius)
		part.Position = p
		part.Parent = parent
		table.insert(created, part)
	end

	return created
end

return CatmullSpline
