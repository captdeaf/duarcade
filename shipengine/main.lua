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
