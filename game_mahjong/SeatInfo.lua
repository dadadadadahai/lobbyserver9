module('SeatInfo', package.seeall) -- 

if SeatClass == nil then
	CreateClass("SeatClass")
end
SeatClass:SetClassName("Seat")

function SeatClass:GetId()
	return self.owner.id .. ":" .. self.id
end
function SeatClass:GetName()
    local name = self.name
    if self.owner ~= nil then
        name = name ..","..self.owner.id .. ",".. self.owner:GetCurRoundNum()
    end
	return name
end
function CreateSeat(owner,seatid)
	local seat = SeatClass:New() 
	seat.id = seatid
	seat.name = GetSeatNameBySeatId(seatid)
	seat.point = 0 
	seat.owner = owner
	seat.playerInfo = nil
	seat.base = nil
	seat.bReady = false
	seat.showCardNum = {} --所有已知明牌,baseid索引
	seat.showCardTypeNum = {} --所有已知明牌,type索引,用来判断是否打清一色
	seat.handCardTypeNum = {} --所有已知明牌,type索引,用来判断是否打清一色
	seat.myCardTypeNum = {} --自己的所有牌,判断的清一色等
	seat.handCardBaseidNum = {}
	seat.pairNum = 0 --对子
	seat.TripletNum = 0 --刻子
	seat.listen = nil --是否已听牌
	seat:InitSeat()
	seat:ResetData()
	return seat
end
function GetSeatNameBySeatId(seatid)
	if seatid == 1 then
		return "东"
	elseif seatid == 2 then
		return "南"
	elseif seatid == 3 then
		return "西"
	elseif seatid == 4 then
		return "北"
	end
end

function SeatClass:InitSeat()
	self.mypoint = 0 
	self:InitMySeat()
	--self:Debug("等待重构InitMySeat")
end
function SeatClass:InitMySeat()
	local a,b = math.modf(self.owner.data.gamenbr)
	if b > 0 then
		self.point = a
	end
	if self.owner.state.bundle then
		self.point = self.owner.state.bundle
	end
end
function SeatClass:ResetMyData()
end
function SeatClass:ResetData()
	self.outCard = {}
	self.handCard = {}
	self.touchCard = {}
	self.barCard = {}
	self.eatCard = {}
	self.flowerCard = {}
	self.checkCard = {} --临时计算用
	self.groupCard = {} --临时计算用
	self.listen = nil
	self:ResetMyData()
	self.last_OutCardMahjongCmd_Brd = nil -- 最后一张出牌,托管时用
	self.pairNum = 0 --对子
	self.TripletNum = 0 --刻子
	self.multiType = nil --翻型
	self.multiTypeCardType = nil --翻型牌型
end
function SeatClass:AddOneCard(card)
	self.handCard[card.base.thisid] = card
	return true
end

function SeatClass:GetOneWaitCardBaseId()
	local ret =  self:GetOneWaitCardBaseIdByType() 
	if ret then
		return ret
	end
	for k,v in pairs(self.handCard) do --本次循环只找一个杠
		local basenum = self:GetHandCardNumByBaseId(v.base.baseid)
		if v.id < 400 and v.base.baseid - 2 >= 1 and self:GetHandCardByBaseId(v.base.baseid - 1) then
			return v.base.baseid
		elseif basenum == 2 then --凑牌,只凑碰
			return v.base.baseid
		end
	end
	return nil
end
function SeatClass:GetOneWaitCardBaseIdByType()
	local wan = self:GetCardNumByCardType(1)
	local suo = self:GetCardNumByCardType(2)
	local bin = self:GetCardNumByCardType(3)

	local tab = {}
	table.insert(tab, wan)
	table.insert(tab, suo)
	table.insert(tab, bin)
	table.sort(tab)
	local typ = nil
	if wan == tab[2] then
		typ = 1
	elseif suo == tab[2] then
		typ = 2
	elseif bin == tab[2] then
		typ = 3
	end

	local temp = 0
	for k,v in pairs(self.handCard) do
		if math.floor(k/100) == typ then
			if temp >= tab[2]/3*2 then -- 暂时检测三分之二
				break
			end
			if v.base.baseid%10 - 2 >= 1 and v.base.baseid%10 + 2 <= 9 and self:GetHandCardByBaseId(v.base.baseid + 1) and not self:GetHandCardByBaseId(v.base.baseid + 2) then
				self:Debug("换好牌,凑顺 baseid:"..(v.base.baseid+2))
				return v.base.baseid + 2
			end
			temp = temp +1
		end
	end
	
	for k,v in pairs(self.handCard) do
		if math.floor(k/100) == typ then
			local basenum = self:GetHandCardNumByBaseId(v.base.baseid)
			if basenum == 2 then
				self:Debug("换好牌,凑刻 baseid:"..v.base.baseid)
				return v.base.baseid
			end
		end
	end
	return nil
end
function SeatClass:GetCardNumByCardType(typ)
	local num = 0
	for k,v in pairs(self.handCard) do
		if math.floor(k/100) == typ then
			num = num + 1
		end
	end
	return num
end

function SeatClass:CheckCanMeld(card)
	--如果是金牌,世界返回true
	if self.owner.state.round:IsGoldCard(card) then
		return true
	end
	if self:GetHandCardByBaseId(card.base.baseid) then --可碰 --可碰 --可碰 --可碰
		return true
	elseif card.id >= 400 then --字牌和花不检查顺子
		return false
	elseif self:GetHandCardByBaseId(card.base.baseid - 1) then
		return true
	elseif self:GetHandCardByBaseId(card.base.baseid - 2) then
		return true
	elseif self:GetHandCardByBaseId(card.base.baseid + 1) then
		return true
	elseif self:GetHandCardByBaseId(card.base.baseid + 2) then
		return true
	end
	for k,v1 in pairs(self.touchCard) do
		if math.floor(v1.thisId/10) == card.base.baseid then --碰杠
			return true
		end
	end
	return false
end
function SeatClass:GetCanBarId()
	local barSet = {}
	local temp = {}
	for k,v in pairs(self.handCard) do --本次循环只找一个杠
		local basenum = self:GetHandCardNumByBaseId(v.base.baseid)
		if basenum == 4 then --杠
			if table.find(temp, v.base.baseid) == nil then
				table.insert(temp, v.base.baseid)
				table.insert(barSet, v.id)
			end
		end
		for i,j in pairs(self.touchCard) do
			if math.floor(j.thisId/10) == math.floor(v.id/10) then
				table.insert(barSet, v.id)
			end
		end
	end
	if next(barSet) == nil then
		barSet = nil
	end
	return barSet
end

function SeatClass:IsBarGet()
	return false
end

function SeatClass:AddOneFlowerCard(thisid)
	table.insert(self.flowerCard,thisid)
end

function SeatClass:RemoveOneCard(card)
	self.handCard[card.base.thisid] = nil
end

function SeatClass:IncHandCardScore(id,score,max,meld,desc)
	desc = desc or ""
	local cur = 0
	for k,v in pairs(self.handCard) do
		if v.id == id or v.base.baseid == id or v.base.type == id then
			v.score = v.score + score
			if not self.playerInfo:IsRobot() then
				if meld then
					if v.meld then
						--v:Error("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:true:true:"..v.score..":" ..cur .. ":" .. max .. ":" .. desc)
					else
						--v:Error("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:true:false:"..v.score..":" ..cur .. ":" .. max .. ":" .. desc)
					end
				else
					if v.meld then
						--v:Error("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:false:true:"..v.score..":" ..cur .. ":" .. max .. ":" .. desc)
					else
						--v:Error("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:false:false:"..v.score..":" ..cur .. ":" .. max .. ":" .. desc)
					end
				end
			end
			cur = cur + 1
			if cur >= max and not v.meld then
				v.meld = meld --是否已成型的牌
				break
			end
			if meld then
				v.meld = meld --是否已成型的牌
			end
		end
	end
end
function SeatClass:ReGroup()
    local group = {}
    for i, v in pairs(self.handCard) do
	    if group[v.base.type] == nil then
		    group[v.base.type] = {0,0,0,0,0,0,0,0,0,}
	    end
	    group[v.base.type][v.base.point] = (group[v.base.type][v.base.point] or 0) + 1
    end
    return group
end

