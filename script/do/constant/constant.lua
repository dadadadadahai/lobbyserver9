module('Const', package.seeall)
--公共的全局变量定义

--道具类型定义
GOODS_TYPE           = {
    NORMAL                  = 1, --普通物品
    GOLD                    = 2, --金币
    GOLD_BASE               = 3, --金币基础(需要加成)
    DIAMOND                 = 4, --宝石
    GOLD_DISCOUNT_ALL       = 5, --金币所有打折物品
    GOLD_DISCOUNT_CUSTOM    = 6, --金币指定物品打折
    BUFF                    = 7, --buff类型
    RANDOM_GROUP            = 8, --随机道具组
    COLLECT                 = 9, --收集物
    RANDOM_ITEM             = 10, --随机道具id
    VIP_SCORE               = 11, --vip积分
    TASK_PASS               = 12, --任务通行证积分
    PASS_LEVEL              = 13, --通行证任务等级
    SAVINGPOT_COUPON        = 14, --存钱罐优惠券
    DIAMOND_DISCOUNT_ALL    = 15, --金币所有打折物品
    DIAMOND_DISCOUNT_CUSTOM = 16, --金币指定物品打折
    GODSTATUE_BADGE         = 17, --神像徽章道具
    CLUB_SCORE              = 19, --俱乐部分数
    CHALLENGE_DIAMO         = 20, --挑战钻石
    BUFF_CUSTOM             = 21, --手动使用buff道具
    AHEADSCORE              = 22, --假金币
    POINT                  = 23,--积分
}
 
--一些特殊的道具ID
GOODS_ID = {
    GOLD            = 1, --金币
    DIAMOND         = 2, --宝石(绿钻)
    GOLD_BASE       = 3, --金币基础值
    POINT           = 4,--积分
    PASS_TASK_POINT = 10006, --任务通行证进度
}

MONEY_TYPE_NAME = {
    [1]     = "金币",
}

--背包操作类型
PACK_OP_TYPE = {
    ADD = 1, --增加
    SUB = 2, --减少
}


--货币类型
MONEY_TYPE = {
    GOLD    = 1, --金币
    DIAMOND = 2, --钻石
}
CLUB_ADD_TYPE={
--俱乐部加分类型ID
    NORMAL          =0,         --普通类型
    GAMEROTATE      =1,--游戏中旋转
	GRADE			=2,			--升级
	CASHSLOTS		=3,			--现金老虎机
	CASHTRUN		=4,			--现金转盘
	CASHGOLD		=5,			--现金金柜
	CASHSILVER		=6,			--现金银柜
	SHOPFREEGOLD	=7,			--商城免费金币
}

--buff类型ID
BUFF_TYPE_ID = {
    PASS_POINT_DOUBLE   = 1200, --通行证积分进度翻倍
    VIP_LIMIT           = 1041, --vip时限卡状态
    PASS_CHECK          = 1042, --通行证
    DAYTASK_PASS        = 1401, --赛季任务普通通行证
    DAYTASK_PASS_DOUBLE = 1402, --赛季任务通行金币双倍奖励
}

