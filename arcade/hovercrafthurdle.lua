local function makeHurdleScene()
    local scene = {
        name = "Hovercraft Hurdle",
        author = "Sixtysixone",
        helptext = "SPACE to accelerate up",
        dataid = "hch",
    }

    local SPEED_X = 150
    local ACCEL_Y = 150
    local MAX_SPEED_Y = 300
    local SHIP_X = 100
    local SHIP_WIDTH = 40
    local SHIP_HEIGHT = 30
    local WALL_WIDTH = 20
    local SCORE_PER_UNIT = 1

    -- Game state variables:
    local SHIP = {}
    local SCORE = 0.0
    local MAYBE_SCORE = 0.0
    local GAME_TIME = 0.0
    local NEXT_SPAWN = 0.0
    local WALLS = {}

    scene.saveState = function()
        if GAME_TIME > 3.0 then
            return {
                SHIP = SHIP,
                GAME_TIME = GAME_TIME,
                NEXT_SPAWN = NEXT_SPAWN,
                MAYBE_SCORE = MAYBE_SCORE,
                WALLS = WALLS,
            }
        end
    end

    local function spawnWall(pos)
        local hole = math.random(250, 800)
        local wall = {
            posX = pos,
            middle = hole,
            bottom = hole + 100,
            top = hole - 100,
        }
        table.insert(WALLS, wall)
    end

    local function resetGame()
      GAME_TIME = 0.0
      NEXT_SPAWN = 3.0
      SCORE = 0.0
      MAYBE_SCORE = 0.0
      SHIP = {
        posX = SHIP_X,
        posY = SCREEN_Y/2,
        velY = 0.0,
      }
      WALLS = {}
      spawnWall(1100)
      spawnWall(1400)
      spawnWall(1700)
      spawnWall(2000)
    end

    scene.start = function(state)
        if false and state and state.SHIP and state.GAME_TIME then
            system.print("we have data to load")
            SHIP = state.SHIP
            GAME_TIME = state.GAME_TIME
            NEXT_SPAWN = state.NEXT_SPAWN
            MAYBE_SCORE = state.MAYBE_SCORE
            WALLS = state.WALLS
        else
            resetGame()
        end
    end

    local function moveShip(secs)
      -- Move the ship
      SHIP.posY = SHIP.posY + SHIP.velY * secs

      local accel = ACCEL_Y * secs
      if keyState("BUTTON") > 0 then
          accel = -ACCEL_Y * secs
      end

      SHIP.velY = SHIP.velY + accel
      if SHIP.velY > MAX_SPEED_Y then
          SHIP.velY = MAX_SPEED_Y
      elseif SHIP.velY < -MAX_SPEED_Y then
          SHIP.velY = -MAX_SPEED_Y
      end

      if SHIP.posY < 25 then
          SHIP.posY = 25
          SHIP.velY = 0
      elseif SHIP.posY > (SCREEN_Y - 25) then
          SHIP.posY = SCREEN_Y - 25
          SHIP.velY = 0
      end
    end

    local function drawShip()
        addDraw(svg("polyline", {
            transform=string.format('translate(%d %d)', math.floor(SHIP.posX), math.floor(SHIP.posY)),
            points = "-20,-20 -15,-20 -10,-15 20,-15 20,10 15,20 -15,20 -20,15 -20,-20",
            stroke = "green",
            strokeWidth = "6",
        }))
    end

    local function drawWalls()
        for w, wall in pairs(WALLS) do
            addDraw(svg("rect", {
                x = math.floor(wall.posX - WALL_WIDTH/2),
                y = 0,
                height = math.floor(wall.top),
                fill = "white",
                width = WALL_WIDTH,
            }))
            addDraw(svg("rect", {
                x = math.floor(wall.posX - WALL_WIDTH/2),
                y = wall.bottom,
                height = math.floor(SCREEN_Y - wall.bottom),
                fill = "white",
                width = WALL_WIDTH,
            }))
        end
    end

    local function moveWalls(secs)
        local old = WALLS
        WALLS = {}
        for w, wall in pairs(old) do
            wall.posX = wall.posX - (secs * SPEED_X)
            if wall.posX > -20 then
                table.insert(WALLS, wall)
            end
        end
    end

    local function endGame()
        HIGHSCORES.addHighScore(scene.dataid, system.getPlayerName(unit.getMasterPlayerId()), math.floor(SCORE))
        GAME_TIME = 0.0
        setScene(scene.highscore_scene)
    end

    local function checkCollisions()
        -- We can only ever hit the 1st wall
        local wall = WALLS[1]
        if wall.posX < (SHIP_X + (WALL_WIDTH/2 + SHIP_WIDTH/2)) and wall.posX > (SHIP_X - (WALL_WIDTH/2 + SHIP_WIDTH/2)) then
            if wall.top > (SHIP.posY - SHIP_HEIGHT/2) then
                endGame()
                return true
            elseif wall.bottom < (SHIP.posY + SHIP_HEIGHT/2) then
                endGame()
                return true
            else
                local dist = (math.abs(SHIP.posY - wall.middle)/5)
                local dscore = math.floor(dist*dist*SCORE_PER_UNIT)
                if dscore > MAYBE_SCORE then
                    MAYBE_SCORE = dscore
                end
            end
        elseif MAYBE_SCORE > 0.0 then
            SCORE = SCORE + MAYBE_SCORE
            MAYBE_SCORE = 0.0
        end
        return false
    end

    local function drawGUI()
        addDraw(svg("style", nil, {[[
          .score { font: bold 60px sans-serif; fill: white; stroke-width: 3; stroke-color: black; }
        ]]}))
        addDraw(svg("text", {x=SCREEN_X/2 - 60, y=SCREEN_Y-90, class="score"}, {string.format("SCORE: %d", math.floor(SCORE))}))
    end

    scene.update = function(secs)
        -- Add asteroid definitions
        GAME_TIME = GAME_TIME + secs

        if GAME_TIME > NEXT_SPAWN then
            spawnWall(2000)
            NEXT_SPAWN = GAME_TIME + 2.0 + (math.random() * 2.0)
        end
        moveShip(secs)
        moveWalls(secs)
        if not checkCollisions() then
          drawShip()
          drawWalls()
          drawGUI()
        end
    end
    return scene
end

makeAndRegisterGame(makeHurdleScene())
