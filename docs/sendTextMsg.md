# 💬 发送消息

### ➡️ 接口描述

用于发送私聊或群聊消息。支持同时发送 **艾特消息** (`[atUin=<QQ号>]`)。

### 🏷️ 接口路径

```
GET /sendMsg?toUin=<目标UIN>&msg=<消息内容>&chatType=<消息类型>
```

### 📋 请求参数

| 参数       | 描述                                            |
| :--------- | :---------------------------------------------- |
| `toUin`    | **目标 QQ 号** 或 **群号**（UIN，String）       |
| `msg`      | 要发送的消息内容，可包含 `[atUin=...]` 特殊标签 |
| `chatType` | **1** 为私聊，**2** 为群聊 (int)                |

### 🌐 示例 URL

- **群聊示例（艾特全体成员）：**
  `http://localhost:8888/sendMsg?toUin=98765&msg=[atUin=0]这是一条通知&chatType=2`
- **私聊示例：**
  `http://localhost:8888/sendMsg?toUin=10001&msg=你好&chatType=1`

---

### 💡 参考代码（Lua 脚本）

以下是实现 `/sendMsg` 接口所需的全部 **Lua 辅助函数** 和 **主函数**。

#### **1. 核心工具函数**

这些函数用于获取消息服务、生成消息 ID、创建 Contact 对象、处理依赖注入等。

```lua
-- 获取 IKernelMsgService 实例
local getKernelMsgservice = function()
    local iKernelIService = findClass("com.tencent.qqnt.kernel.api.IKernelService");
    local kernelService = invoke(sQQAppInterface, "getRuntimeService", iKernelIService, "")
    local msgService = invoke(kernelService, "getMsgService")
    return invoke(msgService, "getService")
end

-- 生成消息的唯一 ID
local generateMsgUniqueId = function(chatType)
    return sGenerateMsgUniqueId.invoke(getKernelMsgservice(), int(chatType), System.currentTimeMillis())
end

-- 发送消息的基础实现
local sendMsgBase = function(contact, elements)
    local chatType = getField(contact, "chatType")
    local msgId = generateMsgUniqueId(chatType);
    sSendMsg.invoke(getKernelMsgservice(), msgId, contact, elements, HashMap(), nil)
end

-- 通过反射/构造函数创建对象实例 (用于依赖注入)
local function makeDefaultObject(clazz, ...)
    local args = { ... }
    local constructors = clazz.getDeclaredConstructors()

    for i = 0, constructors.length - 1 do
        local constructor = constructors[i]
        constructor.setAccessible(true)
        local success, result = pcall(function()
            return constructor.newInstance(table.unpack(args))
        end)

        if success then
            return result
        else
            -- 忽略失败的尝试
        end
    end
    log("创建 " .. tostring(clazz) .. " 对象失败，尝试了 " .. constructors.length .. " 个构造函数")
    return nil
end

-- 通过 UIN 获取 UID
local getUidFromUin = function(uin)
    local RelationNTUinAndUidApiImpl = makeDefaultObject(findClass(
        "com.tencent.relation.common.api.impl.RelationNTUinAndUidApiImpl"))
    local result = invoke(RelationNTUinAndUidApiImpl, "getUidFromUin", String(uin))
    return result
end

-- 创建 Contact 对象 (用于指定接收者)
local function makeContact(peerUin, type)
    local peerUid
    if type == int(1) or type == int(100) then -- 私聊
        peerUid = getUidFromUin(peerUin)
    elseif type == int(2) then -- 群聊
        peerUid = peerUin -- 群聊的 peerUin 即是其 UID (假设)
    else
        peerUid = nil
    end

    return makeDefaultObject(findClass("com.tencent.qqnt.kernelpublic.nativeinterface.Contact"), type, peerUid, "")
end
```

#### **2. 消息内容处理函数**

这些函数负责将包含特殊标签的消息字符串解析成消息元素 (`MsgElement`) 列表。

