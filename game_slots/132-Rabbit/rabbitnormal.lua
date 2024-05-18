-- 兔子游戏模块
module('Rabbit', package.seeall)

function PlayNormalGame(rabbitInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘附加信息
    rabbitInfo.iconsAttachData = {}
    -- 保存下注档次
    rabbitInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_132_hanglie[1].linenum)
    local betgold = betConfig[rabbitInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_132_hanglie[1].linenum                                   -- 全部下注金额
    local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "兔子下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    rabbitInfo.betMoney = payScore

    -- 生成普通棋盘和结果
    -- local imageType = table_132_imagePro[gamecommon.CommRandInt(table_132_imagePro,'pro')].type
    -- imageType = GmProcess(imageType)
    local imageType = nil
    if math.random(5) == 1 then
        imageType = 2
    end
    local resultGame,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,imageType,Rabbit,{betchip=betgold,gameId=GameId,gameType=gameType,betchips=payScore})
    local winScore = 0
    -- 如果是普通则需要处理免费第一把信息
    if imageType == 2 then
        rabbitInfo.freeInfo = table.clone(resultGame.freeInfo)
        rabbitInfo.free.totalTimes = table_132_respinPro[1].num                 -- 总次数
        rabbitInfo.free.lackTimes = table_132_respinPro[1].num - 1              -- 剩余游玩次数
        rabbitInfo.free.tWinScore = 0                                           -- 已经赢得的钱
        resultGame = rabbitInfo.freeInfo[1]
        table.remove(rabbitInfo.freeInfo,1)
        winScore = rabbitInfo.betMoney * resultGame.winMul
    elseif imageType == 1 or imageType == 3 then
        winScore = rabbitInfo.betMoney * realMul
        -- 整理中奖线数据
        for _, winline in ipairs(resultGame.winlines[1]) do
            winline[3] = winline[3] *betgold
        end
    end
    -- 保存棋盘数据
    rabbitInfo.boards = resultGame.boards
    rabbitInfo.iconsAttachData = resultGame.iconsAttachData
    if (imageType == 1 or imageType == 3) and winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, winScore, Const.GOODS_SOURCE_TYPE.RABBIT)
    elseif imageType == 2 and winScore > 0 then
        rabbitInfo.free.tWinScore = rabbitInfo.free.tWinScore + winScore
    end

    -- 保存数据库信息
    SaveGameInfo(uid,gameType,rabbitInfo)
    -- 返回数据
    local res = GetResInfo(uid, rabbitInfo, gameType, resultGame.tringerPoints)
    res.boards = {resultGame.boards}
    res.winScore = winScore
    res.winlines = resultGame.winlines
    res.isfake = resultGame.isfake or 0 
    -- res.extraData = resultGame.extraData
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        rabbitInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        jackpot
    )
    return res
end