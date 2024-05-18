-- Nado相关
module('Nado', package.seeall)

-- Nado机器相关数据库表
DB_NADO_NAME = "nado"
-- Nado机器相关配置表
TableNadoProgress = import "table/table_nado_progress"
TableNadoReward = import "table/table_nado_reward"
TableNadoStar = import "table/table_nado_star"
TableItemConfig = import "table/table_item_config"

-- 道具表收集物类型
CollectType = 9
BlueType = "2"
-- 收集物礼包ID
GiftBagIds = {100008,100000}

-- 玩家数据库Nado机器相关信息初始化
function NadoDataInfoGet(uid)
    -- 玩家救济金数据库信息
	local nadoInfo = unilight.getdata(DB_NADO_NAME, uid)
    -- 是否有修改
	local bUpdate = false
	if table.empty(nadoInfo) then
		local collects = {}
		for k, v in pairs(TableItemConfig) do
			if v.goodType == CollectType and v.para2 == BlueType then
				local collect = {}
				collect.id = v.ID
				collect.num = 0
				table.insert(collects, collect)
			end
		end

		nadoInfo = {
			["_id"] = uid,
            ["residueNadoNbr"] = 0,
            ["nadoRewardList"] = {},
			["collects"] = collects,
			["collectNbr"] = 0
		}
		bUpdate = true
	end

	if bUpdate then
		unilight.savedata(DB_NADO_NAME, nadoInfo)
	end
	return nadoInfo
end

-- 玩家进入Nado机器页面数据返回
function NadoInfoGet(uid)
	local nadoInfo = unilight.getdata(DB_NADO_NAME, uid)
	if table.empty(nadoInfo) then
        nadoInfo = NadoDataInfoGet(uid)
    end
	
	local res = {
        residueNadoNbr = nadoInfo.residueNadoNbr,
        nadoRewardList = nadoInfo.nadoRewardList,
    }
    return res
end

-- 玩家游玩Nado机器游戏
function NadoPlay(uid, skip)
	local skip = skip or false
	-- 获取Nado服务器数据库信息
	local nadoInfo = unilight.getdata(DB_NADO_NAME, uid)
	if nadoInfo.residueNadoNbr < 1 then
		unilight.error("游玩Nado游戏次数不足")
		return
	end
	local residueNadoNbr
	if skip then
		residueNadoNbr = nadoInfo.residueNadoNbr
		nadoInfo.residueNadoNbr = 0
		for i = 1, residueNadoNbr do
			-- 进行Nado机器奖励随机
			local probability = {}
			local allResult = {}
			for k, v in pairs(TableNadoReward) do
				if v.probability > 0 then
					table.insert(probability, v.probability)
					table.insert(allResult, {v.probability, v.reward})
				end
			end
			-- 获取随机后的奖励结果
			local nadoReward = math.random(probability, allResult)[2]
			-- 添加奖励列表
			table.insert(nadoInfo.nadoRewardList, nadoReward)
		end
	else
		-- 进行Nado机器奖励随机
		local probability = {}
		local allResult = {}
		for k, v in pairs(TableNadoReward) do
			if v.probability > 0 then
				table.insert(probability, v.probability)
				table.insert(allResult, {v.probability, v.reward})
			end
		end
		-- 获取随机后的奖励结果
		local nadoReward = math.random(probability, allResult)[2]
		-- 添加奖励列表
		table.insert(nadoInfo.nadoRewardList, nadoReward)
		nadoInfo.residueNadoNbr = nadoInfo.residueNadoNbr - 1
	end

	-- 更新数据库信息
	unilight.update(DB_NADO_NAME, uid, nadoInfo)

	local res = {
		nadoRewardList = nadoInfo.nadoRewardList,
		residueNadoNbr = nadoInfo.residueNadoNbr,
	}
	return res
end

-- 玩家领取Nado机器奖励
function NadoGetReward(uid)
	-- 获取数据库信息
	local nadoInfo = unilight.getdata(DB_NADO_NAME, uid)
	local nadoRewardList = nadoInfo.nadoRewardList
	-- 领取奖励后清空数据库相关数据
	nadoInfo.nadoRewardList = {}
	unilight.update(DB_NADO_NAME, uid, nadoInfo)
	local chips = {}
	-- 循环添加玩家获取物品
	for k, v in pairs(nadoRewardList) do
		local reward = BackpackMgr.GetRewardGood(uid,v.id,v.num, Const.GOODS_SOURCE_TYPE.NADO)
		-- local reward = BackpackMgr.GetRewardGood(uid,v.id,1)
		for i, value in ipairs(GiftBagIds) do
			if v.id == value then
				for k, v in pairs(reward) do
					local chip = {
						id = k,
						num = v,
					}
					table.insert(chips, chip)
				end
			end
		end
	end
	local res = {
		nadoRewardList = nadoInfo.nadoRewardList,
		residueNadoNbr = nadoInfo.residueNadoNbr,
		chips = chips,
	}
	return res
end

-- Nado机器获取收集物
function NadoGetCollect(uid, goodId)
	-- 获取Nado机器数据库信息
	local nadoInfo = unilight.getdata(DB_NADO_NAME, uid)
	if table.empty(nadoInfo) then
        nadoInfo = NadoDataInfoGet(uid)
    end
	local update = false
	local collectStar = 0
	local firstGet = false
	-- 匹配是否是Nado机器的蓝色收集物
	for i, v in ipairs(nadoInfo.collects) do
		if v.id == goodId then
			-- 如果是第一次获得 判断累计次数
			if v.num == 0 then
				firstGet = true
			end
			v.num = v.num + 1
			update = true
			break
		end
	end
	if update then
		-- 搜寻物品表对应物品ID的信息
		for k, v in pairs(TableItemConfig) do
			if v.ID == goodId then
				collectStar = tonumber(v.para1)
				break
			end
		end
		-- 根据对应星数获取摇奖次数
		for i, v in ipairs(TableNadoStar) do
			if v.starNbr == collectStar then
				nadoInfo.residueNadoNbr = nadoInfo.residueNadoNbr + v.addNbr
			end
		end
		-- 第一次获取判断进度
		if firstGet then
			local collectNbr = 0
			-- 收集物进度
			for i, v in ipairs(nadoInfo.collects) do
				if v.num ~= 0 then
					-- 判断获取过的收集物进度
					collectNbr = collectNbr + 1
				end
			end
			-- 判断增加次数
			for i, v in ipairs(TableNadoProgress) do
				if v.blueNbr > nadoInfo.collectNbr and v.blueNbr <= collectNbr then
					nadoInfo.residueNadoNbr = nadoInfo.residueNadoNbr + v.addNbr
				end
			end
			nadoInfo.collectNbr = collectNbr
		end

		-- 保存数据库信息
		unilight.update(DB_NADO_NAME, uid, nadoInfo)

		-- 发送变化信息
		local send = {}
		send["do"] = "Cmd.NadoNumChengeReturnNadoCmd_S"
		local data = {
			residueNadoNbr = nadoInfo.residueNadoNbr
		}
		send["data"] = data
		unilight.sendcmd(uid,send)
	end
end