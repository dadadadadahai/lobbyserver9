module('UserInfo', package.seeall) -- 用户信息
local table_collect_type = import("table/table_collect_type")
local table_withdraw_plat = import "table/table_withdraw_plat"
local table_shop_config = import "table/table_shop_config"
local table_shop_first = import "table/table_shop_first"
local table_shop_discounts = import "table/table_shop_discounts"
local table_parameter_formula = import "table/table_parameter_formula"
local tableMailConfig = import "table/table_mail_config"

table_parameter_parameter= import "table/table_parameter_parameter"
BIND_CHIPS = table_parameter_parameter[10].Parameter        --绑定手机奖励

-- action: 大厅登陆时 检测当前的chips是否是捕鱼的分 如果是 则需要通过rate折算
function CheckRechargeScoreToCoin(userdata)
	if userdata.fish ~= nil then
		if userdata.fish.recharge ~= nil and userdata.fish.recharge.roomtype ~= nil then
			-- 先把分 兑成币 汇总到coin
			if userdata.property.chips ~= 0 then 
				local rate 		= userdata.fish.recharge.rate
				-- 从3a、荣强大厅进去的 默认都是金币
				userdata.fish.goldroom.coin = userdata.fish.goldroom.coin + math.floor(userdata.property.chips/rate)
				userdata.property.chips = 0
			end
			userdata.fish.recharge.roomtype = nil 
			userdata.fish.recharge.rate = nil 
		end
		if userdata.fish.goldroom.coin ~= 0 then
			-- 再把coin 转到 chips 中
			userdata.property.chips = userdata.fish.goldroom.coin
			userdata.fish.goldroom.coin = 0
			
			-- 存档
			chessuserinfodb.SaveUserData(userdata)
		end
	end
end

--玩家登陆事件
function UserLogin(uid)
    --推送收集列表
    --CollectMgr.GetCollectList(uid, 0)
    --历史期数数据
    -- CollectMgr.GetHistoryMissItem(uid)
	--vip经验衰减
	-- vipCoefficientMgr.DampingVipExpForVLight(uid)
    --检测过期邮件
    MailMgr.CheckOverTimeMail(uid)
    --检测是否有新邮件
    MailMgr.UpdateUserMail(uid)
	--登陆下发热门游戏 
	--hallMgr.GetHallQuckGames(uid)
    --商城首充特惠信息
    --ShopMgr.SendDisCountInfoToMe(uid)
    --VIP登陆结算判断
    -- nvipmgr.UserLoginVipSettle(uid)
    --商城限时特惠计算(暂时不需要此功能)
    -- ShopMgr.CalcLimitDiscountInfo(uid)
    --检测玩家是否有金币赠送
    chessrechargemgr.userLoginCheckOrder(uid)
    --检测是否领取过手机绑定奖励
    local userInfo = chessuserinfodb.RUserDataGet(uid)
    -- 判断电话号码表是否有信息
    unilight.delete(InviteRoulette.DB_PhoneNumber_Name,tonumber(userInfo.base.plataccount))

	local laccount = go.accountmgr.GetAccountById(uid)
	if laccount ~= nil then
        print(laccount.JsMessage.GetMobilenum())
    end

    if userInfo.flag ~= nil and userInfo.flag.phoneReward == 0 and userInfo.base.phoneNbr ~= "" then
        userInfo.flag.phoneReward = 1
        AddOfflineReward(uid, Const.GOODS_SOURCE_TYPE.BIND_PHONE, Const.GOODS_ID.GOLD, BIND_CHIPS)
        chessuserinfodb.SaveUserData(userInfo)
        chessuserinfodb.WPresentChange(uid, Const.PACK_OP_TYPE.ADD, BIND_CHIPS, "绑定赠送金币")
    end

    --数据统计
    ChessMonitorMgr.SendUserLoginToMonitor(uid)
    --特惠返利邮件检查
    ShopMgr.CheckDiscountReward(uid)
    -- 增加上级邀请转盘奖励
    InviteRoulette.AddWithdrawCashNum(uid)
    -- 任务转盘登陆任务进度
    TaskTurnTable.AddLoginTask(uid)
    --检查是否需要重新绑定上下级
    if userInfo.status.bindFailFlag ~= nil and userInfo.status.bindFailFlag == 1 then
        ReqBindInvite(uid)
    end
