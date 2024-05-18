module('rockgame',package.seeall)
function NewOneceLogic(uid,gameId,gameType,isfree,epos,chessdata,lastColRow,spin,datainfo)
    local res={
        chessdata  ={},
        winScore = 0,
        disInfo = {},
        rocks={},           --返回的宝石数量,当前收集到宝石数量
        lastInfo={},
    }
    local betMoney = datainfo.betMoney
    local disInfo,resultChessdata  = LogicProcess(chessdata,lastColRow,spin)
    local bepos = table.clone(epos)
    for _,value in ipairs(disInfo) do
        local clearPos = value.clearPos
        for _,pos in ipairs(clearPos) do
            local col,row = pos[1],pos[2]
            local keystr = col..'_'..row
            if epos[keystr]~=nil then
                table.insert(res.rocks,epos[keystr])
                epos[keystr]=nil
            end
        end
    end
    local winScore = 0
    for _,value in ipairs(disInfo) do
        local infos = value.infos
        for _,info in ipairs(infos) do
            winScore = winScore + math.floor(info.mul*betMoney)
        end
    end
    res.lastInfo={
        chessdata = table.clone(resultChessdata),
        lastColRow = lastColRow,
        winScore = winScore,
        epos = table.clone(epos),
        bepos=bepos,
    }
    res.winScore = winScore
    res.chessdata = chessdata
    res.disInfo = disInfo
    return res
end