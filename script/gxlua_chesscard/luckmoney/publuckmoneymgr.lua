-- 用来统一处理公共红包
module('PubLuckMoneyMgr', package.seeall)


PUB_LUCK_MONEY_DB_NAME 		= "publuckmoney"	-- 公共红包 数据表名
RCV_PUB_LUCK_MONEY_DB_NAME 	= "rcvpubluckmoney"	-- 存储该玩家领取过的红包记录

PubLuckMoneyIndex = 1

-- 创建相关表
function CmdDbCreate()
	unilight.createdb(PUB_LUCK_MONEY_DB_NAME, "_id")
	unilight.createindex(PUB_LUCK_MONEY_DB_NAME, "uidSend")

	unilight.createdb(RCV_PUB_LUCK_MONEY_DB_NAME, "uid")
end

-- 公共红包 _id 生成
function PubLuckMoneyIdCreate()
	local strIndex = string.format("%05d", PubLuckMoneyIndex)
	PubLuckMoneyIndex = PubLuckMoneyIndex + 1
	local time = os.time()
	return tostring(time) .. strIndex
end

-- 红包金额随机
function GetRandomChips(surplusNumber, surplusChips)
	if surplusNumber == 1 then 
		return surplusChips
	end

	local money = math.random(1, surplusChips - surplusNumber + 1)
	unilight.info("当前红包随机情况  剩余个数：" .. surplusNumber .. "	剩余金币：" .. surplusChips .. "	金币：" .. money)
	return money
end

-- 发送红包
function CmdSendLuckMoney(uid, roomId, chips, number, bless)
	-- _id生成
	local _id = PubLuckMoneyIdCreate()

	local remainder, ok = chessuserinfodb.WChipsChange(uid, 2, chips, "发送公共红包")
	if ok == false then
		unilight.info("玩家发送公共红包失败，金币不足 uid:" .. uid .. "	remainder:" .. remainder)
		return false, remainder
	end

	local userInfo = chessuserinfodb.RUserInfoGet(uid)
	local timeSend = chessutil.FormatDateGet()

	local luckMoney = {
		_id 			= _id,					-- 红包id 字符串
		allChips 		= chips,				-- 红包总金额
		surplusChips	= chips,				-- 红包剩余金额
		number 			= number,				-- 红包个数
		surplusNumber 	= number,				-- 红包剩余个数
		bless 			= bless,				-- 红包祝福语
		timeSend 		= timeSend,				-- 发送时间
		sendInfo = {							-- 发送人信息
			uid 		= uid,
			headUrl 	= userInfo.base.headurl,
			nickName 	= userInfo.base.nickname,
		},
		getInfo  		= {},					-- 领取者信息  （数组）
	}

	unilight.savedata(PUB_LUCK_MONEY_DB_NAME, luckMoney)

	-- 红包发送 广播
	local doInfo = "Cmd.SendLuckMoneyPubCmd_Brd"
	local doData = {
		_id 	= _id,
		uid 	= uid,
		headUrl = userInfo.base.headurl,
		nickName= userInfo.base.nickname,
	}
	RoomMgr.CmdMsgBrd(doInfo, doData, roomId)

	unilight.info("玩家发送公共红包成功 uid:" .. uid .. "	chips:" .. chips .. "	number:" .. number)
	return true, remainder
end


