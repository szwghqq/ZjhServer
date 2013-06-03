TraceError("init hecheng_lib...")

if hecheng_lib and hecheng_lib.on_user_exit then
	eventmgr:removeEventListener("on_user_exit", hecheng_lib.on_user_exit);
end

if hecheng_lib and hecheng_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", hecheng_lib.on_after_user_login);
end

if hecheng_lib and hecheng_lib.timer then
	eventmgr:removeEventListener("timer_second", hecheng_lib.timer);
end

if hecheng_lib and hecheng_lib.already_init_gift then
    eventmgr:removeEventListener("already_init_gift", hecheng_lib.already_init_gift);
end

if hecheng_lib and hecheng_lib.already_init_car then
    eventmgr:removeEventListener("already_init_car", hecheng_lib.already_init_car);
end

if hecheng_lib and hecheng_lib.already_init_prop then
    eventmgr:removeEventListener("after_get_props_list", hecheng_lib.already_init_prop)
end



if not hecheng_lib then
    hecheng_lib = _S
    {
    	--以下是方法
        open_panl = NULL_FUNC,
        check_status = NULL_FUNC,
        check_datetime = NULL_FUNC,
        send_tz = NULL_FUNC,
        is_zhong = NULL_FUNC, --传一个概率进去，看有没有中
        hecheng_item = NULL_FUNC, --客户端请求合成
        get_need_peifang = NULL_FUNC, --得到需要的配方
        query_tz = NULL_FUNC,
        query_item = NULL_FUNC,
        get_count = NULL_FUNC,
        send_item = NULL_FUNC,
        check_peifang = NULL_FUNC,
        check_tuzhi   = NULL_FUNC,
        give_hecheng_reward = NULL_FUNC, 
        get_hecheng_count = NULL_FUNC,
        on_user_exit = NULL_FUNC,
        on_after_user_login = NULL_FUNC, 
        
        --以下是变量及配置信息
 		user_list = {},
		startime = "2012-11-01 09:00:00",  --活动开始时间
    	endtime = "2020-11-20 23:59:59",  --活动结束时间
    	start_time = "2012-11-01 09:00:00",  --活动开始时间
    	end_time = "2020-11-20 23:59:59",  --活动结束时间
    	start_bike = "2012-11-09 09:00:00",  --活动开始时间
    	end_bike   = "2012-11-14 23:59:59",  --活动结束时间
    
    	CFG_TZ_CLASS = {
    		[1] = "道具类",
    		[2] = "货币类",
    		[3] = "活动类",
    		[4] = "图纸类",
    		
    	},
    	CFG_TZ = {
    		[100001] = {
    			["tz_name"] = "赠票图纸",
    			["tz_desc"] = "赠票图纸：可以合成三分钟赠票1张。\n合成配方：水晶扑克+梅花A+梅花K+梅花Q+梅花J",
    			["hc_id"] = 5056,
    			["hc_name"] = "赠票*1",
    			["hc_desc"] = "赠票：可在3分钟活动中使用赠票游戏，赠票无法取出。 ",
    			["hc_fy_desc"] = "这个要花多少钱zentao还没定 ",
       			["peifang_desc"] = "水晶扑克+梅花A+梅花K+梅花Q+梅花J",
    			["peifang"] = "5055,5014,5024,5025,5026", --如果有2个相同的，就连写2个
    			["gailv"] = "0.5",
    			["class_id"] = 1,
    			
    		},
    		[100002] = {
    			["tz_name"] = "铲子图纸",
    			["tz_desc"] = "铲子图纸：可以合成铲子1把。\n合成配方：水晶扑克*2+红心A+红心K+红心Q+红心J",
    			["hc_id"] = 5057,
    			["hc_name"] = "铲子*1",
    			["hc_desc"] = "铲子：可在挖宝活动中使用，使用后随机挖到奖品。  ",
	 			["hc_fy_desc"] = "这个要花多少钱zentao还没定",
    			["peifang_desc"] = "水晶扑克*2+红心A+红心K+红心Q+红心J",
    			["peifang"] = "5055|2,5037,5038,5039,5027", 
    			["gailv"] = "0.5",
    			["class_id"] = 1,
    		},    		
    		[100003] = {
    			["tz_name"] = "10达人币图纸",
    			["tz_desc"] = "10达人币图纸：可以合成10个达人币。\n合成配方：水晶扑克*10+红心A+红心K+红心Q+红心J",
    			["hc_id"] = 100003,
    			["hc_name"] = "达人币*10",
    			["hc_desc"] = "达人币*10",
    			["hc_fy_desc"] = "这个要花多少钱zentao还没定",
    			["peifang_desc"] = "水晶扑克*10+红心A+红心K+红心Q+红心J",
    			["peifang"] = "5055|10,5037,5038,5039,5027", 
    			["gailv"] = "0.5",
    			["class_id"] = 2,
    		},
    	},
    	CFG_ITEM_NAME = {},
    	CFG_HUODONG_TZ = {    --活动时大家都有的图纸，如果不限制初始化次数就写成-1
    		[100002] = 3,
    		[100003] = 2,
    	}, 
    	CFG_ALL_CARS = {
        5012,--甲壳虫
        5013,--奥拓
        5018,--雪铁龙
        5021,--玛莎拉蒂
        5024,--法拉利
        5026,--兰博基尼
        5027,--布加迪威龙
        5036,--布加迪威龙黄金版
      },
    }
