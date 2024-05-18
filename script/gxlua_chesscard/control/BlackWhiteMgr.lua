module("BlackWhiteMgr", package.seeall)

-- 初始化一个全局唯一的 黑白名单id
function InitBlackWhiteId()
	local info = {
		_id 			= 1,
		blackwhiteid 	= 10000,
	}
	unilight.savedata("blackwhiteid", info)
	return info 
end

-- 获取一个全局唯一的 黑白名单id
function GetBlackWhiteId()
	local info = unilight.getdata("blackwhiteid", 1)
	if info == nil then
		info = InitBlackWhiteId()
	end 
	info.blackwhiteid = info.blackwhiteid + 1
	unilight.savedata("blackwhiteid", info)
	return info.blackwhiteid
end

-- 通过gameId + uid 获取黑白名单数据 (并过滤掉错误信息)
function GetBlackWhiteInfo(gameId, uid)
	local filter = unilight.a(unilight.eq("subgameid", gameId), unilight.eq("charid", uid))
	local blackWhiteInfos = unilight.getByFilter("blackwhitelist", filter, 1)
	local blackWhiteInfo  = blackWhiteInfos[1] 
	blackWhiteInfo = DelErrorBlackWhiteInfo(blackWhiteInfo)
	return blackWhiteInfo
end

-- 删掉不合法的黑白名单数据
function DelErrorBlackWhiteInfo(blackWhiteInfo)
	if blackWhiteInfo ~= nil then
		-- 如果setchips 小于等于0 则有误
		if blackWhiteInfo.setchips <= 0 or  blackWhiteInfo.curtimes > blackWhiteInfo.settimes or blackWhiteInfo.winrate == 0 then
			unilight.delete("blackwhitelist", blackWhiteInfo.id)
			return 	nil
		else
			return  blackWhiteInfo
		end
	end
end

-- 比较两个黑白名单数据权重(true 表示 info1>info2)
function CompareBlackWhiteInfo(info1, info2)
 	if info1.winrate > info2.winrate then
 		return true
 	elseif info1.winrate == info2.winrate then
 		if info1.setchips > info2.setchips then
 			return true
 		elseif info1.setchips == info2.setchips then
 			if math.random(1, 2) > 1 then
 				return true
 			else
 				return false
 			end
 		else
 			return false
 		end 
 	else
 		return false
 	end
end 

-- 获取当前房间内 黑白名单权重最大的一个数据(如果当前房间内 不存在黑白名单 则返回nil 如果存在 则返回最恰当的)
function GetBestBlackWhiteInfo(gameId, users, bankerUid)
	-- 庄家跟投注玩家 同样的处理方法 所以 一起处理
	local tempUsers = table.clone(users)
	if bankerUid ~= nil and bankerUid ~= 0 then
		table.insert(tempUsers, bankerUid)
	end
	local best = nil
	for i,uid in ipairs(tempUsers) do
		local blackWhiteInfo = GetBlackWhiteInfo(gameId, uid)
		if blackWhiteInfo ~= nil and blackWhiteInfo.state == 1 then
			if best == nil then
				best = blackWhiteInfo
			else
				if CompareBlackWhiteInfo(blackWhiteInfo, best) then
					best = blackWhiteInfo
				end
			end
		end
	end
	return best
end

