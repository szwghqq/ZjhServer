--[[
游戏桌子信息公共管理

]]
hall.desk = {}

hall.desk.isemptysite = function(deskno, siteno)
	local deskSite = desklist[deskno].site[siteno]
    --排队机相关
    if (deskSite.user == nil) then
        return true
	else
		return false
    end
end

hall.desk.clear_users = function(nDeskNo, nDeskSite)
    --trace(format("deskno:%d, desksite:%d", nDeskNo, nDeskSite))
    ASSERT(nDeskNo ~= nil and nDeskNo > 0 and nDeskSite ~= nil and nDeskSite > 0)
    local deskSite = desklist[nDeskNo].site[nDeskSite]
    --排队机相关
    if (deskSite.user == nil) then
        return
    end
    if (userlist[deskSite.user] == nil) then
        ASSERT(false, "用户信息为空，但是桌子信息不为空")
        return
    end

    ASSERT(userlist[deskSite.user].desk ~= nil and
                userlist[deskSite.user].site ~= nil, "此用户已经坐在其他位置上了")
    ASSERT(userlist[deskSite.user].desk == nDeskNo
                and userlist[deskSite.user].site == nDeskSite, "此用户记录的桌子信息和实际的桌子信息不匹配")
    ASSERT(desklist[nDeskNo].playercount ~= nil and desklist[nDeskNo].playercount > 0)
    if (desklist[nDeskNo].playercount > 0) then
        desklist[nDeskNo].playercount = desklist[nDeskNo].playercount - 1
		usermgr.leave_playing(userlist[deskSite.user])
        trace("桌子上用户人数减少1nDeskNo:"..nDeskNo.."playcount:"..desklist[nDeskNo].playercount)
        if (gamepkg ~= nil and gamepkg.OnClearUser ~= nil) then
            gamepkg.OnClearUser(nDeskNo, nDeskSite, desklist[nDeskNo].playercount) --事件通知
        end
    else
        --补丁式的在所有人走了之后置零筹码
        desklist[nDeskNo].betgold = 0
        desklist[nDeskNo].usergold = 0
    end
    desklist[nDeskNo].usergold = desklist[nDeskNo].usergold - userlist[deskSite.user].gamescore or 0
    if desklist[nDeskNo].usergold < 0 then
        desklist[nDeskNo].usergold = 0
    end
    if(desklist[nDeskNo].watchingList[deskSite.user]) then
        TraceError("clear_users,从观战列表删除一个玩家")
        desklist[nDeskNo].watchingList[deskSite.user] = nil
        desklist[nDeskNo].watchercount = desklist[nDeskNo].watchercount - 1
    end
    --TraceError("deskSite.user  "..deskSite.user)
    userlist[deskSite.user].desk = nil
    userlist[deskSite.user].site = nil
    deskSite.user = nil;
    hall.desk.set_site_start(nDeskNo, nDeskSite, startflag.notready)
end

--强制清空一桌用户
hall.desk.force_clear_users = function(nDeskNo, nDeskSite)
    if (nDeskNo == nil or nDeskSite == nil) then
        ASSERT(false, "hall.desk.force_clear_users用户信息为空")
        return
    end
    local deskSite = desklist[nDeskNo].site[nDeskSite]
    if (desklist[nDeskNo].playercount > 0) then
        desklist[nDeskNo].playercount = desklist[nDeskNo].playercount - 1
        desklist[nDeskNo].usergold = desklist[nDeskNo].usergold - userlist[deskSite.user].gamescore or 0
        if (userlist[deskSite.user]~= nil) then
			usermgr.leave_playing(userlist[deskSite.user])
        end
        trace("桌子上用户人数减少1nDeskNo:"..nDeskNo.."playcount:"..desklist[nDeskNo].playercount)
        if (gamepkg ~= nil and gamepkg.OnClearUser ~= nil) then
            gamepkg.OnClearUser(nDeskNo, nDeskSite, desklist[nDeskNo].playercount) --事件通知
        end
    else
        --补丁式的在所有人走了之后置零筹码
        desklist[nDeskNo].betgold = 0
        desklist[nDeskNo].usergold = 0
    end
    desklist[nDeskNo].usergold = desklist[nDeskNo].usergold - userlist[deskSite.user].gamescore or 0
    if desklist[nDeskNo].usergold < 0 then
        desklist[nDeskNo].usergold = 0
    end
    if(desklist[nDeskNo].watchingList[deskSite.user]) then
        TraceError("clear_users,从观战列表删除一个玩家")
        desklist[nDeskNo].watchingList[deskSite.user] = nil
        desklist[nDeskNo].watchercount = desklist[nDeskNo].watchercount - 1
    end
    if (userlist[deskSite.user] ~= nil) then
        userlist[deskSite.user].desk = nil
        userlist[deskSite.user].site = nil
    end
    deskSite.user = nil
    hall.desk.set_site_start(nDeskNo, nDeskSite, startflag.notready)
