module('RobotInfo', package.seeall) -- 机器人信息

if RobotClass == nil then
	CreateClass("RobotClass")
end
RobotClass:SetClassName("Robot")

GlobalRobotInfoMap = {}

local robotTempidAlocate = 10000



function GetRobotInfoById(robotid)
    return GlobalRobotInfoMap[robotid]
end

function CreateRobot(room)
	local robot = RobotClass:New() 
	robotTempidAlocate = robotTempidAlocate + 1
	if robotTempidAlocate >= 100000 then
		robotTempidAlocate = 10000
	end
	robot.id = robotTempidAlocate
	robot.state = {}
	robot.base = TableRobot[1]
	robot.name = TableRobotUserInfo[robot.id%350+1].nickname --暂时先用前350吧,WHJ
	robot.state.msglist = {}
	robot.state.timerOneSec = NewUniTimerClass(RobotClass.TimerOneSec, 1000,robot) 
	GlobalRobotInfoMap[robotTempidAlocate] = robot
	robot.state.hostType = 1 --机器人设置为托管模式
	robot.state.ip = math.random(1,254) .. "." .. math.random(1,254) .. "." .. math.random(1,254) .. "." .. math.random(1,254)
	robot.data = {
		uid = robot.id, 
		base = {
		headurl = "http://img.abc.com.cn/img/" .. robot.id%350 .. ".jpg",
		nickname = robot.name,
		gender  = "男", 
		points = 0,--self.state.seat.point,
		seatId = 1,
		flower = {},
		},
	}
	robot.data.mahjong = {
		diamond = math.random(30,100),
	}
	if robot.id%3 == 1 then
		robot.data.gender  = "女"
	end
	return robot
end
function RobotClass:GetId()
	return self.id
end
function RobotClass:GetName()
	return self.name
end

function RobotClass:EventDissolveRoom(me,msg)
	local self = self or me
	local agree = 1
	if self.state.seat.owner.data.winDiamond then --赌钻石不让解散
		agree = 0
	end
	self.state.dissolveRoomEvent = nil
	self.state.seat.owner:DoReplyDissolveRoom(self,{data={isAgree=agree,},})
end
function RobotClass:EventOutCard(me,msg)
	local self = self or me
	local card = nil
	if self.state.seat.owner.state.round.barSeatMap ~= nil and self.state.seat.owner.state.round.barSeatMap[self.state.seat] ~= nil then --湖南麻将用
		return
	end
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
		--if remainNum > 0 then --牌池牌很少了或者剩余胡牌数量大于4
		self.state.seat.listen = true
	else
		self.state.seat.listen = false
		card = self.state.seat:GetOneCard()
		--这里判断是否是金牌,不打
		self.state.seat.owner:DoOutCard(self,card.base.thisid)
	end
end
function RobotClass:EventBarCard(me,msg)
	local self = self or me
	local thisId = msg.data.thisId
	if msg.data.barSet then
		thisId = msg.data.barSet[1]
	end
	if self.state.seat:CheckCanOperate(2,thisId) == false then
		self.state.seat.owner:DoCancelOperate(self)
		return nil
	end
	if self.base.canKong == 1 then
		self.state.seat.owner:DoBarCard(self,thisId)
		self:Info("请求杠牌:" .. msg.data.thisId)
	end
end
function RobotClass:EventCancelOperate(me,msg)
	local self = self or me
	self.state.seat.owner:DoCancelOperate(self)
end
function RobotClass:EventTouchCard(me,msg)
	local self = self or me
	if self.state.seat:CheckCanOperate(6,msg.data.thisId) == false then
		self.state.seat.owner:DoCancelOperate(self)
		return
	end
	if self.base.canPong == 1 and (not self.state.seat.listen or table.len(self.state.seat.handCard) <= 5) then
		self.state.seat.owner:DoTouchCard(self,msg.data.thisId)
		self:Info("请求碰牌:" .. msg.data.thisId)
	else
		self.state.seat.owner:DoCancelOperate(self)
	end
end
function RobotClass:EventEatCard(me,msg)
	local self = self or me
	if self.state.seat:CheckCanOperate(7,msg.data.thisId) == false then
		self.state.seat.owner:DoCancelOperate(self)
		return
	end
	if self.base.canChow == 1 and (not self.state.seat.listen or table.len(self.state.seat.handCard) <= 5) then
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

function RobotClass:EventWinCard(me,msg)
	local self = self or me
	if self.base.canWin == 1 then
		self.state.seat.owner:DoWinCard(self)
		if self.state.seat.owner.state.round ~= nil then
			self.state.seat.owner.state.round.newOutCard = nil --清空,不然断线重连后会报错
			self:Error("请求赢牌:")
		end
	else
		self.state.seat.owner:DoCancelOperate(self)
	end
end
function RobotClass:EventSupplyCard(me,msg)
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


function RobotClass:ResetOpEvent(event)
	if self.state.opEvent then
		self.state.opEvent:Check(unitimer.now,true)
	end
	self.state.opEvent = event
