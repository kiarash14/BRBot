do

function run(msg, matches)
  return [[ B O U K A N   R O B O T +
-----------------------------------
A new bot for manage your Supergroups.
-----------------------------------
@BRBot_Channel #Channel
-----------------------------------
@ZakariaR #Developer
-----------------------------------
@BoukanRobot #Bot
-----------------------------------
Bot version : 7.9 ]]
end

return {
  description = "Shows bot version", 
  usage = "version: Shows bot version",
  patterns = {
    "^[#!/]version$",
    "^[#!/]ver"
  }, 
  run = run 
}

end
