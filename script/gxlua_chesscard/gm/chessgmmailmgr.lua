module("ChessGmMailMgr", package.seeall)

local tableMailConfig   = import "table/table_mail_config"
-- 初始化一个全局唯一的 邮件id
function InitEmailId()
	local info = {
		_id 	= 1,
		emailid = 100000,	-- 初始化10w 因为以前全局唯一由平台控制 避免重复
	}
	unilight.savedata("globalemailid", info)
	return info 
end

-- 获取一个全局唯一的 邮件id
function GetEmailId()
	local info = unilight.getdata("globalemailid", 1)
	if info == nil then
		info = InitEmailId()
	end 
	info.emailid = info.emailid + 1
	unilight.savedata("globalemailid", info)
	return info.emailid
end

-- 新增 全局邮件 gm工具添加后 这里主动添加
--[[
    @param mailInfo  邮件信息,结构如下
        local mailInfo = {}
        mailInfo.charid = 角色uid
        mailInfo.subject = 邮件主题
        mailInfo.content = 邮件内容
        mailInfo.type = 0 --0是个人邮件, 1是所有玩家邮件
        mailInfo.attachment = {{itemId=xx, itemNum=xx}}
        mailInfo.extData = {
            configId = 1,   --邮件表配置id
            uid      = 1,   --客户端有时候需要的用户id
        }
        ChessGmMailMgr.AddGlobalMail(mailInfo)

    @param mailType  标记是系统邮件，还是其它功能邮件，前端要放在不同地方展示，默认是系统邮件
]]

function AddGlobalMail(mailInfo, mailType)
	if mailInfo == nil then
		return 1, "邮件信息为空 发送邮件失败"
	end
    mailInfo.mailType = mailType
    if mailType == nil then
        mailInfo.mailType = Const.MAIL_TYPE.SYSTEM
    end


	-- 全局唯一的邮件id 现在自己维护
	local emailId = GetEmailId()
	mailInfo.id = emailId

    mailInfo.isRead = false

	-- 所有gm过来的邮件 均存档
	if mailInfo.recordtime == nil then
		mailInfo.recordtime = os.time()
	end

    --过期时间
    if mailInfo.overTime == nil then
        -- mailInfo.overTime = os.time() +  Const.MAIL_TIME[mailInfo.mailType] or 86400 * 7
        mailInfo.overTime = os.time() +  Const.MAIL_TIME[4] or 86400 * 7
    end

    if mailInfo.extData == nil then
        mailInfo.extData = {}
    end

    if mailInfo.configId == nil then
        mailInfo.configId = 0
    end
    
    --配表时间
    local mailConfig = tableMailConfig[mailInfo.configId]
    if mailConfig ~= nil then
        mailInfo.overTime = os.time() +  mailConfig.limitTime
    end

    --个人邮件直接扔玩家身上
    if mailInfo.type == 0 then
        local userMailData = MailMgr.GetUserMail(mailInfo.charid)
        table.insert(userMailData.maildata, mailInfo)
        MailMgr.SaveUserMail(userMailData)

        --玩家在线推着下新邮件提示
        local laccount = go.roomusermgr.GetRoomUserById(mailInfo.charid)
        if laccount ~= nil then
            MailMgr.UpdateUserMail(mailInfo.charid)
        end
        unilight.info(string.format("玩家:%d, 获得新邮件, mailId=%d, subject=%s, 附件:%s", mailInfo.charid, mailInfo.id, mailInfo.subject, table2json(mailInfo.attachment)))
    else
        unilight.savedata("globalmailinfo", mailInfo)
        -- 每次添加邮件的时候 主动更新一下当前在线玩家的邮件
        if type(MailMgr.UpdateUserMail) == "function" then
            local userInfo = go.accountmgr.GetOnlineList()
            if mailInfo.type == 0 then
                -- 单人邮件 则检测该玩家是否在线 在线 则刷一下 
                for i=1,#userInfo do
                    if userInfo[i] == mailInfo.charid then
                        MailMgr.UpdateUserMail(mailInfo.charid)
                        break
                    end
                end			
            else
                -- 多人邮件 所有在线玩家均刷新一下
                local userInfo = go.accountmgr.GetOnlineList()
                for i=1,#userInfo do
                    MailMgr.UpdateUserMail(userInfo[i])
                end			
            end
        end

    end



	return 0, "发送邮件成功"
end
