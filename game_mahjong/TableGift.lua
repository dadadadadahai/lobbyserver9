-- FILE: 表情礼物表.xlsx SHEET: 礼物 KEY: giftId
TableGift = {
[1]={["giftId"]=1,["giftName"]="黄瓜",["giftCost"]=1,["giftCharm"]=0},
[2]={["giftId"]=2,["giftName"]="棒棒糖",["giftCost"]=5,["giftCharm"]=0},
[3]={["giftId"]=3,["giftName"]="砖头",["giftCost"]=10,["giftCharm"]=0},
[4]={["giftId"]=4,["giftName"]="炸弹",["giftCost"]=20,["giftCharm"]=0},
[5]={["giftId"]=5,["giftName"]="柠檬汁",["giftCost"]=50,["giftCharm"]=0},
[6]={["giftId"]=6,["giftName"]="蓝色妖姬",["giftCost"]=100,["giftCharm"]=0},
}
setmetatable(TableGift, {__index = function(__t, __k) if __k == "query" then return function(giftId) return __t[giftId] end end end})
