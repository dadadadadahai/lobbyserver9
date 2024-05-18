-- FILE: 车行争霸倍数.xlsx SHEET: typeid
TableCarTypeid = {
[1]={["id"]=1,["name"]="大保时捷",["mult"]=40,["prob"]=248,["maxbet"]=99999999},
[2]={["id"]=2,["name"]="小保时捷",["mult"]=5,["prob"]=1983,["maxbet"]=99999999},
[3]={["id"]=3,["name"]="大宝马",["mult"]=30,["prob"]=331,["maxbet"]=99999999},
[4]={["id"]=4,["name"]="小宝马",["mult"]=5,["prob"]=1983,["maxbet"]=99999999},
[5]={["id"]=5,["name"]="大奥迪",["mult"]=20,["prob"]=496,["maxbet"]=99999999},
[6]={["id"]=6,["name"]="小奥迪",["mult"]=5,["prob"]=1983,["maxbet"]=99999999},
[7]={["id"]=7,["name"]="大大众",["mult"]=10,["prob"]=992,["maxbet"]=99999999},
[8]={["id"]=8,["name"]="小大众",["mult"]=5,["prob"]=1984,["maxbet"]=99999999},
}
setmetatable(TableCarTypeid, {__index = function(__t, __k) if __k == "query" then return function(index) return __t[index] end end end})
