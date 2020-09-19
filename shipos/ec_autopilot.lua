local EC_AUTOPILOT = {
    name = 'Autopilot',
    desc = [[
Engage autopilot. Destination: (Select destination from autopilot menu)
]],
    desctemplate = [[
Engage autopilot. Destination: %s.
]],
    override = false,

    callbacks = {},
    announcements = {},
    time = 0.0,
    throttle = 0.4,
    arrived = false,
}

EC_AUTOPILOT.start = function()
    EC_AUTOPILOT.time = 0.0
    EC_AUTOPILOT.arrived = false
    EC_AUTOPILOT.announcements = {}
    EC_AUTOPILOT.recalculate()
end

EC_AUTOPILOT.announce = function(msg)
    if EC_AUTOPILOT.announcements[msg] then return end
    EC_AUTOPILOT.announcements[msg] = true
    system.print("ANNOUNCEMENT: " .. msg)
end

EC_AUTOPILOT.resume = EC_AUTOPILOT.start

EC_AUTOPILOT.stop = function()
end

-- This is called twice a second
EC_AUTOPILOT.recalculate = function()
    if not databank.hasKey('destination') then return end
    EC_AUTOPILOT.callbacks = {}
    -- This is the meat of autopilot.
    -- To start: discover our position relative to destination, our status
    --    (in atmo safe, in space safe, in space approaching, in atmo approaching)
    -- Then, determine which do we want to do:
    --     - Brake and stop if we are close enough
    --     - Determine if we are in-atmosphere or not
    --     - Near, in atmo: Cross-planetary plotting
    --     - Destination extraplanetary, in atmo: Take off.
    --     - Approaching planet from space? YIKES.
    --         - Be very conservative when approaching a space destination.
    --     - In space: Determine: speed up or slow down, and in which angle
    local destination = MainScreen.destination
    if not (destination and destination.name) then
	clearEngineCommand()
	return
    end
    local dpos = vec3(destination.position)
    local mypos = vec3(core.getConstructWorldPos())
    local vdiff = dpos - mypos
    local dist = vdiff:len()
    EC_AUTOPILOT.announce("Plotting route for " .. math.floor(dist / 1000) .. "km")
    local inatmo = PHYSICS.isInAtmosphere()

    local cbs = EC_AUTOPILOT.callbacks

    -- vdiff also defines what vector we want to aim at.
    -- If we're in atmo, though, we only want the yaw heading.
    local yaw_heading = getRoll(vdiff, PHYSICS.constructUp, PHYSICS.constructRight)
    local altDiff = PHYSICS.altitude - destination.altitude

    SHIP.retractLandingGears()

    if inatmo and dist < 200000.0 and destination.inatmo then

	local flatdist = math.sqrt(dist*dist - altDiff*altDiff)

	local desiredAltitude = 0.0

	-- Still experimenting between speed and throttle
	local desiredSpeed = 0.0
	local desiredThrottle = 0.0

        if EC_AUTOPILOT.arrived and PHYSICS.currentSpeed < 1.0 then
	    table.insert(cbs, {clearEngineCommand})
	    table.insert(cbs, {clearDestination})
	    table.insert(cbs, {setEngineCommand, EC_LAND})
        elseif EC_AUTOPILOT.arrived or flatdist < 15.0 then
	    EC_AUTOPILOT.arrived = true
	    table.insert(cbs, {SHIP.stabilize})
	    table.insert(cbs, {SHIP.throttleTo, 0.0})
	    table.insert(cbs, {SHIP.killEngines})
	    table.insert(cbs, {SHIP.brake, 1.0})
	    table.insert(cbs, {SHIP.hover, 10})
	    return
	elseif flatdist < 50.0 then
	    desiredThrottle = 0.1
	    desiredSpeed = 20.0
	    desiredAltitude = destination.altitude + 10
	elseif flatdist < 400.0 then
	    desiredThrottle = 0.2
	    desiredSpeed = 60.0
	    desiredAltitude = destination.altitude + 20
	elseif flatdist < 600.0 then
	    desiredThrottle = 0.2
	    desiredSpeed = 80.0
	    desiredAltitude = destination.altitude + 60
	elseif flatdist < 1000 then
	    desiredThrottle = 0.3
	    desiredAltitude = destination.altitude + 100
	    desiredSpeed = 80.0
	elseif flatdist < 2000 then
	    desiredThrottle = 0.6
	    desiredAltitude = destination.altitude + 200
	    desiredSpeed = 1000.0
	elseif flatdist < 5000 then
	    desiredThrottle = 1.0
	    desiredAltitude = destination.altitude + 600
	    desiredSpeed = 1000.0
	else
	    desiredThrottle = 1.0
	    desiredAltitude = destination.altitude + 800
	    desiredSpeed = 1000.0
	end

	local vertdiff = desiredAltitude - PHYSICS.altitude

	local pitch = 0.0
	local brakeTo = 0.0

	if PHYSICS.currentSpeed - desiredSpeed > 60 then
	    brakeTo = 1.0
	elseif PHYSICS.currentSpeed - desiredSpeed > 10 then
	    brakeTo = 0.4
	else
	    brakeTo = 0.0
	end
        
	if vertdiff > 40 then
	    pitch = 15.0
	elseif vertdiff > -40 then
	    pitch = 5.0
	else
	    pitch = -12.0
	    brakeTo = 0.4
	end

	EC_AUTOPILOT.throttle = utils.clamp(desiredThrottle, 0.0, 1.0)

        -- Cross-planetary travel
	table.insert(cbs, {SHIP.turnToHeadingAtmo, pitch, yaw_heading})
	table.insert(cbs, {SHIP.hover, 30})
	table.insert(cbs, {SHIP.throttleTo, EC_AUTOPILOT.throttle})
	table.insert(cbs, {SHIP.brake, brakeTo})
    else
        EC_AUTOPILOT.announce("Interplanetary travel TBD")
    end
    
end

EC_AUTOPILOT.update = function(secs)
    local now = EC_AUTOPILOT.time + (secs * 2)
    if math.floor(EC_AUTOPILOT.time) ~= math.floor(now) then
        EC_AUTOPILOT.recalculate()
    end
    EC_AUTOPILOT.time = now
end

EC_AUTOPILOT.flush = function(secs)
    for i, cbs in ipairs(EC_AUTOPILOT.callbacks) do
        local cb = cbs[1]
        cb(table.unpack(cbs, 2, #cbs))
    end
end

CommandSelect.add(EC_AUTOPILOT)