end


--用户登陆大厅
function UserLoginLobby(uid)
    --推送到其它服
    if RoomInfo ~= nil and RoomInfo.BroadcastToAllZone ~= nil then
        RoomInfo.BroadcastToAllZone("Cmd.KickUserGame_S", {uid=uid, desc="重新登陆踢出在线玩家"})
    end

    -- local inviteNum = rebate.GetViteNum(uid)
    -- if inviteNum > 0 then
    --     --增加任务进度
    --     OtherTaskMgr.AddTaskNum(uid, OtherTaskMgr.TASK_TYPE.INVITE, inviteNum)
    -- end

    OtherTaskMgr.GetTaskListInfo(uid)
    -- ShopMgr.CleanHistoryInfo(uid)
end

--在线玩家玩家1秒钟定时器
function Loop(uid)


end

--在线玩家1分钟定时器
function OneMin(uid)
	-- SystemCoupon.TimeCoupon(uid)
end

--在线玩家10秒钟定时器
function TenSec(uid)
    --推送游戏奖池
end


--5秒钟定时器
function FiveSec(uid)
    local userInfo = chessuserinfodb.RUserDataGet(uid)
    BuffMgr.CheckRemove(userInfo)
	local userBackpack = BackpackMgr.CmdBackpackListGetByUid(uid)
    BackpackMgr.CheckTimeAndRemove(userBackpack, true)
end

--零晨4点回调,做一些主动推消息
function FourHour(uid)


end