-- 执行黑白名单信息(由roundId 获取这局游戏各人的输赢情况)
function ExecuteBlackWhiteInfo(gameId, users, bankerUid, roundId)
	unilight.info("------------------------------- 黑白更新 -------------------------------")
	-- 庄家跟投注玩家 同样的处理方法 所以 一起处理
	if bankerUid ~= nil and bankerUid ~= 0 then
		table.insert(users, bankerUid)
	end
	-- 检测这些玩家的 黑白名单信息
	for i,uid in ipairs(users) do
		local blackWhiteInfo = GetBlackWhiteInfo(gameId, uid)
		local delete = false
		if blackWhiteInfo ~= nil then
			-- 名单生效
			if blackWhiteInfo.state == 1 then
				-- 获取本局收益 
				local profit = 0
				if uid == bankerUid then
					profit = ProtectMgr.GetProfit(roundId, uid, true)
				else
					profit = ProtectMgr.GetProfit(roundId, uid, false)
				end
				-- 黑名单 且该局 玩家输钱了 则算 正常执行了
				if blackWhiteInfo.type == 2 and  profit < 0 then
					blackWhiteInfo.curchips = blackWhiteInfo.curchips - profit 
					unilight.info("当前黑名单 且收益小于0 执行有效：" .. uid)
				-- 白名单 且该局 玩家赢钱了
				elseif blackWhiteInfo.type == 1 and  profit > 0 then
					unilight.info("当前白名单 且收益大于0 执行有效：" .. uid)
					blackWhiteInfo.curchips = blackWhiteInfo.curchips + profit 
				end

				-- 如果执行筹码已达标
				if blackWhiteInfo.curchips >= blackWhiteInfo.setchips then
					-- 如果当前生效次数 已达到 设定生效次数 则 整个黑白名单 结束
					if blackWhiteInfo.curtimes >= blackWhiteInfo.settimes then
						unilight.delete("blackwhitelist", blackWhiteInfo.id)
						unilight.info("该玩家黑白名单顺利结束：" .. uid)		
						delete = true
					else
						-- 如果还没达到设定次数 则 开始进入间隔时间
						blackWhiteInfo.state 	= 0
						blackWhiteInfo.curchips = 0 
						unilight.info("该玩家 成功完成一次黑白名单 进入间隔期 等待下次生效：" .. uid)		

						-- 在这里检测下 是否间隔局数为0 如果为零 则不用间隔 从新开始
						if blackWhiteInfo.intervaltimes == 0 then
							blackWhiteInfo.state = 1
							blackWhiteInfo.curtimes = blackWhiteInfo.curtimes + 1
							unilight.info("当前黑白名单间隔局数0 重新开启：" .. blackWhiteInfo.charid)							
						end
					end
				end
			else
				blackWhiteInfo.curintervaltimes = blackWhiteInfo.curintervaltimes or 0
				blackWhiteInfo.curintervaltimes = blackWhiteInfo.curintervaltimes + 1

				unilight.info("当前黑白名单不生效 玩家uid:" .. uid .. "	已间隔局数:" .. blackWhiteInfo.curintervaltimes .. "	总共需要间隔局数:" .. blackWhiteInfo.intervaltimes)
				-- 如果 间隔局数 已够 则开启该玩家黑白名单
				if blackWhiteInfo.curintervaltimes >= blackWhiteInfo.intervaltimes then
					blackWhiteInfo.state = 1
					blackWhiteInfo.curintervaltimes = 0
					blackWhiteInfo.curtimes = blackWhiteInfo.curtimes + 1
					unilight.info("间隔局数已够 开启黑白名单：" .. blackWhiteInfo.charid)
				end
			end

			-- 不管当前名单生不生效 当前最新的名单数据要更新进去 除非该名单已删除
			if not delete then
				unilight.savedata("blackwhitelist", blackWhiteInfo)
			end
		end
	end	
	unilight.info("------------------------------------------------------------------------")
end

-- 单独执行黑白名单 
function AloneExecuteBlackWhiteInfo(gameId, uid, profit)
	-- 没有传入收益金额 则 直接返回
	if profit == nil then
		unilight.error("执行黑白名单 传入数据有误 profit为nil")
		return 
	end
	unilight.info("------------------------------- 黑白更新 -------------------------------")
	-- 检测这些玩家的 黑白名单信息
	local blackWhiteInfo = GetBlackWhiteInfo(gameId, uid)
	local delete = false
	local ret, type, goalChips = nil
	if blackWhiteInfo ~= nil then
		-- 名单生效
		if blackWhiteInfo.state == 1 then
			-- 黑名单 且该局 玩家输钱了 则算 正常执行了
			if blackWhiteInfo.type == 2 and  profit < 0 then
				blackWhiteInfo.curchips = blackWhiteInfo.curchips - profit 
				unilight.info("当前黑名单 且收益小于0 执行有效：" .. uid)
			-- 白名单 且该局 玩家赢钱了
			elseif blackWhiteInfo.type == 1 and  profit > 0 then
				unilight.info("当前白名单 且收益大于0 执行有效：" .. uid)
				blackWhiteInfo.curchips = blackWhiteInfo.curchips + profit 
			end


			-- 如果执行筹码已达标
			if blackWhiteInfo.curchips >= blackWhiteInfo.setchips then
				-- 如果当前生效次数 已达到 设定生效次数 则 整个黑白名单 结束
				if blackWhiteInfo.curtimes >= blackWhiteInfo.settimes then
					unilight.delete("blackwhitelist", blackWhiteInfo.id)
					unilight.info("该玩家黑白名单顺利结束：" .. uid)		
					delete = true
				else
					-- 如果还没达到设定次数 则 开始进入间隔时间
					blackWhiteInfo.state 	= 0
					blackWhiteInfo.curchips = 0 
					unilight.info("该玩家 成功完成一次黑白名单 进入间隔期 等待下次生效：" .. uid)	

					-- 在这里检测下 是否间隔局数为0 如果为零 则不用间隔 从新开始
					if blackWhiteInfo.intervaltimes == 0 then
						blackWhiteInfo.state = 1
						blackWhiteInfo.curtimes = blackWhiteInfo.curtimes + 1
						unilight.info("当前黑白名单间隔局数0 重新开启：" .. blackWhiteInfo.charid)							
					end
				end
				ret, type, goalChips = true, blackWhiteInfo.type, 0
			else
				ret, type, goalChips = true, blackWhiteInfo.type, blackWhiteInfo.setchips - blackWhiteInfo.curchips
			end
		else
			blackWhiteInfo.curintervaltimes = blackWhiteInfo.curintervaltimes or 0
			blackWhiteInfo.curintervaltimes = blackWhiteInfo.curintervaltimes + 1

			unilight.info("当前黑白名单不生效 玩家uid:" .. uid .. "	已间隔局数:" .. blackWhiteInfo.curintervaltimes .. "	总共需要间隔局数:" .. blackWhiteInfo.intervaltimes)
			-- 如果 间隔局数 已够 则开启该玩家黑白名单
			if blackWhiteInfo.curintervaltimes >= blackWhiteInfo.intervaltimes then
				blackWhiteInfo.state = 1
				blackWhiteInfo.curintervaltimes = 0
				blackWhiteInfo.curtimes = blackWhiteInfo.curtimes + 1
				unilight.info("间隔局数已够 开启黑白名单：" .. blackWhiteInfo.charid)
			end
		end

		-- 不管当前名单生不生效 当前最新的名单数据要更新进去 除非该名单已删除
		if not delete then
			unilight.savedata("blackwhitelist", blackWhiteInfo)
		end
	end
	if ret then
		return ret, type, goalChips
	else
		return false
	end
	unilight.info("------------------------------------------------------------------------")	
