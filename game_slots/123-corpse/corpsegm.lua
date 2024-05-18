module('corpse',package.seeall)
function GmProcess(uid,gameType,chessdata)
    local free =  chessuserinfodb.RUserGameControl(uid, GameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    local jackpot = chessuserinfodb.RUserGameControl(uid, GameId, gameType, Const.GAME_CONTROL_TYPE.JACKPOT)
    local bonus = chessuserinfodb.RUserGameControl(uid, GameId, gameType, Const.GAME_CONTROL_TYPE.BONUS)
    if gmInfo.bonus==1 or bonus == 1 then

        chessdata[5][1]=81
        chessdata[5][2]=81
        chessdata[5][3]=81
    elseif gmInfo.bonus==2 or bonus==2 then
        chessdata[5][1]=73
        chessdata[5][2]=73
        chessdata[5][3]=73
    elseif gmInfo.bonus==3 or bonus==3 then
        chessdata[5][1]=72
        chessdata[5][2]=72
        chessdata[5][3]=72
    elseif gmInfo.bonus==4 or bonus==4 then
        chessdata[5][1]=71
        chessdata[5][2]=71
        chessdata[5][3]=71
    end
    -- elseif gmInfo.jackpot==1 or jackpot==1 then
    --     chessdata[1][1]=73
    --     chessdata[2][1]=73
    --     chessdata[3][1]=73
    --     chessdata[4][1]=73
    -- end
end