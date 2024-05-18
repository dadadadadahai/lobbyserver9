module('chilli', package.seeall)
Table = 'game118chilli'
GameId = 118
LineNum = 1
--[[
    无 0
    红 1
    金 2
]]
local Non,red,gold = 1,2,70
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
            respin = {},
            bres = {},
        }
        datainfos.roomInfo[gameType] = rInfo
        unilight.update(Table, datainfos._id, datainfos)
    end
    local datainfo = datainfos.roomInfo[gameType]
    --lampgame.AddLampData(123,1,1,1)
    return datainfo, datainfos
end

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
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB, chip, "辣椒玩法投注")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    gamecommon.ReqGamePoolBet(gameId, gameType, chip)
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local result, newdatainfo = gamecontrol.RealCommonRotate(datainfos._id, gameId, gameType, false, datainfo, chip,
    CommonRotate, nil)
    datainfos.roomInfo[gameType] = newdatainfo
    datainfo = newdatainfo
    local boards = {}
    table.insert(boards, result.chessdata)
    if table.empty(result.jackpot)==false then
        -- gamecommon.ReducePoolChips(gameId,gameType,result.jackpotChips)
        gamecommon.AddJackpotHisory(datainfos._id, GameId, gameType, 15, result.jackpotChips)
    end
    local res = {
        errno = 0,
        betIndex = betindex,
        bAllLine = LineNum,
        payScore = chip,
        winScore = result.winScore,
        winLines = {},
        boards = boards,
        iconsAttachData = result.iconsAttachData,
        features = {
            free = PackRespin(newdatainfo),
            jackpot = result.jackpot,
        },
    }
    BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, result.winScore + result.jackpotChips,
        Const.GOODS_SOURCE_TYPE.Chili)
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        os.time(),
        gameId,
        gameType,
        chip,
        remainder + chip,
        chessuserinfodb.RUserChipsGet(datainfos._id),
        0,
        { type = 'normal', chessdata = result.chessdata, iconsAttachData = result.iconsAttachData },
        result.jackpot
    )
    unilight.update(Table, datainfos._id, datainfos)
    return res
end

--与计算respin
function AheadBonus(uid, gameType, datainfo)
    local respin = datainfo.respin
    local finnum = respin.finnum
    local curnum = 0
    local emptyPos = {}
    for col = 1, #respin.chessdata do
        for row = 1, #respin.chessdata[col] do
            if respin.chessdata[col][row] ~= Non then
                curnum = curnum + 1
            else
                table.insert(emptyPos, { col, row })
            end
        end
    end
    local snum = finnum - curnum
    local gailv = (snum / respin.lackTimes) * 100
    if math.random(100) <= gailv then
        --要出金辣椒
        local realnum = math.floor(snum / respin.lackTimes)
        if realnum <= 0 then
            realnum = 1
        end
        datainfo.respin.lackTimes = datainfo.respin.lackTimes + realnum
        datainfo.respin.totalTimes = datainfo.respin.totalTimes + realnum
        for i = 1, realnum do
            local curPos = gamecommon.ReturnArrayRand(emptyPos)
            respin.chessdata[curPos[1]][curPos[2]] = gold
            local mul = RedIconAttachData(2,false)
            table.insert(respin.iconsAttachData,
            { line = curPos[1], row = curPos[2], mul = mul, gold = datainfo.betMoney * mul * LineNum })
        end
    end
    --计算当前总的tWinScore
    respin.lackTimes = respin.lackTimes - 1
    --统计tWinScore
    local tWinScore = 0
    for index, value in ipairs(respin.iconsAttachData) do
        tWinScore = tWinScore + value.gold
    end
    tWinScore = math.floor(tWinScore)
    respin.tWinScore = tWinScore
    table.insert(datainfo.bres, table.clone(respin))
    if respin.lackTimes <= 0 then
        for _, value in ipairs(datainfo.bres) do
            value.tWinScore = respin.tWinScore
        end
    end
    return respin.tWinScore, respin.lackTimes
end

function Respin(gameType, datainfo, datainfos)
    local respin = datainfo.bres[1]
    datainfo.respin = respin
    table.remove(datainfo.bres, 1)
    local reschip = chessuserinfodb.RUserChipsGet(datainfos._id)
    local boards={}
    table.insert(boards,respin.chessdata)
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        bAllLine = LineNum,
        payScore = 0,
        winScore = 0,
        winLines = {},
        boards = boards,
        features = {
            free = PackRespin(datainfo)
        },
    }
    if datainfo.respin.lackTimes <= 0 then
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, datainfo.respin.tWinScore,
            Const.GOODS_SOURCE_TYPE.Chili)
        datainfo.respin = {}
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
        {
            type = 'free', chessdata = respin.chessdata, iconsAttachData = respin.iconsAttachData
        },
        {}
    )
    unilight.update(Table, datainfos._id, datainfos)
    return res
