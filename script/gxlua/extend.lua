-- 通用lua扩充函数，与任何游戏逻辑无关

-- from http://snippets.luacode.org/?p=snippets/String_to_Hex_String_68
string.tohex = function(str, spacer)
	return  string.gsub(str,"(.)", function (c) return string.format("%02X%s", string.byte(c), spacer or "") end)
end

string.trim = function(str)
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end
string.trimbegin = function(str)
	return string.gsub(str, "^%s*(.-)$", "%1")
end
string.trimend = function(str)
	return string.gsub(str, "^(.-)%s*$", "%1")
end

string.padleft = function(str, totalWidth, paddingChar)
	local len = #str
	if len >= totalWidth then
		return str
	else
		paddingChar = paddingChar or ' '
		assert(#paddingChar == 1)
		return string.rep(paddingChar, totalWidth - len) .. str
	end
end
string.padright = function(str, totalWidth, paddingChar)
	local len = #str
	if len >= totalWidth then
		return str
	else
		paddingChar = paddingChar or ' '
		assert(#paddingChar == 1)
		return str .. string.rep(paddingChar, totalWidth - len)
	end
end

--[[
desc : 字符串分割
szFullString: 要分割的字符串
szSeparator: 分割符号
--]]
string.split = function(szFullString, szSeparator)
	local FindStartIndex = 1
	local SplitArray = {}
	while true do
		local FindLastIndex = string.find(szFullString, szSeparator, FindStartIndex, true)
		if not FindLastIndex then
			table.insert(SplitArray, string.sub(szFullString, FindStartIndex, string.len(szFullString)))
			break
		end
		table.insert(SplitArray, string.sub(szFullString, FindStartIndex, FindLastIndex-1))
		FindStartIndex = FindLastIndex + string.len(szSeparator)
	end
	return SplitArray
end

--[[
desc:   数据查找
]]
table.find = function(this, value)
	for k,v in pairs(this) do
		if v == value then return k end
	end
    return nil
end


--[[
desc: table清空空数据,值为""或0都会被清空
]]
table.omit = function(tbl)
	for k,v in pairs(tbl) do
		local typ = type(v)
		if typ == "table" then
			v = table.omit(v)
			if v == nil or next(v) == nil then
				tbl[k] = nil
			end
		elseif (typ == "string" and v == "") or (typ == "number" and v == 0)  then
			tbl[k] = nil
		end
	end
	return tbl
end

--转换成字符串
table.tostring = function(data, _indent)
	local visited = {}
	local function dump(data, prefix)
		local str = tostring(data)
		if table.find(visited, data) ~= nil then return str end
		table.insert(visited, data)

		local prefix_next = prefix .. "  "
		str = str .. "\n" .. prefix .. "{"
		for k,v in pairs(data) do
			if type(k) == "number" then
				str = str .. "\n" .. prefix_next .. "[" .. tostring(k) .. "] = "
			else
				str = str .. "\n" .. prefix_next .. tostring(k) .. " = "
			end
			if type(v) == "table" then
				str = str .. dump(v, prefix_next)
			elseif type(v) == "string" then
				str = str .. '"' .. v .. '"'
			else
				str = str .. tostring(v)
			end
		end
		str = str .. "\n" .. prefix .. "}"
		return str
	end
	return dump(data, _indent or "")
end

--合并两个table,必须是map
table.merge = function(base, delta)
	if type(delta) ~= "table" then return end
	for k,v in pairs(delta) do
		base[k] = v
	end
end

--扩展table,必须是数组
table.extend = function(base, delta)
	if type(delta) ~= "table" then return end
	for i,v in ipairs(delta) do
		table.insert(base, v)
	end
end

--求table长度
table.len = function(tbl)
	if type(tbl) ~= "table" then return 0 end
	local n = 0
	for k,v in pairs(tbl) do n = n + 1 end
	return n
end
-- print('table.emptytable.emptytable.emptytable.emptytable.emptytable.emptytable.emptytable.emptytable.empty')
--判断一个table是否为空
table.empty = function(tbl)
	if tbl == nil then return true end
	assert(type(tbl) == "table")
	return next(tbl) == nil
	--if #tbl > 0 then return false end
	--for k,v in pairs(tbl) do return false end
	--return true
end

-- 深拷贝一个table
table.clone = function(t,deepnum)
	if type(t) ~= 'table' then return t end
	local mt = getmetatable(t)
	local res = {}

	if deepnum and deepnum > 0 then
		deepnum = deepnum - 1
	end
	for k,v in pairs(t) do
		if type(v) == 'table' then
			if not deepnum or deepnum > 0 then
				v = table.clone(v, deepnum)
			end
		end
		res[k] = v
	end
	setmetatable(res,mt)
	return res
end

--table切割获得指定范围数据，i1.开始, i2.结束
table.slice = function(values,i1,i2)
	local res = {}
	local n = #values
	i1 = i1 or 1
	i2 = i2 or n
	if i2 < 0 then
		i2 = n + i2 + 1
	elseif i2 > n then
		i2 = n
	end
	if i1 < 1 or i1 > n then
		return {}
	end
	local k = 1
	for i = i1,i2 do
		res[k] = values[i]
		k = k + 1
	end
	return res
end

--table翻转{1,2,3,4}变成{4,3,2,1}
table.reverse = function(tab)
	local size = #tab
	local newTable = {}
	for i,v in ipairs(tab) do
		newTable[size+1-i] = v
	end
	return newTable
end

--table置空
table.reset = function(t)
	for k,v in pairs(t) do
		t[k] = nil
	end
	return t
end

--产生n~n个不随机数, 数量是cnd
math.randomx = function(m,n,cnt)
    if cnt>n-m+1 then
        return {}
    end
    local t = {}
    local tmp = {}
    while cnt>0 do
        local x =math.random(m,n)
        if not tmp[x] then
            t[#t+1]=x
            tmp[x]=1
            cnt=cnt-1
        end
    end
    return t
end
-- math.random({0.7, 0.1, 0.2}, {'A', 'B', 'C'})
math.random = function(m, n)
	if type(m) == "table" and #m == #n then
		-- 标准化概率表
		local sum = 0
		for _,v in ipairs(m) do sum = sum + v end
		local sm = {}
		for k,v in ipairs(m) do sm[k] = v / sum end
		-- 得到下标
		local r = go.rand.Random()
		for k,v in ipairs(sm) do
			if r <= v then return n[k]
			else r = r - v end
		end
		assert(false)
	end
	if m == nil then return go.rand.Random() end
	local _random = function(m, n)
		m, n = math.min(m, n), math.max(m, n)
		local mi, mf = math.modf(m)
		local ni, nf = math.modf(n)
		if mf == 0 and nf == 0 then
			return go.rand.RandBetween(m, n)
		else
			return m + go.rand.Random() * (n - m)
		end
	end
	if n == nil then return _random(1, m) end
	return _random(m, n)
end

-- http://www.cplusplus.com/reference/algorithm/random_shuffle/
-- http://stackoverflow.com/questions/17119804/lua-array-shuffle-not-working
math.shuffle = function(array)
	local counter = #array
	while counter > 1 do
		local index = math.random(counter)
		array[index], array[counter] = array[counter], array[index]
		counter = counter - 1
	end
	return array
end

--按table的key值大小顺序遍历table	e.g. for k, v in pairsByKeys(tab) do print(k, v) end
function pairsByKeys(t)
    local kt = {}
	local len = 0
    for k in pairs(t) do
		len = len + 1
        kt[len] = k
    end

    table.sort(kt)
    
    local i = 0  
    return function()
        i = i + 1  
        return kt[i], t[kt[i]] 
    end  
end

function dump_value_(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end
 
function split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == "") then return false end
    local pos, arr = 0, {}
    for st, sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end
 
function trim(input)
    return (string.gsub(input, "^%s*(.-)%s*$", "%1"))
end
 
--[[
打印table的工具函数
@params value 需要打印的内容
@params desciption 描述
@params nesting 打印内容的嵌套级数，默认3级
]]
function dump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 3 end
 
    local lookupTable = {}
    local result = {}
 
    local traceback = split(debug.traceback("", 2), "\n")
    -- print("dump from: " .. trim(traceback[3]))
 
    local function dump_(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_value_(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, dump_value_(desciption), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, dump_value_(desciption), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, dump_value_(desciption))
            else
                result[#result +1 ] = string.format("%s%s = {", indent, dump_value_(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, desciption, "- ", 1)
 
    for i, line in ipairs(result) do
        unilight.info(line)
    end
end