--[[
--玩家充值前处理
    orderInfo
    {
    _id; #订单ID
    uid  #玩家id 
    subTime #订单提交时间
    shopId #商品id
    subPrice #提交金额
    fee #fee手续费
    backTime #回调时间
    backPrice #回调金额
    payType #支付方式
    order_no #支付平台,订单id
    status #订单状态, #订单状态 0 已提交 1 已支付， 2，已发放
    }
]]
function UserRecharge(uid, shopId, orderInfo)
	-- nvipmgr.ChangeVipCallBack(uid,shopId,orderInfo.backPrice)
    --保存下总充值金币
    local userInfo = chessuserinfodb.RUserDataGet(uid)
    -- 首充赠送金币
    local firstPayChips = 0
    -- 如果是首充需要调用
    if userInfo.property.totalRechargeChips == 0 then
        -- 首充玩家累计下注清零
        userInfo.gameData.slotsBet = 0
        -- -- 首充随机增加流水
        -- WithdrawCash.AddRandomStatement(uid)
        -- --首充计算任务总金币
        -- OtherTaskMgr.CalcOtherTaskChips(uid, userInfo.property.chips)
        -- --首充清空身上携带金币,转换成任务金币
        -- userInfo.property.chips = 0

        -- --首充如果有上级增加下任务进度
        -- local parentUid = chessuserinfodb.GetParentUidByInvite(userInfo.base.inviter)
        -- if parentUid > 0 then
        --     --增加任务进度
        --     OtherTaskMgr.AddTaskNum(parentUid, OtherTaskMgr.TASK_TYPE.INVITE, nil, 1)
        -- end
        -- 首充删除这个玩家的游戏进度信息 防止刷钱
        gamecommon.DelGameInfo(uid)
    end
    
    if userInfo.status.isFirstGift == 0 and orderInfo.backPrice < 3000 then
        firstPayChips = table_shop_first[1].chips
        userInfo.status.isFirstGift = 1
    end
    if orderInfo.backPrice > userInfo.status.maxRechargeChips then
        userInfo.status.maxRechargeChips = orderInfo.backPrice
    end
    userInfo.property.totalRechargeChips = userInfo.property.totalRechargeChips + orderInfo.backPrice
    userInfo.status.rechargeNum = userInfo.status.rechargeNum + 1
    if userInfo.status.firstPayTime == 0 then
        userInfo.status.firstPayTime =  os.time() 
        userInfo.status.firstPayChip =  orderInfo.backPrice
    end
    unilight.savedata('userinfo',userInfo)
    local shopConfig = table_shop_config[shopId] 
    if shopConfig ~= nil then
        --查找充值金额
        -- v.shopGoods[1].goodNum
        chessrechargemgr.SaveRechargeWithdrawLog(orderInfo.uid, 1, shopConfig.price)
    end
    chessuserinfodb.WUserInfoUpdate(uid, userInfo)
    --通知系数重随
    gamecommon.RechageRtpRandom(uid,shopId,orderInfo.backPrice)
    --通知后台
    ChessMonitorMgr.SendUserRechargeToMonitor(uid, orderInfo)
    if shopConfig ~= nil and shopConfig.VisualPrice > 0 then
        chessuserinfodb.WPresentChange(uid, Const.PACK_OP_TYPE.ADD, shopConfig.VisualPrice, "充值赠送金币")
    end
    --统计复充数据
    chessrechargemgr.SaveDayRechargeLog(uid)
    --增加订单最大充值
    chessrechargemgr.UpdateOrderDayRecharge(uid, userInfo)

    --增加任务进度
    OtherTaskMgr.AddTaskNum(uid, OtherTaskMgr.TASK_TYPE.RECHARGE, 1)
    -- 充值判断有效玩家
    rebate.IsValidinVite(uid)
    -- 增加任务进度
    TaskTurnTable.AddRechargeTask(uid,orderInfo.backPrice)
    nTask.TaskInit(uid,orderInfo.backPrice)
    -- 重置玩家状态
    ChangeUserExperienceStatus(uid)
    -- 添加返利金额
    rebate.RechargeVite(uid,orderInfo.backPrice)
    LossRebate.AddTodayRechargeNum(uid,orderInfo.backPrice)
    CumulativeRecharge.AddTaskNum(uid,orderInfo.backPrice)
    -- 满足显示需求需要统计额外赠送金币在订单返回中增加
    local addChips = 0
    -- 添加提现打马金额
    if orderInfo.shopId == 801 then
        -- 额外赠送金币
        if firstPayChips > 0 then
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD,firstPayChips, Const.GOODS_SOURCE_TYPE.SHOPGIFT)
            addChips = addChips + firstPayChips
            -- 发送邮件
            local mailInfo = {}
            local mailConfig = tableMailConfig[36]
            mailInfo.charid = uid
            mailInfo.subject = mailConfig.subject
            mailInfo.content = string.format(mailConfig.content,firstPayChips/100)
            print("===========================================")
            print(firstPayChips/100)
            print(string.format(mailConfig.content,firstPayChips/100))
            mailInfo.type = 0
            mailInfo.attachment = {}
            mailInfo.extData = {}
            ChessGmMailMgr.AddGlobalMail(mailInfo)
        end
        -- 一倍打马
        WithdrawCash.AddBet(uid, orderInfo.backPrice + firstPayChips)
    elseif orderInfo.shopId == 802 then
        for _, shopinfo in ipairs(table_shop_discounts) do
            if orderInfo.backPrice >= shopinfo.min and orderInfo.backPrice <= shopinfo.max then
                -- 额外赠送金币
                BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, shopinfo.giftChips + firstPayChips, Const.GOODS_SOURCE_TYPE.SHOPGIFT)
                addChips = addChips + shopinfo.giftChips + firstPayChips
                if firstPayChips > 0 then
                    -- 发送邮件
                    local mailInfo = {}
                    local mailConfig = tableMailConfig[36]
                    mailInfo.charid = uid
                    mailInfo.subject = mailConfig.subject
                    mailInfo.content = string.format(mailConfig.content,firstPayChips/100)
                    mailInfo.type = 0
                    mailInfo.attachment = {}
                    mailInfo.extData = {}
                    ChessGmMailMgr.AddGlobalMail(mailInfo)
                end
                WithdrawCash.AddBet(uid, ((orderInfo.backPrice+ firstPayChips) * shopinfo.mul ))
            end
        end
    end
    return addChips
end

--玩家充值后处理
function UserRechargeEnd(uid, shopId, orderInfo)
    -- local userInfo = chessuserinfodb.RUserDataGet(uid)

    -- --累计充值大于30,赠送金币改为当前携带金币减30,只执行一次
    -- if userInfo.point.resetPresentFlag == 0 and userInfo.property.totalRechargeChips > 3000 then
    --     userInfo.point.resetPresentFlag = 1
    --     local presentChips = userInfo.property.chips - (userInfo.property.totalRechargeChips - 3000) 
    --     if presentChips < 0 then presentChips = 0 end
    --     unilight.info(string.format("玩家:%d, 充值大于30, 重置赠送金币为:%d", uid, presentChips))
    --     userInfo.property.presentChips = presentChips
    -- end
    -- chessuserinfodb.SaveUserData(userInfo)

