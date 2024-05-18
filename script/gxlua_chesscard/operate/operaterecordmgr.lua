module("OprateRecordMgr", package.seeall)
-- 用于统一管理 运营活动 获奖记录

-- 保存获奖记录
function SaveRecords(uid, operateType, awardName, goodId, goodNum, goodType)
	local userInfo = chessuserinfodb.RUserInfoGet(uid)

	local record = {
		uid 		= uid,											-- 获奖玩家id
		nickName 	= userInfo.base.nickname,						-- 获奖玩家昵称
		operateType = operateType, 									-- 运营活动类型  
		awardName	= awardName, 									-- 奖励名称
		goodId   	= goodId, 										-- 道具表格中的id
		goodNum  	= goodNum,										-- 个数
		goodType 	= goodType, 									-- 类型为5时 为实物
		timeStamp 	= os.time(),									-- 奖励获取时间戳
		time 		= chessutil.FormatDateGet(), 					-- 格式化时间
	}

	unilight.savedata("operaterecord", record)
end

-- 获取指定类型运营活动 获奖记录
function GetRecords(uid, operateType)
	-- 获取转盘
	local info = unilight.getByFilter("operaterecord", unilight.a(unilight.eq("uid", uid), unilight.eq("operateType", operateType)), 10000000)
	local records = {}
	for i,v in ipairs(info) do
		local record = {
			time 		= v.time,
			goodName 	= v.awardName,
		}
		table.insert(records, record)
	end
	return 0, "获取幸运大转盘获奖记录成功", records
end