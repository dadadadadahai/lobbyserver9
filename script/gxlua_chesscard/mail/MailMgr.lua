module('MailMgr', package.seeall)
-- 邮件系统

-- 邮件类型type 0个人邮件 1群邮件

-- 初始化 个人邮件 相关存储
function InitUserMail(uid)
	local userMailData = {
		_id 		= uid,	-- 玩家id
		maildata 	= {},	-- 当前邮件数据
		lastid		= 0,	-- 最新同步的邮件id
	}
	SaveUserMail(userMailData)
	return userMailData
end

-- 获取邮件数据
function GetUserMail(uid)
	local userMailData = unilight.getdata("usermailinfo", uid)
	if userMailData == nil then
		userMailData = InitUserMail(uid)
	end
	return userMailData
end

-- 更新玩家邮件相关数据 
function UpdateUserMail(uid)
	-- 如果获取不到laccount则此次不更新邮件 (如果登录了推广员系统则在线玩家列表中存在该玩家 所以可能会通过检测 但是其获取不到laccount)
	local laccount = go.roomusermgr.GetRoomUserById(uid)
	if laccount == nil then
		return 
	end

	local userMailData = GetUserMail(uid)
	local userinfo = unilight.getdata('userinfo',uid)
	-- 获取公共邮件中的 符合要求的 前5封邮件
	local orderby 	= unilight.desc("id")
	local filter1 	= unilight.a(unilight.eq("type", 0), unilight.eq("charid", uid))	-- 单人邮件 且 对象是当前uid
	local filter2	= unilight.o(unilight.eq("type", 1), filter1)						-- 群体邮件 或者 是 （单人邮件 且 对象是当前uid）
	local filter3	= unilight.o(unilight.a(unilight.eq("type", 2),unilight.ge("recordtime", userinfo.status.registertimestamp)), filter2)	-- 群体邮件 但是是发邮件的时候已经拥有的账号
	local filter 	= unilight.a(unilight.gt("id", userMailData.lastid), filter3)		-- 且必须 id 大于 该玩家邮件的lastid
	local info = unilight.topdata("globalmailinfo", 5, orderby, filter)	                -- 最新的5封邮件
	local len = table.len(info)
	-- 存在新邮件需要更新
	if len > 0 then
		-- 从老到新 一个个填充到玩家自身的邮件列表中
		for i=len,1,-1 do
			local mailInfo = {
				id 		    = info[i].id,			-- 该邮件id
				subject		= info[i].subject,		-- 标题
				content		= info[i].content,		-- 内容
				recordtime 	= info[i].recordtime,	-- 发送时间
				attachment 	= info[i].attachment,	-- 附件
				isRead 		= false,				-- 默认未读
                overTime    = info[i].overTime,     -- 结束时间，到期后会删除邮件
                mailType    = info[i].mailType,     -- 邮件类型(参考Const.MAIL_TYPE)
			}

            unilight.info(string.format("玩家:%d, 获得新邮件, mailId=%d, subject=%s, 附件:%s", uid, mailInfo.id, mailInfo.subject, table2json(mailInfo.attachment)))
			table.insert(userMailData.maildata, mailInfo)
		end

        --[[
		-- 只保留最新的5条
		if table.len(userMailData.maildata) > 5 then
			userMailData.maildata = table.slice(userMailData.maildata, table.len(userMailData.maildata)-4, table.len(userMailData.maildata))
		end
        ]]

		-- 更新 最新一条邮件的id
		userMailData.lastid = userMailData.maildata[table.len(userMailData.maildata)].id

		SaveUserMail(userMailData)
	end

	-- 存在未读邮件则 主动推送一下给前端 提示小红点
	local isSend = false
    local notReadNum = 0
	for i,v in ipairs(userMailData.maildata) do
		if v.isRead == false then
			isSend = true
            notReadNum = notReadNum + 1
		end
	end
	if isSend then
		local res = {}
		res["do"] 	= "Cmd.NewMailCmd_Brd"
		res["data"] = {
            notReadNum = notReadNum,
        }
		unilight.success(laccount, res)
	end	
end

-- 存档
function SaveUserMail(userMailData)
	unilight.savedata("usermailinfo", userMailData)
end

