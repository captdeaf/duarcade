-- Physics stuff used by most of the scripted engines.
-- Axis
local PHYSICS = {
    PRESSED = {},
    nullvec = vec3(0.0, 0.0, 0.0)
}

function PHYSICS.keyState(key)
    return PHYSICS.PRESSED[key] and 1 or 0
end

function d2r(v)
    return v * constants.deg2rad
end

function PHYSICS.update()
    -- Information about the ship
    local unit_data = json.decode(unit.getData())
    PHYSICS.maxBrakeForce = unit_data["maxBrake"] or 100000000
    PHYSICS.currentSpeed = unit_data["speed"]
    PHYSICS.currentBrake = unit_data["currentBrake"]
    PHYSICS.currentAccel = unit_data["acceleration"]

    -- Gravity and which way is 'up'
    PHYSICS.worldGravity = vec3(core.getWorldGravity())
    PHYSICS.worldVertical = vec3(core.getWorldVertical())
    PHYSICS.altitude = core.getAltitude()
    PHYSICS.position = vec3(core.getConstructWorldPos())

    -- Construct orientation
    PHYSICS.constructUp = vec3(core.getConstructWorldOrientationUp())
    PHYSICS.constructForward = vec3(core.getConstructWorldOrientationForward())
    PHYSICS.constructRight = vec3(core.getConstructWorldOrientationRight())

    PHYSICS.constructLocalUp = vec3(core.getConstructOrientationUp())
    PHYSICS.constructLocalForward = vec3(core.getConstructOrientationForward())
    PHYSICS.constructLocalRight = vec3(core.getConstructOrientationRight())

    PHYSICS.constructMass = core.getConstructMass()

    -- Ship velocity relative to the world
    PHYSICS.constructVelocity = vec3(core.getWorldVelocity())
    PHYSICS.constructVelocityDir = vec3(core.getWorldVelocity()):normalize()
    PHYSICS.constructVelocitySpeed = vec3(core.getWorldVelocity()):len()

    PHYSICS.speedVertical = PHYSICS.constructVelocity * PHYSICS.constructUp
    PHYSICS.speedLateral = PHYSICS.constructVelocity * PHYSICS.constructRight
    PHYSICS.speedLongitudinal = PHYSICS.constructVelocity * PHYSICS.constructForward

    -- Angular velocity
    PHYSICS.constructAngularVelocity = vec3(core.getWorldAngularVelocity())
    PHYSICS.airAngularFriction = vec3(core.getWorldAirFrictionAngularAcceleration())

    -- Pitch and Roll relative to the planet
    -- I want pitch of 0 to be ship = flat, but game thinks flat = -90
    PHYSICS.currentPitchDeg = (getRoll(PHYSICS.worldVertical, PHYSICS.constructRight, PHYSICS.constructUp) + 90) % 360
    PHYSICS.currentRollDeg = getRoll(PHYSICS.worldVertical, PHYSICS.constructForward, PHYSICS.constructRight)
    PHYSICS.currentYawDeg = getRoll(PHYSICS.worldVertical, PHYSICS.constructUp, PHYSICS.constructForward)

    PHYSICS.atmosphereDensity = unit.getAtmosphereDensity()
    PHYSICS.inAtmo = PHYSICS.worldVertical:len() > 0.01 and PHYSICS.atmosphereDensity > 0.0
end

function PHYSICS.getRotationDiff(targetRotation, currentRotation)
    -- if targetrotation = 0 and currentRotation = 270, then diff should be -90,
    -- not 270.
    -- target: 90. current: 120. Should return  -30
    -- target: 0. current: 270 . Should return 90
    local targetDiff = (targetRotation - currentRotation) % 360
    if targetDiff > 180.0 then
        targetDiff = -(360 - targetDiff)
    elseif targetDiff < -180.0 then
        targetDiff = -(360 + targetDiff)
    end
    return targetDiff
end
function PHYSICS.getRotationCorrection(targetRotation, currentRotation)
    local targetDiff = PHYSICS.getRotationDiff(targetRotation, currentRotation)
    -- targetDiff is >= -180 <= 180
    -- If abs() < 10, then return 0.5, otherwise 1.0
    local mul = targetDiff > 0 and 1.0 or -1.0
    if math.abs(targetDiff) < 0.1 then
        return 0.0
    elseif math.abs(targetDiff) < 10 then
        return mul * 0.1
    elseif math.abs(targetDiff) < 45 then
        return mul * 0.5
    else
        return mul
    end
end

-- Rotation
function PHYSICS.setRotationVelocity(angularVelocity, torqueFactor)
    local angularAcceleration = torqueFactor * (angularVelocity - PHYSICS.constructAngularVelocity)
    angularAcceleration = angularAcceleration - PHYSICS.airAngularFriction -- Try to compensate air friction

    unit.setEngineCommand("torque", {vec3(0.0, 0.0, 0.0):unpack()}, {angularAcceleration:unpack()}, 1, 0, "", "", "", 0)
end

function PHYSICS.setShipRotation(pitch, roll, yaw)
    local target = -pitch * PHYSICS.constructRight + roll * PHYSICS.constructForward + yaw * PHYSICS.constructUp

    PHYSICS.setRotationVelocity(target, 2.0)
end
