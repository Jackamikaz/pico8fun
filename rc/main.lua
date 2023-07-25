---------- PLAYER ----------
player = {}
player.pos = vec:new(9.5, 8.5)
player.alt = 0.5
player.size = 2.5
player.dir = 0.75
player.speed = 1 / 8
player.turnrate = 0.0125
player.radius = 0.2

function player:draw()
  local screenpos = self.pos * 8
  circfill(screenpos.x, screenpos.y, self.size, 6)
  local ppos = screenpos + self:getunitdir() * self.size
  pset(ppos.x, ppos.y, 8)
end

function player:getunitdir()
  return vec:new(cos(self.dir), sin(self.dir))
end

function btnn(b)
  return btn(b) and 1 or 0
end

function player:update()
  self.dir += (btnn(⬅️) - btnn(➡️)) * self.turnrate
  local mov = self:getunitdir() * self.speed * (btnn(⬆️) - btnn(⬇️))

  local my = flr(self.pos.y)
  local nx = flr(self.pos.x + sgn(mov.x)*self.radius)
  if (not luamap[nx | my << 8]) self.pos.x += mov.x

  local mx = flr(self.pos.x)
  local ny = flr(self.pos.y + sgn(mov.y)*self.radius)
  if (not luamap[mx | ny << 8]) self.pos.y += mov.y
end

function player:copytocam()
  cam_x = self.pos.x
  cam_y = self.pos.y
  cam_z = self.alt
  setcamdir(self.dir)
end

---------- INIT ----------

function _init()
  setupcamera()
  setfov(0.2222)
  buildluamap()
  poke(0x5f2d, 1) --enable mouse
end

function setupcamera(startx, starty, startz, startdir, startfar)
  cam_x = startx
  cam_y = starty
  cam_z = startz
  cam_far = startfar or 8
  setcamdir(startdir)
end

function setcamdir(newdir)
  cam_dir = newdir or 0
  cam_dircos = cos(cam_dir)
  cam_dirsin = sin(cam_dir)
end

function setfov(fov)
  cam_halffov = fov/2
  projplanedist = -64 * cos(cam_halffov) / sin(cam_halffov) --half screen width / tan(fov/2)
  rayDir = {}
  antiFishEye = {}
  for x=-64,63 do
    rayDir[x] = atan2(projplanedist, x)
    antiFishEye[x] = 1 / cos(rayDir[x])
  end
end

function getfarsegment()
  local la,ra = cam_dir+cam_halffov,cam_dir-cam_halffov
  local d = cam_far/cos(cam_halffov)
  return cam_x + cos(la)*d, cam_y + sin(la)*d, cam_x + cos(ra)*d, cam_y + sin(ra)*d
end

function append(t,...)
  for _,v in ipairs({...}) do
    add(t,v)
  end
end

function buildluamap()
  luamap = {}

  for y = 0,63 do
    for x = 0,127 do
      local m = mget(x,y)
      if fget(m, 0) then
        --[[local cell = {m}
        if m == 3 then
          cell[1] = 1
          cell.x1 = x
          cell.y1 = y
          cell.x2 = x + 1
          cell.y2 = y + 1
        elseif m == 4 then
          cell[1] = 1
          cell.x1 = x + 1
          cell.y1 = y
          cell.x2 = x
          cell.y2 = y + 1
        end--]]
        local walls = {}
        if not fget(mget(x-1,y),0) then
          append(walls,x,y+1,0,x,y,1,m)
        end
        if not fget(mget(x+1,y),0) then
          append(walls,x+1,y,0,x+1,y+1,1,m)
        end
        if not fget(mget(x,y-1),0) then
          append(walls,x,y,0,x+1,y,1,m)
        end
        if not fget(mget(x,y+1),0) then
          append(walls,x+1,y+1,0,x,y+1,1,m)
        end
        luamap[x | y << 8] = {m,walls}
      end
    end
  end
end

---------- COLLISIONS ----------

--https://stackoverflow.com/questions/2049582/how-to-determine-if-a-point-is-in-a-2d-triangle
function pointintriangle(px,py,x1,y1,x2,y2,x3,y3)
  local s1 = (px-x2)*(y1-y2)-(x1-x2)*(py-y2) < 0
  local s2 = (px-x3)*(y2-y3)-(x2-x3)*(py-y3) < 0
  local s3 = (px-x1)*(y3-y1)-(x3-x1)*(py-y1) < 0
  return s1 == s2 and s2 == s3
