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

function bresescan(func,px,py,x1,y1,x2,y2)
  local l = bresenhamlog(x1,y1,x2,y2)
  local tx,ty = py - y2, x2 - px
  local tx2,ty2 = py - y1, x1 - px

  local sx,sy = 0,0
  local fc
  if abs(x2-x1) < abs(y2-y1) then
    sx = sgn(y1-y2)
    fc = max(abs(py-y1),abs(py-y2))
  else
    sy = sgn(x2-x1)
    fc = max(abs(px-x1),abs(px-x2))
  end

  local ix,iy = 0,0
  local mj = 1
  for i=1,fc do
    for j=mj,#l,2 do
      local x,y = ix+l[j],iy+l[j+1]
      local vx, vy = x - px, y - py
      if vx*tx + vy*ty > 0 then break end
      if vx*tx2 + vy*ty2 > 0 then
        func(x,y,i)
      else
        mj = j
      end
    end

    ix += sx
    iy += sy
  end
end