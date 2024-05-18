module('gamestockredis',package.seeall)
local table_stock_single = import 'table/table_stock_single'
local stockMap = {}
--redis初始化库存
function InitStockToRedis()
    -- print('===============================')
    -- for _,value in ipairs(table_stock_single) do        
    --     local gameType = value.gameType
    --     local tigerGameType = 127*100+gameType
    --     local numcfg = unilight.getdata('slotsStock',gameType)
    --     if numcfg==nil then
    --         numcfg={_id=gameType,num = value.initStock}
    --         unilight.savedata('slotsStock',numcfg)
    --     end
    --     stockMap[gameType] = numcfg.num
    --     local tigerNumCfg = unilight.getdata('slotsStock',tigerGameType)
    --     if tigerNumCfg==nil then
    --         tigerNumCfg={_id=tigerGameType,num = value.initStock}
    --         unilight.savedata('slotsStock',tigerNumCfg)
    --     end
    --     stockMap[tigerGameType] = tigerNumCfg.num
    -- end
end
function loadStock(gameId,gameType)
    -- if gameId==127 or gameId ==131 or gameId==132 then
    --     gameType= 127*100+gameType
    -- end
    -- stockMap[gameType] = unilight.getdata('slotsStock',gameType).num

end
function getStock(gameId,gameType)
    -- if gameId==127 or gameId ==131 or gameId==132 then
    --     gameType= 127*100+gameType
    -- end
    -- return stockMap[gameType]
end
function editStock(gameId,gameType,val)
    -- if gameId==127 or gameId ==131 or gameId==132 then
    --     gameType= 127*100+gameType
    -- end
    -- unilight.incdate('slotsStock',gameType,{num=val})
    -- stockMap[gameType]=stockMap[gameType] + val
end