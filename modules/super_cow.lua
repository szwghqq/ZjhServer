TraceError("init super_cow_lib...")

if super_cow_lib and super_cow_lib.timer then
	eventmgr:removeEventListener("timer_second", super_cow_lib.timer);
end

if super_cow_lib and super_cow_lib.on_server_start then
	eventmgr:removeEventListener("on_server_start", super_cow_lib.on_server_start); 
end


if not super_cow_lib then
    super_cow_lib = _S
    {    	   
        check_datetime = NULL_FUNC, --检查时间
		check_can_game = NULL_FUNC,	--检查是不是能玩
		on_recv_check_status = NULL_FUNC, --客户端查是不是能玩
		on_recv_query_time = NULL_FUNC, --客户端检查剩余时间
		on_recv_open_game = NULL_FUNC, --打开面板
		init_poke_box = NULL_FUNC, --初始化牌盒
		fapai = NULL_FUNC, --发牌
		get_card_list = NULL_FUNC, --得到指定数量的牌		
    	timer=NULL_FUNC, --定时器
        on_server_start=NULL_FUNC, --系统启动
    	get_real_num = NULL_FUNC, --得到真实的牌号，比如J是11
    	get_cow_num = NULL_FUNC, --得到牛牛的牌号，比如J是10
    	get_flower = NULL_FUNC, --得到牌的花色
		is_valid_room = NULL_FUNC, ----是不是在规定的房间玩牌
		cal_poke_count = NULL_FUNC, --看一下这组排好序的牌，有几个poke_len长度的牌，比如poke_len=2，返回2，代表葫芦
		checkisfourbomb = NULL_FUNC, --检查是不是炸弹
		sort_pokes = NULL_FUNC, --把牌按从小到大排序
		get_cow_paixin = NULL_FUNC, --得到牛牛的牌型
		wu_niu_shun = NULL_FUNC, --无牛顺
		wu_xiao_fu = NULL_FUNC,--五小福
		is_gold_cow = NULL_FUNC, --是不是金牛
		is_hulu = NULL_FUNC, --是不是葫芦
		is_tonghua = NULL_FUNC, --是不是同花
		is_shun = NULL_FUNC, --是不是顺子
		get_paixin=NULL_FUNC, --得到牌型
		send_supercow_gold = NULL_FUNC, --返回玩家的游戏币
		send_caichi = NULL_FUNC, --返回最新彩池数据
		on_recv_xiazhu = NULL_FUNC, --收到下注
		send_history = NULL_FUNC, --发送历史记录
		on_recv_buy_cowgamegold = NULL_FUNC, --买银票
		send_other_bet_info = NULL_FUNC, --发其他玩家下注的信息
		start_game = NULL_FUNC, --开始游戏
		get_max_poke = NULL_FUNC, --得到最大的牌
		compare_poke_paixin = NULL_FUNC, --比牌型
		compare_poke_color = NULL_FUNC, --比红黑
		calc_wingold_supercow = NULL_FUNC,  --计算输赢
		get_peilv = NULL_FUNC, --得到赔率
		is_double_cow = NULL_FUNC, --牛对判断
		update_bet_info = NULL_FUNC, --更新下注的信息
		send_supercow_plays = NULL_FUNC, --发玩家列表
		send_zj_user = NULL_FUNC, --发中奖的玩家
		is_double_cow_new = NULL_FUNC, --是不是牛对
		send_all_users_info = NULL_FUNC, --群发消息玩家的信息
		send_btn_status = NULL_FUNC, --发送按钮的状态
		change_win_lost = NULL_FUNC, --发送按钮的状态
        on_jiesuan = NULL_FUNC, --结算事件
        on_bet_over = NULL_FUNC, --下注完成事件
        zhongjiang_num1 = 0, --中奖位1兔赢0龟赢
		zhongjiang_num2 = 0, --中奖位1红赢0黑赢
		
		is_check_bianpai = 0, --是否检查了变牌
		paixin1 = 0, --兔家的牌型
		paixin2 = 0, --龟家的牌型
		
		user_list={}, --参加疯狂斗牛的玩家
		zj_user_list = {}, --本轮中奖的玩家
		poke_box={}, --牌盒里的牌
		player_poke_list={  --兔家和龟家手上的牌
			[1]={},          --兔家手上的牌
			[2]={},          --龟家手上的牌
		},

		sort_player_poke_list={  --兔家和龟家手上的牌(排序后）
			[1]={},          --兔家手上的牌
			[2]={},          --龟家手上的牌
		},
		startime = "2012-03-28 08:00:00",  --活动开始时间
    	endtime = "2012-05-15 00:00:00",  --活动结束时间
    	tex_open_time = {}, --{8,9,10},指定德州开活动的时间
		qp_open_time = {}, --{8,9,10},指定棋牌开活动的时间
    	fajiang_time = 0,  --本局发奖时间
    	fapai_time = 0, --本局发牌时间
    	send_all_users_flag = 0, --用来控制是不是群发消息通知有人进来，及新的排名
    	send_caichi_flag = 0, --用来控制更新彩池
    	other_bet_time = 0, --其他玩家下注信息
    	CFG_TEX_GAMEGOLD_RATE = 1,
    	CFG_QP_GAMEGOLD_RATE = 1,
    	CFG_CHOUSHUI_INFO = 0.05, --取银票的话，要抽%5的水
    	CFG_MAX_BET_RATE = 0.1,
		--总设注
		all_bet_count=0,
		
		CFG_QP_LIMIT_BET = 2000000,	--个人总下注上限  1000
		CFG_TEX_LIMIT_BET = 2000000, --个人总下注上限  1000
		CFG_LIMIT_AREA_BET = 2000000,	--区域下注上限  1000
		
		CFG_ALLOW_GM = 0, --是否允许引入GM报账功能（炒分，杀分）1允许0不允许
		already_gm_change_gold = 0, --已输赢的总金币数		
		CFG_GM_LOSE_GOLD = 30000000, --输够【3000】万杀分【3000】万，难度【50】%
		CFG_GM_WIN_GOLD = -90000000, --赢够【9000】万炒分【3000】万，难度【50】% 
		
		CFG_GM_CAOFEN_RATE = 2, --2代表2分之1的机率，如果要调低机率就改成3，4，5。。。等
		alread_gm_chao_fen_gold = 0, --现在已炒掉或杀掉了多少分
		CFG_GM_CHAO_FEN_GOLD = -30000000, --炒分的钱(炒分是让玩家赢钱，所以add_gold为正数，所以初始值设计成负数）
		CFG_GM_SHA_FEN_GOLD = 30000000, --杀分的钱（杀分是玩电脑赢钱，所以要让add_gold为负数，所以一开始设计成正数）
		CFG_DISPLAY_USERS_LEN = 30,--最多只显示30个玩家
		CFG_CAICHI_XZ_RATE = 0.01,--彩池增加规则改为： 每局取下注总量的1%的到彩池，彩池范围100万至2000万
		--分区域投注信息
		bet_count={
			[1]=0,          
			[2]=0,        
			[3]=0,         
			[4]=0,         
 		},		

		cfg_game_name = {      --游戏配置 
		    ["soha"] = "soha",
		    ["cow"] = "cow",
		    ["zysz"] = "zysz",
		    ["mj"] = "mj",
		    ["tex"] = "tex",
		},
		
		tex_gm_id_arr = {}, -- {'832791'},
		qp_gm_id_arr = {}, --{'19563389'},
		CFG_INIT_BET="0,0,0,0", --默认投注信息
		
		caichi=0, --彩池
		CFG_MAX_CAICHI = 20000000, --最大的彩池
		CFG_INIT_CAICHI = 1000000, --初始化彩池的值
		CFG_CAICHI_RATE = 0.2, --每局结算抽取1/5抽水到彩池
		CFG_CANT_BETTIME = 10, --停止下注时间 10秒
		CFG_BET_RATE = 1, --一千块一注
        sys_win_gold = 0, --系统输赢
		CFG_REFRESH_OTHER_BET = 5, --每隔xx秒刷新其他玩家下注的情况	
		CFG_FAPAI_TIME = 80, --开局80秒后发3张牌
		CFG_MAX_EXCHANGE = 1000000000,--最大兑换10亿
		qp_game_room = 62022, --棋牌在哪个房间开游戏
		tex_game_room = 18001, --德州在哪个房间开游戏	
		history={},
	    history_len = 10,	--历史记录长度
	    already_fapai=0,   --用来控制定时器是不是发过牌了
        niu_percent = 0.1,   --有牛的概率
		--牌型对应的赔率，为-1时就返彩池里的钱
		paixin_rate={
			[1]=1,    --无牛
			[2]=1,    --牛1
			[3]=1,    --牛2
			[4]=1,    --牛3
			[5]=1,    --牛4
			[6]=1,    --牛5
			[7]=1,    --牛6			
			[8]=2,    --牛7
			[9]=2,    --牛8			
			[10]=3,   --牛9
			[11]=5,   --牛牛
			[12]=7,   --顺子
			[13]=7,   --同花
			[14]=7,   --葫芦
			[15]=10,   --金牛
			[16]=15,   --五小福 
			[17]=-777,   --四梅 
			[18]=-777,   --牛对
			[19]=-777,   --无牛顺			
		}
    }    
end

--用来告诉客户端按钮能不能点
function super_cow_lib.send_btn_status(user_id)
	local user_info=usermgr.GetUserById(user_id)
	if(user_info==nil)then return end
	--最多能下多少银票
	local most_bet_gold=math.floor(super_cow_lib.user_list[user_id].cowgamegold_count*super_cow_lib.CFG_MAX_BET_RATE) or 0
	--购买按钮,默认能点
	local buy_btn=1
	local jiesuan_btn=1
	local add_one_btn=1
	local add_three_btn=1

	--如果是结算的那10秒，就不能点购买和结算
	local curr_time = os.time();
	local remain_time = super_cow_lib.fajiang_time-curr_time;
	if(remain_time<=10)then
		buy_btn=0
		jiesuan_btn=0
	end
	
	--如果有下注，就不能点结算
	if (super_cow_lib.user_list[user_id].bet_info~=super_cow_lib.CFG_INIT_BET)then
		jiesuan_btn=0
	end
	--加1倍的注之后能不能点
	local already_bet_gold=super_cow_lib.user_list[user_id].bet_num_count or 0
	local add_to_gold=already_bet_gold+already_bet_gold
	if(most_bet_gold<add_to_gold)then
		add_one_btn=0
	end
	--加3倍的注之后能不能点
	add_to_gold=already_bet_gold+already_bet_gold*3
	if(most_bet_gold<add_to_gold)then
		add_three_btn=0
	end
	
	netlib.send(function(buf)
        buf:writeString("FNCOWBTN"); --返回按钮是否要为可点状态
        buf:writeInt(most_bet_gold);		--最多能下多少银票
      	buf:writeInt(buy_btn); --购买
      	buf:writeInt(jiesuan_btn); --结算
      	buf:writeInt(add_one_btn); --加一倍
      	buf:writeInt(add_three_btn); --加三倍
    end,user_info.ip,user_info.port);
end

--请求服务端，剩余开奖时间
function super_cow_lib.on_recv_query_time(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	super_cow_lib.send_remain_time(user_info,super_cow_lib.fajiang_time)
end

--告诉客户端还差多少秒
function super_cow_lib.send_remain_time(user_info,fajiang_time)
	local curr_time = os.time();
	local remain_time = fajiang_time-curr_time;
	netlib.send(function(buf)
        buf:writeString("FNCOWTIME"); --通知客户端，剩余开奖时间
        buf:writeInt(remain_time);		--剩余开奖时间
    end,user_info.ip,user_info.port);
end

--每行显示头像、昵称、游戏币，自己显示在第一行
function super_cow_lib.send_supercow_plays(user_info,tmp_user_list)
	local count_user = #tmp_user_list
	
	--如果大于30个，就只显示30条
	local tmp_len=super_cow_lib.CFG_DISPLAY_USERS_LEN
	local i=0
	if(count_user>tmp_len)then count_user=tmp_len end 
	netlib.send(function(buf)
	        buf:writeString("FNCOWPLAYERS"); --服务端，返回玩家列表
	        buf:writeInt(count_user+1)
	        --先发自已
        	buf:writeInt(super_cow_lib.user_list[user_info.userId].user_id);		--玩家ID
	        buf:writeString(super_cow_lib.user_list[user_info.userId].nick_name);		--玩家昵称
	        buf:writeString(super_cow_lib.user_list[user_info.userId].face);		--玩家头像路径
	        buf:writeInt(super_cow_lib.user_list[user_info.userId].cowgamegold_count);		--玩家目前的游戏币数额
	        
			for k,v in pairs(tmp_user_list) do
		        i=i+1
		        buf:writeInt(v.user_id);		--玩家ID
		        buf:writeString(v.nick_name);		--玩家昵称
		        buf:writeString(v.face);		--玩家头像路径
		        buf:writeInt(v.cowgamegold_count);		--玩家目前的游戏币数额
		        if(i>=count_user) then break end
			end
	end,user_info.ip,user_info.port);
end

--打开面板
function super_cow_lib.on_recv_open_game(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	local user_id=user_info.userId;
   	--通知客户端，面板信息
   	local send_dvd_info = function(user_info)
   		local user_id=user_info.userId
        if (super_cow_lib.user_list[user_id] == nil) then
            return
        end
   		local bet_info=super_cow_lib.user_list[user_id].bet_info
   		local tmp_user_bet_info=split(bet_info,",")
   		netlib.send(function(buf)
            buf:writeString("FNCOWOPEN"); --通知客户端，更新玩家银票数
             buf:writeInt(super_cow_lib.user_list[user_id].cowgamegold_count or 0)
             buf:writeInt(1); --买入游戏币兑换率
             buf:writeString(1-super_cow_lib.CFG_CHOUSHUI_INFO); --取出游戏币兑换率
              
            buf:writeInt(4); --默认为4个区域都传回客户端。因为大多数情况下所有区域都可能有人投
			for i=1,4 do
				buf:writeInt(i) --区域id
				local tmpnum=super_cow_lib.bet_count[i]-tonumber(tmp_user_bet_info[i])
				buf:writeInt(tmpnum or 0) --其他玩家 投注的银票数量
				buf:writeInt(tonumber(tmp_user_bet_info[i])) --玩家自己 投注的银票数量
				
			end            
            end,user_info.ip,user_info.port) 

           	--下注超过个人总游戏币的1/10
          	local max_bet_count = math.floor(super_cow_lib.user_list[user_id].cowgamegold_count*super_cow_lib.CFG_MAX_BET_RATE)
        --总下注超过个人上限了
         	if (gamepkg.name == "tex") then
         		if (max_bet_count > super_cow_lib.CFG_TEX_LIMIT_BET) then
                    max_bet_count = super_cow_lib.CFG_TEX_LIMIT_BET
                end
            else
                if (max_bet_count > super_cow_lib.CFG_QP_LIMIT_BET) then
                    max_bet_count = super_cow_lib.CFG_QP_LIMIT_BET
                end
         	end
            netlib.send(function(buf)
                    buf:writeString("FNCOWMAXBET");
                    buf:writeInt(max_bet_count or 0);
            end,user_info.ip,user_info.port);
   	end
	
	--super_cow_db_lib.init_supercow_db(user_id)	
 	
   	--给客户端发开奖时间还差多少秒
   	super_cow_lib.send_remain_time(user_info,super_cow_lib.fajiang_time)
   	
   	--给客户端发开奖历史
   	super_cow_lib.send_history(user_info,super_cow_lib.history)
   	
   	--通知客户端，面板信息
   	send_dvd_info(user_info)
   	
   	--一局开始后30秒就要发牌
	if(os.time() > super_cow_lib.fapai_time)then
     	super_cow_lib.fapai()
    end
    
	--群发消息，通知新的排名
	super_cow_lib.send_all_users_flag = 1	
	
	--发一下彩池
	netlib.send(function(buf)
	    buf:writeString("FNCOWCAICHI");
	    buf:writeInt(super_cow_lib.caichi or 0);
	end,user_info.ip,user_info.port);
	
	--发一下按钮状态
	super_cow_lib.send_btn_status(user_id)
end

--检查是否在有效时间内
super_cow_lib.on_recv_check_status = function(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	local user_id=user_info.userId;
   	
   	--看一下是不是在指定的房间里
   	local status=super_cow_lib.check_datetime()   

   	netlib.send(function(buf)
            buf:writeString("FNCOWACTIVE");
            buf:writeInt(status or 0);		--int	0，活动无效（服务端也可不发）；1，活动有效
        end,user_info.ip,user_info.port);
end


--更新玩家的游戏币
super_cow_lib.send_supercow_gold = function(user_info,super_cow_gold)
	if(user_info~=nil)then
	   	netlib.send(function(buf)
	            buf:writeString("FNCOWCOINS");
	            buf:writeInt(super_cow_gold or 0);
	        end,user_info.ip,user_info.port);
        local user_id = user_info.userId
       	--下注超过个人总游戏币的1/10
      	local max_bet_count = math.floor(super_cow_lib.user_list[user_id].cowgamegold_count*super_cow_lib.CFG_MAX_BET_RATE)
        --总下注超过个人上限了
     	if (gamepkg.name == "tex") then
     		if (max_bet_count > super_cow_lib.CFG_TEX_LIMIT_BET) then
                max_bet_count = super_cow_lib.CFG_TEX_LIMIT_BET
            end
        else
            if (max_bet_count > super_cow_lib.CFG_QP_LIMIT_BET) then
                max_bet_count = super_cow_lib.CFG_QP_LIMIT_BET
            end
     	end
        netlib.send(function(buf)
                buf:writeString("FNCOWMAXBET");
                buf:writeInt(max_bet_count or 0);
            end,user_info.ip,user_info.port);    
    end
end

--更新玩家的投注信息
function super_cow_lib.update_bet_info(user_id,area_id,cowgamegold_bet)
	
	--更新字符串中对应位置的值
	local update_bet=function(user_id,bet_info,area_id,cowgamegold_bet)
		if(bet_info==nil or bet_info=="")then
			bet_info=super_cow_lib.CFG_INIT_BET;	
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
		
		local tmp_bet_info=string.sub(tmp_str,2)
		super_cow_db_lib.update_db_bet_info(user_id,tmp_bet_info,super_cow_lib.bet_id)
		return tmp_bet_info --去掉第1个逗号后返回
	end
	
	--更新玩家的投注信息
	
	bet_info=update_bet(user_id,super_cow_lib.user_list[user_id].bet_info,area_id,cowgamegold_bet)
	
	return bet_info
end

--更新彩池
super_cow_lib.send_caichi = function()
	for k,v in pairs(super_cow_lib.user_list) do
	   	local user_info=usermgr.GetUserById(v.user_id)
	   	if(user_info~=nil)then 
		   	netlib.send(function(buf)
		            buf:writeString("FNCOWCAICHI");
		            buf:writeInt(super_cow_lib.caichi or 0);
		        end,user_info.ip,user_info.port);
	    end
    end
end

--发送历史表
function super_cow_lib.send_history(user_info,history_list)
	local send_len = 0
	if(history_list~=nil)then
	   send_len=#history_list
	end
	netlib.send(function(buf)
    	buf:writeString("FNCOWREC")
    	    
		 buf:writeInt(send_len)
			if(send_len < super_cow_lib.history_len)then
				for i=1,send_len do
			        buf:writeByte(history_list[i].zhongjiang_num1)
			        buf:writeByte(history_list[i].zhongjiang_num2)
			         
		        end
			else
		        for i=1,super_cow_lib.history_len do
			    	buf:writeByte(history_list[i].zhongjiang_num1)
			        buf:writeByte(history_list[i].zhongjiang_num2) 
		        end
		    end
     	end,user_info.ip,user_info.port) 
end

--是不是在规定的房间玩牌
super_cow_lib.is_valid_room=function()
	if(gamepkg.name == "tex" and super_cow_lib.tex_game_room ~= tonumber(groupinfo.groupid))then
		return 0
	end
	if(gamepkg.name ~= "tex" and super_cow_lib.qp_game_room ~= tonumber(groupinfo.groupid))then
		return 0
	end
	return 1
end

function super_cow_lib.on_server_start(e)
    if (super_cow_lib.is_valid_room() == 1) then
        super_cow_db_lib.get_sys_win_from_db(function(sys_win_gold)
            super_cow_lib.sys_win_gold = sys_win_gold
        end)
        super_cow_db_lib.rollback_user_bet()
    end
end

--时间心跳方法
function super_cow_lib.timer(e) 
	if (super_cow_lib.is_valid_room()~=1) then return end
	
	--一局开始后80秒就要发牌
	if(super_cow_lib.already_fapai==0 and os.time() > super_cow_lib.fapai_time)then
     	super_cow_lib.fapai()
     	super_cow_lib.already_fapai=1
    end

    if(super_cow_lib.is_check_bianpai == 0 and 
       super_cow_lib.fajiang_time - os.time() < super_cow_lib.CFG_CANT_BETTIME) then
        super_cow_lib.is_check_bianpai = 1
        local bet_info = {super_cow_lib.bet_count[2], super_cow_lib.bet_count[1]}
        xpcall(function() super_cow_lib.on_bet_over(bet_info) end, throw)
    end
    
  	--1分钟开一局
  	if(os.time() > super_cow_lib.fajiang_time)then	 
     	--开局(有个缺陷，刚开局会产生一组没人中过的数据
     	super_cow_lib.start_game()
    end


    --用来刷新其他玩家的下注情况
    if(os.time() > super_cow_lib.other_bet_time)then	 
     	--开局(有个缺陷，刚开局会产生一组没人中过的数据
     	super_cow_lib.send_other_bet_info()
    end
    
  	--如果users有发生变化就群发一下，通知所有客户端
  	if(super_cow_lib.send_all_users_flag == 1)then	 
     	--开局(有个缺陷，刚开局会产生一组没人中过的数据
     	super_cow_lib.send_all_users_flag = 0
     	super_cow_lib.send_all_users_info()     	
    end
    
    --发彩池
    if(super_cow_lib.send_caichi_flag == 1)then
    	 super_cow_lib.send_caichi_flag = 0    	 
    	 super_cow_lib.send_caichi()
    end
end

--群发玩家的消息，并做排行
function super_cow_lib.send_all_users_info()
	local tmp_user_list={}
	local count_user=0
	for k,v in pairs(super_cow_lib.user_list) do
		table.insert(tmp_user_list,v)
		count_user=count_user+1
	end
	table.sort(tmp_user_list, 
	      function(a, b)
		     return a.cowgamegold_count > b.cowgamegold_count		                   
	end)

	for k,v in pairs(tmp_user_list) do
		local user_info=usermgr.GetUserById(v.user_id)
		if(user_info~=nil)then
			super_cow_lib.send_supercow_plays(user_info,tmp_user_list)
		end
	end
end

--检查是不是能玩
function super_cow_lib.check_can_game()
	local can_game=1
	
	if (super_cow_lib.is_valid_room()~=1) then return 0 end
	
	if super_cow_lib.cfg_game_name[gamepkg.name] == nil then return 0 end
	
	can_game=super_cow_lib.check_datetime()
    return can_game
end

--检查有效时间，限时问题int	0，活动无效（服务端也可不发）；1，活动有效
function super_cow_lib.check_datetime()
	local sys_time = os.time();	
	local startime = timelib.db_to_lua_time(super_cow_lib.startime);
	local endtime = timelib.db_to_lua_time(super_cow_lib.endtime);

	if(sys_time > endtime or sys_time < startime) then
		return 0;
	end
	
	--只能在指定的时间段时玩
 	local tableTime = os.date("*t",sys_time);
	local nowHour  = tonumber(tableTime.hour);

	local open_time={}
	if (gamepkg.name == "tex") then
		open_time = super_cow_lib.tex_open_time
	else
		open_time = super_cow_lib.qp_open_time
	end
	
	--如果有设定开游戏的时间，就看一下是不是在允许的时间范围里
	if(open_time~=nil and #open_time>0)then
		for k,v in pairs(open_time) do
			if(nowHour==v)then
				return 1
			end
		end
		return 0
	end
	--活动时间过去了
	return 1;

end

--初始化牌盒
function super_cow_lib.init_poke_box()
	super_cow_lib.poke_box={}
	--没有大小王，所以牌盒里只要放52张牌
	for i=1,52 do
		super_cow_lib.poke_box[i]=i
    end
    --打乱一副牌
	table.disarrange(super_cow_lib.poke_box)
    
	--给兔家发5张牌
	super_cow_lib.player_poke_list[1]=super_cow_lib.get_card_list(5)
	--给龟家发5张牌
	super_cow_lib.player_poke_list[2]=super_cow_lib.get_card_list(5)
	
	--得到兔和龟的排好序的牌
	super_cow_lib.sort_player_poke_list[1]=super_cow_lib.sort_pokes(super_cow_lib.player_poke_list[1])
	super_cow_lib.sort_player_poke_list[2]=super_cow_lib.sort_pokes(super_cow_lib.player_poke_list[2])
	
end

--发牌
function super_cow_lib.fapai()
	--把前3张牌告诉客户端
	local function send_first_card(user_info)
		local player_poke1 = super_cow_lib.player_poke_list[1]
		local player_poke2 = super_cow_lib.player_poke_list[2]
		netlib.send(function(buf)
	            buf:writeString("FNCOWFAPAI");
	            buf:writeInt(3);
	            for i=1,3 do
	            	buf:writeInt(player_poke1[i]);
	            end
	            buf:writeInt(3);
	            for i=1,3 do
	            	buf:writeInt(player_poke2[i]);
	            end
	            
	      end,user_info.ip,user_info.port);
	end	

	--给所有的疯狂斗牛在线的玩家发前三张牌
	for k,v in pairs(super_cow_lib.user_list)do
		local user_info=usermgr.GetUserById(v.user_id)
		if(user_info~=nil)then
			send_first_card(user_info)
		end
	end
end

--给某个玩家发开奖结果
function super_cow_lib.send_kajiang_info(user_info,real_win_gold)
		local player_poke1 = super_cow_lib.player_poke_list[1]
		local player_poke2 = super_cow_lib.player_poke_list[2]
		netlib.send(function(buf)
	            buf:writeString("FNCOWKAI");
	            buf:writeInt(2);
	            for i=1,2 do
	            	buf:writeInt(player_poke1[3+i]); --发第4和第5张牌给客户端
	            end
	            buf:writeInt(2);
	            for i=1,2 do
	            	buf:writeInt(player_poke2[3+i]); --发第4和第5张牌给客户端
	            end
	            
	            buf:writeInt(super_cow_lib.paixin1); --兔家的牌型
	            buf:writeInt(super_cow_lib.paixin2); --龟家的牌型
	            buf:writeInt(super_cow_lib.zhongjiang_num1); --兔龟输赢
	            buf:writeInt(super_cow_lib.zhongjiang_num2); --红黑输赢
	            buf:writeInt(real_win_gold)
					            
	      end,user_info.ip,user_info.port);
end

--[[
    让那家赢win_pos 1让兔赢， 2让龟赢
    peilv 赢多少赔率
--]]
function super_cow_lib.change_win_lost(win_pos, peilv)    	
    if(win_pos ~= 1 and win_pos ~= 2) then
        TraceError("错误的调牌位置"..win_pos or -100)
        return
    end
    local lose_pos = -1
    if (win_pos == 1) then 
        lose_pos = 2 
    end
    if (win_pos == 2) then 
        lose_pos = 1 
    end

    local find_info = {peilv = 1000, poke_index1 = -1, poke_index2 = -1}
    local poke_list = super_cow_lib.player_poke_list[win_pos]
    for i = 1, 10 do
        for j = i + 1, 10 do
            poke_list[4]= super_cow_lib.poke_box[i]
            poke_list[5]= super_cow_lib.poke_box[j]
            super_cow_lib.sort_player_poke_list[win_pos]=super_cow_lib.sort_pokes(poke_list)
            local paixin = super_cow_lib.get_paixin(super_cow_lib.sort_player_poke_list[win_pos])        
            local changed_peilv = super_cow_lib.get_peilv(paixin)
            if (changed_peilv ~= -777 and changed_peilv <= peilv and
                math.abs(changed_peilv - peilv) <= math.abs(find_info["peilv"] - peilv)) then --找到最接近的赔率
                find_info = {peilv = changed_peilv, poke_index1 = i, poke_index2 = j}
                if (find_info["peilv"] == peilv) then --找到了相同赔率的，直接返回了
                    break
                end
            end
        end
    end
    local poke_index1 = find_info["poke_index1"]
    if (poke_index1 <= 0) then
        TraceError("奇怪为啥没有找到相对于的牌呢？？？？")
        return
    end
    poke_list[4] = super_cow_lib.poke_box[find_info["poke_index1"]]
    poke_list[5] = super_cow_lib.poke_box[find_info["poke_index2"]]
    super_cow_lib.sort_player_poke_list[win_pos] = super_cow_lib.sort_pokes(poke_list)
    table.remove(super_cow_lib.poke_box, find_info["poke_index2"])
    table.remove(super_cow_lib.poke_box, find_info["poke_index1"])
    --让另外一家输
    poke_list = super_cow_lib.player_poke_list[lose_pos]    
    for i = 1, 10, 2 do        
        poke_list[4]= super_cow_lib.poke_box[i]
        poke_list[5]= super_cow_lib.poke_box[i + 1]
        super_cow_lib.sort_player_poke_list[lose_pos] = super_cow_lib.sort_pokes(poke_list)
        local paixin = super_cow_lib.get_paixin(super_cow_lib.sort_player_poke_list[lose_pos])
        local changed_peilv = super_cow_lib.get_peilv(paixin)
        if (changed_peilv < find_info["peilv"]) then  
            table.remove(super_cow_lib.poke_box, i)
            table.remove(super_cow_lib.poke_box, i)
            break
        end
    end
    return
end

--取N张牌
function super_cow_lib.get_card_list(poke_count)
    local temp = {}
    for i = 1, poke_count do 
        table.insert(temp, super_cow_lib.poke_box[1])
        table.remove(super_cow_lib.poke_box, 1)
    end
    --调牌， 10%的概率到牛7以上
    local random = math.random(1, 100)
    if (random < super_cow_lib.niu_percent * 100) then
        local find = 0
        for i = 1, 10 do
            for j = i + 1, 10 do
                temp[4]= super_cow_lib.poke_box[i]
                temp[5]= super_cow_lib.poke_box[j]
                local sort_pokes=super_cow_lib.sort_pokes(temp)
                local paixin = super_cow_lib.get_paixin(sort_pokes)        
                if (paixin > 7) then
                    table.remove(super_cow_lib.poke_box, j)
                    table.remove(super_cow_lib.poke_box, i)   
                    find = 1
                    break                 
                end
            end
            if (find == 1) then
                break
            end
        end
    end
    return temp
end

--得到对应的牌的号
function super_cow_lib.get_real_num(poke_num)
	local tmp_num=math.floor(poke_num%13)
	if(tmp_num==0)then
		return 13
	else
		return tmp_num
	end
end

--得到对应的牌的牛号，在牛牛里，11，12，13都为10点
function super_cow_lib.get_cow_num(poke_num)
	local tmp_num=math.floor(poke_num%13)
	if(tmp_num==0 or tmp_num>10)then
		tmp_num = 10
	end
	return tmp_num
end

--得到对应的牌的号
function super_cow_lib.get_flower(poke_num)
	if(poke_num<=13)then
		return 0
	elseif(poke_num<=26)then
		return 1
	elseif(poke_num<=39)then
		return 2
	elseif(poke_num<=52)then
		return 3
	end		
end

--传一个排好序的5张牌过来，看是不是炸弹
function super_cow_lib.checkisfourbomb(pokes)
	if(super_cow_lib.get_real_num(pokes[1]) == super_cow_lib.get_real_num(pokes[4]) or super_cow_lib.get_real_num(pokes[2]) == super_cow_lib.get_real_num(pokes[5])) then
		return true
	else
		return false
	end
end

--按牌的真实数字大小来排序,排序后为从小到大
function super_cow_lib.sort_pokes(pokes)
	local new_pokes=table.clone(pokes)
	table.sort(new_pokes, function(pram1,pram2) return super_cow_lib.get_real_num(pram1) < super_cow_lib.get_real_num(pram2) end)
	return new_pokes
end


--检查玩家的手牌有没有牛
--10代表牛牛
--9代表牛9
--0代表无牛
--最后两张是一对，则返回1，否则返回0
function super_cow_lib.get_cow_paixin(pokelist)
	if not pokelist or #pokelist ~= 5 then return false end
	local pokeArr = {}

	table.insert(pokeArr,{pokelist[1],pokelist[2],pokelist[3]})
	table.insert(pokeArr,{pokelist[1],pokelist[2],pokelist[4]})
	table.insert(pokeArr,{pokelist[1],pokelist[2],pokelist[5]})
	table.insert(pokeArr,{pokelist[1],pokelist[3],pokelist[4]})
	table.insert(pokeArr,{pokelist[1],pokelist[3],pokelist[5]})
	table.insert(pokeArr,{pokelist[1],pokelist[4],pokelist[5]})
	table.insert(pokeArr,{pokelist[2],pokelist[3],pokelist[4]})
	table.insert(pokeArr,{pokelist[2],pokelist[3],pokelist[5]})
	table.insert(pokeArr,{pokelist[2],pokelist[4],pokelist[5]})
	table.insert(pokeArr,{pokelist[3],pokelist[4],pokelist[5]})

	local pointArr={}
	table.insert(pointArr,{pokelist[4],pokelist[5]})
	table.insert(pointArr,{pokelist[3],pokelist[5]})
	table.insert(pointArr,{pokelist[3],pokelist[4]})
	table.insert(pointArr,{pokelist[2],pokelist[5]})
	table.insert(pointArr,{pokelist[2],pokelist[4]})
	table.insert(pointArr,{pokelist[2],pokelist[3]})
	table.insert(pointArr,{pokelist[1],pokelist[5]})
	table.insert(pointArr,{pokelist[1],pokelist[4]})
	table.insert(pointArr,{pokelist[1],pokelist[3]})
	table.insert(pointArr,{pokelist[1],pokelist[2]})
	local point = 0
    local is_dui = 0
	--看前三张有没有牛，再看是牛几
	for i=1,#pokeArr do
		local cow_value = 0
		for k,v in pairs(pokeArr[i]) do		
			cow_value = cow_value + super_cow_lib.get_cow_num(v)			
		end

		local bValid = math.mod(cow_value,10) == 0 and 1 or 0 ; -- 是否有牛
		if bValid == 1 then
			
			local point_temp = 0
            local is_dui_temp = 1
			for k,v in pairs(pointArr[i]) do
				point_temp = point_temp + super_cow_lib.get_cow_num(v)
            end
            local real_num = -1
            for k,v in pairs(pointArr[i]) do
                if (real_num == -1) then  --检查是否是一对
                    real_num = super_cow_lib.get_real_num(v)
                elseif (real_num ~= super_cow_lib.get_real_num(v)) then
                    is_dui_temp = 0                    
                end
			end
			point_temp = math.mod(point_temp, 10)
			--为了方便计算牛牛的牌型，如果是牛牛就返回10。
			if(point_temp == 0)then 
                point_temp = 10 
            end
            if (is_dui_temp == 1) then --如果是对，则直接返回了
			    return point_temp, is_dui_temp
            elseif (point_temp >= point and is_dui == 0) then --以前没有找到对，现在有了                
                point = point_temp
                is_dui = is_dui_temp
            end
		end
	end
	return point, is_dui
end

--看一下这组排好序的牌是不是无牛顺(玩家的牌为(3.4.5.6.7)或(6.7.8.9.10)或(7.8.9.10.J)，可中50倍无牛顺)
function super_cow_lib.wu_niu_shun(pokes)
	if(super_cow_lib.is_shun(pokes)~=true)then
		return false
	end
	
	if(super_cow_lib.get_real_num(pokes[1])==3 and super_cow_lib.get_real_num(pokes[5])==7 )then
		return true
	end
	if(super_cow_lib.get_real_num(pokes[1])==6 and super_cow_lib.get_real_num(pokes[5])==10 )then
		return true
	end
	if(super_cow_lib.get_real_num(pokes[1])==7 and super_cow_lib.get_real_num(pokes[5])==11 )then
		return true
	end	
	return false
end

--看一下这组排好序的牌是不是五小福(玩家的五张牌加起来不到十点)
function super_cow_lib.wu_xiao_fu(pokes)
	local cow_num=0
	for k,v in pairs (pokes) do
		cow_num=cow_num+super_cow_lib.get_cow_num(v)
	end
	
	if(cow_num<=10)then
		return true
	else
		return false
	end	
end

--看一下这组排好序的牌是不是金牛
function super_cow_lib.is_gold_cow(pokes)
	local cow_num=0
	for k,v in pairs (pokes) do
		if(super_cow_lib.get_cow_num(v)~=10)then
			return false
		end
	end
	return true
end

--看一下这组排好序的牌是不是 葫芦(五张牌里有俩个对子的牌)
function super_cow_lib.is_hulu(pokes)
	--1个3个相同，1个2个相同，就返回 葫芦
	if(super_cow_lib.cal_poke_count(pokes,3)==1 and super_cow_lib.cal_poke_count(pokes,2)==3)then
		return true
	end
	return false
end

--看一下这组排好序的牌，有几个poke_len长度的牌，比如poke_len=2，返回2，代表2个2对即葫芦，如果poke_len=3，返回2，代表2个三条
--这里要问一下葫芦与三条是不是互斥的
function super_cow_lib.cal_poke_count(pokes,poke_len)
	local count=0
	for i=#pokes,1,-1 do
		if(i-poke_len+1==0)then break end		
		if(super_cow_lib.get_real_num(pokes[i])==super_cow_lib.get_real_num(pokes[i-poke_len+1]))then
			--这里要问一下葫芦与三条是不是互斥的，如果是，就要 and pokes[i]~=pokes[i-poke_len]才行
			count=count+1
		end
	end
	return count
end

--看一下这组排好序的牌是不是 同花
function super_cow_lib.is_tonghua(pokes)
	local flower=-1
	for k,v in pairs(pokes) do		
		if(flower~=-1 and flower~=super_cow_lib.get_flower(v))then
			return false
		else
			flower=super_cow_lib.get_flower(v)
		end
	end
	return true
end

--看一下这组排好序的牌是不是 顺子
function super_cow_lib.is_shun(pokes)
	local tmp_num1=super_cow_lib.get_real_num(pokes[5])-super_cow_lib.get_real_num(pokes[4])
	local tmp_num2=super_cow_lib.get_real_num(pokes[4])-super_cow_lib.get_real_num(pokes[3])
	local tmp_num3=super_cow_lib.get_real_num(pokes[3])-super_cow_lib.get_real_num(pokes[2])
	local tmp_num4=super_cow_lib.get_real_num(pokes[2])-super_cow_lib.get_real_num(pokes[1])
	if(tmp_num1==tmp_num2 and tmp_num2==tmp_num3 and tmp_num3==tmp_num4 and tmp_num1==1)then
		return true
	end
	return false
end

--得到牌型
function super_cow_lib.get_paixin(pokes)
	--从高到低返回牌型
	--无牛顺
	if(super_cow_lib.wu_niu_shun(pokes))then
		return 19;
	end
	
	--四梅
	if(super_cow_lib.checkisfourbomb(pokes))then
		return 17;
	end
	
	--五小福
	if(super_cow_lib.wu_xiao_fu(pokes))then
		return 16;
	end
	
	--金牛
	if(super_cow_lib.is_gold_cow(pokes))then
		return 15;
	end
	
	--葫芦
	if(super_cow_lib.is_hulu(pokes))then
		return 14;
	end
	
	--同花
	if(super_cow_lib.is_tonghua(pokes))then
		return 13;
	end
	
	--顺子
	if(super_cow_lib.is_shun(pokes))then
		return 12;
	end
	
	--牛牛，牛9。。。。牛1，无牛
	local cow_point, is_dui =super_cow_lib.get_cow_paixin(pokes)
	return cow_point+1;--正好牛1的牌型对应的错开了一位，所以加1，返回0代表无牛，返回2时代表牛1，3代表牛2
end


--接收下注
function super_cow_lib.on_recv_xiazhu(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;

	if (super_cow_lib.is_valid_room()~=1) then return end
	
   	local user_id=user_info.userId
   	--下注数据
   	local area_id = buf:readInt();--区域id
   	local cowgamegold_bet = buf:readInt();--该区域下的金牛游戏币数量
   	local bet_type = buf:readByte(); --下注动作1,下注，2加注

   	
   	--返回客户端下注结果
   	local send_bet_result=function(user_info,result)
   		netlib.send(function(buf)
	            buf:writeString("FNCOWBET");
	            buf:writeInt(result);		--下注结果，0，下注失败； 1，下注成功； 2，活动无效；
	            buf:writeInt(area_id);		--下注结果，0，下注失败； 1，下注成功； 2，活动无效；
	            
	        end,user_info.ip,user_info.port);
   	end
   	
   	--本局结束前10秒不能让玩家下注
 	if(super_cow_lib.fajiang_time-os.time()<super_cow_lib.CFG_CANT_BETTIME ) then
		send_bet_result(user_info,0)
   		return
	end
   	if(cowgamegold_bet==-1)then
   		super_cow_lib.user_list[user_id].bet_num_count=0
   		super_cow_lib.user_list[user_id].bet_info=super_cow_lib.CFG_INIT_BET      				
   		return
    end

    --看牌直接返回成功
	if (bet_type == 2 and cowgamegold_bet == 0) then
        send_bet_result(user_info,1)
        return
    end
   	
	--超过区域下注上限
 	if(cowgamegold_bet>super_cow_lib.CFG_LIMIT_AREA_BET) then
 		send_bet_result(user_info,3)
   		return
 	end
 		
 	--个人的总下注
 	if(super_cow_lib.user_list[user_id].bet_num_count==nil)then
 		super_cow_lib.user_list[user_id].bet_num_count = 0
 	end
 	
 	--个人的总下注
 	if(super_cow_lib.user_list[user_id].cowgamegold_count<cowgamegold_bet)then
 		send_bet_result(user_info,2)
 		return
 	end
 	
 	--总下注超过个人上限了
 	local tmp_limit=super_cow_lib.CFG_QP_LIMIT_BET
 	if (gamepkg.name == "tex") then
 		tmp_limit=super_cow_lib.CFG_TEX_LIMIT_BET
 	end
 	
   	if(super_cow_lib.user_list[user_id].bet_num_count>tmp_limit-cowgamegold_bet)then
   	 	send_bet_result(user_info,3)
   		return
   	end
   	--下注超过个人总游戏币的1/10
  	local tmp_bet_count = super_cow_lib.user_list[user_id].bet_num_count + cowgamegold_bet
  	if(tmp_bet_count>super_cow_lib.user_list[user_id].cowgamegold_count*super_cow_lib.CFG_MAX_BET_RATE)then
  		send_bet_result(user_info,3)
   		return
  	end  	
    local after_add_cowgamegold=function(user_id,result)
    	local user_info=usermgr.GetUserById(user_id)
	    if(result~=nil and result~=-1)then
			--扣成了，就更新下注的字段，通知客户端下注成功
			
			super_cow_lib.user_list[user_id].cowgamegold_count=result --刷新一下现在有多少钱用来下注
		   	super_cow_lib.user_list[user_id].bet_num_count = super_cow_lib.user_list[user_id].bet_num_count + cowgamegold_bet
	  		super_cow_lib.user_list[user_id].bet_info=super_cow_lib.update_bet_info(user_info.userId,area_id,cowgamegold_bet)
			super_cow_lib.user_list[user_id].bet_id=super_cow_lib.bet_id
			send_bet_result(user_info,1)
			
			--下注成功，要通知客户端新的钱还有多少
			super_cow_lib.send_supercow_gold(user_info,result)
			
			--改总下注信息和区域下注信息
			super_cow_lib.all_bet_count=super_cow_lib.all_bet_count+cowgamegold_bet
			super_cow_lib.bet_count[area_id]=super_cow_lib.bet_count[area_id]+cowgamegold_bet
			
			--加彩池			
			super_cow_lib.add_caichi(math.floor(cowgamegold_bet*super_cow_lib.CFG_CAICHI_XZ_RATE))
			--写日志
			--囧人币日志
			if(cowgamegold_bet>0)then
				super_cow_db_lib.log_user_supercow(user_id,result,cowgamegold_bet,1,super_cow_lib.user_list[user_id].bet_info or super_cow_lib.CFG_INIT_BET)
                super_cow_db_lib.update_user_bet_to_db(user_id, cowgamegold_bet)
			end
			
			--看看按钮能不能点
			super_cow_lib.send_btn_status(user_id)
			
		else
			send_bet_result(user_info,2)
		end		
    end
    
   	--扣玩家身上的金牛游戏币，如果成功就返回客户端成功，不然就通知说失败
   	super_cow_db_lib.add_cowgamegold(user_id,-cowgamegold_bet,2,super_cow_lib.user_list[user_id].bet_info,after_add_cowgamegold)	
end

--增加彩池
function super_cow_lib.add_caichi(win_cowgamegold_bet)
	super_cow_lib.caichi=super_cow_lib.caichi+win_cowgamegold_bet   --现在不用抽水super_cow_lib.CFG_CAICHI_RATE
	if(super_cow_lib.caichi>super_cow_lib.CFG_MAX_CAICHI)then
		super_cow_lib.caichi=super_cow_lib.CFG_MAX_CAICHI
	end
	super_cow_lib.send_caichi_flag = 1
end

--接收购买银票
super_cow_lib.on_recv_buy_cowgamegold = function(buf)
	local user_info = userlist[getuserid(buf)];	
   	if not user_info then return end;
   	if (super_cow_lib.is_valid_room()~=1) then return end

    local user_id=user_info.userId
	--发送购买银票结果
	local function send_buy_cowgamegold_result(user_info, result,cowgamegold_count,org_gamegold_count)
		netlib.send(function(buf)
	            buf:writeString("FNCOWEXCG");
	            buf:writeInt(result);		--兑换方式标识，1，购买， 2，取出， 0，为兑换错误   3，坐下时不能购买
	            buf:writeInt(cowgamegold_count);		--兑换银票数量
	            buf:writeInt(org_gamegold_count or 0);		--兑换原始银票数量
	            
	        end,user_info.ip,user_info.port);
	end
	
	 local after_add_cowgamegold=function(user_id,result)
    	local user_info=usermgr.GetUserById(user_id)
	    if(result~=nil and result~=-1)then
			--扣成了，就更新下注的字段，通知客户端下注成功			
			super_cow_lib.user_list[user_id].cowgamegold_count=result --刷新一下现在有多少钱用来下注
					  
			--下注成功，要通知客户端新的钱还有多少
			super_cow_lib.send_supercow_gold(user_info,result)			
			
			--写日志
			--囧人币日志		
			super_cow_db_lib.log_user_supercow(user_id,result,result,2,super_cow_lib.user_list[user_id].bet_info or super_cow_lib.CFG_INIT_BET)
		end		
    end
	

   	 --收到银票
   	local buy_type=buf:readInt(); --1购买 2.取出
    local buy_cowgamegold = buf:readInt(); --银票数量    
    
    --如果服务器掉线了，那么就不能存取银票
    if(super_cow_lib.user_list[user_id].cowgamegold_count==nil)then
    	--发送取银票结果
    	result = 0
		send_buy_cowgamegold_result(user_info, result, buy_cowgamegold)
    	return
    end
    --坐着时不能存取
    if( user_info.site~=nil)then 
        result = 3
		send_buy_cowgamegold_result(user_info, result, buy_cowgamegold)
        
        return	
    end

    --身上没钱的话，不允许取
    if(buy_type==2 and super_cow_lib.user_list[user_id].cowgamegold_count==0)then
    	--发送取银票结果
    	result = 0
		send_buy_cowgamegold_result(user_info, result, buy_cowgamegold)
    	return
    end
    
    --取出时，如果发现玩家有下注，就不允许取出
    if(buy_type==2 and super_cow_lib.user_list[user_id].bet_info~=super_cow_lib.CFG_INIT_BET)then
    	--发送取银票结果
    	result = 0
		send_buy_cowgamegold_result(user_info, result, buy_cowgamegold)
    	return
    end
	
	--竞换银票不能超过10亿
    if(buy_type==1 and super_cow_lib.user_list[user_id].cowgamegold_count+buy_cowgamegold>super_cow_lib.CFG_MAX_EXCHANGE)then
    	--发送竞换银票结果
    	result = 4
		send_buy_cowgamegold_result(user_info, result, buy_cowgamegold)
    	return
    end	
	
    --如果身上的银票比要取的银票少，就不能取。如果初始值是0或nil，所以取的时间只需要判断内存，没判断数据库
    if(buy_type==2 and super_cow_lib.user_list[user_id].cowgamegold_count<buy_cowgamegold)then
    	--发送取出银票结果
    	result = 0
		send_buy_cowgamegold_result(user_info, result, buy_cowgamegold)
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
   	local cowgamegold_choushui=1
   	local cowgamegold_rate=1
   	if (gamepkg.name == "tex") then
   		cowgamegold_rate = super_cow_lib.CFG_TEX_GAMEGOLD_RATE
   	else
   		cowgamegold_rate = super_cow_lib.CFG_QP_GAMEGOLD_RATE
   	end

   	if(buy_type==2)then --取出
   		cowgamegold_choushui=1-super_cow_lib.CFG_CHOUSHUI_INFO
   		choushui_gold=cowgamegold_rate * buy_cowgamegold*super_cow_lib.CFG_CHOUSHUI_INFO
   	end  	
    
    --存的时候cowgamegold_choushui==1，取的时候是0.95(用来扣抽水）
    local org_buy_cowgamegold = buy_cowgamegold
    local buy_cowgamegold = cowgamegold_rate * buy_cowgamegold*cowgamegold_choushui
    local can_use_gold = 0 
    
    --如果是购买银票，就要看一下钱够不够
    if(user_info.site==nil)then
		can_use_gold = get_canuse_gold(user_info) 
	end


    if(buy_type==1 and can_use_gold==0)then
    	--发送购买银票结果
    	result = 3 --坐下时不能购买，不直接判断site而是用can_usegold。以后再改进。
		send_buy_cowgamegold_result(user_info, result, buy_cowgamegold)
    	return
    end

	if(buy_type==1 and can_use_gold<buy_cowgamegold)then
    	--发送购买银票结果
    	result = 0
		send_buy_cowgamegold_result(user_info, result, buy_cowgamegold)
    	return
    end


	--先加减钱，再加减银票
	--加减钱用计算抽水后的值去做，加减银票用原始的没扣过抽水的值去做
	usermgr.addgold(user_id, math.floor(buy_cowgamegold*temp_flag*-1), 0, new_gold_type.SUPERCOW, -1);    
	local bet_info=super_cow_lib.user_list[user_id].bet_info or super_cow_lib.CFG_INIT_BET
	
	super_cow_db_lib.add_cowgamegold(user_id,org_buy_cowgamegold*temp_flag,3,bet_info,after_add_cowgamegold)	

	--通知客户端存取银票的结果
	send_buy_cowgamegold_result(user_info, buy_type, math.floor(buy_cowgamegold),org_buy_cowgamegold)
	
end

--其他玩家投注区域信息
function super_cow_lib.send_other_bet_info()
	local tmp_user_bet_info1={} --用作统计投注数量的临时变量
	local tmp_bet_info=""
	local tmp_str=""

	
	--通知客户端，其他玩家投注结果（所有人减去自己）
	for k,v in pairs (super_cow_lib.user_list) do
		local user_info=usermgr.GetUserById(v.user_id)
		if(user_info~=nil)then
			tmp_user_bet_info1=split(super_cow_lib.user_list[v.user_id].bet_info or super_cow_lib.CFG_INIT_BET,",")
			
			netlib.send(function(buf)
		    	buf:writeString("FNCOWOTHBET")
		    	buf:writeInt(4)    	
		    	for i=1,4 do
		    		local other_bet_num=super_cow_lib.bet_count[i]-tonumber(tmp_user_bet_info1[i])
		    		buf:writeInt(i)
		    		buf:writeInt(other_bet_num or 0)    		
		    	end
		    	end,user_info.ip,user_info.port)
	    end
     end
     
     --5秒之后才能再进来一次,每5秒刷新一下其他玩家的下注情况
     super_cow_lib.other_bet_time=os.time() + super_cow_lib.CFG_REFRESH_OTHER_BET
end

--根据牌型得到赔率,返回-777代表拿彩金的钱
function super_cow_lib.get_peilv(paixin)
	return super_cow_lib.paixin_rate[paixin]
end


--计算赢了多少钱
function super_cow_lib.calc_wingold_supercow(user_id,bet_info)
	if(bet_info==nil or bet_info==super_cow_lib.CFG_INIT_BET)then return 0,0 end	
	if(super_cow_lib.user_list[user_id].bet_id~=super_cow_lib.bet_id)then return 0,0 end
	
	local win_zhuang_gold=0
	local win_redblack_gold=0
	local tmp_user_bet_info=split(bet_info,",")
	local peilv=0
	local tmp_num1=0
	local tmp_num2=0
	local win_paixin_peilv1=super_cow_lib.get_peilv(super_cow_lib.paixin1)--乌龟赢时的赔率
	local win_paixin_peilv2=super_cow_lib.get_peilv(super_cow_lib.paixin2)--兔子赢时的赔率
	local real_win_gold=0
	--兔赢
	if(super_cow_lib.zhongjiang_num1==1)then
		--得到赔率
		if(win_paixin_peilv2==-777)then		
			if(tonumber(tmp_user_bet_info[1])~=0)then
				win_zhuang_gold=(tonumber(tmp_user_bet_info[1])/super_cow_lib.bet_count[1])*super_cow_lib.caichi*super_cow_lib.CFG_BET_RATE
				win_zhuang_gold=win_zhuang_gold+tonumber(tmp_user_bet_info[1])*super_cow_lib.CFG_BET_RATE
				real_win_gold=(tonumber(tmp_user_bet_info[1])/super_cow_lib.bet_count[1])*super_cow_lib.caichi*super_cow_lib.CFG_BET_RATE
			end
		else
			tmp_num1=tonumber(tmp_user_bet_info[1])*super_cow_lib.CFG_BET_RATE*(win_paixin_peilv2+1) --押兔赢的钱
			tmp_num2=tonumber(tmp_user_bet_info[2])*super_cow_lib.CFG_BET_RATE*(win_paixin_peilv2-1) --押龟输的钱
			win_zhuang_gold=tmp_num1-tmp_num2  --赢的钱减输的钱，允许为负的哦
			--计算实际赢的钱
			tmp_num1=tonumber(tmp_user_bet_info[1])*super_cow_lib.CFG_BET_RATE*win_paixin_peilv2 --押兔赢的钱
			tmp_num2=tonumber(tmp_user_bet_info[2])*super_cow_lib.CFG_BET_RATE*win_paixin_peilv2 --押龟输的钱
			real_win_gold=tmp_num1-tmp_num2  --赢的钱减输的钱，允许为负的哦			
			
		end
	else
	--龟赢		
		--得到赔率
		if(win_paixin_peilv1==-777)then
			if(tonumber(tmp_user_bet_info[2])~=0)then
				win_zhuang_gold=(tonumber(tmp_user_bet_info[2])/super_cow_lib.bet_count[2])*super_cow_lib.caichi*super_cow_lib.CFG_BET_RATE
				win_zhuang_gold=win_zhuang_gold+tonumber(tmp_user_bet_info[2])*super_cow_lib.CFG_BET_RATE
				real_win_gold=(tonumber(tmp_user_bet_info[2])/super_cow_lib.bet_count[2])*super_cow_lib.caichi*super_cow_lib.CFG_BET_RATE
			end
		else
			tmp_num1=tonumber(tmp_user_bet_info[2])*super_cow_lib.CFG_BET_RATE*(win_paixin_peilv1+1) --押龟赢的钱
			tmp_num2=tonumber(tmp_user_bet_info[1])*super_cow_lib.CFG_BET_RATE*(win_paixin_peilv1-1) --押兔输的钱
			win_zhuang_gold=tmp_num1-tmp_num2  --赢的钱减输的钱，允许为负的哦
			--计算实际赢的钱
			tmp_num1=tonumber(tmp_user_bet_info[2])*super_cow_lib.CFG_BET_RATE*win_paixin_peilv1 --押龟赢的钱
			tmp_num2=tonumber(tmp_user_bet_info[1])*super_cow_lib.CFG_BET_RATE*win_paixin_peilv1 --押兔输的钱
			real_win_gold=tmp_num1-tmp_num2  --赢的钱减输的钱，允许为负的哦
		end
	end

	--红赢(*2是为了返本金）	
	if(super_cow_lib.zhongjiang_num2==1)then
		tmp_num1=tonumber(tmp_user_bet_info[3])*super_cow_lib.CFG_BET_RATE*2
		tmp_num2=0    --tonumber(tmp_user_bet_info[4])*super_cow_lib.CFG_BET_RATE，如果红黑赔率调整再处理，现在写死成1
		win_redblack_gold=tmp_num1-tmp_num2   --红赢的钱减去黑输的钱
		--计算实际赢的钱
		tmp_num1=tonumber(tmp_user_bet_info[3])*super_cow_lib.CFG_BET_RATE
		tmp_num2=tonumber(tmp_user_bet_info[4])*super_cow_lib.CFG_BET_RATE		
		real_win_gold=real_win_gold+tmp_num1-tmp_num2
	else
		--黑赢
		tmp_num1=0 --tonumber(tmp_user_bet_info[3])*super_cow_lib.CFG_BET_RATE
		tmp_num2=tonumber(tmp_user_bet_info[4])*super_cow_lib.CFG_BET_RATE*2
		win_redblack_gold=tmp_num2-tmp_num1
		--计算实际赢的钱
		tmp_num1=tonumber(tmp_user_bet_info[3])*super_cow_lib.CFG_BET_RATE
		tmp_num2=tonumber(tmp_user_bet_info[4])*super_cow_lib.CFG_BET_RATE
		real_win_gold=real_win_gold+tmp_num2-tmp_num1
	end	
	win_zhuang_gold=math.floor(win_zhuang_gold)
	win_redblack_gold=math.floor(win_redblack_gold)
	real_win_gold=math.floor(real_win_gold)
	return win_zhuang_gold,win_redblack_gold,real_win_gold
end

--返回1代表第1付牌是牛对，2代表第2付牌是牛对，3代表2边都是牛对，0代表都不是牛对
function super_cow_lib.is_double_cow_new(pokes1,pokes2)
	local ret_num=0
    local cow_point1, is_dui1 = super_cow_lib.get_cow_paixin(pokes1)
    local cow_point2, is_dui2 = super_cow_lib.get_cow_paixin(pokes2)
	if(cow_point1 ~= 10 and cow_point2 ~= 10)then  --没有一家为牛牛，直接返回        
		return ret_num  
    end
    if(cow_point2 == 10 and cow_point1 > 0 and is_dui1 == 1) then --一家有牛牛，一家有牛，有对
        ret_num = ret_num + 1
    end
    if(cow_point1 == 10 and cow_point2 > 0 and is_dui2 == 1) then --一家有牛牛，一家有牛，有对
        ret_num = ret_num + 2
    end
	return ret_num
end

--发中奖列表
function super_cow_lib.send_zj_user(user_info)
	
	local send_len=10
	if(send_len>#super_cow_lib.zj_user_list)then
		send_len=#super_cow_lib.zj_user_list
	end
	netlib.send(function(buf)
		buf:writeString("FNCOWUSERS"); --通知客户端，剩余开奖时间
		buf:writeInt(send_len); --要显示的记录条数
		for i=1,send_len do
			buf:writeInt(super_cow_lib.zj_user_list[i].user_id);
	        buf:writeString(super_cow_lib.zj_user_list[i].nick_name);	
	      	buf:writeString(super_cow_lib.zj_user_list[i].face);
	      	buf:writeInt(super_cow_lib.zj_user_list[i].win_gold);
		end
	end,user_info.ip,user_info.port);
end

--开局
--每10分钟进来一次，要做的事如下：
--1. 给上轮的人员发奖
--2. 初始化新的一轮用到的变量
--3. 写开奖日志
function super_cow_lib.start_game()
	if (super_cow_lib.is_valid_room()~=1) then return end
	local sql="";
    local after_add_cowgamegold=function(user_id,result)
    	local user_info=usermgr.GetUserById(user_id)
	    if(result~=nil and result~=-1)then
			--扣成了，就更新下注的字段，通知客户端下注成功
			
			super_cow_lib.user_list[user_id].cowgamegold_count=result --刷新一下现在有多少钱用来下注
		 	
			--下注成功，要通知客户端新的钱还有多少
			super_cow_lib.send_supercow_gold(user_info,result)

			--写日志
			--囧人币日志
			super_cow_db_lib.log_user_supercow(user_id,result,result,3,super_cow_lib.user_list[user_id].bet_info or super_cow_lib.CFG_INIT_BET)
		end		
    end
    
    local function real_jieshuan()
    	--得到牌型
	 	super_cow_lib.paixin1=super_cow_lib.get_paixin(super_cow_lib.sort_player_poke_list[1])
	 	super_cow_lib.paixin2=super_cow_lib.get_paixin(super_cow_lib.sort_player_poke_list[2])
	 	
		
		--如果兔家和龟家都是牛牛，要看一下是不是牛对
		if(super_cow_lib.paixin1>=11 or super_cow_lib.paixin2>=11)then
			local ret = super_cow_lib.is_double_cow_new(super_cow_lib.sort_player_poke_list[1],super_cow_lib.sort_player_poke_list[2])
			if (ret == 1) then 
				super_cow_lib.paixin1 = 18 
			end
			if (ret == 2) then 
				super_cow_lib.paixin2 = 18 
			end
			if (ret == 3) then 
				super_cow_lib.paixin1 = 18
				super_cow_lib.paixin2 = 18 
			end 		
			
		end
		
		--看是兔家还是龟家胜
		super_cow_lib.zhongjiang_num1 = super_cow_lib.compare_poke_paixin()
		
		--看是红用还是黑胜
		super_cow_lib.zhongjiang_num2 = super_cow_lib.compare_poke_color()
		    	
		--计算兔龟2家的牌是谁胜谁败
		--是不是押对了，如果押对了，就给玩家发奖
        local sys_win_gold = 0
		for k,v in pairs(super_cow_lib.user_list) do
			local user_id = v.user_id			
			local win_zhuang_gold,win_redblack_gold,real_win_gold=super_cow_lib.calc_wingold_supercow(v.user_id,v.bet_info)
            if(real_win_gold==nil)then real_win_gold=0 end
			local win_cowgamegold_bet=win_zhuang_gold+win_redblack_gold
			local user_info = usermgr.GetUserById(user_id)			
            sys_win_gold = sys_win_gold + real_win_gold

			local buf={}
			buf.user_id=v.user_id
			buf.win_gold=real_win_gold
			buf.nick_name=v.nick_name
			buf.face=v.face
			buf.cowgamegold_count=v.cowgamegold_count
			
			--如果这个玩家赚钱了就放到中奖用户列表，否则就给彩池加钱
			if(real_win_gold>0)then
				table.insert(super_cow_lib.zj_user_list,buf)
			elseif(win_cowgamegold_bet<0)then
				--现在改成在下注成功时加彩池，不是赢钱时加
				--super_cow_lib.add_caichi(math.abs(win_cowgamegold_bet))							
			end
			super_cow_db_lib.add_cowgamegold(user_id,win_zhuang_gold+win_redblack_gold,1,v.bet_info,after_add_cowgamegold) --给玩家发奖

			if(user_info~=nil)then
				super_cow_lib.send_kajiang_info(user_info,real_win_gold) --把发奖情况发到客户端
			end
        end
        --修改内存输赢的游戏币
        super_cow_lib.sys_win_gold = super_cow_lib.sys_win_gold - sys_win_gold
        --修改系统输赢的游戏币
        super_cow_db_lib.update_sys_win(super_cow_lib.sys_win_gold)
        super_cow_lib.on_jiesuan(super_cow_lib.sys_win_gold)
        --清除数据库内临时下注的钱
        super_cow_db_lib.clear_user_temp_bet()
    end
    
	local function fajiang()
		--真实结算
		real_jieshuan()
		
		--如果开了彩池就要初始化彩池		
		local win_paixin_peilv1=super_cow_lib.get_peilv(super_cow_lib.paixin1)--看一下是不是开了彩池
		local win_paixin_peilv2=super_cow_lib.get_peilv(super_cow_lib.paixin2)--看一下是不是开了彩池		
		if(win_paixin_peilv1==-777 or win_paixin_peilv2==-777)then
			super_cow_lib.caichi=super_cow_lib.CFG_INIT_CAICHI
		end
			
		
		--加入历史表中
		if(#super_cow_lib.history < super_cow_lib.history_len)then		--如果长度小于6，直接加入
			local bufftable ={
						  	    zhongjiang_num1 = super_cow_lib.zhongjiang_num1, 
			                    zhongjiang_num2 = super_cow_lib.zhongjiang_num2,
			                }	                
			table.insert(super_cow_lib.history,bufftable)
		else
			table.remove(super_cow_lib.history,1)	--删除第一条		
			local bufftable ={
						  	    zhongjiang_num1 = super_cow_lib.zhongjiang_num1, 
			                    zhongjiang_num2 = super_cow_lib.zhongjiang_num2,
			                }	                
			table.insert(super_cow_lib.history,bufftable)
		end
		--写历史数据日志
	 	super_cow_db_lib.log_supercow_history(super_cow_lib.zhongjiang_num1,super_cow_lib.zhongjiang_num2,super_cow_lib.bet_id);	 	
		--发新的彩池到客户端
		super_cow_lib.send_caichi()
		
		if(super_cow_lib.zj_user_list==nil or #super_cow_lib.zj_user_list==0)then return end
		if(#super_cow_lib.zj_user_list>2)then
			table.sort(super_cow_lib.zj_user_list, 
			      function(a, b)
				     return a.win_gold > b.win_gold		                   
			end)
		end	
		
		--发送中奖列表
		for k,v in pairs(super_cow_lib.user_list) do
			local user_info=usermgr.GetUserById(v.user_id)
			if(user_info~=nil)then
				super_cow_lib.send_zj_user(user_info)
			end
		end		
	end
	
 	--初始化一局的信息
 	local function init_game_info()
 		local curr_time=os.time()
		--初始化开奖的时间
	 	super_cow_lib.fajiang_time = curr_time+60*2
	 	super_cow_lib.fapai_time = curr_time + super_cow_lib.CFG_FAPAI_TIME --开局之后 30秒再发3张牌
	 	
	 	--初始化牌盒
	 	super_cow_lib.init_poke_box()
	 	
	 	--初始化本轮的投注ID，年月日时分为组和的字段作为投注ID
	 	super_cow_lib.bet_id = os.date("%Y%m%d%H%M", curr_time)
	 	
	 	--初始化打开面板的人的列表
	 	for k,v in pairs(super_cow_lib.user_list) do
			local user_info=usermgr.GetUserById(v.user_id)
			if(user_info==nil)then				
				table.remove(super_cow_lib.user_list,v.user_id)
			else				
				super_cow_lib.user_list[v.user_id].bet_info=super_cow_lib.CFG_INIT_BET
				super_cow_lib.user_list[v.user_id].bet_num_count=0				
			end
	 	end
	 	
	 	--更新最新的bet_id到参数表里，防止服务器重启时要退钱
	 	super_cow_db_lib.update_last_betid(super_cow_lib.bet_id)
	 	
	 	
	 	--初始化输赢情况
	 	super_cow_lib.zhongjiang_num1=0
	 	super_cow_lib.zhongjiang_num2=0
	 		 	
	 	super_cow_lib.paixin1=0
	 	super_cow_lib.paixin2=0
	 	
	 	--初始化发牌的状态
	 	super_cow_lib.already_fapai=0
        --修改变牌标记
	 	super_cow_lib.is_check_bianpai = 0
	 	--初始化彩池
	 	if(super_cow_lib.caichi==0)then
	 		super_cow_lib.caichi=super_cow_lib.CFG_INIT_CAICHI
	 	end
	 	
		--分区域投注信息
		super_cow_lib.bet_count={
			[1]=0,          
			[2]=0,        
			[3]=0,         
			[4]=0,         
 		}
	 	super_cow_lib.zj_user_list={}
 	end
 	
 	--给上一轮的人发奖
 	if(super_cow_lib.player_poke_list[1]~=nil and #super_cow_lib.player_poke_list[1]>0)then
 		fajiang();
 	end
 	
 	--初始化新一轮的信息
 	init_game_info();
	
end

--给排序后的牌，得到最大的牌的花色和数字
function super_cow_lib.get_max_poke(pokes)
	local max_num=0
	local max_flower=0

	--第5张牌就是最大的牌
	max_num=super_cow_lib.get_real_num(pokes[5])
	max_flower=super_cow_lib.get_flower(pokes[5])
	return max_num,max_flower
end

--比红黑
function super_cow_lib.compare_poke_color()
	local red_count=0 --兔家有几个红牌
	for k,v in pairs(super_cow_lib.player_poke_list[2]) do
		local tmp_flower=0
		tmp_flower=super_cow_lib.get_flower(v)
		if(tmp_flower==0 or tmp_flower==2)then
			red_count=red_count+1
		end
	end
	
	if(red_count>2)then
		return 1
	else
		return 0
	end
end

--看是哪边胜了
function super_cow_lib.compare_poke_paixin()
	
	--如果牌型相等，看最大的牌的
	if(super_cow_lib.paixin1 == super_cow_lib.paixin2)then
		--先看大小，再看花色
		local max_num1=0
		local max_flower1=0
		local max_num2=0
		local max_flower2=0
		
		--得到最大的牌的花色和数字
		max_num1,max_flower1=super_cow_lib.get_max_poke(super_cow_lib.sort_player_poke_list[1])
		max_num2,max_flower2=super_cow_lib.get_max_poke(super_cow_lib.sort_player_poke_list[2])

		--先看最大牌的大小，再看花色，
		if(max_num1>max_num2)then
			return 0
		elseif(max_num2>max_num1)then
			return 1
		elseif(max_flower1>max_flower2)then
			return 0
		else
			return 1			
		end
	end

	--如果兔的牌型大，就返回1
	if(super_cow_lib.paixin1>super_cow_lib.paixin2)then
		return 0
	end
	
	return 1

end


--协议命令
cmd_supercow_handler = 
{
        ["FNCOWACTIVE"] = super_cow_lib.on_recv_check_status, --客户端，请求插件是否有效
        ["FNCOWBET"] = super_cow_lib.on_recv_xiazhu, --接收下注
        ["FNCOWEXCG"] = super_cow_lib.on_recv_buy_cowgamegold, --请求兑换游戏币
        ["FNCOWOPEN"] = super_cow_lib.on_recv_open_game, --接收打开面板
        
}

--加载插件的回调
for k, v in pairs(cmd_supercow_handler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("timer_second", super_cow_lib.timer);
eventmgr:addEventListener("on_server_start", super_cow_lib.on_server_start); 