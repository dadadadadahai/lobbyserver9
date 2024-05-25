-- 金牛游戏模块
module('GoldCow', package.seeall)

-- 获取金牛模块信息
function CmdEnterGame(uid, msg)

    SetGameMold(uid,msg.demo)

    local gameType = msg.gameType
    -- 获取数据库信息
    local goldcowInfo = Get(gameType, uid)
    local res = GetResInfo(uid, goldcowInfo, gameType)
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
    local goldcowInfo = Get(msg.gameType, uid)
    --进入普通游戏逻辑
    if   IsDemo(uid) then
        res = PlayNormalGameDemo(goldcowInfo,uid,msg.betIndex,msg.gameType)
        AddDemoNums(uid)
    else 
        res = PlayNormalGame(goldcowInfo,uid,msg.betIndex,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
    end 
  

    gamecommon.SendNet(uid,'GameOprateGame_S',res)
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, GoldCow)
    gamecommon.GetModuleCfg(GameId,GoldCow)
    gameImagePool.loadPool(GameId)
end