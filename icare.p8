pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--icare project
--work in progress

--never repeat button presses
poke(0x5f5c, 255)

--called once for saving
cartdata("icare_galereinvaders")
--dset(63,0)

--store the image in user data
bc={0,12,12,7}

function addr_col(val8)
 return bc[band(flr(val8),0x03)+1]
end

--  expand (1 byte = 4 pixels (col 0..3 each))
--  to display real colors (1 byte = 2 pixels)
local addr_src=0x1800
local addr_dst=0x4300
local max_bytes=0x800
local i, val_src8, val_dst8

for i=1,max_bytes do
 val_src8 = peek(addr_src)
 val_dst8 = addr_col(val_src8   ) + 16*addr_col(val_src8/4 )
 poke(addr_dst, val_dst8)
 val_dst8 = addr_col(val_src8/16) + 16*addr_col(val_src8/64)
 poke(addr_dst+1, val_dst8)
 addr_src+=1
 addr_dst+=2
end

--core draw and update
frame=-1
function _update()
 frame+=1
 if nextscreen then
  currentscreen = nextscreen
  currentscreen:init()
  nextscreen = nil
 end
 currentscreen:update()
end

function _draw()
 currentscreen:draw()
end

--flashing color
function flashcol(defcol,bool)
 if bool or defcol==nil then
  return frame%8+8
 end
 return defcol
end

--shadow text
function sdprint(str,x,y,col,sdcol)
 print(str,x,y+1,sdcol or 0)
 print(str,x,y,col or 7)
end

--random palette
function rndpal()
 for i=1,15 do
   pal(i,rnd(15)+1)
 end
end

--add and square
function sqr(a)
 return a*a
end
function addandsqr(a,b)
 return sqr(a+b)
end

--sign
function sign(a)
 if a<0 then
 	return -1
 elseif a>0 then
  return 1
 else
  return 0
 end
end

--new class function
--adapted from http://lua-users.org/wiki/inheritancetutorial
function newclass(inherits)
 local nc = {}
 nc.__index = nc
 
 if inherits then
  setmetatable(nc,{__index=inherits})
 end
 
 --return the class object
 --of the instance
 function nc:class()
  return nc
 end

 --return the super class object
 --of the instance
 function nc:super()
  return inherits
 end

 --return true if the caller is
 --an instance of theclass
 function nc:isa(theclass)
  local cc = nc

  while cc do
   if cc == theclass then
    return true
   else
    cc = cc:super()
   end
  end

  return false
 end
 
 return nc
end

--vector lib
vec = newclass()
function vec:new(a,b)
 return setmetatable(
  {x=a or 0,y=b or 0},
  self)
end
function vec:set(a,b)
 self.x=a
 self.y=b
end
function vec:__add(r)
 return vec:new(self.x+r.x,self.y+r.y)
end
function vec:__sub(r)
 return vec:new(self.x-r.x,self.y-r.y)
end
function vec:__mul(r)
 return vec:new(self.x*r,self.y*r)
end
function vec:__div(r)
 return vec:new(self.x/r,self.y/r)
end
function vec:__eq(r)
	return self.x == r.x and self.y == r.y
end
function vec:slen()
 return abs(self.x*self.x+self.y*self.y)
end
function vec:__len()
 return sqrt(self:slen())
end
function vec:unit()
 return self / #self
end
function vec:norm()
 local len = #self
 self.x /= len
 self.y /= len
end
--dot product
function vec:__pow(r)
 return self.x*r.x + self.y*r.y
end

--linked list
lklist = newclass()
function lklist:new()
 local n = setmetatable({},self)
 n.last = n
 return n
end
function lklist:addval(value)
 local n = {val=value}
 self.last.nxt = n
 self.last = n
end
function lklist:start()
 self.current = self
 return self:next()
end
function lklist:next()
 self.previous = self.current
 self.current = self.current.nxt 
 if self.current then
  return self.current.val
 else
  return nil
 end
end
function lklist:removecurrent()
 self.previous.nxt = self.current.nxt
 self.current = self.previous
 if not self.current.nxt then
  self.last = self.current
 end
end
function lklist:clear()
 self.nxt = nil
 self.last = self
end
function lklist:isempty()
 return self.nxt==nil
end


--starfield
stf = {}
stf[0] = {}
stf[0].col = 1
stf[0].spd = 1
stf[0].amt = 20
stf[1] = {}
stf[1].col = 5
stf[1].spd = 2
stf[1].amt = 10
stf[2] = {}
stf[2].col = 7
stf[2].spd = 6
stf[2].amt = 3

for l=0,2 do
 for i=0,stf[l].amt-1 do
  stf[l][i] = {}
  stf[l][i] = vec:new(rnd(128),rnd(128))
 end
end

function stfupdate()
 for l=0,2 do
  for i=0,stf[l].amt-1 do
   stf[l][i].y += stf[l].spd
   if stf[l][i].y>128 then
    stf[l][i].x = rnd(128)
    stf[l][i].y = -rnd(128/stf[l].amt)
   end
  end
 end
end

function stfdraw(depth)
 for l=0,depth or 2 do
  local c = stf[l].col
  for i=0,stf[l].amt-1 do
   local s = stf[l][i]
   pset(s.x,s.y,c)
  end
 end
end

-- 3d starfield
stf3d = {}
for i=1,128 do
 local star = {}
 star.x = rnd(512)-256
 star.y = rnd(512)-256
 star.z = rnd(512)
 stf3d[i] = star
end

function stf3dupdate()
 for i,star in pairs(stf3d) do
  star.z -= 5
  if star.z < 0 then
   star.x = rnd(512)-256
   star.y = rnd(512)-256
   star.z = 480+rnd(64)
  end
 end
end

