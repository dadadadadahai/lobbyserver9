--游戏通用杀逻辑
module('gameKillComm', package.seeall)
local table_auto_killConditio = import 'table/table_auto_killConditio'
local table_auto_pointxs = import 'table/table_auto_pointxs'
local table_autoControl_cz = import 'table/table_autoControl_cz'
local table_autoControl_dc = import 'table/table_autoControl_dc'
local table_auto_JF = import 'table/table_auto_JF'
--计算各个上限值
--[[
    conditionlev:当前档次
    userinfo:玩家信息
]]
function CalcChargeMax(chips,conditionlev,userinfo)
    local chipsWithdraw = userinfo.status.chipsWithdraw
    local totalRechargeChips = userinfo.property.totalRechargeChips
    
    --计算最高上限
    local xs =  table_autoControl_cz[1]['condition' .. conditionlev]
    if userinfo.base.regFlag == 2 then
        xs =  table_autoControl_cz[2]['condition' .. conditionlev]
    end

    -- --计算流水上限值
    if totalRechargeChips*(xs-1)>=2000000 then
        userinfo.point.chargeMax=totalRechargeChips+2000000-chipsWithdraw
    else
        userinfo.point.chargeMax = totalRechargeChips*xs - chipsWithdraw
    end
end
--当前是否应该进入点杀判定，是否恢复判定
function EnterKill(chips,userinfo,betinfo)
    local rtp  = 0
    if userinfo.property.totalRechargeChips<=3000 then
        return rtp
    end
    chips = chips + betinfo.betchips
    local chipsWithdraw = userinfo.status.chipsWithdraw
    local killIndex = userinfo.point.killNum + 1
    if userinfo.point.killXs>0 then
        killIndex = userinfo.point.killNum
    end
    if killIndex>#userinfo.point.killcfg then
        killIndex = #userinfo.point.killcfg
    end
    local killcfg = userinfo.point.killcfg[killIndex]
    userinfo.point.killTakeEffect = killcfg.takeEffect
    if userinfo.point.killXs<= 0 and WithdrawCash.GetWithdrawcashInfo(userinfo._id).cancovertchips >= userinfo.point.chargeMax*killcfg.takeEffect/10000 and chips<userinfo.point.chargeMax then
        --进入点杀逻辑
        userinfo.point.killXs = killcfg.takeEffectLowRange/10000
        --点杀系数携带
        userinfo.point.killNum = userinfo.point.killNum + 1
        userinfo.point.killMul = killcfg.mul
        userinfo.point.killRtp = killcfg.rtp
    elseif (userinfo.point.killXs>0 and (chips/(userinfo.point.chargeMax))<=userinfo.point.killXs) or (chips-betinfo.betchips)<=50 or chips>=userinfo.point.chargeMax then
        --刀量结束
        userinfo.point.killXs = 0
        userinfo.point.killChargeMax = killcfg.killChargeMax
    end
    if userinfo.point.killXs>0 then
        --挂在刀量逻辑
        if userinfo.point.MiddleMul<=0 or (userinfo.point.MiddleMul>0 and userinfo.point.MiddleMul>userinfo.point.killMul) then
            userinfo.point.MiddleMul = userinfo.point.killMul
        end
        rtp = userinfo.point.killRtp
        userinfo.point.isInControl = 1
    else
        if userinfo.point.isMiddleKill~=1 then
            userinfo.point.MiddleMul = 0
        end
    end
    userinfo.point.MiddleChageMax = userinfo.point.chargeMax * userinfo.point.killChargeMax
    return rtp
end
--游戏中点杀逻辑实现
function ChargeRandomKill(uid)
    local userinfo = unilight.getdata('userinfo', uid)
    if table.empty(userinfo) then
        return
    end
    local index = 0
    local totalRechargeChips = userinfo.property.totalRechargeChips
    for i, value in ipairs(table_autoControl_dc) do
        if totalRechargeChips>=value.chargeLimit and totalRechargeChips<=value.chargeMax then
            index = i
            break
        end
    end
    if userinfo.point.killNum>0 then
        userinfo.point.killChargeNum = userinfo.point.killChargeNum + 1
        unilight.update('userinfo',userinfo._id,userinfo)
    else
        userinfo.point.killChargeNum = 0
        unilight.update('userinfo',userinfo._id,userinfo)
    end
    if userinfo.point.chargeIndex~=index then
        -- userinfo.point.MiddleMul = 0
        userinfo.point.chargeIndex = index
        -- InitKillCtr(userinfo)
        unilight.update('userinfo',userinfo._id,userinfo)
    else
        for _,value in ipairs(table_auto_JF) do
            if value.chargeNum == userinfo.point.killChargeNum then
                local gailv = value.gailv
                local rand = math.random(1,10000)
                if rand<=gailv then
                    -- InitKillCtr(userinfo)
                    break
                end
            end
        end
    end
end
function InitKillCtr(userinfo,isupdate)
    local totalRechargeChips = userinfo.property.totalRechargeChips
    --玩家充值发生档次改变
   userinfo.point.MiddleChageMax = 0
   userinfo.point.killXs = 0
   userinfo.point.killNum = 0
   userinfo.point.killChargeNum = 0
   userinfo.point.killcfg = {}
   userinfo.point.killChargeMax = 1
   --重新随机上限点杀系数
   for _, value in ipairs(table_auto_killConditio) do
       if totalRechargeChips>=value.chargeLow and totalRechargeChips<=value.chargeUp then
           userinfo.point.killMaxNum = math.random(value.killNumLow,value.killNumUp)
           break
       end
   end
   --重新确定每一刀的上限系数
   for i=1,userinfo.point.killMaxNum -1 do
       --生效百分比
       local takeEffect =  math.random(table_auto_pointxs[i].prcentlow,table_auto_pointxs[i].prcentup)
       local takeEffectLowRange = math.random(table_auto_pointxs[i].low1,table_auto_pointxs[i].up1)
       local mul = table_auto_pointxs[i].mul1
       local rtp = table_auto_pointxs[i].rtp1
       local killChargeMax = table_auto_pointxs[i].kill1ChargeMax
       table.insert(userinfo.point.killcfg,{takeEffect=takeEffect,takeEffectLowRange=takeEffectLowRange,mul=mul,rtp=rtp,killChargeMax=killChargeMax})
   end
   --最后一刀
   local i = #table_auto_pointxs
   local takeEffect =  math.random(table_auto_pointxs[i].prcentlow,table_auto_pointxs[i].prcentup)
   local takeEffectLowRange = math.random(table_auto_pointxs[i].low1,table_auto_pointxs[i].up1)
   local mul = table_auto_pointxs[i].mul1
   local rtp = table_auto_pointxs[i].rtp1
   local killChargeMax = table_auto_pointxs[i].kill1ChargeMax
   table.insert(userinfo.point.killcfg,{takeEffect=takeEffect,takeEffectLowRange=takeEffectLowRange,mul=mul,rtp=rtp,killChargeMax=killChargeMax})
   unilight.update('userinfo',userinfo._id,userinfo)
end