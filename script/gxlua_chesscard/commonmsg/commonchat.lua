module('chesscommonchat', package.seeall) 
-- 玩家登陆 
ENUM_CHAT_TYPE = {
	NONE   = 0, -- 世界聊天
	LOBBY  = 1, -- 大厅聊天
	ROOM   = 2, -- 房间聊天
	ROBOT  = 3, -- 机器人聊天
}

ENUM_CHAT_POS = {
	NONE	  = 0,   -- 空
	NORMAL	  = 1,   -- 普通聊天输出
	SYSTEM	  = 2,   -- 系统提示输出
	TIPS      = 4,   -- 冒泡提示
	POP       = 8,   -- 右下角弹出
	PRIVATE   = 16,  -- 私聊输出
	IMPORTANT = 32,  -- 重要信息，屏幕中央输出
	HONOR     = 64,  -- 荣耀信息
	GM	  	  = 128, -- GM系统公告输出位置
	SUONA	  = 256, -- 喇叭
}

MAX_CACHE 		= 10	-- 公聊最大缓存条数
MAX_HONOR_CACHE = 15 	-- 公告最大缓存条数

CommonChatCache  = {}	-- 公聊缓存 		cache{next:{info,next}}
CommonHonorCache = {}	-- 公告缓存 		cache{next:{info,next}}

MapUserChat = {}		-- uid-->timestamp
	

-- 公共聊天接口
function CommonChat(uid, nickName, bMan, chatPos, chatType, brdInfo)
	if uid == nil or nickName == nil or bMan == nil or chatPos == nil or chatType == nil or brdInfo == nil then
		unilight.error("chesscommonchat: commonchat err some para is nil")
		return
	end

	-- 广播
	go.roomusermgr.CommonChatBroadcast(uid, nickName, bMan, chatPos, chatType, brdInfo) 

	-- 公告缓存
	if chatPos == ENUM_CHAT_POS.GM or chatPos == ENUM_CHAT_POS.SUONA then
		local info = {
			type 		= chatPos, 
			msg  		= brdInfo,
			headUrl 	= nil,
			userId 		= uid,
			userName 	= nickName,
		}
		-- 玩家喇叭
		if uid ~= 0 then
			local userInfo = chessuserinfodb.RUserInfoGet(uid)
			info.headUrl = userInfo.base.headurl
		end
		_,CommonHonorCache = MsgCache(info, CommonHonorCache, MAX_HONOR_CACHE)
	end
end

-- 各种消息缓存
function MsgCache(info, cacheSource, max)
	local index = 1
	local tempCache = table.clone(cacheSource)
	local cache = tempCache

	while true do
		if cache.next == nil then
			break
		end 
		index = index + 1 
		cache = cache.next
	end

	-- 加入新数据
	local data = {
		info = info,
		next = nil, 
	}
	cache.next = data

	-- 如果当前为11条 则去除 前面的
	while index > max do 
		local next = tempCache.next
		tempCache.next = next.next
		index = index - 1
	end
   	return info, tempCache
end

-- 各种消息缓存 获取
function MsgCacheGet(cacheSource)
	local record = {}
	local cache = cacheSource

	while true do
		if cache.next == nil then
			break
		end 
		table.insert(record, cache.next.info)
		cache = cache.next
	end
	return record	
end

-- 公聊记录获取
function GetCommonChatRecord()
	return MsgCacheGet(CommonChatCache)
end

-- 公告记录获取
function GetCommonHonorRecord()
	return MsgCacheGet(CommonHonorCache)
end

-- 处理公聊的一些内容 (当前只做一项操作 保存10条记录)
Chat.PmdCommonChatUserPmd_CS = function(info, laccount)
	local uid = laccount.Id

	-- 如果该玩家 为禁言玩家 
	local gag = ChessGmUserInfoMgr.CheckUserPunish(uid, 3)

	-- 荣强渠道 如果充值低于100 则不给发言 
	local canSay = true
	if laccount.JsMessage.GetPlatid() == 151 or laccount.JsMessage.GetPlatid() == 153 then
		canSay = false
		-- 检测是否充值超过100元
		local sumRecharge = chessrechargemgr.CmdUserSumRechargeGetByUid(uid, 0, os.time())
		if sumRecharge >= 100 then
			canSay = true
		end
	end

	-- 如果为禁言 或者 
	if gag or canSay == false then
		laccount.SendCommonChatUserPmdToMe("info")
		info = ""
	else
		info, CommonChatCache = MsgCache(info, CommonChatCache, MAX_CACHE)
   	end

   	-- 如果为荣强20秒内只能发一条
   	if ZoneId == 138 then
   		local cur = os.time()
   		if MapUserChat[uid] == nil or cur - MapUserChat[uid] > 20 then
   			MapUserChat[uid] = cur
   		else
   			info = ""
   		end
   	end
   	return info
end