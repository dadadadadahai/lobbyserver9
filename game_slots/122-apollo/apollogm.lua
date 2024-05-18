module('Apollo',package.seeall)
function GmProcess(uid, gameId, gameType, chessdata)
    local free =  chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    local jackpot = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.JACKPOT)
    local bonus = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.BONUS)
    if gmInfo.free==1 or free == 1 then
        chessdata[1][2]=S
        chessdata[3][2]=S
        chessdata[5][2]=S
    end
    if gmInfo.respin==1 then
        chessdata[1][2]=U
        chessdata[2][2]=U
        chessdata[3][2]=U
        chessdata[4][2]=U
        chessdata[5][2]=U
        chessdata[3][1]=U
    end
end
