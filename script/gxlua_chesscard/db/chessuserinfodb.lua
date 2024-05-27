module('chessuserinfodb', package.seeall) 

tableParameterParameter= import "table/table_parameter_parameter"
local table_parameter_formula = import "table/table_parameter_formula"
local table_auto_pointLimit = import "table/table_auto_pointLimit"

INIT_CHIPS = tableParameterParameter[2].Parameter
INIT_DIAMOND = tableParameterParameter[3].Parameter
BIND_CHIPS = tableParameterParameter[10].Parameter        --绑定手机奖励

-- 玩家登陆 
-- data
--{"costAmount":0,"adid":"699d20c73b6272f42505f02bc3b4bce4","trackerName":"Share","trackerToken":"6jr2ahy","network":"Share","campaign":"","adgroup":"","creative":"","clickLabel":"bTArAhMTDB","costType":"","costCurrency":"","fbInstallReferrer":""},"do":"Cmd.UserInfoSynRequestLbyCmd_C"}
function RUserLoginGet(uid, data)
	local userInfo = RUserInfoGet(uid)
	if userInfo == nil then
		return WUserConstuct(uid, data)
	else
		local bUpdate = false

		-- 优先检测是否更新玩家平台相关信息
		UpdateUserPlatInfo(userInfo, data, bUpdate)
		if bUpdate == true then
			WUserInfoUpdate(uid, userInfo)
		end
		return userInfo
	end
end
 
-- 更新玩家平台相关信息【运营后台 广告信息处理 make byx】
function UpdateUserPlatInfo(userInfo, data, bUpdate)
	bUpdate = true
	local laccount = go.accountmgr.GetAccountById(userInfo.uid)
	local platInfo = {}
	platInfo.nickName = laccount.JsMessage.GetNickname()
	if platInfo.nickName ~= "" then
		userInfo.base.nickname = platInfo.nickName
	end

	platInfo.headUrl = laccount.JsMessage.GetFaceurl()
	if platInfo.headUrl ~= "" and userInfo.base.oldheadurl ~= platInfo.headUrl then
		userInfo.base.headurl = platInfo.headUrl
	end
	platInfo.platAccount = laccount.JsMessage.GetPlataccount()   
	if platInfo.platAccount ~= "" then
		userInfo.base.plataccount = platInfo.platAccount
	end

	-- platInfo.signature = laccount.JsMessage.GetSignature()
	-- if platInfo.signature ~= "" then
	-- 	userInfo.base.signature = platInfo.signature
	-- 	bUpdate = true
	-- end
	-- userInfo.base.signature = ""

	-- userInfo.base.platid = laccount.JsMessage.GetPlatid()
	-- userInfo.base.subplatid = laccount.JsMessage.GetSubplatid()
    -- 不需要再更新
    userInfo.base.platid = data.platid or 0
    userInfo.base.subplatid = userInfo.base.platid % 100
    userInfo.base.imei   = data.adid or ""

    platInfo.campaign = data.campaign or ""
    platInfo.adcode    = data.network or ""
    --facebook专有信息
    if data.fbInstallReferrer ~= nil and data.fbInstallReferrer ~= "" then
		local jsondata = json2table(data.fbInstallReferrer)
		if jsondata.fb_install_referrer_campaign_group_name ~= nill then
        	platInfo.campaign = jsondata.fb_install_referrer_campaign_group_name
			--强制改下广告码
			platInfo.adcode = "Unattributed"
		end
    end
    --快手玩家特殊处理下信息
    if platInfo.adcode == "Kwai for Business" then
        local bIndex, eIndex, campaign = string.find(platInfo.campaign, "(%a+ )")
        if bIndex ~= nil then
            campaign = string.gsub(campaign, "%s+", "")
            platInfo.campaign = campaign
        end
    end
	if string.find(platInfo.adcode,'Kwai')~=nil then
		platInfo.adcode = 'Kwai for Business'
	end
    --谷歌玩家信息特殊处理
    if platInfo.adcode == "Google Ads ACI" then
        platInfo.campaign = string.split(data.campaign, " ")[1]
    end
    userInfo.base.campaign      = platInfo.campaign or ""    --广告账号相关
    -- unilight.info("玩家campaign:"..userInfo.base.campaign)
	if userInfo.base.adcode==nil or userInfo.base.adcode=='' then
		userInfo.base.adcode        = platInfo.adcode           --广告码		
	end

	if laccount.Imei ~= nil and laccount.Imei ~= "" and userInfo.base.imei ~= laccount.Imei then --这里暂时先兼容下,否则还得要求lua跟unilight同时更新
		userInfo.base.imei = laccount.Imei	
		userInfo.base.osname = laccount.Osname
	end
	-- 性别获取
	local gender = nil
	if go.version and go.version > "v0.11.38"then
		-- 如果存该函数
		if laccount.GetGender ~= nil then
			local temp = laccount.GetGender()
			if temp ~= nil and temp ~= 0 then
				if temp == 1 then
					gender = "男"
				elseif temp == 2 then
					gender = "女"
				end
			elseif temp == 0 then
				laccount.Info("数据更新 玩家性别获取失败:" .. temp)
			end
		end
	end	
	if gender ~= nil and userInfo.base.gender ~= gender then
		userInfo.base.gender = gender
		laccount.Info("数据更新 玩家性别更新成功")
 	end
    if userInfo.base.phoneNbr == "" and laccount.JsMessage.GetMobilenum() ~= "" then
        userInfo.base.phoneNbr = laccount.JsMessage.GetMobilenum()
		laccount.Info("玩家更新手机:"..userInfo.base.phoneNbr)
        userInfo.property.chips = userInfo.property.chips + BIND_CHIPS
    end

    if userInfo.base.regFlag == nil then
        platInfo.regFlag = 1
        if Const.SHARE_PLAYER_FLAG[platInfo.adcode] ~= nil then
            platInfo.regFlag = 2
        end
        userInfo.base.regFlag = platInfo.regFlag
    end

    -- if userInfo.base.gpsAdid == nil or userInfo.base.gpsAdid == "" then
    --     if userInfo.base.adjustId ~= "" then
    --         local url = string.format(table_parameter_formula[1004].Formula, userInfo.base.adjustId, userInfo.uid)
    --         unilight.HttpRequestGet("ReturnGpsAdid", url)
    --     end
    -- end

    --字段兼容
    if userInfo.status.withdawTypeState == nil then
        userInfo.status.withdawTypeState = 0
    end
    if userInfo.property.slotsWins == nil then
        userInfo.property.slotsWins = 0
    end
    if userInfo.property.betMoney == nil then
        userInfo.property.betMoney = 0
    end
    if userInfo.status.lastLoginDayNo == nil then
        userInfo.status.lastLoginDayNo = chessutil.GetMorningDayNo()
    end
    if userInfo.point.maxMul == nil then
        userInfo.point.maxMul = 0
    end
    if userInfo.point.maxMulXs == nil then
        userInfo.point.maxMulXs = 0
    end
    if userInfo.point.isMiddleKill == nil then
        userInfo.point.isMiddleKill = 0
    end
    if userInfo.point.chargeMax == nil then
        userInfo.point.chargeMax = 0
    end
    if userInfo.point.MiddleMul == nil then
        userInfo.point.MiddleMul = 0
    end
    if userInfo.point.pointMaxMul == nil then
        userInfo.point.pointMaxMul = 0
    end

    if userInfo.point.rangeControlGames == nil then
        userInfo.point.rangeControlGames = 0
    end

    if userInfo.point.killXs == nil then
        userInfo.point.killXs = 0
	else
		userInfo.point.killXs = 0
    end
    if userInfo.point.killNum == nil then
        userInfo.point.killNum = 0
	else
		userInfo.point.killNum = 0
    end
	
	if userInfo.point.MiddleChageMax ==nil then
		userInfo.point.MiddleChageMax = 0
	end
	if userInfo.point.chargeIndex ==nil then
		userInfo.point.chargeIndex = 0
	end

    -- if userInfo.status.exclusiveNum == nil then
    --     userInfo.status.exclusiveNum = 0
    -- end
	if userInfo.point.isInControl==nil then
		userInfo.point.isInControl = 0
	end
	if userInfo.point.killChargeNum==nil then
		userInfo.point.killChargeNum = 0
	end
	if userInfo.point.isChargeHandle==nil then
		userInfo.point.isChargeHandle = 0
	end
	if userInfo.point.WithdrawcashMax==nil then
		userInfo.point.WithdrawcashMax= 0
	end
	if userInfo.point.killMul ==nil then
		userInfo.point.killMul = 0
	end
	if userInfo.point.killRtp==nil then
		userInfo.point.killRtp = 0
	end
	if userInfo.point.killChargeMax==nil then
		userInfo.point.killChargeMax = 0
	end
	if userInfo.point.killMaxNum==nil then
		userInfo.point.killMaxNum = 0
	end
	if userInfo.point.killTakeEffect==nil then
		userInfo.point.killTakeEffect = 0
	end

	if userInfo.point.cTolxs==nil then
		userInfo.point.cTolxs = 0
	end
	if userInfo.gameData.slotsBet==nil then
        --充值玩家
        if userInfo.property.totalRechargeChips > 0 then
            userInfo.gameData.slotsBet = userInfo.property.totalRechargeChips * 10
        else
            userInfo.gameData.slotsBet = 10000
        end
	end
	if userInfo.gameData.slotsWin==nil then
        if userInfo.property.totalRechargeChips > 0 then
            userInfo.gameData.slotsWin = userInfo.property.totalRechargeChips * 10  -  userInfo.property.totalRechargeChips + WithdrawCash.GetWithdrawcashInfo(userInfo.uid).totalcovertchips + userInfo.property.chips
        else
            userInfo.gameData.slotsWin = userInfo.property.chips + 10000
        end
	end

	if userInfo.gameData.hundreBet==nil then
		userInfo.gameData.hundreBet = 0
	end
	if userInfo.gameData.hunderWin==nil then
		userInfo.gameData.hunderWin = 0
	end
	if userInfo.point.newPlayerCount==nil then
		userInfo.point.newPlayerCount = 0
	end
	if userInfo.point.newPlayerTimeStamp==nil then
		userInfo.point.newPlayerTimeStamp = 0
	end 
	if userInfo.point.IsNormal==nil then
		userInfo.point.IsNormal = 1
	end
	if userInfo.point.IsFirstKill==nil then
		userInfo.point.IsFirstKill = 0
		if userInfo.property.totalRechargeChips>0 then
			userInfo.point.IsFirstKill = 1
		end
	end
	if userInfo.point.noChargeMax ==nil then
		userInfo.point.noChargeMax = 0
	end
	if userInfo.point.noChargeMin ==nil then
		userInfo.point.noChargeMin = 0
	end
	if userInfo.point.freeUpOrDownNum==nil then
		userInfo.point.freeUpOrDownNum = 0
	end
	if userInfo.gameData.latestChargeMoney==nil then
		userInfo.gameData.latestChargeMoney = 0
	end
	if userInfo.point.upLWorkPrcent ==nil then
		userInfo.point.upLWorkPrcent = 0
	end
	if userInfo.point.isCurRechargeUp==nil then
		userInfo.point.isCurRechargeUp = 0
	end
	--1 放 2 收
	if userInfo.point.FreeControlType==nil then
		userInfo.point.FreeControlType = 0
	end
	if userInfo.point.FreeControlIndex==nil then
		userInfo.point.FreeControlIndex = 1
	end
    if userInfo.property.presentChips == nil then
        userInfo.property.presentChips = 0
    end
    if userInfo.property.totalturntablechips == nil then
        userInfo.property.totalturntablechips = 0
    end
    if userInfo.property.totalntaskchips == nil then
        userInfo.property.totalntaskchips = 0
    end

    if userInfo.status.firstPayTime == nil then
        userInfo.status.firstPayTime = 0
    end
    if userInfo.status.firstPayChip == nil then
        userInfo.status.firstPayChip = 0
    end

    if userInfo.base.uploadFlag == nil then
        userInfo.base.uploadFlag = 0
    end

	-- if userInfo.point.validinViteList==nil then
	-- 	userInfo.point.validinViteList = {}
	-- end
	if userInfo.status.onlyRegister==nil then
		userInfo.status.onlyRegister = 0
	end
	if userInfo.status.onlyPlayerRegister==nil then
		userInfo.status.onlyPlayerRegister = 0
	end
    -- if userInfo.property.rebateflowingchip == nil then
    --     userInfo.property.rebateflowingchip = 0
    -- end

    if userInfo.point.resetPresentFlag == nil then
        userInfo.point.resetPresentFlag = 0
    end

	if table.empty(userInfo.point.killcfg) then
		gameKillComm.InitKillCtr(userInfo)
	end

	if userInfo.status.loginPlatId == nil then
		userInfo.status.loginPlatId = 0
	end
	if userInfo.status.loginPlatIds == nil then
		userInfo.status.loginPlatIds = {}
	end
	if userInfo.status.loginPlatReward == nil then
		userInfo.status.loginPlatReward = 0
	end
	if userInfo.status.badgeGetDays == nil then
		userInfo.status.badgeGetDays = {}
	end
	if userInfo.status.inviteRouletteFlag == nil then
		userInfo.status.inviteRouletteFlag = 0
	end
	if userInfo.status.experienceStatus == nil then
		if userInfo.property.totalRechargeChips <= 0 then
			userInfo.status.experienceStatus = 0
		else
			userInfo.status.experienceStatus = 1
		end
	end
	if userInfo.status.isFirstGift == nil then
		userInfo.status.isFirstGift = 0
	end
	if userInfo.status.maxRechargeChips == nil then
		userInfo.status.maxRechargeChips = 0
	end
