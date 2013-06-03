TraceError("init hecheng_db_lib...")
if not hecheng_db_lib then
    hecheng_db_lib = _S
    {
    	--以下是方法
        
      hecheng					 		= NULL_FUNC,
      init_item_name 			= NULL_FUNC,
      init_user						= NULL_FUNC,
      init_hecheng_info		= NULL_FUNC,
	  after_get_props_list      = NULL_FUNC,
      --以下是变量及配置信息
 	  need_refresh_bag = 0,
      user_list = {},
    }    
end

--登录初始化，删除过期图纸
function hecheng_db_lib.init_user(user_id)
	local user_info = usermgr.GetUserById(user_id)
	if not user_info then return end
	--删除过期图纸
    local sys_time = os.time()
    local propslist = tex_gamepropslib.get_props_list(user_info)
    if (hecheng_db_lib.user_list[user_id] == nil) then
        hecheng_db_lib.user_list[user_id] = 0
    end
    if (hecheng_db_lib.user_list[user_id] == 1) then
        return
    end
    hecheng_db_lib.user_list[user_id] = 1
    local find = 0
    for v1,_  in pairs(propslist) do
        --如果是图纸，判断有效期
        if v1 > 100000 and v1 < 200000 and             
            hecheng_lib.CFG_TZ[v1] and hecheng_lib.CFG_TZ[v1].over_time and 
            timelib.db_to_lua_time(hecheng_lib.CFG_TZ[v1].over_time) < sys_time then
            find = 1
            --如果过期并且道具中有图纸就删除
            --更新数据库           
            local get_count_tuzhi = function(nCount)
                hecheng_db_lib.user_list[user_id] = nil
                tex_gamepropslib.set_props_count_by_id(v1, -nCount, user_info, nil)
            end
            tex_gamepropslib.get_props_count_by_id(v1, user_info, get_count_tuzhi)	
        end
    end
    if (find == 0) then
        hecheng_db_lib.user_list[user_id] = nil
    end
end

function hecheng_db_lib.init_hecheng_info(user_id, call_back)
	local user_info = usermgr.GetUserById(user_id)
	if user_info == nil then return end
	local after_get_bag = function(tab_list)
		if tab_list  then
			for k, v in pairs(tab_list) do
				--初始化碎片 
				if k < 100000 then
					if hecheng_lib.user_list[user_id].sp[k] == nil then hecheng_lib.user_list[user_id].sp[k] = {} end
					hecheng_lib.user_list[user_id].sp[k].item_id = k
					hecheng_lib.user_list[user_id].sp[k].item_count = v
				end
				--初始化图纸
				if k >= 100000 and k <= 200000 then
					if hecheng_lib.user_list[user_id].tz[k] == nil then hecheng_lib.user_list[user_id].tz[k] = {} end
					hecheng_lib.user_list[user_id].tz[k].item_id = k
					hecheng_lib.user_list[user_id].tz[k].item_count = v	
				end
			end
		end
		--[[if call_back ~= nil then
			call_back(user_id)
		end--]]
	end
	
	local after_get_car = function(tab_list)
		if tab_list  then
			for k, v in pairs(tab_list) do
				--初始化汽车 
				
				if hecheng_lib.user_list[user_id].car[v.car_id] == nil then hecheng_lib.user_list[user_id].car[v.car_id] = {} end
				hecheng_lib.user_list[user_id].car[v.car_id].car_id = v.car_id
				hecheng_lib.user_list[user_id].car[v.car_id].car_type = v.car_type
				hecheng_lib.user_list[user_id].car[v.car_id].hui_xin = v.hui_xin
				hecheng_lib.user_list[user_id].car[v.car_id].king_count = v.king_count
				hecheng_lib.user_list[user_id].car[v.car_id].is_using = v.is_using
				hecheng_lib.user_list[user_id].car[v.car_id].cansale = v.cansale
				hecheng_lib.user_list[user_id].car[v.car_id].car_prize = v.car_prize
