-- 金牛游戏模块
module('Leopard', package.seeall)

-- 获取金牛模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local leopardInfo = Get(gameType, uid)
    local res = GetResInfo(uid, leopardInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local res={}
    -- 获取数据库信息
    local leopardInfo = Get(msg.gameType, uid)
    --进入普通游戏逻辑
    local res = PlayNormalGame(leopardInfo,uid,msg.betIndex,msg.gameType,msg.isAdditional)
    WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
    gamecommon.SendNet(uid,'GameOprateGame_S',res)
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, Leopard)
    gamecommon.GetModuleCfg(GameId,Leopard)
end