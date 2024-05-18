--逻辑处理函数
module('WorldCup', package.seeall)
table_206_sessions = import 'table/game/206/table_206_sessions'
table_206_gailv = import 'table/game/206/table_206_gailv'
table_206_other = import 'table/game/206/table_206_other'
table_206_stock = import 'table/game/206/table_206_stock'

table_206ad_adnum = import 'table/game/206/table_206ad_adnum'
table_206ad_gold = import 'table/game/206/table_206ad_gold'
table_206ad_quit = import 'table/game/206/table_206ad_quit'
table_206ad_bTime = import 'table/game/206/table_206ad_bTime'
table_206ad_bNum = import 'table/game/206/table_206ad_bNum'
table_206ad_bili = import 'table/game/206/table_206ad_bili'
table_206ad_area = import 'table/game/206/table_206ad_area'
GameId = 206
Maps = { 5, 2, 6, 3, 7, 4, 8, 1, 5, 2, 6, 3, 7, 4, 8, 1, 5, 2, 6, 3, 7, 4, 8, 1 }
local statusDefine = {
    Free = 1,
    Betting = 2,
    Sellte = 3,
}
MapRoom = {}
MapUser = {} --用户对象
--初始化模块
function Init()
    --执行房间状态初始化
    local roomCfg = chessroominfodb.GetRoomAllInfo(go.gamezone.Gameid)
    local timeNow = os.time()
    for _, v in ipairs(roomCfg) do
        local gameType = v.roomId % 10
        local tmpTable = {
            PlayMap        = {}, --玩家信息记录   {uid,bets,IsRobot,headurl,gender,nickname,isDrop,laccount}
            Stock          = table_206_sessions[gameType].initStock,
            RoomId         = gameType,
            HisTory        = {},                                        --历史记录
            TableStatus    = {
                status = statusDefine.Free,
                sTime = timeNow,
                eTime = table_206_other[gameType].FreeTime + timeNow
            },                                                          --服务器处于的状态,启动时间，结束时间
            TableBets      = { 0, 0, 0, 0, 0, 0, 0, 0 },                --当前桌面的区域押注信息,8个位置
            OtherTableBets = { 0, 0, 0, 0, 0, 0, 0, 0 },                --除开旁坐下注值
            RealManBet     = { 0, 0, 0, 0, 0, 0, 0, 0 },
            TmpBet         = {},                                        --[] {{area,chip}}   --规定时间内的投注缓存
            robot          = {},
            tax            = 0,
            decval         = 0,  --累计衰减值
            latelyRecord   = {}, --近20局信息记录{{{uid,bet,win}}}
            leftSit        = {}, --左边位置  赢钱最多的
            rightSit       = {}, --获胜场次  最多
            betRank        = {}, --下注排行榜
            hundredObj     = gamecommon.HundredPeople:New(GameId, gameType, CmdMsgBrd),
        }
        MapRoom[gameType] = tmpTable
        local robot = gamecommon.Robot:New(
            WorldCup,
            tmpTable,
            table_206_other[gameType].bets,
            table_206ad_adnum,
            table_206ad_gold,
            table_206ad_quit,
            table_206ad_bTime,
            table_206ad_bNum,
            table_206ad_bili,
            table_206ad_area
        )
        tmpTable.robot = robot
        for i = 1, 100 do
            --MapRoom[gameType].HisTory=math.random(8)
            table.insert(MapRoom[gameType].HisTory, gamecommon.CommRandInt(table_206_gailv, 'gailv'))
        end
        gamecommon.RegisterStockDec(GameId, gameType, MapRoom[gameType], table_206_other[gameType])
    end
    --启动定时器
    unilight.addtimermsec("WorldCup.Pluse", 1000)
end

function lobbyconnect()
    for key, value in pairs(MapRoom) do
        value.robot:RequestRebot()
    end
end

function RspRobotList(data)
    local gameType = data.params
    local Table = MapRoom[gameType]
    if Table ~= nil then
        Table.robot:RspRobotList(data)
    end
end

