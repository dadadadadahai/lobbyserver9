-- gm控制指定运营活动开关
GmSvr = GmSvr or {}
GmSvr.GmOperateSwitch_C = function(cmd, laccount)
	local res = {}
	res["do"] = "GmOperateSwitch_S" 
	res["data"] = {}
	local roomId = 101
	if cmd.data == nil or cmd.data.opAcId == nil or cmd.data.openType == nil then
		res.data.retcode = 1 
		res.data.retdesc = "参数有误"
		return res
	end
	unilight.info("debug 收到gm指定运营活动开关" .. table.tostring(cmd.data))
	local opAcId 	= tonumber(cmd.data.opAcId)
	local openType 	= tonumber(cmd.data.openType)
	local isOpen 	= false
	if cmd.data.isOpen == "true" then
		isOpen = true
	end
	local appoint 	= cmd.data.appoint
	local between 	= cmd.data.between
	local ret, desc = OperateSwitchMgr.SetOprateTime(opAcId, openType, isOpen, appoint, between)
	res.data.retcode = ret 
	res.data.retdesc = desc
	return res
end

GmSvr.CmdOperateSwitch_C = function(cmd, laccount)
	local res = {}
	res["do"] = "CmdOperateSwitch_C"
	res["data"] = {}
	if cmd.data == nil or cmd.data.opAcId == nil then
		res.data.retcode = 1
		res.data.retdesc = "参数有误"
		return res
	end
	unilight.info("收到的所有参数:".. table.tostring(cmd.data))
	local uid = cmd.data.appoint
	local userInfo = chessuserinfodb.RUserInfoGet(uid)
	if userInfo == nil then
		res.data.retcode = 2
		res.data.retdesc = "玩家不存在"
		return res
	end
	local info = {}
	info.uid = uid
	unilight.savedata("gmlist", info)

end