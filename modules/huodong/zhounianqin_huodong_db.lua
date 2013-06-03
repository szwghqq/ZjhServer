TraceError("init zhounian_huodong_db_lib...")

if not zhounian_huodong_db_lib then
    zhounian_huodong_db_lib = _S
    {
		--方法
  		get_paiming = NULL_FUNC,
		gen_chenghao = NULL_FUNC,
		insert_chenghao = NULL_FUNC,
		update_chenghao_notify = NULL_FUNC, 
  		--参数

    }    
end

function zhounian_huodong_db_lib.get_paiming(call_back)
	--local sql = "SELECT a.userid as user_id,MAX(a.sys_time) as sys_time,SUM(a.rmb) as rmb,b.face as img_url,b.nick_name as nick_name FROM log_pay_success a left join users b on a.userid = b.id WHERE  a.sys_time>='%s' and a.sys_time<'%s' GROUP BY a.userid ORDER BY SUM(a.rmb) DESC, MAX(a.sys_time) limit %d;"
	--sql = string.format(sql, "2000-1-1 10:0:0", zhounian_huodong_lib.end_time, zhounian_huodong_lib.CFG_PAIMING_LEN)
	local sql = "SELECT a.userid as user_id,MAX(a.sys_time) as sys_time,SUM(a.rmb) as rmb,b.face as img_url,b.nick_name as nick_name FROM log_pay_realrmb a left join users b on a.userid = b.id WHERE a.userid != 1969160 and a.sys_time>='%s' and a.sys_time<'%s' GROUP BY a.userid ORDER BY SUM(a.rmb) DESC, MAX(a.sys_time) limit %d;"
	sql = string.format(sql, zhounian_huodong_lib.start_time, zhounian_huodong_lib.end_time, zhounian_huodong_lib.CFG_PAIMING_LEN)
	
	dblib.execute(sql, function(dt)
		if dt and #dt>0 then
			zhounian_huodong_lib.paiming_list = {}
			for i = 1, #dt do
				local buf_tab = {
					["user_id"] = dt[i].user_id,
					["nick_name"] = dt[i].nick_name,
					["sys_time"] = dt[i].sys_time,
					["rmb"] = dt[i].rmb,
					["img_url"] = dt[i].img_url,
				}
				table.insert(zhounian_huodong_lib.paiming_list, buf_tab)
			end
			if call_back~=nil then
				call_back(zhounian_huodong_lib.paiming_list)
			end
		end
	end)
end

function zhounian_huodong_db_lib.gen_chenghao()
	--每个玩家暂时只有一个称号
	zhounian_huodong_lib.chenghao_list = {}
	local sql = "select * from t_chenghao_info where over_time>now()"
	sql = string.format(sql, user_id)
	dblib.execute(sql, function(dt)
		if dt and #dt > 0 then
			for i = 1, #dt do
				local buf_tab = {
					["user_id"] = dt[i].user_id,
					["chenghao_id"] = dt[i].chenghao_id,
					["mc"] = i,
					["over_time"] = dt[i].over_time,
					["already_notify"] = dt[i].already_notify
				}
				table.insert(zhounian_huodong_lib.chenghao_list, buf_tab)
			end
		end
	end)

end

function zhounian_huodong_db_lib.insert_chenghao(user_id, chenghao_id, over_time)
	local sql = "insert ignore into t_chenghao_info(chengHao_id,user_id,over_time) value(%d, %d, date_add(now(),INTERVAL %d DAY))"
	sql = string.format(sql, chenghao_id, user_id, over_time)
	dblib.execute(sql, function(dt) end, user_id)
end

function zhounian_huodong_db_lib.update_chenghao_notify(user_id, chenghao_id)
	local sql = "update t_chenghao_info set already_notify = 1 where chenghao_id = %d"
	sql = string.format(sql, chenghao_id)
	dblib.execute(sql, function(dt) end , user_id)

end


--命令列表
cmdHandler = 
{


}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end
