module('miner',package.seeall)
--全局配置数组
function CmdEnterGame(uid,msg)
    local res=GetSceneCmd_C(msg.gameType,uid)
    gamecommon.SendNet(uid, 'EnterSceneGame_S', res)
end

function CmdGameOprate(uid,msg)
    local res={}
    if msg.extraData.ctrType==1 then
        res = Spin(msg.gameType,msg.extraData.data,uid)
    elseif msg.extraData.ctrType==2 then
        res = Play(msg.gameType,msg.extraData.data,uid)
    elseif msg.extraData.ctrType==3 then
        res=Settle(msg.gameType,uid)
    end
    res.ctrType = msg.extraData.ctrType
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end

--游戏基本信息注册
function RegisterProto()
    gamecommon.RegGame(GameId, miner)
    -- gamecommon.GamePoolInit(GameId)
    --读取配置
    gamecommon.GetModuleCfg(GameId,miner)
    --初始化库存衰减
    for gameType,value in ipairs(table_210_sessions) do
        StockMap[gameType] = {Stock = value.initStock,tax =0,decval=0}
        gamecommon.RegisterStockDec(GameId,gameType,StockMap[gameType],table_210_other[gameType])
    end
end

local latestBombTime = 0
--机器人假奖池逻辑
function MinerRobotBomb()
    local timenow = os.time()
    if table_210_sessions == nil then return end
    for gameType,_ in ipairs(table_210_sessions) do
        if timenow-latestBombTime>=1 then
            latestBombTime = timenow
            local bombPro = math.random(10000)
            if bombPro<=table_210_jackpotpro[1].pro then
                -- local cfg = table_210_jackpotgrade[gamecommon.CommRandInt(table_210_jackpotgrade,'pro')]
                -- local betMin,betMax = cfg.betMin,cfg.betMax
                -- local betMoney = math.random(betMin,betMax)
                local mul = table_210_jackpotmul[gamecommon.CommRandInt(table_210_jackpotmul,'pro')].mul
                            -- 结构数据
                local params = {
                gameId = GameId,
                gameType = gameType,
                chips = 0,
                }
                params.extData = {
                    -- pool  = randomJackpotId,
                    mul   = mul,
                }
                --请求一个机器人
                gamecommon.ReqRobotList(GameId, 1, params)
            end
        end
    end
end