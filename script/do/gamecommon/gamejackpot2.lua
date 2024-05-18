--老版本的jackpot处理
module('gamecommon', package.seeall)
table_game_list = import "table/table_game_list"
GAME_POOL_CONFIG2 = {}               --奖池配置
MAX_POOL_COUNT = 15                  --奖池最大编号
GAME_ROBOT_CONFIG2 = {}              --游戏机器人配置
TEST_FLAG = true
ROOM_LIST = {1,2,3}
--[[
desc: 奖池初始化(游戏调用)
params @gameid          游戏id
params @lineNum         游戏总线数
params @tableGamePool   游戏奖池配置
params @jackpotRobotTable   游戏奖池机器人配置
]]
function GamePoolInit2(gameId, lineNum, tableGamePool, jackpotRobotTable)
    if IsCustomServer(gameId) == false then
        unilight.info("正式服，不在指定进程，不启动奖池4:"..gameId)
        return 
    end

    local initSuccess = false
    local addPoolNum = tableGamePool.addpoolnum
    GAME_POOL_CONFIG2[gameId] = GAME_POOL_CONFIG2[gameId] or {}
    for _, gameType in ipairs(ROOM_LIST) do
        for i=1, MAX_POOL_COUNT  do
            if tableGamePool["mul"..i]  ~= nil then
                local baseMul = tableGamePool["mul"..i]
                GAME_POOL_CONFIG2[gameId][gameType] = GAME_POOL_CONFIG2[gameId][gameType] or {}
                local gamePool =  GAME_POOL_CONFIG2[gameId][gameType]
                local isAdd    = 0
                if i <= addPoolNum then
                    isAdd = 1
                end
                local poolBase = {
                    baseValue = baseMul * lineNum,      --奖池基础值
                    baseMul   = baseMul,                --奖池倍数
                    poolId    = i,                         --奖池编号
                    lineNum   = lineNum,                  --总线数
                    config    = table.clone(tableGamePool),     --奖池配置
                    isAdd     = isAdd,                  --奖池是否要增长
                }
                gamePool[i] = poolBase  
                initSuccess = true
            end
        end
        GAME_ROBOT_CONFIG2[gameId] = jackpotRobotTable  -- 保存机器人配置
        if not initSuccess then
            unilight.error("奖池初始失败:"..gameId)
        end
    end
end


--[[
desc : 获得指定游戏奖池奖励
params:
        @gameId   游戏id
        @poolId  奖池编号(1-15)最大15
        @betGold  下注金额
]]
function GetGamePoolChips2(gameId, poolId, betGold,gameType)
    local gamePool = GAME_POOL_CONFIG2[gameId][gameType]
    local poolBase = gamePool[poolId]
    -- print("==================")
    -- print("poolBase.baseValue = "..poolBase.baseValue)
    -- print("betGold = "..betGold)
    -- print("poolId = "..poolId)
    -- print("gameId = "..gameId)
    -- print("gameType = "..gameType)
    -- print("==================")
    return poolBase.baseValue * betGold
end


--[[
desc:  奖池定时器,增长、下降奖池金额
--]]
function GamePoolOneMinTick()
    for gameId, gamePool in pairs(GAME_POOL_CONFIG2) do
        for _, roomPool in ipairs(gamePool) do
            for poolId, poolBase  in pairs(roomPool) do
                if poolBase.isAdd == 1 then
                    local poolConfig = poolBase.config 
                    local addPer = math.random(poolConfig.perminaddlowerlimit, poolConfig.perminaddupperlimit) 
                    local addValue = math.floor(poolBase.baseValue *  addPer / 10000)
                    poolBase.baseValue = poolBase.baseValue + addValue
                    --万分比还原
                    if random.selectByTenTh(poolBase.config.perminreset) then
                        poolBase.baseValue  = poolBase.baseMul * poolBase.lineNum
                    end
                end
            end
        end
    end
end


--[[
desc : 推送奖池配置
--]]
function SendGamePoolBase2(uid)
    --没在游戏中不发
    if PLAYER_GAMES[uid] == nil then
        return
    end

    local gameId = PLAYER_GAMES[uid]

    local send      = {}
    send["do"]      = "Cmd.GamePoolBaseGame_S"
    local data = 
    {
        gameId = gameId,
        poolBase = {},
        intervalTime = 0,  
    }
    local gamePool = GAME_POOL_CONFIG2[gameId]
    if gamePool==nil then
        -- print('gameId='..gameId)
        return
    end
    for poolId, poolBase in pairs(gamePool) do
        table.insert(data.poolBase, {poolId = poolBase.poolId, baseValue = poolBase.baseValue, isAdd = poolBase.isAdd, fakeBaseValue = 0, fakePoolMin = 0, fakePoolMax = 0})
    end

    send.data = data
    unilight.sendcmd(uid, send)
