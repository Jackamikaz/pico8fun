editcam = newvector()
edittab = 0
editspr = 0
editbig = false
editmod = 1 -- 1 for floors, 2 for walls
editvew = 1 -- 1 for tile view, 2 for gridcasting

--[[
local str=""
for s=49,50 do
  str ..= "\""..escbin(sprtop8scii(s)).."\"\r"
end
printh(str,"@clip")--]]
icarrw = "ᶜ1⁶.²⁵\9■!」◀\0⁸ᶜ7⁶.\0²⁶ᵉ゛⁶⁸\0"
icgrab = "ᶜ1⁶.⁘*CAB<\0\0⁸ᶜ7⁶.\0T<><\0\0\0"
icfngr = "³eᶜ1⁶.⁴\10\10+BAB<⁸ᶜ7⁶.\0⁴⁴T=><\0"
icrsiz = "ᶜ1⁶.⁴\n■\0■\n⁴\0⁸ᶜ7⁶.\0⁴ᵉ\0ᵉ⁴\0\0"

ictab0 = "⁶.\0>ckkc○○⁸ᶜd⁶.\0\0、⁘⁘、\0\0"
ictab1 = "⁶.\0>swwc○○⁸ᶜd⁶.\0\0ᶜ⁸⁸、\0\0"
ictab2 = "⁶.\0>co{c○○⁸ᶜd⁶.\0\0、▮⁴、\0\0"
ictab3 = "⁶.\0>cgoc○○⁸ᶜd⁶.\0\0、「▮、\0\0"

icsprs = "⁶.?!?\0‖*\0\0"
icexpd = "⁶.?!!!!?\0\0"
ictiln = "⁶.□?□□?□\0\0"
icrcst = "⁶.c]II]c\0\0"

icross = "⁶.\"w>、>w\"\0"
icrayn = "⁶.▮8|>。	⁷\0"
icwall = "⁶.p~~~~ᵉ\0\0"
icflor = "⁶.\0、○◜|「\0\0"

editbtn = {}
function addeditbtn(n,x,y,ic,func)
  editbtn[n] = {x,y,x+6,y+6,ic,func}
end

addeditbtn("small",5,1,icsprs,function() editbig=false end)
addeditbtn("big",13,1,icexpd,function() editbig=true end)
addeditbtn("tiling",108,1,ictiln,function() editvew=1 end)
addeditbtn("raycast",116,1,icrcst,function() editvew=2 end)
addeditbtn("draw",5,88,icrayn,function() if (editspr<0) editspr=-editspr-1 end)
addeditbtn("del",14,88,icross,function() if (editspr>=0) editspr=-editspr-1 end)
addeditbtn("floor",35,88,icflor,function() editmod=1 end)
addeditbtn("wall",44,88,icwall,function() editmod=2 end)

--[[
local test = {1,2,3,4,5,6,7,8}

local i=1
while i<=#test do
  local v=test[i]
  printh("i is "..i)
  if v==2 or v==3 or v==7 then
    printh("deleting value "..v.." at index "..i)
    deli(test,i)
  else
    i+=1
  end
end

for v in all(test) do
  printh(v)
end]]

