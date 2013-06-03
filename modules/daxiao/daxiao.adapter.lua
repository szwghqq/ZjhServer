TraceError("daxiao_adapt_lib loaded!!!")

if (daxiao_adapt_lib and daxiao_adapt_lib.timer) then
    eventmgr:removeEventListener("timer_second", daxiao_adapt_lib.timer); 
end

if not daxiao_adapt_lib then
    daxiao_adapt_lib = _S
    {		
        tex_yipiao_rate=10000, --10000筹码换1银票
        qp_yipiao_rate=10000, --10000筹码换1银票
        key = "234da324fdaf211234",
    }    
end

daxiao_adapt_lib.add_yinpiao_type = {
	NEW_YEAR2013 = 10,
}

daxiao_adapt_lib.is_valid_room=function()
    if(gamepkg.name == "tex" and 18001 ~= tonumber(groupinfo.groupid))then
        return 0
    end
    if(gamepkg.name == "zysz" and 62022 ~= tonumber(groupinfo.groupid))then
        return 0
    end
    return 1
end

--接收购买银票
daxiao_adapt_lib.on_recv_buy_yinpiao = function(buf)
    if (daxiao_adapt_lib.is_valid_room()~=1) then return end
    local user_info = userlist[getuserid(buf)]	
   	if not user_info then return end;
   	--收到银票
   	local buy_type=buf:readInt(); --1购买 2.取出
    local buy_yinpiao = buf:readInt(); --银票数量
    local result = 1    
   	if ((viplib.get_vip_level(user_info) < 1 and buy_type == 1) or buy_yinpiao <= 0 or buy_type ~= 1) then
   		return
   	end
   	--发送购买银票结果
	local function send_buy_yinpiao_result(user_info, result, yinpiao_count)
		netlib.send(function(buf)
            buf:writeString("DVDEXCG");
            buf:writeInt(result);		--兑换方式标识，1，购买， 2，取出， 0，为兑换错误   3，坐下时不能购买
            buf:writeInt(yinpiao_count);		--兑换银票数量
        end,user_info.ip,user_info.port);
	end
    local gold = get_canuse_gold(user_info)--获得用户筹码
    --如果身上的钱不足1万块，不能买银票
    if(buy_type==1 and gold < 10000)then
    	--发送购买银票结果
    	result = 0
		send_buy_yinpiao_result(user_info, result, buy_yinpiao)
    	return
    end
    --加减筹码
    local choushui_gold=0
    --如果是取出，要扣5%的抽水,存入的话，不抽水
   	local yinpiao_choushui=1
   	local yinpiao_rate=daxiao_adapt_lib.tex_yipiao_rate
   	
    --存的时候yinpiao_choushui==1，取的时候是0.95(用来扣抽水）
    local buy_gold = daxiao_adapt_lib.tex_yipiao_rate * buy_yinpiao*yinpiao_choushui
    local can_use_gold = 0 --daxiao_lib.calc_can_use_gold(user_info) --计算能用的钱,因为德州的userinfo.chouma有些问题，所以先不用这个机制
    
    --如果是购买银票，就要看一下钱够不够
    if(user_info.site==nil)then
		can_use_gold = get_canuse_gold(user_info)
	end

    if(buy_type==1 and can_use_gold==0)then
    	--发送购买银票结果
    	result = 3 --坐下时不能购买，不直接判断site而是用can_usegold。以后再改进。
		send_buy_yinpiao_result(user_info, result, buy_yinpiao)
    	return
    end
    if(buy_type==1 and can_use_gold<buy_gold)then
    	--发送购买银票结果
    	result = 0
		send_buy_yinpiao_result(user_info, result, buy_yinpiao)
    	return
    end
    --先加减钱，再加减银票    
	--德州
	if buy_type == 1 then
	  usermgr.addgold(user_info.userId, -buy_gold, choushui_gold, g_GoldType.daxiao_gold, 
                        g_GoldType.daxiao_choushui,-1,nil,999,buy_yinpiao);
  else
    usermgr.addgold(user_info.userId, -buy_gold, choushui_gold, g_GoldType.daxiao_gold_sell, 
                        g_GoldType.daxiao_choushui,-1,nil,999,buy_yinpiao);
  end
	sql="insert into user_exchange_gold(user_id,gold_type,gold_num,sys_time) value(%d,%d,%d,now())"
	sql = string.format(sql, user_info.userId, 1, buy_yinpiao)
	dblib.execute(sql, nil, user_info.userId)	
    send_buy_yinpiao_result(user_info, result, buy_yinpiao)
end

function daxiao_adapt_lib.add_exyinpiao(userId, add_ex_yinpiao, flag, yinpiao_type)
	local user_info = usermgr.GetUserById(userId);
	local sql=""
    if (add_ex_yinpiao == 0) then
        TraceError("为啥要加0赠票")
        return
    end
	if(user_info~=nil)then
		user_info.ex_yinpiao_count = user_info.ex_yinpiao_count or 0 
		user_info.ex_yinpiao_count = user_info.ex_yinpiao_count + add_ex_yinpiao
    end
    sql="insert into user_exchange_gold(user_id,gold_type,gold_num,sys_time) value(%d,%d,%d,now())"
	sql = string.format(sql, user_info.userId, 2, add_ex_yinpiao)
	dblib.execute(sql, nil, user_info.userId)
    netlib.send(function(buf)
        buf:writeString("DVDREYP")
    end, user_info.ip, user_info.port)
    --[[
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
    --]]
end

function daxiao_adapt_lib.on_recv_get_key(buf)
    local user_info = userlist[getuserid(buf)]	
    if not user_info then return end;
    local cur_time = os.time()
    local key = string.md5(daxiao_adapt_lib.key..user_info.userId..cur_time)
    key = key.."|"..user_info.userId.."|"..cur_time
    netlib.send(function(buf)
        buf:writeString("DVGETKEY")
        buf:writeString(key)
    end, user_info.ip, user_info.port)
end

--判断是否为有效的key
function daxiao_adapt_lib.is_valid_key(key, user_id)
    local key_info = split(key, "|")
    if (key_info[1] == nil or key_info[2] == nil or key_info[3] == nil) then
	return 0
    end
    local key = string.md5(daxiao_adapt_lib.key..key_info[2]..key_info[3])
    if (key == key_info[1] and 
        tonumber(key_info[2]) == user_id) then
        return 1
    else
        return 0
    end
end

--三分钟记录赢钱信息
function daxiao_adapt_lib.record_round_info(bet_round_info)
    if (bet_round_info == "") then
        return
    end
    local sql = "insert into daxiao_round_info(bet_info, sys_time) values('%s', now())"
    sql = string.format(sql, bet_round_info)
    dblib.execute(sql)
end

--德州服务器检测三分钟下注的情况
function daxiao_adapt_lib.timer(e)
    if (gamepkg.name ~= "tex" or tonumber(groupinfo.groupid) ~= 18001) then
        return
    end
    local sql = "select id, bet_info from daxiao_round_info where sys_time > DATE_SUB(NOW(),INTERVAL 5 MINUTE)"
    local bet_info = {}
    sql = string.format(sql)
    dblib.execute(sql, function(dt) 
        if (dt and #dt > 0) then
            local split_info = split(dt[1].bet_info, "|")
            local split_item_info = {}
            for k, v in pairs(split_info) do
                split_item_info = split(v, ",")
                bet_info[split_item_info[1]] = {
                    bet_num = split_item_info[2] * daxiao_adapt_lib.tex_yipiao_rate, 
                    win_num = split_item_info[3] * daxiao_adapt_lib.tex_yipiao_rate,
                }
            end
            local ids_info = ""
            for i = 1, #dt do
                if (ids_info ~= "") then
                    ids_info = ids_info..","
                end
                ids_info = ids_info..dt[i].id
            end
            sql = "delete from daxiao_round_info where id in(%s)"
            sql = string.format(sql, ids_info);
            dblib.execute(sql, nil, -100)
            eventmgr:dispatchEvent(Event("daxiao_round_jiesun", {bet_info = bet_info}))            
        end
    end, - 100)    
end

--协议命令
cmd_daxiao_handler = 
{
    ["DVDEXCG"] = daxiao_adapt_lib.on_recv_buy_yinpiao, --接收购买银票
    ["DVGETKEY"] = daxiao_adapt_lib.on_recv_get_key, --请求key
}

--加载插件的回调
for k, v in pairs(cmd_daxiao_handler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("timer_second", daxiao_adapt_lib.timer); 
