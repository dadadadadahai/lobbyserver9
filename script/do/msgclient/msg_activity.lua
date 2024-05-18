-- 玩家领取奖励
Net.CmdInviteRewardRequestActivityCmd_C= function(cmd, laccount)
	ActivityInvite.GetInviteReward(laccount.Id, cmd.data.inviteNum)	
end

-- 请求获取邀请好友列表
Net.CmdInviteUserListRequestActivityCmd_C = function(cmd, laccount)
	ActivityInvite.CmdInviteUserListGetByUid(laccount.Id)	
end

