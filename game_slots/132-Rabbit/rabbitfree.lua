--兔子模块
module('Rabbit',package.seeall)

--兔子免费游戏
function PlayFreeGame(rabbitInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    rabbitInfo.boards = {}
    -- 增加免费游戏次数
    rabbitInfo.free.lackTimes = rabbitInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    local jackpot = {}
    local resultGame = rabbitInfo.freeInfo[1]
    table.remove(rabbitInfo.freeInfo,1)

    local winScore = rabbitInfo.betgold * resultGame.winMul
    rabbitInfo.free.tWinScore = rabbitInfo.free.tWinScore + winScore
    rabbitInfo.iconsAttachData = resultGame.iconsAttachData
    if not table.empty(rabbitInfo.iconsAttachData) and  not table.empty(rabbitInfo.iconsAttachData.boardsInfo) then
        for _, value in pairs(rabbitInfo.iconsAttachData.boardsInfo ) do
            value.mul = value.mul /10
        end 
    end
    -- 返回数据
    local res = GetResInfo(uid, rabbitInfo, gameType, resultGame.tringerPoints)
    -- 判断是否结算
    if rabbitInfo.free.lackTimes <= 0 then
        if rabbitInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, rabbitInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.RABBIT)
        end
    end
    res.winScore = winScore
    res.boards = {resultGame.boards}
    -- res.extraData = resultGame.extraData
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        0,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards},
        jackpot
    )
    if rabbitInfo.free.lackTimes <= 0 then
        rabbitInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,rabbitInfo)
    return res
end


--兔子免费游戏
function PlayFreeGameDemo(rabbitInfo,uid,gameType)

    -- 清理棋盘信息
    rabbitInfo.boards = {}
    -- 增加免费游戏次数
    rabbitInfo.free.lackTimes = rabbitInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    local jackpot = {}
    local resultGame = rabbitInfo.freeInfo[1]
    table.remove(rabbitInfo.freeInfo,1)

    local winScore = rabbitInfo.betgold * resultGame.winMul
    rabbitInfo.free.tWinScore = rabbitInfo.free.tWinScore + winScore
    rabbitInfo.iconsAttachData = resultGame.iconsAttachData
    if not table.empty(rabbitInfo.iconsAttachData) and  not table.empty(rabbitInfo.iconsAttachData.boardsInfo) then
        for _, value in pairs(rabbitInfo.iconsAttachData.boardsInfo ) do
            value.mul = value.mul /10
        end 
    end
    -- 返回数据
    local res = GetResInfo(uid, rabbitInfo, gameType, resultGame.tringerPoints)
    -- 判断是否结算
    if rabbitInfo.free.lackTimes <= 0 then
        if rabbitInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT, rabbitInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.RABBIT)
        end
    end
    res.winScore = winScore
    res.boards = {resultGame.boards}
    if rabbitInfo.free.lackTimes <= 0 then
        rabbitInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,rabbitInfo)
    return res
end
