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