function love.load()
    BOAT_A0 = 16
    BOAT_T0 = 400
    MOUSE_SCALE = 3200

    boatstate = {
        velocity = {0,0,0,0},
        position = {0,0,0,0},
        friction = 0.22,
        angAccel = 0,
        thrust = 0
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

    love.sensitivityStep = 0
    love.delta=0
    love.mouse.setRelativeMode( true )

    F = function (dt,mu)
            local f0 = math.exp(-mu*dt)
            local f1 = (1-f0)/mu
            local f2 = (dt-f1)/mu
           return f0, f1, f2
        end

    A = function (w,a,s,d,mouse)
            local nx, nz = math.min( math.max( (d and 1 or 0) + (a and -1 or 0) + mouse , -1 ) , 1 ) , (w and 1 or 0) + (s and -1 or 0)
            local ax, az = nx , nz>0  and  1   or (
                                nz<0  and -1/8 or (
                                nx==0 and  0   or (
                                math.abs(nx)/8  )))
           return ax, az
        end
end

function love.mousemoved( x, y, dx, dy, istouch )
    love.delta = love.delta + dx*2^(love.sensitivityStep/12)
end

function love.wheelmoved( x, y )
    love.sensitivityStep = love.sensitivityStep + y
end

function love.keyreleased(key, scancode)
   if key == "escape" then
      love.event.quit()
   elseif key == "r" then
      boatstate = {
        velocity = {0,0,0,0},
        position = {0,0,0,0},
        friction = boatstate.friction,
        angAccel = 0,
        thrust = 0
      }
   elseif key == "1" then
      boatstate.friction = 0.22
   elseif key == "2" then
      boatstate.friction = 0.4
   elseif key == "3" then
      boatstate.friction = 2.0
   elseif key == "4" then
      boatstate.friction = 8.0
   end
end

function love.update(dt)
    local dx, ang, _ = love.delta, boatstate.position[4]*math.pi/180, love.keyboard.isDown
    local ax, az = A( _('w') , _('a') , _('s') , _('d') , dx/dt/MOUSE_SCALE )
    local cos , sin = math.cos(ang), math.sin(ang)
    local d0, v0, a0 = boatstate.position , boatstate.velocity, {BOAT_A0*az*cos, 0 , BOAT_A0*az*sin , BOAT_T0*ax} 
    local f0, f1, f2 = F(dt,boatstate.friction)
    for i=1,4 do
        boatstate.velocity[i] = a0[i]*f1 + v0[i]*f0
        boatstate.position[i] = a0[i]*f2 + v0[i]*f1 + d0[i] 
    end
    boatstate.position[4] = ( ( boatstate.position[4] + 180 ) % 360) - 180
    if ax==0 and 1e-8 > boatstate.velocity[4]*boatstate.velocity[4] then boatstate.velocity[4] = 0 end
    if az==0 and 1e-8 > boatstate.velocity[1]*boatstate.velocity[1] + boatstate.velocity[3]*boatstate.velocity[3] then
       boatstate.velocity[1]=0
       boatstate.velocity[3]=0
    end
    love.delta = love.delta - dx
    boatstate.angAccel = ax
    boatstate.thrust = az
end

function love.draw()
    local n=1
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local cx, cy = windowWidth/2 , windowHeight/2
    local r, ang = math.sqrt(cx*cx+cy*cy) , boatstate.position[4]*math.pi/180
    local dx, dy, dr, ax, az = 1.5*r/n/2/16, 2*r/n/2/16, r/n, boatstate.angAccel/2, boatstate.thrust/2
    local R11, R12 =  math.sin(-ang), math.cos(-ang)
    local R21, R22 = -math.cos(-ang), math.sin(-ang)
    local x0, y0 = ((boatstate.position[1]/16+0.5)%1)-0.5, ((boatstate.position[3]/16+0.5)%1)-0.5
    love.graphics.setColor(1,1,1)
    for i=1,22 do
        local r1 , r2 , r3 , r4 = GRIDPAIRS[i][1]-x0 , GRIDPAIRS[i][2]-y0 , GRIDPAIRS[i][3]-x0 , GRIDPAIRS[i][4]-y0
        local x1 , x2 = R11*r1 + R12*r2 , R11*r3 + R12*r4
        local y1 , y2 = R21*r1 + R22*r2 , R21*r3 + R22*r4
        love.graphics.line(dr*x1+cx,dr*y1+cy,dr*x2+cx,dr*y2+cy)
    end
    love.graphics.print(boatstate.position[1] .. ',' .. boatstate.position[2] .. ',' .. boatstate.position[3] .. ' (' .. boatstate.position[4] .. ')\n' ..
                        boatstate.velocity[1] .. ',' .. boatstate.velocity[2] .. ',' .. boatstate.velocity[3] .. ' (' .. boatstate.velocity[4] .. ')\n' ..
                        'Sensitivity: ' .. 2^(love.sensitivityStep/12) .. ' (step '  .. love.sensitivityStep .. ', scroll to adjust) \n' ..
                        'Press 1/2/3/4 to set friction to Blue/Pack/Air/Gnd\n' ..
                        'Press R to reset, Esc to exit.')
    love.graphics.setColor(181/256,153/256,104/256)
    love.graphics.rectangle('fill',cx-dx,cy-dy,2*dx,2*dy)
    love.graphics.setColor(0,1,1)
    love.graphics.line(cx,cy,cx+ax*r/n,cy)
    love.graphics.setColor(1,0,0)
    love.graphics.line(cx,cy,cx,cy-az*r/n)
    love.graphics.setColor(0,1,0)
    love.graphics.printf(math.sqrt(boatstate.velocity[1]*boatstate.velocity[1]+boatstate.velocity[3]*boatstate.velocity[3]) .. ' m/s\n' .. 'mu=' .. boatstate.friction,0,cy+dy,windowWidth,"center")
end
