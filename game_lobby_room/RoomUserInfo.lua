module('UserInfo', package.seeall) -- 用户信息

InitCardNum 	= 0		    -- 初始房卡
InitDiamondNum 	= 100		-- 初始砖石
HISTORY_NBR 	= 50 		-- 玩家所属默认只保存最新50条
RETURN_DIAMOND  = 5         -- 推广员返点5钻石
-- db: 注册玩家
function UserRegister(uid, lobbyId)
	local userdata = CreateUserData(uid, 0, lobbyId)
	return userdata
end

-- db: 构造玩家具体信息
function CreateUserData(uid, parent, lobbyId, parentIsAgent)
    playprops = playprops or {}
	local userdata = chessuserinfodb.CreateUserData(uid, 0) -- 以前chips 现在默认为0
	-- 针对麻将大厅的初始化
	userdata.mahjong = {
		card 	= nil, 			                                   -- 玩家房卡数量	
        play    = {},                                              -- 所有参与过的组局 用于汇总战绩 里面只存全局唯一的 globalRoomId
        lastcreate = nil,                                          -- 最新一次创建记录
        isRecover = nil,                                           -- 单纯用于标记 龙岩 是否已恢复老区砖石数据 
        gZGive    = nil,                                           -- 用于标记贵州是否给老用户赠送过              
    }

    -- 初始化vip相关数据
    CreateUserVipData(userdata)
    -- 推销
    CreateUserMarketData(userdata, parent, parentIsAgent) 
    SaveUserData(userdata)
    
    -- 如果是扫码预登陆的 可能出现lobbyId为nil 则 暂时不赋值钻石
	if lobbyId ~= nil then
        -- 如果lobby为江西客家 则初始化房卡
        if lobbyId == 7 then
            _, _, _, userdata  = CommonChangeUserCard(uid, 1, TableLobbyGameList[lobbyId].iniRoomCard, nil, "账号创建", ItemStatistics.ENUM_STATIC_TYPE.CRT)
        end

        _, _, _, userdata  = CommonChangeUserDiamond(uid, 1, TableLobbyGameList[lobbyId].iniDiamond, nil, "账号创建", ItemStatistics.ENUM_STATIC_TYPE.CRT)
    end
	
	return userdata
end

function CheckCreateInviteRankData(uid, userdata)
    local data = unilight.getdata("inviterank", uid)
    if data == nil then
        local data = {
            _id = uid,
            myselfplaynum = 0,
            childnum = 0,
            childplaynum = 0,
            extdata = "",
            score = 0,
            nickname = userdata.base.nickname,
            headurl = userdata.base.headurl,
        }
        unilight.savedata("inviterank", data)
        return
    end
    if data.nickname == "" or data.headurl == "" then
            data.nickname = userdata.base.nickname
            data.headurl = userdata.base.headurl
            unilight.savedata("inviterank", data)
    end
end

-- 初始化vip相关数据
function CreateUserVipData(userdata) 
    userdata.vip = {
        level       = 0,    -- vip等级
        recharge    = 0,    -- 玩家真实累计充值
    }
end

-- 初始化推广数据 parentIsAgent 上级是否为代理商
function CreateUserMarketData(userdata, parent, parentIsAgent) 
    -- 如果上级没有层级，表示该代理为总代理，此时为层级为1
    userdata.marketing = {
        parent = parent,
        myselfplaynum = 0,
        childplaynum = 0,
        childnum = 0,
        child = {},
        reward = {
            all             = 0,
            notreceive      = 0,
            alreadyreceive  = 0,
        },
        isreturn = 0,       --  0/1/2/nil  未给上级返点、已返点、该玩家不需要返点、推荐老数据为nil也不需要返点
    }
    if parentIsAgent == 1 then
        userdata.marketing.isreturn = 2
    end
end

-- db: 得到一个玩家信息
function GetUserDataById(uid)
	return chessuserinfodb.GetUserDataById(uid)
