TraceError("init super_cow_db_lib...")

if not football_db_lib then
    football_db_lib = _S
    {    	   
        on_after_user_login = NULL_FUNC,--登陆后做的事
		init_supercow_db = NULL_FUNC, --初始化数据库
		add_gamegold = NULL_FUNC, --加游戏币
		log_supercow_history = NULL_FUNC, --写中奖日志
		update_last_betid = NULL_FUNC, --更新最后一次游戏时的游戏ID到数据库
		update_db_bet_info = NULL_FUNC,
		record_score_caichi = NULL_FUNC,
		record_match_caichi = NULL_FUNC,
		get_score_caichi = NULL_FUNC,
		get_match_caichi = NULL_FUNC,
		jieshuan_match = NULL_FUNC,
		jieshuan_score = NULL_FUNC,
		get_paiming_list =NULL_FUNC,
		CFG_TEX_RATE = 10000,
		CFG_QP_RATE = 100000,
		
		CFG_ORG_BET_INFO1 = "0,0,0",
		CFG_ORG_BET_INFO2 = "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0",
    }    
end

--加减牛牛游戏币
--gold_type:1游戏输赢 2兑换
function football_db_lib.add_gamegold(user_id,add_gamegold,gold_type,call_back)	
	if (super_cow_lib.is_valid_room()~=1) then return end
	local gold_rate=football_db_lib.CFG_TEX_RATE
	if gamepkg.name ~= "tex" then
		gold_rate=football_db_lib.CFG_QP_RATE
	end
	
	if(add_gamegold==0)then return end
	
	--如果出现负1，代表出现了异常
	local before_gamegold=super_cow_lib.user_list[user_id].gamegold_count or -1
	
	--先加减玩家身上的钱
	usermgr.addgold(user_id, add_gamegold*-1*gold_rate, 0, new_gold_type.football, -1);
	
	--改数据库里的钱
	local sql="update user_football_info set gamegold_count=gamegold_count+%d where user_id=%d;select gamegold_count from user_football_info where user_id=%d"
	sql=string.format(sql,add_gamegold,user_id,user_id)
	dblib.execute(sql,function (dt)
		if(call_back~=nil)then
			call_back(dt[1].gamegold_count or -1)
		end
		local user_info=usermgr.GetUserById(user_id)
		if(user_info~=nil)then
			super_cow_lib.send_football_gold (user_info,dt[1].gamegold_count)
		end
	end,user_id)
	
	--写日志
	football_db_lib.log_user_football(user_id,before_gamegold,add_gamegold,gold_type,"")	
end

function football_db_lib.log_football_history(zhongjiang_num1,zhongjiang_num2,bet_id)
	local sql="insert into log_football_history(zhongjiang_num1,zhongjiang_num2,bet_id,sys_time) value (%d,%d,'%s',now());commit;";
	sql=string.format(sql,zhongjiang_num1,zhongjiang_num2,bet_id);
	dblib.execute(sql);
end

--记录玩家游戏币变化
function football_db_lib.log_user_football(user_id,before_gamegold,add_gamegold,goldtype,bet_info)
	local sql="insert into log_user_football(user_id,before_gamegold,add_gamegold,goldtype,bet_info,bet_id,sys_time) value(%d,%d,%d,%d,'%s','%s',now());commit;"
	sql=string.format(sql,user_id,before_gamegold,add_gamegold,goldtype,bet_info,super_cow_lib.bet_id)
	dblib.execute(sql,function(dt) end,user_id)
end

function football_db_lib.list2num(list_tab)
	for i=1,#list_tab do
		list_tab[i]=tonumber(list_tab[i])		
	end
	return list_tab	
