TraceError("init friend好友....")

if not friendlib then
	friendlib = _S
	{
		sql = _S
		{
			log_user_maxfriend = "insert into log_user_maxfriend_info(userid,maxnum,currtime) values(%d,%d,now());commit;",
			log_user_friend_num = "insert ignore into user_friendnum_info(userid,gamefriend,snsfriend,freshtime) values(%d,0,0,now()); "..
									" update user_friendnum_info set gamefriend = %d,snsfriend = %d,freshtime = now() where userid = %d;commit;",
			log_user_delfriend = "insert into log_user_delfriend_info(userid,deluserid,deltime) values(%d,%d,now());commit;",
			log_user_addfriend = "insert into log_user_addfriend_info(userid,adduserid,addtime) values(%d,%d,now());commit;",

			getFriendsIdList = "SELECT id FROM users WHERE user_name IN (%s) AND reg_site_no = %d",
			get_user_friends_sql = "select concat(user_friends.friends) as friends from user_friends where user_id = %d",
			update_user_friends_info = "update user_friends set snsfriends = %s,friends = %s where user_id = %d;commit;",
			update_user_friends_info_only = "update user_friends set friends = %s where user_id = %d;commit;",
			getuserinfofromdb = "select userid as userId,nick_name as nick,face as imgUrl,gold as gamescore,level from users a join user_tex_info b where a.id = b.userid and a.id = %d;",
			updateuserdelgamefriend = "update user_friends set friends = replace(friends,%s,'|') where user_id = %d;commit;",
			updateuseraddgamefriend = "update user_friends set friends = concat(friends,%s) where user_id = %d;commit;",
			getuservipinfo = "select vip_level from user_vip_info where user_id = %d and over_time >= now();",
		},

		change_userstate_tofriend				= NULL_FUNC,			--更新好友状态
		load_user_friend_info_from_sns 			= NULL_FUNC,			--更新数据库中的信息并写入内存
		write_friendinfo_to_ram					= NULL_FUNC,			--执行玩家好友信息写入内存
		friendxml_to_table						= NULL_FUNC,			--从XML文件中解析出玩家好友信息表
		do_delete_userfriend_byid				= NULL_FUNC,			--执行删除好友
		do_add_userfriend_byid					= NULL_FUNC,			--执行增加好友
		do_change_userstate_tofriend			= NULL_FUNC,			--执行发送玩家状态
		send_user_allfriend_info				= NULL_FUNC,			--发送所有好友的信息
		net_OnRecvInviteFriendJoin				= NULL_FUNC,             --收到请求邀请某个好友加入牌桌
		net_OnRecvShowAddFriend					= NULL_FUNC,            --收到请求能否显示添加该好友按钮
		net_OnRecvChangeFriendInfo				= NULL_FUNC,         	--收到修改好友信息请求
		net_OnRecvGetAllFriendInfo				= NULL_FUNC,         	--收到得到所有好友信息请求
		net_OnRecvJoinFriendDesk				= NULL_FUNC,			--收到请求加入好友桌子
		net_OnRecvWantToAddFriend				= NULL_FUNC,			 --收到玩家想加某人好友
		net_send_changeresult					= NULL_FUNC,			--发送增加删除结果
		send_newfriend_info						= NULL_FUNC,			--发送新好友信息
		send_newfriend_info_tomanager			= NULL_FUNC,			--发送新好友给好友管理器
		net_broadcastdesk_toplay				= NULL_FUNC,			--广播加好友成功动画
		set_user_friend_info					= NULL_FUNC,			--设置好友管理器玩家信息
		net_OnRecvCheckUserOnline				= NULL_FUNC,			--收到请求玩家在线情况
		
		CONFIG = _S
		{
			MAXFRIEND = 1000,--最大好友数量控制
			LIMIT = 20,--发送好友每次数量限制
		}
	}
end

