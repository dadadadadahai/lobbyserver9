module('gameIn',package.seeall)
Table='gameEnterOrLeave'
--[[
    gameEnterOrLeave
    uid,nickname,enterTime,leaveTime,enterChip,leaveChip,gameId,gameType
    enterTime 进入时间戳
    leaveTime 离开时间戳
    enterChip 进入时金币
    leaveChip 离开时金币
]]
--临时用户缓存
local tmpEnterLogMap={}
--游戏进出日志
--[[
    添加游戏进入日志
]]
function GamerEnterGame(uid,nickname,enterChip,gameId,gameType)
    if tmpEnterLogMap[uid]==nil then
        --记录进入日志
        local data={
            uid = uid,
            nickname = nickname,
            enterChip = enterChip,
            leaveChip = 0,
            gameId = gameId,
            gameType = gameType,
            enterTime = os.time(),
            leaveTime = 0,
        }
        --保存数据
        local _,id = unilight.savedata(Table,data)
        data._id = id
        tmpEnterLogMap[uid] = data
    end
end
--[[
    添加游戏离开日志
]]
function GamerLeaveGame(uid,leaveChip)
    local data = tmpEnterLogMap[uid]
    print('GamerLeaveGame')
    if data~=nil then
        data.leaveTime = os.time()
        data.leaveChip = leaveChip
        unilight.update(Table,data._id,data)
        tmpEnterLogMap[uid] = nil
        print('GamerLeaveGame 1')
        if gamecommon.allGameManagers[data.gameId]~=nil then
            local module = gamecommon.allGameManagers[data.gameId]
            --[[
                进行玩家数据统计
            ]]
            local gameId =  data.gameId
            local gameType = data.gameType
            local userinfo = unilight.getdata('userinfo',uid)
            local unsettleInfo = userinfo.unsettleInfo or {}
            local key = gameId*100+gameType
            local gDataInfo = module.Get(gameType,uid)
            local specialScene = {'bonus','pick','free','respin'}
            local btWinScore = unsettleInfo[key] or 0
            local atWinScore = 0
            for _, value in ipairs(specialScene) do
                if table.empty(gDataInfo[value])==false and gDataInfo[value].tWinScore>0 then
                    atWinScore = atWinScore + gDataInfo[value].tWinScore
                end
            end
            unsettleInfo[key] = atWinScore
            unilight.update('userinfo',uid,userinfo)
            print('leaveGame',atWinScore,btWinScore)
            chessuserinfodb.SetAheadScore(uid,atWinScore - btWinScore)
        end
    end
end