-- 获取来源
GOODS_SOURCE_TYPE           = {
    TASK                    = 1, -- 大厅任务
    DAYSTASK                = 2, -- 大厅每日任务
    ACTIVITY                = 3, -- 大厅活动
    TURNTABLE               = 4, -- 转盘
    GAMETASK                = 5, -- 游戏内部任务
    SHOP                    = 6, -- 商城购买
    GIFTCOUPON              = 7, -- 奖券兑换
    FSTRECHARGE             = 8, -- 首充奖励
    OPERATE                 = 9, -- 运营活动
    BOX                     = 10, -- 等级开宝箱
    COLLECT_AUTO            = 11, --收集物自动兑换
    FRIENDGIVE              = 12, --赠送获得
    SAVINGPOT_PROGRESS      = 13, --存钱罐进程
    WILD_COVERT             = 14, --wild兑换
    SAVINGPOT_CONFIG_RANDOM = 15, --存钱罐配置随机
    GM_COMMAND              = 16, --GM指令获得
    CLUB                    = 17, --庄园城堡玩法
    COOKING                 = 18, --烹饪玩法
    COLLECT_SHOP            = 19, --收集物商城
    GODSTATUE               = 20, --双王之战
    ACTIVITY_SALE           = 21, --活动特卖
    QUEST                   = 22, --探索
    SCORE_BOARD             = 23, --积分榜奖励获取
    CASH_ROULETTE           = 24, --救济金现金轮盘
    CASH_TREASURE           = 25, --救济金现金宝箱
    CASH_SUPER              = 26, --救济金超级奖金
    LOTTERY                 = 27, --彩票
    NADO                    = 28, --NADO机器
    SIGN                    = 29, --签到
    SYSTEM_COUPON           = 30, --系统优惠券
    MAIL                    = 31, --邮件附件
    SHARE                   = 32, --分享奖励
    CHALLENGE               = 33, --挑战
    FISH                    = 34, --捕鱼
    MOONWOLF                = 35, --月狼
    LEVEL                   = 36, --等级
    STAMP                   = 37, --邮票
    SHOP_DAY                = 38, --商城每日奖励
    COLLECT                 = 39, --收集物奖励
    CENTERDICE              = 40, --个人中心小游戏
    TEAM                    = 41, --团队
    ROULETTE                = 42, --大厅转盘
    VIPCARD                 = 43, --vip卡立即获取
    VIPCARD_Day             = 44, --vip周卡，每日领取
    COFRINHO                = 45, --存钱罐
    BENEFIT                 = 46, --救济金
    BIND_PHONE              = 47, --绑定手机
    WITHDRAWCASH            = 48, --兑换提现
    WEEKLYCARD              = 49, --金银周卡
    RECHARGE_REWARD         = 50, --充值专属奖励
    NCHIP                   = 51, --金币返利
    VIPDAYRECV              = 52, --vip领取每日
    VIPWEEKRECV             = 53, --VIP领取每周
    VIPMONTHRECV            = 54, --VIP领取每月
    BINDACCOUNT             = 55, --绑定账号
    TASKTURNTABLE           = 56, --任务转盘
    INVITEROULETTE          = 57, --邀请转盘
    REDRAIN                 = 58, --红包雨
    BADGE                   = 59, --徽章
    NVIP                    = 60, --VIP
    SHOPGIFT                = 61, --商城优惠充值额外赠送
    BINDAPK                 = 62, --绑定APK
    NTASK                   = 63, --新任务
    CUMULATIVERECHARGE      = 64, --累计充值
    TEAMREBATE              = 65, --团队返利
    REDEEMCODE              = 66, --兑换码
    LUCKYPLAYER             = 67, --幸运玩家
    LOSSREBATE              = 68, --损失返利
    DEMOINIT               = 69, --demo游戏初始化
    RECVREBATE              =70,    --领取推广流水返利
    GOLDENUNICORN           =10101,     --黄金独角兽
    CRAZYTRUCK              =10102,     --疯狂大卡车
    HAPPYPUMPKIN            =10103,     --快乐南瓜
    MayanMiracle            =10104,     --玛雅神迹
    BEAUTYDISCO             =10105,     --美女迪斯科
    MARIACHI                =10106,     --墨西哥流浪乐队
    FOOTBALL                =10107,     --足球
    FRUITPARADISE           =10108,     --水果天堂
    CASH                    =10109,     --终极现金
    CLEOPATRA               =10110,     --埃及艳后
    ORCHARDCARNIVAL         =10111,     --果园狂欢
    NINELINESLEGEND         =10112,     --九线传奇
    FIVEDRAGONS             =10113,     --五龙争霸
    FRUITMACHINE            =10114,     --水果机器
    AVATARES                =10115,     --阿凡达
    LUCKYWHEEL              =10116,     --幸运转盘
    FIRECOMBO               =10117,     --火焰连击
    LUCKYSEVEN              =10119,     --幸运七
    CLEOPATRANEW            =10121,     --埃及艳后新
    APOLLO                  =10122,     --阿波罗
    CORPSE                  =10123,     --僵尸来袭
    ADVENTUROUSSPIRIT       =10124,     --冒险精神
    FISHERMAN               =10126,     --渔夫
    TIGER                   =10127,     --老虎
    CANDYTOUCH              =10129,     --糖果连连碰
    FORTUNEGEM              =10130,     --财富宝石
    GOLDCOW                 =10131,     --金牛
    RABBIT                  =10132,     --兔子
    MOUSE                   =10133,     --老鼠
    DRAGON                  =10134,     --生肖龙
    SEVEN                   =10135,     --777
    ELEPHANT                =10137,     --大象
    SWEETBONANZA            =10160,     --甜美的波南扎
    GREATRHINOCEROS         =10161,     --大犀牛
    FRUITPARTY2             =10162,     --水果派对2
    MASTERJOKER             =10164,     --MASTERJOKER
    Rocket                  =10202,     --火箭
    cacaNiQuEls             =10204,     --老虎机
    LongHu                  =10205,     --龙虎
    WorldCup                =10206,     --世界杯
    Miner                   =10210,     --挖地雷
    KindQueen               =10212,     --国王王后
    Chili = 10118, --辣椒
    ROCKSGAME=10125,        --宝石
    Dragon = 10136,   --龙
    dragontriger=10139,
    moneyPig=10140, --金钱猪
    ghost=10141,--亡灵
    luckstar=10142,
    moneytree=10138,
    marry=10143,
    penguin=10144,
    animal=10145,
    cashwheel=10151,  --现金转轮
}

