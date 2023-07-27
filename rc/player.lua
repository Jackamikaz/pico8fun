player = {}
player.pos = vec:new(8.5, 7.5)
player.alt = 0.5
player.size = 2.5
player.dir = 0.25
player.speed = 1 / 8
player.turnrate = 0.0125
player.radius = 0.2

function player:draw()
  local screenpos = self.pos * 8
  circfill(screenpos.x, screenpos.y, self.size, 6)
  local ppos = screenpos + self:getunitdir() * self.size
  pset(ppos.x, ppos.y, 8)
end

function player:getunitdir()
  return vec:new(cos(self.dir), sin(self.dir))
end

function btnn(b)
  return btn(b) and 1 or 0
end

function player:update()
  self.dir += (btnn(⬅️) - btnn(➡️)) * self.turnrate
  local mov = self:getunitdir() * self.speed * (btnn(⬆️) - btnn(⬇️))

  local function wallat(x,y)
    local lm = luamap[x | y << 8]
    return lm and lm.walls ~= nil
  end

  local my = flr(self.pos.y)
  local nx = flr(self.pos.x + sgn(mov.x)*self.radius)
  if (not wallat(nx,my)) self.pos.x += mov.x

  local mx = flr(self.pos.x)
  local ny = flr(self.pos.y + sgn(mov.y)*self.radius)
  if (not wallat(mx,ny)) self.pos.y += mov.y
end

function player:copytocam()
  cam_x = self.pos.x
  cam_y = self.pos.y
  cam_z = self.alt
  setcamdir(self.dir)
end