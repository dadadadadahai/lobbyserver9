module("OperateSwitchMgr", package.seeall)
-- 用于统一管理 运营活动 开关

-- 枚举 运营活动 开关类型
ENUM_SWITCH_TYPE = {
	ALWAYS  	= 1, -- 持续开或关
	MONTHS		= 2, -- 指定月份开启			 每年这几个月都开启
	WEEKS		= 3, -- 指定周几开启   	 		 每逢周几就开启
	DAYS 		= 4, -- 指定哪天开启			 每月这几天都开启
	TIMES 		= 5, -- 指定时间段开启 			 要确切指定哪几天开启的 则 使用指定时间段
}

ENUM_OPRATE_TYPE = {
	TURNTABLE   = 1, -- 幸运大转盘
}

-- 初始化 运营活动开关相关信息 (默认指定运营活动 始终开启)
function Init(opAcId)
	local info = {
		opAcId 		= opAcId,
		openType 	= ENUM_SWITCH_TYPE.ALWAYS,	-- 默认 持续状态
		isOpen 		= false, 					-- 持续开关状态 默认关闭
		appoint		= nil,						-- 如果指定 哪天、哪个月、星期几 开启 则检测该字段
		between 	= nil,						-- 如果指定 时间段 则检测该字段 head tail 
	}
	unilight.savedata("operateswitch", info)
	return info
end

-- 设置指定运营活动 运营时间
function SetOprateTime(opAcId, openType, isOpen, appoint, between)
	local info = {
		opAcId 		= opAcId,
		openType	= openType,
	}
	if info.openType == ENUM_SWITCH_TYPE.ALWAYS then
		info.isOpen = isOpen
	elseif info.openType == ENUM_SWITCH_TYPE.MONTHS or info.openType == ENUM_SWITCH_TYPE.WEEKS or info.openType == ENUM_SWITCH_TYPE.DAYS then
		info.appoint = appoint
	elseif info.openType == ENUM_SWITCH_TYPE.TIMES then
		-- 进来的时间段 为string类型 解析为时间戳后 存储
		local temp = {}
		for i,v in ipairs(between) do
			local time = {
				head = chessutil.TimeBySpecialDateGet(v.head),
				tail = chessutil.TimeBySpecialDateGet(v.tail)
			}
			table.insert(temp, time)
		end
		info.between = temp
	else
		return 2, "设置类型有误"
	end

	unilight.savedata("operateswitch", info)
	unilight.info("设置 运营活动成功：" .. table.tostring(info))
	return 0, "成功设置"
end

-- 检测是否在 指定运营活动 时间内
function CheckInOprateTime(opAcId)
	local info = unilight.getdata("operateswitch", opAcId)
	if info == nil then
		info = Init(opAcId)
	end
	local time = os.time()
	local date = os.date("*t")

	-- 星期几 单独处理 因为通过date直接获取到的数据 与 常规使用的 不一致 所有要整理下
	local wday = date.wday - 1 
	if wday == 0 then
		wday = 7
	end

	-- 持续开关状态
	if info.openType == ENUM_SWITCH_TYPE.ALWAYS then
		if info.isOpen == true then
			return true
		else
			return false
		end
	-- 指定月份开启
	elseif info.openType == ENUM_SWITCH_TYPE.MONTHS then
		for i,v in ipairs(info.appoint) do
			if v == date.month then
				return true
			end
		end
		return false
	-- 指定周几开启
	elseif info.openType == ENUM_SWITCH_TYPE.WEEKS then
		for i,v in ipairs(info.appoint) do
			if v == date.wday then
				return true
			end
		end
		return false
	-- 指定days开启
	elseif info.openType == ENUM_SWITCH_TYPE.DAYS then
		for i,v in ipairs(info.appoint) do
			if v == date.day then
				return true
			end
		end
		return false
	-- 指定时间段开启
	elseif info.openType == ENUM_SWITCH_TYPE.TIMES then
		for i,v in ipairs(info.between) do
			if time >= v.head and time <= v.tail then
				return true
			end
		end
		return false
	end
end


