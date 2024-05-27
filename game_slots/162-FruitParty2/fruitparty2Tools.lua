module('fruitparty2', package.seeall)


--[[
            table.insert(disInfo, {
            chessdata = table.clone(chessdata),
            info = info,
            iconsAttachData = iconsAttachData,

            table.insert(info, {
                iconid = J,
                mul = 0,
                winScore = 0,
                val = J,
            })
        })
]]
--解析数据
function parseData(betMoney,disInfo)

    local disInfos = disInfo
    local resDisInfos={}
    local tmul = 0
    local snum = 0 
    --u图标id记录  重复不添加
    for index, value in ipairs(disInfos) do
        local mchessdata = value.chessdata
        local  winfo = value.winfo 
        local mul = value.mul
        tmul = tmul + mul
        local dis = value.dis
        local resChessdata,ssnum = getIconAttachDataAndInfos(mchessdata)
        snum = ssnum
        local info = getInfos(betMoney,dis)
        table.insert(resDisInfos,{
            chessdata = resChessdata,
            info =  info,
            iconsAttachData=winfo,
        })
    end
    return resDisInfos,tmul,snum
end
--获取info
function getInfos(betMoney,dis)
    local info={}
    for _,d in ipairs(dis) do
        d.winScore = math.floor(betMoney*(d.mul or 0 ))
        table.insert(info,d)
    end
    return info
end
--整理棋牌数据,,添加附加数据
function getIconAttachDataAndInfos(chessdata)
    local resChessdata = {}
    local snums = 0 
    for col=1,#chessdata do
        resChessdata[col] = resChessdata[col] or {}
        for row=1,#chessdata[col] do
            local val = chessdata[col][row].val
            local Id = chessdata[col][row].Id
            resChessdata[col][row] = val
            if val ==S then
                snums = snums + 1
            end 
        end

    end
    return resChessdata ,snums
end


function packFree(datainfo)
    if table.empty(datainfo.free) then
        return {}
    end
    return{
        totalTimes=datainfo.free.totalTimes,
        lackTimes=datainfo.free.lackTimes,
        tWinScore = datainfo.free.tWinScore,
        mulInfoList=datainfo.free.mulInfoList,
        isBuy = 1,
        tMul = datainfo.free.tMul
    }
end