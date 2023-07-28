--new class function
--adapted from http://lua-users.org/wiki/inheritancetutorial
function newclass(inherits)
  local nc = {}
  nc.__index = nc

  if inherits then
    setmetatable(nc, { __index = inherits })
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

--linked list
lklist = newclass()
function lklist:new()
  local n = setmetatable({}, self)
  n.last = n
  return n
end
function lklist:addval(value)
  local n = { val = value }
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
  return self.nxt == nil
end