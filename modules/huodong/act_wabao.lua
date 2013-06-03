TraceError("init act_wabao_lib...初始化挖宝活动")
if act_wabao_lib and act_wabao_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", act_wabao_lib.on_after_user_login);
end 

if not act_wabao_lib then
	act_wabao_lib = _S
	{
		on_after_user_login = NULL_FUNC,--用户登陆后初始化数据
		check_datetime = NULL_FUNC,	--检查有效时间，限时问题
		query_db = NULL_FUNC,		--查询或更新自己数据 
		chaxun_add_items = NULL_FUNC,	--棋牌  查询  和加   道具公用方法   
		ontimer_broad = NULL_FUNC,		-- 广播 
		send_item_info = NULL_FUNC,		--发送材料和道具等信息 
		send_buy_result = NULL_FUNC,	--发送购买结果 
		send_use_result = NULL_FUNC,	--发送使用金矿/银矿/铜矿结果	 
		net_send_playnum = NULL_FUNC,	--发送盘数和时间状态 
		on_recv_items_info = NULL_FUNC,		--请求所有材料等信息 
		on_recv_buy = NULL_FUNC, 			--请求购买 
		on_recv_activation = NULL_FUNC,		--请求打开活动面板 
		on_recv_activity_stat = NULL_FUNC,		--请求活动时间状态 
		on_recv_use = NULL_FUNC,				--使用金矿/银矿/铜矿 
		spring_gift = NULL_FUNC,		--随机生成奖品ID (德州  棋牌    共用)
		doing_props = NULL_FUNC,		--减挖宝图 (德州  棋牌    共用)
		use_process = NULL_FUNC,		--具体使用 逻辑local (德州  棋牌    共用) 
		doing_gold = NULL_FUNC,		--处理加、减金币/筹码
  
	 	cfg_qp_game_name = {      --棋牌游戏配置  
        	["zysz"] = "zysz",
        	["mj"] = "mj", 
    					},
    				
    	cfg_tex_game_name = {      --德州游戏配置   
        	["tex"] = "tex",
    					},
		act_startime = "2012-06-28 09:00:00",  --活动开始时间
    	act_endtime = "2012-07-05 23:59:00",  --活动结束时间
    	rank_endtime = "2012-07-07 00:00:00",	--排行榜结束时间
	}
end

--检查有效时间，限时问题
function act_wabao_lib.check_datetime()
	local sys_time = os.time();
	
	--活动时间
	local statime = timelib.db_to_lua_time(act_wabao_lib.act_startime);
	local endtime = timelib.db_to_lua_time(act_wabao_lib.act_endtime);
	local rank_endtime = timelib.db_to_lua_time(act_wabao_lib.rank_endtime);
	if(sys_time > statime and sys_time <= endtime) then
	    return 1;
	end
	
	if(sys_time > endtime and sys_time <= rank_endtime) then
		return 5; --整个活动结束后，排行榜图标保留1天后消失。
	end
	
	--活动时间过去了
	return 0;
end

--用户登陆后初始化数据
act_wabao_lib.on_after_user_login = function(e)
	
	--游戏类型验证
    if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name or act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
		--TraceError("用户登陆后初始化数据      gamepkg.name： "..gamepkg.name)
	else
		--TraceError("用户登录后事件->游戏事件验证->不在活动内 ， 返回      gamepkg.name： "..gamepkg.name)
		return
	end
	
	local check_result = act_wabao_lib.check_datetime()	--检查活动时间
	if(check_result == 0 or check_result == 5)then
		--TraceError("用户登陆后初始化数据,活动时间失效if(check_result == 0 and check_result == 5)then")
		return
	end
	
	local user_info = e.data.userinfo
	--TraceError("用户登陆后初始化数据,userid:"..user_info.userId)
	if(user_info == nil)then 
		--TraceError("用户登陆后初始化数据,if(user_info == nil)then")
	 	return
	end
	
	--棋牌
    if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
		--背包初始化数据
		if(user_info.bag_items == nil)then
			----TraceError("背包初始化数据")
			bag.get_all_item_info(user_info,function() end ,nil)
		end
	end
	
	--初始化用户藏宝图数量
    if(user_info.wabao_map_value == nil)then
    	user_info.wabao_map_value = 0
    end
    
    --初始化用户金矿数量
    if(user_info.wabao_jin_value == nil)then
    	user_info.wabao_jin_value = 0
    end
    
    --初始化用户银矿数量
    if(user_info.wabao_yin_value == nil)then
    	user_info.wabao_yin_value = 0
    end
    
    --初始化用户铜矿数量
    if(user_info.wabao_tong_value == nil)then
    	user_info.wabao_tong_value = 0
    end
    
    --查询或更新自己数据
	act_wabao_lib.query_db(user_info)
    
end

