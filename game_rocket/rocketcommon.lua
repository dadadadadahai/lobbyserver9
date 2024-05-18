module('rocket', package.seeall)
MapRoom = {} --等级桌子对象
MapUser = {} --用户对象
GameId = 202
table_202_sessions = import 'table/game/202/table_202_sessions'
table_202_gailv = import 'table/game/202/table_202_gailv'
table_202_other = import 'table/game/202/table_202_other'
table_202_stock = import 'table/game/202/table_202_stock'

table_202ad_adnum = import 'table/game/202/table_202ad_adnum'
table_202ad_gold = import 'table/game/202/table_202ad_gold'
table_202ad_quit = import 'table/game/202/table_202ad_quit'
table_202ad_bTime = import 'table/game/202/table_202ad_bTime'
table_202ad_bNum = import 'table/game/202/table_202ad_bNum'
table_202ad_bili = import 'table/game/202/table_202ad_bili'
table_202ad_area = import 'table/game/202/table_202ad_area'
table_202ad_ctr = import 'table/game/202/table_202ad_ctr'

local statusDefine = {
    Free = 1,
    Betting = 2, --下注阶段
    Sellte = 3, --结算阶段
}
--计算当前服务器结束倍数
function CalcFinMul(Table)
    local stockcfg = table_202_stock[#table_202_stock]
    local StockPercent = Table.Stock / table_202_sessions[Table.RoomId].initStock * 100
    --print('StockPercent='..StockPercent)
    for index, value in ipairs(table_202_stock) do
        if StockPercent >= value.low and StockPercent <= value.up then
            stockcfg = value
            break
        end
    end
    if StockPercent > table_202_stock[1].up then
        stockcfg = table_202_stock[1]
    end
    local gailvcfg = table_202_gailv[gamecommon.CommRandInt(table_202_gailv, 'gailv')]
    local low, up = gailvcfg.low * 100, gailvcfg.up * 100
    local finMul = math.random(low, up) / 100
    local xs = 1
    local realManBet = 0
    for key, value in pairs(Table.CurGames) do
        if Table.PlayMap[key].IsRobot == false then
            realManBet = value.chip + realManBet
            xs = stockcfg.xs
            break
        end
    end
    finMul = finMul * xs
    if realManBet > 0 then
        local maxmul = Table.Stock / realManBet
        if finMul > maxmul then
            finMul = maxmul
        end
    end
    finMul = finMul - finMul % 0.01
    --print('finMul='..finMul..',Stock='..Table.Stock..',xs='..stockcfg.xs)
    return finMul
end

--计算服务器当前倍数
function UpMul(timeNow, Table)
    local A = table_202_other[Table.RoomId].A
    local B = table_202_other[Table.RoomId].B
    local sTime = Table.TableStatus.sTime
    local min = timeNow - sTime
    local Y = A ^ min - B
    Y = Y - Y % 0.01
    if Y < 0 then
        Y = 0
    end
    Table.CurMul = Y
end

--启动游戏
function Init()
    local roomCfg = chessroominfodb.GetRoomAllInfo(go.gamezone.Gameid)
    local timeNow = os.msectime() / 1000
    for _, v in ipairs(roomCfg) do
        local gameType = v.roomId % 10
        MapRoom[gameType] = {
            PlayMap = {}, --玩家信息记录   {uid,IsRobot,headurl,gender,nickname,isDrop}  --betinfo 下注信息
            Stock = table_202_sessions[gameType].initStock,
            RoomId = gameType,
            HisTory = {}, --历史记录,最近20局爆炸倍数
            TableStatus = { status = statusDefine.Free, sTime = timeNow, eTime = table_202_sessions[gameType].freeTime + timeNow }, --服务器处于的状态,启动时间，结束时间
            CurGames = {}, --当局结算用户信息[uid]={bet,settleMul,settleScore,settleMin}      --结算时候的秒数
            CurMul = 0, --服务器当前倍数
            FinMul = 0, --结束倍数
            latestBrdTime = 0,
            tax = 0,
            decval = 0, --累计衰减值
        }
        local robot = gamecommon.Robot:New(
            rocket,
            MapRoom[gameType],
            table_202_other[gameType].bets,
            table_202ad_adnum,
            table_202ad_gold,
            table_202ad_quit,
            table_202ad_bTime,
            table_202ad_bNum,
            table_202ad_bili,
            table_202ad_area
        )
        MapRoom[gameType].robot = robot
        MapRoom[gameType].finMul = CalcFinMul(MapRoom[gameType])
        --产生20局的游戏记录
        for i = 1, 20 do
            local gailvcfg = table_202_gailv[gamecommon.CommRandInt(table_202_gailv, 'gailv')]
            local lowgailv, upgailv = gailvcfg.low, gailvcfg.up
            local x = math.random(lowgailv, upgailv)
            x = x - x % 0.01
            table.insert(MapRoom[gameType].HisTory, x)
        end
        gamecommon.RegisterStockDec(GameId, gameType, MapRoom[gameType], table_202_other[gameType])
    end
    unilight.addtimermsec("rocket.Pluse", 100)
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
    local betinfo = {}
    --获取玩家基本信息
    local PlayMap = Table.PlayMap
    if PlayMap[uid] ~= nil then
        PlayMap[uid].isDrop = false
        betinfo = Table.CurGames[uid]
    else
        local userinfo = unilight.getdata('userinfo', uid)
        PlayMap[uid] = {
            IsRobot = false,
            headurl = userinfo.base.headurl,
            gender = userinfo.base.gender,
            nickname = userinfo.base.nickname,
            isDrop = false,
        }
    end
    -- local PlayInfo={}
    -- for k, v in pairs(Table.PlayMap) do
    --     table.insert(PlayInfo,{uid=k,headurl=v.headurl,gender=v.gender,nickname=v.nickname,betinfo = Table.CurGames[k]})
    -- end
    local curgames = {} --服务器当局下注情况
    for key, value in pairs(Table.CurGames) do
        table.insert(curgames,
            { uid = key, bet = value.bet, settleMul = value.settleMul, settleScore = value.settleScore, chip = value.chip,
                settleMin = value.settleMin, nickname = value.nickname, headurl = value.headurl,
                bTaxScore = value.bTaxScore })
    end
    --广播玩家进入消息
    local doInfo = 'Cmd.RocketNewEnterCmd_S'
    local sdata = {
        uid = uid,
        headurl = PlayMap[uid].headurl,
        gender = PlayMap[uid].gender,
        nickname = PlayMap[uid].nickname,
        betinfo = betinfo,
    }
    CmdMsgBrdExceptMe(doInfo, uid, sdata, gameType)
    MapUser[uid] = Table
    gamecommon.UserLoginGameInfo(uid, GameId, gameType)
    return {
        errno = ErrorDefine.SUCCESS,
        status = Table.TableStatus.status,
        sTime = Table.TableStatus.sTime,
        eTime = Table.TableStatus.eTime,
        curMul = Table.CurMul,
        betinfo = betinfo,
        curgames = curgames,
        history = Table.HisTory,
        betLow = table_202_sessions[gameType].betLow,
        minBet = table_202_sessions[gameType].minBet,
        maxBet = table_202_sessions[gameType].maxBet,
    }
end

--处理押注信息
function Betting(gameType, chip, uid)
    local Table = MapRoom[gameType]
    local playinfo = Table.PlayMap[uid]
    if playinfo == nil then
        return {
            errno = ErrorDefine.ERROR_PARAM
        }
    end
    if playinfo.IsRobot == false then
        local tchip = chessuserinfodb.RUserChipsGet(uid)
        if tchip < table_202_sessions[gameType].betLow then
            return {
                errno = ErrorDefine.NOT_ENOUGHTCHIPS,
                param = table_202_sessions[gameType].betLow,
            }
        end
    end
    if chip < table_202_sessions[gameType].minBet or chip > table_202_sessions[gameType].maxBet then
        return {
            errno = ErrorDefine.Rocket_ExCeedBet
        }
    end
    if Table.TableStatus.status ~= statusDefine.Betting then
        return {
            errno = ErrorDefine.Rocket_NotInBetting
        }
    end
    if Table.CurGames[uid] ~= nil then
        return {
            errno = ErrorDefine.Rocket_Beted
        }
    end
    if playinfo.IsRobot == false then
            --进入充值判定
        if chessuserinfodb.GetChargeInfo(uid) <= 0 then
            return {
                errno = ErrorDefine.NO_RECHARGE,
                -- param = table_202_sessions[gameType].betCondition,
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
        local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, chip, "火箭玩法投注")
        if ok == false then
            return {
                errno = ErrorDefine.CHIPS_NOT_ENOUGH
            }
        end
    end
    Table.CurGames[uid] = { chip = chip, settleMul = 0, settleMin = 0, settleScore = 0, nickname = playinfo.nickname,
        headurl = playinfo.headurl, bTaxScore = 0 }
    --广播用户的下注信息
    local doInfo = 'Cmd.RocketBetBrdCmd_S'
    local senddata = {
        errno = ErrorDefine.SUCCESS,
        uid = uid,
        chip = chip,
        nickname = playinfo.nickname,
        headurl = playinfo.headurl,
    }
    CmdMsgBrdExceptMe(doInfo, uid, senddata, gameType)
    return {
        errno = ErrorDefine.SUCCESS
    }
end

--点击结算按钮
function ClickSettle(gameType, uid)
    local Table = MapRoom[gameType]
    local playinfo = Table.PlayMap[uid]
    if playinfo == nil then
        return {
            errno = ErrorDefine.ERROR_PARAM
        }
    end
    if Table.TableStatus.status ~= statusDefine.Sellte then
        return {
            errno = ErrorDefine.Rocket_NotInSettle
        }
    end
    if Table.CurGames[uid] == nil then
        return {
            errno = ErrorDefine.Rocket_NotBet
        }
    end
    local betinfo = Table.CurGames[uid]
    if betinfo.settleMul > 0 or betinfo.settleScore > 0 then
        return {
            errno = ErrorDefine.Rocket_Settled
        }
    end
    local timeNow = os.msectime() / 1000
    local A = table_202_other[Table.RoomId].A
    local B = table_202_other[Table.RoomId].B
    local sTime = Table.TableStatus.sTime
    local min = timeNow - sTime
    local Y = A ^ min - B
    Y = Y - Y % 0.01
    if Y < 0 then
        Y = 0
    end
    local winScore = betinfo.chip * Y
    if playinfo.IsRobot == false then
        Table.Stock = Table.Stock + (betinfo.chip - winScore)
    end
    -- print(string.format('Stock=%d',Table.Stock))
    if Table.Stock <= 0 then
        Table.FinMul = Y
    end
    local btaxWinscore = winScore
    local awinScore    = math.floor(winScore * (1 - table_202_other[gameType].hiddenTax / 100))
    local tax          = winScore - awinScore
    winScore           = awinScore
    if playinfo.IsRobot == false then
        local rtchip = winScore - betinfo.chip
        if rtchip > 0 then
            WithdrawCash.AddBet(uid, rtchip)
        elseif rtchip < 0 then
            rtchip = math.abs(rtchip)
            cofrinho.AddCofrinho(uid, rtchip)
        end
        local rchip = chessuserinfodb.RUserChipsGet(uid) + betinfo.chip
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, winScore, Const.GOODS_SOURCE_TYPE.Rocket)
        Table.tax = Table.tax + tax
        gameDetaillog.SaveDetailGameLog(
            uid,
            os.time(),
            GameId,
            Table.RoomId,
            betinfo.chip,
            rchip,
            chessuserinfodb.RUserChipsGet(uid),
            tax,
            {
                type = 'normal',
                settleTime = min,
                settleMul = Y,
                settleScore = winScore,
            },
            {}
        )
    end
    betinfo.bTaxScore   = btaxWinscore
    betinfo.settleMul   = Y
    betinfo.settleScore = winScore
    betinfo.settleMin   = min
    betinfo.headurl     = playinfo.headurl
    --广播信息
    local doInfo        = 'Cmd.RocketSettleBrdCmd_S'
    local sdata         = {
        errno = ErrorDefine.SUCCESS,
        uid = uid,
        nickname = playinfo.nickname,
        headurl = playinfo.headurl,
        betinfo = betinfo,
    }
    CmdMsgBrdExceptMe(doInfo, uid, sdata, gameType)

    return {
        errno = ErrorDefine.SUCCESS,
        betinfo = betinfo,
    }
