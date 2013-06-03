

tTexAchieveSqlTemplete =
{
    --得到成就配置相关数据
    getachieveconfigure = "select * from configure_achievement_info",

    --写日志记录玩家达成成就
    loguserachieveinfo = "insert into log_user_getachievement_info(userid,achieveid,gettime,currlevel,gamename,getprize) values(%d,%d,now(),%d,%s,%d);commit;",
}

tTexAchieveSqlTemplete = _S(tTexAchieveSqlTemplete)

if not achievelib then
    achievelib = {
        onuser_login = NULL_FUNC, --用户登录
        dogetuserachieveinfo = NULL_FUNC,--得到玩家的成就信息
        inituserachieveinfo = NULL_FUNC,--初始化玩家的成就信息
        loadStrFromTable = NULL_FUNC,--序列化表为一个字符串
        loadTableFromStr = NULL_FUNC,--把字符串转换为一个表
        setuserinfoandcache = NULL_FUNC,--写入内存和cache
        getcompleteachieve = NULL_FUNC,--得到当前完成的成就ID
        getlastachieveinfo = NULL_FUNC,--最近得到的成就ID
        giveuserprize = NULL_FUNC,--给用户发奖
        onrecvgetcompleteachieve = NULL_FUNC,--得到完成了的成就ID
        onrecvgetlastcompleteachieve = NULL_FUNC,--得到最近完成的成就ID
        onrecvgetprize = NULL_FUNC,--动画播放完成后发奖
        getcompleteachievefromdb = NULL_FUNC,--从数据库中得到完成了的成就ID

        net_send_user_completeachieve = NULL_FUNC,--用户完成成就
        net_send_user_lastgetachieve = NULL_FUNC,--最近得到的三个成就
        net_send_completenum = NULL_FUNC,--完成成就的个数
        net_send_completeid = NULL_FUNC,--完成成就的ID集合

        ACHIEVECFG_FROM_DB = {},
    }
    local initachievefromdb = function()
        timelib.createplan(function()
                dblib.execute(tTexAchieveSqlTemplete.getachieveconfigure,function(dt)
                        setAchieveCfg(dt)
                    end)
            end,2)
    end
    
    --从数据中读取成就配置
    initachievefromdb()
end

function setAchieveCfg(dt)
    --TraceError(dt)
    if dt and #dt > 0 then
        TraceError("读取成就系统配置成功")
        for k,v in pairs(dt) do
            achievelib.ACHIEVECFG_FROM_DB[v["id"]] = v
        end
    else
        TraceError("读取成就系统配置失败")
        --TraceError(dt)

    end
end

--初始化新玩家的成就信息
achievelib.inituserachieveinfo = function(userinfo)
    local tab = {}
    for k,v in pairs(achievelib.ACHIEVECFG_FROM_DB) do
        local cjinfo = {}
        cjinfo["countum"] = 0
        cjinfo["sumnum"] = 0
        cjinfo["isget"] = 0
        cjinfo["iscangive"] = 0
        cjinfo["gettime"] = 0
        tab[tonumber(v["id"])] = cjinfo
    end
    --TraceError(tostringex(tab))

    --写入cache和内存
    achievelib.setuserinfoandcache(userinfo,tab,0)
end


achievelib.loadStrFromTable = function(tab)
    local keys = {}
	local strRet = ""
	for k, v in pairs(tab) do
		table.insert(keys, k)
	end
	table.sort(keys)
	for i = 1, #keys do
		local strLine = keys[i] .. "|"
		local t = tab[keys[i]]
		strLine = strLine .. t.countum .. "|"
		strLine = strLine .. t.sumnum .. "|"
		strLine = strLine .. t.isget .. "|"
        strLine = strLine .. t.iscangive .. "|"
		strLine = strLine .. t.gettime .. ";"
		strRet = strRet .. strLine
	end
	return strRet
end

achievelib.loadTableFromStr = function(str)
    if not str or str == "" then return nil end

    if string.sub(str, 1, 2) == "do" then
		return table.loadstring(str)
	else
		local retTable = {}
		local data = split(str, ";")
		for i = 1, #data do
			if (string.len(data[i]) ~= 0) then
				local lines = split(data[i], "|")
				local t = {}
				t.countum 	= tonumber(lines[2])
				t.sumnum	= tonumber(lines[3])
				t.isget 	= tonumber(lines[4])
                t.iscangive	= tonumber(lines[5])
				t.gettime 	= tonumber(lines[6])
				retTable[tonumber(lines[1])] = t
			end
		end
		return retTable
	end