--获取来源名字
GOODS_SOURCE_NAME = {
    [1] = "大厅任务",
    [2] = "大厅每日活动",
    [3] = "大厅活动",
    [4] = "转盘",
    [5] = "游戏内部任务",
    [6] = "商城购买",
    [7] = "奖券兑换",
    [8] = "首充奖励",
    [9] = "运营活动",
    [10] = "等级开宝箱",
    [11] = "收集重复时自动兑换",
    [12] = "赠送获得",
    [13] = "存钱罐进程",
    [14] = "wild兑换",
    [15] = "存钱罐配置随机",
    [16] = "GM指令获得",
    [17] = "庄园城堡玩法",
    [18] = "烹饪玩法",
    [19] = "收集物商城",
    [20] = "双王之战",
    [21] = "活动特卖",
    [22] = "探索",
    [23] = "积分榜奖励",
    [24] = "救济金现金轮盘",
    [25] = "救济金现金宝箱",
    [26] = "救济金超级奖金",
    [27] = "彩票",
    [28] = "NADO机器",
    [29] = "签到",
    [30] = "系统优惠券",
    [31] = "邮件附件",
    [32] = "分享邀请奖励",
    [33] = "挑战",
    [34] = "捕鱼",
    [35] = "月狼小游戏",
    [36] = "等级",
    [37] = "商城邮票",
    [38] = "商城每日奖励",
    [39] = "收集物奖励",
    [40] = "个人中心小游戏",
    [41] = '团队',
    [42] = "大厅转盘",
    [43] = 'vip周卡立即获取',
    [44] = 'vip每日领取',
    [45] = '存钱罐',
    [46] = '救济金',
    [47] = '绑定手机',
    [48] = '兑换提现失败返还',
    [49] = '金银周卡',
    [50] = '充值专属奖励',
    [51] = '分享金币返利',
    [52] = 'vip领取每日损失',
    [53] = 'vip领取每周损失',
    [54] = 'vip领取每月损失',
    [55] = '绑定账号',
    [56] = '任务转盘',
    [57] = '邀请转盘',
    [58] = '红包雨',
    [59] = '徽章',
    [60] = 'NVIP',
    [61] = '商城优惠充值额外赠送',
    [62] = '绑定APK',
    [63] = '新任务',
    [64] = '累计充值',
    [65] = '团队返利',
    [66] = '兑换码',
    [67] = '幸运玩家',
    [68] = '损失返利',
    [70] = '推广流水返利',
    [10101] = '黄金独角兽',
    [10102] = '疯狂大卡车',
    [10103] = '快乐南瓜',
    [10104] = '玛雅神迹',
    [10105] = '美女迪斯科',
    [10106] = '墨西哥流浪乐队',
    [10107] = '足球',
    [10108] = '水果老虎机',
    [10109] = '终极现金',
    [10110] = '宙斯1',
    [10111] = '果园狂欢',
    [10112] = '九线传奇',
    [10113] = '五龙争霸',
    [10114] = '水果机器',
    [10115] = '阿凡达',
    [10116] = '幸运转盘',
    [10117] = '火焰连击',
    [10119] = '幸运七',
    [10121] = '宙斯2',
    [10122] = '经典老虎机',
    [10123] = '万圣节',
    [10124] = '冒险精神',
    [10126] = '渔夫',
    [10127] = '老虎',
    [10129] = '糖果连连碰',
    [10130] = '财富宝石',
    [10131] = '金牛',
    [10132] = '兔子',
    [10133] = '老鼠',
    [10134] = '生肖龙',
    [10135] = '777',
    [10137] = '大象',
    [10160] = '甜美的波南扎',
    [10161] = '大犀牛',
    [10162] = '水果派对2',
    [10164] = 'MASTERJOKER',
    [10202] = '火箭',
    [10204] = '老虎机',
    [10205] = '龙虎斗',
    [10206] = '世界杯',
    [10210] = '挖地雷',
    [10212] = '国王王后',
    [10118] = '辣椒',
    [10125] = '宝石',
    [10136] = '龙',
    [10139] = '龙虎slots',
    [10140] = '金钱猪',
    [10141] = '亡灵',
    [10142] = '幸运星',
    [10138] = '摇钱树',
    [10143]='结婚',
    [10144] = '企鹅',
    [10145] = '动物',
    [10151]='现金转轮',
}

