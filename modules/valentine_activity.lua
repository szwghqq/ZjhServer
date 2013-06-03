TraceError("init valentine_activity...")
if valentine_lib and valentine_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", valentine_lib.on_after_user_login);
end

if valentine_lib and valentine_lib.ontimecheck then
	eventmgr:removeEventListener("timer_minute", valentine_lib.ontimecheck);
end
			
if not valentine_lib then
    valentine_lib = _S
    {
        on_after_user_login = NULL_FUNC,--用户登陆后初始化数据
		check_datetime = NULL_FUNC,	--检查有效时间，限时问题
		ongameover = NULL_FUNC,	--游戏结束采集盘数
		net_send_playnum = NULL_FUNC,	--发送盘数和时间状态
		ontimecheck = NULL_FUNC,	--定时刷新事件
		on_recv_use = NULL_FUNC,	--使用红玫瑰/巧克力/爱心巧克力
		send_use_result = NULL_FUNC,--发送使用结果
		init_charm_ph = NULL_FUNC,	--初始化排行榜
		on_recv_ph_list = NULL_FUNC,	--请求排行榜
		get_my_pm = NULL_FUNC,	--找自己的排行榜
		send_ph_list = NULL_FUNC,	--发送排行榜
		on_recv_activity_stat = NULL_FUNC,	--请求活动时间状态
		on_recv_activation = NULL_FUNC,	--请求打开活动面板
 		on_recv_buy = NULL_FUNC,	--请求购买
		send_buy_result = NULL_FUNC,	--发送购买结果
		on_recv_items_info = NULL_FUNC,	--请求所有材料等信息
		send_item_info = NULL_FUNC,	--发送材料和道具等信息
		on_recv_packs = NULL_FUNC,	--通知服务端，请求领取“神秘礼包”
 		send_exorcist_packs_result = NULL_FUNC,	--发送请求领取“驱魔礼包”结果
		query_db = NULL_FUNC,		--查询或更新自己数据
		_tosqlstr = NULL_FUNC,		--火星文处理
		on_recv_composite = NULL_FUNC,	--请求合成：1，爱心巧克力；2，花束； 6，巧克力；10，红玫瑰；
		net_send_composite_result = NULL_FUNC,	--发送合成结果
		send_random_item = NULL_FUNC,		--发送返回每玩5局随机获得1种合成材料
 
        refresh_invate_time = -1,  --上一次刷新时间
    
        charm_ph_list = {}; --魅力排名
 
        activ1_statime = "2012-02-9 09:00:00",  --活动开始时间
    	activ1_endtime = "2012-02-20 00:00:00",  --活动结束时间
    	rank_endtime = "2012-02-21 00:00:00",	--排行榜结束时间
    }    
end
  
--用户登陆后初始化数据
valentine_lib.on_after_user_login = function(e)
	local user_info = e.data.userinfo
	--TraceError("用户登陆后初始化数据,userid:"..user_info.userId)
	if(user_info == nil)then 
		--TraceError("用户登陆后初始化数据,if(user_info == nil)then")
	 	return
	end
	
	local check_result = valentine_lib.check_datetime()	--检查活动时间
	if(check_result == 0 or check_result == 5)then
		--TraceError("用户登陆后初始化数据,活动时间失效if(check_result == 0 and check_result == 5)then")
		return
	end
	 
    --初始化用户盘数
    if(user_info.valentine_play_count == nil)then
    	user_info.valentine_play_count = 0
    end
    
    --初始化活动登录时间
    if(user_info.valentine_today == nil)then
    	local sys_today = os.date("%Y-%m-%d", os.time());  
    	user_info.valentine_today = sys_today
    end
     
    --初始化用户魅力值
    if(user_info.valentine_charm_value == nil)then
    	user_info.valentine_charm_value = 0
    end
  
 	--初始化用户可可豆数量
    if(user_info.valentine_cocoa_value == nil)then
    	user_info.valentine_cocoa_value = 0
    end
    
    --初始化用户牛奶数量
    if(user_info.valentine_milk_value == nil)then
    	user_info.valentine_milk_value = 0
    end
    
    --初始化用户果仁数量
    if(user_info.valentine_nuts_value == nil)then
    	user_info.valentine_nuts_value = 0
    end
    
    --初始化用户巧克力数量
    if(user_info.valentine_chocolate_value == nil)then
    	user_info.valentine_chocolate_value = 0
    end
    
    --初始化用户玫瑰花种子数量
    if(user_info.valentine_seeds_value == nil)then
    	user_info.valentine_seeds_value = 0
    end
    
    --初始化用户泥土数量
    if(user_info.valentine_soil_value == nil)then
    	user_info.valentine_soil_value = 0
    end
    
    --初始化用户养料数量
    if(user_info.valentine_nourishment_value == nil)then
    	user_info.valentine_nourishment_value = 0
    end
    
    --初始化用户红玫瑰数量
    if(user_info.valentine_rose_value == nil)then
    	user_info.valentine_rose_value = 0
    end
 
    --初始化用户神秘礼包领取标记
    if(user_info.valentine_libao_sign == nil)then
    	user_info.valentine_libao_sign = 0
    end
	
	--查询或更新自己数据
	valentine_lib.query_db(user_info)
    
end

--火星文处理
valentine_lib._tosqlstr = function(s) 
	s = string.gsub(s, "\\", " ") 
	s = string.gsub(s, "\"", " ") 
	s = string.gsub(s, "\'", " ") 
	s = string.gsub(s, "%)", " ") 
	s = string.gsub(s, "%(", " ") 
	s = string.gsub(s, "%%", " ") 
	s = string.gsub(s, "%?", " ") 
	s = string.gsub(s, "%*", " ") 
	s = string.gsub(s, "%[", " ") 
	s = string.gsub(s, "%]", " ") 
	s = string.gsub(s, "%+", " ") 
	s = string.gsub(s, "%^", " ") 
	s = string.gsub(s, "%$", " ") 
	s = string.gsub(s, ";", " ") 
	s = string.gsub(s, ",", " ") 
	s = string.gsub(s, "%-", " ") 
	s = string.gsub(s, "%.", " ") 
	return s 
end

--查询或更新自己数据
function valentine_lib.query_db(user_info)
 
	local user_nick = user_info.nick
	user_nick = valentine_lib._tosqlstr(user_nick).."   "
	
	--查询或更新数据库
	local sql = "insert ignore into t_valentine_activity (user_id, user_nick, sys_time) values(%d, '%s', now());commit;";
    sql = string.format(sql, user_info.userId, user_nick);
	dblib.execute(sql)
	
	local sql_1 = "select sys_time,charm_value,libao_sign,play_count,cocoa_value,milk_value,nuts_value,chocolate_value,seeds_value,soil_value,nourishment_value,rose_value from t_valentine_activity where user_id = %d"
	sql_1 = string.format(sql_1, user_info.userId);
 
	dblib.execute(sql_1,
    function(dt)
    	if dt and #dt > 0 then

    		local sys_today = os.date("%Y-%m-%d", os.time()); --系统的今天
            local db_date = os.date("%Y-%m-%d", timelib.db_to_lua_time(dt[1]["sys_time"]));  --数据库的今天
            user_info.valentine_charm_value = dt[1]["charm_value"] or 0
            user_info.valentine_libao_sign = dt[1]["libao_sign"] or 0
 			
 			--合成材料
            user_info.valentine_cocoa_value = dt[1]["cocoa_value"] or 0
            user_info.valentine_milk_value = dt[1]["milk_value"] or 0
            user_info.valentine_nuts_value = dt[1]["nuts_value"] or 0
            user_info.valentine_chocolate_value = dt[1]["chocolate_value"] or 0
            user_info.valentine_seeds_value = dt[1]["seeds_value"] or 0
            user_info.valentine_soil_value = dt[1]["soil_value"] or 0
            user_info.valentine_nourishment_value = dt[1]["nourishment_value"] or 0
            user_info.valentine_rose_value = dt[1]["rose_value"] or 0
            
            if (db_date ~= sys_today) then
				user_info.valentine_play_count = 0
            else
            	user_info.valentine_play_count = dt[1]["play_count"] or 0
            
            end
  
    	else
			--TraceError("用户登陆后初始化数据,查询或更新数据库->失败")
    	end
    
    end)
