--游戏通用模块
module('gamecommon', package.seeall)
--异形棋盘数据生成,以列为主轴
--[[
    colrownum={1,2,3,4,5}       每一列的行数
]]
--列行
function CreateSpecialChessData(colrownum,spincfg)
    local chessdata={}
    local lastColRow = {}          --上次到的行记录
    for colindex, rownum  in ipairs(colrownum) do
        chessdata[colindex] = {}
        local n = #spincfg
        local randindex = math.random(n)
        lastColRow[colindex] = randindex
        for row = 1, rownum do
            local curRow = (randindex+(row-1))
            if curRow > n then
                curRow = curRow % n
            end
            chessdata[colindex][row] = spincfg[curRow]['c'..colindex]
        end
    end
    return chessdata, lastColRow
end
--[[
    最终定线计算
]]
function WiningLineFinalCalc(chessdata,linecfg,paytable,wild,nowild)
    local lines =WinningLineSpecial(chessdata,linecfg,wild,nowild)
    return CalcWinMulSpecial(lines,paytable,wild)
end
--[[
    最终定线计算 第一列可以非中奖
]]
function WiningLineFinalCalcNoOne(chessdata,linecfg,paytable,wild,nowild)
    local lines =WinningLineSpecialNoOne(chessdata,linecfg,wild,nowild)
    -- return CalcWinMulSpecial(lines,paytable,wild)
    local tmpres =  CalcWinMulSpecial(lines,paytable,wild)
    local sameLineMap={}
    for _,value in ipairs(tmpres) do
        sameLineMap[value.line] = sameLineMap[value.line] or {}
        table.insert(sameLineMap[value.line],value)
    end
    local resdata= {}
    for key, values in pairs(sameLineMap) do
        local maxmul = values[1].mul
        local maxobj = values[1]
        for _, value in ipairs(values) do
            if maxmul<value.mul then
                maxmul = value.mul
                maxobj = value
            end
        end
        table.insert(resdata,maxobj)
    end
    return resdata
end

