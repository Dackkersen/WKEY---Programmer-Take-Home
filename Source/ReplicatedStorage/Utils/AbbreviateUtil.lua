local AbbreviateModule = {}

-- Ordered suffixes by 10^(3*n).
-- n=1 -> K (10^3), n=2 -> M (10^6), n=3 -> B (10^9), etc.
AbbreviateModule.Suffixes = {
	"K",
	"M",
	"B",
	"T",
	"Qua",
	"Qui",
	"Se",
	"Sep",
	"Oct",
	"Non",
	"Dec",
	"Und",
	"Duo",
	"Tre",
	"Quattd",
	"Quin",
	"Sed",
	"Sept",
	"Octo",
	"Nove",
	"Vigi",
	"Unvig",
	"Duov",
	"Tresv",
	"Quattv",
	"Quinv",
	"Ses",
	"Septe",
	"Octov",
	"Novev",
	"Tri",
	"Unt",
	"Duot",
	"Goo",
}

local function trimTrailingZeros(s: string): string
	-- "1.0" -> "1", "1.20" -> "1.2"
	return (s:gsub("%.?0+$", ""))
end

function AbbreviateModule:AbbreviateNumbers(x)
	if typeof(x) ~= "number" then
		return nil
	end
	if x ~= x then
		return "NaN"
	end
	if x == math.huge then
		return "Inf"
	elseif x == -math.huge then
		return "-Inf"
	end

	local sign = ""
	if x < 0 then
		sign = "-"
		x = -x
	end

	-- No abbreviation
	if x < 1000 then
		-- choose whether you want decimals here; most games prefer whole numbers
		return sign .. tostring(math.floor(x + 0.5))
	end

	-- Determine tier: 1 for K, 2 for M, ...
	local tier = math.floor(math.log10(x) / 3) -- 0 for <1e3, 1 for >=1e3, etc.

	-- Clamp tier to suffix list length
	local maxTier = #self.Suffixes
	local clampedTier = math.min(tier, maxTier)

	local divisor = 10 ^ (3 * clampedTier)
	local value = x / divisor

	-- Handle rounding that would push 999.95K -> 1000.0K (should become 1.0M)
	-- We'll round to 1 decimal, then if it's >= 1000 bump tier up (if possible).
	local rounded = tonumber(string.format("%.1f", value)) or value
	if rounded >= 1000 and clampedTier < maxTier then
		clampedTier += 1
		divisor = 10 ^ (3 * clampedTier)
		value = x / divisor
	end

	-- Final format: 1 decimal, but drop ".0"
	local formatted = trimTrailingZeros(string.format("%.1f", value))

	local suffix = self.Suffixes[clampedTier]
	if suffix then
		return sign .. formatted .. suffix
	end

	-- Fallback if beyond list (shouldn't happen due to clamp, but safe)
	return sign .. formatted .. "e" .. tostring(3 * clampedTier)
end

return AbbreviateModule
