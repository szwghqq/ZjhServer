TraceError("init daxiao_game...")
dofile("games/modules/daxiao/daxiao.adapter.lua") --心跳十分钟功能

if (daxiao_lib and daxiao_lib.gm_cmd) then
    eventmgr:removeEventListener("gm_cmd", daxiao_lib.gm_cmd)
end

--if daxiao_lib and daxiao_lib.on_after_user_login then
--	eventmgr:removeEventListener("h2_on_user_login", daxiao_lib.on_after_user_login);
--end

if daxiao_lib and daxiao_lib.timer then
	eventmgr:removeEventListener("timer_second", daxiao_lib.timer);
end

if daxiao_lib and daxiao_lib.restart_server then
	eventmgr:removeEventListener("on_server_start", daxiao_lib.restart_server);
end
if not daxiao_lib then
    daxiao_lib = _S
    {    	   
        on_after_user_login = NULL_FUNC,--登陆后做的事
		check_datetime  = NULL_FUNC,	--检查有效时间，限时问题
		on_recv_query_time = NULL_FUNC, --客户端检查剩余时间
		on_recv_buy_yinpiao = NULL_FUNC,	--接收购买银票
		on_recv_exchange = NULL_FUNC,	--取出银票/银元
        on_recv_check_time = NULL_FUNC, --通知服务端，请求活动时间状态        
        send_remain_time = NULL_FUNC, --计算差多少秒开奖
        update_bet_info = NULL_FUNC, --更新投注信息
        on_recv_xiazhu = NULL_FUNC, --客户端通知下注
        calc_can_use_gold = NULL_FUNC, --计算能用的钱
        gen_counts = NULL_FUNC,
        create_open_num = NULL_FUNC,
        fajiang = NULL_FUNC,
        --计算赚的银票
        calc_win_yinpiao = NULL_FUNC, --计算赚的银票
        add_yinpiao = NULL_FUNC, --给玩家加减银票
        get_random_num = NULL_FUNC, --生成三个随机数
        
        start_game = NULL_FUNC, --开始游戏
        timer = NULL_FUNC, --定时器
        send_other_bet_info = NULL_FUNC, --发其他人的投注信息
        send_history = NULL_FUNC, --发送历史记录
        gm_open_num = NULL_FUNC, --开指定的号
        on_recv_gm_num = NULL_FUNC, --客户端通知开指定的号
        is_valid_room = NULL_FUNC,
        gm_cmd = NULL_FUNC,
   		--游戏配置:
   		num1 = 0,	--骰子1
		num2 = 0,	--骰子2
		num3 = 0,	--骰子3
		
		gm_num1 = 0, --gm开指定的骰子
		gm_num2 = 0, --gm开指定的骰子
		gm_num3 = 0, --gm开指定的骰子
		fajiang_lock = 0,
		history = {},	--历史骰子
		history_len = 6,	--历史骰子长度
 		 		
 		daxiao_game_info = {},		--桌子数据
 		

		total_num = 0,	--骰子相加结果
	
		limit_bet = 1000,	--个人总下注上限  1000
		limit_local_bet = 1000,	--区域下注上限  1000
		day_count_bet = 10000,	--个人每日下注总量  10000 次(每十分钟才开一次，不可能到10000次，所以这个变量应该是没用的）
		
		choushui_info=0.05, --取银票的话，要抽%5的水

		--下注时间 10分钟
		startime = "2011-12-30 00:00:00",  --活动开始时间
    	endtime = "2019-01-04 00:00:00",  --活动结束时间
    	tex_open_time = {{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23}}, --{8,9,10},指定德州开活动的时间
		qp_open_time = {}, --{8,9,10},指定棋牌开活动的时间
        open_time = {},
        fajiang_time = 0,  --本局发奖时间
		other_bet_time = 0, --其他玩家下注信息
		bet_id = "-1", --本局的ID
		kajiang_table={}, --开奖的表格，本轮开出了什么奖
		
		all_user_bet_info={}, --所有玩家下注信息
		send_huodong_expire = 0,  --是否发送过活动结束
		--赔率配置表
		bet_peilv = {
			[1]=1,             --凤
			[2]=180,           --111
			[3]=180,           --222
			[4]=180,           --333
			[5]=180,           --444
			[6]=180,           --555
			[7]=180,           --666
			[8]=25,           --任意一种豹子			
			[9]=1,             --龙
			[10]=50,            --和为4
			[11]=18,            --和为5
			[12]=14,            --和为6
			[13]=12,            --和为7
			[14]=8,            --和为8
			[15]=6,            --和为9
			[16]=6,            --和为10
			[17]=6,            --和为11
			[18]=6,            --和为12
			[19]=8,            --和为13
			[20]=12,            --和为14
			[21]=14,            --和为15
			[22]=18,            --和为16
			[23]=50,            --和为17
			[24]=1,            --押中单数
			[25]=2,            --押中双数
			[26]=3,            --押中三数
		},
		
		qp_game_room = 62022, --棋牌在哪个房间开游戏
		tex_game_room = 18001, --德州在哪个房间开游戏
		tex_gm_id_arr = {'69464','1073'}, -- {'832791'},
		qp_gm_id_arr = {}, --{'19563389'},
		org_bet_info="0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0",
		--停止下注时间 10秒
        user_list = {},
    }    
end

--gm开指定的号
daxiao_lib.gm_open_num=function(num1,num2,num3)
	daxiao_lib.gm_num1=num1
	daxiao_lib.gm_num2=num2
	daxiao_lib.gm_num3=num3	
end

daxiao_lib.is_valid_room=function()
	if(gamepkg.name == "daxiao" and 19001 ~= tonumber(groupinfo.groupid))then
		return 0
	end
	return 1
end

--计算能用的钱
daxiao_lib.calc_can_use_gold=function(userinfo)

    --冻结的筹码
    local can_usegold = 0
    if (gamepkg.name == "daxiao") then
	    if(userinfo.chouma==nil or userinfo.chouma == 0)then
	    	can_usegold = userinfo.gamescore
	    else    
	        can_usegold = userinfo.gamescore - userinfo.chouma  --扣除已下注的筹码        
	    end
	else
		if(userinfo.site~=nil)then
			can_usegold = userinfo.gamescore
		end
    end
    return can_usegold
end

--计算赚的银票
daxiao_lib.calc_win_yinpiao=function(bet_info,num1,num2,num3)
	--加入容错语句
	if(bet_info==nil or bet_info=="")then
		bet_info=daxiao_lib.org_bet_info		
	end
	if (bet_info == daxiao_lib.org_bet_info) then
		return 0,0,{}
	end
	local bet_info_tab={}
	local win_yinpiao = 0 --赚到的银票
	local get_yinpiao = 0 --最后应该得到的银票
	local count_right=0 --押中的个数
	local count_num=num1+num2+num3 --总数
	
	local user_zj_info={} --玩家的分区域中奖信息
	local split_bet_info = function(bet_info)
		local tmp_tab=split(bet_info, ",")
		return tmp_tab
	end
	
	bet_info_tab = split_bet_info(bet_info)
	
	--赚的银票=对应赔率*投注的银票
	--最后得到的银票=对应赔率*投注的银票+投注的银票
	--前23种情况的银票
	local is_baozi=0
	if(num1==num2 and num1==num3)then
		is_baozi=1
	end
	for i=1,23 do
		local zj_buf={} --区域中奖信息，包括区域id和赚了多少银票
		local tmp_bet_right=0 --是否押中的标识符
		if(i==1 and count_num>=4 and count_num<=10 and is_baozi==0)then --龙凤要被豹子吃掉
			tmp_bet_right=1
		elseif(i==2 and num1==1 and num2==1 and num3==1)then
			tmp_bet_right=1
		elseif(i==3 and num1==2 and num2==2 and num3==2)then
			tmp_bet_right=1
		elseif(i==4 and num1==3 and num2==3 and num3==3)then
			tmp_bet_right=1
		elseif(i==5 and num1==4 and num2==4 and num3==4)then
			tmp_bet_right=1		
		elseif(i==6 and num1==5 and num2==5 and num3==5)then
			tmp_bet_right=1
		elseif(i==7 and num1==6 and num2==6 and num3==6)then
			tmp_bet_right=1
		elseif(i==8 and is_baozi==1)then
		--   tmp_bet_right=1   --新版本的三分钟认为任意baozi不算中奖，必须押中指定的baozi
		elseif(i==9 and count_num>=11 and count_num<=17 and is_baozi==0)then --龙凤要被豹子吃掉
			tmp_bet_right=1
		elseif(i==10 and count_num==4)then
			tmp_bet_right=1	
		elseif(i==11 and count_num==5)then
			tmp_bet_right=1	
		elseif(i==12 and count_num==6)then
			tmp_bet_right=1	
		elseif(i==13 and count_num==7)then
			tmp_bet_right=1				
		elseif(i==14 and count_num==8)then
			tmp_bet_right=1				
		elseif(i==15 and count_num==9)then
			tmp_bet_right=1				
		elseif(i==16 and count_num==10)then
			tmp_bet_right=1				
		elseif(i==17 and count_num==11)then
			tmp_bet_right=1				
		elseif(i==18 and count_num==12)then
			tmp_bet_right=1				
		elseif(i==19 and count_num==13)then
			tmp_bet_right=1				
		elseif(i==20 and count_num==14)then
			tmp_bet_right=1				
		elseif(i==21 and count_num==15)then
			tmp_bet_right=1			
		elseif(i==22 and count_num==16)then
			tmp_bet_right=1				
		elseif(i==23 and count_num==17)then
			tmp_bet_right=1																						
		end
		
		if(tmp_bet_right==1)then
			table.insert(daxiao_lib.kajiang_table,i)
		end
		
		
		if(bet_info_tab==nil or bet_info_tab[i]==nil or tonumber(bet_info_tab[i])==0)then --对应格子没押，直接认为没中
			tmp_bet_right=0
		end
		--如果押中了，就加银票
		if(tmp_bet_right==1)then
			win_yinpiao=win_yinpiao+bet_info_tab[i]*daxiao_lib.bet_peilv[i]
			get_yinpiao=get_yinpiao+(bet_info_tab[i]+bet_info_tab[i]*daxiao_lib.bet_peilv[i])
			zj_buf.area_id=i
			zj_buf.get_yinpiao=get_yinpiao
			zj_buf.area_win_yinpiao = bet_info_tab[i]+bet_info_tab[i]*daxiao_lib.bet_peilv[i]
			table.insert(user_zj_info,zj_buf)
		end
	end
	
	--后三种情况的银票,看押中几个数
	--押中1个翻1倍，2个翻3倍，3个翻3倍
	local tmp_num=0
	for i=24,29 do
		local zj_buf={} --区域中奖信息，包括区域id和赚了多少银票
		count_right=0 --标识压中了几次
		
		if(i==24+tmp_num)then  --标识位置
			if(num1==1+tmp_num and  tonumber(bet_info_tab[i])~=0)then --看对应位置的数字是不是对上了
				count_right=count_right+1
			end
			if(num2==1+tmp_num and  tonumber(bet_info_tab[i])~=0)then
				count_right=count_right+1
			end
			if(num3==1+tmp_num and  tonumber(bet_info_tab[i])~=0)then
				count_right=count_right+1
			end
			
			--是否是开奖位
			if(num1==1+tmp_num or num2==1+tmp_num or num3==1+tmp_num)then			
				table.insert(daxiao_lib.kajiang_table,i)
			end
		end
		tmp_num=tmp_num+1
		
		win_yinpiao=win_yinpiao+bet_info_tab[i]*count_right
		local is_zj_area=0
		if(count_right~=0)then
			is_zj_area=1
		end
		
		get_yinpiao=get_yinpiao+(bet_info_tab[i]*is_zj_area+bet_info_tab[i]*count_right)
		if(count_right>0)then
			zj_buf.area_id=i
			zj_buf.get_yinpiao=get_yinpiao
			zj_buf.area_win_yinpiao = bet_info_tab[i]*is_zj_area+bet_info_tab[i]*count_right
			table.insert(user_zj_info,zj_buf)			
		end		
	end
		
	return win_yinpiao,get_yinpiao,user_zj_info
end

--检查是否在有效时间内
daxiao_lib.on_recv_check_time = function(buf)
	--local user_info = daxiao_hall.get_user_info_by_key(daxiao_hall.get_user_key(buf));	
   	--if not user_info then return end;
    local ip = buf:ip()
    local port = buf:port()
   	local time_status=daxiao_lib.check_datetime()
   	local room_status=daxiao_lib.is_valid_room()
   	
   	local status = time_status
   	if daxiao_lib.is_valid_room() ~= 1 then status = 0 end

    --如果没有玩过则活动也无效
    --[[local sql="select count(*) as num from user_daxiao_info where user_id=%d"
    sql = string.format(sql, user_info.userId)
    dblib.execute(sql, function(dt)
        if (time_status == 1 and dt and #dt >0 and dt[1].num > 0) then
            time_status = 1
        else
            time_status = 0
        end
        if (viplib.get_vip_level(user_info) >= 1) then
            time_status = 1
        end
       	netlib.send(function(buf)
                buf:writeString("DVDDATE");
                buf:writeInt(time_status == 1 and status == 1 and 1 or 0);		--int	0，活动无效（服务端也可不发）；1，活动有效
            end,user_info.ip,user_info.port);
    end, user_info.userId)--]]
    --if (time_status == 1 and viplib.get_vip_level(user_info) < 1) then
    --    time_status = 0
    --end
    netlib.send(function(buf)
            buf:writeString("DVDDATE");
            buf:writeInt(time_status == 1 and status == 1 and 1 or 0);		--int	0，活动无效（服务端也可不发）；1，活动有效
        end, ip, port);
end

--用户登陆后初始化数据
daxiao_lib.on_after_user_login = function(user_info, call_back)

	--local user_info = e.data.userinfo
    --这里修改车的情况
	--xpcall(function() car_match_db_lib.on_after_user_login(user_info) end, throw)
	local sql=""
	if(user_info == nil)then 
		TraceError("用户登陆后初始化数据,if(user_info == nil)then")
	 	return
	end
	user_info.init_daxiao_flag = 1
    user_info.yinpiao_count=0
    user_info.ex_yinpiao_count = 0
    user_info.bet_info=daxiao_lib.org_bet_info
    user_info.bet_num_count = 0
    user_info.bet_id=""
	--登陆查询数据库
	--得到用户手上现在有多少银票，最近的一次投注值和最近的一次投注ID
	sql="select yinpiao_count,bet_info,bet_id, ex_yinpiao_count from user_daxiao_info where user_id=%d"
	sql=string.format(sql,user_info.userId)
	dblib.execute(sql,function(dt)	
				if(dt~=nil and  #dt>0)then
					user_info.yinpiao_count=dt[1].yinpiao_count;
                    user_info.ex_yinpiao_count=dt[1].ex_yinpiao_count;
					if(dt[1].bet_id==daxiao_lib.bet_id and dt[1].bet_info~=nil and dt[1].bet_info~="")then
						user_info.bet_info=dt[1].bet_info;
					else
						user_info.bet_info=daxiao_lib.org_bet_info;
					end					
					user_info.bet_id=dt[1].bet_id;
				else
					user_info.yinpiao_count=0;
                    user_info.ex_yinpiao_count=0;
					user_info.bet_info=daxiao_lib.org_bet_info;
					user_info.bet_id="";
				end
				
				local tmp_user_bet_info = split(user_info.bet_info,",")
				local tmp_bet_num_count = 0
	   			for i=1,29 do	   					
	   				tmp_bet_num_count=tmp_bet_num_count+tmp_user_bet_info[i]
	   			end
	   			user_info.bet_num_count=tmp_bet_num_count
				daxiao_lib.check_back_yinpiao(user_info)
				if call_back ~= nil then
					call_back(user_info)
				end
				eventmgr:dispatchEvent(Event("already_init_yinpiao", _S{user_id=user_info.userId,yinpiao_count=user_info.yinpiao_count,ex_yinpiao_count=user_info.ex_yinpiao_count}));
	    end, user_info.userId)
end

--检查是否退还银票
daxiao_lib.check_back_yinpiao = function(user_info)
    local check_status = daxiao_lib.check_expire()
    if (check_status == 0) then
        local sql = "update user_daxiao_info set yinpiao_count = 0, bet_info = '%s', bet_id = '' where user_id = %d"
        sql = string.format(sql, daxiao_lib.org_bet_info, user_info.userId)
		dblib.execute(sql, function(dt)
            if (gamepkg.name == "daxiao") then
				local gold = user_info.yinpiao_count * daxiao_adapt_lib.tex_yipiao_rate
				local choushui = gold * daxiao_lib.choushui_info
				gold = gold - choushui
				usermgr.addgold(user_info.userId, gold, choushui, g_GoldType.daxiao_gold, g_GoldType.daxiao_choushui,-1);
			else
				local gold = user_info.yinpiao_count * daxiao_adapt_lib.qp_yipiao_rate
				local choushui = gold * daxiao_lib.choushui_info
				gold = gold - choushui
				usermgr.addgold(user_info.userId, gold, choushui, tSqlTemplete.goldType.DAXIAO_GOLD, tSqlTemplete.goldType.DAXIAO_CHOUSHUI,-1);
        	end
        end, user_info.userId)
    end
end

--检查活动是否过期
function daxiao_lib.check_expire(time_check)
    local sys_time = os.time();	
    if (time_check ~= nil) then
        sys_time = time_check
    end
    local statime = timelib.db_to_lua_time(daxiao_lib.startime);
	local endtime = timelib.db_to_lua_time(daxiao_lib.endtime);
	if(sys_time > statime and sys_time <= endtime) then
		return 1
    else
        return 0
	end
end

--检查有效时间，限时问题int	0，活动无效（服务端也可不发）；1，活动有效
function daxiao_lib.check_datetime(time_check)
    local sys_time = os.time();	
    if (time_check ~= nil) then
        sys_time = time_check
    end
	local check_status = daxiao_lib.check_expire(sys_time)
    --只能在指定的时间段时玩
    local tableTime = os.date("*t",sys_time);
	local nowHour  = tonumber(tableTime.hour);
	--如果有设定开游戏的时间，就看一下是不是在允许的时间范围里
	if(check_status==1)then
        for k,v in pairs(daxiao_lib.open_time) do
            for k1, v1 in pairs(v) do
                if(nowHour == v1)then
    				return 1
    			end
            end
		end
		return 0
	end
	--活动时间过去了
	return 0;
end

daxiao_lib.on_recv_refresh_buy_yinpiao = function(buf)
    local user_info = daxiao_hall.get_user_info_by_key(daxiao_hall.get_user_key(buf));	
    daxiao_lib.refresh_buy_yinpiao(user_info)
end

daxiao_lib.refresh_buy_yinpiao = function(user_info)
    if not user_info then return end;
    local sql="select id, gold_num, gold_type from user_exchange_gold where user_id=%d and (gold_type = 1 or gold_type = 2)"
	sql=string.format(sql,user_info.userId)
    dblib.execute(sql, function(dt) 
        if (dt and #dt > 0) then
            local id_info = ""
            for k, v in pairs(dt) do
                if (v.gold_type == 1) then
                    xpcall(function()daxiao_lib.add_yinpiao(user_info.userId, v.gold_num, 0, 1) end, throw)
                elseif (v.gold_type == 2) then
                    xpcall(function()daxiao_lib.add_exyinpiao(user_info.userId, v.gold_num, 0, 1) end, throw)
                end
                if (id_info ~= "")then
                    id_info = id_info..","
                end
                id_info = id_info..v.id                
            end
            sql = "delete from user_exchange_gold where id in("..id_info..")"
            dblib.execute(sql, nil, user_info.userId)
        end
    end, user_info.userId)
end

--接收购买银票
daxiao_lib.on_recv_buy_yinpiao = function(buf)
    if (daxiao_lib.is_valid_room()~=1) then return end
	local user_info = daxiao_hall.get_user_info_by_key(daxiao_hall.get_user_key(buf));	
   	if not user_info then return end;
   	--收到银票
   	local buy_type=buf:readInt(); --1购买 2.取出
    local buy_yinpiao = buf:readInt(); --银票数量
        
   	if ((user_info.vip_level < 1 and buy_type == 1) or buy_yinpiao <= 0 or buy_type ~= 2) then
--   			netlib.send(function(buf)
--	            buf:writeString("DVDEXCG");
--	            buf:writeInt(-1);		--兑换方式标识，1，购买， 2，取出， 0，为兑换错误   3，坐下时不能购买
--	            buf:writeInt(0);		--兑换银票数量
--	        end,user_info.ip,user_info.port);
   		return
   	end
   	
   	--发送购买银票结果
	local function send_buy_yinpiao_result(user_info, result,yinpiao_count)
		netlib.send(function(buf)
	            buf:writeString("DVDEXCG");
	            buf:writeInt(result);		--兑换方式标识，1，购买， 2，取出， 0，为兑换错误   3，坐下时不能购买
	            buf:writeInt(yinpiao_count);		--兑换银票数量
	        end,user_info.ip,user_info.port);
    end
   	--如果服务器掉线了，那么就不能存取银票
    if(user_info.yinpiao_count==nil)then
    	--发送取银票结果
    	result = 0
		send_buy_yinpiao_result(user_info, result, buy_yinpiao)
    	return
    end
    
    --身上没银票的话，不允许取
    if(buy_type==2 and user_info.yinpiao_count==0)then
    	--发送取银票结果
    	result = 0
		send_buy_yinpiao_result(user_info, result, buy_yinpiao)
    	return
    end
    --如果身上的银票比要取的银票少，就不能取。如果初始值是0或nil，所以取的时间只需要判断内存，没判断数据库
    if(buy_type==2 and user_info.yinpiao_count<buy_yinpiao)then
    	--发送取出银票结果
    	result = 0
		send_buy_yinpiao_result(user_info, result, buy_yinpiao)
    	return
    end
    --如果是取出，就要用*-1
    local temp_flag=1
    if(buy_type==2)then
    	temp_flag=-1
   	end
   	
    --加减筹码
    local choushui_gold=0
    --如果是取出，要扣5%的抽水,存入的话，不抽水
   	local yinpiao_choushui=1
   	local yinpiao_rate=10000
   	if (gamepkg.name == "daxiao") then
   		yinpiao_rate = daxiao_adapt_lib.tex_yipiao_rate
   	else
   		yinpiao_rate = daxiao_adapt_lib.qp_yipiao_rate
   	end
   	
   	if(buy_type==2)then --取出
   		yinpiao_choushui=1-daxiao_lib.choushui_info
   		choushui_gold=daxiao_adapt_lib.tex_yipiao_rate * buy_yinpiao*daxiao_lib.choushui_info
   	end  	
    
    --存的时候yinpiao_choushui==1，取的时候是0.95(用来扣抽水）
    local buy_gold = daxiao_adapt_lib.tex_yipiao_rate * buy_yinpiao*yinpiao_choushui
    local can_use_gold = 0 --daxiao_lib.calc_can_use_gold(user_info) --计算能用的钱,因为德州的userinfo.chouma有些问题，所以先不用这个机制
    
    --如果是购买银票，就要看一下钱够不够
    if(user_info.site==nil)then
		can_use_gold = user_info.gamescore
    end

	--先加减钱，再加减银票    
	--德州
	if (gamepkg.name == "daxiao") then
	  if buy_type == 1 then
	    usermgr.addgold(user_info.userId, -buy_gold*temp_flag, choushui_gold, g_GoldType.daxiao_gold, g_GoldType.daxiao_choushui,-1,nil,999,buy_yinpiao);
	  else
	    usermgr.addgold(user_info.userId, -buy_gold*temp_flag, choushui_gold, g_GoldType.daxiao_gold_sell, g_GoldType.daxiao_choushui,-1,nil,999,buy_yinpiao);
	  end
		
	else
		--棋牌
		usermgr.addgold(user_info.userId, -buy_gold*temp_flag, choushui_gold, tSqlTemplete.goldType.DAXIAO_GOLD, tSqlTemplete.goldType.DAXIAO_CHOUSHUI,-1);
	end
  	daxiao_lib.add_yinpiao(user_info.userId,buy_yinpiao*temp_flag,0,buy_type)	
	
	--通知客户端存取银票的结果
	send_buy_yinpiao_result(user_info, buy_type, buy_yinpiao)	
end


--更新玩家的投注信息
function daxiao_lib.update_bet_info(userId,area_id,yinpiao_bet)
	local user_info=daxiao_hall.get_user_info(userId)
	if(user_info == nil)then return end
	--更新字符串中对应位置的值
	local update_bet=function(bet_info,area_id,yinpiao_bet)
		if(bet_info==nil or bet_info=="")then
			bet_info=daxiao_lib.org_bet_info;	
		end
		local tmp_tab=split(bet_info,",")
		local tmp_str=""
		local tmp_bet=0
		tmp_bet=tonumber(tmp_tab[area_id])

		if(tmp_bet==nil)then
			TraceError("error bet_info="..bet_info)
		end
		tmp_bet=tmp_bet+yinpiao_bet

		tmp_tab[area_id]=tostring(tmp_bet)
	
		for i=1,#tmp_tab do
			tmp_str=tmp_str..","..tmp_tab[i]
		end
		
		--更新下注的情况
		local tmp_bet_info=string.sub(tmp_str,2)
		local user_info=daxiao_hall.get_user_info(userId)
		local sql="update user_daxiao_info set bet_info='%s',bet_id='%s' where user_id=%d;commit; "
		sql=string.format(sql,tmp_bet_info,daxiao_lib.bet_id,userId)

		dblib.execute(sql, nil, userId)
		return tmp_bet_info --去掉第1个逗号后返回
	end
	
	--更新玩家的投注信息
	local tmpstr=""
	 
   	--加入游戏信息
   	local bufftable ={		 				
		 				userId = user_info.userId,	--用户Id
                        nick = user_info.nick,
                        ip = user_info.ip,
                        port = user_info.port,
		 				bet_info = user_info.bet_info or daxiao_lib.org_bet_info, --玩家投注的信息		 				
					}
					
	local already_join_game=0 --是否已加入了游戏
	
	--如果已加入过游戏，就更新一下投注信息
	for k,v in pairs(daxiao_lib.daxiao_game_info) do
		if(v.userId==user_info.userId)then
			already_join_game=1
			v.ip = user_info.ip
			v.port = user_info.port
			break
		end
	end
	
	--将玩家游戏信息插入到记录表中
	if(already_join_game==0)then
		table.insert(daxiao_lib.daxiao_game_info,bufftable)
	end
	
	for k,v in pairs (daxiao_lib.daxiao_game_info) do
		if(v~=nil and v.userId==userId)then

			v.bet_info=update_bet(v.bet_info,area_id,yinpiao_bet)
			tmpstr=v.bet_info
		end
	end
	return tmpstr
end

--接收下注
function daxiao_lib.on_recv_xiazhu(buf)
	local user_info = daxiao_hall.get_user_info_by_key(daxiao_hall.get_user_key(buf));	
   	if not user_info then return end;
   	local time_status = daxiao_lib.check_datetime()
   	--过了时间不能下
   	if (time_status==0) then return end
   	if user_info.vip_level < 1 then
--   		netlib.send(function(buf)
--	            buf:writeString("DVDBET");
--	            buf:writeInt(-1);		--下注结果，0，活动无效， 1，下注成功， 2，下注失败，银票不足
--	        end,user_info.ip,user_info.port);
   		return
   	end
   	--如果快到23点的前3分钟不能下注
   	local tableTime = os.date("*t",os.time());
    local nowYear = tonumber(tableTime.year);
    local nowMonth = tonumber(tableTime.month);
    local nowDay = tonumber(tableTime.day);
    local now_hour = tonumber(tableTime.hour);
	local db_time = nowYear.."-"..nowMonth.."-"..nowDay.." "..now_hour..":00:00"
    local next_time = timelib.db_to_lua_time(db_time)+60*60

    --if(daxiao_lib.check_datetime(next_time) == 0 and next_time <= os.time()+60*3)then
	--	return
	--end
	
   	if (daxiao_lib.is_valid_room()~=1) then return end
	
   	--下注数据
   	local area_id = buf:readInt();--区域id
   	local yinpiao_bet = buf:readInt();--该区域下的银票数量
   	
   	--返回客户端下注结果
   	local send_bet_result=function(user_info,result)
   		netlib.send(function(buf)
	            buf:writeString("DVDBET");
	            buf:writeInt(result);		--下注结果，0，活动无效， 1，下注成功， 2，下注失败，银票不足
	        end,user_info.ip,user_info.port);
	    local sql = "insert into log_daxiao_xiaozhu(user_id, area_id, yinpiao_bet, status, bet_id, sys_time) value(%d, %d, %d, %d, %d, now())"
		sql = string.format(sql, user_info.userId, area_id, yinpiao_bet, result, daxiao_lib.bet_id)
		dblib.execute(sql, function(dt) end, user_info.userId)	        
   	end
   	
   	--本局结束前10秒不能让玩家下注
 	if(daxiao_lib.fajiang_time-os.time()<10 ) then
		send_bet_result(user_info,3)
   		return
	end
	
	--超过区域下注上限
 	if(yinpiao_bet>daxiao_lib.limit_local_bet) then
 		send_bet_result(user_info,4)
   		return
 	end
 	
 	--个人的总下注
 	if(user_info.bet_num_count==nil)then
 		user_info.bet_num_count = 0
 	end
 	
 	--总下注超过个人上限了
   	if(user_info.bet_num_count>daxiao_lib.limit_bet-yinpiao_bet)then
   	 	send_bet_result(user_info,5)
   		return
   	end
   	
   	--判断银票
   	if(user_info.yinpiao_count == nil or (user_info.yinpiao_count + user_info.ex_yinpiao_count) == 0 or 
       ((user_info.yinpiao_count + user_info.ex_yinpiao_count) <yinpiao_bet))then
   		send_bet_result(user_info,2)
   		return
   	end

  	--扣玩家身上的银票，如果成功就返回客户端成功，不然就通知说失败
	if daxiao_lib.add_yinpiao(user_info.userId,-yinpiao_bet,0,3) then
		--扣成了，就更新下注的字段，通知客户端下注成功
	   	user_info.bet_num_count = user_info.bet_num_count + yinpiao_bet
  		user_info.bet_info=daxiao_lib.update_bet_info(user_info.userId,area_id,yinpiao_bet)
		user_info.bet_id=daxiao_lib.bet_id
		send_bet_result(user_info,1)
	else
		send_bet_result(user_info,2)
	end	
	
end


--随机产生3个数字
function daxiao_lib.get_random_num(num_1,num_2,num_3)
	--以时间作为随机数种子
	local t = os.time() 
	math.randomseed(t)
	
	--默认是1到1万的随机数取6的余数
	local tmp_num1=math.random(1,3333)%6+1
	local tmp_num2=math.random(3334,6666)%6+1
	local tmp_num3=math.random(6667,10000)%6+1
	local tmp_nouse_num=0
	local buf_tab = daxiao_lib.gen_counts()

	local rand_type=math.random(1,t)%5+1 --有5种随机数算法，以后再加
	if(rand_type==1)then  --取1到32000的随机数再取余
		tmp_num1=math.random(20000,30000)%6+1
		tmp_num2=math.random(10000,20000)%6+1
		tmp_num3=math.random(1,10000)%6+1
	elseif(rand_type==2)then
		tmp_num1=buf_tab[math.random(10, 60)]
		tmp_num2=buf_tab[math.random(10, 60)]
		tmp_num3=buf_tab[math.random(10, 60)]
	elseif(rand_type==3)then
		tmp_num1=buf_tab[math.random(15, 60)]
		tmp_num2=buf_tab[math.random(15, 60)]
		tmp_num3=buf_tab[math.random(15, 60)]
	elseif(rand_type==4)then
		tmp_nouse_num=math.random(1,10000)
		tmp_nouse_num=math.random(1,10000)
		tmp_num1=math.random(1,t)%6+1
		tmp_nouse_num=math.random(1,10000)
		tmp_nouse_num=math.random(1,10000)
		tmp_num2=math.random(20000,30000)%6+1
		tmp_nouse_num=math.random(1,10000)
		tmp_nouse_num=math.random(1,10000)		
		tmp_num3=math.random(10000,30000)%6+1	
	end	
	
	if(num_1==nil or num_2==nil  or num_3==nil)then
		--取1到10000的随机数与6去余，得到的值相对随机一点，直接用lua取1到6随机数有些问题
		num_1 = tmp_num1
		num_2 = tmp_num2
		num_3 = tmp_num3
    end
    

    if (num_1 == num_2 and num_2 == num_3) then
        num_1 = math.random(1, 6)
        num_2 = math.random(1, 6)
        num_3 = math.random(1, 6)
    end
	return num_1,num_2,num_3
end

function daxiao_lib.gen_counts()
	local buf_tab={}
	for i=1, 60 do
		table.insert(buf_tab, math.random(1, 6))
	end
	return buf_tab
end

--给某个玩家加减银票
--userId玩家编号
--yinpiao加减的银票数量
--flag是不是通知客户端0不通知1通知
--yinpiao_type 是买银票，还是卖银票，还是游戏中银票变化
function daxiao_lib.add_yinpiao(userId,yinpiao,flag,yinpiao_type)
	if (daxiao_lib.is_valid_room()~=1) then return end
	
	local user_info=daxiao_hall.get_user_info(userId);
	local sql=""
	
	if(user_info==nil)then 
   		flag=1 --玩家投注后下线了，就不用向客户端发了
    end
    local add_ex_yinpiao = 0  --需要修改的扩展银票
    local add_yinpiao = yinpiao  --需要修改的原始银票
    --如果玩家在线，就要改内存
	if(user_info~=nil)then
		--初始化
		if(user_info.yinpiao_count==nil) then user_info.yinpiao_count=0 end
		--给玩家加减银票
        if (yinpiao < 0 and yinpiao_type == 3) then --玩家下注，检测银票是否够下注
            if (user_info.ex_yinpiao_count + yinpiao >= 0) then
                user_info.ex_yinpiao_count = user_info.ex_yinpiao_count + yinpiao
                add_ex_yinpiao = yinpiao
                add_yinpiao = 0
            else
                add_ex_yinpiao = -user_info.ex_yinpiao_count
                add_yinpiao = user_info.ex_yinpiao_count + yinpiao
                user_info.ex_yinpiao_count = 0
            end
        end
		user_info.yinpiao_count=user_info.yinpiao_count+add_yinpiao
		if(user_info.yinpiao_count<0)then
			user_info.yinpiao_count=0
			return false
		end
	end
	
	--改数据库
	local tmp_bet_info=daxiao_lib.org_bet_info;	
	local tmp_nick=""
	if(user_info~=nil)then 
		tmp_bet_info=user_info.bet_info
		tmp_nick=string.trans_str(user_info.nick)
    end
    --这里不晓得，为啥有时候为空
	if (tmp_bet_info == nil) then
        tmp_bet_info=daxiao_lib.org_bet_info;
    end
	sql="insert into user_daxiao_info(user_id,yinpiao_count,bet_info,bet_id,user_nick) value(%d,%d,'%s','%s','%s') ON DUPLICATE KEY UPDATE yinpiao_count=yinpiao_count+%d,bet_id='%s',ex_yinpiao_count=ex_yinpiao_count+%d;commit; "
	sql=string.format(sql,userId,add_yinpiao,tmp_bet_info,daxiao_lib.bet_id,tmp_nick,add_yinpiao,daxiao_lib.bet_id,add_ex_yinpiao)
	dblib.execute(sql, nil, userId)
	
	--写加减银票的日志
	local tmp_yinpiao_count=-1  --因为发奖也会改银票，这时玩家可能已下线了，这时就不写玩家身上有多少钱了吧。以后有空再改进
	if(user_info~=nil)then 
		tmp_yinpiao_count=user_info.yinpiao_count or 0
    end

    local tmp_ex_yinpiao_count=-1  --因为发奖也会改银票，这时玩家可能已下线了，这时就不写玩家身上有多少钱了吧。以后有空再改进
	if(user_info~=nil)then 
		tmp_ex_yinpiao_count=user_info.ex_yinpiao_count or 0
	end
	
    if (add_ex_yinpiao ~= 0) then
        sql="insert into log_user_ex_yipiao(user_id,before_ex_yinpiao,add_yinpiao,yinpiao_type,sys_time)value(%d,%d,%d,%d,now());commit;"
    	sql=string.format(sql,userId,tmp_ex_yinpiao_count,add_ex_yinpiao,yinpiao_type)
    	dblib.execute(sql)
    end
	sql="insert into log_user_yipiao(user_id,before_yinpiao,add_yinpiao,yinpiao_type,sys_time)value(%d,%d,%d,%d,now());commit;"
	sql=string.format(sql,userId,tmp_yinpiao_count,yinpiao,yinpiao_type)
	dblib.execute(sql)
	if(flag==nil or flag~=1)then
		netlib.send(function(buf)
	            buf:writeString("DVDYPNUM"); --通知客户端，更新玩家银票数
	            buf:writeInt(user_info.yinpiao_count); --玩家银票数
                buf:writeInt(user_info.ex_yinpiao_count); --玩家银票数
	            end,user_info.ip,user_info.port)
    end 
	return true
end

function daxiao_lib.add_exyinpiao(userId, add_ex_yinpiao, flag, yinpiao_type)
	if (daxiao_lib.is_valid_room()~=1) then return end
	local user_info=daxiao_hall.get_user_info(userId);
	local sql=""
	if(user_info~=nil)then
		user_info.ex_yinpiao_count = user_info.ex_yinpiao_count or 0 
		user_info.ex_yinpiao_count = user_info.ex_yinpiao_count + add_ex_yinpiao
	end
	--改数据库
	sql="insert into user_daxiao_info(user_id,yinpiao_count,bet_info,bet_id,user_nick,ex_yinpiao_count) value(%d,%d,'%s','%s','%s',%d) ON DUPLICATE KEY UPDATE ex_yinpiao_count=ex_yinpiao_count+%d;commit; "
	sql=string.format(sql,userId,user_info.yinpiao_count or 0, "", 0, "", add_ex_yinpiao,add_ex_yinpiao)
	dblib.execute(sql, nil, userId)
	
	--写加减银票的日志
	local tmp_yinpiao_count=-1  --因为发奖也会改银票，这时玩家可能已下线了，这时就不写玩家身上有多少钱了吧。以后有空再改进
	if(user_info~=nil)then 
		tmp_yinpiao_count=user_info.yinpiao_count or 0
    end

    local tmp_ex_yinpiao_count=-1  --因为发奖也会改银票，这时玩家可能已下线了，这时就不写玩家身上有多少钱了吧。以后有空再改进
	if(user_info~=nil)then 
		tmp_ex_yinpiao_count=user_info.ex_yinpiao_count
	end
	
    if (add_ex_yinpiao ~= 0) then
			sql="insert into log_user_ex_yipiao(user_id,before_ex_yinpiao,add_yinpiao,yinpiao_type,sys_time)value(%d,%d,%d,%d,now());commit;"
			sql=string.format(sql,userId,user_info.ex_yinpiao_count,add_ex_yinpiao,yinpiao_type)
			dblib.execute(sql)
    end
    netlib.send(function(buf)
            buf:writeString("DVDYPNUM"); --通知客户端，更新玩家银票数
            buf:writeInt(user_info.yinpiao_count or 0); --玩家银票数
            buf:writeInt(user_info.ex_yinpiao_count or 0); --玩家银票数
    end,user_info.ip,user_info.port)    
end

function daxiao_lib.fajiang()
	local all_zj_info={}; --所有的本次中奖信息
	local sql="";
	local user_zj_info={}; --玩家分区域的中奖信息
	local tmp_user_info; --为了给客户端发玩家的昵称，所以引入这个变量
	
	local win_yinpiao=0 --赚到的银票
	local get_yinpiao=0 --一共应该有的银票
	local nick_name=""
	local gain_most_info={} --这一轮赚得最多的10个人
    local round_bet_info = ""  --一局输赢的情况
	for k,v in pairs (daxiao_lib.daxiao_game_info) do
		local buf_zj_info={};
		--给每个中奖的人发奖
		win_yinpiao,get_yinpiao,user_zj_info=daxiao_lib.calc_win_yinpiao(v.bet_info,daxiao_lib.num1,daxiao_lib.num2,daxiao_lib.num3)
		--[[tmp_user_info=daxiao_hall.get_user_info(v.userId) 
		if (tmp_user_info ~= nil and tmp_user_info.bet_num_count > 0) then
            if (round_bet_info ~= "") then
                round_bet_info = round_bet_info.."|"
            end
            round_bet_info = round_bet_info..v.userId..","..tmp_user_info.bet_num_count..","..win_yinpiao
        end--]]
		--得到有几个人中奖，这些人赚了多少钱的信息
		if(win_yinpiao>0)then					
		    daxiao_lib.add_yinpiao(v.userId, get_yinpiao,1,4);--这里传get_yinpiao，因为中了奖之后本金也要还给玩家						
            netlib.send(function(buf)
                buf:writeString("DVDMYWIN"); --通知客户端，玩家的中奖记录
                buf:writeInt(win_yinpiao); --中奖的数量		           
            end, v.ip, v.port)
			buf_zj_info.userId=v.userId
			buf_zj_info.nick=v.nick
			buf_zj_info.win_yinpiao=win_yinpiao
			table.insert(all_zj_info,buf_zj_info)
        end
        xpcall(function() daxiao_lib.send_zj_info(user_zj_info, v) end, throw)
	end
    daxiao_adapt_lib.record_round_info(round_bet_info)
	--通知客户端，玩家的中奖记录
	--按照win_yinpiao排名
	if(all_zj_info~=nil and #all_zj_info>2)then

		table.sort(all_zj_info, 
		      function(a, b)
			     return a.win_yinpiao > b.win_yinpiao		                   
		end)
	end

	for k,v in pairs (daxiao_lib.daxiao_game_info) do
		local user_info=daxiao_hall.get_user_info(v.userId)
		if(user_info~=nil)then				
			netlib.send(function(buf)
	            buf:writeString("DVDHISTORY"); --通知客户端，玩家的中奖记录
	           
	            local mc_len=10 --最多显示前10名
	            local send_len=#all_zj_info or 0
	            if(send_len>mc_len)then send_len=mc_len end
	            buf:writeInt(send_len); --中奖的玩家数量
	            if(send_len>0)then
		            for i=1,send_len do
		            	buf:writeInt(all_zj_info[i].userId) --玩家ID
		            	buf:writeString(all_zj_info[i].nick or "")   --玩家昵称
		            	buf:writeInt(all_zj_info[i].win_yinpiao or 0) --玩家中奖的银票数量
		            end
	            end
	            end,user_info.ip,user_info.port) 
		end
	end
end

function daxiao_lib.send_zj_info(user_zj_info, user_game_info)
    --发送骰子数据，理论上1个协议就能全发过去了，不过客户端以前机制有些问题，所以要有DVDPRIZE和DVDMYWIN 2个协议。
    netlib.send(function(buf)
        buf:writeString("DVDPRIZE")
        buf:writeInt(daxiao_lib.num1)
        buf:writeInt(daxiao_lib.num2)
        buf:writeInt(daxiao_lib.num3)
        buf:writeInt(daxiao_lib.total_num)
        buf:writeInt(29)
        for i=1,29 do
            local tmp_flag=0
            if(daxiao_lib.kajiang_table==nil)then
                TraceError("daxiao_lib.kajiang_table nil")
            end
            for k,v in pairs (daxiao_lib.kajiang_table)do
                if(i==v)then
                    tmp_flag=1 --是否是开奖位
                    break
                end
            end
    
            if(user_zj_info==nil)then
                TraceError("user_zj_info nil:"..i)
            end
            buf:writeInt(i) --该玩家赢的区域
            local tmpnum=0
            
            for k,v in pairs (user_zj_info) do
                if(v.area_id==i)then				            	
                    tmpnum=v.area_win_yinpiao --该玩家赢的银票（包含本金）
                    break	
                end			            		
            end
            buf:writeInt(tmpnum)
            buf:writeByte(tmp_flag) --开奖位
            
        end
    end, user_game_info.ip, user_game_info.port) 
end

function daxiao_lib.create_open_num()

 	--如果gm指定了号，就开指定的号，这把中了之后要把值换回来，防止一直开一个号
 	if(daxiao_lib.gm_num1~=nil and daxiao_lib.gm_num1~=0)then
 		daxiao_lib.num1,daxiao_lib.num2,daxiao_lib.num3 = daxiao_lib.get_random_num(daxiao_lib.gm_num1,daxiao_lib.gm_num2,daxiao_lib.gm_num3)
 		daxiao_lib.gm_num1=0
 		daxiao_lib.gm_num2=0
 		daxiao_lib.gm_num3=0
	else
 		daxiao_lib.num1,daxiao_lib.num2,daxiao_lib.num3 = daxiao_lib.get_random_num()	--获取随机数
 	end
 	
	daxiao_lib.total_num=daxiao_lib.num1+daxiao_lib.num2+daxiao_lib.num3
	--加入历史表中
	if(#daxiao_lib.history < daxiao_lib.history_len)then		--如果长度小于6，直接加入
		local bufftable ={
					  	    num_1 = daxiao_lib.num1, 
		                    num_2 = daxiao_lib.num2,
		                    num_3 = daxiao_lib.num3,
		                    total_num = daxiao_lib.total_num,   
		                }	                
		table.insert(daxiao_lib.history,bufftable)
	else
		table.remove(daxiao_lib.history,1)	--删除第一条		
		local bufftable ={
					  	    num_1 = daxiao_lib.num1, 
		                    num_2 = daxiao_lib.num2,
		                    num_3 = daxiao_lib.num3,
		                    total_num = daxiao_lib.total_num,   
		                }	                
		table.insert(daxiao_lib.history,bufftable)
	end
	
	--写历史数据日志
 	sql="insert into log_daxiao_history(num1,num2,num3,total_num,bet_id,sys_time) value (%d,%d,%d,%d,'%s',now());commit;";
 	sql=string.format(sql,daxiao_lib.num1,daxiao_lib.num2,daxiao_lib.num3,daxiao_lib.total_num,daxiao_lib.bet_id);
 	dblib.execute(sql);
end

--开局
--每10分钟进来一次，要做的事如下：
--1. 给上轮的人员发奖
--2. 初始化新的一轮用到的变量
--3. 写开奖日志
function daxiao_lib.start_game()
	if (daxiao_lib.is_valid_room()~=1) then return end


	
 	--初始化一局的信息
 	local function init_game_info()
 		local curr_time=os.time()
		--初始化开奖的时间		
	 	daxiao_lib.fajiang_time=curr_time+60*3
	 	
		local time_status=daxiao_lib.check_datetime()
		
	 	--初始化打开面板的人的列表
	 	for k,v in pairs (daxiao_lib.daxiao_game_info) do
	 		local user_info=daxiao_hall.get_user_info(v.userId)
	 		if(user_info~=nil)then
	 			user_info.bet_info=daxiao_lib.org_bet_info;
	 			user_info.bet_num_count = 0
	 			netlib.send(function(buf)
		            buf:writeString("DVDDATE");
		            buf:writeInt(time_status or 0);		--int	0，活动无效（服务端也可不发）；1，活动有效
		        	end,user_info.ip,user_info.port); 
	 		end			
	 	end
	 	daxiao_lib.daxiao_game_info = {}
	 	
	 	--初始化本轮的投注ID，年月日时分为组和的字段作为投注ID
	 	daxiao_lib.bet_id = os.date("%Y%m%d%H%M", curr_time)
	 	
	 	--更新最新的bet_id到参数表里，防止服务器重启时要退钱
	 	daxiao_lib.update_last_betid(daxiao_lib.bet_id)
	 	
	 	daxiao_lib.kajiang_table = {}
	 	
	 	daxiao_lib.all_user_bet_info = {}
	 	daxiao_lib.fajiang_lock = 0
 	end
 	
 		
 	--初始化新一轮的信息
 	init_game_info();
 	
end

--倒计时
function daxiao_lib.timer()	
    if (gamepkg.name == "daxiao") then
        daxiao_lib.open_time = daxiao_adapt_lib.tex_open_time
    else
        daxiao_lib.open_time = daxiao_adapt_lib.qp_open_time
    end

    if (daxiao_lib.is_valid_room()~=1) then return end
  
    local tableTime = os.date("*t",os.time());
    local nowYear = tonumber(tableTime.year);
    local nowMonth = tonumber(tableTime.month);
    local nowDay = tonumber(tableTime.day);
    local now_hour = tonumber(tableTime.hour);
	local db_time = nowYear.."-"..nowMonth.."-"..nowDay.." "..now_hour..":00:00"
	local next_time = timelib.db_to_lua_time(db_time) + 60*60
	
	if(daxiao_lib.check_expire() == 0 and daxiao_lib.send_huodong_expire == 0)then
		for k, v in pairs(daxiao_hall.user_list) do
			netlib.send(function(buf)
				buf:writeString("DVDEXPIRE")
			end, v.ip, v.port)
		end
		daxiao_lib.send_huodong_expire = 1
		return
    end
    local time_status = daxiao_lib.check_datetime()
    --if (time_status == 0) then return end
    --if(daxiao_lib.check_datetime(next_time) == 0 and os.time() + 60*3 >= next_time)then
    --    return
	--end
	daxiao_lib.send_huodong_expire = 0
    --3分钟开一局
    if(os.time() > daxiao_lib.fajiang_time)then
    	if daxiao_lib.fajiang_lock == 0 then --加一个内存锁，防止发多次奖
    		daxiao_lib.fajiang_lock = 1
        	daxiao_lib.create_open_num()
        	daxiao_lib.fajiang()
        end
        --开局(有个缺陷，刚开局会产生一组没人中过的数据
        if time_status ~= 0 then
        	daxiao_lib.start_game()
        end

        
    end
    
    if(os.time() > daxiao_lib.other_bet_time)then	 
        --开局(有个缺陷，刚开局会产生一组没人中过的数据
        daxiao_lib.send_other_bet_info()
    end
	math.random(1,10000)
end

--重启服务器了
function daxiao_lib.restart_server(e)
	if (daxiao_lib.is_valid_room()~=1) then return end
	if (gamepkg.name == "daxiao") then
        daxiao_lib.open_time = daxiao_adapt_lib.tex_open_time
    else
        daxiao_lib.open_time = daxiao_adapt_lib.qp_open_time
    end
	local param_str_value = "-1"
	--TraceError("daxiao_lib.restart_server")

	local function return_yinpiao(user_id,bet_info)
		if(user_id==-1 or bet_info=="-1")then return end
		local yin_piao=0;
		local tmp_bet_info={}
		tmp_bet_info=split(bet_info,",")   			
		for i=1,29 do
			yin_piao=yin_piao+tmp_bet_info[i]
		end
		--返还银票
		local sql="update user_daxiao_info set yinpiao_count=yinpiao_count+%d,bet_info='%s' where user_id=%d and bet_info<>'%s';commit;"
		sql=string.format(sql,yin_piao,daxiao_lib.org_bet_info,user_id,daxiao_lib.org_bet_info)
		dblib.execute(sql, nil, user_id)
		
		sql="insert into log_user_yipiao(user_id,before_yinpiao,add_yinpiao,yinpiao_type,sys_time)value(%d,%d,%d,%d,now());commit;"
		sql=string.format(sql,user_id,-1,yin_piao,6)
		dblib.execute(sql, nil, user_id)
	end
	
	local sql = "SELECT param_str_value FROM cfg_param_info WHERE param_key = 'DAXIAO_BETID' and room_id=%d"
	sql = string.format(sql,groupinfo.groupid);
	dblib.execute(sql,
    function(dt)
    	if dt and #dt > 0 then
    		param_str_value = dt[1]["param_str_value"]
    	else
    		param_str_value = "-1"
		end
		
	
    		--通过param_str_value（betid)给玩家退银票
    		sql="select user_id,bet_info from user_daxiao_info where bet_id='%s'"
    		sql=string.format(sql,param_str_value)
    		dblib.execute(sql,
			    function(dt)
			    	if dt and #dt > 0 then
			    		for i=1,#dt do
			    			
			    			local user_id=dt[i]["user_id"] or -1
			    			local bet_info=dt[i]["bet_info"] or "-1"
			    			TraceError("return_yinpiao(user_id,bet_info)="..user_id.." ###"..bet_info)
			    			return_yinpiao(user_id,bet_info)
			    			
			    		end
			    	end
			    end)
	end)
end

--更新最近的一次betid
function daxiao_lib.update_last_betid(betid)
	--更新数据库
	--TraceError("daxiao_lib.update_last_betid")
	local sql = "insert into cfg_param_info (param_key,param_str_value,room_id) value('DAXIAO_BETID','-1',%d) on duplicate key update param_str_value = '%s'";
	sql=string.format(sql, groupinfo.groupid,betid)
	dblib.execute(sql)
end
--其他玩家投注区域信息
function daxiao_lib.send_other_bet_info()
	local tmp_user_bet_info1={} --用作统计投注数量的临时变量
	local tmp_user_bet_info2={} --用来存放所有玩家投注数量的临时变量
	local tmp_bet_info=""
	local tmp_str=""
	local tmp_bet_num=daxiao_lib.org_bet_info
	tmp_user_bet_info2=split(tmp_bet_num,",")
	--得到所有人的投注信息放到tmp_user_bet_info2中
	for k,v in pairs (daxiao_lib.daxiao_game_info) do
   			tmp_bet_info=v.bet_info
   			if(tmp_bet_info==nil or tmp_bet_info=="")then
   				tmp_bet_info=daxiao_lib.org_bet_info
   			end
   			tmp_user_bet_info1=split(tmp_bet_info,",")   			
   			for i=1,29 do	   					
   				tmp_user_bet_info2[i]=tmp_user_bet_info2[i]+tmp_user_bet_info1[i]
   			end
	end
	
	daxiao_lib.all_user_bet_info=tmp_user_bet_info2
	
	--通知客户端，其他玩家投注结果（所有人减去自己）
	for k,v in pairs (daxiao_lib.daxiao_game_info) do
		local user_info=daxiao_hall.get_user_info(v.userId)
		if(user_info~=nil)then
			tmp_user_bet_info1=split(user_info.bet_info or daxiao_lib.org_bet_info,",")
			netlib.send(function(buf)
		    	buf:writeString("DVDOTHBET")
		    	buf:writeInt(29)    	
		    	for i=1,29 do
		    		buf:writeInt(i)
					local tmp_num2=tonumber(tmp_user_bet_info2[i]) or 0
					local tmp_num1=tonumber(tmp_user_bet_info1[i]) or 0				
		    		buf:writeInt(tmp_num2-tmp_num1)    		
		    	end
		    	end,user_info.ip,user_info.port)
	    end
     end
     
     --10秒之后才能再进来一次
     daxiao_lib.other_bet_time=os.time()+10
end

--发送历史表
function daxiao_lib.send_history(user_info,history_list)
	local send_len = 0
	if(history_list~=nil)then
	   send_len=#history_list	   
	end
	netlib.send(function(buf)
    	buf:writeString("DVDREC")
    
		 buf:writeInt(send_len)
			if(send_len < daxiao_lib.history_len)then
				for i=1,send_len do
			        buf:writeInt(history_list[i].num_1) 
			        buf:writeInt(history_list[i].num_2) 
			        buf:writeInt(history_list[i].num_3)  
			        buf:writeInt(history_list[i].total_num) 
		        end
			else
		        for i=1,daxiao_lib.history_len do
			        buf:writeInt(history_list[i].num_1)	 
			        buf:writeInt(history_list[i].num_2)  
			        buf:writeInt(history_list[i].num_3)  
			        buf:writeInt(history_list[i].total_num)  
		        end
		    end
     	end,user_info.ip,user_info.port) 
end

function daxiao_lib.do_open_game(user_info)
	--local user_info = daxiao_hall.get_user_info_by_key(daxiao_hall.get_user_key(buf));	
   	if not user_info then return end;
   	
   	
   	
   	--通知客户端，面板信息
   	local send_dvd_info = function(user_info)
   		
   		local bet_info=user_info.bet_info or daxiao_lib.org_bet_info
   		local tmp_user_bet_info=split(bet_info,",")

   		netlib.send(function(buf)
            buf:writeString("DVDOPEN"); --通知客户端，更新玩家银票数
            buf:writeInt(user_info.yinpiao_count); --玩家银票数
            buf:writeInt(user_info.ex_yinpiao_count); --玩家银票数
            buf:writeInt(29); --默认为29个区域都传回客户端。因为大多数情况下所有区域都可能有人投
			for i=1,29 do
				buf:writeInt(i) --区域id
				local tmpnum=0
				if(daxiao_lib.all_user_bet_info~=nil and #daxiao_lib.all_user_bet_info~=0)then
					local tmp_num1=tonumber(daxiao_lib.all_user_bet_info[i]) or 0
					local tmp_num2=tonumber(tmp_user_bet_info[i]) or 0
					tmpnum=tmp_num1-tmp_num2
				end
				buf:writeInt(tmpnum) --其他玩家 投注的银票数量
				buf:writeInt(tonumber(tmp_user_bet_info[i]) or 0) --玩家自己 投注的银票数量
				
			end            
            end,user_info.ip,user_info.port) 
   	end
	
   	local dx_status=daxiao_lib.check_datetime()
   	if daxiao_lib.fajiang_lock == 0 then
   		dx_status = 1
   	end
   	netlib.send(function(buf)
            buf:writeString("DVDDATE");
            buf:writeInt(dx_status or 0);		--int	0，活动无效（服务端也可不发）；1，活动有效
        end,user_info.ip,user_info.port);
    
    if(dx_status==0)then 
    	send_dvd_info(user_info)
    	return 
    end
   	--加入游戏信息
   	local bufftable ={		 				
		 				userId = user_info.userId,	--用户Id
                        ip = user_info.ip,
                        port = user_info.port,
                        nick = user_info.nick,
		 				bet_info = user_info.bet_info or daxiao_lib.org_bet_info, --玩家投注的信息		 				
					}
					
	local already_join_game=0 --是否已加入了游戏
	
	--如果已加入过游戏，就更新一下投注信息
	for k,v in pairs(daxiao_lib.daxiao_game_info) do
		if(v.userId==user_info.userId)then
			already_join_game=1
			v.ip = user_info.ip
            v.port = user_info.port
			break
		end
	end
	--将玩家游戏信息插入到记录表中
	if(already_join_game==0)then
		table.insert(daxiao_lib.daxiao_game_info,bufftable)
	end

   	--给客户端发开奖时间还差多少秒
   	daxiao_lib.send_remain_time(user_info,daxiao_lib.fajiang_time)
   	
   	--给客户端发开奖历史
   	daxiao_lib.send_history(user_info,daxiao_lib.history)
   	
   	--通知客户端，面板信息
   	send_dvd_info(user_info)
end
--请求服务端，剩余开奖时间
function daxiao_lib.on_recv_query_time(buf)
	local user_info = daxiao_hall.get_user_info_by_key(daxiao_hall.get_user_key(buf));	
   	if not user_info then return end;
   	daxiao_lib.send_remain_time(user_info,daxiao_lib.fajiang_time)
end

--告诉客户端还差多少秒
function daxiao_lib.send_remain_time(user_info,fajiang_time)
	local curr_time = os.time();
	local remain_time = fajiang_time-curr_time;
	netlib.send(function(buf)
        buf:writeString("DVDTIME"); --通知客户端，剩余开奖时间
        buf:writeInt(remain_time);		--剩余开奖时间
      
    end,user_info.ip,user_info.port);
end

--客户端指定开某个数，用来调试
function daxiao_lib.on_recv_gm_num(buf)
	local user_info = daxiao_hall.get_user_info_by_key(daxiao_hall.get_user_key(buf));	
   	if not user_info then return end;
   	
   	--是否GM
	local function is_gm(user_id)
		if type(user_id) ~= string then
			user_id = tostring(user_id)
		end
		local tmp_gm={}
		if (gamepkg.name == "daxiao") then
			tmp_gm=daxiao_lib.tex_gm_id_arr
		else		
			tmp_gm=daxiao_lib.qp_gm_id_arr
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
    local gm_num2=buf:readInt(); --数字1
    local gm_num3=buf:readInt(); --数字1
    if(gm_num1==nil or gm_num2==nil or gm_num3==nil)then
    	return
    end

    daxiao_lib.gm_open_num(gm_num1,gm_num2,gm_num3)
end

--gm指令增加三分钟账号
daxiao_lib.gm_cmd = function(e)
    if (e.data["cmd"] == "add_dx_user" and e.data["args"][1] ~= nil) then        
        daxiao_lib.add_yinpiao(tonumber(e.data["args"][1]), 0, 0, 0)
    end
end

--协议命令
cmd_daxiao_handler = 
{
    ["DVDDATE"] = daxiao_lib.on_recv_check_time, --请求活动时间状态
    ["DVRFYP"] = daxiao_lib.on_recv_refresh_buy_yinpiao, --接收卖出银票，覆盖了adapter里面相同的定义
    ["DVDBET"] = daxiao_lib.on_recv_xiazhu, --接收下注
    ["DVDEXCG"] = daxiao_lib.on_recv_buy_yinpiao, --请求刷新银票信息
    ["DVDTIME"] = daxiao_lib.on_recv_query_time, --请求服务端，剩余开奖时间
    ["DVDGMNUM"] = daxiao_lib.on_recv_gm_num, --请求服务端，剩余开奖时间
}

--加载插件的回调
for k, v in pairs(cmd_daxiao_handler) do 
	cmdHandler[k] = v
end


--eventmgr:addEventListener("h2_on_user_login", daxiao_lib.on_after_user_login);
eventmgr:addEventListener("timer_second", daxiao_lib.timer);
eventmgr:addEventListener("on_server_start", daxiao_lib.restart_server);
eventmgr:addEventListener("gm_cmd", daxiao_lib.gm_cmd)

