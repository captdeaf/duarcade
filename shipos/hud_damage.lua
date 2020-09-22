-- Damaged element display. Only visible with damage
-- To display a lot of debug information related to autopilot

local HUDDamage = {
    name = "Damage Display",
    key = "damagepanel",
    opts = {
        enabled = true,
        posX = 50,
        posY = 600
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
            default = 600,
            max = SCREEN_Y,
            datatype = "int",
            uihandler = HUDUI.IntHandler,
            name = "Position Y",
            step = 20
        }
    }
}


function HUDDamage.check()
    local uids = core.getElementIdList()

    local damaged = {}
    for _, uid in ipairs(uids) do
        local max = core.getElementMaxHitPointsById(uid)
        local cur = core.getElementHitPointsById(uid)
        if cur < max then
            table.insert(damaged, {core.getElementNameById(uid), cur, max})
        end
    end
    return damaged
end

function HUDDamage.addData(data, name, val)
    table.insert(data, el("tr", {}, {
        el("td", {}, name),
        el("th", {}, val),
    }))
end

HUDDamage.style = [[<style>
    table.dam { display: block; position: fixed; width: 9vw; font-size: 150%; }
    table.dam th { width: 3vw; height: 1vh; text-align: right; color: red; }
    table.dam td { width: 5vw; height: 1vh; text-align: left; }
</style>]]

function HUDDamage.render()
    local data = {}
    local damaged = HUDDamage.check()
    if #damaged < 1 then
	HUDDamage.addData(data, "All Systems", "OKAY")
    else
        for _, e in ipairs(damaged) do
	    if e[2] == 0 then
		HUDDamage.addData(data, e[1], "Broken")
	    else
		HUDDamage.addData(data, e[1], string.format("%d/%d", math.floor(e[2]), math.floor(e[3])))
	    end
	end
    end
    return HUDDamage.style .. el("table",
        {
            style = string.format(
                "left: %dpx; top: %dpx;",
                HUDDamage.opts.posX,
                HUDDamage.opts.posY
            ),
	    class = "dam",
        },
        data
    )
end

HUDConfig.addHUD(HUDDamage)
