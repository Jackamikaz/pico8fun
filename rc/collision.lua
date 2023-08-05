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

--squared distance between a point and a line
function sqrlinedist(px, py, x1, y1, x2, y2)
  return sqrdst(px,py,lineintersection(x1,y1,x2,y2,px,py,px+y1-y2,py-x1+x2))
end

function rayplaneintersection(raystart,raydir,planep,planenor)
  local d = raydir^planenor
  if (abs(d) < 0x0.001) return
  return raystart+raydir*(planenor^(planep - raystart))/d
end

function ray3Dsquareintersection(raystart,raydir,a,b,c,d)
  local ab,bc,cd,da = b-a,c-b,d-c,a-d
  local pln = (ab&bc):unit()
  local p = rayplaneintersection(raystart,raydir,a,pln)
  if (not p) return
  --printh("intersection at "..p:str())
  local sa,sb,sc,sd = sgn((ab&pln)^(p-a)),sgn((bc&pln)^(p-b)),sgn((cd&pln)^(p-c)),sgn((da&pln)^(p-d))
  --printv("cab,cbc,ccd,cda",(ab%pln):str(),(bc%pln):str(),(cd%pln):str(),(da%pln):str())
  --printv("ap,bp,cp,dp",(p-a):str(),(p-b):str(),(p-c):str(),(p-d):str())
  --printv("sa,sb,sc,sd",sa,sb,sc,sd)
  return sa==sb and sb==sc and sc==sd and p or nil
end

raydda = setmetatable({},{__index=_ENV})
function raydda.start(_ENV, startx, starty, rayx, rayy)
  px,py,rx,ry = startx, starty, rayx, rayy
  ux,uy = abs(1 / rx), abs(1 / ry)
  mx,my = flr(px), flr(py)

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

  d = 0
end

function raydda.next(_ENV)
  if lx < ly then
    mx += sx
    d = lx
    lx += ux
  else
    my += sy
    d = ly
    ly += uy
  end
end

function raydda.point(_ENV)
  return px + rx * d, py + ry * d
end

function raydda.map(_ENV)
  return luamap(mx,my)
end

--[[function raydda(px, py, rx, ry, md)
  local x2,y2 = px+rx,py+ry
  --[[
  px, py : player pos
  rx, ry : unit ray dir
  ux, uy : unit step size
  mx, my : map coord
  lx, ly : ray length 1D
  sx, sy : step X, step Y
]
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
    local m = luamap(mx,my)
    if m and m.solid then
      if m.x1 then
        local cx,cy = lineintersection(px,py,x2,y2,m.x1,m.y1,m.x2,m.y2)
        if cx and cx >= mx and cx <= mx + 1 and cy >= my and cy <= my + 1 then
          local dx, dy = cx-px, cy-py
          return cx, cy, sqrt(dx*dx+dy*dy), m
        end
      elseif m.walls then
        return px + rx * d, py + ry * d, d, m
      end
    end
  end
end]]