end

achievelib.dogetuserachieveinfo = function(userinfo,achieveinfo)
    if string.len(achieveinfo) ~= 0 then
        local tAchieveInfo = achievelib.loadTableFromStr(achieveinfo)
        --登陆时清空iscangive置0        
        for k,v in pairs(tAchieveInfo) do
            tAchieveInfo[k]["iscangive"] = 0
        end
       -- TraceError("achievelib.dogetuserachieveinfo" .. tostringex(tAchieveInfo))

        --写入内存和cache
        achievelib.setuserinfoandcache(userinfo,tAchieveInfo,0)
    else
        --TraceError("首次登陆")
        achievelib.inituserachieveinfo(userinfo)
    end
end

--写入cache和内存
achievelib.setuserinfoandcache = function(userinfo,tInfo,nType)
    if not userinfo then
        TraceError("没有用户信息")
        return 
    end
    
    if not nType then
        TraceError("没有设置nType类型")
        return
    end
    
    --写cache和内存
    if nType == 0 then
        if userinfo.achieveinfo == nil then
            userinfo.achieveinfo = {}
        end
        
        if tInfo then
            userinfo.achieveinfo = table.clone(tInfo)
        end

        if tInfo then
            dblib.cache_set(gamepkg.table,{achieve_info = achievelib.loadStrFromTable(tInfo)},"userid", userinfo.userId)
        end 
    elseif nType == 1 then--写内存
        if userinfo.achieveinfo == nil then
            userinfo.achieveinfo = {}
        end
        
        if tInfo then
            userinfo.achieveinfo = table.clone(tInfo)
        end
    else--写cache
        if tInfo then
            dblib.cache_set(gamepkg.table,{achieve_info = achievelib.loadStrFromTable(tInfo)},"userid", userinfo.userId)
        end 
    end
end

--得到当前完成成就ID情况
achievelib.getcompleteachieve = function(userinfo)
    local t = {}
    if userinfo.achieveinfo == nil then
        return t
    end

    for k,v in pairs(userinfo.achieveinfo) do
        if tonumber(v["isget"]) == 1 then
            local ret = {}
            ret["id"] = k
            ret["time"] = v["gettime"]
            table.insert(t,ret)
        end
    end

    table.sort(t,function(a,b)
        if a.time == b.time then
            return a.id > b.id
        end

        return a.time > b.time
    end)

    return t
end

--得到最近得到的玩家成就ID 
achievelib.getlastachieveinfo = function(userinfo,num)
    local t = {}
    if userinfo.achieveinfo == nil then
        return t
    end
    
    local completetable = achievelib.getcompleteachieve(userinfo)

    for i = 1,num do 
       if i > #completetable then
           table.insert(t,0)
       else
           table.insert(t,completetable[i])
       end
    end

    return t
end

