-- 生肖龙游戏模块
module('Dragon', package.seeall)

-- 获取生肖龙模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
     SetGameMold(uid,msg.demo)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local dragonInfo = Get(gameType, uid)
    local res = GetResInfo(uid, dragonInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
    if IsDemo(uid) then
        chessuserinfodb.DemoInitPoint(uid)
    end
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    -- 获取数据库信息

    if   IsDemo(uid) then
        local dragonInfo = Get(msg.gameType, uid)
         --金龙有免费
         if not table.empty(dragonInfo.free) then 
            --进入免费游戏逻辑
            local res = PlayFreeGameDemo(dragonInfo,uid,msg.gameType)
            gamecommon.SendNet(uid,'GameOprateGame_S',res)
        else
            --进入普通游戏逻辑
            local  res = PlayNormalGameDemo(dragonInfo,uid,msg.betIndex,msg.gameType)
            gamecommon.SendNet(uid,'GameOprateGame_S',res)
            AddDemoNums(uid)
        end
    else
        local dragonInfo = Get(msg.gameType, uid)
        if not table.empty(dragonInfo.free) then 
            --进入免费游戏逻辑
            local res = PlayFreeGame(dragonInfo,uid,msg.gameType)
<<<<<<< HEAD
           -- WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false,GameId)
=======
            WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false,GameId)
>>>>>>> cad78e1 (2)
            gamecommon.SendNet(uid,'GameOprateGame_S',res)
        else
            --进入普通游戏逻辑
            local    res = PlayNormalGame(dragonInfo,uid,msg.betIndex,msg.gameType)
            WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
            gamecommon.SendNet(uid,'GameOprateGame_S',res)
        end
    end 
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, Dragon)
    gamecommon.GetModuleCfg(GameId,Dragon)
    gameImagePool.loadPool(GameId)
end