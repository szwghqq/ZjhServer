TraceError("init act_macth_lib...初始化竞技场信息")
if act_macth_lib and act_macth_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", act_macth_lib.on_after_user_login);
end

if act_macth_lib and act_macth_lib.ontimecheck then
	eventmgr:removeEventListener("timer_minute", act_macth_lib.ontimecheck);
end

if act_macth_lib and act_macth_lib.ongameover then 
	eventmgr:removeEventListener("game_event", act_macth_lib.ongameover);
end
 
--德州专用
if act_macth_lib and act_macth_lib.ongamebegin then  
	eventmgr:removeEventListener("game_begin_event", act_macth_lib.ongamebegin);
end

if not act_macth_lib then
	act_macth_lib = _S
	{ 
		on_after_user_login = NULL_FUNC,	--用户登陆后初始化数据
		check_datetime = NULL_FUNC,		--检查有效时间，限时问题 
		can_join_invite_match = NULL_FUNC,		--判断是不是有效的比赛
		ongameover = NULL_FUNC,		--游戏结束采集盘数
		ontimecheck = NULL_FUNC,		--定时刷新事件
	 	update_invite_db = NULL_FUNC,	--更新比赛信息
	 	update_play_count = NULL_FUNC, 	--更新玩的盘数
		init_invite_ph = NULL_FUNC,		--初始化排行榜
	 	on_recv_invite_ph_list = NULL_FUNC,		--请求竞技场的排行榜
	 	--on_recv_invite_dj = NULL_FUNC,		--填写邀请赛的领奖结果，新版本中不再使用了，先保留，防止以后还要发实物奖
	 	--init_invate_match = NULL_FUNC,		--生成比赛ID，并记录这次比赛的人数，每个桌子在同一时刻，只会有一场比赛，所以直接用桌子号+时间就是唯一的
	 	--get_invate_match_id = NULL_FUNC,		--得到邀请赛的ID
	 	get_invate_match_count = NULL_FUNC,		--获得桌子数据
	 	on_recv_refresh_timeinfo = NULL_FUNC,	--离比赛开局和结束还差多少秒
	 	on_recv_already_know_reward = NULL_FUNC,		--客户端通知已经点过领奖按钮了(本方法暂时不使用，防止逻辑出现混乱）
	 	invite_update_user_play_count = NULL_FUNC,		--用户登录后初始化数据
	 	consider_screen = NULL_FUNC,	--计算第几场
	 	invite_match_fajiang = NULL_FUNC,		--给玩家发奖    产生结果后，再打一盘就发奖，或重登陆时才发奖
	 	on_recv_activity_stat = NULL_FUNC,	--请求活动时间状态
	 	on_recv_sign = NULL_FUNC,		--请求报名比赛
	 	sign_succes = NULL_FUNC,	--报名成功
	 	inster_invite_db = NULL_FUNC,	--报名写数据库
	 	on_recv_buy_ticket = NULL_FUNC,		--请求购买比赛券
	 	send_buy_ticket_result = NULL_FUNC,	--发送购买比赛券结果 
		chaxun_add_items = NULL_FUNC,		--棋牌  查询  和加   道具公用方法 
		send_pm_list = NULL_FUNC,		--发送排行榜 
		init_invate_match = NULL_FUNC,			--初始化竞技场需要的数据
	 	ongamebegin = NULL_FUNC, 		--德州（桌号 专用）
		ontimer_broad = NULL_FUNC,		-- 全服发广播(棋牌专用)
		send_fajiang_msg = NULL_FUNC,		--发送发奖消息 
	 	
	 	start_baoming_date = "2012-06-28",	--活动报名开始时间
		statime = "2012-06-28 09:00:00",  --活动开始时间
	    endtime = "2012-07-05 23:00:00",  --活动结束时间 
	    rank_endtime = "2012-07-07 00:00:00",	--排行榜结束时间
	      
	    start_day = 20120628,	--用于计算第几天 开始时间
	 --   exttime = "2011-11-14 00:00:00",  --只能领奖时间
	  
	    cfg_qp_game_name = {      --棋牌游戏配置  
        	["zysz"] = "zysz",
        	["mj"] = "mj", 
    					},
    				
    	cfg_tex_game_name = {      --德州游戏配置   
        	["tex"] = "tex",
    					},
    	
    	room_smallbet1 = -50,
	    room_smallbet2 = 500,
	    room_smallbet3 = 20000,
	    room_smallbet4 = 200,
	    room_smallbet5 = 10000,
	    refresh_invate_time = -1,  --上一次刷新排行榜的时间
		last_msg_time = -1, --上一次发消息的时间
		
		zysz_gs_id = 62022,                      --  智勇三张顶级场id
		
		mj_yk_id = 3350,				--	麻将游客场id
		mj_xunlian_id = 3001,			--  麻将练习场id
		mj_xs_id = 3002,				--  麻将新手场id
		mj_gs_id = 3003,				--  麻将高手场id
		mj_8f_id = 3091,				--  麻将8番起胡场id
		mj_super_id = 3005,				--  麻将超级高手场id
		
		qp_mp_id  = 8003,                         -- 门票
		  
	    invite_ph_list_zj = {}, --专家场排名
	    invite_ph_list_zy = {}, --职业场排名
	    invite_ph_list_yy = {}, --业余场排名
	    
	    invite_qp_mj_ph_list = {}; --麻将排名
		invite_qp_zysz_ph_list = {};	--智勇三张排名
		
		OP_MENPIAO_PRIZE={			--门票的价格
    		["qp"]=20000,
    		["tex"]=5000,
    		},
	}
end

--德州专用(传递  桌号)
function act_macth_lib.ongamebegin(e)
	local deskno=e.data.deskno
	if(deskno==nil)then return end
	act_macth_lib.init_invate_match(deskno)
	
end
 
--检查有效时间
--3 可以报名,2可以比赛和报名,3可以领奖, 0过期
function act_macth_lib.check_datetime()
	local statime = timelib.db_to_lua_time(act_macth_lib.statime);
	local endtime = timelib.db_to_lua_time(act_macth_lib.endtime);
	local lj_time = timelib.db_to_lua_time(act_macth_lib.rank_endtime); 
	local sys_time = os.time();
	--可以领奖和增加游戏时间
	if(sys_time >= statime and sys_time <= endtime) then
		    local tdate = os.date("*t", sys_time);		    
	        if (tdate.hour >= 20 and tdate.hour < 23)  then
	            return 2;
			else
				return 3
	        end	        
	end	
	
	--只能领奖
	if(sys_time > endtime and sys_time <= lj_time) then
        return 1;
	end	
	 
	--活动时间过去了
	return 0;
end

--判断是不是有效的比赛
function act_macth_lib.can_join_invite_match(user_info,deskinfo,match_num)
	--TraceError("--判断是不是有效的比赛, userId:"..user_info.userId.." match_num:"..match_num)
	
	--1.时间判断 
	if(act_macth_lib.check_datetime()~= 2)then
	   
    	--TraceError("--判断是不是有效的比赛->>>>时间判断    失败")
		return false
	end

	--德州
	if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		--判断时间的合法性,0不合法，1只能填领奖信息，2能填领奖信息和比赛
		if(deskinfo ~= nil and deskinfo.smallbet ~= act_macth_lib.room_smallbet1 and deskinfo.smallbet ~= act_macth_lib.room_smallbet2 and deskinfo.smallbet ~= act_macth_lib.room_smallbet3 and deskinfo.smallbet ~= act_macth_lib.room_smallbet4 and deskinfo.smallbet ~= act_macth_lib.room_smallbet5)then
			--TraceError("--判断是不是有效的比赛->>>deskinfo,room_smallbet1,room_smallbet2")
			return false
		end
		
		--判断4人以上才算有效比赛，记录局数
	    if(match_num < 4)then
	   		--TraceError("--判断不是有效的比赛-->>>德州      人数："..match_num)
	    	return false
	    end
	end
     
    --棋牌
    if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    	--TraceError("--判断不是有效的比赛-->>>棋牌    ")

    	--麻将  不判断  4人都加
    	
    	
    	--智勇三张  高手场4人及以上判断
    	--获取人数 
	--	local desk_nu = user_info.desk
	--	local deskinfo = desklist[desk_nu] 
	--	local playercount = deskinfo.playercount 
    	if(gamepkg.name == "zysz" and tonumber(groupinfo.groupid) ~= act_macth_lib.zysz_gs_id)then
    		--TraceError("--判断不是有效的比赛-->>>棋牌     智勇三张  不是高手场 返回")
	    	return false  
    	end
    	
    	--判断4人以上才算有效比赛，记录局数
	    if(match_num < 4)then
	   		--TraceError("--判断不是有效的比赛-->>> 棋牌  返回  人数："..match_num)
	    	return false
	    end
    end
     
    return true
end

--游戏结束采集盘数
function act_macth_lib.ongameover(gameeventdata)
	
	--活动时间有效性
	local check_time = act_macth_lib.check_datetime()
    if(check_time == 0 or check_time == 1) then
    	--TraceError(" 游戏结束事件处理->时间有效性,失效->if(check_time == 0 and check_time == 5)-- userid:"..user_info.userId)
        return;
    end
    
	if gameeventdata == nil then return end
	
	--游戏事件验证
	if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name or act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
		--TraceError("游戏结束采集盘数    gamepkg.name： "..gamepkg.name)
	else
		--TraceError("游戏结束采集盘数->游戏事件验证->不在活动内 ， 返回      gamepkg.name： "..gamepkg.name)
		return
	end

    local userid = 0
    local match_gold = 0
    --遍历所有用户
    for k,v in pairs(gameeventdata.data) do
      
    	userid = v.userid
    	match_gold = v.wingold
    	
    	--TraceError("游戏结束采集盘数      用户id: "..userid.."   输赢金币: "..match_gold.." gamepkg.name = "..gamepkg.name)
     
	    --获取userinfo
		local user_info = usermgr.GetUserById(userid or 0); 
		if (user_info == nil) then return end
	    
		local deskno = user_info.desk
		local deskinfo = desklist[deskno]
		local match_num = act_macth_lib.get_invate_match_count(deskno)		--获得桌子数据
		local match_type = 1
 
		--TraceError("游戏结束采集盘数,match_num:"..match_num.." 用户id："..userid.." 游戏名："..gamepkg.name)
		--判断是否满足采集条件  (德州 职业场 专家场   人手 >= 4) (麻将  不判断  4人都加) (智勇三张  高手场4人及以上)
		if(act_macth_lib.can_join_invite_match(user_info,deskinfo,match_num))then
		
			--德州
			if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
				 
				if(deskinfo.smallbet == act_macth_lib.room_smallbet1)then		--业余场
					match_type = 1;
				elseif(deskinfo.smallbet == act_macth_lib.room_smallbet2 or deskinfo.smallbet == act_macth_lib.room_smallbet4)then		--职业场
					match_type = 2;
					
					--判断用户在职业场还是专家场打牌
					if(user_info.sign_ruslt == "1" or user_info.sign_ruslt == "3")then
						--TraceError("游戏结束采集盘数  德州  符合职业场采集局数条件      match_type "..match_type.." match_gold "..match_gold.."  用户id: "..user_info.userId.."   sign: "..user_info.sign_ruslt)
						act_macth_lib.update_invite_db(user_info,match_gold,match_type, 0)
					end
					 
				elseif(deskinfo.smallbet == act_macth_lib.room_smallbet3 or deskinfo.smallbet == act_macth_lib.room_smallbet5)then		--专家场
					match_type = 3;
					
					--判断用户在职业场还是专家场打牌
					if(user_info.sign_ruslt == "2" or user_info.sign_ruslt == "3")then
						--TraceError("游戏结束采集盘数  德州  符合专家场采集局数条件      match_type "..match_type.." match_gold "..match_gold.."  用户id: "..user_info.userId.."   sign: "..user_info.sign_ruslt)
						act_macth_lib.update_invite_db(user_info,match_gold,match_type, 0)
					end 
				end 
			end
			
			 --棋牌
    		if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    		 
    			--智勇三张 净赢金币数。
    			if(gamepkg.name == "zysz")then
    				
    				--判断用户 报名 
    				if(user_info.qp_sign_ruslt == "2" or user_info.qp_sign_ruslt == "3")then
    					 
						match_type = 3;		--智勇三张 
	    				--TraceError("游戏结束采集盘数  棋牌 智勇三张  符合专家场采集局数条件      match_type "..match_type.." match_gold "..match_gold.."  用户id: "..user_info.userId.."   sign: "..user_info.sign_ruslt)
						act_macth_lib.update_invite_db(user_info,match_gold,match_type, 0)
					end
					
    				
				else--麻将练习场和新手区 每胜1局加1分，高手入门每胜1局加2分，8番起胡和超级高手每胜1局加3分，所有房间加分之和为个人比赛总分。
					
					if(match_gold > 0)then		--麻将只记录赢家
						--判断用户 报名 
						if(user_info.qp_sign_ruslt == "1" or user_info.qp_sign_ruslt == "3")then
							match_type = 2;		--麻将 
							--TraceError("游戏结束采集盘数  棋牌 麻将  match_type "..match_type.." 转换前match_gold:"..match_gold.." 什么场："..tonumber(groupinfo.groupid))
							
							if(tonumber(groupinfo.groupid) ~= act_macth_lib.mj_yk_id)then	--游客区不进入加分
								if(tonumber(groupinfo.groupid) == act_macth_lib.mj_xunlian_id or tonumber(groupinfo.groupid) == act_macth_lib.mj_xs_id)then	--练习场和新手区 每胜1局加1分
									match_gold = 1
								elseif(tonumber(groupinfo.groupid) == act_macth_lib.mj_gs_id)then		--高手入门每胜1局加2分
									match_gold = 2
								elseif(tonumber(groupinfo.groupid) == act_macth_lib.mj_8f_id or tonumber(groupinfo.groupid) == act_macth_lib.mj_super_id)then		--8番起胡和超级高手每胜1局加3分
									match_gold = 3
								end
						 		
								--TraceError("游戏结束采集盘数  棋牌 麻将  match_type "..match_type.." 转换后match_gold:"..match_gold)
								--TraceError("游戏结束采集盘数  棋牌 智勇三张  符合专家场采集局数条件      match_type "..match_type.." match_gold "..match_gold.."  用户id: "..user_info.userId.."   sign: "..user_info.sign_ruslt)
								act_macth_lib.update_invite_db(user_info,match_gold,match_type, 0)
							end 
						end
					end 
				end
    		end
		end	 
	end
end

--游戏结束采集盘数 写成绩到数据库和 更新玩的盘数
function act_macth_lib.update_invite_db(user_info,match_gold,match_type, sign)
	--TraceError("游戏结束采集盘数 写数据库和 更新玩的盘数  sign->"..sign.." match_gold:"..match_gold.."  match_type:"..match_type)
	local nick = string.trans_str(user_info.nick)
	if(sign == 0)then
		local sql = "insert into t_invite_pm(user_id,nick_name,win_gold,play_count,match_type,sys_time) value(%d,'%s',%d,1,%d,now()) on duplicate key update win_gold=win_gold+%d,play_count=play_count+1,sys_time=now();commit;";
		sql = string.format(sql,user_info.userId,nick,match_gold,match_type,match_gold);
		dblib.execute(sql)
		act_macth_lib.update_play_count(user_info,match_type)
	else
		local sql = "insert into t_invite_pm(user_id,nick_name,win_gold,match_type,sys_time,sign) value(%d,'%s',%d,%d,now(),%d) ON DUPLICATE KEY UPDATE sys_time=NOW()";
		sql = string.format(sql,user_info.userId,nick,match_gold,match_type,sign);
		dblib.execute(sql)
		act_macth_lib.update_play_count(user_info,match_type)
	end
	
	if(match_type == 2)then
		user_info.score_2 = user_info.score_2 + match_gold
	end
	
	if(match_type == 3)then
		user_info.score_3 = user_info.score_3 + match_gold
	end
end	


--游戏结束采集盘数  更新玩的盘数
act_macth_lib.update_play_count=function(user_info,match_type)
 
	--TraceError("游戏结束采集盘数 更新玩的盘数 userID->"..user_info.userId.."match_type->"..match_type.." 游戏名："..gamepkg.name)
 
 	--德州
	if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		if(match_type == 1)then
		
			if(user_info.yy_play_count == nil)then
				user_info.yy_play_count = 1
				return
			end
			
			user_info.yy_play_count = user_info.yy_play_count + 1 or 1
			
		elseif(match_type == 2)then
		
			if(user_info.zy_play_count == nil)then
				user_info.zy_play_count = 1
				--TraceError("游戏结束采集盘数 更新玩的盘数-> 德州 user_info.zy_play_count->"..user_info.zy_play_count.." 游戏名："..gamepkg.name)
				return
			end
			
			user_info.zy_play_count = user_info.zy_play_count + 1 or 1
			--TraceError("游戏结束采集盘数  更新玩的盘数-> 德州  user_info.zy_play_count->"..user_info.zy_play_count.." 游戏名："..gamepkg.name)
			
		elseif(match_type == 3)then
			if(user_info.zj_play_count == nil)then
				user_info.zj_play_count = 1
				--TraceError("游戏结束采集盘数  更新玩的盘数-> 德州 user_info.zj_play_count->"..user_info.zj_play_count.." 游戏名："..gamepkg.name)
				return
			end
			user_info.zj_play_count = user_info.zj_play_count+1 or 1
			--TraceError("游戏结束采集盘数 更新玩的盘数-> 德州 user_info.zj_play_count->"..user_info.zj_play_count.." 游戏名："..gamepkg.name)
		end
	end
	
	--棋牌
    if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    	
    	if(user_info.qp_play_count == nil)then
			user_info.qp_play_count = 1
			--TraceError("游戏结束采集盘数 更新玩的盘数-> 棋牌  user_info.qp_play_count->"..user_info.qp_play_count.." 游戏名："..gamepkg.name)
			return
		end
		
		user_info.qp_play_count = user_info.qp_play_count + 1 or 1
		--TraceError("游戏结束采集盘数 更新玩的盘数 -> 棋牌  user_info.qp_play_count->"..user_info.qp_play_count.." 游戏名："..gamepkg.name)
    end
end

 
--定时刷新事件
act_macth_lib.ontimecheck = function()
  	--10分钟要刷一次 
  	if(act_macth_lib.check_datetime() == 0)then	--判断活动时间过期
  		--TraceError("定时刷新事件   活动时间过期")
  		return
  	end
  	
	if(act_macth_lib.refresh_invate_time == -1 or os.time() > act_macth_lib.refresh_invate_time + 60 * 10)then
		--TraceError("定时刷新事件  10分钟要刷一次 ");
    	act_macth_lib.refresh_invate_time = os.time();
    	act_macth_lib.init_invite_ph();
    end
  
    --20:00,20:20,20:40,21:00,21:20,21:40,22:00 共发全服7次广播
    
    local tableTime = os.date("*t",os.time());
    local nowYear = tonumber(tableTime.year);
    local nowMonth = tonumber(tableTime.month);
    local nowDay = tonumber(tableTime.day);
    
    local nowHour = tonumber(tableTime.hour);
    local nowMin = tonumber(tableTime.min);
    local nowSec = tonumber(tableTime.sec);
    
    local tmp_time="'"..nowYear.."-"..nowMonth.."-"..nowDay.." "..nowHour..":"..nowMin..":00"
    if ((nowHour == 20 and nowMin == 0)
    	or (nowHour == 20 and nowMin == 20)
    	or (nowHour == 20 and nowMin == 40)
    	or (nowHour == 21 and nowMin == 0)
    	or (nowHour == 21 and nowMin == 20)
    	or (nowHour == 21 and nowMin == 40)
    	or (nowHour == 22 and nowMin == 0)) then
		 
		if(act_macth_lib.last_msg_time < timelib.db_to_lua_time(tmp_time))then
			--德州
			if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		    	broadcast_by_msgtype("match_msg_noti",0)
		    	act_macth_lib.last_msg_time = os.time();
		    end
		    
		    --棋牌
    		if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    			local msg = "竞技场已火热开启，赶快加入赢取藏宝图挖宝！" 
		    	BroadcastMsg(_U(msg),0)
		    	act_macth_lib.last_msg_time = os.time();
    		end
		end
	end 
	
	  --定时发送前3名发奖消息
	if ((nowHour == 23 and nowMin == 05)
		or (nowHour == 23 and nowMin == 10)
		or (nowHour == 23 and nowMin == 15)
		or (nowHour == 23 and nowMin == 20))then
		
		--发送发奖消息
		act_macth_lib.send_fajiang_msg()
	end
end

--初始化排行榜
function act_macth_lib.init_invite_ph()
	--TraceError("-->>>>初始化排行榜")
	
	--初始化排行
	local init_match_ph = function(ph_list,match_type)
		local sql = "select user_id,nick_name,win_gold,match_king_count,play_count,sign from t_invite_pm where match_type=%d and play_count>=1 order by win_gold desc LIMIT 20"
		sql = string.format(sql,match_type) 
		dblib.execute(sql,function(dt)	
				if(dt ~= nil and  #dt > 0)then
					for i = 1,#dt do
						local bufftable ={
						  	    mingci = i, 
			                    user_id = dt[i].user_id,
			                    nick_name = dt[i].nick_name,
			                    win_gold = dt[i].win_gold,
			                    match_king_count = dt[i].match_king_count,
			                    play_count = dt[i].play_count,
			                    sign = dt[i].sign,
		                }
		                
						table.insert(ph_list,bufftable)
					end
				end
	    end)
    end
    
    --德州
	if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
	    act_macth_lib.invite_ph_list_zj = {}; --专家场排名
		act_macth_lib.invite_ph_list_yy = {};	--业余场排名
		act_macth_lib.invite_ph_list_zy = {};	--职业场排名
		
		
	    --初始化业余场排行
	    init_match_ph(act_macth_lib.invite_ph_list_yy,1)
	    --初始化职业场排行
	    init_match_ph(act_macth_lib.invite_ph_list_zy,2)
	    --初始化专家场排行
	    init_match_ph(act_macth_lib.invite_ph_list_zj,3)
	end
	
	--棋牌
    if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    	act_macth_lib.invite_qp_mj_ph_list = {}; --麻将排名
		act_macth_lib.invite_qp_zysz_ph_list = {};	--智勇三张排名
 
		--初始化麻将排行
	    init_match_ph(act_macth_lib.invite_qp_mj_ph_list,2)
	    --初始化智勇三张排行
	    init_match_ph(act_macth_lib.invite_qp_zysz_ph_list,3)
    end
	
end

--请求竞技场的排行榜
function act_macth_lib.on_recv_invite_ph_list(buf)
	
	local user_info = userlist[getuserid(buf)]; 
	local mc = -1; --用于记下自己的名次
	local win_gold = 0; --用于记下自己的成绩
	local match_king_count = 0; --用于记下自己的王者次数
	local play_count = 0; --用于记下自己的玩的次数
	
	local invite_paimin_list = {};
	local send_len = 20;--默认发20条信息
	if(user_info == nil)then return end
	--TraceError("请求竞技场的排行榜  用户id："..user_info.userId.." 游戏名："..gamepkg.name)
	
	--查询自己的名次，如果没有名次就返回-1
	--返回名次，成绩，成为王者的次数，玩的次数
	local my_mc=-1;
	local my_win_gold=0;
	local my_king_count=0;
	local my_play_count=0;
	
	local get_my_pm = function(ph_list,user_info)
		local mc = -1
		if (ph_list == nil) then return -1,0,0,0 end
		
		for i = 1,#ph_list do
			if(ph_list[i].user_id == user_info.userId)then
				return i,ph_list[i].win_gold,ph_list[i].match_king_count,ph_list[i].play_count
			end
		end

		return -1,0,0,0;--没有找到对应玩家的记录，认为他没有成绩
	end
	
	--得到自己玩了多少盘
	local get_my_real_play_count=function(user_info,match_type)
		
		 --德州
		if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
			if(match_type==3)then
				return user_info.zj_play_count or 0
			end
			
			if(match_type==2)then
				return user_info.zy_play_count or 0
			end
	
			if(match_type==1)then
				return user_info.yy_play_count or 0						
			end
		end	
		
		--棋牌
    	if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    	 
    		return user_info.qp_play_count or 0		
    	end
    
	end
	
	--德州   1，业余场；2，职业场；3，专家场
	--棋牌  1，麻将 ；2，智勇三张
	local query_match_type = buf:readByte(); 
	--TraceError("请求竞技场的排行榜  用户id："..user_info.userId.." 游戏名："..gamepkg.name.." 请求类型："..query_match_type)
	
	local my_real_play_count = get_my_real_play_count(user_info,query_match_type) or 0
	 
	
	
	--德州
	if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		--德州和棋牌      判断报名    0：未报名    1：职业场      2：专家场       3：职业场和专家场
		local baoming_sign = user_info.sign_ruslt or "0"	--发送客户端，只有0，未报名；1，已报名
		--TraceError("baoming_sign : "..baoming_sign)
		--获取排行榜
		if(query_match_type == 1)then		--1，业余场
			invite_paimin_list = act_macth_lib.invite_ph_list_yy
		elseif(	query_match_type == 2) then		--2，职业场
			invite_paimin_list = act_macth_lib.invite_ph_list_zy
		elseif(	query_match_type == 3) then		--3，专家场
			invite_paimin_list = act_macth_lib.invite_ph_list_zj
		end
		
		--获得自己排名
		my_mc,my_win_gold,my_king_count,my_play_count = get_my_pm(invite_paimin_list,user_info)	
		if(query_match_type == 2)then
			my_win_gold = user_info.score_2
		elseif(query_match_type == 3)then
			my_win_gold = user_info.score_3
		end 
		
		--将baoming_sign转换  0，未报名；1，已报名
		if(query_match_type == 2)then		--职业场
			
			if(baoming_sign == "0")then			--都没报名
				baoming_sign = "0"
			elseif(baoming_sign=="1")then		--只报职业场
			
				baoming_sign = "1"
			elseif(baoming_sign=="2")then		--没报职业场
			
				baoming_sign = "0"
			elseif(baoming_sign=="3")then		--职业和专家场都报
				
				baoming_sign = "1"
			end
		
		elseif(	query_match_type==3) then 		--专家场
			if(baoming_sign == "0")then 		--都没报名
				baoming_sign = "0"
			elseif(baoming_sign == "1")then 	--没报专家场
				baoming_sign = "0"
			elseif(baoming_sign == "2")then 	--只报专家场
				baoming_sign = "1"
			elseif(baoming_sign == "3")then 	--职业和专家场都报
				baoming_sign = "1"
			end
			
		end
		
		local map_values = user_info.propslist[9] or 0
		
		--发送排行榜 
		act_macth_lib.send_pm_list(user_info, baoming_sign, my_win_gold, my_mc, my_king_count, my_real_play_count, send_len, invite_paimin_list, map_values)
		
	end
	
	--棋牌
    if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    	--德州和棋牌      判断报名    0：未报名    1：职业场      2：专家场       3：职业场和专家场
    	local baoming_sign = user_info.qp_sign_ruslt or "0"	--发送客户端，只有0，未报名；1，已报名
    	
    	--获取排行榜
    	if(query_match_type == 2)then		--麻将
			invite_paimin_list = act_macth_lib.invite_qp_mj_ph_list
		elseif(	query_match_type == 3) then		--智勇三张
			invite_paimin_list = act_macth_lib.invite_qp_zysz_ph_list 
		end
		
		--获得自己排名
		my_mc,my_win_gold,my_king_count,my_play_count = get_my_pm(invite_paimin_list,user_info)	
		if(query_match_type == 2)then
			my_win_gold = user_info.score_2
		elseif(query_match_type == 3)then
			my_win_gold = user_info.score_3
		end 
		
		--将baoming_sign转换  0，未报名；1，已报名
		if(query_match_type == 2)then		--麻将场
			
			if(baoming_sign == "0")then		--都没报名
				baoming_sign = "0"
			elseif(baoming_sign=="1")then		--只报麻将场
			
				baoming_sign = "1"
			elseif(baoming_sign=="2")then		--没报麻将
			
				baoming_sign = "0"
			elseif(baoming_sign=="3")then		--麻将和智勇三张都报名
				
				baoming_sign = "1"
			end
		
		elseif(query_match_type == 3) then 		--智勇三张场
			if(baoming_sign == "0")then 		--都没报名
				baoming_sign = "0"
			elseif(baoming_sign == "1")then 	--没报智勇三张
				baoming_sign = "0"
			elseif(baoming_sign == "2")then 	--只报智勇三张
				baoming_sign = "1"
			elseif(baoming_sign == "3")then 	--麻将和智勇三张都报名
				baoming_sign = "1"
			end
			
		end
		
		local map_values = user_info.bag_items[8005] or 0
		
		--发送排行榜
		act_macth_lib.send_pm_list(user_info, baoming_sign, my_win_gold, my_mc, my_king_count, my_real_play_count, send_len, invite_paimin_list, map_values)
		
    end 
	 
end

--发送排行榜
function act_macth_lib.send_pm_list(user_info, baoming_sign, my_win_gold, my_mc, my_king_count, my_real_play_count, send_len, invite_paimin_list, map_values)
	--TraceError("发送排行榜")
	
	netlib.send(function(buf)
		buf:writeString("INVITEPHLIST")
		
		if(baoming_sign == "1")then
			buf:writeByte(1)	--是否已报名：0，未报名；1，已报名
		else
			buf:writeByte(0)	--是否已报名：0，未报名；1，已报名
	
		end
		
	    --是否显示领奖按钮
	    buf:writeByte(0) --目前没有领奖功能，先拿掉这块的代码了。以后有再加上
	    buf:writeInt(my_win_gold or 0)
	    buf:writeInt(my_mc or 0)
	    buf:writeInt(my_king_count or 0)
	
	    buf:writeInt(60- my_real_play_count)--离60局还差多少局
	    buf:writeString(tostring(my_real_play_count))--还要想想怎么优化，玩的局数 e.g. 10|20|32
	    buf:writeInt(map_values or 0)	--发送挖宝图数量
		if send_len > #invite_paimin_list then send_len = #invite_paimin_list end --最多发20条信息
		----TraceError("send_len:"..send_len)
		
		 buf:writeInt(send_len)
			--再发其他人的
	        for i = 1,send_len do
		        buf:writeInt(invite_paimin_list[i].mingci)	--名次
		        buf:writeInt(invite_paimin_list[i].user_id) --玩家ID
		        buf:writeString(invite_paimin_list[i].nick_name) --昵称
		        buf:writeInt(invite_paimin_list[i].win_gold) --玩家成绩
		  
	        end
	    end,user_info.ip,user_info.port)  
end

--[[
--填写邀请赛的领奖结果，新版本中不再使用了，先保留，防止以后还要发实物奖
function act_macth_lib.on_recv_invite_dj(buf)
	----TraceError("--填写邀请赛的领奖结果，新版本中不再使用了，先保留，防止以后还要发实物奖")
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	local real_name=buf:readString();
	local tel=buf:readString();
	local yy_num=buf:readInt();
	local address=buf:readString();
	local sql="update t_invite_pm set real_name='%s',tel='%s',yy_num=%d,address='%s' where user_id=%d;commit;"
	sql=string.format(sql,real_name,tel,yy_num,address,user_info.userId)
	
	dblib.execute(sql)
	netlib.send(function(buf)
		    buf:writeString("INVITEDJ")
		    buf:writeByte(1)		    
	        end,user_info.ip,user_info.port)   
end
]]


--生成比赛ID，并记录这次比赛的人数，每个桌子在同一时刻，只会有一场比赛，所以直接用桌子号+时间就是唯一的
function act_macth_lib.init_invate_match(deskno)
	----TraceError("--生成比赛ID，并记录这次比赛的人数，每个桌子在同一时刻，只会有一场比赛，所以直接用桌子号+时间就是唯一的")
	local deskinfo = desklist[deskno];
	if deskinfo==nil then return -1 end;
	if(deskinfo ~= nil and deskinfo.smallbet ~= act_macth_lib.room_smallbet1 and deskinfo.smallbet ~= act_macth_lib.room_smallbet2 and deskinfo.smallbet ~= act_macth_lib.room_smallbet3 and deskinfo.smallbet ~= act_macth_lib.room_smallbet4 and deskinfo.smallbet ~= act_macth_lib.room_smallbet5)then
		return -1
	end
	local playinglist=deskmgr.getplayers(deskno)
	
	deskinfo.invate_match_id = deskno..os.time();
	deskinfo.invate_match_count=#playinglist;
	
	local flag=0;--0无效，1有效
	local match_time_status = act_macth_lib.check_datetime();
	if(match_time_status ==2)then
	----TraceError("--生成比赛ID，并记录这次比赛的人数，每个桌子在同一时刻，只会有一场比赛，所以直接用桌子号+时间就是唯一的")
		if(deskinfo.invate_match_count~=nil and deskinfo.invate_match_count>3)then
			flag=1;
		end
		for _, player in pairs(playinglist) do
		local user_info = player.userinfo
			if(#playinglist>1)then
			
				--告诉客户端这次成绩是有效还是无效的
				netlib.send(function(buf)
				    buf:writeString("INVITEREC")
				    buf:writeByte(flag)		    
			        end,user_info.ip,user_info.port)   
			end
		end
	end
	
	return deskinfo.invate_match_id;
end


--[[
--得到邀请赛的ID
function act_macth_lib.get_invate_match_id(deskno)
	----TraceError("--得到邀请赛的ID")
	local deskinfo = desklist[deskno];
	if deskinfo==nil then return -1 end;
	return deskinfo.invate_match_id or -1;
end
]]

--获得桌子数据（德州和棋牌   共用）
function act_macth_lib.get_invate_match_count(deskno)
	
	local deskinfo = desklist[deskno];
	if deskinfo==nil then return -1 end;
	
	local player_valuet = 0
	--德州
	if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		player_valuet = deskinfo.invate_match_count or 0;
	end
	
	--棋牌
    if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    	player_valuet = deskinfo.playercount or 0;
    end
	
	return player_valuet
end

--离比赛开局和结束还差多少秒（德州和棋牌  共用）
function act_macth_lib.on_recv_refresh_timeinfo(buf)
	--这个方法在这里没有用，所以直接返回 
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	local match_time_status = act_macth_lib.check_datetime();--有效是1 无效是0
	--有效：距离结束时间1，距离开场时间0
	--无效：距离结束时间0，距离开场时间1
	local flag1=0;
	local flag2=0;
	if(match_time_status == 0 or match_time_status == 1 or match_time_status == 3)then
		flag1=0
		flag2=1
	else 
		flag1=1
		flag2=0
	end
	--TraceError("离比赛开局和结束还差多少秒   flag1:"..flag1.."  flag2:"..flag2)
	netlib.send(function(buf)
	    buf:writeString("INVITEBTN")
	    buf:writeInt(flag1)  --距离比赛结束时间		
	    buf:writeInt(flag2)  --距离比赛开场时间
	    buf:writeInt(-1)  --现在玩了多少盘		    
	end,user_info.ip,user_info.port)   
end

--客户端通知已经点过领奖按钮了（德州和棋牌  共用）
function act_macth_lib.on_recv_already_know_reward(buf)
	--TraceError("--客户端通知已经点过领奖按钮了  match_type："..match_type.." 游戏名："..gamepkg.name)
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	local match_type = buf:readByte()
	local sql = "update t_invite_pm set get_reward_time=now() where user_id=%d and match_type=%d;commit;"
	sql = string.format(sql,user_info.userId,match_type);
	dblib.execute(sql)
end

--用户登录后事件（德州和棋牌  共用）
act_macth_lib.on_after_user_login = function(e)
	 
	--游戏类型验证
	--德州	--棋牌 
	if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name or act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
		--TraceError("用户登录后事件     gamepkg.name： "..gamepkg.name)
	else
		--TraceError("用户登录后事件->游戏事件验证->不在活动内 ， 返回      gamepkg.name： "..gamepkg.name)
		return
	end
	 
    local userinfo = e.data.userinfo
	
	if(userinfo == nil)then 
		--TraceError("比赛  用户登录后事件。。用户登陆后初始化数据,if(user_info == nil)then")
	 	return
	end
	
	--棋牌
    if(act_wabao_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
		--背包初始化数据
		if(userinfo.bag_items == nil)then 
			bag.get_all_item_info(userinfo,function() end ,nil)
		end
	end
 
	--检查时间有效性
	local match_time_status = act_macth_lib.check_datetime();--有效是1 无效是0
	if(match_time_status == 1 or match_time_status == 3)then 
		--TraceError("-- 用户登录后事件    match_time_status->"..match_time_status.."  发奖") 
		act_macth_lib.invite_match_fajiang(userinfo)
	elseif(match_time_status == 0)then
		--TraceError("-- 用户登录后事件     match_time_status->"..match_time_status.."  时间无效")
		return
	end
	 
	--初始化竞技场成绩
	if(userinfo.score_2 == nil)then
		userinfo.score_2 = 0
	end
	if(userinfo.score_3 == nil)then
		userinfo.score_3 = 0
	end
	
	act_macth_lib.invite_update_user_play_count(userinfo)
	
end

--用户登录后初始化数据
function act_macth_lib.invite_update_user_play_count(user_info)

		--德州报名标志
		if(user_info.sign_ruslt == nil)then
			user_info.sign_ruslt = "0"
		end
		
		--棋牌报名标志
		if(user_info.qp_sign_ruslt == nil)then
			user_info.qp_sign_ruslt = "0"
		end
 
		local sql = "SELECT play_count,match_type,win_gold FROM t_invite_pm where user_id=%d order by match_type"
		sql = string.format(sql,user_info.userId)
		dblib.execute(sql,function(dt)
			if(dt ~= nil and #dt > 0)then			
				for i=1,#dt do
 
 					--德州
					if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
						if(dt[i].match_type == 1)then
							user_info.yy_play_count=dt[i].play_count or 0
		
						elseif(dt[i].match_type == 2)then
							user_info.zy_play_count=dt[i].play_count or 0
							user_info.score_2 = dt[i].win_gold or 0
				
						elseif(dt[i].match_type == 3)then
							user_info.zj_play_count=dt[i].play_count or 0
							user_info.score_3 = dt[i].win_gold or 0
						end
					end
					
					--棋牌
    				if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    					
    					if(dt[i].match_type == 1)then
							user_info.qp_play_count = dt[i].play_count or 0
		
						elseif(dt[i].match_type == 2)then
							user_info.qp_play_count = dt[i].play_count or 0
							user_info.score_2 = dt[i].win_gold or 0
							
						elseif(dt[i].match_type == 3)then
							user_info.qp_play_count = dt[i].play_count or 0
							user_info.score_3 = dt[i].win_gold or 0
						end
						
						--判断是否有材料
						if(user_info.bag_items == nil)then
							----TraceError("背包为空")
							bag.get_all_item_info(user_info,function() end ,nil)
						end			
    				end
				
				end
			end
		end)
		 
		--sql="SELECT SUM(sign) AS sign FROM t_invite_pm where user_id=%d AND DATE(baoming_time) = DATE(NOW()) and hour(baoming_time)<23 "
		--sql="SELECT SUM(sign) AS sign FROM t_invite_pm WHERE user_id=%d AND !(DATE(baoming_time) != DATE(NOW()) OR  ((HOUR(NOW())<23 AND baoming_time='1900-01-01 00:00:00') OR ( HOUR(NOW())>=23 AND HOUR(baoming_time)<23)));"
		--复杂的SQL,（1、判断当天内报名情况，2、判断当天23：00到明天23：00报名情况，3、判断31日至1日情况，4、判断无报名情况）
		sql = "SELECT SUM(sign) AS sign FROM t_invite_pm WHERE user_id=%d AND (!(DATE(baoming_time) != DATE(NOW()) OR  ((HOUR(NOW())<23 AND baoming_time='1900-01-01 00:00:00') OR ( HOUR(NOW())>=23 AND HOUR(baoming_time)<23))) OR (DATE(baoming_time)=DATE_SUB(DATE(NOW()), INTERVAL 1 DAY) AND HOUR(baoming_time)>=23))"
		
		sql = string.format(sql,user_info.userId) 
		dblib.execute(sql,function(dt)
			if(dt~=nil and #dt>0)then	
				
				--德州
				if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
					user_info.sign_ruslt = dt[1].sign or "0"  --取出值，0：未报名 1：职业场  2：专家场  3：职业场和专家场
					 
					if(user_info.sign_ruslt == "" )then
						user_info.sign_ruslt = "0"
					end
				end
				
				--棋牌
    			if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    				user_info.qp_sign_ruslt = dt[1].sign or "0"  --取出值，0：未报名 1：职业场  2：专家场  3：职业场和专家场
					 
					if(user_info.qp_sign_ruslt == "" )then
						user_info.qp_sign_ruslt = "0"
					end
    			end
			end
		end)
end

--计算第几场（德州和棋牌  共用）
function act_macth_lib.consider_screen()
	 
	local t1 = act_macth_lib.start_day
	local now_time = os.date("%Y%m%d", os.time())
	
	local day1 = {}
	day1.year,day1.month,day1.day = string.match(t1,"(%d%d%d%d)(%d%d)(%d%d)")
	
	local day2 = {}
	day2.year,day2.month,day2.day = string.match(now_time,"(%d%d%d%d)(%d%d)(%d%d)")
	
	local numDay1 = os.time(day1)
	
	local numDay2 = os.time(day2)
	 
	local total_day = (numDay2 - numDay1)/(3600*24) + 1
	
	return total_day
end

--给玩家发奖
--产生结果后，再打一盘就发奖，或重登陆时才发奖
function act_macth_lib.invite_match_fajiang(user_info)
	--TraceError("给玩家发奖，用户id："..user_info.userId)
 
	local mc = -1;
 
	local screen_n = act_macth_lib.consider_screen()	--计算第几场
	
	local send_result = function(user_info,mc,match_type)
		--TraceError("给玩家发奖 发送结果 名次:"..mc.."  用户userid:"..user_info.userId.."  类型match_type"..match_type.." 游戏名："..gamepkg.name)
		netlib.send(function(buf)
		    buf:writeString("INVITEGIF")
		    buf:writeInt(mc)  --名次	
		    buf:writeByte(match_type)
		    buf:writeInt(screen_n)  --第几场	    
		end,user_info.ip,user_info.port)  
	end
	
	--具体发奖
	local jutifajiang = function(i,user_info,reward,match_type)
		 
		--德州
		if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
			--给发奖 加藏宝图
			tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.wabao_map_id, reward, user_info)
			
			--记录发奖日志
			local sql = "INSERT INTO log_treasurebox_prize(user_id, game_name, sys_time, box_id, prize_id)VALUES(%d, '%s', now(), %d, %d);commit;"
			sql = string.format(sql,user_info.userId,gamepkg.name,match_type,reward);
			dblib.execute(sql)  
			
			--系统发冠军广播消息    采用定时发送    这里处理
		end
		
		--棋牌
    	if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    		--给发奖 加藏宝图 
			local add_items_result = act_wabao_lib.chaxun_add_items(user_info, 8005, reward, 1)
			 
			--记录发奖日志
			local sql = "INSERT INTO log_treasurebox_prize(user_id, game_name, sys_time, box_id, prize_id)VALUES(%d, '%s', now(), %d, %d);commit;"
			sql = string.format(sql,user_info.userId,gamepkg.name,match_type,reward);
			dblib.execute(sql) 
			
			--系统发冠军广播消息    采用定时发送    这里处理  
    	end 
	end
 
 
 	
	--发奖
	local fajiang = function(user_info,match_type,reward1,reward2,reward3,reward4,reward5,reward6)
	 	--TraceError("给玩家发奖，用户id："..user_info.userId.."  match_type:"..match_type.." 游戏名："..gamepkg.name)
		local sql = "select user_id,get_reward_time from t_invite_pm where match_type=%d and play_count>=1  order by win_gold desc limit 20";
		sql = string.format(sql,match_type)
		 
		dblib.execute(sql,function(dt)	
				if(dt ~= nil and  #dt > 0)then
					--local fajiang_flag=0;
					local len = 20
					if(#dt < 20)then
						len = #dt
					end
					
					for i = 1,len do
						local get_reward_time = 0;
						if(dt[i].get_reward_time ~= nil)then
							get_reward_time = timelib.db_to_lua_time(dt[i].get_reward_time) or 0
						end
					  	if(dt[i].user_id == user_info.userId and get_reward_time < timelib.db_to_lua_time('2010-11-11'))then
	     			  			if(i == 1)then
					  				jutifajiang(i,user_info,reward1,match_type)
					  			elseif(i == 2)then
					  				jutifajiang(i,user_info,reward2,match_type)
					  				 
					  			elseif(i == 3)then
					  				jutifajiang(i,user_info,reward3,match_type)
					  				 
					  			elseif(i == 4 or i == 5)then
					  				jutifajiang(i,user_info,reward4,match_type)
					  				 
					  			elseif(i >= 6 and i <= 10)then
					  				jutifajiang(i,user_info,reward5,match_type)
					  			
					  			elseif(i >= 11 and i <= 20)then
					  				jutifajiang(i,user_info,reward6,match_type)
					  				 
					  			end
					  			
					  			--在2月21日没有使用这个方法发送通知消息
					      		--send_result(user_info,i,match_type)
					    end
					end
					
					--更新领奖信息,如果是有名次的，就更新他的领奖时间，如果是没名次的，就直接清0
					sql = "update t_invite_pm set get_reward_time=now() where user_id=%d and match_type=%d;commit;";
					sql = string.format(sql,user_info.userId,match_type)
					dblib.execute(sql)
				end
		end)  
	end
 
 	--德州
	if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		--[[
		专家场：第一名200张；第二名100张；第三名50张；4-5名20张；6-10名10张；11-20名5张
 		 职业场：第一名100张；第二名50张；第三名20张；4-5名10张；6-10名5张；11-20名2张
]]
		
		--发业余场的奖 
		--fajiang(userinfo,1,10000,2000,1000,500,500);
		
		--发职业场的奖
		fajiang(user_info,2,100,50,20,10,5,2);
		
		--发专家场的奖
		fajiang(user_info,3,200,100,50,20,10,5);
	end
	
	--棋牌
    if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    --[[
      	智勇三张：第一名200张；第二名100张；第三名50张；4-5名20张；6-10名10张；11-20名5张
  		麻将：第一名100张；第二名50张；第三名20张；4-5名10张；6-10名5张；11-20名2张
    ]]
    	--TraceError("给玩家发奖，棋牌    发奖前     用户id："..user_info.userId.." 游戏名："..gamepkg.name)
    	--发麻将的奖 
    	if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == "mj")then
			fajiang(user_info,2,100,50,20,10,5,2);
		end
	 
		--发智勇三张的奖
		if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == "zysz")then
			fajiang(user_info,3,200,100,50,20,10,5);
		end 
    end 
end

--请求活动时间状态（德州和棋牌   共用）
function act_macth_lib.on_recv_activity_stat(buf)

	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	
	--0，活动无效，不显示相关UI；2，活动有效，比赛阶段
	local check_stat = act_macth_lib.check_datetime()
	
	local endtime = timelib.db_to_lua_time(act_macth_lib.endtime);
	local ranktime =  timelib.db_to_lua_time(act_macth_lib.rank_endtime);
	local sys_time = os.time();
	if(sys_time > endtime) then
		check_stat = 5 --整个活动结束后，排行榜图标保留1天后消失。
	end
	
	if(sys_time > ranktime) then
		check_stat = 0 --整个活动结束
	end
	
	--为了兼容以前的代码
	if(check_stat==3)then
		check_stat=1
	end
	
	--TraceError("--请求活动时间状态-->>"..check_stat)
	
	netlib.send(function(buf)
		    buf:writeString("INVITEPHDATE")
		    buf:writeByte(check_stat)		    
	        end,user_info.ip,user_info.port)   
end

--请求报名比赛
function act_macth_lib.on_recv_sign(buf)
	
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	
	--TraceError("--请求报名比赛  用户id："..user_info.userId)
	
	--德州  报名哪一个场： 2，职业场；3，专家场
	--棋牌  报名哪一个场： 1，麻将；2，	智勇三张
	local sign = buf:readByte()
	
	--1，报名成功；2，报名失败，不够资格证；3，活动过期；4，其它异常情况
	local sign_ruslt = 0
	local check_time=act_macth_lib.check_datetime()
	--德州
	if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		--查询门票数量
		local shiptickets_count = user_info.propslist[7]
	    
		if(sign == 2)then	--2，职业场
			if(check_time == 0 or check_time==1 )then	--判断活动有效性
				sign_ruslt = 3
				--TraceError(" 请求报名比赛 职业场  活动时间失效  3  用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			elseif(shiptickets_count < 2)then	--判断报名资格
				sign_ruslt = 2
		 		--TraceError("请求报名比赛   职业场   门票不足     2   用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			
			else--报名成功，需扣除资格证数量
				sign_ruslt = 1
				act_macth_lib.sign_succes(user_info, 2, sign)
			end
			
		elseif(sign == 3)then	--3，专家场
			if(check_time == 0 or check_time==1)then	--判断活动有效性
				sign_ruslt = 3
				--TraceError("请求报名比赛   专家场 活动时间失效    3  用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			elseif(shiptickets_count < 5)then	--判断报名资格
				sign_ruslt = 2
				--TraceError("请求报名比赛    专家场    门票不足    2  用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			
			else--报名成功，需扣除资格证数量
				sign_ruslt = 1
				act_macth_lib.sign_succes(user_info, 5, sign)
			end
			
		else
			--TraceError("请求报名比赛       报名错误, 用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			return;
		end
	end
	
	--棋牌
    if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    	--查询门票数量
		local shiptickets_count = user_info.bag_items[act_macth_lib.qp_mp_id] or 0;
	    
		if(sign == 2)then	--2，麻将
			if(act_macth_lib.check_datetime() == 0)then	--判断活动有效性
				sign_ruslt = 3
				--TraceError(" 请求报名比赛 麻将  活动时间失效  3  用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			elseif(shiptickets_count < 2)then	--判断报名资格
				sign_ruslt = 2
		 		--TraceError("请求报名比赛  麻将   门票不足     2   用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			
			else--报名成功，需扣除资格证数量
				sign_ruslt = 1
				act_macth_lib.sign_succes(user_info, 2, sign)
			end
			
		elseif(sign == 3)then	--3，智勇三张
			if(act_macth_lib.check_datetime() == 0)then	--判断活动有效性
				sign_ruslt = 3
				--TraceError("请求报名比赛   智勇三张 活动时间失效      用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			elseif(shiptickets_count < 5)then	--判断报名资格
				sign_ruslt = 2
				--TraceError("请求报名比赛    智勇三张    门票不足      用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			
			else--报名成功，需扣除资格证数量
				sign_ruslt = 1
				act_macth_lib.sign_succes(user_info, 5, sign)
			end
			
		else
			--TraceError("请求报名比赛       报名错误, 用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			return;
		end
    end
		 
	netlib.send(function(buf)
		    buf:writeString("INVITESIGNUP")
		    buf:writeByte(sign_ruslt)		    
	        end,user_info.ip,user_info.port) 
end

--报名成功
function  act_macth_lib.sign_succes(user_info, k_count, match_type)
	--TraceError("报名成功->>match_type:"..match_type.."k_count:"..k_count.." 游戏名："..gamepkg.name)
	--user_info.sign_ruslt记录    0：未报名        1：职业场        2：专家场          3：职业场和专家场
	
	local xie_sign = 0
	--德州
	if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		if(match_type == 2)then
			if(user_info.sign_ruslt == "0")then
				user_info.sign_ruslt = "1"
				xie_sign = 1
			elseif(user_info.sign_ruslt == "2")then
				user_info.sign_ruslt = "3"
	 			xie_sign = 1
			end
		elseif(match_type == 3)then
			----TraceError("报名成功user_info.sign_ruslt->>"..user_info.sign_ruslt)
			if(user_info.sign_ruslt == "0")then
				user_info.sign_ruslt = "2"
				xie_sign = 2
			elseif(user_info.sign_ruslt == "1")then
				user_info.sign_ruslt = "3"
	 			xie_sign = 2
			end
		end
		
		user_info.propslist[7] = user_info.propslist[7] - k_count
		tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.NewYearTickets_ID, -k_count, user_info)
		--TraceError("--报名成功，需扣除门票数量："..k_count.." 游戏名："..gamepkg.name)
	end
	
	--棋牌
    if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    	if(match_type == 2)then
			if(user_info.qp_sign_ruslt == "0")then
				user_info.qp_sign_ruslt = "1"
				xie_sign = 1
			elseif(user_info.qp_sign_ruslt == "2")then
				user_info.qp_sign_ruslt = "3"
	 			xie_sign = 1
			end
		elseif(match_type == 3)then
			----TraceError("报名成功user_info.sign_ruslt->>"..user_info.sign_ruslt)
			if(user_info.qp_sign_ruslt == "0")then
				user_info.qp_sign_ruslt = "2"
				xie_sign = 2
			elseif(user_info.qp_sign_ruslt == "1")then
				user_info.qp_sign_ruslt = "3"
	 			xie_sign = 2
			end
		end
		
		--加背包
		local add_items_result = act_macth_lib.chaxun_add_items(user_info, act_macth_lib.qp_mp_id, -k_count, 1)
		 
		--TraceError("--报名成功，需扣除门票数量："..k_count.." 游戏名："..gamepkg.name)
    end
	 
	--报名写数据库
	act_macth_lib.inster_invite_db(user_info,0,match_type,xie_sign)
	
	--写日志	
	local sql = "INSERT INTO log_invite_baoming_info (userid,card_count,card_type,sys_time)	VALUES (%d,%d,%d,now());"
	sql = string.format(sql,user_info.userId,k_count,match_type);
	dblib.execute(sql)
end

--报名写数据库
function act_macth_lib.inster_invite_db(user_info,match_gold,match_type, xie_sign)
	--TraceError("报名写数据库,sign->"..xie_sign.." 用户id："..user_info.userId.." 游戏名："..gamepkg.name)

	local sql = "insert into t_invite_pm(user_id,nick_name,win_gold,match_type,baoming_time,sign) value(%d,'%s',%d,%d,now(),%d) ON DUPLICATE KEY UPDATE baoming_time=NOW()";
	local nick = string.trans_str(user_info.nick)
	sql = string.format(sql,user_info.userId,nick,match_gold,match_type,xie_sign);
	dblib.execute(sql) 
end	

--请求购买比赛券
function act_macth_lib.on_recv_buy_ticket(buf)
	
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
	
	--TraceError("请求购买比赛券     用户id："..user_info.userId.." 游戏名："..gamepkg.name)
	
	local gold = get_canuse_gold(user_info)--获得用户筹码
	local ruslt = 0
	
	--判断活动有效性
	local check_time = act_macth_lib.check_datetime()
	local endtime = timelib.db_to_lua_time(act_macth_lib.endtime);
	local sys_time = os.time();
	if(check_time == 0 or check_time==1 or sys_time > endtime)then
		ruslt = 2
		--TraceError("--111111111111111请求购买比赛券错误  活动已过期     用户id："..user_info.userId.." 游戏名："..gamepkg.name)
		 
		--发送购买比赛券结果
		act_macth_lib.send_buy_ticket_result(user_info, ruslt)
		return
	end
	
	--德州
	if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		if(act_macth_lib.check_datetime() == 0)then	--判断活动有效性
			ruslt = 2
			--TraceError("--请求购买比赛券错误  活动已过期     用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			 
			--发送购买比赛券结果
			act_macth_lib.send_buy_ticket_result(user_info, ruslt)
			return
			
		elseif(gold < act_macth_lib.OP_MENPIAO_PRIZE["tex"])then	--判断筹码小于2万筹码
			ruslt = 0
		 	--TraceError("-- 请求购买比赛券错误  筹码小于2万筹码     用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			
			--发送购买比赛券结果
			act_macth_lib.send_buy_ticket_result(user_info, ruslt)
			return
			
		else--报名成功，需扣除资格证数量
			--TraceError("发送购买比赛券结果,成功     用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			ruslt = 1
	 		--减2万筹码
		    usermgr.addgold(user_info.userId, -1*act_macth_lib.OP_MENPIAO_PRIZE["tex"], 0, g_GoldType.baoxiang, -1);
		     
		    --加春节大赛参赛券 
	  		tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.NewYearTickets_ID, 1, user_info)
	  	
	  		--发送购买比赛券结果
			act_macth_lib.send_buy_ticket_result(user_info, ruslt)
			return
		end
	end
	
	--棋牌
    if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
    	--查询道具情况
		local chaxun_items_result = act_macth_lib.chaxun_add_items(user_info, act_macth_lib.qp_mp_id, 0, 0)
		 
		local desk_no = user_info.desk		-- 用于判断是否在牌桌内    如果在不能购买
		
    	if(act_macth_lib.check_datetime() == 0)then	--判断活动有效性
			ruslt = 2
			--TraceError("--请求购买比赛券错误  活动已过期     用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			
			--发送购买比赛券结果
			act_macth_lib.send_buy_ticket_result(user_info, ruslt)
			return
			
		elseif(gold < act_macth_lib.OP_MENPIAO_PRIZE["qp"])then	--判断筹码小于10万金币
			ruslt = 0
		 	--TraceError("-- 请求购买比赛券错误  筹码小于10万金币    用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			
			--发送购买比赛券结果
			act_macth_lib.send_buy_ticket_result(user_info, ruslt)
			return
			
		elseif(chaxun_items_result == 3)then		-- 满，返回
			ruslt = 4
		 	--TraceError("-- 请求购买比赛券错误  道具满     用户id："..user_info.userId.." 游戏名："..gamepkg.name)
			
			--发送购买比赛券结果
			act_macth_lib.send_buy_ticket_result(user_info, ruslt)
			return
		
		elseif(desk_no ~= nil)then	--判断是否在牌桌内
			ruslt = 0
		 	--TraceError("-- 请求购买比赛券错误  在牌桌内   不能购买    用户id："..user_info.userId.." 游戏名："..gamepkg.name)
		 	
		 	--发送购买比赛券结果
			act_macth_lib.send_buy_ticket_result(user_info, ruslt)
			return
						
		else--请求购买比赛券成功，需扣除资格证数量
 			
 			--减10万金币
		    usermgr.addgold(user_info.userId, -1*act_macth_lib.OP_MENPIAO_PRIZE["qp"], 0, tSqlTemplete.goldType.HD_NEW_YEAR, -1);
		    
			--加背包门票
			local add_items_result = act_macth_lib.chaxun_add_items(user_info, act_macth_lib.qp_mp_id, 1, 1)
			
			----TraceError("-- 请求购买比赛券   加背包门票    返回    用户id："..user_info.userId.." 游戏名："..gamepkg.name.." add_items_result:"..add_items_result)
			
			--判断加道具结果
			if(add_items_result == 1)then		--加道具成功
				
				--TraceError("发送购买比赛券结果,成功     用户id："..user_info.userId.." 游戏名："..gamepkg.name)
				ruslt = 1
				
				--发送购买比赛券结果
				act_macth_lib.send_buy_ticket_result(user_info, ruslt)
				return
			else	
				--通知用户背包满或其它
				--ruslt = 4
				
				--发送购买比赛券结果
				--act_macth_lib.send_buy_ticket_result(user_info, ruslt)
				--return
			end
		end
    end 
end
 
--发送购买比赛券结果
function act_macth_lib.send_buy_ticket_result(user_info, ruslt)
	--TraceError("发送购买比赛券结果,userId:"..user_info.userId.." ruslt->"..ruslt.." 游戏名："..gamepkg.name)
	netlib.send(function(buf)
		    buf:writeString("INVITEBUYTK")
		    buf:writeByte(ruslt)		    
	        end,user_info.ip,user_info.port) 
end


--棋牌  查询  和加   道具公用方法          item_id:道具id    item_num：道具数量           use_type：使用方式（0:查询   1：加  减）
function act_macth_lib.chaxun_add_items(user_info, item_id, item_num, use_type)
	--TraceError("棋牌  查询  和加   道具公用方法,item_id:"..item_id.." item_num->"..item_num.." use_type:"..use_type.." 用户id: "..user_info.userId)
  
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
    --TraceError("棋牌  查询  和加   道具公用方法,  用户id: "..user_info.userId.."  返回结果:"..ret)
	return ret 
end

-- 全服发广播(棋牌专用)
function act_macth_lib.ontimer_broad(tips,flag)
    --如果提示不为nil 全服发广播。
    if(flag == nil or flag~= 1)then
    	
      tips = _U(tips)
    end
    if (tips ~=  nil and tips ~=  "" and groupinfo.groupid == 3005) then
    	
        tools.SendBufToUserSvr("", "SPBC", "", "", tips)
    end
end
 
--发送发奖消息
act_macth_lib.send_fajiang_msg = function()
	
	--德州
	if(act_macth_lib.cfg_tex_game_name[gamepkg.name] == gamepkg.name)then
		--职业场
	 	local sql = "SELECT nick_name FROM t_invite_pm WHERE match_type = 2 AND play_count >= 1  ORDER BY win_gold DESC LIMIT 3";
		sql = string.format(sql,match_type)
		 
		dblib.execute(sql,function(dt)	
				if(dt ~= nil and  #dt > 0)then
					local len = 3
					if(#dt < 3)then
						len = #dt
					end
					 
					local msg = ""
					for i = 1,len do
						if(i == 1)then
							msg = _U(tex_lan.get_msg(user_info, "match_msg_awards_1"))..dt[i].nick_name.._U(tex_lan.get_msg(user_info, "match_msg_awards_type_2"));
							msg = string.format(msg,i,100);
						elseif(i == 2)then
						 	msg = _U(tex_lan.get_msg(user_info, "match_msg_awards_1"))..dt[i].nick_name.._U(tex_lan.get_msg(user_info, "match_msg_awards_type_2"));
							msg = string.format(msg,i,50);
						elseif(i == 3)then
						 	msg = _U(tex_lan.get_msg(user_info, "match_msg_awards_1"))..dt[i].nick_name.._U(tex_lan.get_msg(user_info, "match_msg_awards_type_2"));
							msg = string.format(msg,i,20);
						end 
						BroadcastMsg(msg,0)
					end 
				end
			end)
		
		--专家场
		local sql = "SELECT nick_name FROM t_invite_pm WHERE match_type = 3 AND play_count >= 1  ORDER BY win_gold DESC LIMIT 3";
		sql = string.format(sql,match_type)
		 
		dblib.execute(sql,function(dt)	
				if(dt ~= nil and  #dt > 0)then
					local len = 3
					if(#dt < 3)then
						len = #dt
					end
					
					local msg = ""
					for i = 1,len do
						if(i == 1)then
							msg = _U(tex_lan.get_msg(user_info, "match_msg_awards_1"))..dt[i].nick_name.._U(tex_lan.get_msg(user_info, "match_msg_awards_type_3"));
							msg = string.format(msg,i,200);
						elseif(i == 2)then
						 	msg = _U(tex_lan.get_msg(user_info, "match_msg_awards_1"))..dt[i].nick_name.._U(tex_lan.get_msg(user_info, "match_msg_awards_type_3"));
							msg = string.format(msg,i,100);
						elseif(i == 3)then
						 	msg = _U(tex_lan.get_msg(user_info, "match_msg_awards_1"))..dt[i].nick_name.._U(tex_lan.get_msg(user_info, "match_msg_awards_type_3"));
							msg = string.format(msg,i,50);
						end 
						BroadcastMsg(msg,0)
					end 
				end
			end)
	end
	
	--棋牌
    if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == gamepkg.name)then
		
		--麻将
	 	local sql = "SELECT nick_name FROM t_invite_pm WHERE match_type = 2 AND play_count >= 1  ORDER BY win_gold DESC LIMIT 3";
		sql = string.format(sql,match_type)
		 
		dblib.execute(sql,function(dt)	
				if(dt ~= nil and  #dt > 0)then
					local len = 3
					if(#dt < 3)then
						len = #dt
					end
					
					local msg = ""
					
					msg = _U("恭喜   ")..dt[1].nick_name.._U("  、 ")..dt[2].nick_name.._U("  、 ")..dt[3].nick_name.._U("获得了今日麻将竞技场前3名，依次奖励藏宝图100 张、50 张、20 张！")
					
					act_macth_lib.ontimer_broad(msg,1);
						 
					--指定向 智勇三张  发
					if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == "zysz")then
						BroadcastMsg(msg,0)
					end
				end
			end)
		
		--智勇三张
		local sql = "SELECT nick_name FROM t_invite_pm WHERE match_type = 3 AND play_count >= 1  ORDER BY win_gold DESC LIMIT 3";
		sql = string.format(sql,match_type)
		 
		dblib.execute(sql,function(dt)	
				if(dt ~= nil and  #dt > 0)then
					local len = 3
					if(#dt < 3)then
						len = #dt
					end
					local msg1 = ""
					
					msg1 = _U("恭喜   ")..dt[1].nick_name.._U("  、 ")..dt[2].nick_name.._U("  、 ")..dt[3].nick_name.._U("获得了今日智勇三张竞技场前3名，依次奖励藏宝图200 张、100 张、50 张！")
					
					act_macth_lib.ontimer_broad(msg1,1);
						 
					--指定向 智勇三张  发
					if(act_macth_lib.cfg_qp_game_name[gamepkg.name] == "zysz")then
						BroadcastMsg(msg1,0)
					end
					
				end
			end)
		
	end 
end
 
--协议命令
cmd_tex_match_handler = 
{ 
    --竞技场相关协议
    ["INVITEPHLIST"] = act_macth_lib.on_recv_invite_ph_list,  --请求邀请赛的排行榜
   -- ["INVITEDJ"] = act_macth_lib.on_recv_invite_dj,  --填写邀请赛的领奖结果
    ["INVITEBTN"] = act_macth_lib.on_recv_refresh_timeinfo, --请求刷新图标按钮信息
    ["INVITEGIF"] = act_macth_lib.on_recv_already_know_reward, --客户端通知已经点过领奖按钮了
    
    ["INVITEPHDATE"] = act_macth_lib.on_recv_activity_stat, --请求活动时间状态
    ["INVITESIGNUP"] = act_macth_lib.on_recv_sign, --请求报名比赛
    ["INVITEBUYTK"] = act_macth_lib.on_recv_buy_ticket, --请求购买比赛券
}

--加载插件的回调
for k, v in pairs(cmd_tex_match_handler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("h2_on_user_login", act_macth_lib.on_after_user_login);
eventmgr:addEventListener("timer_minute", act_macth_lib.ontimecheck); 
eventmgr:addEventListener("game_event", act_macth_lib.ongameover); 
eventmgr:addEventListener("game_begin_event", act_macth_lib.ongamebegin);  

