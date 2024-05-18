module('goldenunicorn', package.seeall)
Table                     = 'game101goldenunicorn'
LineNum                   = 25
GameId                    = 101
--GOLDENUNICORN
table_101_paytable        = import 'table/game/101/table_101_paytable'
table_101_payline         = import 'table/game/101/table_101_payline'
table_101_normalspin      = import 'table/game/101/table_101_normalspin'
table_101_freespin        = import 'table/game/101/table_101_freespin'
table_101_other           = import 'table/game/101/table_101_other'
table_101_freeset         = import 'table/game/101/table_101_freeset'
table_101_bonus           = import 'table/game/101/table_101_bonus'
table_101_bonusmul        = import 'table/game/101/table_101_bonusmul'
table_101_jackpot_chips   = import 'table/game/101/table_101_jackpot_chips'
table_101_jackpot_add_per = import 'table/game/101/table_101_jackpot_add_per'
table_101_jackpot_bomb    = import 'table/game/101/table_101_jackpot_bomb'
-- table_101_jackpot_scale   = import 'table/game/101/table_101_jackpot_scale'
table_101_jackpot_bet     = import 'table/game/101/table_101_jackpot_bet'

W = 90 --彩马wild
W1 = 91 --白马普通wild
S = 70
U = 80
J = 100

function Get(gameType, uid)
    local datainfos = unilight.getdata(Table, uid)
    if table.empty(datainfos) then
        datainfos = {
            _id = uid,
            roomInfo = {},
            gameType = 0,
        }
        unilight.savedata(Table, datainfos)
    end
    if table.empty(datainfos.roomInfo[gameType]) then
        local rInfo = {
            betindex = 1,
            betMoney = 0,
            free = {},
            bonus = {},
            bres={},
        }
        datainfos.roomInfo[gameType] = rInfo
        unilight.update(Table, datainfos._id, datainfos)
    end
    local datainfo = datainfos.roomInfo[gameType]
    --lampgame.AddLampData(123,1,1,1)
    return datainfo, datainfos
end

--进入普通游戏
function Normal(gameId, gameType, betindex, datainfo, datainfos)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betMoney = betconfig[betindex]
    local chip = betMoney * LineNum
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = 1,
            desc = '下注参数错误',
        }
    end
    --执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB, chip, "黄金独角兽玩法投注")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    gamecommon.ReqGamePoolBet(gameId, gameType, chip)
    local sTime = os.time()
    local result,newdatainfo= gamecontrol.RealCommonRotate(datainfos._id, gameId, gameType, false, datainfo, chip, CommonRotate,AheadBonus)
    datainfos.roomInfo[gameType] = newdatainfo
    datainfo=newdatainfo
    if table.empty(result.jackpot) == false then
        AddJackpotHisoryTypeOne(datainfos._id, gameType, result.jackpot.iconNum, result.jackpotChips)
    end
    local boards = {}
    table.insert(boards, result.chessdata)
    local winLines = {}
    table.insert(winLines, result.winLines)
    local free = PackFree(datainfo)
    if table.empty(free) == false then
        free.tringerPoints = result.tringerPoints
    end
    local res = {
        errno = 0,
        betIndex = betindex,
        bAllLine = LineNum,
        payScore = chip,
        winScore = result.winScore,
        winLines = winLines,
        boards = boards,
        features = {
            free = free,
            bonus = PackBonus(datainfo),
            jackpot = result.jackpot,
        },
    }
    BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, result.winScore + result.jackpotChips,
        Const.GOODS_SOURCE_TYPE.GOLDENUNICORN)
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        sTime,
        gameId,
        gameType,
        chip,
        remainder + chip,
        chessuserinfodb.RUserChipsGet(datainfos._id),
        0,
        { type = 'normal', chessdata = result.chessdata },
        result.jackpot
    )
    unilight.update(Table, datainfos._id, datainfos)
    return res
