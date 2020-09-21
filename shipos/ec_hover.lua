local EC_HOVER = {
    name = "Hover",
    desc = [[
1) Engage all brakes
2) Set hover to 30 meters
3) Rotate to be as flat as possible
]],
    override = false,
    runtime = 0.0
}

EC_HOVER.start = function()
    -- BRAKE ALL THE THINGS, but only if speed is low. If we are going fast, we
    -- may be coasting.

    SHIP.retractLandingGears()
    EC_HOVER.runtime = 0.0
end

EC_HOVER.resume = EC_HOVER.start

EC_HOVER.stop = function()
end

EC_HOVER.flush = function(secs)
    EC_HOVER.runtime = EC_HOVER.runtime + secs
    SHIP.stabilize()
    SHIP.brake()
    SHIP.hover(30)
    if EC_HOVER.runtime > 3.0 and math.abs(PHYSICS.constructVelocitySpeed) < 0.2 then
        clearEngineCommand()
    end
end

CommandSelect.add(EC_HOVER)
