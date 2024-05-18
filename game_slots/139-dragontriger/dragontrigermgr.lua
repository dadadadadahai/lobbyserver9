module('dragontriger',package.seeall)
GameId=139

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
    local imageType = msg.extraData.imageType
    
    local datainfo = Get(uid)
    local res={}
    if imageType==1 then
        res = Normal(gameType,betindex,datainfo)
    elseif imageType==2 then
        res = NormalType1(gameType,betindex,datainfo)
    else 
        res = NormalType2(gameType,betindex,datainfo)
    end
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end


--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, dragontriger)
    gamecommon.GetModuleCfg(GameId,dragontriger)
    gameImagePool.loadPool(GameId)
end