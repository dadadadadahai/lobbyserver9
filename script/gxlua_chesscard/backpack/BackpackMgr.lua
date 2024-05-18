module('BackpackMgr', package.seeall)  



local tableItemConfig = import"table/table_item_config"
local table_game_list = import "table/table_game_list"

-- 获取背包信息
function CmdBackpackListGetByUid(uid)
	local userBackpack = unilight.getdata("userbackpack", uid)
	if table.empty(userBackpack) then
		userBackpack = {
			_id = uid,
			uid = uid,
			surplus  = {}, -- 剩余所有物品集合	goodId -> goodNum 
			consum 	 = {}, -- 记录消费物品集合 	goodId -> goodNum 
			exchange = {}, -- 记录一条条物品使用消息
			backpack = {}, -- 记录一条条物品获取信息
		}
		unilight.savedata("userbackpack", userBackpack)
	end
    CheckTimeAndRemove(userBackpack)
	return userBackpack
end

--检测时限道具,并移除
function CheckTimeAndRemove(userBackpack, bNotify)
    if userBackpack == nil then
        return
    end
    local uid = userBackpack.uid
    local bUpdate = false
    for i = #userBackpack.surplus, 1, -1 do
        local goodInfo = userBackpack.surplus[i]
        if goodInfo.prop.overTime ~= nil and os.time() > goodInfo.prop.overTime then
            unilight.info(string.format("玩家:%d,道具:%d,overtime=%d,到期时间删除", uid, goodInfo.goodId, goodInfo.prop.overTime))
            table.remove(userBackpack.surplus, i)
            if bNotify ~= nil then
                SendDeleteItemToMe(uid, goodInfo)
            end
            bUpdate = true
        end
    end
    if bUpdate then
		unilight.savedata("userbackpack", userBackpack)
    end
end

-- 获取普通物品
function CmdGetNormalRewardGood(uid, goodId, goodNum, sourceId, sourceType)
	local userBackpack = CmdBackpackListGetByUid(uid)	
	local date = chessutil.FormatDateGet()
    local reason = Const.GOODS_SOURCE_NAME[sourceId] or "未知"
	local subGoodSInfo = {
		goodid 		= goodId,
		fetchtime 	= date,
		sourcetype 	= sourceType,
		goodNum 	= goodNum,
        reason      = reason,
	}
	table.insert(userBackpack.backpack, subGoodSInfo)

    local lastCount = goodNum
    local itemConfig = tableItemConfig[goodId]

    --处理叠加数量
    for _, goodInfo in pairs(userBackpack.surplus) do
        if goodInfo.goodId == goodId and goodInfo.goodNum < itemConfig.overNum then
            goodInfo.goodNum = goodInfo.goodNum + lastCount
            lastCount = 0
            if goodInfo.goodNum  > itemConfig.overNum then
                lastCount = itemConfig.overNum - goodInfo.goodNum
                goodInfo.goodNum = itemConfig.overNum
            end
            SendItemNumChangeToMe(uid, goodInfo)
        end
    end

    --处理还剩下的数量
    local goodInfoList = {}
    while lastCount > 0 do
        local goodInfo = {
            id=go.newObjectId(),
            goodId = goodId,
            goodNum=lastCount,
            prop = {
                addTime=os.time(),
            }
        }
        lastCount = 0
        if goodInfo.goodNum > itemConfig.overNum then
            lastCount = goodInfo.goodNum - itemConfig.overNum  
            goodInfo.goodNum = itemConfig.overNum
        end

        --时限道具
        if itemConfig.limitTime > 0 then
            goodInfo.prop.overTime = os.time() + itemConfig.limitTime
        end

        table.insert(userBackpack.surplus, goodInfo)
        table.insert(goodInfoList, goodInfo)
    end

 	if table.len(goodInfoList) > 0 then
        SendAddItemToMe(uid, goodInfoList)
    end
	
	unilight.savedata("userbackpack", userBackpack)
    --获得物品回调
    UserInfo.AddItemEvent(uid, goodId, goodNum)
end

