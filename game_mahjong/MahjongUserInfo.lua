module('UserInfo', package.seeall) -- 用户信息

if UserInfoClass == nil then
	CreateClass("UserInfoClass")
end
UserInfoClass:SetClassName("User")

GlobalUserInfoMap = {} --  玩家在线信息全局管理 
GlobalUserDataMap = {} --  玩家数据库信息全局管理 ,大厅发来的



-- print: 获取玩家uid
function UserInfoClass:GetId()
	return self.data.uid
end
-- print: 获取玩家昵称
function UserInfoClass:GetName()
	local name = self.data.base.nickname 
    if self.state.seat ~= nil then
        name = name ..":"..self.state.seat.owner.id
    end
	return name
end

-- db: 注册玩家
function UserRegister(uid, init)
	local userdata = CreateUserData(uid, init)
	return userdata
end
-- db: 构造玩家具体信息
function CreateUserData(uid, userdata)  
	if userdata == nil then
		userdata = GlobalUserDataMap[uid]
		if userdata == nil then
			userdata = {
				uid = uid, 
				base = {
					headurl = "http://img.123.com.cn/img/" .. uid%350 .. ".jpg",
					nickname = "" .. uid,
					seatId = 1,
					gender  = "男", 
					diamond = math.random(30,100),
					points = 0,--self.state.seat.point,
					ip = "8.8.8.8", 
					flower = {},
				},
			}
			CreateUserMahjongData(userdata, init)
		end
	end
	GlobalUserDataMap[uid] = userdata
	return userdata
end
-- db：针对麻将初始化内容
function CreateUserMahjongData(userdata, init)
	userdata.mahjong = {
            diamond = 100,
            --changecoin = 0,
	}
end

-- db: 保存玩家的信息,不一定在桌子上
function SaveUserData(userdata)
	chessuserinfodb.SaveUserData(userdata)
end
-- db: 得到一个玩家信息,不一定在线
function GetUserDataById(uid)
	return GlobalUserDataMap[uid]
end

-- info: 得到一个玩家信息
function GetUserInfoById(uid)
	return GlobalUserInfoMap[uid]
end
-- info: 获取玩家基础数据
function UserInfoClass:GetBaseInfo(requestinfo)
	return GetUserBaseInfo(self,requestinfo)
end
-- info: 获取玩家基础数据
function GetUserBaseInfo(userinfo,requestuser)
	local userBaseInfo = {
		uid = userinfo.data.uid,
		headurl = userinfo.data.base.headurl,
		nickname = userinfo.data.base.nickname,
		gender  = userinfo.data.base.gender, 
		diamond = userinfo.data.mahjong.diamond,
		--flower = userinfo.data.base.flower,
		points = userinfo.state.seat.point,
		seatId = userinfo.state.seat:GetClientId(requestuser),
		ip = userinfo.state.ip,
		onlineState = userinfo.state.onlineState,
		sid = userinfo.state.seat.id,
		lat = userinfo.state.lat,
		lng = userinfo.state.lng,
	}
	if userinfo.data.base.flower then
		userBaseInfo.flower = {}
		userinfo.data.base.flower = userinfo.data.base.flower or {}
		for k,v in pairs(userinfo.data.base.flower) do
			table.insert(userBaseInfo.flower,{id=k,num=v,})
		end
	end
	if userinfo.state.seat.bReady and userinfo.state.seat.owner:IsAllReady() == false then
		userBaseInfo.bReady = 1
	end
	if table.len(userinfo.state.seat.handCard) > 0 then
		userBaseInfo.handCardNum = table.len(userinfo.state.seat.handCard)
	end
	if userinfo.state.hostType and userinfo.state.hostType ~= 0 then
		userBaseInfo.onlineState = 5 --托管状态OnlineState
	end
	return userBaseInfo
end


--连接大厅成功
function LobbyConnect(cmd,lobbytask)
	lobbytask.Info("区服务器回调：新的大厅链接成功:"..table.len(GlobalUserInfoMap))
	for k,v in pairs(GlobalUserInfoMap) do
		v:Debug("重连后同志大厅连接信息")
		if v.state.seat.owner:IsLearnRooom() == false then
			ChessToLobbyMgr.SendEnterRoomToLobby(v.state.seat.owner.id, v.id,v.state.seat.id)
		end
	end
