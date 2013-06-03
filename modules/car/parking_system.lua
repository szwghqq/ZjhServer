TraceError("init parking system....")

if parkinglib and parkinglib.on_user_exit then
	eventmgr:removeEventListener("on_user_exit", parkinglib.on_user_exit);
end

if parkinglib and parkinglib.on_site_event then 
	eventmgr:removeEventListener("site_event", parkinglib.on_site_event);
end

if parkinglib and parkinglib.on_using_gift then 
	eventmgr:removeEventListener("on_using_gift", parkinglib.on_using_gift);
end

if parkinglib and parkinglib.already_init_car then
	eventmgr:removeEventListener("already_init_car", parkinglib.already_init_car);
end
if parkinglib and parkinglib.on_after_sub_user_login then 
	eventmgr:removeEventListener("h2_on_sub_user_login", parkinglib.on_after_sub_user_login)
end

if not parkinglib then
	parkinglib = _S
	{
        process_parking_time_over = NULL_FUNC,      --车位过期处理
        calc_parking_status    = NULL_FUNC,         --计算车位状态
        get_parking_count = NULL_FUNC,              --获取车位数量
        get_car_info = NULL_FUNC,                   --获取车的信息
        process_using_car      = NULL_FUNC,              --处理设置座驾
        pay_parking            = NULL_FUNC,         --租车位扣钱
        --客户端请求handle
        on_recv_open_main_wnd  = NULL_FUNC,			--发送车位主窗口
        on_recv_parking_renew  = NULL_FUNC,         --续租
        on_recv_parking_config = NULL_FUNC,         --获取车位配置
        on_recv_parking_status = NULL_FUNC,         --获取用户车位状态
        on_recv_sale_car       = NULL_FUNC,         --卖车
        on_recv_using_car      = NULL_FUNC,         --设置车为座驾
        active_parking_site    = NULL_FUNC,			--开通（购买）车位
        net_send_parking_data  = NULL_FUNC,			--发送车位信息
        --系统事件调用
        process_sale_car       = NULL_FUNC,         --当礼品被卖时候触发
        on_after_user_login    = NULL_FUNC,         --用户登录时候
        on_site_event          = NULL_FUNC,        --见面事件
        on_add_gift_item       = NULL_FUNC,         --添加礼包道具
        on_user_exit           = NULL_FUNC,         --用户离开
        on_using_gift          = NULL_FUNC,         --使用礼品
        already_init_car       = NULL_FUNC,         --初始化车
        
        --公共接口
        add_parking            = NULL_FUNC,         --添加车位接口
        is_active_item         = NULL_FUNC,         --判断道具是否激活了
        is_parking_item        = NULL_FUNC,         --判断是否车位道具
        get_using_car_info     = NULL_FUNC,

        OP_PARKING_OPEN_PRICE = {   --不同车位开通价格
            1000,     --初级
            10000,    --中级
            100000,   --高级
            500000,   --特殊车位
        },  
        OP_PARKING_OPEN_PRICE_LOG = {
            61001,
            62001,
            63001,
            64001,
        },
        OP_PKARING_RENEW_PACKAGE= {
            [1] ={
                youhui=1,
                name="一个月",
                time=24 * 3600 * 30,
            },
            [6] ={
                youhui=0.9,
                name="半年",
                time=24 * 3600 * 30 * 6,
            },
            [12] = {
                youhui=0.8,
                name="1年",
                time=24 * 3600 * 30 * 12,
            }
        },

        --车位可放车限制，主要是车的价格限制
        OP_PARKING_LIMIT_CAR_PRICE = {
            [1] = 100000, --初级车位，10w以下的
            [2] = 1000000,--中级车位, 100W以下的
            [3] = 1000000000,
            [4] = 0,      --特殊车位
        },

        OP_PARKING_BUY_TIME = 24 * 3600 * 30,
        OP_PARKING_CARS = {
            [5011] = {
                parking_type = -1,
            },
            [5012] = {
                parking_type = -1,
            },
            [5013] = {
                parking_type = -1,
            },
            [5017] = {
                parking_type = -1,
            },
            [5018] = {
                parking_type = -1,
            },
            [5019] = {
                parking_type = -1,
            },
            [5021] = {
                parking_type = -1,
            },
            [5022] = {
                parking_type = -1,
            },
            [5023] = {
                parking_type = 4,--特殊车位
            },
            [5024] = {
                parking_type = -1,
            },
            [5025] = {
                parking_type = -1,
            },
            [5026] = {
                parking_type = -1,
            },
            [5027] = {
                parking_type = -1,
            },
            [5028] = {
                parking_type = 4,--特殊车位
            },
            [5029] = {
                parking_type = 4,--特殊车位
            },
            [5030] = {
                parking_type = -1,
            },
            [5031] = {
                parking_type = -1,
            },
            [5032] = {
                parking_type = -1,
            },
            [5033] = {
                parking_type = -1,
            },
            [5034] = {
                parking_type = -1,
            },
            [5036] = {
                parking_type = -1,
            },
            [5037] = {
                parking_type = -1,
            },
            [5038] = {
                parking_type = -1,
            },
            [5039] = {
                parking_type = -1,
            },
            [5040] = {
                parking_type = -1,
            },
            [5041] = {
                parking_type = -1,
            },

            [5042] = {
                parking_type = -1,
            },
            [5043] = {
                parking_type = -1,
            },
            [5044] = {
                parking_type = -1,
            },
            [5045] = {
                parking_type = -1,
            },
            [5046] = {
                parking_type = -1,
            },
            [5047] = {
                parking_type = -1,
            },
            [5048] = {
                parking_type = -1,
            },
            [5049] = {
                parking_type = -1,
            },
            [5050] = {
                parking_type = -1,
            },
            [5051] = {
                parking_type = -1,
            },

        },
        
        user_list = {},                 --用户的车位与汽车数据
	}
