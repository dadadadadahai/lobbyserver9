-- 下面常量定义 本不应存在 。。 但是为了拷贝飞禽走兽的转账相关代码 所以才临时沿用 后面如需整理 可去除


USER_TRY_REDPAPER_MAXTIME  = 30 -- 玩家连续尝试开红包错误的最大次数

UNREGISTER                           = 400 -- 玩家未注册
PARAMATER_NOT_ENOUGH                 = 401 -- 参数不完整
USER_NOT_ENTER_GAME                  = 402 -- 玩家未进入游戏
USER_NOT_BET                         = 403 -- 玩家未下注
USER_NOT_LOGIN                       = 403 -- 玩家未登陆
PARA_ERROR                           = 404 -- 参数错误 
USER_FORBIT_BY_GM                    = 405 -- 被禁止
USER_CHIPS_LACK                      = 406 -- 玩家缺少筹码
USER_DOUBLE_APPLY_BANKER             = 407 -- 玩家重复申请上庄
EXCHANGE_ORDER_IS_NULL               = 408 -- 交易红包不存在
EXCHANGE_ORDER_HAVE_RECEI            = 409 -- 交易红包已经被领取
EXCHANGE_REMAINTIME_EMPTY            = 410 -- 剩余打开次数不足
USER_IS_NOT_BANKER                   = 411 -- 玩家已下庄
EXCHANGE_ORDER_REPEAT_RECEIVE        = 412 -- 该类红包重复领取
EXCHANGE_CHIPS_ERROR        		 = 413 -- 当前货币类型不一致
-- 转账信息获取
Net.CmdExchangeInfo_CS = function(cmd, laccount)
	local uid = laccount.Id
	local lowestLimit = 1000000
	-- 检测是否为荣强网络 
	if laccount.JsMessage.GetPlatid() == 151 or laccount.JsMessage.GetPlatid() == 153 then
		-- 检测是否充值超过100元
		local sumRecharge = chessrechargemgr.CmdUserSumRechargeGetByUid(uid, 0, os.time())
		if sumRecharge >= 100 then
			lowestLimit = 80000
		end
	end

	-- 检测是否为泰国
	-- if laccount.JsMessage.GetPlatid() == 166 then
	-- 	lowestLimit = 3000000
	-- end

	local res = cmd
	res.data = 
	{
		lowestLimit = lowestLimit,
	}
	return res
end

-- 转账key生成
Net.CmdExchangeKeyGet_CS = function(cmd, laccount)
	local res = cmd
	if cmd.data == nil or cmd.data.exchangeInfo == nil or cmd.data.exchangeInfo.id == nil or cmd.data.exchangeInfo.chips == nil then
		res.data.resultCode = PARAMATER_NOT_ENOUGH
		return res
	end
	local uid = laccount.Id
	local id = cmd.data.exchangeInfo.id
	-- 转账金额 由前端直接发来 服务器不去读表验证 支持自定义转账
	local lowestLimit = 1000000
	-- 荣强网络 平台id 151  且充值100以上 红包限制下限为8w
	if laccount.JsMessage.GetPlatid() == 151 or laccount.JsMessage.GetPlatid() == 153  then
		local sumRecharge = chessrechargemgr.CmdUserSumRechargeGetByUid(uid, 0, os.time())
		if sumRecharge >= 100 then
			lowestLimit = 80000
		end
	end

	-- 检测是否为泰国
	-- if laccount.JsMessage.GetPlatid() == 166 then
	-- 	lowestLimit = 3000000
	-- end
	
	local exchangeChips = cmd.data.exchangeInfo.chips
	if exchangeChips < lowestLimit then
		unilight.error("转账金额低于最低下限 转账有误")
		res.data.resultCode = PARA_ERROR
		return res		
	end

	local userInfo = unilight.getdata("userinfo", uid)
	-- 捕鱼接入bug 如果存在userdata.fish ~= nil and userdata.fish.recharge.roomtype ~= nil 则不给领取红包
	if userInfo.fish ~= nil and userInfo.fish.recharge.roomtype ~= nil then
		unilight.error("当前玩家请求转账红包 货币类型不一致 有刷币风险:" .. uid)
		res.data.resultCode = EXCHANGE_CHIPS_ERROR
		return res
	end

	local remaindChips, bRet = chessuserinfodb.WChipsChange(uid, 2, exchangeChips, "包了转账红包")
	
	if bRet == false then
		res.data.resultCode = USER_CHIPS_LACK
		return res
	end
	local exchageorder = ExchangeMgr.exchangeKeyGet(exchangeChips)

	ExchangeMgr.createExchangeOrder(uid, exchageorder, id, exchangeChips)
	res.data.resultCode = 0
	res.data.remainderChips = remaindChips
	res.data.exchangeKey = exchageorder

	return res
