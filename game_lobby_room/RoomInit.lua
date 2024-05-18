module('LobbyRoomInitMgr', package.seeall) -- 

table_stock_tax = import "table/table_stock_tax"
table_rank_robot = import "table/table_rank_robot"
table_rank_robot_pro = import "table/table_rank_robot_pro"
table_robot_config = import "table/table_robot_config"

rank_robot_list = {}

--大厅房间数据库初始化
function DBReady()
    -- 数据库加载完 就把数据库中有效的房间缓存出来 等游戏服认领
    RoomInfo.CreateRoomCache()
-- 房间初始化表格数据
    RoomInfo.InitTable()

end


--服务器启动后要做的事
function StartOver()
	local CYCLE_MIN = 60
	local CYCLE_HOUR = 3600
	local CYCLE_DAY = CYCLE_HOUR * 24

    unilight.addtimer('racelamp.timer',20)
    racelamp.Init()
	unilight.info("服务器启动调用")
    --每10秒钟定时器
	unilight.addclocker("LobbyRoomInitMgr.TenSecCallback", 0, 10)
    --每30秒钟定时器
	unilight.addclocker("LobbyRoomInitMgr.ThirtySecCallback", 0, 30)
    --每分钟定时器
	unilight.addclocker("LobbyRoomInitMgr.OneMinCallback", 0, CYCLE_MIN)
    --每3分钟定时器
	unilight.addclocker("LobbyRoomInitMgr.ThreeMinCallback", 0, CYCLE_MIN * 3)
    --每10分钟定时器
	unilight.addclocker("LobbyRoomInitMgr.TenMinCallback", 0, CYCLE_MIN * 10)

    --每3秒钟定时器
	unilight.addclocker("LobbyRoomInitMgr.TwoSecCallback", 0, 2)
    --每秒定时器
    unilight.addclocker("LobbyRoomInitMgr.OneSecCallback", 0, 1)
	--每天0点定时器
	unilight.addclocker("LobbyRoomInitMgr.ZeroHourCallback", 0, CYCLE_DAY)
    --积分抽奖定时器
    unilight.addclocker("Pointlottery.PLTick", 0, CYCLE_MIN)
    --重置下特惠礼包
    ShopMgr.RefreshDiscountShop()
    --检查全局限时礼包
    -- ShopMgr.RefreshGlobalLimitDiscountShop()

    --服务器要初始化一遍库存
    -- gamecommon.initStockNum()

    --排行榜初始化
    -- RankListMgr:Init()
    --初始排行榜机器人数量
    InitRobotInfoNum()
    -- 初始化累计充值活动信息
	CumulativeRecharge.Init()

end
--每秒定时器
function OneSecCallback()
    redRain.redLoop()
end


--0点定时器
function ZeroHourCallback()
    InitRobotInfoNum()
    -- CleanCustomRank()
end

--30秒定时器
function ThirtySecCallback()
    --统计下在线人数
    -- annagent.CaleOnlineInfo()
end

--10秒定时器
function TenSecCallback()
end

--2秒定时器
function TwoSecCallback()
    -- chessrechargemgr.CheckOrderDelivery()
    --修改兑换提现订单逻辑
    WithdrawCash.RefreshDiscountShop()
end

--每分钟定时器
function OneMinCallback()
    --重置下特惠礼包
    -- ShopMgr.RefreshDiscountShop()
    --检查限时礼包
    -- ShopMgr.RefreshGlobalLimitDiscountShop()
    --定时记录库存日志
    -- gamecommon.SaveSlotStockLog()
end

--3分钟定时器
function ThreeMinCallback()
end

--10分钟定时器
function TenMinCallback()
    RobotChipsRandomChange()
    RefreshSlotsChipsRank()
end


--清空指定排行榜
function CleanCustomRank()
    -- local cleanRankList = { Const.RANK_TYPE.SLOTS_WIN_CHIPS,
    --                         Const.RANK_TYPE.POOL_122_1,
    --                         Const.RANK_TYPE.POOL_122_2,
    --                         Const.RANK_TYPE.POOL_122_3,
    --                         Const.RANK_TYPE.POOL_117_1,
    --                         Const.RANK_TYPE.POOL_117_2,
    --                         Const.RANK_TYPE.POOL_117_3,
    --                         Const.RANK_TYPE.POOL_110_1,
    --                         Const.RANK_TYPE.POOL_110_2,
    --                         Const.RANK_TYPE.POOL_110_3,
    --                         Const.RANK_TYPE.POOL_108_1,
    --                         Const.RANK_TYPE.POOL_108_2,
    --                         Const.RANK_TYPE.POOL_108_3,
    -- }
    -- for _, randId in pairs(cleanRankList) do
    --     local rankList = RankListMgr:GetRankList(randId)
    --     if rankList ~= nil then
    --         rankList:CleanAllNode()
    --     end
    -- end

    -- RankListMgr:SaveToDB()
