function love.load()
    love.window.setTitle('Use WASD and mouse to move boat - BoatSim')
    boat = {
        velocity = {0,0,0,0},
        position = {0,0,0,0},
        friction = 0.22,
        angAccel = 0,
        fwdAccel = 0,
        A0 = 16,
        T0 = 400,
        F = ( 
        function (dt,mu)
            local f0 = math.exp(-mu*dt)
            local f1 = (1-f0)/mu
            local f2 = (dt-f1)/mu
            return f0, f1, f2
        end ),
        A = (
        function (w,a,s,d,mouse)
            local  nx , nz = math.min( math.max( (d and 1 or 0) + (a and -1 or 0) + mouse , -1 ) , 1 ) , (w and 1 or 0) + (s and -1 or 0)
            return nx , nz>0  and  1   or (
                        nz<0  and -1/8 or (
                        nx==0 and  0   or (
                        math.abs(nx)/8  )))
        end )
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

    MOUSE_SCALE = 3200
    love.steerReactivity = 0
    love.delta=0
    love.mouse.setRelativeMode( true )
end

function love.mousemoved( x, y, dx, dy, istouch )
    love.delta = love.delta + dx*2^(love.steerReactivity/12)
end

function love.wheelmoved( x, y )
    love.steerReactivity = love.steerReactivity + y
end

function love.keyreleased(key, scancode)
   if key == "escape" then
      love.event.quit()
   elseif key == "r" then
      boat.velocity = {0,0,0,0}
      boat.position = {0,0,0,0}
      boat.angAccel = 0
      boat.fwdAccel = 0
   elseif key == "1" then
      boat.friction = 0.22
   elseif key == "2" then
      boat.friction = 0.4
   elseif key == "3" then
      boat.friction = 2.0
   elseif key == "4" then
      boat.friction = 8.0
   end
end

function love.update(dt)
    local dx, ang, k, m = love.delta, boat.position[4]*math.pi/180, love.keyboard.isDown, love.mouse.isDown
    local ax, az = boat.A( k('w') or m(5) , k('a') or m(1) , k('s') or m(4) , k('d') or m(2) , dx/dt/MOUSE_SCALE )
    local cos , sin = math.cos(ang), math.sin(ang)
    local d0, v0, a0 = boat.position , boat.velocity, {boat.A0*az*cos, 0 , boat.A0*az*sin , boat.T0*ax} 
    local f0, f1, f2 = boat.F(dt,boat.friction)
    for i=1,4 do
        boat.velocity[i] = a0[i]*f1 + v0[i]*f0
        boat.position[i] = a0[i]*f2 + v0[i]*f1 + d0[i] 
    end
    boat.position[4] = ( ( boat.position[4] + 180 ) % 360) - 180
    if ax==0 and 1e-8 > boat.velocity[4]*boat.velocity[4] then boat.velocity[4] = 0 end
    if az==0 and 1e-8 > boat.velocity[1]*boat.velocity[1] + boat.velocity[3]*boat.velocity[3] then
       boat.velocity[1]=0
       boat.velocity[3]=0
    end
    love.delta = love.delta - dx
    boat.angAccel = ax
    boat.fwdAccel = az
end

function love.draw()
    local n=1
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local cx, cy = windowWidth/2 , windowHeight/2
    local r, ang = math.sqrt(cx*cx+cy*cy) , boat.position[4]*math.pi/180
    local dx, dy, dr, ax, az = 1.5*r/n/2/16, 2*r/n/2/16, r/n, boat.angAccel/2, boat.fwdAccel/2
    local R11, R12 =  math.sin(-ang), math.cos(-ang)
    local R21, R22 = -math.cos(-ang), math.sin(-ang)
    local x0, y0 = ((boat.position[1]/16+0.5)%1)-0.5, ((boat.position[3]/16+0.5)%1)-0.5
    love.graphics.setColor(1,1,1)
    for i=1,22 do
        local r1 , r2 , r3 , r4 = GRIDPAIRS[i][1]-x0 , GRIDPAIRS[i][2]-y0 , GRIDPAIRS[i][3]-x0 , GRIDPAIRS[i][4]-y0
        local x1 , x2 = R11*r1 + R12*r2 , R11*r3 + R12*r4
        local y1 , y2 = R21*r1 + R22*r2 , R21*r3 + R22*r4
        love.graphics.line(dr*x1+cx,dr*y1+cy,dr*x2+cx,dr*y2+cy)
    end
    love.graphics.print(boat.position[1] .. ',' .. boat.position[2] .. ',' .. boat.position[3] .. ' (' .. boat.position[4] .. ')\n' ..
                        boat.velocity[1] .. ',' .. boat.velocity[2] .. ',' .. boat.velocity[3] .. ' (' .. boat.velocity[4] .. ')\n' ..
                        'SteerResponse: ' .. love.steerReactivity .. ' (scroll to adjust)\n' ..
                        'Press 1/2/3/4 to set surface to Blue/Pack/Air/Gnd\n' ..
                        'Press R to reset, Esc to exit.')
    love.graphics.setColor(181/256,153/256,104/256)
    love.graphics.rectangle('fill',cx-dx,cy-dy,2*dx,2*dy)
    love.graphics.setColor(0,1,1)
    love.graphics.line(cx,cy,cx+ax*r/n,cy)
    love.graphics.setColor(1,0,0)
    love.graphics.line(cx,cy,cx,cy-az*r/n)
    love.graphics.setColor(0,0,1)
    local v1 = R11*boat.velocity[1] + R12*boat.velocity[3]
    local v2 = R21*boat.velocity[1] + R22*boat.velocity[3]
    love.graphics.line(cx,cy,cx+v1*boat.friction*r/n/16/2,cy+v2*boat.friction*r/n/16/2)
    love.graphics.setColor(0,1,0)
    love.graphics.printf(math.sqrt(boat.velocity[1]*boat.velocity[1]+boat.velocity[3]*boat.velocity[3]) .. ' m/s\n' .. 'mu=' .. boat.friction,0,cy+dy,windowWidth,"center")
end