end

--TODO 监听用户退出，删除用户信息

parkinglib.get_car_info = function(parking_data, car_index)
    for k, v in pairs(parking_data.parking_list) do
        for k1, v1 in pairs(v.cars) do
            if(v1.index == car_index) then
                return v1;
            end
        end
    end
    return nil;
end

parkinglib.get_parking_count = function(parking_cars) 
    local count= 0;
    for k,v in pairs(parking_cars) do
        count = count + 1;
    end
    return count;
end

parkinglib.pay_parking = function(user_info, gold, parking_type, parking_time)
--    local retcode = 0;
--    if(user_info.desk and user_info.site) then
--        local deskdata = deskmgr.getdeskdata(user_info.desk);
--        local sitedata = deskmgr.getsitedata(user_info.desk, user_info.site);
--        retcode = dobuygift1(user_info, deskdata, sitedata, 0, gold);
--        --购买成功
--    else
--        retcode = dobuygift2(user_info, 0, gold)
--    end
--    return retcode;
--get_canuse_gold(user_info, is_include_self_chouma)

  if not parking_time then 
    parking_time =1
  end
  if get_canuse_gold(user_info) < gold then
    return 2
  else
    usermgr.addgold(user_info.userId, -gold, 0, hall.gold_type.PARKING_SYS.id, -1, 1, nil, parkinglib.OP_PARKING_OPEN_PRICE_LOG[parking_type], parking_time)
    return 1
  end
end

parkinglib.add_parking = function(user_info, parking_type, parking_count, car_id, index)           
    car_id = car_id ~= nil and car_id or 0;
    index = index ~= nil and index or 0;
    local total_count = parking_count;
    local parking_data = parkinglib.user_list[user_info.userId];
    if(parking_data == nil or parking_count <= 0) then 
        TraceError("用户没有的车位数据"..user_info.userId.." parking_type"..parking_type.." parking_count"..parking_count);
        return; 
    end;

    local parking_list = parking_data.parking_list;
    local data = parking_list[parking_type];
    local find = 0;
    if(car_id > 0 and index > 0) then
        for k, v in pairs(data.cars) do
            --指定激活的车
            --查看这车有激活没有
            if(v.id == car_id and v.parking_id == 0 and v.index == index) then
                find = 1;
                v.parking_id = table.maxn(data.parking_cars) + 1;
                table.insert(data.parking_cars, v.parking_id, {
                    id=v.id,
                    idx=v.index,
                    time=os.time(),
                    oversec=parkinglib.OP_PARKING_BUY_TIME, 
                });
                parking_count = parking_count - 1;
                break;
            end
        end
    end

    if(find == 0 and car_id > 0 and parking_count > 0) then
        for k, v in pairs(data.cars) do
            
            if(v.id == car_id and v.parking_id == 0) then
                find = 1;
                v.parking_id = table.maxn(data.parking_cars) + 1;
                table.insert(data.parking_cars, v.parking_id, {
                    id=v.id,
                    idx=v.index,
                    time=os.time(),
                    oversec=parkinglib.OP_PARKING_BUY_TIME, 
                });
                parking_count = parking_count - 1;
            end

            if(parking_count <= 0) then
                break;
            end
        end
    end

    if(find == 0 and parking_count > 0) then
        --直接租用车位, 随便找一辆
        for k, v in pairs(data.cars) do
            if(v.parking_id == 0) then
                find = 1;
                v.parking_id = table.maxn(data.parking_cars) + 1;
                table.insert(data.parking_cars, v.parking_id, {
                    id=v.id,
                    idx=v.index,
                    time=os.time(),
                    oversec= parkinglib.OP_PARKING_BUY_TIME,
                });
                parking_count = parking_count - 1;
            end

            if(parking_count <= 0) then
                break;
            end
        end
    end

    if(find == 0 and parking_count > 0) then
        --插入一个空的车位
        for i=1, parking_count do 
            table.insert(data.parking_cars, {
                id=0,
                time=os.time(),--车位未使用
                oversec=parkinglib.OP_PARKING_BUY_TIME,
            });
        end
    end

    data.parking_count = data.parking_count + total_count;
    parking_db_lib.add_user_parking_db(user_info.userId, data.id, parking_type, data.parking_count, data.parking_cars);
    parking_data.parking_count = parking_data.parking_count + total_count;
    

    if(data.id == 0) then--重新刷新数据
        parking_data.refresh = 1;
    end
    if(index > 0) then
        parkinglib.process_using_car(user_info, index);
    end
    parking_data.refresh = 1
