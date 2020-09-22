function checkElements()
    local uids = core.getElementIdList()

    local damaged = {}
    for _, uid in ipairs(uids) do
        local max = core.getElementMaxHitPointsById(uid)
        local cur = core.getElementHitPointsById(uid)
        if cur < max then
            table.insert(damaged, string.format("%.5d/%.5d %s", math.floor(cur), math.floor(max), core.getElementName(uid)))
        end
    end

    if #damaged < 1 then
        screen.setHTML([[
        <div style="font-size: 400%; padding: 2vw;">
        <h2 style="color: green; font-size: 100%;">All systems okay</h2><br>
        </div>
        ]])
    else
        screen.setHTML([[
        <div style="font-size: 400%; padding: 2vw;">
        <h2 style="color: red; font-size: 100%;">Alert: Element Damage</h2><br>
        ]] .. table.concat(damaged, '<br>') .. "</div>")
    end
end

-- And run it for the first time:
checkElements()
