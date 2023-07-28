--vector lib
vec = {__index = _ENV}
function vec:new(a, b)
  return setmetatable(
    { x = a or 0, y = b or 0 },
    self
  )
end
function vec:set(_ENV,a, b)
  self.x = a
  self.y = b
end
function vec.__add(_ENV,r)
  return vec:new(x + r.x, y + r.y)
end
function vec.__sub(_ENV,r)
  return vec:new(x - r.x, y - r.y)
end
function vec.__mul(_ENV,r)
  return vec:new(x * r, y * r)
end
function vec.__div(_ENV,r)
  return vec:new(x / r, y / r)
end
function vec.__eq(_ENV,r)
  return x == r.x and y == r.y
end
function vec.slen(_ENV)
  return abs(x * x + y * y)
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
function vec.copy(_ENV,r)
  return vec:new(x, y)
end
--dot product
function vec.__pow(_ENV,r)
  return x * r.x + y * r.y
end