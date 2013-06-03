TraceError("init lottery_activity...")
if lottery_lib and lottery_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", lottery_lib.on_after_user_login);
end


if not lottery_lib then
    lottery_lib = _S
    {
        on_after_user_login = NULL_FUNC,--登陆后做的事
		check_datetime = NULL_FUNC,	--检查有效时间，限时问题
		on_recv_click_award = NULL_FUNC,	--接收点取领取
		on_recv_activ_stat = NULL_FUNC,		--请求活动时间状态
		check_bottom_stat = NULL_FUNC,		--再次判断活动按钮状态
        
        statime = "2012-01-07 09:00:00",  --活动开始时间
    	endtime = "2012-01-10 12:00:00",  --活动结束时间
    	lottery_time = "2012-01-14 00:00:00",	--领奖结果时间
    	
    	activ3_gold = 12000000, 		--参加活动3需要筹码
    	activ4_gold = 36000000,		--参加活动4需要筹码
    	activ5_gold = 20000,		--参加活动5需要筹码
    }    
 end
 

--登陆后做的事
lottery_lib.on_after_user_login = function(e)
	--TraceError("登陆后做的事")
	
	local userinfo = e.data.userinfo
	if(userinfo == nil)then 
		--TraceError("登陆后做的事,if(userinfo == nil)then")
	 	return
	end
	
	--if(tex_gamepropslib ~= nil) then
    --    tex_gamepropslib.get_props_count_by_id(tex_gamepropslib.PROPS_ID.ShipTickets_ID, userinfo, function(ship_ticket_count) end)
   -- end
	
	local check_result = lottery_lib.check_datetime()	--检查活动时间
	if(check_result == 0)then
		--TraceError("登陆后做的事,if(check_result == 0)then")
		return
	end
	
	local lottery1_time = 0
	local lottery2_time = 0
	local lottery3_time = 0
	local lottery4_time = 0
	local lottery5_count = 0
	local recharge = 0
	
	--初始化
	if(userinfo.lottery1_time == nil)then
			userinfo.lottery1_time = 0
	end
	
	if(userinfo.lottery2_time == nil)then
			userinfo.lottery2_time = 0
	end
	
	if(userinfo.lottery3_time == nil)then
			userinfo.lottery3_time = 0
	end
	
	if(userinfo.lottery4_time == nil)then
			userinfo.lottery4_time = 0
	end
	
	if(userinfo.lottery5_count == nil)then
			userinfo.lottery5_count = 0
	end
	
	if(userinfo.recharge == nil)then
			userinfo.recharge = 0
	end
	
	--TraceError("登陆后做的事,查询数据库")
	--登陆查询数据库
	local sql="SELECT recharge,lottery1_time,lottery2_time,lottery3_time,lottery4_time,lottery5_count FROM user_huodong_cj_info where user_id=%d"
		sql=string.format(sql,userinfo.userId)
		dblib.execute(sql,function(dt)
			if(dt~=nil and #dt>0)then
			
				lottery1_time = timelib.db_to_lua_time(dt[1].lottery1_time) or 0
				lottery2_time = timelib.db_to_lua_time(dt[1].lottery2_time) or 0
				lottery3_time = timelib.db_to_lua_time(dt[1].lottery3_time) or 0
				lottery4_time = timelib.db_to_lua_time(dt[1].lottery4_time) or 0
				lottery5_count=dt[1].lottery5_count or 0
				recharge = dt[1].recharge or 0
				userinfo.recharge = recharge
				
				--TraceError("登陆查询数据库,lottery1_time->"..lottery1_time.."  lottery2_time->"..lottery2_time.."  lottery3_time"..lottery3_time.."  lottery4_time"..lottery4_time)
				--TraceError("登陆查询数据库,ueserid-> "..userinfo.userId.."   recharge-> "..recharge)
				
				--判断是否有领奖时间
				local endtime = timelib.db_to_lua_time(lottery_lib.endtime);
				local lottery_time = timelib.db_to_lua_time(lottery_lib.lottery_time);
				--TraceError("登陆后做的事,判断是否有领奖时间")
				
				--第1个
				--判断时间
 
					if(lottery1_time > endtime and lottery1_time <= lottery_time) then
			        	userinfo.lottery1_time = 1
					end
 
				--第2个
				--判断时间
					if(lottery2_time > endtime and lottery2_time <= lottery_time) then
			        	userinfo.lottery2_time = 1
					end
 
				--第3个
				--判断时间
					if(lottery3_time > endtime and lottery3_time <= lottery_time) then
			        	userinfo.lottery3_time = 1
					end
	 
				--第4个
				--判断时间
					if(lottery4_time > endtime and lottery4_time <= lottery_time) then
			        	userinfo.lottery4_time = 1
					end
 
				--第5个
				userinfo.lottery5_count = lottery5_count
				--TraceError("登陆后做的事,userinfo.lottery5_count->"..userinfo.lottery5_count.."  lottery4_time->"..userinfo.lottery4_time.."  lottery3_time->"..userinfo.lottery3_time.."  lottery2_time->"..userinfo.lottery2_time.."  lottery1_time->"..userinfo.lottery1_time)
				--TraceError("登陆后做的事,ueserid-> "..userinfo.userId.."   recharge-> "..recharge)
			end
		end)
	
	
end


--检查有效时间，限时问题
function lottery_lib.check_datetime()
	local statime = timelib.db_to_lua_time(lottery_lib.statime);
	local endtime = timelib.db_to_lua_time(lottery_lib.endtime);
	local lottery_time = timelib.db_to_lua_time(lottery_lib.lottery_time);
	local sys_time = os.time();
	
	--活动时间
	if(sys_time > statime and sys_time <= endtime) then
        return 1;
	end
	
	--领奖时间
	if(sys_time > endtime and sys_time <= lottery_time) then
        return 2;
	end
 
	--活动时间过去了
	return 0;
end


--接收点取领取兑换
lottery_lib.on_recv_click_award = function(buf)
 	--TraceError("接收点取领取兑换")
 	
	local type = buf:readByte()   --活动1,活动2,活动3,活动4,活动5
		
	--判断用户	
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
 
	local gold = get_canuse_gold(user_info)--获得用户筹码
	local check_result = lottery_lib.check_datetime()	--检查活动时间
	
	if(type == 1)then	--活动1
		--TraceError("接收点取领取兑换--活动1")
		--1、活动期间内，点击【点此领取】【点此兑换】，
			--系统提示 “请在活动结束（1月10日中午12:00）后三天内领取充值奖励！”
		if(check_result == 0)then
			--TraceError("接收点取领取兑换--活动1--活动已过期")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-2)		    --活动已过期
	        end,user_info.ip,user_info.port) 
	        
			return
		elseif(check_result == 1)then
			--TraceError("接收点取领取兑换--活动1--请在活动结束（1月10日中午12:00）后三天内领取充值奖励")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-3)		    --请在活动结束（1月10日中午12:00）后三天内领取充值奖励
	        end,user_info.ip,user_info.port) 
	        
			return
		
		end
			
		--4、点击领取时，对应充值总额不足，提示：”领取失败，您在活动期间内的充值总额不满足领取条件！“
		 if(user_info.recharge < 1)then
		 	--TraceError("接收点取领取兑换--活动1--充值总额不足")
		 	netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(0)		    --充值总额不足
	        end,user_info.ip,user_info.port) 
	        
			return
		 end
 
		--1、点击领取、兑换或抽奖，满足对应条件，系统提示“恭喜您获得 "喇叭*1，T人卡*1 ！“，提示中显示对应奖品
		--发奖
		if(user_info.lottery1_time == 0)then
			--TraceError("接收点取领取兑换--活动1--发奖")
			--加小喇叭*1
		    tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, user_info)
			--加T人卡*1
		    tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 1, user_info) 
		    
		    user_info.lottery1_time = 1   --表示领过奖
		    
		    --写日志
			local sql="insert into user_huodong_cj_info(user_id,lottery1_time) value(%d,now()) ON DUPLICATE KEY UPDATE lottery1_time=NOW()";
			sql=string.format(sql,user_info.userId);
			dblib.execute(sql)
			
			netlib.send(function(buf)
			    buf:writeString("HDDHCJING")
			    buf:writeInt(1)		    --成功，返回对就套餐：1、2、3、4或奖品ID
		        end,user_info.ip,user_info.port)
		     
		     --检查按钮状态   
		     lottery_lib.check_bottom_stat(user_info)
		end
		
	elseif(type == 2)then		--活动2
		--TraceError("接收点取领取兑换--活动2")
		--1、活动期间内，点击【点此领取】【点此兑换】，
			--系统提示 “请在活动结束（1月10日中午12:00）后三天内领取充值奖励！”
		if(check_result == 0)then
			--TraceError("接收点取领取兑换--活动2--活动已过期")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-2)		    --活动已过期
	        end,user_info.ip,user_info.port) 
	        
			return
		elseif(check_result == 1)then
			--TraceError("接收点取领取兑换--活动2--请在活动结束（1月10日中午12:00）后三天内领取充值奖励")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-3)		    --请在活动结束（1月10日中午12:00）后三天内领取充值奖励
	        end,user_info.ip,user_info.port) 
	        
			return
		
		end	
		
		--4、点击领取时，对应充值总额不足，提示：”领取失败，您在活动期间内的充值总额不满足领取条件！“
		 if(user_info.recharge < 99)then
		 	--TraceError("接收点取领取兑换--活动2--充值总额不足")
		 	netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(0)		    --充值总额不足
	        end,user_info.ip,user_info.port) 
	        
			return
		 end
			
		--1、点击领取、兑换或抽奖，满足对应条件，系统提示“恭喜您获得 "T人卡*1，喇叭*1，蓝宝石*1 ！“，提示中显示对应奖品
		--发奖
		if(user_info.lottery2_time == 0)then
			--TraceError("接收点取领取兑换--活动2--发奖")
			--加小喇叭*1
		    tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, user_info)
			--加T人卡*1
		    tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 1, user_info) 
			--加蓝宝石*1
			gift_addgiftitem(user_info,5001,user_info.userId,user_info.nick, false)
			
			user_info.lottery2_time = 1   --表示领过奖
			
			--写日志
			local sql="insert into user_huodong_cj_info(user_id,lottery2_time) value(%d,now()) ON DUPLICATE KEY UPDATE lottery2_time=NOW()";
			sql=string.format(sql,user_info.userId);
			dblib.execute(sql)
		
	        netlib.send(function(buf)
			    buf:writeString("HDDHCJING")
			    buf:writeInt(2)		    --成功，返回对就套餐：1、2、3、4或奖品ID
		        end,user_info.ip,user_info.port)
		        
		     --检查按钮状态   
		     lottery_lib.check_bottom_stat(user_info)
		end
		        
	elseif(type == 3)then		--活动3
		--TraceError("接收点取领取兑换--活动3")
		--1、活动期间内，点击【点此领取】【点此兑换】，
			--系统提示 “请在活动结束（1月10日中午12:00）后三天内领取充值奖励！”
		if(check_result == 0)then
			--TraceError("接收点取领取兑换--活动3--活动已过期")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-2)		    --活动已过期
	        end,user_info.ip,user_info.port) 
	        
			return
		elseif(check_result == 1)then
			--TraceError("接收点取领取兑换--活动3--请在活动结束（1月10日中午12:00）后三天内领取充值奖励")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-3)		    --请在活动结束（1月10日中午12:00）后三天内领取充值奖励
	        end,user_info.ip,user_info.port) 
	        
			return
		
		end
		
		--4、点击领取时，对应充值总额不足，提示：”领取失败，您在活动期间内的充值总额不满足领取条件！“
		 if(user_info.recharge < 999)then
		 	--TraceError("接收点取领取兑换--活动3--充值总额不足")
		 	netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(0)		    --充值总额不足
	        end,user_info.ip,user_info.port) 
	        
			return
		 end
		
		--判断筹码
		if(gold < lottery_lib.activ3_gold)then
			--TraceError("接收点取领取兑换--活动3--筹码余额不足")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-1)		    --筹码余额不足
	        end,user_info.ip,user_info.port)
			
			return
		end
		
		
		 
		--1、点击领取、兑换或抽奖，满足对应条件，系统提示“恭喜您获得 "游艇，T人卡*3，喇叭*3，绿宝石*1 ！“，提示中显示对应奖品
		--发奖
		if(user_info.lottery3_time == 0)then
			--TraceError("接收点取领取兑换--活动3--发奖")
			--减筹码
	      	usermgr.addgold(user_info.userId, -lottery_lib.activ3_gold, 0, g_GoldType.baoxiang, -1);
	      	
			--加小喇叭*3
		    tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 3, user_info)
			--加T人卡*3
		    tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 3, user_info)
			--加游艇
			gift_addgiftitem(user_info,5023,user_info.userId,user_info.nick, false)
			  
			--加绿宝石*1
			gift_addgiftitem(user_info,5002,user_info.userId,user_info.nick, false)
			
			user_info.lottery3_time = 1   --表示领过奖
			
			--写日志
			local sql="insert into user_huodong_cj_info(user_id,lottery3_time) value(%d,now()) ON DUPLICATE KEY UPDATE lottery3_time=NOW()";
			sql=string.format(sql,user_info.userId);
			dblib.execute(sql)
		
	        netlib.send(function(buf)
			    buf:writeString("HDDHCJING")
			    buf:writeInt(3)		    --成功，返回对就套餐：1、2、3、4或奖品ID
		        end,user_info.ip,user_info.port)
		    
		    --检查按钮状态   
		    lottery_lib.check_bottom_stat(user_info)
	    end
	        
	elseif(type == 4)then		--活动4
		--TraceError("接收点取领取兑换--活动4")
		--1、活动期间内，点击【点此领取】【点此兑换】，
			--系统提示 “请在活动结束（1月10日中午12:00）后三天内领取充值奖励！”
		if(check_result == 0)then
			--TraceError("接收点取领取兑换--活动4--活动已过期")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-2)		    --活动已过期
	        end,user_info.ip,user_info.port) 
	        
			return
		elseif(check_result == 1)then
			--TraceError("接收点取领取兑换--活动4--请在活动结束（1月10日中午12:00）后三天内领取充值奖励")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-3)		    --请在活动结束（1月10日中午12:00）后三天内领取充值奖励
	        end,user_info.ip,user_info.port) 
	        
			return
		
		end

		--4、点击领取时，对应充值总额不足，提示：”领取失败，您在活动期间内的充值总额不满足领取条件！“
	 	if(user_info.recharge < 4999)then
		 	 --TraceError("接收点取领取兑换--活动4--充值总额不足")
		 	netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(0)		    --充值总额不足
	        end,user_info.ip,user_info.port) 
	        
			return
		 end
		 
		 --判断筹码
		if(gold < lottery_lib.activ4_gold)then
			 --TraceError("接收点取领取兑换--活动4--筹码余额不足")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-1)		    --筹码余额不足
	        end,user_info.ip,user_info.port)
			 
			return
		end
			
		--1、点击领取、兑换或抽奖，满足对应条件，系统提示“恭喜您获得 "法拉利，T人卡*5，喇叭*10，红宝石*1  ！“，提示中显示对应奖品
		--发奖
		if(user_info.lottery4_time == 0)then
			 --TraceError("接收点取领取兑换--活动4--发奖")
			--减筹码
	      	usermgr.addgold(user_info.userId, -lottery_lib.activ4_gold, 0, g_GoldType.baoxiang, -1);
		
			--加小喇叭10
		    tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 10, user_info)
			--加T人卡5
		    tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 5, user_info)
			--加法拉利
			gift_addgiftitem(user_info,5024,user_info.userId,user_info.nick, false)
			
			--加红宝石*1  
			gift_addgiftitem(user_info,5004,user_info.userId,user_info.nick, false)
		
			user_info.lottery4_time = 1   --表示领过奖
			
			--写日志
			local sql="insert into user_huodong_cj_info(user_id,lottery4_time) value(%d,now()) ON DUPLICATE KEY UPDATE lottery4_time=NOW()";
			sql=string.format(sql,user_info.userId);
			dblib.execute(sql)
			
	        netlib.send(function(buf)
			    buf:writeString("HDDHCJING")
			    buf:writeInt(4)		    --成功，返回对就套餐：1、2、3、4或奖品ID
		        end,user_info.ip,user_info.port)
		        
		    --检查按钮状态   
		    lottery_lib.check_bottom_stat(user_info)
		    
	    end
	        		
	elseif(type == 5)then		--活动5
		--TraceError("接收点取领取兑换--活动5")
		--判断活动时间  4、活动结束1.10 12:00后，点击【点此抽奖】，系统提示“抽奖活动已过期！”
		if(check_result ~= 1)then
			--TraceError("接收点取领取兑换--活动5--活动已过期")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-2)		    --活动已过期
	        end,user_info.ip,user_info.port)
	         
			return
		end
		
		--判断资格证 3、抽奖时，资格证书不足提示“资格证书不足！"
		--查询资格证数量
		local shiptickets_count = user_info.propslist[3]
		if(shiptickets_count == nil)then
			--TraceError("接收点取领取兑换--活动5--资格证书为空")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-4)		    --资格证书不足
	        end,user_info.ip,user_info.port)
		
			return
		elseif(shiptickets_count < 1)then
			--TraceError("接收点取领取兑换--活动5--资格证书不足")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-4)		    --资格证书不足
	        end,user_info.ip,user_info.port)
		
			return
		end
		
		--5、点击兑换和抽奖时，牌桌外筹码不足，提示 ：”筹码余额不足，请充值！ 【点击充值】按钮” 
		--点击充值链接到对应合作平台充值页面
		--判断筹码
		if(gold < lottery_lib.activ5_gold)then
			--TraceError("接收点取领取兑换--活动5--筹码余额不足")
			netlib.send(function(buf)
		    buf:writeString("HDDHCJING")
		    buf:writeInt(-1)		    --筹码余额不足
	        end,user_info.ip,user_info.port)
			 
			return
		end
		--TraceError("接收点取领取兑换--活动5--发奖")
		--1、点击领取、兑换或抽奖，满足对应条件，系统提示“恭喜您获得 
			--"蓝宝石*1 或 绿宝石*1  或 黄宝石*1 或 红宝石*1 或 黑宝石*1 ！“，提示中显示对应奖品
		--发奖
		  --随机生成奖品ID
        local sql = format("call sp_huodong_cj_get_random_gift(%d)", user_info.userId)
 
 		local prizeid = 0
 		
        dblib.execute(sql, function(dt)
            if(dt and #dt > 0)then
            	prizeid = dt[1]["gift_id"]
            	
            	if(prizeid == 1)then
	            	--加蓝宝石*1  
					gift_addgiftitem(user_info,5001,user_info.userId,user_info.nick, false)
					prizeid = 5001
				elseif(prizeid == 2)then
	            	--加绿宝石*1  
					gift_addgiftitem(user_info,5002,user_info.userId,user_info.nick, false)
					prizeid = 5002
				elseif(prizeid == 3)then
	            	--加黄宝石*1  
					gift_addgiftitem(user_info,5003,user_info.userId,user_info.nick, false)
					prizeid = 5003
				elseif(prizeid == 4)then
	            	--加红宝石*1  
					gift_addgiftitem(user_info,5004,user_info.userId,user_info.nick, false)
					prizeid = 5004
				elseif(prizeid == 5)then
	            	--加黑宝石*1  
					gift_addgiftitem(user_info,5005,user_info.userId,user_info.nick, false)
					prizeid = 5005
				end
            	
            	user_info.propslist[3] = user_info.propslist[3] - 1
				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.ShipTickets_ID, -1, user_info)
				--TraceError("--抽奖扣除资格证1张，资格证剩余："..user_info.propslist[3].."奖品ID"..prizeid)
				
	            netlib.send(function(buf)
				    buf:writeString("HDDHCJING")
				    buf:writeInt(prizeid)		    --成功，返回对就套餐：1、2、3、4或奖品ID
		        end,user_info.ip,user_info.port)
		        
			end
        end)
        
        --写日志
		local sql="insert into user_huodong_cj_info(user_id,lottery5_count) value(%d,1) ON DUPLICATE KEY UPDATE lottery5_count = lottery5_count+1";
		sql=string.format(sql,user_info.userId);
		dblib.execute(sql)

		--减筹码
	    usermgr.addgold(user_info.userId, -lottery_lib.activ5_gold, 0, g_GoldType.baoxiang, -1);

	else
		TraceError("接收点取领取兑换,错误")
		return
	end

