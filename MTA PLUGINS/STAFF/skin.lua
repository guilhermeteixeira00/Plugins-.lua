function PlayerHaveLevel( player )
  if Func == false then
    if isObjectInACLGroup ( "user." .. getAccountName(getPlayerAccount(player)), aclGetGroup("Admin")) then
      --[[ setElementModel(player, 217)
      setElementData(player, "skin",217) ]]
      setElementData(player, "blood",9999999999999999999999999999999999)
      setElementData(player, "pain",false)
      setElementData(player, "brokenbone",false)
      setElementData(player, "temperature",37)
      setElementData(player, "bleeding",0)
      setElementData(player, "thirst",100)
      setElementData(player, "food",100)
      outputChatBox("[STAFF]#FFFFFFModo Staff Ativado!",player,50,255,50,true)
      Func = true
    end
  else
    if isObjectInACLGroup ( "user." .. getAccountName(getPlayerAccount(player)), aclGetGroup("Admin")) then
      --[[ setElementModel(player, 73)
      setElementData(player, "skin",73) ]]
      setElementData(player, "blood",12000)
      setElementData(player, "pain",false)
      setElementData(player, "brokenbone",false)
      setElementData(player, "temperature",37)
      setElementData(player, "bleeding",0)
      setElementData(player, "thirst",100)
      setElementData(player, "food",100)
      outputChatBox("[STAFF]#FFFFFFModo Staff Desativado!",player,50,255,50,true)
      Func = false
    end
  end
end
addCommandHandler ("staff", PlayerHaveLevel)