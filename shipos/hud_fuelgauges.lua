-- Compact fuel gauges
-- To replace the big ol' ugly widget.

local HUDFuelGauges = {
    name = "Compact Fuel Gauges",
    key = "compactfuel",
    opts = {
        enabled = false,
        posX = 50,
        posY = 50
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
            default = 50,
            max = SCREEN_Y,
            datatype = "int",
            uihandler = HUDUI.IntHandler,
            name = "Position Y",
            step = 20
        }
    }
}

HUDFuelGauges.COLORS = {
    atmo = "#ccccff",
    space = "yellow",
    rocket = "red"
}

function HUDFuelGauges.renderTank(ft, tank, i)
    local color = HUDFuelGauges.COLORS[ft]
    local dat = json.decode(tank.getData())
    return el(
        "g",
        {
            el("rect", {y = i * 30, width = 100, height = 20, fill = "#00000000", stroke = color, rx = 2}),
            el("rect", {y = i * 30, width = (dat.percentage), height = 20, fill = color, rx = 2})
        }
    )
end

function HUDFuelGauges.render()
    local tanklist = {}
    for _, fueltype in pairs({"atmo", "space", "rocket"}) do
        local tanks = _G.fueltanks[fueltype]
        if tanks and #tanks > 0 then
            for _, tank in ipairs(tanks) do
                table.insert(tanklist, HUDFuelGauges.renderTank(fueltype, tank, #tanklist))
            end
        end
    end
    return el(
        "svg",
        {
            style = string.format(
                "display: block; position: fixed; left: %d; top: %d;",
                HUDFuelGauges.opts.posX,
                HUDFuelGauges.opts.posY
            )
        },
        tanklist
    )
end

HUDConfig.addHUD(HUDFuelGauges)