function SeatClass:ResetShowCardNum()
	self.showCardNum = {}
	self.showCardTypeNum = {}
	self.handCardTypeNum = {}
	self.myCardTypeNum = {}
	self.handCardBaseidNum = {}
	self.pairNum = 0 --对子
	self.TripletNum = 0 --刻子
	for k,seat in pairs(self.owner.state.seats) do --所有座位的明牌
		for k,v in pairs(seat.outCard) do
			local baseid = math.floor(v/10)
			self.showCardNum[baseid] = (self.showCardNum[baseid] or 0) + 1
			local typ = math.floor(v/100)
			self.showCardTypeNum[typ] = (self.showCardTypeNum[typ] or 0) + 1
		end
		for i,j in pairs(seat.touchCard) do
			local baseid = math.floor(j.thisId/10)
			self.showCardNum[baseid] = (self.showCardNum[baseid] or 0) + 3
			local typ = math.floor(j.thisId/100)
			self.showCardTypeNum[typ] = (self.showCardTypeNum[typ] or 0) + 3
			if seat == self then
				self.myCardTypeNum[typ] = (self.myCardTypeNum[typ] or 0) + 3
			end
			self.TripletNum = self.TripletNum + 1
		end
		for i,j in pairs(seat.barCard) do
			local baseid = math.floor(j.thisId/10)
			self.showCardNum[baseid] = (self.showCardNum[baseid] or 0) + 4
			local typ = math.floor(j.thisId/100)
			self.showCardTypeNum[typ] = (self.showCardTypeNum[typ] or 0) + 4
			if seat == self then
				self.myCardTypeNum[typ] = (self.myCardTypeNum[typ] or 0) + 4
			end
			self.TripletNum = self.TripletNum + 1
		end
		for k,v in pairs(seat.eatCard) do
			local baseid = math.floor(v.one/10)
			self.showCardNum[baseid] = (self.showCardNum[baseid] or 0) + 1
			local baseid = math.floor(v.two/10)
			self.showCardNum[baseid] = (self.showCardNum[baseid] or 0) + 1
			local baseid = math.floor(v.thisId/10)
			self.showCardNum[baseid] = (self.showCardNum[baseid] or 0) + 1
			local typ = math.floor(v.one/100)
			self.showCardTypeNum[typ] = (self.showCardTypeNum[typ] or 0) + 3
			if seat == self then
				self.myCardTypeNum[typ] = (self.myCardTypeNum[typ] or 0) + 3
			end
		end
	end
    for i, v in pairs(self.handCard) do -- 自己的手牌
	    self.showCardNum[v.base.baseid] = (self.showCardNum[v.base.baseid] or 0) + 1
	    self.showCardTypeNum[v.base.type] = (self.showCardTypeNum[v.base.type] or 0) + 1
	    self.handCardTypeNum[v.base.type] = (self.handCardTypeNum[v.base.type] or 0) + 1
	    self.myCardTypeNum[v.base.type] = (self.myCardTypeNum[v.base.type] or 0) + 1
	    self.handCardBaseidNum[v.base.baseid] = (self.handCardBaseidNum[v.base.baseid] or 0) + 1
    end
    for i, v in pairs(self.handCardBaseidNum) do -- 计算对子数量
	    if v >= 3 then
		    self.pairNum = self.pairNum + 1
		    self.TripletNum = self.TripletNum + 1
	    elseif v == 2 then
		    self.pairNum = self.pairNum + 1
	    end
    end
    if self.multiType == nil and self.owner:GetHeapCardNum() >= 45 then
	    if (self.pairNum >= 5) then --决定打七小对
		    self.multiType = 20
		    self.playerInfo:Info("准备胡七小对")
	    elseif (self.pairNum >= 4 and self.TripletNum >= 3) then
		    self.multiType = 37
		    self.playerInfo:Info("准备胡碰碰胡")
	    else 
		    for k,v in pairs(self.myCardTypeNum) do --判断清一色
			    if k < 4 and v >= 10 then
				    self.multiType = 21 --翻型
				    self.multiTypeCardType = k --翻型牌型
				    self.playerInfo:Info("准备胡清一色:" .. k .. ":" .. v)
				    break
			    end
		    end
	    end
    end
end
--判断最优组合,打出一张最烂的牌
function SeatClass:CheckBestHandCard1()
	return nil
end
function SeatClass:GetBestPairHandCard() --准备胡七小对
	local best = nil
	local waitnum = 0
	for i, v in pairs(self.handCard) do -- 自己的手牌
		if self.handCardBaseidNum[v.base.baseid] % 2 ~= 0 then
			best = best or v
			local tmp = 4 - self.showCardNum[v.base.baseid]
			if tmp < waitnum then
				waitnum = tmp
				best = v
			end
			if waitnum == 0 then
				break
			end
		end
	end
	return best
end

function SeatClass:GetBestOneSuitHandCard() --清一色
	local best = nil
	for i, v in pairs(self.handCard) do -- 自己的手牌
		if v.base.type ~= self.multiTypeCardType then
			best = v
			break
		end
	end
	return best
end
function SeatClass:GetBestTripleHandCard() --准备胡刻子
	local best = nil
	local waitnum = 0
	for i, v in pairs(self.handCard) do -- 自己的手牌
		if self.handCardBaseidNum[v.base.baseid]  == 1 then
			best = best or v
			local tmp = 4 - self.showCardNum[v.base.baseid]
			if tmp < waitnum then
				waitnum = tmp
				best = v
			end
			if waitnum == 0 then
				break
			end
		end
	end
	return best
end
function SeatClass:CheckCanOperate(op,thisid)
	if self.multiType == nil then
		return true
	elseif self.multiType == 20 then --七小对
		return false
	elseif self.multiType == 21 then --清一色
		if math.floor(thisid/100) ~= self.multiTypeCardType then
			return false
		end
	elseif self.multiType == 37 then --碰碰胡
		if op == 7 then --不吃
			return false
		end
	end
	return true
