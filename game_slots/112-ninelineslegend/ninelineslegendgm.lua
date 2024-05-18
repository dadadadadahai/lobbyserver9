module('NineLinesLegend',package.seeall)
function GmProcess(uid, gameId, gameType, chessdata,playResult)
    local free =  chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    local jackpot = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.JACKPOT)
    local bonus = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.BONUS)
    if gmInfo.free==1 or free == 1 then
        chessdata[2][2]=S
        chessdata[3][2]=S
        chessdata[4][2]=S
    end
    if gmInfo.bonus==1 or bonus == 1 then
        if table.empty(chessdata) == false then
            chessdata[2][1]=B
            chessdata[3][1]=B
            chessdata[4][1]=B
        end
    end
    if gmInfo.respin==1 then
        chessdata[2][3]=Bow
        chessdata[3][3]=Bow
        chessdata[4][3]=Bow
    end
    -- if gmInfo.jackpot == 1 or jackpot == 1 then
    --     local tableJackpot = {{jackpot = 4,mul = 0,pro = 120},{jackpot = 3,mul = 0,pro = 50},{jackpot = 2,mul = 0,pro = 20},{jackpot = 1,mul = 0,pro = 10}}
    --     playResult = tableJackpot[math.random(#tableJackpot)]
    -- end
    return playResult
end
