module('storecatch',package.seeall)
--缓存管理包
local storecatch={}  --table,field
-- storecatch['userinfo'] = {}
local storepath={}
local isUseCatch = true

tableMap={
    [101] = 'game101goldenunicorn',
    [102] = 'game102truck',
    [103] = 'game103happypumpkin',
    [104] = 'game104MayanMiracle',
    [105] = 'game105beautydisco',
    [106] = 'game106mariachi',
    [107] = 'game107football',
    [108] = 'game108fruitparadise',
    [109] = 'game109cash',
    [110] = 'game110cleopatra',
    [111] = 'game111orchardcarnival',
    [112] = 'game112ninelineslegend',
    [113] = 'game113fivedragons',
    [114] = 'game114fruitmachine',
    [115] = 'game115avatares',
    [116] = 'game116avatares',
    [117] = 'game117firecombo',
    [118] = 'game118chilli',
    [119] = 'game119luckyseven',
    [121] = 'game121cleopatra',
    [122] = 'game122apollo',
    [123] = 'game123corpse',
    [124] = 'game124adventurous',
    [125] = 'game125rockgame',
    [126] = 'game126fisherman',
    [127] = 'game127tiger',
    [129] = 'game129candytouch',
    [131] = 'game131goldcow',
    [132] = 'game132rabbit',
    [133] = 'game133mouse',
    [134] = 'game134dragon',
    [135] = 'game135seven',
    [136] = 'game136dragon',
    [137] = 'game137elephant',
    [138] = 'game138moneytree',
    [139] = 'game139dragontriger',
    [140] = 'game140moneyPig',
    [141] = 'game141ghost',
    [142] = 'game142luckstar',
    [143] = 'game143marry',
    [144] = 'game144penguin',
    [145] = 'game145animal',
    [146] = 'game146tiger',
    [147] = 'game147redpanda',
    [148] = 'game148leopard',
    [149] = 'game149goldcow',
    [150] = 'game150rabbit',
    [151] = 'game151cashwheel',
    [152] = 'game152tiger',
    [153] = 'game153rabbit',
    [154] = 'game154goldcow',
}
local dnameMap={
['game101goldenunicorn'] = 1,
['game102truck'] = 1,
['game103happypumpkin'] = 1,
['game104MayanMiracle'] = 1,
['game105beautydisco'] = 1,
['game106mariachi'] = 1,
['game107football'] = 1,
['game108fruitparadise'] = 1,
['game109cash'] = 1,
['game110cleopatra'] = 1,
['game111orchardcarnival'] = 1,
['game112ninelineslegend'] = 1,
['game113fivedragons'] = 1,
['game114fruitmachine'] = 1,
['game115avatares'] = 1,
['game116avatares'] = 1,
['game117firecombo'] = 1,
['game118chilli'] = 1,
['game119luckyseven'] = 1,
['game121cleopatra'] = 1,
['game122apollo'] = 1,
['game123corpse'] = 1,
['game124adventurous'] = 1,
['game125rockgame'] = 1,
['game126fisherman'] = 1,
['game127tiger'] = 1,
['game129candytouch'] = 1,
['game130fortunegem'] = 1,
['game131goldcow']= 1,
['game132rabbit'] = 1,
['game133mouse'] = 1,
['game134dragon'] = 1,
['game135seven'] = 1,
['game136dragon'] =1,
['game137elephant'] = 1,
['game138moneytree'] = 1,
['game139dragontriger'] = 1,
['game140moneyPig'] = 1,
['game141ghost'] = 1,
['game142luckstar'] = 1,
['game143marry'] = 1,
['game144penguin'] = 1,
['game145animal'] = 1,
['game146tiger'] = 1,
['game147redpanda'] = 1,
['game148leopard'] = 1,
['game149goldcow'] = 1,
['game150rabbit'] = 1,
['game151cashwheel'] = 1,
['game152tiger'] = 1,
['game153rabbit'] =1,
['game154goldcow'] = 1,
['withdrawcash'] = 1,
-- ['userinfo'] = 1,
}

local exceptionTable={
    ['withdrawcash'] = 1
}
-- name uid
local gamedataCatch={}
local isDebug = unilight.getdebuglevel()
--保存数据
function Save(name,data,force)
    if dnameMap[name]==nil or isUseCatch==false then
        return false
    end
    if go.gamezone.Gameid ~= Const.GAME_TYPE.SLOTS then
        return false
    end
    storecatch[name] =storecatch[name] or {}
    storecatch[name][data._id] = data
    if force then
        return false
    end
    return true
end
function Get(name,key)
    if isUseCatch==false then
        return nil
    end
    if go.gamezone.Gameid ~= Const.GAME_TYPE.SLOTS then
        return nil
    end
    if dnameMap[name]==nil then
       return nil
    end
    local data = storecatch[name]
    if data~=nil then
        return data[key]
    end
    return nil
end
function Update(name,id,args,force)
    if isUseCatch==false then
        return false
    end
    if go.gamezone.Gameid ~= Const.GAME_TYPE.SLOTS then
        return false
    end
    if dnameMap[name]==nil then
        return false
     end
    local data = storecatch[name] or {}
    -- print('data[id]~=nil')
    data[id] = args
    storecatch[name] = data
    if force then
        return false
    end
    return true
end
--玩家离开缓存处理
function LeaveEvent(uid)
    if isUseCatch==false then
        return
    end
    if go.gamezone.Gameid ~= Const.GAME_TYPE.SLOTS then
        return
    end
    for table_name,value in pairs(storecatch) do
        local data = value[uid]
        if data~=nil then
            -- local r = unilight.get_mongodb().SaveCollectionById(table_name, encode_repair(data))
            unilight.savedata(table_name, data, nil, true )
            storecatch[table_name][uid] = nil
        end
    end
end
function ClearStore(uid)
    if go.gamezone.Gameid ~= Const.GAME_TYPE.SLOTS then
        return
    end
    for table_name,value in pairs(storecatch) do
        if exceptionTable[table_name]==nil then
            local data = value[uid]
            if data~=nil then
                -- local r = unilight.get_mongodb().SaveCollectionById(table_name, encode_repair(data))
                storecatch[table_name][uid] = nil
            end
        end
    end
end
--刷新立即保存缓存
function FlushCatchToDb()
    for table_name,value in pairs(storecatch) do
        for uid,data in pairs(value) do
            data.autoInsertTime = os.time()
            local r = unilight.get_mongodb().SaveCollectionById(table_name, encode_repair(data))
            -- unilight.savedata(table_name, data)
            unilight.clearMongoCatch(uid)
        end
    end
end
