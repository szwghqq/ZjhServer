TraceError("init zhongqiu_lib...")
if zhongqiu_lib and zhongqiu_lib.ongameover then 
	eventmgr:removeEventListener("on_game_over_event", zhongqiu_lib.ongameover);
end

if zhongqiu_lib and zhongqiu_lib.restart_server then
	eventmgr:removeEventListener("on_server_start", zhongqiu_lib.restart_server);
end

if zhongqiu_lib and zhongqiu_lib.timer then
	eventmgr:removeEventListener("timer_second", zhongqiu_lib.timer);
end

if zhongqiu_lib and zhongqiu_lib.on_user_exit then
	eventmgr:removeEventListener("on_user_exit", zhongqiu_lib.on_user_exit);
end

if zhongqiu_lib and zhongqiu_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", zhongqiu_lib.on_after_user_login);
end


if not zhongqiu_lib then
    zhongqiu_lib = _S
    {
    	--以下是方法
  		ongameover = NULL_FUNC,
  		restart_server = NULL_FUNC,
  		timer = NULL_FUNC,
  		on_user_exit = NULL_FUNC,
  		on_after_user_login = NULL_FUNC,
        
      --以下是变量及配置信息
			user_list = {},
			--flag_count = 0, --已插旗数量
			--notify_flag = 0,
			
			CFG_ROOM_BET = {
			[1] = 10, 
			[2] = 100, --小于100是业余
			[3] = 1000, --小于1000是职业,大于等于1000是专家
			},
			start_time          = "2012-09-27 09:00:01",
			end_zhongqiu_time   = "2012-10-01 00:00:01",
			--qiche_tuzhi_time    = "2012-10-01 09:00:00",
			yuebing_tuzhi_time 	= "2012-10-06 23:59:59",
			end_guoqing_time 	  = "2012-10-07 23:59:59",
			end_qichetuzhi_time = "2012-10-30 23:59:59",
			end_suipian_time    = "2012-10-31 23:59:59",
			
			CQ_PM_LEN  = 10,
			cq_pm_list = {},
			
			
			CFG_PANSHU = 20,  --需要盘数
			
			--奖励
			CFG_GIVE_NAME = {
			[1] = "方块A", 
			[2] = "梅花A", 
			[3] = "红桃A", 
			[4] = "黑桃A",
			[5] = "水晶扑克",
			[6] = "黄金扑克",
			},
			
			--奖励
			CFG_GIVE_ITEMID = {
			[1] = 5001, 
			[2] = 5014, 
			[3] = 5027, 
			[4] = 5040,
			[5] = 5055,
			[6] = 5056,
			
			},
			
			--“金银铜”打满10局，碎片掉落概率，1是方片A，2是梅花A，3是红桃A, 4是黑桃A ,5是水晶扑克, 6是黄金扑克
			--相关概率
			GFG_PORBABILITY_LIST = {
			[1] = {
						[1] = 800;
						[2] = 150;
						[3] = 40;
						[4] = 10;
						},
			[2] = {
						[1] = 650;
						[2] = 130;
						[3] = 150;
						[4] = 50;
						[5] = 20;
						},
			[3] = {	
						[1] = 440;
						[2] = 200;
						[3] = 220;
						[4] = 89;
						[5] = 50;
						[6] = 1;
						}
			},
			--中秋月饼图纸
			GFG_TUZHI_LIST1 = {
			[1] = 100020;
			[2] = 100021;
			[3] = 100022;
--			[4] = 100023;
--			[5] = 100024;
			},
			
			--国庆汽车图纸
			GFG_TUZHI_LIST2 = {
			[1] = 100100;
			[2] = 100101;
			[3] = 100102;
			[4] = 100103;
			[5] = 100104;
			[6] = 100105;
			[7] = 100106;
			},
			GFG_TUZHI_NAME = {
			[100020] = "晶月祝福图纸";
			[100021] = "雅月祝福图纸";
			[100022] = "素月祝福图纸";
			[100100] = "奥拓图纸";
			[100101] = "雪铁龙C2图纸";
			[100102] = "甲壳虫图纸";
			[100103] = "玛莎拉蒂图纸";
			[100104] = "法拉利图纸";
			[100105] = "保时捷图纸";
			[100106] = "兰博基尼图纸";
			
			},
			GFG_BOX_ID = {
				14,15,16,17,18
			},
			
			--宝箱概率，13是木宝箱的ID
			GUOQING_PORBABILITY_LIST={
				[14] = {1000};
				[15] = {1000};
				[16] = {500,250,250};
				[17] = {500,250,250};
				[18] = {500,250,250};
			},
			
			
			--配置宝箱奖励列表 格式：物品id,数量。13是木宝箱的ID
			GUOQING_REWARD_LIST = {
			[14] = {
						[1] = {
										{100100,1,"奥拓图纸"};
										{5055,1,"水晶扑克"};
									};
						};
			[15] = {
						[1] = {
										{100101,1,"雪铁龙C2图纸"};
										{5055,2,"水晶扑克"};
									};
						};
			[16] = {
						[1] = {
										{100102,1,"甲壳虫图纸"};
										{5055,4,"水晶扑克"};
									};
						[2] = {
										{100102,1,"甲壳虫图纸"};
										{5055,4,"水晶扑克"};
									};
						[3] = {
										{100102,1,"甲壳虫图纸"};
										{5055,5,"水晶扑克"};
									};
						};
			[17] = {
						[1] = {
										{100103,1,"玛莎拉蒂图纸"};
										{5055,10,"水晶扑克"};
									};
						[2] = {
										{100104,1,"法拉利图纸"};
										{5055,11,"水晶扑克"};
									};
						[3] = {
										{100105,1,"保时捷图纸"};
										{5055,12,"水晶扑克"};
									};
						};
			[18] = {
						[1] = {
										{100104,1,"法拉利图纸"};
										{5056,2,"黄金扑克"};
									};
						[2] = {
										{100106,1,"兰博基尼图纸"};
										{5056,3,"黄金扑克"};
									};
						[3] = {
										{100105,1,"保时捷图纸"};
										{5056,4,"黄金扑克"};
									};
						};
			},
    }
