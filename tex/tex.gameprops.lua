--加载配置表格
config_for_yunying = config_for_yunying or {}

TraceError("加载 gameprops(游戏道具) 插件....")
if tex_gamepropslib and tex_gamepropslib.on_after_user_login then
	eventmgr:removeEventListener("h2_on_user_login", tex_gamepropslib.on_after_user_login);
end

if tex_gamepropslib and tex_gamepropslib.timer then
	eventmgr:removeEventListener("timer_minute", tex_gamepropslib.timer);
end


if not tex_gamepropslib then
	tex_gamepropslib = _S
	{
        get_props_list = NULL_FUNC,                 --获取玩家内存中的道具列表

        on_recv_get_props = NULL_FUNC,              --收到“个人设置”相关信息
        on_recv_togive_props = NULL_FUNC,           --收到“牌样设置”相关信息
        net_broadcast_togive_props = NULL_FUNC,
        net_send_error_result = NULL_FUNC,                --只针对玩家自己发送协议
        net_send_togive_props_result = NULL_FUNC,
        net_send_refresh_props_count = NULL_FUNC,   --通知客户端，更新道具数量TIPS
        on_after_user_login = NULL_FUNC,			--用户登录初始化道具
        vaild_props_id = NULL_FUNC,                 --检查道具ID是否有效：0，无效；1，有效
        get_props_count_by_id = NULL_FUNC,          --根据道具ID取得道具数量
        set_props_count_by_id = NULL_FUNC,          --根据道具ID设置道具数量
		on_recv_open_box = NULL_FUNC,               --客户端传来开宝箱
		open_box = NULL_FUNC,
        PROPS_LEN = 8,              --道具种类数量
        PROPS_ID = _S               --道具ID，与数据库表 user_props_info 对应
        {
            KICK_CARD_ID    = 1,    --踢人卡ID
            SPEAKER_ID      = 2,    --小喇叭ID
            ShipTickets_ID      = 3,    --方舟资格证书
            GUN_1_ID = 4,--鞭炮
            GUN_2_ID = 5,--烟花
            GUN_3_ID = 6,--礼炮
            NewYearTickets_ID = 7,--春节竞技场门票
            love_chocolate_id = 8,--爱心巧克力
            wabao_map_id = 9,--藏宝图
            DIAMOND = 10, --钻石礼券
          	GOLD_MOONCATE             = 11,   --金月饼
          	SILVER_MOONCATE           = 12,  --银月饼
          	BRONZE_MOONCATE           = 13,  --铜月饼
          	MUBAOXIANG         			  = 14,  --木宝箱
          	TIEBAOXIANG  		 			    = 15,  --铁宝箱
          	TONGBAOXIANG              = 16,  --铜宝箱
          	YINBAOXIANG               = 17,  --银宝箱
          	JINBAOXIANG               = 18,  --金宝箱
          	
          	BHXY_ID                   = 19,   --半盒香烟
          	YPPJ_ID                   = 20,   --一瓶啤酒
          	YXBLS_ID                  = 21,   --一小包零食
          	XZGZ_ID                   = 22,   --鲜榨果汁
          	
          	ROSE_RED                  = 23,  --红玫瑰
          	ROSE_PINK                 = 24,  --份玫瑰
          	DIAMOND_PURPLE            = 25,  --紫水晶
          	DIAMOND_BLUE              = 26,  --蓝冰钻
          	
          	WING1                     = 27,  --骑士翅膀
          	WING2                     = 28,  --准男爵翅膀
          	WING3                     = 29,  --男爵翅膀
          	WING4                     = 30,  --子爵翅膀
          	WING5                     = 31,  --伯爵翅膀
          	WING6                     = 32,  --侯爵翅膀
          	WING7                     = 33,  --公爵翅膀
          	WING8                     = 34,  --亲王翅膀
          	WING9                     = 35,  --国王翅膀
          	FEATHER                   = 36,  --爵位羽毛   
          	  
  					
        		FANGKUAI1 = 5001,
        		FANGKUAI2 = 5002,
        		FANGKUAI3 = 5003,
        		FANGKUAI4 = 5004,
        		FANGKUAI5 = 5005,
        		FANGKUAI6 = 5006,
        		FANGKUAI7 = 5007,
        		FANGKUAI8 = 5008,
        		FANGKUAI9 = 5009,
        		FANGKUAI10 = 5010,
        		FANGKUAIJ  = 5011,
        		FANGKUAIQ  = 5012,
        		FANGKUAIK  = 5013,
        		MEIHUA1    = 5014,
        		MEIHUA2    = 5015,
        		MEIHUA3    = 5016,
        		MEIHUA4    = 5017,
        		MEIHUA5    = 5018,
        		MEIHUA6    = 5019,
        		MEIHUA7    = 5020,
        		MEIHUA8    = 5021,
        		MEIHUA9    = 5022,
        		MEIHUA10   = 5023,
        		MEIHUAJ    = 5024,
        		MEIHUAQ    = 5025,
        		MEIHUAK    = 5026,
        		HONGTAO1   = 5027,
        		HONGTAO2   = 5028,
        		HONGTAO3   = 5029,
        		HONGTAO4   = 5030,
        		HONGTAO5   = 5031,
        		HONGTAO6   = 5032,
        		HONGTAO7   = 5033,
        		HONGTAO8   = 5034,
        		HONGTAO9   = 5035,
        		HONGTAO10  = 5036,
        		HONGTAOJ   = 5037,
        		HONGTAOQ   = 5038,
        		HONGTAOK   = 5039,
        		HEITAO1    = 5040,
        		HEITAO2    = 5041,
        		HEITAO3    = 5042,
        		HEITAO4    = 5043,
        		HEITAO5    = 5044,
        		HEITAO6    = 5045,
        		HEITAO7    = 5046,
        		HEITAO8    = 5047,
        		HEITAO9    = 5048,
        		HEITAO10   = 5049,
        		HEITAOJ    = 5050,
        		HEITAOQ    = 5051,
        		HEITAOK    = 5052,
        		XIAOWANG   = 5053,
        		DAWANG     = 5054,
        		SHUIJING   = 5055,
        		HUANGJIN   = 5056,
          	
          	
          	GOLD_MOONCATE_TZ          = 100020,  --3种图纸
          	SILVER_MOONCATE_TZ        = 100021,
          	BRONZE_MOONCATE_TZ        = 100022,
          	
          	AT_TZ1                    = 100105, --奥拓1
          	AT_TZ2                    = 100106, --奥拓2
          	AT_TZ3									  =	100107, --奥拓3图纸
						XTL_TZ								    =	100108, --雪铁龙图纸
						JKC_tZ								    =	100109, --甲壳虫图纸
						MSLD_TZ								    =	100110, --玛莎拉蒂图纸
						FLL_TZ								    =	100111, --法拉利图纸
						LBJN_TZ								    =	100112, --兰博基尼图纸
						BJD_TZ								    =	100113, --布加迪威龙图纸
						BJDHJ_TZ							    =	100114, --布加迪威行百年黄金纪念图纸
						SMC_TZ								    =	100115, --神秘车图纸
						YONGJIU_TZ                = 100116,
						FENGHUANG_TZ              = 100117,
						ROSE_BOX1_TZ              = 100118,--情人节活动图纸1
						ROSE_BOX2_TZ              = 100119,--情人节活动图纸2

						BFDKH                     = 200001, --缤纷道具盒子
						KINGCAR_BOX1              = 200002, --普通冠军箱
						KINGCAR_BOX2              = 200003, --豪车冠军箱
						PAY_GIVE_BOX1             = 200004, --充值送铜宝箱
						PAY_GIVE_BOX2             = 200005, --充值送银宝箱
						PAY_GIVE_BOX3             = 200006, --充值送金宝箱
						MORI_QIEGAO               = 200007, --末日切糕
						NEWYEAR_WATER             = 200008, --新年泉水
						NEWYEAR_REDBAG            = 200009, --新年红包
						NEWYEAR_GEMBOX            = 200010, --新年宝石袋
						NEWYEAR_ITEMBOX           = 200011, --新年道具箱
						NEWYEAR_SCROLL            = 200012, --新年卷轴
						NEWYEAR_CARKEY            = 200013, --新年车钥匙
						LOVER_DAY_ROSE            = 200014, --浪漫玫瑰礼盒
						LOVER_DAY_DIAMOND         = 200015, --奢华晶钻礼盒
						pay_car_1                 = 200016, --白银钥匙
						pay_car_2                 = 200017, --黄金钥匙						
						pay_car_3                 = 200018, --水晶钥匙
						pay_box_1                 = 200019, --普通配件箱
						pay_box_2                 = 200020, --白银配件箱
						pay_box_3                 = 200021, --黄金配件箱 
						daojuka_3                 = 200022, --百变道具卡						
						nanjue_box                = 200023, --男爵宝箱
						zijue_box                 = 200024, --子爵宝箱
						bojue_box                 = 200025, --伯爵宝箱
						houjue_box                = 200026, --侯爵宝箱
						MEDAL                     = 200027,  --成长勋章
						pay_box_4                 = 200028, --普通配件箱
						pay_box_5                 = 200029, --白银配件箱
						pay_box_6                 = 200030, --黄金配件箱 
        },

        SQL = _S
        {
            --获取道具数量
            get_props_count = "select total_count from user_props_info where props_type=%d and user_id=%d",
            --查询道具数量
            select_props_count = "select props_type, total_count from user_props_info where user_id=%d;commit;",
            --更新道具数量，并返回最新道具数量；user_id, props_id, props_count
            update_props_count = "call sp_update_gameprops_count(%d, %d, %d);",

            --日志
            add_props_log = "insert into log_user_props(user_id, do_type, props_id, add_count, sys_time) values(%d, %d, %d, %d, NOW())",

            give_props_log = "insert into log_user_give_props(from_user_id, to_user_id, props_id, add_count, sys_time) values(%d, %d, %d, %d, NOW())",
        },
        
        

				REWARDMSG_ITEM_NAME = {
          [5012] = "甲壳虫",
          [5018] = "雪铁龙",
          [5021] = "玛莎拉蒂",
          [100110] = "玛莎拉蒂图纸",
          [100111] = "法拉利图纸",
          [5024] = "法拉利",										
          [5026] = "兰博基尼",
          [100112] = "兰博基尼图纸",			
				},
				BOX_NAME = {
					[200004] = "铜宝箱",
					[200005] = "银宝箱",
					[200006] = "金宝箱",
				},
				
			--每日获得的宝箱东西数量
        already_get = {
        	[200016]={
        		0, --奥拓*2
        		0, --雪铁龙
        		0, --甲壳虫
        		0, --宝马Z4
        		0, --奥迪A8
        	},
        	[200017]={
        		0, --甲壳虫
        		0, --宝马Z4
        		0, --奥迪A8
        		0, --玛莎拉蒂
        		0, --法拉利
        	},
        	[200018]={
        		0, --宝马Z4
        		0, --奥迪A8
        		0, --玛莎拉蒂
        		0, --法拉利
        		0, --兰博基尼
        	},
        },
				
	}
