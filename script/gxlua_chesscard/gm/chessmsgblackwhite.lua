-- 黑白名单相关gm

-- 添加黑白名单
GmSvr.PmdAddBlackWhitelistGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	if cmd.data == nil or cmd.data.data == nil then
		unilight.error("添加黑白名单 数据 有误")
		res.data.retcode = 1
		res.data.retdesc = "添加黑白名单 数据 有误"
		return res
	end

	-- 添加黑白名单(data repeated)
	local ret, desc, data = BlackWhiteMgr.AddBlackWhiteList(cmd.data.data)

	res.data.retcode 	= ret
	res.data.retdesc	= desc
	res.data.data 		= data
	return res
end

-- 修改黑白名单
GmSvr.PmdModBlackWhitelistGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	if cmd.data == nil or cmd.data.data == nil or cmd.data.data.charid == nil then
		unilight.error("修改黑白名单 数据 有误")
		res.data.retcode = 1
		res.data.retdesc = "修改黑白名单 数据 有误"
		return res
	end

	-- 修改黑白名单
	local ret, desc = BlackWhiteMgr.ModBlackWhiteList(cmd.data.data)

	res.data.retcode = ret
	res.data.retdesc = desc
	return res
end

-- 删除黑白名单
GmSvr.PmdDelBlackWhitelistGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	if cmd.data == nil or cmd.data.ids == nil then
		unilight.error("删除黑白名单 数据 有误")
		res.data.retcode = 1
		res.data.retdesc = "删除黑白名单 数据 有误"
		return res
	end

	-- 删除黑白名单
	local ret, desc = BlackWhiteMgr.DelBlackWhiteList(cmd.data.ids)

	res.data.retcode = ret
	res.data.retdesc = desc
	return res
end

-- 查询黑白名单
GmSvr.PmdRequestBlackWhitelistGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	if cmd.data == nil then
		unilight.error("查询黑白名单 数据 有误")
		res.data.retcode = 1
		res.data.retdesc = "查询黑白名单 数据 有误"
		return res
	end

	-- 查询黑白名单
	local data = BlackWhiteMgr.ReqBlackWhiteList(cmd.data)

	res.data = data
	return res
end
