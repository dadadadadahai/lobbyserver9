-- FILE: 创建房间选项.xlsx SHEET: 单个麻将设置 KEY: gameId
TableCreateConfigList = {
[1002]={["id"]=60,["gameId"]=1002,["gameName"]="宁都麻将",["baseUserNbr"]={4,3,2},["userNbr"]={{["value"]=4,["label"]="4人"},{["value"]=3,["label"]="3人"},{["value"]=2,["label"]="2人"}},["playType"]={{["label"]="",["idArr"]={198,199}},{["label"]="",["idArr"]={115,116,208,117}}},["defaltPlayType"]={198,115},["gameNbr"]={{["value"]=6,["label"]="6局"},{["value"]=12,["label"]="12局"}},["payType"]={},["hostTip"]={},["outTime"]={{["value"]=15,["label"]="15秒"},{["value"]=30,["label"]="30秒"},{["value"]=60,["label"]="60秒"},{["value"]=99,["label"]="99秒"}},["open"]=1,["gameshareTitle"]="%s<%s> 房号:【%s】 速度搞起！",["gameshareContent"]="房号:%s,%s人麻将,%s局,%s玩法,%s,快点来玩吧！"},
}
setmetatable(TableCreateConfigList, {__index = function(__t, __k) if __k == "query" then return function(gameId) return __t[gameId] end end end})
