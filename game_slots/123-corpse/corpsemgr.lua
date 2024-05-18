module('corpse',package.seeall)
local table_stock_tax = import 'table/table_stock_tax'
local table_parameter_parameter = import "table/table_parameter_parameter"
--进入游戏场景消息
function CmdEnterGame(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    local betconfig = gamecommon.GetBetConfig(gameType,LineNum)
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        gameType = datainfos.gameType,
        normalScore = datainfo.normalScore,
        features={
            bonus=PackBonus(datainfo),
        },
    }
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end
function CmdGameOprate(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    datainfos.gameType = gameType
    local res={}
    if datainfo.normalScore>0 and table.empty(datainfo.bonus) then
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, datainfo.normalScore,Const.GOODS_SOURCE_TYPE.CORPSE)
        WithdrawCash.AddBet(uid,datainfo.normalScore-datainfo.normalChip,0)
        datainfo.normalScore = 0
        datainfo.normalChip = 0
        datainfo.addMulNum = 0
        unilight.update(Table, datainfos._id, datainfos)
        local r = {
            errno = 0,
            normalScore = datainfo.normalScore,
            gameType = gameType,
        }
        gamecommon.SendNet(uid,'CorpseRecvNormalScoreGame_S',r)
    end
    if table.empty(datainfo.bonus)==false then
        if msg.extraData==nil then
            res=Bonus(nil,gameType,datainfo,datainfos)
        else
            res=Bonus(msg.extraData.pos,gameType,datainfo,datainfos)
        end
        -- WithdrawCash.GetBetInfo(uid,Table,gameType,res,false)
    else
        res = Normal(gameId,gameType,msg.betIndex,datainfo,datainfos)
        -- WithdrawCash.GetBetInfo(uid,Table,gameType,res,true)
    end
    res.gameType = gameType
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
--[[
    是否翻倍普通中奖
]]
function CmdCorpseDouble(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local res={
        errno = 0,
        normalScore = 0,
        gameType = gameType,
    }
    local datainfo,datainfos = Get(gameType,uid)
    datainfos.gameType = gameType
    if datainfo.normalScore<=0 then
        gamecommon.SendNet(uid,'CorpseDoubleCmd_S',{errno=ErrorDefine.ERROR_RECVNORMAL})
        return
    end
  
    local userinfo = unilight.getdata('userinfo', uid)
    local chips =chessuserinfodb.GetAHeadTolScore(uid)
    local stockgameType = gameType
    SuserId.uid = uid
    userinfo.point.chargeMax = userinfo.point.chargeMax or 0
    -- userinfo.point.IsNormal = 1
    -- if userinfo.property.totalRechargeChips<=3000 then
    --     stock = 1000000
    --     userinfo.point.IsNormal = 0
    -- end
    userinfo.gameData.slotsBet  = userinfo.gameData.slotsBet  + datainfo.normalScore
    local betchip = datainfo.normalScore
    local bchip = chessuserinfodb.RUserChipsGet(datainfos._id)+datainfo.normalScore
    if userinfo.property.presentChips>0 then
        userinfo.property.isInPresentChips=1
    end
    gamestock.RawStock(gameId,gameType,betchip,0,userinfo)
    local maxchips = table_parameter_parameter[36].Parameter
    -- local stock =  gamestock.GetStock(gameId,gameType)
    if math.random(100)<=50 and datainfo.addMulNum<3  and (chips+datainfo.normalScore*2)<=userinfo.point.chargeMax and maxchips>=datainfo.normalScore*2 then
        -- stock = stock - datainfo.normalScore
        local normal = datainfo.normalScore
        datainfo.normalScore = datainfo.normalScore*2
        userinfo.gameData.slotsWin  = userinfo.gameData.slotsWin  + datainfo.normalScore
        res.normalScore = datainfo.normalScore
        datainfo.addMulNum = datainfo.addMulNum + 1
        gamestock.RawStock(gameId,gameType,0,datainfo.normalScore,userinfo)
        userinfo.property.isInPresentChips=0
        -- if userinfo.property.totalRechargeChips>0 and userinfo.point.IsNormal==1 then
        --     gamecommon.IncSelfStockNumByType(gameId, stockgameType, -normal)
        -- end
        gameDetaillog.SaveDetailGameLog(
            datainfos._id,
            os.time(),
            GameId,
            gameType,
            betchip,
            bchip,
            chessuserinfodb.RUserChipsGet(datainfos._id)+datainfo.normalScore,
            0,
            { type = 'FanBei'},
            {}
        )
    else
        --[[
            库存恢复
        ]]
        -- if userinfo.property.totalRechargeChips>0 and userinfo.point.IsNormal==1 then
        --     gamecommon.IncSelfStockNumByType(gameId, stockgameType, datainfo.normalScore)
        -- end
        userinfo.property.isInPresentChips=0
        gameDetaillog.SaveDetailGameLog(
            datainfos._id,
            os.time(),
            GameId,
            gameType,
            datainfo.normalScore,
            bchip,
            chessuserinfodb.RUserChipsGet(datainfos._id),
            0,
            { type = 'FanBei'},
            {}
        )
        local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
        if withdrawCashInfo.statement > chessuserinfodb.GetAHeadTolScore(uid) then
            withdrawCashInfo.statement = chessuserinfodb.GetAHeadTolScore(uid)
            -- 保存数据库信息
            unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
        end
        datainfo.normalScore = 0
        datainfo.normalChip = 0
        datainfo.addMulNum = 0
        res.normalScore = 0
    end

    unilight.update(Table, datainfos._id, datainfos)
    gamecommon.SendNet(uid,'CorpseDoubleCmd_S',res)
end
--[[
    领取普通中奖
]]
function CmdCorpseRecvNormalScore(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    datainfos.gameType = gameType
    if datainfo.normalScore>0 then
        local res = {
            errno = 0,
            normalScore = datainfo.normalScore,
            gameType = gameType,
        }
     
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, datainfo.normalScore,Const.GOODS_SOURCE_TYPE.CORPSE)
        WithdrawCash.AddBet(uid,datainfo.normalScore-datainfo.normalChip,0)
        -- if datainfo.addMulNum>0 and datainfo.baseWin~=nil then
        --     local userinfo = unilight.getdata('userinfo', uid)
        --     print('datainfo.baseWin2',datainfo.normalScore,datainfo.baseWin)
        --     userinfo.gameData.slotsWin = userinfo.gameData.slotsWin + datainfo.normalScore
        --     unilight.update('userinfo', uid, userinfo)
        -- end
        datainfo.normalScore = 0
        datainfo.normalChip = 0
        datainfo.addMulNum = 0
        unilight.update(Table, datainfos._id, datainfos)
        gamecommon.SendNet(uid,'CorpseRecvNormalScoreGame_S',res)
     
        -- print('sendNetCorpseRecvNormalScoreGame_S1')
    else
        gamecommon.SendNet(uid,'CorpseRecvNormalScoreGame_S',{errno=ErrorDefine.ERROR_RECVNORMAL})
        -- print('sendNetCorpseRecvNormalScoreGame_S2')
    end
end
function Drop(gameType,uid)
    local datainfo,datainfos = Get(gameType,uid)
    if datainfo.normalScore>0 and table.empty(datainfo.bonus) then
        BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD, datainfo.normalScore,Const.GOODS_SOURCE_TYPE.CORPSE)
        datainfo.normalScore = 0
        datainfo.normalChip = 0
        datainfo.addMulNum = 0
        unilight.update(Table, datainfos._id, datainfos)
    end
end
--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, corpse)
    gamecommon.GetModuleCfg(GameId,corpse)
    gamecommon.JackNameInit(GameId,corpse)
end