pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- zelda-like in progress
-- by jackamikaz

--[[
i keep forgeting this
0 = left
1 = right
2 = up
3 = down
--]]

function brpnt(str)
 str = str or "breakpoint!"
 for i=0,90 do
  cls()
  print(str,0,0,7)
  print(3-flr(i/30),60,60,rnd(15))
  flip()
 end
end

--@begin
--debug = true
debugstr = ""
debugpos = {x=0,y=0}
maxnumber = 32767

spikegrid = {}
campos = {x=0,y=128}
camtgt = {x=0,y=128}

--kinds
--also order of drawing/update
spikes = 1
switches = 2
blocks = 3 --pots are breakable blocks
collectibles = 4
chests = 5
players = 6
blobs = 7
skeletons = 8
keyblocks = 9
bombs = 10
levers = 11
swords = 12
boomerangs = 13
blowers = 14
kindmax = 14


spawnsprite = {
43,
42,
{39,11},
{25,51,54,29,  37,59,61,28,45,53,44,60},
{9,10},
1,
50,
7,
55,
-1,
56,
38,
-1,
27
}

itemsprite = spawnsprite[4]

function invlist(l)
 local inv = {}
	for i=1,#l do
	 if type(l[i]) == "table" then
	  for e in all(l[i]) do
	   inv[e] = i
	  end
	 else
	  inv[l[i]] = i
	 end
	end
	return inv
end

invitemsprite = invlist(itemsprite)
invspawnsprite = invlist(spawnsprite)
keys = invitemsprite[54]
--bombs = invitemsprite[53]
money = invitemsprite[25]
--[[for i=1,kindmax do
 if type(spawnsprite[i]) == "table" then
  for e in all(spawnsprite[i]) do
   invspawnsprite[e] = i
  end
 else
  invspawnsprite[spawnsprite[i] ] = i
 end
end--]]

actors = {}
mapactors = {}
curactors = {}

particles = {}

function xyindex(x,y)
 return bor(x,shr(y,16))
end

function rndpal()
 for i=1,15 do
   pal(i,rnd(15)+1)
 end
end

fadepal={0,0,1,1,2,1,13,6,4,4,9,3,13,1,13,14}

--@vector
function vinit(x,y)
 return {x=x,y=y}
end

function vadd(v1,v2)
 return vinit(
  v1.x + v2.x,
  v1.y + v2.y)
end

function vsub(v1,v2)
 return vinit(
  v1.x - v2.x,
  v1.y - v2.y)
end

function vmul(v,f)
 return vinit(
  v.x * f,
  v.y * f)
end

function vdot(l, r)
 return l.x*r.x + l.y*r.y
end

function safesqr(v)
 if abs(v)>181 then
  return maxnumber
 end
 return v*v
end

function vsqrlen(v)
 local res = safesqr(v.x) + safesqr(v.y)
 
 if res < 0 then
  return maxnumber
 end
 return res
end

function sqrdist(x1,y1,x2,y2)
 return vsqrlen(vsub(vinit(x1,y1),vinit(x2,y2)))
end

function vlen(v)
 local sqrlen = vsqrlen(v)
 if sqrlen == maxnumber then
  return maxnumber
 end
 return sqrt(sqrlen)
end

function norm(vec)
 local l = vlen(vec)
 vec.x /= l
 vec.y /= l
end

-- @collision
function actorscollide(a1,a2)
 return vsqrlen(vsub(a1,a2)) < safesqr(a1.radius+a2.radius)
end

function actorrectcollide(actor,rl,rr,ru,rd)
 local pc = vinit(mid(actor.x,rl,rr),mid(actor.y,ru,rd))
 
 if vsqrlen(vsub(actor,pc)) < safesqr(actor.radius) then
  return pc
 end
end

-- collision testing
-- actor's radius must not > 16
-- o is out collision point
function collide(actor,o)
 local colfound
 local px = flr(actor.x/8)
 local py = flr(actor.y/8)
 
 --avoid redundancy
 --handle collision point
 local lsqrcpd = safesqr(actor.radius)
 local hcp = function(ro)
  if ro then
   local sqrl = vsqrlen(vsub(actor,ro))
   if sqrl < lsqrcpd then
    lsqrcpd = sqrl
    o.x = ro.x
    o.y = ro.y
    colfound = true
   end
  end
 end
 
 for j=py-1,py+1 do
  for i=px-1,px+1 do
   if fget(mget(i,j),0) then
    hcp(
     actorrectcollide(actor,
     i*8,i*8+8,j*8,j*8+8)
    )
   end
  end 
 end
 
 for b in allof(blocks) do
  if b!=actor and b.on then
   hcp(
    actorrectcollide(actor,
    b.x-4,b.x+4,b.y-4,b.y+4)
   )
  end
 end
 
 return colfound
end

--@actors
function spawn(x,y,kind)
 -- shared default values
 local a = {}
 a.kind = kind
 a.x = x
 a.y = y
 a.ox = 4
 a.oy = 4
 a.sp = mget(x/8,y/8)
 a.w = 1
 a.h = 1
 a.fx = false
 a.fy = false
 a.life = 1
 a.radius = 4
 a.hit = 0
 a.stun = 0
 a.vel = {}
 a.vel.x = 0
 a.vel.y = 0
 a.shown = true
 a.on  =true
 a.upt = nil
 a.draw = draw_actor
 a.activate = activate_actor
 a.takehit = nil
 --blob
 if kind == blobs then
  locate_targets(a)
  a.upt = update_blob
  a.takehit = hitmonster
  a.oy = 6
  a.life = 2
  a.radius = 2
 -- skeleton
 elseif kind == skeletons then
  locate_targets(a)
  a.upt = update_skeleton
  a.takehit = hitmonster
  a.oy = 5
  a.life = 4
  a.radius = 2
 --player
 elseif kind == players then
  a.upt = update_player
  a.takehit = hitplayer
  a.spb = 1
  a.f = 0
  a.ox = 4
  a.oy = 5
  a.radius = 1.8
  a.life = 8
  a.lifemax = 8
  a.hor = 0
  a.last_dr = 0
  a.atk = 0
  a.sword = spawn(0,0,swords)
  a.sword.player = a
  local b = spawn(-10,-10,boomerangs)
  b.player = a
  b.activate(b,false)
  a.boomerang = b
  a.ctrl = 0
  if getplayer(1) then
   a.ctrl = 1
   a.altpal = {}
   a.altpal[3] = 8
   a.altpal[11] = 9
  end
  a.lastx = false
  a.lasto = false
  a.items = {}
  for i=1,#itemsprite do
   add(a.items,0)
  end
  a.xitem = 5
  a.oitem = bombs
 --sword
 elseif kind == swords then
  a.draw = draw_sword
  a.shown = false
  a.dr = 3
  a.ox = 4
  a.oy = 5
  a.crr = 40 --cr stands for
  a.crl = 10 --collision rect
  a.cru = 20
  a.crd = 50
 --key
 elseif kind == collectibles then
  a.upt = update_collectible
 --keyblocks
 elseif kind == keyblocks then
  a.draw = nil
  a.push = 0
  a.upt = update_keyblock
 --bombs
 elseif kind == bombs then
  a.sp = 53
  a.upt = update_bomb
  a.takehit = hitbomb
  a.countdown = 120
  a.radius = 3
 --chests
 elseif kind == chests then
  a.upt = update_chest
  a.activate = activate_chest
  a.sp = 9
  mset(x/8,y/8,10)
 --levers
 elseif kind == levers then
  locate_targets(a)
  a.upt = update_lever
 --blocks
 elseif kind == blocks then
  a.upt = update_block
  a.takehit = hitblock
 --switches
 elseif kind == switches then
  locate_targets(a)
  a.upt = update_switch
 --blowers
 elseif kind == blowers then
  a.dr = redstonedir(gridpos(a))
  if a.dr then
   collapsetile(vadd(gridpos(a),a.dr))
   a.x -= a.dr.x*4.5
   a.y -= a.dr.y*4.5
  end
  a.draw = nil
  a.upt = update_blower
 elseif kind == spikes then
  spikegrid[xyindex(x/8,y/8)] = a.sp
 elseif kind == boomerangs then
  a.upt = update_boomerang
  a.sp = 59
  a.ret = 0
 end
 
 add(actors, a)
 
 local midx = xyindex(flr(x/128),flr(y/128))
 if kind == players
 or kind == swords
 or kind == boomerangs then
  midx = -1
 end
 
 a.midx = midx

 if not mapactors[midx] then
  local ma = {}
  for i=1,kindmax do
   ma[i]={}
  end
  mapactors[midx] = ma
 end
 
 add(mapactors[midx][kind],a)
 
 return a
