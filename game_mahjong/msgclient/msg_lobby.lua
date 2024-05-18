-- 用户信息获取
Net.CmdUserInfoGetLbyCmd_C = function(cmd, laccount)
	----
	local res = {}
	res["do"] = "Cmd.UserInfoGetLbyCmd_S"
	local uid = cmd.data.uid or laccount.Id 
	local userInfo = UserInfo.GetUserInfoById(uid) 
    if userInfo == nil then
        res["data"] = {
            resultCode = 1,
            desc = "玩家不存在" 
        }
        return res
    end
    local userBaseInfo = UserInfo.GetUserDataBaseInfo(userInfo)
	retData.uid = uid
	res["data"] = {
		userinfo = userBaseInfo, 
	}
	return res
end
