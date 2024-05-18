module('cash', package.seeall)
Table = 'game109cash'
GameId = 109
LineNum = 30
Table_Base = import 'table/game/109/table_109_hanglie'
Table_Jackpot = import "table/game/109/table_109_jackpot" -- jackpot奖池

table_109_normalspin = import 'table/game/109/table_109_normalspin'
table_109_jackpot = import 'table/game/109/table_109_jackpot'
table_109_paytable = import 'table/game/109/table_109_paytable'
table_109_payline = import 'table/game/109/table_109_payline'
table_109_freespin = import 'table/game/109/table_109_freespin'
local table_parameter_parameter = import "table/table_parameter_parameter"
local table_stock_tax = import 'table/table_stock_tax'
J = 100
--CASH
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
            iconsMap = {},
            chessdataBetIndex = {}, --下注
        }
        datainfos.roomInfo[gameType] = rInfo
        unilight.update(Table, datainfos._id, datainfos)
    end
    local datainfo = datainfos.roomInfo[gameType]
    return datainfo, datainfos
end

--普通拉动
function Normal(gameType, betindex, datainfo, datainfos, uid)
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
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB, chip, "终极现金玩法投注")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    local sTime = os.time()
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local result = {}
    local addscore = 0
    result, datainfo = gamecontrol.RealCommonRotate(datainfos._id, GameId, gameType, false, datainfo, chip, CommonRotate,
        nil)
    local userinfo = unilight.getdata('userinfo', datainfos._id)
    if result.isOver == false then
        print('result.zmul',result.zmul,result.lzmul)
        addscore = result.winScore
        if result.lzmul>0 then
            addscore = result.winScore - result.lzmul*chip
        end
        result.winScore = result.winScore - result.zmul * chip
        result.zmul = 1
    else
        addscore = (result.winScore - result.zmul * chip)
    end

    --添加库存
    local stockGameType = gameType
    gamestock.RawStock(GameId,gameType,chip,addscore,userinfo)

    userinfo.gameData.slotsWin = userinfo.gameData.slotsWin +result.winScore
    local winScore = result.winScore
    local iconnumchip = 0
    -- local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    for key, value in pairs(datainfo.iconsMap) do
        local iconnum = #value
        local tcfgf = table_109_jackpot[iconnum]
        if tcfgf ~= nil then
            iconnumchip = iconnumchip + betconfig[key] * LineNum * tcfgf.mul
        end
    end
    -- chessuserinfodb.SetAheadScore(uid,iconnumchip)
    userinfo.unsettleInfo = userinfo.unsettleInfo or {}
    local key = GameId * 100 + gameType
    userinfo.unsettleInfo[key] = iconnumchip
    -- print('iconnumchip',iconnumchip)
    unilight.update('userinfo', uid, userinfo)
    local winLines = result.winLines
    local zmul = result.zmul
    local chessdata = result.chessdata
    if result.iconsNum >= 11 then
        gamecommon.AddJackpotHisory(datainfos._id, GameId, gameType, 0, chip * zmul, { mul = zmul })
        --跑马灯数据池
        --lampgame.AddLampData(datainfo._id,GameId,chip * zmul,2)
        local userinfo = unilight.getdata('userinfo', datainfos._id)
        lampgame.AddLampData(datainfos._id, userinfo.base.nickname, GameId, chip * zmul, 2)
    end
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        sTime,
        GameId,
        gameType,
        chip,
        remainder + chip,
        remainder + winScore,
        0,
        { type = 'normal', chessdata = chessdata },
        { zmul = zmul }
    )
    datainfo.chessdataBetIndex[datainfo.betindex] = datainfo.chessdataBetIndex[datainfo.betindex] or {}
    datainfo.chessdataBetIndex[datainfo.betindex] = chessdata
    datainfos.roomInfo[gameType] = datainfo
    local boards = {}
    table.insert(boards, chessdata)
    BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, winScore, Const.GOODS_SOURCE_TYPE.CASH)
    unilight.update(Table, datainfos._id, datainfos)
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        bAllLine = LineNum,
        payScore = datainfo.betMoney * LineNum,
        winScore = winScore,
        winLines = winLines,
        boards = boards,
        extraData = {
            zmul = zmul
        },
    }
    return res
end

