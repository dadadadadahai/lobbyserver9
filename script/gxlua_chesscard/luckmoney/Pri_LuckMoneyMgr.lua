module('Pri_LuckMoneyMgr', package.seeall)
-- 用来统一处理私包

CONST_DB_NAME = "luckmoney_pri"

CONST_FLAG_OKY = 0 -- 成功领取
CONST_FLAG_WAT = 1 -- 领取等待
CONST_FLAG_RTN = 2 -- 退回

LuckMoneyIndex = 1

-- 创建相关表
function CmdDbCreate()
	unilight.createdb(CONST_DB_NAME, "_id")
	unilight.createindex(CONST_DB_NAME, "uidSend")
	unilight.createindex(CONST_DB_NAME, "uidReceive")
end

function LuckMoneyIdCreate()
	local strIndex = string.format("%05d", LuckMoneyIndex)
	LuckMoneyIndex = LuckMoneyIndex + 1
	local time = os.time()
	return tostring(time) .. strIndex
end

-- 组装成客户端需求的，发给客户端
function LuckMoneyConstuct(luckMoneyServer)
	local sendUid = luckMoneyServer.uidSend
	luckMoneyServer.uidSend = nil
	local recvUid = luckMoneyServer.uidReceive 
	luckMoneyServer.uidReceive = nil 

	local sendInfo = chessuserinfodb.RUserBaseInfoGet(chessuserinfodb.RUserLoginGet(sendUid))
	local recvInfo = chessuserinfodb.RUserBaseInfoGet(chessuserinfodb.RUserLoginGet(recvUid))
	local luckMoneyClient = luckMoneyServer
	luckMoneyClient.sendInfo = sendInfo
	luckMoneyClient.recvInfo = recvInfo 
	return luckMoneyClient
end
-- 由客户端发过来了组织成我们需要的
function LuckMoneyDeConstuct(luckMoneyClient)
	local luckMoneyServer = luckMoneyClient	
	luckMoneyServer.uidSend = luckMoneyServer.sendInfo.uid
	luckMoneyServer.sendInfo = nil
	luckMoneyServer.uidReceive = luckMoneyServer.recvInfo.uid
	luckMoneyServer.recvInfo = nil
	return luckMoneyServer
end

-- 当玩家上线时检查是否有退回包，是否有待收的包
function CmdCheckLuckMoney(uid)
	local rcvLuckMoney, watLuckMoney = ReceiveLuckMoneyGet(uid)
	local sndLuckMoney, rtnLuckMoney = SendLuckMoneyGet(uid) 	
	return rcvLuckMoney, watLuckMoney, sndLuckMoney, rtnLuckMoney
end

function ReceiveLuckMoneyGet(uid)
	local receiveLuckMoney = unilight.chainResponseSequence(unilight.startChain().Table(CONST_DB_NAME).Find(unilight.field("uidReceive").Eq(uid).M))
	if table.empty(receiveLuckMoney) then
		return {}, {}
	end

	local rcvLuckMoney = {}
	local watLuckMoney = {}
	for id, luckMoney in ipairs(receiveLuckMoney) do
		if luckMoney.status == CONST_FLAG_WAT then
			local bOk, remainder, luckMoneyTmp = CmdReturnLuckMoney(luckMoney._id, false)
			if bOk == true then
				luckMoney = luckMoneyTmp
			end
		end

		if luckMoney.status == CONST_FLAG_WAT then
			table.insert(watLuckMoney, luckMoney)
		else
			table.insert(rcvLuckMoney, luckMoney)
		end
	end
	return rcvLuckMoney, watLuckMoney 
end

function SendLuckMoneyGet(uid)
	local sendLuckMoney = unilight.chainResponseSequence(unilight.startChain().Table(CONST_DB_NAME).Find(unilight.field("uidSend").Eq(uid).M))
	if table.empty(sendLuckMoney) then
		return {}, {}
	end

	local rtnLuckMoney = {} -- 要退回的包
	local sndLuckMoney = {} -- 已发送的红包
	for id, luckMoney in ipairs(sendLuckMoney) do
		-- 检测是否要退回
		if luckMoney.status == CONST_FLAG_WAT then
			local bOk, remainder, luckMoneyTmp = CmdReturnLuckMoney(luckMoney._id, false)
			if bOk == true then
				luckMoney = luckMoneyTmp
			end
		end
		if luckMoney.status == CONST_FLAG_RTN then
			table.insert(rtnLuckMoney, luckMoney)
		else
			table.insert(sndLuckMoney, luckMoney)
		end
	end

	return sndLuckMoney, rtnLuckMoney
end

-- 处理发送红包
function CmdSendLuckMoney(uidSnd, uidRev, chips, bless)
	local _id = LuckMoneyIdCreate()
	local remainder, ok = chessuserinfodb.WChipsChange(uidSnd, 2, chips, "发送私人红包")
	if ok == false then
		return false, remainder
	end
	local timeSend = chessutil.FormatDateGet()
	local luckMoney = {
		_id = _id,
		chips = chips,
		bless = bless,
		status = CONST_FLAG_WAT,
		uidSend = uidSnd,
		uidReceive = uidRev,
		timeSend = timeSend,
		bBest =true,
	}
	unilight.savedata(CONST_DB_NAME, luckMoney)
	return true, luckMoney
end

-- 处理接收红包
function CmdRevceiveLuckMoney(uid, _id)
	local luckMoney = unilight.getdata(CONST_DB_NAME, _id)
	if table.empty(luckMoney) then
		return false
	end
	-- test the uid
	if uid ~= luckMoney.uidReceive and uid ~= luckMoney.uidSend then
		unilight.error("红包领取玩家不匹配" .. uid .. " 期待接受者" .. luckMoney.uidReceive .. "或发送者" .. luckMoney.uidSend)
		return false
	end
	-- test 是否已被领取
	if luckMoney.status ~= CONST_FLAG_WAT then	
		unilight.error("红包已被领取，或者过期")
		return false
	end
	local remainder, ok = chessuserinfodb.WChipsChange(uid, 1, luckMoney.chips, "接收私人红包")
	if ok == false then
		return false, remainder
	end
	-- update
	luckMoney.timeReceive = chessutil.FormatDateGet()
	luckMoney.status = CONST_FLAG_OKY
	luckMoney.uidReceive = uid
	unilight.savedata(CONST_DB_NAME, luckMoney)
	
	return true, remainder, luckMoney
end

-- 处理退回红包
function CmdReturnLuckMoney(id, bForce)
	local luckMoney = unilight.getdata(CONST_DB_NAME, _id)
	if table.empty(luckMoney) then
		return false
	end

	if bForce == false then
		local sendTime = chessutil.TimeByDateGet(luckMoney.timeSend)	
		local currentTime = os.time()
		if currentTime - sendTime < 24*60*60 then
			return false
		end	
	end

	local uid = luckMoney.uidSend
	local remainder, ok = chessuserinfodb.WChipsChange(uid, 1, luckMoney.chips, "私人红包退回")
	if ok == false then
		return false, remainder
	end
	luckMoney.status = CONST_FLAG_RTN
	unilight.savedata(CONST_DB_NAME, luckMoney)
	return true, remainder, luckMoney
end

-- 查询红包
function CmdLuckMoneyGetById(_id)
	local luckMoney = unilight.getdata(CONST_DB_NAME, _id)
	if table.empty(luckMoney) then
		return false, {}
	end
	return true, luckMoney
end
