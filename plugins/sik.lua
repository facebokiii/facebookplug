local function sik_user(user_id, chat_id)
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id
  chat_del_user(chat, user, ok_cb, true)
end

local function siktir_user(user_id, chat_id)
  -- Save to redis
  local hash =  'siktired:'..chat_id..':'..user_id
  redis:set(hash, true)
  -- Sik from chat
  sik_user(user_id, chat_id)
end

local function siktirkon_user(user_id)
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

local function unsiktirkon_user(user_id)
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
      local siktired = is_siktired(user_id, msg.to.id)
      if siktired then
        print('User is siktired!')
        sik_user(user_id, msg.to.id)
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
    if banned then
      print('siktired user talking!')
      ban_user(user_id, chat_id)
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
   local text = 'کسی با یوزر @'..member..' پیدا نکردم تا دکمه سیکشو بزنم '
   for k,v in pairs(result.members) do
      vusername = v.username
      if vusername == member then
      	member_username = member
      	member_id = v.id
		if member_id == our_id then return false end
      	if get_cmd == 'sik' then
      	    return sik_user(member_id, chat_id)
      	elseif get_cmd == 'siktir' then
      	    send_large_msg(receiver, 'دکمه سیکتیر @'..member..' ['..member_id..'] زدم')
      	    return siktir_user(member_id, chat_id)
      	elseif get_cmd == 'unsiktir' then
      	    send_large_msg(receiver, 'حاجیمون @'..member..' ['..member_id..'] از سیک در اومد')
      	    local hash =  'siktired:'..chat_id..':'..member_id
			redis:del(hash)
			return 'دکمه سیکتیر '..user_id..' زدم'
      	elseif get_cmd == 'siktir' then
      	    send_large_msg(receiver, 'حاجیمون @'..member..' ['..member_id..'] سیک جهانی شد')
      	    return siktirkon_user(member_id, chat_id)
		elseif get_cmd == 'unsiktirbaw' then
      	    send_large_msg(receiver, 'حاجیمون @'..member..' ['..member_id..'] از سیک جهانی در اومد')
      	    return unsiktirkon_user(member_id, chat_id)
		end
	   end
	end
   return send_large_msg(receiver, text)
end
local function run(msg, matches)
local receiver = get_receiver(msg)
  if matches[1] == 'sikme' then
    if msg.to.type == 'chat' then
      sik_user(msg.from.id, msg.to.id)
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
		return 'دکمه سیک '..user_id..' زدم'
    end
  end
  if matches[1] == 'unsiktired' then
    local chat_id = msg.to.id
	if msg.to.type == 'chat' then
		if string.match(matches[2], '^%d+$') then
		    local user_id = matches[2]
			local hash =  'siktired:'..chat_id..':'..user_id
			redis:del(hash)
			return ' حاجیمون '..user_id..' از سیک خارج شد'
		else
	      local member = string.gsub(matches[2], '@', '')
		  local get_cmd = 'unsiktir'
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
	if matches[1] == 'siktirkon' then
		local user_id = matches[2]
		local chat_id = msg.to.id
		if msg.to.type == 'chat' then
			if string.match(matches[2], '^%d+$') then
				if matches[2] == our_id then return false end
				siktirkon_user(user_id)
			return 'دکمه سیک '..user_id..' زدم'
			else
				local member = string.gsub(matches[2], '@', '')
				local get_cmd = 'siktirkon'
				chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
			end
		end
   end
   if matches[1] == 'unsiktirkon' then
		local user_id = matches[2]
		local chat_id = msg.to.id
		if msg.to.type == 'chat' then
			if string.match(matches[2], '^%d+$') then
				if matches[2] == our_id then return false end
				unbanall_user(user_id)
			return ' حاجیمون '..user_id..' از سیک جهانی خارج شد'
			else
				local member = string.gsub(matches[2], '@', '')
				local get_cmd = 'unsiktirkon'
				chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
			end
		end
   end

end

return {
  description = "Plugin to manage bans and kicks.",
  patterns = {
    "^!(sik) (.*)$",
    "^/(siktirkon) (.*)$",
    "^/(siktirkon) (.*)$",
    "^!(siktir) (.*)$",
    "^/(siktir) (.*)$",
    "^!(unsiktir) (.*)$",
    "^/(unsiktir) (.*)$",
	"^/(unsiktirkon) (.*)$",
    "^!(sik) (.*)$",
    "^/(sik) (.*)$",
	"^/(sikme)$",
    "^!(sikme)$",
    "^!!tgservice (.+)$",
  },
  run = run,
  pre_process = pre_process
}
