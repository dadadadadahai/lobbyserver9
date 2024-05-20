-- 兑换提现模块     订单功能
module('WithdrawCash', package.seeall)
WithdrawCash = WithdrawCash or {}
-- 兑换提现 订单数据表
WithdrawCash.DB_Order_Name = "withdrawcash_order"
local tableMailConfig = import "table/table_mail_config"
parameterConfig = import "table/table_parameter_parameter"
STATE_WAIT_REVIEW = 1           -- 订单状态 待审核
STATE_REFUSE = 2                -- 订单状态 已拒绝
STATE_SUCCESS = 3               -- 订单状态 兑换成功
STATE_FAILURE = 4               -- 订单状态 兑换失败
STATE_UNDER_REVIEW = 5          -- 订单状态 审核中
STATE_SUCCESS_FINISH = 6        -- 订单状态 已结束 成功
STATE_FAILURE_FINISH = 7        -- 订单状态 已结束 失败
STATE_IGNORE = 8                -- 订单状态 已忽略
-- 添加订单
WithdrawCash.SetOrder = function(uid, moedas, dinheiro, withdrawCashInfo, orderType)
    local userInfo = chessuserinfodb.RUserDataGet(uid)
    local data = {
        _id = WithdrawCash.CreateOrderId(),
        uid = uid,                                                          -- 玩家ID
        orderType = orderType,                                              -- 订单类型     1 兑换提现  2 推广提现
        name = withdrawCashInfo.name,                                       -- 玩家姓名
        cpf = withdrawCashInfo.cpf,                                         -- CPF
        chavePix = withdrawCashInfo.chavePix,                               -- chavePix
        chavePixNum = withdrawCashInfo.flag,                                -- chavePix类型  0 只有姓名和CPF 1 额外增加一个Phone 2 额外增加一个Email
        moedas = moedas,                                                    -- 消耗金币
        dinheiro = dinheiro,                                                -- 提现金额
        times = chessutil.FormatDateGet(),                                  -- 订单申请时间(直接返回date格式日期 弃用)
        timestamp = os.time(),                                              -- 订单申请时间(时间戳)
        finishTimes = 0,                                                    -- 订单结束时间(时间戳)
        state = STATE_WAIT_REVIEW,                                          -- 订单当前状态 1.待审核， 2.已拒绝 3.兑换成功, 4.兑换失败, 5.审核中, 6.订单完成, 7.订单失败已返回奖励
        orderId = "",                                                       -- 平台订单号
        channel = "",                                                       -- 通道名
        regFlag = userInfo.base.regFlag ,                                   -- 注册来源
        subplatid = userInfo.base.subplatid,                                -- 子渠道id
        payPlatId = 0,                                                      -- 提现渠道id
        totalRechargeChips = userInfo.property.totalRechargeChips,          -- 当日总充值
        regTime   = userInfo.status.registertimestamp,                      -- 玩家注册时间
        isSend      = false,                                                -- 是否发放运营后台
    }
    -- 保存订单信息
    local _,orderId = unilight.savedata(WithdrawCash.DB_Order_Name,data)
    -- 返回订单ID
    return orderId
end
-- 生成订单号
WithdrawCash.CreateOrderId = function()
    while true do
        -- 获取当前时间
        local date = chessutil.DateByFormatDateGet(chessutil.FormatDateGet())
        -- local orderId = (date.year..date.month..date.day..date.hour..date.min..date.sec)..tostring(math.random(10,99))
        local orderId = tonumber(os.time()..tostring(math.random(10,99)))
        orderId = orderId * 10 + parameterConfig[31].Parameter
        -- 验证重复
        if table.empty(unilight.getdata(WithdrawCash.DB_Order_Name, orderId)) then
            return orderId
        end
    end
end
--------------------------------------------------------    外部调用    --------------------------------------------------------
-- 查询订单     page为第几页 line为每页几条数据 state 为状态判断条件 不填为查询所有
WithdrawCash.QueryOrderInfo = function(page, line, state)
    local orderInfo
    if state ~= nil then
        local filter = unilight.eq('state',state)
        orderInfo = unilight.startChain().Table(WithdrawCash.DB_Order_Name).Filter(filter).Skip(line * page).Limit(line)
    else
        orderInfo = unilight.startChain().Table(WithdrawCash.DB_Order_Name).Skip(line * page).Limit(line)
    end
    return orderInfo
