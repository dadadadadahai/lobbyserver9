module('gameHelp',package.seeall)
local table_auto_upf = import 'table/table_auto_upf'
function ChargeBack(uid,backPrice)
    local userinfo = unilight.getdata('userinfo',uid)
    userinfo.gameData.latestChargeMoney = backPrice
    --随机生效万分比
    for _, value in ipairs(table_auto_upf) do
        if backPrice>=value.latestLow and backPrice<=value.latestUp then
            --随机一个生效万分比
            userinfo.point.upLWorkPrcent = math.random(value.workPecentLow,value.workPecentUp)
            userinfo.point.isCurRechargeUp = 0
            break
        end
    end
    unilight.update('userinfo',userinfo._id,userinfo)
end
--服务器拉起机制
function UserHelp(chips,userinfo)
    local slotsBet= userinfo.gameData.slotsBet
    local totalRechargeChips = userinfo.property.totalRechargeChips
    local backPrice = userinfo.gameData.latestChargeMoney
    local chipsWithdraw = userinfo.status.chipsWithdraw
    local bObj = {}
    for _, value in ipairs(table_auto_upf) do
        if backPrice>=value.latestLow and backPrice<=value.latestUp then
            bObj = value
            if userinfo.point.upLWorkPrcent<=0 then
                userinfo.point.upLWorkPrcent = math.random(value.workPecentLow,value.workPecentUp)
            end
            break
        end
    end
    if userinfo.gameData.latestChargeMoney<=-1 or userinfo.point.IsNormal==0 then
        return false,0
    end
    if slotsBet<=totalRechargeChips*bObj.betMul and (chips+chipsWithdraw)<=totalRechargeChips*(userinfo.point.upLWorkPrcent/10000) and userinfo.point.isCurRechargeUp==0 then
        userinfo.point.isCurRechargeUp = 1
        --解除倍数限制
        userinfo.point.MiddleMul = 0
        return true,bObj.rtp
    end
    if userinfo.point.isCurRechargeUp == 1 then
        local o1 = totalRechargeChips*bObj.upOverPecent/10000-chipsWithdraw
        local o2 = userinfo.gameData.latestChargeMoney*bObj.latestChargeMul
        local min = o1
        if min>o2 then
            min = o2
        end
        if chips>=min then
            --结束拉起
            userinfo.gameData.latestChargeMoney = -1
            return false,0
        end
        userinfo.point.MiddleMul = 0
        return true,bObj.rtp
    end
end