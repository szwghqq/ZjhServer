-------------------------------------------------------
-- 文件名　：wing_lib.lua
-- 创建者　：lgy
-- 创建时间：2013-04-08 15：00：00
-- 文件描述：爵位翅膀活动
-------------------------------------------------------


TraceError("init wing_lib.lua...")

if wing_lib and wing_lib.on_user_exit then
	eventmgr:removeEventListener("on_user_exit", wing_lib.on_user_exit)
end

if wing_lib and wing_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", wing_lib.on_after_user_login);
end

if wing_lib and wing_lib.on_use_item then
	eventmgr:removeEventListener("use_item_event", wing_lib.on_use_item);
end

if wing_lib and wing_lib.on_game_over then 
	eventmgr:removeEventListener("on_game_over_event", wing_lib.on_game_over);
end

if wing_lib and wing_lib.before_open_hecheng then 
	eventmgr:removeEventListener("before_open_hecheng", wing_lib.before_open_hecheng);
end

if wing_lib and wing_lib.after_hecheng_event then 
	eventmgr:removeEventListener("after_hecheng_event", wing_lib.after_hecheng_event);
end

if wing_lib and wing_lib.restart_server then 
	eventmgr:removeEventListener("on_server_start", wing_lib.restart_server);
end

if wing_lib and wing_lib.timer then 
	eventmgr:removeEventListener("timer_second", wing_lib.timer);
end

if wing_lib and wing_lib.on_meet_event then 
	eventmgr:removeEventListener("meet_event", wing_lib.on_meet_event);
end

if wing_lib and wing_lib.bag_open_box_event then 
	eventmgr:removeEventListener("bag_open_box_event", wing_lib.bag_open_box_event);
end

-----------------------------------收到的各种事件-------------------------------------
--登录事件
function wing_lib.on_after_user_login(e)
	local user_info = e.data.userinfo;
	if user_info == nil then return end
	local user_id = user_info.userId	
	--读取爵位翅膀信息
	wing_lib_db.init_user_info(user_id)
end

--退出事件
function wing_lib.on_user_exit(e)
  local user_id = e.data.user_id
  wing_lib_db.update_exit_time(user_id)
  wing_lib.user_list[user_id] = nil
end

--重启事件
function wing_lib.restart_server(e)
  wing_lib_db.get_wing_ranklist()
end

--每分钟事件
function wing_lib.timer(e)

  --每天零点清除数据
  if wing_lib.get_time_everyday_0(e.data.time)==1 then
    for k,v in pairs (wing_lib.user_list) do
  		local user_info = usermgr.GetUserById(k)
  		--清一下内存中已下线的人的数据，并且清掉在线玩家的在线时间，盘数等
  		if user_info==nil then
  		  wing_lib.user_list[k] = nil 
  		elseif wing_lib.user_list[k] then
  		    wing_lib.user_list[k].exp_play = 0
  		    wing_lib.user_list[k].exp_item = 0
  		end
  		wing_lib_db.clear_everyday_info(k)
  		wing_lib.update_wing_info(k)
  	end
  end
  --每天凌晨2点更新数据
  if wing_lib.get_time_everyday_2(e.data.time)==1 then
    wing_lib_db.get_wing_ranklist()
  end
end

--牌局结束事件
function wing_lib.on_game_over(e)
  local user_info = e.data.user_info
	if(user_info==nil)then return end
	local user_id = user_info.userId
	local win_gold = e.data.win_gold
	local deskno = user_info.desk
	if wing_lib.user_list[user_id] == nil then return end
	local deskinfo = desklist[user_info.desk]
	if not deskinfo then return end
	if not wing_lib.cfg_exp_play[deskinfo.smallbet] then
		--TraceError("请检查配置信息，没有该桌子盲注对应奖励信息")
		return
	end
	--TraceError(wing_lib.cfg_exp_play[deskinfo.smallbet])
  wing_lib.add_exp(user_id, wing_lib.cfg_exp_play[deskinfo.smallbet], 2)
  if viproom_lib then
	  local type_room =  viproom_lib.get_room_spec_type(deskno)
	  if type_room ~= 2 then return end
	  --如果是爵位场
	  local room_level = viproom_lib.get_room_spec_level(deskno)
	  if room_level and wing_lib.BOX_ITEM_GUIZU[room_level] then
	    wing_lib.add_time_for_guizu(room_level, user_id)  
  	  return
  	end
  end
  
