--游戏通用变量定义
module('gamecommon', package.seeall)

--[[
    有名字的jack通用逻辑
]]
NameJackMap={}          --{gameId,configTable={},sessions={virtPools,realPools}}
local table_game_list = import "table/table_game_list"
local table_parameter_parameter = import "table/table_parameter_parameter"

--[[
    初始化奖池
]]
function JackNameInit(GameId,module)
    -- if IsCustomServer(GameId) == false then
    --     unilight.info("正式服，不在指定进程，不启动奖池3:"..GameId)
    --     return 
    -- end

    -- --拼接配置
    -- local cfgbase = string.format('table/game/%d/',GameId)
    -- if NameJackMap[GameId]~=nil then
    --     unilight.error('JackNameInit 重复注册')
    --     return
    -- end
    -- --注册机器人请求逻辑
    -- lampgame.reqRebotList(GameId,module)
    -- NameJackMap[GameId] = {
    --     intervalSec = table_parameter_parameter[13].Parameter,
    --     lastTimeSec = 0,
    --     gameId = GameId,
    --     configTable={
    --     table_jackpot_chips = import(cfgbase..'table_jackpot_chips'),
    --     -- table_jackpot_add_per = import(cfgbase..'table_jackpot_add_per'),
    --     table_jackpot_add_pers={},
    --     table_jackpot_bomb = import(cfgbase..'table_jackpot_bomb'),
    --     table_jackpot_scale = import(cfgbase..'table_jackpot_scale'),
    --     table_jackpot_bet = import(cfgbase..'table_jackpot_bet'),
    --     },
    --     sessions={},        --场次[gameType] = {virtPools,realPools}
    --     realPoolBombInfo={},        --真奖池爆发记录 realPoolBombInfo[gameType]={}
    --     module=module,
    -- }
    -- --初始化奖池
    -- local childcfg = NameJackMap[GameId]
    -- for gameType, value in ipairs(childcfg.configTable.table_jackpot_chips) do
    --     local tmp = {virtPools={},realPools={}}
    --     local i=1
    --     while true do
    --         if value['pool'..i]==nil then
    --             break
    --         end
    --         table.insert(tmp.virtPools,value['pool'..i])
    --         table.insert(tmp.realPools,value['realchips'..i])
    --         i=i+1
    --     end
    --     table.insert(childcfg.sessions,tmp)
    --     -- 获取奖池库存数据
    --     local jackpotStockInfo = unilight.getdata('jackpotstock',GameId*1000000+ unilight.getzoneid() * 100 + gameType)
    --     -- 读取奖池库存数据
    --     if table.empty(jackpotStockInfo) == false and jackpotStockInfo.jackpotStock ~= nil then
    --         childcfg.sessions[gameType].realPools = jackpotStockInfo.jackpotStock
    --     end
    --     childcfg.configTable.table_jackpot_add_pers[gameType] = import(cfgbase..'table_jackpot_add_per'..gameType)
    -- end
end
--奖池时间函数每分钟
function JackNameTimeTicket()
    local timenow = os.time()
    for _,gameobj in pairs(NameJackMap) do
        if timenow - gameobj.lastTimeSec>= gameobj.intervalSec then
            if table.empty(gameobj.realPoolBombInfo)==false then
                --机器人爆池
                --增加机器人记录
                for gameType,objs in pairs(gameobj.realPoolBombInfo) do
                    for _,obj in ipairs(objs) do
                        local sessions = gameobj.sessions
                        local virtPools = sessions[gameType].virtPools
                        -- print(string.format('poolid=%d,gameType=%d,gameId=%d,score=%d',obj.poolId,gameType,gameobj.gameId,obj.realpoolscore))
                        --假奖池衰减
                        virtPools[obj.poolId] = virtPools[obj.poolId] - obj.realpoolscore
                        --增加机器人记录
                        lampgame.AddRobotJackpotHistory({gameId=gameobj.gameId,gameType=gameType,chips=obj.realpoolscore,jackpotNum=0,extData={pool=obj.poolId}})
                        --增加跑马灯
                        --一共有多少个奖池
                        local poolId = obj.poolId
                        local realpoolscore = obj.realpoolscore
                        local tpoolnum = #virtPools
                        local rpool = tpoolnum-poolId+1
                        lampgame.AddTypeThreeRobot(gameobj.gameId,3+(rpool-1),realpoolscore)
                    end
                end
                gameobj.realPoolBombInfo = {}
            end
            --假奖池增加
            virtualPoolAdd(gameobj)
            --假奖池爆池概率
            bombVirtualPool(gameobj)
            gameobj.lastTimeSec=timenow
        end
    end