--某个成就完成的处理
achievelib.updateuserachieveinfo = function(userinfo,id,isreset)
    if not userinfo or not userinfo.achieveinfo then return end

    if not achievelib.ACHIEVECFG_FROM_DB[id] then
        TraceError("数据库中没有配置该ID ".. id)
        return
    end

    if not userinfo.achieveinfo[id] then
        TraceError("用户信息中没有相应的成就ID " .. id)
        return
    end

    --得到玩家等级
    local userlevel = usermgr.getlevel(userinfo)
    if userlevel < tonumber(achievelib.ACHIEVECFG_FROM_DB[id]["level"]) then
        --TraceError("用户没有达到该成就的等级,发来成就完成,异常")
        return
    end

    if userinfo.achieveinfo[id].isget == 1 then
        --TraceError("已经获得了该成就,不处理")
        return
    end

    --TraceError("什么成就id = " .. id)
    --[[
    if userinfo.achieveinfo[id].iscangive == 1 then
        --TraceError("奖励正在发放中,再触发了一次?")
        return
    end
    --]]

    --改写内存
    if tonumber(achievelib.ACHIEVECFG_FROM_DB[id]["count_type"]) == 0 then--单次累计
        userinfo.achieveinfo[id].countum = userinfo.achieveinfo[id].countum + 1

        if tonumber(userinfo.achieveinfo[id].countum) >= tonumber(achievelib.ACHIEVECFG_FROM_DB[id]["count_num"]) then
            --给玩家一次改过的机会
            userinfo.achieveinfo[id].countum = achievelib.ACHIEVECFG_FROM_DB[id]["count_num"] - 1

            --等待玩家领奖,可以给成就奖励
            userinfo.achieveinfo[id].iscangive = 1

            --延迟发放,只有动画播放完毕才会发放
            achievelib.net_send_user_completeachieve(userinfo,id)
             --分享游戏事件
            if(dhomelib) then
                xpcall(function() dhomelib.update_share_info(userinfo, id) end, throw)
            end
        end
    else--连续累计
        if not isreset then
            TraceError("连续累计的没有重置设置")
            return
        end
        if isreset == 0 then
            userinfo.achieveinfo[id].countum = userinfo.achieveinfo[id].countum + 1
        else
            userinfo.achieveinfo[id].countum = 0
        end

        if tonumber(userinfo.achieveinfo[id].countum) >= tonumber(achievelib.ACHIEVECFG_FROM_DB[id]["count_num"]) then
            userinfo.achieveinfo[id].countum = 0 
            userinfo.achieveinfo[id].sumnum = userinfo.achieveinfo[id].sumnum + 1

            if tonumber(userinfo.achieveinfo[id].sumnum) >= tonumber(achievelib.ACHIEVECFG_FROM_DB[id]["sum_num"]) then
                --给玩家一次改过的机会
                userinfo.achieveinfo[id].sumnum = achievelib.ACHIEVECFG_FROM_DB[id]["sum_num"] - 1

                --等待玩家领奖,可以给成就奖励
                userinfo.achieveinfo[id].iscangive = 1

                --延迟发放,只有动画播放完毕才会发放
                achievelib.net_send_user_completeachieve(userinfo,id)
                 --分享游戏事件
                if(dhomelib) then
                    xpcall(function() dhomelib.update_share_info(userinfo, id) end, throw)
                end
            end
        end     
    end
    
    --写入cache
    achievelib.setuserinfoandcache(userinfo,userinfo.achieveinfo,2)
end

