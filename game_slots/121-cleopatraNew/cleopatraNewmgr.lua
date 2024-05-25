module('cleopatraNew',package.seeall)
--进入游戏场景消息
function CmdEnterGame(uid,msg)
    local gameType = msg.gameType
    local datainfo = Get(gameType,uid)
    local res={
        errno = 0,
        betConfig = gamecommon.GetBetConfig(gameType,LineNum), 
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        gameType = gameType,
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
    for i = 1, 50000, 1 do
        local datainfo = Get(msg.gameType,uid)
        local res={}
        if table.empty(datainfo.free)==false then
            res = Free(msg.gameType,datainfo,uid)
        else
            res = Normal(msg.gameType,msg.betIndex,datainfo,uid)
           -- WithdrawCash.GetBetInfo(uid,Table,msg.gameType,res,true,GameId)
        end
    end
    local datainfo = Get(msg.gameType,uid)
    local res={}
    if table.empty(datainfo.free)==false then
        res = Free(msg.gameType,datainfo,uid)
    else
        res = Normal(msg.gameType,msg.betIndex,datainfo,uid)
       -- WithdrawCash.GetBetInfo(uid,Table,msg.gameType,res,true,GameId)
    end
  --  res.gameType = msg.gameType
  --  dump(res,"cleopatraNewCmdGameOprate",10)
   -- gamecommon.SendNet(uid, 'GameOprateGame_S', res)

end
function CmdBuyFree(uid,msg)
    local datainfo = Get(msg.gameType,uid)
    local res = BuyFree(msg.gameType,msg.betIndex,datainfo,uid)
    WithdrawCash.GetBetInfo(uid,Table,msg.gameType,res,true,GameId)
    res.gameType = msg.gameType
    dump(res,"cleopatraNewCmdBuyFree",10)
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
function CmdBuyHighBet(uid,msg)
    local datainfo = Get(msg.gameType,uid)
    local res = BuyHighBet(msg.highLevel,datainfo,msg.gameType,uid)
    res.gameType = msg.gameType
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