end
--假奖池增加,处理
function virtualPoolAdd(gameobj)
    -- local table_jackpot_add_per = gameobj.configTable.table_jackpot_add_per
    local sessions = gameobj.sessions
    for gameType, value in ipairs(sessions) do
        local table_jackpot_add_per = gameobj.configTable.table_jackpot_add_pers[gameType]
        local virtPools = value.virtPools
        for pool=1,#virtPools do
            local realAddPer = math.random(table_jackpot_add_per[pool].fakePoolMin,table_jackpot_add_per[pool].fakePoolMax)
            virtPools[pool] = math.floor(virtPools[pool]*(1+realAddPer/10000))
            -- unilight.info(string.format('假奖池增加,gameId=%d,gameType=%d,pooId=%d,val=%d',gameobj.gameId,gameType,pool,virtPools[pool]))
        end
    end
end
--假奖池爆池概率
function bombVirtualPool(gameobj)
    local sessions = gameobj.sessions
    for gameType, value in ipairs(sessions) do
        local virtPools = value.virtPools
        local table_jackpot_add_per = gameobj.configTable.table_jackpot_add_pers[gameType]
        local poolId
        local curval
        local poolList = {}
        -- 判断筛选满足爆池条件的奖池
        for id, value in ipairs(virtPools) do
            if bombItemCfg(gameType,id,value,gameobj) > 0 then
                table.insert(poolList,{poolId = id,curval = value,jackpotPro = table_jackpot_add_per[id].jackpotPro})
            end
        end
        -- 按权重随机爆哪一个奖池
        if table.empty(poolList) == false then
            local randomIndex = gamecommon.CommRandInt(poolList, 'jackpotPro')
            poolId = poolList[randomIndex].poolId
            curval = poolList[randomIndex].curval
        end
        if poolId ~= nil and curval ~= nil then
            local gailv = bombItemCfg(gameType,poolId,curval,gameobj)
            local r = math.random(10000)
            if r<=gailv then
                --爆发假奖池
                --local virtualper = math.random(virtualpercfg.fakePoolPer,virtualpercfg.fakePoolPro)
                --确定爆池比例
                local virtualpercfg  = gameobj.configTable.table_jackpot_scale[CommRandInt(gameobj.configTable.table_jackpot_scale,'fakePoolPro')]
                local virtualper = virtualpercfg.fakePoolPer
                local realpoolscore = math.floor(curval*(virtualper/100))
                -- unilight.info(string.format('curval=%d,realpoolscore=%d,poolId=%d,gameId=%d,gameType=%d'
                -- ,curval,realpoolscore,poolId,gameobj.gameId,gameType))
                --判断真奖池情况
                if value.realPools[poolId] >=realpoolscore then
                    gameobj.realPoolBombInfo[gameType] = gameobj.realPoolBombInfo[gameType] or {}
                    table.insert(gameobj.realPoolBombInfo[gameType],{poolId=poolId,realpoolscore=realpoolscore})
                else
                    virtPools[poolId] = curval - realpoolscore
                    --unilight.info(string.format('机器人获得假奖池,gameId=%d,gameType=%d,poolid=%d,realpoolscore=%d',gameobj.gameId,gameType,poolId,realpoolscore))
                    --增加机器人记录
                    lampgame.AddRobotJackpotHistory({gameId=gameobj.gameId,gameType=gameType,chips=realpoolscore,jackpotNum=0,extData={pool=poolId}})
                    --增加跑马灯
                    --一共有多少个奖池
                    local tpoolnum = #virtPools
                    local rpool = tpoolnum-poolId+1
                    lampgame.AddTypeThreeRobot(gameobj.gameId,3+(rpool-1),realpoolscore)
                    -- if gameobj.gameId==112 then
                    --     print(string.format("AddTypeThreeRobot rpool=%d tpoolnum=%d poolId=%d type=%d",rpool,tpoolnum,poolId,3+(rpool-1)))
                    -- end
                end
            end
        end
    end
