--任务模块
module('DaysTaskMgr', package.seeall)

local tableTaskDaily    = import "table/table_task_daily"
local tableSeasonTask   = import "table/table_task_season"
local tableTaskConfig   = import "table/table_task_config"
local tableItemConfig   = import "table/table_item_config"
local tableTaskOther    = import "table/table_task_other"
local tableTaskFlower   = import "table/table_task_flower"
local tableTaskFlowerRand = import "table/table_task_flower_random"
local tableSeasonTaskCoef = import "table/table_task_season_coef"
local tableMailConfig   = import "table/table_mail_config"
local tableTaskVerion   =  import "table/table_task_version"
local tableActivityPassTask = import "table/table_activity_passtask"

local taskOtherConfig  = tableTaskOther[1]

-- 任务状态枚举
TASK_STATUS = {
	DOING = 1, -- 任务进行中
	DONE = 2, -- 已完成
	RECIEVED = 3, -- 已领取奖励
}

--任务分类
TASK_CLASS = {
    DAILY  = 1,     --每日任务
    SEASON = 2,     --赛季任务
}


--通行证任务奖励
PASS_REWARD_TYPE = {
   FREE  = 1,       --免费奖励
   PASS  = 2,       --通行证奖励
}

--花朵最大数量
FLOWER_MAX = 7
--花朵类型
FLOWER_TYPE =
{
    PURPLE = 1,     --紫色
    GOLD   = 2,     --金色
}

--水壶道具
FLOWER_ITEM = {
    PURPLE = 10042,
    GOLD   = 10041,
}

--活动免费奖励
REWARD_FREE = 1
--活动收费奖励
REWARD_PAY  = 2


--通行证任务分类

--每日任务最大次数
TASK_DAILY_MAX = 3
--赛季任务每日最大次数
TASK_ROUND_MAX = 1

DYAS_TASK_DB_NAME = "daystaskinfo"

-- 任务创建
function UserTaskConstuct(uid)
	-- 遍历任务配置表 找出第一批任务
	local userTasks = {
		_id 		= uid,			    -- 玩家id
		daysTaskInfo= {                 --每日任务
            index  = 1,                  --当前任务进度
            status = TASK_STATUS.DOING, --任务状态
            curNum = 0,                 --当前进度
            taskId = 0,                 --当前任务id
        },			
        seasonTaskInfo = {              --赛季任务
            index  = 1,                 --当前任务进度
            status = TASK_STATUS.DOING, --任务状态
            curNum = 0,                 --当前进度
            taskId = 0,                 --当前任务id
        },        
		lastDayNo 		= 0,		    --上次更新天数
        passTaskInfo = {
            level          = 0,         --通行证任务等级
            point          = 0,         --通行证积分
            round          = 0,         --当前期
            extPoint       = 0,         --通行证满进度后多出来的积分
            freeRewardList = {},        --等级免费奖励领取情况{[1]        = 1}
            passRewardList = {},        --等级通行证奖励领取情况{[1]      = 1}
            buyPassCount   = 0,         --购买通行证次数
            buyDoubleCount = 0,         --购买双倍通行证次数
            buyDoublePointNum  = 0,     --购买双倍进度buff次数

        },
        flowerTaskInfo = {              --浇花信息
            purpleList = {},            --紫色花信息
            goldList   = {},            --金花化信息
            lastWeekNo = 0,             --上次刷新周
        }
	}

    userTasks.passTaskInfo.round = GetCurrentRound()
    unilight.info(string.format("新用户:%d, 当前期:%d", uid, userTasks.passTaskInfo.round))
	return userTasks
end



--增加通行证积分
function AddPassPoint(uid, point)
	local userTasks = unilight.getdata(DYAS_TASK_DB_NAME, uid)
    if userTasks == nil then
        userTasks = UserTaskConstuct(uid)
    end
    local passTaskInfo = userTasks.passTaskInfo

    passTaskInfo.point = passTaskInfo.point + point
    local maxPassPoint = GetPassMaxPoint(passTaskInfo.round)
    --多出的积分放到扩展里
    if passTaskInfo.point > maxPassPoint then
        local extPoint = passTaskInfo.point - maxPassPoint 
        passTaskInfo.point = maxPassPoint
        passTaskInfo.extPoint =  passTaskInfo.extPoint +  extPoint
    end

    --计算等级
    local newLevel = 0
    local passTaskList = GetPassTaskListByVersion(passTaskInfo.round)
    for level, passTaskConfig in ipairs(passTaskList) do
        if passTaskInfo.point >=  passTaskConfig.needNum then
            newLevel =  passTaskConfig.level
        end
    end

    if newLevel ~= passTaskInfo.level then
        passTaskInfo.level = newLevel
    end

    unilight.info(string.format("玩家:%d, 获得任务通行积分:%d, 总积分:%d, 等级:%d", uid, point, passTaskInfo.point, passTaskInfo.level))
    unilight.savedata(DYAS_TASK_DB_NAME, userTasks)
    GetTaskList(uid)
end


--计算双倍buff需要花费的钻石
function CalcDoubleBuffDiamond(buyNum) 
    local needDiamond = (taskOtherConfig.doubleCoefA * buyNum * buyNum) + (taskOtherConfig.doubleCoefB * buyNum) + taskOtherConfig.doubleCoefC
    return needDiamond
end

--计算通证等5等级需要的商品id
function Calc5LevelPrice(round, level)
    local version = GetCurrentVersion(round)
    local versionConfig = tableTaskVerion[version]
    --满级
    local maxLevel = #GetPassTaskListByVersion(version)   
    local diffLevel = maxLevel - level
    if diffLevel >= 5 then
        diffLevel = 5
    end
    local oldPrice = versionConfig.level5X1 * level + versionConfig.level5Y1
    local price = math.floor(oldPrice * diffLevel / 5   + 0.5)  * 100 - 1
    if price < 0 then
        price = 0
    end
    return price 
end

