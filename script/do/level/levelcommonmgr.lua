module("levelmgr", package.seeall)
Level = Level or {}
local TABLE_LEVEL = "userLevel"
function GetLevelInfo(uid)
    local level = unilight.getdata(TABLE_LEVEL,uid)
    if table.empty(level) then
        level={
            _id = uid,
            gain  =1,
            vip = 0,
            club = 0,
            rs={},
            boxindex=1,         --玩了几次宝箱游戏
            boxTime=0,
            boxs={},        
            ispaynum = 0,           --是否购买了 付费玩游戏
            sgames={},              --小游戏存档数组  {id,num,ispay,sTime,tmpresult}
            sGameId=0,            --当前小游戏的ID
        }
        
        unilight.savedata(TABLE_LEVEL,level)
    end
    return level
end
--插入新的等级游戏,返回当前小游戏id
Level.InsertNewSmallGame =function (levelinfo)
    local id = 0
    while true do
        id = id+1
        local isBreak = true
        for _, value in ipairs(levelinfo.sgames) do
            if value.id == id then
                isBreak = true
                break
            end
        end
        if isBreak then
            break
        end
    end
    levelinfo.sGameId = id
    table.insert(levelinfo.sgames, { id = id, num = 0, ispay = 0, ispaynum = 0, sTime = os.time(),tmpresult={}})
    --保存记录
    unilight.update(TABLE_LEVEL, levelinfo._id, levelinfo)
    
    return id
end
--条件成立返回邮件入口
Level.SendSGameMail =function (levelinfo,sGameId)
    local Table_MailInfo = import 'table/table_mail_config'
    --发送邮件入口
    local mailConfig = Table_MailInfo[18]
    --发送邮件处理
    local mailInfo = {}
    mailInfo.charid = levelinfo._id
    mailInfo.subject = 'LEVEL RUSH GAME'
    mailInfo.content = 'Play and get your rewards!'
    mailInfo.type = 0
    mailInfo.attachment = {}
    mailInfo.extData = {configId = mailConfig.ID,sGameId = sGameId}
    ChessGmMailMgr.AddGlobalMail(mailInfo)
end
--查询并返回小游戏对象
Level.GetSGame = function (levelinfo,sGameId)
    for index, value in ipairs(levelinfo.sgames) do
        if value.id == sGameId then
            return value
        end
    end
    return {}
end
--删除小游戏
Level.DelSGame =function (levelinfo,sGameId)
    for index, value in ipairs(levelinfo.sgames) do
        if value.id == sGameId then
            table.remove(levelinfo.sgames,index)
            unilight.update(TABLE_LEVEL,levelinfo._id,levelinfo)
            break
        end
    end
end
--内部调用宝箱功能函数
Level.AutoRecvBoxAwardCmd=function (index,levelInfo,nUserInfo)
    if index<=0 then
        return{}
    end
    local res={
        errno =1
    }
    local curLevel=nUserInfo.property.level
    if table.empty(levelInfo.boxs)==false  then
        local box =  levelInfo.boxs[index]
        if table.empty(box)==false and box.status == 0 and curLevel>=box.level then
            local summary ={}
            summary=BackpackMgr.GetRewardGood(nUserInfo._id,box.list.goodId, box.list.goodNum, Const.GOODS_SOURCE_TYPE.BOX,summary)
            box.status=1
            --unilight.update(Table_Name,levelInfo._id,levelInfo)
            local reward = {}
            for key, value in pairs(summary) do
                table.insert(reward,{goodId=key,goodNum=value})
            end
            res={
                errno =0,
                reward = reward,
                index = index,
            }
        end
        --判断三个宝箱是否全部领取完
        --Level.InsertNewSmallGame
        if levelInfo.boxs[1].status==1 and levelInfo.boxs[2].status==1 and levelInfo.boxs[3].status==1 then
            --初始化小游戏
            res.sGameId=Level.InsertNewSmallGame(levelInfo)
            --触发小游戏玩法
            Level.SendSGameMail(levelInfo,res.sGameId)
        end
        if res.errno ==0 then
            return res
        end
    end
    res={}
    return res
end