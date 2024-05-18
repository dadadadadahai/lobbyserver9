-- 手机号码相关gm请求

-- 添加手机号码
GmSvr.PmdStPhonenumUploadPmd_C = function(cmd, laccount)
	if cmd.data == nil then
		unilight.error("插入手机号码 有误")
		return cmd
	end
	if table.empty(cmd.data.data) then
		unilight.error("插入手机号码 有误")
		return cmd
	end
    -- 插入手机号
    unilight.savebatch(InviteRoulette.DB_PhoneNumber_Name,cmd.data.data)
    local res = {
        data = {
            retcode = 0,
            retdesc = "生成成功",
        },
    }
	return res
end