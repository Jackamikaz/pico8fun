fadepal = {
  split("[0]=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15"),
  split("[0]=0,0,1,1,2,1,13,6,4,4,9,3,13,1,13"),
  split("[0]=14,0,0,0,0,1,0,1,13,2,2,4,1,1,0,1,13"),
  split("[0]=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0")
  }
  
-- sets a darkened palette depending on distance
function pald(d)
  if d > 8 then
    pal(fadepal[4])
  elseif d > 7 then
    pal(fadepal[3])
  elseif d > 5 then
    pal(fadepal[2])
  else
    pal()
  end
end