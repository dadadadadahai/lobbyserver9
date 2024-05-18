module('InviteRoulette', package.seeall) 

Table_InviteRoulettePro = require "table/table_inviteR_pro"
Table_InviteRouletteCashNum = require "table/table_inviteR_cnum"
Table_InviteRouletteCash = require "table/table_inviteR_cash"
Table_InviteRouletteGoldNum = require "table/table_inviteR_gnum"
DB_Name  = "inviteroulette"
DB_Log_Name  = "inviteroulettelog"
DB_PhoneNumber_Name  = "phonenumber"
-- 获取信息
function GetInviteRouletteInfo(uid)
    -- 获取任务转盘模块数据库信息
	local inviterouletteInfo = unilight.getdata(DB_Name, uid)
	-- 没有则初始化信息
	if table.empty(inviterouletteInfo) then
		inviterouletteInfo = {
            _id = uid,                                              --uid
			playNum = 1,                                            --可游玩次数
			cashNum = 0,                                            --提现金额
            inviteNum = 0,                                          --邀请玩家数
			lastChangeTime = 0,		                                --上一次更新时间
			lastPlayTime = 0,		                                --上一次更新时间
            history = {}                                            --邀请历史
		}
		unilight.savedata(DB_Name,inviterouletteInfo)
	end
    local changeFlag = false
	-- 判断是否需要刷新
	if inviterouletteInfo.lastPlayTime ~= 0 and os.time() - inviterouletteInfo.lastPlayTime > 3600 * 24 then
	-- if chessutil.DateDayDistanceByTimeGet(inviterouletteInfo.lastPlayTime) > 0 then
        -- 刷新数据
        inviterouletteInfo.lastPlayTime = 0
        inviterouletteInfo.playNum = 1
        changeFlag = true
    end
	if inviterouletteInfo.lastChangeTime ~= 0 and os.time() - inviterouletteInfo.lastChangeTime > 3600 * 24 * 3 then
	-- if chessutil.DateDayDistanceByTimeGet(inviterouletteInfo.lastChangeTime) > 3 then
        -- 刷新数据
        inviterouletteInfo.lastChangeTime = 0
        inviterouletteInfo.cashNum = 0
        inviterouletteInfo.inviteNum = 0
        inviterouletteInfo.history = {}
        changeFlag = true
	end
    if changeFlag then
        unilight.savedata(DB_Name,inviterouletteInfo)
    end
	return inviterouletteInfo
end

-- 返回轮盘页面信息
function ReturnInviteRouletteInfo(uid)
    local inviterouletteInfo = GetInviteRouletteInfo(uid)
    --包装返回信息
    local history = {}
    for _, historyInfo in ipairs(inviterouletteInfo.history) do
        -- 生成加密字段
        local firstPlataccount = tonumber(string.sub(tostring(historyInfo[1]), 1, 1))
        local secondPlataccount = tonumber(string.sub(tostring(historyInfo[1]), -3, -1))
        table.insert(history,{firstPlataccount = firstPlataccount,secondPlataccount = secondPlataccount,addCashNum = historyInfo[2]})
    end
    local lastChangeTime = 0
    local lastPlayTime = 0
    if inviterouletteInfo.lastChangeTime > 0 then
        lastChangeTime = inviterouletteInfo.lastChangeTime + 3 * 24 * 3600
    end
    if inviterouletteInfo.lastPlayTime > 0 then
        lastPlayTime = inviterouletteInfo.lastPlayTime + 1 * 24 * 3600
    end
    local res = {
        playNum = inviterouletteInfo.playNum,                                            --可游玩次数
        cashNum = inviterouletteInfo.cashNum,                                            --提现金额
        inviteNum = inviterouletteInfo.inviteNum,                                        --邀请玩家数
        lastChangeTime = lastChangeTime,                                                 --上一次更新时间3天
        lastPlayTime = lastPlayTime,                                                     --上一次更新时间1天
        history = history,                                                               --历史记录
    }
    return res
end

