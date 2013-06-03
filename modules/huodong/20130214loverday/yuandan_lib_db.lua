-------------------------------------------------------
-- 文件名　：yuandan_lib_db.lua
-- 创建者　：lgy
-- 创建时间：2012-11-12 15：00：00
-- 文件描述：开宝箱，优惠券活动，11月15日
-------------------------------------------------------

TraceError("init yuandan_lib_db...")
if yuandan_lib_db and yuandan_lib_db.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", yuandan_lib_db.on_after_user_login);
end

if not yuandan_lib_db then
    yuandan_lib_db = _S
    {
    }
end

------------------------------------外部接口------------------------------------------
function yuandan_lib_db.on_after_user_login(e)
  if yuandan_lib.check_datetime() == 0 then return end
	local user_info = e.data.userinfo
	if user_info == nil then return end
	local user_id = user_info.userId
	if yuandan_lib.user_list[user_id] == nil then
		yuandan_lib.user_list[user_id] = {}
	end
	
	local current_time = os.time()
	dblib.cache_get("user_yuandan_info", "*", "user_id", user_id,function(dt)
		if dt and #dt>0 then
			yuandan_lib.user_list[user_id].user_id = user_id
			yuandan_lib.user_list[user_id].now_step = {}
			yuandan_lib.user_list[user_id].now_step[1] = dt[1].now_step1
			yuandan_lib.user_list[user_id].now_step[2] = dt[1].now_step2
			yuandan_lib.user_list[user_id].now_step[3] = dt[1].now_step3		
			yuandan_lib.user_list[user_id].now_state = {}
			yuandan_lib.user_list[user_id].now_state[1] = dt[1].now_state1
			yuandan_lib.user_list[user_id].now_state[2] = dt[1].now_state2
			yuandan_lib.user_list[user_id].now_state[3] = dt[1].now_state3
    else
      yuandan_lib.user_list[user_id].user_id = user_id
			yuandan_lib.user_list[user_id].now_step = {}
			yuandan_lib.user_list[user_id].now_step[1] = 1
			yuandan_lib.user_list[user_id].now_step[2] = 1
			yuandan_lib.user_list[user_id].now_step[3] = 1
			yuandan_lib.user_list[user_id].now_state = {}
			yuandan_lib.user_list[user_id].now_state[1] = 1
			yuandan_lib.user_list[user_id].now_state[2] = 1
			yuandan_lib.user_list[user_id].now_state[3] = 1		
			
			dblib.cache_add("user_yuandan_info",{user_id=user_id,now_step1=1,now_step2=1,now_step3=1,now_state1=1,now_state2=1,now_state3=1},nil,user_id)
    end
	end,user_id)
end

--记录翻牌奖励记录
function yuandan_lib_db.log_yuandan_play_card(user_id, type_game, now_step, type_id)
	local sql = "insert into log_yuandan_play_card(user_id,type_game,now_step,type_id,sys_time) value(%d,%d,%d,%d,now());"
	sql = string.format(sql,user_id,type_game,now_step,type_id)
	dblib.execute(sql)
end
--记录兑换奖励记录（包括汽车和达人币）
function yuandan_lib_db.log_yuandan_reward(user_id, type_game, now_step, car_id, cash_num)
	local sql = "insert into log_yuandan_reward(user_id,type_game,now_step,car_id,cash_num,sys_time) value(%d,%d,%d,%d,%d,now());"
	sql = string.format(sql,user_id,type_game,now_step,car_id,cash_num)
	dblib.execute(sql)
end
--记录开始游戏记录（使用达人币还是金币开始的）
function yuandan_lib_db.log_start_playcard(user_id, type_game, type_id)
	local sql = "insert into log_start_playcard(user_id,type_game,type_id,sys_time) value(%d,%d,%d,now());"
	sql = string.format(sql,user_id,type_game,type_id)
	dblib.execute(sql)
end
--保存数据
function yuandan_lib_db.set_gameinfo(user_id, duihuan_type, now_step, now_state)
	yuandan_lib_db.set_now_step(user_id, duihuan_type, now_step)
	yuandan_lib_db.set_now_state(user_id, duihuan_type, now_state)
end

--保存游戏步骤
function yuandan_lib_db.set_now_step(user_id, duihuan_type, now_step)
	if duihuan_type == 1 then
		dblib.cache_set("user_yuandan_info", {now_step1=now_step}, "user_id", user_id, nil, user_id)
	elseif duihuan_type == 2 then
		dblib.cache_set("user_yuandan_info", {now_step2=now_step}, "user_id", user_id, nil, user_id)
	elseif duihuan_type == 3 then
		dblib.cache_set("user_yuandan_info", {now_step3=now_step}, "user_id", user_id, nil, user_id)
	end
end

--保存游戏状态
function yuandan_lib_db.set_now_state(user_id, duihuan_type, now_state)
	if duihuan_type == 1 then
		dblib.cache_set("user_yuandan_info", {now_state1=now_state}, "user_id", user_id, nil, user_id)
	elseif duihuan_type == 2 then
		dblib.cache_set("user_yuandan_info", {now_state2=now_state}, "user_id", user_id, nil, user_id)
	elseif duihuan_type == 3 then
		dblib.cache_set("user_yuandan_info", {now_state3=now_state}, "user_id", user_id, nil, user_id)
	end
end

cmdHandler = 
{



}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("h2_on_user_login", yuandan_lib_db.on_after_user_login);

