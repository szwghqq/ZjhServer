if not tex_buf_lib then
    tex_buf_lib = _S
    {
        onrecvwanttokick = NULL_FUNC,
        toupiaotimeover = NULL_FUNC,
        dealkickresult = NULL_FUNC,
        onrecvkickpeopleid = NULL_FUNC,
        sendresult = NULL_FUNC,
        initkickinfo = NULL_FUNC,
        on_after_gameover = NULL_FUNC,
        onrecvtoupiao = NULL_FUNC,
        on_after_user_standup = NULL_FUNC,
        on_after_user_sitdown = NULL_FUNC,
        onrecvifkickvip = NULL_FUNC,
        onafterkickuser = NULL_FUNC,
        get_kick_card_count = NULL_FUNC,
        sub_kick_card_count = NULL_FUNC,
        load_kick_card_from_db = NULL_FUNC,
        on_before_user_enter_desk = NULL_FUNC,
        onrecvcheckcishu = NULL_FUNC,
        send_can_kick_result = NULL_FUNC,
        get_aleady_kick=NULL_FUNC,
        set_aleady_kick=NULL_FUNC,
        is_user_kicked=NULL_FUNC,
        on_recvclick_cancel=NULL_FUNC, --收到点击“取消”按钮
        give_kick_card=NULL_FUNC,
    }
end

--登陆完成后事件
function tex_buf_lib.load_kick_card_from_db(userinfo) 
 --   if(tex_gamepropslib ~= nil) then
        --这个方法会在userinfo.propslist[kick_card_id]中记录踢人卡数量
  --      tex_gamepropslib.get_props_count_by_id(tex_gamepropslib.PROPS_ID.KICK_CARD_ID, userinfo, function(kick_card_count) end)
   -- end
end

--获取踢人卡
function tex_buf_lib.get_kick_card_count(user_id)
    local userinfo = usermgr.GetUserById(user_id);
    if(userinfo == nil or userinfo.propslist == nil) then return 0 end
    return userinfo.propslist[tex_gamepropslib.PROPS_ID.KICK_CARD_ID] or 0
end

--减少踢人卡
--complete_callback_func(props_count)
function tex_buf_lib.sub_kick_card_count(user_id, sub_count,complete_callback_func)
    local userinfo = usermgr.GetUserById(user_id);
    if not userinfo then return end
    if tex_gamepropslib == nil then return end

    local kick_card_id = tex_gamepropslib.PROPS_ID.KICK_CARD_ID;
    --更新踢人卡数量
    tex_gamepropslib.set_props_count_by_id(kick_card_id, sub_count, userinfo, complete_callback_func)
end

--给某个玩家发几个踢人卡
function tex_buf_lib.give_kick_card(user_id,card_num)
    local userinfo = usermgr.GetUserById(user_id);
    if not userinfo then return end
    if tex_gamepropslib == nil then return end

    local kick_card_id = tex_gamepropslib.PROPS_ID.KICK_CARD_ID;
    tex_gamepropslib.set_props_count_by_id(kick_card_id, card_num, userinfo, function(count) end)
end

function tex_buf_lib.send_can_kick_result(userinfo, cankick, call_back)
    local cankicknum = tex_buf_lib.get_kick_card_count(userinfo.userId)
        netlib.send(
                function(buf)
                    buf:writeString("TXFQTR")
                    buf:writeByte(cankick)
                    buf:writeInt(cankicknum)
                    buf:writeByte(userinfo.site or 0)
                end,userinfo.ip,userinfo.port)    
    if (call_back ~= nil and cankick <= 0) then
        call_back(cankicknum)
    end
end

