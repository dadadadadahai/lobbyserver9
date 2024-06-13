-- 兑换提现模块
module('WithdrawCash', package.seeall)
WithdrawCash = WithdrawCash or {}
-- 兑换提现数据表
WithdrawCash.DB_Name = "withdrawcash"
WithdrawCash.DB_History_Name = "withdrawcashhistory"
WithdrawCash.Table_Gold = import "table/table_withdrawcash_gold"
WithdrawCash.Table_Other = import "table/table_withdrawcash_other"
WithdrawCash.Table_Vip = import "table/table_nvip_level"
local tableMailConfig = import "table/table_mail_config"
-- 公共调用

-- 构造数据存档
WithdrawCash.UserGameConstruct = function (uid)
    -- 获取兑换模块数据库信息
    local withdrawCashInfo = unilight.getdata(WithdrawCash.DB_Name, uid)
    -- 获取兑换模块数据库信息
    if table.empty(withdrawCashInfo) then
        withdrawCashInfo = {
            _id = uid, -- 玩家ID
            serviceCharge = WithdrawCash.Table_Other[1].firstServiceCharge, -- 手续费
            refreshTime = os.time(), -- 刷新时间
            statement = 0, -- 充值流水(可提现金额)
            telephone = nil, -- 电话
            email = nil, -- 邮箱
            cpf = nil, -- cpf
            name = nil, -- 姓名
            chavePix = nil, -- chavePix
            flag = 0,   -- Flag 0 只有姓名和CPF 1 额外增加一个Phone 2 额外增加一个Email
            history = {}, -- 历史记录   (废弃字段)
            totalWithdrawal = 0, -- 总提现金额
            specialWithdrawal = 0,  -- 特殊提现金额
            withdrawcashNum = 0, -- 今日兑换次数
            clearTime = os.time(), -- 清除数据时间
        }
        unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
    else
        -- 判断清除数据
        WithdrawCash.ClearInfo(withdrawCashInfo)
    end
    return withdrawCashInfo
end
-- 兑换界面信息
WithdrawCash.GetWithdrawCashInfo = function(uid)
    -- 获取兑换模块数据库信息
    local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    local userInfo = unilight.getdata('userinfo',uid)
    -- 可兑换金额列表
    local exchangeGoldList = {}
    -- 玩家充值金币
    local totalRechargeChips = chessuserinfodb.GetChargeInfo(uid)
    -- -- 未提现则增加30档位
    -- if userInfo.status.chipsWithdrawNum == 0 and userInfo.status.chipsWithdraw == 0 then
    --     table.insert(exchangeGoldList,3000)
    -- end
    -- 循环插入金额列表数据
    for i, v in ipairs(WithdrawCash.Table_Gold) do
        table.insert(exchangeGoldList,v.dinheiro)
    end
    -- 返回信息
    local res = {
        exchangeGoldList = exchangeGoldList,                                                                        -- 可兑换金额列表
        serviceCharge = withdrawCashInfo.serviceCharge,                                                             -- 手续费
        exchangeFlag = userInfo.property.totalRechargeChips > 0,                                                    -- 是否可以兑换(改为是否充值过)
        -- history = withdrawCashInfo.history,                                                                      -- 历史记录
        statement = withdrawCashInfo.statement,                                                                     -- 流水(可提现金额)
        telephone = withdrawCashInfo.telephone,                                                                     -- 电话
        email = withdrawCashInfo.email,                                                                             -- 邮件
        cpf = withdrawCashInfo.cpf,                                                                                 -- cpf
        chavePix = withdrawCashInfo.chavePix,                                                                       -- PIX
        name = withdrawCashInfo.name,                                                                               -- 姓名
        flag = withdrawCashInfo.flag,                                                                               -- FLAG
        withdrawcashNum = withdrawCashInfo.withdrawcashNum,                                                         -- 今日兑换次数
        -- sumWithdrawcashNum = WithdrawCash.GetWithdrawCashNum(uid),                                                  -- 今日总可提现次数
        minDinheiro = WithdrawCash.Table_Other[1].minDinheiro,                                                      -- 最低提现金额
        totalWithdrawal = withdrawCashInfo.totalWithdrawal,                                                         -- 玩家总提现金额
        specialWithdrawal = withdrawCashInfo.specialWithdrawal,                                                     -- 玩家特殊提现金额
        loginPlatIds = userInfo.status.loginPlatIds
    }
    -- 如果是首次提现则最低提现金额修改为配置表
    -- if userInfo.status.chipsWithdraw == 0 or userInfo.status.chipsWithdrawNum == 0 then
    -- if userInfo.status.rechargeNum < 2 and userInfo.status.chipsWithdrawNum == 0 and userInfo.status.chipsWithdraw == 0 then
    if userInfo.status.chipsWithdrawNum == 0 and userInfo.status.chipsWithdraw == 0 then
        res.minDinheiro = WithdrawCash.Table_Other[1].firstMinDinheiro                                              -- 未提现过的最低提现金额
    end
    -- res.exchangeFlag = withdrawCashInfo.statement >= WithdrawCash.Table_Other[1].minDinheiro and os.time() >= withdrawCashInfo.refreshTime and withdrawCashInfo.withdrawcashNum < res.sumWithdrawcashNum
    -- if not (withdrawCashInfo.cpf == withdrawCashInfo.chavePix) then
    --     res.chavePix = withdrawCashInfo.chavePix
    -- end
    return res
