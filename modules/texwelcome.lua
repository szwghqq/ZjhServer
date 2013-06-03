 TraceError("texwelcom::::::::::::::::")


if not texwelclib then
    texwelclib = _S
    {
        net_send_show_welcome   = NULL_FUNC,
        net_send_rewards   = NULL_FUNC,
        on_recv_show_welcome   = NULL_FUNC,
        on_recv_get_reward   = NULL_FUNC,
        --sql语句
        SQL = {
            insert_reward_info = "insert into huodong_tex_welcome_info(user_id, isget,getdate) values(%d,%d,%s)",
            update_reward_info = "update huodong_tex_welcome_info set isget=%d,getdate=%s where user_id = %d",
            select_reward_info = "select isget,getdate from huodong_tex_welcome_info where user_id = %d",
        },
        --变量
        MINNUM = 700,
        MAXNUM = 1200,
    }
end

--获得随机的德州豆数量
function getRandGolds()
    local first_random = true
    local  random = function(min, max)
        if first_random then
            math.randomseed(os.clock()*1000)
            math.randomseed(math.random(1, 65536) + os.clock()*1000)
            math.random(min, max)
            first_random = false
        end
        return math.random(min, max)
    end

    local random_num = random(texwelclib.MINNUM, texwelclib.MAXNUM) --得到随机数
    return random_num
end

--获得当前的日期
function getNowDate()
    local tableTime = os.date("*t",os.time())
    local date = tableTime.year.."-"..tableTime.month.."-"..tableTime.day
    TraceError("date:::"..date)
    return date
end

--通知客户端显示欢迎界面
function texwelclib.net_send_show_welcome(userinfo)
    netlib.send(
        function(buf)
            buf:writeString("TXWEL")
    end, userinfo.ip, userinfo.port)
end

--发送玩家领取的德州豆数
function texwelclib.net_send_rewards(userinfo,dous)
    TraceError("dous::::::::::"..dous);
    netlib.send(
        function(buf)
            buf:writeString("TXGETRW")
            buf:writeInt(dous)
    end, userinfo.ip, userinfo.port)
end

function texwelclib.on_recv_show_welcome(buf)
    --读取userinfo，若为空，直接返回
    local userinfo = userlist[getuserid(buf)]
    if not userinfo then
       return
    end
    --判断玩家当天是否已经领取过奖励，若没有，则通知显示
    dblib.execute(string.format(texwelclib.SQL.select_reward_info, userinfo.userId),
                                function(dt)
                                    TraceError("::::::"..tostringex(dt))
                                    if #dt <= 0 then               --表是空的，插入信息
                                         dblib.execute(string.format(texwelclib.SQL.insert_reward_info, userinfo.userId, 0,"0"),
                                          function(dt)
                                              texwelclib.net_send_show_welcome(userinfo)
                                          end)
                                    elseif dt[1]["isget"] == 0 then  --未领取过
                                         TraceError("未领取过:::::")
                                         texwelclib.net_send_show_welcome(userinfo)
                                    elseif dt[1]["getdate"] ~= getNowDate() then  --已经领取过了，判断信息是否过期了
                                         TraceError("领取过，但信息已经过期::::")
                                         texwelclib.net_send_show_welcome(userinfo)
                                    end
                                end)
end

function texwelclib.on_recv_get_reward(buf)
    --读取userinfo，若为空，直接返回
    local userinfo = userlist[getuserid(buf)]
    if not userinfo then
       return
    end
    --判断玩家领取是否合法，若合法(未领取过)
    --则通知领取，并刷新总的德州豆数，并记录该玩家已经领取
    dblib.execute(string.format(texwelclib.SQL.select_reward_info, userinfo.userId),
                            function(dt)
                                if #dt > 0 and (dt[1]["isget"] == 0 or dt[1]["getdate"] ~= getNowDate()) then                
                                    local golds = getRandGolds();
                                    usermgr.addgold(userinfo.userId, golds, 0, g_GoldType.jifenhuodong, -1)
                                    --记录
                                    dblib.execute(string.format(texwelclib.SQL.update_reward_info, 
                                                                1, 
                                                                dblib.tosqlstr(getNowDate()),
                                                                userinfo.userId))
                                    texwelclib.net_send_rewards(userinfo,golds)
                                else
                                    TraceError("数据为空，或者已经领取过!!!!")
                                end
                            end)
end

----------------------------------------协议------------------------------------------------
--命令列表
cmdHandler =
{
    ["TXWEL"]   = texwelclib.on_recv_show_welcome, --收到客户端请求显示欢迎界面
    ["TXGETRW"] = texwelclib.on_recv_get_reward, --收到客户端请求领奖
}

--加载插件的回调
for k, v in pairs(cmdHandler) do
	cmdHandler_addons[k] = v
end