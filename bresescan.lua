px, py = 63, 63

dir = 0
halffov = 0.125

function farviewcoord(farplane)
  local ld,rd = dir + halffov, dir - halffov
  local lc,ls,rc,rs = cos(ld), sin(ld), cos(rd), sin(rd)
  return
    px + lc*farplane,  py + ls*farplane,
    px + rc*farplane,  py + rs*farplane
    --px + lc*nearplane, py + ls*nearplane,
    --px + rc*nearplane, py + rs*nearplane
end

function bresenhamlog(x1, y1, x2, y2)
  local t = {}
  x1 = flr(x1)
  y1 = flr(y1)
  x2 = flr(x2)
  y2 = flr(y2)
  local dx = x2-x1
  local dy = y2-y1
  local sx = sgn(dx)
  local sy = sgn(dy)
  dx = abs(dx)
  dy = -abs(dy)
  local err = dx+dy

  while true do
    --pset(x1,y1)
    add(t,x1)
    add(t,y1)
    if x1==x2 and y1 == y2 then return t end
    local e2 = err * 2
    if e2 >= dy then
      err += dy
      x1 += sx
    end
    if e2 <= dx then
      err += dx
      y1 += sy
    end
  end
end


function btnn(b)
  return btn(b) and 1 or 0
end

function _update()
  dir += (btnn(⬅️) - btnn(➡️)) * 0.0125
end

function _draw()
  cls()
  x1,y1,x2,y2 = farviewcoord(50)

  color(7)
  bresenham(x1,y1,x2,y2)
  bresenham(x1,y1,px,py)
  bresenham(x2,y2,px,py)

  --[[local ltop,rtop = {}, {}
  bresenhamlog(ltop,x1,y1,px,py)
  bresenhamlog(rtop,x2,y2,px,py)

  local col = 1
  for i=0,min(#ltop,#rtop) * 0.5 - 2 do
    color(col+1)
    local ix,iy = i*2+1, i*2+2
    bresenham(ltop[ix],ltop[iy],rtop[ix],rtop[iy])
    col = (col+1) % 15
  end]]

  local l = bresenhamlog(x1,y1,x2,y2)
  local tx,ty = py - y2, x2 - px
  local tx2,ty2 = py - y1, x1 - px

  local col = 1
  for i=1,30 do
    color(col+1)

    for j=1,#l,2 do
      local x,y = i+l[j],l[j+1]
      local vx, vy = x - px, y - py
      if vx*tx + vy*ty > 0 then break end
      if (vx*tx2 + vy*ty2 > 0) pset(x,y)
    end

    col = (col+1) % 15
  end
end