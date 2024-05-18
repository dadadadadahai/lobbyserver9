
-- 游戏服 向 大厅 发来筹码警告
Zone.CmdSendChipsWarnLobbyCmd_C= function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.SendChipsWarnLobbyCmd_S"

	if cmd.data == nil or cmd.data.uid == nil or cmd.data.remainder == nil then
		res["data"] = {
			resultCode 	= 1,
			desc 		= "参数不完整",
		}
		return res
	end

	-- 收到警告后 调用函数
	LobbyToChessMgr.HandleChipsWarn(cmd.data.uid, cmd.data.remainder)
	res["data"] = {
		resultCode 	= 0,
		desc 		= "给大厅发送筹码警告成功",
	}
	return res	
end