end
--[[
	获取用户当前的全部金币,包括虚拟金币
]]
function RUserBaseInfoGet(userInfo)
--	local sumRecharge = chessrechargemgr.CmdUserSumRechargeGetByUid(userInfo.uid)
	local nvipInfo = nvipmgr.Get(userInfo.uid)
	local userBaseInfo = {
		uid = userInfo.uid,
		headUrl = userInfo.base.headurl,
		nickName = userInfo.base.nickname,
		plataccount = userInfo.base.plataccount,
		gender  = userInfo.base.gender,
		platId = userInfo.base.platid,
		subPlatId = userInfo.base.subplatid,
		roundNum = userInfo.max.roundnum,
		maxMulti = userInfo.max.maxmulti,
		giftCoupon = userInfo.property.giftCoupon,	-- 奖券
		signature = userInfo.base.signature,		-- 个性签名
		charm = userInfo.base.charm,                -- 魅力
		points = userInfo.point.points, 				-- 积分
        totalSpins = userInfo.property.totalSpins,      --总拉动拉杆次数
        biggestMultipiles = userInfo.property.biggestMultipiles,   --最大倍数
        biggestWins =  userInfo.property.biggestWins,      --最大赢得数
        totalWins  = userInfo.property.totalWins,        --总胜利数 
        vipLevel = nvipInfo.vipLevel,           		--vip等级
		vipExp   = userInfo.property.vipExp,			--vip经验
        level = userInfo.property.level,                 --玩家等级
		exp   = userInfo.property.exp,					 --玩家等级经验
        manorPoint = userInfo.property.manorPoint,       --庄园积分
        challengeLevel =userInfo.property.challengeLevel,--挑战等级
        factionName =userInfo.base.factionName,      --公会名字
        factionHeadUrl =userInfo.base.factionHeadUrl,--公会头像
        chips =userInfo.property.chips,                    --金币数量
        diamond = userInfo.property.diamond,             --宝石数量
		headFramList = userInfo.property.headFramList,	 --头像框列表
		email = userInfo.base.email,				     --邮箱地址
		teamid = userInfo.base.teamid,				      --团队id
        logoutTime = userInfo.status.logoutTime,         --离线时间
        facebookId = userInfo.base.facbookId,             --facebookID
        phoneNbr   = userInfo.base.phoneNbr,             --手机信息
        inviteCode = userInfo.base.inviteCode,           --我的邀请码
        rechargeNum = userInfo.status.rechargeNum,       --充值次数
        regtimestamp = userInfo.status.registertimestamp, --注册时间
        totalRechargeChips = userInfo.property.totalRechargeChips, --累计充值
        loginPlatIds = userInfo.status.loginPlatIds, --更新玩家渠道列表
        experienceStatus = userInfo.status.experienceStatus,  --体验阶段
        isFirstGift = userInfo.status.isFirstGift,  --是否首次赠送金币
        maxRechargeChips = userInfo.status.maxRechargeChips,  --最大充值金额
	}
	userBaseInfo.lossRebateReward = LossRebate.Get(userInfo.uid).yestedayReward		-- 损失返利可领取金额
	return userBaseInfo
end

---------------------------userinfo----------------------------------
function RUserInfoGetByPlatidPlataccount(platid, plataccount)

	local filter1 = unilight.eq("base.plataccount", plataccount)
	local filter2 = unilight.eq("base.platid", platid)
	local filtera = unilight.a(filter2, filter1)
	local res = unilight.getByFilter("userinfo", filter1, 1)
	if table.empty(res) == true then
		return nil
	end
	return res[1]
end

function RUserInfoGet(uid, force)
	local userInfo = unilight.getdata("userinfo", uid, force)
	if table.empty(userInfo) then
		return nil
	end

	return userInfo
end

function RUserInfoGetByName(name)
	local filter = unilight.eq("base.nickname", name)
	local res = unilight.getByFilter("userinfo", filter, 1)
	if table.empty(res) == true then
		return nil
	end
	return res[1]
end

