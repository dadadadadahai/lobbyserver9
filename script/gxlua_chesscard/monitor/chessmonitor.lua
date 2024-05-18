module('ChessMonitorMgr', package.seeall) 

--玩家登陆【运营后台 byx】
function SendUserLoginToMonitor(uid)
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
	local laccount = go.accountmgr.GetAccountById(uid)
    local msg = {
        data  = {
            userid 		= userInfo.uid, -- // 角色ID
            username 	= userInfo.base.nickname, -- // 角色名称
            accountid 	= userInfo.uid, -- // 账号ID
            accountname	= userInfo.base.plataccount, -- // 账号名称
            platid      = userInfo.base.platid,   -- // 渠道ID，目前accountid里面包含了渠道ID，如不包含可通过该字段传送
            mobilenum   = userInfo.base.phoneNbr,   --手机号码

        },

        ip		    = laccount.GetLoginIp(),--登陆ip
        imei		= userInfo.base.gpsAdid,--设备码
        adcode      = userInfo.base.adcode, --// 广告码
        -- extdata     = userInfo.base.campaign,--来源
        extdata     =   '',--来源
        sid         = 1, -- // 平台标识，1、IOS，2、android，3、windowsphone, 4、web
        onlinetime	= 0, -- // 累计在线时间，从创建至今 //20161111
        userlevel	= 1, -- // 角色等级
        viplevel	= userInfo.property.vipLevel, -- // vip等级
        gold		= chessuserinfodb.RUserChipsGet(uid), -- // 玩家剩余金币，充值获得的
        goldgive	= 0,  -- // 玩家剩余金币，充值赠送或其他赠送获得
        money		= 0,  -- // 除金币外，最重要的一种游戏币的数量
        createtime  = userInfo.status.registertimestamp, -- // 注册时间
    }
    go.buildProtoFwdServer("*Smd.LoginUserDataMonitorSmd_C", table2json(msg), "MS")
end


--玩家退出
function SendUserLogoutToMonitor(uid)

    print('uid chessuserinfodb.RUserInfoGet',uid)
    local userInfo = chessuserinfodb.RUserInfoGet(uid)
	local laccount = go.accountmgr.GetAccountById(uid)
    local msg = {

        data  = {
            userid 		= userInfo.uid, -- // 角色ID
            username 	= userInfo.base.nickname, -- // 角色名称
            accountid 	= userInfo.uid, -- // 账号ID
            accountname	= userInfo.base.plataccount, -- // 账号名称
            platid      = userInfo.base.platid,   -- // 渠道ID，目前accountid里面包含了渠道ID，如不包含可通过该字段传送
            mobilenum   = userInfo.base.phoneNbr,   --手机号码
        },

        sceneid     = 0,     --; // 登出时的玩家所在场景
        taskid      = "",     --; // 登出时最后接的任务ID
        level       = 0,     --; // 登出时的等级
	    viplevel	= userInfo.property.vipLevel, --; // 20161111  新加
	    onlinetime	= os.time()  - userInfo.status.logintimestamp ,      --; // 累计在线时间
	    isguid		= 0,      --// 当前指引
	    power		= 0,      -- // 当前战力
	    gold		= chessuserinfodb.RUserChipsGet(uid), -- // 当前剩余金币，充值获得
	    goldgive	= 0,      --// 当前剩余金币，充值赠送或其他赠送获得
	    money		= 0,      --// 除金币外最重要的游戏币的数量
    }
    -- go.buildProtoFwdServer("*Smd.LogoutUserDataMonitorSmd_C", table2json(msg), "MS")
    --只统计游戏内时间
    if unilight.islobbyserver()  == false then
        local data = {}
        data.msg = msg
        data.msgName = "*Smd.LogoutUserDataMonitorSmd_C"
        ChessToLobbyMgr.SendCmdToLobby("Cmd.ReqForwardToMonitor_CS", data)
        unilight.info("LogoutUserDataMonitorSmd_C="..table2json(msg))
    end
end

