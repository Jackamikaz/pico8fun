--button press as number
function btnn(b)
  return tonum(btn(b))
end

--mouse support utils
lastmousestate = 0
currentmousestate = 0
lastmousepos = newvector2()
mousepos = newvector2()
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

function getrelmouse()
  return mousepos-lastmousepos
end