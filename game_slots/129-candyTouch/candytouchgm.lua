module('CandyTouch',package.seeall)
function GmProcess(uid, gameId, gameType, chessdata)
    -- local free =  chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    local wildFlag = false
    local wildPoint = {}
    if gmInfo.free==1 then
        chessdata[2][2]=S
        chessdata[3][2]=S
        chessdata[4][2]=S
    end
    if gmInfo.bonus==1 then
        chessdata[3][2] = U
    end
    if gmInfo.respin==1 then
        wildFlag = true
        wildPoint = {3,2}
        chessdata[3][2] = W
        chessdata[3][3] = B
        chessdata[3][1] = B
        chessdata[2][2] = B
        chessdata[1][2] = B
    end
    return wildFlag,wildPoint
end