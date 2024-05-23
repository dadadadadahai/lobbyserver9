-- 生肖龙游戏模块
module('Dragon', package.seeall)

-- 获取生肖龙模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local dragonInfo = Get(gameType, uid)
    local res = GetResInfo(uid, dragonInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local res={}
    -- 获取数据库信息
    local dragonInfo = Get(msg.gameType, uid)
    --金龙有免费
    if not table.empty(dragonInfo.free) then 
        --进入免费游戏逻辑
        dump(dragonInfo.free,"生肖龙游戏模块free",10)
         res = PlayFreeGame(dragonInfo,uid,msg.gameType)
         WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false,GameId)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    else
        --进入普通游戏逻辑
         res = PlayNormalGame(dragonInfo,uid,msg.betIndex,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    end

end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, Dragon)
    gamecommon.GetModuleCfg(GameId,Dragon)
    gameImagePool.loadPool(GameId)
end