friendlib.load_user_friend_info_from_sns = function(userinfo)
    --TraceError('load_user_friend_info_from_sns');
	--if true then return end
    --所有合作伙伴都能加好友，改一下
	if true or userinfo.nRegSiteNo == 0 or userinfo.nRegSiteNo == 1 then
        --登陆时读好友前先更新好友
        --local url = "http://121.9.221.7:8080/GetBuddylist.php?uid=-1"    --userinfo.passport
		
        --dblib.dourl(url, function(xml_info)
	   
            --local success, yy_friends_uids = xpcall(function() return friendlib.friendxml_to_table(xml_info) end, throw)
            local success=true;
            local yy_friends_uids="";
            
            if success then
                --更新好友
                
                if yy_friends_uids == "" then
                    yy_friends_uids = dblib.tosqlstr(yy_friends_uids)
                end
                local szSql = format(friendlib.sql.getFriendsIdList, yy_friends_uids, userinfo.nRegSiteNo)
                dblib.execute(szSql, function(dt)
                    if dt and #dt >= 0 then
                        local snsfriend = {}
                        local len = #dt
                        local snsnum = 0
                        local gamenum = 0
                        if len >= friendlib.CONFIG.MAXFRIEND then
                            --记录超过好友最大上限的日志
                            dblib.execute(string.format(friendlib.sql.log_user_maxfriend,userinfo.userId,len))
                            
                            len = friendlib.CONFIG.MAXFRIEND 
                            snsnum = len
                            
                            for i = 1, len  do
                                if tonumber(dt[i]["id"]) and tonumber(dt[i]["id"]) ~= tonumber(userinfo.userId) then
                                    snsnum = snsnum + 1
                                    table.insert(snsfriend, tostring(dt[i]["id"]))
                                end
                            end
                            
                            --写入内存
                            local szSnsfriend = "|"..table.concat(snsfriend,"|").."|"
                            friendlib.write_friendinfo_to_ram(userinfo,"", szSnsfriend)
                            --写入数据库
                            --dblib.execute(string.format(friendlib.sql.update_user_friends_info,dblib.tosqlstr(szSnsfriend),dblib.tosqlstr(""),userinfo.userId))
                        else
                            --去掉牌友中存在的Y友
                            local sql = format(friendlib.sql.get_user_friends_sql,userinfo.userId)
                            dblib.execute(sql, function(dt1)
                                if dt1 and #dt1 >= 0 then
                                    snsnum = len
                                    local friendsstr = ""
                                    
                                    if dt1[1].friends and string.len(dt1[1].friends) ~= 0 then
                                        --判断第一个字母是不是|不是的话加上
                                        if string.sub(dt1[1].friends,1,1) ~= "|"then
                                          dt1[1].friends = "|"..dt1[1].friends
                                          --更新数据可
                                          dblib.execute(string.format(friendlib.sql.update_user_friends_info_only,dblib.tosqlstr(dt1[1].friends),userinfo.userId),nil,userinfo.userId)
                                        end
                                        
                                        local tFriend = split(dt1[1].friends, "|")
                                        
                                        --如果同时是YY好友，又是牌友，去掉重复了的牌友
                                        local tmpTable = {}
                                        for k,v in pairs(tFriend) do
                                            if(tonumber(v) ~= nil)then
                                                tmpTable[tostring(v)] = v
                                            end
                                        end
                                        
                                        for i = 1,#dt do
                                            local v = dt[i]["id"]
                                            if(tonumber(v) ~= nil)then
                                                tmpTable[tostring(v)] = v
                                            end
                                        end
                                        
                                        local friendlist = {}
                                        for _,uid in pairs(tmpTable) do
                                            if(tonumber(uid) ~= userinfo.userId)then
                                                table.insert(friendlist, uid)
                                                gamenum = gamenum + 1
                                            end
                                        end
                                        
                                        friendsstr = "|"..table.concat(friendlist, "|").."|"
                                        
                                        if gamenum + len > friendlib.CONFIG.MAXFRIEND then
                                            --记录超过好友最大上限的日志
                                            dblib.execute(string.format(friendlib.sql.log_user_maxfriend,userinfo.userId,gamenum + len))
                                        
                                            gamenum = friendlib.CONFIG.MAXFRIEND - len
                                        end
                                    else
                                        --TraceError("玩家没有游戏好友")
                                    end
    	
                                    for i = 1, len  do
                                        if tonumber(dt[i]["id"]) and tonumber(dt[i]["id"]) ~= tonumber(userinfo.userId) then
                                            snsnum = snsnum + 1
                                            table.insert(snsfriend, tostring(dt[i]["id"]))
                                        end
                                    end
                                    --写入内存
                                    local szSnsfriend = "|"..table.concat(snsfriend,"|").."|"
                                    friendlib.write_friendinfo_to_ram(userinfo,friendsstr,szSnsfriend)
                                    --写入数据库
                                    --dblib.execute(string.format(friendlib.sql.update_user_friends_info,dblib.tosqlstr(szSnsfriend),dblib.tosqlstr(friendsstr),userinfo.userId))
                                else
                                    TraceError("数据异常,没有该玩家的好友记录")
                                end
                            end)
                        end

                        --记录好友总量日志
                        local userid = userinfo.userId
                        --dblib.execute(string.format(friendlib.sql.log_user_friend_num,userid,gamenum,snsnum,userid));
                    else
                        TraceError("读取玩家YY好友异常")
                    end
                end)
            else
                TraceError("获取yy好友信息数据错误")
            end
       -- end)
    end
end

friendlib.friendxml_to_table = function(xml_info)
	if (type(xml_info) ~= "string") then
		TraceError("为啥xml为空")
		return "", ""
    end
    --检测xml文件是否合法
    if (string.find(xml_info, [[xml version="1.0" encoding="UTF"]]) == nil) then
        TraceError("xml数据不合法"..xml_info)
		return "", ""
    end

    local users_friend = {}
    local friend_uids_list = {}
    local user_friend_uids = ""
    local strlen = 0  --防止字符串超长
    local find = false
    --解析yy好友信息
    for w in string.gmatch(xml_info, [[<uid>[%d]+</uid>%s+<imid>[%d]+</imid>]]) do
    	local uid = string.match(w, [[<uid>([%d]+)</uid>]])
    	local imid = string.match(w, [[<imid>([%d]+)</imid>]])
    	local users_item = {uid=uid, imid=imid}
    	if (tonumber(uid) ~= nil and imid ~= nil) then
            if(strlen < 14000)then
        		users_friend[tonumber(uid)] = users_item
        		table.insert(friend_uids_list, "'"..tostring(uid).."'")
                strlen = strlen + string.len(tostring(uid)) + 1  --uid和",",
            end
    	end
    	find = true
    end
    --解析自己的信息
    if (find == false) then
        for w in string.gmatch(xml_info, [[<id>[%d]+</id>%s+<imid>[%d]+</imid>]]) do
        	local id = string.match(w, [[<id>([%d]+)</id>]])
        	local imid = string.match(w, [[<imid>([%d]+)</imid>]])
        	local users_item = {id=id, imid=imid}
        	if (tonumber(id) ~= nil and imid ~= nil) then
                if(strlen < 14000)then
            		users_friend[tonumber(id)] = users_item
            		table.insert(friend_uids_list, "'"..tostring(uid).."'")
                    strlen = strlen + string.len(tostring(uid)) + 1  --uid和",",
                end
        	end
        end
    end

    --friend_uids_list必须是数组
    user_friend_uids = table.concat(friend_uids_list,",")
	return user_friend_uids
