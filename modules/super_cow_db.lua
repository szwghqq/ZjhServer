TraceError("init super_cow_db_lib...")

if super_cow_db_lib and super_cow_db_lib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", super_cow_db_lib.on_after_user_login);
end

if not super_cow_db_lib then
    super_cow_db_lib = _S
    {    	   
        on_after_user_login = NULL_FUNC,--登陆后做的事
		init_supercow_db = NULL_FUNC, --初始化数据库
		add_cowgamegold = NULL_FUNC, --加游戏币
		log_supercow_history = NULL_FUNC, --写中奖日志
		update_last_betid = NULL_FUNC, --更新最后一次游戏时的游戏ID到数据库
		update_db_bet_info = NULL_FUNC,
		get_sys_win_from_db = NULL_FUNC,
        update_sys_win = NULL_FUNC,
        update_user_bet_to_db = NULL_FUNC,
		cfg_game_name = {      --游戏配置 
		    ["soha"] = "soha",
		    ["cow"] = "cow",
		    ["zysz"] = "zysz",
		    ["mj"] = "mj",
		    ["tex"] = "tex",
		},
		

    }    
end

--登陆后做的事
function super_cow_db_lib.on_after_user_login(e)
	local user_info = e.data.userinfo
	if(user_info==nil)then return end
	local user_id=user_info.userId	
	super_cow_db_lib.init_supercow_db(user_id)
end

