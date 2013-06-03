TraceError("init car_match_lib...")

if car_match_lib and car_match_lib.timer then
	eventmgr:removeEventListener("timer_second", car_match_lib.timer);
end

if car_match_lib and car_match_lib.restart_server then
	eventmgr:removeEventListener("on_server_start", car_match_lib.restart_server);
end

if (car_match_lib and car_match_lib.gm_cmd) then
    eventmgr:removeEventListener("gm_cmd", car_match_lib.gm_cmd)
end

if car_match_lib and car_match_lib.on_user_exit then
	eventmgr:removeEventListener("on_user_exit", car_match_lib.on_user_exit);
end

if not car_match_lib then
    car_match_lib = _S
    {
		------------------------------------网络请求--------------------------------
        on_recv_tuifei                      = NULL_FUNC, --请求查询退费
  		on_recv_baoming                     = NULL_FUNC, --请求报名
  		on_recv_openjoin                    = NULL_FUNC, --客户端，点参赛或报名按钮
  		on_recv_openpl                      = NULL_FUNC, --客户端打开活动面板
        on_recv_querystatus                 = NULL_FUNC, --客户端看这个活动的状态
        on_recv_xiazhu                      = NULL_FUNC, --客户端下注
        on_recv_carinfo                     = NULL_FUNC, --客户端查询车库信息
        on_recv_carface_info                = NULL_FUNC, --查车的信息，用在头像显示上
        on_recv_query_match_mc              = NULL_FUNC, --查比赛名次
        on_recv_query_king_info             = NULL_FUNC, --查某个人得冠的信息
		on_recv_open_box					= NULL_FUNC, --收到开宝箱请求

        ------------------------------------网络发送--------------------------------
        send_match_time                     = NULL_FUNC, --查本阶段剩余时间
        send_king_list                      = NULL_FUNC, --向客户端发历界冠军
        send_main_box                       = NULL_FUNC, --发主面板的信息
        send_all_message                    = NULL_FUNC, --全服广播右下角信息
		send_user_message                   = NULL_FUNC, --给某个人发右下角信息
        send_cfg_info                       = NULL_FUNC, --发服务端配置信息给客户端，用于显示
        send_match_mc                       = NULL_FUNC, --发比赛名次
		send_match_status                   = NULL_FUNC, --发比赛状态
		send_match_status2                  = NULL_FUNC, --发比赛状态
        send_next_match_time                = NULL_FUNC, --发下一个开始时间给客户端
        send_xiazhu_pm                      = NULL_FUNC, --下注得奖排行榜
		send_superfans                      = NULL_FUNC, --发超级粉丝的信息
		send_today_minren                   = NULL_FUNC, --今日名人
		send_king_car                       = NULL_FUNC, --王者之车
		send_today_king                     = NULL_FUNC, --今日冠军
		send_history_minren                 = NULL_FUNC, --历史名人
        send_chadui                         = NULL_FUNC, --发送被插队了
        send_other_bet                      = NULL_FUNC, --发送所有人的下注
        send_guanjun_reward                 = NULL_FUNC, --只要有人下注了，就通知客户端新的冠军奖金
        send_sys_chat_msg                   = NULL_FUNC, --发送聊天
        send_king_gift_des                  = NULL_FUNC, --发送宝箱描述
        send_other_winner                   = NULL_FUNC, --发送2-8名玩家的获奖信息

        ------------------------------------内部接口--------------------------------
        init_match                          = NULL_FUNC, --初始化某轮比赛
        init_peilv                          = NULL_FUNC, --初始化赔率信息
        init_user_match                     = NULL_FUNC, --初始化玩家的比赛信息
        init_user_king_info                 = NULL_FUNC, --初始化玩家的冠军信息
		init_super_fans_list                = NULL_FUNC, --初始化超级粉丝信息

        get_match_by_id                     = NULL_FUNC, --通过比赛ID得到比赛信息
        get_match_mc                        = NULL_FUNC, --得到比赛的名次
  		get_speed                           = NULL_FUNC, --得到某类车的速度
        get_npc_car_info                    = NULL_FUNC, --查NPC的车的信息
        get_remain_time                     = NULL_FUNC, --得到剩余时间
        get_rand_num                        = NULL_FUNC, --取随机数
		get_jiacheng_by_prize               = NULL_FUNC, --根据车价获取加成及奖金上限值
		get_jiacheng                        = NULL_FUNC, --获取车型加成
        get_car_name                        = NULL_FUNC, --获取车名
        get_car_cost                        = NULL_FUNC, --得到基础车的价格
        get_user_car_prize                  = NULL_FUNC, --得到玩家的车价格
        get_match_name                      = NULL_FUNC, --获取比赛名
        get_baoming_gold                    = NULL_FUNC, --得到报名或插队需要的钱
        get_default_match_type              = NULL_FUNC, --得到某个玩家默认的match_type
        get_npc_num                         = NULL_FUNC, --从NPC列表中抽取一个NPC参赛

		set_proccess                        = NULL_FUNC, --比赛进程设置
		add_npc                             = NULL_FUNC, --加入NPC
		check_time                          = NULL_FUNC, --检查时间
		query_car_info                      = NULL_FUNC, --查车子的信息
        query_carinfo_by_site               = NULL_FUNC, --根据位置查车子的信息
		update_guanjun_info                 = NULL_FUNC, --更新比赛冠军的一些信息
		update_minren_list                  = NULL_FUNC, --更新名人
		update_king_car_list                = NULL_FUNC, --更新王者之车
        update_bet_info                     = NULL_FUNC, --得到某个玩家默认的match_type
        return_baoming_gold                 = NULL_FUNC, --退还被插队的人的报名费
        match_fajiang                       = NULL_FUNC, --给参赛的人发奖
        xiazhu_fajiang                      = NULL_FUNC, --给下注的人发奖
        clear_car_king_data                 = NULL_FUNC, --清数据
        change_mc                           = NULL_FUNC, --GM控制车
		give_kingcar_box					= NULL_FUNC, --发冠军宝箱
        add_other_winner                    = NULL_FUNC, --加入一个2-8名的参赛获奖玩家
        give_other_winner                   = NULL_FUNC, --给其他玩家发奖
	    check_match_room                    = NULL_FUNC, --检测是否比赛服务器
		get_useing_king_count               = NULL_FUNC, --得到玩家正在用的车的冠军次数
		open_or_close_wnd                   = NULL_FUNC, --打开或关闭面板，用于性能优化
		on_user_exit						= NULL_FUNC, --玩家离线
		
        ------------------------------------系统事件--------------------------------
        timer                               = NULL_FUNC, --定时器
        gm_cmd                              = NULL_FUNC, --GM控制
        restart_server                      = NULL_FUNC, --服务器重启

		------------------------------------系统参数--------------------------------
		current_time = 0,   --系统当前时间
		match_list = {}, --比赛信息
		user_list = {},  --玩家列表
		king_list = {
			[1] = {},
			[2] = {},
		},  --历界冠军的列表
		king_car_list = {}, --王者之车
		all_zj_info = {
			[1] = {},
			[2] = {},
		},    --中奖玩家列表
		restart_match_id = {
			[1] = 0,
			[2] = 0,
		}, --如果有重启过，记录重启前的match_id是多少
        CFG_GOLD_TYPE = {
            XIA_ZHU = 1,  --下注
            BAO_MIN = 2,  --报名
            JIANG_JIN = 3, --奖金
            CAR_WIN = 4,   --车赢的钱
            BACK_XIA_ZHU = 5, --退还报名费用
        },
		match_start_status = {0, 0}, --比赛是不是开始了
		notify_flag = 0, -- 通知客户端刷新界面
		need_notify_proc = 0, --通知进度有变化
        gm_ctrl = {0, 0},
		CFG_KING_LEN = 10, --最多10条冠军记录
		CFG_TOTALMATCH_TIME = 6*60, --30 * 60,   --多长时间一场比赛
		CFG_BAOMING_TIME = 60*2, --10 * 60, --报名阶段需要多少时间
		CFG_XZ_TIME = 60*2,      --19 * 60 + 15, --下注阶段要多少时间
		CFG_MATCH_TIME = 50, --比赛动画的时间
		CFG_LJ_TIME = 60*1,--5, --比赛领奖界面的显示时间
		CFG_CAR_NUM = 8,      --一共8辆车参赛
		CFG_BET_RATE = { -- 鲜花与筹码的兑换比例
			[1] = 100,
			[2] = 10000,
		},
		CFG_MAX_CAR_LEVEL = 99, --车最多升到99级
		CFG_MAX_GJ_CAR_GOLD = 100000, --得冠军最多加这多
		CFG_XIAZHU_PM_LEN = 8, --下注得奖排行榜长度
		CFG_MATCH_NUM = 2, --一共2种比赛
		CFG_BET_INIT = "0,0,0,0,0,0,0,0", --默认下注的情况
		CFG_BAOMING_GOLD ={   --默认的报名费用
			[1] = 5000,
			[2] = 100000,
		},
		CFG_MAX_XZ_GOLD = {   --最大下注
			[1] = 100000,
			[2] = 10000000,
		},
		CFG_MAX_XZ_HUA = {   --最大下注的花
			[1] = 100000,
			[2] = 100000,
		},
		CFG_MIN_XZ_GOLD = {   --最小下注
			[1] = 100,
			[2] = 10000,
		},
		king_reward = {    --冠军的奖励
			[1] = 0,
			[2] = 0,
		},
		king_nick = {}, --冠军的昵称
		CFG_TIME_DESC = "10:00-23:00",
		CFG_MAX_CAR_COST = 1000000, --报名车价上限
		CFG_RETURN_RATE = 0.8, --返奖率
		CFG_MAX_HUIXIN = 20, --最大会心值
		CFG_CAR_LEVEL = "4,10,28,81",
		CFG_OPEN_TIME = {{},{}}, --开放时段
		send_bet_flag = 0, --其他人下注的发消息标识
		CFG_BAOXIANG = {
			[1] = "",
			[2] = "",
		},
        CFG_SHIPS_INFO = {
            [5028] = {
                ["cost"] = 8380000,	--白银龙舟838W
                ["name"] = "白银龙舟",
            },
	        [5029] = {
                ["cost"] = 22800000,	--黄金龙舟2280W
                ["name"] = "黄金龙舟",
            },
            [5023] = {
                ["cost"] = 9347369,  --游艇888W
                ["name"] = "游艇",
            },
        },
		--  低级场各车速如下：奥拓80、奇瑞110、夏利140、雪铁龙180、甲壳虫220
    	--	高级场各车速如下：奥迪180、奔驰210、玛莎拉蒂240、法拉利275、保时捷300、兰博基尼360、布加迪420
		CFG_CAR_INFO = {
			[5011] = {
				["speed"]=180,
				["cost"]=1880000,
				["name"]="奥迪A8",
			},
			[5012] = {
				["speed"]=220,
				["cost"]=288000,
				["name"]="甲壳虫",
			},
			[5013] = {
				["speed"]=80,
				["cost"]=18800,
				["name"]="奥拓",
			},
			[5017] = {
				["speed"]=210,
				["cost"]=2880000,
				["name"]="奔驰",
			},
			[5018] = {
				["speed"]=180,
				["cost"]=78800,
				["name"]="雪铁龙",
			},
			[5019] = {
				["speed"]=140,
				["cost"]=33800,
				["name"]="夏利",
			},
			[5021] = {
				["speed"]=240,
				["cost"]=2800000,
				["name"]="玛莎拉蒂",
			},
			[5022] = {
				["speed"]=110,
				["cost"]=25500,
				["name"]="奇瑞qq",
			},
			[5024] = {
				["speed"]=275,
				["cost"]=5880000,
				["name"]="法拉利",
			},
			[5025] = {
				["speed"]=300,
				["cost"]=12800000,
				["name"]="保时捷",
			},
			[5026] = {
				["speed"]=360,
				["cost"]=18880000,
				["name"]="兰博基尼",
			},
			[5027] = {
				["speed"]=420,
				["cost"]=47600000,
				["name"]="布加迪",
			},

		},

		CFG_XZGOLD_MSG = 1000000, --100万，当玩家一次向单台车献花超过价值100万时，右侧信息框中新增信息
		npc_num = {
			[1] = {},
			[2] = {},
		},
		--NPC定义，先放这里，最终定稿好移到配置文件中去
		npc_car ={
			[1] ={
				[1]={
					["user_id"] = -100,
					["nick_name"] = "舒马赫",
					["car_id"] = -100,
					["car_type"] = 5019,
				},
				[2]={
					["user_id"] = -101,
					["nick_name"] = "方吉奥",
					["car_id"] = -101,
					["car_type"] = 5022,
				},
				[3]={
					["user_id"] = -102,
					["nick_name"] = "赛纳",
					["car_id"] = -102,
					["car_type"] = 5019,
				},
				[4]={
					["user_id"] = -103,
					["nick_name"] = "阿斯卡利",
					["car_id"] = -103,
					["car_type"] = 5022,
				},
				[5]={
					["user_id"] = -104,
					["nick_name"] = "克拉克",
					["car_id"] = -104,
					["car_type"] = 5019,
				},
				[6]={
					["user_id"] = -105,
					["nick_name"] = "斯图尔特",
					["car_id"] = -105,
					["car_type"] = 5022,
				},
				[7]={
					["user_id"] = -106,
					["nick_name"] = "劳达",
					["car_id"] = -106,
					["car_type"] = 5019,
				},
				[8]={
					["user_id"] = -107,
					["nick_name"] = "莫斯",
					["car_id"] = -107,
					["car_type"] = 5022,
				},
				[9]={
					["user_id"] = -108,
					["nick_name"] = "布拉海姆",
					["car_id"] = -108,
					["car_type"] = 5019,
				},
				[10]={
					["user_id"] = -109,
					["nick_name"] = "普罗斯特",
					["car_id"] = -109,
					["car_type"] = 5022,
				},
				[11]={
					["user_id"] = -110,
					["nick_name"] = "费斯切拉",
					["car_id"] = -110,
					["car_type"] = 5019,
				},
				[12]={
					["user_id"] = -111,
					["nick_name"] = "苏蒂尔",
					["car_id"] = -111,
					["car_type"] = 5022,
				},
				[13]={
					["user_id"] = -112,
					["nick_name"] = "库特哈德",
					["car_id"] = -112,
					["car_type"] = 5019,
				},
				[14]={
					["user_id"] = -113,
					["nick_name"] = "小皮奎特",
					["car_id"] = -113,
					["car_type"] = 5022,
				},
				[15]={
					["user_id"] = -114,
					["nick_name"] = "特鲁利",
					["car_id"] = -114,
					["car_type"] = 5019,
				},
				[16]={
					["user_id"] = -115,
					["nick_name"] = "汉密尔顿",
					["car_id"] = -115,
					["car_type"] = 5022,
				},
			},
			[2] ={
				[1]={
					["user_id"] = -200,
					["nick_name"] = "汉密尔顿",
					["car_id"] = -200,
					["car_type"] = 5017,
				},
				[2]={
					["user_id"] = -201,
					["nick_name"] = "特鲁利",
					["car_id"] = -201,
					["car_type"] = 5024,
				},
				[3]={
					["user_id"] = -202,
					["nick_name"] = "小皮奎特",
					["car_id"] = -202,
					["car_type"] = 5017,
				},
				[4]={
					["user_id"] = -203,
					["nick_name"] = "库特哈德",
					["car_id"] = -203,
					["car_type"] = 5024,
				},
				[5]={
					["user_id"] = -204,
					["nick_name"] = "苏蒂尔",
					["car_id"] = -204,
					["car_type"] = 5024,
				},
				[6]={
					["user_id"] = -205,
					["nick_name"] = "斯图尔特",
					["car_id"] = -205,
					["car_type"] = 5017,
				},
				[7]={
					["user_id"] = -206,
					["nick_name"] = "普罗斯特",
					["car_id"] = -206,
					["car_type"] = 5024,
				},
				[8]={
					["user_id"] = -207,
					["nick_name"] = "布拉海姆",
					["car_id"] = -207,
					["car_type"] = 5017,
				},
				[9]={
					["user_id"] = -208,
					["nick_name"] = "方吉奥",
					["car_id"] = -208,
					["car_type"] = 5024,
				},
				[10]={
					["user_id"] = -209,
					["nick_name"] = "费斯切拉",
					["car_id"] = -209,
					["car_type"] = 5017,
				},
				[11]={
					["user_id"] = -210,
					["nick_name"] = "劳达",
					["car_id"] = -210,
					["car_type"] = 5024,
				},
				[12]={
					["user_id"] = -211,
					["nick_name"] = "克拉克",
					["car_id"] = -211,
					["car_type"] = 5017,
				},
				[13]={
					["user_id"] = -212,
					["nick_name"] = "莫斯",
					["car_id"] = -212,
					["car_type"] = 5024,
				},
				[14]={
					["user_id"] = -213,
					["nick_name"] = "阿斯卡利",
					["car_id"] = -213,
					["car_type"] = 5017,
				},
				[15]={
					["user_id"] = -214,
					["nick_name"] = "赛纳",
					["car_id"] = -214,
					["car_type"] = 5024,
				},
				[16]={
					["user_id"] = -215,
					["nick_name"] = "舒马赫",
					["car_id"] = -215,
					["car_type"] = 5017,
				},
			},
		},
		CFG_MATCH_NAME = {
			[1] = "普通赛",
			[2] = "名车赛",
		},
		CFG_GAME_ROOM = 18001, --只能在德州的主服务器上做的操作
		CFG_SUPERFANS_LEN = 6, --超级粉丝的前6名
		CFG_TODAYMR_LEN = 10, --今日名人
		CFG_TODAY_KING_LEN = 10, --今日冠军
		CFG_KINGCAR_LEN = 10, --王者之车
		CFG_WEEK_KING_LEN = 10,
		CFG_HISTORYMR_LEN = 10, --历史名人
		superfans_list = {}, --超级粉丝
		today_king_list = {},
		history_minren_list = {},
		today_minren_list = {},
        -----------------------------------赛车改造新加配置------------------------------------
        CFG_PEILV = {
            [1] = {},
            [2] = {},
        },         --des:车位赔率
        CFG_WIN_CHANCE = {
            [1] = {},
            [2] = {},
        },    --des:车位获胜概率
        CFG_MAX_REWARD = {},    --des:各区间车价对应奖金加成比例
        open_wnd_user_list = {}, --打开窗口的玩家
    }