end

--玩家提现成功
--[[
local orderInfo = {
    _id = WithdrawCash.CreateOrderId(),
    uid = uid,                                                          -- 玩家ID
    orderType = orderType,                                              -- 订单类型     1 兑换提现  2 推广提现
    name = withdrawCashInfo.name,                                       -- 玩家姓名
    cpf = withdrawCashInfo.cpf,                                         -- CPF
    chavePix = withdrawCashInfo.chavePix,                               -- chavePix
    chavePixNum = withdrawCashInfo.flag,                                -- chavePix类型  0 只有姓名和CPF 1 额外增加一个Phone 2 额外增加一个Email
    moedas = moedas,                                                    -- 消耗金币
    dinheiro = dinheiro,                                                -- 提现金额
    times = chessutil.FormatDateGet(),                                  -- 订单申请时间(直接返回date格式日期 弃用)
    timestamp = os.time(),                                              -- 订单申请时间(时间戳)
    finishTimes = 0,                                                    -- 订单结束时间(时间戳)
    state = STATE_WAIT_REVIEW,                                          -- 订单当前状态 1.待审核， 2.已拒绝 3.兑换成功, 4.兑换失败, 5.审核中, 6.订单完成, 7.订单失败已返回奖励
    orderId = "",                                                       -- 平台订单号
    channel = "",                                                       -- 通道名
    regFlag = userInfo.base.regFlag ,                                   -- 注册来源
    subplatid = userInfo.base.subplatid,                                -- 子渠道id
    payPlatId = 0,                                                      -- 提现渠道id
    totalWithdrawal = 0,                                                -- 当日总充值
}
]]
function UserWithdrawSucces(uid, orderInfo)

    --增加提现订单最大充值
    local userInfo = chessuserinfodb.RUserDataGet(uid)
    chessrechargemgr.UpdateWithdrawOrderDayRecharge(uid, userInfo)

    --增加任务进度
    OtherTaskMgr.AddTaskNum(uid, OtherTaskMgr.TASK_TYPE.WITHDRAW, 1)
end


--玩家获得道具事件
function AddItemEvent(uid, goodId, goodNum)
	if goodId==10043 then
		--宾果球
		bingomgr.BingoAddBasket(goodNum,uid)
	elseif goodId==10017 then
		--烹饪食材币
		cookingmgr.CookingAddWanNeng(goodNum,uid)
	end
    --内购检查保险袋buff
	SlotIapMgr.CheckUseBuffItem(uid, goodId)
end

--玩家删除道具事件
function DeleteItemEvent(uid, goodId, goodNum)

end


--玩家获得buff事件
function AddBuffEvent(uid, buffId)
    --内购获得特定buff后要更新结束时间
    SlotIapMgr.UpdateBuffEndTime(uid, buffId)
	if buffId==1233 then
		bingomgr.BingoAddBuff3(25,uid)
	end

end


--玩家删除buff事件(调用此接口后buff再删除)
function RemoveBuffEvent(uid, buffId, buffInfo)

    --内购检查使用道具
	SlotIapMgr.CheckBuffOverUseItem(uid, buffId, buffInfo)
end


--获得一个收集物事件
function AddCollectEvent(uid, goodId)
    --团队任务添加收集事件
    teammgr.TeamGetCollectTask(uid, 1)
end

--收集奖励事件
function CollectRewardEvent(uid, collectType, gold)
    --团队收集完成一个组事件
    if collectType ~= 0 then
        local collectName = table_collect_type[collectType].name
        teammgr.TeamInteractGold(uid, gold, Const.TEAM_INTERACT_TYPE.COLLECTION, collectName)
    end
end

--玩家退出游戏
function Logout(uid)
    --通知游戏玩家退出游戏
    if go.gamezone.Gameid == Const.GAME_TYPE.SLOTS then
        gamecommon.UserLogoutGame(uid)
    end

    --数据统计
    ChessMonitorMgr.SendUserLogoutToMonitor(uid)
