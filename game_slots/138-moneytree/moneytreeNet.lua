-- 玩家购买免费
Net.CmdMoneyTreeBuyFreeCmd_C= function(cmd, laccount)
    moneytree.CmdBuyFree(laccount.Id,cmd.data)
end