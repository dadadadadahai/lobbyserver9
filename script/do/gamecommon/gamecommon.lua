--游戏通用模块
module('gamecommon', package.seeall)
local betgrade= import "table/gamecommon/table_gamecommon_betgrade" --读取等级档次表
local commonbet= import "table/gamecommon/table_gamecommon_bet" --通用下注配置
local table_gamecommon_bet_1 = import 'table/gamecommon/table_gamecommon_bet_1'
local table_gamecommon_bet_2 = import 'table/gamecommon/table_gamecommon_bet_2'
local table_gamecommon_bet_3 = import 'table/gamecommon/table_gamecommon_bet_3'
local table_game_list = import "table/table_game_list"
local table_parameter_parameter= import "table/table_parameter_parameter"
local table_stock_tax = import "table/table_stock_tax"

local POOL_TICK = table_parameter_parameter[13].Parameter        --奖池间隔时间




local gameChangeBetCallBack = {}    --游戏改变下注回调
allGameManagers = {}                --所有游戏管理类 = {[101] = xxmgr}

PLAYER_GAMES     = {}               --玩家所在的游戏{[10011]=1}
PLAYER_GAMES_TYPE = {}              --玩家所在的游戏类型
PLAYER_LAST_TIME  = {}              --玩家上次发送时间,小于1秒返回

MAX_POOL_COUNT = 15                  --奖池最大编号

function GetBetConfig(gameType,LineNum)
    local betconfig = table_gamecommon_bet_1
    if gameType==2 then
        betconfig = table_gamecommon_bet_2
    elseif gameType==3 then
        betconfig = table_gamecommon_bet_3
    end
    local config ={}
    for _, value in ipairs(betconfig) do
        table.insert(config,value['bet_'..LineNum])
    end
    return config
end

--获得所有下注配置
function GetAllBetConfig(gameId, LineNum)
    local configs = {}
    for gameType =1, 3 do
        local gameConfig = table_game_list[gameId * 10000 + gameType]
        if gameConfig ~= nil then
            local betconfig = table_gamecommon_bet_1
            if gameType==2 then
                betconfig = table_gamecommon_bet_2
            elseif gameType==3 then
                betconfig = table_gamecommon_bet_3
            end
            local config ={}
            for _, value in ipairs(betconfig) do
                table.insert(config,value['bet_'..LineNum])
            end
            table.insert(configs, config)
        end
    end
    return configs
end

--通用浮点数随机取
function CommRandFloat(cTable,filed)
    local r = math.random()
    local trand = 0
    for index, value in ipairs(cTable) do
        trand = trand + value[filed]
        if r<=trand then
            return index
        end
    end
    return -1
end
--通用整数取随机
function CommRandInt(cTable,filed)
    if #cTable == 1 then 
        return 1,cTable[1]
    end 
    
    local rt = 0
    for _, value in ipairs(cTable) do
        rt =rt + value[filed]
    end
    if rt<=0 then
        return -1,-1
    end
    local r = math.random(rt)
    rt = 0
    for index, value in ipairs(cTable) do
        rt =rt + value[filed]
        if r<=rt then
            return index,value 
        end
    end
    return -1,-1
end
--随机取数组权重
function CommRandArray(array)
    local zt = 0
    for _, value in ipairs(array) do
        zt = zt + value
    end
    local r = math.random(zt)
    zt = 0
    for index,value in ipairs(array) do
        zt = zt + value
        if r<=zt then
            return index
        end
    end
    return -1
end


function filllinewinicon(oneline,out)
    local index=1
    while true do
        if oneline['I'..index]~=nil then
            table.insert(out,oneline['I'..index])
            index=index+1
        else
            break
        end
    end
