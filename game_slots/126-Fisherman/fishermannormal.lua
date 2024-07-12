module('Fisherman', package.seeall)
Table = 'game126fisherman'
LineNum = 10
GameId = 126

W = 90
J = 100
S = 70

-- 普通拉动
function Normal(gameType, betindex, datainfo, uid)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betGold = betconfig[betindex]
    local reschip = chessuserinfodb.RUserChipsGet(uid)
   
    if betGold == nil or betGold <= 0 then
        return {
            errno = ErrorDefine.ERROR_PARAM,
        }
    end
    local betMoney = betGold * LineNum
    local sTime = os.time()
    if datainfo.isInHight  == true then
        betMoney = math.floor(chip/table_126_buygailv[1].betChange)
    end
    -- 执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, betMoney,
        "渔夫玩法投注")
    if ok == false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betGold = betGold
    datainfo.betindex = betindex
    --启用图库模式
    local resultGames,realMul ,imageType= gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,Fisherman,{betchip=betMoney,betIndex=betindex,gameId=GameId,gameType=gameType,betchips=betGold})
    if  imageType == 3 then 
        local resultGame =  table.remove(resultGames,1)

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
            resdata=resultGames
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
    else
        resultGames.winScore = realMul *  betMoney
        -- 保存棋盘数据
        datainfo.boards = resultGames.boards
        -- 整理中奖线数据
        for _, winline in ipairs(resultGames.winLines) do
            winline[3] = winline[3] * betGold
        end
        if resultGames.winScore >0 then 
          BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGames.winScore, Const.GOODS_SOURCE_TYPE.MASTERJOKER)
        end 
        -- 返回数据
        local res = GetResInfo(uid, datainfo, gameType)
        res.winScore = resultGames.winScore
        res.winlines = resultGames.winLines
        res.iconsAttachData = resultGames.iconsAttachData
        gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            datainfo.betMoney,
            reschip,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {type='normal',chessdata = resultGames.boards}
            
        )
        -- 保存数据库信息
        SaveGameInfo(uid,gameType,datainfo)
        return res
    end 
end


-- 普通拉动
function NormalDemo(gameType, betindex, datainfo, uid)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betGold = betconfig[betindex]
    local reschip = chessuserinfodb.RUserChipsGet(uid)
   
    if betGold == nil or betGold <= 0 then
        return {
            errno = ErrorDefine.ERROR_PARAM,
        }
    end
    local betMoney = betGold * LineNum
    local sTime = os.time()
    if datainfo.isInHight  == true then
        betMoney = math.floor(betMoney/table_126_buygailv[1].betChange)
    end
    -- 执行扣费
    local remainder, ok = chessuserinfodb.WGoldChange(uid, Const.PACK_OP_TYPE.SUB, betMoney,
        "渔夫玩法投注")
    if ok == false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    datainfo.betGold = betGold
    datainfo.betindex = betindex
    --启用图库模式
    local resultGames,realMul ,imageType= gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,Fisherman,{betchip=betMoney, demo = IsDemo(uid),betIndex=betindex,gameId=GameId,gameType=gameType,betchips=betGold})
    if  imageType == 3 then 
        local resultGame =  table.remove(resultGames,1)
        local winScore = resultGame.sumMul *betGold
        if winScore > 0 then 
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT,winScore, Const.GOODS_SOURCE_TYPE.Fisherman)
        end 
        datainfo.boards = resultGame.boards
        datainfo.free={
            totalTimes=resultGame.FreeInfo.FreeNum,
            lackTimes=resultGame.FreeInfo.FreeNum,
            tWinScore = 0,
            isBuy = 0,
            realMulall = realMulall,
            FreeInfo = resultGame.FreeInfo,
            resdata=resultGames
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
    else
        resultGames.winScore = realMul *  betMoney
        -- 保存棋盘数据
        datainfo.boards = resultGames.boards
        -- 整理中奖线数据
        for _, winline in ipairs(resultGames.winLines) do
            winline[3] = winline[3] * betGold
        end
        if resultGames.winScore >0 then 
          BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT, resultGames.winScore, Const.GOODS_SOURCE_TYPE.MASTERJOKER)
        end 
        -- 返回数据
        local res = GetResInfo(uid, datainfo, gameType)
        res.winScore = resultGames.winScore
        res.winlines = resultGames.winLines
        res.iconsAttachData = resultGames.iconsAttachData
        gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            datainfo.betMoney,
            reschip,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {type='normal',chessdata = resultGames.boards}
            
        )
     
        -- 保存数据库信息
        SaveGameInfo(uid,gameType,datainfo)
        return res
    end 
end