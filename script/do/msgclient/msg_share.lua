-- 请求信息
Net.CmdGetShareInfoShareCmd_C= function(cmd, laccount)
	local uid = laccount.Id
	DayShare.GetShareInfo(uid)
end

-- 获得分享奖励
Net.CmdGetShareRewardShareCmd_C= function(cmd, laccount)
	local uid = laccount.Id
    DayShare.GetShareReward(uid, cmd.data.shareType)
end