end

function CommonRotate(uid, gameId, gameType, isfree, datainfo)
    local res = {
        chessdata = {},
        winScore = 0,
        jackpotChips = 0,
        jackpot = {},
        iconsAttachData = {},
    }
    local respinChessdata = {}
    --附加金币
    local respinIconAttachData = {}
    local emptyPos = {}
    for col = 1, 5 do
        res.chessdata[col]={}
        respinChessdata[col]={}
        for row = 1, 3 do
            res.chessdata[col][row] = Non
            respinChessdata[col][row] = Non
            table.insert(emptyPos, { col, row })
        end
    end
    --获取转轴表
    local betinfo={
        betindex = datainfo.betindex,
        betchips = datainfo.betMoney * LineNum,
        gameType = gameType,
        gameId = gameId,
    }
    local spin = gamecommon.GetSpin(uid, GameId, gameType,betinfo)
    local chilliNum = 0
    local bSucess1, jackpotNum, jackpotChips = gamecommon.GetGamePoolChips(GameId, gameType,datainfo.betindex)
    if bSucess1 then
        jackpotChips= math.floor(jackpotChips)
        res.jackpotChips = jackpotChips
        res.jackpot = {
            lackTimes = 0,
            totalTimes = 1,
            tWinScore = jackpotChips,
            tringerPoints = {},
         }
    end
    local goldNum = 0
    local bSucess=false
    -- if bSucess then
    --     chilliNum = 15
    --     if jackpotNum==1 then
    --         goldNum = 0
    --     else
    --         goldNum = 15
    --     end
    --     jackpotChips= math.floor(jackpotChips)
    --     res.jackpotChips = jackpotChips
    --     res.jackpot = {
    --         lackTimes = 0,
    --         totalTimes = 1,
    --         tWinScore = jackpotChips,
    --         tringerPoints = {},
    --      }
    -- else
    chilliNum = spin[gamecommon.CommRandInt(spin, 'gailv')].num
    --金辣椒应该出多少个
    goldNum = table_gold_gailv[gamecommon.CommRandInt(table_gold_gailv, 'j' .. chilliNum)].num
    goldNum =GmProcess(uid,gameType,goldNum)
    for i = 1, goldNum do
        local curPos = gamecommon.ReturnArrayRand(emptyPos)
        res.chessdata[curPos[1]][curPos[2]] = gold
        if chilliNum >= 5 then
            local mul = RedIconAttachData(2,bSucess)
            table.insert(res.iconsAttachData, { line = curPos[1], row = curPos[2], mul = mul,
                gold = datainfo.betMoney * mul * LineNum })
        end
        respinChessdata[curPos[1]][curPos[2]] = gold
        local mul = RedIconAttachData(2,bSucess)
        table.insert(respinIconAttachData, { line = curPos[1], row = curPos[2], mul = mul,
        gold = datainfo.betMoney * mul * LineNum })
    end
    --红辣椒的钱
    for i = 1, chilliNum - goldNum do
        local curPos = gamecommon.ReturnArrayRand(emptyPos)
        res.chessdata[curPos[1]][curPos[2]] = red
        if chilliNum >= 5 then
            local mul = RedIconAttachData(1,bSucess)
            table.insert(res.iconsAttachData, { line = curPos[1], row = curPos[2], mul = mul,
                gold = datainfo.betMoney * mul * LineNum })
        end
    end
    if chilliNum >= 5 then
        for index, value in ipairs(res.iconsAttachData) do
            res.winScore = res.winScore + value.gold
        end
    end
    res.winScore = math.floor(res.winScore)
    --触发respin
    if goldNum >= 3 and bSucess == false then
        --计算最终金辣椒个数
        local finnum = table_respin[gamecommon.CommRandInt(table_respin, 'j' .. goldNum)].num
        datainfo.respin = { totalTimes = goldNum, lackTimes = goldNum, tWinScore = 0, chessdata = respinChessdata,
            finnum = finnum, iconsAttachData = respinIconAttachData }
    end
    return res
end

--[[
    每个红辣椒所带金币
]]
function RedIconAttachData(type, jackSuccess)
    local cfg = {}
    if type == 1 then
        if jackSuccess then
            cfg = table_red_jp
        else
            cfg = table_red_chilli
        end
    else
        if jackSuccess then
            cfg = table_gold_jp
        else
            cfg = table_gold_chilli
        end
    end
    local mul = cfg[gamecommon.CommRandInt(cfg, 'gailv')].mul
    return mul
end
