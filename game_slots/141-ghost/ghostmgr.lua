module('ghost', package.seeall)

GameId=141

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
        features={
            free=GetFreeInfo(datainfo)
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
    gamecommon.RegGame(GameId, ghost)
    gamecommon.GetModuleCfg(GameId,ghost)
    gameImagePool.loadPool(GameId)
end