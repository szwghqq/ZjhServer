--lua版本的buf模拟类

lua_buf = {}
lua_buf.__index = lua_buf


if (lua_port_start == nil) then
    lua_port_start = 0
end

function lua_buf:new(x,y)
    local temp = {}
    setmetatable(temp, lua_buf)
	temp.content = {}    
    temp.my_ip = "-10.10.10.10"
    temp.my_port = lua_port_start
    lua_port_start = lua_port_start + 1
    return temp
end

function lua_buf:write_item(arg, arg_type)
    if (arg == nil) then
        TraceError("非法数据")
        TraceError(debug.traceback())
    end
    table.insert(self.content, {arg = arg, arg_type = arg_type})
end

--把数据从luabuf，拷贝到cbuf中
function lua_buf:copy_buf(cbuf)
    local item_count = lua_buf.count(self)
    for i = 1, item_count do
        local item1, item_type1 = lua_buf.get_item(self)
        if (item1 == nil) then
            TraceError(self.content)
        end
        local item, item_type = lua_buf.read_item(self)
        
        if (item_type == 1) then
            cbuf:writeString(item)
        elseif (item_type == 2) then
            cbuf:writeInt(item)
        elseif (item_type == 3) then
            cbuf:writeShort(item)
        elseif (item_type == 4) then
            cbuf:writeByte(item)
        end
    end
end

function lua_buf:get_item()
    local  data = self.content[1]
    return data.arg, data.arg_type
end
--读取一个buf
function lua_buf:read_item()
    local  data = self.content[1]
	 table.remove(self.content, 1)
	 return data.arg, data.arg_type
end

--获取buf有多少个元素
function lua_buf:count()
    return #self.content
end

--获取第一个元素，一般情况下为消息命令
function lua_buf:get_top_item()
    local  data = self.content[1]
	 return data.arg, data.arg_type
end
function lua_buf:writeString(arg)
    lua_buf.write_item(self, tostring(arg) or "", 1)
end

function lua_buf:writeInt(arg)
    lua_buf.write_item(self, tonumber(arg) or 0, 2)
end

function lua_buf:writeShort(arg)
    lua_buf.write_item(self, tonumber(arg) or 0, 3)
end

function lua_buf:writeByte(arg)
    lua_buf.write_item(self, tonumber(arg) or 0, 4)
end

function lua_buf:readString()
    return lua_buf.read_item(self)
end

function lua_buf:readInt(arg)
    return lua_buf.read_item(self)
end

function lua_buf:readShort(arg)
    return lua_buf.read_item(self)
end

function lua_buf:readByte(arg)
    return lua_buf.read_item(self)
end

function lua_buf:ip()
    return self.my_ip
end

function lua_buf:port()
    return self.my_port
end

function lua_buf:set_ip(ip)
    self.my_ip = ip
end

function lua_buf:set_port(port)
    self.my_port = port
end

