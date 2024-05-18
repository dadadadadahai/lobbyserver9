--游戏通用变量定义
module('gamecommon', package.seeall)

GAME_POOL_CONFIG = {}               --奖池配置

table_parameter_parameter = import "table/table_parameter_parameter"
POOL_TICK                 = table_parameter_parameter[13].Parameter        --奖池间隔时间
TENTH                     = 10000                                          --万分比
JACKPOT_HISTORY_DB        = "gamejackpothistory"                          --历史记录
JACKPOT_HISTORY_LEN       = 20                                           --jackpot历史记录长度

local table_game_list = import "table/table_game_list"
 


--[[
desc: jackpot数据库获取接口
params @gameid          游戏id
params @gameType        游戏子类型 
--]]
function GetJackpotHistoryDBInfo(gameId, gameType)
    -- -- local gameKey = gameId * 10000 + gameType
    -- local gameKey = gameId*1000000+ unilight.getzoneid() * 100 + gameType
	-- local filter = unilight.eq("_id", gameKey)
	-- local jackpotHistoryInfo = unilight.chainResponseSequence(unilight.startChain().Table(JACKPOT_HISTORY_DB).Filter(filter))	
	-- for _,jackpotInfo in ipairs(jackpotHistoryInfo) do
    --     return jackpotInfo
    -- end

    -- unilight.info("获得jackpot历史数据为空, gameId="..gameId..", gameType="..gameType)
    -- return nil
end

--[[
desc: jackpot增加爆池历史
params: 
    @uid        玩家id
    @gameId     slots游戏id
    @gameType   slots游戏子类型
    @jackpotNum jackpot数量
    @chips      jackpot获得的金币 
    @extData    {}自定义数据,比如终级现金可以存放jackpot数量对应的倍数
--]]
function AddJackpotHisory(uid, gameId, gameType, jackpotNum, chips, extData)

    local gameKey = gameId * 10000 + gameType
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    local jackpotInfo = {
        headUrl    = userInfo.base.headurl,
        nickName   = userInfo.base.nickname,
        chips      = chips,
        jackpotNum = jackpotNum,
        extData    = extData,
        uid        = uid,
    }

    -- local jackpotHistoryInfo  = GetJackpotHistoryDBInfo(gameId, gameType)
    -- if jackpotHistoryInfo == nil then
        -- jackpotHistoryInfo = {
            -- _id = gameKey,
            -- jackpotInfos = {}
        -- }
    -- end
    -- if table.len(jackpotHistoryInfo.jackpotInfos) >= JACKPOT_HISTORY_LEN then
        -- table.remove(jackpotHistoryInfo.jackpotInfos, 1)
    -- end
--
    -- table.insert(jackpotHistoryInfo.jackpotInfos, jackpotInfo)
	-- unilight.savedata(JACKPOT_HISTORY_DB, jackpotHistoryInfo)
    -- if gameId==112 then
    --     print(string.format('gameId=%d,chips=%d',gameId,chips))
    -- end
    -- lampgame.AddTypeOneRobot(gameId,chips)

    local data = {}
    data.gameId = gameId
    data.gameType = gameType
    data.jackpotInfo = jackpotInfo
    local gameKey = gameId*1000000+ unilight.getzoneid() * 100 + gameType


    local jackpotHistoryInfo  = gamecommon.GetJackpotHistoryDBInfo(gameId, gameType)
    if jackpotHistoryInfo == nil then
        jackpotHistoryInfo = {
            _id = gameKey,
            jackpotInfos = {}
        }
    end
    if table.len(jackpotHistoryInfo.jackpotInfos) >= gamecommon.JACKPOT_HISTORY_LEN then
        table.remove(jackpotHistoryInfo.jackpotInfos, 1)
    end

    table.insert(jackpotHistoryInfo.jackpotInfos, jackpotInfo)
	unilight.savedatasyn(gamecommon.JACKPOT_HISTORY_DB, jackpotHistoryInfo)

    -- ChessToLobbyMgr.SendCmdToLobby("Cmd.ReqHistoryInfoGame_CS", data)
    gamecommon.BroadcastPoolReward(data)

    --保存日志记录, 充值大于等于60才记录
    if userInfo.property.totalRechargeChips >= 6000 then
        gamecommon.AddUserJackpotLog(gameId, gameType, uid, chips)
    end

