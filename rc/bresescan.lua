--[[function bresenhamlog(x1, y1, x2, y2)
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

function minx(...)
  local r = 0x7FFF.FFFF
  for _,v in ipairs({...}) do
    if (v<r) r=v
  end
  return r
end

function maxx(...)
  local r = 0x8000
  for _,v in ipairs({...}) do
    if (v>r) r=v
  end
  return r
end

function insquare(px,py,t,b,l,r)
  return l <= px and px <= r and t <= py and py <= b
end

parascanvalues = {
  { 0,-1,-1, 0, 1, 1},
  {-1,-1, 0, 1, 1, 0},
  {-1, 0, 0, 1, 1, 0},
  {-1, 1, 1, 0, 0, 0},
  { 0, 1, 1, 0, 0, 0},
  { 1, 1, 0,-1, 0, 1},
  { 1, 0, 0,-1, 0, 1},
  { 1,-1,-1, 0, 1, 1}
}
function parascan(func,px,py,x1,y1,x2,y2)
  local bt = flr(minx(py,y1,y2))
  local bb = flr(maxx(py,y1,y2))
  local bl = flr(minx(px,x1,x2))
  local br = flr(maxx(px,x1,x2))
  local dx,dy,lx,ly,sx,sy = unpack(parascanvalues[flr((cam_dir+1/16)%1*8)+1]) -- line direction
  --local lx,ly = dy,-dx --direction to player
  --local sx,sy = -lx,-ly --start position
  --if (sx==0) sx = -dx
  --if (sy==0) sy = -dy
  ----lx,ly = (sy+1)/2,(-sx+1)/2
  --sx,sy = (sx+1)/2,(sy+1)/2
  sx,sy = (1-sx)*bl+sx*br,(1-sy)*bt+sy*bb

  --printh("------------------------")
  --printh("bt="..bt..", bb="..bb..", bl="..bl..", br="..br)
  --printh("dx="..dx..", dy="..dy)
  --printh("lx="..lx..", ly="..ly)
  --printh("sx="..sx..", sy="..sy)

  local diag = abs(dx)+abs(dy)

  while true do
    local x,y = sx,sy
    while insquare(x,y,bt,bb,bl,br) do
      if (pointintriangle(x+0.5,y+0.5,px,py,x1,y1,x2,y2)) func(x,y)
      x += dx
      y += dy
    end
    sx += lx
    sy += ly
    if not insquare(sx,sy,bt,bb,bl,br) then
      if diag == 1 then
        return
      else
        diag = 1
        sx -= lx
        sy -= ly
        lx,ly = -ly,lx
        sx += lx
        sy += ly
      end
    end
  end
end

firstfire = {
  { 1, 0},
  { 1,-1},
  { 0,-1},
  {-1,-1},
  {-1, 0},
  {-1, 1},
  { 0, 1},
  { 1, 1}
}

function disperscanfire(func,x,y,dx,dy,tri,subfire)
  if pointintriangle(x,y,unpack(tri)) then
    disperscanfire(func,x+dx,y+dy,dx,dy,tri,subfire)

    if subfire > 0 then
      local px,py = dy,-dx
      if abs(dx)+abs(dy) == 2 then
        if (sgn(dx) ~= sgn(dy)) px,py = -px,-py
        disperscanfire(func,x+dx,y   , px, py,tri,0)
        disperscanfire(func,x   ,y+dy,-px,-py,tri,0)
      end
      disperscanfire(func,x+px,y+py, px, py,tri,0)
      disperscanfire(func,x-px,y-py,-px,-py,tri,0)
    end
    func(flr(x),flr(y))
    return true
  end
  return false
end

function disperscan(func)
  local dx,dy = unpack(firstfire[flr((cam_dir+1/16)%1*8)+1])
  local tri = {expandtriangle(0.71,cam_x,cam_y,getfarsegment())}

  local sx,sy = flr(cam_x)+0.5,flr(cam_y)+0.5
  while not disperscanfire(func,sx,sy,dx,dy,tri,1) do
    sx += dx sy += dy
  end
  -- edge case on diagonals where a cell near the camera isn't caught by the disperscan
  if abs(dx)+abs(dy)==2 then
    sx, sy = flr(sx), flr(sy)
    func(sx-dx,sy)
    func(sx,sy-dy)
  end

  --print(flr((cam_dir+1/16)%1*8)+1,0,0,7)

  return tri
end--]]

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

function printv(s,...)
  local v = {...}
  local r = ""
  for i,n in ipairs(split(s)) do
    r = r..n.."="..v[i].." "
  end
  printh(r)
end

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

function disperscan(func)
  local dx,dy = -sgn(cam_dircos),-sgn(cam_dirsin)
  if abs(cam_dircos) > abs(cam_dirsin) then
    dy = 0 else dx = 0 end
  local pdx,pdy = -dy,dx
  local px,py,lx,ly,rx,ry = expandtriangle(0.71,cam_x,cam_y,getfarsegment())
  local lsd = sqrdst(px,py,lx,ly)
  local ex,ey = middle(cam_x,cam_y)
  local sx,sy = middle(lineintersection(ex,ey,ex+dx,ey+dy,lx,ly,rx,ry))
  --for i=1,abs((sx-ex)*dx)+abs((sy-ey)*dy)+1 do
  for i=1,sqrt(sqrdst(sx,sy,ex,ey))+1 do
    local pl = {sx,sy,sx+pdx,sy+pdy}
    local fsx,fsy = lineintersection(lx,ly,rx,ry,unpack(pl))
    local skip = sqrdst(sx,sy,fsx,fsy) > lsd

    local li = {
      {lineintersection(px,py,rx,ry,unpack(pl))},
      {lineintersection(px,py,lx,ly,unpack(pl))}}

    for i=1,2 do
      local msx,msy = unpack(li[i])

      if skip or lsd > sqrdst(px,py,msx,msy) then
        msx,msy = middle(msx,msy)
      else
        msx,msy = middle(fsx,fsy)
      end
      
      local f = (i-1)*2-1
      if sgn0(msx-sx)==pdx*f and sgn0(msy-sy)==pdy*f then
        while msx ~= sx or msy ~= sy do
          func(flr(msx),flr(msy))
          msx -= pdx*f msy -= pdy*f
        end
      end
    end
    func(flr(sx),flr(sy))
    sx += dx sy += dy
  end
end