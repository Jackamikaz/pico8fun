function shiftline(x1,y1,x2,y2,d)
  local nx,ny = y2-y1,x1-x2
  local f = d/sqrt(nx*nx+ny*ny)
  nx,ny = nx*f,ny*f
  return x1+nx,y1+ny,x2+nx,y2+ny
end

-- winding order sensitive
function expandtriangle(d,x1,y1,x2,y2,x3,y3)
  local fx1,fy1,fx2,fy2 = shiftline(x2,y2,x3,y3,d)
  local lx1,ly1,lx2,ly2 = shiftline(x1,y1,x2,y2,d)
  local rx1,ry1,rx2,ry2 = shiftline(x3,y3,x1,y1,d)

  local npx,npy = lineintersection(lx1,ly1,lx2,ly2,rx1,ry1,rx2,ry2)
  local nlx,nly = lineintersection(lx1,ly1,lx2,ly2,fx1,fy1,fx2,fy2)
  local nrx,nry = lineintersection(rx1,ry1,rx2,ry2,fx1,fy1,fx2,fy2)

  return npx,npy,nlx,nly,nrx,nry
end

--saves token when using this at least 3 times
function middle(x,y)
  return flr(x)+0.5,flr(y)+0.5
end

--sometimes I want 0 included
function sgn0(v)
  if (v==0) return 0
  return sgn(v)
end

function sqrdst(x1,y1,x2,y2)
  local dx,dy = x1-x2,y2-y1
  local r = dx*dx+dy*dy
  --overflow can happen! limit to max
  if (r < 0) return 0x7fff.ffff
  return r
end

function sqrdst3(x1,y1,z1,x2,y2,z2)
  local dx,dy,dz = x1-x2,y2-y1,z2-z1
  local r = dx*dx+dy*dy+dx*dx
  --overflow can happen! limit to max
  if (r < 0) return 0x7fff.ffff
  return r
end

function isvalbetween(v,a,b)
  return mid(v,a,b) == v
end