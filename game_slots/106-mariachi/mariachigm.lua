module('mariachi',package.seeall)
function GmProcess(uid, gameId, gameType, chessdata,datainfo)
    local free =  chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    -- local jackpot = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.JACKPOT)
    local bonus = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.BONUS)
    if gmInfo.free==1 or free == 1 then
        chessdata[2][2]=S
        chessdata[3][2]=S
        chessdata[4][2]=S
    elseif gmInfo.bonus==1 or bonus == 1 then
        chessdata[2][2]=U
        chessdata[3][2]=U
        chessdata[4][2]=U
    end
end
