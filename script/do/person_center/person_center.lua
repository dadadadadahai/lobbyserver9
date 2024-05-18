module("PersonCenterMgr", package.seeall)

UserPhoneNbrDatas = {}                 --手机短信次数
SMS_MAX_NUM  = 5                       --每天上限次数

local table_parameter_formula = import "table/table_parameter_formula"

-- 绑定邮箱
function BindMailAddr(uid, mailAddr)
    --未做校验
	local userInfo = chessuserinfodb.RUserInfoGet(uid)
    userInfo.base.email = mailAddr
    chessuserinfodb.WUserInfoUpdate(uid, userInfo)
	return 0, "设置成功" 
end

-- 修改头像
function ModifyHeadUrl(uid, headUrl, frame)
	local userInfo = chessuserinfodb.RUserInfoGet(uid)
    userInfo.headurl = headUrl
    local bFind = false
    local newFrame = 0
    for k, v in pairs(userInfo.property.headFramList) do
        if frame == v then
            bFind  = true
            break
        end
    end
    userInfo.base.headurl = headUrl
    if bFind then
        -- userInfo.base.headFrame = frame
        newFrame = frame
    end
    chessuserinfodb.WUserInfoUpdate(uid, userInfo)
	return 0, headUrl, frame, "设置成功"
end

-- 修改玩家名字
function ModifyNickName(uid, nickName)
	local userInfo = chessuserinfodb.RUserInfoGet(uid)
    local nickName = string.gsub(nickName, "\r\n", "")
    userInfo.base.nickname = nickName
    chessuserinfodb.WUserInfoUpdate(uid, userInfo)
	return 0, "设置成功" 
end


--绑定手机
function BindPhoneNumber(uid, msg)
	local res = {}
	res["do"] = "Cmd.ModifyPhoneNumberPersonCenterCmd_S"
    res.data = {
        reqType = msg.data.reqType,
        errno 	= ErrorDefine.SUCCESS,
        desc 	= "成功", 
    }
	if msg.data == nil or msg.data.phoneNbr == nil or msg.data.verifyNbr == nil or msg.data.reqType == nil then
		res.data.errno = ErrorDefine.ERROR_PARAM
        res.data.desc  = "参数有误"
        unilight.sendcmd(uid, res)
		return
    end

    local userInfo  = UserInfo.GetUserDataById(uid)
    local reqType   = msg.data.reqType
    local phoneNbr  = msg.data.phoneNbr
    local verifyNbr = msg.data.verifyNbr
    --真实的验证码
    local realVerifyNbr = unilight.redis_getdata(phoneNbr)
    if verifyNbr ~= realVerifyNbr then
		res.data.errno = ErrorDefine.CENTER_ERROR_VERIFY
        res.data.desc  = "错误的验证码"
        unilight.sendcmd(uid, res)
        return
    end

    --新绑定
    if reqType == 1 then
        if string.len(userInfo.base.phoneNbr) > 0 then
            res.data.errno = ErrorDefine.CENTER_DUPLICATE_BIND
            res.data.desc  = "重复绑定"
            unilight.sendcmd(uid, res)
            return 
        end

        local allNum 	= unilight.startChain().Table("userinfo").Filter(unilight.eq("base.phoneNbr", phoneNbr)).Count()
        if allNum > 0 then
            res.data.errno = ErrorDefine.CENTER_DUPLICATE_BIND
            res.data.desc  = "重复绑定"
            unilight.sendcmd(uid, res)
            return 
        end

        --修改成功回来再修改
        -- userInfo.base.phoneNbr = phoneNbr
        -- userInfo.base.passwd   = msg.data.password
        res.data.phoneNbr      = phoneNbr
        -- chessuserinfodb.WUserInfoUpdate(uid, userInfo)
        uniplatform.modifyaccountmobilenum(uid, phoneNbr, uid, msg.data.password)
        userInfo  = UserInfo.GetUserDataById(uid)
    --修改换手机认证
    elseif reqType == 2 then
        local curDayNo = chessutil.GetMorningDayNo()
        if userInfo.status.phoneEditDayNo ==  curDayNo then
            res.data.errno = ErrorDefine.CENTER_DUPLICATE_DAY
            res.data.desc  = "一天只能绑定一次"
            unilight.sendcmd(uid, res)
            return 
        end

        userInfo.status.phoneEditFlag = 1
        userInfo.status.phoneEditDayNo = curDayNo
    --重新绑定
    elseif reqType == 3 then
        --换手机
        if phoneNbr ~= userInfo.base.phoneNbr then
            if userInfo.status.phoneEditFlag == 0 then
                res.data.errno = ErrorDefine.CENTER_OLD_PHONE_NOT_VERIFY
                res.data.desc  = "旧手机没有验证"
                unilight.sendcmd(uid, res)
                return 
            end

            local allNum 	= unilight.startChain().Table("userinfo").Filter(unilight.eq("base.phoneNbr", phoneNbr)).Count()
            if allNum > 0 then
                res.data.errno = ErrorDefine.CENTER_DUPLICATE_BIND
                res.data.desc  = "重复绑定"
                unilight.sendcmd(uid, res)
                return 
            end

            --修改成功回来再修改
            -- userInfo.base.phoneNbr = phoneNbr
            -- userInfo.base.passwd   = msg.data.password
            userInfo.status.phoneEditFlag = 0
            res.data.phoneNbr      = phoneNbr
            uniplatform.modifyaccountmobilenum(uid, phoneNbr, uid, msg.data.password)
        --改密码
        else
            userInfo.base.passwd   = msg.data.password
            uniplatform.modifyaccountmobilenum(uid, "", uid, msg.data.password)
        end
    end

    --成功后删除手机验证信息
    unilight.redis_setexpire(phoneNbr, 1)
    unilight.sendcmd(uid, res)
    chessuserinfodb.WUserInfoUpdate(uid, userInfo)
