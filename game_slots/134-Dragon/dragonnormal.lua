-- 生肖龙游戏模块
module('Dragon', package.seeall)

function PlayNormalGame(dragonInfo,uid,betIndex,gameType,specialType)
    specialType = specialType or false
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘附加信息
    dragonInfo.iconsAttachData = {}
    -- 保存下注档次
    dragonInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_134_hanglie[1].linenum)
    local betgold = betConfig[dragonInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_134_hanglie[1].linenum                                   -- 全部下注金额
    local jackpot = {}
    local payMul = 1
    if specialType then
        print("=========================")
        payMul = 5
    end
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore * payMul, "生肖龙下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    dragonInfo.betMoney = payScore

    -- 生成普通棋盘和结果
    local tablepro = table.clone(table_134_imagePro)
    if specialType then
        table.remove(tablepro,1)
    else
        table.remove(tablepro,2)
    end
    local param = {betchip=payScore,gameId=GameId,gameType=gameType,betchips=payScore}
    local controlvalue = gamecommon.GetControlPoint(uid,param)
    --获取rtp
    local rtp = gamecommon.GetModelRtp(uid, GameId, gameType, controlvalue)
    
    param.rtp = rtp
    local imageType = tablepro[gamecommon.CommRandInt(tablepro,'gailv'..rtp)].type

    local resultGame,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,imageType,Dragon,param)
    local winScore = realMul * dragonInfo.betMoney
    local result = resultGame
    -- 如果是中了免费 第一句就需要配置
    if imageType == 3 then
        result = resultGame.free[1]
        table.remove(resultGame.free,1)
        dragonInfo.free = {
            lackTimes = 7,
            totalTimes = 8,
            tWinScore = 0,
            freeinfo = resultGame.free
        }
        winScore = result.winMul * dragonInfo.betMoney
        dragonInfo.free.tWinScore = dragonInfo.free.tWinScore + winScore / table_134_hanglie[1].linenum
    end
    -- 保存棋盘数据
    dragonInfo.boards = result.boards
    dragonInfo.mulList = result.mulList
    dragonInfo.sumMul = result.sumMul
    -- 整理中奖线数据
    for _, winline in ipairs(result.reswinlines[1]) do
        winline[3] = winline[3] * dragonInfo.betMoney / table_134_hanglie[1].linenum
    end
    if winScore > 0 and imageType ~= 3 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, winScore, Const.GOODS_SOURCE_TYPE.DRAGON)
    end
    -- 返回数据
    local res = GetResInfo(uid, dragonInfo, gameType, {})
    res.boards = {result.boards}
    res.winScore = winScore
    res.winlines = result.reswinlines
    res.extraData = {
        mulList = result.mulList,
        sumMul = result.sumMul,
    }
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,dragonInfo)
    -- 增加后台历史记录
    local type = 'normal'
    -- 如果中了免费模式
    if not table.empty(dragonInfo.free) then
        type = 'freeNormal'
    end
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        dragonInfo.betMoney * payMul,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type=type,chessdata = result.boards},
        jackpot
    )
    return res
end