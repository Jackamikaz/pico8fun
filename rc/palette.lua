-- fadepal = {
--   split"[0]=0,0,1,1,2,1,13,6,4,4,9,3,13,1,13",
--   split"[0]=14,0,0,0,0,1,0,1,13,2,2,4,1,1,0,1,13",
--   split"[0]=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
--   }

function initfadepal()
  poke(0x4300,unpack(split"0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,0,1,1,2,1,13,6,4,4,9,3,13,1,13,14,0,0,0,0,1,0,1,13,2,2,4,1,1,0,1,13,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"))
  currentfadepal=0
end

function setfadepal(newpal)
    -- thanks to freds72 again https://freds72.itch.io/poom/devlog/241700/journey-to-poom
    if(currentfadepal!=newpal) memcpy(0x5f00,0x4300|newpal<<4,16) currentfadepal=newpal
end

-- sets a darkened palette depending on distance
function pald(d)
  if d > cam_far then
    setfadepal(3)
  elseif d > cam_far-1 then
    setfadepal(2)
  elseif d > cam_far-2 then
    setfadepal(1)
  else
    setfadepal(0)
  end
end