end
function RobotClass:TimerOneSec(me)
	local self = self or me
	local tmp = self.state.msglist
	self.state.msglist = {}
	if table.len(tmp) > 0 then
		--self:Error("zzz:" .. json.encode(self.state.seat:GetUserCard()))
	end
	local opTime = math.random(self.base.outTime.minTime,self.base.outTime.maxTime)
	if unilight.getdebuglevel() > 0 then
		opTime = math.floor(opTime/10)
	end
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
			self.userCard.flowerCardSet = self.userCard.flowerCardSet or {}
			table.insert(self.userCard.flowerCardSet , msg.data.flowerSet)
		elseif msg["do"] == "Cmd.TurnGoldMahjongCmd_Brd" then
			self.goldCard = msg.data.cardSet
		elseif msg["do"] == "Cmd.SendCardMahjongCmd_S" then
			
			if msg.data and msg.data.opType then
				for _,op in ipairs(msg.data.opType) do
					if op == 1 or table.find({11,19,20,21,25}, op) ~= nil then
						if math.random(1,40) == 1 then --机器人不能太厉害
							self:ResetOpEvent(NewUniEventClass(RobotClass.EventWinCard, opTime,1,self,self,msg))
						else
							self:ResetOpEvent(NewUniEventClass(RobotClass.EventOutCard, opTime,1,self,self,msg))
						end
						break
					elseif op == 2 then
						self:ResetOpEvent(NewUniEventClass(RobotClass.EventBarCard, opTime,1,self,self,msg))
						break
					elseif op == 3 then
						self:ResetOpEvent(NewUniEventClass(RobotClass.EventSupplyCard, opTime,1,self,self,msg))
						break
					elseif table.find({14,15,16}, op) ~= nil then
						if msg.data.goldOutCardSet then
							self.state.seat.owner:DoOutCard(self,msg.data.goldOutCardSet[1])
						else
							self:ResetOpEvent(NewUniEventClass(RobotClass.EventOutCard, opTime,1,self,self,msg))
						end
						break
					else
						self:Error("未处理操作类型:"..op)
						self:ResetOpEvent(NewUniEventClass(RobotClass.EventOutCard, opTime,1,self,self,msg))
					end
				end
			elseif math.floor(msg.data.thisId/100) == 5 then
				self:Error("忽略花牌:"..msg.data.thisId)
			else
				self:ResetOpEvent(NewUniEventClass(RobotClass.EventOutCard, opTime,1,self,self,msg))
			end
		elseif msg["do"] == "Cmd.OutCardMahjongCmd_S" then
			self.winCardSet = msg.data.winCardSet
		elseif msg["do"] == "Cmd.OutCardMahjongCmd_Brd" then
			if msg.data.opType then
				self:Info("操作牌:" .. json.encode(msg))
				local bestop = nil
				for _,op in ipairs(msg.data.opType) do
					bestop = bestop or op
					if bestop == 1 and op == 7 then --机器人暂时不吃胡,不然P胡太多了
						bestop = op
					end
				end
				if bestop == 2 then
					self:ResetOpEvent(NewUniEventClass(RobotClass.EventBarCard, opTime,1,self,self,msg))
					break
				elseif bestop == 6 then
					self:ResetOpEvent(NewUniEventClass(RobotClass.EventTouchCard, opTime,1,self,self,msg))
					break
				elseif bestop == 1 or (bestop >= 11 and bestop  <= 21) then --机器人不能太厉害,只能单吊胡和碰胡
					if msg.data.uid and msg.data.uid > 1000000 then --机器人只抓胡玩家,不抓胡机器人
						self:ResetOpEvent(NewUniEventClass(RobotClass.EventWinCard, opTime,1,self,self,msg))
					else
						self:ResetOpEvent(NewUniEventClass(RobotClass.EventCancelOperate, opTime,1,self,self,msg))
					end
					break
				elseif op == 3 then
					self:ResetOpEvent(NewUniEventClass(RobotClass.EventSupplyCard, opTime,1,self,self,msg))
					break
				elseif bestop == 7 then
					self:ResetOpEvent(NewUniEventClass(RobotClass.EventEatCard, opTime,1,self,self,msg))
					break
				else
					self:Error("未处理操作类型:"..bestop)
					self:ResetOpEvent(NewUniEventClass(RobotClass.EventCancelOperate, opTime,1,self,self,msg))
				end
			end
		elseif msg["do"] == "Cmd.SendCardMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.TouchCardMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.BarCardMahjongCmd_Brd" then
			if msg.data.canWin == 1 then
				self:ResetOpEvent(NewUniEventClass(RobotClass.EventWinCard, opTime,1,self,self,msg))
			end
		elseif msg["do"] == "Cmd.CancelOpMahjongCmd_S" then
		elseif msg["do"] == "Cmd.EatCardMahjongCmd_Brd" then
		elseif msg["do"] == "Cmd.ReadyStartMahjongCmd_Brd" then
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
						if self.state.seat.owner.DoJudgeOperate then
							local ret = self.state.seat.owner:DoJudgeOperate(userInfo, {}, 1)
						end
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
				self.state.seat.owner.state.opEvent = NewUniEventClass(RoomClass.EventSeaFloor, 3000, 1, self.state.seat.owner, self.state.seat.owner.state.seats[(self.state.seat.id % self.state.seat.owner.state.usernum) + 1])
			end
		elseif msg["do"] == "Cmd.RequestDissolveRoom_Brd" then
		elseif msg["do"] == "Cmd.ReplyDissolveRoom_Brd" then
			if msg.data.isAgree == 1 and not self.state.dissolveRoomEvent then
				local randtime = 1 --debug下飞速
				if unilight.getdebuglevel() > 0 then
					randtime = math.random(2000,5000)
				end
				self.state.dissolveRoomEvent = NewUniEventClass(RobotClass.EventDissolveRoom, randtime,1,self,self,msg)
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
			if self:DoMyRobotMessage(msg, opTime) == false then
				self:Error("遗漏处理消息:" .. json.encode(v))
			end
		end
	end
	if table.len(tmp) > 0 then
		--self:Error("ZZZ:" .. json.encode(self.state.seat:GetUserCard()))
	elseif self.state.seat.bReady and not self.state.seat.owner.data.sendFlower then --没有操作就给个概率讲话
		if math.random(1,200) == 1 then
			self.state.seat.owner:Broadcast("Cmd.CommonChat_Brd", {uid=self.id,voiceId=math.random(11,25),})
		end
		if math.random(1,200) == 1 then
			self.state.seat.owner:Broadcast("Cmd.SendGiftMahjongCmd_Brd", {gift={toUid=0,fromUid=self.id,giftsNum=1,giftsId=math.random(1,6)},fromid=self.id})
		end
	end
