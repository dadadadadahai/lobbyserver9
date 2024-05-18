module('marry',package.seeall)
function Get(uid)
    local datainfo = unilight.getdata(Table, uid)
    if table.empty(datainfo) then
        datainfo={
            _id = uid,
            betindex = 1,
            betMoney = 0,
            free={}
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
    local remainder, ok = chessuserinfodb.WChipsChange(datainfo._id, Const.PACK_OP_TYPE.SUB, chip, "结婚")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local imageType = table_143_imagePro[gamecommon.CommRandInt(table_143_imagePro,'pro')].type
    local tmpImageType = GmProcess(datainfo._id,gameType,chessdata)
    if tmpImageType>0 then
        imageType=tmpImageType
    end
    local backData,realMul = gameImagePool.RealCommonRotate(datainfo._id,GameId,gameType,imageType,marry,{betchip=betMoney,gameId=GameId,gameType=gameType,betchips=chip})
    --回送b
    local b = backData.b
    local f = backData.f
    local boards={[1]=b.chessdata}
    local winLines={[1]=b.winLines}
    local winScore = betMoney*b.mul*LineNum
    if table.empty(f)==false then
        --触发免费
        datainfo.free={
            totalTimes=8,
            lackTimes=8,
            tWinScore=winScore,
            res=f,
        }
    else
        BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD,winScore,Const.GOODS_SOURCE_TYPE.marry)
    end
    local res = {
        errno = 0,
        betIndex = betindex,
        bAllLine = LineNum,
        payScore = chip,
        winScore = winScore,
        winLines = winLines,
        boards = boards,
        features={
            free=PackFree(datainfo)
        }
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


function Free(gameType,betindex,datainfo)
    local betindex = datainfo.betindex
    local betMoney = datainfo.betMoney
    local res = datainfo.free.res[1]
    table.remove(datainfo.free.res,1)
    datainfo.free.lackTimes = res.lackTimes
    datainfo.free.totalTimes = res.totalTimes
    datainfo.free.tWinScore = datainfo.free.tWinScore + res.fMul*betMoney
    local boards={[1]=res.data[1].chessdata,[2]=res.data[2].chessdata}
    local winLines={[1]=res.data[1].winLines,[2]=res.data[2].winLines}
    local winScore = res.fMul*betMoney*LineNum
    local res = {
        errno = 0,
        betIndex = betindex,
        bAllLine = LineNum,
        payScore = chip,
        winScore = winScore,
        winLines = winLines,
        boards = boards,
        features={
            free=PackFree(datainfo)
        }
    }
    local rchip = chessuserinfodb.RUserChipsGet(datainfo._id)
    if datainfo.free.lackTimes<=0 then
        BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD,datainfo.free.tWinScore,Const.GOODS_SOURCE_TYPE.marry)
        datainfo.free={} 
    end
    gameDetaillog.SaveDetailGameLog(
        datainfo._id,
        os.time(),
        GameId,
        gameType,
        0,
        rchip,
        chessuserinfodb.RUserChipsGet(datainfo._id),
        0,
        { type = 'free'},
        {}
    )
    unilight.update(Table, datainfo._id, datainfo)
    return res
end