end

hall.desk.user_sitdown = function(userKey, nDeskNo, nDeskSite, nStartState, sit_type)
    if nDeskNo <= 0 or nDeskSite <= 0 then
        return
    end
    local deskSite = desklist[nDeskNo].site[nDeskSite]
    ASSERT(deskSite.user == nil, "此座位已经有用户了，没法排进去")
    ASSERT(userlist[userKey].site == nil, "此用户已经坐在其他位置上了")

    deskSite.user = userKey;
    desklist[nDeskNo].playercount = desklist[nDeskNo].playercount + 1
    desklist[nDeskNo].usergold = desklist[nDeskNo].usergold + userlist[userKey].gamescore or 0

    if(desklist[nDeskNo].watchingList[userKey]) then
        TraceError("user_sitdown,从观战列表删除一个玩家")
        desklist[nDeskNo].watchingList[userKey] = nil
        desklist[nDeskNo].watchercount = desklist[nDeskNo].watchercount - 1
    end

    userlist[userKey].desk = nDeskNo
    userlist[userKey].site = nDeskSite
    deskSite.startstate = nStartState;
end

hall.desk.get_user_count = function(nDeskno)
    if (desklist[nDeskno].playercount == nil) then
        return 0
    else
        return desklist[nDeskno].playercount
    end
end

hall.desk.get_empty_site = function(deskno)
    for i = 1, room.cfg.DeskSiteCount do
        if (desklist[deskno].site[i].user == nil) then
            return i
        end
    end
    return -1
end

hall.desk.get_user = function(nDeskNo, nDeskSite)
    if nDeskNo <= 0 or nDeskSite <= 0 then
        return nil
    end
    local desksite = desklist[nDeskNo].site[nDeskSite]
    return desksite.user
end

hall.desk.is_win_site = function(nDeskNo, nDeskSite)
    if nDeskNo <= 0 or nDeskSite <= 0 then
        return false
    end
    local bWinner = desklist[nDeskNo].site[nDeskSite].IsWinner
    if (bWinner == nil)  then--防错处理
        trace("这里没有数据，应该算输家")
        return false
    end
    return bWinner
end

hall.desk.set_win_site = function(nDeskNo, nDeskSite, bWinner)
    if nDeskNo <= 0 or nDeskSite <= 0 then
        return
    end
    desklist[nDeskNo].site[nDeskSite].IsWinner = bWinner
end

hall.desk.set_user = function(nDeskNo, nDeskSite, userkey)
    if nDeskNo == nil or nDeskSite == nil or nDeskNo <= 0 or nDeskSite <= 0 then
        return nil
    end
    local desksite = desklist[nDeskNo].site[nDeskSite]
    desksite.user = userkey
    return desksite.user
end

hall.desk.set_site_start = function(nDeskNo, nDeskSite, nStartFlag)
    if nDeskNo == nil or nDeskSite == nil or nDeskNo <= 0 or nDeskSite <= 0 then
        trace('invalid deskno or desksite')
        return
    end
    local desksite = desklist[nDeskNo].site[nDeskSite]
    desksite.startstate = nStartFlag
end

