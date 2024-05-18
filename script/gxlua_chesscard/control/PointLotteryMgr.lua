module("PointLotteryMgr", package.seeall)
TABLE_NAME = "pointlottery"
TABLE_VIPPL_NAME = "vippointlottery"
--local curdata = { time =1,totalbet=1000,minbet = 500,curbet= 0 ,prizename = "金币",prizeid = 1,prizenum =2,prizeplayer=2,isfinish=0 }
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
    --isfinish  --是否已经结算过 0代表没有
--}
function AddPointLottery(data)
	data.curbet = 0
	data.prizename = data.prizename or  "金币"
	data.prizeid = data.prizeid or 1
	data.isfinish = 0
	dump(data,"CreatePointLottery",10)
	unilight.savedata(TABLE_NAME, data)
	return 0, "添加积分抽奖成功", data
end


function AddtPointLotteryVip(data)
	dump(data,"AddtPointLotteryVip",10)
	unilight.savedata(TABLE_VIPPL_NAME, data)
	return 0, "添加积分抽奖VIP成功", data
end