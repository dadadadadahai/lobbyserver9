module('cacaNiQuEls', package.seeall)
local blueLuckPos = 10
local redLuckPos = 22
-- 进行最终返回
function CalcFinallResult(gameType,sysWin,bets,betChip)
    local res={
        iconid = 0,
        mul = 0,
        position = 0,       --转动棋盘位置
        WinScore=0,
        redLuckType=0,      --三元四元
        redIconInfo={},
        trainInfo={},       --开火车信息{num,infos}
    }
    if sysWin == 0 then
       --纯随机
       res.position,res.iconid,res.mul = GetFinallIdByRandom()
    elseif sysWin==1 then
        --系统赢
        res.position,res.iconid,res.mul =SysWinResult(gameType,bets,betChip)
    else
        --系统输
        res.position,res.iconid,res.mul =SysLostResult(gameType,bets,betChip)
    end
    local minBet = table_204_sessions[gameType].minBet
    if gmInfo.free==1 then
        --大小三元
        res.position = 22
        res.iconid = 100
        res.mul = 0
    elseif gmInfo.sfree==1 then
        res.position= 10
        res.mul = 0
        res.iconid = 101
    end
    --进行中奖图标判断
    res.WinScore = IconWin(gameType,res.iconid,bets)
    --进行大小三元判定
    if res.iconid==100 then
        local id = gamecommon.CommRandInt(table_204_redluck,'gailv')
        if id==1 then
            --大三元
            res.redLuckType = 1
            --大元素中奖
            if bets[5]>0 then
                local winScore = iconMulMap[10]*bets[5]*table_204_sessions[gameType].minBet
                table.insert(res.redIconInfo,{iconid = 10,WinScore = winScore})
                res.WinScore = res.WinScore + winScore
            end 
            if bets[6]>0 then
                local winScore = iconMulMap[12]*bets[6]*table_204_sessions[gameType].minBet
                table.insert(res.redIconInfo,{iconid = 12,WinScore = winScore})
                res.WinScore = res.WinScore + winScore
            end
            if bets[7]>0 then
                local winScore = iconMulMap[14]*bets[7]*table_204_sessions[gameType].minBet
                table.insert(res.redIconInfo,{iconid = 14,WinScore = winScore})
                res.WinScore = res.WinScore + winScore
            end
        elseif id==2 then
            --小三元
            res.redLuckType = 2
            if bets[2]>0 then
                local winScore = iconMulMap[4]*bets[2]*table_204_sessions[gameType].minBet
                table.insert(res.redIconInfo,{iconid = 4,WinScore = winScore})
                res.WinScore = res.WinScore + winScore
            end
            if bets[3]>0 then
                local winScore = iconMulMap[6]*bets[3]*table_204_sessions[gameType].minBet
                table.insert(res.redIconInfo,{iconid = 6,WinScore = winScore})
                res.WinScore = res.WinScore + winScore
            end
            if bets[4]>0 then
                local winScore = iconMulMap[8]*bets[4]*table_204_sessions[gameType].minBet
                table.insert(res.redIconInfo,{iconid = 8,WinScore = winScore})
                res.WinScore = res.WinScore + winScore
            end
        else
            --小四喜
            res.redLuckType = 3
            if bets[1]>0 then
                for i=1,4 do
                    local winScore = iconMulMap[2]*bets[1]*table_204_sessions[gameType].minBet
                    table.insert(res.redIconInfo,{iconid = 2,WinScore = winScore})
                    res.WinScore = res.WinScore + winScore
                end
            end
        end
    elseif res.iconid==101 then
        --开火车
        local num = table_204_blueluck[gamecommon.CommRandInt(table_204_blueluck,'gailv')].num
        res.trainInfo.num = num
        local traincfg = table_204_train[gamecommon.CommRandInt(table_204_train,'gailv'..num)]
        local position = traincfg.ID
        res.trainInfo.infos={}
        for i=1,num do
            if position>#maps then
                position = position - #maps
            end
            local iconid = maps[position]
            local mul = iconMulMap[iconid]
            local WinScore = 0
            for index, value in ipairs(bets) do
                if value>0 then
                    local iconBets = betCfg[index]
                    if iconBets[1]==iconid or iconBets[2]==iconid then
                        --押中当前图标
                         WinScore = mul * minBet*value
                         break
                    end
                end
            end
            table.insert(res.trainInfo.infos,{position=position,iconid=iconid,mul=mul,WinScore=WinScore})
            res.WinScore = res.WinScore + WinScore
            position = position+1
        end
    end
    return res
end
--纯随机处理
function GetFinallIdByRandom()
    local g = table_204_gailv[gamecommon.CommRandInt(table_204_gailv,'gailv')]
    local posRand = {}
    for index, value in ipairs(maps) do
        if value==g.iconid then
            table.insert(posRand,index)
        end
    end
    local pos = math.random(#posRand)
    return posRand[pos],g.iconid,g.mul
end
--系统输判定
function SysLostResult(gameType,bets,betChip)
    local UserlostPools={}      --用户输的随机选择池
    for i=1,#maps do
        if i~=blueLuckPos and i~=redLuckPos then
            local winScore = IconWin(gameType,maps[i],bets)
            if winScore>=betChip then
                table.insert(UserlostPools,i)
            end
        end
    end
    if #UserlostPools<=0 then
        return GetFinallIdByRandom()
    else
        local posrand = math.random(#UserlostPools)
        local iconid = maps[UserlostPools[posrand]]
        local mul = iconMulMap[iconid]
        return UserlostPools[posrand],iconid,mul
    end
end

--系统赢判定 排除特殊图标
function SysWinResult(gameType,bets,betChip)
    local UserlostPools={}      --用户输的随机选择池
    for i=1,#maps do
        if i~=blueLuckPos and i~=redLuckPos then
            local winScore = IconWin(gameType,maps[i],bets)
            if winScore<=betChip then
                table.insert(UserlostPools,i)
            end
        end
    end
    if #UserlostPools<=0 then
        return GetFinallIdByRandom()
    else
        local posrand = math.random(#UserlostPools)
        local iconid = maps[UserlostPools[posrand]]
        local mul = iconMulMap[iconid]
        return UserlostPools[posrand],iconid,mul
    end
end
--图标玩家赢的金额
function IconWin(gameType,NiconId,bets)
    local minBet = table_204_sessions[gameType].minBet
    local WinScore = 0
    for index, value in ipairs(bets) do
        if value>0 then
            local iconBets = betCfg[index]
            if iconBets[1]==NiconId or iconBets[2]==NiconId then
                --押中当前图标
                 WinScore = iconMulMap[NiconId] * minBet*value
                 return WinScore
            end
        end
    end
    return WinScore
end