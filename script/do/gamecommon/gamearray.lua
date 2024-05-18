--一维数组棋盘
module('gamecommon', package.seeall)

--[[
@desc 创建一维数组棋盘
@param spincfg  棋盘数据
@param num   棋盘大小
--]]
function CreateArrayChess(spincfg, num)
    local chessData = {}
    local maxRow = #spincfg
    for colIndex = 1, num do
       local randomRow = math.random(maxRow) 
       table.insert(chessData,spincfg[randomRow]["c"..colIndex])
    end
    return chessData
end

--[[
@desc 计算中奖线(没有wild替代)
@param chessData 棋盘数据
@param table_paylines 中奖线配置
@param table_paytables 中奖倍数配置
--]]
function ArrayWiningLine(chessData, table_paylines, table_paytables)
    --中奖结果数据
    local resData = {}
    --线数据
    local lineData = {}
    --已经判断过的元素
    local hasUseEle = {}
    for _, payline in ipairs(table_paylines) do
        for _, eleId in ipairs(chessData) do
            --指定元素如果在中奖线为1的标识里都有，说明中奖了 
            if hasUseEle[payline.ID.."_"..eleId] == nil then
                hasUseEle[payline.ID.."_"..eleId]  = 1
                local index = 1
                local sameNum = 0
                while true do
                    if payline['I'..index] ~= nil then
                        if payline['I'..index] == 1 then
                            if chessData[index] == eleId then
                                sameNum = sameNum + 1
                            end
                        end
                    else
                        break
                    end
                    index = index + 1
                end
                --相同大于1的才记录
                if sameNum > 1 then
                    local singleLine = {
                        line = payline.ID,
                        num = sameNum,
                        ele = eleId,
                    }
                    table.insert(lineData,singleLine)
                end
            end
        end

    end
    for index, value in ipairs(lineData) do
        if table_paytables[value.ele]~=nil then
            if table_paytables[value.ele]['c'..value.num]~=nil and table_paytables[value.ele]['c'..value.num]>0 then
                table.insert(resData,{
                    line = value.line,
                    ele  = value.ele,
                    num  = value.num,
                    mul  = table_paytables[value.ele]['c'..value.num],
                    }
                )
            end
        end
    end
    return resData
end
