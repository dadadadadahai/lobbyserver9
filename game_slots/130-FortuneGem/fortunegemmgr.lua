-- 财富宝石游戏模块
module('FortuneGem', package.seeall)

-- 获取财富宝石模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local fortunegemInfo = Get(gameType, uid)
    local res = GetResInfo(uid, fortunegemInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local res={}
    -- 获取数据库信息
    local fortunegemInfo = Get(msg.gameType, uid)
    msg.isAdditional = msg.isAdditional or false
    --进入普通游戏逻辑
    local res = PlayNormalGame(fortunegemInfo,uid,msg.betIndex,msg.gameType,msg.isAdditional)
    WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
    gamecommon.SendNet(uid,'GameOprateGame_S',res)
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, FortuneGem)
    gamecommon.GetModuleCfg(GameId,FortuneGem)
end