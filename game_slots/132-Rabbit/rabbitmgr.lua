-- 兔子游戏模块
module('Rabbit', package.seeall)

-- 获取兔子模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    SetGameMold(uid,msg.demo)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local rabbitInfo = Get(gameType, uid)
    local res = GetResInfo(uid, rabbitInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
    if IsDemo(uid) then
        chessuserinfodb.DemoInitPoint(uid)
    end
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local rabbitInfo = Get(msg.gameType, uid)
    if   IsDemo(uid) then
        if not table.empty(rabbitInfo.free) then
            --进入免费游戏逻辑
            local res = PlayFreeGameDemo(rabbitInfo,uid,msg.gameType)
            gamecommon.SendNet(uid,'GameOprateGame_S',res)
        else
            --进入普通游戏逻辑
            local res = PlayNormalGameDemo(rabbitInfo,uid,msg.betIndex,msg.gameType)
            gamecommon.SendNet(uid,'GameOprateGame_S',res)
            AddDemoNums(uid)
        end
    else
        if not table.empty(rabbitInfo.free) then
            --进入免费游戏逻辑
            local res = PlayFreeGame(rabbitInfo,uid,msg.gameType)
           -- WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false,GameId)
            gamecommon.SendNet(uid,'GameOprateGame_S',res)
        else
            --进入普通游戏逻辑
            local res = PlayNormalGame(rabbitInfo,uid,msg.betIndex,msg.gameType)
            WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
            gamecommon.SendNet(uid,'GameOprateGame_S',res)
        end
    end 
    --  for i = 1, 100000 do
    --      local res={}
    --      -- 获取数据库信息
    --      local rabbitInfo = Get(msg.gameType, uid)
    --      msg.betIndex = math.random(12)
    --      if not table.empty(rabbitInfo.free) then
    --          --进入免费游戏逻辑
    --          local res = PlayFreeGame(rabbitInfo,uid,msg.gameType)
    --          -- WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false,GameId)
    --          -- gamecommon.SendNet(uid,'GameOprateGame_S',res)
    --      else
    --          --进入普通游戏逻辑
    --          local res = PlayNormalGame(rabbitInfo,uid,msg.betIndex,msg.gameType,msg.isAdditional)
    --          -- WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
    --          -- gamecommon.SendNet(uid,'GameOprateGame_S',res)
    --      end
    --  end
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, Rabbit)
    gamecommon.GetModuleCfg(GameId,Rabbit)
    gameImagePool.loadPool(GameId)
end