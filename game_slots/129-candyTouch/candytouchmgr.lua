-- 糖果连连碰游戏模块
module('CandyTouch', package.seeall)

-- 获取糖果连连碰模块信息
function CmdEnterGame(uid, msg)
    -- 获取玩家信息
    local userInfo = unilight.getdata("userinfo",uid)
    -- 获取游戏类型
    local gameType = msg.gameType
    -- 获取数据库信息
    local candytouchInfo = Get(gameType, uid)
    local res = GetResInfo(uid, candytouchInfo, gameType)
    -- 发送消息
    gamecommon.SendNet(uid,'EnterSceneGame_S',res)
end

--拉动游戏过程
function CmdGameOprate(uid, msg)
    msg.extraData = msg.extraData or {}
    msg.extraData.isBuyFree = msg.extraData.isBuyFree or false
    local res={}
    -- 获取数据库信息
    local candytouchInfo = Get(msg.gameType, uid)
    if not table.empty(candytouchInfo.free) then
        --进入免费游戏逻辑
        local res = PlayFreeGame(candytouchInfo,uid,msg.gameType)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,false,GameId)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    else
        --进入普通游戏逻辑
        local res = PlayNormalGame(candytouchInfo,uid,msg.betIndex,msg.gameType,msg.extraData.isBuyFree)
        WithdrawCash.GetBetInfo(uid,DB_Name,msg.gameType,res,true,GameId)
        gamecommon.SendNet(uid,'GameOprateGame_S',res)
    end
    
end


-- 糖果连连碰购买免费次数
-- function CmdBuyFree(uid,msg)
--     -- 获取数据库信息
--     local candytouchInfo = Get(msg.gameType, uid)
--     local buyRes = BuyFree(candytouchInfo,uid,msg.betIndex,msg.gameType)
--     gamecommon.SendNet(uid,'CandyTouchBuyFreeCmd_S',buyRes)
-- end

-- 注册消息解析
function RegisterProto()
    gamecommon.RegGame(GameId, CandyTouch)
    gamecommon.GetModuleCfg(GameId,CandyTouch)
end