-- 获取物品统一处理接口
-- summary = {goodId:goodNum} 汇总 
--[[
	uid: 玩家uid
	goodsId: 道具表道具id
	goodsNbr: 道具数量
	sourceType: GOODS_SOURCE_TYPE,没有自己定一个
	summary: 获得物品汇总,不需要可以不传
]]
function GetRewardGood(uid, goodId, goodNum, sourceType, summary)
	-- 有些时候 获取物品 不需要汇总功能 summary没传时 避免出错
	summary 	= summary or {}
	sourceType 	= sourceType or 0
    local reason = Const.GOODS_SOURCE_NAME[sourceType] or "未知"

    if uid == nil or type(uid) ~= "number" or Const.GOODS_SOURCE_NAME[sourceType] == nil then
        unilight.error("玩家获得道具时参数错误, 请检查代码")
        return
    end

	local tableGood = tableItemConfig[goodId]
    if tableGood == nil then
        unilight.error("玩家获得道具时错误的道具id:"..goodId)
        return
    end

    --数据校验
    if type(goodNum) ~= "number" or goodNum < 0 or tostring(goodNum) == "nan" or tostring(goodNum) == "inf" then
        unilight.error("玩家获得道具时错误的道具数量:"..goodId..", goodNum"..goodNum)
        return
    end
    if tableGood.goodType == Const.GOODS_TYPE.GOLD and goodNum<=0 then
        return
    end
	-- 金币
    if tableGood.goodType == Const.GOODS_TYPE.GOLD then
        chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.ADD, goodNum, Const.GOODS_SOURCE_NAME[sourceType], sourceType)
        --如果是金币，要判断增加下排行榜
        if sourceType > 10000 then
            local gameId = sourceType % 1000 
            local userInfo = chessuserinfodb.RUserInfoGet(uid)
            local gameInfo = userInfo.gameInfo
            local gameKey = gameId * 10000 + gameInfo.subGameType
            local gameConfig = table_game_list[gameKey]
            if gameConfig ~= nil then
                local userInfo = chessuserinfodb.RUserInfoGet(uid)
                userInfo.property.slotsWins = userInfo.property.slotsWins + goodNum
                chessuserinfodb.SaveUserData(userInfo)
                -- unilight.incdate("userinfo", uid, { property.slotsWins = goodNum })
            end

        end

        -- 金币基础
    elseif tableGood.goodType == Const.GOODS_TYPE.GOLD_BASE then
        --加成统一处理
        goodNum = chessuserinfodb.GetChipsAddition(uid, goodNum)
        chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.ADD, goodNum, Const.GOODS_SOURCE_NAME[sourceType], sourceType)
            --chessuserinfodb.WGiftCouponsChange(uid, 1, goodNum)

        -- 宝石
    elseif tableGood.goodType == Const.GOODS_TYPE.DIAMOND then
        chessuserinfodb.WDiamondChange(uid, Const.PACK_OP_TYPE.ADD, goodNum, Const.GOODS_SOURCE_NAME[sourceType], sourceType)


        -- 礼包(则拆开 -- bug 拆礼包时 必须拆goodNum个)
        --TODO位置占用
    elseif tableGood.goodType == 999999 then
        local giftGoods = tableGood.giftGoods
        for i,v in ipairs(giftGoods) do
            summary = GetRewardGood(uid, v.goodId, v.goodNum * goodNum, sourceType, summary)
        end
