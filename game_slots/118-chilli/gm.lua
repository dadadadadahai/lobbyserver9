module('chilli', package.seeall)
function GmProcess(uid,gameType,goldNum)
    local free =  chessuserinfodb.RUserGameControl(uid, GameId, gameType, Const.GAME_CONTROL_TYPE.FREE)
    if gmInfo.free==1 or free==1 then
        return 3
    end
    return goldNum
end