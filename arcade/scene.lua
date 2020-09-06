-- Start

local ACTIVE_SCENE = {}
local PRESSED = {}
local DO_UPDATE = false

function setScene(scene)
    if ACTIVE_SCENE.saveState then
        local state = ACTIVE_SCENE.saveState()
        if state then
            alldata.setStringValue('save' .. ACTIVE_SCENE.dataid, json.encode(state))
        end
    end
    ACTIVE_SCENE = scene
    local newstate = nil
    if scene.start and scene.dataid then
        if alldata.hasKey('save' .. scene.dataid) then
            local val = alldata.getStringValue('save' .. scene.dataid)
            alldata.setStringValue('save' .. scene.dataid, "")
	    if val and val ~= "" then
	        newstate = json.decode(val)
	    end
        end
    end
    if scene.start then
	scene.start(newstate)
    end
    Renderer.draw(ACTIVE_SCENE, 0.0)
    DO_UPDATE = true
end

function onUpdate(secs)
    if ACTIVE_SCENE.update or DO_UPDATE then
        Renderer.draw(ACTIVE_SCENE, secs)
	DO_UPDATE = false
    end
end

-- What defines a scene? A scene has:
-- - A Render function.
-- - Key handlers
-- - Optional: SaveState() returns a JSON-able object, and LoadState(object)

-- Input from the player comes through here
function press(s)
    RESET_SCORE = 0
    PRESSED[s] = true
    kb = "onKey" .. s
    if ACTIVE_SCENE[kb] then
        ACTIVE_SCENE[kb](s) -- Some games prefer click to holding down
        Renderer.draw(ACTIVE_SCENE, 0.0)
    end
end
function release(s)
    PRESSED[s] = nil
end
function keyState(s)
    if PRESSED[s] then
        return 1
    else
        return 0
    end
end
