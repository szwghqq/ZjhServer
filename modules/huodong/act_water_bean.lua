TraceError("init newyear_activity...")
if newyear_lib and newyear_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", newyear_lib.on_after_user_login);
end

if newyear_lib and newyear_lib.ontimecheck then
	eventmgr:removeEventListener("timer_minute", newyear_lib.ontimecheck);
end
		
if not newyear_lib then
    newyear_lib = _S
    {
        on_after_user_login = NULL_FUNC,--用户登陆后初始化数据
 
		check_datetime = NULL_FUNC,	--检查有效时间，限时问题
		ongameover = NULL_FUNC,	--游戏结束采集盘数
		net_send_playnum = NULL_FUNC,	--发送盘数和时间状态
		ontimecheck = NULL_FUNC,	--定时刷新事件
		on_recv_monster_info = NULL_FUNC,	--请求年兽数据
		on_recv_attack_monster = NULL_FUNC,	--攻击年兽
		send_attack_monster_result = NULL_FUNC,--发送攻击年兽结果
		init_attack_ph = NULL_FUNC,	--初始化排行榜
		on_recv_attack_ph_list = NULL_FUNC,	--请求排行榜
		get_my_pm = NULL_FUNC,	--找自己的排行榜
		send_ph_list = NULL_FUNC,	--发送排行榜
		on_recv_activity_stat = NULL_FUNC,	--请求活动时间状态
		on_recv_activation = NULL_FUNC,	--请求打开活动面板
		send_monster_stat = NULL_FUNC,	--通知用户,年兽状态
		on_recv_buy_fire = NULL_FUNC,	--购买礼炮
		send_buy_gun_result = NULL_FUNC,	--发送购买礼炮结果
		on_recv_gun_info = NULL_FUNC,	--通知客户端，返回鞭炮、烟花、礼炮等信息
		send_gun_info = NULL_FUNC,	--发送鞭炮、烟花、礼炮等信息
		on_recv_exorcist_packs = NULL_FUNC,	--通知服务端，请求领取“驱魔礼包”
 		send_exorcist_packs_result = NULL_FUNC,	--发送请求领取“驱魔礼包”结果
 		sync_dragon_blood = NULL_FUNC,		--同步年兽生命值
		read_dragon_blood = NULL_FUNC,			--读取年兽生命值
		write_dragon_blood = NULL_FUNC,			--更新年兽生命值
		send_my_hurt = NULL_FUNC,		--发送我的伤害
		query_db = NULL_FUNC,		--查询或更新自己数据
 		autoNotifyClientForStart = NULL_FUNC,  --自动通知客户端活动时间到了
        refresh_invate_time = -1,  --上一次刷新时间
        
        play1_num = 20,    --鞭炮盘数
        play2_num = 40,    --烟花盘数
        
        blood = 600000,	--是血条，gs上的全局变量 
		last_blood = 0,	-- 上次同步时血条的值 
		add_blood = 0,	-- 是血条变化的值 
        
        attack_ph_list = {}, --攻击年兽排名
 		
 		player_count = 3,		--每局需求玩家数
 		
        activ1_statime = "2012-06-21 09:00:00",  --活动开始时间
    	activ1_endtime = "2012-06-27 24:00:00",  --活动结束时间
    	rank_endtime = "2012-06-29 00:00:00",	--排行榜结束时间
    }    
 end
 
 --同步年兽生命值
 --
function newyear_lib.sync_dragon_blood() 
	local function set_this_gameserver_blood(tmp_blood) 
		newyear_lib.last_blood = tmp_blood; 
		--TraceError("同步年兽生命值,之前,newyear_lib.blood:"..newyear_lib.blood.." newyear_lib.last_blood:"..newyear_lib.last_blood.." newyear_lib.add_blood:"..newyear_lib.add_blood)
		newyear_lib.blood = newyear_lib.last_blood - newyear_lib.add_blood; 
		set_param_value("DRAGON_BLOOD",newyear_lib.blood);
		--TraceError("同步年兽生命值,之前,newyear_lib.blood:"..newyear_lib.blood.." newyear_lib.last_blood:"..newyear_lib.last_blood.." newyear_lib.add_blood:"..newyear_lib.add_blood) 
		newyear_lib.add_blood=0; 
	end 
	get_param_value("DRAGON_BLOOD",set_this_gameserver_blood) 
end 

--读取年兽生命值
function newyear_lib.read_dragon_blood()
	local monster_value = 0
	local sql = "SELECT param_value FROM cfg_param_info WHERE param_key = 'DRAGON_BLOOD'"
	sql = string.format(sql);
	dblib.execute(sql,
    function(dt)
    	if dt and #dt > 0 then
    		monster_value = dt[1]["param_value"] or 0
    		if(monster_value > newyear_lib.blood)then
    			--TraceError("读取年兽生命值,monster_value > newyear_lib.blood,,monster_value:"..monster_value.." newyear_lib.blood:"..newyear_lib.blood)
    			return
    		end
    		--TraceError("读取年兽生命值,monster_value 小于 newyear_lib.blood,,monster_value:"..monster_value.." newyear_lib.blood:"..newyear_lib.blood)
    		newyear_lib.blood = monster_value
		end
	end)
end

--更新年兽生命值
function newyear_lib.write_dragon_blood(monster_value)
	--更新数据库
	local sqltemplet = "update cfg_param_info set param_value = %d WHERE param_key = 'DRAGON_BLOOD'";             
	dblib.execute(string.format(sqltemplet, monster_value))
end

 
--用户登陆后初始化数据
newyear_lib.on_after_user_login = function(e)
	local user_info = e.data.userinfo
	--TraceError("用户登陆后初始化数据,userid:"..user_info.userId)
	if(user_info == nil)then 
		--TraceError("用户登陆后初始化数据,if(user_info == nil)then")
	 	return
	end
	
	local check_result = newyear_lib.check_datetime()	--检查活动时间
	
	
	--加载鞭炮、烟花、礼炮
