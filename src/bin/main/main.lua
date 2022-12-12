function love.load()
    BOAT_MU = 0.22
    BOAT_A0 = 16
    BOAT_T0 = 400
    MOUSE_SCALE = 3200
    love.sensitivityStep = 0
    boatstate = {
        velocity = {0,0,0,0},
        position = {0,0,0,0},
        accel = 0
    }
    GRIDPAIRS={}
    -- populate vertical lines
    for i=1,11 do
        GRIDPAIRS[i] = { i-6 , -5 , i-6 , 5 }
    end
    -- populate horizontal lines
    for i=12,22 do
        GRIDPAIRS[i]={-5,i-17,5,i-17}
    end
    love.delta=0
    love.mouse.setRelativeMode( true )
end

function love.draw()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local cx, cy = windowWidth/2 , windowHeight/2
    local r, ang = math.sqrt(cx*cx+cy*cy) , boatstate.position[4]*math.pi/180
    local dx, dy, dr, ax = 1.5*r/10, 2*r/10, r/5, boatstate.accel
    local R11, R12 = math.cos(-ang), math.sin(ang)
    local R21, R22 = math.sin(-ang), math.cos(ang)
    love.graphics.setColor(1,1,1)
    for i=1,22 do
        local x1 , x2 = R11*GRIDPAIRS[i][1] + R12*GRIDPAIRS[i][2] , R11*GRIDPAIRS[i][3] + R12*GRIDPAIRS[i][4]
        local y1 , y2 = R21*GRIDPAIRS[i][1] + R22*GRIDPAIRS[i][2] , R21*GRIDPAIRS[i][3] + R22*GRIDPAIRS[i][4]
        love.graphics.line(dr*x1+cx,dr*y1+cy,dr*x2+cx,dr*y2+cy)
    end
    love.graphics.print(boatstate.velocity[4]/6 .. ' rpm\n' .. boatstate.position[4] .. '\n' .. 'LogSensitivity: ' .. love.sensitivityStep .. ' (scroll to adjust)')
    love.graphics.setColor(181/256,153/256,104/256)
    love.graphics.rectangle('fill',cx-dx,cy-dy,2*dx,2*dy)
    love.graphics.setColor(0,1,0)
    love.graphics.line(cx,cy,cx+ax*dx,cy)
    love.graphics.setColor(1,0,0)
    love.graphics.line(cx,cy-dy,cx,cy+dy)
end

function love.update(dt)
    local key = 0
    if love.keyboard.isDown( 'a' ) then
        key = key - 1
    end
    if love.keyboard.isDown( 'd' ) then
        key = key + 1
    end
    local f0, f1, f2 = F(dt,BOAT_MU)
    local dx = love.delta
    local ax = math.max(-1,math.min(1,key+dx/dt/MOUSE_SCALE))
    local a0 = BOAT_T0*ax
    local v0 = boatstate.velocity[4]
    boatstate.position[4] = -180 + ((180 + boatstate.position[4] + a0*f2 + v0*f1) % 360)
    boatstate.velocity[4] = a0*f1 + v0*f0
    love.delta = love.delta - dx
    boatstate.accel = ax
end

function love.mousemoved( x, y, dx, dy, istouch )
    love.delta = love.delta + dx*2^(love.sensitivityStep/12)
end

function love.wheelmoved( x, y )
    love.sensitivityStep = love.sensitivityStep + y
end

function love.keypressed(key, scancode, isrepeat)
   if key == "escape" then
      love.event.quit()
   end
end

function F(dt,mu)
    local f0 = math.exp(-mu*dt)
    local f1 = (1-f0)/mu
    local f2 = (dt-f1)/mu
   return f0, f1, f2
end