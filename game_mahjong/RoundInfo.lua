module('RoundInfo', package.seeall) -- 

if RoundClass == nil then
	CreateClass("RoundClass")
end
RoundClass:SetClassName("Round")

function RoundClass:GetId()
	return self.owner.id .. ":" .. self.id
end
function RoundClass:GetName()
	return self.name
end
function CreateRound(owner,roundid)
	local round = RoundClass:New() 
	round.id = roundid
	round.name = owner.name
	round.owner = owner
	round.goldCard = {}
	round.firstBankerCard = nil --庄家的第14张牌
	round.newGetCardType = 0 --最新发出的牌类型,0表示正常摸牌,1表示杠后摸牌,中间预留,10表示模拟摸牌
	round.newGetCard = nil --最新发出的牌
	round.newOutCard = nil --最新打出去的牌
	round.outCardSeat = nil --最后一个出牌座位
	round.waitOpSet = {} --被优先级影响的操作等待列表
	round.canOpSet = {} --玩家可操作集合
	round:InitMyRound()

	return round
end
function RoundClass:InitMyRound()
	self:Debug("等待重构InitMyRound")
end
function RoundClass:SetGoldCard()
	for k,v in ipairs(self.owner.base.goldCard) do
		local card = self.owner:GetOneCard(v,true)
		self.goldCard[card.id] = card
		self.owner:Shuffle()
	end
end
function RoundClass:GetGoldCardSet()
	local list = {}
	for k,v in pairs(self.goldCard) do
		table.insert(list,v.id)
	end
	if table.len(list) == 0 then
		list = nil
	end
	return list
end
function RoundClass:CheckCanOp(seat,optype)
	if self.canOpSet[seat] == nil then
		return false
	end
	for k,v in pairs(self.canOpSet[seat]) do
		if v == optype then
			return true
		end
	end
	return false
end
function RoundClass:GetOperatePrioritySeat(seat,optype)
	if seat == nil or optype == nil then
		return seat
	end
	for k,v in pairs(self.canOpSet) do
		if k ~= seat then
			if v[1] < optype then
				return k
			end
		end
	end
	return seat
end
function RoundClass:GetOperatePrioritySeatCan()
	local first = nil --最优先操作者
	local retk,retv = nil --最优先操作者
	for k,v in pairs(self.canOpSet) do
		first = first or v[1]
		retk = retk or k
		retv = retv or v
		if first > v[1] then
			first = v[1]
			retk = k
			retv = v
		end
	end
	return retk,retv
end
function RoundClass:GetOperatePrioritySeatWait()
	local first = nil --最优先操作者
	local retk,retv = nil --最优先操作者
	for k,v in pairs(self.waitOpSet) do
		first = first or v.opType
		retk = retk or k
		retv = retv or v
		if first > v.opType then
			first = v.opType
			retk = k
			retv = v
		end
	end
	return retk,retv
end
function RoundClass:IsGoldCard(card)
	for k,v in pairs(self.goldCard) do
		if v.base.baseid == card.base.baseid then
			return true
		end
	end
	return false
end
