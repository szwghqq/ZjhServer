TraceError("init car_match_sj_lib...")

if car_match_sj_lib and car_match_sj_lib.timer then
	eventmgr:removeEventListener("timer_second", car_match_sj_lib.timer);
end

if car_match_sj_lib and car_match_sj_lib.restart_server then
	eventmgr:removeEventListener("on_server_start", car_match_sj_lib.restart_server);
end

if car_match_sj_lib and car_match_sj_lib.on_server_start then
	eventmgr:removeEventListener("on_server_start", car_match_sj_lib.on_server_start); 
end

if not car_match_sj_lib then
    car_match_sj_lib = _S
    {
		--方法

        ------------------------------------系统参数--------------------------------
        CFG_TODAY_KING_LEN = 10,    --最多10条冠军记录
		CFG_TOTALMATCH_TIME = 0,    --多长时间一场比赛
		CFG_BAOMING_TIME = 0,       --报名阶段需要多少时间
		CFG_MATCH_TIME = 0,         --比赛动画的时间
		CFG_LJ_TIME = 0,            --比赛领奖界面的显示时间
		CFG_CAR_NUM = 8,            --一共8辆车参赛
		CFG_MAX_TEAM_LEVEL = 100,   --车队最高等级
        CFG_TIME_DESC = "",         --比赛时段描述
        CFG_GAS_TIME = 30 * 60,      --汽油值恢复时间
		CFG_BAOMING_GOLD ={         --默认的报名费用
			[3] = 200,
		},
		CFG_OPEN_TIME = {
            [3] = {},
            },    --开放时段
		CFG_MATCH_NAME = {
			[3] = "升级赛",
		},
		CFG_GAME_ROOM = 18001,      --只能在德州的主服务器上做的操作
        CFG_WIN_CHANCE = {          --des:车位获胜概率
            [3] = {},
        },
        CFG_GAS_USE = 1,            --每场汽油值消耗
        CFG_GAS_MAX = 5,            --玩家最大汽油值保有量(自动恢复)
        temp_race_reward = {},
        race_reward = {             --奖励
            [20] = {
                {exp=400, chouma=500, flag=3, flag_num=1},
                {exp=300, chouma=300, flag=2, flag_num=1},
                {exp=300, chouma=300, flag=2, flag_num=1},
                {exp=200, chouma=0, flag=1, flag_num=1},
                {exp=200, chouma=0, flag=1, flag_num=1},
                {exp=200, chouma=0, flag=1, flag_num=1},
                {exp=200, chouma=0, flag=1, flag_num=1},
                {exp=200, chouma=0, flag=1, flag_num=1},
            },
            [40] = {
                {exp=400, chouma=500, flag=4, flag_num=1},
                {exp=300, chouma=300, flag=3, flag_num=1},
                {exp=300, chouma=300, flag=3, flag_num=1},
                {exp=200, chouma=0, flag=2, flag_num=1},
                {exp=200, chouma=0, flag=2, flag_num=1},
                {exp=200, chouma=0, flag=2, flag_num=1},
                {exp=200, chouma=0, flag=2, flag_num=1},
                {exp=200, chouma=0, flag=2, flag_num=1},
            },
            [100] = {
                {exp=400, chouma=500, flag=5, flag_num=1},
                {exp=300, chouma=300, flag=4, flag_num=1},
                {exp=300, chouma=300, flag=4, flag_num=1},
                {exp=200, chouma=0, flag=3, flag_num=1},
                {exp=200, chouma=0, flag=3, flag_num=1},
                {exp=200, chouma=0, flag=3, flag_num=1},
                {exp=200, chouma=0, flag=3, flag_num=1},
                {exp=200, chouma=0, flag=3, flag_num=1},
            },
		},
        exp_list = {},
        temp_exp_list = {
            [1] = 200,    [2]  = 400,   [3]  = 600,   [4]  = 800,   [5] = 1000,
            [6] = 1200,   [7]  = 1400,  [8]  = 1600,  [9]  = 1800,  [10] = 2000,
            [11] = 2200,  [12] = 2400,  [13] = 2600,  [14] = 2800,  [15] = 3000,
            [16] = 3200,  [17] = 3400,  [18] = 3600,  [19] = 3800,  [20] = 4000,
            [21] = 4200,  [22] = 4400,  [23] = 4600,  [24] = 4800,  [25] = 5000,
            [26] = 5200,  [27] = 5400,  [28] = 5600,  [29] = 5800,  [30] = 6000,
            [31] = 6200,  [32] = 6400,  [33] = 6600,  [34] = 6800,  [35] = 7000,
            [36] = 7200,  [37] = 7400,  [38] = 7600,  [39] = 7800,  [40] = 8000,
            [41] = 8200,  [42] = 8400,  [43] = 8600,  [44] = 8800,  [45] = 9000,
            [46] = 9200,  [47] = 9400,  [48] = 9600,  [49] = 9800,  [50] = 10000,
            [51] = 10200, [52] = 10400, [53] = 10600, [54] = 10800, [55] = 11000,
            [56] = 11200, [57] = 11400, [58] = 11600, [59] = 11800, [60] = 12000,
            [61] = 12200, [62] = 12400, [63] = 12600, [64] = 12800, [65] = 13000,
            [66] = 13200, [67] = 13400, [68] = 13600, [69] = 13800, [70] = 14000,
            [71] = 14200, [72] = 14400, [73] = 14600, [74] = 14800, [75] = 15000,
            [76] = 15200, [77] = 15400, [78] = 15600, [79] = 15800, [80] = 16000,
            [81] = 16200, [82] = 16400, [83] = 16600, [84] = 16800, [85] = 17000,
            [86] = 17200, [87] = 17400, [88] = 17600, [89] = 17800, [90] = 18000,
            [91] = 18200, [92] = 18400, [93] = 18600, [94] = 18800, [95] = 19000,
            [96] = 19200, [97] = 19400, [98] = 19600, [99] = 19800, [100] = 20000,
        },
        gas_reason = {              --汽油加减原因 1:参赛 2:自动恢复 3:购买
            match = 1,
            huifu = 2,
            buy   = 3,
        },        
        notify_flag = 0,            --通知客户端刷新界面
		need_notify_proc = 0,       --通知进度有变化
        match_start_status = {[3] = 0},   --比赛是不是开始了
        current_time = 0,           --系统当前时间
		match_list = {},            --比赛信息
		user_list = {},             --在线玩家列表
        match_user_list = {},       --打开比赛面板的玩家列表
		today_king_list = {         --冠军列表
			[3] = {},
		},
		restart_match_id = {        --如果有重启过，记录重启前的match_id是多少
			[3] = 0,
		},
        car_flag_sign = {
            [1] = "flag1_num",       --普通车标
            [2] = "flag2_num",       --优良车标
            [3] = "flag3_num",       --珍贵车标
            [4] = "flag4_num",       --稀世车标
            [5] = "flag5_num",       --传奇车标
        },
        npc_num = {
			[3] = {},
		},
        match_reward_list = {},     --参赛奖励
        npc_num = {
			[3] = {},
		},
        npc_car ={
			[3] ={
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
					["nick_name"] = "苏蒂尔",
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
					["nick_name"] = "迪雷斯塔",
					["car_id"] = -108,
					["car_type"] = 5019,
				},
				[10]={
					["user_id"] = -109,
					["nick_name"] = "佩雷兹",
					["car_id"] = -109,
					["car_type"] = 5022,
				},
				[11]={
					["user_id"] = -110,
					["nick_name"] = "布埃米",
					["car_id"] = -110,
					["car_type"] = 5019,
				},
				[12]={
					["user_id"] = -111,
					["nick_name"] = "巴里切罗",
					["car_id"] = -111,
					["car_type"] = 5022,
				},
				[13]={
					["user_id"] = -112,
					["nick_name"] = "特鲁利",
					["car_id"] = -112,
					["car_type"] = 5019,
				},
				[14]={
					["user_id"] = -113,
					["nick_name"] = "莱科宁",
					["car_id"] = -113,
					["car_type"] = 5022,
				},
				[15]={
					["user_id"] = -114,
					["nick_name"] = "里尤兹",
					["car_id"] = -114,
					["car_type"] = 5019,
				},
				[16]={
					["user_id"] = -115,
					["nick_name"] = "汉密尔顿",
					["car_id"] = -115,
					["car_type"] = 5022,
				},
				[17]={
					["user_id"] = -200,
					["nick_name"] = "海德菲尔德",
					["car_id"] = -200,
					["car_type"] = 5017,
				},
				[18]={
					["user_id"] = -201,
					["nick_name"] = "佩特罗夫",
					["car_id"] = -201,
					["car_type"] = 5024,
				},
				[19]={
					["user_id"] = -202,
					["nick_name"] = "小皮奎特",
					["car_id"] = -202,
					["car_type"] = 5017,
				},
				[20]={
					["user_id"] = -203,
					["nick_name"] = "库特哈德",
					["car_id"] = -203,
					["car_type"] = 5024,
				},
				[21]={
					["user_id"] = -204,
					["nick_name"] = "格洛克",
					["car_id"] = -204,
					["car_type"] = 5024,
				},
				[22]={
					["user_id"] = -205,
					["nick_name"] = "斯图尔特",
					["car_id"] = -205,
					["car_type"] = 5017,
				},
				[23]={
					["user_id"] = -206,
					["nick_name"] = "普罗斯特",
					["car_id"] = -206,
					["car_type"] = 5024,
				},
				[24]={
					["user_id"] = -207,
					["nick_name"] = "布拉海姆",
					["car_id"] = -207,
					["car_type"] = 5017,
				},
				[25]={
					["user_id"] = -208,
					["nick_name"] = "马尔多纳多",
					["car_id"] = -208,
					["car_type"] = 5024,
				},
				[26]={
					["user_id"] = -209,
					["nick_name"] = "费斯切拉",
					["car_id"] = -209,
					["car_type"] = 5017,
				},
				[27]={
					["user_id"] = -210,
					["nick_name"] = "巴顿",
					["car_id"] = -210,
					["car_type"] = 5024,
				},
				[28]={
					["user_id"] = -211,
					["nick_name"] = "维特尔",
					["car_id"] = -211,
					["car_type"] = 5017,
				},
				[29]={
					["user_id"] = -212,
					["nick_name"] = "马萨",
					["car_id"] = -212,
					["car_type"] = 5024,
				},
				[30]={
					["user_id"] = -213,
					["nick_name"] = "阿隆索",
					["car_id"] = -213,
					["car_type"] = 5017,
				},
				[31]={
					["user_id"] = -214,
					["nick_name"] = "罗斯伯格",
					["car_id"] = -214,
					["car_type"] = 5024,
				},
				[32]={
					["user_id"] = -215,
					["nick_name"] = "韦伯",
					["car_id"] = -215,
					["car_type"] = 5017,
				},
			},
		},
    }
