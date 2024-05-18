-- 检测当前能否进入 指定游戏、指定区服
Net.CmdCheckIntoGameCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.CheckIntoGameCmd_S"
	if cmd.data == nil or cmd.data.gameId == nil or cmd.data.zoneId == nil then
		res["data"] = {
			resultCode 	= 1,
			desc 		= "参数有误"
		}
		return res
	end
	local uid = laccount.Id
	local ret, desc, gameId, zoneId = IntoGameMgr.LobbyCheckIntoGame(uid, cmd.data.gameId, cmd.data.zoneId)
	res["data"] = {
		resultCode 	= ret,
		desc 		= desc, 
		gameId 		= gameId,
		zoneId 		= zoneId,
	}
	return res
end