end
-- action: 上桌
function UserIntoRoom(room, laccount)
	local uid = laccount.Id
	local userdata = UserInfo.GetUserDataById(uid)
	if userdata == nil then
		return 
	end
	local userinfo = UserInfoClass:New()
	userinfo.id = uid
	userinfo.data = userdata
	userinfo.name = userinfo.data.base.nickname
	userinfo.state = {
		onlineState = 0, --OnlineState
		laccount = laccount,
		ip = laccount.GetLoginIpstr(),
		hostType = 0,
		notifyMsg = nil, --短信通知
		--hostType = 1,
		--timerOneSec = NewUniTimerClass(UserInfoClass.TimerOneSec, 1000,userinfo), --托管时间以秒为单位 
	}
	--if unilight.getdebuguser() == "WHJ" then
	--	userinfo.state.jsonCompress = defaultJsonCompress
	--	userinfo.state.jsonCompress.owner = userinfo
	--end
	if unilight.getgameid() == 4055 and userinfo.data.base.nickname == "" .. userinfo.id then
		userinfo.data.base.nickname = TableRobotUserInfo[userinfo.id%350+1].nickname --暂时先用前350吧,WHJ
		userinfo.state.robot = true
		if userinfo.id%4 == 0 then 
			userinfo.state.ip = 106 .. "." .. 224 .. "." .. math.random(1,254) .. "." .. math.random(1,254)
		elseif userinfo.id%4 == 1 then 
			userinfo.state.ip = 182 .. "." .. 96 .. "." .. math.random(1,254) .. "." .. math.random(1,254)
		elseif userinfo.id%4 == 2 then 
			userinfo.state.ip = 111 .. "." .. 72 .. "." .. math.random(1,254) .. "." .. math.random(1,254)
		elseif userinfo.id%4 == 3 then 
			userinfo.state.ip = 117 .. "." .. 40 .. "." .. math.random(1,254) .. "." .. math.random(1,254)
		end
	end
	userinfo.name = userinfo.data.base.nickname
	userinfo.state.msglist = {}
	if room:AddNewUser(userinfo) == true then
		userinfo:Debug("进入房间")
		GlobalUserInfoMap[uid] = userinfo
	else
		userinfo:Error("进入房间失败")
		userinfo = nil
	end
	return userinfo
end

function UserInfoClass:CheckDissolveRoom()
	if self.state.seat.owner.state.dissoveEvent then
		if self.state.seat.owner.state.Dissolver ~= self and self.state.seat.owner.state.Dissolver.state.seat then
			self.state.seat.owner:DoDissolveRoom(self.state.seat.owner.state.Dissolver,self)
		end
		for k,v in ipairs(self.state.seat.owner.state.seats) do
			if v.isAgreeDissolve == 1 and v.playerInfo and v.playerInfo ~= self then
				self.state.seat.owner:DoReplyDissolveRoom(v.playerInfo,{data={isAgree=1,},},self)
			end
		end
		--self.state.seat.owner.state.dissoveEvent = nil --有人上线就取消解散超时等待
	end
end
-- action: 玩家上线
function UserInfoClass:Online()
	if self.state.onlineState == 0 then
	end
	self.state.onlineState = 1 --OnlineState
	self:BroadcastOnlineState()
	self:Debug("Online")
	self.state.opEvent = nil
	self.state.notifyMsg = nil
	self.state.notifyMsgEvent = nil
	self.state.offlineEvent = nil

	--self.state.dissoveEvent = nil --有人上线就取消解散超时等待
	self:AddBroadcast(self.state.laccount)
	self:CheckDissolveRoom()
	--if self.state.dissolveRoomEvent then
		--self:EventDissolveRoom(self,{data={isAgree=0,},})
	--end
	--self.state.dissolveRoomEvent = nil