function RUserChipsGet(uid)
	local userInfo = RUserInfoGet(uid)
	if table.empty(userInfo) then
		return 0
	end
	if userInfo.property.chips < 0 then
		local chips = userInfo.property.chips
		userInfo.property.chips = 0  
		unilight.savedata("userinfo", userInfo)
		unilight.error("玩家出现了负值，Bug" .. chips)
	end
	return userInfo.property.chips
end

--获得玩家银币
function RUserDiamondGet(uid)
	local userInfo = RUserInfoGet(uid)
	if table.empty(userInfo) then
		return 0
	end
	if userInfo.property.diamond < 0 then
		local diamond = userInfo.property.diamond
		userInfo.property.diamond = 0  
		unilight.savedata("userinfo", userInfo)
		unilight.error("玩家出现了负值，Bug" .. diamond)
	end
	return userInfo.property.diamond
end

function RUserGiftCouponsGet(uid)
	local userInfo = RUserInfoGet(uid)
	if table.empty(userInfo) then
		return 0
	end

	return userInfo.property.giftCoupon
end

-- 麻将钻石获取
function RUserMahjongDiamondGet(uid)
	local userInfo = RUserInfoGet(uid)
	if userInfo == nil or userInfo.mahjong == nil then
		return 0
	end

	return userInfo.mahjong.diamond
end

-- 麻将房卡获取
function RUserMahjongCardGet(uid)
	local userInfo = RUserInfoGet(uid)
	if userInfo == nil or userInfo.mahjong == nil then
		return 0
	end

	return userInfo.mahjong.card
end

function RUserPlatInfoGet(uid)
	local userInfo = RUserInfoGet(uid)
	if table.empty(userInfo) then
		return nil  
	end
	local platInfo = {
		platAccount = userInfo.base.plataccount,
		platId = userInfo.base.platid,
		subPlatId = userInfo.base.subplatid,
	}	
	return platInfo
end

-- 检测玩家域名
function CheckNickName(userData)
	-- 取域名前13位来作校验
	local url 		= go.getconfigstr("image_server2")
	local check 	= string.sub(url,0,13)

	-- 取玩家headUrl前13位
	local headUrl 	= userData.base.headurl 
	local pre 		= string.sub(headUrl,0,13)

	if pre == check then
		-- 前缀一致 代表自己服务器内的url
		return true
	else
		-- 发送请求 更换url
		RequstChangeHeadUrl(userData.uid, headUrl)
		return false
	end
end

-- 随机图像生成
function RandomIcon()
    local head_url = math.random(1, 50)
    return tostring(head_url)
end