end

function checkspikes(a)
 local px = flr(a.x/8)
 local py = flr(a.y/8)
 for j=py-1,py+1 do
  for i=px-1,px+1 do
   if spikegrid[xyindex(i,j)]
   and actorrectcollide(a,
     i*8,i*8+8,j*8,j*8+8) then
    a.takehit(a,a,1)
   end
  end 
 end
end

function activate_actor(a,onoff)
 a.on = onoff
 a.shown = onoff
end

function despawn(a)
 del(actors,a)
 del(mapactors[a.midx][a.kind],a)
end

function allof(kind)
 local a = curactors
 if kind == players
 or kind == swords
 or kind == boomerangs then
  a = mapactors[-1]
 end
 
 if not a then
  a = {}
 end
 return all(a[kind])
end

function getplayer(id)
 return mapactors[-1][players][id]
end

function allactors()
 return all(actors)
 --[[local l = {}
 for kind = 1,kindmax do
  for a in allof(kind) do
   add(l,a)
  end
 end
 return all(l)--]]
end

--@move
function move(actor,d)
 actor.x += d.x
 actor.y += d.y
 
 local o = vinit(0,0)
 local tries = 4
 local ret = true
 while tries > 0 do
  if collide(actor, o) then
   ret = false
   local v = vsub(actor,o)
   if vsqrlen(v) == 0 then 
    v = vmul(d,-1)
   end
   if vsqrlen(v) > 0 then
    norm(v)
    actor.x = o.x + v.x*actor.radius*1.01
    actor.y = o.y + v.y*actor.radius*1.01
    tries -= 1;
    add(debugpos,vsub(actor,vmul(v,actor.radius)))
   end
  else
   tries = 0
  end
 end
 return ret
end

function call_upt(actor)
 if actor.upt and actor.on then
  actor.upt(actor)
 end
end

function call_draw(actor)
 if actor.draw and actor.shown then
  actor.draw(actor)
 end
end

function draw_actor(a)
 if a.hit > 0 then
  rndpal()
 elseif a.altpal then
  for col,alt in pairs(a.altpal) do
   pal(col,alt)  
  end
 end
 spr(a.sp,
  a.x-a.ox,a.y-a.oy,
  a.w,a.h,
  a.fx,a.fy)
 pal()
 if debug then
  circ(a.x, a.y, a.radius, 0)
 end
end

--@particles
function spawnparticle(pos,vel,r,life,col)
 local part = {}
 part.pos = pos
 part.vel = vel
 part.r = r
 part.life = life
 part.col = col
 add(particles,part)
end

function updateparticle(part)
 part.life -= 1
 if part.life>0 then
  part.pos = vadd(part.pos,part.vel)
 else
  del(particles,part)
 end
end

function drawparticle(part)
 circfill(part.pos.x,part.pos.y,part.r,part.col)
end

function particlesplosion(pos)
 for i=0,20 do
  local vx, vy = rnd(6)-3, rnd(6)-3
  if (vx > 0) then vx += 1 else vx -= 1 end
  if (vy > 0) then vy += 1 else vy -= 1 end
  spawnparticle(pos,
  vinit(vx,vy),
  rnd(2)+1,rnd(4)+2,rnd(3)+8)
 end
end

--@behaviors
function getdir(v)
 if abs(v.x) > abs(v.y) then
  if v.x>0then
   return 1
  else
   return 0
  end
 else
  if v.y>0then
   return 3
  else
   return 2
  end
 end
end

function player_sword(p)
	p.atk = 5
 sfx(0)
 
 local sword = p.sword
 
 sword.shown = true
 sword.dr = p.last_dr
 sword.x = p.x
 sword.y = p.y
 
 local w,h = 1,1
 
 if sword.dr == 0 then
  sword.x -= 8 w = 3
 elseif sword.dr == 1 then
  sword.x += 8 w = 3
 elseif sword.dr == 2 then
  sword.y -= 8 h = 3
 elseif sword.dr == 3 then
  sword.y += 8 h = 3
 end

 p.sword.crl = p.sword.x -w
 p.sword.cru = p.sword.y -h
 p.sword.crr = p.sword.x +w
 p.sword.crd = p.sword.y +h
end

function player_bomb(p)
 p.items[bombs] -= 1
 spawn(p.x,p.y,bombs)
end

function player_boomerang(p)
 local b = p.boomerang
 if not b.on then
	 p.atk = 5
	 b.x = p.x
	 b.y = p.y
	 
	 local dr = p.last_dr
	 
	 if dr == 0 then
	  b.vel = vinit(-1,0)
	 elseif dr == 1 then
	  b.vel = vinit(1,0)
	 elseif dr == 2 then
	  b.vel = vinit(0,-1)
	 elseif dr == 3 then
	  b.vel = vinit(0,1)
	 end
	 
	 b.ret = 15
	 b.activate(b,true)
 end
end

function empty()
end

player_funcs = {}

for i=5,12 do
 player_funcs[i] = empty
end

player_funcs[invitemsprite[37]]
= player_sword

player_funcs[invitemsprite[59]]
= player_boomerang

player_funcs[invitemsprite[53]]
= player_bomb