function stf3ddraw()
 for i,star in pairs(stf3d) do
  local z=star.z
  if z<512 then
	  local c=1
	  if z<300 then
	   c=7
	  elseif z<450 then
	   c=5
	  end
	  local mul = 64/(z+64)
	  pset(star.x*mul+64,star.y*mul+64,c)
  end
 end
end
-->8
--scroll screen
scrollscreen = {}
sstext = [[
    galeres
    invaders
  
  voici un jeu
   qui va te
  permettre de
  shooter tes
   soucis en
  attendant ton
  rendez-vous!
  
   infojeunes
   occitanie
   
   #explorer-
     les-
   possibles
]]

function scrollscreen:init()
 ssscroll = 0
 for j=0,7 do
  for i=0,7 do
   mset(i,j,128+j*16+i)
   mset(i,j+8,128+j*16+i+8)
  end
 end
end

function scrollscreen:update()
 ssscroll += 0.02
 if btnp(❎) then
  nextscreen = titlescreen
 end
end
function scrollscreen:draw()
 cls()
 print (sstext,1,0,1)
 print (sstext,0,0,7)
 ---[[
 for i=0,63 do
  memcpy(0x1000+i*64,0x6000+i*64,32)
 end
 for i=64,127 do
  memcpy(0x1000+32+(i-64)*64,0x6000+i*64,32)
 end
 --]]

 cls()
 --map(0,0,32,32,8,32)
 stfdraw(0)

 ---[[
 for i=0,111 do
  local my = 2-256/i+ssscroll
  local s = 1
  if my > 0 then
   tline(
    32-s*i,16+i,
    96+s*2*i,16+i,
    0,my,
    8/(64+s*2*i))
  end
 end
 --]]
end

nextscreen = scrollscreen
-->8
--title screen
titlescreen = {}

function titlescreen:init()
 memcpy(0x1000,0x4300,0x1000)
 for j=0,8 do
  for i=0,15 do
   mset(i,j,128+j*16+i)
  end
 end
 tsstart=frame
end

function titlescreen:update()
 stf3dupdate()
 if btnp(❎) then
  nextscreen = difficultyscreen
 end
end

function titlescreen:draw()
 cls()
 
 stf3ddraw()
 
 --map(0,0,0,32,16,8)
 local tsframe = frame-tsstart
 local dy=32+cos(frame/60)*4
 for i=0,63 do
  local dx=(tsframe-5-i)*8-128
  if dx>0 then
   dx=0
  elseif i%2==0 then
   dx=-dx
  end
  local x=dx+cos((frame/2+i)/30)*2
  tline(x,dy+i,
        x+127,dy+i,
        0,i/8)
 end
 
 if frame%30> 15 and tsframe>90 then
  print("appuyez sur ❎",56,100,5)
 end
end
-->8
--difficulty select screen
difficultyscreen = {}

difficulty = 2

function difficultyscreen:init()
end

function difficultyscreen:update()
 stf3dupdate()
 
 if btnp(⬆️) then
  difficulty -= 1
 end
 if btnp(⬇️) then
  difficulty += 1
 end
 if btnp(❎) then
  nextscreen = gamescreen
 end
 
 difficulty = (difficulty-1) % 3+1
end

difftext = {
[1]="facile",
[2]="normal",
[3]="difficile"
}

function difficultyscreen:draw()
 cls()
 
 stf3ddraw()
 
 for i=1,3 do
  local y=30+i*16
  local cur = i==difficulty
  if (cur) sdprint(">",32,y,7,1)
  sdprint(difftext[i],44,y,flashcol(7,cur),1)
 end
end
-->8
--game screen
gamescreen = {}

--score particles
scoreparticles = lklist:new()
function spawnscorepart(a,b,val)
 scoreparticles:addval(
 {x=a,y=b,life=0,s=val})
end

function scoreparticleupdate()
 local p=scoreparticles:start()
 while p do
  p.y-=1
  p.life+=1
  if p.life >= 20 then
   scoreparticles:removecurrent()
  end
  p=scoreparticles:next()
 end
end

function scoreparticledraw()
 local p=scoreparticles:start()
 while p do
  print("+"..p.s,p.x,p.y,7)
  p=scoreparticles:next()
 end
end

--particles
particles = lklist:new()
function spawnparticle(part)
 particles:addval(part)
end

function particleupdate()
 local p=particles:start()
 while p do
  p.life += 1
  local pl = p.life
  if pl > p.duration then
   particles:removecurrent()
  elseif pl > 0 then
   if (p.cols[pl]) p.col = p.cols[pl]
   if (p.sizes[pl]) p.size = p.sizes[pl]
   p.x += p.dx
   p.y += p.dy
  end
  p=particles:next()
 end
end

function particledraw()
 local p=particles:start()
 while p do
  if p.life > 0 then
   circfill(p.x,p.y,p.size,p.col)
  end
  p=particles:next()
 end
end

function particleexplosion(a,b)
 for j=-10,0 do
  for i=1,5 do
   local r = rnd(360)/360
   local p = {}
   p.duration = 8
   p.x = a
   p.y = b
   p.dx = cos(r)*1.5
   p.dy = sin(r)*1.5
   p.life = j
   p.col = 8
   p.cols = {}
   p.cols[3] = 9
   p.cols[5] = 10
   p.cols[7] = 5
   p.size = 1
   p.sizes = {}
   p.sizes[2] = 2
   p.sizes[4] = 2.5
   p.sizes[6] = 2
   p.sizes[7] = 1
   particles:addval(p)
  end
 end
end

--bullets
bullets = lklist:new()

function bulletcreate(a,b)
 bullets:addval({x=a,y=b-2,c=8})
end