end
-- db: 保存玩家的信息
function SaveUserData(userdata)
	chessuserinfodb.SaveUserData(userdata)
end

-- info: 获取玩家基础数据
function GetUserDataBaseInfo(data)
	local userBaseInfo = {
		uid 		= data.uid,
		headUrl 	= data.base.headurl,
		nickName 	= data.base.nickname,
		gender  	= data.base.gender, 
		platId 		= data.base.platid,
		subPlatId 	= data.base.subplatid,
		ip  		= "127.0.0.1",
		parent 		= 0,
	}

	-- 默认不填或者为2时-房卡模式  4-钻石模式
	if go.getconfigint("zone_type") == 4 then
		-- 兼容老玩家数据 不存在diamond数据
		data.mahjong.diamond = data.mahjong.diamond or InitDiamondNum
		userBaseInfo.diamond = data.mahjong.diamond
    end

    -- 房卡始终赋值出去
	userBaseInfo.card = data.mahjong.card

	local laccount = go.roomusermgr.GetRoomUserById(data.uid)
	if laccount ~= nil then
		userBaseInfo.ip = laccount.GetLoginIpstr()
	end

	-- 获取其上级代理
	if data.marketing ~= nil and data.marketing.parent ~= nil then
		userBaseInfo.parent = data.marketing.parent
	end

    -- 填充vip数据
    if data.vip ~= nil then
        userBaseInfo.vip = data.vip.level
    end

	return userBaseInfo
end

function GetMarketingListById(uid)
    local userData = GetUserDataById(uid)
    if userData == nil then
        return nil
    end
    local childs = {}
    for i, v in pairs(userData.marketing.child) do
        table.insert(childs, {uid=i,createTime = v.invitetime})
    end
    return childs
end
-- 查看当前房卡
function RoomCardGet(uid)
	return chessuserinfodb.RUserMahjongCardGet(uid)
end

-- 查看当前钻石
function RoomDiamondGet(uid)
	return chessuserinfodb.RUserMahjongDiamondGet(uid)	
end

-- 房卡变动 type 1房卡增加 2房卡减少
function ChangeRoomCard(uid, type, num, statistics, desc, changeType)
	if num < 0 then
		num = -num
	end
 	local userData = GetUserDataById(uid)
 	if userData == nil then
 		unilight.info("房卡变动有误 当前玩家不存在：" .. uid)
 		return 1, "房卡变动有误 uid不存在：" ..uid
 	end

    userData.mahjong.card = userData.mahjong.card or 0

 	if type == 1 then
 		-- 增加
 		userData.mahjong.card = userData.mahjong.card + num
 		unilight.info("uid:" .. uid .. " 获得房卡 num:" .. num) 	

        -- 房卡变动记录(通用)
        ChessItemsHistory.AddItemsHistory(uid, 3, userData.mahjong.card, num, desc)
 	else
 		-- 减少
 		if userData.mahjong.card < num then
 			return 2, "当前房卡不足", userData.mahjong.card
 		end

 		userData.mahjong.card = userData.mahjong.card - num
 		unilight.info("uid:" .. uid .. " 扣除房卡 num:" .. num)

        -- 房卡变动记录(通用)
        ChessItemsHistory.AddItemsHistory(uid, 3, userData.mahjong.card, -num, desc)
 	end

 	-- 存档
 	SaveUserData(userData)

    -- 存档结束后 把服务器钻石汇总更新一下(钻石 itemId=2)
    if type == 1 then
        ItemStatistics.UpdateItemStatistics(2, changeType, num)
    else
        ItemStatistics.UpdateItemStatistics(2, changeType, -num)
    end

 	return 0, "房卡变动成功", userData.mahjong.card, userData
end 

