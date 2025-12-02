---@diagnostic disable: undefined-global

---@diagnostic disable: undefined-global

--[[
作者：帕帝天秀
TG：@paditianxiu
参考文献：https://github.com/oneQAQone/QFun

HTTP服务器功能说明：
- 监听端口：localhost:8888（使用getLocalIpAddress(ctx)获取本机IP）

API接口列表：
- 获取QQ号：/getQQ
- 发送消息：/sendMsg?toUin=QQ/群号&msg=消息内容&chatType=1/2
- 发送文件: /sendFile?toUin=QQ/群号&filePath=文件路径&chatType=1/2
- 撤回消息: /recallMsg?toUin=QQ/群号&msgIds=1,2,3&chatType=1/2
- 拍一拍好友：/sendPai?toUin=QQ号&peerUin=QQ/群号&chatType=1/2
- 获取好友列表：/getAllFriend
- 获取群聊列表：/getGroupList

]]

imports "top.sacz.xphelper.dexkit.FieldFinder"
imports "java.lang.reflect.Modifier"
imports "top.sacz.xphelper.dexkit.bean.MethodInfo"
imports "top.sacz.xphelper.dexkit.bean.FieldInfo"
imports "top.sacz.xphelper.dexkit.bean.ClassInfo"
imports "java.lang.Void"
imports "android.net.Uri"
imports "java.lang.Integer"
imports "java.lang.String"
imports "java.lang.Boolean"
imports "java.lang.Object"
imports "java.lang.System"
imports "java.lang.Class"
imports "java.lang.Long"
imports "top.sacz.xphelper.util.ActivityTools"
imports "java.util.HashMap"
imports "java.util.ArrayList"
imports "java.util.regex.Pattern"
imports "java.util.AbstractMap.SimpleEntry"
imports "java.net.ServerSocket"
imports "java.net.Socket"
imports "java.net.InetAddress"
imports "java.io.BufferedReader"
imports "java.io.InputStreamReader"
imports "java.io.OutputStreamWriter"
imports "java.io.BufferedWriter"
imports "java.lang.Thread"
imports "java.lang.Runnable"
imports "java.util.concurrent.atomic.AtomicBoolean"
imports "java.lang.System"
imports "java.net.URLDecoder"
imports "java.util.List "

local isInit = false
local PORT = 8888
local BACKLOG = 50
local SOCKET_TIMEOUT = 5000 -- 5秒超时

local running = AtomicBoolean(false)
local server = nil

-- 日志函数
local function log(msg)
    print("[HTTP Server] " .. tostring(msg))
end

local function readRequestLine(reader)
    local line = reader.readLine()
    log("Request Line: " .. tostring(line))
    return line
end

local function readHeaders(reader)
    local t = {}
    while true do
        local line = reader.readLine()
        if not line or line == "" then
            log("Headers end")
            break
        end
        log("Header: " .. line)
        local k, v = line:match("^(.-):%s*(.*)$")
        if k then
            t[k:lower()] = v
            log("Parsed header: " .. k:lower() .. " = " .. v)
        end
    end
    return t
end


local function sendResponse(outStream, code, text, headers, body)
    log("Sending response: " .. code .. " " .. text)
    local bw = BufferedWriter(OutputStreamWriter(outStream))
    bw.write("HTTP/1.1 " .. code .. " " .. text .. "\r\n")
    bw.write("Access-Control-Allow-Origin: *\r\n")
    bw.write("Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE\r\n")
    bw.write("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With\r\n")

    for k, v in pairs(headers) do
        bw.write(k .. ": " .. v .. "\r\n")
        log("Response header: " .. k .. ": " .. v)
    end
    bw.write("\r\n")
    if body then
        bw.write(body)
        log("Response body: " .. body)
    end
    bw.flush()
    log("Response sent successfully")
end

local function urlDecode(str)
    return URLDecoder.decode(str, "UTF-8")
end