function update_player(p)
 -- player hit
 if p.hit > 0 then
  p.hit -= 1
  local scl = 2 * p.hit / 10
  local vel = vmul(p.vel,scl)
  move(p,vel)
 else
  checkspikes(p)
 end
 
 -- Ž action
 local itm = p.items[p.oitem]
 if itm and itm > 0
 and btn(4,p.ctrl)
 and not p.lasto then
  player_funcs[p.oitem](p)
 end
 
 -- — action
 itm = p.items[p.xitem]
 if itm and itm > 0
 and btn(5,p.ctrl)
 and not p.lastx then
  player_funcs[p.xitem](p)
 end
 
 if p.atk == 0 then
  p.sword.shown = false
  -- player movement
  local d = vinit(0,0)
  if (btn(0,p.ctrl)) d.x -= 1
  if (btn(1,p.ctrl)) d.x += 1
  if (btn(2,p.ctrl)) d.y -= 1
  if (btn(3,p.ctrl)) d.y += 1
  
  if d.x!=0 or d.y!=0 then
   move(p,d)
  
   -- cycle frames
   p.f += 0.3
   if p.f >= 4 then
    p.f -= 4
   end
   
   p.hor = 0
   
   p.last_dr = getdir(d)
   p.spb = ({33,33,17,1})[p.last_dr+1]
   
   if p.spb == 33 then
    p.hor = d.x
   end
  end
 else
  p.atk -= 1
 end
 
 -- player animation
 p.fx = false
 local frame = p.f
 if p.hor != 0 then
  if frame >=3 then
   frame = 2
  elseif frame >=2 then
   frame = 0
  end
  if p.hor < 0 then
   p.fx = true
  end
  if p.atk > 0 then
   frame = 3
  end
 else
  if frame >= 2 then
   frame -= 2
   p.fx = true
  end
  if p.atk > 0 then
   frame = 2
  end
 end
 p.sp = p.spb + frame

 p.lasto = btn(4,p.ctrl) 
 p.lastx = btn(5,p.ctrl)
 
 --check map transition
 if p.x < campos.x then
  camtgt.x -= 128
  updatefct = changescreen
 elseif p.x > campos.x + 128 then
  camtgt.x += 128
  updatefct = changescreen
 elseif p.y < campos.y then
  camtgt.y -= 128
  updatefct = changescreen
 elseif p.y > campos.y + 128 then
  camtgt.y += 128
  updatefct = changescreen
 end
end

function update_blob(b)
 update_monster(b,32,1,0.2)
 if b.hit <= 0 and b.stun <=0 then
  b.sp += 0.15
  if (b.sp >= 51) b.sp -= 2
 end
end

function update_skeleton(s)
 update_monster(s,64,2,0.8)
 if s.hit <= 0 and s.stun <=0 then
  local lsp = flr(s.sp)
  s.sp += 0.3
  if (s.sp >= 9) s.sp -= 2
  s.fx = ((s.sp*2)%2) > 1
 end
end

function hitplayer(player,m,dmg)
 if player.hit <= 0 then
  player.hit = 10
  player.vel = vsub(player,m)
  if vsqrlen(player.vel) > 0 then
   norm(player.vel)
  else
   player.vel.x = 0
   player.vel.y = 0
  end
  player.life -= dmg
  sfx(3)
 end
end

function hitmonster(m,from,dmg)
 m.life -= dmg
 if m.life <= 0 then
  sfx(1)
 else
  sfx(2)
 end
 local d = vsub(m,from)
 m.x += d.x
 m.y += d.y
 m.hit = 11
end

function checkswordhit(a)
 for sword in allof(swords) do
  if sword.shown and actorrectcollide(a,sword.crl,sword.crr,sword.cru,sword.crd) then
   return sword
  end
 end
end

function checkboomeranghit(a)
 for bmrg in allof(boomerangs) do
  if bmrg.on and actorscollide(a,bmrg) then
   return bmrg
  end
 end
end

function activatetargets(targets, onoff)
 if targets then
  for target in all(targets) do
   if target.life > 0 then
    target.activate(target,onoff)
   end
  end
 end
end

function update_monster(m,
 reactradius,dmg,speed)
 local moved=false

 grab_targets(m)

 if m.hit > 0 then
  m.hit -= 1
 elseif m.life <= 0 then
  --die!
  particlesplosion(m)
  activatetargets(m.targets,true)
  despawn(m)
 else
  -- move toward first player
  -- todo nearest
  if m.stun <= 0 then
	  for player in allof(players) do
	   local vec = vsub(player,m)
	   if vsqrlen(vec) < reactradius*reactradius then
	    norm(vec)
	    vec = vmul(vec, speed)
	    move(m,vec)
	    moved = true
	    break
	   end
	  end
	  
	  for player in allof(players) do
	   if actorscollide(player,m) then
	    hitplayer(player,m,dmg)
	   end
	  end
  else
   m.stun -= 1
  end
  
  -- check if hit by sword
  local s = checkswordhit(m)
  if s then
   hitmonster(m,s.player,1)
  end
  
  -- or by boomerang
  local bmrg = checkboomeranghit(m)
  if bmrg then
   m.stun = 45
   bmrg.ret = 0
  end
  
  checkspikes(m)
 end
 return moved
end

function gridpos(xy)
 return vinit(flr(xy.x/8),flr(xy.y/8))
end

function update_collectible(k)
 if k.holder == nil then
  for a in allactors() do
   if a.kind != collectibles then
    local gdif = vsub(gridpos(k),gridpos(a))
    if abs(gdif.x) == 1 and gdif.y == 0
    or abs(gdif.y) == 1 and gdif.x == 0then
	    k.holder = a
	    k.shown = false
	    a.holds = k
	    break
	   end
   end
  end
  if k.shown then
   k.holder = k
  end
 else
  if k.holder != k then
   if k.holder.life <= 0 and k.holder.hit <= 0 then
    k.shown = true
    k.x = k.holder.x
    k.y = k.holder.y
    k.holder = k
   end
  else
   for p in allof(players) do
    if actorscollide(p,k) then
     if k.sp == 51 then
      --reward heart
      p.life = min(p.life+1,p.lifemax)
      sfx(6)
     else
      --reward the item
      p.items[invitemsprite[k.sp]] += 1
      sfx(4)
     end
     despawn(k)
    end  
   end
  end
 end
end

function hugblock(p,b)
 return actorrectcollide(
  p,b.x-4.1,b.x+4.1,b.y-4.1,b.y+4.1)
end

function update_keyblock(k)
 for p in allof(players) do
  if p.items[keys] > 0 and hugblock(p,k) then
   local b = getdir(vsub(k,p))
   if btn(b,p.ctrl) then
    k.push += 1
    if k.push >= 15 then
     collapsetile(gridpos(k))
     k.life = 0
     despawn(k)
     sfx(5)
     p.items[keys] -= 1
    end
   else
    k.push = 0
   end
  else
   k.push = 0
  end
 end
