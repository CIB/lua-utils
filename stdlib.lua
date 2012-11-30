-- Various tools are contained in this file which are needed in most lua projects.

-- ============================================================================================
-- GENERIC
-- ============================================================================================

-----------------------------------------------------------------------------------------------
-- loadLibrary
-----------------------------------------------------------------------------------------------
function loadLibrary(libName)
   local lib = package.loadlib(libName, "luaopen_"..libName)
   if not lib then local lib = package.loadlib(libName..".dll","luaopen_"..libName) end
   if not lib then local lib = package.loadlib(libName..".so", "luaopen_"..libName) end
   if not lib then error("Lib not found: "..libName) end
   lib()
end


-----------------------------------------------------------------------------------------------
-- deepcopy
-----------------------------------------------------------------------------------------------
function deepcopy(object)
  local lookup_table = {}

  local function _copy(object)
    if type(object) ~= "table" then
       return object
    elseif lookup_table[object] then
       return lookup_table[object]
    end

    local new_table = {}
    lookup_table[object] = new_table
    for index, value in pairs(object) do
        new_table[_copy(index)] = _copy(value)
    end
    return setmetatable(new_table, _copy(getmetatable(object)) )
  end

  return _copy(object)
end
clone = deepcopy


-----------------------------------------------------------------------------------------------
-- check (alternative to assert)
-----------------------------------------------------------------------------------------------
function check(cond, ...)
  if not cond then 
     local strList = {...}
     if #strList == 0
     then error("Check failed. See stacktrace.")
     else error( concat({...}) )
     end
  end
  return true
end


-----------------------------------------------------------------------------------------------
-- automatic detailed stacktrace
-----------------------------------------------------------------------------------------------
function print_stack_trace(errobj)
  -- First sum up the error
  local errStr = tostring(errobj) or ""
  print("Error: "..errStr)

  -- Now print a detailed stack trace
  local i = 2
  while true do
    -- extract the function name
    local info = debug.getinfo(i)
    
    -- make sure there's still something to examine
    if not info then break end

    if not info.name then info.name = "Unknown" end

    -- print the function name
    print("["..tostring(i-1).."] "..tostring(info.name))

    -- print the function args/locals
    local arg_index = 1
    while true do
      local name, value = debug.getlocal(i,arg_index)
      if not name then break end

      if name ~= "(*temporary)" then
        print("\t"..tostring(name).."="..tostring(value))
      end
      arg_index = arg_index + 1
    end

    i = i + 1
  end
end
debug.traceback = print_stack_trace


-- ============================================================================================
-- TYPING
-- ============================================================================================

-----------------------------------------------------------------------------------------------
-- reqArgs
-----------------------------------------------------------------------------------------------
function reqArgs(numArgs, ...)
  local args = {...}
  if #args ~= numArgs then
     local missingArgs = {}
     for idx=1, numArgs, 1 do
         if args[idx] == nil then table.insert(missingArgs, idx) end
     end
     error("The following args are missing: "..table.concat(missingArgs,", "))
  end
end


-----------------------------------------------------------------------------------------------
-- isType
-----------------------------------------------------------------------------------------------
function isType(obj,reqType)
  local typ = type(obj)
  local success = false
  if reqType == "integer"
  then success = typ == "number" and math.floor(obj) == obj
  else success = typ == reqType
  end
  return success
end


-----------------------------------------------------------------------------------------------
-- typeCheck (alias checkType)
-----------------------------------------------------------------------------------------------
function typeCheck(obj,...)
  local success = false
  for idx,typ in ipairs({...}) do if isType(obj,typ) then success = true end end
  if not success then error("Invalid type: "..type(obj)) end
end
checkType = typeCheck


-----------------------------------------------------------------------------------------------
-- type conversions
-----------------------------------------------------------------------------------------------
function tobool(bool)
  return not not bool
end
toBool = tobool

