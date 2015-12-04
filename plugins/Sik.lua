local function sik_user(user_id, chat_id)
  local chat = 'chat#id'..chat_id
  local user = 'user#id'..user_id
  chat_del_user(chat, user, ok_cb, true)
end

local function siktir_user(user_id, chat_id)
  -- Save to redis
  local hash =  'siktired:'..chat_id..':'..user_id
  redis:set(hash, true)
  -- sik from chat
  sik_user(user_id, chat_id)
end

local function siktirbaw_user(user_id)
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

local function unsiktirbaw_user(user_id)
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
      if banned then
        print('User is siktired!')
        kick_user(user_id, msg.to.id)
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
      print('siktireded user talking!')
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
   local text = ' هیشکی با یوزر @'..member..' نیس تا دکمه سکتیرشو بزنم  '
   for k,v in pairs(result.members) do
      vusername = v.username
      if vusername == member then
      	member_username = member
      	member_id = v.id
		if member_id == our_id then return false end
      	if get_cmd == 'sik' then
      		      	          	    send_large_msg(receiver, 'حاجیمون @'..member..' ['..member_id..'] سیک کیک کرد')

      	    return sik_user(member_id, chat_id)
      	          	    send_large_msg(receiver, 'حاجیمون @'..member..' ['..member_id..'] خودش سیک  کرد')
      	elseif get_cmd == 'siktir' then
      	    send_large_msg(receiver, 'حاجیمون @'..member..' ['..member_id..'] دکمه سیکتیرشو زدم')
      	    return ban_user(member_id, chat_id)
      	elseif get_cmd == 'unsiktir' then
      	    send_large_msg(receiver, 'حاجیمون @'..member..' ['..member_id..'] از سیکتیری در اومد')
      	    local hash =  'siktired:'..chat_id..':'..member_id
			redis:del(hash)
			return ' حاجیمون  '..user_id..' از سیکتیری در اومد'
      	elseif get_cmd == 'siktirbaw' then
      	    send_large_msg(receiver, 'حاجیمون @'..member..' ['..member_id..'] از سوپر سیکتیر در اومد')
      	    return siktirbaw_user(member_id, chat_id)
		elseif get_cmd == 'unsiktirbaw' then
      	    send_large_msg(receiver, 'حاجیمون @'..member..' ['..member_id..'] از سوپر سیکتیر در اومد')
      	    return unsiktirbaw_user(member_id, chat_id)
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
		return '  حاجیمون '..user_id..' دکمه سیکیرشو زدم  '   
    end
  end
  if matches[1] == 'unsiktir' then
    local chat_id = msg.to.id
	if msg.to.type == 'chat' then
		if string.match(matches[2], '^%d+$') then
		    local user_id = matches[2]
			local hash =  'siktired:'..chat_id..':'..user_id
			redis:del(hash)
			return '  حاجیمون   '..user_id..' از سیکتیری در اومد  '   
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
	if matches[1] == 'siktirbaw' then
		local user_id = matches[2]
		local chat_id = msg.to.id
		if msg.to.type == 'chat' then
			if string.match(matches[2], '^%d+$') then
				if matches[2] == our_id then return false end
				siktirbaw_user(user_id)
			return 'حاجیمون '..user_id..' سوپر سیکتیر کرد'
			else
				local member = string.gsub(matches[2], '@', '')
				local get_cmd = 'siktirbaw'
				chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
			end
		end
   end
   if matches[1] == 'unsiktirbaw' then
		local user_id = matches[2]
		local chat_id = msg.to.id
		if msg.to.type == 'chat' then
			if string.match(matches[2], '^%d+$') then
				if matches[2] == our_id then return false end
				unsiktirbaw_user(user_id)
			return '  حاجیمون  '..user_id..'  از سیکتیری بیرون اومد'  
			else
				local member = string.gsub(matches[2], '@', '')
				local get_cmd = 'unsiktirbaw'
				chat_info(receiver, username_id, {get_cmd=get_cmd, receiver=receiver, chat_id=msg.to.id, member=member})
			end
		end
   end

end

return {
  description = "Plugin to manage bans and kicks.",
  patterns = {
    "^!(sik) (.*)$",
    "^/(siktirbaw) (.*)$",
        "^!(siktirbaw) (.*)$",
    "^!(siktir) (.*)$",
    "^/(siktir) (.*)$",
    "^!(unsiktir) (.*)$",
    "^/(unsiktir) (.*)$",
	"^/(unsiktirbaw) (.*)$",
    "^!(sik) (.*)$",
    "^/(sik) (.*)$",
	"^/(sikme)$",
    "^!(sikme)$",
    "^!!tgservice (.+)$",
  },
  run = run,
  pre_process = pre_process
}
