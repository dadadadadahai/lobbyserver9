--游戏处理大厅充值相关


--大厅通知游戏有玩家充值成功
--[[
    _id; #订单ID
    uid  #玩家id 
    subTime #订单提交时间
    shopId #商品id
    subPrice #提交金额
    fee #fee手续费
    backTime #回调时间
    backPrice #回调金额
    payType #支付方式
    order_no #支付平台,订单id
    status #订单状态, #订单状态 0 已提交 1 已支付， 2，已发放
    ]]
Lby.CmdReqUserRechargeLobby_CS = function(cmd, lobbytask) 
    local orderInfo = cmd.data
    --立即通知大厅
    local laccount = go.roomusermgr.GetRoomUserById(orderInfo.uid)
    --在线才处理
    if laccount ~= nil then
        if ShopMgr.IsExistHistoryOrder(orderInfo.uid, orderInfo._id) == false then
            ShopMgr.BuyGoods(orderInfo.uid, orderInfo.shopId, orderInfo)
        else
            unilight.error(string.format("大厅通知游戏充值成功，玩家:%d, 出现重复订单:%s", orderInfo.uid, table2json(orderInfo)))
        end
        unilight.success(lobbytask, cmd)
    end

end 


--大厅通知游戏有玩家充值成功
--[[
    _id; #订单ID
    uid  #玩家id 
    subTime #订单提交时间
    shopId #商品id
    subPrice #提交金额
    fee #fee手续费
    backTime #回调时间
    backPrice #回调金额
    payType #支付方式
    order_no #支付平台,订单id
    status #订单状态, #订单状态 0 已提交 1 已支付， 2，已发放
    ]]
    Lby.CmdReqUserWithdrawCashSuccessLobby_CS = function(cmd, lobbytask) 
        local orderInfo = cmd.data
        --立即通知大厅
        local laccount = go.roomusermgr.GetRoomUserById(orderInfo.uid)
        --在线才处理
        if laccount ~= nil then
            WithdrawCash.ChangeState(orderInfo._id, WithdrawCash.STATE_SUCCESS_FINISH)
            UserInfo.UserWithdrawSucces(orderInfo.uid, orderInfo)
            -- unilight.success(lobbytask, cmd)
        end
    end 
    Lby.CmdReqUserWithdrawCashFailureLobby_CS = function(cmd, lobbytask) 
        local orderInfo = cmd.data
        --立即通知大厅
        local laccount = go.roomusermgr.GetRoomUserById(orderInfo.uid)
        --在线才处理
        if laccount ~= nil then
            -- 改变状态
            WithdrawCash.ChangeState(orderInfo._id, WithdrawCash.STATE_FAILURE_FINISH)
            -- unilight.success(lobbytask, cmd)
        end
    end 