end

--收到使用道具（穿上翅膀，使用勋章）
function wing_lib.on_use_item(e)
  local user_id     = e.data.user_id
	local item_id        = e.data.item_id
	local user_info = usermgr.GetUserById(user_id)
	if not user_info then return end
  if item_id < tex_gamepropslib.PROPS_ID.WING1 or
     item_id > tex_gamepropslib.PROPS_ID.MEDAL then
      return
  end
  if item_id == tex_gamepropslib.PROPS_ID.MEDAL then
      --如果成长值已经满了则提示使用失败
      if wing_lib.get_need_to_level_up(user_id) == 0 then
        wing_lib.send_use_item(user_id,item_id,-2)
        return
      end
      if wing_lib.get_left_today_item_exp(user_id) == 0 then
        wing_lib.send_use_item(user_id,item_id,-3)
        return
      end   	
    	local set_count_box = function(nCount)

    	  if nCount >= 1 then
      	  local call_back = function()
      	    user_info.update_use_medal_update_db = 0
      	    --加成长值
      	    wing_lib.add_exp(user_id, wing_lib.exp_num_item, 3)
      	    --通知客户端
      	    wing_lib.send_use_item(user_id,item_id,1)
      	  end
    	  
    	    tex_gamepropslib.set_props_count_by_id(item_id, -1, user_info, call_back)
    	  else
    	    user_info.update_use_medal_update_db = 0
    	  end
  	  	
    	end
    	
    	--如果数据库锁定则返回
	    if user_info.update_use_medal_update_db == 1 then
		    return
		  end
		  --锁定数据库
    	user_info.update_use_medal_update_db = 1
    	tex_gamepropslib.get_props_count_by_id(item_id, user_info, set_count_box)	
  else
    wing_lib.dress_wing(user_id, 1)
  end
end

--收到开完宝箱
function wing_lib.bag_open_box_event(e)
  local user_id = e.data.user_id
  local box_id  = e.data.box_id
  local type_id = e.data.type_id
  local item_gift_id = e.data.item_gift_id
  local item_number = e.data.item_number

  local user_info = usermgr.GetUserById(user_id)
  local msg = "通过%s获得%s。赶紧来贵族场大比拼，领取贵族宝箱！"		
	if wing_lib.need_broadcast[box_id] and
	  wing_lib.need_broadcast[box_id][item_gift_id] and
	  wing_lib.need_broadcast[box_id][item_gift_id][1] == 1 then
  	  msg = string.format(msg,wing_lib.box_name[box_id],wing_lib.need_broadcast[box_id][item_gift_id][2])
  		tex_speakerlib.send_sys_msg( _U"恭喜"..user_info.nick.._U(msg))
	end
end

--收到打开合成面板消息，发送对应的翅膀图纸
function wing_lib.before_open_hecheng(e)
   local user_info = e.data.user_info

end


