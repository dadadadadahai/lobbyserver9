module('TeamRebate', package.seeall)
-- 领取
function TeamRebateGet(uid)
    -- 玩家信息
    local userInfo = unilight.getdata('userinfo',uid)
    local data = unilight.getdata('extension_relation',uid)
    local amountavailablechip = data.amountavailablechip
    unilight.incdate('extension_relation', uid, {amountavailablechip=-amountavailablechip})
    -- 增加奖励
    -- BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD, amountavailablechip, Const.GOODS_SOURCE_TYPE.TEAMREBATE)
    -- 保存统计
    local userInfo = unilight.getdata('userinfo',uid)
    userInfo.property.totalteamrebatechips = userInfo.property.totalteamrebatechips + amountavailablechip
    unilight.savedata('userinfo',userInfo)
    local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    withdrawCashInfo.specialWithdrawal = withdrawCashInfo.specialWithdrawal + amountavailablechip
    unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
    local res = {
        rewardChips = amountavailablechip,
    }
    return res
end