--查询或更新自己数据
function act_wabao_lib.query_db(user_info)
 
	local user_nick = user_info.nick
	user_nick = string.trans_str(user_nick)
	
	--查询或更新数据库
	local sql = "insert ignore into t_wabao_activity (user_id, user_nick, sys_time) values(%d, '%s', now());commit;";
    sql = string.format(sql, user_info.userId, user_nick);
	dblib.execute(sql)
	
	local sql_1 = "select sys_time,map_value,jin_value,yin_value,tong_value from t_wabao_activity where user_id = %d"
	sql_1 = string.format(sql_1, user_info.userId);
 
	dblib.execute(sql_1,
    function(dt)
    	if dt and #dt > 0 then

    		local sys_today = os.date("%Y-%m-%d", os.time()); --系统的今天
            local db_date = os.date("%Y-%m-%d", timelib.db_to_lua_time(dt[1]["sys_time"]));  --数据库的今天
            user_info.wabao_map_value = dt[1]["map_value"] or 0
            user_info.wabao_jin_value = dt[1]["jin_value"] or 0 
            user_info.wabao_yin_value = dt[1]["yin_value"] or 0
            user_info.wabao_tong_value = dt[1]["tong_value"] or 0 
             
    	else
			--TraceError("用户登陆后初始化数据,查询或更新数据库->失败")
    	end
    
    end)
end


--使用金矿/银矿/铜矿
function act_wabao_lib.on_recv_use(buf)
 
	--游戏类型验证
    if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name or act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
		--TraceError("使用金矿/银矿/铜矿      gamepkg.name： "..gamepkg.name)
	else
		--TraceError("使用金矿/银矿/铜矿->游戏事件验证->不在活动内 ， 返回      gamepkg.name： "..gamepkg.name)
		return
	end
  
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end; 
   	 
   	--检查时间有效性
	local check_time = act_wabao_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then 
    	--TraceError("使用金矿/银矿/铜矿,时间过期，     gamepkg.name： "..gamepkg.name.."  USERID:"..user_info.userId)
    	act_wabao_lib.send_use_result(user_info, -1, -1)
        return;
    end
     
    --收到的使用id	1:藏宝图   2：铜      3：银         4：金
    local use_id = buf:readByte();
    
    --TraceError("使用金矿/银矿/铜矿      gamepkg.name： "..gamepkg.name.."  USERID:"..user_info.userId.."   收到的使用id:"..use_id)
    
    --转换收到id
    local change_id = 0
    if(use_id == 2)then	--2：铜
    	change_id = 1 
    elseif(use_id == 3)then	--3：银
    	change_id = 2 
    elseif(use_id == 4)then	--4：金
    	change_id = 3 
    end
    
    local jin_value = user_info.wabao_jin_value or 0		--金
    local yin_value = user_info.wabao_yin_value or 0		--银
    local tong_value = user_info.wabao_tong_value or 0 	--铜
   
  	local result = 0 
  	
	--读取用户藏宝图数据
	--德州
	if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
	
		local map_value = user_info.propslist[9] or 0;		--藏宝图
		
		--具体使用 逻辑local (德州  棋牌    共用)
		act_wabao_lib.use_process(user_info, change_id, map_value)
	end
	
	--棋牌
    if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    
    	--查询背包 满 问题
		local chaxun_items_result = act_wabao_lib.chaxun_add_items(user_info, 4, 0, 0)		--4代表，新道具，主要是判断加入行道具，背包是否满
		--TraceError("使用 2：铜      3：银         4：金       棋牌        --查询背包 满 问题,--， USERID:"..user_info.userId.." chaxun_items_result:"..chaxun_items_result)
		--判断加道具结果
		if(chaxun_items_result == 3)then		--背包 满
			--TraceError("使用 2：铜      3：银         4：金       棋牌         用户背包满,--， USERID:"..user_info.userId.." result:"..result)
			local result = 4
			act_wabao_lib.send_use_result(user_info, result, 0)
			return 
		end 
	 
    	local map_value = user_info.bag_items[8005] or 0;		--藏宝图
    	
    	--具体使用 逻辑local (德州  棋牌    共用)
		act_wabao_lib.use_process(user_info, change_id, map_value)
    end
  	
end

--具体使用 逻辑local (德州  棋牌    共用)
function act_wabao_lib.use_process(user_info, change_id, map_value)
  	local result = 0
  	local award_id = 0		--随机奖品ID
  	if(change_id == 1)then	--铜 
   		if(map_value  >= 1)then 
   			--减挖宝图 
   			map_value = map_value - 1
   			--user_info.wabao_tong_value = map_value
   			
   			--减挖宝图 
   			act_wabao_lib.doing_props(user_info, 1, change_id)
   			 
   		else
   			--TraceError("使用    铜 ,--挖宝图  不足， USERID:"..user_info.userId)
   			--发送使用铜 失败结果
	    	result = 0
	    	award_id = -1
			act_wabao_lib.send_use_result(user_info, result, award_id)
	        return;
   		end
       
    elseif(change_id == 2)then	--银 
    	if(map_value >= 3)then 
   			--减银
   			map_value = map_value - 3
   			
   			--减挖宝图 
   			act_wabao_lib.doing_props(user_info, 3, change_id)
   			  
   		else
   			--TraceError("使用银,--挖宝图不足， USERID:"..user_info.userId)
   			--发送使用银失败结果
	    	result = 0
	    	award_id = -1
			act_wabao_lib.send_use_result(user_info, result, award_id)
	        return;
   		end
    elseif(change_id == 3)then	--金
    	if(map_value >= 10)then 
   			--减金
   			map_value = map_value - 10
   			 
   			 --减挖宝图 
   			act_wabao_lib.doing_props(user_info, 10, change_id)
   		else
   			--TraceError("使用金,--挖宝图不足， USERID:"..user_info.userId)
   			--发送使用金失败结果
	    	result = 0
	    	award_id = -1
			act_wabao_lib.send_use_result(user_info, result, award_id)
	        return;
   		end
    else 
    	--TraceError("使用   未知 错误， USERID:"..user_info.userId)
    	result = 0
    	award_id = -1
		act_wabao_lib.send_use_result(user_info, result, award_id)
        return;
   	end
     
	--更新 数据库
    local sqltemplet = "update t_wabao_activity set map_value = %d where user_id = %d;commit;";
    local sql=string.format(sqltemplet, map_value, user_info.userId);
    dblib.execute(sql);
    
    
  	--发送材料和道具等信息
 	local item1 = map_value		--藏宝图
	local item2 = user_info.wabao_tong_value or 0		--铜
 	local item3 = user_info.wabao_yin_value or 0		--银
 	local item4 = user_info.wabao_jin_value or 0		--金 
 	act_wabao_lib.send_item_info(user_info, item1, item2, item3, item4)
    
