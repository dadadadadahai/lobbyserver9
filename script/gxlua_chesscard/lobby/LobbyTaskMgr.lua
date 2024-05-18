
-- 大厅 向  游戏服 发来的回复
Lby.CmdSendChipsWarnLobbyCmd_S= function(cmd, laccount)
	if cmd.data == nil or cmd.data.resultCode ~= 0 then
		unilight.info("大厅 不能正常收到低筹码警告")
	end
end
