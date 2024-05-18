--火焰连击模块
module('FireCombo',package.seeall)

--火焰连击免费游戏
function PlayFreeGame(firecomboInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    firecomboInfo.boards = {}
    -- 增加免费游戏次数
    firecomboInfo.free.times = firecomboInfo.free.times + 1
    -- 中奖金额
    local winScore = 0
    local winScoreList = {}
    -- 生成免费棋盘和结果
    local resultGame,firecomboInfo = gamecontrol.RealCommonRotate(uid,GameId,gameType,true,firecomboInfo,firecomboInfo.betMoney,GetBoards)
    firecomboInfo.free.tWinScore = firecomboInfo.free.tWinScore + resultGame.winScore
    -- 返回数据
    local res = GetResInfo(uid, firecomboInfo, gameType, resultGame.tringerPoints, nil, resultGame.collect)
    -- 判断是否结算
    if firecomboInfo.free.times >= firecomboInfo.free.totalTimes then
        if firecomboInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, firecomboInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.FIRECOMBO)
        end
    end
    -- 缓存Collect的金额
    -- if table.empty(resultGame.collect) == false then
    --     res.winScore = resultGame.winScore - resultGame.collect.tWinScore
    -- else
    --     res.winScore = resultGame.winScore
    -- end
    res.winScore = resultGame.winScore
    res.winlines = resultGame.winlines
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        firecomboInfo.betMoney,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free',chessdata = resultGame.boards,totalTimes=firecomboInfo.free.totalTimes,lackTimes=firecomboInfo.free.totalTimes-firecomboInfo.free.times,tWinScore=firecomboInfo.free.tWinScore},
        {}
    )
    if firecomboInfo.free.times >= firecomboInfo.free.totalTimes then
        firecomboInfo.free.totalTimes = -1                                     -- 总次数
        firecomboInfo.free.times = 0                                           -- 游玩次数
        firecomboInfo.free.tWinScore = 0                                       -- 已经赢得的钱
    end
    -- 保存数据库信息
    firecomboInfo.collect = nil
    SaveGameInfo(uid,gameType,firecomboInfo)
    return res
end
