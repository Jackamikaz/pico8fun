function setupcamera()
  cam_x = 0
  cam_y = 0
  cam_z = 0
  cam_far = 6
  cam_near = 0.085
  disp_top = -64
  disp_bottom = 64
  setcamdir()
end

function setcamdir(newdir)
  cam_dir = newdir or 0
  cam_dircos = cos(cam_dir)
  cam_dirsin = sin(cam_dir)
end

function setfov(fov)
  cam_halffov = fov/2
  projplanedist = -64 * cos(cam_halffov) / sin(cam_halffov) --half screen width / tan(fov/2)
  rayDir = {}
  antiFishEye = {}
  for x=-64,63 do
    rayDir[x] = atan2(projplanedist, x)
    antiFishEye[x] = 1 / cos(rayDir[x])
  end
end

function getfarsegment()
  local la,ra = cam_dir+cam_halffov,cam_dir-cam_halffov
  local d = cam_far/cos(cam_halffov)
  return cam_x + cos(la)*d, cam_y + sin(la)*d, cam_x + cos(ra)*d, cam_y + sin(ra)*d
end