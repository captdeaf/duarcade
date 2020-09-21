-- Main screen, which tabs between different modes, and
-- keeps state across children.
--
-- We always have a ShipRunner running, even if ShipOff
-- ShipRunner is background
-- Current Screen is foreground
-- Main Tabs on top, always.

-- MainScreen must be global for earlier files to access it.
MainScreen = {
    ShipRunner = {},
    ShipCommand = nil,
    Screen = ScreenStart,
    Tab = 1,
    ACTIVE = {},
    destination = nil
}

MainScreen.TABS = {
    {name = "Control", isControl = true, render = function()
        end}
}

if unit.isRemoteControlled() == 1 then
    table.insert(
        MainScreen.TABS,
        {name = "Walk", isWalk = true, freeze = false, render = function()
            end}
    )
end

table.insert(MainScreen.TABS, CommandSelect)
table.insert(MainScreen.TABS, AutoPilotScreen)
table.insert(MainScreen.TABS, HUDConfig)

-- Control is active first.
MainScreen.ACTIVE = MainScreen.TABS[1]

MainScreen.onGEAR = function()
    MainScreen.Tab = MainScreen.Tab + 1
    if MainScreen.Tab > #MainScreen.TABS then
        MainScreen.Tab = 1
    end
    MainScreen.ACTIVE = MainScreen.TABS[MainScreen.Tab]
    if MainScreen.ACTIVE.isWalk then
        system.freeze(0)
    else
        system.freeze(1)
    end
end

function MainScreen.setControl()
    MainScreen.Tab = 1
    MainScreen.ACTIVE = MainScreen.TABS[1]
end

function onFlush(secs)
    PHYSICS.update()
    if MainScreen.ShipCommand and MainScreen.ShipCommand.flush then
        MainScreen.ShipCommand.flush(secs)
    elseif MainScreen.ShipRunner and MainScreen.ShipRunner.flush then
        MainScreen.ShipRunner.flush(secs)
    end
    SHIP.flush()
end

