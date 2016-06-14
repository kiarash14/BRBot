package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  ..';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require("./bot/utils")

local f = assert(io.popen('/usr/bin/git describe --tags', 'r'))
VERSION = assert(f:read('*a'))
f:close()

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then
    return
  end

  msg = backward_msg_format(msg)

  local receiver = get_receiver(msg)
  print(receiver)
  --vardump(msg)
  --vardump(msg)
  msg = pre_process_service_msg(msg)
  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      match_plugins(msg)
      if redis:get("bot:markread") then
        if redis:get("bot:markread") == "on" then
          mark_read(receiver, ok_cb, false)
        end
      end
    end
  end
end

function ok_cb(extra, success, result)

end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)
  -- See plugins/isup.lua as an example for cron

  _config = load_config()

  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
  if msg.out then
    print('\27[36mNot valid: msg from us\27[39m')
    return false
  end

  -- Before bot was started
  if msg.date < os.time() - 5 then
    print('\27[36mNot valid: old msg\27[39m')
    return false
  end

  if msg.unread == 0 then
    print('\27[36mNot valid: readed\27[39m')
    return false
  end

  if not msg.to.id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.from.id == our_id then
    print('\27[36mNot valid: Msg from our id\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.id == 777000 then
    --send_large_msg(*group id*, msg.text) *login code will be sent to GroupID*
    return false
  end

  return true
end

--
function pre_process_service_msg(msg)
   if msg.service then
      local action = msg.action or {type=""}
      -- Double ! to discriminate of normal actions
      msg.text = "!!tgservice " .. action.type

      -- wipe the data to allow the bot to read service messages
      if msg.out then
         msg.out = false
      end
      if msg.from.id == our_id then
         msg.from.id = 0
      end
   end
   return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      print('Preprocess', name)
      msg = plugin.pre_process(msg)
    end
  end
  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        local warning = 'Plugin '..disabled_plugin..' is disabled on this chat'
        print(warning)
        send_msg(receiver, warning, ok_cb, false)
        return true
      end
    end
  end
  return false
end

function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

  -- Go over patterns. If one matches it's enough.
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      print("msg matches: ", pattern)

      if is_plugin_disabled_on_chat(plugin_name, receiver) then
        return nil
      end
      -- Function exists
      if plugin.run then
        -- If plugin is for privileged users only
        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(receiver, result)
          end
        end
      end
      -- One patterns matches
      return
    end
  end
end

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
  send_large_msg(destination, text)
end

-- Save the content of _config to config.lua
function save_config( )
  serialize_to_file(_config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config( )
  local f = io.open('./data/config.lua', "r")
  -- If config.lua doesn't exist
  if not f then
    print ("Created new config file: data/config.lua")
    create_config()
  else
    f:close()
  end
  local config = loadfile ("./data/config.lua")()
  for v,user in pairs(config.sudo_users) do
    print("Sudo user: " .. user)
  end
  return config
end

-- Create a basic config.json file and saves it.
function create_config( )
  -- A simple config with basic plugins and ourselves as privileged user
  config = {
    enabled_plugins = {
    "plugins",
    "antiSpam",
    "antiArabic",
    "banhammer",
    "broadcast",
    "inv",
    "password",
    "welcome",
    "toSupport",
    "me",
    "toStciker_By_Reply",
    "invSudo_Super",
    "invSudo",
    "cpu",
    "badword",
    "aparat",
    "calculator",
    "antiRejoin",
    "pmLoad",
    "inSudo",
    "blackPlus",
    "toSticker(Text_to_stick)",
    "toPhoto_By_Reply",
    "inPm",
    "autoleave_Super",
    "black",
    "terminal",
    "sudoers",
    "time",
    "tophoto",
    "toPhoto_Txt_img",
    "tosticker",
    "toVoice",
    "ver",
    "start",
    "whitelist",
    "inSuper",
    "inRealm",
    "onservice",
    "inGroups",
    "updater",
    "qrCode",
    "inAdmin",
    "antitag",
    "calc-fa",
    "fantasty_writter",
    "filterword",
    "Id",
    "info",
    "lock_ads",
    "time2",
    "Wai",
    "weather",
    "rmsg",
    "salam-s",
    "addp",
    "bye.s",
    "sticker_maker",
    "number"

    },
    sudo_users = {139328010},--Sudo users
    moderation = {data = 'data/moderation.json'},
    about_text = [[ 👽 ｂ ｏ ｕ ｋ ａ ｎ   ｒ ｏ ｂ ｏ ｔ 👽  ]],
    help_text_realm = [[
💙لیست دستورات ریلم💙

#creategroup [Name]
🔹ساخت گروه

#createrealm [Name]
🔹ساخت ریلم

#setname [Name]
🔹تعویض اسم

#setabout [group|sgroup] [GroupID] [Text]
🔹در باره گروه

#setrules [GroupID] [Text]
🔹گذاشتن قوانین

#lock [GroupID] [setting]
🔹قفل کردن تنظیمات

#unlock [GroupID] [setting]
🔹باز کردن تنظیمات

#settings [group|sgroup] [GroupID]
🔹تنظیمات

#wholist
🔹درباره ریلم یا گروه

#who
🔹نشان دادن تعداد افراد داخل گروه یا ریلم

#type
🔹ست کردن تایپ

#addadmin [id|username]
🔹افزودن ادمین(فقط توسط سودو)

#removeadmin [id|username]
🔹رمیو کردن ادمین (توسط سودو)

#list groups
🔹لیست گروه ها

#list realms
🔹لیست ریلم ها 

#support
🔹ساپورت
#-support
🔹ساپورت-

#log
🔹بازگشت به عقب

#broadcast [text]
#broadcast Hello !
🔹نشان دادن آل گروپ

شما میتونید از علامت های
/ و ! و #
استفاده کنید👌😂

Final Version @BoukanRobot
Channel : @BRBot_Channel
👤 Sudo User : https://telegram.me/ZakariaR 👤
]],
    help_text = [[
💙لیست دستورات💙

`!kick [username|id]`
🔹حذف شخص از گروه 

`!ban [ username|id]`
🔹حذف و محروم کردن شخص از گروه 

`!unban [id]`
🔹محرومیت شخص را بر طرف کردن

!who
🔹درباره یک شخص 

!modlist
🔹لیست مدیران

`!promote [username]`
🔹افزودن مدیر

!demote [username]
🔹حذف شخص از مدیریت

!kickme
🔹حذف خود از گروه

!about
🔹درباره گروه

!setphoto
🔹تعویض عکس گروه

!setname [name]
🔹تعویض اسم گروه

!rules
🔹قوانین

!id
🔹درباره خود

!help
🔹راهنما ربات

`!lock` `[links|flood|spam|Arabic|member|rtl|sticker|contacts|strict]`
🔹قفل کردن
🔸[لینک|حساسیت|اسپم|عربی|ممبر|RTL|استیکر|مخاطب]

`!unlock` `[links|flood|spam|Arabic|member|rtl|sticker|contacts|strict]`
🔹باز کردن 
🔸[لینک|حساسیت|اسپم|عربی|ممبر|RTL|استیکر|مخاطب]

`!mute [all|audio|gifs|photo|video]`
🔹ساکت کردن
🔸[همه|صدا|گیف|عکس|ویدیو]

`!unmute [all|audio|gifs|photo|video]`
🔹ازاد کردن ساکتی
🔸[همه|صدا|گیف|عکس|ویدیو]

!set rules <text>
🔹گذاشتن قوانین گروه

!set about <text>
🔹گذاشتن در باره گروه

!settings
🔹تنظیمات گروه

!muteslist
🔹لیست ساکت شده ها

`!muteuser [username]`
🔹ساکت کردن یک شخص

!mutelist
🔹لیست افراد ساکت شده

!newlink
🔹ساخت لینک جدید

!link
🔹لینک گروه

!owner
🔹صاحب گروه

!setowner [id]
🔹انتخاب صاحب گروه

!setflood [value]
🔹گذاشتن حساسیت اسپم

!save [value] <text>
🔹سیو کردن

!get [value]
🔹برگشت به عقب

!clean [modlist|rules|about]
🔹پاک کردن
🔸[لیست مدیران|قوانین|درباره گروه]

!res [username]
🔹مشخصات یک شخص

!banlist
🔹لیست افراد محروم

شما میتونید از علامت های
/ و ! و #
استفاده کنید👌😂

Final Version @BoukanRobot
Channel : @BRBot_Channel
👤 Sudo User : https://telegram.me/ZakariaR 👤
]],
	help_text_super =[[
💙 لیست دستورات سوپر گروه💙

!info
🔹مشخصات خود

!admins
🔹ادمین ها

!owner
🔹صاحب گروه

!modlist
🔹لیست مدیران

!bots
🔹ربات های گروه

!who
🔹مشخصات یک شخص

`!block`
🔹حذف شخص از گروه و گذاشتن در لیست مسدودین

`!ban`
🔹حذف شخص و محروم کردن 

`!unban`
🔹از بین بردن محرومیت شخص

!id
🔹مشخصات خود

!kickme
🔹حذف خود از گروه

!setowner
🔹معرفی صاحب گروه به ربات

`!promote [username|id]`
🔹ارتقا دادن یک شخص

`!demote [username|id]`
🔹برکنار کردن یک شخص

!setname
🔹تعویض اسم گروه

!setphoto
🔹تعویض عکس گروه

!setrules
🔹گذاشتن قوانین

!setabout
🔹گذاشتن درباره گروه

!newlink
🔹ساخت لینک جدید(باید گروه مال خود ربات باشد)

!link
🔹لینک

!rules
🔹قوانین

`!lock` `[links|flood|spam|Arabic|member|rtl|sticker|contacts|strict]`
🔹قفل کردن
🔸[لینک|حساسیت|اسپم|ممبر|RTL|استیکر|مخاطب]

`!unlock` `[links|flood|spam|Arabic|member|rtl|sticker|contacts|strict]`
🔹باز کردن
🔸[لینک|حساسیت|اسپم|ممبر|RTL|استیکر|مخاطب]

`!mute [all|audio|gifs|photo|video|service]`
🔹ساکت کردن
🔸[همه|صدا|گیف|عکس|ویدیو]

`!unmute [all|audio|gifs|photo|video|service]`
🔹با صدا کردن
🔸[همه|صدا|گیف|عکس|ویدیو]

!setflood [value]
🔹حساسیت

!settings
🔹تنظیمات 

!muteslist
🔹لیست ساکت شده ها

`!muteuser [username]`
🔹ساکت کردن یک شخص

!mutelist
🔹لیست اشخاص ساکت شده

!banlist
🔹لیست افراد محروم شده

`!clean [rules|about|modlist|mutelist]`
🔹پاک کردن
🔸[قوانین|مدیران|اشخاص ساکت شده]

!del
🔹حذف یک پیغام

شما میتونید از علامت های
/ و ! و #
استفاده کنید👌😂

Final Version @BoukanRobot
Channel :@BRBot_Channel
👤 Sudo User : https://telegram.me/ZakariaR 👤
]],
  }
  serialize_to_file(config, './data/config.lua')
  print('saved config into ./data/config.lua')
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)
  --vardump (chat)
end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

-- Enable plugins in config.json
function load_plugins()
  for k, v in pairs(_config.enabled_plugins) do
    print("Loading plugin", v)

    local ok, err =  pcall(function()
      local t = loadfile("plugins/"..v..'.lua')()
      plugins[v] = t
    end)

    if not ok then
      print('\27[31mError loading plugin '..v..'\27[39m')
	  print(tostring(io.popen("lua plugins/"..v..".lua"):read('*all')))
      print('\27[31m'..err..'\27[39m')
    end

  end
end

-- custom add
function load_data(filename)

	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)

	return data

end

function save_data(filename, data)

	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()

end


-- Call and postpone execution for cron plugins
function cron_plugins()

  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end

  -- Called again in 2 mins
  postpone (cron_plugins, false, 120)
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false
