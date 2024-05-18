module('cacaNiQuEls', package.seeall)
stockMap = {} -- 库存保存 [场次] = 数值
GameId = 204
table_204_sessions = import 'table/game/204/table_204_sessions'
table_204_other = import 'table/game/204/table_204_other'
table_204_stockctr = import 'table/game/204/table_204_stockctr'
table_204_gailv = import 'table/game/204/table_204_gailv'
table_204_redluck = import 'table/game/204/table_204_redluck'
table_204_blueluck = import 'table/game/204/table_204_blueluck'
table_204_train = import 'table/game/204/table_204_train'

table_204_jackpot_chips = import 'table/game/204/table_204_jackpot_chips'
table_204_jackpot_add_per = import 'table/game/204/table_204_jackpot_add_per'
table_204_jackpot_bomb = import 'table/game/204/table_204_jackpot_bomb'
-- table_204_jackpot_scale = import 'table/game/204/table_204_jackpot_scale'
table_204_jackpot_bet = import 'table/game/204/table_204_jackpot_bet'


maps = {4,8,15,16,2,1,6,10,9,101,2,3,4,8,13,14,2,5,6,11,12,100,2,7}
-- betCfg={2,4,6,8,10,12,14,16}
betCfg = { { 1, 2 }, { 3, 4 }, { 5, 6 }, { 7, 8 }, { 9, 10 }, { 11, 12 }, { 13, 14 }, { 15, 16 } }
sessionsPlayNum = {}
iconMulMap = {}
--[[
    下注区域
    bets 从右至左
]]
function Normal(gameType, bets, uid)
    if table.empty(iconMulMap) then
        for _, value in ipairs(table_204_gailv) do
            iconMulMap[value.iconid] = value.mul
        end
    end
    local chip = chessuserinfodb.RUserChipsGet(uid)
    local enterLow = table_204_sessions[gameType].enterLow
    local enterLimit = table_204_sessions[gameType].enterLimit
    if chessuserinfodb.RUserChipsGet(uid)<table_204_sessions[gameType].betCondition then
        return{
            errno=ErrorDefine.NOT_ENOUGHTCHIPS,
            param = table_204_sessions[gameType].betCondition,
        }
    end
    if chip < enterLow and enterLow > 0 then
        return {
            errno = ErrorDefine.cacaNiQuEls_EnterLow
        }
    end
    if chip > enterLimit and enterLimit > 0 then
        return {
            errno = ErrorDefine.cacaNiQuEls_enterLimit
        }
    end
    local minBet = table_204_sessions[gameType].minBet
    local tolNum = 0
    for i = 1, #betCfg do
        local num = bets[i]
        if num > table_204_other[gameType].areaMaxNum then
            return {
                errno = ErrorDefine.ERROR_AREALIMIT
            }
        end
        tolNum = tolNum + num
    end
    local betChip = tolNum * minBet
    --进入充值判定
    if chessuserinfodb.GetChargeInfo(uid) <= 0 then
        return {
            errno = ErrorDefine.NO_RECHARGE,
            -- param = table_204_sessions[gameType].betCondition,
        }
    end
        -- --进入充值判定
        -- if nvipmgr.GetVipLevel(uid) <= 0 then
        --     return {
        --         errno = ErrorDefine.NOT_ENOUGHTVIPLEVEL,
        --         param = 1,
        --     }
        -- end
    -- 扣减金币
    local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, betChip, "老虎机玩法投注")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH
        }
    end
    gamecommon.ReqGamePoolBet(GameId, gameType, betChip)
    local sysWin = JudgeWinOrLost(gameType)
    local result= {}
    while true do
        result = CalcFinallResult(gameType, sysWin, bets, betChip)
        local rchange = stockMap[gameType].Stock + betChip * (1 - table_204_jackpot_add_per[1].addRealPoolPer /
        10000) - result.WinScore
        if rchange>=0 or sysWin==1 then
            break
        else
            sysWin=1
        end
    end

    local jackpot = {}
    --取倍数
    local bSucess, iconNum, jackpotChips = gamecommon.GetGamePoolChips(GameId, gameType, tolNum)
    if bSucess then
        jackpot = {
            lackTimes     = 0,
            totalTimes    = 0,
            tWinScore     = jackpotChips,
            tringerPoints = {},
        }
    end
    -- 进行库存加减
    stockMap[gameType].Stock = stockMap[gameType].Stock + betChip * (1 - table_204_jackpot_add_per[1].addRealPoolPer /
        10000) - result.WinScore
    gamecommon.AddGamesCount(GameId,gameType)
    local tax = 0
    if result.WinScore > 0 then
        local aWinScore = math.floor(result.WinScore * (100 - table_204_other[gameType].tax) / 100)
        tax = result.WinScore - aWinScore
        result.WinScore = aWinScore
    end
    local rchip = result.WinScore+jackpotChips - betChip
    if rchip>0 then
        WithdrawCash.AddBet(uid,rchip)
    elseif rchip<0 then
        rchip = math.abs(rchip)
        cofrinho.AddCofrinho(uid,rchip)
    end
    local rchip1 = chessuserinfodb.RUserChipsGet(uid)
    -- 执行金币变化
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, result.WinScore + jackpotChips,
        Const.GOODS_SOURCE_TYPE.cacaNiQuEls)
    stockMap[gameType].tax = stockMap[gameType].tax + tax

            --记录日志
    gameDetaillog.SaveDetailGameLog(
        uid,
        os.time(),
        GameId,
        gameType,
        betChip,
        rchip1 + betChip,
        chessuserinfodb.RUserChipsGet(uid),
        tax,
        {type='normal',iconid = result.iconid,mul = result.mul,position = result.position,redLuckType = result.redLuckType,
        redIconInfo = result.redIconInfo,trainInfo = result.trainInfo },
        jackpot
    )
    -- 返回
    return {
        errno = 0,
        betIndex = 1,
        payScore = betChip,
        winScore = result.WinScore,
        features = {
            jackpot = jackpot,
        },
        extraData = {
            iconid = result.iconid,
            mul = result.mul,
            position = result.position, -- 转动棋盘位置
            redLuckType = result.redLuckType, --0没有 1大三元 2 小三元 3 小四喜
            redIconInfo = result.redIconInfo, --中奖倍数奖励 {iconid ,WinScore})
            trainInfo = result.trainInfo -- 开火车信息{num,infos}
        }
    }
end

-- 判断系统输赢控制
--[[
    0 随机 1系统赢 2系统输
]]
function JudgeWinOrLost(gameType)
    local stock = stockMap[gameType].Stock
    local cfg = table_204_stockctr[1]
    local sysWin = 0
    local percent=0
    percent = stock / table_204_sessions[gameType].initStock*100
    for i = 1, #table_204_stockctr do
        if percent >= table_204_stockctr[i].stockPercentMin and percent <= table_204_stockctr[i].stockPercentMax then
            cfg = table_204_stockctr[i]
            break
        end
    end
    local r = math.random(100)
    if r <= cfg.gailv then
        if cfg.ID >= 4 then
            sysWin = 1      --系统赢
        else
            sysWin = 2
        end
    end
    if stock<0 then
        sysWin=1
    end
    -- print(string.format('stock=%d,cfgID=%d,sysWin=%d,percent=%d',stock,cfg.ID,sysWin,percent))
    return sysWin
end
