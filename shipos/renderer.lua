local SCREEN_X = 1920
local SCREEN_Y = 1080

function ischild(tbl)
    if type(tbl) == "string" then
        return true
    end
    -- Or if it has array-style indexes.
    for i, _ in ipairs(tbl) do
        return true
    end
    return false
end

function el(name, params, children)
    local attrvals = ""
    if ischild(params) then
        children = params
    elseif params then
        for k, v in pairs(params) do
            k =
                k:gsub(
                "%u",
                function(c)
                    return "-" .. c:lower()
                end
            )
            attrvals = attrvals .. " " .. k .. '="' .. v .. '"'
        end
    end
    if type(children) == "string" then
        return string.format("<%s%s>%s</%s>", name, attrvals, children, name)
    elseif type(children) == "table" then
        return string.format("<%s%s>%s</%s>", name, attrvals, table.concat(children, "\n"), name)
    else
        return string.format("<%s%s />", name, attrvals)
    end
end

lastarg = ""
function eldebug(arg)
    if arg ~= lastarg then
        system.print(string.gsub(string.gsub(arg, "<", "("), ">", ")"))
        lastarg = arg
    end
    return arg
end

local Render = {}

Render.distance = function(meters)
    meters = math.floor(meters)
    if meters < 10000 then
        return string.format("%dm", meters)
    elseif meters < 250000 then
        return string.format("%dkm", math.floor(meters / 1000))
    else
        return string.format("%dsu", math.floor(meters / 200000))
    end
end

Render.time = function(secs)
    local sign = ''
    if secs < 0 then
        sign = '-'
    end
    secs = math.abs(secs)
    local days = math.floor(secs / 86400)
    secs = secs % 86400
    local hours = math.floor(secs / 3600)
    secs = secs % 3600
    local minutes = math.floor(secs / 60)
    secs = math.floor(secs % 60)
    if days > 0 then
        return string.format("%s%dd %.2dh", sign, days, hours)
    elseif hours > 0 then
        return string.format("%s%dh %.2dm", sign, hours, minutes)
    elseif minutes > 0 then
        return string.format("%s%dm %.2ds", sign, minutes, secs)
    else
        return string.format("%s%ds", sign, secs)
    end
end
