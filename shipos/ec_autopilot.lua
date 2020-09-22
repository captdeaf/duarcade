local AP_DESCENT_THROTTLE = 0.2 --export: Throttle % to use on descent / approach
local AP_DESCENT_DISTANCE = 2200 --export: How far away from destination to start descending
local AP_CRUISE_ALTITUDE = 800 --export: How high above target altitude to cruise?
local AP_CLIMB_PITCH = 15 --export: In degrees, how high to aim the ship during initial, full power climb.
local AP_CRUISE_PITCH = 6.0 --export: Pitch to cruise at. If you're bouncing up and down, adjust this.

local AP_ESCAPE_PITCH = 15.0 --export: Pitch to climb out of atmosphere with.

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
    last_announcement = nil,
    time = 0.0,
    arrived = false,
}

EC_AUTOPILOT.start = function()
    EC_AUTOPILOT.time = 0.0
    EC_AUTOPILOT.arrived = false
    EC_AUTOPILOT.announcements = {}
    EC_AUTOPILOT.recalculate()
    EC_AUTOPILOT.log = {}
end

EC_AUTOPILOT.announce = function(msg)
    if EC_AUTOPILOT.last_announcement == msg then return end
    EC_AUTOPILOT.last_announcement = msg
    system.print("ANNOUNCEMENT: " .. msg)
end

EC_AUTOPILOT.resume = EC_AUTOPILOT.start