end

--减挖宝图 (德州  棋牌    共用)
function act_wabao_lib.doing_props(user_info, item_values, change_id)
	--德州
	if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		user_info.propslist[9] = user_info.propslist[9] - item_values
		local complete_callback_func = function(tools_count)
  	 		--随机生成奖品ID
			act_wabao_lib.spring_gift(user_info, change_id) 
		end
 		tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.wabao_map_id, -item_values, user_info, complete_callback_func)
 	end
 	
 	--棋牌
    if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
     	--加背包
		local add_items_result = act_wabao_lib.chaxun_add_items(user_info, 8005, -item_values, 1)
		--判断加道具结果
		if(add_items_result == 1)then		--加道具成功
			--TraceError("减挖宝图  , 成功")
			 
			--随机生成奖品ID
			act_wabao_lib.spring_gift(user_info, change_id) 
		else
			--TraceError("减挖宝图  , 失败。。背包问题")
			
			--通知用户背包满或其它
			local result = 4
			--发送使用 	1:藏宝图   2：铜      3：银         4：金成功结果
	    	--TraceError("使用 2：铜      3：银         4：金       棋牌         用户背包满,--， USERID:"..user_info.userId.." result:"..result)
			act_wabao_lib.send_use_result(user_info, result, 0)
		end
    end
end