end
 
--请求活动时间状态
lottery_lib.on_recv_activ_stat = function(buf)
	--TraceError("请求活动时间状态")
	--判断用户	
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	
	local check_result = lottery_lib.check_datetime()	--检查活动时间
	if(check_result == 0)then
		--TraceError("请求活动时间状态--活动已过期")
--		netlib.send(function(buf)
--	    buf:writeString("HDDHCJDATE")
--	    buf:writeByte(0)		    --活动已过期
--	  	buf:writeInt(0)		    --按键显示状态，显示已兑换或正常显示；把 已兑换活动的ID 进行或运算发过来
--        end,user_info.ip,user_info.port) 
        
		return
	elseif(check_result == 1)then
		--TraceError("请求活动时间状态--正常活动期间（可抽奖时间）；")
		netlib.send(function(buf)
	    buf:writeString("HDDHCJDATE")
	    buf:writeByte(1)		    --正常活动期间（可抽奖时间）；
	    buf:writeInt(0)		    --按键显示状态，显示已兑换或正常显示；把 已兑换活动的ID 进行或运算发过来
        end,user_info.ip,user_info.port) 
        
		return
		
	elseif(check_result == 2)then
		
		local result = 0
		if(user_info.lottery1_time == 1)then
			--result = 2
			result = bit_mgr:_or(result, 2)
		end
		
		if(user_info.lottery2_time == 1)then
			--result = 4
			result = bit_mgr:_or(result, 4)
		end
		
		if(user_info.lottery3_time == 1)then
			--result = 8
			result = bit_mgr:_or(result, 8)
		end
		
		if(user_info.lottery4_time == 1)then
			--result = 16
			result = bit_mgr:_or(result, 16)
		end
		
		--TraceError("请求活动时间状态--活动结束（领奖、兑换时间）result:"..result)
		
		netlib.send(function(buf)
		    buf:writeString("HDDHCJDATE")
		    buf:writeByte(2)		    --活动结束（领奖、兑换时间）
		    buf:writeInt(result)		    --按键显示状态，显示已兑换或正常显示；把 已兑换活动的ID 进行或运算发过来
	        end,user_info.ip,user_info.port) 
        
		return
	
	end
	
