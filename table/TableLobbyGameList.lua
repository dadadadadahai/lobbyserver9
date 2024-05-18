-- FILE: 创建房间选项.xlsx SHEET: 麻将大厅设置
TableLobbyGameList = {
[7]={["id"]=7,["desc"]="江西客家麻将",["iniDiamond"]=100,["iniRoomCard"]=10,["returnDiamond"]=0,["mahjongList"]={1002},["exerciseList"]={{["id"]=1,["bet"]=5,["type"]=1,["minLimit"]=50,["maxLimit"]=0,["cost"]=1},{["id"]=2,["bet"]=10,["type"]=1,["minLimit"]=200,["maxLimit"]=0,["cost"]=2},{["id"]=3,["bet"]=20,["type"]=1,["minLimit"]=2000,["maxLimit"]=0,["cost"]=3}},["shopList"]={109,110,111,112},["exerciseLabelList"]={{["id"]=1,["name"]="初级场",["bet"]="底注5钻石",["limit"]="50钻石以上"},{["id"]=2,["name"]="中级场",["bet"]="底注10钻石",["limit"]="200钻石以上"},{["id"]=3,["name"]="高级场",["bet"]="底注20钻石",["limit"]="2000钻石以上"}},["freeList"]={},["shareTitle"]="江西客家麻将",["noPractice"]=0,["pracFee"]=2,["autoMode"]=0,["giftCost"]=1,["shareFirst"]="江西客家麻将",["shareContent"]="今天玩了一款很好玩的麻将，你也来试试吧！"},
}
setmetatable(TableLobbyGameList, {__index = function(__t, __k) if __k == "query" then return function(index) return __t[index] end end end})
