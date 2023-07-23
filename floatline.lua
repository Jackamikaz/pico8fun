function floatline(x,y,x2,y2)
  local dx, dy = x2-x, y2-y
  if abs(dx) >= abs(dy) then
    local s = sgn(dx)
    local r = dy/dx*s
    while (x2 - x)*s > 0 do
      pset(x,y)
      x += s
      y += r
    end
  else
    local s = sgn(dy)
    local r = dx/dy*s
    while (y2 - y)*s > 0 do
      pset(x,y)
      x += r
      y += s
    end
  end
end