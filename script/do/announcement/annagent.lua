module('annagent', package.seeall)  

GameOnline = nil
DB_GLOBAL_NAME = "global"
--每个大区用户在线数据
game_zone_online_list = {}
--每个大区游戏类型在线人数
game_zone_gametype_online = {}

function BroadCastAgent()
end

-- 当前人数获取这块 不合理 后期统一处理
function BroadCastGameOnline()
    local lobbyOnlineNum = 0
    local onlineinfo = go.gameonlineinfo
    local doInfo  = "Cmd.GameOnlineNumLbyCmd_Brd"
    local gameOnline = {}

    for k, v  in pairs(onlineinfo) do
        unilight.info(string.format("在线统计: gameid:%d, online:%d",k, v))
    end
    data = {}
    data.gameOnline = gameOnline
    data.lobbyOnlineNum = lobbyOnlineNum

    -- 数据缓存 留待前端主动请求时推送
    GameOnline = data

    -- 不广播了
	-- chesstcplib.TcpMsgSendEveryOne(doInfo, data)
end


--计算在线峰值
function CaleOnlineInfo()
    RoomInfo.BroadcastToAllZone("Cmd.ReqZoneOnlineListLobby_CS", {})

    --统计大厅在线人数
    local onlineList = go.accountmgr.GetOnlineList()
    local uids = {}
    local uidList = {}
    for i=1, #onlineList do
        UserInfo.Loop(onlineList[i])
        local userInfo = chessuserinfodb.RUserInfoGet(onlineList[i])
        local gameInfo = userInfo.gameInfo
        local userInfo = {
            uid = onlineList[i],
            subGameId = gameInfo.subGameId,
            subGameType = gameInfo.subGameType,
            subplatid   = gameInfo.subplatid
        }
        table.insert(uids, userInfo)
        table.insert(uidList,onlineList[i] )
    end

    table.sort(uidList, function(a, b)
        return a > b
    end)
    -- unilight.info("大厅在线玩家列表:"..table2json(uidList))

    SetZoneInfoList(unilight.getgameid(), unilight.getzoneid(), uids)


    --所有在线统计
    local onlineInfo = unilight.getdata(DB_GLOBAL_NAME, Const.GLOBAL_DB_TYPE.ONLINE)
    if table.empty(onlineInfo) then
        -- 需要初始化
        onlineInfo = {
            _id = Const.GLOBAL_DB_TYPE.ONLINE,
            todayOnline = 0, 
            yestedayOnline = 0,
            lastDay = chessutil.GetMorningDayNo(),
            
        }
        unilight.savedata(DB_GLOBAL_NAME, onlineInfo)
    end

    local curDay = chessutil.GetMorningDayNo()
    if curDay ~= onlineInfo.lastDay then
        onlineInfo.lastDay = curDay
        --昨日在线更新
        onlineInfo.yestedayOnline = onlineInfo.todayOnline
        --今日在线重置
        onlineInfo.todayOnline = 0
    end

    --各个子游戏在线统计
    local gameOnlineInfo = unilight.getdata(DB_GLOBAL_NAME, Const.GLOBAL_DB_TYPE.GAME_ONLINE)
    if table.empty(gameOnlineInfo) then
        -- 需要初始化
        gameOnlineInfo = {
            _id = Const.GLOBAL_DB_TYPE.GAME_ONLINE,
            gameOnlines = {},
            lastDay = chessutil.GetMorningDayNo(),
            
        }
        unilight.savedata(DB_GLOBAL_NAME, gameOnlineInfo)
    end


    local curDay = chessutil.GetMorningDayNo()
    if curDay ~= gameOnlineInfo.lastDay then
        gameOnlineInfo.lastDay = curDay
        --今日在线重置
        gameOnlineInfo.gameOnlines = {}
    end


    -- local onlineinfo = go.gameonlineinfo
    local totalOnlineNum  = table.len(uids)
