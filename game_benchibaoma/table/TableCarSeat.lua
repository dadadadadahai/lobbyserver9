-- FILE: 车行争霸倍数.xlsx SHEET: seat
TableCarSeat = {
[1]={["seatidx"]=1,["id"]=1,["name"]="大保时捷"},
[2]={["seatidx"]=2,["id"]=2,["name"]="小保时捷"},
[3]={["seatidx"]=3,["id"]=3,["name"]="大宝马"},
[4]={["seatidx"]=4,["id"]=4,["name"]="小宝马"},
[5]={["seatidx"]=5,["id"]=5,["name"]="大奥迪"},
[6]={["seatidx"]=6,["id"]=6,["name"]="小奥迪"},
[7]={["seatidx"]=7,["id"]=7,["name"]="大大众"},
[8]={["seatidx"]=8,["id"]=8,["name"]="小大众"},
[9]={["seatidx"]=9,["id"]=1,["name"]="大保时捷"},
[10]={["seatidx"]=10,["id"]=2,["name"]="小保时捷"},
[11]={["seatidx"]=11,["id"]=3,["name"]="大宝马"},
[12]={["seatidx"]=12,["id"]=4,["name"]="小宝马"},
[13]={["seatidx"]=13,["id"]=5,["name"]="大奥迪"},
[14]={["seatidx"]=14,["id"]=6,["name"]="小奥迪"},
[15]={["seatidx"]=15,["id"]=7,["name"]="大大众"},
[16]={["seatidx"]=16,["id"]=8,["name"]="小大众"},
[17]={["seatidx"]=17,["id"]=1,["name"]="大保时捷"},
[18]={["seatidx"]=18,["id"]=2,["name"]="小保时捷"},
[19]={["seatidx"]=19,["id"]=3,["name"]="大宝马"},
[20]={["seatidx"]=20,["id"]=4,["name"]="小宝马"},
[21]={["seatidx"]=21,["id"]=5,["name"]="大奥迪"},
[22]={["seatidx"]=22,["id"]=6,["name"]="小奥迪"},
[23]={["seatidx"]=23,["id"]=7,["name"]="大大众"},
[24]={["seatidx"]=24,["id"]=8,["name"]="小大众"},
[25]={["seatidx"]=25,["id"]=1,["name"]="大保时捷"},
[26]={["seatidx"]=26,["id"]=2,["name"]="小保时捷"},
[27]={["seatidx"]=27,["id"]=3,["name"]="大宝马"},
[28]={["seatidx"]=28,["id"]=4,["name"]="小宝马"},
[29]={["seatidx"]=29,["id"]=5,["name"]="大奥迪"},
[30]={["seatidx"]=30,["id"]=6,["name"]="小奥迪"},
[31]={["seatidx"]=31,["id"]=7,["name"]="大大众"},
[32]={["seatidx"]=32,["id"]=8,["name"]="小大众"},
}
setmetatable(TableCarSeat, {__index = function(__t, __k) if __k == "query" then return function(index) return __t[index] end end end})