--	if(tex_gamepropslib ~= nil) then
 --       tex_gamepropslib.get_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_1_ID, user_info, function(tool_count) end)
 --       tex_gamepropslib.get_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_2_ID, user_info, function(tool_count) end)
 --       tex_gamepropslib.get_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_3_ID, user_info, function(tool_count) end)
 --   end
  
     --初始化用户盘数
    if(user_info.newyear_play_count == nil)then
    	user_info.newyear_play_count = 0
    end
    
    --初始化用户伤害值
    if(user_info.newyear_attack_value == nil)then
    	user_info.newyear_attack_value = 0
    end
    
    --初始化用户驱魔礼包领取标记
    if(user_info.newyear_libao_sign == nil)then
    	user_info.newyear_libao_sign = 0
    end
    --检查活动时间放后面是为了活动时间到了可以响应在线用户的请求
	if(check_result == 0 or check_result == 5)then
		--TraceError("用户登陆后初始化数据,if(check_result == 0 and check_result == 5)then")
		return
	end
	--查询或更新自己数据
	newyear_lib.query_db(user_info)
    
end

--查询或更新自己数据
function newyear_lib.query_db(user_info)
	local _tosqlstr = function(s) 
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
	
	local user_nick=user_info.nick
	user_nick=_tosqlstr(user_nick).."   "
	
	--查询或更新数据库
	local sql = "insert ignore into t_attack_monster_rank (user_id, user_nick, sys_time) values(%d, '%s', now());commit;";
    sql = string.format(sql, user_info.userId, user_nick);
	dblib.execute(sql)
	
	local sql_1 = "select sys_time,attack_value,libao_sign,play_count from t_attack_monster_rank where user_id = %d"
	sql_1 = string.format(sql_1, user_info.userId);
	
	dblib.execute(sql_1,
    function(dt)
    	if dt and #dt > 0 then

    		local sys_today = os.date("%Y-%m-%d", os.time()); --系统的今天
            local db_date = os.date("%Y-%m-%d", timelib.db_to_lua_time(dt[1]["sys_time"]));  --数据库的今天
            user_info.newyear_attack_value = dt[1]["attack_value"] or 0
            user_info.newyear_libao_sign = dt[1]["libao_sign"] or 0
            
            if (db_date ~= sys_today) then
				user_info.newyear_play_count = 0
            else
            	user_info.newyear_play_count = dt[1]["play_count"] or 0
            
            end
  
    	else
			--TraceError("用户登陆后初始化数据,查询或更新数据库->失败")
    	end
    
    end)
end
 	
--检查有效时间，限时问题
function newyear_lib.check_datetime()
	local sys_time = os.time();
	
	--活动1时间
	--if(activ_type == 1)then
		local statime = timelib.db_to_lua_time(newyear_lib.activ1_statime);
		local endtime = timelib.db_to_lua_time(newyear_lib.activ1_endtime);
		local rank_endtime = timelib.db_to_lua_time(newyear_lib.rank_endtime);
		----TraceError("statime->"..statime.." endtime->"..endtime.." rank_endtime->"..rank_endtime.." sys_time->"..sys_time)
		if(sys_time >= statime and sys_time <= endtime) then
		    return 1;
		end
		
		if(sys_time > endtime and sys_time <= rank_endtime) then
			return 5; --整个活动结束后，排行榜图标保留1天后消失。
		end
	--end
 
	--活动时间过去了
	return 0;
end


--游戏结束采集盘数
newyear_lib.ongameover = function(user_info,addgold,player_count)
--活动一：年兽FUN礼
--[[
基本流程：
1、每天玩20盘得到鞭炮，德州VIP1-3（棋牌普通VIP、黄金VIP）获得鞭炮*2，德州VIP4-5（棋牌钻石VIP）获得鞭炮*3

2、每天玩够40盘得到烟花，德州VIP1-3（棋牌普通VIP、黄金VIP）获得烟花*2，德州VIP4-5（棋牌钻石VIP）获得烟花*3



5、显示持有武器的数量，格式为“鞭炮×1” 

6、鼠标移到武器上方，显示武器的TIPS,包括名称、描述、奖品、伤害
 
]]

 	--TraceError(play_count.." 游戏结束采集盘数,userId:"..user_info.userId)
	if not user_info or not user_info.desk or player_count < newyear_lib.player_count  then return end;
	 
	--活动一：时间有效性
	local check_time = newyear_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError(" 游戏结束采集盘数->时间有效性->if(check_time == 0 and check_time == 5)-- userid:"..user_info.userId)
        return;
    end
  
    --判断用户能开几次
    if(user_info.newyear_play_count > 40 )then 
		--TraceError(" 游戏结束采集盘数,> 40  userid:"..user_info.userId)
		return;    
    
    end    
 
    local play_count = user_info.newyear_play_count or 0
    --累加局数
    play_count = play_count + 1;
	--gamedata.playgameinfo.play_num = play_count;
	user_info.newyear_play_count = play_count
  
   --通知客户端
   newyear_lib.net_send_playnum(user_info, check_time, play_count);
   
   --如果玩20盘得到鞭炮，德州VIP1-3 获得鞭炮*2，德州VIP4-5 获得鞭炮*3
   --每天玩够40盘得到烟花，德州VIP1-3 获得烟花*2，德州VIP4-5 获得烟花*3
   	--发送鞭炮、烟花、礼炮等信息   	
   	local gun1_value = 0	--鞭炮
	local gun2_value = 0	--烟花
	local gun3_value = 0	--礼炮
	local vip_level = viplib.get_vip_level(user_info);
	
   	if(play_count == newyear_lib.play1_num)then	--满20盘
  		
  		gun2_value = user_info.propslist[5]	--烟花
	   	gun3_value = user_info.propslist[6]	--礼炮
	   	
	   	local complete_callback_func = function(tools_count)
       	 	gun1_value = user_info.propslist[4]	--鞭炮
	   	 	--TraceError(" 游戏结束采集盘数,= 20 --非VIP userid:"..user_info.userId.."鞭炮:"..gun1_value.."烟花:"..gun2_value.."礼炮"..gun3_value)
			newyear_lib.send_gun_info(user_info, gun1_value, gun2_value, gun3_value)
    	end
	   	
   		if(not viplib.check_user_vip(user_info))then	--非VIP
   			--加鞭炮
	      	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_1_ID, 1, user_info, complete_callback_func)
   		 
   		elseif(vip_level < 4)then  --VIP
   			--加鞭炮
	      	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_1_ID, 2, user_info, complete_callback_func)
   			 
   		elseif(vip_level == 4 or vip_level == 5)then  --VIP4、5
   			--加鞭炮
	      	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_1_ID, 3, user_info, complete_callback_func)
   		elseif(vip_level == 6) then
	   		tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_1_ID, 6, user_info, complete_callback_func)	 
   		end
   		 
	elseif(play_count == newyear_lib.play2_num)then	--满40盘
		gun1_value = user_info.propslist[4]	--鞭炮
	   	gun3_value = user_info.propslist[6]	--礼炮
	   	
	   	local complete_callback_func = function(tools_count)
       		gun2_value = user_info.propslist[5]	--烟花
	   		--TraceError(" 游戏结束采集盘数,= 40 --VIP4、5 userid:"..user_info.userId.." 鞭炮:"..gun1_value.." 烟花:"..gun2_value.." 礼炮"..gun3_value)
			newyear_lib.send_gun_info(user_info, gun1_value, gun2_value, gun3_value)
   		
    	end
    	
		if(not viplib.check_user_vip(user_info))then	--非VIP
  			--加烟花
	      	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_2_ID, 1, user_info, complete_callback_func)
	    
   		elseif(vip_level < 4)then  --VIP
  			--加烟花
	   	 	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_2_ID, 2, user_info, complete_callback_func)
   		elseif(vip_level == 4 or vip_level == 5 )then  --VIP4、5
  			--加烟花
	      	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_2_ID, 3, user_info, complete_callback_func)
	   	elseif(vip_level == 6) then
	   		tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_2_ID, 6, user_info, complete_callback_func)
   		end
   		
   	else
   		--TraceError(" 游戏结束采集盘数, userid:"..user_info.userId.." 鞭炮:"..gun1_value.." 烟花:"..gun2_value.." 礼炮"..gun3_value.." play_count:"..play_count)
   		gun1_value = user_info.propslist[4] or 0	--鞭炮
		gun2_value = user_info.propslist[5]	or 0	--烟花
		gun3_value = user_info.propslist[6]	or 0	--礼炮
   		 	
	end
	
	--记录到数据库
    local sqltemplet = "INSERT IGNORE INTO t_attack_monster_rank(user_id,user_nick) VALUE (%d,'%s');update t_attack_monster_rank set play_count = %d, gun1_attack_num = %d, gun2_attack_num = %d, gun3_attack_num = %d, sys_time = now() where user_id = %d;commit;";
    local sql=string.format(sqltemplet,user_info.userId,string.trans_str(user_info.nick), play_count, gun1_value,gun2_value,gun3_value,user_info.userId);
    dblib.execute(sql);
	