--
    -- for gameId, onlineNum  in pairs(onlineinfo) do
        -- totalOnlineNum = totalOnlineNum + onlineNum
    -- end

    local all_game_online = {} 
    local game_zone_game_online_list = GetGameTypeOnline()-- {"1002":{"302":{"1":{"subGameType":1,"onlineNum":1,"subGameId":111}}}}
    
    for gameId, zone_game_online_list in pairs(game_zone_game_online_list) do
        for zoneId, game_online_list in pairs(zone_game_online_list) do
            for _, onlineInfos in pairs(game_online_list) do
                all_game_online[onlineInfos.subGameId] = all_game_online[onlineInfos.subGameId] or {}
                all_game_online[onlineInfos.subGameId][onlineInfos.subGameType] = all_game_online[onlineInfos.subGameId][onlineInfos.subGameType] or 0
                all_game_online[onlineInfos.subGameId][onlineInfos.subGameType] = all_game_online[onlineInfos.subGameId][onlineInfos.subGameType] + onlineInfos.onlineNum
                totalOnlineNum = totalOnlineNum + onlineInfos.onlineNum
            end
        end
    end

    -- unilight.info("子游戏在线信息:"..table2json(all_game_online))
    for subGameId, game_online_list in pairs(all_game_online)  do
        for subGameType, onlineNum in pairs(game_online_list)  do
            gameOnlineInfo.gameOnlines[subGameId] = gameOnlineInfo.gameOnlines[subGameId] or {}
            gameOnlineInfo.gameOnlines[subGameId][subGameType] = gameOnlineInfo.gameOnlines[subGameId][subGameType] or 0
            if onlineNum > gameOnlineInfo.gameOnlines[subGameId][subGameType] then
                gameOnlineInfo.gameOnlines[subGameId][subGameType] = onlineNum
            end
        end

    end


    if totalOnlineNum > onlineInfo.todayOnline then
        onlineInfo.todayOnline = totalOnlineNum
    end

    -- unilight.info("全部在线人数:"..onlineInfo.todayOnline)
    unilight.savedata(DB_GLOBAL_NAME, onlineInfo)
    unilight.savedata(DB_GLOBAL_NAME, gameOnlineInfo)

    if unilight.REDISDB ~= nil then
        local zone_user_online_list = GetOnlineUids()
        unilight.redis_setdata(Const.REDIS_HASH_NAME.ONLINE_INFO, table2json(zone_user_online_list))
        unilight.redis_setexpire(Const.REDIS_HASH_NAME.ONLINE_INFO, 60)
    end

end

--设置每个区服在线人数
--获取区服信息
function SetZoneInfoList(gameId, zoneId, uids)
    -- unilight.info(string.format("区服在线, gameId:%d, zoneId:%d, online:%d", gameId, zoneId, table.len(uids)))
    if game_zone_online_list[gameId] == nil then
        game_zone_online_list[gameId] = {}
    end
    --value = {"uid":2152552,"regFlag":2,"rechargeFlag":1,"subGameType":1,"subplatid":5,"subGameId":110}
    -- for _, value in ipairs(uids) do
    --     print('uid',table2json(value))
    -- end
    -- print('gameId zoneId',gameId,zoneId)
    -- local taskZone = unizone.getzonetaskbygameidzonid(gameId,zoneId)
    -- unilight.success(taskZone, {test=22222})
    game_zone_online_list[gameId][zoneId] = uids
end

function CleanZoneInfolist(gameId, zoneId)
    if game_zone_online_list[gameId] ~= nil and game_zone_online_list[gameId][zoneId]  ~= nil then
        game_zone_online_list[gameId][zoneId] = nil
    end
    if game_zone_gametype_online[gameId] ~= nil and game_zone_gametype_online[gameId][zoneId] ~= nil then
        game_zone_gametype_online[gameId][zoneId] = nil
    end
end

--获得指定区在线人数
function GetZoneOnlineNum(gameId, zoneId)
    if game_zone_online_list[gameId] == nil or game_zone_online_list[gameId][zoneId] == nil then
        return 0
    end

    local onlineNum = table.len(game_zone_online_list[gameId][zoneId])
    return onlineNum
end

--设置每个区子游戏在线人数
function SetZoneGameTypeOnline(gameId, zoneId, gameOnlineNum)
    -- unilight.info(string.format("区服游戏类型在线, gameId:%d, zoneId:%d, online:%s", gameId, zoneId, table2json(gameOnlineNum)))
    if game_zone_gametype_online[gameId] == nil then
        game_zone_gametype_online[gameId] = {}
    end
    game_zone_gametype_online[gameId][zoneId] = gameOnlineNum
end




--获得在线人数
function GetOnlineInfo()

    local onlineInfo = unilight.getdata(DB_GLOBAL_NAME, Const.GLOBAL_DB_TYPE.ONLINE)
    if table.empty(onlineInfo) then
        -- 需要初始化
        onlineInfo = {
            _id = Const.GLOBAL_DB_TYPE.ONLINE,
            todayOnline = 0, 
            yestedayOnline = 0,
            lastDay = chessutil.GetMorningDayNo(),
            
        }
        unilight.savedata(DB_GLOBAL_NAME, onlineInfo)
    end

    return onlineInfo.todayOnline, onlineInfo.yestedayOnline
end


--获得在线玩家列表
function GetOnlineUids()
    return game_zone_online_list
end

--获得游戏类型在线列表
function GetGameTypeOnline()
    return game_zone_gametype_online
end

--获得指定游戏在线玩家数量
function GetOnlineNumByGameId(gameId, gameType)
    local gameOnlineInfo = unilight.getdata(DB_GLOBAL_NAME, Const.GLOBAL_DB_TYPE.GAME_ONLINE)
    if gameOnlineInfo == nil then
        return 0
    end

    if gameOnlineInfo.gameOnlines[gameId] ~= nil and gameOnlineInfo.gameOnlines[gameId][gameType] ~= nil then
        return gameOnlineInfo.gameOnlines[gameId][gameType]
    end
    return 0
end

