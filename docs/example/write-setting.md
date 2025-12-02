# 编写脚本设置页面

## 1. @set 的作用
`@set` 是一个特殊的注解，它用于标识这是一个设置页面的定义。在 LuaHook 环境中，这种注解帮助脚本引擎识别并正确处理设置页面脚本
## 2. 代码概览
```lua
@set
function setActivity()
	import "com.kulipai.luahook.util.*"
	import "java.lang.*"
	import "android.widget.Toast"
	import "android.widget.*"

	function print(...)
		local text = table.concat({ ... }, " ")
		Toast.makeText(this, tostring(text), Toast.LENGTH_SHORT).show()
	end

	local layout = {
		LinearLayout, -- 根布局为线性布局
		gravity = "center", -- 内容居中
		id = "filelayout", -- 布局ID
		orientation = 1, -- 垂直排列(1=垂直，0=水平)
		layout_width = "fill", -- 宽度填满
		layout_height = "fill", -- 高度填满
		{
			TextView, -- 文本视图
			id = "tv", -- 控件ID
			textIsSelectable = true, -- 文本可长按复制
			gravity = "center", -- 文本居中
			layout_width = "fill", -- 宽度填满
			text = "测试文本", -- 默认文本
		},
		{
			Button, -- 按钮视图
			id = "btn", -- 控件ID
			layout_marginTop = "16dp", -- 上边距16dp
			layout_marginBottom = "16dp", -- 下边距16dp
			gravity = "center", -- 内容居中
			layout_width = "fill", -- 宽度填满
			text = "测试按钮", -- 按钮文本
		},
	}

	activity.setContentView(loadlayout(layout)) -- 加载并设置布局

	btn.onClick = function() -- 按钮点击事件
		tv.setText("我爱LuaHook") -- 修改文本内容
	end
end
```

## 3. 关键点说明
- `loadlayout`函数：将Lua表格式的布局转换为Android视图
- 事件绑定：通过控件`ID.onClick`方式绑定点击事件

**布局属性**
- `layout_width/layout_height`：可以是"fill"(填满)或"wrap"(包裹内容)
- `gravity`：控制内容对齐方式
- `orientation`：线性布局的排列方向
- 单位：Android中常用dp(density-independent pixels)作为尺寸单位

## 宿主和设置界面传参


**封装跳转页面方法**
```lua
local function startScriptActivity(context, scriptName,arg)
    import "android.content.ComponentName"
    import "android.content.Intent"
    local intent = Intent()
    intent.setComponent(ComponentName("com.kulipai.luahook",
    "com.kulipai.luahook.Activity.ScriptSetActivity"))
    intent.putExtra("arg",arg)
    local packageName = context.getPackageName()
    intent.putExtra("path", "/data/local/tmp/LuaHook/AppScript/"..packageName.."/"..scriptName..".lua")
    context.startActivity(intent)
end
```

**简单例子**

```lua
hookcotr(
	"com.tencent.mm.pluginsdk.ui.chat.ChatFooter",
	loader,
	"android.content.Context",
	"android.util.AttributeSet",
	"int",
	function(it) end,
	function(it)
		local button = getField(it.thisObject, "w")
		local context = invoke(button, "getContext")
		button.onLongClick = function()
			startScriptActivity(context, "当前脚本名称", "你好")
		end
end)

@set
function setActivity()
	import "com.kulipai.luahook.util.*"
	import "java.lang.*"
	import "android.widget.Toast"
	import "android.widget.*"

	function print(...)
		local text = table.concat({ ... }, " ")
		Toast.makeText(this, tostring(text), Toast.LENGTH_SHORT).show()
	end

	local argStr = this.getIntent().getExtras().getString("arg")
	local layout = {
		LinearLayout, -- 根布局为线性布局
		gravity = "center", -- 内容居中
		id = "filelayout", -- 布局ID
		orientation = 1, -- 垂直排列(1=垂直，0=水平)
		layout_width = "fill", -- 宽度填满
		layout_height = "fill", -- 高度填满
		{
			TextView, -- 文本视图
			id = "tv", -- 控件ID
			textIsSelectable = true, -- 文本可长按复制
			gravity = "center", -- 文本居中
			layout_width = "fill", -- 宽度填满
			text = "测试文本", -- 默认文本
		},
		{
			Button, -- 按钮视图
			id = "btn", -- 控件ID
			layout_marginTop = "16dp", -- 上边距16dp
			layout_marginBottom = "16dp", -- 下边距16dp
			gravity = "center", -- 内容居中
			layout_width = "fill", -- 宽度填满
			text = "测试按钮", -- 按钮文本
		},
	}

	activity.setContentView(loadlayout(layout)) -- 加载并设置布局

	btn.onClick = function() -- 按钮点击事件
		tv.setText(argStr) -- 修改文本内容
	end
end

```

