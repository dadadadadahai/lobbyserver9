module('fruitparty2', package.seeall)
Table = 'game162fruitparty2'
LineNum = 1
GameId = 162

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
    local sTime = os.time()
    if datainfo.isInHight  == true then
        chip = math.floor(chip/table_162_buygailv[1].betChange)
    end
    -- 执行扣费
    local remainder, ok = chessuserinfodb.WChipsChange(datainfos._id, Const.PACK_OP_TYPE.SUB, chip,
        "水果派对2玩法投注")
    if ok == false then
        return {
            errno =ErrorDefine.CHIPS_NOT_ENOUGH,
        }
    end
    datainfo.betMoney = chip
    datainfo.betindex = betindex
    local userinfo = unilight.getdata('userinfo', datainfos._id)
    --启用图库模式
    local alldisInfo,realMul,imageType = gameImagePool.RealCommonRotate(uid,GameId,gameType,nil,fruitparty2,{betchip=betMoney,betIndex=betindex,gameId=GameId,gameType=gameType,betchips=chip})
    if imageType == 2 or imageType == 3 then
        local disInfo =  table.remove(alldisInfo,1)
        local betchip = chip
        local disInfos,realMul,ssums = parseData(betMoney,disInfo)
        local  Smul =  calcSMul(ssums)
        local winScore = (realMul+Smul)*betchip
        if winScore > 0 then 
            BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.FRUITPARTY2)
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
           -- disInfos[i].iconsAttachData = disInfos[i+1].iconsAttachData
        end
        table.remove(disInfos,#disInfos)

        local freetimes = CalcFreeNum(sNum)
        dump(freetimes,"freetimes",1)
        datainfo.free={
            totalTimes=freetimes,
            lackTimes=freetimes,
            tWinScore = 0,
            mulInfoList={},
            isBuy = 1,
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
    else 
        local disInfos ,realMul2,ssums= parseData(betMoney,alldisInfo)
        local  Smul =  calcSMul(ssums)
        print(string.format("realMul%d  realMul2%d",realMul,realMul2))
        local winScore = (realMul+Smul)*chip
        if winScore >0 then 
            BackpackMgr.GetRewardGood(datainfos._id, Const.GOODS_ID.GOLD,winScore, Const.GOODS_SOURCE_TYPE.FRUITPARTY2)
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