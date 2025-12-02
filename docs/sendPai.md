# 拍一拍 (`/sendPai`)

用于发送拍一拍功能.

```
GET /sendPai?toUin=<被拍UIN>&peerUin=<目标UIN>&chatType=<聊天类型>
```

| 参数       | 描述                           |
| :--------- | :----------------------------- |
| `toUin`    | 被拍用户的 QQ UIN (String)     |
| `peerUin`  | 当前会话的目标 UIN (String)    |
| `chatType` | 聊天类型 (int, 1 私聊, 2 群聊) |

**示例 URL：** `http://localhost:8888/sendPai?toUin=123456&peerUin=98765&chatType=2`

---