end
function SeatClass:CheckBestHandCard(nested)
	if self.playerInfo:IsRobot() then
		--return self:CheckBestHandCard1()
	end
	local handcardnum = table.len(self.handCard)
	local heapcardnum = self.owner:GetHeapCardNum()
	if  table.len(self.owner.state.round.goldCard) == 0 then
		if self.multiType == 20 then --决定打七小对
			local ret = self:GetBestPairHandCard()
			if ret then
				return ret.id
			end
		end
		if self.multiType == 21 then
			local ret = self:GetBestOneSuitHandCard()
			if ret then
				return ret.id
			end
		end
		if self.multiType == 37 then
			local ret = self:GetBestTripleHandCard()
			if ret then
				return ret.id
			end
		end
		for k,v in pairs(self.handCard) do --先重置所有分数
			if not nested then
				v.meld = nil
				v.score = v.base.score or 0
			elseif not v.meld then
				v.score = v.base.score or 0
			end
		end
	end
	local groupCard = self:ReGroup()
	local pattern = TableWinPatternScore[1]
	local meldnum = math.floor((14 - handcardnum)/3)
	local pairnum = 0
	local pairbaseid = 0
	for k,v in pairs(groupCard) do
		for k1,v1 in ipairs(v) do
			local baseid = k * 10 + k1
			if v1 == 2 then
				if self:CheckCanPair(baseid) then
					pairnum = pairnum + 1
					pairbaseid = baseid
				end
				self:IncHandCardScore(baseid,2,v1,false,"对子") --对
			end
		end
	end
	for k,v in pairs(groupCard) do
		for k1,v1 in ipairs(v) do
			local baseid = k * 10 + k1
			if v1 == 4 then
				self:IncHandCardScore(baseid,pattern.Kong,v1,true,"杠") --杠
				groupCard[k][k1] = 0
				meldnum = meldnum + 1
			elseif v1 == 3 then
				if pairnum == 0 and self:CheckCanPair(baseid) then --如果将是刻子,则第三张牌先不标志meld
					self:IncHandCardScore(baseid,pattern.Triplet,2,true,"刻子") --刻
					self:IncHandCardScore(baseid,pattern.Triplet,3,false,"刻子将") --刻
				else
					self:IncHandCardScore(baseid,pattern.Triplet,3,true,"刻子") --刻
				end
				groupCard[k][k1] = 0
				meldnum = meldnum + 1
			end
		end
	end
	for k,v in pairs(groupCard) do
		for k1,v1 in ipairs(v) do
				if v1 > 0 and k < 4 then --万条筒才有必要考虑顺子
					local func = function()
						local baseid = k * 10 + k1
						if v[k1 + 1] and v[k1 + 1] > 0 and v[k1 + 2] and v[k1 + 2] > 0 then
							self:IncHandCardScore(baseid,pattern.Sequence,1,true,"顺子") --顺子
							self:IncHandCardScore(baseid+1,pattern.Sequence,1,true,"顺子") --顺子
							self:IncHandCardScore(baseid+2,pattern.Sequence,1,true,"顺子") --顺子
							if v[k1 + 3] and v[k1 + 3] > 0 then --2,3,4,5
								self:IncHandCardScore(baseid+3,pattern.Sequence/5+(5-k1),1,false,"靠边加分少") --尽量打靠边牌,
							end
							--self.playerInfo:Error("cccccccc:"..k .. ":" .. k1 .. ":" .. v[k1+1] .. ":" ..v[k1+2])
							for i = k1,k1 + 2 do
								v[i] = v[i] - 1
							end
							v1 = v1 - 1
							meldnum = meldnum + 1
						end
					end
					func()
					if v1 > 0 then
						--self.playerInfo:Error("嵌套进入顺子检查:"..v1 .. ":" ..k .. ":" .. k1)
						func()
					end
				end
		end
	end
	local paired = false --寻找将牌
	if pairnum == 1 and meldnum >= 2 then --如果只有一对可以做将,直接强制指定
		paired = true
		self:IncHandCardScore(pairbaseid,pattern.Pair*5,2,true,"定将") --做将牌
		groupCard[math.floor(pairbaseid/10)][pairbaseid%10] = 0
	end
	for k,v in pairs(groupCard) do
		for k1,v1 in ipairs(v) do
			if v1 > 0 and k < 4 then --万条筒才有必要考虑顺子
				local baseid = k * 10 + k1
				--self.playerInfo:Error("bbbbbbbb:"..k .. ":" .. k1..":"..v1)
				if v[k1 + 1] and v[k1 + 1] > 0 then
					if v1 == 2 then
						local waitnum = 4 - self.showCardNum[baseid]
						self:IncHandCardScore(baseid,waitnum*pattern.Pair/(self.showCardNum[baseid]),2,false,"普通对子:"..waitnum) --对,根据剩余牌数量加分
					end
					if k1 == 1 then --边顺,1,2,
						local waitnum = self.showCardNum[baseid+2] or 0 + (self.handCardBaseidNum[baseid+2] or 0)
						waitnum = (4 - waitnum)/4
						if not v[k1 + 3] or v[k1 + 3] == 0 then --1,2,4,直接无视1
							self:IncHandCardScore(baseid,waitnum*pattern.Sequence/(4*v[k1]),1,false,"边顺1:"..waitnum) --顺子
						end
						self:IncHandCardScore(baseid+1,waitnum*pattern.Sequence/(3*v[k1+1]),1,false,"边顺1:"..waitnum) --顺子
						--self.playerInfo:Error("aaaa:1" .. ":"..k .. ":"  .. baseid)
					elseif k1 + 1 == 9 then --边顺,8,9,
						local waitnum = self.showCardNum[baseid-1] or 0 + (self.handCardBaseidNum[baseid-1] or 0)
						waitnum = (4 - waitnum)/4
						if not v[k1 - 2] or v[k1 - 2] == 0 then --6,8,9,直接无视9
							self:IncHandCardScore(baseid,waitnum*pattern.Sequence/(3*v[k1]),1,false,"边顺2:"..waitnum) --顺子
						end
						self:IncHandCardScore(baseid+1,waitnum*pattern.Sequence/(4*v[k1+1]),1,false,"边顺2:"..waitnum) --顺子
						--self.playerInfo:Error("aaaa:2" .. ":"..k .. ":"  .. baseid)
					elseif k1 + 1 < 9 or k1 > 1 then --缺顺,7,8,
						local waitnum = (self.showCardNum[baseid-1] or 0) + (self.showCardNum[baseid+2] or 0) + (self.handCardBaseidNum[baseid-1] or 0) + (self.handCardBaseidNum[baseid+2] or 0)
						waitnum = (8 - waitnum)/4
						self:IncHandCardScore(baseid,waitnum*pattern.Sequence/(2*v[k1]),1,false,"两边顺:"..waitnum) --顺子
						self:IncHandCardScore(baseid+1,waitnum*pattern.Sequence/(2*v[k1+1]),1,false,"两边顺:"..waitnum) --顺子
						--self.playerInfo:Error("aaaa:0" .. ":"..k .. ":"  .. baseid)
					else
						self.playerInfo:Error("BBBBBBBB:2" .. ":"..k .. ":"  .. baseid)
					end
				elseif v[k1 + 2] and v[k1 + 2] > 0 then --卡
					if v1 == 2 then
						local waitnum = 4 - self.showCardNum[baseid]
						self:IncHandCardScore(baseid,waitnum*pattern.Pair/(self.showCardNum[baseid]),2,false,"普通对子:"..waitnum) --对,根据剩余牌数量加分
					end
					local waitnum = self.showCardNum[baseid+1] or 0 + (self.handCardBaseidNum[baseid+1] or 0)
					waitnum = (4 - waitnum)/4
					if k1 == 1 then --边顺,1,3,
						if not v[k1 + 3] or v[k1 + 3] == 0 then --1,2,4,直接无视1
							self:IncHandCardScore(baseid,v[k1+1]+waitnum*pattern.Sequence/(5*v[k1]),1,false,"卡顺1:"..waitnum) --顺子
						end
						self:IncHandCardScore(baseid+2,waitnum*pattern.Sequence/(4*v[k1+2]),1,false,"卡顺1:"..waitnum) --顺子
						--self.playerInfo:Error("aaaa:4" .. ":"..k .. ":"  .. baseid)
					elseif k1 + 2 == 9 then --边顺,7,9,
						if not v[k1 - 1] or v[k1 - 1] == 0 then --6,7,9,直接无视9
							self:IncHandCardScore(baseid,waitnum*pattern.Sequence/(4*v[k1]),1,false,"卡顺2:"..waitnum) --顺子
						end
						self:IncHandCardScore(baseid+2,v[k1] + waitnum*pattern.Sequence/(5*v[k1+2]),1,false,"卡顺2:"..waitnum) --顺子
						--self.playerInfo:Error("aaaa:5" .. ":"..k .. ":"  .. baseid)
					elseif k1 + 2 < 9 or k1 > 1 then --边卡,7,9,
						if not v[k1 + 3] or v[k1 + 3] == 0 then --,2,4,5,直接无视5
							self:IncHandCardScore(baseid,waitnum*pattern.Sequence/(3*v[k1]),1,false,"卡顺3:"..waitnum) --顺子
						end
						if not v[k1 - 1] or v[k1 - 1] == 0 then --2,3,5,直接无视5
							self:IncHandCardScore(baseid+2,waitnum*pattern.Sequence/(3*v[k1+2]),1,false,"卡顺3:"..waitnum) --顺子
						end
						--self.playerInfo:Error("aaaa:3" .. ":"..k .. ":"  .. baseid)
					else
						self.playerInfo:Error("BBBBBBBB:2" .. ":"..k .. ":"  .. baseid)
					end
					--if v1 == 2 then -- 1,3 vs 1,3,3
					--	self:IncHandCardScore(baseid,4,2) --对
				elseif (not v[k1 - 1] or not v[k1 - 1] == 0) and (not v[k1 + 1] or not v[k1 + 1] == 0) then --单独的对子
					if v1 == 2 then
						if not paired and self:CheckCanPair(baseid) then
							paired = true
							self:IncHandCardScore(baseid,pattern.Pair*5,2,true,"定将") --做将牌
						else
							local waitnum = 4 - self.showCardNum[baseid]
							self:IncHandCardScore(baseid,waitnum*pattern.Pair/(self.showCardNum[baseid]),2,false,"普通对子:"..waitnum) --对,根据剩余牌数量加分
						end
					end
				end
			end
		end
	end
	for k,v in pairs(self.handCard) do
		if paired == false and v.score == 52 and self:CheckCanPair(v.base.baseid) then
			paired = true
			self:IncHandCardScore(v.base.baseid,pattern.Pair,2,true,"paired") --做将牌
			self.playerInfo:Error("指定将牌:" .. v.id)
		end
		if v.base.type < 4 then --非字牌
			v.score = v.score + 1
		end
		if self.owner.state.round:IsGoldCard(v) == true and v.score < 100000 then --如果金牌不打
			self:IncHandCardScore(47,v.score,4,false,"goldcard") --白板替金牌
			self:IncHandCardScore(v.base.baseid,100000,4,true,"goldcard") --金牌
		end
		if v.base.type < 4 then --非字牌
			v.score = v.score + (4 - (self.showCardNum[v.base.baseid] or 0))*2
		else
			v.score = v.score + (4 - (self.showCardNum[v.base.baseid] or 0))
		end
		--if self.handCardTypeNum >= 8 then --清一色概率很大了
		--	v.score = v.score + self.handCardTypeNum * 2
		--end
	end
	local best = nil
	local bestlist = {}
	local scores = {}
	for k,v in pairs(self.handCard) do
		if not v.meld then --带牌型的牌最后考虑打
			if paired == false and handcardnum > 2 and self:CheckCanPair(v.base.baseid) then --如果没有将,则给将牌加分,为了减少循环,顺道加下
				if meldnum > 2 and v.score < 10 then
					v.score = v.score + 5 --要大于边牌
				else
					v.score = v.score + 1 --3,3,4,5,5,希望打3不是打5
				end
			end
			best = best or v
			if v.score < best.score then
				best = v
			end
		end
		if v.meld then
			table.insert(scores,",".. k .. ":" .. v.score .. ":true")
		else
			table.insert(scores,",".. k .. ":" .. v.score .. ":false")
		end
	end
	if best and best.base.type < 4 then
		for k,v in pairs(self.handCard) do
			if not v.meld then --带牌型的牌最后考虑打
				if v.score == best.score then
					table.insert(bestlist,v)
				end
			end
		end
		best = nil
		local waitnum_max = nil
		for k,v in ipairs(bestlist) do
			local waitnum = (4 - (self.showCardNum[v.base.baseid] or 0))*3*self.handCardBaseidNum[v.base.baseid]*self.handCardBaseidNum[v.base.baseid]
			local waitnumbase = waitnum
			if waitnumbase > 0 then
				if v.base.point-1 >= 1 and v.base.point-1 <= 9 then
					waitnum = waitnum + (4 - (self.showCardNum[v.base.baseid-1] or 0) + (self.handCardBaseidNum[v.base.baseid-1] or 0))*2
				end
				if v.base.point+1 >= 1 and v.base.point+1 <= 9 then
					waitnum = waitnum + (4 - (self.showCardNum[v.base.baseid+1] or 0) + (self.handCardBaseidNum[v.base.baseid+1] or 0))*2
				end
				if v.base.point-2 >= 1 and v.base.point-2 <= 9 then
					waitnum = waitnum + (4 - (self.showCardNum[v.base.baseid-2] or 0) + (self.handCardBaseidNum[v.base.baseid-2] or 0))*1
				end
				if v.base.point+2 >= 1 and v.base.point+2 <= 9 then
					waitnum = waitnum + (4 - (self.showCardNum[v.base.baseid+2] or 0) + (self.handCardBaseidNum[v.base.baseid+2] or 0))*1
				end
			end
			waitnum_max = waitnum_max or waitnum
			best = best or v
			if waitnum_max > waitnum then
				best = v
			elseif waitnum_max == waitnum and paired == false and self:CheckCanPair(best.base.baseid) then --如果是得分一样,将牌保留
				best = v
			end
		end
	end
	if not best then --如果都配型了,
		--self.playerInfo:Error("准备拆牌打牌")
		for k,v in pairs(self.handCard) do
			best = best or v
			if v.score < best.score then
				best = v
			end
		end
	end
	table.sort(scores)
	local scoresstr = ""
	for i,v in ipairs(scores) do
		scoresstr = scoresstr .. v
	end
	if not self.playerInfo:IsRobot() and (false or unilight.getdebuglevel() > 0) then --屏蔽
		self.playerInfo:Error("出牌得分:"..scoresstr)
		if best.meld then
			best:Error("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx:true:"..best.score..":"..table.len(self.handCard))
		else
			best:Error("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx:false:"..best.score..":"..table.len(self.handCard))
		end
	end
	return best.id
