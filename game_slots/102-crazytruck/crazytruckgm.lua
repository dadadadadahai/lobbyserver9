-- 卡车游戏模块
module('CrazyTruck', package.seeall)

-- 卡车GM
function GmProcess(uid, gameId, gameType, boards,crazytruckInfo)

    local free =  chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    -- local jackpot = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.JACKPOT)
    -- local bonus = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.BONUS)

    local iconId = Table_Free[math.random(#Table_Free)].iconId
    if gmInfo.free == 1 or free == 1 then
        -- 触发免费
        boards[1][1] = iconId
        boards[3][3] = iconId
        boards[5][2] = iconId
    end
    -- if gmInfo.free == 1 then
    --     -- 触发免费
    --     crazytruckInfo.collect[crazytruckInfo.betIndex].curPro[1] = 4
    --     crazytruckInfo.collect[crazytruckInfo.betIndex].curPro[3] = 4
    --     crazytruckInfo.collect[crazytruckInfo.betIndex].curPro[5] = 4
    -- end
    -- if gmInfo.free == 1 then
    --     -- 测试中线的数据
    --     boards[1][1] = 11
    --     boards[2][1] = 11
    --     boards[3][1] = 11
    --     boards[4][1] = 10
    --     boards[5][1] = 10
    -- end
end
