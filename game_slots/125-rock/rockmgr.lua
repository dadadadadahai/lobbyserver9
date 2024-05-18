module('rockgame',package.seeall)
--进入游戏场景消息
function CmdEnterGame(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    local betconfig = gamecommon.GetBetConfig(gameType,LineNum)
    local bonus = getPackBonusInfo(datainfo)
    local boards={}
    local epos = {}
    local rocks=datainfo.rocks
    if table.empty(bonus)==false then
        local latestChessdata = {}
        if table.empty(datainfo.bonusQueue)==false then
            epos = datainfo.bonusQueue[1].result.lastInfo.bepos
            -- rocks = datainfo.bonusres[1].result.rocks
            latestChessdata=datainfo.bonusQueue[1].latestChessdata
        end
        bonus.type = 0
        table.insert(boards,latestChessdata)
    end
    local curRocks = {}
    for i=1,#betconfig do
        curRocks[i] = datainfo.tRocks[i] or {}
    end
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        boards = boards,
        gameType = gameType,
        collect={
            rocks = rocks,
            tRocks = curRocks,
        },
        features={
            bonus = bonus
        },
        extraData = {
            epos = eposToArray(epos)
        }
    }
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end
function CmdGameOprate(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    datainfos.gameType = gameType
    local res={}
    local bonusInfo =  getPackBonusInfo(datainfo)
    if table.empty(bonusInfo)==false then
        res = Bonus(gameType,datainfo,datainfos)
        WithdrawCash.GetBetInfo(uid, Table, gameType, res, false)
    else
        res = Normal(gameId,gameType,msg.betIndex,datainfo,datainfos,uid)
        WithdrawCash.GetBetInfo(uid, Table, gameType, res, true)
    end
    res.gameType = gameType
    unilight.update(Table,datainfos._id,datainfos)
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, rockgame)
    gamecommon.GetModuleCfg(GameId,rockgame)
end