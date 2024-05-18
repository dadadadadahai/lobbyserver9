module('cashwheel',package.seeall)

GameId=151
Table='game151cashwheel'
LineNum = 1
Betconfig = {
    [1] = 100,
    [2] = 500,
    [3] = 1000,
    [4] = 5000,
    [5] = 10000
}
--进入游戏场景消息
function CmdEnterGame(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo = Get(uid)
    local betconfig = Betconfig
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
    local res=Normal(gameType,betindex,datainfo)
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end

--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, cashwheel)
    gamecommon.GetModuleCfg(GameId,cashwheel)
    gameImagePool.loadPool(GameId)
end