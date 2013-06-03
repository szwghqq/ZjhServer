-------------------------------------------------------
-- 文件名　：tex.chenghao.lua
-- 创建者　：lgy
-- 创建时间：2012-11-27 15：00：00
-- 文件描述：德州称号模块，从周年庆中抽出来 11月27日
-------------------------------------------------------

TraceError("init chenghao_lib...")

if chenghao_lib and chenghao_lib.restart_server then
	eventmgr:removeEventListener("on_server_start", chenghao_lib.restart_server);
end

if chenghao_lib and chenghao_lib.on_meet_event then
	eventmgr:removeEventListener("meet_event", chenghao_lib.on_meet_event);
end

if not chenghao_lib then
    chenghao_lib = _S
    {
		--方法  
  		send_chenhao = NULL_FUNC,
  		add_chenghao = NULL_FUNC,
  		init_chenghao = NULL_FUNC,
  		restart_server = NULL_FUNC, 
      on_user_exit = NULL_FUNC,

  		--参数
		chenghao_list = {},
		CFG_ROOM_ID = "18001",
		CFG_CHENGHAO_NAME = {
			[1] = "THE RICHEST MAN",
			[2] = "I'M BUFFETT",
			[3] = "FABULOUSLY RICH",
			[4] = "幸运之星",
			[5] = "幸运之神",
		},
    }    
end

function chenghao_lib.init_chenghao()
	--每个玩家暂时只有一个称号
	chenghao_lib.chenghao_list = {}
	local sql = "select * from t_chenghao_info where over_time>now()"
	sql = string.format(sql, user_id)
	dblib.execute(sql, function(dt)
		if dt and #dt > 0 then
			for i = 1, #dt do
				if not chenghao_lib.chenghao_list[dt[i].user_id] then
--					chenghao_lib.chenghao_list[dt[i].user_id] =	{}
--				local buf_tab = {
--					["user_id"] = dt[i].user_id,
--					["chenghao_id"] = dt[i].chenghao_id,
--					["over_time"] = dt[i].over_time,
--					["already_notify"] = dt[i].already_notify
--				}
					chenghao_lib.chenghao_list[dt[i].user_id] = {
						["user_id"] = dt[i].user_id,
						["chenghao_id"] = dt[i].chenghao_id,
						["over_time"] = dt[i].over_time,
						["already_notify"] = dt[i].already_notify
					}
				elseif chenghao_lib.chenghao_list[dt[i].user_id].chenghao_id < dt[i].chenghao_id then
					chenghao_lib.chenghao_list[dt[i].user_id] = {
						["user_id"] = dt[i].user_id,
						["chenghao_id"] = dt[i].chenghao_id,
						["over_time"] = dt[i].over_time,
						["already_notify"] = dt[i].already_notify
					}
				end
--				table.insert(chenghao_lib.chenghao_list[user_id], buf_tab)
			end
		end
	end)
end


function chenghao_lib.send_chenhao(from_user_info, to_user_info)
		if chenghao_lib.chenghao_list[from_user_info.userId] then
			netlib.send(function(buf)
				buf:writeString("CZHDCH")
				buf:writeInt(1)
					if os.time() > timelib.db_to_lua_time(chenghao_lib.chenghao_list[from_user_info.userId].over_time) then
						buf:writeInt(-1)
						buf:writeInt(-1)
						buf:writeString(chenghao_lib.chenghao_list[from_user_info.userId].over_time)
					else
						buf:writeInt(chenghao_lib.chenghao_list[from_user_info.userId].user_id)
						buf:writeInt(chenghao_lib.chenghao_list[from_user_info.userId].chenghao_id)
						buf:writeString(_U("有效期至")..chenghao_lib.chenghao_list[from_user_info.userId].over_time)
					end
			end, to_user_info.ip, to_user_info.port)
		end
end

function chenghao_lib.on_meet_event(e)
  --  e.data.subject      ： 状态改变的玩家
	--  e.data.observer     :  观察者
	--  将状态改变的玩家信息通知给观察者
	if not e.data.subject or not e.data.observer then return end
	chenghao_lib.send_chenhao(e.data.subject, e.data.observer)
end

function chenghao_lib.add_chenghao(user_id, chenghao_id, over_time)
	if groupinfo.groupid ~= chenghao_lib.CFG_ROOM_ID then return end
	local nowtime = os.time()
	nowtime = timelib.lua_to_db_time(nowtime)
	local endtime = timelib.add_db_time(nowtime,over_time,0,0,0)
	
	if not chenghao_lib.chenghao_list[user_id] then
		local sql = "insert ignore into t_chenghao_info(chengHao_id,user_id,over_time) value(%d, %d, date_add(now(),INTERVAL %d DAY))"
		sql = string.format(sql, chenghao_id, user_id, over_time)
		dblib.execute(sql, nil, user_id)
	elseif chenghao_lib.chenghao_list[user_id].chenghao_id <= chenghao_id or
		os.time() > timelib.db_to_lua_time(chenghao_lib.chenghao_list[user_id].over_time) then
		local sql = "UPDATE t_chenghao_info SET over_time = DATE_ADD(NOW(),INTERVAL %d DAY) ,chenghao_id =%d  WHERE user_id =%d"
		sql = string.format(sql, over_time, chenghao_id, user_id )
		dblib.execute(sql, nil, user_id)
	end
	
	if not chenghao_lib.chenghao_list[user_id] or
		chenghao_lib.chenghao_list[user_id].chenghao_id <= chenghao_id or
		 os.time() > timelib.db_to_lua_time(chenghao_lib.chenghao_list[user_id].over_time) then
		chenghao_lib.chenghao_list[user_id] ={}
		local buf_tab = {
						["user_id"] = user_id,
						["chenghao_id"] = chenghao_id,
						["over_time"] = endtime,
						["already_notify"] = already_notify
					}
		chenghao_lib.chenghao_list[user_id] = buf_tab	
	end
	
end


function chenghao_lib.restart_server()
	chenghao_lib.init_chenghao()
end


--命令列表
cmdHandler = 
{
	

}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("on_server_start", chenghao_lib.restart_server);
eventmgr:addEventListener("meet_event",  chenghao_lib.on_meet_event);