-- 统一扣房卡接口 并检测发给前端、发给游戏服 
function CommonChangeUserCard(uid, typ, num, statistics, desc, changeType)
    local ret, desc, card, userData = UserInfo.ChangeRoomCard(uid, typ, num, statistics, desc, changeType)
    if ret == 0 then
        -- 通知大厅客户端
        local laccount = go.accountmgr.GetAccountById(uid)
        if laccount ~= nil then
            local userData = UserInfo.GetUserDataById(uid)
            local data = {
                userInfo    = UserInfo.GetUserDataBaseInfo(userData),
            }
            if userData.vip ~= nil then
                data.recharge    = userData.vip.recharge
            end
            RoomInfo.SendCmdToUser("Cmd.UserInfoGetLobbyCmd_S", data, laccount)
        end

        -- 如果在游戏服中 也通知下游戏服 (此处是发送房卡变化)
        RoomInfo.CheckSendDiamondChange(uid, nil, nil, card, num)
    end
    return ret, desc, card, userData
end

-- 钻石变动 type 1钻石增加 2钻石减少  statistics(是否记录到玩家消耗中 只记录正常开房消费) desc(变动原因) changeType(变动项)
function ChangeRoomDiamond(uid, type, num, statistics, desc, changeType)
	if num < 0 then
		num = -num
	end
 	local userData = GetUserDataById(uid)
 	if userData == nil then
 		unilight.info("钻石变动有误 当前玩家不存在：" .. uid)
 		return 1, "钻石变动有误 uid不存在：" ..uid
 	end

    userData.mahjong.diamond = userData.mahjong.diamond or 0

 	if type == 1 then
 		-- 增加
 		userData.mahjong.diamond = userData.mahjong.diamond + num
 		unilight.info("uid:" .. uid .. " 获得钻石 num:" .. num) 	

        -- 钻石变动记录(通用)
        ChessItemsHistory.AddItemsHistory(uid, 2, userData.mahjong.diamond, num, desc)
    else
        -- 减少
        if userData.mahjong.diamond < num then
            return 2, "当前钻石不足",userData.mahjong.diamond
        end

        userData.mahjong.diamond = userData.mahjong.diamond - num
        unilight.info("uid:" .. uid .. " 扣除钻石 num:" .. num)

        if statistics == true then
            userData.mahjong.consume = userData.mahjong.consume or 0
            userData.mahjong.consume = userData.mahjong.consume + num
        end
        -- 钻石变动记录(通用)
        ChessItemsHistory.AddItemsHistory(uid, 2, userData.mahjong.diamond, -num, desc)
    end

    -- 存档
    SaveUserData(userData)

    -- 存档结束后 把服务器钻石汇总更新一下(钻石 itemId=2)
    if type == 1 then
        ItemStatistics.UpdateItemStatistics(2, changeType, num)
    else
        ItemStatistics.UpdateItemStatistics(2, changeType, -num)
    end

 	return 0, "钻石变动成功", userData.mahjong.diamond, userData
end

-- 统一扣钻石接口 并检测发给前端、发给游戏服
function CommonChangeUserDiamond(uid, typ, num, statistics, desc, changeType)
    local preDesc = desc -- 缓存下来 发送给代理商系统
    local ret, desc, diamond, userData = UserInfo.ChangeRoomDiamond(uid, typ, num, statistics, desc, changeType)
    if ret == 0 then
        -- 通知大厅客户端
        local laccount = go.accountmgr.GetAccountById(uid)
        if laccount ~= nil then
            local userData = UserInfo.GetUserDataById(uid)
            local data = {
                userInfo    = UserInfo.GetUserDataBaseInfo(userData),
            }
            if userData.vip ~= nil then
                data.recharge    = userData.vip.recharge
            end
            RoomInfo.SendCmdToUser("Cmd.UserInfoGetLobbyCmd_S", data, laccount)
        end

        -- 如果在游戏服中 也通知下游戏服 
        RoomInfo.CheckSendDiamondChange(uid, diamond, num)

        -- 检测下是否发送给代理商系统
        AgentInfo.CheckComsumeNotify(uid, typ, num, preDesc, changeType)
    end
    return ret, desc, diamond, userData
end