end

-- 领取交易筹码
Net.CmdExchangeChipsReceive_CS = function(cmd, laccount)
	local res = cmd
	if cmd.data == nil or cmd.data.exchangeKey == nil then
		res.data.resultCode = PARAMATER_NOT_ENOUGH
		return res
	end

	local uid = laccount.Id

	local userInfo = unilight.getdata("userinfo", uid)
	if nil == userInfo.control.redPaperTryTime then  --算是字段的增加吧
		userInfo.control.redPaperTryTime = 0
	end

	if userInfo.control.redPaperTryTime >= USER_TRY_REDPAPER_MAXTIME then   --兑换错误次数限制 ，直接返回错误
		res.data.resultCode = EXCHANGE_REMAINTIME_EMPTY
		return res
	end

	-- 捕鱼接入bug 如果存在userdata.fish ~= nil and userdata.fish.recharge.roomtype ~= nil 则不给领取红包
	if userInfo.fish ~= nil and userInfo.fish.recharge.roomtype ~= nil then
		unilight.error("当前玩家接收转账红包 货币类型不一致 有刷币风险:" .. uid)
		res.data.resultCode = EXCHANGE_CHIPS_ERROR
		return res
	end

	local exchageOrder = cmd.data.exchangeKey
	local exchangeInfo = ExchangeMgr.exchangeRecordGetByExchangeOrder(exchageOrder)
	if exchangeInfo == nil then		
		--增加兑换码try time限制
		userInfo.control.redPaperTryTime = userInfo.control.redPaperTryTime + 1  --次数增加
		unilight.savedata("userinfo", userInfo)  --数据更新

		res.data.resultCode = EXCHANGE_ORDER_IS_NULL
		res.data.remainTryTime = USER_TRY_REDPAPER_MAXTIME - userInfo.control.redPaperTryTime    --剩余次数通知

		return res
	end

	-- 如果成功过一次 尝试次数清空
	if userInfo.control.redPaperTryTime ~= 0 then
		userInfo.control.redPaperTryTime = 0 
		unilight.savedata("userinfo", userInfo)  --数据更新	
	end

	-- 判断该红包是否已领取过
	if exchangeInfo.dstuid ~= 0 or exchangeInfo.bok ~= 0 then
		res.data.resultCode = EXCHANGE_ORDER_HAVE_RECEI
		return res
	end

	-- 加入flag判断 1--1000范围内 同一个flag的红包 每个用户最多只能领取一个
	if exchangeInfo.flag ~= nil and exchangeInfo.flag <= 1000 then
		-- 检测是否已领过该类红包 
		local filter = unilight.a(unilight.eq("dstuid", uid), unilight.eq("bok", 1), unilight.eq("flag", exchangeInfo.flag))	
		local count  = unilight.startChain().Table("lobbyExchange").Filter(filter).Count()
		if count ~= 0 then
			unilight.info("当前玩家已领取过该类型红包 不能重复领取 uid：" .. uid .. " flag:" .. exchangeInfo.flag)
			res.data.resultCode = EXCHANGE_ORDER_REPEAT_RECEIVE
			return res		
		end
	end

	-- add chips
	local bOk, remainderChips = chessuserinfodb.WChipsChange(uid, 1, exchangeInfo.chips, "领取转账红包")
	if bOk == false then
		unilight.error("这里出现说明有bug找不到相应的uid:" .. uid)
	end

	-- 修改红包信息
	exchangeInfo = ExchangeMgr.receiveExchangeOrder(uid, exchangeInfo)

	-- 发送一份数据给monitor
	ExchangeMgr.SendExchangeInfoToMonitor(exchangeInfo)

	res.data.exchangeInfo = {
		id = exchangeInfo.id,
		chips = exchangeInfo.chips,
	}
	res.data.remainderChips = remainderChips
	res.data.resultCode = 0
	
	return res
