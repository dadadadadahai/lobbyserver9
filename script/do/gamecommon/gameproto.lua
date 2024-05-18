--游戏通用变量定义
module('gamecommon', package.seeall)

--服务器启动完后注册网络消息
function RegGameNetCommand()
    --辣椒游戏
  --  GameChili.RegisterProto()
  local gameArrayOj={
    'goldenunicorn','happypumpkin','beautydisco','mariachi','CrazyTruck','MayanMiracle',
	'Football','FruitParadise','cash','cleopatra','cacaNiQuEls','PenaltyKick','OrchardCarnival',
	'NineLinesLegend','FiveDragons','FruitMachine','Avatares','LuckyWheel','miner','FireCombo',
	'LuckySeven','chilli','cleopatraNew','Apollo','corpse','AdventurousSpirit','Fisherman',
	'rockgame','Tiger','Tiger3','CandyTouch','FortuneGem','GoldCow','Rabbit','Mouse','Dragon',
	'Seven','Elephant','dragon','dragontriger','moneyPig','ghost','luckstar','moneytree','marry',
	'penguin','NewTiger','RedPanda','Leopard','NewGoldCow','NewRabbit','animal','Rabbit3','NewGoldCow3',
	'sweetBonanza',	'GreatRhinoceros',	'fruitparty2',
  }
  if unilight.getdebuglevel() > 0 then
    for _,value in ipairs(gameArrayOj) do
        local obj = _G[value]
        if obj~=nil then
          obj.RegisterProto()
        end
    end
  else
    for _,value in ipairs(gameArrayOj) do
      local obj = _G[value]
      if obj~=nil then
        if obj.GameId == subGameId then
          obj.RegisterProto()
        end
      end
    end
  end
end