--[[
    根据中奖线配置自动判断中奖的线
    线数上2个以上相同的会统计 参数 chessdata 当前数据棋盘,linecfg 线数配置表 wild[key]=1 配置表 nowild[key]=1 排除wild替用配置
    返回值 lines[{line,num,ele,winicon}]  中奖线 中奖元素 中奖图标(列行模式)
]]
function WinningLineSpecial(chessdata,linecfg,wild,nowild)
    local resdata={}
    --每条中奖线遍历
    for k, v in ipairs(linecfg) do
        local winlineIcon={}
        filllinewinicon(v,winlineIcon)
        local firsticon=0
        local samenum = 1
        local ele = 0
        local wNum = 0
        local winicon = {}
        local winpos={}
        local iconval={}
        local isContinuWild = false     --是否为连续wild
        for i = 1, #winlineIcon do
            local rowindex =math.floor(winlineIcon[i]/10)
            local colindex =winlineIcon[i]%10
            if firsticon==0 then
                firsticon = chessdata[colindex][rowindex]
                ele = firsticon
                if wild[firsticon]~=nil then
                    wNum = wNum + 1
                    isContinuWild=true
                end
                table.insert(winicon,{colindex,rowindex})
                table.insert(winpos,{colindex,rowindex})
                table.insert(iconval,chessdata[colindex][rowindex])
            else
                local same=false
                if isSame(ele,chessdata[colindex][rowindex],wild,nowild) or wild[ele]~=nil then
                    table.insert(winicon,{colindex,rowindex})
                    table.insert(winpos,{colindex,rowindex})
                    table.insert(iconval,chessdata[colindex][rowindex])
                    same=true
                    if wild[chessdata[colindex][rowindex]]==nil then
                        if wild[firsticon]~=nil and nowild[chessdata[colindex][rowindex]]~=nil then
                            same=false
                        else
                            ele = chessdata[colindex][rowindex]
                            isContinuWild = false
                            samenum = samenum+1
                        end
                    else
                        if isContinuWild then
                            wNum = wNum + 1
                        end
                        samenum = samenum+1
                    end
                end
                if same==false or samenum>=#winlineIcon then
                    --print('winiconcolnum='..#winicon)
                    local singleline={
                        line = k,
                        num = samenum,
                        ele = ele,
                        firsticon = firsticon,
                        winicon =winicon,
                        winpos=winpos,
                        wNum = wNum,
                        iconval=iconval,
                    }
                    table.insert(resdata,singleline)
                    break
                end
            end
        end
    end
    return resdata
end

function CalcWinMulSpecial(lines,paytable,wild)
    local resdata={}
    for index, value in ipairs(lines) do
        if paytable[value.ele]~=nil then
            if paytable[value.ele]['c'..value.num]~=nil and paytable[value.ele]['c'..value.num]>0 then
                local winicon ={}
                if value.winicon ~= nil then
                    table.sort(value.winicon,function (a, b)
                        return a[1]<b[1]
                    end)
                    for _, v in ipairs(value.winicon) do
                        table.insert(winicon,v[2])
                    end
                end
                local mul=paytable[value.ele]['c'..value.num]
                local ele = value.ele
                local wmul = 0
                local wIcon = 0
                if wild[value.firsticon]~=nil then
                    local iconwildmap = {}
                    for _, v in ipairs(value.iconval) do
                        if wild[v]~=nil then
                            iconwildmap[v] = 1
                        end
                    end
                    for key,_ in pairs(iconwildmap) do
                        local tmpMul = paytable[key]['c'..value.wNum]
                        if tmpMul~=nil and tmpMul>wmul then
                            wmul = tmpMul
                            wIcon = key
                        end
                    end
                end
                if wmul>mul then
                    mul = wmul
                    ele = wIcon
                    value.num = value.wNum
                end
                table.insert(resdata,{line=value.line,ele=ele,num=value.num,mul=mul, winicon=winicon, lineNum=value.lineNum or 1,iconval=value.iconval,firstindex = value.firstindex,winpos=value.winpos})
            end
        end
    end
    return resdata
end

function WinningLineSpecialNoOne(chessdata,linecfg,wild,nowild)
    local resdata={}
    --每条中奖线遍历
    for k, v in ipairs(linecfg) do
        local winlineIcon={}
        filllinewinicon(v,winlineIcon)
        local index = 1
        -- for index = 1, #winlineIcon - 1 do
        while index < #winlineIcon do
            local firsticon=0
            local samenum = 1
            local ele = 0
            local wNum = 0
            local winicon = {}
            local iconval={}
            local winpos={}
            local isContinuWild = false     --是否为连续wild
            local breakFlag = false
            for i = index, #winlineIcon do
                local rowindex =math.floor(winlineIcon[i]/10)
                local colindex =winlineIcon[i]%10
                if  firsticon==0 then
                    firsticon = chessdata[colindex][rowindex]
                    ele = firsticon
                    if wild[firsticon]~=nil then
                        wNum = wNum + 1
                        isContinuWild=true
                    end
                    table.insert(winicon,{colindex,rowindex})
                    table.insert(winpos,{colindex,rowindex})
                    table.insert(iconval,chessdata[colindex][rowindex])
                else
                    local same=false
                    if isSame(ele,chessdata[colindex][rowindex],wild,nowild) or wild[ele]~=nil then
                        table.insert(winicon,{colindex,rowindex})
                        table.insert(winpos,{colindex,rowindex})
                        table.insert(iconval,chessdata[colindex][rowindex])
                        same=true
                        if wild[chessdata[colindex][rowindex]]==nil then
                            if wild[firsticon]~=nil and nowild[chessdata[colindex][rowindex]]~=nil then
                                same=false
                            else
                                ele = chessdata[colindex][rowindex]
                                isContinuWild = false
                                samenum = samenum+1
                            end
                        else
                            if isContinuWild then
                                wNum = wNum + 1
                            end
                            samenum = samenum+1
                        end
                    end
                    if same==false or i == #winlineIcon then
                        local singleline={
                            line = k,
                            num = samenum,
                            ele = ele,
                            firsticon = firsticon,
                            winpos=winpos,
                            firstindex = index,
                            winicon =winicon,
                            wNum = wNum,
                            iconval=iconval,
                        }
                            -- index = i - 1
                            table.insert(resdata,singleline)
                        -- end
                        break
                    end
                end
            end
            -- if breakFlag then
            --     break
            -- end
            index = index + 1
        end
    end
    return resdata
end




--计算中奖线最终呈现
--[[
    winPoints 中奖图标  winMuls中奖线和中奖倍数
]]
function SpecialAllLineFinal(chessdata,wild,nowild,paytable)
    local rowInfoList = {}
    SpecialAllLineWinPos(chessdata,wild,nowild,1,rowInfoList)
    local winPoints,winMuls = SpecialAlllineWinIcon(chessdata,rowInfoList,wild,nowild,paytable)
    return winPoints,winMuls
end
--计算出中奖线
function SpecialAllLineWinPos(chessdata, wild, nowild, col, rowInfoList)
    if chessdata[col] == nil  then 
        return
    end
    for row = 1, #chessdata[col] do
        if not (nowild[chessdata[col][row]] ~= nil and col > 1) then
            local firstid = chessdata[col][row]
            local sameNum = col
            local lineNum = 1
            if wild[firstid] ~= nil then
                SpecialAllLineWinPos(chessdata, wild, nowild, col + 1, rowInfoList)
            else
                for c = col + 1, #chessdata do
                    local bFind = false
                    local sameColumnNum = 0
                    for r = 1, #chessdata[c] do
                        if bFind == false then
                            if isSame(firstid, chessdata[c][r], wild, nowild) then
                                sameNum = sameNum + 1
                                bFind = true
                            end
                        end
                        if isSame(firstid, chessdata[c][r], wild, nowild) then
                            sameColumnNum = sameColumnNum + 1
                        end
                    end
                    if bFind == false then
                        break
                    else
                        lineNum = lineNum * sameColumnNum
                    end
                end
                local rowInfo = {
                    num     = sameNum, --最大中数量
                    ele     = firstid, --中奖图标编号
                    lineNum = lineNum, --中线总数

                }
                table.insert(rowInfoList, rowInfo)
            end
        end
    end
end
--计算中奖图标，中奖倍数
function SpecialAlllineWinIcon(chessData, lineInfoList, wild, noWild, paytable)
    local winIconIndexList = {}
    local winLinesMul = {}
    for _, lineInfo in pairs(lineInfoList) do
        local mul = 0
        if paytable[lineInfo.ele] ~= nil and lineInfo.num>1 then
            mul = paytable[lineInfo.ele]['c' .. lineInfo.num]
        end
        if mul==nil then
            print('lineinfo.ele='..lineInfo.ele..',num='..lineInfo.num)
            mul = 0
        end
        if mul > 0 then
            local firstIcon = lineInfo.ele
            local muls = { mul = mul * lineInfo.lineNum, ele = lineInfo.ele, num = lineInfo.num,
                lineNum = lineInfo.lineNum, icons = {} }
            for colIndex = 1, lineInfo.num do
                for rowIndex = 1, #chessData[colIndex] do
                    if isSame(firstIcon, chessData[colIndex][rowIndex], wild, noWild) then
                        winIconIndexList[rowIndex .. "-" .. colIndex] = { colIndex, rowIndex }
                        table.insert(muls.icons, { colIndex, rowIndex })
                    end
                end
            end
            table.insert(winLinesMul, muls)
        end
    end
    --转换下格式
    local retList = {}
    for _, v in pairs(winIconIndexList) do
        table.insert(retList, v)
    end
    return retList, winLinesMul
end
--查找倍数
function calcMul(ele,num,paytable)
    if paytable[ele]~=nil then
        return paytable[ele]['c'..num]
    end
    return 0
end
--找到中奖图标中的ele
function findEle(icons,wild,chessdata)
    local ele = 0
    for col, value in ipairs(icons) do
        ele = chessdata[col][value]
        if wild[ele]==nil then
            return ele
        end
    end
    return ele
end
--构造全线中奖线
function buildAllWinLine(colsame,outLineInfo)
    local tmp = outLineInfo
    local linedata={}
    local colindex=2
    for i = colindex, #colsame do
        for _, v in ipairs(colsame[i]) do
            for index, value in ipairs(tmp) do
                local r= table.clone(value)
                table.insert(r,v)
                table.insert(linedata,r)
            end
        end
        tmp = table.clone(linedata)
        linedata={}
    end
    return tmp
end
--统计元素的个数
function StatEleNum(ele,chessdata)
    local num = 0
    for i=1,#chessdata do
        for j=1,#chessdata[i] do
            if chessdata[i][j]==ele then
                num = num+1
            end
        end
    end
    return num
end


--[[
@desc 棋盘掉落
@param chessData 棋盘数据
@param spinCfg   棋盘配表数据 
@param lastColRow 上次记录的位置{[colIndex] = row, [colIndex]=row}
@param removeList 要移除的数据{[2]=1,[3]=1}
--]]

function ChessDataDrop(chessData, spinCfg, lastColRow, removeList)

    local colNum = {}       --每列需要填充的个数
    local colEles = {}       --每列保留的元素
    local bFinish = true
    --获得保留的数据，并清空棋盘
    for colIndex=#chessData, 1, -1 do
        for rowIndex=#chessData[colIndex], 1, -1 do
            local eleId = chessData[colIndex][rowIndex]
            --统计每列个数
            if removeList[eleId] ~= nil then
                colNum[colIndex] = colNum[colIndex] or 0
                colNum[colIndex] = colNum[colIndex] + 1
            else
                colEle = colEles[colIndex]  or {} 
                table.insert(colEle, eleId)
                colEles[colIndex] = colEle
            end

            --棋盘全部清空一遍
            chessData[colIndex][rowIndex] = 0
        end
    end

    --下降棋盘
    for colIndex =1,  #chessData do
        for rowIndex =1,  #chessData[colIndex] do

            local colEle = colEles[colIndex]
            if chessData[colIndex][rowIndex] == 0 and colEle ~= nil and #colEle > 0 then
                chessData[colIndex][rowIndex] = colEle[#colEle]
                table.remove(colEle,#colEle)
            else
                --配表往上取
                local lastRow = lastColRow[colIndex] - 1
                --循环取
                if lastRow < 1 then
                    lastRow = #spinCfg
                end
                local newEleId = spinCfg[lastRow]["c"..colIndex]
                chessData[colIndex][rowIndex] = newEleId
                lastColRow[colIndex] = lastRow
            end
        end
    end

    --再检查一次是否有替换完
    for colIndex=#chessData, 1, -1 do
        for rowIndex=#chessData[colIndex], 1, -1 do
                local eleId = chessData[colIndex][rowIndex]
                --统计每列个数
                if removeList[eleId] ~= nil then
                    bFinish = false
                    return bFinish, chessData
                end
        end
    end

    return bFinish, chessData
end
--消除算法
function Eliminate(chessdata,iconmap)
    for col = 1,#chessdata do
        local row=1
        while true do
            local iconid = chessdata[col][row]
            if iconmap[iconid]~=nil then
                --要消除
                for r=row,#chessdata[col]-1 do
                    chessdata[col][r] = chessdata[col][r+1]
                end
                chessdata[col][#chessdata[col]] = 0
            else
                row = row + 1
            end
            if row>#chessdata[col] then
                break
            end
        end
    end
end
--填充算法 --填充0的位置
function FillZeroChess(chessdata,lastColRow,spin,eliminateInfo)
    local iconAttachData = {}
    for col=1,#chessdata do
        local lastRow = lastColRow[col]
        for row=1,#chessdata[col] do
            if chessdata[col][row]==0 then
                lastRow = lastRow - 1
                if lastRow<=0 then
                    lastRow = #spin+lastRow
                end
                local isFill = false
                if eliminateInfo.jackNum>0 and math.random(100)<=20 then
                    chessdata[col][row] = 100
                    eliminateInfo.jackNum =eliminateInfo.jackNum - 1
                    isFill=true
                end
                if isFill==false and table.empty(eliminateInfo.mulcfg)==false and #eliminateInfo.mulcfg>0 and math.random(100)<=50 then
                    chessdata[col][row] = eliminateInfo.mulcfg[1].iconid
                    table.insert(iconAttachData,{line = col,
                    row = row,
                    data = {
                        mul = eliminateInfo.mulcfg[1].mul,
                    }})
                    table.remove(eliminateInfo.mulcfg,1)
                    isFill=true
                end
                if isFill==false then
                    chessdata[col][row] = spin[lastRow]['c'..col]
                end
            end
        end
        lastColRow[col] = lastRow
    end
    return iconAttachData
end


--定线处理
-- doubleMap 加倍个数计算图标,payTable 倍数图标,payLines线配置,chessdata 棋盘 getIconIdFunc 自定义棋盘获取参数
function LinesHandle(wildMap,noWildMap,doubleMap,payTable,payLines,chessdata,getIconIdFunc)
    local getLineIconIdReal=function (LineIconId)
        local iconId = LineIconId[1]
        for _, value in ipairs(LineIconId) do
            if wildMap[value]==nil then
                iconId = value
                break
            end
        end
        return iconId
    end
    --获取倍数图标
    local getPayMul=function (lineIndex,LineIconId,num)
        local iconId=getLineIconIdReal(LineIconId)
        if payTable[iconId]~=nil and payTable[iconId]['c'..num]~=nil and payTable[iconId]['c'..num]>0 then
            return {lineIndex,iconId,payTable[iconId]['c'..num],num}
        end
        return {}
    end
    local dis={}
    for lineIndex,lineValue in ipairs(payLines) do
        local I=1
        local numLine = lineValue['I'..I]
        local LineIconId={}
        local num = 0
        while numLine~=nil do
            I = I+1
            local col = numLine%10
            local row = math.floor(numLine/10)
            local iconId = 0
            if getIconIdFunc==nil then
                iconId = chessdata[col][row]
            else
                iconId = getIconIdFunc(chessdata[col][row])
            end
            local isOk = false
            if #LineIconId<=0 then
                table.insert(LineIconId,iconId)
                isOk = true
            else
                local lastIconId = getLineIconIdReal(LineIconId)
                if (lastIconId==iconId) or (wildMap[lastIconId]~=nil and noWildMap[iconId]==nil) or (noWildMap[lastIconId]==nil and wildMap[iconId]~=nil) then
                    table.insert(LineIconId,iconId)
                    isOk = true
                end
            end
            if isOk then
                if doubleMap[iconId]~=nil then
                    num = num + doubleMap[iconId]
                else
                    num = num + 1
                end
            else
                break
            end
            numLine=lineValue['I'..I]
        end
        --进行中奖分析
        local linMul = getPayMul(lineIndex,LineIconId,num)
        if next(linMul)~=nil then
            table.insert(dis,linMul)
        end
    end
    return dis
end