--[[
-- 创建新玩家
-- @params data: 参数
{
    "costAmount":0,                     --安装成本
    "adid":"699d20c73b6272f42505f02bc3b4bce4", --设备的唯一adjustID
    "trackerName":"Share",              --当前归因跟踪连接的名称
    "trackerToken":"6jr2ahy",           --当前归因跟踪连接的跟踪码
    "network":"Share",                  --当前归因渠道的名称
    "campaign":"",                      --当前归因推广活动的名称
    "adgroup":"",                       --当前归因广告组的名称
    "creative":"",                      --当前归因素材的名称
    "clickLabel":"bTArAhMTDB",          --来自邀请码
    "costType":"",                      --推广活动定价模型(如cpi)
    "costCurrency":"",                  --成本相关货币代码
    "fbInstallReferrer":""              --facebook install referrer信息
},
--]]
function WUserConstuct(uid, data)
    -- unilight.info(string.format("创建玩家:%d, 渠道数据:%s", uid, table2json(data)))
	local laccount = go.accountmgr.GetAccountById(uid)
	local platInfo = {}
	local imei = nil
	local osname = nil
	if laccount ~= nil then
		-- platInfo.nickName = laccount.JsMessage.GetNickname()
		platInfo.nickName =  GetFakeNickName()--string.format("user%4d", uid % 10000)
		if platInfo.nickName == "" then
			platInfo.nickName = nil
		end
		platInfo.headUrl = laccount.JsMessage.GetFaceurl()
		if platInfo.headUrl == "" then
			platInfo.headUrl = nil
		end
		platInfo.platAccount = laccount.JsMessage.GetPlataccount()
		if platInfo.platAccount == "" then
			platInfo.platAccount = nil
		end
		-- platInfo.platId = laccount.JsMessage.GetPlatid()
		-- platInfo.subPlatId = laccount.JsMessage.GetSubplatid()
        platInfo.platId = data.platid or 0
        platInfo.imei   = data.adid or ""
        platInfo.inviter = data.clickLabel or ""

        -- unilight.info(string.format("玩家:%d, 来自邀请码:%s", uid, platInfo.inviter))
        platInfo.campaign = data.campaign or ""
        platInfo.adcode    = data.network or ""
        platInfo.adjustid  = data.adid or ""
		if platInfo.adcode=="" then
			platInfo.adcode='Organic'
		end
        --facebook专有信息
		if data.fbInstallReferrer ~= nil and data.fbInstallReferrer ~= "" then
			local jsondata = json2table(data.fbInstallReferrer)
			if jsondata.fb_install_referrer_campaign_group_name ~= nill then
				platInfo.campaign = jsondata.fb_install_referrer_campaign_group_name
				--强制改下广告码
				platInfo.adcode = "Unattributed"
			end
		end
        --快手玩家特殊处理下信息
        if platInfo.adcode == "Kwai for Business" then
            local bIndex, eIndex, campaign = string.find(data.campaign, "(%a+ )")
            if bIndex ~= nil then
                campaign = string.gsub(campaign, "%s+", "")
                platInfo.campaign = campaign
            end
        end
		if string.find(platInfo.adcode,'Kwai')~=nil then
			platInfo.adcode = 'Kwai for Business'
		end
        --谷歌玩家信息特殊处理
        if platInfo.adcode == "Google Ads ACI" then
            -- local bIndex, eIndex, campaign = string.find(data.campaign, "(%a+ )")
            -- print(bIndex, eIndex, campaign)
            -- if bIndex ~= nil then
                -- campaign = string.gsub(campaign, "%s+", "")
                -- platInfo.campaign = campaign
            -- end
            platInfo.campaign = string.split(data.campaign, " ")[1]
        end

		-- unilight.info("玩家campaign:"..platInfo.campaign)
		if laccount.Imei ~= nil then --这里暂时先兼容下,否则还得要求lua跟unilight同时更新
			imei = laccount.Imei	
			osname = laccount.Osname	
		end
        platInfo.regFlag = 1
        if Const.SHARE_PLAYER_FLAG[platInfo.adcode] ~= nil then
            platInfo.regFlag = 2
        end



		-- 通过laccount 获取到个性签名  需要这么一个接口。。(索取 ----------------  mark  )
		-- platInfo.signature = laccount.JsMessage.GetSignature() 
		-- if platInfo.signature == "" then
		-- 	platInfo.signature = nil
		-- end

		-- 性别获取
        -- 如果存该函数
        if laccount.GetGender ~= nil then
            local temp = laccount.GetGender()
            if temp ~= nil then
                if temp == 0 then
                    laccount.Info("创建玩家 性别获取失败:" .. temp)
                else
                    if temp == 1 then
                        platInfo.gender = "男"
                    elseif temp == 2 then
                        platInfo.gender = "女"
                    end
                    laccount.Info("创建玩家 性别获取成功:" .. temp)
                end
            end
        end
	end
	local curtime = os.time()
	local currentdate = chessutil.FormatDateGet()
	local randomHeadUrl = RandomIcon() 
	-- 创建基本表
	local userInfo = {
		_id=uid,
		uid = uid,
		base = {
			nickname       = platInfo.nickName or  GetFakeNickName(),      --玩家名字
			headurl        = platInfo.headUrl or randomHeadUrl,       --玩家头像
            -- headFrame      = 0,                                      --玩家头像框
			email          = platInfo.email or "123@qq.com",          --邮箱
			passwd         = platInfo.passwd or "123456",             --密码
			plataccount    = laccount.JsMessage.GetPlataccount() or "",--平台账号
			platid         = platInfo.platId or 0,                      --平台id
			subplatid      = platInfo.platId % 100,                --子平台id
			gender         = platInfo.gender or "男",                  --性别
			inviter        = platInfo.inviter or "",                    --邀请者
			-- signature      = platInfo.signature or "", --"这家伙很懒，什么都没有留下。",	-- 个性签名
			-- name           = nil,						-- 真实姓名
			phoneNbr       = laccount.JsMessage.GetMobilenum(),						    -- 手机
			-- qq             = nil,						-- qq
			-- zipcode        = nil,						-- 邮编
			-- addr           = nil,						-- 住址
            imei           = platInfo.imei,          --注册机器码
			osname         = osname,					-- osname
			-- charm          = 0,						    -- 魅力
            -- factionName    = 0,                         --公会名字
            -- factionHeadUrl = 0,                         --公会头像
			-- teamid         = 0,							--团队id
            facebookId     = 0,                         --facebookId
            cpf            = "",                        --巴西税号
            realName       = "",                        --真实姓名
            guest          = 0,                         --是否游客
            inviteCode     = GetInviteCode(),           --我的邀请码
            campaign      = platInfo.campaign or "",    --广告账号相关
            adcode         = platInfo.adcode,           --广告码   
            adjustId       = platInfo.adjustid,         --adjust设备 
            regFlag        = platInfo.regFlag,          --注册来源(1投放，0非投放)
            gpsAdid        = "",                        --gps adid
            uploadFlag     = 0,                         --上传图片标志(1已上传，0未上传)

		},
		status = {
			logintime         = currentdate,
			logintimestamp    = curtime,			    -- 存入时间戳 用于筛选
			lastlogintime     = currentdate,
			registertime      = currentdate,            --注册日期
			registertimestamp = curtime,		        -- 存入时间戳 用于筛选
            firstPayTime      = 0,                      --首充时间
            firstPayChip      = 0,                      --首充金额
			-- continueDays      = 1,
            logoutTime        = 0,                      --退出时间
            phoneEditFlag     = 0,                      --能否修改手机,0不能修改，1可以修改
            phoneEditDayNo    = 0,                      --手机修改天数，一天只能修改一次
            registerIp        = laccount.GetLoginIpstr(),                     --注册IP
            lastLoginIp       = "",                     --上次登陆ip
            lastLoginImei     = "",                     --上次登陆imei
            registerSrc       = "",                     --注册来源
            loginNum          = 0,                      --登陆次数
            -- riskFlag          = "",                     --风险标签
            -- traceInfo         = "",                     --追踪信息
            rechargeNum       = 0,                      --充值次数
            chipsWithdrawNum  = 0,                      --金币提现次数
            promoteWithdawNum = 0,                      --推广提现次数
            chipsWithdraw     = 0,                      --金币提现金额
            promoteWithdaw    = 0,                      --推广提现金额 
            -- childNum          = 0,                      --下级人数
            withdawTypeState  = 1,                      --提现类型状态
            lastLoginDayNo    = chessutil.GetMorningDayNo(), --上次登陆天数
            -- exclusiveNum      = 0,                      --专属奖励金额
			onlyRegister = 0,							-- 是否提供给上级过有效充值玩家金钱  （需求更改 但是因为发出去过钱所以字段名不能修改了QAQ） 0 未提供  2 提供过
			onlyPlayerRegister = 0,						-- 注册(注册时候的IP和设备ID)是否唯一  0 不唯一 1 唯一 2 唯一并且已经给上级提供过奖励
            bindFailFlag      = 0,                      --绑定失败标记，失败的话登陆会再次请求
			loginPlatId 	  = 0,						-- 更新玩家渠道	1 安卓网页 2 苹果网页 3 安卓客户端 4 苹果客户端
			loginPlatIds 	  = {},						-- 更新玩家渠道列表(登陆过的全部保存)	1 安卓网页 2 苹果网页 3 安卓客户端 4 苹果客户端
			loginPlatReward   = 0,						-- 玩家渠道奖励是否下发
            badgeGetDays	  = {},               		-- 徽章领取记录
			inviteRouletteFlag = 0,						-- 邀请转盘是否给上级添加过进度
			experienceStatus = 0,						-- 玩家体验状态 默认0 体验币  1 真钱
			isFirstGift       = 0,						-- 是否首次赠送金币 默认 0 没赠送 1 赠送过
			maxRechargeChips  = 0,						-- 最大充值金额
		},
		property = {
			chips                    = INIT_CHIPS or 0,             --初始金币
            totalRechargeChips       = 0,                           --累计充值金额
			giftCoupon               = 0,	                        -- 新增 奖券 （货币）
            totalSpins               = 0,                           --总拉动拉杆次数
            -- biggestMultipiles        = 0,                           --最大倍数
            -- biggestWins              = 0,                           --最大赢得数
            totalWins                = 0,                           --总胜利数
            vipLevel                 = 0,                           --vip等级(默认为0)
			vipExp                   = 0,							--vip经验
			lastVipFensRewardGetTime = 0,			                --上次玩家领取粉丝礼物的时间(秒级时间戳)
            level                    = 1,                           --玩家等级
			-- exp                      = 0,							--玩家升级经验
            manorPoint               = 0,                           --庄园积分
            challengeLevel           = 0,                           --挑战等级
            gold                     = 0,                           --金币数量 --现在用作积分抽奖积分字段
            -- diamond                  = 0,           --宝石数量(银币)
            headFramList             = {},                          --头像框列表
			lastVipWeekNo            = chessutil.GetMorningWeekNo(),--vip经验上次衰减时间
            rebatechip               = 0,                          --返利金额
            -- rebateflowingchip        = 0,                          --返利流水金额
			aHeadScore               = 0,				--预结算在玩家身上的金币
            slotsWins                = 0,               --slots 赢的钱
            betMoney                 = 0,               --下注金额
            presentChips             = 0,               --赠送金币
			totalbadgechips			 = 0,				--徽章等级总领取金额
			totalredrainchips			 = 0,				--红包雨总领取金额
			totallossrebatechips			 = 0,				--损失返利总领取金额
			totalredeemcodechips			 = 0,				--兑换码总领取金额
			totalvipchips			 = 0,				--VIP总领取金额
			totalactivitychips			 = 0,				--活动总领取金额
			totalluckplayerchips			 = 0,				--幸运玩家总领取金额
			totalvalidinvitechips			 = 0,				--普通返利总领取金额
			totalteamrebatechips			 = 0,				--团队返利总领取金额
			totalturntablechips			 	 = 0,				--普通转盘总领取金额
			totalntaskchips			 	 	 = 0,				--新任务总领取金额
		},
		point = {
			points       = 0,                         --积分
			-- bankerpoints = 0,                   --庄家筹码
			-- giftCoupon   = 0,                     -- 新增 奖券 （货币）
			rechargeSpin = 0,					--充值Spin次数
            controlvalue = 0,                   --点控值
            autocontrolvalue = 0,               --自动点控制值
            autocontroltype  = 0,               --自动点控制类型,0未自动， 1系统自动，  2人工自动
            autocontroltime  = 0,               --自动点控时间
			maxMul = 0,				--最大允许倍数
			maxMulXs= 0 ,			--最大倍数系数
			isMiddleKill = 0,       --用户充值后执行首次下降充值
			chargeMax =0,   --最大金币上限
			WithdrawcashMax = 0, --可提现最大值
			MiddleMul = 0,  --系统系数最大倍数
			pointMaxMul = 0,--充值最大倍数
			rangeControlGames =0, --充值最大杀局数
			killXs = 0,		--杀放系数
			killNum = 0,		-- 杀放次数
			MiddleChageMax = 0,		--点杀触发中间值
			chargeIndex = 0,			--当前充值档次
			isInControl = 0,		--玩家是否处于点控中
			killChargeNum = 0,		--点控期间充值次数
			isChargeHandle = 0,		--是否按照充值用户对待
			killMaxNum  = 0,	 	--最大刀次数
			killcfg = {},			--点杀配置
			killMul = 0,			--当前刀倍数
			killRtp = 0,			--当前刀RTP
			killChargeMax = 0,		--当前刀最大允许上限
			killTakeEffect = 0,--当前生效系数
			cTolxs = 0,			--当前玩家RTP系数
			IsNormal = 0,		--当前玩家是否正常
			IsFirstKill = 0,		--是否已经进行过首杀
			noChargeMax=  0,		--免费用户最高值
			noChargeMin = 0,		--免费用户低值
			FreeControlType = 0,		--免费玩家的控制类型  1放 2 杀
			FreeControlIndex= 1,		--控制循环次数
			newPlayerCount = 0,		--新手玩家当日起落次数
			newPlayerTimeStamp=0,	--新手玩家时间戳
			freeUpOrDownNum = 0,		--起落次数
			upLWorkPrcent = 0,		--拉起万分比
			isCurRechargeUp = 0,		--当前充值是否拉起过
			-- validinViteList = {},							-- 邀请的有效玩家ID列表
            resetPresentFlag = 0,   --重置赠送金币
		},
		-- bank = {
		-- 	chips = 0,
		-- },
		-- max = {
		-- 	maxchips = 5000,
		-- 	maxpoint = 5000,
		-- 	maxGiftCoupon = 0,
		-- },
		-- set = {
		-- 	music = true,
		-- 	sound = true,
		-- 	rank  = nil,
		-- },
		recharge = {
			first = nil,	-- 默认为nil 表示从有首充系统开始 并未充值过 赋值为 首充金额（分）
			isGot = false, 	-- 是否已领取首充奖励
		},
        inviteRewardStatus = {},  --邀请人数奖励领取状态{[1]=1,[2]=0}
		-- mahjong = {}, 			  --麻将房间信息
        gameInfo = {              --进入游戏信息
            intoTime  = 0,        --进入时间
            loginChips = 0,       --进入游戏时金币
            logoutChips  = 0,     --退出游戏时金币
            subGameId    = 0,        --所在游戏id
            subGameType  = 0,        --所在游戏场次
			loginIp   = "", 	  --进游戏ip	
            gameId = 0,        --服务器大区id
            zoneId    = 0,        --区id
        },
        daySign  = {              --签到数据
        },
        gameControl = {           --玩家游戏控制
        },
        offlineReward = {            --待领取奖励
            --[1] = {{goodId=1, goodNum=200}, {goodId=2, goodNum=500}
        },
        flag = {                    --杂项标记
            phoneReward      = 0,       --手机奖励是否有领取
        },
		gameData={
			slotsCount = 0,			--累计slot局数
			slotsBet = 0,			--slots总押注
			slotsWin = 0,			--slots总返现
			hundreBet = 0,		--百人场总押注
			hunderWin = 0,			--百人场总返现
			latestChargeMoney = 0,	--上一笔充值金额
		},
		unsettleInfo={},			--游戏各个模式下的未领取奖励定义
	}
	WUserInfoUpdate(uid, userInfo,true)
    --触发新玩家事件
    UserInfo.NewUserEvent(uid)  
    userInfo = RUserDataGet(uid)
	return userInfo
end


--[[
--获得玩家是否slots中游戏免费，爆池, bonus
--]]
function RUserGameControl(uid, gameId, gameType, opType)
	local userInfo    = RUserInfoGet(uid) 
    local gameControl = userInfo.gameControl or {}
    local ret = 0
    if gameControl[gameId] ~= nil and gameControl[gameId][gameType] ~= nil and gameControl[gameId][gameType][opType]  ~= nil then
        if gameControl[gameId][gameType][opType] == 1 then
            --只中一次
            gameControl[gameId][gameType][opType] = 0
            userInfo.gameControl = gameControl
            SaveUserData(userInfo)
            ret = 1
        else
            ret = 0
        end
    end
    -- unilight.info(string.format("获得玩家:%d, 中奖标志, gameId=%d, gameType=%d, opType=%s, opNum=%d",uid, gameId, gameType, Const.GAME_CONTROL_NAME[opType], ret))
    return ret
end


--[[
-- 设置玩家中奖标志
--]]
function WUserGameControl(uid, gameId, gameType, opType, opNum)
    -- unilight.info(string.format("设置玩家:%d, 中奖标志, gameId=%d, gameType=%d, opType=%d, opNum=%d",uid, gameId, gameType, opType, opNum))

	local userInfo    = RUserInfoGet(uid) 
    local gameControl = userInfo.gameControl or {}
    gameControl[gameId] = gameControl[gameId] or {}
    gameControl[gameId][gameType] = gameControl[gameId][gameType] or {}
    gameControl[gameId][gameType][opType]  = opNum
    userInfo.gameControl = gameControl
    SaveUserData(userInfo)
end

function WUserInfoModity(uid, modifyInfo)
	local userInfo = RUserInfoGet(uid) 
	userInfo.base.headurl = modifyInfo.headUrl or userInfo.base.headurl
	userInfo.base.nickname = modifyInfo.nickName or userInfo.base.nickname
	userInfo.base.gender = modifyInfo.gender or userInfo.base.gender
	userInfo.base.signature = modifyInfo.signature or userInfo.base.signature
	userInfo.base.busermodify = true
	WUserInfoUpdate(uid, userInfo)
	return RUserBaseInfoGet(userInfo)
end

-- 玩家信息更新
function WUserInfoUpdate(uid, data, force)
	if uid == nil then
		return nil
	end
	-- 这里对一些最大值进行赋值
	local userInfo = updateMaxInfo(data)
	unilight.savedata("userinfo", userInfo, force)
end

function updateMaxInfo(data)
	data.max = data.max or {}
	data.max.maxchips = data.max.maxchips or 0
	if data.max.maxchips < data.property.chips then
		data.max.maxchips = data.property.chips
	end
	data.max.maxpoint = data.max.maxpoint or 0
	data.point = data.point or {} 
	data.point.points = data.point.points or 0
	if data.max.maxpoint < data.point.points then
		data.max.maxpoint = data.point.points
	end
	data.max.maxmulti = data.max.maxmulti or 0
	data.max.roundnum = data.max.roundnum or 0

	-- 奖券 老数据不存在该字段 需要初始化
	data.max.maxGiftCoupon = data.max.maxGiftCoupon or 0
	return data
end
--获取玩家总金币
function GetAHeadTolScore(uid)
	local userInfo = unilight.getdata("userinfo", uid)
	local gameId = userInfo.gameInfo.subGameId
	local gameType = userInfo.gameInfo.subGameType
	local key = gameId*100+gameType
	userInfo.property.aHeadScore = userInfo.property.aHeadScore or 0
	-- local aheadscore = userInfo.property.aHeadScore
	local aheadscore =  0
	local allAddMap = {}
	allAddMap[109] = 1
	if table.empty(userInfo.unsettleInfo) == false then
		for k,val in pairs(userInfo.unsettleInfo) do
			if k~=key or allAddMap[gameId]~=nil then
				aheadscore = aheadscore + val
			end
		end
	end
	local tchips = userInfo.property.chips+aheadscore
	-- print('tchips',tchips)
	return tchips
	-- userInfo.property.aHeadScore = userInfo.property.aHeadScore or 0
	-- return userInfo.property.chips+userInfo.property.aHeadScore
end
function AddAheadScore(uid,aheadscore)
	-- print('AddAheadScore',aheadscore)
	local userInfo = unilight.getdata("userinfo", uid)
	userInfo.property.aHeadScore = userInfo.property.aHeadScore or 0
	userInfo.property.aHeadScore = userInfo.property.aHeadScore + aheadscore
	-- if userInfo.property.aHeadScore<0 then
	-- 	userInfo.property.aHeadScore = 0
	-- end
	unilight.update('userinfo',uid,userInfo)
end
--设置玩家的虚拟金币
function SetAheadScore(uid,aheadscore)
	-- print('SetAheadScore',aheadscore)
	local userInfo = unilight.getdata("userinfo", uid)
	userInfo.property.aHeadScore = aheadscore
	unilight.update('userinfo',uid,userInfo)
end


-- 修改金币数量
-- in, opType = 1 表示增加, opType = 2 表示减少
-- out, remander = 表示剩余钱数, ok
function WChipsChange(uid, opType, chips, desc, sourceType)
    chips = math.floor(chips) 
    if type(chips) ~= "number" or chips <= 0 or tostring(chips) == "nan" or tostring(chips) == "inf" then
        unilight.error("金币扣数数据错误: chips="..chips)
        return 0, false
    end
	local userInfo = unilight.getdata("userinfo", uid)
	local property = userInfo.property
	if property == nil then
		unilight.error("WChipsChange()玩家不存在" .. uid)
		return 0, false
	end	
	if userInfo.property.chips < 0 then
		unilight.error("bug err WChipsChange " ..userInfo.property.chips)
		userInfo.property.chips = 0
	end

	local diff = chips
	if opType == 1 then
		property.chips = property.chips + chips 
	else
		if chips <= property.chips then
			property.chips = property.chips - chips 
		else
			return property.chips, false
		end
		diff = -diff
	end
	userInfo.property = property
	WUserInfoUpdate(uid, userInfo)
    local opStr = "获得"
    if opType ~= 1 then
        opStr = "失去"
    end
    if sourceType ~= nil and Const.GOODS_SOURCE_NAME[sourceType] ~= nil then
        desc = Const.GOODS_SOURCE_NAME[sourceType]
    end

    if desc == nil then desc = "未知" end
    unilight.info(string.format("玩家:%d,%s金币:%d, 剩余:%d, 原因:%s", uid, opStr,chips, property.chips, desc ))
	-- 金币流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, Const.GOODS_TYPE.GOLD, property.chips, diff, desc)
	SendRefreshMoneyMsg(uid, Const.GOODS_ID.GOLD, property.chips, opType, chips, sourceType,userInfo.status.experienceStatus)
    -- ChessMonitorMgr.SendUserEconomicConsumeToMonitor(uid,  opType, Const.GOODS_ID.GOLD, chips, sourceType or 0, desc)
	-- 获取兑换模块数据库信息
	-- local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
	-- if withdrawCashInfo.statement > property.chips then
	-- 	withdrawCashInfo.statement = property.chips
	-- 	-- 保存数据库信息
	-- 	unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
	-- end
	return property.chips, true