end
 	
--检查有效时间，限时问题
function valentine_lib.check_datetime()
	local sys_time = os.time();
	
	--活动时间
	local statime = timelib.db_to_lua_time(valentine_lib.activ1_statime);
	local endtime = timelib.db_to_lua_time(valentine_lib.activ1_endtime);
	local rank_endtime = timelib.db_to_lua_time(valentine_lib.rank_endtime);
	if(sys_time > statime and sys_time <= endtime) then
	    return 1;
	end
	
	if(sys_time > endtime and sys_time <= rank_endtime) then
		return 5; --整个活动结束后，排行榜图标保留1天后消失。
	end
	
	--活动时间过去了
	return 0;
end


--游戏结束采集盘数
valentine_lib.ongameover = function(user_info,addgold)
--[[
基本流程：

显示每日进度，格式为0/50，满了显示为50/50

每人每天最多可以获得10次，即：共50局可获得10次

每玩5局随机获得1种合成材料

VIP玩家每次可获得双倍材料，如：果仁*2

 
]]
 	--TraceError(" 游戏结束采集盘数,userId:"..user_info.userId)
	if not user_info or not user_info.desk then return end;
	 
	--活动一：时间有效性
	local check_time = valentine_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError(" 游戏结束采集盘数->时间有效性,失效->if(check_time == 0 and check_time == 5)-- userid:"..user_info.userId)
        return;
    end
  
    --判断用户能开几次
    if(user_info.valentine_play_count >= 50 )then 
 
    	--跨天处理
    	local sys_today = os.date("%Y-%m-%d", os.time()); --系统的今天
    	local act_date = user_info.valentine_today  --用户登录日期
    	if (act_date ~= sys_today) then
    		--TraceError(" 游戏结束采集盘数,> 50  跨天处理 userid:"..user_info.userId)
    		user_info.valentine_play_count = 0
    		
    		user_info.valentine_today = sys_today 
    	end
    	
		--TraceError(" 游戏结束采集盘数,> 50  userid:"..user_info.userId)
		return;    
    end    
 
 	--累加局数
    local play_count = user_info.valentine_play_count or 0
    play_count = play_count + 1;
	user_info.valentine_play_count = play_count
  
    --通知客户端
    valentine_lib.net_send_playnum(user_info, check_time, play_count);
   
    local love_chocolate_value = 0	--爱心巧克力
	local flowers_value = 0	--花束
	
	local material_id = 0			--随机材料id
	local material_value = 0		--随机获得材料数量
 
 	if(play_count % 5 == 0)then		--能被5整除为1次
 		--每玩5局随机获得1种合成材料
 		local sql = format("call sp_get_random_spring_gift(%d, '%s', %d)", user_info.userId, "tex", 4)
        	dblib.execute(sql, function(dt)
        		material_id = dt[1]["gift_id"]	or 1	--合成材料id
        		
        		--TraceError("游戏结束采集盘数,每玩5局随机获得1种合成材料，随机生成奖品ID:"..material_id.." USERID:"..user_info.userId)
                if(material_id <= 0) then
                	--TraceError("游戏结束采集盘数,每玩5局随机获得1种合成材料,失败")
                    return 
                end 
                
                --将合成材料加到用户userinfo中
                if(material_id == 1)then		--可可豆
                	
                	user_info.valentine_cocoa_value = user_info.valentine_cocoa_value + 1
            		material_value = 1
            		
            		--发送返回每玩5局随机获得1种合成材料
					valentine_lib.send_random_item(user_info, 3)
					
                elseif(material_id == 2)then		--牛奶
                
                	user_info.valentine_milk_value = user_info.valentine_milk_value + 1
            		material_value = 1
            		
            		--发送返回每玩5局随机获得1种合成材料
					valentine_lib.send_random_item(user_info, 4)
						
                elseif(material_id == 3)then		--果仁
                
                	user_info.valentine_nuts_value = user_info.valentine_nuts_value + 1
            		material_value = 1
            		
            		--发送返回每玩5局随机获得1种合成材料
					valentine_lib.send_random_item(user_info, 5)
						
                elseif(material_id == 4)then		--玫瑰花种子
                
                	user_info.valentine_seeds_value = user_info.valentine_seeds_value + 1
            		material_value = 1
            		
            		--发送返回每玩5局随机获得1种合成材料
					valentine_lib.send_random_item(user_info, 7)
					
                elseif(material_id == 5)then		--泥土
                
                	user_info.valentine_soil_value = user_info.valentine_soil_value + 1
            		material_value = 1
            		
            		--发送返回每玩5局随机获得1种合成材料
					valentine_lib.send_random_item(user_info, 8)
					
                elseif(material_id == 6)then		--养料
                	
            		user_info.valentine_nourishment_value = user_info.valentine_nourishment_value + 1
            		material_value = 1
            		
            		--发送返回每玩5局随机获得1种合成材料
					valentine_lib.send_random_item(user_info, 9)
            	
                end
                
                local item1 = user_info.propslist[8] or 0
 				local item2 = user_info.propslist[9] or 0
			 	local item3 = user_info.valentine_cocoa_value
			 	local item4 = user_info.valentine_milk_value
			 	local item5 = user_info.valentine_nuts_value
			 	local item6 = user_info.valentine_chocolate_value
			 	local item7 = user_info.valentine_seeds_value
			 	local item8 = user_info.valentine_soil_value
			 	local item9 = user_info.valentine_nourishment_value
			 	local item10 = user_info.valentine_rose_value
			
				--记录到数据库
			    local sqltemplet = "update t_valentine_activity set play_count = %d, cocoa_value = %d, milk_value = %d, nuts_value = %d, seeds_value = %d, soil_value = %d, nourishment_value = %d, sys_time = now() where user_id = %d;commit;";
			    local sql=string.format(sqltemplet, play_count, item3, item4, item5, item7, item8, item9, user_info.userId);
			    dblib.execute(sql);
			    
        	end)
  
 	end
 	
 	--记录盘数到数据库
    local sqltemplet = "update t_valentine_activity set play_count = %d, sys_time = now() where user_id = %d;commit;";
    local sql=string.format(sqltemplet, play_count, user_info.userId);
    dblib.execute(sql);
 
end

