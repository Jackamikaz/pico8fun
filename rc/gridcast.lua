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
  return cam_x + cos(raydir) * floordist, cam_y + sin(raydir) * floordist
end

-- translate world position to camera coordinates
function worldtocam(wx,wy)
  wx,wy = wy-cam_y, wx-cam_x
  return wx*cam_dircos - wy*cam_dirsin, wx*cam_dirsin + wy*cam_dircos
end

-- tpoly adapted from freds72 picocad client https://github.com/freds72/picocad-client 
function tpoly(poly)
  local p0=poly[#poly]
  local spans,x0,y0,z0,u0,v0={},p0[1],p0[2],p0[3],p0[4],p0[5]
  -- ipairs is slower for small arrays
  for i=1,#poly do
    local p1=poly[i]
    local x1,y1,z1,u1,v1=p1[1],p1[2],p1[3],p1[4],p1[5]
    local _x1,_y1,_z1,_u1,_v1=x1,y1,z1,u1,v1
    if(y0>y1) x0,y0,z0,x1,y1,z1,u0,v0,u1,v1=x1,y1,z1,x0,y0,z0,u1,v1,u0,v0
    local z0o,t,dy=z0,0,y1-y0
    local dx,dz,dt=(x1-x0)/dy,(z1-z0)/dy,256/dy
    local cy0=y0\1+1
    local topcut = y0-disp_top
    if(topcut<0) x0-=topcut*dx z0-=topcut*dz t-=topcut*dt y0=disp_top cy0=disp_top
    -- sub-pix shift
    local sy=cy0-y0
    x0+=sy*dx
    z0+=sy*dz
    t+=sy*dt
    for y=cy0,min(y1,disp_bottom) do
      local span=spans[y]
      local omt = 256-t
      local det = omt/z0o+t/z1
      local u,v = (omt*u0/z0o+t*u1/z1)/det,(omt*v0/z0o+t*v1/z1)/det
      --local u,v=omt*u0+t*u1>>8,omt*v0+t*v1>>8
      if span then
        span.used=true
        local ax,au,av,bx,bu,bv=x0,u,v,span[1],span[2],span[3]
        if(ax>bx) ax,au,av,bx,bu,bv=bx,bu,bv,ax,au,av
        local cax,cbx=ax\1+1,bx\1
        if cax<=cbx then
          -- pixel perfect sampling
          local sa,dab=cax-ax,bx-ax
          local dau,dav=(bu-au)/dab,(bv-av)/dab
          --rectfill(cax,y,cbx,y,11)
          pald(z0)
          tline(cax,y,cbx,y,au+sa*dau,av+sa*dav,dau,dav)
        end
      else
        spans[y]={x0,u,v}
      end
      x0+=dx
      z0+=dz
      t+=dt
    end
    x0,y0,z0,u0,v0=_x1,_y1,_z1,_u1,_v1
  end
end

function warpindex(i,s)
  return (i-1)%s+1
end

function tpolyb(poly)
  -- find highest point in polygon
  local ps,topy,topi=#poly,0x7fff
  for i=1,ps do
    local y=poly[i][2]
    if (y<topy) topy=y topi=i
  end
  -- the traversal direction depends on the polygon being clockwise or not
  -- so we check the sign of the Z value of a cross product between two segments
  local pc,pl,pr=poly[topi],poly[topi%ps+1],poly[(topi-2)%ps+1]
  local ax,ay,bx,by,cx,cy=pc[1]>>3,topy>>3,pl[1]>>3,pl[2]>>3,pr[1]>>3,pr[2]>>3
  local dir=sgn((bx-ax)*(cy-ay) - (by-ay)*(cx-ax))
  -- declare all used variables
  local lx,llz,lz,lt,lu0,lv0,ldx,ldz,ldt,rx,rlz,rz,rt,ru0,rv0,rdx,rdz,rdt
  -- prefill values for the next point in the segment (here it's the top one)
  local li,ri=topi,topi
  local lnx,lny,lnz,lu1,lv1 = unpack(pc)
  local rnx,rny,rnz,ru1,rv1 = lnx,lny,lnz,lu1,lv1
  local c=0
  -- top and bottom clipping is managed by the for loop
  for y=max(topy\1+1,disp_top),disp_bottom do
    -- trigger traversal to the next segment (will trigger the first time)
    while y>lny do
      -- triggering more than the number of points means we're done
      c+=1
      if (c>ps) return
      -- replace current point with values we already have, then get next point
      li=(li-1-dir)%ps+1
      local pli=poly[li]
      lx,lz,llz,lt,lu0,lv0,lu1,lv1=lnx,lnz,lnz,0,lu1,lv1,pli[4],pli[5]
      lnx,lnz=pli[1],pli[3]
      -- calculate slopes
      local ny=pli[2]
      local dy,sy=ny-lny,y-lny
      lny=ny
      ldx,ldz,ldt = (lnx-lx)/dy, (lnz-lz)/dy, 256/dy
      -- sub pixel shift
      lx += sy*ldx
      lz += sy*ldz
      lt += sy*ldt
    end
    -- same with the other direction
    while y>rny do
      c+=1
      if (c>ps) return
      ri=(ri-1+dir)%ps+1 -- the only difference is adding dir
      local pri=poly[ri]
      rx,rz,rlz,rt,ru0,rv0,ru1,rv1=rnx,rnz,rnz,0,ru1,rv1,pri[4],pri[5]
      rnx,rnz=pri[1],pri[3]
      local ny=pri[2]
      local dy,sy=ny-rny,y-rny
      rny=ny
      rdx,rdz,rdt = (rnx-rx)/dy, (rnz-rz)/dy, 256/dy
      rx += sy*rdx
      rz += sy*rdz
      rt += sy*rdt
    end

    local clx,crx=lx\1+1,rx\1
    if clx<=crx then
      -- almost perspective correct u,v, for both sides
      local omt = 256-lt
      local det = omt/llz+lt/lnz
      local lu,lv=(omt*lu0/llz+lt*lu1/lnz)/det,(omt*lv0/llz+lt*lv1/lnz)/det
  
      omt = 256-rt
      det = omt/rlz+rt/rnz
      local ru,rv=(omt*ru0/rlz+rt*ru1/rnz)/det,(omt*rv0/rlz+rt*rv1/rnz)/det

      -- pixel perfect sampling
      local sa,dab=clx-lx,rx-lx
      local dau,dav=(ru-lu)/dab,(rv-lv)/dab
      pald(lz+rz>>1)
      tline(clx,y,crx,y,lu+sa*dau,lv+sa*dav,dau,dav)
      --rectfill(clx,y,crx,y,5+c)
    end

    -- next scanline
    lx+=ldx
    rx+=rdx
    lz+=ldz
    rz+=rdz
    lt+=ldt
    rt+=rdt
  end
end

function clippolyh(poly,cuty)
  local p0=poly[#poly]
  local cutprev,i = p0[2] > cuty,1
  while i<=#poly do
    local p=poly[i]
    local cutcurr = p[2] > cuty
    if cutcurr~=cutprev then
      local t=(cuty-p0[2])/(p[2]-p0[2])
      add(poly,{p0[1]+(p[1]-p0[1])*t,cuty,0,p0[4]+(p[4]-p0[4])*t,p0[5]+(p[5]-p0[5])*t},i)
      i+=1
    end
    if not cutcurr then
      deli(poly,i)
    else
      i+=1
    end
    p0=p
    cutprev=cutcurr
  end
end

function drawfloortile(fx, fy, fz, s)
  local alt,x1,y1 = cam_z-fz,worldtocam(fx,fy)
  local poly={
    {x1,y1,0,s,0},
    {x1+cam_dircos,y1+cam_dirsin,0,s+1,0},
    {x1+cam_dircos-cam_dirsin,y1+cam_dirsin+cam_dircos,0,s+1,1},
    {x1-cam_dirsin,y1+cam_dircos,0,s,1}
  }
  clippolyh(poly,cam_near)
  if (#poly<3) return
  for i=1,#poly do
    local p=poly[i]
    local df = projplanedist / p[2]
    p[1],p[2],p[3] = p[1]*df, alt*df, p[2]
  end
  
  if btn(🅾️) then
    tpoly(poly)
  else
    tpolyb(poly)
  end
end

function drawwall(x1, y1, x2, y2, z1, z2, sp)
  -- cut the line to stay in front of the camera
  x1,y1 = worldtocam(x1,y1)
  x2,y2 = worldtocam(x2,y2)
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

  local w1 = y1
  local df = projplanedist / y1
  x1,y1 = x1*df,z1*df
  local y1b = z2*df

  local w2 = y2
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
  if x1 < -65 then
    local d = -65-x1
    y1 += tt*d
    y1b += bt*d
    d1 += dt*d
    x1 = -65
  end
  local x2b = x2
  if (x2b > 64) x2b = 64

  -- sub pixel shift
  local cx1 = x1\1+1
  local sx = cx1-x1
  y1 += tt*sx
  y1b += bt*sx
  d1 += dt*sx

  local prec=4--(time()*2)\1%5
  local prec2=prec*2
  tline(13+prec)

  -- draw!
  for x=cx1,x2b do
    local t = (x2-x)/dx
    local u = ((1-t)*t1*w1+t*t2*w2)/((1-t)*w1+t*w2)
    pald(d1)
    local cy1,cy1b = y1\1,y1b\1+1
    if sp==1 then
      local sa,dab=cy1b-y1b<<prec,y1-y1b<<prec
      u*=2
      local v=(z1-z2)*2
      local dav=((v<<prec2)/dab)
      tline(x,cy1b,x,cy1,  u<<prec,((4<<prec)+((sa*dav)>>prec)),0,dav)
      --tline(x,cy1b,  x,cy1,  u*2,4,  0,(z1-z2)/(cy1-cy1b)*2)
    else
      sspr((sp%16+u)*8,sp\16*8,1,8,x,cy1b,1,cy1-cy1b)
    end
    --line(x,y1,x,y1b)

    y1 += tt
    y1b += bt
    d1 += dt
  end

  tline(13)
end

function traverse3Dcell(x,y,ordhandler)
  local lm = luamap(x,y)
  if lm then
    local ord = {}
    local function ordcomp(a,b) return a[1] > b[1] end
    for f in all(lm.floors) do
      local d = sqrdst3(cam_x,cam_y,cam_z,x+0.5,y+0.5,f[1])
      addordered(ord,{d,1,x,y,f[1],f[2],f},ordcomp)
    end
    for w in all(luamapgetwalls(x,y)) do
      local x1,y1,x2,y2,z1,z2,m = unpack(w)
      local d = sqrdst3(cam_x,cam_y,cam_z,(x1+x2)*0.5,(y1+y2)*0.5,(z1+z2)*0.5)
      addordered(ord,{d,2,x1,y1,x2,y2,z1,z2,m,w},ordcomp)
    end
    ordhandler(ord)
  end
end

function ordhandlerdraw(ord)
  for p in all(ord) do
    (p[2]==1 and drawfloortile or drawwall)(unpack(p,3))
  end
end