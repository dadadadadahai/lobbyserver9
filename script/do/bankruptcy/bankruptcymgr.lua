-- 处理 破产相关
module('BankRuptcyMgr', package.seeall)

TABLE_DB_NAME 	 = "bankruptcy"
BANKRUPTCY_TIME  = 2
BANKRUPTCY_CHIPS = 3000

-- 新建一个 破产信息
function NewBankRuptcyInfo(uid)
	local bankRuptcyInfo = {
		uid 	= uid,			-- 
		nbr 	= 0,			-- 今天破产补助已领取次数
		time 	= 0,			-- 信息更新时间戳
	}

	-- 存档
	UpdateBankRuptcyInfo(bankRuptcyInfo)

	return bankRuptcyInfo
end

-- 更新破产信息
function UpdateBankRuptcyInfo(bankRuptcyInfo)
	bankRuptcyInfo.time = os.time()
	unilight.savedata(TABLE_DB_NAME, bankRuptcyInfo)
end

-- 给前端发送破产消息
function SendBankRuptcy(uid)
	local laccount = go.accountmgr.GetAccountById(uid)
	local send = {}
	send["do"] = "Cmd.SendBankruptcyCmd_Brd"

	-- 现在给前端发送破产补助时 并自动帮其领取了（只有当前领取成功了 才给弹通知）
	local ret, desc, subsidy, remainder, surplus = GetSubsidyBankruptcy(uid)
	if ret == 0 then
		send["data"] = {
			surplus = surplus,
			all 	= BANKRUPTCY_TIME,
			chips 	= BANKRUPTCY_CHIPS,
			remainder = remainder,
		}
		unilight.success(laccount, send)
		unilight.info("大厅给前端发送破产通知 并帮其领取")		
	end
end

-- 领取破产补助
function GetSubsidyBankruptcy(uid)
	local userInfo = chessuserinfodb.RUserInfoGet(uid) 
	-- 检测是否破产
	if userInfo.property.chips + userInfo.bank.chips >= LobbyToChessMgr.BANKRUPTCY_THRESHOLD then
		return 1, "还未破产 领取破产补助 失败"
	end

	-- 检测是否还有补助可领 
	local bankRuptcyInfo = unilight.getdata(TABLE_DB_NAME, uid)
	-- 如果不存在 或者 数据不是今天的 则 新建
	if bankRuptcyInfo == nil or TaskMgr.IsSameDay(os.time(), bankRuptcyInfo.time) == false then
		bankRuptcyInfo = NewBankRuptcyInfo(uid)
	end

	if bankRuptcyInfo.nbr >= BANKRUPTCY_TIME then
		-- 如果补助用光了 则 告诉玩家 多久后 可以领取在线奖励
		local nextTimes = DaySign.CmdUserNextTimesRequest(uid)
		return 2, "今天已经没有破产补助可领取", nil, nil, nil, nextTimes
	end

	-- 正式领取
	local summary = BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD_BASE, BANKRUPTCY_CHIPS, Const.GOODS_SOURCE_TYPE.ACTIVITY)
	local remainder = summary[Const.GOODS_ID.GOLD_BASE]	


	-- 置状态
	bankRuptcyInfo.nbr = bankRuptcyInfo.nbr + 1 
	UpdateBankRuptcyInfo(bankRuptcyInfo)

	unilight.info("玩家：" .. uid .. " 领取破产补助：" .. BANKRUPTCY_CHIPS .. " 当天剩余领取次数： " .. BANKRUPTCY_TIME - bankRuptcyInfo.nbr)

	-- 数据返回
	return 0, "领取破产补助 成功", BANKRUPTCY_CHIPS, remainder, BANKRUPTCY_TIME - bankRuptcyInfo.nbr
end


-- 查看当前次数
function GetSubsidyBankruptcyTimes(uid)
	local surplus = 0

	-- 检测是否还有补助可领 
	local bankRuptcyInfo = unilight.getdata(TABLE_DB_NAME, uid)
	-- 如果不存在 或者 数据不是今天的 则 新建
	if bankRuptcyInfo == nil or TaskMgr.IsSameDay(os.time(), bankRuptcyInfo.time) == false then
		bankRuptcyInfo = NewBankRuptcyInfo(uid)
	end

	if bankRuptcyInfo.nbr < BANKRUPTCY_TIME then
		surplus = BANKRUPTCY_TIME - bankRuptcyInfo.nbr
	end
	
	return 0, "获取补助次数成功", surplus, BANKRUPTCY_TIME
end