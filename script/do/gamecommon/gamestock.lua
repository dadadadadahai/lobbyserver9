module('gamestock',package.seeall)
-- {
--     _id   增长
--     gameId
--     gameType
--     value
-- }
--库存缓冲结构体
local stockmap={}
local table_game_list = import 'table/table_game_list'
local table_stock_tax = import 'table/table_stock_tax'
table_stock_xs_1 = import 'table/table_stock_xs_1'
local table_stock_xs_2 = import 'table/table_stock_xs_2'
local table_stock_single = import 'table/table_stock_single'
--初始化库存
function LoadStock()
    -- if unilight.getdebuglevel() >0 then    
    --     --加载所有
    --     -- local data = unilight.getByFilter('slotsStock',{},200)
    --     local data = unilight.getAll('slotsStock')
    --     for _, value in ipairs(data) do
    --         local gameId = value.gameId
    --         local gameType = value.gameType
    --         local keyval = gameId*10000 + gameType
    --         stockmap[keyval] = value.value
    --     end
    -- else
    --     --正式环境
    --     local zoneid = unilight.getzoneid()
    --     local isInArrays=function (val,arrays)
    --         for _, value in ipairs(arrays) do
    --             if value==val then
    --                 return true
    --             end
    --         end
    --         return false
    --     end
    --     for _,value in pairs(table_game_list) do
    --         if isInArrays(zoneid,value.rechargeZone) then
    --             local gameId = value.subGameId
    --             local gameType = value.roomType
    --             local keyval = gameId*10000 + gameType
    --             data =  unilight.getdata('slotsStock',keyval)
    --             if data~=nil then
    --                 stockmap[keyval] = data.value
    --             end
    --         end
    --     end
    -- end
end
--初始化库存
function initStock(keyval,gameType)
    -- if stockmap[keyval]~=nil then
    --     return
    -- end
    -- if unilight.getdebuglevel() >0 then
    --     stockmap[keyval] = table_stock_tax[keyval].initStock
    -- else
    --     local zoneid = unilight.getzoneid()
    --     local isInArrays=function (val,arrays)
    --         for _, value in ipairs(arrays) do
    --             if value==val then
    --                 return true
    --             end
    --         end
    --         return false
    --     end
    --     for _,value in pairs(table_game_list) do
    --         if isInArrays(zoneid,value.rechargeZone) then
    --             local gameId = value.subGameId
    --             local gameType = value.roomType
    --             local bkeyval = gameId*10000 + gameType
    --             if bkeyval~=keyval then
    --                 return
    --             end
    --             stockmap[keyval] = table_stock_tax[keyval].initStock
    --             break
    --         end
    --     end
    -- end
end
--获取库存对应的RTP
function GetStockRtp(gameId,gameType)
    -- local stockNum = GetStock(gameId,gameType)
    -- local stockcfg = gamestock['table_stock_xs_'..gameType]
    -- for _, value in ipairs(stockcfg) do
    --     if stockNum>=value.stockMin and stockNum<=value.stockMax then
    --         return value.rtpXS
    --     end
    -- end
    -- local stockNum = GetStock(gameId,gameType)
    -- local stockcfg = table_stock_xs_1
    -- if gameId==127 then
    --     stockcfg = table_stock_xs_2
    -- end
    -- local taxcfg = table_stock_single[gameType]
    -- for _, value in ipairs(stockcfg) do
    --     if stockNum>value.stockMin*taxcfg.initStock/100 and stockNum<=value.stockMax*taxcfg.initStock/100 then
    --         return value.rtpXS
    --     end
    -- end
    -- return 10000
    local subplatid = 1
    local key = gameId*1000000+ unilight.getzoneid() * 1000 + subplatid * 10 + gameType
    -- if table_game_list[key]~=nil then
    --     return table_game_list[key].RTP4
    -- end
    local keyRtp = gameId*10000+gameType
    print('keyRtp',keyRtp)
    local rtp4 =  table_game_list[keyRtp].RTP4 or 10000
    -- if gameDetaillog.prcentRtpMap[key]~=nil then
    --     print('gameDetaillog.prcentRtpMap[key]~=nil',gameDetaillog.prcentRtpMap[key].twin,gameDetaillog.prcentRtpMap[key].tchip)
    --     local rtp = gameDetaillog.prcentRtpMap[key].twin/gameDetaillog.prcentRtpMap[key].tchip*100
    --     rtp = rtp / rtp4 *10000
    --     print('calcRtp',rtp)
    --     for _, value in ipairs(table_stock_xs_1) do
    --         if rtp>=value.stockMin and rtp<=value.stockMax then
    --             print('value.rtpXS',value.rtpXS)
    --             return rtp4*value.rtpXS/10000
    --         end
    --     end
    -- end
    print('value.rtpXS=9850')
    return rtp4