end

--在车库开通购买车位
parkinglib.active_parking_site  = function(buf)
    local user_info = userlist[getuserid(buf)]
    local parking_data = parkinglib.user_list[user_info.userId];
    if(user_info == nil or parking_data == nil)then return end 
    local parking_list = parking_data.parking_list;
    local parking_type = buf:readInt(); --要开通的车位类型
    local parking_count = 1;--buf:readInt();--要开通的数量
    local car_id = buf:readInt();
    local index = buf:readInt();

    local retcode = 1;
    --local car_id = buf:readInt() --停在该车位的车辆ID，为0表示没有汽车

    local parking_price = parkinglib.OP_PARKING_OPEN_PRICE[parking_type];
    if(parking_price == nil or parking_price <= 0) then
        TraceError("没有该类型的车位，买什么"..parking_type);
        return;
    end

    local data = parking_list[parking_type];
    parking_price = parking_price * parking_count;

    --判断数量
    if(parking_list[parking_type].parking_count + parking_count > 100) then
        retcode = 0; 
    end

    if(retcode == 1) then
        retcode = parkinglib.pay_parking(user_info, parking_price, parking_type);
    end

    --某用户的车位增加并激活停在车位上的某汽车
    if(retcode == 1) then
        --写日志。
        parking_db_lib.log_user_parking_db(user_info.userId, parking_type, parking_count, parking_price)
        parkinglib.add_parking(user_info, parking_type, parking_count, car_id, index);
        --[[if(index > 0) then
            parkinglib.process_using_car(user_info, index);
        end--]]
        parkinglib.net_send_parking_data(user_info, parking_data, user_info.userId); 
    else
        netlib.send(function(buf)
            buf:writeString("PKACTIVERS");
            buf:writeInt(retcode);--0 购买失败 2 钱不够
        end, user_info.ip, user_info.port);
    end
end

parkinglib.calc_parking_status = function(userinfo, user_parking_data) 
    local parking_count = 0;--车位总数
    local car_count =  0;--车辆总数
    local car_type  =  0; --车的类型
    local car_price =  0;--车的总价值
    local client_refresh_time = 0;--客户端重新请求服务端刷新数据
    local cars = {};
    for k, v in pairs(user_parking_data.parking_list) do
        parking_count = parking_count + v.parking_count;
        local active_count = 0;
        for k1, v1 in pairs(v.cars) do
            cars[v1.id] = 1;
            car_count = car_count + 1;
            car_price = car_price + car_match_lib.get_user_car_prize(userinfo.userId, v1.car_id) or car_match_lib.get_car_cost(v1.car_type)
            if(v1.parking_id > 0) then
                active_count = active_count + 1;
            end
        end

        for k2, v2 in pairs(v.parking_cars) do
            local over_time = v2.time + v2.oversec;
            if(over_time < client_refresh_time or client_refresh_time == 0) then
                client_refresh_time = over_time - os.time();
            end
        end
        v.active_count = active_count;
    end

    for k, v in pairs(cars) do
        car_type = car_type + 1;
    end

    --注意，客户端倒计时超过15日会chubug
    if(client_refresh_time > 15 * 3600 * 24) then
        client_refresh_time = 0;
    end
    
    user_parking_data.car_type = car_type;
    user_parking_data.car_count = car_count;
    user_parking_data.car_price = car_price;
    user_parking_data.parking_count = parking_count;
    user_parking_data.client_refresh_time = client_refresh_time;
end
--自动帮用户选择车位
parkinglib.auto_select_parking = function(user_info, user_parking_data) 
    --查看有多少车位是空的，默认帮用户绑定车位
    for k, v in pairs(user_parking_data.parking_list) do
        local parking_count = v.parking_count;
        local real_parking_count = parkinglib.get_parking_count(v.parking_cars); 
        local find = false;
        local left_count = parking_count - real_parking_count;
        if(left_count > 0) then
            --把所有空的车位激活
            find = true;
            for i = 1, left_count do
                table.insert(v.parking_cars, {--默认是一个月的车位
                    id=0,
                    time = os.time(),
                    oversec= parkinglib.OP_PARKING_BUY_TIME,
                });
            end
        end

        local empty_parking = 0;--空车位的个数
        for k1, v1 in pairs(v.parking_cars) do
            if(v1.id <= 0) then
                empty_parking = empty_parking + 1;
            else
                local find_parking = 0;
                for k2, v2 in pairs(v.cars) do
                    --查找哪个车占了这个位置
                    if(v2.parking_id == k1) then
                        --找到了
                        find_parking = 1;
                        break;
                    end
                end

                if(find_parking == 0) then
                    --TraceError("：异常情况"..user_info.userId.." "..tostringex(v1));
                    empty_parking = empty_parking + 1;
                    v1.id = 0;
                    find = true;
                end
            end
        end
            
        --自动找个没有激活的位置让车停上
        if(empty_parking > 0) then
            local carids = {};
            for k1, v1 in pairs(v.cars) do
                if(v1.parking_id == 0) then
                    empty_parking = empty_parking - 1;
                    for k2, v2 in pairs(v.parking_cars) do
                        --查找有空的车位没有
                        if(v2.id <= 0) then
                            find = true;
                            v1.parking_id = k2; 
                            v2.id = v1.id;
                            if(v2.time == -1) then
                                v2.time = os.time();
                                v2.oversec=parkinglib.OP_PARKING_BUY_TIME;
                            end
                            break;
                        end
                    end
                end

                if(empty_parking <= 0) then
                    break;
                end
            end
        end

        if(find == true) then
            parking_db_lib.add_user_parking_db(user_info.userId, v.id, k, v.parking_count, v.parking_cars);
        end
    end
