-- 有效邀请返利
module('rebate',package.seeall)
local Table_ValidInvite = import "table/table_validinvite" --读取等级档次表
local Table_ValidInviteCash = import "table/table_validinviteCash" --读取等级档次表
local Table_TeamRebate_Chips = import "table/table_teamRebate_chips" --奖励配置
local Table_TeamRebate_Recharge = import "table/table_teamRebate_recharge" --奖励配置
local DB_LOG_NAME = 'validinvitelog'
local DB_NAME = 'validinvite'
-- 判断玩家是否满足
function IsValidinVite(uid)
    -- 玩家信息
    local userInfo = unilight.getdata('userinfo',uid)
    -- 是否有上级邀请
    if (not UserInfo.HaveSuperiors(uid)) then
        return
    end
    -- 是否充值
    if userInfo.property.totalRechargeChips < 1000 then
        return
    end
    -- 是否提供给上级过有效充值玩家金钱  （需求更改 但是因为发出去过钱所以字段名不能修改了QAQ） 0 未提供  2 提供过
    if userInfo.status.onlyRegister == 2 then
        return
    end
    -- 游戏中累计下注小于200
    if userInfo.gameData.slotsBet >= 20000 then
        return
    end
    -- 判定已经给予奖励
    userInfo.status.onlyRegister = 2
    unilight.savedata('userinfo',userInfo)
    -- 添加进度 发放奖励接口
    addParentSchedule(uid)
end

-- 判断玩家是否满足
function IsFreeValidinVite(uid)
    -- 玩家信息
    local userInfo = unilight.getdata('userinfo',uid)
    -- 是否有上级邀请
    if (not UserInfo.HaveSuperiors(uid)) then
        return
    end
    -- 是否充值
    if userInfo.property.totalRechargeChips <= 1000 then
        return
    end
    -- 游戏中累计下注达到30
    if userInfo.gameData.slotsBet < 20000 then
        return
    end
    -- 是否提供给上级过有效充值玩家金钱  （需求更改 但是因为发出去过钱所以字段名不能修改了QAQ） 0 未提供  2 提供过
    if userInfo.status.onlyPlayerRegister == 2 then
        return
    end
    -- 判定已经给予奖励
    userInfo.status.onlyPlayerRegister = 2
    unilight.savedata('userinfo',userInfo)

    -- 添加进度 发放奖励接口
    addParentFreeSchedule(uid)
end

