# 👏 拍一拍

### ➡️ 接口描述

用于发送“拍一拍”功能。

### 🏷️ 接口路径

```
GET /sendPai?toUin=<被拍UIN>&peerUin=<目标UIN>&chatType=<聊天类型>
```

### 📋 请求参数

| 参数       | 描述                               |
| :--------- | :--------------------------------- |
| `toUin`    | 被拍用户的 QQ UIN (String)         |
| `peerUin`  | 当前会话的目标 UIN (String)        |
| `chatType` | 聊天类型 (int, `1` 私聊, `2` 群聊) |

### 🌐 示例 URL

`http://localhost:8888/sendPai?toUin=123456&peerUin=98765&chatType=2`

### 💡 参考代码（Lua 脚本）

```lua
_G["sendPai"] = function(toUin, peerUin, chatType)
    local sSendPai

    -- 尝试查找第一种方法签名: String, String, int, int
    sSendPai = MethodInfo() {
        declaredClass = findClass("com.tencent.mobileqq.paiyipai.PaiYiPaiHandler"),
        parameters = { String, String, int, int },
        returnType = Void.TYPE,
    }.generate().firstOrNull()

    -- 如果第一种签名未找到，则尝试查找第二种签名: int, int, String, String
    if ! sSendPai then
        sSendPai = MethodInfo() {
            declaredClass = findClass("com.tencent.mobileqq.paiyipai.PaiYiPaiHandler"),
            parameters = { int, int, String, String },
            returnType = Void.TYPE,
        }.generate().firstOrNull()
    end

    local cls = findClass("com.tencent.mobileqq.paiyipai.PaiYiPaiHandler")

    -- 构造 PaiYiPaiHandler 实例
    local ctor = cls.getDeclaredConstructor({
        sQQAppInterface.class -- 假设 sQQAppInterface 是一个全局可用的 QQAppInterface 实例
    })
    ctor.setAccessible(true)
    local paiYiPaiHandler = ctor.newInstance(Object.array { sQQAppInterface })

    local ok = pcall(function()
        -- 尝试使用第一种方法签名调用
        callMethod(sSendPai, paiYiPaiHandler, toUin, peerUin, chatType, 1) -- 假设最后一个参数为固定值 1
    end)

    if not ok then
        -- 如果第一种方法调用失败，则尝试使用第二种方法签名调用
        callMethod(sSendPai, paiYiPaiHandler, chatType, 1, toUin, peerUin) -- 调整参数顺序
        ok = true
    end

    return ok -- 返回操作是否成功的布尔值
end
```
