function editorupdate()

end

function editordraw()
  cls()
  camera(0,0)

  fillp(0b1010010110100101)
  color(1)
  for x=0,127,8 do
    line(x,0,x,127)
    line(0,x,127,x)
  end

  spr(32,stat(32),stat(33))
end