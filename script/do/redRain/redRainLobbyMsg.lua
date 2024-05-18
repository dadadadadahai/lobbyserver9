
--来自大厅的消息,游戏服信息
Lobby.CmdRedCmd_S = function(cmd,zonetask)    
    local doInfo='Cmd.RedTriggerCmd_Brd'
	local jobj =  json.decode(cmd)
	redRain.redId = jobj.data.redId
	redRain.firstRedId = jobj.data.firstRedId
	redRain.endRedId = jobj.data.endRedId
	redRain.timeList = jobj.data.timeList
	redRain.GmFlag = jobj.data.GmFlag
    chesstcplib.TcpMsgSendEveryOne(doInfo, {endTime = jobj.data.endTime})
end
--场景消息
Net.CmdRedRainInfoRequestSgnCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
	res["do"] = "Cmd.RedRainInfoRequestSgnCmd_S"
	local redRainData = redRain.RedRainInfo(uid)
	res["data"] = redRainData
	return res
end
--领取消息
Net.CmdRedRainGetRequestSgnCmd_C = function(cmd, laccount)
    local res = {}
    local uid = laccount.Id
	res["do"] = "Cmd.RedRainGetRequestSgnCmd_S"
	local redRainData = redRain.RedRainGet(uid)
	res["data"] = redRainData
	return res
end