--生肖龙模块
module('Dragon',package.seeall)

--生肖龙免费游戏
function PlayFreeGame(dragonInfo,uid,gameType)
    -- 游戏后台记录所需初始信息
    local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    -- 清理棋盘信息
    dragonInfo.boards = {}
    -- 增加免费游戏次数
    dragonInfo.free.lackTimes = dragonInfo.free.lackTimes - 1
    -- jackpot发送客户端的数据表
    -- 生成免费棋盘和结果

    local data =  table.remove(dragonInfo.free.resdata,1)
    local boards =  data.boards
    dragonInfo.boards = boards
     
    local  winscore = dragonInfo.betgold * data.sumMul

    dragonInfo.free.tWinScore = dragonInfo.free.tWinScore +winscore

    -- 判断是否结算
    if dragonInfo.free.lackTimes <= 0 then
        if dragonInfo.free.tWinScore > 0 then
            -- 获取奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, dragonInfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.DRAGON)
        end
    end
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        dragonInfo.betMoney,
        dragonInfo.betgold,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type= 'normal',chessdata = boards},
        {}
    )
    -- WithdrawCash.ResetWithdawTypeState(datainfos._id,0)

    local res = {
        errno = 0,
        betIndex = dragonInfo.betindex,
        bAllLine = LineNum,
        payScore = 0,
        winScore = winscore,
        winLines = data.reswinlines,
        boards = boards,
        mulList= data.mulList,
        sumMulList = sumtable(data.mulList),
        sumMul = data.sumMul,
        free = packFree(dragonInfo),

    }
    if dragonInfo.free.lackTimes <= 0 then
        dragonInfo.free = {}
        dragonInfo.isFree = nil 
    end
    -- 保存数据库信息
    SaveGameInfo(uid,gameType,dragonInfo)
    return res
end
