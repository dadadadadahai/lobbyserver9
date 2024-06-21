--生肖龙模块
module('diamond',package.seeall)

--生肖龙免费游戏
function PlayFreeGame(diamondInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    diamondInfo.boards = {}
    -- 增加免费游戏次数
    diamondInfo.free.lackTimes = diamondInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    -- 生成免费棋盘和结果

    local data =  table.remove(diamondInfo.free.resdata,1)
    local boards =  data.boards
    diamondInfo.boards = boards
     
    local  winscore = diamondInfo.betgold * data.winMul

    diamondInfo.free.tWinScore = diamondInfo.free.tWinScore +winscore
    if  calc_S(boards) >=3 then
        diamondInfo.free.lackTimes = diamondInfo.free.lackTimes+8
        diamondInfo.free.totalTimes = diamondInfo.free.totalTimes+8
    end 
    -- 判断是否结算
    if diamondInfo.free.lackTimes <= 0 then
        if diamondInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, diamondInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.DIAMOND)
        end
    end
    for _, winline in ipairs(data.winlines) do
        winline[3] = winline[3] * diamondInfo.betgold
    end

    if not table.empty(data.bonus) then
        data.bonus.winScore =   data.bonus.mul   * diamondInfo.betgold
    end
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
        {type= 'free',chessdata = boards},
        {}
    )
  
    local res = GetResInfo(uid, diamondInfo, gameType)
    res.winScore = winscore
    res.winlines = data.winlines
    res.bonus = data.bonus
    res.free = packFree(diamondInfo)
    if diamondInfo.free.lackTimes <= 0 then
        diamondInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,diamondInfo)
    return res
end


--生肖龙免费游戏
function PlayFreeGameDemo(diamondInfo,uid,gameType)
    -- 清理棋盘信息
    diamondInfo.boards = {}
    -- 增加免费游戏次数
    diamondInfo.free.lackTimes = diamondInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    -- 生成免费棋盘和结果

    local data =  table.remove(diamondInfo.free.resdata,1)
    local boards =  data.boards
    diamondInfo.boards = boards
     
    local  winscore = diamondInfo.betgold * data.winMul

    diamondInfo.free.tWinScore = diamondInfo.free.tWinScore +winscore
    if  calc_S(boards) >=3 then
        diamondInfo.free.lackTimes = diamondInfo.free.lackTimes+8
        diamondInfo.free.totalTimes = diamondInfo.free.totalTimes+8
    end 
    for _, winline in ipairs(data.winlines) do
        winline[3] = winline[3] * diamondInfo.betgold
    end

    if not table.empty(data.bonus) then
        data.bonus.winScore =   data.bonus.mul   * diamondInfo.betgold
    end
    -- 判断是否结算
    if diamondInfo.free.lackTimes <= 0 then
        if diamondInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT, diamondInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.DIAMOND)
        end
    end
    local res = GetResInfo(uid, diamondInfo, gameType)
    res.winScore = winscore
    res.winlines = data.winlines
    res.bonus = data.bonus
    res.free = packFree(diamondInfo)
    if diamondInfo.free.lackTimes <= 0 then
        diamondInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,diamondInfo)
    return res
end
