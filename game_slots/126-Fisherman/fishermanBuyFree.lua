module('Fisherman', package.seeall)
Table = 'game126fisherman'
LineNum = 1
GameId = 126


J = 100
S = 70
--购买免费
function BuyFree(gameType,betindex,datainfo,uid)
    if table.empty(datainfo.free)==false then
        return{
            errno = ErrorDefine.ERROR_INFREEING,
        }
    end
        -- 游戏后台记录所需初始信息
     local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betGold = betconfig[betindex]
    local betMoney = betGold * LineNum
    local chip = table_126_buyfree[1].price * betMoney
        -- 执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB,chip ,"渔夫购买免费")
    if ok==false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betGold = betGold
    datainfo.betindex = betindex
    --取图库2
    local alldisInfo,realMulall = gameImagePool.RealCommonRotate(uid,GameId,gameType,2,Fisherman,{betchip=betMoney,betIndex=betindex,gameId=GameId,gameType=gameType,betchips=betGold})

    local resultGame =  table.remove(alldisInfo,1)

    local winScore = resultGame.sumMul *betGold
    if winScore > 0 then 
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.Fisherman)
    end 
    dump(resultGame,"resultGame",10)
    datainfo.boards = resultGame.boards
    datainfo.free={
        totalTimes=resultGame.FreeInfo.FreeNum,
        lackTimes=resultGame.FreeInfo.FreeNum,
        tWinScore = 0,
        isBuy = 1,
        realMulall = realMulall,
        FreeInfo = resultGame.FreeInfo,
        resdata=alldisInfo
    }
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        chip,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = boards},
        {}
    )
    -- 整理中奖线数据
    for _, winline in ipairs(resultGame.winLines) do
        winline[3] = winline[3] * betGold
    end

    -- 返回数据
    local res = GetResInfo(uid, datainfo, gameType)
    res.winScore = winScore
    res.winlines = resultGame.winLines
    res.iconsAttachData = resultGame.iconsAttachData
    res.disInfo = resultGame.disInfo
    res.isfake = resultGame.isfake or 0 
    SaveGameInfo(uid,gameType,datainfo)
    return res
end


function BuyFreeDemo(gameType,betindex,datainfo,uid)
    if table.empty(datainfo.free)==false then
        return{
            errno = ErrorDefine.ERROR_INFREEING,
        }
    end

    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betGold = betconfig[betindex]
    local betMoney = betGold * LineNum
    local chip = table_126_buyfree[1].price * betMoney
        -- 执行扣费
    local remainder, ok = chessuserinfodb.WGoldChange(uid, Const.PACK_OP_TYPE.SUB,chip ,"宙斯购买免费")
    if ok==false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betGold = betGold
    datainfo.betindex = betindex
    --取图库2
    local alldisInfo ,realMulall= gameImagePool.RealCommonRotate(uid,GameId,gameType,2,Fisherman,{betchip=betMoney,demo = IsDemo(uid),betIndex=betindex,gameId=GameId,gameType=gameType,betchips=betGold})

    local resultGame =  table.remove(alldisInfo,1)
    local winScore = resultGame.sumMul *betGold
    if winScore > 0 then 
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT,winScore, Const.GOODS_SOURCE_TYPE.Fisherman)
    end 
    datainfo.boards = resultGame.boards
    datainfo.free={
        totalTimes=resultGame.FreeInfo.FreeNum,
        lackTimes=resultGame.FreeInfo.FreeNum,
        tWinScore = 0,
        isBuy = 1,
        realMulall = realMulall,
        FreeInfo = resultGame.FreeInfo,
        resdata=alldisInfo
    }
    -- 整理中奖线数据
    for _, winline in ipairs(resultGame.winLines) do
        winline[3] = winline[3] * betGold
    end

    -- 返回数据
    local res = GetResInfo(uid, datainfo, gameType)
    res.winScore = winScore
    res.winlines = resultGame.winLines
    res.iconsAttachData = resultGame.iconsAttachData
    res.disInfo = resultGame.disInfo
    res.isfake = resultGame.isfake or 0 
    SaveGameInfo(uid,gameType,datainfo)
    return res
end