-- 通过邮件存档数据 获取邮件信息
function GetMailInfoByData(mailData)
	local mailInfo = {
		id  		= mailData.id,
		subject 	= mailData.subject,
		content 	= mailData.content,
		recordTime 	= mailData.recordtime,
		isRead 		= mailData.isRead,
        mailType    = mailData.mailType,
        overTime    = mailData.overTime,
        attachment  = mailData.attachment,
        extData     = mailData.extData,
	}
	return mailInfo
end

-- 获取邮件列表
function GetListUserMail(uid,page)
	page = page or 0
	local userMailData = GetUserMail(uid)

	local userMailInfo = {}

	-- 邮件数据未读的放前面
	local isRead = {}	-- 已读
	local endPoints = table.len(userMailData.maildata) - 12 * (page + 1)
	if endPoints < 1 then
		endPoints = 1
	end
	-- 是否改变表示
	local isChange = false
	for i=table.len(userMailData.maildata), 1, -1 do
		local mailData = userMailData.maildata[i]
		if i <= table.len(userMailData.maildata) - 12 * page and i >= endPoints then
			if mailData ~= nil then		
				local mailInfo = GetMailInfoByData(mailData)
	
				-- 已读的先缓存起来 后期放到后面
				if mailData.isRead == true then
					table.insert(isRead, mailInfo)
				else
					table.insert(userMailInfo, mailInfo)
				end		
			end
		end
		-- 如果未读 则改为已读
		if mailData.isRead == false then
			mailData.isRead = true
			isChange = true
		end
	end
	-- 如果改变信息 则保存
	if isChange then
		unilight.savedata("usermailinfo", userMailData)
	end
	-- 最后把已读的拼接到后面 保证未读的在前面
	table.extend(userMailInfo, isRead)

	return 0, "获取邮件成功", userMailInfo
end
-- 获取邮件列表
function GetUserMailNum(uid)
	local userMailData = GetUserMail(uid)
	local noReadNum = 0
	for _, maildata in ipairs(userMailData.maildata) do
		if maildata.isRead == false then
			noReadNum = noReadNum + 1
		end
	end
	local res= {
		noReadNum 	= noReadNum,
		totalNum = table.len(userMailData.maildata),
	}
	return res
end

-- 查看邮件
function ReadMail(uid, id)
	local userMailData = GetUserMail(uid)

	local index 	= 0 -- 是否存在该邮件
	local mailData 	= {}
	for i,v in ipairs(userMailData.maildata) do
		if v.id == id then
			index = i
			mailData = v
			break
		end
	end

	-- 当前不存在该邮件 则返回当前最新邮件列表 当前最新邮件列表前端要求可通过删除邮件那条协议返回
	if index == 0 then
		local res = {}
		res["do"] = "Cmd.DeleteMailCmd_S"
		local _, _, userMailInfo = GetListUserMail(uid)
		res["data"] = {
			resultCode 	= 0, 
			desc 		= "用于邮件已失效时 同步当前最新邮件列表", 
			mailInfo 	= userMailInfo,
		}	
		local laccount = go.roomusermgr.GetRoomUserById(uid)
		unilight.success(laccount, res)	
		unilight.info("该邮件已失效 同步当前最新邮件列表")

		return 2, "该邮件已失效"
	end

	-- 当前邮件存在附件
	local add = nil
	local remainder = nil

	-- 获取该邮件具体信息
	local mailInfo = GetMailInfoByData(mailData)

	return 0, "读取邮件成功", mailInfo, add, remainder
end

-- 删除邮件数据
function DeleteUserMail(uid, mailIds)
	local userMailData = GetUserMail(uid)

	if table.len(userMailData.maildata) == 0 then
        unilight.error(string.format("玩家:%d, 删除邮件，邮件列表为空", uid))
		return 2, "当前不存在邮件可删除"
	end

	local remove = {}
	-- 遍历需要删除的所有邮件id
	for i,v in ipairs(mailIds) do
		remove[v] = true
	end

	-- 遍历该玩家的邮件列表
	local maildata = {}
	for i,v in ipairs(userMailData.maildata) do
		-- 如果不在删除列表中 则 当前邮件保留
		if remove[v.id] ~= true then
			table.insert(maildata, v)
		end
	end

	-- 确实删除了 某些邮件了 
	if table.len(maildata) < table.len(userMailData.maildata) then
		userMailData.maildata = maildata
		SaveUserMail(userMailData)

		local _, _, userMailInfo = GetListUserMail(uid)
        unilight.info(string.format("玩家:%d, 删除邮件id:(%s)成功", uid, table2json(mailIds)))
		return 0, "删除邮件成功", userMailInfo

	else
        unilight.error(string.format("玩家:%d, 删除邮件找不到邮件id:%s", uid, table2json(mailIds)))
		return 3, "删除的邮件id有误"
	end
