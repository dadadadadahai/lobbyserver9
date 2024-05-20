-- 兑换提现模块
module('WithdrawCash', package.seeall)

function InviteWithdrawCashCommon(uid)
    local data = unilight.getdata('extension_relation',uid)
    if math.floor(data.rebatechip) < 1000 then
        return
    end
    -- 减少金额
    unilight.incdate('extension_relation', uid, {rebatechip=-math.floor(data.rebatechip)})
    -- 获取兑换模块数据库信息
    local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    -- 添加订单
    local orderId = WithdrawCash.SetOrder(uid, math.floor(data.rebatechip), math.floor(data.rebatechip), withdrawCashInfo, 2)
end