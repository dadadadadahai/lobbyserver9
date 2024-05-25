module('cleopatraNew', package.seeall)
Table = 'game121cleopatra'
LineNum = 1
GameId = 121


J = 100
S = 70

-- 普通拉动
function Normal(gameType, betindex, datainfo, uid)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betMoney = betconfig[betindex]
    local reschip = chessuserinfodb.RUserChipsGet(uid)
    local chip = betMoney * LineNum
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = ErrorDefine.ERROR_PARAM,
        }
    end
    local sTime = os.time()
    if datainfo.isInHight  == true then
        chip = math.floor(chip/table_121_buygailv[1].betChange)
    end
    -- 执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, chip,
        "宙斯玩法投注")
    if ok == false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = chip
    datainfo.betindex = betindex
    --启用图库模式
    local alldisInfo,realMul ,imageType= gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,cleopatraNew,{betchip=betMoney/LineNum,betIndex=betindex,gameId=GameId,gameType=gameType,betchips=chip})
    if imageType == 2 or imageType == 3 then 

        local disInfo =  table.remove(alldisInfo,1)
        local betchip = chip 
        local disInfos,realMul2,bombdataMap,ssum = parseData(betMoney,disInfo)
        dump(string.format("realMul%d  realMul2%d ssum%d",realMul,realMul2,ssum))
        local  Smul =  calcSMul(ssum)
        local winScore = (realMul2+Smul)*betchip
        if winScore > 0 then 
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.CLEOPATRANEW)
        end 
        local boards= table.clone(disInfos[1].chessdata)
        local iconsAttachData = disInfos[1].iconsAttachData
        for i=1,#disInfos-1 do
            disInfos[i].chessdata = disInfos[i+1].chessdata
            disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
        end
        table.remove(disInfos,#disInfos)
    
        datainfo.free={
            totalTimes=15,
            lackTimes=15,
            tWinScore = 0,
            tMul = 0,
            sMul = 0 ,
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
          -- 增加后台历史记录
          gameDetaillog.SaveDetailGameLog(
            uid,
            sTime,
            GameId,
            gameType,
            datainfo.betMoney,
            reschip,
            chessuserinfodb.RUserChipsGet(uid),
            0,
            {type='normal',chessdata = boards},
            {}
        )
        SaveGameInfo(uid,gameType,datainfos)
        return res
    else
        local disInfos ,realMul2= parseData(betMoney,alldisInfo)
        print(string.format("realMul%d  realMul2%d",realMul,realMul2))
        local winScore = realMul*chip
        if winScore >0 then 
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.SWEETBONANZA)
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
            reschip,
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