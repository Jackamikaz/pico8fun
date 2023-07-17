pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
cls()

-- adapted from http://lua-users.org/wiki/inheritancetutorial
function newclass(inherits)
 local nc = {}
 nc.__index = nc
 
 if inherits then
  setmetatable(nc,{__index=inherits})
 end
 
 -- return the class object of the instance
 function nc:class()
  return nc
 end

 -- return the super class object of the instance
 function nc:super()
  return inherits
 end

 -- return true if the caller is an instance of theclass
 function nc:isa(theclass)
  local cc = nc

  while cc do
   if cc == theclass then
    return true
   else
    cc = cc:super()
   end
  end

  return false
 end
 
 return nc
end

mother = newclass()
function mother:new()
 return setmetatable({a=1},self)
end

function mother:func()
 print("my a value is "..self.a)
end
function mother:show()
 print("hi i'm mother")
end

daughter = newclass(mother)

function daughter:new()
 local n=self:super():new()
 n.a += 1
 return setmetatable(n,self)
end
function daughter:show()
 print("hi i'm daughter")
end

otherclass = newclass()

val = mother:new()
val:show()
val:func()

val2 = daughter:new()
val2:show()
val2:func()

res = "false"
if val2:isa(mother) then
 res = "true"
end

print("daughter is a mother : "..res)

res = "false"
if val2:isa(otherclass) then
 res = "true"
end
print("daughter is otherclass : "..res)
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
