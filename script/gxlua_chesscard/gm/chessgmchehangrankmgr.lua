module("ChessGmCheHangRankMgr", package.seeall)

---------------------------------排行榜控制-------------------------------------

-- 初始化车行排行榜控制相关数据
function InitRankCtr()
	local rankCtr = {
		_id 			= 1,
		starttime		= nil, -- 活动开始时间
		endtime 		= nil, -- 活动结束时间
		nextstarttime 	= nil, -- 下期开始时间
		nextendtime 	= nil, -- 下期结束时间
	}
	-- 存档
	SaveRankCtr(rankCtr)
	return rankCtr
end

-- 存档车行控制数据
function SaveRankCtr(rankCtr)
	unilight.savedata("chehangrankctr", rankCtr)
end

-- 获取车行排行榜开启时间
function GetRankOpenTime()
	local rankCtr = unilight.getdata("chehangrankctr", 1)
	if rankCtr == nil then
		rankCtr = InitRankCtr()
	end

	if rankCtr.starttime == nil and rankCtr.nextstarttime == nil then
		return false
	else
		return true, rankCtr.starttime, rankCtr.endtime, rankCtr.nextstarttime, rankCtr.nextendtime, rankCtr
	end
end

-- 通过gm控制排行榜开启
function GmCtrRankOpenTime(startTime, endTime)
	-- 检测时间的合法性
	local curTime = os.time()
	if startTime >= endTime or startTime < curTime then
		return 2, "传入时间不合法"
	end 

	local rankCtr = unilight.getdata("chehangrankctr", 1)
	if rankCtr == nil then
		rankCtr = InitRankCtr()
	end

	if rankCtr.endtime ~= nil and startTime < rankCtr.endtime then
		local desc = "前后两期排行榜时间有冲突 下期排行榜开始时间不能小于上期排行榜结束时间"
		unilight.info(desc)
		return 3, desc
	end

	rankCtr.nextstarttime 	= startTime
	rankCtr.nextendtime 	= endTime

	-- 存档
	SaveRankCtr(rankCtr)

	return 0, "设置下期车行排行榜成功"
end