function bulletupdate()
 local b = bullets:start()
 while b do
  b.y -= 5
  if b.y < 0 then
   bullets:removecurrent()
  else
   b.c += 1
   if (b.c>10) b.c=8
  end  
  b = bullets:next()
 end
end

function bulletdraw()
 local b = bullets:start()
 while b do
  line(b.x,b.y-2,b.x,b.y+3,b.c)
  b = bullets:next()
 end
end

--enemies
enemies = lklist:new()

--base enemy class
enemy = newclass()
function enemy:new()
 return setmetatable({
 pos=vec:new(),
 spd=vec:new(),
 sprn=0,
 sprw=1,
 sprh=1,
 sprfx=false,
 sprfy=false,
 radius=4,
 life=1,
 value=1,
 hit=0
 },self)
end
function enemy:checkbullets(deathfunc,hitsnd)
 local b=bullets:start()
 while b do
  local bpos = vec:new(b.x,b.y)
  if (self.pos-bpos):slen() < sqr(self.radius) then
   self.life -= hitstr
   if self.life <= 0 then
    if deathfunc then
     deathfunc(self)
    else
     self:die()
    end
   else
    self.hit = 10
    sfx(hitsnd or 3)
   end
   b = nil
   bullets:removecurrent()
  else
   b = bullets:next()
  end
 end
end
function enemy:givescore()
 local scoreval = self.value*scoremul
 score += scoreval
 spawnscorepart(self.pos.x,self.pos.y,scoreval)
end
function enemy:die()
 particleexplosion(self.pos.x,self.pos.y)
 enemies:removecurrent()
 sfx(1)
 self:givescore()
end
function enemy:delayeddeath()
 if self.deathcountdown then
  self.deathcountdown-=1
  if self.deathcountdown<=0 then
   self:die()
  end
  return true
 end
 return false
end
function enemy:removeiftoolow()
 if self.pos.y > 128+self.radius then
  enemies:removecurrent()
 end
end
function enemy:bouncex(alsoy)
 local spx = self.pos.x
 local l = self.radius
 local r = 128-self.radius
 if self.canbounce then
	 if spx < l and self.spd.x < 0
	 or spx > r and self.spd.x > 0 then
	  self.spd.x *= -1
	 end
	 if alsoy then
	  local spy = self.pos.y
	  if spy < l and self.spd.y < 0
	  or spy > r and self.spd.y > 0 then
	   self.spd.y *= -1
	  end
	 end
	else
	 self.canbounce = spx > l and spx < r
	end
end
function enemy:update()
 --empty
end
function enemy:hitpal()
 if self.hit>0 then
  rndpal()
  self.hit-=1
 end
end
function enemy:draw()
 self:hitpal()
 spr(self.sprn,
  self.pos.x-self.sprw*4,
  self.pos.y-self.sprh*4,
  self.sprw,self.sprh,
  self.sprfx,self.sprfy)
 pal()
end

--helper to multi-direction
--sprite. s get its sprn, sprfx
--and sprfy members modified
--a = angle
--r = sprite right
--d = sprite diagonal
--u = sprite up
function getspriteturn(
 s,a,r,d,u)
 local ca = cos(a)
 local sa = sin(a)
 local aca = abs(ca)
 local asa = abs(sa)
 if abs(aca-asa)<0.541 then
  s.sprn=d
 elseif aca>asa then
  s.sprn=r
 else
  s.sprn=u
 end
 s.sprfx = ca<0
 s.sprfy = sa>0
end

--weak common enemy
enemyweak = newclass(enemy)
function enemyweak:new()
 local n = self:super():new()
 n.sprn = 2
 n.value = 2
 return setmetatable(n,self)
end
function enemyweak:update()
 self.pos += self.spd
 self:bouncex()
 self:checkbullets()
 self:removeiftoolow()
end

function spawnweakenemy(a,b,c,d)
 local e=enemyweak:new()
 e.pos:set(a,b)
 e.spd:set(c*spdmul,d*spdmul)
 enemies:addval(e)
end

--big enemy
enemybig = newclass(enemy)
function enemybig:new()
 local n = self:super():new()
 n.sprn=3
 n.sprw=2
 n.sprh=2
 n.radius=7
 n.life=20
 n.value=18
 n.spd.x=spdmul
 n.y=30
 n.mtimer=46*spawnmul
 return setmetatable(n,self)
end

function enemybig:update()
 --move
 self.pos.x += self.spd.x
 self:bouncex()
 self.pos.y=self.y+sin(frame/60)*12
 
 --spawn missiles
 local st=sign(self.mtimer)
 self.mtimer -= st
 if self.mtimer==0 then
  sfx(5)
  self.mtimer=-st*60
  spawnmissile(
   self.pos.x+6.5*st,
   self.pos.y+8)
 end
 
 self:checkbullets()
end

function spawnbigenemy(ypos)
 local e=enemybig:new()
 e.pos.x=-12
 e.y=ypos
 enemies:addval(e)
end

--missile
missile = newclass(enemy)
function missile:new()
 local n=self:super():new()
 n.sprn=5
 n.agl=0.75
 n.radius=3
 n.value=2
 n.smoketimer=5
 return setmetatable(n,self)
end

function missile:die()
 enemies:removecurrent()
 local xps = explosion:new()
 xps.pos = self.pos
 self:givescore()
 enemies:addval(xps)
end