--任务类型
TASK_TYPE                 = {
    PLAY_COUNT            = 1, --游戏N次
    WINNING_COUNT         = 2, --中奖N次
    HIT_FREE_GAME         = 3, --中N次免费游戏
    HIT_GAME              = 4, --中N次小游戏
    HIT_BIGWIN_COUNT      = 5, --中BIGWIN N次
    HIT_FIVE_LINE_COUNT   = 6, --中5次连线N数
    HIT_PRIZE_POOL        = 7, --中N次奖池
    COLLECT_WILD_COUNT    = 8, --收集WILD图标N次
    COLLECT_BONUS_COUNT   = 9, --收集bonus图标N次
    COLLECT_SCATTER_COUNT = 10, --收集scatter图标N次
}


--商城类型
SHOP_TYPE        = {
    GOLD         = 1, --金币
    DIAMOND      = 2, --宝石
    DAILY        = 3, --每日礼包
    SAVINGPOT    = 4, --存钱罐
    PASS_TICKET  = 6, --通行证
    SUPERSALE    = 5, --特卖
    ACTIVITYSALE = 13, --活动特卖
}

--排行榜类型
RANK_TYPE = {
    -- FISH      = 3,        --排行榜
    -- QUEST     = 4,        --探索
    -- COOKING   = 1000,      --烹饪大师
    -- CATCHFISH = 2000,      --捕鱼
    -- BINGO     = 3000,      --宾果
    -- SCORE     = 10000,     --积分榜
    -- TEAM      = 100000,    --团队排行榜
    -- CHALLENGE = 5,         --挑战
    -- TEAMTOL   =6,           --团队总榜单
    SLOTS_WIN_CHIPS  = 7,       --slots赢取金币排行
    POOL_122_1   = 12201,     --阿波罗初级场
    POOL_122_2   = 12202,     --阿波罗中级场
    POOL_122_3   = 12203,     --阿波罗高级场
    POOL_117_1   = 11701,     --火焰连击初级场
    POOL_117_2   = 11702,     --火焰连击中级场
    POOL_117_3   = 11703,     --火焰连击高级场
    POOL_110_1   = 11001,     --宙斯击初级场
    POOL_110_2   = 11002,     --宙斯连击中级场
    POOL_110_3   = 11003,     --宙斯连击高级场
    POOL_108_1   = 10801,     --水果天堂击初级场
    POOL_108_2   = 10802,     --水果天堂中级场
    POOL_108_3   = 10803,     --水果天堂高级场

}

--排行榜
RANK           = {
    SORT_TIME  = 600, --排行榜排序存档时间
    MAX_COUNT  = 100, --排行榜保存最大长度
    SHOW_COUNT = 100, --前端显示排名长度
}

--活动特卖
GOODS_STATE = {
    CAN_BUY = 1, --可以买
    BOUGHT = 2,--已经买了
    LOCKING = 3, --上锁中
}

--邮件类型
MAIL_TYPE = {
    SYSTEM      = 1,        --系统邮件
    FRIEND      = 2;        --好友邮件
}

