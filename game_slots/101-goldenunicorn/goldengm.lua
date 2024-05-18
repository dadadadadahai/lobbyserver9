module('goldenunicorn',package.seeall)
function GmProcess(uid, gameId, gameType, chessdata,datainfo)
    local free =  chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    local jackpot = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.JACKPOT)
    local bonus = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.BONUS)
    if gmInfo.respin==1 then
        chessdata[1][1] = W
    elseif gmInfo.free==1 or free == 1 then
        chessdata[3][2] = S
        chessdata[4][3] = S
        chessdata[5][1] = S
    elseif gmInfo.bonus==1 or bonus == 1 then
        chessdata[2][2] = U
        chessdata[3][3] = U
        chessdata[4][1] = U
    end
end
