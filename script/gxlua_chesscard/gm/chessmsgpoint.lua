-- 积分兑入兑出相关gm

-- 请求兑换积分报表
GmSvr.PmdRequestPointReportGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	-- 时间段 必须要有 玩家id 存在 则寻找单一玩家数据  不存在则 查找所有数据
	if cmd.data == nil then
		unilight.error("请求兑换积分报表 有误")
		return res
	end
	local gameId 	= cmd.data.gameid
	local uid 		= cmd.data.charid 
	local starttime = cmd.data.starttime
	local endtime 	= cmd.data.endtime
	local curpage 	= cmd.data.curpage
	local perpage 	= cmd.data.perpage

	if curpage == 0 then
		curpage = 1
	end

	if endtime == 0 then
		endtime = os.time()
	end

	local filter1 = unilight.o(unilight.eq("flag", "带入金币成功"), unilight.eq("flag", "兑换出去成功"))
	local filter2 = unilight.a(unilight.gt("timestamp", starttime), unilight.lt("timestamp", endtime))
	local filter  = nil 

	-- 获取时间段内的 所有兑换积分报表数据
	if uid == 0 then
		filter = unilight.a(filter1, filter2)
	-- 获取时间段内的 指定玩家兑换积分报表数据
	else
		filter = unilight.a(filter1, filter2, unilight.eq("uid", uid))
	end

	-- 计算总页数
	local infoNum 	= unilight.startChain().Table("gameorder").Filter(filter).Count()
	local info 		= unilight.chainResponseSequence(unilight.startChain().Table("gameorder").Filter(filter).Skip((curpage-1)*perpage).Limit(perpage))
	local maxpage	= math.ceil(infoNum/perpage)

	-- 返回的数据组装
	local PointReports = {}
	for i,v in ipairs(info) do
		local PointReport = {
			recorddate 	= v.timestamp,				-- 日期
			redeemin 	= nil, 						-- 兑入积分
			redeemout 	= nil,						-- 兑出积分
			redeemtotal = v.remainder,				-- 盈亏积分(也就是玩家带入带出后的筹码)		暂无 后续补充  
		}	
		if v.flag == "带入金币成功" then
			PointReport.redeemin 	= v.rmb*100
			PointReport.redeemout 	= 0
		else
			PointReport.redeemin 	= 0
			PointReport.redeemout 	= v.rmb*100
		end
		table.insert(PointReports, PointReport)
	end
	
	res.data.maxpage = maxpage 
	res.data.data 	 = PointReports
	
	unilight.info("请求兑换积分报表 成功")
	return res
end

-- 请求积分兑换明细，需要逻辑服自行处理查询，monitor没有带入带出前的积分详情
GmSvr.PmdRequestPointDetailGmUserPmd_CS = function(cmd, laccount)
	res = cmd

	-- 时间段 必须要有 玩家id 存在 则寻找单一玩家数据  不存在则 查找所有数据
	if cmd.data == nil then
		unilight.error("请求积分兑换明细 有误")
		return res
	end
	local gameId 	= cmd.data.gameid
	local uid 		= cmd.data.charid 
	local ptype 	= cmd.data.ptype 
	local starttime = cmd.data.starttime
	local endtime 	= cmd.data.endtime
	local curpage 	= cmd.data.curpage
	local perpage 	= cmd.data.perpage

	if endtime == 0 then
		endtime = os.time()
	end

	if curpage == 0 then
		curpage = 1
	end

	local filter1 = nil
	if ptype == nil then
		filter1 = unilight.o(unilight.eq("flag", "带入金币成功"), unilight.eq("flag", "兑换出去成功"))
	elseif ptype == 2 then 
		filter1 = unilight.eq("flag", "带入金币成功")
	else
		filter1 = unilight.eq("flag", "兑换出去成功")
	end
	local filter2 = unilight.a(unilight.gt("timestamp", starttime), unilight.lt("timestamp", endtime))
	local filter  = nil 

	-- 获取时间段内的 所有兑换积分报表数据
	if uid == 0 then
		filter = unilight.a(filter1, filter2)
	-- 获取时间段内的 指定玩家兑换积分报表数据
	else
		filter = unilight.a(filter1, filter2, unilight.eq("uid", uid))
	end

	-- 计算总页数
	local infoNum 	= unilight.startChain().Table("gameorder").Filter(filter).Count()
	local info 		= unilight.chainResponseSequence(unilight.startChain().Table("gameorder").Filter(filter).Skip((curpage-1)*perpage).Limit(perpage))
	local maxpage	= math.ceil(infoNum/perpage)

	-- 返回的数据组装
	local PointDetails = {}
	for i,v in ipairs(info) do
		local PointDetail = {
			id 			= i ,	
			recordtime 	= v.timestamp,						-- 日期
			charid 		= v.uid, 							-- 角色Id					
			charname 	= v.nickname or "老数据无名字",		-- 角色名称					暂无
			ptype 		= nil,								-- 积分类型，2兑入，3兑出
			redeemnum 	= v.rmb*100,						-- 兑换数额
			originnum 	= nil,								-- 兑换前数额				无（可通过 currentnum与redeemnum得出）
			currentnum 	= v.remainder,						-- 兑换后数额				暂无
		}	
		if v.flag == "带入金币成功" then
			PointDetail.ptype 	= 2
			if PointDetail.currentnum ~= nil then 
				PointDetail.originnum = PointDetail.currentnum - PointDetail.redeemnum
			end
		else
			PointDetail.ptype 	= 3
			if PointDetail.currentnum ~= nil then 
				PointDetail.originnum = PointDetail.currentnum + PointDetail.redeemnum
			end
		end		
		
		table.insert(PointDetails, PointDetail)
	end
	
	res.data.maxpage = maxpage
	res.data.data 	 = PointDetails
	
	unilight.info("请求积分兑换明细 成功")
	return res
end
