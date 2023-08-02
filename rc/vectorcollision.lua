function isvecinrect(v,x1,y1,x2,y2)
  return isvalbetween(v.x,x1,x2) and isvalbetween(v.y,y1,y2)
end

--https://stackoverflow.com/questions/3838329/how-can-i-check-if-two-segments-intersect
function vec_ccw(a,b,c)
  return (c.y-a.y)*(b.x-a.x) >= (b.y-a.y)*(c.x-a.x)
end

function segmentstouch(a,b,c,d)
  return vec_ccw(a,c,d) != vec_ccw(b,c,d) and vec_ccw(a,b,c) != vec_ccw(a,b,d)
end