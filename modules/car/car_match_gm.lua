
if car_match_sys_ctrl and car_match_sys_ctrl.restart_server then
	eventmgr:removeEventListener("on_server_start", car_match_sys_ctrl.restart_server);
end

if car_match_sys_ctrl and car_match_sys_ctrl.timer then
    eventmgr:removeEventListener("timer_second", car_match_sys_ctrl.timer);
end

if (car_match_sys_ctrl == nil) then
    car_match_sys_ctrl = 
    {
        update_win_info = NULL_FUNC,
        on_round_over = NULL_FUNC,
        restart_server = NULL_FUNC,
        BACK_PRIZE_RATE = 0.05,
        random_win_rate = {  --随机模式下赢的概率和配置
            {rate = 60, prize_rate = {0.8, 1.2}},
            {rate = 25, prize_rate = {0, 0.79}},
            {rate = 15, prize_rate = {1.21, 3}},
	    },
        sys_round_info ={{},{}},   --系统总的输赢信息
        cur_round_info = {{},{}},  --当局输赢信息
    }
end

function car_match_sys_ctrl.init_sys_round_info(match_type)
    local sys_round_info = car_match_sys_ctrl.sys_round_info[match_type]
    sys_round_info.sys_win_gold = 0 --系统赢多少钱
    sys_round_info.sys_lost_gold = 0 --系统输多少钱
    sys_round_info.round_num = 0 --此轮的局数
    sys_round_info.game_module = 0 --当前游戏模式
    sys_round_info.ROUND_MAX_WIN = 2000000000  --系统一局最大输钱数
end

function car_match_sys_ctrl.init_cur_round_info(match_type)
    local cur_round_info = car_match_sys_ctrl.cur_round_info[match_type]
    cur_round_info.win_info = {0,0,0,0,0,0,0,0} --当局每个车位赢时的系统输赢信息
    cur_round_info.win_rate = {0,0,0,0,0,0,0,0} --出奖率
    cur_round_info.total_xiazhu = 0  --当局总下注
