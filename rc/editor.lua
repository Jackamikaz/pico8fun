editcam = newvector2()
edittab = 0
editspr = 0
editbig = false
editwlh = 1
editmod = 1 -- 1 for floors, 2 for walls, 3 for chunks
editvew = 1 -- 1 for tile view, 2 for gridcasting

--[[
local str=""
for s=48,49 do
  str ..= "\""..escbin(sprtop8scii(s)).."\"\r"
end
printh(str,"@clip")--]]
icarrw = "ᶜ1⁶.²⁵\9■!」◀\0⁸ᶜ7⁶.\0²⁶ᵉ゛⁶⁸\0"
icgrab = "ᶜ1⁶.⁘*CAB<\0\0⁸ᶜ7⁶.\0T<><\0\0\0"
icfngr = "³eᶜ1⁶.⁴\10\10+BAB<⁸ᶜ7⁶.\0⁴⁴T=><\0"
icrszv = "ᶜ1⁶.⁴\n■\0■\n⁴\0⁸ᶜ6⁶.\0\0ᵉ\0ᵉ\0\0\0⁸ᶜ7⁶.\0⁴\0\0\0⁴\0\0"
icrszh = "ᶜ1⁶.⁘\"A\"⁘\0\0\0⁸ᶜ6⁶.\0⁘⁘⁘\0\0\0\0⁸ᶜ7⁶.\0\0\"\0\0\0\0\0"

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

addeditbtn("small",5,1,icsprs,function() editbig=false refreshtopbottom() end)
addeditbtn("big",13,1,icexpd,function() editbig=true refreshtopbottom() end)
addeditbtn("tiling",108,1,ictiln,function() editvew=1 end)
addeditbtn("raycast",116,1,icrcst,function() editvew=2 end)
addeditbtn("draw",5,88,icrayn,function() if (editspr<0) editspr=-editspr-1 end)
addeditbtn("del",14,88,icross,function() if (editspr>=0) editspr=-editspr-1 end)
addeditbtn("floor",35,88,icflor,function() editmod=1 end)
addeditbtn("wall",44,88,icwall,function() if editmod==2 then editmod=3 else editmod=2 end end)

function refreshtopbottom()
  disp_top = -56
  disp_bottom = editbig and 64 or 22
end

function editorenter()
  refreshtopbottom()
  cam_z-=0.5