--定时刷新事件
valentine_lib.ontimecheck = function()
 
  	--活动一：时间有效性
	local check_time = valentine_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
        return;
    end
  
  	--10分钟要刷一次排名 和  更新年兽数据
	if(valentine_lib.refresh_invate_time == -1 or os.time() > valentine_lib.refresh_invate_time+60*10)then
	--if(valentine_lib.refresh_invate_time == -1 or os.time() > valentine_lib.refresh_invate_time+10*1)then
		----TraceError("定时刷新事件，10分钟要刷一次排名 ");
    	valentine_lib.refresh_invate_time = os.time();
    	valentine_lib.init_charm_ph();
 
    end
   
end
 
--使用红玫瑰/巧克力/爱心巧克力
function valentine_lib.on_recv_use(buf)
--[[
基本流程：

1、点击红玫瑰/巧克力/爱心巧克力获得奖品，剩余数量-1

2、显示使用的动画

3、随机获得对应奖励，动画文字提示随机取一条“太给力了，获得600金币！”/“厉害，获得1万金币！”/“还不错，获得1万金币！”,3秒消失

5、获得10万金币/1万筹码以上的奖后系统广播，“XXXX打开{什么花/巧克力}，获得10万金币奖励！”

补充需求：

1、数量为0时候，点击动画文字提示 “数量不足！” ,3秒消失



随机奖品： 
1. 200筹码
2. 2K筹码
3. 2万筹码
4. 小喇叭
5. “红心”礼物
6. 1K筹码
7. 1万筹码
8. 10万筹码
9. T人卡
10.“红唇”礼物
11.5K筹码
12.20万筹码
13.138万玛莎拉蒂
14.588万法拉利

]]	
 
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	
   	--TraceError("使用红玫瑰/巧克力/爱心巧克力,USERID:"..user_info.userId)
   
   	--检查时间有效性
	local check_time = valentine_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("使用红玫瑰/巧克力/爱心巧克力,时间过期， USERID:"..user_info.userId)
    	valentine_lib.send_use_result(user_info, -1, -1)
        return;
    end
     
    --收到的使用id
    local item_id = buf:readByte();
    
    --转换收到id
    local change_id = 0
    if(item_id == 1)then	--1，爱心巧克力
    	change_id = 3
    	--TraceError("使用红玫瑰/巧克力/爱心巧克力 收到的使用id:"..item_id.." 转换收到id:"..change_id)
    elseif(item_id == 6)then	--6，巧克力
    	change_id = 1
    	--TraceError("使用红玫瑰/巧克力/爱心巧克力 收到的使用id:"..item_id.." 转换收到id:"..change_id)
    elseif(item_id == 10)then	--10，红玫瑰
    	change_id = 2
    	--TraceError("使用红玫瑰/巧克力/爱心巧克力 收到的使用id:"..item_id.." 转换收到id:"..change_id)
    end
    
    --10，红玫瑰；6，巧克力；1，爱心巧克力
	local love_chocolate_value = user_info.propslist[8] or 0	--爱心巧克力
	--local flowers_value = user_info.propslist[9] or 0	--花束
	local chocolate_value = user_info.valentine_chocolate_value or 0	--巧克力
	local rose_value = user_info.valentine_rose_value or 0	--红玫瑰
  
  	local result = 0
  	local award_id = 0  --随机奖品ID
  	
  
    --使用巧克力魅力值：+1
	--使用爱心巧克力魅力值：+10
	--使用红玫瑰魅力值：+3
	--TraceError("使用红玫瑰/巧克力/爱心巧克力之前   魅力值："..user_info.valentine_charm_value.."  USERID:"..user_info.userId)
	local charm_value = 0	--魅力值
	
	--随机生成奖品ID
	local function spring_gift(user_info, change_id)
		 
        	local sql = format("call sp_get_random_spring_gift(%d, '%s', %d)", user_info.userId, "tex", change_id)
        	dblib.execute(sql, function(dt)
            	if(dt and #dt > 0)then
            		local prizeid = dt[1]["gift_id"]
	                
	                --TraceError("使用红玫瑰/巧克力/爱心巧克力,发奖，随机生成奖品ID:"..prizeid.." USERID:"..user_info.userId)
	                if(prizeid <= 0) then
	                	--TraceError("使用红玫瑰/巧克力/爱心巧克力,发奖，随机生成奖品ID,失败")
	                    return 
	                end 
 	 
 					--发奖
		 			if(change_id == 1)then	--巧克力
			   			--转换对应奖品ID
			            if(prizeid == 1)then	--200筹码
			            	award_id = 1	
			            	--加200筹码
			  				usermgr.addgold(user_info.userId, 200, 0, g_GoldType.baoxiang, -1);
			  				
			            elseif(prizeid == 2)then	--2K筹码
			            	award_id = 2	
			            	--加1K筹码
			  				usermgr.addgold(user_info.userId, 2000, 0, g_GoldType.baoxiang, -1);
			  				
			            elseif(prizeid == 3)then	--2万筹码
			            	award_id = 3	
			            	--2万筹码
			  				usermgr.addgold(user_info.userId, 20000, 0, g_GoldType.baoxiang, -1);
			  	
			            elseif(prizeid == 4)then	--小喇叭
			            	award_id = 4	
			            	--小喇叭怎么加
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, user_info)
			  	
			            elseif(prizeid == 5)then	--“红心”礼物
			            	award_id = 5	
			            	--加“红心”礼物
			  				gift_addgiftitem(user_info,9016,user_info.userId,user_info.nick, false)
			  				
			         	elseif(prizeid == 0)then	--异常
			  				--TraceError("使用巧克力 ,发奖，随机生成奖品ID,失败--异常 USERID:"..user_info.userId)
			  				return
			            end	
			        elseif(change_id == 2)then	--红玫瑰
			        	--转换对应奖品ID
			            if(prizeid == 1)then	--1K筹码
			            	award_id = 6	
			            	--加1K筹码
			  				usermgr.addgold(user_info.userId, 1000, 0, g_GoldType.baoxiang, -1);
			  				
			            elseif(prizeid == 2)then	--1W筹码
			            	award_id = 7	
			            	--加1W筹码
			  				usermgr.addgold(user_info.userId, 10000, 0, g_GoldType.baoxiang, -1);
			  				 
			            elseif(prizeid == 3)then	--10万筹码
			            	award_id = 8	
			            	--加10万筹码
			  				usermgr.addgold(user_info.userId, 100000, 0, g_GoldType.baoxiang, -1);
			  				
			  				--系统广播，“XXXX使用{什么花/巧克力}，获得XXX奖励！”
			  				local user_nick = user_info.nick
							user_nick = valentine_lib._tosqlstr(user_nick).."   "
			  				local msg = tex_lan.get_msg(user_info, "valentine_activity_msg_awards_1"); 
							local msg1 = tex_lan.get_msg(user_info, "valentine_activity_msg_awards"); 
							msg1 = string.format(msg1,5); 
							BroadcastMsg(_U(msg)..user_nick.._U(msg1),0)
			  	
			            elseif(prizeid == 4)then	--T人卡
			            	award_id = 9
			            	--T人卡怎么加
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 1, user_info)
			  	
			            elseif(prizeid == 5)then	--“红唇”礼物
			            	award_id = 10
			            	--加“红唇”礼物
			  				gift_addgiftitem(user_info,9017,user_info.userId,user_info.nick, false)
			  		 
			  			elseif(prizeid == 0)then	--异常
			  				--TraceError("使用 红玫瑰 ,发奖，随机生成奖品ID,失败--异常 USERID:"..user_info.userId)
			  				return
			            end	
			   		elseif(change_id == 3)then		--爱心巧克力
			   			--转换对应奖品ID
			            if(prizeid == 1)then	--T人卡*2
			            	award_id = 15  --T人卡*2	
			            	--加T人卡*2
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 2, user_info)
			          
			            elseif(prizeid == 2)then	--小喇叭*2
			            	award_id = 16	
			            	--小喇叭*2
			  				--小喇叭怎么加
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 2, user_info)
			  				  
			            elseif(prizeid == 3)then	--1万筹码
			            	award_id = 7	
			            	--加1万筹码
			  				usermgr.addgold(user_info.userId, 10000, 0, g_GoldType.baoxiang, -1);
			  				 
			  			elseif(prizeid == 4)then	--2万筹码
			            	award_id = 3	
			            	--加2万筹码
			  				usermgr.addgold(user_info.userId, 20000, 0, g_GoldType.baoxiang, -1);
			  				 
			  			elseif(prizeid == 5)then	--20万筹码
			            	award_id = 12	
			            	--20万筹码
							usermgr.addgold(user_info.userId, 200000, 0, g_GoldType.baoxiang, -1);
							
							--系统广播，“XXXX使用{什么花/巧克力}，获得XXX奖励！”
			  				local user_nick = user_info.nick
							user_nick = valentine_lib._tosqlstr(user_nick).."   "
			  				local msg = tex_lan.get_msg(user_info, "valentine_activity_msg_awards_1"); 
							local msg1 = tex_lan.get_msg(user_info, "valentine_activity_msg_awards_2"); 
							msg1 = string.format(msg1,5); 
							BroadcastMsg(_U(msg)..user_nick.._U(msg1),0)
							
						elseif(prizeid == 6)then	--138万玛莎拉蒂
			            	award_id = 13	--138万玛莎拉蒂
			            	--138万玛莎拉蒂
			  				gift_addgiftitem(user_info,5021,user_info.userId,user_info.nick, false)	
			  				
			  				--系统广播，“XXXX使用{什么花/巧克力}，获得XXX奖励！”
			  				local user_nick = user_info.nick
							user_nick = valentine_lib._tosqlstr(user_nick).."   "
			  				local msg = tex_lan.get_msg(user_info, "valentine_activity_msg_awards_1"); 
							local msg1 = tex_lan.get_msg(user_info, "valentine_activity_msg_awards_3"); 
							msg1 = string.format(msg1,5); 
							BroadcastMsg(_U(msg)..user_nick.._U(msg1),0)
			 
			            elseif(prizeid == 7)then	--588万法拉利
			            	award_id = 14		--588万法拉利
			            	--588万法拉利
			  				gift_addgiftitem(user_info,5024,user_info.userId,user_info.nick, false)	
			  				
			  				--系统广播，“XXXX使用{什么花/巧克力}，获得XXX奖励！”
			  				local user_nick = user_info.nick
							user_nick = valentine_lib._tosqlstr(user_nick).."   "
			  				local msg = tex_lan.get_msg(user_info, "valentine_activity_msg_awards_1"); 
							local msg1 = tex_lan.get_msg(user_info, "valentine_activity_msg_awards_4"); 
							msg1 = string.format(msg1,5); 
							BroadcastMsg(_U(msg)..user_nick.._U(msg1),0)
			  	 
			  			elseif(prizeid == 0)then	--异常
			  				--TraceError("使用 爱心巧克力,发奖，随机生成奖品ID,失败--异常 USERID:"..user_info.userId)
			  				return
			            end	
				    end
				   
				   --发送使用红玫瑰/巧克力/爱心巧克力成功结果
			    	result = charm_value
			    	--TraceError("使用红玫瑰/巧克力/爱心巧克力之后,--， USERID:"..user_info.userId.." result:"..result.." award_id:"..award_id)
					valentine_lib.send_use_result(user_info, result, award_id)
					
					--发送材料和道具等信息
				 	local item1 = user_info.propslist[8] or 0
 					local item2 = user_info.propslist[9] or 0
				 	local item3 = user_info.valentine_cocoa_value
				 	local item4 = user_info.valentine_milk_value
				 	local item5 = user_info.valentine_nuts_value
				 	local item6 = user_info.valentine_chocolate_value
				 	local item7 = user_info.valentine_seeds_value
				 	local item8 = user_info.valentine_soil_value
				 	local item9 = user_info.valentine_nourishment_value
				 	local item10 = user_info.valentine_rose_value
				 	valentine_lib.send_item_info(user_info, item1, item2, item3, item4, item5, item6, item7, item8, item9, item10)
	            end
	        end)
	   
	end
  	
   	if(change_id == 1)then	--巧克力
   		
   		if(chocolate_value  > 0)then
   			charm_value = 1	--使用巧克力魅力值：+1
    	
   			--更新用户魅力值
   			user_info.valentine_charm_value = user_info.valentine_charm_value + charm_value
 
   			--减巧克力
   			chocolate_value = chocolate_value - 1
   			user_info.valentine_chocolate_value = chocolate_value
   			 
  			--随机生成奖品ID
			spring_gift(user_info, change_id)
    	 
   		else
   			--TraceError("使用巧克力,--巧克力不足， USERID:"..user_info.userId)
   			--发送使用巧克力失败结果
	    	result = 0
	    	award_id = -1
			valentine_lib.send_use_result(user_info, result, award_id)
	        return;
   		end
       
    elseif(change_id == 2)then	--红玫瑰
    
    	if(rose_value > 0)then
   			charm_value = 3	--使用红玫瑰魅力值：+3
   		 
   			--更新用户魅力值
   			user_info.valentine_charm_value = user_info.valentine_charm_value + charm_value
 
   			--减红玫瑰
   			rose_value = rose_value - 1
   			user_info.valentine_rose_value = rose_value
   			 
  	 		--随机生成奖品ID
			spring_gift(user_info, change_id)
     
   		else
   			--TraceError("使用红玫瑰,--红玫瑰不足， USERID:"..user_info.userId)
   			--发送使用红玫瑰失败结果
	    	result = 0
	    	award_id = -1
			valentine_lib.send_use_result(user_info, result, award_id)
	        return;
   		end
    elseif(change_id == 3)then	--爱心巧克力
    	if(love_chocolate_value  > 0)then
   			charm_value = 10	--使用爱心巧克力魅力值：+10
   		 
   			--更新用户魅力值
   			user_info.valentine_charm_value = user_info.valentine_charm_value + charm_value
 
   			--减爱心巧克力
   			love_chocolate_value = love_chocolate_value - 1
   			user_info.propslist[8] = love_chocolate_value
   			
   			local complete_callback_func = function(tools_count)
      	 		--随机生成奖品ID
   				spring_gift(user_info, change_id)
	 
    		end
   		 	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.love_chocolate_id, -1, user_info, complete_callback_func)
   		else
   			--TraceError("使用爱心巧克力,--爱心巧克力不足， USERID:"..user_info.userId)
   			--发送使用爱心巧克力失败结果
	    	result = 0
	    	award_id = -1
			valentine_lib.send_use_result(user_info, result, award_id)
	        return;
   		end
    else
    	
    	--TraceError("使用爱心巧克力 红玫瑰 巧克力，收到错误的攻击id");
    	--发送攻击年兽结果
    	result = 0
    	award_id = -1
		valentine_lib.send_use_result(user_info, result, award_id)
        return;
   	end
   	
   	--TraceError("使用爱心巧克力 红玫瑰 巧克力之后  用户魅力值："..user_info.valentine_charm_value.."  USERID:"..user_info.userId)
   
   --发送排行榜
	--找自己的排行榜
	local charm_paimin_list = valentine_lib.charm_ph_list	--排行榜数组
	local my_mc = -1;
	local my_attack_value = 0;
	my_mc,my_attack_value = valentine_lib.get_my_pm(charm_paimin_list,user_info)
	if(user_info.valentine_charm_value ~= nil)then
		my_attack_value = user_info.valentine_charm_value
	end
	
	local libao_sign = user_info.valentine_libao_sign		----是否领取了“神秘礼包”标记
	valentine_lib.send_ph_list(user_info, libao_sign, my_attack_value, my_mc, charm_paimin_list)

	--更新 数据库
    local sqltemplet = "update t_valentine_activity set user_nick = '%s', charm_value = %d, love_chocolate_value = %d, chocolate_value = %d, rose_value = %d where user_id = %d;commit;";
    local tmp_user_nick = valentine_lib._tosqlstr(user_info.nick)
    local sql=string.format(sqltemplet, tmp_user_nick, user_info.valentine_charm_value, love_chocolate_value, chocolate_value, rose_value, user_info.userId);
    dblib.execute(sql);
 
