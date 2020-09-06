function makeHighScoreScene(startscene, gamename)
    local scene = {}
    scene.render = function()
	HIGHSCORES.render(gamename)
    end
    scene.onKeyBUTTON = function()
	setScene(startscene)
    end
    scene.onKeyBUTTON2 = scene.onKeyBUTTON
    scene.onKeyQ = scene.onKeyBUTTON
    return scene
end

HIGHSCORES = {}

function HIGHSCORES.getHighScores(gamename)
    local scores = {}
    for i = 1,5,1 do
        if alldata.hasKey(gamename .. "n" .. i) then
          scores[#scores+1] = {
              alldata.getIntValue(gamename .. "s" .. i),
              alldata.getStringValue(gamename .. "n" .. i),
          }
        end
    end
    return scores
end

function HIGHSCORES.addHighScore(gamename, name, total)
    -- We have 15 values in our databank.
    -- 10 for high score: 1 string + 1 number
    -- 5 for recent: strings only

    local scores = HIGHSCORES.getHighScores(gamename)
    local newscores = {}
    local done = false
    for i = 1,5,1 do
        if not done and total > 0 and total > scores[i][1] then
            newscores[#newscores+1] = {total, name}
            done = true
        end
        newscores[#newscores+1] = scores[i]
    end
    if #newscores < 5 then
        newscores[#newscores+1] = {total, name}
    end
    if done then
      for i = 1,5,1 do
          if #newscores >= i then
              alldata.setIntValue(gamename .. "s" .. i, newscores[i][1])
              alldata.setStringValue(gamename .. "n" .. i, newscores[i][2])
          end
      end
    end

    -- Rotate recent scores
    for i = 4,1,-1 do
        if alldata.hasKey(gamename .. "r" .. i) then
            alldata.setStringValue(gamename .. "r" .. (i + 1), alldata.getStringValue(gamename .. "r" .. i))
        end
    end
    system.print("Setting " .. gamename .. "r1" .. string.format("%.10d %s", total, name))
    alldata.setStringValue(gamename .. "r1", string.format("%.10d %s", total, name))
end

HIGHSCORES.render = function(gamename)
    local highs = HIGHSCORES.getHighScores(gamename)
    addDraw(svg("style", nil, {[[
        .title { font: bold italic 120px fixed; fill: white; }
        .score { font: bold 60px fixed; fill: yellow; }
    ]]}))
    addDraw(svg("text", {x=320, y=160, class="title"}, {"High Scores - " .. gamename}))
    for i = 1,5,1 do
        if highs[i] then
            addDraw(svg("text", {x=320, y=180 + 50*i, class="score"}, {string.format("%.10d %s", highs[i][1], highs[i][2])}))
        end
    end

    addDraw(svg("text", {x=320, y=600, class="title"}, {"Recent Scores:"}))
    for i = 1,5,1 do
        if alldata.hasKey(gamename .. "r" .. i) then
            addDraw(svg("text", {x=320, y=640 + 50*i, class="score"}, {alldata.getStringValue(gamename .. "r" .. i)}))
        end
    end
end