end
function Free(gameId, gameType, datainfo, datainfos)
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(datainfos._id)
    local chip = datainfo.betMoney * LineNum
    local result,newdatainfo = gamecontrol.RealCommonRotate(datainfos._id, gameId, gameType, true, datainfo, chip, CommonRotate,AheadBonus)
    datainfos.roomInfo[gameType] = newdatainfo
    datainfo = newdatainfo
    if table.empty(result.jackpot) == false then
        AddJackpotHisoryTypeOne(datainfos._id, gameType, result.jackpot.iconNum, result.jackpotChips)
    end
    local boards = {}
    table.insert(boards, result.chessdata)
    local winLines = {}
    table.insert(winLines, result.winLines)
    datainfo.free.lackTimes = datainfo.free.lackTimes - 1
    -- datainfo.free.tWinScore = datainfo.free.tWinScore + result.winScore + result.jackpotChips
    datainfo.free.tWinScore = datainfo.free.tWinScore + result.winScore
    if result.jackpotChips > 0 then
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, result.jackpotChips,
            Const.GOODS_SOURCE_TYPE.GOLDENUNICORN)
    end
    local free = PackFree(datainfo)
    if table.empty(free) == false then
        free.tringerPoints = result.tringerPoints
    end
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        bAllLine = LineNum,
        payScore = datainfo.betMoney * LineNum,
        winScore = result.winScore,
        tringerPoints = result.tringerPoints,
        winLines = winLines,
        boards = boards,
        features = {
            free = free,
            bonus = PackBonus(datainfo),
            jackpot = result.jackpot,
        },
    }
    if datainfo.free.lackTimes <= 0 and table.empty(datainfo.bonus) then
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, datainfo.free.tWinScore,
            Const.GOODS_SOURCE_TYPE.GOLDENUNICORN)
        -- datainfo.free = {}
    end
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        sTime,
        gameId,
        gameType,
        datainfo.betMoney * LineNum,
        reschip,
        chessuserinfodb.RUserChipsGet(datainfos._id),
        0,
        { type = 'free', chessdata = result.chessdata, totalTimes = free.totalTimes, lackTimes = free.lackTimes,
            tWinScore = free.tWinScore },
        result.jackpot
    )
    if datainfo.free.lackTimes <= 0 and table.empty(datainfo.bonus) then
        datainfo.free = {}
    end
    unilight.update(Table, datainfos._id, datainfos)
    return res
end
-- 预计算bonus
function AheadBonus(uid,gameType,datainfo)
    local bonus = datainfo.bonus
    local iconid = 0
    local mul = 0
    local winScore = 0
    local table_bonus = goldenunicorn['table_101_bonus_'..gameType]
    local table_bonusmul = goldenunicorn['table_101_bonusmul_'..gameType]
    -- local lackTimes =  datainfo.bonus.lackTimes
    if bonus.znum <= 0 then
        local tmul = bonus.tmul + 1
        local r = math.random(100)
        if r <= table_bonus[bonus.tmul].gailv then
            --结束
            iconid = 3
            bonus.lackTimes = 0
        else
            bonus.tmul = tmul
            bonus.znum = math.random(table_bonus[bonus.tmul].znum, table_bonus[bonus.tmul].fanwei)
            iconid = 2
        end
    else
        bonus.znum = bonus.znum - 1
        iconid = 1
        mul = table_bonusmul[gamecommon.CommRandInt(table_bonusmul, 'gailv')].mul
        winScore = math.floor(mul * datainfo.betMoney * LineNum * bonus.tmul)
        bonus.tWinScore = bonus.tWinScore + winScore
    end
    datainfo.bonus.iconid = iconid
    datainfo.bonus.mul = mul
    datainfo.bonus.winScore = winScore
    -- if table.empty(datainfo.free) == false then
    --     datainfo.free.tWinScore = datainfo.free.tWinScore + winScore
    -- end
    datainfo.bres = datainfo.bres or {}
    table.insert(datainfo.bres,table.clone(datainfo.bonus))
    local tWinScore,lackTimes = datainfo.bonus.tWinScore,datainfo.bonus.lackTimes
    return tWinScore,lackTimes
end


