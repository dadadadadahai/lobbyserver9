-- 与游戏服通讯 相关接口
module('LobbyToChessMgr', package.seeall)

-- 暂定破产阈值1000 
BANKRUPTCY_THRESHOLD = 1000

-- 处理筹码警告
function HandleChipsWarn(uid, remainder)
	-- 如果金币低于1000 则向前端 发送破产消息 
	if remainder < BANKRUPTCY_THRESHOLD then 
		BankRuptcyMgr.SendBankRuptcy(uid)
	end
end