-- buff
	elseif tableGood.goodType == Const.GOODS_TYPE.BUFF then
		local buffId = tonumber(tableGood.para2)
		local buffTime = tonumber(tableGood.para1) * goodNum
		BuffMgr.AddBuff(uid, buffId, buffTime)
	--随机道具组
	elseif tableGood.goodType == Const.GOODS_TYPE.RANDOM_GROUP then
		local randomGroupId = tonumber(tonumber(tableGood.para1))
		for i=1, goodNum do
			ItemRandomMgr.GetRandomGroupByRandId(uid, randomGroupId, sourceType, summary)
		end
    --随机道具
	elseif tableGood.goodType == Const.GOODS_TYPE.RANDOM_ITEM then
		local randomGroupId = tonumber(tonumber(tableGood.para1))
		for i=1, goodNum do
			ItemRandomMgr.GetRandomItemByRandId(uid, randomGroupId, sourceType, summary)
		end
	--收集物
	elseif tableGood.goodType == Const.GOODS_TYPE.COLLECT then
		for i=1, goodNum do
			CollectMgr.AddCollect(uid, goodId, sourceType)
			Nado.NadoGetCollect(uid, goodId)
		end
		summary[goodId] = summary[goodId] or 0
		summary[goodId] = summary[goodId] + goodNum
	--vip积分
	elseif tableGood.goodType == Const.GOODS_TYPE.VIP_SCORE then
        --goodNum    	 vip积分(uid, goodNum)
		vipCoefficientMgr.ExpCoefficientForVip(uid,goodNum)
	--任务通行证积分
	elseif tableGood.goodType == Const.GOODS_TYPE.TASK_PASS then
		DaysTaskMgr.AddPassPoint(uid,goodNum)
	--任务通行证等级
	elseif tableGood.goodType == Const.GOODS_TYPE.PASS_LEVEL then
		DaysTaskMgr.AddPassTaskLevel(uid,goodNum)
	--双王之战神像徽章
	elseif tableGood.goodType == Const.GOODS_TYPE.GODSTATUE_BADGE then
		for i=1,goodNum do
			godstatueMgr.addGodStatueBadeg(uid, goodId, sourceType)
		end
	--俱乐部分数
	elseif tableGood.goodType==Const.GOODS_TYPE.CLUB_SCORE then
		clubmgr.ClubScoreAdd(uid,goodNum,Const.CLUB_ADD_TYPE.NORMAL)
    --挑战钻石
    elseif tableGood.goodType==Const.GOODS_TYPE.CHALLENGE_DIAMO then
        challengeMgr.ChallengeAddDiamo(uid,goodNum,Const.GOODS_TYPE.CHALLENGE_DIAMO)
    --假金币
    elseif tableGood.goodType==Const.GOODS_TYPE.AHEADSCORE then
        chessuserinfodb.AddAheadScore(uid,goodNum)
    else
		CmdGetNormalRewardGood(uid, goodId, goodNum, sourceId, sourceType)
	end

	-- 汇总总共获取了多少物品（礼包全部拆开）
    local disableTypeList = {
        -- Const.GOODS_TYPE.RANDOM_GROUP,
        -- Const.GOODS_TYPE.RANDOM_ITEM,
        Const.GOODS_TYPE.COLLECT,
    }
    if table.find(disableTypeList, tableGood.goodType) == nil then
		summary[goodId] = summary[goodId] or 0
		summary[goodId] = summary[goodId] + goodNum
		-- 获取物品统一打日志
		unilight.info("玩家：" .. uid ..", 获得物品:(goodId:" .. goodId .. ", num:" .. goodNum.."), 原因: " .. reason)
	end

	return summary
end

--检测查道具是否足够
function CheckItemEnough(uid, goodId, goodNum)
    local userBackpack = CmdBackpackListGetByUid(uid)
    CheckTimeAndRemove(userBackpack, true)
    local remainCount = 0
	for _, goodInfo in pairs(userBackpack.surplus) do
           if goodInfo.goodId == goodId then
               remainCount = remainCount + goodInfo.goodNum
           end
    end
    if remainCount < goodNum then
        return false
    end

    return true
end


