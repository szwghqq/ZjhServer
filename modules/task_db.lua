TraceError("init quest....")
if not task_db_lib then 
    task_db_lib = _S
    {
        init_quest_info = NULL_FUNC, --初始化用户任务信息
    }
end

task_db_lib.init_quest_info = function(user_id, task_id, progress, task_list, callback)
   local sql = "insert ignore into user_quest_info(user_id, progress, task_id, task_list, sys_time) values(%d, %d, %d, '%s', NOW())";
    sql = string.format(sql, user_id, progress, task_id, table.tostring(task_list));
    dblib.execute(sql, function(dt)
        if(callback) then
            callback();
        end
    end, user_id);
end