end
--获取爆炸配置具体项
--[[
    场次 奖池id 当前值
]]
function bombItemCfg(gameType,poolid,curval,gameobj)
    local table_jackpot_bomb = gameobj.configTable.table_jackpot_bomb
    local table_jackpot_chips = gameobj.configTable.table_jackpot_chips
    local initchip = table_jackpot_chips[gameType]['pool'..poolid]
    local bili = curval/initchip*100
    local bomb = 0
    for i=1,#table_jackpot_bomb do
        if bili>=table_jackpot_bomb[i].fakePoolChipsMin and bili<=table_jackpot_bomb[i].fakePoolChipsMax then
            bomb = table_jackpot_bomb[i]['fakeBombPer'..poolid]
            break
        end
    end
    return bomb
end
--[[
    用户下注增加真奖池
]]
function NameReqGamePoolBet(gameId, gameType, chip)
    local gameobj = NameJackMap[gameId]
    if gameobj==nil then
        unilight.error('gameId='..gameId..',未注册游戏增加奖池下注')
        return
    end
    local session = gameobj.sessions[gameType]
    -- local table_jackpot_add_per = gameobj.configTable.table_jackpot_add_per
    local table_jackpot_add_per = gameobj.configTable.table_jackpot_add_pers[gameType]
    for poolid,_ in ipairs(session.realPools) do
        local addRealPoolPer = table_jackpot_add_per[poolid].addRealPoolPer
        local addrealscore = chip*addRealPoolPer/10000
        session.realPools[poolid] = session.realPools[poolid] + addrealscore
        -- unilight.info(string.format('真奖池%d,增加%d,chip = %d',poolid,addrealscore,chip))
    end
end
--[[
    真实用户返回是否应该触发奖池
]]
function NameGetGamePoolChips(GameId,gameType,betIndex)
    local poolId,jackpotscore = 0,0
    if gamecommon.IsRotateInControl() then
        return poolId,jackpotscore
    end
    local gameobj = NameJackMap[GameId]
    if gameobj==nil then
        unilight.error('gameId='..GameId..',未注册游戏增加奖池下注')
        return
    end
    local needOut=false
    if gameobj.module.gmInfo.jackpot==1 then
        -- print("进入GM")
        if table.empty(gameobj.realPoolBombInfo[gameType]) then
            gameobj.realPoolBombInfo[gameType] = gameobj.realPoolBombInfo[gameType] or {}
            table.insert(gameobj.realPoolBombInfo[gameType],{
                poolId = 1,
                realpoolscore = 20000,
            })
        end
        gameobj.sessions[gameType].virtPools[4] = gameobj.sessions[gameType].virtPools[4] + 20000
        gameobj.sessions[gameType].realPools[4] = gameobj.sessions[gameType].realPools[4] + 20000
        needOut  =true
    end
    if table.empty(gameobj.realPoolBombInfo[gameType])==false then
        local table_jackpot_bet = gameobj.configTable.table_jackpot_bet
        local cfg=table_jackpot_bet[1]
        for _, value in ipairs(table_jackpot_bet) do
            if betIndex>=value.realPoolBet then
                cfg = value
            else
                break
            end
        end
        --他的触发概率
        local gailv = cfg.realPoolPer
        local r = math.random(10000)
        if r<=gailv or needOut then
            local real = gameobj.realPoolBombInfo[gameType][1]
            poolId,jackpotscore = real.poolId,real.realpoolscore
            --print("==================")
            --真奖池衰减
            gameobj.sessions[gameType].realPools[poolId] = gameobj.sessions[gameType].realPools[poolId] - jackpotscore
            gameobj.sessions[gameType].virtPools[poolId] = gameobj.sessions[gameType].virtPools[poolId] - jackpotscore
            table.remove(gameobj.realPoolBombInfo[gameType],1)
            if #gameobj.realPoolBombInfo[gameType]<=0 then
                gameobj.realPoolBombInfo[gameType] = nil
            end
        end
    end
    -- unilight.info(string.format('poolId=%d,jackpotscore=%d',poolId,jackpotscore))
    return poolId,jackpotscore
