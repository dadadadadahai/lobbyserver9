module('animal',package.seeall)

GameId=145
Table='game145animal'
LineNum = 20
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
        bAllLine=1,
        gameType = gameType,
        features={
            free=packFree(datainfo)
        }
    }
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end
function CmdGameOprate(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local betindex = msg.betIndex
    local datainfo = Get(uid)
    local res={}
    if table.empty(datainfo.free) then
        res= Normal(gameType,betindex,datainfo)
    else
        res = Free(datainfo)
    end
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end

--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, animal)
    gamecommon.GetModuleCfg(GameId,animal)
    gameImagePool.loadPool(GameId)
end