-- 金牛游戏模块
module('GoldCow', package.seeall)

-- 获取金牛模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    -- 获取游戏类型
    SetGameMold(uid,msg.demo)
    local gameType = msg.gameType
    -- 获取数据库信息
    local goldcowInfo = Get(gameType, uid)
    local res = GetResInfo(uid, goldcowInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local res={}
    -- 获取数据库信息
    local goldcowInfo = Get(msg.gameType, uid)
    --进入普通游戏逻辑
  -- for i = 1, 5000, 1 do
       -- msg.betIndex = math.random(12)
        local res = PlayNormalGame(goldcowInfo,uid,msg.betIndex,msg.gameType,msg.isAdditional)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
  -- end

    gamecommon.SendNet(uid,'GameOprateGame_S',res)
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, GoldCow)
    gamecommon.GetModuleCfg(GameId,GoldCow)
    gameImagePool.loadPool(GameId)
end