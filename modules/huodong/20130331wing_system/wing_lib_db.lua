-------------------------------------------------------
-- 文件名　：wing_lib_db.lua
-- 创建者　：lgy
-- 创建时间：2013-04-08 18：00：00
-- 文件描述：爵位翅膀系统
-------------------------------------------------------
TraceError("init wing_lib_db...")
if not wing_lib_db then
    wing_lib_db = _S
    {
    	--以下是方法
        --以下是变量及配置信息
    }    
end

--登录初始化用户爵位系统信息
function wing_lib_db.init_user_info(user_id)
	if not wing_lib.user_list[user_id] then
		wing_lib.user_list[user_id] = {}
  end
  local user_info = usermgr.GetUserById(user_id)
  local current_time = os.time()
  
	wing_lib.user_list[user_id].exp_now = 0
	wing_lib.user_list[user_id].exp_play = 0
	wing_lib.user_list[user_id].exp_item = 0
	wing_lib.user_list[user_id].dress_on = 0
	wing_lib.user_list[user_id].level = 0
	wing_lib.user_list[user_id].guizu3 = 0
	wing_lib.user_list[user_id].guizu4 = 0
	wing_lib.user_list[user_id].guizu5 = 0
	wing_lib.user_list[user_id].guizu6 = 0
	dblib.cache_get("user_wing_info", "*", "user_id", user_id,function(dt)
		if dt and #dt > 0 then
		    if not wing_lib.user_list[user_id] then return end
			  wing_lib.user_list[user_id].exp_now  = dt[1].exp_now
      	wing_lib.user_list[user_id].exp_play = dt[1].exp_play
      	wing_lib.user_list[user_id].exp_item = dt[1].exp_item
      	wing_lib.user_list[user_id].last_login_time = timelib.db_to_lua_time(dt[1].last_login_time)
      	--如果隔天登录则清楚每日获得成长值信息
      	local now_time = os.time()
      	if wing_lib.is_today(now_time, wing_lib.user_list[user_id].last_login_time) ~= 1 then
          wing_lib.clear_everyday_info(user_id)
      	end
    else
      dblib.cache_add("user_wing_info",{user_id=user_id, nick_name = user_info.nick, face = user_info.imgUrl},nil,user_id)
    end
    wing_lib.user_list[user_id].already_init = 1
    wing_lib_db.update_face_name(user_info)
	end, user_id)
	
	local sql = "select * from  user_wing_dress_info where user_id =%d"
	sql = string.format(sql, user_id)
	dblib.execute(sql, function(dt) 
	  --防止玩家在数据库很卡，初始化到一半时掉线
		local user_info = usermgr.GetUserById(user_id)
		if user_info == nil then return end
		if dt and #dt > 0 then
			wing_lib.user_list[user_id].dress_on = dt[1].dress_on
			wing_lib.user_list[user_id].level    = dt[1].level
		else
		  sql = "insert into user_wing_dress_info(user_id) value(%d)"
			sql = string.format(sql, user_id)
			dblib.execute(sql, function(dt) end, user_id)
		end
		wing_lib.user_list[user_id].already_init_dress = 1 
		wing_lib.update_wing_info(user_id)
	end, user_id)	
end

--清除每日信息
function wing_lib_db.clear_everyday_info(user_id)
  dblib.cache_set("user_wing_info",{exp_play = 0, exp_item = 0},"user_id", user_id, nil, user_id)
end

--更新下线时间
function wing_lib_db.update_exit_time(user_id)
  dblib.cache_set("user_wing_info",{last_login_time = timelib.lua_to_db_time(os.time())},"user_id", user_id, nil, user_id)
end

--更新名字和face,vip
function wing_lib_db.update_face_name(user_info)
  local user_id = user_info.userId
  local vip_level = 0
  if viplib then
      vip_level = viplib.get_vip_level(user_info)
      --TraceError("vip_level"..vip_level)
  end
  dblib.cache_set("user_wing_info",{nick_name = user_info.nick, face = user_info.imgUrl, vip_level = vip_level},"user_id", user_id, nil, user_id)
end

--爵位排行榜
function wing_lib_db.get_wing_ranklist()
	local sql  = "SELECT * FROM user_wing_info ORDER BY level DESC,exp_now DESC, sys_time LIMIT 50"
	sql = string.format(sql, user_id)
	dblib.execute(sql, function(dt) 
		if dt and #dt > 0 then
			for i = 1, #dt do
				wing_lib.wing_ranklist[i] = {}
				wing_lib.wing_ranklist[i].user_id   = dt[i].user_id
				wing_lib.wing_ranklist[i].level     = dt[i].level
	      wing_lib.wing_ranklist[i].exp_now   = dt[i].exp_now
	      wing_lib.wing_ranklist[i].nick_name = dt[i].nick_name
	      wing_lib.wing_ranklist[i].face      = dt[i].face
	      wing_lib.wing_ranklist[i].vip_level = dt[i].vip_level
			end
    end
	end, user_id)
end

--保存玩家获得成长值
function wing_lib_db.update_wing_info(user_id)
dblib.cache_set("user_wing_info",{exp_play = wing_lib.user_list[user_id].exp_play,
                                  exp_item = wing_lib.user_list[user_id].exp_item,
                                  exp_now  = wing_lib.user_list[user_id].exp_now,                                  
                                  },"user_id", user_id, nil, user_id)
end

--保存玩家等级(不走memcacahe)
function wing_lib_db.update_wing_level(user_id, level)
    local sql = "update user_wing_dress_info set level = %d where user_id = %d; commit;"
  	sql = string.format(sql, level, user_id)
  	dblib.execute(sql, nil, user_id)
    
    dblib.cache_set("user_wing_info",{level = level},"user_id", user_id, nil, user_id)
end

--保存玩家翅膀穿戴状态(不走memcacahe)
function wing_lib_db.update_wing_dress(user_id, dress_not)
  local sql = "update user_wing_dress_info set dress_on = %d where user_id = %d; commit;"
	sql = string.format(sql, dress_not, user_id)
	dblib.execute(sql, nil, user_id)
end

--保存玩家升级后的时间排行榜用
function wing_lib_db.update_sys_time(user_id)
  dblib.cache_set("user_wing_info",{sys_time = timelib.lua_to_db_time(os.time())},"user_id", user_id, nil, user_id)
end

--记录日志
function wing_lib_db.record_chris_event_log(user_id, item_gift_id, type_id, item_number)
    if(duokai_lib ~= nil and duokai_lib.is_sub_user(user_id) == 1) then
        user_id = duokai_lib.get_parent_id(user_id);
    end
  local sql = "insert into log_gaobei_diaoluo_info(user_id,item_gift_id,type_id,item_number,sys_time) value(%d,%d,%d,%d,now());"
	sql = string.format(sql, user_id, item_gift_id, type_id, item_number)
	dblib.execute(sql,function(dt) end, user_id)
end