--加减牛牛游戏币
--gold_type:1游戏输赢 2兑换
function super_cow_db_lib.add_cowgamegold(user_id,add_cowgamegold,gold_type,bet_info,call_back)	
	if(add_cowgamegold==0)then return end --为0时不变化钱
	if(user_id==nil)then return end --user_id为空时不变化钱
	
	if (super_cow_lib.is_valid_room()~=1) then return end
	
	--先看玩家身上的钱
	local before_cowgamegold=super_cow_lib.user_list[user_id].cowgamegold_count or -1
	
	--改数据库里的钱	
	local sql="update user_supercow_info set cowgamegold_count=cowgamegold_count+%d where user_id=%d;select cowgamegold_count from user_supercow_info where user_id=%d"
	sql=string.format(sql,add_cowgamegold,user_id,user_id)
	dblib.execute(sql,function (dt)	
		if(dt and #dt>0)then
			local ret_gamegold_count=dt[1].cowgamegold_count
			if(dt[1].cowgamegold_count<0)then 
				ret_gamegold_count=0
				sql="update user_supercow_info set cowgamegold_count=0 where user_id=%d;"
				sql=string.format(sql,user_id)
				dblib.execute(sql,function(dt) end,user_id)				
			end
		
			if(call_back~=nil)then
				call_back(user_id,ret_gamegold_count or -1)
			end
			local user_info=usermgr.GetUserById(user_id)
			if(user_info~=nil)then
				super_cow_lib.send_supercow_gold (user_info,ret_gamegold_count)
			end
			--群发消息，通知新的排名
			super_cow_lib.send_all_users_flag = 1	
			--金币变化后，要看看按钮是不是能点
			super_cow_lib.send_btn_status(user_id)
		else			
			TraceError(debug.traceback())
			TraceError(dt or -1)
			TraceError("error sql="..sql)
		end
		
	end,user_id)
	

	--写日志
	super_cow_db_lib.log_user_supercow(user_id,before_cowgamegold,add_cowgamegold,gold_type,bet_info)	
end

function super_cow_db_lib.log_supercow_history(zhongjiang_num1,zhongjiang_num2,bet_id)
	local sql="insert into log_supercow_history(zhongjiang_num1,zhongjiang_num2,bet_id,sys_time) value (%d,%d,'%s',now());commit;";
	sql=string.format(sql,zhongjiang_num1,zhongjiang_num2,bet_id);
	dblib.execute(sql);
end

--记录玩家游戏币变化
function super_cow_db_lib.log_user_supercow(user_id,before_cowgamegold,add_cowgamegold,goldtype,bet_info)
	local sql="insert into log_user_supercow(user_id,before_cowgamegold,add_cowgamegold,goldtype,bet_info,bet_id,sys_time) value(%d,%d,%d,%d,'%s','%s',now());commit;"
	sql=string.format(sql,user_id,before_cowgamegold,add_cowgamegold,goldtype,bet_info,super_cow_lib.bet_id)
	dblib.execute(sql)    
end

--记录玩家下注数据到数据库
function super_cow_db_lib.update_user_bet_to_db(user_id, bet_gold)
    local sql = "insert into user_supercow_temp_bet(user_id, gold, sys_time) value(%d, %d, now()) ON DUPLICATE KEY update gold = gold + %d, sys_time = now();commit;"
    sql = string.format(sql, user_id, bet_gold, bet_gold)
    dblib.execute(sql, function(dt) end, user_id)
end

--删除临时下注数据
function super_cow_db_lib.clear_user_temp_bet()
    local sql = "delete from user_supercow_temp_bet;commit;"    
    dblib.execute(sql)
end

--回退上次重启前玩家下的注
function super_cow_db_lib.rollback_user_bet()
    local sql = "update user_supercow_info a, user_supercow_temp_bet b set a.cowgamegold_count = a.cowgamegold_count + b.gold where a.user_id = b.user_id"    
    dblib.execute(sql, function(dt) 
        super_cow_db_lib.clear_user_temp_bet()
    end)
end

--初始化疯狂牛牛的数据层数据
function super_cow_db_lib.init_supercow_db(user_id,call_back)
	
	local user_info = usermgr.GetUserById(user_id)
	if(user_info==nil)then return end
	
	local sql="call sp_init_supercow(%d,'%s');"	
	sql=string.format(sql,user_id,super_cow_lib.bet_id)
	dblib.execute(sql,function(dt) 
		if(dt and #dt>0)then		
			if(dt[1].cowgamegold_count==nil or (dt[1].cowgamegold_count==0 and dt[1].bet_info==super_cow_lib.CFG_INIT_BET))then
				super_cow_lib.user_list[user_id]={}
				super_cow_lib.user_list[user_id].user_id=user_id
				super_cow_lib.user_list[user_id].nick_name=user_info.nick or ""
				super_cow_lib.user_list[user_id].face=user_info.imgUrl or ""
				super_cow_lib.user_list[user_id].bet_info=super_cow_lib.CFG_INIT_BET
				super_cow_lib.user_list[user_id].bet_id=super_cow_lib.bet_id
				super_cow_lib.user_list[user_id].cowgamegold_count=0
				sql="insert ignore into user_supercow_info(user_id,cowgamegold_count,bet_info,bet_id,user_nick,sys_time) value (%d,%d,'%s','%s','%s',now());"
				sql=string.format(sql,user_id,0,super_cow_lib.CFG_INIT_BET,super_cow_lib.bet_id,string.trans_str(user_info.nick))
				dblib.execute(sql,function(dt) end,user_id)
			else
				super_cow_lib.user_list[user_id]={}
				super_cow_lib.user_list[user_id].user_id=user_id
				super_cow_lib.user_list[user_id].nick_name=user_info.nick
				super_cow_lib.user_list[user_id].face=user_info.imgUrl
				super_cow_lib.user_list[user_id].bet_info=dt[1].bet_info
				super_cow_lib.user_list[user_id].bet_id=super_cow_lib.bet_id			
				super_cow_lib.user_list[user_id].cowgamegold_count=dt[1].cowgamegold_count	
			end
			
		end
		
	end,user_id)
end

function super_cow_db_lib.update_db_bet_info(user_id,bet_info,bet_id)
		--更新下注的情况
		local sql="update user_supercow_info set bet_info='%s',bet_id='%s' where user_id=%d;commit; "
		sql=string.format(sql,bet_info,bet_id,user_id)
		dblib.execute(sql)
end		

--更新最近的一次betid
function super_cow_db_lib.update_last_betid(betid)
	--更新数据库
	local sql = "insert into cfg_param_info (param_key,param_str_value,room_id) value('SUPERCOW_BETID','-1',%d) on duplicate key update param_str_value = '%s'";
	sql=string.format(sql, groupinfo.groupid,betid)
	dblib.execute(sql)
end

--更新系统输赢的金币
function super_cow_db_lib.update_sys_win(gold)
    --更新数据库, 记录成字符串，因为很容易超过21亿
    local sql = "update supercow_sys_info set gold = '%s', sys_time = now()";
    sql=string.format(sql, tostring(gold))
    dblib.execute(sql)
end

--获取系统输赢的金币
function super_cow_db_lib.get_sys_win_from_db(call_back)
    --更新数据库
    local sql = "select gold from supercow_sys_info";
    dblib.execute(sql, function(dt) 
        if(dt and #dt>0)then
            call_back(tonumber(dt[1].gold))
        else
            call_back(0)
        end
    end)
end


eventmgr:addEventListener("h2_on_user_login", super_cow_db_lib.on_after_user_login);


 