end

--https://iq.opengenus.org/2d-line-intersection/#:~:text=Step%201%20%3A%20Input%20four%20coordinates,of%20slope%20of%20each%20line.
function lineintersection(x1, y1, x2, y2, x3, y3, x4, y4)
  local x12 = x1 - x2
  local x34 = x3 - x4
  local y12 = y1 - y2
  local y34 = y3 - y4
  local c = x12 * y34 - y12 * x34
  --if (c~=0) then
    local a = x1 * y2 - y1 * x2
    local b = x3 * y4 - y3 * x4
    return (a * x34 - b * x12 ) / c, (a * y34 - b * y12) / c
  --end
end

function raydda(px, py, rx, ry, md)
  local x2,y2 = px+rx,py+ry
  --[[
  px, py : player pos
  rx, ry : unit ray dir
  ux, uy : unit step size
  mx, my : map coord
  lx, ly : ray length 1D
  sx, sy : step X, step Y
]]
  local ux,uy = abs(1 / rx), abs(1 / ry)
  local mx,my = flr(px), flr(py)
  local rl1x,rl1y,sx,sy

  if rx < 0 then
    sx = -1
    lx = (px - mx) * ux
  else
    sx = 1
    lx = (mx + 1 - px) * ux
  end

  if ry < 0 then
    sy = -1
    ly = (py - my) * uy
  else
    sy = 1
    ly = (my + 1 - py) * uy
  end

  local d = 0
  while d < md do
    if lx < ly then
      mx += sx
      d = lx
      lx += ux
    else
      my += sy
      d = ly
      ly += uy
    end

    --local m = mget(mx, my)
    local m = luamap[mx | my << 8]
    if m then
      if m.x1 then
        local cx,cy = lineintersection(px,py,x2,y2,m.x1,m.y1,m.x2,m.y2)
        if cx and cx >= mx and cx <= mx + 1 and cy >= my and cy <= my + 1 then
          local dx, dy = cx-px, cy-py
          return cx, cy, sqrt(dx*dx+dy*dy), m
        end
      else
        return px + rx * d, py + ry * d, d, m
      end
    end
  end
end

---------- RAYCAST ----------

-- translate world position to screen coordinates
function getscreenpos(mx,my,mz)
  --[[local dx, dy = mx - cam_x, my - cam_y
  local d = sqrt(dx*dx+dy*dy)
  local raydir = atan2(dx,dy) - cam_dir
  local crd = cos(raydir)
  local afe = 1 / crd
  local x = projplanedist * sin(raydir) * afe
  local depthfactor = afe * projplanedist / d
  local y = mz * depthfactor
  if (abs(raydir)+0.25)%1 >= 0.5 then
    if -crd * d > projplanedist/128 then
      return
    else
      return -x, -y
    end
  else
    return x,y
  end--]]

  mx,my = my-cam_y, mx-cam_x
  mx,my = mx*cam_dircos - my*cam_dirsin, mx*cam_dirsin + my*cam_dircos
  if my > 0.1 then
    local df = projplanedist / my
    return mx * df, mz * df
  end
end

-- adapted from @p01 trifill https://www.lexaloffle.com/bbs/?pid=azure_trifillr4-1
function quadfillfloor(alt,x1,y1,x2,y2,x3,y3,x4,y4)
  if (y1 > y2) x1,y1,x2,y2 = x2,y2,x1,y1
  if (y3 > y4) x3,y3,x4,y4 = x4,y4,x3,y3
  if (y1 > y3) x1,y1,x3,y3 = x3,y3,x1,y1
  if (y2 > y4) x2,y2,x4,y4 = x4,y4,x2,y2
  if (y2 > y3) x2,y2,x3,y3 = x3,y3,x2,y2

  local s1,s2,s3--,s4

  s1 = x1+(x4-x1)/(y4-y1)*(y2-y1)
  s3 = x1+(x3-x1)/(y3-y1)*(y2-y1)

  if abs(s1 - x2) < abs(s3- x2) then
    s1 = s3
    s2 = x2+(x4-x2)/(y4-y2)*(y3-y2) -- s4
  else
    s2 = x1+(x4-x1)/(y4-y1)*(y3-y1)
  end

  if (s1 < x2) x2, s1 = s1, x2
  if (s2 < x3) x3, s2 = s2, x3

  floortrapeze(x1,x1,x2,s1,y1,y2,alt)
  floortrapeze(x2,s1,x3,s2,y2,y3,alt)
  floortrapeze(x3,s2,x4,x4,y3,y4,alt)