-- 随机每日轮盘结果
function GetDayRoulette(uid)
    local inviterouletteInfo = GetInviteRouletteInfo(uid)
    -- 减少游玩次数
    inviterouletteInfo.playNum = inviterouletteInfo.playNum - 1
    -- 转盘ID   默认为现金
    local rouletteDesc = -2
    local rouletteNum = 0
    -- 判断是否首次转盘
    if inviterouletteInfo.cashNum == 0 then
        inviterouletteInfo.cashNum = math.random(Table_InviteRouletteCash[1].min,Table_InviteRouletteCash[1].max)
        rouletteNum = inviterouletteInfo.cashNum
    else
        --随机转盘内容
        rouletteDesc = Table_InviteRoulettePro[gamecommon.CommRandInt(Table_InviteRoulettePro, 'pro')].num
        if rouletteDesc == -1 then
            rouletteNum = Table_InviteRouletteGoldNum[gamecommon.CommRandInt(Table_InviteRouletteGoldNum, 'pro')].num
            -- 增加奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, rouletteNum, Const.GOODS_SOURCE_TYPE.TASKTURNTABLE)
            AddLog(inviterouletteInfo,rouletteDesc,rouletteNum)
        elseif rouletteDesc == -2 then
            -- 现金奖励
            -- 获取玩家配置表区间
            for _, tableInfo in ipairs(Table_InviteRouletteCashNum) do
                if inviterouletteInfo.cashNum >= tableInfo.ownedMin and inviterouletteInfo.cashNum <= tableInfo.ownedMax then
                    rouletteNum = math.random(tableInfo.getMin,tableInfo.getMax)
                    inviterouletteInfo.cashNum = inviterouletteInfo.cashNum + rouletteNum
                    break
                end
            end
            -- 如果未中奖则改变状态
            if rouletteNum == 0 then
                rouletteDesc = 0
            end
            AddLog(inviterouletteInfo,rouletteDesc,rouletteNum)
        elseif rouletteDesc ~= -2 then
            rouletteNum = rouletteDesc
            -- 增加奖励
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, rouletteNum, Const.GOODS_SOURCE_TYPE.TASKTURNTABLE)
            AddLog(inviterouletteInfo,rouletteDesc,rouletteNum)
        end
    end
    -- 修改时间
    if inviterouletteInfo.lastChangeTime == 0 then
        inviterouletteInfo.lastChangeTime = os.time()
    end
    -- 修改时间
    if inviterouletteInfo.lastPlayTime == 0 then
        inviterouletteInfo.lastPlayTime = os.time()
    end
    unilight.savedata(DB_Name,inviterouletteInfo)
    -- 返回结果
    local res = {
        rouletteDesc = rouletteDesc,
        rouletteNum = rouletteNum,
        lastPlayTime = inviterouletteInfo.lastPlayTime + 1 * 24 * 3600,
        lastChangeTime = inviterouletteInfo.lastChangeTime + 3 * 24 * 3600,
    }
    return res
end

-- 邀请玩家增加提现金额
function AddWithdrawCashNum(childId)
    local userInfo = unilight.getdata('userinfo',childId)
    -- 是否有上级邀请
    if not UserInfo.HaveSuperiors(childId) then
        return
    end
    -- 下级是否添加过进度判断
    if userInfo.status.inviteRouletteFlag ~= 0 then
        return
    else
        userInfo.status.inviteRouletteFlag = 1
    end

	local filter = unilight.a(unilight.eq("childId", childId),unilight.eq("lev", 1))
    local fatherInfo = unilight.chainResponseSequence(unilight.startChain().Table('rebateItem').Filter(filter))[1]
    if fatherInfo == nil then
        return
    end
    local plataccount = unilight.getdata('userinfo',childId).base.plataccount

    local inviterouletteInfo = GetInviteRouletteInfo(fatherInfo.uid)
    if inviterouletteInfo.cashNum == 0 then
        return
    end
    local addCashNum = 0
    -- 获取玩家配置表区间
    for _, tableInfo in ipairs(Table_InviteRouletteCashNum) do
        if inviterouletteInfo.cashNum >= tableInfo.ownedMin and inviterouletteInfo.cashNum <= tableInfo.ownedMax then
            addCashNum = math.random(tableInfo.getMin,tableInfo.getMax)
            break
        end
    end
    inviterouletteInfo.cashNum = inviterouletteInfo.cashNum + addCashNum
    inviterouletteInfo.inviteNum = inviterouletteInfo.inviteNum + 1
    AddLog(inviterouletteInfo,-3,addCashNum)
    table.insert(inviterouletteInfo.history,{plataccount, addCashNum})
    unilight.savedata(DB_Name,inviterouletteInfo)
    unilight.savedata('userinfo',userInfo)
end

-- 获取电话号码
function GetPhoneNumber()
    local countNum = unilight.startChain().Table(DB_PhoneNumber_Name).Filter(unilight.gt('_id',0)).Count()
    local points = {}
    if countNum >= 20 then
        points = chessutil.NotRepeatRandomNumbers(1, countNum, 20)
    else
        points = chessutil.NotRepeatRandomNumbers(1, countNum, countNum)
    end
    local phoneInfos = {}
    for _, point in ipairs(points) do
        local datainfo = unilight.chainResponseSequence(unilight.startChain().Table(DB_PhoneNumber_Name).Filter(unilight.gt('_id',0)).Skip(point - 1).Limit(1))
        if table.empty(datainfo) == false then
            table.insert(phoneInfos,datainfo[1]._id)
        end
    end
    local res = {
        phoneInfos = phoneInfos
    }
    return res
end

-- 添加日志
function AddLog(inviterouletteInfo,getType,addCashNum)
    unilight.savedata(DB_Log_Name,{
        uid = inviterouletteInfo._id,
        playNum = inviterouletteInfo.playNum,
        getType = getType,
        addCashNum = addCashNum,
        cashNum = inviterouletteInfo.cashNum,
        inviteNum = inviterouletteInfo.inviteNum,
        lastChangeTime = inviterouletteInfo.lastChangeTime,
        lastPlayTime = inviterouletteInfo.lastPlayTime,
        dateTime = os.time()
    })
end
