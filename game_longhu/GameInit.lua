local zoneKey = go.config().GetConfigStr("zone_key")
local gameId = tonumber(string.split(zoneKey, ":")[1])
GameId = "G"..gameId
NUMBER_GAMEID = gameId
module('LongHu',package.seeall)
--启动事件
function StartOver()
    gamecommon.RegGame(LongHu.GameId,LongHu)
    chessroominfodb.InitUnifiedRoomInfoDb(go.gamezone.Gameid,0,nil,nil,nil,nil,0,0)
    LongHu.Init()
end