function missile:update()
 --update angle
 local astep=0.01
 local mts=ship-self.pos
 local atgt=atan2(mts.x,mts.y)
 local adif=atgt-self.agl
 if (adif>0.5) atgt-=1
 if (adif<-0.5) atgt+=1
 adif=atgt-self.agl
 if abs(adif) <= astep then
  self.agl = atgt
 else
  self.agl += sign(adif)*astep
 end
 if (self.agl>1) self.agl-=1
 if (self.agl<0) self.agl+=1
 
 --update position
 local ca = cos(self.agl)
 local sa = sin(self.agl)
 self.pos += vec:new(ca,sa)
 
 --update sprite
 getspriteturn(self,self.agl,5,6,7)
 
 --smoke particle
 self.smoketimer-=1
 if self.smoketimer<=0 then
  local p = {}
  p.duration = 12
  p.x = self.pos.x
  p.y = self.pos.y
  p.dx = -ca
  p.dy = -sa
  p.life = -3
  p.col = 13
  p.cols = {}
  p.size = 2
  p.sizes = {}
  p.sizes[4] = 1.5
  p.sizes[8] = 0.5
  particles:addval(p)
  self.smoketimer=16  
 end
 
 self:checkbullets(missile.die)
end

function spawnmissile(a,b)
 local m=missile:new()
 m.pos:set(a,b)
 enemies:addval(m)
end

--explosion
explosion = newclass(enemy)
function explosion:new()
 local e=self:super():new()
 e.radius=0
 sfx(4)
 return setmetatable(e,self)
end
function explosion:update()
 self.radius += 1
 if self.radius >= 15 then
  enemies:removecurrent()
 end
end
function explosion:draw()
 circfill(
  self.pos.x,self.pos.y,
  self.radius,6)
end

--caterpillar
caterpillar = newclass(enemy)
function caterpillar:new()
 local n=self:super():new()
 n.life = 20
 n.value = 12
 n.radius = 7
 n.agl = 0
 n.turn = 1
 n.trail={}
 for i=0,37 do
  n.trail[i]=vec:new(-16,-16)
 end
 --spawn bodies
 n.bodies={}
 for i=6,1,-1 do
  local b=cpbody:new(n,i*6)
  n.bodies[i] = b
  enemies:addval(b)
 end
 n.bodies[6].sprn=23
 return setmetatable(n,self)
end

function caterpillar:plandeath()
 self.deathcountdown=1
 for i=1,6 do
  self.bodies[i].deathcountdown = i*10
 end
end

function caterpillar:update()
 if self:delayeddeath() then
  return
 end
 --turn left and right periodically
 local s=sign(self.turn)
 self.turn -= s
 if self.turn==0 then
  self.turn =-s*(30+flr(rnd(15)))
 end
 
 self.agl+=s*0.01
 if (self.agl<0) self.agl+=1
 if (self.agl>1) self.agl-=1
 
 --move according to angle
 self.spd:set(cos(self.agl),sin(self.agl))
 self.pos += self.spd
 self:bouncex(true)
 self.agl=atan2(self.spd.x,self.spd.y)
 
 --update trail pos's for bodies
 for i=37,1,-1 do
  self.trail[i]=self.trail[i-1]
 end
 self.trail[0]=self.pos
 
 self:checkbullets(caterpillar.plandeath)
end

function draweye(pos,a)
 pos+=vec:new(cos(a),sin(a))*6
 local s={}
 getspriteturn(s,a,26,27,11)
 spr(s.sprn,
  pos.x-4,pos.y-4,
  1,1,
  s.sprfx,s.sprfy)
end

function caterpillar:draw()
 self:hitpal()
 
 local w=sin(frame/20)*3
 local w2=w/2
 
 sspr(64,0,16,16,
  self.pos.x-6-w2,self.pos.y-6+w2,
  12+w,12-w)
  
 draweye(self.pos,self.agl-0.1)
 draweye(self.pos,self.agl+0.1)
  
 pal()
end

cpbody = newclass(enemy)
function cpbody:new(cpparent,trailpos)
 local n=self:super():new()
 n.sprn=10
 n.value=2
 n.parent=cpparent
 n.tp=trailpos
 return setmetatable(n,self)
end

function cpbody:update()
 self.sprfx=(frame & 0x2)==0
 self.sprfy=(frame & 0x4)==0

 if self:delayeddeath() then
  return
 end
 self.pos=self.parent.trail[self.tp]
 
 --fake hits by the head
 local pp=self.parent.pos
 local pr=self.parent.radius
 self.parent.pos=self.pos
 self.parent.radius=self.radius
 self.parent:checkbullets(caterpillar.plandeath)
 self.parent.pos=pp
 self.parent.radius=pr
 self.hit=self.parent.hit
end

function spawncaterpillar(a,b,angle)
 local c=caterpillar:new()
 c.pos:set(a,b)
 c.agl=angle
 enemies:addval(c)
end

asteroid = newclass(enemy)

function asteroid:new(size)
 local n=self:super():new()
 n.sprw=size
 n.sprh=size
 n.radius=4*size
 if size==4 then
  n.sprn=12
  n.life=15
  n.value=24
 elseif size==2 then
  n.sprn=42
  n.life=8
  n.value=8
 elseif size==1 then
  n.sprn=38+flr(rnd(4))
  n.value=2
 end
 return setmetatable(n,self)
end
function asteroid:death()
 self:givescore()
 sfx(7)
 local x=self.pos.x
 local y=self.pos.y
 if self.sprw == 4 then
  spawnasteroid(x-4,y+6,-0.2,0.5,2)
  spawnasteroid(x+4,y+6,0.2,0.5,2)
  spawnasteroid(x,y-6,0,0.7,2)
 elseif self.sprw==2 then
  spawnasteroid(x-2,y-2,-0.5,0.8,1)
  spawnasteroid(x-2,y+2,-0.3,1,1)
  spawnasteroid(x+2,y-2,0.5,0.8,1)
  spawnasteroid(x+2,y+2,0.3,1,1)
 end
 enemies:removecurrent()
end
function asteroid:update()
 self.pos+=self.spd
 self:bouncex()
 self:checkbullets(asteroid.death,6)
 self:removeiftoolow()
end

