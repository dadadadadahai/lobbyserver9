module('sweetBonanza', package.seeall)
Table = 'game160sweetBonanza'
LineNum = 1
GameId = 160


J = 100
S = 70
function Free(gameType, datainfo,uid)
    local chip = datainfo.betMoney * LineNum
    local disInfo =   table.remove(datainfo.free.resdata,1)
    local disInfos,tmul ,bombdataMap,ssum= parseData(datainfo.betMoney,disInfo)
    local boommuls = table.sum(bombdataMap,function (v)
        return v.mul 
    end)
    local boards= table.clone(disInfos[1].chessdata)
  
    local iconsAttachData = disInfos[1].iconsAttachData
    if tmul>0 then
        for _,value in ipairs(iconsAttachData) do
            table.insert(datainfo.free.mulInfoList,value.data.mul)
            datainfo.free.tMul = datainfo.free.tMul+value.data.mul
        end
       
    end
    for i=1,#disInfos-1 do
        disInfos[i].chessdata = disInfos[i+1].chessdata
        disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
        if tmul>0 then
            for _,value in ipairs(disInfos[i].iconsAttachData) do
                table.insert(datainfo.free.mulInfoList,value.data.mul)
                datainfo.free.tMul = datainfo.free.tMul+value.data.mul
            end
        end
    end
    local lastDis = disInfos[#disInfos]
    local sNum = 0
    for col=1,#lastDis.chessdata do
        for row=1,#lastDis.chessdata[col] do
            if lastDis.chessdata[col][row]==70 then
                sNum = sNum +1 
            end
        end
    end
    dump(string.format("sNum%d  sum%d ",sNum,ssum))
    if sNum >= 3 then
        datainfo.free.lackTimes = datainfo.free.lackTimes + 5
        datainfo.free.totalTimes = datainfo.free.totalTimes + 5
    end
    table.remove(disInfos,#disInfos)
    local  Smul =  calcSMul(ssum)
    local winScore =  chip*(tmul+Smul) *  (boommuls == 0 and 1 or  boommuls)
    datainfo.free.lackTimes = datainfo.free.lackTimes  -1
    datainfo.free.tWinScore = datainfo.free.tWinScore + winScore
    local achip = chessuserinfodb.RUserChipsGet(uid)
    if table.empty(datainfo.free.resdata)  then --倍数超过300倍就不会继续下去没有数据了
        datainfo.free.lackTimes = 0 
    end 
    if datainfo.free.lackTimes<=0 then
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD,datainfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.SWEETBONANZA)
    end
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        bAllLine = LineNum,
        payScore = datainfo.betMoney * LineNum,
        winScore = winScore,
        winLines = {},
        boards = boards,
        iconsAttachData = iconsAttachData,
        features={
            free=packFree(datainfo),
        },
        extraData = {
            disInfo = disInfos,
        },
    
        bombdataMap = bombdataMap
    }
    if datainfo.free.isBuy==0 then
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,false)
    else
        if datainfo.free.lackTimes<=0 then
            local c = table_160_buyfree[1].price * datainfo.betMoney
            WithdrawCash.AddBet(uid,datainfo.free.tWinScore,c)
        end
    end
    if datainfo.free.lackTimes<=0 then
        if datainfo.free.isBuy==1 then
            --加流水
            local userinfo = unilight.getdata('userinfo',uid)
            userinfo.gameData.slotsBet = userinfo.gameData.slotsBet + table_160_buyfree[1].price * datainfo.betMoney
            userinfo.property.isInPresentChips = 0
        end
        datainfo.free={}
    end
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
    SaveGameInfo(uid,gameType,datainfo)
    return res
end

function FreeDemo(gameType, datainfo,uid)
    local chip = datainfo.betMoney * LineNum
    local disInfo =   table.remove(datainfo.free.resdata,1)
    local disInfos,tmul ,bombdataMap,ssum= parseData(datainfo.betMoney,disInfo)
    local boommuls = table.sum(bombdataMap,function (v)
        return v.mul 
    end)
    local boards= table.clone(disInfos[1].chessdata)
  
    local iconsAttachData = disInfos[1].iconsAttachData
    if tmul>0 then
        for _,value in ipairs(iconsAttachData) do
            table.insert(datainfo.free.mulInfoList,value.data.mul)
            datainfo.free.tMul = datainfo.free.tMul+value.data.mul
        end
       
    end
    for i=1,#disInfos-1 do
        disInfos[i].chessdata = disInfos[i+1].chessdata
        disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
        if tmul>0 then
            for _,value in ipairs(disInfos[i].iconsAttachData) do
                table.insert(datainfo.free.mulInfoList,value.data.mul)
                datainfo.free.tMul = datainfo.free.tMul+value.data.mul
            end
        end
    end
    local lastDis = disInfos[#disInfos]
    local sNum = 0
    for col=1,#lastDis.chessdata do
        for row=1,#lastDis.chessdata[col] do
            if lastDis.chessdata[col][row]==70 then
                sNum = sNum +1 
            end
        end
    end
    dump(string.format("sNum%d  sum%d ",sNum,ssum))
    if sNum >= 3 then
        datainfo.free.lackTimes = datainfo.free.lackTimes + 5
        datainfo.free.totalTimes = datainfo.free.totalTimes + 5
    end
    table.remove(disInfos,#disInfos)
    local  Smul =  calcSMul(ssum)
    local winScore =  chip*(tmul+Smul) *  (boommuls == 0 and 1 or  boommuls)
    datainfo.free.lackTimes = datainfo.free.lackTimes  -1
    datainfo.free.tWinScore = datainfo.free.tWinScore + winScore

    if datainfo.free.lackTimes<=0 then
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT,datainfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.SWEETBONANZA)
    end
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        bAllLine = LineNum,
        payScore = datainfo.betMoney * LineNum,
        winScore = winScore,
        winLines = {},
        boards = boards,
        iconsAttachData = iconsAttachData,
        features={
            free=packFree(datainfo),
        },
        extraData = {
            disInfo = disInfos,
        },
    
        bombdataMap = bombdataMap
    }

    if datainfo.free.lackTimes<=0 then

        datainfo.free={}
    end
  
    SaveGameInfo(uid,gameType,datainfo)
    return res
end