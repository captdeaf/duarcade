local SHIP = {}

SHIP.plan = {
    throttle = 0.0,
    throttleLateral = 0.0,
    throttleVertical = 0.0,
    pitch = 0.0,
    roll = 0.0,
    yaw = 0.0,
    brake = 0.0,
    booster = false,
    hoverAt = 4.0
}

SHIP.LONGITUDINAL = 0
SHIP.LATERAL = 1
SHIP.VERTICAL = 2

SHIP.TORQUE = 2.0

SHIP.setVectorThrust = function(throttle, tags, kinematicdirection, thrustdirection)
    local thrust = PHYSICS.nullvec
    if math.abs(throttle) > 0.01 then
        local maxThrust = core.getMaxKinematicsParametersAlongAxis(tags, {kinematicdirection:unpack()})
        local speedF, speedB, spaceF, spaceB = table.unpack(maxThrust)
        if not PHYSICS.inAtmo then
            speedF, speedB = spaceF, spaceB
        end
        local speed = speedF
        if throttle < 0 then
            speed = speedB
        end
        thrust = thrustdirection * speed * math.abs(throttle)
    end
    unit.setEngineCommand(tags, {thrust:unpack()}, {PHYSICS.nullvec:unpack()}, true, false, "", "", "", 0)
end

SHIP.update = function()
    unit.setAxisCommandValue(SHIP.LONGITUDINAL, SHIP.plan.throttle)
    unit.setAxisCommandValue(SHIP.LATERAL, SHIP.plan.throttleLateral)
    unit.setAxisCommandValue(SHIP.VERTICAL, SHIP.plan.throttleVertical)
end

SHIP.flush = function()
    SHIP.setVectorThrust(
        SHIP.plan.throttle,
        "thrust analog longitudinal",
        PHYSICS.constructLocalForward,
        PHYSICS.constructForward
    )
    SHIP.setVectorThrust(
        SHIP.plan.throttleLateral,
        "thrust analog lateral",
        PHYSICS.constructLocalRight,
        PHYSICS.constructRight
    )
    SHIP.setVectorThrust(
        SHIP.plan.throttleVertical,
        "thrust analog vertical",
        PHYSICS.constructLocalUp,
        PHYSICS.constructUp
    )

    local desiredAngularVelocity =
        SHIP.plan.pitch * PHYSICS.constructRight + SHIP.plan.roll * PHYSICS.constructForward +
        SHIP.plan.yaw * PHYSICS.constructUp

    PHYSICS.setRotationVelocity(desiredAngularVelocity, SHIP.TORQUE)

    unit.setEngineThrust("brake", SHIP.plan.brake * PHYSICS.maxBrakeForce)
    if SHIP.plan.booster then
        -- Any non-zero value, really.
        unit.setEngineThrust("booster", 100.0)
    else
        unit.setEngineThrust("booster", 0.0)
    end
    if SHIP.plan.hoverAt > 0.0 then
        unit.activateGroundEngineAltitudeStabilization(SHIP.plan.hoverAt)
    else
        unit.deactivateGroundEngineAltitudeStabilization()
    end
end

SHIP.unhover = function()
    SHIP.plan.hoverAt = -1.0
end

SHIP.hover = function(amt)
    amt = amt or 10.0
    SHIP.plan.hoverAt = amt
end

SHIP.reset = function()
    unit.setupAxisCommandProperties(0, 0)
    SHIP.plan = {
        throttle = 0.0,
        throttleLateral = 0.0,
        throttleVertical = 0.0,
        pitch = 0.0,
        roll = 0.0,
        yaw = 0.0,
        brake = 0.0,
        booster = false,
        hoverAt = 4.0
    }
end

SHIP.killEngines = SHIP.reset

SHIP.spin = function(pitch, roll, yaw)
    SHIP.plan.pitch = pitch
    SHIP.plan.roll = roll
    SHIP.plan.yaw = yaw
end

SHIP.rotateTo = function(pitch, roll, yaw)
    if pitch == nil then
        pitch = PHYSICS.currentPitchDeg
    end
    if roll == nil then
        roll = PHYSICS.currentRollDeg
    end
    if yaw == nil then
        yaw = PHYSICS.currentYawDeg
    end
    pitch = PHYSICS.getRotationCorrection(pitch, PHYSICS.currentPitchDeg)
    roll = PHYSICS.getRotationCorrection(roll, PHYSICS.currentRollDeg)
    yaw = PHYSICS.getRotationCorrection(yaw, PHYSICS.currentYawDeg)
    SHIP.spin(pitch, roll, yaw)
end

SHIP.throttleTo = function(amt)
    SHIP.plan.throttle = utils.clamp(amt, -1.0, 1.0)
end

SHIP.extendLandingGears = function()
    unit.extendLandingGears()
end

SHIP.retractLandingGears = function()
    unit.retractLandingGears()
end

SHIP.getCorrectionThrust = function(heading)
    local rval = utils.sign(heading)
    if math.abs(heading) > 90 then
	return rval * 0.3
    elseif math.abs(heading) > 15 then
	return rval * 0.05
    elseif math.abs(heading) > 5 then
	return rval * 0.01
    end
    return 0
end

SHIP.turnToSpaceVector = function(vec)
    local phead = getRoll(vec, PHYSICS.constructForward, PHYSICS.constructUp)
    local yhead = -getRoll(vec, PHYSICS.constructUp, PHYSICS.constructRight)
    local pvec = SHIP.getCorrectionThrust(phead)
    local yvec = SHIP.getCorrectionThrust(yhead)
    -- Roll doesn't matter
    SHIP.spin(pvec, 0.0, yvec)
end

SHIP.turnToHeadingAtmo = function(pitch, heading)
    local targetYaw = nil
    local roll = 0
    if math.abs(heading) > 90 then
	targetYaw = 0.5
	roll = 20
    elseif math.abs(heading) > 15 then
	targetYaw = 0.2
	roll = 10
    elseif math.abs(heading) > 5 then
	targetYaw = math.abs(heading) / 100
	roll = 5
    elseif math.abs(heading) > 0.01 then
	targetYaw = math.abs(heading) / 100
	roll = 0
    else
	targetYaw = 0.0
	roll = 0.0
    end
    if heading > 0 then
	targetYaw = -targetYaw
    else
	roll = -roll
    end
    local pvel = PHYSICS.getRotationCorrection(pitch, PHYSICS.currentPitchDeg)
    local rvel = PHYSICS.getRotationCorrection(roll, PHYSICS.currentRollDeg)
    local yvel = targetYaw
    SHIP.spin(pvel, rvel, yvel)
end

SHIP.stabilize = function()
    SHIP.rotateTo(0.0, 0.0, nil)
end

SHIP.brake = function(amt)
    SHIP.plan.brake = amt or 1.0
end
