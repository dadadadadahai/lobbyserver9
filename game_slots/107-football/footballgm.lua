module('Football',package.seeall)
function GmProcess(uid, gameId, gameType, colNum)

    -- local free =  chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    -- local jackpot = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.JACKPOT)
    local bonus = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.BONUS)
    if gmInfo.bonus==1 or bonus == 1 then
        return math.random(3)
    end
    return colNum
end
