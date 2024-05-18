---WHJ这里是临时添加,为了方便兼容升级
if not TableWinPatternScore then
	TableWinPatternScore = {
		[1]={["id"]=1,["name"]="平胡",["Sequence"]=100,["Triplet"]=101,["Kong"]=200,["Pair"]=50},
	}
end
---WHJ这里是临时添加结束,为了方便兼容升级

module('RoomInfo', package.seeall) -- 用户信息

table_game_list = import "table/table_game_list"

if RoomClass == nil then
	CreateClass("RoomClass")
end
RoomClass:SetClassName("Room")

GlobalRoomInfoMap = {} --全局房间管理
GloablTemplateRoomId = 10000

function GetRandomRoomId()
    if GloablTemplateRoomId > 99999 then
        GloablTemplateRoomId = 10000
    end
    GloablTemplateRoomId = GloablTemplateRoomId + 1
    return GloablTemplateRoomId
end

function CreateRandomRoomData(globalroomid, roomid, gameid,ownerid)
	local globalRoomData = {
		globalroomid= globalroomid,		-- 全局唯一房间id
		roomid 		= roomid, 		-- 随机一个房间号
		owner 		= 0,				-- 房主
		gameid 		= gameid,		-- 所属游戏id
		zoneid 		= 301,			-- 所属区id
		gamenbr		= 4,			-- 该房间能玩几局
		usernbr		= 4,			-- 该房间为几人模式
		paytype		= 0,			-- 该房间支付模式
		hosttip		= nil,			-- 该房间房主小费百分比
		props		= {},			-- 属性
		diamondcost = nil,				-- 钻石模式 房间消耗
		type 		= 1,				-- 玩法类型 
		mult 		= 1, 			-- 倍数（暂时是为了 龙岩麻将添加的游金倍数）
		createtime 	= os.time(),		-- 创建时间
		curgamenbr  = 0,				-- 当前房间已玩局数
		valid 		= 1,				-- 是否有效  房间解散时 该值置为0
		allleavetime= nil,				-- 房间内所有玩家都离开的时刻 用于判断该房间是否要失效解散
		hasDecrease = nil,				-- 是否已经扣费了 （该字段由游戏中添加并赋值）
		history 	= {
			position 	= {},			-- 确定每个uid在数组中的位置 填充第一局游戏数据时 填充该数据 map{uid:pos} 
			statistics 	= {},			-- 统计数据 （是个数组 里面4个数据 分别为四个玩家的数据 数据内容有{uid,nickname,integral}）
			detail 		= {},			-- 详细每局数据 (是个数组 里面为每局游戏具体数据 数据内容为{timestamp,statistics:{uid,nickname,integral}})
		},
		msglist  = {},				-- 消息历史
	}
	-- globalRoomData.props = TableRoomConfig.query(globalRoomData.gameid,globalRoomData.usernbr).defaltPlayType
	if unilight.getdebuglevel() > 0 then
		globalRoomData.gamenbr		= 4000			-- debug下方便测试
		if unilight.getdebuguser() == "WHJ" then
			globalRoomData.winDiamond = 1 --输赢钻石
			globalRoomData.gamenbr		= 4000			-- debug下方便测试
			globalRoomData.needDiamond = 1 --开场扣费
			globalRoomData.sendFlower = 1 --发花送钻
		end
	end
	if ownerid then
		globalRoomData.owner = ownerid
	end
	local userdata = UserInfo.GetUserDataById(ownerid or 0)   
	if userdata ~= nil and userdata.roomdata then
		globalRoomData.winDiamond = userdata.roomdata.winDiamond
		globalRoomData.needDiamond = userdata.roomdata.needDiamond
		globalRoomData.hostType = userdata.roomdata.hostType
		globalRoomData.sendFlower = userdata.roomdata.sendFlower
		if userdata.roomdata.exercise then
			globalRoomData.exercise = json2table(userdata.roomdata.exercise)
		end
		--userdata.roomdata = nil
	end
	return globalRoomData
end


function GetRoomInfoById(roomid)
    return GlobalRoomInfoMap[roomid]
end

function CreateRoom(roomdata)
	local room = RoomClass:New() 
	room.globalId = roomdata.globalroomid
	room.data = roomdata
	if room.data == nil then
		unilight.error("房间找不到数据库记录:" .. roomdata.globalroomid)
		return nil
	end

	room.base = table_game_list[room.data.lobbyId]
	if room.base == nil then
		unilight.error("找不到房间对应表格TableRoomConfig记录:" .. room.data.lobbyId .. ":" .. room.data.usernbr .. ":" .. roomdata.globalroomid)
		return nil
	end
	room.id = room.data.roomid
	room.name = room.base.gameName
	if room.data.msglist == nil then
		room.data.msglist  = {}				-- 消息历史
	end
	room.state = {
		seats = {
		},
	}
	-- 创建座位
	for i=1, room.data.usernbr do
		room.state.seats[i] = SeatInfo.CreateSeat(room, i)
	end
	room.state.maxRobotNum = 4 --临时测试用
	room.state.round = nil
	room.state.heapCard = {}
	room.state.outCardBaseIdNum = {} --所有牌池的牌

	room.state.allCard = nil
	room.state.allCardNum = 0 --一副牌的数量,剔除策划配置的noCard 
	room.state.normalCardNum = 0 --一副牌的数量,剔除策划配置的noCard和花牌
	room.state.usernum = room.data.usernbr 
	room.state.broadcastRoom= go.roommgr.CreateRoom()
	room.state.bankerSeat = nil
	room.state.bankerUid = 0 --这里有点冗余,为了录像用下WHJ,否则最后一局会找不到庄
	room.state.operateSeat = nil
	room.state.readyForOperate = false
	room.state.curgamenbrWin = 0 --最后一次胡牌的局数
	room.state.totalScore = {} --每局结算累计明细
	--room:InitAllCard()
	--self:CreateCard(0)
	if GlobalRoomInfoMap[room.id] ~= nil then
		local tmproom = GlobalRoomInfoMap[room.id]
		tmproom:Error("严重bug,发现未销毁房间被再次创建")
		tmproom:Destroy()
	end
	GlobalRoomInfoMap[room.id]=room 
	if room.data.outtime then
		room.state.outTime = room.data.outtime*1000
	else
		room.state.outTime = room.base.outTime
	end
	room.state.loopTimer = unitimer.addtimermsec(RoomClass.Loop, 100,room)
	room.state.timerOneSec = NewUniTimerClass(RoomClass.TimerOneSec, 1000,room) 
	room.state.opEvent = NewUniEventClass(RoomClass.EventSendQuickStart, 3000, 1, room) --开局一分钟后才可以发托管按钮
	room.state.dissoveEvent = nil
	room:InitRoom()
	room.state.props = {} --玩法属性用key值管理起来
	room:InitProps()
	room:Info("create room ok roomId:" .. room.id)
	return room
end

function RoomClass:CheckProp(id)
	for i,v in pairs(self.data.props) do
		if v == id then
			return true
		end
	end
	return false
end
function RoomClass:InitProps()
	self.data.props = self.data.props or {} --先建容下老的模式,避免报错
	for i,v in pairs(self.data.props) do
		if v == 143 then --超时暂停
			self.state.props[v] = self.TimeOutIdle
			--TODO
		elseif v == 144 then --超时托管
			self.state.props[v] = self.DoHostMahjong
			--TODO
		elseif v == 196 then --是否赌钻石
			if not self.data.winDiamond then
				self.data.winDiamond = 1 
			end
		end
	end
	if self:IsLearnRooom() then
		local has_144 = false
		for i,v in pairs(self.data.props) do
			if v == 144 then
				has_144 = true
				break
			end
		end
		if not has_144 then
			table.insert(self.data.props,144)
			self.state.props[144] = self.DoHostMahjong
		end
	end
	self:InitMyProps()
end
function RoomClass:InitMyProps()
	self:Debug("等待重构InitMyProps")
end

function RoomClass:InitRoom()
	local a,b = math.modf(self.data.gamenbr)
	if b > 0 then
		self.data.gamenbr = a*100
		self.state.bundle = a -- 打捆
	end
	self:InitMyRoom()
end

function RoomClass:InitMyRoom()
	self:Debug("等待重构InitMyRoom")
end

function ClearTableData(data,list)
	if type(data) == "table" then
		data.base = nil
		for k,v in pairs(data) do
			for k1,v1 in ipairs(list) do
				if v1 == v then
					data[k] = nil
				end
			end
			table.insert(list,v)
			data[k] = ClearTableData(v,list)
			table.remove(list)
		end
	elseif type(data) == "userdata" then
		return nil
	end
	return data
end
--关机存档所有房间数据
function SaveAllRoomData()
	for roomid,room in pairs(GlobalRoomInfoMap) do
		--room:Save()
		--room:Debug("停机存档")
		--local tmp = ClearTableData(room,{room})
		--local tmpstr = table.tostring(tmp)
		--print(tmpstr)
		--local tmpstr = json.encode(tmp)
		--print("strlen:" .. string.len(tmpstr))
	end
end

-- 匹配场 换桌
function RoomClass:DoChangeRoomMahjong(userinfo)
	if self:IsAllReady() then
		self:BroadcastSys("已经开局,不能再换桌")
		return false
	end
	self:BroadcastExceptOne("Cmd.LeaveMahjongCmd_Brd", {uid=userinfo.id,state=0,},userinfo.id)
	if self.state.bankerSeat and self.state.bankerSeat.playerInfo and self.state.bankerSeat.playerInfo == userinfo then
		self.state.bankerSeat = nil
	end
	self.state.last_WinRetMahjongCmd_Brd = nil
	self.state.broadcastRoom.Rum.RemoveRoomUser(userinfo.state.laccount)
	userinfo.state.seat.playerInfo = nil
	userinfo.state.seat.bReady = false
	userinfo.state.seat = nil

	local roomId = GetRandomRoomId(nil, self.id, userinfo.data.mahjong.diamond, self.data.exercise.minLimit)
	if roomId == nil then
		userinfo:Destroy()
		return false
	end
	userinfo:RemoveRoomUserInfo(userinfo)
	local cmd = {
		data = {},
	}
	cmd.data.roomId = roomId
	Net.CmdEnterMahjongCmd_C(cmd, userinfo.state.laccount)
	if self:GetCurrentUserNum() == 0 then
		self:Destroy()
	end
end

-- 动态修改房间人数
function RoomClass:ChangeUserNbr(usernbr)
	if self:IsAlreadyStart() then
		self:BroadcastSys("已经开局,不能改变人数了")
		return false
	end
	if self.data.usernbr < usernbr then
		self:BroadcastSys("房间人数只能减少,不能增加")
		return false
	end
	local base = TableRoomConfig.query(self.data.gameid,usernbr)
	if base == nil then
		self:Info("房间人数设置找不到base:"..self.data.usernbr .. ":" .. usernbr)
		return false
	end
	local oldseats = self.state.seats
	self.state.seats = {}
	self.data.usernbr = usernbr
	self.state.usernum = usernbr --这里有冗余,但是为了兼容没办法
	self.base = base
	self.name = self.base.name
	for i=1, self.data.usernbr do
		self.state.seats[i] = SeatInfo.CreateSeat(self, i)
	end
	for i, v in ipairs(oldseats) do
		if v.playerInfo then
			self:BroadcastExceptOne("Cmd.LeaveMahjongCmd_Brd", {uid=v.playerInfo.id,state=0,},v.playerInfo.id)
			if v.playerInfo:IsRobot() then
			else
				v.playerInfo:RemoveBroadcast() --先移除下,避免发过多无用信息干扰
			end
		end
	end
	for i, v in ipairs(oldseats) do
		if v.playerInfo then
			v.playerInfo.state.seat = nil
			if v.playerInfo:IsRobot() then
				self:AddNewRobot(v.playerInfo)
			else
				self:AddNewUser(v.playerInfo)
				self:DoEnterMahjong(v.playerInfo, true)
			end
		end
	end
	self:Info("调整开局人数成功:"..usernbr)
	return true
end
-- 获取房间状态
function RoomClass:GetRoomState(requestuser)
    local outCount = math.floor(self.state.outTime/1000)
    local opCount = math.floor(self.base.operateTime/1000)
    local userInfoSet  = self:GetUserBaseInfo(requestuser) 
    local roomPro = self:GetRoomPro()
    local ret = {
        outCount = autCount,
        opCount = opCount,
        roomId = self.id,
        userInfoSet = userInfoSet,
        setInfo = nil,
        roomProps = roomPro,
	props = self.data.props,
    }
    if self.state.dissoveEvent then
	    ret.dissoveTime = ((self.state.dissoveEvent.nextmsec - unitimer.now)/1000)
    end
    return ret
end

function RoomClass:GetRoomPro()
    local roomPro = self:GetMyGetRoomPro()
    -- 房间总局数
    local roundPro = {
        id = 1, 
        value = self:GetRoundNum(),
    }
    table.insert(roomPro, roundPro)

    --人数模式
   local seatPro = {
        id = 3, 
        value = self:GetSeatNum(),
    }
    table.insert(roomPro, seatPro)

    -- 支付模式
   local payPro = {
        id = 4, 
        value = self:GetPayType(),
    }
    table.insert(roomPro, payPro)

    -- 是否支持托管
   local prop = {
        id = 6, 
        value = 1,
    }
    table.insert(roomPro, prop)
    
    return roomPro
end
--已被捉鸡重写
function RoomClass:GetMyGetRoomPro()
	local roomPro = {}
	local goldPro = {
		id = 101,
		value = table.len(self.base.goldCard),
	}
	table.insert(roomPro, goldPro)

	local val = 2
	if self.state.bundle then
		val = 1
	end
	local pro = {
		id = 102,
		value = val,
	}
	table.insert(roomPro, pro)
	return roomPro
end

function RoomClass:GetPayType()
    return self.data.paytype
end

function RoomClass:GetSeatNum()
    --return self.data.usernbr
    return self.data.usernbr
end

function RoomClass:GetRoundNum()
	if self.state.bundle then
		return self.state.bundle
	end
	return self.data.gamenbr
end

function RoomClass:GetCurRoundNum()
    return self.data.curgamenbr
end

function RoomClass:GetUserBaseInfo(requestuser)
    local userBaseInfoList = {} 
    for i, v in ipairs(self.state.seats) do
        if v.playerInfo ~= nil then
            table.insert(userBaseInfoList, v.playerInfo:GetBaseInfo(requestuser))
        end
    end
    return userBaseInfoList
end


function RoomClass:GetId()
	return self.id .. ":" .. self.globalId
end

function RoomClass:GetName()
	return self.name .. ":".. self:GetCurRoundNum()
end

function RoomClass:CheckNoCard(basecard)
	for k,v in ipairs(self.base.noCard) do
		if basecard.thisid == v or basecard.type == v then --判断是否是剔除牌
			--self:Debug("InitAllCard 洗牌")
			return false
		end
		if basecard.baseid == v then --判断是否是剔除牌,用baseid时,要注意花牌当字和字牌当花的情况
			if basecard.nocard == 1 then --看系统是否配置不加载,负负得正,注意安全
				return true
			else
				return false
			end
		end
	end
	if basecard.nocard == 1 then --看系统是否配置不加载
		return false
	end
	if self:CheckMyNoCard(basecard) == false then
		return false
	end
	return true
end
function RoomClass:CheckMyNoCard(basecard)
	return true
end
function RoomClass:IsNormalCard(basecard)
	return basecard.type < 5
