--游戏通用变量定义
module('gamecommon', package.seeall)

--游戏请求类型
GAME_OPRATE = {
    BASE          = 1,               --基础玩法
    FREE_EXTRA    = 2,               --免费玩法之前的附加(选择玩法，或者确定次数)
    FREE          = 3,               --免费玩法
    SFREE_EXTRA   = 4,               --超级免费玩法之前的附加(选择玩法，或者确定次数)
    SFREE         = 5,               --超级免费玩法
    RESPIN_EXTRA  = 6,               --respin玩法之前的附加(选择玩法，或者确定次数)
    RESPIN        = 7,               --respin玩法
    BONUS_EXTRA   = 8,               --bonus玩法之前的附加(选择玩法，或者确定次数)
    BONUS         = 9,               --bonus玩法
    COLLECT_EXTRA = 10,              --collect触发的玩法之前的附加(选择玩法，或者确定次数)
    COLLECT       = 11,              --collect触发的玩法
    JACKPOT_EXTRA = 12,              --jackpot玩法之前的附加(选择玩法，或者确定次数)
    JACKPOT       = 13,              --jackpot玩法
}

--gm状态信息
gmInfo = {
    free    = 0,    --是否触发免费
    respin  = 0,    --是否触发respin
    collect = 0,    --是否触发收集
    sfree   = 0,    --是否触发超级免费
    bonus   = 0,    --是否触发bonus
    jackpot = 0,    --是否角发jackpot
}
