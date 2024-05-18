table.empty = function(tbl)
	if tbl == nil then return true end
	return next(tbl) == nil
	--if #tbl > 0 then return false end
	--for k,v in pairs(tbl) do return false end
	--return true
end
function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local newObject = {}
        lookup_table[object] = newObject
        for key, value in pairs(object) do
            newObject[_copy(key)] = _copy(value)
        end
        return setmetatable(newObject, getmetatable(object))
    end
    return _copy(object)
end
-- 深拷贝一个table
table.clone = clone
function table.nums(t)
    local count = 0
    for _,_ in pairs(t or {}) do
        count = count + 1
    end
    return count
end

table.count = table.nums

function table.series(tb,tail,fn)
    local s = {}
    if type(tb) == "table" then
        fn = tail
        for k,v in pairs(tb or {}) do
            if fn then
                local tmp = fn(v,k)
                if tmp ~= nil then table.insert(s,tmp) end
            else
                table.insert(s,v)
            end
        end
    elseif type(tb) == "number" then
        if not fn then return s end
        local head = tb
        tail = tail or head
        if type(fn) == "function" then
            local v
            for i = head,tail do
                v = fn(i)
                if v ~= nil then table.insert(s,v) end
            end
        else
            local v = fn
            for _ = head,tail do
                table.insert(s,v)
            end
        end
    end

    return s
end

function table.keys(tb)
    local keys = {}
    for k, _ in pairs(tb or {}) do
        table.insert(keys,k)
    end
    return keys
end

