module('mariachi',package.seeall)
--进入游戏场景消息
function CmdEnterGame(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    local betconfig = gamecommon.GetBetConfig(gameType,LineNum)
    local boards=nil
    if table.empty(datainfo.pick)==false then
        boards={}
        table.insert(boards,datainfo.pick.chessdata)
    end
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        gameType = datainfos.gameType,
        boards = boards,
        features={
            free = PackFree(datainfo),
            bonus = PackPick(datainfo),
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
    if table.empty(datainfo.pick)==false then
        res = Pick(gameType,datainfo,datainfos)
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,false)
    elseif table.empty(datainfo.free)==false then
        res = Free(gameId, gameType,datainfo,datainfos)
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,false)
    else
        res = Normal(gameId, gameType,msg.betIndex,datainfo,datainfos)
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,true)
    end
    res.gameType = gameType
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, mariachi)
    -- local poolConfigs = {
    --     chipsConfigs     = table_106_jackpot_chips,   --标准金额
    --     addPerConfigs    = table_106_jackpot_add_per, --奖池增加
    --     bombConfigs      = table_106_jackpot_bomb,    --奖池暴池概率
    --     scaleConfigs     = table_106_jackpot_scale,   --奖池爆池比例
    --     betConfigs       = table_106_jackpot_bet,     --奖池触发下注
    -- }
    -- gamecommon.GamePoolInit(GameId,poolConfigs)
    gamecommon.GamePoolInit(GameId)
    gamecommon.GetModuleCfg(GameId,mariachi)
    gamecontrol.RegisterSgameFunc(GameId,'pick',AheadBonus)
end