end
--获取库存
function GetStock(gameId,gameType)
    -- local keyval = gameId*10000 + gameType
    -- initStock(keyval,gameType)
    -- return stockmap[keyval]
    -- return gamestockredis.getStock(gameId,gameType)
    return 0
end
--变化库存
function IncStock(gameId,gameType,val)
    -- local keyval = gameId*10000 + gameType
    -- initStock(keyval,gameType)
    -- stockmap[keyval] = stockmap[keyval] + val
    -- print('edit stock',val,gameId,gameType)
    -- gamestockredis.editStock(gameId,gameType,val)
end
--增加较少库存
function RawStock(gameId,gameType,betchip,winScore,userinfo)
    -- if userinfo.point.IsNormal==1 then
    --     addscore =  betchip*(10000-GetTaxXs(gameId,gameType))/10000
    --     addscore = addscore - GamePoolAddPer(betchip,gameId,gameType)
    --     --正常玩家影响库存
    --     local stock = addscore - winScore
    --     IncStock(gameId,gameType,stock)
    -- elseif userinfo.property.presentChips>0 or userinfo.property.isInPresentChips==1  then
    --     if userinfo.property.totalRechargeChips<=3000 then
    --         userinfo.property.presentChips = userinfo.property.presentChips - betchip
    --     else
    --         local decchip = winScore - betchip
    --         userinfo.property.presentChips = userinfo.property.presentChips + decchip
    --     end
    --     if userinfo.property.presentChips<0 then
    --         userinfo.property.presentChips = 0
    --     end
    --     -- print('userinfo.property.presentChips',userinfo.property.presentChips)
    -- end
    if userinfo.property.presentChips>0 or userinfo.property.isInPresentChips==1  then
        if userinfo.property.totalRechargeChips<=3000 then
            userinfo.property.presentChips = userinfo.property.presentChips - betchip
        else
            local decchip = winScore - betchip
            userinfo.property.presentChips = userinfo.property.presentChips + decchip
        end
        if userinfo.property.presentChips<0 then
            userinfo.property.presentChips = 0
        end
    -- print('userinfo.property.presentChips',userinfo.property.presentChips)
    end
end
--[[
    获取抽水系数
]]
function GetTaxXs(gameId,gameType)
    local xs = 0
    -- local keyval = gameId*10000 + gameType
    -- if table_stock_tax[keyval]~=nil then
    --     xs = table_stock_tax[keyval].taxPercent
    -- end
    -- print('tax',xs)
    if table_stock_single[gameType]~=nil then
        xs = table_stock_single[gameType].taxPercent
    end
    return xs
end
--[[
    确定奖池抽水值
]]
function GamePoolAddPer(chip,gameId,gameType)
    if gameId==109 or gameId == 105 or gameId ==121 or gameId == 124 or gameId == 126 or gameId==125 or gameId==115 then
        return 0
    end
    local addrealscore = 0
    --112 114 123
    if gameId==112 or gameId==114 or gameId==123 then
        local gameobj = gamecommon.NameJackMap[gameId]
        if gameobj==nil then
            return 0
        end
        local session = gameobj.sessions[gameType]
        local table_jackpot_add_per = gameobj.configTable.table_jackpot_add_pers[gameType]
        for poolid,_ in ipairs(session.realPools) do
            local addRealPoolPer = table_jackpot_add_per[poolid].addRealPoolPer
            addrealscore = addrealscore + chip*addRealPoolPer/10000
        end
        return addrealscore
    else
        local gamePool     = gamecommon.GAME_POOL_CONFIG[gameId]
        if gamePool==nil then
            return 0
        end
        local addRealPoolPer =  gamePool.poolConfigs.addPerConfigs[gameType].addRealPoolPer
        addrealscore = addrealscore + chip*addRealPoolPer/10000
        return addrealscore
    end
    return 0
end
--服务关闭时保存数据
function FlushData()
    -- for keyval,value in pairs(stockmap) do
    --     local gameId = math.floor(keyval/10000)
    --     local gameType =  keyval%10
    --     local data={
    --         _id = keyval,
    --         gameId = gameId,
    --         gameType = gameType,
    --         value = value
    --     }
    --     unilight.savedata('slotsStock',data)
    -- end
end
--后台获取库存
function BackGetStock(gameId,gameType)
    return GetStock(gameId,gameType)
end
--后台修改库存
function EditStock(gameId,gameType,val)
    -- print('edit')
    -- local keyval = gameId*10000 + gameType
    -- stockmap[keyval] = val
end