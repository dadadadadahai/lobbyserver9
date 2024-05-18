module('happypumpkin',package.seeall)
--进入游戏场景消息
function CmdEnterGame(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    local betconfig = gamecommon.GetBetConfig(gameType,LineNum)
    local collectBet = datainfo.collectBet[datainfo.betindex]
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        gameType = datainfos.gameType,
        features={
            free = datainfo.free,
        },
        collect = {
            curPro = collectBet.cnum,
            talPro = collectBet.nnum,
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
    if table.empty(datainfo.free)==false then
        res = Free(gameId,gameType,datainfo,datainfos)
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,false)
    else
        res = Normal(gameId,gameType,msg.betIndex,datainfo,datainfos)
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,true)
    end
    res.gameType = datainfos.gameType
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
function CmdChangeBet(uid,msg)
    local betindex = msg.betIndex
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    datainfo.collectBet[betindex] =datainfo.collectBet[betindex] or {cnum =table_103_other[1].cs,nnum=table_103_other[1].cf}
    local collectBet = datainfo.collectBet[betindex]
    local res={
        curPro = collectBet.cnum,
        talPro = collectBet.nnum,
    }
    gamecommon.SendNet(uid, 'ChangeBetCmd_S', res)
end
--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, happypumpkin)
    --注册变化下注消息
    gamecommon.RegChangeBet(GameId,CmdChangeBet)
    -- local poolConfigs = {
    --     chipsConfigs     = table_103_jackpot_chips,   --标准金额
    --     addPerConfigs    = table_103_jackpot_add_per, --奖池增加
    --     bombConfigs      = table_103_jackpot_bomb,    --奖池暴池概率
    --     scaleConfigs     = table_103_jackpot_scale,   --奖池爆池比例
    --     betConfigs       = table_103_jackpot_bet,     --奖池触发下注
    -- }
    -- gamecommon.GamePoolInit(GameId,poolConfigs)
    gamecommon.GamePoolInit(GameId)
    gamecommon.GetModuleCfg(GameId,happypumpkin)

end