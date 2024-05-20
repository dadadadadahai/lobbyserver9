module('ZoneInfo', package.seeall) -- 用户信息
local table_game_list = import "table/table_game_list"

--[[
	麻将游戏服优先级分配规则：
		在游戏服启动时 使用的配置文件xml中 可配置 <priority>0</priority> 当前游戏服优先级
		
		tips：优先级取值范围 只能在 -2^31 至 2^31 之间

		创建普通场 大厅只会分配到 优先级为 0 或 正数的游戏服
		如果多个游戏服优先级不一致 则 新创建房间的玩家 会优先往优先级高的服务器分配

		如果：	当前只有一个游戏服 且游戏服A-优先级为-1
				则创建普通场时 会找不到任何一个合适的游戏服
		如果：  游戏服B-优先级为1  游戏服C-优先级为2
				则创建房间时 玩家会被分配至游戏服C
		如果：	游戏服D-优先级也为2  
				则创建房间时 会在C、D之间进行负载均衡 分配适当的区服给玩家


		创建练习场 大厅只会分配到 优先级为 0 或 负数的游戏服
		如果多个游戏服优先级不一致 则 新创建房间的玩家 会优先往优先级【【绝对值】】高的服务器分配

		如果：	当前只有一个游戏服 且游戏服A-优先级为1
				则创建练习场时 会找不到任何一个合适的游戏服
		如果：  游戏服B-优先级为-1  游戏服C-优先级为-2
				则创建房间时 玩家会被分配至游戏服C
		如果：	游戏服D-优先级也为-2  
				则创建房间时 会在C、D之间进行负载均衡 分配适当的区服给玩家
]]
if ZoneClass == nil then
	CreateClass("ZoneClass")
end
ZoneClass:SetClassName("Zone")

GlobalZoneInfoMap = {} --全局区管理,gamezoneid二级key
zoneIdInfoMap={}
-- 通过gameId、zoneId 获取区服信息
function GetZoneInfoByGameIdZoneId(gameid,zoneid)
	local zoneTask = unizone.getzonetaskbygameidzonid(gameid,zoneid)
	if zoneTask then
        return GlobalZoneInfoMap[zoneTask.GetId()]
	end
    return nil
end

-- 生成区
function CreateZone(zonetask)
	local zone = ZoneClass:New() 
	zone.id = zonetask.GetId()
	zone.name = zonetask.GetName()
	zone.gameid = zonetask.GetGameId()
	zone.zoneid = zonetask.GetZoneId()
	zone.state = {}
	zone.state.priority = 0
	zone.state.maxOnlineNum = 10000
	zone.state.zoneTask = zonetask
	zone:Info("CreateZone")
    zoneIdInfoMap[zone.zoneid] = zone
	return zone
end

function ZoneClass:GetId()
	return self.id
end

function ZoneClass:GetName()
	return self.name
end

-- 区服销毁时 置空相关房间的区服信息
function ZoneClass:Destroy()
	for k,room in pairs(RoomInfo.GlobalRoomInfoMap) do
		if room.state.zoneInfo == self then
			room:Debug("当前房间所属区服关闭了 去除房间区服信息")
			room.state.zoneInfo = nil
		end
	end
end

-- 共用区服消息发送
function ZoneClass:SendCmdToMe(doinfo, data)
    local send = {}
    send["do"] = doinfo
    send["data"] = data
    local s = json.encode(send)
    -- self:Info("sendCmdToMe" .. s)
    self.state.zoneTask.SendString(s)	   
end

