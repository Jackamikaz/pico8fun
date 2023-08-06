pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function vec(a,b,c)
 return {x=a,y=b,z=c}
end

function cross(l,r)
 return vec(
  l.y*r.z - l.z*r.y,
  l.z*r.x - l.x*r.z,
  l.x*r.y - l.y*r.x)
end

camera(-64,-64)

function _draw()
 cls()

 local t = t()*0.1
 local turn = vec(cos(t)*32,sin(t)*32,0)
 local perp = cross(turn,vec(0,0,1))

 line(0,0,turn.x,turn.y,7)
 line(0,0,perp.x,perp.y,11)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000