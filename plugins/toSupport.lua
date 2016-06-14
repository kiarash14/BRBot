do

function run(msg, matches)
  return " The Support Invition Link : \n https://telegram.me/ZakariaR\n-------------------------------------\nChannel: @Zakaria_Rasoli"
  end
return {
  description = "shows support link", 
  usage = "tosupport : Return supports link",
  patterns = {
    "^[#!/]support$",
    "^/tosupport$",
    "^#tosupport$",
    "^>tosupport$",
  },
  run = run
}
end