end

--初始化排行榜
function valentine_lib.init_charm_ph()
--[[
查看魅力排名

基本流程：

1、显示前20名玩家的魅力排名

2、排名标签为 排名、昵称（支持最多16字符）、魅力（支持6位数字）、奖励（最多10个字符）

4、在排名下方显示自己伤害值

补充需求：

1、魅力=打开情谊礼包*1+打开黄金礼包*10+打开浪漫礼包*3+使用花束*15

2、同魅力按时间先后排

3、前20名奖励在活动结束后人工发放

4、排名10分钟更新1次


]]
 
	--TraceError("-->>>>初始化排行榜")
	valentine_lib.charm_ph_list = {}; --魅力排名
 
	--初始化排行
	local init_ph=function(ph_list)
		local sql="select user_id,user_nick,charm_value from t_valentine_activity where charm_value >= 1 order by charm_value desc LIMIT 20"
		sql=string.format(sql)
		dblib.execute(sql,function(dt)	
				if(dt~=nil and  #dt>0)then
					for i=1,#dt do
						local bufftable ={
						  	    mingci = i, 
			                    user_id = dt[i].user_id,
			                    nick_name = dt[i].user_nick,
			                    charm_value = dt[i].charm_value,   
		                }	                
						table.insert(ph_list,bufftable)
					end
				end
	    end)
    end
    
    --初始化魅力排名
    init_ph(valentine_lib.charm_ph_list)
 
end

--请求排行榜
function valentine_lib.on_recv_ph_list(buf)
	local user_info = userlist[getuserid(buf)]; 
	if not user_info then return end;
	--TraceError("--请求排行榜,userid:"..user_info.userId)
 
   	--检查时间有效性
	local check_time = valentine_lib.check_datetime()
    if(check_time == 0) then
    	--TraceError("请求排行榜,时间过期， USERID:"..user_info.userId)
        return;
    end
 
	local charm_paimin_list = valentine_lib.charm_ph_list
	
	if(user_info == nil)then return end
	
	--查询自己的名次，如果没有名次就返回-1
	--返回名次，我的攻击成绩
	local my_mc = -1;
	local my_charm_value = 0;
 
	--找自己的排行榜
	my_mc,my_charm_value = valentine_lib.get_my_pm(charm_paimin_list,user_info)
	
	local libao_sign = user_info.valentine_libao_sign		----是否领取了“驱魔礼包”标记
 
 	--发送排行榜
	valentine_lib.send_ph_list(user_info, libao_sign, my_attack_value, my_mc, charm_paimin_list)  
end

--找自己的排行榜
valentine_lib.get_my_pm = function(ph_list,user_info)

		local mc = -1
		if (ph_list == nil) then return -1,0 end
		
		for i = 1, #ph_list do
			if(ph_list[i].user_id == user_info.userId)then
				return i, ph_list[i].charm_value
			end
		end

		return -1,0;--没有找到对应玩家的记录，认为他没有成绩
end

--请求活动时间状态
function valentine_lib.on_recv_activity_stat(buf)
	
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
 
	--检查时间有效性
	local check_time = valentine_lib.check_datetime()
	
	--TraceError("--请求活动时间状态-->>"..check_time)
	
	if(check_time == 0)then
		return
	end
	
	--判断是否有材料
	local item1 = user_info.propslist[8] or 0
 	local item2 = user_info.propslist[9] or 0
 	local item3 = user_info.valentine_cocoa_value
 	local item4 = user_info.valentine_milk_value
 	local item5 = user_info.valentine_nuts_value
 	local item6 = user_info.valentine_chocolate_value
 	local item7 = user_info.valentine_seeds_value
 	local item8 = user_info.valentine_soil_value
 	local item9 = user_info.valentine_nourishment_value
 	local item10 = user_info.valentine_rose_value
	if(item1 > 0 or item2 > 0 or item3 > 0 or item4 > 0 or item5 > 0 or item6 > 0 or item7 > 0 or item8 > 0 or item9 > 0 or item10 > 0)then
		check_time = 2;		--活动有效,有材料
	end
	 
	--用户盘数
	local play_count = 0
    if(user_info.valentine_play_count == nil)then
    	user_info.valentine_play_count = 0	
    	play_count = 0
    else
    	play_count = user_info.valentine_play_count
    end
  
 	--通知客户端
    valentine_lib.net_send_playnum(user_info, check_time, play_count);
end

--请求打开活动面板
function valentine_lib.on_recv_activation(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
 
   	--TraceError("请求打开活动面板,USERID:"..user_info.userId)
   
   	--检查时间有效性
	local check_time = valentine_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("请求打开活动面板,时间过期， USERID:"..user_info.userId)
        return;
    end
    
    --初始化或更新情人节表
	local user_nick = user_info.nick
	user_nick = valentine_lib._tosqlstr(user_nick)
	local sql = "insert ignore into t_valentine_activity (user_id, user_nick, charm_value) ";
    sql = sql.."values(%d, '%s   ', %d);commit;";   
    sql = string.format(sql, user_info.userId, user_nick, 0);
	dblib.execute(sql)
	 
	
	--查询或更新自己数据
	valentine_lib.query_db(user_info)
	
	--发送材料和道具等信息
 	local item1 = user_info.propslist[8] or 0
 	local item2 = user_info.propslist[9] or 0
 	local item3 = user_info.valentine_cocoa_value
 	local item4 = user_info.valentine_milk_value
 	local item5 = user_info.valentine_nuts_value
 	local item6 = user_info.valentine_chocolate_value
 	local item7 = user_info.valentine_seeds_value
 	local item8 = user_info.valentine_soil_value
 	local item9 = user_info.valentine_nourishment_value
 	local item10 = user_info.valentine_rose_value
 	valentine_lib.send_item_info(user_info, item1, item2, item3, item4, item5, item6, item7, item8, item9, item10)
	
	--发送排行榜
	--找自己的排行榜
	local charm_paimin_list = valentine_lib.charm_ph_list	--排行榜数组
	local my_mc = -1;
	local my_attack_value = 0;
	my_mc,my_attack_value = valentine_lib.get_my_pm(charm_paimin_list,user_info)
	if(user_info.valentine_charm_value ~= nil)then
		my_attack_value = user_info.valentine_charm_value
	end
	
	local libao_sign = user_info.valentine_libao_sign		----是否领取了“神秘礼包”标记
	valentine_lib.send_ph_list(user_info, libao_sign, my_attack_value, my_mc, charm_paimin_list)
	
end

--请求购买
function valentine_lib.on_recv_buy(buf)
--[[
点击【点此购买】，消耗所需筹码/金币，购买对应材料

    购买成功，文字动画提示“购买成功！”
 
    钱不够，按钮灰色禁用
 
    德州使用牌桌外的筹码购买
 购买类型：1，巧克力；2，玫瑰花； 
  ]]
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   
   	--收到购买id
    local buy_type_id = buf:readByte();
    	
   	--TraceError("请求购买,USERID:"..user_info.userId.." 收到购买id:"..buy_type_id)
   	
   	--转换buy_id
   	local buy_id = 0
   	if(buy_type_id == 1)then	--1，爱心巧克力
   		buy_id = 3
   	else
   		--TraceError("请求购买  收到错误id")
   		return
   	end
   	--[[
   	if(buy_type_id == 6)then	--1，巧克力
   		buy_id = 1
   	elseif(buy_type_id == 10)then		--2，玫瑰花
   		buy_id = 2
   	else
   		--TraceError("请求购买  收到错误id")
   		return
   	end
   	]]
   	
   	--local chocolate_value = 0		--巧克力
   	--local rose_value = 0			--红玫瑰
 	local result = 0
    local gold = get_canuse_gold(user_info)		--获得用户筹码

	--chocolate_value = user_info.valentine_chocolate_value	--巧克力
	--rose_value = user_info.valentine_rose_value	--红玫瑰
	local love_chocolate_value = user_info.propslist[8] or 0	--爱心巧克力
	
   	--检查时间有效性
	local check_time = valentine_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("请求购买,时间过期， USERID:"..user_info.userId)
    	
    	--发送购买结果
    	result = 2
    	if(buy_id == 3)then		--爱心巧克力
    		valentine_lib.send_buy_result(user_info, buy_id, love_chocolate_value, result)
        	return;
        end
    	--[[
    	if(buy_id == 1)then		--巧克力
    		valentine_lib.send_buy_result(user_info, buy_id, chocolate_value, result)
        	return;
    	elseif(buy_id == 2)then		--红玫瑰
    		valentine_lib.send_buy_result(user_info, buy_id, rose_value, result)
        	return;
    	end
		]]
		
    end
 
 	--判断是否有钱
 	if(buy_id == 1)then		--巧克力
		if(gold < 10000)then
	    	--TraceError("购买巧克力,钱不够， USERID:"..user_info.userId)
	    	
	    	--发送购买结果
	    	result = 0
			valentine_lib.send_buy_result(user_info, buy_id, chocolate_value, result)
	    	return
	    else
	    	--可以购买
	    	--减筹码
			usermgr.addgold(user_info.userId, -10000, 0, g_GoldType.baoxiang, -1);
			
			--加巧克力
			chocolate_value = chocolate_value + 1
			user_info.valentine_chocolate_value = chocolate_value
			
			--发送购买成功
			result = 1
		  	valentine_lib.send_buy_result(user_info, buy_id, chocolate_value, result)
    	end
	elseif(buy_id == 2)then		--红玫瑰
		if(gold < 30000)then
	    	--TraceError("购买红玫瑰,钱不够， USERID:"..user_info.userId)
	    	
	    	--发送购买结果
	    	result = 0
			valentine_lib.send_buy_result(user_info, buy_id, rose_value, result)
	    	return
	    else
	    	--可以购买
	    	--减筹码
			usermgr.addgold(user_info.userId, -30000, 0, g_GoldType.baoxiang, -1);
			
			--加红玫瑰
			rose_value = rose_value + 1
			user_info.valentine_rose_value = rose_value
			
			--发送购买成功
			result = 1
		  	valentine_lib.send_buy_result(user_info, buy_id, rose_value, result)
    	end
    elseif(buy_id == 3)then		--爱心巧克力
    	if(gold < 100000)then
    		--TraceError("购买爱心巧克力,钱不够， USERID:"..user_info.userId)
	    	
	    	--发送购买结果
	    	result = 0
			valentine_lib.send_buy_result(user_info, buy_id, love_chocolate_value, result)
	    	return
	    else
	    	--可以购买
	    	--减筹码
			usermgr.addgold(user_info.userId, -100000, 0, g_GoldType.baoxiang, -1);
 
			--加爱心巧克力
			love_chocolate_value = love_chocolate_value + 1
			
    		user_info.propslist[8] = love_chocolate_value
    		
   			local complete_callback_func = function(tools_count)
   				result = 1
      	 		--发送购买成功
				valentine_lib.send_buy_result(user_info, 1, love_chocolate_value, result)
    		end
   		 	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.love_chocolate_id, 1, user_info, complete_callback_func)
    	
    	end
	end
    
    --[[
    --更新 数据库
    local sqltemplet = "update t_valentine_activity set charm_value = %d, chocolate_value = %d, rose_value = %d where user_id = %d;commit;";
    local sql=string.format(sqltemplet, user_info.valentine_charm_value, chocolate_value, rose_value, user_info.userId);
    dblib.execute(sql);
    ]]
    
    --更新 数据库
    local sqltemplet = "update t_valentine_activity set love_chocolate_value = %d where user_id = %d;commit;";
    local sql=string.format(sqltemplet, love_chocolate_value, user_info.userId);
    dblib.execute(sql);
    
end

--请求所有材料等信息
function valentine_lib.on_recv_items_info(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	
   	--TraceError("请求所有材料等信息,USERID:"..user_info.userId)
   
   	--检查时间有效性
	local check_time = valentine_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("返回请求所有材料等信息,时间过期， USERID:"..user_info.userId)
        return;
    end
    
    --发送材料和道具等信息
 	local item1 = user_info.propslist[8] or 0
 	local item2 = user_info.propslist[9] or 0
 	local item3 = user_info.valentine_cocoa_value
 	local item4 = user_info.valentine_milk_value
 	local item5 = user_info.valentine_nuts_value
 	local item6 = user_info.valentine_chocolate_value
 	local item7 = user_info.valentine_seeds_value
 	local item8 = user_info.valentine_soil_value
 	local item9 = user_info.valentine_nourishment_value
 	local item10 = user_info.valentine_rose_value
 	valentine_lib.send_item_info(user_info, item1, item2, item3, item4, item5, item6, item7, item8, item9, item10)
 
end

--通知服务端，请求领取“神秘礼包”
function valentine_lib.on_recv_packs(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	
   	--TraceError("请求领取“神秘礼包”,USERID:"..user_info.userId)
   
   	--检查时间有效性
	local check_time = valentine_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("请求领取“神秘礼包”,时间过期， USERID:"..user_info.userId)
        return;
    end
    
    if(user_info.valentine_libao_sign == 1)then
    	--TraceError("请求领取“神秘礼包”,已领过， USERID:"..user_info.userId)
    	return
    end
    
    local charm_value = user_info.valentine_charm_value
    local result = 0
    
    --我的魅力值大于100时可领取神秘礼包
    if(charm_value > 99)then
    	--TraceError("请求领取“神秘礼包” 领取成功,USERID:"..user_info.userId.." charm_value:"..charm_value)
    	--标记领取
	    user_info.valentine_libao_sign = 1
	    
	    --更新数据库
	    local sqltemplet = "update t_valentine_activity set libao_sign = 1 where user_id = %d;commit;";             
		dblib.execute(string.format(sqltemplet, user_info.userId))
		
		--加获得10万筹码
		usermgr.addgold(user_info.userId, 100000, 0, g_GoldType.baoxiang, -1);
	 
		--发送请求领取“神秘礼包”结果
		result = 1
    	valentine_lib.send_exorcist_packs_result(user_info, result)
    	
    	--系统广播，“XXXX领取神秘礼包，获得10万筹码！”
    	local user_nick = user_info.nick
		user_nick = valentine_lib._tosqlstr(user_nick).."   "		--火星文处理
		local msg = tex_lan.get_msg(user_info, "valentine_activity_msg_awards_1"); 
		local msg1 = tex_lan.get_msg(user_info, "valentine_activity_msg"); 
		msg1 = string.format(msg1); 
		BroadcastMsg(_U(msg)..user_nick.._U(msg1),0)
    else
    	--TraceError("请求领取“驱魔礼包” 失败,USERID:"..user_info.userId.." charm_value:"..charm_value)
    	--发送请求领取“神秘礼包”结果
    	valentine_lib.send_exorcist_packs_result(user_info, result)
    end
   
end

--请求合成：1，爱心巧克力；2，花束； 6，巧克力；10，红玫瑰；
function valentine_lib.on_recv_composite(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   
   	--检查时间有效性
	local check_time = valentine_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("请求合成,时间过期， USERID:"..user_info.userId)
        return;
    end
    
    --收到合成id  合成类型：1，爱心巧克力；2，花束； 6，巧克力；10，红玫瑰；
    local composite_id = buf:readByte();
    	
   	--TraceError("请求 合成,USERID:"..user_info.userId.." 收到合成id:"..composite_id)
    
    --所有材料和道具等信息
 	local item1 = user_info.propslist[8] or 0
 	local item2 = user_info.propslist[9] or 0
 	local item3 = user_info.valentine_cocoa_value
 	local item4 = user_info.valentine_milk_value
 	local item5 = user_info.valentine_nuts_value
 	local item6 = user_info.valentine_chocolate_value
 	local item7 = user_info.valentine_seeds_value
 	local item8 = user_info.valentine_soil_value
 	local item9 = user_info.valentine_nourishment_value
 	local item10 = user_info.valentine_rose_value
 	
 	local result = 0		--合成结果
  
    --判断合成id
    if(composite_id == 1)then 		--1，爱心巧克力
    	--判断巧克力数量
    	if(item6 < 10)then
    		--TraceError("请求合成  1，爱心巧克力   巧克力数量不足    用户id："..user_info.userId)
    		
    		--发送合成结果
			valentine_lib.net_send_composite_result(user_info, result)
    		return
    	else
    		--减巧克力
    		item6 = item6 - 10
    		user_info.valentine_chocolate_value = item6
    		
    		--TraceError("1111111111111111请求 合成,USERID:"..user_info.userId.." item6:"..item6)
    		
    		--加爱心巧克力
    		item1 = item1 + 1
    		user_info.propslist[8] = item1
    		
   			local complete_callback_func = function(tools_count)
   				result = 1
      	 		--发送合成结果
				valentine_lib.net_send_composite_result(user_info, result)
    		end
   		 	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.love_chocolate_id, 1, user_info, complete_callback_func)
    	end
  	
    elseif(composite_id == 2)then 		--2，花束
    	--判断玫瑰花数量
    	if(item10 < 10)then
    		--TraceError("请求合成  花束   玫瑰花数量不足    用户id："..user_info.userId)
    		
    		--发送合成结果
			valentine_lib.net_send_composite_result(user_info, result)
    		return
    	else
    		--减玫瑰花
    		item10 = item10 - 10
    		user_info.valentine_rose_value = item10
    		
    		--加花束
    		item2 = item2 + 1
    		user_info.propslist[9] = item2
    		
    		local complete_callback_func = function(tools_count)
   				result = 1
      	 		--发送合成结果
				valentine_lib.net_send_composite_result(user_info, result)
    		end
   		 	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.flowers_id, 1, user_info, complete_callback_func)
    	
    	end
    	
    elseif(composite_id == 6)then 		-- 6，巧克力
    	--判断可可豆、牛奶、果仁数量 
    	if(item3 < 1 or item4 < 1 or item5 < 1)then
    		--TraceError("请求合成  可可豆、牛奶、果仁数量 数量不足    用户id："..user_info.userId)
    		
    		--发送合成结果
			valentine_lib.net_send_composite_result(user_info, result)
    		return
    	else
    		--减可可豆、牛奶、果仁数量 
    		item3 = item3 - 1  
    		item4 = item4 - 1 
    		item5 = item5 - 1
    		user_info.valentine_cocoa_value = item3
 			user_info.valentine_milk_value = item4
 			user_info.valentine_nuts_value = item5
 			
    		--加巧克力
    		item6 = item6 + 1
    		user_info.valentine_chocolate_value = item6
     
     		--发送合成结果
    		result = 1
      	 	valentine_lib.net_send_composite_result(user_info, result)
    	end
    	
    elseif(composite_id == 10)then 		-- 10，红玫瑰；
    		--判断玫瑰花种子、泥土、养料数量
    		if(item7 < 1 or item8 < 1 or item9 < 1)then
    			--TraceError("请求合成  玫瑰花种子、泥土、养料数量不足    用户id："..user_info.userId)
    		
	    		--发送合成结果
				valentine_lib.net_send_composite_result(user_info, result)
	    		return
    		end
    		
    		--减玫瑰花种子、泥土、养料数量 
    		item7 = item7 - 1  
    		item8 = item8 - 1 
    		item9 = item9 - 1
    		user_info.valentine_seeds_value = item7
 			user_info.valentine_soil_value = item8
 			user_info.valentine_nourishment_value = item9
  
    		--加红玫瑰
    		item10 = item10 + 1
    		user_info.valentine_rose_value = item10
     
     		--发送合成结果
    		result = 1
      	 	valentine_lib.net_send_composite_result(user_info, result)
    
    else
    	--TraceError("请求合成 接收错误id 用户id："..user_info.userId)
    	return
    end
   
    --更新 数据库
    --TraceError("2222222222222222222222222请求 合成,USERID:"..user_info.userId.." item6:"..item6)
    local sqltemplet = "update t_valentine_activity set love_chocolate_value = %d, flowers_value = %d, cocoa_value = %d, milk_value = %d, nuts_value = %d, chocolate_value = %d, seeds_value = %d, soil_value = %d, nourishment_value = %d, rose_value = %d where user_id = %d;commit;";
    local sql=string.format(sqltemplet, item1, item2, item3, item4, item5, item6, item7, item8, item9, item10, user_info.userId);
    dblib.execute(sql);
        
    --发送材料和道具等信息
    valentine_lib.send_item_info(user_info, item1, item2, item3, item4, item5, item6, item7, item8, item9, item10)
end

--发送合成结果
valentine_lib.net_send_composite_result = function(user_info, result)
  	--TraceError("发送合成结果,userid:"..user_info.userId.." result->"..result)
	netlib.send(function(buf)
	    buf:writeString("HDQRKILL")
	    buf:writeByte(result)	 --0，合成失败；1，合成成功
	    end,user_info.ip,user_info.port) 
end

--发送盘数和时间状态
valentine_lib.net_send_playnum = function(user_info, check_time, play_count)
  	--TraceError(" 发送盘数和时间状态,userid:"..user_info.userId.." check_time->"..check_time.." play_count:"..play_count)
	netlib.send(function(buf)
	    buf:writeString("HDQRDATE")
	    buf:writeByte(check_time)	 --0，活动无效（服务端也可不发）；1，活动有效；2,有材料   5，活动结束，保留一天
	    buf:writeInt(play_count)	--玩家玩的盘数
	    end,user_info.ip,user_info.port) 
end
 
--发送使用红玫瑰/巧克力/爱心巧克力结果
function valentine_lib.send_use_result(user_info, result, award_id)
	--TraceError("发送使用红玫瑰/巧克力/爱心巧克力结果，userid:"..user_info.userId.." result:"..result.." award_id:"..award_id);
	netlib.send(function(buf)
            buf:writeString("HDQRUSE");
            buf:writeInt(result);
            buf:writeInt(award_id);
        end,user_info.ip,user_info.port);
end

 
--发送排行榜
function valentine_lib.send_ph_list(user_info, libao_sign, my_charm_value, my_mc, charm_paimin_list)
	--TraceError("发送排行榜，libao_sign:"..libao_sign.." my_charm_value"..my_charm_value.." my_mc:"..my_mc)
	----TraceError(charm_paimin_list)
	local send_len = 20; --默认发20条信息
	netlib.send(function(buf)
    	buf:writeString("HDQRLIST")
    	buf:writeByte(libao_sign or 0)		--是否领取了“神秘礼包”：0，未领取；1，已领取；
	    buf:writeInt(my_charm_value or 0)	--我的魅力值
	    buf:writeInt(my_mc or 0)	--我的排名
 
		if send_len > #charm_paimin_list then send_len = #charm_paimin_list end --最多发20条信息
		--TraceError("发送排行榜，send_len:"..send_len)
		
		 buf:writeInt(send_len)
			--再发其他人的
	        for i = 1,send_len do
		        buf:writeInt(charm_paimin_list[i].mingci)	--名次
		        buf:writeInt(charm_paimin_list[i].user_id) --玩家ID
		        buf:writeString(charm_paimin_list[i].nick_name) --昵称
		        buf:writeInt(charm_paimin_list[i].charm_value) --玩家攻击成绩
              
	        end
     	end,user_info.ip,user_info.port) 
end
 
--发送购买结果
function valentine_lib.send_buy_result(user_info, buy_id, items_value, result)
	--TraceError("发送购买结果,USERID:"..user_info.userId.." items_value:"..items_value.." result:"..result.." buy_id:"..buy_id)
	netlib.send(function(buf)
            buf:writeString("HDQRBUY");
            buf:writeInt(result);		--0，购买失败，筹码不足；1，购买成功；2，购买失败，活动已过期；3，购买失败，其它原因；
            buf:writeByte(buy_id);
            buf:writeInt(items_value);		--材料的数量
        end,user_info.ip,user_info.port);
end


--发送材料和道具等信息
function valentine_lib.send_item_info(user_info, item1, item2, item3, item4, item5, item6, item7, item8, item9, item10)
	  --TraceError("发送材料和道具等信息,USERID:"..user_info.userId.." 爱心巧克力数量:"..item1.." 花束数量:"..item2.." 可可豆数量:"..item3.." 牛奶数量:"..item4.." 果仁数量:"..item5.." 巧克力数量:"..item6.." 玫瑰花种子数量:"..item7.." 泥土数量:"..item8.." 养料数量:"..item9.." 红玫瑰数量:"..item10)
	  netlib.send(function(buf)
            buf:writeString("HDQRVALUE");
            buf:writeInt(item1);		--爱心巧克力数量
            buf:writeInt(item2);		--花束数量
            buf:writeInt(item3);		--可可豆数量
            buf:writeInt(item4);		--牛奶数量
            buf:writeInt(item5);		--果仁数量
            buf:writeInt(item6);		--巧克力数量
            buf:writeInt(item7);		--玫瑰花种子数量
            buf:writeInt(item8);		--泥土数量
            buf:writeInt(item9);		--养料数量
            buf:writeInt(item10);		--红玫瑰数量
        end,user_info.ip,user_info.port);
end
 
--发送请求领取“神秘礼包”结果
function valentine_lib.send_exorcist_packs_result(user_info, result)
	--TraceError("发送请求领取“神秘礼包”结果,USERID:"..user_info.userId.." result:"..result)
	 netlib.send(function(buf)
            buf:writeString("HDQRGIFTEX");
            buf:writeByte(result);		--0，领取失败，未达到领取条件；1，领取成功；2，已领取；3，领取失败，其它原因；
        end,user_info.ip,user_info.port);
end

--发送返回每玩5局随机获得1种合成材料
function valentine_lib.send_random_item(user_info, items_id)
	--TraceError("发送返回每玩5局随机获得1种合成材料,USERID:"..user_info.userId.." items_id:"..items_id)
	 netlib.send(function(buf)
            buf:writeString("HDQRRANDOMITEMS");
            buf:writeByte(items_id);		--合成材料类型：3)可可豆数量  4)牛奶数量	5)果仁数量  7)玫瑰花种子数量  8)泥土数量  9)养料数量
        end,user_info.ip,user_info.port);
end


--协议命令
cmd_tex_match_handler = 
{
	["HDQRDATE"] = valentine_lib.on_recv_activity_stat, --请求活动时间状态
    ["HDQRPANEL"] = valentine_lib.on_recv_activation, -- 请求打开活动面板
    ["HDQRLIST"] = valentine_lib.on_recv_ph_list, -- --请求排行榜 
    ["HDQRVALUE"] = valentine_lib.on_recv_items_info, 	--请求所有材料等信息
    ["HDQRUSE"] = valentine_lib.on_recv_use, --使用红玫瑰/巧克力/爱心巧克力
    ["HDQRBUY"] = valentine_lib.on_recv_buy,--请求购买
    ["HDQRGIFTEX"] = valentine_lib.on_recv_packs ,--通知服务端，请求领取“神秘礼包”
	["HDQRKILL"] = valentine_lib.on_recv_composite, --请求合成：1，爱心巧克力；2，花束； 6，巧克力；10，红玫瑰；
}

--加载插件的回调
for k, v in pairs(cmd_tex_match_handler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("h2_on_user_login", valentine_lib.on_after_user_login);
eventmgr:addEventListener("timer_minute", valentine_lib.ontimecheck);