end
--[[
--假人增加jackpot
--]]
function AddRobotJackpotHistory(robotConfig, params)


--     local gameId  = params.gameId
--     local gameType = params.gameType
--     local gameKey = gameId * 10000 + gameType

--     --做个优化,多开时如果不在指定服务器内不请求
--     if go.gamezone.Gameid == Const.GAME_TYPE.SLOTS then
--         if IsCustomServer(gameId, gameType) == false then
--             return 
--         end
--     end

--     local jackpotInfo = {
--         headUrl    = robotConfig.frameId,
--         nickName   = robotConfig.nickName,
--         chips      = params.chips,
--         jackpotNum = params.jackpotNum,
--         extData    = params.extData,
--         uid        = 0,
--         robotId    = robotConfig.uid
--     }


--     -- local jackpotHistoryInfo  = GetJackpotHistoryDBInfo(gameId, gameType)
--     -- if jackpotHistoryInfo == nil then
--         -- jackpotHistoryInfo = {
--             -- _id = gameKey,
--             -- jackpotInfos = {}
--         -- }
--     -- end
--     -- if table.len(jackpotHistoryInfo.jackpotInfos) >= JACKPOT_HISTORY_LEN then
--         -- table.remove(jackpotHistoryInfo.jackpotInfos, 1)
--     -- end
-- --
--     -- table.insert(jackpotHistoryInfo.jackpotInfos, jackpotInfo)
-- 	-- unilight.savedata(JACKPOT_HISTORY_DB, jackpotHistoryInfo)
--     -- lampgame.AddTypeOneRobot(gameId,params.chips)
--     local data = {}
--     data.gameId = gameId
--     data.gameType = gameType
--     data.jackpotInfo = jackpotInfo
--     local gameKey = gameId*1000000+ unilight.getzoneid() * 100 + gameType


--     local jackpotHistoryInfo  = gamecommon.GetJackpotHistoryDBInfo(gameId, gameType)
--     if jackpotHistoryInfo == nil then
--         jackpotHistoryInfo = {
--             _id = gameKey,
--             jackpotInfos = {}
--         }
--     end
--     if table.len(jackpotHistoryInfo.jackpotInfos) >= gamecommon.JACKPOT_HISTORY_LEN then
--         table.remove(jackpotHistoryInfo.jackpotInfos, 1)
--     end

--     table.insert(jackpotHistoryInfo.jackpotInfos, jackpotInfo)
-- 	unilight.savedatasyn(gamecommon.JACKPOT_HISTORY_DB, jackpotHistoryInfo)

--     -- ChessToLobbyMgr.SendCmdToLobby("Cmd.ReqHistoryInfoGame_CS", data)

--     gamecommon.BroadcastPoolReward(data)
end




--[[
desc: jackpot历史记录通知玩家
--]]
function SendJackpotHisoryToMe(uid, gameId, gameType)
    local jackpotHistoryInfo  = GetJackpotHistoryDBInfo(gameId, gameType)
    if jackpotHistoryInfo == nil then
        return 
    end
	local res = {}
	res["do"] = "Cmd.GetJackpotHistoryGame_S"
    res.data = {}
    res.data.jackpotInfos = {}
    res.data.gameType = gameType

    for _, jackpotInfo in ipairs(jackpotHistoryInfo.jackpotInfos) do
        table.insert(res.data.jackpotInfos, jackpotInfo)
    end

    unilight.sendcmd(uid, res)
end


