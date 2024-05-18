--游戏通用变量定义
module('gamecommon', package.seeall)
local table_stock_tax = import 'table/table_stock_tax'
local table_stock_single = import 'table/table_stock_single'
local table_game_list = import "table/table_game_list"

--定时记录库存记录
function SaveSlotStockLog(isSave)
    -- for k, v in pairs(table_stock_single) do
    --     local curStocknum = gamecommon.GetStockNumByType(v.ID)
    --     if  curStocknum ~= nil then
    --         local data = {
    --             timestamp = os.time(),
    --             gameType = v.gameType,
    --             gameId   = v.gameId,
    --             stockNum = curStocknum,
    --             _id = go.newObjectId()
    --         }
    --         unilight.savedata("slotsStockLog", data)
    --     end
    -- end
end

--初始化库存
function initStockNum()
    -- for k, v in pairs(table_stock_tax) do
    --     local gameKey   = v.gameId * 10000  + v.gameType
    --     local slotsStock = unilight.getdata("slotsStock", gameKey)
    --     --初始化库存
    --     if slotsStock == nil then
    --         local stockConfig = table_stock_tax[gameKey]
    --         if stockConfig == nil then
    --             unilight.error("IncStockNumByType gameType err:"..gameType)
    --             return 0
    --         end
    --         slotsStock = {
    --             _id = gameKey,                        --场次id
    --             gameId   = v.gameId,                    --游戏id
    --             gameType = v.gameType,                         --场次id
    --             -- ZoneId = unilight.getzoneid(),        --zoneId
    --             stockNum = stockConfig.initStock,             --初始库存              
    --         }
    --         unilight.savedata("slotsStock", slotsStock)
    --     end
    -- end
end


--玩家增加奖池日志
function AddUserJackpotLog(gameId, gameType, uid, chips)
    unilight.info(string.format("玩家:%d,增加奖池记录, gameId:%d, gameType:%d,chips:%d", uid, gameId, gameType, chips))
    local data = {
        timestamp = os.time(),
        gameType  = gameType,
        gameId    = gameId,
        chips     = chips,
        _id       = go.newObjectId(),
        uid       = uid,
    }
    unilight.savedata("gameJackpotLog", data)
end

--保存奖池信息到redis
function SaveSlotsPoolInfoToRedis()
    local datas = {}
    for gameKey, gameConfig in pairs(table_game_list) do
        if gameConfig.isOpen == 1 then
            if IsCustomServer(gameConfig.subGameId , gameConfig.roomType) then
                if gameConfig.poolType == 1 then
                    local poolConfig = GetPoolConfig(gameConfig.subGameId, gameConfig.roomType)
                    if poolConfig ~= nil then
                        table.insert(datas, poolConfig)
                    end
                elseif gameConfig.poolType == 3 then
                    local poolLen = GetPoolLen(gameConfig.subGameId, gameConfig.roomType)
                    for poolId=1, poolLen do
                        local poolConfig = GetPoolConfigNew(gameConfig.subGameId, gameConfig.roomType, poolId)
                        if poolConfig ~= nil then
                            table.insert(datas, poolConfig)
                        end
                    end
                elseif gameConfig.poolType == 5 then
                    local poolConfig = GetPoolConfig3(gameConfig.subGameId, gameConfig.roomType)
                    if poolConfig ~= nil then
                        table.insert(datas, poolConfig)
                    end
                end
            end
        end
    end

    if unilight.REDISDB ~= nil and table.len(datas) > 0 then
        unilight.redis_sethashdata(Const.REDIS_HASH_NAME.SLOTS_POOL_INFO, tostring(unilight.getzoneid()), table2json(datas))
    end

end

--保存单机游戏信息到redis
function SaveSinglePoolInfoToRedis()
    local datas = {}
    for gameKey, gameConfig in pairs(table_game_list) do
        if gameConfig.isOpen == 1 then
            if (gameConfig.poolType == 2 or gameConfig.poolType == 4) then
                if IsCustomServer(gameConfig.subGameId , gameConfig.roomType) then
                    local poolConfig = GetPoolConfig(gameConfig.subGameId, gameConfig.roomType)
                    local stockInfo = GetHundredStockInfo(gameConfig.subGameId, gameConfig.roomType)
                    table.merge(poolConfig, stockInfo)
                    table.insert(datas, poolConfig)
                end
            end
        end
    end
    if unilight.REDISDB ~= nil and table.len(datas) > 0 then
        unilight.redis_sethashdata(Const.REDIS_HASH_NAME.SINGLE_POOL_INFO, tostring(unilight.getzoneid()), table2json(datas))
    end
end
