# 📤 撤回消息

### ➡️ 接口描述

用于撤回指定会话中的消息。

### 🏷️ 接口路径

```
GET /recallMsg?toUin=<目标UIN>&msgIds=<消息ID列表>&chatType=<聊天类型>
```

### 📋 请求参数

| 参数       | 描述                                        |
| :--------- | :------------------------------------------ |
| `toUin`    | 目标用户或群组的 QQ UIN (String)           |
| `msgIds`   | 要撤回的消息ID列表，用逗号分隔 (String)     |
| `chatType` | 聊天类型 (int, `1` 私聊, `2` 群聊)         |

### 🌐 示例 URL

`http://localhost:8888/recallMsg?toUin=123456&msgIds=1111111111,2222222222&chatType=2`

### 🔄 函数实现

```lua
-- 撤回消息基础函数（支持多条消息）
local recallMsgBase2 = function(contact, msgIds)
    local sRecallMsg = MethodInfo() {
        declaredClass = findClass("com.tencent.qqnt.kernel.nativeinterface.IKernelMsgService$CppProxy"),
        methodName = "recallMsg",
    }.generate().firstOrNull()
    
    sRecallMsg.invoke(getKernelMsgservice(), contact, msgIds, nil)
end

-- 撤回消息包装函数
local recallMsgBase = function(contact, msgId)
    local msgIds = ArrayList.new()
    for _, value in ipairs(msgId) do
        msgIds.add(value)
    end
    recallMsgBase2(contact, msgIds)
end

-- 撤回消息主函数
_G["recallMsg"] = function(type, peerUin, msgIds)
    recallMsgBase(makeContact(peerUin, int(type)), msgIds)
end
```

### 🔄 路由处理

```lua
Route("GET", "/recallMsg", function(getParams)
    local ids = {}
    local toUin = getParams["toUin"]
    local chatType = getParams["chatType"]
    local msgIds = getParams["msgIds"]
    
    if toUin and msgIds and chatType then
        -- 解析逗号分隔的消息ID列表
        for id in msgIds:gmatch("[^,]+") do
            table.insert(ids, Long.valueOf(id))
        end
        
        print("ids: ", dump(ids))
        
        local result = recallMsg(int(chatType), toUin, ids)
        return {
            status = result and "ok" or "error",
            result = result
        }
    end
    
    return {
        status = "error",
        message = "Missing parameters"
    }
end)
```

### 📝 使用说明

1. **参数说明**：
   - `toUin`: 消息所在的会话目标（用户或群组）
   - `msgIds`: 要撤回的消息ID，多个ID用英文逗号分隔
   - `chatType`: 会话类型，1为私聊，2为群聊

2. **返回值**：
   ```json
   {
     "status": "ok",
     "result": true
   }
   ```
   或
   ```json
   {
     "status": "error",
     "message": "Missing parameters"
   }
   ```

3. **注意事项**：
   - 只能撤回自己发送的消息
   - 消息撤回有2分钟的时间限制
   - 群聊中需要管理员权限或撤回自己的消息
   - 消息ID需要是长整型数字

4. **使用示例**：
   - 撤回单条消息：`http://localhost:8888/recallMsg?toUin=123456&msgIds=1111111111&chatType=1`
   - 撤回多条消息：`http://localhost:8888/recallMsg?toUin=987654&msgIds=1111111111,2222222222,3333333333&chatType=2`