--[[
	to wangyu
	踢人卡实现代码
	获取桌子上的用户信息方法如下
						deskmgr.getplayers(deskno)
	返回内容结构如下	{{ siteno=i, userinfo=userinfo },{ siteno=i, userinfo=userinfo }...}	
--]]	
--收到想踢人的请求
function tex_buf_lib.onrecvwanttokick(buf)
    local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end; if not userinfo.desk or userinfo.desk <= 0 then return end;
	local deskno = userinfo.desk

	local deskinfo = desklist[deskno].gamedata
    local cankick = 0
	local players = deskmgr.getplayers(deskno)
    local cankicknum = 0

    local kickcounts = 0
    kickcounts = tex_buf_lib.get_kick_card_count(userinfo.userId)

    
    --先看是否VIP，再判断次数是不是够，是不是正在踢人，是不是人数不够
    --否则直接记录发起人投票人的info
    if kickcounts <= 0 then
        cankick = 3 --踢人次数不够
    elseif deskinfo.kickinfo.peoplecount ~= 0  then
		cankick = 4 --正在踢人
	elseif #players < 5 then
		cankick = 1 --人数不够    
    elseif tex_buf_lib.get_aleady_kick(deskno)==1 then
        cankick = 7 --如果本局已踢过人，就让客户端显示相应错误
    else
		deskinfo.kickinfo.userinfo = userinfo --记录发起投票人的info	
    end
    --如果可以踢人，那么设置这局为用过踢人卡
    if (cankick==0) then
        tex_buf_lib.set_aleady_kick(deskno,1)
    end
    --发送是否可以替人胡请求
    tex_buf_lib.send_can_kick_result(userinfo, cankick)
  
end
	
--通知所有人某人已经被踢出房间
function tex_buf_lib.onafterkickuser(deskno,kickuser, is_playing)
   local deskinfo = desklist[deskno].gamedata
   local kickname = kickuser.userinfo.nick
   local face = kickuser.userinfo.imgUrl
   local faqiren = deskinfo.kickinfo.userinfo
    for _, player in pairs(deskmgr.getplayers(deskno)) do
        --被踢人在玩，不应当收到协议
        if (is_playing == 0 or 
            (is_playing == 1 and kickuser.userinfo.userId ~= player.userinfo.userId)) then
            netlib.send(
                function(buf)
                    buf:writeString("TXKICK")
                    buf:writeString(kickname)  --被踢人的名字
                    buf:writeString(face)  --被踢人的头像
                    buf:writeByte(kickuser.okcount) --同意的人数
                    buf:writeByte(kickuser.notokcount) --不同意的人数
                    buf:writeByte(kickuser.abortcount) --弃权的人数
                    buf:writeByte(kickuser.count) --投票的人数
                    buf:writeString(faqiren.nick or "") --发起人的昵称
                end,player.userinfo.ip,player.userinfo.port)
        end
    end
    --被踢人在玩，不应当收到协议
    if (is_playing == 0) then
        --通知被踢的人自己被踢走
        netlib.send(
            function(buf)
                buf:writeString("TXBTZL")       
            end,kickuser.userinfo.ip,kickuser.userinfo.port)
    end
end

--投票30秒时间到
function tex_buf_lib.toupiaotimeover(deskno)
	local deskinfo = desklist[deskno].gamedata
	for i, player in pairs(deskinfo.kickinfo.toupiaoren) do
		if player.toupiaoresult == -1 then  --没有投票,按照弃权处理
			player.toupiaoresult = 2 --弃权
			deskinfo.kickinfo.toupiaoabort = deskinfo.kickinfo.toupiaoabort + 1			
		end
	end
	
	tex_buf_lib.dealkickresult(deskno)
end

function tex_buf_lib.add_desk_kick_list(deskno, kick_info, kick_user_info)
    kick_info.userinfo = kick_user_info;
    if(desklist[deskno] and desklist[deskno].gamedata) then
        table.insert(desklist[deskno].gamedata.kickedlist, kick_info); 
    end
end

