---@diagnostic disable: undefined-global
imports "org.nanohttpd.protocols.http.NanoHTTPD"
imports "java.io.File"
imports "java.io.FileInputStream"
imports "java.io.FileOutputStream"
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

local Status = luajava.bindClass "org.nanohttpd.protocols.http.response.Status"
local Response = luajava.bindClass "org.nanohttpd.protocols.http.response.Response"
local Method = luajava.bindClass "org.nanohttpd.protocols.http.request.Method"

local isInit = false
local PORT = 8888

local filePath = "/sdcard/Download/LuaQQ/"

-- 路由系统
local routes = {}

-- 路由注册函数
function Route(method, path, handler)
    local methodStr = tostring(method)
    routes[methodStr .. ":" .. path] = {
        method = method,
        methodStr = methodStr,
        path = path,
        handler = handler
    }
    -- print("注册路由: " .. methodStr .. " " .. path)
end

-- 匹配路由
local function matchRoute(method, uri)
    -- 提取路径（去除查询参数）
    local path = uri:match("([^?]*)")
    local methodStr = tostring(method)
    return routes[methodStr .. ":" .. path]
end

-- 文件上传处理函数
local function handleFileUpload(session)
    print("开始处理文件上传")
    local files = HashMap.new()

    local ok, err = pcall(function()
        session.parseBody(files)
    end)

    if not ok then
        print("parseBody出错：" .. tostring(err))
        return nil, "parseBody error"
    end

    -- 从解析后的数据中获取参数
    local postParams = session.getParms()
    print("POST参数 = " .. tostring(postParams))

    local tmpPath = files["file"]
    print("临时文件路径 = " .. tostring(tmpPath))

    if not tmpPath then
        print("没有找到file字段")
        return nil, "No file"
    end

    local originName = postParams["file"] or postParams["filename"] or "unknown.bin"
    print("上传文件名 = " .. tostring(originName))

    if ! file.isExists(filePath) then
        os.execute("mkdir " .. filePath)
    end

    local savePath = filePath .. originName
    print("保存路径 = " .. savePath)

    -- 文件保存
    local ok, err = pcall(function()
        local inFile = FileInputStream(File(tmpPath))
        local outFile = FileOutputStream(File(savePath))
        local buf = byte[4096]

        print("开始写入文件")
        while true do
            local r = inFile.read(buf)
            if r <= 0 then break end
            outFile.write(buf, 0, r)
        end

        outFile.close()
        inFile.close()
    end)

    if not ok then
        print("文件保存失败：" .. tostring(err))
        return nil, "Save file error: " .. tostring(err)
    end

    print("文件保存完成 => " .. savePath)
    return savePath, nil
end


