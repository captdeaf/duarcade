local ENGINE_SHIP = {
    name = 'Control engine using the SHIP shiplib',
    desc = [[Pretty much the same as default, but clearer in code for me.]],
    isEngine = true,
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
    if cur > 1.0 then cur = 1.0 end
    if cur < -1.0 then cur = -1.0 end
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
    if SHIP.plan.hoverAt > 50.0 then SHIP.plan.hoverAt = 50.0 end
end

function ENGINE_SHIP.loopGROUNDALTITUDEUP()
    SHIP.plan.hoverAt = SHIP.plan.hoverAt + 1.0
    if SHIP.plan.hoverAt > 50.0 then SHIP.plan.hoverAt = 50.0 end
end

function ENGINE_SHIP.startGROUNDALTITUDEDOWN()
    SHIP.plan.hoverAt = SHIP.plan.hoverAt - 1.0
    if SHIP.plan.hoverAt < 1.0 then SHIP.plan.hoverAt = 1.0 end
end

function ENGINE_SHIP.loopGROUNDALTITUDEDOWN()
    SHIP.plan.hoverAt = SHIP.plan.hoverAt - 1.0
    if SHIP.plan.hoverAt < 1.0 then SHIP.plan.hoverAt = 1.0 end
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
    local pitchInput = PHYSICS.keyState('BACKWARD') - PHYSICS.keyState('FORWARD')
    local rollInput = PHYSICS.keyState('RIGHT') - PHYSICS.keyState('LEFT')
    local yawInput = PHYSICS.keyState('YAWLEFT') - PHYSICS.keyState('YAWRIGHT')

    SHIP.plan.throttleLateral = PHYSICS.keyState('STRAFERIGHT') - PHYSICS.keyState('STRAFELEFT')
    SHIP.plan.throttleVertical = PHYSICS.keyState('UP') - PHYSICS.keyState('DOWN')

    local finalPitchInput = pitchInput + system.getControlDeviceForwardInput()
    local finalRollInput = rollInput + system.getControlDeviceYawInput()
    local finalYawInput = yawInput - system.getControlDeviceLeftRightInput()
    local finalBrakeInput = PHYSICS.keyState('BRAKE')

    SHIP.spin(finalPitchInput, finalRollInput, finalYawInput)

    SHIP.brake(finalBrakeInput)
end

CommandSelect.add(ENGINE_SHIP, true)
