module("ProtectMgr", package.seeall)

--[[
	lbx-2016.9.7
	文件内容修改：
		保护信息 不再作为一个独立的功能 去控制
		而是去检测玩家在游戏中是否 输超过一定限额或赢超过一定限额 
		如果超过限额 则 自动给其添加黑白名单
		并不是单独的保护玩家不输太多钱 同时也限制玩家不能赢太多钱（稍微限制 如果玩家大量赢钱 还需手动设置黑白名单）

	TODO：
		后期兼容 保护金额、返点比例 可配表
]]

-- users 为本局有投注的玩家id

PROTECT_TIME	= 12*3600			-- 保护时间12小时
PROTECT_CHIP 	= 10000000			-- 保护金额默认值1000w
PROTECT_RETN 	= 0.3				-- 保护返点默认值30%

-- 保护类型（自动黑、自动白）
ENUM_PROTECT_TYPE = {
	WHITE = 1,	-- 白名单
	BLACK = 2,	-- 黑名单
}
MapProtectTyepString = {"自动白名单", "自动黑名单"}
-- 组装主键 
function GetProtectKey(gameId, uid)
	return tostring(gameId) .. "-" .. tostring(uid)
end

-- 新增保护信息（每次到这一步 表示 已经经过各种判断 可以正式添加保护 都生成最新保护信息 更新最新保护时间）
function CreateProtectInfo(gameId, uid, chips, type, protectRetn)
	local key = GetProtectKey(gameId, uid)	
	local protectInfo = {
		key 		= key,
		gameid 		= gameId,
		uid 		= uid,
		effective 	= true, 	-- 默认新增时 当前保护生效
		type 		= type, 	-- 自动黑名单 或 自动白名单
		chips 		= chips,	-- 多少金额触发的保护
		allchips 	= 0,		-- 总共需执行
		curchips	= 0,		-- 当前已经执行了的金额
		timestamp	= os.time()
	}
	local allChips 	= math.floor(chips*protectRetn)
	protectInfo.allchips = allChips
	unilight.savedata("protectinfo", protectInfo)
	unilight.info("新增保护信息成功 key: " .. key .. "	- " .. MapProtectTyepString[type])

	-- 获取唯一黑白名单id
	local id = BlackWhiteMgr.GetBlackWhiteId()

	-- 执行金额 
	local setChips 	= math.floor(allChips/30)

	-- 概率（暂时按照 默认50   1500w--2000w:55  2000w--3000w:60 3000w--->：65）
	local winRate 	= 50
	if allChips >15000000 and allChips<=20000000 then
		winRate = 55
	elseif allChips >20000000 and allChips<=30000000 then
		winRate = 60
	elseif allChips >30000000 then
		winRate = 65
	end			

	-- 新建黑白名单
	local data = {
		id 				= id,
		subgameid 		= gameId,
		charid 			= uid, 
		setchips 		= setChips,
		curchips 		= 0,
		winrate 		= winRate,
		state 			= 1,
		type 			= type,
		settimes 		= 20,
		curtimes 		= 1,
		intervaltimes 	= 3,
	}

	BlackWhiteMgr.AddBlackWhiteList({data}, true)

	return protectInfo
end	

