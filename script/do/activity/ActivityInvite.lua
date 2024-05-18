module('ActivityInvite', package.seeall)  

local shareRewardTable  = import("table/table_invite_share")
local inviteRewardTable = import("table/table_invite_num")
local shareRewardConfig = shareRewardTable[1]


--获得邀请奖励列表
function CmdInviteUserListGetByUid(uid)
	local send = {}
	send["do"] = "Cmd.InviteUserListReturnActivityCmd_S"
    local data = {
        rewardList = {}
    }
    send["data"] = data

	local filter = unilight.eq("base.inviter", uid)	
    local inviteNum = unilight.startChain().Table("userinfo").Filter(filter).Count()        --我的邀请人数
    data.inviteNum = inviteNum


    local userInfo = chessuserinfodb.RUserDataGet(uid)
    local inviteRewardStatus = userInfo.inviteRewardStatus

    local bUpdate = false
    for num, reward in pairs(inviteRewardTable) do
        if inviteRewardStatus[num] == nil then
            inviteRewardStatus[num] = 0
            bUpdate = true
        end
        local isGet =  inviteRewardStatus[num]

        table.insert(data.rewardList, {isGet = isGet, inviteNum = num, rewardList = reward})
    end

    if bUpdate == true then
        unilight.update("userinfo",uid, userInfo)
    end


    unilight.sendcmd(uid, send)
end


--请求获得邀请奖励
function GetInviteReward(uid, inviteNum) 

	local send = {}
	send["do"] = "Cmd.InviteRewardReturnActivityCmd_S"
    local data = {
        errno      = 0,
        desc       = "领取成功",
        rewardList = {}
    }
    send.data = data

    local userInfo = chessuserinfodb.RUserDataGet(uid)
    local inviteRewardStatus = userInfo.inviteRewardStatus
    local isGet = inviteRewardStatus[inviteNum]

    if isGet == nil  or isGet == 1 then
        data.errno  = 1
        data.desc   = "已经领取过了"
        unilight.sendcmd(uid, send)
        return
    end

	local filter = unilight.eq("base.inviter", uid)	
    local count = unilight.startChain().Table("userinfo").Filter(filter).Count()

    if count < inviteNum  then
        data.errno = 2
        data.desc  = "条件未达成"
        unilight.sendcmd(uid, send)
        return
    end

    inviteRewardStatus[inviteNum] = 1
    unilight.savefield("userinfo",uid, "inviteRewardStatus", inviteRewardStatus)
    local rewardList = inviteRewardTable[inviteNum].reward
    local summary = {}
    for _, goodInfo in pairs(rewardList) do
        summary = BackpackMgr.GetRewardGood(uid, goodInfo.goodId, goodInfo.goodNum, Const.GOODS_SOURCE_TYPE.SHARE, summary)
    end

    local rewardList = {}
    for k, v in pairs(summary) do
        table.insert(rewardList, {goodId=k, goodNum=v})
    end

    data.rewardList = rewardList
    unilight.sendcmd(uid, send)

    --刷新下列表
    CmdInviteUserListGetByUid(uid)
end


function UserInvitedDetailGetByUid(uid, inviteUserNum, oneUserPlayNum)
	local filter = unilight.eq("base.inviter", uid)	
    local count = unilight.startChain().Table("userinfo").Filter(filter).Count()
	local inviteUserArray = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter).Pluck("uid", "base.nickname", "base.headurl"))
	local inviterArray = {}
	local hasInviterdNum = 0
	for i, v in ipairs(inviteUserArray) do 
		local inviterUid = v.uid
		local completeNum = chessprofitbet.CmdAllGamePlayNmuberGetByUid(inviterUid)

		local inviter = {
			uid = uid,
			nickName = v.base.nickname,
			headUrl = v.base.headurl,
			needAllNum = oneUserPlayNum,
			completeNum = completeNum,
		}	
		table.insert(inviterArray, inviter)
		hasInviterdNum = hasInviterdNum + 1
	end
	local sortFun = function(a, b)
		return a.completeNum< b.completeNum
	end
	if hasInviterdNum > 1 then
		table.sort(inviterArray, sortFun)
	end
	local resInviter = {}	
	for i=1, 5, 1 do
		if inviterArray[i] ~= nil then
			table.insert(resInviter, inviterArray[i])
		end
	end
	return resInviter
end