end
-- 兑换金额操作
WithdrawCash.AmountExchange = function(uid, dinheiro, type)
    if type == 1 then
        
        local userInfo = unilight.getdata('userinfo', uid)
        -- 判断是否低于最少提现金额  首次提现和后续的最低金额不同
        if userInfo.status.chipsWithdraw == 0 or userInfo.status.chipsWithdrawNum == 0 then
            if dinheiro < WithdrawCash.Table_Other[1].firstMinDinheiro then
                local res = {
                    -- errno = ErrorDefine.WITHDRAWCASH_DINHEIRO_ERROR,
                    errno = ErrorDefine.WITHDRAWCASH_MINDINHEIRO_ERROR,
                    -- desc = "低于最少提现金额",
                }
                return res
            end
        else
            if dinheiro < WithdrawCash.Table_Other[1].minDinheiro then
                local res = {
                    -- errno = ErrorDefine.WITHDRAWCASH_DINHEIRO_ERROR,
                    errno = ErrorDefine.WITHDRAWCASH_MINDINHEIRO_ERROR,
                    -- desc = "低于最少提现金额",
                }
                return res
            end
        end
        -- 判断玩家是否登陆过客户端     1 安卓网页 2 苹果网页 3 安卓客户端 4 苹果客户端
        -- 目前只有安卓网页不能提
        -- if userInfo.status.loginPlatId == 1 then
        --     local res = {
        --         -- errno = ErrorDefine.WITHDRAWCASH_DINHEIRO_ERROR,
        --         errno = ErrorDefine.WITHDRAWCASH_NOLOGINAPK_ERROR,
        --         -- desc = "低于最少提现金额",
        --     }
        --     return res
        -- end
        -- 判断是否充值
        if userInfo.property.totalRechargeChips == 0 then
            local res = {
                errno = ErrorDefine.WITHDRAWCASH_NORECHARGE_ERROR
            }
            return res
        end
        -- 判断是否绑定手机
        -- if userInfo.base.phoneNbr == "" then
        --     local res = {
        --         errno = ErrorDefine.WITHDRAWCASH_UNTETHEREDPHONE_ERROR
        --     }
        --     return res
        -- end
        -- 获取兑换模块数据库信息
        local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
        -- local withdrawCashInfo = unilight.getdata(WithdrawCash.DB_Name, uid)
        -- -- 判断是否需要初始化
        -- if table.empty(withdrawCashInfo) then
        --     withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
        --     unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
        -- end
        -- 判断是否可以兑换
        if withdrawCashInfo.cpf == nil then
            local res = {
                errno = ErrorDefine.WITHDRAWCASH_NOCPF_ERROR,
            }
            return res
        elseif withdrawCashInfo.refreshTime > os.time()then
            local res = {
                errno = ErrorDefine.WITHDRAWCASH_REFRESHTIME_ERROR,
                -- desc = "刷新时间不够",
            }
            return res
        -- elseif withdrawCashInfo.statement < dinheiro then
        elseif userInfo.property.chips < dinheiro then
            local res = {
                errno = ErrorDefine.WITHDRAWCASH_QUOTA_ERROR,
                -- desc = "剩余可提现额度不足",
            }
            return res
        -- elseif withdrawCashInfo.withdrawcashNum >= WithdrawCash.GetWithdrawCashNum(uid) then
        --     local res = {
        --         errno = ErrorDefine.WITHDRAWCASH_RESIDUALNUM_ERROR,
        --         -- desc = "剩余次数不足",
        --     }
        --     return res
        end
        -- 增加兑换次数
        withdrawCashInfo.withdrawcashNum = withdrawCashInfo.withdrawcashNum + 1
        -- 扣除金额
        -- local moedas = dinheiro * (1 + withdrawCashInfo.serviceCharge / 10000)
        local moedas = dinheiro
        local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, moedas, "兑换扣费")
        if ok == false then
            local res = {
                errno = ErrorDefine.CHIPS_NOT_ENOUGH,
                -- desc = "当前余额不足",
            }
            return res
        end
        -- 减少可提现金额
        -- withdrawCashInfo.statement = withdrawCashInfo.statement - moedas
        -- 修改可以提现出现的金额  内扣
        dinheiro = math.floor(dinheiro * (1 - withdrawCashInfo.serviceCharge / 10000))
        -- 增长服务费用
        withdrawCashInfo.serviceCharge = withdrawCashInfo.serviceCharge + WithdrawCash.Table_Other[1].addServiceCharge
        -- 增加冷却时间
        withdrawCashInfo.refreshTime = os.time() + WithdrawCash.Table_Other[1].intervalMinutes * 60
        -- 增加总提现次数
        local userInfo = unilight.getdata('userinfo',uid)
        userInfo.status.chipsWithdrawNum = userInfo.status.chipsWithdrawNum + 1
        -- 统计总提现金额  从扣除手续费后金额变为扣除前金额
        -- userInfo.status.chipsWithdraw = userInfo.status.chipsWithdraw + dinheiro
        userInfo.status.chipsWithdraw = userInfo.status.chipsWithdraw + moedas
        unilight.savedata('userinfo',userInfo)
        -- 添加订单
        local orderId = WithdrawCash.SetOrder(uid, moedas, dinheiro, withdrawCashInfo, 1)
        -- 保存记录
        -- 同步历史记录信息  数据搬迁
        local withdrawCashHistoryInfo = unilight.getdata(WithdrawCash.DB_History_Name,uid)
        -- 获取兑换模块数据库信息
        if table.empty(withdrawCashHistoryInfo) then
            withdrawCashHistoryInfo = {
                _id = uid, -- 玩家ID
                history = {}, -- 历史记录
            }
            -- 如果有旧数据则同步数据
            if table.empty(withdrawCashInfo.history) == false then
                withdrawCashHistoryInfo.history = withdrawCashInfo.history
            end
        end
        table.insert(withdrawCashHistoryInfo.history,1,{orderId = orderId,type = type, chavePix = withdrawCashInfo.chavePix, hora = os.time(), moedas = moedas, dinheiro = dinheiro, state = STATE_WAIT_REVIEW})
    
        -- 保存数据库信息
        unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
        unilight.savedata(WithdrawCash.DB_History_Name,withdrawCashHistoryInfo)
        local res = {
            errno = ErrorDefine.SUCCESS,
        }
        -- 发送邮件
        local mailInfo = {}
        local mailConfig = tableMailConfig[44]
        mailInfo.charid = uid
        mailInfo.subject = mailConfig.subject
        mailInfo.type = 0
        mailInfo.attachment = {}
        mailInfo.extData = {}
        mailInfo.content = string.format(mailConfig.content,orderId,moedas/100)
        ChessGmMailMgr.AddGlobalMail(mailInfo)
        -- -- 如果提现金额小于配置表的直接提现  那么直接同意不需要后台
        -- if moedas <= parameterConfig[35].Parameter then
        --     WithdrawCash.ChangeState(orderId, WithdrawCash.STATE_UNDER_REVIEW)
        -- end
        return res
    elseif type == 2 then
        -- 获取兑换模块数据库信息
        local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
        if withdrawCashInfo.specialWithdrawal < 1000 or withdrawCashInfo.specialWithdrawal < dinheiro then
            local res = {
                errno = ErrorDefine.CHIPS_NOT_ENOUGH,
            }
            return res
        end
        local moedas = dinheiro
        -- 添加订单
        local orderId = WithdrawCash.SetOrder(uid, moedas, dinheiro, withdrawCashInfo, 3)
        -- 保存记录
        -- 同步历史记录信息  数据搬迁
        local withdrawCashHistoryInfo = unilight.getdata(WithdrawCash.DB_History_Name,uid)
        -- 获取兑换模块数据库信息
        if table.empty(withdrawCashHistoryInfo) then
            withdrawCashHistoryInfo = {
                _id = uid, -- 玩家ID
                history = {}, -- 历史记录
            }
            -- 如果有旧数据则同步数据
            if table.empty(withdrawCashInfo.history) == false then
                withdrawCashHistoryInfo.history = withdrawCashInfo.history
            end
        end
        table.insert(withdrawCashHistoryInfo.history,1,{orderId = orderId,type = type, chavePix = withdrawCashInfo.chavePix, hora = os.time(), moedas = moedas, dinheiro = dinheiro, state = STATE_WAIT_REVIEW})
        withdrawCashInfo.specialWithdrawal = withdrawCashInfo.specialWithdrawal - dinheiro
        -- 增加总提现次数
        local userInfo = unilight.getdata('userinfo',uid)
        userInfo.status.chipsWithdrawNum = userInfo.status.chipsWithdrawNum + 1
        -- 统计总提现金额  从扣除手续费后金额变为扣除前金额
        userInfo.status.chipsWithdraw = userInfo.status.chipsWithdraw + moedas
        unilight.savedata('userinfo',userInfo)
        -- 保存数据库信息
        unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
        unilight.savedata(WithdrawCash.DB_History_Name,withdrawCashHistoryInfo)
        -- 发送邮件
        local mailInfo = {}
        local mailConfig = tableMailConfig[44]
        mailInfo.charid = uid
        mailInfo.subject = mailConfig.subject
        mailInfo.content = string.format(mailConfig.content,orderId,moedas/100)
        mailInfo.type = 0
        mailInfo.attachment = {}
        mailInfo.extData = {}
        ChessGmMailMgr.AddGlobalMail(mailInfo)
        local res = {
            errno = ErrorDefine.SUCCESS,
        }
        return res
    end
