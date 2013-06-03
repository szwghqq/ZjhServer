-------------------------------------------------------
-- 文件名　：new_year_db.lua
-- 创建者　：lgy
-- 创建时间：2012-12-13 18：00：00
-- 文件描述：世界末日大逃亡活动
-------------------------------------------------------
TraceError("init new_year_db...")
if not new_year_db then
    new_year_db = _S
    {
    	--以下是方法
        --以下是变量及配置信息
    }    
end

function new_year_db.init_user_info(user_id)
	if new_year.user_list[user_id] == nil then
		new_year.user_list[user_id] = {}
  end
  local user_info = usermgr.GetUserById(user_id)
  local current_time = os.time()
	new_year.user_list[user_id].wishes = 0
	new_year.user_list[user_id].buff = 0
	new_year.user_list[user_id].flower1 = 0
	new_year.user_list[user_id].flower2 = 0
	new_year.user_list[user_id].flower3 = 0
	new_year.user_list[user_id].flower4 = 0
	new_year.user_list[user_id].flower5 = 0
  dblib.cache_get("user_new_year_info", "*", "user_id", user_id,function(dt)
  	if user_info == nil then return end
  	if not new_year.user_list[user_id] then return end
  	if dt and #dt>0 then
			new_year.user_list[user_id].wishes = dt[1].wishes
				new_year.user_list[user_id].buff = dt[1].buff
				new_year.user_list[user_id].flower1 = dt[1].flower1
				new_year.user_list[user_id].flower2 = dt[1].flower2
				new_year.user_list[user_id].flower3 = dt[1].flower3
				new_year.user_list[user_id].flower4 = dt[1].flower4
				new_year.user_list[user_id].flower5 = dt[1].flower5
				new_year.user_list[user_id].last_login_time = dt[1].last_login_time
		else
			dblib.cache_add("user_new_year_info",{user_id=user_id, nick_name = user_info.nick},nil,user_id)
  	end
  	new_year.send_new_year_status(user_info)
  	dblib.cache_set("user_new_year_info",{nick_name = user_info.nick},"user_id", user_id, nil, user_id)
  	--登录送心愿值todo 一天送一次
  	local now_time = os.time()
		if new_year.check_time() == 1 then
	  	if new_year.is_today(now_time,new_year.user_list[user_id].last_login_time) ~= 1 then
				new_year.add_wishes(user_id, new_year.CFG_LOGIN_NUMBER, 6)
			end
		end
		--更新用户登录时间
		new_year_db.update_user_login_time(user_id, now_time)
  end,user_id)

  new_year.user_list[user_id].history = {}
	dblib.cache_get("user_new_year_history_info", "*", "user_id", user_id,function(dt)
		--防止玩家在数据库很卡，初始化到一半时掉线
		
		if user_info == nil then return end
		if dt and #dt > 0 then
				for i=1, 5 do
					local name = "gift_name"..i
					local time = "sys_time"..i
					local buf_tab = {
						["gift_name"] = dt[1][name],
					}
					if string.len(buf_tab.gift_name)>0  then
						table.insert(new_year.user_list[user_id].history, buf_tab)
					end
				end
		else
			dblib.cache_add("user_new_year_history_info",{user_id=user_id},nil,user_id)
    end
	end, user_id)
  xpcall(function() new_year_db.check_wish_time(user_id) end, throw)
end

function new_year_db.check_wish_time(user_id)  
  new_year.user_list[user_id].bet_wishes = {}
	for i =1 ,7 do
	  new_year.user_list[user_id].bet_wishes[i] = 0
	end
	new_year.user_list[user_id].last_update_time = 0
	dblib.cache_get("bet_new_year_wishes", "*", "user_id", user_id,function(dt)
		--防止玩家在数据库很卡，初始化到一半时掉线
		if new_year.user_list[user_id] == nil then return end
		if dt and #dt > 0 then

				new_year.user_list[user_id].bet_wishes[1] = dt[1].wishes_number1
				new_year.user_list[user_id].bet_wishes[2] = dt[1].wishes_number2
				new_year.user_list[user_id].bet_wishes[3] = dt[1].wishes_number3
				new_year.user_list[user_id].bet_wishes[4] = dt[1].wishes_number4
				new_year.user_list[user_id].bet_wishes[5] = dt[1].wishes_number5
				new_year.user_list[user_id].bet_wishes[6] = dt[1].wishes_number6
				new_year.user_list[user_id].bet_wishes[7] = dt[1].wishes_number7
				new_year.user_list[user_id].last_update_time = timelib.db_to_lua_time(dt[1].last_update_time)

		else
			dblib.cache_add("bet_new_year_wishes",{user_id=user_id},nil,user_id)
    end
    local now_time = os.time()
    if new_year.is_today(new_year.user_list[user_id].last_update_time ,now_time) == 0 then
      new_year_db.clear_task_proc(user_id)
    end
	end, user_id)    
