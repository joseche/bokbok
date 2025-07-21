

PLAYER_WIDTH_IMAGE = 512
PLAYER_HEIGHT_IMAGE = 512

PLAYER_WIDTH_SCREEN = 128
PLAYER_HEIGHT_SCREEN = 128

SCALE = 1/2

function love.load()
    wf = require 'libraries/windfield/windfield'
    anim8 = require 'libraries.anim8.anim8'

    sprites = {}
    sprites.playerSheet = love.graphics.newImage('sprites/bokbok-sprite.png')
    local grid = anim8.newGrid(PLAYER_WIDTH_IMAGE, PLAYER_HEIGHT_IMAGE, sprites.playerSheet:getWidth(), sprites.playerSheet:getHeight())

    animations = {}
    animations.idle = anim8.newAnimation(grid('1-2', 1), 1.0)
    animations.walk = anim8.newAnimation(grid('1-2', 2), 0.08)
    animations.fly = anim8.newAnimation(grid('1-2', 3), 0.01)

    world = wf.newWorld(0, 1200, false)
    world:setQueryDebugDrawing(true)
    world:addCollisionClass('Player')
    world:addCollisionClass('Platform')
    world:addCollisionClass('Danger')

    platform = world:newRectangleCollider(200, 400, 400, 50, {collision_class = 'Platform'})
    platform:setType('static')

    dangerzone = world:newRectangleCollider(0, 550, 800, 50, {collision_class = 'Danger'})
    dangerzone:setType('static')
    createPlayer()
end

function createPlayer()
    player = world:newRectangleCollider(360, 100, PLAYER_WIDTH_SCREEN, PLAYER_HEIGHT_SCREEN, {collision_class = 'Player'})
    player.animation = animations.idle
    player.speed = 250
    player.direction = 1
end

function destroyPlayer()
    player:destroy()
    player = nil
end

function recreatePlayer()
    destroyPlayer()
    createPlayer()
end

function playerUpdateStanding()
    if player.body then
        local half_x = PLAYER_WIDTH_SCREEN / 2
        local half_y = PLAYER_HEIGHT_SCREEN / 2
        colliders = world:queryRectangleArea(player:getX() - half_x, player:getY() + half_y, PLAYER_WIDTH_SCREEN, 2, {'Platform'})
        if #colliders > 0 then
            player.standing = true
        else
            player.standing = false
        end
    end
end

function love.update(dt)
    world:update(dt)

    if player.body then
        local px, _ = player:getPosition()
        playerUpdateStanding()
        if love.keyboard.isDown('right') then
            player:setX(px + player.speed * dt)
            player.direction = 1
        end
        if love.keyboard.isDown('left') then
            player:setX(px - player.speed * dt)
            player.direction = -1
        end

        if love.keyboard.isDown('right') or love.keyboard.isDown('left') then
            if player.standing then
                player.animation = animations.walk
            end
        else
            if player.standing then
                player.animation = animations.idle
            end
        end

        -- revive the user when it dies
        if player:enter('Danger') then
            recreatePlayer()
        end

        -- if it is standing on land
        if player:enter('Platform') then
            player.animation = animations.idle
            if love.keyboard.isDown('right') or love.keyboard.isDown('left') then
                player.animation = animations.walk
            end
        end

        if player.animation == animations.fly then
            if love.keyboard.isDown('up') then
                player.animation:update(dt)
            end
        else
            player.animation:update(dt)
        end
    end
end

function love.draw()
    world:draw()
    local px, py = player:getPosition()
    player.animation:draw(sprites.playerSheet, px, py, nil, SCALE * player.direction, SCALE, PLAYER_WIDTH_IMAGE/2, PLAYER_HEIGHT_IMAGE/2)
end

function love.keypressed(key)
    if key == 'up' then
        if player.body then
            if player.standing then
                player:applyLinearImpulse(0, -14000)
                player.animation = animations.fly
            else
                player:applyLinearImpulse(0, -6000)
                player.animation = animations.fly
            end
        end
    elseif key == 'q' then
        love.event.quit(0)
    end
end