-- 获取当前gameId最合适的区服 如果为进入练习场则只允许进入到 0权限区服
function GetBestZoneId(uid, mapGameInfoList, gameId, subGameId, roomType, isPractice)
	local gameInfo = mapGameInfoList[gameId] or {}
	local zoneInfos = gameInfo.zoneInfo or {}

	local bestZoneId 		= nil 	-- 最佳区服
	local maxPriority 		= nil 	-- 最高权限
	local zoneNbr 			= 0 	-- 当前游戏区服个数
	local allOver 			= true	-- 所有区服均超过阈值
	local noOver  			= true 	-- 所有区服均没超过阈值
	local maxZoneId 		= nil 	-- 人数最多的区服 
	local minZoneId 		= nil 	-- 人数最少的区服
	local noOverMaxZoneId 	= nil 	-- 未超过阈值且人数最多的区服
    local isRecharge = true        --是否充值(默认充值服务器）
    --[[
    if chessuserinfodb.GetChargeInfo(uid) > 0 then
        isRecharge = true
    end
    ]]

    local gameType = 0
    local str = nil
    local rechargeZone = {}           --充值连接区服
    local notRechargeZone = {}        --非充值连接区服


    for _, gameConfig in pairs(table_game_list) do
        if gameConfig.subGameId == subGameId and gameConfig.roomType == roomType then
            gameType = gameConfig.gameType
            rechargeZone = gameConfig.rechargeZone
            notRechargeZone = gameConfig.notRechargeZone 
            break
        end
    end
    --全部走随机
    if gameType == Const.SUBGAME_TYPE.SLOTS then
    -- if 1 == 2 then
        local zoneLists = {}
        for zoneId, _ in pairs(zoneInfos) do
            --测试模式不分区服
            if unilight.getdebuglevel() > 0 then
                table.insert(zoneLists, zoneId)
            else
                --如果有限制
                -- if table.len(rechargeZone) > 0 and table.len(notRechargeZone) > 0 then
                if table.len(rechargeZone) > 0 then
                    -- if isRecharge or roomType > 1 then  --充值和中高级走充值服务器列表
                    if isRecharge  then  --充值服务器列表
                        if table.find(rechargeZone, zoneId) ~= nil then
                            table.insert(zoneLists, zoneId)
                        end
                    else
                        if table.find(notRechargeZone, zoneId) ~= nil then
                            table.insert(zoneLists, zoneId)
                        end
                    end
                else
                    table.insert(zoneLists, zoneId)
                end
            end
        end
        if table.len(zoneLists) > 0 then
            bestZoneId = zoneLists[math.random(table.len(zoneLists))]
            maxPriority = maxPriority or 0
            str = " 权限:" .. maxPriority .. "可用服务器:"..table2json(zoneLists).." 取随机服务器"
        end

     else
        local zoneLists = {}
        for zoneId, zoneInfo in pairs(zoneInfos) do
            --测试模式不分区服
            if unilight.getdebuglevel() > 0 then
                zoneLists[zoneId] = zoneInfo
            else
                --如果有限制
                if table.len(limitZone) > 0  then
                    if table.find(limitZone, zoneId) ~= nil then
                        zoneLists[zoneId] = zoneInfo
                    end
                else
                    zoneLists[zoneId] = zoneInfo
                end
            end
        end
        unilight.info("所有区服信息:"..table2json(zoneLists))
        for zoneId,zoneInfo in pairs(zoneLists) do
            -- 普通场 只考虑正数权限。。 练习场 只考虑负数权限的。。 0为万金油
            if (isPractice == nil and zoneInfo.priority >= 0) or (isPractice == true and zoneInfo.priority <= 0) then
                -- 有更佳权限的 则 清空掉低权限的所有中间数据
                if maxPriority == nil or math.abs(zoneInfo.priority) > math.abs(maxPriority) then
                    zoneNbr = 0
                    maxZoneId = nil
                    minZoneId = nil
                    noOverMaxZoneId = nil
                    allOver = true
                    noOver = true
                    maxPriority = zoneInfo.priority
                end
                -- 相同权限的各个区服 才来统计出最佳的
                if maxPriority == zoneInfo.priority then
                    -- 取人数最多的区
                    if maxZoneId == nil or zoneInfo.onlineNum > zoneInfos[maxZoneId].onlineNum then
                        maxZoneId = zoneId
                    end
                    -- 取人数最少的区
                    if minZoneId == nil or zoneInfo.onlineNum < zoneInfos[minZoneId].onlineNum then
                        minZoneId = zoneId
                    end

                    if zoneInfo.onlineNum > zoneInfo.maxOnlineNum then
                        -- 超阈值了
                        noOver = false
                    else
                        -- 没超阈值的也取出其中人数最高的区服
                        if noOverMaxZoneId == nil or zoneInfo.onlineNum > zoneInfos[noOverMaxZoneId].onlineNum then
                            noOverMaxZoneId = zoneId
                        end
                        -- allOver = false
                    end

                    zoneNbr = zoneNbr + 1
                end
            end
        end

        if maxPriority ~= nil then
            if allOver then
                bestZoneId = minZoneId 
                str = " 权限:" .. maxPriority .. " 同权限区服个数:" .. zoneNbr .. " 所有区服均超阈值 取人数最少的区服"
            elseif noOver then
                bestZoneId = maxZoneId
                str = " 权限:" .. maxPriority .. " 同权限区服个数:" .. zoneNbr .. " 所有区服都没超阈值 取人数最多的区服"
            elseif noOverMaxZoneId ~= nil then
                bestZoneId = noOverMaxZoneId
                str = " 权限:" .. maxPriority .. " 同权限区服个数:" .. zoneNbr .. " 部分区服超阈值 取没超阈值且人数最多的区服"
            end
        end

    end

	if bestZoneId ~= nil then
		unilight.info("gameId:" .. gameId .. str .. ":" .. bestZoneId)
	end
    print('bestZoneId',bestZoneId)
	return bestZoneId
end

-- 游戏服接入
Zone.zone_connect = function(cmd,zonetask)
	if zonetask.GetGameId() == go.gamezone.Gameid then
		unilight.debug("代理商系统接入")
		return
	end
    
	local zone = GlobalZoneInfoMap[zonetask.GetId()]
	if zone == nil then
		zone = CreateZone(zonetask)
		GlobalZoneInfoMap[zonetask.GetId()] = zone
	end
end

-- 游戏服断开
Zone.zone_disconnect = function(cmd,zonetask)
	if zonetask.GetGameId() == go.gamezone.Gameid then
		unilight.debug("代理商系统断开")
		return
	end
	local zone = GlobalZoneInfoMap[zonetask.GetId()]
	if zone ~= nil then
		zone:Destroy()
		GlobalZoneInfoMap[zonetask.GetId()] = nil
        zoneIdInfoMap[zonetask.GetZoneId()] = nil
		zone:Info("卸载游戏区")
	end
    --清空下游戏在线
    annagent.CleanZoneInfolist(zonetask.GetGameId(), zonetask.GetZoneId())
end

-- 游戏服属性变动
Zone.zone_change_props = function(cmd,zonetask)
	if zonetask.GetGameId() == go.gamezone.Gameid then
		unilight.debug("代理商系统变动")
		return
	end
	local zone = GlobalZoneInfoMap[zonetask.GetId()]
	if zone ~= nil then
		local priority = cmd.GetPriority()
		if priority > 2^31 then
			priority = priority - 2^32
		end
		zone:Info("区配置信息变化回调:" .. zone.state.priority .. "->".. priority)
		zone:Info("区配置信息变化回调:" .. zone.state.maxOnlineNum .. "->".. cmd.GetMaxonlinenum())
		zone.state.priority = priority
		zone.state.maxOnlineNum = cmd.GetMaxonlinenum()
	end
end
