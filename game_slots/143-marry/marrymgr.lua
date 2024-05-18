module('marry',package.seeall)
GameId=143
LineNum = 30
Table='game143marry'
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
        gameType = gameType,
        features={
            free=PackFree(datainfo)
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
        res=Normal(gameType,betindex,datainfo)
    else
        res=Free(gameType,betindex,datainfo)
    end
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end

--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, marry)
    gamecommon.GetModuleCfg(GameId,marry)
    gameImagePool.loadPool(GameId)
end