end
--什么牌可以做将牌,需要每个游戏重写,默认是长沙模式
function SeatClass:CheckCanPair(baseid)
	return true
end
--[[function SeatClass:CheckBestHandCard()
	local checkCard = self:RecombineHandCard()
	local goldCardSet = {}
	local card = nil
	local baseid = 0

	-- 检测单张字牌
	for k,v in pairs(checkCard) do
		if v == 1 and math.floor(k/10) == 4 then
			baseid = k
		end
	end
	local focusCard = FocusHandCard(checkCard)
	-- 检测左右间隔两个的单张序数牌
	if baseid == 0 then
		for k,v in pairs(focusCard) do
			if table.len(v) == 1 then
				local left = false
				local right = false
				if focusCard[k-1] == nil or math.modf(focusCard[k-1][1]/10) ~= math.modf(v[1]/10) or (v[1] - focusCard[k-1][table.len(focusCard[k-1])] > 2) then
					left = true
				end
				if focusCard[k+1] == nil or math.modf(focusCard[k+1][1]/10) ~= math.modf(v[1]/10) or (focusCard[k+1][1] - v[1] > 2) then
					right = true
				end
				if left and right then
					baseid = v[1]
					break
				end
			end
		end
	end
	-- 检测左右间隔一个的单张序数牌
	if baseid == 0 then
		for k,v in pairs(focusCard) do
			if table.len(v) == 1 then
				local left = false
				local right = false
				if focusCard[k-1] == nil or math.modf(focusCard[k-1][1]/10) ~= math.modf(v[1]/10) or (v[1] - focusCard[k-1][table.len(focusCard[k-1])] > 1) then
					left = true
				end
				if focusCard[k+1] == nil or math.modf(focusCard[k+1][1]/10) ~= math.modf(v[1]/10) or (focusCard[k+1][1] - v[1] > 1) then
					right = true
				end
				if left and right then
					baseid = v[1]
					break
				end
			end
		end
	end
	-- 检测剔除副牌后剩余的单牌
	if baseid == 0 then
		for k,v in pairs(focusCard) do
			local start = v[1]
			local finish = v[table.len(v)]
			local temp = {}
			for i,j in pairs(v) do
				temp[i] = (temp[i] or 0) + 1
			end
			local num = 0
			while true do
				if temp[start] ~= nil and temp[start+1] ~= nil and temp[start+2] ~= nil then
					temp[start] = temp[start] - 1
					temp[start+1] = temp[start+1] - 1
					temp[start+2] = temp[start+2] - 1
					if temp[start] == 0 then temp[start] = nil end
					if temp[start+1] == 0 then temp[start+1] = nil end
					if temp[start+2] == 0 then temp[start+2] = nil end
				elseif temp[start] ~= nil and temp[start] == 3 then
					temp[start] = nil
				end
				start = start + 1
				if start > finish then
					break
				end
				num = num + 1
				if num == 1000 then
					break
				end
			end
			local tempCard = FocusHandCard(temp)
			for i,j in pairs(tempCard) do
				if table.len(j) == 1 then
					baseid = j[1]
					break
				end
			end
			if baseid == 0 then
				for i,j in pairs(tempCard) do
					if table.len(j) > 1 then
						baseid = j[1]
						break
					end
				end
			end
		end
	end
	if baseid ~= 0 then
		for k,v in pairs(self.handCard) do
			if v.base.baseid == baseid then
				card = v
				break
			end
		end
	end
	-- 到这里还找不到合适的牌那就随便打一张
	if card == nil then
		for k,v in pairs(self.handCard) do
			card = v
			break
		end
	end
	if card == nil then
		self:Error("机器人的牌出错 一张牌都没有 原因未知")
		return 0
	end
	return card.id
end

function FocusHandCard(checkCard)
	local focusCard = {}
	local index = 1
	for i = 11, 19 do
		if checkCard[i] ~= nil and checkCard[i] > 0 then
			focusCard[index] = focusCard[index] or {}
			for j = 1, checkCard[i] do
				table.insert(focusCard[index], i)
			end
		else
			if focusCard[index] ~= nil then
				index = index + 1
			end
		end
	end
	if focusCard[index] ~= nil then
		index = index + 1
	end
	for i = 21, 29 do
		if checkCard[i] ~= nil and checkCard[i] > 0 then
			focusCard[index] = focusCard[index] or {}
			for j = 1, checkCard[i] do
				table.insert(focusCard[index], i)
			end
		else
			if focusCard[index] ~= nil then
				index = index + 1
			end
		end
	end
	if focusCard[index] ~= nil then
		index = index + 1
	end
	for i = 31, 39 do
		if checkCard[i] ~= nil and checkCard[i] > 0 then
			focusCard[index] = focusCard[index] or {}
			for j = 1, checkCard[i] do
				table.insert(focusCard[index], i)
			end
		else
			if focusCard[index] ~= nil then
				index = index + 1
			end
		end
	end
	return focusCard
end]]