--   1 绿水晶  2 蓝水晶  3 红水晶
function Bonus(gameType, datainfo, datainfos)
    local bonus = datainfo.bres[1]
    datainfo.bonus = bonus
    table.remove(datainfo.bres,1)
    local boards = {}
    table.insert(boards, bonus.chessdata)
    local winScore =  datainfo.bonus.winScore
    local iconid = datainfo.bonus.iconid
    local mul = datainfo.bonus.mul
    local reschip = chessuserinfodb.RUserChipsGet(datainfos._id)
    local bon = PackBonus(datainfo)
    bon.extraData.iconid = datainfo.bonus.iconid
    bon.extraData.mul = datainfo.bonus.mul
    if bonus.lackTimes <= 0 then
        if table.empty(datainfo.free) then
            BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, datainfo.bonus.tWinScore,
                Const.GOODS_SOURCE_TYPE.GOLDENUNICORN)
        else
            if datainfo.free.lackTimes <= 0 then
                BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, datainfo.free.tWinScore+datainfo.bonus.tWinScore,
                    Const.GOODS_SOURCE_TYPE.GOLDENUNICORN)
                datainfo.free = {}
            else
                datainfo.free.tWinScore = datainfo.free.tWinScore + datainfo.bonus.tWinScore
            end
        end
        datainfo.bonus = {}
    end
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        os.time(),
        GameId,
        gameType,
        datainfo.betMoney * LineNum,
        reschip,
        chessuserinfodb.RUserChipsGet(datainfos._id),
        0,
        { type = 'bonus', iconid = iconid, mul = mul, totalTimes = bon.totalTimes, lackTimes = bon.lackTimes,
            tWinScore = bon.tWinScore },
        {}
    )
    unilight.update(Table, datainfos._id, datainfos)
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        bAllLine = LineNum,
        payScore = datainfo.betMoney * LineNum,
        winScore = winScore,
        boards = boards,
        features = {
            free = PackFree(datainfo),
            bonus = bon,
        },
    }
    return res
end

--通用旋转
function CommonRotate(uid, gameId, gameType, isfree, datainfo)
    local res = {
        chessdata = {}, --初始棋盘
        winLines = {},
        winScore = 0,
        tringerPoints = {},
        jackpotChips = 0,
        jackpot = {},
    }
    local spin ={}
    
    if isfree then
        spin = goldenunicorn['table_101_freespin_'..gameType]
    else
        local betinfo={
            betindex = datainfo.betindex,
            betchips = datainfo.betMoney * LineNum,
            gameType = gameType,
            gameId = gameId,
        }
        spin = gamecommon.GetSpin(uid, gameId, gameType,betinfo)
    end
    local cols = { 3, 3, 3, 3, 3 }
    res.chessdata = gamecommon.CreateSpecialChessData(cols, spin)
    GmProcess(uid, gameId, gameType, res.chessdata, datainfo)
    --获得奖励
    local bSucess, iconNum, jackpotChips = gamecommon.GetGamePoolChips(gameId, gameType, datainfo.betindex)
    if bSucess then
        res.jackpot = {
            lackTimes = 0,
            totalTimes = 1,
            tWinScore = jackpotChips,
            tringerPoints = {},
            iconNum = iconNum,
        }
        for col = 1, iconNum do
            local r = math.random(3)
            res.chessdata[col][r] = J
            table.insert(res.jackpot.tringerPoints, { line = col, row = r })
        end
        res.jackpotChips = jackpotChips
        --第一列
        for r=1,3 do
            if res.chessdata[1][r] ~= J then
                res.chessdata[1][r] = math.random(1,3)
            end
        end
        for r=1,3 do
            if res.chessdata[2][r] ~= J then
                res.chessdata[2][r] = math.random(4,6)
            end
        end
    end
    local jackFill = gamecommon.FillJackPotIcon:New(5, 3, bSucess, GameId)
    local fNum, tringerPoints = CalcFreeNum(res.chessdata)
    if fNum < 3 then
        res.tringerPoints = {}
    else
        res.tringerPoints = tringerPoints
        for _, value in ipairs(res.tringerPoints) do
            jackFill:FillExtraIcon(value.line, value.row)
        end
    end
    --进行棋盘wild变化
    local dchessdata = ChangeWild(res.chessdata)
    local uNum = 0
    for col = 1, #dchessdata do
        for row = 1, #dchessdata[col] do
            if dchessdata[col][row] == U then
                uNum = uNum + 1
                jackFill:FillExtraIcon(col, row)
            end
        end
    end
    if fNum >= 3 then
        --触发免费
        local freenum = table_101_freeset[fNum].num
        if isfree then
            datainfo.free.totalTimes = datainfo.free.totalTimes + freenum
            datainfo.free.lackTimes = datainfo.free.lackTimes + freenum
        else
            datainfo.free = { totalTimes = freenum, lackTimes = freenum, tWinScore = 0 }
        end
    end
    if uNum >= 3 then
        --触发bonus
        local table_bonus = goldenunicorn['table_101_bonus_'..gameType]
        local znum = math.random(table_bonus[1].znum, table_bonus[1].fanwei)
        datainfo.bonus = { totalTimes = 1, lackTimes = 1, tWinScore = 0, chessdata = dchessdata, tmul = 1, znum = znum }
    end
    local wild = {}
    wild[W] = 1
    wild[W1] = 1
    local nowild = {}
    nowild[U] = 1
    nowild[S] = 1
    --计算本次中奖金额
    local resdata = gamecommon.WiningLineFinalCalc(dchessdata, table_101_payline, table_101_paytable, wild, nowild)
    for _, value in ipairs(resdata) do
        local winScore = 0
        winScore = value.mul * datainfo.betMoney
        local wmul = 1
        for _, v in ipairs(value.iconval) do
            if v == W then
                --winScore = winScore * 2
                wmul = wmul * 2
            end
        end
        winScore = winScore * wmul
        res.winScore = res.winScore + winScore
        table.insert(res.winLines, { value.line, value.num, winScore, value.ele })
        jackFill:PreWinData(value.winicon)
    end
    local posArrays = jackFill:CreateFinalChessData(res.chessdata, J)
    for _, value in ipairs(posArrays) do
        dchessdata[value[1]][value[2]] = J
    end
    return res