-- 使用物品
function UseItem(uid, goodId, goodNum, reason)
	local userBackpack = CmdBackpackListGetByUid(uid)
    CheckTimeAndRemove(userBackpack, true)
    local remainCount = 0


    local goodList = {}

    --统计剩余
    for _, goodInfo in pairs(userBackpack.surplus) do
        if goodInfo.goodId == goodId then
            remainCount = remainCount + goodInfo.goodNum
            table.insert(goodList, goodInfo)
        end
    end
	if remainCount < goodNum then
		return false, "不存在，或者不够"
	end

    --处理使用一个道具的情况
    if  goodNum == 1 then 
        --按获得时间排序下列表
        table.sort(goodList,function (a, b)
            return a.prop.addTime < b.prop.addTime
        end)

        --最早添加的物品id
        local id = goodList[1].id
        
        for i = #userBackpack.surplus, 1, -1 do
            local goodInfo = userBackpack.surplus[i]
            if goodInfo.id == id then
                goodInfo.goodNum =  goodInfo.goodNum - goodNum
                if goodInfo.goodNum <= 0 then
                    goodInfo.goodNum = 0
                    SendDeleteItemToMe(uid, goodInfo)
                    table.remove(userBackpack.surplus, i)
                    break
                end
                SendItemNumChangeToMe(uid, goodInfo)
            end
        end
    else

        --扣除道具
        local lastCount = goodNum
        for i = #userBackpack.surplus, 1, -1 do
            local goodInfo = userBackpack.surplus[i]
            if goodInfo.goodId == goodId then
                --删除道具
                if lastCount >= goodInfo.goodNum then
                    lastCount = lastCount - goodInfo.goodNum
                    goodInfo.goodNum =  0
                    SendDeleteItemToMe(uid, goodInfo)
                    table.remove(userBackpack.surplus, i)
                    --扣除数量
                else
                    goodInfo.goodNum =  goodInfo.goodNum - lastCount
                    lastCount = 0
                    SendItemNumChangeToMe(uid, goodInfo)
                end

                if lastCount == 0 then
                    break;
                end
            end
        end
    end

	userBackpack.consum[goodId] = userBackpack.consum[goodId] or 0
	userBackpack.consum[goodId] = userBackpack.consum[goodId] + goodNum

	local extdata = reason
	unilight.info("玩家:"..uid..",使用物品(goodid:" .. goodId .. ",num:" .. goodNum.."), 原因:"..reason or "")
	-- 物品使用分类处理
	-- elseif content ~= nil then
		-- 发送公告
		-- local userInfo = chessuserinfodb.RUserInfoGet(uid)
		-- local nickName = userInfo.base.nickname
		-- local bMan 	   = false
		-- if userInfo.base.gender == "男" then
		-- 	bMan = true
		-- end
		-- chesscommonchat.CommonChat(uid, nickName, bMan, chesscommonchat.ENUM_CHAT_POS.SUONA, chesscommonchat.ENUM_CHAT_TYPE.LOBBY, content)
	-- end
	
	-- 记录一条兑换消息
	local exchange = {
		goodid = goodId,
		goodnbr = goodNum,
		extdata = extdata,
		date = chessutil.FormatDateGet(),
	}	
	table.insert(userBackpack.exchange, exchange)
	unilight.savedata("userbackpack", userBackpack)
    UseItemReward(uid, goodId, goodNum)
    UserInfo.DeleteItemEvent(uid, goodId, goodNum)
	return true, "ok" 
end

-- 使用物品指定物品id
function UseItemById(uid, id, goodNum, reason)
	local userBackpack = CmdBackpackListGetByUid(uid)
    CheckTimeAndRemove(userBackpack, true)
    local remainCount = 0


    local goodId =  0
    --统计剩余
    for _, goodInfo in pairs(userBackpack.surplus) do
        if goodInfo.id == id then
            remainCount = remainCount + goodInfo.goodNum
            goodId = goodInfo.goodId
            break
        end
    end
	if remainCount < goodNum then
		return false, "不存在，或者不够"
	end

    --处理使用一个道具的情况
    if  goodNum == 1 then 
        for i = #userBackpack.surplus, 1, -1 do
            local goodInfo = userBackpack.surplus[i]
            if goodInfo.id == id then
                goodInfo.goodNum =  goodInfo.goodNum - goodNum
                if goodInfo.goodNum <= 0 then
                    goodInfo.goodNum = 0
                    SendDeleteItemToMe(uid, goodInfo)
                    table.remove(userBackpack.surplus, i)
                    break
                end
                SendItemNumChangeToMe(uid, goodInfo)
            end
        end
    else

        --扣除道具
        local lastCount = goodNum
        for i = #userBackpack.surplus, 1, -1 do
            local goodInfo = userBackpack.surplus[i]
            if goodInfo.id == id then
                --删除道具
                if lastCount >= goodInfo.goodNum then
                    lastCount = lastCount - goodInfo.goodNum
                    goodInfo.goodNum =  0
                    SendDeleteItemToMe(uid, goodInfo)
                    table.remove(userBackpack.surplus, i)
                    --扣除数量
                else
                    goodInfo.goodNum =  goodInfo.goodNum - lastCount
                    lastCount = 0
                    SendItemNumChangeToMe(uid, goodInfo)
                end

                if lastCount == 0 then
                    break;
                end
            end
        end
    end

	userBackpack.consum[goodId] = userBackpack.consum[goodId] or 0
	userBackpack.consum[goodId] = userBackpack.consum[goodId] + goodNum

	local extdata = reason
	unilight.info("玩家:"..uid..",使用物品(goodid:" .. goodId .. ",num:" .. goodNum.."), 原因:"..reason or "")
	-- 物品使用分类处理
	-- elseif content ~= nil then
		-- 发送公告
		-- local userInfo = chessuserinfodb.RUserInfoGet(uid)
		-- local nickName = userInfo.base.nickname
		-- local bMan 	   = false
		-- if userInfo.base.gender == "男" then
		-- 	bMan = true
		-- end
		-- chesscommonchat.CommonChat(uid, nickName, bMan, chesscommonchat.ENUM_CHAT_POS.SUONA, chesscommonchat.ENUM_CHAT_TYPE.LOBBY, content)
	-- end
	
	-- 记录一条兑换消息
	local exchange = {
		goodid = goodId,
		goodnbr = goodNum,
		extdata = extdata,
		date = chessutil.FormatDateGet(),
	}	
	table.insert(userBackpack.exchange, exchange)
	unilight.savedata("userbackpack", userBackpack)
    UseItemReward(uid, goodId, goodNum)
    UserInfo.DeleteItemEvent(uid, goodId, goodNum)
	return true, "ok" 
