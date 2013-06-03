
--只支持礼券 商品要改动 一些地方。
--不兼容
TraceError("init shop_lib...")
if shop_lib and shop_lib.restart_server then
	eventmgr:removeEventListener("on_server_start", shop_lib.restart_server);
end

if not shop_lib then
    shop_lib = _S
    {    	   
		open_shop_panl = NULL_FUNC,
		buy_gift = NULL_FUNC,
		get_client_info = NULL_FUNC,
		exchange_real_gift = NULL_FUNC,
		set_gift_list = NULL_FUNC,
		check_can_buy = NULL_FUNC,
		restart_server = NULL_FUNC,
		get_gold_type = NULL_FUNC,
		is_today = NULL_FUNC,
		gift_list = {},
		CFG_SHOPGOLD_TYPE = {
			["SHOP_GOLD"] = 0, --换普通礼品
			["HUODONG_GOLD"] = 1, --在活动中送的
			["SHOP_SY_GOLD"] = 2, --换实物
				
		}
    }
end

--打开商品面板
function shop_lib.open_shop_panl(buf)	
	local user_info = userlist[getuserid(buf)]	
	if user_info == nil then return end
	local gift_type = buf:readByte()
	
	local send_result = function(n_count)
		if gift_type == 0 then user_info.diamond_gold = n_count end --打开商城时同步一下礼券数量备用
		local gift_list = shop_lib.get_gift_list_by_type(gift_type)
		local gift_list_info = shop_lib.get_gift_info_str(gift_list)
		netlib.send(function(buf)
			buf:writeString("SHOPLS")
			buf:writeInt(n_count)
			buf:writeString(gift_list_info or "")
		end, user_info.ip, user_info.port)
	end
	--目前只有2种货币单位，筹码和礼券
	if gift_type == 0 then
		tex_gamepropslib.get_props_count_by_id(tex_gamepropslib.PROPS_ID.DIAMOND, user_info, send_result)
	else
		send_result(user_info.gamescore)
	end	
end

