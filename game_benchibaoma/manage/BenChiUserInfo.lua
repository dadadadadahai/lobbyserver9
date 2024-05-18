module('UserInfo', package.seeall) -- 用户信息

-- db: 得到一个玩家信息
function GetUserDataById(uid)
	return chessuserinfodb.GetUserDataById(uid)
end
-- db: 保存玩家的信息
function SaveUserData(userdata)
	chessuserinfodb.SaveUserData(userdata)
end

-- info: 获取玩家基础数据
function GetUserDataBaseInfo(userData)
	local userBaseInfo = {
		uid 		= userData.uid,
		headUrl 	= userData.base.headurl,
		nickName 	= userData.base.nickname,
		gender  	= userData.base.gender,
		remainder 	= userData.property.chips+userData.property.bankerchips,
		platId 		= userData.base.platid,
		subPlatId 	= userData.base.subplatid,
		giftCoupon 	= userData.property.giftCoupon,
		signature 	= userData.base.signature,
	}
	return userBaseInfo
end
