module('cleopatraNew', package.seeall)


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
    local ssum = 0
    --u图标id记录  重复不添加
    local uIconIdMap={}
    local bombdataMap = {}
    for index, value in ipairs(disInfos) do
        local mchessdata = value.chessdata
        local mul = value.mul
        tmul = tmul + mul
        local dis = value.dis
        local resChessdata,iconsAttachData ,tssum= getIconAttachDataAndInfos(mchessdata,uIconIdMap,bombdataMap)
        ssum = tssum
        local info = getInfos(betMoney,dis)
        table.insert(resDisInfos,{
            chessdata = resChessdata,
            info = info,
            iconsAttachData=iconsAttachData,
        })
    end
    local bombdata = {}
    for key, value in pairs(bombdataMap) do
        table.insert(bombdata,{val=key,mul = value})
    end
    return resDisInfos,tmul,bombdata,ssum
end
--获取info
function getInfos(betMoney,dis)
    local info={}
    for _,d in ipairs(dis) do
        table.insert(info,{
            iconid=d.ele,
            mul = d.mul,
            winScore = tonumber(string.format("%.2f",betMoney*(d.mul or 0 ))),
            val = d.num,
        })
    end
    return info
end
--整理棋牌数据,,添加附加数据
function getIconAttachDataAndInfos(chessdata,uIconIdMap,bombdataMap)
    local resChessdata = {}
    local iconsAttachData={}
    local snums = 0 
    for col=1,#chessdata do
        resChessdata[col] = resChessdata[col] or {}
        for row=1,#chessdata[col] do
            local val = chessdata[col][row].val
            local Id = chessdata[col][row].Id
            resChessdata[col][row] = val
            if val>100 then
                if uIconIdMap[Id]==nil then
                    table.insert(iconsAttachData,{
                        line = col,
                        row = row,
                        data={
                            mul = chessdata[col][row].mul
                        }
                    })
                    uIconIdMap[Id]=1
                end
                bombdataMap[val] = chessdata[col][row].mul
            end
            if val ==S then
                snums = snums + 1
            end 
        end
    end
    return resChessdata,iconsAttachData , snums
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