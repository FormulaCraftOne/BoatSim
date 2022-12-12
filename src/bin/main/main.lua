

function love.mousemoved( x, y, dx, dy, istouch )
    love.delta = love.delta + dx*2^(love.sensitivityStep/12)
end

function love.wheelmoved( x, y )
    love.sensitivityStep = love.sensitivityStep + y
end

function love.keyreleased(key, scancode, isrepeat)
   if key == "escape" then
      love.event.quit()
   elseif key == "r" then
    boatstate = {
        velocity = {0,0,0,0},
        position = {0,0,0,0},
        accel = 0
    }
   end
end




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
    local dx, dy, dr, ax = 1.5*r/10, 2*r/10, r/5, boatstate.angAccel
    local R11, R12 =  math.sin(-ang), math.cos(-ang)
    local R21, R22 = -math.cos(-ang), math.sin(-ang)
    local x0, y0 = ((boatstate.position[1]+0.5)%1)-0.5, ((boatstate.position[3]+0.5)%1)-0.5
    love.graphics.setColor(1,1,1)
    for i=1,22 do
        local r1 , r2 , r3 , r4 = GRIDPAIRS[i][1]-x0 , GRIDPAIRS[i][2]-y0 , GRIDPAIRS[i][3]-x0 , GRIDPAIRS[i][4]-y0
        local x1 , x2 = R11*r1 + R12*r2 , R11*r3 + R12*r4
        local y1 , y2 = R21*r1 + R22*r2 , R21*r3 + R22*r4
        love.graphics.line(dr*x1+cx,dr*y1+cy,dr*x2+cx,dr*y2+cy)
    end
    love.graphics.print(boatstate.position[1] .. ',' .. boatstate.position[2] .. ',' .. boatstate.position[3] .. ' (' .. boatstate.position[4] .. ')\n' ..
                        boatstate.velocity[1] .. ',' .. boatstate.velocity[2] .. ',' .. boatstate.velocity[3] .. ' (' .. boatstate.velocity[4] .. ')\n' ..
                        'Sensitivity: ' .. 2^(love.sensitivityStep/12) .. ' (step ' .. love.sensitivityStep .. ', scroll to adjust) \n' ..
                        'Press R to reset, Esc to exit.')
    love.graphics.setColor(181/256,153/256,104/256)
    love.graphics.rectangle('fill',cx-dx,cy-dy,2*dx,2*dy)
    love.graphics.setColor(0,1,0)
    love.graphics.line(cx,cy,cx+ax*dx,cy)
    love.graphics.setColor(1,0,0)
    love.graphics.line(cx,cy-dy,cx,cy+dy)
end

function love.update(dt)
    local dx = love.delta
    local _  = love.keyboard.isDown
    local ax, ay = A( _('w') , _('a') , _('s') , _('d') , dx/dt/MOUSE_SCALE )
    local f0, f1, f2 = F(dt,BOAT_MU)
    local ang = boatstate.position[4]*math.pi/180
    local cos , sin = math.cos(ang), math.sin(ang)
    local a0, v0 = {BOAT_A0*ay*cos, 0 , BOAT_A0*ay*sin , BOAT_T0*ax} , boatstate.velocity
    for i=1,3 do
        boatstate.velocity[i] = a0[i]*f1 + v0[i]*f0
        boatstate.position[i] = a0[i]*f2 + v0[i]*f1 + boatstate.position[i] 
    end
    boatstate.velocity[4] =     a0[4]*f1 + v0[4]*f0
    boatstate.position[4] = ( ( a0[4]*f2 + v0[4]*f1 + boatstate.position[4] + 180 ) % 360) - 180
    love.delta = love.delta - dx
    boatstate.angAccel = ax
end

function F(dt,mu)
    local f0 = math.exp(-mu*dt)
    local f1 = (1-f0)/mu
    local f2 = (dt-f1)/mu
   return f0, f1, f2
end

function A(w,a,s,d,mouse)
    local forward , right = 0 , 0
    if w then
       forward = forward + 1
    end
    if a then
       right = right - 1
    end
    if s then
       forward = forward - 1
    end
    if d then
       right = right + 1
    end
    right = math.max(-1,math.min(1,right+mouse))
    if forward>0 then
       forward =  1
    elseif forward<0 then
       forward = -1/8
    elseif not (right==0) then
       forward = math.abs(right)/8
    end
    return right, forward
end