function tointeger(num)
  return math.floor(tonumber(num))
end
toInteger = tointeger
toInt     = tointeger

toNumber  = tonumber
toNum     = tonumber

toString  = tostring
toStr     = tostring


-- ============================================================================================
-- TABLES & STRINGS
-- ============================================================================================

-----------------------------------------------------------------------------------------------
-- push and pop
-----------------------------------------------------------------------------------------------
table.push = table.insert
table.pop  = table.remove
push       = table.insert
pop        = table.remove


-----------------------------------------------------------------------------------------------
-- hasKey
-----------------------------------------------------------------------------------------------
function table.hasKey(tab, reqKey)
  if reqKey == nil then error("Passed key is nil") end
  return tab[reqKey] ~= nil
end
hasKey = table.hasKey

-----------------------------------------------------------------------------------------------
-- hasVal
-----------------------------------------------------------------------------------------------
function table.hasVal(tab, reqVal)
  if reqVal == nil then error("Passed value is nil") end
  local success = false
  for key,val in pairs(tab) do 
      if val == reqVal then success = true; break end 
  end
  return success
end
hasVal = table.hasVal


-----------------------------------------------------------------------------------------------
-- keysToVals
-----------------------------------------------------------------------------------------------
function table.keysToVals(tab)
  local newTab = {}
  for key,val in pairs(tab) do push(newTab, key) end
  return newTab
end
keysToVals = table.keysToVals


-----------------------------------------------------------------------------------------------
-- valsToKeys
-----------------------------------------------------------------------------------------------
function table.valsToKeys(tab)
  local newTab = {}
  for key,val in pairs(tab) do newTab[val] = true end
  return newTab
end
valsToKeys = table.valsToKeys


-----------------------------------------------------------------------------------------------
-- hasAllVals
-----------------------------------------------------------------------------------------------
function table.hasAllVals(tab, ...)
  local count       = 0
  local targetCount = #{...}
  local valTab      = valsToKeys({...})
  for key,val in pairs(tab) do 
      if valTab[val] ~= nil then count = count +1 end 
  end
  return count == targetCount
end
hasAllVals = table.hasAllVals


-----------------------------------------------------------------------------------------------
-- merge
-----------------------------------------------------------------------------------------------
function table.merge(...)
  local newtab = {}
  for key,val in ipairs({...}) do
    for subkey,subval in pairs(val) do newtab[subkey] = subval end
  end
  return newtab
end
merge = table.merge


-----------------------------------------------------------------------------------------------
-- length
-----------------------------------------------------------------------------------------------
function length(obj)
  local objType = type(obj)
  local len     = 0

  if     objType == "table"  then for idx,val in pairs(obj) do len = len +1 end
  elseif objType == "string" then len = #obj
  else   error("Invalid type to length-func: "..objType)
  end
  return len
end


-----------------------------------------------------------------------------------------------
-- concat
-----------------------------------------------------------------------------------------------
function concat(...)
  local strList = {}
  for idx,val in ipairs({...}) do
    if type(val) == "table"
    then table.insert(strList, concat_helper(val))
    else table.insert(strList, val)
    end
  end
  return table.concat(strList)
end
function concat_helper(obj)
    local list = {}
    for idx=1, #obj do list[idx] = concat(obj[idx]) end
    return table.concat(list)
end


-----------------------------------------------------------------------------------------------
-- trim
-----------------------------------------------------------------------------------------------
function string.trim(str)
 local pos = str:find("%S")
 return pos and str:match(".*%S", pos) or ""
end
trim = string.trim


-----------------------------------------------------------------------------------------------
-- splitLines()
-----------------------------------------------------------------------------------------------
function string.splitLines(text)
  local lines = {}
  if text ~= "" then
     for line in text:gmatch("[^\r\n]+") do table.insert(lines, line) end
  end
  return lines
end
splitLines = string.splitLines


