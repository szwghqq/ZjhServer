TraceError("init task_huodong_lib...")
if not task_huodong_lib then
    task_huodong_lib = _S
    {


    }    
 end


--命令列表
cmdHandler = 
{

}

--加载插件的回调
for k, v in pairs(cmdHandler) do 
	cmdHandler_addons[k] = v
end

