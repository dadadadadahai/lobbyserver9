
Net.CmdUserInfoModifyRequestLobyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserInfoModifyReturnLobyCmd_S"
	if cmd.data.nickName == "" then
		cmd.data.nickName = nil
	end

	if cmd.data.gender == "" then
		cmd.data.gender = nil
	end

	if cmd.data.headUrl == "" then
		cmd.data.headUrl = nil
	end

	if cmd.data.signature == "" then
		cmd.data.signature = nil
	end

	local uid = laccount.Id
	local userInfo = {
		nickName = cmd.data.nickName,
		headUrl = cmd.data.headUrl,
		gender = cmd.data.gender,
		signature = cmd.data.signature,
	}		
	local userBaseInfo = chessuserinfodb.WUserInfoModity(uid, userInfo)
	res["data"] = {
		resultCode = 0,
		desc = "ok",
		userInfo = userBaseInfo,
	}
	return res
end

Net.CmdUserBaseInfoRequestLbyCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.UserBaseInfoReturnLbyCmd_S"
	if cmd.data == nil or cmd.data.uid == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数不足"
		}
		return res
	end

	-- 有可能是机器人
	local uid = tonumber(cmd.data.uid)
	local userInfo = chessuserinfodb.RUserInfoGet(uid)	
	if userInfo == nil then
		res["data"] = {
			resultCode = 2,
			desc = "所查找玩家未注册" .. uid
		}
		return res
	end

	local userBaseInfo = chessuserinfodb.RUserBaseInfoGet(userInfo)	
	if RobotMgr ~= nil and RobotMgr.CmdIsRobot ~= nil and RobotMgr.CmdRobotInfoGet ~= nil then
		if RobotMgr.CmdIsRobot(uid) then
			local robotInfo = RobotMgr.CmdRobotInfoGet(uid)
			userBaseInfo.bankerCips = userBaseInfo.bankerCips
			userBaseInfo.remainder = robotInfo.chips or userBaseInfo.remainder
		end	
	end

	res["data"] = {
		resultCode = 0,
		desc = "ok",
		uid = uid,
		userInfo = userBaseInfo,
	}
	return res
end

Net.PmdEmailRegistRequestCreateAccountLoginUserPmd_C = function(cmd, laccount) 
	local res = {}
	res["do"] = "Pmd.EmailRegistReturnCreateAccountLoginUserPmd_S"
	if cmd.data == nil or cmd.data.email == nil or cmd.data.email == "" or cmd.data.password == nil or cmd.data.password == "" then
		res["data"] = {
			resultCode = 5,
			desc = "参数不足"
		}
		return res
	end
    cmd.data.isbind = true
    cmd.data.uid = laccount.Id
    local resStr = json.encode(encode_repair(cmd.data))
    local bok = go.buildProtoFwdServer("*Pmd.EmailRegistRequestCreateAccountLoginUserPmd_C", resStr, "LS")
    if bok == true then
        unilight.info("游客模式去绑定请求成功" .. resStr)
    else
        unilight.error("游客模式去绑定请求失败" .. resStr)
    end
end

LoginClientTask = LoginClientTask or {}
LoginClientTask.EmailRegistReturnCreateAccountLoginUserPmd_S= function(task, cmd)
    local retCode = cmd.GetRetcode()
    local desc = cmd.GetDesc()
    local uid = cmd.GetUid()
	local accountTcp = go.roomusermgr.GetRoomUserById(uid)
    accountTcp = accountTcp or go.accountmgr.GetAccountById(uid)
	if accountTcp == nil then
		unilight.error("laccount is null  EmailRegistReturnCreateAccountLoginUserPmd_S : " .. uid)
		return 
	end
	res = {}
	res["do"] = "Pmd.EmailRegistReturnCreateAccountLoginUserPmd_S"
	res.data = {
        retcode = retCode,
        desc = desc,
        uid = uid,
    }
	unilight.success(accountTcp, res)
end

