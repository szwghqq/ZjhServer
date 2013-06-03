-------------------------------------------------------
-- 文件名　：christmas_lib.lua
-- 创建者　：lgy
-- 创建时间：2012-12-13 18：00：00
-- 文件描述：圣诞掉落
-------------------------------------------------------


TraceError("init christmas_lib...")

if christmas_lib and christmas_lib.ongameover then 
	eventmgr:removeEventListener("game_event", christmas_lib.ongameover)
end

if christmas_lib and christmas_lib.ongamebegin then 
	eventmgr:removeEventListener("game_begin_event", christmas_lib.ongamebegin)
end

--有效时间返回1
function christmas_lib.check_time()
	local current_time = os.time()
	if current_time < timelib.db_to_lua_time(christmas_lib.CFG_START_TIME)
		or current_time > timelib.db_to_lua_time(christmas_lib.CFG_END_TIME) then
		return -1
	end
	return 1
end

function christmas_lib.ongamebegin(e)
		local deskno = e.data.deskno
		local deskinfo = desklist[deskno]
		if christmas_lib.check_time() ~= 1 then return end
		if deskinfo.playercount > 4 then
			deskinfo.cangetitem = 1
		end
end

function christmas_lib.ongameover(e)
	local user_id = e.data[1].userid
	local user_info = usermgr.GetUserById(user_id)
	local deskno =user_info.desk
	local deskinfo = desklist[deskno]
	if christmas_lib.check_time() ~= 1 then return end
	if not deskinfo.cangetitem or deskinfo.cangetitem == 0 then
		return
	end
	deskinfo.cangetitem = 0
	if deskinfo.desktype ~= 1 then
		return
	end
	local user_info = usermgr.GetUserById(user_id)
	local reward_id = 0
	if deskinfo.smallbet == 1 then
		reward_id = 1
	elseif deskinfo.smallbet < 100 then
		reward_id = 2
	elseif deskinfo.smallbet < 1000 then
		reward_id = 3
	else
		reward_id = 4
	end
	--随机奖励
	local find = 0;
	local add = 0;
	local rand = math.random(1, 10000);
	for i = 1, #christmas_lib.BOX_PORBABILITY_LIST[reward_id] do
				add = add + christmas_lib.BOX_PORBABILITY_LIST[reward_id][i]
				if add >= rand then
						find = i;
					break;
				end
	end
	if find == 0 then
		return
	end

	--开始发奖
	local lucky_man = math.random(1,#e.data)
	local user_id = e.data[lucky_man].userid
	local user_info = usermgr.GetUserById(user_id)
	--发奖
	if find > 0 then
		type_id          = christmas_lib.BOX_ITEM_GIFT_ID[reward_id][find][1]
		item_gift_id     = christmas_lib.BOX_ITEM_GIFT_ID[reward_id][find][2]
		item_number      = christmas_lib.BOX_ITEM_GIFT_ID[reward_id][find][3]
		--记录获得的随机事件
		christmas_lib.record_chris_event_log(user_id, item_gift_id, type_id, item_number)
		if type_id == 1 or type_id == 7 then
			tex_gamepropslib.set_props_count_by_id(item_gift_id, item_number, user_info, nil)		
		elseif type_id == 2 then
			--加礼物
			gift_addgiftitem(user_info, item_gift_id, user_id, user_info.nick, 0)
		elseif type_id == 3 then
			--加汽车
			car_match_db_lib.add_car(user_id, item_gift_id, 0);
		end
		
		if (reward_id == 3 and find == 3) or
			(reward_id == 3 and find == 4) or
			(reward_id == 4 and find == 2) or
			(reward_id == 4 and find == 3) then
			local nick_name = string.trans_str(user_info.nick)
			local gift_name = christmas_lib.BOX_ITEM_GIFT_NAME[reward_id][find]
			local msg = "玩家幸运的获得%s"
			msg = string.format(msg, gift_name)
			tex_speakerlib.send_sys_msg( _U("恭喜")..nick_name.._U(msg))
		end
		--给所有人和旁观者发协议
		--广播给所有人
	  local sendfunc = function(buf)
	      buf:writeString("CHRISTGIFT")
	      buf:writeInt(item_gift_id)
	      buf:writeInt(item_number)
	      buf:writeByte(type_id)
	      buf:writeByte(user_info.site)
	      buf:writeString(user_info.nick)
	  end
	  netlib.broadcastdesk(sendfunc, deskno, borcastTarget.all)
	end

end

--记录日志
function christmas_lib.record_chris_event_log(user_id, item_gift_id, type_id, item_number)
  local sql = "insert into log_chris_event_info(user_id,item_gift_id,type_id,item_number,sys_time) value(%d,%d,%d,%d,now());"
	sql = string.format(sql, user_id, item_gift_id, type_id, item_number)
	dblib.execute(sql,function(dt) end, user_id)
end
--命令列表
cmdHandler = 
{
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end


eventmgr:addEventListener("game_begin_event", christmas_lib.ongamebegin)
eventmgr:addEventListener("game_event", christmas_lib.ongameover)