end

------------------------------------------------网络请求--------------------------------------------

--收到报名
function car_match_sj_lib.on_recv_baoming(buf)
    local send_baoming_result = function(user_info,result)
	 	netlib.send(function(buf)
        	buf:writeString("SJCARJOIN");
        	buf:writeInt(result)
        end,user_info.ip,user_info.port);
	end

	local user_info = userlist[getuserid(buf)];
   	if not user_info then return end;

   	local car_id = buf:readInt()
   	local area_id = buf:readByte()
   	local match_type = buf:readByte()
   	local car_type = buf:readInt()
   	local user_id = user_info.userId
   	local result = 1

   	--[[返回值说明:
    -1,此位置其他人已报名或插队
    -2 报名时间过期
    -3 报名费用不足
    -4 在其他位置上报过名了
    -5 汽油值不足
    -0 其他无效报名
    --]]

    --活动不是有效时直接不允许报名
   	if car_match_sj_lib.match_start_status[match_type] == 0 then return end

    if car_match_sj_lib.match_list[match_type].proccess ~= 1 then
   	   	send_baoming_result(user_info, -2)
   		return
   	end

    --报名的这个位置已经有人了
    if (car_match_sj_lib.match_list[match_type].match_car_list[area_id].match_user_id ~= nil) then
   		send_baoming_result(user_info, -1)
   		return
   	end

    --报名费用不足
    local need_gold = car_match_sj_lib.get_baoming_gold(match_type)
    local usergold = get_canuse_gold(user_info)
   	if usergold < need_gold then
   		send_baoming_result(user_info, -3)
   		return
    end

    --汽油值不足
    local user_gas = car_match_sj_lib.user_list[user_info.userId].gas_num
    if (user_gas < 1) then
        send_baoming_result(user_info, -5)
   		return
    end

    --在其他位置上报过名了
   	for k,v in pairs(car_match_sj_lib.match_list[match_type].match_car_list) do
   		if v.match_user_id == user_id then
   			send_baoming_result(user_info,-4)
   			return
   		end
   	end

   	--以上条件都满足，进行报名
    local team_lv = car_match_sj_lib.user_list[user_id].team_lv
    local team_exp = car_match_sj_lib.user_list[user_id].team_exp
   	usermgr.addgold(user_id, -need_gold, 0, new_gold_type.CAR_MATCH, -1)    --扣筹码
    car_match_sj_lib.add_gas(user_id, -car_match_sj_lib.CFG_GAS_USE, car_match_sj_lib.gas_reason.match)  --扣汽油
    
   	car_match_sj_lib.match_list[match_type].match_car_list[area_id].car_id = car_id
   	car_match_sj_lib.match_list[match_type].match_car_list[area_id].match_user_id = user_id
   	car_match_sj_lib.match_list[match_type].match_car_list[area_id].match_nick_name = user_info.nick
   	car_match_sj_lib.match_list[match_type].match_car_list[area_id].match_user_face = user_info.imgUrl or ""
   	car_match_sj_lib.match_list[match_type].match_car_list[area_id].car_type = car_type
    car_match_sj_lib.match_list[match_type].match_car_list[area_id].team_lv = team_lv
    car_match_sj_lib.match_list[match_type].match_car_list[area_id].team_exp = team_exp
   	send_baoming_result(user_info,result)

    --发车队信息
    car_match_sj_lib.send_team_info(user_info)
   	--标记一下刷新
   	car_match_sj_lib.notify_flag = match_type
    
 	--通知数据层保存报名数据
 	local baoming_num = 0
 	local match_id = car_match_sj_lib.match_list[match_type].match_id
 	car_match_sj_db_lib.update_car_baoming(area_id, car_id, user_id, baoming_num, match_type, match_id)
end

