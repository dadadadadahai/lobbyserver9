-- FILE: 上庄筹码列表.xlsx SHEET: config
TableBankerConfig = {
[1]={["id"]=1,["chips"]=80000000},
[2]={["id"]=2,["chips"]=100000000},
[3]={["id"]=3,["chips"]=300000000},
[4]={["id"]=4,["chips"]=500000000},
}
setmetatable(TableBankerConfig, {__index = function(__t, __k) if __k == "query" then return function(index) return __t[index] end end end})
