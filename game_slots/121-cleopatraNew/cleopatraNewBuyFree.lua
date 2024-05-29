module('cleopatraNew', package.seeall)
Table = 'game121cleopatra'
LineNum = 1
GameId = 121


J = 100
S = 70
--购买免费
function BuyFree(gameType,betindex,datainfo,uid)
    if table.empty(datainfo.free)==false then
        return{
            errno = ErrorDefine.ERROR_INFREEING,
        }
    end
        -- 游戏后台记录所需初始信息
     local sTime = os.time()
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
   
    local betMoney = betconfig[betindex]
    local chip = table_121_buyfree[1].price * betMoney
        -- 执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB,chip ,"宙斯购买免费")
    if ok==false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    --入库存
    SuserId.uid = uid
    -- local userinfo = unilight.getdata('userinfo', uid)
    -- if userinfo.property.totalRechargeChips<=3000 then
    --     userinfo.point.IsNormal = 0
    -- end
    -- if userinfo.property.presentChips>0 then
    --     userinfo.property.isInPresentChips=1
    -- end

    datainfo.betMoney = betMoney
    --取图库2
    local alldisInfo,realMulall = gameImagePool.RealCommonRotate(uid,GameId,gameType,2,cleopatraNew,{betchip=betMoney,betIndex=betindex,gameId=GameId,gameType=gameType,betchips=betMoney})

    local disInfo =  table.remove(alldisInfo,1)
    local betchip = betMoney * LineNum
    local disInfos,realMul,bombdataMap,ssum = parseData(betMoney,disInfo)
    local  Smul =  calcSMul(ssum)
    local winScore = (realMul+Smul)*betchip
    if winScore > 0 then 
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.CLEOPATRANEW)
    end 
    local boards= table.clone(disInfos[1].chessdata)
    local iconsAttachData = disInfos[1].iconsAttachData
    for i=1,#disInfos-1 do
        disInfos[i].chessdata = disInfos[i+1].chessdata
        disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
    end
    table.remove(disInfos,#disInfos)
   
    datainfo.free={
        totalTimes=15,
        lackTimes=15,
        tWinScore = 0,
        tMul = 0,
        sMul = 0 ,
        allmul = realMulall,
        normalwinScore = winScore,
        mulInfoList={},
        isBuy = 1,
        resdata=alldisInfo
    }
    -- 增加后台历史记录
    gameDetaillog.SaveDetailGameLog(
        uid,
        sTime,
        GameId,
        gameType,
        chip,
        reschip,
        chessuserinfodb.RUserChipsGet(uid),
        0,
        {type='normal',chessdata = boards},
        {}
    )

    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        bAllLine = LineNum,
        payScore =chip,
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
    SaveGameInfo(uid,gameType,datainfo)
    return res
end


function BuyFreeDemo(gameType,betindex,datainfo,uid)
    if table.empty(datainfo.free)==false then
        return{
            errno = ErrorDefine.ERROR_INFREEING,
        }
    end
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
   
    local betMoney = betconfig[betindex]
    local chip = table_121_buyfree[1].price * betMoney
        -- 执行扣费
    local remainder, ok = chessuserinfodb.WGoldChange(uid, Const.PACK_OP_TYPE.SUB,chip ,"宙斯购买免费")
    if ok==false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = betMoney
    --取图库2
    local alldisInfo ,realMulall= gameImagePool.RealCommonRotate(uid,GameId,gameType,2,cleopatraNew,{betchip=betMoney,demo = IsDemo(uid),betIndex=betindex,gameId=GameId,gameType=gameType,betchips=betMoney})

    local disInfo =  table.remove(alldisInfo,1)
    local betchip = betMoney * LineNum
    local disInfos,realMul,bombdataMap,ssum = parseData(betMoney,disInfo)
    local  Smul =  calcSMul(ssum)
    local winScore = (realMul+Smul)*betchip
    if winScore > 0 then 
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT,winScore, Const.GOODS_SOURCE_TYPE.CLEOPATRANEW)
    end 
    local boards= table.clone(disInfos[1].chessdata)
    local iconsAttachData = disInfos[1].iconsAttachData
    for i=1,#disInfos-1 do
        disInfos[i].chessdata = disInfos[i+1].chessdata
        disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
    end
    table.remove(disInfos,#disInfos)
   
    datainfo.free={
        totalTimes=15,
        lackTimes=15,
        tWinScore = 0,
        tMul = 0,
        sMul = 0 ,
        allmul = realMulall,
        normalwinScore = winScore,
        mulInfoList={},
        isBuy = 1,
        resdata=alldisInfo
    }

    local res = {
        errno = 0,
        betIndex = datainfo.betindex,
        bAllLine = LineNum,
        payScore =chip,
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
    SaveGameInfo(uid,gameType,datainfo)
    return res
end