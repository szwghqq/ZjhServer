if not parking_db_lib then
	parking_db_lib = _S
	{
        get_user_parking_db = NULL_FUNC,--获取用户车位数据
        add_user_parking_db = NULL_FUNC,--添加用户车位
        log_user_parking_db = NULL_FUNC,--记录用户车位日志
        get_give_parking_db = NULL_FUNC,--获取赠送车位
        delete_give_parking_db = NULL_FUNC, --删除赠送车位
        update_give_parking_db = NULL_FUNC, --更新赠送车位状态
        translate_old_cars_data = NULL_FUNC,--转移旧的车数据
	}
end

parking_db_lib.translate_old_cars_data = function(user_id)
    --需要先获取车的数据
    local touserinfo = usermgr.GetUserById(user_id);
    if(touserinfo == nil) then
        return;
    end

    local touserdata = deskmgr.getuserdata(touserinfo);
    local giftinfo = touserdata.giftinfo;
    local cars = {};
    --过滤礼品获取用户汽车数据
    if(giftinfo ~= nil) then
        for k, v in pairs(giftinfo) do
            if(parkinglib.is_parking_item(v.id) == 1) then
                v.active = 0;
                table.insert(cars, v);
            end
        end
    end
    local add_car = 0
    if(#cars > 0) then
        for k, v in pairs(cars) do
            if(gift_removegiftitem(touserinfo, v.index) >= 0) then
                car_match_db_lib.add_car(user_id, v.id);
                add_car = 1
            end
        end
    end
    if (add_car == 1) then
        car_match_db_lib.init_car_list(user_id, nil, 1)
    end
end

parking_db_lib.log_user_parking_db = function(user_id, parking_type, parking_count, parking_price) 
    local sql = 'insert into log_user_parking_info(user_id, parking_type, parking_count, parking_price, sys_time) values(%d, %d, %d, %d, NOW());commit;';
    sql = string.format(sql, user_id, parking_type, parking_count, parking_price);
    dblib.execute(sql);
end

parking_db_lib.log_user_car_db = function(user_id, parking_type, parking_count, carids)
    local sql = "insert ignore into log_user_car_info(user_id, parking_type, parking_count, total_car, car_info, sys_time) values(%d, %d, %d, '%s', '%s', NOW()) on duplicate key update parking_count = %d, total_car = %d, car_info='%s', sys_time=NOW();commit;";
    local str_carids = '';
    local total_car = 0;
    if(#carids > 0) then
        for k, v in pairs(carids) do
            if(str_carids ~= '') then
                str_carids = str_carids .. "|";
            end
            str_carids =  str_carids .. v;
            total_car = total_car + 1;
        end
    end

    if(str_carids ~= '') then
        str_carids = "|" .. str_carids; 
    end
    sql = string.format(sql, user_id, parking_type, parking_count, total_car, str_carids, parking_count, total_car, str_carids);
    dblib.execute(sql);
end


parking_db_lib.add_user_parking_db = function(user_id, id, parking_type, parking_count, carids, callback)
    local sql = "insert ignore into user_parking_info(user_id, parking_type, parking_count, parking_cars, sys_time) values(%d, %d, %d, '%s', NOW()) on duplicate key update parking_count = %d, parking_cars = '%s';commit;";
    local str_carids = '';
    if(carids~=nil) then
        str_carids = table.tostring(carids);
    end

    if(str_carids ~= "") then
        if(id <= 0) then
            sql = string.format(sql, user_id, parking_type, parking_count, str_carids, parking_count, str_carids);
            dblib.execute(sql, function(dt)
                if(callback) then
                    callback();
                end
            end, user_id);
        else
            dblib.cache_set("user_parking_info", {parking_cars=str_carids, parking_count=parking_count}, "id", id, nil, user_id);
            if(callback) then
                callback();
            end
        end
    else
        if(callback) then
            callback();
        end
    end
end


--只可以获取在线用户的车位数据
parking_db_lib.get_user_parking_db = function(user_id, callback)
    --需要先获取车的数据
    local touserinfo = usermgr.GetUserById(user_id);
    if(touserinfo == nil) then
        callback({});
        return;
    end

    local parking_list = {};
    local car_type = {};
    local cars = {}
    if(car_match_lib.user_list[user_id] ~= nil) then
        cars = car_match_lib.user_list[user_id].car_list;
    end

    if(cars == nil) then
        cars = {};
    end

    local ret = {
        parking_count = 0,--车位总数
        car_count =  0,--车辆总数
        car_type  =  0, --车的类型
        car_price =  0,--车的总价值
        parking_list = parking_list,
        using_car = nil,
    };

        for k, v in pairs(cars) do
            v.id = v.car_type;
            v.index = v.car_id;
            v.parking_id = 0;
            local salegold = car_match_lib.get_user_car_prize(user_id, v.car_id)
            if salegold >= 0 then
            	ret.car_price = ret.car_price + salegold;
            end
            ret.car_count = ret.car_count + 1;
            car_type[v.id] = 1;
            if(v.is_using == 1) then
                ret.using_car = v;
            end
        end

        for k, v in pairs(car_type) do
            ret.car_type = ret.car_type + 1;
        end
    
        --初始化车位类型列表
        
        for k, v in pairs(parkinglib.OP_PARKING_LIMIT_CAR_PRICE) do
             local min = 0;
             if(parkinglib.OP_PARKING_LIMIT_CAR_PRICE[k-1] ~= nil) then
                 min = parkinglib.OP_PARKING_LIMIT_CAR_PRICE[k-1];
             end
             parking_list[k] = {cars={}, parking_count=0, active_count=0, parking_cars={}, id=0};
             for k1, v1 in pairs(cars) do
                 if(parkinglib.OP_PARKING_CARS[v1.id].parking_type <= 0) then
                    local salegold = car_match_lib.get_user_car_prize(user_id, v1.car_id)
                   	if((salegold < v and salegold >= min) or (salegold < 0 and salegold == -1 * k)) then
                        v1.parking_id = 0;
                        v1.org_salegold = salegold;
                        table.insert(parking_list[k].cars, v1);
                   	end
                end
             end
            table.sort(parking_list[k].cars, function(d1, d2)
                return d1.org_salegold > d2.org_salegold;
            end);
        end

        --将特殊车放到指定车位
        for k, v in pairs(cars) do
            local parking_type = parkinglib.OP_PARKING_CARS[v.id].parking_type;
            if(parking_type > 0 and parking_list[parking_type] ~= nil) then
                table.insert(parking_list[parking_type].cars, v);
            end
        end
       
        local sql = string.format("select id from user_parking_info where user_id = %d", user_id);
        dblib.execute(sql, function(dt)
            local data = {};
            if(dt ~= nil and #dt > 0) then
                --从内存里面读取数据
                local count = #dt;
               for k5, v5 in pairs(dt) do
                    dblib.cache_exec("get_user_parking_info", {v5.id}, function(dt2)
                        count = count - 1;
                        if(dt2 == nil or dt2[1] == nil) then
                            if(count <= 0) then
                                callback(ret);
                            end
                            return;
                        end
                        local v = dt2[1];
                      	if(parking_list[v.parking_type] == nil) then
                                 parking_list[v.parking_type] = {cars={}};
                        end
                        local parking_count = v.parking_count; 
                        parking_list[v.parking_type]["id"] = v.id;
                        parking_list[v.parking_type]['parking_count'] = v.parking_count;
                        if(v.parking_cars ~= nil and v.parking_cars ~= "") then
                            parking_list[v.parking_type]['parking_cars'] = table.loadstring(v.parking_cars);--split(v.parking_cars, '|');
                        else
                            parking_list[v.parking_type]['parking_cars'] = {};
                        end
                        local active_count = 0;
                        parking_list[v.parking_type]['active_count'] = 0;
                        ret.parking_count = ret.parking_count + v.parking_count;
                        local type_cars = parking_list[v.parking_type].cars;
                        for k1, v1 in pairs(parking_list[v.parking_type]['parking_cars']) do
                            local find_car = 0;
                            if(v1.id > 0 and v1.idx ~= nil and v1.idx > 0) then
                                for k2, v2 in pairs(type_cars) do
                                    if(v2.index == v1.idx and v2.parking_id == 0) then
                                        v2.parking_id = k1;
                                        find_car = 1;
                                        break;
                                    end
                                end
                                if(find_car == 1) then
                                	active_count = active_count + 1;
                                end
                            end

                            if(find_car == 0 and v1.id > 0) then
                                for k2, v2 in pairs(type_cars) do
                                    if(v2.id == v1.id and v2.parking_id == 0) then
                                        v2.parking_id = k1;
                                        v1.idx = v2.index;
                                        break;
                                    end
                                end
                                active_count = active_count + 1;
                            end
                        end
    
                        parking_list[v.parking_type]['active_count'] = active_count;
        
                        for k2, v2 in pairs(type_cars) do
                            if(v2.parking_id == 0 and v2.is_using == 1) then
                                v2.is_using = 0;
                            end
                        end
    
                        if(count <= 0) then
                            for k6, v6 in pairs(cars) do
                                   if(v6.parking_id == 0 and v6.is_using == 1) then
                                       v6.is_using = 0;
                                   end
                            end 
                            callback(ret);
                        end
                    end, user_id);
               end
           else
               callback(ret);
           end
        end);
    --end);
end

parking_db_lib.update_give_parking_db = function(id, callback)
    local sql =string.format("call sp_update_give_parking(%d);", id);
    dblib.execute(sql, function(dt)
        if(dt ~= nil and dt[1] ~= nil) then
            if(dt[1]["0"] ~= nil) then
                callback(dt[1]["0"]);
            else
                callback(dt[1]["1"]);
            end
        else
            callback(0);
        end
    end);
end

parking_db_lib.get_give_parking_db = function(user_id, callback)
    local sql = string.format("select * from user_giveparking_info where user_id = %d and status = 0", user_id);
    dblib.execute(sql, function(dt)
    	if dt and #dt > 0 then
        callback(dt)
      end
    end)
end

parking_db_lib.delete_give_parking_db = function(id)
    local sql = string.format("delete from user_giveparking_info where id = %d and status = 1", id);
    dblib.execute(sql);
end