end

--邀请绑定返回
Http.InviteBindCallback = function (cmd, params)
	unilight.info("receive http res=" .. table.tostring(cmd), "params="..params)
    params = json2table(params)
    local userInfo = chessuserinfodb.RUserDataGet(params.uid)
    --不成功的话，记录下玩家绑定信息下次登陆继续绑定
    if cmd.errno == 1 then
        userInfo.status.bindFailFlag =1 
        chessuserinfodb.SaveUserData(userInfo)
        unilight.info(string.format("玩家:%d, 未绑定成功，保存标记", params.uid))
    elseif cmd.errno == 0 then
        userInfo.status.bindFailFlag =0 
        chessuserinfodb.SaveUserData(userInfo)
        unilight.info(string.format("玩家:%d, 绑定上下级成功", params.uid))
    end

end


--请求绑定上下级
function ReqBindInvite(uid)
    local userInfo = chessuserinfodb.RUserDataGet(uid)
    if userInfo.base.inviter ~= "" then
        local url = string.format(table_parameter_formula[1001].Formula, userInfo.base.inviter, userInfo.base.inviteCode)
        unilight.HttpRequestGet("InviteBindCallback", url, {}, {uid=uid})
    end
end

--新玩家触发
function NewUserEvent(uid)
	-- SystemCoupon.TimeCoupon(uid)
    ReqBindInvite(uid)

    local userInfo = chessuserinfodb.RUserDataGet(uid)
    -- 判断账号注册IP和设备ID是否唯一
    local filter = unilight.o(unilight.eq("status.registerIp", userInfo.status.registerIp), unilight.eq("base.adjustId", userInfo.base.adjustId))
    if unilight.getCountByFilter('userinfo', filter) == 1 then
        userInfo.status.onlyPlayerRegister = 1
        unilight.savedata('userinfo',userInfo)
    end
    -- -- 判断电话号码表是否有信息
    -- unilight.delete(InviteRoulette.DB_PhoneNumber_Name,tonumber(userInfo.base.plataccount))
    -- 创建EX表
    local exinfo = {
        _id = uid,
        belowNum = 0,
        tolrebate = 0,              --总返利值
        tolBelowCharge = 0,         --下线总充值
        rebatechip = 0,             --可领取返利
        freeValidinViteChips = 0,   --免费有效玩家可领取金额
        todayFlowingChips = 0,      --今日可领取金额
        tomorrowFlowingChips = 0,   --明日可领取金额
        addFlowingTimes = 0,        --上次添加流水时间
        tolBetAll = 0,              --累计团队下线金币下注
        tolBetFall = 0,             --累计团队下线金币总返利
        todayBetAll = 0,            --今日团队下线金币下注
        amountavailablechip = 0,    --可领取金额
        totalRebateChip = 0,        --新玩家总返利
        totalFreeValidChips = 0,    --活跃玩家总返利
        totalValidChips = 0,        --玩家充值返利
    }
    unilight.savedata("extension_relation",exinfo)
end

--增加离线奖励
--sourceType 添加原因
function AddOfflineReward(uid, sourceType, goodId, goodNum, isCover, params)
    unilight.info(string.format("玩家:%d,增加离线奖励, 奖励类型:%d, goodId=%d, goodNum=%d",uid, sourceType, goodId, goodNum))
	local userInfo = chessuserinfodb.RUserInfoGet(uid)
    userInfo.offlineReward[sourceType] = userInfo.offlineReward[sourceType] or {isGet = 0, reward = {}}
    --专属奖励加个日志 
    if Const.GOODS_SOURCE_TYPE.RECHARGE_REWARD == sourceType then
        --以前的过期
        local lastGlobalId = userInfo.offlineReward[sourceType].globalId
        local filter = unilight.a(unilight.eq("uid", uid), unilight.eq("globalId", lastGlobalId))
        local infos  = unilight.chainResponseSequence(unilight.startChain().Table("exclusiveRewardLog").Filter(filter).Limit(100))
        for _, info in pairs(infos) do
            --已过期
            info.isOver = 1
            unilight.savedatasyn("exclusiveRewardLog", info)
            unilight.debug("专属奖励过期:%s"..table2json(info))
        end

        --记录一个全局id,方便查询
        local globalId = ChessGmMailMgr.GetEmailId()
        userInfo.offlineReward[sourceType].globalId = globalId
        local dataLog = {
            _id                = go.newObjectId(),      --唯一id
            timestamp          = os.time(),             --发放时间
            uid                = uid,                   --玩家id
            isGet              = 1,                     --是否领取(1未领取， 2已领取)
            rewardId           = params.rewardId,       --奖励类型
            chips              = goodNum,               --发放金币
            getTime            = 0,                     --领取时间
            isOver             = 0,                     --是否过期(0未过期，1已过期)
            globalId           = globalId,              --全局id
        }
        unilight.savedata("exclusiveRewardLog", dataLog)
    end

    --每次强制清空
    if isCover ~= nil and isCover == true then
        userInfo.offlineReward[sourceType].isGet = 0 
        userInfo.offlineReward[sourceType].reward = {}
    end

    table.insert(userInfo.offlineReward[sourceType].reward, {goodId=goodId, goodNum=goodNum})
    chessuserinfodb.SaveUserData(userInfo)
    unilight.savedata("userinfo", userInfo)