end

--计算免费次数
function CalcFreeNum(chessdata)
    local tringerPoints = {}
    local fNum = 0
    --从左至右逻辑
    for col = 1, #chessdata do
        local bFind = false
        for row = 1, #chessdata[col] do
            if chessdata[col][row] == S then
                fNum = fNum + 1
                bFind = true
                table.insert(tringerPoints, { line = col, row = row })
                break
            end
        end
        if bFind == false then
            break
        end
    end
    if fNum >= 3 then
        return fNum, tringerPoints
    end
    fNum = 0
    tringerPoints = {}
    --从右至左逻辑
    for col = #chessdata, 1, -1 do
        local bFind = false
        for row = 1, #chessdata[col] do
            if chessdata[col][row] == S then
                fNum = fNum + 1
                bFind = true
                table.insert(tringerPoints, { line = col, row = row })
                break
            end
        end
        if bFind == false then
            break
        end
    end
    return fNum, tringerPoints
end
function ChangeWild(chessdata)
    local dchessdata = table.clone(chessdata)
    --1 3行wild处理
    for col = 1, #dchessdata do
        if dchessdata[col][1] == W or dchessdata[col][3] == W then
            if dchessdata[col][2] == J then
                if dchessdata[col][1] == W then
                    chessdata[col][1] = math.random(6)
                    dchessdata[col][1] = math.random(6)
                end
                if dchessdata[col][3] == W then
                    chessdata[col][3] = math.random(6)
                    dchessdata[col][3] = math.random(6)
                end
            else
                --彩马
                dchessdata[col][2] = W
            end
        end
    end
    return dchessdata
end

--添加奖池历史
function AddJackpotHisoryTypeOne(uid, gameType, iconNum, jackpotChips)
    gamecommon.AddJackpotHisory(uid, GameId, gameType, iconNum, jackpotChips, {})
    local userinfo = unilight.getdata('userinfo', uid)
    lampgame.AddLampData(uid, userinfo.base.nickname, GameId, jackpotChips, 1)
end