end
-------------------------------后台操作-----------------------

-- 添加黑白名单(datas repeated 预防后期一次性新增多个)
function AddBlackWhiteList(datas, isAuto)
	-- 新增黑白名单 操作状态
	local status = {0,0,0,0}

	local gameId = nil

	for i,data in ipairs(datas) do
		local id 				= GetBlackWhiteId() 		-- 该黑白名单的唯一id --lbx(以前为平台指定唯一 现在改为服务器指定并返回给平台)
		gameId 					= data.subgameid 			-- 指定游戏 
		local uid 				= data.charid 				-- 设定黑白名单 玩家id
		local setChips  		= data.setchips				-- 设定筹码
		local curChips 			= data.curchips 			-- 当前已经执行的筹码	
		local winRate 			= data.winrate				-- 胜率
		local state 			= data.state 				-- 状态,1有效, 0无效
		local type 				= data.type					-- 类型,1白名单 2黑名单, 
		local setTimes 			= data.settimes 			-- 设定生效次数
		local curTimes 			= data.curtimes or 1		-- 当前已经生效的次数	默认值为1
		local intervalTimes 	= data.intervaltimes 		-- 间隔次数

		-- 如果当前游戏为捕鱼则只让设置生效一次
		if gameId == 150 then
			setTimes = 1
		end

		-- 赋值并等待返回给平台
		datas[i].id = id

		local userInfo = chessuserinfodb.RUserInfoGet(uid) 
		if userInfo ~= nil then
			if setChips > 0 and winRate > 0 and setTimes > 0 and curTimes <= setTimes then
				local lastBlackWhiteInfo = GetBlackWhiteInfo(gameId, uid)
				if lastBlackWhiteInfo == nil then
					local blackWhiteInfo = {
						id 				= id,						-- 该黑白名单的唯一id
						subgameid 		= gameId,					-- 指定游戏 
						charid			= uid,						-- 设定黑白名单 玩家id
						charname		= userInfo.base.nickname,
						setchips		= setChips,					-- 设定筹码
						curchips		= curChips,					-- 当前已经执行的筹码	
						winrate			= winRate,					-- 胜率
						state			= state,					-- 状态,1有效, 0无效
						type			= type,						-- 类型,1白名单 2黑名单
						settimes		= setTimes,					-- 设定生效次数
						curtimes		= curTimes,					-- 当前已经生效的次数  默认值为1
						intervaltimes 	= intervalTimes,			-- 间隔次数
						curintervaltimes= 0,						-- 当前间隔次数(用于计数)
						recordtime		= os.time(),
						isauto 			= isAuto or false  			-- 是否为自动添加的 （protect来的）
					}
					unilight.savedata("blackwhitelist", blackWhiteInfo)	
					
					status[4] = status[4] + 1
					unilight.info("黑白名单设置成功 gameId:" .. gameId .. "	uid:" .. uid)
				else
					status[3] = status[3] + 1
					unilight.info("黑白名单设置失败 该玩家指定游戏中已经存在黑白名单信息 gameId:" .. gameId .. "	uid:" .. uid)
				end
			else
				status[2] = status[2] + 1
				unilight.info("黑白名单设置失败 将设置的黑白名单信息有误")					
			end
		else
			status[1] = status[1] + 1
			unilight.info("黑白名单设置失败 该玩家不存在 uid:" .. uid)
		end
	end

	local log = "黑白名单设置 gameId:" .. gameId .. "成功个数：" .. status[4] .. "玩家uid不存在个数：" .. status[1] .. "设置的黑白名单信息有误个数：" .. status[2] .. "已存在黑白名单数据玩家个数：" .. status[3]
	unilight.info(log)
	-- 至少有一个成功了
	if status[4] > 0 then
		return 0, log, datas
	-- 一个都没有成功
	else
		return 2, log, datas		
	end
