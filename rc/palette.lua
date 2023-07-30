fadepal = {
  split"[0]=0,0,1,1,2,1,13,6,4,4,9,3,13,1,13",
  split"[0]=14,0,0,0,0,1,0,1,13,2,2,4,1,1,0,1,13",
  split"[0]=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
  }
  
-- sets a darkened palette depending on distance
function pald(d)
  if d > cam_far then
    pal(fadepal[3])
  elseif d > cam_far-1 then
    pal(fadepal[2])
  elseif d > cam_far-2 then
    pal(fadepal[1])
  else
    pal()
  end
end