-- 领取红包
function CmdGetLuckMoney(uid, _id)
	local luckMoney = unilight.getdata(PUB_LUCK_MONEY_DB_NAME, _id)
	if luckMoney == nil then
		unilight.info("公共红包领取失败 并不存在该红包 _id:" .. _id)
		return 54
	end

	-- 查看红包是否还有
	if luckMoney.surplusNumber == 0 then 
		unilight.info("公共红包领取失败 红包已被抢光了")
		return 55, luckMoney.sendInfo, _, _, luckMoney.bless
	end 

	local userInfo = chessuserinfodb.RUserInfoGet(uid)

	-- 随机一个金额
	local money = GetRandomChips(luckMoney.surplusNumber, luckMoney.surplusChips)

	-- 红包领取
	local remainder, ok = chessuserinfodb.WChipsChange(uid, 1, money, "领取公共红包")

	-- 红包数据更新 
	luckMoney.surplusChips		= luckMoney.surplusChips - money				
	luckMoney.surplusNumber 	= luckMoney.surplusNumber - 1
	local getinfo = {
		uid = uid,
		headUrl = userInfo.base.headurl,
		nickName = userInfo.base.nickname,
		get = money,
	}
	table.insert(luckMoney.getInfo, getinfo)

	-- 如果当前为最后一个领取红包的玩家 则 选出 最佳
	if luckMoney.surplusNumber == 0 then
		local best_index = 0
		local best = 0
		for i,v in ipairs(luckMoney.getInfo) do
			if v.get > best then
				best_index = i
				best = v.get
			end
		end
		luckMoney.getInfo[best_index].isBest = true
	end

	unilight.savedata(PUB_LUCK_MONEY_DB_NAME, luckMoney)

	local record = {
		_id = _id,									-- 红包id
		uid = luckMoney.sendInfo.uid,				-- 谁送的红包
		headUrl = luckMoney.sendInfo.headUrl, 		-- 谁发的
		nickName = luckMoney.sendInfo.nickName, 	-- 昵称
		get = money,								-- 领了多少钱
		rcvTime = chessutil.FormatDateGet() 		-- 当前领取时间
	}
	-- 玩家领取记录更新
	UpdateRcvRecord(uid, record)

	unilight.info("玩家领取红包成功 uid:" .. uid .. "	chips:" .. money)
	return 1, luckMoney.sendInfo, money, remainder, luckMoney.bless
end

-- 领取记录更新
function UpdateRcvRecord(uid, record)
	local rcvrecord = unilight.getdata(RCV_PUB_LUCK_MONEY_DB_NAME, uid)
	if rcvrecord == nil then
		-- 新建一条 红包领取记录
		rcvrecord = {
			uid = uid,
			record = {},
		}
	end

	-- 数据插入
	table.insert(rcvrecord.record, record)
	-- 存进数据库
	unilight.savedata(RCV_PUB_LUCK_MONEY_DB_NAME, rcvrecord)
end

-- 获取发送过的红包记录
function SendLuckMoneyGet(uid)
	local sendLuckMoneyRecords = {} -- 已发送的红包记录

	local sendLuckMoney = unilight.chainResponseSequence(unilight.startChain().Table(PUB_LUCK_MONEY_DB_NAME).Find(unilight.field("sendInfo.uid").Eq(uid).M))
	if sendLuckMoney == nil then
		return sendLuckMoneyRecords
	end

	-- 取出前端需要的部分数据即可
	for k,v in pairs(sendLuckMoney) do
		local sendLuckMoneyRecord = {
			_id 	= v._id,
			bless 	= v.bless,
			chips 	= v.allChips,
		}
		table.insert(sendLuckMoneyRecords, sendLuckMoneyRecord)
	end
	return sendLuckMoneyRecords
end

-- 获取领取过的红包记录
function RcvLuckMoneyGet(uid)
	-- 读取数据库
	local rcvLuckMoney = unilight.getdata(RCV_PUB_LUCK_MONEY_DB_NAME, uid)
	if rcvLuckMoney == nil then
		return {}
	end
	return rcvLuckMoney.record
end

-- 获取指定红包详情
function CmdLuckMoneyGetById(_id)
	
	local luckMoney = unilight.getdata(PUB_LUCK_MONEY_DB_NAME, _id)
	if luckMoney == nil then
		return 54
	end
	return 1, luckMoney.getInfo
end


-- 获取公共红包相关记录 
function GetRecordLuckMoneyPub(uid)
	-- 获取红包发送记录
	local sendLuckMoneyRecords = SendLuckMoneyGet(uid)

	-- 获取红包领取记录
	local rcvLuckMoneyRecords = RcvLuckMoneyGet(uid)

	return sendLuckMoneyRecords, rcvLuckMoneyRecords
end

