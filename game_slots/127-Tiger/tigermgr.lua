-- 老虎游戏模块
module('Tiger', package.seeall)

-- 获取老虎模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local tigerInfo = Get(gameType, uid)
    local res = GetResInfo(uid, tigerInfo, gameType)
    print(table2json(res))


    ------------------------------------- 特殊游戏特殊处理 -------------------------------------
    res.features = nil
    -------------------------------------------------------------------------------------------


    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local res={}
    -- 获取数据库信息
    local tigerInfo = Get(msg.gameType, uid)

        --进入普通游戏逻辑
      for i = 1, 50000 do
         msg.betIndex = math.random(12)
         local res = PlayNormalGame(tigerInfo,uid,msg.betIndex,msg.gameType)
         WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
        ------------------------------------- 特殊游戏特殊处理 -------------------------------------
         res.features = nil
      end 
        -------------------------------------------------------------------------------------------
      --  gamecommon.SendNet(uid,'GameOprateGame_S',res)
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, Tiger)
    gamecommon.GetModuleCfg(GameId,Tiger)
    gameImagePool.loadPool(GameId)
end