-- 定义路由处理器映射表
local routeHandlers = {
    GET = {},
    POST = {},
    -- 可以添加其他HTTP方法
}

-- 主处理函数
local function handleClient(client)
    log("New client connected: " .. tostring(client))

    local ok, err = pcall(function()
        local reader = BufferedReader(InputStreamReader(client.getInputStream()))
        local requestLine = (readRequestLine(reader))
        if not requestLine then
            log("No request line received, closing connection")
            client.close()
            return
        end

        local method, path, version = requestLine:match("^(%w+)%s+([^%s]+)%s+(HTTP/[%d%.]+)$")
        if not method then
            method, path = requestLine:match("^(%w+)%s+([^%s]+)")
        end

        log("Parsed request - Method: " .. tostring(method) .. ", Path: " .. tostring(path))

        -- 解析GET参数
        local getParams = {}
        local pathWithoutQuery = path
        local queryString = path:match("%?(.+)")

        if queryString then
            pathWithoutQuery = path:match("^([^%?]*)%?") or path:match("^([^%?]*)")

            -- 解析查询字符串
            for key, value in queryString:gmatch("([^&=]+)=([^&=]*)") do
                getParams[key] = urlDecode(value)
                log("GET parameter - " .. key .. ": " .. value)
            end
        end

        local headers = readHeaders(reader)
        log("Headers count: " .. tostring(#headers))

        local out = client.getOutputStream()
        local responseTable = {}

        -- 根据HTTP方法获取对应的路由处理器
        local methodHandlers = routeHandlers[string.upper(method or "GET")] or {}

        if methodHandlers then
            -- 查找匹配的路由处理器
            local handler = methodHandlers[pathWithoutQuery] or methodHandlers["*"]

            if handler then
                -- 调用路由处理器
                responseTable = handler(getParams, headers, pathWithoutQuery, method)
                log("Handling request for path: " .. pathWithoutQuery)
            else
                -- 没有找到处理器，返回404
                responseTable = {
                    status = "error",
                    message = "Path not found: " .. pathWithoutQuery,
                    time = System.currentTimeMillis()
                }
                log("No handler found for path: " .. pathWithoutQuery)
            end
        else
            -- 方法不允许
            responseTable = {
                error = "method not allowed"
            }
            local resp = json.encode(responseTable)
            log("Method not allowed: " .. tostring(method))
            sendResponse(out, 405, "Method Not Allowed", {
                ["Content-Type"] = "application/json; charset=utf-8",
                ["Content-Length"] = tostring(#resp),
                ["Connection"] = "close"
            }, resp)
            client.close()
            return
        end

        -- 编码JSON响应
        local resp = json.encode(responseTable)
        sendResponse(out, 200, "OK", {
            ["Content-Type"] = "application/json; charset=utf-8",
            ["Content-Length"] = tostring(#resp),
            ["Connection"] = "close"
        }, resp)

        log("Request handling completed, closing client connection")
        client.close()
    end)

    if not ok then
        log("Error handling client: " .. tostring(err))
        pcall(function()
            client.close()
            log("Client connection closed after error")
        end)
    end
end


local function Route(method, path, handler)
    method = string.upper(method)
    if not routeHandlers[method] then
        routeHandlers[method] = {}
    end
    routeHandlers[method][path] = handler
    log("Registered route: " .. method .. " " .. path)
end




local function startAcceptLoop()
    return Runnable {
        run = function()
            log("Accept loop started")
            local acceptCount = 0
            local timeoutCount = 0

            while running.get() do
                local ok, client, err = pcall(function()
                    -- if acceptCount % 10 == 0 then
                    --   log("Waiting for client connection... (timeouts: " .. timeoutCount .. ")")
                    -- end
                    local c = server.accept()
                    acceptCount = acceptCount + 1
                    log("Client connection accepted: " .. tostring(c) .. " (total: " .. acceptCount .. ")")
                    return c
                end)

                if ok and client then
                    log("Spawning new thread for client handling")
                    Thread(Runnable {
                        run = function()
                            handleClient(client)
                        end
                    }).start()
                else
                    if not running.get() then
                        log("Server stopped, breaking accept loop")
                        break
                    end

                    local errorMsg = tostring(client or "Unknown error")
                    -- 如果是超时异常，增加计数器但不记录错误
                    if errorMsg:find("SocketTimeoutException") then
                        timeoutCount = timeoutCount + 1
                        -- 每20次超时输出一次日志
                        if timeoutCount % 20 == 0 then
                            log("No client connections received (total timeouts: " .. timeoutCount .. ")")
                        end
                    else
                        log("Accept failed: " .. errorMsg)
                    end
                end
            end
            log("Accept loop ended - Total connections: " .. acceptCount .. ", Total timeouts: " .. timeoutCount)
        end
    }
end



local sQQAppInterface

hook {
    class = "android.app.Application",
    classLoader = lpparam.classLoader,
    method = "attach",
    params = { "android.content.Context" },
    before = function(it)
    end,
    after = function(it)
        local appContext = it.thisObject
        XpHelper.initContext(appContext)
        XpHelper.injectResourcesToContext(appContext)
        local loader = appContext.getClassLoader()

        local sSendMsg = MethodInfo() {
            declaredClass = findClass("com.tencent.qqnt.kernel.nativeinterface.IKernelMsgService$CppProxy"),
            methodName = "sendMsg",
        }.generate().firstOrNull()

        local sGenerateMsgUniqueId = MethodInfo() {
            declaredClass = findClass("com.tencent.qqnt.kernel.nativeinterface.IKernelMsgService$CppProxy"),
            methodName = "generateMsgUniqueId",
        }.generate().firstOrNull()


        local onCreate = MethodInfo() {
            declaredClass = findClass("com.tencent.mobileqq.app.QQAppInterface"),
            methodName = "onCreateQQMessageFacade",
        }.generate().firstOrNull()

        hook(onCreate,
            function(it)
                sQQAppInterface = it.thisObject
            end,
            function(it)
                sQQAppInterface = it.thisObject
            end
        )


        _G["getQQAppInterface"] = function()
            return sQQAppInterface
        end


        local getKernelMsgservice = function()
            local iKernelIService = findClass("com.tencent.qqnt.kernel.api.IKernelService");
            local kernelService = invoke(sQQAppInterface, "getRuntimeService", iKernelIService, "")
            local msgService = invoke(kernelService, "getMsgService")
            return invoke(msgService, "getService")
        end

        local generateMsgUniqueId = function(chatType)
            return sGenerateMsgUniqueId.invoke(getKernelMsgservice(), int(chatType), System.currentTimeMillis())
        end

        local sendMsgBase = function(contact, elements)
            local chatType = getField(contact, "chatType")
            local msgId = generateMsgUniqueId(chatType);
            sSendMsg.invoke(getKernelMsgservice(), msgId, contact, elements, HashMap(), nil)
        end

        local function splitMessageString(input)
            input = String(input)
            local result = ArrayList.new()

            local pattern = Pattern.compile("\\[atUin=\\d+]|\\[pic=.*?]");
            local matcher = pattern.matcher(input);
            local lastEnd = 0;

            while (matcher.find()) do
                local start_ = matcher.start();
                local end_ = matcher["end"]();
                if (start_ > lastEnd) then
                    result.add(input.substring(lastEnd, start_));
                end
                result.add(input.substring(start_, end_));
                lastEnd = end_;
            end
            if (lastEnd < input.length()) then
                result.add(input.substring(lastEnd));
            end
            return result
        end



        local function processMessageParts(input)
            local parts = splitMessageString(input)
            local entries = ArrayList.new()
            local tagPattern = Pattern.compile("\\[(atUin|pic)=([^]]*)]");

            for i = 0, parts.size() - 1 do
                local part = String(parts.get(i))
                if (part.startsWith("[") and part.endsWith("]")) then
                    local matcher = tagPattern.matcher(part);
                    if (matcher.matches()) then
                        entries.add(SimpleEntry.new(matcher.group(1), matcher.group(2)));
                    else
                        entries.add(SimpleEntry.new("text", part));
                    end
                else
                    entries.add(SimpleEntry.new("text", part))
                end
            end
            return entries
        end



        local sCreateTextElement = MethodInfo() {
            declaredClass = findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"),
            methodName = "createTextElement",
            parameters = { String },
        }.generate().firstOrNull()



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
                end
            end

            log("创建 " .. tostring(clazz) .. " 对象失败，尝试了 " .. constructors.length .. " 个构造函数")


            return nil
        end


        local getUidFromUin = function(uin)
            local RelationNTUinAndUidApiImpl = makeDefaultObject(findClass(
                "com.tencent.relation.common.api.impl.RelationNTUinAndUidApiImpl"))
            local result = invoke(RelationNTUinAndUidApiImpl, "getUidFromUin", String(uin))
            return result
        end


        local createTextElement = function(value)
            local sMsgUtilApiImpl = makeDefaultObject(findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"))
            return sCreateTextElement.invoke(sMsgUtilApiImpl, { value })
        end

        local sCreateAtTextElement = MethodInfo() {
            declaredClass = findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"),
            methodName = "createAtTextElement",
        }.generate().firstOrNull()

        local createAtTextElement = function(uid, atType)
            local sMsgUtilApiImpl = makeDefaultObject(findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"))
            return sCreateAtTextElement.invoke(sMsgUtilApiImpl, "@全体成员", uid, int(atType));
        end


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
                    local atType
                    local uid
                    if value == "0" then
                        atType = 1
                        uid = "0"
                    else
                        atType = 2
                        uid = getUidFromUin(value);
                    end
                    element = createAtTextElement(uid, atType);
                end

                if element ~= nil then
                    msgElements.add(element)
                end
            end

            return msgElements
        end


        local sendMsgBase2 = function(contact, msg)
            local msgElements = processMessageContent(contact, msg)
            sendMsgBase(contact, msgElements)
        end

        local getUidFromUin = function(uin)
            local RelationNTUinAndUidApiImpl = makeDefaultObject(findClass(
                "com.tencent.relation.common.api.impl.RelationNTUinAndUidApiImpl"))
            local result = invoke(RelationNTUinAndUidApiImpl, "getUidFromUin", String(uin))
            return result
        end

        local function makeContact(peerUin, type)
            local peerUid
            if type == int(1) or type == int(100) then
                peerUid = getUidFromUin(peerUin)
            elseif type == int(2) then
                peerUid = peerUin
            else
                peerUid = nil
            end

            return makeDefaultObject(findClass("com.tencent.qqnt.kernelpublic.nativeinterface.Contact"), type, peerUid,
                "")
        end

        _G["sendMsg"]              = function(peerUin, msg, type)
            return sendMsgBase2(makeContact(String(peerUin), type), msg)
        end

        _G["sendPai"]              = function(toUin, peerUin, chatType)
            local sSendPai

            sSendPai = MethodInfo() {
                declaredClass = findClass("com.tencent.mobileqq.paiyipai.PaiYiPaiHandler"),
                parameters = { String, String, int, int },
                returnType = Void.TYPE,
            }.generate().firstOrNull()

            if ! sSendPai then
                sSendPai = MethodInfo() {
                    declaredClass = findClass("com.tencent.mobileqq.paiyipai.PaiYiPaiHandler"),
                    parameters = { int, int, String, String },
                    returnType = Void.TYPE,
                }.generate().firstOrNull()
            end

            local cls = findClass("com.tencent.mobileqq.paiyipai.PaiYiPaiHandler")

            local ctor = cls.getDeclaredConstructor({
                sQQAppInterface.class
            })
            ctor.setAccessible(true)
            local paiYiPaiHandler = ctor.newInstance(Object.array { sQQAppInterface })

            local ok = pcall(function()
                callMethod(sSendPai, paiYiPaiHandler, toUin, peerUin, chatType, 1)
            end)
            if not ok then
                callMethod(sSendPai, paiYiPaiHandler, chatType, 1, toUin, peerUin)
                ok = true
            end

            return ok
        end

        _G["getAllFriend"]         = function()
            local friendList = {}
            local FriendsInfoServiceImpl = makeDefaultObject(findClass(
                "com.tencent.qqnt.ntrelation.friendsinfo.api.impl.FriendsInfoServiceImpl"))
            local friendInfoList = invoke(FriendsInfoServiceImpl, "getAllFriend", "")
            for _, friendInfo in friendInfoList do
                local uin = tostring(friendInfo.uin) or ""
                local uid = tostring(friendInfo.uid) or ""
                local name = invoke(FriendsInfoServiceImpl, "getNickWithUid", uid, "") or ""
                local remark = invoke(FriendsInfoServiceImpl, "getRemarkWithUid", uid, "") or ""

                friendList[#friendList + 1] = {
                    uin = uin,
                    uid = uid,
                    name = name,
                    remark = remark
                }
            end
            return friendList
        end

        _G["getGroupList"]         = function()
            local groupList = {}
            local troopListRepoApiImpl = makeDefaultObject(findClass(
                "com.tencent.qqnt.troop.impl.TroopListRepoApiImpl"))
            if ! troopListRepoApiImpl then
                return
            end

            local sGetTroopList = MethodInfo() {
                declaredClass = troopListRepoApiImpl.getClass(),
                methodName = "getSortedJoinedTroopInfoFromCache",
            }.generate().firstOrNull()
            local troopInfoList = {}
            while troopInfoList == nil or #troopInfoList == 0 do
                troopInfoList = sGetTroopList.invoke(troopListRepoApiImpl) or {}
            end


            for _, troopInfo in troopInfoList do
                local troopMap = {}
                local group = getField(troopInfo, "troopuin") or ""
                local groupName = getField(troopInfo, "troopNameFromNT") or ""
                local groupOwner = getField(troopInfo, "troopowneruin") or ""
                troopMap["group"] = tostring(group)
                troopMap["groupName"] = tostring(groupName or group)
                troopMap["groupOwner"] = tostring(groupOwner)
                troopMap["groupInfo"] = troopInfo

                table.insert(groupList, troopMap)
            end

            return groupList
        end

        _G["getCurrentAccountUin"] = function()
            return invoke(sQQAppInterface, "getCurrentAccountUin")
        end

        local createFileElement    = function(path)
            local sMsgUtilApiImpl = makeDefaultObject(findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"))
            local sCreateFileElement = MethodInfo() {
                declaredClass = findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"),
                methodName = "createFileElement",
                parameters = { String },
            }.generate().firstOrNull()

            return sCreateFileElement.invoke(sMsgUtilApiImpl, { path })
        end

        _G["sendFile"]             = function(peerUin, path, type)
            local contact = makeContact(String(peerUin), type)
            local msgElements = ArrayList.new()
            msgElements.add(createFileElement(path))
            sendMsgBase(contact, msgElements)
        end

        local recallMsgBase2       = function(contact, msgIds)
            local sRecallMsg
            sRecallMsg = MethodInfo() {
                declaredClass = findClass("com.tencent.qqnt.kernel.nativeinterface.IKernelMsgService$CppProxy"),
                methodName = "recallMsg",
            }.generate().firstOrNull()
            sRecallMsg.invoke(getKernelMsgservice(), contact, msgIds, nil)
        end
        local recallMsgBase        = function(contact, msgId)
            local msgIds = ArrayList.new()
            for _, value in ipairs(msgId) do
                msgIds.add(value)
            end
            recallMsgBase2(contact, msgIds)
        end


        _G["recallMsg"] = function(type, peerUin, msgIds)
            recallMsgBase(makeContact(peerUin, int(type)), msgIds);
        end


        _G["registerRoutes"] = function()
            Route("GET", "*", function(getParams, headers, pathWithoutQuery, method)
                return {
                    path = pathWithoutQuery,
                    method = method,
                    time = System.currentTimeMillis(),
                    params = getParams
                }
            end)

            Route("GET", "/ping", function()
                return {
                    status = "ok",
                    time = System.currentTimeMillis()
                }
            end)

            Route("GET", "/getQQ", function()
                local result = getCurrentAccountUin()
                return {
                    status = result and "ok" or "error",
                    result = result
                }
            end)

            Route("GET", "/sendMsg", function(getParams)
                local toUin = getParams["toUin"]
                local chatType = getParams["chatType"]
                local msg = getParams["msg"]
                if toUin and msg and chatType then
                    local result = sendMsg(toUin, msg, int(chatType))
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

            Route("GET", "/getAllFriend", function()
                local result = getAllFriend()
                return {
                    status = result and "ok" or "error",
                    result = result
                }
            end)

            Route("GET", "/getGroupList", function()
                local result = getGroupList()
                return {
                    status = result and "ok" or "error",
                    result = result
                }
            end)

            Route("GET", "/sendPai", function(getParams)
                local toUin = getParams["toUin"]
                local peerUin = getParams["peerUin"]
                local chatType = int(getParams["chatType"])
                if toUin and peerUin and chatType then
                    local result = sendPai(String(toUin), String(peerUin), chatType)
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

            Route("GET", "/sendFile", function(getParams)
                local toUin = getParams["toUin"]
                local chatType = getParams["chatType"]
                local filePath = getParams["filePath"]
                if toUin and filePath and chatType then
                    local result = sendFile(toUin, filePath, int(chatType))
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

            Route("GET", "/recallMsg", function(getParams)
                local ids = {}
                local toUin = getParams["toUin"]
                local chatType = getParams["chatType"]
                local msgIds = getParams["msgIds"]
                if toUin and msgIds and chatType then
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
        end


        hookOnKeyDown(loader)
        hookOnCreate(loader)
        hookOnDestroy(loader)
    end
}


_G["hookOnKeyDown"] = function(loader)
    hook {
        class = "android.app.Activity",
        classloader = loader,
        method = "onKeyDown",
        params = { "int", "android.view.KeyEvent" },
        before = function(it)
        end,
        after = function(it)
            local context = it.thisObject
            local keyCode = it.args[0]
            if keyCode == 24 then
            end
        end
    }
end


_G["hookOnCreate"] = function(loader)
    hook {
        class = "android.app.Activity",
        classLoader = loader,
        method = "onCreate",
        params = { "android.os.Bundle" },
        after = function(it)
            local ctx = it.thisObject
            running.set(true)

            local name = ctx.getClass().getName()
            if isInit then
                return
            end

            if name ~= "com.tencent.mobileqq.activity.SplashActivity" then
                return
            else
                isInit = true
            end


            Thread(Runnable {
                run = function()
                    log("Starting server thread...")
                    local ok, err = pcall(function()
                        log("Creating ServerSocket on port " .. PORT)

                        -- 尝试多种方式创建 ServerSocket
                        local ss
                        local success = false

                        -- 方法1: 直接创建
                        local ok1, err1 = pcall(function()
                            ss = ServerSocket(PORT, BACKLOG)
                            log("ServerSocket created with method 1")
                            success = true
                        end)

                        -- 方法2: 绑定到所有地址
                        if not success then
                            log("Method 1 failed, trying method 2...")
                            local ok2, err2 = pcall(function()
                                ss = ServerSocket()
                                ss.setReuseAddress(true)
                                local InetSocketAddress = findClass("java.net.InetSocketAddress")
                                ss.bind(IInetSocketAddress(PORT), BACKLOG)
                                log("ServerSocket created with method 2")
                                success = true
                            end)
                            if not success then
                                log("Method 2 failed: " .. tostring(err2))
                            end
                        end

                        -- 方法3: 绑定到本地地址
                        if not success then
                            log("Trying method 3...")
                            local ok3, err3 = pcall(function()
                                ss = ServerSocket()
                                ss.setReuseAddress(true)
                                local localAddr = InetAddress.getByName("0.0.0.0")
                                local InetSocketAddress = findClass("java.net.InetSocketAddress")
                                ss.bind(InetSocketAddress(localAddr, PORT), BACKLOG)
                                log("ServerSocket created with method 3")
                                success = true
                            end)
                            if not success then
                                log("Method 3 failed: " .. tostring(err3))
                            end
                        end

                        if not success then
                            error("All ServerSocket creation methods failed")
                        end


                        server = ss
                        ctx.__server = ss
                        log("ServerSocket created successfully on port " .. PORT)

                        -- 设置SO_TIMEOUT为5秒
                        ss.setSoTimeout(SOCKET_TIMEOUT)
                        log("Socket timeout set to " .. SOCKET_TIMEOUT .. "ms")

                        -- 开启 Accept 循环
                        Thread(startAcceptLoop()).start()
                        log("Server started successfully on port " .. PORT)

                        -- 测试连接信息
                        log("Server is ready for connections")
                        log("Test with: curl http://" .. getLocalIpAddress(ctx) .. ":" .. PORT .. "/ping")

                        registerRoutes()
                    end)

                    if not ok then
                        log("Server start error: " .. tostring(err))
                        log("Please check:")
                        log("1. App INTERNET permission")
                        log("2. Port " .. PORT .. " availability")
                        log("3. Try different port if needed")
                    end
                end
            }).start()
        end
    }
end

_G["hookOnDestroy"] = function(loader)
    hook {
        class = "android.app.Activity",
        classLoader = loader,
        method = "onDestroy",
        params = {},
        before = function(it)
            if name ~= "com.tencent.mm.ui.LauncherUI" then
                return
            end
            log("Activity destroying, stopping server...")
            running.set(false)
            pcall(function()
                if server then
                    log("Closing server socket...")
                    server.close()
                    server = nil
                    log("Server socket closed")
                end
            end)
            it.thisObject.__server = nil
            log("Server stopped completely")
        end
    }
end

-- 获取局域网IP地址的函数
_G["getLocalIpAddress"] = function(context)
    -- 获取 WifiManager 服务
    local wifiManager = context.getApplicationContext().getSystemService("wifi")

    -- 如果获取不到 WifiManager 或 Wi-Fi 状态不可用
    if wifiManager == nil or not invoke(wifiManager, "isWifiEnabled") then
        log("WiFi is not enabled or WifiManager is null")
        return nil
    end

    -- 检查连接信息是否有效
    local wifiInfo = invoke(wifiManager, "getConnectionInfo")
    if wifiInfo == nil or invoke(wifiInfo, "getIpAddress") == 0 then
        log("WiFi connection info is invalid or IP address is 0")
        return nil
    end

    local ok, ipAddress = pcall(function()
        local ipInt = invoke(wifiInfo, "getIpAddress")
        log("Raw IP address (int): " .. tostring(ipInt))

        -- 将整数IP地址转换为字节数组
        local ByteBuffer = findClass("java.nio.ByteBuffer")
        local ByteOrder = findClass("java.nio.ByteOrder")

        local byteBuffer = ByteBuffer.allocate(4)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        byteBuffer.putInt(ipInt)
        local bytes = byteBuffer.array()

        -- 通过字节数组获取InetAddress
        local InetAddress = findClass("java.net.InetAddress")
        local inetAddress = InetAddress.getByAddress(bytes)
        local ipStr = invoke(inetAddress, "getHostAddress")

        log("Converted IP address: " .. ipStr)
        return ipStr
    end)

    if not ok then
        log("Error converting IP address: " .. tostring(ipAddress))
        return nil
    end

    return ipAddress
end