--随机生成奖品ID(德州  棋牌    共用)
function act_wabao_lib.spring_gift(user_info, change_id)
 		local result = 0
	 	local award_id = 0			--随机奖品ID
	 	
    	local sql = format("call sp_get_random_spring_gift(%d, '%s', %d)", user_info.userId, "tex", change_id)
    	dblib.execute(sql, function(dt)
        	if(dt and #dt > 0)then
        		local prizeid = dt[1]["gift_id"] or 0
                
                --TraceError("使用使用金矿/银矿/铜矿,发奖，随机生成奖品ID:"..prizeid.." USERID:"..user_info.userId.."  change_id: "..change_id)
                if(prizeid <= 0) then
                	--TraceError("使用使用金矿/银矿/铜矿,发奖，随机生成奖品ID,失败")
                    return 
                end 
 
				--发奖
	 			if(change_id == 1)then	--铜 
		   			--转换对应奖品ID
		            if(prizeid == 1)then	--棋牌:500金币		德州  :200筹码 
		            	award_id = 1	 
		            	result = 1
		            	--处理加、减金币/筹码
						act_wabao_lib.doing_gold(user_info, 500, 200)
		  				
		            elseif(prizeid == 2)then	-- 棋牌:荣誉翻倍卡		德州  :2K筹码
		            	award_id = 2
		            	result = 1				 
		            	
		            	--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
			            	--加荣誉翻倍卡
			  				viploginlib.AddBuffToUser(user_info,user_info,1); 	
			  			else
			  				--处理加、减金币/筹码		德州  :2K筹码
							act_wabao_lib.doing_gold(user_info, 0, 2000)
			  			end 
			  			
		             elseif(prizeid == 3)then	-- 棋牌:小喇叭		德州  :2万筹码
		            	award_id = 7
		            	result = 1	
		            	
		            	--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
			            	--小喇叭 怎么加
							local add_items_result = act_wabao_lib.chaxun_add_items(user_info, 4, 1, 1)
							--判断加道具结果
							if(add_items_result == 1)then		--加道具成功
								--TraceError("使用 铜 ,发奖 小喇叭 加,成功")
								--通知用户
								result = 1
							else
								--TraceError("使用 铜 ,发奖 小喇叭 加,失败。。背包问题")
								
								--通知用户背包满或其它
								result = 4
							end	
			  			else
			  				--处理加、减金币/筹码    德州  :2万筹码
							act_wabao_lib.doing_gold(user_info, 0, 20000)
			  			end 
		  	
		            elseif(prizeid == 4)then	-- 棋牌:1万金币		德州  :小喇叭
		            	award_id = 4
		            	result = 1	
		            	
		            	--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    					
			            	 --处理加、减金币/筹码    棋牌:1万金币
							act_wabao_lib.doing_gold(user_info, 10000, 0)
			  			else
			  				--处理加     德州  :小喇叭
							--小喇叭怎么加
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, user_info)
			  			end 
		  				
		            elseif(prizeid == 5)then	-- 棋牌:10万金币		德州  :5000筹码
		            	award_id = 5
		            	result = 1	
		            	
		            	--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    					
			            	 --处理加、减金币/筹码    棋牌:10万金币
							act_wabao_lib.doing_gold(user_info, 100000, 0)
			  			else
			  				--处理加     德州  :筹码-->5K改VIP1会员3天试用
			  				
			  				--act_wabao_lib.doing_gold(user_info, 0, 5000)  
			  				add_user_vip(user_info,1,3);
			  				--gift_addgiftitem(user_info,9018,user_info.userId,user_info.nick, false)
			  			end  
		         	elseif(prizeid == 0)then	--异常
		         		result = 0
		  				--TraceError("使用铜 ,发奖，随机生成奖品ID,失败--异常 USERID:"..user_info.userId)
		  				return
		            end	
		        elseif(change_id == 2)then	--银
		        	--转换对应奖品ID
		            if(prizeid == 1)then	-- 棋牌:2000金币		德州  :1K筹码
		            	award_id = 6
		            	result = 1	
		            	
		            	--处理加、减金币/筹码
						act_wabao_lib.doing_gold(user_info, 2000, 1000)
		  				
		            elseif(prizeid == 2)then	-- 棋牌:荣誉翻倍卡		德州  :1W筹码 
		            	result = 1	
		            	
		            	--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    						award_id = 2
    						
			            	 --加荣誉翻倍卡
			  				viploginlib.AddBuffToUser(user_info,user_info,1); 
			  			else
			  				award_id = 19
			  				
			  				--处理加、减金币/筹码    德州  :1W筹码 -->1W改VIP3会员3天试用
			  				add_user_vip(user_info,3,3);
							--act_wabao_lib.doing_gold(user_info, 0, 10000)
			  			end 
		  				 
		            elseif(prizeid == 3)then	-- 棋牌:声望翻倍卡		德州  :10万筹码 
		             
		            	result = 1	 
		            	
		  				--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    						award_id = 7
    						
			            	 --加声望翻倍卡
		  					viploginlib.AddBuffToUser(user_info,user_info,2); 
			  			else
			  				award_id = 8
			  				 
			  				--处理加、减金币/筹码    德州  :10万筹码  
							act_wabao_lib.doing_gold(user_info, 0, 100000)
							
							--系统广播，“{XXXX}在竞技场挖宝，获得{什么奖励}！”
			  				local user_nick = user_info.nick
							user_nick = string.trans_str(user_nick) 
			  				local msg = _U(tex_lan.get_msg(user_info, "act_wabao_lib_msg_5"))..user_nick.._U(tex_lan.get_msg(user_info, "act_wabao_lib_msg")); 
							msg = string.format(msg,10);  
							BroadcastMsg(msg,0)
							 
			  			end 
		  	
		            elseif(prizeid == 4)then	-- 棋牌:小喇叭*2  		德州  :T人卡
		            	--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    						award_id = 8
		            	
			            	--小喇叭*2怎么加
							local add_items_result = act_wabao_lib.chaxun_add_items(user_info, 4, 2, 1)
							--判断加道具结果
							if(add_items_result == 1)then		--加道具成功
								--TraceError("使用 银 ,发奖 小喇叭*2加,成功")
								--通知用户
								result = 1
							else
								--TraceError("使用 银 ,发奖 小喇叭*2加,失败。。背包问题")
								
								--通知用户背包满或其它
								result = 4
							end
						else
							award_id = 9
			            	--德州  :T人卡      
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 1, user_info)
						end
						
		            elseif(prizeid == 5)then	-- 棋牌:50万金币 		德州  :幽灵
		            	result = 1	 
		            	
		  				--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    						award_id = 9
    						 
			            	 --加棋牌:50万金币 
		  					act_wabao_lib.doing_gold(user_info, 500000, 0)
		  					 
		  					--系统广播，“{XXXX}在竞技场挖宝，获得{什么奖励}！” 
			  		 		local user_nick = user_info.nick
							user_nick = string.trans_str(user_nick)
			  				local tips = user_nick.._U("  在竞技场挖宝，获得50万金币！");
							act_wabao_lib.ontimer_broad(tips,1);
			  			else
			  				award_id = 10
			  				 
			  				--处理加    德州  :幽灵--》OL美女
							gift_addgiftitem(user_info,9025,user_info.userId,user_info.nick, false)
			  			end 
		  		  	
		  		  	elseif(prizeid == 6)then	-- 棋牌:500万金币 		德州  :138万玛莎拉蒂 
		            	result = 1 
		  				--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    						award_id = 10
    						 
			            	 --加棋牌:500万金币 
		  					act_wabao_lib.doing_gold(user_info, 5000000, 0)
		  					 
		  					--系统广播，“{XXXX}在竞技场挖宝，获得{什么奖励}！” 
			  		 		local user_nick = user_info.nick
							user_nick = string.trans_str(user_nick)
			  				local tips = user_nick.._U("  在竞技场挖宝，获得500万金币！");
							act_wabao_lib.ontimer_broad(tips,1);
			  			else
			  				award_id = 11
			  				 
			  				--处理加    德州  :小喇叭
							tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, user_info)
			  			end 
						
		  			elseif(prizeid == 0)then	--异常
		  				--TraceError("使用银 ,发奖，随机生成奖品ID,失败--异常 USERID:"..user_info.userId)
		  				return
		            end	
		   		elseif(change_id == 3)then		--金
		   			--转换对应奖品ID
		            if(prizeid == 1)then	-- 棋牌: 小喇叭*3		德州  :T人卡*2
		            	
		            	--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then 
			            	award_id = 11  --小喇叭*3
			             
			            	--小喇叭*3
			  				local add_items_result = act_wabao_lib.chaxun_add_items(user_info, 4, 3, 1)
							--判断加道具结果
							if(add_items_result == 1)then		--加道具成功
								--TraceError("使用 金 ,发奖 小喇叭*3加,成功")
								--通知用户
								result = 1
							else
								--TraceError("使用 金 ,发奖 小喇叭*3加,失败。。背包问题")
								
								--通知用户背包满或其它
								result = 4
							end
						else
							result = 1
							award_id = 12 
							--加 德州  : T人卡*2
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 2, user_info)
						
						end
		          
		            elseif(prizeid == 2)then	-- 棋牌: 5万金币		德州  :小喇叭
		            	result = 1 
		            	--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then 
	    					
			            	award_id = 12
			            	
			  				--处理加、减金币/筹码 
							act_wabao_lib.doing_gold(user_info, 50000, 0)
			  			else
			  				--处理加     德州  :小喇叭 *2
			  				award_id = 13
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 2, user_info)
			  			end  
		            elseif(prizeid == 3)then	-- 棋牌: 80万金币		德州  :火辣girl（1%）
		            	result = 1 
		            	--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then 
	    					
			            	award_id = 13
			            	
			  				--处理加、减金币/筹码     棋牌: 80万金币
							act_wabao_lib.doing_gold(user_info, 800000, 0)
							
							--系统广播，“{XXXX}在竞技场挖宝，获得{什么奖励}！” 
			  		 		local user_nick = user_info.nick
							user_nick = string.trans_str(user_nick)
			  				local tips = user_nick.._U("  在竞技场挖宝，获得80万金币！");
							act_wabao_lib.ontimer_broad(tips,1);
			  			else
			  				--处理加     德州  :火辣girl(9022)改成性感美女（ 9024）
			  		 		award_id = 14
			  				gift_addgiftitem(user_info,9024,user_info.userId,user_info.nick, false)
			  			end  
		  				 
		  			elseif(prizeid == 4)then	-- 棋牌: 500万金币		德州  :1万筹码
		            	result = 1 
		            	--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then 
	    					
			            	award_id = 10
			            	
			  				--处理加、减金币/筹码     棋牌: 500万金币
							act_wabao_lib.doing_gold(user_info, 5000000, 0)
							
							--系统广播，“{XXXX}在竞技场挖宝，获得{什么奖励}！” 
			  		 		local user_nick = user_info.nick
							user_nick = string.trans_str(user_nick)
			  				local tips = user_nick.._U("  在竞技场挖宝，获得500万金币！");
							act_wabao_lib.ontimer_broad(tips,1);
			  			else
			   				--处理加     德州  :2万筹码
			  		 		award_id = 7
			  				act_wabao_lib.doing_gold(user_info, 0, 20000)
			  			end
						 
		  			elseif(prizeid == 5)then	-- 棋牌: 2000万金币		德州  :2万筹码
		            	result = 1 
		            	--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then 
	    					
			            	award_id = 14
			            	
			  				--处理加、减金币/筹码     棋牌: 2000万金币
							act_wabao_lib.doing_gold(user_info, 20000000, 0)
							
							--系统广播，“{XXXX}在竞技场挖宝，获得{什么奖励}！” 
			  		 		local user_nick = user_info.nick
							user_nick = string.trans_str(user_nick)
			  				local tips = user_nick.._U("  在竞技场挖宝，获得2000万金币！");
							act_wabao_lib.ontimer_broad(tips,1);
			  			else
			   				--处理加     德州  :10万筹码
			  		 		award_id = 3
			  				act_wabao_lib.doing_gold(user_info, 0, 100000)
			  			end
					elseif(prizeid == 6)then	-- 棋牌: 1亿金币		德州  :20万筹码
		            	result = 1 
		            	--棋牌
    					if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then 
	    					
			            	award_id = 15
			            	
			  				--处理加、减金币/筹码     棋牌: 1亿金币
							act_wabao_lib.doing_gold(user_info, 100000000, 0)
							
							--系统广播，“{XXXX}在竞技场挖宝，获得{什么奖励}！” 
			  		 		local user_nick = user_info.nick
							user_nick = string.trans_str(user_nick)
			  				local tips = user_nick.._U("  在竞技场挖宝，获得1亿金币！");
							act_wabao_lib.ontimer_broad(tips,1);
			  			else
			   				--处理加     德州  :20万筹码
			  		  		award_id = 15
			  				act_wabao_lib.doing_gold(user_info, 0, 200000)
			  				
			  				--系统广播，“{XXXX}在竞技场挖宝，获得{什么奖励}！”
			  				local user_nick = user_info.nick
							user_nick = string.trans_str(user_nick)
			  				local msg = _U(tex_lan.get_msg(user_info, "act_wabao_lib_msg_5"))..user_nick.._U(tex_lan.get_msg(user_info, "act_wabao_lib_msg")); 
							msg = string.format(msg,20);  
							BroadcastMsg(msg,0)
			  			end
			  		elseif(prizeid == 7)then	-- 德州  :138万奔驰豪华房车
			  			result = 1 
			  			award_id = 16
			  				 
		  				--处理加    德州  :138万奔驰豪华房车
						gift_addgiftitem(user_info,5017,user_info.userId,user_info.nick, false)	
						
						--系统广播，“{XXXX}在竞技场挖宝，获得138万奔驰豪华房车 ！”
		  				local user_nick = user_info.nick
						user_nick = string.trans_str(user_nick) 
		  				local msg = _U(tex_lan.get_msg(user_info, "act_wabao_lib_msg_5"))..user_nick.._U(tex_lan.get_msg(user_info, "act_wabao_lib_msg_1")); 
						BroadcastMsg(msg,0)
						
			  		elseif(prizeid == 8)then	--  德州  :588万法拉利
			  			result = 1 
			  			award_id = 17
			  				 
		  				--处理加    德州  :588万法拉利
						gift_addgiftitem(user_info,5024,user_info.userId,user_info.nick, false)	
						 
						--系统广播，“{XXXX}在竞技场挖宝，获得588万法拉利 ！”
		  				local user_nick = user_info.nick
						user_nick = string.trans_str(user_nick) 
		  				local msg = _U(tex_lan.get_msg(user_info, "act_wabao_lib_msg_5"))..user_nick.._U(tex_lan.get_msg(user_info, "act_wabao_lib_msg_2")); 				
						BroadcastMsg(msg,0)
			  		
			  		elseif(prizeid == 9)then	-- 德州  :1888万兰博基尼
			  			result = 1 
			  			award_id = 18
			  				 
		  				--处理加    德州  :1888万兰博基尼
						gift_addgiftitem(user_info,5026,user_info.userId,user_info.nick, false)	
						 
						--系统广播，“{XXXX}在竞技场挖宝，获得1888万兰博基尼 ！”
		  				local user_nick = user_info.nick
						user_nick = string.trans_str(user_nick) 
		  				local msg = _U(tex_lan.get_msg(user_info, "act_wabao_lib_msg_5"))..user_nick.._U(tex_lan.get_msg(user_info, "act_wabao_lib_msg_3"));  
						BroadcastMsg(msg,0)
			  		
		  			elseif(prizeid == 0)then	--异常
		  				result = 0
		  				----TraceError("使用 爱心巧克力,发奖，随机生成奖品ID,失败--异常 USERID:"..user_info.userId)
		  				return
		            end	
			    end
			   
			   --发送使用 	1:藏宝图   2：铜      3：银         4：金成功结果
		    	--TraceError("使用 2：铜      3：银         4：金之后,--， USERID:"..user_info.userId.." result:"..result.." award_id:"..award_id)
				act_wabao_lib.send_use_result(user_info, result, award_id) 
            end
        end)
   
