-- 幸运转盘游戏模块
module('LuckyWheel', package.seeall)

-- 获取幸运转盘模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local luckywheelInfo = Get(gameType, uid)
    local res = GetResInfo(uid, luckywheelInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local res={}
    -- 获取数据库信息
    local luckywheelInfo = Get(msg.gameType, uid)
    if table.empty(luckywheelInfo.free) == false then
        --进入免费游戏逻辑
        local res = PlayFreeGame(luckywheelInfo,uid,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    else
        --进入普通游戏逻辑
        local res = PlayNormalGame(luckywheelInfo,uid,msg.betIndex,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    end
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, LuckyWheel)
    gamecommon.GetModuleCfg(GameId,LuckyWheel)
    gamecontrol.RegisterSgameFunc(GameId,'free',AheadFree)
end
