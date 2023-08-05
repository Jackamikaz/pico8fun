--vector lib
function newvector2(a, b)
  return setmetatable({
    x = a or 0, y = b or 0,
    set=function(_ENV,a, b)
      x = a
      y = b
    end,
    --slen=function(_ENV)
    --  return abs(x * x + y * y)
    --end,
    --unit=function(self)
    --  return self / #self
    --end,
    --norm=function(_ENV)
    --  local len = #_ENV
    --  x /= len
    --  y /= len
    --end,
    copy=function(_ENV,r)
      x = r.x
      y = r.y
    end,
    unpack=function(_ENV)
      return x,y
    end,
    --flr=function(_ENV)
    --  return newvector2(flr(x),flr(y))
    --end
  },{
  __add=function(_ENV,r)
    return newvector2(x + r.x, y + r.y)
  end,
  __sub=function(_ENV,r)
    return newvector2(x - r.x, y - r.y)
  end,
  __mul=function(_ENV,r)
    return newvector2(x * r, y * r)
  end,
  __div=function(_ENV,r)
    return newvector2(x / r, y / r)
  end,
  __idiv=function(_ENV,r)
    return newvector2(x \ r, y \ r)
  end,
  __eq=function(_ENV,r)
    return x == r.x and y == r.y
  end,
  --__len=function(_ENV)
  --  return sqrt(slen(_ENV))
  --end,
  --dot product
  --__pow=function(_ENV,r)
  --  return x * r.x + y * r.y
  --end,
  __index = _ENV
  })
end

function newvector3(a, b, c)
  return setmetatable({
    x = a or 0, y = b or 0, z = c or 0,
    set=function(_ENV,a,b,c)
      x = a
      y = b
      z = c
    end,
    slen=function(_ENV)
      return abs(x * x + y * y + z * z)
    end,
    unit=function(self)
      return self / #self
    end,
    --norm=function(_ENV)
    --  local len = #_ENV
    --  x /= len
    --  y /= len
    --  z /= len
    --end,
    --copy=function(_ENV,r)
    --  x = r.x
    --  y = r.y
    --  z = r.z
    --end,
    dup=function(_ENV)
      return newvector3(x,y,z)
    end,
    unpack=function(_ENV)
      return x,y,z
    end,
    --flr=function(_ENV)
    --  return newvector3(flr(x),flr(y),flr(z))
    --end
    str=function(_ENV)
      return "["..x..","..y..","..z.."]"
    end
  },{
  __add=function(_ENV,r)
    return newvector3(x + r.x, y + r.y, z + r.z)
  end,
  __sub=function(_ENV,r)
    return newvector3(x - r.x, y - r.y, z - r.z)
  end,
  __mul=function(_ENV,r)
    return newvector3(x * r, y * r, z * r)
  end,
  __div=function(_ENV,r)
    return newvector3(x / r, y / r, z / r)
  end,
  __idiv=function(_ENV,r)
    return newvector3(x \ r, y \ r, z \ r)
  end,
  __eq=function(_ENV,r)
    return x == r.x and y == r.y and z == r.z
  end,
  __len=function(_ENV)
    return sqrt(slen(_ENV))
  end,
  --dot product
  __pow=function(_ENV,r)
    return x * r.x + y * r.y + z * r.z
  end,
  --cross product
  __and=function(_ENV,r)
    return newvector3(y*r.z - z*r.y, z*r.x - x*r.z, x*r.y - y*r.x)
  end,
  __index = _ENV
  })
end