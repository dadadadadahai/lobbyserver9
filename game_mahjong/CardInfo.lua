module('CardInfo', package.seeall) -- 

if CardClass == nil then
	CreateClass("CardClass")
end
CardClass:SetClassName("Card")

function CardClass:GetId()
	return self.base.thisid .. ":" .. self.base.baseid
end
function CardClass:GetName()
	return self.base.name
end
function CreateCard(thisid)
	local card = CardClass:New() 
	card.base = TableCard[thisid]
	if card.base == nil then
		unilight.error("找不到麻将对应表格TableCard记录:" .. thisid)
		card = nil
		return
	end
	card.id = card.base.thisid
	card.score = card.base.score or 0 --用来打牌时计算
	return card
end
function GetCardNameByBaseId(baseid)
	local base = TableCard[baseid * 10 + 1]
	if base == nil then
		return "找不到牌:" .. baseid
	end
	return base.name
end

