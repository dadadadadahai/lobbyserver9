-- 老虎游戏模块
module('diamond', package.seeall)

function PlayNormalGame(diamondInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘附加信息
    diamondInfo.iconsAttachData = {}
    -- 保存下注档次
    diamondInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_163_hanglie[1].linenum)
    local betgold = betConfig[diamondInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_163_hanglie[1].linenum                                   -- 全部下注金额
    local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "diamond下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    diamondInfo.betMoney = payScore
    -- 生成普通棋盘和结果
    -- local imageType = table_163_imagePro[gamecommon.CommRandInt(table_163_imagePro,'pro')].type
    -- imageType = GmProcess(imageType)

    local resultGame,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,1,diamond,{betchip=betgold,betIndex=betIndex,gameId=GameId,gameType=gameType,betchips=payScore})
    resultGame.winScore = realMul *  betgold
    -- 保存棋盘数据
    diamondInfo.boards = resultGame.boards
    -- 整理中奖线数据
    for _, winline in ipairs(resultGame.winlines) do
        winline[3] = winline[3] * betgold
    end
    if resultGame.winScore >0 then 
      BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.DIAMOND)
    end 
    -- 返回数据
    local res = GetResInfo(uid, diamondInfo, gameType)
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        diamondInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        jackpot
    )
 
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,diamondInfo)
    return res
end

function PlayNormalGameDemo(diamondInfo,uid,betIndex,gameType)
    -- 清理棋盘附加信息
    diamondInfo.iconsAttachData = {}
    -- 保存下注档次
    diamondInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_163_hanglie[1].linenum)
    local betgold = betConfig[diamondInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_163_hanglie[1].linenum                                   -- 全部下注金额
    -- 扣除金额
    local _, ok = chessuserinfodb.WGoldChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "diamond下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    diamondInfo.betMoney = payScore
    -- 生成普通棋盘和结果


    local resultGame,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,1,diamond,{betchip=betgold,demo = IsDemo(uid),betIndex=betIndex,gameId=GameId,gameType=gameType,betchips=payScore})
    resultGame.winScore = realMul *  betgold
    -- 保存棋盘数据
    diamondInfo.boards = resultGame.boards

    -- 整理中奖线数据
    for _, winline in ipairs(resultGame.winlines) do
        winline[3] = winline[3] * betgold
    end
    if resultGame.winScore >0 then 
          BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT, resultGame.winScore, Const.GOODS_SOURCE_TYPE.DIAMOND)
    end 
    -- 返回数据
    local res = GetResInfo(uid, diamondInfo, gameType)
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines

    -- 保存数据库信息
    SaveGameInfo(uid,gameType,diamondInfo)
    return res
end