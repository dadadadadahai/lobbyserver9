-- 卡车游戏模块
module('CrazyTruck', package.seeall)

-- 获取卡车模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    -- 玩家等级
    -- local level = userInfo.property.level or 1
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local crazytruckInfo = Get(gameType, uid)
    local res = GetResInfo(uid, crazytruckInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local res={}
    -- 获取数据库信息
    local crazytruckInfo = Get(msg.gameType, uid)
    if crazytruckInfo.free.totalTimes ~= -1 then
        --进入免费游戏逻辑
        local res = PlayFreeGame(crazytruckInfo,uid,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    else
        --进入普通游戏逻辑
        local res = PlayNormalGame(crazytruckInfo,uid,msg.betIndex,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    end
end

-- 切换下注金额
function CmdChangeBet(uid,msg)
    local betindex = msg.betIndex
    local gameType = msg.gameType
    -- 获取数据库信息
    local crazytruckInfo = Get(gameType, uid)
    
    local res={
        errno = 0,
        betIndex = betindex,
        collect = crazytruckInfo.collect[betindex],
    }
    gamecommon.SendNet(uid, 'ChangeBetCmd_S', res)
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, CrazyTruck)
    gamecommon.RegChangeBet(GameId, CmdChangeBet)
    -- local poolConfigs = {
    --     chipsConfigs     = table_102_jackpot_chips,   --标准金额
    --     addPerConfigs    = table_102_jackpot_add_per, --奖池增加
    --     bombConfigs      = table_102_jackpot_bomb,    --奖池暴池概率
    --     scaleConfigs     = table_102_jackpot_scale,   --奖池爆池比例
    --     betConfigs       = table_102_jackpot_bet,     --奖池触发下注
    -- }
    -- gamecommon.GamePoolInit(GameId,poolConfigs)
    gamecommon.GamePoolInit(GameId)
    gamecommon.GetModuleCfg(GameId,CrazyTruck)
end
