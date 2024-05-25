-- 下线下注流水返利
module('rebate',package.seeall)

-- 流水缓存
RebateList = {}
-- 添加流水的最小间隔事件
MinAddTime = 10
-- 流水返利表
RebateChipsTable = 'flowing_final'

-- 添加返利流水缓存
function AddRebateListChips(dbId,uid,chips)
    -- 获取玩家信息
    local userInfo = unilight.getdata('userinfo',uid)
    if userInfo.property.totalRechargeChips<=0 then
        return
    end
    -- if userInfo.status.experienceStatus == 0 then
    --     return
    -- end

    -- if (not UserInfo.HaveSuperiors(uid)) then
    --     return
    -- end
    -- 检测缓存
    if table.empty(RebateList[uid]) then
        RebateList[uid] = {
            dbId = dbId, -- 数据库主键ID
            chips = chips, -- 需要插入的流水
            lastAddTimes = 0, -- 上一次插入的时间戳
        }
    else
        RebateList[uid].chips = RebateList[uid].chips + chips
    end
    -- 增加返利流水(每局判断增加)
    AddRebateChips(uid,false)
end

-- 添加返利流水
function AddRebateChips(uid,roomEndFlag)
        -- 获取玩家信息
    local userInfo = unilight.getdata('userinfo',uid)
    if userInfo.status.experienceStatus == 0 then
        return
    end

    roomEndFlag = roomEndFlag or false
    local rebateInfo = RebateList[uid]
    if table.empty(rebateInfo) or rebateInfo.chips == 0 then
        return
    end
    -- 如果退出房间 或者 间隔时间满足最小流水添加事件则添加流水
    if roomEndFlag or os.time() - rebateInfo.lastAddTimes > MinAddTime then
        -- 如果有上级邀请则走邀请的下级返利逻辑
        if UserInfo.HaveSuperiors(uid) then
            -- 插入返利数据表
            local infoDB = {
                _id = rebateInfo.dbId,
                uid = uid,
                tchip = rebateInfo.chips
            }
            unilight.savedata(RebateChipsTable,infoDB)
        end
        -- 添加EX表本身自己下注
        unilight.incdate('extension_relation', uid, {tolBetAll=rebateInfo.chips})
        unilight.incdate('extension_relation', uid, {todayBetAll=rebateInfo.chips})
        -- 清理对应缓存
        RebateList[uid].chips = 0
        RebateList[uid].lastAddTimes = os.time()
    end
end