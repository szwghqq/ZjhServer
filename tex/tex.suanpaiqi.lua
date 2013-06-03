TraceError("init spq....")

if not tex_suanpaiqilib then
	tex_suanpaiqilib = _S
	{
        on_recvclick_suan=NULL_FUNC, --收到点击“算”按钮
        on_user_game_over=NULL_FUNC, --结算时扣钱
	}
end

function tex_suanpaiqilib.on_recvclick_suan(buf)
   -- TraceError("收到点击算牌")
	local user_info = userlist[getuserid(buf)]; 

    if(user_info.gameInfo.suan==nil)then
        user_info.gameInfo.suan = {};
    end

    --算牌器开关，0关，1开
    local suan_switch=buf:readByte(); 
    --TraceError("suan_switch="..tostring(suan_switch));
    user_info.gameInfo.suan.suan_switch=suan_switch;
    user_info.gameInfo.suan.is_use_suan=0;--默认为这盘没用过算牌


    --是否允许用算牌功能
    local can_use_suan=1;
	
	--计算要扣的钱
	local smallbet = 0
	local usespq_money=0
	
	--有人进来时没有桌子号，就认为这局不能用算牌器
	if (user_info.desk==nil or desklist[user_info.desk]==nil) then 
		can_use_suan=-1
	else
		smallbet = desklist[user_info.desk].smallbet;	
		usespq_money=smallbet/10;
		if(usespq_money<10) then usespq_money=10 end;
	    if(usespq_money>400) then usespq_money=400 end;
	        --看看能不能用算牌器功能，就直接返回错误信息
	    if(is_can_usesuan(user_info,usespq_money)==0)then
	        can_use_suan=-1
	    end
	end
	


    --这盘用过算牌器
    if(can_use_suan~=-1)then
        user_info.gameInfo.suan.is_use_suan=1;
    end

    --关闭算牌器
    if(suan_switch==0)then
         can_use_suan=-2;
    end

    --如果能用算牌器功能
    --扣钱       
	--usermgr.addgold(user_info.userId, -usespq_money, 0, g_GoldType.spq_usespq, -1, 1);
    
	--发给客户端概率
	     netlib.send(
            function(buf)
                buf:writeString("SPQCLICKSUAN")
                buf:writeByte(can_use_suan)  --能否使用
            end,user_info.ip,user_info.port)	
end


function tex_suanpaiqilib.on_user_game_over(user_info)
    --这盘没用过算牌，而且算牌开关也是关的，直接return
    if (user_info==nil) then return end;
    if(user_info.gameInfo.suan==nil or user_info.desk==nil)then
        return;
    end

    if( user_info.gameInfo.suan.is_use_suan~=1 and user_info.gameInfo.suan.suan_switch==0)then
        return;
    end

    local user_level=usermgr.getlevel(user_info);


    local smallbet = desklist[user_info.desk].smallbet;	
	local usespq_money=smallbet/10;
	if(usespq_money<10) then usespq_money=10 end;
    if(usespq_money>400) then usespq_money=400 end;
    if(user_level<4)then usespq_money=0 end;--等级小于4的是免费用户

    --算牌器是开的或者这盘用过算牌的功能，直接扣钱
    if(user_info.gameInfo.suan.suan_switch==1 or user_info.gameInfo.suan.is_use_suan==1)then
        --扣钱
        if(is_can_usesuan(user_info,usespq_money) == 1) then
            usermgr.addgold(user_info.userId, -usespq_money, 0, g_GoldType.spq_usespq, -1, 1);
        end
    end

    --算牌器是关的,下一盘开始时，修改状态为默认是没用过算牌功能
    if(user_info.gameInfo.suan.suan_switch==0)then
        user_info.gameInfo.suan.is_use_suan=0;
    end
end


--看是不是有资格用算牌器
function is_can_usesuan(user_info,usespq_money)
    
    --没拿到用户信息或不在牌桌上
	if not user_info then return 0 end;
	if not user_info.desk or user_info.desk <= 0 then return 0 end;
    local user_level=usermgr.getlevel(user_info);

	--等级小于4的是免费用户，直接能用
    if(user_level<4)then
        return 1;
    end

	--计算钱是否够
	if (get_canuse_gold(user_info) < usespq_money) then
		return 0;
	end
	
	--是否是黄金以上的VIP
	local viplevel = 0
	if(viplib) then
	    viplevel = viplib.get_vip_level(user_info);
	end
	
	if (viplevel<3) then
		return 0;
	end
    
	--以上条件都不满足，代表可以用算牌器了
	return 1;
end


--命令列表
cmd_suan_pan_qi_handler = 
{
	["SPQCLICKSUAN"] = tex_suanpaiqilib.on_recvclick_suan, --收到点击“算”按钮
   
}

--加载插件的回调
for k, v in pairs(cmd_suan_pan_qi_handler) do 
	cmdHandler_addons[k] = v
end






