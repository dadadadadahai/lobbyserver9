module('FruitMachine',package.seeall)
function GmProcess(uid, gameId, gameType, chessdata)
    -- local free =  chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    -- local jackpot = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.JACKPOT)
    local bonus = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.BONUS)
    if gmInfo.bonus==1 or bonus == 1 then
        chessdata[1][2]=B
        chessdata[2][2]=B
        chessdata[3][2]=B
    end
    -- if gmInfo.jackpot==1 then
        
    --     local jackpotInfo = Table_JackpotIcon[math.random(#Table_JackpotIcon - 1)]
    --     playResult = {iconId = jackpotInfo.iconId,jackpot = jackpotInfo.jackpot}
    -- end
    -- return playResult
end
