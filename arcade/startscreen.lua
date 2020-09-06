-- makeStartScene creates a scene that has a few bindings
-- and updates. 'gamescene' object passed must have:
-- scene.name, scene.author, scene.helptext, scene.dataid (a normalized string like 'ast')
function makeStartScene(gamescene)
    local scene = {}

    local highscore_scene = makeHighScoreScene(scene, gamescene.dataid)
    gamescene.highscore_scene = highscore_scene

    scene.render = function()
        -- Draw intro GUI screen.
        -- Text styles used:
        addDraw(svg("style", nil, {[[
            .title { font: bold italic 200px sans-serif; fill: white; }
            .byline { font: bold italic 80px sans-serif; fill: yellow; }
            .instr { font: bold 80px sans-serif; fill: blue; }
        ]]}))
        addDraw(svg("text", {x=220, y=280, class="title"}, {gamescene.name}))
        addDraw(svg("text", {x=320, y=500, class="byline"}, {"By " .. gamescene.author}))
        addDraw(svg("text", {x=320, y=800, class="instr"}, {gamescene.helptext}))
        addDraw(svg("text", {x=320, y=900, class="instr"}, {"Press SPACE start!"}))
        addDraw(svg("text", {x=320, y=960, class="instr"}, {"Press C to view High Scores"}))
        addDraw(svg("text", {x=320, y=1020, class="instr"}, {"Press Q to return to Main Menu"}))
    end
    scene.onKeyBUTTON = function()
	setScene(gamescene)
    end
    scene.onKeyBUTTON2 = function()
	setScene(highscore_scene)
    end
    scene.onKeyQ = function()
	setScene(SCENE_MENU)
    end
    return scene
end

function makeAndRegisterGame(gamescene)
    local startscene = makeStartScene(gamescene)
    registerGame(gamescene.name, startscene)
end