function tabStyle()
    return el(
        "style",
        [[
        .maintabs { position: fixed; display: block; left: 40vw; top: 15vh; }
        .tab { display: inline-block; width: 5vw; height: 4vh; margin: 0; padding: 5px; background-color: grey; font-size: 2vh; color: white; }
        .sel { background-color: yellow; color: black; }
	.dest { display: block; position: fixed; left: 45vw; top: 26vh; font-size: 2vh; color: green; font-weight: bold; }
	.info { display: block; position: fixed; left: 40vw; top: 20vh; font-size: 3vh; color: red; font-weight: bold; background-color: #66666666; }
    ]]
    )
end

function renderTabs()
    local tabs = {}
    for i, tab in ipairs(MainScreen.TABS) do
        local cls = "tab"
        if i == MainScreen.Tab then
            cls = "tab sel"
        end
        table.insert(tabs, el("div", {class = cls}, tab.name))
    end
    return el("div", {class = "maintabs"}, tabs)
end

function generateContent()
    local selected = MainScreen.TABS[MainScreen.Tab]
    local subscreen = ""
    if selected.render then
        subscreen = selected.render() or ""
    else
        subscreen = "NO RENDERER?"
    end
    local shipcommand = ""
    if MainScreen.ShipCommand then
        shipcommand = el("div", {class = "info"}, "Executing: " .. MainScreen.ShipCommand.name .. "(Q to cancel)")
    end
    local dest = ""
    if MainScreen.destination and MainScreen.destination.name then
        dest = el("div", {class = "dest"}, "Destination: " .. (MainScreen.destination.name or "None?"))
    end
    return el(
        "html",
        {
            el(
                "head",
                {
                    tabStyle()
                }
            ),
            el(
                "body",
                {
                    renderTabs(),
                    renderHUD(),
                    subscreen,
                    shipcommand,
                    dest
                }
            )
        }
    )
end

function renderHUD()
    local ret = {}
    for _, hud in pairs(HUDConfig.ENABLED) do
        if hud.render then
            table.insert(ret, hud.render())
        end
    end
    return table.concat(ret, "")
end

function MainScreen.start()
    system.freeze(1)
    system.showScreen(1)
    if databank.hasKey("destination") then
        MainScreen.destination = json.decode(databank.getStringValue("destination"))
    end
    local ec = databank.getStringValue("ec")
    if ec and ec ~= nil and ec ~= "" then
        MainScreen.ShipCommand = CommandSelect.ENGINES_NAME[ec]
        if MainScreen.ShipCommand.resume then
            MainScreen.ShipCommand.resume()
        end
    end
    local eng = databank.getStringValue("eng")
    if not eng or eng == nil or eng == "" then
        eng = ENGINE_SHIP.name
    end
    MainScreen.ShipRunner = CommandSelect.ENGINES_NAME[eng]
    if MainScreen.ShipRunner.start then
        MainScreen.ShipRunner.start()
    end
end

local NEXTRENDER = 0.0
local FLYTIME = 0.0

function onUpdate(secs)
    SHIP.update()
    if FLYTIME == 0.0 then
        initialize()
    end
    FLYTIME = FLYTIME + secs
    if MainScreen.ShipRunner and MainScreen.ShipRunner.update then
        if not (MainScreen.ShipCommand and MainScreen.ShipCommand.override) then
            MainScreen.ShipRunner.update(secs)
        end
    end
    if MainScreen.ShipCommand and MainScreen.ShipCommand.update then
        MainScreen.ShipCommand.update(secs)
    end
    if FLYTIME > NEXTRENDER then
        collectgarbage()
        for _, hud in pairs(HUDConfig.ENABLED) do
            if hud.update then
                hud.update(secs)
            end
        end
        system.setScreen(generateContent())
        NEXTRENDER = FLYTIME + 0.1 -- 10 times a second
    end
end

function setEngineControl(engine)
    if engine.start then
        engine.start()
    end
    MainScreen.ShipRunner = engine
    databank.setStringValue("eng", engine.name)
end

function clearEngineCommand()
    if MainScreen.ShipCommand and MainScreen.ShipCommand.stop then
        MainScreen.ShipCommand.stop()
    end
    databank.setStringValue("ec", "")
    MainScreen.ShipCommand = nil
end

function setEngineCommand(cmd)
    if cmd.start then
        cmd.start()
    end
    databank.setStringValue("ec", cmd.name)
    MainScreen.ShipCommand = cmd
end

-- Input from the player comes through here
function press(s)
    if s == "GEAR" then
        MainScreen.onGEAR()
        return
    end
    local listener = MainScreen.ACTIVE
    if s == "LEFT" and MainScreen.ShipCommand and listener.isControl then
        clearEngineCommand()
        return
    end
    if listener.isWalk then
        return
    end
    if listener.isControl then
        if MainScreen.ShipCommand then
            listener = MainScreen.ShipCommand
        end
        if not listener.override_controls then
            PHYSICS.PRESSED[s] = true
            listener = MainScreen.ShipRunner
        end
    end
    local kb = "start" .. s
    if listener[kb] then
        listener[kb]()
    end
end
function release(s)
    if s == "GEAR" then
        return
    end
    local listener = MainScreen.ACTIVE
    if listener.isWalk then
        return
    end
    if listener.isControl then
        PHYSICS.PRESSED[s] = nil
        listener = MainScreen.ShipRunner
    end
    local kb = "stop" .. s
    local kb2 = "on" .. s
    if listener[kb] then
        listener[kb]()
    elseif listener[kb2] then
        listener[kb2]()
    elseif listener.hit then
        listener.hit(s)
    end
end
function loopKey(s)
    if s == "GEAR" then
        return
    end
    local listener = MainScreen.ACTIVE
    if listener.isWalk then
        return
    end
    if listener.isControl then
        listener = MainScreen.ShipRunner
    end
    local kb = "loop" .. s
    if listener[kb] then
        listener[kb]()
    end
end
