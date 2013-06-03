TraceError("init choujiang_tools_lib...")
if not choujiang_tools_lib then
    choujiang_tools_lib = _S
    {
		do_chuojiang=NULL_FUNC,
		do_fajiang=NULL_FUNC,
		onRecvDakaiZhuanpan=NULL_FUNC,
		onRecvKaishiChoujiang=NULL_FUNC,
    }   
 end

--抽奖
function choujiang_tools_lib.do_chuojiang(user_info)
	local user_info = userlist[getuserid(buf)]; 
    if not user_info then return end;
    local do_cj=function(userinfo,choujiang_type)
    	local sql = "call sp_get_random_spring_gift(%d,'%s',%d)"
	    sql = string.format(sql, userinfo.userId,gamepkg.name,choujiang_type)
	    dblib.execute(sql, 
	         function(dt)
	             if (dt and #dt > 0) then
	                 local jiangpin = dt[1]["gift_id"]                 
	                  choujiang_tools_lib.do_fajiang(userinfo,jiangpin)
	                  
	        		 --通知获奖结果
	            	 netlib.send(
	                 function(buf)
	                     buf:writeString("TXKSCJ")
	                     buf:writeInt(task_huodong_lib.user_list[user_id].jiangjuan or 0)  
	                     buf:writeInt(jiangpin)  --奖卷编号
	                 end,userinfo.ip,userinfo.port)
	             end
	         end)
    end
    
    --抽一次奖要用多少奖卷
    local cj_area,use_jiang_juan = choujiang_lib.g_get_user_reward_area(user_info.userId)
    
    local ret = task_huodong_lib.add_jiang_juan(user_info, -1*use_jiang_juan)


    if (ret == 0) then
        TraceError("奖券不够了，无法抽奖")
        return    
    end
    
 	if (gamepkg.name ~= "tex") then
		bag.get_all_item_info(user_info, function(items)
            local check_items = {[4]=1};--检查小喇叭是不 是以前有
            local check_space = 0;
            local ret = 0;
            --背包检查
            for k, v in pairs(check_items) do
                check_space = bag.check_space(items, {[k] = v});                
                if(check_space ~= 1) then--背包已满
                	--通知获奖结果
	            	 netlib.send(
	                 function(buf)
	                     buf:writeString("TXKSCJ")
	                     buf:writeInt(0)  
	                     buf:writeInt(0)  --背包满了，发奖失败
	                 end,userinfo.ip,userinfo.port)
                    return false;
                end
            end   
            TraceError("qp")
    		do_cj(user_info,choujiang_type);
	   		
	 	end);
	else
		 TraceError("tex")
		do_cj(user_info,choujiang_type);
	end 
 	

end



--棋牌的奖从1到5000
--德州的奖从5001到10000
function choujiang_tools_lib.do_fajiang(user_info,jiangpin)
    --棋牌和德州的奖品都是从1开始配，这样不容易出错，但发奖时给德州的ID加5000，这样好区分代码
	local msg=""
	local nick_name=user_info.nick
	jiangpin=tonumber(jiangpin)
    if (gamepkg.name ~= "tex") then
        --棋牌发奖
        if(jiangpin == 1)then           --低矿
            --加荣誉翻倍卡
            viploginlib.AddBuffToUser(user_info,user_info,1); 	
        elseif(jiangpin == 2)then
            --声望翻倍卡
            viploginlib.AddBuffToUser(user_info,user_info,2); 	
        elseif(jiangpin == 3)then
            --小嗽叭
	   		bag.add_item (user_info,{item_id = 4, item_num = 1},nil,bag.log_type.MD33_HOUDONG);
        elseif(jiangpin == 4)then
	    	--200金币
            usermgr.addgold(user_info.userId, 200, 0, tSqlTemplete.goldType.cj_HOUDONG, -1);
        elseif(jiangpin == 5)then
	    	--1000金币
	    	usermgr.addgold(user_info.userId, 1000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1);            
        elseif(jiangpin == 6)then
	    	--5000金币
	    	usermgr.addgold(user_info.userId, 5000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1);            
        elseif(jiangpin == 7)then
	    	--10000金币
	   		usermgr.addgold(user_info.userId, 10000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1); 
        elseif(jiangpin == 8)then
	    	--50000金币
	    	usermgr.addgold(user_info.userId, 50000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1);
	    	msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到50000金币 ")
	    	tools.SendBufToUserSvr("", "SPBC", "", "", msg) 
        elseif(jiangpin == 11)then
            --加荣誉翻倍卡
            viploginlib.AddBuffToUser(user_info,user_info,1); 		
        elseif(jiangpin == 12)then
            --声望翻倍卡
             viploginlib.AddBuffToUser(user_info,user_info,2); 	
        elseif(jiangpin == 13)then
            --小嗽叭
	    	bag.add_item (user_info,{item_id = 4, item_num = 1},nil,bag.log_type.MD33_HOUDONG);
        elseif(jiangpin == 14)then
             --1000金币
	    	usermgr.addgold(user_info.userId, 1000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1);            
        elseif(jiangpin == 15)then
            --10000金币
	    	usermgr.addgold(user_info.userId, 10000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1);            
        elseif(jiangpin == 16)then
            --50000金币
	    	usermgr.addgold(user_info.userId, 50000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1); 
	        msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到50000金币 ")
	    	tools.SendBufToUserSvr("", "SPBC", "", "", msg)  
        elseif(jiangpin == 17)then
	    	--10000金币
	   		usermgr.addgold(user_info.userId, 100000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1);  
        elseif(jiangpin == 18)then
	   		--500000金币
	    	usermgr.addgold(user_info.userId, 500000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1);  
	        msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到500000金币")
	    	tools.SendBufToUserSvr("", "SPBC", "", "", msg) 
        elseif(jiangpin == 21)then--搞矿
            --小嗽叭
	    	bag.add_item (user_info,{item_id = 4, item_num = 3},nil,bag.log_type.MD33_HOUDONG);
       elseif(jiangpin == 22)then
             --5000金币
	    	usermgr.addgold(user_info.userId, 5000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1);   
        elseif(jiangpin == 23)then            
	    	--10000金币
	    	usermgr.addgold(user_info.userId, 10000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1);  
        elseif(jiangpin == 24)then
	    	--50000金币
	    	usermgr.addgold(user_info.userId, 50000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1);  
	        msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到50000金币")
	    	tools.SendBufToUserSvr("", "SPBC", "", "", msg) 
        elseif(jiangpin == 25)then
	    	--100000金币
	    	usermgr.addgold(user_info.userId, 100000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1); 
	        msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到10万金币")
	    	tools.SendBufToUserSvr("", "SPBC", "", "", msg)  
        elseif(jiangpin == 26)then
	    	--1000000金币
	    	usermgr.addgold(user_info.userId, 1000000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1);  
	        msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到1百万金币")
	    	tools.SendBufToUserSvr("", "SPBC", "", "", msg)  
        elseif(jiangpin == 27)then
	    	--10000000金币
	    	usermgr.addgold(user_info.userId, 10000000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1); 
	        msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到1千万金币")
	    	tools.SendBufToUserSvr("", "SPBC", "", "", msg)  
        elseif(jiangpin == 28)then
	    	--100000000金币
	    	usermgr.addgold(user_info.userId, 100000000, 0, tSqlTemplete.goldType.cj_HOUDONG, -1); 
	    	msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到1亿金币")
	    	tools.SendBufToUserSvr("", "SPBC", "", "", msg)  
        end

    else

        jiangpin=jiangpin+5000
        --德州分发奖品
        if (jiangpin  == 5001) then
            --8888奥拓
            gift_addgiftitem(user_info,5013,user_info.userId,user_info.nick, false)  
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值8888奥拓 ")
	    	BroadcastMsg(msg);             
        elseif (jiangpin  == 5002) then
	    	--T卡
            tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 1, user_info);
        elseif (jiangpin  == 5003) then
            --1288筹码;
	    	usermgr.addgold(user_info.userId, 1288, 0, new_gold_type.CHOUJIANG, -1);
        elseif (jiangpin  == 5004) then
	    	--经验药水
            usermgr.addexp(user_info.userId, usermgr.getlevel(user_info), 10, g_ExpType.jhm_huodong, groupinfo.groupid);
        elseif (jiangpin  == 5005) then
	    	--小喇叭
            tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, user_info);
        elseif (jiangpin  == 5006) then
	    	--关公
	    	gift_addgiftitem(user_info,4023,user_info.userId,user_info.nick, false)	
        elseif (jiangpin  == 5007) then
	    	--老神仙	 
	    	gift_addgiftitem(user_info,4024,user_info.userId,user_info.nick, false)		
        elseif (jiangpin  == 5008) then
	    	--葫芦仙	 
	    	gift_addgiftitem(user_info,4025,user_info.userId,user_info.nick, false)	
        elseif (jiangpin  == 5009) then
	    	--LV包	 
	    	gift_addgiftitem(user_info,5020,user_info.userId,user_info.nick, false)	
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到LV包 ")
	    	BroadcastMsg(msg); 		    		
        elseif (jiangpin  == 5010) then
	    	--138万玛莎拉蒂 	
	    	gift_addgiftitem(user_info,5021,user_info.userId,user_info.nick, false)  
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值138万玛莎拉蒂 ")
	    	BroadcastMsg(msg); 		    	
        elseif (jiangpin  == 5011) then
	    	--1万蓝宝石
	    	gift_addgiftitem(user_info,5001,user_info.userId,user_info.nick, false)
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值1万蓝宝石 ")
	    	BroadcastMsg(msg); 	
        elseif (jiangpin  == 5012) then
	    	--2万QQ轿车
	    	gift_addgiftitem(user_info,5022,user_info.userId,user_info.nick, false)
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值2万QQ轿车 ")
	    	BroadcastMsg(msg); 	    	
        elseif (jiangpin  == 5021) then
	    	--T卡
            tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 1, user_info);
        elseif (jiangpin  == 5022) then
	    	--小喇叭
            tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 1, user_info);
        elseif (jiangpin  == 5023) then
            --关公
            gift_addgiftitem(user_info,4023,user_info.userId,user_info.nick, false)	
        elseif (jiangpin  == 5024) then
            --1000幸运筹码
            usermgr.addgold(user_info.userId, 1000, 0, new_gold_type.CHOUJIANG, -1);
        elseif (jiangpin  == 5025) then
            --5000幸运筹码
            usermgr.addgold(user_info.userId, 5000, 0, new_gold_type.CHOUJIANG, -1);
        elseif (jiangpin  == 5026) then
            --8888奥拓
            gift_addgiftitem(user_info,5013,user_info.userId,user_info.nick, false)  
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值8888奥拓 ")
	    	BroadcastMsg(msg);              
        elseif (jiangpin  == 5027) then
            --1万蓝宝石
            gift_addgiftitem(user_info,5001,user_info.userId,user_info.nick, false)
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值1万蓝宝石 ")
	    	BroadcastMsg(msg);               
        elseif (jiangpin  == 5028) then
            --2万QQ轿车
            gift_addgiftitem(user_info,5022,user_info.userId,user_info.nick, false)
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值2万QQ轿车 ")
	    	BroadcastMsg(msg);            
        elseif (jiangpin  == 5029) then
            --5万绿宝石
            gift_addgiftitem(user_info,5002,user_info.userId,user_info.nick, false)
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值5万绿宝石 ")
	    	BroadcastMsg(msg);	            
        elseif (jiangpin  == 5030) then
            --10万黄宝石	
            gift_addgiftitem(user_info,5003,user_info.userId,user_info.nick, false)
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值10万黄宝石 ")
	    	BroadcastMsg(msg);	
        elseif (jiangpin  == 5031) then
            --50万红宝石
            gift_addgiftitem(user_info,5004,user_info.userId,user_info.nick, false)
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值50万红宝石 ")
	    	BroadcastMsg(msg);	            
        elseif (jiangpin  == 5032) then
            --138万玛莎拉蒂 	
            gift_addgiftitem(user_info,5021,user_info.userId,user_info.nick, false)  
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值138万玛莎拉蒂 ")
	    	BroadcastMsg(msg);	
        elseif (jiangpin  == 5041) then
            --T人卡*2	
            tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, 2, user_info);
        elseif (jiangpin  == 5042) then
            --小喇叭*2
            tex_gamepropslib.set_props_count_by_id(tex_gamepropslib.PROPS_ID.SPEAKER_ID, 2, user_info);
        elseif (jiangpin  == 5043) then
            --5000幸运筹码
            usermgr.addgold(user_info.userId, 5000, 0, new_gold_type.CHOUJIANG, -1);
        elseif (jiangpin  == 5044) then
            --8888奥拓
            gift_addgiftitem(user_info,5013,user_info.userId,user_info.nick, false) 
             msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值8888奥拓")
	    	BroadcastMsg(msg);	             
        elseif (jiangpin  == 5045) then
            --1万蓝宝石
            gift_addgiftitem(user_info,5001,user_info.userId,user_info.nick, false)	
             msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值1万蓝宝石")
	    	BroadcastMsg(msg);	            
        elseif (jiangpin  == 5046) then
            --2万QQ轿车
            gift_addgiftitem(user_info,5022,user_info.userId,user_info.nick, false)
             msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值2万QQ轿车")
	    	BroadcastMsg(msg);	           
        elseif (jiangpin  == 5047) then
            --5万绿宝石
            gift_addgiftitem(user_info,5002,user_info.userId,user_info.nick, false)
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值5万绿宝石")
	    	BroadcastMsg(msg);	
        elseif (jiangpin  == 5048) then
            --10万黄宝石	
            gift_addgiftitem(user_info,5003,user_info.userId,user_info.nick, false)
            msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值10万黄宝石")
	    	BroadcastMsg(msg);	
        elseif (jiangpin  == 5049) then
            --50万红宝石
            gift_addgiftitem(user_info,5004,user_info.userId,user_info.nick, false)
	    	msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值50万红宝石")
	    	BroadcastMsg(msg);			
        elseif (jiangpin  == 5050) then
	    	--138万奔驰	
            gift_addgiftitem(user_info,5017,user_info.userId,user_info.nick, false)
	    	msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值138万奔驰	")
	    	BroadcastMsg(msg);	
        elseif (jiangpin  == 5051) then
	   		--588万法拉利
	   		gift_addgiftitem(user_info,5024,user_info.userId,user_info.nick, false)
	    	msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值588万法拉利")
	    	BroadcastMsg(msg);	   		
        elseif (jiangpin  == 5052) then
	    	--1888万兰博基尼
	    	gift_addgiftitem(user_info,5026,user_info.userId,user_info.nick, false)
	    	msg=_U("恭喜 ")..nick_name.._U("在每日任务嘉年华中抽奖得到价值1888万兰博基尼")
	    	BroadcastMsg(msg);
        end
     end
end



function choujiang_tools_lib.onRecvDakaiZhuanpan(buf)
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end;
	--local lottery_count = zhuanpan_zyszlib.get_lottery_count(userinfo)
	local lottery_count = task_huodong_lib.user_list[user_id].jiangjuan or 0
    local pai_xin = 0--zhuanpan_zyszlib.get_pai_xin(userinfo)
	netlib.send(
            function(buf)
                buf:writeString("TXDKZP")
                buf:writeInt(lottery_count)  --奖卷数
                buf:writeInt(pai_xin) --?
            end,userinfo.ip,userinfo.port)
 

end


function choujiang_tools_lib.onRecvKaishiChoujiang(buf)
	local userinfo = userlist[getuserid(buf)]; 
    if not userinfo then return end;
   choujiang_tools_lib.do_chuojiang(user_info)

end    



--命令列表
cmdHandler = 
{
	--["TXDKZP"] = choujiang_tools_lib.onRecvDakaiZhuanpan, --收到打开转盘
	--["TXKSCJ"] = choujiang_tools_lib.onRecvKaishiChoujiang, --收到开始抽奖
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