-- 注册所有路由
local function registerRoutes()
    Route("GET", "/ping", function(params, session)
        return {
            status = 200,
            time = System.currentTimeMillis()
        }
    end)

    Route("GET", "/getQQ", function(params, session)
        local ok, result = pcall(getCurrentAccountUin)
        if ok then
            return {
                status = 200,
                result = result
            }
        else
            return {
                status = 500,
                message = "获取QQ失败: " .. tostring(result)
            }
        end
    end)

    Route("GET", "/sendMsg", function(params, session)
        local toUin = params["toUin"]
        local chatType = params["chatType"]
        local msg = params["msg"]
        print(toUin, chatType, msg)
        if toUin and msg and chatType then
            local ok, result = pcall(function()
                return sendMsg(toUin, msg, int(chatType))
            end)
            if ok then
                return {
                    status = 200,
                    result = result
                }
            else
                return {
                    status = 500,
                    message = "发送消息失败: " .. tostring(result)
                }
            end
        end
        return {
            status = 500,
            message = "Missing parameters"
        }
    end)

    Route("GET", "/getAllFriend", function(params, session)
        local ok, result = pcall(getAllFriend)
        if ok then
            return {
                status = 200,
                result = result
            }
        else
            return {
                status = 500,
                message = "获取好友列表失败: " .. tostring(result)
            }
        end
    end)

    Route("GET", "/getGroupList", function(params, session)
        local ok, result = pcall(getGroupList)
        if ok then
            return {
                status = 200,
                result = result
            }
        else
            return {
                status = 500,
                message = "获取群列表失败: " .. tostring(result)
            }
        end
    end)

    Route("GET", "/sendPai", function(params, session)
        local toUin = params["toUin"]
        local peerUin = params["peerUin"]
        local chatType = params["chatType"]
        if toUin and peerUin and chatType then
            local ok, result = pcall(function()
                return sendPai(String(toUin), String(peerUin), int(chatType))
            end)
            if ok then
                return {
                    status = 200,
                    result = result
                }
            else
                return {
                    status = 500,
                    message = "发送拍一拍失败: " .. tostring(result)
                }
            end
        end
        return {
            status = 500,
            message = "Missing parameters"
        }
    end)

    Route("GET", "/sendFile", function(params, session)
        local toUin = params["toUin"]
        local chatType = params["chatType"]
        local filePath = params["filePath"]
        if toUin and filePath and chatType then
            local ok, result = pcall(function()
                return sendFile(toUin, filePath, int(chatType))
            end)
            if ok then
                return {
                    status = 200,
                    result = result
                }
            else
                return {
                    status = 500,
                    message = "发送文件失败: " .. tostring(result)
                }
            end
        end
        return {
            status = 500,
            message = "Missing parameters"
        }
    end)

    Route("GET", "/sendVideo", function(params, session)
        local toUin = params["toUin"]
        local chatType = params["chatType"]
        local filePath = params["filePath"]
        if toUin and filePath and chatType then
            local ok, result = pcall(function()
                return sendVideo(toUin, filePath, int(chatType))
            end)
            if ok then
                return {
                    status = 200,
                    result = result
                }
            else
                return {
                    status = 500,
                    message = "发送视频失败: " .. tostring(result)
                }
            end
        end
        return {
            status = 500,
            message = "Missing parameters"
        }
    end)

    Route("GET", "/sendPic", function(params, session)
        local toUin = params["toUin"]
        local chatType = params["chatType"]
        local filePath = params["filePath"]
        if toUin and filePath and chatType then
            local ok, result = pcall(function()
                return sendPic(toUin, filePath, int(chatType))
            end)
            if ok then
                return {
                    status = 200,
                    result = result
                }
            else
                return {
                    status = 500,
                    message = "发送图片失败: " .. tostring(result)
                }
            end
        end
        return {
            status = 500,
            message = "Missing parameters"
        }
    end)


    Route("GET", "/recallMsg", function(params, session)
        local toUin = params["toUin"]
        local chatType = params["chatType"]
        local msgIds = params["msgIds"]
        if toUin and msgIds and chatType then
            local ids = {}
            for id in msgIds:gmatch("[^,]+") do
                table.insert(ids, Long.valueOf(id))
            end
            local ok, result = pcall(function()
                return recallMsg(int(chatType), toUin, ids)
            end)
            if ok then
                return {
                    status = 200,
                    result = result
                }
            else
                return {
                    status = 500,
                    message = "撤回消息失败: " .. tostring(result)
                }
            end
        end
        return {
            status = 500,
            message = "Missing parameters"
        }
    end)


    Route("POST", "/sendFile", function(params, session)
        local savePath, err = handleFileUpload(session)
        if not savePath then
            return {
                status = 500,
                message = "上传失败: " .. tostring(err)
            }
        end

        local toUin = params["toUin"]
        local chatType = params["chatType"]

        if not (toUin and chatType) then
            return {
                status = 500,
                message = "Missing parameters: toUin, chatType"
            }
        end

        local ok, result = pcall(function()
            return sendFile(toUin, savePath, int(chatType))
        end)

        if ok then
            return {
                status = 200,
                result = result,
                path = savePath
            }
        else
            return {
                status = 500,
                message = "发送文件失败: " .. tostring(result),
                path = savePath
            }
        end
    end)

    Route("POST", "/sendVideo", function(params, session)
        local savePath, err = handleFileUpload(session)
        if not savePath then
            return {
                status = 500,
                message = "上传失败: " .. tostring(err)
            }
        end


        local toUin = params["toUin"]
        local chatType = params["chatType"]

        if not (toUin and chatType) then
            return {
                status = 500,
                message = "Missing parameters: toUin, chatType"
            }
        end

        local ok, result = pcall(function()
            return sendVideo(toUin, savePath, int(chatType))
        end)

        if ok then
            return {
                status = 200,
                result = result,
                path = savePath
            }
        else
            return {
                status = 500,
                message = "发送视频失败: " .. tostring(result),
                path = savePath
            }
        end
    end)

    Route("POST", "/sendPic", function(params, session)
        local savePath, err = handleFileUpload(session)
        if not savePath then
            return {
                status = 500,
                message = "上传失败: " .. tostring(err)
            }
        end

        local toUin = params["toUin"]
        local chatType = params["chatType"]

        if not (toUin and chatType) then
            return {
                status = 500,
                message = "Missing parameters: toUin, chatType"
            }
        end

        local ok, result = pcall(function()
            return sendPic(toUin, savePath, int(chatType))
        end)

        if ok then
            return {
                status = 200,
                result = result,
                path = savePath
            }
        else
            return {
                status = 500,
                message = "发送图片失败: " .. tostring(result),
                path = savePath
            }
        end
    end)
end



