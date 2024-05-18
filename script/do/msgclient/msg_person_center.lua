--绑定邮箱 
Net.CmdBindMailPersonCenterCmd_C = function(cmd, laccount)
	local uid = laccount.Id 

	local res = {}
	res["do"] = "Cmd.BindMailPersonCenterCmd_S"

	if cmd.data == nil or cmd.data.mailAddr == nil then
		res["data"] = {
			errno 	= 1,
			desc 	= "参数有误", 
		}
		return res
	end

	local ret, desc = PersonCenterMgr.BindMailAddr(uid, cmd.data.mailAddr)
	res["data"] = {
		errno 		= ret,
		desc 		= desc,
        mailAddr    = cmd.data.mailAddr
	}	
	return res
end


--修改头像
Net.CmdModifyHeadUrlPersonCenterCmd_C = function(cmd, laccount)
	local uid = laccount.Id 

	local res = {}
	res["do"] = "Cmd.ModifyHeadUrlPersonCenterCmd_S"

	if cmd.data == nil or cmd.data.headUrl == nil or cmd.data.frame == nil then
		res["data"] = {
			errno 	= 1,
			desc 	= "参数有误", 
		}
		return res
    end

	local ret, headUrl, frame, desc = PersonCenterMgr.ModifyHeadUrl(uid, cmd.data.headUrl, cmd.data.frame)
	res["data"] = {
		errno 		= ret,
		desc 		= desc,
        headUrl     = headUrl,
		frame       = frame,
	}	
	return res

end

--修改玩家名字
Net.CmdModifyNickNamePersonCenterCmd_C = function(cmd, laccount)
	local uid = laccount.Id 

	local res = {}
	res["do"] = "Cmd.ModifyNickNamePersonCenterCmd_S"

	if cmd.data == nil or cmd.data.nickName == nil or string.len(cmd.data.nickName) == 0 then
		res["data"] = {
			errno 	= 1,
			desc 	= "参数有误", 
		}
		return res
    end

	local ret, desc = PersonCenterMgr.ModifyNickName(uid, cmd.data.nickName)
	res["data"] = {
		errno 		= ret,
		desc 		= desc,
        nickName     = cmd.data.nickName,
	}	
	return res

end

--绑定手机
Net.CmdModifyPhoneNumberPersonCenterCmd_C = function(cmd, laccount)
	local uid = laccount.Id 
	PersonCenterMgr.BindPhoneNumber(uid, cmd)
end

--绑定账号
Net.CmdModifyPlataccountPersonCenterCmd_C = function(cmd, laccount)
	local uid = laccount.Id 
	PersonCenterMgr.BindPlataccount(uid, cmd)
end

--发送手机验证码
Net.CmdSendPhoneVerifyNumberPersonCenterCmd_C = function(cmd, laccount)
	local uid = laccount.Id 
	PersonCenterMgr.SendPhoneVerifyNumber(uid, cmd)
end

--反馈
Net.CmdFeedbackPersonCenterCmd_C = function(cmd, laccount)
	local uid = laccount.Id 
	PersonCenterMgr.Feedback(uid, cmd)
end
