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

-- tpoly from freds72 picocad client https://github.com/freds72/picocad-client 
function tpoly(poly)
  local p0=poly[#poly]
	local spans,x0,y0,z0,u0,v0={},p0[1],p0[2],p0[3],p0[4],p0[5]
	-- ipairs is slower for small arrays
	for i=1,#poly do
    local p1=poly[i]
		local x1,y1,z1,u1,v1=p1[1],p1[2],p1[3],p1[4],p1[5]
		local _x1,_y1,_z1,_u1,_v1=x1,y1,z1,u1,v1
		if(y0>y1) x0,y0,z0,x1,y1,z1,u0,v0,u1,v1=x1,y1,z1,x0,y0,z0,u1,v1,u0,v0
		local dy=y1-y0
		local dx,dz,du,dv=(x1-x0)/dy,(z1-z0)/dy,(u1-u0)/dy,(v1-v0)/dy
		local cy0=y0\1+1
    local topcut = y0-disp_top
		if(topcut<0) x0-=topcut*dx z0-=topcut*dz u0-=topcut*du v0-=topcut*dv y0=disp_top cy0=disp_top
		-- sub-pix shift
		local sy=cy0-y0
		x0+=sy*dx
    z0+=sy*dz
		u0+=sy*du
		v0+=sy*dv
		if(y1>disp_bottom) y1=disp_bottom
		for y=cy0,y1 do
			local span=spans[y]
			if span then
				local ax,au,av,bx,bu,bv=x0,u0,v0,span[1],span[2],span[3]
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
				spans[y]={x0,u0,v0}
			end
			x0+=dx
      z0+=dz
			u0+=du
			v0+=dv
		end
		x0,y0,z0,u0,v0=_x1,_y1,_z1,_u1,_v1
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
  if (#poly==0) return
  for i=1,#poly do
    local p=poly[i]
    local df = projplanedist / p[2]
    p[1],p[2],p[3] = p[1]*df, alt*df, p[2]
  end
  tpoly(poly)
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