--[[
desc: 奖池初始化(游戏调用)
params @gameid          游戏id
params @poolConfigs  奖池配置文件，缺一不可 
{
chipsConfigs     = table_101_jackpot_chips   --标准金额
addPerConfigs    = table_101_jackpot_add_per --奖池增加
bombConfigs      = table_101_jackpot_bomb    --奖池暴池概率
scaleConfigs     = table_101_jackpot_scale   --奖池爆池比例
betConfigs       = table_101_jackpot_bet     --奖池触发下注
}
游戏奖池配置
]]
-- function GamePoolInit(gameId, poolConfigs)
function GamePoolInit(gameId)
    -- if IsCustomServer(gameId) == false then
    --     unilight.info("正式服，不在指定进程，不启动奖池2:"..gameId)
    --     return 
    -- end
    -- local poolConfigs = {
    --     chipsConfigs = import ("table/game/"..gameId.."/table_"..gameId.."_jackpot_chips"),
    --     addPerConfigs = import ("table/game/"..gameId.."/table_"..gameId.."_jackpot_add_per"),
    --     bombConfigs = import ("table/game/"..gameId.."/table_"..gameId.."_jackpot_bomb"),
    --     -- scaleConfigs = import ("table/game/"..gameId.."/table_"..gameId.."_jackpot_scale"),
    --     betConfigs = import ("table/game/"..gameId.."/table_"..gameId.."_jackpot_bet"),
    -- }
    -- if  poolConfigs.chipsConfigs  == nil or
    --     poolConfigs.addPerConfigs == nil or
    --     poolConfigs.bombConfigs   == nil or
    --     -- poolConfigs.scaleConfigs  == nil or
    --     poolConfigs.betConfigs    == nil then
    --     unilight.error("奖池初始配置失败, 请检查配置, gameId="..gameId)
    --     return
    -- end
    -- local initSuccess = false
    -- --初始化标准金额
    -- for gameType, chipsInfo in pairs(poolConfigs.chipsConfigs) do
    --     GAME_POOL_CONFIG[gameId] = GAME_POOL_CONFIG[gameId] or {}
    --     local gamePool =  GAME_POOL_CONFIG[gameId]
    --     gamePool.gameTypeInfos = gamePool.gameTypeInfos or {}
    --     gamePool.gameTypeInfos[gameType] = gamePool.gameTypeInfos[gameType] or {}
    --     gamePool.gameTypeInfos[gameType] = {
    --         standardChips = chipsInfo.chips or 0,        --标准金额
    --         realPoolChips = chipsInfo.realchips or 0,    --真奖池金额
    --         fakePoolChips = chipsInfo.chips or 0,        --假奖池金额
    --         bombTime      = 0,                      --假奖池爆池时间
    --         bombChips     = 0,                      --假奖池爆池金额
    --         betIndex      = 0,                      --真奖池爆池下注档次
    --         realChips     = 0,                      --真奖池爆池金额
    --         realEndTime   = 0,                      --真奖池爆池结束时间
    --         jackpotNum    = 0,                       --中真奖池时，jackpot图标数量
    --         jackpotNum2   = 0,                      --假奖池图标数量
    --         poolConfigs = {},
    --     }
    --     -- 获取奖池库存数据
    --     local jackpotStockInfo = unilight.getdata('jackpotstock',gameId*1000000+ unilight.getzoneid() * 100 + gameType)
    --     -- 读取奖池库存数据
    --     if table.empty(jackpotStockInfo) == false and jackpotStockInfo.jackpotStock ~= nil then
    --         gamePool.gameTypeInfos[gameType].realPoolChips = jackpotStockInfo.jackpotStock
    --     end
    --     gamePool.gameTypeInfos[gameType].poolConfigs.scaleConfigs = import ("table/game/"..gameId.."/table_"..gameId.."_jackpot_scale"..gameType)
    --     gamePool.poolConfigs = poolConfigs              --配置文件
    --     gamePool.poolType = GetGameConfig(gameId, gameType).poolType
    --     gamePool.intervalSec  = POOL_TICK
    --     gamePool.lastTimeSec  = 0

    --     initSuccess = true
    -- end
    -- unilight.info("初始化奖池:"..gameId)

    -- if not initSuccess then
    --     unilight.error("奖池初始失败:"..gameId)
    -- end
end


