local SCREEN_X = 1920
local SCREEN_Y = 1080

function ischild(tbl)
    if type(tbl) == 'string' then
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
            k = k:gsub("%u", function(c) return '-' .. c:lower() end)
            attrvals = attrvals .. " " .. k .. '="' .. v .. '"'
        end
    end
    if type(children) == 'string' then
        return string.format("<%s%s>%s</%s>", name, attrvals, children, name)
    elseif type(children) == 'table' then
        return string.format("<%s%s>%s</%s>", name, attrvals, table.concat(children,"\n"), name)
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
