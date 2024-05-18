module('Fisherman',package.seeall)
function GmProcess(uid, gameId, gameType, chessdata)
    -- local free =  chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    if gmInfo.free==1 then
        chessdata[2][2]=S
        chessdata[3][2]=S
        chessdata[4][2]=S
    end
    if gmInfo.bonus==1 then
        chessdata[3][2]=U
    end
end