end



--根据道具ID，取得道具数量
--[[
    props_id:
    user_info:
    complete_callback_func: 回调函数，返回道具数量
--]]
function tex_gamepropslib.get_props_count_by_id(props_id, user_info, complete_callback_func)
    if(complete_callback_func == nil) then 
        --TraceError("tex_gamepropslib.get_props_count_by_id() -> 回调函数不能为空")
        return 
    end

    --玩家道具列表
    local propslist = tex_gamepropslib.get_props_list(user_info)
    local props_count = 0

    local set_props_count_to_user_info = function(count)
        if(propslist[props_id] == nil) then
            if(tex_gamepropslib.vaild_props_id(props_id) == 1) then
                table.insert(user_info.propslist, props_id, count)
            end
        else
            user_info.propslist[props_id] = count
        end
        --执行回调函数
        complete_callback_func(count or 0)
    end
    
    if(user_info.propslist==nil) then
        --内存道具为空，则查数据库
        local sql = string.format(tex_gamepropslib.SQL.get_props_count, props_id, user_info.userId);
        dblib.execute(sql, 
                    function(dt)
                       if (dt and #dt > 0) then
                            props_count = dt[1].total_count or 0
                            --读取成功，并且ID有效，放到内存中
                            set_props_count_to_user_info(props_count)
                       else
                            set_props_count_to_user_info(props_count)
                       end
                    end)
    else
        props_count = propslist[props_id];
        complete_callback_func(props_count or 0)
    end
end

--根据道具ID，设置道具数量
--[[
    props_id:
    add_count:道具增加或减少的值
    user_info:
    complete_callback_func:
]]--
function tex_gamepropslib.set_props_count_by_id(props_id, add_count, user_info, complete_callback_func, do_type, failed_callback_func)
    --检查道具ID是否有效
    if(tex_gamepropslib.vaild_props_id(props_id) == 0) then 
  		if(failed_callback_func ~= nil) then 
  			failed_callback_func() 
  		end
    	return 
    end
    if(do_type == nil) then
        do_type = 0;
    end

    dblib.execute(string.format(tex_gamepropslib.SQL.add_props_log, user_info.userId, do_type, props_id, add_count));

    --更新到数据库   
    local sql = string.format(tex_gamepropslib.SQL.update_props_count, user_info.userId, props_id, add_count);
        dblib.execute(sql, 
                 function(dt) 
                 	local props_count = 0
                    if (dt and #dt > 0) then
                        props_count = dt[1].total_count or 0
                        --玩家道具列表
                        local propslist = tex_gamepropslib.get_props_list(user_info)
                        --更新成功，放到内存中
                        if(propslist[props_id] == nil) then
                            table.insert(user_info.propslist, props_id, props_count)
                        else
                            user_info.propslist[props_id] = props_count
                        end
												eventmgr:dispatchEvent(Event("bag_change_event", {user_id = user_info.userId}));
                        
                    end  
                    --执行回调函数
                    if(complete_callback_func ~= nil) then complete_callback_func(props_count) end  
                 end, user_info.userId)
end

--加道具的新接口，以后尽量用这个，可以在玩家不在线时也加道具
function tex_gamepropslib.add_tools(props_id, add_count, user_id, complete_callback_func)
    --检查道具ID是否有效
    if(tex_gamepropslib.vaild_props_id(props_id) == 0) then return end
	local user_info = usermgr.GetUserById(user_id)
    --更新到数据库   
    local sql = string.format(tex_gamepropslib.SQL.update_props_count, user_id, props_id, add_count);
        dblib.execute(sql, 
                 function(dt) 
                 	local props_count = 0
                    if (dt and #dt > 0 and user_info ~= nil) then
                    	
                        props_count = dt[1].total_count or 0
                        --玩家道具列表
                        local propslist = tex_gamepropslib.get_props_list(user_info)
                        --更新成功，放到内存中
                        if(propslist[props_id] == nil) then
                            table.insert(user_info.propslist, props_id, props_count)
                        else
                            user_info.propslist[props_id] = props_count
                        end
												eventmgr:dispatchEvent(Event("bag_change_event", {user_id = user_info.userId}));
                        
                    end
                    --执行回调函数
                    if(complete_callback_func ~= nil) then complete_callback_func(props_count) end
                 end, user_id)
end

--检查道具ID是否有效：0，无效；1，有效
function tex_gamepropslib.vaild_props_id(props_id)
    local is_valid = 0
    for k, v in pairs(tex_gamepropslib.PROPS_ID) do
        if(props_id == v) then
            is_valid = 1
            break;
        end
    end
    return is_valid
end


--获取玩家内存中的道具列表
function tex_gamepropslib.get_props_list(user_info)
    if(user_info.propslist == nil) then
        user_info.propslist = {}
    end
    return user_info.propslist
end


--收到“请求道具列表数据”信息
function tex_gamepropslib.on_recv_get_props(buf)
		local get_count = function(tab)
			local i = 0
			for k, v in pairs(tab) do
				i = i + 1
			end
			return i
	  end
	  
    local user_info = userlist[getuserid(buf)]
    if not user_info then return end
    --向客户端发送道具列表
    local send_to_func = function(temp_propslist)
        netlib.send(
                function(buf)
                    buf:writeString("TXPROPS")      --给客户端协议，道具列表
                    buf:writeInt(get_count(temp_propslist));
                    for k, v in pairs(temp_propslist) do
                        buf:writeInt(k)     --  ID
                        buf:writeInt(v)     --  数量
                    end
                end,user_info.ip,user_info.port)
    end
    	--TraceError("收到“请求道具列表数据”信息1111111111111111111")
    local propslist = tex_gamepropslib.get_props_list(user_info)
    --内存中没有道具，则向数据库读取
    if(#propslist < tex_gamepropslib.PROPS_LEN) then
    	
        local sql = string.format(tex_gamepropslib.SQL.select_props_count, user_info.userId);
        dblib.execute(sql, 
                    function(dt)
                        if (dt and #dt >= 0) then
                            --读到数据，放到内存中
                            for i = 1, #dt do
                                local temp_id = dt[i].props_type
                                if(tex_gamepropslib.vaild_props_id(temp_id) == 1) then
                                    table.insert(user_info.propslist, temp_id, dt[i].total_count)
                                end
                            end
                        end
                        --根据定义中的道具ID，判断道具
                        for k, v in pairs(tex_gamepropslib.PROPS_ID) do
                            --如果数据库表中道具不全，则置该道具数量为0
                            
                            if(user_info.propslist[v] == nil) then
                                table.insert(user_info.propslist, v, 0)
                            end
                        end
                        --向客户端发送道具列表
                        send_to_func(user_info.propslist)
                    end)
    else
        --向客户端发送道具列表
        send_to_func(propslist)
    end
end

--收到“请求赠送道具”信息
function tex_gamepropslib.on_recv_togive_props(buf)
    local user_info = userlist[getuserid(buf)]; 
    if not user_info then return end;

	local props_id = buf:readInt()
    local togive_props_count = buf:readInt()   --赠送数量，留着，暂时不用
	local tosites_len = buf:readInt()
	local tosites = {}
	--翅膀是绑定的不能交易
	if props_id >= 27 and props_id <= 35 then return end
	for i = 1, tosites_len do
		tosites[i] = buf:readByte()
    end

    if (togive_props_count < 1) then
        TraceError("送赠送道具 num < 0  "..user_info.userId.."   "..user_info.ip)
	    return
    end
    
    if (togive_props_count > 1 and tosites_len ~= 1) or (togive_props_count ~= 1 and tosites_len > 1) or (tosites_len < 1) or (togive_props_count < 1) then
   	    TraceError("赠送人和赠送道具数量大于1，错误流程")
   	    return
    end
    
	--获取道具数量后执行这个函数
    local complete_callback_func = function(props_count)
        if(props_count == nil or props_count < tosites_len) or props_count < togive_props_count then
                tex_gamepropslib.net_send_error_result(user_info, 9)
                return;
            end

            local last_toprops_time = user_info.last_toprops_time or 0
            if(os.clock()*1000 - last_toprops_time < 800) then
                --TraceError("赠送道具，点击得太快了")
                return
            end
            user_info.last_toprops_time = os.clock()*1000
        	
        	--记录赠送失败的玩家
        	local failedusers = {}

          local retcode = 0
        	for i = 1, #tosites do
        		local touser_info = nil
        		local tosite = tosites[i]
        		if(tosite and tosite ~= 0) then
        			if(user_info.desk and user_info.site) then
        				touser_info = deskmgr.getsiteuser(user_info.desk, tosite)
        			else
        				--TraceError("观战的时候给人送道具？")
        			end
                else
        			--送给自己
        			touser_info = user_info
        		end
        		if touser_info then
                    --TraceError("user_info:"..user_info.userId.."  touser_info:"..touser_info.userId)
                    if(user_info.userId == touser_info.userId) then
                        --TraceError("不会吧，自己给自己送道具？")
        		    else
        					retcode = do_togive_props(user_info, touser_info, props_id, togive_props_count)     		
                        if(retcode ~= 1) then
        					table.insert(failedusers, {site = touserinfo.site or 0, retcode = retcode})
        				end
                    end
                    
        		end
        	end
        	--只有在游戏中才有批量送礼失败的情况
        	if(user_info.desk and user_info.site) then
        		tex_gamepropslib.net_send_togive_props_result(user_info, failedusers)
        	end
    end
	
    tex_gamepropslib.get_props_count_by_id(props_id, user_info, complete_callback_func)

end

--执行赠送道具
--返回:1=成功 5=道具不足 6=赠送人站起来了
function do_togive_props(user_info, touser_info, props_id, togive_props_count)
	if not user_info or not touser_info then
		--TraceError("谁送给谁啊？")
		return 0
	end
    --TraceError("do_togive_props user_info.userId:"..user_info.userId.."  touser_info:"..touser_info.userId)
	local retcode = 0
	--只有在游戏中才能给人赠送道具
	if(user_info.desk and user_info.site and touser_info.site) then
		local deskdata = deskmgr.getdeskdata(user_info.desk)
		local sitedata = deskmgr.getsitedata(user_info.desk, user_info.site)
		local tosite = touser_info.site
	
		local tositedata = deskmgr.getsitedata(user_info.desk, tosite)
		
		local props_num = user_info.propslist[props_id] or 0;
        if(props_num < togive_props_count) then
            retcode = 5
        else
            retcode = 1
		end
	else
		--TraceError("不坐下不能赠送啦")
        retcode = 6
    end

    local user_callback_func = function(temp_props_count)
        --赠送成功，通知客户端，更新道具数量TIPS
        tex_gamepropslib.net_send_refresh_props_count(user_info, props_id, temp_props_count)
        --广播播放送礼物动画
        local nolimit_ture = 0;
				for _,v in pairs (config_for_yunying.cannot_puton_gift) do
					if v == props_id then
						nolimit_ture = 1;
						break
					end
				end
				--if nolimit_ture ~= 1 then
                    tex_gamepropslib.net_broadcast_togive_props(user_info.desk, user_info.site, touser_info.site, props_id, 2,togive_props_count)
                    --[[
                else
    			tex_gamepropslib.net_broadcast_togive_props(user_info.desk, user_info.site, touser_info.site, props_id, 7,togive_props_count)
                --]]
                --end
    end

    local touser_callback_func = function(temp_props_count)
        --赠送成功，通知客户端，更新道具数量TIPS
        tex_gamepropslib.net_send_refresh_props_count(touser_info, props_id, temp_props_count)
         --更新赠送玩家的道具数量
         --更新成功了被赠送玩家，再减少自己的数量
        tex_gamepropslib.set_props_count_by_id(props_id, -1*togive_props_count, user_info, user_callback_func, 2)
    end

    if(retcode == 1)then	   
        --更新被赠送玩家的道具数量
        tex_gamepropslib.set_props_count_by_id(props_id, togive_props_count, touser_info, touser_callback_func, 3)


        local user_id = user_info.userId;
        if(duokai_lib ~= nil and duokai_lib.is_sub_user(user_id) == 1) then
            user_id = duokai_lib.get_parent_id(user_id);
        end
        dblib.execute(string.format(tex_gamepropslib.SQL.give_props_log, user_id, touser_info.userId, props_id, togive_props_count));
    end

    return retcode
end

--播放送礼物动画
function tex_gamepropslib.net_broadcast_togive_props(deskno, fromsite, tositeno, props_id, typenumber, props_number)
    net_broadcast_give_gift(deskno, fromsite, tositeno, props_id, typenumber, props_number);
end

--赠送道具结果
function tex_gamepropslib.net_send_togive_props_result(user_info, failedusers)
    if(not user_info or not failedusers) then
        return
    end
    netlib.send(
        function(buf)
            buf:writeString("TXBGFF")
            buf:writeInt(#failedusers)
            for i = 1, #failedusers do
                buf:writeByte(failedusers[i].site)	
                buf:writeInt(failedusers[i].retcode) --1=成功赠送 5=道具不足 6=赠送人站起来了 0=其他异常
            end
        end
    , user_info.ip, user_info.port)
end

function tex_gamepropslib.net_send_error_result(user_info, retcode)
    if not user_info then return end
    netlib.send(
		function(buf)
			buf:writeString("TXBGFD")
			buf:writeByte(retcode)	--9=道具不足 
		end
	, user_info.ip, user_info.port, borcastTarget.playingOnly)
end


--通知客户端，更新道具数量TIPS
function tex_gamepropslib.net_send_refresh_props_count(user_info, props_id, props_count)
    netlib.send(
        function(buf)
            buf:writeString("TXREDJNUM")
            buf:writeInt(props_id)
            buf:writeInt(props_count)
        end
    , user_info.ip, user_info.port)
end

--用户登录初始化道具
function tex_gamepropslib.on_after_user_login(e)

    local user_info = e.data.userinfo;
	if(user_info==nil)then return end;
	
     
    if(user_info.propslist == nil or #user_info.propslist==0) then
    	user_info.propslist={}
    	
    	 for i = 1,tex_gamepropslib.PROPS_LEN do
	       	table.insert(user_info.propslist, i, 0)
	     end
	     
        --内存道具为空，则查数据库
        local sql="select props_type,total_count from user_props_info where user_id=%d order by props_type"
		sql=string.format(sql,user_info.userId)
        dblib.execute(sql, 
                    function(dt)
                       if (dt and #dt > 0) then
                       
                            for i = 1,#dt do
                                local v = dt[i]["props_type"]
                       		
                            	user_info.propslist[v]=dt[i]["total_count"]
                            end
                            eventmgr:dispatchEvent(Event("after_get_props_list", {user_id = user_info.userId}));
                       end
                    end)
    
    end
	
	
end

--客户端请求打开宝箱
function tex_gamepropslib.on_recv_open_box(buf)
	local user_info = userlist[getuserid(buf)]
	if user_info == nil then return end
	local item_id = buf:readInt()
	if tonumber(groupinfo.groupid) ~= 18001 then return end
	
	--判断是不是宝箱，是宝箱调用开宝箱接口
	for k,_ in pairs (config_for_yunying.BOX_PORBABILITY_LIST) do
		if item_id == k then
			tex_gamepropslib.open_box(user_info, item_id)
			return
		end
	end
	
	--如果不是缤纷道具和则发消息，各个模块对应处理
  eventmgr:dispatchEvent(Event("use_item_event", {user_id = user_info.userId, item_id=item_id}));
  
	--判断是不是末日切糕
	if item_id == tex_gamepropslib.PROPS_ID.MORI_QIEGAO then
		if end_world and end_world.check_time() == 1 then
			end_world.use_qiegao(user_info, item_id)
		else
			--todoreturn活动过期。。
			netlib.send(function(buf)
				buf:writeString("TXOPENBOX")
				buf:writeByte(-1)									
				buf:writeInt(0)
				buf:writeByte(0)
				buf:writeInt(0)
				buf:writeInt(0)	
			end, user_info.ip, user_info.port)
		end
	end
	--判断是不是春节泉水
	if item_id == tex_gamepropslib.PROPS_ID.NEWYEAR_WATER then
		if new_year and new_year.check_time() == 1 then
			new_year.use_water(user_info)
		else
			netlib.send(function(buf)
				buf:writeString("TXOPENBOX")
				buf:writeByte(-1)									
				buf:writeInt(0)
				buf:writeByte(0)
				buf:writeInt(0)
				buf:writeInt(0)	
			end, user_info.ip, user_info.port)
		end
	end
	--使用春节道具
	if item_id >= tex_gamepropslib.PROPS_ID.NEWYEAR_REDBAG and item_id <= tex_gamepropslib.PROPS_ID.NEWYEAR_CARKEY then
		if new_year then
			new_year.use_box(user_info, item_id)
		else
			netlib.send(function(buf)
				buf:writeString("TXOPENBOX")
				buf:writeByte(-1)									
				buf:writeInt(0)
				buf:writeByte(0)
				buf:writeInt(0)
				buf:writeInt(0)	
			end, user_info.ip, user_info.port)
		end
	end
end

function tex_gamepropslib.open_box(user_info, item_id)
	--调用背包接口查找宝箱，有宝箱的话就宝箱数量-1
	local set_count_box = function(nCount)
		if nCount >= 1 then
				if gift_getgiftcount(user_info) >= 100 then
					net_send_gift_faild(user_info, 5)		--告诉客户端礼物已满
					user_info.update_open_box_update_db = 0
					return
				end	
				--随机奖励
				local call_back = function ()
					--解锁数据库操作
					user_info.update_open_box_update_db = 0
					local find = 1;
					local add = 0;
					local rand = math.random(1, 10000);
					for i = 1, #config_for_yunying.BOX_PORBABILITY_LIST[item_id] do
								add = add + config_for_yunying.BOX_PORBABILITY_LIST[item_id][i];
								if add >= rand then
										find = i;
									break;
								end
					end
					if config_for_yunying.BOX_ITEM_GIFT_ID[item_id][find][4] and 
					   tex_gamepropslib.already_get[item_id] and
					   tex_gamepropslib.already_get[item_id][find] and
					   tex_gamepropslib.already_get[item_id][find] >= config_for_yunying.BOX_ITEM_GIFT_ID[item_id][find][4] then
					    
					    find =1 
					    --TraceError("超出上限，强制奥拓")
					end  
					--调用背包接口给道具，发送客户端协议
				    if find > 0 then
						local type_id          = config_for_yunying.BOX_ITEM_GIFT_ID[item_id][find][1]
						local item_gift_id     = config_for_yunying.BOX_ITEM_GIFT_ID[item_id][find][2]
						local item_number      = config_for_yunying.BOX_ITEM_GIFT_ID[item_id][find][3]
						if type_id == 1 or type_id == 7 then	
							tex_gamepropslib.set_props_count_by_id(item_gift_id, item_number, user_info, nil)
						elseif type_id == 2 then
							--加礼物
							gift_addgiftitem(user_info, item_gift_id, user_info.userId, user_info.nick, 0)
						elseif type_id == 3 then
							--加汽车
							for i = 1,item_number do 
							  car_match_db_lib.add_car(user_info.userId, item_gift_id, 0);
							end
						elseif type_id == 4 then
							--加赠票
							daxiao_adapt_lib.add_exyinpiao(user_info.userId,item_number,0,3)
							--daxiao_lib.add_yinpiao(user_info.userId,buy_yinpiao*temp_flag,0,buy_type)	
						end
						
						if tex_gamepropslib.already_get[item_id] and tex_gamepropslib.already_get[item_id][find] then
						  tex_gamepropslib.already_get[item_id][find] = tex_gamepropslib.already_get[item_id][find] + item_number
						end
						
						--记录开盒子获得的道具
						tex_gamepropslib.record_gift_box_log(user_info,item_gift_id,type_id,item_number,item_id)
						eventmgr:dispatchEvent(Event("bag_open_box_event", {user_id = user_info.userId, box_id=item_id, type_id=type_id, item_gift_id= item_gift_id, item_number=item_number}));
						netlib.send(function(buf)
							buf:writeString("TXOPENBOX")
									buf:writeByte(1)									
									buf:writeInt(item_id)
									buf:writeByte(type_id)
									buf:writeInt(item_gift_id)
									buf:writeInt(item_number)	
						end, user_info.ip, user_info.port)
						
						--发广播消息
						local match_name = "普通"
						if item_id == 200003 then
							match_name = "名车"
						end

						local msg = "从%s赛冠军宝箱获得了%s，大家一起来恭喜他吧！"
						
						if (item_id == 200002 or item_id == 200003) and tex_gamepropslib.REWARDMSG_ITEM_NAME[item_gift_id] ~= nil then  
								msg = string.format(msg, match_name, tex_gamepropslib.REWARDMSG_ITEM_NAME[item_gift_id])
								tex_speakerlib.send_sys_msg( _U("恭喜")..user_info.nick.._U(msg))
						end
						
						msg = "从%s中获得%s！"
						if (item_id == 200004 or item_id == 200005 or item_id == 200006) and type_id == 3 then  
								msg = string.format(msg, tex_gamepropslib.BOX_NAME[item_id], car_match_lib.CFG_CAR_INFO[item_gift_id]["name"])
								tex_speakerlib.send_sys_msg( _U("恭喜")..user_info.nick.._U(msg))
						end
					end
				end  --end call_back			
				tex_gamepropslib.set_props_count_by_id(item_id, -1, user_info, call_back)
		else
			user_info.update_open_box_update_db = 0
			return
		end
	end
	
	--如果数据库锁定则返回
	if user_info.update_open_box_update_db == 1 then
		--[[timelib.createplan(function()
			user_info.update_open_box_update_db = 0
		end, 10)--]]
		return
	end
	--锁定数据库
	user_info.update_open_box_update_db = 1
	tex_gamepropslib.get_props_count_by_id(item_id, user_info, set_count_box)	
	
end

--商城购买调用，判断是不是合成图纸 和 或是 缤纷盒子可售道具
function tex_gamepropslib.is_gameprops(user_info, to_user_info, giftid, gift_num)
	if (not user_info) or (not to_user_info) or (not giftid) then
		return 0;
	end
	
	if giftid > 100000 and giftid < 200000 then

		--增加背包里的图纸
		tex_gamepropslib.set_props_count_by_id(giftid, gift_num or 1, to_user_info, nil)

		--记录购买图纸log
		if hecheng_db_lib then
			hecheng_db_lib.record_tz_change(to_user_info,giftid,1)
		end
		return 1;
	end
	if giftid > 200000  or giftid < 998 then
		--增加背包里的盒子	
		tex_gamepropslib.set_props_count_by_id(giftid, gift_num or 1, to_user_info, nil)
		--记录购买图纸log
		--hecheng_db_lib.record_tz_change(user_info,giftid,1);
		tex_gamepropslib.record_gift_box_log(to_user_info,giftid,-1,gift_num)	
		return 2
	end
	return 0;	
end
--判断一个id是物品还是礼物(粗略的判断一下是礼物还是道具)囧囧囧囧囧囧囧囧囧囧囧囧囧囧囧
function tex_gamepropslib.get_type_pro_gift(giftid)
  if giftid > 100000  or giftid < 998 then
    return 1
  else
    return 2
  end
end

function tex_gamepropslib.record_gift_box_log(user_info,item_id,type_id,item_number,box_id)
		if not user_info or not item_id  then 
			return
		end
		if not type_id then type_id = 1 end
		if not item_number then item_number = 1 end
		if not box_id then box_id = 0 end
		local user_id = user_info.user_id
    local sqltemple = "INSERT INTO log_gift_box(user_id, item_id, type_id, item_number, box_id, sys_time)value(%d, %d, %d, %d, %d, now()) ";
    sqltemple = string.format(sqltemple, user_info.userId, item_id, type_id, item_number, box_id);
    dblib.execute(sqltemple);
end

function tex_gamepropslib.timer(e)
	local current_time = os.time()
	--每天零点清一下之前一天的数据
	if tex_gamepropslib.clear_data_time == nil or  
	tex_gamepropslib.is_today(tex_gamepropslib.clear_data_time,current_time) == 0 then
		for k1,v1 in pairs (tex_gamepropslib.already_get) do
		  for k2,v2 in pairs(v1) do
		    tex_gamepropslib.already_get[k1][k2] = 0
		  end
		end
		tex_gamepropslib.clear_data_time=current_time
	end

end


--是不是在同一天
function tex_gamepropslib.is_today(time1,time2)
	if time1==nil or time2==nil or time1=="" or time2=="" then return 0 end
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
	if tonumber(year1)<2012 or tonumber(year2)<2012 then 
		return 0 
	end
	if time1~=time2 then
		return 0
	end
	return 1
end


--命令列表
cmd_gameprops_handler = 
{
	["TXPROPS"] = tex_gamepropslib.on_recv_get_props, --收到“请求道具列表数据”信息
    ["TXTOUDJ"] = tex_gamepropslib.on_recv_togive_props, --收到“请求赠送道具”信息
    ["TXOPENBOX"] = tex_gamepropslib.on_recv_open_box,  --请求打开缤纷道具盒
}

--加载插件的回调
for k, v in pairs(cmd_gameprops_handler) do 
	cmdHandler_addons[k] = v
end


eventmgr:addEventListener("timer_minute", tex_gamepropslib.timer)
eventmgr:addEventListener("h2_on_user_login", tex_gamepropslib.on_after_user_login);