function table.values(tb)
    local values = {}
    for _, v in pairs(tb) do
        values[#values + 1] = v
    end
    return values
end

function table.merge(dest,src,agg)
    local ret = clone(dest or {})

    for k,v in pairs(src or {}) do
        ret[k] = agg and agg(dest[k],v) or v
    end

    return ret
end

function table.merge_x(src,fn,dest)
    local ret = clone(dest or {})

    for k,v in pairs(src or {}) do
        ret[k] = fn and fn(dest[k],v) or v
    end

    return ret
end

function table.mergeto(dest, src, agg)
    dest = dest or {}
    for k, v in pairs(src or {}) do
        dest[k] = agg and agg(dest[k],v) or v
    end
    return dest
end

function table.mergeto_x(src,fn,dest)
    dest = dest or {}
    for k, v in pairs(src or {}) do
        dest[k] = fn and fn(dest[k],v) or v
    end
    return dest
end

function table.merge_tables(tbs,agg)
    local r
    for _,tb in pairs(tbs or {}) do
        if not r then 
            r = clone(tb)
        else 
            table.mergeto(r,tb,agg) 
        end
    end
    return r or {}
end

function table.insertto(dest, src, begin)
    begin = checkint(begin)
    if (not begin) or begin <= 0 then
        begin = #dest + 1
    end

    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end

function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        local v = array[i]
        local is = type(value) == "function" and value(v,i) or value == v
        if is then return i end
    end
    return false
end

function table.find(tb,fn)
    for k,v in pairs(tb) do
        if fn(v,k) then
            return k,v
        end
    end
end

function table.keyof(hashtable, value)
    for k, v in pairs(hashtable or {}) do
        local is = type(value) == "function" and value(v,k) or value == v
        if is then return k end
    end
    return nil
end

function table.removebyvalue(array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table.remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end

function table.map(t,fn)
    if not t or not fn then return {} end

    local ret = {}
    for k,v in pairs(t or {}) do
        local k1,v1 = fn(v,k)
        if k1 then ret[k1] = v1 end
    end

    return ret
end

table.pick = table.map

function table.ref_map(t, fn)
    for k, v in pairs(t or {}) do
        t[k] = fn(v, k)
    end
end

function table.group(t,fn)
    local g = {}
    for k,v in pairs(t or {}) do
        local x = fn(v,k)
        g[x] = g[x]  or {}
        g[x][k] = v
    end
    return g
end

function table.walk(t, fn,on)
    for k,v in pairs(t or {}) do
        if not on or on(v,k) then fn(v, k) end
    end
end

function table.filter(t, fn)
    for k, v in pairs(t or {}) do
        if fn and not fn(v, k) then t[k] = nil end
    end
end

function table.select(t,fn,serial)
    local tb = {}

    for k,v in pairs(t or {}) do
        local v = (fn and fn(v,k)) and v  or nil
        if serial then
            if v then table.insert(tb,v) end
        else
            tb[k] = v
        end 
    end

    return tb
end

function table.unique_value(t)
    if not t then return {} end

    local check = {}
    local n = {}
    for k, v in pairs(t) do
        if not check[v] then
            n[k] = v
            check[v] = true
        end
    end
    return n
end

function table.unique(t, bArray)
    local check = {}
    local n = {}
    local idx = 1
    for k, v in pairs(t) do
        if not check[v] then
            if bArray then
                n[idx] = v
                idx = idx + 1
            else
                n[k] = v
            end
            check[v] = true
        end
    end
    return n
end

function table.choice(t)
    assert(type(t) == "table")
    local len = table.nums(t)
    if len == 0 then
        return nil
    end
    local i = math.random(len)
    local index = 1
    for k,v in pairs(t) do
        if index == i then
            return k,v
        end

        index = index + 1
    end
    return nil
end

function table.merge_back(dst,tb,func)
    for _,v in pairs(tb or {}) do 
        table.insert(dst,(func and func(v) or v))
    end
	return dst
end

function table.push_back(dst,v)
	table.insert(dst,v)
end

function table.union(dst,src,agg)
    dst = dst or {}

    local tb = {}
    for k,v in pairs(dst or {}) do
        table.insert(tb,agg and agg(v,k) or v)
    end

    for k,v in pairs(src or {}) do
        table.insert(tb,agg and agg(v,k) or v)
    end
    return tb
end

function table.unionto(dst,src,agg)
    dst = dst or {}

    for k,v in pairs(src or {}) do
        table.insert(dst,agg and agg(v,k) or v)
    end

    return dst
end

function table.union_tables(tbs,agg)
    local t = {}

    for _,tb in pairs(tbs or {}) do
            table.unionto(t,tb,agg)
    end

    return t
end

function table.flatten(tbs,agg)
    local t = {}
    for _,tb in pairs(tbs or {}) do
        for k,v in pairs(tb) do
            if agg then
                table.insert(t,agg(v,k))
            else
                table.insert(t,v)
            end
        end
    end

    return t
end

function table.fold(l,fn)
    local t = {}
    local k,v
    for i = 1,#l,2 do
        if fn then
            k,v = fn(l[i + 1],l[i])
        else
            k,v = l[i],l[i + 1]
        end
        t[k] = v
    end
    return t
end

function table.fold_into(l,tb,fn)
    tb = tb or {}
    l = l or {}

    local k,v
    for i = 1,#l,2 do
        if fn then
            k,v = fn(l[i + 1],l[i])
        else
            k,v = l[i],l[i + 1]
        end
        tb[k] = v
    end

    return tb
end

function table.expand(tb,fn)
    local t = {}
    for k,v in pairs(tb or {}) do
        if fn then
            k,v = fn(v,k)
        end
        table.insert(t,k)
        table.insert(t,v)
    end
    return t
end

function table.pop_back(tb)
	local ret = tb[#tb]
	table.remove(tb)
	return ret
end

function table.slice(tb,head,trail)
    if not trail then trail = #tb end
	if head > trail then return nil end
    if head == trail then return tb[head] end
    
	local vals = {}
	for i = head,trail do table.insert(vals,tb[i]) end
	return vals
end

function table.incr(tb,key,v)
    tb[key] = tb[key] or 0
    local value = tb[key] + (v or 1)
	tb[key] = value
	return value
end

function table.decr(tb,key,v)
    tb[key] = tb[key] or 0
    local value = tb[key] - (v or 1)
	tb[key] = value
	return value
end

function table.fill(tb,value,head,tail)
	head	= head or 1
	tail	= tail or head
    tb		= tb or {}
    if type(value) == "function" then
        for i = head,tail do 
            tb[i] = value(i)
        end
    else
        for i = head,tail do
            tb[i] = value
        end
    end
	return tb
end

function table.sum(tb,agg)
    local value = 0
    for k,v in pairs(tb or {}) do
        value = value + (agg and agg(v,k) or tonumber(v))
    end

    return value
end

function table.min(tb,agg)
    local mini,minv
    for i,v in pairs(tb or {}) do
        local aggv = agg and agg(v,i) or v
        if not minv or aggv < minv then
            minv = aggv
            mini = i
        end
    end
    return mini,minv
end

function table.max(tb,agg)
    local maxi,maxv
    for i,v in pairs(tb or {}) do
        local aggv = agg and agg(v,i) or v
        if not maxv or aggv > maxv then
            maxv = aggv
            maxi = i
        end
    end
    return maxi,maxv
end

function table.logic_and(tb,agg)
    for k,v in pairs(tb or {}) do
        if not agg(v,k) then return false end
    end

    return true
end

table.And = table.logic_and

function table.logic_or(tb,agg)
    for k,v in pairs(tb or {}) do
        if agg(v,k) then return true end
    end

    return false
end

table.Or = table.logic_or

function table.foreach(tb,op,on)
    for k,v in pairs(tb or {}) do
        if not on or on(v,k) then op(v,k) end
    end
end

function table.agg(tb,init,agg_op)
    local ret = init or {}
    for k,v in pairs(tb or {}) do ret = agg_op(ret,v,k) end
    return ret
end

function table.agg1(tb,fn,init)
    local ret = init or {}
    for k,v in pairs(tb or {}) do ret = fn(ret,v,k) end
    return ret
end

function table.ref_broadcast(tb,func)
    for k,v in pairs(tb or {}) do 
        tb[k] = func(v,k)
    end
end

function table.broadcast(tb,func)
    local r = {}
    for k,v in pairs(tb or {}) do r[k] = func(v,k) end
    return r
end

function table.get(tb,field,default)
    if not tb[field] then
        tb[field] = default
    end

    return tb[field]
end

function table.join(left,right,on,join_type,prefix)
    prefix = prefix or "r"
    join_type = join_type or "inner"

    local function merge_with_prefix(l,r,pre)
        pre = pre or "r"
        local tb = clone(l)
        for k,v in pairs(r) do
            k = not tb[k] and k or pre .. "_".. k
            tb[k] = v
        end
        return tb
    end
    local join_func = {
        left = function()
            local res = {}
            for _,lr in pairs(left) do
                local row
                for _,rr in pairs(right) do
                    if on(lr,rr) then
                        row = merge_with_prefix(lr,rr,prefix)
                    end
                end
                table.insert(res,row or lr)
            end

            return res
        end,
        right = function()
            local res = {}
            for _,rr in pairs(right) do
                local row
                for _,lr in pairs(left) do
                    if on(lr,rr) then
                        row = merge_with_prefix(lr,rr,prefix)
                    end
                end
                if not row then
                    table.insert(res,table.map(rr,function(v,k) return prefix .. "_".. k,v end))
                else
                    table.insert(res,row)
                end
            end

            return res
        end,
        inner = function()
            local res = {}
            for _,lr in pairs(left) do
                local row
                for _,rr in pairs(right) do
                    if on(lr,rr) then
                        row = merge_with_prefix(lr,rr,prefix)
                    end
                end
                if row then
                    table.insert(res,row)
                end
            end

            return res
        end
    }
    
    return join_func[join_type]()
end

function table.reverse(tb)
    local ret = {}
    for j = #tb,1,-1 do
        table.insert(ret,tb[j])
    end
    return ret
end

function table.intersect(left,right,on)
    local inter = {}
    for _,l in pairs(left) do
        for _,r in pairs(right) do
            if on(l,r) then
                table.insert(inter,l)
            end
        end
    end
    return inter
end

function table.extract(tb,field)
    return table.series(tb,function(v) return v[field] end)
end

function table.tostring(tb)
    return string.format("{%s}",table.concat(tb,","))
end


string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

function string.htmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, k, v)
    end
    return input
end

function string.restorehtmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, v, k)
    end
    return input
end

function string.nl2br(input)
    return string.gsub(input, "\n", "<br />")
end

function string.text2html(input)
    input = string.gsub(input, "\t", "    ")
    input = string.htmlspecialchars(input)
    input = string.gsub(input, " ", "&nbsp;")
    input = string.nl2br(input)
    return input
end

function string.split(input, fetcher)
    if not fetcher or fetcher == '' then 
        return nil 
    end

    local next = string.gmatch(input,fetcher)
    local ss = {}
    local s = next()
    while s do
        table.insert(ss,s)
        s = next()
    end
    return ss
end

function string.ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end

function string.rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.ucfirst(input)
    return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

function string.urlencode(input)
    -- input = string.gsub(tostring(input), "\n", "\r\n")

    input = string.gsub(input, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    -- input = string.gsub(input, " ", "+")
    -- convert spaces to "+" symbols
    return input
end

function string.urldecode(input)
    input = string.gsub (input, "+", " ")
    input = string.gsub (input, "%%(%x%x)", function(h) return string.char(checknumber(h,16)) end)
    input = string.gsub (input, "\r\n", "\n")
    return input
end

function string.utf8len(input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

function string.formatnumberthousands(num)
    local formatted = tostring(checknumber(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

function string.eval(str)
    return assert(load(str))()
end