--处理投票结果
function tex_buf_lib.dealkickresult(deskno)
    local deskinfo = desklist[deskno].gamedata
    --投票结束后不处理结果信息
    if deskinfo.kickinfo.peoplecount == 0 then
        return
    end
    
    local result = 0
    local kickuserinfo = deskinfo.kickinfo.kickuserinfo
	local kickname = kickuserinfo.nick
	local face = kickuserinfo.imgUrl
    --同意大于半数后踢出，结束投票
    local isplaying = 0
    if deskinfo.kickinfo.toupiaook > deskinfo.kickinfo.peoplecount / 2 then  	        
    	--不在游戏中的人将被马上踢出房间
    	for _, player in pairs(deskmgr.getplayingplayers(deskno)) do
    		if player.userinfo == deskinfo.kickinfo.kickuserinfo then
    			isplaying = 1
    			break
    		end			
        end
        local player = {
                        userinfo = deskinfo.kickinfo.kickuserinfo,
                        systime = os.time(),
                        isondesk = isplaying,
                        okcount = deskinfo.kickinfo.toupiaook,
                        notokcount = deskinfo.kickinfo.toupiaonotok,
                        abortcount = deskinfo.kickinfo.toupiaoabort,
                        count = deskinfo.kickinfo.peoplecount,
                    }

	    --通知被踢走
	    tex_buf_lib.onafterkickuser(deskno, player, isplaying)
        tex_buf_lib.add_desk_kick_list(deskno, player, deskinfo.kickinfo.kickuserinfo);
    	result = 1
    end

     --弃权+不同意大于等于半数后结束
   if deskinfo.kickinfo.toupiaonotok + deskinfo.kickinfo.toupiaoabort >= deskinfo.kickinfo.peoplecount / 2 then  
    	result = 2
   end
    
	--通知投票结果
	for _, player in pairs(deskmgr.getplayers(deskno)) do
		local deskuserinfo = player.userinfo
		local desksiteno = player.siteno
		
        if deskinfo.kickinfo.peoplecount == 0 then
            break
        end
        --不发给被踢的人
		if deskinfo.kickinfo.kickuserinfo  ~= deskuserinfo then
            --投票还没有结束的话，不发给还没有完成投票的投票人，？？干什么用的？
            if result > 0 then
                if deskinfo.kickinfo.toupiaoren[deskuserinfo.userId] ~= nil then
                    deskinfo.kickinfo.toupiaoren[deskuserinfo.userId].toupiaoresult = 3
                end
            end
            if deskinfo.kickinfo.toupiaoren[deskuserinfo.userId] == nil or 
                deskinfo.kickinfo.toupiaoren[deskuserinfo.userId].toupiaoresult > -1 then
                --通知投票结果
                tex_buf_lib.sendresult(deskinfo,deskuserinfo,result)			        
             end
        else --如果投票是成功的，发给被踢人，投票结果
            if result==1 then
                 --通知投票结果
                tex_buf_lib.sendresult(deskinfo,deskuserinfo,result)	
            end
        end
    end

    --处理结束，停止计划任务
	if result ~= 0 then
        if (deskinfo.kickinfo.timeover ~= nil) then
            deskinfo.kickinfo.timeover.cancel()
            deskinfo.kickinfo.timeover = nil
        end
        --减少发起人的踢人卡
        local faqiren = deskinfo.kickinfo.userinfo
        local send_kick_counts = function(kick_counts)
	        netlib.send(
	            	    function(buf)
	                    buf:writeString("TXVPCS")
	                    buf:writeInt(kick_counts) ---次数，-1：不是vip，0：次数不够，其他：次数
	                end,faqiren.ip,faqiren.port)
        end
        
        tex_buf_lib.sub_kick_card_count(faqiren.userId, -1,send_kick_counts)

        tex_buf_lib.initkickinfo(deskno) --清空投票人信息
        --通知客户端该用户的剩余踢人卡数
        
            
        --用户在才能被踢走
        if (isplaying == 0 and kickuserinfo.desk ~= nil and kickuserinfo.desk == deskno and result==1) then
            pre_process_back_to_hall(kickuserinfo)            
        end
	end
    
end


function tex_buf_lib.sendresult(deskinfo,userinfo,result)
    if deskinfo.kickinfo.peoplecount == 0 then
        return
    end
    local kickuserinfo = deskinfo.kickinfo.kickuserinfo
	local kickname = kickuserinfo.nick
	local face = kickuserinfo.imgUrl
    local faqiren = deskinfo.kickinfo.userinfo
    local isKickUser=0 --是不是被踢人 0不是 1是

    if(kickuserinfo.userId==userinfo.userId)then
        isKickUser=1
    end

    --TraceError(faqiren)
    netlib.send(
            function(buf)
                buf:writeString("TXTPJG")
                buf:writeByte(deskinfo.kickinfo.toupiaook) --同意的人数
                buf:writeByte(deskinfo.kickinfo.toupiaonotok) --不同意的人数
                buf:writeByte(deskinfo.kickinfo.toupiaoabort) --弃权的人数
                buf:writeByte(deskinfo.kickinfo.peoplecount) --投票的总人数
                buf:writeByte(result) --投票结果，2：投票结束，不同意踢；1：投票结束，同意踢；0：进行中 
                buf:writeString(kickname)   --被踢人的名称
                buf:writeString(face)       --被踢人的头像
                buf:writeString(faqiren.nick or "")       --发起人的昵称
                buf:writeByte(isKickUser)  --是不是被踢人 0不是 1是
            end,userinfo.ip,userinfo.port)