end

newyear_lib.autoNotifyClientForStart = function(min)
	local now_time = os.date("*t",os.time());
	local hd_start_time = os.date("*t",timelib.db_to_lua_time(newyear_lib.activ1_statime));
	
	if(now_time.year == hd_start_time.year and now_time.month == hd_start_time.month and now_time.day == hd_start_time.day and now_time.hour == hd_start_time.hour and min == hd_start_time.min ) then
		--通知客户端
		for k, v in pairs(userlist) do
   			newyear_lib.net_send_playnum(v, 1, 0);
   		end
	end
end

--定时刷新事件
newyear_lib.ontimecheck = function(e)
 
 	--检查并主动通知客户端活动上线
 	newyear_lib.autoNotifyClientForStart(e.data.min);
 	
  	--活动一：时间有效性
	local check_time = newyear_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
        return;
    end
  
  	
  	
  	--10分钟要刷一次排名 和  更新年兽数据
	if(newyear_lib.refresh_invate_time == -1 or os.time() > newyear_lib.refresh_invate_time+60*10)then
	--if(newyear_lib.refresh_invate_time == -1 or os.time() > newyear_lib.refresh_invate_time+10*1)then
		--TraceError("定时刷新事件，10分钟要刷一次排名 ");
    	newyear_lib.refresh_invate_time = os.time();
    	newyear_lib.init_attack_ph();
    	
    	--newyear_lib.sync_dragon_blood() --更新年兽数据
    	newyear_lib.read_dragon_blood()		--读取年兽生命值
    end
   
   local now_time = os.date("*t",os.time());
   if(now_time.hour == 0 and e.data.min == 0) then --每天凌晨活动局数清零
   		for k,v in pairs(userlist) do
   			newyear_lib.net_send_playnum(v,check_time,0);
   			v.newyear_play_count = 0;
   		end
   end
end

