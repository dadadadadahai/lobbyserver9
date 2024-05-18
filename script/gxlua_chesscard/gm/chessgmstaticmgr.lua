module("ChessGmStaticMgr", package.seeall)

BjlLtyType 	= {"相", "将", "和", "相对", "将对"}
EbgLtyType 	= {"顺", "天", "地"} 
SupLtyType 	= {"燕子", "鸽子", "孔雀", "老鹰", "狮子", "熊猫", "猴子", "兔子", "飞禽", "走兽", "银鲨", "金鲨"}
HbfLtyType 	= {"天", "地" ,"玄", "黄", "庄"}
BullTypes  	= {"牛一", "牛二", "牛三", "牛四", "牛五", "牛六", "牛七", "牛八", "牛九", "牛牛", "炸弹牛", "五花牛", "五小牛", "没牛"}
CarTypes 	= {"大保时捷", "小保时捷", "大宝马", "小宝马", "大奥迪", "小奥迪", "大大众", "小大众"}

-- 获取投注详情
function GetDetail(gameId, detail)
	local betdetail 	= ""
	local lotterydetail = ""

	local betInfo 		= detail.betInfo
	local lotteryInfo 	= detail.lotteryInfo

	-- 百家乐
	if gameId == 152 or gameId == 174 then
		for i=1,5 do
			if betInfo[i] ~= nil and betInfo[i] ~= 0 then
				betdetail = betdetail .. BjlLtyType[i] .. ":" .. betInfo[i] .. " "
			end
		end
		for i,v in ipairs(lotteryInfo) do
			lotterydetail = lotterydetail .. BjlLtyType[v] .. " "
		end
	-- 28杠
	elseif gameId == 157 or gameId == 173 then
		for i=1,3 do
			if betInfo[i] ~= nil and betInfo[i] ~= 0 then
				betdetail = betdetail .. EbgLtyType[i] .. ":" .. betInfo[i] .. " "
			end
		end

		-- 28gang改为有倍数后 存入数据增多了 兼容以前老数据
		if lotteryInfo.mults ~= nil then
			-- 新数据 
			local pos 		= {"banker", "shun", "tian", "di"}
			local posStr 	= {"庄", "顺", "天", "地"}
			local types 	= {"点数", "二八", "彩二八", "豹子"}
			local points 	= {"零点", "一点", "二点", "三点", "四点", "五点", "六点", "七点", "八点", "九点"}		
			lotterydetail = " | "
			for i,v in ipairs(pos) do
				local poker = lotteryInfo[v]

				local winMap = {}
				for i,v in ipairs(lotteryInfo.lotteryInfos) do
					winMap[v] = true
				end

				local isWin = " "
				if i > 1 then
					if winMap[i-1] == true then
						isWin = "赢"
					else
						isWin = "输"
					end
				end

				local typer = nil
				if poker.typer == 1 then
					typer = points[(poker.infos[1]+poker.infos[2])%10+1]
				else
					typer = types[poker.typer]
				end


				local perDetail = string.format(posStr[i] .. ":%s,%s-%s %s", poker.infos[1], poker.infos[2], typer, isWin)	
				
				if i > 1 then 
					perDetail = perDetail .. lotteryInfo.mults[i-1] .. "倍" 
				end
				
				lotterydetail = lotterydetail .. perDetail .. " | "	
			end
		else
			-- 老数据
			for i,v in ipairs(lotteryInfo) do
				lotterydetail = lotterydetail .. EbgLtyType[v] .. " "
			end
		end


	-- 飞禽走兽
	elseif gameId == 1000 then
		for i=1,12 do
			if betInfo[i] ~= nil and betInfo[i] ~= 0 then
				betdetail = betdetail .. SupLtyType[i] .. ":" .. betInfo[i] .. " "
			end
		end
		for i,v in ipairs(lotteryInfo) do
			lotterydetail = lotterydetail .. SupLtyType[v.id] .. "-倍率:" .. v.multiple .. " "
		end
	-- 百人牛牛
	elseif gameId == 167 then
		for i=1,4 do
			if betInfo[i] ~= nil and betInfo[i] ~= 0 then
				betdetail = betdetail .. HbfLtyType[i] .. ":" .. betInfo[i] .. " "
			end
		end

		-- 开奖明细 整合 位置:天-牌型:牛牛-赢
		for i,v in ipairs(lotteryInfo) do
			-- 当前输赢
			local isWin = "输"
			if v.isWin then
				isWin = "赢"
			end

			-- 当前牛型
			local type = v.type
			if type == 0 then
				type = 14
			end

			if i ~= 5 then
				lotterydetail = lotterydetail .. HbfLtyType[i] .. "-" .. BullTypes[type] .. "-" .. isWin .. "  "
			else
				lotterydetail = lotterydetail .. HbfLtyType[i] .. "-" .. BullTypes[type]
			end
		end		
	
	-- 车行争霸
	elseif gameId == 178 then
		for i=1,8 do
			if betInfo[i] ~= nil and betInfo[i] ~= 0 then
				betdetail = betdetail .. CarTypes[i] .. ":" .. betInfo[i] .. " "
			end
		end
		lotterydetail = lotterydetail .. CarTypes[lotteryInfo.id] .. "-倍率:" .. lotteryInfo.multiple
	end

	return betdetail, lotterydetail