--请求购买商品
function shop_lib.buy_gift(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local deskno = user_info.desk
	local desk_info =  desklist[deskno]
	local to_user_siteids = buf:readString() --客户端旧程序没有user_id，要改造的话需要的时间比较久，所以保留原来的接口，由服务器计算user_id  
	local gift_type = buf:readByte()
	local gift_id = buf:readInt()
	local gift_count = buf:readInt()
    local gift_type_ex = 0;
	
	--防止客户端传入异常的数据
	if gift_count <= 0 then return end
	local to_user_tab_before = split(to_user_siteids, ",")
	if #to_user_tab_before == 0 then return end
	local remain_gift_count = shop_lib.get_remain_gift(gift_type_ex, gift_id)
	local can_buy,to_user_tab = shop_lib.check_can_buy(user_info, gift_type_ex, gift_id, gift_count * #to_user_tab_before, to_user_tab_before)
	
	--如果不能买，就通知客户端，然后直接返回
	if can_buy ~= 1 then
		netlib.send(function(buf)
			buf:writeString("SHOPBUY")
			buf:writeByte(can_buy)
			buf:writeInt(remain_gift_count)
			buf:writeByte(gift_type_ex)
		end, user_info.ip, user_info.port)
		return
    end
	local to_user_sites = table.clone(to_user_tab);
    local failedusers = {};
    if(shop_lib.is_gift_item(gift_type_ex, gift_id) == 1) then
    	for i = 1, #to_user_sites do
    		local touserinfo = nil
    		local tosite = tonumber(to_user_sites[i]);
    		if(tosite and tosite ~= 0 and deskno and deskno > 0) then
    			touserinfo = deskmgr.getsiteuser(deskno, tosite)
    		else
    			--送给自己
    			touserinfo = user_info
            end
    
    		if touserinfo then
    			if gift_getgiftcount(touserinfo) + gift_count >= 100 and gift_id < 100000 then
    				if(user_info.userId == touserinfo.userId) then  --自己给自己送礼
                        table.remove(to_user_tab, i);
    					net_send_gift_faild(touserinfo, 5, gift_id, gift_count, gift_type)		--告诉客户端礼物已满
    				else
                        table.remove(to_user_tab, i);
    					net_send_gift_faild(touserinfo, 3, gift_id, gift_count, gift_type)		--1=成功扣钱 2=钱不够 3=礼物满了 4=礼物满了 0=其他异常				
                        table.insert(failedusers, {site = touserinfo.site or 0, retcode = 4})
    				end
    			end
    		end
        end
    
        if(#failedusers > 0) then
            net_send_gift_faildlist(user_info, failedusers)
        end
    end

    if(#to_user_tab <= 0) then
        return;
    end
		
	local need_gift_count = #to_user_tab * gift_count --需要的礼品数量
	
	--先扣资金
	local gold_type = shop_lib.get_gold_type(gift_type_ex)
	local cost = shop_lib.gift_list[gift_type_ex][gift_id].cost
	local change_gold = cost * gift_count * #to_user_tab
	
	local call_back = function (props_count)
		--解锁数据库
		user_info.update_new_shop = 0
		--再给礼品
		local to_user_id = -1
		for k, v in pairs(to_user_tab) do
			to_user_id = shop_lib.get_user_id_by_siteno(deskno, tonumber(v))
			if to_user_id == -2 then
				to_user_id = user_info.userId --找不到对应的ID，买给自己。
			end
			shop_lib.give_gift(user_info, to_user_id, gift_type_ex, gift_id, gift_count)
		end
		
	  eventmgr:dispatchEvent(Event("on_user_change_coupon", _S{user_id = user_info.userId, to_user_id = to_user_id, gift_count = gift_count, gools_id = gift_id, coupon_num = change_gold}));
		netlib.send(function(buf)
			buf:writeString("SHOPBUY")
			buf:writeByte(1) --购买成功 
			buf:writeInt(remain_gift_count - need_gift_count) --得到现在礼品的剩余数量
			buf:writeByte(gift_type_ex)
		end, user_info.ip, user_info.port)
		
		if gift_type_ex == 0 then user_info.diamond_gold = props_count end --打开商城时同步一下礼券数量备用
		local gift_list = shop_lib.get_gift_list_by_type(0)--礼券区是0 如果改成兼容筹码购买必须更改
		local gift_list_info = shop_lib.get_gift_info_str(gift_list)
		netlib.send(function(buf)
			buf:writeString("SHOPLS")
			buf:writeInt(props_count)
			buf:writeString(gift_list_info or "")
		end, user_info.ip, user_info.port)
		
	end
	
	--如果数据库锁定则返回
	if user_info.update_new_shop and user_info.update_new_shop == 1 then
		return
	end
	--锁定数据库
	user_info.update_new_shop = 1
	
	
	--再扣剩余礼品数量,扣钱
	shop_lib.add_remain_gift(gift_type_ex, gift_id, need_gift_count)
	shop_lib.add_gold(user_info.userId, gold_type, -1 * change_gold, shop_lib.CFG_SHOPGOLD_TYPE.SHOP_GOLD, call_back, gift_count)
end

function shop_lib.send_duihuan_result(user_info, result, remain_gift, gift_type)
	netlib.send(function(buf)
		buf:writeString("SHOPDH2")
		buf:writeByte(result)
		buf:writeInt(remain_gift)
		buf:writeByte(gift_type)
	end, user_info.ip, user_info.port)
end

--得到之前的购买信息
--现在没有实物奖，可预期的情况也是只有少部分实物奖，所以先直接读数据库，如果实物奖会有很多人兑换时再优化一下走memocache
function shop_lib.get_client_info(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId
	local gift_type = buf:readByte()
	local gift_id = buf:readInt()
	local gift_count = buf:readInt()
	

	--检查一下能不能兑换
	local can_buy = shop_lib.check_can_buy(user_info, gift_type, gift_id, gift_count)
	if can_buy ~= 1 then
		local remain_gift = shop_lib.get_remain_gift(gift_type, gift_id)
		shop_lib.send_duihuan_result(user_info, can_buy, remain_gift, gift_type)
		return
	end
	
	local send_func = function(before_info)
		netlib.send(function(buf)
			buf:writeString("SHOPDH")
			buf:writeString(before_info.real_name or "")
			buf:writeString(before_info.tel or "")
			buf:writeString(before_info.yy_num or "")
			buf:writeString(before_info.real_address or "")			
		end, user_info.ip, user_info.port)
		
	end
	shop_db_lib.get_before_buy_info(user_id, send_func)
	
end

--请求兑换实物礼品
function shop_lib.exchange_real_gift(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local gift_type = buf:readByte()
	local gift_id = buf:readInt()
	local gift_count = buf:readInt()
	--检查一下能不能兑换
	local can_buy = shop_lib.check_can_buy(user_info, gift_type, gift_id, gift_count)
	local remain_gift = shop_lib.get_remain_gift(gift_type, gift_id)
	if can_buy ~= 1 then
		shop_lib.send_duihuan_result(user_info, can_buy, remain_gift, gift_type)
		return
	end
	
	--先扣资金
	local gold_type = shop_lib.get_gold_type(gift_type)
	local cost = shop_lib.gift_list[gift_type][gift_id].cost
	local change_gold = cost * gift_count
	shop_lib.add_gold(user_info.userId, gold_type, -1* change_gold, shop_lib.CFG_SHOPGOLD_TYPE.SHOP_SY_GOLD)
	--再扣剩余礼品数量
	shop_lib.add_remain_gift(gift_type, gift_id, gift_count)	
	
	local real_user_info = {
		["user_id"] = user_info.userId,
		["real_name"] = buf:readString(),
		["tel"] = buf:readString(),
		["yy_num"] = buf:readString(),
		["real_address"] = buf:readString(),
	}
	local gift_des =  shop_lib.gift_list[gift_type][gift_id].gift_des or ""
	shop_db_lib.save_real_gift_info(gift_type, gift_id, gift_count, gift_des, real_user_info)
	--通知客户端兑换成功
	shop_lib.send_duihuan_result(user_info, 1, remain_gift, gift_type)
end

--得到资金类型
function shop_lib.get_gold_type(gift_type)
	if gift_type == 0 then
		return 0
	else
		return 1
	end
end

--得到某一类礼品的列表
function shop_lib.get_gift_list_by_type(gift_type)
	if shop_lib.gift_list == nil then return end
	return shop_lib.gift_list[gift_type]
end

--得到以||分隔的字符串
function shop_lib.get_gift_info_str(gift_list)
	if not gift_list then return end
	local tmp_str = ""
	for k, v in pairs(gift_list) do
		tmp_str = tmp_str .. "||" ..v.gift_type --商品类型 0 礼卷 1可售 2 一般 3图纸
		tmp_str = tmp_str.."||"..v.ex_type --礼券被换成的类型
		if v.gift_type == 0 and v.ex_type==4 then
			tmp_str = tmp_str .. "||1" --是否实物（0不是，1是)
		else
			tmp_str = tmp_str .. "||0" --是否实物（0不是，1是)
		end
		tmp_str = tmp_str .. "||" ..v.gift_id --商品编号
		tmp_str = tmp_str .. "||" ..v.cost --商品价格
		local remain_num = shop_lib.get_remain_gift(v.gift_type, v.gift_id)
		tmp_str = tmp_str .. "||" ..remain_num --剩余数量
		tmp_str = tmp_str .. "||" ..v.can_give    --是否可送人
		if tonumber(v.valid_time) == -999 then
			tmp_str = tmp_str .. "||" .._U("永久")  --有效期
		else
			tmp_str = tmp_str .. "||" ..v.valid_time.._U("天")  --有效期
		end
		tmp_str = tmp_str.."||"..v.gift_des
		
	end
	tmp_str=string.sub(tmp_str, 3) --去掉第一组||
	return tmp_str
end

--提供接口，用来设置某一类商品信息
function shop_lib.set_gift_list_by_type(gift_type, gift_list_tab)
	shop_lib.gift_list[gift_type] = {}
	for k, v in pairs(gift_list_tab) do
		shop_lib.gift_list[gift_type][v.gift_id] = v
	end
end

--判断是不是能买
--返回 -1货币不足 -2商品不足 -3其他错误 1能购买
function shop_lib.check_can_buy(user_info, gift_type, gift_id, gift_count, to_user_tab)
	if user_info == nil then return -3 end
	local deskno = user_info.desk
	
	local cost = shop_lib.gift_list[gift_type][gift_id].cost
	local need_gold = cost * gift_count
	local can_use_gold = get_canuse_gold(user_info);
	if gift_type == 0 and  need_gold > user_info.diamond_gold then
		return -1
	end
	if gift_type ~= 0 and need_gold > can_use_gold then
		return -1
	end
	
	local remain_count = shop_lib.get_remain_gift(gift_type, gift_id)
	if gift_count > remain_count then
		return -2
	end
	
	if to_user_tab then
		for k, v in pairs(to_user_tab)do
			if tonumber(v) ~= 0 then
				local to_user_info = shop_lib.get_user_id_by_siteno(deskno, tonumber(v))
				if to_user_info == -1 then 
					table.remove(to_user_tab,k) 
				end
			end
		end
		return 1,to_user_tab
	end
	return 1
end

--商品加减钱的接口
--gold_type==0 礼券  gold_type==1 筹码 
--change_gold 变化的资金数量
--change_result 变化的原因
--这个方法不做正确性判断，所以钱够不够需要预先判断好
function shop_lib.add_gold(user_id, gold_type, change_gold, change_result, call_back, gift_count)
	local before_change = 0
	if not gift_count then gift_count = 1  end
	--加减钱
    local user_info = usermgr.GetUserById(user_id)
	if gold_type == 0 then
		if user_info == nil then return end --目前礼券只有在线才能用
		before_change = user_info.diamond_gold
		tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.DIAMOND, change_gold, user_info, call_back)
		
	else
		before_change = user_info.gamescore
		usermgr.addgold(user_id, change_gold, 0, new_gold_type.NEW_SHOP, -1);
	end
	
	--写日志
	shop_db_lib.add_gold_log(user_id, gold_type, change_gold, before_change, change_result)
end

--给礼品
function shop_lib.give_gift(from_user_info, to_user_id, gift_type, gift_id, gift_count)
	local to_user_info = usermgr.GetUserById(to_user_id)
	if to_user_info == nil then return end --暂时不支持离线送礼 
	local read_gift_type = gift_type
	if gift_type == 0 then
		read_gift_type = shop_lib.gift_list[0][gift_id].ex_type
	end

	if read_gift_type == 1 then --礼品
		for i=1, gift_count do
			gift_addgiftitem(to_user_info, gift_id, from_user_info.userId, from_user_info.nick, true)
		end
		if from_user_info.site then
			tex_gamepropslib.net_broadcast_togive_props(from_user_info.desk, from_user_info.site, to_user_info.site, gift_id, 1, gift_count)
		end
	elseif read_gift_type == 2 then --道具和图纸
		tex_gamepropslib.set_props_count_by_id(gift_id, gift_count, to_user_info)
		if from_user_info.site then
			tex_gamepropslib.net_broadcast_togive_props(from_user_info.desk, from_user_info.site, to_user_info.site, gift_id, 2, gift_count)
		end
	elseif read_gift_type == 3 then --车
		for i=1, gift_count do
			car_match_db_lib.add_car(to_user_info.userId, gift_id, 0, 1)
		end
		if from_user_info.site then
			tex_gamepropslib.net_broadcast_togive_props(from_user_info.desk, from_user_info.site, to_user_info.site, gift_id, 3, gift_count)
		end
	end 
end

--变化今日剩余数量
function shop_lib.add_remain_gift(gift_type, gift_id, change_count)
	if shop_lib.is_today(timelib.db_to_lua_time(shop_lib.gift_list[gift_type][gift_id].sys_time)) == 1 then
		shop_lib.gift_list[gift_type][gift_id].today_num = shop_lib.gift_list[gift_type][gift_id].today_num + change_count
	else
		shop_lib.gift_list[gift_type][gift_id].today_num = change_count
	end
	
	shop_lib.gift_list[gift_type][gift_id].sys_time = timelib.lua_to_db_time(os.time())
	--修改数据库
	shop_db_lib.save_today_num(gift_type, gift_id, change_count)
end

-- 得到剩余礼品数量
function shop_lib.get_remain_gift(gift_type, gift_id)
	if gift_type == nil or gift_id == nil then
		TraceError(debug.traceback())
		return -1
	end
	if shop_lib.gift_list[gift_type][gift_id].sys_time ~= nil and shop_lib.is_today(timelib.db_to_lua_time(shop_lib.gift_list[gift_type][gift_id].sys_time)) == 1 then
		return shop_lib.gift_list[gift_type][gift_id].gift_num - shop_lib.gift_list[gift_type][gift_id].today_num
	else
		return shop_lib.gift_list[gift_type][gift_id].gift_num
	end
end

function shop_lib.is_gift_item(gift_type, gift_id)
    if(shop_lib.gift_list[gift_type][gift_id].ex_type == 1) then
        return 1;
    end
    return 0;
end

function shop_lib.get_user_id_by_siteno(deskno, siteno)
	if siteno == 0 then return -2 end
	if deskno==nil or siteno == nil then return -1 end
	local desk_info =  desklist[deskno]
	if not desk_info then return -1 end
	local user_info = userlist[desk_info.site[siteno].user]
	if user_info == nil then
		return -1
	else
		return user_info.userId
	end
end

function shop_lib.restart_server()
	shop_db_lib.init_coupon_list()
end

--是不是在同一天
function shop_lib.is_today(time1, time2)
	if time1==nil  or time1=="" then return 0 end
	if time2 == nil  or time2=="" then time2 = os.time() end
	local table_time1 = os.date("*t",time1);
	local year1  = table_time1.year;
	local month1 = table_time1.month;
	local day1 = table_time1.day;
	local time1 = year1.."-"..month1.."-"..day1.." 00:00:00"
	
	local table_time2 = os.date("*t",time2);
	local year2  = tonumber(table_time2.year);
	local month2 = tonumber(table_time2.month);
	local day2 = tonumber(table_time2.day);
	local time2 = year2.."-"..month2.."-"..day2.." 00:00:00"

	--容错处理，如果时间拿到空的，会得到1970年
	if (tonumber(year1)<2012 or tonumber(year2)<2012) then 
		return 0 
	end
	if (time1 ~= time2) then
		return 0
	end
	return 1
end

--协议命令
cmd_shop_handler = 
{
	["SHOPLS"] = shop_lib.open_shop_panl,
	["SHOPBUY"] = shop_lib.buy_gift,
	["SHOPDH"] = shop_lib.get_client_info,
	["SHOPDH2"] = shop_lib.exchange_real_gift,
}

--加载插件的回调
for k, v in pairs(cmd_shop_handler) do 
	cmdHandler_addons[k] = v
end
eventmgr:addEventListener("on_server_start", shop_lib.restart_server)