-- 自动生成 ./excel/G-公式参数.xlsx(table_parameter_formula)
return {

    [101] = {
        Formula = "{[1]=10038, [2]=10039, [3]=10039}",
        ID = 101,
        desc = "收集物蓝绿金对应的奖券id",
    },

    [201] = {
        Formula = "{[1]={40001,40004,40007},[2]={40002,40005,40008},[3]={40003,40006},[4]={40051,40061,40071,40081,40091}}",
        ID = 201,
        desc = "内购中buff类型对应的所有道具ID",
    },

    [301] = {
        Formula = "{[0]=150,[100]=135,[200]=120,[300]=110,[500]=100,[800]=95,[1300]=90,[3000]=85}",
        ID = 301,
        desc = "RTP系数1百分比：账号总游戏局数影响rtp",
    },

    [302] = {
        Formula = "{[30]={default=100,limit=120,lowermax=30,uppermax=50}}",
        ID = 302,
        desc = "RTP系数2百分比：最近一段时间内，账号在某个子游戏的游戏局数影响rtp",
    },

    [303] = {
        Formula = "{[1]={default=100,limit=120,lowermax=30,uppermax=50}}",
        ID = 303,
        desc = "RTP系数3百分比：充值后影响rtp",
    },

    [305] = {
        Formula = "{[0]=100,[1]=100,[2]=100,[3]=100,[4]=100,[5]=100,[6]=100,[7]=100,[8]=100,[9]=100}",
        ID = 305,
        desc = "RTP系数5百分比：账号尾号影响rtp",
    },

    [1001] = {
        Formula = "http://webapi.slotmagia7.com:8083/relation/bind/%s/%s",
        ID = 1001,
        desc = "好友邀请url",
    },

    [1002] = {
        Formula = "http://webapi.slotmagia7.com:8083/sms/send/%s/%s",
        ID = 1002,
        desc = "短信验证url",
    },

    [1003] = {
        Formula = "http://webapi.slotmagia7.com:8083/repay/repayState/%s/%s",
        ID = 1003,
        desc = "申请提现url",
    },

    [1004] = {
        Formula = "https://pay.slotsclassic11.com/collectdata/find/%s/%s",
        ID = 1004,
        desc = "查询gps_adid url",
    },

}
