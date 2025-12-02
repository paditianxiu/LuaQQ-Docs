# 🤖 获取好友/群聊列表

以下是获取好友列表和群列表的 HTTP 接口及其对应的 Lua 脚本参考实现。

---

## 👥 接口一：获取好友列表

### ➡️ 接口描述

返回当前用户的好友列表的 **JSON 字符串**。

### 🏷️ 接口路径

```
GET /getAllFriend
```

### 🌐 示例 URL

`http://localhost:8888/getAllFriend`

### 💡 参考代码（Lua 脚本）

```lua
_G["getAllFriend"] = function()
    local friendList = {}
    -- 查找并实例化 FriendsInfoServiceImpl
    local FriendsInfoServiceImpl = makeDefaultObject(findClass(
        "com.tencent.qqnt.ntrelation.friendsinfo.api.impl.FriendsInfoServiceImpl"))

    -- 调用 API 获取原始好友信息列表
    local friendInfoList = invoke(FriendsInfoServiceImpl, "getAllFriend", "")

    for _, friendInfo in friendInfoList do
        local uin = tostring(friendInfo.uin) or ""
        local uid = tostring(friendInfo.uid) or ""

        -- 通过 FriendsInfoServiceImpl 获取昵称和备注
        local name = invoke(FriendsInfoServiceImpl, "getNickWithUid", uid, "") or ""
        local remark = invoke(FriendsInfoServiceImpl, "getRemarkWithUid", uid, "") or ""

        friendList[#friendList + 1] = {
            uin = uin,
            uid = uid,
            name = name,
            remark = remark
        }
    end

    -- 返回 JSON 格式字符串
    return json.encode(friendList)
end
```

---

## 🏘️ 接口二：获取群列表

### ➡️ 接口描述

返回当前用户加入的群列表的 **JSON 字符串**。

### 🏷️ 接口路径

```
GET /getGroupList
```

### 🌐 示例 URL

`http://localhost:8888/getGroupList`

### 💡 参考代码（Lua 脚本）

```lua
_G["getGroupList"] = function()
    local groupList = {}
    -- 查找并实例化 TroopListRepoApiImpl
    local troopListRepoApiImpl = makeDefaultObject(findClass(
        "com.tencent.qqnt.troop.impl.TroopListRepoApiImpl"))

    if ! troopListRepoApiImpl then
        return -- 无法获取实现类则返回
    end

    -- 查找 getSortedJoinedTroopInfoFromCache 方法
    local sGetTroopList = MethodInfo() {
        declaredClass = troopListRepoApiImpl.getClass(),
        methodName = "getSortedJoinedTroopInfoFromCache",
    }.generate().firstOrNull()

    local troopInfoList = {}
    -- 循环等待直到获取到群信息列表（缓存可能需要加载）
    while troopInfoList == nil or #troopInfoList == 0 do
        troopInfoList = sGetTroopList.invoke(troopListRepoApiImpl) or {}
    end


    for _, troopInfo in troopInfoList do
        local troopMap = {}
        -- 通过反射/字段获取群信息
        local group = getField(troopInfo, "troopuin") or ""
        local groupName = getField(troopInfo, "troopNameFromNT") or ""
        local groupOwner = getField(troopInfo, "troopowneruin") or ""

        troopMap["group"] = tostring(group)
        troopMap["groupName"] = tostring(groupName or group)
        troopMap["groupOwner"] = tostring(groupOwner)
        troopMap["groupInfo"] = troopInfo -- 原始群信息对象，可选

        table.insert(groupList, troopMap)
    end

    -- 返回 JSON 格式字符串
    return json.encode(groupList)
end
```
