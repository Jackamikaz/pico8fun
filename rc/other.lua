-- Do not include! Those are just failed test...
-- But you know even if it's useless it still feels like a waste if I delete all

function deductnormal(mt, cx, cy)
  if mt.x1 then
    return newvector2(mt.y1 - mt.y2, mt.x2-mt.x1):unit()
  end
  local x,y = cx % 1, cy % 1
  if x < 0.0005 then
    return newvector2(-1,0)
  elseif x > 0.9995 then
    return newvector2(1,0)
  elseif y < 0.0005 then
    return newvector2(0,-1)
  else
    return newvector2(0,1)
  end
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
  for v in all({...}) do
    if (v<r) r=v
  end
  return r
end

function maxx(...)
  local r = 0x8000
  for v in all({...}) do
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

  local sx,sy = middle(cam_x,cam_y)
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
end

-- adapted from @p01 trifill https://www.lexaloffle.com/bbs/?pid=azure_trifillr4-1
function quadfillfloor(alt,x1,y1,x2,y2,x3,y3,x4,y4)
  if (y1 > y2) x1,y1,x2,y2 = x2,y2,x1,y1
  if (y3 > y4) x3,y3,x4,y4 = x4,y4,x3,y3
  if (y1 > y3) x1,y1,x3,y3 = x3,y3,x1,y1
  if (y2 > y4) x2,y2,x4,y4 = x4,y4,x2,y2
  if (y2 > y3) x2,y2,x3,y3 = x3,y3,x2,y2

  local s1,s2,s3--,s4

  s1 = x1+(x4-x1)/(y4-y1)*(y2-y1)
  s3 = x1+(x3-x1)/(y3-y1)*(y2-y1)

  if abs(s1 - x2) < abs(s3- x2) then
    s1 = s3
    s2 = x2+(x4-x2)/(y4-y2)*(y3-y2) -- s4
  else
    s2 = x1+(x4-x1)/(y4-y1)*(y3-y1)
  end

  if (s1 < x2) x2, s1 = s1, x2
  if (s2 < x3) x3, s2 = s2, x3

  floortrapeze(x1,x1,x2,s1,y1,y2,alt)
  floortrapeze(x2,s1,x3,s2,y2,y3,alt)
  floortrapeze(x3,s2,x4,x4,y3,y4,alt)
end

function round(val)
  local d = val % 1
  if d < 0.5 then return flr(val) else return flr(val+1) end
end

