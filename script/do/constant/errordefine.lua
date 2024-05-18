module('ErrorDefine', package.seeall)

--错误定义100以内为通用定义, 每个独立模块以100-199,200-299跨区域使用,避免冲突
SUCCESS                                 = 0         -- 成功
CHIPS_NOT_ENOUGH                        = 1         -- 币货不足
ERROR_PARAM                             = 2         -- 参数错误
ERROR_AREALIMIT                         = 3         --超过押注区域限制
BAN_LOGIN                               = 4         --账号禁止登陆
NO_RECHARGE                             = 5         -- 玩家未充值
NOT_ENOUGHTCHIPS                        = 6         --没有携带足够的金币
NOT_ENOUGHTVIPLEVEL                     = 7        --VIP等级不足
--埃及艳后新
ERROR_INFREEING                         =10121      --免费游戏中
--僵尸
ERROR_POSERROR                          = 1012301     --选择位置错误
ERROR_RECVNORMAL                        = 1012302     --无法领取普通奖励
-- 大厅轮盘模块错误码
ROULETTE_SCORE_ERROR                    = 101       -- 客户端传入参数错误 score不合法

-- 每日签到模块错误码
SIGN_VIPLEVEL_ERROR                     = 201       -- 玩家当前VIP等级不足签到需求
SIGN_FULLMAX_ERROR                      = 202       -- 当前签到次数超过总签到次数
SIGN_HAVESIGN_ERROR                     = 203       -- 今日已经签到

--vip模块错误码定义
NVIP_DAYS_RECVED                        = 300       --当日已经领取过天卡了
NVIP_WEEK_RECVED                        = 301       --本周已领取过周卡
NVIP_MOON_RECVED                        = 301       --本周已领取月卡
--存钱罐
COFRINHO_NO_GOLD                        = 400       --银色存钱罐余额不足
--救济金
BENEFIT_RECVED                          = 500       --已领取过救济金
BENEFIT_GTMIN                           = 501       --余额大于领取金额

-- 兑换提现模块错误码
WITHDRAWCASH_DINHEIRO_ERROR             = 601       -- 客户端传入参数错误 dinheiro不合法
WITHDRAWCASH_UNTETHEREDPHONE_ERROR      = 602       -- 未绑定手机号
WITHDRAWCASH_NOCPF_ERROR				= 603       -- 未绑定CPF
WITHDRAWCASH_NAMEFORMAT_ERROR			= 604       -- NAME格式不合法
WITHDRAWCASH_CPFFORMAT_ERROR			= 605       -- CPF格式不合法
WITHDRAWCASH_PHONEFORMAT_ERROR			= 606       -- PHONE格式不合法
WITHDRAWCASH_EMAILFORMAT_ERROR			= 607       -- EMAIL格式不合法
WITHDRAWCASH_REPEATCPF_ERROR			= 608       -- 重复绑定
WITHDRAWCASH_REGISTERED_ERROR			= 609       -- 已经有人绑定过

WITHDRAWCASH_RESIDUALNUM_ERROR			= 610       -- 剩余次数不足
WITHDRAWCASH_QUOTA_ERROR			    = 611       -- 剩余可提现的额度不足
WITHDRAWCASH_MINDINHEIRO_ERROR			= 612       -- 低于最少提现金额
WITHDRAWCASH_REFRESHTIME_ERROR			= 613       -- 提现冷却时间未到
WITHDRAWCASH_NOLOGINAPK_ERROR			= 614       -- 未在apk登陆过
WITHDRAWCASH_NORECHARGE_ERROR			= 615       -- 未充值


--个人中心错误码
CENTER_FREQUENTLY_VERIFY                = 701       --获取手机验证码太频繁
CENTER_DUPLICATE_BIND                   = 702       --重复绑定
CENTER_ERROR_VERIFY                     = 703       --错误的验证码
CENTER_OLD_PHONE_NOT_VERIFY             = 704       --旧手机没有验证
CENTER_DUPLICATE_DAY                    = 705       --一天只能修改一次
CENTER_PHONE_EMPLTY                     = 706       --手机号码不能为空
CENTER_SMS_SERVER_SHUTDOWN              = 707       --短信服务器未开
CENTER_SMS_NOT_SEND                     = 708       --未发送验证验证
CENTER_ACCOUNT_PASSWD_EMPTY             = 709       --手机号码或密码不能为空
CENTER_ERROR_PASSWD_ACCOUNT             = 710       --错误的账号或密码
CENTER_ACCOUNT_NOT_FIND                 = 711       --找不到要绑定的账号
CENTER_BIND_FAILD                       = 712       --绑定失败
CENTER_PHONE_SMS_MAX                    = 713       --今日的验证码发送次数已达上限，请明日再试
CENTER_DUPLICATE_ACCOUNT                = 714       --账号已经绑定了



--老虎机错误配置
cacaNiQuEls_EnterLow                    =800    --龙虎进入小于最低值
cacaNiQuEls_enterLimit                  =801    --龙虎进入大于最大值

--gm后台相关
GM_KICK_USER                          = 901    --网络已断开
GM_BAN_USER                           = 902    --账号已被封禁

--世界杯错误信息定义
WorldCup_LTLOWBET                =1000           --低于最小押注条件
WorldCup_MAXBET                  =1001          --大于最大下注值
WorldCup_NotInBetting           =1002           --不在押注阶段
--龙虎
LongHu_LTLOWBET                =1010          --低于最小押注条件
LongHu_MAXBET                  =1011          --大于最大下注值
LongHu_NotInBetting           =1012           --不在押注阶段
LongHu_OnlyArea             =1013       --在其他区域已经下注了
--火箭
Rocket_ExCeedBet                =1020       --超过押注范围
Rocket_NotInBetting             =1021       --不在下注阶段
Rocket_Beted                    =1022       --已经下过注了
Rocket_LTLOWBET                =1023          --低于最小押注条件
Rocket_NotInSettle              =1024       --不在结算阶段
Rocket_NotBet               =1025       --没有下注
Rocket_Settled              =1026       --已下注过了
--国王王后
KingQueen_LTLOWBET                =1030          --低于最小押注条件
KingQueen_MAXBET                  =1031          --大于最大下注值
KingQueen_NotInBetting           =1032           --不在押注阶段
KingQueen_OnlyArea             =1033       --在其他区域已经下注了
--房间错误
RANDOM_ROOM_ERROR                       = 1101      --进入随机房间错误
GAMEID_ERROR                            = 1102      --错误的游戏ID
SERVER_SHUTDOWN                         = 1103      --服务器未开放


--扫雷游戏
MINER_SPINED                =2101           --已经进行过选择了
MINER_NOSPINED              =2102           --没有进行spin选择
MINER_INVAILD               =2103           --这个位置无效


--特鲁科
Truco_NotInTimes            =20800          --消息不在该阶段
Truco_Entered               =20801          --已经有进入消息
Truco_NoCUrPoker            =20802          --不是你的出牌时间
Truco_DealError             =20803          --出牌错误
