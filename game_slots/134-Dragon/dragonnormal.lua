-- 生肖龙游戏模块
module('Dragon', package.seeall)
function sumtable(table)
    local sum = 0
    for _, value in pairs(table) do
        sum = sum + value
    end
    return sum 
end
function PlayNormalGame(dragonInfo,uid,betIndex,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 保存下注档次
    dragonInfo.betIndex = betIndex
    local betConfig = gamecommon.GetBetConfig(gameType,table_134_hanglie[1].linenum)
    local betgold = betConfig[dragonInfo.betIndex]                                                      -- 单注下注金额
    local payScore = betgold * table_134_hanglie[1].linenum                                   -- 全部下注金额
    local jackpot = {}
    -- 只有普通扣费 买免费触发的普通不扣费

    -- 扣除金额
    local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, payScore, "生肖龙下注扣费")
    if ok == false then
        local res = {
            errno = 1,
            desc = "当前余额不足"
        }
        return res
    end
    dragonInfo.betMoney = payScore
    dragonInfo.betgold = betgold
    -- 生成普通棋盘和结果
    local resultGame,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,Dragon,{betchip=betgold,gameId=GameId,gameType=gameType,betchips=payScore})

    -- 保存棋盘数据
    local data = table.remove(resultGame,1) 
    local boards =  data.boards
    dragonInfo.boards = boards
    -- 整理中奖线数据
    for _, winline in ipairs(data.reswinlines) do
        winline[3] = winline[3] * betgold
    end
    local  winscore = betgold * data.sumMul
    if (imageType == 1 or imageType == 3 )and winscore > 0 then
        -- 增加奖励
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, winscore, Const.GOODS_SOURCE_TYPE.DRAGON)
    elseif imageType == 2 then
        resultGame.isFree = true
        dragonInfo.free={
            totalTimes=8,
            lackTimes=7,
            tWinScore = winscore,
            resdata=resultGame
        }
    end
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        dragonInfo.betMoney,
        remainder+payScore,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type=( resultGame.isFree and "free" or 'normal'),chessdata = boards},
        {}
    )
    -- WithdrawCash.ResetWithdawTypeState(datainfos._id,0)


    SaveGameInfo(uid,gameType,dragonInfo)
    local res = {
        errno = 0,
        betIndex = dragonInfo.betindex,
        bAllLine = LineNum,
        payScore = payScore,
        winScore = winscore,
        winLines = data.reswinlines,
        boards = boards,
        mulList= data.mulList,
        sumMulList = sumtable(data.mulList),
        sumMul = data.sumMul,
        free = packFree(dragonInfo),
        isfake = resultGame.isfake or 0 

    }
    return res
 
end