--vector lib
function newvector(a, b)
  return setmetatable({
    x = a or 0, y = b or 0,
    set=function(_ENV,a, b)
      x = a
      y = b
    end,
    slen=function(_ENV)
      return abs(x * x + y * y)
    end,
    unit=function()
      return self / #self
    end,
    norm=function()
      local len = #self
      self.x /= len
      self.y /= len
    end,
    copy=function(_ENV,r)
      x = r.x
      y = r.y
    end,
    unpack=function(_ENV)
      return x,y
    end,
    flr=function(_ENV)
      return newvector(flr(x),flr(y))
    end
  },{
  __add=function(_ENV,r)
    return newvector(x + r.x, y + r.y)
  end,
  __sub=function(_ENV,r)
    return newvector(x - r.x, y - r.y)
  end,
  __mul=function(_ENV,r)
    return newvector(x * r, y * r)
  end,
  __div=function(_ENV,r)
    return newvector(x / r, y / r)
  end,
  __eq=function(_ENV,r)
    return x == r.x and y == r.y
  end,
  __len=function()
    return sqrt(self:slen())
  end,
  --dot product
  __pow=function(_ENV,r)
    return x * r.x + y * r.y
  end,
  __index = _ENV
  })
end