-- 创建房间或者加入、返回房间时检测 货币是否足够消耗
function CheckRoomCost(uid, userNbr, gameNbr, payType, hasDecrease, owner, lobbyId)
    local cost = 0 -- 需要消费
	local cur  = 0 -- 当前玩家拥有多少货币

    -- 江西客家消耗房卡
    if lobbyId == 7 then
        cur = RoomCardGet(uid)
    else
        cur = RoomDiamondGet(uid)
    end

	-- 还没扣费过 则需要检测
	if hasDecrease == nil then
        local costTableInfo = RoomInfo.MapTableRoomCost[lobbyId] or RoomInfo.MapTableRoomCost[1]
		if (payType == 1 and owner) or payType == 3 then
			-- 房主支付模式 且 当前为房主 / 大赢家支付则需要所有玩家都足够
			cost = costTableInfo[userNbr][gameNbr].diamondcost
		elseif payType == 2 then
			-- 均摊模式 
			cost = costTableInfo[userNbr][gameNbr].averdiamondcost
		end
	end

	if cur ~= nil and cur >= cost then
		return true, cost
	else
		return false, cost
	end
end

-- 添加玩家战绩
function AddUserPlayData(uid, room)
	local userData = GetUserDataById(uid)
	if userData == nil then
		room:Error("为玩家添加战绩 找不到该玩家 uid:" .. uid)
		return 
	end

	userData.mahjong.play = userData.mahjong.play or {}
	if userData.mahjong.play[#userData.mahjong.play] == room.data.globalroomid then
		room:Error("为玩家添加战绩 该玩家已有此房间数据 uid:" .. uid)
		return 		
	end
	table.insert(userData.mahjong.play, room.data.globalroomid)

	-- 默认只保存玩家新战绩
	local len = #userData.mahjong.play
	if len > HISTORY_NBR then
		userData.mahjong.play = table.slice(userData.mahjong.play, len - HISTORY_NBR + 1 , len)
	end

	room:Debug("为玩家添加战绩:" .. uid)

	SaveUserData(userData)
end

-- 向统计打了一局信息
function AddUserPlayNumData(uid, addnum, lobbyId)
    local inviteRankProps = unilight.getdata("inviterankprops", 1)

    local userData = GetUserDataById(uid)    
    userData.marketing.myselfplaynum = userData.marketing.myselfplaynum or 0
    userData.marketing.myselfplaynum = userData.marketing.myselfplaynum + addnum
    unilight.info("玩家又新打了一局 " ..uid .. "  "..userData.marketing.myselfplaynum)
    local rankData = unilight.getdata("inviterank", uid)
    -- 给自己加分
    rankData.myselfplaynum = userData.marketing.myselfplaynum 
    rankData.score = rankData.myselfplaynum * inviteRankProps.myselfplaynum + rankData.childnum * inviteRankProps.childnum + inviteRankProps.childplaynum*rankData.childplaynum
    rankData.extdata = string.format("%s*%s+%s*%s+%s*%s=%s", rankData.myselfplaynum, inviteRankProps.myselfplaynum, rankData.childnum, inviteRankProps.childnum, rankData.childplaynum, inviteRankProps.childplaynum, rankData.score)
    unilight.savedata("inviterank", rankData)


    local parent = userData.marketing.parent or 0
    if parent == 0 then
        unilight.debug("AddUserPlayNumData err parent is null " .. uid)
        return
    end

    local parentUserData = GetUserDataById(parent)
    if parentUserData == nil then
        unilight.error("AddUserPlayNumData err parent is error uid:%s,parent:%s", tostring(uid), tostring(parent))
        return
    end
    if parentUserData.marketing.child[uid] == nil  then
        unilight.error("AddUserPlayNumData err parent is is not the child uid:%s,parent:%s", tostring(uid), tostring(parent))
        return
    end

    parentUserData.marketing.child[uid].playnum = userData.marketing.myselfplaynum
    local childplaynum = 0
    for i, v in pairs(parentUserData.marketing.child) do
        v.playnum = v.playnum or 0
        childplaynum = childplaynum + v.playnum 
    end
    parentUserData.marketing.childplaynum = childplaynum
    unilight.info("更新打牌数据 " .. parent .. " " .. childplaynum)

    -- 如果下级玩家还未返金币 且 已满4局 则返砖石 (判断为0的原因是 老推荐该值为nil 新推荐该值为0 已返点该值为1)
    if userData.marketing.isreturn == 0 and userData.marketing.myselfplaynum >= 4 then
        -- 下线已返点
        userData.marketing.isreturn = 1

        -- 上线返点记录
        parentUserData.marketing.reward = parentUserData.marketing.reward or {
            all             = 0,
            notreceive      = 0,
            alreadyreceive  = 0,
        }
        local returnDiamond = RETURN_DIAMOND
        if lobbyId ~= nil and TableLobbyGameList[lobbyId].returnDiamond ~= nil and TableLobbyGameList[lobbyId].returnDiamond ~= 0 then
            returnDiamond = TableLobbyGameList[lobbyId].returnDiamond
        end
        parentUserData.marketing.reward.all         = parentUserData.marketing.reward.all + returnDiamond
        parentUserData.marketing.reward.notreceive  = parentUserData.marketing.reward.notreceive + returnDiamond

        unilight.info("返钻记录 uid:" .. uid .. " parent:" .. parent .. "   returnDiamond:" .. returnDiamond)
    end

    SaveUserData(userData)
    SaveUserData(parentUserData)

    -- 给我的推荐者加分
    local rankData = unilight.getdata("inviterank", parent)
    rankData.childplaynum = childplaynum 
    rankData.score = rankData.myselfplaynum * inviteRankProps.myselfplaynum + rankData.childnum * inviteRankProps.childnum + inviteRankProps.childplaynum*rankData.childplaynum
    rankData.extdata = string.format("%s*%s+%s*%s+%s*%s=%s", rankData.myselfplaynum, inviteRankProps.myselfplaynum, rankData.childnum, inviteRankProps.childnum, rankData.childplaynum, inviteRankProps.childplaynum, rankData.score)
    unilight.savedata("inviterank", rankData)
end

-- 向代理商服务器发送玩家推广下线成功记录
function SendParentRelationshipCreate(parent, child)
    local zonetask = unizone.getzonetaskbygameidzonid(unilight.getgameid(), 1)
    if zonetask == nil then
        unilight.error("玩家推广下线成功 但是代理商服务器未开启 parent:" .. parent .. " childId:" .. child)
        return 
    end

    local res = {}
    res["do"] = "Cmd.ParentRelationshipCreateNotity_S"
    res["data"] = {
        parentId = parent,
        childId  = child,
        createTime = os.time()
    }
    unilight.success(zonetask, res)
    unilight.info("send 玩家推广下线成功 给代理商发送数据 parent:" .. parent .. " childId:" .. child)
end

-- operateinfo: 增加下线
function AddMarketingChild(parent, parentUserData, child, userData)
	if parent == child then
		unilight.error("不能设置" .. uid)
		return
	end

    --TODO 这里暂时没有判断当上线没有推光权限时，处理，这个需要沟通
    if parentUserData.marketing[child] ~= nil then
        local desc = "AddMarketingChild err parent have the child can not add again" .. parent .. "  " .. child
        unilight.error(desc)
        return false, desc
    end

    parentUserData.marketing.child[child] = {
        invitetime = os.time(),
        playnum = 0,
        nickname = userData.base.nickname,
        headurl = userData.base.headurl,
    }

    local childnum = 0
    for i, v in pairs(parentUserData.marketing.child) do
        childnum = childnum + 1
    end
    parentUserData.marketing.childnum = childnum
	SaveUserData(parentUserData)

    -- 向排行统计表里加数据
    local inviteRankProps = unilight.getdata("inviterankprops", 1)

    local rankParentData = unilight.getdata("inviterank", parent)
    rankParentData.childnum = parentUserData.marketing.childnum
    rankParentData.score = rankParentData.myselfplaynum * inviteRankProps.myselfplaynum + rankParentData.childnum * inviteRankProps.childnum + inviteRankProps.childplaynum*rankParentData.childplaynum
    rankParentData.extdata = string.format("%s*%s+%s*%s+%s*%s=%s", rankParentData.myselfplaynum, inviteRankProps.myselfplaynum, rankParentData.childnum, inviteRankProps.childnum, rankParentData.childplaynum, inviteRankProps.childplaynum, rankParentData.score)
    unilight.savedata("inviterank", rankParentData)

    -- 成功推广一个下线则发送数据给代理商服务器 
    SendParentRelationshipCreate(parent, child)

    return true
end

-- 领取推广员奖励
function GetInviteReward(userData)
    -- 获取砖石
    local change = userData.marketing.reward.notreceive
    local ret, desc, diamond, userData = CommonChangeUserDiamond(userData.uid, 1, change, nil, "领取推广员奖励", ItemStatistics.ENUM_STATIC_TYPE.IVT)
    if ret == 0 then
        -- 数据改变
        userData.marketing.reward.alreadyreceive = userData.marketing.reward.alreadyreceive + change
        userData.marketing.reward.notreceive = 0

        -- 存档
        SaveUserData(userData)
        return true, diamond, change, userData
    end
    return false
end

-- 检测是否开启签到活动
function CheckSignIn(lobbyId, userData, data)
    -- 暂时只有广东和贵州需要
    if lobbyId == nil or (lobbyId ~= 4 and lobbyId ~= 2) then
        return
    end

    local curDay = 0
    local curZero = chessutil.ZeroTodayTimestampGet()

    -- 贵州方案
    if lobbyId == 4 then
        -- 获取注册时间0点时间戳
        local registerZero = chessutil.ZeroTodayTimestampGetByTime(chessutil.TimeByDateGet(userData.status.registertime))
        -- 开放14天
        curDay = (curZero - registerZero)/(24*3600) + 1
        if curDay > 14 then
            return 
        end

    -- 广东方案
    elseif lobbyId == 2 then
        local curTime = os.time()
        local begin = 1488556800 -- 2017.3.4    零点
        local ended = 1489161600 -- 2017.3.11   零点
        if curTime < begin or curTime >= ended then
            return
        end
    end

    local canGet = 1
    if userData.status.signintime ~= nil and chessutil.ZeroTodayTimestampGetByTime(userData.status.signintime) == curZero then
        canGet = 0
    end 

    if data ~= nil then
        data.openSignIn = 1
        data.days = curDay
        data.canGet = canGet
    end
    return 1, curDay, canGet
end

-- sdk需求给指定玩家加指定物品
function SdkReward(uid, item)
    local all = 0
    for i=1,#item do
        local itemId = item[i].GetItemid()
        local itemNum = item[i].GetItemnum()

        if itemId == 1 then
            -- 加钻石
            all = all + itemNum
        else
            unilight.warn("暂时sdk发奖只支持物品1 当前物品id:" .. itemId)
        end
    end
    if all > 0 then
        local ret, desc, diamond = CommonChangeUserDiamond(uid, 1, all, nil, "sdk发奖", ItemStatistics.ENUM_STATIC_TYPE.SDK)
        if ret == 0 then
            unilight.info("sdk给玩家发奖 uid:" .. uid .. " 钻石数量:" .. all .. "钻 玩家充值后钻石:" .. diamond)
        end
        return ret, desc
    end
    return 4, "sdk发奖 num:0"
end

-- 湖南湖北大厅 约牌赠钻
function CheckRewardTodayFirstPlay(globalRoomData)
    -- 非湖南湖北的房间 就不操作了
    if globalRoomData.lobbyId ~= 1 and globalRoomData.lobbyId ~= 3 then
        return
    end

    -- 是否在活动时间 默认写死 1月25--2月3
    local curTime = os.time()
    if curTime < 1485273600 or curTime > 1486137600 then
        return 
    end

    for i,statistic in ipairs(globalRoomData.history.statistics) do
        local uid       = statistic.uid
        local userData = UserInfo.GetUserDataById(uid)
        local todayfirst = userData.mahjong.todayfirst
        local reward = false

        if todayfirst == nil then
            reward = true
        else
            local curZero   = chessutil.ZeroTodayTimestampGet()
            local zero      = chessutil.ZeroTodayTimestampGetByTime(todayfirst)
            -- 检测是否在同一天
            if curZero ~= zero then
                reward = true
            end
        end 

        -- 如果今天需要奖励 发5个钻
        if reward then
            local num  = 5
            local ret, desc, diamond, userData = CommonChangeUserDiamond(uid, 1, num, nil, "湖南湖北约牌赠钻", ItemStatistics.ENUM_STATIC_TYPE.ARR)
            if ret == 0 then
                userData.mahjong.todayfirst = os.time()
                -- 存档
                UserInfo.SaveUserData(userData)

                unilight.info("湖南湖北约牌赠钻 uid:" .. uid .. " 钻石数量:" .. num .. "钻 玩家充值后钻石:" .. diamond)

                -- pos1 弹窗
                local msg = "您今日的“约牌赠钻”活动奖励已到账，祝您游戏愉快~"
                local laccount = go.accountmgr.GetAccountById(uid)
                if laccount ~= nil then
                    RoomInfo.SendFailToUser(msg, laccount, 1)
                end
            else
                unilight.error("湖南湖北约牌赠钻不成功 加钻有bug uid:" .. uid)
            end
        end
    end    
end

-- 预登陆
function NotifyPreLoginInfo(cmd, parentIsAgent)
    local uid = tonumber(cmd.GetData().GetMyaccid())
    local platId = cmd.GetData().GetPlatid()
    local plataccount = cmd.GetData().GetPlataccount()
    local nickName = cmd.GetData().GetNickname()
    local faceUrl = cmd.GetData().GetFaceurl()
    local gameProps = json.decode(cmd.GetData().GetGameprops())
    local roomId = tonumber(gameProps.roomid or 0)
    local parent = tonumber(gameProps.inviterid or 0) 
    local userData = UserInfo.GetUserDataById(uid)
    roomId = roomId or 0

    if uid == parent then
        unilight.error("自己不能推荐自己" .. uid)
        return
    end

    -- 是否不需要绑定
    local noBind = false

    -- 贵州大厅 如果上级为代理商 则不需要绑定
    if unilight.getgameid() == 9014 and parentIsAgent == 1 then
        noBind = true
    end

    if noBind == false then
        -- 邀请者一个新玩家时，玩家点入
        if userData == nil then
            if parent ~= 0 then
                local parentData = UserInfo.GetUserDataById(parent)
                if parentData ~= nil and parentData.marketing.parent ~= uid then
                    userData = UserInfo.CreateUserData(uid, parent, nil, parentIsAgent)
                    unilight.info("推荐建立档案成功"..  tostring(uid) .. ","..tostring(parent))
                else
                    unilight.error("NotifyPreLoginInfoSdkPmd_CS inviterid is error " .. uid .. "  ,"..parent)
                    return
                end
            else
                unilight.error("NotifyPreLoginInfoSdkPmd_CS inviterid is nil " ..  uid)
                return
            end
        end
       
        -- 当这个玩家还没有登录时，取最近的邀请者为真正的邀请者
        if userData.base.havelogin == nil and parent ~= 0 and parent ~= userData.marketing.parent then
            local parentData = UserInfo.GetUserDataById(parent)
            if parentData ~= nil and parentData.marketing.parent ~= uid then
                userData.marketing.parent = parent 
                if parentIsAgent == 1 then
                    userData.marketing.isreturn = 2
                else
                    userData.marketing.isreturn = 0
                end
                UserInfo.SaveUserData(userData)
                unilight.info("推荐建立档案，用户还没有进入，取最新推荐%s,%s", uid, parent)
            end
        end

        -- 当玩家登陆了，但是还没有推荐者时，可以加上一个邀请者
        if userData.base.havelogin == true and userData.marketing.parent == 0 then
            -- 且该号注册不超一天才能添加推荐人
            if os.time() - (userData.status.registertimestamp or 0) < 24*3600 then
                local parentData = UserInfo.GetUserDataById(parent)
                if parentData ~= nil and parentData.marketing.parent ~= uid then
                    userData.marketing.parent = parent 
                    if parentIsAgent == 1 then
                        userData.marketing.isreturn = 2
                    else
                        userData.marketing.isreturn = 0
                    end
                    UserInfo.SaveUserData(userData)
                    local bok = UserInfo.AddMarketingChild(parent, parentData, uid, userData)
                    if bok == true then
                        unilight.info("推荐成功，这里可能加奖励之类的数据%s,%s", uid, parent)
                        unilight.info("玩家登陆过了，但是还没有推荐者时，可以加上一个邀请者%s,%s", uid, parent)
                    end
                end
            end
        end
    end

    if roomId ~= 0 then
        local roomInfo = RoomInfo.GetRoomInfoById(roomId) 
        if roomInfo ~= nil and roomInfo.data.hasDecrease == nil then
            unilight.info("玩家%s, 将进入房间%s", tostring(uid), tostring(roomId))
            RoomInfo.MapPreLogin[uid] = {
                roomId = roomId,
                inviterId = inviterId,
            }
        else
            unilight.error("房间不存在，或者已开始" .. uid .."  " .. roomId) 
        end
    end
end

-- 闽西龙岩砖石数据恢复
function LongYanDiamondRecover(userData, lobbyId, laccount)
    -- 只需要处理龙岩数据
    if lobbyId ~= 9 then
        return userData
    end

    local uid = userData.uid
    local tableInfo = TablePreDiamond

    if userData.mahjong.isRecover == nil and tableInfo ~= nil and tableInfo[uid] ~= nil then
        local cur  = userData.mahjong.diamond or 0
        local will = tableInfo[uid].diamond
        local change = will - cur
        if change < 0 then
            _, _, _, userData = CommonChangeUserDiamond(uid, 2, -change, nil, "老区砖石恢复")
            laccount.Info("老区钻石恢复 减去" .. -change .. "钻 .. 至:" .. will .. "钻")
        elseif change > 0 then
            _, _, _, userData = CommonChangeUserDiamond(uid, 1, change, nil, "老区砖石恢复")
            laccount.Info("老区钻石恢复 加上" .. change .. "钻 .. 至:" .. will .. "钻")
        else
            laccount.Info("老区钻石恢复 玩家金币刚好正常 不需变动")
        end

        -- 标记已恢复 不需重复操作
        userData.mahjong.isRecover = 1
        SaveUserData(userData)
    end

    return userData
end

-- 贵州老用户 赠钻10个
function GuizhouDiamondGive(userData, lobbyId, laccount)
    -- 只需要处理贵州的
    if lobbyId ~= 4 then
        return userData
    end

    local give = 10 -- 赠送额
    local value= 1  -- 第几次送
    local actTime       = 1490295600 -- 活动开始时间 3.24 3点
    local thresholdTime = 1490284800 -- 老用户认定时间 3.24 0点前的玩家

    -- 活动时间内 老用户增钻 
    if os.time() >= actTime and userData.status.registertimestamp < thresholdTime then
        if userData.mahjong.gZGive == nil or userData.mahjong.gZGive < value then
            _, _, _, userData = CommonChangeUserDiamond(userData.uid, 1, give, nil, "系统赠送", ItemStatistics.ENUM_STATIC_TYPE.GIV)      
        end
        userData.mahjong.gZGive = value
        SaveUserData(userData)       
    end

    return userData
end