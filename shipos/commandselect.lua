-- Flying Engine Selection screen. The first tab of main screen.
-- This is loaded fairly early on, so ShipEngine instances can
-- register themselves with CommandSelection.

local CommandSelect = {
    name = "Engine",
    ENGINES = {},
    ENGINES_NAME = {},
    Choice = 1
}

CommandSelect.add = function(cmd, hide)
    if not hide then
        table.insert(CommandSelect.ENGINES, cmd)
    end
    CommandSelect.ENGINES_NAME[cmd.name] = cmd
end

CommandSelect.Style =
    el(
    "style",
    [[
	    .enginetabs { position: fixed; display: block; left: 20vw; top: 35vh; }
	    .estab { display: block; width: 15vw; height: 4vh; margin: 0; padding: 5px; background-color: grey; font-size: 1.5vh; color: white; }
	    .essel { background-color: yellow; color: black; }
	    .esdesc { position: fixed; display: block; left: 35vw; top: 35vh; background-color: #666666cc; padding: 1em; width: 30vw; height: 30vh; font-size: 2vh; }
    ]]
)

CommandSelect.onFORWARD = function()
    CommandSelect.Choice = CommandSelect.Choice - 1
    if CommandSelect.Choice < 1 then
        CommandSelect.Choice = #CommandSelect.ENGINES
    end
end

CommandSelect.onBACKWARD = function()
    CommandSelect.Choice = CommandSelect.Choice + 1
    if CommandSelect.Choice > #CommandSelect.ENGINES then
        CommandSelect.Choice = 1
    end
end

CommandSelect.onUP = function()
    local choice = CommandSelect.ENGINES[CommandSelect.Choice]
    system.print("selecting engine")
    if choice.isEngine then
        setEngineControl(choice)
    else
        setEngineCommand(choice)
    end
    MainScreen.setControl()
end

CommandSelect.render = function()
    local tabs = {}
    local chosen = nil
    for i, engine in ipairs(CommandSelect.ENGINES) do
        local cls = "estab"
        if i == CommandSelect.Choice then
            cls = "estab essel"
            chosen = engine
        end
        table.insert(tabs, el("div", {class = cls}, engine.name))
    end
    return CommandSelect.Style .. el("div", {class = "enginetabs"}, tabs) .. el("div", {class = "esdesc"}, chosen.desc)
end
