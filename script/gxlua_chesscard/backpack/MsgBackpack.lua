-- 请求背包列表
Net.CmdBackpackInfoRequestBackpackCmd_C= function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.BackpackInfoReturnBackpackCmd_S"
	local uid = laccount.Id
	local backpack = BackpackMgr.CmdBackpackListGetByUid(uid)
	local backpackList = {}
	local backpackNbr = 0
	local backpackArray = {}

	-- for i,v in pairs(backpack.surplus) do
        -- table.insert(backpackList, v)
	-- end

	res["data"] = {
		resultCode = 0,
		desc = "ok",
		backpackList = backpack.surplus,
	}
	return res
end

-- 请求使用物品
Net.CmdBackpackExchangeRequestBackpackCmd_C= function(cmd, laccount)
	local res = {}
	res["do"] = "Cmd.BackpackExchangeReturnBackpackCmd_S"
	local uid = laccount.Id
	if cmd.data == nil or cmd.data.backpackInfo == nil then
		res["data"] = {
			resultCode = 1,
			desc = "参数缺乏",
		}
		return res 
	end
	local backpackInfo = cmd.data.backpackInfo
	local goodId = backpackInfo.goodId
	local goodNum = backpackInfo.number
	local content = "客户端请求使用"
	local bOk, desc, surplus = BackpackMgr.UseItem(uid, goodId, goodNum, content)
	if bOk ~= true then
		res["data"] = {
			resultCode = 2,
			desc = "物品数量不够",
		}
		return res
	end

	res["data"] = {
		resultCode = 0,
		desc = "ok",
        goodId = goodId,
		surplus = surplus, 
	}
	return res
end