end
--通用3个最先出现中奖 小游戏玩法 AAABBBCCC
--返回数组
function CommThreeWin(cTable,filed)
    local trow = #cTable*3
    local rpospools={}
    for i=1, #cTable do
        for j=1,3 do
            table.insert(rpospools,i)
        end
    end
    local rands = {}
    --构成随机数组
    for i=1,trow do
        local rindex = math.random(#rpospools)
        table.insert(rands,rpospools[rindex])
        table.remove(rpospools,rindex)
    end
    --取最先满足3个的图标
    local threefirst = 0
    local threemap={}
    for _, value in ipairs(rands) do
        threemap[value]=threemap[value] or 0
        threemap[value] =threemap[value]+1
        if threemap[value]>=3 then
            threefirst = value
            break
        end
    end
    --取权重得出中奖id
    local zid = CommRandInt(cTable,filed)
    for  index, value in ipairs(rands) do
        if value==threefirst then
            rands[index] = zid
        elseif value==zid then
            rands[index] = threefirst
        end
    end
    return rands, zid
end



--判断图标是否一致 是否需要可用wild
function isSame(firsticon,curicon,wild,nowild)
    if firsticon==curicon then
        return true
    else
        if wild[curicon]~=nil and nowild[firsticon]~=nil then
            return false
        end
        --如果当前图标不能使用wild替换
        if nowild[curicon]~=nil then
            return false
        end
        --当前图标可以使用wild替换
        if wild[curicon]~=nil then
            return true
        end
    end
end
--通用发送
function SendNet(uid,cmd,data)
    local send={}
    send['do']='Cmd.'..cmd
    send['data'] = data
    unilight.sendcmd(uid,send)
end

--注册游戏
function RegGame(gameId, gamemgr)
    if allGameManagers[gameId] ~= nil then
        unilight.error("重复注册游戏："..gameId)
        return
    end
    unilight.info("注册游戏:"..gameId)
    allGameManagers[gameId] = gamemgr
    gamemgr.gmInfo = table.clone(gamecommon.gmInfo)
    --如果没有处理机器人消息，这里代处理下
    -- if gamemgr.RspRobotList == nil then
    --     -- unilight.info("游戏:("..gameId..")未定义机器人处理， 通用函数处理")
    --     gamemgr.RspRobotList = function(data)
    --         --还回机器人
    --         -- print('moren')
    --         local robotIds = {}
    --         for _, robotConfig in pairs(data.robotList) do
    --             table.insert(robotIds, robotConfig.uid)
    --             AddRobotJackpotHistory(robotConfig, data.params)
    --             if not(gameId==112 or gameId==114 or gameId==109 or gameId==105 or gameId==210) then
    --                 --增加跑马灯
    --                 lampgame.AddTypeOneRobot(gameId,data.params.chips)
    --             end
    --         end
    --         ReqRobotRestore(data.gameId, robotIds)
    --     end
    -- end
end

--获得游戏管理类
function GetGameMgr(gameId)
    if allGameManagers[gameId] == nil then
        unilight.error("获得游戏管理失败："..gameId)
        return nil
    end
    
    return allGameManagers[gameId]
end

--注册游戏改变下注消息
function RegChangeBet(gameId,func)
    gameChangeBetCallBack[gameId] = func
end

--进入游戏操作
function CmdEnterGame(gameId, uid, msg)
    local gameMgr = allGameManagers[gameId]
    if gameMgr == nil then
        unilight.error("CmdEnterGame 未注册游戏:"..gameId)
        return
    end
    if  gameMgr.CmdEnterGame == nil then
        unilight.error("CmdEnterGame 没有注册消息:"..gameId)
        return
    end
    gameMgr.CmdEnterGame(uid, msg)

    PLAYER_GAMES[uid] = gameId

    --游戏类型在线
    local gameType = msg.gameType
    PLAYER_GAMES_TYPE[gameId] = PLAYER_GAMES_TYPE[gameId] or {}
    PLAYER_GAMES_TYPE[gameId][gameType] = PLAYER_GAMES_TYPE[gameId][gameType] or {}
    PLAYER_GAMES_TYPE[gameId][gameType][uid] = 1

    SendGamePoolBase(uid)
    SendGamePoolBase2(uid)
    SendGamePoolBase3(uid)
    SendJackNameSend(uid)
    -- 中级场引导
    -- IntermediateFieldGuidance(uid,gameType)
    --统计游戏信息
    UserLoginGameInfo(uid, gameId, gameType)
    -- SendJackpotHisoryToMe(uid, gameId, gameType)
end
--进入游戏操作
function CmdBuyHighBetCmd(gameId, uid, msg)
    local gameMgr = allGameManagers[gameId]
    if gameMgr == nil then
        unilight.error("CmdBuyHighBetCmd 未注册游戏:"..gameId)
        return
    end
    if  gameMgr.CmdBuyHighBet == nil then
        unilight.error("CmdBuyHighBetCmd 未注册消息:"..gameId)
        return
    end
    gameMgr.CmdBuyHighBet(uid, msg)
    
end

--发送消息给指定游戏类型的玩家
function SendMsgToGameType(gameId, gameType, msg)
    if PLAYER_GAMES_TYPE[gameId] == nil then return end
    if PLAYER_GAMES_TYPE[gameId][gameType] == nil then return end
    for uid, _ in pairs(PLAYER_GAMES_TYPE[gameId][gameType]) do
        unilight.sendcmd(uid, msg)
    end
end

--发送消息给指定游戏id的玩家
function SendMsgToGameId(gameId, msg)
    if PLAYER_GAMES_TYPE[gameId] == nil then return end
    for gameType, uidMaps in pairs(PLAYER_GAMES_TYPE[gameId]) do
        for uid, _ in pairs(uidMaps) do
            unilight.sendcmd(uid, msg)
        end
    end
end

--通知指定类型游戏玩家的奖池信息
function SendPoolDataToGameType(gameId, gameType)
    if PLAYER_GAMES_TYPE[gameId] == nil then return end
    if PLAYER_GAMES_TYPE[gameId][gameType] == nil then return end
    for uid, _ in pairs(PLAYER_GAMES_TYPE[gameId][gameType]) do
        SendGamePoolBase(uid)
        SendGamePoolBase2(uid)
        SendGamePoolBase3(uid)
        SendJackNameSend(uid)
    end


end

--通知指定类型id玩家的奖池信息
function SendPoolDataToGameId(gameId)
    if PLAYER_GAMES_TYPE[gameId] == nil then return end
    for gameType, uidMaps in pairs(PLAYER_GAMES_TYPE[gameId]) do
        for uid, _ in pairs(uidMaps) do
            SendGamePoolBase(uid)
            SendGamePoolBase2(uid)
            SendGamePoolBase3(uid)
            SendJackNameSend(uid)
        end
    end

end

--游戏操作消息
function CmdGameOprate(gameId, uid, msg)
    local gameMgr = allGameManagers[gameId]
    if gameMgr == nil then
        unilight.error("CmdGameOprate 未注册游戏:"..gameId)
        return
    end
    if PLAYER_LAST_TIME[uid] == nil then
        PLAYER_LAST_TIME[uid] = os.msectime()
    end

    if PLAYER_LAST_TIME[uid] < Const.SLOTS_LIMIT_TIME then
        return
    end

    gameMgr.CmdGameOprate(uid, msg)
    --操作完成记录下玩家数据
    local gameType = msg.gameType

    PLAYER_LAST_TIME[uid] = os.msectime()
end


--游戏操作消息
function CmdBuyFreeCmd(gameId, uid, msg)
    local gameMgr = allGameManagers[gameId]
    if gameMgr == nil then
        unilight.error("CmdBuyFreeCmd 未注册游戏:"..gameId)
        return
    end
    if gameMgr.CmdBuyFree == nil then
        unilight.error("CmdBuyFreeCmd 未注册消息:"..gameId)
        return
    end
    if PLAYER_LAST_TIME[uid] == nil then
        PLAYER_LAST_TIME[uid] = os.msectime()
    end

    if PLAYER_LAST_TIME[uid] < Const.SLOTS_LIMIT_TIME then
        return
    end

    gameMgr.CmdBuyFree(uid, msg)
    --操作完成记录下玩家数据
    local gameType = msg.gameType

    PLAYER_LAST_TIME[uid] = os.msectime()
end
--游戏改变下注消息
function CmdChangeBet(gameId,uid,msg)
    local callback = gameChangeBetCallBack[gameId]
    if callback == nil then
        unilight.error("CmdGameOprate 未注册游戏:"..gameId)
        return
    end
    callback(uid, msg)
end
--[[
    第一例有WILD元素下，根据中奖线配置自动判断中奖的线
    线数上2个以上相同的会统计 参数 chessdata 当前数据棋盘,linecfg 线数配置表 wild[key]=1 配置表 nowild[key]=1 排除wild替用配置
    返回值 lines[{line,num,ele,winicon}]  中奖线 中奖元素 中奖图标(列行模式)
]]
function WildWinningLine(chessdata,linecfg,wild,nowild)
    local resdata={}
    --每条中奖线遍历
    for k, v in ipairs(linecfg) do
        local winlineIcon={}
        filllinewinicon(v,winlineIcon)
        local firsticon=0
        local samenum = 1
        local winicon = {}
        local wildTlb = {}
        for i = 1, #winlineIcon do
            local rowindex =math.floor(winlineIcon[i]/10)
            local colindex =winlineIcon[i]%10

            if i==1 or firsticon==0 then

                if chessdata[rowindex][colindex] ==90 then
                    table.insert(wildTlb,{rowindex,colindex})
                else
                    firsticon = chessdata[rowindex][colindex]
                    table.insert(winicon,{rowindex,colindex})
                end
            end
            if firsticon~=0 then
                local same=false
                if isSame(firsticon,chessdata[rowindex][colindex],wild,nowild) then

                    samenum = samenum+1
                    table.insert(winicon,{rowindex,colindex})
                    if #wildTlb>0 then
                        samenum = samenum+#wildTlb
                        for index, value in ipairs(wildTlb) do
                            table.insert(winicon,{value[1],value[2]})

                        end

                    end

                    same=true
                end
                if same==false or samenum>=#winlineIcon then
                    --print('winiconcolnum='..#winicon)
                    local singleline={
                        line = k,
                        num = samenum,
                        ele = firsticon,
                        winicon =winicon,
                    }
                    table.insert(resdata,singleline)
                    break
                end

            end
        end
    end

    return resdata
end


--[[
desc : 玩家退出游戏
]]
function UserLogoutGame(uid)
    local gameId = PLAYER_GAMES[uid]
    PLAYER_GAMES[uid] = nil

    if PLAYER_GAMES_TYPE[gameId] ~= nil then
        for gameType, ids in pairs(PLAYER_GAMES_TYPE[gameId]) do
            ids[uid] = nil
            UserLogoutGameInfo(uid, gameId, gameType)
            if gameId==123 then
                corpse.Drop(gameType,uid)
            end
        end
    end
    storecatch.LeaveEvent(uid)
end


--[[
@desc 执行gm命令
--]]
function CmdGmSetCommand(uid,opType, opValue, gameId)
    local gameId = PLAYER_GAMES[uid] or gameId
    if gameId == nil then
        return "不在游戏中, 使用gm命令失败"
    end
    local gameMgr = allGameManagers[gameId]
    local gmInfo = gameMgr.gmInfo 
    if gmInfo == nil then
        return "未找到游戏id:"..gameId
    end
    if gmInfo[opType] == nil then
        return "不存在的type, 请检查gm命令"
    end
    if type(opValue) ~= "number" then
        return "value值必须为数字"
    end
    gmInfo[opType] = opValue
    gameMgr.gmInfo = gmInfo
    return nil
end

--[[
@desc   获得gm命令状态
--]]
function CmdGmGetCommand(uid, gameId)
    local gameId = PLAYER_GAMES[uid] or gameId
    if gameId == nil then
        return "不在游戏中, 使用gm命令失败"
    end
    local gameMgr = allGameManagers[gameId]
    return table2json(gameMgr.gmInfo)

end

--[[
@desc 重置gm命令状态
--]]
function CmdGmResetCommand(uid, gameId)

    local gameId = PLAYER_GAMES[uid] or gameId
    if gameId == nil then
        return "不在游戏中, 使用gm命令失败"
    end
    local gameMgr  = allGameManagers[gameId]
    gameMgr.gmInfo = table.clone(gamecommon.gmInfo) 
    unilight.info("重置游戏gm命令成功")

end


--[[
-- 请求可用机器人
-- gameId 游戏id
-- robotNum 机器人数量
-- params 自定义参数(会回传)
--]]
function ReqRobotList(gameId, robotNum, params)
    -- local gameInfo = table_game_list[gameId * 10000 + 1]
    -- --做个优化,多开时如果不在指定服务器内不请求
    -- if IsCustomServer(gameId) == false then
    --     return 
    -- end
    -- if gameInfo == nil then
    --     --unilight.error("请求机器人时找不到机器人类型, gameid="..gameId)
    --     gameInfo={}
    --     gameInfo.robotType = 1
    -- end
    -- local data = {
    --     robotType = gameInfo.robotType,
    --     robotNum  = robotNum,
    --     params = params or {},
    --     gameId = gameId,
    -- }
    -- -- print('send ReqRobotList',gameId,gameInfo.robotType)
    -- ChessToLobbyMgr.SendCmdToLobby("Cmd.GetRobotListSmd_C",data)
end

--[[
-- 大厅返回机器人信息
--]]
function RspRobotList(data)
    -- local gameId  = data.gameId   
    -- local gameMgr = GetGameMgr(gameId)
    -- -- print('RspRobotList RspRobotList befor',gameId)
    -- if gameMgr == nil then
    --     unilight.error("大厅返回机人时找不到游戏:"..gameId)
    --     return
    -- end
    ---test
    -- local robotIds = {}
    -- for _, robotConfig in pairs(data.robotList) do
        -- table.insert(robotIds, robotConfig.uid)
    -- end
    -- ReqRobotRestore(gameId, robotIds)
    --test
    -- if gameMgr.RspRobotList == nil then
    --     unilight.error("大厅返回机人时找不到游戏处理函数:RspRobotList, 游戏ID:"..gameId)
    --     return
    -- end
    -- print('RspRobotList RspRobotList',gameId)
    -- gameMgr.RspRobotList(data)
end


--[[
--机器人归还
--@ gameId 游戏id
--@ robotIds 机器人id列表 {100001, 10002}
--]]
function ReqRobotRestore(gameId, robotIds)
    local gameInfo = table_game_list[gameId * 10000 + 1]
    if gameInfo == nil then
        unilight.error("请求机器人归还时找不到机器人类型, gameid="..gameId)
        --return
        gameInfo={
            robotType = 1,
        }
    end

    local data = {
        robotType = gameInfo.robotType,
        robotIds  = robotIds,
    }
    -- if gameId == 112 or gameId == 123 then
    --     unilight.info("归还机器人gameID =="..gameId)
    -- end
    ChessToLobbyMgr.SendCmdToLobby("Cmd.RestoreRobotSmd_C",data)
end


--[[
--进入游戏信息
--@ gameId 游戏id
--@ gameType 游戏类型
--]]
function UserLoginGameInfo(uid, gameId, gameType)
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    local gameInfo = userInfo.gameInfo
    gameInfo.intoTime = os.time()
    gameInfo.loginChips = userInfo.property.chips 
    gameInfo.subGameId   = gameId
    gameInfo.subGameType = gameType
    gameInfo.loginIp  = userInfo.status.lastLoginIp
    gameInfo.gameId   = unilight.getgameid()
    gameInfo.zoneId   = unilight.getzoneid()
    print('unilight.getgameid()',unilight.getgameid(),unilight.getzoneid())
    unilight.info(string.format("用户:%d, 进入游戏:%d:%d, 进入时金币:%d", uid, gameId, gameType, gameInfo.loginChips))
    chessuserinfodb.SaveUserData(userInfo)
end

--[[
--退出游戏信息
--@ gameId 游戏id
--@ gameType 游戏类型
--]]
function UserLogoutGameInfo(uid, gameId, gameType)
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    local gameInfo = userInfo.gameInfo

    if gameInfo.subGameId == gameId and gameInfo.subGameType == gameType then
        gameInfo.logoutChips = userInfo.property.chips 
        unilight.info(string.format("用户:%d, 退出游戏:%d, 退出时金币:%d", uid, gameId, gameInfo.logoutChips))
    end

    --保存下进出日志
    local data={
        _id = go.newObjectId(),
        uid = uid,
        beginTime = gameInfo.intoTime,              -- 进入时间
        endTime = os.time(),                        -- 退出时间
        subGameId = gameInfo.subGameId,             --子游戏id
        subGameType = gameInfo.subGameType,         --子游戏场次
        loginChips = gameInfo.loginChips,           --进入时金币
        logoutChips = gameInfo.logoutChips,         --退出时金币
        table='gameInOutLog',
    }
    if unilight.getdebuglevel() > 0 then
        unilight.savedatasyn("gameInOutLog",data)
    else
        go.logRpc.SaveLogData(json.encode(encode_repair(data)))
    end
    --清空下所在游戏id
    gameInfo.gameId   = 0
    gameInfo.zoneId   = 0
    -- unilight.update('userinfo',uid,userInfo)
    unilight.savedata('userinfo',userInfo)
    -- 房间退出后把缓存的返利流水增加
    rebate.AddRebateChips(uid,true)
end

--[[
--Gm获得单机游戏参数
--@ gameId 游戏id
--@ gameType 游戏类型
--]]
function GmGetSinglePoolConfig(gameId, gameType)
    local datas  = {}
    --查找所有游戏
    if gameId == 0 and gameType == 0 then
        for gameKey, gameConfig in pairs(table_game_list) do
            if gameConfig.isOpen == 1 then
                if (gameConfig.poolType == 2 or gameConfig.poolType == 4) then
                    local poolConfig = GetPoolConfig(gameConfig.subGameId, gameConfig.roomType)
                    local stockInfo = GetHundredStockInfo(gameConfig.subGameId, gameConfig.roomType)
                    table.merge(poolConfig, stockInfo)
                    table.insert(datas, poolConfig)
                end
            end
        end

    --指定游戏所有
    elseif gameId > 0 and gameType == 0 then
        for gameKey, gameConfig in pairs(table_game_list) do
            if (gameConfig.poolType == 2 or gameConfig.poolType == 4) and gameConfig.subGameId == gameId then
                local poolConfig = GetPoolConfig(gameConfig.subGameId, gameConfig.roomType)
                local stockInfo = GetHundredStockInfo(gameConfig.subGameId, gameConfig.roomType)
                table.merge(poolConfig, stockInfo)
                table.insert(datas, poolConfig)
            end
        end
    --指定场次,不区分游戏
    elseif gameId == 0 and gameType > 0 then
        for gameKey, gameConfig in pairs(table_game_list) do
            if (gameConfig.poolType == 2 or gameConfig.poolType == 4) and gameConfig.roomType == gameType then
                local poolConfig = GetPoolConfig(gameConfig.subGameId, gameConfig.roomType)
                local stockInfo = GetHundredStockInfo(gameConfig.subGameId, gameConfig.roomType)
                table.merge(poolConfig, stockInfo)
                table.insert(datas, poolConfig)
            end
        end
    --指定游戏，指定类型
    else
        local gameConfig = table_game_list[gameId * 10000 + gameType]
        if  (gameConfig.poolType == 2 or gameConfig.poolType == 4) then
            local poolConfig = GetPoolConfig(gameId, gameType)
            local stockInfo = GetHundredStockInfo(gameConfig.subGameId, gameConfig.roomType)
            table.merge(poolConfig, stockInfo)
            table.insert(datas, poolConfig)
        end
    end

    return datas
end

--[[
--Gm设置单机游戏参数
--@ gameId 游戏id
--@ gameType 游戏类型
--]]
function GmSetSinglePoolConfig(gameId, gameType, poolConfig)
    local gameConfig = table_game_list[gameId * 10000 + gameType]
    SetPoolConfig(gameId, gameType, poolConfig)
    GmSetHundredGameConfig(gameId, gameType, poolConfig)
end


--[[
--Gm获得slots游戏参数
--@ gameId 游戏id
--@ gameType 游戏类型
--]]
function GmGetSlotsPoolConfig(gameId, gameType)
    local datas  = {}
    --查找所有游戏
    if gameId == 0 and gameType == 0 then
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

    --指定游戏所有
    elseif gameId > 0 and gameType == 0 then
        for gameKey, gameConfig in pairs(table_game_list) do
            if (gameConfig.poolType == 1 or gameConfig.poolType == 0) and gameConfig.subGameId == gameId then
                local poolConfig = GetPoolConfig(gameConfig.subGameId, gameConfig.roomType)
                table.insert(datas, poolConfig)
            elseif gameConfig.poolType == 3 and gameConfig.subGameId == gameId then
                local poolLen = GetPoolLen(gameConfig.subGameId, gameConfig.roomType)
                for poolId=1, poolLen do
                    local poolConfig = GetPoolConfigNew(gameConfig.subGameId, gameConfig.roomType, poolId)
                    table.insert(datas, poolConfig)
                end
            elseif (gameConfig.poolType == 5 or gameConfig.poolType == 0) and gameConfig.subGameId == gameId then
                local poolConfig = GetPoolConfig3(gameConfig.subGameId, gameConfig.roomType)
                table.insert(datas, poolConfig)
            end
        end
    --指定场次,不区分游戏
    elseif gameId == 0 and gameType > 0 then
        for gameKey, gameConfig in pairs(table_game_list) do
            if (gameConfig.poolType == 1  or gameConfig.poolType == 0)and gameConfig.roomType == gameType then
                local poolConfig = GetPoolConfig(gameConfig.subGameId, gameConfig.roomType)
                table.insert(datas, poolConfig)
            elseif gameConfig.poolType == 3 and gameConfig.roomType == gameType then
                local poolLen = GetPoolLen(gameConfig.subGameId, gameConfig.roomType)
                for poolId=1, poolLen do
                    local poolConfig = GetPoolConfigNew(gameConfig.subGameId, gameConfig.roomType, poolId)
                    table.insert(datas, poolConfig)
                end
            elseif (gameConfig.poolType == 5  or gameConfig.poolType == 0)and gameConfig.roomType == gameType then
                local poolConfig = GetPoolConfig3(gameConfig.subGameId, gameConfig.roomType)
                table.insert(datas, poolConfig)
            end
        end
    --指定游戏，指定类型
    else
        local gameConfig = table_game_list[gameId * 10000 + gameType]

        if  (gameConfig.poolType == 1  or gameConfig.poolType == 0) then
            local poolConfig = GetPoolConfig(gameId, gameType)
            table.insert(datas, poolConfig)
        elseif gameConfig.poolType == 3 then
            local poolLen = GetPoolLen(gameConfig.subGameId, gameConfig.roomType)
            for poolId=1, poolLen do
                local poolConfig = GetPoolConfigNew(gameId, gameType, poolId)
                table.insert(datas, poolConfig)
            end
        elseif  (gameConfig.poolType == 5  or gameConfig.poolType == 0) then
            local poolConfig = GetPoolConfig3(gameId, gameType)
            table.insert(datas, poolConfig)
        end
    end

    return datas
end


--[[
--Gm设置slots游戏参数
--@ gameId 游戏id
--@ gameType 游戏类型
--]]
function GmSetSlotsPoolConfig(gameId, gameType, poolConfig)

    local gameConfig = table_game_list[gameId * 10000 + gameType]
    if (gameConfig.poolType == 1  or gameConfig.poolType == 0) then
        SetPoolConfig(gameId, gameType, poolConfig)
    elseif gameConfig.poolType == 3 then
        SetPoolConfigNew(gameId, gameType, poolConfig.poolId, poolConfig)
    elseif gameConfig.poolType == 5 then
        SetPoolConfig3(gameId, gameType, poolConfig)
    end
end
 
--[[
--desc : 获得游戏配置
--]]
function GetGameConfig(gameId, gameType)
    local gameConfig = table_game_list[gameId * 10000 + gameType]
    return gameConfig
end

--[[
--获得游戏RTP
--]]
function GetGameRTP(userinfo,gameId, gameType)
    local rtp = 0
    local gameConfig = table_game_list[gameId * 10000 + gameType]
    if gameConfig ~= nil then
        rtp =  gameConfig.RTP4
    end
    if userinfo.property.totalRechargeChips<=table_parameter_parameter[23].Parameter then
        return rtp
    end
    -- local xs =  gameDetaillog.GetRtpXs(gameId,gameType)
    -- rtp = math.floor(rtp * xs)
    -- print(string.format('GetGameRTP gameId=%d,gameType=%d,rtp=%d,xs=%d',gameId,gameType,rtp,xs))
    return rtp
end

--[[
--获得游戏RTP
--]]
function GetRTPByGame(gameId, gameType)
    local rtp = 0       --充值rtp
    local noRtp = 0     --非充值rtp
    local lowRtp = 0    --低充值rtp
    local gameConfig = table_game_list[gameId * 10000 + gameType]
    if gameConfig ~= nil then
        rtp =  gameConfig.RTP4
        noRtp = gameConfig.noChargeRtp
        lowRtp = gameConfig.lowChargeRtp
    end
    return rtp, noRtp, lowRtp
end


--[[
--设置游戏RTP
--]]
function SetGameRTP(gameId, gameType, rtp, noRtp, lowRtp)
    local gameConfig = table_game_list[gameId * 10000 + gameType]
    if gameConfig ~= nil then
        gameConfig.RTP4 = rtp
        gameConfig.noChargeRtp = noRtp  
        gameConfig.lowChargeRtp = lowRtp
    end
    unilight.info(string.format("设置游戏RTP, 游戏id:%d, 类型:%d, RTP", gameId, gameType, rtp))
end


--[[
-- desc: 获得百人场配置数据
--]]
function GetHundredStockInfo(gameId, gameType)
    local gameMgr = GetGameMgr(gameId)
    local gameConfig = GetGameConfig(gameId, gameType)
    if gameMgr == nil then 
        --空数据
        local data =  {
            subgameid      = gameConfig.subGameId, --; //具体游戏id
            subgametype    = gameConfig.roomType, --; //具体游戏场次
            srcstock       = 0,--; //实际库存
            tarstock       = 0, --; //目标库存
            cutper         = 0, --; //抽水比例
            totalcutnum    = 0, --; //累计抽水
            decaytime      = 0, --; //衰减时间
            decayratio     = 0, --; //衰减比例
            limitchips     = 0, --; //最低准入金额
            decaytype      = 0, --衰减类型
            totaldecaynum  = 0, --todo等待填充
        }
        return data
    end
    local stockInfo = gameMgr.GetStockInfo(gameType)
    local data =  {
            subgameid      = gameConfig.subGameId, --; //具体游戏id
            subgametype    = gameConfig.roomType, --; //具体游戏场次
            srcstock       = stockInfo.Stock,--; //实际库存
            tarstock       = stockInfo.targetStock, --; //目标库存
            cutper         = stockInfo.taxRatio, --; //抽水比例
            totalcutnum    = stockInfo.tTax, --; //累计抽水
            decaytime      = stockInfo.decPeriod, --; //衰减时间
            decayratio     = stockInfo.decRatio, --; //衰减比例
            limitchips     = gameConfig.limitLow, --; //最低准入金额
            decaytype      = stockInfo.type, --衰减类型
            totaldecaynum  = stockInfo.decval, --todo等待填充
        }
    return data
end

--[[
--Gm获得百人场游戏参数
--@ gameId 游戏id
--@ gameType 游戏类型
--]]
function GmGetHundredGameConfig(gameId, gameType)
    local datas  = {}
    --查找所有游戏
    if gameId == 0 and gameType == 0 then
        for gameKey, gameConfig in pairs(table_game_list) do
            if gameConfig.isOpen == 1 then
                if gameConfig.poolType == 100 then
                    local stockInfo = GetHundredStockInfo(gameConfig.subGameId, gameConfig.roomType)
                    if stockInfo.decaytype > 0 then
                        table.insert(datas, stockInfo)
                    end
                end
            end
        end

    --指定游戏所有
    elseif gameId > 0 and gameType == 0 then
        for gameKey, gameConfig in pairs(table_game_list) do
            if (gameConfig.poolType == 100 ) and gameConfig.subGameId == gameId then
                local stockInfo = GetHundredStockInfo(gameConfig.subGameId, gameConfig.roomType)
                if stockInfo.decaytype > 0 then
                    table.insert(datas, stockInfo)
                end
            end
        end
    --指定场次,不区分游戏
    elseif gameId == 0 and gameType > 0 then
        for gameKey, gameConfig in pairs(table_game_list) do
            if (gameConfig.poolType == 100 ) and gameConfig.roomType == gameType then
                local stockInfo = GetHundredStockInfo(gameConfig.subGameId, gameConfig.roomType)
                if stockInfo.decaytype > 0 then
                    table.insert(datas, stockInfo)
                end
            end
        end
    --指定游戏，指定类型
    else
        local stockInfo = GetHundredStockInfo(gameId, gameType)
        if stockInfo.decaytype > 0 then
            table.insert(datas, stockInfo)
        end
    end
    return datas
end

--[[
--Gm设置百人场游戏参数
--@ gameId 游戏id
--@ gameType 游戏类型
--]]
function GmSetHundredGameConfig(gameId, gameType, stockInfo)
    unilight.info("gm设单机百人置配置信息:"..table2json(stockInfo))
    local gameMgr = GetGameMgr(gameId)
    local gameConfig = table_game_list[gameId * 10000 + gameType]
    if stockInfo.limitchips > 0 then
        gameConfig.limitLow = stockInfo.limitchips
    end
    local data = 
    {
        targetStock = stockInfo.tarstock,     --目标库存
        Stock       = stockInfo.srcstock,     --实际库存
        taxRatio    = stockInfo.cutper,     --抽水比例
        decPeriod   = stockInfo.decaytime,     --衰减周期
        decRatio    = stockInfo.decayratio,     --衰减比例
        type   = stockInfo.decaytype,   --衰减类型
        tTax = stockInfo.totalcutnum,   --累计抽水
        decval = stockInfo.totaldecaynum,  --累计衰减值
    }
    gameMgr.SetStockInfo(gameType, data)
end


--[[
--获得游戏奖池配置
--]]
function GetGamePoolConfig(gameId, gameType, poolId)

    local gameConfig = table_game_list[gameId * 10000 + gameType]

    local data = {}
    data.intervalTime = POOL_TICK           --奖池间隔时间
    data.fakeBaseValue = {}                      --奖池基础值 
    data.fakePoolMin = {}                      --奖池变化最小
    data.fakePoolMax = {}                      --奖池变化最大

    if gameConfig.poolType == 1 or gameConfig.poolType == 2 or gameConfig.poolType == 4 then 
        local gamePool =  GAME_POOL_CONFIG[gameId]
        local poolConfigs = gamePool.poolConfigs
        local chipsConfigs = poolConfigs.chipsConfigs
        local addPerConfig = poolConfigs.addPerConfigs[gameType]
        for subGameType, chipsConfig in ipairs(chipsConfigs) do
            if gameType  == subGameType then
                data.fakeBaseValue =chipsConfig.chips
            end
        end
        data.fakePoolMin = addPerConfig.fakePoolMin     --奖池变化最小
        data.fakePoolMax = addPerConfig.fakePoolMax     --奖池变化最大
    elseif gameConfig.poolType == 3 then
        local gamePool = NameJackMap[gameId]
        local table_jackpot_chips = gamePool.configTable.table_jackpot_chips
        --读取基础值
        for subGameType, chipsConfig in ipairs(table_jackpot_chips) do
            if subGameType == gameType then
                data.fakeBaseValue = chipsConfig['pool'..poolId]
                break
            end
        end

        --读取基础配置
        -- local table_jackpot_add_per = gamePool.configTable.table_jackpot_add_per
        local table_jackpot_add_per = gamePool.configTable.table_jackpot_add_pers[gameType]
        for poolIdx, addConfig in ipairs(table_jackpot_add_per) do
            if poolIdx == poolId then
                data.fakePoolMin = addConfig.fakePoolMin     --奖池变化最小
                data.fakePoolMax =  addConfig.fakePoolMax     --奖池变化最大
            end
        end
    elseif gameConfig.poolType == 5 then
        local gamePool =  GAME_POOL_CONFIG3[gameId]
        local poolConfigs = gamePool.poolConfigs
        local chipsConfigs = poolConfigs.chipsConfigs
        local addPerConfig = poolConfigs.addPerConfigs[gameType]
        for subGameType, chipsConfig in ipairs(chipsConfigs) do
            if gameType  == subGameType then
                data.fakeBaseValue =chipsConfig.chips
            end
        end
        data.fakePoolMin = addPerConfig.fakePoolMin     --奖池变化最小
        data.fakePoolMax = addPerConfig.fakePoolMax     --奖池变化最大
    end

    return data
end
--添加奖池历史
function AddJackpotHisoryTypeOne(uid, gameId, gameType, iconNum, jackpotChips)
    gamecommon.AddJackpotHisory(uid, gameId, gameType, iconNum, jackpotChips, {})
    local userinfo = unilight.getdata('userinfo', uid)
    lampgame.AddLampData(uid, userinfo.base.nickname, gameId, jackpotChips, 1)
end
--获取特定模块的配置文件
function GetModuleCfg(GameId,module)
    local tablecfg = unilight.customfiles(string.format('table/game/%d/',GameId))
    for _, value in ipairs(tablecfg) do
        local as = Split(value,'/')
        if #as<=1 then
            as = Split(value,'\\')
        end
        local itemname = Split(as[#as],'.')[1]
        local filepath = Split(value,'.')[1]
        module[itemname] = import(filepath)
    end
end
function Split(str,reps)
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function (w)
        table.insert(resultStrList,w)
    end)
    return resultStrList
end
--返回数组唯一rand
function ReturnArrayRand(array)
    local arrayIndex = math.random(#array)
    local obj = array[arrayIndex]
    table.remove(array,arrayIndex)
    return obj
end

--是否在自定义服务器，正式环境下生效
function IsCustomServer(gameId, gameType)
    if unilight.getdebuglevel() == 0 then
        --优先判断下忽略列表
        if Const.ROBOT_IGNORE_GAME_ID[gameId] ~= nil then  
            return true
        end
        local find = false
        --指定场次
        if gameType ~= nil then
            local gameInfo = table_game_list[gameId * 10000 + gameType]
            --没有配置的话直接返回
            if table.len(gameInfo.rechargeZone) == 0 and table.len(gameInfo.notRechargeZone) == 0 then
                return true
            end
            if table.find(gameInfo.rechargeZone, go.gamezone.Zoneid) ~= nil or table.find(gameInfo.notRechargeZone, go.gamezone.Zoneid) ~= nil then
                find = true
            end
        else
            for i=1, 3 do
                local gameInfo = table_game_list[gameId * 10000 + i]
                if gameInfo ~= nil then
                    --没有配置的话直接返回
                    if table.len(gameInfo.rechargeZone) == 0 and table.len(gameInfo.notRechargeZone) == 0 then
                        return true
                    end
                    if table.find(gameInfo.rechargeZone, go.gamezone.Zoneid) ~= nil or table.find(gameInfo.notRechargeZone, go.gamezone.Zoneid) ~= nil then
                        find = true
                        break
                    end
                end
            end
        end
        if find == true then
            return true
        end
        return false
    end
    return true
end

--游戏增加减少库存
function IncSelfStockNumByType(gameId, gameType, addScore)
    -- gameId = 0
    -- local gameKey   = gameId * 10000  + gameType
    -- unilight.incdate("slotsStock", gameKey, { stockNum = addScore })
end

--获得指定场次库存
function GetSelfStockNumByType(gameId, gameType)
    -- print('SuserId',SuserId)
    -- local userinfo = unilight.getdata('userinfo',SuserId.uid)
    -- -- print('SuserId.uid',SuserId.uid)
    -- if userinfo.property.totalRechargeChips<=0 or userinfo.point.IsNormal==0 then
    --     return 0
    -- end
    -- gameId = 0
    -- local gameKey   = gameId * 10000  + gameType
    -- local slotsStock = unilight.getdata("slotsStock", gameKey)
    -- return slotsStock.stockNum
    return 0
end

--获得库存
function GetStockNumByType(gameKey)
    -- -- gameId = 0
    -- -- local gameKey   = gameId * 10000  + gameType
    -- local slotsStock = unilight.getdata("slotsStock", gameKey)
    -- if slotsStock==nil then
    --     -- unilight.info('gameKey='..gameKey)
    --     return 0
    -- end
    -- return slotsStock.num
    return 0
end

--设置指定场次库存
function SetStockNumByType(gameKey, stockNum)
    -- unilight.info(string.format("设置库存, 场次:%d, 库存:%d", gameKey, stockNum))
    -- local stockInfo = unilight.getdata("slotsStock", gameKey)
    -- stockInfo.num = stockNum
    -- unilight.savedata("slotsStock", stockInfo)
end

-- 保存奖池库存
function SaveJackpotStock()
    -- 游戏列表
    local table_game_list = import "table/table_game_list"
    for _, v in pairs(table_game_list) do
        if v.isOpen == 1 then
            -- 获取奖池库存数据
            local jackpotStockInfo = unilight.getdata('jackpotstock',v.subGameId)
            if table.empty(jackpotStockInfo) then
                local keyval = v.subGameId*1000000+ unilight.getzoneid() * 100 + v.roomType
                jackpotStockInfo = {
                    _id = keyval,
                    jackpotStock = {},
                }
            end
            if v.poolType == 1 then
                if GAME_POOL_CONFIG[v.subGameId] ~= nil then
                    jackpotStockInfo.jackpotStock = GAME_POOL_CONFIG[v.subGameId].gameTypeInfos[v.roomType].realPoolChips
                    unilight.savedata('jackpotstock',jackpotStockInfo)
                end
            elseif v.poolType == 3 then
                if NameJackMap[v.subGameId] ~= nil then
                    jackpotStockInfo.jackpotStock = NameJackMap[v.subGameId].sessions[v.roomType].realPools
                    unilight.savedata('jackpotstock',jackpotStockInfo)
                end
            end
        end
    end
end

-- 中级场引导
function IntermediateFieldGuidance(uid,gameType)
    if gameType ~= 1 then
        return
    end
    -- 玩家携带金币
    local score = chessuserinfodb.RUserChipsGet(uid)
    -- 玩家提现金币
    local totalcovertchips = WithdrawCash.GetWithdrawcashInfo(uid).totalcovertchips
    -- 玩家充值金币
    local totalRechargeChips = chessuserinfodb.GetChargeInfo(uid)
    if (score + totalcovertchips) / totalcovertchips > 1 and totalRechargeChips > 4000 then
        local res = {}
        res["do"] = "Cmd.UserConotrolTipsGame_S"
        res.data = {}
        unilight.sendcmd(uid, res)
    end
end


--广播奖池信息
function BroadcastPoolReward(data)

    local gameId = data.gameId
    local gameType = data.gameType

    local msg = {}
    msg["do"] = "Cmd.AddJackpotInfoGame_S"
    msg.data = data.jackpotInfo
    msg.data.gameType = gameType

    gamecommon.SendMsgToGameType(gameId, gameType, msg)

    gamecommon.SendPoolDataToGameType(gameId, gameType)
    --发送奖池信息统计排行
    local gameConfig = GetGameConfig(gameId, gameType)
    if gameConfig.isRank == 1 then
        
        local jackpotInfo = data.jackpotInfo
        local uid = jackpotInfo.uid
        if uid == 0 then
            uid = jackpotInfo.robotId
        end
        local betMoney = 0

        jackpotInfo.gameId = gameId
        jackpotInfo.gameType = gameType
        jackpotInfo.uid = uid


        jackpotInfo.timestamp = os.time()
        local lineNum = GetGameLineNum(gameId) or 1
        local rankValue = 0

        --判断是否是机器人
        if uid > 10000000 then
            local betConfig = GetBetConfig(gameType, lineNum)
            -- print(table2json(betConfig))
            -- betMoney = betConfig[1]             --机器人固定取1档次1
            --随机一个奖池图标
            local randomIdx = math.random(1, table.maxn(betConfig))
            betMoney = betConfig[randomIdx]

            --机器人已经是单线倍数
            rankValue =  math.floor(jackpotInfo.chips / betMoney)
        else
            betMoney = GetBetMoneyByGame(uid, gameId, gameType)
            rankValue =  math.floor(jackpotInfo.chips / betMoney)
        end

        --排名值(单线下注的多少倍)
        jackpotInfo.rankValue = rankValue
        -- print("rankValue="..rankValue)
        -- unilight.info(table.tostring(data.jackpotInfo))
        ChessToLobbyMgr.SendCmdToLobby("Cmd.JackpotRankInfoGame_CS", data.jackpotInfo)

    end
end


--获得游戏线数
function GetGameLineNum(gameId)
    local lineNum = 1
    local gameMgr = GetGameMgr(gameId)
    if gameMgr ~= nil then
        lineNum = gameMgr.LineNum
    end
    return lineNum
end

--获得下注金额(单线)
function GetBetMoneyByGame(uid, gameId, gameType)
    local betMoney = 0
    local gameMgr = GetGameMgr(gameId)
    if gameMgr ~= nil then
        local gameInfo = gameMgr.Get(gameType, uid)
        if gameInfo ~= nil then
            local betIndex = gameInfo.betIndex or gameInfo.betindex or 1
            local lineNum = gameMgr.LineNum
            local betConfig = GetBetConfig(gameType, lineNum)
            betMoney = betConfig[betIndex]
        end
    else
        unilight.error("获得下注金额找不到游戏配置:"..gameId)
    end
    return betMoney

end


-- 首充之后删除游戏信息
function DelGameInfo(uid)
    for gameId, dbName in pairs(storecatch.tableMap) do
        unilight.delete(dbName,uid)
    end
    storecatch.ClearStore(uid)
end

--通用发送
function SendGlobalMsgTip(uid,data)
    SendNet(uid,'GlobalMsgTip_S',data)
end