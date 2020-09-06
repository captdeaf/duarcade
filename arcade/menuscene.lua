SCENE_MENU = {
    optionIdx = 1,
    options = {},
    GAMES = {},
    DEFAULT = {},
}

function rebuildMenu()
    SCENE_MENU.options = {}
    for k, v in pairs(SCENE_MENU.GAMES) do
        table.insert(SCENE_MENU.options, v)
    end
    for k, v in pairs(SCENE_MENU.DEFAULT) do
        table.insert(SCENE_MENU.options, v)
    end
end

function registerGame(name, scene)
    table.insert(SCENE_MENU.GAMES, {name=name, scene=scene})
    rebuildMenu()
end

function registerDefaultScene(name, scene)
    table.insert(SCENE_MENU.DEFAULT, {name=name, scene=scene})
    rebuildMenu()
end

SCENE_MENU.render = function(secs)
    -- Draw intro GUI screen.
    -- Text styles used:
    addDraw(svg("style", nil, {[[
        .title { font: bold italic 160px sans-serif; fill: white; }
        .item { font: bold 80px sans-serif; fill: gray; }
        .choice { font: bold 80px sans-serif; fill: yellow; }
    ]]}))
    addDraw(svg("text", {x=120, y=280, class="title"}, {"Ready, Player One!"}))

    if SCENE_MENU.optionIdx > 2 then
	local opt1 = SCENE_MENU.options[SCENE_MENU.optionIdx - 2]
        addDraw(svg("text", {x=220, y=600, class="item"}, {opt1.name}))
    end
    if SCENE_MENU.optionIdx > 1 then
	local opt2 = SCENE_MENU.options[SCENE_MENU.optionIdx - 1]
        addDraw(svg("text", {x=220, y=700, class="item"}, {opt2.name}))
    end
    local choice = SCENE_MENU.options[SCENE_MENU.optionIdx]
    addDraw(svg("text", {x=220, y=800, class="choice"}, {choice.name}))
    if #SCENE_MENU.options > (SCENE_MENU.optionIdx) then
	local opt3 = SCENE_MENU.options[SCENE_MENU.optionIdx + 1]
        addDraw(svg("text", {x=220, y=900, class="item"}, {opt3.name}))
    end
    if #SCENE_MENU.options > (SCENE_MENU.optionIdx + 1) then
	local opt4 = SCENE_MENU.options[SCENE_MENU.optionIdx + 2]
        addDraw(svg("text", {x=220, y=1000, class="item"}, {opt4.name}))
    end
end

function SCENE_MENU.onKeyUP()
    SCENE_MENU.optionIdx = SCENE_MENU.optionIdx - 1
    if SCENE_MENU.optionIdx < 1 then
        SCENE_MENU.optionIdx = 1
    end
end

function SCENE_MENU.onKeyDOWN()
    SCENE_MENU.optionIdx = SCENE_MENU.optionIdx + 1
    if SCENE_MENU.optionIdx > #SCENE_MENU.options then
        SCENE_MENU.optionIdx = #SCENE_MENU.options
    end
end

function SCENE_MENU.onKeyBUTTON()
    choice = SCENE_MENU.options[SCENE_MENU.optionIdx]
    if choice.scene then
	setScene(choice.scene)
    end
end
