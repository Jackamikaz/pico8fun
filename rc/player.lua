player = {}
player.pos = newvector(8.5, 7.5)
player.alt = 0
player.size = 2.5
player.dir = 0.25
player.speed = 1 / 8
player.turnrate = 1 / 80
player.radius = 0.2
player.height = 0.6
player.vvel = 0
player.grounded = true

setmetatable(player,{__index=_ENV})

function player.draw(_ENV)
  local screenpos = pos * 8
  circfill(screenpos.x, screenpos.y, size, 6)
  local ppos = screenpos + getunitdir(_ENV) * size
  pset(ppos.x, ppos.y, 8)
end

function player.getunitdir(_ENV)
  return newvector(cos(dir), sin(dir))
end

function player.update(_ENV)
  --printh(sqrlinedist(pos.x,pos.y,0,6,4,6))

  dir += (btnn(⬅️) - btnn(➡️)) * turnrate
  
  local lm = luamap(flr(pos.x), flr(pos.y))
  local touchingladder = false
  if lm and not lm.solid and lm.walls
  and alt < max(lm.walls[5],lm.walls[6])
  and sqrlinedist(pos.x,pos.y,unpack(lm.walls,1,4)) <= radius*radius then
    touchingladder = true
  end

  if btn(⬆️) and touchingladder then
    alt += speed
    grounded = false
  end

  local ground = 0
  if lm.floors then
    for i = 1,#lm.floors,2 do
      local z = lm.floors[i]
      if alt < z then
        break
      else
        ground = z
      end
    end
  end

  if not touchingladder then
    vvel -= 0.01
    if btnp(❎) and grounded then
      vvel = 0.085
      grounded = false
    end
    alt += vvel
  end

  if alt < ground then
    vvel = 0
    alt = ground
    grounded = true
  else
    grounded = false
  end

  local mov = getunitdir(_ENV) * speed * (btnn(⬆️) - btnn(⬇️))

  local function wallat(x,y)
    local lm = luamap(x,y)
    return lm and lm.solid and alt < lm.walls[6] and alt+height > lm.walls[5]
  end

  local my = flr(pos.y)
  local nx = flr(pos.x + sgn(mov.x)*radius)
  if (not wallat(nx,my)) pos.x += mov.x

  local mx = flr(pos.x)
  local ny = flr(pos.y + sgn(mov.y)*radius)
  if (not wallat(mx,ny)) pos.y += mov.y
end

function player:copytocam()
  cam_x = self.pos.x
  cam_y = self.pos.y
  cam_z = self.alt + 0.5
  setcamdir(self.dir)
end
