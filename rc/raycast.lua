function floorcast(alt)
  for y=1,63 do
    local lx,ly,fd = getfloorpos(-64,y,cam_z-alt)
    local rx,ry = getfloorpos(63,y,cam_z-alt)

    pald(fd)
    tline(-64,y,63,y,lx,ly,(rx-lx)/128,(ry-ly)/128)
  end
end

function raycast()
  for x=-64,63 do
    local raydir = cam_dir + rayDir[x]
    --local rx = cos(raydir)
    --local ry = sin(raydir)
    --local cx,cy,d,mr = raydda(cam_x, cam_y, rx, ry, cam_far)
    local d,cx,cy,mr = 0
    raydda:start(cam_x,cam_y,cos(raydir),sin(raydir))
    while d < cam_far do
      raydda:next()
      d = raydda.d
      mr = raydda:map()
      if mr and mr.walls then
        cx,cy = raydda:point()
        break
      end
    end
    if cx then
      local tx = abs(cx % 1)
      local ty = abs(cy % 1)
      local c
      if abs(tx - 0.5) < abs(ty - 0.5) then
        c = tx
      else
        c = ty
      end

      local m = mr.walls[1][7] or 1
      local depthfactor = antiFishEye[x] * projplanedist / d
      local walltop = -(1-cam_z) * depthfactor
      sspr((m%16 + c)*8,m\16*8,1,8,x,walltop+1,1,depthfactor + walltop%1)

      --local halfwall = flr(antiFishEye[x] * 0.5 * projplanedist / d)
      --sspr((m%16 + c)*8,m\16*8,1,8,x,-halfwall+1,1,halfwall*2)
    end
  end
end