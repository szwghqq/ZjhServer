TraceError("init car_shop...")

if not car_shop_lib then
    car_shop_lib = _S
    {

        --[[
            天津大发  5043
            奥拓  5013
            奇瑞  5022 
            夏利  5019
            海马  5031
            奇瑞瑞麟  5032
            铃木新奥拓 5034
            雪铁龙  5018
            丰田  5030
            高尔夫  5046
            福克斯  5033
            
            ------------------------
            甲壳虫  5012
            英菲尼迪G  5047
            捷豹XF  5048
            -------------------------
            宝马Z4  5049
            奥迪  5011
            玛莎拉蒂  5021
            奔驰  5017
            ------------------------
            法拉利  5024
            宾利慕尚  5050
            保时捷 5025            
            ------------------------
            兰博基尼  5026
            莲花   5038
            Zenvo  5037
            布加迪  5027
            黄金布加迪  5036
        --]]
		--方法  
        CAR_LIST =  --车行车的类型
        {
            {5043,5013,5022,5019,5018,5051,5046},   --普通
            {5012,5047,5048},   --优良
            {5049,5011,5021,5017,},   --珍贵
            {5024, 5050,5025},        --稀世
            {5026,5038,5037,5027,5036},   --传奇
        }
    }
end

function car_shop_lib.is_vaild_shop_car(car_type)
    for i = 1, #car_shop_lib.CAR_LIST do
        for j = 1, #car_shop_lib.CAR_LIST[i] do
            if (car_shop_lib.CAR_LIST[i][j] == car_type) then
                return 1, i
            end
        end
    end
    return 0, 0
end

function car_shop_lib.on_recv_car_list(buf)
    local user_info = userlist[getuserid(buf)];
   	if not user_info then return end;
    local flag_type = buf:readByte()
    if (flag_type < 1 or flag_type > #car_shop_lib.CAR_LIST) then
        TraceError("参数错误")
        return
    end
    netlib.send(function(buf) 
        buf:writeString("CARSPLS")
        local car_num = #car_shop_lib.CAR_LIST[flag_type]
        buf:writeInt(flag_type)
        buf:writeInt(car_num)
        for i = 1, car_num do
            local car_type = car_shop_lib.CAR_LIST[flag_type][i]
            buf:writeInt(car_type)
            local can_buy = car_shop_lib.can_buy_car(user_info, car_type, flag_type)
            buf:writeInt(car_match_lib.CFG_CAR_INFO[car_type].need_level)
            buf:writeInt(car_match_lib.CFG_CAR_INFO[car_type].need_gold)
            buf:writeInt(car_match_lib.CFG_CAR_INFO[car_type].need_flag[flag_type])
            buf:writeInt(can_buy)            
        end
    end, user_info.ip, user_info.port)    
end

function car_shop_lib.can_buy_car(user_info, car_type, flag_type)
    local user_id = user_info.userId
    local need_gold = car_match_lib.CFG_CAR_INFO[car_type].need_gold
    --检查钱是否够
    local user_gold = get_canuse_gold(user_info)
    if (user_gold < need_gold) then
        return -1
    end
    --车标是否够
    local flag_num = car_match_sj_lib.user_list[user_id]["flag"..flag_type.."_num"]
    local need_flag_num = car_match_lib.CFG_CAR_INFO[car_type].need_flag[flag_type]
    if (flag_num < need_flag_num) then
        return -2
    end
    --车队经验是否够
    if (car_match_sj_lib.user_list[user_id].team_lv < car_match_lib.CFG_CAR_INFO[car_type].need_level) then
        return -3
    end
    return 1
end
function car_shop_lib.on_recv_car_exchange(buf)
    local user_info = userlist[getuserid(buf)];
    if not user_info then return end;
    local user_id = user_info.userId
    local car_type = buf:readInt() --需要兑换的车
    local ret, flag_type = car_shop_lib.is_vaild_shop_car(car_type)
    if (ret == 0 or car_match_lib.CFG_CAR_INFO[car_type] == nil) then
        TraceError("on_recv_car_exchange 非法的车  "..car_type.."  "..user_info.userId)
        return
    end
    local send_ret = function(ret)
        netlib.send(function(buf)
            buf:writeString("CARSPEC")
            buf:writeInt(ret)
            buf:writeInt(car_type)
            buf:writeInt(flag_type)
        end, user_info.ip, user_info.port)
    end
    local ret = car_shop_lib.can_buy_car(user_info, car_type, flag_type)
    if (ret < 0) then
        send_ret(ret)
        return
    end
    local need_flag_num = car_match_lib.CFG_CAR_INFO[car_type].need_flag[flag_type]
    local need_gold = car_match_lib.CFG_CAR_INFO[car_type].need_gold
    --扣车标，和钱
    car_match_sj_lib.add_car_flag(user_info.userId, flag_type, -need_flag_num, car_match_sj_lib.gas_reason.buy)
    usermgr.addgold(user_id, -need_gold, 0, new_gold_type.CAR_BUY, -1)
    --加车
    car_match_db_lib.add_car(user_info.userId, car_type, 0, 1)
    car_match_sj_lib.send_team_info(user_info)
    --记录兑换日志
    car_shop_db_lib.record_exchange_log(user_info.userId, car_type, 1)
    send_ret(1)
end

------------------------------------------------网络协议--------------------------------------------
cmdHandler =
{
    ["CARSPLS"] = car_shop_lib.on_recv_car_list,                --请求获取车的列表    
    ["CARSPEC"] = car_shop_lib.on_recv_car_exchange,            --请求兑换车辆
}

--加载插件的回调
for k, v in pairs(cmdHandler) do
    cmdHandler_addons[k] = v
end

--eventmgr:addEventListener("timer_second", car_match_lib.timer);
--eventmgr:addEventListener("on_server_start", car_match_lib.restart_server);
--eventmgr:addEventListener("gm_cmd", car_match_lib.gm_cmd)