end
function RoomClass:InitAllCard()
	self.state.heapCard = {}
	self.state.outCardBaseIdNum = {}
	if self.state.allCard == nil then
		self:Debug("InitAllCard 洗牌")
		self.state.allCardNum = 0
		self.state.normalCardNum = 0
		self.state.allCard = {}
		self.state.normalCardBaseId = {}
		for k,v in pairs(TableCard) do
			if self:CheckNoCard(v) then
				local card = CardInfo.CreateCard(v.thisid)
				self.state.allCardNum = self.state.allCardNum + 1
				table.insert(self.state.allCard,card) --这里的插入有顺序要求,花牌必须在最后面
				if self:IsNormalCard(v) then
					self.state.normalCardNum = self.state.normalCardNum + 1
				end
			end
		end
		for k,v in pairs(CardBaseIdMap) do
			v = v[1]
			if self:CheckNoCard(v) and self:IsNormalCard(v) then
				table.insert(self.state.normalCardBaseId, v.baseid)
			end
		end
	end
	for k,v in ipairs(self.state.allCard) do
		self.state.heapCard[v.id] = v
	end
	self:Info("初始化洗牌数量:".. table.len(self.state.heapCard))
	self:InitSeatCard()
end

function RoomClass:Shuffle()
	self.state.shuffleCard = {}
	--table.reset(self.state.shuffleCard)
	for k,v in pairs(self.state.heapCard) do
		table.insert(self.state.shuffleCard,v.id)
	end
	self.state.shuffleCard = math.shuffle(self.state.shuffleCard)
	--self:Info("洗牌日志:".. json.encode(self.state.shuffleCard))
end
-- 生成麻将牌
function RoomClass:InitSeatCard()
	self:Shuffle()
	-- 生成 初始手牌
	for k,v in ipairs(self.state.seats) do
		local num = 13
		if v == self.state.bankerSeat then
			self.state.bankerUid = self.state.bankerSeat.playerInfo.id
			self:Error("庄家发第十四张")
			num = 14
		end
		if self.state.bankerSeat == nil then
			self:Error("庄家为空")
		end
		self:ResetHandCard(v,num)
	end
end

