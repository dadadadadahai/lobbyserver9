-- 兑换提现模块
module('WithdrawCash', package.seeall)
WithdrawCash = WithdrawCash or {}

-- 返回兑换页面信息
function CmdUserWithdrawCashInfoGet(uid)
    local withdrawCashInfo = WithdrawCash.GetWithdrawCashInfo(uid)
    -- local res = {
    --     errno = withdrawCashInfo.errno,
    --     exchangeGoldList = withdrawCashInfo.exchangeGoldList,
    --     serviceCharge = withdrawCashInfo.serviceCharge,
    --     exchangeFlag = withdrawCashInfo.exchangeFlag,
    --     -- history = withdrawCashInfo.history,
    --     cpf = withdrawCashInfo.cpf,
    --     name = withdrawCashInfo.name,
    --     name = withdrawCashInfo.name,
    -- }
    return withdrawCashInfo
end
-- 返回兑换结果
function CmdUserWithdrawCashRequest(uid, dinheiro, type)
    -- 进行金额兑换逻辑
    local amountExchangeInfo = WithdrawCash.AmountExchange(uid, dinheiro, type)
    if amountExchangeInfo.errno ~= ErrorDefine.SUCCESS then
        return amountExchangeInfo
    end
    -- 返回兑换页面信息
    local withdrawCashInfo = WithdrawCash.GetWithdrawCashInfo(uid)
    -- local res = {
    --     errno = amountExchangeInfo.errno,
    --     exchangeGoldList = withdrawCashInfo.exchangeGoldList,
    --     serviceCharge = withdrawCashInfo.serviceCharge,
    --     exchangeFlag = withdrawCashInfo.exchangeFlag,
    --     -- history = withdrawCashInfo.history,
    --     cpf = withdrawCashInfo.cpf,
    --     name = withdrawCashInfo.name,
    -- }
    return withdrawCashInfo
end
-- 返回兑换历史记录
function CmdUserWithdrawCashHistoryRequest(uid)
    local withdrawCashHistoryInfo = WithdrawCash.GetHistory(uid)
    local res = {
        history = withdrawCashHistoryInfo.history,
    }
    return res
end
-- 返回兑换CPF绑定结果
function CmdUserWithdrawCashCPFRequest(uid, cpf, name, flag, chavePix, email, telephone)
    -- 判断请求逻辑 有cpf和name代表绑定 没有代表请求是否绑定
    if cpf == nil or name == nil then
        -- 请求是否绑定
        local withdrawCashInfo = WithdrawCash.GetCpfInfo(uid)
        local res = {
            errno = withdrawCashInfo.errno,
            cpfFlag = withdrawCashInfo.cpfFlag,
        }
        return res
    else
        -- 绑定逻辑
        local withdrawCashInfo = WithdrawCash.BindingCpf(uid, cpf, name, flag, chavePix, email, telephone)
        local res = {
            errno = withdrawCashInfo.errno,
        }
        return res
    end

end