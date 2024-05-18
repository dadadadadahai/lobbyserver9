-- 积分抽奖相关gm
-- 生成区
--local curdata = { time =os.time,totalbet=10*100,minbet = 5*100,curbet= 0 ,prizename = "金币",prizeid = 1,prizenum =2,prizeplayer=2,isfinish=0 }
--data = {
--	  _id  -- 编号自动生成
--	  time -- 开奖时间
	--totalbet --总投注数量
	--minbet -- 最低投注数量 
	--curbet   --已经投注数量
	--prizename --奖品名字
	--prizeid  -- 奖品ID
	--prizenum --奖品总数量
	--prizeplayer -- 中将人数量
    --isfinish --是否已经完成
--}
-- 添加积分抽奖
local function check_pldata(data)
	return data.time and data.totalbet and data.minbet and data.prizenum and data.prizeplayer and (data.minbet>=100) and (data.totalbet>=100)and (data.totalbet>=data.minbet)
end



GmSvr.PmdAddPointLotteryGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	if cmd.data == nil or cmd.data.data == nil then
		unilight.error("添加积分抽奖 数据 有误")
		res.data.retcode = 1
		res.data.retdesc = "添加积分抽奖 数据 有误"
		return res
	end
	if not check_pldata(cmd.data.data)  then
		unilight.error("添加积分抽奖 数据 有误")
		res.data.retcode = 1
		res.data.retdesc = "添加积分抽奖 数据 有误"
		return res
	end

	-- 添加积分抽奖(data repeated)
	local ret, desc, data = PointLotteryMgr.AddPointLottery(cmd.data.data)

	res.data.retcode 	= ret
	res.data.retdesc	= desc
	res.data.data 		= data
	return res
end

-- 修改
GmSvr.PmdModPointLotteryGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	if cmd.data == nil or cmd.data.data == nil or cmd.data.data.charid == nil then
		unilight.error("修改积分抽奖 数据 有误")
		res.data.retcode = 1
		res.data.retdesc = "修改积分抽奖 数据 有误"
		return res
	end

	-- 修改积分抽奖
	local ret, desc = PointLotteryMgr.ModPointLottery(cmd.data.data)

	res.data.retcode = ret
	res.data.retdesc = desc
	return res
end

-- 删除积分抽奖
GmSvr.PmdDelPointLotteryGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	if cmd.data == nil or cmd.data.ids == nil then
		unilight.error("删除积分抽奖 数据 有误")
		res.data.retcode = 1
		res.data.retdesc = "删除积分抽奖 数据 有误"
		return res
	end

	-- 删除积分抽奖
	local ret, desc = PointLotteryMgr.DelPointLottery(cmd.data.ids)

	res.data.retcode = ret
	res.data.retdesc = desc
	return res
end

-- 查询积分抽奖
GmSvr.PmdRequestPointLotteryGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	if cmd.data == nil then
		unilight.error("查询积分抽奖 数据 有误")
		res.data.retcode = 1
		res.data.retdesc = "查询积分抽奖 数据 有误"
		return res
	end

	-- 查询积分抽奖
	local data = PointLotteryMgr.ReqPointLottery(cmd.data)

	res.data = data
	return res
end

-- 设置特殊中奖人
GmSvr.PmdAddtPointLotteryVipGmUserPmd_CS = function(cmd, laccount)
	res = cmd
	if cmd.data == nil or cmd.data.uid == nil  or cmd.data.plid == nil then
		unilight.error("设置特殊中奖人 数据 有误")
		res.data.retcode = 1
		res.data.retdesc = "设置特殊中奖人 数据 有误"
		return res
	end

	-- 查询积分抽奖
	local data = PointLotteryMgr.AddtPointLotteryVip(cmd.data)

	res.data = data
	return res
end
