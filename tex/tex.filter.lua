if not texfilter then
    texfilter = _S
    {
        net_recv_filter_message     = NULL_FUNC,
        change_string_by_pingbikey  = NULL_FUNC,
        is_exist_pingbici			= NULL_FUNC,
        cfg = {
            pingbikey = {},
        },

        timelib.createplan(function() 
            dblib.execute("select ciyu, length(ciyu) as len from ping_bi_ci order by length(ciyu) desc", function(dt) 
                texfilter.cfg.pingbikey = dt 
                for k,v in pairs(texfilter.cfg.pingbikey) do
                    local t1 = v.ciyu
                    t1 = string.gsub(t1, "%(", "%%(")
                    t1 = string.gsub(t1, "%)", "%%)")
                    t1 = string.gsub(t1, "%.", "%%.")
                    t1 = string.gsub(t1, "%+", "%%+")
                    t1 = string.gsub(t1, "%-", "%%-")
                    t1 = string.gsub(t1, "%*", "%%*")
                    t1 = string.gsub(t1, "%?", "%%?")
                    t1 = string.gsub(t1, "%[", "%%[")
                    t1 = string.gsub(t1, "%^", "%%^")
                    t1 = string.gsub(t1, "%$", "%%$")
                    v.ciyu = t1
                end
            end)
        end, 2)
    }
end


--转换字符串中存在的非法字符
texfilter.change_string_by_pingbikey = function(str)
	if type(str) ~= string then
		str = tostring(str)
	end
    
    if str == "" then return str end
       
    for k,v in pairs(texfilter.cfg.pingbikey) do
        local len = (v.len)/3
        local repl = ""
        for i = 1,len do 
            repl = repl .. "*"
        end        
        str = string.gsub(str,v.ciyu,repl)
    end

    return str
end

--检查字符串中是否存在非法字符
texfilter.is_exist_pingbici = function(str)
    ASSERT(type(str) ~= string,"要转换的不是字符串!!!")
    
    if str == "" then return false end
       
    for k,v in pairs(texfilter.cfg.pingbikey) do
    	if(string.find(str,v.ciyu) ~= nil)then
    		return true
    	end     
    end

    return false
end
