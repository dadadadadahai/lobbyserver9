-- 卡车游戏模块
module('FruitParadise', package.seeall)

-- 获取卡车模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local fruitparadiseInfo = Get(gameType, uid)
    local res = GetResInfo(uid, fruitparadiseInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local res={}
    -- 获取数据库信息
    local fruitparadiseInfo = Get(msg.gameType, uid)
    if fruitparadiseInfo.free.totalTimes ~= -1 then
        --进入免费游戏逻辑
        local res = PlayFreeGame(fruitparadiseInfo,uid,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    else
        --进入普通游戏逻辑
        local res = PlayNormalGame(fruitparadiseInfo,uid,msg.betIndex,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    end
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, FruitParadise)
    -- local poolConfigs = {
    --     chipsConfigs     = table_108_jackpot_chips,   --标准金额
    --     addPerConfigs    = table_108_jackpot_add_per, --奖池增加
    --     bombConfigs      = table_108_jackpot_bomb,    --奖池暴池概率
    --     scaleConfigs     = table_108_jackpot_scale,   --奖池爆池比例
    --     betConfigs       = table_108_jackpot_bet,     --奖池触发下注
    -- }
    -- gamecommon.GamePoolInit(GameId,poolConfigs)
    gamecommon.GamePoolInit(GameId)
    gamecommon.GetModuleCfg(GameId,FruitParadise)
end