function SeatClass:GetOneCard()
	self:ResetShowCardNum()
	local thisid = self:CheckBestHandCard()
	if thisid ~= nil then
		local card = self.handCard[thisid]
		if card then
			return card
		end
	end
	for k,v in pairs(self.handCard) do
		if self.owner.state.round:IsGoldCard(v) == false then --如果金牌不打
			return v
		end
	end
	for k,v in pairs(self.handCard) do --实在没牌,什么都打
		return v
	end
end

function SeatClass:GetListenCard()
	return nil
end
function SeatClass:GetUserCard(hidecard,outcard)
    local uid = self.playerInfo.id
    local ret = {}
    ret.uid = uid
    ret.totalPoints = self.point -- TODO 业务层填充
    if hidecard then
	    ret.handCardSet = self:GetHandCard()
	    ret.listenSet = self:GetListenCard()
    end
    ret.flowerCardSet = self:GetFlowerCard()
    ret.eatSet = self:GetEatCard()
    ret.barSet = self:GetBarCard()
    ret.touchSet = self:GetTouchCard()
    if outcard then
	    ret.outCardSet = self:GetOutCard()
    end
    if next(ret) == nil then
	    ret = nil
    end
    return ret
end

function SeatClass:GetHandCard()
    local cardSet = {}
    for k,v in pairs(self.handCard) do
	    table.insert(cardSet, k)
    end
    if next(cardSet) == nil then
	    return nil
    end
    return cardSet
end


function SeatClass:GetFlowerCard()
	if next(self.flowerCard) == nil then
		return nil
	end
	return self.flowerCard
end
function SeatClass:GetTouchCard()
	if next(self.touchCard) == nil then
		return nil
	end
	return self.touchCard
end

function SeatClass:GetBarCard()
	if next(self.barCard) == nil then
		return nil
	end
	return self.barCard
end

function SeatClass:GetEatCard()
	if next(self.eatCard) == nil then
		return nil
	end
	return self.eatCard
end

function SeatClass:GetOutCard()
	if next(self.outCard) == nil then
		return nil
	end
	return self.outCard
end

function SeatClass:AddOutCard(card)
	table.insert(self.outCard,card.id)
end

function SeatClass:RemoveOutCard(card)
	for k,v in pairs(self.outCard) do
		if v == card.id then
			table.remove(self.outCard,k)
			break
		end
	end
end


function SeatClass:GetHandCardNum()
	return table.len(self.handCard)
end

function SeatClass:Loop()
	if self.playerInfo then
		self.playerInfo:Loop()
	end
end

function SeatClass:GetCardMaxThisid()
	local card = nil
	for k,v in pairs(self.handCard) do
		if self.owner.state.round:IsGoldCard(v) == false then
			card = card or v
			if v.base.baseid > card.base.baseid then
				card = v
			end
		end
	end
	if card == nil then
		for k,v in pairs(self.handCard) do
			 card = v
			 break
		end
	end
	if card == nil then
		self:Error("bbbbbbbbbbbbbbbbbbb:"..table.len(self.handCard)..":".. table.len(self.touchCard) .. ":" .. table.len(self.barCard))
	end
	return card
end
function SeatClass:EatCard(card,one,two,fromid)
	local set = {
		uid = self.playerInfo.id,
		thisId = card.id,
		fromUid = fromid,
	}
	local oneCard = self.handCard[one]
	local twoCard = self.handCard[two]
	if not oneCard or not twoCard then
		self:Error("吃牌失败,找不到:"..one .. ":" ..two .. ":" .. card.id)
		return nil
	end
	local tmplist = {}
	table.insert(tmplist,card.base.baseid)
	table.insert(tmplist,oneCard.base.baseid)
	table.insert(tmplist,twoCard.base.baseid)
	table.sort(tmplist)
	if tmplist[2] - tmplist[1] ~= 1 or tmplist[3] - tmplist[2] ~= 1 then
		self:Error("吃牌发现不是顺子:"..one .. ":" ..two .. ":" .. card.id)
		return nil
	end
	self.handCard[oneCard.id] = nil
	self.handCard[twoCard.id] = nil
	set.one = one
	set.two = two
	table.insert(self.eatCard,set)
	return set
end
function SeatClass:TouchCard(card,fromid)
	local set = {
		uid = self.playerInfo.id,
		thisId = card.id,
		fromUid = fromid,
	}
	set.cardSet = self:GetCardBaseSet(card,2)
	if table.len(set.cardSet) ~= 2 then
		self:Error("碰牌失败,数量不够:"..card:GetName())
		return nil
	end
	for k,v in pairs(set.cardSet) do
		self.handCard[v] = nil
	end
	table.insert(set.cardSet,card.base.thisid)
	table.insert(self.touchCard,set)
	return set
end

function SeatClass:CheckBarCard(card,fromid)
	if card == nil then
		for k,v in pairs(self.handCard) do
			local ret = self:CheckBarCard(v,self.playerInfo.id)
			if ret then
				return ret
			end
		end
	end
	if card == nil then
		return card
	end
	local set = {
		uid = self.playerInfo.id,
		thisId = card.id,
		fromUid = fromid,
	}
	set.cardSet = self:GetCardBaseSet(card,4)
	if self.handCard[card.id] == nil then
		table.insert(set.cardSet,card.id)
	end
	if table.len(set.cardSet) == 4 then
		return set
	elseif fromid == self.playerInfo.id or table.len(set.cardSet) == 1 then
		for k,v in pairs(self.touchCard) do
			if math.floor(v.thisId/10) == card.base.baseid then
				set = table.clone(v)
				table.insert(set.cardSet,card.base.thisid) --这里和上面的代码有约定型猫腻
				break
			end
		end
	end
	if table.len(set.cardSet) < 4 then --这里因为借数组存了个isAllMe,数长度的确会有可能大于5
		return nil
	end
	return set
end
function SeatClass:BarCard(card,fromid)
	local set = {
		uid = self.playerInfo.id,
		thisId = card.id,
		fromUid = fromid,
	}
	set.cardSet = self:GetCardBaseSet(card,4)
	
	if table.len(set.cardSet) == 4 then
		set.barType = 102
		if self.owner.state.operateSeat ~= self or (self.owner.state.operateSeat == self and self.owner.state.round.outCardSeat == nil) then
			self:Debug("*****************************非法操作, 不能杠")
			return
		end
	elseif table.len(set.cardSet) == 3 and fromid ~= self.playerInfo.id then
		set.barType = 101
	elseif table.len(set.cardSet) == 1 and fromid == self.playerInfo.id  then
		if self.owner.state.operateSeat ~= self or (self.owner.state.operateSeat == self and self.owner.state.round.outCardSeat == nil) then
			self:Debug("*****************************非法操作, 不能杠")
			return
		end
		for k,v in pairs(self.touchCard) do
			if math.floor(v.thisId/10) == card.base.baseid then
				set = table.clone(v)
				set.barType = 103
				table.insert(set.cardSet,card.base.thisid)
				table.remove(self.touchCard,k)
				break
			end
		end
	end
	if self.handCard[card.id] == nil then
		table.insert(set.cardSet,card.id)
	end
	if table.len(set.cardSet) < 4 then--这里因为借数组存了个isAllMe,数长度的确会有可能大于5
		self:Error("杠牌失败,数量不够:"..table.len(set.cardSet) .. ":" .. card:GetName())
		return nil
	end
	for k,v in pairs(set.cardSet) do
		self.handCard[v] = nil
	end
	table.insert(self.barCard,set)
	return set
end
function SeatClass:GetCardBaseSet(card,max)
	local ret = {}
	for k,v in pairs(self.handCard) do
		if v.base.baseid == card.base.baseid and table.len(ret) < max then
			table.insert(ret,v.base.thisid)
		end
	end
	return ret