end

-- 修改黑白名单
function ModBlackWhiteList(data)
	local id 				= data.id 					-- 该黑白名单的唯一id
	local gameId 			= data.subgameid 			-- 指定游戏 
	local uid 				= data.charid 				-- 设定黑白名单 玩家id
	local setChips  		= data.setchips				-- 设定筹码
	local curChips 			= data.curchips 			-- 当前已经执行的筹码	
	local winRate 			= data.winrate				-- 胜率
	local state 			= data.state 				-- 状态,0有效, 1无效
	local type 				= data.type					-- 类型,0黑名单, 1白名单
	local setTimes 			= data.settimes 			-- 设定生效次数
	local curTimes 			= data.curtimes	or 1		-- 当前已经生效的次数	
	local intervalTimes 	= data.intervaltimes 		-- 间隔次数

	-- 如果当前游戏为捕鱼则只让设置生效一次
	if gameId == 150 then
		setTimes = 1
	end

	local userInfo = chessuserinfodb.RUserInfoGet(uid) 
	if userInfo == nil then
		return 2, "不存在该玩家:" .. uid 
	end

	local lastBlackWhiteInfo = GetBlackWhiteInfo(gameId, uid)
	if lastBlackWhiteInfo == nil then
		return 3, "当前玩家不存在黑白名单信息 不能修改:" .. uid 
	end

	if setChips <= 0 or winRate <= 0 or setTimes <= 0 or curTimes > setTimes then
		return 4, "将设置的黑白名单信息有误"
	end

	local blackWhiteInfo = {
		id 				= id,
		subgameid 		= gameId,
		charid			= uid,
		charname		= userInfo.base.nickname,
		setchips		= setChips,
		curchips		= curChips,
		winrate			= winRate,
		state			= state,
		type			= type,
		settimes		= setTimes,
		curtimes		= curTimes,
		intervaltimes 	= intervalTimes,
		curintervaltimes= 0,						-- 当前间隔次数(用于计数)
		recordtime		= os.time(),
		isauto 			= false  					-- 手动修改过的黑白名单 全部置为false
	}

	unilight.savedata("blackwhitelist", blackWhiteInfo)

	unilight.info("黑白名单修改成功 gameId:" .. gameId .. "uid:" .. uid)
	return 0, "黑白名单修改成功 gameId:" .. gameId .. "uid:" .. uid 
end

-- 删除黑白名单
function DelBlackWhiteList(ids)
	local delete = false
	for i,id in ipairs(ids) do
		local blackWhiteInfo = unilight.getdata("blackwhitelist", id)
		if blackWhiteInfo ~= nil then
			unilight.delete("blackwhitelist", id)	
			delete = true
		end
	end
	if delete then
		return 0, "删除黑白名单成功"
	else
		return 2, "删除黑白名单失败 并不存在这些黑白名单"
	end
end

-- 查询黑白名单
function ReqBlackWhiteList(data)
	local id 		= data.id
	local subgameid = data.subgameid 
	local charid 	= data.charid 	
	local nickname 	= data.charname 	
	local curpage 	= data.curpage
	local perpage 	= data.perpage

	-- 只查指定游戏的
	local filter = unilight.eq("subgameid", subgameid)

	-- 如果存在id  则默认使用id
	if id ~= 0 then
		filter = unilight.a(filter, unilight.eq("id", id))
	else
		-- 如果指定玩家id
		if charid ~= 0 then
			filter = unilight.a(filter, unilight.eq("charid", charid))
		end
	end

	-- 计算总页数
	local infoNum 	= unilight.startChain().Table("blackwhitelist").Filter(filter).Count()
	local info 		= unilight.chainResponseSequence(unilight.startChain().Table("blackwhitelist").Filter(filter).Skip((curpage-1)*perpage).Limit(perpage))
	local maxpage	= math.ceil(infoNum/perpage)

	data.maxpage 	= maxpage
	data.data 		= info 

	return data
end