end

--桌子帧循环执行
function PluseDo(roomId, Table)
    local timeNow = os.msectime() / 1000
    local TableStatus = Table.TableStatus
    --    local TriggerNext = false
    if TableStatus.status == statusDefine.Free and timeNow >= TableStatus.eTime then
        TableStatus.status = statusDefine.Betting
        TableStatus.sTime = timeNow
        TableStatus.eTime = table_202_sessions[roomId].bettingTime + timeNow
        --空间时间结束
        local doInfo = 'Cmd.RocketChangeStatusBrdCmd_S'
        local sdata = {
            errno = ErrorDefine.SUCCESS,
            status = TableStatus.status,
            sTime = timeNow,
            eTime = timeNow + table_202_sessions[roomId].bettingTime,
        }
        RobotClientTime(Table.robot)
        Table.robot:ChangeToBetting()
        CmdMsgBrd(doInfo, sdata, roomId)
    elseif TableStatus.status == statusDefine.Betting and timeNow >= TableStatus.eTime then
        --执行结算
        Table.FinMul = CalcFinMul(Table)

        TableStatus.status = statusDefine.Sellte
        TableStatus.sTime = timeNow
        local doInfo = 'Cmd.RocketChangeStatusBrdCmd_S'
        local sdata = {
            errno = ErrorDefine.SUCCESS,
            status = TableStatus.status,
            sTime = timeNow,
            eTime = 0,
        }
        Table.robot:ChangeToSettle({})
        CmdMsgBrd(doInfo, sdata, roomId)
    elseif TableStatus.status == statusDefine.Sellte then
        --计算状态
        UpMul(timeNow, Table)
        local res = {
            curMul = Table.CurMul,
            Isbreak = false,
        }
        local sTime, eTime = nil, nil
        if Table.CurMul >= Table.FinMul then
            gamecommon.AddGamesCount(GameId, roomId)
            res.Isbreak = true
            --加入历史记录
            table.insert(Table.HisTory, Table.CurMul)
            table.remove(Table.HisTory, 1)
            --进行入库结算
            for uid, value in pairs(Table.CurGames) do
                local playinfo = Table.PlayMap[uid]
                if playinfo ~= nil and value.settleMul == 0 and value.settleScore == 0 and playinfo.IsRobot == false then
                    Table.Stock = Table.Stock + value.chip
                    if playinfo ~= nil and playinfo.IsRobot == false then
                        local betinfo = value
                        if betinfo.settleScore <= 0 and betinfo.chip > 0 then
                            cofrinho.AddCofrinho(uid, betinfo.chip)
                        end
                        --玩家日志处理
                        gameDetaillog.SaveDetailGameLog(
                            uid,
                            os.time(),
                            GameId,
                            Table.RoomId,
                            value.chip,
                            chessuserinfodb.RUserChipsGet(uid) + value.chip,
                            chessuserinfodb.RUserChipsGet(uid),
                            0,
                            {
                                type = 'normal',
                                settleTime = 0,
                                settleMul = 0,
                                settleScore = 0,
                            },
                            {}
                        )
                    end
                end
                if playinfo ~= nil and playinfo.isDrop then
                    Table.PlayMap[uid] = nil
                    local userData = chessuserinfodb.GetUserDataById(uid)
                    IntoGameMgr.ClearUserCurStatus(userData)
                    UserLeavel(uid, roomId.RoomId)
                    gamecommon.UserLogoutGameInfo(uid, GameId, roomId.RoomId)
                end
            end
            RobotClientTime(Table.robot)
            Table.CurGames = {}
            TableStatus.status = statusDefine.Free
            TableStatus.sTime = timeNow
            TableStatus.eTime = timeNow + table_202_sessions[roomId].freeTime
            sTime = timeNow
            eTime = timeNow + table_202_sessions[roomId].freeTime
        else
            --不爆炸的情况
            RobotClick(timeNow, Table)
        end
        if timeNow - Table.latestBrdTime >= 1 or res.Isbreak then
            local doInfo = 'Cmd.RocketSettleProcessBrdCmd_S'
            local sdata = {
                errno = ErrorDefine.SUCCESS,
                curMul = Table.CurMul,
                Isbreak = res.Isbreak,
                status = TableStatus.status,
                sTime = sTime,
                eTime = eTime,
            }
            CmdMsgBrd(doInfo, sdata, roomId)
            Table.latestBrdTime = timeNow
        end
        if res.Isbreak then
            Table.CurMul = 0
        end
    end
    Table.robot:Pluse(timeNow)
end

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
    local PlayMap = roomInfo.PlayMap
    local uinfo = PlayMap[uid]
    if uinfo ~= nil then
        local isExist = true
        if roomInfo.CurGames[uid] ~= nil then
            isExist      = false
            uinfo.isDrop = true
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
    CmdMsgBrd('Cmd.RocketUserLeavelCmd_S', send, gameType)
end

------------------------------------广播---------------------------------------

-- 广播包装
function CmdMsgBrd(doInfo, data, roomId)
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
function CmdMsgBrdExceptMe(doInfo, uid, data, roomId)
    local roomInfo = MapRoom[roomId]
    local PlayMap = roomInfo.PlayMap
    local send = {}
    send['do'] = doInfo
    send['data'] = data
    for key, value in pairs(PlayMap) do
        if value.IsRobot == false and value.isDrop == false and key ~= uid then
            unilight.sendcmd(key, send)
        end
    end
end