end

Net.CmdExchangeRecordGet_CS = function(cmd, laccount)
	local retMsg = cmd
	local uid = laccount.Id
	
	local sendRecord = {}
	local receiveRecord = {}

	local filter = nil

	-- 获取所有 发送并未被领取的红包记录
	filter = unilight.a(unilight.eq("srcuid", uid), unilight.eq("bok", 0), unilight.neq("flag", 1))
	local sendRecord1 = unilight.chainResponseSequence(unilight.startChain().Table("lobbyExchange").Filter(filter)) or {}
	for i,v in ipairs(sendRecord1) do
		local srcUser = unilight.getdata("userinfo", uid)
		local msgRedPaper = {
			exchangeInfo = v.exchangeInfo,
			exchangeKey = v.exchangeorder,
			bOk = v.bok,
			sendUserName = srcUser.base.nickname,
		}
		table.insert(sendRecord, msgRedPaper)		
	end

	-- 获取最新 发送并被接收的记录 5条
	filter = unilight.a(unilight.eq("srcuid", uid), unilight.eq("bok", 1), unilight.neq("receivedate", ""))
	local sendRecord2 = unilight.chainResponseSequence(unilight.startChain().Table("lobbyExchange").Filter(filter).OrderBy(unilight.desc("receivetime")).Limit(5)) or {}
	for i,v in ipairs(sendRecord2) do
		local srcUser = unilight.getdata("userinfo", uid)
		local recvUser = unilight.getdata("userinfo", v.dstuid)	
		local msgRedPaper = {
			exchangeInfo = v.exchangeInfo,
			exchangeKey = v.exchangeorder,
			bOk = v.bok,
			sendUserName = srcUser.base.nickname,
			recvUserName = recvUser.base.nickname,
			recvTime = v.receivedate,
		}
		table.insert(sendRecord, msgRedPaper)		
	end

	-- 获取最新 领取过的红包记录 5条
	filter =  unilight.a(unilight.neq("srcuid", uid), unilight.eq("dstuid", uid), unilight.eq("bok", 1), unilight.neq("receivedate", ""))
	local temp = unilight.chainResponseSequence(unilight.startChain().Table("lobbyExchange").Filter(filter).OrderBy(unilight.desc("receivetime")).Limit(5)) or {}
	for i,v in ipairs(temp) do
		local srcUser = unilight.getdata("userinfo", v.srcuid)
		local recvUser = unilight.getdata("userinfo", uid)
		local msgRedPaper = {
			exchangeInfo = v.exchangeInfo,
			exchangeKey = v.exchangeorder,
			bOk = v.bok,
			sendUserName = srcUser.base.nickname,
			recvUserName = recvUser.base.nickname,  
			recvTime = v.receivedate,
		}
		table.insert(receiveRecord, msgRedPaper)
	end

	retMsg.data.sendRecord 		= sendRecord
	retMsg.data.receiveRecord 	= receiveRecord
	retMsg.data.resultCode 		= 0
	return retMsg
end
