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
    diamondInfo.betgold = betgold
    local resultGame,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,diamond,{betchip=betgold,betIndex=betIndex,gameId=GameId,gameType=gameType,betchips=payScore})
    if imageType == 2 then
        local ntfres = table.remove(resultGame,1)
        diamondInfo.free={
            totalTimes=8,
            lackTimes=8,
            tWinScore = 0,
            resdata=resultGame
        }
        local winScore = ntfres.winMul *  betgold
        -- 保存棋盘数据
        diamondInfo.boards = ntfres.boards

        -- 整理中奖线数据
        for _, winline in ipairs(ntfres.winlines) do
            winline[3] = winline[3] * betgold
        end
        if not table.empty(ntfres.bonus) then
            ntfres.bonus.winScore =   ntfres.bonus.mul   * betgold
        end
        if winScore >0 then 
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, winScore, Const.GOODS_SOURCE_TYPE.DIAMOND)
        end 
        -- 返回数据
        
       
        local res = GetResInfo(uid, diamondInfo, gameType)
        res.winScore = winScore
        res.winlines = ntfres.winlines
        res.bonus = ntfres.bonus
        res.imageType = imageType 
        res.free = packFree(diamondInfo)
        gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            diamondInfo.betMoney,
            reschip,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {type='normal',chessdata =  ntfres.boards},
            jackpot
        )
            -- 保存数据库信息
            SaveGameInfo(uid,gameType,diamondInfo)
            return res
    else
        resultGame.winScore = realMul *  betgold
        -- 保存棋盘数据
        diamondInfo.boards = resultGame.boards
        -- 整理中奖线数据
        for _, winline in ipairs(resultGame.winlines) do
            winline[3] = winline[3] * betgold
        end
        if not table.empty(resultGame.bonus) then
            resultGame.bonus.winScore =   resultGame.bonus.mul   * betgold
        end
       
        if resultGame.winScore >0 then 
          BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.DIAMOND)
        end 
        -- 返回数据
        local res = GetResInfo(uid, diamondInfo, gameType)
        res.winScore = resultGame.winScore
        res.winlines = resultGame.winlines
        res.bonus = resultGame.bonus
        res.imageType = imageType 
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
    diamondInfo.betgold = betgold
    diamondInfo.betMoney = payScore
    -- 生成普通棋盘和结果
    
    -- local ximageType =  1
    -- if cindex%3== 1 then 
    --    ximageType =2
    -- elseif cindex %3 == 2 then 
    --    ximageType = 3
    -- end 

    local resultGame,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,diamond,{betchip=betgold,demo = IsDemo(uid),betIndex=betIndex,gameId=GameId,gameType=gameType,betchips=payScore})
    if imageType == 2 then
        local ntfres = table.remove(resultGame,1)
        diamondInfo.free={
            totalTimes=8,
            lackTimes=8,
            tWinScore = 0,
            resdata=resultGame
        }
        local winScore = ntfres.winMul *  betgold
        -- 保存棋盘数据
        diamondInfo.boards = ntfres.boards

        -- 整理中奖线数据
        for _, winline in ipairs(ntfres.winlines) do
            winline[3] = winline[3] * betgold
        end
        if not table.empty(ntfres.bonus) then
            ntfres.bonus.winScore =   ntfres.bonus.mul   * betgold
        end
        if winScore >0 then 
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT, winScore, Const.GOODS_SOURCE_TYPE.DIAMOND)
        end 
        -- 返回数据
        local res = GetResInfo(uid, diamondInfo, gameType)
        res.winScore = winScore
        res.winlines = ntfres.winlines
        res.bonus = ntfres.bonus
        res.imageType = imageType 
        res.free = packFree(diamondInfo)
        SaveGameInfo(uid,gameType,diamondInfo)
        return res
    else
        resultGame.winScore = realMul *  betgold
        -- 保存棋盘数据
        diamondInfo.boards = resultGame.boards

        -- 整理中奖线数据
        for _, winline in ipairs(resultGame.winlines) do
            winline[3] = winline[3] * betgold
        end
        if not table.empty(resultGame.bonus) then
            resultGame.bonus.winScore =   resultGame.bonus.mul   * betgold
        end
        if resultGame.winScore >0 then 
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT, resultGame.winScore, Const.GOODS_SOURCE_TYPE.DIAMOND)
        end 
        -- 返回数据
        local res = GetResInfo(uid, diamondInfo, gameType)
        res.winScore = resultGame.winScore
        res.winlines = resultGame.winlines
        res.bonus = resultGame.bonus
        res.imageType = imageType 
        -- 保存数据库信息
        SaveGameInfo(uid,gameType,diamondInfo)
        return res
    end

end