-----------------------------------------------------------------------------------------------
-- wordWrap()
-----------------------------------------------------------------------------------------------
function string.wordWrap(text, width)
  local lines = splitLines(text)

  for idx, text in ipairs(lines) do
    width = width or 64
    local lstart = 1, #text
    local len    = #text
    while len - lstart > width do
      local i = lstart + width
      while i > lstart and string.sub(text, i, i) ~= " " do i = i - 1 end
      local j = i
      while j > lstart and string.sub(text, j, j) == " " do j = j - 1 end
      text = string.sub(text, 1, j) .. "\n" .. string.sub(text, i + 1, -1)
      local change = 1 - (i - j)
      lstart = j + change
      len = len + change
    end
    lines[idx] = text
  end
  return concat(text,"\n")
end
wordWrap = string.wordWrap


-----------------------------------------------------------------------------------------------
-- subString, upper, lower
-----------------------------------------------------------------------------------------------
string.subString = string.sub
subString        = string.sub
upper            = string.upper
lower            = string.lower



-- ============================================================================================
-- MATHS & BITOPS
-- ============================================================================================

-----------------------------------------------------------------------------------------------
-- isEvenNum
-----------------------------------------------------------------------------------------------
function math.isEvenNum(num)
  typeCheck(num,"integer")
  num = num /2
  return num == math.floor(num)
end
isEvenNum = math.isEvenNum


-----------------------------------------------------------------------------------------------
-- MATH.AVG()  (yes, right, lua has no averaging function >.> )
-----------------------------------------------------------------------------------------------
function math.avg(...)
   local sum   = 0
   local count = 0
   for idx, val in pairs({...}) do
      count = count + 1
      sum   = sum + val
   end
   return sum / count
end


-----------------------------------------------------------------------------------------------
-- clamp
-----------------------------------------------------------------------------------------------
function math.clamp(num, minNum, maxNum) 
  return math.min( math.max(num, minNum), maxNum)
end
clamp = math.clamp


-----------------------------------------------------------------------------------------------
-- isInRange
-----------------------------------------------------------------------------------------------
function math.isInRange(num, minNum, maxNum)
  typeCheck(num,    "number")
  typeCheck(minNum, "number")
  typeCheck(maxNum, "number")
  return num >= minNum and num <= maxNum
end
isInRange = math.isInRange



-- ============================================================================================
-- FILEOPS
-- ============================================================================================

-----------------------------------------------------------------------------------------------
-- fileExists
-----------------------------------------------------------------------------------------------
function fileExists(filePath)
  local file = io.open(filePath,"rb")
  if file then file:close(); return true else return false end
end


-----------------------------------------------------------------------------------------------
-- readFile
-----------------------------------------------------------------------------------------------
function readFile(filePath)
  local err  = "Cannot read file: "..filePath
  local file = assert( io.open(filePath,"rb"), err)
  local data = assert( file:read("*all"), err)
  file:close()
  return data
end


-----------------------------------------------------------------------------------------------
-- writeFile
-----------------------------------------------------------------------------------------------
function writeFile(filePath, data)
  local err  = "Cannot write file: "..filePath
  local file = assert( io.open(filePath,"wb"), err)
  assert(file:write(data), err)
  file:close()
end

-- ============================================================================================
-- PRETTY PRINTING
-- ============================================================================================

--** tostring_pretty
--*@ pretty_string = tostring_pretty(object)
--*? Converts an object to a string in human-readable format.
function tostring_pretty(object)
    if type(object) == "table" then
        local rval = "{"
        for key, value in pairs(object) do
            rval = rval .. tostring(key) .. " = '" .. tostring(value)
            if next(object, key) then
                rval = rval .. "', "
            end
        end
        rval = rval .. "}"
        return rval
    else
        return tostring(object)
    end
end

--** pprint
--*@ pprint(object)
--*? Pretty prints an object in human-readable format.
function pprint(object)
    print(tostring_pretty(object))
end

