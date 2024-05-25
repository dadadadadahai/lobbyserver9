-- 老鼠游戏模块
module('Mouse', package.seeall)

-- 获取老鼠模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    SetGameMold(uid,msg.demo)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local mouseInfo = Get(gameType, uid)
    local res = GetResInfo(uid, mouseInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
    if IsDemo(uid) then
        chessuserinfodb.DemoInitPoint(uid)
    end
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    -- 获取数据库信息
    local mouseInfo = Get(msg.gameType, uid)
    if   IsDemo(uid) then
        --进入普通游戏逻辑
        local res = PlayNormalGameDemo(mouseInfo,uid,msg.betIndex,msg.gameType)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
        AddDemoNums(uid)
    else 
        --进入普通游戏逻辑
        local res = PlayNormalGame(mouseInfo,uid,msg.betIndex,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    end 
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, Mouse)
    gamecommon.GetModuleCfg(GameId,Mouse)
    gameImagePool.loadPool(GameId)
end