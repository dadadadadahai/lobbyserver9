module('gameDetaillog',package.seeall)
local table_ctr_autoadjust = import 'table/table_ctr_autoadjust'
local table_auto_pointLimit= import 'table/table_auto_pointLimit'
local gameMap = {}
--押注,赢取
function SetBetWin(gameId,gameType,type,tchip,twin)
    local keyval = gameId*1000000+ unilight.getzoneid() * 1000 + gameType
    gameMap[keyval] = gameMap[keyval] or {}
    gameMap[keyval][type] = gameMap[keyval][type] or {}
    gameMap[keyval][type] = {tchip=tchip,twin = twin}
    print('settype',type,tchip,twin)
end
--获取RTP系数
function getRtpXs(gameId,gameType,rtp,userinfo)
    local subplatid = userinfo.base.subplatid
    local keyval = gameId*1000000+ unilight.getzoneid() * 1000 + gameType
    local xs=1
    local type = 2
    if userinfo.property.presentChips>0 then
        type=CodingPlayerType(userinfo)
    elseif userinfo.property.totalRechargeChips>0 and userinfo.property.totalRechargeChips<=3000 then
        type=4 --低充值玩家
    elseif userinfo.property.totalRechargeChips>3000 then
        type = 1 --其余玩家
    end
    if gameMap[keyval] and gameMap[keyval][type] then
        local twin,tchip = gameMap[keyval][type].twin,gameMap[keyval][type].tchip
        local rtpxs = (twin/tchip)-rtp/10000
        for _,value in ipairs(table_ctr_autoadjust) do
            if rtpxs>=value.rtpLow and rtpxs<=value.rtpHight then
                xs = value.xs
                break
            end
        end
    end
    -- print('rtpxs',xs)
    return xs
end
--打码玩家分类
function CodingPlayerType(userinfo)
    local type = 3
    local totalRechargeChips = userinfo.property.totalRechargeChips
    for ID,value in ipairs(table_auto_pointLimit) do
        if totalRechargeChips>=value.chargeLow1 and totalRechargeChips<=value.chargeUp1 then
            if ID>1 then
                type=5
            end
            break
        end
    end
    return type
end