-- 老虎游戏模块
module('MasterJoker', package.seeall)

-- 获取老虎模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    SetGameMold(uid,msg.demo)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local tigerInfo = Get(gameType, uid)
    local res = GetResInfo(uid, tigerInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
    if IsDemo(uid) then
      chessuserinfodb.DemoInitPoint(uid)
    end 
end

--拉动游戏过程
function CmdGameOprate(uid, msg)

    if   IsDemo(uid) then
        local res={}
        -- 获取数据库信息
        local tigerInfo = Get(msg.gameType, uid)
       res = PlayNormalGameDemo(tigerInfo,uid,msg.betIndex,msg.gameType)
       gamecommon.SendNet(uid,'GameOprateGame_S',res)
       AddDemoNums(uid)
    else
        local res={}
        -- 获取数据库信息
        local tigerInfo = Get(msg.gameType, uid)
        res = PlayNormalGame(tigerInfo,uid,msg.betIndex,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    end 

end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, MasterJoker)
    gamecommon.GetModuleCfg(GameId,MasterJoker)
    gameImagePool.loadPool(GameId)
end