end
-- 改变状态
WithdrawCash.ChangeState = function(id, state)
    -- 获取订单数据信息
    local filter =  unilight.eq("_id", id)
    local covertInfos = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Filter(filter))	
    local orderInfo = covertInfos[1]
    -- 判断订单是否合法
    if orderInfo == nil then
        return
    end
    -- 修改状态信息
    orderInfo.state = state
    -- 如果是兑换功能
    local data = unilight.getdata(WithdrawCash.DB_Name, orderInfo.uid)
    if orderInfo.orderType == 1 then
        -- 对历史记录进行判断如果新历史记录表中没有字段值则同步历史记录并且删除withdrawcash表中历史记录内容
        -- 同步历史记录信息  数据搬迁
        local withdrawCashHistoryInfo = unilight.getdata(WithdrawCash.DB_History_Name,orderInfo.uid)
        if table.empty(withdrawCashHistoryInfo) then
            withdrawCashHistoryInfo = {
                _id = orderInfo.uid, -- 玩家ID
                history = {}, -- 历史记录
            }
            -- 如果有旧数据则同步数据
            if table.empty(data.history) == false then
                withdrawCashHistoryInfo.history = data.history
            end
        end

        for i, v in ipairs(withdrawCashHistoryInfo.history) do
            if v.orderId == orderInfo._id then
                v.state = state
            end
        end
        -- 判断提现成功并且是兑换功能的订单
        if state == STATE_SUCCESS_FINISH then
            -- 添加订单结束时间
            orderInfo.finishTimes = os.time()
            -- 添加兑换成功总金额
            -- 统计总提现金额  从扣除手续费后金额变为扣除前金额
            -- data.totalWithdrawal = data.totalWithdrawal + orderInfo.dinheiro
            data.totalWithdrawal = data.totalWithdrawal + orderInfo.moedas
            local mailInfo = {}
            local mailConfig = tableMailConfig[21]
            mailInfo.charid = data._id
            mailInfo.subject = mailConfig.subject
            mailInfo.content = string.format(mailConfig.content,orderInfo._id,orderInfo.moedas/100)
            mailInfo.type = 0
            mailInfo.attachment = {}
            mailInfo.extData = {}
            ChessGmMailMgr.AddGlobalMail(mailInfo)
            gamecommon.CashOutRtpRandom(data._id)
            --保存下日志
            chessrechargemgr.SaveRechargeWithdrawLog(data._id, 2, orderInfo.dinheiro)
        elseif state == STATE_REFUSE or state == STATE_FAILURE_FINISH then
            -- 增加兑换次数 订单和审核在同一天才添加次数
            if TaskMgr.IsSameDay(os.time(),chessutil.TimeByDateGet(orderInfo.times)) then
               data.withdrawcashNum = data.withdrawcashNum - 1 
            end
            -- 回退提现次数
            local userInfo = unilight.getdata('userinfo',orderInfo.uid)
            userInfo.status.chipsWithdrawNum = userInfo.status.chipsWithdrawNum - 1
            userInfo.status.chipsWithdraw = userInfo.status.chipsWithdraw - orderInfo.moedas
            unilight.savedata('userinfo',userInfo)
            local mailInfo = {}
            local mailConfig = tableMailConfig[22]
            mailInfo.charid = data._id
            mailInfo.subject = mailConfig.subject
            -- mailInfo.content = string.format(mailConfig.content,orderInfo.moedas/100,chessutil.FormatDateGet(nil,"%d/%m/%Y %H:%M:%S"))
            mailInfo.content = string.format(mailConfig.content,orderInfo._id,orderInfo.moedas/100)
            mailInfo.configId = 22
            mailInfo.type = 0
            mailInfo.attachment = {}
            mailInfo.extData = {}
            ChessGmMailMgr.AddGlobalMail(mailInfo)
            -- 增加奖励
            BackpackMgr.GetRewardGood(data._id, Const.GOODS_ID.GOLD, orderInfo.moedas, Const.GOODS_SOURCE_TYPE.WITHDRAWCASH)
        elseif state == STATE_UNDER_REVIEW then
            orderInfo.payPlatId = UserInfo.ReqWithDraw(orderInfo._id,orderInfo.orderType)
        end
        unilight.savedata(WithdrawCash.DB_Name, data)
        unilight.savedata(WithdrawCash.DB_History_Name,withdrawCashHistoryInfo)
    elseif orderInfo.orderType == 2 then
        if state == STATE_SUCCESS_FINISH then
            -- 添加订单结束时间
            orderInfo.finishTimes = os.time()
            local mailInfo = {}
            local mailConfig = tableMailConfig[21]
            mailInfo.charid = data._id
            mailInfo.subject = mailConfig.subject
            mailInfo.content = string.format(mailConfig.content,orderInfo._id,orderInfo.moedas/100)
            mailInfo.type = 0
            mailInfo.attachment = {}
            mailInfo.extData = {}
            -- 增加提现次数
            local userInfo = unilight.getdata('userinfo',orderInfo.uid)
            userInfo.status.promoteWithdawNum = userInfo.status.promoteWithdawNum + 1
            userInfo.status.promoteWithdaw = userInfo.status.promoteWithdaw + orderInfo.dinheiro
            unilight.savedata('userinfo',userInfo)
            ChessGmMailMgr.AddGlobalMail(mailInfo)
        elseif state == STATE_REFUSE or state == STATE_FAILURE_FINISH then
            -- 添加订单结束时间
            -- orderInfo.finishTimes = os.time()
            -- 推广失败 返回金钱
            unilight.incdate('extension_relation',data._id,{rebatechip = orderInfo.moedas})
            -- -- 减少提现次数
            -- local userInfo = unilight.getdata('userinfo',orderInfo.uid)
            -- userInfo.status.promoteWithdawNum = userInfo.status.promoteWithdawNum - 1
            -- userInfo.status.promoteWithdaw = userInfo.status.promoteWithdaw - orderInfo.dinheiro
            local mailInfo = {}
            local mailConfig = tableMailConfig[22]
            mailInfo.charid = data._id
            mailInfo.subject = mailConfig.subject
            mailInfo.content = string.format(mailConfig.content,orderInfo._id,orderInfo.moedas/100)
            mailInfo.type = 0
            mailInfo.attachment = {}
            mailInfo.extData = {}
            ChessGmMailMgr.AddGlobalMail(mailInfo)
        elseif state == STATE_UNDER_REVIEW then
            orderInfo.payPlatId = UserInfo.ReqWithDraw(orderInfo._id,orderInfo.orderType)
        end
    elseif orderInfo.orderType == 3 then
        -- 对历史记录进行判断如果新历史记录表中没有字段值则同步历史记录并且删除withdrawcash表中历史记录内容
        -- 同步历史记录信息  数据搬迁
        local withdrawCashHistoryInfo = unilight.getdata(WithdrawCash.DB_History_Name,orderInfo.uid)
        if table.empty(withdrawCashHistoryInfo) then
            withdrawCashHistoryInfo = {
                _id = orderInfo.uid, -- 玩家ID
                history = {}, -- 历史记录
            }
            -- 如果有旧数据则同步数据
            if table.empty(data.history) == false then
                withdrawCashHistoryInfo.history = data.history
            end
        end

        for i, v in ipairs(withdrawCashHistoryInfo.history) do
            if v.orderId == orderInfo._id then
                v.state = state
            end
        end
        -- 判断提现成功并且是兑换功能的订单
        if state == STATE_SUCCESS_FINISH then
            -- 添加订单结束时间
            orderInfo.finishTimes = os.time()
            -- 添加兑换成功总金额
            -- 统计总提现金额  从扣除手续费后金额变为扣除前金额
            -- data.totalWithdrawal = data.totalWithdrawal + orderInfo.dinheiro
            data.totalWithdrawal = data.totalWithdrawal + orderInfo.moedas
            local mailInfo = {}
            local mailConfig = tableMailConfig[51]
            mailInfo.charid = data._id
            mailInfo.subject = mailConfig.subject
            mailInfo.content = string.format(mailConfig.content,orderInfo._id,orderInfo.moedas/100)
            mailInfo.type = 0
            mailInfo.attachment = {}
            mailInfo.extData = {}

            ChessGmMailMgr.AddGlobalMail(mailInfo)
            gamecommon.CashOutRtpRandom(data._id)
            --保存下日志
            chessrechargemgr.SaveRechargeWithdrawLog(data._id, 2, orderInfo.dinheiro)
        elseif state == STATE_REFUSE or state == STATE_FAILURE_FINISH then
            -- 回退提现次数
            local userInfo = unilight.getdata('userinfo',orderInfo.uid)
            userInfo.status.promoteWithdawNum = userInfo.status.promoteWithdawNum - 1
            userInfo.status.promoteWithdaw = userInfo.status.promoteWithdaw - orderInfo.moedas
            unilight.savedata('userinfo',userInfo)
            local mailInfo = {}
            local mailConfig = tableMailConfig[52]
            mailInfo.charid = data._id
            mailInfo.subject = mailConfig.subject
            mailInfo.content = string.format(mailConfig.content,orderInfo._id,orderInfo.moedas/100)
            mailInfo.configId = 22
            mailInfo.type = 0
            mailInfo.attachment = {}
            mailInfo.extData = {}
            ChessGmMailMgr.AddGlobalMail(mailInfo)
            -- 增加余额
            data.specialWithdrawal = data.specialWithdrawal + orderInfo.moedas
        elseif state == STATE_UNDER_REVIEW then
            orderInfo.payPlatId = UserInfo.ReqWithDraw(orderInfo._id,orderInfo.orderType)
        end
        unilight.savedata(WithdrawCash.DB_Name, data)
        unilight.savedata(WithdrawCash.DB_History_Name,withdrawCashHistoryInfo)
    elseif orderInfo.orderType == 4 then
        -- 对历史记录进行判断如果新历史记录表中没有字段值则同步历史记录并且删除withdrawcash表中历史记录内容
        -- 同步历史记录信息  数据搬迁
        local withdrawCashHistoryInfo = unilight.getdata(WithdrawCash.DB_History_Name,orderInfo.uid)
        if table.empty(withdrawCashHistoryInfo) then
            withdrawCashHistoryInfo = {
                _id = orderInfo.uid, -- 玩家ID
                history = {}, -- 历史记录
            }
            -- 如果有旧数据则同步数据
            if table.empty(data.history) == false then
                withdrawCashHistoryInfo.history = data.history
            end
        end

        for i, v in ipairs(withdrawCashHistoryInfo.history) do
            if v.orderId == orderInfo._id then
                v.state = state
            end
        end
        -- 判断提现成功并且是兑换功能的订单
        if state == STATE_SUCCESS_FINISH then
            -- 添加订单结束时间
            orderInfo.finishTimes = os.time()
            -- 添加兑换成功总金额
            -- 统计总提现金额  从扣除手续费后金额变为扣除前金额
            -- data.totalWithdrawal = data.totalWithdrawal + orderInfo.dinheiro
            data.totalWithdrawal = data.totalWithdrawal + orderInfo.moedas
            local mailInfo = {}
            local mailConfig = tableMailConfig[54]
            mailInfo.charid = data._id
            mailInfo.subject = mailConfig.subject
            mailInfo.content = string.format(mailConfig.content,orderInfo._id,orderInfo.moedas/100)
            mailInfo.type = 0
            mailInfo.attachment = {}
            mailInfo.extData = {}

            ChessGmMailMgr.AddGlobalMail(mailInfo)
            gamecommon.CashOutRtpRandom(data._id)
            --保存下日志
            chessrechargemgr.SaveRechargeWithdrawLog(data._id, 2, orderInfo.dinheiro)
        elseif state == STATE_REFUSE or state == STATE_FAILURE_FINISH then
            local mailInfo = {}
            local mailConfig = tableMailConfig[55]
            mailInfo.charid = data._id
            mailInfo.subject = mailConfig.subject
            mailInfo.content = string.format(mailConfig.content,orderInfo._id,orderInfo.moedas/100)
            mailInfo.configId = 22
            mailInfo.type = 0
            mailInfo.attachment = {}
            mailInfo.extData = {}
            ChessGmMailMgr.AddGlobalMail(mailInfo)
            -- 增加余额
            data.specialWithdrawal = data.specialWithdrawal + orderInfo.moedas
        elseif state == STATE_UNDER_REVIEW then
            orderInfo.payPlatId = UserInfo.ReqWithDraw(orderInfo._id,orderInfo.orderType)
        end
        unilight.savedata(WithdrawCash.DB_Name, data)
        unilight.savedata(WithdrawCash.DB_History_Name,withdrawCashHistoryInfo)
    end
    -- 保存数据库
    unilight.savedata(WithdrawCash.DB_Order_Name, orderInfo)
