-- 点球大战游戏模块
module('PenaltyKick', package.seeall)

-- 获取点球大战模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local penaltykickInfo = Get(gameType, uid)
    local res = GetResInfo(uid, penaltykickInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local res={}
    -- 获取数据库信息
    local penaltykickInfo = Get(msg.gameType, uid)
    if msg.save then
       -- 进入取钱逻辑
       res = GetMoney(penaltykickInfo,uid,msg.betIndexList,msg.peopleType,msg.gameType)
       WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true)
    else
        --进入普通游戏逻辑
        res = PlayGames(penaltykickInfo,uid,msg.betIndex,msg.betIndexList,msg.peopleType,msg.mul,msg.gameType)
    end
    -- 保存数据库信息
    SaveGameInfo(uid,msg.gameType,penaltykickInfo)
    gamecommon.SendNet(uid,'GameOprateGame_S',res)
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, PenaltyKick)
    StockInit()
    ChangeAttenuationType()
end