end

--处理加、减金币/筹码
function act_wabao_lib.doing_gold(user_info, qp_gold_value, tex_gold_value)
	--TraceError("处理加、减金币/筹码         用户id："..user_info.userId.." qp_gold_value: "..qp_gold_value.."  gamepkg.name： "..gamepkg.name.." tex_gold_value: "..tex_gold_value)
	--德州
	if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		 usermgr.addgold(user_info.userId, tex_gold_value, 0, g_GoldType.baoxiang, -1);
	end
	
	--棋牌
    if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
		usermgr.addgold(user_info.userId, qp_gold_value, 0, tSqlTemplete.goldType.HD_NEW_YEAR, -1);
	end
	
end

--请求活动时间状态
function act_wabao_lib.on_recv_activity_stat(buf)
	
	--游戏类型验证
    if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name or act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
		--TraceError("请求活动时间状态      gamepkg.name： "..gamepkg.name)
	else
		--TraceError("请求活动时间状态   ->游戏事件验证->不在活动内 ， 返回      gamepkg.name： "..gamepkg.name)
		return
	end
    
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
 
	--检查时间有效性
	local check_time = act_wabao_lib.check_datetime()
	
	--TraceError("--请求活动时间状态-->>"..check_time)
	
	if(check_time == 0 or check_time == 5) then 
		return
	end 
	 
 	local item1 = 0;		--藏宝图
	local item2 = user_info.wabao_tong_value or 0;		--铜
 	local item3 = user_info.wabao_yin_value or 0		--银
 	local item4 = user_info.wabao_jin_value or 0		--金  
 	
 	--德州
	if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		item1 = user_info.propslist[9] or 0
	end
	
	--棋牌
    if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    	item1 = user_info.bag_items[8005] or 0
    end
 	
	if(item1 > 0 or item2 > 0 or item3 > 0 or item4 > 0)then
		check_time = 2;		--活动有效,有材料
	end
	 
	--用户盘数     在这里没有用，只是方便前台不改变代码
	local play_count = 0 
	
 	--通知客户端
    act_wabao_lib.net_send_playnum(user_info, check_time, play_count);
