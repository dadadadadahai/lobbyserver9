module('luckstar',package.seeall)

local Table='game142luckstar'
LineNum = 20

function Get(uid)
    local datainfo = unilight.getdata(Table, uid)
    if table.empty(datainfo) then
        datainfo={
            _id = uid,
            betindex = 1,
            betMoney = 0,
        }
        unilight.savedata(Table, datainfo)
    end
    return datainfo
end

function Normal(gameType,betindex,datainfo)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betMoney = betconfig[betindex]
    local chip = betMoney*LineNum
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = 1,
            desc = '下注参数错误',
        }
    end
    --执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfo._id, Const.PACK_OP_TYPE.SUB, chip, "幸运星")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local backData,realMul = gameImagePool.RealCommonRotate(datainfo._id,GameId,gameType,1,luckstar,{betchip=betMoney,gameId=GameId,gameType=gameType,betchips=chip})
    local boards={[1]=backData.chessdata}
    local winLines = {[1]=backData.winLines}
    for _,value in ipairs(winLines[1]) do
        value[3] = value[3]*betMoney
    end
    local winScore = realMul*betMoney*LineNum
    BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD,winScore,Const.GOODS_SOURCE_TYPE.luckstar)
    local res = {
        errno = 0,
        betIndex = betindex,
        bAllLine = LineNum,
        payScore = chip,
        winScore = winScore,
        winLines = winLines,
        boards = boards,
        extraData={
            serverMul=backData.serverMul*betMoney,
        },
    }
    gameDetaillog.SaveDetailGameLog(
        datainfo._id,
        os.time(),
        GameId,
        gameType,
        chip,
        remainder + chip,
        chessuserinfodb.RUserChipsGet(datainfo._id),
        0,
        { type = 'normal'},
        {}
    )
    unilight.update(Table, datainfo._id, datainfo)
    return res
end
