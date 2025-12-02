# Hook 使用说明文档

本模块提供了三种 Hook 接口形式：

- `hook`：用于 Hook 指定的方法
- `hookctor`：用于 Hook 构造函数（构造方法）
- `hookAll`：用于 Hook 某个类中所有同名方法（重载方法）

每种形式均支持 `before` 和 `after` 的钩子函数执行。

---

## 1. `hook` —— Hook 单个方法

### 用法一：通过类名、类加载器、方法名、参数类型列表 Hook 方法

```lua
hook("com.xx",
    lpparam.classLoader,
    "f1",
    "int", "String", "com.my.class",
    function(it)
        -- before
    end,
    function(it)
        -- after
    end
)
```

### 参数说明：

- `类名`：目标类的全限定名
- `类加载器`：用于加载类的 `ClassLoader`（如 `lpparam.classLoader`）
- `方法名`：要 Hook 的方法名
- `参数类型`：可变参数，可传类名字符串或已加载的类对象（推荐使用 `findClass`）
- `before/after`：前置与后置处理函数，接收一个参数 `it`（即 `MethodHookParam`）

### 混合使用类名与类对象：

支持将参数类型混合传入类名和类对象。例如：

```lua
hook("com.xx",
    lpparam.classLoader,
    "f1",
    findClass("com.yy", myLoader), "String",
    function(it)
        -- before
    end,
    function(it)
        -- after
    end
)
```

### 支持参数封装为 `LuaTable`：

```lua
local param = { "int", findClass("com.aaa", lpparam.classLoader) }

hook("com.xx",
    lpparam.classLoader,
    "f1",
    param, -- 参数以 LuaTable 形式传入
    function(it)
        -- before
    end,
    function(it)
        -- after
    end
)
```

---

### 用法二：直接 Hook 方法对象

适用于已通过 `DexKit` 或其他方式获取 `Method` 实例的场景：

```lua
hook(method,
    function(it)
        -- before
    end,
    function(it)
        -- after
    end
)
```

---

## 2. `hookctor` —— Hook 构造方法（Constructor）

用法与 `hook` 类似，但无需传入方法名，默认选中构造函数。

### 示例一：通过类名和加载器 Hook 构造方法

```lua
hookctor("com.xx",
    lpparam.classLoader,
    "int", "String", "com.my.class",
    function(it)
        -- before
    end,
    function(it)
        -- after
    end
)
```

### 示例二：直接传入类对象

```lua
local clazz = findClass("a", lpparam.classLoader)

hookctor(clazz,
    "int", "String", "com.my.class",
    function(it)
        -- before
    end,
    function(it)
        -- after
    end
)
```

支持将参数类型以类名字符串或类对象混合传入。

---

## 3. `hookAll` —— Hook 所有同名方法

用于 Hook 类中所有同名、参数不同的重载方法。

### 示例一：通过类名和加载器 Hook 所有方法重载

```lua
hookAll("com.xx",
    lpparam.classLoader,
    function(it)
        -- before
    end,
    function(it)
        -- after
    end
)
```

### 示例二：直接传入类对象

```lua
local clazz = findClass("com.xx", lpparam.classLoader)

hookAll(clazz,
    function(it)
        -- before
    end,
    function(it)
        -- after
    end
)
```

---

## `it` 参数说明（即 `MethodHookParam`）

> 可以简单的理解成函数的相关信息

每个 `before` 和 `after` 钩子函数都会接收到一个 `it` 参数（即 `MethodHookParam` 实例），代表当前 Hook 的上下文信息：

- `it.args`：方法参数数组

  - `it.args[0]`：获取第一个参数
  - `#it.args`：获取参数个数
  - `it.args[0] = 1`：修改参数（仅在 `before` 中有效）
- `it.result`：

  - `it.result`：获取返回值（在 `after` 中使用）
  - `it.result = true`：修改返回值

    - 在 `before` 中赋值将直接跳过原方法执行
    - 在 `after` 中赋值将覆盖原方法结果
- `it.thisObject`：当前方法所属对象实例（`this` 对象）

  - 可用于访问字段、方法等，常用于获取 `Activity`、`Context` 实例等