end
function floortrapeze(l,r,lt,rt,y1,y2,alt)
  lt,rt=(lt-l)/(y2-y1),(rt-r)/(y2-y1)
  --if(y1<0)l,r,y1=l-y1*lt,r-y1*rt,0
  --y2=min(y2,128)
  for y1=y1,min(64,y2) do
    --rectfill(l,y1,r,y1)
    
    if r >= -64 and l < 64 then
      local la,ra = min(max(-64,flr(l)), 63), min(max(-64,flr(r)), 63)

      local lx,ly = getfloorpos(la,y1,alt)
      local rx,ry = getfloorpos(ra,y1,alt)

      local sd = ra - la
      tline(la,y1,ra,y1,lx,ly,(rx-lx)/sd,(ry-ly)/sd)
    end

    l+=lt
    r+=rt
  end
end

function worldtocam(wx,wy)
  wx,wy = wy-cam_y, wx-cam_x
  return wx*cam_dircos - wy*cam_dirsin, wx*cam_dirsin + wy*cam_dircos
end

--offsets = {0,0,1,0,1,1,0,1}
function drawfloortile(fx, fy, fz, s)
  --[[local points = {}
  for i=1,7,2 do
    local sx,sy = getscreenpos(fx+offsets[i],fy+offsets[i+1],cam_z-fz)
    if (not sx) return
    add(points,sx)
    add(points,sy)
  end

  quadfillfloor(cam_z-fz,unpack(points))]]
  local x1,y1 = worldtocam(fx,fy)
  local x2,y2 = worldtocam(fx+1,fy)
  local x3,y3 = worldtocam(fx+1,fy+1)
  local x4,y4 = worldtocam(fx,fy+1)

  if (y1 < y2) x1,y1,x2,y2 = x2,y2,x1,y1
  if (y3 < y4) x3,y3,x4,y4 = x4,y4,x3,y3
  if (y1 < y3) x1,y1,x3,y3 = x3,y3,x1,y1
  if (y2 < y4) x2,y2,x4,y4 = x4,y4,x2,y2
  if (y2 < y3) x2,y2,x3,y3 = x3,y3,x2,y2

  local ylimit = 0.01

  if (y1 < ylimit) return

  local alt,tra = cam_z-fz,3
  local x2b,x3b,x4b

  if y2 < ylimit then
    tra = 1
    x2,y2 = x1+(x2-x1)/(y2-y1)*(ylimit-y1),ylimit
  end

  x2b = x1+(x4-x1)/(y4-y1)*(y2-y1)
  x3b = x1+(x3-x1)/(y3-y1)*(y2-y1)

  if abs(x2b - x2) < abs(x3b- x2) then
    x2b = x3b
    x3b = x2+(x4-x2)/(y4-y2)*(y3-y2)
  else
    x3b = x1+(x4-x1)/(y4-y1)*(y3-y1)
  end

  if (x2b < x2) x2, x2b = x2b, x2
  if (x3b < x3) x3, x3b = x3b, x3

  if tra > 1 then
    if y3 < ylimit then
      tra = 2
      x3 = x2+(x3-x2)/(y3-y2)*(ylimit-y2)
      x3b = x2b+(x3b-x2b)/(y3-y2)*(ylimit-y2)
      y3 = ylimit
    else
      x4b = x4
      if y4 < ylimit then
        x4 = x4+(x4-x3)/(y3-y4)*(y4-ylimit)
        x4b = x4b+(x4b-x3b)/(y3-y4)*(y4-ylimit)
        y4 = ylimit
      end
    end
  end
  
  --[[debug
  local s = -30
  line(-60,ylimit*s,60,ylimit*s,13)
  line(x1*s,y1*s,x2*s,y2*s,7)
  line(x1*s,y1*s,x2b*s,y2*s,7)
  line(x2*s,y2*s,x2b*s,y2*s,7)

  if tra >= 2 then
    line(x2*s,y2*s,x3*s,y3*s,7)
    line(x2b*s,y2*s,x3b*s,y3*s,7)
    line(x3*s,y3*s,x3b*s,y3*s,7)
  end

  if tra >= 3 then
    line(x3*s,y3*s,x4*s,y4*s,7)
    line(x3b*s,y3*s,x4b*s,y4*s,7)
    line(x4*s,y4*s,x4b*s,y4*s,7)
  end--]]

  local df = projplanedist / y1
  x1,y1 = x1*df, alt*df

  df = projplanedist / y2
  x2,x2b,y2 = x2*df, x2b*df, alt*df
  floortrapeze(x1,x1,x2,x2b,y1,y2,alt)

  if (tra < 2) return
  df = projplanedist / y3
  x3,x3b,y3 = x3*df, x3b*df, alt*df
  floortrapeze(x2,x2b,x3,x3b,y2,y3,alt)

  if (tra < 3) return
  df = projplanedist / y4
  x4,x4b,y4 = x4*df, x4b*df, alt*df
  floortrapeze(x3,x3b,x4,x4b,y3,y4,alt)
