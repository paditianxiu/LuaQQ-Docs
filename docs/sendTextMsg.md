# 发送消息 (`/sendMsg`)

用于发送私聊或群聊消息. 支持同时发送 **艾特消息** (`[atUin=<QQ号]`).

```
GET /sendMsg?qq=<目标UIN>&msg=<消息内容>&type=<消息类型>
```

| 参数   | 描述                       |
| :----- | :------------------------- |
| `qq`   | 目标 QQ 号或群号（UIN）    |
| `msg`  | 要发送的消息内容           |
| `type` | **1** 为私聊，**2** 为群聊 |

**群聊示例：**
`http://localhost:8888/sendMsg?qq=98765&msg=[atUin=0]这是一条通知&type=2`

**私聊示例：**
`http://localhost:8888/sendMsg?qq=10001&msg=你好&type=1`