end

--处理过期的车位
parkinglib.process_parking_time_over = function(user_info, user_parking_data) 
    local parking_list = user_parking_data.parking_list;
    local count = 0;
    for k, v in pairs(parking_list) do
        local modify = 0;
        for k1, v1 in pairs(v.parking_cars) do
            if(v1.time == nil or v1.time == -1) then
                modify = 1;
                v1.time = os.time();
            end

            if(v1.oversec == nil) then 
                modify = 1;
                v1.oversec = parkinglib.OP_PARKING_BUY_TIME;
            end

            if(v1.time + v1.oversec< os.time()) then
                --过期了
                modify = 1;
                count = count + 1;

                --过期车处理
                v.parking_cars[k1] = nil;
                v.parking_count = v.parking_count - 1;
                for k2, v2 in pairs(v.cars) do
                    if(v2.id == v1.id and v2.parking_id == k1) then
                        v2.parking_id = 0;
                        --车位过期了，对应的车也要改一下数据
                        local parking_data = parkinglib.user_list[user_info.userId];
                        if (parking_data ~= nil and parking_data.using_car ~= nil and v1.idx == parking_data.using_car.index) then                                
                            car_match_db_lib.update_is_using(user_info.userId, parking_data.using_car.index, 0);
                            parking_data.using_car = nil;
                        end
                        break;
                    end
                end
            end
        end

        if(modify == 1) then
            parking_db_lib.add_user_parking_db(user_info.userId, v.id, k, v.parking_count, v.parking_cars);
        end
    end

    if(count > 0) then
        netlib.send(function(buf)
            buf:writeString("PKREMIND");
            buf:writeInt(count);
        end, user_info.ip, user_info.port);
    end
end

parkinglib.on_recv_sale_car = function(buf) 
    --TraceError('on_recv_sale_car');
    local user_info = userlist[getuserid(buf)]
    local parking_data = parkinglib.user_list[user_info.userId];
    if(user_info == nil or parking_data == nil)then return end 
    local result = 0;
    local send_func = function(buf) 
        buf:writeString("PKSALE");
        buf:writeInt(result);--1成功,-1正在比赛,0,失败
    end
    local car_index = buf:readInt();
    
    if not car_match_lib.user_list[user_info.userId] or
      not car_match_lib.user_list[user_info.userId].car_list[car_index] then
        return
    end
    
    if (car_match_lib and car_match_sj_lib) then
        local car_type = car_match_lib.user_list[user_info.userId].car_list[car_index].car_type or 0
        local sell_lv = 10
        local team_lv = car_match_sj_lib.user_list[user_info.userId].team_lv
        if (car_type == 5043 and team_lv < sell_lv) then  --卖的是天津大发而且车队等级小于10级不能卖
            parkinglib.send_can_not_sell_car(user_info, car_type, sell_lv)
            return
        end
    end


    parkinglib.process_sale_car(user_info, car_index, function(result)
        if(result == 1) then
            result = 1;
            car_match_db_lib.del_car(user_info.userId, car_index);
        end
    end); 
end

parkinglib.process_using_car = function(user_info, car_index, refresh)
    local parking_data = parkinglib.user_list[user_info.userId];
    if(parking_data ~= nil) then
        if(parking_data.using_car ~= nil) then
            parking_data.using_car.is_using = 0;
            car_match_db_lib.update_is_using(user_info.userId, parking_data.using_car.index, 0);
        end
        gift_remove_using(user_info);
        
        local car_info = parkinglib.get_car_info(parking_data, car_index);
        if(car_info ~= nil) then
            parking_data.using_car = car_info;
            car_info.is_using = 1;
            dispatchMeetEvent(user_info);
            if(refresh == true) then
                parkinglib.net_send_parking_data(user_info, parking_data, user_info.userId);
            end
        end
        car_match_db_lib.update_is_using(user_info.userId, car_index, 1);
    end
end

parkinglib.on_recv_using_car = function(buf)
    local user_info = userlist[getuserid(buf)]
    if(user_info == nil)then return end 
    local car_index = buf:readInt();
    parkinglib.process_using_car(user_info, car_index, true);
end


