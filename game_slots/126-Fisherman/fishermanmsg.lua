-- 玩家购买免费
Net.CmdFishermanBuyFreeCmd_C= function(cmd, laccount)
    Fisherman.CmdBuyFree(laccount.Id,cmd.data)
end