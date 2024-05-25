module('sweetBonanza', package.seeall)
Table = 'game160sweetBonanza'
LineNum = 1
GameId = 160


J = 100
S = 70
-- 普通拉动
function Normal(gameId,gameType, betindex, datainfo, datainfos, uid)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betMoney = betconfig[betindex]
    --print('betconfig='..json.encode(betconfig))
    local chip = betMoney * LineNum
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = ErrorDefine.ERROR_PARAM,
        }
    end
    local userinfo = unilight.getdata('userinfo', datainfos._id)
    local sTime = os.time()
    if datainfo.isInHight  == true then
        chip = math.floor(chip/table_160_buygailv[1].betChange)
    end
    -- 执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB, chip,
        "波南扎玩法投注")
    if ok == false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = chip
    datainfo.betindex = betindex
    --启用图库模式
    local alldisInfo,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,sweetBonanza,{betchip=betMoney,betIndex=betindex,gameId=GameId,gameType=gameType,betchips=chip})
    if imageType == 2 or imageType == 3 then 
        local disInfo =  table.remove(alldisInfo,1)
        local betchip = chip 
        local disInfos,realMul,bombdataMap,ssum  = parseData(betMoney,disInfo)
        local  Smul =  calcSMul(ssum)
        local winScore = (realMul+Smul)*betchip
        if winScore > 0 then 
            BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.SWEETBONANZA)
        end 
        local boards= table.clone(disInfos[1].chessdata)
        local iconsAttachData = disInfos[1].iconsAttachData
        for i=1,#disInfos-1 do
            disInfos[i].chessdata = disInfos[i+1].chessdata
            disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
        end
        table.remove(disInfos,#disInfos)
       
        datainfo.free={
            totalTimes=10,
            lackTimes=10,
            tWinScore = 0,
            tMul = 0,
    
            mulInfoList={},
            isBuy = 0,
            resdata=alldisInfo
        }
        local res = {
            errno = 0,
            betIndex = datainfo.betindex,
            bAllLine = LineNum,
            payScore = datainfo.betMoney * LineNum,
            winScore = winScore,
            winLines = {},
            boards = boards,
       
            iconsAttachData = iconsAttachData,
            features={
                free = packFree(datainfo),
    
            },
            extraData = {
                disInfo = disInfos
            }
        }
        --记录系统级流水
        gameDetaillog.updateRoomFlow(GameId,gameType,0,1,chip,0,userinfo)
        -- WithdrawCash.ResetWithdawTypeState(datainfos._id,0)
        unilight.update(Table, datainfos._id, datainfos)
        return res
    else 
        local disInfos ,realMul2= parseData(betMoney,alldisInfo)
        dump(string.format("realMul%d  realMuls %d",realMul,realMul2))
        local winScore = realMul*chip
        if winScore >0 then 
            BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.SWEETBONANZA)
        end 
        local boards=table.clone(disInfos[1].chessdata)
        local iconsAttachData = disInfos[1].iconsAttachData
        for i=1,#disInfos-1 do
            disInfos[i].chessdata = disInfos[i+1].chessdata
            disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
        end
        table.remove(disInfos,#disInfos)
        -- 增加后台历史记录
        gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            datainfo.betMoney,
            remainder+chip,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {type='normal',chessdata = boards},
            {}
        )
        local res = {
            errno = 0,
            betIndex = datainfo.betindex,
            bAllLine = LineNum,
            payScore = datainfo.betMoney * LineNum,
            winScore = winScore,
            winLines = {},
            boards = boards,
        
            iconsAttachData = iconsAttachData,
            features={
                jackpot={},
                free = {},

            },
            extraData = {
                disInfo = disInfos
            }
        }
        return res
    end 
end