end

--收到想踢谁的信息
function tex_buf_lib.onrecvkickpeopleid(buf)
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end; if not userinfo.desk or userinfo.desk <= 0 then return end;
	local deskno = userinfo.desk
	local kicksiteno = buf:readByte()

	local deskinfo = desklist[deskno].gamedata
	
	local cankick = 0 
	local players = deskmgr.getplayers(deskno)

    --检查被踢人是否还在座位上
    local kickuserinfo = nil
    local cankicknum = 0
    for _, player in pairs(players) do
        if player.siteno == kicksiteno then
            kickuserinfo = player.userinfo --被踢的人的用户信息 
            break
        end
    end
    
    local kickcounts = tex_buf_lib.get_kick_card_count(userinfo.userId)
    if kickcounts <= 0 then
        cankick = 3
    elseif deskinfo.kickinfo.peoplecount > 0  then
        cankick = 4
	elseif #players  < 5 then
        cankick = 1 --人数不够
    elseif kickuserinfo == nil then
        cankick = 5 --已经离开
    elseif tex_buf_lib.is_user_kicked(kickuserinfo, deskno)  == 1 then
        cankick = 6 --就是被踢了
   
    end
    local kick_func = function(kick_card_num)
        if (kick_card_num <= 0) then
            return
        end
        
        cankicknum = kick_card_num
        deskinfo.kickinfo.kickuserinfo = kickuserinfo
        deskinfo.kickinfo.peoplecount = #players - 1	--收集当前可以参与投票的人数，扣除自己和被踢的人
        deskinfo.kickinfo.toupiaook = 1 --发起人默认为同意
        --30秒计时
        deskinfo.kickinfo.timeover = timelib.createplan(
                function()
                     tex_buf_lib.toupiaotimeover(deskno)
               end, 30)
        for _, player in pairs(deskmgr.getplayers(deskno)) do
    		local deskuserinfo = player.userinfo
    		local desksiteno = player.siteno
    		--只对有权投票的人发送投票框消息
    		if deskuserinfo ~= deskinfo.kickinfo.kickuserinfo  and 
                deskinfo.kickinfo.userinfo ~= deskuserinfo then    
                deskinfo.kickinfo.toupiaoren[deskuserinfo.userId] = {}
    			deskinfo.kickinfo.toupiaoren[deskuserinfo.userId].toupiaoresult = -1 --没有投票
                --通知踢人
    			netlib.send(
                	function(buf)
                    	buf:writeString("TXTRID")
                    	buf:writeByte(deskinfo.kickinfo.peoplecount)
                    	buf:writeString(kickuserinfo.nick)
                    	buf:writeString(kickuserinfo.imgUrl)
                        buf:writeString(deskinfo.kickinfo.userinfo.nick or "")
                	end,deskuserinfo.ip,deskuserinfo.port)
            end
             --增加发起人发送结果消息，全部为0
            local faqiren = deskinfo.kickinfo.userinfo
               
            tex_buf_lib.sendresult(deskinfo,faqiren,0)
        end
    end    
    --发送是否可以替人胡请求
    if(cankick~=0)then
        tex_buf_lib.send_can_kick_result(userinfo, cankick)  
    else
        local cankicknum = tex_buf_lib.get_kick_card_count(userinfo.userId)
        kick_func(cankicknum)
    end

end

--清空投票人信息
function tex_buf_lib.initkickinfo(deskno) 
	local deskinfo = desklist[deskno].gamedata
	
	deskinfo.kickinfo = {}
	deskinfo.kickinfo.peoplecount = 0	--投票人数
	deskinfo.kickinfo.userinfo = {}	--发起投票人
	deskinfo.kickinfo.toupiaook = 0		--同意人数
	deskinfo.kickinfo.toupiaonotok = 0	--不同意人数
	deskinfo.kickinfo.toupiaoabort = 0  --弃权人数
	
	deskinfo.kickinfo.kickuserinfo = {}	--被踢人的信息
	
	deskinfo.kickinfo.toupiaoren = {} --投票人数组清空
    deskinfo.kickinfo.alreadykick = 1 --这一局用过踢人卡了