end
function RobotClass:DoMyRobotMessage(msg, opTime)
	return false
end
function RobotClass:Loop()
	if self.state.seat.owner.state.operateSeat == self.state.seat and self.state.opEvent == nil then
	end
	local oldEvent = self.state.opEvent
	if oldEvent and oldEvent:Check(unitimer.now) == true and oldEvent.maxtimes <= 0 and self.state and oldEvent == self.state.opEvent then
		 self.state.opEvent = nil
	end
	if self.state then --这里有可能已经为空了,因为最后一局结束会销毁自己
		self.state.timerOneSec:Check(unitimer.now)
		if self.state.dissolveRoomEvent then
			self.state.dissolveRoomEvent:Check(unitimer.now)
		end
	end
	
end
function RobotClass:LeaveRoom()
	if self.state.seat ~= nil then
		self.state.seat.owner:DoLeaveRoom(self)
	end
	self:Debug("退出桌子")
	return true
end
function RobotClass:SendStringToMe(s)
	if self.state then
		table.insert(self.state.msglist,s)
		--self.state.seat.owner:AddRecordMsg(self.id,s) --机器人先不录像
	end
end
function RobotClass:SendCmdToMe(doinfo, data,needlog)
	local send = {}
	send["do"] = doinfo
	send["data"] = data
	local s = json.encode(send)
	table.insert(self.state.msglist,s)
	if needlog then
		self:Debug("SendCmdToMe:" .. s)
	end
    --table.insert(self.state.seat.owner.data.msglist,{uid=self.id,brd=nil,msg=s,})
end
function RobotClass:SendCmdToMeHost(doinfo, data)
	local send = {}
	send["do"] = doinfo
	send["data"] = data
	local s = json.encode(send)
	table.insert(self.state.msglist,s)
end
function RobotClass:SendFailToMe(msg,pos)
	local data = {
		desc=msg,
		pos = pos,
	}
	self:SendCmdToMe("Cmd.SysMessageMahjongCmd_S",data)
end

function RobotClass:IsRobot()
	return true
end
function RobotClass:Destroy()
	self.state.seat = nil
	self.state = nil
	--TODO 
end

-- info: 获取玩家基础数据
function RobotClass:GetBaseInfo(requestuser)
	local userBaseInfo = {
		ip = self.state.ip,
		uid = self.data.uid,
		headurl = self.data.base.headurl,
		nickname = self.data.base.nickname,
		gender  = self.data.base.gender, 
		diamond = self.data.mahjong.diamond,
		points = self.state.seat.point,
		seatId = self.state.seat:GetClientId(requestuser),
		sid = self.state.seat.id,
		onlineState = 1,
	}
	userBaseInfo.flower = {}
	for k,v in pairs(self.data.base.flower) do
		table.insert(userBaseInfo.flower,{id=k,num=v,})
	end
	if self.state.seat.bReady and self.state.seat.owner:IsAllReady() == false then
		userBaseInfo.bReady = 1
	end
	if table.len(self.state.seat.handCard) > 0 then
		userBaseInfo.handCardNum = table.len(self.state.seat.handCard)
	end
	return userBaseInfo
end

