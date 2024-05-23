module('cleopatraNew',package.seeall)
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
        features={
            free = packFree(datainfo),      --是否存在免费  存在的话 就是刚才的数据
        },
        extraData={
            isInHight = datainfo.isInHight,         --无用
            freePrice = table_121_buyfree[1].price, --购买免费的钱
            betChange = table_121_buygailv[1].betChange, --无用
        }
    }
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end
function CmdGameOprate(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    datainfos.gameType = gameType
    local res={}
    if table.empty(datainfo.free)==false then
    
        res = Free(gameId,gameType,datainfo,datainfos)
        -- WithdrawCash.GetBetInfo(uid,Table,gameType,res,false)
    else
        res = Normal(gameId,gameType,msg.betIndex,datainfo,datainfos,uid)
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,true)
    end
    res.gameType = gameType
    dump(res,"cleopatraNewCmdGameOprate",10)
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)

end
function CmdBuyFree(uid,msg)

    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    datainfos.gameType = gameType
    local res = BuyFree(gameType,msg.betIndex,datainfo,datainfos)
    res.gameType = gameType
    dump(res,"cleopatraNewCmdBuyFree",10)
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
function CmdBuyHighBet(uid,msg)

    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    datainfos.gameType = gameType
    local res = BuyHighBet(msg.highLevel,datainfo,datainfos)
    res.gameType = gameType

    gamecommon.SendNet(uid, 'HighBetCmd_S', res)
end
--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, cleopatraNew)
    -- local poolConfigs = {
    --     chipsConfigs     = table_110_jackpot_chips,   --标准金额
    --     addPerConfigs    = table_110_jackpot_add_per, --奖池增加
    --     bombConfigs      = table_110_jackpot_bomb,    --奖池暴池概率
    --     scaleConfigs     = table_110_jackpot_scale,   --奖池爆池比例
    --     betConfigs       = table_110_jackpot_bet,     --奖池触发下注
    -- }
    -- gamecommon.GamePoolInit(GameId,poolConfigs)
    -- gamecommon.GamePoolInit(GameId)
    gamecommon.GetModuleCfg(GameId,cleopatraNew)
    gameImagePool.loadPool(GameId)
end