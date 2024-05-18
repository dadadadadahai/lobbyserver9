module('cashwheel',package.seeall)

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
    local betMoney =Betconfig[betindex]
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = 1,
            desc = '下注参数错误',
        }
    end
    local chip = betMoney
    --执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfo._id, Const.PACK_OP_TYPE.SUB, betMoney, "现金转轮")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local imageType = table_151_imagePro[gamecommon.CommRandInt(table_151_imagePro,'pro')].type 
    local backData,realMul,imageType = gameImagePool.RealCommonRotate(datainfo._id,GameId,gameType,imageType,cashwheel,{betchip=betMoney,gameId=GameId,gameType=gameType,betchips=chip})
    local winScore = betMoney * realMul
    BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD,winScore,Const.GOODS_SOURCE_TYPE.cashwheel)
    local boards={[1]=backData[1].chessdata}
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        gameType = gameType,
        boards=boards,
        winLines = winLines,
        extraData=backData
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
        { type = 'normal',imageType=imageType},
        {}
    )
    unilight.update(Table, datainfo._id, datainfo)
    return res
end