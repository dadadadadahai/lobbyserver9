-- 老虎游戏模块
module('GreatRhinoceros', package.seeall)

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
        -- 获取数据库信息
    if   IsDemo(uid) then
        local diamonInfo = Get(msg.gameType, uid)
            --金龙有免费
            if not table.empty(diamonInfo.free) then 
            --进入免费游戏逻辑
            local res = PlayFreeGameDemo(diamonInfo,uid,msg.gameType)
            gamecommon.SendNet(uid,'GameOprateGame_S',res)
            dump(res,"GR",5)
        else
            --进入普通游戏逻辑
            local  res = PlayNormalGameDemo(diamonInfo,uid,msg.betIndex,msg.gameType)
            gamecommon.SendNet(uid,'GameOprateGame_S',res)
            AddDemoNums(uid)
            dump(res,"GR",5)
        end
    else
        local diamonInfo = Get(msg.gameType, uid)
        if not table.empty(diamonInfo.free) then 
            --进入免费游戏逻辑
            local res = PlayFreeGame(diamonInfo,uid,msg.gameType)
            -- WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false,GameId)
            gamecommon.SendNet(uid,'GameOprateGame_S',res)
            dump(res,"GR",5)
        else
            --进入普通游戏逻辑
            local    res = PlayNormalGame(diamonInfo,uid,msg.betIndex,msg.gameType)
            WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
            gamecommon.SendNet(uid,'GameOprateGame_S',res)
            dump(res,"GR",5)
        end
    end 
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, GreatRhinoceros)
    gamecommon.GetModuleCfg(GameId,GreatRhinoceros)
    gameImagePool.loadPool(GameId)
end