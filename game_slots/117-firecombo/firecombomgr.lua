-- 火焰连击游戏模块
module('FireCombo', package.seeall)

-- 获取火焰连击模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local firecomboInfo = Get(gameType, uid)
    local res = GetResInfo(uid, firecomboInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local res={}
    -- 获取数据库信息
    local firecomboInfo = Get(msg.gameType, uid)
    if firecomboInfo.free.totalTimes ~= -1 then
        --进入免费游戏逻辑
        local res = PlayFreeGame(firecomboInfo,uid,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false,GameId)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    else
        --进入普通游戏逻辑
        local res = PlayNormalGame(firecomboInfo,uid,msg.betIndex,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    end
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, FireCombo)

    -- 假奖池爆池给机器人配置
    -- local jackpotRobotTable = {
    --     JackpotGrade = import "table/game/117/table_117_jackpotgrade",            -- 爆池档次
    --     JackpotPool = import "table/game/117/table_117_jackpotpool",              -- 爆池奖池
    --     JackpotPro = import "table/game/117/table_117_jackpotpro",                -- 爆池概率
    -- }
    -- gamecommon.GamePoolInit2(GameId,Table_Base[1].linenum,Table_Jackpot[1],jackpotRobotTable)
    gamecommon.GamePoolInit(GameId)
    gamecommon.GetModuleCfg(GameId,FireCombo)
end