end

------------------------------------网络请求------------------------------------------

--请求查询退费
function car_match_lib.on_recv_tuifei(buf)
    local user_info = userlist[getuserid(buf)];
   	if not user_info then return end;
    car_match_db_lib.tui_fei(user_info)
end

--收到报名
function car_match_lib.on_recv_baoming(buf)
	local send_baoming_result = function(user_info,result)
	 	netlib.send(function(buf)
        	buf:writeString("CARJOIN");
        	buf:writeInt(result)
        end,user_info.ip,user_info.port);
	end

	local user_info = userlist[getuserid(buf)];
   	if not user_info then return end;

   	local car_id = buf:readInt()
   	local area_id = buf:readByte()
   	local match_type = buf:readByte()
   	local baoming_gold = buf:readInt()
   	local car_type = buf:readInt()
   	local user_id = user_info.userId
   	local result = 1

   	-- -1,此位置其他人已报名或插队;-2 报名时间过期；-3 报名或插队的费用不足 -4在其他位置上报过名了  0，其他无效报名；
   	--做异常判断
   	if car_match_lib.match_start_status[match_type] == 0 then return end --活动不是有效时直接不允许报名

   	local need_gold = car_match_lib.get_baoming_gold(match_type,area_id)
    --得到玩家桌子上的钱
    local usergold = get_canuse_gold(user_info)

   	if baoming_gold < need_gold then
   		send_baoming_result(user_info,-1)
   		return
   	end

   	if car_match_lib.match_list[match_type].proccess ~= 1 then
   	   	send_baoming_result(user_info,-2)
   		return
   	end

   	if usergold < need_gold then
   		send_baoming_result(user_info,-3)
   		return
   	end

   	local find = 0
   	for k,v in pairs(car_match_lib.match_list[match_type].match_car_list) do
   		if v.match_user_id == user_id then
   			find = 1
   			break
   		end
   	end

   	if find==1 then
   	   	send_baoming_result(user_info,-4)
   		return
   	end

   	
	if (car_match_sys_ctrl) then
		--car_match_sys_ctrl.update_win_info(match_type, need_gold, car_match_lib.CFG_GOLD_TYPE.BAO_MIN)
	end
   	local return_user_id = car_match_lib.match_list[match_type].match_car_list[area_id].match_user_id
   	local return_chadui = car_match_lib.match_list[match_type].match_car_list[area_id].chadui
   	local return_user_nick = car_match_lib.match_list[match_type].match_car_list[area_id].match_nick_name

    --扣钱
    --报名和插队次数加1，通知客户端报名成功
    if return_chadui == 0 then
      if match_type == 1 then
   	    usermgr.addgold(user_id, -need_gold, 0, new_gold_type.CAR_MATCH_BAOMING_1, -1);
   	  else
   	    usermgr.addgold(user_id, -need_gold, 0, new_gold_type.CAR_MATCH_BAOMING_2, -1);
   	  end
   	else
   	  if match_type == 1 then
   	    usermgr.addgold(user_id, -need_gold, 0, new_gold_type.CAR_MATCH_QIANGWEI_1, -1);
   	  else
   	    usermgr.addgold(user_id, -need_gold, 0, new_gold_type.CAR_MATCH_QIANGWEI_2, -1);
   	  end
   	end


   	car_match_lib.match_list[match_type].match_car_list[area_id].chadui = car_match_lib.match_list[match_type].match_car_list[area_id].chadui + 1
   	car_match_lib.match_list[match_type].match_car_list[area_id].car_id = car_id
   	car_match_lib.match_list[match_type].match_car_list[area_id].match_user_id = user_id
   	car_match_lib.match_list[match_type].match_car_list[area_id].match_nick_name = user_info.nick
   	car_match_lib.match_list[match_type].match_car_list[area_id].match_user_face = user_info.imgUrl or ""
   	car_match_lib.match_list[match_type].match_car_list[area_id].car_type = car_type
   	car_match_lib.match_list[match_type].match_car_list[area_id].king_count = car_match_lib.user_list[user_id].car_list[car_id].king_count
   	car_match_lib.match_list[match_type].match_car_list[area_id].hui_xin = car_match_lib.user_list[user_id].car_list[car_id].hui_xin
    car_match_lib.match_list[match_type].match_car_list[area_id].jiacheng = car_match_lib.get_jiacheng(user_id, car_id)

   	send_baoming_result(user_info,result)

   	--防止2个场都同时有人报名，如果2边同时报了名，就设定为999
   	if car_match_lib.notify_flag ~= 0 and car_match_lib.notify_flag ~= match_type then
   		car_match_lib.notify_flag = 999
   	else
   		car_match_lib.notify_flag = match_type
   	end

   	--向客户端右下角发提示信息
   	local msg_type = 1 --1报名成功 2赛车位被抢 3 献花超100万
   	local msg_list = {}
   	if return_user_id==nil or return_user_id==0 then
   		msg_type = 1
   		table.insert(msg_list, user_info.nick)
   		table.insert(msg_list, area_id)
   	else
   		msg_type = 2
   		table.insert(msg_list,user_info.nick)
   		table.insert(msg_list,return_user_nick)
   		table.insert(msg_list, area_id)
   		--通知客户端被插队了
   		local return_user_info = usermgr.GetUserById(return_user_id)
   		if return_user_info~=nil then
   			car_match_lib.send_chadui(return_user_id,match_type)
   		else
   			car_match_db_lib.need_notify_chadui(return_user_id,match_type)
   		end

   		--退还被插队的人的报名费
   		car_match_lib.return_baoming_gold(return_user_id,return_chadui,match_type)
   	end

   	car_match_lib.send_all_message(match_type, msg_type, msg_list)

 	--通知数据层保存报名数据
 	local baoming_num = car_match_lib.match_list[match_type].match_car_list[area_id].chadui or 0
 	local match_id = car_match_lib.match_list[match_type].match_id
 	car_match_db_lib.update_car_baoming(area_id, car_id, user_id, baoming_num, match_type, match_id)
 	car_match_db_lib.record_car_baoming_log(area_id,car_id,user_id,match_id,match_type,baoming_gold)
end

