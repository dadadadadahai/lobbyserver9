module('beautydisco',package.seeall)
function CmdEnterGame(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    local betconfig = gamecommon.GetBetConfig(gameType,LineNum)
    datainfo.betMoney = betconfig[datainfo.betindex]
    local chip = datainfo.betMoney *LineNum
    local pools={}
    pools[1] = table_105_sgame[8].pmul * chip
    pools[2] = table_105_sgame[9].pmul * chip
    pools[3] = table_105_sgame[10].pmul * chip
    pools[4] = table_105_sgame[11].pmul * chip
    local bonus = PackBonus(datainfo)
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        gameType = datainfos.gameType,
        extraData={
            pools=pools,
        },
        features={
            bonus = bonus
        },
    }
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end
function CmdGameOprate(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    datainfos.gameType=gameType
    local res={}
    if table.empty(datainfo.bonus)==false then
        res = Bonus(gameType,datainfo,datainfos)
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,false)
    else
        res = Normal(uid,gameType,msg.betIndex,datainfo,datainfos)
        WithdrawCash.GetBetInfo(uid,Table,gameType,res,true)
    end
    res.gameType = datainfos.gameType
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, beautydisco)
        -- 假奖池爆池给机器人配置
    local jackpotRobotTable = {
        JackpotGrade = import "table/game/105/table_105_jackpotgrade",            -- 爆池档次
        JackpotPool = import  "table/game/105/table_105_jackpotpool",              -- 爆池奖池
        JackpotPro = import   "table/game/105/table_105_jackpotpro",                -- 爆池概率
    }
    gamecommon.GamePoolInit2(GameId,Table_Base[1].linenum,Table_Jackpot[1],jackpotRobotTable)
    --gamecommon.GamePoolInit(GameId,LineNum,table_holloween_jackpot[1])

    -- local table_105_jackpot_chips = import 'table/game/105/table_105_jackpot_chips'
    -- local table_105_jackpot_add_per = import 'table/game/105/table_105_jackpot_add_per'
    -- local table_105_jackpot_bomb = import 'table/game/105/table_105_jackpot_bomb'
    -- local table_105_jackpot_scale = import 'table/game/105/table_105_jackpot_scale'
    -- local table_105_jackpot_bet = import 'table/game/105/table_105_jackpot_bet'

    -- --为了gm后台修改配置
    -- local poolConfigs = {
    --     chipsConfigs     = table_105_jackpot_chips,   --标准金额
    --     addPerConfigs    = table_105_jackpot_add_per, --奖池增加
    --     bombConfigs      = table_105_jackpot_bomb,    --奖池暴池概率
    --     scaleConfigs     = table_105_jackpot_scale,   --奖池爆池比例
    --     betConfigs       = table_105_jackpot_bet,     --奖池触发下注
    -- }
    -- gamecommon.GamePoolInit(GameId,poolConfigs)
    gamecommon.GamePoolInit(GameId)
    gamecommon.GetModuleCfg(GameId,beautydisco)
    gamecontrol.RegisterSgameFunc(GameId,'bonus',AheadBonus)
end
