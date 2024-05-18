-- 足球游戏模块
module('Football', package.seeall)

-- 获取足球模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo", uid)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local footballInfo = Get(gameType, uid)
    -- footballInfo.betIndex = msg.betIndex
    local res = GetResInfo(uid, footballInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid, 'EnterSceneGame_S', res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local res = {}
    -- 获取数据库信息
    local footballInfo = Get(msg.gameType, uid)
    --进入普通游戏逻辑
    res = PlayNormalGame(footballInfo, uid, msg.betIndex, msg.gameType)
    WithdrawCash.GetBetInfo(uid, DB_Name, msg.gameType, res, true)
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
-- 切换下注金额
function CmdChangeBet(uid, msg)
    local betindex = msg.betIndex
    local gameType = msg.gameType
    -- 获取数据库信息
    local footballInfo = Get(gameType, uid)

    local res = {
        errno = 0,
        betIndex = betindex,
        iconsAttachData = { footballInfo.iconsAttachData[betindex] },
        boards = { footballInfo.boards[betindex] },
    }
    gamecommon.SendNet(uid, 'ChangeBetCmd_S', res)
end

-- 注册消息解析
function RegisterProto()
    -- print("GameId = "..GameId)
    gamecommon.RegGame(GameId, Football)
    gamecommon.RegChangeBet(GameId, CmdChangeBet)
    -- local poolConfigs = {
    --     chipsConfigs     = table_107_jackpot_chips,   --标准金额
    --     addPerConfigs    = table_107_jackpot_add_per, --奖池增加
    --     bombConfigs      = table_107_jackpot_bomb,    --奖池暴池概率
    --     scaleConfigs     = table_107_jackpot_scale,   --奖池爆池比例
    --     betConfigs       = table_107_jackpot_bet,     --奖池触发下注
    -- }
    -- gamecommon.GamePoolInit(GameId,poolConfigs)
    gamecommon.GamePoolInit(GameId)
    gamecommon.GetModuleCfg(GameId,Football)
end
