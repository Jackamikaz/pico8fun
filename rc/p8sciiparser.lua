function escbin(s)
  local out=""
  for i=1,#s do
   local c  = sub(s,i,i)
   local nc = ord(s,i+1)
   local pr = (nc and nc>=48 and nc<=57) and "00" or ""
   local v=c
   if(c=="\"") v="\\\""
   if(c=="\\") v="\\\\"
   if(ord(c)==0) v="\\"..pr.."0"
   if(ord(c)==10) v="\\n"
   if(ord(c)==13) v="\\r"
   out..= v
  end
  return out
 end

function sprtop8scii(spr)
  t={}
  for i=1,15 do add(t,{}) end

  local sx,sy = (spr*8)%128,spr\16*8
  for y=0,7 do
    for i=1,15 do t[i][y+1] = 0 end
    for x=0,7 do
      local c=sget(sx+x,sy+y)
      if c~= 0 then
        t[c].use=true
        t[c][y+1] |= 1<<x
      end
    end
  end

  local str=""
  local notfirst
  for i=1,15 do
    local tc = t[i]
    local c=i
    if (c>=10) c = chr(c+87) --c+ord('a')-10
    if tc.use then
      if (notfirst) str ..="⁸"
      notfirst = true
      str ..= "ᶜ"..c.."⁶."..chr(unpack(tc))
    end
  end

  return str
end