end
-- 判断金额是否合法
WithdrawCash.GoldLegal = function(dinheiro)
    -- 循环数据表判断是否存在数值
    for i, v in ipairs(WithdrawCash.Table_Gold) do
        if v.dinheiro == dinheiro then
            return true
        end
    end
    return false
end
-- 获取历史记录信息
WithdrawCash.GetHistory = function(uid)
    -- 获取兑换模块数据库信息
    local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    -- 同步历史记录信息  数据搬迁
    local withdrawCashHistoryInfo = unilight.getdata(WithdrawCash.DB_History_Name,uid)
    if table.empty(withdrawCashHistoryInfo) then
        withdrawCashHistoryInfo = {
            _id = uid, -- 玩家ID
            history = {}, -- 历史记录
        }
        -- 如果有旧数据则同步数据
        if table.empty(withdrawCashInfo.history) == false then
            withdrawCashHistoryInfo.history = withdrawCashInfo.history
        end
    end
    local res = {
        history = withdrawCashHistoryInfo.history,
    }
    return res
end
-- 获取提现次数
WithdrawCash.GetWithdrawCashNum = function(uid)
    -- -- 获取当前玩家VIP等级
    -- local vipLevel = nvipmgr.GetVipLevel(uid)
    -- -- 循环查找兑换次数
    -- for _, v in ipairs(WithdrawCash.Table_Vip) do
    --     if v.vipLevel == vipLevel then
    --         return v.withdrawcashNum
    --     end
    -- end
    return 0
