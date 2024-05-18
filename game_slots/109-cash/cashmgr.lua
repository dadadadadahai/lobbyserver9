module('cash',package.seeall)
--进入游戏场景消息
function CmdEnterGame(uid,msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    local betconfig = gamecommon.GetBetConfig(gameType,LineNum)
    datainfo.iconsMap[datainfo.betindex] = datainfo.iconsMap[datainfo.betindex] or {}
    datainfo.chessdataBetIndex[datainfo.betindex] = datainfo.chessdataBetIndex[datainfo.betindex] or {}
    local iconsAttach = datainfo.iconsMap[datainfo.betindex]
    local boards={}
    table.insert(boards,datainfo.chessdataBetIndex[datainfo.betindex])
    local res={
        errno = 0,
        betConfig = betconfig,
        betIndex = datainfo.betindex,
        boards=boards,
        gameType = datainfos.gameType,
        bAllLine=LineNum,
        extraData={
            iconsAttach=iconsAttach,
            
        },
    }
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end
function CmdGameOprate(uid, msg)
    local gameId = msg.gameId
    local gameType = msg.gameType
    local datainfo, datainfos = Get(gameType, uid)
    local res = {}
    res = Normal(gameType, msg.betIndex, datainfo, datainfos, uid)
    res.gameType = gameType
    WithdrawCash.GetBetInfo(uid, Table, gameType, res, true)
    gamecommon.SendNet(uid, 'GameOprateGame_S', res)
end

function CmdChangeBet(uid,msg)
    local betindex = msg.betIndex
    local gameType = msg.gameType
    local datainfo,datainfos = Get(gameType,uid)
    datainfo.iconsMap[betindex] = datainfo.iconsMap[betindex] or {}
    datainfo.chessdataBetIndex[betindex] = datainfo.chessdataBetIndex[betindex] or {}
    local boards={}
    table.insert(boards,datainfo.chessdataBetIndex[betindex])
    local res={
        errno = 0,
        iconsAttach=datainfo.iconsMap[betindex],
        boards=boards,
    }
    gamecommon.SendNet(uid, 'ChangeBetCmd_S', res)
end

--注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, cash)
    gamecommon.RegChangeBet(GameId,CmdChangeBet)
    gamecommon.GetModuleCfg(GameId,cash)
    --gamecommon.GamePoolInit(GameId,LineNum,table_holloween_jackpot[1])
    -- 假奖池爆池给机器人配置
    -- local jackpotRobotTable = {
    --     JackpotGrade = import "table/game/109/table_109_jackpotgrade",             -- 爆池档次
    --     -- JackpotPool = import "table/game/109/table_109_jackpotpool",              -- 爆池奖池
    --     JackpotMul = import "table/game/109/table_109_jackpotmul",                 -- 爆池倍数
    --     JackpotPro = import "table/game/109/table_109_jackpotpro",                 -- 爆池概率
    -- }

    -- gamecommon.GamePoolInit2(GameId,Table_Base[1].linenum,Table_Jackpot[1],jackpotRobotTable)
    -- local table_109_jackpot_chips = import 'table/game/109/table_109_jackpot_chips'
    -- local table_109_jackpot_add_per = import 'table/game/109/table_109_jackpot_add_per'
    -- local table_109_jackpot_bomb = import 'table/game/109/table_109_jackpot_bomb'
    -- local table_109_jackpot_scale = import 'table/game/109/table_109_jackpot_scale'
    -- local table_109_jackpot_bet = import 'table/game/109/table_109_jackpot_bet'

    --为了gm后台修改配置
    -- local poolConfigs = {
    --     chipsConfigs     = table_109_jackpot_chips,   --标准金额
    --     addPerConfigs    = table_109_jackpot_add_per, --奖池增加
    --     bombConfigs      = table_109_jackpot_bomb,    --奖池暴池概率
    --     scaleConfigs     = table_109_jackpot_scale,   --奖池爆池比例
    --     betConfigs       = table_109_jackpot_bet,     --奖池触发下注
    -- }
    -- gamecommon.GamePoolInit(GameId,poolConfigs)
    -- gamecommon.GamePoolInit(GameId)
end
-- TEST_FLAG = true
function CashRobotHistory()
    -- 假奖池爆池给机器人配置
    local jackpotTable = {
        JackpotGrade = import "table/game/109/table_109_jackpotgrade",             -- 爆池档次
        --JackpotPool = import "table/game/109/table_109_jackpotpool",              -- 爆池奖池
        JackpotMul = import "table/game/109/table_109_jackpotmul",                 -- 爆池倍数
        JackpotPro = import "table/game/109/table_109_jackpotpro",                 -- 爆池概率
    }
    local gameId = GameId

    local gameTypeList = {1,2,3}
    for _, gameType in ipairs(gameTypeList) do
        -- 如果中奖
        if math.random(10000) < jackpotTable.JackpotPro[1].pro then
        -- if TEST_FLAG then
            local randomJackpotId
            if table.empty(jackpotTable.JackpotPool) == false then
                -- 随机爆池的奖池号
                local jackpotIdPro = {}
                local jackpotIdResult = {}
                for i, v in ipairs(jackpotTable.JackpotPool) do
                    if v.pro > 0 then
                        table.insert(jackpotIdPro, v.pro)
                        table.insert(jackpotIdResult, {v.pro, v.jackpot})
                    end
                end
                randomJackpotId = math.random(jackpotIdPro, jackpotIdResult)[2]
            end
            -- 随机爆池档次
            local jackpotPoolPro = {}
            local jackpotPoolResult = {}
            for i, v in ipairs(jackpotTable.JackpotGrade) do
                if v.pro > 0 then
                    table.insert(jackpotPoolPro, v.pro)
                    table.insert(jackpotPoolResult, {v.pro, v.betIndex})
                end
            end
            local randomBetIndex = math.random(jackpotPoolPro, jackpotPoolResult)[2]
            local lineNum = LineNum
            local betConfig = gamecommon.GetBetConfig(gameType,lineNum)
            local betgold = betConfig[randomBetIndex]                                                       -- 单注下注金额
            local payScore = betgold * lineNum                                                              -- 全部下注金额

            -- 获取奖池奖励
            local winScore = 0
            local mul
            if table.empty(jackpotTable.JackpotMul) == false then
                mul = jackpotTable.JackpotMul[gamecommon.CommRandInt(jackpotTable.JackpotMul,'pro')].mul
                winScore = payScore * mul
            else
                winScore = GetGamePoolChips2(gameId, randomJackpotId, betgold,gameType)
            end
            
            -- 发送跑马灯
            lampgame.AddTypeTwoRobot(gameId,winScore)
            if mul<=10 then
                print('mul='..mul)
            end
            -- 结构数据
            local params = {
                gameId = gameId,
                gameType = gameType,
                chips = winScore,
            }
            params.extData = {
                pool  = randomJackpotId,
                mul   = mul,
            }
            --请求一个机器人
            gamecommon.ReqRobotList(gameId, 1, params)
        end
    end
    -- TEST_FLAG = false
end
