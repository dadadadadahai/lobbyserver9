module('penguin',package.seeall)
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
    local remainder, ok = chessuserinfodb.WChipsChange(datainfo._id, Const.PACK_OP_TYPE.SUB, chip, "企鹅")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local imageType = table_144_imagePro[gamecommon.CommRandInt(table_144_imagePro,'pro')].type
    local backData,realMul = gameImagePool.RealCommonRotate(datainfo._id,GameId,gameType,imageType,penguin,{betchip=betMoney,gameId=GameId,gameType=gameType,betchips=chip})
    local b=backData.b
    local f=backData.f
    local c=backData.c
    local winScore = realMul*chip
    local boards={[1]=b[1].chessdata}
    if table.empty(f)==false then
        --触发了免费
        datainfo.free={
            totalTimes=1,
            lackTimes=1,
            tWinScore=winScore,
            blueMul=c.blueMul,
            blueNum=c.blueNum,
            purpleMul=c.purpleMul,
            purpleNum=c.purpleNum,
            res=f,
        }
    else
        BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD,winScore,Const.GOODS_SOURCE_TYPE.penguin)
    end
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        gameType = gameType,
        boards=boards,
        extraData={
            b=b,
            c=c
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
        { type = 'normal',imageType=1},
        {}
    )
    unilight.update(Table, datainfo._id, datainfo)
    return res
end
--免费模式
function Free(gameType,betindex,datainfo)
    local betMoney = datainfo.betMoney
    local f = datainfo.free.res[1]
    table.remove(datainfo.free.res,1)
    datainfo.free.purpleMul=f.purpleMul
    local res = f.res
    local lastRes = res[#res]
    datainfo.free.blueNum=lastRes.blueNum
    datainfo.free.purpleMul=lastRes.purpleMul
    datainfo.free.purpleNum=lastRes.purpleNum
    datainfo.free.tWinScore = datainfo.free.tWinScore + f.tMul*betMoney
    local remainder = chessuserinfodb.RUserChipsGet(datainfo._id)
    local boards={[1]=res[1].chessdata}
    if table.empty(datainfo.free.res) then
        datainfo.free.lackTimes = 0
        BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD,datainfo.free.tWinScore,Const.GOODS_SOURCE_TYPE.penguin)
    end
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        gameType = gameType,
        boards=boards,
        extraData={
            f=res
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
        0,
        remainder,
        chessuserinfodb.RUserChipsGet(datainfo._id),
        0,
        { type = 'free',imageType=2},
        {}
    )
    if datainfo.free.lackTimes<=0 then
        datainfo.free={}
    end
    unilight.update(Table, datainfo._id, datainfo)
    return res
end