end
--验证奖池是否应该触发
--percent 爆池百分比
function IsWinJackPot(money,poolId,percent,GameId,gameType)
    if gamecommon.IsRotateInControl() then
        return 0
    end
    local gameobj = NameJackMap[GameId]
    if gameobj==nil then
        unilight.error('gameId='..GameId..',未注册游戏增加奖池下注')
        return 0
    end
    local configTable = gameobj.configTable
    local table_jackpot_chips = configTable.table_jackpot_chips
    local lowcp = table_jackpot_chips[gameType]['pool'..poolId]
    local virtPools = gameobj.sessions[gameType].virtPools[poolId]
    local realPools = gameobj.sessions[gameType].realPools[poolId]
    local bombscore = (virtPools*(percent/100))+money
    local bomblowchip = table_jackpot_chips[gameType]['bomb'..poolId]
    -- print('bombscore',bombscore,'virtPools',virtPools,'realPools',realPools)
    if virtPools<lowcp or realPools<bombscore or virtPools<bombscore or realPools<bomblowchip then
        return 0
    end
    return math.floor(bombscore)
end
--奖池执行扣减
function DecPool(linemoney,jackpotMoney,poolId,GameId,gameType)
    local gameobj = NameJackMap[GameId]
    gameobj.sessions[gameType].virtPools[poolId] =  gameobj.sessions[gameType].virtPools[poolId] - jackpotMoney
    gameobj.sessions[gameType].realPools[poolId] = gameobj.sessions[gameType].realPools[poolId] - (linemoney+jackpotMoney)
end
--玩家登陆推送奖池,每分钟推送奖池
function SendJackNameSend(uid)
    --没在游戏中不发
    if PLAYER_GAMES[uid] == nil then
        return
    end
    local gameId = PLAYER_GAMES[uid]
    -- print('gameId='..gameId..',uid='..uid)
    local send      = {}
    send["do"]      = "Cmd.GamePoolBaseGame_S"
    local data = {
        gameId = gameId,
        poolBase = {},
        intervalTime = 0,
    }
    local gamePool = NameJackMap[gameId]
    if gamePool==nil then
        --print('gameId='..gameId)
        return
    end
    for gameType, value in pairs(gamePool.sessions) do
        local virtPools = value.virtPools
        for poolId, curval in ipairs(virtPools) do
            local poolConfig = GetGamePoolConfig(gameId, gameType, poolId)
            data.intervalTime =  poolConfig.intervalTime
            local poolData = 
            {
                gameType = gameType,  
                fakeBaseValue = poolConfig.fakeBaseValue,
                fakePoolMin   = poolConfig.fakePoolMin,
                fakePoolMax   = poolConfig.fakePoolMax,
                poolId=poolId,
                baseValue=curval,
                isAdd=1
            }
            table.insert(data.poolBase, poolData)
        end
    end
    send.data = data
    unilight.sendcmd(uid, send)
end

--[[
    desc: 获得奖池长度
]]
function GetPoolLen(gameId, gameType)
    -- local childcfg = NameJackMap[gameId]
    -- local gamepoolobj = childcfg.sessions[gameType]
    -- return table.len(gamepoolobj.realPools)
    return 0
end