--收到合成完成的消息
function wing_lib.after_hecheng_event(e)
  local user_info = e.data.user_info
  local tz_id = e.data.tz_id
  local do_hc_count = e.data.do_hc_count
  local fail_hc_count = e.data.fail_hc_count
  if wing_lib.check_wing(tz_id) ~= 1 then return end
  --如果失败则旧翅膀保留
  if fail_hc_count == 1 and
    wing_lib.cfg_tzid_wingid[tz_id] then
      tex_gamepropslib.set_props_count_by_id(wing_lib.cfg_tzid_wingid[tz_id], 1, user_info, nil)
      --成长值清零
      if  wing_lib.get_wing_level(user_info.userId) >= 3 then
        wing_lib.user_list[user_info.userId].exp_now = 0
        wing_lib_db.update_wing_info(user_info.userId)
        wing_lib.update_wing_info(user_info.userId)
      end
      return
  end
  if fail_hc_count == 0 then
    --成功则升级
    wing_lib.level_up(user_info.userId)
    --如果成功并且为男爵以上则广播
    local nlevel = wing_lib.get_wing_level(user_info.userId)
    if nlevel >= 3 then
      local msg = "从%s晋升为%s，拥有更多贵族特权！"
      msg = string.format(msg,wing_lib.cfg_name_each_level[nlevel-1] ,wing_lib.cfg_name_each_level[nlevel])
			tex_speakerlib.send_sys_msg( _U("恭喜")..user_info.nick.._U(msg))
    end  
  end
end

--收到见面事件
function wing_lib.on_meet_event(e)
  --  e.data.subject      ： 状态改变的玩家
	--  e.data.observer     :  观察者
	--  将状态改变的玩家信息通知给观察者
	if not e.data.subject or not e.data.observer then return end
	wing_lib.send_wing(e.data.subject, e.data.observer)
end

----------------------------------------发送给客户端事件---------------------------------------
--通知客户端更新爵位信息
function wing_lib.update_wing_info(user_id)
  local user_info = usermgr.GetUserById(user_id)
  if not user_info then return end
  if not wing_lib.user_list[user_id] then return end
  local level = wing_lib.get_wing_level(user_id)
  if level == -1 then return end
  local vip_level = 0
  if viplib then
      vip_level = viplib.get_vip_level(user_info)
      --TraceError("vip_level"..vip_level)
  end
  netlib.send(function(buf)
		buf:writeString("WINGINFO")
		buf:writeInt(wing_lib.user_list[user_id].level )
		buf:writeInt(wing_lib.user_list[user_id].exp_now)
		buf:writeInt(wing_lib.cfg_exp_need_each[level])		
		buf:writeInt(wing_lib.user_list[user_id].exp_play)
		buf:writeInt(wing_lib.exp_play_everyday[level] or 200)
		buf:writeInt(wing_lib.user_list[user_id].exp_item )
		buf:writeInt(wing_lib.cfg_exp_vip_item[vip_level] or 500)
		buf:writeByte(wing_lib.user_list[user_id].dress_on )
	end, user_info.ip, user_info.port)
end

--通知客户端带翅膀的人坐下来了
function wing_lib.send_wing(from_user_info, to_user_info)
  if wing_lib.user_list[from_user_info.userId] then
    netlib.send(function(buf)
  				buf:writeString("WINGSIT")
  				buf:writeInt(from_user_info.userId)
  				buf:writeByte(wing_lib.user_list[from_user_info.userId].dress_on)
  				buf:writeInt(wing_lib.user_list[from_user_info.userId].level)
  	end, to_user_info.ip, to_user_info.port)
  end
end

