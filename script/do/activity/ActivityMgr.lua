module('ActivityMgr', package.seeall)  

TABLE_NAME = "useractivityinfo" 

ACTIVITY_STATUS_UNSTART  = 0
ACTIVITY_STATUS_PROGRESS = 1
ACTIVITY_STATUS_COMPLETE = 2 
ACTIVITY_STATUS_RECEIVED = 3 

function UserActivityStatusGet(uid)
	local activityInfo = unilight.getdata(TABLE_NAME, uid)
	local bUpdate = false
	if table.empty(activityInfo) then
		bUpdate = true
		activityInfo = {
			_id = uid,
			uid = uid,
		}
	end
	if bUpdate == true then 
		unilight.savedata(TABLE_NAME, activityInfo)
	end
	
	activityInfo, bUpdate = AddActivity(activityInfo)
	if bUpdate == true then 
		unilight.savedata(TABLE_NAME, activityInfo)
	end
	return activityInfo 
end

function AddActivity(activityInfo)
	local bUpdate = false
	for id, activity in ipairs(TableActivityConfig) do
		if activity[id] == nil then
			activityInfo[id] = {
				actvityid = activity.id,
				activitystatus = ACTIVITY_STATUS_PROGRESS,
				breceived = false,
				activitylog = {}
			}
			bUpdate = true
		end
	end
	return activityInfo, bUpdate
end

function CmdUpdateActivityInfo(uid, activityInfo)
	if activityInfo.uid ~= uid or activityInfo._id ~= uid then
		unilight.error("activityinfo save error uid  " .. id) return 
	end
	for id, activity in ipairs(TableActivityConfig) do
		if activityInfo[id] == nil then
			unilight.error("activityinfo save error " .. id)
			return 
		end
	end

	unilight.savedata(TABLE_NAME, activityInfo)
end

function CmdUserActivityRewardReceive(uid, activityId)
	local actvityInfo = UserActivityStatusGet(uid)	
	if actvityInfo[actvityid] == nil then
		return false, "当前不存在该活动 领取活动奖励失败"
	end
	local subActivityInfo = activityInfo[actvityid]
	if subActivityInfo.activitystatus == ACTIVITY_STATUS_COMPLETE and subActivityInfo.breceived == false then
		local rewardCfg = TableActivityConfig[activityId].reward
		local rewardGoods = {}
		for i, rewardInfo in ipairs(rewardCfg) do
			local goodId = rewardInfo.goodId
			local goodNum = rewardInfo.goodNum
			local rewardItem = {
				goodId = goodId,
				goodNum = goodNum,
			}

			-- 物品获取调用统一接口
			BackpackMgr.GetRewardGood(uid, goodId, goodNum, Const.GOODS_SOURCE_TYPE.ACTIVITY)

			table.insert(rewardGoods, rewardItem)
		end

		local remainder = chessuserinfodb.RUserChipsGet(uid) 

		return true, "领取活动奖励成功", remainder, rewardGoods 
	else
		return false, "该活动未完成 或 奖励已领取 "
	end
end