function CommonRotate(uid, gameId, gameType, isfree, datainfo)
    local result = {
        chessdata = {},
        winScore = 0,
        zmul = 0,
        lzmul = 0, --上一次的库存
        winLines = {},
        isOver = false,
        iconsNum = 0,
    }
    local betindex = datainfo.betindex
    local chip = datainfo.betMoney * LineNum
    datainfo.iconsMap[betindex] = datainfo.iconsMap[betindex] or {}
    local spin = {}
    local iconsAttach = datainfo.iconsMap[betindex]
    local iconsNum = #iconsAttach
    local userinfo = unilight.getdata('userinfo', uid)
    local chips = chessuserinfodb.GetAHeadTolScore(uid)
    isfree = false
    local isMiddle = false
    if iconsNum >= 3 then
        spin = cash['table_109_freespin_' .. gameType]
        isfree = true
    else
        local betinfo={
            betindex = datainfo.betindex,
            betchips = datainfo.betMoney * LineNum,
            gameType = gameType,
            gameId = gameId,
        }
        spin = gamecommon.GetSpin(uid, GameId, gameType,betinfo)
    end
    local cols = { 4, 4, 4, 4, 4 }
    result.chessdata = gamecommon.CreateSpecialChessData(cols, spin)
    if isMiddle then
        if math.random(100) <= 30 then
            local maxJNum = math.random(2)
            for i = 1, maxJNum do
                local randCol = math.random(#result.chessdata)
                local randRow = math.random(#result.chessdata[randCol])
                result.chessdata[randCol][randRow] = J
            end
        end
    end
    if isfree == false then
        local jNum = 0
        local tmpIcons = {}
        for col = 1, #result.chessdata do
            for row = 1, #result.chessdata[col] do
                if result.chessdata[col][row] == J then
                    jNum = jNum + 1
                    table.insert(tmpIcons, { col, row })
                end
            end
        end
        if jNum >= 3 then
            local jcfg = table_109_jackpot[jNum]
            result.winScore = jcfg.mul * chip
            result.zmul = jcfg.mul
            for _, value in ipairs(tmpIcons) do
                table.insert(iconsAttach, { value[1], value[2] })
            end
        end
    else
        for _, value in ipairs(iconsAttach) do
            result.chessdata[value[1]][value[2]] = J
        end
        local jcfg = table_109_jackpot[iconsNum]
        result.lzmul = jcfg.mul
        local array = { jcfg.new0, jcfg.new1, jcfg.new2, jcfg.new3 }
        local index = gamecommon.CommRandArray(array)
        local tmpcfg = table_109_jackpot[iconsNum + index - 1]
        if userinfo.property.totalRechargeChips <= 0 then
            local noChargeMax = table_parameter_parameter[15].Parameter
            if tmpcfg.mul * chip + chips >= noChargeMax then
                index = 0
            end
        else
            -- local stock = gamestock.GetStock(gameId, gameType)
            -- if tmpcfg.mul * chip > stock then
            --     index = 0
            -- end
            local maxchips = table_parameter_parameter[36].Parameter
            if tmpcfg.mul * chip > maxchips then
                index = 0
            end
            if userinfo.point.chargeMax~=nil and tmpcfg.mul*chip+chips>userinfo.point.chargeMax then
                index = 0
            end
        end
        if index > 1 then
            --要出
            local emptyPos = {}
            for col = 1, #result.chessdata do
                for row = 1, #result.chessdata[col] do
                    if result.chessdata[col][row] ~= J then
                        table.insert(emptyPos, { col, row })
                    end
                end
            end
            index = index - 1
            for i = 1, index do
                if #emptyPos > 0 then
                    local pIndex = math.random(#emptyPos)
                    table.insert(iconsAttach, { emptyPos[pIndex][1], emptyPos[pIndex][2] })
                    result.chessdata[emptyPos[pIndex][1]][emptyPos[pIndex][2]] = J
                    table.remove(emptyPos, pIndex)
                end
            end
            result.winScore = result.winScore + tmpcfg.mul * chip
            result.zmul = tmpcfg.mul
            -- chessuserinfodb.SetAheadScore(datainfos._id,tmpcfg.mul*chip)
        else
            --触发结算
            result.iconsNum = iconsNum
            result.zmul = jcfg.mul
            datainfo.iconsMap[betindex] = {}
            -- chessuserinfodb.AddAheadScore(uid,-result.zmul*chip)
            -- result.winScore = result.winScore + result.zmul*chip
            result.isOver = true
        end
    end
    local wild = {}
    local nowild = {}
    nowild[J] = 1
    result.winLines[1] = {}
    local resdata = gamecommon.WiningLineFinalCalc(result.chessdata, table_109_payline, table_109_paytable, wild, nowild)
    for _, value in ipairs(resdata) do
        result.winScore = result.winScore + value.mul * datainfo.betMoney
        table.insert(result.winLines[1], { value.line, value.num, value.mul * datainfo.betMoney })
    end
    if result.isOver then
        result.winScore = result.winScore + chip * result.zmul
    end
    return result
end
