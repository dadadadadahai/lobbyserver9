-- FILE: 捕鱼大厅棋牌游戏设置.xlsx SHEET: 房间配置 KEY: gameId
TableBuYuLobbyGameConfig = {
[167]={["gameId"]=167,["perCoinScore"]=10000,["maxExchange"]=50000000},
[173]={["gameId"]=173,["perCoinScore"]=10000,["maxExchange"]=50000000},
[174]={["gameId"]=174,["perCoinScore"]=10000,["maxExchange"]=50000000},
}
setmetatable(TableBuYuLobbyGameConfig, {__index = function(__t, __k) if __k == "query" then return function(gameId) return __t[gameId] end end end})
