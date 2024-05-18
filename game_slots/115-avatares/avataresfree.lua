--阿凡达模块
module('Avatares',package.seeall)

--阿凡达免费游戏
function PlayFreeGame(avataresInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    avataresInfo.boards = {}
    -- 增加免费游戏次数
    avataresInfo.free.times = avataresInfo.free.times + 1
    -- 特殊模式触发图标位置
    local tringerPoints = {}
    -- 生成免费棋盘和结果
    local resultGame,avataresInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,avataresInfo,avataresInfo.betMoney,GetBoards)
    tringerPoints.freeTringerPoints = resultGame.freeTringerPoints
    avataresInfo.free.tWinScore = avataresInfo.free.tWinScore + resultGame.winScore
    -- 返回数据
    local res = GetResInfo(uid, avataresInfo, gameType, tringerPoints, nil)
    -- 判断是否结算
    if avataresInfo.free.times >= avataresInfo.free.totalTimes then
        if avataresInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, avataresInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.AVATARES)
        end
    end
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    res.boards = {resultGame.boards}
    res.iconsAttachData = resultGame.iconsAttachData
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        avataresInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards,totalTimes=avataresInfo.free.totalTimes,lackTimes=avataresInfo.free.totalTimes-avataresInfo.free.times,tWinScore=avataresInfo.free.tWinScore},
        {}
    )
    if avataresInfo.free.times >= avataresInfo.free.totalTimes then
        avataresInfo.free.totalTimes = -1                                     -- 总次数
        avataresInfo.free.times = 0                                           -- 游玩次数
        avataresInfo.free.tWinScore = 0                                       -- 已经赢得的钱
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,avataresInfo)
    return res
end