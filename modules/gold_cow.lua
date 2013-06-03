TraceError("init gold_cow_lib...")

if gold_cow_lib and gold_cow_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", gold_cow_lib.on_after_user_login);
end

if gold_cow_lib and gold_cow_lib.timer then
	eventmgr:removeEventListener("timer_second", gold_cow_lib.timer);
end

if gold_cow_lib and gold_cow_lib.restart_server then
	eventmgr:removeEventListener("on_server_start", gold_cow_lib.restart_server);
end


if gold_cow_lib and gold_cow_lib.on_game_over then
	eventmgr:removeEventListener("game_event", gold_cow_lib.on_game_over);
end

if not gold_cow_lib then
    gold_cow_lib = _S
    {    	   
        on_after_user_login = NULL_FUNC,--登陆后做的事
		check_datetime  = NULL_FUNC,	--检查有效时间，限时问题
		on_recv_query_time = NULL_FUNC, --客户端检查剩余时间
        on_recv_check_status = NULL_FUNC, --通知服务端，请求活动状态
        on_recv_open_game = NULL_FUNC, --请求服务端，请求打开面板信息
        send_remain_time = NULL_FUNC, --计算差多少秒开奖
        update_bet_info = NULL_FUNC, --更新投注信息
        on_recv_xiazhu = NULL_FUNC, --客户端通知下注
        send_caichi=NULL_FUNC, --发给客户端彩池的信息
        add_caichi=NULL_FUNC, --加彩池
        on_game_over = NULL_FUNC,                   --结算事件
        --计算赚的金牛游戏币
        get_random_num = NULL_FUNC, --生成随机数
        get_card_num=NULL_FUNC, --得到6张牌
        set_user_cowgold_info = NULL_FUNC, --设置玩家小游戏的一些游戏，一般是给数据层调用
        start_game = NULL_FUNC, --开始游戏
        timer = NULL_FUNC, --定时器
        send_other_bet_info = NULL_FUNC, --发其他人的投注信息
        send_history = NULL_FUNC, --发送历史记录
        gm_open_num = NULL_FUNC, --开指定的号
        on_recv_gm_num = NULL_FUNC, --客户端通知开指定的号
        update_pl=NULL_FUNC,	--计算新的赔率
        init_poke_box=NULL_FUNC, --初始化牌盒
        get_one_poke=NULL_FUNC,  --从牌盒中拿一张牌
        send_is_finish=NULL_FUNC, --发给客户端，是不是打够15盘，可以玩这个小游戏了
        send_gold_change=NULL_FUNC, --发给客户端新的可用的囧人币
        change_safebox_gold=NULL_FUNC, --改保险箱在内存里的钱
        is_valid_room = NULL_FUNC,
   		--游戏配置:
   		num1 = 0,	--第1张牌
		num2 = 0,	--第2张牌
		num3 = 0,	--第3张牌
		num4 = 0,   --第4张牌
		num5 = 0,   --第5张牌
		num6 = 0,   --第6张牌
		
		zhongjiang_num = 0, --中奖的位置
		gm_num = 0, --gm开指定的位置
		
		history = {},	--历史骰子
		history_len = 11,	--历史骰子长度

		total_num = 0,	--骰子相加结果
	
		limit_bet = 100000,	--个人总下注上限
		tex_limit_bet = 10000,--个人总下注上限
		
		limit_local_bet = 100000,	--区域下注上限  1000
		day_count_bet = 10000,	--个人每日下注总量  10000 次(每十分钟才开一次，不可能到10000次，所以这个变量应该是没用的）


		--下注时间 10分钟
		startime = "2012-04-27 08:00:00",  --活动开始时间
    	endtime = "2012-05-11 00:00:00",  --活动结束时间
		fajiang_time = 0,  --本局发奖时间
		other_bet_time = 0, --其他玩家下注信息
		bet_id = "-1", --本局的ID
		
		all_user_bet_info={}, --所有玩家下注信息
		user_list={}, --玩抓金牛小游戏的玩家
		poke_box={}, --牌盒
		
		--赔率配置表
		bet_peilv = {
			[1]=12,          
			[2]=6,        
			[3]=3,         
			[4]=3,         
			[5]=6,           
			[6]=12,           
		},
		
		--总设注
		all_bet_count=0,
		
		--分区域投注信息
		bet_count={
			[1]=0,          
			[2]=0,        
			[3]=0,         
			[4]=0,         
			[5]=0,           
			[6]=0,           
		},		

		cfg_game_name = {      --游戏配置 
		    ["soha"] = "soha",
		    ["cow"] = "cow",
		    ["zysz"] = "zysz",
		    ["mj"] = "mj",
		    ["tex"] = "tex",
		},
		
		qp_game_room = 4031, --因为只能在一个房间上
		tex_game_room = 18001, --因为只能在一个房间上
		
		tex_gm_id_arr = {}, -- {'832791'},
		qp_gm_id_arr = {}, --{'19563389'},
		org_bet_info="0,0,0,0,0,0", --默认投注信息
		
		caichi=0, --彩池
		CFG_CAN_PLAY=15,    --用来决定大家能不能玩抓金牛
		CFG_CANT_BETTIME=10, --停止下注时间 10秒
		CFG_BET_RATE=1000, --一千块一注
		CFG_REWARD_COWGAMEGOLD=1, --每天送1注
		
    }    
end

--gm开指定的号
gold_cow_lib.gm_open_num=function(num)
	gold_cow_lib.gm_num=num
end

gold_cow_lib.is_valid_room=function()
	if(gamepkg.name == "tex" and gold_cow_lib.tex_game_room ~= tonumber(groupinfo.groupid))then
		return 0
	end
	if(gamepkg.name ~= "tex" and gold_cow_lib.qp_game_room ~= tonumber(groupinfo.groupid))then
		return 0
	end
	return 1
end

--游戏结束事件处理
gold_cow_lib.on_game_over = function(gameeventdata)
    if gold_cow_lib.check_datetime() == 0 then return end
    if gameeventdata == nil then return end
    --游戏事件验证
    if gold_cow_lib.cfg_game_name[gamepkg.name] == nil then return end
    --遍历所有用户
    for k,v in pairs(gameeventdata.data) do
        --游戏开始事件 退出
        if (gamepkg.name ~= "cow" or gamepkg.name ~= "tlj") and v.single_event == 1 then
            break;
        else
        	--当天玩的第一盘
        	--改时间，改盘数为1
        	if(gold_cow_lib.user_list[v.userid]==nil) then gold_cow_lib.user_list[v.userid]={} end
        	if(gold_cow_lib.user_list[v.userid].lastplay_date ~= os.date("%Y-%m-%d", curr_time))then
        		gold_cow_lib.user_list[v.userid].lastplay_date = os.date("%Y-%m-%d", curr_time)
        		if(gold_cow_lib.user_list[v.userid].cowgamegold_rewardcount==0 and gold_cow_lib.user_list[v.userid].play_count>=15)then
        			gold_cow_lib.user_list[v.userid].play_count=1
        		else
        			gold_cow_lib.user_list[v.userid].play_count=gold_cow_lib.user_list[v.userid].play_count+1;
        		end
        	else
        		gold_cow_lib.user_list[v.userid].play_count=gold_cow_lib.user_list[v.userid].play_count+1;
        		--打开第15盘时，送一个银票
        		if(gold_cow_lib.user_list[v.userid].play_count==15)then
        			gold_cow_lib.user_list[v.userid].cowgamegold_rewardcount=1
        			gold_cow_db_lib.record_cowgamegold_rewardcount(v.userid,gold_cow_lib.user_list[v.userid].cowgamegold_rewardcount)
        		end
        	end
        	--todo db记录
    		gold_cow_db_lib.record_user_cowgold_info(v.userid,gold_cow_lib.user_list[v.userid].play_count)
    		send_is_finish(v.userid)
        end
    end
end

--设置金牛游戏初始值
function gold_cow_lib.set_user_cowgold_info(user_cowgold_info)
	local user_id=user_cowgold_info.user_id
	if(gold_cow_lib.user_list[user_id]==nil)then gold_cow_lib.user_list[user_id]={} end
	gold_cow_lib.user_list[user_id].user_id=user_id
	gold_cow_lib.user_list[user_id].play_count=user_cowgold_info.play_count
	gold_cow_lib.user_list[user_id].lastplay_date=user_cowgold_info.lastplay_date
	gold_cow_lib.user_list[user_id].cowgamegold_count=user_cowgold_info.cowgamegold_count
	gold_cow_lib.user_list[user_id].cowgamegold_rewardcount=user_cowgold_info.cowgamegold_rewardcount
	gold_cow_lib.user_list[user_id].bet_info=user_cowgold_info.bet_info
	local tmp_tab=split(gold_cow_lib.user_list[user_id].bet_info,",")
	local tmp_bet_num_count=0
	for i=1,6 do
		tmp_bet=tonumber(tmp_tab[i])
		tmp_bet_num_count=tmp_bet_num_count+tmp_bet
	end
	gold_cow_lib.user_list[user_id].bet_num_count=tmp_bet_num_count	
	
	--取出IP和port，这样可以方便不用user_info来发送信息
	local user_info=usermgr.GetUserById(user_id)
	gold_cow_lib.user_list[user_id].ip=user_info.ip
	gold_cow_lib.user_list[user_id].port=user_info.port
	gold_cow_lib.user_list[user_id].nick=string.trans_str(user_info.nick) or ""
	
	
end

--检查是否在有效时间内
gold_cow_lib.on_recv_check_status = function(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	local user_id=user_info.userId;
   	
   	local cow_status=0
   	--先查时间，是不是活动时间
   	local time_status=gold_cow_lib.check_datetime()
   	cow_status=time_status
   	--再查是不是完成了任务，是不是变成能玩状态了
   	netlib.send(function(buf)
            buf:writeString("CTCOWACTIVE");
            buf:writeInt(time_status or 0);		--int	0，活动无效（服务端也可不发）；1，活动有效
        end,user_info.ip,user_info.port);
	send_is_finish(user_id)
end

function send_is_finish(user_id)

   	local user_info=usermgr.GetUserById(user_id)
   	if(user_info==nil)then return end
 
   	
   	local function send_finish_result(user_info)
   		local is_finish_task=0
   		local user_id=user_info.userId
   		if(gold_cow_lib.user_list[user_id].play_count>=gold_cow_lib.CFG_CAN_PLAY)then
	   		is_finish_task=1
	   	end
   		netlib.send(function(buf)
	        buf:writeString("CTCOWTASK");
	        buf:writeByte(is_finish_task or 1);		--int	0，活动无效（服务端也可不发）；1，活动有效
	        buf:writeInt(gold_cow_lib.user_list[user_id].play_count or 0);		--int	完成盘数
        end,user_info.ip,user_info.port);
   	end
   	
   	if(gold_cow_lib.user_list[user_id]==nil or gold_cow_lib.user_list[user_id].play_count==nil)then
   		gold_cow_db_lib.init_user_safebox_gold(user_id,send_finish_result)
   	else
   		send_finish_result(user_info)
   	end
   	
   	
   
   	


end

--用户登陆后初始化数据
gold_cow_lib.on_after_user_login = function(e)
	local user_info = e.data.userinfo
	local sql=""
	if(user_info == nil)then 
		TraceError("用户登陆后初始化数据,if(user_info == nil)then")
	 	return
	end

end

--检查有效时间，限时问题int	0，活动无效（服务端也可不发）；1，活动有效
function gold_cow_lib.check_datetime()
	local sys_time = os.time();	
	local statime = timelib.db_to_lua_time(gold_cow_lib.startime);
	local endtime = timelib.db_to_lua_time(gold_cow_lib.endtime);
			
	if(sys_time > statime and sys_time <= endtime) then
		return 1;
	end
 
	--活动时间过去了
	return 0;

end


--更新玩家的投注信息
function gold_cow_lib.update_bet_info(userId,area_id,cowgamegold_bet)
	
	--更新字符串中对应位置的值
	local update_bet=function(bet_info,area_id,cowgamegold_bet)
		if(bet_info==nil or bet_info=="")then
			bet_info=gold_cow_lib.org_bet_info;	
		end
		local tmp_tab=split(bet_info,",")
		local tmp_str=""
		local tmp_bet=0
		tmp_bet=tonumber(tmp_tab[area_id])

		if(tmp_bet==nil)then
			TraceError("error bet_info="..bet_info)
		end
		
		tmp_bet=tmp_bet+cowgamegold_bet
		
		tmp_tab[area_id]=tostring(tmp_bet)
	
		for i=1,#tmp_tab do
			tmp_str=tmp_str..","..tmp_tab[i]
		end
		
		--更新下注的情况
		local tmp_bet_info=string.sub(tmp_str,2)
		local user_info=usermgr.GetUserById(userId)
		local sql="update user_goldcow_info set bet_info='%s',bet_id='%s' where user_id=%d;commit; "
		sql=string.format(sql,tmp_bet_info,gold_cow_lib.bet_id,userId)

		dblib.execute(sql)
		return tmp_bet_info --去掉第1个逗号后返回
	end
	
	--更新玩家的投注信息
	local tmpstr=""
	
	for k,v in pairs (gold_cow_lib.user_list) do
		if(v~=nil and v.user_id==userId)then

			v.bet_info=update_bet(v.bet_info,area_id,cowgamegold_bet)
			tmpstr=v.bet_info
		end
	end
	return tmpstr
end

--可用的钱发生变化
function gold_cow_lib.send_gold_change(user_info)
	netlib.send(function(buf)
            buf:writeString("CTCOWMONEY");
            buf:writeInt(user_info.cowgamegold_count*10000);		--下注结果，0，下注失败； 1，下注成功； 2，活动无效；
        end,user_info.ip,user_info.port);
end

--接收下注
function gold_cow_lib.on_recv_xiazhu(buf)

	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
	
	if (gold_cow_lib.is_valid_room()~=1) then return end
	
   	local user_id=user_info.userId
   	--下注数据
   	local area_id = buf:readInt();--区域id
   	local cowgamegold_bet = buf:readInt();--该区域下的金牛游戏币数量
   	
   	--返回客户端下注结果
   	local send_bet_result=function(user_info,result)
   		netlib.send(function(buf)
	            buf:writeString("CTCOWBET");
	            buf:writeInt(result);		--下注结果，0，下注失败； 1，下注成功； 2，活动无效；
	        end,user_info.ip,user_info.port);
   	end
   	
   	
   	
   	--本局结束前10秒不能让玩家下注
 	if(gold_cow_lib.fajiang_time-os.time()<gold_cow_lib.CFG_CANT_BETTIME ) then
		send_bet_result(user_info,3)
   		return
	end
	
	--超过区域下注上限
 	if(cowgamegold_bet>gold_cow_lib.limit_local_bet) then
 		send_bet_result(user_info,4)
   		return
 	end
 	
 	--个人的总下注
 	if(gold_cow_lib.user_list[user_id].bet_num_count==nil)then
 		user_info.bet_num_count = 0
 	end
 	
 	--总下注超过个人上限了
 	local tmp_limit=gold_cow_lib.limit_bet
 	if (gamepkg.name == "tex") then
 		tmp_limit=gold_cow_lib.tex_limit_bet
 	end
   	if(gold_cow_lib.user_list[user_id].bet_num_count>tmp_limit-cowgamegold_bet)then
   	 	send_bet_result(user_info,5)
   		return
   	end
   	
   	--判断金牛游戏币
   	--没有免费的钱，要看身上的钱够不够
   	local tmp_rate=10000/gold_cow_lib.CFG_BET_RATE
   	if(gold_cow_lib.user_list[user_id].cowgamegold_rewardcount<=0)then
   	   	if(gold_cow_lib.user_list[user_id].cowgamegold_count == nil or gold_cow_lib.user_list[user_id].cowgamegold_count == 0 or gold_cow_lib.user_list[user_id].cowgamegold_count <cowgamegold_bet/tmp_rate)then
	   		send_bet_result(user_info,2)
	   		return
	   	end
   	end
    
    local after_add_cowgamegold=function(result)
	    if(result~=-1)then
			--扣成了，就更新下注的字段，通知客户端下注成功
			gold_cow_lib.user_list[user_id].cowgamegold_count=result --刷新一下现在有多少钱用来下注
		   	gold_cow_lib.user_list[user_id].bet_num_count = gold_cow_lib.user_list[user_id].bet_num_count + cowgamegold_bet
	  		gold_cow_lib.user_list[user_id].bet_info=gold_cow_lib.update_bet_info(user_info.userId,area_id,cowgamegold_bet)
			gold_cow_lib.user_list[user_id].bet_id=gold_cow_lib.bet_id
			send_bet_result(user_info,1)
			
			--下注成功，要通知客户端新的钱还有多少
			gold_cow_lib.send_gold_change(gold_cow_lib.user_list[user_id])
			
			--下注成功，要修改一下内存里的保险箱里的钱（数据库里的钱不用改，因为存储过程里改过了
			gold_cow_lib.change_safebox_gold(user_id,gold_cow_lib.user_list[user_id].cowgamegold_count)
			
			--改总下注信息和区域下注信息
			gold_cow_lib.all_bet_count=gold_cow_lib.all_bet_count+cowgamegold_bet
			gold_cow_lib.bet_count[area_id]=gold_cow_lib.bet_count[area_id]+cowgamegold_bet
			
			--计算新的赔率(不用动态计算赔率了）
			--gold_cow_lib.update_pl()
			
			--改彩池
			gold_cow_lib.add_caichi(user_info,cowgamegold_bet)
			
			--写日志
			--囧人币日志
			gold_cow_db_lib.log_user_goldcow(user_id,result,cowgamegold_bet,1,gold_cow_lib.user_list[user_id].bet_info)
		else
			send_bet_result(user_info,2)
		end	
	
    end
   	--扣玩家身上的金牛游戏币，如果成功就返回客户端成功，不然就通知说失败
   	gold_cow_lib.add_cowgamegold(user_info.userId,-cowgamegold_bet/tmp_rate,after_add_cowgamegold)
end

--修改保险箱在内存里的值
--这里本来要调用保险箱接口，但因为这个是活动，上几天后要下线，所以直接修改了
function gold_cow_lib.change_safebox_gold(user_id,new_safebox_gold)
	local user_info=usermgr.GetUserById(user_id)
	if (gamepkg.name == "tex") then
		user_info.safegold=new_safebox_gold
		net_send_user_getsetgold_case(user_info,1,new_safebox_gold)
	else
		user_info.safebox.safegold=new_safebox_gold
	end
end

--加减牛牛游戏币
function gold_cow_lib.add_cowgamegold(user_id,add_cowgamegold,call_back)
	
	if (gold_cow_lib.is_valid_room()~=1) then return end
	
	--先扣每天免费的注
	local before_cowgamegold=gold_cow_lib.user_list[user_id].cowgamegold_count
	local goldtype=1
	local free_reward_count=gold_cow_lib.user_list[user_id].cowgamegold_rewardcount or 0
	local sql=""

	--如果玩家有免费的注
	if(add_cowgamegold<0 and free_reward_count>0)then
		--免费的只能下1注
		
   		gold_cow_lib.user_list[user_id].cowgamegold_rewardcount=0
   		sql="update user_goldcow_info set cowgamegold_rewardcount=0 where user_id=%d;select row_count() as rowcount;"
   		sql=string.format(sql,user_id)

   		dblib.execute(sql,function(dt)
			if(dt and #dt>0)then			
				if(dt[1]["rowcount"] > 0 and call_back~=nil)then
					call_back(gold_cow_lib.user_list[user_id].cowgamegold_count)
				end
			end
		end,user_id)	

		return
   	end

	--免费的钱不够了，抓金牛用的是保险箱，所以这里直接加减保险箱的钱就行了。
	--这里会同时改user_goldcow_info的钱，统一由这里改钱，就能保证2个货币是一致的
	--德州的保险箱这里要注意看一下
	local bet_info=gold_cow_lib.user_list[user_id].bet_info or ""
	if(add_cowgamegold<0)then
		gold_cow_lib.user_list[user_id].cowgamegold_count=gold_cow_lib.user_list[user_id].cowgamegold_count+add_cowgamegold
		sql="call sp_direct_safebox(%d,%d);"
		sql=string.format(sql,user_id,add_cowgamegold)
		dblib.execute(sql,function(dt)
			if(dt and #dt>0)then
				local result=dt[1].result;--result记的是变化后的值
				
				if(call_back~=nil)then
					--减钱日志放在回调里写，因为需要知道当时的投注情况
					call_back(result)					
				end				
			end
		end,user_id)	
	end
	

	if(add_cowgamegold>0)then
		 usermgr.addgold(user_id, add_cowgamegold*gold_cow_lib.CFG_BET_RATE, 0, new_gold_type.JIONGREN, -1);
		 goldtype=2
		--囧人币日志,加钱直接写日志
		gold_cow_db_lib.log_user_goldcow(user_id,before_cowgamegold,add_cowgamegold/10,goldtype,bet_info)
	end
end


--随机产生6个数字(6张牌）
function gold_cow_lib.get_card_num()
	--以时间作为随机数种子
	local t = os.time() 
	math.randomseed(t)
	
	--默认是1到1万的随机数取54的余数
	local poke_box_count=#gold_cow_lib.poke_box	
	gold_cow_lib.num1=gold_cow_lib.get_one_poke(math.random(1,10000)%poke_box_count+1)
	poke_box_count=#gold_cow_lib.poke_box	
	gold_cow_lib.num2=gold_cow_lib.get_one_poke(math.random(1,10000)%poke_box_count+1)
	poke_box_count=#gold_cow_lib.poke_box	
	gold_cow_lib.num3=gold_cow_lib.get_one_poke(math.random(1,10000)%poke_box_count+1)
	poke_box_count=#gold_cow_lib.poke_box	
	gold_cow_lib.num4=gold_cow_lib.get_one_poke(math.random(1,10000)%poke_box_count+1)
	poke_box_count=#gold_cow_lib.poke_box	
	gold_cow_lib.num5=gold_cow_lib.get_one_poke(math.random(1,10000)%poke_box_count+1)
	poke_box_count=#gold_cow_lib.poke_box	
	gold_cow_lib.num6=gold_cow_lib.get_one_poke(math.random(1,10000)%poke_box_count+1)
end

function gold_cow_lib.init_poke_box()
	gold_cow_lib.poke_box={}
	for i=1,54 do
		gold_cow_lib.poke_box[i]=i
	end	
end

function gold_cow_lib.get_one_poke(poke_index)
	local tmp_poke=gold_cow_lib.poke_box[poke_index]
	table.remove(gold_cow_lib.poke_box,poke_index)
	return tmp_poke
end

--随机产生1个数字（金牛开的位置）
function gold_cow_lib.get_random_num(num_1)
	--以时间作为随机数种子
	local t = os.time() 
	math.randomseed(t)
	
	--默认是1到1万的随机数取54的余数
	--生成1到100的随机数
	local tmp_num1=math.random(1,10000)%100+1
	local tmp_nouse_num=0
	
	local rand_type=math.random(1,t)%6+1 --有4种随机数算法，以后再加
	
	if(rand_type==1)then  --取1到32000的随机数再取余
		tmp_num1=math.random(20000,30000)%100+1
	elseif(rand_type==2)then
		tmp_nouse_num=math.random(1,10000)
		tmp_nouse_num=math.random(1,20000)
		tmp_num1=math.random(1,t)%100+1
	elseif(rand_type==3)then
		tmp_nouse_num=math.random(1,10000)
		tmp_nouse_num=math.random(1,10000)
		tmp_num1=(math.random(1,t)+math.random(1,t))%100+1
	elseif(rand_type==4)then
		tmp_nouse_num=math.random(1,t)
		tmp_nouse_num=math.random(1,10000)
		tmp_num1=(math.random(1,10000)+math.random(1,t))%100+1		
	elseif(rand_type==5)then
		tmp_nouse_num=math.random(1,10000)
		tmp_nouse_num=math.random(1,10000)
		tmp_num1=math.random(1,20000)%100+1		
	elseif(rand_type==6)then
		tmp_nouse_num=math.random(1,10000)
		tmp_nouse_num=math.random(1,3000)
		tmp_nouse_num=math.random(1,2000)
		tmp_num1=math.random(1,30000)%100+1	
	end	
	
	
	-- 概率依次：7%  14%  29%  29%  14%  7%
	if(tmp_num1>0 and tmp_num1<=7) then
		tmp_num1=1
	elseif(tmp_num1>=8 and tmp_num1<=21) then
		tmp_num1=2
	elseif(tmp_num1>=22 and tmp_num1<=50) then
		tmp_num1=3
	elseif(tmp_num1>=51 and tmp_num1<=79) then
		tmp_num1=4	
	elseif(tmp_num1>=80 and tmp_num1<=93) then
		tmp_num1=5		
	elseif(tmp_num1>=94 and tmp_num1<=100) then
		tmp_num1=6
	end

	--如果有指定值，就用指定值，否则用随机数生成的值，这是为了给GM预留接口
	if(num_1==nil)then		
		num_1 = tmp_num1		
	end
	
	return num_1
end

--计算有没有中奖，中了多少钱
function gold_cow_lib.calc_win_cowgamegold(bet_info,open_num)
	if(bet_info==nil) then return 0,0 end
	if(open_num==nil) then return 0,0 end
	local tmp_bet_info=split(bet_info,",")
    local win_gold=0
    local get_gold=0
    --赚的银票=对应赔率*投注的银票    
	win_gold=tonumber(tmp_bet_info[open_num])*gold_cow_lib.bet_peilv[open_num]
	get_gold=tmp_bet_info[open_num]+win_gold
	return win_gold,get_gold
end

--开局
--每10分钟进来一次，要做的事如下：
--1. 给上轮的人员发奖
--2. 初始化新的一轮用到的变量
--3. 写开奖日志
function gold_cow_lib.start_game()
	if (gold_cow_lib.is_valid_room()~=1) then return end
	
	local sql="";
	local zj_count=0; --有几个玩家中奖了
	local all_zj_info={}; --所有的本次中奖信息
	
	local tmp_user_info; --为了给客户端发玩家的昵称，所以引入这个变量

	local function fajiang()
		local win_cowgamegold=0 --赚到的金牛游戏币
		local get_cowgamegold=0 --一共应该有的金牛游戏币
		local gain_most_info={} --这一轮赚得最多的10个人
		for k,v in pairs (gold_cow_lib.user_list) do
			local buf_zj_info={};
			
			--给每个中奖的人发奖
			win_cowgamegold,get_cowgamegold=gold_cow_lib.calc_win_cowgamegold(v.bet_info,gold_cow_lib.zhongjiang_num)
			gold_cow_lib.user_list[v.user_id].win_cowgamegold=win_cowgamegold
			gold_cow_lib.user_list[v.user_id].get_cowgamegold=get_cowgamegold
			--得到有几个人中奖，这些人赚了多少钱的信息
			if(win_cowgamegold>0)then					
			    gold_cow_lib.add_cowgamegold(v.user_id, win_cowgamegold);
				zj_count=zj_count+1
				tmp_user_info=usermgr.GetUserById(v.user_id) --为了给客户端发玩家的昵称，所以引入这个变量
				
				if(tmp_user_info~=nil)then
					netlib.send(function(buf)
			            buf:writeString("DVDMYWIN"); --通知客户端，玩家的中奖记录
			            buf:writeInt(win_cowgamegold); --中奖的玩家数量		           
			            end,tmp_user_info.ip,tmp_user_info.port)
			            
			           
		        end
		        
				buf_zj_info.user_id=v.user_id
				buf_zj_info.nick=v.nick
				buf_zj_info.win_cowgamegold=win_cowgamegold
				table.insert(all_zj_info,buf_zj_info)
			end
		end
	
		--通知客户端，玩家的中奖记录
		--按照win_cowgamegold排名
		if(all_zj_info~=nil and #all_zj_info>2)then
			table.sort(all_zj_info, 
			      function(a, b)
				     return a.win_cowgamegold > b.win_cowgamegold		                   
			end)
		end
		--计算一下总共被赢走了多少钱
		local all_win_gold=0
		for k,v in pairs (all_zj_info) do
			all_win_gold=all_win_gold+v.win_cowgamegold
		end
		
		--给游戏里的人发前10名的记录
		for k,v in pairs (gold_cow_lib.user_list) do
			local user_info=usermgr.GetUserById(v.user_id)
			if(user_info~=nil)then				
				netlib.send(function(buf)
		            buf:writeString("CTCOWUSERS"); --通知客户端，玩家的中奖记录		           
		            local mc_len=10 --最多显示前10名
		            local send_len=#all_zj_info or 0
		            if(send_len>mc_len)then send_len=mc_len end
		            buf:writeInt(send_len); --中奖的玩家数量
		            if(send_len>0)then
			            for i=1,send_len do
			            	buf:writeInt(all_zj_info[i].user_id) --玩家ID
			            	buf:writeString(all_zj_info[i].nick or "")   --玩家昵称
			            	buf:writeInt(all_zj_info[i].win_cowgamegold*gold_cow_lib.CFG_BET_RATE or 0) --玩家中奖的金牛游戏币数量
			            end
		            end
		            end,user_info.ip,user_info.port) 
			end
		end
		
		--如果彩池大于0，还要给大家分彩池里的钱(暂时不用退了）
		--local reward_caichi=0
		--if(gold_cow_lib.caichi>0)then
		--	for k,v in pairs (all_zj_info) do
		--		reward_caichi=(gold_cow_lib.caichi/1000)*(v.win_cowgamegold/all_win_gold)
		--		--加金牛游戏币
		--	   	gold_cow_lib.add_cowgamegold(v.userId,reward_caichi)
		--	end
		--end
		
	end
	
 	--初始化一局的信息
 	local function init_game_info()
 		local curr_time=os.time()
		--初始化开奖的时间		
	 	gold_cow_lib.fajiang_time=curr_time+60*5
 	    
 	    --初始化本轮的投注ID，年月日时分为组和的字段作为投注ID
	 	gold_cow_lib.bet_id = os.date("%Y%m%d%H%M", curr_time)	 	
	 	
	 	--初始化这一轮投注的人
	 	for k,v in pairs(gold_cow_lib.user_list) do
	 		v.bet_info=gold_cow_lib.org_bet_info
			v.bet_num_count=0
			v.win_cowgamegold=0	
			v.get_cowgamegold=0		
	 	end
	 	
	 	--初始化彩池
	 	gold_cow_lib.caichi=0
	 	gold_cow_lib.send_caichi()
	 	
	 	--初始化牌盒
	 	gold_cow_lib.init_poke_box()
	 	
	
	 	
	 	--更新最新的bet_id到参数表里，防止服务器重启时要退钱
	 	gold_cow_lib.update_last_betid(gold_cow_lib.bet_id)
	 	
	 	gold_cow_lib.all_user_bet_info={}
	 	gold_cow_lib.all_bet_count=0
	 	gold_cow_lib.bet_count={
			[1]=0,          
			[2]=0,        
			[3]=0,         
			[4]=0,         
			[5]=0,           
			[6]=0,           
		}
 	end
 	
 	--设置中奖的号码
 	local function set_zj_num()
 		if(gold_cow_lib.zhongjiang_num==1)then
 			gold_cow_lib.num1=55 			
 		elseif(gold_cow_lib.zhongjiang_num==2)then
 			gold_cow_lib.num2=55
 		elseif(gold_cow_lib.zhongjiang_num==3)then
 			gold_cow_lib.num3=55	
 		elseif(gold_cow_lib.zhongjiang_num==4)then
 			gold_cow_lib.num4=55
 		elseif(gold_cow_lib.zhongjiang_num==5)then
 			gold_cow_lib.num5=55
 		elseif(gold_cow_lib.zhongjiang_num==6)then
 			gold_cow_lib.num6=55
 		end
 	end
 	
 	--如果gm指定了号，就开指定的号，这把中了之后要把值换回来，防止一直开一个号
 	if(gold_cow_lib.gm_num~=nil and gold_cow_lib.gm_num~=0)then
 		gold_cow_lib.zhongjiang_num= gold_cow_lib.get_random_num(gold_cow_lib.gm_num)
 		gold_cow_lib.gm_num=0
	else
 		gold_cow_lib.zhongjiang_num = gold_cow_lib.get_random_num()	--获取随机数
 	end
 	
 	--设置6张底牌
 	if(#gold_cow_lib.poke_box==0)then
 		gold_cow_lib.init_poke_box()
 	end
 	gold_cow_lib.get_card_num()
 	
 	--设置中奖的号为55即金牛
 	set_zj_num()

	--加入历史表中
	if(#gold_cow_lib.history < gold_cow_lib.history_len)then		--如果长度小于6，直接加入
		local bufftable ={
	  	    zhongjiang_num = gold_cow_lib.zhongjiang_num
        }	                
		table.insert(gold_cow_lib.history,bufftable)
	else
		table.remove(gold_cow_lib.history,1)	--删除第一条		
		local bufftable ={
			zhongjiang_num = gold_cow_lib.zhongjiang_num, 
		}	                
		table.insert(gold_cow_lib.history,bufftable)
	end
	
	
	--写历史数据日志
	gold_cow_db_lib.log_goldcow_history(gold_cow_lib.zhongjiang_num,gold_cow_lib.bet_id)
 	
 	--给中奖的人发奖
 	fajiang();
 	
 	--发送骰子数据
 	local tmp_flag=0
 	for k1,v1 in pairs (gold_cow_lib.user_list) do
		local user_info=usermgr.GetUserById(v1.user_id)
		if (user_info~=nil)then				
		 	netlib.send(function(buf)
 				buf:writeString("CTCOWKAI")
            	buf:writeInt(gold_cow_lib.num1)
            	buf:writeInt(gold_cow_lib.num2)
            	buf:writeInt(gold_cow_lib.num3)
            	buf:writeInt(gold_cow_lib.num4)
            	buf:writeInt(gold_cow_lib.num5)
            	buf:writeInt(gold_cow_lib.num6)
            	buf:writeInt(v1.win_cowgamegold*gold_cow_lib.CFG_BET_RATE or 0)
		 	 end,user_info.ip,user_info.port) 
		 	 
		end --end if
	 end -- end for
 	
 	--初始化新一轮的信息
 	init_game_info(); 	
end

--倒计时
function gold_cow_lib.timer()
	math.random();
  	
  	if (gold_cow_lib.is_valid_room()~=1) then return end
  	
  	--10分钟开一局
  	if(os.time() > gold_cow_lib.fajiang_time-3)then	 
     	--开局(有个缺陷，刚开局会产生一组没人中过的数据
     	gold_cow_lib.start_game()
    end
    
    if(os.time() > gold_cow_lib.other_bet_time)then	 
     	--开局(有个缺陷，刚开局会产生一组没人中过的数据
     	gold_cow_lib.send_other_bet_info()
    end    
end

--重启服务器了
function gold_cow_lib.restart_server(e)
	if (gold_cow_lib.is_valid_room()~=1) then return end
	
	local param_str_value = "-1"
	local function return_cowgamegold(user_id,bet_info)
		if(user_id==-1 or bet_info=="-1")then return end
		local yin_piao=0;
		local tmp_bet_info={}
		tmp_bet_info=split(bet_info,",")   			
		for i=1,6 do
			yin_piao=yin_piao+tmp_bet_info[i]
		end
		yin_piao=yin_piao/(10000/gold_cow_lib.CFG_BET_RATE)
		--先返还金牛游戏币，再还保险箱
		local sql="update user_goldcow_info set cowgamegold_count=cowgamegold_count+%d,bet_info='%s' where user_id=%d and bet_info<>'%s';commit;"
		sql=string.format(sql,yin_piao,gold_cow_lib.org_bet_info,user_id,gold_cow_lib.org_bet_info)
		dblib.execute(sql,function(dt)
				--返还保险箱里的钱
				sql="UPDATE user_safebox_info SET safe_gold=safe_gold+%d WHERE user_id = %d;"
				sql=string.format(sql,yin_piao,user_id)
				dblib.execute(sql)
		end)
	
	end
	
	local sql = "SELECT param_str_value FROM cfg_param_info WHERE param_key = 'GOLDCOW_BETID' and room_id=%d"
	sql = string.format(sql,groupinfo.groupid);
	dblib.execute(sql,
    function(dt)
    	if dt and #dt > 0 then
    		param_str_value = dt[1]["param_str_value"]
    	else
    		param_str_value = "-1"
		end
    		--通过param_str_value（betid)给玩家退金牛游戏币
    		sql="select user_id,bet_info from user_goldcow_info where bet_id='%s'"
    		sql=string.format(sql,param_str_value)
    		dblib.execute(sql,
			    function(dt)
			    	if dt and #dt > 0 then
			    		for i=1,#dt do
			    			
			    			local user_id=dt[i]["user_id"] or -1
			    			local bet_info=dt[i]["bet_info"] or "-1"
			    			
			    			return_cowgamegold(user_id,bet_info)			    			
			    		end
			    	end
			    end)
	end)
end

--更新最近的一次betid
function gold_cow_lib.update_last_betid(betid)
	--更新数据库
	local sql = "insert into cfg_param_info (param_key,param_str_value,room_id) value('GOLDCOW_BETID','-1',%d) on duplicate key update param_str_value = '%s'";
	sql=string.format(sql, groupinfo.groupid,betid)
	dblib.execute(sql)
end

--其他玩家投注区域信息
function gold_cow_lib.send_other_bet_info()
	local tmp_user_bet_info1={} --用作统计投注数量的临时变量
	local tmp_user_bet_info2={} --用来存放所有玩家投注数量的临时变量
	local tmp_bet_info=""
	local tmp_str=""
	local tmp_bet_num=gold_cow_lib.org_bet_info
	tmp_user_bet_info2=split(tmp_bet_num,",")
	--得到所有人的投注信息放到tmp_user_bet_info2中
	for k,v in pairs (gold_cow_lib.user_list) do
   			tmp_bet_info=v.bet_info
   			if(tmp_bet_info==nil or tmp_bet_info=="")then
   				tmp_bet_info=gold_cow_lib.org_bet_info
   			end
   			tmp_user_bet_info1=split(tmp_bet_info,",")   			
   			for i=1,6 do	   					
   				tmp_user_bet_info2[i]=tmp_user_bet_info2[i]+tmp_user_bet_info1[i]
   			end
	end
	
	gold_cow_lib.all_user_bet_info=tmp_user_bet_info2
	
	--通知客户端，其他玩家投注结果（所有人减去自己）
	for k,v in pairs (gold_cow_lib.user_list) do
		local user_info=usermgr.GetUserById(v.user_id)
		if(user_info~=nil)then
			tmp_user_bet_info1=split(v.bet_info or gold_cow_lib.org_bet_info,",")
			netlib.send(function(buf)
		    	buf:writeString("CTCOWALLBET")
		    	buf:writeInt(6)    	
		    	for i=1,6 do
		    		buf:writeInt(i)
		    		--buf:writeInt(tmp_user_bet_info2[i]-tmp_user_bet_info1[i])
		    		buf:writeInt(tmp_user_bet_info2[i])
		    		buf:writeInt(gold_cow_lib.bet_peilv[i])		    		    		
		    	end
		    	end,user_info.ip,user_info.port)
	    end
     end
     
     --10秒之后才能再进来一次
     gold_cow_lib.other_bet_time=os.time()+10
end

--发给客户端彩池信息
function gold_cow_lib.send_caichi()
	for k,v in pairs(gold_cow_lib.user_list) do
		local user_info=usermgr.GetUserById(v.user_id)
		if(user_info~=nil)then
			netlib.send(function(buf)
	    		buf:writeString("CTCOWCAICHI")
	    		buf:writeInt(gold_cow_lib.caichi or 0) 
	    		end,user_info.ip,user_info.port)
		end
    end
end

--按投注额来给彩池加钱
function gold_cow_lib.add_caichi(user_info,bet_count)
	gold_cow_lib.caichi=gold_cow_lib.caichi+bet_count*1000
	gold_cow_lib.send_caichi()
end

--发送历史表
function gold_cow_lib.send_history(user_info,history_list)
	local send_len = 0
	if(history_list~=nil)then
	   send_len=#history_list
	end
	netlib.send(function(buf)
    	buf:writeString("CTCOWREC")
    	    
		 buf:writeInt(send_len)
			if(send_len < gold_cow_lib.history_len)then
				for i=1,send_len do
			        buf:writeInt(history_list[i].zhongjiang_num) 
		        end
			else
		        for i=1,gold_cow_lib.history_len do
			        buf:writeInt(history_list[i].zhongjiang_num)	 
		        end
		    end
     	end,user_info.ip,user_info.port) 
end

--倍率=所有牌总下注/当前牌总下注，率取整
function gold_cow_lib.update_pl()
	for i=1,6 do
		bet_peilv[i]=gold_cow_lib.all_bet_count/gold_cow_lib.bet_count[i]
	end
end

--进入游戏
--通知客户端，返回面板信息
--	a. 消息名：DVDOPEN
--	b. 参数：
--		1) int		金牛游戏币数量
--		2) int		已投注区域个数
--		for 已投注区域个数
--			1) int	区域id
--			2) int	 其他玩家 投注的金牛游戏币数量
--			3) int  玩家自己 投注的金牛游戏币数量
--给客户端发开奖时间还差多少秒
--给客户端发开奖历史
function gold_cow_lib.on_recv_open_game(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	local user_id=user_info.userId
   	--通知客户端，面板信息
   	local send_dvd_info = function(cow_user_info)
   		local bet_info=cow_user_info.bet_info
   		local tmp_user_bet_info=split(bet_info,",")
   		local is_finish_task=0
   		if(gold_cow_lib.user_list[user_id].play_count>=gold_cow_lib.CFG_CAN_PLAY)then
	   		is_finish_task=1
	   	end
	   	local user_info=usermgr.GetUserById(cow_user_info.user_id)
	   	--todo
	   	--同步保险箱的钱
   		netlib.send(function(buf)
            buf:writeString("CTCOWOPEN") --通知客户端，更新玩家金牛游戏币数
            buf:writeByte(is_finish_task)            
            buf:writeInt(gold_cow_lib.user_list[user_id].cowgamegold_count*10000 or 0); --玩家金牛游戏币数
            buf:writeInt(gold_cow_lib.user_list[user_id].cowgamegold_rewardcount or 0)
            buf:writeInt(6); --默认为6个区域都传回客户端。因为大多数情况下所有区域都可能有人投
			for i=1,6 do
				buf:writeInt(i) --区域id
				local tmpnum=0
				if(gold_cow_lib.all_user_bet_info~=nil and #gold_cow_lib.all_user_bet_info~=0)then
					tmpnum=gold_cow_lib.all_user_bet_info[i]
				end
				buf:writeInt(tmpnum) --其他玩家 投注的金牛游戏币数量
				buf:writeInt(tmp_user_bet_info[i]) --玩家自己 投注的金牛游戏币数量
				buf:writeInt(gold_cow_lib.bet_peilv[i]) --这个区域的赔率
				
			end            
            end,user_info.ip,user_info.port) 
   	end
   	
   	local function send_client_info(user_info)
   	   	--给客户端发开奖时间还差多少秒
	   	gold_cow_lib.send_remain_time(user_info,gold_cow_lib.fajiang_time)
	   	
	   	--给客户端发开奖历史
	   	gold_cow_lib.send_history(user_info,gold_cow_lib.history)
	   	
	   	--通知客户端，面板信息
	   	send_dvd_info(gold_cow_lib.user_list[user_info.userId])
   	end
   	
   	--加入游戏信息
	local already_join_game=0 --是否已加入了游戏
	
	--如果已加入过游戏，就初始化一下玩家的游戏信息
	for k,v in pairs(gold_cow_lib.user_list) do
		if(v.user_id==user_info.userId)then
			already_join_game=1
			break
		end
	end
	
	--将玩家游戏信息插入到记录表中
	if(already_join_game==0)then
		--gold_cow_lib.user_list[user_info.userId]={}
		gold_cow_db_lib.init_user_safebox_gold(user_info.userId,send_client_info)	
		return --gold_cow_lib.user_list[user_info.userId].bet_info=gold_cow_lib.org_bet_info
	end
   	
   	send_client_info(user_info)
   	
end

--请求服务端，剩余开奖时间
function gold_cow_lib.on_recv_query_time(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	gold_cow_lib.send_remain_time(user_info,gold_cow_lib.fajiang_time)
end

--告诉客户端还差多少秒
function gold_cow_lib.send_remain_time(user_info,fajiang_time)
	local curr_time = os.time();
	local remain_time = fajiang_time-curr_time;
	netlib.send(function(buf)
        buf:writeString("CTCOWTIME"); --通知客户端，剩余开奖时间
        buf:writeInt(remain_time);		--剩余开奖时间
      
    end,user_info.ip,user_info.port);
end

--客户端指定开某个数，用来调试
function gold_cow_lib.on_recv_gm_num(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	
   	--是否GM
	local function is_gm(user_id)
		if type(user_id) ~= string then
			user_id = tostring(user_id)
		end
		local tmp_gm={}
		if (gamepkg.name == "tex") then
			tmp_gm=gold_cow_lib.tex_gm_id_arr
		else		
			tmp_gm=gold_cow_lib.qp_gm_id_arr
		end
		
		for k, v in pairs(tmp_gm) do
			if v == user_id then
				return true
			end
		end
		return false
	end

   	if(is_gm(user_info.userId)==false)then
   		return
   	end

    local gm_num1=buf:readInt(); --数字1

    if(gm_num1==nil)then
    	return
    end

    gold_cow_lib.gm_open_num(gm_num1)
end

--协议命令
cmd_goldcow_handler = 
{
	["CTCOWACTIVE"] = gold_cow_lib.on_recv_check_status, --请求活动是否有效
    ["CTCOWBET"] = gold_cow_lib.on_recv_xiazhu, --接收下注
    ["CTCOWOPEN"] = gold_cow_lib.on_recv_open_game, --请求服务端，请求打开面板信息
    ["CTCOWTIME"] = gold_cow_lib.on_recv_query_time, --请求服务端，剩余开奖时间
    ["CTCOWGMNUM"] = gold_cow_lib.on_recv_gm_num, --请求服务端，GM数字
    
}

--加载插件的回调
for k, v in pairs(cmd_goldcow_handler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("h2_on_user_login", gold_cow_lib.on_after_user_login);
eventmgr:addEventListener("timer_second", gold_cow_lib.timer);
eventmgr:addEventListener("game_event", gold_cow_lib.on_game_over);
eventmgr:addEventListener("on_server_start", gold_cow_lib.restart_server);
 