end 

	

--1 业余 2职业 3专家
function zhongqiu_lib.get_room_type(small_bet)
	if not small_bet then
		return 0;
	end
	
	if small_bet < zhongqiu_lib.CFG_ROOM_BET[1] then
		return -1;
	elseif small_bet < zhongqiu_lib.CFG_ROOM_BET[2] then
		return 1;
	elseif small_bet < zhongqiu_lib.CFG_ROOM_BET[3] then
		return 2;
	elseif small_bet >= zhongqiu_lib.CFG_ROOM_BET[3] then
		return 3;
	end

end 


--重启加载商城礼物列表
function zhongqiu_librestart_server(e)
	gift_list_info[100020] = 500000 --黄金月饼图纸
	gift_list_info[100021] = 100000 --白银月饼图纸
	gift_list_info[100022] = 10000  --黄铜月饼图纸
	gift_list_info[100100] = 1000	   --奥拓图纸
	gift_list_info[100101] = 5000	   --雪铁龙C2图纸
	gift_list_info[100102] = 30000	   --甲壳虫图纸
	gift_list_info[100103] = 250000	 --玛莎拉蒂图纸
	gift_list_info[100104] = 600000	 --法拉利图纸
	gift_list_info[100105] = 1000000	 --保时捷图纸
	gift_list_info[100106] = 1500000  --兰博基尼图纸
	
end
function zhongqiu_lib.on_after_user_login(e)
	if (not e) and (not e.data.userinfo) then 
		return 0;
	end
	
	local user_info = e.data.userinfo;
	local user_id = user_info.userId;
	
	--从数据库中初始化用户在各个场中的盘数
	zhongqiu_db_lib.init_user(user_id);
	
	--从数据库中读取所有图纸信息，判断图纸是否过期
	timelib.createplan(function()
			zhongqiu_db_lib.init_user_tuzhi(user_id)
		end,6)
	

end

