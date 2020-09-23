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
local SHIP = {}
SHIP.plan = {
speed = nil,
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
SHIP.pids = {}
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
if SHIP.plan.speed ~= nil then
local speedDiff = SHIP.plan.speed - PHYSICS.constructVelocitySpeed
local delta = SHIP.pid('speed', speedDiff)
SHIP.plan.throttle = utils.clamp(SHIP.plan.throttle + delta, 0.0, 1.0)
end
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
SHIP.targetSpeed = function(amt)
SHIP.plan.speed = amt
end
SHIP.reset = function()
unit.setupAxisCommandProperties(0, 0)
SHIP.plan = {
speed = nil,
throttle = 0.0,
throttleLateral = 0.0,
throttleVertical = 0.0,
pitch = 0.0,
roll = 0.0,
yaw = 0.0,
brake = 0.0,
booster = false,
hoverAt = 20.0
}
SHIP.pids = {}
end
SHIP.killEngines = function()
SHIP.plan.throttle = 0.0
SHIP.plan.throttleLateral = 0.0
SHIP.plan.throttleVertical = 0.0
SHIP.plan.pitch = 0.0
SHIP.plan.roll = 0.0
SHIP.plan.yaw = 0.0
SHIP.plan.booster = false
end
SHIP.spin = function(pitch, roll, yaw)
SHIP.plan.pitch = pitch
SHIP.plan.roll = roll
SHIP.plan.yaw = yaw
end
SHIP.rotateTo = function(pitch, roll)
-- rotateTo is atmo-only. Yaw has no meaning in atmo.
if pitch == nil then
pitch = PHYSICS.currentPitchDeg
end
if roll == nil then
roll = PHYSICS.currentRollDeg
end
pitch = SHIP.pidRotate('pitch', pitch, PHYSICS.currentPitchDeg)
roll = SHIP.pidRotate('roll', roll, PHYSICS.currentRollDeg)
SHIP.spin(pitch, roll, 0.0)
end
SHIP.throttleTo = function(amt)
SHIP.plan.speed = nil
SHIP.plan.throttle = utils.clamp(amt, -1.0, 1.0)
end
SHIP.extendLandingGears = function()
unit.extendLandingGears()
end
SHIP.retractLandingGears = function()
unit.retractLandingGears()
end
SHIP.pid = function(name, val)
if not SHIP.pids[name] then
SHIP.pids[name] = pid.new(0.01, 0, 0.2)
end
SHIP.pids[name]:inject(val)
local ret = SHIP.pids[name]:get()
return ret
end
SHIP.pidRotate = function(name, val, target)
local diff = PHYSICS.getRotationDiff(val, target)
return SHIP.pid(name, diff)
end
SHIP.turnToSpaceVector = function(vec)
local phead = PHYSICS.getRotationDiff(getRoll(vec, PHYSICS.constructRight, PHYSICS.constructUp), 180)
local yhead = getRoll(vec, PHYSICS.constructUp, PHYSICS.constructRight)
-- phead and yhead are the difference between vec and current construct facing
-- So we need to invert them for the pid()
local pvec = SHIP.pid('spacepitch', -phead)
local yvec = SHIP.pid('spaceyaw', -yhead)
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
local pvel = SHIP.pidRotate('headingpitch', pitch, PHYSICS.currentPitchDeg)
local rvel = SHIP.pidRotate('headingroll', roll, PHYSICS.currentRollDeg)
local yvel = targetYaw
SHIP.spin(pvel, rvel, yvel)
end
SHIP.stabilize = function()
SHIP.rotateTo(0.0, 0.0, nil)
end
SHIP.brake = function(amt)
SHIP.plan.brake = amt or 1.0
end
local ENGINE_SHIP = {
name = "Control engine using the SHIP shiplib",
desc = [[Pretty much the same as default, but clearer in code for me.]],
isEngine = true
}
function ENGINE_SHIP.start()
system.print("Setting throttle info")
SHIP.reset()
end
function ENGINE_SHIP.onSTOPENGINES()
SHIP.killEngines()
end
function ENGINE_SHIP.onBOOSTER()
SHIP.plan.booster = not SHIP.plan.booster
end
function ENGINE_SHIP.startSPEEDDOWN()
ENGINE_SHIP.alterSpeed(-0.1)
end
function ENGINE_SHIP.startSPEEDUP()
ENGINE_SHIP.alterSpeed(0.1)
end
function ENGINE_SHIP.alterSpeed(amt)
local cur = SHIP.plan.throttle + amt
if cur > 1.0 then
cur = 1.0
end
if cur < -1.0 then
cur = -1.0
end
SHIP.plan.throttle = cur
end
function ENGINE_SHIP.update(secs)
local amt = system.getThrottleInputFromMouseWheel()
if math.abs(amt) > 0.01 then
ENGINE_SHIP.alterSpeed(0.1 * amt)
end
end
function ENGINE_SHIP.onLIGHT()
if unit.isAnyHeadlightSwitchedOn() == 1 then
unit.switchOffHeadlights()
else
unit.switchOnHeadlights()
end
end
function ENGINE_SHIP.startGROUNDALTITUDEUP()
SHIP.plan.hoverAt = SHIP.plan.hoverAt + 1.0
if SHIP.plan.hoverAt > 50.0 then
SHIP.plan.hoverAt = 50.0
end
end
function ENGINE_SHIP.loopGROUNDALTITUDEUP()
SHIP.plan.hoverAt = SHIP.plan.hoverAt + 1.0
if SHIP.plan.hoverAt > 50.0 then
SHIP.plan.hoverAt = 50.0
end
end
function ENGINE_SHIP.startGROUNDALTITUDEDOWN()
SHIP.plan.hoverAt = SHIP.plan.hoverAt - 1.0
if SHIP.plan.hoverAt < 1.0 then
SHIP.plan.hoverAt = 1.0
end
end
function ENGINE_SHIP.loopGROUNDALTITUDEDOWN()
SHIP.plan.hoverAt = SHIP.plan.hoverAt - 1.0
if SHIP.plan.hoverAt < 1.0 then
SHIP.plan.hoverAt = 1.0
end
end
function ENGINE_SHIP.onWARP()
if warpdrive ~= nil then
warpdrive.activateWarp()
end
end
function ENGINE_SHIP.onANTIGRAVITY()
if antigrav ~= nil then
antigrav.toggle()
end
end
function ENGINE_SHIP.flush(secs)
-- OVERRIDE by shipos
local pitchInput = PHYSICS.keyState("BACKWARD") - PHYSICS.keyState("FORWARD")
local rollInput = PHYSICS.keyState("RIGHT") - PHYSICS.keyState("LEFT")
local yawInput = PHYSICS.keyState("YAWLEFT") - PHYSICS.keyState("YAWRIGHT")
SHIP.plan.throttleLateral = PHYSICS.keyState("STRAFERIGHT") - PHYSICS.keyState("STRAFELEFT")
SHIP.plan.throttleVertical = PHYSICS.keyState("UP") - PHYSICS.keyState("DOWN")
local finalPitchInput = pitchInput + system.getControlDeviceForwardInput()
local finalRollInput = rollInput + system.getControlDeviceYawInput()
local finalYawInput = yawInput - system.getControlDeviceLeftRightInput()
local finalBrakeInput = PHYSICS.keyState("BRAKE")
SHIP.spin(finalPitchInput, finalRollInput, finalYawInput)
SHIP.brake(finalBrakeInput)
end
function onFlush(secs)
PHYSICS.update()
ENGINE_SHIP.flush(secs)
SHIP.flush(secs)
end
function onUpdate(secs)
SHIP.update()
ENGINE_SHIP.update(secs)
end
function press(s)
local kb = "start" .. s
if ENGINE_SHIP[kb] then
ENGINE_SHIP[kb]()
end
PHYSICS.PRESSED[s] = true
end
function release(s)
local kb = "stop" .. s
local kb2 = "on" .. s
if ENGINE_SHIP[kb] then
ENGINE_SHIP[kb]()
elseif ENGINE_SHIP[kb2] then
ENGINE_SHIP[kb2]()
end
PHYSICS.PRESSED[s] = nil
end
function loopKey(s)
local kb = "loop" .. s
if ENGINE_SHIP[kb] then
ENGINE_SHIP[kb]()
end
end
SHIP.reset()
PHYSICS.update()
ENGINE_SHIP.start()
