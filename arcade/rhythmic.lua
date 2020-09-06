local function makeRhythmScene()
    local scene = {
        name = "Key Rhythm",
        author = "Sixtysixone",
        helptext = "W, A, S and D, and space when they turn white",
        dataid = "rhythm",
    }

    local GAME_TIME = 0.0
    local X_PER_SECOND = 500
    local ZERO_OFFSET = 300
    local RHYTHM_OFFSET = 1.0
    local MAX_RANK = 30
    local RANK_MISSED = -3
    local RANK_WRONG = -2
    local RANK_GOOD = 1
    local ENDED = false
    local END_TIMER = 0.0

    local RHYTHM_END = 0.0
    local KEYS = {}
    local SCORE = {}

    local SCORE_GOOD = 50
    local SCORE_OKAY = 20

    scene.saveState = function()
    end

    local KEYPOS = {
      W = 200,
      A = 300,
      S = 400,
      D = 500,
      _ = 700,
    }

    local function resetGame()
        GAME_TIME = 0.0
        KEYS = {}
        RHYTHM_END = 2.0
        ENDED = false
        END_TIMER = 0.0
        SCORE = {
            total = 0,
            bonus = 0,
            rank = 20,
        }
    end

    scene.start = function(state)
        if false and state and state.SHIP and state.GAME_TIME then
        else
            resetGame()
        end
    end

    local function drawKeys()
        for k, key in pairs(KEYS) do
            local tdiff = key.time - GAME_TIME
            local xpos = tdiff * X_PER_SECOND + ZERO_OFFSET
            local cls = key.class
            if cls == "upcoming" and math.abs(key.time - GAME_TIME) < 0.2 then
                cls = "now"
            end
            addDraw(svg(
                "text", {
                    x=xpos,
                    y=KEYPOS[key.key],
                    class=cls,
                },
                {key.key}
            ))
        end
        addDraw(svg("line", {
            x1=ZERO_OFFSET,
            y1=0,
            x2=ZERO_OFFSET,
            y2=SCREEN_Y,
            stroke = "green",
            strokeWidth = "3",
        }))
    end

    local function endGame()
        HIGHSCORES.addHighScore(scene.dataid, system.getPlayerName(unit.getMasterPlayerId()), math.floor(SCORE.total))
        GAME_TIME = 0.0
        END_TIMER = 3.0
        ENDED = true
    end

    local function shuffle(x)
        shuffled = {}
        for i, v in ipairs(x) do
          	local pos = math.random(1, #shuffled+1)
          	table.insert(shuffled, pos, v)
        end
        return shuffled
    end

    local function makeRhythm()
        local complexity = math.floor(70 - (GAME_TIME/2))
        local beat_time = 0.5
        while complexity < 0 do
            beat_time = beat_time * 0.9
            complexity = complexity + 20
        end
        local ktime = RHYTHM_END
        local beat_len = math.random(3,5)
        local repeat_len = math.random(2,4)
        RHYTHM_END = ktime + ((beat_len * beat_time) * repeat_len) + RHYTHM_OFFSET

        local beat = {}
        for i=1,beat_len,1 do
            local rand = math.random(100) - complexity
            local keys = shuffle({"W", "A", "S", "D", "_"})
            local n = 1
            while rand > 0 and n < 4 do
                rand = rand - 40
                table.insert(beat, {
                    key= keys[n],
                    time= i * beat_time,
                })
                n = n + 1
            end
        end
        for j=1,repeat_len,1 do
            local offt = ktime + (j-1) * (beat_len * beat_time)
            for i=1,#beat,1 do
                local k = beat[i]
                table.insert(KEYS, {
                    key= k.key,
                    time= offt + k.time,
                    class = "upcoming",
                })
            end
        end
    end

    local function updateKeys()
        -- Filter out passed keys
        local old = KEYS
        KEYS = {}
        for k, key in ipairs(old) do
            if key.time > (GAME_TIME - 3.0) then
                table.insert(KEYS, key)
            end
            if key.time < (GAME_TIME - 0.3) and key.class == "upcoming" then
                key.class = "missed"
                SCORE.bonus = 0
                SCORE.rank = SCORE.rank + RANK_MISSED
            end
        end
        while RHYTHM_END < (GAME_TIME + 30.0) do
            makeRhythm()
        end
    end

    local function hitkey(hit)
        local good = false
        for k, key in ipairs(KEYS) do
            if key.time > (GAME_TIME + 0.3) then
              break
            end
            if key.class == "upcoming" and key.time > (GAME_TIME - 0.3) then
              if key.key == hit then
                  if math.abs(key.time - GAME_TIME) < 0.1 then
                      SCORE.total = SCORE.total + SCORE.bonus + SCORE_GOOD
                      SCORE.bonus = SCORE.bonus + 2
                      key.class = "good"
                  else
                      SCORE.total = SCORE.total + SCORE_OKAY
                      key.class = "okay"
                  end
                  good = true
                  break
              end
            end
        end
        if good then
            SCORE.rank = SCORE.rank + RANK_GOOD
            if SCORE.rank > MAX_RANK then
                SCORE.rank = MAX_RANK
            end
        else
            SCORE.bonus = 0
            SCORE.rank = SCORE.rank + RANK_WRONG
        end
    end

    local function checkRank()
        if SCORE.rank < 0 then
            endGame()
        end
    end

    local function getRankSym()
        if SCORE.rank == 30 then
            return "S"
        elseif SCORE.rank > 25 then
            return "A"
        elseif SCORE.rank > 15 then
            return "B"
        elseif SCORE.rank > 5 then
            return "C"
        else
            return "D"
        end
    end

    scene.onKeyUP = function() hitkey("W") end
    scene.onKeyDOWN = function() hitkey("S") end
    scene.onKeyLEFT = function() hitkey("A") end
    scene.onKeyRIGHT = function() hitkey("D") end
    scene.onKeyBUTTON = function() hitkey("_") end

    local function drawGUI()
        addDraw(svg("text", {x=SCREEN_X/2 - 60, y=SCREEN_Y-90, class="score"}, {string.format("RANK: %s SCORE: %d", getRankSym(), math.floor(SCORE.total))}))
    end

    scene.update = function(secs)
        addDraw(svg("style", nil, {[[
          .upcoming { font: bold 120px sans-serif; fill: #bbbbbb; }
          .now { font: bold 120px sans-serif; fill: #ffffff; }
          .good { font: bold 120px sans-serif; fill: #00ff00; }
          .okay { font: bold 120px sans-serif; fill: #009900; }
          .missed { font: bold 120px sans-serif; fill: #ff0000; }
          .score { font: bold 60px sans-serif; fill: white; }
          .ended { font: bold 60px sans-serif; fill: white; }
        ]]}))

        drawKeys()
        drawGUI()

        if ENDED and END_TIMER > 0.0 then
          END_TIMER = END_TIMER - secs
          addDraw(svg("text", {x=SCREEN_X/2 - 80, y=SCREEN_Y/2 - 50, class="ended"}, {"GAME OVER"}))
          if END_TIMER <= 0.0 then
              setScene(scene.highscore_scene)
          end
        else
          GAME_TIME = GAME_TIME + secs
          updateKeys()
          checkRank()
        end
    end
    return scene
end

makeAndRegisterGame(makeRhythmScene())