parkinglib.on_recv_open_main_wnd  = function(buf)    --打开车位主窗口
    --TraceError("OP wnd")
    local user_info = userlist[getuserid(buf)]
    if(user_info == nil)then return end 

    local user_id = buf:readInt() --要打开的车位窗口
    if(duokai_lib) then
        if(duokai_lib.is_sub_user(user_id) == 1) then
            user_id = duokai_lib.get_parent_id(user_id);
        end
    end
    --第一次从数据库读取数据
    local refresh = 0;
    if(parkinglib.user_list[user_id] ~= nil and (parkinglib.user_list[user_id].refresh == nil  or parkinglib.user_list[user_id].refresh == 1)) then
        refresh = 1; 
    end
    if parkinglib.user_list[user_id] == nil or refresh == 1 then
        local on_ret = function(user_parking_data)
            local enter_desk_data = {};

            if(parkinglib.user_list[user_id] == nil) then
                parkinglib.user_list[user_id] = {};
            end

            if(refresh == 1 and parkinglib.user_list[user_id].enter_desk_data ~= nil) then
                enter_desk_data = parkinglib.user_list[user_id].enter_desk_data;
            end
            user_parking_data.enter_desk_data = enter_desk_data;
            parkinglib.user_list[user_id] = user_parking_data;
            parkinglib.process_parking_time_over(user_info, user_parking_data);
            parkinglib.auto_select_parking(user_info, user_parking_data);
            parkinglib.net_send_parking_data(user_info, user_parking_data, user_id);    
            parkinglib.user_list[user_id].refresh = 0
        end
        parking_db_lib.get_user_parking_db(user_id, on_ret);
    else
        local user_parking_data = parkinglib.user_list[user_id];
        parkinglib.process_parking_time_over(user_info, user_parking_data);
        parkinglib.auto_select_parking(user_info, user_parking_data);
        parkinglib.net_send_parking_data(user_info, user_parking_data, user_id);
    end
end







parkinglib.on_recv_parking_status = function(buf)
    local user_info = userlist[getuserid(buf)]
    if(user_info == nil)then return end 
    local to_userid = buf:readInt();
    local parking_data = parkinglib.user_list[to_userid];
    if(parking_data == nil) then
        return;
    end
    local parking_list = parking_data.parking_list;
    local active_count = 0;
    if(parking_list ~= nil) then
        local status = 0;
        for k, v in pairs(parking_list) do
            if(status < k and v.parking_count > 0) then
                status = k;
                active_count = v.active_count;
            end
        end
        if(status > 0) then
            netlib.send(function(buf)
                buf:writeString("PKSTUTAS");
                buf:writeInt(status);
                buf:writeInt(active_count);
            end, user_info.ip, user_info.port);
        end
    end
end

parkinglib.on_recv_parking_config = function(buf)
    local user_info = userlist[getuserid(buf)]
    if(user_info == nil)then return end 
    netlib.send(function(buf)
        local count = #parkinglib.OP_PARKING_OPEN_PRICE;
        buf:writeString('PKCONFIG');
        buf:writeInt(count);--车位类型数量
        for i = 1, #parkinglib.OP_PARKING_OPEN_PRICE do
            buf:writeInt(i);--车位类型
            buf:writeInt(parkinglib.OP_PARKING_OPEN_PRICE[i]);--车位价钱
        end
        buf:writeInt(3);--暂时写死，因为客户端只可以显示3个价格
        for k, v in pairs(parkinglib.OP_PKARING_RENEW_PACKAGE) do
            buf:writeInt(k);
            buf:writeString(_U(v.name));
            buf:writeString(tostring(v.youhui));
        end
    end, user_info.ip, user_info.port);
end

--续租
parkinglib.on_recv_parking_renew = function(buf) 
    local user_info = userlist[getuserid(buf)];
    if(user_info == nil)then return end 
    local parking_time = buf:readInt();
    local parking_type = buf:readInt();
    local parking_id   = buf:readInt();
  
    local parking_data = parkinglib.user_list[user_info.userId];
    local parking_list = parking_data.parking_list;
    local result = 0;
    local overtime = "";
    local sendFunc = function(buf)
        buf:writeString("PKRENEWRS");
        buf:writeInt(result);        
        buf:writeString(overtime);
    end
    local renew_data = parkinglib.OP_PKARING_RENEW_PACKAGE[parking_time];
    if(parking_data ~= nil and parking_list ~= nil and  
       parking_list[parking_type] ~= nil and renew_data ~= nil) then
           local data = parking_list[parking_type].parking_cars[parking_id];
           if(data ~= nil) then
               local price = parking_time * parkinglib.OP_PARKING_OPEN_PRICE[parking_type] * renew_data.youhui;

               --扣钱
               result = parkinglib.pay_parking(user_info, price, parking_type, parking_time);
               if(result == 1) then
                   if(data.time + data.oversec< os.time()) then
                       --已经过期了
                       data.time = os.time();
                       data.oversec = 0;
                   end
    
                   data.oversec = data.oversec + renew_data.time; 
                   local test_over_time = data.time + data.oversec
                   if (test_over_time > 2147483647) then
                        test_over_time = 2147483647
                   end
                   overtime = timelib.lua_to_db_time(test_over_time);

                   --保存数据
                   parking_db_lib.add_user_parking_db(user_info.userId, parking_list[parking_type].id, parking_type, parking_list[parking_type].parking_count, parking_list[parking_type].parking_cars);

                   --通知客户端更新了
                   parkinglib.net_send_parking_data(user_info, parking_data, user_info.userId);
               end
           end
    end

    netlib.send(sendFunc, user_info.ip, user_info.port);