end

-- 同意玩家申请发送邮件
function AgreeApplySendMail(userData, parentData, coin, applyType)
	if applyType == 0 then
		applyType = '充值'
	elseif applyType == 1 then
		applyType = '兑奖'
	end
	local mailInfo = {}
	mailInfo.charid = userData.uid
	mailInfo.subject = parentData.base.plataccount .. '已同意' .. applyType ..'申请'
	mailInfo.content = '您的'.. applyType ..'申请已成功,申请的币值为: ' .. coin .. '金币'
	mailInfo.type = 0
	ChessGmMailMgr.AddGlobalMail(mailInfo)
end

-- 同意玩家申请发送邮件
function RefuseApplySendMail(uid, parentData, coin, applyType, applyTime)
	if applyType == 0 then
		applyType = '充值'
	elseif applyType == 1 then
		applyType = '兑奖'
	end
	local mailInfo = {}
	mailInfo.charid = uid
	mailInfo.subject = parentData.base.plataccount .. '已拒绝' .. applyType ..'申请'
	mailInfo.content = '您的'.. applyType ..'申请已被拒绝,申请的币值为: ' .. coin .. ',申请时间:' .. applyTime
	mailInfo.type = 0
	ChessGmMailMgr.AddGlobalMail(mailInfo)
end


--检测邮件到期并删除邮件
function CheckOverTimeMail(uid)
    local userMailData = GetUserMail(uid)
    local delMailList = {}
    for _, mailInfo in pairs(userMailData.maildata) do
        if os.time() > mailInfo.overTime then
           table.insert(delMailList, mailInfo.id) 
		   unilight.info(string.format("玩家%d,邮到期删除邮件,endTime=%d, subject=%s",uid,mailInfo.overTime, mailInfo.subject))
        end
    end
    if table.len(delMailList) > 0 then
        DeleteUserMail(uid, delMailList)
    end
end

--提取附件
function GetMailAttachment(uid, mailIds)
    local userMailData = GetUserMail(uid)
    local bSucess = false
    local goodInfoList = {}
    local summary = {}   

	local send = {}
	send["do"] = "Cmd.GetAttachmentMailCmd_S"
    send["data"] = {
        ids = mailIds,
        errno = 0,
        desc  = "领取成功",
        goodInfoList = {},
    }

    for i,mailInfo in ipairs(userMailData.maildata) do
        for _, mailId in pairs(mailIds) do
            if mailInfo.id ==  mailId and mailInfo.isRead == false then
                if table.len(mailInfo.attachment) > 0 then
                    for _, itemInfo in ipairs(mailInfo.attachment) do
                        summary = BackpackMgr.GetRewardGood(uid, itemInfo.itemId, itemInfo.itemNum, Const.GOODS_SOURCE_TYPE.MAIL, summary)
                        if mailInfo.extData ~= nil and mailInfo.extData.isPresentChips ~= nil then
                            if itemInfo.itemId == Const.GOODS_ID.GOLD or itemInfo.itemId == Const.GOODS_ID.GOLD_BASE then
                                chessuserinfodb.WPresentChange(uid, Const.PACK_OP_TYPE.ADD, itemInfo.itemNum, "邮件赠送金币")
                            end
                        end
                    end
                end
                --mailInfo.attachment = {}    --清空附件
                mailInfo.isRead = true
                bSucess = true
            end
        end
    end

    if bSucess == false then
        send["data"] = {
            ids = mailIds,
            errno = 1,
            desc  = "没有可领的附件",
        }
        unilight.sendcmd(uid, send)
        return
    end

    for k, v in pairs(summary) do
        table.insert(send.data.goodInfoList, {goodId=k, goodNum=v})
    end
    SaveUserMail(userMailData)

    unilight.sendcmd(uid, send)
end
