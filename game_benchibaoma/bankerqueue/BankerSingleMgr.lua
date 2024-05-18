module('BankerSingleQueue', package.seeall)
-- 用来处理坐庄信息：
-- （1）玩家申请上庄后，排队上庄；
-- （2）当没有人申请上庄时，默认系统作为庄家；
-- （3）申请一次庄家最多可以玩10把，之后重新排队申请上庄
-- （4）在排队或者上庄中，可随时申请取消上庄
function Init()
	local romCfg = chessroominfodb.GetRoomAllInfo(go.gamezone.Gameid)
	Room = {}
	for i, v in ipairs(romCfg) do
		Room[v.roomId] = {
			userList = {}, -- 保存每个申请者链表
			maxNbr = 10, -- 每次申请可玩局数
		}
	end
end

-- 玩家申请上庄
function UserApply(roomId, uid)
	local room = Room[roomId]
	if room == nil then
		unilight.error("玩家申请的上庄roomId不存在" .. uid .. "    "  .. roomId)
		return false, 0
	end	
	-- 判断是否已申请上庄
	local bApply = UserHasApply(roomId, uid)
	if bApply == true then
		unilight.info("玩家已经申请了上庄" .. uid .. "    "  .. roomId)
		return false, 0
	end	
	AddUser(uid, roomId)
	local index = GetUserApplyIndex(roomId, uid)

	return true, index
end	

-- 玩家申请下庄
function UserCancelBanker(roomId, uid)
	local room = Room[roomId]
	if room == nil then
		unilight.error("申请下庄，但是房间不存在" .. roomId)
		return false
	end	
	local bOk = RemoveUser(uid, roomId)
	-- if bOk == true then
	-- 	unilight.info("申请下庄，" .. uid)
	-- end
	return bOk
end	

-- 每局庄家信息获取
function GetCurrentBanker(roomId)
	local room = Room[roomId]
	if room == nil then
		return nil
	end	
	local uid = 0
	local bankerNbr = 0
	local userList = Room[roomId].userList
	local c = userList.next
	if c ~= nil then
		uid = c.uid
		bankerNbr = c.currentIdx
		c.currentIdx  = c.currentIdx + 1
		if c.currentIdx > room.maxNbr then
			RemoveUser(uid, roomId)
		end	
	end	
	return uid, bankerNbr
end

-- 每局庄家信息列表获取(不包括当前庄家)
function GetBankerList(roomId)
	local room = Room[roomId]
	if room == nil then
		return false 
	end	

	local roomInfo = RoomMgr.MapRoom[roomId]
	local bankerUid = roomInfo.betInfo.bankerInfo.uid

	local bankerList = {} 
	local userList = Room[roomId].userList
	local c = userList.next
	local index = 1
	while c do
		-- 申请列表中 过滤掉当前的庄家。 但是玩家为庄家 申请了下庄 再次申请上庄 并优先到第一位的时候 这时的申请列表还得有他
		if c.currentIdx == 1 then 
			local banker = {
				uid = c.uid,
				bankerNbr = c.currentIdx,
				index = index,
			}
			table.insert(bankerList, banker)
			index = index + 1
		end
		c = c.next
	end
	return true, bankerList
end

------------------------------------------------------
-- 上庄申请列表添加玩家
function AddUser(uid, roomId)
	-- body
	local index = 1 
	local userList = Room[roomId].userList
	local t = userList
	while t.next do
		index = index + 1
		t = t.next
	end

	local newApply = {
		currentIdx = 1,
		uid        = uid,
	}

	t.next = newApply
	-- unilight.info("uid:" .. uid .. "   申请了上庄")
	return index
end

-- 上庄申请列表移除玩家
function RemoveUser(uid, roomId)
	local userList = Room[roomId].userList
	local c = userList
	local p = c
	while c do
		if c.uid == uid then
			-- unilight.info("玩家uid:" .. uid .. "下庄成功")
			p.next = c.next
			return true 
		end	
		p = c
		c = c.next
	end

	return false
end

-- 玩家优先上庄
-- 如果当前列表的第一个是庄家 则优先到第二位 否则到 第一位
function UserMoveToFirst(uid, roomId)
	local roomInfo = RoomMgr.MapRoom[roomId]
	local bankerUid = roomInfo.betInfo.bankerInfo.uid

	local userList = Room[roomId].userList

	local applyUser = nil

	-- 先从列表中 移除他 
	local c = userList
	local p = c
	while c do
		if c.uid == uid then
			applyUser = c
			p.next = c.next
			break
		end	
		p = c
		c = c.next
	end

	-- 然后再插进去
	local curUserList = Room[roomId].userList
	local first = curUserList.next
	-- 如果第一位 是庄家 则插到第二位中
	if first ~= nil and first.uid == bankerUid then 
		local temp = first.next
		applyUser.next = temp
		first.next = applyUser
		curUserList.next = first
	else
		curUserList.next = applyUser
		applyUser.next = first
	end
	Room[roomId].userList = curUserList

	unilight.info("uid:" .. uid .. "   申请了优先上庄")	
end

-- 上庄申请列表是否有该玩家
function UserHasApply(roomId, uid)
	local userList = Room[roomId].userList
	local t = userList
	while t do
		if t.uid == uid then
			return true
		end	
		t = t.next
	end

	return false
end

-- 获取该玩家在上庄申请列表中的位置
function GetUserApplyIndex(roomId, uid)
	local roomInfo = RoomMgr.MapRoom[roomId]
	local bankerUid = roomInfo.betInfo.bankerInfo.uid

	local index = 0
	local tempIndex = 0
	local userList = Room[roomId].userList

	local t = userList.next
	while t do
		-- 如果第一个为庄家 则 不计入内
		if tempIndex ~= 0 or t.uid ~= bankerUid then 
			tempIndex = tempIndex + 1
		end

		if t.uid == uid then
			index = tempIndex
			break
		end	
		t = t.next
	end
	return index 
end



