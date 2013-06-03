
TraceError("init sn_huodonglib....")

if not sn_huodonglib then
	sn_huodonglib = _S
	{
        on_recv_gift_sn = NULL_FUNC,		--时间校验        
        on_game_over = NULL_FUNC,			--游戏结束牌型判断
  		on_after_user_login = NULL_FUNC,    --用户登陆时更新礼品
  		on_recv_czgift = NULL_FUNC,			--登陆自动送充值得到的礼品
	}
end

--收到激活码
function sn_huodonglib.on_recv_gift_sn(buf)
    --TraceError("init on_recv_gift_sn....");
	local userinfo = userlist[getuserid(buf)]; 
    if not userinfo then return end;
    local gift_sn=buf:readString();  --得到激活码
    gift_sn=no_sql_insert(gift_sn);
    local sendStr="";
    local sendResult;
    local retresult;
    --1.调用存储过程，如果激活码没使用过，就直接用掉
   dblib.execute(string.format("call sp_update_giftsn(%d,'%s')",userinfo.userId,gift_sn),
		function(dt)
            if dt and #dt > 0 then
				--存储过程返回了要发的奖
                --TraceError(dt[1]["result"]);
                retresult=tonumber(dt[1]["result"]);
    				if retresult > 0 then
    				   	sendResult=1;
                        	
    					--给玩家发奖
    					if retresult==1 then
    						--A.12000份：688筹码、30经验值。
    						usermgr.addgold(userinfo.userId, 688, 0, g_GoldType.jhm_huodong, -1, 1);
    						usermgr.addexp(userinfo.userId, usermgr.getlevel(userinfo), 30, g_ExpType.jhm_huodong, groupinfo.groupid);
                            --sendStr="688筹码、30经验值";
                            sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_688");
                        elseif retresult==2 then
    					    --B.12000份：铜卡VIP 3日体验、888筹码、30经验值。
    						usermgr.addgold(userinfo.userId, 888, 0, g_GoldType.jhm_huodong, -1, 1);
    						usermgr.addexp(userinfo.userId, usermgr.getlevel(userinfo), 30, g_ExpType.jhm_huodong, groupinfo.groupid);
    						add_user_vip(userinfo,1,3);
                            --sendStr="铜卡VIP3日体验、888筹码、30经验值"
                            sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_888");
    					elseif retresult==3 then
    					--1000份：铜卡VIP5日体验、1688筹码、50经验值、限量缤纷冰激凌商城礼品。
    						usermgr.addgold(userinfo.userId, 1688, 0, g_GoldType.jhm_huodong, -1, 1);
    						usermgr.addexp(userinfo.userId, usermgr.getlevel(userinfo), 50, g_ExpType.jhm_huodong, groupinfo.groupid);
    						gift_addgiftitem(userinfo,9007,userinfo.userId,userinfo.nick, false);
    						add_user_vip(userinfo,1,5);
                            --sendStr="铜卡VIP5日体验、1688筹码、50经验值、\n限量缤纷冰激凌商城礼品";
                            sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_1688");
	   					elseif retresult==4 then
    					--奖励1000W筹码，数量：10个。
    						usermgr.addgold(userinfo.userId, 10000000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="1000W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_1000W");
	   					elseif retresult==5 then
    					--奖励500W筹码，数量：10个。
    						usermgr.addgold(userinfo.userId, 5000000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="500W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_500W");
	   					elseif retresult==6 then
    					--奖励200W筹码，数量：200个。
    						usermgr.addgold(userinfo.userId, 2000000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="200W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_200W");
    					elseif retresult==7 then
    					--奖励100万筹码，数量：200个。
    						usermgr.addgold(userinfo.userId, 1000000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="100W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_100W");
    					elseif retresult==8 then
    					--奖励90万筹码，数量：50个。
    						usermgr.addgold(userinfo.userId, 900000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="90W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_90W");
    					elseif retresult==9 then
    					--奖励80万筹码，数量：50个。
    						usermgr.addgold(userinfo.userId, 800000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="80W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_80W");
    					elseif retresult==10 then
    					--奖励70万筹码，数量：50个。
    						usermgr.addgold(userinfo.userId, 700000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="70W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_70W");
    					elseif retresult==11 then
    					--奖励60万筹码，数量：50个。
    						usermgr.addgold(userinfo.userId, 600000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="60W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_60W");
    					elseif retresult==12 then
    					--奖励50万筹码，数量：100个。
    						usermgr.addgold(userinfo.userId, 500000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="50W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_50W");
    					elseif retresult==13 then
    					--奖励40万筹码，数量：50个。
    						usermgr.addgold(userinfo.userId, 400000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="40W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_40W");
    					elseif retresult==14 then
    					--奖励30万筹码，数量：50个。
    						usermgr.addgold(userinfo.userId, 300000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="30W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_30W");
    					elseif retresult==15 then
    					--奖励20万筹码，数量：50个。
    						usermgr.addgold(userinfo.userId, 200000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="20W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_20W");
    					elseif retresult==16 then
    					--奖励10万筹码，数量：50个。
    						usermgr.addgold(userinfo.userId, 100000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="10W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_10W");
    					elseif retresult==17 then
    					--QQ车
    						gift_addgiftitem(userinfo,5022,userinfo.userId,userinfo.nick, false)  
    					    --sendStr="QQ车";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_QQ");
     					elseif retresult==18 then
    					--玛莎
    						gift_addgiftitem(userinfo,5021,userinfo.userId,userinfo.nick, false)  
    					    --sendStr="玛莎";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_Car");   
    					elseif retresult==19 then
    					--奥拓
    						gift_addgiftitem(userinfo,5013,userinfo.userId,userinfo.nick, false)  
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_Car1");
    				    elseif retresult==20 then
    					--甲壳虫
    						gift_addgiftitem(userinfo,5012,userinfo.userId,userinfo.nick, false)  
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_Car2");		
    					elseif retresult==21 then
    						usermgr.addgold(userinfo.userId, 50000000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="5000W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_5000W");  
    					elseif retresult==22 then
    						usermgr.addgold(userinfo.userId, 20000000, 0, g_GoldType.jhm_huodong, -1, 1);
    					    --sendStr="2000W筹码";
    					    sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_2000W");
                        elseif retresult==23 then
                            --需求：http://172.17.0.114/zentao/story-view-793.html
                            --雪铁龙C2一辆
                            car_match_db_lib.add_car(userinfo.userId, 5018, 1, 1);
                            --红宝石两个
    						gift_addgiftitem(userinfo,5004,userinfo.userId,userinfo.nick, false);
    						gift_addgiftitem(userinfo,5004,userinfo.userId,userinfo.nick, false);
                            --VIP银卡30天体验
    						add_user_vip(userinfo,2,30);
                            sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_Car3");
               elseif retresult == 24 then
                --.7600份：铜卡VIP 3日体验、1888筹码。
    						usermgr.addgold(userinfo.userId, 1888, 0, g_GoldType.jhm_huodong, -1, 1);
    						add_user_vip(userinfo,1,3);
                --sendStr="铜卡VIP 3日体验、1888筹码"
                sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_retresult24");
               elseif retresult == 25 then
                 --.2000份：银卡VIP 3日体验、3888筹码。
    						usermgr.addgold(userinfo.userId, 3888, 0, g_GoldType.jhm_huodong, -1, 1);
    						add_user_vip(userinfo,2,3);
                --sendStr="银卡VIP 3日体验、3888筹码"
                sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_retresult25");
               elseif retresult == 26 then
                 --.400份：金卡VIP 3日体验、5888筹码。
    						usermgr.addgold(userinfo.userId, 5888, 0, g_GoldType.jhm_huodong, -1, 1);
    						add_user_vip(userinfo,3,3);
                --sendStr="金卡VIP 3日体验、5888筹码"
                sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_retresult26");
    					 elseif retresult == 27 then
    					  --.30w份：铜卡VIP 3日体验、6w筹码。
    						usermgr.addgold(userinfo.userId, 60000, 0, g_GoldType.jhm_huodong, -1, 1);
    						add_user_vip(userinfo,1,3);
                --sendStr="铜卡VIP 3日体验、6w筹码。"
                sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_retresult27");
              elseif retresult == 28 then
                --.30w份：金卡VIP 3日体验、4w筹码。
    						usermgr.addgold(userinfo.userId, 40000, 0, g_GoldType.jhm_huodong, -1, 1);
    						add_user_vip(userinfo,3,3);
                --sendStr="金卡VIP 3日体验、4w筹码。"
                sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_retresult28");
              elseif retresult == 29 then
                --.30w份：银卡VIP 3日体验、7.5w筹码。
    						usermgr.addgold(userinfo.userId, 75000, 0, g_GoldType.jhm_huodong, -1, 1);
    						add_user_vip(userinfo,2,3);
                --sendStr="银卡VIP 3日体验、7.5w筹码。"
                sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_retresult29");
              elseif retresult == 30 then
                 --.30w份：铜卡VIP 3日体验、7.5w筹码。
    						usermgr.addgold(userinfo.userId, 100000, 0, g_GoldType.jhm_huodong, -1, 1);
    						add_user_vip(userinfo,1,3);
                --sendStr="铜卡VIP 3日体验、7.5w筹码。"
                sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_retresult30");
              elseif retresult == 31 then
                --.5w份：金卡VIP 15日体验、8w筹码、甲壳虫汽车。
    						usermgr.addgold(userinfo.userId, 80000, 0, g_GoldType.jhm_huodong, -1, 1);
    						car_match_db_lib.add_car(userinfo.userId, 5012, 0)
    						add_user_vip(userinfo,3,15);
                --sendStr="金卡VIP 15日体验、8w筹码、甲壳虫汽车。"
                sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_retresult31");
              elseif retresult == 32 then
                --.5w份：金卡VIP 30日体验、3w筹码、宝马汽车。
    						usermgr.addgold(userinfo.userId, 30000, 0, g_GoldType.jhm_huodong, -1, 1);
    						car_match_db_lib.add_car(userinfo.userId, 5049, 0)
    						add_user_vip(userinfo,3,30);
                --sendStr="金卡VIP 30日体验、3w筹码、宝马汽车。"
                sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_retresult32");
    					elseif retresult == 33 then
    					  --30w张 1W筹码 + VIP*1天
    					  usermgr.addgold(userinfo.userId, 10000, 0, g_GoldType.jhm_huodong, -1, 1);
    					  add_user_vip(userinfo,1,1);
                sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_retresult33");
              elseif retresult == 34 then
                --20w张 1.5W筹码 + VIP*1天
                usermgr.addgold(userinfo.userId, 15000, 0, g_GoldType.jhm_huodong, -1, 1);
                add_user_vip(userinfo,1,1);
                sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_retresult34");            
              elseif retresult == 35 then
                --20w张 1.5W筹码 + VIP*1天
                usermgr.addgold(userinfo.userId, 15000, 0, g_GoldType.jhm_huodong, -1, 1);
                add_user_vip(userinfo,1,1);
                sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_retresult35");
              elseif retresult == 36 then
                --20w张 1.5W筹码 + VIP*1天
                usermgr.addgold(userinfo.userId, 15000, 0, g_GoldType.jhm_huodong, -1, 1);
                add_user_vip(userinfo,1,1);
                sendStr=tex_lan.get_msg(userinfo, "jhm_chouma_type_retresult36");
    					end
    				else
    					--存储过程返回了-1,-2-3等错误码

    				    sendResult=retresult
                        if retresult==-1 then
                            --sendStr="激活码错误"
                            sendStr=tex_lan.get_msg(userinfo, "jhm_error");
                        elseif retresult==-2 then
                            --sendStr="激活码已被使用"
                            sendStr=tex_lan.get_msg(userinfo, "jhm_error_beenUsed");
                        elseif retresult==-3 then
                            --sendStr="激活码过期"
                            sendStr=tex_lan.get_msg(userinfo, "jhm_error_expired");
                        elseif retresult==-4 then
                            --sendStr="您已用过同类型的激活码或激活码已被使用"
                            sendStr=tex_lan.get_msg(userinfo, "jhm_error_usedSameType");
                        elseif retresult==-5 then
                            --sendStr="您在7天之内已经使用过改类型的激活码。"
                            sendStr=tex_lan.get_msg(userinfo, "jhm_error_usedSameType_retresult5");
                        elseif retresult==-6 then
                            --sendStr="您在3天之内已经使用过改类型的激活码。"
                            sendStr=tex_lan.get_msg(userinfo, "jhm_error_usedSameType_retresult6");
                        elseif retresult==-7 then
                            --sendStr="您在1天之内已经使用过改类型的激活码。"
                            sendStr=tex_lan.get_msg(userinfo, "jhm_error_usedSameType_retresult7");
                        end
    				end
				   -- TraceError("sendResult"..sendResult)
                   -- TraceError("sendStr"..sendStr)
				
				netlib.send(
					function(buf)				
						buf:writeString("JHMGIFTSN")
						buf:writeByte(sendResult)
						buf:writeString(_U(sendStr))
						
					end,userinfo.ip,userinfo.port)
            else
                netlib.send(
					function(buf)				
						buf:writeString("JHMGIFTSN")
						buf:writeByte("-1")
						--buf:writeString(_U("激活码验证错误"))
						buf:writeString(_U(tex_lan.get_msg(userinfo, "jhm_error2")))
						
					end,userinfo.ip,userinfo.port)
				--TraceError("激活码发放出错")
			end
		end)
    
