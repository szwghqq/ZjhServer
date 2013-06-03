-------------------------------------------------------
-- 文件名　：yuandan_lib.lua
-- 创建者　：lgy
-- 创建时间：2012-11-12 15：00：00
-- 文件描述：开宝箱，优惠券活动，11月15日
-------------------------------------------------------


TraceError("init yuandan_lib...")

if yuandan_lib and yuandan_lib.on_user_exit then
	eventmgr:removeEventListener("on_user_exit", yuandan_lib.on_user_exit)
end

function yuandan_lib.on_recv_huodong_status(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local status = yuandan_lib.check_datetime()
   	netlib.send(function(buf)
            buf:writeString("YDACTIVE");
            buf:writeInt(status or 0);		--int	0，活动无效（服务端也可不发）；1，活动有效
	end,user_info.ip,user_info.port);
end


--检查有效时间，限时问题int	0，活动无效（服务端也可不发）；1，活动有效, 2不在活动日, 3是情人节
function yuandan_lib.check_datetime()
	local sys_time = os.time();	
	local startime = timelib.db_to_lua_time(yuandan_lib.startime);
	local endtime = timelib.db_to_lua_time(yuandan_lib.endtime);
	if(sys_time > endtime or sys_time < startime) then
		return 0;
	end
	
	return 1

end


--清空他的数据
function yuandan_lib.on_user_exit(e)
	local user_id = e.data.user_id;
	if yuandan_lib.user_list[user_id] == nil then return end	
	yuandan_lib.user_list[user_id] = nil
end

function yuandan_lib.on_recv_open_panel(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId
	local ask_tab = buf:readByte()
	if ask_tab > 2 or ask_tab < 1 then return end
	if yuandan_lib.user_list[user_id]==nil then return end
    --记录打开面板的玩家，即使刷新排行版的时候用到
    yuandan_lib.user_list[user_id].open_panel = 1 
    --发送当前玩家状态
    yuandan_lib.seng_user_gameinfo(user_info, ask_tab)
    --发送兑换历史
    yuandan_lib.send_user_history(user_info)
end


function yuandan_lib.on_recv_ask_gametab(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId
	if yuandan_lib.user_list[user_id]==nil then return end
	local ask_tab = buf:readByte()
	if ask_tab > 3 or ask_tab < 1 then return end
	--发送当前玩家状态
  yuandan_lib.seng_user_gameinfo(user_info, ask_tab)
end

function yuandan_lib.on_recv_close_panel(buf)
    if yuandan_lib.check_datetime() == 0 then return end
    local user_info = userlist[getuserid(buf)]
    if user_info == nil then return end
    local user_id = user_info.userId
    if yuandan_lib.user_list[user_id] == nil then return end
    --记录关闭面板的玩家，即使刷新排行版的时候用到
    yuandan_lib.user_list[user_id].open_panel = nil 
end

--传回对应玩家的游戏状态
function yuandan_lib.seng_user_gameinfo(user_info, ask_tab)
	local user_id = user_info.userId
	if not user_id then return end
	if yuandan_lib.user_list[user_id]==nil then return end
  local n_step  = yuandan_lib.user_list[user_id].now_step[ask_tab] or 1
  local n_state = yuandan_lib.user_list[user_id].now_state[ask_tab] or 1
  local n_card_num = 0
  
  if n_step <= 10 then
  	n_card_num = #yuandan_lib.POKER_ID[ask_tab][n_step]
  else 
  	n_card_num = #yuandan_lib.POKER_ID[ask_tab][10] 
  end
  
	netlib.send(function(buf)
	    buf:writeString("YDGAMEINFO")
	    buf:writeInt(n_step)
	    buf:writeByte(n_card_num + 1)
      buf:writeByte(n_state)
      buf:writeInt(yuandan_lib.CFG_DOZENCOIN_REWARD[ask_tab]*(2^n_step))
  end,user_info.ip,user_info.port)
end

--奖券翻牌
function yuandan_lib.on_recv_check_poker(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then  return  end
	local user_id = user_info.userId
	if not yuandan_lib.user_list[user_id] then  return  end
	local duihuan_type = buf:readByte() --1，2，3对应圆圆蛋蛋乐乐
	local use_type = buf:readByte() --1是达人币 2是金币
	if duihuan_type > 3 or duihuan_type < 1 then return  end
	if use_type > 2 or use_type < 1 then TraceError("错误的use_type")return  end
	local n_step  = yuandan_lib.user_list[user_id].now_step[duihuan_type]
  local n_state = yuandan_lib.user_list[user_id].now_state[duihuan_type]
  if n_state ~= 1 then  
  	TraceError("玩家"..user_id.."不再可以翻牌的状态")
  	return
  end
  local send_result = function(result, n_money, card_num, tb_reward, luck_quan, quan_type)
  	local qingrenjie = yuandan_lib.check_datetime()
		netlib.send(function(buf)
		    buf:writeString("YDCHECKPOKER")
	    	buf:writeInt(result)
	    	buf:writeInt(n_money or 0)
	    	buf:writeInt(card_num or 0)
	    	if card_num and card_num > 0 then
		    	for i=1, card_num  do 
						buf:writeByte(tb_reward[i][1] or 0) --type奖品类型 （1,元旦祝福，2达人币翻倍卡，3汽车）
						buf:writeInt(tb_reward[i][2] or 0)  --car_id 
				  end
				end
				buf:writeByte(qingrenjie)--是否为情人节
			  buf:writeByte(luck_quan or 0) --中奖与否 0没中奖 1中将 （奖券）
			  buf:writeByte(quan_type or 0) --type奖品类型 （1-8中优惠券）
    end,user_info.ip,user_info.port)   
	end
	
	--如果活动过期
	if (yuandan_lib.check_datetime() ~= 1) and (yuandan_lib.check_datetime() ~= 3) then 
		send_result(-4) 
		return  
	end
	
  local result = 1
  if n_step == 1 then
   		result = yuandan_lib.start_game(user_info, user_id, use_type, duihuan_type)
  end
  
  --如果是其他原因，达人币不足，金币不足，坐下
  if result ~= 1 then
  	send_result(result)
  	return
  end
  --开始随机奖励
  local card_num,tb_reward,luck_quan,quan_type = yuandan_lib.give_reward(user_id, n_step, duihuan_type)	
	send_result(1,yuandan_lib.CFG_DOZENCOIN_REWARD[duihuan_type]*(2^n_step),card_num,tb_reward,luck_quan,quan_type)
	yuandan_lib_db.log_yuandan_play_card(user_id, duihuan_type, n_step, tb_reward[1][1])
end
--随机奖励
function yuandan_lib.give_reward(user_id, n_step, duihuan_type)
	local user_info = usermgr.GetUserById(user_id)
	if not user_info then return end
	if n_step > 8 then n_step = 8 end
	local card_num, luck_card, find_reward, car_id, luck_quan, quan_type
	card_num = #yuandan_lib.POKER_ID[duihuan_type][n_step]
	local t = os.time() + math.random(0, 10000000)
	math.randomseed(t)
	local tb_reward = {}
	for i=1, card_num do
		if yuandan_lib.POKER_ID[duihuan_type][n_step][i] == 1 then
				table.insert(tb_reward,{2,0})
		else
				table.insert(tb_reward,{3,yuandan_lib.POKER_ID[duihuan_type][n_step][i]})
		end
	end
	--再加一个没中的
		table.insert(tb_reward,{1,0})
		card_num = card_num + 1
	--生成随机排序
	for i=1,card_num do
		local rand_num = math.random(1, card_num +1 -i)
		local ntemp         = tb_reward[rand_num]
	  tb_reward[rand_num] = tb_reward[card_num +1 -i]
	  tb_reward[card_num +1 -i]  = ntemp
	end
	
	
	--随机卡片奖励
	local find = 0;
	local add = 0;
	local rand = math.random(1, 10000);
	for i = 1, #yuandan_lib.POKER_PORBABILITY_LIST[duihuan_type][n_step] do
				add = add + yuandan_lib.POKER_PORBABILITY_LIST[duihuan_type][n_step][i];
				if add >= rand then
						find = i;
					break;
				end
	end
	if find == 0 then
		--如果没中则把祝福放到tb_reward的第一位交换
		for i=1,card_num do
			if tb_reward[i][1] == 1 then
				local ntemp  = tb_reward[1]
			  tb_reward[1] = tb_reward[i]
			  tb_reward[i] = ntemp
			end
		end
		--重置游戏状态
		yuandan_lib.restart_game(user_id, duihuan_type)
	end
	
	--如果中奖了
	local type_id          = 0
	local item_gift_id     = 0
	local item_number      = 0
	if find > 0 then
		find_reward          = yuandan_lib.POKER_ID[duihuan_type][n_step][find]
		if find_reward == 1 then
			--达人币翻倍卡
			--如果没中则把达人币卡放到tb_reward的第一位交换
			for i=1,card_num do
				if tb_reward[i][1] == 2 then
					local ntemp  = tb_reward[1]
				  tb_reward[1] = tb_reward[i]
				  tb_reward[i] = ntemp
				end
			end
			yuandan_lib.user_list[user_id].now_state[duihuan_type] = 2
			yuandan_lib_db.set_now_state(user_id, duihuan_type, 2)
			--如果是第十次则强制对话
--			if n_step == 10 then
--				yuandan_lib.exchange_goon(user_id, duihuan_type, 2)
--			end
		else
			--加汽车
			for i=1,card_num do
				if tb_reward[i][2] == find_reward then
					local ntemp  = tb_reward[1]
				  tb_reward[1] = tb_reward[i]
				  tb_reward[i] = ntemp
				end
			end
			--加汽车 和材料 
			if find_reward >= 23 and find_reward <= 26 then
				tex_gamepropslib.set_props_count_by_id(find_reward, 1, user_info, nil)
			else
				car_match_db_lib.add_car(user_info.userId, find_reward, 0)
			end
			
			if yuandan_lib.CFG_NAME_REWARD[find_reward] then
				local msg = "玩家在浪漫新春活动中获得%s"
				msg = string.format(msg, yuandan_lib.CFG_NAME_REWARD[find_reward])
				tex_speakerlib.send_sys_msg( _U("恭喜")..user_info.nick.._U(msg))
			  yuandan_lib.add_user_history(user_id, user_info.nick, _U(yuandan_lib.CFG_NAME_REWARD[find_reward]))
			end
			--log
			yuandan_lib_db.log_yuandan_reward(user_id, duihuan_type, n_step, find_reward, 0)
			--重置游戏状态
			yuandan_lib.restart_game(user_id, duihuan_type)
			--发送兑换榜单todo
			--yuandan_lib.notify_all_msg(user_info.userId,user_info.nick,yuandan_lib.CFG_CAR_NAME[find_reward],find_reward,1)
		end
	end
	return card_num, tb_reward, 0, 0
end

--重置游戏
function yuandan_lib.restart_game(user_id, duihuan_type)
		if not yuandan_lib.user_list[user_id] then return end
		yuandan_lib.user_list[user_id].now_state[duihuan_type] = 1
		yuandan_lib.user_list[user_id].now_step[duihuan_type] = 1
		--更新数据库
		yuandan_lib_db.set_gameinfo(user_id, duihuan_type, 1, 1 )
end

--兑换请求
function yuandan_lib.on_recv_exchange_goon(buf)
	--if yuandan_lib.check_datetime() == 0 then return end
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local user_id = user_info.userId
	if not yuandan_lib.user_list[user_id] then return end
	local duihuan_type = buf:readByte() --1，2，3对应圆圆蛋蛋乐乐
	local exchangeorgoon = buf:readByte() -- 1,2 1继续，2兑换
	if yuandan_lib.user_list[user_id].now_state[duihuan_type] ~= 2 then
		TraceError("非法协议now_state~=2")
		return
	end
	yuandan_lib.exchange_goon(user_id, duihuan_type, exchangeorgoon)
end

function yuandan_lib.exchange_goon(user_id, duihuan_type, exchange_goon)
	local user_info = usermgr.GetUserById(user_id)
	if exchange_goon == 1 then
		yuandan_lib.user_list[user_id].now_step[duihuan_type] = yuandan_lib.user_list[user_id].now_step[duihuan_type] + 1
		yuandan_lib_db.set_now_step(user_id, duihuan_type, yuandan_lib.user_list[user_id].now_step[duihuan_type])
		yuandan_lib.user_list[user_id].now_state[duihuan_type] = 1
		yuandan_lib_db.set_now_state(user_id, duihuan_type, 1)
		yuandan_lib.seng_user_gameinfo(user_info, duihuan_type)
	elseif exchange_goon == 2 then
		--给奖励
		local n_money = yuandan_lib.CFG_DOZENCOIN_REWARD[duihuan_type]
		--给筹码
		usermgr.addgold(user_id, n_money*(2^yuandan_lib.user_list[user_id].now_step[duihuan_type]), 0, new_gold_type.LOVE_DAY2013, -1, 1)
		--广播
		if 2^yuandan_lib.user_list[user_id].now_step[duihuan_type] > 1000000  then
				local msg = "玩家在浪漫新春活动中获得"..2^yuandan_lib.user_list[user_id].now_step[duihuan_type].."筹码"
				tex_speakerlib.send_sys_msg( _U("恭喜")..user_info.nick.._U(msg))
		end
		--log
		yuandan_lib_db.log_yuandan_reward(user_id, duihuan_type, yuandan_lib.user_list[user_id].now_step[duihuan_type], 0, n_money*(2^yuandan_lib.user_list[user_id].now_step[duihuan_type])) 
		--通知客户端
		netlib.send(function(buf)
	    buf:writeString("YDEXCHANGE")
	    buf:writeInt(n_money*(2^yuandan_lib.user_list[user_id].now_step[duihuan_type]))
  	end,user_info.ip,user_info.port)
  	--重置游戏
		yuandan_lib.user_list[user_id].now_step[duihuan_type] = 1
		yuandan_lib_db.set_now_step(user_id, duihuan_type, 1)
		yuandan_lib.user_list[user_id].now_state[duihuan_type] = 1
		yuandan_lib_db.set_now_state(user_id, duihuan_type, 1)
	end
	
end
--开始第一步游戏，扣钱后者达人币1成功  -1达人币不够 -2金币不够 -3 玩家几经坐下 
function yuandan_lib.start_game(user_info, user_id, use_type, duihuan_type)
	if yuandan_lib.check_datetime() ~= 1 then return -4 end
	if use_type == 1 then
		if not user_info.wealth.dzcash or user_info.wealth.dzcash < yuandan_lib.CFG_DOZENCOIN_START[duihuan_type] then 
			return -1
		end
		--扣达人币
		usermgr.addcash(user_id, -yuandan_lib.CFG_DOZENCOIN_START[duihuan_type], g_TransType.Buy, "", 1, nil)      
	elseif  use_type == 2 then
		if not user_info.site then
			if not user_info.gamescore or user_info.gamescore < yuandan_lib.CFG_COIN_START[duihuan_type] then
				return -2
			end
			--扣金币
			usermgr.addgold(user_id, -yuandan_lib.CFG_COIN_START[duihuan_type], 0, new_gold_type.LOVE_DAY2013, -1);
		else
			return -3
		end
	end
	yuandan_lib_db.log_start_playcard(user_id, duihuan_type, use_type)
	return 1
end
--兑换记录列表
function yuandan_lib.send_history()
	for k1,v1 in pairs(yuandan_lib.user_list) do
		local user_info = nil
		if v1.user_id then
				user_info = usermgr.GetUserById(v1.user_id)
		end
		if user_info ~= nil and v1.open_panel and v1.open_panel == 1 then
			yuandan_lib.send_user_history(user_info)
		end
   end
end

--兑换记录列表
function yuandan_lib.send_user_history(user_info)
		if user_info ~= nil then
			netlib.send(function(buf)
			    buf:writeString("YDHISTORY")
			    buf:writeInt(#yuandan_lib.history_list)
				for k,v in pairs(yuandan_lib.history_list)do
					buf:writeInt(v.user_id)
					buf:writeString(v.nick_name)
					buf:writeString(v.gift_name)
				end
		    end,user_info.ip,user_info.port)
		end
end

function yuandan_lib.add_user_history(user_id, nick_name, gift_name)
	--加兑换记录列表
	local buf_tab={}
	buf_tab.user_id = user_id
	buf_tab.nick_name = nick_name
	buf_tab.gift_name = gift_name
	if #yuandan_lib.history_list<yuandan_lib.CFG_HISTORY_LEN then
		table.insert(yuandan_lib.history_list,buf_tab)
	else
		table.remove(yuandan_lib.history_list,1)
		table.insert(yuandan_lib.history_list,buf_tab)
	end
	yuandan_lib.send_history()
end


cmdHandler = 
{
    ["YDACTIVE"]    = yuandan_lib.on_recv_huodong_status,    --活动是否有效
 		["YDOPEN"]      = yuandan_lib.on_recv_open_panel,        --打开活动面板
 		["YDGAMEINFO"]  = yuandan_lib.on_recv_ask_gametab,       --请求对应活动区域
   -- ["YDOPENJQ"]    = yuandan_lib.on_recv_open_yhq,          --打开兑换优惠券面板
    ["YDCLOSE"]    	= yuandan_lib.on_recv_close_panel,       --关闭活动面板
    ["YDCHECKPOKER"]= yuandan_lib.on_recv_check_poker,       --收到请求翻牌
    ["YDEXCHANGE"]  = yuandan_lib.on_recv_exchange_goon,          --收到兑换还是继续翻牌
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

eventmgr:addEventListener("on_user_exit", yuandan_lib.on_user_exit)