--获取场景信息
function Scene(gameType, laccount, uid)
    local Table = MapRoom[gameType]
    if Table == nil then
        return {
            errno = ErrorDefine.ERROR_PARAM
        }
    end
    --获取玩家基本信息
    local PlayMap = Table.PlayMap
    local bets = { 0, 0, 0, 0, 0, 0, 0, 0 }
    if PlayMap[uid] ~= nil then
        PlayMap[uid].isDrop = false
        bets = PlayMap[uid].bets
    else
        local userinfo = unilight.getdata('userinfo', uid)
        PlayMap[uid] = {
            bets = bets,
            IsRobot = false,
            headurl = userinfo.base.headurl,
            gender = userinfo.base.gender,
            nickname = userinfo.base.nickname,
            isDrop = false,
        }
    end
    local PlayInfo = {}
    for k, v in pairs(Table.PlayMap) do
        --local chip 	= chessuserinfodb.RUserChipsGet(k)
        table.insert(PlayInfo, { uid = k, headurl = v.headurl, gender = v.gender, nickname = v.nickname })
    end
    --广播玩家进入消息
    local doInfo = 'Cmd.WorldCupNewEnterCmd_S'
    local sdata = {
        uid = uid,
        headurl = PlayMap[uid].headurl,
        gender = PlayMap[uid].gender,
        nickname = PlayMap[uid].nickname,
    }
    local umap = {}
    umap[uid] = 1
    CmdMsgBrdExceptMe(doInfo, umap, sdata, gameType)
    MapUser[uid] = Table
    gamecommon.UserLoginGameInfo(uid, GameId, gameType)
    return {
        errno = ErrorDefine.SUCCESS,
        tableBets = Table.TableBets,
        bets = table_206_other[gameType].bets, --下载配置
        status = Table.TableStatus.status,
        sTime = Table.TableStatus.eTime - os.time(),
        curBets = bets,
        curNum = Table.hundredObj:get(),
        -- playInfo=PlayInfo,
        history = Table.HisTory,
        betLow = table_206_sessions[gameType].betLow,
        leftSit = Table.leftSit,
        rightSit = Table.rightSit,
    }
end

function WorldCupGetRankCmd_C(gameType, uid)
    local Table = MapRoom[gameType]
    local playinfo = Table.PlayMap[uid]
    -- 进入下注记录
    if playinfo == nil then
        return {
            errno = ErrorDefine.ERROR_PARAM
        }
    end
    local res = {
        errno = ErrorDefine.SUCCESS,
        betRank = Table.betRank
    }
    return res
end

--处理押注信息
function Betting(gameType, betinfo, uid)
    local Table = MapRoom[gameType]
    local playinfo = Table.PlayMap[uid]
    local allBet = 0
    for i = 1, #playinfo.bets do
        allBet = allBet + playinfo.bets[i]
    end
    -- 进入下注记录
    if playinfo == nil then
        return {
            errno = ErrorDefine.ERROR_PARAM
        }
    end
    if playinfo.IsRobot == false then
        if allBet <= 0 then
            local chip = chessuserinfodb.RUserChipsGet(uid)
            if chip < table_206_sessions[gameType].betLow then
                return {
                    errno = ErrorDefine.NOT_ENOUGHTCHIPS,
                    param = table_206_sessions[gameType].betLow
                }
            end
        end
    end
    if Table.TableStatus.status ~= statusDefine.Betting then
        return {
            errno = ErrorDefine.WorldCup_NotInBetting
        }
    end
    local area, betIndex = betinfo[1], betinfo[2]
    local betchip = table_206_other[gameType].bets[betIndex]
    if betchip == nil then
        return {
            errno = ErrorDefine.ERROR_PARAM
        }
    end
    local TableBets = Table.TableBets

    if allBet + betchip > table_206_sessions[gameType].maxBet then
        return {
            errno = ErrorDefine.WorldCup_MAXBET
        }
    end
    if playinfo.IsRobot == false then
        --进入充值判定
        if chessuserinfodb.GetChargeInfo(uid) <= 0 then
            return {
                errno = ErrorDefine.NO_RECHARGE,
                -- param = table_206_sessions[gameType].betCondition,
            }
        end
        -- --进入充值判定
        -- if nvipmgr.GetVipLevel(uid) <= 0 then
        --     return {
        --         errno = ErrorDefine.NOT_ENOUGHTVIPLEVEL,
        --         param = 1,
        --     }
        -- end
        -- 扣除
        local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, betchip, "世界杯玩法投注")
        if ok == false then
            return {
                errno = ErrorDefine.CHIPS_NOT_ENOUGH
            }
        end
    end
    playinfo.bets[area] = playinfo.bets[area] + betchip

    TableBets[area] = TableBets[area] + betchip

    if playinfo.IsRobot == false then
        Table.RealManBet[area] = Table.RealManBet[area] + betchip
    end
    local TmpBet = Table.TmpBet
    if TmpBet[uid] == nil then
        local betsSingle = {}
        local singleBet = { area, betchip }
        table.insert(betsSingle, singleBet)
        TmpBet[uid] = betsSingle
    else
        local betsSingle = TmpBet[uid]
        local insert = true
        for _, value in ipairs(betsSingle) do
            if value[1] == area then
                value[2] = value[2] + betchip
                insert = false
                break
            end
        end
        if insert then
            table.insert(betsSingle, { area, betchip })
        end
    end
    --Cmd.WorldCupSideBetCmd_S          旁坐玩家下注信息
    local isSide = false
    for i = 1, 3 do
        if Table.leftSit[i] ~= nil and Table.leftSit[i].uid == uid then
            isSide = true
            break
        elseif Table.rightSit[i] ~= nil and Table.rightSit[i].uid == uid then
            isSide = true
            break
        end
    end
    if isSide then
        local binfo = {}
        table.insert(binfo, { area, betchip })
        local brd = {
            errno = ErrorDefine.SUCCESS,
            uid = uid,
            binfo = binfo
        }
        CmdMsgBrd('Cmd.WorldCupSideBetCmd_S', brd, gameType)
    else
        Table.OtherTableBets[area] = Table.OtherTableBets[area] + betchip
    end
    --下注处理完毕
    return {
        errno = ErrorDefine.SUCCESS
    }
