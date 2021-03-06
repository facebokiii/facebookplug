local function sik_user(user_id, chat_id)
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id
  chat_del_user(chat, user, ok_cb, true)
end

local function siktir_user(user_id, chat_id)
  -- Save to redis
  local hash =  'siktired:'..chat_id..':'..user_id
  redis:set(hash, true)
  -- Kick from chat
  kick_user(user_id, chat_id)
end

local function banall_user(user_id)
  local data = load_data(_config.moderation.data)
  local groups = 'groups'
  	for k,v in pairs(data[tostring(groups)]) do
		chat_id =  v
		siktir_user(user_id, chat_id)
	end
	for k,v in pairs(_config.realm) do
		chat_id = v
		siktir_user(user_id, chat_id)
    end
end

local function unbanall_user(user_id)
  local data = load_data(_config.moderation.data)
  local groups = 'groups'
  	for k,v in pairs(data[tostring(groups)]) do
		chat_id =  v
		local hash =  'siktired:'..chat_id..':'..user_id
		redis:del(hash)
	end
	for k,v in pairs(_config.realm) do
		chat_id = v
		local hash =  'siktired:'..chat_id..':'..user_id
		redis:del(hash)
    end
end

local function is_siktired(user_id, chat_id)
  local hash =  'siktired:'..chat_id..':'..user_id
  local siktired = redis:get(hash)
  return siktired or false
end

local function pre_process(msg)

  -- SERVICE MESSAGE
  if msg.action and msg.action.type then
    local action = msg.action.type
    -- Check if siktired user joins chat
    if action == 'chat_add_user' or action == 'chat_add_user_link' then
      local user_id
      if msg.action.link_issuer then
        user_id = msg.from.id
      else
	      user_id = msg.action.user.id
      end
      print('Checking invited user '..user_id)
      local siktired = is_banned(user_id, msg.to.id)
      if siktir then
        print('User is banned!')
        sik(user_id, msg.to.id)
      end
    end
    -- No further checks
    return msg
  end

  -- SIKTIRED USER TALKING
  if msg.to.type == 'chat' then
    local user_id = msg.from.id
    local chat_id = msg.to.id
    local siktired = is_siktired(user_id, chat_id)
    if siktired then
      print('siktired user talking!')
      siktir_user(user_id, chat_id)
      msg.text = ''
    end
  end

  return msg
end

local function username_id(cb_extra, success, result)
   local get_cmd = cb_extra.get_cmd
   local receiver = cb_extra.receiver
   local chat_id = cb_extra.chat_id
   local member = cb_extra.member
   local text = 'هیچکی با یوزر @'..member..' iنیس تا دکمشو بزنم
   for k,v in pairs(result.members) do
      vusername = v.username
      if vusername == member then
      	member_username = member
      	member_id = v.id
		if member_id == our_id then return false end
      	if get_cmd == 'sik' then
      	    return kick_user(member_id, chat_id)
      	elseif get_cmd == 'ban' then
      	    send_large_msg(receiver, ' حاجیمون @'..member..' ['..member_id..'] سیکید')
      	    return siktir_user(member_id, chat_id)
      	elseif get_cmd == 'unban' then
      	    send_large_msg(receiver, ' حاجیمون @'..member..' ['..member_id..'] uسیکید)
      	    local hash =  'siktired:'..chat_id..':'..member_id
			redis:del(hash)
			return 'User '..user_id..' unbanned'
      	elseif get_cmd == 'banall' then
      	    send_large_msg(receiver, 'User @'..member..' ['..member_id..'] banned')
      	    return banall_user(member_id, chat_id)
		elseif get_cmd == 'unbanall' then
      	    send_large_msg(receiver, 'User @'..member..' ['..member_id..'] unbanned')
      	    return unbanall_user(member_id, chat_id)
		end
	   end
	end
   return send_large_msg(receiver, text)
end
local function run(msg, matches)
local receiver = get_receiver(msg)
  if matches[1] == 'kickme' then
    if msg.to.type == 'chat' then
      kick_user(msg.from.id, msg.to.id)
    end
  end

  if not is_momod(msg) then
    if not is_sudo(msg) then
      return nil
    end
  end

  if matches[1] == 'siktir' then
    local chat_id = msg.to.id
    if msg.to.type == 'chat' then
		if string.match(matches[2], '^%d+$') then
			if matches[2] == our_id then return false end
			local user_id = matches[2]
			siktir_user(user_id, chat_id)
		else
	      local member = string.gsub(matches[2], '@', '')
		  local get_cmd = 'siktir'
          chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
        end
		return ' حاجیمون '..user_id..' سیکید '
    end
  end
  if matches[1] == 'unban' then
    local chat_id = msg.to.id
	if msg.to.type == 'chat' then
		if string.match(matches[2], '^%d+$') then
		    local user_id = matches[2]
			local hash =  'siktir:'..chat_id..':'..user_id
			redis:del(hash)
			return 'User '..user_id..' unbanned'
		else
	      local member = string.gsub(matches[2], '@', '')
		  local get_cmd = 'unban'
          chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
		end
	end
  end

  if matches[1] == 'sik' then
    if msg.to.type == 'chat' then
		if string.match(matches[2], '^%d+$') then
			if matches[2] == our_id then return false end
			sik_user(matches[2], msg.to.id)
		else
          local member = string.gsub(matches[2], '@', '')
		  local get_cmd = 'sik'
          chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
        end
    else
      return 'This isn\'t a chat group'
    end
  end
  if not is_admin(msg) then
	return
  end
	if matches[1] == 'banall' then
		local user_id = matches[2]
		local chat_id = msg.to.id
		if msg.to.type == 'chat' then
			if string.match(matches[2], '^%d+$') then
				if matches[2] == our_id then return false end
				banall_user(user_id)
			return 'User '..user_id..' banned'
			else
				local member = string.gsub(matches[2], '@', '')
				local get_cmd = 'banall'
				chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
			end
		end
   end
   if matches[1] == 'unbanall' then
		local user_id = matches[2]
		local chat_id = msg.to.id
		if msg.to.type == 'chat' then
			if string.match(matches[2], '^%d+$') then
				if matches[2] == our_id then return false end
				unbanall_user(user_id)
			return 'User '..user_id..' unbanned'
			else
				local member = string.gsub(matches[2], '@', '')
				local get_cmd = 'unbanall'
				chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
			end
		end
   end

end

return {
  description = "Plugin to manage bans and kicks.",
  patterns = {
    "^!(siktir) (.*)$",
    "^/(siktir) (.*)$",
    "^!(unsiktir) (.*)$",
    "^/(unsiktir) (.*)$",
    "^!!tgservice (.+)$",
  },
  run = run,
  pre_process = pre_process
}
