GmSvr.PmdBroadcastNewGmUserPmd_C = function(cmd, laccount)
	res = {}
	res["do"] = "ReturnBroadcastNewGmUserPmd_S" 
	res["data"] = {}
	if cmd.data == nil or cmd.data.data == nil or cmd.data.data.taskid == nil or cmd.data.data.intervaltime == nil or cmd.data.data.content == nil  then
		res.data.retcode = 1 
		res.data.retdesc = "参数没有带入"
		return res
	end
	unilight.info("debug " .. table.tostring(cmd.data.data))
	local task = cmd.data.data
	local bOk, desc = chessgm.SysGmBroadAdd(task)
	if bOk ~= true then
		res.data.retcode = 2
		res.data.retdesc = desc 
		return res
	end
	res.data.retcode = 0
    res.data.retdesc = "成功"
	unilight.info("add gm broadcast ok" .. cmd.data.data.content .. "taskid   " .. task.taskid)
	return res
end

-- 当gmserver连上来时，去主动请求是否有gm相关公告等数据
GmSvr.GmClientInitOk = function(cmd, laccount)
	unilight.info("RequestBroadcastListGmUserPmd_C")
	laccount.RequestBroadcastListGmUserPmd_C()
end

-- 删除公告任务
GmSvr.PmdBroadcastDeleteGmUserPmd_C= function(cmd, laccount)
	res = {}
	res["do"] = "ReturnDeletePunishUserGmUserPmd_S" 
	res["data"] = {}
	local taskId = cmd.data.taskid
	local bOk = chessgm.SysGmBroadDelete(taskId)	
	res.data.taskid = taskid
	res.data.retcode = 0
    res.data.retdesc = "成功"
	unilight.info("delete  gm broadcast ok" .. taskId) 
	return res 
end 

-- 第一次上线，刷新所有的公告回复
GMClientTask = GMClientTask or {}
GMClientTask.ReturnBroadcastListGmUserPmd_S = function(task, cmd) 
	local broadList = cmd.Data
	for i=1, #broadList do
		local broadInfo = broadList[i]
		local broadTask = {
			taskid = broadInfo.Taskid,
			countryid = broadInfo.Countryid,
			sceneid = broadInfo.Sceneid,
			starttime = broadInfo.Starttime,
			endtime = broadInfo.Endtime,
			intervaltime = broadInfo.Intervaltime,
			content = broadInfo.Content,
			btype = broadInfo.Btype
		}
		unilight.info("启动添加公告 btype:" .. broadInfo.Btype .. " content:" .. broadInfo.Content)
		chessgm.SysGmBroadAdd(broadTask)
	end
end