end

--批量下注
function WorldCupBatchBetCmd_S(gameType, betinfo, uid)
    local Table = MapRoom[gameType]
    -- 进入下注记录
    local playinfo = Table.PlayMap[uid]
    if playinfo == nil then
        return {
            errno = ErrorDefine.ERROR_PARAM
        }
    end
    local chip = chessuserinfodb.RUserChipsGet(uid)
    if chip < table_206_sessions[gameType].betLow then
        return {
            errno = ErrorDefine.NOT_ENOUGHTCHIPS,
            param = table_206_sessions[gameType].betLow,
        }
    end
    if Table.TableStatus.status ~= statusDefine.Betting then
        return {
            errno = ErrorDefine.WorldCup_NotInBetting
        }
    end
    -- local TableBets = Table.TableBets
    local allBet = 0
    local betAllChip = 0
    for _, v in ipairs(playinfo.bets) do
        allBet = allBet + v
    end
    for i = 1, 8 do
        allBet = allBet + betinfo[i]
        betAllChip = betAllChip + betinfo[i]
    end
    if allBet > table_206_sessions[gameType].maxBet then
        return {
            errno = ErrorDefine.WorldCup_MAXBET
        }
    end
    --进入充值判定
    if chessuserinfodb.GetChargeInfo(uid) <= 0 then
        return {
            errno = ErrorDefine.NO_RECHARGE,
            -- param = table_206_sessions[gameType].betCondition,
        }
    end
    -- --进入充值判定
    -- if nvipmgr.GetVipLevel(uid) <= 0 then
    --     return {
    --         errno = ErrorDefine.NOT_ENOUGHTVIPLEVEL,
    --         param = 1,
    --     }
    -- end
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, betAllChip, "世界杯玩法投注")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH
        }
    end
    for index, value in ipairs(betinfo) do
        Table.RealManBet[index] = Table.RealManBet[index] + value
        Table.TableBets[index] = Table.TableBets[index] + value
        playinfo.bets[index] = playinfo.bets[index] + value
    end
    --Cmd.WorldCupSideBetCmd_S          旁坐玩家下注信息
    local isSide = false
    for i = 1, 3 do
        if Table.leftSit[i] ~= nil and Table.leftSit[i].uid == uid then
            isSide = true
            break
        elseif Table.rightSit[i] ~= nil and Table.rightSit[i].uid == uid then
            isSide = true
            break
        end
    end
    if isSide then
        local binfo = {}
        for index, value in ipairs(betinfo) do
            if value > 0 then
                table.insert(binfo, { index, value })
            end
        end
        local brd = {
            errno = ErrorDefine.SUCCESS,
            uid = uid,
            binfo = binfo
        }
        CmdMsgBrd('Cmd.WorldCupSideBetCmd_S', brd, gameType)
    else
        for index, value in ipairs(betinfo) do
            Table.OtherTableBets[index] = Table.OtherTableBets[index] + value
        end
    end
    local TmpBet = Table.TmpBet
    if TmpBet[uid] == nil then
        local betsSingle = {}
        for index, value in ipairs(betinfo) do
            if value > 0 then
                local singleBet = { index, value }
                table.insert(betsSingle, singleBet)
            end
        end
        TmpBet[uid] = betsSingle
    else
        local betsSingle = TmpBet[uid]
        for index, value in ipairs(betinfo) do
            local insert = true
            for _, v in ipairs(TmpBet[uid]) do
                if v[1] == index and value > 0 then
                    v[2] = v[2] + value
                    insert = false
                    break
                end
            end
            if insert then
                table.insert(TmpBet[uid], { index, value })
            end
        end
    end
    --下注处理完毕
    return {
        errno = ErrorDefine.SUCCESS
    }
end

