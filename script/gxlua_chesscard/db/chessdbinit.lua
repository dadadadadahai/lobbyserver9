module("ChessDbInit", package.seeall)
isNotStatistics = true
-- 全局的数据库相关初始化  针对单独游戏的 则各自初始化 
function Init()
    if unilight.getgameid() ~= Const.GAME_TYPE.LOBBY then
        unilight.info("不在大厅，不初始化数据库创建索引相关")
        return
    end
	-- 基础信息
	local startAgentSystem = go.getconfigint("start_agent")
	if go.getconfigint("isNotStatistics") == 0 then
		isNotStatistics = false
	end
	unilight.createdb("userinfo","uid")						-- 玩家个人信息
	unilight.createindex("userinfo", "uid")	                -- 角色id
	-- unilight.createindex("userinfo", "property.chips")		-- 玩家筹码添加索引
	unilight.createindex("userinfo", "status.logintime")	-- 玩家最近登录时间添加索引
	unilight.createindex("userinfo", "base.platid")	        -- 平台索引
	unilight.createindex("userinfo", "property.totalRechargeChips")	        -- 平台索引
	unilight.createindex("userinfo", "property.vipLevel")	        -- 平台索引
	unilight.createindex("userinfo", "base.regFlag")	        -- 平台索引
	-- unilight.createindex("userinfo", "status.registertimestamp")	        -- 平台索引
	unilight.createindex("userinfo", "base.phoneNbr")	        -- 平台索引
	unilight.createindex("userinfo", "status.logintimestamp")	        -- 平台索引
	unilight.createindex("userinfo", "property.presentChips")	        -- 平台索引
	unilight.createindex("userinfo", "base.inviteCode")	        -- 平台索引
	unilight.createindex("userinfo", "base.plataccount")	        -- 平台索引




	unilight.createdb("globalroomid", "_id") 				-- 只用于递增 获取全局唯一房间id
	-- unilight.createdb("globalroomdata", "globalroomid")		-- 通过全局唯一房间id 索引该房间游戏数据 一经创建 就不销毁
    unilight.createdb("globalinvitecode", "_id")            -- 唯一邀请码
	-- 统计相关
	-- unilight.createdb("userprofitbet", "_id")				-- 玩家筹码统计
	-- unilight.createdb("userprofitbet_day", "_id")				-- 玩家筹码天为单位统计
	unilight.createdb("userOnlineTimes", "uid")				-- 在线时长统计
	-- unilight.createdb("userprofitbonus", "_id")				-- 统计玩家彩金收益 
    --邮件
	unilight.createdb("usermailinfo", "_id")				-- 玩家邮件 
	unilight.createdb("globalemailid", "_id")				-- 邮件全局 
	unilight.createdb("globalmailinfo", "_id")				-- 邮件全局信息 

	-- unilight.createdb("roundid", "_id")						-- 单纯记录牌局id 全局唯一、
	-- 大厅系统相关
	unilight.createdb("daysign", "_id")						-- 每日签到
	-- unilight.createdb("userbackpack", "_id") 				-- 记录玩家的背包
	unilight.createdb("usertaskinfo", "_id") 				-- 记录玩家已完成的任务列表
	unilight.createdb("useractivityinfo", "_id") 			-- 记录玩家已完成的活动列表	
	unilight.createdb("daystaskinfo", "_id")			    -- 记录玩家每日任务信息
	-- unilight.createdb("taskseven", "_id")			        -- 玩家七日任务
	-- unilight.createdb("bankruptcy", "uid")					-- 记录玩家破产补助信息
	-- unilight.createdb("turntable", "uid")					-- 记录玩家转盘相关信息
	-- unilight.createdb("rankinfo", "_id")					-- 记录大厅排行榜信息
	-- unilight.createdb("giftcoupon", "uid")					-- 记录奖券相关信息
	-- unilight.createdb("userLevel","_id")					-- 玩家等级模块  (byx)
	unilight.createdb("userset", "_id")						-- 用户设置
	unilight.createdb("rechargeinfo", "_id")				-- 充值信息记录
	unilight.createindex('rechargeinfo','firstBuyTime')	--首充时间
	-- unilight.createdb("teaminfo","_id")					--团队数据库
	-- unilight.createdb("teamchart","_id")				--团队聊天记录id
	-- unilight.createindex("teamchart","teamid")				--团队聊天记录,创建团队id索引
	-- unilight.createdb("friendinfo","_id")				--好友模块相关
	-- unilight.createdb("usercollect","_id")				--收集模块
	-- unilight.createdb("usercollecthistory","_id")		--收集模块历史
	-- unilight.createdb("usercollectshop","_id")				--收集商城模块
	-- unilight.createdb("lottery","_id")						--彩票模块相关
	-- unilight.createdb("grandPrize","_id")					--彩票模块相关
	-- unilight.createdb('clubinfo','_id')						--俱乐部模块
	-- unilight.createdb('cookinginfo','_id')					--创建烹饪模块
	-- unilight.createdb("benefits","_id")						-- 救济金模块
	-- unilight.createdb("catchfish","_id")					-- 捕鱼模块
	-- unilight.createdb("bingoinfo","_id")					-- 宾果模块	
	-- unilight.createdb("centerdice","_id")					-- 个人中心小游戏模块	
    unilight.createdb("slotiap","_id")						--slot内购（有时间限制的buff类）
	unilight.createdb("slotiapnum","_id")					--slot内购（消耗品的道具类）
	unilight.createdb("global","_id")						--全局定义表
	-- unilight.createdb("scoreboard","_id")						--积分榜模块
	-- unilight.createdb("weeklycard","_id")					--金银周卡
	-- unilight.createdb("weeklycard_history","_id")			--金银周卡
	-- unilight.createdb("roulette","_id")						--世界杯轮盘
	-- unilight.createdb("roulette_history","_id")				--世界杯轮盘

		-- 运营活动
    -- unilight.createdb("systemCoupon","_id")					-- 优惠券模块
    -- unilight.createdb("nado","_id")							-- Nado机器模块
	-- unilight.createdb("operateswitch", "opAcId")			-- 运营活动开关 通过运营活动id（opAcId） 索引
	-- unilight.createdb("operaterecord", "_id")				-- 运营活动 所有奖励记录
	-- unilight.createdb("luckyturntable", "uid")				-- 幸运转盘 通过uid 索引 指定玩家 数据
	-- unilight.createdb("rankinfolist","moduleid")				--记录排行榜信息 模块id
	-- unilight.createdb("activitysale", "_id")				--玩家的活动特卖信息


	-- 转账相关
	-- unilight.createdb("lobbyExchange", "exchangeorder") 	-- 转账功能
	unilight.createdb("lobbyUserRedPaper", "userId") 		-- 玩家发出去的红包
	unilight.createdb("lobbyUserRecvRedPaper", "userId") 	-- 玩家领取的红包

	-- 红包相关
	unilight.createdb("publuckmoney", "_id")				-- 公共红包 数据表名
	unilight.createindex("publuckmoney", "uidSend")			-- 公共红包 uidSend字段创建索引
	unilight.createdb("rcvpubluckmoney", "uid")				-- 存储该玩家领取过的红包记录

    -- 房间相关
	chessroominfodb.InitRoomInfoDb(go.gamezone.Gameid)

	-- 处罚相关
	unilight.createdb("userpunishinfos", "charid")			-- 玩家处罚信息(为了兼容协议内容  使用charid 代替 uid)
	unilight.createdb("punishinfos", "taskid")				-- 处罚信息汇总

	-- 开奖控制相关
	-- unilight.createdb("blackwhitelist", "id")				-- 黑白名单信息  id为主键  id改为服务器自己自增唯一
	-- unilight.createdb("protectinfo", "key")					-- 保庄/玩家信息  通过gameId .. "-" .. uid .."-" .. type 为主键
	-- unilight.createdb("blackwhiteid", "_id")				-- 黑白名单信息  

	-- 兑换提现相关
	unilight.createdb("withdrawcash", "_id")				-- 兑换提现整体数据表 玩家ID主键
	unilight.createdb("withdrawcashhistory", "_id")			-- 兑换提现历史记录数据表 玩家ID主键
	unilight.createindex('withdrawcash','cpf')				--建立cpf索引
	unilight.createdb("withdrawcash_order", "_id")			-- 兑换提现订单数据表 自增长主键
	unilight.createindex("withdrawcash_order", "state")		-- 索引
	unilight.createindex("withdrawcash_order", "uid")		-- 索引
	unilight.createindex("withdrawcash_order", "timestamp")		-- 索引
	unilight.createindex("withdrawcash_order", "finishTimes")		-- 索引
	unilight.createindex("withdrawcash_order", "regFlag")		-- 索引
	unilight.createindex("withdrawcash_order", "regTime")		-- 索引



	-- 上下分异常报警记录
	-- unilight.createdb("updownchipswarn", "uid")				-- 上下分异常记录 uid为索引

	-- 物品变动历史
	--unilight.createdb("itemsHistory", "uid")				-- 变动历史 uid为索引
	unilight.createdb("newItemsHistory", "_id")				-- 新变动历史 老的废了 _id为索引
	unilight.createindex("newItemsHistory", "uid")			-- 用户字段索引
	unilight.createindex("newItemsHistory", "timestamp")	-- 用户字段索引

	unilight.createdb("gameMatchLog", "_id")			    -- 游戏记录表
	unilight.createindex("gameMatchLog", "uid")			    -- 用户字段索引
	unilight.createindex("gameMatchLog", "sTime")			-- 时间字段索引
	unilight.createindex("gameMatchLog", "eTime")			-- 时间字段索引
	unilight.createindex("gameMatchLog", "gameType")		-- 时间字段索引
	unilight.createindex("gameMatchLog", "gameId")		-- 时间字段索引



	unilight.createdb("gameInOutLog", "_id")			    -- 进出日志
	unilight.createindex("gameInOutLog", "uid")			    -- 用户字段索引
	unilight.createindex("gameInOutLog", "beginTime")	    -- 时间字段索引
    unilight.createindex("gameInOutLog", "endTime")		    -- 时间字段索引

	unilight.createdb("rechargeWithdrawLog", "_id")			    -- 进出日志
	unilight.createindex("rechargeWithdrawLog", "uid")			    -- 用户字段索引
    unilight.createindex("rechargeWithdrawLog", "timestamp")		    -- 时间字段索引
    unilight.createindex("rechargeWithdrawLog", "opType")		    -- 时间字段索引

	unilight.createdb("gameDayStatistics", "_id")			    -- 进出日志
	unilight.createindex("gameDayStatistics", "gameId")			    -- 用户字段索引
	unilight.createindex("gameDayStatistics", "gameType")			    -- 用户字段索引
	unilight.createindex("gameDayStatistics", "daytimestamp")			    -- 用户字段索引
	unilight.createindex("gameDayStatistics", "classType")			    -- 用户字段索引
	unilight.createindex("gameDayStatistics", "keyval")			    -- 用户字段索引
	unilight.createindex("gameDayStatistics", "type")			    -- 用户字段索引




	-- unilight.createdb("slotsStock", "_id")			    	-- slots库存信息
	-- unilight.createindex("slotsStock", "_id")			    -- 用户字段索引
	-- unilight.createdb("slotsStockLog", "_id")			    	-- slots库存日志
	-- unilight.createindex("slotsStockLog", "gameId")			    -- 用户字段索引
	-- unilight.createindex("slotsStockLog", "gameType")			-- 用户字段索引
	-- unilight.createindex("slotsStockLog", "daytimestamp")		-- 用户字段索引

	unilight.createdb("exclusiveRewardLog", "_id")			    -- 专属奖励日志
	unilight.createindex("exclusiveRewardLog", "uid")			-- 用户字段索引
	unilight.createindex("exclusiveRewardLog", "globalId")		-- 用户字段索引
	unilight.createindex("exclusiveRewardLog", "rewardId")		-- 用户字段索引
	unilight.createindex("exclusiveRewardLog", "timestamp")		-- 用户字段索引
	unilight.createindex("exclusiveRewardLog", "isGet")			-- 用户字段索引

	unilight.createdb("orderinfo", "_id")			    -- 订单
	unilight.createindex("orderinfo", "status")			-- 用户字段索引
	unilight.createindex("orderinfo", "subTime")		-- 用户字段索引
	unilight.createindex("orderinfo", "subPrice")		-- 用户字段索引
	unilight.createindex("orderinfo", "backTime")		-- 用户字段索引
	unilight.createindex("orderinfo", "regFlag")		-- 用户字段索引
	unilight.createindex("orderinfo", "regTime")		-- 用户字段索引



	--子游戏相关
    --[[
	unilight.createdb("game101moonwolf","_id")						--创建月亮狼数据记录
	unilight.createdb("game106westcowboy","_id")						--创建牛仔数据记录
	unilight.createdb('game115thanksgiving','_id')				--感恩节
	unilight.createdb('game111goldchile','_id')				--金辣椒
	unilight.createdb('game105miner','_id')					--矿工
	unilight.createdb('game116magicorb','_id')					--小蜜蜂
	unilight.createdb('game234fortunecat','_id')					--摇钱树
	unilight.createdb('game218apollo','_id')					--阿波罗
	unilight.createdb('game302VolcanoFury','_id')					--火山
	unilight.createdb('game226fencingcat','_id')					--招财猫
	unilight.createdb('game224tarzanfight','_id')					--人猿泰山
	unilight.createdb('game268championfish','_id')					--鱼
	unilight.createdb('game210Themysteryofatlantis','_id')			--亚特兰蒂斯
	unilight.createdb('game267LuxuryCasino','_id')			--赌场
	unilight.createdb('game270clownw','_id')			--小丑
	unilight.createdb('game216GoblinTreasure','_id')			--地精
	unilight.createdb('game251WizardofOz','_id')			--绿野仙踪
	unilight.createdb('game259MONSTERCASTLE','_id')			--吸血鬼
	unilight.createdb('game203MAGICPOT','_id')			--吸血鬼

	unilight.createdb("game102caribbingo","_id")			--海盗

	unilight.createdb("game104chili","_id")					--辣椒
	unilight.createdb("game108easter","_id")				--复活节
	unilight.createdb("game114godthunder","_id")			--雷神
	unilight.createdb("game114magicalhat","_id")			--神奇的帽子
	unilight.createdb("game113mermaid","_id")				--美人鱼
	unilight.createdb("game225flowerfairy","_id")			--花仙子
	unilight.createdb("game107fortunetree","_id")			--摇钱树
	unilight.createdb("game212tigerbless","_id")			--太极虎
	unilight.createdb("game253medusa","_id")			    --美杜莎
	unilight.createdb("game261labmonster","_id")			--科学怪人
	unilight.createdb("game260thanksgivingday","_id")		--感恩节

	

	unilight.createdb("game103aladdin","_id")				--创建阿拉丁游戏数据
	unilight.createdb("game117spartacus","_id")				--创建斯巴达游戏数据
	unilight.createdb("game222seapower","_id")				--创建海王游戏数据
	unilight.createdb("game228grandelephant","_id")			--创建史诗大象游戏数据
	unilight.createdb("game235zeus","_id")					--创建宙斯游戏数据
	unilight.createdb("game269egyptianwheel","_id")			--创建埃及轮盘游戏数据
	unilight.createdb("game217coinfever","_id")				--创建聚宝盆游戏数据
	unilight.createdb("game307frostyqueen","_id")			--创建冰雪女王游戏数据

	unilight.createdb("game109holloween","_id")				--创建万圣节
	unilight.createdb("game118moneyHoney","_id")			--创建爱丽丝
	unilight.createdb("game213treasurehunt","_id")			--创建海盗寻宝
	unilight.createdb("game215mysteryveil","_id")			--创建神秘面莎
	unilight.createdb("game213roaringbuffalo","_id")		--创建咆哮的野牛
	unilight.createdb("game311greatepypt","_id")			--神秘的埃及
	unilight.createdb("game306magicfeast","_id")			--魔法盛宴
	unilight.createdb("game281wolfgold","_id")				--白头鹰
    ]]
	
	unilight.createdb('game102truck','_id')					-- 102 疯狂大卡车
	unilight.createdb('game104MayanMiracle','_id')			-- 104 玛雅
	unilight.createdb('game107football','_id')				-- 107 足球
	unilight.createdb('game108fruitparadise','_id')			-- 108 水果天堂
	unilight.createdb('game201penaltykick','_id')			-- 201 点球大战
	unilight.createdb('game111orchardcarnival','_id')		-- 111 果园狂欢
	unilight.createdb('game112ninelineslegend','_id')		-- 112 九线传奇
	unilight.createdb('game113fivedragons','_id')			-- 113 五龙争霸
	unilight.createdb('game114fruitmachine','_id')			-- 114 水果机器
	unilight.createdb('game115avatares','_id')				-- 115 阿凡达
	unilight.createdb('game116avatares','_id')				-- 116 幸运转盘
	unilight.createdb('game117firecombo','_id')				-- 117 火焰连击
	unilight.createdb('game119luckyseven','_id')			-- 119 幸运七
	unilight.createdb('game122apollo','_id')				-- 122 阿波罗
	unilight.createdb('game121cleopatra','_id')				-- 121 新宙斯	
	unilight.createdb('game124adventurous','_id')			-- 124 冒险精神
	unilight.createdb('game126fisherman','_id')				-- 126 渔夫
	unilight.createdb('game125rockgame','_id')				-- 125 宝石
	unilight.createdb('game127tiger','_id')					-- 127 老虎
	unilight.createdb('game129candytouch','_id')			-- 129 糖果连连碰
	unilight.createdb('game130fortunegem','_id')			-- 130 财富宝石
	unilight.createdb('game131goldcow','_id')				-- 131 十倍金牛
	unilight.createdb('game132rabbit','_id')				-- 132 兔子
	unilight.createdb('game133mouse','_id')					-- 133 老鼠
	unilight.createdb('game135seven','_id')					-- 135 生肖龙
	unilight.createdb('game137elephant','_id')				-- 137 大象
	unilight.createdb('game136dragon','_id')				-- 136探龙
	unilight.createdb('game138moneytree','_id')				-- 138
	unilight.createdb('game139dragontriger','_id')				-- 139龙虎slots
	unilight.createdb('game140moneyPig','_id')				-- 140 金钱猪
	unilight.createdb('game141ghost','_id')				-- 141 亡灵
	unilight.createdb('game142luckstar','_id')				-- 141 亡灵
	unilight.createdb('game143marry','_id')				-- 143 结婚
	unilight.createdb('game144penguin','_id')				-- 144 企鹅
	unilight.createdb('game146tiger','_id')					-- 146 新老虎
	unilight.createdb('game147redpanda','_id')				-- 147 小熊猫
	unilight.createdb('game148leopard','_id')				-- 148 豹子
	unilight.createdb('game149goldcow','_id')				-- 149 新金牛
	unilight.createdb('game150rabbit','_id')				-- 150 新兔子
	unilight.createdb('game153rabbit','_id')				-- 153 新兔子
	unilight.createdb('game145animal','_id')				-- 145 动物
	unilight.createdb('game151cashwheel','_id')				-- 151 现金转轮
	unilight.createdb('game152tiger','_id')					-- 152 老虎3
	unilight.createdb('game154goldcow','_id')				-- 154 牛3
	unilight.createdb('game155mouse','_id')					-- 155 老鼠2
	
	--双王之战(神像)
	
	-- unilight.createdb("godStatueInfo","_id")                --双王之战神像信息
	-- unilight.createdb("pickGameInfo","_id")					--pickGame游戏数据
	--探索长期
	-- unilight.createdb("userQuestInfo","_id")				--长期探索

	--挑战
	-- unilight.createdb("challengeUserInfo","_id")			--挑战玩家数据
	-- unilight.createdb("pearlUserInfo","_id")				--珍珠挑战游戏
	-- unilight.createdb("diceUserInfo","_id")					--骰子挑战游戏
	--大厅快捷页
	-- unilight.createdb("hallGameInfo","_id")					--大厅游戏
	-- unilight.createdb("hallUserInfo","_id")					--大厅游戏个人数据

	--byx
	--新vip功能
	unilight.createdb('nVip','_id')				--新vip功能
	unilight.createdb('nviplog','_id')			--新vip日志
	unilight.createdb('cofrinho','_id')			--存钱罐
	unilight.createdb('benefit','_id')			--救济金模块
	--游戏
	unilight.createdb('game101goldenunicorn','_id')		--黄金独角兽
	unilight.createdb('game103happypumpkin','_id')		--快乐南瓜
	unilight.createdb('game105beautydisco','_id')		--美女迪斯科
	unilight.createdb('game106mariachi','_id')		--墨西哥流浪乐队
	unilight.createdb('game109cash','_id')		--终极现金
	unilight.createdb('game118chilli','_id')	--辣椒
	unilight.createdb('game110cleopatra','_id')		--埃及艳后
	unilight.createdb('game123corpse','_id')		--僵尸
	
    --游戏jackpot相关
	unilight.createdb('gamejackpothistory','_id')		--slot游戏jackpot历史记录
	unilight.createindex("gamejackpothistory","_id")
	unilight.createdb("jackpotstock","_id")			-- 奖池金额
	--[[
		游戏押注抽水相关
	]]
	unilight.createdb('gameBetPumpInfo','_id')		--游戏押注抽水相关
	unilight.createindex("gameBetPumpInfo", "daytimestamp")			    -- 用户字段索引
    unilight.createindex("gameBetPumpInfo", "gameType")		    -- 时间字段索引
	unilight.createindex('gameBetPumpInfo','taxPercent')

	unilight.createdb('gameDayChipsStatisicLog','daytimestamp')		--游戏每日货币日志统计
	unilight.createindex("gameDayChipsStatisicLog", "daytimestamp")	-- 用户字段索引

	unilight.createdb('DayRechargeStatistic','dayNum')		--每日复充数据
	unilight.createindex("DayRechargeStatistic", "dayNum")	-- 用户字段索引

    --其它任务
	unilight.createdb('taskother','uid')		--每日复充数据

    --jackpot日志
	unilight.createdb('gameJackpotLog','_id')		--游戏每日货币日志统计
	unilight.createindex("gameJackpotLog", "uid")	-- 用户字段索引
	unilight.createindex("gameJackpotLog", "gameId")	-- 用户字段索引
	unilight.createindex("gameJackpotLog", "gameType")	-- 用户字段索引
	unilight.createindex("gameJackpotLog", "timestamp")	-- 用户字段索引
    --玩家上传图片
	unilight.createdb('user_image_upload','_id')		--玩家上传日志
	unilight.createindex('user_image_upload','timestamp')	--索引
	unilight.createindex('user_image_upload','status')		--索引
	--玩家上传app
	unilight.createdb('user_image_addDesktop','_id')		--玩家上传日志
	unilight.createindex('user_image_addDesktop','timestamp')	--索引
	unilight.createindex('user_image_addDesktop','status')		--索引
	
	-- 推广
	unilight.createdb('extension_relation','_id')			-- 推广上下级信息
	unilight.createdb('flowing_final','_id')				-- 推广流水

	unilight.createdb('nchiplog','_id')				-- 推广流水
	unilight.createindex('nchiplog','uid')			--金币日志加上索引
    --返利日志
	unilight.createdb('rebateItem','_id')		
	unilight.createindex('rebateItem','uid')	--索引

	unilight.createdb('rebatelog','_id')		
	unilight.createindex('rebatelog','parentid')	--索引

    --有效玩家奖励
	unilight.createdb('validinvite','_id')		
	unilight.createindex('validinvite','uid')	--索引
	unilight.createdb('validinvitelog','_id')		
	unilight.createindex('validinvitelog','uid')	--索引
	unilight.createindex('validinvitelog','addTime')	--索引
	unilight.createindex('validinvitelog','type')	--索引


    --有效玩家奖励
	unilight.createdb('maillog','_id')		
    --有效玩家奖励
	unilight.createdb('cumulativerecharge','_id')		

	--红包雨
	unilight.createdb('redrain','_id')
	unilight.createdb('redraingetlog','_id')
	unilight.createdb('redraingrantlog','_id')
	--每日下注统计
	unilight.createdb('daybetmoney','_id')
	--任务转盘
	unilight.createdb('taskturntable','_id')
	unilight.createdb('taskturntablelog','_id')
	--邀请转盘
	unilight.createdb('inviteroulette','_id')
	unilight.createdb('inviteroulettelog','_id')
	--邀请转盘电话号码
	unilight.createdb('phonenumber','_id')
	--损失返利
	unilight.createdb('lossrebate','_id')
	unilight.createdb('lossrebatelog','_id')
	--新任务
	unilight.createdb('ntask','_id')
	unilight.createdb('ntasklog','_id')
	--兑换码
	unilight.createdb('redeemcode','_id')
	--兑换码记录
	unilight.createdb('redeemcodelog','_id')
	--幸运玩家
	unilight.createdb('luckyplayerlog','_id')
	--徽章等级
	unilight.createdb('badgelog','_id')
	--通用活动日志
	unilight.createdb('generalactivitielog','_id')
end
