
-- 查看提取码
GmSvr.PmdRedpackCodeSearchGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	if cmd.data == nil or cmd.data.code == nil then
		unilight.error("查看兑换码有误")
        res.retcode = 1
        res.retdesc = "参数有误"
		return res
	end

    local info = OpenRedPack.RecordGetByRedPackCode(cmd.data.code)
    if info == nil then
        res.retcode = 2
        res.retdesc = "不存在该兑换码"
		return res
    end
    local rdata = {
        code     = info.drawredpackcode,
        chardid  = info.uid,
        charname = info.nickname,
        money    = info.reward,
        state    = info.status - 1,
        created  = info.time,
    }
    res.data.rdata = {rdata}
	unilight.info("查看兑换码成功")
	return res
end

-- 使用提取码
GmSvr.PmdRedPackCodeOperateGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	if cmd.data == nil or cmd.data.code == nil then
		unilight.error("使用兑换码有误")
        res.retcode = 1
        res.retdesc = "参数有误"
		return res
	end

    local info = OpenRedPack.RecordGetByRedPackCode(cmd.data.code)
    if info == nil then
        res.retcode = 2
        res.retdesc = "不存在该兑换码"
		return res
    end
    if info.status ~= 1 then
        res.retcode = 3
        res.retdesc = "该兑换码已使用过"
		return res
    end
    info.status = 2
	unilight.savedata("drawredpackinfo", info)
    res.data.state = info.status -1
    res.data.retcode= 0
	unilight.info("使用兑换码 成功")

    -- 具体统计数据发送给monitor
    OpenRedPack.SendRedPackInfoToMonitor(info, cmd.data.gmid)

	return res
end