end

-- 绑定账号
function BindPlataccount(uid, msg)
    local res = {}
	res["do"] = "Cmd.ModifyPlataccountPersonCenterCmd_S"
    res.data = {
        errno 	= ErrorDefine.SUCCESS,
        desc 	= "成功", 
    }
	if msg.data == nil or msg.data.plataccount == nil then
		res.data.errno = ErrorDefine.ERROR_PARAM
        res.data.desc  = "参数有误"
        unilight.sendcmd(uid, res)
		return
    end
    local userInfo = unilight.getdata("userinfo", uid)
    if string.len(userInfo.base.plataccount) > 0 then
        res.data.errno = ErrorDefine.CENTER_DUPLICATE_BIND
        res.data.desc  = "重复绑定"
        unilight.sendcmd(uid, res)
        return 
    end
    local allNum 	= unilight.startChain().Table("userinfo").Filter(unilight.eq("base.plataccount",msg.data.plataccount )).Count()
    if allNum > 0 then
        res.data.errno = ErrorDefine.CENTER_DUPLICATE_BIND
        res.data.desc  = "重复绑定"
        unilight.sendcmd(uid, res)
        return
    end
    local loginType = msg.data.loginType or 2
    uniplatform.modifyaccountplataccount(uid, msg.data.plataccount, msg.data.password,loginType)
    userInfo.base.plataccount = msg.data.plataccount
    res.data.plataccount = userInfo.base.plataccount
    unilight.savedata('userinfo',userInfo)
    -- 发送消息
    unilight.sendcmd(uid, res)
end