end

function DemoInitPoint(uid)
    local userInfo = unilight.getdata("userinfo", uid)
	local property = userInfo.property
	if property == nil then
		unilight.error("DemoInitPoint()玩家不存在" .. uid)
		return 0, false
	end	
	property.gold = 100000000
	userInfo.property = property
	WUserInfoUpdate(uid, userInfo)
	SendRefreshMoneyMsg(uid, Const.GOODS_ID.POINT, property.gold, 1, 100000000, Const.GOODS_SOURCE_TYPE.DEMOINIT,userInfo.status.experienceStatus)
end 
-- 修改积分数量
-- in, opType = 1 表示增加, opType = 2 表示减少
-- out, remander = 表示剩余钱数, ok
function WGoldChange(uid, opType, gold, desc, sourceType)
    gold = math.floor(gold) 
    if type(gold) ~= "number" or gold <= 0 or tostring(gold) == "nan" or tostring(gold) == "inf" then
        unilight.error("积分扣数数据错误: gold="..gold)
        return 0, false
    end
	local userInfo = unilight.getdata("userinfo", uid)
	local property = userInfo.property
	if property == nil then
		unilight.error("WGoldChange()玩家不存在" .. uid)
		return 0, false
	end	
	if userInfo.property.gold < 0 then
		unilight.error("bug err WGoldChange " ..userInfo.property.gold)
		userInfo.property.gold = 0
	end

	local diff = gold
	if opType == 1 then
		property.gold = property.gold + gold 
	else
		if gold <= property.gold then
			property.gold = property.gold - gold 
		else
			return property.gold, false
		end
		diff = -diff
	end
	userInfo.property = property
	WUserInfoUpdate(uid, userInfo)
    local opStr = "获得"
    if opType ~= 1 then
        opStr = "失去"
    end
    if sourceType ~= nil and Const.GOODS_SOURCE_NAME[sourceType] ~= nil then
        desc = Const.GOODS_SOURCE_NAME[sourceType]
    end

    if desc == nil then desc = "未知" end
    unilight.info(string.format("玩家:%d,%s积分:%d, 剩余:%d, 原因:%s", uid, opStr,gold, property.gold, desc ))
	SendRefreshMoneyMsg(uid, Const.GOODS_ID.POINT, property.gold, opType, gold, sourceType,userInfo.status.experienceStatus)

	return property.gold, true
