module('fruitparty2', package.seeall)
Table = 'game162fruitparty2'
LineNum = 1
GameId = 162

J = 100
S = 70

function Free(gameId, gameType, datainfo,datainfos)
    local chip = datainfo.betMoney * LineNum
    local disInfo =   table.remove(datainfo.free.resdata,1)
    local disInfos,tmul,ssums = parseData(datainfo.betMoney,disInfo)
    local  Smul =  calcSMul(ssums)
    local boards= table.clone(disInfos[1].chessdata)
    local yyy = table.clone(disInfos[1].chessdata) --服务器打印跟客户端收到的数据BOARDS不一样加一个
    local iconsAttachData = disInfos[1].iconsAttachData
    for i=1,#disInfos-1 do
        disInfos[i].chessdata = disInfos[i+1].chessdata
       -- disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
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
    if sNum >= 3 then
        datainfo.free.lackTimes = datainfo.free.lackTimes + 5
        datainfo.free.totalTimes = datainfo.free.totalTimes + 5
    end
    table.remove(disInfos,#disInfos)
    local winScore =  chip*(tmul+Smul)
    datainfo.free.lackTimes = datainfo.free.lackTimes  -1
    datainfo.free.tWinScore = datainfo.free.tWinScore + winScore
    local achip = chessuserinfodb.RUserChipsGet(datainfos._id)
    if datainfo.free.lackTimes<=0 then
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD,datainfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.FRUITPARTY2)
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
        }
    }
    if datainfo.free.isBuy==0 then
        WithdrawCash.GetBetInfo(datainfos._id,Table,gameType,res,false)
    else
        if datainfo.free.lackTimes<=0 then
            local c = table_162_buyfree[1].price * datainfo.betMoney
            WithdrawCash.AddBet(datainfos._id,datainfo.free.tWinScore,c)
        end
    end
    if datainfo.free.lackTimes<=0 then
        if datainfo.free.isBuy==1 then
            --加流水
            local userinfo = unilight.getdata('userinfo',datainfos._id)
            userinfo.gameData.slotsBet = userinfo.gameData.slotsBet + table_162_buyfree[1].price * datainfo.betMoney
            userinfo.property.isInPresentChips = 0
        end
        datainfo.free={}
    end
    gameDetaillog.SaveDetailGameLog(
        datainfos._id,
        os.time(),
        gameId,
        gameType,
        chip,
        achip,
        chessuserinfodb.RUserChipsGet(datainfos._id),
        0,
        {type='free'},
        {},
        {}
    )
    unilight.update(Table, datainfos._id, datainfos)
    return res
end