--给用户发奖
achievelib.giveuserprize = function(userinfo,id)
    if not userinfo or not userinfo.achieveinfo then return end
    
    if userinfo.achieveinfo[id].isget ~= 0 or userinfo.achieveinfo[id].iscangive ~= 1 then
        TraceError("还没有达成成就完成条件")
        return
    end

    --达成成就
    userinfo.achieveinfo[id].isget = 1
    userinfo.achieveinfo[id].iscangive = 0
    userinfo.achieveinfo[id].gettime = tonumber(os.time())

    --发奖
    local prizenum = math.abs(tonumber(achievelib.ACHIEVECFG_FROM_DB[id]["prize_count"]))
    if tonumber(achievelib.ACHIEVECFG_FROM_DB[id]["prize_type"]) == 0 then
        usermgr.addgold(userinfo.userId, prizenum, 0, g_GoldType.achievegive, -1, 1)
    end
    
    --写入cache
    achievelib.setuserinfoandcache(userinfo,userinfo.achieveinfo,2)

    --更新玩家完成成就数目
    local completetable = achievelib.getcompleteachieve(userinfo)
    achievelib.net_send_completenum(userinfo,#completetable)

    --写入日志
    --得到玩家等级
    local userlevel = usermgr.getlevel(userinfo)
    dblib.execute(string.format(tTexAchieveSqlTemplete.loguserachieveinfo,userinfo.userId,id,userlevel,dblib.tosqlstr(gamepkg.name),prizenum))
end
-----------------------------------得到用户成就信息------------------------------------
--用户登录的时机
if achievelib.onuser_login then
	eventmgr:removeEventListener("h2_on_user_login_forachieve", achievelib.onuser_login);
end

achievelib.onuser_login = function(e)
    --TraceError(e.data.data["achieve_info"])	
    local achievedata = e.data.data["achieve_info"] or ""
    achievelib.dogetuserachieveinfo(e.data.userinfo, achievedata)
end

eventmgr:addEventListener("h2_on_user_login_forachieve", achievelib.onuser_login);

---------------------------------------协议相关---------------------------------------
achievelib.net_send_user_completeachieve = function(userinfo,achieveid)
    netlib.send(
        function(buf)
            buf:writeString("TXAMCA")
            buf:writeInt(achieveid)--成就ID
        end,userinfo.ip,userinfo.port)
end

achievelib.net_send_user_lastgetachieve = function(userinfo,tab)
    netlib.send(
        function(buf)
            buf:writeString("TXAMZA")
            buf:writeInt(#tab)--成就ID集合
            for i = 1,#tab do
                buf:writeInt(tab[i])
            end
        end,userinfo.ip,userinfo.port)
end

achievelib.net_send_completenum = function(userinfo,num)
    netlib.send(
        function(buf)
            buf:writeString("TXAMCN")
            buf:writeInt(num)--成就数量
        end,userinfo.ip,userinfo.port)
end

achievelib.net_send_completeid = function(userinfo,tabid)
    netlib.send(
        function(buf)
            buf:writeString("TXAMCI")
            buf:writeInt(os.time())--系统当前时间
            buf:writeInt(#tabid)--成就ID集合
            for i = 1,#tabid do
                buf:writeInt(tonumber(tabid[i]["id"]))
                buf:writeInt(tonumber(tabid[i]["time"]))
            end
        end,userinfo.ip,userinfo.port)
end

achievelib.onrecvgetcompleteachieve = function(buf)
    local userinfo = userlist[getuserid(buf)]
    if not userinfo or not userinfo.achieveinfo then return end

    local ntype = buf:readByte()
    local curruserid = 0
    if ntype == 1 then
        curruserid = buf:readInt()
    end

    local curruserinfo = usermgr.GetUserById(curruserid)

    local completetable = {}

    if ntype == 0 then
        completetable = achievelib.getcompleteachieve(userinfo)
        achievelib.net_send_completenum(userinfo,#completetable)
    else
        if curruserinfo and curruserinfo.achieveinfo then
            completetable = achievelib.getcompleteachieve(curruserinfo)
            achievelib.net_send_completeid(userinfo,completetable)
        else
            TraceError("请求的用户信息内存已经不存在,去memcache里读")
            dblib.cache_get(gamepkg.table,"achieve_info","userid",curruserid,
                function(dt)
                    if dt and #dt > 0 then
                        local tCmpId = achievelib.getcompleteachievefromdb(dt[1]["achieve_info"])--完成的成就ID集合
                        achievelib.net_send_completeid(userinfo,tCmpId)
                    else
                        TraceError("读去数据失败")
                    end
                end)
        end
    end
end


achievelib.getcompleteachievefromdb = function(str)
    local info = loadTableFromStr(str)

    local tCmpId = {}--完成的成就ID集合
    for k,v in pairs(info) do
        if tonumber(v["isget"]) == 1 then
            local ret = {}
            ret["id"] = k
            ret["time"] = v["gettime"]
            table.insert(tCmpId,ret)
        end
    end

    return tCmpId
end

achievelib.onrecvgetlastcompleteachieve = function(buf)
    local userinfo = userlist[getuserid(buf)]
    if not userinfo or not userinfo.achieveinfo then return end

    local lastachieves = achievelib.getlastachieveinfo(userinfo,3)--最近3名
    if #lastachieves == 0 then
        TraceError("数据异常,不可能的事情发生了")
        return
    end

    achievelib.net_send_user_lastgetachieve(userinfo,lastachieves)
end

achievelib.onrecvgetprize = function(buf)
    local userinfo = userlist[getuserid(buf)]
    if not userinfo or not userinfo.achieveinfo then return end

    local achieveid = buf:readInt()

    if not achievelib.ACHIEVECFG_FROM_DB[achieveid] then
        TraceError("数据库中没有配置该ID " .. achieveid)
        return
    end

    if not userinfo.achieveinfo[achieveid] then
        TraceError("没有相应的成就ID " .. achieveid)
        return
    end

    achievelib.giveuserprize(userinfo,achieveid)
end


