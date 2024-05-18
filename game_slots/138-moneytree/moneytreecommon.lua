module('moneytree',package.seeall)

function Get(uid)
    local datainfo = unilight.getdata(Table, uid)
    if table.empty(datainfo) then
        datainfo={
            _id = uid,
            betindex = 1,
            betMoney = 0,
            respin={}
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
    local remainder, ok = chessuserinfodb.WChipsChange(datainfo._id, Const.PACK_OP_TYPE.SUB, chip, "摇钱树玩法投注")
    if ok == false then
        return {
            errno = ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betindex = betindex
    local backData,realMul = gameImagePool.RealCommonRotate(datainfo._id,GameId,1,1,moneytree,{betchip=betMoney,gameId=GameId,gameType=gameType,betchips=chip})
    local winScore = chip*realMul
    BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD, winScore,Const.GOODS_SOURCE_TYPE.moneytree)
    local boards={
        [1] = backData[1].chessdata
    }
    local res = {
        errno = 0,
        betIndex = betindex,
        payScore = chip,
        winScore = winScore,
        boards = boards,
        extraData=backData,
        features={
            respin={}
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
function Respin(gameType,betindex,datainfo)
    local betindex = datainfo.betindex
    local respin = datainfo.respin
    local res = respin.res[1]
    datainfo.respin.lastRes = res
    table.remove(respin.res,1)
    local winScore = 0
    local remainder = chessuserinfodb.RUserChipsGet(datainfo._id)
    if #respin.res<=0 then
        local chessdata = res.chessdata
        local tMul = 0
        for _,value in ipairs(chessdata) do
            for _,celloj in ipairs(value) do
                if celloj~=0 then
                    tMul = tMul + celloj.mul
                end
            end
        end
        winScore= datainfo.betMoney*tMul
        BackpackMgr.GetRewardGood(datainfo._id, Const.GOODS_ID.GOLD, winScore,Const.GOODS_SOURCE_TYPE.moneytree)
    end
    local resNew = {
        errno = 0,
        betIndex = betindex,
        payScore = chip,
        winScore = winScore,
        extraData=res,
        features={
            respin={
                totalTimes=3,
                lackTimes=res.lackTimes,
                tWinScore=0,
            }
        }
    }
    if #respin.res<=0 then
        datainfo.respin={}
    end
    gameDetaillog.SaveDetailGameLog(
        datainfo._id,
        os.time(),
        GameId,
        gameType,
        0,
        remainder,
        chessuserinfodb.RUserChipsGet(datainfo._id),
        0,
        { type = 'respin',imageType=2},
        {}
    )
    unilight.update(Table, datainfo._id, datainfo)
    return resNew
end



function BuyFree(betindex,datainfo)
    if table.empty(datainfo.respin)==false then
        return{
            errno = ErrorDefine.ERROR_INFREEING,
        }
    end
    local betconfig = gamecommon.GetBetConfig(1, LineNum)
    local betMoney = betconfig[betindex]
    local chip = 100 * betMoney
    local remainder, ok = chessuserinfodb.WChipsChange(datainfo._id, Const.PACK_OP_TYPE.SUB,chip ,"摇钱树购买免费")
    if ok==false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    --取出respin图库
    local backData,realMul = gameImagePool.RealCommonRotate(datainfo._id,GameId,gameType,2,moneytree,{betchip=betMoney,gameId=GameId,gameType=1,betchips=chip})
    --取出0倍图库
    local zeroData,_ = gameImagePool.getZeroImagePool(GameId)
    local ichessdata = backData[1].chessdata
    for col=1,#ichessdata do
        for row=1,#ichessdata[col] do
            if ichessdata[col][row]~=0 then
                zeroData[1].chessdata[col][row]=80
            end
        end
    end
    local lastRes=backData[1]
    table.remove(backData,1)
    datainfo.betMoney=betMoney
    --初始化记录
    datainfo.respin={
        totalTimes=3,
        lackTimes=3,
        tWinScore=0,
        lastRes=lastRes,
        res=backData
    }
    local res = {
        errno = 0,
        betIndex = betindex,
        payScore = chip,
        winScore = winScore,
        boards = boards,
        extraData=zeroData,
        features={
            respin={
                totalTimes=3,
                lackTimes=3,
                tWinScore=0,
            }
        }
    }
    unilight.update(Table, datainfo._id, datainfo)
    return res
end