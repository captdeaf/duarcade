-- Autopilot Information Display
-- To display a lot of debug information related to autopilot

local HUDAutopilot = {
    name = "Autopilot Infopanel",
    key = "autopilotpanel",
    opts = {
        enabled = false,
        posX = 50,
        posY = 200
    },
    config = {
        posX = {
            min = 0,
            default = 50,
            max = SCREEN_X,
            datatype = "int",
            uihandler = HUDUI.IntHandler,
            name = "Position X",
            step = 20
        },
        posY = {
            min = 0,
            default = 200,
            max = SCREEN_Y,
            datatype = "int",
            uihandler = HUDUI.IntHandler,
            name = "Position Y",
            step = 20
        }
    }
}

function HUDAutopilot.addData(data, name, val)
    table.insert(data, el("tr", {}, {
        el("td", {}, name),
        el("th", {}, val),
    }))
end

HUDAutopilot.style = [[<style>
    table.ap { display: block; position: fixed; font-size: 120%; }
    table.ap td { width: 4vw; height: 1vh; text-align: left; }
    table.ap th { width: 6vw; height: 1vh; text-align: right; }
</style>]]

function HUDAutopilot.render()
    local data = {}
    if MainScreen.destination and MainScreen.destination.position then
	HUDAutopilot.addData(data, "Destination", MainScreen.destination.name)
        local dpos = vec3(MainScreen.destination.position)
	local sbody = DU.getNearestBody(PHYSICS.position)
	local dbody = DU.getNearestBody(dpos)
	HUDAutopilot.addData(data, "Location", sbody.name)
	if sbody.name ~= dbody.name then
	    HUDAutopilot.addData(data, "Target Body", dbody.name)
	end
    end
    if not PHYSICS.inAtmo then
	HUDAutopilot.addData(data, "Brake Dist", Render.distance(PHYSICS.brakeDistance))
	HUDAutopilot.addData(data, "Brake Time", Render.time(PHYSICS.brakeTime))
    end
    return HUDAutopilot.style .. el("table",
        {
            style = string.format(
                "left: %dpx; top: %dpx;",
                HUDAutopilot.opts.posX,
                HUDAutopilot.opts.posY
            ),
	    class = "ap",
        },
        data
    )
end

HUDConfig.addHUD(HUDAutopilot)
