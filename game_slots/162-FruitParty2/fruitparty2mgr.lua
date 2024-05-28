module('fruitparty2',package.seeall)
--进入游戏场景消息

function CmdEnterGame(uid,msg)
    SetGameMold(uid,msg.demo)
    local gameType = msg.gameType
    local datainfo = Get(gameType,uid)
    local res={
        errno = 0,
        betConfig = gamecommon.GetBetConfig(gameType,LineNum), 
        betIndex = datainfo.betindex,
        bAllLine=LineNum,
        gameType = gameType,
        features={
            free = packFree(datainfo),      --是否存在免费  存在的话 就是刚才的数据
        },
        extraData={
            isInHight = datainfo.isInHight,         --无用
            freePrice = table_162_buyfree[1].price, --购买免费的钱
            betChange = table_162_buyfree[1].betChange, --无用
        }
    }
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
    if IsDemo(uid) then
        chessuserinfodb.DemoInitPoint(uid)
    end 
end

function CmdGameOprate(uid,msg)
    if   IsDemo(uid) then
        local datainfo = Get(msg.gameType,uid)
        local res={}
        if table.empty(datainfo.free)==false then
            res = FreeDemo(msg.gameType,datainfo,uid)
        else
            res = NormalDemo(msg.gameType,msg.betIndex,datainfo,uid)
            AddDemoNums(uid)
        end
         res.gameType = msg.gameType
        gamecommon.SendNet(uid, 'GameOprateGame_S', res)
    else
        -- for i = 1, 1000, 1 do
        --     local datainfo = Get(msg.gameType,uid)
        --     local res={}
        --     if table.empty(datainfo.free)==false then
        --         res = Free(msg.gameType,datainfo,uid)
        --     else
        --         msg.betIndex = math.random(12)
        --         res = Normal(msg.gameType,msg.betIndex,datainfo,uid)
        --     -- WithdrawCash.GetBetInfo(uid,Table,msg.gameType,res,true,GameId)
        --     end
        --     -- res.gameType = msg.gameType
        --       --  dump(res,"sweetBonanzaCmdGameOprate",10)
        --     -- gamecommon.SendNet(uid, 'GameOprateGame_S', res)
        -- end
        local datainfo = Get(msg.gameType,uid)
        local res={}
        if table.empty(datainfo.free)==false then
            res = Free(msg.gameType,datainfo,uid)
        else
           
            res = Normal(msg.gameType,msg.betIndex,datainfo,uid)
          WithdrawCash.GetBetInfo(uid,Table,msg.gameType,res,true,GameId)
        end
        res.gameType = msg.gameType
         dump(res,"sweetBonanzaCmdGameOprate",10)
        gamecommon.SendNet(uid, 'GameOprateGame_S', res)
    end
end
function CmdBuyFree(uid,msg)
    if   IsDemo(uid) then
        local datainfo = Get(msg.gameType,uid)
        local res = BuyFreeDemo(msg.gameType,msg.betIndex,datainfo,uid)
        res.gameType = msg.gameType
        gamecommon.SendNet(uid, 'GameOprateGame_S', res)
    else 
        -- for i = 1, 1000, 1 do
        --     local datainfo = Get(msg.gameType,uid)
        --     if table.empty(datainfo.free) ==false then
        --         res = Free(msg.gameType,datainfo,uid)
        --     else
        --         msg.betIndex = math.random(12)
        --         local res = BuyFree(msg.gameType,msg.betIndex,datainfo,uid)
        --     end 
        -- end
        local datainfo = Get(msg.gameType,uid)
        local res = BuyFree(msg.gameType,msg.betIndex,datainfo,uid)
        WithdrawCash.GetBetInfo(uid,Table,msg.gameType,res,true,GameId)
        res.gameType = msg.gameType
        dump(res,"sweetBonanzaCmdBuyFree",10)
        gamecommon.SendNet(uid, 'GameOprateGame_S', res)
    end
end
function CmdBuyHighBet(uid,msg)
    local datainfo = Get(msg.gameType,uid)
    local res = BuyHighBet(msg.highLevel,datainfo,msg.gameType,uid)
    res.gameType = msg.gameType
    gamecommon.SendNet(uid, 'HighBetCmd_S', res)
end
--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, fruitparty2)
    gamecommon.GetModuleCfg(GameId,fruitparty2)
    gameImagePool.loadPool(GameId)
end