end

-- 红包已领取数据修复（被领取时间老数据是记录date string类型 添加一个记录时间戳的变量 用于数据筛选）
function RepairRedPacketsData()
	-- 已被领取过的红包
	local filter = unilight.a(unilight.eq("bok", 1), unilight.neq("receivedate", ""))
	local info = unilight.chainResponseSequence(unilight.startChain().Table("lobbyExchange").Filter(filter))
	local nbr  = 0
	for i,v in ipairs(info) do
		if v.receivetime == nil or v.receivetime == 0 then 
			local receiveTime = chessutil.TimeByDateGet(v.receivedate)
			v.receivetime = receiveTime
			unilight.savedata("lobbyExchange", v)
			nbr = nbr + 1
		end
	end	
	unilight.info("修复红包数据 %v 个", nbr)
end

-- 上下分异常报警 暂时先存至数据库中 后续需要再取用
-- 暂时定为 三十天内 下分是上分的两倍或以上 则 报警
-- 每天定时 半夜3点检测
function UpDownChipsWarn()
	-- 老的警告数据清除
	unilight.cleardb("updownchipswarn")

	-- 已领
	local filter = unilight.a(unilight.eq("bok", 1), unilight.neq("receivedate", ""))
	-- 三十天内
	filter = unilight.a(filter, unilight.ge("receivetime", os.time()-30*24*3600), unilight.le("receivetime", os.time()))
	-- 获取符合条件的所有转账记录
	local info = unilight.chainResponseSequence(unilight.startChain().Table("lobbyExchange").Filter(filter))	

	-- 汇总当前上下分信息
	local upDownInfos = {}
	for i,v in ipairs(info) do
		-- 自己发给自己的 不计入在内
		if v.dstuid ~= v.srcuid then
			-- 上分的玩家信息
			local upInfo 	= upDownInfos[v.dstuid] or {
				nickname 	= v.dstnickname,
				upChips 	= 0,
				downChips 	= 0,
			}
			upInfo.upChips = upInfo.upChips + v.chips


			-- 下分的玩家信息
			local downInfo 	= upDownInfos[v.srcuid] or {
				nickname 	= v.srcnickname,
				upChips 	= 0,
				downChips 	= 0,
			}
			downInfo.downChips = downInfo.downChips + v.chips

			-- 赋值
			upDownInfos[v.dstuid] = upInfo
			upDownInfos[v.srcuid] = downInfo
		end
	end

	-- 检测每一个上下分玩家 是否异常
	for uid,upDownInfo in pairs(upDownInfos) do
		local unusual = false

		-- 如果上分小于100w的玩家 下分超过200w 则表示异常
		if upDownInfo.upChips <= 1000000 then
			if upDownInfo.downChips >= 2000000 then
				unusual = true
			end
		else
			-- 如果上分大于100w的玩家 则下分超过上分的两倍 则表示异常
			if upDownInfo.downChips >= upDownInfo.upChips * 2 then
				unusual = true
			end
		end

		-- 如果异常 则存入数据库中
		if unusual then
			local warnInfo = {
				uid 		= uid,
				nickname 	= upDownInfo.nickname,
				upchips 	= upDownInfo.upChips,
				downchips 	= upDownInfo.downChips,
			}
			unilight.savedata("updownchipswarn", warnInfo)
		end
	end
end