end

friendlib.write_friendinfo_to_ram = function(userinfo,gamefriend,snsfriend)
	local tabgf = split(gamefriend,"|")
	local tabsnsf = split(snsfriend,"|")
	--TraceError(tabsnsf)
	userinfo.friends = {}
	local friendcount = 0
	--游戏好友
	for k,v in pairs(tabgf) do
		if tonumber(v) ~= nil then
			userinfo.friends[tonumber(v)] = {}
			userinfo.friends[tonumber(v)].friendType = 0
			friendcount = friendcount + 1
		end
	end
	--SNS好友
	for k,v in pairs(tabsnsf) do
		if tonumber(v) ~= nil then
			userinfo.friends[tonumber(v)] = {}
			userinfo.friends[tonumber(v)].friendType = 1
			friendcount = friendcount + 1
		end
	end

	--记录此玩家的好友数量
	userinfo.extra_info["F06"] = friendcount
	save_extrainfo_to_db(userinfo)

	--TraceError("所有好友列表 " .. tostringex(userinfo.friends))
	--通知其他好友我上线了
	friendlib.change_userstate_tofriend(userinfo,1)

  friendlib.send_user_allfriend_info(userinfo,0)--0所有在线好友
end

friendlib.send_user_allfriend_info = function(userinfo,nType)
	ASSERT(userinfo, 'userinfo nil')
	if not userinfo.friends then return end

    local tPack = {}
	local tSendPacks = { [1] = tPack }
	local friendsNum = 0
	for k, v in pairs(userinfo.friends) do
		if table.getn(tPack) == friendlib.CONFIG.LIMIT then
			tPack = {}
			tSendPacks[table.getn(tSendPacks) + 1] = tPack
		end
		local info
		if nType == 0 then
			info = usermgr.GetUserById(tonumber(k))
			if info and info.friends then--防止异步
				friendsNum = friendsNum + 1--好友数量
				tPack[table.getn(tPack) + 1] = info
			end
		else
			info = userinfo.friends[tonumber(k)].userinfo
			if info then
				friendsNum = friendsNum + 1--好友数量
				tPack[table.getn(tPack) + 1] = info
			end
		end
	end

	local sendUserFriendOnLinePack = function(userinfo, tPack)
		if table.getn(tPack) ~= 0 then
			netlib.send(
				function(outBuf)
					outBuf:writeString("FDSENDOL")
					for k, v in ipairs(tPack) do
						local ntype = 0
						local deskinfo = {}
						if v.desk and v.desk > 0 then
							ntype = 1
							table.insert(deskinfo,desklist[v.desk].smallbet)
							table.insert(deskinfo,desklist[v.desk].largebet)
                            table.insert(deskinfo,desklist[v.desk].channel_id or -1)
							table.insert(deskinfo,v.desk)
							table.insert(deskinfo,desklist[v.desk].desktype)
						end
						local vip_level = 0
						if viplib and viplib.get_vip_level(v) then
							vip_level = viplib.get_vip_level(v)
                        end
                      
						outBuf:writeInt(v.userId)
						outBuf:writeString(v.nick or "")
						outBuf:writeString(v.imgUrl or "")
						outBuf:writeByte(vip_level)--是否为VIP
						outBuf:writeByte(ntype)--0大厅,1在牌桌
                        outBuf:writeInt(v.channel_id or -1) --这个用户的频道属性
                        outBuf:writeInt(v.channel_role or 0);
                        outBuf:writeInt(v.sex);
                        outBuf:writeInt(v.home_status or 0);
                        
						outBuf:writeByte(#deskinfo)
						for k,v in pairs(deskinfo) do
							outBuf:writeInt(v)
						end
					end
					outBuf:writeInt(0)
				end,userinfo.ip,userinfo.port)
        end
	end

	local sendUserFriendAllPack = function(userinfo, tPack)
       
        local vip_level = 0
        --TraceError(tPack)
		if table.getn(tPack) ~= 0 then
			netlib.send(
				function(outBuf)
					outBuf:writeString("FDSENDALL")
					for k, v in ipairs(tPack) do
						outBuf:writeInt(v.userid)
						outBuf:writeString(v.nick or "")
						outBuf:writeString(v.face or "")
						outBuf:writeInt(v.level or 0)
						outBuf:writeInt(v.gold or 0)
						outBuf:writeByte(v.friendType)
						outBuf:writeByte(v.viplevel)
					end
					outBuf:writeInt(0)
				end,userinfo.ip,userinfo.port)
        end
    end

    for k, v in ipairs(tSendPacks) do
		if nType == 0 then
			sendUserFriendOnLinePack(userinfo, v)
		else
			sendUserFriendAllPack(userinfo, v)
		end
	end
	
	--发送自己当前好友数量结束读取
    local ntfdFun = function(outBuf)
        outBuf:writeString("FDSENDEND")
        outBuf:writeInt(friendsNum)
		outBuf:writeByte(nType)--0在线--1所有
    end

    netlib.send(ntfdFun,userinfo.ip,userinfo.port)
end

friendlib.change_userstate_tofriend = function(userinfo,nType)
	ASSERT(userinfo, 'userinfo nil')
	if not userinfo.friends then
		return
	end
	--TraceError("状态变化 nType = " .. nType)
	--TraceError("userinfo 的 ID " .. userinfo.userId)
	for k,v in pairs(userinfo.friends) do
		local touserinfo = usermgr.GetUserById(tonumber(k))

		if touserinfo and touserinfo.friends then--防止异步执行
			--TraceError("好友 的 ID " .. touserinfo.userId)
			if nType == 1 then--上线特殊和加好友一样
				--TraceError("上线了")
				local deskinfo = {}
				local nType = 0 
				if userinfo.desk and userinfo.desk > 0 then
					nType = 1
					table.insert(deskinfo,desklist[userinfo.desk].smallbet)
					table.insert(deskinfo,desklist[userinfo.desk].largebet)
                    table.insert(deskinfo,desklist[userinfo.desk].channel_id or -1)
					table.insert(deskinfo,userinfo.desk)
					table.insert(deskinfo,desklist[userinfo.desk].desktype)
				end

				friendlib.send_newfriend_info(touserinfo,userinfo,nType,deskinfo)--通知好友自己上线了
			else
				--TraceError("其他状态 nType" .. nType)
				friendlib.do_change_userstate_tofriend(userinfo,touserinfo,nType)
			end
		end
	end
end

friendlib.do_change_userstate_tofriend = function(userinfo,friendinfo,nType)
	local deskinfo = {}
	if nType == 3 then
		table.insert(deskinfo,desklist[userinfo.desk].smallbet)
		table.insert(deskinfo,desklist[userinfo.desk].largebet)
        table.insert(deskinfo,desklist[userinfo.desk].channel_id or -1)
		table.insert(deskinfo,userinfo.desk)
		table.insert(deskinfo,desklist[userinfo.desk].desktype)
	end

	netlib.send(
		function(buf)
			buf:writeString("FDSENDSTATE")
			buf:writeInt(userinfo.userId)
			buf:writeByte(nType)--0离线,2牌桌到大厅,3大厅到牌桌
			buf:writeByte(#deskinfo)
			for k,v in pairs(deskinfo) do
				buf:writeInt(v)
			end
		end,friendinfo.ip,friendinfo.port)
end

friendlib.net_OnRecvInviteFriendJoin = function(buf)
	local userKey = getuserid(buf)
    local userinfo = userlist[userKey]
	if not userinfo then return end
	if not userinfo.friends then return end

	if not userinfo.desk or userinfo.desk <= 0 then
		--TraceError("自己不在桌子上还邀请其他人加入??")
		return
	end

	local inviteuserid = buf:readInt()
	if not usermgr.GetUserById(inviteuserid) or not userinfo.friends[inviteuserid] then
		--TraceError("不在线的用户或不是自己的好友")
		return
	end

	local inviteuserinfo = usermgr.GetUserById(inviteuserid)
	
	netlib.send(
		function(buf)
			buf:writeString("FDSENDINVITE")
			buf:writeByte((inviteuserinfo.site and inviteuserinfo.site > 0) and 1 or 0)--是否正在玩1在玩，0没玩
			buf:writeString(userinfo.nick or "")
			buf:writeInt(desklist[userinfo.desk].smallbet)
			buf:writeInt(desklist[userinfo.desk].largebet)
			buf:writeInt(userinfo.desk)
            buf:writeInt(userinfo.channel_id or -1)
            buf:writeInt(desklist[userinfo.desk].desktype)
		end,inviteuserinfo.ip,inviteuserinfo.port)
end

friendlib.net_OnRecvShowAddFriend = function(buf)
	local userKey = getuserid(buf)
	local userinfo = userlist[userKey]
	if not userinfo then return end
	if not userinfo.friends then return end

	if not userinfo.site or userinfo.site <= 0 then
		--TraceError("自己不在坐下，不能加别人好友")
		return
	end

	local clickid = buf:readInt()
    --[[
    if (duokai_lib and duokai_lib.is_sub_user(clickid) == 1) then
        clickid = duokai_lib.get_parent_id(clickid)
    end
    --]]
	local clickuserinfo = usermgr.GetUserById(clickid)
	if not clickuserinfo then 
		--TraceError("clickuserinfo nil")
		return 
	end
	if not clickuserinfo.site or clickuserinfo.site <= 0 then
		--TraceError("别人没坐下，不能加别人好友")
		return
	end

    if(duokai_lib and duokai_lib.is_sub_user(clickid) == 1) then
        clickid = duokai_lib.get_parent_id(clickid)
    end
	if userinfo.friends[clickid] then
		--TraceError("已经是自己的好友了")
		return
	end

	--检查自己和对方的好友人数
	--if #userinfo.friends >= friendlib.CONFIG.MAXFRIEND then
	local myfriendcount = userinfo.extra_info["F06"] or 0
	local hisfriendcount = clickuserinfo.extra_info["F06"] or 0
	local limitcount = friendlib.CONFIG.MAXFRIEND
	if myfriendcount > limitcount or hisfriendcount > limitcount then
		--TraceError("再增加好友将超过上限")
		return
	end
	
	--如果玩家有拒绝列表
	if clickuserinfo.refuselist and #clickuserinfo.refuselist > 0 then
		local num = 0
		for k,v in pairs(clickuserinfo.refuselist) do
			if tonumber(v) == tonumber(userinfo.userId) then
				num = 1
				break
			end
		end

		if num == 1 then
			--TraceError("当前点击的玩家已经拒绝了自己")
			return
		end
	end
	
	--发送可以显示了
    --TraceError('okdkjkdd')
	netlib.send(
		function(buf)
			buf:writeString("FDSENDSHOWADD")
		end,userinfo.ip,userinfo.port)
end

friendlib.net_OnRecvChangeFriendInfo = function(buf)
    --TraceError('net_onRecChagneFreindInfo');
	local userKey = getuserid(buf)
	local userinfo = userlist[userKey]
	if not userinfo then return end
	if not userinfo.friends then return end
	
	local changetype = buf:readByte()--更改类型,0删除,1增加,2拒绝
	local changeid = buf:readInt()--邮件的始发人from 

	if changeid == userinfo.userId then
		TraceError("想加自己啊")
		return
	end

	if changetype ~= 0 then
		local szMd5 = buf:readString()

		local szMd5Check = string.md5(tostring(changeid) .. tostring(userinfo.userId) .. "OY^_^OY")

		if szMd5 ~= szMd5Check then
			TraceError("验证没有通过")
			return
		end
	end

	if changetype == 0 then
		if not userinfo.friends[tonumber(changeid)] then
			--TraceError("不是自己好友非法删除")
			friendlib.net_send_changeresult(userinfo,0,0,changeid)
			return
		end

		friendlib.do_delete_userfriend_byid(userinfo,changeid)
	elseif changetype == 1 then
		if userinfo.friends[tonumber(changeid)] then
			--TraceError("已经是自己好友非法添加")
			friendlib.net_send_changeresult(userinfo,1,0,changeid)
			return
		end
		
		--检查好友数量是否超过限制
		local touserinfo = usermgr.GetUserById(changeid)
		if(not touserinfo) then
			--TraceError("加鬼啊，人都不在线...")
			friendlib.net_send_changeresult(userinfo,1,0,changeid)
			return
		end
		local myfriendcount = userinfo.extra_info["F06"] or 0
		local hisfriendcount = touserinfo.extra_info["F06"] or 0
		local limitcount = friendlib.CONFIG.MAXFRIEND
		if myfriendcount > limitcount or hisfriendcount > limitcount then
			--TraceError("再增加好友将超过上限")
			friendlib.net_send_changeresult(userinfo,1,0,changeid)
			return
        end

        if userinfo.site and userinfo.site > 0 then 
            friendlib.do_add_userfriend_byid(userinfo,changeid)
    	end
	else
		if not userinfo.refuselist then--拒绝列表不存在
			userinfo.refuselist = {}--创建
			table.insert(userinfo.refuselist,changeid)
			return
		end

		local num = 0
		for k,v in pairs(userinfo.refuselist) do
			if tonumber(v) == tonumber(changeid) then
				num = 1
				break
			end
		end

		if num == 0 then
			table.insert(userinfo.refuselist,changeid)
		end
	end
end

friendlib.net_OnRecvCheckUserOnline = function(buf)
	local userKey = getuserid(buf)
	local myInfo = userlist[userKey]
	if not myInfo then return end

	local user_id = buf:readInt(); --收到需要查询的用户ID
	local userinfo = usermgr.GetUserById(user_id)
	local is_online = 0; --是否在线0：不在线， 1在线
	if userinfo ~= nil then
		is_online = 1;
	end
	--通知客户端用户在线情况
	netlib.send(
		function(buf)
			buf:writeString("PHUOS")
			buf:writeByte(is_online)--是否在线
			buf:writeInt(user_id)	--需要查询的用户ID
		end,myInfo.ip,myInfo.port)
end

friendlib.do_delete_userfriend_byid = function(userinfo,delid)
    if not userinfo then return end
    if not userinfo.friends then return end
    
    --删除别人
    userinfo.friends[tonumber(delid)] = nil
	friendlib.net_send_changeresult(userinfo,0,1,delid)
    --拒绝列表中删除
    if type(userinfo.refuselist) == "table" then
        for i=1,#userinfo.refuselist do
            if(userinfo.refuselist[i] == delid)then
                userinfo.refuselist[i] = nil
                break
            end
        end
    end
    --更新此玩家的好友数量
    userinfo.extra_info["F06"] = userinfo.extra_info["F06"] - 1
    save_extrainfo_to_db(userinfo)
    
    local deluserinfo = usermgr.GetUserById(delid)
    
    --别人在线，要把自己删除--处理为离线
    if deluserinfo then
        deluserinfo.friends[tonumber(userinfo.userId)] = nil
        friendlib.net_send_changeresult(deluserinfo,0,1,userinfo.userId)
        --拒绝列表中删除
        if type(deluserinfo.refuselist) == "table" then
            for i=1,#deluserinfo.refuselist do
                if(deluserinfo.refuselist[i] == userinfo.userId)then
                    deluserinfo.refuselist[i] = nil
                    break
                end
            end
        end
        --更新另一个玩家的好友数量
        deluserinfo.extra_info["F06"] = deluserinfo.extra_info["F06"] - 1
        save_extrainfo_to_db(deluserinfo)
    
        friendlib.do_change_userstate_tofriend(userinfo,deluserinfo,0)
    
        friendlib.do_change_userstate_tofriend(deluserinfo,userinfo,0)--我的在线好友中删除之
    end
	
    --记录删除日志
    dblib.execute(string.format(friendlib.sql.log_user_delfriend,userinfo.userId,delid))
    
    --写入数据库
    local usergamestr = "|" .. tostring(delid) .. "|"
    dblib.execute(string.format(friendlib.sql.updateuserdelgamefriend,dblib.tosqlstr(usergamestr),userinfo.userId))
    
    --写入数据库
    local delgamestr = "|" .. tostring(userinfo.userId) .. "|"
    dblib.execute(string.format(friendlib.sql.updateuserdelgamefriend,dblib.tosqlstr(delgamestr),delid))
end

friendlib.do_add_userfriend_byid = function(userinfo,addid)
	if not userinfo then return end
	if not userinfo.friends then return end
	
	local adduserinfo = usermgr.GetUserById(addid)

	--通知加好友成功了
	friendlib.net_send_changeresult(userinfo,1,1,addid)

    --通知五道杠模块，这个人今天有加过好友
    if (tex_dailytask_lib) then
        xpcall(function()tex_dailytask_lib.set_addfriend_status(adduserinfo) end,throw)
    end
    
  	--通知达人家园更新好友  
    if (dhomelib) then
        xpcall(function()dhomelib.notify_add_friend(userinfo.userId,adduserinfo.userId) end,throw)
    end
    
	eventmgr:dispatchEvent(Event("add_friend",	_S{to_user_info=userinfo, from_user_info=adduserinfo}));

	--更新此玩家的好友数量
	userinfo.extra_info["F06"] = userinfo.extra_info["F06"] + 1
	save_extrainfo_to_db(userinfo)

	--游戏好友
	userinfo.friends[tonumber(addid)] = {}
	userinfo.friends[tonumber(addid)].friendType = 0

	if adduserinfo then

		local ntype = 0 
		local deldeskinfo = {}
		if adduserinfo.desk and adduserinfo.desk > 0 then --在桌子里
			--通知加好友成功了
			friendlib.net_send_changeresult(adduserinfo,1,1,addid)
			--更新另一个玩家的好友数量
			adduserinfo.extra_info["F06"] = adduserinfo.extra_info["F06"] + 1
			save_extrainfo_to_db(adduserinfo)

			ntype = 1
			table.insert(deldeskinfo,desklist[adduserinfo.desk].smallbet)
			table.insert(deldeskinfo,desklist[adduserinfo.desk].largebet)
            table.insert(deldeskinfo,desklist[adduserinfo.desk].channel_id or -1)
			table.insert(deldeskinfo,adduserinfo.desk)
            table.insert(deldeskinfo,desklist[adduserinfo.desk].desktype)
		end

		friendlib.send_newfriend_info(userinfo,adduserinfo,ntype,deldeskinfo)--告诉自己,好友的状况
		
		local mydeskinfo = {}
		table.insert(mydeskinfo,desklist[userinfo.desk].smallbet)
		table.insert(mydeskinfo,desklist[userinfo.desk].largebet)
        table.insert(mydeskinfo,desklist[userinfo.desk].channel_id or -1)
		table.insert(mydeskinfo,userinfo.desk)
		table.insert(mydeskinfo,desklist[userinfo.desk].desktype)
		friendlib.send_newfriend_info(adduserinfo,userinfo,1,mydeskinfo)--告诉好友,自己的状况

		--设置好友管理信息
		friendlib.set_user_friend_info(userinfo,adduserinfo,addid)

		--游戏好友
		adduserinfo.friends[tonumber(userinfo.userId)] = {}
		adduserinfo.friends[tonumber(userinfo.userId)].friendType = 0

		--设置好友管理信息
		friendlib.set_user_friend_info(adduserinfo,userinfo,userinfo.userId)

		--发送更新好友管理信息
		friendlib.send_newfriend_info_tomanager(userinfo,userinfo.friends[tonumber(addid)].userinfo)

		--发送更新好友管理信息
		friendlib.send_newfriend_info_tomanager(adduserinfo,adduserinfo.friends[tonumber(userinfo.userId)].userinfo)
	else
		--好友离线了，去数据库查
		dblib.execute(string.format(friendlib.sql.getuserinfofromdb,tonumber(addid)),
			function(dt)
				if dt and #dt > 0 then
					local frieninfo = table.clone(dt[1])
					frieninfo["viplevel"] = 0
					local id = frieninfo["userId"]
					dblib.execute(string.format(friendlib.sql.getuservipinfo,tonumber(id)),
						function(dtt)
							if dtt and #dtt > 0 then
								--frieninfo["viplevel"] = dtt[1]["vip_level"] > 0 and 1 or 0
                                				frieninfo["viplevel"] = dtt[1]["vip_level"]
							end

							friendlib.set_user_friend_info(userinfo,frieninfo,id)
							--发送更新好友管理信息
							friendlib.send_newfriend_info_tomanager(userinfo,userinfo.friends[tonumber(id)].userinfo)
						end)
				end
			end)
	end
	
	--在桌子上广播加好友动画
	friendlib.net_broadcastdesk_toplay(userinfo,addid)

	--记录加好友日志
	dblib.execute(string.format(friendlib.sql.log_user_addfriend,userinfo.userId,addid))

	--写入数据库
	local usergamestr = tostring(addid) .. "|"
	dblib.execute(string.format(friendlib.sql.updateuseraddgamefriend,dblib.tosqlstr(usergamestr),userinfo.userId))

	--写入数据库
	local delgamestr = tostring(userinfo.userId) .. "|"
	dblib.execute(string.format(friendlib.sql.updateuseraddgamefriend,dblib.tosqlstr(delgamestr),addid))
end

friendlib.send_newfriend_info_tomanager = function(userinfo,friendinfo)
	netlib.send(
		function(buf)
			buf:writeString("FDSENDTOMGR")
			buf:writeInt(friendinfo.userid)
			buf:writeString(friendinfo.nick or "")
			buf:writeString(friendinfo.face or "")
			buf:writeInt(friendinfo.level)
			buf:writeInt(friendinfo.gold)
			buf:writeByte(friendinfo.friendType)
			buf:writeByte(friendinfo.viplevel)--是否为VIP
		end,userinfo.ip,userinfo.port)
end

friendlib.net_send_changeresult = function(userinfo,addordel,result,changeID)
	netlib.send(
		function(buf)
			buf:writeString("FDSENDRESULT")
			buf:writeByte(addordel)--0删除，1增加
			buf:writeByte(result)--0失败，1成功
            buf:writeInt(changeID)  --被操作玩家ID
		end,userinfo.ip,userinfo.port)
end

friendlib.net_broadcastdesk_toplay = function(userinfo,addid)
	netlib.broadcastdesk(
		function(buf)
			buf:writeString("FDSENDPLAY")
			buf:writeInt(userinfo.userId)--接受方
			buf:writeInt(addid)--发送方
		end,userinfo.desk,borcastTarget.all)
end

friendlib.send_newfriend_info = function(userinfo,newfriend,ntype,info)
    --TraceError('to userid'..userinfo.userId..' friend id'..newfriend.userId);
	local vip_level = 0
	if viplib and viplib.get_vip_level(newfriend) then
		vip_level = viplib.get_vip_level(newfriend)	
	end
	netlib.send(
		function(buf)
			buf:writeString("FDSENDNEWOL")
			buf:writeInt(newfriend.userId)
			buf:writeString(newfriend.nick or "")
			buf:writeString(newfriend.imgUrl or "")
			buf:writeByte(vip_level)--是否为VIP
			buf:writeByte(ntype)--0大厅--1牌桌
			buf:writeInt(newfriend.channel_id or -1)
            buf:writeInt(newfriend.channel_role or 0);
            buf:writeInt(newfriend.sex or 0);
            buf:writeInt(newfriend.home_status or 0);            
			buf:writeByte(#info)	
			for i = 1,#info do
				buf:writeInt(info[i])
			end
		end,userinfo.ip,userinfo.port)
end

--设置玩家好友管理信息
friendlib.set_user_friend_info = function(userinfo,friendinfo,friendid)
	if not userinfo then return end
	local userlevle = 0
	if friendinfo.level then
		userlevle = friendinfo.level
	else
		userlevle = usermgr.getlevel(friendinfo)
	end

    local vip_level = 0
    if(viplib and usermgr.GetUserById(friendinfo.userId) ~= nil) then
        vip_level = viplib.get_vip_level(usermgr.GetUserById(friendinfo.userId))
    else
        vip_level = friendinfo.viplevel
    end

    local isvip = (vip_level > 0) and 1 or 0

	userinfo.friends[tonumber(friendid)].userinfo = {}
	userinfo.friends[tonumber(friendid)].userinfo["userid"] = friendinfo.userId
	userinfo.friends[tonumber(friendid)].userinfo["nick"] = friendinfo.nick
	userinfo.friends[tonumber(friendid)].userinfo["face"] = friendinfo.imgUrl
	userinfo.friends[tonumber(friendid)].userinfo["level"] = userlevle
	userinfo.friends[tonumber(friendid)].userinfo["gold"] = friendinfo.gamescore
	userinfo.friends[tonumber(friendid)].userinfo["isvip"] = isvip
    	userinfo.friends[tonumber(friendid)].userinfo["viplevel"] = vip_level
	userinfo.friends[tonumber(friendid)].userinfo["friendType"] = userinfo.friends[tonumber(friendid)].friendType
end

friendlib.net_OnRecvGetAllFriendInfo = function(buf)
	--TraceError("这里有人用吗")
	local userKey = getuserid(buf)
    local userinfo = userlist[userKey]
	if not userinfo then return end
	if not userinfo.friends then return end
  --if not userinfo.mobile_mode then return end;
  if userinfo.init_friend_finsh == 1 then 
    --friendlib.send_user_allfriend_info(userinfo,1) 
    return 
  end

	local leavefriendidlist = {}
	
	for k,v in pairs(userinfo.friends) do
		local friendinfo = usermgr.GetUserById(tonumber(k))

		if not friendinfo then--得到离线好友列表
			table.insert(leavefriendidlist,tonumber(k))
		else
			friendlib.set_user_friend_info(userinfo,friendinfo,k)
		end			 
	end

	--好友都在线
	if #leavefriendidlist <= 0 then
		friendlib.send_user_allfriend_info(userinfo,1)--1得到所有好友列表
	else --这块的逻辑怀疑以前有问题，这里只会发已离线的好友情况，不包含在线的好友，翼锋说IOS版本要用到这个，先这样处理了，保持跟以前逻辑一样，只优化性能(以前是循环调数据库，现在一条语句搞定
		local leave_ids = ""
		for k,v in pairs(leavefriendidlist) do
			if leave_ids == "" then
				leave_ids = v
			else
				leave_ids = leave_ids..","..v
			end
		end
		
		local sql = "select userid as userId,nick_name as nick,face as imgUrl,gold as gamescore,level,vip_level AS viplevel from users a left join user_tex_info b on a.id = b.userid left join user_vip_info c on a.id = c.user_id where  a.id in (%s) limit 1000;"
		sql = string.format(sql, leave_ids)
		dblib.execute(sql, function(dt)		
			if dt and #dt > 0 then
				for i = 1, #dt do
					local frieninfo = table.clone(dt[i])
					friendlib.set_user_friend_info(userinfo,frieninfo,frieninfo["userId"])
				end
			end
				friendlib.send_user_allfriend_info(userinfo,1)
				userinfo.init_friend_finsh = 1
		end)
	end
end

friendlib.net_OnRecvJoinFriendDesk = function(buf)
	local userKey = getuserid(buf)
  local userinfo = userlist[userKey]
	if not userinfo then return end
	if not userinfo.friends then return end

	local deskno = buf:readInt()
	--local joinid = buf:readInt()--好友ID--可以是邀请人的ID，也可以是被加入人的ID

	local deskinfo = desklist[deskno]
	if not deskinfo then
		TraceError("不存在的桌子号" .. deskno)
		return
	end
	
	--[[
	if not userinfo.friends[tonumber(joinid)] then
		TraceError("想开特权进入不是好友的桌子中??")
		return
	end
	--]]	
    if deskinfo.desktype == g_DeskType.VIP then--想进的是VIP场
		if viplib and not viplib.check_user_vip(userinfo) then
			netlib.send(
				function(buf)
					buf:writeString("FDJOINFAIL")
				end,userinfo.ip,userinfo.port)
			return
		end
	end

	DoRecvRqWatch(userinfo, deskno, 1)
end

friendlib.net_OnRecvWantToAddFriend = function(buf)
	local userKey = getuserid(buf)
    local userinfo = userlist[userKey]
	if not userinfo then return end
	if not userinfo.friends then return end
	if not (userinfo.site and userinfo.site > 0) then 
		--TraceError("不在座位上想加人?")
		return 
	end
	local touserid = buf:readInt()
	local touserinfo = usermgr.GetUserById(touserid)

	if not touserinfo then return end
	if not (touserinfo.site and touserinfo.site > 0) then 
		--TraceError("被加的人不在座位上？怎么点的？")
		return 
	end
	
	if userinfo.desk and touserinfo.desk then
		if userinfo.desk ~= touserinfo.desk then
			TraceError("不在一个桌子?")
			return
		end
	end

	if userinfo.friends[tonumber(touserid)] then
		TraceError("net_OnRecvWantToAddFriend 已经是自己好友还能加?")
		return
	end
	--派发想添加某人为好友
	eventmgr:dispatchEvent(Event("want_add_friend",	{to_user_info=touserinfo, from_user_info=userinfo}));
	
	if not touserinfo.refuselist then--拒绝列表不存在
		touserinfo.refuselist = {}--创建
		table.insert(touserinfo.refuselist,userinfo.userId)
	else
		local num = 0
		for k,v in pairs(touserinfo.refuselist) do
			if tonumber(v) == tonumber(userinfo.userId) then
				num = 1
				break
			end
		end
	
		if num == 0 then
			table.insert(touserinfo.refuselist,userinfo.userId)
		end
	end

	--make md5
    local szMd5 = string.md5(tostring(userinfo.userId) .. tostring(touserinfo.userId) .. "OY^_^OY")
    --send request to another user
    local sendFun = function(outBuf)
        outBuf:writeString("FDSENDCANADD")
        outBuf:writeString(szMd5)
        outBuf:writeInt(touserinfo.userId)
        outBuf:writeInt(userinfo.userId)
        outBuf:writeString(userinfo.nick)
	end
	--播动画了
	netlib.broadcastdeskex(sendFun,userinfo.desk,borcastTarget.all)
end

--命令列表
cmdHandler = 
{
  ["FDRQYQHY"] = friendlib.net_OnRecvInviteFriendJoin,         --收到请求邀请某个好友加入牌桌
  ["FDRQTJHY"] = friendlib.net_OnRecvShowAddFriend,            --收到请求能否显示添加该好友按钮
  ["FDRQZJHY"] = friendlib.net_OnRecvChangeFriendInfo,         --收到修改好友信息请求
  ["FDRQAFIF"] = friendlib.net_OnRecvGetAllFriendInfo,         --收到得到所有好友信息请求
  ["FDRQJOIN"] = friendlib.net_OnRecvJoinFriendDesk,			 --收到请求加入好友桌子
  ["FDRQWTAD"] = friendlib.net_OnRecvWantToAddFriend,			 --收到玩家想加某人好友
  ["PHUOS"] 	 = friendlib.net_OnRecvCheckUserOnline,			 --收到查询玩家在线情况
}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end