--请求年兽数据
function newyear_lib.on_recv_monster_info(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	
   	--TraceError("请求年兽数据,USERID:"..user_info.userId)
   
   	--活动一：时间有效性
	local check_time = newyear_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("请求年兽数据,时间过期， USERID:"..user_info.userId)
        return;
    end
     
    --通知用户,年兽状态
    local monster_now_value = newyear_lib.blood
	newyear_lib.send_monster_stat(user_info, 600000, monster_now_value)
	
end

--攻击年兽
function newyear_lib.on_recv_attack_monster(buf)
--[[
1、点击鞭炮、烟花、礼炮三种武器发动攻击，武器剩余数量-1
 

3、出现伤害值掉血数字动画，如“-13”，年兽总生命值相应减少

4、当前玩家随机获得所使用武器对应随机奖励，动画文字提示随机取一条“太给力了，获得600金币！”/“厉害，获得1万金币！”/“还不错，获得1万金币！”,3秒消失

5、获得1万金币/1万筹码以上的奖后系统广播，“XXXX袭击年兽，获得1万金币奖励！”

补充需求：

1、武器数量为0时候，武器为灰色不能点击

随机奖品： 
1.春节大赛参赛券 
2.200筹码 
3.1K筹码 
4.1万筹码 
5.5万筹码 
6.10万筹码 
7.20万筹码 
8.50万筹码 
9.100万筹码 
10.10经验药水 
11.小喇叭 
12.T卡 
13.福字（礼物） 
14.“红灯笼”礼物 
15.888万游艇
16.春节大赛参赛券 *5
17.T卡*2
18.小喇叭*3

]]	
	local _tosqlstr = function(s) 
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

	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	
   	--TraceError("攻击年兽,USERID:"..user_info.userId)
   
   	--活动一：时间有效性
	local check_time = newyear_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("攻击年兽,时间过期， USERID:"..user_info.userId)
    	newyear_lib.send_attack_monster_result(user_info, -1, -1)
        return;
    end
     
    --收到的攻击id
    local attack_id = buf:readByte();
    
	local gun1_value = user_info.propslist[4] or 0	--鞭炮
	local gun2_value = user_info.propslist[5] or 0	--烟花
	local gun3_value = user_info.propslist[6] or 0	--礼炮
  
  	local result = 0
  	local award_id = 0  --随机奖品ID
  	
  
    --鞭炮伤害：+1
	--烟花伤害：+3
	--礼炮伤害：+10
 
 	--TraceError("攻击年兽之前   newyear_lib.add_blood："..newyear_lib.add_blood.."  newyear_lib.blood:"..newyear_lib.blood.." attack_id:"..attack_id);
	local monster_life_value = newyear_lib.blood	--年兽生命值
	local attack_value = 0	--攻击值
	
	--随机生成奖品ID
	local function spring_gift(user_info, attack_id)
		 
        	local sql = format("call sp_get_random_spring_gift(%d, '%s', %d)", user_info.userId, "tex", attack_id)
        	dblib.execute(sql, function(dt)
            	if(dt and #dt > 0)then
            		local prizeid = dt[1]["gift_id"]
	               -- local award_name = dt[1]["gift_des"] or ""
	                --TraceError("攻击年兽,发奖，随机生成奖品ID:"..prizeid.." USERID:"..user_info.userId)
	                if(prizeid == nil or prizeid <= 0) then
	                	--TraceError("攻击年兽,发奖，随机生成奖品ID,失败")
	                    return 
	                end 
 	 
 					--发奖
		 			if(attack_id == 1)then
			   			--转换对应奖品ID
			            if(prizeid == 1)then	--200筹码
			            	award_id = 2	
			            	--加200筹码
			  				usermgr.addgold(user_info.userId, 200, 0, g_GoldType.baoxiang, -1);
			  				
			            elseif(prizeid == 2)then	--1K筹码
			            	award_id = 3	
			            	--加1K筹码
			  				usermgr.addgold(user_info.userId, 1000, 0, g_GoldType.baoxiang, -1);
			  				
			            elseif(prizeid == 3)then	--春节大赛参赛券 
			            	award_id = 1	
			            	--加春节大赛参赛券 
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.NewYearTickets_ID, 1, user_info)
			  	
			            elseif(prizeid == 4)then	--小喇叭
			            	award_id = 11	
			            	--小喇叭怎么加
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, user_info)
			  	
			            elseif(prizeid == 5)then	--“福”礼物
			            	award_id = 13	
			            	--加“福”礼物
			  				gift_addgiftitem(user_info,9014,user_info.userId,user_info.nick, false)
			  				
			            elseif(prizeid == 6)then	--5万筹码
			            	award_id = 5
			            	--加5万筹码
			  				usermgr.addgold(user_info.userId, 50000, 0, g_GoldType.baoxiang, -1);
			  				
			  				--系统广播，“XXXX袭击年兽，获得***万奖励！”
			  				local user_nick=user_info.nick
							user_nick=_tosqlstr(user_nick).."   "
							local msg = tex_lan.get_msg(user_info, "newyear_activity_msg_awards_1"); 
							local msg1 = tex_lan.get_msg(user_info, "lz_activity_msg_awards"); 
							msg1 = string.format(msg1,5); 
							BroadcastMsg(_U(msg)..user_nick.._U(msg1),0)
			  				
			  			elseif(prizeid == 0)then	--异常
			  				--TraceError("攻击年兽,发奖，随机生成奖品ID,失败--异常 USERID:"..user_info.userId)
			  				return
			            end	
			        elseif(attack_id == 2)then
			        	--转换对应奖品ID
			            if(prizeid == 1)then	--1K筹码
			            	award_id = 3	
			            	--加1K筹码
			  				usermgr.addgold(user_info.userId, 1000, 0, g_GoldType.baoxiang, -1);
			  				
			            elseif(prizeid == 2)then	--1W筹码
			            	award_id = 4	
			            	--加1W筹码
			  				usermgr.addgold(user_info.userId, 10000, 0, g_GoldType.baoxiang, -1);
			  				
			            elseif(prizeid == 3)then	--春节大赛参赛券 
			            	award_id = 1	
			            	--加春节大赛参赛券 
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.NewYearTickets_ID, 1, user_info)
			  	
			            elseif(prizeid == 4)then	--T人卡
			            	award_id = 12
			            	--T人卡怎么加
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 1, user_info)
			  	
			            elseif(prizeid == 5)then	--“红灯笼”礼物
			            	award_id = 14
			            	--加“红灯笼”礼物
			  				gift_addgiftitem(user_info,9015,user_info.userId,user_info.nick, false)
			  				
			            elseif(prizeid == 6)then	--50万筹码
			            	award_id = 8
			            	--加50万筹码
			  				usermgr.addgold(user_info.userId, 500000, 0, g_GoldType.baoxiang, -1);
			  				local user_nick=user_info.nick
							user_nick=_tosqlstr(user_nick).."   "
							local msg = tex_lan.get_msg(user_info, "newyear_activity_msg_awards_1");
							local msg1 = tex_lan.get_msg(user_info, "lz_activity_msg_awards"); 
							msg1 = string.format(msg1,50); 
							BroadcastMsg(_U(msg)..user_nick.._U(msg1),0)
			  				
			  			elseif(prizeid == 0)then	--异常
			  				--TraceError("攻击年兽,发奖，随机生成奖品ID,失败--异常 USERID:"..user_info.userId)
			  				return
			            end	
			   		elseif(attack_id == 3)then
			   			--转换对应奖品ID
			            if(prizeid == 1)then	--春节大赛参赛券 
			            	award_id = 16  --16.春节大赛参赛券 *5  	
			            	--加春节大赛参赛券 
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.NewYearTickets_ID, 5, user_info)
			          
			            elseif(prizeid == 2)then	--5万筹码
			            	award_id = 5	
			            	--加5万筹码
			  				usermgr.addgold(user_info.userId, 50000, 0, g_GoldType.baoxiang, -1);
			  				
			  				--系统广播，“XXXX袭击年兽，获得***万奖励！”
			  				local user_nick = user_info.nick
							user_nick=_tosqlstr(user_nick).."   "
			  				local msg = tex_lan.get_msg(user_info, "newyear_activity_msg_awards_1"); 
							local msg1 = tex_lan.get_msg(user_info, "lz_activity_msg_awards"); 
							msg1 = string.format(msg1,5); 
							BroadcastMsg(_U(msg)..user_nick.._U(msg1),0)
			  				 
			            elseif(prizeid == 3)then	--20万筹码
			            	award_id = 7	
			            	--加20万筹码
			  				usermgr.addgold(user_info.userId, 200000, 0, g_GoldType.baoxiang, -1);
			  				
			  				--系统广播，“XXXX袭击年兽，获得***万奖励！”
			  				local user_nick = user_info.nick
							user_nick=_tosqlstr(user_nick).."   "
							local msg = tex_lan.get_msg(user_info, "newyear_activity_msg_awards_1"); 
							local msg1 = tex_lan.get_msg(user_info, "lz_activity_msg_awards"); 
							msg1 = string.format(msg1,20); 
							BroadcastMsg(_U(msg)..user_nick.._U(msg1),0)
			  	
			  			elseif(prizeid == 4)then	--100万筹码
			            	award_id = 9	
			            	--加100万筹码
			  				usermgr.addgold(user_info.userId, 1000000, 0, g_GoldType.baoxiang, -1);
			  				
			  				--系统广播，“XXXX袭击年兽，获得***万奖励！”
			  				local user_nick = user_info.nick
							user_nick=_tosqlstr(user_nick).."   "
							local msg = tex_lan.get_msg(user_info, "newyear_activity_msg_awards_1"); 
							local msg1 = tex_lan.get_msg(user_info, "lz_activity_msg_awards"); 
							msg1 = string.format(msg1,100); 
							BroadcastMsg(_U(msg)..user_nick.._U(msg1),0)
			  				
			  			elseif(prizeid == 5)then	--加游艇
			            	award_id = 15	
			            	--加游艇
							gift_addgiftitem(user_info,5023,user_info.userId,user_info.nick, false)	
							local user_nick=user_info.nick
							user_nick=_tosqlstr(user_nick).."   "
							local msg = tex_lan.get_msg(user_info, "newyear_activity_msg_awards_1");
							local msg1 = tex_lan.get_msg(user_info, "lz_activity_msg_awards1"); 
							BroadcastMsg(_U(msg)..user_nick.._U(msg1),0)
						elseif(prizeid == 6)then	--T人卡
			            	award_id = 17	--17.T卡*2
			            	--T人卡怎么加
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 2, user_info)
			 
			            elseif(prizeid == 7)then	--小喇叭
			            	award_id = 18		--18.小喇叭*3
			            	--小喇叭怎么加
			  				tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 3, user_info)
			  	 
			  			elseif(prizeid == 0)then	--异常
			  				--TraceError("攻击年兽,发奖，随机生成奖品ID,失败--异常 USERID:"..user_info.userId)
			  				return
			            end	
				    end
				   
				   --发送攻击年兽成功结果
			    	result = attack_value
			    	--TraceError("攻击年兽成功,--， USERID:"..user_info.userId.." result:"..result.." award_id:"..award_id.." monster_life_value:"..monster_life_value.." gun1_value:"..gun1_value.." gun2_value:"..gun2_value.." gun3_value:"..gun3_value.." attack_id:"..attack_id)
					newyear_lib.send_attack_monster_result(user_info, result, award_id)
					
					--通知客户端，更新鞭炮、烟花、礼炮等信息
 					newyear_lib.send_gun_info(user_info, gun1_value, gun2_value, gun3_value)
	            end
	        end)
	   
	end
  	
   	if(attack_id == 1)then	--鞭炮
   		
   		if(gun1_value > 0)then
   			attack_value = 1	--鞭炮伤害：+1
   			
   			--更新年兽生命值
   			monster_life_value = monster_life_value - attack_value	  
   			newyear_lib.blood = newyear_lib.blood - attack_value
   			if(monster_life_value <= 0)then
   				monster_life_value = 0
   			end
   			if(newyear_lib.blood <= 0)then
   				newyear_lib.blood = 0
   			end
   			newyear_lib.write_dragon_blood(monster_life_value)	--写数据库
   			
   			--更新用户攻击值
   			user_info.newyear_attack_value = user_info.newyear_attack_value + attack_value
 
   			--减鞭炮
   			gun1_value = gun1_value -1
   			user_info.propslist[4] = gun1_value
   			
   			local complete_callback_func = function(tools_count)
      			--随机生成奖品ID
   				spring_gift(user_info, attack_id)
    		end
   			tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_1_ID, -1, user_info, complete_callback_func)
     
   		else
   			--TraceError("攻击年兽,--鞭炮不足， USERID:"..user_info.userId)
   			--发送攻击年兽失败结果
	    	result = 0
	    	award_id = -1
			newyear_lib.send_attack_monster_result(user_info, result, award_id)
	        return;
   		end
       
    elseif(attack_id == 2)then	--烟花
    
    	if(gun2_value > 0)then
   			attack_value = 3	--烟花伤害：+3
   			
   			--更新年兽生命值
   			monster_life_value = monster_life_value - attack_value	  
   			newyear_lib.blood = newyear_lib.blood - attack_value
   			if(monster_life_value <= 0)then
   				monster_life_value = 0
   			end
   			if(newyear_lib.blood <= 0)then
   				newyear_lib.blood = 0
   			end
   			newyear_lib.write_dragon_blood(monster_life_value)	--写数据库	
   			
   			--更新用户攻击值
   			user_info.newyear_attack_value = user_info.newyear_attack_value + attack_value
 
   			--减烟花
   			gun2_value = gun2_value -1
   			user_info.propslist[5] = gun2_value
   			
   			local complete_callback_func = function(tools_count)
      	 		--随机生成奖品ID
   				spring_gift(user_info, attack_id)
   			end
   			tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_2_ID, -1, user_info, complete_callback_func)
     
   		else
   			--TraceError("攻击年兽,--烟花不足， USERID:"..user_info.userId)
   			--发送攻击年兽失败结果
	    	result = 0
	    	award_id = -1
			newyear_lib.send_attack_monster_result(user_info, result, award_id)
	        return;
   		end
    elseif(attack_id == 3)then	--礼炮
    	if(gun3_value > 0)then
   			attack_value = 10	--礼炮伤害：+10
   			 
   			--更新年兽生命值
   			monster_life_value = monster_life_value - attack_value	  
   			newyear_lib.blood = newyear_lib.blood - attack_value
   			if(monster_life_value <= 0)then
   				monster_life_value = 0
   			end
   			if(newyear_lib.blood <= 0)then
   				newyear_lib.blood = 0
   			end
   			newyear_lib.write_dragon_blood(monster_life_value)	--写数据库
   			
   			--更新用户攻击值
   			user_info.newyear_attack_value = user_info.newyear_attack_value + attack_value
 
   			--减礼炮
   			gun3_value = gun3_value -1
   			user_info.propslist[6] = gun3_value
   			
   			local complete_callback_func = function(tools_count)
      	 		--随机生成奖品ID
   				spring_gift(user_info, attack_id)
	 
    		end
   			tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_3_ID, -1, user_info, complete_callback_func)
     
   		else
   			--TraceError("攻击年兽,--礼炮不足， USERID:"..user_info.userId)
   			--发送攻击年兽失败结果
	    	result = 0
	    	award_id = -1
			newyear_lib.send_attack_monster_result(user_info, result, award_id)
	        return;
   		end
    else
    	
    	--TraceError("攻击年兽，收到错误的攻击id");
    	--发送攻击年兽结果
    	result = 0
    	award_id = -1
		newyear_lib.send_attack_monster_result(user_info, result, award_id)
        return;
   	end
   
   	--TraceError("攻击年兽结果   newyear_lib.add_blood："..newyear_lib.add_blood.."  newyear_lib.blood:"..newyear_lib.blood.." newyear_attack_value:"..user_info.newyear_attack_value);
 
	--更新攻击,武器数据
    local sqltemplet = "update t_attack_monster_rank set attack_value = %d, gun1_attack_num = %d, gun2_attack_num = %d, gun3_attack_num = %d where user_id = %d;commit;";
    local sql=string.format(sqltemplet, user_info.newyear_attack_value, gun1_value,gun2_value,gun3_value,user_info.userId);
    dblib.execute(sql);
 	
 	newyear_lib.send_my_hurt(user_info,user_info.newyear_attack_value);