end
function UserInfoClass:SendWarnToUser(title,msec)
	msec = msec or 5000
        if self.state.notifyMsg == nil then 
		self.state.notifyMsg = title
		self.state.notifyMsgEvent = NewUniEventClass(UserInfoClass.EventWarnToUser, msec,1,self)
		self:SendCmdToMe("Cmd.ServerEchoMahjongCmd_SC",{id=1,})
	end
end
function UserInfoClass:EventWarnToUser(me)
	local self = self or me
        if self.state.notifyMsg ~= nil then 
		if self.state.notifyMsg ~= "" then
			local title = self.state.notifyMsg --东先还没用
			local msg = title
			local timestamp = os.time()
			local userData = {
				accid = self.id, 
				charid = self.id, 
				charname = self.data.base.nickname,
				imei = self.data.base.imei,
				osname = self.data.base.osname,
			}    
			local userDataTable = {} 
			table.insert(userDataTable, userData)
			uniplatform.requestpushiosmessage(title, msg, timestamp, userDataTable)
			self:Info("推送苹果消息IOS")
		end
		self.state.notifyMsg = ""
		self.state.notifyMsgEvent = nil
        end  
end

function UserInfoClass:BroadcastOnlineState()
	if self.state.seat then
		local state = self.state.onlineState
		if self.state.hostType and self.state.hostType ~= 0 then
			state = 5 --托管状态OnlineState
		end
		self.state.seat.owner:Broadcast("Cmd.OnlineStateMahjongCmd_Brd", {uid=self.id,state=state,},true)
	end
end
function UserInfoClass:EventLearnRoomTimeOut(me)
	local self = self or me
	if self.state.onlineState == 0 then
		self.state.seat.owner:DoLeaveRoom(self)
		self:Error("退出桌子等待超时,房间解散:"..self.state.seat.owner.id)
	end
end
function UserInfoClass:Offline()
	if self.state.seat.owner:IsLearnRooom() then
		self.state.offlineEvent = NewUniEventClass(UserInfoClass.EventLearnRoomTimeOut, 1000000,1,self) 
	end
	local seat = self.state.seat
	if seat then
		if not seat.bReady then
			--if not seat.owner.base.prepareType == 1 then
				--seat.owner:DoReadyStart(self) --离线时强制指定准备状态
				--seat.owner:CheckStart()
			--else
			--end
		end
		if seat.owner:IsDissolveRooming() then
			if seat.isAgreeDissolve ~= 1 then
				--self:EventDissolveRoom(self,{data={isAgree=0,},})
				--seat.isAgreeDissolve = 1
				--seat.owner:CheckDissolveRoomOk()
			end
		end
	end
	self:RemoveBroadcast()
	self.state.laccount = nil
	self.state.onlineState = 0
	--self:RemoveRoomUserInfo(self) --不能在这里删除,只能destroy的时候
	self:BroadcastOnlineState()
	self:Debug("离开桌子")
	--SaveUserData(self.data)
end
function UserInfoClass:Destroy()
	self:RemoveBroadcast()
	self.state.laccount = nil
	self.state.onlineState = 0
	self:RemoveRoomUserInfo(self)
	--self:BroadcastOnlineState()
	--SaveUserData(self.data)
end

function UserInfoClass:AddBroadcast(laccount)
	self.state.laccount = laccount
	if self.state.seat then -- 这里有一种情况的确为空,换座位的时候
		self.state.seat.owner.state.broadcastRoom.Rum.AddRoomUser(laccount)
	end
end

function UserInfoClass:RemoveBroadcast()
	if self.state.laccount and self.state.seat then
		self.state.seat.owner.state.broadcastRoom.Rum.RemoveRoomUser(self.state.laccount)
	end
end

-- action: 删除一个玩家byuid
function UserInfoClass:RemoveRoomUserInfo()
    unilight.info("user leave room " .. self.id)
	GlobalUserInfoMap[self.id] = nil
end
-- action: 删除一个玩家
function RemoveRoomUserInfo(userinfo)
	GlobalUserInfoMap[userinfo.data.uid] = nil
end