function drawfloortileold(fx, fy, fz, s)
  -- local x1,y1 = worldtocam(fx,fy)
  -- local x2,y2 = worldtocam(fx+1,fy)
  -- local x3,y3 = worldtocam(fx+1,fy+1)
  -- local x4,y4 = worldtocam(fx,fy+1)
  local ox,oy = fx-s*2-0.5,fy-0.5

  local x1,y1 = worldtocam(fx,fy)
  local x2,y2 = x1+cam_dircos,y1+cam_dirsin
  local x3,y3 = x1+cam_dircos-cam_dirsin,y1+cam_dirsin+cam_dircos
  local x4,y4 = x1-cam_dirsin,y1+cam_dircos

  -- local dx,dy = (cam_dircos-cam_dirsin)*0.5,(cam_dirsin+cam_dircos)*0.5
  -- local x1,y1 = fx-dx,fy-dy
  -- local x2,y2 = fx-dy,fy+dx
  -- local x3,y3 = fx+dx,fy+dy
  -- local x4,y4 = fx+dy,fy-dx
  -- ox,oy = ox-s*2-0.5,oy-0.5

  if (y1 < y2) x1,y1,x2,y2 = x2,y2,x1,y1
  if (y3 < y4) x3,y3,x4,y4 = x4,y4,x3,y3
  if (y1 < y3) x1,y1,x3,y3 = x3,y3,x1,y1
  if (y2 < y4) x2,y2,x4,y4 = x4,y4,x2,y2
  if (y2 < y3) x2,y2,x3,y3 = x3,y3,x2,y2

  if (y1 < cam_near) return

  local alt,tra = cam_z-fz,3
  local x2b,x3b,x4b

  if y2 < cam_near then
    tra = 1
    x2,y2 = x1+(x2-x1)/(y2-y1)*(cam_near-y1),cam_near
  end

  x2b = x1+(x4-x1)/(y4-y1)*(y2-y1)
  x3b = x1+(x3-x1)/(y3-y1)*(y2-y1)

  if abs(x2b - x2) < abs(x3b- x2) then
    x2b = x3b
    x3b = x2+(x4-x2)/(y4-y2)*(y3-y2)
  else
    x3b = x1+(x4-x1)/(y4-y1)*(y3-y1)
  end

  if (x2b < x2) x2, x2b = x2b, x2
  if (x3b < x3) x3, x3b = x3b, x3

  if tra > 1 then
    if y3 < cam_near then
      tra = 2
      x3 = x2+(x3-x2)/(y3-y2)*(cam_near-y2)
      x3b = x2b+(x3b-x2b)/(y3-y2)*(cam_near-y2)
      y3 = cam_near
    else
      x4b = x4
      if y4 < cam_near then
        x4 = x4+(x4-x3)/(y3-y4)*(y4-cam_near)
        x4b = x4b+(x4b-x3b)/(y3-y4)*(y4-cam_near)
        y4 = cam_near
      end
    end
  end
  
  --[[debug
  if fz==1 then
    local s = -30
    line(-60,cam_near*s,60,cam_near*s,13)
    line(x1*s,y1*s,x2*s,y2*s,7)
    line(x1*s,y1*s,x2b*s,y2*s,7)
    line(x2*s,y2*s,x2b*s,y2*s,7)

    if tra >= 2 then
      line(x2*s,y2*s,x3*s,y3*s,7)
      line(x2b*s,y2*s,x3b*s,y3*s,7)
      line(x3*s,y3*s,x3b*s,y3*s,7)
    end

    if tra >= 3 then
      line(x3*s,y3*s,x4*s,y4*s,7)
      line(x3b*s,y3*s,x4b*s,y4*s,7)
      line(x4*s,y4*s,x4b*s,y4*s,7)
    end
  end--]]

  local df = projplanedist / y1
  x1,y1 = x1*df, alt*df

  df = projplanedist / y2
  x2,x2b,y2 = x2*df, x2b*df, alt*df
  floortrapeze(x1,x1,x2,x2b,y1,y2,alt,ox,oy)

  if (tra < 2) return
  df = projplanedist / y3
  x3,x3b,y3 = x3*df, x3b*df, alt*df
  floortrapeze(x2,x2b,x3,x3b,y2,y3,alt,ox,oy)

  if (tra < 3) return
  df = projplanedist / y4
  x4,x4b,y4 = x4*df, x4b*df, alt*df
  floortrapeze(x3,x3b,x4,x4b,y3,y4,alt,ox,oy)
end

function floortrapeze(l,r,lt,rt,y1,y2,alt,ox,oy)
  if (y1==y2) return
  local s=sgn(y2-y1)
  lt,rt=(lt-l)/(y2-y1)*s,(rt-r)/(y2-y1)*s
  
  for y1=y1,mid(y2,disp_top,disp_bottom),s do
    if r >= -64 and l < 64 then
      local la,ra = mid(-64,flr(l), 63), mid(-64,flr(r), 63)

      local lx,ly = getfloorpos(la,y1,alt)
      local rx,ry = getfloorpos(ra,y1,alt)

      local sd = ra-la
      pald(projplanedist*alt/y1)
      tline(la,y1,ra,y1,lx-ox,ly-oy,(rx-lx)/sd,(ry-ly)/sd)
      --rectfill(la,y1,ra,y1,7)

      --pset(la,y1,7) pset(ra,y1,8)
    end

    l+=lt
    r+=rt
  end
end