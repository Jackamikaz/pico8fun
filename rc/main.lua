flatcellcount = 0
function drawflatcell(x,y)
  if btn(❎) then
    x,y = x*8,y*8
    rectfill(x,y,x+8,y+8,7)
    rect(x,y,x+8,y+8,0)
    print(flatcellcount,x+1,y+2,1)
    flatcellcount += 1
  else
    map(x,y,x*8,y*8,1,1)
  end
end

drawmethods = {
function() -- 2D DRAW ------------------------------
  local cx = cam_x - 8
  local cy = cam_y - 8
  camera(cx * 8, cy * 8)

  --map(cx, cy, flr(cx) * 8, flr(cy) * 8, 17, 17)
  
  flatcellcount = 0
  disperscan(drawflatcell)
  player:draw()

  if btn(❎) then
    local px,py,xl,yl,xr,yr = cam_x,cam_y, getfarsegment()
    px*=8 py*=8 xl*=8 yl*=8 xr*=8 yr*=8

    color(8)
    line(xl,yl,xr,yr)
    line(px,py,xl,yl)
    line(px,py,xr,yr)

    local mx, my = stat(32)+cx*8, stat(33)+cy*8
    spr(32,mx,my)
    print(pointintriangle(mx,my,px,py,xl,yl,xr,yr),mx+6,my+2,7)
  end
end,
function() -- CLASSIC RAYCAST ------------------------------
  camera(-64,-64)
  floorcast(0)
  raycast()
end,
function() -- MY "GRIDCASTING" ------------------------------
  camera(-64,-64)
  disperscan(draw3Dcell)
end}

currentdraw = 3

modes = {
play={
enter=function()
  disp_top=-64
  disp_bottom=64
end,
update=function()
  player:update()
  player:copytocam()
end,
draw=function()
  cls()
  if btnp(🅾️) then
    currentdraw = (currentdraw + 1) % #drawmethods + 1
  end

  drawmethods[currentdraw]()
end,
fps=30},
edit={
enter=editorenter,
update=editorupdate,
draw=editordraw,
fps=60}
}

function switchmode(mode)
  local fps = mode.fps
  _set_fps(fps)
  if fps == 30 then
    _update = mode.update
    _update60 = nil
  else
    _update = nil
    _update60 = mode.update
  end
  _draw = mode.draw
end

function _init()
  setupcamera()
  setfov(0.2222)
  buildluamap()
  poke(0x5f2d, 1) --enable mouse
  local i = 1
  for n,v in pairs(modes) do
    menuitem(i,n,function() switchmode(v) end)
    i += 1
  end

  switchmode(modes.edit)
end