function UserInfoClass:Loop()
	local oldEvent = self.state.opEvent
	if oldEvent and oldEvent:Check(unitimer.now) == true and oldEvent.maxtimes <= 0 and oldEvent == self.state.opEvent then
		 self.state.opEvent = nil
	end
	if self.state.timerOneSec then
		self.state.timerOneSec:Check(unitimer.now)
	elseif next(self.state.msglist) ~= nil then --这里为了防止消息加了,但忘记处理,最终消息太多cpu就废了
		self:Error("发现严重问题,消息被托管却没有处理:"..table.len(self.state.msglist))
		self.state.msglist={}
	end
	if self.state.notifyMsgEvent then
		self.state.notifyMsgEvent:Check(unitimer.now)
	end
	if self.state.offlineEvent then
		self.state.offlineEvent:Check(unitimer.now)
	end
	if self.state.dissolveRoomEvent then
		self.state.dissolveRoomEvent:Check(unitimer.now)
	end
end
function UserInfoClass:EventTimeOutLeaveRoom(me,msg)
	local self = self or me
	self.state.seat.owner:DoLeaveRoom(self)
	self:Error("未准备状态超时踢")
end

function UserInfoClass:SendStringToMe(s,ignore_record)
	if self.state.laccount then
		self.state.laccount.SendString(s)
	end
	if self.state.hostType > 0 then
		table.insert(self.state.msglist,s)
	end
	if not ignore_record and self.state and self.state.seat then
		self.state.seat.owner:AddRecordMsg(self.id,s)
	end
end
-- broadcast: 广播消息给具体玩家
function UserInfoClass:SendCmdToMe(doinfo, data,ignore_record)
	local send = {}
	send["do"] = doinfo
	send["data"] = data
	if self.state.jsonCompress then
		send = self.state.jsonCompress:Compress(send)
	end
	local s = json.encode(send)
	self:SendStringToMe(s,ignore_record)
	self:Debug("sendCmdToMe:" .. s)
	--s = json.encode(send)
	--if self.state.seat then
		--table.insert(self.state.seat.owner.data.msglist,{uid=self.id,brd=nil,msg=s,})
	--end
	return s
end
function UserInfoClass:SendCmdToMeHost(doinfo, data)
	local send = {}
	send["do"] = doinfo
	send["data"] = data
	if self.state.jsonCompress then
		send = self.state.jsonCompress:Compress(send)
	end
	local s = json.encode(send)
	if self.state.hostType > 0 then
		table.insert(self.state.msglist,s)
	end
end
function UserInfoClass:SendFailToMe(msg,pos)
	local data = {
		desc=msg,
		pos = pos,
	}
	self:SendCmdToMe("Cmd.SysMessageMahjongCmd_S",data,true) --系统消息不录像
end
function SendCmd(doinfo, data, laccount)
	local send = {}
	send["do"] = doinfo
	send["data"] = data
	local s = json.encode(send)
	if laccount then
		laccount.SendString(s)
		laccount.Info("sendCmdToMe" .. s)
	else
		unilight.error("sendCmdToMe" .. s)
	end
end
function UserInfoClass:IsRobot()
	return false
end

function UserInfoClass:EventOutCard(me,msg)
	local self = self or me
	local card = nil
	if msg.data.listenSet then
		local thisId = msg.data.listenSet[1]
		local remainNum = 0
		if msg.data.listenObjSet then
			for k,v in ipairs(msg.data.listenObjSet) do
				local tmp = 0
				if v.listenCardSet ~= nil then
					for k1,v1 in ipairs(v.listenCardSet) do
						tmp = tmp + self.state.seat:GetRemainNumByBaseId(math.floor(v1.thisId/10))
					end
				else
					for k1,v1 in ipairs(v) do
						if v1[2] ~= nil then
							tmp = tmp + v1[2]
						end
					end
				end
				if remainNum < tmp then
					remainNum = tmp
					thisId = msg.data.listenSet[k]
				end
			end
		end
		self.state.seat.owner:DoOutCard(self,thisId)
		--if remainNum > 0 then --一旦听牌,就不再换牌
		self.state.seat.listen = true
	else
		self.state.seat.listen = false
		--if self.state.seat.owner.data.hostType and self.state.seat.owner.data.hostType == 1 then --傻瓜式托管
		--if self.state.seat.owner.data.hostType and self.state.seat.owner.data.hostType == 1 then --傻瓜式托管(暂时屏蔽,因为金华客户端有bug)
		--	self.state.seat.owner:DoOutCard(self,msg.data.thisId)
		--else
			local card = self.state.seat:GetOneCard()
			--这里判断是否是金牌,不打
			self.state.seat.owner:DoOutCard(self,card.base.thisid)
		--end
	end
