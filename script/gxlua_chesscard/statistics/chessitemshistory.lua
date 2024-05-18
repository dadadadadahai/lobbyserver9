module('ChessItemsHistory', package.seeall) 
-- 统计玩家最近100条物品消耗记录（暂时只记录金币变动）

TABLE_NAME = "newItemsHistory"

--[[
	刷回方式(存在问题未解决 勿用)
	db.itemsHistory.find().forEach(
		function(history){
			var uid = history.uid;
			var test = history.data[1];
			for (x in test)
			{
				var newhistory;
				var pre = test[x];
				newhistory.uid 	 = uid;
				newhistory.itemid = pre.itemid;	
				newhistory.balance = pre.balance;	
				newhistory.diff = pre.diff;	
				newhistory.timestamp = pre.timestamp;	
				newhistory.desc = pre.desc;	
				var newDate = new Date();
				newDate.setTime(pre.timestamp * 1000);
				newhistory.time = newDate.toLocaleString();	
				db.newItemsHistory.save(newhistory)
			}
		}
	)
	添加索引
	db.newItemsHistory.ensureIndex({uid: 1, itemid: 1});

	获取方式修改
	db.newItemsHistory.find({uid:1303027, itemid:1}).sort({timestamp:-1}).limit(100).pretty()
]]

-- 新增物品变动历史记录(17.3.9 采用新的存储方式 老的表数据 后期有需要就手动刷回去 itemsHistory)
-- itemid 1/2/3 金币、钻石、房卡
function AddItemsHistory(uid, itemId, balance, diff, desc)
	if desc == nil then
		return
	end

    local userInfo = chessuserinfodb.RUserInfoGet(uid)
	local history = {
        _id         = go.newObjectId(),
        uid 		= uid,						-- 玩家id
        itemid 		= itemId,					-- 物品id
        balance		= balance,					-- 当前余额
        diff		= diff,						-- 变化值
        timestamp	= os.time(),				-- 当前操作时间
        time 		= chessutil.FormatDateGet(),-- 格式化时间
        desc 		= desc,						-- 操作描述
        chipsWithdraw = userInfo.status.chipsWithdraw, --提现金额
        totalRechargeChips = userInfo.property.totalRechargeChips, --充值金额
        canCovertChips = WithdrawCash.GetWithdrawcashInfo(uid).cancovertchips, --可兑换额度
		table='newItemsHistory'
	}

    if unilight.getdebuglevel() > 0 then
        unilight.savedatasyn(TABLE_NAME, history)
    else
        go.logRpc.SaveLogData(json.encode(encode_repair(history)))
    end
end

-- 获取指定物品的变动历史(暂时默认取最新的100条)
function GetItemsHistory(uid, itemId)
	local filter 	= unilight.a(unilight.eq("uid", uid), unilight.eq("itemid", itemId))
	local orderby 	= unilight.desc("timestamp")
	local limit 	= 100
	local historys 	= unilight.topdata(TABLE_NAME, 100, orderby, filter)
	
	-- 多余数据不发送
	for i,v in ipairs(historys) do
		v.uid = nil
		v.time= nil
	end
	return historys
end
