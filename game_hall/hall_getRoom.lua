local table_game_list = import 'table/table_game_list'
--获取房间处理
-- 获取合适的练习场(同样需要通知游戏服准备好 然后等待回调)
Net.CmdGetPracticeGameInfoRoomCmd_C = function(cmd, laccount)
	local uid = laccount.Id
	if cmd.data == nil or cmd.data.lobbyId == nil then
		RoomInfo.SendFailToUser("参数有误",laccount)
		RoomInfo.SendCmdToUser("Cmd.GetPracticeGameInfoRoomCmd_S",{errno = ErrorDefine.ERROR_PARAM, desc= "参数有误"},laccount)		
		return
	end
	local lobbyId = cmd.data.lobbyId
	local lobbyTableInfo = table_game_list[lobbyId]
	if lobbyTableInfo == nil then
		RoomInfo.SendCmdToUser("Cmd.GetPracticeGameInfoRoomCmd_S",{errno = ErrorDefine.ERROR_PARAM, desc= "参数有误"},laccount)		
		return
	end
    local chips = chessuserinfodb.RUserChipsGet(uid)
    if chips <  lobbyTableInfo.limitLow then
		RoomInfo.SendCmdToUser("Cmd.GetPracticeGameInfoRoomCmd_S",{errno = ErrorDefine.CHIPS_NOT_ENOUGH, desc= "参数有误"},laccount)		
		return
    end
	local gameId = 1002
	--检查redis,是否有在线信息
	local ok,rSubGameId =  backRealtime.checkRedisOnline(1002,uid)
	
	local zoneId = lobbyTableInfo.subGameId*100+11
	--构造房间默认参数
	cmd.data.lobbyId 	= cmd.data.lobbyId or 0
	cmd.data.gameId 	= gameId
	cmd.data.gameNbr 	= cmd.data.gameNbr or 0
	cmd.data.userNbr 	= cmd.data.userNbr or 0		-- 
	cmd.data.payType 	= cmd.data.payType or 1		-- 支付没传 默认房主支付
	cmd.data.hostTip 	= cmd.data.hostTip or 1		-- 房主小费没传 默认为1
	cmd.data.outTime    = 15 						-- 操作时间
	cmd.data.props      = {} 						-- 房间其余参数

	local data = {
		errno       = 0,
		desc        = "sucess",
		gameId 		= gameId,
		zoneId 		= zoneId,
		roomId 		= 0,
		globalRoomId	= 0,
		lobbyId     = cmd.data.lobbyId,
	}
	local send={}
	send['do'] = 'Cmd.GetPracticeGameInfoRoomCmd_S'
	send['data'] =data
	return send
end