module('moneytree',package.seeall)

GameId=138
Table = 'game138moneytree'
LineNum = 1
--进入游戏场景消息
function CmdEnterGame(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo = Get(uid)
    local betconfig = gamecommon.GetBetConfig(gameType,LineNum)
    local respin={}
    if table.empty(datainfo.respin)==false then
        respin={
            totalTimes=3,
            lackTimes=datainfo.respin.lastRes.lackTimes,
            tWinScore=0,
            res=datainfo.respin.lastRes,
        }
    end
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        gameType = gameType,
        features={
            respin=respin
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
    if table.empty(datainfo.respin) then
        res = Normal(gameType,betindex,datainfo)
    else
        res = Respin(gameType,betindex,datainfo)
    end
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, moneytree)
    gamecommon.GetModuleCfg(GameId,moneytree)
    gameImagePool.loadPool(GameId)
end

--消息处理
function CmdBuyFree(uid,msg)
    local datainfo = Get(uid)
    local res = BuyFree(msg.betIndex,datainfo)
    gamecommon.SendNet(uid, 'MoneyTreeBuyFreeCmd_S', res)
end