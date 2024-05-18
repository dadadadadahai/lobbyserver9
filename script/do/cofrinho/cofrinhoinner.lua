module('cofrinho', package.seeall)
--金币银币
function AddCofrinho(uid, gold)
    -- nvipmgr.AddVipRecv(uid,gold)
    local vipLevel = nvipmgr.GetVipLevel(uid)
    --vip等级
    if vipLevel<table_cofrinho_cfg[1].vipLowLevel then
        return
    end
    --转换银币
    local wSilScore = math.floor(gold *(table_cofrinho_cfg[1].precet/100))
    --实际银币
    local rsil = chessuserinfodb.RUserDiamondGet(uid)
    if wSilScore>rsil then
        wSilScore = rsil
    end
    if wSilScore<=0 then
        return
    end
    --改变银币实际值
    chessuserinfodb.WDiamondChange(uid, Const.PACK_OP_TYPE.SUB,wSilScore , "输金币转化银币")
    local datainfo = Get(uid)
    datainfo.goldRecv = datainfo.goldRecv + wSilScore
    datainfo.tChange = datainfo.tChange + wSilScore
    unilight.update(Table,datainfo._id,datainfo)
end
--获取总共转换的银币值
function GetTchange(uid)
    local datainfo = Get(uid)
    return datainfo.tChange,datainfo.goldRecv
end


-- --存钱罐回调
-- function ChargeCallBack(uid, shopId, chips)
--     if shopId == 401 then
--         local datainfo = Get(uid)
--         local rgold = chips * 2
--         if rgold > datainfo.goldRecv then
--             rgold = datainfo.goldRecv
--         end
--         local goldCharge = math.floor(datainfo.goldRecv*(table_cofrinho_other[1].goldPrice/100))
--         goldCharge = math.floor(goldCharge/100)
--         goldCharge = goldCharge*100
--         if goldCharge<=chips then
--             rgold = datainfo.goldRecv
--             datainfo.goldRecv=0
--         else
--             datainfo.goldRecv = datainfo.goldRecv - rgold
--         end
--         if rgold<=0 then
--             return
--         end
--         datainfo.latestRecvGold = rgold
--         BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, rgold, Const.GOODS_SOURCE_TYPE.COFRINHO)
--         unilight.update(Table,datainfo._id,datainfo)
--         local sendres = {}
--         sendres['do'] = 'Cmd.CofrinhoRecvGoldCmd_S'
--         sendres['data'] = {
--             errno = 0,
--             rgold = rgold,
--             goldRecv = datainfo.goldRecv,
--             curGold = datainfo.curGold,
--         }
--         unilight.sendcmd(uid,sendres)
--     end
-- end

-- --[[
--     获取存钱罐 金银猪信息
--     savingpot_silver savingpot_gold
-- ]]
-- function GetCofrinInfo(uid)
--     local datainfo = Get(uid)
--     Settle(datainfo)
--     return {
--         savingpot_silver = datainfo.silverTolGold,
--         savingpot_gold = datainfo.goldTolGold,
--         latestRecvGold = datainfo.latestRecvGold,
--     }
-- end

-- --[[
--     获取存钱罐状态
--     silverRecv 当前可领银罐
--     goldRecv    当前可领金罐
--     curSilver  当前银罐值
--     curGold    当前金罐值
--     beforlost   前一日输赢
-- ]]
-- function GetCofrinStatus(uid)
--     local datainfo = Get(uid)
--     Settle(datainfo)
--     return {
--         silverRecv = datainfo.silverRecv,
--         goldRecv = datainfo.goldRecv,
--         curSilver = datainfo.curSilver,
--         curGold = datainfo.curGold,
--         beforlost = datainfo.beforlost,
--     }
-- end
-- --存钱罐结算
-- function ConfrinLogin(uid)
--     local datainfo = Get(uid)
--     Settle(datainfo)
-- end