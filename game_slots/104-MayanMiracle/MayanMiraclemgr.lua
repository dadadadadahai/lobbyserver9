module('MayanMiracle',package.seeall)

function CmdEnterGame(uid,msg)
    local datainfo = Get(msg.gameType, uid)
    local betConfig = gamecommon.GetBetConfig(msg.gameType,LineNum)
    -- local zinfo = datainfo.zMapInfo[datainfo.betindex] or {}
    local res={
        errno = 0,
        betConfig = betConfig,
        betIndex = datainfo.betindex,
        boards = datainfo.boards,
        bAllLine=LineNum,
        extraData = {
            -- zinfo = zinfo
        },
        features={
            bonus = PackPick(datainfo),
            free = PackFree(datainfo),
        },
    }
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end
function CmdGameOprate(uid,msg)
    local datainfo = Get(msg.gameType, uid)
    local res={}
    if table.empty(datainfo.pick)==false then
        res = Pick(datainfo, msg.gameType, uid)
        WithdrawCash.GetBetInfo(uid,Table,msg.gameType,res,false)
    elseif table.empty(datainfo.free)==false then
        res=Free(datainfo, msg.gameType, uid)
        WithdrawCash.GetBetInfo(uid,Table,msg.gameType,res,false)
    else
        res=Normal(msg.betIndex,msg.gameType, datainfo,uid)
        WithdrawCash.GetBetInfo(uid,Table,msg.gameType,res,true)
    end
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end
-- function CmdChangeBet(uid,msg)
--     local datainfo = Get(msg.gameType, uid)
--     if table.empty(datainfo.free) and table.empty(datainfo.pick) then
--         datainfo.betindex = msg.betIndex
--         local betConfig = gamecommon.GetBetConfig(mgs.gameType,LineNum)
--         local betMoney = betConfig[datainfo.betindex]
--         if betMoney==nil or betMoney<=0 then
--             return{
--                 errno=1,
--                 desc='参数不正确'
--             }
--         end
--         local zinfo = datainfo.zMapInfo[datainfo.betindex] or {}
--         local res={
--             errno = 0,
--             zinfo = zinfo
--         }
--         -- unilight.update(Table,datainfo._id,datainfo)
--         SaveGameInfo(uid,msg.gameType,datainfo)
--         gamecommon.SendNet(uid, 'ChangeBetCmd_S', res)
--     end
-- end
--注册消息解析
function RegisterProto()
    --52
    gamecommon.RegGame(GameId, MayanMiracle)
    -- gamecommon.RegChangeBet(GameId, CmdChangeBet)
    --gamecommon.GamePoolInit(GameId,LineNum,table_Luxury_jackpot[1])

    -- local poolConfigs = {
    --     chipsConfigs     = table_104_jackpot_chips,   --标准金额
    --     addPerConfigs    = table_104_jackpot_add_per, --奖池增加
    --     bombConfigs      = table_104_jackpot_bomb,    --奖池暴池概率
    --     scaleConfigs     = table_104_jackpot_scale,   --奖池爆池比例
    --     betConfigs       = table_104_jackpot_bet,     --奖池触发下注
    -- }
    -- gamecommon.GamePoolInit(GameId,poolConfigs)
    gamecommon.GamePoolInit(GameId)
    gamecommon.GetModuleCfg(GameId,MayanMiracle)
end