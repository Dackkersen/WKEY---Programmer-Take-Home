-- Easing.lua
-- Standard easing functions matching Roblox EasingStyles
-- Usage: local easedT = Easing.InOutQuad(t)

local Easing = {}

-- Linear
function Easing.Linear(t)
    return t
end

-- Sine
function Easing.InSine(t)
    return 1 - math.cos((t * math.pi) / 2)
end

function Easing.OutSine(t)
    return math.sin((t * math.pi) / 2)
end

function Easing.InOutSine(t)
    return -(math.cos(math.pi * t) - 1) / 2
end

-- Quad
function Easing.InQuad(t)
    return t * t
end

function Easing.OutQuad(t)
    return 1 - (1 - t)^2
end

function Easing.InOutQuad(t)
    return if t < 0.5
        then 2 * t * t
        else 1 - (-2 * t + 2)^2 / 2
end

-- Cubic
function Easing.InCubic(t)
    return t ^ 3
end

function Easing.OutCubic(t)
    return 1 - (1 - t)^3
end

function Easing.InOutCubic(t)
    return if t < 0.5
        then 4 * t^3
        else 1 - (-2 * t + 2)^3 / 2
end

-- Quart
function Easing.InQuart(t)
    return t ^ 4
end

function Easing.OutQuart(t)
    return 1 - (1 - t)^4
end

function Easing.InOutQuart(t)
    return if t < 0.5
        then 8 * t^4
        else 1 - (-2 * t + 2)^4 / 2
end

-- Quint
function Easing.InQuint(t)
    return t ^ 5
end

function Easing.OutQuint(t)
    return 1 - (1 - t)^5
end

function Easing.InOutQuint(t)
    return if t < 0.5
        then 16 * t^5
        else 1 - (-2 * t + 2)^5 / 2
end

-- Expo
function Easing.InExpo(t)
    return if t == 0 then 0 else 2^(10 * (t - 1))
end

function Easing.OutExpo(t)
    return if t == 1 then 1 else 1 - 2^(-10 * t)
end

function Easing.InOutExpo(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    if t < 0.5 then
        return 2^(20 * t - 10) / 2
    else
        return (2 - 2^(-20 * t + 10)) / 2
    end
end

-- Circ
function Easing.InCirc(t)
    return 1 - math.sqrt(1 - t * t)
end

function Easing.OutCirc(t)
    return math.sqrt(1 - (t - 1)^2)
end

function Easing.InOutCirc(t)
    if t < 0.5 then
        return (1 - math.sqrt(1 - (2 * t)^2)) / 2
    else
        return (math.sqrt(1 - (-2 * t + 2)^2) + 1) / 2
    end
end

return Easing