end

-- 获得指定类型的物品列表
function GetItemListByType(uid, goodType)
	local itemList = {}
	local userBackpack = unilight.getdata("userbackpack", uid)
    CheckTimeAndRemove(userBackpack, true)
    if userBackpack == nil then
        return itemList
    end
	for _, goodInfo in pairs(userBackpack.surplus) do
		local tableGood = tableItemConfig[goodInfo.goodId]
		if tableGood ~= nil and tableGood.goodType == goodType then
			table.insert(itemList, goodInfo)
		end
	end
	return itemList
end

--根据物品id获得物品列表
function GetItemListByGoodId(uid, goodId)
	local itemList = {}
	local userBackpack = unilight.getdata("userbackpack", uid)
    CheckTimeAndRemove(userBackpack, true)
    if userBackpack == nil then
        return itemList
    end
	for _, goodInfo in pairs(userBackpack.surplus) do
		local tableGood = tableItemConfig[goodInfo.goodId]
		if tableGood ~= nil and tableGood.goodId == goodId then
			table.insert(itemList, goodInfo)
		end
	end
	return itemList
end

--获得指定类型物品数量
function GetItemNumByGoodId(uid, goodId)
	local userBackpack = unilight.getdata("userbackpack", uid)
    CheckTimeAndRemove(userBackpack, true)
    local remain = 0
    for _, goodInfo in pairs(userBackpack.surplus) do
        if goodInfo.goodId == goodId then
            remain = remain + goodInfo.goodNum
        end
    end
    return remain
end


--使用道具后获得奖励
function UseItemReward(uid, goodId, goodNum)
    local tableGood = tableItemConfig[goodId]
    --获得buff道具
    if tableGood.goodType == Const.GOODS_TYPE.BUFF_CUSTOM then
		local buffId = tonumber(tableGood.para2)
		local buffTime = tonumber(tableGood.para1) * goodNum
		BuffMgr.AddBuff(uid, buffId, buffTime)
    end

end


--发送一个添加道具消息到客户端
function SendAddItemToMe(uid, goodInfoList)
	local send = {}
	send["do"] = "Cmd.AddItemBackpackCmd_S"
	send["data"] = {
        goodInfoList = goodInfoList
	}
	unilight.sendcmd(uid, send)

end


--发送一个增加道具消息到客户端
function SendDeleteItemToMe(uid, goodInfo)
	local send = {}
	send["do"] = "Cmd.DeleteItemBackpackCmd_S"
	send["data"] = {
        goodInfo = goodInfo,
	}
	unilight.sendcmd(uid, send)
end


--增加或减少道具数量
function SendItemNumChangeToMe(uid, goodInfo)
	local send = {}
	send["do"] = "Cmd.ItemChangeBackpackCmd_S"
    send.data = {
       goodInfo = goodInfo 
    }
	unilight.sendcmd(uid, send)
end
