module("ItemStatistics", package.seeall)

-- 统计项
ENUM_STATIC_TYPE = {
	CRT 	= 1,	-- 账号创建 		-- 注入
	AGT 	= 2,	-- 代理商充值
	ARR  	= 3,	-- 约牌
	SDK  	= 4,	-- sdk
	IVT  	= 5,	-- 邀请赠送
	REC  	= 6,	-- 官方充值
	SGN 	= 7, 	-- 签到奖励
	SHR 	= 8, 	-- 分享奖励
	RET 	= 9, 	-- 代理商返钻  
	GIV 	=10, 	-- 系统赠送  

	NOR  	= 101,	-- 普通房费  		-- 消耗
	PRA  	= 102,	-- 练习场房费
	SNA 	= 103,	-- 喇叭扣费
	FLW 	= 104,	-- 送花扣费

	GBL  	= 201,	-- 赌钻 			-- 变动
	GM  	= 202,	-- gm变动
	RED 	= 203,	-- 包红包了
	MTC 	= 204,	-- 比赛场输赢		
}

function Init(itemId)
	local itemData = {
		_id 		= itemId,
		pre 		= nil, 	-- 该系统引入前服务器已有货币量
		all 		= 0, 	-- 总共服务器存留货币量
	}
	unilight.savedata("itemstatistics", itemData)
	return itemData
end

-- 更新物品变动数据
function UpdateItemStatistics(itemId, typ, num)
	-- local itemData = unilight.getdata("itemstatistics", itemId)
	-- if itemData == nil then
	-- 	itemData = Init()
	-- end

	-- itemData[typ] = itemData[typ] or 0

	-- -- 如果pre字段为nil 则先统计一下当前服务器现有钻石总量 
	-- if itemData.pre == nil then
	-- 	itemData.pre = GetPreItemNum(itemId, num)
	-- 	if itemData.pre ~= nil then
	-- 		itemData.all = itemData.all + itemData.pre
	-- 	end
	-- end

	-- itemData[typ] 	= itemData[typ] + num
	-- itemData.all 	= itemData.all + num

	-- unilight.savedata("itemstatistics", itemData)
end

-- 汇总该系统开发前 该物品所有数量
function GetPreItemNum(itemId, num)
	local pre  = nil
	local info = nil
	-- 金币
	if itemId == 1 then
		info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate('{"$match":{}}','{"$group":{"_id":1, "sum":{"$sum":"$property.chips"}}}'))
	-- 钻石
	elseif itemId == 2 then
		info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate('{"$match":{}}','{"$group":{"_id":1, "sum":{"$sum":"$mahjong.diamond"}}}'))
	-- 房卡
	elseif itemId == 3 then
		info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate('{"$match":{}}','{"$group":{"_id":1, "sum":{"$sum":"$mahjong.card"}}}'))
	-- 积分
	elseif itemId == 4 then
		info = unilight.chainResponseSequence(unilight.startChain().Table("userinfo").Aggregate('{"$match":{}}','{"$group":{"_id":1, "sum":{"$sum":"$mahjong.point"}}}'))
	end

  	local sum = info[1] and info[1].sum
  	if sum ~= nil and sum ~= false then
		-- 去除最新的这次变动 即为该系统生效前 服务器所存有的钻石量 
		pre = sum - num
  	end
	return pre
end