-- 满足条件的玩家添加进度 发放奖励
function addParentSchedule(childId)
    local childInfo = unilight.getdata('extension_relation',childId)
    if table.empty(childInfo) then
        return
    end
    if table.empty(childInfo.parents) then
        return
    end
    local parentId = childInfo.parents[#childInfo.parents]
    -- 玩家信息
    local parentInfo = unilight.getdataNoCatch(DB_NAME,parentId)
    if table.empty(parentInfo) then
        parentInfo = {
            _id = parentId,
            validinViteNewPlayerList = {},
            validinViteActivePlayerList = {},
            validinViteNewPlayerNum = 0,
            validinViteActivePlayerNum = 0,
            validinViteRechargePlayerNum = 0,
            validinViteNewPlayerChips = 0,
            validinViteActivePlayerChips = 0,
            validinViteRechargePlayerChips = 0,
            validinViteRechargePlayerRechargeChips = 0,
        }
    end
    local addChips = 0
    local userInfo = unilight.getdata('userinfo',childId)
    if userInfo.status.firstPayChip < 3000 then
        addChips = Table_TeamRebate_Chips[1].chips
    else
        addChips = Table_TeamRebate_Chips[1].chips2
    end
    local validinViteNewPlayerNum = #parentInfo.validinViteNewPlayerList + 1
    -- 添加邀请人数
    table.insert(parentInfo.validinViteNewPlayerList,childId)
    parentInfo.validinViteNewPlayerNum = parentInfo.validinViteNewPlayerNum or 0
    parentInfo.validinViteNewPlayerChips = parentInfo.validinViteNewPlayerChips or 0
    parentInfo.validinViteNewPlayerNum = parentInfo.validinViteNewPlayerNum + 1
    parentInfo.validinViteNewPlayerChips = parentInfo.validinViteNewPlayerChips + addChips
    -- 增加奖励金额
    unilight.savedata(DB_NAME,parentInfo)
    -- 有奖励则发放奖励
    if addChips > 0 then
        unilight.incdate('extension_relation', parentId, {rebatechip=addChips,totalRebateChip = addChips})
        local inc={
            ['$inc']={
                totalrebate=addChips
            }
        }
        unilight.get_mongodb().Table("rebateItem").Update({uid=parentId,childId=childId},inc)
        -- 添加日志记录
        ValidinViteLog(parentId,addChips,1,childId,validinViteNewPlayerNum)
    end
end

-- 满足条件的玩家添加进度 发放奖励
function addParentFreeSchedule(childId)
    local childInfo = unilight.getdata('extension_relation',childId)
    if table.empty(childInfo) then
        return
    end
    if table.empty(childInfo.parents) then
        return
    end
    local parentId = childInfo.parents[#childInfo.parents]
    -- 玩家信息
    local parentInfo = unilight.getdataNoCatch(DB_NAME,parentId)
    if table.empty(parentInfo) then
        parentInfo = {
            _id = parentId,
            validinViteNewPlayerList = {},
            validinViteActivePlayerList = {},
            validinViteNewPlayerNum = 0,
            validinViteActivePlayerNum = 0,
            validinViteRechargePlayerNum = 0,
            validinViteNewPlayerChips = 0,
            validinViteActivePlayerChips = 0,
            validinViteRechargePlayerChips = 0,
            validinViteRechargePlayerRechargeChips = 0,
        }
    end
    -- 添加奖励金额
    local addChips = 0
    -- 判断是否需要补发
    local userInfo = unilight.getdata('userinfo',childId)
    if userInfo.status.firstPayChip < 3000 then
        addChips = Table_TeamRebate_Chips[2].chips
    else
        addChips = Table_TeamRebate_Chips[2].chips2
    end

    if userInfo.status.onlyRegister ~= 2 then
        userInfo.status.onlyRegister = 2
        unilight.savedata('userinfo',userInfo)
        addChips = addChips + Table_TeamRebate_Chips[1].chips
    end
    local validinViteNewPlayerNum = #parentInfo.validinViteActivePlayerList + 1
    -- 添加邀请人数
    table.insert(parentInfo.validinViteActivePlayerList,childId)
    parentInfo.validinViteActivePlayerNum = parentInfo.validinViteActivePlayerNum or 0
    parentInfo.validinViteActivePlayerChips = parentInfo.validinViteActivePlayerChips or 0
    parentInfo.validinViteActivePlayerNum = parentInfo.validinViteActivePlayerNum + 1
    parentInfo.validinViteActivePlayerChips = parentInfo.validinViteActivePlayerChips + addChips
    -- 增加奖励金额
    unilight.savedata(DB_NAME,parentInfo)
    -- 有奖励则发放奖励
    if addChips > 0 then
        unilight.incdate('extension_relation', parentId, {freeValidinViteChips=addChips,totalFreeValidChips = addChips})
        local inc={
            ['$inc']={
                totalrebate=addChips
            }
        }
        unilight.get_mongodb().Table("rebateItem").Update({uid=parentId,childId=childId},inc)
        -- 添加日志记录
        ValidinViteLog(parentId,addChips,2,childId,validinViteNewPlayerNum)
    end
end


function ValidinViteLog(uid,addChips,type,childId,validinViteNewPlayerNum)
    local dbInfo = {
        _id = go.newObjectId(),
        uid = uid,                  -- 玩家ID
        addChips = addChips,        -- 本次发放金额
        addTime = os.time(),        -- 发放时间
        validinViteNewPlayerNum = validinViteNewPlayerNum,  -- 第几个下限
        childId = childId,              -- 下限ID
        type = type,              -- 有效玩家类型 1 付费玩家 2 免费有效玩家
    }
    -- 保存记录
    unilight.savedata(DB_LOG_NAME,dbInfo)
end

--获得邀请玩家人数
function GetViteNum(uid) 
    local parentInfo = unilight.getdataNoCatch(DB_NAME, uid)
    if table.empty(parentInfo) then
        return 0
    end
    return table.len(parentInfo.validinViteNewPlayerList) + table.len(parentInfo.validinViteActivePlayerList)
end

-- 充值直接返利
function RechargeVite(childId,rechargeChips)
    local childInfo = unilight.getdata('extension_relation',childId)
    if table.empty(childInfo) then
        return
    end
    if table.empty(childInfo.parents) then
        return
    end
    local parentId = childInfo.parents[#childInfo.parents]
    -- 玩家信息
    local parentInfo = unilight.getdataNoCatch(DB_NAME,parentId)
    if table.empty(parentInfo) then
        parentInfo = {
            _id = parentId,
            validinViteNewPlayerList = {},
            validinViteActivePlayerList = {},
            validinViteNewPlayerNum = 0,
            validinViteActivePlayerNum = 0,
            validinViteRechargePlayerNum = 0,
            validinViteNewPlayerChips = 0,
            validinViteActivePlayerChips = 0,
            validinViteRechargePlayerChips = 0,
            validinViteRechargePlayerRechargeChips = 0,
        }
    end
    -- 添加奖励金额
    local addChips = 0
    -- 判断是否需要补发
    addChips = rechargeChips * (Table_TeamRebate_Recharge[1].rates / 10000)

    local validinViteNewPlayerNum = #parentInfo.validinViteActivePlayerList + 1
    -- 添加邀请人数
    table.insert(parentInfo.validinViteActivePlayerList,childId)
    parentInfo.validinViteRechargePlayerNum = parentInfo.validinViteRechargePlayerNum or 0
    parentInfo.validinViteRechargePlayerChips = parentInfo.validinViteRechargePlayerChips or 0
    parentInfo.validinViteRechargePlayerNum = parentInfo.validinViteRechargePlayerNum + 1
    parentInfo.validinViteRechargePlayerChips = parentInfo.validinViteRechargePlayerChips + addChips
    parentInfo.validinViteRechargePlayerRechargeChips = parentInfo.validinViteRechargePlayerRechargeChips + rechargeChips
    -- 增加奖励金额
    unilight.savedata(DB_NAME,parentInfo)
    -- 有奖励则发放奖励
    if addChips > 0 then
        unilight.incdate('extension_relation', parentId, {rechargeValidinViteChips=addChips,totalValidChips = addChips})
        local inc={
            ['$inc']={
                totalrebate=addChips
            }
        }
        unilight.get_mongodb().Table("rebateItem").Update({uid=parentId,childId=childId},inc)
        -- 添加日志记录
        ValidinViteLog(parentId,addChips,2,childId,validinViteNewPlayerNum)
    end
end

-- 领取返利奖励
function GetInviteReward(uid,type)
    type = type or 0
    -- 玩家信息
    local datainfo = unilight.getdataNoCatch(DB_NAME,uid)
    if table.empty(datainfo) then
        datainfo = {
            _id = uid,
            validinViteNewPlayerList = {},
            validinViteActivePlayerList = {},
            validinViteNewPlayerNum = 0,
            validinViteActivePlayerNum = 0,
            validinViteRechargePlayerNum = 0,
            validinViteNewPlayerChips = 0,
            validinViteActivePlayerChips = 0,
            validinViteRechargePlayerChips = 0,
            validinViteRechargePlayerRechargeChips = 0,
        }
    end
    local rewardChips = 0
    if type == 1 then
        rewardChips = datainfo.validinViteNewPlayerChips
    elseif type == 2 then
        rewardChips = datainfo.validinViteActivePlayerChips
    elseif type == 3 then
        rewardChips = datainfo.validinViteRechargePlayerChips
    end
    
    -- 增加奖励
    -- BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, rewardChips, Const.GOODS_SOURCE_TYPE.NCHIP)
    -- 保存统计
    local userInfo = unilight.getdata('userinfo',uid)
    userInfo.property.totalvalidinvitechips = userInfo.property.totalvalidinvitechips + rewardChips
    unilight.savedata('userinfo',userInfo)
    local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    withdrawCashInfo.specialWithdrawal = withdrawCashInfo.specialWithdrawal + rewardChips
    unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)

    if type == 1 then
        datainfo.validinViteNewPlayerNum = 0
        datainfo.validinViteNewPlayerChips = 0
    elseif type == 2 then
        datainfo.validinViteActivePlayerNum = 0
        datainfo.validinViteActivePlayerChips = 0
    elseif type == 3 then
        datainfo.validinViteRechargePlayerNum = 0
        datainfo.validinViteRechargePlayerChips = 0
        datainfo.validinViteRechargePlayerRechargeChips = 0
    end
    unilight.savedata(DB_NAME,datainfo)
    local res = {
        rewardChips = rewardChips,
    }
    return res
end

--查询流水返利接口
function QueryRebateRelation(uid)
    local data = unilight.getdata('extension_relation',uid)
    local res={
        unclaimed = 0,      --待领取
        claimed = 0,        --可领取
        oneUnderNum = 0,    --下线人数
    }
    if table.empty(data)==false then
        res.unclaimed = data.TodayBetFall
        res.claimed = data.tomorrowFlowingChips
        res.oneUnderNum = data.oneUnderNum
    end
    return res

end
--领取返利
function RecvRebateRelation(uid)
    local claimed = 0
    local data = unilight.getdata('extension_relation',uid)
    if table.empty(data)==false then
        claimed = math.floor(data.tomorrowFlowingChips)
    end
    if claimed>0 then
        --加上金币
        data.tomorrowFlowingChips=data.tomorrowFlowingChips-claimed
        unilight.savedata('extension_relation',data)
        local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
        withdrawCashInfo.statement = withdrawCashInfo.statement + claimed
        BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD,claimed , Const.GOODS_SOURCE_TYPE.RECVREBATE)
        unilight.savedata('withdrawcash',withdrawCashInfo)
    end
    --返回
    return {
        claimed = claimed,  --领取的具体值
    }
end