end

-- 修改宝石数量
-- in, oPtype = 1 表示增加, oPtype = 2 表示减少
-- out, remander = 表示剩余钱数, ok
function WDiamondChange(uid, opType, diamond, desc)
    if type(diamond) ~= "number" or diamond < 0 or tostring(diamond) == "nan" or tostring(diamond) == "inf" then
        unilight.error("绿钻扣数数据错误: diamond="..diamond)
        return 0, false
    end
	local userInfo = unilight.getdata("userinfo", uid)
	local property = userInfo.property 
	if property == nil then
		unilight.error("WDiamondChange()玩家不存在" .. uid)
		return 0, false
	end	
	if userInfo.property.diamond < 0 then
		unilight.error("bug err WDiamondChange " ..userInfo.property.diamond)
		userInfo.property.diamond = 0
	end

	local diff = diamond
	if opType == 1 then
		property.diamond = property.diamond + diamond 
	else
		if diamond <= property.diamond then
			property.diamond = property.diamond - diamond 
		else
			return property.diamond, false
		end
		diff = -diff
	end
	userInfo.property = property
	WUserInfoUpdate(uid, userInfo)

	-- 金币流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, Const.GOODS_TYPE.DIAMOND, property.diamond, diff, desc)
	SendRefreshMoneyMsg(uid, Const.GOODS_ID.DIAMOND, property.diamond, opType, diamond,userInfo.status.experienceStatus)
	return property.diamond, true
end

-- 修改赠送金币
-- in, oPtype = 1 表示增加, oPtype = 2 表示减少
-- out, remander = 表示剩余钱数, ok
function WPresentChange(uid, opType, presentChips, desc)
    if type(presentChips) ~= "number" or presentChips < 0 or tostring(presentChips) == "nan" or tostring(presentChips) == "inf" then
        unilight.error("赠送扣数数据错误: presentChips="..presentChips)
        return 0, false
    end
	local userInfo = unilight.getdata("userinfo", uid)
	local property = userInfo.property 
	if property == nil then
		unilight.error("WDiamondChange()玩家不存在" .. uid)
		return 0, false
	end	
    if userInfo.property.totalRechargeChips <= 0 then
        unilight.debug(string.format("玩家:%d, 未充值不增加赠送金币", uid))
        return 0, false
    end
	if userInfo.property.presentChips < 0 then
		unilight.error("bug err WPresentChange " ..userInfo.property.presentChips)
		userInfo.property.presentChips = 0
	end

	local diff = presentChips
	if opType == 1 then
        --增加要加上倍数
        local nMul = 1
        for _, pointConfig in ipairs(table_auto_pointLimit) do
            if userInfo.property.totalRechargeChips >= pointConfig.chargeLow1 then
                nMul = pointConfig.visualBetMul
            end
        end
		property.presentChips = property.presentChips + (presentChips * nMul)
	else
		if presentChips <= property.presentChips then
			property.presentChips = property.presentChips - presentChips 
		else
			return property.presentChips, false
		end
		diff = -diff
	end
	userInfo.property = property
	WUserInfoUpdate(uid, userInfo)
    unilight.info(string.format("赠送金币:%d, 总赠送:%d", presentChips, property.presentChips))
    chessrechargemgr.SaveRechargeWithdrawLog(uid, 3, presentChips)
	-- 金币流向 全部记录
	-- ChessItemsHistory.AddItemsHistory(uid, Const.GOODS_TYPE.DIAMOND, property.presentChips, diff, desc)
	-- SendRefreshMoneyMsg(uid, Const.GOODS_ID.DIAMOND, property.presentChips, opType, presentChips)
	return property.presentChips, true
end


-- 修改积分
-- in, type = 1 表示增加, type = 2 表示减少
function WPointsChange(uid, changeType, points)
	if points < 0 then
		points = 0 - points
	end
	local userInfo = unilight.getdata("userinfo", uid)
	local point = userInfo.point
	if changeType == 1 then
		point.points = point.points + points
	else
		point.points = point.points - points
	end
	userInfo.point = point
	WUserInfoUpdate(uid, userInfo)
	return point.points
end

-- 负分清零
function WNegativePointsClear(uid)
	local userInfo = unilight.getdata("userinfo", uid)
	local point = userInfo.point
	if point.points < 0 then
		point.points = 0
	end
	userInfo.point = point
	WUserInfoUpdate(uid, userInfo)
	return point.points
end

-- 修改魅力值
-- in, type = 1 表示增加, type = 2 表示减少
function WCharmsChange(uid, changeType, charms)
	if charms < 0 then
		charms = 0 - charms
	end
	local userInfo = unilight.getdata("userinfo", uid)
	local base = userInfo.base
	if changeType == 1 then
		base.charm = base.charm + charms
	else
		base.charm = base.charm - charms
	end
	userInfo.base = base
	WUserInfoUpdate(uid, userInfo)
	return base.charm
end

-- 修改奖券
-- in, type = 1 表示增加, type = 2 表示减少
function WGiftCouponsChange(uid, type, giftCoupons)
	if giftCoupons < 0 then
		giftCoupons = 0 - giftCoupons
	end
	local userInfo = unilight.getdata("userinfo", uid)
	local property = userInfo.property 
	if property == nil then
		unilight.error("WGiftCouponsChange()玩家不存在" .. uid)
		return nil
	end	
	if type == 1 then
		property.giftCoupon = property.giftCoupon + giftCoupons 
	else
		if giftCoupons <= property.giftCoupon then
			property.giftCoupon = property.giftCoupon - giftCoupons 
		else
			return property.giftCoupon, false
		end
	end
	userInfo.property = property
	WUserInfoUpdate(uid, userInfo)
	return property.giftCoupon, true
end

-- 修改麻将钻石（前提是必须存在该麻将信息）
-- in, type = 1 表示增加, type = 2 表示减少
function WMahjongDiamondChange(uid, type, num, desc)
	if num < 0 then
		num = 0 - num
	end
	local userInfo = unilight.getdata("userinfo", uid)
	local mahjong = userInfo.mahjong 
	if mahjong == nil then
		unilight.error("WMahjongDiamondChange()玩家不存在" .. uid)
		return 
	end	
	if mahjong.diamond < 0 then
		unilight.error("bug err WMahjongDiamondChange " ..mahjong.diamond)
		mahjong.diamond = 0
	end

	local diff = num
	if type == 1 then
		mahjong.diamond = mahjong.diamond + num 
	else
		if num <= mahjong.diamond then
			mahjong.diamond = mahjong.diamond - num
		else
			return mahjong.diamond, false
		end
		diff = -diff
	end

	userInfo.mahjong = mahjong
	WUserInfoUpdate(uid, userInfo)

	-- 钻石流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, 2, mahjong.diamond, diff, desc)

	return mahjong.diamond, true
end

