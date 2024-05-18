module('animal',package.seeall)
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
    print('betMoney',betMoney)
    local chip = betMoney*LineNum
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = 1,
            desc = '下注参数错误',
        }
    end
    --执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfo._id, Const.PACK_OP_TYPE.SUB, chip, "动物")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local imageType = table_145_imagePro[gamecommon.CommRandInt(table_145_imagePro,'pro')].type
    local tmpImageType =  GmProcess()
    if tmpImageType>0 then
        imageType=tmpImageType
    end
    local backData,realMul,imageType = gameImagePool.RealCommonRotate(datainfo._id,GameId,gameType,imageType,animal,{betchip=betMoney,gameId=GameId,gameType=gameType,betchips=chip})
    local boards={[1]={}}
    local winLines={[1]={}}
    local uPosRange={}
    local uToIconId=0
    local winScore = betMoney * realMul*LineNum
    if imageType==1 then
        --普通模式
        boards[1]=backData.b.chessdata
        winLines[1] = backData.b.dis
        BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD,winScore,Const.GOODS_SOURCE_TYPE.animal)
    elseif imageType==2 then
        boards[1]=backData.b.chessdata
        winLines[1] = backData.b.dis
        --免费模式
        datainfo.free={
            totalTimes=backData.f[1].totalTimes,
            lackTimes = backData.f[1].totalTimes,
            tWinScore = winScore,
            res=backData.f,
        }
    elseif imageType==3 then
        --特殊模式
        boards[1]=backData.chessdata
        winLines[1] = backData.dis
        uPosRange = backData.uPosRange
        uToIconId = backData.uToIconId
        BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD,winScore,Const.GOODS_SOURCE_TYPE.animal)
    end
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        winScore=winScore,
        gameType = gameType,
        boards=boards,
        winLines = winLines,
        extraData={
            uPosRange=  uPosRange,
            uToIconId = uToIconId,
            imageType = imageType,
        },
        features={
            free=packFree(datainfo)
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
        { type = 'normal',imageType=imageType},
        {}
    )
    unilight.update(Table, datainfo._id, datainfo)
    return res
end

function Free(datainfo)
    local betMoney = datainfo.betMoney
    f = datainfo.free.res[1]
    datainfo.free.lackTimes = f.lackTimes
    datainfo.free.totalTimes = f.totalTimes
    local winScore = f.mul*betMoney*LineNum
    datainfo.free.tWinScore = datainfo.free.tWinScore + winScore
    local boards={[1]=f.chessdata}
    local winLines={[1]=f.dis}
    local sameLockRange=f.sameLockRange
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        winScore=winScore,
        gameType = gameType,
        boards=boards,
        winLines = winLines,
        extraData={
            sameLockRange=  sameLockRange,
        },
        features={
            free=packFree(datainfo)
        }
    }
    table.remove(datainfo.free.res,1)
    if datainfo.free.lackTimes<=0 then
        BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD,datainfo.free.tWinScore,Const.GOODS_SOURCE_TYPE.animal)
        datainfo.free={}
    end
    unilight.update(Table, datainfo._id, datainfo)
    return res
end


