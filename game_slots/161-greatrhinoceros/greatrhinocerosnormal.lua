-- 大象游戏模块
module('GreatRhinoceros', package.seeall)

function PlayNormalGame(GreatRhinocerosInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘附加信息
    GreatRhinocerosInfo.iconsAttachData = {}
    -- 保存下注档次
    GreatRhinocerosInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_161_hanglie[1].linenum)
    local betgold = betConfig[GreatRhinocerosInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_161_hanglie[1].linenum                                   -- 全部下注金额
    local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "大犀牛下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    GreatRhinocerosInfo.betMoney = payScore
    GreatRhinocerosInfo.betgold = betgold
    -- 生成普通棋盘和结果
    local resultGame,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,nil ,GreatRhinoceros,{betchip=betgold,betIndex=betIndex,gameId=GameId,gameType=gameType,betchips=payScore})
    local winScore = betgold * resultGame.normalMul
    
    -- 判断免费生成
    if imageType == 2 then
        -- 生成免费数据
        GreatRhinocerosInfo.free = {
            totalTimes = resultGame.freeTotalTime,                              -- 总次数
            lackTimes = resultGame.freeTotalTime,                               -- 剩余游玩次数
            tWinScore = 0,                                                      -- 总共已经赢得的钱
            freeInfo = resultGame.freeInfo,                                     -- 免费预计算棋盘信息
            wildNum = 0,
            wMul = 2,
        }
    end

    -- 保存棋盘数据
    GreatRhinocerosInfo.boards = resultGame.boards
    if winScore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, winScore, Const.GOODS_SOURCE_TYPE.GREATRHINOCEROS)
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,GreatRhinocerosInfo)
    -- 返回数据
    local res = GetResInfo(uid, GreatRhinocerosInfo, gameType, resultGame.tringerPoints)
    res.boards = {resultGame.boards}
    res.winScore = winScore
    res.winPoints = resultGame.winPoints
    res.extraData = {}
    for _, value in ipairs(resultGame.winEle) do
        value.score = value.mul * GreatRhinocerosInfo.betMoney
        value.mul = nil
    end
    res.extraData.winEle = resultGame.winEle
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        GreatRhinocerosInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = resultGame.boards},
        jackpot
    )
    return res
end