-- 修改麻将房卡（前提是必须存在该麻将信息）
-- in, type = 1 表示增加, type = 2 表示减少
function WMahjongCardChange(uid, type, num, desc)
	if num < 0 then
		num = 0 - num
	end
	local userInfo = unilight.getdata("userinfo", uid)
	local mahjong = userInfo.mahjong 
	if mahjong == nil then
		unilight.error("WMahjongCardChange()玩家不存在" .. uid)
		return 
	end	
	if mahjong.card < 0 then
		unilight.error("bug err WMahjongCardChange " ..mahjong.card)
		mahjong.card = 0
	end
	local diff = num
	if type == 1 then
		mahjong.card = mahjong.card + num 
	else
		if num <= mahjong.card then
			mahjong.card = mahjong.card - num 
		else
			return mahjong.card, false
		end
		diff = -diff
	end
	userInfo.mahjong = mahjong
	WUserInfoUpdate(uid, userInfo)

	-- 房卡流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, 3, mahjong.card, diff, desc)

	return mahjong.card, true
end

-- 修改银行存款（用于直接消耗银行存款 -- 暂时只有送礼）
-- in, type = 1 表示增加, type = 2 表示减少
function WBankChipsChange(uid, type, bankChips)
	if bankChips < 0 then
		bankChips = 0 - bankChips
	end
	local userInfo = unilight.getdata("userinfo", uid)
	local bank = userInfo.bank 
	if bank == nil then
		unilight.error("WbankChipsChange()玩家不存在" .. uid)
		return nil
	end	
	if type == 1 then
		bank.chips = bank.chips + bankChips 
	else
		if bankChips <= bank.chips then
			bank.chips = bank.chips - bankChips 
		else
			return bank.chips, false
		end
	end
	userInfo.bank = bank
	WUserInfoUpdate(uid, userInfo)
	return bank.chips, true
end

-- 充值数据库入口
function WChipsRecharge(uid, chips)
	local userInfo = unilight.getdata("userinfo", uid)
	if userInfo == nil then
		unilight.error("玩家不存在" .. uid)
		return nil
	end	
	userInfo.property.chips = userInfo.property.chips + chips
	WUserInfoUpdate(uid, userInfo)

	-- 金币流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, 1, userInfo.property.chips, chips, "充值")

	return userInfo.property.chips
end
--[[
	获取充值信息
	充值金额,充值次数
]]
function GetChargeInfo(uid)
	local userinfo = unilight.getdata('userinfo',uid)
	local totalRechargeChips = userinfo.property.totalRechargeChips
	local rechargeNum = userinfo.status.rechargeNum
	return totalRechargeChips,rechargeNum
end
-- 兑换出去金币减少入口
function WChipsRedeemBack(uid, chips)
	local userInfo = unilight.getdata("userinfo", uid)
	if userInfo == nil then
		unilight.error("玩家不存在" .. uid)
		return nil
	end	
	userInfo.property.chips = userInfo.property.chips - chips
	if userInfo.property.chips < 0 then
		unilight.error("bug err WChipsRedeemBack" .. chips .. "   " .. userInfo.property.chips)
		userInfo.property.chips = 0
	end
	WUserInfoUpdate(uid, userInfo)

	-- 金币流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, 1, userInfo.property.chips, -chips, "金币兑出")

	return userInfo.property.chips
end

-- GM设定金币数
function WChipsSet(uid, chips)
	local userInfo = unilight.getdata("userinfo", uid)
	if userInfo == nil then
		unilight.error("玩家不存在" .. uid)
		return nil
	end	
	userInfo.property.chips = chips
	WUserInfoUpdate(uid, userInfo)

	SendRefreshMoneyMsg(uid, Const.GOODS_ID.GOLD, userInfo.property.chips, 1, chips, Const.GOODS_SOURCE_TYPE.GM_COMMAND,userInfo.status.experienceStatus)
	return userInfo.property.chips
end

-- GM设定金币数
function WDiamondSet(uid, chips)
	local userInfo = unilight.getdata("userinfo", uid)
	if userInfo == nil then
		unilight.error("玩家不存在" .. uid)
		return nil
	end	
	userInfo.property.diamond = chips
	WUserInfoUpdate(uid, userInfo)

	SendRefreshMoneyMsg(uid, Const.GOODS_ID.DIAMOND, userInfo.property.diamond, 1, chips, Const.GOODS_SOURCE_TYPE.GM_COMMAND,userInfo.status.experienceStatus)
	return userInfo.property.chips
end

-- GM设定麻将钻石
function WMahjongDiamondSet(uid, mahjongDiamond)
	local userInfo = unilight.getdata("userinfo", uid)
	if userInfo == nil or userInfo.mahjong == nil then
		unilight.error("玩家不存在" .. uid)
		return nil
	end	
	userInfo.mahjong.diamond = mahjongDiamond
	WUserInfoUpdate(uid, userInfo)
	return userInfo.mahjong.diamond
end

-- GM设定麻将房卡
function WMahjongCardSet(uid, mahjongCard)
	local userInfo = unilight.getdata("userinfo", uid)
	if userInfo == nil or userInfo.mahjong == nil then
		unilight.error("玩家不存在" .. uid)
		return nil
	end	
	userInfo.mahjong.card = mahjongCard
	WUserInfoUpdate(uid, userInfo)
	return userInfo.mahjong.card
end


function UserChipsExchange(srcUid, dstUid, chips)
	local srcUser = unilight.getdata("userinfo", srcUid)
	local dstUser = unilight.getdata("userinfo", dstUid)
	if srcUser == nil or dstUser == nil then
		return false
	end	

	if srcUser.property.chips < chips then
		return false
	end	

	srcUser.property.chips = serUser.property.chips - chips
	dstUser.property.chips = dstUser.property.chips + chips
	WUserInfoUpdate(srcUid, srcUser)
	WUserInfoUpdate(dstUid, dstUser)

	return srcUser.property.chips
end

-- 将指定玩家金币移入庄家金币库存
function WMoveChipsToBankerChips(uid, bankerChips)
	local userInfo = unilight.getdata("userinfo", uid)
	if table.empty(userInfo) or IsRobot(uid) then
		unilight.error("玩家不存在" .. uid)
		return false
	end 
	if userInfo.property.chips < bankerChips or bankerChips < 1 then
		return false
	end 
	userInfo.property.chips = userInfo.property.chips - bankerChips
	WUserInfoUpdate(uid, userInfo)

	-- 金币流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, 1, userInfo.property.chips, -bankerChips, "上庄")

	return true, userInfo.property.chips, userInfo
end

-- 将指定玩家庄家金币移入金币库存
function WMoveBankerChipsToChips(uid)
	-- body
	local userInfo = unilight.getdata("userinfo", uid)
	if table.empty(userInfo) or IsRobot(uid) then
		unilight.error("玩家不存在" .. uid)
		return false
	end 
	userInfo.property.chips = userInfo.property.chips

	-- 金币流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, 1, userInfo.property.chips, userInfo.property.chips, "下庄")

	WUserInfoUpdate(uid, userInfo)

	-- 金币流向 全部记录

	return true, userInfo.property.chips, 0, userInfo
end

function WUpdateBankerChips(uid, oriBankerChips, addProfit)
	-- body
	local userInfo = unilight.getdata("userinfo", uid)
	if table.empty(userInfo) then
		unilight.error("玩家不存在" .. uid)
		return false
	end 
	WUserInfoUpdate(uid, userInfo)
	return true, userInfo.property.chips, userInfo                                                                                                                                                                                                       
end

---------------------------------------------------------------------------------------------------------------------
--银行与携带互转
function WBankchipsExChange(uid, chips, exchangeType)
	local userInfo = unilight.getdata("userinfo", uid)
	if table.empty(userInfo) then
		unilight.error("玩家不存在" .. uid)
		return false
	end
	local bank = userInfo.bank.chips
	local remainder = userInfo.property.chips
	local diff = chips
	if exchangeType == 0 then
		-- 银行转入携带
		if bank < chips then
			return false
		end
		userInfo.property.chips = remainder + chips
		userInfo.bank.chips = bank - chips
	else	
		-- 携带转入银行 
		if remainder < chips then
			return false
		end
		userInfo.property.chips = remainder - chips
		userInfo.bank.chips = bank + chips
		diff = -diff
	end
	bank = userInfo.bank.chips
	remander = userInfo.property.chips
	WUserInfoUpdate(uid, userInfo)

	-- 金币流向 全部记录
	ChessItemsHistory.AddItemsHistory(uid, 1, userInfo.property.chips, diff, "保险箱存取")	

	return true, remander, bank
end