end


--获得离线奖励
function GetOfflineReward(uid, sourceType)
	local userInfo = chessuserinfodb.RUserInfoGet(uid)
    local rewardList = {}
    if userInfo.offlineReward[sourceType] == nil or table.len(userInfo.offlineReward[sourceType].reward) == 0 then
        return 1, rewardList
    end

    if userInfo.offlineReward[sourceType].isGet == 1 then
        unilight.debug("已经领取过了")
        return 1, rewardList
    end
    

    local summary = {}
    --累计专属奖励
    local totalChips = 0
    for _, v in pairs(userInfo.offlineReward[sourceType].reward) do
        summary = BackpackMgr.GetRewardGood(uid, v.goodId, v.goodNum, sourceType, summary)
        totalChips = totalChips + v.goodNum
    end

    for k, v in pairs(summary) do
        table.insert(rewardList, {goodId=k, goodNum=v})
    end
    -- userInfo.offlineReward[sourceType] = {}

	local userInfo = chessuserinfodb.RUserInfoGet(uid)
    userInfo.offlineReward[sourceType].isGet = 1
    --专属奖励
    if sourceType ==  Const.GOODS_SOURCE_TYPE.RECHARGE_REWARD then
        local lastGlobalId = userInfo.offlineReward[sourceType].globalId
        local filter = unilight.a(unilight.eq("uid", uid), unilight.eq("globalId", lastGlobalId))
        local infos  = unilight.chainResponseSequence(unilight.startChain().Table("exclusiveRewardLog").Filter(filter).Limit(100))
        for _, info in pairs(infos) do
            info.isGet = 2
            info.getTime = os.time()
            unilight.savedata("exclusiveRewardLog", info)
            unilight.debug("专属奖励获得:%s"..table2json(info))
        end
        -- userInfo.status.exclusiveNum = userInfo.status.exclusiveNum + totalChips 
    end

    chessuserinfodb.SaveUserData(userInfo)
    if sourceType ==  Const.GOODS_SOURCE_TYPE.RECHARGE_REWARD then
        chessuserinfodb.WPresentChange(uid, Const.PACK_OP_TYPE.ADD, totalChips, "专属奖励赠送金币")
    end

    return 0, rewardList
end


--获得离线奖励列表
function CmdGetOfflineRewardList(uid, sourceType)

    local send = {}
    send["do"] = "Cmd.ReqGetOfflineRewardListLobbyCmd_CS"

    local offlineReward = {}
    send["data"] = {
        sourceType = sourceType, 
        isGet = 1,
    }

	local userInfo = chessuserinfodb.RUserInfoGet(uid)
    if userInfo.offlineReward[sourceType] ~= nil  then
        for sourceType, goodInfo in pairs(userInfo.offlineReward[sourceType].reward) do
            table.insert(offlineReward, {goodId=goodInfo.goodId, goodNum = goodInfo.goodNum})
        end
        send.data.isGet = userInfo.offlineReward[sourceType].isGet
    end
    send.data.offlineReward = offlineReward
    unilight.sendcmd(uid, send)
end

