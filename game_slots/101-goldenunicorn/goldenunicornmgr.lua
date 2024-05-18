module('goldenunicorn',package.seeall)
--进入游戏场景消息
function CmdEnterGame(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    local betconfig = gamecommon.GetBetConfig(gameType,LineNum)
    local boards = nil
    if table.empty(datainfo.bonus)==false then
        boards  ={}
        table.insert(boards,datainfo.bonus.chessdata)
    end
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        boards = boards,
        gameType = datainfos.gameType,
        bAllLine=LineNum,
        features={
            free = PackFree(datainfo),
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
    if table.empty(datainfo.bonus)==false then
        res = Bonus(gameType,datainfo,datainfos)
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,false)
    elseif table.empty(datainfo.free)==false then
        res = Free(gameId,gameType,datainfo,datainfos)
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,false)
    else
        res = Normal(gameId,gameType,msg.betIndex,datainfo,datainfos)
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,true)
    end
    res.gameType = datainfos.gameType
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, goldenunicorn)
    -- local poolConfigs = {
    --     chipsConfigs     = table_101_jackpot_chips,   --标准金额
    --     addPerConfigs    = table_101_jackpot_add_per, --奖池增加
    --     bombConfigs      = table_101_jackpot_bomb,    --奖池暴池概率
    --     scaleConfigs     = table_101_jackpot_scale,   --奖池爆池比例
    --     betConfigs       = table_101_jackpot_bet,     --奖池触发下注
    -- }
    -- gamecommon.GamePoolInit(GameId,poolConfigs)
    gamecommon.GamePoolInit(GameId)
    gamecommon.GetModuleCfg(GameId,goldenunicorn)
    gamecontrol.RegisterSgameFunc(GameId,'bonus',AheadBonus)
    --初始化配置

    --获得奖励
    -- local bSucess, iconNum, jackpotChips = gamecommon.GetGamePoolChips(gameId, gameType, betIndex)
    --获得奖池奖励
    -- if bSucess then
    --
    -- end
end