--[[
desc : gm获得奖池配置
--]]
function GetPoolConfigNew(gameId, gameType, poolId)

    local gameKey = gameId  * 10000 + gameType
    local gameConfig = table_game_list[gameKey]
    local childcfg = NameJackMap[gameId]
    local gamepoolobj = childcfg.sessions[gameType]
    if gamepoolobj == nil then
        return nil
    end
    local config = childcfg.configTable
    local rebatevalue, norechargertp, lowrechargertp = gamecommon.GetRTPByGame(gameId, gameType)
    local poolConfig = {
        subgameid         = gameId,         --游戏id
        subgametype       = gameType,       --游戏类型
        addrealpoolper = config.table_jackpot_add_pers[gameType][poolId].addRealPoolPer,                 --入池万分比
        realpoolchips  = gamepoolobj.realPools[poolId],                 --真奖池金额
        fakepoolchips  = gamepoolobj.virtPools[poolId],                 --假奖池金额
        fakepoolmin    = config.table_jackpot_add_pers[gameType][poolId].fakePoolMin,                 --假奖池增长最小
        fakepoolmax    = config.table_jackpot_add_pers[gameType][poolId].fakePoolMax,                 --假奖池增长最大
        limitlow       = gameConfig.limitLow, --最低准入金额
        standardchips  = config.table_jackpot_chips[gameType]['pool'..poolId], --最爆低池金额
        bomblooptime   = childcfg.intervalSec, --爆池周期(不修改)
        totalprofit    = 0,     --todo等待填充
        poolId         = poolId,    --奖池id
        rebatevalue    = rebatevalue,   --充值rtp
        norechargertp  = norechargertp, --非充值rtp 
        lowrechargertp = lowrechargertp, --低充值rtp
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
function SetPoolConfigNew(gameId, gameType, poolId, poolConfig)
    unilight.info(string.format("gm设置slots奖池,游戏ID:%d, 游戏场次:%d, 参数:%s", gameId, gameType, table2json(poolConfig)))
    -- local gameTypeInfo = gamePool.gameTypeInfos[gameType]
    -- local addRealPoolPer = gamePool.poolConfigs.addPerConfigs[1].addRealPoolPer
    local childcfg = NameJackMap[gameId]
    local gamepoolobj = childcfg.sessions[gameType]
    local config = childcfg.configTable
    if poolConfig.bomblooptime > 0 then
        childcfg.intervalSec = poolConfig.bomblooptime
    end
    if poolConfig.addrealpoolper > 0 then
        --
        config.table_jackpot_add_pers[gameType][poolId].addRealPoolPer = poolConfig.addrealpoolper
    end

    if poolConfig.realpoolchips ~= nil and poolConfig.realpoolchips > 0 then
        --
        gamepoolobj.realPools[poolId] = poolConfig.realpoolchips
    end

    if poolConfig.fakepoolchips ~= nil and poolConfig.fakepoolchips > 0 then
        --
        gamepoolobj.virtPools[poolId] = poolConfig.fakepoolchips
    end

    if poolConfig.fakepoolmin > 0 then
        --
        config.table_jackpot_add_pers[gameType][poolId].fakePoolMin = poolConfig.fakepoolmin
    end

    if poolConfig.fakepoolmax > 0 then
        --
        config.table_jackpot_add_pers[gameType][poolId].fakePoolMax = poolConfig.fakepoolmax
    end

    if poolConfig.limitlow ~= nil then
        local gameKey = gameId  * 10000 + gameType
        local gameConfig = table_game_list[gameKey]
        gameConfig.limitLow = poolConfig.limitlow
    end

    --todo 等待数据填充
    if poolConfig.rebatevalue > 0 then
        gamecommon.SetGameRTP(gameId, gameType, poolConfig.rebatevalue, poolConfig.norechargertp, poolConfig.lowrechargertp)
    end

    if poolConfig.standardchips > 0 then
        --
        config.table_jackpot_chips[gameType]['pool'..poolId] = poolConfig.standardchips
    end

end
