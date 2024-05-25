-- 获取邮件列表
Net.CmdGetListMailCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetListMailCmd_S"
	local uid = laccount.Id
	cmd.data = cmd.data or {}
	local page = cmd.data.page or 0
	local  ret, desc, userMailInfo = MailMgr.GetListUserMail(uid,page)
	res["data"] = {
		errno 	= ret, 
		desc 		= desc, 
		mailInfo 	= userMailInfo,
	}
	return res
end

-- 请求邮件已读和总数
Net.CmdGetMailNumCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.GetMailNumCmd_S"
	local uid = laccount.Id
	local page = cmd.data.page or 0
	local dataInfo = MailMgr.GetUserMailNum(uid)
	res["data"] = {
		noReadNum 	= dataInfo.noReadNum,
		totalNum = dataInfo.totalNum,
		errno = 0
	}
	return res
end

-- 查看邮件 只有第一次看的时候 才会发送该条请求
Net.CmdReadMailCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.ReadMailCmd_S"
	local uid = laccount.Id
	if cmd.data == nil or cmd.data.id == nil then
		return 1, "参数有误"
	end

	local  ret, desc, mailInfo, coin, remainder = MailMgr.ReadMail(uid, cmd.data.id)
	res["data"] = {
		errno 	= ret, 
		desc 		= desc, 
		coin 		= coin, 
		mailInfo 	= mailInfo,
		remainder 	= remainder, 
	}
	return res
end

-- 删除邮件
Net.CmdDeleteMailCmd_C = function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.DeleteMailCmd_S"
	local uid = laccount.Id
	if cmd.data == nil or cmd.data.ids == nil or table.len(cmd.data.ids) == 0 then
		return 1, "参数有误"
	end

	local  ret, desc, userMailInfo = MailMgr.DeleteUserMail(uid, cmd.data.ids)
	res["data"] = {
		errno 	= ret, 
		desc 		= desc, 
		mailInfo 	= userMailInfo,
	}
	return res
end

--提取附件
Net.CmdGetAttachmentMailCmd_C = function(cmd, laccount)
    MailMgr.GetMailAttachment(laccount.Id, cmd.data.ids)
end