end
--初始化欧冠赛的数据层数据
function football_db_lib.get_football_match_db(user_id,call_back)
	if(user_id==nil)then return end
	local user_info = usermgr.GetUserById(user_id)
	if(user_info==nil)then return end
	local get_score_bet= function (bet_info)
		local score_count=0
		local tmp_tab=split(bet_info,",")
		for k,v in pairs (tmp_tab)do
			score_count=score_count+tonumber(v)
		end
		return score_count
	end
	local bet_info=""
	local bet_info2=""
	local gamegold_count=0	
	local sql="select gamegold_count,bet_info,bet_info2,bet_info3,bet_info4 from user_football_info where user_id=%d"
	sql=string.format(sql,user_id)

	dblib.execute(sql,function(dt) 
		if(dt and #dt>0)then
			bet_info=dt[1].bet_info
			bet_info2=dt[1].bet_info2			
			bet_info3=dt[1].bet_info3
			bet_info4=dt[1].bet_info4
		else
			bet_info=football_db_lib.CFG_ORG_BET_INFO1
			bet_info2=football_db_lib.CFG_ORG_BET_INFO2
			bet_info3=football_db_lib.CFG_ORG_BET_INFO1
			bet_info4=football_db_lib.CFG_ORG_BET_INFO2
			--bet_id暂时没用了，所以直接传1
			sql="insert ignore into user_football_info(user_id,gamegold_count,bet_info,bet_info2,bet_info3,bet_info4,bet_id,user_nick,sys_time) value (%d,%d,'%s','%s','%s','%s','%s','%s',now());"
			sql=string.format(sql,user_id,0,bet_info,bet_info2,bet_info3,bet_info4,1,string.trans_str(user_info.nick))
			dblib.execute(sql,function(dt) end,user_id)
		end
		
		if(call_back~=nil)then
			local user_match_data={}
			user_match_data[1]={}
			user_match_data[2]={}			
			
			if(bet_info~=nil and bet_info~="")then
				user_match_data[1]=split(bet_info,",")
				user_match_data[1]=football_db_lib.list2num(user_match_data[1])
			end
			
			if(bet_info3~=nil and bet_info3~="")then
				user_match_data[2]=split(bet_info3,",")
				user_match_data[2]=football_db_lib.list2num(user_match_data[2])
			end
			
			--得到押分数的
			user_match_data[1][4]=get_score_bet(bet_info2)
			user_match_data[2][4]=get_score_bet(bet_info4)
			
			call_back(user_match_data)
		end
	end,user_id)
end

--初始化欧冠赛的数据层数据
function football_db_lib.get_football_score_db(user_id,match_id,call_back)
	if(user_id==nil)then return end
	local user_info = usermgr.GetUserById(user_id)
	if(user_info==nil)then return end
	
	local bet_info=""
	local bet_info2=""
	local gamegold_count=0	
	local sql="select gamegold_count,bet_info,bet_info2,bet_info3,bet_info4 from user_football_info where user_id=%d"
	sql=string.format(sql,user_id)

	dblib.execute(sql,function(dt) 
		if(dt and #dt>0)then
			bet_info=dt[1].bet_info
			bet_info2=dt[1].bet_info2			
			bet_info3=dt[1].bet_info3
			bet_info4=dt[1].bet_info4
		else
			bet_info=football_db_lib.CFG_ORG_BET_INFO1
			bet_info2=football_db_lib.CFG_ORG_BET_INFO2
			bet_info3=football_db_lib.CFG_ORG_BET_INFO1
			bet_info4=football_db_lib.CFG_ORG_BET_INFO2
			
			sql="insert ignore into user_football_info(user_id,gamegold_count,bet_info,bet_info2,bet_info3,bet_info4,bet_id,user_nick,sys_time) value (%d,%d,'%s','%s','%s','%s','%s','%s',now());"
			sql=string.format(sql,user_id,0,bet_info,bet_info2,bet_info3,bet_info4,match_id,string.trans_str(user_info.nick))

			dblib.execute(sql,function(dt) end,user_id)
		end
		
		if(call_back~=nil)then
			local user_score_data={}
			user_score_data[1]={}
			user_score_data[2]={}			
			
			if(bet_info2~=nil and bet_info2~="")then
				user_score_data[1]=split(bet_info2,",")
				user_score_data[1]=football_db_lib.list2num(user_score_data[1])
			end
						
			if(bet_info4~=nil and bet_info4~="")then
				user_score_data[2]=split(bet_info4,",")
				user_score_data[2]=football_db_lib.list2num(user_score_data[2])
			end
			
			if(match_id==1)then
				call_back(user_score_data[1])
			else
				call_back(user_score_data[2])
			end
		end
	end,user_id)
end

function football_db_lib.record_score_data(user_id,score_type,bet_gold,bet_id)
		if(user_id==nil)then return end
		local sql="select bet_info2,bet_info4 from user_football_info where user_id=%d"
		sql=string.format(sql,user_id)
		
		dblib.execute(sql,function(dt) 
			if(dt and #dt>0)then
				if(bet_id==1)then
					bet_info=dt[1].bet_info2
				else
					bet_info=dt[1].bet_info4
				end
			else
				bet_info=football_db_lib.CFG_ORG_BET_INFO2
			end
			local tmp_tab=split(bet_info,",")
			local tmp_str=""
			tmp_tab[score_type]=tmp_tab[score_type]+bet_gold
		
			for i=1,#tmp_tab do
				tmp_str=tmp_str..","..tmp_tab[i]
			end
			tmp_str=string.sub(tmp_str,2)
			
			if(bet_id==1)then
				sql="update user_football_info set bet_info2='%s' where user_id=%d"
			else
				sql="update user_football_info set bet_info4='%s' where user_id=%d"
			end
						
			sql=string.format(sql,tmp_str,user_id)
			dblib.execute(sql,function(dt) end,user_id)
		end,user_id)
end		

function football_db_lib.record_match_data(user_id,match_type,bet_gold,bet_id)
		if(user_id==nil)then return end
		local sql="select bet_info,bet_info3 from user_football_info where user_id=%d"
		sql=string.format(sql,user_id,bet_id)
		dblib.execute(sql,function(dt) 
			if(dt and #dt>0)then
				if(bet_id==1)then
					bet_info=dt[1].bet_info
				else
					bet_info=dt[1].bet_info3
				end
			else
				bet_info=football_db_lib.CFG_ORG_BET_INFO1
			end
			local tmp_tab=split(bet_info,",")
			local tmp_str=""
			tmp_tab[match_type]=tmp_tab[match_type]+bet_gold
		
			for i=1,#tmp_tab do
				tmp_str=tmp_str..","..tmp_tab[i]
			end				
			tmp_str=string.sub(tmp_str,2)			

			if(bet_id==1)then
				sql="update user_football_info set bet_info='%s' where user_id=%d"
			else
				sql="update user_football_info set bet_info3='%s' where user_id=%d"
			end
			sql=string.format(sql,tmp_str,user_id)
			dblib.execute(sql,function(dt) end,user_id)
		end,user_id)
end

function football_db_lib.record_match_caichi(bet_id,caichi_area,bet_gold,peilv)
		local tmp_str=""
		local ret_bet_count=""
		local ret_peilv=""
		--暂时写死只取一条记录
		local sql="select bet_info_count,bet_info_count2,bet_info_count3,bet_info_count4,peilv,peilv2,peilv3,peilv4 from t_football_caichi limit 1"
		dblib.execute(sql,function(dt) 
			if(dt and #dt>0)then
				if(bet_id==1)then
					bet_info=dt[1].bet_info_count
					peilv_info=dt[1].peilv
				else
					bet_info=dt[1].bet_info_count3
					peilv_info=dt[1].peilv3
				end
			else
				bet_info=football_db_lib.CFG_ORG_BET_INFO1
				peilv_info=football_db_lib.CFG_ORG_BET_INFO1
			end

			local tmp_tab=split(bet_info,",")
			tmp_tab[caichi_area]=bet_gold
			for i=1,#tmp_tab do
				tmp_str=tmp_str..","..tmp_tab[i]
			end
			tmp_str=string.sub(tmp_str,2)
			ret_bet_count=tmp_str
			
			
			if(bet_id==1)then
				sql="update t_football_caichi set bet_info_count='%s',peilv='%s'"
			else
				sql="update t_football_caichi set bet_info_count3='%s',peilv3='%s'"
			end
			sql=string.format(sql,ret_bet_count,peilv)
			dblib.execute(sql,function(dt) end,user_id)
		end)

end

function football_db_lib.record_score_caichi(bet_id, caichi_area, bet_gold, peilv)
		local tmp_str=""
		local ret_bet_count=""
		local ret_peilv=""
		--暂时写死只取一条记录
		local sql="select bet_info_count,bet_info_count2,bet_info_count3,bet_info_count4,peilv,peilv2,peilv3,peilv4 from t_football_caichi limit 1"
		dblib.execute(sql,function(dt) 
			if(dt and #dt>0)then
				if(bet_id==1)then
					bet_info=dt[1].bet_info_count2
					peilv_info=dt[1].peilv2
				else
					bet_info=dt[1].bet_info_count4
					peilv_info=dt[1].peilv4
				end
			else
				bet_info=football_db_lib.CFG_ORG_BET_INFO2
				peilv_info=football_db_lib.CFG_ORG_BET_INFO2
			end

			local tmp_tab=split(bet_info,",")
			tmp_tab[caichi_area]=bet_gold
			for i=1,#tmp_tab do
				tmp_str=tmp_str..","..tmp_tab[i]
			end
			tmp_str=string.sub(tmp_str,2)
			ret_bet_count=tmp_str
			
			if(bet_id==1)then
				sql="update t_football_caichi set bet_info_count2='%s',peilv2='%s'"
			else
				sql="update t_football_caichi set bet_info_count4='%s',peilv4='%s'"
			end
			sql=string.format(sql,ret_bet_count,peilv)
			dblib.execute(sql,function(dt) end,user_id)
		end)

end

function football_db_lib.get_match_caichi(bet_id,call_back)
		--暂时写死只取一条记录
		local bet_info=""
		local peilv_info=""
		local sql="select bet_info_count,bet_info_count2,bet_info_count3,bet_info_count4,peilv,peilv2,peilv3,peilv4 from t_football_caichi limit 1"
		dblib.execute(sql,function(dt) 
			if(dt and #dt>0)then
				if(bet_id==1)then
					bet_info=dt[1].bet_info_count
					peilv_info=dt[1].peilv
				else
					bet_info=dt[1].bet_info_count3
					peilv_info=dt[1].peilv3
				end
			else
				bet_info=football_db_lib.CFG_ORG_BET_INFO1
				peilv_info=football_db_lib.CFG_ORG_BET_INFO1
			end
			
			local tmp_tab=split(bet_info,",")
			tmp_tab=football_db_lib.list2num(tmp_tab)

			local tmp_tab2=split(peilv_info,",")
			tmp_tab2=football_db_lib.list2num(tmp_tab2)

			if(call_back~=nil)then
				call_back(tmp_tab,tmp_tab2,bet_id)
			end
		end)
end

function football_db_lib.get_score_caichi(bet_id,call_back)
		--暂时写死只取一条记录
		local bet_info=""
		local peilv_info=""
		local sql="select bet_info_count,bet_info_count2,bet_info_count3,bet_info_count4,peilv,peilv2,peilv3,peilv4 from t_football_caichi limit 1"
		dblib.execute(sql,function(dt) 
			if(dt and #dt>0)then
				if(bet_id==1)then
					bet_info=dt[1].bet_info_count2
					peilv_info=dt[1].peilv2
				else
					bet_info=dt[1].bet_info_count4
					peilv_info=dt[1].peilv4
				end
			else
				bet_info=football_db_lib.CFG_ORG_BET_INFO2
				peilv_info=football_db_lib.CFG_ORG_BET_INFO2
			end

			local tmp_tab=split(bet_info,",")
			tmp_tab=football_db_lib.list2num(tmp_tab)

			local tmp_tab2=split(peilv_info,",")
			tmp_tab2=football_db_lib.list2num(tmp_tab2)

			if(call_back~=nil)then
				call_back(tmp_tab,tmp_tab2,bet_id)
			end
		end)
end

--结算
function football_db_lib.jieshuan_match(bet_id,zj_area,call_back)
		local peilv_info=""
		local peilv=0
		local tmp_tab={}

		local sql="select bet_info_count,bet_info_count2,bet_info_count3,bet_info_count4,peilv,peilv2,peilv3,peilv4 from t_football_caichi limit 1"

		dblib.execute(sql,function(dt)
			if(dt and #dt>0)then

				if(bet_id==1)then
					peilv_info=dt[1].peilv
				else
					peilv_info=dt[1].peilv3
				end
				
				tmp_tab=split(peilv_info,",")
				
				peilv=tonumber(tmp_tab[zj_area])
				
				sql="select user_id,bet_info,bet_info2,bet_info3,bet_info4,user_nick from user_football_info"
				dblib.execute(sql,function(dt)
					if(dt and #dt>0)then
						for i=1,#dt do
							local add_gamegold=0
							local bet_info=""
							if(bet_id==1)then
								bet_info=dt[i].bet_info
							else
								bet_info=dt[i].bet_info3
							end
							local nick_name=dt[i].user_nick or ""
							local user_id=dt[i].user_id
							tmp_tab=split(bet_info,",")
							local gold_rate=football_db_lib.CFG_TEX_RATE
							if gamepkg.name ~= "tex" then
								gold_rate=football_db_lib.CFG_QP_RATE
							end
							add_gamegold=tonumber(tmp_tab[zj_area])*gold_rate*peilv
							add_gamegold=math.floor(add_gamegold)
							
							if(add_gamegold>0)then
								
								
								usermgr.addgold(user_id, add_gamegold, 0, new_gold_type.FOOTBALL, -1);
								
								sql="insert into user_football_zj(user_id,add_gamegold,bet_id,user_nick,sys_time) value(%d,%d,%d,'%s',now()) on duplicate key update add_gamegold=add_gamegold+%d;"
								sql=string.format(sql,user_id,add_gamegold,bet_id,nick_name,add_gamegold)
								dblib.execute(sql,function(dt) end,user_id)
							end
						end
					end
				end)
			end
		end)
end

--结算
function football_db_lib.jieshuan_score(bet_id,zj_area,call_back)
		local peilv_info=""
		local peilv=0
		local tmp_tab={}
		local sql="select bet_info_count,bet_info_count2,bet_info_count3,bet_info_count4,peilv,peilv2,peilv3,peilv4 from t_football_caichi limit 1"
		dblib.execute(sql,function(dt)
			if(dt and #dt>0)then
				if(bet_id==1)then
					peilv_info=dt[1].peilv2
				else
					peilv_info=dt[1].peilv4
				end
				
				tmp_tab=split(peilv_info,",")
				
				peilv=tonumber(tmp_tab[zj_area])
				
				sql="select user_id,user_nick,bet_info,bet_info2,bet_info3,bet_info4,user_nick from user_football_info"
				dblib.execute(sql,function(dt)
					if(dt and #dt>0)then
						for i=1,#dt do
							local add_gamegold=0
							local bet_info=""
							if(bet_id==1)then
								bet_info=dt[i].bet_info2
							else
								bet_info=dt[i].bet_info4
							end
							local nick_name=dt[i].user_nick
							local user_id=dt[i].user_id
							tmp_tab=split(bet_info,",")
							local gold_rate=football_db_lib.CFG_TEX_RATE
							if gamepkg.name ~= "tex" then
								gold_rate=football_db_lib.CFG_QP_RATE
							end
							add_gamegold=tonumber(tmp_tab[zj_area])*gold_rate*peilv
							add_gamegold=math.floor(add_gamegold)
							if(add_gamegold>0)then
								
								usermgr.addgold(user_id, add_gamegold, 0, new_gold_type.FOOTBALL, -1);

								sql="insert into user_football_zj(user_id,add_gamegold,bet_id,user_nick,sys_time) value(%d,%d,%d,'%s',now()) on duplicate key update add_gamegold=add_gamegold+%d;"
								sql=string.format(sql,user_id,add_gamegold,bet_id,nick_name,add_gamegold)
								dblib.execute(sql,function(dt) end,user_id)
							end
						end
					end
				end)
			end
		end)
end

function football_db_lib.get_paiming_list(user_id,bet_id,paiming_len,call_back)
	local paiming_list={}
	local sql="select user_id,add_gamegold,user_nick,bet_id from user_football_zj where bet_id=%d order by add_gamegold desc limit %d"
	sql=string.format(sql,bet_id,paiming_len)
	dblib.execute(sql,function(dt)
		if(dt and #dt>0)then
			for i=1,#dt do
				paiming_list[i]={}
				paiming_list[i][1]=dt[i].user_id
				paiming_list[i][2]=dt[i].add_gamegold
				paiming_list[i][3]=dt[i].user_nick
				paiming_list[i][4]=tonumber(dt[i].bet_id)		

			end
			--自己的中奖情况
			sql="select user_id,add_gamegold,user_nick,bet_id  from user_football_zj where user_id=%d and bet_id=%d"
			sql=string.format(sql,user_id,bet_id)
			dblib.execute(sql,function(dt)
				if(dt and #dt>0)then
					
					paiming_list[#paiming_list+1]={}
					paiming_list[#paiming_list][1]=user_id
					paiming_list[#paiming_list][2]=dt[1].add_gamegold
					paiming_list[#paiming_list][3]=dt[1].user_nick
					paiming_list[#paiming_list][4]=tonumber(dt[1].bet_id)
				else--自己没中奖

					paiming_list[#paiming_list+1]={}
					paiming_list[#paiming_list][1]=user_id
					paiming_list[#paiming_list][2]=0
					paiming_list[#paiming_list][3]=""
					paiming_list[#paiming_list][4]=bet_id
				end
				
				if(call_back~=nil)then
					call_back(paiming_list)
				end
				
			end,user_id)
		end
	end)
	
end