end
  
--更新下线时间
function new_year_db.update_exit_time(user_id)  
  dblib.cache_set("bet_new_year_wishes",{last_update_time = timelib.lua_to_db_time(os.time())},"user_id", user_id, nil, user_id)
end

function new_year_db.clear_task_proc(user_id)
  dblib.cache_set("bet_new_year_wishes",{
        wishes_number1 = 0,
				wishes_number2 = 0,
				wishes_number3 = 0,
				wishes_number4 = 0,
				wishes_number5 = 0,
				wishes_number6 = 0,
				wishes_number7 = 0,},"user_id", user_id, nil, user_id)
end

function new_year_db.set_bet_wishes_up(user_id,num_type,wishes)
  if num_type == 1 then
    dblib.cache_set("bet_new_year_wishes",{wishes_number1 = wishes,},"user_id", user_id, nil, user_id)
  elseif num_type == 2 then
    dblib.cache_set("bet_new_year_wishes",{wishes_number2 = wishes,},"user_id", user_id, nil, user_id)
  elseif num_type == 3 then
    dblib.cache_set("bet_new_year_wishes",{wishes_number3 = wishes,},"user_id", user_id, nil, user_id)
  elseif num_type == 4 then
    dblib.cache_set("bet_new_year_wishes",{wishes_number4 = wishes,},"user_id", user_id, nil, user_id)
  elseif num_type == 5 then
    dblib.cache_set("bet_new_year_wishes",{wishes_number5 = wishes,},"user_id", user_id, nil, user_id)
  elseif num_type == 6 then
    dblib.cache_set("bet_new_year_wishes",{wishes_number6 = wishes,},"user_id", user_id, nil, user_id)
  elseif num_type == 7 then
    dblib.cache_set("bet_new_year_wishes",{wishes_number7 = wishes,},"user_id", user_id, nil, user_id)
  end
end

--更新心愿值数据
function new_year_db.update_wishes(user_id, add_wishes)
	add_wishes = new_year.user_list[user_id].wishes
	dblib.cache_set("user_new_year_info",{wishes = add_wishes},"user_id", user_id, nil, user_id)
end

--更新花的数量--todo
function new_year_db.update_flowers(user_id, flower_id)
	local name = "flower"..flower_id
	add_number_flower = new_year.user_list[user_id][name]
	if flower_id == 1 then
		dblib.cache_set("user_new_year_info",{flower1 = add_number_flower},"user_id", user_id, nil, user_id)
	elseif flower_id == 2 then
		dblib.cache_set("user_new_year_info",{flower2 = add_number_flower},"user_id", user_id, nil, user_id)
	elseif flower_id == 3 then
		dblib.cache_set("user_new_year_info",{flower3 = add_number_flower},"user_id", user_id, nil, user_id)
	elseif flower_id == 4 then
		dblib.cache_set("user_new_year_info",{flower4 = add_number_flower},"user_id", user_id, nil, user_id)
	elseif flower_id == 5 then
		dblib.cache_set("user_new_year_info",{flower5 = add_number_flower},"user_id", user_id, nil, user_id)
	end
end

--更新buff时间
function new_year_db.update_buff(user_id, time)
		dblib.cache_set("user_new_year_info",{buff = time},"user_id", user_id, nil, user_id)
end

--跟新登录时间
function new_year_db.update_user_login_time(user_id, time)
	dblib.cache_set("user_new_year_info",{last_login_time = time},"user_id", user_id, nil, user_id)
end
	
--保存玩家最近5次的兑换历史
function new_year_db.update_history_me(user_id)
	if new_year.user_list[user_id].history[1] then
		dblib.cache_set("user_new_year_history_info", {gift_name1=new_year.user_list[user_id].history[1].gift_name or ""},"user_id", user_id, nil, user_id)
	end
	if new_year.user_list[user_id].history[2] then
		dblib.cache_set("user_new_year_history_info", {gift_name2=new_year.user_list[user_id].history[2].gift_name or "",},"user_id", user_id, nil, user_id)
	end
	if new_year.user_list[user_id].history[3] then
		dblib.cache_set("user_new_year_history_info", {gift_name3=new_year.user_list[user_id].history[3].gift_name or "",},"user_id", user_id, nil, user_id)
	end
	if new_year.user_list[user_id].history[4] then
		dblib.cache_set("user_new_year_history_info", {gift_name4=new_year.user_list[user_id].history[4].gift_name or "",},"user_id", user_id, nil, user_id)
	end
	if new_year.user_list[user_id].history[5] then
		dblib.cache_set("user_new_year_history_info", {gift_name5=new_year.user_list[user_id].history[5].gift_name or "",},"user_id", user_id, nil, user_id)
	end
