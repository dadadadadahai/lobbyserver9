uniplatform = uniplatform or {}

local table_parameter_parameter= require "table/table_parameter_parameter"
local BIND_CHIPS = table_parameter_parameter[10].Parameter        --绑定手机奖励

-- 请求修改帐户推广者
uniplatform.modifyaccountparent = function(uid, parent, accoutuid, oldpassowrd)
    local send = {
        accid = uid,
        parent = parent,
        accountid = accountid,
        oldpassword = oldpassowrd,
    } 
    local sendstr = json.encode(send) 
    local ret = go.buildProtoFwdServer("*Smd.RequestModifyAccountInfoLoginSmd_CS", sendstr, "LS")
    unilight.info("modify account parent request ok " .. uid .. "  " .. parent)
    return ret 
end
-- 请求修改账户注册登录密码
uniplatform.modifyaccountpassword= function(uid, password, accountid, oldpassowrd)
    local send = {
        accid = uid,
        password = password, 
        accountid = accountid,
        oldpassword = oldpassowrd,
    } 
    local sendstr = json.encode(send) 
    local ret = go.buildProtoFwdServer("*Smd.RequestModifyAccountInfoLoginSmd_CS", sendstr, "LS")
    unilight.info("modify account password request ok " .. uid .. "  " .. password)
    return ret 
end
-- 请求修改玩家手机号
uniplatform.modifyaccountmobilenum = function(uid, mobilenum, accountid, password)
    local send = {
        accid = uid,
        mobilenum = mobilenum, 
        accountid = accountid,
        password = password,
    } 
    local sendstr = json.encode(send) 
    local ret = go.buildProtoFwdServer("*Smd.RequestModifyAccountInfoLoginSmd_CS", sendstr, "LS")
    unilight.info("modify account mobilenum request ok " .. uid .. "  " .. mobilenum)
    return ret
end
-- 请求修改玩家账号
uniplatform.modifyaccountplataccount = function(uid, plataccount, password,loginType)
    local send = {
        accid = uid,
        -- desc = plataccount..'|'..loginType,
        desc = plataccount,
        password = password
    }
    local sendstr = json.encode(send) 
    local ret = go.buildProtoFwdServer("*Smd.RequestModifyAccountInfoLoginSmd_CS", sendstr, "LS")
    -- 如果绑定成功发送奖励
    if ret then
        --赠送金币
        local addScore = (import "table/table_parameter_parameter")[34].Parameter
        chessuserinfodb.WPresentChange(uid, Const.PACK_OP_TYPE.ADD, addScore, "绑定账号")
        --增加金额
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, addScore, Const.GOODS_SOURCE_TYPE.BINDACCOUNT)
    end
    -- unilight.info("modify account plataccount request ok " .. uid .. "  " .. plataccount)
    return ret
end
LoginClientTask = LoginClientTask or {}
-- 请求平台帐号中剩余点数返回
LoginClientTask.RequestModifyAccountInfoLoginSmd_CS= function(task, cmd)
	local uid = cmd.GetAccid()
	local accoutid = cmd.GetAccountid()
	local retcode = cmd.GetRetcode()
    local desc = cmd.GetDesc()

    local res = {}
    res["do"] = "Do.XXXXXXX"
    res["data"] = {
        returncode = retcode,
        desc = desc,
    }
    --绑定手机奖励
    local mobilenum = cmd.GetMobilenum()
    if mobilenum ~= "" then
        local userInfo = chessuserinfodb.RUserInfoGet(uid)
        if  userInfo.base.phoneNbr == ""  then
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, BIND_CHIPS, Const.GOODS_SOURCE_TYPE.BIND_PHONE)
            chessuserinfodb.WPresentChange(uid, Const.PACK_OP_TYPE.ADD, BIND_CHIPS, "绑定赠送金币")
        end
        local userInfo  = chessuserinfodb.RUserInfoGet(uid)
        userInfo.base.phoneNbr = mobilenum
        -- userInfo.base.passwd   = msg.data.password
        chessuserinfodb.SaveUserData(userInfo)
    end
end

--苹果推送业务
--demo
--[[
local title = "苹果推送title"
    local msg = "苹果推送mssage"
    local pushtime = os.time()
    local data = {}
    local user = {
        accid = 10086,
        charid = 10086,
        imei = "testimei",
        osname = "zwl",
    }
    table.insert(data, user)
    local ret = uniplatform.requestpushiosmessage(title, msg, pushtime, data)
    if ret == true then
        unilight.info("send ios push ok")
    else
        unilight.error("send ios push error")
    end
--]]
--
uniplatform.requestpushiosmessage = function(title, msg, pushtime, data)
    local send = {
        title = title,
        desc = msg,
        timestamp = pushtime,
        data = data
    }
    local sendstr = json.encode(send) 
    return go.buildProtoFwdServer("*Pmd.GameRequestPushMessageUserListGmUserPmd_C", sendstr, "GMS")
end

-- 请求二维码接口
uniplatform.requestqrcodeurl = function(uid, platid, roleid, extdata)
    local send = {
        data = {myaccid = uid, platid=platid,},
        roleid = roleid,
        extdata = extdata,
    }
    local sendstr = json.encode(send) 
    return go.buildProtoFwdServer("*Pmd.RequestQrcodeURLSdkPmd_CS", sendstr, "LS")
end

-- 发短信接口
uniplatform.requestsendmobilemessage = function(uid, platid, mobilenum, message)
    local send = {
        data = {myaccid = uid, platid=platid,},
        mobilenum = mobilenum,
        randcode = message,
    }
    local sendstr = json.encode(send) 
    return go.buildProtoFwdServer("*Pmd.RequestMobileRegistRandCodeSdkPmd_CS", sendstr, "LS")
end

uniplatform.requestsenderrornotice= function(mobilenum, message)
    local send = {
        data = {myaccid = 999000, platid=100000,},
        mobilenum = mobilenum,
        randcode = message,
    }
    local sendstr = json.encode(send) 
    return go.buildProtoFwdServer("*Pmd.RequestMobileRegistRandCodeSdkPmd_CS", sendstr, "LS")
end
