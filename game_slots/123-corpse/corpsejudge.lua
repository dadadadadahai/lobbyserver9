module('corpse',package.seeall)
--取游戏中奖线
function GetGameRewardLine(chessdata)
   local linesIconIds = {}
   for lineNo, rows in ipairs(table_123_payline) do        
        local tmplines = {}
        local I = 1
        while rows['I'..I]~=nil do
            local rs=rows['I'..I]
            I = I + 1
            if rs~=0 then
                local col,row = GetLineColAndRow(rs)
                table.insert(tmplines,chessdata[col][row])
            end
        end
        table.insert(linesIconIds,tmplines)
   end
   return linesIconIds
end
--[[
    进行中奖判断和预处理

]]
function WinningLineInfo(betchip,chessdata)
    local winLinesInfo={}       --{line=,winId=,num=,isContinuous=,isVertical=}
    local linesIconIds = GetGameRewardLine(chessdata)
    for lineNo,valLineIconInfo in ipairs(linesIconIds) do
        local tmpSingle =  SigleLineDetailInfo(lineNo,valLineIconInfo)
        if table.empty(tmpSingle)==false then
            table.insert(winLinesInfo,tmpSingle)
        end
    end
    --计算中奖线
    local winLines = {}
    local winScore = 0
    for _, value in ipairs(winLinesInfo) do
        local FinMul = 0
        local num = 0
        local type = 0
        if value.isContinuous~=value.num and table_123_paytableNo[value.winId]~=nil and table_123_paytableNo[value.winId]['c'..value.num]~=nil and table_123_paytableNo[value.winId]['c'..value.num]>0 then
            local mul = table_123_paytableNo[value.winId]['c'..value.num]
            -- winScore = winScore + betchip * mul
            FinMul = mul
            num = value.num
            type = 1
        end
        local continPayTable={}
        if value.isContinuous>0 and value.isVertical==0 then
            if value.isMiddle then
                continPayTable = table_123_middlepaytable
            else
                continPayTable = table_123_paytableContin
            end
        end
        if value.isContinuous>0 and value.isVertical==0 and continPayTable[value.winId]~=nil and continPayTable[value.winId]['c'..value.isContinuous]~=nil and continPayTable[value.winId]['c'..value.isContinuous]>0 then
            local mul = continPayTable[value.winId]['c'..value.isContinuous]
            -- winScore = winScore + betchip * mul
            if mul>FinMul then
                FinMul = mul
                num = value.isContinuous
                type = 2
                -- print('num2',num)
            end
            -- print(mul,value.winId)
            -- table.insert(winLines,{value.line,value.num,betchip * mul,value.winId})
        end
        if value.isVertical==1 and table_123_paytableVir[value.winId]~=nil and table_123_paytableVir[value.winId]['c'..value.num]~=nil and table_123_paytableVir[value.winId]['c'..value.num]>0 then
            local mul = table_123_paytableVir[value.winId]['c'..value.num]
            -- winScore = winScore + betchip * mul
            if mul>FinMul then
                FinMul = mul
                num = value.num
                type=3
                -- print('num3',num)
            end
            -- table.insert(winLines,{value.line,value.num,betchip * mul,value.winId})
        end
        if FinMul>0 then
            -- print(value.line,num,FinMul,value.winId)
            winScore = winScore + betchip * FinMul
            table.insert(winLines,{value.line,num,betchip * FinMul,value.winId,type})
        end
    end
    return winLines,winScore,winLinesInfo
end
function SigleLineDetailInfo(lineNo,valLineIconInfo)
    local sameMap = {}      --[[iconid = num]]
    for _, value in ipairs(valLineIconInfo) do
        sameMap[value] = (sameMap[value] or 0) + 1
    end
    local winId = 0
    for key, value in pairs(sameMap) do
        if value >= 3 then
            winId = key
            break
        end
    end
    if winId == 0 then
        return {}
    else
        local res={
            line = lineNo,
            winId = winId,
            num = sameMap[winId],
            isContinuous = 1,
            isVertical = 1,
            winPoints={},
            isMiddle =false,
        }
        local posInfos = {}
        local lastIndex = 0
        local maxContinuous = 0
        for index ,value in ipairs(valLineIconInfo) do
            if value==winId then
                local c,r  = GetLineColAndRow(table_123_payline[lineNo]['I'..index])
                table.insert(posInfos,{c,r})
                if lastIndex==0 then
                    lastIndex = index
                else
                    if lastIndex+1~=index then
                        -- res.isContinuous = 0
                        -- print('lineNo',lineNo,value,lastIndex,index)
                        if res.isContinuous>maxContinuous then
                            maxContinuous = res.isContinuous
                            if res.isContinuous<3 then
                                posInfos={}
                            end
                        end
                        res.isContinuous = 1
                        lastIndex = index
                    else
                        res.isContinuous = res.isContinuous + 1
                        lastIndex = index
                    end
                end
            end
        end
        if maxContinuous>res.isContinuous then
            res.isContinuous = maxContinuous
        end
        --判断是否为纵向连续
        if res.isContinuous~=3 then
            res.isVertical = 0
        else
            print('winId',res.winId)
            for i=1,#posInfos-1 do
                if posInfos[i][1]~=posInfos[i+1][1] then
                    res.isVertical = 0
                    break
                end
            end
        end
        if res.isContinuous==3 and res.isVertical==0 then
            if posInfos[1][1]~=1 and posInfos[#posInfos][1]~=5 then
                res.isMiddle = true
            end
            -- local str=''
            -- for index, value in ipairs(posInfos) do
            --     str =str..value[1]..','..value[2]..';'
            -- end
            -- print(str,res.isMiddle)
        end
        res.winPoints = posInfos
        return res
    end
end
function GetLineColAndRow(value)
    local row = math.floor(value/10)
    local col = math.floor(value%10)
    return col,row
end