hall.desk.get_site_start = function(nDeskNo, nDeskSite)
    if nDeskNo <= 0 or nDeskSite <= 0 then
        return startflag.notready
    end
    local desksite = desklist[nDeskNo].site[nDeskSite]
    return desksite.startstate
end

--注册状态列表到座位
hall.desk.register_site_states = function(states)
	if SITE_STATE == nil then
		SITE_STATE = states
		for k,v in pairs(SITE_STATE) do
			setmetatable(v, {__tostring = function() return "[SITE_STATE." .. k .. "]" end})
		end
	else
		TraceError("重复初始化状态表，忽略！")
	end
end

--注册状态改变函数
hall.desk.register_site_state_change = function(callback)
    ASSERT(callback and type(callback) == "function")
    desklist.onstatechange = callback
end

--清空桌子状态
hall.desk.clear_state_list = function(deskno)
    desklist[deskno].state_list = {}
end

--记录桌子状态
hall.desk.set_state_list = function(deskno, siteno, state)
    if (desklist[deskno].state_list == nil) then
        desklist[deskno].state_list = {}
    end
    local siteinfo = desklist[deskno].site[siteno]
    local str = " timelib.time "..timelib.time.." room.cfg.time "..room.time.."site:" .. siteno .. " " .. tostring(siteinfo.state) .. "->" .. tostring(state)
    table.insert(desklist[deskno].state_list, str)
end

