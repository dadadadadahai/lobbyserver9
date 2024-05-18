-- FILE: 房费.xlsx SHEET: 房费
TableRoomCostConfig = {
[79]={["id"]=79,["usernbr"]=4,["gamenbr"]=4.0,["diamondcost"]=1.0,["averdiamondcost"]=0.25,["lobbyId"]=7},
[80]={["id"]=80,["usernbr"]=4,["gamenbr"]=6.0,["diamondcost"]=1.0,["averdiamondcost"]=0.25,["lobbyId"]=7},
[81]={["id"]=81,["usernbr"]=4,["gamenbr"]=8.0,["diamondcost"]=1.0,["averdiamondcost"]=0.25,["lobbyId"]=7},
[82]={["id"]=82,["usernbr"]=4,["gamenbr"]=12.0,["diamondcost"]=2.0,["averdiamondcost"]=0.5,["lobbyId"]=7},
[83]={["id"]=83,["usernbr"]=2,["gamenbr"]=4.0,["diamondcost"]=1.0,["averdiamondcost"]=0.5,["lobbyId"]=7},
[84]={["id"]=84,["usernbr"]=2,["gamenbr"]=6.0,["diamondcost"]=1.0,["averdiamondcost"]=0.5,["lobbyId"]=7},
[85]={["id"]=85,["usernbr"]=2,["gamenbr"]=8.0,["diamondcost"]=1.0,["averdiamondcost"]=0.5,["lobbyId"]=7},
[86]={["id"]=86,["usernbr"]=2,["gamenbr"]=12.0,["diamondcost"]=2.0,["averdiamondcost"]=1.0,["lobbyId"]=7},
[87]={["id"]=87,["usernbr"]=3,["gamenbr"]=4.0,["diamondcost"]=1.0,["averdiamondcost"]=0.333333343,["lobbyId"]=7},
[88]={["id"]=88,["usernbr"]=3,["gamenbr"]=6.0,["diamondcost"]=1.0,["averdiamondcost"]=0.333333343,["lobbyId"]=7},
[89]={["id"]=89,["usernbr"]=3,["gamenbr"]=8.0,["diamondcost"]=1.0,["averdiamondcost"]=0.333333343,["lobbyId"]=7},
}
setmetatable(TableRoomCostConfig, {__index = function(__t, __k) if __k == "query" then return function(index) return __t[index] end end end})
