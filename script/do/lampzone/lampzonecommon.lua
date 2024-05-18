module('lampzone',package.seeall)
--[[
    timestamp
    uid
    gameId
    chip
    type
]]
ZoneLampData={}     --跑马灯数据池
ZoneLampLimit = 1000        --最大跑马灯数据池长度 1000
function GetLampCmd_C()
    local latestNum = 50        --回送50条
    local num = 0
    local res={}

    for i=#ZoneLampData,1,-1 do
        table.insert(res,ZoneLampData[i])
        num = num + 1
        if num>=latestNum then
            break
        end
    end
    return res
end
function ReportLampCmd_C(data)
    if data.gameId==109 then
        if math.random(100)<=90 then
            return
        end
    end
    -- print('recv ReportLampCmd_C',table2json(data))
    table.insert(ZoneLampData,data)
    if #ZoneLampData>ZoneLampLimit then
        table.remove(ZoneLampData,1)
    end
end