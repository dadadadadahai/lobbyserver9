-- 老虎游戏模块
module('Tiger', package.seeall)

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
    local res={}
    -- 获取数据库信息
    local tigerInfo = Get(msg.gameType, uid)
    if   IsDemo(uid) then
       res = PlayNormalGameDemo(tigerInfo,uid,msg.betIndex,msg.gameType)
       AddDemoNums(uid)
    else
       res = PlayNormalGame(tigerInfo,uid,msg.betIndex,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
    end 
    gamecommon.SendNet(uid,'GameOprateGame_S',res)
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, Tiger)
    gamecommon.GetModuleCfg(GameId,Tiger)
    gameImagePool.loadPool(GameId)
end