--设置座位状态 (deskno, siteno, state) 传两个参数的话代表设置整桌所有人状态, timeout可不传
hall.desk.set_site_state = function(deskno, siteno, state, timeout)
    local set_site_state = function(deskno, siteno, state)
        local stateinfo = state
        local siteinfo = desklist[deskno].site[siteno]
        ASSERT(siteinfo, "siteno=" .. tostring(siteno))
        --清除上个状态时的timeoutfunc
        if siteinfo.state ~= state then
            if siteinfo.plan and siteinfo.plan.cancel then
                siteinfo.plan.cancel()
                siteinfo.plan = {}
            end
        else
            if (state ~= NULL_STATE and stateinfo[3] ~= 0) then
                TraceError("不稳的状态被执行两次"..tostring(state).."  "..debug.traceback())
            end
            return
        end
        xpcall(function() hall.desk.set_state_list(deskno, siteno, state) end, throw)

		--TraceError("    site:" .. siteno .. " " .. tostring(siteinfo.state) .. "->" .. tostring(state))
        local oldstate = siteinfo.state
        siteinfo.state = state
        local timeoutfunc = stateinfo[2]
        local delay = timeout or stateinfo[3] or 0
        local userinfo = userlist[hall.desk.get_user(deskno, siteno) or ""]
        if timeoutfunc and userinfo then
            if delay > 0 then
                siteinfo.plan = timelib.createplan(function() timeoutfunc(userinfo) end, delay)
            end
		end
        if oldstate ~= state and desklist.onstatechange then
            xpcall(function() desklist.onstatechange(deskno, siteno, oldstate, state) end, throw)
        end
    end

    ASSERT(deskno and deskno > 0 and deskno <= #desklist, "deskno=" .. tostring(deskno))
    if type(siteno) == "table" then
        for i = 1, room.cfg.DeskSiteCount do
            set_site_state(deskno, i, siteno)
        end
    else
        ASSERT(state, "设空状态的话用NULL_STATE,不要用nil")
        ASSERT(siteno and siteno > 0 and siteno <= room.cfg.DeskSiteCount)
        set_site_state(deskno, siteno, state)
    end
end

--获取座位状态
hall.desk.get_site_state = function(deskno, siteno)
    ASSERT(deskno and siteno and deskno > 0 and deskno <= #desklist and siteno > 0, "桌号座位号有问题")
    local siteinfo = desklist[deskno].site[siteno]
    ASSERT(siteinfo)
    return siteinfo.state or NULL_STATE
end

--获取座位距离超时的时间(-1表示永不超时)
hall.desk.get_site_timeout = function(deskno, siteno)
    ASSERT(deskno and siteno and deskno > 0 and deskno <= #desklist and siteno > 0, "桌号座位号有问题")
    local siteinfo = desklist[deskno].site[siteno]
    ASSERT(siteinfo)
    if siteinfo.plan and siteinfo.plan.getlefttime then
        return siteinfo.plan.getlefttime(), siteinfo.plan.getdelaytime()
    else
        return -1
    end
end

--设置桌子中已经开始了几局
hall.desk.inc_round_num = function(nDeskNo)
    if nDeskNo <= 0 then
        return
    end
    desklist[nDeskNo].js = (desklist[nDeskNo].js or 0) + 1
end

hall.desk.get_round_num = function(nDeskNo)
    if nDeskNo <= 0 then
        return -1
    end
    if (desklist[nDeskNo].js == nil) then
        desklist[nDeskNo].js = 0
    end
    return desklist[nDeskNo].js
end

hall.desk.get_site_data = function(deskno, siteno)
	return desklist[deskno].site[siteno].gamedata
end

hall.desk.get_desk_data = function(deskno)
	return desklist[deskno].gamedata
end

--给玩家推荐一个桌子和座位
--推荐条件：
--玩家必须能坐下
--优先找人数最接近满的桌子
--然后再空桌子，人满的桌子不考虑
hall.desk.give_user_deskno = function(userinfo)
    if not userinfo then return end
    --候选桌子号,按空，差1，差2，差3...规律各选一个
    local tmpdesklist = {}
    local tmp_null_desk_list = {} --空房间
    local nulldesks = {}  --保证每种赔率的空房间只找一个(提高效率)
    local find_desk_no = -1
    local channel_id=userinfo.channel_id
    
    --看是不是被踢的用户
    local is_kickeduser=function(kick_deskinfo,userinfo)
    	--遍历是否有需要被踢的人
	    for i, player in pairs(kick_deskinfo.gamedata.kickedlist) do
	        if(player.userinfo.userId==userinfo.userId)then
	        	return 1
	        end
	    end
	    return 0
    end

    for i = 1, #desklist do
        --只能自动加入普通游戏桌,有人，而且没满
        local playercount = desklist[i].playercount
        local maxplayercount = desklist[i].max_playercount
        local smallbet = desklist[i].smallbet
        local nullkey = format("%d_%d", smallbet, maxplayercount) --每种赔率，人数上限的空桌子加一个备用


        --如果玩家在频道房，就找频道桌子
        if((groupinfo.groupid == "18002" and desklist[i].desktype==g_DeskType.channel and desklist[i].channel_id==channel_id) or
           (desklist[i].desktype == g_DeskType.normal)) then  --有人并且没满的桌子
            if(playercount > 0 and playercount < maxplayercount)then
            	--找有人并且没有满的桌子，如果玩家在被踢列表中，就跳过
            	if(desklist[i].gamedata.kickedlist~=nil)then
            		if(is_kickeduser(desklist[i],userinfo)~=1)then
            			table.insert(tmpdesklist, {deskno = i, deskinfo = desklist[i]})
            		end            	
            	else            	
               		table.insert(tmpdesklist, {deskno = i, deskinfo = desklist[i]})
                end
            elseif(playercount == 0 and nulldesks[nullkey] == nil)then  --没人的桌子只要一个
                nulldesks[nullkey] = 1
                table.insert(tmp_null_desk_list, {deskno = i, deskinfo = desklist[i]})
            end
        end
        
    end

    --把空房间放在后面
    for i=1,#tmp_null_desk_list do
        table.insert(tmpdesklist,tmp_null_desk_list[i])
    end

    --检查是否能坐下此桌子
    local isCanSitdown = function(userinfo, deskinfo)

        local needlevel = deskinfo["deskinfo"].needlevel
        local needgold = deskinfo["deskinfo"].at_least_gold
        local smallbet=deskinfo["deskinfo"].smallbet
        local deskno=deskinfo.deskno or "-1"
	
	if(userinfo==nil or userinfo.gamescore == nil or userinfo.bankruptcy_give_count==nil)then
	    return false
	end

        if(usermgr.getlevel(userinfo) < needlevel) then
            return false
        end

        if(userinfo.gamescore < needgold and userinfo.bankruptcy_give_count>3) then
            return false
        end

        --新手场限制，筹码大于1500不坐到新手场
        if(smallbet == 1 and userinfo.gamescore > room.cfg.freshman_limit) then
            return false
        end
        --根据用户身上的钱分配房间
        --2000001以上，分配到10K/20K或以上房间。这个不用改了，直接就可以排到
        --800001-200W，分配到5K/10K的房间
        if(userinfo.gamescore >= 800001 and userinfo.gamescore<=2000000 and smallbet>=10000) then
            return false
        end
        --400001-80W，分配到2K/4K的房间，smallbet>=5000，就认为不可以自动给的房间
        if(userinfo.gamescore >= 400001 and userinfo.gamescore<=800000 and smallbet>=5000) then
            return false
        end

        --200001-40W，分配到1K/2K的房间
        if(userinfo.gamescore >= 200001 and userinfo.gamescore<=400000 and smallbet>=2000) then
            return false
        end

        --80001-20W ，分配到500/1K的房间
        if(userinfo.gamescore >= 80001 and userinfo.gamescore<=200000 and smallbet>=1000) then
            return false
        end

         --40001-80000，分配到200/400房间
        if(userinfo.gamescore >= 40001 and userinfo.gamescore<=80000 and smallbet>=500) then
            return false
        end
    

         --20001-40000，分配到100/200房间
        if(userinfo.gamescore >= 20001 and userinfo.gamescore<=40000 and smallbet>=200) then
            return false
        end

        --10001-20000，分配到50/100房间
        if(userinfo.gamescore >= 10001 and userinfo.gamescore<=20000 and smallbet>=100) then
            return false
        end

        --4001-10000，分配到25/50房间
        if(userinfo.gamescore >= 4001 and userinfo.gamescore<=10000 and smallbet>=50) then
            return false
        end

        --1500-4000，分配到10/20房间
        if(userinfo.gamescore >= 1501 and userinfo.gamescore<=4000 and smallbet>=25) then
            return false
        end

        --200-1500，对应等级大于3级（不是新手）分配到能进入的最大赔率业余场
        if(userinfo.gamescore >=200  and userinfo.gamescore<=room.cfg.freshman_limit and smallbet>=10) then
            return false
        end

        --0-200，分配到新手场
        if(userinfo.gamescore >=0  and userinfo.gamescore<=200 and smallbet>=2) then
            return false
        end

        return true
    end

    local hasSameIP = function(userinfo, players)
        for i = 1, #players do
            local ip = players[i].userinfo.ip;
            if(userinfo.ip == ip) then
                return true
            end
        end
        return false
    end

    --新手特殊选择桌子规则
    local success, templist = xpcall (function() 
        return hall.desk.xinshou_desklist_handle(userinfo, tmpdesklist) end, throw)

    if (success == true and templist ~= nil) then
        tmpdesklist = templist
        -- else
        --打乱桌子顺序再遍历
        --table.disarrange(tmpdesklist)
    end

    --遍历查找适合条件的桌子，注意：等级低于3级且筹码少于1500，安排去新手房
    for i = 1, #tmpdesklist do
        local deskinfo = tmpdesklist[i]
        local deskno = tmpdesklist[i].deskno
        
        local players = deskmgr.getplayers(deskno)
            --判断能否坐下
            local allow_sit = false
            if(room.cfg.allow_samedesk == 1) then
                allow_sit = true
            else
                allow_sit = (hasSameIP(userinfo, players) == false)
            end

            if(isCanSitdown(userinfo, deskinfo) == true and allow_sit) then
                find_desk_no = deskno 
		break
	    end

    end
	return find_desk_no
end

--新手特殊选择桌子规则
--[[
    等级低于3级且筹码少于1500，优先分配到新手场
--]]
hall.desk.xinshou_desklist_handle = function(userinfo, desklist)
    local temp_desklist = {}
    local xinshou_desklist = {}  --新手场桌子
    local other_desklist = {}    --除了新手场以外的桌子
    if(usermgr.getlevel(userinfo) < 3 and userinfo.gamescore <= room.cfg.freshman_limit) then
        --TraceError("等级低于3级且筹码少于1500")
        for i = 1, #desklist do
            --新手场，且没有坐满，放入新手场
            if(desklist[i].deskinfo.smallbet == 1 and   --新手场
               desklist[i].deskinfo.playercount ~= desklist[i].deskinfo.max_playercount) then --人没有满员的房间
                table.insert(xinshou_desklist, desklist[i])   --新手场
            elseif (desklist[i].deskinfo.at_least_gold <= userinfo.gamescore and --身上钱大于最小携带的房间 
                    desklist[i].playercount ~= desklist[i].max_playercount) then --人没有满的房间
                table.insert(other_desklist, desklist[i])     --其它普通场
            end
        end
        --打乱桌子顺序
        --table.disarrange(xinshou_desklist)
        --table.disarrange(other_desklist)

        for j = 1, #xinshou_desklist do
            table.insert(temp_desklist, xinshou_desklist[j])
        end
        for k = 1, #other_desklist do
            table.insert(temp_desklist, other_desklist[k])
        end
    else
        return nil
    end

    return temp_desklist
end

hall.desk.init_desk_info = function(index, deskcfg)
	local deskinfo = {}
	
	--排队相关
	deskinfo.playercount = 0 --本桌已经坐下的玩家数量
    deskinfo.watchercount = 0 --观战的玩家数量
	deskinfo.gamepeilv = groupinfo and groupinfo.gamepeilv or 0

    deskinfo.name = ""
    deskinfo.description = ""
    deskinfo.needlevel = 0
    deskinfo.fast = 0
    deskinfo.desktype = 1  --桌子类型(1普通，2比赛，3VIP专用)
    deskinfo.smallbet = groupinfo and groupinfo.gamepeilv or 0
    deskinfo.largebet = deskinfo.smallbet * 2
    deskinfo.at_most_gold = 200000000
    deskinfo.specal_choushui = 0
    deskinfo.min_playercount = 2
    deskinfo.max_playercount = room.cfg.DeskSiteCount
    deskinfo.desk_settings = ""
    deskinfo.at_least_gold = deskinfo.largebet + deskinfo.specal_choushui

	deskinfo.site = {}
	for j = 1, room.cfg.DeskSiteCount do
	    deskinfo.site[j] = {}
	    deskinfo.site[j].gamedata = gamepkg.init_site_info()
	    deskinfo.site[j].state = NULL_STATE
	    deskinfo.site[j].pokes = {}
	    deskinfo.site[j].response = false  --用户反馈，暂未使用
    end

    --观战玩家列表 lch
    deskinfo.watchingList = {}

    --按数据库配置桌子参数 lch
    if(deskcfg ~= nil) then
        deskinfo.desk_settings = deskcfg["desk_settings"] or ""
        --桌子的附加属性(注意此处如果和字段名冲突了，则会被覆盖)
        local desksetting = split(deskinfo.desk_settings, "|")
        for i = 1, #desksetting do
            local item = split(desksetting[i], ":")
            if(#item == 2) then
                deskinfo[item[1]] = tonumber(item[2]) or item[2]
            end
        end
	    deskinfo.db_desk_id = deskcfg["id"] or -1 
        deskinfo.name = deskcfg["name"] or ""
        deskinfo.description = deskcfg["description"] or ""
        deskinfo.desktype = deskcfg["desktype"] or 1
        deskinfo.needlevel = deskcfg["needlevel"] or 0
        deskinfo.smallbet = deskcfg["smallbet"] or 1
        deskinfo.largebet = deskcfg["largebet"] or 2
        deskinfo.at_most_gold = deskcfg["at_most_gold"] or 2100000000
        deskinfo.specal_choushui = deskcfg["specal_choushui"] or 0
        deskinfo.min_playercount = deskcfg["min_playercount"] or room.cfg.DeskSiteCount
        deskinfo.max_playercount = deskcfg["max_playercount"] or room.cfg.DeskSiteCount
        deskinfo.at_least_gold = deskcfg["at_least_gold"] or (deskinfo.largebet + deskinfo.specal_choushui)
        deskinfo.channel_id = deskcfg["channel_id"] or -1

        if((deskinfo.desktype ~= g_DeskType.tournament and deskinfo.desktype ~= g_DeskType.channel_tournament) and deskinfo.at_least_gold < (deskinfo.largebet + deskinfo.specal_choushui)) then
            TraceError(deskinfo)
            TraceError(format("桌子[%d]配置有误, 最小金额[%d]不能小于大盲加抽水的总额", index, deskinfo.at_least_gold))
            deskinfo.at_least_gold = (deskinfo.largebet + deskinfo.specal_choushui)
        end
        
		TraceError("fffffffffffffffffffffffffffffffffffffsssssssssssssssssssssssssssssssss")
        eventmgr:dispatchEvent(Event("on_desk_init", null));
       
    end

    --设置一个静态大小盲实现动态大小盲功能
    deskinfo.staticsmallbet = deskinfo.smallbet
    deskinfo.staticlargebet = deskinfo.largebet
    deskinfo.betgold = 0
    deskinfo.usergold = 0

	deskinfo.gamedata = gamepkg.init_desk_info()
	deskqueue[index] = index            --剩余空位的排列顺序
	return deskinfo
end

hall.desk.init_all = function()
    --按注额排序，用于查找合适的房间，不要随便修改排序规则，否则查找座位功能会有问题
    --desktype!=3代表去掉VIP房
    --如果不是频道场，就初始化桌子
    if(groupinfo.groupid ~= "18002")then
	    local szsql = "select * from configure_deskinfo where room_id = %d and desktype!=3  ORDER BY smallbet desc,id asc"
	    local ongetdeskcfg = function(dt)
	        if(dt and #dt > 0) then
	            for i = 1, #dt do
	        		desklist[i] = hall.desk.init_desk_info(i, dt[i])
	        	end
	        else
	            for i = 1, room.cfg.deskcount do
	        		desklist[i] = hall.desk.init_desk_info(i, nil)
	        	end
	        end
	    end
	    dblib.execute(format(szsql, groupinfo.groupid), ongetdeskcfg);
    end
end

--TraceError("加载hall.desk.lua完成!");


--[[游戏大厅显示桌子信息的配置]]
if not hall.displaycfg then
    TraceError("初始化hall.displaycfg!");
    hall.displaycfg = {cfgdata = {},}
end
--获取某个场的显示参数
hall.displaycfg.getdisplaycfg = function(desktype, tabindex)
    if hall.displaycfg.cfgdata[desktype] == nil then
        hall.displaycfg.cfgdata[desktype] = {}
    end
	return hall.displaycfg.cfgdata[desktype][tabindex] or {}
end

hall.displaycfg.init = function()
    local szsql = "select * from configure_displaydesk order by desktype asc, tabindex asc, isfast asc, peilv1 asc "
    local displaycfg = function(dt)
        if(dt and #dt > 0) then
            for i = 1, #dt do
        		local desktype = dt[i]["desktype"]
                local tabindex = dt[i]["tabindex"]
                local isfast = dt[i]["isfast"]
                local peilv1 = dt[i]["peilv1"]
                local peilv2 = dt[i]["peilv2"]  --暂时不用
                local displaycount = dt[i]["displaycount"]
                if hall.displaycfg.cfgdata[desktype] == nil then
                    hall.displaycfg.cfgdata[desktype] = {}
                end
                if hall.displaycfg.cfgdata[desktype][tabindex] == nil then
                    hall.displaycfg.cfgdata[desktype][tabindex] = {}
                end
                if hall.displaycfg.cfgdata[desktype][tabindex][isfast] == nil then
                    hall.displaycfg.cfgdata[desktype][tabindex][isfast] = {}
                end
                hall.displaycfg.cfgdata[desktype][tabindex][isfast][peilv1] = displaycount
        	end
        else
            TraceError("从数据库读取显示桌子列表配置失败")
        end
        --TraceError(hall.displaycfg.cfgdata)
    end
    dblib.execute(szsql, displaycfg);
end

--改变桌子的状况
function hall.desk.add_channel_desk(userinfo)
    --todo:集成频道代码之后，把这个写成从程序中取
    local channel_id=userinfo.channel_id--先写死一个频道，方便测试userinfo.channel_id

    --测试用的代码，上线后要拿掉
    if(userinfo.userId<=105) then 
        channel_id=888
        userinfo.channel_id=888
    end

    if(userinfo.userId>105 and userinfo.userId<200) then 
        channel_id=7612793
        userinfo.channel_id=7612793
    end

    --1.如果这个用户的channel_id为空，就不做什么事情
    if(channel_id==nil)then
        return
    end

    --2.如果这个用户有channel_id，就看一下对应的channel_id的桌子是不是存在，如果不存在，就创建33张频道桌子，否则就不做什么事情
    if(hall.desk.is_exist_channel_desk(channel_id)~=1)then--如果不存在频道桌子，就创建33张
        create_channel_desklist(channel_id)
    end
end

--创建指定channel_id的频道房
function create_channel_desklist(channel_id)
	
    if(channel_desklist==nil or #channel_desklist==0)then
          --取出频道房，放在channel_desklist中
        local szsql = "select * from configure_deskinfo where desktype=4  ORDER BY smallbet desc,id asc"
        local ongetdeskcfg = function(dt)
            if(dt and #dt > 0) then
                channel_desklist = table.clone(dt)
                for i = 1, #dt do
               		local need_show = 1
		        	--761279328205这个桌子，只有333频道（频道号是：7612793）能看到才对
		        	if dt[i].id == 28205 and channel_id ~= 7612793 then
		        		need_show = 0
		        	end
			        if need_show == 1 then
	                    dt[i].id=channel_id..dt[i].id   --设定桌子为频道的桌子
	                    dt[i].channel_id=channel_id
	                    table.insert(desklist,hall.desk.init_desk_info(i, dt[i]))
                    end
            	end
            end
        end
        dblib.execute(szsql, ongetdeskcfg);
    else
        --找到一堆空桌子，用于创建频道桌子
        local desk_pos = 0
        for i=1,#desklist do
            if (desklist[i].channel_id == -2) then
                desk_pos = i
                break
            end
        end
        if (desk_pos == 0) then
            desk_pos = #desklist + 1
        end

        local tmp_channel_desklist = table.clone(channel_desklist)
        for i=1, #tmp_channel_desklist do
        	local need_show = 1
        	--761279328205这个桌子，只有333频道（频道号是：7612793）能看到才对
        	if tmp_channel_desklist[i].id == 28205 and channel_id ~= 7612793 then
        		need_show = 0
        	end
        	
	        if need_show == 1 then
	            tmp_channel_desklist[i].id = channel_id..tmp_channel_desklist[i].id   --设定桌子为频道的桌子
	            tmp_channel_desklist[i].channel_id = channel_id                
	            desklist[desk_pos] = hall.desk.init_desk_info(i, tmp_channel_desklist[i])
	            desk_pos = desk_pos + 1
            end
        end
    end
    
end

--删除不用的桌子
function hall.desk.remove_channel_desk(channel_id)
    --用户桌子必须是连续的，因为很多地方用了#desklist，所以只能把桌子频道设置成-2
    for i = #desklist, 1, -1 do
        if(channel_id~=nil and desklist[i].channel_id==channel_id and channel_id~=-1)then
            desklist[i].channel_id = -2
        end
    end    
    for i = #desklist, 1, -1 do
        if(desklist[i].channel_id ~= -2)then
            break
        end
        table.remove(desklist,i)
    end
end

--判断是不是这个频道没有人了,如果还有人就返回1，否则就返回0
function hall.desk.is_not_exist_channel(user_id,channel_id)
   for k,v in pairs(userlist) do
        if (v.channel_id==channel_id and v.userId~=user_id) then
             return 1
        end
    end
    return 0
end


--看是不是已经有对应频道的桌子了
function hall.desk.is_exist_channel_desk(channel_id)
    for i = 1, #desklist do
        if(desklist[i].channel_id==channel_id)then
            return 1
        end
    end
    return 0
end
--TraceError("初始化hall.displaycfg.lua完成!");


