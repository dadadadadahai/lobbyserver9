module('BankerRoomMgr', package.seeall)

BANKER_TYPE_CLS = 1 -- 集体坐庄
Banker_TYPE_SGL = 2 -- 单个坐庄


-- 玩家申请上庄
-- 二八杠全部是单个玩家上庄
function Init()
	BankerSingleQueue.Init()
end

-- 组装庄家信息 用于回复给 前端
function ConsructBankerInfo(uid, bankerNbr, index, userInfo)
	local bRobot = RobotMgr.IsRobot(uid)
	if bRobot then
		-- 机器人（暂时 没有机器人）
		if uid ~= 0 then
			local userInfo = RobotMgr.GetRobotInfo(uid)
			local bankerInfo = {
				uid = uid,
				nickName = userInfo.nickname,
				bankerChips = userInfo.bankerchips,
				remainder = userInfo.chips,
				index = index,
				bankerNbr = bankerNbr,
				headUrl = userInfo.headurl,
			}
			return bankerInfo
		else
			return {
				uid = uid,
				nickName = "系统",
				bankerChips = 0,
				remainder = 0,
				index = index,
				bankerNbr = bankerNbr,
				headUrl = chessuserinfodb.RandomIcon(),
			}
		end
	end

	local userInfo = chessuserinfodb.RUserInfoGet(uid)

	-- 获取庄家的赌本 如果在上庄列表时 则庄家筹码暂时还为0 
	local bankerchips = userInfo.property.bankerchips
	if bankerchips == 0 then
		bankerchips = RoomMgr.TempBankChips[uid] or 0
	end

	local bankerInfo = { 
		uid         = uid, 								-- 玩家id
		nickName    = userInfo.base.nickname, 			-- 庄家的名字
		bankerChips = bankerchips, 						-- 庄家的赌本  
		remainder   = userInfo.property.chips, 			-- 玩家可下注的库存
		headUrl     = userInfo.base.headurl, 			-- 图像
		index       = index,
		bankerNbr  = bankerNbr,
	}   
	return bankerInfo
end 

-- 玩家申请上庄
-- 二八杠全部是单个玩家上庄
function UserApply(roomId, uid)
	return 	BankerSingleQueue.UserApply(roomId, uid)
end

-- 玩家申请下庄
function UserLeave(roomId, uid)
	return BankerSingleQueue.UserCancelBanker(roomId, uid)
end

-- 本次上庄玩家获取
function GetBankerUser(roomId)
	return BankerSingleQueue.GetCurrentBanker(roomId) 
end

-- 上庄列表获取
function GetBankerList(roomId)
	return BankerSingleQueue.GetBankerList(roomId)
end

-- 获取该玩家在上庄申请列表中的位置
function GetUserApplyIndex(roomId, uid)
	return BankerSingleQueue.GetUserApplyIndex(roomId, uid)
end

-- 玩家优先上庄
function UserMoveToFirst(uid, roomId)
	return BankerSingleQueue.UserMoveToFirst(uid, roomId)
end