function spawnasteroid(a,b,c,d,size)
 local n=asteroid:new(size)
 n.pos=vec:new(a,b)
 n.spd=vec:new(c,d)
 enemies:addval(n)
end

function enemyupdate()
 local e = enemies:start()
	while e do
	 e:update()
	 e = enemies:next()
 end
end

function enemydraw()
 local e = enemies:start()
 while e do
  e:draw()
  e = enemies:next()
 end
end

--init, update and draw
function gamescreen:init()
 bullets:clear()
 enemies:clear()
 particles:clear()
 score=0
 --ship
	ship = vec:new(60,100)
	shipspd = vec:new()
	laserleft = 0
 shipdeath=nil
 --spawn schedule
 spawntimer=0
 spawnpattern=0
 spawndifficulty=1
 --difficulty settings
 if difficulty==1 then
  spdmul = 0.5
  spawnmul = 2
		hitstr = 2
  scoremul = 0.5
 elseif difficulty==2 then
  spdmul = 0.75 
  spawnmul = 1.5
		hitstr = 1.5
  scoremul = 1
 else
  spdmul = 1
  spawnmul = 1
  hitstr = 1
  scoremul = 2
 end
end

function gamescreen:update()
 stfupdate()
	bulletupdate()
	enemyupdate()
	particleupdate()
	scoreparticleupdate()
	
	if shipdeath then
	 shipdeath += 1
	 if shipdeath > 128 then
 	 nextscreen = scorescreen
	 end
	else
	 --move
	 local spdtgt = vec:new()
	 if (btn(⬅️)) spdtgt.x -=3
	 if (btn(➡️)) spdtgt.x +=3
	 if (btn(⬆️)) spdtgt.y -=3
	 if (btn(⬇️)) spdtgt.y +=3
	 
	 local stt = spdtgt - shipspd
	 local sttl = #stt
	 if sttl > 0.3 then
	  shipspd += stt * 0.6 / sttl
	 elseif spdtgt:slen() == 0 then
	  shipspd:set(0,0)
	 end
	 ship += shipspd
	 
	 --restrict to screen
	 if (ship.x < 0  ) ship.x=0
	 if (ship.x > 128) ship.x=128
	 if (ship.y < 0  ) ship.y=0
	 if (ship.y > 128) ship.y=128
	 
	 --check death
	 local e = enemies:start()
	 while e do
	  if (e.pos-ship):slen() < addandsqr(3,e.radius) then
	   shipdeath = 0
	   sfx(2)
	  end
	  e = enemies:next()
	 end
	 
	 --shoot
	 if btnp(❎) then
	  sfx(0)
	  bulletcreate(
	   ship.x-laserleft%2,
	   ship.y-3)
	  laserleft += 1
	 end
	 
	 --spawn schedule
	 spawntimer-=1
	 if spawntimer<=0 or enemies:isempty() then
   local spawnfactor = 30*spawndifficulty*spawnmul
	  if spawnpattern<4 then
	   local s=1
	   if (spawnpattern&0x1==1) s=-1
	   spawnweakenemy(64-124*s,0,2*s,0.5)
	   spawnweakenemy(64-112*s,0,2*s,0.5)
	   spawnweakenemy(64-100*s,0,2*s,0.5)
	   spawnweakenemy(64-88*s,0,2*s,0.5)
	   spawnweakenemy(64-72*s,0,2*s,0.5)	  
    spawntimer = 4*spawnfactor
	  elseif spawnpattern==4 then
    spawnbigenemy(30)
    spawntimer = 14*spawnfactor
	  elseif spawnpattern==5 then
	   spawncaterpillar(-10,32,0)
	   spawncaterpillar(138,32,0.5)
    spawntimer = 14*spawnfactor
	  elseif spawnpattern==6 then
	   spawnasteroid(64,-16,0,0.2,4)
    spawnasteroid(24,-24,0,0.2,4)
    spawnasteroid(104,-32,0,0.2,4)
    spawntimer = 26*spawnfactor
	  end
	  spawnpattern+=1
	  if spawnpattern>6 then
	   spawnpattern=0
    if spawndifficulty>0.4 then
     spawndifficulty-=0.1
    end
	  end
	 end
 end
end

function gamescreen:draw()
 cls()
 stfdraw()
 particledraw()
 bulletdraw()
 enemydraw()
 scoreparticledraw()
 if shipdeath then
  circfill(ship.x,ship.y,shipdeath,7)
 else
  spr(1,ship.x-4,ship.y-4)
 end
 print(score,0,122,7)
 
 if debug then
  print(debug,2,2,7)
 end
end
-->8
--score screen
scorescreen = {}

--default scores
scores = {}
scores[0] =
 {name = "pog",val = 1500}
scores[1] =
 {name = "god",val = 1000}
scores[2] =
 {name = "lol",val = 800}
scores[3] =
 {name = "hey",val = 500}
scores[4] =
 {name = "gud",val = 400}
scores[5] =
 {name = "bof",val = 300}
scores[6] =
 {name = "nul",val = 100}
scores[7] =
 {name = "dog",val = 8}

function savescores()
 for i=0,7 do
  local name = scores[i].name
  local rawname =
   ord(name,1) >> 8 |
   ord(name,2)  |
   ord(name,3) << 8
   
  dset(i*2,rawname)
  dset(i*2+1,scores[i].val)
 end
end

function loadscores()
 --last index says stores
 --if the score was ever saved
 if dget(63) == 0 then
  --first time loading scores
  --save then set 63 to 1
  savescores()
  dset(63,1)
 else
  for i=0,7 do
   local rawname = dget(i*2)
   scores[i].name =
    chr(rawname << 8 & 0xff)..
    chr(rawname & 0xff)..
    chr(rawname >> 8 & 0xff)
   scores[i].val = dget(i*2+1)
  end
 end