EC_AUTOPILOT.stop = function()
    EC_AUTOPILOT.log = {}
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
    local vdirection = vdiff:normalize()
    local dist = vdiff:len()
    local inatmo = PHYSICS.inAtmo

    local cbs = EC_AUTOPILOT.callbacks

    -- vdiff also defines what vector we want to aim at.
    -- If we're in atmo, though, we only want the yaw heading.
    local yaw_heading = getRoll(vdiff, PHYSICS.constructUp, PHYSICS.constructRight)
    local altDiff = PHYSICS.altitude - destination.altitude

    local mybody = DU.getNearestBody(PHYSICS.position)
    local dbody = DU.getNearestBody(vec3(destination.position))
    local samebody = mybody.id == dbody.id
    local saltitude = DU.distanceFromSurface(PHYSICS.position, dbody)
    local daltitude = DU.distanceFromSurface(vec3(destination.position), dbody)

    SHIP.retractLandingGears()

    -- I think there's no planets more than 1.5 SU wide, and there's no
    if saltitude < 10000 and daltitude < 10000 and samebody then

	local flatdist = math.sqrt(dist*dist - altDiff*altDiff)

	local desiredAltitude = 0.0

	-- Still experimenting between speed and throttle
	local desiredSpeed = 0.0
	local desiredThrottle = 0.0

        if EC_AUTOPILOT.arrived and PHYSICS.currentSpeed < 1.0 then
	    if altDiff < 15.0 then
		table.insert(cbs, {clearEngineCommand})
		table.insert(cbs, {clearDestination})
		table.insert(cbs, {setEngineCommand, EC_LAND})
	    else
	        -- Unbrake so we fall down. 
		table.insert(cbs, {SHIP.stabilize})
		table.insert(cbs, {SHIP.brake, 0.0})
		table.insert(cbs, {SHIP.hover, 10})
	    end
        elseif EC_AUTOPILOT.arrived or flatdist < 30.0 then
	    EC_AUTOPILOT.arrived = true
	    table.insert(cbs, {SHIP.stabilize})
	    table.insert(cbs, {SHIP.throttleTo, 0.0})
	    table.insert(cbs, {SHIP.killEngines})
	    table.insert(cbs, {SHIP.brake, 1.0})
	    table.insert(cbs, {SHIP.hover, 10})
	    return
	elseif flatdist < AP_DESCENT_DISTANCE then
	    desiredThrottle = AP_DESCENT_THROTTLE
	    desiredSpeed = 20.0
	    local fact = flatdist / AP_DESCENT_DISTANCE
	    desiredAltitude = destination.altitude + AP_CRUISE_ALTITUDE * (fact * fact)
	else
	    desiredThrottle = 1.0
	    desiredAltitude = destination.altitude + AP_CRUISE_ALTITUDE
	    desiredSpeed = 1000.0
	end

	local vertdiff = desiredAltitude - PHYSICS.altitude

	local pitch = 0.0
	local brakeTo = 0.0

	if PHYSICS.currentSpeed - desiredSpeed > 60 then
	    brakeTo = 1.0
	elseif PHYSICS.currentSpeed - desiredSpeed > 10 then
	    brakeTo = 0.2
	else
	    brakeTo = 0.0
	end

	if vertdiff > 50 then
	    pitch = AP_CLIMB_PITCH
	elseif vertdiff > -20 then
	    pitch = AP_CRUISE_PITCH
	elseif vertdiff > -60 then
	    pitch = -5.0
	else
	    pitch = -15.0
	end

	desiredThrottle = utils.clamp(desiredThrottle, 0.0, 1.0)

	-- At a very high distance (on other side of planet), yaw heading gets confused easily.
	if dist > 30000 and math.abs(yaw_heading) < 5 then
	    yaw_heading = 0
	end

        -- Cross-planetary travel
	table.insert(cbs, {SHIP.turnToHeadingAtmo, pitch, yaw_heading})
	table.insert(cbs, {SHIP.hover, 30})
	table.insert(cbs, {SHIP.throttleTo, desiredThrottle})
	table.insert(cbs, {SHIP.brake, brakeTo})
    elseif inatmo then
        -- If we are here, we have to take off. Destination is either in space, or
	-- on another body.
	table.insert(cbs, {SHIP.throttleTo, 1.0})
	table.insert(cbs, {SHIP.brake, 0.0})
        if EC_AUTOPILOT.time < 40 then
	    table.insert(cbs, {SHIP.turnToHeadingAtmo, AP_CLIMB_PITCH, yaw_heading})
	    EC_AUTOPILOT.announce("Begin takeoff")
	elseif PHYSICS.altitude < 3000 then
	    -- TODO: Depend on body gravity+density+etc?
	    SHIP.rotateTo(AP_CLIMB_PITCH, 0.0, nil)
	    EC_AUTOPILOT.announce("Climb to escape")
	else
	    SHIP.rotateTo(AP_ESCAPE_PITCH, 0.0, nil)
	    EC_AUTOPILOT.announce("Attempting to escape atmo")
	end
    elseif PHYSICS.altitude < 30000 and not samebody then
	EC_AUTOPILOT.announce("Out of atmosphere, attempting to escape")
        -- Continue to try escaping our planet.
	if inatmo then
	    table.insert(cbs, {SHIP.turnToHeadingAtmo, AP_CLIMB_PITCH, yaw_heading})
	else
	    table.insert(cbs, {SHIP.turnToSpaceVector, vdirection})
	end
	table.insert(cbs, {SHIP.throttleTo, 1.0})
	table.insert(cbs, {SHIP.brake, 0.0})
    else
        -- TODO: Raycast and determine if any of the bodies are in the way
        local stopIn = dist
	local desiredBrake = 0.0
        if saltitude < stopIn then stopIn = saltitude end
	stopIn = stopIn - 10000 -- Atmosphere
	EC_AUTOPILOT.announce("Performing space approach")
	local brakedist = PHYSICS.brakeDistance * 1.5 -- Padding for Gravity until I can account for it
	if (PHYSICS.currentSpeed > 270.0 and stopIn <= brakedist) or
	   (SHIP.plan.brake == 1.0 and stopIn < (brakedist * 1.2)) then
	    -- 277 m/s is just under 1000 km/h, which is the damage point for
	    -- entering atmosphere.
	    desiredBrake = 1.0
	    table.insert(cbs, {SHIP.brake, 1.0})
	    table.insert(cbs, {SHIP.throttleTo, 0.0})
	elseif brakedist < (stopIn * 0.75) then
	    table.insert(cbs, {SHIP.brake, 0.0})
	    table.insert(cbs, {SHIP.throttleTo, 1.0})
	else
	    table.insert(cbs, {SHIP.throttleTo, 0.0})
	end
	-- Attempt to correct for drift

	local vfix = vdirection - PHYSICS.constructVelocityDir
	local vgo = (vdirection + vfix):normalize()

        local vfl = vfix:len()

        if PHYSICS.constructVelocitySpeed > 100 then
	  if vfix:len() > 1.0 then
	      -- Massive course correction required
	      desiredBrake = 1.0
	  elseif vfix:len() > 0.25 then
	      vgo = vfix
	  elseif vfix:len() > 0.05 then
	      vgo = (vdirection * 2.0 + vfix):normalize()
	  end
	end

	table.insert(cbs, {SHIP.turnToSpaceVector, vgo})
	table.insert(cbs, {SHIP.brake, desiredBrake})
    end

end

EC_AUTOPILOT.update = function(secs)
    local now = EC_AUTOPILOT.time + secs
    -- To save processing time, we recalculate only twice a second.
    if math.floor(EC_AUTOPILOT.time * 2) ~= math.floor(now * 2) then
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