--				hecheng_lib.user_list[user_id].car[v.car_id].is_matching = 0
			end
		end
		if call_back ~= nil then
			call_back(user_id)
		end
	end

	hecheng_lib.user_list[user_id] = {}
	hecheng_lib.user_list[user_id].user_id = user_id
	hecheng_lib.user_list[user_id].tz = {} --图纸
	hecheng_lib.user_list[user_id].sp = {} --碎片
	hecheng_lib.user_list[user_id].car = {} --汽车
	
	local propslist = tex_gamepropslib.get_props_list(user_info)
	after_get_bag(propslist)
	local match_car_list = {}
	--得到可以报澳门和维加斯的车
    if (car_match_lib.user_list[user_id] ~= nil and car_match_lib.user_list[user_id].car_list ~= nil) then        
        if car_match_lib then
            for k,v in pairs(car_match_lib.user_list[user_id].car_list) do
                if v.car_type~=nil and car_match_lib.CFG_CAR_INFO[v.car_type]~=nil then
                --and v.car_type ~= 5044 and v.car_type ~= 5045 
                    table.insert(match_car_list,v)
                end   		
            end
        end
    end
    after_get_car(match_car_list)
end

--合成
--function hecheng_db_lib.hecheng(user_id, old_need_peifang, do_hc_count, call_back)
--	if do_hc_count == nil then do_hc_count = 1 end
--	local need_peifang = table.clone(old_need_peifang)
--	local user_info = usermgr.GetUserById(user_id)
--	if user_info == nil then return end
--	for k, v in pairs(need_peifang) do 
--		local item = {
--			["item_id"] = need_peifang[i].cl_id,
--			["item_num"] = -1 * need_peifang[i].cl_count * do_hc_count,
--   		}		
--		bag.add_item(user_info, item, nil, bag.log_type.HECHENG)
--		if v.cl_type == 1 then
--			tex_gamepropslib.set_props_count_by_id(need_peifang[i].cl_id, -1 * do_hc_count * need_peifang[i].cl_count, user_info, nil)	
--		end
--	end
--	call_back(1)
--end

--初始化材料和图纸名称
function hecheng_db_lib.init_item_name()
	local sql = "select * from configure_items"
	dblib.execute(sql, function(dt)
		if dt and #dt>0 then
			for i = 1, #dt do 
				hecheng_lib.CFG_ITEM_NAME[dt[i].id]={}
				hecheng_lib.CFG_ITEM_NAME[dt[i].id].item_name=dt[i].name
			end
		end
	end)
end

function hecheng_db_lib.record_hecheng_log(user_id, item_id, do_hc_count)
	local sql = "insert into log_hecheng_log(user_id, item_id,do_hc_count, sys_time) value(%d, %d,%d, now());"
	sql = string.format(sql, user_id, item_id,do_hc_count)
	dblib.execute(sql, nil, user_id)
end

function hecheng_db_lib.record_hecheng_success_log(user_id, item_id, zj_count)
	local sql = "insert into log_hecheng_success_log(user_id, item_id,zj_count, sys_time) value(%d, %d,%d, now());"
	sql = string.format(sql, user_id, item_id, zj_count)
	dblib.execute(sql, nil, user_id)
end

function hecheng_db_lib.record_hecheng_failed_log(user_id, tz_id, failed_count)
	local sql = "insert into log_hecheng_failed_log(user_id, tz_id, failed_count, sys_time) value(%d, %d,%d, now());"
	sql = string.format(sql, user_id, tz_id, failed_count)
	dblib.execute(sql, nil, user_id)
end

--记录图纸变更，购买type_id为1，合成type_id为2
function hecheng_db_lib.record_tz_change(user_info, item_id, type_id)
			if not user_info or not item_id or not type_id then 
				return
			end
		local user_id = user_info.user_id
    local sqltemple = "INSERT INTO log_hecheng_tz (user_id, item_id, type_id, sys_time)value(%d, %d,% d, now()) ";
    sqltemple = string.format(sqltemple, user_info.userId, item_id, type_id);
    dblib.execute(sqltemple);
end

--命令列表
cmdHandler = 
{
 
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

