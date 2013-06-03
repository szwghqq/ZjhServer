-------------------------------------------------------
-- 文件名　：gaobei_diaoluo_lib.lua
-- 创建者　：lgy
-- 创建时间：2013-1-9 14：00：00
-- 文件描述：德州高倍场掉落
-------------------------------------------------------


TraceError("init gaobei_diaoluo_lib...")

if gaobei_diaoluo_lib and gaobei_diaoluo_lib.ongameover then 
	eventmgr:removeEventListener("on_game_over_event", gaobei_diaoluo_lib.ongameover)
end

if gaobei_diaoluo_lib and gaobei_diaoluo_lib.ongamebegin then 
	eventmgr:removeEventListener("game_begin_event", gaobei_diaoluo_lib.ongamebegin)
end

if gaobei_diaoluo_lib and gaobei_diaoluo_lib.on_after_user_login then 
	eventmgr:removeEventListener("h2_on_user_login", gaobei_diaoluo_lib.on_after_user_login)
end

if gaobei_diaoluo_lib and gaobei_diaoluo_lib.on_after_sub_user_login then 
	eventmgr:removeEventListener("h2_on_sub_user_login", gaobei_diaoluo_lib.on_after_sub_user_login)
end

if gaobei_diaoluo_lib and gaobei_diaoluo_lib.on_user_exit then 
	eventmgr:removeEventListener("on_user_exit", gaobei_diaoluo_lib.on_user_exit)
end

function gaobei_diaoluo_lib.on_after_sub_user_login(e)
    if(duokai_lib ~= nil) then
        local user_info = e.data.user_info;
        local parent_id = duokai_lib.get_parent_id(user_info.userId);
        if gaobei_diaoluo_lib.user_list[parent_id] ~= nil then
            gaobei_diaoluo_lib.user_list[user_info.userId] = gaobei_diaoluo_lib.user_list[parent_id];
        end
    end
end

--登录事件
function gaobei_diaoluo_lib.on_after_user_login(e)
	local user_info = e.data.userinfo;
	if user_info == nil then return end
	local user_id = user_info.userId
	if gaobei_diaoluo_lib.user_list[user_id] == nil then
		gaobei_diaoluo_lib.user_list[user_id] = {} 
		gaobei_diaoluo_lib.user_list[user_id].ontime1 = 0
		gaobei_diaoluo_lib.user_list[user_id].ontime2 = 0
  end
end

function gaobei_diaoluo_lib.on_user_exit(e)
    if e.data ~= nil and gaobei_diaoluo_lib.user_list[e.data.user_id] ~= nil then
        gaobei_diaoluo_lib.user_list[e.data.user_id] = nil;
    end
end

--有效时间返回1
function gaobei_diaoluo_lib.check_time()
	local current_time = os.time()
	if current_time < timelib.db_to_lua_time(gaobei_diaoluo_lib.CFG_START_TIME)
		or current_time > timelib.db_to_lua_time(gaobei_diaoluo_lib.CFG_END_TIME) then
		return -1
	end
	return 1
end

function gaobei_diaoluo_lib.ongamebegin(e)
		local deskno = e.data.deskno
		local deskinfo = desklist[deskno]
		if viproom_lib then
      local type_room = viproom_lib.get_room_spec_type(deskno)
      if type_room == 2 then return end
    end
		if gaobei_diaoluo_lib.check_time() ~= 1 then return end
		if deskinfo.playercount >= gaobei_diaoluo_lib.number_min then
			deskinfo.cangetitem_gaobei_diaoluo = 1
		else
			deskinfo.cangetitem_gaobei_diaoluo = nil
		end
end

function gaobei_diaoluo_lib.on_recv_panshu(buf)

  local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId
	local deskno = user_info.desk
	local deskinfo = desklist[deskno]
	if viproom_lib then
    local type_room = viproom_lib.get_room_spec_type(deskno)
    if type_room == 2 then return end
  end  
    local send_func = function(show, pan_shu, need_pan_shu)
        netlib.send(function(buf) 
            buf:writeString("GBHDPS")
            buf:writeInt(show)
            buf:writeInt(pan_shu)
            buf:writeInt(need_pan_shu)
        end, user_info.ip, user_info.port)
    end
    if(deskinfo == nil) then
        return;
    end
    if deskinfo.smallbet == 20000  then
        send_func(1, gaobei_diaoluo_lib.user_list[user_id].ontime1, gaobei_diaoluo_lib.number_for8m)
    elseif deskinfo.smallbet == 40000 then
        send_func(1, gaobei_diaoluo_lib.user_list[user_id].ontime2, gaobei_diaoluo_lib.number_for16m )
    else
        send_func(0, -1, -1)
    end
end

