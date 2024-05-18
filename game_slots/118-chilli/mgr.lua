module('chilli', package.seeall)

function CmdEnterGame(uid, msg)
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    local betconfig = gamecommon.GetBetConfig(gameType,LineNum)
    local boards = {}
    if table.empty(datainfo.respin)==false then
        table.insert(boards, datainfo.respin.chessdata)
    end
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        boards=boards,
        bAllLine=LineNum,
        gameType = datainfos.gameType,
        features={
            free = PackRespin(datainfo)
        },
    }
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    datainfos.gameType = gameType
    local res={}
    if table.empty(datainfo.respin)==false then
        res = Respin(gameType,datainfo,datainfos)
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,false)
    else
        res=Normal(gameId,gameType,msg.betIndex,datainfo,datainfos)
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,true)
    end
    res.gameType = gameType
    gamecommon.SendNet(uid,'GameOprateGame_S',res)
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, chilli)
    gamecommon.GamePoolInit(GameId)
    gamecommon.GetModuleCfg(GameId,chilli)
    gamecontrol.RegisterSgameFunc(GameId,'respin',AheadBonus)
end