end
function SeatClass:CheckHasChickenByBaseId(baseid)
	for k,v in pairs(self.handCard) do
		if v.base.baseid == baseid then
			return true
		end
	end
	for k,v in pairs(self.touchCard) do
		if math.floor(v.thisId/10) == baseid then
			return true
		end
	end
	for k,v in pairs(self.barCard) do
		if math.floor(v.thisId/10) == baseid then
			return true
		end
	end
	for k,v in pairs(self.eatCard) do
		if math.floor(v.thisId/10) == baseid then
			return true
		end
		if math.floor(v.one/10) == baseid then
			return true
		end
		if math.floor(v.two/10) == baseid then
			return true
		end
	end
	for k,v in pairs(self.outCard) do
		if math.floor(v/10) == baseid then
			return true
		end
	end
	return false
end
function SeatClass:GetHandCardByBaseId(baseid)
	for k,v in pairs(self.handCard) do
		if v.base.baseid == baseid then
			return v
		end
	end
	return nil
end
function SeatClass:GetHandCardNumByBaseId(baseid)
	local ret = 0
	for k,v in pairs(self.handCard) do
		if v.base.baseid == baseid then
			ret = ret + 1
		end
	end
	return ret
end
-- 其他座位的手牌和牌堆中的剩余数
function SeatClass:GetRemainNumByBaseId(baseid)
	local ret = 0
	for k,v in pairs(self.owner.state.heapCard) do
		if v.base.baseid == baseid then
			ret = ret + 1
		end
	end
	for k,v in pairs(self.owner.state.seats) do
		if v ~= self then
			ret = ret + v:GetHandCardNumByBaseId(baseid)
		end
	end
	return ret
end

function SeatClass:GetBestWinType(card)
	return nil
end
function SeatClass:GetClientId(requestuser)
	requestuser = requestuser or self.playerInfo
	local ret = 0
	if self.owner.base.eastSeat == 1 then
		if requestuser.state.seat.id == 1 then
			ret = self.id
		elseif requestuser.state.seat.id == 2 then
			ret = (self.id+2)%4+1
		elseif requestuser.state.seat.id == 3 then
			ret = (self.id+1)%4+1
		elseif requestuser.state.seat.id == 4 then
			ret = (self.id+4)%4+1
		end
	else
		for i = requestuser.state.seat.id,requestuser.state.seat.id + 4 do
			local index = ((i - 1)%4)+1
			if self.owner.state.seats[index] then 
				ret = ret + 1
				if self.owner.state.seats[index].id == self.id then
					break
				else
				end
			end
		end
		if self.owner.data.usernbr == 3 and ret == 3 then
			ret = ret + 1
		elseif self.owner.data.usernbr == 2 and ret == 2 then
			ret = ret + 1
		end
	end
	--requestuser.state.seat.playerInfo:Error("xxxxxxxxxxxxxxxxxxxxxxxxxx:" .. self.owner.data.usernbr .. ":".. requestuser.state.seat.id .. ":" .. self.id .. ":" .. ret)
	return ret
end
function SeatClass:GetNextSeat()
	return self.owner.state.seats[(self.owner.state.operateSeat.id % self.owner.data.usernbr) + 1]
end
function SeatClass:GetPreSeat()
	return self.owner.state.seats[((self.owner.state.operateSeat.id + 2) % self.owner.data.usernbr) + 1]
end
function SeatClass:CheckCanEat(card)
	return false
end
function SeatClass:GetEatSet(card)
	if not self.owner:CheckCanEatCard() then
		return nil
	end
	if card.base.type >= 4 then
		return nil
	end
	local list = {}
	local nextSeat = self.owner.state.operateSeat:GetNextSeat()
	if self ~= nextSeat then
		return nil
	end
	local l2 = nextSeat:GetHandCardByBaseId(card.base.baseid - 2)
	local l1 = nextSeat:GetHandCardByBaseId(card.base.baseid - 1)
	local r1 = nextSeat:GetHandCardByBaseId(card.base.baseid + 1)
	local r2 = nextSeat:GetHandCardByBaseId(card.base.baseid + 2)
	if l1  and l2  then
		table.insert(list,{one=l1.id,two=l2.id,})
	end
	if l1 and r1 then
		table.insert(list,{one=l1.id,two=r1.id,})
	end
	if r1 and r2 then
		table.insert(list,{one=r1.id,two=r2.id,})
	end
	if next(list) == nil then
		list = nil
	end
	return list
end
function SeatClass:GetOperateType(card) --打牌检测,返回要按操作优先级返回
	local list = {}
	local basenum = self:GetHandCardNumByBaseId(card.base.baseid)
	local winType = self:GetBestWinType(card)
	if winType ~= nil then
		table.insert(list,winType) --MahjongOpCardType_Bar
	end
	if self.owner:CheckCanBarCard() and basenum >= 3 then --杠
		table.insert(list,2) --MahjongOpCardType_Bar
	end
	if self.owner:CheckCanTouchCard() and basenum >= 2 then --碰
		table.insert(list,6) --MahjongOpCardType_Touch
	end
	local eatSet = self:GetEatSet(card)
	if self.owner:CheckCanEatCard() and eatSet then
		table.insert(list,7) --MahjongOpCardType_Bar
	end
	if next(list) == nil then
		list = nil
	end
	return list,eatSet
end

function SeatClass:GetMyOperateType() --摸牌检测
	local list = {}
	local thisid = nil
	for k,v in pairs(self.handCard) do --本次循环只找一个杠
		local basenum = self:GetHandCardNumByBaseId(v.base.baseid)
		if basenum == 1 then --碰杠
			for k,v1 in pairs(self.touchCard) do
				if math.floor(v1.thisId/10) == v.base.baseid then
					basenum = basenum + 3
					break
				end
			end
		end
		if basenum == 4 then --自杠
			--thisid = v.id
			table.insert(list,2) --MahjongOpCardType_Bar
			break
		end
	end
	if next(list) == nil then
		list = nil
	end
	--TODO 听牌
	return list,thisid
end

function SeatClass:GetMyOperateData(data)
	return data
end
function SeatClass:GetMyOutCardData(data, card)
	return data
end
-- 检测胡牌(可根据需求重写需要的组合)
function SeatClass:CheckWin(card, winflag, check)
	if self:CheckCommonWin(card) then
		return true
	end

	if self:CheckSevenPairsWin(card) then
		return true
	end

	if self:CheckShiSanYaoWin(card) then
		return true
	end

	if self:CheckQuanBuKaoWin(card) then
		return true
	end

	if self:CheckZeHeLongWin(card) then
		return true
	end
	return false
end

-- 获取出牌之后的待胡牌
function SeatClass:GetWinCardList()
	local normalCard = self:GetNormalCard()
	local winCard = {}
	for k,v in pairs(normalCard) do
		local thisid = v*10 + 5
		local card = {}
		card.id = thisid
		card.base = {
			baseid = v,
			thisid = thisid,
			type = math.floor(v/10),
			point = v%10
		}
		if self:CheckWin(card) then
			thisid = v*10 + 1
			table.insert(winCard, thisid)
		end
	end
	if next(winCard) == nil then
		winCard = nil
	end
	return winCard
end

function SeatClass:GetWinCardSet()
	local winCardSet = {}
	local winCard = self:GetWinCardList()
	if winCard == nil then
		winCardSet = nil
	else
		for k,v in pairs(winCard) do
			local obj = {
				thisId = v,
			}
			if not self.last_JsonCompressNullUserPmd_CS then
				--等待兼容后删除
				obj.remainNum = self:GetRemainNumByBaseId(math.floor(v/10))
			end
			table.insert(winCardSet, obj)
		end
	end
	return winCardSet
end

function SeatClass:GetNormalCard()
	return self.owner.state.normalCardBaseId
end