end

--打开主窗口时,通知客户端数据
parkinglib.net_send_parking_data = function(user_info, parking_data, my_user_id)
    local touserinfo = usermgr.GetUserById(my_user_id) or {};
    parkinglib.calc_parking_status(touserinfo, parking_data);
    netlib.send(function(buf)
        local parking_list = parking_data.parking_list;
        local count = 0;
        for k, v in pairs(parking_list) do
           count = count + 1; 
        end
        buf:writeString("PKOPENMWND");
        buf:writeInt(my_user_id);
        buf:writeString(touserinfo.nick or "");
        buf:writeString(touserinfo.imgUrl or "");
        buf:writeInt(parking_data.car_type);
        buf:writeInt(parking_data.car_count);
        buf:writeInt(parking_data.parking_count);
        local str_price = tostring(parking_data.car_price)
        buf:writeString(str_price);
        buf:writeInt(count);
        for k, v in pairs(parking_list) do
            buf:writeInt(k);--车位类型
            buf:writeInt(#v.cars);
            for k1, v1 in pairs(v.cars) do
				buf:writeInt(v1.index)				--索引，不一定连续，操作列表时依赖这个东东
				buf:writeInt(v1.id)					--礼物编号  决定了显示啥图片
				buf:writeByte(v1.is_using)			--是否正在使用 1=是，0=不是
                buf:writeByte(v1.cansale)			--是否可以出售 1=是，0=不是
                local salegold = car_match_lib.get_user_car_prize(my_user_id, v1.car_id) or car_match_lib.get_car_cost(v1.car_type);
                buf:writeInt(salegold)			    --回收价格
				buf:writeString(v1.fromuser or "")			--赠送人的名字
                buf:writeInt(v1.parking_id or 0);
                buf:writeInt(v1.king_count or 0)
            end

            buf:writeInt(parkinglib.get_parking_count(v.parking_cars));
            for k2, v2 in pairs(v.parking_cars) do
                buf:writeInt(k2);
                local test_over_time = v2.time + v2.oversec
                if (test_over_time > 2147483647) then
                    test_over_time = 2147483647
                end
                if(v2.time ~= nil and v2.time ~= "") then
                    buf:writeString(timelib.lua_to_db_time(v2.time));
                    buf:writeString(timelib.lua_to_db_time(test_over_time));
                else
                    buf:writeString("");
                    buf:writeString("");
                end
            end
        end
        buf:writeInt(parking_data.client_refresh_time or 0);
    end, user_info.ip, user_info.port);
end

-----------------------------------------公开接口------------------------------------------------------
--是否泊车道具
parkinglib.is_parking_item = function(item_id) 
    local ret = 0;
    if(parkinglib.OP_PARKING_CARS[item_id] ~= nil)then
        ret = 1;
    end
    return ret;
end

parkinglib.get_using_car_info = function(userinfo)
    local parking_data = parkinglib.user_list[userinfo.userId];   
    local using_car = nil;
    if(parking_data ~= nil) then
        using_car = parking_data.using_car;
        if(using_car and parkinglib.is_active_item(userinfo, using_car.id, using_car.index) == 0) then
           using_car = nil;  
        end
    end
    return using_car;
end

--是否激活的道具(如果不是车位系统道具，默认认为是激活的)
parkinglib.is_active_item = function(userinfo, item_id, item_index) 
    local parking_data = parkinglib.user_list[userinfo.userId];   
    local ret = 0;
    if(parking_data == nil) then
        return ret;
    end
    local parking_list = parking_data.parking_list;
    local find = false;
    if(parkinglib.is_parking_item(item_id) == 1) then
        if(parking_list ~= nil) then
            for parking_type, v in pairs(parking_list) do
                for k1, v1 in pairs(v.cars) do
                    if(v1.id == item_id and v1.parking_id > 0 and v1.index == item_index) then
                        find = true;
                        ret = 1;
                        break;
                    end
                end
                if(find == true) then
                    break;
                end
            end
        end
    else
        find = true; 
    end

    if(find == false) then
        ret = 0;
    end
    return ret;
end

------------------------------------------系统事件触发-----------------------------------------------

parkinglib.on_after_user_login = function(userinfo)
    parking_db_lib.translate_old_cars_data(userinfo.userId);
    
end
--用户离线的时候
parkinglib.on_user_exit = function(e)
    local user_id = e.data.user_id;
    if(parkinglib.user_list[user_id] ~= nil) then
        parkinglib.user_list[user_id] = nil;
    end
end

parkinglib.on_using_gift = function(e)
    local userinfo = e.data.userinfo;
    local iteminfo = e.data.iteminfo;
    if(userinfo and iteminfo) then
        local parking_data = parkinglib.user_list[userinfo.userId];
        if(parking_data) then
            local parking_list = parking_data.parking_list;
            for k,v in pairs(parking_list) do
                for k1,v1 in pairs(v.cars) do
                    if(v1.is_using == 1) then
                        v1.is_using = 0;
                        parking_data.using_car = nil;
                        car_match_db_lib.update_is_using(userinfo.userId, v1.index, 0);
                        return;
                    end
                end
            end
        end
    end
end

--用户添加道具的时候
parkinglib.on_add_gift_item = function(userinfo, item_id)
    if(parkinglib.user_list[userinfo.userId] ~= nil) then
        parkinglib.user_list[userinfo.userId].refresh = 1;
    end
end

function parkinglib.on_after_sub_user_login(e)
    if(duokai_lib ~= nil) then
        local user_info = e.data.user_info;
        local parent_id = duokai_lib.get_parent_id(user_info.userId);
        parkinglib.user_list[user_info.userId] = parkinglib.user_list[parent_id];
    end
end

--用户登录的时候
parkinglib.already_init_car = function(e)
    local user_info = usermgr.GetUserById(e.data.user_id);
	if(user_info == nil)then 
		TraceError("parkinglib 用户登陆后初始化数据,if(user_info == nil)then")
	 	return
    end
    local userId = user_info.userId;
    
    local on_ret = function(user_parking_data)
        --TraceError(user_parking_data);
        parkinglib.user_list[user_info.userId] = user_parking_data;
        if(duokai_lib and duokai_lib.is_sub_user(user_info.userId) == 0) then
            --不是子帐号
            local all_sub_user = duokai_lib.get_all_sub_user(user_info.userId);
            for sub_user_id, v in pairs(all_sub_user) do
                parkinglib.user_list[sub_user_id] = user_parking_data;
            end
        end
        eventmgr:dispatchEvent(Event("already_init_parking", _S{user_id=user_info.userId}));

        local parking_list = user_parking_data.parking_list;
        --过期处理
        --parkinglib.process_parking_time_over(user_info, user_parking_data);

        --计算充值送的道具
        if(user_info.init_give_parking == nil) then
            user_info.init_give_parking = 1;
            parking_db_lib.get_give_parking_db(userId, function(parking_info)
                for k,v in pairs(parking_info) do
                    parking_db_lib.update_give_parking_db(v.id, function(result)
                        --TraceError("result"..result);
                        if(result == 1) then
                            --TraceError("1");
                            parking_db_lib.delete_give_parking_db(v.id);
    
                            --赠送车位
                            local parking_count = v.parking_count;--赠送的数量
                            local parking_type = v.parking_type;--赠送的类型
                            local data = parking_list[parking_type];
                            --TraceError(data);
    
                            local give_time_count = parking_count;
                            local update = false;
                            if(data.parking_count < parking_count) then
                                --TraceError(data.parking_count);
                                --用户没有这么多的车位,送够车位
                                give_time_count = data.parking_count;
                                data.parking_count = parking_count;
                                local give_count = parking_count - parkinglib.get_parking_count(data.parking_cars); 
                                update = true;
                                for i = 1, give_count do
                                    table.insert(data.parking_cars, {
                                        id=0,
                                        time=timelib.db_to_lua_time(v.sys_time),
                                        oversec=parkinglib.OP_PARKING_BUY_TIME,
                                    });
                                end
                            end
    
                            if give_time_count > 0 then
                                update = true;
                                local min_parking = nil;
                                --赠送用户时间
                                for k5, v5 in pairs(data.parking_cars) do
                                    if(v5.time + v5.oversec < os.time()) then
                                        --过期了
                                        v5.time = os.time();
                                        v5.oversec = 0;
                                    end
                                    if(min_parking == nil or (min_parking.time + min_parking.oversec) > (v5.time + v5.oversec)) then
                                        min_parking = v5;
                                    end
                                end
    
                                if(min_parking ~= nil) then
                                    --加到最少时间的车位上
                                    min_parking.oversec = min_parking.oversec + parkinglib.OP_PARKING_BUY_TIME * give_time_count;
                                end
                            end
    
                            if(update == true) then
                                parking_db_lib.add_user_parking_db(userId, data.id, parking_type, data.parking_count, data.parking_cars);
                            end
                        end
                    end);
                end
            end);

            parkinglib.give_free_parking(user_info)
        end
        
        --[[
        for k, v in pairs(parking_list) do
            local carids = {};
            for k1, v1 in pairs(v.cars) do
                table.insert(carids, v1.id);
            end
            if(#carids > 0) then
                parking_db_lib.log_user_car_db(user_info.userId, k, v.parking_count, carids)
            end
        end
        --]]
    end
    parking_db_lib.get_user_parking_db(user_info.userId, on_ret);
    
    
end


parkinglib.on_site_event = function(e)
    local userinfo = e.data.userinfo;
    local deskno = userinfo.desk; 
    local userId = userinfo.userId;
    local parking_data = parkinglib.user_list[userId];
    if(parking_data ~= nil and deskno ~= nil and deskno > 0) then
        local item_id = 0;
        local item_index = 0;
		if parking_data.using_car then
            item_id = parking_data.using_car.id; 
            item_index = parking_data.using_car.index;
            if(parkinglib.is_active_item(userinfo, item_id, item_index) == 0) then
               item_id = 0; 
            end

            if(parkinglib.is_parking_item(item_id) == 0) then
                item_id = 0;
            end
        end

        if(item_id > 0 and (parking_data.last_desk == nil or parking_data.last_desk ~= deskno)) then
            parking_data.last_desk = deskno;
            if(parking_data.enter_desk_data == nil) then
                parking_data.enter_desk_data = {};
            end
            if(parking_data.enter_desk_data[deskno] == nil or parking_data.enter_desk_data[deskno] + 10 * 60 < os.time()) then
                parking_data.enter_desk_data[deskno] = os.time();
                --onsenddeskchat(userinfo.desk, 4, _U("xxxxxx进来了"), {userId=0, nick=""})
                --广播给所有人
                local sendfunc = function(buf)
                    buf:writeString("PKSHOW")
                    buf:writeInt(item_id);		--对应座位号
                    buf:writeString(userinfo.nick);
                end;
                netlib.broadcastdesk(sendfunc, deskno, borcastTarget.all);
            end
        end
    end
end

--用户卖道具的时候
parkinglib.process_sale_car = function(userinfo, index, callback)
    local parking_data = parkinglib.user_list[userinfo.userId];   
    local parking_list = parking_data.parking_list;
    local find = false;
    local car_info = nil;
    for parking_type, v in pairs(parking_list) do
        find = false;
        for k1, v1 in pairs(v.cars) do
            if(v1.index == index) then
                --把车位里面的数据清空
                car_info = v1;
                table.remove(v.cars, k1);
                if(v1.parking_id ~= nil and v1.parking_id > 0) then
                    --清空车位数据
                    for k2, v2 in pairs(v.parking_cars) do
                        if(k2 == v1.parking_id) then
                            find = true;
                            v2.id = 0;
                            v2.idx = 0;
                            break;
                        end
                    end
                end
                break;
            end
        end

        if(find == true) then--and #carids > 0) then
            --更新车位激活状态
            parking_db_lib.add_user_parking_db(userinfo.userId, v.id, parking_type, v.parking_count, v.parking_cars);
        end

        if(car_info ~= nil) then
            local car_prize = car_match_lib.get_user_car_prize(userinfo.userId, car_info.car_id)
            usermgr.addgold(userinfo.userId, car_prize, 0, new_gold_type.SALECAR, new_gold_type.SALECARTAX, 1, nil, car_info.car_type); 
            break;
        end
    end

    if(car_info == nil) then
        callback(0);
    else
    	callback(1);
    end
    parkinglib.auto_select_parking(userinfo, parking_data);
    parkinglib.net_send_parking_data(userinfo, parking_data, userinfo.userId);
end


function parkinglib.give_free_parking(user_info)
    local user_parking_data = parkinglib.user_list[user_info.userId];
    if(user_parking_data ~= nil and user_parking_data.parking_list ~= nil) then
        local init_parking = 0;
        for k, v in pairs(user_parking_data.parking_list) do
            if(v.id > 0) then
                init_parking = 1;
                break;
            end
        end

        if(init_parking == 0) then
            parking_db_lib.log_user_parking_db(user_info.userId, 1, 1, 0)
        	parkinglib.add_parking(user_info, 1, 1)
			local parking_data = parkinglib.user_list[user_info.userId]
			parkinglib.net_send_parking_data(user_info, parking_data, user_info.userId)
        end
    end
    --[[
	local sql = "select already_give from user_parking_info where user_id = %d"
	sql = string.format(sql, user_info.userId)
	dblib.execute(sql, function(dt)
		if not dt or #dt == 0 then
            parking_db_lib.log_user_parking_db(user_info.userId, 1, 1, 0)
        	parkinglib.add_parking(user_info, 1, 1)
			local parking_data = parkinglib.user_list[user_info.userId]
			parkinglib.net_send_parking_data(user_info, parking_data, user_info.userId)
		end
	end, user_info.userId)--]]
end

--通知该车不到等级不能卖
function parkinglib.send_can_not_sell_car(user_info, car_type, sell_lv)
    if user_info == nil then return end
    netlib.send(function(buf)
        buf:writeString("CANNOTSELL")
        buf:writeInt(sell_lv)
    end, user_info.ip, user_info.port)
end

--命令列表
cmdHandler = 
{
    ["PKOPENMWND"] = parkinglib.on_recv_open_main_wnd,    --打开车位系统主窗口
    ["PKACTIVE"] = parkinglib.active_parking_site,    --激活某个车位
    ["PKCONFIG"] = parkinglib.on_recv_parking_config, --获取车位配置
    ["PKSTUTAS"] = parkinglib.on_recv_parking_status,   --获取车位开通状态
    ["PKRENEW"]  = parkinglib.on_recv_parking_renew,            --车位续租
    ["PKSALE"] = parkinglib.on_recv_sale_car,         --出售车辆
    ["PKUSING"] = parkinglib.on_recv_using_car,       --设置座驾
}


--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end


eventmgr:addEventListener("on_user_exit", parkinglib.on_user_exit);
eventmgr:addEventListener("site_event", parkinglib.on_site_event);
eventmgr:addEventListener("on_using_gift", parkinglib.on_using_gift);
eventmgr:addEventListener("already_init_car", parkinglib.already_init_car);
eventmgr:addEventListener("h2_on_sub_user_login", parkinglib.on_after_sub_user_login)