function zhongqiu_lib.timer(e)
	local start_time         = timelib.db_to_lua_time(zhongqiu_lib.start_time)
	local end_zhongqiu_time  = timelib.db_to_lua_time(zhongqiu_lib.end_zhongqiu_time);
	local yuebing_tuzhi_time = timelib.db_to_lua_time(zhongqiu_lib.yuebing_tuzhi_time)
	local end_guoqing_time   = timelib.db_to_lua_time(zhongqiu_lib.end_guoqing_time)
	local end_qichetuzhi_time   = timelib.db_to_lua_time(zhongqiu_lib.end_qichetuzhi_time)
	
	if start_time < e.data.time and e.data.time < end_zhongqiu_time then
		--更新汽车图纸 删除月饼图纸
		gift_list_info[100020] = {price = 500000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0}--黄金月饼图纸
		gift_list_info[100021] = {price = 100000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0}  --白银月饼图纸
		gift_list_info[100022] = {price = 10000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0}   --黄铜月饼图
	end
	
	
	if end_zhongqiu_time < e.data.time and e.data.time < yuebing_tuzhi_time then
	  --更新汽车图纸 删除月饼图纸
		gift_list_info[100100] ={price = 1000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0}  --奥拓图纸
		gift_list_info[100101] ={price = 5000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0}  	   --雪铁龙C2图纸
		gift_list_info[100102] ={price = 30000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0}    --甲壳虫图纸
		gift_list_info[100103] ={price = 250000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0}  	 --玛莎拉蒂图纸
		gift_list_info[100104] ={price = 600000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0} 	 --法拉利图纸
		gift_list_info[100105] = {price = 1000000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0}  --保时捷图纸
		gift_list_info[100106] = {price = 1500000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0}  --兰博基尼图纸
		
		gift_list_info[100020] ={price = 500000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0}   --黄金月饼图纸
		gift_list_info[100021] ={price = 100000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0}   --白银月饼图纸
		gift_list_info[100022] ={price = 10000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0}    --黄铜月饼图
	end
	
	if yuebing_tuzhi_time < e.data.time and e.data.time then
		--更新汽车图纸 删除月饼图纸
         --晶月祝福
		gift_list_info[100100] = {price = 1000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0} 	   --奥拓图纸
		gift_list_info[100101] = {price = 5000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0} 	   --雪铁龙C2图纸
		gift_list_info[100102] = {price = 30000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0} 	 --甲壳虫图纸
		gift_list_info[100103] =  {price = 250000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0} 	 --玛莎拉蒂图纸
		gift_list_info[100104] = {price = 600000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0} 	 --法拉利图纸
		gift_list_info[100105] = {price = 1000000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0} --保时捷图纸
		gift_list_info[100106] =  {price = 1500000, everyday_num = 2, valid_time = "", can_sale = 0, is_car = 0} --兰博基尼图纸
		
		gift_list_info[100020] = nil --黄金月饼图纸
		gift_list_info[100021] = nil --白银月饼图纸
		gift_list_info[100022] = nil --黄铜月饼图	
	end
	
	if end_qichetuzhi_time < e.data.time  then
		--更新汽车图纸 删除月饼图纸
		gift_list_info[100100] = nil	   --奥拓图纸
		gift_list_info[100101] = nil	   --雪铁龙C2图纸
		gift_list_info[100102] = nil	   --甲壳虫图纸
		gift_list_info[100103] = nil	 --玛莎拉蒂图纸
		gift_list_info[100104] = nil	 --法拉利图纸
		gift_list_info[100105] = nil	 --保时捷图纸
		gift_list_info[100106] = nil	 --兰博基尼图纸
		
		gift_list_info[100020] = nil --黄金月饼图纸
		gift_list_info[100021] = nil --白银月饼图纸
		gift_list_info[100022] = nil  --黄铜月饼图	
	end

