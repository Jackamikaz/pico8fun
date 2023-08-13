-- fadepal = {
--   split"[0]=0,0,1,1,2,1,13,6,4,4,9,3,13,1,13",
--   split"[0]=14,0,0,0,0,1,0,1,13,2,2,4,1,1,0,1,13",
--   split"[0]=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
--   }

function initfadepal()
  poke(0x4300,unpack(split"0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,0,1,1,2,1,13,6,4,4,9,3,13,1,13,14,0,0,0,0,1,0,1,13,2,2,4,1,1,0,1,13,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"))
  currentfadepal=0
end

-- sets a darkened palette depending on distance
function pald(d)
  local newfadepal
  if d > cam_far then
    newfadepal = 3
  elseif d > cam_far-1 then
    newfadepal = 2
  elseif d > cam_far-2 then
    newfadepal = 1
  else
    newfadepal = 0
  end

  -- thanks to freds72 again https://freds72.itch.io/poom/devlog/241700/journey-to-poom
  if(currentfadepal!=newfadepal) memcpy(0x5f00,0x4300|newfadepal<<4,16) currentfadepal=newfadepal
end