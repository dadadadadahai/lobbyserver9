-- 接收gm mail相关

-- 接收mail
GmSvr.PmdRequestSendMailGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	res["do"] = "RequestSendMailGmUserPmd_CS" 
    res.data.retdesc = ""
	-- local ret, desc = ChessGmMailMgr.AddGlobalMail(cmd.data.data)
    local data = cmd.data.data
    -- 生成默认邮件本体结构
    local mailConfig = import "table/table_mail_config"
    local content = mailConfig[48].content
    if data.content ~= nil and data.content ~= "" then
        content = data.content
    end
    -- 只有个人邮件判断玩家ID
    if data.type == 0 then
        local uidList = string.split(data.pid,",")

        for _, uid in ipairs(uidList) do
            uid = tonumber(uid)
            local userInfo = chessuserinfodb.RUserInfoGet(uid)
            if userInfo == nil then
                if res.data.retcode == 0 then
                    res.data.retdesc = "玩家id:"
                end
                res.data.retcode = 1
                res.data.retdesc = res.data.retdesc..uid..","
                -- return res
            else
                --发放奖励
                local mailInfo = {}
                mailInfo.charid = uid
                mailInfo.content = string.format(content,data.gold/100)
                mailInfo.type = data.type --0是个人邮件
                mailInfo.subject = ""
                mailInfo.attachment = {}
                if data.gold ~= nil and data.gold > 0 then
                    -- 增加奖励
                    BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, data.gold, Const.GOODS_SOURCE_TYPE.MAIL)
                end
                ChessGmMailMgr.AddGlobalMail(mailInfo)
                local data = {
                    timestamp = os.time(),
                    _id       = go.newObjectId(),
                    gmId      = cmd.data.gmid,
                    -- subject   = data.subject, 
                    content   = mailInfo.content,
                    chips     = data.gold,
                    uid       = uid,
                }
                unilight.savedata("maillog", data)
            end

        end
        if res.data.retcode == 1 then
            res.data.retdesc = res.data.retdesc.."不存在"
            return res
        end
    elseif data.type == 1 then
        if data.content == nil or data.content == "" then
            res.data.retcode = 1
            res.data.retdesc = "全局邮件内容为空"
            return res
        end
        -- 全局邮件
        local mailInfo = {}
        mailInfo.content = data.content
        mailInfo.type = 2
        mailInfo.attachment = {}
        mailInfo.extData = {}
        mailInfo.subject = ""
        ChessGmMailMgr.AddGlobalMail(mailInfo)
        local data = {
            timestamp = os.time(),
            _id       = go.newObjectId(),
            gmId      = cmd.data.gmid,
            -- subject   = data.subject, 
            content   = mailInfo.content,
            chips     = data.gold,
            uid       = data.charid,
        }
        unilight.savedata("maillog", data)
    end
    res.data.retcode = 0
    res.data.retdesc = "发送邮件成功"
    return res
end

-- 批量邮件
GmSvr.PmdRequestSendMailExGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	-- local ret, desc = ChessGmMailMgr.AddGlobalMail(cmd.data.data)

    local data = cmd.data.data
    local mailinfo = data.data 
    --批量个人邮件
    if data.extdata ~= "" then
        local uids = string.split(data.extdata, ",")
        for _, uid in pairs(uids) do
            uid = tonumber(uid)
            --发放奖励
            local mailInfo = {}

            mailInfo.charid = uid
            mailInfo.subject = mailinfo.subject
            mailInfo.content = mailinfo.content

            mailInfo.type = 0 --0是个人邮件

            if data.money ~= nil and data.money > 0 then
                mailInfo.attachment = {{itemId=Const.GOODS_ID.GOLD, itemNum=data.money}}
            end
            ChessGmMailMgr.AddGlobalMail(mailInfo)
        end

    --条件全区邮件
    else
        --发放奖励
        local mailInfo = {}
        mailInfo.subject = mailinfo.subject
        mailInfo.content = mailinfo.content

        mailInfo.type = 1 --0是个人邮件

        if data.money ~= nil and data.money > 0 then
            mailInfo.attachment = {{itemId=Const.GOODS_ID.GOLD, itemNum=data.money}}
        end
        ChessGmMailMgr.AddGlobalMail(mailInfo)
    end

	res.data.retcode = 0
	res.data.retdesc = "发送邮件成功"
	return res
end

-- 邮件界面 gm还会过来请求物品列表用于添加附件
GmSvr.PmdRequestItemTypeInfoGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	res["do"] = "RequestItemTypeInfoGmUserPmd_CS" 
	
	local zoneType = go.getconfigint("zone_type")
	-- 暂时只处理捕鱼大厅
	if zoneType == 1 then
		local itemTypeInfo = {
			itemtype = 1,
			typename = "金币",
			data = {}
		}
		local data = {
			itemid = 1,
			itemname = "金币",
			itemnum = 1,
			itemtype = 2,
		}
		table.insert(itemTypeInfo.data, data)
		res.data.data = {}
		table.insert(res.data.data, itemTypeInfo)
	end		
	
	res.data.retcode = 0
	res.data.retdesc = "获取物品成功"
	return res
end