end
--商城购买调用，判断是不是中秋月饼图纸
function zhongqiu_lib.is_in_zhongqiu_tuzhi(user_info, to_user_info, giftid, gift_num)
	if (not user_info) or (not to_user_info) or (not giftid) then
		return 0;
	end
	
	local temp_list = {};
	for _, item in ipairs(zhongqiu_lib.GFG_TUZHI_LIST1) do
		temp_list[#temp_list + 1] = item;
	end
	for _, item in ipairs(zhongqiu_lib.GFG_TUZHI_LIST2) do
		temp_list[#temp_list + 1] = item;
	end
	
	for _,v in ipairs(temp_list) do
		if giftid == v then
			--增加背包里的图纸
			zhongqiu_lib.give_item(to_user_info, giftid, gift_num);
			--zhongqiu_lib.send_get_tuzhi(user_info, to_user_info, giftid, zhongqiu_lib.GFG_TUZHI_NAME[giftid]);
			
			--更新合成面板的内存

			--记录购买图纸log
			zhongqiu_db_lib.record_zhongqiu_transaction(user_info,giftid,1);
			return 1;
		end
	end
	
	return 0;
	
end

function zhongqiu_lib.on_user_exit(e)
	if (not e) and (not e.data.userinfo) then 
		return 0;
	end
	local user_id = e.data.user_id

	if zhongqiu_lib.user_list[user_id] ~= nil then
		zhongqiu_db_lib.save_user_info(user_id)
		zhongqiu_lib.user_list[user_id] = nil
	end
end

function zhongqiu_lib.ongameover(e)
	if (not e) and (not e.data.userinfo) then 
		return 0;
	end
	
	--活动时间判断
	if zhongqiu_lib.check_time() == 0 then
		 return 0; 
	end
	local user_info = e.data.user_info;
	local user_id   = user_info.userId;
	local deskno    = user_info.desk;
	local deskinfo  = desklist[deskno];
	local room_type = zhongqiu_lib.get_room_type(deskinfo.smallbet)
	if room_type > 0 then
		zhongqiu_lib.user_list[user_id].play_count[room_type] = zhongqiu_lib.user_list[user_id].play_count[room_type] + 1;
		if zhongqiu_lib.user_list[user_id].play_count[room_type] % zhongqiu_lib.CFG_PANSHU == 0 then
				--随机奖励
				local find = 0;
				local add = 0;
				local rand = math.random(1, 1000);
				for i = 1, #zhongqiu_lib.GFG_PORBABILITY_LIST[room_type] do
						add = add + zhongqiu_lib.GFG_PORBABILITY_LIST[room_type][i];
					if add >= rand then
						find = i;
						break;
					end
				end
				if find ~= 0 then
					zhongqiu_lib.give_item(user_info, zhongqiu_lib.CFG_GIVE_ITEMID[find])
					zhongqiu_lib.send_get_item(user_info, zhongqiu_lib.CFG_GIVE_ITEMID[find], zhongqiu_lib.CFG_GIVE_NAME[find])
					--记录碎片掉落log
					zhongqiu_db_lib.record_zhongqiu_transaction(user_info,zhongqiu_lib.CFG_GIVE_ITEMID[find],2);
				end
		end
		
		zhongqiu_lib.send_panshu(user_info)
	end
end

--给道具
function zhongqiu_lib.give_item(user_info, nItemId, item_num)
	if (not user_info) and (not nItemId) then
			return 0;
	end
	--调用背包接口
	tex_gamepropslib.set_props_count_by_id(nItemId, item_num or 1, user_info, nil) 
end

--通知客户端给道具
function zhongqiu_lib.send_get_item(user_info, nItemId, szItemName)
	if user_info == nil then return end

	netlib.send(function(buf)
		buf:writeString("ZQGVITEM")
		buf:writeInt(nItemId)
		buf:writeString(_U(szItemName))
	end, user_info.ip, user_info.port)
end

--通知客户端给从商城购买了图纸
--function zhongqiu_lib.send_get_tuzhi(user_info, to_user_info, nItemId, szItemName)
--	if user_info == nil then return end
--	if to_user_info == nil then return end
--	local user_id = user_info.userId
--	local to_user_id = to_user_info.userId
--
--	
--	netlib.send(function(buf)
--		buf:writeString("ZQGVTUZHI")
--		buf:writeInt(user_id)
--		buf:writeString(user_info.nick)
--		buf:writeInt(to_user_id)
--		buf:writeString(to_user_info.nick)
--		buf:writeInt(nItemId)
--		buf:writeString(_U(szItemName))
--	end, user_info.ip, user_info.port)
--	if user_id ~= to_user_id then
--		netlib.send(function(buf)
--		buf:writeString("ZQGVTUZHI")
--		buf:writeInt(user_id)
--		buf:writeString(user_info.nick)
--		buf:writeInt(to_user_id)
--		buf:writeString(to_user_info.nick)
--		buf:writeInt(nItemId)
--		buf:writeString(_U(szItemName))
--		end, to_user_info.ip, to_user_info.port)
--	end
--	
--end

--通知客户端更新盘数
function zhongqiu_lib.send_panshu(user_info)
	if user_info == nil then return end
	local user_id = user_info.userId
	netlib.send(function(buf)
		buf:writeString("ZQPANSHU")
		buf:writeInt(user_id)
		buf:writeInt(zhongqiu_lib.user_list[user_id].play_count[1])
		buf:writeInt(zhongqiu_lib.user_list[user_id].play_count[2])
		buf:writeInt(zhongqiu_lib.user_list[user_id].play_count[3])
	end, user_info.ip, user_info.port)
end

--客户端请求活动是否有效
function zhongqiu_lib.huodong_status(buf)
	if not buf then return end
	if tonumber(groupinfo.groupid) ~= 18001 then return end
	local status = zhongqiu_lib.check_time()
	netlib.send(function(buf)
		buf:writeString("ZQSTATU")
		buf:writeByte(status)
	end, buf:ip(), buf:port()) 	 	 	 	
end


--客户端请求打开宝箱
function zhongqiu_lib.open_pay_box(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local item_id = buf:readInt()
	if item_id < 14 or item_id > 18 then
		TraceError("客户端传来的宝箱ID错误，不再14到18之间")
		return
	end
	
	local status = zhongqiu_lib.check_time()
	if status ~= 2 then
		netlib.send(function(buf)
					buf:writeString("ZQOPENBOX")
					buf:writeInt(0)
				end, buf:ip(), buf:port())
		return
	end
	if tonumber(groupinfo.groupid) ~= 18001 then return end
	--调用背包接口查找宝箱，有宝箱的话就宝箱数量-1
	local set_count_box = function(nCount)
		if nCount >= 1 then
			
				--随机奖励
				local call_back = function ()
					--解锁数据库操作
					if zhongqiu_lib.user_list[user_info.userId] then
						 zhongqiu_lib.user_list[user_info.userId].update_db = 0 
					end
						local find = 0;
						local add = 0;
						local rand = math.random(1, 1000);
						for i = 1, #zhongqiu_lib.GUOQING_PORBABILITY_LIST[item_id] do
									add = add + zhongqiu_lib.GUOQING_PORBABILITY_LIST[item_id][i];
									if add >= rand then
											find = i;
										break;
									end
						end
					--调用背包接口给道具，发送客户端协议
						netlib.send(function(buf)
							buf:writeString("ZQOPENBOX")
							buf:writeInt(#zhongqiu_lib.GUOQING_REWARD_LIST[item_id][find])
							for i = 1,#zhongqiu_lib.GUOQING_REWARD_LIST[item_id][find] do
									local reward_id        = zhongqiu_lib.GUOQING_REWARD_LIST[item_id][find][i][1]
									local reward_number    = zhongqiu_lib.GUOQING_REWARD_LIST[item_id][find][i][2]
									local reward_name      = zhongqiu_lib.GUOQING_REWARD_LIST[item_id][find][i][3]	
									tex_gamepropslib.set_props_count_by_id(reward_id, reward_number, user_info, nil)
									buf:writeInt(reward_id)
									buf:writeInt(reward_number)
									buf:writeString(_U(reward_name))
							end		
						end, user_info.ip, user_info.port)
				end
				tex_gamepropslib.set_props_count_by_id(item_id, -1, user_info, call_back)
		else
				netlib.send(function(buf)
					buf:writeString("ZQOPENBOX")
					buf:writeInt(0)
				end, buf:ip(), buf:port())
				return
		end
	end
	
	--如果数据库锁定则返回
	if zhongqiu_lib.user_list[user_info.userId] and zhongqiu_lib.user_list[user_info.userId].update_db == 1 then
		 return
	end
	--锁定数据库
	zhongqiu_lib.user_list[user_info.userId].update_db = 1 
	tex_gamepropslib.get_props_count_by_id(item_id, user_info, set_count_box)	
	
	
		
end

function zhongqiu_lib.check_time()
	local status = 1

	local sys_time = os.time()
	
	--活动时间
	local start_time = timelib.db_to_lua_time(zhongqiu_lib.start_time);
	local end_zhongqiu_time = timelib.db_to_lua_time(zhongqiu_lib.end_zhongqiu_time);
	local end_guoqing_time = timelib.db_to_lua_time(zhongqiu_lib.end_guoqing_time);
	local end_suipian_time = timelib.db_to_lua_time(zhongqiu_lib.end_suipian_time);
	if(sys_time < start_time or sys_time > end_suipian_time) then
	    status = 0
	end
	if(sys_time > end_zhongqiu_time and sys_time < end_guoqing_time) then
		  status = 2
	end
	if(sys_time > end_guoqing_time and sys_time < end_suipian_time) then
		  status = 3
	end
	return status;
end


--命令列表
cmdHandler = 
{
    ["ZQSTATU"]  = zhongqiu_lib.huodong_status, --查询活动是否进行中
		--["ZQGVITEM"] = zhongqiu_lib.send_get_item,  --给道具
		--["ZQPANSHU"] = zhongqiu_lib.send_panshu,    --更新盘数
    --["DYDOPPL"] = dyd_lib.open_pl, -- 打开面板
    ["ZQOPENBOX"] = zhongqiu_lib.open_pay_box,  --请求打开充值宝箱

}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end


eventmgr:addEventListener("timer_second", zhongqiu_lib.timer); 
eventmgr:addEventListener("on_game_over_event", zhongqiu_lib.ongameover); 
eventmgr:addEventListener("on_server_start", zhongqiu_lib.restart_server); 
eventmgr:addEventListener("on_user_exit", zhongqiu_lib.on_user_exit); 
eventmgr:addEventListener("h2_on_user_login", zhongqiu_lib.on_after_user_login); 