end

function draw_sword(s)
 s.sp = 37
 s.fx = s.player.fx
 s.fy = false
 if(s.dr == 2) s.fx = (not s.fx)
 if s.dr == 1 then
  s.sp = 38
  s.fx = false
 end
 if s.dr == 0 then
  s.sp = 38
  s.fx = true
 end
 if(s.dr == 3) s.fy = true
 
 draw_actor(s)
end

function tryexplodething(b,kind)
 for m in allof(kind) do
  if actorscollide(b,m) then
   m.takehit(m,b,3)
  end
 end
end

function hitbomb(b,f,dmg)
 b.countdown = 3
end

function update_bomb(b)
 b.countdown -= 1
 if b.countdown <= 0 then

  local r = b.radius
  b.radius = 10
  for k in all({blobs,skeletons,players,bombs,blocks}) do
   tryexplodething(b,k)
  end
  
  local w = flr(b.radius/8)
  local cx = flr(b.x/8)
  local cy = flr(b.y/8)
  for j=cy-w,cy+w do
   for i=cx-w,cx+w do
    if fget(mget(i,j),1) then
     collapsetile(vinit(i,j))
    end
   end
  end
  
  b.radius = r
  
  particlesplosion(b)
  sfx(7)
  despawn(b)
 else
  b.hit = 0
  local m = b.countdown%30
  if (m == 10 or b.countdown == 20) sfx(8)
  if (b.countdown < 15 or m < 10) b.hit = 1
 end
end

function activate_chest(c,on)
 local cgp = gridpos(c)
 if on then
  mset(cgp.x,cgp.y,10)
 else
  collapsetile(cgp)
 end
 activate_actor(c,on)
end

function update_chest(c)
 if c.slide then
  c.slide -= 2
  if c.slide < 0 then
   c.y += 10
   despawn(c)
  else
   c.y -= 2
   if c.slide <= 0 then
     --to spawn the collectible
     c.life = 0 
   end
  end
 else
  for p in allof(players) do
   if p.last_dr == getdir(vsub(c,p))
   and btn(5,p.ctrl)
   and hugblock(p,c) then
    if c.holds then
     c.slide = 8
     c.sp = c.holds.sp
     sfx(9)
    else
     c.slide = 0
    end
   end
  end
 end
end

function redstonedir(pos,list)
 for j=-1,1 do
  for i=-1,1 do
   if i!=0 or j!=0 then
    local m = mget(pos.x+i,pos.y+j)
    if m==57 then
     local dr = vinit(i,j)
     if list then
      add(list,dr)
     else
      return dr
     end
    end
   end
  end
 end
end

