editcam = newvector()
edittab = 1

--printh(escbin(sprtop8scii(51)),"@clip")
icons = {
  arrow = "ᶜ1⁶.²⁵\9■!」◀\0⁸ᶜ7⁶.\0²⁶ᵉ゛⁶⁸\0",
  grab = "ᶜ1⁶.⁘*CAB<\0\0⁸ᶜ7⁶.\0T<><\0\0\0",
  finger = "³eᶜ1⁶.⁴\10\10+BAB<⁸ᶜ7⁶.\0⁴⁴T=><\0",
  tab0 = "⁶.\0>ckkc○○⁸ᶜd⁶.\0\0、⁘⁘、\0\0",
  tab1 = "⁶.\0>swwc○○⁸ᶜd⁶.\0\0ᶜ⁸⁸、\0\0",
  tab2 = "⁶.\0>co{c○○⁸ᶜd⁶.\0\0、▮⁴、\0\0",
  tab3 = "⁶.\0>cgoc○○⁸ᶜd⁶.\0\0、「▮、\0\0"
}

function isvecinrect(v,x1,y1,x2,y2)
  return mid(v.x,x1,x2) == v.x and mid(v.y,y1,y2) == v.y
end

function editorupdate()
  mousesupport()

  cursor = icons.arrow
  if mbtn(2) then
    editcam -= getrelmouse()
    cursor = icons.grab
  elseif isvecinrect(mousepos,96,86,127,95) then
    cursor = icons.finger
    if (mbtnp(0)) edittab = (mousepos.x-96)\8
  end

  cam_z -= mwhl/8
end

function topdowndepth(d)
  d=cam_z-d
  if (d~=mid(2,0,d)) return false
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

  fillp(0b1010010110100101)
  color(1)
  for i=0,127,8 do
    local x=i+8-editcam.x%8
    local y=i+8-editcam.y%8
    line(x,0,x,127)
    line(0,y,127,y)
  end

  fillp()
  local ex,ey = editcam:unpack()
  camera(ex,ey)
  ex,ey = ex\8,ey\8
  
  for x=ex,ex+16 do
    for y=ey,ey+16 do
      local lm,f=luamap(x,y)
      if (lm) f=lm.floors
      if f then
        for i=1,#f,2 do
          local z,m = unpack(f,i,i+1)
          if (topdowndepth(z)) spr(m,x*8,y*8)
        end
      end
    end
  end

  pal()

  for x=ex,ex+16 do
    for y=ey,ey+16 do
      local lm,w=luamap(x,y)
      if (lm) w=lm.walls
      if  w then
        for i=1,#w,7 do
          local x1,y1,x2,y2,z1,z2,m = unpack(w,i,i+6)
          if (mid(z1,z2,cam_z) == cam_z) line(x1*8,y1*8,x2*8,y2*8,7)
        end
      end
    end
  end

  camera(0,0)

  rectfill(0,86,127,95,5)
  for i=0,3 do
    local x=96+i*8
    local t = edittab == i
    ?icons["tab"..i],x,88-tonum(t),t and 7 or 6
    line(x,95,x+6,95,t and 6 or 13)
  end

  rectfill(0,96,127,127,0)
  for y=0,3 do
    for x=0,15 do
      spr(edittab*64+y*16+x,x*8,96+y*8)
    end
  end
  
  ?"z: "..flr(cam_z).."."..(cam_z%1*8),2,2,7
  ?cursor,mousepos:unpack()

  
end
