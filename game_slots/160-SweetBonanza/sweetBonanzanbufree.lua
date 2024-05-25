module('sweetBonanza', package.seeall)
Table = 'game160sweetBonanza'
LineNum = 1
GameId = 160


J = 100
S = 70
--购买免费
function BuyFree(gameType,betindex,datainfo,datainfos)
    if table.empty(datainfo.free)==false then
        return{
            errno = ErrorDefine.ERROR_INFREEING,
        }
    end
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)

    local betMoney = betconfig[betindex]
    local chip = table_160_buyfree[1].price * betMoney
        -- 执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB,chip ,"波南扎购买免费")
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
    local alldisInfo = gameImagePool.RealCommonRotate(datainfos._id,GameId,gameType,2,sweetBonanza,{betchip=betMoney,betIndex=betindex,gameId=GameId,gameType=gameType,betchips=chip})
    local disInfo =  table.remove(alldisInfo,1)
    local betchip = betMoney * LineNum
    local disInfos,realMul ,bombdataMap,ssum = parseData(betMoney,disInfo)
    local  Smul =  calcSMul(ssum)
    local winScore = (realMul+Smul)*betchip
    if winScore > 0 then 
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.SWEETBONANZA)
    end 
    local boards= table.clone(disInfos[1].chessdata)
    local iconsAttachData = disInfos[1].iconsAttachData
    for i=1,#disInfos-1 do
        disInfos[i].chessdata = disInfos[i+1].chessdata
        disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
    end
    table.remove(disInfos,#disInfos)
   
    datainfo.free={
        totalTimes=10,
        lackTimes=10,
        tWinScore = 0,
        tMul = 0,
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