--计算通行证10级需要的商品id
function Calc10LevelPrice(round, level)
    local version = GetCurrentVersion(round)
    local versionConfig = tableTaskVerion[version]
    --满级
    local maxLevel  = #GetPassTaskListByVersion(version)
    local diffLevel = maxLevel - level
    if diffLevel >= 10  then
        diffLevel = 10
    end
    local oldPrice  = versionConfig.level10X2 * level + versionConfig.level10Y2
    local price     = math.floor(oldPrice * diffLevel / 10 + 0.5) * 100 - 1
    if price < 0 then
        price = 0
    end
    return price
end

--增加通行证任务等级
function AddPassTaskLevel(uid, addLevel)
	local userTasks = unilight.getdata(DYAS_TASK_DB_NAME, uid)
    if userTasks == nil then
        userTasks = UserTaskConstuct(uid)
    end

    local passTaskInfo = userTasks.passTaskInfo
    local newLevel =  addLevel + passTaskInfo.level
    local passTaskList = GetPassTaskListByVersion(passTaskInfo.round)
    if passTaskList[newLevel] == nil then
        newLevel = #passTaskList
    end

    unilight.info(string.format("通行证任务增加后等级：%d,原等级:%d", newLevel, passTaskInfo.level))
    passTaskInfo.level = newLevel
    passTaskInfo.point = passTaskList[newLevel].needNum
    unilight.savedata(DYAS_TASK_DB_NAME, userTasks)

    GetTaskList(uid)
end