end


--请求打开活动面板
function act_wabao_lib.on_recv_activation(buf)

	--游戏类型验证
    if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name or act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
		--TraceError("请求打开活动面板      gamepkg.name： "..gamepkg.name)
	else
		--TraceError("请求打开活动面板   ->游戏事件验证->不在活动内 ， 返回      gamepkg.name： "..gamepkg.name)
		return
	end
    
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
 
   	--TraceError("请求打开活动面板,USERID:"..user_info.userId)
   
   	--检查时间有效性
	local check_time = act_wabao_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("请求打开活动面板,时间过期， USERID:"..user_info.userId)  
    	--发送时间过期
		act_wabao_lib.net_send_playnum(user_info, 0, 0) 
        return;
    else
    	--发送时间过期
		act_wabao_lib.net_send_playnum(user_info, 1, 0) 
    end 
    
	--查询或更新自己数据
	act_wabao_lib.query_db(user_info)
	
	--发送材料和道具等信息 
 	local item1 = 0;		--藏宝图
	local item2 = user_info.wabao_tong_value or 0;		--铜
 	local item3 = user_info.wabao_yin_value or 0		--银
 	local item4 = user_info.wabao_jin_value or 0		--金  
 	
 	--德州
	if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		item1 = user_info.propslist[9] or 0
	end
	
	--棋牌
    if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    	item1 = user_info.bag_items[8005] or 0
    end
    
 	act_wabao_lib.send_item_info(user_info, item1, item2, item3, item4) 
