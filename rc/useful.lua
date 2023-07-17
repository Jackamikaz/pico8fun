--shadow text
function sdprint(str,x,y,col,sdcol)
print(str,x,y+1,sdcol or 0)
print(str,x,y,col or 7)
end

--random palette
function rndpal()
for i=1,15 do
pal(i,rnd(15)+1)
end
end

--add and square
function sqr(a)
return a*a
end
function addandsqr(a,b)
return sqr(a+b)
end

--sign
function sign(a)
if a<0 then
return -1
elseif a>0 then
return 1
else
return 0
end
end

--new class function
--adapted from http://lua-users.org/wiki/inheritancetutorial
function newclass(inherits)
local nc = {}
nc.__index = nc

if inherits then
setmetatable(nc,{__index=inherits})
end

--return the class object
--of the instance
function nc:class()
return nc
end

--return the super class object
--of the instance
function nc:super()
return inherits
end

--return true if the caller is
--an instance of theclass
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

--vector lib
vec = newclass()
function vec:new(a,b)
return setmetatable(
{x=a or 0,y=b or 0},
self)
end
function vec:set(a,b)
self.x=a
self.y=b
end
function vec:__add(r)
return vec:new(self.x+r.x,self.y+r.y)
end
function vec:__sub(r)
return vec:new(self.x-r.x,self.y-r.y)
end
function vec:__mul(r)
return vec:new(self.x*r,self.y*r)
end
function vec:__div(r)
return vec:new(self.x/r,self.y/r)
end
function vec:__eq(r)
return self.x == r.x and self.y == r.y
end
function vec:slen()
return abs(self.x*self.x+self.y*self.y)
end
function vec:__len()
return sqrt(self:slen())
end
function vec:unit()
return self / #self
end
function vec:norm()
local len = #self
self.x /= len
self.y /= len
end
function vec:copy(r)
return vec:new(self.x, self.y)
end
--dot product
function vec:__pow(r)
return self.x*r.x + self.y*r.y
end

--linked list
lklist = newclass()
function lklist:new()
local n = setmetatable({},self)
n.last = n
return n
end
function lklist:addval(value)
local n = {val=value}
self.last.nxt = n
self.last = n
end
function lklist:start()
self.current = self
return self:next()
end
function lklist:next()
self.previous = self.current
self.current = self.current.nxt 
if self.current then
return self.current.val
else
return nil
end
end
function lklist:removecurrent()
self.previous.nxt = self.current.nxt
self.current = self.previous
if not self.current.nxt then
self.last = self.current
end
end
function lklist:clear()
self.nxt = nil
self.last = self
end
function lklist:isempty()
return self.nxt==nil
end