end

function scorescreen:init()
 ssstart = frame
 scrolltext = 512
 highlight = -1
 newname = nil
 for i,star in pairs(stf3d) do
  star.z += 512
 end
 loadscores()
 
 local lowscore = 0x7fff
 for i,s in pairs(scores) do
  if s.val < lowscore then
   lowscore = s.val
  end
 end
 
 if score >= lowscore then
	 newname = {
	  [0]="a",
	  [1]="a",
	  [2]="a"}
	  
	 cursorpos = 0
 end
end

function scorescreen:update()
 tss = frame - ssstart
 if scrolltext > 0 then
  scrolltext -=4
 end
 if tss>96 then
  stf3dupdate()
  
  if newname then
   if cursorpos < 3 then
	   local l = ord(newname[cursorpos])
	
	   if btnp(⬆️) then
	    if l==57 then l = 97
	    elseif l==122 then l = 48
	    else l+=1 end
	   elseif btnp(⬇️) then
	    if l==97 then l = 57
	    elseif l==48 then l = 122
	    else l-=1 end
	   end
	   
	   newname[cursorpos] = chr(l)
   end
   
   if btnp(❎) then
    if cursorpos < 3 then
     cursorpos += 1
    else
     --name confirmed
     local i=8
     if score >= scores[0].val then
      i=0
     else
	     while scores[i-1].val <= score do
	      i-=1
	     end
     end
     highlight = i
     local j=7
     while j>i do
      scores[j].name = scores[j-1].name
      scores[j].val = scores[j-1].val
      j-=1
     end
     scores[i].name = newname[0]..newname[1]..newname[2]
     scores[i].val = score
     newname = nil
     scrolltext = 128
     savescores()
    end
   elseif btnp(🅾️) then
    if cursorpos > 0 then
     cursorpos -= 1
    end
   end
  elseif scrolltext<=0 and btnp(❎) then
   nextscreen = scrollscreen
  end
 end
end

--fill pattern bits order
fpbo = {
32768,
32,
128,
8192,
1,
1024,
4,
256,
2048,
2,
64,
16,
8,
512,
16384,
4096,
}
curfp=0

function filltrstn(t,c1,c2)
 local mt = tss-t
 if mt>=0 and mt<32 then
  if mt==0 then
   cls(c1)
   curfp = 0
  else
   curfp |= fpbo[ceil(mt/2)]
   fillp(curfp)
   rectfill(0,0,128,128,c1|c2<<4)
  end
 end
end

function scorescreen:draw()
 if tss<96 then
  filltrstn(0,7,5)
  filltrstn(32,5,1)
  filltrstn(64,1,0)
 else
  cls()
  fillp(0)
  stf3ddraw()
  
  if newname then
   print("nouveau score!",32,38+scrolltext,7)
   print("vous avez fait "..score,28,48+scrolltext,7)
   print("entrez votre nom",28,70+scrolltext,7)
   
   for i=0,2 do
    print(newname[i],52+i*4,90+scrolltext,flashcol(7,i==cursorpos))
   end
   
   if cursorpos < 3 then
    print("^",52+cursorpos*4,100+scrolltext,7)
   else
    print("ok",70,90+scrolltext,flashcol())
   end
  else
	  for i=0,7 do
	   print(
	    scores[i].name.."......."
	    ..scores[i].val,
	    38,15+i*10+scrolltext,flashcol(7,i==highlight))
	  end
	  
	  if highlight==-1 then
	   print("votre score : "..score,2,120+scrolltext,7)
	  end
  end
  
 end
end

