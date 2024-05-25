module('fruitparty2', package.seeall)
Table = 'game162fruitparty2'
LineNum = 1
GameId = 162

J = 100
S = 70

function BuyFree(gameType,betindex,datainfo,datainfos)
    if table.empty(datainfo.free)==false then
        return{
            errno = ErrorDefine.ERROR_INFREEING,
        }
    end
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)

    local betMoney = betconfig[betindex]
    local chip = table_162_buyfree[1].price * betMoney
        -- 执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB,chip ,"水果派对2购买免费")
    if ok==false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    --入库存
    SuserId.uid = datainfos._id
    local userinfo = unilight.getdata('userinfo', datainfos._id)
    if userinfo.property.totalRechargeChips<=3000 then
        userinfo.point.IsNormal = 0
    end
    if userinfo.property.presentChips>0 then
        userinfo.property.isInPresentChips=1
    end

    datainfo.betMoney = betMoney
    --取图库2
    local alldisInfo = gameImagePool.RealCommonRotate(datainfos._id,GameId,gameType,2,fruitparty2,{betchip=betMoney,betIndex=betindex,gameId=GameId,gameType=gameType,betchips=chip})

    local disInfo =  table.remove(alldisInfo,1)
    local betchip = betMoney * LineNum
    local disInfos,realMul ,ssums= parseData(betMoney,disInfo)
    local  Smul =  calcSMul(ssums)
    local winScore = (realMul+Smul)*betchip
    if winScore > 0 then 
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.FRUITPARTY2)
    end 
    local lastDis = disInfos[#disInfos]
    
    local sNum = 0
    for col=1,#lastDis.chessdata do
        for row=1,#lastDis.chessdata[col] do
            if lastDis.chessdata[col][row] ==70 then
                sNum = sNum +1 
            end
        end
    end

    local boards= table.clone(disInfos[1].chessdata)
    local iconsAttachData = disInfos[1].iconsAttachData
    for i=1,#disInfos-1 do
        disInfos[i].chessdata = disInfos[i+1].chessdata
       -- disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
    end
    table.remove(disInfos,#disInfos)

    local freetimes = CalcFreeNum(sNum)
    dump(freetimes,"freetimes",1)
    datainfo.free={
        totalTimes=freetimes,
        lackTimes=freetimes,
        tWinScore = 0,
        mulInfoList={},
        isBuy = 1,
        resdata=alldisInfo
    }
    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        bAllLine = LineNum,
        payScore = 0,
        winScore = winScore,
        winLines = {},
        boards = boards,
   
        iconsAttachData = iconsAttachData,
        features={
            free = packFree(datainfo),

        },
        extraData = {
            disInfo = disInfos
        }
    }
    --记录系统级流水
    gameDetaillog.updateRoomFlow(GameId,gameType,0,1,chip,0,userinfo)
    -- WithdrawCash.ResetWithdawTypeState(datainfos._id,0)
    unilight.update(Table, datainfos._id, datainfos)
    return res
end