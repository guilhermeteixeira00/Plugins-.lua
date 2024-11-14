addEventHandler("onClientResourceStart", resourceRoot, function()
   local app_id = "1289036767604899882"
   if setDiscordApplicationID(app_id) then
      outputChatBox ( "#00FF00(DC RICH) #969696Rich #00FF00Conectado#969696 ao Servidor do #0000FFDiscord !! #969696Creditos By: #00FFFFT#00FF00e#FFFF001#FF0000x#FF00FFe#FFA5001#A020F0r#FF00FFa",255, 255, 255, true)
      setDiscordRichPresenceAsset("https://i.imgur.com/PpfITfN.png", "Te1xe1ra O Brabo !!!")
      setDiscordRichPresenceButton(1, "Entrar no Discord", "https://discord.gg/sZnuksgens")
      setDiscordRichPresenceButton(2, "Conectar ao Servidor", "mtasa://191.96.224.79:23913")
      updateRPC()
   end
end )

function updateRPC()
   local name = getPlayerName(localPlayer)
   setDiscordRichPresenceState("Players: "..#getElementsByType("player").." de 100")
   setDiscordRichPresenceDetails("Jogando Com o Nick: "..name)
end 
setTimer(updateRPC, 5000, 0)