--[[
    orderInfo
    {
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
    }
]]
--玩家充值
function SendUserRechargeToMonitor(uid, orderInfo)

    --不是真实充值，不通知后台
    if orderInfo._id == nil then
        unilight.info("不是真实充值不通知后台:"..table2json(orderInfo))
        return
    end

    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    local msg = 
    {
        data  = {
            userid 		= userInfo.uid, -- // 角色ID
            username 	= userInfo.base.nickname, -- // 角色名称
            accountid 	= userInfo.uid, -- // 账号ID
            accountname	= userInfo.base.plataccount, -- // 账号名称
            platid      = userInfo.base.platid   -- // 渠道ID，目前accountid里面包含了渠道ID，如不包含可通过该字段传送
        },
        platorder	= orderInfo.order_no, 		--// 平台订单号
        gameorder	= orderInfo._id, 		    --// 游戏订单号
        roleid		= uid, 		                --// 用户在游戏内部游戏服上的角色ID
        originalmoney= orderInfo.subPrice,		--// 原价(格式:0.00),购买时应用传入的单价*总数,总原价
        ordermoney	= orderInfo.backPrice,		--// 实际价格(格式:0.00),购买时应用传入的单价*总数,总实际 价格
        goodid		= orderInfo.shopId,		    --// 用户买了什么商品
        goodnum		= 1,		                --// 用户买了多少个
        result		= 2,		                --// 购买状态, 1, 处理中;2 支付成功;3支付失败,4登录失效,5表示金额是查询的余额
        extdata		= "",		                --// 扩展数据长度
        type		= 0,		                --// 充值类型，0玩家充值，1沙箱充值（非rmb充值）,2玩家补偿
        rolelevel	= 1,                		--// 角色等级，游戏转发给monitor的时候加上角色等级
    }

    if unilight.islobbyserver() then
        go.buildProtoFwdServer("*Pmd.NotifyRechargeRequestSdkPmd_S", table2json(msg), "MS")
    else
        --如果在游戏，则通过大厅转发到后台
        local data = {}
        data.msg = msg
        data.msgName = "*Pmd.NotifyRechargeRequestSdkPmd_S"
        ChessToLobbyMgr.SendCmdToLobby("Cmd.ReqForwardToMonitor_CS", data)
    end

    unilight.info("NotifyRechargeRequestSdkPmd_S="..table2json(msg))
end


--用户提现
--[[
{
    "_id": 1676542601653,
    "orderId": "",
    "state": 2,
    "uid": 1005487,
    "times": "2023-02-16 10-16-41",
    "dinheiro": 30000,
    "cpf": "98765432541",
    "orderType": 2,
    "moedas": 30000,
    "chavePixNum": 0,
    "chavePix": "98765432541",
    "name": "asdf"
}
]]
function SendUserWithDrawToMonitor(uid, orderInfo)

    local userInfo = chessuserinfodb.RUserInfoGet(uid)

    local msg = 
    {
        data  = {
            userid 		= userInfo.uid, -- // 角色ID
            username 	= userInfo.base.nickname, -- // 角色名称
            accountid 	= userInfo.uid, -- // 账号ID
            accountname	= userInfo.base.plataccount, -- // 账号名称
            platid      = userInfo.base.platid   -- // 渠道ID，目前accountid里面包含了渠道ID，如不包含可通过该字段传送
        },
        gameorder = tostring(orderInfo._id),     --//游戏订单号 
        platorder = orderInfo.orderId or "", --    //平台订单号
        money     = orderInfo.dinheiro, --    //提现金额
        timedate  = orderInfo.times,          --//提现日期
    }

    go.buildProtoFwdServer("*Smd.StUserWithDrawMonitorSmd_CS", table2json(msg), "MS")
    unilight.info("StUserWithDrawMonitorSmd_CS="..table2json(msg))
end

--货币消耗
function SendUserEconomicConsumeToMonitor(uid,  opType, moneyType, moneyNum, actionType, actionName)

    local userInfo = chessuserinfodb.RUserInfoGet(uid)
    local msg = 
    {
        data  = {
            userid 		= userInfo.uid, -- // 角色ID
            username 	= userInfo.base.nickname, -- // 角色名称
            accountid 	= userInfo.uid, -- // 账号ID
            accountname	= userInfo.base.plataccount, -- // 账号名称
            platid      = userInfo.base.platid   -- // 渠道ID，目前accountid里面包含了渠道ID，如不包含可通过该字段传送
        },
        type        = opType,       --// 类别，0：产出，1：消耗
        coinid      = moneyType,    --// 属性ID或者货币ID
        coincount   = moneyNum,     -- // 货币数量
        actionid    = 0,            -- // 行为ID
        actioncount = 1,            --// 行为次数
        level       = 0,            -- // 等级
        actionname  = actionName or "", --// 行为名称
        viplevel	= userInfo.property.vipLevel, --// 角色当前vip等级，//20161111
        curcoin		= chessuserinfodb.RUserChipsGet(uid), -- // 本次行为后，当前剩余该货币的数量
        coinname	= Const.MONEY_TYPE_NAME[moneyType] or "未知", -- //货币名称
    }
    if unilight.islobbyserver() then
        go.buildProtoFwdServer("*Smd.EconomicProduceConsumeMonitorSmd_C", table2json(msg), "MS")
    else
        --如果在游戏，则通过大厅转发到后台
        local data = {}
        data.msg = msg
        data.msgName = "*Smd.EconomicProduceConsumeMonitorSmd_C"
        ChessToLobbyMgr.SendCmdToLobby("Cmd.ReqForwardToMonitor_CS", data)
    end

end

