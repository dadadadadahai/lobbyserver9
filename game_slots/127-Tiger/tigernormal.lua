-- 老虎游戏模块
module('Tiger', package.seeall)

function PlayNormalGame(tigerInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘附加信息
    tigerInfo.iconsAttachData = {}
    -- 保存下注档次
    tigerInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_127_hanglie[1].linenum)
    local betgold = betConfig[tigerInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_127_hanglie[1].linenum                                   -- 全部下注金额
    local jackpot = {}
    -- 扣除金额
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "老虎下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    tigerInfo.betMoney = payScore
    -- 生成普通棋盘和结果
    -- local imageType = table_127_imagePro[gamecommon.CommRandInt(table_127_imagePro,'pro')].type
    -- imageType = GmProcess(imageType)

    local resultGame,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,Tiger,{betchip=betgold,gameId=GameId,gameType=gameType,betchips=payScore})
    resultGame.winScore = realMul *  tigerInfo.betMoney 
    -- 保存棋盘数据
    tigerInfo.boards = resultGame.boards
    tigerInfo.respin = resultGame.respin
    -- 整理中奖线数据
    for _, winline in ipairs(resultGame.winlines[1]) do
        winline[3] = winline[3] * betgold
    end
    if not table.empty(resultGame.respin) then
        for _, curresultGame in pairs(resultGame.respin) do
            for _, winline in ipairs(curresultGame.winlines[1]) do
                winline[3] = winline[3] * betgold
            end
        end
     
    end 
    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.TIGER)
    -- 返回数据
    local res = GetResInfo(uid, tigerInfo, gameType)
    res.boards = {resultGame.boards}
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines

    res.bigWinIcon = resultGame.bigWinIcon
    res.isfake = resultGame.isfake
    res.respinFlag = resultGame.respinFlag
    res.respinIconId = resultGame.respinIconId or -1
    if imageType ==2 then 
        -- 增加后台历史记录
        gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            tigerInfo.betMoney,
            reschip,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {type='normalRespin',chessdata = resultGame.boards,respin = resultGame.respin},
            jackpot
        )
    else
        gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            tigerInfo.betMoney,
            reschip,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {type='normal',chessdata = resultGame.boards},
            jackpot
        )
    end 
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,tigerInfo)
    return res
end