TraceError("init shop_db_lib...")

if not shop_db_lib then
    shop_db_lib = _S
    {    	   
		get_gift_list = NULL_FUNC, 
		set_gift_list = NULL_FUNC,
		init_coupon_list = NULL_FUNC,
		save_real_gift_info = NULL_FUNC, 
		add_gold_log = NULL_FUNC, 
		get_before_buy_info = NULL_FUNC, 
    }
end

function shop_db_lib.init_coupon_list()
	local sql = "select sys_time, gift_id, gift_des, gift_num, today_num, gift_type, cost, valid_time, can_give,ex_type from cfg_coupon_gift"
	dblib.execute(sql, function(dt)
		if dt and #dt > 0 then
			shop_lib.set_gift_list_by_type(0, dt)
		end
	end, 9999)	
end

--记录玩家的兑换实物礼品情况 gift_type是冗余参数，实物礼品目前只有礼券能换
function shop_db_lib.save_real_gift_info(gift_type, gift_id, gift_num, gift_des,  real_user_info)
	local sql = "insert into user_real_gift(sys_time, user_id, gift_id, gift_num, gift_des, real_name, tel, yy_num, real_address) value(now(), %d, %d, %d,'%s', '%s', '%s','%s','%s');commit;"
	sql = string.format(sql, real_user_info.user_id, gift_id, gift_num, gift_des, string.trans_str(real_user_info.real_name), string.trans_str(real_user_info.tel), 
				string.trans_str(real_user_info.yy_num), string.trans_str(real_user_info.real_address))
	dblib.execute(sql, function(dt) end, real_user_info.user_id)
end

--写金币变化日志
function shop_db_lib.add_gold_log(user_id, gold_type, change_gold, before_change, change_result)
	local sql = "insert into log_shop_gold(user_id, gold_type, change_gold, before_change, change_result, sys_time) value(%d, %d, %d, %d,%d, now())"
	sql = string.format(sql, user_id, gold_type, change_gold, before_change, change_result)
	dblib.execute(sql, function(dt) end, user_id)
end

function shop_db_lib.get_before_buy_info(user_id, call_back)
	if call_back == nil then return end
	local before_info = {}
	local sql = "select user_id, gift_id, gift_num, real_name, tel, yy_num, real_address from user_real_gift where user_id = %d order by id desc limit 1"
	sql = string.format(sql, user_id)
	dblib.execute(sql, function(dt)
		if dt and #dt > 0 then
			before_info = {
				["user_id"] = dt[1].user_id,
				["real_name"] = dt[1].real_name,
				["tel"] = dt[1].tel,
				["yy_num"] = dt[1].yy_num,
				["real_address"] = dt[1].real_address,				
			}
			
		end
		call_back(before_info)
	end, user_id)
end

function shop_db_lib.save_today_num(gift_type, gift_id, today_num)
	local sql = "update cfg_coupon_gift set today_num = today_num + %d, sys_time= now() where gift_type=%d and gift_id = %d"
	sql = sql.format(sql, today_num, gift_type, gift_id)
	dblib.execute(sql, function(dt) end, 9998)
end