-- 检测当前房间内的玩家 是否超过某一个阈值 需要自动添加黑白名单
function CheckProtect(gameId, users, bankerUid, protectChips, protectRetn)
	if users == nil and bankerUid == nil then
		return 
	end

	-- 如果没有传入 保护阈值、保护返点 则取默认值
	protectChips 	= protectChips 	or PROTECT_CHIP
	protectRetn 	= protectRetn 	or PROTECT_RETN

	local allUsers = {}
	if users ~= nil then
		allUsers = table.clone(users)
	end
	if bankerUid ~= nil then
		table.insert(allUsers, bankerUid)
	end

	-- 分别检测每个玩家
	for i,uid in ipairs(allUsers) do
		local key = GetProtectKey(gameId, uid)
		local protectInfo = unilight.getdata("protectinfo", key)
		-- 如果当前不在保护列表 才进行检测 是否要添加保护
		if protectInfo == nil or protectInfo.effective == false then
			-- 当前玩家 在这段时间内的收益
			local profit = 0

			-- 查看是否存在上次自动黑白名单  获取其执行时间
			local timeStamp = nil
			if protectInfo ~= nil then
				timeStamp = protectInfo.timestamp
			end

			-- 开始统计输赢记录的时间点
			local startTime = os.time() - PROTECT_TIME
			if timeStamp ~= nil then
				if timeStamp > startTime then
					startTime = timeStamp
				end
			end

			-- 如果开始时间 等于当前时间 则代表当前游戏局该玩家刚去除自动黑白名单 此时不需要检测该玩家是否添加自动黑白名单
			if startTime ~= os.time() then
				-- 先查看这段时间 坐庄输赢
				local bankerBetInfo = chessprofitbet.CmdGameBankerInfoGetByGameIdUidBetween(uid, gameId, startTime, os.time())
				for i,v in ipairs(bankerBetInfo) do
					profit = profit + (v.remainderbankerchips - v.carrybankerchips)
				end

				-- 再查看这段时间 投注输赢
				local betInfo = chessprofitbet.CmdGamePlayInfoGetByGameIdUidBetween(uid, gameId, startTime, os.time())
				for i,v in ipairs(betInfo) do
					profit = profit + v.profitchips
				end	

				-- 如果上次保护为PROTECT_TIME时间内 则上次自动黑白名单所产生的溢值 也需计算到当前收益中 
				if protectInfo ~= nil then
					if os.time() - protectInfo.timestamp < PROTECT_TIME then
						-- 如果是 因保护过度 而结束保护的  
						if protectInfo.curchips > protectInfo.allchips then
							local chips = protectInfo.curchips - protectInfo.allchips
							-- 白名单 保护过度 则玩家profit加上该值
							if protectInfo.type == ENUM_PROTECT_TYPE.WHITE then
								profit = profit + chips
							else
								profit = profit - chips
							end
						end
					end 
				end
				
				-- 如果收益大于0 则 检测 是否触发 自动黑名单
				if profit > 0 then
					if profit >= protectChips then
						-- 添加自动黑名单
						CreateProtectInfo(gameId, uid, profit, ENUM_PROTECT_TYPE.BLACK, protectRetn)
					end

				-- 如果收益小于0 则 检测 是否触发 自动白名单 
				else
					local loseChips = - profit 
					if loseChips > protectChips then
						-- 添加自动白名单
						CreateProtectInfo(gameId, uid, loseChips, ENUM_PROTECT_TYPE.WHITE, protectRetn)
					end
				end	
			end
		end
	end
end

-- 获取指定玩家本局输赢
function GetProfit(roundId, uid, isBanker)
	local profit 	= 0
	local filter 	= unilight.a(unilight.eq("roundid", roundId), unilight.eq("uid", uid))
	local info 		= unilight.chainResponseSequence(unilight.startChain().Table("userprofitbet").Filter(filter))

	if info ~= nil and info[1] ~= nil then
		if isBanker then
			profit = info[1].remainderbankerchips - info[1].carrybankerchips
		else
			profit = info[1].profitchips
		end
	else
		unilight.error("该玩家本局并没有投注：" .. uid)
	end
	return profit
end

