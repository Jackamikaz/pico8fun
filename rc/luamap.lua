function luamapset(x,y,v)
  luamap[x | y << 8] = v
end

function buildluamap()
  luamap = setmetatable({},{__call = function(self,x,y) return self[x | y << 8] end})

  for y = 0,63 do
    for x = 0,127 do
      local m = mget(x,y)
      -- ladder on [10,5]
      if x==10 and y==5 then
        luamapset(x,y,{walls={x+0.1,y+1,x+0.1,y,0,1,20}, floors={0,m}})
      elseif fget(m, 0) then
        local w = {}
        local h = 1
        if (m==1) h=2 --high walls
        if not fget(mget(x-1,y),0) then
          append(w,x,y,x,y+1,0,h,m)
        end
        if not fget(mget(x+1,y),0) then
          append(w,x+1,y+1,x+1,y,0,h,m)
        end
        if not fget(mget(x,y-1),0) then
          append(w,x+1,y,x,y,0,h,m)
        end
        if not fget(mget(x,y+1),0) then
          append(w,x,y+1,x+1,y+1,0,h,m)
        end
        luamapset(x,y,{walls=w,solid=true})
      elseif m~=0 then
        luamapset(x,y,{floors={0,m}})
      end
    end
  end

  -- roof test for wood cabin
  --local roof = {5,1}
  local function setroof(x,y,z,s)
    local lm = luamap(x,y) or {}
    local floors = lm.floors or {}
    append(floors,z,s)
    lm.floors = floors
    luamapset(x,y,lm)
  end

  for x=5,9 do
    for y=2,5 do
      setroof(x,y,1,5)    
    end
  end

  -- some platforming to test to
  local function addplatform(x,y,z)
    local lm = luamap(x,y) or {}
    local floors = lm.floors or {}
    local walls = lm.walls or {}

    local z1 = z-0.2

    append(floors,z1,17)
    append(floors,z,17)

    append(walls,x,y,x,y+1,z1,z,17)
    append(walls,x+1,y+1,x+1,y,z1,z,17)
    append(walls,x+1,y,x,y,z1,z,17)
    append(walls,x,y+1,x+1,y+1,z1,z,17)

    lm.floors = floors
    lm.walls = walls
    lm.solid = true
    luamapset(x,y,lm)
  end

  addplatform(5,7,1.3)
  addplatform(5,9,1.6)
  addplatform(7,9,1.9)
  addplatform(9,9,2.2)
  addplatform(9,7,2.5)
  addplatform(9,5,2.8)
  
  for x=8,10 do
    for y=3,4 do
      setroof(x,y,2.8,17)    
    end
  end

  -- stress test
  --for i=0.1,1,0.1 do
  --  setroof(6,9,i)
  --end

  -- rework floor sprites for their tline'ing
  poke(0x5f55,0x00)
  for i=1,127 do
    if fget(i) == 0 then
      rectfill(0,0,7,7,0)
      spr(i,0,0)
      local x,y = i*8%128,i\16*8
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
    local x,y = i*2%128,i\64*2
    mset(x,y,i)
    mset(x+1,y,i)
    mset(x,y+1,i)
    mset(x+1,y+1,i)
  end

  -- sampling section for the walls
  for x=0,1 do
    for y=4,10 do
      mset(x,y,1)
    end
  end
end