--邮件类型到期时间
MAIL_TIME = {
    [1] = 86400 * 7,        --1天
    [2] = 86400 * 7,        --7天
    [3] = 86400 * 14,       --14天
    [4] = 86400 * 30,       --30天
}
--buff类型
BUFF_TYPE = {
    REWARD_POOL_RETURN = 1,--奖池回赠1
    FREE_RETURN        = 2,--免费回赠2
    BIG_AWARD_RETURN   = 3,--大奖回赠3
    CASH_BACK          = 4,--保险袋4
}
--全局表对应
GLOBAL_DB_TYPE = {
    SCORE_BOARD        = 1,     -- 积分榜
    TEAMRANK           = 2,      --团队排行榜,刷新时间
    CATCHFISH          = 3,     --捕鱼
    COOKING            = 4,     --烹饪
    BINGO              = 5,     --宾果
    ONLINE             = 6,    --在线信息
    SHOP_DISCOUNT      = 7,    --充值特惠
    WEEKLY_CARD        = 8,     -- 周卡
    GAME_ONLINE        = 9,     --各游戏在线
    CUMULATIVERECHARGE = 10,    --累计充值活动配置
}
--团队互动,类型
TEAM_INTERACT_TYPE={
    SLOTS      = 1,         --玩任意slot游戏
    BUYGOOD    = 2,         --商城购买任意金币，绿钻礼包
    COLLECTION = 3,         --集齐某一类型收集物
    LOTTERY    = 4,         --彩票得八等奖及以上
}
--小游戏活动类型
SMGAME_TYPE={
    COOKING= 1,     --烹饪 1
    CATCHFISH = 2,  --捕鱼 2
    BINGO = 3,      --宾果 3
}




--封号类型
BAN_TYPE = {
    CHAT        = 1,        --禁言
    LOGOUT      = 2,        --踢下线
    ACCOUNT     = 3,        --封号
    CONTROL     = 4,        --点控
    TRACE       = 5,        --追踪
    IP          = 6,        --封ip
    IMEI        = 7,        --封设备



}

--游戏控制类型
GAME_CONTROL_TYPE = {
    FREE       = 1,        --免费游戏
    JACKPOT    = 2,        --奖池
    BONUS      = 3,        --bonus
}

GAME_CONTROL_NAME = {
    [1]       = "free",
    [2]       = "jackpot",
    [3]       = "bonus",
}

--游戏类型
SUBGAME_TYPE = {
    SLOTS       = 1,        --slots游戏
    HUNDRED     = 2,        --百人场游戏
}


--忽略消息列表, 避免频繁打印日志
IGNORE_MSG = {
    ["Cmd.GetRobotListSmd_S"] = 1,
}


--订单状态
ORDER_STATUS = {
    CREATE   = 0,         --创建订单
    PAY      = 1,         --已支付
    DELIVERY = 2,         --已发放奖励
}


--充值对应类型
RECHARGE_TYPE = {
    ["TsPay"]   = "Pix01",
    ["LePay"]   = "Pix02",
    ["SafePay"] = "Pix03",
    ["PayTest"] = "Pix10",
}



SLOTS_LIMIT_TIME = 1000         --玩家slots消息限制

--机器人请求时忽略的gameid
ROBOT_IGNORE_GAME_ID = {
    [500] = 1,          --广播忽略id
    [202] = 1,          --广播忽略id
    [205] = 1,          --广播忽略id
    [206] = 1,          --广播忽略id
    [208] = 1,          --广播忽略id
    -- [210] = 1,          --广播忽略id
}

--非分享玩家标识
SHARE_PLAYER_FLAG = {
    [""]             = 1,    --内部登陆
    ["Organic"]      = 1,    --自然用户
    ["Share"]        = 1,    --分享用户
    -- ["Unattributed"] = 3,    --facebook
}

--需要缓存redis的表
REDIS_CACHE_NAME = {
    ["userinfo"] = 1
}


--redis hash表名
REDIS_HASH_NAME = {
    USERINFO    = "userinfo",               --玩家缓存
    STOCKNUM    = "stocknum",               --库存缓存
    ONLINE_INFO = "online_info",            --在线信息
    SLOTS_POOL_INFO   = "slots_pool_info",      --slots奖池信息
    SINGLE_POOL_INFO  = "single_pool_info" ,    --单机奖池
}


--消息提示枚举
MSGTIP = {
    DEMO = 1 ,--DEMO 提示
}

