-- 阿波罗游戏模块
module('Apollo', package.seeall)

-- 获取阿波罗模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local apolloInfo = Get(gameType, uid)
    local res = GetResInfo(uid, apolloInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local res={}
    -- 获取数据库信息
    local apolloInfo = Get(msg.gameType, uid)
    if not table.empty(apolloInfo.respin) then
        --进入免费游戏逻辑
        local res = PlayRespinGame(apolloInfo,uid,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    elseif not table.empty(apolloInfo.free) then
        --进入免费游戏逻辑
        local res = PlayFreeGame(apolloInfo,uid,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    else
        --进入普通游戏逻辑
        local res = PlayNormalGame(apolloInfo,uid,msg.betIndex,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    end
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, Apollo)
    gamecommon.GamePoolInit(GameId)
    gamecommon.GetModuleCfg(GameId,Apollo)
    gamecontrol.RegisterSgameFunc(GameId,'respin',AheadRespin)
end