--收到打开报名选车面板
function car_match_sj_lib.on_recv_openjoin(buf)
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
   	need_gold = car_match_sj_lib.get_baoming_gold(match_type)
   	local car_num = get_car_num(car_match_lib.user_list[user_id].car_list)

   	--得到可以报名的车
   	local match_car_list = {}
   	for k,v in pairs(car_match_lib.user_list[user_id].car_list) do
   		if v.car_type ~= nil and car_match_lib.CFG_CAR_INFO[v.car_type] ~= nil then
			table.insert(match_car_list,v)
		end
   	end

   	netlib.send(function(buf)
        buf:writeString("SJCAROPJN");
        buf:writeInt(need_gold)
        buf:writeInt(#match_car_list)
        for k,v in pairs (match_car_list) do
        	buf:writeInt(v.car_id)
        	buf:writeInt(v.car_type)
        end
     end, user_info.ip, user_info.port);
end

--收到打开面板
function car_match_sj_lib.on_recv_openpl(buf)
	local user_info = userlist[getuserid(buf)];
   	if not user_info then return end;
   	local user_id = user_info.userId
   	local match_type = buf:readByte() --得到比赛的ID

    --保存打开面板的玩家信息
    if (car_match_sj_lib.user_list[user_id] ~= nil) then
        car_match_sj_lib.match_user_list[user_id] = {}
   	    car_match_sj_lib.match_user_list[user_id] = car_match_sj_lib.user_list[user_id]
    end
    --判断关闭面板的期间是否要加汽油
    car_match_sj_lib.add_off_line_gas(user_id)
    --发主面板的信息
    car_match_sj_lib.send_main_box(user_info,match_type)
    --发送剩余时间
    car_match_sj_lib.send_match_time(user_info,match_type)
	--发送最近冠军
    car_match_sj_lib.send_today_king(user_info, match_type)
    --发奖励信息
    car_match_sj_lib.send_match_reward(user_info, match_type)
	--发下一轮比赛开始的时间
	car_match_sj_lib.send_next_match_time(user_info, match_type)
end

--客户端查询活动状态
--byte 1有效 -1整体上线时间过期 -2不是有效的时段 0其他异常
function car_match_sj_lib.on_recv_querystatus(buf)
	local user_info = userlist[getuserid(buf)];
	if not user_info then return end;
	local match_type = buf:readInt()

	local send_result = function(user_info,status)
	   	netlib.send(function(buf)
	        buf:writeString("SJCARSTAT");
	        buf:writeByte(status);
			buf:writeByte(match_type);
    	end,user_info.ip,user_info.port);
	end

    --比赛未开始
    if car_match_sj_lib.match_start_status[match_type] == 0 then
    	send_result(user_info,-2)
    	return
    end
    if car_match_sj_lib.check_time(match_type)==1 then
    	send_result(user_info,1)
    	return
    end
   	--不是有效时段
   	send_result(user_info,-2)
end

--收到查比赛名次
function car_match_sj_lib.on_recv_query_match_mc(buf)
	local user_info = userlist[getuserid(buf)];
   	if not user_info then return end;
   	local match_type = buf:readByte()
	car_match_sj_lib.send_match_mc(match_type)
end

--收到关闭活动面板
function car_match_sj_lib.on_recv_closepl(buf)
    local user_info = userlist[getuserid(buf)];
    car_match_sj_lib.match_user_list[user_info.userId] = nil
end

--收到请求恢复汽油
function car_match_sj_lib.on_recv_get_gas(buf)
    local user_info = userlist[getuserid(buf)];
   	if not user_info then return end;

    local send_result = function(user_info, result, over_time)
	 	netlib.send(function(buf)
        	buf:writeString("GETGAS");
        	buf:writeInt(result)
        end, user_info.ip, user_info.port);
	end

    local current_time = os.time()
    local over_time = current_time - car_match_sj_lib.user_list[user_info.userId].gas_time  --已过CD时间
    local result = 1
    local gas_num = car_match_sj_lib.user_list[user_info.userId].gas_num    --玩家剩余汽油

    if (gas_num < car_match_sj_lib.CFG_GAS_MAX) then            --玩家剩余汽油小于最大汽油值保有量
        if (over_time >= car_match_sj_lib.CFG_GAS_TIME) then    --已过CD时间大于等于30分钟可恢复
            local add_gas_num = math.floor(over_time / car_match_sj_lib.CFG_GAS_TIME)
            car_match_sj_lib.add_gas(user_info.userId, add_gas_num, car_match_sj_lib.gas_reason.huifu)
            send_result(user_info, result)
            car_match_sj_lib.send_team_info(user_info)          --正确恢复后发车队信息给客户端
        else        --时间未到就请求,把上次恢复时间再发回客户端倒计时
            TraceError("玩家"..user_info.userId.."未到冷却时间请求恢复汽油")
            result = -1
            send_result(user_info, result)
            car_match_sj_lib.send_team_info(user_info)
        end
    else
        TraceError("玩家"..user_info.userId.."汽油值已满")  --应该不会出现这种情况
        --car_match_sj_lib.user_list[user_info.userId].gas_time = 0
        result = -2
        send_result(user_info, result)
    end
    
end

------------------------------------网络发送------------------------------------------

--发本阶段剩余时间
function car_match_sj_lib.send_match_time(user_info,match_type)
	--如果活动还没开始，就不要发比赛时间了
	if car_match_sj_lib.match_start_status[match_type] == 0 then return end
	local current_time = car_match_sj_lib.current_time
	local match_info = car_match_sj_lib.match_list[match_type]
	local remain_time = car_match_sj_lib.get_remain_time(match_type, current_time)
	netlib.send(function(buf)
       buf:writeString("SJCARTIME"); --通知客户端
       buf:writeByte(match_info.match_type);
	   buf:writeByte(match_info.proccess);
	   buf:writeInt(remain_time);
	end,user_info.ip,user_info.port)
end

--发主面板的信息
function car_match_sj_lib.send_main_box(user_info, match_type)
	if car_match_sj_lib.match_list[match_type] == nil or car_match_sj_lib.match_list[match_type].proccess == nil then return end
    local user_id = user_info.userId
 	netlib.send(function(buf)
        buf:writeString("SJCAROPPL");
        buf:writeByte(car_match_sj_lib.match_list[match_type].proccess)     --阶段
        buf:writeInt(car_match_sj_lib.get_remain_time(match_type, car_match_sj_lib.current_time)) --剩余时间
        buf:writeInt(car_match_sj_lib.CFG_MATCH_TIME)   --比赛阶段时长
        buf:writeByte(car_match_sj_lib.CFG_CAR_NUM)
        for  i = 1,car_match_sj_lib.CFG_CAR_NUM do
        	  buf:writeByte(i)
        	  buf:writeInt(car_match_sj_lib.match_list[match_type].match_car_list[i].car_id)     --车id
              buf:writeInt(car_match_sj_lib.match_list[match_type].match_car_list[i].mc)
        	  --比赛的玩家ID
              local match_user_team_lv = car_match_sj_lib.match_list[match_type].match_car_list[i].team_lv
        	  local match_user_id = car_match_sj_lib.match_list[match_type].match_car_list[i].match_user_id
        	  local match_nick_name = car_match_sj_lib.match_list[match_type].match_car_list[i].match_nick_name
        	  local match_user_face = car_match_sj_lib.match_list[match_type].match_car_list[i].match_user_face
              buf:writeInt(match_user_team_lv or 0)
        	  buf:writeInt(match_user_id or 0)
        	  buf:writeString(match_nick_name or "")
        	  local car_type = car_match_sj_lib.match_list[match_type].match_car_list[i].car_type or 0
        	  buf:writeInt(car_type)
        	  buf:writeString(match_user_face or "")
        end
        --1到1000的随机数控制客户端挑选一个比赛动画
        local seed = car_match_sj_lib.match_list[match_type].current_rand_num or 1000
        buf:writeInt(seed)
        buf:writeByte(match_type)
    end, user_info.ip, user_info.port);
end

--发送车队信息
function car_match_sj_lib.send_team_info(user_info)
    if user_info == nil then return end
    local user_id = user_info.userId
    local team_lv = car_match_sj_lib.user_list[user_id].team_lv   --车队等级
    local next_lv_exp = car_match_sj_lib.exp_list[team_lv + 1] or 0 --下一级所需经验
    netlib.send(function(buf)
        buf:writeString("CARTEAMINFO");
        buf:writeString(user_info.gamescore)
        buf:writeInt(#car_match_sj_lib.car_flag_sign)  --车标种类数量
        for i = 1, #car_match_sj_lib.car_flag_sign do
            buf:writeInt(car_match_sj_lib.user_list[user_id]["flag"..i.."_num"])
        end
        buf:writeInt(car_match_sj_lib.user_list[user_id].gas_num)    --汽油值
        buf:writeInt(team_lv)               --车队等级
        buf:writeInt(car_match_sj_lib.user_list[user_id].team_exp)   --车队经验
        buf:writeInt(next_lv_exp)           --下一级所需经验
        local gas_time = 0
        if (car_match_sj_lib.user_list[user_id].gas_time ~= 0) then
            gas_time = car_match_sj_lib.CFG_GAS_TIME - (os.time() - car_match_sj_lib.user_list[user_id].gas_time)
        end
        buf:writeString(gas_time)   --汽油值恢复时间
    end, user_info.ip, user_info.port)
end

--时间到了，通知开赛
function car_match_sj_lib.send_match_status(match_type, current_time)
	local send_result = function(status)
		for k,v in pairs (car_match_sj_lib.match_user_list) do
			local user_info = usermgr.GetUserById(v.user_id)
			if user_info~=nil then
			   	netlib.send(function(buf)
			        buf:writeString("SJCARSTAT");
			        buf:writeByte(status);
					buf:writeByte(match_type);
		    	end,user_info.ip,user_info.port);
		    	car_match_sj_lib.send_match_time(user_info,match_type);
	    	end
    	end
    end

    local total_time = car_match_sj_lib.CFG_TOTALMATCH_TIME / 60;   --一场比赛的时间
    local table_time = os.date("*t", current_time);
    local now_min = table_time.min
    local times = math.floor(60 / total_time);      --一小时内可开的场次
    for i = 1, times do
        if (now_min == (i * total_time == 60 and 0 or i * total_time)) then
            if (car_match_sj_lib.match_start_status[match_type] == 0 and car_match_sj_lib.check_time(match_type) == 1) then
                car_match_sj_lib.match_start_status[match_type] = 1
                car_match_sj_lib.init_match(match_type, current_time)
                send_result(1)
                return
            end
        end
    end
end

--时间到了，通知开赛
function car_match_sj_lib.send_match_status2(current_time, match_type)
	local send_result = function(status)
		for k,v in pairs (car_match_sj_lib.match_user_list) do
			local user_info = usermgr.GetUserById(v.user_id)
			if user_info~=nil then
			   	netlib.send(function(buf)
			        buf:writeString("SJCARSTAT");
			        buf:writeByte(status);
					buf:writeByte(match_type);
		    	end,user_info.ip,user_info.port);
	    	end
    	end
	end
    --活动从有效变成无效了
	if car_match_sj_lib.match_start_status[match_type] == 1 and
       car_match_sj_lib.check_time(match_type)==0 then
        car_match_sj_lib.match_start_status[match_type] = 0
        send_result(-2)
        return
    end
end

--发下一个开始时间给客户端
function car_match_sj_lib.send_next_match_time(user_info, match_type)
	--如果比赛已经开始，就不用再进这个方法了
	if car_match_sj_lib.match_start_status[match_type] == 1 then
		return
	end
    local total_time = car_match_sj_lib.CFG_TOTALMATCH_TIME / 60;   --一场比赛的时间
	local table_time = os.date("*t", car_match_sj_lib.current_time);
	local now_hour = table_time.hour
	local now_min = table_time.min
	local start_hour = ""
	local start_min = ""
    local need_calc = 1
	if (car_match_sj_lib.CFG_OPEN_TIME[match_type][now_hour] ~= nil and
        now_min + total_time <= car_match_sj_lib.CFG_OPEN_TIME[match_type][now_hour][2]) then
        local times = math.floor(60 / total_time);      --一小时内可开的场次
        for i = 1, times do
            if (now_min < i * total_time) then
                start_hour = now_hour;
                start_min = i * total_time;
                if (start_min < car_match_sj_lib.CFG_OPEN_TIME[match_type][now_hour][1]) then
                    start_min = car_match_sj_lib.CFG_OPEN_TIME[match_type][now_hour][1]
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
            if (car_match_sj_lib.CFG_OPEN_TIME[match_type][next_time] ~= nil) then
                start_hour = next_time;
                start_min = car_match_sj_lib.CFG_OPEN_TIME[match_type][next_time][1];
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
        msg = _U("测试已结束，敬请期待新年新版本!")
    end
    netlib.send(function(buf)
        buf:writeString("SJCARDES")
        buf:writeString(msg)
        buf:writeInt(match_type)
    end,user_info.ip,user_info.port);
end


--发最近冠军功能
function car_match_sj_lib.send_today_king(user_info, match_type)
    if (car_match_sj_lib.match_list[match_type] == nil or 
        car_match_sj_lib.match_list[match_type].proccess ~= 1) then return end;
	if car_match_sj_lib.today_king_list[match_type] == nil then car_match_sj_lib.today_king_list[match_type] = {} end
	local len = #car_match_sj_lib.today_king_list[match_type]
	if len > car_match_sj_lib.CFG_TODAY_KING_LEN then
		len = car_match_sj_lib.CFG_TODAY_KING_LEN
    end

	netlib.send(function(buf)
		buf:writeString("SJCARJRGJ")
		buf:writeByte(match_type)
		buf:writeInt(len)
		for i = 1, len do
			buf:writeInt(car_match_sj_lib.today_king_list[match_type][i].user_id)
			buf:writeInt(car_match_sj_lib.today_king_list[match_type][i].area_id)
			buf:writeString(car_match_sj_lib.today_king_list[match_type][i].nick_name)
			buf:writeInt(car_match_sj_lib.today_king_list[match_type][i].car_id)
			buf:writeInt(car_match_sj_lib.today_king_list[match_type][i].car_type)
		end
	end,user_info.ip, user_info.port)
end

--发送比赛奖励
function car_match_sj_lib.send_match_reward(user_info, match_type)
    if (car_match_sj_lib.match_list[match_type] == nil or 
        car_match_sj_lib.match_list[match_type].proccess ~= 4) then return end;
    local send_func = function(buf_tab, match_type)
        if (user_info ~= nil) then
            local car_type = car_match_sj_lib.match_list[match_type].match_car_list[buf_tab.area_id].car_type
            netlib.send(function(buf)
                buf:writeString("SJCARREWARD")
                buf:writeString(buf_tab.nick_name or "")
                buf:writeString(buf_tab.img_url or "")
                buf:writeInt(buf_tab.area_id)
                buf:writeInt(car_type)
                buf:writeInt(buf_tab.add_gold)
                buf:writeInt(buf_tab.add_exp)
                buf:writeInt(buf_tab.flag_lv)
                buf:writeInt(buf_tab.flag_num)
                buf:writeInt(buf_tab.add_gas)
                buf:writeInt(buf_tab.mingci)
                buf:writeInt(match_type)
            end, user_info.ip, user_info.port)
        end
    end
    --第一名的玩家id
    local open_num = car_match_sj_lib.match_list[match_type].open_num
    local open_num_user_id = car_match_sj_lib.match_list[match_type].match_car_list[open_num].match_user_id
    local buf_tab = car_match_sj_lib.match_reward_list[open_num_user_id]   --默认发第一名的
    --此列表里有玩家ID说明玩家是参赛的，要发他自己的参赛奖励
    if (car_match_sj_lib.match_reward_list[user_info.userId] ~= nil) then  
        buf_tab = car_match_sj_lib.match_reward_list[user_info.userId]
    end
    send_func(buf_tab, match_type)
end

--通知客户端汽油变化了
function car_match_sj_lib.send_gas_chenge(user_info, num)
    if not user_info then return end
    netlib.send(function(buf)
        buf:writeString("CARGASCHANGE")
        buf:writeInt(num)
    end, user_info.ip, user_info.port)
end
------------------------------------内部接口------------------------------------------
function car_match_sj_lib.check_match_room()
    return tonumber(groupinfo.groupid) == car_match_sj_lib.CFG_GAME_ROOM and 1 or 0;
end

--初始化某一轮比赛
function car_match_sj_lib.init_match(match_type, match_id)
	if car_match_sj_lib.match_list[match_type] == nil then car_match_sj_lib.match_list[match_type] = {} end
	car_match_sj_lib.match_list[match_type].match_type = match_type --3升级赛
	car_match_sj_lib.match_list[match_type].proccess = 1  --1报名插队 3比赛 4出结果
	car_match_sj_lib.match_list[match_type].start_time = match_id --match_id就是current_time
	car_match_sj_lib.match_list[match_type].current_rand_num = car_match_sj_lib.get_rand_num(1, 1000)
    car_match_sj_lib.match_reward_list = {}
    --活动有效时才做这步
	if car_match_sj_lib.match_start_status[match_type] == 1 then
		car_match_sj_lib.match_list[match_type].match_id = match_id..""..match_type
    end

	--初始化赛车手和赛场信息
	car_match_sj_lib.match_list[match_type].match_car_list = {}
	for i = 1,car_match_sj_lib.CFG_CAR_NUM do
		car_match_sj_lib.match_list[match_type].match_car_list[i] = {}
		car_match_sj_lib.match_list[match_type].match_car_list[i].area_id = i --几号跑道
		car_match_sj_lib.match_list[match_type].match_car_list[i].car_id = 0  --这个位置上的车
        car_match_sj_lib.match_list[match_type].match_car_list[i].win_chance = 0   --当前这个位置的获胜概率
		car_match_sj_lib.match_list[match_type].match_car_list[i].mc = 0      --当前名次
		car_match_sj_lib.match_list[match_type].match_car_list[i].car_type = 0 --这个位置停了什么车
        car_match_sj_lib.match_list[match_type].match_car_list[i].team_lv = 0   --车队等级
        car_match_sj_lib.match_list[match_type].match_car_list[i].team_exp = 0
	end

	--初始化获胜概率
	car_match_sj_lib.init_win_chance(match_type)

	--初始化NPC的号
	if car_match_sj_lib.npc_num == nil then car_match_sj_lib.npc_num = {} end
	car_match_sj_lib.npc_num[match_type] ={}

	for i=1,#car_match_sj_lib.npc_car[match_type] do        
    	table.insert(car_match_sj_lib.npc_num[match_type],i)
	end
end

--修改8个位置的赢率
function car_match_sj_lib.init_win_chance(match_type)
	local car_box = car_match_sj_lib.match_list[match_type].match_car_list
    for i=1,#car_box do
        car_match_sj_lib.match_list[match_type].match_car_list[i].win_chance = car_match_sj_lib.CFG_WIN_CHANCE[match_type][i]
    end
end

--得到比赛名次
function car_match_sj_lib.get_match_mc(match_type)
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
		local rand_num = car_match_sj_lib.get_rand_num(1, total_chance)
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
	local car_box = table.clone(car_match_sj_lib.match_list[match_type].match_car_list)
	local mc = {}

	--用递归算法 得到各个车的名次
	for i = 1,car_match_sj_lib.CFG_CAR_NUM do
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
		local area_id = mc[i]
		car_match_sj_lib.match_list[match_type].match_car_list[area_id].mc = i
		if i == 1 then
			car_match_sj_lib.match_list[match_type].open_num = area_id
		end
	end
end

--得到当前阶段的剩余时间
function car_match_sj_lib.get_remain_time(match_type, current_time)
	local match_info = car_match_sj_lib.match_list[match_type]
	local use_time = current_time - match_info.start_time --现在用了多少时间
	local remain_time = 0
	--计算剩余时间
	if use_time < car_match_sj_lib.CFG_BAOMING_TIME then
		remain_time = car_match_sj_lib.CFG_BAOMING_TIME - use_time
	elseif use_time < car_match_sj_lib.CFG_BAOMING_TIME + car_match_sj_lib.CFG_MATCH_TIME then
		remain_time = car_match_sj_lib.CFG_BAOMING_TIME + car_match_sj_lib.CFG_MATCH_TIME - use_time
	elseif use_time < car_match_sj_lib.CFG_BAOMING_TIME + car_match_sj_lib.CFG_MATCH_TIME + car_match_sj_lib.CFG_LJ_TIME then
		remain_time = car_match_sj_lib.CFG_BAOMING_TIME + car_match_sj_lib.CFG_MATCH_TIME + car_match_sj_lib.CFG_LJ_TIME - use_time
	end

	if car_match_sj_lib.check_time(match_type) ~= 1 and car_match_sj_lib.match_start_status[match_type]==0 then
		remain_time = -1
	end
	return remain_time
end

--稍微处理一下LUA的随机算法，防止 被人找到规律
function car_match_sj_lib.get_rand_num(min_num, max_num)
		local buf_tab = {}
		for i = 1, 100 do
			table.insert(buf_tab, math.random(min_num, max_num))
        end
		return buf_tab[math.random(10, 80)]
end

--得到车的名字
function car_match_sj_lib.get_car_name(car_type)
	return car_match_lib.CFG_CAR_INFO[car_type].name
end

--得到基础车的价格
function car_match_sj_lib.get_car_cost(car_type)
	return car_match_lib.CFG_CAR_INFO[car_type].cost
end

--得到玩家车的价格
function car_match_sj_lib.get_user_car_prize(user_id, car_id)
    if (car_match_lib.user_list[user_id] ~= nil and car_match_lib.user_list[user_id].car_list[car_id] ~= nil) then
        return car_match_lib.user_list[user_id].car_list[car_id].car_prize
    else
        return 0
    end
end

--得到比赛的名字
function car_match_sj_lib.get_match_name(match_type)
	return car_match_sj_lib.CFG_MATCH_NAME[match_type]
end

--得到报名或插队需要的钱
function car_match_sj_lib.get_baoming_gold(match_type)
	local baoming_gold = car_match_sj_lib.CFG_BAOMING_GOLD[match_type]
    return baoming_gold
end

--从NPC列表中抽取一个NPC参赛
function car_match_sj_lib.get_npc_num(match_type)
	local npc_count = #car_match_sj_lib.npc_num[match_type]
	local rand_num = math.random(1,npc_count or 8) --挑一个NPC
	local tmp_num = car_match_sj_lib.npc_num[match_type][rand_num]
	if(tmp_num==nil)then
		TraceError("NPC抽取算法出错了！")
		TraceError(car_match_sj_lib.npc_num[match_type])
	end

	table.remove(car_match_sj_lib.npc_num[match_type], rand_num)
	return tmp_num
end

--设置当前在第几阶段
function car_match_sj_lib.set_proccess(match_info,current_time)
	--如果不是有效时间，并且还没进入第二阶段，就不再改比赛的阶段
	--目的：让未开赛的比赛不再继续，让已开赛的比赛跑完，然后不再继续
	if car_match_sj_lib.match_start_status[match_info.match_type] == 0 and match_info.proccess == 1 then
		return
    end
    if match_info.proccess == 4 then
        car_match_sj_lib.send_match_status2(current_time, match_info.match_type)
        --比赛已经结束
        if car_match_sj_lib.match_start_status[match_info.match_type] == 0 then
    		car_match_sj_lib.init_match(match_info.match_type, current_time)
			car_match_sj_lib.need_notify_proc = 1
        end
    end
    if (car_match_sj_lib.check_time(match_info.match_type) == 1 and
        current_time >= match_info.start_time + car_match_sj_lib.CFG_TOTALMATCH_TIME) then
        car_match_sj_lib.init_match(match_info.match_type, current_time)
        car_match_sj_lib.need_notify_proc = 1
	elseif match_info.proccess < 3 and current_time >= match_info.start_time + car_match_sj_lib.CFG_BAOMING_TIME then
        match_info.proccess = 3
        --报名阶段完了，如果还有车位没报名，就加NPC
		car_match_sj_lib.add_npc(match_info.match_type)
		car_match_sj_lib.need_notify_proc = 1
   		car_match_sj_lib.get_match_mc(match_info.match_type)   		    --算出比赛的名次
        car_match_sj_db_lib.log_sj_match(match_info)    --记录比赛日志
	elseif match_info.proccess < 4 and current_time >= match_info.start_time + car_match_sj_lib.CFG_BAOMING_TIME + car_match_sj_lib.CFG_MATCH_TIME then
		match_info.proccess = 4
		car_match_sj_lib.need_notify_proc = 1
		car_match_sj_lib.match_fajiang(match_info.match_type)     		--给玩家发奖
		car_match_sj_lib.update_guanjun_info(match_info.match_type)     --更新冠军信息
        car_match_sj_db_lib.clear_baoming()                             --清报名
	end

	--进度有变化了，需要通知客户端
	if car_match_sj_lib.need_notify_proc == 1  then
		car_match_sj_lib.need_notify_proc = 0
		for k,v in pairs (car_match_sj_lib.match_user_list) do
			local user_info = usermgr.GetUserById(v.user_id)
			if user_info ~= nil then
				car_match_sj_lib.send_main_box(user_info, match_info.match_type)
				car_match_sj_lib.send_match_time(user_info, match_info.match_type)          --下场时间
                car_match_sj_lib.send_today_king(user_info, match_info.match_type)
                car_match_sj_lib.send_match_reward(user_info, match_info.match_type)
                car_match_sj_lib.send_team_info(user_info)
                if car_match_sj_lib.match_start_status[match_info.match_type] == 0 then
                    car_match_sj_lib.send_next_match_time(user_info, match_info.match_type)
                end
			end
		end
    end
end

--加入NPC
function car_match_sj_lib.add_npc(match_type)
	for k,v in pairs (car_match_sj_lib.match_list[match_type].match_car_list) do
		local rand_num = car_match_sj_lib.get_npc_num(match_type) or 1
		if v.car_id==0 then --如果这个位置上没有车报名，就加NPC
			v.car_id = car_match_sj_lib.npc_car[match_type][rand_num].car_id
			v.car_type = car_match_sj_lib.npc_car[match_type][rand_num].car_type
			v.match_user_id = car_match_sj_lib.npc_car[match_type][rand_num].user_id
			v.match_nick_name = _U(car_match_sj_lib.npc_car[match_type][rand_num].nick_name)
			v.match_user_face = "face/1025.jpg" --NPC的头像要怎么弄？todo
            v.team_lv = car_match_sj_lib.get_rand_num(1, 100)
            v.team_exp = 0
		end
	end

	--通知客户端变化主面板的信息
	for k,v in pairs(car_match_sj_lib.match_user_list) do
		local user_info = usermgr.GetUserById(v.user_id)
		if user_info ~= nil then
			car_match_sj_lib.send_main_box(user_info,match_type)
		end
	end
end

--检查时间
function car_match_sj_lib.check_time(match_type)
	local table_time = os.date("*t", car_match_sj_lib.current_time);
	local now_hour  = tonumber(table_time.hour);
    local now_min  = tonumber(table_time.min);
    if (car_match_sj_lib.CFG_OPEN_TIME[match_type][now_hour] ~= nil and
        now_min >= car_match_sj_lib.CFG_OPEN_TIME[match_type][now_hour][1]  and
        now_min <= car_match_sj_lib.CFG_OPEN_TIME[match_type][now_hour][2]) then
        return 1
    end
	return 0
end

--更新冠军车的信息
function car_match_sj_lib.update_guanjun_info(match_type)
	local call_back = function(user_info, car_info, site)
		netlib.send(function(buf)
	    	buf:writeString("SJCARQTYPE");
	    	buf:writeInt(car_info.car_id)
	    	buf:writeInt(car_info.car_type)
	    	buf:writeInt(site)
	    end,user_info.ip,user_info.port);
	end

	for k,v in pairs(car_match_sj_lib.match_list[match_type].match_car_list)do
		local car_id = v.car_id
		local match_user_id = v.match_user_id
		local match_user_info = usermgr.GetUserById(match_user_id)
		local nick_name = v.match_nick_name
		local car_type = v.car_type
        local car_prize = 0;
        if (match_user_id > 0) then --冠军为玩家
            car_prize = car_match_sj_lib.get_user_car_prize(match_user_id, car_id)
        else
            car_prize = car_match_sj_lib.get_car_cost(car_type)    --冠军为NPC
        end
		if(match_user_id == nil)then
			TraceError("拿冠军的人不是参赛者？？")
			TraceError(v)
        end
        
        if v.mc == 1 then
    		--第一名写到冠军列表里去
            local buf_tab = {
                ["area_id"] = k2,
                ["user_id"] = match_user_id,
                ["nick_name"] = nick_name,
                ["car_id"] = car_id,
                ["car_type"] = car_type,
                ["area_id"] = car_match_sj_lib.match_list[match_type].open_num,
            }
            --今日冠军
            if #car_match_sj_lib.today_king_list[match_type] < car_match_sj_lib.CFG_TODAY_KING_LEN then
                table.insert(car_match_sj_lib.today_king_list[match_type], buf_tab)
            else
                table.remove(car_match_sj_lib.today_king_list[match_type], 1)
                table.insert(car_match_sj_lib.today_king_list[match_type], buf_tab)
            end
    
            if (match_user_id > 0) then
                car_match_sj_db_lib.add_king_list(match_type, buf_tab)
            end
        end
	end
end

--给参赛的人发奖
function car_match_sj_lib.match_fajiang(match_type)
    --第一名的位置号
    local open_num = car_match_sj_lib.match_list[match_type].open_num
    local user_id = 0
    local mingci = 0
    local area_id = 0
    local car_type = 0

    --给所有人发奖
    for i = 1, car_match_sj_lib.CFG_CAR_NUM do
        mingci = car_match_sj_lib.match_list[match_type].match_car_list[i].mc
        area_id = car_match_sj_lib.match_list[match_type].match_car_list[i].area_id
        user_id = car_match_sj_lib.match_list[match_type].match_car_list[i].match_user_id
        car_type = car_match_sj_lib.match_list[match_type].match_car_list[i].car_type

        --发经验、车标、筹码、加汽油
        local team_lv = 0
        local reward_num = 0

        team_lv = car_match_sj_lib.match_list[match_type].match_car_list[i].team_lv
        reward_num = car_match_sj_lib.get_reward_num(team_lv)

        local add_exp = car_match_sj_lib.race_reward[reward_num][mingci].exp
        if (team_lv == #car_match_sj_lib.exp_list) then --满级了不加经验
            add_exp = 0
        end

        local flag_lv = car_match_sj_lib.race_reward[reward_num][mingci].flag
        local flag_num = car_match_sj_lib.race_reward[reward_num][mingci].flag_num
        local add_gold = car_match_sj_lib.race_reward[reward_num][mingci].chouma
        local add_gas = mingci == 1 and 1 or 0

        local user_info = usermgr.GetUserById(user_id)
        local img_url =  car_match_sj_lib.match_list[match_type].match_car_list[i].match_user_face
        local nick_name =  car_match_sj_lib.match_list[match_type].match_car_list[i].match_nick_name
        local team_exp = car_match_sj_lib.match_list[match_type].match_car_list[i].team_exp
        local buf_tab = {
            ["user_id"] = user_id,      
            ["area_id"] = area_id,      --车位
            ["img_url"] = img_url,      --头像
            ["nick_name"] = nick_name,  --昵称
            ["add_exp"] = add_exp,      --奖励经验
            ["flag_lv"] = flag_lv,      --奖励车标等级
            ["flag_num"] = flag_num,    --奖励车标数量
            ["add_gold"] = add_gold,    --奖励筹码
            ["add_gas"] = add_gas,      --奖励汽油
            ["mingci"] = mingci,        --名次  
            ["team_lv"] = team_lv,      --车队等级
            ["team_exp"] = team_exp,    --目前车队经验
        }
        car_match_sj_lib.save_fajiang(buf_tab)
    end
end

--保存玩家奖励
function car_match_sj_lib.save_fajiang(buf_tab)
    if (car_match_sj_lib.match_reward_list == nil) then
        car_match_sj_lib.match_reward_list = {}
    end
    car_match_sj_lib.match_reward_list[buf_tab.user_id] = buf_tab

    if (buf_tab.user_id > 0) then --只有玩家信息才保存
        local user_info = usermgr.GetUserById(buf_tab.user_id)
        if (user_info == nil) then
            --玩家不在线时保存玩家的奖励信息，上线时提示
            car_match_sj_db_lib.update_offline_reward(buf_tab)
        end 
        --保存数据
        usermgr.addgold(buf_tab.user_id, buf_tab.add_gold, 0, new_gold_type.CAR_MATCH, -1)   --加筹码
        if (buf_tab.add_exp > 0) then   --加的经验大于0时才加
            car_match_sj_lib.add_team_exp(buf_tab.user_id, buf_tab.team_lv, buf_tab.team_exp, buf_tab.add_exp, car_match_sj_lib.gas_reason.match)   --加经验
        end
        car_match_sj_lib.add_car_flag(buf_tab.user_id, buf_tab.flag_lv, buf_tab.flag_num, car_match_sj_lib.gas_reason.match)  --加车标
        if (buf_tab.add_gas ~= 0) then
            car_match_sj_lib.add_gas(buf_tab.user_id, buf_tab.add_gas, car_match_sj_lib.gas_reason.match)
        end
    end
end

--根据车队等级经验计算新等级经验
function car_match_sj_lib.get_user_team_lv(lv, exp)
    if (lv == #car_match_sj_lib.exp_list) then     --满级了
        return #car_match_sj_lib.exp_list,exp
    end
    local up_lv_exp = car_match_sj_lib.exp_list[lv+1] or 0 --该级的升级经验
    if (exp >= up_lv_exp) then          --玩家现在经验大于升级经验，可以升级了
        lv = lv + 1                     --新的等级
        exp = exp - up_lv_exp           --新的经验(超出的经验)
        lv, exp = car_match_sj_lib.get_user_team_lv(lv, exp)  --递归判断一下超出的经验是否足够再升一级
    end
    return lv, exp
end

--根据玩家车队等级获取奖励区间
function car_match_sj_lib.get_reward_num(team_lv)
    for k, v in pairs(car_match_sj_lib.temp_race_reward) do
        if (team_lv <= v) then
            return v
        end
    end
end

--更新玩家汽油值
function car_match_sj_lib.add_gas(user_id, add_num, reason)
    --[[
        自动恢复及参赛扣汽油时玩家肯定在线，只有发比赛奖励时可能不在线
        所以玩家不在线时给他加汽油，不用记录汽油恢复时间，上线时会处理
    --]]
    local user_info = usermgr.GetUserById(user_id)
    if (user_info ~= nil) then
        --同步一下内存的汽油值和CD时间
        local gas_num = car_match_sj_lib.user_list[user_id].gas_num
        if (gas_num == 0 and add_num < 0) then
            TraceError("玩家"..user_id.."汽油值为0还继续扣..")
            return;
        end
        car_match_sj_lib.user_list[user_id].gas_num = gas_num + add_num
        --汽油值未满，计算恢复时间
        if (car_match_sj_lib.user_list[user_id].gas_num < car_match_sj_lib.CFG_GAS_MAX) then
            if (reason == car_match_sj_lib.gas_reason.huifu) then               --自动恢复汽油
                car_match_sj_lib.user_list[user_id].gas_time = os.time()
            elseif (reason == car_match_sj_lib.gas_reason.match) then           --参赛扣汽油
                if (car_match_sj_lib.user_list[user_id].gas_time == 0 and add_num < 0) then     --之前没有记录CD时间，表示之前汽油是满的
                    car_match_sj_lib.user_list[user_id].gas_time = os.time()    --扣完后开始记录时间
                end
            end
        else
            car_match_sj_lib.user_list[user_id].gas_time = 0                    --满了就把CD时间清除
        end
        --更新恢复时间
        car_match_sj_db_lib.update_gas_time(user_id, car_match_sj_lib.user_list[user_id].gas_time)
        if (gas_num <= 5) then
            car_match_sj_lib.send_gas_chenge(user_info, add_num)
        end
        car_match_sj_lib.send_team_info(user_info)
    end
    car_match_sj_db_lib.add_gas(user_id, add_num, reason)
end

--检查是否加离线恢复的汽油(这个离线概念是指客户端主动请求恢复汽油的间隔时间)
function car_match_sj_lib.add_off_line_gas(user_id)
    local gas_time = car_match_sj_lib.user_list[user_id].gas_time
    local off_time = os.time() - gas_time   --距离上次恢复的时间
    if (gas_time == 0) then return end      --恢复时间为0说明汽油值已满不用处理

    if (off_time < car_match_sj_lib.CFG_GAS_TIME) then      --离线时间还不到一次恢复时间
        --这样处理一下可以保证玩家参赛时离线了给他加了汽油奖励，汽油值如果满了不会再出现倒计时
        if (car_match_sj_lib.user_list[user_id].gas_num >= car_match_sj_lib.CFG_GAS_MAX) then
            car_match_sj_lib.user_list[user_id].gas_time = 0
            car_match_sj_db_lib.update_gas_time(user_id, car_match_sj_lib.user_list[user_id].gas_time) --更新恢复时间
        end
    elseif (off_time >= car_match_sj_lib.CFG_GAS_TIME) then  --计算出距离上次恢复有几个间隔
        local num = car_match_sj_lib.CFG_GAS_MAX - car_match_sj_lib.user_list[user_id].gas_num  --理论可恢复几格
        if (num <= 0) then          --这种情况就是玩家离线后给他加了汽油奖励，汽油满了
            car_match_sj_lib.user_list[user_id].gas_time = 0
        else
            local times = math.floor(off_time / car_match_sj_lib.CFG_GAS_TIME)              --实际可恢复几格
            local shengyu_time = off_time - (times * car_match_sj_lib.CFG_GAS_TIME)         --剩下的时间
            if (times < num) then   --实际可恢复小于理论可恢复，取实际
                num = times
                car_match_sj_lib.user_list[user_id].gas_time = os.time() - shengyu_time     --剩余恢复时间
            else
                car_match_sj_lib.user_list[user_id].gas_time = 0;                           --恢复满了就清掉
            end
            --加汽油(这里不能直接调用在线恢复的接口,在线恢复接口会更改更新时间)
            car_match_sj_db_lib.add_gas(user_id, num, car_match_sj_lib.gas_reason.huifu)    
            car_match_sj_lib.user_list[user_id].gas_num = car_match_sj_lib.user_list[user_id].gas_num + num
        end
        car_match_sj_db_lib.update_gas_time(user_id, car_match_sj_lib.user_list[user_id].gas_time) --更新恢复时间
    end
end

--给玩家加车队经验
function car_match_sj_lib.add_team_exp(user_id, old_lv, old_exp, add_exp, reason)
    local user_info = usermgr.GetUserById(user_id)
    local new_lv, new_exp = car_match_sj_lib.get_user_team_lv(old_lv, old_exp + add_exp)
    local curr_exp = new_exp
    if (user_info ~= nil) then --玩家还在线就更新内存
        car_match_sj_lib.user_list[user_id].team_exp = new_exp
        car_match_sj_lib.user_list[user_id].team_lv = new_lv
    end
    if (new_lv == 100 and new_exp > 0) then --99升到100级处理，new_exp是超出的经验，要从add_exp中扣除
        add_exp = add_exp - new_exp
        if (user_info ~= nil) then
            car_match_sj_lib.user_list[user_id].team_exp = 0
        end
        curr_exp = 0
    end
    car_match_sj_db_lib.update_team_exp(user_id, add_exp, curr_exp, new_lv, reason)   --加经验
end

--更新玩家车标
function car_match_sj_lib.add_car_flag(user_id, flag_lv, flag_num, reason)
    local user_info = usermgr.GetUserById(user_id)
    if (user_info ~= nil) then --玩家还在线就更新内存
        local flag_name = "flag"..tostring(flag_lv).."_num"
        local user_flag = car_match_sj_lib.user_list[user_id][flag_name]
        car_match_sj_lib.user_list[user_id][flag_name] = user_flag + flag_num
    end
    car_match_sj_db_lib.add_car_flag(user_id, flag_lv, flag_num, reason)  --加车标
end

--检查玩家是否为新手
function car_match_sj_lib.check_is_new_player(user_id, call_back)
    car_match_sj_db_lib.get_team_car_info(user_id, function(dt)
        if (#dt == 0) then
            call_back(1)
            return
        else
            call_back(0)
        end
    end)
end

-------------------------------------------系统事件----------------------------------------------------------------
--定时器
function car_match_sj_lib.timer(e)
   
    if(car_match_sj_lib.check_match_room() == 0) then
        return;
    end
	local current_time = e.data.time;
    car_match_sj_lib.current_time = current_time
	local tmp_match_type = 3

	--如果活动从无效变成有效，就需要通知客户端
	car_match_sj_lib.send_match_status(tmp_match_type, current_time)

    if car_match_sj_lib.match_start_status[tmp_match_type] == 1 and
        car_match_sj_lib.match_list == nil or car_match_sj_lib.match_list[tmp_match_type] == nil then
        car_match_sj_lib.init_match(tmp_match_type ,current_time)
    else
        car_match_sj_lib.set_proccess(car_match_sj_lib.match_list[tmp_match_type],current_time)
    end
	if car_match_sj_lib.notify_flag > 0 then
		tmp_match_type = car_match_sj_lib.notify_flag
		car_match_sj_lib.notify_flag = 0 --先改标识，防止程序出错，不断的发消息
		for k,v in pairs (car_match_sj_lib.match_user_list) do
			local user_info = usermgr.GetUserById(v.user_id)
			if user_info ~= nil then
                car_match_sj_lib.send_main_box(user_info, tmp_match_type)
			end
		end
	end

	if (current_time % 10 == 0) then
		for k,v in pairs (car_match_sj_lib.user_list) do
			if (v.user_id ~= nil) then
			    local user_info = usermgr.GetUserById(v.user_id)
			    if user_info == nil then
    				car_match_sj_lib.user_list[k] = nil
                    car_match_sj_lib.match_user_list[k] = nil
			    end
			end
		end
	end
end


--服务器重启了
function car_match_sj_lib.restart_server()
    if(car_match_sj_lib.check_match_room() == 0) then
        return;
    end
	--备份报名表，玩家登陆时，从备份表里给他退钱。
	car_match_sj_db_lib.backup_baoming_table()

	--初始化重启前的match_id到内存里
	car_match_sj_db_lib.init_restart_match_id()

	--初始化最近冠军
	car_match_sj_db_lib.init_today_king_list()
end

--服务器启动
function car_match_sj_lib.on_server_start(e)
    --排序奖励
    for i = 1, 100 do
        table.insert(car_match_sj_lib.exp_list, car_match_sj_lib.temp_exp_list[i])
    end
    for k, v in pairs (car_match_sj_lib.race_reward) do
        table.insert(car_match_sj_lib.temp_race_reward, k)
    end
    table.sort(car_match_sj_lib.temp_race_reward)
end

--比赛是否已经开始了
function car_match_sj_lib.is_match_start(match_type)
    if (car_match_sj_lib.match_list[match_type] ~= nil and
        car_match_sj_lib.match_list[match_type].proccess >= 1 and
        car_match_sj_lib.match_list[match_type].proccess <= 3) then
        return 1
    else
        return 0
    end
end

------------------------------------------------网络协议--------------------------------------------
cmdHandler =
{
    ["SJCARSTAT"]   = car_match_sj_lib.on_recv_querystatus,         --客户端查询活动状态
    ["SJCAROPPL"]   = car_match_sj_lib.on_recv_openpl,              --打开活动面板
    ["CARCLOSE"]    = car_match_sj_lib.on_recv_closepl,             --关闭活动面板
    ["SJCARJOIN"]   = car_match_sj_lib.on_recv_baoming,             --请求报名
	["SJCAROPJN"]   = car_match_sj_lib.on_recv_openjoin,            --点参赛或报名按钮
	["SJCARMC"]     = car_match_sj_lib.on_recv_query_match_mc,      --查比赛名次
    ["GETGAS"]      = car_match_sj_lib.on_recv_get_gas,             --请求恢复汽油
}

--加载插件的回调
for k, v in pairs(cmdHandler) do
    cmdHandler_addons[k] = v
end

eventmgr:addEventListener("timer_second", car_match_sj_lib.timer);
eventmgr:addEventListener("on_server_start", car_match_sj_lib.restart_server);
eventmgr:addEventListener("on_server_start", car_match_sj_lib.on_server_start); 


