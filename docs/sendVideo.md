## 📹 发送视频

### ➡️ 接口描述

用于向指定会话发送视频文件。

### 🏷️ 接口路径

```
GET /sendVideo?toUin=<目标UIN>&filePath=<文件路径>&chatType=<聊天类型>
```

### 📋 请求参数

| 参数       | 描述                               |
| :--------- | :--------------------------------- |
| `toUin`    | 目标用户的 QQ UIN (String)         |
| `filePath` | 本地视频文件路径 (String)          |
| `chatType` | 聊天类型 (int, `1` 私聊, `2` 群聊) |

### 🌐 示例 URL

`http://localhost:8888/sendVideo?toUin=123456&filePath=/sdcard/Download/my_video.mp4&chatType=1`

### 📁 函数实现

```lua
-- 创建视频元素
local createVideoElement = function(path)
    local sMsgUtilApiImpl = makeDefaultObject(findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"))
    local sCreateVideoElement = MethodInfo() {
        declaredClass = findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"),
        methodName = "createVideoElement",
        parameters = { String },
    }.generate().firstOrNull()

    return sCreateVideoElement.invoke(sMsgUtilApiImpl, { path })
end

-- 发送视频主函数
_G["sendVideo"] = function(peerUin, path, type)
    local contact = makeContact(String(peerUin), type)
    local msgElements = ArrayList.new()
    msgElements.add(createVideoElement(path))
    sendMsgBase(contact, msgElements)
end
```

### 🔄 路由处理

```lua
Route("GET", "/sendVideo", function(getParams)
    local toUin = getParams["toUin"]
    local chatType = getParams["chatType"]
    local filePath = getParams["filePath"]

    if toUin and filePath and chatType then
        local result = sendVideo(toUin, filePath, int(chatType))
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

1.  **参数说明**：

      * `toUin`: 接收视频的用户或群组的 UIN
      * `filePath`: 要发送的视频的完整本地路径
      * `chatType`: 会话类型，1 为私聊，2 为群聊

2.  **返回值**：

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
      "message": "错误信息"
    }
    ```

3.  **注意事项**：

      * 确保视频文件路径存在且可访问。
      * 视频文件大小和时长可能受到 QQ 客户端的限制。
      * 私聊和群聊的视频发送方式相同，只是目标不同。
