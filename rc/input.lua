--button press as number
function btnn(b)
  return tonum(btn(b))
end

--mouse support utils
lastmousestate = 0
currentmousestate = 0
lastmousepos = newvector()
mousepos = newvector()
function mousesupport()
  lastmousestate = currentmousestate
  currentmousestate = stat(34)
  lastmousepos:copy(mousepos)
  mousepos:set(stat(32),stat(33))
  mwhl = stat(36)
end

function mbtn(mb)
  return (currentmousestate & 1 << mb) ~= 0
end

function mbtnp(mb)
  return (currentmousestate & 1 << mb) ~= 0 and (lastmousestate & 1 << mb) == 0
end

-- mouse position as a vector relative to screen position set by camera(x,y)
function getlocalmouse()
  return mousepos+newvector(peek2(0x5f28), peek2(0x5f2a))
end

function getrelmouse()
  return mousepos-lastmousepos
end