-- 执行保护信息(由roundId 获取这局游戏各人的输赢情况)
function ExecuteProtectInfo(gameId, users, bankerUid, roundId)
	if users == nil and bankerUid == nil then
		return 
	end

	local allUsers = {}
	if users ~= nil then
		allUsers = table.clone(users)
	end
	if bankerUid ~= nil then
		table.insert(allUsers, bankerUid)
	end

	-- 分别检测每个玩家
	for i,uid in ipairs(allUsers) do
		local key = GetProtectKey(gameId, uid)
		local protectInfo = unilight.getdata("protectinfo", key)
		-- 保护列表存在该条信息
		if protectInfo ~= nil and protectInfo.effective == true then
			local req = {
				id 			= 0, -- 不使用id
				subgameid 	= gameId,
				charid 		= uid,
				charname 	= nil,
				curpage 	= 1,
				perpage 	= 15,
			}
			local blackWhiteData = BlackWhiteMgr.ReqBlackWhiteList(req)
			local blackWhiteInfo = blackWhiteData.data -- 回来的是个数组 里面的第一个就是我们查到的数据
			-- 当前玩家不存在自动黑白名单 则代表自动黑白名单 已被手动删除或修改或（已执行够20次但是还是没达到金额 也会被移除） 则直接认为保护信息已执行结束
			if blackWhiteInfo == nil or table.len(blackWhiteInfo) == 0 or blackWhiteInfo[1].isauto ~= true then
				protectInfo.effective = false
				protectInfo.timestamp = os.time()

				-- 数据更新
				unilight.savedata("protectinfo", protectInfo)

				unilight.info("当前自动黑白名单已被去除（手动或已结束） 保护信息是否生效 置为false:" .. uid)
			else
				-- 如果自动黑白名单存在 则 更新里面的信息
				local profit = 0
				if bankerUid ~= nil and uid == bankerUid then
					profit = GetProfit(roundId, uid, true)
				else
					profit = GetProfit(roundId, uid, false)
				end

				-- 当前为自动黑名单
				if protectInfo.type == ENUM_PROTECT_TYPE.BLACK then
					-- 检查该玩家 当前是否输钱了 如果输钱了 则认为当前在执行 
					if profit < 0 then
						protectInfo.curchips = protectInfo.curchips - profit
						if protectInfo.curchips >= protectInfo.allchips then
							-- 数据更新
							protectInfo.effective = false
							protectInfo.timestamp = os.time()
							unilight.savedata("protectinfo", protectInfo)
							unilight.info("该玩家自动黑名单结束：" .. uid)

							-- 删除自动黑名单
							BlackWhiteMgr.DelBlackWhiteList({blackWhiteInfo[1].id})
						else
							unilight.savedata("protectinfo", protectInfo)
							unilight.info("正常执行该玩家自动黑名单：" .. uid .. "已执行金额：" .. protectInfo.curchips .. " 总共需执行：" .. protectInfo.allchips)
						end						
					end
				else
					-- 检查该玩家 当前是否赢钱了 如果赢钱了 则认为当前在执行
					if profit > 0 then
						protectInfo.curchips = protectInfo.curchips + profit
						if protectInfo.curchips >= protectInfo.allchips then
							protectInfo.effective = false
							protectInfo.timestamp = os.time()
							unilight.savedata("protectinfo", protectInfo)
							unilight.info("该玩家自动白名单结束：" .. uid)
							
							-- 删除自动白名单
							BlackWhiteMgr.DelBlackWhiteList({blackWhiteInfo[1].id})
						else
							unilight.savedata("protectinfo", protectInfo)
							unilight.info("正常执行该玩家自动白名单：" .. uid .. "已执行金额：" .. protectInfo.curchips .. " 总共需执行：" .. protectInfo.allchips)
						end	
					end
				end
			end
		end
	end
end

-- 开奖后 更新保护信息
function UpdateProtectInfo(gameId, users, bankerUid, roundId, protectChips, protectRetn)
	unilight.info("------------------------------- 保护更新 -------------------------------")
	-- 检测 老的自动黑白名单数据更新
	ExecuteProtectInfo(gameId, users, bankerUid, roundId)
	-- 检测 是否有 新的保护信息
	CheckProtect(gameId, users, bankerUid, protectChips, protectRetn)
	unilight.info("------------------------------------------------------------------------")
end

