module('CandyTouch',package.seeall)
function NewOneceLogic(uid,gameId,gameType,isfree,chessdata,lastColRow,spin,datainfo)
    local res={
        chessdata  ={},
        winScore = 0,
        disInfo = {},
        lastInfo={},
    }
    local betMoney = datainfo.betMoney
    
    -- 标记翻倍缓存
    local doubleMaps = {}
    if isfree then
        doubleMaps = datainfo.doubleMaps or {}
        if table.empty(doubleMaps) then
            for col = 1,#DataFormat do
                doubleMaps[col] = {}
                for row = 1,DataFormat[col] do
                    doubleMaps[col][row] = 0
                end
            end
        end
    else
        for col = 1,#DataFormat do
            doubleMaps[col] = {}
            for row = 1,DataFormat[col] do
                doubleMaps[col][row] = 0
            end
        end
    end


    local disInfo,resultChessdata  = LogicProcess(chessdata,lastColRow,spin,doubleMaps)
    datainfo.doubleMaps = doubleMaps
    local winScore = 0
    for _,value in ipairs(disInfo) do
        local infos = value.infos
        for _,info in ipairs(infos) do
            winScore = winScore + math.floor(info.mul * betMoney / table_129_hanglie[1].linenum) * info.sumDoubleMul
        end
    end
    res.lastInfo={
        chessdata = table.clone(resultChessdata),
        lastColRow = lastColRow,
        winScore = winScore,
    }
    res.winScore = winScore
    res.chessdata = chessdata
    res.disInfo = disInfo
    return res
end