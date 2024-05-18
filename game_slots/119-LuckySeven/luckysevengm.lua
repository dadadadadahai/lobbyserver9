module('LuckySeven',package.seeall)
function GmProcess(uid, gameId, gameType, chessdata)
    -- local free =  chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    if gmInfo.free>=1 then
        for i = 1, gmInfo.free do
            chessdata[i][1]=3
        end
        chessdata[math.random(1,gmInfo.free)][1]=90
    end
end