end

--心愿值排序，终极大奖
function new_year_db.get_final_history()
	local sql  = "SELECT * FROM user_new_year_info ORDER BY  (flower1+flower2+flower3+flower4+flower5) DESC,wishes DESC, sys_time LIMIT 100"
	sql = string.format(sql, user_id)
	dblib.execute(sql, function(dt) 
		if dt and #dt > 0 then
			for i = 1, #dt do
				new_year.history_final_list[i] = {}
				new_year.history_final_list[i].flowers  = dt[i].flower1 + dt[i].flower2 + dt[i].flower3 + dt[i].flower4 + dt[i].flower5
	      new_year.history_final_list[i].wishes   = dt[i].wishes
	      new_year.history_final_list[i].sys_time = dt[i].sys_time
	      new_year.history_final_list[i].user_id  = dt[i].user_id
	      new_year.history_final_list[i].already_reward = dt[i].already_reward
	      new_year.history_final_list[i].nick_name = dt[i].nick_name
			end
    end
	end, user_id)
end
--已填写资料
function new_year_db.set_final_info(user_id)
	local sql = "update user_new_year_info set already_reward = 1 where user_id = %d; commit;"
	sql = string.format(sql, user_id)
	dblib.execute(sql, nil, user_id)
end

--记录获得的随机奖励
function new_year_db.record_new_year_box_info(user_id,item_gift_id,type_id,item_number)
  local sql = "insert into log_new_year_box_info(user_id,box_id,item_id,item_number,sys_time) value(%d,%d,%d,%d,now());"
	sql = string.format(sql, user_id, type_id, item_gift_id, item_number)
	dblib.execute(sql, nil, user_id)
end

--记录心愿值产出
function new_year_db.update_wishes_log(user_id, wishes_now, where, small_bet)
  local sql = "insert into log_new_year_wishes(user_id,type_id,wishes_number,small_bet,sys_time) value(%d,%d,%d,%d,now());"
	sql = string.format(sql, user_id, where, wishes_now, small_bet)
	dblib.execute(sql, nil, user_id)
end

--记录开花什么花
function new_year_db.record_new_year_flower_info(user_id,flower_id,add_flower)
  local sql = "insert into log_new_year_flower_info(user_id,flower_id,add_flower,sys_time) value(%d,%d,%d,now());"
	sql = string.format(sql, user_id, flower_id, add_flower)
	dblib.execute(sql, nil, user_id)
end

--给下线玩家加心愿值
function new_year_db.update_offline_wishes(user_id, add_wishes)
	--从cache里取出buff时间
	local buff = 0
	local wishes = 0
	dblib.cache_get("user_new_year_info", "*", "user_id", user_id,function(dt)
  	if dt and #dt>0 then
				wishes = dt[1].wishes
				buff = dt[1].buff
		else
			dblib.cache_add("user_new_year_info",{user_id=user_id},nil,user_id)
  	end
  end,user_id)
  if buff - os.time() > 0 then
  	add_wishes = add_wishes * new_year.CFG_BUFF_COEFFICIENT
  end
  if wishes%200 + add_wishes > 200 then
		math.randomseed(os.time())
		math.randomseed(os.time() + math.random(1, 10000000))
		local find = 0;
		local add = 0;
		local rand = math.random(1, 10000);
		for i = 1, #new_year.FLOWER_PORBABILITY_LIST do
				add = add + new_year.FLOWER_PORBABILITY_LIST[i]
				if add >= rand then
						find = i
					break
				end
		end
		
		if find == 0 then
			TraceError("随即失败没有随即出结果，请检查配置概率")
			return
		end
		local name = "flower"..find
		new_year_db.update_flowers(user_id, name, 1)
  end
  new_year_db.update_wishes(user_id, add_wishes)
end


--更新获奖联系人资料
function new_year_db.add_user_contact(user_id, rank_number, realname, yy, address, tel)
    local sql = "insert into newyear_contact_info(user_id, rank_number, realname, yy, address, tel) values(%d, %d, %s, %s, %s, %s)";
    sql = string.format(sql, user_id, rank_number, dblib.tosqlstr(realname), dblib.tosqlstr(yy), dblib.tosqlstr(address), dblib.tosqlstr(tel));
    dblib.execute(sql)
end