end

function add_user_vip(userinfo,vip_level,vip_days)
		--送VIP
		local sql = "";
		sql = "insert into user_vip_info values(%d,%d,DATE_ADD(now(),INTERVAL %d DAY),0,0)";
		sql = sql.." ON DUPLICATE KEY UPDATE over_time = case when over_time > now() then DATE_ADD(over_time,INTERVAL %d DAY) else DATE_ADD(now(),INTERVAL %d DAY) end,notifyed = 0,first_logined = 0; ";
		sql = string.format(sql,userinfo.userId,vip_level,vip_days,vip_days,vip_days);
		dblib.execute(sql);
end

--不允许包含SQL语句，防止注入攻击
function no_sql_insert(tmp_str)
    tmp_str = string.gsub(tmp_str, "'", "\"");
    tmp_str = string.gsub(tmp_str,"select","s_elect");
    tmp_str = string.gsub(tmp_str,"insert","i_nsert");
    tmp_str = string.gsub(tmp_str,"update","u_pdate");
    return tmp_str;
end


--登陆送礼物
function sn_huodonglib.on_recv_czgift(buf)
    do return end;
	local user_info = userlist[getuserid(buf)]
	if user_info==nil then return end
	--数据库默认时间为2000年11月11日，这个功能是2012年5月上线，如果数据库里的值小于2012年，就一定是个默认值（没有送出）
	local sql="select gift_id from user_givegift_info where user_id=%d and give_time<'2012-1-1';update user_givegift_info set give_time=now() where user_id=%d;"
	sql=string.format(sql,user_info.userId,user_info.userId)
	dblib.execute(sql,function(dt)
		if(dt and #dt>0)then
            local gifts = {};
            local count = 0;
            for i=1,#dt do
                local gift_id=dt[i].gift_id
                --充值送车代码，新代码
                if (car_match_lib.CFG_CAR_INFO[gift_id] ~= nil) then
                    car_match_db_lib.add_car(user_info.userId, gift_id, 0)
                else
                    gift_addgiftitem(user_info,gift_id,user_info.userId,user_info.nick, false)                      
                end
                --合并再发给客户端
                if(gifts[gift_id] == nil) then
                    gifts[gift_id] = 1;
                    count = count + 1;
                else
                    gifts[gift_id] = gifts[gift_id] + 1;
                end
            end
			netlib.send(
				function(buf)				
				buf:writeString("CZGIFT")
				buf:writeInt(count)
                for k,v in pairs(gifts) do
                    buf:writeInt(k);
                    buf:writeInt(v);
                end
			end,user_info.ip,user_info.port)
		end
	end, user_info.userId)
end

--命令列表
cmdHandler = 
{
	["JHMGIFTSN"] = sn_huodonglib.on_recv_gift_sn, --收到激活码
	--["CZGIFT"] = sn_huodonglib.on_recv_czgift, --收到激活码
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end