end

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

  if changingwallheight then
    cursor = icrszh
    editwlh = max((mousepos.x-changingwallheight)*4\8/8,0.125)
    changingwallheight = mbtn(0) and changingwallheight
  elseif mousepos.y <= 8 then
    if isvalbetween(mousepos.x,64,100) then
      cursor = icfngr
      changingwallheight = mbtnp(0) and mousepos.x - editwlh*16
    end
  elseif mousepos.y <= (editbig and 128 or 85) then
    if editvew==1 then
      if mbtn(2) then -- grab and pan scene
        editcam -= getrelmouse()
        cursor = icgrab
      end

      if editmod == 1 then
        if mbtn(0) then -- add or remove floor
          if not f and editspr>=0 then
            lm = lm or {}
            lm.floors = {{cam_z,editspr}}
            luamapset(x,y,lm)
          else
            local insert=0
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
              add(f,{cam_z,editspr},insert+1)
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
                  local a,b = newvector2(unpack(v,1,2)),newvector2(unpack(v,3,4))
                  if isvalbetween(cam_z,unpack(v,5,6)) and segmentstouch(a,b,gridmouse,lastgridmouse) then
                    deli(w,i)
                  else
                    i+=1
                  end
                end
                if #w == 0 then
                  lm.walls = nil
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
              raydda:start(lastgridmouse.x,lastgridmouse.y,l.x,l.y)
              repeat
                local pmx,pmy = raydda.mx,raydda.my
                raydda:next()
                -- add wall here
                local next = newvector2(raydda:point())
                if not editwls.editwls.genbyclick then
                  local lm = luamap(pmx,pmy) or {}
                  lm.walls = lm.walls or {}
                  add(lm.walls,{editwls.x,editwls.y,next.x,next.y,cam_z,cam_z+editwlh,editspr})
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
      elseif editmod==3 then --chunk mode
        if mbtn(0) then
          local wt = cam_z+editwlh
          local lmc,nc=lm and lm.chunks,{cam_z,wt,editspr}
          for i,chk in ipairs(lmc) do
            if (overlap(chk[1],chk[2],cam_z,wt)) deli(lmc,i) break
          end
          local adding = editspr>=0
          local deltng = not adding
          if adding then
            if (not lmc) lmc={}
            add(lmc,nc)
          elseif lmc and #lmc==0 then
            lmc=nil
          end
          local function adjustchunk(x,y,side)
            local lm2,opsd = luamap(x,y),(side+2)%4+4
            side+=4
            nc[side] = true
            for ac in all(lm2 and lm2.chunks) do
              local z1,z2 = ac[1],ac[2]
              if cam_z==z1 and wt==z2 then
                nc[side] = deltng
                ac[opsd] = deltng
              elseif cam_z <= z1 and wt >= z2 then
                ac[opsd] = deltng
              elseif cam_z >= z1 and wt <= z2 then
                nc[side] = deltng
                ac[opsd] = adding
              end
            end
          end
          adjustchunk(x+1,y,0)
          adjustchunk(x,y-1,1)
          adjustchunk(x-1,y,2)
          adjustchunk(x,y+1,3)
          if (not lm) lm={}
          lm.chunks = lmc
          luamapset(x,y,lm)
        end
      end
    else
      if mbtn(2) then
        local relm = getrelmouse()/8
        setcamdir(cam_dir+relm.x/16)
        cam_x += cam_dircos*relm.y
        cam_y += cam_dirsin*relm.y
      end
      if (mbtn(0) or mbtn(1)) and editspr >= 0 then
        local raystart = newvector3(cam_x,cam_y,cam_z)
        local rx,ry = worldtocam(cam_x+(mousepos.x-64)/64,cam_y+projplanedist/64)
        local raydir = newvector3(rx,ry,-(mousepos.y-64)/64):unit()
        rx, ry = raydir.x, raydir.y
        raydda:start(raystart.x,raystart.y,raydir.x,raydir.y)
        local dist = 0
        while dist < cam_far do
          raydda:next()
          dist = raydda.d
          local function colfloor(x,y,z,s,f)
            if (dist>=cam_far) return
            local a = newvector3(x,y,z)
            local b = a:dup() b.x += 1
            local c = b:dup() c.y += 1
            local d = a:dup() d.y += 1
            if ray3Dsquareintersection(raystart,raydir,a,b,c,d) then
              if (mbtn(0)) f[2] = editspr else editspr = f[2]
              dist = cam_far
            end
          end
          local function colwall(x1, y1, x2, y2, z1, z2, sp, w)
            if (dist>=cam_far) return
            x1, y1, x2, y2, z1, z2, sp = unpack(w)
            local a,b,c,d = newvector3(x1,y1,z1),newvector3(x2,y2,z1),newvector3(x2,y2,z2),newvector3(x1,y1,z2)
            if ray3Dsquareintersection(raystart,raydir,a,b,c,d) then
              if (mbtn(0)) w[7] = editspr else editspr = w[7]
              dist = cam_far
            end
          end
          local function ordhandlercol(ord)
            for i=#ord,1,-1 do
              local p = ord[i]; --next line won't work without this semicolon!
              (p[2]==1 and colfloor or colwall)(unpack(p,3))
            end
          end
          traverse3Dcell(raydda.mx,raydda.my,ordhandlercol)
        end
      end
    end
  elseif mousepos.y>85 and not editbig then
    if mousepos.y < 96 then -- select spritesheet
      if mousepos.x > 95 then
        cursor = icfngr
        if (mbtnp(0)) edittab = (mousepos.x-96)\8
      end
    else
      if (mbtnp(0)) editspr = edittab*64 + mousepos.x\8 + (mousepos.y-96)\8*16
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
  editbtn.wall.col = editmod==3 and 12
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
    disperscan(traverse3Dcell,ordhandlerdraw)
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
    if editmod>=2 then
      camera(0,0)
      grid()
      camera(editcam:unpack())
    end

    -- wall lines
    for y=ey,ey+16 do
      for x=ex,ex+16 do
        local lm=luamap(x,y)
          if lm then
          for v in all(lm.walls) do
            local x1,y1,x2,y2,z1,z2,m = unpack(v)
            if (isvalbetween(cam_z,z1,z2)) line(x1*8,y1*8,x2*8,y2*8,7)
          end
          for c in all(lm.chunks) do
            local z1,z2,s,a,b,c,d = unpack(c)
            if isvalbetween(cam_z,z1,z2) then
              local xl,xr,yt,yb = x*8,x*8+7,y*8,y*8+7
              color(12)
              if (a) line(xr,yb,xr,yt)
              if (b) line(xr,yt,xl,yt)
              if (c) line(xl,yt,xl,yb)
              if (d) line(xl,yb,xr,yb)
            end
          end
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
      ?i,x,y,v.on and 7 or v.col or 13
    end
  end
  
  -- info and mouse
  --?"z: "..flr(cam_z).."."..(cam_z%1*8),2,2,7
  ?"z:"..cam_z,25,2,7
  ?"w:"..editwlh,66,2,7
  ?cursor,mousepos:unpack()

  palt()
end