--桌子对象
function PluseDo(roomId, Table)
    local timeNow = os.time()
    Table.hundredObj:calc(timeNow)
    local TableStatus = Table.TableStatus
    local TriggerNext = false
    if timeNow >= TableStatus.eTime then
        --切换到下一阶段
        TableStatus.status = TableStatus.status + 1
        if TableStatus.status > 3 then
            TableStatus.status = statusDefine.Free
        end
        TableStatus.sTime = timeNow
        local statusStr = ''
        if TableStatus.status == statusDefine.Free then
            statusStr = 'FreeTime'
            gamecommon.AddGamesCount(GameId, roomId)
        elseif TableStatus.status == statusDefine.Betting then
            statusStr = 'bettingTime'
            Table.robot:ChangeToBetting()
        elseif TableStatus.status == statusDefine.Sellte then
            statusStr = 'SettleTime'
        end
        TableStatus.eTime = timeNow + table_206_other[roomId][statusStr]
        TriggerNext = true
        --触发广播阶段发送
        local doInfo = 'Cmd.WorldCupChangeStatusCmd_S'
        local sdata = {
            errno = ErrorDefine.SUCCESS,
            status = TableStatus.status,
            sTime = timeNow,
            eTime = TableStatus.eTime,
        }
        CmdMsgBrd(doInfo, sdata, roomId)
    end
    Table.robot:Pluse(timeNow)
    if TableStatus.status == statusDefine.Betting or (TriggerNext and TableStatus.status == statusDefine.Sellte) then
        --正在下注阶段执行下注广播
        --local TmpBet = Table.TmpBet
        -- local bets=table_206_other[1].bets
        -- for i=1,8 do
        --     Table.TableBets[i]=Table.TableBets[i] + table_206_other[1].bets[math.random(#bets)]
        -- end
        local boarddata = {
            -- TableBets = Table.TableBets,
            TableBets = Table.OtherTableBets
            --singleBetInfo={},
        }
        -- for k, v in pairs(TmpBet) do
        --     table.insert(boarddata.singleBetInfo,{uid=k,data=v})
        -- end
        CmdMsgBrd('Cmd.WorldCupBetListRoomCmd_S', boarddata, roomId)
        Table.TmpBet = {}
    end
    if TableStatus.status == statusDefine.Sellte and TriggerNext then
        --触发结算
        local result = Settle(Table)
        --进入历史记录
        table.insert(Table.HisTory, result.nId)
        table.remove(Table.HisTory, 1)
        SellteResult(result, Table)
    end
end

--执行定时脉冲 500ms 执行一次
function Pluse()
    for k, v in pairs(MapRoom) do
        PluseDo(k, v)
    end
end

function Drop(roomuser)
    if roomuser == nil then
        unilight.error("调用断线 但是roomuser为nil")
        return
    end
    local uid = roomuser.Id
    local roomInfo = MapUser[uid]
    if roomInfo == nil then
        return
    end
    local PlayMap = roomInfo.PlayMap
    local uinfo = PlayMap[uid]
    if uinfo ~= nil then
        local isExist = true
        for _, value in ipairs(uinfo.bets) do
            if value > 0 then
                isExist = false
                uinfo.isDrop = true
                break
            end
        end
        MapUser[uid] = nil
        --chesstcplib.TcpUserRoomOut(roomInfo.BrdRoom, uinfo.laccount)
        if isExist then
            --执行退出
            PlayMap[uid] = nil
            local userData = chessuserinfodb.GetUserDataById(uid)
            IntoGameMgr.ClearUserCurStatus(userData)
            gamecommon.UserLogoutGameInfo(uid, GameId, roomInfo.RoomId)
            UserLeavel(uid, roomInfo.RoomId)
        end
    end
end

--广播用户离开
function UserLeavel(uid, gameType)
    local send = {}
    send = {
        errno = ErrorDefine.SUCCESS,
        uid = uid,
    }
    CmdMsgBrd('Cmd.WorldCupUserLeavelCmd_S', send, gameType)
end

------------------------------------广播---------------------------------------

-- 广播包装
function CmdMsgBrd(doInfo, data, roomId)
    -- local gameType = roomId % 10
    -- local roomInfo = MapRoom[gameType]
    -- if roomInfo.BrdRoom ~= nil then
    -- 	chesstcplib.TcpRoomInfoBrd(roomInfo.BrdRoom, doInfo, data)
    -- end
    local roomInfo = MapRoom[roomId]
    local PlayMap = roomInfo.PlayMap
    local send = {}
    send['do'] = doInfo
    send['data'] = data
    for key, value in pairs(PlayMap) do
        if value.IsRobot == false and value.isDrop == false then
            unilight.sendcmd(key, send)
        end
    end
end

-- 广播包装
function CmdMsgBrdExceptMe(doInfo, uidmap, data, roomId)
    local roomInfo = MapRoom[roomId]
    local PlayMap = roomInfo.PlayMap
    local send = {}
    send['do'] = doInfo
    send['data'] = data
    for key, value in pairs(PlayMap) do
        if value.IsRobot == false and value.isDrop == false and uidmap[key] == nil then
            unilight.sendcmd(key, send)
        end
    end
end
