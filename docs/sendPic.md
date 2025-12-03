## 🖼️ 发送图片

### ➡️ 接口描述

用于向指定会话发送本地图片文件。

### 🏷️ 接口路径

```
GET /sendPic?toUin=<目标UIN>&filePath=<文件路径>&chatType=<聊天类型>
```

---

### 📋 请求参数

| 参数         | 描述                                 |
| :----------- | :----------------------------------- |
| `toUin`      | 目标用户的 QQ UIN (String)           |
| `filePath`   | 本地图片文件路径 (String)            |
| `chatType`   | 聊天类型 (int, `1` 私聊, `2` 群聊)   |

---

### 🌐 示例 URL

`http://localhost:8888/sendPic?toUin=123456&filePath=/sdcard/Pictures/photo.jpg&chatType=1`

---

### 📁 函数实现

以下是您提供的用于发送图片的核心 Lua 函数代码：

```lua
-- 创建图片元素
local createPicElement = function(path)
    local sMsgUtilApiImpl = makeDefaultObject(findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"))
    local sCreatePicElement = MethodInfo() {
        declaredClass = findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"),
        methodName = "createPicElement",
        parameters = { String, Boolean.TYPE, Integer.TYPE },
    }.generate().firstOrNull()
    log("createPicElement: " .. tostring(sCreatePicElement) .. " path: " .. tostring(path) .. " true 0")
    -- 注意：这里的 Boolean.TYPE 和 Integer.TYPE 参数（true, int(0)）通常用于控制图片的发送类型（如是否为原图、是否为闪照等）
    return sCreatePicElement.invoke(sMsgUtilApiImpl, String(path), true, int(0))
end

-- 发送图片主函数
_G["sendPic"] = function(peerUin, path, type)
    local contact = makeContact(String(peerUin), type)
    local msgElements = ArrayList.new()
    msgElements.add(createPicElement(path))
    sendMsgBase(contact, msgElements)
end
```

---

### 🔄 路由处理

以下是您提供的 HTTP 路由处理代码：

```lua
Route("GET", "/sendPic", function(getParams)
    local toUin = getParams["toUin"]
    local chatType = getParams["chatType"]
    local filePath = getParams["filePath"]

    if toUin and filePath and chatType then
        local result = sendPic(toUin, filePath, int(chatType))
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

---

### 📝 使用说明

1.  **参数说明**：

    - `toUin`: 接收图片的用户或群组的 **UIN** (String)。
    - `filePath`: 要发送的图片的完整**本地路径** (String)。
    - `chatType`: 会话类型，`1` 为私聊，`2` 为群聊 (int)。

2.  **返回值**：

    - **成功**:

    <!-- end list -->

    ```json
    {
      "status": "ok",
      "result": true
    }
    ```

    - **失败/缺少参数**:

    <!-- end list -->

    ```json
    {
      "status": "error",
      "message": "Missing parameters"
    }
    ```

3.  **注意事项**：

    - 确保 `filePath` 指向的文件是有效的图片格式（如 JPG, PNG 等），并且程序有权限访问该路径。
    - **`createPicElement`** 函数中的 `true` 和 `int(0)` 参数通常控制图片的发送属性，您可能需要根据实际需求调整这些参数以发送不同类型的图片（例如，原图、缩略图或闪照）。