end

function tex_buf_lib.get_aleady_kick(deskno)
    local deskinfo = desklist[deskno].gamedata
    return deskinfo.kickinfo.alreadykick
end

function tex_buf_lib.set_aleady_kick(deskno,v_alreadykick)
      local deskinfo = desklist[deskno].gamedata
    deskinfo.kickinfo.alreadykick = v_alreadykick
end

--游戏结束后调用此函数
function tex_buf_lib.on_after_gameover(deskno)
	local deskinfo = desklist[deskno].gamedata
	--遍历是否有需要被踢的人
    for i, player in pairs(deskinfo.kickedlist) do
        if player.isondesk == 1 then
            local kickname = player.userinfo.nick
            if (player.userinfo.desk ~= nil and 
                player.userinfo.desk == deskno) then
                pre_process_back_to_hall(player.userinfo) --强制踢走                       
            end
            player.isondesk = 0
            player.systime = os.time()
            --通知被踢走
            if not player.n_type or player.n_type ~= 1 then
              tex_buf_lib.onafterkickuser(deskno,player, 0)
            else
              --todo 贵族T人通知
              if wing_lib then
                wing_lib.send_kick_info_toall(deskno,player)
              end
            end
        end
        
        --时间已经过了10分钟后就删除记录
        if os.time() - player.systime > 600 then
            deskinfo.kickedlist[i] = nil
        end
    end
end

--坐下后，通知坐下的人投票结果
function tex_buf_lib.on_after_user_sitdown(userinfo, deskno, siteno)
    local deskinfo = desklist[deskno].gamedata
    if deskinfo.kickinfo.peoplecount > 0 then
        tex_buf_lib.sendresult(deskinfo,userinfo,0)
    end

    --通知客户端该用户的剩余踢人卡数
    local kickcounts = tex_buf_lib.get_kick_card_count(userinfo.userId)

        netlib.send(
            	    function(buf)
                    buf:writeString("TXVPCS")
                    buf:writeInt(kickcounts) ---次数，-1：不是vip，0：次数不够，其他：次数
                end,userinfo.ip,userinfo.port)

end

function tex_buf_lib.is_user_kicked(user_info, deskno)
    local deskinfo = desklist[deskno].gamedata
  	--遍历是否可以坐下
  	for k, player in pairs(deskinfo.kickedlist) do
        if player.userinfo == nil then
            deskinfo.kickedlist[k] = nil
        elseif player.userinfo.userId == user_info.userId then
      		--时间已经过了30分钟后就删除记录
      		if os.time() - player.systime > 600 then
      			deskinfo.kickedlist[k] = nil
      			return 0
            else
      			return 1
      		end
        end
    end
    return 0
end

--坐下前判断是否可以坐
function tex_buf_lib.on_before_user_enter_desk(user_info, deskno)
    if (deskno == nil or deskno < 0) then
        return 1
    end
    if (tex_buf_lib.is_user_kicked(user_info, deskno) == 1) then
        return 0
    else
        return 1
    end
end
         
-- 用户站起处理
function tex_buf_lib.on_after_user_standup(user_info,deskno,site)
    local deskinfo = desklist[deskno].gamedata
	if deskinfo.kickinfo.toupiaoren[user_info.userId] ~= nil and
            deskinfo.kickinfo.toupiaoren[user_info.userId].toupiaoresult == -1 then
        deskinfo.kickinfo.toupiaoren[user_info.userId].toupiaoresult = 2 --弃权
		deskinfo.kickinfo.toupiaoabort = deskinfo.kickinfo.toupiaoabort + 1				
    end

    if deskinfo.kickinfo.peoplecount > 0 then
        tex_buf_lib.dealkickresult(deskno)
    end
	
end

