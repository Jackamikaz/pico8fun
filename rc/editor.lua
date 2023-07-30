editcam = newvector()
edittab = 0
editspr = 0

printh(escbin(sprtop8scii(48)),"@clip")
icarrw = "ᶜ1⁶.²⁵\9■!」◀\0⁸ᶜ7⁶.\0²⁶ᵉ゛⁶⁸\0"
icgrab = "ᶜ1⁶.⁘*CAB<\0\0⁸ᶜ7⁶.\0T<><\0\0\0"
icfngr = "³eᶜ1⁶.⁴\10\10+BAB<⁸ᶜ7⁶.\0⁴⁴T=><\0"
ictab0 = "⁶.\0>ckkc○○⁸ᶜd⁶.\0\0、⁘⁘、\0\0"
ictab1 = "⁶.\0>swwc○○⁸ᶜd⁶.\0\0ᶜ⁸⁸、\0\0"
ictab2 = "⁶.\0>co{c○○⁸ᶜd⁶.\0\0、▮⁴、\0\0"
ictab3 = "⁶.\0>cgoc○○⁸ᶜd⁶.\0\0、「▮、\0\0"
icross = "⁶.\"w>、>w\"\0"
icrayn = "⁶.▮8|>。	⁷\0"

function isvalbetween(v,a,b)
  return mid(v,a,b) == v
end

function isvecinrect(v,x1,y1,x2,y2)
  return isvalbetween(v.x,x1,x2) and isvalbetween(v.y,y1,y2)
end

function editorupdate()
  mousesupport()

  cursor = icarrw
  if mbtn(2) then
    editcam -= getrelmouse()
    cursor = icgrab
  elseif isvecinrect(mousepos,96,86,127,95) then
    cursor = icfngr
    if (mbtnp(0)) edittab = (mousepos.x-96)\8
  elseif isvecinrect(mousepos,20,86,27,95) then
    cursor = icfngr
    if (mbtnp(0)) editspr = -1
  elseif mousepos.y > 95 then
    if (mbtnp(0)) editspr = edittab*64 + mousepos.x\8 + (mousepos.y-96)\8*16
  elseif mbtn(0) then
    local lm = luamap(((editcam+mousepos)/8):flr():unpack())
    local f = lm and lm.floors
    for i,v in ipairs(f) do
      if v[1]==cam_z then
        if editspr == -1 then
          deli(f,i)
        else
          v[2] = editspr
        end
        break
      end
    end
  end

  cam_z = flr(cam_z*8)/8 - mwhl/8
end

function topdowndepth(d)
  d=cam_z-d
  if (not isvalbetween(d,0,2)) return false
  if d==0 then
    pal()
  elseif d<1 then
    pal(fadepal[1])
  else
    pal(fadepal[2])
  end
  return true
end

function editordraw()
  cls()

  -- grid background
  fillp(0b1010010110100101)
  color(1)
  for i=0,127,8 do
    local x=i+8-editcam.x%8
    local y=i+8-editcam.y%8
    line(x,0,x,127)
    line(0,y,127,y)
  end
  fillp()

  -- floor tiles
  local ex,ey = editcam:unpack()
  camera(ex,ey)
  ex,ey = ex\8,ey\8

  for x=ex,ex+16 do
    for y=ey,ey+16 do
      local lm=luamap(x,y)
      for _,v in ipairs(lm and lm.floors) do
        local z,m = unpack(v)
        if (topdowndepth(z)) spr(m,x*8,y*8)
      end
    end
  end
  pal()

  -- wall lines
  for x=ex,ex+16 do
    for y=ey,ey+16 do
      local lm=luamap(x,y)
      for _,v in ipairs(lm and lm.walls) do
        local x1,y1,x2,y2,z1,z2,m = unpack(v)
        if (isvalbetween(cam_z,z1,z2)) line(x1*8,y1*8,x2*8,y2*8,7)
      end
    end
  end

  camera(0,0)

  -- spritesheet
  local edittab64=edittab*64
  rectfill(0,96,127,127,0)
  for y=0,3 do
    for x=0,15 do
      spr(edittab64+y*16+x,x*8,96+y*8)
    end
  end

  -- selected sprite
  if isvalbetween(editspr,edittab64,edittab64+63) then
    local s = editspr-edittab64
    local x,y = s%16*8,s\16*8+96
    rect(x-1,y-1,x+8,y+8,7)
    rect(x-2,y-2,x+9,y+9,0)
  end

    -- tools and tabs
    rectfill(0,85,127,95,5)
    ?icrayn,9,87,editspr~=-1 and 7 or 13
    ?icross,20,87,editspr==-1 and 7 or 13
    for i=0,3 do
      local x=96+i*8
      local t = edittab == i
      ?_ENV["ictab"..i],x,88-tonum(t),t and 7 or 6
      line(x,95,x+6,95,t and 6 or 13)
    end
  
  -- info and mouse
  ?"z: "..flr(cam_z).."."..(cam_z%1*8),2,2,7
  ?cursor,mousepos:unpack()

  
end