end

--------------------------------------------------------    清除调用    --------------------------------------------------------

WithdrawCash.ClearInfo = function(withdrawCashInfo)
    -- 判断是否返回
    if withdrawCashInfo.clearTime == nil then
        withdrawCashInfo.clearTime = os.time()
    end
    -- if chessutil.DateDayDistanceByTimeGet(withdrawCashInfo.clearTime) == 0 then
    if chessutil.GetMorningDayNo() - chessutil.GetMorningDayNo(withdrawCashInfo.clearTime) <= 0 then
        return
    end
    -- 循环配置表重置数据
    withdrawCashInfo.serviceCharge = WithdrawCash.Table_Other[1].firstServiceCharge -- 手续费
    withdrawCashInfo.withdrawcashNum = 0 -- 兑换次数
    -- 历史记录中的初始下标
    local point = 1
    -- -- 循环删除过时历史记录
    -- while(point <= #withdrawCashInfo.history) do 
    --     if (chessutil.GetMorningDayNo() - chessutil.GetMorningDayNo(withdrawCashInfo.history[point].hora)) > 7 then 
    --         table.remove(withdrawCashInfo.history,point)
    --     else
    --         point = point + 1
    --     end
    -- end
    withdrawCashInfo.clearTime = os.time()
    unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
end


--------------------------------------------------------    时间调用    --------------------------------------------------------

-- 每日凌晨重置手续费
WithdrawCash.ResetServiceCharge = function()
    -- 获取整体模块数据信息
    local withdrawCashInfo = unilight.getAll(WithdrawCash.DB_Name)
    -- 循环配置表重置数据
    for id, data in ipairs(withdrawCashInfo) do
        data.serviceCharge = WithdrawCash.Table_Other[1].firstServiceCharge -- 手续费
        data.withdrawcashNum = 0 -- 兑换次数
        unilight.savedata(WithdrawCash.DB_Name,data)
    end
end

-- 每日凌晨清除多于30天的历史记录
WithdrawCash.ClearHistory = function()
    -- -- 获取整体模块数据信息
    -- local withdrawCashInfo = unilight.getAll(WithdrawCash.DB_Name)
    -- -- 循环配置表删除数据
    -- for id, data in ipairs(withdrawCashInfo) do
    --     -- 历史记录中的初始下标
    --     local point = 1
    --     -- 循环删除过时历史记录
    --     while(point <= #data.history) do 
    --         if (chessutil.GetMorningDayNo() - chessutil.GetMorningDayNo(data.history[point].hora)) > 30 then 
    --             table.remove(data.history,point)
    --         else
    --             point = point + 1
    --         end
    --     end
    --     unilight.savedata(WithdrawCash.DB_Name,data)
    -- end
end

--------------------------------------------------------    外部调用    --------------------------------------------------------

function GetWithdrawcashInfo(uid)
    -- 获取兑换模块数据库信息
    local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    -- local withdrawCashInfo = unilight.getdata(WithdrawCash.DB_Name, uid)
    -- -- 判断是否需要初始化
    -- if table.empty(withdrawCashInfo) then
    --     withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
    --     unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
    -- end

    local res = {
        cancovertchips = withdrawCashInfo.statement,                                -- 充值流水(可提现金额)
        totalcovertchips = withdrawCashInfo.totalWithdrawal,                        -- 总提现金额
        chavePix = withdrawCashInfo.chavePix,                                       -- chavePix账号
    }
    return res
end

-- 更改Pix渠道
function ChangeChavePixChannel(uid,flag)
    -- Flag 0 只有姓名和CPF 1 额外增加一个Phone 2 额外增加一个Email
    if flag == 0 or flag == 1 or flag == 2 then
        -- 获取兑换模块数据库信息
        local withdrawCashInfo = WithdrawCash.UserGameConstruct(uid)
        withdrawCashInfo.flag = flag
        unilight.savedata(WithdrawCash.DB_Name,withdrawCashInfo)
    end
end