end
 
 
--查询活动是否进行中
function hecheng_lib.check_status(buf)
	--local user_info = userlist[getuserid(buf)]
	--if user_info == nil then return end

	local status = hecheng_lib.check_datetime()
   	netlib.send(function(buf)
            buf:writeString("HCHACTIVE");
            buf:writeInt(status or 0);		--int	0，活动无效（服务端也可不发）；1，活动有效
	end,buf:ip(),buf:port());
end

function hecheng_lib.open_panl(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId

	
	local call_back = function(user_id)
		eventmgr:dispatchEvent(Event("before_open_hecheng",	{user_info = user_info}))
		hecheng_lib.send_tz(user_id)
		hecheng_lib.send_item(user_id)
		hecheng_lib.send_car_info(user_id)
--		hecheng_lib.send_wing_info(user_id)
	end

	--如果没初始化过，就先初始化
--	if hecheng_lib.user_list[user_id] == nil then
		hecheng_db_lib.init_hecheng_info(user_id, call_back)
--	else
--		call_back(user_id)		
--	end
end

--检查有效时间，限时问题int	0，活动无效（服务端也可不发）；1，活动有效
function hecheng_lib.check_datetime()
	local sys_time = os.time();	
	local startime = timelib.db_to_lua_time(hecheng_lib.startime);
	local endtime = timelib.db_to_lua_time(hecheng_lib.endtime);
	
	if(sys_time > endtime or sys_time < startime) then
		return 0;
	end

	--活动时间过去了
	return 1;

end

--查询图纸
function hecheng_lib.query_tz(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId
	hecheng_lib.send_tz(user_id)
end

--查询背包里的材料
function hecheng_lib.query_item(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId
	hecheng_lib.send_item(user_id)
end

--查询汽车
function hecheng_lib.query_car(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId
	hecheng_lib.send_car_info(user_id)
end

--得到某个list有多少个元素
function hecheng_lib.get_count(tab)
	local count = 0
	for k, v  in pairs(tab) do
		count = count + 1
	end
	return count
end

function hecheng_lib.get_tuzhi_count(user_id, item_id, class_id)
	if not user_id then
		return -1;
	end
	
	local user_info = usermgr.GetUserById(user_id)
	if user_info == nil then return -1; end
	
--	if class_id ~= 4 and class_id ~= 5 then
--		--如果为-2则图纸为不消耗类别
--		return -2;
--	end
	
	if not hecheng_lib.user_list[user_id].tz[item_id] then
		hecheng_lib.user_list[user_id].tz[item_id] ={}
		hecheng_lib.user_list[user_id].tz[item_id].item_id = item_id;
		hecheng_lib.user_list[user_id].tz[item_id].item_count = 0;
	end
	return hecheng_lib.user_list[user_id].tz[item_id].item_count;
end
--发图纸信息
function hecheng_lib.send_tz(user_id)
	if not user_id then
		return 0;
	end
	local user_info = usermgr.GetUserById(user_id)
	if user_info == nil then return end
	--local tz_count = hecheng_lib.get_count(hecheng_lib.user_list[user_id].tz) --有多少图纸
  --local tz_count = 13
  --if wing_lib and --不是国王等级
  --tz_count = 14
  --end
	local tb_tz_id = {100105,100106,100107,100108,100109,100110,100111,100112,100113,100114,100115,100116,100117,100118,100119}
	if wing_lib and wing_lib.get_wing_level(user_id) >= 0 and wing_lib.get_wing_level(user_id) < 9 then
	  local wing_tz_id = 100120 --骑士翅膀
	  wing_tz_id = wing_tz_id + wing_lib.get_wing_level(user_id)
    table.insert(tb_tz_id,wing_tz_id)
  end
	hecheng_lib.send_tz_to_client(user_info, tb_tz_id)

end

function hecheng_lib.get_need_peifang(tz_id)
	local peifang_tab = {}
	local tmp_peifang_tab = split(hecheng_lib.CFG_TZ[tz_id].peifang, ",")
	for i = 1, #tmp_peifang_tab do
		local tmp_tab = split(tmp_peifang_tab[i], "|")
		local cl_id = tonumber(tmp_tab[1]) --材料ID
		local cl_count = 1 --材料数量
		local cl_type  = 1 --默认道具材料
		if #tmp_tab > 1 then
			cl_count = tonumber(tmp_tab[2])
		end
		if #tmp_tab > 2 then
			cl_type = tonumber(tmp_tab[3])
		end				
		local tmp_tab = {
			["cl_id"] = cl_id,
			--["cl_name"] = hecheng_lib.CFG_ITEM_NAME[cl_id].item_name,--材料名称 todo	
			["cl_count"] = cl_count,
			["cl_type"]  = cl_type,	
		}
		
		table.insert(peifang_tab, tmp_tab)				
	end
	return peifang_tab
end

--发背包道具
function hecheng_lib.send_item(user_id)
	local user_info = usermgr.GetUserById(user_id)
	if user_info == nil then return end
	local item_num = hecheng_lib.get_count(hecheng_lib.user_list[user_id].sp)
	netlib.send(function(buf)
		buf:writeString("HCHITEM")
		buf:writeInt(item_num)
		
		for k,v in pairs (hecheng_lib.user_list[user_id].sp) do
			buf:writeInt(v.item_id)
			buf:writeInt(v.item_count)
			
		end
	end, user_info.ip, user_info.port)
end

--发汽车信息
function hecheng_lib.send_car_info(user_id)
	local user_info = usermgr.GetUserById(user_id)
	if user_info == nil then return end
	local car_num = hecheng_lib.get_count(hecheng_lib.user_list[user_id].car)
	netlib.send(function(buf)
		buf:writeString("HCHCAR")
		if  car_num > 32*8 then 
			car_num = 32*8
		end
		buf:writeInt(car_num)
		local times = 0;
		for k,v in pairs (hecheng_lib.user_list[user_id].car) do
			if times == 32*8 then
				break
			end	
			buf:writeInt(v.car_id)
			buf:writeInt(v.car_type)
			--buf:writeInt(v.hui_xin)
			--buf:writeInt(v.king_count)
			buf:writeByte(v.is_using)
			--buf:writeInt(v.cansale)
			--buf:writeInt(v.car_prize)
			local bMatch = 0;

			--如果汽车已经报名赛车 就不添加
			if car_match_lib and (car_match_lib.is_match_start(1) == 1 or 
                car_match_lib.is_match_start(2) == 1) then
				for i=1, 2 do
                    for j=1,8 do
						if car_match_lib.match_list[i].match_car_list[j].car_id ~= nil and
                            car_match_lib.match_list[i].match_car_list[j].car_id == hecheng_lib.user_list[user_id].car[v.car_id].car_id then							
							bMatch = 1
                            break
						end
                    end
                    if (bMatch == 1) then
                        break
                    end
				end
			end
			buf:writeByte(bMatch)	
			times = times + 1	
		end
	end, user_info.ip, user_info.port)
end


--传一个概率进去，看有没有中
function hecheng_lib.is_zhong(gailv)
	local gen_rand_num = function()
		local tmp_tab = {}		
		for i = 1, 50 do
			table.insert(tmp_tab, math.random(1,10000))
		end
		return tmp_tab
	end
	
	local can_num = 10000 * gailv
	local rand_num_tab = gen_rand_num()
	local rand_num = rand_num_tab[math.random(10,50)]
	
	if rand_num <= can_num then
		return 1
	end
	
	return 0
end

function hecheng_lib.hecheng_item(buf)

	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId
	local tz_id = buf:readInt()
	local do_hc_count = buf:readInt() --合成次数
	local need_car_number = buf:readInt() --材料里面需要几种车
	local tb_need_car_id ={}
	if need_car_number > 0 then
		for i=1, need_car_number do
			local car_id = buf:readInt()
			table.insert(tb_need_car_id,car_id)
		end
	end
	if need_car_number > 0 and do_hc_count > 1 then
		TraceError("有车为材料的情况下，合成次数不能大于1")
		return
	end
	
	--如果是翅膀则判断翅膀是否可以合成的条件（成长值）
	if wing_lib and wing_lib.check_wing(tz_id) == 1 then
	  if do_hc_count ~= 1 then return end
	  if wing_lib.check_wing_hengcheng(user_id, tz_id) == 0 then
	    return
	  end
	end
	
	if do_hc_count <= 0 then
		return
	end
	
	if hecheng_lib.check_datetime() ~= 0 then
		eventmgr:dispatchEvent(Event("before_hecheng_event", {user_info = user_info, tz_id = tz_id, do_hc_count = do_hc_count}))
	end
	
	local send_result = function(result)
		local zj_count = 0
		if result == 1 then
			--如果扣材料成功了，先记一下日志，代表他做了一次合成
			hecheng_db_lib.record_hecheng_log(user_id, tz_id, do_hc_count)
			--如果扣材料成功了，再看看他人品好不好
			local gailv = hecheng_lib.CFG_TZ[tz_id].gailv
	
			for i = 1, do_hc_count do
				zj_count = zj_count + hecheng_lib.is_zhong(gailv)
			end
			--人品也好，可以发奖了
			if zj_count > 0 then
				for i = 1, zj_count do
					hecheng_lib.give_hecheng_reward(user_id, tz_id)
				end
				if (tz_id >= 100109) and (tz_id <= 100112)  then
					local car_name = hecheng_lib.CFG_TZ[tz_id].hc_name
					local msg = _U("天地合力，乾坤借法，玩家")..user_info.nick.._U("手抚合成的").._U(car_name).._U("(")..zj_count.._U("辆)").._U("仰天长笑。")
					tex_speakerlib.send_sys_msg(msg)
				end
				--如果是布加迪威龙 -- 奖励兰博基尼一辆
				if tz_id == 100113 then
				  car_match_db_lib.add_car(user_id,5026,0)
				  local car_name = hecheng_lib.CFG_TZ[tz_id].hc_name
					local msg = _U("天地合力，乾坤借法，玩家")..user_info.nick.._U("手抚合成的").._U(car_name).._U("(")..zj_count.._U("辆)").._U("仰天长笑，系统额外赠送兰博基尼一辆。")
					tex_speakerlib.send_sys_msg(msg)
				end
				--如果是黄金版布加迪--给一辆保时捷 和 称号 幸运之星
				if tz_id == 100114 then
					car_match_db_lib.add_car(user_id,5027,0)
					local car_name = hecheng_lib.CFG_TZ[tz_id].hc_name
					local msg = _U("天地合力，乾坤借法，玩家")..user_info.nick.._U("手抚合成的").._U(car_name).._U("(")..zj_count.._U("辆)").._U("仰天长笑，系统额外赠送布加迪威龙一辆。")
					tex_speakerlib.send_sys_msg(msg)
				end
				if tz_id == 100115 then
					for k,v in ipairs (hecheng_lib.CFG_ALL_CARS) do 
						  car_match_db_lib.add_car(user_id,v,0)
          end
          local car_name = hecheng_lib.CFG_TZ[tz_id].hc_name
					local msg = _U("天地合力，乾坤借法，玩家")..user_info.nick.._U("手抚合成的").._U(car_name).._U("(")..zj_count.._U("辆)").._U("仰天长笑，系统额外赠送德州全系车各一辆。")
					tex_speakerlib.send_sys_msg(msg)
				end
				--记日志他成功合成了多少次
				hecheng_db_lib.record_hecheng_success_log(user_id, tz_id, zj_count)
			end
			
			--合成失败了记录
			if do_hc_count-zj_count > 0 then
				hecheng_db_lib.record_hecheng_failed_log(user_id, tz_id, do_hc_count-zj_count)
			end
			eventmgr:dispatchEvent(Event("after_hecheng_event", {user_info = user_info, tz_id = tz_id, do_hc_count = do_hc_count, fail_hc_count = do_hc_count-zj_count}))
	
			--刷新背包
			--bag.get_all_item_info(user_info, function(bag_items) end, 1)
			--local propslist = tex_gamepropslib.get_props_list(user_info);
			
			
		elseif result < 0 then
			zj_count = result
		end
		netlib.send(function(buf)
			buf:writeString("HCHHC")
			buf:writeInt(zj_count)
		end, user_info.ip, user_info.port)
		
		--让客户端刷新一下，客户端处理动画的机制有些问题，所以让客户端请求更新，服务端不主动更新了
		--hecheng_lib.send_tz(user_id)
		--hecheng_lib.send_item(user_id)
	end	

	if hecheng_lib.check_datetime() == 0 then
		send_result(-1)
		return 0;
	end
	
	
	
	local need_peifang = hecheng_lib.get_need_peifang(tz_id)
	
	if hecheng_lib.user_list[user_id].tz[tz_id].status ~= nil then
		send_result(hecheng_lib.user_list[user_id].tz[tz_id].status)
		return
	end 
	
	--看一下合成次数是不是用完了
	if hecheng_lib.user_list[user_id].tz[tz_id].today_can_use ~= nil and hecheng_lib.user_list[user_id].tz[tz_id].today_can_use <= 0 then
		send_result(0)
		return
	end 
	
	--看看玩家身上的材料够不够
	local check_cl = hecheng_lib.check_peifang(user_id, need_peifang, do_hc_count)
	if check_cl == 0 then
		send_result(check_cl)
		return
	end
	
	--看看玩家身上的图纸是否过期
	local sys_time = os.time()
	if hecheng_lib.CFG_TZ[tz_id].over_time and timelib.db_to_lua_time(hecheng_lib.CFG_TZ[tz_id].over_time) < sys_time then
				send_result(-1)
				return
	end
	
	--看看玩家是否达到需要合成的vip等级
	if hecheng_lib.CFG_TZ[tz_id].need_vip and viplib then
	   local vip_level = viplib.get_vip_level(user_info) or 0
	   if vip_level < hecheng_lib.CFG_TZ[tz_id].need_vip then
	    return
	   end
	end
	
	--看看玩家身上的图纸材料够不够
	if hecheng_lib.CFG_TZ[tz_id].class_id ~= 6 then
			local check_tz = hecheng_lib.check_tuzhi(user_id, tz_id, do_hc_count)
			if check_tz <= 0 then
				send_result(0)
				return
			end
	end
	--todo看费用够不够，够的话就先扣费用，再扣材料
	--根据图终的费用信息和合成次数来计算
	
	--先扣材料再合成
	for k, v in pairs(need_peifang) do
		if v.cl_type == 1 then
			hecheng_lib.user_list[user_id].sp[v.cl_id].item_count = hecheng_lib.user_list[user_id].sp[v.cl_id].item_count - v.cl_count * do_hc_count
			tex_gamepropslib.set_props_count_by_id(v.cl_id,  -1*v.cl_count*do_hc_count, user_info, nil)
		else
			--删除车
			for _,car_id in pairs (tb_need_car_id) do
				hecheng_lib.user_list[user_id].car[car_id] = {}
				car_match_db_lib.del_car(user_id,car_id)
			end
		end
	end
	
	
	--扣图纸,内存 和背包
	--if hecheng_lib.CFG_TZ[tz_id].class_id == 4 or hecheng_lib.CFG_TZ[tz_id].class_id == 5 then
		hecheng_lib.user_list[user_id].tz[tz_id].item_count = hecheng_lib.user_list[user_id].tz[tz_id].item_count - do_hc_count
		tex_gamepropslib.set_props_count_by_id(tz_id,  -1*do_hc_count, user_info, nil)
	--end
	
	send_result(1)

	
end

--检查一下材料够不够
function hecheng_lib.check_peifang(user_id, need_peifang, do_hc_count)
	if do_hc_count == nil then do_hc_count = 1 end --默认为计算只合成一次所需要的材料够不够
	for k, v in pairs (need_peifang) do
		if v.cl_type == 1 then
			if hecheng_lib.user_list[user_id].sp[v.cl_id] == nil then
				return 0
			end
			
			if hecheng_lib.user_list[user_id].sp[v.cl_id].item_count < v.cl_count * do_hc_count then
				return 0
			end
		elseif v.cl_type == 2 then
			--循环玩家车辆是否有该id的车
				 local car_number = 0
			   for index,car in pairs (hecheng_lib.user_list[user_id].car) do
			   		if car.car_type == v.cl_id then
			   			car_number = car_number + 1
			   		end
			 	 end
			 	 if car_number < v.cl_count * do_hc_count then
			 	 	return 0
			 	 end
		end
	end
	return 1
	
end

--检查一下图纸够不够
function hecheng_lib.check_tuzhi(user_id, tz_id, do_hc_count)
	if do_hc_count == nil then do_hc_count = 1 end --默认为计算只合成一次所需要的材料够不够
			 
		if hecheng_lib.user_list[user_id].tz[tz_id] == nil then
			return 0
		end
		
		if hecheng_lib.user_list[user_id].tz[tz_id].item_count <  do_hc_count then
			return 0
		end

	return 1
	
end

--得到能合成多少个物品
function hecheng_lib.get_hecheng_count(user_id, tz_id)
	local last_num = -1
	local need_peifang = hecheng_lib.get_need_peifang(tz_id)

	for k, v in pairs (need_peifang) do
		--由最少的材料决定能组合出多少道具
		if hecheng_lib.user_list[user_id].sp[v.cl_id] == nil then
			return 0 --缺少某一种材料，直接认为1个物品都合不出来
		end
	
		local tmp_num = math.floor(hecheng_lib.user_list[user_id].sp[v.cl_id].item_count/v.cl_count)
		if tmp_num < last_num or last_num == -1 then
			last_num = tmp_num
		end
	end
	return last_num
end


--合成成功了，给奖励
function hecheng_lib.give_hecheng_reward(user_id, tz_id)
			if (not user_id) and (not tz_id) then
				return
			end
			local user_info = usermgr.GetUserById(user_id)
			if tz_id<100000 then return end
				
			--月饼
			if tz_id >= 100020 and tz_id <= 100022 then
				
				local nItemId = hecheng_lib.CFG_TZ[tz_id].hc_id;
		
				--更新合成月饼(礼物)
				gift_addgiftitem(user_info, nItemId, user_info.userId, user_info.nick)

			end
			
			--汽车
			if hecheng_lib.CFG_TZ[tz_id].class_id == 5 then
				local nItemId = hecheng_lib.CFG_TZ[tz_id].hc_id;
				car_match_db_lib.add_car(user_id,nItemId,0)
				if tz_id == 100116 or tz_id == 100117 then
					parkinglib.give_free_parking(user_info)
				end
				--给了汽车，同时又是合成材料，在刷新合成内存
				hecheng_db_lib.init_hecheng_info(user_id)
			end
			
			--加道具
			if hecheng_lib.CFG_TZ[tz_id].class_id == 1 or hecheng_lib.CFG_TZ[tz_id].class_id == 6 then
				tex_gamepropslib.set_props_count_by_id(hecheng_lib.CFG_TZ[tz_id].hc_id, 1, user_info, nil)
			end
			
end

--得到合成图纸今天用了多少
function hecheng_lib.get_hechengtz_use_count(user_id, tz_id)
	if not hecheng_lib.user_list[user_id].tz[tz_id] then
		return -1
	end
	
	local today_can_use = hecheng_lib.user_list[user_id].tz[tz_id].today_can_use
	if today_can_use == nil or today_can_use < 0 then
		return -1
	end
	local item_count = hecheng_lib.user_list[user_id].tz[tz_id].item_count or 0
	local already_used = item_count - today_can_use
	return already_used
end

--得到图纸每天会被初始化成多少
function hecheng_lib.get_hechengtz_count(tz_id)
	return hecheng_lib.CFG_HUODONG_TZ[tz_id] or -1
end

--初始化玩家的图纸
function hecheng_lib.init_hechengtz(user_id, tz_id_tab, status)
	for k, v in pairs(tz_id_tab) do		
		if hecheng_lib.user_list[user_id].tz[v.tz_id] == nil then
			hecheng_lib.user_list[user_id].tz[v.tz_id] = {}
		end
		hecheng_lib.user_list[user_id].tz[v.tz_id].item_id = v.tz_id
		hecheng_lib.user_list[user_id].tz[v.tz_id].item_count = v.tz_count
		hecheng_lib.user_list[user_id].tz[v.tz_id].today_can_use = v.today_can_use
		
		if status ~= nil then
			hecheng_lib.user_list[user_id].tz[v.tz_id].status = status
		end
	end
	
end


function hecheng_lib.on_user_exit(e)
	local user_id = e.data.user_id;
    if(hecheng_lib.user_list[user_id] ~= nil) then
        hecheng_lib.user_list[user_id] = nil;
    end
end

---todo需要优化，放到外面
function hecheng_lib.timer(e)
    if (tex == nil) then return end
    local start_time  = timelib.db_to_lua_time(hecheng_lib.start_time)
    local end_time    = timelib.db_to_lua_time(hecheng_lib.end_time)
    local start_bike  = timelib.db_to_lua_time(hecheng_lib.start_bike)
    local end_bike    = timelib.db_to_lua_time(hecheng_lib.end_bike)
  
    if start_bike > e.data.time or e.data.time > end_bike then
        -- 删除商城图纸
        tex.cfg.giftlist[100116] = nil --凤凰
        tex.cfg.giftlist[100117] = nil --永久
        tex.cfg.giftlist[4026] = nil   --单身帅哥
        tex.cfg.giftlist[4027] = nil   --单身美女
    end
    if start_bike < e.data.time and e.data.time < end_bike then	
        tex.cfg.giftlist[100116] = 100 --凤凰
        tex.cfg.giftlist[100117] = 100 --永久
        tex.cfg.giftlist[4026] = 11   --单身帅哥
        tex.cfg.giftlist[4027] = 11   --单身美女
    end
end

function hecheng_lib.on_after_user_login(e)
	if (not e) and (not e.data.userinfo) then 
		return 0;
	end
	
	local user_info = e.data.userinfo;
	local user_id = user_info.userId;
	hecheng_db_lib.init_hecheng_info(user_id, nil)
	--登录送到道具
	local sys_time = os.time();	
	local start_bike  = timelib.db_to_lua_time(hecheng_lib.start_bike)
	local end_bike    = timelib.db_to_lua_time(hecheng_lib.end_bike)
	if start_bike < sys_time and sys_time < end_bike then
		local sql = "select already_give from user_guanggun_info where user_id = %d"
		sql = string.format(sql, user_id)
		dblib.execute(sql, function(dt)
			if not dt or #dt == 0 then
				--给道具
				if  tonumber(user_info.sex) == 1  then-- 男的
					tex_gamepropslib.set_props_count_by_id(19, 1, user_info, nil)
					tex_gamepropslib.set_props_count_by_id(20, 1, user_info, nil)
				else 
					tex_gamepropslib.set_props_count_by_id(21, 1, user_info, nil)
					tex_gamepropslib.set_props_count_by_id(22, 1, user_info, nil)
                end
                
				--写入数据库
				local sql = "insert into user_guanggun_info(user_id,already_give) value(%d,1)"
				sql = string.format(sql,user_id)
				dblib.execute(sql,function(dt)end,user_id)
			end
		end, user_info.userId)
	end
end

function hecheng_lib.already_init_gift(e)
    local user_id = e.data.user_id
    local user_info = usermgr.GetUserById(user_id)
    if (user_info ~= nil) then
        local start_bike  = timelib.db_to_lua_time(hecheng_lib.start_bike)
        local end_bike    = timelib.db_to_lua_time(hecheng_lib.end_bike)
        local gift_info = user_info.gameInfo.giftinfo
        for k, v in pairs(gift_info) do
            --单身帅哥
            if ((v.id == 4026 or v.id == 4027) and os.time() > end_bike) then                
                gift_removegiftitem(user_info, k)
            end
        end
    end
end

function hecheng_lib.already_init_car(e)
    local user_id = e.data.user_id
    local user_info = usermgr.GetUserById(user_id)
    local sys_time = os.time()
    local end_bike    = timelib.db_to_lua_time(hecheng_lib.end_bike)
    if (user_info ~= nil and sys_time > end_bike) then
        --取出玩家道具列表
        local propslist = tex_gamepropslib.get_props_list(user_info)
        for v1,_  in pairs(propslist) do
            --如果有过期汽车也删除
            if (car_match_lib.user_list and car_match_lib.user_list[user_id] and 
                car_match_lib.user_list[user_id].car_list) then
                for k,v in pairs (car_match_lib.user_list[user_id].car_list) do
                    if v.car_type == 5044 or v.car_type == 5045 then
                        car_match_db_lib.del_car(user_id, k)
                    end
                end
            end
        end
    end
end

function hecheng_lib.already_init_prop(e)
	local user_id = e.data.user_id
	local user_info = usermgr.GetUserById(e.data.user_id)
	if not user_info then return end
    local user_id = e.data.user_id
    local user_info = usermgr.GetUserById(user_id)
    local sys_time = os.time()
    local end_bike    = timelib.db_to_lua_time(hecheng_lib.end_bike)
    if (user_info ~= nil and sys_time > end_bike) then
        --取出玩家道具列表
        local propslist = tex_gamepropslib.get_props_list(user_info)
        for v1,_  in pairs(propslist) do
            --如果是合成道具中 删除
            if (v1 == 19 or v1 == 20 or v1 == 21 or v1 == 22) then
                --更新数据库
                local get_count_daoju = function(nCount)
                    tex_gamepropslib.set_props_count_by_id(v1, -nCount, user_info, nil)
                end
                tex_gamepropslib.get_props_count_by_id(v1, user_info, get_count_daoju)
            end            
        end
    end	   
    hecheng_db_lib.init_user(user_id)
end


function hecheng_lib.send_tz_to_client(user_info, tb_tz_id)
  local sys_time = os.time()
  local user_id = user_info.userId
    netlib.send(function(buf)
  		buf:writeString("HCHTZ")
  		buf:writeInt(#tb_tz_id)
     for k,tz_id in ipairs (tb_tz_id) do
	    local class_id = hecheng_lib.CFG_TZ[tz_id].class_id
			buf:writeByte(class_id)--类型ID
			buf:writeString(_U(hecheng_lib.CFG_TZ_CLASS[class_id]))--类型名称
			buf:writeInt(tz_id) --图纸ID
			local hc_tz_use_count = hecheng_lib.get_hechengtz_use_count(user_id, tz_id)
			buf:writeInt(hc_tz_use_count) --今天已合成物品的数量
			local hc_tz_count = 0
			if hecheng_lib.user_list[user_id].tz[tz_id] and hecheng_lib.user_list[user_id].tz[tz_id].item_count then
				hc_tz_count = hecheng_lib.user_list[user_id].tz[tz_id].item_count
			end
			buf:writeInt(hc_tz_count) --可合成多少个物品的数量
			local hc_count = hecheng_lib.get_hecheng_count(user_id, tz_id)
			buf:writeInt(hc_count) --可合成多少个物品的数量（按材料计算）
			local tuzhi_count = hecheng_lib.get_tuzhi_count(user_id, tz_id, class_id)
			if hecheng_lib.CFG_TZ[tz_id].over_time and timelib.db_to_lua_time(hecheng_lib.CFG_TZ[tz_id].over_time) < sys_time then
				tuzhi_count = -1
			end
			buf:writeInt(tuzhi_count) --图纸数量如果有的话,非图纸类不用此参数
			buf:writeString(_U(hecheng_lib.CFG_TZ[tz_id].tz_name)) --图纸名称
			buf:writeString(_U(hecheng_lib.CFG_TZ[tz_id].tz_desc)) --图纸描述
			buf:writeInt(hecheng_lib.CFG_TZ[tz_id].hc_id) --合成物品ID
			buf:writeString(_U(hecheng_lib.CFG_TZ[tz_id].hc_name)) --合成物品名称
			buf:writeString(_U(hecheng_lib.CFG_TZ[tz_id].hc_desc)) --合成物品描述
			buf:writeString(_U(hecheng_lib.CFG_TZ[tz_id].hc_fy_desc)) --合成物品费用描述
			if hecheng_lib.CFG_TZ[tz_id].gailv_false then
				buf:writeString(hecheng_lib.CFG_TZ[tz_id].gailv_false) --假合成概率
			else
				buf:writeString(hecheng_lib.CFG_TZ[tz_id].gailv) --真合成概率
			end
			local peifang_tab = hecheng_lib.get_need_peifang(tz_id)
			buf:writeInt(#peifang_tab) --合成配方长度len
			for i = 1, #peifang_tab do
				buf:writeInt(peifang_tab[i].cl_id) --材料ID	
				--buf:writeString(peifang_tab[i].cl_name) --材料名称	
				buf:writeInt(peifang_tab[i].cl_count) --材料数量
				buf:writeInt(peifang_tab[i].cl_type) --材料类型				
			end
			buf:writeInt(hecheng_lib.CFG_TZ[tz_id].need_chengzhang or 0)--成长值
			buf:writeInt(hecheng_lib.CFG_TZ[tz_id].need_vip or 0)--VIP等级
			local fy_len = #hecheng_lib.CFG_TZ[tz_id].hc_fy
			if fy_len == 1 and hecheng_lib.CFG_TZ[tz_id].hc_fy[1].hc_fy_type == 0 then
				buf:writeInt(0)
			else
				buf:writeInt(fy_len)
				for i = 1, fy_len do
					buf:writeInt(hecheng_lib.CFG_TZ[tz_id].hc_fy[i].hc_fy_type)
					buf:writeInt(hecheng_lib.CFG_TZ[tz_id].hc_fy[i].fy)
				end
			end
		 end
		end, user_info.ip, user_info.port)
end
--命令列表
cmdHandler = 
{
    ["HCHACTIVE"] = hecheng_lib.check_status, --查询活动是否进行中
    ["HCHOPEN"]   = hecheng_lib.open_panl,    --打开主面板
    ["HCHTZ"]     = hecheng_lib.query_tz,     --客户端，请求图纸信息
	  ["HCHITEM"]   = hecheng_lib.query_item,   --返回背包道具
	  ["HCHCAR"]    = hecheng_lib.query_car,     --返回汽车
	  ["HCHHC"]     = hecheng_lib.hecheng_item, -- 客户端请求合成
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("on_user_exit", hecheng_lib.on_user_exit);

eventmgr:addEventListener("timer_second", hecheng_lib.timer); 
---todo需要优化，放到外面
eventmgr:addEventListener("h2_on_user_login", hecheng_lib.on_after_user_login);
eventmgr:addEventListener("after_get_props_list", hecheng_lib.already_init_prop)
eventmgr:addEventListener("already_init_gift", hecheng_lib.already_init_gift)
eventmgr:addEventListener("already_init_car", hecheng_lib.already_init_car)

