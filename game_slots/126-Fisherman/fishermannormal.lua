module('Fisherman', package.seeall)
Table = 'game126fisherman'
LineNum = 1
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
    local resultGame,realMul ,imageType= gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,Fisherman,{betchip=betMoney,betIndex=betindex,gameId=GameId,gameType=gameType,betchips=betGold})
    if  imageType == 3 then 

        -- local disInfo =  table.remove(alldisInfo,1)
        -- local betchip = chip 
        -- local disInfos,realMul2,bombdataMap,ssum = parseData(betMoney,disInfo)
        -- dump(string.format("realMul%d  realMul2%d ssum%d",realMul,realMul2,ssum))
        -- local  Smul =  calcSMul(ssum)
        -- local winScore = (realMul2+Smul)*betchip
        -- if winScore > 0 then 
        --     BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.FISHERMAN)
        -- end 
        -- local boards= table.clone(disInfos[1].chessdata)
        -- local iconsAttachData = disInfos[1].iconsAttachData
        -- for i=1,#disInfos-1 do
        --     disInfos[i].chessdata = disInfos[i+1].chessdata
        --     disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
        -- end
        -- table.remove(disInfos,#disInfos)
    
        -- datainfo.free={
        --     totalTimes=15,
        --     lackTimes=15,
        --     tWinScore = 0,
        --     tMul = 0,
        --     sMul = 0 ,
        --     allmul = realMul,
        --     normalwinScore = winScore,
        --     mulInfoList={},
        --     isBuy = 0,
        --     resdata=alldisInfo
        -- }
        -- local res = {
        --     errno = 0,
        --     betIndex = datainfo.betindex,
        --     bAllLine = LineNum,
        --     payScore = datainfo.betMoney * LineNum,
        --     winScore = winScore,
        --     winLines = {},
        --     boards = boards,
        --     iconsAttachData = iconsAttachData,
        --     features={
        --         free = packFree(datainfo),

        --     },
        --     extraData = {
        --         disInfo = disInfos
        --     }
        -- }
        --   -- 增加后台历史记录
        --   gameDetaillog.SaveDetailGameLog(
        --     uid,
        --     sTime,
        --     GameId,
        --     gameType,
        --     datainfo.betMoney,
        --     reschip,
        --     chessuserinfodb.RUserChipsGet(uid),
        --     0,
        --     {type='normal',chessdata = boards},
        --     {}
        -- )
        -- SaveGameInfo(uid,gameType,datainfo)
        return res
    else
        resultGame.winScore = realMul *  betMoney
        -- 保存棋盘数据
        datainfo.boards = resultGame.boards
        -- 整理中奖线数据
        for _, winline in ipairs(resultGame.winLines) do
            winline[3] = winline[3] * betGold
        end
        if resultGame.winScore >0 then 
          BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.MASTERJOKER)
        end 
        -- 返回数据
        local res = GetResInfo(uid, datainfo, gameType)
        res.winScore = resultGame.winScore
        res.winlines = resultGame.winLines
        res.iconsAttachData = resultGame.iconsAttachData
        gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            datainfo.betMoney,
            reschip,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {type='normal',chessdata = resultGame.boards}
            
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
    local resultGame,realMul ,imageType= gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,Fisherman,{betchip=betMoney, demo = IsDemo(uid),betIndex=betindex,gameId=GameId,gameType=gameType,betchips=betGold})
    if  imageType == 3 then 

        -- local disInfo =  table.remove(alldisInfo,1)
        -- local betchip = chip 
        -- local disInfos,realMul2,bombdataMap,ssum = parseData(betMoney,disInfo)
        -- local  Smul =  calcSMul(ssum)
        -- local winScore = (realMul2+Smul)*betchip
        -- if winScore > 0 then 
        --     BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT,winScore, Const.GOODS_SOURCE_TYPE.FISHERMAN)
        -- end 
        -- local boards= table.clone(disInfos[1].chessdata)
        -- local iconsAttachData = disInfos[1].iconsAttachData
        -- for i=1,#disInfos-1 do
        --     disInfos[i].chessdata = disInfos[i+1].chessdata
        --     disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
        -- end
        -- table.remove(disInfos,#disInfos)
    
        -- datainfo.free={
        --     totalTimes=15,
        --     lackTimes=15,
        --     tWinScore = 0,
        --     tMul = 0,
        --     sMul = 0 ,
        --     allmul = realMul,
        --     normalwinScore = winScore,
        --     mulInfoList={},
        --     isBuy = 0,
        --     resdata=alldisInfo
        -- }
        -- local res = {
        --     errno = 0,
        --     betIndex = datainfo.betindex,
        --     bAllLine = LineNum,
        --     payScore = datainfo.betMoney * LineNum,
        --     winScore = winScore,
        --     winLines = {},
        --     boards = boards,
        --     iconsAttachData = iconsAttachData,
        --     features={
        --         free = packFree(datainfo),

        --     },
        --     extraData = {
        --         disInfo = disInfos
        --     }
        -- }
       
        -- SaveGameInfo(uid,gameType,datainfo)
        return res
    else
        resultGame.winScore = realMul *  betMoney
        -- 保存棋盘数据
        datainfo.boards = resultGame.boards
        -- 整理中奖线数据
        for _, winline in ipairs(resultGame.winLines) do
            winline[3] = winline[3] * betGold
        end
        if resultGame.winScore >0 then 
          BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, resultGame.winScore, Const.GOODS_SOURCE_TYPE.MASTERJOKER)
        end 
        -- 返回数据
        local res = GetResInfo(uid, datainfo, gameType)
        res.winScore = resultGame.winScore
        res.winlines = resultGame.winLines
        res.iconsAttachData = resultGame.iconsAttachData
        gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            datainfo.betMoney,
            reschip,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {type='normal',chessdata = resultGame.boards}
            
        )
     
        -- 保存数据库信息
        SaveGameInfo(uid,gameType,datainfo)
        return res
    end 
end