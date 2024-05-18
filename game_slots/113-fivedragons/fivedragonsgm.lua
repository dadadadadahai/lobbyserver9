module('FiveDragons',package.seeall)
function GmProcess(uid, gameId, gameType, chessdata)
    local free =  chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    -- local jackpot = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.JACKPOT)
    local bonus = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.BONUS)
    if gmInfo.free==1 or free == 1 then
        chessdata[1][2]=S
        chessdata[2][2]=S
        chessdata[3][2]=S
    end
    if gmInfo.bonus==1 or bonus == 1 then
        chessdata[1][2]=E
        chessdata[5][2]=E
    end
end
