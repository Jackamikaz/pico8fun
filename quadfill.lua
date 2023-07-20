-- adapted from @p01 trifill https://www.lexaloffle.com/bbs/?pid=azure_trifillr4-1
function quadfill(x0,y0,x1,y1,x2,y2,x3,y3,col)
  color(col)

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

  p01_trapeze_h(x0,x0,x1,s1,y0,y1)
  p01_trapeze_h(x1,s1,x2,s2,y1,y2)
  p01_trapeze_h(x2,s2,x3,x3,y2,y3)
end
function p01_trapeze_h(l,r,lt,rt,y0,y1)
  lt,rt=(lt-l)/(y1-y0),(rt-r)/(y1-y0)
  --if(y0<0)l,r,y0=l-y0*lt,r-y0*rt,0
  --y1=min(y1,128)
  for y0=y0,y1 do
    rectfill(l,y0,r,y0)
    l+=lt
    r+=rt
  end
end