end
function UserInfoClass:EventBarCard(me,msg)
	local self = self or me
	local thisId = msg.data.thisId
	if msg.data.barSet then
		thisId = msg.data.barSet[1]
	end
	if self.state.seat:CheckCanOperate(2,thisId) == false then
		self.state.seat.owner:DoCancelOperate(self)
		return nil
	end
	self.state.seat.owner:DoBarCard(self,thisId)
end
function UserInfoClass:EventSupplyCard(me,msg)
	local self = self or me
	local thisId = msg.data.thisId
	if msg.data.supplySet then
		thisId = msg.data.supplySet[1]
	end
	if self.state.seat:CheckCanOperate(2,thisId) == false then
		self.state.seat.owner:DoCancelOperate(self)
		return nil
	end
	if self.state.seat.owner.DoJudgeOperate then
		self.state.seat.owner:DoJudgeOperate(self,{thisId=thisId,},3)
	end
end

function UserInfoClass:EventTouchCard(me,msg)
	local self = self or me
	if self.state.seat:CheckCanOperate(6,msg.data.thisId) == false then
		self.state.seat.owner:DoCancelOperate(self)
		return
	end
	if self:CheckNeedTouch(msg) then
		self.state.seat.owner:DoTouchCard(self,msg.data.thisId)
	else
		self.state.seat.owner:DoCancelOperate(self)
	end
end
function UserInfoClass:CheckNeedTouch(msg)
	return not self.state.seat.listen
end
function UserInfoClass:CheckNeedEat(msg)
	if self.state.seat:GetHandCardNumByBaseId(math.floor(msg.data.thisId/10)) > 0 then
		return false
	end
	return not self.state.seat.listen
end
function UserInfoClass:EventEatCard(me,msg)
	local self = self or me
	if self.state.seat:CheckCanOperate(7,msg.data.thisId) == false then
		self.state.seat.owner:DoCancelOperate(self)
		return
	end
	if self:CheckNeedEat(msg) then
		local best = nil
		local maxnum = 0
		for k,v in pairs(msg.data.eatSet) do
			best = best or v
			local tmp = self.state.seat:GetHandCardNumByBaseId(v.one) + self.state.seat:GetHandCardNumByBaseId(v.two)
			if maxnum == 0 or tmp < maxnum then
				best = v
			elseif table.len(msg.data.eatSet) == 2 then
				if msg.data.thisId - v.one == 2 or v.two - msg.data.thisId == 2 then --2,3,4,5 吃4的话用2,3,4 吃
					best = v
				end
			elseif table.len(msg.data.eatSet) == 3 then
				if  v.two  == 9 then --2,3,4,5,6 吃4的话用2,3,4 吃
					best = v
				end
			end
		end
		if best then
			self.state.seat.owner:DoEatCard(self,best.one,best.two)
			self:Info("请求吃牌:"..best.one .. ":" .. best.two .. ":" .. msg.data.thisId)
		end
	else
		self.state.seat.owner:DoCancelOperate(self)
	end
end

function UserInfoClass:EventWinCard(me,msg)
	local self = self or me
	self.state.seat.owner:DoWinCard(self)
	if self.state.seat.owner.state.round ~= nil then
		self.state.seat.owner.state.round.newOutCard = nil --清空,不然断线重连后会报错
	end
end

function UserInfoClass:EventDissolveRoom(me,msg)
	local self = self or me
	self.state.dissolveRoomEvent = nil
	self.state.seat.owner:DoReplyDissolveRoom(self,{data={isAgree=msg.data.isAgree,},})
end

function UserInfoClass:ResetOpEvent(event)
	if self.state.opEvent then
		self.state.opEvent:Check(unitimer.now,true)
	end
	self.state.opEvent = event
