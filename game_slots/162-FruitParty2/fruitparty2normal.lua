module('fruitparty2', package.seeall)
Table = 'game162fruitparty2'
LineNum = 1
GameId = 162

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
        chip = math.floor(chip/table_162_buygailv[1].betChange)
    end
    -- 执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(uid, Const.PACK_OP_TYPE.SUB, chip,
        "水果派对2玩法投注")
    if ok == false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = chip
    datainfo.betindex = betindex
    --启用图库模式
    local alldisInfo,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,fruitparty2,{betchip=betMoney,betIndex=betindex,gameId=GameId,gameType=gameType,betchips=chip})
    if  imageType == 3 then
        local disInfo =  table.remove(alldisInfo,1)
        local betchip = chip
        local disInfos,realMuls,ssums = parseData(betMoney,disInfo.b)
        local  Smul =  calcSMul(ssums)
        local winScore = (realMuls+Smul)*betchip
        if winScore > 0 then 
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.FRUITPARTY2)
        end 
        local lastDis = disInfos[#disInfos]
       
        local sNum = 0
        for col=1,#lastDis.chessdata do
            for row=1,#lastDis.chessdata[col] do
                if lastDis.chessdata[col][row]==70 then
                    sNum = sNum +1 
                end
            end
        end
        local boards= table.clone(disInfos[1].chessdata)
        local iconsAttachData = disInfos[1].iconsAttachData
        for i=1,#disInfos-1 do
            disInfos[i].chessdata = disInfos[i+1].chessdata
         
        end
        table.remove(disInfos,#disInfos)

        local freetimes = CalcFreeNum(sNum)
        dump(freetimes,"freetimes",1)
        datainfo.free={
            totalTimes=freetimes,
            lackTimes=freetimes,
            tWinScore = 0,
            mulInfoList={},
            isBuy = 0,
            resdata=alldisInfo
        }
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
                free = packFree(datainfo),
    
            },
            extraData = {
                disInfo = disInfos
            }
        }

        SaveGameInfo(uid,gameType,datainfo)
        return res
    else 
        local disInfos ,realMul2,ssums= parseData(betMoney,alldisInfo.b)  
        print(string.format("realMul%d  realMul2%d",realMul,realMul2))
        local winScore = realMul*chip
        if winScore >0 then 
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.FRUITPARTY2)
        end 
        local boards=table.clone(disInfos[1].chessdata)
        local iconsAttachData = disInfos[1].iconsAttachData
        for i=1,#disInfos-1 do
            disInfos[i].chessdata = disInfos[i+1].chessdata
            --disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
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


-- 普通拉动
function NormalDemo(gameType, betindex, datainfo, uid)
    local betconfig = gamecommon.GetBetConfig(gameType, LineNum)
    local betMoney = betconfig[betindex]
    local chip = betMoney * LineNum
    if betMoney == nil or betMoney <= 0 then
        return {
            errno = ErrorDefine.ERROR_PARAM,
        }
    end
    if datainfo.isInHight  == true then
        chip = math.floor(chip/table_162_buygailv[1].betChange)
    end
    -- 执行扣费
    local remainder, ok = chessuserinfodb.WGoldChange(uid, Const.PACK_OP_TYPE.SUB, chip,
        "水果派对2玩法投注")
    if ok == false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = chip
    datainfo.betindex = betindex
    --启用图库模式
    local alldisInfo,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,fruitparty2,{betchip=betMoney,demo = IsDemo(uid),betIndex=betindex,gameId=GameId,gameType=gameType,betchips=chip})
    if  imageType == 3 then
        local disInfo =  table.remove(alldisInfo,1)
        local betchip = chip
        local disInfos,realMuls,ssums = parseData(betMoney,disInfo.b)
        local  Smul =  calcSMul(ssums)
        local winScore = (realMuls+Smul)*betchip
        if winScore > 0 then 
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT,winScore, Const.GOODS_SOURCE_TYPE.FRUITPARTY2)
        end 
        local lastDis = disInfos[#disInfos]
       
        local sNum = 0
        for col=1,#lastDis.chessdata do
            for row=1,#lastDis.chessdata[col] do
                if lastDis.chessdata[col][row]==70 then
                    sNum = sNum +1 
                end
            end
        end
        local boards= table.clone(disInfos[1].chessdata)
        local iconsAttachData = disInfos[1].iconsAttachData
        for i=1,#disInfos-1 do
            disInfos[i].chessdata = disInfos[i+1].chessdata
         
        end
        table.remove(disInfos,#disInfos)

        local freetimes = CalcFreeNum(sNum)
        dump(freetimes,"freetimes",1)
        datainfo.free={
            totalTimes=freetimes,
            lackTimes=freetimes,
            tWinScore = 0,
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

        SaveGameInfo(uid,gameType,datainfo)
        return res
    else 
        local disInfos ,realMul2,ssums= parseData(betMoney,alldisInfo.b)
        print(string.format("realMul%d  realMul2%d",realMul,realMul2))
        local winScore = realMul*chip
        if winScore >0 then 
            BackpackMgr.GetRewardGood(uid, Const.GOODS_ID.POINT,winScore, Const.GOODS_SOURCE_TYPE.FRUITPARTY2)
        end 
        local boards=table.clone(disInfos[1].chessdata)
        local iconsAttachData = disInfos[1].iconsAttachData
        for i=1,#disInfos-1 do
            disInfos[i].chessdata = disInfos[i+1].chessdata
            --disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
        end
        table.remove(disInfos,#disInfos)

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