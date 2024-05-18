module('miner', package.seeall)
GameId = 210
StockMap = {} --类型
Table = 'game210miner'
LineNum = 1
function Get(gameType, uid)
    local datainfos = unilight.getdata(Table, uid)
    if table.empty(datainfos) then
        datainfos = {
            _id = uid,
            roomInfo = {},
        }
        unilight.savedata(Table, datainfos)
    end
    if table.empty(datainfos.roomInfo[gameType]) then
        local rInfo = {
            betMoney = 0, --下注金额
            chessdata = {}, --棋盘
            bombNum = 1, --点几下爆炸
            mineNum = 0, --选择的地雷个数
        }
        datainfos.roomInfo[gameType] = rInfo
        unilight.update(Table, datainfos._id, datainfos)
    end
    local datainfo = datainfos.roomInfo[gameType]
    return datainfo, datainfos
end

--获取场景数据
function GetSceneCmd_C(gameType, uid)
    local datainfo, datainfos = Get(gameType, uid)
    return {
        errno = ErrorDefine.SUCCESS,
        betMoney = datainfo.betMoney, --下注金额
        chessdata = datainfo.chessdata,
        mineNum = datainfo.mineNum,
        minBet = table_210_sessions[gameType].minBet,
        maxBet = table_210_sessions[gameType].maxBet,
        betLow = table_210_sessions[gameType].betLow,
    }
