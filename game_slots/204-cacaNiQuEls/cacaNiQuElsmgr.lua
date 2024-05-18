module('cacaNiQuEls',package.seeall)
function CmdEnterGame(uid,msg)
    gamecommon.SendNet(uid, 'EnterSceneGame_S', {errno=ErrorDefine.SUCCESS})
end
function CmdGameOprate(uid,msg)
    local res = Normal(msg.gameType,msg.extraData.bets,uid)
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
--注册消息解析
function RegisterProto()

    --52
    gamecommon.RegGame(GameId, cacaNiQuEls)
    -- local poolConfigs = {
    --     chipsConfigs     = table_204_jackpot_chips,   --标准金额
    --     addPerConfigs    = table_204_jackpot_add_per, --奖池增加
    --     bombConfigs      = table_204_jackpot_bomb,    --奖池暴池概率
    --     scaleConfigs     = table_204_jackpot_scale,   --奖池爆池比例
    --     betConfigs       = table_204_jackpot_bet,     --奖池触发下注
    -- }
    -- gamecommon.GamePoolInit(GameId,poolConfigs)
    gamecommon.GamePoolInit(GameId)
    --注册库存衰减
    for gameType, value in ipairs(table_204_sessions) do
        stockMap[gameType] = stockMap[gameType] or {
            Stock=table_204_sessions[gameType].initStock,
            tax= 0,--累计抽水
            decval=0,       --累积衰减值
        }
        
        gamecommon.RegisterStockDec(GameId,gameType,stockMap[gameType],table_204_other[gameType])
    end
    --gamecommon.RegChangeBet(GameId, CmdChangeBet)
    --gamecommon.GamePoolInit(GameId,LineNum,table_Luxury_jackpot[1])
end