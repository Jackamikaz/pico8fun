--shadow text
function sdprint(str, x, y, col, sdcol)
  print(str, x, y + 1, sdcol or 0)
  print(str, x, y, col or 7)
end

--random palette
function rndpal()
  for i = 1, 15 do
    pal(i, rnd(15) + 1)
  end
end

--add several values to a table
--function append(t,...)
--  for v in all({...}) do
--    add(t,v)
--  end
--end

--quick binary search for adding a value to an ordered table
function addordered(t,v,ordfunc)
  local l,h = 1,#t
  while l <= h do
    local m = l+(h-l)\2
    if ordfunc(t[m],v) then
      l = m+1
    else
      h = m-1
    end
  end
  add(t,v,l)
end

--print names associated with value for lazy devs not wanting to concatenate debug values
function printv(s,...)
  local v = {...}
  local r = ""
  for i,n in ipairs(split(s)) do
    local c=v[i]
    if (type(c)=="boolean") c = c and "true" or "false"
    if (type(c)=="table") c = "{}"
    r = r..n.."="..c.." "
  end
  printh(r)
end