-- 任务更新
function TaskUpdate(userTasks)


    local daysTaskInfo = userTasks.daysTaskInfo
    local seasonTaskInfo = userTasks.seasonTaskInfo
    local passTaskInfo = userTasks.passTaskInfo
    local flowerTaskInfo = userTasks.flowerTaskInfo
    local bUpdate = false

    --跨天刷新
    local curDayNo = chessutil.GetMorningDayNo()
    if userTasks.lastDayNo == 0 or curDayNo ~= userTasks.lastDayNo then
        userTasks.lastDayNo = curDayNo
        --获得随机每日任务
        daysTaskInfo.index = 1
        daysTaskInfo.status = TASK_STATUS.DOING
        daysTaskInfo.curNum = 0

        local taskDailyConfig = tableTaskDaily[daysTaskInfo.index]
        local randomIdx = math.random(1,#taskDailyConfig.randTask)
        local nextTaskId = taskDailyConfig.randTask[randomIdx]

        daysTaskInfo.taskId = nextTaskId

        --赛季随机任务
        seasonTaskInfo.index = 1
        seasonTaskInfo.status = TASK_STATUS.DOING
        seasonTaskInfo.curNum = 0
        --赛季任务只有一个
        local reasonTaskConfig = tableSeasonTask[TASK_ROUND_MAX]
        local randomIdx = math.random(1,#reasonTaskConfig.randTask)
        local nextTaskId = reasonTaskConfig.randTask[randomIdx]

        seasonTaskInfo.taskId = nextTaskId

        bUpdate = true
    end
    --周刷新
    local curWeekNo = chessutil.GetMorningWeekNo()
    if flowerTaskInfo.lastWeekNo == 0 or  flowerTaskInfo.lastWeekNo ~= curWeekNo then
        flowerTaskInfo.lastWeekNo = curWeekNo
        --初始化浇花信息
        local bigRewardNum1  = FlowerBigRewardNum()
        local bigRewardNum2  = FlowerBigRewardNum()
        for i=1, FLOWER_MAX do
            local rewardInfo = {isGet = 0, isBigReward=0}
            if i == bigRewardNum1 then
                rewardInfo.isBigReward = 1
            end
            flowerTaskInfo.purpleList[i] = rewardInfo
            local rewardInfo = {isGet = 0, isBigReward=0}
            if i == bigRewardNum2 then
                rewardInfo.isBigReward = 1
            end
            flowerTaskInfo.goldList[i] =  rewardInfo
        end
        bUpdate = true
    end

    --如果当前状态已经完成,则切入到下一个任务
    if daysTaskInfo.status == TASK_STATUS.RECIEVED then
        --满足条件进入一个任务
        if (daysTaskInfo.index)  < TASK_DAILY_MAX then

            daysTaskInfo.index =  daysTaskInfo.index + 1

            --获得随机每日任务
            local taskDailyConfig = tableTaskDaily[daysTaskInfo.index]
            local randomIdx = math.random(1,#taskDailyConfig.randTask)
            local nextTaskId = taskDailyConfig.randTask[randomIdx]

            daysTaskInfo.status = TASK_STATUS.DOING
            daysTaskInfo.taskId = nextTaskId
            daysTaskInfo.curNum = 0
            bUpdate = true
        end
    end
    --赛季任务切换到下一个任务
    if seasonTaskInfo.status == TASK_STATUS.RECIEVED then
        --直接进入下一个任务,只是条件增加
        seasonTaskInfo.index =  seasonTaskInfo.index + 1

        local reasonTaskConfig = tableSeasonTask[TASK_ROUND_MAX]
        local randomIdx = math.random(1,#reasonTaskConfig.randTask)
        local nextTaskId = reasonTaskConfig.randTask[randomIdx]

        seasonTaskInfo.taskId = nextTaskId

        bUpdate = true

    end

    --计算通行证奖励是否跨赛季
    local newRound = GetCurrentRound()
    local newPassTaskInfo = nil
    if newRound ~= passTaskInfo.round then
        --防止奖励报错
        newPassTaskInfo = table.clone(passTaskInfo)
        passTaskInfo.round = newRound
        passTaskInfo.level = 0                  --通行证任务等级
        passTaskInfo.point = 0                  --通行证积分
        passTaskInfo.extPoint  = 0              --通行证满进度后多出来的积分
        passTaskInfo.freeRewardList = {}        --等级免费奖励领取情况{[1]=1}
        passTaskInfo.passRewardList = {}        --等级通行证奖励领取情况{[1]=1}
        bUpdate = true
    end
    

	-- 存档
    if bUpdate == true then
        unilight.savedata(DYAS_TASK_DB_NAME, userTasks)
    end

    --奖励放到最后，防止脚本报错
    if newPassTaskInfo ~= nil then
        --结算没领的奖励
        EndPassTaskRound(uid, newPassTaskInfo)

    end
end

--浇花大奖概率
function FlowerBigRewardNum()
	local probability = {}
	local allResult = {}
	for k, v in pairs(tableTaskFlowerRand) do
        table.insert(probability, v.pro)
        table.insert(allResult, {v.times})
	end

	local ret = math.random(probability, allResult)
	return ret[1]
end


--通行证赛季结束，结算没领的奖励和额外的积分
function EndPassTaskRound(uid, passTaskInfo)
    local rewardList = {}
    --未领的道具奖励
    local passTaskList = GetPassTaskListByVersion(passTaskInfo.round)
    for k, v in pairs(passTaskList) do
        if passTaskInfo.point >= v.needNum then

            if passTaskInfo.freeRewardList[v.level] == nil then
                for k2,v2 in pairs(v.freeReward) do
                    table.insert(rewardList, {itemId=v2.goodId, itemNum=v2.goodNum})
                end
            end

            if passTaskInfo.passRewardList[v.level] == nil and CheckPassNormalReward(uid) then
                for k2,v2 in pairs(v.payReward) do
                    --金币翻倍
                    if tableItemConfig[v2.goodId].goodType == Const.GOODS_TYPE.GOLD_BASE and CheckPassDoubleReward(uid) ~= nil then
                        table.insert(rewardList, {itemId=v2.goodId, itemNum=v2.goodNum * 2})
                        unilight.info(string.format("任务奖励金币翻倍,原始金币:%d, 翻倍金币:%d",v2.goodNum, v2.goodNum*2 ))
                    else
                        table.insert(rewardList, {itemId=v2.goodId, itemNum=v2.goodNum})
                    end
                end
            end

            --活动奖励
            local activityRewardList = GetActivityReward(uid, passTaskInfo.round, v.level, REWARD_FREE)
            for _, rewardInfo in pairs(activityRewardList) do
                table.insert(rewardList, {itemId=rewardInfo.goodId, itemNum=rewardInfo.goodNum})
            end

            local activityRewardList = GetActivityReward(uid, passTaskInfo.round, v.level, REWARD_PAY)
            for _, rewardInfo in pairs(activityRewardList) do
                table.insert(rewardList, {itemId=rewardInfo.goodId, itemNum=rewardInfo.goodNum})
            end


        end
    end


    if #rewardList > 0 then
        unilight.info(string.format("赛季结束, 玩家:%d，还未领的道具:%s", uid, table2json(rewardList)))
        local mailConfig = tableMailConfig[9]
        local mailInfo = {}
        mailInfo.charid = uid
        mailInfo.subject = mailConfig.subject
        mailInfo.content = mailConfig.content
        mailInfo.type = 0
        mailInfo.attachment = rewardList
        mailInfo.extData = {configId=mailConfig.ID}
        ChessGmMailMgr.AddGlobalMail(mailInfo)
    end

end

-- 获取各个游戏中的数据 来 填充修改 大厅任务表数据
function FillDaysTask(uid, userTasks)
	local completeNbr = 0
	-- 获取当天零点时间
	local temp = os.date("*t", os.time())
	local zeroTime = os.time({year=temp.year, month=temp.month, day=temp.day, hour=0})
	local nextZeroTime = zeroTime + 24*60*60

	-- 遍历任务列表中 的所有任务	(过滤掉 统计任务 那个后面再处理) 
	for i,v in ipairs(userTasks.taskLists) do
		local tableDaysTask = TableLobbyTaskConfig[v.taskId]
		-- 当任务 处于 进行阶段 才去更新里面的内容
		if v.taskStatus == TASK_STATUS.DOING then
			-- 累计局数
			if tableDaysTask.taskType == 1 then
				local nbr = chessprofitbet.CmdGamePlayNmuberGetByGameIdUidBetween(uid, tableDaysTask.gameId, zeroTime, nextZeroTime)
				if nbr >= tableDaysTask.taskCondition then
					v.taskStatus = TASK_STATUS.DONE
					v.current = tableDaysTask.taskCondition
					-- 统计完成了多少个任务
					completeNbr = completeNbr + 1
				else
					v.current = nbr
				end
			-- 累计时间
			elseif tableDaysTask.taskType == 2 then
				local times = ChessOnlineTimes.GetOnlineTimesByUidGameId(uid, tableDaysTask.gameId)
				if times >= tableDaysTask.taskCondition then
					v.taskStatus = TASK_STATUS.DONE
					v.current = tableDaysTask.taskCondition
					-- 统计完成了多少个任务
					completeNbr = completeNbr + 1
				else
					v.current = times
				end
			-- 累计赢了多少局
			elseif tableDaysTask.taskType == 3 then
				local nbr = chessprofitbet.CmdGameWinNmuberGetByGameIdUidBetween(uid, tableDaysTask.gameId, zeroTime, nextZeroTime)
				if nbr >= tableDaysTask.taskCondition then
					v.taskStatus = TASK_STATUS.DONE
					v.current = tableDaysTask.taskCondition
					-- 统计完成了多少个任务
					completeNbr = completeNbr + 1
				else
					v.current = nbr
				end
			end
		else
			-- 统计完成了多少个任务
			if tableDaysTask.taskType ~= 4 then
				completeNbr = completeNbr + 1
			end
		end
	end


	-- 单独处理 完成多少个任务的 统计任务
	for i,v in ipairs(userTasks.taskLists) do
		-- 当任务 处于 进行阶段 才去更新里面的内容
		if v.taskStatus == TASK_STATUS.DOING then
			local tableDaysTask = TableLobbyTaskConfig[v.taskId]
			if tableDaysTask.taskType == 4 then
				if completeNbr >= tableDaysTask.taskCondition then
					v.taskStatus = TASK_STATUS.DONE
					v.current = tableDaysTask.taskCondition
				else
					v.current = completeNbr
				end		
			end	
		end
	end

	return userTasks	
end

-- 获取任务列表(也可用于 玩家 进入游戏时 更新当前任务数据)
function GetTaskList(uid)
	-- 从数据库中 获取该玩家数据
	local userTasks = unilight.getdata(DYAS_TASK_DB_NAME, uid)
    if userTasks == nil then
        userTasks = UserTaskConstuct(uid)
    end
	-- 任务更新
	TaskUpdate(userTasks)

    local daysTaskInfo = userTasks.daysTaskInfo
    local seasonTaskInfo = userTasks.seasonTaskInfo
    local passTaskInfo = userTasks.passTaskInfo

	local send = {}
	send["do"] = "Cmd.GetTaskListDaysTaskCmd_S"
    local taskConfig = tableTaskConfig[daysTaskInfo.taskId]
    local daysTaskInfo2 = {
        taskId = daysTaskInfo.taskId,
        taskStatus = daysTaskInfo.status,
        curNum     = daysTaskInfo.curNum,
        maxNum     = taskConfig.finishNum,
        curDailyNum = daysTaskInfo.index,
        curDailyMax = TASK_DAILY_MAX,
    }

    local taskConfig = tableTaskConfig[seasonTaskInfo.taskId]
    local seasonTaskInfo2 = {
        taskId = seasonTaskInfo.taskId,
        taskStatus = seasonTaskInfo.status,
        curNum     = seasonTaskInfo.curNum,
        maxNum     = taskConfig.finishNum * seasonTaskInfo.index,
        curDailyNum = seasonTaskInfo.index,
        curDailyMax = TASK_ROUND_MAX,
    }

    local passTaskData = {
       level =  passTaskInfo.level,
       point =  passTaskInfo.point,
       round = passTaskInfo.round,
       extPoint = passTaskInfo.extPoint,
       exchangePoint = taskOtherConfig.passPointMaxExt,
       freeRewardList = {} ,
       passRewardList = {},
       buyPassCount = passTaskInfo.buyPassCount,
       buyDoubleCount = passTaskInfo.buyDoubleCount,
       doublePointDiamond = CalcDoubleBuffDiamond(passTaskInfo.buyDoublePointNum),
       level5Price = Calc5LevelPrice(passTaskInfo.round, passTaskInfo.level),
       level10Price = Calc10LevelPrice(passTaskInfo.round, passTaskInfo.level),
    } 
    local endTime = chessutil.TimeByDateGet(GetPassEndTimeByRound(passTaskInfo.round))
    passTaskData.endTime = endTime

    for k, v in pairs(passTaskInfo.freeRewardList) do
        table.insert(passTaskData.freeRewardList, k)
    end

    for k, v in pairs(passTaskInfo.passRewardList) do
        table.insert(passTaskData.passRewardList, k)
    end


    --浇花信息
    local flowerTaskInfo = userTasks.flowerTaskInfo

    local purpleTaskInfo = {}
    local goldTaskInfo = {}
    for k, v in pairs(flowerTaskInfo.purpleList) do
        table.insert(purpleTaskInfo, {flowerId=k, isGet=v.isGet})
    end

    for k, v in pairs(flowerTaskInfo.goldList) do
        table.insert(goldTaskInfo, {flowerId=k, isGet=v.isGet})
    end

    send.data = {
        errno = 0,
        desc  = "获取成功",
        daysTaskInfo = daysTaskInfo2, 
        seasonTaskInfo = seasonTaskInfo2,
        passTaskInfo = passTaskData,
        purpleTaskInfo = purpleTaskInfo,
        goldTaskInfo = goldTaskInfo,
        flowerEndTime = chessutil.GetMorningWeekNo2Time(flowerTaskInfo.lastWeekNo + 1),
        curRound      = passTaskInfo.round,
    }

    unilight.sendcmd(uid, send)
end

-- 领取任务奖励
function GetTaskReward(uid, taskId)
	local taskConfig = tableTaskConfig[taskId]

    local send = {}
    send["do"] = "Cmd.GetTaskRewardDaysTaskCmd_S"

    if taskConfig == nil then
       send["data"] = {
           errno = 2,
           desc  = "配置表找不到任务id:"..taskId
       } 
       return send
    end

	local userTasks = unilight.getdata(DYAS_TASK_DB_NAME, uid)
    local taskInfo = userTasks.daysTaskInfo
    if taskConfig.taskClass == TASK_CLASS.SEASON then
        taskInfo = userTasks.seasonTaskInfo
    end

    if taskInfo.status == TASK_STATUS.RECIEVED then
       send["data"] = {
           errno = 3,
           desc  = "已经领取过奖励"
       } 
        return send
    end

    if taskInfo.status == TASK_STATUS.DOING then
       send["data"] = {
           errno = 4,
           desc  = "任务未完成"
       } 
        return send
    end


    taskInfo.status = TASK_STATUS.RECIEVED
    TaskUpdate(userTasks)
    --保存下数据
    unilight.savedata(DYAS_TASK_DB_NAME, userTasks)
    
    --判断完成可以领奖
    local rewardInfo = {}
    for k, v in pairs(taskConfig.reward) do
        --双倍进度
        if v.goodId == Const.GOODS_ID.PASS_TASK_POINT and BuffMgr.GetBuffByBuffId(uid, Const.BUFF_TYPE_ID.PASS_POINT_DOUBLE) ~= nil then
            table.insert(rewardInfo, {goodId=v.goodId, goodNum=v.goodNum * 2})
        --赛季奖励翻倍(累计不同金币不一样)
        elseif v.goodId == Const.GOODS_ID.GOLD_BASE and taskConfig.taskClass == TASK_CLASS.SEASON then
            local index = taskInfo.index
            local maxIndex = table.len(tableSeasonTaskCoef) 
            if index > maxIndex then
                index = maxIndex
            end
            local SeasonTaskCoef = tableSeasonTaskCoef[index]
            local goodNum = math.floor(v.goodNum * SeasonTaskCoef.coef)
            unilight.info(string.format("玩家:%d,赛季任务刷新次数:%d",uid, index))
            table.insert(rewardInfo, {goodId=v.goodId, goodNum=goodNum})
        else
            table.insert(rewardInfo, {goodId=v.goodId, goodNum=v.goodNum})
        end
    end

    for _, goodInfo in pairs(rewardInfo) do
        BackpackMgr.GetRewardGood(uid, goodInfo.goodId, goodInfo.goodNum, Const.GOODS_SOURCE_TYPE.TASK)
    end


    send["data"] = {
        errno = 0,
        desc  = "领取成功",
        reward = rewardInfo, 
    }

    unilight.sendcmd(uid, send)

    --刷新下任务列表
    GetTaskList(uid)

end

-- 领取通行证任务奖励
function GetPassTaskReward(uid, level, getType)

	local send = {}
	send["do"] = "Cmd.GetPassRewardTask_S"
	-- 从数据库中 获取该玩家数据
	local userTasks = unilight.getdata(DYAS_TASK_DB_NAME, uid)
    local passTaskInfo = userTasks.passTaskInfo
    local rewardList = {}

    local passTaskList = GetPassTaskListByVersion(passTaskInfo.round)
    --领取全部奖励
    if level == 0 then
        for k, v in pairs(passTaskList) do
           if passTaskInfo.point >= v.needNum then

               if passTaskInfo.freeRewardList[v.level] == nil then
                   for k2,v2 in pairs(v.freeReward) do
                       table.insert(rewardList, {goodId=v2.goodId, goodNum=v2.goodNum})
                   end
                   passTaskInfo.freeRewardList[v.level] = 1
               end

               if passTaskInfo.passRewardList[v.level] == nil and CheckPassNormalReward(uid) then
                   for k2,v2 in pairs(v.payReward) do
                       --金币翻倍
                       if tableItemConfig[v2.goodId].goodType == Const.GOODS_TYPE.GOLD_BASE and CheckPassDoubleReward(uid) then
                           table.insert(rewardList, {goodId=v2.goodId, goodNum=v2.goodNum * 2})
                           unilight.info(string.format("任务奖励金币翻倍,原始金币:%d, 翻倍金币:%d",v2.goodNum, v2.goodNum*2 ))
                       else
                           table.insert(rewardList, {goodId=v2.goodId, goodNum=v2.goodNum})
                       end
                   end
                   passTaskInfo.passRewardList[v.level] = 1
               end

               local activityRewardList = GetActivityReward(uid, passTaskInfo.round, v.level, REWARD_FREE)
               for _, rewardInfo in pairs(activityRewardList) do
                   table.insert(rewardList, {goodId=rewardInfo.goodId, goodNum=rewardInfo.goodNum})
               end

               local activityRewardList = GetActivityReward(uid, passTaskInfo.round, v.level, REWARD_PAY)
               for _, rewardInfo in pairs(activityRewardList) do
                   table.insert(rewardList, {goodId=rewardInfo.goodId, goodNum=rewardInfo.goodNum})
               end
           end
        end
        --没有可领的奖励
        if #rewardList == 0 then
            send["data"] = {
                errno = 2,
                desc  = "没有可领的奖励"
            }
            unilight.sendcmd(uid, send)
            return
        end

    else

        local passTaskConfigList = GetPassTaskListByVersion(passTaskInfo.round)
        local passTaskConfig = passTaskConfigList[level]
        if passTaskConfig == nil then
            send["data"] = {
                errno = 3,
                desc  = "没有该等级奖励"
            }
            unilight.sendcmd(uid, send)
            return
        end

        if passTaskInfo.point < passTaskConfig.needNum then
            send["data"] = {
                errno = 4,
                desc  = "条件不足，不能领取"
            }
            unilight.sendcmd(uid, send)
            return
        end

        if getType == PASS_REWARD_TYPE.FREE then
            if passTaskInfo.freeRewardList[level] ~= nil then
                send["data"] = {
                    errno = 5,
                    desc  = "已经领取过奖励，不能重复领取"
                }
                unilight.sendcmd(uid, send)
                return
            end
            passTaskInfo.freeRewardList[level] = 1
            for k, v in pairs(passTaskConfig.freeReward) do
                table.insert(rewardList, {goodId=v.goodId, goodNum=v.goodNum})
            end

            local activityRewardList = GetActivityReward(uid, passTaskInfo.round, level, REWARD_FREE)
            for _, rewardInfo in pairs(activityRewardList) do
                table.insert(rewardList, {goodId=rewardInfo.goodId, goodNum=rewardInfo.goodNum})
            end

        else
            if CheckPassNormalReward(uid) == false then
                send["data"] = {
                    errno = 5,
                    desc  = "没有通行证，无法领取"
                }
                unilight.sendcmd(uid, send)
                return
            end

            if passTaskInfo.passRewardList[level] ~= nil then
                send["data"] = {
                    errno = 5,
                    desc  = "已经领取过奖励，不能重复领取"
                }
                unilight.sendcmd(uid, send)
                return
            end


            for k, v2 in pairs(passTaskConfig.payReward) do
                --金币翻倍
                if tableItemConfig[v2.goodId].goodType == Const.GOODS_TYPE.GOLD_BASE and  CheckPassDoubleReward(uid) then
                    table.insert(rewardList, {goodId=v2.goodId, goodNum=v2.goodNum * 2})
                    unilight.info(string.format("任务奖励金币翻倍,原始金币:%d, 翻倍金币:%d",v2.goodNum, v2.goodNum*2 ))
                else
                    table.insert(rewardList, {goodId=v2.goodId, goodNum=v2.goodNum})
                end
            end

            local activityRewardList = GetActivityReward(uid, passTaskInfo.round, level, REWARD_PAY)
            for _, rewardInfo in pairs(activityRewardList) do
                table.insert(rewardList, {goodId=rewardInfo.goodId, goodNum=rewardInfo.goodNum})
            end

            passTaskInfo.passRewardList[level] = 1
        end

    end

        --保存下数据
        unilight.savedata(DYAS_TASK_DB_NAME, userTasks)
        local summary = {}
        for k, v in pairs(rewardList) do
            summary = BackpackMgr.GetRewardGood(uid, v.goodId, v.goodNum, Const.GOODS_SOURCE_TYPE.TASK, summary)
        end

        local rewardList = {}
        for k, v in pairs(summary) do
            table.insert(rewardList, {goodId=k, goodNum=v})
        end


        send["data"] = {
            errno = 0,
            desc  = "领取成功",
            rewardList = rewardList,
        }
        unilight.sendcmd(uid, send)
        --刷新下任务列表
        GetTaskList(uid)
        return
end


--花宝石完成任务(只能完成每日任务)
function UseDiamondFinishTask(uid, taskId)
	local send = {}
	send["do"] = "Cmd.UseDiamondFinishTask_S"
    local taskConfig = tableTaskConfig[taskId]


    if taskConfig.taskClass ~=  TASK_CLASS.DAILY then
        send["data"] = {
            errno = 1,
            desc  = "只能完成每日任务"
        }
        unilight.sendcmd(uid, send)
        return
    end

	local userTasks = unilight.getdata(DYAS_TASK_DB_NAME, uid)
    local daysTaskInfo = userTasks.daysTaskInfo
    if daysTaskInfo.taskId ~= taskId then
        send["data"] = {
            errno = 2,
            desc  = "任务与当前任务不匹配"
        }
        unilight.sendcmd(uid, send)
        return
    end

    if daysTaskInfo.status ~= TASK_STATUS.DOING then
        send["data"] = {
            errno = 3,
            desc  = "该任务已经完成"
        }
        unilight.sendcmd(uid, send)
        return
    end

    local taskDaily = tableTaskDaily[daysTaskInfo.index]

    local _, ret = chessuserinfodb.WDiamondChange(uid, Const.PACK_OP_TYPE.SUB, taskDaily.passDiamond, "跳过每日任务扣除")
    if ret == false then
        send["data"] = {
            errno = 4,
            desc  = "货币不足，不能完成"
        }
        unilight.sendcmd(uid, send)
        return

    end

    --扣除完成可以完成任务
    daysTaskInfo.status = TASK_STATUS.DONE
    daysTaskInfo.curNum = taskConfig.finishNum

    send["data"] = {
        errno = 0,
        desc  = "成功"
    }
    unilight.sendcmd(uid, send)

    unilight.savedata(DYAS_TASK_DB_NAME, userTasks)

    --刷新下任务列表
    GetTaskList(uid)
end


--请求浇花
function ReqWaterFlower(uid, flowerType, flowerId)
    local taskFlowerConfig = tableTaskFlower[1]
	local send = {}
	send["do"] = "Cmd.ReqWaterFlowerTask_S"
	local userTasks = unilight.getdata(DYAS_TASK_DB_NAME, uid)
    if IsInWaterFlower(userTasks.flowerTaskInfo) == false then
        send["data"] = {
            errno = 4,
            desc  = "不在浇花时间"
        }
        unilight.sendcmd(uid, send)
        return
    end
    local recycleList = {}      --回收奖励
    local rewardList = {}       --普通奖励


    local flowerTaskInfo = userTasks.flowerTaskInfo
    if flowerType == FLOWER_TYPE.PURPLE then
        local flowerInfo = flowerTaskInfo.purpleList[flowerId]
        if  flowerInfo == nil then
            send["data"] = {
                errno = 2,
                desc  = "FlowerId不存在"
            }
            unilight.sendcmd(uid, send)
            return
        end
        if flowerInfo.isGet == 1 then
            send["data"] = {
                errno = 3,
                desc  = "FlowerId已经浇过"
            }
            unilight.sendcmd(uid, send)
            return
        end
        
        local bOk, desc, surplus = BackpackMgr.UseItem(uid, FLOWER_ITEM.PURPLE, 1, "浇花扣除")
        if bOk ~= true then
            send["data"] = {
                errno = 4,
                desc = "物品数量不够",
            }
            unilight.sendcmd(uid, send)
            return
        end
        
        --改变标志
        flowerInfo.isGet = 1

        local isBigReward = 0
        for k, v in pairs(taskFlowerConfig.purpleBaseReward) do
            table.insert(rewardList, {goodId=v.goodId, goodNum=v.goodNum})
        end
        --大奖
        if flowerInfo.isBigReward == 1 then
            for _, v in pairs(flowerTaskInfo.purpleList) do
                if v.isGet == 0 then
                    v.isGet = 1
                end
            end
            --全部置已领取
            for k, v in pairs(taskFlowerConfig.purpleBigReward) do
                table.insert(rewardList, {goodId=v.goodId, goodNum=v.goodNum})
            end
            isBigReward = 1

            --触发大奖扣除所有道具
            local remainNum = BackpackMgr.GetItemNumByGoodId(uid, FLOWER_ITEM.PURPLE) 
            if remainNum > 0  then
                local bOk, desc = BackpackMgr.UseItem(uid, FLOWER_ITEM.PURPLE, remainNum, "紫花-浇花大奖剩余扣除")
                if bOk == true then
                    table.insert(recycleList, {goodId=Const.GOODS_ID.GOLD_BASE, goodNum=remainNum * taskFlowerConfig.purpleRecovery})
                end
            end
        else
            --检查是否全部浇完,剩余数量换成奖励
            local allFinish = true
            for _, v in pairs(flowerTaskInfo.purpleList) do
                if v.isGet == 0 then
                    allFinish = false
                    break;
                end
            end
            if allFinish then
                local remainNum = BackpackMgr.GetItemNumByGoodId(uid, FLOWER_ITEM.PURPLE) 
                if remainNum > 0  then
                    local bOk, desc, surplus = BackpackMgr.UseItem(uid, FLOWER_ITEM.PURPLE, remainNum, "紫花-浇花完成剩余扣除")
                    if bOk == true then
                        table.insert(recycleList, {goodId=Const.GOODS_ID.GOLD_BASE, goodNum=remainNum * taskFlowerConfig.purpleRecovery})
                    end
                end
            end
        end

        send["data"] = {
            errno = 0,
            desc  = "成功",
            isBigReward = isBigReward,
        }
    else
        local flowerInfo = flowerTaskInfo.goldList[flowerId]
        if  flowerInfo == nil then
            send["data"] = {
                errno = 2,
                desc  = "FlowerId不存在"
            }
            unilight.sendcmd(uid, send)
            return
        end
        if flowerInfo.isGet == 1 then
            send["data"] = {
                errno = 3,
                desc  = "FlowerId已经浇过"
            }
            unilight.sendcmd(uid, send)
            return
        end

        local bOk, desc, surplus = BackpackMgr.UseItem(uid, FLOWER_ITEM.GOLD, 1, "浇花扣除")
        if bOk ~= true then
            send["data"] = {
                errno = 4,
                desc = "物品数量不够",
            }
            unilight.sendcmd(uid, send)
            return
        end

        --改变标志
        flowerInfo.isGet = 1

        local isBigReward = 0
        for k, v in pairs(taskFlowerConfig.goldBaseReward) do
            table.insert(rewardList, {goodId=v.goodId, goodNum=v.goodNum})
        end
        --大奖
        if flowerInfo.isBigReward == 1 then
            for _, v in pairs(flowerTaskInfo.goldList) do
                if v.isGet == 0 then
                    v.isGet = 1
                end
            end
            --全部置已领取
            for k, v in pairs(taskFlowerConfig.goldBigReward) do
                table.insert(rewardList, {goodId=v.goodId, goodNum=v.goodNum})
            end
            isBigReward = 1


            --触发大奖扣除所有道具
            local remainNum = BackpackMgr.GetItemNumByGoodId(uid, FLOWER_ITEM.GOLD) 
            if remainNum > 0  then
                local bOk, desc = BackpackMgr.UseItem(uid, FLOWER_ITEM.GOLD, remainNum, "金花-浇花大奖剩余扣除")
                if bOk == true then
                    table.insert(recycleList, {goodId=Const.GOODS_ID.GOLD_BASE, goodNum=remainNum * taskFlowerConfig.goldRecovery})
                end
            end
        else
            --扣除剩余
            local allFinish = true
            for _, v in pairs(flowerTaskInfo.goldList) do
                if v.isGet == 0 then
                    allFinish = false
                    break
                end
            end

            if allFinish then
                local remainNum = BackpackMgr.GetItemNumByGoodId(uid, FLOWER_ITEM.GOLD) 
                if remainNum > 0  then
                    local bOk, desc = BackpackMgr.UseItem(uid, FLOWER_ITEM.GOLD, remainNum, "金花-浇花完成剩余扣除")
                    if bOk == true then
                        table.insert(recycleList, {goodId=Const.GOODS_ID.GOLD_BASE, goodNum=remainNum * taskFlowerConfig.goldRecovery})
                    end
                end

            end
        end

        send["data"] = {
            errno = 0,
            desc  = "成功",
            isBigReward = isBigReward,
        }
    end

    unilight.savedata(DYAS_TASK_DB_NAME, userTasks)

    local summary = {}
    for k, v in pairs(rewardList) do
        summary = BackpackMgr.GetRewardGood(uid, v.goodId, v.goodNum, Const.GOODS_SOURCE_TYPE.TASK, summary)
    end
    send.data.rewardList = {}
    for k, v in pairs(summary) do
        table.insert(send.data.rewardList, {goodId=k, goodNum=v})
    end

    summary = {}
    for k, v in pairs(recycleList) do
        summary = BackpackMgr.GetRewardGood(uid, v.goodId, v.goodNum, Const.GOODS_SOURCE_TYPE.TASK, summary)
    end
    
    send.data.recycleList = {}
    for k, v in pairs(summary) do
        table.insert(send.data.recycleList, {goodId=k, goodNum=v})
    end
    unilight.sendcmd(uid, send)
end


-- 获取当前玩家 进入指定游戏  最合适的场次
function GetCorrectToGo(uid, gameId)
	local subGameId = 0
	local roomType = 0

	local subGameId, roomType = EnterGameMgr.GetCorrectRoomType(uid, gameId)

	-- subGameId = 0 时 代表该 游戏没有选场 
	if subGameId ~= 0 and roomType == 0 then 
		return 2, "筹码不足 不能找到合适的场"
	end

	return 0, "成功前往任务", subGameId, roomType
end

--是否在浇花时间
function IsInWaterFlower(flowerTaskInfo)
    local isOk = false
    local curTime = os.time()
    local beginTime = chessutil.GetMorningWeekNo2Time(flowerTaskInfo.lastWeekNo + 1) - 86400
    local endTime   = chessutil.GetMorningWeekNo2Time(flowerTaskInfo.lastWeekNo + 1)
    if curTime >= beginTime and curTime < endTime then
        isOk = true
    end
    return isOk
end 


--增加任务完成状态
function AddTaskNum(uid, taskType, num)
	local userTasks = unilight.getdata(DYAS_TASK_DB_NAME, uid)
    if userTasks == nil then
        userTasks = UserTaskConstuct(uid)
    end

    local daysTaskInfo = userTasks.daysTaskInfo
    local seasonTaskInfo = userTasks.seasonTaskInfo

    local taskConfig = tableTaskConfig[daysTaskInfo.taskId]
    local bUpdate = false
    if taskConfig.taskClass == taskType then
        daysTaskInfo.curNum = daysTaskInfo.curNum + num        
        if daysTaskInfo.curNum >= taskConfig.finishNum then
            daysTaskInfo.curNum = taskConfig.finishNum
            daysTaskInfo.status = TASK_STATUS.DONE
        end
        bUpdate = true
        unilight.info(string.format("玩家:%d,增加任务完成状态,taskType=%d, num=%d, totalNum=", uid, taskType, num, daysTaskInfo.curNum))
    end

    local taskConfig = tableTaskConfig[seasonTaskInfo.taskId]
    if taskConfig.taskClass == taskType then
        seasonTaskInfo.curNum = seasonTaskInfo.curNum + num        
        if seasonTaskInfo.curNum >= taskConfig.finishNum then
            seasonTaskInfo.curNum = taskConfig.finishNum
            seasonTaskInfo.status = TASK_STATUS.DONE
        end
        bUpdate = true
        unilight.info(string.format("玩家:%d,增加任务完成状态,taskType=%d, num=%d, totalNum=", uid, taskType, num, seasonTaskInfo.curNum))
    end

    if bUpdate then
        unilight.savedata(DYAS_TASK_DB_NAME, userTasks)
        GetTaskList(uid)
    end

end


--请求购买2倍加速卡
function ReqBuyFastBuff(uid)

	local userTasks = unilight.getdata(DYAS_TASK_DB_NAME, uid)
    local passTaskInfo = userTasks.passTaskInfo

	local send = {}
	send["do"] = "Cmd.ReqBuyFastBuffTask_S"
    local _, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, CalcDoubleBuffDiamond(passTaskInfo.buyDoublePointNum), "任务购买2倍加速buff")
    if ok == false then
        send["data"] = {
            errno = 1,
            msg   = "货币不够，购买失败"
        }
        unilight.sendcmd(uid, send)
        return
    end
    send["data"] = {
        errno = 0,
        msg   = "购买成功"
    }

    passTaskInfo.buyDoublePointNum = passTaskInfo.buyDoublePointNum + 1
    unilight.savedata(DYAS_TASK_DB_NAME, userTasks)

    unilight.sendcmd(uid, send)
    if passTaskInfo.buyDoublePointNum  == 1 then
        for _, goodInfo in pairs(taskOtherConfig.firstDoubleBuff) do
            BackpackMgr.GetRewardGood(uid, goodInfo.goodId, goodInfo.goodNum, Const.GOODS_SOURCE_TYPE.TASK)
        end
    else
        for _, goodInfo in pairs(taskOtherConfig.longDoubleBuff) do
            BackpackMgr.GetRewardGood(uid, goodInfo.goodId, goodInfo.goodNum, Const.GOODS_SOURCE_TYPE.TASK)
        end
    end

end


--请求保险箱奖励
function GetPassBoxReward(uid)

	local userTasks = unilight.getdata(DYAS_TASK_DB_NAME, uid)
    local passTaskInfo = userTasks.passTaskInfo

	local send = {}
	send["do"] = "Cmd.GetPassBoxReward_S"

    send.data = {
        errno = 0,
        desc  = "领取成功"
    } 

    if CheckPassNormalReward(uid) == false then
        send.data = {
            errno = 1,
            desc  = "没有购买通行证，不能领取"
        }
        unilight.sendcmd(uid, send)
        return
    end


    local rewardList = {}
    --额外的积分
    local chips = 0
    if passTaskInfo.extPoint < taskOtherConfig.passPointMaxExt then
        send["data"] = {
            errno = 2,
            desc  = "积分不足，不能兑换"
        }
        unilight.sendcmd(uid, send)
        return
    end

    local chipCount = passTaskInfo.extPoint / taskOtherConfig.passPointMaxExt
    local remainPoint = passTaskInfo.extPoint % taskOtherConfig.passPointMaxExt
    passTaskInfo.extPoint = remainPoint
    chips  = math.floor(chipCount * taskOtherConfig.passPointChips)
    table.insert(rewardList, {goodId=Const.GOODS_ID.GOLD_BASE, goodNum=chips})

    for _, goodInfo in pairs(rewardList) do
        BackpackMgr.GetRewardGood(uid, goodInfo.goodId, goodInfo.goodNum, Const.GOODS_SOURCE_TYPE.TASK)
    end

    unilight.savedata(DYAS_TASK_DB_NAME, userTasks)

    send.data.rewardList = rewardList
    unilight.sendcmd(uid, send)

    GetTaskList(uid)


end

--是否可以领取通行证任务奖励
function CheckPassNormalReward(uid)
    if BuffMgr.GetBuffByBuffId(uid, Const.BUFF_TYPE_ID.DAYTASK_PASS) ~= nil or BuffMgr.GetBuffByBuffId(uid, Const.BUFF_TYPE_ID.DAYTASK_PASS_DOUBLE) ~= nil then
        return true
    end

    return false
end

--是否可以领取通行证双倍金币
function CheckPassDoubleReward(uid)
    if BuffMgr.GetBuffByBuffId(uid, Const.BUFF_TYPE_ID.DAYTASK_PASS_DOUBLE) ~= nil then
        return true
    end
    return false
end


--充值后增加购买次数
function AddPassBuyCount(uid, shopId)
    local userTasks = unilight.getdata(DYAS_TASK_DB_NAME, uid)
    local passTaskInfo = userTasks.passTaskInfo
    local bUpdate = false
    for version, buyPassInfo in pairs(tableTaskVerion) do
        if buyPassInfo.firsPassShopId == shopId or buyPassInfo.secondPassShopId == shopId or buyPassInfo.longPassShopId == shopId then
            passTaskInfo.buyPassCount = passTaskInfo.buyPassCount + 1
            bUpdate = true 
            break
        end

        if buyPassInfo.firstDoubleShopId == shopId or buyPassInfo.secondDoubleShopId == shopId or buyPassInfo.longDoubleShopId == shopId then
            passTaskInfo.buyDoubleCount = passTaskInfo.buyDoubleCount + 1
            bUpdate = true
            break
        end
    end
    if bUpdate then
        unilight.info(string.format("玩家:%d, 充值后增加购买次数, 通行证次数:%d, 双倍通行证次数:%d", uid, passTaskInfo.buyPassCount, passTaskInfo.buyDoubleCount))
        unilight.savedata(DYAS_TASK_DB_NAME, userTasks)
    end

end


--获得额外活动奖励
function GetActivityReward(uid, round, level, rewardType)
    local rewardList = {}
    local activityId = ActivityMgr.GetOpenActivityID()
    local key = round * 10000 +  level * 10 + activityId
    local activityPassConfig = tableActivityPassTask[key]
    if activityPassConfig  ~= nil then
        --免费奖励
        if rewardType == REWARD_FREE then
            for _, rewardInfo in  pairs(activityPassConfig.freeReward) do
                table.insert(rewardList, rewardInfo)
            end
        end
        if rewardType == REWARD_PAY then
            --付费活动奖励
            if CheckPassNormalReward(uid) then
                for _, rewardInfo in  pairs(activityPassConfig.payReward) do
                    table.insert(rewardList, rewardInfo)
                end
            end
        end
    end
    return rewardList
end