-- 生成手牌
function RoomClass:ResetHandCard(seat,num)
	seat.handCard = {}
	for i = 1 ,num do
		if i < 14 then
			--local card = self:GetOneCard()
			local card = nil
			if unilight.getdebuglevel() > 0 then
				if not seat.base then
					--seat.base = TableHandCardInit[math.random(1,#TableHandCardInit)]
				end
				if unilight.getdebuguser() == "WHJ" and math.random(1,100) < 90 then
					card = self:GetOneCard(1)
				else
					if seat.base and seat.base.card[i] ~= nil then
						card = self:GetOneCard(seat.base.card[i])
					end
				end
			end
			if card == nil then
				card = self:RemoveOneHeapCard()
			end
			seat.handCard[card.base.thisid] = card --这里没必要,只是为了保险,后面又会删除
		else
			local card = self:GetOneCard(nil,true)
			seat.handCard[card.base.thisid] = card --这里没必要,只是为了保险,后面又会删除
			self.state.round.newGetCard = card --庄家第14张牌当做摸到的牌
			self.state.round.firstBankerCard = card --庄家第14张牌当做摸到的牌
		end
	end
end

function RoomClass:Save()
	local msglist = self.data.msglist
	self.data.msglist = nil
	self.data.msglist = msglist --历史消息先不存数据库,我想办法放个合理的地方
	self:Debug("存档")
end

function RoomClass:RemoveOneRobot()
	for k,v in ipairs(self.state.seats) do
		if v.playerInfo == v.playerInfo:IsRobot() then
			v.playerInfo:Destroy()
			v.playerInfo = nil 
			break
		end
	end
end
function RoomClass:GetIdleSeat(seatid)
	local seatid = seatid or math.random(1,self:GetSeatNum())
	if self.state.seats[seatid].playerInfo == nil then
		return self.state.seats[seatid]
	end
	for k,v in ipairs(self.state.seats) do
		if v.playerInfo == nil then
			return v
		end
	end
end

function RoomClass:GetSeatByUid(uid)
	for k,v in ipairs(self.state.seats) do
		if v.playerInfo.id == uid then
			return v
		end
	end
end

function RoomClass:IsLearnRooom()
	return self.id < 100000
end

function RoomClass:GetPlayerNum()
	local ret = 0
	for i, v in ipairs(self.state.seats) do
		if v.playerInfo then
			ret = ret + 1
		end
	end
	return ret
end

function RoomClass:GetRobotNum()
	local ret = 0
	for i, v in ipairs(self.state.seats) do
		if v.playerInfo and v.playerInfo:IsRobot() == true then
			ret = ret + 1
		end
	end
	return ret
end

function RoomClass:HasAnyUserReady()
	local ret = true
	for i, v in ipairs(self.state.seats) do
		if v.playerInfo and v.playerInfo:IsRobot() == false then
			ret = false
			if v.bReady == true then
				return true
			end
		end
	end
	return false
end
function RoomClass:HasAnyUser()
    for i, v in ipairs(self.state.seats) do
        if v.playerInfo and v.playerInfo:IsRobot() == false then
            return true
        end
    end
    return false
end
function RoomClass:IsAllRobot()
    for i, v in ipairs(self.state.seats) do
        if not v.playerInfo or v.playerInfo:IsRobot() == false then
            return false
        end
    end
    return true
end

function RoomClass:IsAlreadyStart()
	if self.data.curgamenbr > 0 then
		return true
	end
	return false
end

function RoomClass:CanLeaveRoom()
	if self:IsLearnRooom() then
		return true
	end
	if self:IsAllReady() == false and self.data.curgamenbr == 0 then
		return true
	end
	return false
end

function RoomClass:IsAllReady()
    for i, v in ipairs(self.state.seats) do
        if v.playerInfo == nil or v.bReady ~= true then
            return false
        end
    end
    return true
end

function RoomClass:ResetReady()
    if go.version and self:IsLearnRooom() == false then
	    self.state.broadcastRoom.SaveRecordMsg(self.data.globalroomid .. ":" ..self.data.curgamenbr,self.state.bankerUid)
	    for i, v in pairs(self.state.seats) do --录像用
		    if v.last_EnterMahjongCmd_S then
			    self:AddRecordMsg(v.playerInfo.id,v.last_EnterMahjongCmd_S)
		    end
		    if v.last_JsonCompressNullUserPmd_CS then
			    self:AddRecordMsg(v.playerInfo.id,v.last_JsonCompressNullUserPmd_CS)
		    end
	    end
	    for i, v in pairs(self.state.seats) do --录像用
		    if v.playerInfo then
			    for ii, vv in pairs(self.state.seats) do --录像用
				    if v ~= vv and vv.playerInfo then
					    local brd = {
					    }
					    brd.userInfo = v.playerInfo:GetBaseInfo(vv.playerInfo)
					    local send = {}
					    send["do"] = "Cmd.EnterMahjongCmd_Brd"
					    send["data"] = brd
					    local s = json.encode(send)
					    self:AddRecordMsg(vv.playerInfo.id,s)
				    end
			    end
		    end
	    end
		    
    end
    for i, v in pairs(self.state.seats) do
        v.bReady = false
	v:ResetData()
		if v.playerInfo and v.playerInfo:IsRobot() == true  then
			v.playerInfo.msglist = {}
		end
    end
    self.state.round = nil
    self.state.operateSeat = nil 
    self.state.readyForOperate = false
    if self.data.curgamenbr > 0 and self.data.curgamenbr < self.data.gamenbr then
	self.state.opEvent = NewUniEventClass(RoomClass.EventDoReadyStart, 15000, 1, self)
    end
end

function RoomClass:AddNewRobot(robot)
	if robot == nil then
		self:Error("机器人为空")
		return false
	end
	if robot.state.seat ~= nil then
		self:Error("机器人座位不为空")
		return false
	end
	local seat = self:GetIdleSeat(nil)
	if seat == nil then
		self:Error("机器人没找到空座位")
		return false
	end
	seat.playerInfo = robot
	robot.state.seat = seat
	self:Info("AddNewRobot ok:" .. seat.id)
	self:BroardBaseInfoToUser(robot)
	self:DoReadyStart(seat.playerInfo)
	return true
end
function RoomClass:CheckStart()
    if self:IsAllReady() and self.state.round == nil then
        self:Info("所有人员到位，准备开始:"..self.data.curgamenbr .. ":" .. self.data.gamenbr)
	self:StartNewRound()
	self.state.opEvent = NewUniEventClass(RoomClass.EventSetBanker, self.base.bankerTime, 1, self)
	self:Save()
    end
end
function RoomClass:AddNewUser(userinfo)
	if userinfo.state.seat ~= nil then
		--userinfo:SendFailToMe("已经在房间,不能再次进入")
		return false
	end
	local seat = self:GetIdleSeat(nil)
	if seat == nil then
		userinfo:SendFailToMe("房间已满")
		userinfo:Error("房间已满")
		return false
	end
	seat.playerInfo = userinfo
	userinfo.state.seat = seat
	--默认不准备,进入房间时决定是否准备,WHJ
	seat.bReady = false
	--userinfo:Online()
	self:Info("AddNewUser ok:" .. seat.id .. ":" .. userinfo.id)
	--self:DoHostMahjong(userinfo,{data={hostType=1,},})
    --这里需要判断是否开局
	return true
end

local profi = nil
ProFi = nil
function RoomClass:StartNewRound()
	--ProFi = import 'script/gxlua/ProFi'
	if profi == nil then
		--ProFi:start()
		--profi = 1
	end
	if self:IsAllRobot() == true or self.data.curgamenbr > self.data.gamenbr then --机器人测试不结束
		self.data.curgamenbr = 0
	end
	if self.data.curgamenbr > self.data.gamenbr then
		self:Error("本局次数已用完:" .. ":" .. self.data.curgamenbr .. "/" .. self.data.gamenbr)
		return false
	end
	self.data.curgamenbr= self.data.curgamenbr + 1 
	if self.data.curgamenbr == 1 then
		for i, v in ipairs(self.state.seats) do
			 self.data.history.position[v.playerInfo.id]=i
			 if v.playerInfo:IsRobot() == false then --如果是玩家切后台,增加短信提示
				v.playerInfo:SendWarnToUser("游戏已开局")
			end
		end
	end
	self.state.round = RoundInfo.CreateRound(self,self.data.curgamenbr)
	self.state.last_WinRetMahjongCmd_Brd = nil
	self.state.last_CashChickenCmd_Brd = nil
	self.state.readyForOperate = false
	-- 创建座位
	for i=1, self.data.usernbr do
		self.state.seats[i]:ResetData()
	end
	-- 圈风
	local circle = math.floor(self.data.curgamenbr/4) + 1
	if self.data.curgamenbr%4 == 0 then
		circle = circle - 1
	end
	-- 门风
	local gate = self.data.curgamenbr%4
	if gate == 0 then
		gate = 4
	end
	local data = {
		roomId=self.id,
		curGameNbr=self.data.curgamenbr,
		circle=circle,
		gate=gate,
	}
	data = self:GetMyNewRoundData(data)
	self:Broadcast("Cmd.StartMahjongCmd_Brd", data)
	self.state.goodcardProb = self.base.goodcardProb
	--if math.random(1,self.data.gamenbr) <= 1 then
	if math.random(1,8) <= 1 then
		self.state.goodcardProb = (self.state.goodcardProb or 0) + 1000
		self:Debug("加速配牌:"..self.state.goodcardProb)
	end
	local winpoint = 0
	local winseat = nil
	local losepoint = 100000
	local losenseat = nil
	for i, v in ipairs(self.state.seats) do
		winseat = winseat or v
		losenseat = losenseat or v
		if winpoint <= v.point then
			winpoint = v.point
			winseat = v
		end
		if losepoint >= v.point then
			losepoint = v.point
			losenseat = v
		end
		v.playerInfo.state.goodcardProb = 0
		v.playerInfo.state.changegoldCard = 0
		if v.playerInfo.id == self.data.owner then
			v.playerInfo.state.goodcardProb = (v.playerInfo.state.goodcardProb or 0) + 500 --房主给个1%的好牌率
			self:Debug("房主好牌概率:"..v.playerInfo.id .. ":" .. v.playerInfo.state.goodcardProb)
		end
	end
	if winseat == losenseat then
		winseat = nil
	end
	if self.data.gamenbr >= 1000 then
		if self.data.curgamenbr >= 6 then --,打捆不能永远不到底超过17局加速来开差距,大于1000先假设为打捆模式
			if self.data.curgamenbr >= 10 and winseat then
				winseat.playerInfo.state.goodcardProb = (winseat.playerInfo.state.goodcardProb or 0) + 1500 --加速赢得最多的人结束
				self:Debug("扶持强者:".. winseat.playerInfo.id .. ":" .. self.data.curgamenbr .. ":" .. self.data.gamenbr .. ":" .. winseat.playerInfo.state.goodcardProb ..":"..winseat.point)
			end
			if self.data.curgamenbr >= 6 and losenseat then
				losenseat.playerInfo.state.goodcardProb = (losenseat.playerInfo.state.goodcardProb or 0) - 3000 --加速赢得最多的人结束
				self:Debug("打击弱者:"..losenseat.playerInfo.id .. ":" .. self.data.curgamenbr .. ":" .. self.data.gamenbr .. ":" .. losenseat.playerInfo.state.goodcardProb ..":"..losenseat.point)
			end
		end
	else
		if self.data.curgamenbr > 2 and losenseat then
			losenseat.playerInfo.state.goodcardProb = (losenseat.playerInfo.state.goodcardProb or 0) + 1000 + math.abs(losenseat.point) * 10 --保护弱者
			self:Debug("保护弱者:"..losenseat.playerInfo.id .. ":" .. self.data.curgamenbr .. ":" .. self.data.gamenbr .. ":" .. losenseat.playerInfo.state.goodcardProb ..":"..losenseat.point)
			if losenseat.point < -100 then
				losenseat.playerInfo.state.changegoldCard = losenseat.point*10
			end
		end
	end
	if self.state.dissoveEvent then
		for k,v in ipairs(self.state.seats) do
			if v.isAgreeDissolve ~= 1 and v.playerInfo then
				self:DoReplyDissolveRoom(v.playerInfo,{data={isAgree=0,},})
				break
			end
		end
	end
	return true
end

function RoomClass:GetMyNewRoundData(data)
	return data
end

function RoomClass:SetBanker(seatid)
	self.state.bankerSeat = self.state.seats[seatid]
	if unilight.getdebuglevel() > 0 then
		for i, v in ipairs(self.state.seats) do
			--if v.playerInfo:IsRobot() == false then
			--	self.state.bankerSeat = v
			--	self:ResetOperator()
			--	break
			--end
		end
	end
	self:Info("定庄:"..seatid .. ":" ..self.state.bankerSeat.id)
end

function RoomClass:GetHeapCardNum()
	--return table.len(self.state.heapCard)
	return table.len(self.state.shuffleCard)
end

function RoomClass:GetInitHandCardButton()
	local ret = {}
	for k,v in pairs(TableHandCardInit) do
		if TableGameHandCardInit then
			for k1,v1 in ipairs(TableGameHandCardInit[1].cardSet) do
				if v1 == k then
					table.insert(ret,{id=k,value=v.name})
				end
			end
		elseif v.type == 1 then
			table.insert(ret,{id=k,value=v.name})
		end
	end
	return ret
end
function RoomClass:GetHeapCard()
	return self.state.shuffleCard
end

--已被重写
function RoomClass:EventSetBanker(me)
	local self = self or me 
	self.state.opEvent = nil
	local data = {
		dice = {one=math.random(1,6), two=math.random(1,6)},
	}
	if self.state.bankerSeat == nil then
		self:SetBanker((data.dice.one+data.dice.two)%self.data.usernbr+1)
	else
		self:SetBanker((self.state.bankerSeat.id)%self.data.usernbr+1)
	end
	data.bankerId = self.state.bankerSeat.playerInfo.id
	data.eastUid = self:GetEastUid()
	data.sec = self.base.bankerTime
	self:Broadcast("Cmd.SetBankerMahjongCmd_Brd", data)
	self.state.opEvent = NewUniEventClass(RoomClass.EventDealCard, self.base.dealTime, 1, self)
end
function RoomClass:GetEastUid()
	if self.state.seats[1].playerInfo then
		return self.state.seats[1].playerInfo.id
	end
end

function RoomClass:EventDealCard(me)
	local self = self or me 
	self.state.opEvent = nil
	self:InitAllCard()
	self:ResetOperator(self.state.bankerSeat)
	self.state.round:SetGoldCard()
	self.state.round.outCardSeat = self.state.bankerSeat
	self.state.opEvent = NewUniEventClass(RoomClass.EventSendFlower, self.base.flowerTime, 1, self)
	local heapNum = self:GetHeapCardNum()
	for i, v in ipairs(self.state.seats) do
		local data = {
			heapCardNum = heapNum,
			userCard = v:GetUserCard(true,true),
			sec = math.floor(self.state.outTime/1000) ,
		}
		if unilight.getdebuglevel() > 0 then
			data.otherCard = {}
			for i1, v1 in ipairs(self.state.seats) do
				if v1 ~= v then
					table.insert(data.otherCard,v1:GetUserCard(true,true))
				end
			end
		end
		if v == self.state.bankerSeat and self.state.round.firstBankerCard then
			data.bankerThisId = self.state.round.firstBankerCard.id
			for k1,v1 in ipairs(data.userCard.handCardSet) do
				if v1 == data.bankerThisId then
					table.remove(data.userCard.handCardSet,k1)
					break
				end
			end
		end
		v.playerInfo:SendCmdToMe("Cmd.SelfCardMahjongCmd_S", data)
	end
	self.state.round.SendSelfCardOk = true
end

function RoomClass:SendFlower()
	local start = self.state.operateSeat.id - 1
	for i = start,start + self.data.usernbr do
		local seat = self.state.seats[i % self.data.usernbr + 1]
		local data = {
			uid = seat.playerInfo.id,
			flowerSet = {},
		}
		for k,v in pairs(seat.handCard) do
			if v.base.type == 5 then
				if self.state.readyForOperate == false then
					seat.playerInfo:Debug("开局补花:"..v.base.thisid)
				else
					seat.playerInfo:Debug("补花:"..v.base.thisid)
				end
				table.insert(data.flowerSet,v.base.thisid)
			end
		end
		if table.len(data.flowerSet) > 0 then
			local myCardSet = nil
			for k,v in pairs(data.flowerSet) do
				if self.state.readyForOperate == false then
					seat.playerInfo:Debug("开局补花删手牌:"..v .. ":" .. seat.handCard[v].id)
				end
				seat:AddOneFlowerCard(v)
				seat.handCard[v] = nil
				local card = self:GetOneCard(nil,true)
				if card == nil then
					self:Error("发花后没牌了:" .. v)
					return true --这里得返回true,否则如果最后一张是花,就会死循环
				end
				myCardSet = myCardSet or {}
				table.insert(myCardSet,card.base.thisid)
				self.state.round.newGetCard = card
				seat:AddOneCard(card)
			end
			data.heapCardNum = self:GetHeapCardNum()
			 if unilight.getdebuglevel() > 0 then
				 data.myCardSet = myCardSet
			 end
			self:BroadcastExceptOne("Cmd.FlowerMahjongCmd_Brd", data,seat.playerInfo.id)
			data.myCardSet = myCardSet
			seat.playerInfo:SendCmdToMe("Cmd.FlowerMahjongCmd_Brd", data)
			return true
		end
		--广播
	end
	return false
end

function RoomClass:EventSendFlower(me)
	local self = self or me 
	self.state.opEvent = nil
	if self:SendFlower() == true then
		self.state.opEvent = NewUniEventClass(RoomClass.EventSendFlower, self.base.flowerTime, 1, self)
	else
		if self.state.readyForOperate == false then
			if  table.len(self.state.round.goldCard) > 0 then
				local data = {
					cardSet = {
					},
					heapCardNum = self:GetHeapCardNum(),
				}
				for k,v in pairs(self.state.round.goldCard) do
					table.insert(data.cardSet,k)
				end
				data.cardSet = self.state.round:GetGoldCardSet()
				data.goldType = self.base.goldType
				data = self:GetMyTurnGoldDada(data)
				self:Broadcast("Cmd.TurnGoldMahjongCmd_Brd", data)
			end
			self:Info("翻金:" .. self.state.round.firstBankerCard.id)
			self:EventDealOneCard(self,self.state.round.firstBankerCard,2)
			self.state.round.firstBankerCard = nil
			if self.state.operateSeat ~= self.state.bankerSeat then
				self.state.bankerSeat:Error("发金后发现第一个操作者不是庄家:"..self.state.operateSeat:GetName())
			end
		else
			self.state.opEvent = NewUniEventClass(RoomClass.EventDealOneCard, self.base.flowerTime + 100, 1, self,self,self.state.round.newGetCard)
		end
		self.state.readyForOperate = true
	end
end

-- 兼容宁波翻金
function RoomClass:GetMyTurnGoldDada(data)
	return data
end

function RoomClass:ResetOperator(seat)
	if self.state.operateSeat ~= seat then
		self.state.round.newGetCard = nil
	end
	 if seat then
		 self.state.operateSeat = seat 
		 return 
	 end
	 if self.state.operateSeat == nil then
		 self.state.operateSeat = self.state.bankerSeat
	 else
		self.state.operateSeat = self.state.seats[(self.state.operateSeat.id % self.data.usernbr) + 1]
	 end
end
-- 兼容旌德 海底捞月
function RoomClass:DoSeaFloorFishingMoon(opType)
end
function RoomClass:DealOneCard(seat,card,isReconnect)
	if self.state.round.omitHu then --兼容长沙
		self.state.round.omitHu[seat] = nil
	end
	local data= {
		thisId = card.base.thisid,
	}
	if not seat.last_JsonCompressNullUserPmd_CS then
		if unilight.mahjong_new() ~= 1 then
			--等待兼容后启用
			data.heapCardNum = self:GetHeapCardNum()
		end
	end
	if card.base.type == 5 then
		seat.playerInfo:SendCmdToMe("Cmd.SendCardMahjongCmd_S", data)
		self:EventSendFlower()
		return
	else
		local newthisid = nil
		data.opType, data.listenSet, data.listenObjSet = seat:GetMyOperateType()
		seat.last_listenObjSet = table.clone(data.listenObjSet)
		seat.last_listenSet = table.clone(data.listenSet)
		if seat.last_JsonCompressNullUserPmd_CS then --为了兼容
			data.listenObjSet = nil
		end
		--[[data.opType,newthisid = seat:GetMyOperateType()
		if newthisid then
			data.thisId = newthisid
		end]]
		data.barSet = seat:GetCanBarId()
		data = seat:GetMyOperateData(data) -- 如果分支有需要扩展操作,可重写
		if self.state.round.newGetCardType == 1 then
			data.isBar = 1
		end
		if self.state.opEvent == nil then
			self.state.opEvent = NewUniEventClass(RoomClass.EventOutCardTimeOut, self.state.outTime, 1, self)
		end
		seat.playerInfo:SendCmdToMe("Cmd.SendCardMahjongCmd_S", data)
	end
	local brd = {
		uid = seat.playerInfo.id,
		--等待兼容后启用
		--hn = self:GetHeapCardNum(),
		sec = math.floor((self.state.opEvent.nextmsec - unitimer.now)/1000),
	} 
	if unilight.mahjong_new() ~= 1 then
		--等待兼容后启用
		brd.heapCardNum = self:GetHeapCardNum()
	end
	if unilight.mahjong_new() == 1 then
		--等待兼容后启用
		if self.state.outTime/1000 == brd.sec then
			brd.sec = nil
		end
		if self.state.outTime/1000 == brd.sec then
			brd.sec = nil
		end
	end
	if unilight.getdebuglevel() > 0 then
		brd.thisId = card.base.thisid
	end
	if self.state.round.startSmallWin and self.state.round.startSmallWin[seat] and self.state.round.startSmallWin[seat].stand == 0 then --{winType=winType,stand=0} --兼容长沙
		brd.stand = 1
		self.state.round.startSmallWin[seat].stand = 1
	end
	if self.state.round.originalLack and self.state.round.originalLack[seat] == true then --兼容贵州
		brd.stand = 1
		self.state.round.originalLack[seat] = false
	end
	--等待兼容后启用
	if unilight.mahjong_new() == 1 then
		brd.sid = seat.id
		brd.uid = nil
	end
	if self.state.round.newGetCardType <= 1 and not isReconnect then --只有新摸牌会广播给其他人,否则只给自己,目前是摸牌和杠后摸牌
		self:Broadcast("Cmd.SendCardMahjongCmd_Brd", brd)
	else
		seat.playerInfo:SendCmdToMe("Cmd.SendCardMahjongCmd_Brd", brd)
	end
	if data.opType == nil and self.state.round.barSeatMap and self.state.round.barSeatMap[seat] then
		self.state.opEvent = NewUniEventClass(RoomClass.EventDoOutCardToBar, 500, 1, self, seat.playerInfo, card.base.thisid)
	end
	self:DoSeaFloorFishingMoon(data.opType)
end
function RoomClass:EventDealOneCard(me,card,gettype)
	local self = self or me 
	self.state.round.newOutCard = nil --清空
	self.state.round.newGetCardType = gettype or 0
	self.state.round.waitOpSet = {}
	self.state.round.canOpSet = {}
	if self:DoMyGetCard(self.state.operateSeat.playerInfo,card,gettype) == false then
		return
	end
	if not card then
		card = self:GetOneCard()
		if card then
			local goldrate = self.base.changegoldCard or 0
			local rand = math.random(1,10000)
			goldrate = goldrate + self.state.operateSeat.playerInfo.state.changegoldCard
			if goldrate and goldrate > 0 and rand < goldrate and self.state.round:IsGoldCard(card) then -- and table.len(self.state.round.goldCard) > 1 then --金牌必换,延迟金牌出现
				self:Debug("换一张金牌:" .. card.id .. ":" .. self.state.operateSeat.playerInfo.id .. ":" .. goldrate .. ":" .. self.data.curgamenbr .. ":" ..self.state.operateSeat.point)
				self.state.heapCard[card.base.thisid] = card
				table.insert(self.state.shuffleCard,card.base.thisid)
				self:Shuffle()
				card = self:GetOneCard()
			elseif card.base.baseid == 21 and self.base.changeYitiao and self.base.changeYitiao ~= 0 and rand < self.base.changeYitiao and self.state.operateSeat:CheckHasChickenByBaseId(21) then
				self:Debug("换一张幺鸡:"..card.id..":"..self.state.operateSeat.playerInfo.id..":"..self.base.changeYitiao)
				self.state.heapCard[card.base.thisid] = card
				table.insert(self.state.shuffleCard,card.base.thisid)
				self:Shuffle()
				card = self:GetOneCard()
			elseif card.base.baseid == 38 and self.base.changeBatong and self.base.changeBatong ~= 0 and rand < self.base.changeBatong and self.state.operateSeat:CheckHasChickenByBaseId(38) then
				self:Debug("换一张八筒:"..card.id..":"..self.state.operateSeat.playerInfo.id..":"..self.base.changeYitiao)
				self.state.heapCard[card.base.thisid] = card
				table.insert(self.state.shuffleCard,card.base.thisid)
				self:Shuffle()
				card = self:GetOneCard()
			elseif (self.data.usernbr == 4 or self.data.usernbr == 3) and not self.state.operateSeat.listen and not self.state.operateSeat:CheckCanMeld(card) then  --听牌不扶持
				--if card and not self.state.operateSeat:CheckCanMeld(card) then 
				local good = (self.state.goodcardProb or 0) + (self.state.operateSeat.playerInfo.state.goodcardProb or 0) + math.floor(self.data.curgamenbr/2) * 100
				if good > 5000 then
					good = 5000
				end
				if  rand <= good then
					self:Debug("换一张好牌:" .. card.id .. ":" .. self.state.operateSeat.playerInfo.id .. ":" .. good .. ":" .. self.data.curgamenbr .. ":" .. self.state.goodcardProb .. ":" ..self.state.operateSeat.point)
					self.state.heapCard[card.base.thisid] = card
					table.insert(self.state.shuffleCard,card.base.thisid)
					self:Shuffle()
					card = self:GetOneCard(self.state.operateSeat:GetOneWaitCardBaseId())
				elseif self.base.changecardProb and rand <= self.base.changecardProb then
					self:Debug("换一张:" .. card.id)
					self.state.heapCard[card.base.thisid] = card
					table.insert(self.state.shuffleCard,card.base.thisid)
					self:Shuffle()
					card = self:GetOneCard()
				else
					local lastout = table.len(self.state.operateSeat.outCard)
					if lastout ~= 0 and card.base.baseid == math.floor(self.state.operateSeat.outCard[lastout]/10) and math.random(1,2) == 1 then --抓牌尽量不要抓跟上一张打出去的牌一样
						self:Debug("摸到上一张打出去的牌,换一张:" .. card.id)
						self.state.heapCard[card.base.thisid] = card
						table.insert(self.state.shuffleCard,card.base.thisid)
						self:Shuffle()
						card = self:GetOneCard()
					end
				end
			elseif self.data.usernbr == 2 and self.state.operateSeat:CheckCanMeld(card) then  --二人模式不能胡的太快
				if  rand <= 3000 then
					self:Debug("换一张烂牌:" .. card.id)
					self.state.heapCard[card.base.thisid] = card
					table.insert(self.state.shuffleCard,card.base.thisid)
					self:Shuffle()
					card = self:GetOneCard()
				end
			end
		end
	end
	if self.state.round.newGetCardType ~= 10 and self.state.round.newGetCardType ~= 2 then --只有模拟摸牌时事件不能重置
		self.state.opEvent = nil
	end
	 if self:CheckDrawGame(card) == true then
		 self:Error("结束:" .. self.state.operateSeat.playerInfo.id)
		 self:DrawGame() --流局
	 else
		 self.state.round.newGetCard = card
		 self.state.operateSeat:AddOneCard(card)
		 self:DealOneCard(self.state.operateSeat,card)

		 if self.state.round then
		 	self.state.round.outCardSeat = self.state.operateSeat
		 end
	 end
end

-- 检测流局(流局条件不同可重写)
function RoomClass:CheckDrawGame(card)
	if card == nil then
		return true
	end
	return false
end

function RoomClass:CheckOperator(playerid)
	 if self.state.operateSeat == nil then
		userinfo:Error("没有操作者")
		 return false
	 end
	 if self.state.round.outCardSeat ~= self.state.operateSeat or self.state.operateSeat.playerInfo.id ~= playerid then
	 --if self.state.operateSeat.playerInfo.id ~= playerid then
		 return false
	 end
	return true
end
function RoomClass:DoSendGift(userinfo,data)
	if not data then
		userinfo:SendFailToMe("送礼数据不能为空")
		userinfo:Error("送礼数据不能为空")
		return nil
	end
	data.fromid = userinfo.id
	if data.gift.giftsId == 7 then
		if unilight.getgameid() == 4055 then --江西客家麻将需求
			if self.data.usernbr ~= 2 then
				userinfo:SendFailToMe("房卡礼物限制二人房才可以送")
				return false
			end
		end
		if not data.gift.toUid or data.gift.toUid == 0 then
			userinfo:SendFailToMe("房卡礼物需要指定要赠送的玩家")
			return false
		end
	end
	if data.gift.toUid and data.gift.toUid ~= 0 then
		userinfo:Error("送花扣钻:"..data.gift.giftsId)
		if TableGift and TableGift[data.gift.giftsId] and userinfo:IsRobot() == false then
			if data.gift.giftsId == 7 then
				if not userinfo.data.mahjong.card or userinfo.data.mahjong.card < TableGift[data.gift.giftsId].giftCost then
					userinfo:SendFailToMe("房卡不够,赠送礼物失败")
					return false
				end
				local toUserInfo = UserInfo.GetUserInfoById(data.gift.toUid)
				if not toUserInfo then --如果不是玩家就是机器人
					userinfo:SendFailToMe("房卡赠送找不到目标玩家")
					return false
				end
				--userinfo.data.mahjong.card = TableGift[data.gift.giftsId].giftCost - userinfo.data.mahjong.card
				--toUserInfo.data.mahjong.card = TableGift[data.gift.giftsId].giftCost + toUserInfo.data.mahjong.card
				ChessToLobbyMgr.SendCmdToLobby("Cmd.UserCardChangeLobbyCmd_CS",{uid=userinfo.id,typ=1,change=-TableGift[data.gift.giftsId].giftCost,needSend=1,})
				ChessToLobbyMgr.SendCmdToLobby("Cmd.UserCardChangeLobbyCmd_CS",{uid=toUserInfo.id,typ=1,change=TableGift[data.gift.giftsId].giftCost,needSend=1,})
				userinfo:Error("送花扣房卡:"..data.gift.giftsId)
				--userinfo:SendFailToMe("扣除房卡:"..TableGift[data.gift.giftsId].giftCost)
				--toUserInfo:SendFailToMe("获得房卡:"..TableGift[data.gift.giftsId].giftCost)
			elseif self.data.sendFlower then
				if userinfo.data.mahjong.diamond < TableGift[data.gift.giftsId].giftCost then
					userinfo:SendFailToMe("钻石不够,操作失败")
					return false
				end
				if self.data.exercise and self.data.exercise.minLimit and (userinfo.data.mahjong.diamond - TableGift[data.gift.giftsId].giftCost) < self.data.exercise.minLimit then
					userinfo:SendFailToMe("送礼后钻石不能低于"..self.data.exercise.minLimit)
					return false
				end
				local toUserInfo = UserInfo.GetUserInfoById(data.gift.toUid)
				if not toUserInfo then --如果不是玩家就是机器人
					toUserInfo = RobotInfo.GetRobotInfoById(data.gift.toUid)
				end
				if toUserInfo then
					toUserInfo.data.base.flower = toUserInfo.data.base.flower or {}
					toUserInfo.data.base.flower[data.gift.giftsId] = (toUserInfo.data.base.flower[data.gift.giftsId] or 0) + 1
					ChessToLobbyMgr.SendCmdToLobby("Cmd.UserFlowerDataLobbyCmd_CS",{uid=toUserInfo.id,flower=toUserInfo.data.base.flower,})
				end
				ChessToLobbyMgr.SendCmdToLobby("Cmd.UserDiamondWinLobbyCmd_CS",{uid=userinfo.id,typ=4,change=-TableGift[data.gift.giftsId].giftCost,needSend=1,})
				local diamond = {}
				local obj = {}
				table.insert(obj, userinfo.id)
				table.insert(obj, userinfo.data.mahjong.diamond-TableGift[data.gift.giftsId].giftCost)
				table.insert(diamond, obj)
				data.diamond = diamond
			end
		end
		return self:Broadcast("Cmd.SendGiftMahjongCmd_Brd", data)
	else
		if self.data.sendFlower and TableGift and TableGift[data.gift.giftsId] and userinfo:IsRobot() == false then
			if userinfo.data.mahjong.diamond < TableGift[data.gift.giftsId].giftCost*(self.data.usernbr-1) then
				userinfo:SendFailToMe("钻石不够,操作失败")
				return false
			end
			if self.data.exercise and self.data.exercise.minLimit and (userinfo.data.mahjong.diamond - TableGift[data.gift.giftsId].giftCost*(self.data.usernbr-1)) < self.data.exercise.minLimit then
				userinfo:SendFailToMe("送礼后钻石不能低于"..self.data.exercise.minLimit)
				return false
			end
			for k,toUserInfo in ipairs(self.state.seats) do
				if toUserInfo.playerInfo ~= userinfo then
					toUserInfo.playerInfo.data.base.flower = toUserInfo.playerInfo.data.base.flower or {}
					toUserInfo.playerInfo.data.base.flower[data.gift.giftsId] = (toUserInfo.playerInfo.data.base.flower[data.gift.giftsId] or 0) + 1
				end
			end
			local diamond = {}
			local obj = {}
			table.insert(obj, userinfo.id)
			table.insert(obj, userinfo.data.mahjong.diamond-TableGift[data.gift.giftsId].giftCost*(self.data.usernbr-1))
			table.insert(diamond, obj)
			data.diamond = diamond
			ChessToLobbyMgr.SendCmdToLobby("Cmd.UserDiamondWinLobbyCmd_CS",{uid=userinfo.id,typ=4,change=-TableGift[data.gift.giftsId].giftCost*(self.data.usernbr-1),needSend=1,})
		end
		return self:Broadcast("Cmd.SendGiftMahjongCmd_Brd", data)
	end
	return false
end
function RoomClass:DoVoiceChat(userinfo,data)
	if not data then
		userinfo:SendFailToMe("聊天数据不能为空")
		userInfo:Error("聊天数据不能为空")
		return nil
	end
	data.uid = userinfo.id
	data.roomId = self.id
	if data.time == "NaN" then
		data.time = 5000
	end
	self.state.chathistory = self.state.chathistory or {}
	table.insert(self.state.chathistory,data)
	if table.len(self.state.chathistory) > 5 then ---保存最近5条记录
		table.remove(self.state.chathistory,1)
	end
	return self:Broadcast("Cmd.VoiceChat_Brd", data,true)
end
GlobalChatHistoryMap = {} --全局房间管理
-- 获取语音聊天记录
function GetChatRecords(uid)
	local chatInfo = self.state.chathistory
	local records = {}
	if chatInfo ~= nil and chatInfo.records ~= nil then
		unilight.info("获取语音聊天记录 roomId:" .. roomId)
		records = chatInfo.records
	end
	return TableServerReturnCode[1].id, records
end
function RoomClass:DoVoiceChatRecord(userinfo)
	return userinfo:SendCmdToMe("Cmd.VoiceChatRecord_S", self.state.chathistory,true)
end
function RoomClass:DoCommonChat(userinfo,data)
	if not data then
		userinfo:SendFailToMe("聊天数据不能为空")
		userInfo:Error("聊天数据不能为空")
		return nil
	end
	data.uid = userinfo.id
	return self:Broadcast("Cmd.CommonChat_Brd", data,true)
end
function RoomClass:DoChangeCardGmMahjongCmd(userinfo,oldid,newid)
	if not newid then --这里有可能策划配置错误导致报错
		return false
	end
	if unilight.getdebuglevel() <= 0 then
		userinfo:SendFailToMe("GM权限不够,不允许操作")
		userinfo:Error("GM权限不够,不允许操作")
		return false
	end
	local oldcard = userinfo.state.seat.handCard[oldid]
	if oldcard == nil then
		userinfo:SendFailToMe("手中没有这张牌怎么换:"..oldid)
		return false
	end
	if self:CheckOperator(userinfo.id) == false and self:GetCardTypeByThisid(newid) == 5 then --如果自己是操作者就不能指定花
		userinfo:SendFailToMe("只有操作者才可以换花")
		return false
	end
	local data = {
		oldCardId = oldid,
	}
	local newcard = self:ChangeOneCard(oldcard,newid)
	data.newCardId = newcard.base.thisid
	-- 手牌中去掉旧牌
	userinfo.state.seat.handCard[oldid] = nil
	if self:CheckOperator(userinfo.id) then --如果自己是操作盒
		data.needDelete = 1
		userinfo:SendCmdToMe("Cmd.ChangeCardGmMahjongCmd_S", data)
		self:EventDealOneCard(userinfo.state.seat,newcard,10)
	else
		data.needDelete = 0
		userinfo.state.seat:AddOneCard(newcard)
		data.winCardSet = self.state.operateSeat:GetWinCardSet()
		self.state.operateSeat.last_winCardSet = table.clone(data.winCardSet)
		userinfo:SendCmdToMe("Cmd.ChangeCardGmMahjongCmd_S", data)
	end
	return true
end
function RoomClass:DoCancelOperate(userinfo)
	 if self.state.round.waitOpSet[userinfo.state.seat] == nil then --这里必须有,不然会出现别人抓牌时再抓牌问题
		 --return false --展示屏蔽
	 end
	 if self.state.round.canOpSet[userinfo.state.seat] == nil then
	 	return false
	 end
	 userinfo:SendCmdToMe("Cmd.CancelOpMahjongCmd_S", "{}")
	 self.state.round.waitOpSet[userinfo.state.seat]= nil
	 self.state.round.canOpSet[userinfo.state.seat]= nil
	 self:DoMyCancleCard(userinfo)
	 if table.len(self.state.round.canOpSet) == 0 then -- and self.state.operateSeat == userinfo.state.seat then --所有人都放弃操作,就可以重新发牌了
		 if self.state.operateSeat ~= userinfo.state.seat then
			 self:ResetOperator()
			 self:EventDealOneCard()
		 end
		 if self.state.round then
			 self:Error("取消操作,重新开始:"..table.len(self.state.round.canOpSet) .. ":" ..table.len(self.state.round.waitOpSet))
		 else
			 self:Error("取消操作时发现已经流局")
		 end
	 else
		 local seat,op = self.state.round:GetOperatePrioritySeatWait() 
		 if op ~= nil and seat == self.state.round:GetOperatePrioritySeat(seat,op.opType) then
			 self.state.round.waitOpSet[seat]=nil
			 if op.opType == 2 then
				 self:DoBarCard(seat.playerInfo,op.thisId)
			 elseif op.opType == 6 then
				 self:DoTouchCard(seat.playerInfo,op.thisId)
			 elseif op.opType == 7 then
				 self:DoEatCard(seat.playerInfo,op.eat.one,op.eat.two)
			 else
				 self:Error("遗漏处理的操作等待列表:" .. seat.playerInfo.id .. ":" .. op.opType .. ":" .. op.thisId)
			 end
		 end
		 userinfo:Debug("DoCancelOperate:"..table.len(self.state.round.canOpSet) .. ":" ..table.len(self.state.round.waitOpSet))
	 end
	return true
end
function RoomClass:CheckReadyForOperate()
	if self.state.readyForOperate == false then
		return false
	end
	if self.state.opEvent and self.state.opEvent.tick < 5000 then --先假设低于5秒的事件都是系统级事件,过程中不允许用户操作
		self:Error("系统处理时间,不能操作")
		return false
	end
	return true
end
function RoomClass:GetCardType(card)
	if self.state.round.ji == nil then
		 self.state.round.ji = card
	 else
		 return nil
	end
	return self.state.round.ji.id
end
function RoomClass:DoOutCard(userinfo,thisid, isskylisten)
	if self:CheckIsCallListen(userinfo.id) then --贵州用
		if thisid ~= self.state.round.newGetCard.base.thisid then 
			userinfo:SendFailToMe("玩家叫听，不能跟换手牌")
			return 1
		end  
	end 
	local card = userinfo.state.seat.handCard[thisid]
	if card == nil then --这里有可能是网络卡了,玩家发了多次打牌消息,所以这种情况下,就什么都不做,也不能反悔false,否则客户端处理会乱,这个消息直接丢掉
		--userinfo:SendCmdToMe("Cmd.OutCardMahjongCmd_Brd", {uid = userinfo.id,thisId = thisid,}) --这个不能有
		self:Error("DoOutCard err:没有这张牌:" .. userinfo.id .. ":" .. thisid)
		return 2
	end
	if self:CheckReadyForOperate() == false then
		userinfo:SendFailToMe("当前还不能操作")
		self:Error("DoOutCard 当前还不能操作:" .. userinfo.id)
		return 1
	end
	--起手小胡期间不能出牌,湖南
	if self.state.round.startSmall and self.state.round.startSmall == true then
		userinfo:SendFailToMe("当前还不能操作")
		self:Error("DoOutCard 当前还不能操作:" .. userinfo.id)
		return 1
	end
	--if userinfo:IsRobot() == false and math.random(1,2) == 1 then
	--	return false
	--end
	--if userinfo:IsRobot() == false then
		--os.execute("sleep " .. 5)
	--end
	local ret = true
	local data = {
		uid = userinfo.id,
		thisId = thisid,
	} 
	if self:CheckOperator(userinfo.id) == false then
		--userinfo:SendFailToMe("当前不能操作")
		userinfo:Error("DoOutCard err:当前不能操作:" .. userinfo.id)
		ret = false
	end
	if ret then
		if ret and card.base.type == 0 then
			self:Error("DoOutCard err:不能打花牌:" .. userinfo.id .. ":" .. thisid)
			userinfo:SendFailToMe("不能打花牌")
			ret = false
		end
		if not self:DoCheckOutCardLack(userinfo,card) then --贵州用
			ret = false
		end
	end
	if ret then
		if self.state.operateSeat:RemoveOneCard(card) == false then
			userinfo:SendFailToMe("没有这张牌,不能出牌")
			self:Error("DoOutCard err:没有这张牌:" .. userinfo.id .. ":" .. thisid)
			ret = false
		end
	end
	if ret then
		data.winCardSet = self.state.operateSeat:GetWinCardSet(card)
		data = self.state.operateSeat:GetMyOutCardData(data, card) -- 可组装各分支额外的数据
		if data.winCardSet then
			self.state.operateSeat.listen = true
		else
			self.state.operateSeat.listen = false
		end
		local reset = true
		if userinfo.state.seat.last_JsonCompressNullUserPmd_CS then --为了兼容
			if not data.winCardSet and userinfo.state.seat.last_winCardSet then
				data.resetListen = 1
			elseif data.winCardSet and userinfo.state.seat.last_winCardSet and json.encode(data.winCardSet) == json.encode(userinfo.state.seat.last_winCardSet) then
				data.winCardSet = nil
				reset = false
			end
		end
		userinfo:SendCmdToMe("Cmd.OutCardMahjongCmd_S", data,self.state.bankerSeat ~= userinfo.state.seat)
		if reset then
			userinfo.state.seat.last_winCardSet = table.clone(data.winCardSet)
		end
	else
		return 1
	end
	if isskylisten then
		self:DoSkyListen(userinfo, thisid)
	end

	--贵州专用 必须在DoRecordOutCard前面 不然报听相关有bug
	self.state.round.out_card_player_id = userinfo.id 

	self:DoRecordOutCard(userinfo, card)
	self.state.round.outCardSet = (self.state.round.outCardSet or 0) + 1 --湖南用
	--广播给别人
	if self.data.outtime == nil then
		self.data.outtime = 2000
	end
	local sec = math.floor(self.state.outTime/1000)
	local brd = {
		uid = userinfo.id,
		thisId = thisid,
	} 
	brd.cardType = self:GetCardType(card)
	if unilight.mahjong_new() == 1 then
		--等待兼容后启用
		if brd.cardType == 0 then
			brd.cardType = nil
		end
	end
	brd.isFollow = self:CheckFollowCard(userinfo, thisid)
	local op = false
	self.state.round.canOpSet = {} --玩家可操作集合
	for k,v in ipairs(self.state.seats) do
		local mybrd = table.clone(brd)
		if v.last_JsonCompressNullUserPmd_CS then
			mybrd.sid = userinfo.state.seat.id
			mybrd.uid = nil
		end
		if v.playerInfo ~= userinfo then
			mybrd.opType,mybrd.eatSet = v:GetOperateType(card)
			if mybrd.opType then
				self.state.round.canOpSet[v] = mybrd.opType
				if not op then
					sec = math.floor(self.base.operateTime/1000)
					op = true
				end
				local winCardSet = v.last_winCardSet
				if winCardSet then
					local flag = false
					for i,j in pairs(winCardSet) do
						local tmpid = j.thisId or j[1] --兼容贵州
						if math.floor(tmpid/10) == math.floor(thisid/10) then
							flag = true
							break
						end
					end
					if flag == true then
						mybrd.winCardSet = winCardSet
					end
				end
			end
		end
		v.playerInfo.state.seat.last_OutCardMahjongCmd_Brd = mybrd
	end
	for k,v in ipairs(self.state.seats) do
		local mybrd = v.playerInfo.state.seat.last_OutCardMahjongCmd_Brd
		if op == true then
			mybrd.isOp = 1
			--等待兼容后启用
			if v.playerInfo.state.jsonCompress and v.playerInfo.state.jsonCompress.data and v.playerInfo.state.jsonCompress.data.key then
				if self.base.operateTime/1000 ~= sec then
					mybrd.sec = sec
				end
				if mybrd.cardType == 0 then
					mybrd.cardType = nil
				end
			end
		else
			--等待兼容后启用
			if v.playerInfo.state.jsonCompress and v.playerInfo.state.jsonCompress.data and v.playerInfo.state.jsonCompress.data.key then
				if self.state.outTime/1000 ~= sec then
					mybrd.sec = sec
				end
				if mybrd.cardType == 0 then
					mybrd.cardType = nil
				end
			end
		end
		v.playerInfo:SendCmdToMe("Cmd.OutCardMahjongCmd_Brd", mybrd,self.state.bankerSeat ~= v)
	end
	self.state.round.outCardSeat = nil
	self.state.round.waitOpSet = {}
	self.state.operateSeat:AddOutCard(card)
	
	self.state.round.newOutCard = card
	self:DoMyOutCard(userinfo)
	if self:CheckOutWin(userinfo) == true then 		-- 宁波 检测打胡
		return 0
	end
	self.state.round.newGetCard = nil

	if op == true then
		self.state.opEvent = NewUniEventClass(RoomClass.EventOperateCardTimeOut, self.base.operateTime, 1, self)
	else
		self:ResetOperator()
		self:EventDealOneCard()
	end
	if userinfo.state then
		self:Debug("出牌成功"..card:GetId() .. ":" .. userinfo.id .. ":" .. table.len(userinfo.state.seat.handCard))
		if userinfo.state.opEvent then --如果这个时候有托管事件,需要去掉
			userinfo.state.opEvent = nil
		end
		userinfo.state.msglist = {} --如果这个时候有托管事件,需要去掉
	end
	return 0
 end
 function RoomClass:CheckOutWin(userinfo)
 	return false
 end
 function RoomClass:DoCheckOutCardLack(userinfo,card)
	 return true
 end
 function RoomClass:CheckIsCallListen(uid)
 end
 function RoomClass:DoRecordOutCard(userinfo, card)
 end
 function RoomClass:DoSkyListen(userinfo)
 end
 function RoomClass:DoMyOutCard(userinfo)
 end
 function RoomClass:DoMyGetCard(userinfo,card,gettype)
	 return true
 end
 function RoomClass:DoMyBarCard(userinfo)
 end
 function RoomClass:DoMyOperateCard(userinfo)
 end
 function RoomClass:DoMyCancleCard(userinfo)
 end
 function RoomClass:GetCircleGate()
 end
 function RoomClass:EventOutCardTimeOut(me)
	 local self = self or me 
	 self.state.opEvent = nil
	 self:Debug("出牌超时处理")
	 if self.state.operateSeat.playerInfo.state.hostType == 0 and self.state.props[144] ~= nil then --超时托管
		 self.state.props[144](self,self.state.operateSeat.playerInfo,{data={hostType=1,},})
	 elseif self.state.props[143] ~= nil then --超时等待
		 self.state.props[143](self,self.state.operateSeat.playerInfo)
	 else
		 if self.state.round.newGetCard then
			 self:DoOutCard(self.state.operateSeat.playerInfo,self.state.round.newGetCard.id)
		 else
			 local card = self.state.operateSeat:GetCardMaxThisid()
			 self:DoOutCard(self.state.operateSeat.playerInfo,card.id)
		 end
	 end
end
function RoomClass:EventOperateCardTimeOut(me)
	local self = self or me 
	 self.state.opEvent = nil
	self:Debug("操作超时处理")
	local seat,op = self.state.round:GetOperatePrioritySeatWait() 
	if op ~= nil then
		self.state.round.canOpSet = {} --清除掉其他可操作类型,然后再模拟添加本次被选中的优先级
		self.state.round.canOpSet[seat] = op --清除掉其他可操作类型,然后再模拟添加本次被选中的优先级
		--self.state.round.waitOpSet[seat]=nil
		self.state.round.waitOpSet ={}
		if op.opType == 2 then
			self:DoBarCard(seat.playerInfo,op.thisId)
		elseif op.opType == 6 then
			self:DoTouchCard(seat.playerInfo,op.thisId)
		elseif op.opType == 7 then
			self:DoEatCard(seat.playerInfo,op.eat.one,op.eat.two)
		else
			self:Error("遗漏处理的操作等待列表:" .. seat.playerInfo.id .. ":" .. op.opType .. ":" .. op.thisId)
			self:ResetOperator()
			self:EventDealOneCard()
		end
	else
		local firstSeat = self.state.round:GetOperatePrioritySeatCan()
		if firstSeat and firstSeat.playerInfo.state.hostType == 0 and self.state.props[144] ~= nil then --超时托管
			self.state.props[144](self,firstSeat.playerInfo,{data={hostType=1,},})
		else
			self:ResetOperator()
			self:EventDealOneCard()
		end
	end
end
function GetRoundResult(round,userinfo)
	if profi == 1 then
		--ProFi:stop()
		--ProFi:writeReport( 'MyProfilingReport.txt' )
		--profi = 0
		--local xx = profi + profiprofiprofi
	end
	local ret = round.owner:GetWinResult()
	local data={
		detailData = {
			timestamp = unitimer.now,
			statistics = {}
		}
	}
	if round.owner:IsLearnRooom() == false then
		for k,v in ipairs(ret.rewardSet) do
			table.insert(data.detailData.statistics,{uid=ret.uid,nickname=ret.nickname,integral=ret.totalReward,})
		end
		ChessToLobbyMgr.SendCmdToLobby("Cmd.UserRoundResultLobbyCmd_C",data)
	end
	if ret then
		round.owner.state.last_WinRetMahjongCmd_Brd = table.clone(ret)
	end
	return ret,nil --是否胡牌标志也需要传,不传就用totalReward为0判断
end
function RoomClass:GetWinResult() --流局
	local brd = {
		 rewardSet = {},
		 thisId = 0,
	}
	for i, v in ipairs(self.state.seats) do
		local ret = {}
		ret.uid = v.playerInfo.id
		ret.nickname = v.playerInfo.name
		ret.totalReward = 0
		ret.winType = 0
		ret.points = 0
		ret.userCard = v:GetUserCard(true,false)
		table.insert(brd.rewardSet,ret)
	end
	return brd
end
function RoomClass:GetMyFinalScore(state)
	return {}
end
function RoomClass:GetFinalScore(state)
	
	local totalScore = self.state.totalScore
	if table.len(totalScore) == 0 then
		self:Debug("GetRoomResult Fail 没打完一局就解散房间 roomid:"..self.id)
		return
	end
	local maxScore = nil

	for k,v in pairs(totalScore) do
		if maxScore == nil then
			maxScore = v.totalScore
		elseif maxScore < v.totalScore then
			maxScore = v.totalScore
		end
	end
	local brd = self:GetMyFinalScore(state) 
	if not brd then
		brd = {}
	end
	brd.state = state
	brd.roomId = self.id
	--local recordInfo = brd.recordInfo or {} --WHJ这里可以节省效率,但是需要放置重复,有空处理
	local recordInfo = {}

	for k,v in pairs(totalScore) do
		if v.uid == self.data.owner then
			v.isOwner = 1
		else
			v.isOwner = 0
		end
		if maxScore ~= 0 and v.totalScore == maxScore then
			v.isWinner = 1
		else
			v.isWinner = 0
		end

		local userinfo = UserInfo.GetUserInfoById(v.uid)
		if userinfo == nil then
			userinfo = RobotInfo.GetRobotInfoById(v.uid)
			local robotinfo = userinfo:GetBaseInfo()
			v.headurl = robotinfo.headurl
		else
			v.headurl = userinfo.data.base.headurl
		end
		v.nickname = userinfo.name
		table.insert(recordInfo, v)
		--if self:IsLearnRooom() and self.data.needDiamond and userinfo.data.mahjong.diamond>=self.data.needDiamond then --暂时如果是0也可以让玩
		if  self:IsLearnRooom() and (v.isWinner == 1 or self:GetRobotNum() > 0) then
			if self.data.needDiamond and userinfo.data.mahjong.diamond>=self.data.needDiamond then --暂时也可以让玩
				--练习场先不扣钻吧,瞎折腾,一帮猪头
				--ChessToLobbyMgr.SendCmdToLobby("Cmd.UserDiamondWinLobbyCmd_CS",{uid=userinfo.id,typ=5,change=-self.data.needDiamond,})
			end
		end
	end
	brd.recordInfo = self:FillOwnerTip(recordInfo)
	brd.recordInfo = self:FillRedPack(recordInfo)
	return brd
end

-- 填充红包
function RoomClass:FillRedPack(recordInfo)
	if self.data.redpacks and self:CheckGameOver() then
		local redpacks = {}
		for k,v in pairs(recordInfo) do
			local pos = self.data.history.position[v.uid]
			redpacks[pos] = {}
			redpacks[pos].uid = v.uid
			redpacks[pos].num = self.data.redpacks[k]
			v.redpack = self.data.redpacks[k]
		end
		-- 缓存红包信息 在销毁房间时发送给大厅
		self.state.redpacks = table2json(redpacks)
	end
	return recordInfo
end

-- 填充房主小费
function RoomClass:FillOwnerTip(recordInfo) -- tip:房主小费
	if self.data.hosttip ~= nil then
		local hasRoomOwner = false -- 房主是否也在
		local winnerNum = 0		   -- 大赢家个数(不包括房主)

		for k,v in pairs(recordInfo) do
			if v.isOwner == 1 then
				hasRoomOwner = true
			end
			if v.isWinner == 1 and v.isOwner ~= 1 then
				winnerNum = winnerNum + 1
			end
		end

		if hasRoomOwner == true and winnerNum > 0 then
			
			local maxScore1 = 0		-- 最大的分数
			local maxScore2 = 0		-- 第二大的分数
			for k,v in pairs(recordInfo) do
				if maxScore1 < v.totalScore then
					maxScore1 = v.totalScore
				elseif maxScore2 < v.totalScore then
					maxScore2 = v.totalScore
				end
			end

			local percent = self.data.hosttip

			local tip = 0
			if maxScore2 > 0 then
				tip = (maxScore1-maxScore2)*percent/winnerNum
			else
				tip = maxScore1*percent/winnerNum
			end
			tip = GetRoundInteger(tip)
	
			local tipList = {}
			for k,v in pairs(recordInfo) do
				if v.isWinner == 1 and v.isOwner ~= 1 then
					v.tip = 0 - tip
					v.totalScore = v.totalScore - tip
				end
				if v.isWinner ~= 1 and v.isOwner ~= 1 then
					v.tip = 0
				end
				if v.isWinner ~= 1 and v.isOwner == 1 then
					v.tip = tip*winnerNum
					v.totalScore = v.totalScore + tip*winnerNum
				end

				local pos = self.data.history.position[v.uid]
				tipList[pos] = {}
				tipList[pos].uid = v.uid
				tipList[pos].nickname = v.nickname
				tipList[pos].integral = v.tip
			end

			-- 缓存小费信息 在销毁房间时发送给大厅
			self.state.hostTip = table2json(tipList)
		end
	end
	return recordInfo
end

-- 小数部分四舍五入
function GetRoundInteger(num)
	local a,b = math.modf(num)
	if b >= 0.5 then
		a = a + 1
	end
	return a
end

function RoomClass:DrawGame() --流局
	if self.state.opEvent then
		self.state.opEvent:Stop()
		self.state.opEvent = nil
	end
	local brd = GetRoundResult(self.state.round)
	self:DoDiamondBalance(brd.rewardSet)
	self:Broadcast("Cmd.WinRetMahjongCmd_Brd", brd)
	self.state.curgamenbrWin = self.data.curgamenbr
	if self:CheckGameOver() then
		self:Info("牌局全部结束")
		if self.data.curgamenbr > 1 then
			self:Broadcast("Cmd.FinalScoreMahjongCmd_Brd", self:GetFinalScore(2))
		end
		self:Destroy()
		return
	end
	local len = 0 
	for k,v in ipairs(self.data.msglist) do
		len = len + string.len(v.msg)
	end
	self:Info("本局消息总个数:"..table.len(self.data.msglist)..",总长度:" .. table.len(json.encode(self.data.msglist)) .. ",消息总长度:"..len)
	--self:Debug(json.encode(self.data.msglist))
	self:ResetReady()
	self:CheckStart() --临时添加用来循环测试


end
function RoomClass:Loop(me)
	local self = self or me
	local oldEvent = self.state.opEvent
	if oldEvent and oldEvent:Check(unitimer.now) == true and oldEvent.maxtimes <= 0 and oldEvent == self.state.opEvent then
		 self.state.opEvent = nil
	end
	self.state.timerOneSec:Check(unitimer.now)
	if self.state.readyForOperate == true then
		for k,v in ipairs(self.state.seats) do
			v:Loop()
		end
	else
		if unilight.getgameid() == 4055 and self:GetPlayerNum() == self.data.usernbr and self:IsLearnRooom() then --江西客家麻将需求
			for k,v in ipairs(self.state.seats) do
				if v.bReady then
					v.playerInfo.state.readyTimeOutEvent = nil
				elseif not v.bReady and not v.playerInfo.state.readyTimeOutEvent then
					v.playerInfo.state.readyTimeOutEvent = NewUniEventClass(UserInfoClass.EventTimeOutLeaveRoom, 60000,1,v.playerInfo,v.playerInfo)
				elseif v.playerInfo.state.readyTimeOutEvent then
					v.playerInfo.state.readyTimeOutEvent:Check(unitimer.now)
				end
			end
		end
	end
	if self.state.dissoveEvent and self.state.dissoveEvent:Check(unitimer.now) == true then
		 self.state.dissoveEvent = nil
	end
	if self.state.addRobotEvent and self.state.addRobotEvent:Check(unitimer.now) == true then
		--self.state.addRobotEvent = nil
	end
end
function RoomClass:CheckAddRobot()

	if self:IsLearnRooom() and self:GetIdleSeat(nil) ~= nil and self:HasAnyUser() == true then
		if  self:GetRobotNum() < self.state.maxRobotNum then
			--机器人如果赌钻石,就不上场
			if unilight.getdebuglevel() > 0 or ((not self.data.winDiamond or self.data.winDiamond == 0) and math.random(1,5) == 1) then
				self:AddNewRobot(RobotInfo.CreateRobot(self))
			end
		else
			--self:ChangeUserNbr(self:GetPlayerNum())
		end
	end
	--以下是临时用
	if self:HasAnyUserReady() then --如果没有玩家,则自动准备,如果有玩家,则有玩家准备了,机器人才开始准备
		for k,v in ipairs(self.state.seats) do
			if v.playerInfo and v.playerInfo:IsRobot() == true and v.bReady == false then
				if unilight.getdebuglevel() > 0 or math.random(1,3) == 1 then
					self:DoReadyStart(v.playerInfo)
				end
				break
			end
		end
	end
end
function RoomClass:TimerOneSec(me)
	local self = self or me
	if self.state.readyForOperate == false then
		self:CheckAddRobot()
	end
end

function RoomClass:GetAllCardThisidByIndex(index)
	local card = self.state.allCard[index]
	if card then
		return card.base.thisid
	end
	return 0
end
function RoomClass:GetCardTypeByThisid(thisid)
	if  thisid  < 10 then
		return thisid
	elseif  thisid  < 100 then
		return math.floor(thisid / 10)
	else
		return math.floor(thisid / 100)
	end
end
-- 抓牌
function RoomClass:GetOneCard(thisid,normal) --可以指定thisid,也可以指定是否要拿normal牌
	thisid = thisid or 0
	local tmpid = thisid
	local card = self.state.heapCard[thisid]
	if card == nil and thisid >0 then
		if  thisid  < 10 then
			thisid = CardTypeMap[thisid][math.random(1,#(CardTypeMap[thisid]))].thisid --类型牌里随机
		elseif  thisid  < 100 then
			thisid = thisid * 10
		end
		thisid = math.floor(thisid / 10) * 10 --只指定牌,不能指定是四张里面的哪一张,要循环去查找
		for i = 1 , 4 do
			thisid = thisid + 1
			card = self.state.heapCard[thisid]
			if card ~= nil then
				self.state.heapCard[thisid] = nil
				break
			end
		end
		self:Shuffle()
	else
		self.state.heapCard[thisid] = nil
	end
	if card == nil then
		card = self:RemoveOneHeapCard(normal)
	end
	if card then
		--self:Shuffle()
		if self.state.operateSeat then
			self:Debug("摸牌:"..card:GetId() .. ":" .. self.state.operateSeat.playerInfo.id .. ":" ..table.len(self.state.heapCard) .. ":" .. self.state.operateSeat.point)
		else
			self:Debug("摸牌:"..card:GetId() .. ":" .. 0 .. ":" ..table.len(self.state.heapCard))
		end
	elseif thisid and thisid ~= 0 then
		self:Error("牌堆里没牌了")
	else
		self:Error("摸牌失败:" ..table.len(self.state.heapCard))
	end
	return card
end
function RoomClass:ChangeOneCard(card,newid) --换出一张牌,可以指定,也可以不指定
	local newcard = self:GetOneCard(newid)
	if newcard and newcard ~= card then
		if card then
			self.state.heapCard[card.base.thisid] = card
			self.state.heapCard[newid] = nil
			table.insert(self.state.shuffleCard,card.base.thisid)
			self:Shuffle()
		else
			self:Error("换牌时没有传要换的牌,小心相公:" .. newid)
		end
	else
		newcard = card
	end
	return newcard
end

function RoomClass:RemoveOneHeapCard(normal,nesttimes)
	nesttimes = nesttimes or 0
	local heapCardNum = self:GetHeapCardNum()
	local drawnum = self.state.drawnum or self.base.drawnum or 0
	if DRAW_CARD_NUMBER  then --如果指定,兼容老代码
		drawnum = DRAW_CARD_NUMBER
	end
	if heapCardNum <= drawnum then --如果指定
		self:Error("RemoveOneHeapCard:牌堆剩余数量限制,已经结束了:"..drawnum)
		return nil
	end
	local thisid = nil
	if heapCardNum <= drawnum + 10 and not self.state.outCardBaseIdNum[math.floor(self.state.shuffleCard[1]/10)] then --剩10张牌时,指定最后一张牌,不能是特殊牌,也不能被杠,避免后续操作麻烦
		for k,v in ipairs(self.state.shuffleCard) do
			local tmpcard = self.state.heapCard[v]
			if self:IsNormalCard(tmpcard.base) then --这里只是为了确保最后一张牌是个普通牌
				if self.state.outCardBaseIdNum[tmpcard.base.baseid] then --这张牌再牌池子了,就不会被杠
					table.remove(self.state.shuffleCard,k)
					table.insert(self.state.shuffleCard,1,v)
					self:Debug("RemoveOneHeapCard:指定最后一张牌:"..tmpcard.id)
					break
				end
			end
		end
	end
	if heapCardNum == drawnum + 1 then --如果是最后一张牌,需要给控制好的那张牌,不会杠的普通牌
		thisid = table.remove(self.state.shuffleCard,1) --取最后一张
	end
	if thisid == nil and normal == true then
		for i = heapCardNum, 1, -1 do
			local v = self.state.shuffleCard[i]
			if v ~= nil and self.state.heapCard[v] ~= nil and self:IsNormalCard(self.state.heapCard[v].base) then
				thisid = table.remove(self.state.shuffleCard,i)
				break
			end
		end
	end
	if thisid == nil then
		thisid = table.remove(self.state.shuffleCard)
	end
	if thisid == nil then
		self:Error("RemoveOneHeapCard:牌堆里没牌了:"..table.len(self.state.heapCard) .. ":" .. table.len(self.state.shuffleCard))
		return nil
	end
	if nesttimes == 0 and self.base.delayCard == math.floor(thisid/100) and math.random(1,10000) < self.base.delayCardProb then
		self:Error("推迟牌,换一张:"..thisid)
		self:Shuffle()
		return self:RemoveOneHeapCard(normal,nesttimes + 1)
	end
	local card = self.state.heapCard[thisid]
	self.state.heapCard[thisid] = nil
	if card == nil then
		self:Error("RemoveOneHeapCard:牌堆数据跟洗牌数据不一致了,有风险:"..thisid)
		self:Shuffle()
		return self:RemoveOneHeapCard(normal)
	end
	self.state.outCardBaseIdNum[card.base.baseid] = (self.state.outCardBaseIdNum[card.base.baseid] or 0) + 1
	return card
end

function RoomClass:CheckFollowCard()
end
function RoomClass:CheckCanWinCard(userinfo)
	return true
end
function RoomClass:CheckCanEatCard()
	return true
end
function RoomClass:CheckCanTouchCard()
	return true
end
function RoomClass:CheckIsCallListen(uid)
	return false
end
function RoomClass:DoTouchCard(userinfo,thisid)
	if self:CheckIsCallListen(userinfo.id) then
		userinfo:Error("玩家已经叫听,不能碰牌")
		return false
	end
	if self:CheckReadyForOperate() == false then
		userinfo:Error("系统操作时间,个人不能操作")
		return false
	end
	if self:CheckCanTouchCard() == false then
		userinfo:SendFailToMe("本房间不支持碰牌玩法")
		--self:DoCancelOperate(userinfo)
		return false
	end
	if self.state.round.newOutCard ==nil then
		if userinfo.state.hostType == 0 then
			userinfo:SendFailToMe("要碰的牌已经被别人抢走了")
			userinfo:Error("要碰的牌已经被别人抢走了")
		end
		--self:DoCancelOperate(userinfo)
		return false
	end
	thisid = thisid or self.state.round.newOutCard.id
	if self.state.round.newOutCard.id ~= thisid then
		if userinfo.state.hostType == 0 then
			userinfo:SendFailToMe("最新摸到的牌和要碰的牌不一致")
			userinfo:Error("最新摸到的牌和要碰的牌不一致:"..self.state.round.newOutCard.id .. ":" .. thisid)
		end
		--self:DoCancelOperate(userinfo)
		return false
	end
	if userinfo.state.seat:GetHandCardNumByBaseId(self.state.round.newOutCard.base.baseid) < 2 then
		userinfo:SendFailToMe("数量不够,不能碰")
		userinfo:Error("数量不够,不能碰:"..thisid)
		--self:DoCancelOperate(userinfo)
		return false
	end
	local firstSeat = self.state.round:GetOperatePrioritySeat(userinfo.state.seat,6)
	if firstSeat ~= userinfo.state.seat then
		--userinfo:SendFailToMe("碰操作优先级不够,请等待")
		if firstSeat then
			userinfo:Error("碰操作优先级不够:" .. thisid .. ",请等待:" .. firstSeat.playerInfo.id .. "先操作")
		else
			userinfo:Error("碰操作优先级不够:" .. thisid .. ",请等待:" .. self.state.operateSeat.playerInfo.id)
		end
		self.state.round.waitOpSet[userinfo.state.seat]= {opType=6,thisId=thisid,}
		userinfo:SendCmdToMe("Cmd.CancelOpMahjongCmd_S", "{}")
		return false
	end

	--TODO 这里要做优先级检查
	
	local brd = {
		obj = {},
	}
	brd.obj = userinfo.state.seat:TouchCard(self.state.round.newOutCard,self.state.operateSeat.playerInfo.id)
	brd.card_type = self:GetCardType(self.state.round.newOutCard)
	if brd.obj == nil then
		userinfo:SendFailToMe("碰牌失败")
		userinfo:Error("碰牌失败,未知原因")
		return false
	end
	self.state.operateSeat:RemoveOutCard(self.state.round.newOutCard)
	self:Broadcast("Cmd.TouchCardMahjongCmd_Brd", brd)
	self:DoMyOperateCard(userinfo)
	self:ResetOperator(userinfo.state.seat) --重置操作者为碰牌者
	local card = userinfo.state.seat:GetCardMaxThisid()
	userinfo:Info("碰牌成功:"..card.id .. ":" ..self.state.round.newOutCard.id .. ":" .. json.encode(brd.obj))
	userinfo.state.seat.handCard[card.id] = nil --模拟发牌
	self.state.opEvent = nil
	self:EventDealOneCard(self,card,10)
end

function RoomClass:CheckCanBarCard()
	return true
end
function RoomClass:DoBarCard(userinfo,thisid)
	if self:CheckIsCallListen(userinfo.id) then
		userinfo:Error("玩家已经叫听,不能杠牌")
		return false
	end
	if self:CheckReadyForOperate() == false then
		userinfo:Error("系统操作时间,个人不能操作")
		return false
	end
	if self:CheckCanBarCard() == false then
		userinfo:SendFailToMe("本房间不支持杠牌玩法")
		--self:DoCancelOperate(userinfo)
		return false
	end
	local card = userinfo.state.seat.handCard[thisid]
	if card == nil then
		if self.state.round.newOutCard ==nil then
			if userinfo.state.hostType == 0 then
				userinfo:SendFailToMe("要杠的牌已经被别人抢走了:"..thisid)
				userinfo:Error("要杠的牌已经被别人抢走了:"..thisid)
			end
			--self:DoCancelOperate(userinfo)
			return false
		end
		card = self.state.round.newOutCard
	end
	if userinfo.state.seat:CheckBarCard(card,self.state.operateSeat.playerInfo.id) == nil then
		userinfo:SendFailToMe("数量不够,不能杠")
		userinfo:Error("数量不够,不能杠:"..thisid)
		return false
	end
	local firstSeat = self.state.round:GetOperatePrioritySeat(userinfo.state.seat,2)
	if firstSeat ~= userinfo.state.seat then
		--userinfo:SendFailToMe("杠操作优先级不够,请等待")
		if firstSeat then
			userinfo:Error("杠操作优先级不够:" .. thisid .. ",请等待:" .. firstSeat.playerInfo.id .. "先操作")
		else
			userinfo:Error("杠操作优先级不够:" .. thisid .. ",请等待:" .. self.state.operateSeat.playerInfo.id)
		end
		self.state.round.waitOpSet[userinfo.state.seat]= {opType=2,thisId=thisid,}
		userinfo:SendCmdToMe("Cmd.CancelOpMahjongCmd_S", "{}")
		return false
	end

	--TODO 这里要做优先级检查
	
	local brd = {
		obj = {},
	}
	brd.obj = userinfo.state.seat:BarCard(card,self.state.operateSeat.playerInfo.id)
	if brd.obj == nil then
		userinfo:SendFailToMe("杠牌失败")
		userinfo:Error("杠牌失败,未知原因")
		return false
	end
	if brd.obj.barType == 102 then
		brd.obj.fromUid = userinfo.id
	end
	brd.card_type = self:GetCardType(card)
	self.state.operateSeat:RemoveOutCard(card) -- 这里有冗余,如果是杠自己的牌,已经在BarCard里清楚了
	self:Broadcast("Cmd.BarCardMahjongCmd_Brd", brd)
	self:DoMyBarCard(userinfo)
	self:ResetOperator(userinfo.state.seat) --重置操作者为杠牌者
	self.state.opEvent = nil
	self:EventDealOneCard(self,nil,1)
	if self.state.round then
		userinfo:Info("杠牌成功:"..card.id .. ":" ..self.state.round.newGetCard.id .. ":" .. json.encode(brd.obj))
	end
end
function RoomClass:DoFinalScore(userinfo)
	self:Error("等待总结算:"..userinfo.id)
	--self:Broadcast("Cmd.LeaveMahjongCmd_Brd", {uid=userinfo.id,})
	if userinfo.state.seat == self.state.operateSeat then
		self.state.operateSeat = nil
	end
	--userinfo.state.seat = nil
	self:Destroy()
end
function RoomClass:Destroy(noSend)
	if self.state.loopTimer then
		self.state.loopTimer:Stop()
		self.state.loopTimer = nil
	end
	local tmp = ""
	for k,v in ipairs(self.state.seats) do
		if v.playerInfo then
			tmp = tmp ..":" .. v.playerInfo.id .. ":" .. v.point
			v.playerInfo:Destroy()
			v.playerInfo = nil
		end
	end
	GlobalRoomInfoMap[self.id]=nil
	self:Save()
	self:Debug("房间销毁" .. tmp)
	if self:IsLearnRooom() == false and noSend ~= true then
		ChessToLobbyMgr.SendRemoveRoomToLobby(self.id, self.state.hostTip, self.state.redpacks)
	end
end
function RoomClass:BroardBaseInfoToUser(userinfo)
	--广播给其它玩家
	local brd = {
	}
	for i, v in ipairs(self.state.seats) do -- 把其他人发给自己
		if v.playerInfo then
			brd.userInfo = userinfo:GetBaseInfo(v.playerInfo)
			v.playerInfo:SendCmdToMe("Cmd.EnterMahjongCmd_Brd", brd)
		end
	end
end
 --如果分支需要扩充字段,直接写这个函数
function RoomClass:GetMyReConnectData(userinfo,data)
	return data
end
 --如果分支需要增加更多协议发送,写在这里
function RoomClass:DoMyEnterMahjong(userinfo)
end
function RoomClass:DoEnterMahjong(userinfo, isAdvance)
	userinfo:Online()
	local oldCompress = userinfo.state.jsonCompress --这里是为了兼容托管模式
	userinfo.state.jsonCompress = nil
	
	if (self.base.prepareType == 0 or (not self:IsLearnRooom() and self.data.curgamenbr >= 1) or isAdvance == true) and not self.state.last_WinRetMahjongCmd_Brd then
		userinfo.state.seat.bReady = true
	end
	userinfo.state.seat.last_EnterMahjongCmd_S = userinfo:SendCmdToMe("Cmd.EnterMahjongCmd_S",{ownerId = self.data.owner,roomState = self:GetRoomState(userinfo),})
	self:BroardBaseInfoToUser(userinfo)
	if self.state.last_WinRetMahjongCmd_Brd then
		userinfo:SendCmdToMe("Cmd.WinRetMahjongCmd_Brd", self.state.last_WinRetMahjongCmd_Brd,true)
	end
	if self.state.last_CashChickenCmd_Brd then
		userinfo:SendCmdToMe("Cmd.CashChickenCmd_Brd", self.state.last_CashChickenCmd_Brd,true)
	end
	if self:IsAlreadyStart() == true then
		local data = {
			heapCardNum = self:GetHeapCardNum(),
			roomId=self.id , 
			curGameNbr=self.data.curgamenbr,
		}
		if self.state.round then
			data.goldCardSet = self.state.round:GetGoldCardSet()
		end
		if self.state.bankerSeat then
			data.bankerId = self.state.bankerSeat.playerInfo.id
			data.eastUid = self:GetEastUid()

		end
		if self.state.round and self.state.round.SendSelfCardOk or self.state.readyForOperate then --WHJ 断线重连又没在准备状态似乎会多发数据下去
			for k,v in ipairs(self.state.seats) do
				if v.playerInfo then
					if v.playerInfo == userinfo then
						data.userCard = v:GetUserCard(true,true)
					else
						data.otherCard = data.otherCard or {}
						if unilight.getdebuglevel() > 0 then
							table.insert(data.otherCard,v:GetUserCard(true,true))
						else
							table.insert(data.otherCard,v:GetUserCard(false,true))
						end
					end
				end
			end
		else
			data.userCard = data.userCard or {} --否则客户端可能报错
			data.otherCard = data.otherCard or {} --否则客户端可能报错
		end
		local circle = math.floor(self.data.curgamenbr/4) + 1
		if self.data.curgamenbr%4 == 0 then
			circle = circle -1
		end
		local gate = self.data.curgamenbr%4
		if gate == 0 then
			gate = 4
		end
		data.circle = circle
		data.gate = gate
		data.goldType = self.base.goldType
		if self.state.round and userinfo.state.seat.last_winCardSet then
			data.winCardSet = userinfo.state.seat.last_winCardSet
		end
		data = self:GetMyReConnectData(userinfo,data) --如果分支需要扩充字段,直接写这个函数
		if self.state.operateSeat and self.state.operateSeat.playerInfo == userinfo and self.state.round.newGetCard then
			local card = self.state.round.newGetCard
			if data.userCard and data.userCard.handCardSet then
				for k1,v1 in ipairs(data.userCard.handCardSet) do
					if v1 == card.id then
						table.remove(data.userCard.handCardSet,k1)
						break
					end
				end
			end
		end
		userinfo:SendCmdToMe("Cmd.ReConnectMahjongCmd_S",data,true)
		if self.state.operateSeat then
			if self.state.operateSeat.playerInfo == userinfo then
				local card = self.state.round.newGetCard
				if card  then
					--self:DealOneCard(userinfo.state.seat,card,self.state.round.newGetCardType)
					self:DealOneCard(userinfo.state.seat,card,true)
				end
			else
				local card = self.state.round.newOutCard
				if card  and userinfo.state.seat.last_OutCardMahjongCmd_Brd then
					if self.state.opEvent then
						userinfo.state.seat.last_OutCardMahjongCmd_Brd.sec = math.floor((self.state.opEvent.nextmsec - unitimer.now)/1000)
					else
						userinfo.state.seat.last_OutCardMahjongCmd_Brd.sec = 0
					end
					--WHJ 先去掉当前托管的消息,再重发一遍,否则有问题
					if userinfo.state.opEvent then --如果这个时候有托管事件,需要去掉
						userinfo.state.opEvent = nil
					end
					userinfo.state.msglist = {} --如果这个时候有托管事件,需要去掉
					userinfo:SendCmdToMe("Cmd.OutCardMahjongCmd_Brd", userinfo.state.seat.last_OutCardMahjongCmd_Brd)
				end
			end
		end
		userinfo:Info("断线重连进入")
		self:DoMyEnterMahjong(userinfo)
		self:CheckStart()
	else
		if self.base.prepareType == 1 then
			--userinfo.state.seat.bReady = false
		else
			--WHJ先设置成false
			userinfo.state.seat.bReady = false
			self:DoReadyStart(userinfo)
		end
		self:CheckStart()
		userinfo:Info("新用户进入")
		self:EventSendQuickStart()
		self:EventSendPrepareBtn(userinfo)
	end
	userinfo.state.jsonCompress = oldCompress--这里是为了兼容托管模式
	userinfo:CheckDissolveRoom()
end
function RoomClass:DoLeaveRoom(userinfo)
	if self:CanLeaveRoom() == false then
		userinfo:SendFailToMe("已经开局,不能中途离开")
		return false
	end

	self:Debug("请求离开桌子:"..userinfo.id)
	if self:IsLearnRooom() then
		self:Destroy()
	else
		--if self.data.owner == userinfo.id and userinfo.data.mahjong.diamond < 100 then
		--	userinfo:SendFailToMe("房主携带低于100,不能返回大厅")
		--	return true
		--end
		self:Broadcast("Cmd.LeaveMahjongCmd_Brd", {uid=userinfo.id,state=0,})
		if self.state.readyForOperate == false then
			self.state.broadcastRoom.Rum.RemoveRoomUser(userinfo.state.laccount)
			userinfo.state.seat.playerInfo = nil
			userinfo.state.seat = nil
		end
		ChessToLobbyMgr.SendLeaveRoomToLobby(userinfo.id,self.id)
		userinfo:Destroy()
	end
	return true
end

function RoomClass:EventSendQuickStart(me)
	local self = self or me
	if self:IsAlreadyStart() then
		return false
	end
	local need = false
	local host = nil
	for k,v in ipairs(self.state.seats) do
		if v.playerInfo == nil then
			need = true
		elseif self.data.owner == v.playerInfo.id then
			host = v.playerInfo
		end
	end
	if need and host and self:IsLearnRooom() == false then
		host:SendCmdToMe("Cmd.ShowChangeUserNbrRoom_S", {})
	end
end
function RoomClass:EventSendPrepareBtn(userinfo)
	if self.base.prepareType == 1 and userinfo.state.seat.bReady ~= true then
		if self:IsAlreadyStart() then
			return false
		end
		userinfo:SendCmdToMe("Cmd.ShowPrepareBtnRoom_S", {})
	end
end
function RoomClass:EventDissolveRoom(me)
	local self = self or me
	local check = false
	for k,v in ipairs(self.state.seats) do
		if v.isAgreeDissolve ~= 1 then
			check = true
			v.isAgreeDissolve = 1
		end
	end
	if check == true then
		self:CheckDissolveRoomOk()
		self:Debug("超时解散房间")
	end
end
function RoomClass:DoRequestChangeUserNbr(userinfo)
	if self:IsAlreadyStart() then
		userinfo:SendFailToMe("已经开局,不能改变人数了")
		return false
	end
	if self.data.owner ~= userinfo.id then
		userinfo:SendFailToMe("只有房主才能申请提前开局")
		return false
	end
	self:BroadcastExceptOne("Cmd.RequestChangeUserNbrRoom_Brd", {uid=userinfo.id,},userinfo.id,true)
	for k,v in ipairs(self.state.seats) do
		v.isAgreeChangeUserNbr = nil
	end
	userinfo.state.seat.isAgreeChangeUserNbr = 1
	return true
end
function RoomClass:DoReturnChangeUserNbr(userinfo,isagree)
	if self:IsAlreadyStart() then
		userinfo:SendFailToMe("已经开局,不能改变人数了")
		return false
	end
	if isagree ~= 1 then
		self:BroadcastSys("因" .. userinfo.name .. "拒绝,提前开局改变房间人数失败")
		for k,v in ipairs(self.state.seats) do
			v.isAgreeChangeUserNbr = nil
		end
		return true
	end
	self:BroadcastSys(userinfo.name .. "已经同意改变房间人数提前开局")
	userinfo.state.seat.isAgreeChangeUserNbr = 1
	local ok = true
	for k,v in ipairs(self.state.seats) do
		if v.playerInfo and v.isAgreeChangeUserNbr ~= 1 then
			ok = false
		end
	end
	if ok == true then
		local data = {
			roomId = self.id,
			userNbr = self:GetPlayerNum(),
			uid = userinfo.id,
		}
		ChessToLobbyMgr.SendCmdToLobby("Cmd.ChangeUserNbrLobbyCmd_CS",data)
		self:BroadcastSys("经所有人同意,正在处理改变房间人数请求")
		self:Debug("经所有人同意,正在处理改变房间人数请求")
	end
	return true
end
function RoomClass:DoDissolveRoom(userinfo,touserinfo)
	if touserinfo then
		--if userinfo == touserinfo then
		--	userinfo:SendCmdToMe("Cmd.RequestDissolveRoom_S", {userNum = self:GetCurrentUserNum(),},false)
		--elseif self.state.dissoveEvent then
		if self.state.dissoveEvent then
			touserinfo:SendCmdToMe("Cmd.RequestDissolveRoom_Brd", {uid=userinfo.id,waitTime=math.floor((self.state.dissoveEvent.nextmsec - unitimer.now)/1000),},userinfo.id,true)
		end
		touserinfo:SendCmdToMe("Cmd.ReplyDissolveRoom_Brd", {uid=userinfo.id,isAgree=userinfo.state.seat.isAgreeDissolve,},true)
	else
		if self.state.dissoveEvent and self.state.Dissolver and self.state.Dissolver ~= userinfo then
			userinfo:SendFailToMe("已经有人申请解散房间了")
			return
		end
		for k,v in ipairs(self.state.seats) do
			v.isAgreeDissolve = nil
		end
		userinfo:Debug("请求解散房间")
		userinfo.state.seat.isAgreeDissolve = 1
		self.state.Dissolver = userinfo
		--self:BroadcastExceptOne("Cmd.RequestDissolveRoom_Brd", {uid=userinfo.id,waitTime=self.base.closeroomchooseTime/1000,},userinfo.id,true)
		self:Broadcast("Cmd.RequestDissolveRoom_Brd",{uid=userinfo.id,waitTime=self.base.closeroomchooseTime/1000,},true)
		userinfo:SendCmdToMe("Cmd.RequestDissolveRoom_S", {userNum = self:GetCurrentUserNum(),},false)
		self:Broadcast("Cmd.ReplyDissolveRoom_Brd", {uid=userinfo.id,isAgree=userinfo.state.seat.isAgreeDissolve,},true)
		self.state.dissoveEvent = NewUniEventClass(RoomClass.EventDissolveRoom, self.base.closeroomchooseTime, 1, self)
		self:CheckDissolveRoomOk()
	end
end
function RoomClass:GetCurrentUserNum()
	local ret = 0
	for k,v in ipairs(self.state.seats) do
		if v.playerInfo then
			ret = ret + 1
		end
	end
	return ret
end

function RoomClass:GetOnlineCurrentUserNum()
	local ret = 0
	for k,v in ipairs(self.state.seats) do
		if v.playerInfo and v.playerInfo.state.onlineState ~= nil and v.playerInfo.state.onlineState >= 1 then
			ret = ret + 1
		end
	end
	return ret
end

function RoomClass:TimeOutIdle(userinfo)
	self:BroadcastSys(userinfo.name .. "处于超时等待状态")
	self:Debug("超时等待:"..userinfo.id)
	self:Broadcast("Cmd.TimeOutWaitMahjongCmd_Brd", {uid=userinfo.id,nickname=userinfo.name})
end
function RoomClass:CheckCanHost(hosttype)
	return self.state.props[144] ~= nil
end
function RoomClass:DoListenObjMahjong(userinfo,cmd)
	if userinfo.state.seat.last_listenObjSet then
		local send ={}
		if cmd.data.thisId then
			local index = nil
			send.thisId = cmd.data.thisId
			for k,v in ipairs(userinfo.state.seat.last_listenSet) do
				if math.floor(v/10) == math.floor(send.thisId/10) then
					index = k
				end
			end
			if index then
				send.los = userinfo.state.seat.last_listenObjSet[index]
			end
		elseif cmd.data.index then
			send.index = cmd.data.index
			send.los = userinfo.state.seat.last_listenObjSet[send.index]
		end
		if send.los then
			userinfo:SendCmdToMe("Cmd.ListenObjMahjongCmd_S", send)
		end
	end
	return true
end
function RoomClass:DoHostMahjong(userinfo,cmd)
	if self.state.readyForOperate == false and cmd.data.hostType ~= 0 then
		--userinfo:SendFailToMe("开局后才能托管")
		--return false
	end
	userinfo:Debug("请求托管:"..cmd.data.hostType)
	--if self:CheckCanHost(hosttype) == false then
	--	userinfo:SendFailToMe("本房间不支持托管")
	--	return false
	--end
	if cmd.data.hostType == userinfo.state.hostType then
		self:Broadcast("Cmd.HostMahjongCmd_Brd", {uid=userinfo.id,hostType=cmd.data.hostType,},true)  --这里为了保持跟客户端一致,冗余发
		--userinfo:SendFailToMe("托管状态未发生变化")
		return true
	end

	if self:DoMyHostMahjong(userinfo) == false then
		return false		
	end

	userinfo.state.hostType = cmd.data.hostType
	self:Broadcast("Cmd.HostMahjongCmd_Brd", {uid=userinfo.id,hostType=cmd.data.hostType,},true)
	if userinfo.state.hostType > 0 then
		userinfo.state.timerOneSec = NewUniTimerClass(UserInfoClass.TimerOneSec, 1000,userinfo) --托管时间以秒为单位 
		if self.state.operateSeat and self.state.operateSeat.playerInfo == userinfo then 
			if self.state.round.newGetCard and not next(self.state.round.canOpSet) then
				local data= {
					thisId = self.state.round.newGetCard.id,
					heapCardNum = self:GetHeapCardNum(),
				}
				data.opType, data.listenSet, data.listenObjSet = userinfo.state.seat:GetMyOperateType()
				userinfo.state.seat.last_listenObjSet = table.clone(data.listenObjSet)
				userinfo.state.seat.last_listenSet = table.clone(data.listenSet)
				data.barSet = userinfo.state.seat:GetCanBarId()
				data = userinfo.state.seat:GetMyOperateData(data) -- 如果分支有需要扩展操作,可重写
				if self.state.round.newGetCardType == 1 then
					data.isBar = 1
				end
				userinfo:SendCmdToMeHost("Cmd.SendCardMahjongCmd_S", data) --模拟法一张牌
				userinfo:TimerOneSec() --直接执行,否则会错过这次操作
				--self:DoOutCard(userinfo,userinfo.state.seat:GetOneCard().id)
			else
				userinfo:SendFailToMe("托管操作将在下一轮开始生效")
			end
		elseif self.state.round then
			if userinfo.state.seat.last_OutCardMahjongCmd_Brd then
				if self.state.opEvent then
					userinfo.state.seat.last_OutCardMahjongCmd_Brd.sec = math.floor((self.state.opEvent.nextmsec - unitimer.now)/1000)
				else
					userinfo.state.seat.last_OutCardMahjongCmd_Brd.sec = 0
				end
				userinfo:SendCmdToMeHost("Cmd.OutCardMahjongCmd_Brd", userinfo.state.seat.last_OutCardMahjongCmd_Brd)
				userinfo:TimerOneSec() --直接执行,否则会错过这次操作
			end
			--self:DoCancelOperate(userinfo)
		end
	else
		if userinfo.state.opEvent then --如果这个时候有托管事件,需要去掉
			userinfo.state.opEvent = nil
		end
		userinfo.state.msglist = {} --如果这个时候有托管事件,需要去掉
	end
	return true
end

function RoomClass:DoMyHostMahjong(userinfo)
	return true
end

function RoomClass:DoReplyDissolveRoom(userinfo,cmd,touserinfo)
	userinfo:Debug("回应解散房间:"..cmd.data.isAgree)
	if self.state.dissoveEvent == nil then
		userinfo:SendFailToMe("已经取消解散房间")
		return true
	end
	userinfo.state.seat.isAgreeDissolve = cmd.data.isAgree
	local bok = self:CheckDissolveRoomOk()
	if touserinfo then
		touserinfo:SendCmdToMe("Cmd.ReplyDissolveRoom_Brd", {uid=userinfo.id,isAgree=cmd.data.isAgree,},true) --断线重连后重新组织数据发给客户端
	else
		self:Broadcast("Cmd.ReplyDissolveRoom_Brd", {uid=userinfo.id,isAgree=cmd.data.isAgree,},true)
	end
	if bok == false then
		userinfo:SendFailToMe("操作已提交,请等待其他选择")
	end
	return true
end
--检查是否在解散房间状态
function RoomClass:IsDissolveRooming()
	for k,v in ipairs(self.state.seats) do
		if v.isAgreeDissolve ~= nil then
			return true
		end
	end
	return false
end
function RoomClass:CheckDissolveRoomOk()
	if self.state.dissoveEvent == nil then
		return
	end
	local data = {
		agreeUsers = {},
		disagreeUsers = {},
	}
	for k,v in ipairs(self.state.seats) do
		if not v.playerInfo then
		--elseif v.playerInfo.state.onlineState == 0 or v.playerInfo:IsRobot() then
		elseif v.isAgreeDissolve == 1 then
			table.insert(data.agreeUsers,v.playerInfo.name)
		elseif v.isAgreeDissolve == 0 then
			table.insert(data.disagreeUsers,v.playerInfo.name)
		elseif v.playerInfo.state.onlineState == 0 and not v.playerInfo.state.dissolveRoomEvent and not v.playerInfo:IsRobot() then
			--离线状态给30秒等待时间等待上线
			v.playerInfo.state.dissolveRoomEvent = NewUniEventClass(UserInfoClass.EventDissolveRoom, 30000,1,v.playerInfo,v.playerInfo,{data={isAgree=1,},})
		end
	end
	--if table.len(data.agreeUsers) > math.floor(self:GetCurrentUserNum()/2) then
	local agreenum = table.len(data.agreeUsers)
	if table.len(data.disagreeUsers) > 0 then
		data.bOk = false
		self:Broadcast("Cmd.SuccessDissolveRoom_Brd", data,true)
		self:Debug("解散房间失败")
		for k,v in ipairs(self.state.seats) do
			if v.playerInfo then
				v.isAgreeDissolve = nil
			end
		end
		self.state.Dissolver = nil
		self.state.dissoveEvent = nil
		return true
	elseif agreenum >= self:GetCurrentUserNum() or ((self.state.readyForOperate == false or self:IsLearnRooom()) and agreenum >= self:GetOnlineCurrentUserNum()) then --GetOnlineCurrentUserNum
		data.bOk = true
		self:Debug("解散房间成功:"..agreenum .. ":" .. self:GetCurrentUserNum() .. ":" .. self:GetOnlineCurrentUserNum())
		if self:CheckSendFinalScore() then
			self:Broadcast("Cmd.FinalScoreMahjongCmd_Brd", self:GetFinalScore(1),true)
		else
			self:Broadcast("Cmd.SuccessDissolveRoom_Brd", data,true)
		end
		self:Destroy()
		self.state.dissoveEvent = nil
		return true
	end
	return false
end

-- 检测是否需要发送最终面板信息
function RoomClass:CheckSendFinalScore()
	if self.data.curgamenbr > 1 or (self.data.curgamenbr == 1 and self:IsAllReady() == false) then
		return true
	end
	return false
end

function RoomClass:EventDoReadyStart(me)
	local self = self or me 
	for i, v in ipairs(self.state.seats) do
		if v.playerInfo and v.bReady == false and v.playerInfo.state.hostType ~= 0 then
			self:DoReadyStart(v.playerInfo)
			v.playerInfo:Debug("EventDoReadyStart")
		end
	end
end
function RoomClass:DoReadyStart(userinfo, readyType)
	if readyType == nil then
		if userinfo.state.seat.bReady == true then
			--userinfo:SendFailToMe("已经准备好,请耐心等待其他人准备")
			return false
		end
		if self:CheckGameOver() and self:IsAllRobot() == false then
			userinfo:SendFailToMe("本局已结束,不能再次准备")
			userinfo:Error("本局已结束,不能再次准备")
			if self:IsLearnRooom() then
				userinfo:SendCmdToMe("Cmd.LeaveMahjongCmd_Brd", {uid=userinfo.id,})
			end
			return false
		end

		if self:CheckMyDiamond(userinfo) == false then 		-- 广东梅州红中王 匹配场赌钻检测钻石是否足够
			return false
		end

		userinfo.state.seat.bReady = true
		userinfo:Info("准备就绪")
		userinfo:SendCmdToMe("Cmd.ReadyStartMahjongCmd_S",{}) --{resultCode=0,}
		local brd = {
			uid = userinfo.id,
			readyUserSet = {},
		}
		for k,v in ipairs(self.state.seats) do
			if v.playerInfo and v.playerInfo.state.seat.bReady == true  then
				table.insert(brd.readyUserSet,v.playerInfo.id)
			end
		end
		self:Broadcast("Cmd.ReadyStartMahjongCmd_Brd",brd)
		if userinfo.state.hostType ~= 0 and not userinfo:IsRobot() then --如果不是机器人,取消托管
			--self:DoHostMahjong(userinfo,{data={hostType=0,},})
		end
		--userinfo:SendCmdToMe("Cmd.ReadyStartMahjongCmd_S",{})
		self:CheckStart()
	elseif readyType == 0 then
		if userinfo.state.seat.bReady == nil or userinfo.state.seat.bReady == false then
			return false
		end
		userinfo.state.seat.bReady = false
		userinfo:Info("取消准备")
		local brd = {
			uid = userinfo.id,
		}
		self:Broadcast("Cmd.CancelReadyMahjongCmd_Brd",brd)
	end
	return true
end
function RoomClass:CheckMyDiamond(userinfo)
	return true
end

--已被捉鸡重写,如果重写的需要返回true
function RoomClass:DoMyWinCard(userinfo)
	return false
end
function RoomClass:CheckNewGetCardType()
	return true
end
function RoomClass:DoWinCard(userinfo)
	if self:CheckReadyForOperate() == false then
		userinfo:Error("系统操作时间,个人不能操作")
		return false
	end
	if self:CheckCanWinCard(userinfo) == false then
		return false
	end
	if self.state.last_WinRetMahjongCmd_Brd or self.state.round.last_WinRetMahjongCmd_Brd then --这里防止 --为了兼容有点冗余
		userinfo:Error("胡牌按钮点多了")
		return false
	end
	if self.state.readyForOperate == false then
		if userinfo.state.hostType == 0 then
			userinfo:SendFailToMe("本局已结束")
			userinfo:Error("本局已结束")
		end
		return false
		--self:DoCancelOperate(userinfo)
	end
	if self.state.curgamenbrWin >= self.data.curgamenbr then
		if userinfo.state.hostType == 0 then
			userinfo:SendFailToMe("本局已结算")
			userinfo:Error("本局已结算,又要请求结算,外挂?")
		end
		return false
	end
	if self:CheckNewGetCardType() then
		if self.state.operateSeat.playerInfo == userinfo and self.state.round.newGetCardType > 2 and unilight.getdebuglevel() == 0 then --如果是吃碰后模拟摸得牌,不能被外挂搞成自摸胡
			if userinfo.state.hostType == 0 then
				--userinfo:SendFailToMe("模拟抓的牌不能自摸胡")
				userinfo:Error("模拟抓的牌不能自摸胡,外挂?")
			end
			return false
		end
	end
	--[[local card = self.state.round.newOutCard
	if card == nil then
		if self.state.round.newOutCard ==nil then
			userinfo:SendFailToMe("当前不能胡牌")
			userinfo:Error("要胡的牌已经被别人抢走了")
			self:DoCancelOperate(userinfo)
			return false
		end
	end]]
	if self:DoMyWinCard(userinfo) == false then
		local brd ,isWin = GetRoundResult(self.state.round,userinfo)
		for i, v in ipairs(brd.rewardSet) do
			if v.totalReward ~= 0 then
				if isWin == nil then
					isWin = true
				end
			end
		end
		self:DoDiamondBalance(brd.rewardSet)
		if isWin == nil then
			isWin = false --暂时判断是否胡牌,靠是否有人有分数
		end
		if isWin then
			self.state.curgamenbrWin = self.data.curgamenbr
			self:Broadcast("Cmd.WinRetMahjongCmd_Brd", brd)
			self.state.last_WinRetMahjongCmd_Brd = table.clone(brd)
			self:ResetReady()
		else
			if userinfo.state.hostType == 0 then
				--userinfo:SendFailToMe("没有胡牌就想请求胡牌,外挂?")
				self:Error("没有胡牌就想结算,外挂风险:".. userinfo.id)
			end
			return 
		end
		if self:CheckGameOver() then
			self:Info("牌局全部结束")
			if self:IsLearnRooom() or self:GetRobotNum() + 1 == self.data.usernbr then
				self:Info("销毁练习场")
				self:Broadcast("Cmd.FinalScoreMahjongCmd_Brd", self:GetFinalScore(2))
				self:Destroy()
			elseif self.data.curgamenbr > 1 then
				self:Broadcast("Cmd.FinalScoreMahjongCmd_Brd", self:GetFinalScore(2))
				self:Destroy()
			end
		end
	end
	--userinfo:Info("胡牌结束:"..card:GetId()..":"..card:GetName())
end

function RoomClass:DoDiamondBalance(rewardSet)
	for i, v in ipairs(rewardSet) do
		if v.totalReward and self.data.winDiamond then --机器人如果输赢钻石, 单局结算
			local change = v.totalReward * self.data.winDiamond
			local tempUserInfo = UserInfo.GetUserInfoById(v.uid)
			if tempUserInfo == nil then
				tempUserInfo = RobotInfo.GetRobotInfoById(v.uid)
			end
			if change < 0 and math.abs(change) > tempUserInfo.data.mahjong.diamond then
				change = -tempUserInfo.data.mahjong.diamond
			end
			v.diamond = tempUserInfo.data.mahjong.diamond + change
			ChessToLobbyMgr.SendCmdToLobby("Cmd.UserDiamondWinLobbyCmd_CS",{uid=tempUserInfo.id,typ=4,change=change,needSend=1,})
			if change > 0 then
				tempUserInfo:SendFailToMe("获得钻石:"..change)
			else
				tempUserInfo:SendFailToMe("扣除钻石:"..-change)
			end
			tempUserInfo:Info("输赢钻石:"..change..":"..v.totalReward..":"..tempUserInfo.data.mahjong.diamond .. ":" .. self.data.winDiamond)
			local old = tempUserInfo.data.mahjong.diamond --暂时山寨下
			tempUserInfo.data.mahjong.diamond = tempUserInfo.data.mahjong.diamond + change
			self:BroardBaseInfoToUser(tempUserInfo)--这里冗余山寨下更新钻石
			tempUserInfo.data.mahjong.diamond = old
		end
	end
end

-- 牌局正常结束条件(各分支条件不同可重写)
function RoomClass:CheckGameOver()
	if self.state.bundle then
		for k,v in pairs(self.state.seats) do
			if v.playerInfo and v.point <= 0 then
				if self.data.curgamenbr == 1 then
					self.data.curgamenbr = 2
				end
				return true
			end
		end
	else
		if self.data.curgamenbr >= self.data.gamenbr then
			return true
		end
	end
	return false
end

function RoomClass:DoEatCard(userinfo,one, two)
	if self:CheckReadyForOperate() == false then
		userinfo:Error("系统操作时间,个人不能操作")
		return false
	end
	if self:CheckCanEatCard() == false then
		userinfo:SendFailToMe("不房间不支持吃牌玩法")
		--self:DoCancelOperate(userinfo)
		return false
	end
	local card = self.state.round.newOutCard
	if card == nil then
		if self.state.round.newOutCard ==nil then
			if userinfo.state.hostType == 0 then
				userinfo:SendFailToMe("要吃的牌已经被别人抢走了")
				userinfo:Error("要吃的牌已经被别人抢走了:"..one .."," .. two)
			end
			--self:DoCancelOperate(userinfo)
			return false
		end
	end
	if self.state.round.waitOpSet[userinfo.state.seat] ~= nil then
		userinfo:SendFailToMe("已经操作过,请不要频繁操作")
		userinfo:Error("已经操作过,请不要频繁操作")
		return false
	end
	if not self.state.round:CheckCanOp(userinfo.state.seat,7) then
		userinfo:SendFailToMe("当前没有吃操作")
		userinfo:Error("当前没有吃操作")
		return false
	end
	local firstSeat = self.state.round:GetOperatePrioritySeat(userinfo.state.seat,7)
	if firstSeat ~= userinfo.state.seat then
		--userinfo:SendFailToMe("吃操作优先级不够,请等待")
		if firstSeat then
			userinfo:Error("吃操作优先级不够:" .. card.id .. ",请等待:" .. firstSeat.playerInfo.id .. "先操作")
		else
			userinfo:Error("吃操作优先级不够:" .. card.id .. ",请等待:" .. self.state.operateSeat.playerInfo.id)
		end
		self.state.round.waitOpSet[userinfo.state.seat]= {opType=7,eat={one=one,two=two,},}
		userinfo:SendCmdToMe("Cmd.CancelOpMahjongCmd_S", "{}")
		return false
	end

	--TODO 这里要做优先级检查
	
	local brd = {
		obj = {},
	}
	brd.obj = userinfo.state.seat:EatCard(card,one,two,self.state.operateSeat.playerInfo.id)
	if brd.obj == nil then
		userinfo:SendFailToMe("吃牌失败")
		userinfo:Error("吃牌失败,未知原因")
		return false
	end
	self.state.operateSeat:RemoveOutCard(card) -- 这里有冗余,如果是杠自己的牌,已经在BarCard里清除了
	self:Broadcast("Cmd.EatCardMahjongCmd_Brd", brd)
	self:DoMyOperateCard(userinfo)
	self:ResetOperator(userinfo.state.seat) --重置操作者为杠牌者
	local card = userinfo.state.seat:GetCardMaxThisid()
	userinfo:Info("吃牌成功:"..card.id .. ":" ..self.state.round.newOutCard.id .. ":" .. json.encode(brd.obj))
	userinfo.state.seat.handCard[card.id] = nil --模拟发牌
	self.state.opEvent = nil
	self:EventDealOneCard(self,card,10)
	return true
end

function RoomClass:SendCmdToUser(doinfo, data,uid)
	for k,v in ipairs(self.state.seats) do
		if v.playerInfo and v.playerInfo.id == uid  then
			v.playerInfo:SendCmdToMe(doinfo, data)
			return true
		end
	end
	return false
end
function RoomClass:BroadcastSys(data,pos)
	for k,v in ipairs(self.state.seats) do
		if v.playerInfo then
			v.playerInfo:SendFailToMe(data,pos)
			return true
		end
	end
	return false
end
function RoomClass:Broadcast(doinfo, data,ignore_record)
	local send = {}
	send["do"] = doinfo
	send["data"] = data
	if unilight.mahjong_new() == 1 then
		if self.state.bankerSeat and self.state.bankerSeat.playerInfo and self.state.bankerSeat.playerInfo.state and self.state.bankerSeat.playerInfo.state.jsonCompress then
			send = self.state.bankerSeat.playerInfo.state.jsonCompress:Compress(send)
		end
	end
	local s = json.encode(send)
	self.state.broadcastRoom.BroadcastString(s)
	if not ignore_record then
		self:AddRecordMsg(0,s)
	end
	self:Debug("Broadcast:" .. s)
	return true
end
function RoomClass:AddRecordMsg(uid,s)
	if go.version and not self:IsLearnRooom() then
		if type(s) == "table" then
			s =  json.encode(s)
		end
		self.state.broadcastRoom.AddRecordMsg(uid,s)
	end
end

function RoomClass:BroadcastExceptOne(doinfo, data,uid,ignore_record)
	local send = {}
	send["do"] = doinfo
	send["data"] = data
	--if self.state.jsonCompress then
	--	send = self.state.jsonCompress:Compress(send)
	--end
	local s = json.encode(send)
	for k,v in ipairs(self.state.seats) do
		if v.playerInfo and v.playerInfo.id ~= uid then
			v.playerInfo:SendStringToMe(s,ignore_record)
		end
	end
	self:Debug("BroadcastExceptOne:" .. uid .. ":" .. s)
	return true
end
function RoomClass:GetPlayInfoById(uid)
	for k,v in ipairs(self.state.seats) do
		if v.playerInfo and v.playerInfo.id == uid then
			return v.playerInfo
		end
	end
end

-- 大厅主动通知游戏服销毁房间 lbx
function LobbyActiveRemove(roomId)
	local room = GetRoomInfoById(roomId)
	if room == nil then
		unilight.error("大厅通知游戏服解散房间 当前游戏缓存不存在该房间:" .. roomId)
		return
	end
	if room:CheckSendFinalScore() then
		room:Broadcast("Cmd.FinalScoreMahjongCmd_Brd", room:GetFinalScore(1),true)
	else
		local data = {}
		data.bOk = true
		data.agreeUsers = {}
		for k,v in pairs(room.state.seats) do
			if v.playerInfo then
				table.insert(data.agreeUsers, v.playerInfo.name)
			end
		end
		room:Broadcast("Cmd.SuccessDissolveRoom_Brd", data,true)
	end
	-- 由大厅主动通知解散的房间 不需要再次通知大厅
	room:Destroy(true)
end
