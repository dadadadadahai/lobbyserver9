-- 兑换提现模块
module('WithdrawCash', package.seeall)
WithdrawCash = WithdrawCash or {}
DB_Log_Name = "withdrawcashlog"

-- 提现日志 现推广
WithdrawCash.AddWithDrawCashLog = function(uid,type,addChips)
    unilight.savedata(DB_Log_Name,{
        uid = uid,
        type = type,
        addChips = addChips,
    })
end
