--生肖龙模块
module('GreatRhinoceros',package.seeall)

--生肖龙免费游戏
function PlayFreeGame(GRInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    GRInfo.boards = {}
    -- 增加免费游戏次数
    GRInfo.free.lackTimes = GRInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    -- 生成免费棋盘和结果

    local data =  table.remove(GRInfo.free.resdata,1)
    local boards =  data.boards
    GRInfo.boards = boards
     
    local  winscore = GRInfo.betgold * data.winMul

    GRInfo.free.tWinScore = GRInfo.free.tWinScore +winscore
    if  calc_S(boards) >=3 then
        GRInfo.free.lackTimes = GRInfo.free.lackTimes+8
        GRInfo.free.totalTimes = GRInfo.free.totalTimes+8
    end 
    -- 判断是否结算
    if GRInfo.free.lackTimes <= 0 then
        if GRInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, GRInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.GREATRHINOCEROS)
        end
    end
    for _, winline in ipairs(data.winlines) do
        winline[3] = winline[3] * GRInfo.betgold
    end

    if not table.empty(data.bonus) then
        data.bonus.winScore =   data.bonus.mul   * GRInfo.betgold
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
  
    local res = GetResInfo(uid, GRInfo, gameType)
    res.winScore = winscore
    res.winlines = data.winlines
    res.bonus = data.bonus
    res.free = packFree(GRInfo)
    if GRInfo.free.lackTimes <= 0 then
        GRInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,GRInfo)
    return res
end


--生肖龙免费游戏
function PlayFreeGameDemo(GRInfo,uid,gameType)
    -- 清理棋盘信息
    GRInfo.boards = {}
    -- 增加免费游戏次数
    GRInfo.free.lackTimes = GRInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    -- 生成免费棋盘和结果

    local data =  table.remove(GRInfo.free.resdata,1)
    local boards =  data.boards
    GRInfo.boards = boards
     
    local  winscore = GRInfo.betgold * data.winMul

    GRInfo.free.tWinScore = GRInfo.free.tWinScore +winscore
    if  calc_S(boards) >=3 then
        GRInfo.free.lackTimes = GRInfo.free.lackTimes+8
        GRInfo.free.totalTimes = GRInfo.free.totalTimes+8
    end 
    for _, winline in ipairs(data.winlines) do
        winline[3] = winline[3] * GRInfo.betgold
    end

    if not table.empty(data.bonus) then
        data.bonus.winScore =   data.bonus.mul   * GRInfo.betgold
    end
    -- 判断是否结算
    if GRInfo.free.lackTimes <= 0 then
        if GRInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT, GRInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.GREATRHINOCEROS)
        end
    end
    local res = GetResInfo(uid, GRInfo, gameType)
    res.winScore = winscore
    res.winlines = data.winlines
    res.bonus = data.bonus
    res.free = packFree(GRInfo)
    if GRInfo.free.lackTimes <= 0 then
        GRInfo.free = {}
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,GRInfo)
    return res
end
