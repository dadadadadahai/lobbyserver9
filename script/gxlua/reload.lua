
-- local allMs = {}

function Split(str,reps)
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function (w)
        table.insert(resultStrList,w)
    end)
    return resultStrList
end
function import(sModule)
    -- print('sModule',sModule)
    -- local as = Split(sModule,'/')
    -- if #as<=1 then
    --     as = Split(sModule,'\\')
    -- end
    -- local itemname = Split(as[#as],'.')[1]
    allMs[sModule] = 1
    return require(sModule)
    -- if not allMs[sKey] then
    --     allMs[sKey] = require(sModule)
    -- end
    -- return allMs[sKey]
end

function reload(skey)

    -- print('package.loaded[skey]',skey,package.loaded[skey])
    -- package.loaded[skey] = nil
    -- package.loaded[skey] = require(skey)
    -- local sKey = string.gsub(sModule, "/", ".")

    -- local cm = allMs[sKey]
    -- if not cm then
    --     return
    -- end
    -- unilight.info("重载配置:"..sModule)
    -- package.loaded[sModule] = nil
    -- local om = require(sModule) 
    -- local bStatus, sErr = pcall(function ()
    --     local visited = {}
    --     local recu
    --     recu = function (new, old)
    --         if visited[old] then
    --             return
    --         end
    --         visited[old] = true
    --         for k, v in pairs(new) do
    --             local o = old[k]
    --             if type(v) ~= type(o) then
    --                 old[k] = v
    --             else
    --                 if type(v) == "table" then
    --                     recu(v, o)
    --                 else
    --                     old[k] = v
    --                 end
    --             end
    --         end
    --         for k, v in pairs(old) do
    --             if not rawget(new, k) then
    --                 old[k] = nil
    --             end
    --         end
    --     end

    --     for k, v in pairs(om) do
    --         local o = cm[k]
    --         if type(o) == type(v) and type(v) == "table" then
    --             recu(v, o)
    --             om[k] = o
    --         end
    --     end
    -- end)
    
    -- if not bStatus then
    --     unilight.info("reload failed="..sErr)
    --     -- local l = {}
    --     -- for k, v in pairs(om) do
    --     --     if not cm[k] then
    --     --         table.insert(l, k)
    --     --     else
    --     --         om[k] = cm[k]
    --     --     end
    --     -- end
    --     -- for _, k in ipairs(l) do
    --     --     om[k] = nil
    --     -- end
    -- end
end

function reloadall()
    unilight.info("重载所有脚本")
    for key, _ in pairs(allMs) do
        local value = package.loaded[key]
        if value~=nil then
            local oldvalue = value
            package.loaded[key]=  nil
            value = require (key)
            addressClone(oldvalue,value)
            package.loaded[key] = oldvalue
        end
    end
end
function addressClone(oldtable,newtable)
    for key,value in pairs(newtable) do
        oldtable[key] = value
    end
    -- for key,value in pairs(oldtable) do
    --     if newtable[key]==nil then
    --         oldtable[key] = nil
    --     end
    -- end
end