end

function getfloorpos(sx, sy, cz)
  local floordist = antiFishEye[sx] * cz * projplanedist / sy
  local raydir = cam_dir + rayDir[sx]
  return cam_x + cos(raydir) * floordist, cam_y + sin(raydir) * floordist
end

function drawfloor(alt)
  for y=1,63 do
    local lx,ly = getfloorpos(-64,y,cam_z-alt)
    local rx,ry = getfloorpos(63,y,cam_z-alt)

    tline(-64,y,63,y,lx,ly,(rx-lx)/128,(ry-ly)/128)
  end
end

function drawwall(x1, y1, z1, x2, y2, z2, sp)
  local ylimit = 0.1
  x1,y1 = worldtocam(x1,y1)
  x2,y2 = worldtocam(x2,y2)
  local t1,t2 = 1,0
  if y1 < ylimit then
    if (y2 < ylimit) return
    t2 = (ylimit - y1)/(y2-y1)
    x1 += (x2-x1)*t2
    y1 = ylimit
  elseif y2 < ylimit then
    t1 = (ylimit - y2)/(y1-y2)
    x2 += (x1-x2)*t1
    y2 = ylimit
    t1 = 1-t1
  end
  
  --[[local s = -20
  line(-60,ylimit*s,60,ylimit*s,13)
  line(x1*s,y1*s,x2*s,y2*s,7)
  circ(x1*s,y1*s,2,8)
  circ(x2*s,y2*s,2,11)--]]

  z1,z2 = cam_z-z1,cam_z-z2
  local w1 = 1 / y1
  local df = projplanedist / y1
  x1,y1 = x1*df,z1*df
  local y1b = z2*df

  local w2 = 1 / y2
  df = projplanedist / y2
  x2,y2 = x2*df,z1*df
  local y2b = z2 * df

  local dx = x2-x1
  local sdx = sgn(dx)
  local tt,bt = (y2-y1)/dx*sdx,(y2b-y1b)/dx*sdx

  --printh("t1="..(x2-x1)/dx..", t2="..(x2-x2)/dx..", tp1="..tp1..", tp2="..tp2)

  for x=x1,x2,sdx do
    local t = (x2-x)/dx
    local u = ((1-t)*t1/w1+t*t2/w2)/((1-t)/w1+t/w2)
    sspr((sp%16+u)*8,flr(sp/16)*8,1,8,x,y1b,1,y1-flr(y1b))
    --line(x,y1,x,y1b)

    y1 += tt
    y1b += bt
  end
end

--function round(val)
--  local d = val % 1
--  if d < 0.5 then return flr(val) else return flr(val+1) end
--end

function drawhorizon()
  for x=-64,63 do
    local raydir = cam_dir + rayDir[x]
    local rx = cos(raydir)
    local ry = sin(raydir)
    local cx,cy,d,mr = raydda(cam_x, cam_y, rx, ry, cam_far)
    if cx then
      local tx = abs(cx % 1)
      local ty = abs(cy % 1)
      local c
      if abs(tx - 0.5) < abs(ty - 0.5) then
        c = tx
      else
        c = ty
      end

      local m = mr[1]
      local depthfactor = antiFishEye[x] * projplanedist / d
      local walltop = -(1-cam_z) * depthfactor
      sspr((m%16 + c)*8,flr(m/16)*8,1,8,x,walltop+1,1,depthfactor + walltop%1)

      --local halfwall = flr(antiFishEye[x] * 0.5 * projplanedist / d)
      --sspr((m%16 + c)*8,flr(m/16)*8,1,8,x,-halfwall+1,1,halfwall*2)
    end
  end