local sQQAppInterface = nil
hook {
    class = "android.app.Application",
    classLoader = lpparam.classLoader,
    method = "attach",
    params = { "android.content.Context" },
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


        _G["recallMsg"]          = function(type, peerUin, msgIds)
            recallMsgBase(makeContact(peerUin, int(type)), msgIds);
        end

        local createVideoElement = function(path)
            local sMsgUtilApiImpl = makeDefaultObject(findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"))
            local sCreateVideoElement = MethodInfo() {
                declaredClass = findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"),
                methodName = "createVideoElement",
                parameters = { String },
            }.generate().firstOrNull()

            return sCreateVideoElement.invoke(sMsgUtilApiImpl, { path })
        end

        _G["sendVideo"]          = function(peerUin, path, type)
            local contact = makeContact(String(peerUin), type)
            local msgElements = ArrayList.new()
            msgElements.add(createVideoElement(path))
            sendMsgBase(contact, msgElements)
        end

        local createPicElement   = function(path)
            local sMsgUtilApiImpl = makeDefaultObject(findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"))
            local sCreatePicElement = MethodInfo() {
                declaredClass = findClass("com.tencent.qqnt.msg.api.impl.MsgUtilApiImpl"),
                methodName = "createPicElement",
                parameters = { String, Boolean.TYPE, Integer.TYPE },
            }.generate().firstOrNull()
            log("createPicElement: " .. tostring(sCreatePicElement) .. " path: " .. tostring(path) .. " true 0")
            return sCreatePicElement.invoke(sMsgUtilApiImpl, String(path), true, int(0))
        end


        _G["sendPic"] = function(peerUin, path, type)
            local contact = makeContact(String(peerUin), type)
            local msgElements = ArrayList.new()
            msgElements.add(createPicElement(path))
            sendMsgBase(contact, msgElements)
        end

        local function createCorsResponse(status, contentType, content)
            local response = Response.newFixedLengthResponse(status, contentType, content)
            -- 添加 CORS 头
            response.addHeader("Access-Control-Allow-Origin", "*")
            response.addHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH")
            response.addHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With, Accept")
            response.addHeader("Access-Control-Allow-Credentials", "true")
            response.addHeader("Access-Control-Max-Age", "86400")
            return response
        end

        hook {
            class = "android.app.Activity",
            classLoader = loader,
            method = "onCreate",
            params = { "android.os.Bundle" },

            after = function(it)
                local context = it.thisObject
                local name = context.getClass().getName()
                if isInit then
                    return
                end

                if name ~= "com.tencent.mobileqq.activity.SplashActivity" then
                    return
                else
                    isInit = true
                end

                print("MainActivity.onCreate => 准备启动HTTP服务")

                -- 注册所有路由
                registerRoutes()

                local server = NanoHTTPD.override {
                    serve = function(super, session)
                        print("收到HTTP请求")
                        local method = session.getMethod()
                        local uri = session.getUri()
                        print("URI = " .. tostring(uri))
                        print("Method = " .. tostring(method))

                        -- 获取参数
                        local params = session.getParms() or HashMap.new()

                        -- 打印参数用于调试
                        if params and params.size() > 0 then
                            print("请求参数:")
                            local paramIterator = params.entrySet().iterator()
                            while paramIterator.hasNext() do
                                local entry = paramIterator.next()
                                print("  " .. tostring(entry.getKey()) .. " = " .. tostring(entry.getValue()))
                            end
                        end

                        -- 尝试匹配路由
                        local route = matchRoute(method, uri)

                        if route then
                            print("匹配到路由: " .. route.method .. " " .. route.path)

                            -- 执行路由处理器
                            local ok, result = pcall(function()
                                return route.handler(params, session)
                            end)

                            if ok then
                                -- 将结果转换为JSON响应
                                local jsonResponse = json.encode(result)
                                print("路由处理成功，返回JSON响应")
                                return createCorsResponse(
                                    Status.OK,
                                    "application/json",
                                    jsonResponse
                                )
                            else
                                print("路由处理出错：" .. tostring(result))
                                return createCorsResponse(
                                    Status.INTERNAL_ERROR,
                                    "application/json",
                                    json.encode({
                                        status = 500,
                                        message = "Internal server error: " .. tostring(result)
                                    })
                                )
                            end
                        end

                        -- 其他请求返回404 Not Found
                        print("未匹配到路由: " .. uri)
                        return createCorsResponse(
                            Status.NOT_FOUND,
                            "application/json",
                            json.encode({
                                status = 500,
                                message = "Route not found: " .. uri
                            })
                        )
                    end
                }

                local s = server(PORT)
                print("准备启动HTTP服务...")
                s.start()
                print("HTTP服务启动成功 => " .. PORT)
                print("可用路由:")
                for key, route in pairs(routes) do
                    print("  " .. route.method .. " " .. route.path)
                end
            end
        }
    end
}