__gfx__
00000000000000000000000000000cccccc00000000000000000000000000000000009889990000000899e000000000000000000000000000000000000000000
00000000000cc000000000000000c000000c0000000000000000080000088000000999ee999890000ee99e900001100000000000000000000000000000000000
00700700002cc2005d6666d5000c04400440c0000e20000000006d80000dd000009999e9999e890099e889990018810000000000000011111000000000000000
00077000012dd2100ddc7dd0000c05444450c00000666d800026dd00000d600009889998899ee990999ee9880178871000000000000111111110000000000000
000770001150051100dccd0000dc51844815cd0000dddd800e6dd000000d600009ee999ee99999808899e9ee0177771000000000001111111111110000000000
0070070010000001008008000ddc11444411cdd00e200000000d2000002d6200999e9999e99999eeee9899e90017710000000000011111111111111110000000
000000000000000000000000ddddc114411cd6dd00000000000e000000e00e00999999999999999e0e9e89900001100000000001111111111111111440000000
000000000000000000000000dddddccccccdd66d0000000000000000000000008899999999988999009ee9000000000000000011111111111111144444000000
000000000000000000000000ddddddddddddd66d000000000000000000000000ee998999899ee999000000000000000000004141414141411114444444000000
000000000000000000000000d6dddd7777ddd66d00000000000000000060dd009e99e899e899e999000110000001100000041414141414141444444444000000
000000000000000000000000d6677d0770d7766d00000000000000000d6656609999ee99ee999999001771000017880000044444444444444444449494000000
000000000000000000000000022677d77d77622000000000000000000d5116000999999999998990017788100177881000044444444444444444494949000000
000000000000000000000000211e67766776211e0000000000000000006115d0099889998999e890017788100177771000044444444444444494949999900000
000000000000000000000000211e77666677211e0000000000000000066566d0009ee999e899ee00001771000017710000009494949494444949499999111100
0000000000000000000000000ee77dddddd77ee0000000000000000000dd06000009e999ee999000000110000001100000000949494949449499999111111110
00000000000000000000000000000000000000000000000000000000000000000000099999900000000000000000000000000999999999949999111111111110
00000000000000000000000000000000000000000000000000110000000110000011100000000000000001100000000000001449999999944411111111111110
00000000000000000000000000000000000000000000000001111110011111000141111001111100000111110000000000001114444444444444141411111100
00000000000000000000000000000000000000000000000014141411414141414414141411141414001111111000000000011111111111111444414141411100
00000000000000000000000000000000000000000000000041414141444444144444414111414444011111114444000000011111111111111444444414141100
00000000000000000000000000000000000000000000000004444444049444404944444414144494141414144444110000141411111111111444444444444000
00000000000000000000000000000000000000000000000000494949094949409494944000444949444444444441111000414141414141114444949444444000
00000000000000000000000000000000000000000000000000049490009494000949490000449490444444444111111000444414141414141111999949494000
00000000000000000000000000000000000000000000000000009900000990000009900000099900994444441111111000044444444441411111119999999000
00000000000000000000000000000000000000000000000000000000000000000000000000000000094949444414141100004444444444111111111199990000
00000000000000000000000000000000000000000000000000000000000000000000000000000000009999944444444400000949494994414111111100000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000001111144449494400000000999944441414111000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000001111114499999000000000099444444441410000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000011414144440000000000000004444444444400000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000014444444990000000000000000444449494900000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000004444949900000000000000000044499999000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000004449999000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000aa0000000000000000000000000000000000000000000000000000000000008aaaa2000000000000000000000000000000000
0000000000000000000000008aaaaaa000000000000000000000000000000000000000000000000000000008aaa08aa200000000000000000000000000000000
00000000000000000000000aaa20aaa20000000000000000000000000000000000000820000000000000008aaa00aaa200000000000000000000000000000000
00008aa2000000000000008aa208aaaa000000000000000000000000000000000000aaaa00000000000000aaa208aaaa00000000000000000000000000000000
0000aaaa00000000000000aaa000aaa2000000000000000000000000000000000008aaaa20000000000008aaa000aaa200000000000000000000000000000000
0008aaaa20000000000008aa20008aa0000000000000000000000000000000000000aaaa0000000000000aaa2000000000000000000000000000000000000000
0000aaaa0000000000000aaa200000000000000000000000000000000000000000008aa20000000000008aaa0000000000000000000000000000000000000000
000008200000000000008aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008a20008a00000000000000000aa0000000000000000000000000000000000008aaa008aa208aa000aaaaaa00aaaa000000000000000000000000000000000
00aaaa20aaa20aaa20aaaaaaa0aa28a2000008aaaaaaaaaaaaaaaaaaaaaaaaa208aaaa28aaa28aaa28aaaaaaa8aa08aa000aaaaaaaaaaaaaaaaaaaaaaaaaaaa2
0aaaaa2aaaa2aaaa28aaaaaaaaaa08aa00aaaaaaaaaaaaaaaaaaaaaaaaaaaaa28aaaaa8aaaaaaaaa2aaaaaaaaaaa0aaa00aaaaaaafaaaaaabaaaaaaaaaaaaaa2
00aaaa00aaaa2aaa0aaaaaaa8aa20aaa08aaaaaaeabaaaabfabaaeabaaaaaaa200aaa200aaaa0aaa000aaa20aaa20aaa08aaaaaaeabebebabeeebaeeaaaaaaa2
00aaa208aaa28aaa008aaa20aaa20aaa0aaaaaaaeabbababbafeeeefaaaaaaa000aaa00aaaa28aaa008aaa00aaa08aaa0aaaaaaaeabbababbeeeeeeaaaaaaaa0
08aaa28aaaa0aaaa008aaa00aaa08aa20aaaaaaaafaebebbeafeeeafaaaaaa2008aaaaaaaaa0aaaaa0aaaa008aa08aa20aaaaaaaaaaaaaaaaaaaaaaaaaaaaa20
08aaaa2aaa20aaaaa0aaaa008aa0aaa00aaaaaaaaaaaaaaaaaaaaaaaaaaaa20008aaaa0aaa20aaaa20aaa2000aa0aa200aaaaaaaaaaaaaaaaaaaaaaaaaa00000
00aaa28aaa008aaa00aaa20008aaaa0000000000000000000000000000000000008a208aaa000aa008aaa20000aaa00000000000000000000000000000000000
000000000000000008aaa0000000000000000000000000000000000000000000000000000000000008aaa0008a20008aa008aa2008a0000000008a200008aaa0
000000000000000008aaa00aaaa200aaa20aaa208aa208aa000aaaa2008a2aa200000000000000000aaaa08aa0aa08aaa20aaa20aaa20aaa208aa0aa00aa08aa
00000000000000000aaa20aa20aa0aaaa20aaa28aaa28aaa20aa20aa08aa00aa00000000000000000aaa28aa208a8aaaa28aaa0aaaa2aaaa28aa208a08aa2082
00000000000000008aaa2aaa20aa00aaa28aaa8aaaaaaaaa2aaa20aa08aaa28000000000000000008aaa2aaa28a208aaa08aaa00aaaa2aaa0aaa28a208aaaa00
00000000000000008aaa0aaaaaa008aaa0aaa200aaaa0aaa0aaaaaa008aaaa200000000000000000aaaa8aaa200008aaa8aaa208aaa28aaa0aaa20000aaaaaa0
0000000000000000aaaa8aaaa00008aa28aaaa2aaaa28aaa0aaaa000aa28aaa20000000000000000aaa28aaaaaaa0aaa2a8aaaaaaaa0aaaa0aaaaaaaaaa0aaa2
0000000000000008aaa20aaaaaaa0aaaa28aaaaaaaa0aaaaaaaaaaaaaaa08aa20000000000000008aaa00aaaaaa20aaaa0aaaa0aaa20aaaaaaaaaaa28aa20aa2
0000000000000008aaa008aaaaa008aa20aaa20aaa20aaaa28aaaaa00aa20aa2000000000000000aaaa000aaaa2008aa008aa08aaa008aaa00aaaa2000aa8aa0
000000000aa2000aaa20000aa2000000000a008aaa000aa0000aa200000aaa00000000008aaa000aaa2000000000000000000000000000000000000000000000
00000000aaaa208aaa000000000000000000000000000000000000000000000000000000aaaa208aaa008a88828002028a8200808a02000808080802a020a280
00000000aaaa20aaa2008088888088888088008080880002222222222220202200000000aaaa20aaa00080028880888880880080808000022222020222202020
00000000aaaa08aaa000820282808882828200808202000a02280802a020a080000000008aa20aaa200080888080888880880080808800020222222222202022
000000000a208aaa00008a88808a02888a88008a8a02000208080802a0a2a2800000000008aaaaa0000000000000000000000000000000000000000000000000
00000000008aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007777771117777777771117771110000007777777771111777777777111777777777111000777777111000000000000000000000000000
00000000000000000077777711177777777771117771110000007777777771111777777777111777777777111000777777711100000000000000000000000000
00000000000000000077777711177777777711117771110000007777777771111777777777111777777777111100077777711100000000000000000000000000
00000000000000777111000000077711177711177711110000007771110000000777111777111777111000000077711100000000000000000000000000000000
00000000000000777111000000777111177711177711100000007771110000000777111777111777111100000077711100000000000000000000000000000000
00000000000007771110000000777777777711177711100000007777771110000777777111000777777711100077777777771110000000000000000000000000
00000000000007771110000000777777777111177711100000007777771110000777777111000077777711100007777777771111000000000000000000000000
00000000000077711110000007777777777111777711100000077777771110000777777111000077777711100007777777777111000000000000000000000000
00000000000077711177711117771117777111777111100000077771110000000777111777111177711100000000000000777111000000000000000000000000
00000000000777111177711177771117771111777111000000077771110000000777111777711177711110000000000000777111100000000000000000000000
00000000000777777777711177711117771111777777777711177777777771111777111777711177777777771111777777111100000000000000000000000000
00000000007777777777111177711177771117777777777711177777777771111777111777711177777777771111777777711100000000000000000000000000
00000000007777777777111777711177771117777777777111177777777771111777111777711177777777777111777777711100000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777711117777777111000077771117777111777777777771111777777711100007777777777111177777777777111000077777771111000000
00000007777777777711177777777111000077711117777111777777777771111777777711100007777777777711177777777777111100077777771111000000
00000007777777777111177777771111000077711117771111777777777771111777777711100007777777777711117777777777111100007777777111100000
00000077777777777111177777771111000777711117771111777777777771111777777711100007777777777711117777777777711100007777777111100000
00000000077771111000777711117771111777711177771111777111177771111777111177771117777111100000007777111777711117771111000000000000
00000000077711110000777711177771111777711177771111777111177771111777111177771117777111100000007777111177711117777111100000000000
00000000777711110000777111177771111777111177771111777111177771111777111177771111777111100000000777111177771111777111100000000000
00000000777711100007777111177711117777111177771117777777777771111777111177771111777777711110000777777711110000777777777771111000
00000007777111100007777111777711117777111177711117777777777771111777111177771111777777711110000777777771110000777777777777111100
00000007777111100077771111777711117777111777711117777777777771111777111177771111777777771110000777777771111000077777777777111100
00000077771111000077771111777711117771111777711117777777777771111777111177771111777777771111000077777771111000077777777777711110
00000077771111000077771117777111177777777777711117777111177771111777111177771111777711110000000077771111777111100000000777711110
00000777711110000777711117777111177777777777711117777111177771111777111177771111777711110000000077771111777711110000000077771111
00000777711110000777711117777111177777777777711117777111177771111777111177771111777711110000000077771111777711110000000077771111
00007777111100007777111177771111777777777777111177771111777711117777111177771111777711110000000077771111777711110000000077771111
00007777111100007777111177771111777777777777111177771111777711111777711117777111177771111000000007777111177771111000000007777111
77777777777711117777111177771111000077771111000077771111777711111777777777777111177777777777711117777111177771111777777771111000
77777777777111177771111177771111000077771111000077771111777711111777777777777111177777777777711117777111177777111177777777111100
77777777777111177771111777711111000077771111000077771111777711111777777777777111177777777777711111777711117777111177777777111100
77777777771111177771111777711110000777771111000077771111777711111777777777777111177777777777771111777711117777111177777777711110
77777777771111777711111777711110000777711111000077771111777711111777777777777111177777777777771111777711117777711117777777711110
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
000100003b1503a150391503615033150301502c15029150241501f1501a15013100121000f1500e100011000a100061500710005100021000300000000011500e0000b000070000200002100222000000000000
000200001961035220246402f2602e67025270346601d05033640180302b63013030266001c64016600136200f6000d6200c600086200b6000662009600066200760006620046000460003600016000060000600
00120000396303c6403c6703c6503c64039640386303763033630366303763035630336302e63034630316302f6202d6202d6202e6202d6102b6102861025610226101e6101c6101a61018610156101461013610
00020000000001b0501b0001e0501b000200502c13020050311301b05029130181500f13009120041200111000110000000000000000000000000000000000000000000000000000000000000000000000000000
000300000c630106401465018650206502a650316503465035650336502e650276502065019650106500b65006650036500065000640006300062000610006000060000600006000000000000000000000000000
000100000b1500b1000b150000000b150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000b350116000b350126000b3500f600083500c600053500860001350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000166500f31019670123101b670123101b6700f310186700b31012660053500e650013500a6400031007630003100562004600036200260001620016000061000000000000000000000000000000000000
