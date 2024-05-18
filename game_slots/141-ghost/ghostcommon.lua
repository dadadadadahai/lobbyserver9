module('ghost', package.seeall)
local Table='game141ghost'
LineNum = 1
function Get(uid)
    local datainfo = unilight.getdata(Table, uid)
    if table.empty(datainfo) then
        datainfo={
            _id = uid,
            betindex = 1,
            betMoney = 0,
            free={},
        }
        unilight.savedata(Table,datainfo)
    end
    return datainfo
end

function Normal(gameType,betindex,datainfo)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betMoney = betconfig[betindex]
    local chip = betMoney
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = 1,
            desc = '下注参数错误',
        }
    end
    --执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfo._id, Const.PACK_OP_TYPE.SUB, chip, "亡灵")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local imageType = table_141_imagePro[gamecommon.CommRandInt(table_141_imagePro,'pro')].type
    local tmpImageType =  GmProcess()
    if tmpImageType>0 then
        imageType=tmpImageType
    end
    local backData,realMul = gameImagePool.RealCommonRotate(datainfo._id,GameId,gameType,imageType,ghost,{betchip=betMoney,gameId=GameId,gameType=gameType,betchips=chip})
    --下发数据
    local n = backData.n
    local winScore = math.floor(chip*n.mul)
    local boards={[1]=n.dis[1].chessdata}
    if table.empty(backData.f) then
        BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD, winScore,Const.GOODS_SOURCE_TYPE.ghost)
    end
    local res = {
        errno = 0,
        betIndex = betindex,
        payScore = chip,
        winScore = winScore,
        boards = boards,
        extraData=n,
        features={
            free=InitFree(backData.f,winScore,datainfo)
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

--免费过程处理
function Free(datainfo)
    local chip = datainfo.betMoney
    local free=datainfo.free
    local res=free.res[1]
    free.lackTimes = free.lackTimes - 1
    table.remove(free.res,1)
    local winScore = math.floor(chip*res.mul)
    free.tWinScore = free.tWinScore + winScore
    free.AddMul = res.AddMul
    local boards={[1]=res.dis[1].chessdata}
    local remainder = chessuserinfodb.RUserChipsGet(datainfo._id)
    local res = {
        errno = 0,
        betIndex = betindex,
        payScore = chip,
        winScore = winScore,
        boards = boards,
        extraData=res,
        features={
            free=GetFreeInfo(datainfo)
        }
    }
    if free.lackTimes<=0 then
        BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD, free.tWinScore,Const.GOODS_SOURCE_TYPE.ghost)
        datainfo.free={}
    end
    gameDetaillog.SaveDetailGameLog(
        datainfo._id,
        os.time(),
        GameId,
        gameType,
        chip,
        remainder + chip,
        chessuserinfodb.RUserChipsGet(datainfo._id),
        0,
        { type = 'free',imageType=2},
        {}
    )
    unilight.update(Table, datainfo._id, datainfo)
    return res
end