function gaobei_diaoluo_lib.ongameover(e)
	local user_info = e.data.user_info
	local user_id = user_info.userId
	local deskno = user_info.desk
	local deskinfo = desklist[deskno]
	if viproom_lib then
    local type_room = viproom_lib.get_room_spec_type(deskno)
    if type_room == 2 then return end
  end
	if gaobei_diaoluo_lib.check_time() ~= 1 then return end
	if not deskinfo.cangetitem_gaobei_diaoluo or deskinfo.cangetitem_gaobei_diaoluo == 0 then
		return
	end
	if deskinfo.desktype ~= 1 then
		return
	end
	--两个场次累加对应的盘数
	if deskinfo.smallbet == 20000  then
		gaobei_diaoluo_lib.user_list[user_id].ontime1 = gaobei_diaoluo_lib.user_list[user_id].ontime1 + 1
	elseif deskinfo.smallbet == 40000 then
		gaobei_diaoluo_lib.user_list[user_id].ontime2 = gaobei_diaoluo_lib.user_list[user_id].ontime2 + 1
	else
		return
    end
    --发送客户端盘数信息
    local send_func = function(pan_shu, need_pan_shu)
        netlib.send(function(buf) 
            buf:writeString("GBHDPS")
            buf:writeInt(1)  --是否显示盘数信息
            buf:writeInt(pan_shu)
            buf:writeInt(need_pan_shu)
        end, user_info.ip, user_info.port)
    end
    if deskinfo.smallbet == 20000  then
        send_func(gaobei_diaoluo_lib.user_list[user_id].ontime1, gaobei_diaoluo_lib.number_for8m)
    elseif deskinfo.smallbet == 40000 then
        send_func(gaobei_diaoluo_lib.user_list[user_id].ontime2, gaobei_diaoluo_lib.number_for16m )
    end
    if gaobei_diaoluo_lib.user_list[user_id].ontime1 >= gaobei_diaoluo_lib.number_for8m then        
		gaobei_diaoluo_lib.user_list[user_id].ontime1 = 0                
	elseif gaobei_diaoluo_lib.user_list[user_id].ontime2 >= gaobei_diaoluo_lib.number_for16m then
		gaobei_diaoluo_lib.user_list[user_id].ontime2 = 0
    else
		return
	end
	--随机奖励
	local find = 0;
	local add = 0;
	local t = os.time() + math.random(0, 10000000)
	math.randomseed(t)
	local rand = math.random(1, 10000);
	for i = 1, #gaobei_diaoluo_lib.BOX_PORBABILITY_LIST do
				add = add + gaobei_diaoluo_lib.BOX_PORBABILITY_LIST[i]
				if add >= rand then
						find = i;
					break;
				end
	end
	if find == 0 then
		return
	end

	--开始发奖
	local user_info = usermgr.GetUserById(user_id)
	--发奖
	if find > 0 then
		type_id          = gaobei_diaoluo_lib.BOX_ITEM_GIFT_ID[find][1]
		item_gift_id     = gaobei_diaoluo_lib.BOX_ITEM_GIFT_ID[find][2]
		item_number      = gaobei_diaoluo_lib.BOX_ITEM_GIFT_ID[find][3]
		--记录获得的随机事件
		gaobei_diaoluo_lib.record_chris_event_log(user_id, item_gift_id, type_id, item_number)
		if type_id == 1 or type_id == 7 then
			tex_gamepropslib.set_props_count_by_id(item_gift_id, item_number, user_info, nil)		
		elseif type_id == 2 then
			--加礼物
			gift_addgiftitem(user_info, item_gift_id, user_id, user_info.nick, 0)
		elseif type_id == 3 then
			--加汽车
			for i=1,item_number do 
			  car_match_db_lib.add_car(user_id, item_gift_id, 0);
			end
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
function gaobei_diaoluo_lib.record_chris_event_log(user_id, item_gift_id, type_id, item_number)
    if(duokai_lib ~= nil and duokai_lib.is_sub_user(user_id) == 1) then
        user_id = duokai_lib.get_parent_id(user_id);
    end
  local sql = "insert into log_gaobei_diaoluo_info(user_id,item_gift_id,type_id,item_number,sys_time) value(%d,%d,%d,%d,now());"
	sql = string.format(sql, user_id, item_gift_id, type_id, item_number)
	dblib.execute(sql,function(dt) end, user_id)
end
--命令列表
cmdHandler = 
{
    ["GBHDPS"] = gaobei_diaoluo_lib.on_recv_panshu;
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("h2_on_user_login", gaobei_diaoluo_lib.on_after_user_login)
eventmgr:addEventListener("h2_on_sub_user_login", gaobei_diaoluo_lib.on_after_sub_user_login)
eventmgr:addEventListener("game_begin_event", gaobei_diaoluo_lib.ongamebegin)
eventmgr:addEventListener("on_game_over_event", gaobei_diaoluo_lib.ongameover)
eventmgr:addEventListener("on_user_exit", gaobei_diaoluo_lib.on_user_exit)