--收到打开参赛面板
function car_match_lib.on_recv_openjoin(buf)
	local get_car_num = function(car_list)
		local len = 0
		for k,v in pairs(car_list)do
			len = len + 1
		end
		return len
	end
	local user_info = userlist[getuserid(buf)];
   	if not user_info then return end;
   	local user_id = user_info.userId
   	local area_id = buf:readByte()
   	local match_type = buf:readByte()
   	local need_gold = 0
   	need_gold = car_match_lib.get_baoming_gold(match_type,area_id)
   	--car_list需要在数据层初始化
   	local car_num = get_car_num(car_match_lib.user_list[user_id].car_list)

   	--得到可以报澳门和维加斯的车
   	local match_car_list = {}
   	for k,v in pairs(car_match_lib.user_list[user_id].car_list) do

   		if v.car_type~=nil and car_match_lib.CFG_CAR_INFO[v.car_type]~=nil then
			--光棍节自行车不能赛车
			if v.car_type ~= 5044 and v.car_type ~= 5045 then
				if (match_type == 1 and car_match_lib.CFG_CAR_INFO[v.car_type].cost < car_match_lib.CFG_MAX_CAR_COST and car_match_lib.CFG_CAR_INFO[v.car_type].cost > 0)
					or (match_type==1 and (car_match_lib.CFG_CAR_INFO[v.car_type].cost == -1 or car_match_lib.CFG_CAR_INFO[v.car_type].cost == -2)) then
					table.insert(match_car_list,v)
				end
				if (match_type==2 and car_match_lib.CFG_CAR_INFO[v.car_type].cost >= car_match_lib.CFG_MAX_CAR_COST and car_match_lib.CFG_CAR_INFO[v.car_type].cost > 0)
					or (match_type==2 and car_match_lib.CFG_CAR_INFO[v.car_type].cost == -3) then
					table.insert(match_car_list,v)
				end
			end
		end
   	end

   	netlib.send(function(buf)
        buf:writeString("CAROPJN");
        buf:writeInt(need_gold)
        buf:writeInt(#match_car_list)

        for k,v in pairs (match_car_list) do
        	buf:writeInt(v.car_id)
        	buf:writeInt(v.car_type)
        	buf:writeInt(v.king_count)
        end
     end,user_info.ip,user_info.port);
end

--收到打开面板
function car_match_lib.on_recv_openpl(buf)
	local user_info = userlist[getuserid(buf)]
   	if not user_info then return end;
   	local user_id = user_info.userId
   	local match_type = buf:readByte() --得到比赛的ID
   	if match_type == 0 then
   		match_type = car_match_lib.get_default_match_type(user_info)
    end

    --发送车队信息
    if (car_match_sj_lib) then
        car_match_sj_lib.send_team_info(user_info)
    end

    local send_func = function()
        --发主面板的信息
        car_match_lib.send_main_box(user_info,match_type)
        --发送剩余时间
        car_match_lib.send_match_time(user_info,match_type)
        --发冠军列表
        if (car_match_lib.match_list[match_type].proccess ~= 3) then
            car_match_lib.send_king_list(user_info, match_type)
        end
        --只是向8个人发，服务器压力不大，所以直接发送我的冠军奖金
        if (car_match_lib.match_list[match_type].proccess == 2) then
    		for i = 1, car_match_lib.CFG_CAR_NUM do
    			car_match_lib.send_guanjun_reward(match_type,i)
    		end
    	end
    	--需要的话就发下一轮比赛开始的时间
    	car_match_lib.send_next_match_time(user_info, match_type)
    end
    
     --新手引导检测
    if (car_match_sj_lib) then
        --判断关闭面板的期间是否要加汽油
        car_match_sj_lib.add_off_line_gas(user_id)
        car_match_sj_lib.check_is_new_player(user_id, function(ret)
            if (ret == 1) then
                car_match_lib.send_new_player(user_info)
            else
                send_func()
            end
        end)
    else
        send_func()
    end
end

--客户端查询活动状态
--byte 1有效 -1整体上线时间过期 -2不是有效的时段 0其他异常
function car_match_lib.on_recv_querystatus(buf)
	local user_info = userlist[getuserid(buf)];
	if not user_info then return end;
	local match_type = buf:readInt()

	local send_result = function(user_info,status)
	   	netlib.send(function(buf)
	        buf:writeString("CARSTAT");
	        buf:writeByte(status);
			buf:writeByte(match_type);
			buf:writeString(_U(car_match_lib.CFG_BAOXIANG[match_type]) or "");
    	end,user_info.ip,user_info.port);
	end
	--改成客户端登陆成功才认为是登陆成功了
	if match_type == 1 then
  	car_match_db_lib.on_after_user_login(user_info)
  end

    --改成客户端登陆成功才认为是登陆成功了
    car_match_sj_db_lib.on_after_user_login(user_info)

	--每次请求服务状态时，顺便把配置信息也发过去
	for i=1,car_match_lib.CFG_MATCH_NUM do
		car_match_lib.send_cfg_info(user_info,i)
		car_match_lib.send_match_time(user_info,i)
	end

	--如果之前有被插队，就通知一下退款, 只需要通知一次就好了
    if (match_type == 1) then
	    car_match_db_lib.car_need_notify_msg(user_info.userId)
    end
    --只能在指定的时间段时玩
    if car_match_lib.match_start_status[match_type] == 0 then
    	send_result(user_info,-2)
    	return
    end
    if car_match_lib.check_time(match_type)==1 then
    	send_result(user_info,1)
    	return
    end
   	--不是有效时段
   	send_result(user_info,-2)
end

--客户端下注
--byte -1 下注超时 -2 下注失败 1 下注成功 -4钱不够
function car_match_lib.on_recv_xiazhu(buf)

	local send_result = function (user_info,result)
		netlib.send(function(buf)
	        buf:writeString("CARXZ");
	        buf:writeByte(result);
    	end,user_info.ip,user_info.port);
	end
	local user_info = userlist[getuserid(buf)];
   	if not user_info then return end;
   	local user_id = user_info.userId
   	local area_id = buf:readByte()
   	local bet_count = buf:readInt()
   	local match_type = buf:readByte()

   	--看钱够不够，时间有没有过等异常信息
    if (car_match_lib.check_time(match_type) ~= 1 and car_match_lib.match_start_status[match_type] == 0)  or car_match_lib.match_list[match_type].proccess ~= 2 then
    	send_result(user_info,-1)
    	return
    end

    local need_gold = bet_count * car_match_lib.CFG_BET_RATE[match_type]
    --得到玩家桌子上的钱
    local usergold = get_canuse_gold(user_info)
    if usergold < need_gold then
    	send_result(user_info,-4)
    	return
    end

    --小于最小下注
    if need_gold < car_match_lib.CFG_MIN_XZ_GOLD[match_type] then
    	send_result(user_info,-2)
    	return
    end

    --超过最大下注
	local already_bet = car_match_lib.user_list[user_id].match_info[match_type].bet_num_count or 0
    if (already_bet+bet_count)* car_match_lib.CFG_BET_RATE[match_type] > car_match_lib.CFG_MAX_XZ_GOLD[match_type] then
        send_result(user_info,-3)
    	return
    end

   	--扣钱，改下注信息
   	if car_match_lib.user_list[user_id].match_info[match_type].bet_num_count == nil then
   		car_match_lib.user_list[user_id].match_info[match_type].bet_num_count = bet_count
   	else
   		car_match_lib.user_list[user_id].match_info[match_type].bet_num_count = car_match_lib.user_list[user_id].match_info[match_type].bet_num_count + bet_count
   	end

   	--usermgr.addgold(user_id, -need_gold, 0, new_gold_type.CAR_MATCH, -1);
   	--下注信息
    if match_type == 1 then
      usermgr.addgold(user_id, -need_gold, 0, new_gold_type.CAR_MATCH_XIANHUA_1, -1);
    else
      usermgr.addgold(user_id, -need_gold, 0, new_gold_type.CAR_MATCH_XIANHUA_2, -1);
    end
 	  
    if (car_match_sys_ctrl) then
		car_match_sys_ctrl.update_win_info(match_type, need_gold, car_match_lib.CFG_GOLD_TYPE.XIA_ZHU)
	end
   	car_match_lib.update_bet_info(user_id,area_id,bet_count,match_type)

	--修改match_list中下注位置的总下注金额
	if car_match_lib.match_list[match_type].match_car_list[area_id].xiazhu == nil then
		car_match_lib.match_list[match_type].match_car_list[area_id].xiazhu = bet_count
	else
		car_match_lib.match_list[match_type].match_car_list[area_id].xiazhu = car_match_lib.match_list[match_type].match_car_list[area_id].xiazhu + bet_count
	end

	--如果2个场同时有人下注，就把标识改成999，通知定时器把2个场的下注信息都刷新一下
	if car_match_lib.send_bet_flag ~= 0 and car_match_lib.send_bet_flag ~= match_type then
		car_match_lib.send_bet_flag = 999
	else
		car_match_lib.send_bet_flag = match_type
	end
   	send_result(user_info,1)

   	--写一下下注日志
   	car_match_db_lib.record_car_xiazhu_log(user_id,area_id,bet_count, car_match_lib.match_list[match_type].match_id, match_type, car_match_lib.user_list[user_id].match_info[match_type].bet_info)

end

--收到客户端查询车库信息
function car_match_lib.on_recv_carinfo(buf)
	local user_info = userlist[getuserid(buf)];
   	if not user_info then return end;
   	local user_id = user_info.userId
   	local query_car_list = buf:readString()

   	if query_car_list==nil or query_car_list=="" then return end

	car_match_lib.query_car_info(user_info,query_car_list)

end

--客户端头像时用到车的话，要查询车的一些信息
function car_match_lib.on_recv_carface_info(buf)
	local call_back = function(user_info, car_info, site)
		netlib.send(function(buf)
	    	buf:writeString("CARQTYPE");
	    	buf:writeInt(car_info.car_id)
	    	buf:writeInt(car_info.car_type)
	    	buf:writeInt(car_info.king_count)
	    	buf:writeInt(site)
	    end,user_info.ip,user_info.port);
	end
	local user_info = userlist[getuserid(buf)]
   	if not user_info then return end
   	local user_id = user_info.userId
   	local car_type = buf:readInt()
   	local site = buf:readInt()

	car_match_lib.query_carinfo_by_site(user_id, car_type, site, call_back)
end

--收到查比赛名次
function car_match_lib.on_recv_query_match_mc(buf)
	local user_info = userlist[getuserid(buf)];
   	if not user_info then return end;
   	local match_type = buf:readByte()
	car_match_lib.send_match_mc(match_type)
end

--收到请求发冠军信息
function car_match_lib.on_recv_query_king_info(buf)
	local user_info = userlist[getuserid(buf)];
   	if not user_info then return end
   	local query_user_id = buf:readInt()
    if(duokai_lib and duokai_lib.is_sub_user(query_user_id) == 1) then
        query_user_id = duokai_lib.get_parent_id(query_user_id)
    end
	netlib.send(function(buf)
		buf:writeString("CARKINGIF")
		buf:writeInt(car_match_lib.user_list[query_user_id].match_info[1].total_king_count or 0)
		buf:writeInt(car_match_lib.user_list[query_user_id].match_info[2].total_king_count or 0)
	end, user_info.ip, user_info.port)
end

------------------------------------网络发送------------------------------------------

--发本阶段剩余时间
function car_match_lib.send_match_time(user_info,match_type)
	--如果活动还没开始，就不要发比赛时间了
	if car_match_lib.match_start_status[match_type] == 0 then return end
	local current_time = car_match_lib.current_time
	local match_info = car_match_lib.match_list[match_type]
	local remain_time = car_match_lib.get_remain_time(match_type, current_time)
	netlib.send(function(buf)
       buf:writeString("CARTIME"); --通知客户端
       buf:writeByte(match_info.match_type);
	   buf:writeByte(match_info.proccess);
	   buf:writeInt(remain_time);

	end,user_info.ip,user_info.port)
end

--向客户端发王者之车
function car_match_lib.send_king_list(user_info, match_type)
	netlib.send(function(buf)
	    buf:writeString("CARCARPM")
	    buf:writeByte(match_type)
	    buf:writeInt(#car_match_lib.king_list[match_type])
	    for i=#car_match_lib.king_list[match_type], 1, -1  do --需要逆序排列
			buf:writeInt(car_match_lib.king_list[match_type][i].user_id);
	    	buf:writeString(car_match_lib.king_list[match_type][i].nick_name);
	    	buf:writeInt(car_match_lib.king_list[match_type][i].car_id);
	    	buf:writeInt(car_match_lib.king_list[match_type][i].car_type);
	    	buf:writeInt(car_match_lib.king_list[match_type][i].area_id);
	    end
	end,user_info.ip,user_info.port);
end

--发主面板的信息
function car_match_lib.send_main_box(user_info,match_type,not_send_history)
	if match_type==nil then match_type=2 end--默认显示第二个赛场
	if car_match_lib.match_list[match_type] == nil or car_match_lib.match_list[match_type].proccess==nil then return end
	local user_id = user_info.userId
 	netlib.send(function(buf)
        buf:writeString("CAROPPL");
        buf:writeByte(car_match_lib.match_list[match_type].proccess)
        buf:writeInt(car_match_lib.get_remain_time(match_type, car_match_lib.current_time))
        buf:writeByte(car_match_lib.CFG_CAR_NUM)
        for  i = 1,car_match_lib.CFG_CAR_NUM do
        	  buf:writeByte(i)
        	  buf:writeInt(car_match_lib.match_list[match_type].match_car_list[i].car_id)
        	  --赔率是有小数点的，所以用string传到客户端
        	  buf:writeString(car_match_lib.match_list[match_type].match_car_list[i].peilv.."")
        	  buf:writeInt(car_match_lib.match_list[match_type].match_car_list[i].xiazhu)
        	  if(car_match_lib.user_list[user_id]==nil)then
        	  	TraceError("玩家参赛信息有错误1:")
        	  end
        	  if(car_match_lib.user_list[user_id].match_info==nil)then
        	  	TraceError("玩家参赛信息有错误2:")
        	  	TraceError(car_match_lib.user_list[user_id])
        	  end
        	  if(car_match_lib.user_list[user_id].match_info[match_type]==nil)then
        	  	car_match_lib.init_user_match(user_id,match_type)
        	  end

        	  local bet_info = car_match_lib.user_list[user_id].match_info[match_type].bet_info or car_match_lib.CFG_BET_INIT
        	  local bet_tab = split(bet_info,",")
        	  buf:writeInt(tonumber(bet_tab[i]))
        	  --if car_match_lib.match_list[match_type].proccess > 2 and car_match_lib.match_list[match_type].match_car_list[i].mc<1 or car_match_lib.match_list[match_type].match_car_list[i].mc>8 then
        	  --   TraceError("match_type="..match_type.." error mc="..car_match_lib.match_list[match_type].match_car_list[i].mc)
         	  --end

        	  buf:writeInt(car_match_lib.match_list[match_type].match_car_list[i].mc)
        	  buf:writeInt(car_match_lib.match_list[match_type].match_car_list[i].chadui - 1) --要把报名的值减掉

        	  --比赛的玩家ID
        	  local match_user_id = car_match_lib.match_list[match_type].match_car_list[i].match_user_id
        	  local match_nick_name = car_match_lib.match_list[match_type].match_car_list[i].match_nick_name
        	  local match_user_face = car_match_lib.match_list[match_type].match_car_list[i].match_user_face
        	  buf:writeInt(match_user_id or 0)
        	  buf:writeString(match_nick_name or "")
        	  local car_type = car_match_lib.match_list[match_type].match_car_list[i].car_type or 0
        	  local king_count = car_match_lib.match_list[match_type].match_car_list[i].king_count or 0
              local jiacheng = car_match_lib.match_list[match_type].match_car_list[i].jiacheng * 100 or 0
        	  buf:writeInt(car_type)
              buf:writeInt(jiacheng)
        	  buf:writeString(match_user_face or "")
        	  buf:writeInt(king_count)
        end

        --1到1000的随机数
        local seed = car_match_lib.match_list[match_type].current_rand_num or 1000
        buf:writeInt(seed)
        buf:writeByte(match_type)
        buf:writeInt(car_match_lib.king_reward[match_type])
    end,user_info.ip,user_info.port);

	--发送初始奖金信息
	if (car_match_lib.match_list[match_type].proccess == 2) then
		for i = 1, car_match_lib.CFG_CAR_NUM do
			car_match_lib.send_guanjun_reward(match_type,i)
		end
	end
    --超级粉丝功能
    if (car_match_lib.match_list[match_type].proccess == 3) then
        car_match_lib.send_superfans(user_info, match_type)
    end

    --[[
    if (car_match_lib.match_list[match_type].proccess == 1 and
        car_match_lib.user_list[user_id] ~= nil and
        car_match_lib.user_list[user_id].match_info[match_type] ~= nil and
        car_match_lib.user_list[user_id].match_info[match_type].notify_paihang1 == 0) then
        car_match_lib.user_list[user_id].match_info[match_type].notify_paihang1 = 1
            car_match_lib.send_history(user_info, match_type)
    end
    if (car_match_lib.match_list[match_type].proccess == 2 and
        car_match_lib.user_list[user_id] ~= nil and
        car_match_lib.user_list[user_id].match_info[match_type] ~= nil and
        car_match_lib.user_list[user_id].match_info[match_type].notify_paihang2 == 0) then
        car_match_lib.user_list[user_id].match_info[match_type].notify_paihang2 = 1
            car_match_lib.send_history(user_info, match_type)
    end
    --]]

    if(not_send_history == nil) then
        car_match_lib.send_history(user_info, match_type)
    end

    --发车队信息
    if (car_match_sj_lib) then
        car_match_sj_lib.send_team_info(user_info)
    end
end

function car_match_lib.send_history(user_info, match_type)
    --今日名人功能
    if (car_match_lib.match_list[match_type].proccess == 1 or car_match_lib.match_list[match_type].proccess == 2) then
        car_match_lib.send_today_minren(user_info, match_type)
    end
    --发历史名人功能
    if (car_match_lib.match_list[match_type].proccess == 1 or car_match_lib.match_list[match_type].proccess == 2) then
        car_match_lib.send_history_minren(user_info, match_type)
    end
    --今日冠军功能
    if (car_match_lib.match_list[match_type].proccess == 1 or car_match_lib.match_list[match_type].proccess == 2) then
        car_match_lib.send_today_king(user_info, match_type)
    end
    --王者之车功能
    if (car_match_lib.match_list[match_type].proccess == 1 or car_match_lib.match_list[match_type].proccess == 2) then
        car_match_lib.send_king_car(user_info, match_type)
    end
end

--全服发发右下角的信息
function car_match_lib.send_all_message(match_type, msg_type, msg_list)
    local user_list = car_match_lib.user_list
    if (msg_type == 1 or msg_type == 2) then
        user_list = car_match_lib.open_wnd_user_list
    end
	for k,v in pairs(user_list) do
		
		local user_id = 0;
		if (type(v) == "number") then
			user_id = v
		else
			user_id = v.user_id
		end
		local user_info = usermgr.GetUserById(user_id)
		if user_info ~= nil then
		 	netlib.send(function(buf)
		    	buf:writeString("CARMSG");
		    	buf:writeByte(match_type)
		    	buf:writeByte(msg_type)
		    	buf:writeByte(#msg_list)
		    	for k1,v1 in pairs(msg_list) do
		    		buf:writeString(v1)
		    	end
		    end,user_info.ip,user_info.port);
	    end
    end
end

--发右下角的信息
function car_match_lib.send_user_message(user_info, match_type, msg_type, msg_list)
 	netlib.send(function(buf)
    	buf:writeString("CARMSG");
    	buf:writeByte(match_type)
    	buf:writeByte(msg_type)
    	buf:writeByte(#msg_list)
    	for k,v in pairs(msg_list) do
    		buf:writeString(v)
    	end
    end,user_info.ip,user_info.port);
end

--发服务端配置信息给客户端，用于显示
function car_match_lib.send_cfg_info(user_info,match_type)
		netlib.send(function(buf)
	    	buf:writeString("CARCFG");
	    	buf:writeByte(match_type) --match type
	    	buf:writeInt(car_match_lib.CFG_MAX_CAR_COST)  --报名车价上限(下限) 这里只作提示用，先不支持N场比赛，只支持2场
	    	buf:writeInt(car_match_lib.CFG_BAOMING_GOLD[match_type])  --报名费
	    	buf:writeInt(car_match_lib.CFG_MAX_XZ_GOLD[match_type])  --最大下注金额
	    	buf:writeString(car_match_lib.CFG_CAR_LEVEL) --汽车的升级区间
	    	buf:writeInt(car_match_lib.CFG_MATCH_TIME)   --第3阶段总共有多少秒
	    	buf:writeString(_U(car_match_lib.CFG_TIME_DESC))   --比赛时段描述
	    	buf:writeInt(car_match_lib.CFG_MAX_XZ_HUA[match_type])  --最大下注的花
	    end,user_info.ip,user_info.port);
end

--发比赛名次
function car_match_lib.send_match_mc(match_type)
	local car_list = car_match_lib.match_list[match_type].match_car_list

	for k,v in pairs(car_match_lib.open_wnd_user_list) do
		local user_info = usermgr.GetUserById(v)
		if user_info==nil then return end
		netlib.send(function(buf)
		    buf:writeString("CARMC");
		    buf:writeByte(match_type);
		    buf:writeByte(#car_list);
		    for k1,v1 in pairs (car_list) do
		    	buf:writeInt(v1.mc);
		    	buf:writeInt(v1.car_id);
		    	buf:writeInt(v1.car_type);
		    	buf:writeInt(v1.match_user_id);
		    	buf:writeString(v1.match_nick_name);
		    	buf:writeString(v1.match_user_face);
		    	local car_gold = v1.car_prize or 0

		    	buf:writeInt(car_gold);	--车的价值
				buf:writeInt(v1.hui_xin); --会心值
				buf:writeInt(v1.king_count); --冠军次数
				buf:writeInt(v1.xiazhu); --献花

		    end
		end,user_info.ip,user_info.port);
	end
end

--时间到了，通知开赛
function car_match_lib.send_match_status(match_type, current_time)
	local send_result = function(status)
		for k,v in pairs (car_match_lib.open_wnd_user_list) do
			local user_info = usermgr.GetUserById(v)
			if user_info~=nil then
			   	netlib.send(function(buf)
			        buf:writeString("CARSTAT");
			        buf:writeByte(status);
					buf:writeByte(match_type);
                    buf:writeString(_U(car_match_lib.CFG_BAOXIANG[match_type]) or "");
		    	end,user_info.ip,user_info.port);
		    	car_match_lib.send_match_time(user_info,match_type);

	    	end
    	end
    end

    local total_time = car_match_lib.CFG_TOTALMATCH_TIME / 60;   --一场比赛的时间
    local table_time = os.date("*t", current_time);
    local now_min = table_time.min
    local times = math.floor(60 / total_time);      --一小时内可开的场次
    for i = 1, times do
        if (now_min == (i * total_time == 60 and 0 or i * total_time)) then
            if (car_match_lib.match_start_status[match_type] == 0 and car_match_lib.check_time(match_type) == 1) then
                car_match_lib.match_start_status[match_type] = 1
                car_match_lib.init_match(match_type, current_time)
                send_result(1)
                return
            end
        end
    end
end

--时间到了，通知开赛
function car_match_lib.send_match_status2(current_time, match_type)
	local send_result = function(status)
		for k,v in pairs (car_match_lib.open_wnd_user_list) do
			local user_info = usermgr.GetUserById(v)
			if user_info~=nil then
			   	netlib.send(function(buf)
			        buf:writeString("CARSTAT");
			        buf:writeByte(status);
					buf:writeByte(match_type);
                    buf:writeString(_U(car_match_lib.CFG_BAOXIANG[match_type]) or "");
		    	end,user_info.ip,user_info.port);
	    	end
    	end
	end
    --活动从有效变成无效了
	if car_match_lib.match_start_status[match_type]==1 and
       car_match_lib.check_time(match_type)==0 then
        car_match_lib.match_start_status[match_type] = 0
        send_result(-2)
        return
    end
end

--发下一个开始时间给客户端
function car_match_lib.send_next_match_time(user_info, match_type)
	--如果比赛已经开始，就不用再进这个方法了
	if car_match_lib.match_start_status[match_type] == 1 then
		return
	end
    local total_time = car_match_lib.CFG_TOTALMATCH_TIME / 60;   --一场比赛的时间
	local table_time = os.date("*t", car_match_lib.current_time);
	local now_hour = table_time.hour
	local now_min = table_time.min
	local start_hour = ""
	local start_min = ""
    local need_calc = 1
	if (car_match_lib.CFG_OPEN_TIME[match_type][now_hour] ~= nil and
        now_min + total_time <= car_match_lib.CFG_OPEN_TIME[match_type][now_hour][2]) then
        local times = math.floor(60 / total_time);      --一小时内可开的场次
        for i = 1, times do
            if (now_min < i * total_time) then
                start_hour = now_hour;
                start_min = i * total_time;
                if (start_min < car_match_lib.CFG_OPEN_TIME[match_type][now_hour][1]) then
                    start_min = car_match_lib.CFG_OPEN_TIME[match_type][now_hour][1]
                end
                if (start_min < 10) then
			        start_min = "0"..start_min
                end
                need_calc = 0
                break;
            elseif (i == times) then
                need_calc = 1
            end
        end
    end
    if (need_calc == 1) then
        for i = 1, 24 do
            local next_time = (now_hour + i) % 24
            if (car_match_lib.CFG_OPEN_TIME[match_type][next_time] ~= nil) then
                start_hour = next_time;
                start_min = car_match_lib.CFG_OPEN_TIME[match_type][next_time][1];
                if (start_min < 10) then
                    start_min = "0"..start_min
                end
                break;
            end
        end
    end

    --做一下容错处理
    local msg = ""
    if start_hour ~= "" and start_min ~= "" then
		msg = _U("下场比赛"..start_hour.."："..start_min.."开始")
    else
        msg = _U("比赛未开放，请稍后...")
    end
    netlib.send(function(buf)
        buf:writeString("CARDES")
        buf:writeString(msg)
        buf:writeInt(match_type)
    end,user_info.ip,user_info.port);
end

--下注得奖排行榜
function car_match_lib.send_xiazhu_pm(match_type)
	if car_match_lib.all_zj_info[match_type] == nil then return end
	if(#car_match_lib.all_zj_info[match_type] > 1)then
		table.sort(car_match_lib.all_zj_info[match_type],
		      function(a, b)
			     return a.add_gold > b.add_gold
		end)
	end

	local send_len = #car_match_lib.all_zj_info[match_type]
	if send_len > car_match_lib.CFG_XIAZHU_PM_LEN then
		send_lend = car_match_lib.CFG_XIAZHU_PM_LEN
	end

	--发竞猜达人
	for k,v in pairs (car_match_lib.open_wnd_user_list) do
		local user_info = usermgr.GetUserById(v)
		if user_info~=nil then
		   	netlib.send(function(buf)
		        buf:writeString("CARJCDR");
		        buf:writeByte(match_type)
		        buf:writeInt(send_len);
	            for i=1,send_len do
	            	buf:writeInt(car_match_lib.all_zj_info[match_type][i].user_id) --玩家ID
	            	buf:writeString(car_match_lib.all_zj_info[match_type][i].nick_name or "")   --玩家昵称
	            	buf:writeString(car_match_lib.all_zj_info[match_type][i].img_url or "")   --玩家头像
	            	buf:writeInt(car_match_lib.all_zj_info[match_type][i].add_gold or 0) --玩家得的钱
	            end
 		    end,user_info.ip,user_info.port);
		end
	end

	for k,v in pairs(car_match_lib.all_zj_info[match_type]) do
		local user_info = usermgr.GetUserById(v.user_id)
		if user_info ~= nil then
			local add_gold = v.add_gold or 0
		   	local msg_type = 4 --1报名成功 2赛车位被抢 3 献花超100万 4.给下注中奖的人发消息
		   	local msg_list = {}
			table.insert(msg_list, add_gold)
			car_match_lib.send_user_message(user_info,match_type,msg_type,msg_list)
			car_match_lib.send_sys_chat_msg(user_info, _U("恭喜你在本轮赛车中赢得$")..add_gold)
		end
	end

end

--发超级粉丝列表
function car_match_lib.send_superfans(user_info, match_type)

	if car_match_lib.superfans_list[match_type] == nil then car_match_lib.superfans_list[match_type] = {} end
	local len = #car_match_lib.superfans_list[match_type]
	if len > car_match_lib.CFG_SUPERFANS_LEN then
		len = car_match_lib.CFG_SUPERFANS_LEN
	end

	netlib.send(function(buf)
		buf:writeString("CARCJFS")
		buf:writeByte(match_type)
		buf:writeInt(len)
		for i = 1, len do
			buf:writeInt(car_match_lib.superfans_list[match_type][i].user_id)
			buf:writeString(car_match_lib.superfans_list[match_type][i].nick_name)
			buf:writeString(car_match_lib.superfans_list[match_type][i].img_url)
			buf:writeInt(car_match_lib.superfans_list[match_type][i].area_id)
			buf:writeInt(car_match_lib.superfans_list[match_type][i].area_bet_count)
		end
	end,user_info.ip,user_info.port)
end

--发最近名人功能
function car_match_lib.send_today_minren(user_info, match_type)
	if car_match_lib.today_minren_list[match_type] == nil then car_match_lib.today_minren_list[match_type] = {} end
	local len = #car_match_lib.today_minren_list[match_type]
	if len > car_match_lib.CFG_TODAYMR_LEN then
		len = car_match_lib.CFG_TODAYMR_LEN
	end
	netlib.send(function(buf)
		buf:writeString("CARJRMR")
		buf:writeByte(match_type)
		buf:writeInt(len)
		for i = 1, len do
			buf:writeInt(car_match_lib.today_minren_list[match_type][i].user_id)
			buf:writeString(car_match_lib.today_minren_list[match_type][i].nick_name)
			buf:writeString(car_match_lib.today_minren_list[match_type][i].img_url)
			buf:writeInt(car_match_lib.today_minren_list[match_type][i].today_win_gold)
		end
	end,user_info.ip,user_info.port)
end

--发王者之车功能
function car_match_lib.send_king_car(user_info, match_type)
	if car_match_lib.king_car_list[match_type] == nil then car_match_lib.king_car_list[match_type] = {} end
	local len = #car_match_lib.king_car_list[match_type]
	if len > car_match_lib.CFG_KINGCAR_LEN then
		len = car_match_lib.CFG_KINGCAR_LEN
	end
	netlib.send(function(buf)
		buf:writeString("CARKICA")
		buf:writeByte(match_type)
		buf:writeInt(len)
		for i = 1, len do
			buf:writeInt(car_match_lib.king_car_list[match_type][i].user_id)
			buf:writeString(car_match_lib.king_car_list[match_type][i].nick_name)
			buf:writeInt(car_match_lib.king_car_list[match_type][i].car_id)
			buf:writeInt(car_match_lib.king_car_list[match_type][i].car_type)
			buf:writeInt(car_match_lib.king_car_list[match_type][i].king_count)
			buf:writeInt(car_match_lib.king_car_list[match_type][i].car_prize)
		end
	end,user_info.ip,user_info.port)
end

--发最近冠军功能
function car_match_lib.send_today_king(user_info, match_type)
	if car_match_lib.today_king_list[match_type] == nil then car_match_lib.today_king_list[match_type] = {} end
	local len = #car_match_lib.today_king_list[match_type]
	if len > car_match_lib.CFG_TODAY_KING_LEN then
		len = car_match_lib.CFG_TODAY_KING_LEN
    end

	netlib.send(function(buf)
		buf:writeString("CARJRGJ")
		buf:writeByte(match_type)
		buf:writeInt(len)
		for i = 1, len do
			buf:writeInt(car_match_lib.today_king_list[match_type][i].user_id)
			buf:writeInt(car_match_lib.today_king_list[match_type][i].area_id)
			buf:writeString(car_match_lib.today_king_list[match_type][i].nick_name)
			buf:writeInt(car_match_lib.today_king_list[match_type][i].car_id)
			buf:writeInt(car_match_lib.today_king_list[match_type][i].car_type)
			buf:writeInt(car_match_lib.today_king_list[match_type][i].king_count)
			buf:writeInt(car_match_lib.today_king_list[match_type][i].car_prize)
		end
	end,user_info.ip,user_info.port)
end

--发历史名人功能
function car_match_lib.send_history_minren(user_info, match_type)
	if car_match_lib.history_minren_list[match_type] == nil then car_match_lib.history_minren_list[match_type] = {} end
	local len = #car_match_lib.history_minren_list[match_type]
	if len > car_match_lib.CFG_HISTORYMR_LEN then
		len = car_match_lib.CFG_HISTORYMR_LEN
	end
	netlib.send(function(buf)
		buf:writeString("CARLSMR")
		buf:writeByte(match_type)
		buf:writeInt(len)
		for i = 1, len do
			buf:writeInt(car_match_lib.history_minren_list[match_type][i].user_id)
			buf:writeString(car_match_lib.history_minren_list[match_type][i].nick_name)
			buf:writeString(car_match_lib.history_minren_list[match_type][i].img_url)
			buf:writeInt(car_match_lib.history_minren_list[match_type][i].week_win_gold)
		end
	end,user_info.ip,user_info.port)
end

--通知玩家被插队了
function car_match_lib.send_chadui(user_id,match_type)
	local user_info = usermgr.GetUserById(user_id)
	if user_info == nil then return end
 	netlib.send(function(buf)
    	buf:writeString("CARCHA");
    	buf:writeByte(match_type)
    end,user_info.ip,user_info.port);

end

--发送所有人的下注
function car_match_lib.send_other_bet(match_type)
	if match_type==nil then return end
	for k,v in pairs (car_match_lib.open_wnd_user_list) do
		local user_info = usermgr.GetUserById(v)
		if user_info ~= nil then
		   	netlib.send(function(buf)
		        buf:writeString("CAROTXZ");
		        buf:writeByte(match_type)
		        buf:writeInt(car_match_lib.CFG_CAR_NUM)
		        for i=1,car_match_lib.CFG_CAR_NUM do
		        	buf:writeByte(i)
		        	buf:writeInt(car_match_lib.match_list[match_type].match_car_list[i].xiazhu or 0)
		        	buf:writeString(car_match_lib.match_list[match_type].match_car_list[i].peilv or "")
		        end
		    end,user_info.ip,user_info.port);
	    end
	end
end

--只要有人下注了，就通知客户端新的冠军奖金
function car_match_lib.send_guanjun_reward(match_type,area_id)

	local match_user_id = car_match_lib.match_list[match_type].match_car_list[area_id].match_user_id
	if match_user_id == nil then return end
	local match_user_info = usermgr.GetUserById(match_user_id)
	if match_user_info == nil then return end

	--冠军奖金=外围对该车的下注总额(献花筹码)×对应赔率×车身加成比例
	local xiazhu = car_match_lib.match_list[match_type].match_car_list[area_id].xiazhu or 0
	local peilv = car_match_lib.match_list[match_type].match_car_list[area_id].peilv
    local car_id = car_match_lib.match_list[match_type].match_car_list[area_id].car_id
	local jiacheng = car_match_lib.match_list[match_type].match_car_list[area_id].jiacheng
	local guanjun_gold = xiazhu * peilv * jiacheng * car_match_lib.CFG_BET_RATE[match_type]
    guanjun_gold = math.floor(guanjun_gold)

	netlib.send(function(buf)
		    buf:writeString("CARCKP");
		    buf:writeByte(match_type)
			buf:writeInt(jiacheng * 100)		--车型加成
		    buf:writeInt(guanjun_gold) --冠军奖金
		    buf:writeInt(xiazhu) --下注数量
	end, match_user_info.ip, match_user_info.port);

end

--发送系统聊天
function car_match_lib.send_sys_chat_msg(user_info, msg)
	netlib.send(function(buf)
        buf:writeString("REDC");
        buf:writeByte(4)      --desk chat
        buf:writeString(msg or "")     --text
        buf:writeInt(0)         --user id
        buf:writeString("") --user name
        buf:writeByte(0)
    end,user_info.ip,user_info.port);
end

--发送冠军宝箱描述
function car_match_lib.send_king_gift_des(user_info, match_type)
	netlib.send(function(buf)
		buf:writeString("CARKINGDES")
		buf:writeByte(match_type)
		buf:writeString(car_match_lib.CFG_KING_GIFT_DES[match_type])
	end, user_info.ip, user_info.port)
end

--发送2-8名玩家的获奖信息
function car_match_lib.send_other_winner(user_info, jiacheng, add_gold, match_type)
	if user_info == nil then return end
    netlib.send(function(buf)
		buf:writeString("CAROTHERWIN")
		buf:writeInt(jiacheng * 100)
		buf:writeInt(add_gold)
        buf:writeInt(match_type)
	end, user_info.ip, user_info.port)
end

--发送新手通知
function car_match_lib.send_new_player(user_info)
    if user_info == nil then return end
    netlib.send(function(buf)
        buf:writeString("OPENPANELNG")
        buf:writeInt(1)
    end, user_info.ip, user_info.port)
end 
------------------------------------内部接口------------------------------------------
function car_match_lib.check_match_room()
    return tonumber(groupinfo.groupid) == car_match_lib.CFG_GAME_ROOM and 1 or 0;
end

--初始化某一轮比赛
function car_match_lib.init_match(match_type, match_id)
	if car_match_lib.match_list[match_type] == nil then car_match_lib.match_list[match_type] = {} end
	car_match_lib.match_list[match_type].match_type = match_type --1澳门2维加斯
	car_match_lib.match_list[match_type].proccess = 1  --1报名插队 2献花 3比赛 4出结果    
	car_match_lib.match_list[match_type].start_time = match_id --match_id就是current_time
	car_match_lib.match_list[match_type].current_rand_num = car_match_lib.get_rand_num(1, 1000)

	--如果之前有比赛，在新的一局开始时发冠军宝箱（不管活动是否有效都要做这步）
	if car_match_lib.match_list[match_type].open_num == nil then car_match_lib.match_list[match_type].open_num = 0 end
	if car_match_lib.match_list[match_type].open_num ~= 0 then
		car_match_lib.match_list[match_type].open_num = 0
		car_match_lib.give_kingcar_box(match_type)      --发宝箱
		car_match_lib.give_other_winner(match_type)     --发2-8名奖励
	end

    --活动有效时才做这步
	if car_match_lib.match_start_status[match_type] == 1 then
		--match_id太长 int型存不下，所以这里除10
        match_id = math.floor(match_id / 10)..""..match_type
		car_match_lib.match_list[match_type].match_id = match_id
		--更新这一轮的比赛ID，万一服务器重启的话要用到这个
		car_match_db_lib.update_last_matchid(match_id, match_type)
    end

	--初始化赛车手和赛场信息
	car_match_lib.match_list[match_type].match_car_list = {}
	for i = 1,car_match_lib.CFG_CAR_NUM do
		car_match_lib.match_list[match_type].match_car_list[i] = {}
		car_match_lib.match_list[match_type].match_car_list[i].area_id = i --几号跑道
		car_match_lib.match_list[match_type].match_car_list[i].car_id = 0  --这个位置上的车
		car_match_lib.match_list[match_type].match_car_list[i].peilv = 0   --当前这个位置的赔率
        car_match_lib.match_list[match_type].match_car_list[i].jiacheng = 0   --当前这个位置车的奖金加成
        car_match_lib.match_list[match_type].match_car_list[i].win_chance = 0   --当前这个位置的获胜概率
		car_match_lib.match_list[match_type].match_car_list[i].xiazhu = 0  --当前这个位置的下注
		car_match_lib.match_list[match_type].match_car_list[i].mc = 0      --当前名次
		car_match_lib.match_list[match_type].match_car_list[i].chadui = 0  --插队次数
		car_match_lib.match_list[match_type].match_car_list[i].car_type = 0 --这个位置停了什么车
		car_match_lib.match_list[match_type].match_car_list[i].king_count = 0 --这个位置的车得过几次冠
		car_match_lib.match_list[match_type].match_car_list[i].hui_xin = 0 --这个位置的车的会心值
	end



	--初始化玩家的下注信息和比赛ID
	for k,v in pairs (car_match_lib.user_list)do
		local match_user_info = usermgr.GetUserById(v.user_id)
		if match_user_info == nil then
			car_match_lib.user_list[v.user_id] = nil
		else
			if car_match_lib.user_list[v.user_id].match_info[match_type] == nil then
	 			car_match_lib.user_list[v.user_id].match_info[match_type] = {}
	 		end
			car_match_lib.user_list[v.user_id].match_info[match_type].bet_num_count = 0
			car_match_lib.user_list[v.user_id].match_info[match_type].bet_info = car_match_lib.CFG_BET_INIT
			car_match_lib.user_list[v.user_id].match_info[match_type].match_id = match_id
			car_match_lib.user_list[v.user_id].match_info[match_type].match_type = match_type
            car_match_lib.user_list[v.user_id].match_info[match_type].notify_paihang1 = 0
            car_match_lib.user_list[v.user_id].match_info[match_type].notify_paihang2 = 0
		end
	end
	--初始化赔率
	car_match_lib.init_peilv(match_type)

	--初始化中奖记录
	car_match_lib.all_zj_info[match_type] = {}

	--初始化NPC的号
	if car_match_lib.npc_num == nil then car_match_lib.npc_num = {} end
	car_match_lib.npc_num[match_type] ={}

	for i=1,#car_match_lib.npc_car[match_type] do
    	table.insert(car_match_lib.npc_num[match_type],i)
	end

	--初始化超级粉丝的信息
	car_match_lib.superfans_list[match_type] = {}

end

--根据参赛的8辆车修改8个位置的赔率及赢率
function car_match_lib.init_peilv(match_type)
	--初始化8个位置的赔率
	local car_box = car_match_lib.match_list[match_type].match_car_list
    --根据match_type设置赔率赔率
    for i=1,#car_box do
        car_match_lib.match_list[match_type].match_car_list[i].peilv = car_match_lib.CFG_PEILV[match_type][i]
        car_match_lib.match_list[match_type].match_car_list[i].win_chance = car_match_lib.CFG_WIN_CHANCE[match_type][i]
    end
end

--初始化玩家的比赛信息
function car_match_lib.init_user_match(user_id,match_type)
	if car_match_lib.user_list[user_id].match_info[match_type] == nil then
		car_match_lib.user_list[user_id].match_info[match_type] = {}
	end
	car_match_lib.user_list[user_id].match_info[match_type].bet_info = car_match_lib.CFG_BET_INIT
	car_match_lib.user_list[user_id].match_info[match_type].match_id = car_match_lib.match_list[match_type].match_id
	car_match_lib.user_list[user_id].match_info[match_type].match_type = match_type

end

--初始化玩家的冠军信息
function car_match_lib.init_user_king_info(user_id)
    if (car_match_lib.user_list[user_id] == nil) then return end
	if car_match_lib.user_list[user_id].match_info == nil then 	car_match_lib.user_list[user_id].match_info = {} end
	if car_match_lib.user_list[user_id].match_info[1] == nil then 	car_match_lib.user_list[user_id].match_info[1] = {} end
	if car_match_lib.user_list[user_id].match_info[2] == nil then 	car_match_lib.user_list[user_id].match_info[2] = {} end

	car_match_lib.user_list[user_id].match_info[1].total_king_count = 0
	car_match_lib.user_list[user_id].match_info[2].total_king_count = 0
	for k,v in pairs(car_match_lib.user_list[user_id].car_list) do
   		if v.car_type~=nil and car_match_lib.CFG_CAR_INFO[v.car_type]~=nil then
	   		if car_match_lib.CFG_CAR_INFO[v.car_type].cost < car_match_lib.CFG_MAX_CAR_COST then
	   			car_match_lib.user_list[user_id].match_info[1].total_king_count = car_match_lib.user_list[user_id].match_info[1].total_king_count + v.king_count
	   		else
	   			car_match_lib.user_list[user_id].match_info[2].total_king_count = car_match_lib.user_list[user_id].match_info[2].total_king_count + v.king_count
	   		end
		end
   	end
end

--初始化超级粉丝信息
function car_match_lib.init_super_fans_list(match_type)
   	--超级粉丝，这个每局都不一样，所以不用写数据库
   	if car_match_lib.superfans_list[match_type] == nil then car_match_lib.superfans_list[match_type] = {} end

   	for k, v in pairs (car_match_lib.user_list) do
   		local bet_info = v.match_info[match_type].bet_info or car_match_lib.CFG_BET_INIT
   		local area_bet_count_tab = split(bet_info, ",")
   		for i = 1, #area_bet_count_tab do
	   		local area_bet_count = tonumber(area_bet_count_tab[i])
	   		if area_bet_count>0 then
		   		local buf_tab = {
			   		["user_id"] = v.user_id,
			   		["nick_name"] = v.nick_name,
			   		["img_url"] = v.img_url,
			   		["area_id"] = i,
			   		["area_bet_count"] = area_bet_count,
			   	}
			   	table.insert(car_match_lib.superfans_list[match_type], buf_tab)
		    end
   		end

   	end

   	if #car_match_lib.superfans_list[match_type] > 1 then
		table.sort(car_match_lib.superfans_list[match_type],
		      function(a, b)
			     return a.area_bet_count > b.area_bet_count
		end)
	end
end

--通过比赛ID来找比赛信息
function car_match_lib.get_match_by_id(match_id)
	for k,v  in pairs(car_match_lib.match_list) do
		if v.match_id == match_id then
			return v
		end
	end
end

--得到比赛名次
function car_match_lib.get_match_mc(match_type)
	local get_tab_index = function(list_table,index)
		local i = 1
		for k,v in pairs(list_table) do
			if index == i then
				return v
			end
			i = i + 1
		end
	end

    local get_mc = function(car_box)
		local win_chance = {}
        local total_chance = 0
		for k, v in pairs(car_box) do
            local tmp_chance = v.win_chance * 10
            table.insert(win_chance, tmp_chance)
            total_chance = total_chance + tmp_chance
        end
		local rand_num = car_match_lib.get_rand_num(1, total_chance)
		local tmp_num = win_chance[1]
		for i=1,#win_chance do
			if (i > 1) then
			    tmp_num = tmp_num + win_chance[i]
			end
            if rand_num <= tmp_num then
				local tmp_car = get_tab_index(car_box,i)
				return tmp_car.area_id
            end
		end
	end

	--把参赛车放到要用来排名的盒子里(车库）
	local car_box = table.clone(car_match_lib.match_list[match_type].match_car_list)
	local mc = {}

	--用递归算法 得到各个车的名次
	for i = 1,car_match_lib.CFG_CAR_NUM do
		--mc[1]=2代表第1名的是在2号跑道的车，mc[2]=4代表第2名的是4号跑道的车，依次类推
		local tmp_area_id = get_mc(car_box)
		table.insert(mc, tmp_area_id)

		--从car_box中清掉排出第一名的车，然后再让car_box去排第1名
		for k1,v1 in pairs(car_box)do
			if v1.area_id == mc[i] then
				car_box[k1] = nil
				break
			end
		end
	end

	--更新参赛的8个位置的名次信息
	for i = 1, #mc do
		local area_id=mc[i]
		car_match_lib.match_list[match_type].match_car_list[area_id].mc = i
		if i == 1 then
			car_match_lib.match_list[match_type].open_num = area_id
		end
	end

end

--通过车的型号得到车的速度
function car_match_lib.get_speed(car_type)
	if car_type==nil or car_type== 0 then return 0 end
	return car_match_lib.CFG_CAR_INFO[car_type].speed
end

--得到NPC的车的信息
function car_match_lib.get_npc_car_info(car_info,call_back)
	if call_back==nil then return end
	local car_list_tab = split(car_info,",")
	local buf_tab_list = {}

	for k,v in pairs(car_match_lib.npc_car) do
		for k1,v1 in pairs(v) do
			for k2,v2 in pairs(car_list_tab)do
				if v1.car_id == tonumber(v2) then
					local buf_tab = {}
					buf_tab.user_id = v1.user_id
					buf_tab.nick_name = _U(v1.nick_name)
					buf_tab.car_id = v1.car_id
					buf_tab.car_type = v1.car_type
					buf_tab.hui_xin = v1.hui_xin or 0
					buf_tab.king_count = v1.king_count or 0
					buf_tab.is_using = 1
					buf_tab.cansale = 0
					local car_gold = car_match_lib.get_car_cost(v1.car_type)
					buf_tab.car_prize = car_gold or 0
                    local jiacheng = car_match_lib.get_jiacheng_by_prize(car_gold)
                    buf_tab.jiacheng = jiacheng --奖金加成
					table.insert(buf_tab_list,buf_tab)
					call_back(buf_tab_list)
					return --暂时NPC只有一个车，所以只要找到就直接return了。
				end
			end
		end
	end
end

--得到当前阶段的剩余时间
function car_match_lib.get_remain_time(match_type, current_time)
	local match_info = car_match_lib.match_list[match_type]
    if (match_info == nil) then return end;
	local use_time = current_time - match_info.start_time --现在用了多少时间
	local remain_time = 0
	--计算剩余时间
	if use_time < car_match_lib.CFG_BAOMING_TIME then
		remain_time = car_match_lib.CFG_BAOMING_TIME - use_time
	elseif use_time < car_match_lib.CFG_BAOMING_TIME + car_match_lib.CFG_XZ_TIME then
		remain_time = car_match_lib.CFG_BAOMING_TIME + car_match_lib.CFG_XZ_TIME - use_time
	elseif use_time < car_match_lib.CFG_BAOMING_TIME + car_match_lib.CFG_XZ_TIME + car_match_lib.CFG_MATCH_TIME then
		remain_time = car_match_lib.CFG_BAOMING_TIME + car_match_lib.CFG_XZ_TIME + car_match_lib.CFG_MATCH_TIME - use_time
	elseif use_time < car_match_lib.CFG_BAOMING_TIME + car_match_lib.CFG_XZ_TIME + car_match_lib.CFG_MATCH_TIME + car_match_lib.CFG_LJ_TIME then
		remain_time = car_match_lib.CFG_BAOMING_TIME + car_match_lib.CFG_XZ_TIME + car_match_lib.CFG_MATCH_TIME + car_match_lib.CFG_LJ_TIME - use_time
	end

	if car_match_lib.check_time(match_type)~=1 and car_match_lib.match_start_status[match_type]==0 then
		remain_time=-1
	end
	return remain_time
end

--稍微处理一下LUA的随机算法，防止 被人找到规律
function car_match_lib.get_rand_num(min_num, max_num)
		local buf_tab = {}
		for i = 1, 100 do
			table.insert(buf_tab, math.random(min_num, max_num))
        end
		return buf_tab[math.random(10, 80)]
end

--通过车价取得该车的奖金及加成范围
function car_match_lib.get_jiacheng_by_prize(car_prize)
    for k, v in pairs(car_match_lib.CFG_MAX_REWARD) do
        if (car_prize >= v.min and car_prize <= v.max) then
            return tonumber(k)
        end
    end
end

--通过us通过userid和carid取车价加成
function car_match_lib.get_jiacheng(user_id, car_id)
    local car_prize = car_match_lib.get_user_car_prize(user_id, car_id)         --通过userid和carid取车价
    local jiacheng = car_match_lib.get_jiacheng_by_prize(car_prize)				    --车辆对应奖金加成
	return jiacheng
end

--得到车的名字
function car_match_lib.get_car_name(car_type)
	return car_match_lib.CFG_CAR_INFO[car_type].name
end

--得到基础车的价格
function car_match_lib.get_car_cost(car_type)
	return car_match_lib.CFG_CAR_INFO[car_type].cost
end

--得到玩家车的价格
function car_match_lib.get_user_car_prize(user_id, car_id)
    if (car_match_lib.user_list[user_id] ~= nil and car_match_lib.user_list[user_id].car_list[car_id] ~= nil) then
        return car_match_lib.user_list[user_id].car_list[car_id].car_prize
    else
        return 0
    end
end

--得到比赛的名字
function car_match_lib.get_match_name(match_type)
	return car_match_lib.CFG_MATCH_NAME[match_type]
end

--得到报名或插队需要的钱
function car_match_lib.get_baoming_gold(match_type,area_id)
	--根据比赛类型和位置及相关公式计算出这个位置要多少报名费
	local baoming_gold = car_match_lib.CFG_BAOMING_GOLD[match_type]
	local chadui_num = car_match_lib.match_list[match_type].match_car_list[area_id].chadui or 0
	local chadui_gold = baoming_gold * math.pow(2,chadui_num)
	local need_gold = baoming_gold + chadui_gold
	if chadui_num == 0 then
		need_gold = baoming_gold
	end
    return need_gold
end

--得到某个玩家默认的match_type
function car_match_lib.get_default_match_type(user_info)
	local match_type = 1
	--大于10万默认为去维加斯场
	if user_info.gamescore >= 100000 then
		match_type = 2
    end
    --只要有一个开赛了，就选择默认打开已经开赛的tab
    if (car_match_lib.check_time(1) == 1 and car_match_lib.check_time(2) ~= 1) then
        match_type = 1
    end
    if (car_match_lib.check_time(2) == 1 and car_match_lib.check_time(1) ~= 1) then
        match_type = 2
    end
	return match_type
end

--从NPC列表中抽取一个NPC参赛
function car_match_lib.get_npc_num(match_type)
	local npc_count = #car_match_lib.npc_num[match_type]
	local rand_num = math.random(1,npc_count or 8) --挑一个NPC
	local tmp_num = car_match_lib.npc_num[match_type][rand_num]
	if(tmp_num==nil)then
		TraceError("NPC抽取算法出错了！")
		TraceError(car_match_lib.npc_num[match_type])
	end

	table.remove(car_match_lib.npc_num[match_type], rand_num)
	return tmp_num
end

function car_match_lib.get_all_bet_info(match_type)
    local all_bet_info = {}
        --取得所有人下注
    for k, v in pairs(car_match_lib.user_list) do
        local bet_info = v.match_info[match_type].bet_info or car_match_lib.CFG_BET_INIT
        local tmp_bet_tab = split(bet_info,",")
        local all_bet = 0
        for i = 1, #tmp_bet_tab do
            all_bet = all_bet + tmp_bet_tab[i]
        end
        all_bet = all_bet * car_match_lib.CFG_BET_RATE[match_type]
        if (all_bet > 0) then
            all_bet_info[v.user_id] = {}
            all_bet_info[v.user_id].bet = all_bet
            all_bet_info[v.user_id].add_gold = 0
        end
    end
    --取得所有中奖人
    for k, v in pairs (car_match_lib.all_zj_info[match_type]) do
        if (v.user_id ~= nil and all_bet_info[v.user_id] ~= nil) then 
            all_bet_info[v.user_id].add_gold = v.add_gold
        end
    end
    return all_bet_info
end

--设置当前在第几阶段
function car_match_lib.set_proccess(match_info,current_time)
	--如果不是有效时间，并且还没进入第二阶段，就不再改比赛的阶段
	--目的：让未开赛的比赛不再继续，让已开赛的比赛跑完，然后不再继续
	if car_match_lib.match_start_status[match_info.match_type] == 0 and  match_info.proccess == 1 then
		return
    end
    --活动如果从有效变无效,目前是2种比赛的时间不一致，
    if match_info.proccess == 4 then
        car_match_lib.send_match_status2(current_time, match_info.match_type) 
        --todo
        --活动已经无效了
        if car_match_lib.match_start_status[match_info.match_type] == 0 then
    		car_match_lib.init_match(match_info.match_type, current_time)
			car_match_lib.need_notify_proc = 1
        end   
    end
	--如果现在超过一轮比赛的时间,并且活动无效，就初始化比赛信息
    if (car_match_lib.check_time(match_info.match_type) == 1 and
        current_time >= match_info.start_time + car_match_lib.CFG_TOTALMATCH_TIME) then
        car_match_lib.init_match(match_info.match_type, current_time)
        car_match_lib.need_notify_proc = 1
	--如果当前时间多于报名时间了，就设置进入下一阶段
	elseif match_info.proccess < 2 and current_time >= match_info.start_time + car_match_lib.CFG_BAOMING_TIME then
        match_info.proccess = 2
		car_match_lib.need_notify_proc = 1

		--报名阶段完了，如果还有车位没报名，就加NPC
		car_match_lib.add_npc(match_info.match_type)

		--全服通知可以献花了
		if match_info.match_type == 1 then
			BroadcastMsg(_U("赛车报名已结束，所有赛车车辆全部就绪，进入赛场支持您心目中的冠军！"),0)
		end
	--如果当前时间多于下注时间了，就设置进入下一阶段
	elseif match_info.proccess < 3 and current_time >= match_info.start_time + car_match_lib.CFG_BAOMING_TIME + car_match_lib.CFG_XZ_TIME then
        match_info.proccess = 3
		car_match_lib.need_notify_proc = 1
		--得到超级粉丝的列表
		xpcall(function() car_match_lib.init_super_fans_list(match_info.match_type) end, throw)
		--如果gm没有控制，则自动启动
        if (car_match_lib.gm_ctrl == nil) then
			car_match_lib.gm_ctrl = {0,0}
		end
  		--进入比赛阶段，算出比赛的名次并通知客户端
   		car_match_lib.get_match_mc(match_info.match_type)
        --炒分杀分
        if (car_match_sys_ctrl) then
            xpcall(function() car_match_sys_ctrl.on_process2_end(match_info.match_type) end, throw)
        end
        car_match_lib.gm_ctrl[match_info.match_type] = 0
	--如果当前时间多于比赛时间了，就设置进入下一阶段
	elseif match_info.proccess < 4 and current_time >= match_info.start_time + car_match_lib.CFG_BAOMING_TIME + car_match_lib.CFG_XZ_TIME + car_match_lib.CFG_MATCH_TIME then
		match_info.proccess = 4
		car_match_lib.need_notify_proc = 1

        --这一阶段需要给参赛者和献花的人发奖
		car_match_lib.match_fajiang(match_info.match_type)
		car_match_lib.xiazhu_fajiang(match_info.match_type)

        --所有下注及中奖信息
        local all_bet_info = car_match_lib.get_all_bet_info(match_info.match_type)

		--更新冠军的一些信息
		car_match_lib.update_guanjun_info(match_info.match_type)

        --清一下报名信息
        car_match_db_lib.clear_baoming()
		--发献花得奖排行榜
		car_match_lib.send_xiazhu_pm(match_info.match_type)
		if (car_match_sys_ctrl) then
			car_match_sys_ctrl.on_round_over(match_info.match_type)
		end
		if match_info.match_type == 1 or match_info.match_type == 2 then
        	eventmgr:dispatchEvent(Event("after_car_match_event", {match_type = match_info.match_type, car_list = car_match_lib.match_list[match_info.match_type].match_car_list, open_num = car_match_lib.match_list[match_info.match_type].open_num, all_bet_info = all_bet_info}))
        end
	end

	--进度有变化了，需要通知客户端
	if car_match_lib.need_notify_proc == 1  then
		car_match_lib.need_notify_proc = 0
		for k,v in pairs (car_match_lib.open_wnd_user_list) do
			local user_info = usermgr.GetUserById(v)
			if user_info ~= nil then
				--先发剩余时间再发主面板信息
				car_match_lib.send_main_box(user_info, match_info.match_type)
				car_match_lib.send_match_time(user_info, match_info.match_type)
                if car_match_lib.match_start_status[match_info.match_type] == 0 then
                    car_match_lib.send_next_match_time(user_info, match_info.match_type)
                end
				--出结果时，要把新的冠军列表通知客户端
				if match_info.proccess == 4 then
					car_match_lib.send_king_list(user_info, match_info.match_type)
				end
			end
		end
        --todo增加一个冒火的协议
    end
end

--加入NPC
function car_match_lib.add_npc(match_type)
	for k,v in pairs (car_match_lib.match_list[match_type].match_car_list) do
		local rand_num = car_match_lib.get_npc_num(match_type) or 1
		if v.car_id==0 then --如果这个位置上没有车报名，就加NPC
			v.car_id = car_match_lib.npc_car[match_type][rand_num].car_id
			v.car_type = car_match_lib.npc_car[match_type][rand_num].car_type
			v.match_user_id = car_match_lib.npc_car[match_type][rand_num].user_id
			v.match_nick_name = _U(car_match_lib.npc_car[match_type][rand_num].nick_name)
			v.match_user_face = "face/1025.jpg" --NPC的头像要怎么弄？todo
			v.king_count = car_match_lib.npc_car[match_type][rand_num].king_count or 0
			v.hui_xin = car_match_lib.npc_car[match_type][rand_num].hui_xin or 0
			v.jiacheng = car_match_lib.get_jiacheng_by_prize(car_match_lib.get_car_cost(v.car_type))
		end
	end

	--通知客户端变化主面板的信息
	--for k,v in pairs(car_match_lib.user_list) do
	for k,v in pairs(car_match_lib.open_wnd_user_list) do
		local user_info = usermgr.GetUserById(v)
		if user_info ~= nil and car_match_lib.user_list[v] ~= nil and 
				car_match_lib.user_list[v].match_info ~= nil and car_match_lib.user_list[v].match_info.match_type == match_type then
			car_match_lib.send_main_box(user_info, match_type, 1)
		end
	end
end

--检查时间
function car_match_lib.check_time(match_type)
	local table_time = os.date("*t",car_match_lib.current_time);
	local now_hour  = tonumber(table_time.hour);
    local now_min  = tonumber(table_time.min);
    if (car_match_lib.CFG_OPEN_TIME[match_type][now_hour] ~= nil and
        now_min >= car_match_lib.CFG_OPEN_TIME[match_type][now_hour][1]  and
        now_min <= car_match_lib.CFG_OPEN_TIME[match_type][now_hour][2]) then
        return 1
    end
	return 0
end

--查车子信息
function car_match_lib.query_car_info(user_info,query_car_list)
   	if not user_info then return end
   	local user_id = user_info.userId

   	if query_car_list==nil or query_car_list=="" then return end

	local call_back = function(car_list)
		netlib.send(function(buf)
		    buf:writeString("CARQUERY");
		    buf:writeInt(#car_list);
		    for k,v in pairs (car_list) do
		    	buf:writeInt(v.car_id);
		    	buf:writeInt(v.car_type);
		    	buf:writeInt(v.user_id);
		    	buf:writeString(v.nick_name);
		    	local car_gold = v.car_prize or 0
		    	buf:writeInt(car_gold); --车的价格
				buf:writeInt(v.hui_xin); --会心值
				buf:writeInt(v.king_count); --冠军次数
                buf:writeInt((v.jiacheng or 0) * 100); --奖金加成
		    end
		end,user_info.ip,user_info.port);
	end

   	local car_list_tab = split(query_car_list,",")

   	--因为数据层用的是in，所以加上限制防止一次性查太多影响性能
   	if #car_list_tab > 10 then return end

   	--查NPC的车的信息只会一辆一辆查，另外，暂时不支持混和查询
   	local is_npc = 0
   	if  #car_list_tab==1 and tonumber(car_list_tab[1]) < 0 then
		is_npc = 1
   	end

   	if  is_npc == 1 then
   		car_match_lib.get_npc_car_info(query_car_list,call_back)
   	else
   		car_match_db_lib.get_car_list(query_car_list,call_back)
   	end

end

--根据座位查车信息
function car_match_lib.query_carinfo_by_site(user_id, car_type, site, call_back)
   	--如果不是车的话就不返回消息
   	if car_match_lib.CFG_CAR_INFO[car_type] == nil then return end

   	--从数据库查询信息并返回
   	car_match_db_lib.query_carinfo_by_type(user_id, car_type, site, call_back)
end

--更新冠军车的信息
function car_match_lib.update_guanjun_info(match_type)
	local call_back = function(user_info, car_info, site)
		netlib.send(function(buf)
	    	buf:writeString("CARQTYPE");
	    	buf:writeInt(car_info.car_id)
	    	buf:writeInt(car_info.car_type)
	    	buf:writeInt(car_info.king_count)
	    	buf:writeInt(site)
	    end,user_info.ip,user_info.port);
	end

	for k,v in pairs(car_match_lib.match_list[match_type].match_car_list)do

		local car_id = v.car_id
		local match_user_id = v.match_user_id
		local match_user_info = usermgr.GetUserById(match_user_id)
		local nick_name = v.match_nick_name
		local car_type = v.car_type
        local car_prize = 0;
        if (match_user_id > 0) then --冠军为玩家
            car_prize = car_match_lib.get_user_car_prize(match_user_id, car_id)
        else
            car_prize = car_match_lib.get_car_cost(car_type)    --冠军为NPC
        end
		if(match_user_id==nil)then
			TraceError("拿冠军的人不是参赛者？？")
			TraceError(v)
		end
		--第一名写到冠军列表里去
		--给冠军车加冠军次数
		if v.mc == 1 then
			v.king_count = v.king_count + 1
            car_match_lib.init_user_king_info(match_user_id)
			local buf_tab = {
				["area_id"] = k2,
				["user_id"] = match_user_id,
				["nick_name"] = nick_name,
				["car_id"] = car_id,
				["car_type"] = car_type,
				["area_id"] = car_match_lib.match_list[match_type].open_num,
				["king_count"] = v.king_count,
				["car_prize"] = car_prize,
			}
			--历史冠军
			for k, v in pairs(car_match_lib.king_list[match_type]) do
				if v.car_id == car_id then
					v.king_count = buf_tab.king_count
				end
			end
			if #car_match_lib.king_list[match_type] < car_match_lib.CFG_KING_LEN then
				table.insert(car_match_lib.king_list[match_type], buf_tab)
			else
				table.remove(car_match_lib.king_list[match_type], 1)
				table.insert(car_match_lib.king_list[match_type], buf_tab)
			end
			--今日冠军
			for k, v in pairs(car_match_lib.today_king_list[match_type]) do
				if v.car_id == car_id then
					v.king_count = buf_tab.king_count
				end
			end
			if #car_match_lib.today_king_list[match_type] < car_match_lib.CFG_TODAY_KING_LEN then
				table.insert(car_match_lib.today_king_list[match_type], buf_tab)
			else
				table.remove(car_match_lib.today_king_list[match_type], 1)
				table.insert(car_match_lib.today_king_list[match_type], buf_tab)
            end

            if (match_user_id > 0) then
			    car_match_db_lib.add_king_list(match_type, buf_tab)
            end

			if match_user_info~=nil and car_match_lib.user_list[match_user_id].car_list[car_id] ~= nil then --如果玩家还在线，并且车没被卖掉
				car_match_lib.user_list[match_user_id].car_list[car_id].king_count = car_match_lib.user_list[match_user_id].car_list[car_id].king_count + 1
				car_match_lib.user_list[match_user_id].car_list[car_id].hui_xin = 0
			elseif match_user_id < 0 then --NPC得冠军
				for k1,v1 in pairs (car_match_lib.npc_car[match_type]) do
					if v1.user_id == match_user_id then
						v1.king_count = v.king_count
						v1.hui_xin = 0
					end
				end
			end

			--通知数据库给玩家加一次冠军次数
            if (match_user_id > 0) then
			    car_match_db_lib.add_king_count(car_id)
            end

			--王者之车
			car_match_lib.update_king_car_list(match_type, buf_tab)

			for k1,v1 in pairs (car_match_lib.match_list[match_type].match_car_list) do
				local user_info = usermgr.GetUserById(v1.match_user_id)
				if user_info ~= nil then
					car_match_lib.query_car_info(user_info, car_id)
				end
			end

			--设置得冠军的人的昵称
			car_match_lib.king_nick[match_type] = nick_name

			--更新玩家坐下时带的车的成就
			if match_user_info ~= nil and match_user_info.site ~= nil then
				--改成给桌内的人群发冠军次数信息
				--car_match_lib.query_carinfo_by_site(match_user_id, car_type, match_user_info.site, call_back)
				car_match_lib.refresh_using_king_count(match_user_id)
			end

			--记录数据库日志
			car_match_db_lib.record_car_car_match_log(match_user_id, car_match_lib.match_list[match_type].open_num, car_match_lib.match_list[match_type].match_id, match_type, car_id)
			
		else
			if v.hui_xin < car_match_lib.CFG_MAX_HUIXIN then
				v.hui_xin = v.hui_xin + 1
				if match_user_info~=nil and car_match_lib.user_list[match_user_id].car_list[car_id] ~= nil then
					car_match_lib.user_list[match_user_id].car_list[car_id].hui_xin = car_match_lib.user_list[match_user_id].car_list[car_id].hui_xin + 1
				elseif match_user_id < 0 then
					for k1,v1 in pairs (car_match_lib.npc_car[match_type]) do
						if v1.user_id == match_user_id then
							v1.hui_xin = v.hui_xin
						end
					end
				end
				car_match_db_lib.add_hui_xin(car_id)
			end
		end
	end

	--如果冠军产生了，就发小喇叭
	if car_match_lib.king_nick[match_type] ~= nil then
    	local msg = _U("恭喜")..car_match_lib.king_nick[match_type].._U("获得").._U(car_match_lib.CFG_MATCH_NAME[match_type]).._U("冠军。下场比赛报名即将开始")
    	tex_speakerlib.send_sys_msg(msg)
    	car_match_lib.king_nick[match_type] = nil
    end
end

--今日名人和历史名人
function car_match_lib.update_minren_list(user_id, match_type, buf_tab)
		local add_gold = buf_tab.add_gold
		if car_match_lib.user_list[user_id].match_info[match_type].today_win_gold == nil then car_match_lib.user_list[user_id].match_info[match_type].today_win_gold = 0 end
		if car_match_lib.user_list[user_id].match_info[match_type].week_win_gold == nil then car_match_lib.user_list[user_id].match_info[match_type].week_win_gold = 0 end

		car_match_lib.user_list[user_id].match_info[match_type].today_win_gold = car_match_lib.user_list[user_id].match_info[match_type].today_win_gold + add_gold
		car_match_lib.user_list[user_id].match_info[match_type].week_win_gold = car_match_lib.user_list[user_id].match_info[match_type].week_win_gold + add_gold
		buf_tab.today_win_gold = car_match_lib.user_list[user_id].match_info[match_type].today_win_gold
		buf_tab.week_win_gold = car_match_lib.user_list[user_id].match_info[match_type].week_win_gold
		if car_match_lib.today_minren_list[match_type] == nil then car_match_lib.today_minren_list[match_type] = {} end


		local tmp_index = #car_match_lib.today_minren_list[match_type]
		local finder = 0
		for k, v in pairs (car_match_lib.today_minren_list[match_type]) do
			if v.user_id == buf_tab.user_id then
				v.today_win_gold = buf_tab.today_win_gold
				finder = 1
				break
			end
		end
		if tmp_index < car_match_lib.CFG_TODAYMR_LEN then
			if finder ~= 1 then
				table.insert(car_match_lib.today_minren_list[match_type], buf_tab)
			end
			car_match_db_lib.add_today_minren(match_type, buf_tab)
		elseif car_match_lib.user_list[user_id].match_info[match_type].today_win_gold > car_match_lib.today_minren_list[match_type][tmp_index].today_win_gold then
			if finder ~= 1 then
				table.remove(car_match_lib.today_minren_list[match_type], tmp_index)
				table.insert(car_match_lib.today_minren_list[match_type], buf_tab)
			end
			car_match_db_lib.add_today_minren(match_type, buf_tab)
		end

		if car_match_lib.history_minren_list[match_type] == nil then car_match_lib.history_minren_list[match_type] = {} end

		tmp_index = #car_match_lib.history_minren_list[match_type]
		for k, v in pairs (car_match_lib.history_minren_list[match_type]) do
			if v.user_id == buf_tab.user_id then
				v.week_win_gold = buf_tab.week_win_gold
				finder = 2
				break
			end
		end
		if tmp_index < car_match_lib.CFG_WEEK_KING_LEN then
			if finder ~= 2 then
				table.insert(car_match_lib.history_minren_list[match_type], buf_tab)
			end
			car_match_db_lib.add_week_minren(match_type, buf_tab)
		elseif car_match_lib.user_list[user_id].match_info[match_type].week_win_gold > car_match_lib.history_minren_list[match_type][tmp_index].week_win_gold then
			if finder ~= 2 then
				table.remove(car_match_lib.history_minren_list[match_type], tmp_index)
				table.insert(car_match_lib.history_minren_list[match_type], buf_tab)
			end
			car_match_db_lib.add_week_minren(match_type, buf_tab)
		end

		--排序
		if #car_match_lib.today_minren_list[match_type] > 1 then
			table.sort(car_match_lib.today_minren_list[match_type],
			      function(a, b)
				     return a.today_win_gold > b.today_win_gold
			end)
		end
		if #car_match_lib.history_minren_list[match_type] > 1 then
			table.sort(car_match_lib.history_minren_list[match_type],
			      function(a, b)
				     return a.week_win_gold > b.week_win_gold
			end)
		end

end

--更新王者之车
function car_match_lib.update_king_car_list(match_type, old_buf_tab)
	local buf_tab = table.clone(old_buf_tab)
	--机器人不要去计算王者之车
	if buf_tab.user_id < 0 then return end
	if car_match_lib.king_car_list[match_type] == nil then car_match_lib.king_car_list[match_type] = {} end
	local car_id = buf_tab.car_id
	local len =#car_match_lib.king_car_list[match_type]
	local finder = 0
	for k, v in pairs(car_match_lib.king_car_list[match_type]) do
		if car_id == v.car_id then
			v.king_count = v.king_count + 1
			finder = 1
			break
		end
	end

	if len < car_match_lib.CFG_KINGCAR_LEN then
		if finder == 0 then
			table.insert(car_match_lib.king_car_list[match_type], buf_tab)
		end
		car_match_db_lib.add_kingcar_list(match_type, buf_tab)
	elseif buf_tab.king_count > car_match_lib.king_car_list[match_type][len].king_count then
		if finder == 0 then
			table.remove(car_match_lib.king_car_list[match_type], len)
			table.insert(car_match_lib.king_car_list[match_type], buf_tab)
		end
		car_match_db_lib.add_kingcar_list(match_type, buf_tab)
	end

	if len > 1 then
		table.sort(car_match_lib.king_car_list[match_type],
		      function(a, b)
			     return a.king_count > b.king_count
		end)
	end
end

--更新玩家的投注信息
function car_match_lib.update_bet_info(user_id,area_id,bet_count,match_type)
	--更新字符串中对应位置的值
	local update_bet=function(bet_info,area_id,bet_count)
		if(bet_info==nil or bet_info=="")then
			bet_info=car_match_lib.CFG_BET_INIT;
		end
		local tmp_tab=split(bet_info,",")
		local tmp_str=""
		local tmp_bet=0
		tmp_bet=tonumber(tmp_tab[area_id])

		if(tmp_bet==nil)then
			TraceError("error bet_info="..bet_info)
		end

		tmp_bet = tmp_bet + bet_count
		local gold_cost = bet_count * car_match_lib.CFG_BET_RATE[match_type]

		if gold_cost >= car_match_lib.CFG_XZGOLD_MSG then
			local user_info = usermgr.GetUserById(user_id)
			local msg_list = {}
			local msg_type = 3 --1报名成功 2赛车位被抢 3 献花超100万
			table.insert(msg_list, user_info.nick)
			table.insert(msg_list, car_match_lib.match_list[match_type].match_car_list[area_id].match_nick_name)
			table.insert(msg_list, bet_count)
			car_match_lib.send_all_message(match_type, msg_type, msg_list)
		end

		tmp_tab[area_id]=tostring(tmp_bet)

		for i=1,#tmp_tab do
			tmp_str=tmp_str..","..tmp_tab[i]
		end

		--更新下注的情况
		local tmp_bet_info=string.sub(tmp_str,2)

		return tmp_bet_info --去掉第1个逗号后返回
	end

	--更新玩家的投注信息
	local bet_info = car_match_lib.user_list[user_id].match_info[match_type].bet_info
	bet_info = update_bet(bet_info, area_id, bet_count)
	car_match_lib.user_list[user_id].match_info[match_type].bet_info = bet_info

	--更新数据库
	car_match_db_lib.update_bet_info(user_id,bet_info, car_match_lib.match_list[match_type].match_id, match_type)
	return car_match_lib.user_list[user_id].match_info[match_type].bet_info
end

--退还被插队的人的报名费
function car_match_lib.return_baoming_gold(user_id,return_chadui,match_type)
	return_chadui = return_chadui - 1
	local baoming_gold = car_match_lib.CFG_BAOMING_GOLD[match_type]
	local chadui_gold = baoming_gold * math.pow(2,return_chadui)
	if return_chadui == 0 then chadui_gold = 0 end
	local add_gold = baoming_gold + chadui_gold
	if chadui_num == 0 then
		add_gold = baoming_gold
	end

	--usermgr.addgold(user_id, add_gold, 0, new_gold_type.CAR_MATCH, -1);
  if match_type == 1 then
    usermgr.addgold(user_id, add_gold, 0, new_gold_type.CAR_MATCH_BEIQIANGWEI_1, -1);
  else
    usermgr.addgold(user_id, add_gold, 0, new_gold_type.CAR_MATCH_BEIQIANGWEI_2, -1);
  end
	
	if (car_match_sys_ctrl) then
		--car_match_sys_ctrl.update_win_info(match_type, -add_gold, car_match_lib.CFG_GOLD_TYPE.BACK_XIA_ZHU)
	end
end

--给参赛的人发奖
function car_match_lib.match_fajiang(match_type)
    --第一名的位置号
    local open_num = car_match_lib.match_list[match_type].open_num
    local user_id = 0
    local mingci = 0
    local add_gold = 0

    --给所有人发奖
    for i = 1, car_match_lib.CFG_CAR_NUM do
        mingci = car_match_lib.match_list[match_type].match_car_list[i].mc
        user_id = car_match_lib.match_list[match_type].match_car_list[mingci].match_user_id

        if  user_id > 0 then --处理玩家
            local xiazhu = car_match_lib.match_list[match_type].match_car_list[mingci].xiazhu or 0
            local jiacheng = car_match_lib.match_list[match_type].match_car_list[mingci].jiacheng
            if (mingci == open_num) then --第一名直接发奖
                --冠军奖金=当前车下注总额*当前车位倍率*加成比例
                local peilv = car_match_lib.match_list[match_type].match_car_list[mingci].peilv
                local car_id = car_match_lib.match_list[match_type].match_car_list[mingci].car_id
                add_gold = xiazhu * peilv * jiacheng * car_match_lib.CFG_BET_RATE[match_type]
                add_gold = math.floor(add_gold)
                car_match_lib.king_reward[match_type] = add_gold
                --usermgr.addgold(user_id, add_gold, 0, new_gold_type.CAR_MATCH, -1);
                if match_type == 1 then
                  usermgr.addgold(user_id, add_gold, 0, new_gold_type.CAR_MATCH_GAMEFANJIANG_1, -1);
                else
                  usermgr.addgold(user_id, add_gold, 0, new_gold_type.CAR_MATCH_GAMEFANJIANG_2, -1);
                end
                if (car_match_sys_ctrl) then
					car_match_sys_ctrl.update_win_info(match_type, -add_gold, car_match_lib.CFG_GOLD_TYPE.CAR_WIN)
				end
    		    --写日志
    		    car_match_db_lib.record_log_match_fajiang(user_id, add_gold, match_type)
            else    --其他名次保存起来，等结算过了以后再发奖
                add_gold = xiazhu * jiacheng * car_match_lib.CFG_BET_RATE[match_type]
                add_gold = math.floor(add_gold)
                car_match_lib.add_other_winner(user_id, mingci, jiacheng, add_gold, match_type)
            end
        else        --NPC只显示奖金
            if (mingci == open_num) then
                local xiazhu = car_match_lib.match_list[match_type].match_car_list[mingci].xiazhu or 0
                local jiacheng = car_match_lib.match_list[match_type].match_car_list[mingci].jiacheng
                local peilv = car_match_lib.match_list[match_type].match_car_list[mingci].peilv
                local car_id = car_match_lib.match_list[match_type].match_car_list[mingci].car_id
                add_gold = xiazhu * peilv * jiacheng * car_match_lib.CFG_BET_RATE[match_type]
                add_gold = math.floor(add_gold)
                car_match_lib.king_reward[match_type] = add_gold
            end
        end
    end
end

--给下注的人发奖
function car_match_lib.xiazhu_fajiang(match_type)
	--得到开出来的号码
	local open_num = car_match_lib.match_list[match_type].open_num
	for k,v in pairs (car_match_lib.user_list) do
		local user_id = v.user_id
		local nick_name = v.nick_name
		local img_url = v.img_url
		if v.match_info[match_type] ~=nil then
			local bet_info = v.match_info[match_type].bet_info or car_match_lib.CFG_BET_INIT
			local tmp_bet_tab = split(bet_info,",")
			local xiazhu = tonumber(tmp_bet_tab[open_num]) or 0 --开奖位的下注金额
			if xiazhu > 0 then
				--应该加多少钱
				local add_gold = xiazhu * car_match_lib.CFG_BET_RATE[match_type] * car_match_lib.match_list[match_type].match_car_list[open_num].peilv
				add_gold = math.floor(add_gold)
				--usermgr.addgold(user_id, add_gold, 0, new_gold_type.CAR_MATCH, -1);
        if match_type == 1 then
          usermgr.addgold(user_id, add_gold, 0, new_gold_type.CAR_MATCH_FANJIANG_1, -1);
        else
          usermgr.addgold(user_id, add_gold, 0, new_gold_type.CAR_MATCH_FANJIANG_2, -1);
        end
                
		        if (car_match_sys_ctrl) then
					car_match_sys_ctrl.update_win_info(match_type, -add_gold, car_match_lib.CFG_GOLD_TYPE.JIANG_JIN)
				end
				--加入中奖玩家列表
				local buf_tab = {
					["user_id"] = user_id,
					["add_gold"] = add_gold,
					["nick_name"] = nick_name, --这里要用car_match_lib.user_list的nick，而不是user_info的，因为car_match_lib.user_list是一轮之后才清的，不是玩家下线就清了
					["img_url"] = img_url,
				}
				table.insert(car_match_lib.all_zj_info[match_type], buf_tab)

				car_match_lib.update_minren_list(user_id, match_type, buf_tab)
				if add_gold > 0 then
					car_match_db_lib.record_log_xiazhu_fajiang(user_id, add_gold, match_type, bet_info)
                end
                
            end
            if (bet_info ~= car_match_lib.CFG_BET_INIT) then
                local match_id = car_match_lib.match_list[match_type].match_id
                car_match_db_lib.update_bet_info(user_id,car_match_lib.CFG_BET_INIT,match_id,match_type) --清掉下注信息
            end
		end
		local user_info = usermgr.GetUserById(user_id)
		if user_info == nil and car_match_lib.user_list[user_id] ~= nil then
			local other_match_type = match_type % 2 + 1 --得到另一场比赛的type
			--如果在另一场比赛中没下注就把玩家的信息清掉，节约内存
			if car_match_lib.user_list[user_id].match_info[other_match_type].bet_info == nil or
					car_match_lib.user_list[user_id].match_info[other_match_type].bet_info == car_match_lib.CFG_BET_INIT then
				car_match_lib.user_list[user_id] = nil
			end
		end
	end
end

--清数据
function car_match_lib.clear_car_king_data(current_time)
	local table_time = os.date("*t", current_time);
	local now_hour = table_time.hour
	local now_min = table_time.min
	local now_sec = table_time.sec

	if now_hour == 0 and now_min == 0 and now_sec == 1 then
        car_match_db_lib.clear_today_minren()
		car_match_lib.today_minren_list = {}
		car_match_lib.today_minren_list[1] = {}
		car_match_lib.today_minren_list[2] = {}
		--每周一清掉每周的排名数据
		local now_week = os.date("%w", current_time)
		if tonumber(now_week) == 1 then
            car_match_db_lib.clear_week_minren()
			car_match_lib.history_minren_list = {}
			car_match_lib.history_minren_list[1] = {}
			car_match_lib.history_minren_list[2] = {}
		end

		for k, v in pairs (car_match_lib.open_wnd_user_list) do
			local user_info = usermgr.GetUserById(v)
			if user_info ~= nil then
				car_match_lib.send_today_minren(user_info, 1)
				car_match_lib.send_history_minren(user_info, 1)

				car_match_lib.send_today_minren(user_info, 2)
				car_match_lib.send_history_minren(user_info, 2)
			end
		end

	end

end

--GM控制车
function car_match_lib.change_mc(match_type, mc)
    --只能第二阶段设置名次
    if ((match_type ~= 1 and match_type ~= 2) or
        #mc ~= 8 or car_match_lib.match_list[match_type].proccess ~= 2) then
        return
    end
    for i = 1, 8 do
        car_match_lib.match_list[match_type].match_car_list[mc[i]].mc = i
    end
    car_match_lib.match_list[match_type].open_num = mc[1]
	if (car_match_lib.gm_ctrl == nil) then
		car_match_lib.gm_ctrl = {0, 0}
	end
	car_match_lib.gm_ctrl[match_type] = 1
end

--加入一个获奖玩家
function car_match_lib.add_other_winner(user_id, mingci, jiacheng, add_gold, match_type)
    if (car_match_lib.match_list[match_type].other_winner == nil) then
        car_match_lib.match_list[match_type].other_winner = {}
    end
    local buf_tab = {
					["user_id"]  = user_id,
                    ["mingci"]   = mingci,
					["add_gold"] = add_gold,
					["jiacheng"] = jiacheng,
				}
	table.insert(car_match_lib.match_list[match_type].other_winner, buf_tab)
end

--给其他玩家发奖
function car_match_lib.give_other_winner(match_type)
    local tmp_tab = car_match_lib.match_list[match_type].other_winner
    if (tmp_tab ~= nil) then
        for k, v in pairs(tmp_tab) do
            local user_info = usermgr.GetUserById(v.user_id)
            car_match_lib.send_other_winner(user_info, v.jiacheng, v.add_gold, match_type)
            --usermgr.addgold(v.user_id, v.add_gold, 0, new_gold_type.CAR_MATCH, -1);
            if match_type == 1 then
              usermgr.addgold(v.user_id, v.add_gold, 0, new_gold_type.CAR_MATCH_GAMEFANJIANG_1, -1);
            else
              usermgr.addgold(v.user_id, v.add_gold, 0, new_gold_type.CAR_MATCH_GAMEFANJIANG_2, -1);
            end
            if (car_match_sys_ctrl) then
				car_match_sys_ctrl.update_win_info(match_type, -v.add_gold, car_match_lib.CFG_GOLD_TYPE.CAR_WIN)
			end
    		car_match_db_lib.record_log_match_fajiang(v.user_id, v.add_gold, match_type)
        end
        car_match_lib.match_list[match_type].other_winner = nil
    end
end

-------------------------------------------系统事件----------------------------------------------------------------
--定时器
function car_match_lib.timer(e)
    if(car_match_lib.check_match_room() == 0) then
        return;
    end
	local current_time = e.data.time;
    car_match_lib.current_time = current_time
	local tmp_match_type = 1

	--如果活动从无效变成有效，就需要通知客户端
	car_match_lib.send_match_status(1, current_time)
    car_match_lib.send_match_status(2, current_time)

	for i = 1, car_match_lib.CFG_MATCH_NUM do
		if car_match_lib.match_start_status[i] == 1 and
           car_match_lib.match_list == nil or car_match_lib.match_list[i]==nil then
			car_match_lib.init_match(i,current_time)
        else
			car_match_lib.set_proccess(car_match_lib.match_list[i],current_time)
		end
	end
	--notify_flag等于1时刷澳门的信息，等于2时刷维加斯的信息
	if car_match_lib.notify_flag > 0 then
		tmp_match_type = car_match_lib.notify_flag
		car_match_lib.notify_flag = 0 --先改标识，防止程序出错，不断的发消息
		--for k,v in pairs (car_match_lib.user_list) do
		for k,v in pairs (car_match_lib.open_wnd_user_list) do
			local user_info = usermgr.GetUserById(v)
			if user_info ~= nil then
				if car_match_lib.notify_flag == 999 then
					--两场比赛都刷
					for i=1,car_match_lib.CFG_MATCH_NUM do
						car_match_lib.send_main_box(user_info, i, 1)
					end
				else
					car_match_lib.send_main_box(user_info,tmp_match_type, 1)
				end
			end
		end
	end

	--如果有人下注了，通知客户端，有人下注
	if car_match_lib.send_bet_flag >0 and current_time % 2 == 0 then
		tmp_match_type = car_match_lib.send_bet_flag
		car_match_lib.send_bet_flag = 0
		if tmp_match_type == 999 then
			for i=1,car_match_lib.CFG_MATCH_NUM do
				car_match_lib.send_other_bet(i)
				--通知参赛选手更新奖金数，需要的话，这里是可以优化的。
				for j = 1, car_match_lib.CFG_CAR_NUM do
					car_match_lib.send_guanjun_reward(i,j)
				end
			end
		else
			car_match_lib.send_other_bet(tmp_match_type)
			--通知参赛选手更新奖金数，需要的话，这里是可以优化的。
			for j = 1, car_match_lib.CFG_CAR_NUM do
				car_match_lib.send_guanjun_reward(tmp_match_type, j)
			end
		end
	end

	for i = 1, car_match_lib.CFG_MATCH_NUM do
		--开赛前一分钟发小喇叭消息
		if car_match_lib.match_list ~= nil and car_match_lib.match_list[i] ~= nil and
           car_match_lib.match_list[i].proccess == 2 and
           car_match_lib.get_remain_time(i, current_time) == 60 then
			--全服发小喇叭通知开赛了
			tex_speakerlib.send_sys_msg(_U("格林披治大赛即将开始，赶紧前往围观！"))
			break
		end
	end

	math.random(1,100)

	if (e.data.time % 10 == 0 and car_match_lib.check_time(1) == 0 and car_match_lib.check_time(2) == 0) then
		for k,v in pairs (car_match_lib.user_list) do
			if (v.user_id ~= nil) then
			    local user_info = usermgr.GetUserById(v.user_id)
			    if user_info == nil then
				car_match_lib.user_list[k] = nil
			    end
			end
		end
	end

	car_match_lib.clear_car_king_data(current_time)
end

--gm指令，增加赛车控制
function car_match_lib.gm_cmd(e)
    if(car_match_lib.check_match_room() == 0) then
        return;
    end
    if (e.data["cmd"] == "change_car_rank" and e.data["args"][1] ~= nil) then
        local mc = {}
        for i = 2, 9 do
            table.insert(mc, tonumber(e.data["args"][i]))
        end
        car_match_lib.change_mc(tonumber(e.data["args"][1]), mc)
    end
end

--服务器重启了
function car_match_lib.restart_server()
    if(car_match_lib.check_match_room() == 0) then
        return;
    end
	--备份报名表，因为报名表不断在变化，防止有其他人在这个位置上报名，把用户数据清了，所以先备份，玩家登陆时，从备份表里给他退钱。
	car_match_db_lib.backup_baoming_table()

	--初始化重启前的match_id到内存里
	car_match_db_lib.init_restart_match_id()

	--初始化king_list
	car_match_db_lib.init_king_list()
	car_match_db_lib.init_today_king_list()
	car_match_db_lib.init_kingcar_list()
	car_match_db_lib.init_today_minren()
	car_match_db_lib.init_week_minren()

end

--给冠军发冠军宝箱
function car_match_lib.give_kingcar_box(match_type)
	local send_result = function(user_id, box_type)
		local user_info = usermgr.GetUserById(user_id)
		if user_info == nil then return end
		netlib.send(function(buf)
			buf:writeString("GCARKINGBOX")
			buf:writeByte(box_type)
		end, user_info.ip, user_info.port)
	end

	local carbox_type = tex_gamepropslib.PROPS_ID.KINGCAR_BOX1
	if match_type == 2 then
		carbox_type = tex_gamepropslib.PROPS_ID.KINGCAR_BOX2
	end

	for k,v in pairs(car_match_lib.match_list[match_type].match_car_list)do
		--得第一名的不是机器人
		if v.mc == 1 and v.match_user_id > 0 then
			--给玩家发宝箱
			tex_gamepropslib.add_tools(carbox_type, 1, v.match_user_id)

			--通知客户端弹框
			send_result(v.match_user_id, match_type)
			return
		end
	end
end

function car_match_lib.on_recv_open_box(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local box_type = buf:readByte()
	local item_id = tex_gamepropslib.PROPS_ID.KINGCAR_BOX1
	if box_type == 2 then
		item_id = tex_gamepropslib.PROPS_ID.KINGCAR_BOX2
	end
	if tex_gamepropslib then
		tex_gamepropslib.open_box(user_info, item_id)
	end
end

--比赛是否已经开始了
function car_match_lib.is_match_start(match_type)
    if (car_match_lib.match_list[match_type] ~= nil and
        car_match_lib.match_list[match_type].proccess >= 1 and
        car_match_lib.match_list[match_type].proccess <= 3) then
        return 1
    else
        return 0
    end
end

--得到玩家正在使用的车的冠军次数
function car_match_lib.get_useing_king_count(user_id)
	local user_info = usermgr.GetUserById(user_id)
	if user_info == nil then return -1 end
	local parking_data = parkinglib.user_list[user_info.userId]
	if parking_data == nil or parking_data.using_car == nil then return -1 end
	return parking_data.using_car.king_count or 0
end

--如果玩家在打牌时,正在使用的汽车king_count有更新，就用这个方法通知桌上的人处理一下
function car_match_lib.refresh_using_king_count(user_id)
	local user_info = usermgr.GetUserById(user_id)
	if user_info == nil or user_info.desk == nil or  user_info.site == nil then return end
	local use_king_count = car_match_lib.get_useing_king_count(user_id)
	netlib.broadcastdesk(
		function(buf)
            buf:writeString("FREKINGCO")
            buf:writeInt(user_info.site)
            buf:writeInt(use_king_count)            
		end, user_info.desk, borcastTarget.all)
end

function car_match_lib.open_or_close_wnd(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local show_status = buf:readByte()
	if show_status == 1 then
		car_match_lib.open_wnd_user_list[user_info.userId] = user_info.userId
	else
		car_match_lib.open_wnd_user_list[user_info.userId] = nil
	end
end

function car_match_lib.on_user_exit(e)
    local user_id = e.data.user_id;
    if(car_match_lib.open_wnd_user_list[user_id] ~= nil) then
        car_match_lib.open_wnd_user_list[user_id] = nil;
    end
end

--收到新手点击领车
function car_match_lib.on_recv_new_player(buf)
    local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
    if (car_match_sj_db_lib) then
        --加一辆天津大发
        --防止被刷的问题
        if (user_info.update_new_car_user == nil) then
            user_info.update_new_car_user = 1
            car_match_sj_lib.check_is_new_player(user_info.userId, function(ret) 
                car_match_db_lib.add_car(user_info.userId, 5043, 1, 1)
                --注册车队信息
                car_match_sj_lib.add_team_exp(user_info.userId, 0, 0, 200, 4)
                car_match_sj_lib.add_gas(user_info.userId, 5, 4)
                user_info.update_new_car_user = nil
                netlib.send(function(buf) 
                    buf:writeString("CARGETCAR")
                    buf:writeInt(1)
                end, user_info.ip, user_info.port)
                car_match_sj_lib.send_team_info(user_info)
            end)
        end
    end
end

------------------------------------------------网络协议--------------------------------------------
cmdHandler =
{
    ["CARREST"]     = car_match_lib.on_recv_tuifei,                 --请求查询退费
	["CARJOIN"]     = car_match_lib.on_recv_baoming,                --请求报名
	["CAROPJN"]     = car_match_lib.on_recv_openjoin,               --客户端，点参赛或报名按钮
	["CAROPPL"]     = car_match_lib.on_recv_openpl,                 --打开活动面板
	["CARSTAT"]     = car_match_lib.on_recv_querystatus,            --客户端查询活动状态
	["CARXZ"]       = car_match_lib.on_recv_xiazhu,                 --客户端下注
	["CARQUERY"]    = car_match_lib.on_recv_carinfo,                --客户端查询车库信息
	["CARQTYPE"]    = car_match_lib.on_recv_carface_info,           --客户端头像时用到车的话，要查询车的一些信息
	["CARMC"]       = car_match_lib.on_recv_query_match_mc,         --查比赛名次
	["CARKINGIF"]   = car_match_lib.on_recv_query_king_info,        --查某个人得冠的信息
	["OCARKINGBOX"] = car_match_lib.on_recv_open_box,               --开宝箱
	["CARSHOW"]     = car_match_lib.open_or_close_wnd,              --记录打开和关闭面板，优化一下性能
	["CARGETCAR"]   = car_match_lib.on_recv_new_player,             --收到新手点击领车
	
}

--加载插件的回调
for k, v in pairs(cmdHandler) do
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("timer_second", car_match_lib.timer)
eventmgr:addEventListener("on_server_start", car_match_lib.restart_server)
eventmgr:addEventListener("gm_cmd", car_match_lib.gm_cmd)
eventmgr:addEventListener("on_user_exit", car_match_lib.on_user_exit)