end

---------- OTHER ----------
function deductnormal(mt, cx, cy)
  if mt.x1 then
    return vec:new(mt.y1 - mt.y2, mt.x2-mt.x1):unit()
  end
  local x,y = cx % 1, cy % 1
  if x < 0.0005 then
    return vec:new(-1,0)
  elseif x > 0.9995 then
    return vec:new(1,0)
  elseif y < 0.0005 then
    return vec:new(0,-1)
  else
    return vec:new(0,1)
  end
end

function bssfunc(x,y)
  local lm = luamap[x | y << 8]
  if lm then
    local w = lm[2]
    for i=1,#w,7 do
      drawwall(unpack(w,i,i+6))
    end
  elseif mget(x,y) ~= 0 then
    drawfloortile(x,y,0,0)
  end
end

flatbsscount = 0
stepbystep = false
function flatbss(x,y)
  --map(x,y,x*8,y*8,1,1)

  x,y = x*8,y*8
  rectfill(x,y,x+8,y+8,7)
  rect(x,y,x+8,y+8,0)
  print(flatbsscount,x+1,y+2,1)
  flatbsscount += 1
end

---------- DRAW/UPDATE ----------

function _update()
  player:update()
  player:copytocam()
end

modes = {top = 0, raycast=1, newtech=2, max=3}

rendermode = modes.raycast

function _draw()
  cls()

  if btnp(❎) then
    rendermode = (rendermode + 1) % modes.max
  end

  local rcx,rcy = cam_x,cam_y --cam_x-cam_dircos*2,cam_y-cam_dirsin*2
  if rendermode == modes.top then
    local cx = player.pos.x - 8
    local cy = player.pos.y - 8
    camera(cx * 8, cy * 8)

    --map(cx, cy, flr(cx) * 8, flr(cy) * 8, 17, 17)
    --bresescan(flatbss,rcx,rcy,getfarsegment())
    --parascan(flatbss,rcx,rcy,getfarsegment())
    
    flatbsscount = 0
    stepbystep = false
    local tri = disperscan(flatbss)
    player:draw()

    if btn(🅾️) then
      local px,py,xl,yl,xr,yr = rcx,rcy, getfarsegment()
      px*=8 py*=8 xl*=8 yl*=8 xr*=8 yr*=8

      color(7)
      line(xl,yl,xr,yr)
      line(px,py,xl,yl)
      line(px,py,xr,yr)

      px,py,xl,yl,xr,yr = unpack(tri)
      px*=8 py*=8 xl*=8 yl*=8 xr*=8 yr*=8

      color(7)
      line(xl,yl,xr,yr)
      line(px,py,xl,yl)
      line(px,py,xr,yr)

      local mx, my = stat(32)+cx*8, stat(33)+cy*8
      spr(32,mx,my)
      print(pointintriangle(mx,my,px,py,xl,yl,xr,yr),mx+6,my+2,7)
    end
  elseif rendermode == modes.raycast then
    camera(-64,-64)
    drawfloor(0)
    drawhorizon()

    --local a = 0.4--sin(t()*0.25) * 0.4
    --drawfloortile(9,25,a, 0)

    --drawwall(2,22,1,4,23,0, 1)
    --drawwall(4,23,1,5,25,0, 17)
    --[[local x1,y1 = getscreenpos(px, py, 2, 2, pd, alt)
    local x2,y2 = getscreenpos(px, py, 3, 2, pd, alt)
    local x3,y3 = getscreenpos(px, py, 3, 3, pd, alt)
    local x4,y4 = getscreenpos(px, py, 2, 3, pd, alt)
    if x1 and x2 and x3 and x4 then
      line(x1,y1,x2,y2,7)
      line(x2,y2,x3,y3,7)
      line(x3,y3,x4,y4,7)
      line(x4,y4,x1,y1,7)
    end]]
  elseif rendermode == modes.newtech then
    camera(-64,-64)
    --parascan(bssfunc,rcx,rcy,getfarsegment())
    --drawfloor(0)
    disperscan(bssfunc)
  end

  --[[camera(0,0)
    rectfill(0,0,50,14, 7)
    color(0)
    print(player.dir)--]]
end