end

--刷新slots排行榜
function RefreshSlotsChipsRank()
    --排行榜刷新
    --[[
    local orderby = unilight.desc("property.slotsWins")
    local usrgroup = unilight.topdata("userinfo", 100, orderby)
    --先增加玩家
    for k,userInfo in pairs(usrgroup) do
        -- local userRankInfo = GetUserRankInfo(v.uid, lastZeroTime, zeroTime)
        -- if userRankInfo ~= nil then
            -- table.insert(userInfoList, userRankInfo)
        -- end
        --更新排行榜
        if userInfo.property.slotsWins ~= nil and userInfo.property.slotsWins > 0 then
            local rankInfo = {}
            --用户名字
            rankInfo.name = userInfo.base.nickname
            rankInfo.headurl = userInfo.base.headurl

            RankListMgr:UpdateRankNode(Const.RANK_TYPE.SLOTS_WIN_CHIPS, userInfo.uid, rankInfo, userInfo.property.slotsWins)
        end
    end
    ]]
    --增加机器人
    -- for _, robotInfo in pairs(rank_robot_list) do

    --     -- [1] = {
    --         -- ID = 1,
    --         -- frameId = 2,
    --         -- gender = "男",
    --         -- nickName = "user0000",
    --         -- robotType = 1,
    --         -- uid = 10000000,
    --     -- },
    --     local rankInfo = {}
    --     --用户名字
    --     rankInfo.name = robotInfo.nickName
    --     rankInfo.headurl = robotInfo.frameId
    --     RankListMgr:UpdateRankNode(Const.RANK_TYPE.SLOTS_WIN_CHIPS, robotInfo.ID, rankInfo, robotInfo.chips)
    -- end

    -- local rankList = RankListMgr:GetRankList(Const.RANK_TYPE.SLOTS_WIN_CHIPS)
    -- rankList:SortNode()
end




--服务器关闭后要做的事
function StopOver()
	unilight.info("服务器关闭调用")
    unilight.info("保存房间信息")
    RoomInfo.SaveAllRoomData()

    --排行榜排序并存档一下
    -- RankListMgr:SortRank()

end

--初始化机器人数量
function InitRobotInfoNum()
    rank_robot_list = {}
    local rankRobotConfig = table_rank_robot[1]
    local robotNum = rankRobotConfig.robotNum
    local curNum = 0 
    local maxRobotNum = table.maxn(table_robot_config)
    while curNum < robotNum do
        local randomIdx = math.random(1, maxRobotNum)
        local robotInfo = table_robot_config[randomIdx]
        if rank_robot_list[robotInfo.ID]  == nil then
            local newRobotInfo = table.clone(robotInfo)
            newRobotInfo.chips = math.random(rankRobotConfig.chipsMin,rankRobotConfig.chipsMax)  
            rank_robot_list[robotInfo.ID] = newRobotInfo
            curNum = curNum + 1
        end
    end
    unilight.info("初化排行榜机器人数量:"..curNum)
end

--机器人金币变化
function RobotChipsRandomChange()

    for _, robotInfo in pairs(rank_robot_list) do
        local probability = {}
        local allResult = {}
        for k, v in pairs(table_rank_robot_pro) do
            table.insert(probability, v.percent)
            table.insert(allResult, {addMin=v.addMin, addMax=v.addMax})
        end
        local randInfo = math.random(probability, allResult)
        local addChips = math.random(randInfo.addMin, randInfo.addMax)
        robotInfo.chips = robotInfo.chips + addChips
    end

end

Tcp = Tcp or {}
-- 断线重连 覆盖掉默认实现
Tcp.reconnect_login_ok = function(laccount)
    local uid = laccount.Id

    -- 模拟下获取
    local cmd = {
        data = {
            uid = uid,
            getIsCreate = true,
        }
    }

    -- 重新拉去下个人信息
    Net.CmdUserInfoGetLobbyCmd_C(cmd, laccount)
    RoomInfo.CheckPreLogin(uid, laccount)
    unilight.info("reconnect_login_ok uid:" .. uid)
end 

Do.online_state_change_account = function(laccount,oldstate,newstate)
    local uid = laccount.Id
    if newstate == 1 then
        RoomInfo.CheckPreLogin(uid, laccount)
    end
end