end

-- 查询玩家统计提现金额
WithdrawCash.QueryTotalWithdrawal = function(uid)
    local withdrawInfo =  unilight.getdata(WithdrawCash.DB_Name,uid)
    if withdrawInfo ~= nil then
        return withdrawInfo.totalWithdrawal
    else
        return 0
    end
end
--检查是否有新订单发放奖励
function RefreshDiscountShop()
	local orderList = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Filter(unilight.eq("state", STATE_SUCCESS)))	
    for _, orderInfo in pairs(orderList) do
        -- 对运营后台发送数据
        if  orderInfo.isSend == nil then
            orderInfo.isSend = false
        end
        if orderInfo.isSend == false then
            orderInfo.isSend = true
            --后台数据统计
            ChessMonitorMgr.SendUserWithDrawToMonitor(orderInfo.uid, orderInfo)
            unilight.savedata('withdrawcash_order',orderInfo)
        end
        
        --在大厅
        local laccount = go.roomusermgr.GetRoomUserById(orderInfo.uid)
        if laccount ~= nil then
            WithdrawCash.ChangeState(orderInfo._id, STATE_SUCCESS_FINISH)
            UserInfo.UserWithdrawSucces(orderInfo.uid, orderInfo)
        else
            --在其它进程
            -- local userInfo = chessuserinfodb.RUserInfoGet(orderInfo.uid)
            -- local gameInfo = userInfo.gameInfo
            -- local zoneInfo = ZoneInfo.GetZoneInfoByGameIdZoneId(gameInfo.gameId, gameInfo.zoneId)
            local zoneInfo = backRealtime.lobbyOnlineUserManageMap[orderInfo.uid]
            if zoneInfo ~= nil then
                zoneInfo.zone:SendCmdToMe("Cmd.ReqUserWithdrawCashSuccessLobby_CS",orderInfo)
                print('send to other')
            end
        end
    end
	local orderList = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Filter(unilight.eq("state", STATE_FAILURE)))	
    for _, orderInfo in pairs(orderList) do
        --在大厅
        local laccount = go.roomusermgr.GetRoomUserById(orderInfo.uid)
        if laccount ~= nil then
            -- 改变状态
            WithdrawCash.ChangeState(orderInfo._id, STATE_FAILURE_FINISH)
        else
            --在其它进程
            -- local userInfo = chessuserinfodb.RUserInfoGet(orderInfo.uid)
            -- local gameInfo = userInfo.gameInfo
            local zoneInfo = backRealtime.lobbyOnlineUserManageMap[orderInfo.uid]
            if zoneInfo ~= nil then
                zoneInfo.zone:SendCmdToMe("Cmd.ReqUserWithdrawCashFailureLobby_CS",orderInfo)
            end
        end
    end

    local orderList = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Filter(unilight.eq("state", STATE_REFUSE)))	
    for _, orderInfo in pairs(orderList) do
        --在大厅
        local laccount = go.roomusermgr.GetRoomUserById(orderInfo.uid)
        if laccount ~= nil then
            -- 改变状态
            WithdrawCash.ChangeState(orderInfo._id, STATE_REFUSE)
        else
            --在其它进程
            -- local userInfo = chessuserinfodb.RUserInfoGet(orderInfo.uid)
            -- local gameInfo = userInfo.gameInfo
            local zoneInfo = backRealtime.lobbyOnlineUserManageMap[orderInfo.uid]
            if zoneInfo ~= nil then
                zoneInfo.zone:SendCmdToMe("Cmd.ReqUserWithdrawCashReFuseLobby_CS",orderInfo)
            end
        end
    end


    -- 提现金额小于配置直接同意
    local orderList = unilight.chainResponseSequence(unilight.startChain().Table("withdrawcash_order").Filter(unilight.a(unilight.eq("state", STATE_WAIT_REVIEW),unilight.le("moedas",parameterConfig[35].Parameter))))	
    for _, orderInfo in pairs(orderList) do
        WithdrawCash.ChangeState(orderInfo._id, STATE_UNDER_REVIEW)
        -- --在大厅
        -- local laccount = go.roomusermgr.GetRoomUserById(orderInfo.uid)
        -- if laccount ~= nil then
        --     WithdrawCash.ChangeState(orderInfo._id, STATE_UNDER_REVIEW)
        -- else
        --     --在其它进程
        --     -- local userInfo = chessuserinfodb.RUserInfoGet(orderInfo.uid)
        --     -- local gameInfo = userInfo.gameInfo
        --     local zoneInfo = backRealtime.lobbyOnlineUserManageMap[orderInfo.uid]
        --     if zoneInfo ~= nil then
        --         zoneInfo.zone:SendCmdToMe("Cmd.ReqUserWithdrawCashSuccessLobby_CS",orderInfo)
        --     end
        -- end
    end
end