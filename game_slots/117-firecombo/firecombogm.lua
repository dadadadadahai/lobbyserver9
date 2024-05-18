module('FireCombo',package.seeall)
function GmProcess(uid, gameId, gameType, chessdata,playResult)
    local free =  chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    local jackpot = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.JACKPOT)
    local bonus = chessuserinfodb.RUserGameControl(uid, gameId, gameType, Const.GAME_CONTROL_TYPE.BONUS)
    if gmInfo.free==1 or free == 1 then
        chessdata[1][2]=S
        chessdata[3][2]=S
        chessdata[5][2]=S
    end
    if gmInfo.bonus==1 or bonus == 1 then
        playResult = FireCombo['table_117_normalu_'..gameType][6]
    end
    if gmInfo.respin==1 then
        chessdata[1][1] = FreeU
        chessdata[1][2] = FreeU
    end
    -- if gmInfo.jackpot == 1 or jackpot == 1 then
    --     local tableJackpot = {{jackpot = 4,mul = 0,pro = 120},{jackpot = 3,mul = 0,pro = 50},{jackpot = 2,mul = 0,pro = 20},{jackpot = 1,mul = 0,pro = 10}}
    --     playResult = tableJackpot[math.random(#tableJackpot)]
    -- end
    return playResult
end
