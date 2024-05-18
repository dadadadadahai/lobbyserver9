module('dragon',package.seeall)
GameId=136

--进入游戏场景消息
function CmdEnterGame(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo = Get(uid)
    local betconfig = gamecommon.GetBetConfig(gameType,1)
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        bAllLine=1,
        gameType = gameType,
    }
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end
function CmdGameOprate(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local betindex = msg.betIndex
    local datainfo = Get(uid)
    local res = Normal(gameType,betindex,datainfo)
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, dragon)
    gamecommon.GetModuleCfg(GameId,dragon)
    gameImagePool.loadPool(GameId)
end