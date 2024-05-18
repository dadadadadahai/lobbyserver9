-- 登陆
Net.CmdUserInfoSynRequestLobbyCmd_C = function (cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserInfoSynRequestLobbyCmd_S"
	local data = cmd.data
	local uid = laccount.Id 

	-- 获取到玩家信息
	local userData = chessuserinfodb.RUserLoginGet(uid)

	-- 接入某个大厅了 就必须经过大厅检测
	local zoneType = go.getconfigint("zone_type") 
	if zoneType ~= nil and zoneType ~= 0 then
		local ret = IntoGameMgr.CheckIntoGame(userData)
		if ret == false then
			res["data"]={
				ret 		= 1,
				desc 		= "未经过大厅检测 不允许进入游戏"
			}		
			return res 	
		end
	end

	-- 检查是否有上庄筹码,如果当前不是在坐庄 则把上庄筹码取出来
	if userData.property.bankerchips ~= 0 then
		if RoomMgr.IsBanker(uid) == false then
			_, _, _, userData = chessuserinfodb.WMoveBankerChipsToChips(uid)
		end
	end

	-- 如果当前游戏 接入捕鱼大厅 则可能存在有分未兑 则此处应该兑回去
	if go.getconfigint("zone_type") == 1 then
		if userInfo.fish ~= nil and userInfo.fish.converttype ~= nil then
			local userInfo = RoomMgr.LeaveRoomReturnCoin(uid)
		end
	end

	local userBaseInfo = UserInfo.GetUserDataBaseInfo(userData)

	-- 公共接口 获取该游戏 所有房间信息(这里是获取库存相关信息  这里只用到了填充房间名字)
	local roomInfoAll = chessroominfodb.GetRoomAllInfo(go.gamezone.Gameid)
	local roomInfoRet = {}
	for i, v in ipairs(roomInfoAll) do
		local roomItem = {
			roomId 			= v.roomId,
			maxUser 		= nil,
			roomName 		= v.roomName,
			lowestCarry 	= nil,
			lowestBet 		= nil,
			maxSeat 		= nil,
			bankerConfig 	= nil,
		}
		table.insert(roomInfoRet, roomItem)
	end	

	-- 从房间配置表中 获取房间最低携带 上庄筹码
	for i,v in ipairs(roomInfoRet) do
		-- 上庄相关筹码设置 由服务器 发给前端
		local bankerConfig = {}
		local selectChips = {}
		for i,vv in ipairs(TableBankerConfig) do
			table.insert(selectChips, vv.chips)
		end
		local lowestBankerChips = selectChips[1]

		bankerConfig.selectChips = selectChips
		bankerConfig.lowestBankerChips = lowestBankerChips

		v.bankerConfig = bankerConfig
	end

	res["data"] = {
		ret 		= 0,
		desc 		= "登录信息同步成功",
		userInfo 	= userBaseInfo,
		roomInfo 	= roomInfoRet,
		gmLevel 	= laccount.GetGmlevel(),
	}
	return res
end

-- 用户信息获取
Net.CmdUserInfoGetLobbyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserInfoGetLobbyCmd_S"
	local uid = laccount.Id

	-- 获取到玩家信息
	local userData 		= chessuserinfodb.RUserLoginGet(uid)
	local userBaseInfo 	= UserInfo.GetUserDataBaseInfo(userData)

	res["data"] = {
		ret 		= 0,
		desc 		= "获取指定信息成功",
		userInfo 	= userBaseInfo
	}
	return res
end

