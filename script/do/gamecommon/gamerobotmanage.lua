module('gamecommon', package.seeall)
Robot = {}
local RobotStatus = {
    Betting = 1, --下注阶段
    Settle = 2, --结算阶段
}
function Robot:New(module, Table, bets, adnum, gold, quit, bTime, bNum, bili, area)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    obj.module = module
    obj.bets = bets
    obj.adnum = adnum
    obj.gold = gold
    obj.quit = quit
    obj.bTime = bTime
    obj.bNum = bNum
    obj.bili = bili
    obj.area = area
    obj.robot = {} --机器人对象       {uid,gender,nickName,lTime,betinfo={betUpTime,betTImes}}  lTime 离开时间戳  betUpTime 下注持续时间
    obj.latestTime = 0 --上一次操作的时间戳
    obj.Table = Table
    obj.Status = 0 --0 其他状态  1 下注状态
    return obj
end

--请求机器人,进场
function Robot:RequestRebot()
    local tmin, tmax = self.adnum[1].tmin, self.adnum[1].tmax
    local realRobotNum = #self.robot
    if realRobotNum >= tmax then
        return
    end
    local realQuest = tmin - realRobotNum
    if realQuest > 0 then
        ReqRobotList(self.module.GameId, realQuest, self.Table.RoomId)
    else
        --随机选择,进入
        local r = math.random(10000)
        if r <= self.adnum[1].gailv then
            --机器人需要进入
            ReqRobotList(self.module.GameId, 1, self.Table.RoomId)
            --print('request enter')
        end
    end
end

--机器人加入
function Robot:RspRobotList(data)
    local timeNow = os.time()
    for _, value in ipairs(data.robotList) do
        local goldcfg = self.gold[gamecommon.CommRandInt(self.gold, 'gailv')]
        local chip = math.random(goldcfg.gLow, goldcfg.gUp)
        local quitcfg = self.quit[gamecommon.CommRandInt(self.quit, 'gailv')]
        local lTime = math.random(quitcfg.low, quitcfg.up) + timeNow --离开时间
        local rebots = {
            uid = value.uid,
            gender = value.gender,
            nickName = value.nickName,
            chip = chip,
            lTime = lTime,
            betinfo = {} ,
            frameId = value.frameId,
        }
        table.insert(self.robot, rebots)
        if self.Status ~= RobotStatus.Betting then
            self:CreateGamesAction(rebots)
        end
        --调用模块机器人加入
        self.module.RobotEnter(rebots, self.Table)
    end
end

--机器人离开判断
function Robot:RobotLeave(timeNow)
    local robotIds = {}
    for i = #self.robot, 1, -1 do
        if timeNow >= self.robot[i].lTime and self.module.IsRobotLeave(self.robot[i].uid,self.Table) then
            self.module.RobotLeavel(self.robot[i].uid, self.Table)
            table.insert(robotIds, self.robot[i].uid)
            table.remove(self.robot, i)
        end
    end
    if #robotIds > 0 then
        gamecommon.ReqRobotRestore(self.module.GameId, robotIds)
    end
end

--机器人脉冲
function Robot:Pluse(timeNow)
    if timeNow - self.latestTime >= 1 then
        --机器人进入判断
        self:RequestRebot()
        if self.Status == RobotStatus.Betting then
            --print('self.Status == RobotStatus.Betting')
            --下注阶段
            local passMin = timeNow - self.Table.TableStatus.sTime
            local rebotBetNum = 0
            --遍历机器人
            for _, value in ipairs(self.robot) do
                if value.betinfo.betTImes ~= nil and value.betinfo.betTImes > 0 and value.betinfo.betUpTime > passMin and
                    passMin >= 1 then
                    --进入机器人随机下注判断
                    local r = math.random(100)
                    local tr = value.betinfo.betTImes / (value.betinfo.betUpTime - passMin) * 100
                    if r <= tr then
                        local num = 1
                        if tr > 100 then
                            num = math.floor(tr / 100)
                        end
                        -- print('num='..num)
                        for i = 1, num do
                            --进入下注区域多少判断
                            local betIndex, aftergold = self:CreateChipIndex(value.chip)
                            value.chip = aftergold
                            local area = self:CreateBetArea()
                            --调用桌面下注调用
                            if betIndex > 0 then
                                rebotBetNum = rebotBetNum + 1
                                local errnoobj = self.module.RobotBet(value.uid, betIndex, area, self.Table)
                                if errnoobj.errno==0 then
                                    value.betinfo.betTImes = value.betinfo.betTImes - 1
                                    value.betinfo.betUpTime = value.betinfo.betUpTime
                                end
                            end
                        end
                    end
                end
            end
            --print('rebotBetNum='..rebotBetNum)
        else
            --进行离开判断
            self:RobotLeave(timeNow)
        end
        self.latestTime = timeNow
    end
end

--产生索引筹码
function Robot:CreateChipIndex(gold)
    local betRatio = self.bili[CommRandInt(self.bili, 'gailv')].betRatio
    local betchip = gold * betRatio / 100
    local betIndex = 1
    for i = 1, #self.bets - 1 do
        if betchip >= self.bets[i] and betchip < self.bets[i + 1] then
            betIndex = i
            break
        end
    end
    --print('gold='..gold,'betRatio='..betRatio,'betchip='..betchip,'realChip='..self.bets[betIndex])
    local aftergold = gold - self.bets[betIndex]
    if aftergold <= 0 then
        return 0, gold
    end
    return betIndex, aftergold
end

--产生下注区域
function Robot:CreateBetArea()
    local area = self.area[CommRandInt(self.area, 'gailv')].area
    return area
end

--游戏进入押注阶段
function Robot:ChangeToBetting()
    --print('ChangeToBetting')
    self.Status = RobotStatus.Betting
end

--游戏进入结算阶段
--[[
    data[uid]={
        winScore = 0        --赢取的金额
    }
]]
function Robot:ChangeToSettle(data)
    --print('ChangeToSettle')
    self.Status = RobotStatus.Settle
    --进行机器人下局计算
    for _, value in ipairs(self.robot) do
        --机器人金币扣减
        if data[value.uid] ~= nil then
            local winScore = data[value.uid]
            value.chip = value.chip + winScore
        end
        self:CreateGamesAction(value)
    end
end

--产生机器人下注预制动作
function Robot:CreateGamesAction(rebotinfo)
    local bTimecfg = self.bTime[CommRandInt(self.bTime, 'gailv')]
    rebotinfo.betinfo.betUpTime = math.random(bTimecfg.low, bTimecfg.up) + 1
    --print('betUpTime='..rebotinfo.betinfo.betUpTime)
    local bNumcfg = self.bNum[CommRandInt(self.bNum, 'gailv')]
    rebotinfo.betinfo.betTImes = math.random(bNumcfg.low, bNumcfg.up)
    --print('betTImes='..rebotinfo.betinfo.betTImes)
    --  print(rebotinfo.betinfo.betUpTime,rebotinfo.betinfo.betTImes)
end
function Robot:GetGold(uid)
    for _, value in ipairs(self.robot) do
        if value.uid==uid then
            return value.chip
        end
    end
    return 0
end