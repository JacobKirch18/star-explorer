-- StarExplorer

require "io"

-- Start physics with no gravity
local physics = require("physics")
physics.start()
physics.setGravity(0, 0)

-- Seed the random number generator
math.randomseed(os.time())

-- Configure image sheet
    -- asteroid 1, 2, 3
    -- ship
    -- laser
local sheetOptions = 
{
    frames =
    {
        {
            x = 0,
            y = 0,
            width = 102,
            height = 85
        },
        {
            x = 0,
            y = 85,
            width = 90,
            height = 83
        },
        {
            x = 0,
            y = 168,
            width = 100,
            height = 97
        },
        {
            x = 0,
            y = 265,
            width = 98,
            height = 79
        },
        {
            x = 98,
            y = 265,
            width = 14,
            height = 40
        },
    },
}

-- Load the sprite sheet
local objectSheet = graphics.newImageSheet("gameObjects.png", sheetOptions)

-- Initialize variables
local lives = 3
local score = 0
local highScore = 0
local died = false
gameLoopSpeed = 1000

local asteroidsTable = {}
local ship
local gameLoopTimer
local livesText
local scoreText
local highScoreText
local gameOverText

local file = io.open("../Corona Projects/StarExplorerHighScore/highScore.txt", "r")
if file then
    highScore = tonumber(file:read("*a")) or 0
    io.close(file)
end

-- Set up display groups
local backGroup = display.newGroup()
local mainGroup = display.newGroup()
local uiGroup = display.newGroup()

-- Load the background
local background = display.newImageRect(backGroup, "background.png", 800, 1400)
background.x = display.contentCenterX
background.y = display.contentCenterY

-- Load and configure the ship from image sheet
ship = display.newImageRect(mainGroup, "falcon.png", 150, 120)
-- ship = display.newImageRect(mainGroup, objectSheet, 4, 98, 79)
ship.x = display.contentCenterX
ship.y = display.contentHeight - 100
physics.addBody(ship, {radius = 40, isSensor = true})
ship.myName = "ship"

-- Display lives and score
livesText = display.newText(uiGroup, "Lives: " .. lives, 256, 80, native.systemFont, 36)
scoreText = display.newText(uiGroup, "Score: " .. score, 512, 80, native.systemFont, 36)
highScoreText = display.newText(uiGroup, "High Score: " .. highScore, 384, 160, native.systemFont, 36)

-- Hide the status bar
display.setStatusBar(display.HiddenStatusBar)

-- Functions to update lives and score
local function update()
    livesText.text = "Lives: " .. lives
    scoreText.text = "Score: " .. score
    highScoreText.text = "High Score: " .. highScore
end

local function createAsteroid()

    local newAsteroid = display.newImageRect(mainGroup, objectSheet, 1, 102, 85)
    table.insert(asteroidsTable, newAstroid)
    physics.addBody( newAsteroid, "dynamic", { radius = 40, bounce = 0.8 } )
    newAsteroid.myName = "asteroid"

    local whereFrom = math.random(3)
    if (whereFrom == 1) then 
        -- From the left
        newAsteroid.x = -60
        newAsteroid.y = math.random(500)
        newAsteroid:setLinearVelocity(math.random(40, 120), math.random(20, 60))
    elseif (whereFrom == 2) then
        -- From the top
        newAsteroid.x = math.random(display.contentWidth)
        newAsteroid.y = -60
        newAsteroid:setLinearVelocity(math.random(-40, 40), math.random(40, 120))
    elseif (whereFrom == 3) then
        -- From the right
        newAsteroid.x = display.contentWidth + 60
        newAsteroid.y = math.random(500)
        newAsteroid:setLinearVelocity(math.random(-120, -40), math.random(20, 60))
    end

    newAsteroid:applyTorque(math.random(-6, 6))

end

local function fireLaser()

    local newLaser = display.newImageRect(mainGroup, objectSheet, 5, 14, 40)
    physics.addBody(newLaser, "dynamic", {isSensor = true})
    newLaser.isBullet = true
    newLaser.myName = "laser"

    newLaser.x = ship.x
    newLaser.y = ship.y
    newLaser:toBack()

    transition.to(newLaser, {y = -40, time = 500, 
        onComplete = function() display.remove(newLaser) end
    })

end

ship:addEventListener("tap", fireLaser)

local function dragShip(event)

    local ship = event.target
    local phase = event.phase

    if ("began" == phase) then
        display.currentStage:setFocus(ship)
        ship.touchOffsetX = event.x - ship.x
        ship.touchOffsetY = event.y - ship.y
    elseif ("moved" == phase) then
        ship.x = event.x - ship.touchOffsetX
        ship.y = event.y - ship.touchOffsetY
    elseif ("ended" == phase or "cancelled" == phase) then
        display.currentStage:setFocus(nil)
    end

    return true

end

ship:addEventListener("touch", dragShip)

local function gameLoop()

    createAsteroid()

    for i = #asteroidsTable, 1, -1 do 

        local thisAsteroid = asteroidsTable[i]

        if (thisAsteroid.x < -100 or 
            thisAsteroid.x > display.contentWidth + 100 or 
            thisAsteroid.y < -100 or 
            thisAsteroid.y > display.contentHeight + 100) 
        then
            display.remove(thisAsteroid)
            table.remove(asteroidsTable, i)
        end
    end

    if (gameLoopSpeed > 25) then
        gameLoopSpeed = gameLoopSpeed - 25
    end 

end

gameLoopTimer = timer.performWithDelay( gameLoopSpeed, gameLoop, 0 )

local function restoreShip()

    ship.isBodyActive = false
    ship.x = display.contentCenterX
    ship.y = display.contentHeight - 100

    -- Fade in the ship
    transition.to(ship, {alpha = 1, time = 4000, 
        onComplete = function() 
            ship.isBodyActive = true
            died = false
        end
    })

end

local function onCollision(event) 

    if (event.phase == "began") then
        local obj1 = event.object1
        local obj2 = event.object2
    

        if ((obj1.myName == "laser" and obj2.myName == "asteroid") or
            (obj1.myName == "asteroid" and obj2.myName == "laser"))
        then
            display.remove(obj1)
            display.remove(obj2)

            for i = #asteroidsTable, 1, -1 do
                if (asteroidsTable[i] == obj1 or asteroidsTable[i] == obj2) then
                    table.remove(asteroidsTable, i)
                    break
                end
            end

            score = score + 100
            scoreText.text = "Score: " .. score
            if (score > highScore) then
                highScore = score
                highScoreText.text = "High Score: " .. highScore

                local file = io.open("../Corona Projects/StarExplorerHighScore/highScore.txt", "w")
                if file then
                    file:write(highScore)
                    io.close(file)
                end
            end

        elseif ((obj1.myName == "ship" and obj2.myName == "asteroid") or
                (obj1.myName == "asteroid" and obj2.myName == "ship"))
        then
            if (died == false) then
                died = true

                lives = lives - 1
                livesText.text = "Lives: " .. lives

                if (lives == 0) then
                    display.remove(ship)
                    gameOverText = display.newText(uiGroup, "Game Over", 384, 512, native.systemFont, 64)
                else
                    ship.alpha = 0
                    timer.performWithDelay(1000, restoreShip)
                end
            end
        end
    end
end

Runtime:addEventListener("collision", onCollision)