---------------------------------------------------------------------------------------------------------------------
--排行榜
-- getgoldrank 
function RChipsRankGet(num)
	chipsRank = chipsRank or {}
	chipsRank.updateTime = chipsRank.updateTime or 0
	local distance = os.time() - chipsRank.updateTime
	if distance < 60 * 60 then
	   return chipsRank.rank
	end
	unilight.debug("查询整体排行榜")	
	nbr = 20 
	local orderby = unilight.desc("property.chips")
	local usrgroup = unilight.topdata("userinfo", nbr, orderby, nil)
	if table.empty(usrgroup) then 
		return nil
	end
	local res = {}
	for i, v in ipairs(usrgroup) do
		res[i] = {
			nickName = v.base.nickname,
			chips = v.property.chips,
			rank = i,
			uid  = v.uid,
		}
	end
	chipsRank.rank = res
	chipsRank.updateTime = os.time()
	return res
end

-- getrgoldrank by uid
function RUserChipsRankGet(uid)	
	userChipsRank = userChipsRank or {}
	userChipsRank[uid] = userChipsRank[uid] or {}
	userChipsRank[uid].updateTime = userChipsRank[uid].updateTime or 0
	local distance = os.time() - userChipsRank[uid].updateTime 
	if distance < 60 * 60 then
		return userChipsRank[uid].index
	end

	local orderby = unilight.desc("property.chips")
	local index =  unilight.getindex("userinfo", "uid", uid, orderby)
	index = index + 1
	userChipsRank[uid].updateTime = os.time()
	userChipsRank[uid].index = index
	return index
end

--更新货币后通知客户端
function SendRefreshMoneyMsg(uid, moneyType, moneyNum, opType, opNum, sourceType,experienceStatus)
    local send = {}
    send["do"] = "Cmd.RefreshMoneyLobbyCmd_S"
    send["data"] = {
        moneyType  = moneyType,
        moneyNum = moneyNum,
        opType   = opType, 
        opNum    = opNum,
        sourceType = sourceType, 
        experienceStatus = experienceStatus, 
    }
    local laccount = go.roomusermgr.GetRoomUserById(uid)
    unilight.success(laccount, send)
end

--获得金币加成
--chipsBase: 金币基础值
function GetChipsAddition(uid, chipsBase)
    -- local vipAdd = vipCoefficientMgr.GoldCoefficientForVip(uid)
    -- local levelAdd = levelmgr.GetXs(uid)
    -- local totalChips = math.floor(chipsBase * vipAdd * levelAdd)
    -- return totalChips
    return chipsBase
end

--玩家退出登陆
function UserLogout(uid)
    UserInfo.Logout(uid)
	local userInfo = RUserInfoGet(uid)
    userInfo.status.logoutTime = os.time()
    unilight.savedata("userinfo", userInfo, true)
    unilight.info("玩家下线:"..uid..", chips="..userInfo.property.chips)
end

---------------------------------------------------------------------------------------------------------------------
-- 加个判断是否为机器人的接口
function IsRobot(uid)
	local begin = TableRobotUserInfo[1].uid
	local ended = begin + #TableRobotUserInfo - 1
	if uid >= begin and uid <= ended then
		return true
	else
		return false
	end
end


---------------------------------------------------------------------------------------------------------------------
-- http 请求替换headurl
function RequstChangeHeadUrl(uid, headUrl)
	local req = {}
	req["do"] = "ChangeHeadurl_C"
	req["data"] = {
		uid 		= uid,
		srcImage	= headUrl
	}
	local url = go.getconfigstr("image_server")
	if url ~= nil then
		unilight.HttpRequestPost("ReturnChangeHeadUrl", url, req)
	else
		unilight.error("更新头像失败 image_server url为nil")
	end
end

Http.ReturnChangeHeadUrl = function (cmd,laccount)
	if cmd.data ~= nil and cmd.data.resultCode == 0 and cmd.data.dstImage ~= nil then
		local uid = cmd.data.uid
		local userData = unilight.getdata("userinfo", uid)
		if userData == nil then
			unilight.error("当前玩家不存在 修改headUrl失败：" .. uid)
			return 
		end	
		userData.base.oldheadurl 	= userData.base.headurl -- 老头像 非本服务器的headurl保留起来
		userData.base.headurl 		= cmd.data.dstImage
		WUserInfoUpdate(uid, userData)

		local laccount = go.accountmgr.GetAccountById(uid)
		if laccount ~= nil then
			-- 替换头像成功后 重新给前端刷新一下头像数据
			local userBaseInfo = chessuserinfodb.RUserBaseInfoGet(userData)	
			local brdInfo = {}
			brdInfo["do"] = "Cmd.UserBaseInfoReturnLbyCmd_S"
			brdInfo["data"] = {
				resultCode 	= 0,
				desc 		= "ok",
				uid 		= uid,
				userInfo 	= userBaseInfo,
			}
			unilight.success(laccount, brdInfo)
			unilight.info("新玩家头像存储到本地服务器后 返回最新头像数据 headUrl:" .. userBaseInfo.headUrl)
		end
	end
end

Http.ReturnGpsAdid = function (cmd,laccount)
    unilight.info("http返回玩家gpsadid:" .. table2json(cmd))
	if cmd.gps_adid ~= "" and cmd.uid ~= "" then
        local uid = tonumber(cmd.uid)
        local userInfo = RUserInfoGet(uid)
        if userInfo ~= nil then
            userInfo.base.gpsAdid = cmd.gps_adid
            WUserInfoUpdate(uid, userInfo)
            --再次更新下玩家登陆信息
            ChessMonitorMgr.SendUserLoginToMonitor(uid)
        end
    end
end
---------------------------------------------------------------------------------------------------------------------
--获得唯一邀请码
function GetInviteCode()
    local inviteCode = chessutil.GetRandomStr(10)
    while true do
        local inviteInfo = unilight.getdata("globalinvitecode", inviteCode)
        if table.empty(inviteInfo) then
            inviteInfo = {
                _id = inviteCode,
            }
            unilight.savedata("globalinvitecode", inviteInfo)
            return inviteCode
        end
        inviteCode = chessutil.GetRandomStr(10)
    end
end

--获得下级人总数
function GetBelowNum(uid)
    local nNum = unilight.startChain().Table("rebateItem").Filter(unilight.eq("uid",uid)).Count()
    return nNum
end


--获得推广总收入
function GetPromotionChips(uid)
    local suminfo = unilight.chainResponseSequence(unilight.startChain().Table("rebateItem").Aggregate('{"$match":{"uid":{"$eq":' .. uid .. '}}}','{"$group":{"_id":null, "sum":{"$sum":"$chip"}}}'))
    local childpromotemoney = 0
    if table.len(suminfo)  > 0  then
        childpromotemoney = suminfo[1].sum
    end
    return childpromotemoney
end


--获得推广提现金额
function GetPromotionWithdrawMoney(uid)
    local suminfo = unilight.chainResponseSequence(unilight.startChain().Table("rebateItem").Aggregate('{"$match":{"uid":{"$eq":' .. uid .. '}}}','{"$group":{"_id":null, "sum":{"$sum":"$chip"}}}'))
    local childpromotemoney = 0
    if table.len(suminfo)  > 0  then
        childpromotemoney = suminfo[1].sum
    end
    return childpromotemoney
end

--查找上级id
function GetParentUid(uid)
    local parentcharid = 0
    local filter = unilight.eq("childId", uid)
	filter = unilight.a(filter,unilight.eq("lev",1))
    local infos = unilight.chainResponseSequence(unilight.startChain().Table("rebateItem").Filter(filter))
    if table.len(infos) > 0 then
        parentcharid = infos[1].uid
    end
    return parentcharid
end

--根据推广码查找上级uid
function GetParentUidByInvite(inviteCode)
    local parentUid = 0
    if inviteCode == "" then
        return parentUid
    end
    local filter = unilight.eq("base.inviteCode", inviteCode)
    local infos = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Filter(filter))
    if table.len(infos) > 0 then
        parentUid = infos[1].uid
    end

    return parentUid
end

--获得推广未提现的金额
function GetRebateChips(uid)
    local chips = 0
    local data = unilight.getdata("extension_relation",uid)
    if table.empty(data) == false then
        chips = data.rebatechip or 0
    end

    return chips
end




---王海军添加,希望升级成所有跟db相关的操作都叫Data而不叫Info
RUserBaseDataGet = RUserBaseInfoGet
RUserDataGet = RUserInfoGet
RUserPlatDataGet = RUserPlatInfoGet
WUserDataModity = WUserInfoModity
WUserDataUpdate = WUserInfoUpdate
updateMaxData = updateMaxInfo

GetUserDataBaseInfo = RUserBaseDataGet
CreateUserData = WUserConstuct
GetUserDataById = RUserInfoGet
GetLoginUserDataById = RUserLoginGet
SaveUserDataById = WUserInfoUpdate
GetUserPlatDataById = RUserPlatInfoGet
SaveUserBaseData = WUserInfoModity
UpdateMaxData = updateMaxInfo
function SaveUserData(userdata)
	SaveUserDataById(userdata.uid,userdata)
end