--爵位排行榜
function wing_lib.send_user_history_final(user_info)
		if user_info ~= nil then
		  local num_rank = 0
			netlib.send(function(buf)
			    buf:writeString("WINGRANKLIST")
			    buf:writeInt(#wing_lib.wing_ranklist)
				for k,v in pairs(wing_lib.wing_ranklist) do
					buf:writeString(v.nick_name)
					buf:writeString(v.face)
					buf:writeInt(v.user_id)
					buf:writeInt(v.level)
          buf:writeInt(v.vip_level)
				end
					--buf:writeInt(num_rank)--名次
		  end,user_info.ip,user_info.port)
		end
end

--通知客户端
function wing_lib.send_use_item(user_id,item_id,sucess)
  local user_info = usermgr.GetUserById(user_id)
          netlib.send(function(buf)
						buf:writeString("TXOPENBOX")
								buf:writeByte(sucess)									
								buf:writeInt(item_id)
								buf:writeByte(0)
								buf:writeInt(0)
								buf:writeInt(0)	
					end, user_info.ip, user_info.port)
end

--通知客户端打了多少盘
function wing_lib.send_panshu(user_info,room_level,panshu,panshu_need)
  netlib.send(function(buf) 
      buf:writeString("WINGPS")
      buf:writeInt(room_level or 0)
      buf:writeInt(panshu or 0)
      buf:writeInt(panshu_need)
  end, user_info.ip, user_info.port)
end

--通知客户端打了多少盘
function wing_lib.send_panshu(user_info,room_level,panshu,panshu_need)
  netlib.send(function(buf) 
      buf:writeString("WINGPS")
      buf:writeInt(room_level or 0)
      buf:writeInt(panshu or 0)
      buf:writeInt(panshu_need)
  end, user_info.ip, user_info.port)
end
--通知客户端今日打牌获得成长值已到上限
function wing_lib.send_chengzhang_up(user_info)
  netlib.send(function(buf) 
      buf:writeString("WINGPLAYUP")
  end, user_info.ip, user_info.port)
end
--通知客户端他人的爵位等级
function wing_lib.send_other_winginfo(user_info,ask_userid,ask_level)
  netlib.send(function(buf) 
      buf:writeString("WINGLEVEL")
      buf:writeInt(ask_userid)
      buf:writeInt(ask_level)
  end, user_info.ip, user_info.port)
end

--通知客户端已T人结果
function wing_lib.send_kick_info(user_info,n_type)
   netlib.send(function(buf)
		buf:writeString("WINGKICK")
		buf:writeInt(n_type)
	end, user_info.ip, user_info.port)

end

--通知客户端T人toall
function wing_lib.send_kick_info_toall(deskno, kickuser)
   local deskinfo = desklist[deskno].gamedata
   local kickname = kickuser.userinfo.nick
   local faqiren = deskinfo.kickinfo.userinfo
   local kicker_name = kickuser.kicker_userinfo.nick
    for _, player in pairs(deskmgr.getplayers(deskno)) do
        --被踢人在玩，不应当收到协议
        if ( kickuser.userinfo.userId ~= player.userinfo.userId) then
            netlib.send(
                function(buf)
                    buf:writeString("WINGKICKALL")
                    buf:writeString(kickname)  --被踢人的名字
                    buf:writeString(kicker_name or "") --发起人的昵称
                end,player.userinfo.ip,player.userinfo.port)
        end
    end

    --通知被踢的人自己被踢走
    netlib.send(
      function(buf)
          buf:writeString("WINGKICKSELF")
          buf:writeString(kicker_name or "") --发起人的昵称       
      end,kickuser.userinfo.ip,kickuser.userinfo.port)


end

---------------------------------------api------------------------------------------------------
--增加成长值
function wing_lib.add_exp(user_id, exp_num, exp_type)
  if not wing_lib.user_list[user_id] then return end
	local user_info = usermgr.GetUserById(user_id)
	if not user_info then return end
	local user_wing_level = wing_lib.user_list[user_id].level
	if user_wing_level == 9 then return end
	local vip_level = 0
  if viplib then
      vip_level = viplib.get_vip_level(user_info)
      --TraceError("vip_level"..vip_level)
  end
	local can_get_exp = wing_lib.cfg_exp_need_each[user_wing_level] - wing_lib.user_list[user_id].exp_now
	local can_get_exp_play_today = wing_lib.exp_play_everyday[user_wing_level] - wing_lib.user_list[user_id].exp_play
	local can_get_exp_item_today = wing_lib.cfg_exp_vip_item[vip_level] - wing_lib.user_list[user_id].exp_item
	local min_exp_can_get = 0
	local should_get = 0
	 
	if exp_type == 2 then
	  min_exp_can_get = can_get_exp_play_today < can_get_exp and can_get_exp_play_today or can_get_exp
	  should_get = exp_num < min_exp_can_get and exp_num or min_exp_can_get
	  wing_lib.user_list[user_id].exp_play = wing_lib.user_list[user_id].exp_play + should_get
	  if (can_get_exp_play_today <= exp_num) and (should_get <= exp_num) and (can_get_exp_play_today ~= 0) and (should_get ~= 0) then
	    wing_lib.send_chengzhang_up(user_info)
	  end 
	elseif exp_type == 3 then 
	  min_exp_can_get = can_get_exp_item_today < can_get_exp and can_get_exp_item_today or can_get_exp
	  should_get = exp_num < min_exp_can_get and exp_num or min_exp_can_get
	  wing_lib.user_list[user_id].exp_item = wing_lib.user_list[user_id].exp_item + should_get
	end
	wing_lib.user_list[user_id].exp_now = wing_lib.user_list[user_id].exp_now + should_get
	--跟新数据库todo
  wing_lib_db.update_wing_info(user_id, should_get)
  wing_lib.update_wing_info(user_id)
end

--成功升级
function wing_lib.level_up(user_id)
  if not wing_lib.user_list[user_id] then return end
  wing_lib.user_list[user_id].level = wing_lib.user_list[user_id].level + 1
  if  wing_lib.user_list[user_id].level ~= 9 then
    wing_lib.user_list[user_id].exp_now = 0
    wing_lib_db.update_wing_info(user_id)
  end
  wing_lib.update_wing_info(user_id)
  wing_lib_db.update_wing_level(user_id, wing_lib.user_list[user_id].level)
  --加保险箱
  if safebox_lib and wing_lib.cfg_level_give_safebox[wing_lib.user_list[user_id].level] then
    safebox_lib.add_safebox_num(user_id, wing_lib.cfg_level_give_safebox[wing_lib.user_list[user_id].level])
  end
  --更新升级后的时间，排行榜排序用
  wing_lib_db.update_sys_time(user_id)
end

--穿上或卸下穿上翅膀
function wing_lib.dress_wing(user_id, dress_not)
  local user_info = usermgr.GetUserById(user_id)
	if(user_info==nil)then return end
	if not wing_lib.user_list[user_id] then return end
	if wing_lib.user_list[user_id].level == 0 then return end
	if dress_not ~= 0 and dress_not ~= 1 then return end
	
  local call_back = function()
    wing_lib.send_use_item(user_id,wing_lib.cfg_wing_id[wing_lib.user_list[user_id].level],1)
  end
	--如果客户端卡住不停刷协议也没有关系
	if not wing_lib.user_list[user_id].already_init_dress then return end
	if wing_lib.user_list[user_id].dress_on == 0 and dress_not == 1 then
    tex_gamepropslib.set_props_count_by_id(wing_lib.cfg_wing_id[wing_lib.user_list[user_id].level], -1, user_info, call_back)
  elseif wing_lib.user_list[user_id].dress_on == 1 and dress_not == 0 then
    tex_gamepropslib.set_props_count_by_id(wing_lib.cfg_wing_id[wing_lib.user_list[user_id].level], 1, user_info, nil)
  else
    return
  end
  wing_lib.user_list[user_id].dress_on = dress_not
  wing_lib_db.update_wing_dress(user_id, dress_not)
  --更新客户端
  wing_lib.update_wing_info(user_id)
end

--得到翅膀信息
function wing_lib.get_wing_level(user_id)
  if wing_lib.user_list[user_id] and wing_lib.user_list[user_id].already_init_dress and wing_lib.user_list[user_id].already_init_dress == 1 then
      return wing_lib.user_list[user_id].level
  else
    return -1
  end
end

--加钱登录领取
function wing_lib.add_wing_level_gold(user_id)
  if not wing_lib.cfg_level_get_money[wing_lib.get_wing_level(user_id)] then return 0,0 end 
  local level = wing_lib.get_wing_level(user_id)
  local money = wing_lib.cfg_level_get_money[level]
  usermgr.addgold(user_id, money, 0, new_gold_type.TEX_RAWDON_MONEY, -1, 1)
  return level,money
end

--加贵族长大盘数
function wing_lib.add_time_for_guizu(room_level, user_id)
  local user_info = usermgr.GetUserById(user_id)
  local name = "guizu"..room_level
  local deskno = user_info.desk
  wing_lib.user_list[user_id][name] = wing_lib.user_list[user_id][name] + 1
  --todo通知客户端加盘数
  if wing_lib.user_list[user_id][name] >= wing_lib.BOX_ITEM_GUIZU_NEED[room_level] then
    tex_gamepropslib.set_props_count_by_id(wing_lib.BOX_ITEM_GUIZU[room_level], 1, user_info, nil)
    wing_lib.user_list[user_id][name] = 0
    --给所有人和旁观者发协议
		--广播给所有人
	  local sendfunc = function(buf)
	      buf:writeString("WINGBOX")
	      buf:writeInt(wing_lib.BOX_ITEM_GUIZU[room_level])
	      buf:writeByte(user_info.site)
	      buf:writeString(user_info.nick)
	  end
	  netlib.broadcastdesk(sendfunc, deskno, borcastTarget.all)
    wing_lib_db.record_chris_event_log(user_id, wing_lib.BOX_ITEM_GUIZU[room_level], 1, 1)
  end 
  wing_lib.send_panshu(user_info,room_level,wing_lib.user_list[user_id][name],wing_lib.BOX_ITEM_GUIZU_NEED[room_level]) 
end

--清除每日信息
function wing_lib.clear_everyday_info(user_id)
  if wing_lib.user_list[user_id] then
    wing_lib.user_list[user_id].exp_play = 0
  	wing_lib.user_list[user_id].exp_item = 0
  end
  wing_lib_db.clear_everyday_info(user_id)
end

--是不是在同一天
function wing_lib.is_today(time1,time2)
	if time1==nil or time2==nil or time1=="" or time2=="" then return 0 end
	local table_time1 = os.date("*t",time1);
	local year1  = table_time1.year;
	local month1 = table_time1.month;
	local day1 = table_time1.day;
	local time1 = year1.."-"..month1.."-"..day1.." 00:00:00"
	
	local table_time2 = os.date("*t",time2);
	local year2  = tonumber(table_time2.year);
	local month2 = tonumber(table_time2.month);
	local day2 = tonumber(table_time2.day);
	local time2 = year2.."-"..month2.."-"..day2.." 00:00:00"
	
	--容错处理，如果时间拿到空的，会得到1970年
	if tonumber(year1)<2012 or tonumber(year2)<2012 then 
		return 0 
	end
	if time1~=time2 then
		return 0
	end
	return 1
end

--判断是不是每天2点
function wing_lib.get_time_everyday_2(time_now)
  local tableTime = os.date("*t",time_now)
  local time_2 = os.time{year = tableTime.year, month = tableTime.month, day = tableTime.day, hour = 2, min=0, sec=0}
  if time_2 == time_now then
    return 1
  else
    return 0
  end
end

--判断是不是每天零点
function wing_lib.get_time_everyday_0(time_now)
  local tableTime = os.date("*t",time_now)
  local time_0 = os.time{year = tableTime.year, month = tableTime.month, day = tableTime.day, hour = 0, min=0, sec=0}
  if time_0 == time_now then
    return 1
  else
    return 0
  end
end

--发送对应的玩家翅膀合成信息
function wing_lib.send_wing_hecheng_tz(user_info)

end

--判断是不是翅膀图纸
function wing_lib.check_wing(tz_id)
  if tz_id >= 100120 and tz_id <= 100128 then
    return 1
  else
    return 0
  end
end

--判断是否达到合成翅膀的条件--todo判断跨等级合成过滤
function wing_lib.check_wing_hengcheng(user_id, tz_id)
  if not wing_lib.user_list[user_id] then return 0 end
  if not wing_lib.user_list[user_id].already_init then return end
  if not wing_lib.user_list[user_id].already_init_dress then return end
  local level = wing_lib.user_list[user_id].level
  local exp_now = wing_lib.user_list[user_id].exp_now
  if  exp_now < wing_lib.cfg_exp_need_each[level] then return 0 end
  return 1
end


--得到差多少成长值满
function wing_lib.get_need_to_level_up(user_id)
  if not wing_lib.user_list[user_id] then return  end
  local exp_now = wing_lib.user_list[user_id].exp_now
  local level = wing_lib.user_list[user_id].level
  --TraceError("差多少成长值满"..wing_lib.cfg_exp_need_each[level] - exp_now)
  if level == 9 then 
    return 0
  else
    return wing_lib.cfg_exp_need_each[level] - exp_now
  end
end

--得到今天还可以得到多少exp item
function wing_lib.get_left_today_item_exp(user_id)
  if not wing_lib.user_list[user_id] then return  end
  local user_info = usermgr.GetUserById(user_id)
  local exp_item = wing_lib.user_list[user_id].exp_item
  local vip_level = 0
  if viplib then
      vip_level = viplib.get_vip_level(user_info)
  end
  return wing_lib.cfg_exp_vip_item[vip_level] - wing_lib.user_list[user_id].exp_item
end


--检查是否可以增加工资时间
function wing_lib.check_online_prize(user_info)
  local result = 1
  if not user_info.gametimeinfo then result = 0 end
  local level = wing_lib.get_wing_level(user_info.userId)
  if not wing_lib.cfg_online_prize[level] then result = 0 end
  local max_time = wing_lib.cfg_online_prize[level] or 0
  local today_add = split(user_info.gametimeinfo["today_add"],"|");
  local today_add_time = tonumber(today_add[2]) or 0
  if today_add_time >= max_time then result = 0 end
  return result
end


--得到爵位工资袋的详细情况
function wing_lib.get_online_info(user_info)
 local level = wing_lib.get_wing_level(user_info.userId)
 local result = 1
 if (not wing_lib.cfg_online_prize) or (wing_lib.cfg_online_prize[level] == 0) then 
   return -1
 end
 result = wing_lib.check_online_prize(user_info)
 return result
end

-------------------------------------------来自客户端的请求----------------------------------
--活动是否有效
function wing_lib.on_recv_huodong_status(buf)
  
end

--收到请求卸下翅膀协议
function wing_lib.on_recv_not_dress(buf)
  local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId
	if not wing_lib.user_list[user_id] then return end
  wing_lib.dress_wing(user_id, 0)	
end

--收到请求排行榜协议
function wing_lib.on_recv_rank_list(buf)
  local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId
	if not wing_lib.user_list[user_id] then return end
	wing_lib.send_user_history_final(user_info)
end

--收到请求查看用户爵位信息
function wing_lib.on_recv_ask_wing_info(buf)
  local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local ask_user_id = buf:readInt()
	local ask_level = wing_lib.get_wing_level(ask_user_id)
	wing_lib.send_other_winginfo(user_info,ask_user_id,ask_level)
end

--请求贵族场盘数
function wing_lib.on_recv_panshu(buf)
  local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId
	if not wing_lib.user_list[user_id] then return end
	local deskno = user_info.desk
	local deskinfo = desklist[deskno]
	if(deskinfo == nil) then
        return;
  end
  local room_level = nil
  local type_room = nil
  if viproom_lib then
    type_room = viproom_lib.get_room_spec_type(deskno)
    room_level = viproom_lib.get_room_spec_level(deskno)

    if  (type_room ~= 2) or (not room_level) or room_level < 3 then
       return
    end
  end
  local name = "guizu"..room_level
  wing_lib.send_panshu(user_info,room_level,wing_lib.user_list[user_id][name],wing_lib.BOX_ITEM_GUIZU_NEED[room_level])
end


--收到想踢谁的信息
function wing_lib.on_recv_kick_people(buf)
	local user_info = userlist[getuserid(buf)] 
	if not user_info then return end
	if not user_info.desk or user_info.desk <= 0 then return end	
	local deskno = user_info.desk
	local kicksiteno = buf:readByte()
	local deskinfo = desklist[deskno].gamedata
	local cankick = 0 
	local players = deskmgr.getplayers(deskno)
  --判断是不是爵位场
  if viproom_lib then
    local type_room = viproom_lib.get_room_spec_type(deskno)
    local room_level = viproom_lib.get_room_spec_level(deskno)
    if type_room ~= 2 then 
      return
    end
  end
  
  --检查被踢人是否还在座位上
  local kickuserinfo = nil
  local cankicknum = 0
  for _, player in pairs(players) do
      if player.siteno == kicksiteno then
          kickuserinfo = player.userinfo --被踢的人的用户信息 
          break
      end
  end
  if not kickuserinfo then return end
  --判断爵位高低是否符合
  if wing_lib.get_wing_level(user_info.userId) <= wing_lib.get_wing_level(kickuserinfo.userId) then
    wing_lib.send_kick_info(user_info,-2)
    return
  end
  if not tex_buf_lib then return end
  if tex_buf_lib.get_aleady_kick(deskno) == 1 then
    wing_lib.send_kick_info(user_info,-1)
    return
  end
  tex_buf_lib.set_aleady_kick(deskno,1)
  deskinfo.kickinfo.kickuserinfo = kickuserinfo
  local player = {
                userinfo = deskinfo.kickinfo.kickuserinfo,
                systime = os.time(),
                isondesk = 1,
                n_type = 1,
                kicker_userinfo = user_info,
                --okcount = deskinfo.kickinfo.toupiaook,
                --notokcount = deskinfo.kickinfo.toupiaonotok,
                --abortcount = deskinfo.kickinfo.toupiaoabort,
                --count = deskinfo.kickinfo.peoplecount,
            }
  
  --通知被踢走todo
  --tex_buf_lib.onafterkickuser(deskno, player, isplaying)
  tex_buf_lib.add_desk_kick_list(deskno, player, deskinfo.kickinfo.kickuserinfo);
  wing_lib.send_kick_info(user_info,1)
end

cmdHandler = 
{
    ["WINGACTIVE"]    = wing_lib.on_recv_huodong_status,    --活动是否有效
    ["WINGNOTDRESS"]  = wing_lib.on_recv_not_dress,         --收到卸下翅膀请求
    ["WINGRANKLIST"]  = wing_lib.on_recv_rank_list,         --请求排行榜
    ["WINGLEVEL"]     = wing_lib.on_recv_ask_wing_info,         --请求别人的爵位信息
    ["WINGPS"]        = wing_lib.on_recv_panshu;         --请求贵族场盘数
    --贵族T人
    ["WINGKICK"]        = wing_lib.on_recv_kick_people,		--收到想踢谁的信息
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("on_user_exit", wing_lib.on_user_exit)
eventmgr:addEventListener("h2_on_user_login", wing_lib.on_after_user_login)
eventmgr:addEventListener("use_item_event", wing_lib.on_use_item)
eventmgr:addEventListener("on_game_over_event", wing_lib.on_game_over)
eventmgr:addEventListener("before_open_hecheng", wing_lib.before_open_hecheng)
eventmgr:addEventListener("meet_event",  wing_lib.on_meet_event);
eventmgr:addEventListener("after_hecheng_event",  wing_lib.after_hecheng_event);
eventmgr:addEventListener("on_server_start", wing_lib.restart_server)
eventmgr:addEventListener("timer_second", wing_lib.timer)
eventmgr:addEventListener("bag_open_box_event", wing_lib.bag_open_box_event)