--申请提现
function ReqWithDraw(orderNo, orderType, payPlat) 
    if payPlat == nil then
        -- local probability = {}
        -- local allResult = {}
        -- for _, v in ipairs(table_withdraw_plat) do
        --     if v["status"..orderType] == 1 then
        --         -- payPlat =  v.platId
        --         table.insert(probability, 10)
        --         table.insert(allResult, v.platId)
        --     end
        -- end
        -- payPlat = math.random(probability, allResult)
        payPlat = table_withdraw_plat[gamecommon.CommRandInt(table_withdraw_plat, 'pro')].platId
    end
    unilight.info("申请提现,使用渠道号:"..payPlat)
    local url = string.format(table_parameter_formula[1003].Formula, orderNo, payPlat)
    unilight.HttpRequestGet("Echo", url)
    return payPlat
end

--玩家踢下线
function KickUserLogout(uid, errno)
    local msg = {}
    msg["do"] = "Cmd.KickUserGame_S"
    msg["data"] = {
        errno = errno,
        desc  = "",
    }
    unilight.sendcmd(uid, msg)

    --其它进程也要踢下线
    if RoomInfo ~= nil and RoomInfo.BroadcastToAllZone ~= nil then
        RoomInfo.BroadcastToAllZone("Cmd.KickUserGame_S", {uid=uid, desc="重新登陆踢出在线玩家"})
    end
end

--服务器关闭事件在线玩家才会调用
function ServerStop(uid)
    --如果还在缓存
    if unilight.REDISDB ~= nil then
        -- local userInfo = unilight.redis_gethashdata_Str("userinfo", tostring(uid))
        local userInfo = unilight.redis_getdata('userinfo_'..tostring(uid))
        if userInfo ~= "" then
            unilight.savedata("userinfo", json2table(userInfo), true)
        end
    end
end

-- 更改玩家货币状态  体验和真实金币
function ChangeUserExperienceStatus(uid)
    local userInfo = unilight.getdata('userinfo',uid)
    if userInfo.status.experienceStatus == 0 then
        -- 重置状态
        userInfo.status.experienceStatus = 1
        userInfo.property.chips = 0
        unilight.savedata('userinfo',userInfo)
        local mailInfo = {}
        local mailConfig = tableMailConfig[34]
        mailInfo.charid = uid
        mailInfo.subject = mailConfig.subject
        mailInfo.content = string.format(mailConfig.content)
        mailInfo.type = 0
        mailInfo.attachment = {}
        mailInfo.extData = {}
        ChessGmMailMgr.AddGlobalMail(mailInfo)
    end
    -- 插入前判断是否是首次进入APK  首次进入需要下发奖励
    local firstApkFlag = false
    -- 遍历查找玩家是否登陆过安卓APK
    for _, loginPlatId in ipairs(userInfo.status.loginPlatIds) do
        if loginPlatId >= 3 then
            firstApkFlag = true
            break
        end
    end
    if userInfo.status.loginPlatReward == 2 then
        firstApkFlag = false
    end
    -- 首次登陆下发奖励
    if firstApkFlag == true then
        local addScore = (import "table/table_parameter_parameter")[33].Parameter
        local mailInfo = {}
        local mailConfig = tableMailConfig[40]
        mailInfo.charid = uid
        mailInfo.subject = mailConfig.subject
        mailInfo.content = string.format(mailConfig.content,addScore / 100,chessutil.FormatDateGet(nil,"%d/%m/%Y %H:%M:%S"))
        mailInfo.configId = 30
        mailInfo.type = 0
        -- mailInfo.attachment={{itemId=3, itemNum=addScore}}
        mailInfo.extData={configId=mailConfig.ID,isPresentChips = 1}
        ChessGmMailMgr.AddGlobalMail(mailInfo)
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, addScore, Const.GOODS_SOURCE_TYPE.BINDAPK)
        WithdrawCash.AddBet(uid,addScore * 3)
        userInfo.status.loginPlatReward = 2
        chessuserinfodb.WUserInfoUpdate(uid, userInfo)
    end
end

-- 查询玩家是否有上级
function HaveSuperiors(uid)
    local childInfo = unilight.getdata('extension_relation',uid)
    if table.empty(childInfo) then
        return false
    end
    if table.empty(childInfo.parents) then
        return false
    end
    return true    
end