end

--再次判断活动按钮状态
function lottery_lib.check_bottom_stat(user_info)

	local result = 0
		if(user_info.lottery1_time == 1)then
			--result = 2
			result = bit_mgr:_or(result, 2)
		end
		
		if(user_info.lottery2_time == 1)then
			--result = 4
			result = bit_mgr:_or(result, 4)
		end
		
		if(user_info.lottery3_time == 1)then
			--result = 8
			result = bit_mgr:_or(result, 8)
		end
		
		if(user_info.lottery4_time == 1)then
			--result = 16
			result = bit_mgr:_or(result, 16)
		end
		
		--TraceError("再次判断活动按钮状态 result:"..result)
		
		netlib.send(function(buf)
		    buf:writeString("HDDHCJDATE")
		    buf:writeByte(2)		    --活动结束（领奖、兑换时间）
		    buf:writeInt(result)		    --按键显示状态，显示已兑换或正常显示；把 已兑换活动的ID 进行或运算发过来
	        end,user_info.ip,user_info.port)
        
end



--协议命令
cmd_tex_match_handler = 
{
    ["HDDHCJING"] = lottery_lib.on_recv_click_award, --接收点取领取兑换
    ["HDDHCJDATE"] = lottery_lib.on_recv_activ_stat, --请求活动时间状态

}

--加载插件的回调
for k, v in pairs(cmd_tex_match_handler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("h2_on_user_login", lottery_lib.on_after_user_login);