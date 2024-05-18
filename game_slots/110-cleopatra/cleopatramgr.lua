module('cleopatra',package.seeall)
--进入游戏场景消息
function CmdEnterGame(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    local betconfig = gamecommon.GetBetConfig(gameType,LineNum)
    local res={
        errno = 0,
        betConfig = betconfig,
        gameType = datainfos.gameType,
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
    }
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end
function CmdGameOprate(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    datainfos.gameType = gameType
    local res={}
    res = Normal(gameId,gameType,msg.betIndex,datainfo,datainfos,uid)
    res.gameType = gameType
    WithdrawCash.GetBetInfo(uid,Table,gameType,res,true)
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, cleopatra)
    -- local poolConfigs = {
    --     chipsConfigs     = table_110_jackpot_chips,   --标准金额
    --     addPerConfigs    = table_110_jackpot_add_per, --奖池增加
    --     bombConfigs      = table_110_jackpot_bomb,    --奖池暴池概率
    --     scaleConfigs     = table_110_jackpot_scale,   --奖池爆池比例
    --     betConfigs       = table_110_jackpot_bet,     --奖池触发下注
    -- }
    -- gamecommon.GamePoolInit(GameId,poolConfigs)
    gamecommon.GamePoolInit(GameId)
    gamecommon.GetModuleCfg(GameId,cleopatra)
end