end

--请求购买
function act_wabao_lib.on_recv_buy(buf) 
	--游戏类型验证
    if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name or act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
		--TraceError("请求购买      gamepkg.name： "..gamepkg.name)
	else
		--TraceError("请求购买   ->游戏事件验证->不在活动内 ， 返回      gamepkg.name： "..gamepkg.name)
		return
	end
	
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   
   	--收到购买id
    local buy_type_id = buf:readByte();
    	
   	--TraceError("请求购买,USERID:"..user_info.userId.." 收到购买id:"..buy_type_id)
   	 
 	local result = 0
    local gold = get_canuse_gold(user_info) --获得用户筹码
  
	local map_value = 0	--藏宝图
	--德州
	if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		map_value = user_info.propslist[9] or 0
	end
	
	--棋牌
    if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    	map_value = user_info.bag_items[8005] or 0
    end
	
   	--检查时间有效性
	local check_time = act_wabao_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("请求购买,时间过期， USERID:"..user_info.userId)
    	
    	--发送购买结果
    	result = 2 
		act_wabao_lib.send_buy_result(user_info, buy_type_id, map_value, result)
    	return;  
    end
 
 	--德州
 	if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
	 	--判断是否有钱
	 	if(buy_type_id == 1)then		--藏宝图
	    	if(gold < 100000)then
	    		--TraceError("购买藏宝图,钱不够， USERID:"..user_info.userId)
		    	
		    	--发送购买结果
		    	result = 0
				act_wabao_lib.send_buy_result(user_info, buy_type_id, map_value, result)
		    	return
		    else
		    	 
	    		--加藏宝图
				--可以购买
		    	--减筹码
				usermgr.addgold(user_info.userId, -100000, 0, g_GoldType.baoxiang, -1);
	 
				--加藏宝图
				map_value = map_value + 10 
				user_info.propslist[9] = map_value
	    		
	   			local complete_callback_func = function(tools_count)
	   				result = 1
	      	 		--发送购买成功
					act_wabao_lib.send_buy_result(user_info, 1, map_value, result)
	    		end 
	   		 	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.wabao_map_id, 10, user_info, complete_callback_func)
	    		 
	    	end
		end
	end
	
	--棋牌
	if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
		local result = 0
		--查询道具情况 满，返回 
		local chaxun_items_result = act_wabao_lib.chaxun_add_items(user_info, 8005, 0, 0)
		--TraceError("购买藏宝图,钱不够， USERID:"..user_info.userId.."  chaxun_items_result: "..chaxun_items_result)
		
		if(chaxun_items_result == 3)then		--满
	 		--通知用户背包满或其它
			result = 4 
			act_wabao_lib.send_buy_result(user_info, 1, map_value, result)
			return
	 	end
	 	
	 	local site = user_info.site		-- 用于判断是否在牌桌内    如果在不能购买
		
		--判断是否有钱
	 	if(buy_type_id == 1)then		--藏宝图
	    	if(gold < 500000)then
	    		--TraceError("购买藏宝图,钱不够， USERID:"..user_info.userId)
		     
		    	--发送购买结果
		    	result = 0
				act_wabao_lib.send_buy_result(user_info, buy_type_id, map_value, result)
		    	return
		    	
		    elseif(site ~= nil)then	--判断是否在 
				--TraceError("-- 请求购买藏宝图错误  在牌桌内坐下   不能购买    用户id："..user_info.userId.." 游戏名："..gamepkg.name)
				
				result = 5 
		 		act_wabao_lib.send_buy_result(user_info, buy_type_id, map_value, result)
		    	return 
		    else
		    	--可以购买
			    --减筹码
				usermgr.addgold(user_info.userId, -500000, 0, tSqlTemplete.goldType.HD_NEW_YEAR, -1);
		    	 
	    		--加背包 藏宝图
				local add_items_result = act_wabao_lib.chaxun_add_items(user_info, 8005, 10, 1)
				--判断加道具结果
				if(add_items_result == 1)then		--加道具成功
					--TraceError("  请求购买藏宝图 , 成功")
					
					--加藏宝图
					map_value = map_value + 10
					
					--通知用户
					result = 1
					act_wabao_lib.send_buy_result(user_info, 1, map_value, result)
				else
					--TraceError("请求购买藏宝图 , 失败。。背包问题 add_items_result:"..add_items_result)
					
					--通知用户背包满或其它
					result = 4
					act_wabao_lib.send_buy_result(user_info, 1, map_value, result)
				end
	    		 
	    	end
		end
	end
    
    --更新 数据库
    local sqltemplet = "update t_wabao_activity set map_value = %d where user_id = %d;commit;";
    local sql=string.format(sqltemplet, map_value, user_info.userId);
    dblib.execute(sql);
    
end
 
