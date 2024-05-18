-- 活动类型
ACTIVITY_TYPE = {
	CHEHANG_RANK	= 1, 		-- 车行排行榜活动
	SHARE 			=11,  		-- 麻将分享活动控制
	POINT_RANK 		=12,  		-- 麻将积分排行榜活动控制
	FREE_GAME 		=13,  		-- 麻将免费游戏
	OPEN_PRAC 		=14,  		-- 麻将练习场定时开放
	COST_RANK 		=15,  		-- 麻将房费消耗排行榜活动控制
	OPEN_REDPACK    =16,  		-- 开房红包奖励
}


-- 活动控制
GmSvr.PmdActivitySwitchGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	res["do"] = "ActivitySwitchGmUserPmd_CS" 
	

	local data 		= cmd.data
	local startTime = data.starttime
	local endTime 	= data.endtime
	local actId 	= data.actid
	local actName 	= data.actname -- 活动名称（第一次使用 利用该字段区分 对应麻将大厅）

	if data == nil or startTime == nil or endTime == nil or actId == nil then
		res.data.retcode = 1 
		res.data.retdesc = "参数有误"
		return res
	end

	local startDate = chessutil.FormatDateGet(startTime)
	local endDate 	= chessutil.FormatDateGet(endTime)

	-- 先根据区服类型区分(暂时只有这两个有需要)
	local zoneType = go.getconfigint("zone_type") 

	local ret,desc = 2, "控制类型不正确 zoneType:" .. zoneType .. "	actId:" .. actId 

	if zoneType == 5 then
		-- 风驰大厅
		if actId == ACTIVITY_TYPE.CHEHANG_RANK then
			unilight.info("收到gm指定车行时间控制" .. startDate .. "至" .. endDate)
			ret, desc = ChessGmCheHangRankMgr.GmCtrRankOpenTime(startTime, endTime)
			if ret == 0 then
				unilight.info("成功控制")
			end
		end
	elseif zoneType == 4 then
		-- 麻将大厅
		if actId == ACTIVITY_TYPE.SHARE then
			unilight.info("收到gm指定麻将分享时间控制" .. startDate .. "至" .. endDate)
			ret, desc = ShareMgr.GmSetShareCtrInfo(startTime, endTime)
			if ret == 0 then
				unilight.info("成功控制")
			end
		elseif actId == ACTIVITY_TYPE.POINT_RANK then
			-- 积分排行榜
			unilight.info("收到gm指定积分排行榜时间控制" .. startDate .. "至" .. endDate)
			ret, desc = RankMgr.GmSetRankInfo(startTime, endTime, RankMgr.ENUM_RANK_TYPE.POINT)
			if ret == 0 then
				unilight.info("成功控制")
			end
		elseif actId == ACTIVITY_TYPE.FREE_GAME then
			-- 控制免费游戏时间
			unilight.info("收到gm指定麻将免费游戏时间控制 lobby:" .. actName .. " " .. startDate .. "至" .. endDate)
			ret, desc = FreeGame.GmSetFreeGame(actName, startTime, endTime)
			if ret == 0 then
				unilight.info("成功控制")
			end
		elseif actId == ACTIVITY_TYPE.OPEN_PRAC then
			-- 练习场定时开放逻辑
			ret, desc = OpenPrac.GmSetOpenPrac(startTime, endTime)
			if ret == 0 then
				unilight.info("成功控制")
			end
		elseif actId == ACTIVITY_TYPE.COST_RANK then
			-- 老司机
			unilight.info("收到gm指定房费排行榜时间控制" .. startDate .. "至" .. endDate)
			ret, desc = RankMgr.GmSetRankInfo(startTime, endTime, RankMgr.ENUM_RANK_TYPE.COST)
			if ret == 0 then
				unilight.info("成功控制")
			end
		elseif actId == ACTIVITY_TYPE.OPEN_REDPACK then
			-- 开房红包
			unilight.info("收到gm指定开房红包时间控制" .. startDate .. "至" .. endDate)
			ret, desc = OpenRedPack.GmSetOpenRedPackData(startTime, endTime)
			if ret == 0 then
				unilight.info("成功控制")
			end
		end
	end

	res.data.retcode = ret 
	res.data.retdesc = desc
	return res
end

