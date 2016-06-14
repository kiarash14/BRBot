do

function run(msg, matches)
  return [[ B O U K A N   R O B O T
-----------------------------------
A new bot for manage your SuperGroups.
-----------------------------------
@BRBot_Channel #Channel
-----------------------------------
@ZakariaR #Developer
-----------------------------------
@BoukanRobot #Bot
-----------------------------------
Bot version : 7.9]]
end
return {
  description = ".", 
  usage = "use black command",
  patterns = {
    "^/BoukanRobot$",
    "^!BoukanRobot$",
    "^%BoukanRobot$",
    "^$BoukanRobot$",
   "^#BoukanRobot$",
   "^#BoukanRobot",
   "^/boukanrobot$",
   "^#BoukanRobot$",

  },
  run = run
}
end
