module('sweetBonanza', package.seeall)
Table = 'game160sweetBonanza'
LineNum = 1
GameId = 160
-- table_160_normalspin = import 'table/game/160/table_160_normalspin'
-- table_160_mul = import 'table/game/160/table_160_mul'
-- table_160_paytable = import 'table/game/160/table_160_paytable'
-- table_160_jackpot_chips = import 'table/game/160/table_160_jackpot_chips'
-- table_160_jackpot_add_per = import 'table/game/160/table_160_jackpot_add_per'
-- table_160_jackpot_bomb = import 'table/game/160/table_160_jackpot_bomb'
-- -- table_160_jackpot_scale = import 'table/game/160/table_160_jackpot_scale'
-- table_160_jackpot_bet = import 'table/game/160/table_160_jackpot_bet'
-- table_mul_gamety1 = import 'table/game/160/table_mul_gamety1'
-- table_mul_gamety2 = import 'table/game/160/table_mul_gamety2'
-- table_mul_gamety3 = import 'table/game/160/table_mul_gamety3'

J = 100
S = 70
-- sweetBonanza
function Get(gameType, uid)
    local datainfos = unilight.getdata(Table, uid)
    if table.empty(datainfos) then
        datainfos = {
            _id = uid,
            roomInfo = {},
            gameType = 0,
        }
        unilight.savedata(Table, datainfos)
    end
    if table.empty(datainfos.roomInfo[gameType]) then
        local rInfo = {
            betindex = 1,
            betMoney = 0,
            free={},            --免费模式
            isInHight=false ,        --是否处于高下注模式 0:不是 1:是
        }
        datainfos.roomInfo[gameType] = rInfo
        unilight.update(Table, datainfos._id, datainfos)
    end
    local datainfo = datainfos.roomInfo[gameType]
    return datainfo, datainfos
end
--购买高中奖率
function BuyHighBet(highLevel,datainfo,datainfos)
    datainfo.isInHight = highLevel
    unilight.update(Table, datainfos._id, datainfos)
    return {
        errno = 0,
        isInHight=highLevel,
    }
end
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
        wMul = 0 ,
        resdata=alldisInfo
    }
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
-- 普通拉动
function Normal(gameId,gameType, betindex, datainfo, datainfos, uid)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betMoney = betconfig[betindex]
    --print('betconfig='..json.encode(betconfig))
    local chip = betMoney * LineNum
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = ErrorDefine.ERROR_PARAM,
        }
    end
    local userinfo = unilight.getdata('userinfo', datainfos._id)
    local sTime = os.time()
    if datainfo.isInHight  then
        chip = math.floor(chip/table_160_buygailv[1].betChange)
    end
    -- 执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB, chip,
        "波南扎玩法投注")
    if ok == false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = chip
    datainfo.betindex = betindex
    --启用图库模式
    local alldisInfo,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,sweetBonanza,{betchip=betMoney,betIndex=betindex,gameId=GameId,gameType=gameType,betchips=chip})
    if imageType == 2 or imageType == 3 then 
        local disInfo =  table.remove(alldisInfo,1)
        local betchip = chip 
        local disInfos,realMul,bombdataMap,ssum  = parseData(betMoney,disInfo)
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
            wMul = 0 ,
            mulInfoList={},
            isBuy = 0,
            resdata=alldisInfo
        }
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
    else 
        local disInfos ,realMul2= parseData(betMoney,alldisInfo)
        dump(string.format("realMul%d  realMuls %d",realMul,realMul2))
        local winScore = realMul*chip
        if winScore >0 then 
            BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.SWEETBONANZA)
        end 
        local boards=table.clone(disInfos[1].chessdata)
        local iconsAttachData = disInfos[1].iconsAttachData
        for i=1,#disInfos-1 do
            disInfos[i].chessdata = disInfos[i+1].chessdata
            disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
        end
        table.remove(disInfos,#disInfos)
        -- 增加后台历史记录
        gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            datainfo.betMoney,
            remainder+chip,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {type='normal',chessdata = boards},
            {}
        )
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
                jackpot={},
                free = {},

            },
            extraData = {
                disInfo = disInfos
            }
        }
        return res
    end 
end

function Free(gameId, gameType, datainfo,datainfos)
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
        datainfo.free.sMul =  boommuls
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
    local winScore =  chip*(tmul+Smul) *  (datainfo.free.sMul == 0 and 1 or  datainfo.free.sMul)
    datainfo.free.lackTimes = datainfo.free.lackTimes  -1
    datainfo.free.tWinScore = datainfo.free.tWinScore + winScore
    local achip = chessuserinfodb.RUserChipsGet(datainfos._id)
    if table.empty(datainfo.free.resdata)  then --倍数超过300倍就不会继续下去没有数据了
        datainfo.free.lackTimes = 0 
    end 
    if datainfo.free.lackTimes<=0 then
        if datainfo.free.tMul>0 then
            datainfo.free.tWinScore = datainfo.free.tWinScore * datainfo.free.tMul
        end
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD,datainfo.free.tWinScore, Const.GOODS_SOURCE_TYPE.SWEETBONANZA)
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
        WithdrawCash.GetBetInfo(datainfos._id,Table,gameType,res,false)
    else
        if datainfo.free.lackTimes<=0 then
            local c = table_160_buyfree[1].price * datainfo.betMoney
            WithdrawCash.AddBet(datainfos._id,datainfo.free.tWinScore,c)
        end
    end
    if datainfo.free.lackTimes<=0 then
        if datainfo.free.isBuy==1 then
            --加流水
            local userinfo = unilight.getdata('userinfo',datainfos._id)
            userinfo.gameData.slotsBet = userinfo.gameData.slotsBet + table_160_buyfree[1].price * datainfo.betMoney
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

function calcSMul(sNum)
    if sNum==4 then
        return 6
    elseif sNum==5 then
        return 10
    elseif sNum==6 then
        return 200
    end
    return 0
end