end
--点击确认地雷数，下注等
function Spin(gameType, spindata, uid)
    local datainfo, datainfos = Get(gameType, uid)
    if table.empty(datainfo.chessdata) == false then
        return {
            errno = ErrorDefine.MINER_SPINED
        }
    end
    local betMoney = spindata.betMoney
    local mineNum = spindata.mineNum
    if chessuserinfodb.RUserChipsGet(uid)<table_210_sessions[gameType].betLow then
        return{
            errno=ErrorDefine.NOT_ENOUGHTCHIPS,
            param = table_210_sessions[gameType].betLow,
        }
    end
    if betMoney < table_210_sessions[gameType].minBet or betMoney > table_210_sessions[gameType].maxBet then
        return {
            errno = ErrorDefine.ERROR_PARAM
        }
    end
    if mineNum < 1 or mineNum > 8 then
        return {
            errno = ErrorDefine.ERROR_PARAM
        }
    end
    --进入充值判定
    if chessuserinfodb.GetChargeInfo(uid) <= 0 then
        return {
            errno = ErrorDefine.NO_RECHARGE,
            -- param = table_210_sessions[gameType].betCondition,
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
    local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, betMoney, "地雷玩法投注")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH
        }
    end
    local chessdata = {}
    --信息初始化
    for col = 1, 5 do
        chessdata[col] = {}
        for row = 1, 5 do
            chessdata[col][row] = 0
        end
    end
    local tmpTablecfg = table.clone(table_210_gailv)
    local stockPrcent = StockMap[gameType].Stock / table_210_sessions[gameType].initStock * 100
    local xs = table_210_stock[#table_210_stock].xs
    for _, value in ipairs(table_210_stock) do
        if stockPrcent >= value.low and stockPrcent <= value.up then
            xs = value.xs
            break
        end
    end
    if stockPrcent > table_210_stock[1].up then
        xs = table_210_stock[1].xs
    end
    tmpTablecfg[1]['mine' .. mineNum] = math.floor(tmpTablecfg[1]['mine' .. mineNum]* xs)
    datainfo.bombNum = tmpTablecfg[gamecommon.CommRandInt(tmpTablecfg, 'mine' .. mineNum)].ID
    datainfo.betMoney = betMoney
    datainfo.mineNum = mineNum
    datainfo.chessdata = chessdata
    --执行存档
    unilight.update(Table, datainfos._id, datainfos)
    return {
        errno = ErrorDefine.SUCCESS,
        betMoney = datainfo.betMoney,
        mineNum = datainfo.mineNum,
        chessdata = datainfo.chessdata,
    }
end

--开箱子
function Play(gameType, pointPos, uid)
    local datainfo, datainfos = Get(gameType, uid)
    if table.empty(datainfo.chessdata) then
        return {
            errno = ErrorDefine.MINER_NOSPINED
        }
    end
    local chessdata = datainfo.chessdata
    local col, row = pointPos[1], pointPos[2]
    if chessdata[col][row] == nil or chessdata[col][row] ~= 0 then
        return {
            errno = ErrorDefine.MINER_INVAILD
        }
    end
    local isend = IsEnd(gameType, datainfo)
    local res = {}
    if isend then
        chessdata[col][row] = 2
        --结算
        StockMap[gameType].Stock = StockMap[gameType].Stock +
            datainfo.betMoney * (1 - table_210_other[gameType].hiddenTax / 100)
        res = {
            errno = ErrorDefine.SUCCESS,
            chessdata = chessdata,
            isEnd = true,
        }
        cofrinho.AddCofrinho(uid,datainfo.betMoney)
        gamecommon.AddGamesCount(GameId,gameType)
        --记录日志
        gameDetaillog.SaveDetailGameLog(
            uid,
            os.time(),
            GameId,
            gameType,
            datainfo.betMoney,
            chessuserinfodb.RUserChipsGet(uid) + datainfo.betMoney,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {
                type = 'normal',
                chessdata = chessdata,
                mineNum = datainfo.mineNum
            },
            {}
        )
        --清理恢复数据点
        ReSetSpin(datainfo)
    else
        chessdata[col][row] = 1
        res = {
            errno = ErrorDefine.SUCCESS,
            chessdata = chessdata,
            isEnd = false,
        }
    end
    unilight.update(Table, datainfos._id, datainfos)
    return res
end

--要求结算
function Settle(gameType, uid)
    local datainfo, datainfos = Get(gameType, uid)
    if table.empty(datainfo.chessdata) then
        return {
            errno = ErrorDefine.MINER_NOSPINED
        }
    end
    local chessdata = datainfo.chessdata
    local clicknum = 0
    for c = 1, #chessdata do
        for r = 1, #chessdata[c] do
            if chessdata[c][r] == 1 then
                clicknum = clicknum + 1
            end
        end
    end
    local winScore ,mul          = CalcSettle(datainfo.betMoney, clicknum, datainfo.mineNum)

    if mul>=5 then
        local userinfo = unilight.getdata('userinfo',uid)
        local robotConfig={
            headUrl = userinfo.base.headurl,
            nickName = userinfo.base.nickname,
            chips = 0,
            jackpotNum = nil,
            extData=nil,
            uid = uid,
        }
        local params = {
            gameId = GameId,
            gameType = gameType,
            chips = 0,
            }
            params.extData = {
                -- pool  = randomJackpotId,
                mul   = mul,
            }
        gamecommon.AddRobotJackpotHistory(robotConfig,params)
    end
    --库存改变
    StockMap[gameType].Stock = StockMap[gameType].Stock - (winScore - datainfo.betMoney)
    --结果返回

    local rchip              = chessuserinfodb.RUserChipsGet(uid)
    local tax = math.floor(winScore * (table_210_other[gameType].tax/100))
    winScore = winScore - tax
    StockMap[gameType].tax = StockMap[gameType].tax + tax
    local res                = {
        errno = ErrorDefine.SUCCESS,
        winScore = winScore+tax,
        fWinScore = winScore,
    }
    --加钱
    -- 执行金币变化
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, winScore,Const.GOODS_SOURCE_TYPE.Miner)
    if winScore-datainfo.betMoney>0 then
        -- cofrinho.AddCofrinho(uid,winScore-datainfo.betMoney)
        WithdrawCash.AddBet(uid,winScore-datainfo.betMoney)
    end
    gamecommon.AddGamesCount(GameId,gameType)
    --记录日志
    gameDetaillog.SaveDetailGameLog(
        uid,
        os.time(),
        GameId,
        gameType,
        datainfo.betMoney,
        rchip + datainfo.betMoney,
        chessuserinfodb.RUserChipsGet(uid),
        tax,
        {
            type = 'normal',
            chessdata = chessdata,
            mineNum = datainfo.mineNum
        },
        {}
    )
    ReSetSpin(datainfo)
    unilight.update(Table, datainfos._id, datainfos)
    return res
end

--判断是否结束
-- true 结束  false  不结束
function IsEnd(gameType, datainfo)
    local chessdata = datainfo.chessdata
    local Stock = StockMap[gameType].Stock
    local clicknum = 0
    for c = 1, #chessdata do
        for r = 1, #chessdata[c] do
            if chessdata[c][r] == 1 then
                clicknum = clicknum + 1
            end
        end
    end
    clicknum = clicknum + 1
    if clicknum >= datainfo.bombNum then
        return true
    end
    local mineNum = datainfo.mineNum
    local winScore = CalcSettle(datainfo.betMoney, clicknum, datainfo.mineNum)
    if winScore > Stock then
        return true
    end
    return false
end

--[[
    计算最终金额
]]
function CalcSettle(betMoney, clicknum, mineNum)
    local index = clicknum + 1
    local mul = table_210_mul[index]['mine' .. mineNum]
    return math.floor( mul* betMoney),mul
end

--恢复初始设置
function ReSetSpin(datainfo)
    datainfo.betMoney = 0
    datainfo.chessdata = {}
    datainfo.bombNum = 0
    datainfo.mineNum = 0
end
