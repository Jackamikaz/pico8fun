function buildluamap()
  luamap = {}

  for y = 0,63 do
    for x = 0,127 do
      local m = mget(x,y)
      if fget(m, 0) then
        local w = {}
        if not fget(mget(x-1,y),0) then
          append(w,x,y,0,x,y+1,1,m)
        end
        if not fget(mget(x+1,y),0) then
          append(w,x+1,y+1,0,x+1,y,1,m)
        end
        if not fget(mget(x,y-1),0) then
          append(w,x+1,y,0,x,y,1,m)
        end
        if not fget(mget(x,y+1),0) then
          append(w,x,y+1,0,x+1,y+1,1,m)
        end
        luamap[x | y << 8] = {walls=w}
      elseif m~=0 then
        luamap[x | y << 8] = {floors={m,0}}
      end
    end
  end

  -- roof test for wood cabin
  --local roof = {5,1}
  local function setroof(x,y,z)
    local lm = luamap[x | y << 8]
    if (not lm) lm = {}
    local floors = lm.floors or {}
    append(floors,5,z)
    lm.floors = floors
    luamap[x | y << 8] = lm
  end

  for x=5,9 do
    for y=0,3 do
      setroof(x,y,1)    
    end
  end
  for i=0.1,1,0.1 do
    setroof(6,9,i)
  end

  -- rework floor sprites for their tline'ing
  poke(0x5f55,0x00)
  for i=1,127 do
    if fget(i) == 0 then
      rectfill(0,0,7,7,0)
      spr(i,0,0)
      local x,y = i*8%128,flr(i/16)*8
      rectfill(x,y,x+7,y+7,0)
      sspr(4,4,4,4,x  ,y  )
      sspr(0,4,4,4,x+4,y  )
      sspr(0,0,4,4,x+4,y+4)
      sspr(4,0,4,4,x  ,y+4)
    end
  end
  poke(0x5f55,0x60)

  -- set the map for "tline'ing the sprite sheet"
  for i=0,127 do
    local x,y = i*2%128,flr(i/64)*2
    mset(x,y,i)
    mset(x+1,y,i)
    mset(x,y+1,i)
    mset(x+1,y+1,i)
  end
end