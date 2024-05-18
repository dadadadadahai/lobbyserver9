--处理来自游戏的消息

--游戏处理充值成功
Zone.CmdReqUserRechargeLobby_CS = function(cmd, zonetask) 
    local orderInfo = cmd.data
    orderInfo.status = Const.ORDER_STATUS.DELIVERY
    --增加一个当前金币
    orderInfo.curChips = chessuserinfodb.RUserChipsGet(orderInfo.uid)
    unilight.savedata("orderinfo", orderInfo )
    unilight.info("游戏充值成功回调:%s"..table2json(orderInfo))

    --如果在游戏服中充值到账，重新更新下订单总充值
    chessrechargemgr.UpdateOrderDayRecharge(orderInfo.uid)

end 


