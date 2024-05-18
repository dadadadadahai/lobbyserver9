module('luckstar',package.seeall)

GameId=142

--进入游戏场景消息
function CmdEnterGame(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo = Get(uid)
    local betconfig = gamecommon.GetBetConfig(gameType,LineNum)
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        gameType = gameType
    }
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

function CmdGameOprate(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local betindex = msg.betIndex
    local datainfo = Get(uid)
    local res=Normal(gameType,betindex,datainfo)
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end

--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, luckstar)
    gamecommon.GetModuleCfg(GameId,luckstar)
    gameImagePool.loadPool(GameId)
end