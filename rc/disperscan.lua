function disperscan(func,...)
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
          func(flr(msx),flr(msy),...)
          msx -= pdx*f msy -= pdy*f
        end
      end
    end
    func(flr(sx),flr(sy),...)
    sx += dx sy += dy
  end
end