end



--[[
desc: jackpot增加爆池历史
params: 
    @uid        玩家id
    @gameId     slots游戏id
    @gameType   slots游戏子类型
    @jackpotNum jackpot图标数量
    @chips      jackpot获得的金币 
    @extData    {}自定义数据,比如终级现金可以存放jackpot图标数量对应的倍数
--]]
function AddRobotJackpotHisory2(uid, gameId, gameType, jackpotNum, chips, extData)

    -- local gameKey = gameId * 10000 + gameType
    -- local gameKey = gameId*1000000+ unilight.getzoneid() * 100 + gameType
    -- local userInfo = chessuserinfodb.RUserInfoGet(uid)
    -- local jackpotInfo = {
    --     headUrl    = userInfo.base.headurl,
    --     nickName   = userInfo.base.nickname,
    --     chips      = chips,
    --     jackpotNum = jackpotNum,
    --     extData    = extData,
    -- }

    -- local jackpotHistoryInfo  = GetJackpotHistoryDBInfo(gameId, gameType)
    -- if jackpotHistoryInfo == nil then
    --     jackpotHistoryInfo = {
    --         _id = gameKey,
    --         jackpotInfos = {}
    --     }
    -- end
    -- if table.len(jackpotHistoryInfo.jackpotInfos) >= JACKPOT_HISTORY_LEN then
    --     table.remove(jackpotHistoryInfo.jackpotInfos, 1)
    -- end

    -- table.insert(jackpotHistoryInfo.jackpotInfos, jackpotInfo)
	-- unilight.savedata(JACKPOT_HISTORY_DB, jackpotHistoryInfo)
end

-- 假爆池给机器人
function JackpotRobot()
    cash.CashRobotHistory()
    miner.MinerRobotBomb()
    if table.empty(GAME_POOL_CONFIG2) then
        return
    end
    -- 遍历奖池
    for gameId, gamePool in pairs(GAME_POOL_CONFIG2) do
        local jackpotTable = GAME_ROBOT_CONFIG2[gameId]
        if table.empty(jackpotTable) then
            unilight.error("2类型奖池假爆池给机器人注册失败, 请检查配置, gameId="..gameId)
        else
            for gameType, roomPool in pairs(gamePool) do
                -- 如果中奖
                if math.random(10000) < jackpotTable.JackpotPro[1].pro then
                -- if TEST_FLAG then
                    local randomJackpotId = 0
                    if table.empty(jackpotTable.JackpotPool) == false then
                        -- 随机爆池的奖池号
                        local jackpotIdPro = {}
                        local jackpotIdResult = {}
                        for i, v in ipairs(jackpotTable.JackpotPool) do
                            if v.pro > 0 then
                                table.insert(jackpotIdPro, v.pro)
                                table.insert(jackpotIdResult, {v.pro, v.jackpot})
                            end
                        end
                        randomJackpotId = math.random(jackpotIdPro, jackpotIdResult)[2]
                    end
                    -- 随机爆池档次
                    local jackpotPoolPro = {}
                    local jackpotPoolResult = {}
                    for i, v in ipairs(jackpotTable.JackpotGrade) do
                        if v.pro > 0 then
                            table.insert(jackpotPoolPro, v.pro)
                            table.insert(jackpotPoolResult, {v.pro, v.betIndex})
                        end
                    end
                    local randomBetIndex = math.random(jackpotPoolPro, jackpotPoolResult)[2]
                    local lineNum = roomPool[randomJackpotId].lineNum or roomPool[1].lineNum
                    local betConfig = gamecommon.GetBetConfig(gameType,lineNum)
                    local betgold = betConfig[randomBetIndex]                                                       -- 单注下注金额
                    -- 获取奖池奖励
                    local winScore = 0
                    local mul
                    if table.empty(jackpotTable.JackpotMul) == false then
                        mul = jackpotTable.JackpotMul[gamecommon.CommRandInt(jackpotTable.JackpotMul,'pro')].mul
                    else
                        winScore = GetGamePoolChips2(gameId, randomJackpotId, betgold,gameType)
                    end

                    if gameId == 105 and randomJackpotId > 2 then
                        break
                    end
                    
                    -- 发送跑马灯
                    lampgame.AddTypeThreeRobot(gameId,randomJackpotId + 2,winScore)
                    -- 结构数据
                    local params = {
                        gameId = gameId,
                        gameType = gameType,
                        chips = winScore,
                    }
                    params.extData = {
                        pool  = randomJackpotId,
                        mul   = mul,
                    }
                    --请求一个机器人
                    ReqRobotList(gameId, 1, params)
                end
            end
        end
    end
    TEST_FLAG = false
end
