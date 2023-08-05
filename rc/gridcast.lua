-- translate world position to screen coordinates
--function getscreenpos(wx,wy,wz)
--  wx,wy = worldtocam(wx,wy)
--  if wy > 0.1 then
--    local df = projplanedist / wy
--    return wx * df, wz * df
--  end
--end

-- get world coordinate from a screen one given a known world z value
function getfloorpos(sx, sy, wz)
  local floordist = antiFishEye[sx] * wz * projplanedist / sy
  local raydir = cam_dir + rayDir[sx]
  return cam_x + cos(raydir) * floordist, cam_y + sin(raydir) * floordist, floordist*cos(rayDir[sx])
end

-- translate world position to camera coordinates
function worldtocam(wx,wy)
  wx,wy = wy-cam_y, wx-cam_x
  return wx*cam_dircos - wy*cam_dirsin, wx*cam_dirsin + wy*cam_dircos
end

function drawfloortile(fx, fy, fz, s)
  local ox,oy = fx-s*2-0.5,fy-0.5

  local x1,y1 = worldtocam(fx,fy)
  local x2,y2 = worldtocam(fx+1,fy)
  local x3,y3 = worldtocam(fx+1,fy+1)
  local x4,y4 = worldtocam(fx,fy+1)

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

      local lx,ly,fd = getfloorpos(la,y1,alt)
      local rx,ry = getfloorpos(ra,y1,alt)

      local sd = ra-la
      pald(fd)
      tline(la,y1,ra,y1,lx-ox,ly-oy,(rx-lx)/sd,(ry-ly)/sd)
      --rectfill(la,y1,ra,y1,7)

      --pset(la,y1,7) pset(ra,y1,8)
    end

    l+=lt
    r+=rt
  end
end

function drawwall(x1, y1, x2, y2, z1, z2, sp)
  -- cut the line to stay in front of the camera
  --pretransformed by the caller now
  --x1,y1 = worldtocam(x1,y1)
  --x2,y2 = worldtocam(x2,y2)
  if (z1>z2) z1,z2 = z2,z1
  z1,z2 = cam_z-z1,cam_z-z2
  local t1,t2 = 1,0
  if y1 < cam_near then
    if (y2 < cam_near) return
    t2 = (cam_near - y1)/(y2-y1)
    x1 += (x2-x1)*t2
    y1 = cam_near
  elseif y2 < cam_near then
    t1 = (cam_near - y2)/(y1-y2)
    x2 += (x1-x2)*t1
    y2 = cam_near
    t1 = 1-t1
  end

  -- transform coordinates for depth
  local d1,d2 = y1,y2

  local w1 = 1 / y1
  local df = projplanedist / y1
  x1,y1 = x1*df,z1*df
  local y1b = z2*df

  local w2 = 1 / y2
  df = projplanedist / y2
  x2,y2 = x2*df,z1*df
  local y2b = z2 * df

  -- making sure we draw from left to right
  --if (x1 > x2) x1,y1,y1b,w1,x2,y2,y2b,w2 = x2,y2,y2b,w2,x1,y1,y1b,w1
  -- EDIT : nope, we're culling
  if (x1 > x2 or max(y1,y2) < disp_top or min(y1b,y2b) > disp_bottom) return

  -- calculate slopes
  local dx = x2-x1
  local tt,bt,dt = (y2-y1)/dx,(y2b-y1b)/dx,(d2-d1)/dx

  -- confine to the screen edges
  if (x2 < -64 or x1 > 64) return
  if x1 < -64 then
    local d = -64-x1
    y1 += tt*d
    y1b += bt*d
    d1 += dt*d
    x1 = -64
  end
  local x2b = x2
  if (x2b > 64) x2b = 64

  -- draw!
  for x=x1,x2b do
    local t = (x2-x)/dx
    local u = ((1-t)*t1/w1+t*t2/w2)/((1-t)/w1+t/w2)
    pald(d1)
    if sp==1 then
      tline(x,y1b,  x,y1+y1b%1,  u*2,4,  0,(z1-z2)/(y1-y1b)*2)
    else
      sspr((sp%16+u)*8,sp\16*8,1,8,x,y1b,1,y1-flr(y1b))
    end
    --line(x,y1,x,y1b)

    y1 += tt
    y1b += bt
    d1 += dt
  end
end

function draw3Dcell(x,y)
  local lm = luamap(x,y)
  if lm then
    local f = lm.floors
    if f then
      local middle = 0x7fff
      for i,v in ipairs(f) do
        local z = v[1]
        if cam_z < z then
          middle = i
          break
        end
        drawfloortile(x,y,z,v[2])
      end
      for i=#f,middle,-1 do
        local v = f[i]
        drawfloortile(x,y,v[1],v[2])
      end
    end
    local ord = {}
    for v in all(lm.walls) do
      local x1,y1,x2,y2,z1,z2,m = unpack(v)
      x1,y1 = worldtocam(x1,y1)
      x2,y2 = worldtocam(x2,y2)
      local d = y1+y2--no need to divide by 2, the comparison is still correct
      addordered(ord,{d,x1,y1,x2,y2,z1,z2,m},
        function(a,b)
          return a[1] > b[1]
        end)
    end
    for w in all(ord) do
      drawwall(unpack(w,2,8))
    end
  end
end
