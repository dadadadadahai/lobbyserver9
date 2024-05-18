
-- 获取运营活动 幸运大转盘 信息
Net.CmdGetInfoLuckyTurnTableCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetInfoLuckyTurnTableCmd_S"

	local uid = laccount.Id

	-- 检测是否在运营活动时间 （暂时还没有运营时间控制相关逻辑）
	local isOpen = OperateSwitchMgr.CheckInOprateTime(OperateSwitchMgr.ENUM_OPRATE_TYPE.TURNTABLE)
	if isOpen == false then
		res["data"] = {
			resultCode 	= 1, 
			desc 	 	= "当前不在活动时间",
		}	
		return res	
	end

	local ret, desc, info = LuckyTurnTableMgr.GetInfoLuckyTurnTable(uid)
	res["data"] = {
		resultCode 	= ret, 
		desc 	 	= desc,
		integral 	= info.integral, 
	}
	return res
end

-- 转动 幸运大转盘 
Net.CmdTurnLuckyTurnTableCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.TurnLuckyTurnTableCmd_S"

	local uid = laccount.Id

	-- 检测是否在运营活动时间 
	local isOpen = OperateSwitchMgr.CheckInOprateTime(OperateSwitchMgr.ENUM_OPRATE_TYPE.TURNTABLE)
	if isOpen == false then
		res["data"] = {
			resultCode 	= 1, 
			desc 	 	= "当前不在活动时间",
		}		
		return res
	end

	local ret, desc, turnId, integral, remainder = LuckyTurnTableMgr.TurnLuckyTurnTable(uid)
	res["data"] = {
		resultCode 	= ret, 
		desc 	 	= desc,
		turnId 		= turnId, 
		integral 	= integral, 
		remainder 	= remainder, 
	}
	return res
end

-- 获取幸运大转盘 获奖记录
Net.CmdGetRecordLuckyTurnTableCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetRecordLuckyTurnTableCmd_S"

	local uid = laccount.Id

	-- 检测是否在运营活动时间 
	local isOpen = OperateSwitchMgr.CheckInOprateTime(OperateSwitchMgr.ENUM_OPRATE_TYPE.TURNTABLE)
	if isOpen == false then
		res["data"] = {
			resultCode 	= 1, 
			desc 	 	= "当前不在活动时间",
		}	
		return res	
	end

	local ret, desc, records = OprateRecordMgr.GetRecords(uid, OperateSwitchMgr.ENUM_OPRATE_TYPE.TURNTABLE)
	res["data"] = {
		resultCode 	= ret, 
		desc 	 	= desc,
		records  	= records, 
	}
	return res
end