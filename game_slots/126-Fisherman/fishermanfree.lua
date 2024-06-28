module('Fisherman', package.seeall)
Table = 'game126fisherman'
LineNum = 10
GameId = 126


J = 100
S = 70


function Free(gameType, datainfo,uid)
    local resultGame =   table.remove(datainfo.free.resdata,1)
    datainfo.free.lackTimes = datainfo.free.lackTimes  -1
    datainfo.free.FreeInfo.Wnums = datainfo.free.FreeInfo.Wnums  +  resultGame.wNum
    datainfo.boards = resultGame.boards
    local winScore = resultGame.sumMul *datainfo.betGold + resultGame.wumul * datainfo.betMoney
    if winScore > 0 then
        datainfo.free.tWinScore = datainfo.free.tWinScore + winScore
    end 

    local achip = chessuserinfodb.RUserChipsGet(uid)
    -- 整理中奖线数据
    for _, winline in ipairs(resultGame.winLines) do
        winline[3] = winline[3] * datainfo.betGold
    end
    local isinc
    if datainfo.free.lackTimes<=0 then
        local curFreeInfoWnums = datainfo.free.FreeInfo.Wnums >12 and 12 or datainfo.free.FreeInfo.Wnums
        local curlevel = math.floor(curFreeInfoWnums/4) +1
        if curlevel > datainfo.free.FreeInfo.Level then 
            datainfo.free.lackTimes =  datainfo.free.lackTimes + 10 * (curlevel -datainfo.free.FreeInfo.Level )
            datainfo.free.totalTimes =  datainfo.free.totalTimes +  datainfo.free.lackTimes
            datainfo.free.FreeInfo.Level = curlevel
            isinc = true 
        else 
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD,datainfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.FISHERMAN)
            if datainfo.free.isBuy==1 then
                --加流水
                local userinfo = unilight.getdata('userinfo',uid)
                userinfo.gameData.slotsBet = userinfo.gameData.slotsBet + table_126_buyfree[1].price * datainfo.betMoney
                userinfo.property.isInPresentChips = 0
            end
            datainfo.free={}
        end
    end
    -- 返回数据
    local res = GetResInfo(uid, datainfo, gameType)
    res.winScore = winScore
    res.winlines = resultGame.winLines
    res.iconsAttachData = resultGame.iconsAttachData
    res.disInfo = resultGame.disInfo
    res.isfake = resultGame.isfake or 0 
    res.isinc = isinc
    SaveGameInfo(uid,gameType,datainfo)
    gameDetaillog.SaveDetailGameLog(
        uid,
        os.time(),
        GameId,
        gameType,
        0,
        achip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='free'},
        {},
        {}
    )
    return res
end

function FreeDemo(gameType, datainfo,uid)
    local resultGame =   table.remove(datainfo.free.resdata,1)
    datainfo.free.lackTimes = datainfo.free.lackTimes  -1
    datainfo.free.FreeInfo.Wnums = datainfo.free.FreeInfo.Wnums  +  resultGame.wNum
    datainfo.boards = resultGame.boards
    local winScore = resultGame.sumMul *datainfo.betGold + resultGame.wumul * datainfo.betMoney
    if winScore > 0 then
        datainfo.free.tWinScore = datainfo.free.tWinScore + winScore
    end 
    -- 整理中奖线数据
    for _, winline in ipairs(resultGame.winLines) do
        winline[3] = winline[3] * datainfo.betGold
    end
    local isinc
    if datainfo.free.lackTimes<=0 then
        local curFreeInfoWnums = datainfo.free.FreeInfo.Wnums >12 and 12 or datainfo.free.FreeInfo.Wnums
        local curlevel = math.floor(curFreeInfoWnums/4) +1
        if curlevel > datainfo.free.FreeInfo.Level then 
            datainfo.free.lackTimes =  datainfo.free.lackTimes + 10 * (curlevel -datainfo.free.FreeInfo.Level )
            datainfo.free.totalTimes =  datainfo.free.totalTimes +  datainfo.free.lackTimes
            datainfo.free.FreeInfo.Level = curlevel
            isinc = true 
        else 
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT,datainfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.FISHERMAN)
            datainfo.free={}
        end
    end
    -- 返回数据
    local res = GetResInfo(uid, datainfo, gameType)
    res.winScore = winScore
    res.winlines = resultGame.winLines
    res.iconsAttachData = resultGame.iconsAttachData
    res.disInfo = resultGame.disInfo
    res.isfake = resultGame.isfake or 0 
    res.isinc = isinc
    SaveGameInfo(uid,gameType,datainfo)
    return res
end