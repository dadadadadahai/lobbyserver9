--百人场虚拟人数
module('gamecommon', package.seeall)
local table_pnum_TimeNum = import 'table/table_pnum_TimeNum'
local table_pnum_Setting = import 'table/table_pnum_Setting'
HundredPeople={}            --百人人数
function HundredPeople:New(gameId,gameType,brdFunc)
    local obj = {}
    setmetatable(obj,self)
    self.__index = self
    obj.gameId = gameId     --游戏id
    obj.brdFunc = brdFunc   --广播函数
    obj.latestTime = 0      --上一次计算时间
    obj.curNum = 0          --当前在线人数
    obj.gameType = gameType
    return obj
end
function HundredPeople:get()
    return self.curNum
end
function HundredPeople:calc(timenow)
    if timenow-self.latestTime>=table_pnum_Setting[1].ctime then
        --间隔计算时间
        local h = tonumber(os.date('%H',timenow))
        local cfg={}
        --获取配置
        for index, value in ipairs(table_pnum_TimeNum) do
            if h>=value.min and h<value.max then
                cfg = value
                break
            end
        end
        local B = math.random(cfg.low,cfg.up)
        local A = self.curNum
        local X = math.random(table_pnum_Setting[1].low,table_pnum_Setting[1].up)
        if B>A then
            self.curNum = math.min(B,A+X)
        elseif B<A then
            self.curNum = math.max(B,A-X)
        end
        --调用推送消息
        local doInfo='Cmd.NumPeopleBrd_S'
        local data={
            errno =0,
            curNum = self.curNum,
        }
        self.brdFunc(doInfo,data,self.gameType)
        self.latestTime = timenow
    end
end