--[[
desc : 游戏下注传入下注金额,增加真奖池
]]
function ReqGamePoolBet(gameId, gameType, chips)
    -- local gamePool     = GAME_POOL_CONFIG[gameId]
    -- local gameTypeInfo = gamePool.gameTypeInfos[gameType]
    -- if gameTypeInfo == nil then
    --     -- unilight.error("真奖池增加金额游戏类型错误:gameId="..gameId..", gameType="..gameType)
    --     return
    -- end
    -- --gm增加真奖池添加金额倍数
    -- local gameMgr = GetGameMgr(gameId)
    -- if gameMgr ~= nil and gameMgr.gmInfo.jackpot == 1 then
    --     chips = chips * 100000
    -- end
    -- local addRealPoolPer = gamePool.poolConfigs.addPerConfigs[gameType].addRealPoolPer
    -- local addChips       =  chips * (addRealPoolPer / TENTH)
    -- gameTypeInfo.realPoolChips = gameTypeInfo.realPoolChips + addChips
    -- unilight.info(string.format("游戏(%d:%d)下注增加奖池金额:%d, 总金额:%d", gameId, gameType, addChips, gameTypeInfo.realPoolChips))
end

--[[
desc:  假奖池，根据配置时间定时增加金额, 暴池判断
--]]
function GamePoolsTick()
    if go.gamezone.Gameid ~= Const.GAME_TYPE.SLOTS then
        return
    end
    -- if 1 == 1 then
        -- return
    -- end
    --增加假奖池金额
    for gameId, gamePool in pairs(GAME_POOL_CONFIG) do
        -- 判断是否超出周期
        if os.time() >= gamePool.lastTimeSec + gamePool.intervalSec then
            if gamePool.poolType == 1 or gamePool.poolType == 4 then
                for gameType, gameTypeInfo in pairs(gamePool.gameTypeInfos) do
                    local addPerConfig  = gamePool.poolConfigs.addPerConfigs[gameType]
                    --增加万分比
                    -- print("game="..gameId)
                    -- print(table2json(gameTypeInfo))
                    local addTenPer     = math.random(addPerConfig.fakePoolMin, addPerConfig.fakePoolMax)
                    local addChips     = math.floor(gameTypeInfo.standardChips * (addTenPer / TENTH))
                    -- local gameMgr = GetGameMgr(gameId)
                    --gm固定增加假奖池
                    -- if gameMgr ~= nil and gameMgr.gmInfo.jackpot == 1 then
                    --     addChips = 2000000
                    -- end
                    gameTypeInfo.fakePoolChips = gameTypeInfo.fakePoolChips + addChips
                    -- unilight.info(string.format("游戏(%d:%d)假奖池增加奖池金额:%d, 总金额:%d", gameId, gameType, addChips, gameTypeInfo.fakePoolChips))
                end
            end
        end
    end
    --假奖池爆池
    for gameId, gamePool in pairs(GAME_POOL_CONFIG) do
        -- 判断是否超出周期
        if os.time() >= gamePool.lastTimeSec + gamePool.intervalSec then
            gamePool.lastTimeSec = os.time()
            if gamePool.poolType == 1 or gamePool.poolType == 4 then
                for gameType, gameTypeInfo in pairs(gamePool.gameTypeInfos) do
                    --是否爆池
                    local bBomb = false
                    local bombPer = 0
                    --当前值/标准值，查看在哪个区间
                    local diffChips = math.floor((gameTypeInfo.fakePoolChips / gameTypeInfo.standardChips) * 100)
                    -- local diffChips = math.floor(gameTypeInfo.fakePoolChips / gameTypeInfo.standardChips) * 100
                    local bombConfigs = gamePool.poolConfigs.bombConfigs
                    for _, bombConfig in ipairs(bombConfigs) do
                        if diffChips >= bombConfig.fakePoolChipsMin and diffChips <= bombConfig.fakePoolChipsMax then
                            bombPer = bombConfig.fakePoolBombPer
                            break
                        elseif diffChips > bombConfigs[#bombConfigs].fakePoolChipsMax then
                            -- 如果超出配置表范围
                            bombPer = bombConfigs[#bombConfigs].fakePoolBombPer
                            break
                        end
                    end
    
                    if random.selectByTenTh(bombPer) then
                        bBomb = true
                    end
                    --gm固定增加假奖池
                    local gameMgr = GetGameMgr(gameId)
                    if gameMgr ~= nil and gameMgr.gmInfo.jackpot == 1 then
                        bBomb = true
                    end
                    --触发爆池
                    if bBomb then
                        --假奖池爆出金额
                        -- local scaleConfigs = gamePool.poolConfigs.scaleConfigs
                        local scaleConfigs = gamePool.gameTypeInfos[gameType].poolConfigs.scaleConfigs
    
                        local probability   = {}
                        local allResult     = {}
                        for _, scaleConfig in ipairs(scaleConfigs) do
                            table.insert(probability, scaleConfig.fakePoolPro)
                            table.insert(allResult, scaleConfig)
    
                        end
                        local fakeScaleConfig = math.random(probability, allResult)
    
                        --中假奖池时jackpot数量
                        -- gameTypeInfo.jackpotNum = fakeScaleConfig.iconNum
                        gameTypeInfo.jackpotNum2 = fakeScaleConfig.iconNum
                        --假奖池暴出金额
                        local bombChips = math.floor(gameTypeInfo.fakePoolChips * (fakeScaleConfig.fakePoolPer / 100))
                        gameTypeInfo.bombChips = bombChips
                        --如果真奖池的金额小于这个金额,未来随机时间为假奖池减掉这个金额
                        -- if gameTypeInfo.realPoolChips < bombChips then
                        -- 判断真奖池配置表是否符合爆池
                        local realPoolFlag = false
                        for _, scaleConfig in ipairs(scaleConfigs) do
                            if scaleConfig.realPoolPro > 0 then
                                realPoolFlag = true
                            end
                        end
                        if (gameTypeInfo.realPoolChips < math.floor(gameTypeInfo.fakePoolChips * (scaleConfigs[#scaleConfigs].fakePoolPer / 100))) or (not realPoolFlag) then
                            -- gameTypeInfo.bombTime = os.time() + math.random(1, POOL_TICK)
                            gameTypeInfo.bombTime = os.time() + math.random(1, gamePool.intervalSec)
                            -- gameTypeInfo.bombChips = bombChips
                            -- unilight.info(string.format("游戏(%d:%d)触发假奖池暴池, 总金额:%d, 爆池时间:%d, 爆池金额:%d", gameId, gameType, gameTypeInfo.fakePoolChips, gameTypeInfo.bombTime, bombChips))
                            -- local params = {
                            --     chips = bombChips,
                            --     gameId = gameId,
                            --     gameType = gameType,
                            --     jackpotNum = gameTypeInfo.jackpotNum,
                            -- }
                            -- --倍数和奖池id
                            -- params.extData = {
                            --     pool  = math.random(1,4),
                            --     mul   = math.random(1,4),
                            -- }
                            -- --请求一个机器人
                            -- ReqRobotList(gameId, 1, params)
                        else

                            -- 真奖池配置
                            local probability   = {}
                            local allResult     = {}
                            for _, scaleConfig in ipairs(scaleConfigs) do
                                table.insert(probability, scaleConfig.realPoolPro)
                                table.insert(allResult, scaleConfig)
        
                            end
                            local realScaleConfig = math.random(probability, allResult)
        
                            --中真奖池时jackpot数量
                            gameTypeInfo.jackpotNum = realScaleConfig.iconNum
                            --真奖池爆奖下注档次
                            local betConfigs = gamePool.poolConfigs.betConfigs
                            local probability   = {}
                            local allResult     = {}
                            for _, betConfig in ipairs(betConfigs) do
                                table.insert(probability, betConfig.realPoolPer)
                                table.insert(allResult, betConfig)
    
                            end
                            local betConfig          = math.random(probability, allResult)
                            gameTypeInfo.betIndex    = betConfig.realPoolBet
                            -- gameTypeInfo.realChips   = bombChips
                            gameTypeInfo.realChips   = math.floor(gameTypeInfo.fakePoolChips * (realScaleConfig.fakePoolPer / 100))
                            -- gameTypeInfo.realEndTime = os.time() + POOL_TICK
                            gameTypeInfo.realEndTime = os.time() + gamePool.intervalSec
                            -- unilight.info(string.format("游戏(%d:%d)触发真奖池暴池, 总金额:%d, 爆池结束时间:%d, 爆池金额:%d, 中奖档次:%d", gameId, gameType, gameTypeInfo.realPoolChips, 
                            --             gameTypeInfo.realEndTime, gameTypeInfo.realChips, gameTypeInfo.betIndex))
                        end
                    end
                end
            end
        end
    end
end



--[[
desc : 获得指定游戏奖池奖励
params:
        @gameId   游戏id
        @gameType 游戏类型
        @betIndex 下注档次
]]
function GetGamePoolChips(gameId, gameType, betIndex)
    -- local gamePool = GAME_POOL_CONFIG[gameId]
    -- local gameTypeInfo = gamePool.gameTypeInfos[gameType]
    -- local jackpotNum = 0
    -- local jackpotChips = 0
    -- if gameTypeInfo == nil then
    --     unilight.error("玩家计算奖池奖励，找不到游戏奖池信息:gameId="..gameId..", gameType="..gameType)
    --     return false, jackpotNum, jackpotChips
    -- end
    -- if gamecommon.IsRotateInControl() then
    --     return false, jackpotNum, jackpotChips
    -- end
    -- print("gameTypeInfo.realEndTime = "..gameTypeInfo.realEndTime)
    -- --不能中奖判断
    -- if gameTypeInfo.realChips == 0 or os.time() > gameTypeInfo.realEndTime or gameTypeInfo.betIndex <= 0  then
    --     return false, jackpotNum, jackpotChips 
    -- end
    -- --下注档次必须要大于中奖档次
    -- if betIndex < gameTypeInfo.betIndex then
    --     return false, jackpotNum, jackpotChips 
    -- end

    -- --可以爆池了
    -- jackpotNum = gameTypeInfo.jackpotNum
    -- jackpotChips = gameTypeInfo.realChips
    -- -- 真奖池爆池减少假奖池金额
    -- gameTypeInfo.fakePoolChips = gameTypeInfo.fakePoolChips - jackpotChips
    -- -- 真奖池爆池减少真奖池金额
    -- gameTypeInfo.realPoolChips = gameTypeInfo.realPoolChips - jackpotChips
    -- --清空下爆池信息
    -- gameTypeInfo.realChips   = 0
    -- gameTypeInfo.realEndTime = 0
    -- gameTypeInfo.betIndex    = 0

    return false, 0, 0
end


--[[
desc:  奖池秒钟循环，减少假奖池数量, 真奖池没人中也要减少假奖池
--]]
function GamePoolsTenTick()
    local curTime = os.time()
    for gameId, gamePool in pairs(GAME_POOL_CONFIG) do
        for gameType, gameTypeInfo in pairs(gamePool.gameTypeInfos) do
            --假奖池扣除金额
            if gameTypeInfo.bombTime > 0 and  curTime >= gameTypeInfo.bombTime and gameTypeInfo.bombChips >= 0 then
                local params = {
                    chips = gameTypeInfo.bombChips,
                    gameId = gameId,
                    gameType = gameType,
                    jackpotNum = gameTypeInfo.jackpotNum2,
                }
                --倍数和奖池id
                params.extData = {
                    pool  = math.random(1,4),
                    mul   = math.random(1,4),
                }
                gameTypeInfo.fakePoolChips = gameTypeInfo.fakePoolChips - gameTypeInfo.bombChips
                if gameTypeInfo.fakePoolChips < 0 then
                    gameTypeInfo.fakePoolChips = 0
                end
                gameTypeInfo.bombChips     = 0
                gameTypeInfo.bombTime      = 0
                --请求一个机器人
                ReqRobotList(gameId, 1, params)
            end

            --真奖池如果没人中奖， 扣除假奖池数量
            if gameTypeInfo.realChips > 0 and curTime >= gameTypeInfo.realEndTime and gameTypeInfo.betIndex > 0  then
                local params = {
                    -- chips = gameTypeInfo.realChips,
                    chips = gameTypeInfo.bombChips,
                    gameId = gameId,
                    gameType = gameType,
                    jackpotNum = gameTypeInfo.jackpotNum2,
                }
                --倍数和奖池id
                params.extData = {
                    pool  = math.random(1,4),
                    mul   = math.random(1,4),
                }
                -- gameTypeInfo.fakePoolChips = gameTypeInfo.fakePoolChips - gameTypeInfo.realChips
                gameTypeInfo.fakePoolChips = gameTypeInfo.fakePoolChips - gameTypeInfo.bombChips
                if gameTypeInfo.fakePoolChips < 0 then
                    gameTypeInfo.fakePoolChips = 0
                end
                gameTypeInfo.realChips = 0
                gameTypeInfo.realEndTime = 0
                gameTypeInfo.betIndex = 0
                gameTypeInfo.bombChips = 0
                --请求一个机器人
                ReqRobotList(gameId, 1, params)
            end

        end
    end

end


--[[
desc : 推送奖池配置
--]]
function SendGamePoolBase(uid)
    --没在游戏中不发
    if PLAYER_GAMES[uid] == nil then
        return
    end

    local gameId = PLAYER_GAMES[uid]

    local send      = {}
    send["do"]      = "Cmd.GamePoolBaseGame_S"
    local data = {
        gameId = gameId,
        poolBase = {},
        intervalTime = 0,

    }
    local gamePool = GAME_POOL_CONFIG[gameId]
    if gamePool==nil then
        -- print('gameId='..gameId)
        return
    end
    for gameType, gameTypeInfo in pairs(gamePool.gameTypeInfos) do

        local poolConfig = GetGamePoolConfig(gameId, gameType)
        data.intervalTime =  poolConfig.intervalTime
        local poolData = 
        {
            gameType = gameType,  
            chips = gameTypeInfo.fakePoolChips,
            fakeBaseValue = poolConfig.fakeBaseValue,
            fakePoolMin   = poolConfig.fakePoolMin,
            fakePoolMax   = poolConfig.fakePoolMax,
        }
        table.insert(data.poolBase, poolData)
    end

    send.data = data
    unilight.sendcmd(uid, send)
end


--[[
desc : gm获得奖池配置
--]]
function GetPoolConfig(gameId, gameType)
    local gamePool = GAME_POOL_CONFIG[gameId]
    local rebatevalue, norechargertp, lowrechargertp = gamecommon.GetRTPByGame(gameId, gameType)
    if gamePool == nil then
        local poolConfig = {
            subgameid         = gameId, 
            subgametype       = gameType,
            addrealpoolper = 0,
            realpoolchips  = 0,
            fakepoolchips  = 0,
            fakepoolmin    = 0,
            fakepoolmax    = 0,
            limitlow       = 0,
            rebatevalue    = rebatevalue, 
            norechargertp  = norechargertp, 
            lowrechargertp = lowrechargertp,
            standardchips  = 0,
            bomblooptime   = 0,
            totalprofit    = 0,     --todo等待填充
        } 
        return poolConfig
    end
    local gameTypeInfo = gamePool.gameTypeInfos[gameType]

    local gameKey = gameId  * 10000 + gameType
    local gameConfig = table_game_list[gameKey] 

    local addPerConfig  = gamePool.poolConfigs.addPerConfigs[gameType]
    local poolConfig = {
        subgameid         = gameId, 
        subgametype       = gameType,
        addrealpoolper = gamePool.poolConfigs.addPerConfigs[gameType].addRealPoolPer,
        realpoolchips  = gameTypeInfo.realPoolChips,
        fakepoolchips  = gameTypeInfo.fakePoolChips,
        fakepoolmin    = addPerConfig.fakePoolMin,
        fakepoolmax    = addPerConfig.fakePoolMax,
        limitlow       = gameConfig.limitLow,
        standardchips  = gameTypeInfo.standardChips,
        bomblooptime   = gamePool.intervalSec,
        totalprofit    = 0,     --todo等待填充
        rebatevalue    = rebatevalue, 
        norechargertp  = norechargertp, 
        lowrechargertp = lowrechargertp,
    }
    return poolConfig
end

--[[
desc : gm设置奖池参数
poolConfig: {
    addRealPoolPer, --入池万分比
    realPoolChips,  --真奖池金额
    fakePoolChips,  --假奖池金额
    fakePoolMin,    --假奖池增长最小
    fakePoolMax,    --假奖池增长最大
    limitLow   ,    --进入金币条件-分
    rebateValue,    --返奖参数
    standardChips   --最低爆池金额
}
--]]
function SetPoolConfig(gameId, gameType, poolConfig)
    unilight.info(string.format("gm设置slots奖池,游戏ID:%d, 游戏场次:%d, 参数:%s", gameId, gameType, table2json(poolConfig)))

    --设置rtp
    if poolConfig.rebatevalue > 0 then
        gamecommon.SetGameRTP(gameId, gameType, poolConfig.rebatevalue, poolConfig.norechargertp, poolConfig.lowrechargertp )
    end

    if GAME_POOL_CONFIG[gameId] == nil then
        unilight.info(string.format("gm设置slots奖池,游戏ID:%d, 游戏场次:%d, 没有奖池数据", gameId, gameType))
        return
    end
    local gamePool = GAME_POOL_CONFIG[gameId]
    local gameTypeInfo = GAME_POOL_CONFIG[gameId].gameTypeInfos[gameType]
    local addPerConfig  = gamePool.poolConfigs.addPerConfigs[gameType]
    -- local gameTypeInfo = gamePool.gameTypeInfos[gameType]
    -- local addRealPoolPer = gamePool.poolConfigs.addPerConfigs[gameType].addRealPoolPer
    if poolConfig.addrealpoolper > 0 then
        gamePool.poolConfigs.addPerConfigs[gameType].addRealPoolPer = poolConfig.addrealpoolper
    end

    if poolConfig.realpoolchips ~= nil and poolConfig.realpoolchips > 0 then
        gameTypeInfo.realPoolChips = poolConfig.realpoolchips
    end

    if poolConfig.fakepoolchips ~= nil and poolConfig.fakepoolchips > 0 then
        gameTypeInfo.fakePoolChips = poolConfig.fakepoolchips
    end

    if poolConfig.fakepoolmin > 0 then
        addPerConfig.fakePoolMin = poolConfig.fakepoolmin
    end

    if poolConfig.fakepoolmax > 0 then
        addPerConfig.fakePoolMax = poolConfig.fakepoolmax
    end

    if poolConfig.limitlow ~= nil then
        local gameKey = gameId  * 10000 + gameType
        local gameConfig = table_game_list[gameKey] 
        gameConfig.limitLow = poolConfig.limitlow 
    end


    if poolConfig.standardchips > 0 then
        gameTypeInfo.standardChips = poolConfig.standardchips
    end

    if poolConfig.bomblooptime > 0 then
        gamePool.intervalSec = poolConfig.bomblooptime
    end
end
-- 获取当前奖池中奖的Jackpot图标数量
function GetJackpotIconNum(gameId, gameType)
    local gamePool = GAME_POOL_CONFIG[gameId]
    local gameTypeInfo = gamePool.gameTypeInfos[gameType]
    return gameTypeInfo.jackpotNum
end

-- Jackpot奖池数值修改总定时器触发逻辑
function JackpotClocker()
    -- if os.time() == GAME_POOL_CONFIG[111].gameTypeInfos[1].realEndTime then
    --     local msg = {
    --         betIndex = 5,
    --         gameType = 1,
    --     }
    --     OrchardCarnival.CmdGameOprate(1004345, msg)
    -- end
    -- 减少金额
    GamePoolsTenTick()
    -- if os.time() % POOL_TICK == 0 then
    -- 新的周期增加金额
    GamePoolsTick()
    -- end
end