-- 检测听牌
function SeatClass:CheckListen(card)
	-- 备份
	local handCard = self.handCard --WHJ 第一遍不需要clone,clone后也是直接被覆盖
	if card ~= nil then
		handCard[card.id] = card
	end
	local listenMap = {}		-- 出哪张牌->听哪些牌
	local baseidMap = {}
	for k,v in pairs(handCard) do
		if not baseidMap[v.base.baseid] then
			baseidMap[v.base.baseid] = 1
			-- 刷新
			self.handCard = table.clone(handCard,1)
			self.handCard[k] = nil
			local winCardSet = self:GetWinCardSet()
			if winCardSet then
				local listenSet = {}
				for i,j in pairs(winCardSet) do
					local listenObj = {
						thisId = j,
					}
					if not self.last_JsonCompressNullUserPmd_CS then
						--等待兼容后删除
						listenObj.remainNum = self:GetRemainNumByBaseId(math.floor(j/10))
					end
					table.insert(listenSet, listenObj)
				end
				listenMap[k] = listenSet
			end
		end
	end
	-- 还原
	if card ~= nil then
		handCard[card.id] = nil
	end
	self.handCard = handCard
	if next(listenMap) == nil then
		listenMap = nil
	end
	return listenMap
end

-- 检测七对
function SeatClass:CheckSevenPairsWin(card)
	local checkCard = self:RecombineHandCard(card)
	local isPair = true
	local handNum = 0
	for k,v in pairs(checkCard) do
		if v ~= 2 and v ~= 4 then
			isPair = false
			break
		end
		handNum = handNum + v
	end
	if handNum ~= 14 then
		isPair = false
	end
	return isPair
end

-- 检测十三幺
function SeatClass:CheckShiSanYaoWin(card)
	local checkCard = self:RecombineHandCard(card)
	local set = {}
	local pairsNum = 0
	for k,v in pairs(checkCard) do
		table.insert(set, k)
		if v >= 2 then
			pairsNum = pairsNum + 1
		end
	end
	if table.len(set) ~= 13 or pairsNum >= 2 or pairsNum == 0 then
		return false
	end
	local tab = {11,19,21,29,31,39,41,42,43,44,45,46,47}
	return CheckTableContainTable(set,tab)
end

-- 检测全不靠
function SeatClass:CheckQuanBuKaoWin(card)
	local checkCard = self:RecombineHandCard(card)
	local groupCard = self:ReGroupHandCard(card)
	local set = {}
	for k,v in pairs(checkCard) do
		table.insert(set, k)
	end
	if table.len(set) ~= 14 then
		return false
	end
	if groupCard[1] == nil or groupCard[2] == nil or groupCard[3] == nil or groupCard[4] == nil then
		return false
	end
	local tab1 = {1,4,7}
	local tab2 = {2,5,8}
	local tab3 = {3,6,9}

	-- 枚举
	if (CheckTableContainTable(tab1, groupCard[1]) == true and CheckTableContainTable(tab2, groupCard[2]) and CheckTableContainTable(tab3, groupCard[3]) == true) or
	   (CheckTableContainTable(tab1, groupCard[1]) == true and CheckTableContainTable(tab2, groupCard[3]) and CheckTableContainTable(tab3, groupCard[2]) == true) or
	   (CheckTableContainTable(tab1, groupCard[2]) == true and CheckTableContainTable(tab2, groupCard[1]) and CheckTableContainTable(tab3, groupCard[3]) == true) or
	   (CheckTableContainTable(tab1, groupCard[2]) == true and CheckTableContainTable(tab2, groupCard[3]) and CheckTableContainTable(tab3, groupCard[1]) == true) or
	   (CheckTableContainTable(tab1, groupCard[3]) == true and CheckTableContainTable(tab2, groupCard[1]) and CheckTableContainTable(tab3, groupCard[2]) == true) or
	   (CheckTableContainTable(tab1, groupCard[3]) == true and CheckTableContainTable(tab2, groupCard[2]) and CheckTableContainTable(tab3, groupCard[1]) == true) then
	   return true
	end
	return false
end

-- 检测组合龙+顺/刻+将
function SeatClass:CheckZeHeLongWin(card)
	local checkCard = self:RecombineHandCard(card)
	local tab1 = {1,4,7}
	local tab2 = {2,5,8}
	local tab3 = {3,6,9}
	for k,v in pairs(checkCard) do
		if CheckPairCard(k, v) then
			local tempCheckCard = table.clone(checkCard)
			tempCheckCard[k] = tempCheckCard[k] - 2
			if tempCheckCard[k] == 0 then
				tempCheckCard[k] = nil
			end
			local groupCard = ReGroupByCheckCard(tempCheckCard)
			if groupCard ~= nil and groupCard[1] ~= nil and groupCard[2] ~= nil and groupCard[3] ~= nil then
				-- 枚举
				local flag = false
				if CheckTableContainTable(groupCard[1], tab1) and CheckTableContainTable(groupCard[2], tab2) and CheckTableContainTable(groupCard[3], tab3) then
					tempCheckCard[11] = tempCheckCard[11] - 1
					tempCheckCard[14] = tempCheckCard[14] - 1
					tempCheckCard[17] = tempCheckCard[17] - 1
					tempCheckCard[22] = tempCheckCard[22] - 1
					tempCheckCard[25] = tempCheckCard[25] - 1
					tempCheckCard[28] = tempCheckCard[28] - 1
					tempCheckCard[33] = tempCheckCard[33] - 1
					tempCheckCard[36] = tempCheckCard[36] - 1
					tempCheckCard[39] = tempCheckCard[39] - 1
					flag = true
				end
				if flag == false and CheckTableContainTable(groupCard[1], tab1) and CheckTableContainTable(groupCard[2], tab3) and CheckTableContainTable(groupCard[3], tab2) then
					tempCheckCard[11] = tempCheckCard[11] - 1
					tempCheckCard[14] = tempCheckCard[14] - 1
					tempCheckCard[17] = tempCheckCard[17] - 1
					tempCheckCard[23] = tempCheckCard[23] - 1
					tempCheckCard[26] = tempCheckCard[26] - 1
					tempCheckCard[29] = tempCheckCard[29] - 1
					tempCheckCard[32] = tempCheckCard[32] - 1
					tempCheckCard[35] = tempCheckCard[35] - 1
					tempCheckCard[38] = tempCheckCard[38] - 1
					flag = true
				end
				if flag == false and CheckTableContainTable(groupCard[1], tab2) and CheckTableContainTable(groupCard[2], tab1) and CheckTableContainTable(groupCard[3], tab3) then
					tempCheckCard[12] = tempCheckCard[12] - 1
					tempCheckCard[15] = tempCheckCard[15] - 1
					tempCheckCard[18] = tempCheckCard[18] - 1
					tempCheckCard[21] = tempCheckCard[21] - 1
					tempCheckCard[24] = tempCheckCard[24] - 1
					tempCheckCard[27] = tempCheckCard[27] - 1
					tempCheckCard[33] = tempCheckCard[33] - 1
					tempCheckCard[36] = tempCheckCard[36] - 1
					tempCheckCard[39] = tempCheckCard[39] - 1
					flag = true
				end
				if flag == false and CheckTableContainTable(groupCard[1], tab2) and CheckTableContainTable(groupCard[2], tab3) and CheckTableContainTable(groupCard[3], tab1) then
					tempCheckCard[12] = tempCheckCard[12] - 1
					tempCheckCard[15] = tempCheckCard[15] - 1
					tempCheckCard[18] = tempCheckCard[18] - 1
					tempCheckCard[23] = tempCheckCard[23] - 1
					tempCheckCard[26] = tempCheckCard[26] - 1
					tempCheckCard[29] = tempCheckCard[29] - 1
					tempCheckCard[31] = tempCheckCard[31] - 1
					tempCheckCard[34] = tempCheckCard[34] - 1
					tempCheckCard[37] = tempCheckCard[37] - 1
					flag = true
				end
				if flag == false and CheckTableContainTable(groupCard[1], tab3) and CheckTableContainTable(groupCard[2], tab1) and CheckTableContainTable(groupCard[3], tab2) then
					tempCheckCard[13] = tempCheckCard[13] - 1
					tempCheckCard[16] = tempCheckCard[16] - 1
					tempCheckCard[19] = tempCheckCard[19] - 1
					tempCheckCard[21] = tempCheckCard[21] - 1
					tempCheckCard[24] = tempCheckCard[24] - 1
					tempCheckCard[27] = tempCheckCard[27] - 1
					tempCheckCard[32] = tempCheckCard[32] - 1
					tempCheckCard[35] = tempCheckCard[35] - 1
					tempCheckCard[38] = tempCheckCard[38] - 1
					flag = true
				end
				if flag == false and CheckTableContainTable(groupCard[1], tab3) and CheckTableContainTable(groupCard[2], tab2) and CheckTableContainTable(groupCard[3], tab1) then
					tempCheckCard[13] = tempCheckCard[13] - 1
					tempCheckCard[16] = tempCheckCard[16] - 1
					tempCheckCard[19] = tempCheckCard[19] - 1
					tempCheckCard[22] = tempCheckCard[22] - 1
					tempCheckCard[25] = tempCheckCard[25] - 1
					tempCheckCard[28] = tempCheckCard[28] - 1
					tempCheckCard[31] = tempCheckCard[31] - 1
					tempCheckCard[34] = tempCheckCard[34] - 1
					tempCheckCard[37] = tempCheckCard[37] - 1
					flag = true
				end
				if flag == true then
					for i,j in pairs(tempCheckCard) do
						if tempCheckCard[i] == 0 then
							tempCheckCard[i] = nil
						end
					end
					if table.len(tempCheckCard) == 0 then
						return true
					else
						local set = {}
						for i,j in pairs(tempCheckCard) do
							table.insert(set, k)
						end
						-- 剩余三张是刻子
						if table.len(set) == 1 then
							return true
						end
						-- 剩余三张是顺子
						if table.len(set) == 3 then
							if math.floor(set[1]/10) ~= 4 and set[1] + 1 == set[2] and set[2] + 1 == set[3] then
								return true
							end
						end
					end
				end
			end
		end
	end
	return false
