-- 渔夫游戏模块
module('Fisherman', package.seeall)

-- 获取渔夫模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local fishermanInfo = Get(gameType, uid)
    local res = GetResInfo(uid, fishermanInfo, gameType)
    print(table2json(res))
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    local res={}
    -- 获取数据库信息
    local fishermanInfo = Get(msg.gameType, uid)
    if not table.empty(fishermanInfo.free) then
        --进入免费游戏逻辑
        local res = PlayFreeGame(fishermanInfo,uid,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false,GameId)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    else
        --进入普通游戏逻辑
        local res = PlayNormalGame(fishermanInfo,uid,msg.betIndex,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    end

end

-- 渔夫购买免费次数
function CmdBuyFree(uid,msg)
    -- 获取数据库信息
    local fishermanInfo = Get(msg.gameType, uid)
    local buyRes = BuyFree(fishermanInfo,uid,msg.betIndex,msg.gameType)
    gamecommon.SendNet(uid,'FishermanBuyFreeCmd_S',buyRes)
end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, Fisherman)
    gamecommon.GetModuleCfg(GameId,Fisherman)
end