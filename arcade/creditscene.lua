local SCENE_CREDITS = {}

SCENE_CREDITS.render = function(secs)
    -- Draw intro GUI screen.
    -- Text styles used:
    addDraw(svg("style", nil, {[[
        .title { font: bold italic 200px sans-serif; fill: white; }
        .byline { font: bold italic 80px sans-serif; fill: yellow; }
        .instr { font: bold 80px sans-serif; fill: blue; }
    ]]}))
    addDraw(svg("text", {x=220, y=280, class="title"}, {"RPO Arcade."}))
    addDraw(svg("text", {x=320, y=500, class="byline"}, {"By Sixtysixone"}))
    addDraw(svg("text", {x=320, y=900, class="instr"}, {"Press space to exit!"}))
end

SCENE_CREDITS.onKeyBUTTON = function()
    setScene(SCENE_MENU)
end

registerDefaultScene("Credits", SCENE_CREDITS)