end

--初始化排行榜
function newyear_lib.init_attack_ph()
--[[
查看伤害排名

基本流程：
1、在年兽旁显示前50名玩家的伤害排名

2、排名标签为 排名、昵称（支持最多16字符）、伤害值（支持6位数字）、奖励（最多10个字符）

4、在排名下方显示自己伤害值、排名、应得奖励奖励

 4.1 上榜，显示为“第X名”

 4.2 没上榜，显示为“未上榜”

 4.3 有奖励，取前50名奖励

 4.4 无奖励，显示“无”

补充需求：

1、伤害值=燃放烟花数量*20+燃放鞭炮数量*10+燃放礼炮数量*100

2、同伤害按时间排

3、前50名奖励在活动结束后人工发放

4、排名10分钟更新1次


]]
 
	--TraceError("-->>>>初始化排行榜")
 
	--初始化排行
	
	local sql="select user_id,user_nick,attack_value from t_attack_monster_rank where attack_value >= 1 order by attack_value desc LIMIT 50"
	sql=string.format(sql)
	dblib.execute(sql,function(dt)	
			if(dt~=nil and  #dt>0)then
				newyear_lib.attack_ph_list = {}
				for i=1,#dt do
					local bufftable ={
					  	    mingci = i, 
		                    user_id = dt[i].user_id,
		                    nick_name=dt[i].user_nick,
		                    attack_value=dt[i].attack_value,   
	                }	                
					table.insert(newyear_lib.attack_ph_list,bufftable)
				end
			end
    end)
   
    
    --初始化攻击年兽排名
    --init_ph(newyear_lib.attack_ph_list)
 
end

--请求排行榜
function newyear_lib.on_recv_attack_ph_list(buf)
	local user_info = userlist[getuserid(buf)]; 
	if not user_info then return end;
	--TraceError("--请求排行榜,userid:"..user_info.userId)
 
   	--活动一：时间有效性
	local check_time = newyear_lib.check_datetime()
    if(check_time == 0) then
    	--TraceError("请求排行榜,时间过期， USERID:"..user_info.userId)
        return;
    end
 
	local mc = -1; --用于记下自己的名次
	local attack_value = 0; --用于记下自己的攻击成绩
 
	local attack_paimin_list = newyear_lib.attack_ph_list
	
	if(user_info == nil)then return end
	
	--查询自己的名次，如果没有名次就返回-1
	--返回名次，我的攻击成绩
	local my_mc = -1;
	local my_attack_value = 0;
 
	--找自己的排行榜
	my_mc,my_attack_value = newyear_lib.get_my_pm(attack_paimin_list,user_info)
	
	local libao_sign = user_info.newyear_libao_sign		----是否领取了“驱魔礼包”标记
 
 	--发送排行榜
	newyear_lib.send_ph_list(user_info, libao_sign, my_attack_value, my_mc, attack_paimin_list)  
end

--找自己的排行榜
newyear_lib.get_my_pm = function(ph_list,user_info)

		local mc=-1
		if (ph_list==nil) then return -1,0 end
		
		for i=1,#ph_list do
			if(ph_list[i].user_id==user_info.userId)then
				return i,ph_list[i].attack_value
			end
		end

		return -1,0;--没有找到对应玩家的记录，认为他没有成绩
end

--请求活动时间状态
function newyear_lib.on_recv_activity_stat(buf)
	
	local user_info = userlist[getuserid(buf)]; 
	if(user_info == nil)then return end
 
	--活动一：时间有效性
	local check_time = newyear_lib.check_datetime()
	
	--TraceError("--请求活动时间状态-->>"..check_time)
	
	if(check_time == 0)then
		return
	end
	
	--判断是否有武器
	local gun1_value = user_info.propslist[4] or 0	--鞭炮
	local gun2_value = user_info.propslist[5] or 0	--烟花
	local gun3_value = user_info.propslist[6] or 0	--礼炮
	if(gun1_value > 0 or gun2_value > 0 or gun3_value >0)then
		check_time = 2;		--活动有效,有武器
	end
	
	local play_count = 0
	--用户盘数
    if(user_info.newyear_play_count == nil)then
    	user_info.newyear_play_count = 0	
    	play_count = 0
    else
    	play_count = user_info.newyear_play_count
    end
 
 	--通知客户端
   newyear_lib.net_send_playnum(user_info, check_time, play_count);
  
end

--请求打开活动面板
function newyear_lib.on_recv_activation(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	
   	local _tosqlstr = function(s) 
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
	
   	--TraceError("请求打开活动面板,USERID:"..user_info.userId)
   
   	--活动一：时间有效性
	local check_time = newyear_lib.check_datetime()
    if(check_time ~= 1 and check_time ~= 5) then
    	--TraceError("请求打开活动面板,时间过期， USERID:"..user_info.userId)
        return;
    end
    
    --初始化或更新攻击表
 	
	local user_nick=user_info.nick
	user_nick=_tosqlstr(user_nick)
	local sql = "insert ignore into t_attack_monster_rank (user_id, user_nick, attack_value) ";
    sql = sql.."values(%d, '%s   ', %d);commit;";   
    sql = string.format(sql, user_info.userId, user_nick, 0);
	dblib.execute(sql)
	
	--通知用户,年兽状态
	local monster_now_value = newyear_lib.blood	--年兽生命值
	newyear_lib.send_monster_stat(user_info, 600000, monster_now_value)
	
	--发送用户鞭炮、烟花、礼炮等信息
	local gun1_value = user_info.propslist[4] or 0	--鞭炮
	local gun2_value = user_info.propslist[5] or 0	--烟花
	local gun3_value = user_info.propslist[6] or 0	--礼炮
	newyear_lib.send_gun_info(user_info, gun1_value, gun2_value, gun3_value)
	
	
	--发送排行榜
	--找自己的排行榜
	local attack_paimin_list = newyear_lib.attack_ph_list	--排行榜数组
	local my_mc = -1;
	local my_attack_value = 0;
	my_mc,my_attack_value = newyear_lib.get_my_pm(attack_paimin_list,user_info)
	local libao_sign = user_info.newyear_libao_sign		----是否领取了“驱魔礼包”标记
	newyear_lib.send_ph_list(user_info, libao_sign, user_info.newyear_attack_value or my_attack_value, my_mc, attack_paimin_list)
	
	--查询或更新自己数据
	newyear_lib.query_db(user_info)
end

--购买礼炮
function newyear_lib.on_recv_buy_fire(buf)
--[[
3、礼炮需要用游戏币直接购买，点击礼炮旁的【购买】按钮购买

   3.1 钱够，按钮上方文字动画提示“购买成功，获得礼炮*1，消耗10000筹码”

   3.2 钱不够，按钮为灰色，鼠标移上去TIP显示“金币不足”/“筹码不足”

   3.3 德州使用牌桌外的筹码购买； 在牌桌中不能购买，购买按钮为灰色，鼠标移上去TIP显示“请退出牌桌后购买”
 
  ]]
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	
   	--TraceError("购买礼炮,USERID:"..user_info.userId)
   	
   	local gun3_value = 0
 	local result = 0
    local gold = get_canuse_gold(user_info)--获得用户筹码

	gun3_value = user_info.propslist[6]	--礼炮
	
   	--活动一：时间有效性
	local check_time = newyear_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("购买礼炮,时间过期， USERID:"..user_info.userId)
    	
    	--发送购买礼炮结果
    	result = 2
		newyear_lib.send_buy_gun_result(user_info, gun3_value, result)
        return;
    end
 
    if(gold < 100000)then
    	--TraceError("购买礼炮,钱不够， USERID:"..user_info.userId)
    	
    	--发送购买礼炮结果
    	result = 0
		newyear_lib.send_buy_gun_result(user_info, gun3_value, result)
    	return
    end
    
    --减筹码
	usermgr.addgold(user_info.userId, -100000, 0, g_GoldType.baoxiang, -1);
	
	--加礼炮
	local complete_callback_func = function(tools_count)
      	--发送购买礼炮结果
		gun3_value = user_info.propslist[6]	--礼炮
		result = 1
		newyear_lib.send_buy_gun_result(user_info, gun3_value, result)
	 
    end
    
	tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.GUN_3_ID, 1, user_info, complete_callback_func)
	
	
end

--通知客户端，返回鞭炮、烟花、礼炮等信息
function newyear_lib.on_recv_gun_info(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	
   	--TraceError("返回鞭炮、烟花、礼炮等信息,USERID:"..user_info.userId)
   
   	--活动一：时间有效性
	local check_time = newyear_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("返回鞭炮、烟花、礼炮等信息,时间过期， USERID:"..user_info.userId)
        return;
    end
    
    --发送用户鞭炮、烟花、礼炮等信息
	local gun1_value = user_info.propslist[4]	--鞭炮
	local gun2_value = user_info.propslist[5]	--烟花
	local gun3_value = user_info.propslist[6]	--礼炮
	newyear_lib.send_gun_info(user_info, gun1_value, gun2_value, gun3_value)
 
end

--通知服务端，请求领取“驱魔礼包”
function newyear_lib.on_recv_exorcist_packs(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	
   	--TraceError("请求领取“驱魔礼包”,USERID:"..user_info.userId)
   
   	--活动一：时间有效性
	local check_time = newyear_lib.check_datetime()
    if(check_time == 0 or check_time == 5) then
    	--TraceError("请求领取“驱魔礼包”,时间过期， USERID:"..user_info.userId)
        return;
    end
    
    if(user_info.newyear_libao_sign == 1)then
    	--TraceError("请求领取“驱魔礼包”,已领过， USERID:"..user_info.userId)
    	return
    end
    
    local attack_value = user_info.newyear_attack_value
    local result = 0
    
    --我的攻击值大于300时可领取驱魔礼包
    if(attack_value > 300)then
    	--TraceError("请求领取“驱魔礼包” 领取成功,USERID:"..user_info.userId.." attack_value:"..attack_value)
    	--标记领取
	    user_info.newyear_libao_sign = 1
	    
	    --更新数据库
	    local sqltemplet = "update t_attack_monster_rank set libao_sign = 1 where user_id = %d;commit;";             
		dblib.execute(string.format(sqltemplet, user_info.userId))
		
		--加获得10万金币
		usermgr.addgold(user_info.userId, 100000, 0, g_GoldType.baoxiang, -1);
	 
		--发送请求领取“驱魔礼包”结果
		result = 1
    	newyear_lib.send_exorcist_packs_result(user_info, result)
    	
    	--系统广播，“XXXX领取驱魔礼包，获得10万金币！”
		local msg = tex_lan.get_msg(user_info, "newyear_activity_msg_awards_1"); 
		local msg1=tex_lan.get_msg(user_info, "newyear_activity_msg"); 
		msg1 = string.format(msg1); 
		BroadcastMsg(_U(msg)..user_info.nick.._U(msg1),0)
    else
    	--TraceError("请求领取“驱魔礼包” 失败,USERID:"..user_info.userId.." attack_value:"..attack_value)
    	--发送请求领取“驱魔礼包”结果
    	newyear_lib.send_exorcist_packs_result(user_info, result)
    end
   
end


--发送盘数和时间状态
newyear_lib.net_send_playnum = function(user_info, check_time, play_count)
  	--TraceError(" 发送盘数和时间状态,userid:"..user_info.userId.." check_time->"..check_time.." play_count:"..play_count)
	netlib.send(function(buf)
	    buf:writeString("HDNYNSDATE")
	    buf:writeByte(check_time)	 --0，活动无效（服务端也可不发）；1，活动有效；5，活动结束，保留一天
	    buf:writeInt(play_count)	--玩家玩的盘数
	    end,user_info.ip,user_info.port) 
end
 
--发送攻击年兽结果
function newyear_lib.send_attack_monster_result(user_info, result, award_id)
	--TraceError("发送攻击年兽结果，userid:"..user_info.userId.." result:"..result.." award_id:"..award_id);
	netlib.send(function(buf)
            buf:writeString("HDNYNSKILL");
            buf:writeInt(result);
            buf:writeInt(award_id);
        end,user_info.ip,user_info.port);
end
 
--发送排行榜
function newyear_lib.send_ph_list(user_info, libao_sign, my_attack_value, my_mc, attack_paimin_list)
	--TraceError("发送排行榜，libao_sign:"..libao_sign.." my_attack_value"..my_attack_value.." my_mc:"..my_mc.." attack_paimin_list...")
	--TraceError(attack_paimin_list)
	local send_len=50;--默认发50条信息
	netlib.send(function(buf)
    	buf:writeString("HDNYNSLIST")
    	buf:writeByte(libao_sign or 0)		--是否领取了“驱魔礼包”：0，未领取；1，已领取；
	    buf:writeInt(my_attack_value or 0)	--我造成的伤害
	    buf:writeInt(my_mc or 0)	--我的排名
 
		if send_len>#attack_paimin_list then send_len=#attack_paimin_list end --最多发50条信息
		--TraceError("发送排行榜，send_len:"..send_len)
		
		 buf:writeInt(send_len)
			--再发其他人的
	        for i=1,send_len do
		        buf:writeInt(attack_paimin_list[i].mingci)	--名次
		        buf:writeInt(attack_paimin_list[i].user_id) --玩家ID
		        buf:writeString(attack_paimin_list[i].nick_name) --昵称
		        buf:writeInt(attack_paimin_list[i].attack_value) --玩家攻击成绩
              
	        end
     	end,user_info.ip,user_info.port) 
end
 
--发送年兽状态
function newyear_lib.send_monster_stat(user_info, monster_value, monster_now_value)
	--TraceError("发送年兽状态， USERID:"..user_info.userId.." monster_value:"..monster_value.." monster_now_value:"..monster_now_value)
	netlib.send(function(buf)
            buf:writeString("HDNYNSBLOOD");
            buf:writeInt(monster_value);		--年兽总血量
            buf:writeInt(monster_now_value);		--年兽当前血量
        end,user_info.ip,user_info.port);
end
 

--发送购买礼炮结果
function newyear_lib.send_buy_gun_result(user_info, gun3_value, result)
	--TraceError("发送购买礼炮结果,USERID:"..user_info.userId.." gun3_value:"..gun3_value.." result"..result)
	netlib.send(function(buf)
            buf:writeString("HDNYNSBUYLP");
            buf:writeInt(result);		--0，购买失败，筹码不足；1，购买成功；2，购买失败，活动已过期；3，购买失败，其它原因；
            buf:writeInt(gun3_value);		--礼炮的数量
        end,user_info.ip,user_info.port);
end


--发送鞭炮、烟花、礼炮等信息
function newyear_lib.send_gun_info(user_info, gun1_value, gun2_value, gun3_value)
	  --TraceError("发送鞭炮、烟花、礼炮等信息,USERID:"..user_info.userId.." gun1_value:"..gun1_value.." gun2_value:"..gun2_value.." gun3_value:"..gun3_value)
	  netlib.send(function(buf)
            buf:writeString("HDNYNSVALUE");
            buf:writeInt(gun1_value);		--鞭炮数量
            buf:writeInt(gun2_value);		--烟花数量
            buf:writeInt(gun3_value);		--礼炮数量
        end,user_info.ip,user_info.port);
end
 
--发送请求领取“驱魔礼包”结果
function newyear_lib.send_exorcist_packs_result(user_info, result)
	--TraceError("发送请求领取“驱魔礼包”结果,USERID:"..user_info.userId.." result:"..result)
	 netlib.send(function(buf)
            buf:writeString("HDNYNSGIFTEX");
            buf:writeByte(result);		--0，领取失败，未达到伤害条件；1，领取成功；2，已领取；3，领取失败，其它原因；
        end,user_info.ip,user_info.port);
end

--发送我的伤害
function newyear_lib.send_my_hurt(user_info, hurt)
	 netlib.send(function(buf)
            buf:writeString("HDNYNSMH");
            buf:writeInt(hurt);
        end,user_info.ip,user_info.port);
end


--协议命令
cmd_tex_match_handler = 
{
	["HDNYNSDATE"] = newyear_lib.on_recv_activity_stat, --请求活动时间状态
    ["HDNYNSPANEL"] = newyear_lib.on_recv_activation, -- 请求打开活动面板
    ["HDNYNSLIST"] = newyear_lib.on_recv_attack_ph_list, -- --请求攻击年兽排行榜 
    ["HDNYNSBLOOD"] = newyear_lib.on_recv_monster_info, -- 请求更新年兽数据
    ["HDNYNSVALUE"] = newyear_lib.on_recv_gun_info, 	--通知客户端，返回鞭炮、烟花、礼炮等信息
    ["HDNYNSKILL"] = newyear_lib.on_recv_attack_monster, -- 攻击年兽/驱赶年兽 
    ["HDNYNSBUYLP"] = newyear_lib.on_recv_buy_fire,--购买礼炮
    ["HDNYNSGIFTEX"] = newyear_lib.on_recv_exorcist_packs ,--通知服务端，请求领取“驱魔礼包”
  
}

--加载插件的回调
for k, v in pairs(cmd_tex_match_handler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("h2_on_user_login", newyear_lib.on_after_user_login);
eventmgr:addEventListener("timer_minute", newyear_lib.ontimecheck);