```lua
-- 定义 createTextElement 方法信息
local sCreateTextElement = MethodInfo() {
    declaredClass = findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"),
    methodName = "createTextElement",
    parameters = { String },
}.generate().firstOrNull()

-- 调用创建文本消息元素
local createTextElement = function(value)
    local sMsgUtilApiImpl = makeDefaultObject(findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"))
    return sCreateTextElement.invoke(sMsgUtilApiImpl, { value })
end

-- 定义 createAtTextElement 方法信息
local sCreateAtTextElement = MethodInfo() {
    declaredClass = findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"),
    methodName = "createAtTextElement",
}.generate().firstOrNull()

-- 调用创建艾特消息元素
local createAtTextElement = function(uid, atType)
    local sMsgUtilApiImpl = makeDefaultObject(findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"))
    -- 注: 这里 hardcode 了 "@全体成员" 作为 AtTextElement 的文本
    return sCreateAtTextElement.invoke(sMsgUtilApiImpl, "@全体成员", uid, int(atType));
end

-- 将消息字符串分割成文本和标签两部分
local function splitMessageString(input)
    input = String(input)
    local result = ArrayList.new()

    -- 匹配 [atUin=...] 或 [pic=...] 标签
    local pattern = Pattern.compile("\\[atUin=\\d+]|\\[pic=.*?]");
    local matcher = pattern.matcher(input);
    local lastEnd = 0;

    while (matcher.find()) do
        local start_ = matcher.start();
        local end_ = matcher["end"]();
        if (start_ > lastEnd) then
            -- 添加标签前的普通文本
            result.add(input.substring(lastEnd, start_));
        end
        -- 添加标签本身
        result.add(input.substring(start_, end_));
        lastEnd = end_;
    end
    if (lastEnd < input.length()) then
        -- 添加剩余的普通文本
        result.add(input.substring(lastEnd));
    end
    return result
end

-- 处理分割后的消息部分，提取类型和值
local function processMessageParts(input)
    local parts = splitMessageString(input)
    local entries = ArrayList.new()
    local tagPattern = Pattern.compile("\\[(atUin|pic)=([^]]*)]"); -- 解析标签内容

    for i = 0, parts.size() - 1 do
        local part = String(parts.get(i))
        if (part.startsWith("[") and part.endsWith("]")) then
            local matcher = tagPattern.matcher(part);
            if (matcher.matches()) then
                -- 标签匹配成功 (e.g., atUin, 12345)
                entries.add(SimpleEntry.new(matcher.group(1), matcher.group(2)));
            else
                -- 标签匹配失败，当作普通文本
                entries.add(SimpleEntry.new("text", part));
            end
        else
            -- 普通文本
            entries.add(SimpleEntry.new("text", part))
        end
    end
    return entries
end

-- 将处理后的消息部分转换为消息元素列表
local processMessageContent = function(contact, msg)
    local msgElements = ArrayList.new()
    local processedParts = processMessageParts(msg)

    for i = 0, processedParts.size() - 1 do
        local entry = processedParts.get(i)
        local type = entry.getKey()
        local value = entry.getValue()
        local element = nil

        if type == "text" then
            element = createTextElement(value)
        elseif type == "atUin" then
            local atType -- 1: @全体成员, 2: @个人
            local uid
            if value == "0" then
                atType = 1 -- @全体成员
                uid = "0"
            else
                atType = 2 -- @个人
                uid = getUidFromUin(value);
            end
            element = createAtTextElement(uid, atType);
        elseif type == "pic" then
             -- TODO: 此处应添加 createPicElement 的逻辑
        end

        if element ~= nil then
            msgElements.add(element)
        end
    end

    return msgElements
end

-- 消息发送的流程封装
local sendMsgBase2 = function(contact, msg)
    local msgElements = processMessageContent(contact, msg)
    sendMsgBase(contact, msgElements)
end
```

#### **3. 主接口函数**

```lua
_G["sendMsg"] = function(peerUin, msg, type)
    -- 1. 创建 Contact 对象
    local contact = makeContact(String(peerUin), type)
    -- 2. 解析消息内容并发送
    return sendMsgBase2(contact, msg)
end
```
