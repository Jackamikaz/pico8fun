pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
#include bresenham.lua
#include bresescan.lua

px, py = 63, 63

dir = 0
halffov = 0.125

function farviewcoord(farplane)
  local ld,rd = dir + halffov, dir - halffov
  local lc,ls,rc,rs = cos(ld), sin(ld), cos(rd), sin(rd)
  return
    px + lc*farplane,  py + ls*farplane,
    px + rc*farplane,  py + rs*farplane
    --px + lc*nearplane, py + ls*nearplane,
    --px + rc*nearplane, py + rs*nearplane
end

function btnn(b)
  return btn(b) and 1 or 0
end

function _update()
  dir += (btnn(🅾️) - btnn(❎)) * 0.0125

  if(btn(⬅️)) px -=1
  if(btn(➡️)) px +=1
  if(btn(⬆️)) py -=1
  if(btn(⬇️)) py +=1
end

col,li = 1,-1
function bssfunc(x,y,i)
  pset(x,y,col+1)
  if i~=li then
    li=i
    col = (col+1)%15
  end
end

function _draw()
  cls()
  x1,y1,x2,y2 = farviewcoord(50)

  color(7)
  bresenham(x1,y1,x2,y2)
  bresenham(x1,y1,px,py)
  bresenham(x2,y2,px,py)

  --[[local ltop,rtop = {}, {}
  bresenhamlog(ltop,x1,y1,px,py)
  bresenhamlog(rtop,x2,y2,px,py)

  local col = 1
  for i=0,min(#ltop,#rtop) * 0.5 - 2 do
    color(col+1)
    local ix,iy = i*2+1, i*2+2
    bresenham(ltop[ix],ltop[iy],rtop[ix],rtop[iy])
    col = (col+1) % 15
  end

  -----------------]]

  col = 1
  bresescan(bssfunc,px,py,x1,y1,x2,y2)
  
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
