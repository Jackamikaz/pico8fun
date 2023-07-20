function bresenham(x1, y1, x2, y2)
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
    pset(x1,y1)
    if x1==x2 and y1 == y2 then return end
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
