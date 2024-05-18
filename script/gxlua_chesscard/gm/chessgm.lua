module('chessgm', package.seeall) 

MapSysGmBroad = {}
DefaultBroad  = nil

SysGmBroadAdd = function(task)
	if task.endtime < os.time() then
		unilight.info("task id " .. task.taskid .. "   endtime " .. task.endtime .. "  过期")
		return false, "结束时间小于当前时间"
	end

	local taskInfo = {
		id = task.taskid,
		countryId = task.countryid,
		sceneId = task.sceneid,
		startTime = task.starttime,
		endTime = task.endtime,
		intervalTime = task.intervaltime,
		content = task.content,
	}
    racelamp.AddSysLamp(task.taskid, task.content, task.endtime)
	return true, "添加成功"
end

SysGmBroadDelete = function(taskId)
    racelamp.DelSysLamp(taskId)
	return true
end

-- 加多个type 如果type为5表示为弹幕
SysGmBroadTimer = function(taskId, type, timer)
	local taskInfo = MapSysGmBroad[taskId]	
	if taskInfo == nil then
		unilight.info("taskid is null " .. taskId .. " stop the system barod")
		timer.Stop()
		return 
	end

	local currentTime = os.time()	
	-- 到end时间了
	if taskInfo.endTime < currentTime then
		unilight.info("公告过期了 " .. taskInfo.id .. " currentTime ".. currentTime .. " endtime:" .. taskInfo.endTime)	
		MapSysGmBroad[taskId] = nil		
		timer.Stop()
		return 
	end

	-- 广播还没有开始
	if taskInfo.startTime > currentTime  and taskInfo.startTime ~= 0 then 
		unilight.info("公告还没有开始 " .. taskInfo.id)	
		return 
	end
	-- 广播了
	local uid = 0  
	local nickName = "系统公告"
	local bMan = true
	local chatType = chesscommonchat.ENUM_CHAT_TYPE.LOBBY
	local chatPos = chesscommonchat.ENUM_CHAT_POS.GM
	local brdInfo = taskInfo.content

	-- 弹幕特殊处理一下
	if type == 5 then
		nickName = TableRobotUserInfo[math.random(1, 1000)].nickname
		chatPos = chesscommonchat.ENUM_CHAT_POS.NORMAL
		unilight.info("弹幕发送 nickname:" .. nickName .. " content:" .. brdInfo)
	end

	chesscommonchat.CommonChat(uid, nickName, bMan, chatPos, chatType, brdInfo)
end

GmCommandInit = function()
	GmList = GmList or {}
	AddGmCommand("RequestRoomStockGmCmd_C", "")
	AddGmCommand("RequestEditRoomStockGmCmd_C", "roomId=101 roomStock=900000")
end

AddGmCommand = function(name, para)
	local gmItem = {
		name = name,
		para = para,
	}
	table.insert(GmList, gmItem)
end
