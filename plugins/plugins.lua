{\rtf1\ansi\deff0\nouicompat{\fonttbl{\f0\fnil\fcharset0 Courier New;}{\f1\fnil\fcharset1 Segoe UI Symbol;}}
{\*\generator Riched20 6.3.9600}\viewkind4\uc1 
\pard\f0\fs22\lang1033 do\par
\par
-- Returns the key (index) in the config.enabled_plugins table\par
local function plugin_enabled( name )\par
  for k,v in pairs(_config.enabled_plugins) do\par
    if name == v then\par
      return k\par
    end\par
  end\par
  -- If not found\par
  return false\par
end\par
\par
-- Returns true if file exists in plugins folder\par
local function plugin_exists( name )\par
  for k,v in pairs(plugins_names()) do\par
    if name..'.lua' == v then\par
      return true\par
    end\par
  end\par
  return false\par
end\par
\par
local function list_all_plugins(only_enabled)\par
  local tmp = '\\n\\n@BoukanRobot'\par
  local text = ''\par
  local nsum = 0\par
  for k, v in pairs( plugins_names( )) do\par
    --  \f1\u10004?\f0  enabled, \f1\u10060?\f0  disabled\par
    local status = '/Disable\f1\u10147?\f0 '\par
    nsum = nsum+1\par
    nact = 0\par
    -- Check if is enabled\par
    for k2, v2 in pairs(_config.enabled_plugins) do\par
      if v == v2..'.lua' then \par
        status = '/Enable\f1\u10147?\f0 ' \par
      end\par
      nact = nact+1\par
    end\par
    if not only_enabled or status == '/Enable\f1\u10147?\f0 ' then\par
      -- get the name\par
      v = string.match (v, "(.*)%.lua")\par
      text = text..nsum..'.'..status..' '..v..' \\n'\par
    end\par
  end\par
  local text = text..'\\n\\n'..nsum..' plugins installed\\n\\n'..nact..' plugins enabled\\n\\n'..nsum-nact..' plugins disabled'..tmp\par
  return text\par
end\par
\par
local function list_plugins(only_enabled)\par
  local text = ''\par
  local nsum = 0\par
  for k, v in pairs( plugins_names( )) do\par
    --  \f1\u10004?\f0  enabled, \f1\u10060?\f0  disabled\par
    local status = '/Disable\f1\u10147?\f0 '\par
    nsum = nsum+1\par
    nact = 0\par
    -- Check if is enabled\par
    for k2, v2 in pairs(_config.enabled_plugins) do\par
      if v == v2..'.lua' then \par
        status = '/Enable\f1\u10147?\f0 ' \par
      end\par
      nact = nact+1\par
    end\par
    if not only_enabled or status == '/Enable\f1\u10147?\f0 ' then\par
      -- get the name\par
      v = string.match (v, "(.*)%.lua")\par
     -- text = text..v..'  '..status..'\\n'\par
    end\par
  end\par
  local text = text..'\\nPlugins Reloaded !\\n\\n'..nact..' plugins enabled\\n'..nsum..' plugins installed\\n\\n@BoukanRobot'\par
  return text\par
end\par
\par
local function reload_plugins( )\par
  plugins = \{\}\par
  load_plugins()\par
  return list_plugins(true)\par
end\par
\par
\par
local function enable_plugin( plugin_name )\par
  print('checking if '..plugin_name..' exists')\par
  -- Check if plugin is enabled\par
  if plugin_enabled(plugin_name) then\par
    return ''..plugin_name..' is enabled'\par
  end\par
  -- Checks if plugin exists\par
  if plugin_exists(plugin_name) then\par
    -- Add to the config table\par
    table.insert(_config.enabled_plugins, plugin_name)\par
    print(plugin_name..' added to _config table')\par
    save_config()\par
    -- Reload the plugins\par
    return reload_plugins( )\par
  else\par
    return ''..plugin_name..' does not exists'\par
  end\par
end\par
\par
local function disable_plugin( name, chat )\par
  -- Check if plugins exists\par
  if not plugin_exists(name) then\par
    return ' '..name..' does not exists'\par
  end\par
  local k = plugin_enabled(name)\par
  -- Check if plugin is enabled\par
  if not k then\par
    return ' '..name..' not enabled'\par
  end\par
  -- Disable and reload\par
  table.remove(_config.enabled_plugins, k)\par
  save_config( )\par
  return reload_plugins(true)    \par
end\par
\par
local function disable_plugin_on_chat(receiver, plugin)\par
  if not plugin_exists(plugin) then\par
    return "Plugin doesn't exists"\par
  end\par
\par
  if not _config.disabled_plugin_on_chat then\par
    _config.disabled_plugin_on_chat = \{\}\par
  end\par
\par
  if not _config.disabled_plugin_on_chat[receiver] then\par
    _config.disabled_plugin_on_chat[receiver] = \{\}\par
  end\par
\par
  _config.disabled_plugin_on_chat[receiver][plugin] = true\par
\par
  save_config()\par
  return ' '..plugin..' disabled on this chat'\par
end\par
\par
local function reenable_plugin_on_chat(receiver, plugin)\par
  if not _config.disabled_plugin_on_chat then\par
    return 'There aren\\'t any disabled plugins'\par
  end\par
\par
  if not _config.disabled_plugin_on_chat[receiver] then\par
    return 'There aren\\'t any disabled plugins for this chat'\par
  end\par
\par
  if not _config.disabled_plugin_on_chat[receiver][plugin] then\par
    return 'This plugin is not disabled'\par
  end\par
\par
  _config.disabled_plugin_on_chat[receiver][plugin] = false\par
  save_config()\par
  return ' '..plugin..' is enabled again'\par
end\par
\par
local function run(msg, matches)\par
  -- Show the available plugins \par
  if matches[1]:lower() == '!plist' and is_sudo(msg) then --after changed to moderator mode, set only sudo\par
    return list_all_plugins()\par
  end\par
\par
  -- Re-enable a plugin for this chat\par
  if matches[1] == '+' and matches[3] == 'chat' then\par
      if is_momod(msg) then\par
    local receiver = get_receiver(msg)\par
    local plugin = matches[2]\par
    print("enable "..plugin..' on this chat')\par
    return reenable_plugin_on_chat(receiver, plugin)\par
  end\par
    end\par
\par
  -- Enable a plugin\par
  if matches[1] == '+' and is_sudo(msg) then --after changed to moderator mode, set only sudo\par
      if is_momod(msg) then\par
    local plugin_name = matches[2]\par
    print("enable: "..matches[2])\par
    return enable_plugin(plugin_name)\par
  end\par
    end\par
  -- Disable a plugin on a chat\par
  if matches[1] == '-' and matches[3] == 'chat' then\par
      if is_momod(msg) then\par
    local plugin = matches[2]\par
    local receiver = get_receiver(msg)\par
    print("disable "..plugin..' on this chat')\par
    return disable_plugin_on_chat(receiver, plugin)\par
  end\par
    end\par
  -- Disable a plugin\par
  if matches[1] == '-' and is_sudo(msg) then --after changed to moderator mode, set only sudo\par
    if matches[2] == 'plug' then\par
    \tab return 'This plugin can\\'t be disabled'\par
    end\par
    print("disable: "..matches[2])\par
    return disable_plugin(matches[2])\par
  end\par
\par
  -- Reload all the plugins!\par
  if matches[1] == '*' and is_sudo(msg) then --after changed to moderator mode, set only sudo\par
    return reload_plugins(true)\par
  end\par
  if matches[1]:lower() == 'reload' and is_sudo(msg) then --after changed to moderator mode, set only sudo\par
    return reload_plugins(true)\par
  end\par
end\par
\par
return \{\par
  description = "Plugin to manage other plugins. Enable, disable or reload.", \par
  usage = \{\par
      moderator = \{\par
          "!plug disable [plugin] chat : disable plugin only this chat.",\par
          "!plug enable [plugin] chat : enable plugin only this chat.",\par
          \},\par
      sudo = \{\par
          "!plist : list all plugins.",\par
          "!pl + [plugin] : enable plugin.",\par
          "!pl - [plugin] : disable plugin.",\par
          "!pl * : reloads all plugins." \},\par
          \},\par
  patterns = \{\par
    "^!plist$",\par
    "^!pl? (+) ([%w_%.%-]+)$",\par
    "^!pl? (-) ([%w_%.%-]+)$",\par
    "^!pl? (+) ([%w_%.%-]+) (chat)",\par
    "^!pl? (-) ([%w_%.%-]+) (chat)",\par
    "^!pl? (*)$",\par
    "^[!/](reload)$"\par
    \},\par
  run = run,\par
  moderated = true, -- set to moderator mode\par
  --privileged = true\par
\}\par
\par
end\par
\par
-- By @ZakariaR\par
}
 