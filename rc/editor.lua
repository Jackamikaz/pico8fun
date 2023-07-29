editcam = newvector()

--printh(escbin(sprtop8scii(3)),"@clip")
icons = {
  arrow = "ᶜ1⁶.²⁵\9■!」◀\0⁸ᶜ7⁶.\0²⁶ᵉ゛⁶⁸\0",
  grab = "ᶜ1⁶.⁘*CAB<\0\0⁸ᶜ7⁶.\0T<><\0\0\0",
  finger = "ᶜ1⁶.⁴\10\10+BAB<⁸ᶜ7⁶.\0⁴⁴T=><\0"
}

printh(chr(0b110000))

function editorupdate()
  mousesupport()

  cursor = icons.arrow
  if mbtn(2) then
    editcam -= getrelmouse()
    cursor = icons.grab
  end
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

  local ex,ey = editcam:unpack()
  camera(ex,ey)
  ex,ey = ex\8,ey\8
  for x=ex,ex+16 do
    for y=ey,ey+16 do
      local lm=luamap(x,y)
      if lm and lm.floors then
        spr(lm.floors[2],x*8,y*8)
      end
    end
  end

  camera(0,0)
  ?cursor,mousepos:unpack()

  
end
