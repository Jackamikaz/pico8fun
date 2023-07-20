---------- PLAYER ----------
player = {}
player.pos = vec:new(4.5, 23.5)
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
  setfov(0.3)
  buildluamap()
end

function setupcamera(startx, starty, startz, startdir)
  cam_x = startx or 0
  cam_y = starty or 0
  cam_z = startz or 0.5
  setcamdir(startdir)
end

function setcamdir(newdir)
  cam_dir = newdir or 0
  cam_dircos = cos(cam_dir)
  cam_dirsin = sin(cam_dir)
end

function setfov(fov)
  projplanedist = -128 * cos(fov/2) / sin(fov/2) --screen width / tan(fov/2)
  rayDir = {}
  antiFishEye = {}
  for x=-64,63 do
    rayDir[x] = atan2(projplanedist, x)
    antiFishEye[x] = 1 / cos(rayDir[x])
  end
end

function buildluamap()
  luamap = {}

  for y = 0,63 do
    for x = 0,127 do
      local m = mget(x,y)
      if fget(m, 0) then
        local cell = {m}
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
        end
        luamap[x | y << 8] = cell
      end
    end
  end
end

---------- COLLISIONS ----------

--https://iq.opengenus.org/2d-line-intersection/#:~:text=Step%201%20%3A%20Input%20four%20coordinates,of%20slope%20of%20each%20line.
function lineintersection(x1, y1, x2, y2, x3, y3, x4, y4)
  local x12 = x1 - x2
  local x34 = x3 - x4
  local y12 = y1 - y2
  local y34 = y3 - y4
  local c = x12 * y34 - y12 * x34
  if (c~=0) then
    local a = x1 * y2 - y1 * x2
    local b = x3 * y4 - y3 * x4
    return (a * x34 - b * x12 ) / c, (a * y34 - b * y12) / c
  end
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
  local dx, dy = mx - cam_x, my - cam_y
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
  end
end

-- adapted from @p01 trifill https://www.lexaloffle.com/bbs/?pid=azure_trifillr4-1
function quadfillfloor(alt,x0,y0,x1,y1,x2,y2,x3,y3)
  if (y0 > y1) x0,y0,x1,y1 = x1,y1,x0,y0
  if (y2 > y3) x2,y2,x3,y3 = x3,y3,x2,y2
  if (y0 > y2) x0,y0,x2,y2 = x2,y2,x0,y0
  if (y1 > y3) x1,y1,x3,y3 = x3,y3,x1,y1
  if (y1 > y2) x1,y1,x2,y2 = x2,y2,x1,y1

  local s1,s2,s3--,s4

  s1 = x0+(x3-x0)/(y3-y0)*(y1-y0)
  --s2 = x0+(x3-x0)/(y3-y0)*(y2-y0)
  s3 = x0+(x2-x0)/(y2-y0)*(y1-y0)
  --s4 = x1+(x3-x1)/(y3-y1)*(y2-y1)

  if abs(s1 - x1) < abs(s3- x1) then
    s1 = s3
    s2 = x1+(x3-x1)/(y3-y1)*(y2-y1) -- s4
  else
    s2 = x0+(x3-x0)/(y3-y0)*(y2-y0)
  end

  if (s1 < x1) x1, s1 = s1, x1
  if (s2 < x2) x2, s2 = s2, x2

  floortrapeze(x0,x0,x1,s1,y0,y1,alt)
  floortrapeze(x1,s1,x2,s2,y1,y2,alt)
  floortrapeze(x2,s2,x3,x3,y2,y3,alt)
end
function floortrapeze(l,r,lt,rt,y0,y1,alt)
  lt,rt=(lt-l)/(y1-y0),(rt-r)/(y1-y0)
  --if(y0<0)l,r,y0=l-y0*lt,r-y0*rt,0
  --y1=min(y1,128)
  for y0=y0,y1 do
    --rectfill(l,y0,r,y0)
    
    local la,ra = min(max(-64,flr(l)), 63), min(max(-64,flr(r)), 63)

    local lx,ly = getfloorpos(la,y0,alt)
    local rx,ry = getfloorpos(ra,y0,alt)

    local sd = ra - la
    tline(la,y0,ra,y0,lx,ly,(rx-lx)/sd,(ry-ly)/sd)

    l+=lt
    r+=rt
  end
end

offsets = {0,0,1,0,1,1,0,1}
function drawfloortile(fx, fy, fz, s)
  local points = {}
  for i=1,7,2 do
    local sx,sy = getscreenpos(fx+offsets[i],fy+offsets[i+1],cam_z-fz)
    if (not sx) return
    add(points,sx)
    add(points,sy)
  end

  quadfillfloor(cam_z-fz,unpack(points))
end

function getfloorpos(sx, sy, wz)
  local floordist = antiFishEye[sx] * wz * projplanedist / sy
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

--function round(val)
--  local d = val % 1
--  if d < 0.5 then return flr(val) else return flr(val+1) end
--end

function drawhorizon()
  for x=-64,63 do
    local raydir = cam_dir + rayDir[x]
    local rx = cos(raydir)
    local ry = sin(raydir)
    local cx,cy,d,mr = raydda(cam_x, cam_y, rx, ry, 8)
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

---------- DRAW/UPDATE ----------

function _update()
  player:update()
  player:copytocam()
end

modes = {top = 0, raycast=1, max=2}

rendermode = modes.raycast

ltx1 = 2
lty1 = 2
ltx2 = 6
lty2 = 9

function _draw()
  cls()

  if btnp(❎) then
    rendermode = (rendermode + 1) % modes.max
  end

  if rendermode == modes.top then
    local cx = player.pos.x - 8
    local cy = player.pos.y - 8
    camera(cx * 8, cy * 8)

    map(cx, cy, flr(cx) * 8, flr(cy) * 8, 17, 17)
    player:draw()

    local ppx = player.pos.x
    local ppy = player.pos.y
    local unit = player:getunitdir()
    local cx, cy, d, m = raydda(ppx, ppy, unit.x, unit.y, 16)

    if d then
      line(ppx * 8, ppy * 8, cx * 8, cy * 8, 12)
    end

    if m then
      m = m[1]
      camera(0, 0)
      sspr(m % 16 * 8, flr(m / 16) * 8, 8, 8, 10, 10, 16, 16)
    end
  elseif rendermode == modes.raycast then
    camera(-64,-64)
    drawfloor(0)
    drawhorizon()

    drawfloortile(9,25,sin(t()*0.25) * 0.4, 0)
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
  end

  --[[camera(0,0)
    rectfill(0,0,50,14, 7)
    color(0)
    print(player.dir)--]]
end