end
function UserInfoClass:TimerOneSec(me)
	local optime = 900
	if unilight.getgameid() == 4055 and self.state.robot  then
		optime = math.random(900,4000)
	end
	local self = self or me
	local tmp = self.state.msglist
	self.state.msglist = {}
	for k,v in ipairs(tmp) do
		local msg = json.decode(v)
		if self.state.jsonCompress then
			msg = self.state.jsonCompress:DeCompress(msg)
		end
		if msg["do"] == "Cmd.StartMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.EnterMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.SetBankerMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.SelfCardMahjongCmd_S" then
			self.userCard = msg.data.userCard
		elseif msg["do"] == "Cmd.FlowerMahjongCmd_Brd" then
			if self.userCard then
				self.userCard.flowerCardSet = self.userCard.flowerCardSet or {}
				table.insert(self.userCard.flowerCardSet , msg.data.flowerSet)
			end
		elseif msg["do"] == "Cmd.TurnGoldMahjongCmd_Brd" then
			self.goldCard = msg.data.cardSet
		elseif msg["do"] == "Cmd.SendCardMahjongCmd_S" then

			if msg.data and msg.data.opType then
				for _,op in ipairs(msg.data.opType) do
					if op == 1 or table.find({11,19,20,21,25}, op) ~= nil then
						self:ResetOpEvent(NewUniEventClass(UserInfoClass.EventWinCard, optime,1,self,self,msg))
						break
					elseif op == 2 then
						self:ResetOpEvent(NewUniEventClass(UserInfoClass.EventBarCard, optime,1,self,self,msg))
						break
					elseif op == 3 then
						self:ResetOpEvent(NewUniEventClass(UserInfoClass.EventSupplyCard, optime,1,self,self,msg))
						break
					elseif table.find({14,15,16}, op) ~= nil then
						if msg.data.goldOutCardSet then
							self.state.seat.owner:DoOutCard(self,msg.data.goldOutCardSet[1])
						else
							self:ResetOpEvent(NewUniEventClass(UserInfoClass.EventOutCard, optime,1,self,self,msg))
						end
						break
					else
						self:Error("未处理操作类型:"..op)
					end
				end
				if not self.state.opEvent then
					self.state.seat.owner:DoCancelOperate(self)
				end
			elseif math.floor(msg.data.thisId/100) == 5 then
				self:Error("忽略花牌:"..msg.data.thisId)
			else
				self:ResetOpEvent(NewUniEventClass(UserInfoClass.EventOutCard, optime,1,self,self,msg))
			end
		elseif msg["do"] == "Cmd.OutCardMahjongCmd_S" then
			self.winCardSet = msg.data.winCardSet
		elseif msg["do"] == "Cmd.OutCardMahjongCmd_Brd" then
			if msg.data.opType then
				self:Info("操作牌:" .. json.encode(msg))
				for _,op in ipairs(msg.data.opType) do
					if op == 1 then
						self:ResetOpEvent(NewUniEventClass(UserInfoClass.EventWinCard, optime,1,self,self,msg))
						break
					elseif op == 2 then
						self:ResetOpEvent(NewUniEventClass(UserInfoClass.EventBarCard, optime,1,self,self,msg))
						break
					elseif op == 3 then
						self:ResetOpEvent(NewUniEventClass(UserInfoClass.EventSupplyCard, optime,1,self,self,msg))
						break
					elseif op == 6 then
						self:ResetOpEvent(NewUniEventClass(UserInfoClass.EventTouchCard, optime,1,self,self,msg))
						break
					elseif op == 7 then
						self:ResetOpEvent(NewUniEventClass(UserInfoClass.EventEatCard, optime,1,self,self,msg))
						break
					else
						self:Error("未处理操作类型:"..op)
					end
				end
				if not self.state.opEvent then
					self.state.seat.owner:DoCancelOperate(self)
				end
			end
		elseif msg["do"] == "Cmd.SendCardMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.TouchCardMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.BarCardMahjongCmd_Brd" then
			if msg.data.canWin == 1 then
				self:ResetOpEvent(NewUniEventClass(UserInfoClass.EventWinCard, optime,1,self,self,msg))
			end
		elseif msg["do"] == "Cmd.CancelOpMahjongCmd_S" then
		elseif msg["do"] == "Cmd.EatCardMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.ReadyStartMahjongCmd_Brd" then
			local already = false
			for k,v in ipairs(msg.data.readyUserSet) do
				if v == self.id  then
					already = true
				end
			end
			if already == false then
				--self.state.seat.owner:DoReadyStart(self) --这里没有必要,因为准备状态分不到cpu,用其他方法解决
			end
		elseif msg["do"] == "Cmd.LeaveMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.DrawGameMahjongCmd_Brd" then
			--self.state.seat.owner:DoReadyStart(self)
		elseif msg["do"] == "Cmd.WinRetMahjongCmd_Brd" then
			--self.state.seat.owner:DoReadyStart(self)
		elseif msg["do"] == "Cmd.OnlineStateMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.SysMessageMahjongCmd_S" then
		elseif msg["do"] == "Cmd.HostMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.ReadyStartMahjongCmd_S" then
		elseif msg["do"] == "Cmd.StartNewRoundOpCmd_Brd" then
		elseif msg["do"] == "Cmd.StartNewRoundOpCmd_S" then
			if msg.data.opType then
				self:Info("起手操作牌:" .. json.encode(msg))
				for _,op in ipairs(msg.data.opType) do
					if op == 1 then
						local ret = self.state.seat.owner:DoJudgeOperate(userInfo, {}, 1)
						break
					elseif op == 22 then
						self.state.seat.owner:DoStartSmallWin(self)
						break
					elseif op == 205 then
						self.state.seat.owner:DoBarOp(self, 205)
						break
					elseif op >= 11 and op <= 21 then
						self.state.seat.owner:DoWinCard(self)
						break
					else
						self:Error("未处理操作类型:"..op)
					end
				end
			end
		elseif msg["do"] == "Cmd.StartNewRoundOpTimeCmd_Brd" then
		elseif msg["do"] == "Cmd.SeaRoamTurnMahjongCmd_Brd" then --湖南麻将的海底漫游
			if msg.data.uid == self.id then
				self.state.seat.owner.state.opEvent = NewUniEventClass(RoomClass.EventSeaFloor, 3000, 1, self.state.seat.owner, self.state.seat.owner.state.seats[(self.state.seat.id%self.state.seat.owner.state.usernum) + 1])
			end
		elseif msg["do"] == "Cmd.RequestDissolveRoom_Brd" then
		elseif msg["do"] == "Cmd.ReplyDissolveRoom_Brd" then
			if msg.data.isAgree == 1 and not self.state.dissolveRoomEvent then
				local randtime = 10000 
				--debug下飞速
				if unilight.getdebuglevel() > 0 then
					randtime = 1
				end
				self.state.dissolveRoomEvent = NewUniEventClass(UserInfoClass.EventDissolveRoom, randtime,1,self,self,msg)
			end
		elseif msg["do"] == "" then
		elseif msg["do"] == "Cmd.CommonChat_Brd" then
		elseif msg["do"] == "Cmd.SendGiftMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.SuccessDissolveRoom_Brd" then
		elseif msg["do"] == "Cmd.WinMahjongCmd_S" then
		elseif msg["do"] == "Cmd.WinCardMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.BirdMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.SupplyCardMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.ClientEchoMahjongCmd_SC" then
		elseif msg["do"] == "Cmd.EnterMahjongCmd_S" then
		elseif msg["do"] == "Cmd.ReConnectMahjongCmd_S" then
		elseif msg["do"] == "Cmd.GetPersonalPanel_S" then
		elseif msg["do"] == "Cmd.JsonCompressNullUserPmd_CS" then
		elseif msg["do"] == "Cmd.ServerEchoMahjongCmd_SC" then
		else
			if self:DoMyRobotMessage(msg) == false then
				self:Error("遗漏处理消息:" .. json.encode(v))
			end
		end
	end
	if self.state.hostType == 0 then
		self.state.timerOneSec = nil
	end
end
function UserInfoClass:DoMyRobotMessage(msg)
	return false
end
