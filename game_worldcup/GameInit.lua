local zoneKey = go.config().GetConfigStr("zone_key")
local gameId = tonumber(string.split(zoneKey, ":")[1])
GameId = "G"..gameId
NUMBER_GAMEID = gameId
module('WorldCup',package.seeall)
RobotManage = {}            --机器人行为管理类
--启动事件
function StartOver()
    --注册游戏
    gamecommon.RegGame(WorldCup.GameId,WorldCup)
    chessroominfodb.InitUnifiedRoomInfoDb(go.gamezone.Gameid,0,nil,nil,nil,nil,0,0)
    WorldCup.Init()
end