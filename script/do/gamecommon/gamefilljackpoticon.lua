module('gamecommon',package.seeall)
local table_jackpot100 = import 'table/gamecommon/table_jackpot100'
local table_110_jackpot = import 'table/gamecommon/table_110_jackpot'
--通用填充棋牌jackpot图标类
FillJackPotIcon={}

function GetCfg(GameId)
    local cfg = table_jackpot100
    if GameId==110 then
        cfg = table_110_jackpot
    end
    return cfg
end


--[[
    总列 总行 是否已经出奖池  配置
]]
function FillJackPotIcon:New(tcol,trow,success,GameId)
    local o={}
    setmetatable(o,self)
    self.__index  = self
    o.num = 0
    if success==false then
        local jackpotcfg = GetCfg(GameId)
        o.tcol=tcol
        o.trow = trow
        o.jackpotcfg = jackpotcfg
        --计入当次需要填充的图标数量
        local num = jackpotcfg[CommRandInt(jackpotcfg,'gailv')].num
        o.num = num
        o.noWinPositionMap = {}     --填充未中奖位置  col-row key
        if num>0 then
            for col=1,tcol do
                for row=1,trow do
                    local keystr = col..'-'..row
                    o.noWinPositionMap[keystr] = {col,row}
                end
            end
        end
    end
    return o
end
--填充中奖数据
function FillJackPotIcon:PreWinData(winicon)
    if self.num<=0 then
        return
    end
    for col, row in ipairs(winicon) do
        local keystr = col..'-'..row
        self.noWinPositionMap[keystr] = nil
    end
end
--填充额外排除配置
function FillJackPotIcon:FillExtraIcon(col,row)
    if self.num<=0 then
        return
    end
    local keystr = col..'-'..row
    self.noWinPositionMap[keystr] = nil
end
--生成最终发回棋盘
function FillJackPotIcon:CreateFinalChessData(chessdata,jackPotIcon)
    if self.num<=0 then
        return {}
    end
    local randPos = {}          --构建二维数组 列行
    local realnum = 0
    local colnum = 0
    local coltype={}
    for _, value in pairs(self.noWinPositionMap) do
        --col value[1] row value[2]
        -- randPos[value[1]] = randPos[value[1]] or {}
        -- table.insert(randPos[value[1]],value[2])
        table.insert(randPos,{value[1],value[2]})
        realnum = realnum + 1
        if coltype[value[1]]==nil then
            colnum = colnum +1
            coltype[value[1]] = 1
        end
        --table.insert(randPos,{value[1],value[2]})
    end
    if realnum<=0 or realnum<self.num then
        return {}
    end
    local singcol = false
    if colnum>=self.num then
        singcol =true
    end
    local existCol={}       --已填充的列
    local returnFillPos={}
    --进入随机填充
    for i=1,self.num do
        while true do
            local randindex = math.random(#randPos)
            local posIndex = randPos[randindex]
            table.remove(randPos,randindex)
            if not(singcol and existCol[posIndex[1]]~=nil) then
                existCol[posIndex[1]] = 1
                chessdata[posIndex[1]][posIndex[2]]=jackPotIcon
                table.insert(returnFillPos,{posIndex[1],posIndex[2]})
                break
            end
        end
    end
    return returnFillPos
end