function locate_targets(l)
 local checkpos = {}
 add(checkpos,gridpos(l))
 
 l.tpos = {}
 
 while #checkpos > 0 do
  local cp = checkpos[1]
  del(checkpos,cp)
  --check redstones around
  local drs = {}
  redstonedir(cp, drs)
  --brpnt(#drs)
  
  --dr is defined
  --locate next redstone
  --in straight line
  for dr in all(drs) do
   --turn this way
   local tpos = vadd(cp,dr)      
   collapsetile(tpos)
   for i=0,64 do
    tpos = vadd(tpos,dr)
    local m = mget(tpos.x,tpos.y)
    if invspawnsprite[m] then
     add(l.tpos,vadd(vmul(tpos,8),vinit(4,4)))
     break
    elseif m == 57 then
     add(checkpos,tpos)
     collapsetile(tpos)
     break
    end
   end
  end
 end
 
 if #l.tpos == 0 then
  l.tpos = nil
 end
end

function grab_targets(l)
 --if tpos is defined there
 --is some targets to grab
 if l.tpos then
  l.targets = {}
  for tpos in all(l.tpos) do
	  for a in allactors() do
	   if a != l and vsqrlen(vsub(tpos,a)) < 21 then
	    add(l.targets,a)
	    a.activate(a,false)
	    break
	   end
	  end
  end
  l.tpos = nil
 end
end

function update_lever(l)
 grab_targets(l)

 local csh = checkswordhit(l) or checkboomeranghit(l)
 if csh and not l.last_csh then
  l.fx = not l.fx
  sfx(10)
  activatetargets(l.targets,l.fx)
 end
 l.last_csh = csh
end

function hitblock(b,f,dmg)
 b.life -= dmg
 if b.life <= 0 then
  despawn(b)
  sfx(14)
 end
end

function update_block(b)
 if not fget(b.sp,0)
 and checkswordhit(b) then
  hitblock(b,nil,1)
 end

 for p in allof(players) do
  if hugblock(p,b) then
   local bt = getdir(vsub(b,p))
   if btn(bt,p.ctrl) then
    local d = vinit(0,0)
    if (bt == 0) d.x -= 0.5
    if (bt == 1) d.x += 0.5
    if (bt == 2) d.y -= 0.5
    if (bt == 3) d.y += 0.5
    move(b,d)
    sfx(13)
   end
  end
 end
end

function isabove(s,kind)
 for a in allof(kind) do
  if actorscollide(s,a) then
   return true
  end
 end
 return false
end

function update_switch(s)
 grab_targets(s)
 local lastsp = s.sp
 s.sp = 42
 if isabove(s,players) or isabove(s,blocks) then
  s.sp = 58 
 end
 
 if lastsp != s.sp then
  if s.sp==58 then
   sfx(11)
  else
   sfx(12)
  end
  activatetargets(s.targets,s.sp==58)
 end
end

function update_blower(b)
 if b.dr then
  local v = vmul(b.dr,2)
  local w = vmul(b.dr,rnd(1)-0.5)
  v.x += w.y
  v.y += w.x
  spawnparticle(b,v,rnd(2),18,6+rnd(2))
  
  for kind in all({players,blocks,blobs,skeletons,bombs}) do
   for a in allof(kind) do
	   local btoa = vsub(a,b)
	   local l = vlen(btoa)
	   btoa = vmul(btoa,1/l)
	   if l < 40
	   and vdot(btoa,b.dr) > 0.8 then
	    move(a,vmul(btoa,mid(1-(l-32)/8,0,1)))
	   end
	  end
  end
 end
end

function update_boomerang(b)
 if not move(b,vmul(b.vel,4)) then
  b.ret = 0
 end
 
 b.ret -= 1
 if b.ret <= 0 then
	 b.vel = vsub(b.player,b)
	 norm(b.vel)
	 if actorscollide(b,b.player) then
	  b.activate(b,false)
	 end
 end
 
 if b.ret%2 == 0 then
  local a = (b.ret/2)%4
  if a==0 then
   b.fx = false
   b.fy = false
  elseif a==1 then
   b.fx = true
   b.fy = false
  elseif a==2 then
   b.fx = true
   b.fy = true
  else
   b.fx = false
   b.fy = true
  end
	end
 
end

--@end behavior

function collapsetile(tp)
 local poll = {}
 local x,y = tp.x, tp.y
 poll[4] = 0.5
 poll[57] = -99
 for j=y-1,y+1 do
  for i=x-1,x+1 do
   if i!=x or j!=y then
    local m = mget(i,j)
    if not fget(m,0)
    and invspawnsprite[m] == nil then
     if poll[m] then
      poll[m] += 1
     else
      poll[m] = 1
     end
    end
   end
  end
 end
 
 local h = 0
 local v = 0
 for m,c in pairs(poll) do
  if c>h then
   v = m
   h = c
  end
 end
 mset(x,y,v)
end

--@main
function firstspawn()
 --auto spawn!
 --check all the map (except borders)
 local collapse = {}
 for j=1,62 do
  for i=1,126 do
   local m = mget(i,j)
   local k = invspawnsprite[m]
   if k != nil then
    if k!=keyblocks and k!=chests then
     add(collapse,vinit(i,j))
    end
    local a = spawn(i*8,j*8,k)
    --be adjusted to the grid
    a.x += a.ox
    a.y += a.oy
    if (k == collectibles) a.sp = m
   end
  end
 end
 for c in all(collapse) do
  collapsetile(c)
 end
 
 --force update everything once
 for a in allactors() do
  if(a.upt != nil) a.upt(a)
 end
 
 curactors = mapactors[xyindex(0,0)]
 
 updatefct = mainupdate
end

function mainupdate()
 debugpos = {}

 --actors
 for i=1,kindmax do
  for a in allof(i) do
 	 call_upt(a)
 	end
	end
 
 --particles
 foreach(particles,updateparticle)
end

function changescreen()
 local d = vsub(camtgt,campos)
 local l = flr(vlen(d)+0.5)
 
 if l == 0 then
  curactors = mapactors[xyindex(flr(campos.x/128),flr(campos.y/128))]
  updatefct = mainupdate
 else
  campos = vadd(campos,vmul(d,8/l))
 end
end

function maindraw()
 cls()
 rectfill(o,o,127,127,0)
 
 --show map
 camera(campos.x,campos.y)
 map(0,0,0,0,128,64)
 
 --show actors
 for i=1,kindmax do
  for a in allof(i) do
 	 call_draw(a)
 	end
	end
	
	local nextactors=mapactors[xyindex(flr(camtgt.x/128),flr(camtgt.y/128))]
	if nextactors and nextactors!=curactors then
	 for i=1,kindmax do
	  foreach(nextactors[i],call_draw)
		end
	end
 
 --show particles  
 foreach(particles,drawparticle)

 if debug then
  local p = actors[players][1]
 
  local c = 0
  for d in all(debugpos) do
   line(d.x-3,d.y-3,d.x+3,d.y+3,c)
   line(d.x-3,d.y+3,d.x+3,d.y-3,c)
   c += 1
  end
 end

 -- hud
 -- player life
 local player = getplayer(1)
 camera()
 for i=0,player.lifemax-1 do
  idx = 52
  if (i<player.life) idx = 51
  spr(idx,i*8,0)
 end
 spr(54,112,120)
 print("="..player.items[keys],120,122,6)
 spr(53,90,120)
 print("="..player.items[bombs],98,122,6)
 spr(25,0,120)
 print("="..player.items[money],8,122,6)
 
 --@debug
 if debug then
  camera()
  print(debugstr,0,100,8)
  print("mem "..stat(0),0,112,6)
  print("cpu "..flr(stat(1)*100).."%",64,112,6)
  print("px = "..player.x,0,120,6)
  print("py = "..player.y,64,120,6)
 end
end

function itemsmenustart()
 if updatefct != itemsmenuupt then
  --manually fade the screen
	 for j=0,127 do
	  for i=0,127 do
	   pset(i,j,fadepal[pget(i,j)+1])
	  end
	 end
	 memcpy(0x4300,0x6800,0x1000)
	 updatefct = itemsmenuupt
	 drawfct = itemsmenudraw
	 
	 local p = getplayer(1)
	 xitem = itemsprite[p.xitem]
	 oitem = itemsprite[p.oitem]
	 angleanim = 20
	 sizeanim = 20
	 itemselect = 0
--build list of available items
	 itemlist = {}
	 for i=5,12 do
	  if p.items[i] > 0 then
	   add(itemlist, itemsprite[i])
	  end
	 end
 end
end

function sign(val)
 if val < 0 then
  return -1
 elseif val == 0 then
  return 0
 else
  return 1
 end
end

function itemsmenuupt()
 if sizeanim != 0 then
  angleanim -= sign(angleanim)*2
  sizeanim -= 2
  if sizeanim == -20 then
	  updatefct = mainupdate
	  drawfct = maindraw
  end
 else
  if angleanim == 0 then
		 if btn(0) then
		  itemselect -= 1
		  angleanim += 10
		 elseif btn(1) then
		  itemselect += 1
		  angleanim -= 10
		 elseif btn(2) then
		  --exit item menu
		  local p = getplayer(1)
		  p.xitem = invitemsprite[xitem]
		  p.oitem = invitemsprite[oitem]
		  sizeanim = -2
		  angleanim = 20
		 elseif btnp(4) then
		  oitem = itemlist[itemselect+1]
		 elseif btnp(5) then
		  xitem = itemlist[itemselect+1]
		 end
		 itemselect = itemselect % #itemlist
		else
		 angleanim -= sign(angleanim)
		 sizeanim -= sign(sizeanim)
		end
	end
end

function easysspr(id,x,y,s)
 sspr((id%16)*8,flr(id/16)*8,8,8,
 x,y,s,s)
end

function itemsmenudraw()
 memcpy(0x6800,0x4300,0x1000)

 local da = 1/#itemlist 
 local a = (itemselect+angleanim/10)*da
 for id,itm in pairs(itemlist) do
  local s=cos(a)
  local sa=20-abs(sizeanim)
  local t=min(s+1.5,2.0)*8
  local x=56 + sin(a)*sa*2.5
  local y=56 + s*sa*0.25
  --white outline
  for p=1,15 do pal(p,7) end
  for j=-1,1 do
   for i=-1,1 do
    easysspr(itm,x+i,y+j,t)
   end
  end
  pal()
  easysspr(itm,x,y,t)
  local c=9
  if itm == xitem then
   rect(x-2,y-2,x+t+2,y+t+2,12)
   print("—",x,y+t-4)
   c=11
  end
  if itm == oitem then
   rect(x-2,y-2,x+t+2,y+t+2,c)
   print("Ž",x,y,9)
  end
  a -= da
 end
end

function _init()
 updatefct = firstspawn
 drawfct = maindraw
 
 menuitem(1,"items menu",itemsmenustart)
end

function _update()
 updatefct()
end

function _draw()
 drawfct()
end
__gfx__
000000000004400000000000000000000000000055565556000077000007770000077700444444444444444400000000eeeeeeee644444460000000000000000
00000000000ff00000044000000000000000000066666666077007000070707000707070499999944000000400222200222e222e64dddd460000000000000000
00700700000ff000000ff0000004400000000000565556550770700000077700000777004aaaaaa44000000402111120222e222e64dddd460444442000000000
000770000b3333b0000ff0000b0ff0000000000066666666000707000000000000000000444444444000000404222240eee2eee264dddd4600d44d2000000000
000770000b3333b00b3333b00b0ff00000000000655565550070707000670760006707604994499444400444444444442e222e22644ddd46044dd40000000000
00700700003333000b3333f000333b0000000000666666660707007700607060006070604999999449999994454545422e222e2264dddd460444442000000000
00000000001111000055110000333b0000000000556555657700700000060600000606004aaaaaa44aaaaaa404545420e5eee5ee64dddd460004200000000000
0000000000000000000000000000f100000000006666666600007770000606000060006044444444444444440022220066666666644444460004200000000000
00044000000440000000000000f44000444444443333333333333333cccccccc99999999000cc000000000000000000000040000000600000000000000000000
004ff400000440000004400000b44000444444443333333333333333cccccccc9999999900cccc00000000000077700000064000006660000000000000000000
040ff040000440000004400000b440004994444433333b3333333b33cccccccc9aa999990c7cc7c0003333000767670000060400000400000000000000000000
00b33b000b3333b00004400000333b00444444443333333333333333cccccccc999999990cc77cc003b33b3006767d0000060400000400000000000000000000
0b0330b00b3333b00b3333b000333bf04444444433333a3333333333cccccccc999999990cccccc03b3333b30767d70000060400000400000000000000000000
00333300003333000b3333f000001100444449943b33a8a33b333333cccccccc99999aa90c7cc7c0333b3b3b007d700000060400000400000000000000000000
001111000011110000551100000000004444444433333a3333333333cccccccc9999999900c77c0033b3b3b30000000000064000007470000000000000000000
00000000000000000000000000000000444444443333333333333333cccccccc99999999000cc0000bbbbb300000000000040000007070000000000000000000
00000000000440000000000000000000000000000000000000000000dddddddd2222222255065556000000000000000000000000000000000000000000000000
000000000004f0000004400000044000000044000000000000000000d111111d442444246600066600666600007000700000000a00033bb00000000000000000
00000000000ff0000004f0000004f00000004f000000700000000000d111111d4424442456550600066666607060706004000a00003bb3b00000000000000000
00044000000b3000000ff000000ff00000b0ff000000700050000000d11111dd442444240066000606666660600060004450044a03b33b300000000000000000
000ff000000f330000bb3000000bbf0000b33bbf0000700057777700d1111d1d44244424600505550566665000000000444544400b3bb3000000000000000000
00b33b000003330000f3330000033300000333000000700050000000d111d1dd442444246600066600555500007000700444441000b330000000000000000000
00011000000110000011550000551100000501100000700000000000d11d1d1d4424442455605565000000007060706000444100030000000000000000000000
00000000000000000000000000000000000000000005550000000000dddddddd2222222266606666000000006000600000011000000000000000000000000000
0000000000000000000000000000000000000000005500000000050056dddd560000000000011000000000000000000000666600055000500000000000000000
000ff000000000000000000000880880002202200001510000005050d561156d00000000001ee100000000000099990006111560567500650000000000000000
000ff000000880000000000008888778020020020011111000005005d156561d49000000018ee210006666000009999006111160006506750000000000000000
00055000008228000000000008888888020000020111111d00000550d10000dd049000001eeee281066666600000099006111560000115500000000000000000
00b55bb0008228000008800008888888020000020111111d00005500d100001d0049000018ee2221066666600000099006515160055110000000000000000000
00bb33b0008228000082280000888880002000200111111d05056000d15006dd0004900012228221006666000000009006151560576056000000000000000000
0014110000822800082222800008880000022200001111d055560000d56d156d0022220001122110000000000000000000615600560057650000000000000000
0000000000888800088888800000000000000000000ddd000060000056dddd560555555000011000000000000000000000066000050005500000000000000000
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
61616161616161616161616161616161616161616161616161936161616161717171717171717171717171717171717171616161616161616161616141414141
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161939361936161616161717171717171717171717171717171717171716161616161616161616161414141
41616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161615061615050616161925061615061717171717171717171717171717171717171716161616161616161616161614141
41416161616161616161616161616161616161616161616123616161616161616161616161616161616161616161616161616161616161616161616161616161
61505050505061616161616161616161615050505050505050929250505061717171717171717171717171717171717171717161616161616161616161616141
41414161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61504040405050505050505050506161615040404040404040504040405061717171717171717171717171717171717171717161616161616161616161616161
41414161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
9350932340b2b293b1b2b293b1506161615040404040404040504040635061717171717171717171717171717171717171717161616161616161616161616161
61414141616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
93504040405050505050505093506161615040604090914040504040705061717171717171717171717171717171717171717161616161616161616161616161
61616141416161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
615050505050616161616161a2616161615040404040404040505050505061717171717171717171717171818181717171717171616161616161616161616161
61616161414161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
93936161616161619090536161616161615040404040404040404040405061717171717171717171717181535353817171717171616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161619161616161616161615090534040404040404040405061823370828293238282233381535353817171717171616161616161616161616161
616161616161616161c0c0c061616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161615050505050507350505050505061717171717171717171717181535353817171717161616161616161616161616161
6161616161e061616150d05061616161616161616161616161616161616161616161616161616161616161703361616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161717171717171717171717171818181717171717161616161616161616161616161
61616161616161616103610161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161717171717171717171717171717171717171717161616161616161616161616161
61616161616161616161616102616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161717171717171717171717171717171717171716161616161616161616161616161
61616161616161616161610261616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161717171717171717171717171717171717171716161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161717171717171717171717171717171717171616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161717171717171717171717171717171717171616161616161616161616161616161
61616161616161616161616161616161616161616161616161616123616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616171717171717171717171717171716161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161336161616161613361616161616133616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161617171717171717171717161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161612361616161612361616161612361616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616171716161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61236161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61336161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161332361616161616161616161612333616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161612361616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616123336161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161612361616161612361616161612361616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161706161616161616161616161616161616161616161616161616161616161616161336161616161613361616161616133616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161
__label__
555655565556555655565556555655565556555655565556555655565556555655565556cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
668868866688688666886886668868866688688666886886668868866688688666666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
588887785888877858888778588887785888877858888778588887785888877856555655cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
688888886888888868888888688888886888888868888888688888886888888866666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
688888886888888868888888688888886888888868888888688888886888888865556555cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
668888866688888666888886668888866688888666888886668888866688888666666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
556888655568886555688865556888655568886555688865556888655568886555655565cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
666666666666666666666666666666666666666666666666666666666666666666666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
55565556000000000000000000000000000000000000000000000000dddddddd5556555655565556555655565556555633333333333333333333333333333333
66666666000000000022220000222200000000000000000000000000d111111d6666666666666666666666666666666633333333333333333333333333333333
56555655000000000211112002111120000000000000000000000000d111111d5655565556555655565556555655565533333b3333333b3333333b3333333b33
66666666000000000422224004222240000000000000000000000000d11111dd6666666666666666666666666666666633333333333333333333333333333333
65556555000000004444444444444444000000000000000000000000d1111d1d6555655565556555655565556555655533333333333333333333333333333333
66666666000000004545454245454542000000000000000000000000d111d1dd666666666666666666666666666666663b3333333b3333333b3333333b333333
55655565000000000454542004545420000000000000000000000000d11d1d1d5565556555655565556555655565556533333333333333333333333333333333
66666666000000000022220000222200000000000000000000000000dddddddd6666666666666666666666666666666633333333333333333333333333333333
55565556000000000000000000000000000000000000000000000000dddddddd0000000000000000000000005556555633333333333333333333333333333333
66666666000000000022220000222200000000000000000000000000d111111d0000000000000000000000006666666633333333333333333333333333333333
56555655000000000211112002111120000000000000000000000000d111111d0000000000000000000000005655565533333b3333333b3333333b3333333b33
66666666000000000422224004222240000000000000000000000000d11111dd0000000000000000000000006666666633333333333333333333333333333333
65556555000000004444444444444444000000000000000000000000d1111d1d0000000000000000000000006555655533333333333333333333333333333333
66666666000000004545454245454542000000000000000000000000d111d1dd000000000000000000000000666666663b3333333b3333333b3333333b333333
55655565000000000454542004545420000000000000000000000000d11d1d1d0000000000000000000000005565556533333333333333333333333333333333
66666666000000000022220000222200000000000000000000000000dddddddd0000000000000000000000006666666633333333333333333333333333333333
55565556000000000000000000000000000000000000000000000000dddddddd5556555655565556000000005556555633333333333333333333333333333333
66666666000000000000000000000000000000000000000000000000d111111d6666666666666666000000006666666633333333333333333333333333333333
56555655000000000000000000000000000000000000000000000000d111111d5655565556555655000000005655565533333b3333333b3333333b3333333b33
66666666000000000000000000000000000000000000000000000000d11111dd6666666666666666000000006666666633333333333333333333333333333333
65556555000000000000000000000000000000000000000000000000d1111d1d6555655565556555000000006555655533333333333333333333333333333333
66666666000000000000000000000000000000000000000000000000d111d1dd666666666666666600000000666666663b3333333b3333333b3333333b333333
55655565000000000000000000000000000000000000000000000000d11d1d1d5565556555655565000000005565556533333333333333333333333333333333
66666666000000000000000000000000000000000000000000000000dddddddd6666666666666666000000006666666633333333333333333333333333333333
55565556000000000000000000000000000000000000000055565556555655565556555633333333333333333333333333333333333333333333333333333333
66666666000000000000000000000440000000000000000066666666666666666666666633333333333333333333333333333333337333733333333333333333
56555655000000000000000000000ff0000000000000000056555655565556555655565533333b3333333b3333333b3333333b3373637b6333333b3333333b33
66666666000000000000000000000ff0000000000000000066666666666666666666666633333333333333333333333333333333633363333333333333333333
655565550000000000000000000b3333b00000000000000065556555655565556555655533333333333333333333333333333333333333333333333333333333
666666660000000000000000000f3333b0000000000000006666666666666666666666663b3333333b3333333b3333333b3333333b7333733b3333333b333333
55655565000000000000000000001155000000000000000055655565556555655565556533333333333333333333333333333333736373633333333333333333
66666666000000000000000000000000000000000000000066666666666666666666666633333333333333333333333333333333633363333333333333333333
55565556000000000000000000000000000000000000000055565556333333333333333333333333333333333333333333333333333333333333333333333333
66666666000000000066660000000000000000000000000066666666333333333333333333333333333333333333333333333333337333733333333333333333
5655565500000000066666600000000000000000000000005655565533333b3333333b3333333b3333333b3333333b3333333b3373637b6333333b3333333b33
66666666000000000666666000000000000000000000000066666666333333333333333333333333333333333333333333333333633363333333333333333333
65556555000000000566665000000000000000000000000065556555333333333333333333333333333333333333333333333333333333333333333333333333
666666660000000000555500000000000000000000000000666666663b3333333b3333333b3333333b3333333b3333333b3333333b7333733b3333333b333333
55655565000000000000000000000000000000000000000055655565333333333333333333333333333333333333333333333333736373633333333333333333
66666666000000000000000000000000000000000000000066666666333333333333333333333333333333333333333333333333633363333333333333333333
555655565556555655565556555655565556555655565556555655563333333333333333dddddddd333333333333333333333333333333333333333333333333
666666666666666666666666666666666666666666666666666666663333333333666633d111111d333333333333333333333333337333733333333333333333
5655565556555655565556555655565556555655565556555655565533333b3336666663d111111d33333b3333333b3333333b3373637b6333333b3333333b33
666666666666666666666666666666666666666666666666666666663333333336666663d11111dd333333333333333333333333633363333333333333333333
655565556555655565556555655565556555655565556555655565553333333335666653d1111d1d333333333333333333333333333333333333333333333333
666666666666666666666666666666666666666666666666666666663b3333333b555533d111d1dd3b3333333b3333333b3333333b7333733b3333333b333333
556555655565556555655565556555655565556555655565556555653333333333333333d11d1d1d333333333333333333333333736373633333333333333333
666666666666666666666666666666666666666666666666666666663333333333333333dddddddd333333333333333333333333633363333333333333333333
55565556333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333337333733373337333733373337333733333333333333333
5655565533333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3373637b6373637b6373637b6373637b6333333b3333333b33
66666666333333333333333333333333333333333333333333333333333333333333333333333333633363336333633363336333633363333333333333333333
65556555333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
666666663b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b7333733b7333733b7333733b7333733b3333333b333333
55655565333333333333333333333333333333333333333333333333333333333333333333333333736373637363736373637363736373633333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333633363336333633363336333633363333333333333333333
55565556333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
5655565533333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b33
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
65556555333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
666666663b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b333333
55655565333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
55565556333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
5655565533333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b33
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
65556555333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
666666663b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b333333
55655565333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
55565556333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
5655565533333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b33
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
65556555333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
666666663b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b333333
55655565333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
55565556333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
5655565533333b3333333b3333333b3333333b3333388b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b33
66666666333333333333333333333333333333333382283333333333333333333333333333333333333333333333333333333333333333333333333333333333
65556555333333333333333333333333333333333382283333333333333333333333333333333333333333333333333333333333333333333333333333333333
666666663b3333333b3333333b3333333b3333333b8228333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b333333
55655565333333333333333333333333333333333382283333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333388883333333333333333333333333333333333333333333333333333333333333333333333333333333333
55565556333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
5655565533333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333388b3333333b3333333b3333333b3333333b3333333b3333333b33
66666666333333333333333333333333333333333333333333333333333333333333333333822833333333333333333333333333333333333333333333333333
65556555333333333333333333333333333333333333333333333333333333333333333333822833333333333333333333333333333333333333333333333333
666666663b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b8228333b3333333b3333333b3333333b3333333b3333333b333333
55655565333333333333333333333333333333333333333333333333333333333333333333822833333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333888833333333333333333333333333333333333333333333333333
55565556333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
5655565533333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b33
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
655565553333333333333333333333333333333333333a3333333333333333333333333333333333333333333333333333333333333333333333333333333333
666666663b3333333b3333333b3333333b3333333b33a8a33b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b333333
556555653333333333333333333333333333333333333a3333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
55565556333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
5655565533333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b33
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
65556555333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
666666663b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b333333
55655565333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
66666666333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
555cc556cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc55ccccccccccccccccccccccc5cccccccccc
66cccc66ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc151cccccccccccccccccccc5c5ccccccccc
5c7cc7c5cccc666ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111ccccc666ccccccccccc5cc5cccc666c
6cc77cc6666c6c6cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111d666c6c6cccccccccccc55c666c6c6c
6cccccc5cccc6c6cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111dcccc6c6ccccccccccc55cccccc6c6c
6c7cc7c6666c6c6cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111d666c6c6cccccccc5c56ccc666c6c6c
55c77c65cccc666ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111dccccc666ccccccc5556cccccccc666c
666cc666cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccdddcccccccccccccccccc6ccccccccccccc

__gff__
0000000000010000000101000000000000000000000200010000020000000000000000000000000100030000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0505050505050505051717171717171717171717171717171717171717171717171616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
05330b0b33040427050505051616161616163916161616393916161717171717171616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
05190b0b1904042704391b051616161616163916161616161616161617171717171616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
0504040404040427050504051616161616050505050505140505051616171717171616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
050404040404050505163916162b161616050404050505140505051616171717171616161635161616323516161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
05042a390404051616163916162b161616050404291414141414141616171717171616161632161616161616161818181616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
05050505050505162a271616162b161616050936051405050505051616171717171616161616161616161618181818181816161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
051616161616161639162b2b2b2b161616050505051405043906051616271717171714141414321414161618181818181818181616161616161616161616161616161616161616161616161616161616161632161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
0516161616161616161616161616161616141414141405043804051616372828282814321414351414141818181818181818181616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
0516330716161639393916160716161616050514050505040404051616271717171714351414141414141414141818181818181816161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
0516161616161616161616163316161616050514050505052905051616171717171616161632161414323514141418181818181818161616161616161616161632161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616163216161616161616161616161616161616
0535071639321616161616161616161616161616161616163916161616171717171616161635161614141414141414181818181818181616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
0516391616331616163239160716161616161616351616160716161617171717171616161616161616161414141414141818181818161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
0516161616151616163316163516161616161616091616163916161717171717171616161616161616161818141414141414181818161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
0516393916161616161616161616161616161616161616163917171717171717171616161616161616161618181814141414181816161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616160733161616161616161616161616161616161616161616161616161616
0517171717171617171717171717171717171717171717171717171717171716161616161616161616161616161814141414181616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
1717171717171617171717171717171717171717171717171717171717171716161616161616161616161616161616141414161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
1616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161414141616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
1616161616161616161616161616161616050505050505050505050505051616161616161616161616161616161616161414141416161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
161616331616351616361616191616161605051b39042b050404040739051639161616161616161616161616161616161614141414161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
1616160916160916160916160916161616050504050505050405040404051639161616161616161616161616161616161616141414141416161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
1616161616161616161616161616161616050539050404040405390404051616161616161616161616161616161616161616161614141414161616161616161616161616161616161616161616161616161616161632161616161616161616161616161616161616161616161616161616161616161616161616161616161616
1616161c16161d16162c16162d1616161605051b0404040404051b0404051616161616161616161616161616161616161616161614141414161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
1616160916160916160916160916161616050505050505050505050505051616161616161616161616161616161616161616161616141414141416161616161616161616161616161632161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
1616161616161616161616161616161616050505050505050505050505051616161616161616161616161616161616161616161616141414141414161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
1616163b16163c16162516163d16161616050439040404040404390404051616161616161616161616161616161616161616161616161414141414141616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
161616091616091616091616091616161605042a0404380404042a0419051616161616161616161616161616161616161616161616161614141414141616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
1616161616161616161616161616161616050404040439040404040409053939161616161616161616321616161616161616161616161614141414141616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
161616161616161616161616161616161605050505050505050d050505051616161616161616161717171616161616161616161616161614141414141416161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
1616161616161616161616161616161616161616161616161616163916161616161616171717171717171717171616161616161616161616141414141416161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
1616161616161616161616321616161616161616161639391616163916161616161717171717171717171717171717161616161616161616161414141414161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616
1616160116161616161616161616161616161616161639161616161616161617171717171717171717171717171717171716161616161616161616141414141616161616161616161616161616161616161616161616161616161616161616161616161616161616161616163216161616161616161616161616161616161616
__sfx__
00010000026200462006630086300c640136501d6602a6701f60026600016001160013600096001b6001c6001d6001e6001e6001e6001e6001e6001e600000000000000000000000000000000000000000000000
000300000a6500735011340196401b6300d6201132017620196200c62015320166201b230292302e34034650396303a6203a61037610336102e6102c610362001400017000000001b0001e000190000000000000
00030000076500b3500d25015650083500d2500f250156300f3300c2300e220116200d3100f3000e3000e3000f30025200271001e600283002930000000000000000000000000000000000000000000000000000
0003000021070250701b0701507019070160500f0500a050090400603005020010200300002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a00002e0302a030370300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001f4501f4501565015150156501415015650151503265030450316502e4502b650281501b6001a1001a1001a1001e1001c100196001c1001b600201002310024100256002710028100396003960039600
000400002653026530330002a050335002d5503350031050320503556039050390403903039030297002970029700000000000000000000000000000000000000000000000000000000000000000000000000000
000200001d65022650121502d650346501e150396503a6502315037650356501e1502b65027650161501e6401b6400c1501563011630051500c6200a620021500661004610026000160001100011001310013100
000200001144011400114400000011440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000154501f6501e400154501f650000000000000000231502315023150231502b2502b2502b2503905039050390503905039050390503905039050390503900039000390003900039000390003900039000
000200001410014100081301013027650141000e1301513028650101002760000000000000f100151002860000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000b74010740000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600001074009740077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000161001610016101560001610016100161015600016100161001610156000161001610016101560015600000001360013600136001360014600146001560014600136001360013600136001360013600
000200001f650377501b6002975001600327501b65022750166502975010650187500c65020750076501e75000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000003f7003f7003f7003f7003f7003f7003f7003f700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600003f0703f0003f070000003f070000002600000000260000000000000260000000026000260000000026000260000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

