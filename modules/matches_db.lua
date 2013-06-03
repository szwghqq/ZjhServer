if not matches_db then
    matches_db = _S {
        get_match_list = NULL_FUNC,                 --取当天所有比赛
        get_match_award = NULL_FUNC,                --取所有奖励信息
        get_match_blind = NULL_FUNC,                --取所有盲注信息
        get_match_join_info_by_userid = NULL_FUNC,  --根据用户ID取报名信息
        get_match_win_list = NULL_FUNC,             --获取比赛赢家列表
        save_match_join_info = NULL_FUNC,           --保存用户报名信息
        save_match_win_info  = NULL_FUNC,           --保存比赛赢家信息
    }
end

function matches_db.get_match_win_info(callback)
    local sql = "select m.*, u.face, u.nick_name as nick from match_win_info m left join users u on u.id = m.user_id order by m.sys_time desc limit 5";
    dblib.execute(sql, function(dt)
        callback(dt);
    end);
end

function matches_db.save_match_win_info(match_id, match_name, win_user_id, win_jifen, prize_list)
    local sql = "insert into match_win_info(user_id, match_id, match_name, jifen, sys_time, prize_list) values(%d, '%s', '%s', %d, NOW(), '%s');commit;";
    sql = string.format(sql, win_user_id, match_id, match_name, win_jifen, table.tostring(prize_list or {}));
    dblib.execute(sql, function()end);
end

function matches_db.record_back_match_gold()
end

--取当天所有比赛
function matches_db.get_match_list(func)
    local currtime = os.date("%y-%m-%d %X",os.time());  --当前系统时间
    --查找符合比赛日期的赛事
    local sqltmp = "select * from cfg_match_info WHERE start_day <= '%s' AND end_day >= '%s'";
    local sql = format(sqltmp,currtime,currtime);
    dblib.execute(sql,func);
end

--取所有奖励信息
function matches_db.get_match_award(func)
    dblib.execute("select type_id, rank, chouma, diamond, others from cfg_match_award", func);
end

--取所有盲注信息
function matches_db.get_match_blind(func)
    dblib.execute("select type_id, lv, small_blind, big_blind, ante from cfg_match_blind", func);
end

--根据用户id取用户报名信息
function matches_db.get_match_join_info_by_userid(userid, func)
    dblib.execute(format("select user_id, join_info, join_time from match_baoming where user_id = '%s'",userid), func, userid);
end

--保存用户报名信息
function matches_db.save_match_join_info(userid, list)
    local join_info = table.tostring(list);
    local len = 0;
    for k,v in pairs(list) do
        len = len + 1;
    end
    local sql;
    if len == 0 then
        sql = format("delete from match_baoming where user_id = '%s'", userid);
    else
        sql = format("insert into match_baoming values ('%s','%s','%s') on duplicate key update join_info= '%s' , join_time = '%s';", userid, join_info, os.date("%y-%m-%d %X"), join_info, os.date("%y-%m-%d %X"));
    end
    dblib.execute(sql, nil, userid);
end