end

-- 检测通用胡(顺/刻+将)
function SeatClass:CheckCommonWin(card)
	local checkCard = self:RecombineHandCard(card)
	local groupCard = self:ReGroupHandCard(card)
	for k,v in pairs(checkCard) do
		if CheckPairCard(k,v) then
			local tempGroupCard = table.clone(groupCard)
			local one = math.floor(k/10)
			local two = k%10
			tempGroupCard[one][two] = tempGroupCard[one][two] - 2
			if tempGroupCard[one][two] == 0 then
				tempGroupCard[one][two] = nil
			end
			local ret, straightSet, threeSet = DoCheckCommon(tempGroupCard)
			if ret == true then
				return true, straightSet, threeSet, k
			end
		end
	end
	return false, {}, {}
end

-- 检测刻+顺
function DoCheckCommon(groupCard)
	local straightSet = {} -- 存储顺子中最小的baseid
	local threeSet = {}	   -- 存储刻子的baseid
	for k,v in pairs(groupCard) do
		if k == 4 then
			for i,j in pairs(v) do
				if j ~= 3 then
					return false
				end
				table.insert(threeSet, k*10+i)
			end
		else
			if CheckOrdinalCard(k, groupCard, straightSet, threeSet) == false then
				return false
			end
		end
	end
	return true, straightSet, threeSet
end

-- 检测序数牌
function CheckOrdinalCard(k, groupCard, straightSet, threeSet)
	for i=1,9 do
		if groupCard[k][i] ~= nil and groupCard[k][i] > 0 then
			if groupCard[k][i] == 3 then
				local subGroupCard = table.clone(groupCard)
				subGroupCard[k][i] = subGroupCard[k][i] - 3
				if CheckOrdinalCard(k, subGroupCard, straightSet, threeSet) == true then
					table.insert(threeSet, k * 10 + i)
					return true
				end
			elseif groupCard[k][i] == 4 then
				groupCard[k][i] = groupCard[k][i] - 3
				table.insert(threeSet, k * 10 + i)
			end
			local ret, num = CheckStraight(groupCard, k, i)
			if ret == false then
				return false
			else
				for j=1,num do
					table.insert(straightSet, k * 10 + i)
				end
			end
		end
	end
end

-- 检测顺
function CheckStraight(groupCard, k, i)
	local nextOne = i + 1
	local nextTwo = i + 2
	local num = groupCard[k][i]
	if nextOne < 9 and nextTwo <= 9 and groupCard[k][nextOne] ~= nil and groupCard[k][nextTwo] ~= nil and 
		groupCard[k][nextOne] >= num and groupCard[k][nextTwo] >= num then
		groupCard[k][i] = groupCard[k][i] - num
		groupCard[k][nextOne] = groupCard[k][nextOne] - num
		groupCard[k][nextTwo] = groupCard[k][nextTwo] - num
		return true, num
	end
	return false
end

-- 重组胡牌者最终手牌(包括返回所有顺子 刻子 将) 用于番型检测 card是点炮的牌或抢杠胡的牌 自摸不需要
function SeatClass:RegroupFinalHandCard(card)
	local groupCard = self:ReGroupHandCard(card)
	local ret, straightSet, threeSet, pairCard = self:CheckCommonWin(card)
	for k,v in pairs(self.touchCard) do
		table.insert(threeSet, math.floor(v.thisId/10))
		local cardType = math.floor(v.thisId/100)
		local cardPoint = math.floor(v.thisId/10)%10
		groupCard[cardType] = groupCard[cardType] or {}
		groupCard[cardType][cardPoint] = (groupCard[cardType][cardPoint] or 0) + 3
	end
	for k,v in pairs(self.barCard) do
		table.insert(threeSet,math.floor(v.cardSet[1]/10))
		local cardType = math.floor(v.thisId/100)
		local cardPoint = math.floor(v.thisId/10)%10
		groupCard[cardType] = groupCard[cardType] or {}
		groupCard[cardType][cardPoint] = (groupCard[cardType][cardPoint] or 0) + 3 --WHJ 这里是不是应该是4?
	end
	for k,v in pairs(self.eatCard) do
		table.insert(straightSet, CheckMin(math.floor(v.one/10),math.floor(v.two/10),math.floor(v.thisId/10)))
		local cardType = math.floor(v.thisId/100)
		local thisPoint = math.floor(v.thisId/10)%10
		local onePoint = math.floor(v.one/10)%10
		local twoPoint = math.floor(v.two/10)%10
		groupCard[cardType] = groupCard[cardType] or {}
		groupCard[cardType][thisPoint] = (groupCard[cardType][thisPoint] or 0) + 1
		groupCard[cardType][onePoint] = (groupCard[cardType][onePoint] or 0) + 1
		groupCard[cardType][twoPoint] = (groupCard[cardType][twoPoint] or 0) + 1
	end
	return groupCard, threeSet, straightSet, pairCard
end

-- 重组手牌(baseid->num)
function SeatClass:RecombineHandCard(card)
	local checkCard = {}
	if card and self.handCard[card.base.thisid] ~= nil then
		checkCard[card.base.baseid] = (checkCard[card.base.baseid] or 0) + 1
	end
	for k,v in pairs(self.handCard) do
		checkCard[v.base.baseid] = (checkCard[v.base.baseid] or 0) + 1
	end
    return checkCard
end

-- 重组手牌(type->{point->num})
function SeatClass:ReGroupHandCard(card)
	local groupCard = {}
	if card and self.handCard[card.base.thisid] == nil then
		groupCard[card.base.type] = groupCard[card.base.type] or {}
		groupCard[card.base.type][card.base.point] = (groupCard[card.base.type][card.base.point] or 0) + 1
	end
	for k, v in pairs(self.handCard) do
		groupCard[v.base.type] = groupCard[v.base.type] or {}
		groupCard[v.base.type][v.base.point] = (groupCard[v.base.type][v.base.point] or 0) + 1
	end
    return groupCard
end

-- 重组手牌(由(baseid->num)转换成type->{point->num})
function ReGroupByCheckCard(checkCard)
	local groupCard = {}
	for k,v in pairs(checkCard) do
		if v > 0 then
			local one = math.floor(k/10)
			local two = k%10
			groupCard[one] = groupCard[one] or {}
			table.insert(groupCard[one],two)
		end
	end
	return groupCard
end

-- 检测数组tabOne是否包含数组tabTwo中所有元素
function CheckTableContainTable(tabOne, tabTwo)
    local flag = true
    for k,v in pairs(tabTwo) do
        if table.find(tabOne, v) == nil then
            flag = false
            break
        end
    end
    return flag
end

-- 获取三个数中的最小数
function CheckMin(one,two,three)
	local min = one
	if one >= two then
		min = two
	end
	if min >= three then
		min = three
	end
	return min
end

-- 对将牌有特殊要求的可重写该方法(这里只需数量大于1即可做将 k:baseid v:num)
function CheckPairCard(k, v)
	if v > 1 then
		return true
	end
	return false
end