function tex_buf_lib.onrecvifkickvip(buf)
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end; if not userinfo.desk or userinfo.desk <= 0 then return end;
	local deskno = userinfo.desk

    local kickcounts = tex_buf_lib.get_kick_card_count(userinfo.userId)
    netlib.send(
            	    function(buf)
                    buf:writeString("TXKVIP")
                    buf:writeByte(1) --1:是vip，0：不是vip
                    buf:writeInt(kickcounts) ---次数，-1：不是vip，0：次数不够，其他：次数
                end,userinfo.ip,userinfo.port)

end

--收到查询次数消息
function tex_buf_lib.onrecvcheckcishu(buf)
    local userinfo = userlist[getuserid(buf)]; 

    local complete_callback_func = function(kick_card_count)
        netlib.send(
                function(buf)
                buf:writeString("TXBFKS")
                buf:writeInt(kick_card_count) 
            end,userinfo.ip,userinfo.port)
    end

    local props_id = tex_gamepropslib.PROPS_ID.KICK_CARD_ID
    tex_gamepropslib.get_props_count_by_id(props_id, userinfo, complete_callback_func)
   
        
end

--点击取消按钮，就可以认为这盘没用过算牌器了，因为其他人是点不了取消的
function tex_buf_lib.on_recvclick_cancel(buf)
    local userinfo = userlist[getuserid(buf)];
    if not userinfo then return 0 end;
    local deskno = userinfo.desk or 0
    if(deskno~=0)then --防止万一线程不同步造成回到大厅之后才收到要取消的协议，这时不作什么操作，让这个房间玩多一局再取消状况。
        tex_buf_lib.set_aleady_kick(deskno,0)
    end
    return 1;
end

--收到投票信息
function tex_buf_lib.onrecvtoupiao(buf)
	local userinfo = userlist[getuserid(buf)]; 
	if not userinfo then return end; if not userinfo.desk or userinfo.desk <= 0 then return end;
	local deskno = userinfo.desk
	local toupiaojieguo = buf:readByte() --投票结果，2：弃权；1：同意；0：不同意
	local deskinfo = desklist[deskno].gamedata
    --投票已经结束的话，不处理此消息
	if deskinfo.kickinfo.peoplecount == 0 then
        return
    end

    --这一局用过踢人功能了
    tex_buf_lib.set_aleady_kick(deskno,1)
	if (deskinfo.kickinfo.toupiaoren[userinfo.userId].toupiaoresult ~= -1) then
        return
    end
    --记录投票人投票信息
    deskinfo.kickinfo.toupiaoren[userinfo.userId].toupiaoresult = toupiaojieguo	
	if toupiaojieguo == 1 then
		deskinfo.kickinfo.toupiaook = deskinfo.kickinfo.toupiaook + 1 --同意的人加一
	elseif toupiaojieguo == 2 then
		deskinfo.kickinfo.toupiaoabort = deskinfo.kickinfo.toupiaoabort + 1 --弃权的人加一
	else	
		deskinfo.kickinfo.toupiaonotok = deskinfo.kickinfo.toupiaonotok + 1 --不同意的人加一
	end	
	--处理结果。
	tex_buf_lib.dealkickresult(deskno)
end

--]]



--命令列表
cmdHandler =
{
    	["TXFQTR"] = tex_buf_lib.onrecvwanttokick,			--发起踢人
		["TXTRID"] = tex_buf_lib.onrecvkickpeopleid,		--收到想踢谁的信息
		["TXTPXX"] = tex_buf_lib.onrecvtoupiao,				--收到投票结果
   		["TXKVIP"] = tex_buf_lib.onrecvifkickvip,				--查询是否可以踢人的vip
        ["TXBFKS"] = tex_buf_lib.onrecvcheckcishu,				--查询踢人卡的次数
        ["TXCLICKCANCEL"] = tex_buf_lib.on_recvclick_cancel, --收到点击“取消”按钮

    --[[
		to wangyu
		踢人卡协议放在这里
	----------踢人卡模块----------
	
		
		["TXEMOT"] = onrecvsendemot,			--点发表情
		["TXGIFT"] = onrecvsendgift,			--点送礼物
		["TXGFLT"] = onrecvgetgiftinfo,			--请求某人的礼物详情
		["TXGFUS"] = onrecvusinggift,			--请求穿某礼物		
    --]]
}

--加载插件的回调
for k, v in pairs(cmdHandler) do
	cmdHandler_addons[k] = v
end

TraceError("加载texbuff插件")