function editorupdate()
  mousesupport()

  cursor = icarrw

  local x,y = ((editcam+mousepos)\8):unpack()
  local lm = luamap(x,y)
  local f = lm and lm.floors


  for _,v in pairs(editbtn) do
    if (not editbig or v[2] < 8) and isvecinrect(mousepos,unpack(v)) then
      cursor = icfngr
      if (mbtnp(0)) v[6]()
      break
    end
  end

  if mousepos.y < 8 then
  elseif mbtn(2) then -- grab and pan scene
    editcam -= getrelmouse()
    cursor = icgrab
  elseif isvalbetween(mousepos.y,86,95) and not editbig then -- select spritesheet
    if mousepos.x > 95 then
      cursor = icfngr
      if (mbtnp(0)) edittab = (mousepos.x-96)\8
    end
  elseif mousepos.y > 95 and not editbig then -- select sprite
    if (mbtnp(0)) editspr = edittab*64 + mousepos.x\8 + (mousepos.y-96)\8*16
  elseif editmod == 1 then
    if mbtn(0) and editmod == 1 then -- add or remove floor
      if not f and editspr>=0 then
        lm = lm or {}
        lm.floors = {{cam_z,editspr}}
        luamapset(x,y,lm)
      else
        local insert=1
        for i,v in ipairs(f) do
          if v[1]==cam_z then
            insert = nil
            if editspr < 0 then
              deli(f,i)
              if (#f==0) lm.floors=nil
            else
              v[2] = editspr
            end
            break
          elseif v[1] > cam_z then
            break
          end
          insert = i
        end
        if insert and editspr>=0 then
          add(f,{cam_z,editspr},insert)
        end
      end
    elseif mbtn(1) then -- copy floor
      if (editspr>=0) editspr=-editspr-1
      for v in all(f) do
        if v[1]==cam_z then
          editspr = v[2]
        end
      end
    end
  elseif editmod==2 then -- edit walls
    local gridmouse,lastgridmouse = (editcam + mousepos)/8, (editcam + lastmousepos)/8
    local prvmap,newmap = lastgridmouse\1,gridmouse\1
    if editspr<0 then
      if mbtn(0) then
        local function trydelwall(mx,my)
          local lm=luamap(mx,my)
          if lm and lm.walls then
            local w,i = lm.walls,1
            while i<=#w do
              local v=w[i]
              local a,b = newvector(unpack(v,1,2)),newvector(unpack(v,3,4))
              if isvalbetween(cam_z,unpack(v,5,6)) and segmentstouch(a,b,gridmouse,lastgridmouse) then
                deli(w,i)
              else
                i+=1
              end
            end
            if #w == 0 then
              lm.walls = nil
              lm.solid = nil
            end
          end
        end
        trydelwall(prvmap:unpack())
        if (prvmap~=newmap) trydelwall(newmap:unpack())
      end
    else
      if mbtnp(0) then
        editwls = gridmouse
        editwls.genbyclick = true
      end
      if mbtn(0) then
        if prvmap~=newmap then
          local l=gridmouse-lastgridmouse
          local ls=#l
          l /= ls
          --printh("----------")
          raydda:start(lastgridmouse.x,lastgridmouse.y,l.x,l.y)
          repeat
            local pmx,pmy = raydda.mx,raydda.my
            raydda:next()
            -- add wall here
            local next = newvector(raydda:point())
            if not editwls.editwls.genbyclick then
              local lm = luamap(pmx,pmy) or {}
              lm.walls = lm.walls or {}
              add(lm.walls,{editwls.x,editwls.y,next.x,next.y,0,1,editspr})
              luamapset(pmx,pmy,lm)
            end
            editwls = next
            --printv("wx,wy",editwls.x,editwls.y)
          until raydda.mx==newmap.x and raydda.my==newmap.y or raydda.d >=ls
        end
      else
        editwls = nil
      end
    end
  end

  editbtn.small.on = not editbig
  editbtn.big.on = editbig
  editbtn.tiling.on = editvew==1
  editbtn.raycast.on = editvew==2
  editbtn.draw.on = editspr>=0
  editbtn.del.on = editspr<0
  editbtn.floor.on = editmod==1
  editbtn.wall.on = editmod==2
  cam_z = flr(cam_z*8)/8 - mwhl/8
end

function topdowndepth(d)
  d=cam_z-d
  if (not isvalbetween(d,0,2)) return
  if d==0 then
    pal()
  elseif d<1 then
    pal(fadepal[1])
  else
    pal(fadepal[2])
  end
  return true
end

function grid()
  color(1)
  for i=0,127,8 do
    local x=i+8-editcam.x%8
    local y=i+8-editcam.y%8
    line(x,0,x,127)
    line(0,y,127,y)
  end
end

function editordraw()
  cls()

  if editvew == 2 then
    camera(-64,-64)
    disperscan(draw3Dcell)
  else
    -- grid background
    fillp(0b1010010110100101.11)
    if editmod==1 then
      grid()
      fillp()
    end

    -- floor tiles
    local ex,ey = editcam:unpack()
    camera(ex,ey)
    ex,ey = ex\8,ey\8

    for y=ey,ey+16 do
      for x=ex,ex+16 do
        local sx,sy=x*8,y*8
        local lm=luamap(x,y)
        for v in all(lm and lm.floors) do
          local z,m = unpack(v)
          if topdowndepth(z) then
            spr(m,sx,sy)
          end
        end
      end
    end
    pal()
    fillp(editmod==1 and 0b1010010110100101.1 or 0)
    if editmod==2 then
      camera(0,0)
      grid()
      camera(editcam:unpack())
    end

    -- wall lines
    for y=ey,ey+16 do
      for x=ex,ex+16 do
        local lm=luamap(x,y)
        for v in all(lm and lm.walls) do
          local x1,y1,x2,y2,z1,z2,m = unpack(v)
          if (isvalbetween(cam_z,z1,z2)) line(x1*8,y1*8,x2*8,y2*8,7)
        end
      end
    end

    if (editwls) line(editwls.x*8,editwls.y*8,(mousepos+editcam):unpack())
  end

  fillp()
  camera(0,0)
  pal()
  palt(0,false)

  if not editbig then
    -- spritesheet
    local edittab64=edittab*64
    --rectfill(0,96,127,127,0)
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
    rectfill(0,86,127,95,5)
    --?icrayn,9,87,editspr~=-1 and 7 or 13
    --?icross,20,87,editspr==-1 and 7 or 13
    if editspr>=0 then
      rectfill(79,88,91,94,6)
      local str=tostr(editspr)
      while #str<3 do str="0"..str end
      ?str,80,89,13
      spr(editspr,70,87)
    end
    for i=0,3 do
      local x=96+i*8
      local t = edittab == i
      ?_ENV["ictab"..i],x,88-tonum(t),t and 7 or 6
      line(x,95,x+6,95,t and 6 or 13)
    end
  end

  -- top band
  rectfill(0,0,127,7,8)

  -- edit buttons
  for _,v in pairs(editbtn) do
    if v[2] < 8 or not editbig then
      local x,y,_,_,i = unpack(v)
      ?i,x,y,v.on and 7 or 13
    end
  end
  
  -- info and mouse
  --?"z: "..flr(cam_z).."."..(cam_z%1*8),2,2,7
  ?"z: "..cam_z,25,2,7
  ?cursor,mousepos:unpack()

  palt()
end
