module('gamecommon',package.seeall)
Const_Stock_Type={
    GAMES  = 1,
    MIN    = 2,
}
--外围游戏通用处理
OutJackMap={}           --库存衰减处理
--注册库存衰减通用处理
function RegisterStockDec(gameId,gameType,Table,StockCfg)
    OutJackMap[gameId] = OutJackMap[gameId] or {}
    local oj = OutJackMap[gameId][gameType]
    if oj==nil then
        OutJackMap[gameId][gameType]={
            StockCfg = StockCfg,
            Table = Table,
            gameType = gameType,
            count = 0,
            sTime=os.time(),
        }
    else
        oj.StockCfg = StockCfg
        oj.Table = Table
        oj.gameType = gameType
    end
end
--局数衰减
function AddGamesCount(gameId,gameType)
    OutJackMap[gameId] = OutJackMap[gameId] or {}
    local oj = OutJackMap[gameId][gameType]
    if oj~=nil then
        if oj.StockCfg.type == Const_Stock_Type.GAMES then
            oj.count = oj.count + 1
            if oj.count>=oj.StockCfg.per then
                --执行衰减
                local Table = oj.Table
                if Table.Stock~=nil and Table.Stock>0 then
                    -- Table.Stock = Table.Stock*(1-oj.StockCfg.decPercent/100)
                    local rstock = Table.Stock*(oj.StockCfg.decPercent/100)
                    -- local rdecval = Table.Stock - rstock
                    --当前衰减值
                    Table.decval = Table.decval + rstock
                    -- print('Table.decval + rdecval=',Table.decval)
                    gameDetaillog.AttenuationVal(gameId,gameType,rstock)
                    Table.Stock = Table.Stock - rstock
                    print(string.format('AddGamesCount,gameid=%d rstock=%d',gameId,rstock))
                end
                oj.count = 0
            end
        end
    end
end
--每分钟执行一次
function StockTimer()
    local timeNow = os.time()
    for gameId, gameIdOj in pairs(OutJackMap) do
        -- print(string.format('StockTimer gameId=%d',gameId))
        for gameType, oj in pairs(gameIdOj) do
            if oj.StockCfg.type==Const_Stock_Type.MIN then
                if timeNow - oj.sTime>=oj.StockCfg.per*60 then
                    local Table = oj.Table
                    if Table.Stock~=nil and Table.Stock>0 then
                        local rstock = Table.Stock*(oj.StockCfg.decPercent/100)
                        -- local rdecval = Table.Stock - rstock
                        --记录当前衰减值
                        Table.decval = Table.decval + rstock
                        --当前衰减值
                        gameDetaillog.AttenuationVal(gameId,gameType,rstock)
                        Table.Stock = Table.Stock - rstock
                        -- print(string.format('rdecval=%d,gameId=%d',Table.decval,gameId))
                        -- print(string.format('rdecval=%d',Table.decval))
                    end
                    oj.sTime = os.time()
                end
            end
        end
    end
end

--启动定时器
unilight.addtimer("gamecommon.StockTimer", 60)