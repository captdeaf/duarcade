local EC_LAND = {
    name = "Land Ship",
    desc = [[
1) Shut off all thrust engines. Turn on all brakes.<br>
2) Stabilize pitch and Roll to 0.<br>
3) Extend landing gears.<br>
4) Lower Altitude Stabilization to zero.<br>
5) Shut down altitude stabilizers.
]],
    override = false
}

EC_LAND.start = function()
    -- BRAKE ALL THE THINGS, but only if speed is low. If we are going fast, we
    -- may be coasting.

    EC_LAND.stage = "stabilize"
    SHIP.killEngines()
end

EC_LAND.resume = function()
    EC_LAND.stage = "done"
    SHIP.unhover()
end

EC_LAND.stop = function()
end

EC_LAND.flush = function(secs)
    if EC_LAND.stage ~= "done" then
        SHIP.stabilize()
    else
        SHIP.killEngines()
        SHIP.unhover()
    end
    if math.abs(PHYSICS.constructVelocitySpeed) > 0.2 then
        SHIP.brake()
    end
    if EC_LAND.stage == "stabilize" then
        if
            math.abs(PHYSICS.getRotationDiff(PHYSICS.currentPitchDeg, 0)) < 2.0 and
                math.abs(PHYSICS.getRotationDiff(PHYSICS.currentRollDeg, 0)) < 2.0
         then
            SHIP.extendLandingGears()
            EC_LAND.stage = "extend"
            EC_LAND.timer = 0.0
        end
    end
    if EC_LAND.stage == "extend" then
        EC_LAND.timer = EC_LAND.timer + secs
        if EC_LAND.timer > 3.0 then
            system.print("extended")
            EC_LAND.stage = "lower"
            EC_LAND.timer = 0
            SHIP.hover(1.0)
        end
    end
    if EC_LAND.stage == "lower" then
        if math.abs(PHYSICS.constructVelocitySpeed) < 0.4 then
            system.print("lowered, finished")
            EC_LAND.stage = "done"
            SHIP.killEngines()
            SHIP.unhover()
            clearEngineCommand()
        end
    end
end

CommandSelect.add(EC_LAND)