--请求所有材料等信息
function act_wabao_lib.on_recv_items_info(buf)
	--游戏类型验证
    if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name or act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
		--TraceError("请求所有材料等信息      gamepkg.name： "..gamepkg.name)
	else
		--TraceError("请求所有材料等信息   ->游戏事件验证->不在活动内 ， 返回      gamepkg.name： "..gamepkg.name)
		return
	end
	
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	
   	--TraceError("请求所有材料等信息,USERID:"..user_info.userId)
   
   	--检查时间有效性
	local check_time = act_wabao_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("返回请求所有材料等信息,时间过期， USERID:"..user_info.userId) 
        return;
    end
    
    --发送材料和道具等信息 
 	local item1 = 0;
 	local item2 = user_info.wabao_tong_value or 0
 	local item3 = user_info.wabao_yin_value or 0
 	local item4 = user_info.wabao_jin_value or 0
 	--德州
	if(act_wabao_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		item1 = user_info.propslist[9] or 0
	end
	
	--棋牌
    if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    	item1 = user_info.bag_items[8005] or 0
    end
 	 
 	act_wabao_lib.send_item_info(user_info, item1, item2, item3, item4)
 
end

--发送盘数和时间状态
act_wabao_lib.net_send_playnum = function(user_info, check_time, play_count)
  	--TraceError(" 发送盘数和时间状态,userid:"..user_info.userId.." check_time->"..check_time.." play_count:"..play_count)
	netlib.send(function(buf)
	    buf:writeString("HDQRDATE")
	    buf:writeByte(check_time)	 --0，活动无效（服务端也可不发）；1，活动有效；2,有材料   5，活动结束，保留一天
	    buf:writeInt(play_count)	--玩家玩的盘数
	    end,user_info.ip,user_info.port) 
end

--发送使用金矿/银矿/铜矿结果
function act_wabao_lib.send_use_result(user_info, result, award_id)
	--TraceError("发送使用金矿/银矿/铜矿结果，userid:"..user_info.userId.." result:"..result.." award_id:"..award_id);
	netlib.send(function(buf)
            buf:writeString("HDQRUSE");
            buf:writeInt(result);
            buf:writeInt(award_id);
        end,user_info.ip,user_info.port);
end

--发送购买结果
function act_wabao_lib.send_buy_result(user_info, buy_id, items_value, result)
	--TraceError("发送购买结果,USERID:"..user_info.userId.." items_value:"..items_value.." result:"..result.." buy_id:"..buy_id)
	netlib.send(function(buf)
            buf:writeString("HDQRBUY");
            buf:writeInt(result);		--0，购买失败，金币不足；1，购买成功；2，购买失败，活动已过期；3，购买失败，其它原因；
            buf:writeByte(buy_id);
            buf:writeInt(items_value);		--材料的数量
        end,user_info.ip,user_info.port);
end

--发送材料和道具等信息
function act_wabao_lib.send_item_info(user_info, item1, item2, item3, item4)
	  --TraceError("发送材料和道具等信息,USERID:"..user_info.userId.." 藏宝图数量:"..item1.." 铜数量:"..item2.." 银豆数量:"..item3.." 金数量:"..item4)
	  netlib.send(function(buf)
            buf:writeString("HDQRVALUE");
            buf:writeInt(item1);		--藏宝图数量
            buf:writeInt(item2);		--铜数量
            buf:writeInt(item3);		--银豆数量
            buf:writeInt(item4);		--金数量 
        end,user_info.ip,user_info.port);
end

-- 广播
function act_wabao_lib.ontimer_broad(tips,flag)

    --如果提示不为nil 全服发广播。
    if(flag == nil or flag~= 1)then
      tips = _U(tips)
    end
    if (tips ~=  nil and tips ~=  "" ) then 
        tools.SendBufToUserSvr("", "SPBC", "", "", tips)
    end
end

--棋牌  查询  和加   道具公用方法          item_id:道具id    item_num：道具数量           use_type：使用方式（0:查询   1：加  减）
function act_wabao_lib.chaxun_add_items(user_info, item_id, item_num, use_type)
	--TraceError("棋牌  查询  和加   道具公用方法,item_id:"..item_id.." item_num->"..item_num)
 
	local ret = 0; 
	bag.get_all_item_info(user_info, function(items)
            local check_items = {[item_id]=1};
            local check_space = 0;
            
            for k, v in pairs(check_items) do
                check_space = bag.check_space(items, {[k]=v}); 
                if(check_space ~= 1) then--背包已满
                    ret = 3
                end 
            end  
    		
            if (ret == 3) then                      --背包已满 
                ret = 3;
                return ret
            end
             
            if(use_type > 0)then                                             --通过基础验证 
                bag.add_item(user_info, {item_id = item_id, item_num = item_num},nil,bag.log_type.NY_HOUDONG);
                ret = 1;	--加道具成功 
                return ret
            end 
        end); 
     return ret
end

--协议命令
cmd_tex_match_handler = 
{ 
    ["HDQRDATE"] = act_wabao_lib.on_recv_activity_stat, --请求活动时间状态
    ["HDQRPANEL"] = act_wabao_lib.on_recv_activation, -- 请求打开活动面板 
    ["HDQRVALUE"] = act_wabao_lib.on_recv_items_info, 	--请求所有材料等信息
    ["HDQRUSE"] = act_wabao_lib.on_recv_use, --使用金矿/银矿/铜矿
    ["HDQRBUY"] = act_wabao_lib.on_recv_buy,--请求购买  
}

--加载插件的回调
for k, v in pairs(cmd_tex_match_handler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("h2_on_user_login", act_wabao_lib.on_after_user_login); 