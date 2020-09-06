local SCREEN_X = 1920
local SCREEN_Y = 1080

function svg(name, params, children)
    local attrvals = ""
    if params then
        for k, v in pairs(params) do
            k = k:gsub("%u", function(c) return '-' .. c:lower() end)
            attrvals = attrvals .. " " .. k .. '="' .. v .. '"'
        end
    end
    if children then
        return string.format("<%s%s>%s</%s>", name, attrvals, table.concat(children,"\n"), name)
    else
        return string.format("<%s%s />", name, attrvals)
    end
end

screen.activate()
system.lockView(1)

Renderer = {}
Renderer.DRAWS = {}
function addDraw(s)
    Renderer.DRAWS[#Renderer.DRAWS+1] = s
end
function Renderer.draw(scene, secs)
    Renderer.DRAWS = {}
    if scene.update then
        scene.update(secs)
    end
    if scene.render then
        scene.render()
    end
    screen.setSVG(svg("g", nil, Renderer.DRAWS))
end
function Renderer.debug()
    local x = table.concat(Renderer.DRAWS, '')
    system.print(string.gsub(string.gsub(x, "<", "("), ">", ")"))
end
