local function makeAsteroidsScene()
    local scene = {
        name = "Blasteroids",
        author = "Sixtysixone",
        helptext = "WDA to move, SPACE to fire",
        dataid = "ast",
    }

    local SHIP_MAX_SPEED = 240
    local SHIP_ACCEL = 100
    local SHIP_ROTATION_PER_SECOND = 120.0
    local MAX_BULLET_COUNT = 3
    local BULLET_SPEED = 400
    local ASTEROID_BIG = 60
    local ASTEROID_MEDIUM = 40
    local ASTEROID_SMALL = 25
    local MAX_ASTEROIDS = 12
    local MIN_ASTEROID_SPEED = 40
    local ASTEROID_SPEED_VARIATION = 80

    -- Game state variables:
    local SHIP = {}
    local SCORE = {}
    local GAME_TIME = 0.0
    local LAST_SPAWN = 0.0
    local ASTEROID_COUNT = 0
    local BULLETS = {}
    local ASTEROIDS = {}

    -- ASTEROID_DEFS is not kept between saves, but is regenerated every time a game
    -- is loaded or started.
    local ASTEROID_DEFS = ""

    scene.saveState = function()
        if SCORE.total < 1 then
            return nil
        else
            return {
                SHIP = SHIP,
                SCORE = SCORE,
                GAME_TIME = GAME_TIME,
                LAST_SPAWN = LAST_SPAWN,
                ASTEROID_COUNT = ASTEROID_COUNT,
                BULLETS = BULLETS,
                ASTEROIDS = ASTEROIDS,
            }
        end
    end

    local function getAsteroidDef(sz, elid)
        -- An asteroid is drawn as 16 vertices, almost all the same but slightly randomized.
        local vertices = {}
        for i = 1,16,1 do
            local angle = (((22.5 * i + math.random(-5,5)) % 360) / 180) * math.pi
            local vsz = sz - math.random(0,8)
            vertices[#vertices+1] = string.format("%d,%d", math.floor(math.cos(angle) * vsz), math.floor(math.sin(angle) * vsz))
        end
	vertices[#vertices+1] = vertices[1]
        return svg("polyline", {id=elid, points=table.concat(vertices, " "), strokeWidth=4, stroke="yellow"})
    end

    local function getAsteroidSvgs(sz)
        local ret = svg("defs", nil, {
            getAsteroidDef(ASTEROID_BIG, "a" .. ASTEROID_BIG),
            getAsteroidDef(ASTEROID_MEDIUM, "a" .. ASTEROID_MEDIUM),
            getAsteroidDef(ASTEROID_SMALL, "a" .. ASTEROID_SMALL),
        })
        return ret
    end

    local function getAsteroidPos()
        -- Pick a random place about 30 pixels OUTSIDE the screen.
        local pos = math.random()
        local fromdir = math.random(4)
        local dir = math.random(140) + 20

        if fromdir == 1 then
            -- On top
            return {
                posX = math.floor((pos * SCREEN_X) + 60)- 30,
                posY = -30,
                dir = (dir + 0) % 360
            }
        elseif fromdir == 2 then
            -- On the right side
            return {
                posX = SCREEN_X + 30,
                posY = math.floor((pos * SCREEN_Y) + 60)- 30,
                dir = (dir + 90) % 360
            }
        elseif fromdir == 3 then
            -- On bottom
            return {
                posX = math.floor((pos * SCREEN_X) + 180)- 30,
                posY = SCREEN_Y - 30,
                dir = (dir + 180) % 360
            }
        else
            -- On the left
            return {
                posX = -30,
                posY = math.floor((pos * SCREEN_Y) + 60)- 30,
                dir = (dir + 270) % 360,
            }
        end
    end


    local function spawnAsteroid(from)
        if #ASTEROIDS >= MAX_ASTEROIDS then
            return
        end
        LAST_SPAWN = GAME_TIME
        ASTEROID_COUNT = ASTEROID_COUNT + 1
        local ast = getAsteroidPos()
        ast.spd = MIN_ASTEROID_SPEED + math.random(ASTEROID_SPEED_VARIATION) + ASTEROID_COUNT
        ast.velX = math.cos((ast.dir / 180) * math.pi) * ast.spd
        ast.velY = math.sin((ast.dir / 180) * math.pi) * ast.spd
        ast.size = 60
        ast.alive = true
        ASTEROIDS[#ASTEROIDS+1] = ast
    end

    local function resetGame()
      GAME_TIME = 0.0
      LAST_SPAWN = 0.0
      SCORE = {
        total = 0,
        bonus = 0,
      }
      SHIP = {
        dir = 0,
        posX = SCREEN_X/2,
        posY = SCREEN_Y/2,
        speed = 0.0,
        velX = 0.0,
        velY = 0.0,
        size = 15,
      }
      BULLETS = {}
      ASTEROIDS = {}
      ASTEROID_COUNT = 0
      ASTEROID_DEFS = getAsteroidSvgs()

      for i = 1,10,1 do
          spawnAsteroid()
      end
    end

    scene.start = function(state)
        if state and state.SHIP and state.GAME_TIME then
            SHIP = state.SHIP
            SCORE = state.SCORE
            GAME_TIME = state.GAME_TIME
            LAST_SPAWN = state.LAST_SPAWN
            ASTEROID_COUNT = state.ASTEROID_COUNT
            BULLETS = state.BULLETS
            ASTEROIDS = state.ASTEROIDS
            ASTEROID_DEFS = getAsteroidSvgs()
        else
            resetGame()
        end
    end

    local function moveShip(secs)
      -- Move the ship
      SHIP.posX = SHIP.posX + SHIP.velX * secs
      SHIP.posY = SHIP.posY + SHIP.velY * secs

      -- Turn the ship
      local dirPressed = keyState("RIGHT") - keyState("LEFT")
      SHIP.dir = SHIP.dir + (dirPressed * SHIP_ROTATION_PER_SECOND * secs)
      if SHIP.dir < 0.0 then
          SHIP.dir = SHIP.dir + 360.0
      elseif SHIP.dir >= 360.0 then
          SHIP.dir = SHIP.dir - 360.0
      end

      if SHIP.posX < 0 then
        SHIP.posX = SHIP.posX + SCREEN_X
      elseif SHIP.posX > SCREEN_X then
        SHIP.posX = SHIP.posX - SCREEN_X
      end

      if SHIP.posY < 0 then
        SHIP.posY = SHIP.posY + SCREEN_Y
      elseif SHIP.posY > SCREEN_Y then
        SHIP.posY = SHIP.posY - SCREEN_Y
      end

      -- Accelerate the ship
      local oldX = SHIP.velX
      local oldY = SHIP.velY
      local speedPressed = keyState("UP")
      SHIP.velX = SHIP.velX + math.cos((SHIP.dir / 180) * math.pi) * speedPressed * SHIP_ACCEL * secs
      SHIP.velY = SHIP.velY + math.sin((SHIP.dir / 180) * math.pi) * speedPressed * SHIP_ACCEL * secs
      if math.sqrt(SHIP.velX * SHIP.velX + SHIP.velY * SHIP.velY) > SHIP_MAX_SPEED then
        SHIP.velX = oldX
        SHIP.velY = oldY
      end
    end

    local function drawShip()
        addDraw(svg("g",
            {
                transform=string.format('translate(%d %d)', math.floor(SHIP.posX), math.floor(SHIP.posY))
            },
            {svg("g", {transform=string.format("rotate(%d 0 0)", math.floor(SHIP.dir))},
            {
                svg("line", {x1="-20", y1="-20", x2="30", y2="0", stroke="green", strokeWidth='6'}),
                svg("line", {x1="-20", y1="20", x2="30", y2="0", stroke="green", strokeWidth='6'}),
                svg("line", {x1="-20", y1="20", x2="-20", y2="-20", stroke="green", strokeWidth='6'}),
            })}
        ))
    end

    scene.onKeyBUTTON = function()
        if #BULLETS < MAX_BULLET_COUNT then
            local velX = BULLET_SPEED * math.cos((SHIP.dir / 180) * math.pi) + SHIP.velX
            local velY = BULLET_SPEED * math.sin((SHIP.dir / 180) * math.pi) + SHIP.velY
            BULLETS[#BULLETS+1] = {
                posX = SHIP.posX,
                posY = SHIP.posY,
                velX = velX,
                velY = velY,
                size = 5,
                alive = true,
            }
        end
    end

    local function moveBullets(secs)
        local old = BULLETS
        BULLETS = {}
        for k, v in ipairs(old) do
            if v.alive then
              v.posX = v.posX + v.velX * secs
              v.posY = v.posY + v.velY * secs
              if v.posX > 0 and v.posX < SCREEN_X and v.posY > 0 and v.posY < SCREEN_Y then
                  addDraw(svg("circle", {cx=v.posX, cy=v.posY, r=5, fill="yellow"}))
                  BULLETS[#BULLETS+1] = v
              else
                  SCORE.bonus = 0
              end
            end
        end
    end
    local function getAsteroidSvg(ast)
        local attrs = {
            x = ast.posX,
            y = ast.posY,
        }
        attrs["xlink:href"] = "#a" .. ast.size
        return svg("use", attrs)
    end

    local function breakAsteroid(old)
        old.alive = false
        if old.size <= ASTEROID_SMALL then
            return
        end
        for i = 1,3,1 do
          local ast = {
              posX = old.posX + math.random(-20,20),
              posY = old.posY + math.random(-20,20),
              dir = old.dir + math.random(-30, 30),
          }
          ast.spd = old.spd + math.random(20, 40)
          ast.velX = math.cos((ast.dir / 180) * math.pi) * ast.spd
          ast.velY = math.sin((ast.dir / 180) * math.pi) * ast.spd
          if old.size == ASTEROID_BIG then
            ast.size = ASTEROID_MEDIUM
          elseif old.size == ASTEROID_MEDIUM then
            ast.size = ASTEROID_SMALL
          else
            -- wtf
            ast.size = ASTEROID_SMALL
          end
          ast.alive = true
          ASTEROIDS[#ASTEROIDS+1] = ast
        end
    end

    local function moveAsteroids(secs)
        local old = ASTEROIDS
        ASTEROIDS = {}
        for k, v in ipairs(old) do
            if v.alive then
              v.posX = v.posX + v.velX * secs
              v.posY = v.posY + v.velY * secs
              if v.posX > -30 and v.posX < SCREEN_X + 30 and v.posY > -30 and v.posY < SCREEN_Y + 30 then
                  addDraw(getAsteroidSvg(v))
                  ASTEROIDS[#ASTEROIDS+1] = v
              end
            end
        end
    end

    local function checkCollide(a, b)
      local dx = a.posX - b.posX
      local dy = a.posY - b.posY
      local dm = a.size + b.size
      if (dx * dx) + (dy * dy) < (dm * dm) then
        return true
      end
      return false
    end

    local function endGame()
        HIGHSCORES.addHighScore(scene.dataid, system.getPlayerName(unit.getMasterPlayerId()), SCORE.total)
	SCORE.total = 0
	setScene(scene.highscore_scene)
    end

    local function checkCollisions()
        for k, asteroid in pairs(ASTEROIDS) do
            if checkCollide(SHIP, asteroid) then
                endGame()
            end
            for b, bullet in pairs(BULLETS) do
              if checkCollide(bullet, asteroid) then
                bullet.alive = false
                if asteroid.size == ASTEROID_BIG then
                  SCORE.total = SCORE.total + SCORE.bonus + 5
                elseif asteroid.size == ASTEROID_MEDIUM then
                  SCORE.total = SCORE.total + SCORE.bonus + 10
                else
                  SCORE.total = SCORE.total + (SCORE.bonus * 2) + 20
                end
                SCORE.bonus = SCORE.bonus + 2
                breakAsteroid(asteroid)
                break
              end
            end
        end
    end

    local function drawGUI()
        addDraw(svg("style", nil, {[[
          .score { font: bold 60px sans-serif; fill: white; stroke-width: 3; stroke-color: black; }
        ]]}))
        addDraw(svg("text", {x=SCREEN_X/2 - 60, y=SCREEN_Y-90, class="score"}, {string.format("SCORE: %d", SCORE.total)}))
    end

    scene.update = function(secs)
        -- Add asteroid definitions
        addDraw(ASTEROID_DEFS)
        GAME_TIME = GAME_TIME + secs

        if (GAME_TIME - LAST_SPAWN) > 0.5 then
            spawnAsteroid()
        end
        moveShip(secs)
        moveBullets(secs)
        moveAsteroids(secs)
        drawShip()
        drawGUI()
        checkCollisions()
    end
    return scene
end

makeAndRegisterGame(makeAsteroidsScene())
