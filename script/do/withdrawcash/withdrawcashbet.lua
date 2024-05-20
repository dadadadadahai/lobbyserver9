-- 兑换提现模块
module('WithdrawCash', package.seeall)
WithdrawCash = WithdrawCash or {}
-- 流水表
local Table_XS = import "table/table_auto_prcent"
local table_autoControl_dc = import 'table/table_autoControl_dc'
local table_auto_addPro = import 'table/table_auto_addPro'
local clearMinNum = 200         -- 少于次数清零打马

-- 兑换功能获取金额提升(增加可提现金额)
WithdrawCash.AddBet = function(uid, addBet)
    -- 获取玩家信息
    local userInfo = unilight.getdata('userinfo',uid)
    -- 获取兑换模块数据库信息
    local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    if addBet < 0 then
        addBet = 0
    end
    -- 判断清零     携带金币<2 清零打马
    if chessuserinfodb.RUserChipsGet(uid) <= clearMinNum then
        withdrawCashInfo.statement = 0
    end
    withdrawCashInfo.statement = withdrawCashInfo.statement + addBet
    unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
end

-- 兑换功能打马金额减少(减少可提现金额)
WithdrawCash.ReduceBet = function(uid, reduceBet)
    -- 获取兑换模块数据库信息
    local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    -- 如果兑换流水已经为0直接返回
    if withdrawCashInfo.statement == 0 then
        return
    end
    -- 减少流水金额
    if withdrawCashInfo.statement <= reduceBet then
        withdrawCashInfo.statement = 0
    else
        withdrawCashInfo.statement = withdrawCashInfo.statement - reduceBet
    end
    -- 判断清零     携带金币<2 清零打马
    if chessuserinfodb.RUserChipsGet(uid) <= clearMinNum then
        withdrawCashInfo.statement = 0
    end
    -- 保存数据库信息
    unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
end

--------------------------------------------------------    公共接口    --------------------------------------------------------
WithdrawCash.GetBetInfo = function(uid,dataName,gameType,resInfo,isNormal,gameId)
    -- 兑换功能打马金额减少(减少可提现金额)
    WithdrawCash.ReduceBet(uid, resInfo.payScore)
end

-- 首充随机增加流水
function AddRandomStatement(uid)
    ----------------------------   从随机增加流水变为流水清零   ----------------------------
    local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    -- 增加流水金额
    withdrawCashInfo.statement = 0
    -- 保存数据库信息
    unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)

end