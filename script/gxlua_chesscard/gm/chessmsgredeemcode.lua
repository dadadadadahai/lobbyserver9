-- 兑换码相关gm请求

-- 生成兑换码/查询兑换码发放条件
GmSvr.PmdRequestRedemptioncodePmd_C = function(cmd, laccount)
	if cmd.data == nil then
		unilight.error("请求兑换码生成 有误")
		return cmd
	end

    local usernum = 0
    if cmd.data.optype == 1 then
        cmd.data.childnum = cmd.data.childnum or 0
        cmd.data.actchildnum = cmd.data.actchildnum or 0
        local userList = unilight.chainResponseSequence(unilight.startChain().Table("rebateItem").Aggregate('{"$match":{"lev":{"$eq":1}}}','{"$group":{"_id":"$uid", "sum":{"$sum":1}}}','{"$match":{"sum": {"$gte":'..cmd.data.childnum..'}}}'))
        if cmd.data.actchildnum > 0 then
            for _, value in ipairs(userList) do
                local actNum = unilight.startChain().Table("rebateItem").Filter(unilight.a(unilight.eq('uid',value._id),unilight.eq('lev',1),unilight.gt('tchip',0))).Count()
                if actNum >= cmd.data.actchildnum then
                    usernum = usernum + 1
                end
            end
        else
            usernum = #userList
        end
    elseif cmd.data.optype == 2 then
        -- 转换时间戳
        cmd.data.expiretime = chessutil.TimeByDateGet(cmd.data.expiretime)
        RedeemCode.AddRedeemCode(cmd.data)
    end
    local res = {
        data = {
            retcode = 0,
            retdesc = "生成成功",
            usernum = usernum,
        },
    }
	return res
end

-- 请求兑换码详情
GmSvr.PmdRequestRedemptioncodeListPmd_C = function(cmd, laccount)
	if cmd.data == nil then
		unilight.error("请求兑换码生成 有误")
		return cmd
	end
    local filter = unilight.neq('_id',"")
    if cmd.data.batch ~= nil and cmd.data.batch ~= '' then
        filter = unilight.a(filter,unilight.eq("batch", cmd.data.batch))
    end
    if cmd.data.code ~= nil and cmd.data.code ~= '' then
        filter = unilight.a(filter,unilight.eq("_id", cmd.data.code))
    end
    local order = unilight.desc("initTime")
    local redeemcodeInfos = unilight.chainResponseSequence(unilight.startChain().Table(RedeemCode.DB_Name).Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
    local infoNum = unilight.startChain().Table(RedeemCode.DB_Name).Filter(filter).Count()
    local maxpage = math.ceil(infoNum/cmd.data.perpage)
    local res = {
        data = {
            batch = cmd.data.batch,
            code = cmd.data.code,
            maxpage = maxpage,
            perpage = cmd.data.perpage,
            curpage = cmd.data.curpage,
            data = {},
        }
    }
    for _, codeinfo in ipairs(redeemcodeInfos) do
        table.insert(res.data.data,{
            batch = codeinfo.batch,
            code = codeinfo._id,
            gold = codeinfo.gold,
            usednum = codeinfo.totalTime - codeinfo.lackTime,
            residuenum = codeinfo.lackTime,
            initTime = chessutil.FormatDateGet(codeinfo.initTime),
            expiretime = chessutil.FormatDateGet(codeinfo.expiretime),
        })
    end
	return res
end

-- 请求兑换码玩家兑换详情
GmSvr.PmdRequestRedemptioncodeUsedPmd_C = function(cmd, laccount)
	if cmd.data == nil then
		unilight.error("请求兑换码玩家兑换记录页面 有误")
		return cmd
	end
    local filter = unilight.gt('uid',0)
    if cmd.data.charid ~= nil and cmd.data.charid ~= 0 then
        filter = unilight.a(filter,unilight.eq("uid", cmd.data.charid))
    end
    if cmd.data.code ~= nil and cmd.data.code ~= '' then
        filter = unilight.a(filter,unilight.eq("redeemcodeInfo._id", cmd.data.code))
    end
    local order = unilight.desc("getTime")
    local redeemcodeInfos = unilight.chainResponseSequence(unilight.startChain().Table(RedeemCode.DB_Log_Name).Filter(filter).OrderBy(order).Skip((cmd.data.curpage-1)*cmd.data.perpage).Limit(cmd.data.perpage))
    local infoNum = unilight.startChain().Table(RedeemCode.DB_Log_Name).Filter(filter).Count()
    local maxpage = math.ceil(infoNum/cmd.data.perpage)
    local res = {
        data = {
            batch = cmd.data.batch,
            code = cmd.data.code,
            maxpage = maxpage,
            perpage = cmd.data.perpage,
            curpage = cmd.data.curpage,
            codenum = infoNum,
            data = {},
        }
    }
    for _, codeinfo in ipairs(redeemcodeInfos) do
        print("=============")
        print(table2json(codeinfo.redeemcodeInfo))
        table.insert(res.data.data,{
            charid = codeinfo.uid,
            code = codeinfo.redeemcodeInfo._id,
            gold = codeinfo.redeemcodeInfo.gold,
            date = chessutil.FormatDateGet(codeinfo.getTime),
        })
    end
	return res
end