--发送手机验证码
function SendPhoneVerifyNumber(uid, msg)
	local res = {}
	res["do"] = "Cmd.SendPhoneVerifyNumberPersonCenterCmd_S"

    res.data = {
        errno 	= ErrorDefine.SUCCESS,
        desc 	= "成功", 
    }

	if msg.data == nil or msg.data.phoneNbr == nil or type(msg.data.phoneNbr) ~= "string" then
		res.data.errno	= ErrorDefine.ERROR_PARAM
		res.data.desc	= "参数有误"
        unilight.sendcmd(uid, res)
		return 
    end

    local phoneNbr =  msg.data.phoneNbr
    --判断下重复问题
    -- local  verifyNbr = unilight.redis_getdata(phoneNbr)
    -- if verifyNbr ~= nil and string.len(verifyNbr) > 0 then
        -- res.data.errno	= ErrorDefine.ERROR_FREQUENTLY_VERIFY
        -- res.data.desc	= "获取验证码太频繁"
        -- unilight.sendcmd(uid, res)
        -- return
    -- end
    local curDayNo = chessutil.GetMorningDayNo()
    local phoneData = UserPhoneNbrDatas[phoneNbr] or {lastDayNo = chessutil.GetMorningDayNo(), curNum = 1}
    if phoneData.lastDayNo ~= curDayNo then
        phoneData.lastDayNo = curDayNo
        phoneData.curNum = 1
    end

    unilight.info(string.format("玩家:%d,发送短信次数:%d", uid, phoneData.curNum))
    if phoneData.curNum > SMS_MAX_NUM then
        res.data.errno	= ErrorDefine.CENTER_PHONE_SMS_MAX
        res.data.desc	= "验证码次数达到上限"
        unilight.sendcmd(uid, res)
        return
    end

    phoneData.curNum = phoneData.curNum + 1
    UserPhoneNbrDatas[phoneNbr] = phoneData

    --固定手验证码，方便测试,后续接入sdk再随机
    -- local verifyNbr = "1111"
    local verifyNbr = tostring(math.random(100000, 999999))
    unilight.redis_setdata(phoneNbr, verifyNbr)
    unilight.redis_setexpire(phoneNbr, 60 * 10)

    local realVerifyNbr = unilight.redis_getdata(phoneNbr)
    unilight.info(string.format("手机:%s, 生成验证码:%s,%s",phoneNbr,verifyNbr, realVerifyNbr))
    res.data.randcode = verifyNbr
    local url = string.format(table_parameter_formula[1002].Formula, verifyNbr, phoneNbr)
    unilight.HttpRequestGet("Echo", url)

    unilight.sendcmd(uid, res)
end


--留言反馈
function Feedback(uid, msg)
	local res = {}
	res["do"] = "Cmd.FeedbackPersonCenterCmd_S"

    res.data = {
        errno 	= ErrorDefine.SUCCESS,
        desc 	= "成功", 
    }

	if msg.data == nil or msg.data.content == nil then
		res.data.errno	= ErrorDefine.ERROR_PARAM
		res.data.desc	= "参数有误"
        unilight.sendcmd(uid, res)
		return 
    end
    local content = msg.data.content

    local userInfo = chessuserinfodb.RUserInfoGet(uid)

    local feedbackInfo = {
        gameid     = unilight.getgameid(),
        zoneid     = unilight.getzoneid(),
        charid	   = uid, 
        charname   = userInfo.base.nickname,
        userlevel  = userInfo.property.level,
        viplevel   = userInfo.property.vipLevel, 
        subject    = content,
        content    = content, 
        recordtime = os.time(),     
        -- recordid   = 0,  -- 返回给Gmtools时使用
        state	   = 1,  -- 状态，1未处理，2已处理, 3忽略
        -- reply	   = 0,  -- GM回复
        -- phonenum   = 0,  -- 手机号
    }
    local sendstr = json.encode(feedbackInfo) 
    local ret = go.buildProtoFwdServer("*Smd.FeedbackGmUserPmd_CS", sendstr, "GMS")
    unilight.info(string.format("玩家:%d, 留言反馈:%s", uid, content))
    unilight.sendcmd(uid, res)
end