end
--服务器启动
function car_match_sys_ctrl.restart_server()
    if (tonumber(groupinfo.groupid) ~= 18001) then
		return
    end
    local sql = "select * from car_win_info";
	dblib.execute(sql, function(dt) 
        if (dt and #dt > 0) then
            for i = 1, #dt do
                car_match_sys_ctrl.sys_round_info[i].sys_win_gold = tonumber(dt[i].sys_win_gold)
                car_match_sys_ctrl.sys_round_info[i].sys_lost_gold = tonumber(dt[i].sys_lost_gold)
                car_match_sys_ctrl.sys_round_info[i].game_module = dt[i].game_module
                car_match_sys_ctrl.sys_round_info[i].round_num = dt[i].round_num
            end
            
        end
    end)
    for i = 1, 2 do
        car_match_sys_ctrl.init_cur_round_info(i)
        car_match_sys_ctrl.init_sys_round_info(i)
    end
end

function car_match_sys_ctrl.timer(e)
    if (tonumber(groupinfo.groupid) ~= 18001) then
		return
    end
    local cur_time = e.data.time
    local cur_week = os.date("%w", cur_time)
    local cur_time = os.date("%X", cur_time)
    --每周一晚上一点钟清空一次数据信息
    if (cur_week == "1" and cur_time == "01:00:00") then
        local sql = "update car_win_info set round_num = 0,game_module=0,sys_win_gold='0',sys_lost_gold='0'";
        dblib.execute(sql)
        --重置内存中的信息
        for i = 1, 2 do
            car_match_sys_ctrl.init_cur_round_info(i)
            car_match_sys_ctrl.init_sys_round_info(i)
        end
    end
end
--更新当局输赢
function car_match_sys_ctrl.update_win_info(match_type, win_count, win_type)
    if (win_type ~= car_match_lib.CFG_GOLD_TYPE.XIA_ZHU and win_type ~= car_match_lib.CFG_GOLD_TYPE.BAO_MIN and 
        win_type ~= car_match_lib.CFG_GOLD_TYPE.JIANG_JIN and win_type ~= car_match_lib.CFG_GOLD_TYPE.CAR_WIN and 
        win_type ~= car_match_lib.CFG_GOLD_TYPE.BACK_XIA_ZHU) then
        return
    end
    --计算系统输赢
    local sys_round_info = car_match_sys_ctrl.sys_round_info[match_type]
    if (win_count > 0) then        
        sys_round_info.sys_win_gold = sys_round_info.sys_win_gold + win_count
    else
        sys_round_info.sys_lost_gold = sys_round_info.sys_lost_gold + win_count
    end
    --单独记录当局下注情况
    local cur_round_info = car_match_sys_ctrl.cur_round_info[match_type]
    if (win_type == car_match_lib.CFG_GOLD_TYPE.XIA_ZHU) then
        cur_round_info.total_xiazhu = cur_round_info.total_xiazhu + win_count
    end    
end

--更新系统总输赢
function car_match_sys_ctrl.on_round_over(match_type)
    local sys_round_info = car_match_sys_ctrl.sys_round_info[match_type]
    --更新数据库
    local sql = "";
    sql = "update car_win_info set sys_lost_gold = '%s', sys_win_gold = '%s' where match_type = %d";
    sql = string.format(sql, sys_round_info.sys_lost_gold, sys_round_info.sys_win_gold, match_type)
    dblib.execute(sql)    
end

--计算赛车的人的奖励
function car_match_sys_ctrl.get_car_fajiang_gold(match_type, open_num)
    --计算总奖励(每个车的奖金，用户下注的奖金)
    --给参赛的人发奖 
    local user_id = 0
    --给所有人发奖
    local all_add_gold = 0
    for i = 1, car_match_lib.CFG_CAR_NUM do
        local add_gold = 0
        user_id = car_match_lib.match_list[match_type].match_car_list[i].match_user_id
        --不处理NPC
        if  user_id > 0 then
            local xiazhu = car_match_lib.match_list[match_type].match_car_list[i].xiazhu or 0
            local jiacheng = car_match_lib.match_list[match_type].match_car_list[i].jiacheng
            if (i == open_num) then --第一名直接发奖
                --冠军奖金=当前车下注总额*当前车位倍率*加成比例
                local peilv = car_match_lib.match_list[match_type].match_car_list[i].peilv
                add_gold = xiazhu * peilv * jiacheng * car_match_lib.CFG_BET_RATE[match_type]
                add_gold = math.floor(add_gold)                    		    
            else    --其他名次发奖
                add_gold = xiazhu * jiacheng * car_match_lib.CFG_BET_RATE[match_type]
                add_gold = math.floor(add_gold)                
            end
        end
        all_add_gold = all_add_gold + add_gold
    end
    return all_add_gold
end

--给下注的人发奖
function car_match_sys_ctrl.get_xiazhu_fajiang_gold(match_type, open_num)
	--得到开出来的号码
    local all_add_gold = 0
	for k,v in pairs (car_match_lib.user_list) do
		if v.match_info[match_type] ~=nil then 
			local bet_info = v.match_info[match_type].bet_info or car_match_lib.CFG_BET_INIT
			local tmp_bet_tab = split(bet_info,",")
			local xiazhu = tonumber(tmp_bet_tab[open_num]) or 0 --开奖位的下注金额
			if xiazhu > 0 then
				--应该加多少钱
				local add_gold = xiazhu * car_match_lib.CFG_BET_RATE[match_type] * car_match_lib.match_list[match_type].match_car_list[open_num].peilv
				add_gold = math.floor(add_gold)	
                all_add_gold = all_add_gold + add_gold
			end
		end		
    end
    return all_add_gold
end

--计算当前局的奖励信息
function car_match_sys_ctrl.calc_round_info(match_type)    
    --计算每个车位获奖时的奖励信息
    local round_info = car_match_sys_ctrl.cur_round_info[match_type]
    for i = 1, car_match_lib.CFG_CAR_NUM do
        --计算车发奖的钱
        round_info.win_info[i] = round_info.win_info[i] + car_match_sys_ctrl.get_car_fajiang_gold(match_type, i)
        --计算下注发奖的钱
        round_info.win_info[i] = round_info.win_info[i] + car_match_sys_ctrl.get_xiazhu_fajiang_gold(match_type, i)
    end
    --计算出奖率,  保留两位小数
    for i = 1, #round_info.win_info do
        if (round_info.total_xiazhu == 0) then
            round_info.win_rate[i] = 0
        else
            round_info.win_rate[i] = math.ceil(round_info.win_info[i] * 100 / round_info.total_xiazhu) / 100
        end
    end
    return round_info
end

--第二轮结束的时候调用修改排名
function car_match_sys_ctrl.on_process2_end(match_type)
    if (car_match_lib.gm_ctrl[match_type] == 1) then
        return
    end
    --增加局数
    car_match_sys_ctrl.add_round_num(match_type, 1)
    --获取第一名的位置
    local top_area_id = car_match_sys_ctrl.get_win_num(match_type)
    if (top_area_id < 1 or top_area_id > 8) then
        TraceError("top_area_id 为非法值。为啥?  "..top_area_id)
    end
    --把老的第一名换掉
    local org_top_area_id = car_match_lib.match_list[match_type].open_num
    car_match_lib.match_list[match_type].match_car_list[org_top_area_id].mc = car_match_lib.match_list[match_type].match_car_list[top_area_id].mc
    car_match_lib.match_list[match_type].match_car_list[top_area_id].mc = 1
    car_match_lib.match_list[match_type].open_num = top_area_id
    --当局信息清0
    car_match_sys_ctrl.init_cur_round_info(match_type)
end

--设置gm模式
function car_match_sys_ctrl.set_game_module(match_type, game_module)
	car_match_sys_ctrl.sys_round_info[match_type].game_module = game_module
    local sql = "";
    sql = "update car_win_info set game_module = %d where match_type = %d";
    sql = string.format(sql, game_module, match_type)
    dblib.execute(sql)
end

function car_match_sys_ctrl.get_game_module(match_type)
	return car_match_sys_ctrl.sys_round_info[match_type].game_module
end

--设置局数
function car_match_sys_ctrl.add_round_num(match_type, num)
    local sys_round_info = car_match_sys_ctrl.sys_round_info[match_type]
    sys_round_info.round_num = sys_round_info.round_num + num
    local sql = "update car_win_info set round_num = %d where match_type = %d";
    local sql = string.format(sql, sys_round_info.round_num, match_type)
    dblib.execute(sql)
end

--获取局数
function car_match_sys_ctrl.get_round_num(match_type)
	local sys_round_info = car_match_sys_ctrl.sys_round_info[match_type]
	return sys_round_info.round_num
end

--取到赢得位置
function car_match_sys_ctrl.get_win_num(match_type)    
    local round_num = car_match_sys_ctrl.get_round_num(match_type)    
    local round_info = car_match_sys_ctrl.calc_round_info(match_type)
    --第一局进入随机模式
    if (round_num ~= 1 and ((round_num - 1) % 5 == 0 or car_match_sys_ctrl.get_game_module(match_type) == 1)) then
        return car_match_sys_ctrl.process_force_mod(match_type, round_info)
    else
        return car_match_sys_ctrl.process_random_mod(match_type, round_info)
    end
end

--随机模式
function car_match_sys_ctrl.process_random_mod(match_type, round_info)
    local win_rate_info = car_match_sys_ctrl.random_win_rate
    local win_num = 0   --赢得位置
    local sum_rate = 0
    for i = 1, #win_rate_info do
        sum_rate = sum_rate + win_rate_info[i].rate
    end
    local random_num = math.random(0, sum_rate)
    sum_rate = 0 
    for i = 1, #win_rate_info do
        sum_rate =  sum_rate + win_rate_info[i].rate
        if (random_num <= sum_rate) then
            local win_num_info = {}
            for j = 1, #round_info.win_rate do
            if (round_info.win_rate[j] >= win_rate_info[i].prize_rate[1] and round_info.win_rate[j] <= win_rate_info[i].prize_rate[2]) then
                    table.insert(win_num_info,  j)
                end
            end
            if (#win_num_info ~= 0) then
                local chose_num = math.random(1,  #win_num_info)
                win_num = win_num_info[chose_num]
            end
            break
        end
    end
    if (win_num == 0) then  --没有找到这种模式的位置，走纯概率模式
        win_num = car_match_sys_ctrl.process_other_mod(match_type, round_info)
    end
    return win_num
end

--强制模式
function car_match_sys_ctrl.process_force_mod(match_type, round_info)
    --获取实际彩池和理论彩池
    local win_num = 0
    local sys_round_info = car_match_sys_ctrl.sys_round_info[match_type]
    local real_win_gold = sys_round_info.sys_win_gold + sys_round_info.sys_lost_gold
    local need_win_gold = math.floor(sys_round_info.sys_win_gold * 0.05)
    if (real_win_gold / 1.5 > need_win_gold)  then --强制送分
        local win_num_info = {}
        for j = 1, #round_info.win_rate do
            if (round_info.win_rate[j] > 1 and   --找到可以送分的位置
                round_info.win_info[j] < sys_round_info.ROUND_MAX_WIN) then  --没有超过本局最大赢钱数
                table.insert(win_num_info, j)
            end
        end
        if (#win_num_info ~= 0) then
            local chose_num = math.random(1,  #win_num_info)
            win_num = win_num_info[chose_num]
        end
        car_match_sys_ctrl.set_game_module(match_type, 1)
    elseif (real_win_gold / 1.2 < need_win_gold)  then --强制杀分
        local lost_num_info = {}
        for j = 1, #round_info.win_rate do
            if (round_info.win_rate[j]  < 1 and   --找到可以杀分的位置
                round_info.win_info[j] < sys_round_info.ROUND_MAX_WIN) then  --没有超过本局最大赢钱数
                table.insert(lost_num_info, j)
            end
        end
        if (#lost_num_info ~= 0) then
            local chose_num = math.random(1,  #lost_num_info)
            win_num = lost_num_info[chose_num]
        end
        car_match_sys_ctrl.set_game_module(match_type, 1)
    else  --无需强制炒分杀分了，走随机模式
        car_match_sys_ctrl.set_game_module(match_type, 0)
        win_num = car_match_sys_ctrl.process_random_mod(match_type, round_info)
    end
    --所有的情况都走不通
    if ( win_num == 0) then
        win_num = car_match_sys_ctrl.process_other_mod(match_type, round_info)
    end
    return win_num
end

--纯概率模式
function car_match_sys_ctrl.process_other_mod(match_type, round_info)
    local sys_round_info = car_match_sys_ctrl.sys_round_info[match_type]
    local random_num = math.random(1, 8)
    if (round_info.win_info[random_num] < sys_round_info.ROUND_MAX_WIN) then  --没有超过本局最大赢钱数
        return random_num
    end
    for j = 1, #round_info.win_rate do
        if (round_info.win_info[j] < sys_round_info.ROUND_MAX_WIN) then  --没有超过本局最大赢钱数
            return j
        end
    end
    return 1
end

eventmgr:addEventListener("on_server_start", car_match_sys_ctrl.restart_server);
eventmgr:addEventListener("timer_second", car_match_sys_ctrl.timer);

