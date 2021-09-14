<center>
    <h1> tofu </h1>
<svg width="192" height="192" xmlns="http://www.w3.org/2000/svg">
 <g>
  <g id="svg_1">
   <path id="svg_20" d="m27.49104,48.05657l0,96.14392l137.01793,0l0,-69.15164l-68.89457,0l0,-27.24934" opacity="0.5" fill-opacity="null" stroke-opacity="null" stroke-width="16" stroke="#000" fill="#fff"/>
  </g>
 </g>
</svg>
</center>



# lua-resty-tofu



tofu(豆腐) 应用 framework, 开箱即用，使得基于openresty开发应用时更加丝般顺滑



[TOC]



## 状态

alpha 阶段, 目前仅支持 linux/unix 环境





## 特性

* 基于openresty
* middleware方式流程处理
* 所有功能使用extend方式
* 内置常用工具包脚手架等,方便开发





## 开速开始

openresty 在提供脚手架方面非常有限，请确保环境已安装好

* [openresty](http://openresty.org/en/installation.html)
* [opm](http://openresty.org/en/installation.html) 
* [luarocks (可选)](https://luarocks.org/)



### 创建项目

> 使用项目工程模板 详细查看 [tofu-project-default](https://github.com/d80x86/tofu-project-default)

```sh
## 从github中clone
git clone --depth=1 https://github.com/d80x86/tofu-project-default.git new_name

## 进入项目
cd new_name

## 安装tofu framework
./tofu install

```



### 可选操作

```sh
## 移除无用的旧git信息
rm -rf .git

## 添加
echo '/lua_modules' >> .gitignore

## 重新添加git信息
git init
```



### 启动项目(开发)

```sh
./tofu console
```

如果可以看到类似这样的提示, 恭喜🎉

```sh
2021/08/18 19:56:49 [notice] 2482#2482: using the "epoll" event method
2021/08/18 19:56:49 [notice] 2482#2482: openresty/1.19.3.2
2021/08/18 19:56:49 [notice] 2482#2482: built by gcc 9.3.1 20200408 (Red Hat 9.3.1-2) (GCC) 
2021/08/18 19:56:49 [notice] 2482#2482: OS: Linux 3.10.0-957.21.3.el7.x86_64
2021/08/18 19:56:49 [notice] 2482#2482: getrlimit(RLIMIT_NOFILE): 100001:1000000
2021/08/18 19:56:49 [notice] 2482#2482: start worker processes
2021/08/18 19:56:49 [notice] 2482#2482: start worker process 2483
2021/08/18 19:56:49 [notice] 2482#2482: start worker process 2484
2021/08/18 19:56:49 [notice] 2482#2482: start privileged agent process 2485
2021-08-18 19:56:49 [notice] tofu version: 0.1.1
2021-08-18 19:56:49 [notice] environment: development
2021-08-18 19:56:49 [notice] listen: 9527
```



### 启动项目(生产)

```sh
./tofu start
```

> 默认使用 9527 端口
>
> 可在 conf/config.lua 配置中更改



### 停止服务

``` sh
./tofu stop
```

> 开发模式，直接使用control + c 终止



### 更多命令

```shell
./tofu help
```

执行后会看到下面的信息

```sh
usage:tofu COMMADN [OPTIONS]...

the available commands are:
console		start service (development)
help		help
install		install deps to current resty_module
new			create a new project in the directory
reload		reload nginx.conf
start		start service (production)
stop		stop service
version		show version information

```

> 如想查看某命令的使用方式
>
> ./tofu help console



### 依赖管理

许多时候我们都有比较好的第三方库或解决方案选择，我们直接下载使用即可，无需做过多的重复工作。tofu一些内置组件 view , session 等有第三方依赖，如我们需要使用，只需添加相关组件配置和安装依赖即可使用。安装依赖tofu也提供简单的管理方案,只需要:

1. #### 在 tofu.package.lua 文件中添加所需的依赖

```lua
-- 在配置文件 tofu.package.lua
-- 添加所需要的opm包或luarocks包
-- 也需要相关的 opm 或 luarocks 的使用环境, 安装方式请查阅资料

-- 依赖列表
-- 使用 -- string 或 {'方式:opm|luarocks', '<package name>'}
deps = {
		'bungle/lua-resty-template',	-- 默认使用 opm 方式
		'bungle/lua-resty-session',
		{'luarocks', 'lua-resty-jwt'} 	-- 指定 luarocks 方式
}
```

2. #### 然后执行

```sh
./tofu install
```

tofu 会根据 ```tofu.package.lua``` 文件中所配置 ```deps={...}``` 列表使用opm或luarocks进行安装所需要的依赖.

相关依赖安装在当前目录```lua_modules```中.（默认情况下tofu已将该目录添加到 lua_package_path 中了）

类信于下面的安装依赖包的过程信息

```text
install bungle/lua-resty-template
* Fetching bungle/lua-resty-template  
...
install bungle/lua-resty-session
* Fetching bungle/lua-resty-session  
* Fetching openresty/lua-resty-string  
...
install lua-resty-jwt
...
```





## 启动执行流程

1. 执行 ./tofu start 或 ./tofu console
2. 读取 conf/tofu.nginx.conf 配置文件
3. 根据配置初始化相关(生成最终的 nginx.conf 文件, 创建logs目录, 临时目录，缓存等目录)
4. 使用 openrsety 启动服务
5. 根据环境加载扩展配置文件 conf/extend.lua   conf/extend.<环境>.lua
6. 实例化和挂载 extend
7. 根据环境加载中间件配置文件 conf/middleware.lua  conf/middleware.<环境>.lua
8. 实例化和挂载 middleware
9. 服务启动完成



服务启动完成后会打印下面信息

``` text
2021-08-25 13:43:46 [notice] tofu version: 0.1.3.alpha
2021-08-25 13:43:46 [notice] environment: development
2021-08-25 13:43:46 [notice] listen: 9527

```





## 用户请求处理流程

1. openresty 接收到用户请求调用tofu处理
2. tofu 为该请求创建一个独立的 context, 然后调用中间件处理
3. 中间件 resty.tofu.middleware.trace 只是一个简单的记录访问时间和响应时间
4. 中间件 resty.tofu.middleware.router 路由和uri参数解析处理，处理结果存在 context 中
5. 中间件 resty.tofu.middleware.payload 参数解析处理， 结果存在 context 中
6. 中间件 resty.tofu.middleware.guard 从context 中获得参数然后调用相应方法处理, 结果中断流程还是继续 
7. 中间件 resty.tofu.middleware.controller 从context 中获得相应的controller 和 action 处理

> 注: 所有中间件(middleware) 都是可选的， 这里只列举出较常规的处理流程





## 基础功能



### 配置 / config

框架提供了各种可扩展的配置功能，可以自动合并，按顺序覆盖，且可以根据环境维护不同的配置。

配置文件放在 conf/ 目录下，并根据作用/功能划分到不同的配置文件

| 文件名          | 作用                                          | 可选 |
| --------------- | --------------------------------------------- | :--: |
| config.lua      | 通用的一些配置，以及tofu.nginx.conf的变量配置 |      |
| extend.lua      | 扩展组件配置，挂载那些扩展到tofu中使用        |      |
| middleware.lua  | 中间件配置, 挂载那些中间件到处理流程中        |      |
| tofu.nginx.conf | nginx 配置                                    |      |
| task.lua        | 定时任务配置                                  | 可选 |



#### 配置格式

后缀是lua的配置文件是一个可执行的lua文件, 返回文件中的全局变量

``` lua
-- 配置文件 config.lua 样例

ngx_port = 9527	-- 这是一个在 tofu.nginx.conf 中使用的变量, 配置nginx的server端口

```



配置文件约定使用一个 与 文件名相同的全局变量名

``` lua
-- 配置文件 extend.lua 样例

-- 约定一个lua 全局变量名称 extend 与配置文件名称相同, 仅仅是一种约定！
extend = {    
    --
    -- ...
    --
}
```



#### 多环境配置加载与合并规则

加载目标配置文件, 加载目标环境配置文件。后加载的会覆盖或合并前面的同名配置。

文件命名格式: `[name].[env].lua` , 如 `config.development.lua`, `config.production.lua`

```lua
-- 配置文件 config.lua
api = {
	appid = '123',
	secret = 'asdfghjkl',
}


-- 配置文件 config.production.lua
api = {
	secret = 'lkjhgfdsa',
	timeout = 5000,
}
```

配置加载目标配置文件 `config.lua`, 然后加载目标环境配置文件 `config.production.lua`, 后并后结果

``` lua
api = {
    appid = '123',
    secret = 'lkjhgfdsa',
    timeout = 5000,
}
```

> 更多使用方法查看扩展: `resty.tofu.extend.config`



#### 特殊配置文件

```tofu.nginx.conf``` 这是个特殊的配文件，是个标准的[nginx](http://nginx.org/)配置文件。 额外支持使用 ${var_name} 变量.

如果需要更复杂的处理，可以在 `config.lua` 中 设置 `ngx_conf_file_template = true` 开启` lua-resty-template` 语法持持 (需要 库 lua-resty-template ) 支持 



### 上下文 / context

`context` 是处理用户请求过程中的一个对象，贯穿整个请求生命周期。简称`ctx`。

与 `ngx.ctx` 功能类似`ngx.ctx`只是要给用户使用的, 而`ctx` 主要使用于框架内使用。

如主要用于在中间件中流转



### 中间件 / middleware

tofu 的中间件执行过程是基于洋葱圈模型

#### 中间件格式

``` lua
return function (options)
  
    return function (ctx, flow)
    	-- 干 ...
        flow()		-- 调用后面的中间件
        -- ...
    end
end
```

中间件格式为一个高阶阶函数，外部的函数接收一个 `options` 参数，这样方便中间件提供一些配置信息，用来开启/关闭一些功能。执行后返回另一个函数，这个函数接收 `ctx`, `flow` 参数，其中 `ctx` 为 `context` 的简写，是当前请求生命周期的一个对象，`flow` 是后续的中间件，这样可以很方便的处理后置逻辑。

中间件洋葱圈模型图:

![中间件葱图](https://camo.githubusercontent.com/d80cf3b511ef4898bcde9a464de491fa15a50d06/68747470733a2f2f7261772e6769746875622e636f6d2f66656e676d6b322f6b6f612d67756964652f6d61737465722f6f6e696f6e2e706e67)





#### 中间件配置和格式

中间件的配置文件在 `<应用根目录>/conf/middleware.lua`

```lua
-- 配置文件 conf/middleware.lua

middleware = {
    
    -- 中间件配置样例
    {
        enable	= true, -- default
        match	= [[/api]],
        handle = 'resty.touf.middleware.trace',
        options = {
            logger = tofu.log.n
        }
    },
    
    -- 快速配置方式
    'resty.tofu.middleware.router',
    
    -- ...
}
```



#### 通用参数:

| 参数    | 类型               | 说明                                                | 必填 | 缺省值 |
| ------- | ------------------ | --------------------------------------------------- | :--: | ------ |
| handle  | string \| function | 中间件, 可以是包名 或是中间件的高阶函数             |  是  |        |
| enable  | bool               | 控制中间件是否开启,主要用于控制中间件作用于某种环境 |  否  | true   |
| match   | string \| function | 设置只有符合某些规则的请求才会进入这个中间件处理    |  否  |        |
| options | any                | 中间件初始化时，传递给中间件函数                    |  否  |        |



#### handle

**string**: 

包名字符串，如 `resty.tofu.middleware.router` ，先查找应用middleware目录下，如果没有再按`require`方式加载。

``` lua
-- 配置文件 conf/middleware.lua

middleware = {

    -- 方式一
    {
        handle = 'resty.tofu.middleware.router',
    },
    
    -- 方式二
    'resty.tofu.middleware.router',
    
    -- 这两种配方式效果是相同的
}
```



**function**: 

中间件函数, 有些比较简单或临时的中间件，我们可以直接写在配置文件中

``` lua
-- 配置文件 conf/middleware.lua

middleware = {
    
    -- 中间件配置样例
    {
        handle = function (options)
            		return function (ctx, flow)
                		tofu.log.d('业务处理')
                		flow()
                	end
            	 end,
        options = { }
    },

}
```



#### enable

如果我们需要控制中间件在特定的环境中开启或关闭，可以设置`enable`参数为 true | false （默认 true）

``` lua
-- 配置文件 conf/middleware.lua

local _isdev  = 'development' == tofu.env

middleware = {
    
    -- 只在开发模式中开启该中间件
    {
        enable = _isdev,
        handle = 'resty.tofu.middleware.trace',
    },

}
```



#### match

**string**:

uri路径正则配置，使用的是`ngx.re.match`语法

``` lua
-- 配置文件 conf/middleware.lua

middleware = {
    
    -- uri 以 /static 前缀开头的请求才进入处理
    {
        match = [[/static]],
        handle = 'xxx_middleware',
    },

}
```



**function**:

函数返回 true | false 结果来判断匹配

``` lua
-- 配置文件 conf/middleware.lua

middleware = {
    
    {
        handle = 'xxx_middleware',
        
        -- 只有 ios 设备才进入处理
        match = function (ctx)
            		local user_agent = ngx.req.get_headers()['user-agent']
            		return ngx.re.match(user_agent, [[(iphone|ipad|ipod)]], 'joi')
            	end
    },

}
```



#### options

中间件初始化时，透传给中间件创建函数

``` lua
-- 配置文件 conf/middleware.lua

middleware = {
    
    {
        handle = function (options)
            		return function (ctx, flow)
                	end
            	 end,
        options = { }, -- 这个参数会原样传入给上面 handle 指定的中间件
    },
}
```



#### 内置中间件

> 框架默认内置了常用的中间件

| 中间件名称 | 中间件包名                       | 作用             |
| ---------- | -------------------------------- | ---------------- |
| trace      | resty.tofu.middleware.trace      | 跟踪记录请求     |
| router     | resty.tofu.middleware.router     | 路由解析         |
| payload    | resty.tofu.middleware.payload    | 请求参数解析     |
| guard      | resty.tofu.middleware.guard      | 参数过滤         |
| controller | resty.tofu.middleware.controller | 控制器，业务处理 |



#### 其它中间件

* [CORS](https://github.com/d80x86/tofu-middleware-cors) 跨域处理

* [JWT](https://github.com/d80x86/tofu-middleware-jwt) 验证处理 



#### 自定义中间件

根据业务需要添加中间件，按约定放在 `lua/middleware` 目录下，然后就可以中间件配置中直接使用

创建自定义中间件, 添加文件 `lua/middleware/example.lua`

``` lua
-- 文件lua/middleware/example.lua

return function (options)
    return function (ctx, flow)
        tofu.log.d('你静鸡鸡地来了')
        flow()
        tofu.log.d('你静鸡鸡地走了')
    end
end
```

然后在中间件配置文件 `conf/middleware.lua` 中添加配置

``` lua
-- 配置文件 conf/middleware.lua

middleware = {
    
    -- 方式一
    {
        handle = 'example',
        options = { }
    },
    
    -- 方式二
    'middleware.example',
}
```

直接写在配置文件中

``` lua
-- 配置文件 conf/middleware.lua

middleware = {
    
    -- 自定义中间件
    {
        handle = function (options)
            		return function (ctx, flow)
                		tofu.log.d('业务处理')
                		flow()
                	end
            	 end,
        options = { }
    },
    
    -- ...
}
```



### 扩展 / extend

tofu框架可以说是一个 **零** 功能的框架，所有功能都是通过扩展得来实现。所以扩展都可以通过配置来控制。

因为openresty已提供了相关基础的很友好和方便调用的api，所以tofu没有必要再封装一套基础的api。

这也极大减少不必要的api和学习的成本。



#### 扩展配置和格式

扩展的配置文件在 `<应用根目录>/conf/extend.lua`

```lua
-- 配置文件 conf/extend.lua

extend = {
    
    -- 扩展配置样例
    {
        enable	= true, -- default
        named	= 'config',
        type	= 'default',
        default	= {
        	handle = 'resty.touf.extend.config',
        	options = {
            	env = tofu.env,
                prefix = tofu.ROOT_PATH .. 'conf/',
        	}
        }
    },
    
    -- 快速配置方式一
    'resty.tofu.extend.builtin',
    
    -- 快速配置方式二, 等同上面方式
    {
        default = {
            handle = 'resty.tofu.extend.builtin', -- 还可以是 function | table 
        }
    },
    
    -- ...
}
```



#### 通用参数:

| 参数   | 类型   | 说明                                                  | 必填 | 缺省值  |
| ------ | ------ | ----------------------------------------------------- | :--: | :-----: |
| enable | bool   | 控制中间件是否开启,主要用于控制扩展组件作用于某种环境 |  否  |  true   |
| named  | string | 为设置扩展命名后可用 tofu.<named> 全局调用            |  否  |         |
| type   | string | 中间件初始化时，指定使用那一组参数初始化`扩展组件`    |  否  | default |



#### enable

如果我们需要控制扩展组件在特定的环境中开启或关闭，可以设置`enable`参数为 true | false （默认 true）

``` lua
-- 配置文件 conf/extend.lua

-- 是否开发环境
local _isdev  = 'development' == tofu.env

extend = {
    
    -- 只在开发模式中开启该扩展组件
    {
        named	= 'watcher',
        enable	= _isdev,
        default = {
            trace 	= true,
            handle	= 'resty.tofu.extend.jili'
        },
    },
}
```



#### named

挂载到`tofu`的名称,使得后面可以使用 `tofu.<named>` 方式调用。命名不能为空字符串，命名不能重复。

当为 `nil` 时，扩展组件又是` table`，则将扩展中的所有非下划`_`开头的属性加载到tofu



#### type

指定扩展组件使用那一组参数

``` lua
-- 配置文件 conf/extend.lua


-- 是否开发环境
local _isdev  = 'development' == tofu.env

extend = {
    
    -- 只在开发模式中开启该中间件
    {
        named	= 'log',
        -- 根据环境指定不同类型的中间件,分别对应下面的配置
        type	= _isdev and 'console' or 'file',
        
        -- 把日志打印到终端
        console = {
            -- ...
        },
        
        -- 把日志打印到文件
        file = {
            -- ...
        },
    },
}
```



**扩展组件参数格式**

```lua
-- 配置文件 conf/extend.lua

extend = {
    
    {
        named	= 'view',
        
        -- 扩展组件参数格式
    	default = {
            handle = 'resty.tofu.extend.view',
            options = {
                -- ...
            }
        }
        
    },
}
```



**type指定的扩展组件**

| 参数    | 类型                    | 说明               | 必填 | 缺省 |
| ------- | ----------------------- | ------------------ | :--: | :--: |
| handle  | string\|function\|table | 扩展组件主体内容   |  是  |      |
| options | any                     | 透传给扩展组件函数 |  否  |      |



#### handle

**string**: 

包名字符串，如 `resty.tofu.extend.task` ，先查找应用extend目录下，如果没有再按`require`方式加载。

``` lua
-- 配置文件 conf/extend.lua

extend = {
    
    -- 快速配置方式一
    'resty.tofu.extend.builtin',
    
    -- 快速配置方式二, 等同上面方式
    {
        default = {
            handle = 'resty.tofu.extend.builtin',
        }
    },
}
```

**function**: 

函数, 有些比较简单或临时的扩展组件，我们可以直接写在配置文件中

``` lua
-- 配置文件 conf/extend.lua

extend = {
    
    {
        named	= 'bye'
        handle = function (options)
            		return function (who)
                		tofu.log.d(who, ': 散水,系噉先喇!')
                	end
            	 end,
        options = { }
    },
}

-- 在其它地方调用 tofu.bye('肥标')
```

**table**:

将`handle`所有非下划线`_`开头的属性或方法合并（浅copy）到`tofu`中

``` lua
-- 配置文件 conf/extend.lua

extend = {
    -- 情况1: 没有命名
    {
        -- named = nil
        handle = {
            bye = function (who)
                	tofu.log.d(who, ': 散水,系噉先喇!')
                   end,
       }
    },
    -- 在其它地方调用 tofu.bye('肥标')
    
    
    -- 情况2: 指定命名
    {
        named = 'foo',
        handle = {
            -- 如果存在 new 方法则调用
            new = function(options)
                	return {
                    	bye = function (who)
                		tofu.log.d(who, ': 散水,系噉先喇!')
                   end,
                	}
            	  end
       }
    },
    -- 在其它地方调用 tofu.foo.bye('肥标')
}


```







## 内置中间件





### 访问请求追踪中间件 / trace

> resty.tofu.middleware.trace

一个简单记录请求的进入中间件时间, 退出中间件时间，请求的uri 和 方法，状态，并使用指定的方法记录/打印

#### 配置 options

| 参数   | 类型     | 说明           | 必须 |     缺省      |
| ------ | -------- | -------------- | :--: | :-----------: |
| logger | function | 记录日志的方法 |  否  | ngx.log(INFO) |
|        |          |                |      |               |



#### 使用配置

``` lua
-- 配置文件 conf/middleware.lua

middleware = {
    {
        handle = 'resty.touf.middleware.trace',
        options = {
            logger = tofu.log.n
        }
    },
}
```







### 路由中间件 / router

> resty.tofu.middleware.router

uri路由解析，uri参数解析, 解析结果存放在 context 中

#### 配置 options

| 参数       | 类型   | 说明                   | 必须 |  缺省   |
| ---------- | ------ | ---------------------- | :--: | :-----: |
| module     | string | 缺省的`module`名称     |  是  | default |
| controller | string | 缺省的`controller`名称 |  是  |  index  |
| action     | string | 缺省的`action`名称     |  是  |  index  |



#### 使用配置

``` lua
-- 配置文件 conf/middleware.lua

middleware = {
    {
        handle = 'resty.touf.middleware.router',
        options = {
            module		= 'default',
            controller	= 'index',
            action		= 'index'
        }
    },
}
```



#### 路由解析规则

通过解析 ngx.var.uri 为 `[/module]` `[/.../path/../]` `[/controller]` `[/action]` `[/arg1/arg2.../...]`

[] 中的内容为可选, 如果module, controller, action 各项为空时，则使用配置

1. 使用 `/` 分割 uri
2. 从左向右查找和检验`module`, 如果没有则使用 `options.module` 配置值
3. 在`module`之后，从左向右查找和检验`controller`, 如果没有则使用 `options.controller` 配置值
4. 在`controller`之后，从左向右查找和检验`action`, 如果没有则使用 `options.action` 配置值
5. 在 `action`之后，从左向右的所有内容解析为 args 数组参数

#### 解析结果合并到中间件 context

| 参数       | 类型   | 说明                                           | 样例             |
| ---------- | ------ | ---------------------------------------------- | ---------------- |
| handler    | string | 处理品的文件,相对于应用内的 controller/ 目录下 | default/index    |
| module     | string | 模块名称                                       | default          |
| controller | string | 控制器名称                                     | index            |
| action     | string | 方法名称                                       | index            |
| args       | table  | 参数表,数组                                    | {'arg1', 'arg2'} |





### 参数解析中间件 / payload

> resty.tofu.middleware.payload

解析处理 body 与 uri 参数，get参数合并到 context.args.get, 其它方式合并到 context.args.post, 文件合并到 context.args.file。



#### 配置 options

| 参数   | 类型  | 说明         | 必须 | 缺省 |
| ------ | ----- | ------------ | :--: | :--: |
| parser | table | 协议解析器表 |  否  |      |

> 默认支持
>
> application/x-www-form-urlencoded
>
> application/json
>
> multipart/form-data



#### 使用配置

``` lua
-- 配置文件 conf/middleware.lua

middleware = {
	'resty.tofu.middleware.payload',
}
```



#### 解析器格式

``` lua
function()
    return { post={},  get={}, file={} }
end
```

> 结果会合并到中间件 context.args 中



#### 添加或修改解析器

``` lua
-- 配置文件 conf/middleware.lua

middleware = {
	{
        handle	= 'resty.tofu.middleware.payload',
        options	= {
            
            -- 添加一个 xml 解析器
            ['application/xml'] = function()
                -- 按约定存放到 post | get | file 中
                return { post = {} }
            end,
            
            
            -- 重写(覆盖) multipart/form-data 解析器
            ['multipart/form-data'] = function()
                return { post={}, file={} }
            end,
            
            -- ...
        },
    }
}
```

> 建议，把解析器写成独文件，通过require引入，这样使得配置文件不至于冗长





### 参数过滤中间件 / guard

> resty.tofu.middleware.guard
>
> 依赖: resty.tofu.middleware.router

参数过滤校检是一个不可少的环节，将参数统一处理，当参数校验完成后，再进行后续的流程。这样可以减少action 复杂且冗长和重复的代码，使得action更加注重业务方面



#### 配置 options

| 参数       | 类型   | 说明                       | 必须 | 缺省  |
| ---------- | ------ | -------------------------- | :--: | :---: |
| guard_root | string | guard 起始查找目录         |  是  | guard |
| suffix     | string | 方法后缀，如 action_fuffix |  是  |       |



#### 使用配置

``` lua
-- 配置文件 conf/middleware.lua

middleware = {
	'resty.tofu.middleware.guard',
}
```

> 使用默认配置基本可以满足需要



#### 添加参数检验过滤器

当请求 `module/controller/action`, 中间件会在 guard 目录下查找 `module/controller/action` 。

* 没有命中的guard，直接通过，执行后面的中间件流程

* 命中guard中定义了_enter(魔术方法)，会优先执行，并判断结果是否为非 false，否则中断流程
* 执行命中guard中定义的action方法，并判断结果是否为非 false







### 控制器中间件 / controller

> resty.tofu.middleware.controller
>
> 依赖: resty.tofu.middleware.router

控制器是处理用户请求业务的主要场所，使得不同的业务对相应的`controller.action`简单明了。

controller中间件根据路由中间件resty.tofu.middleware.router的处理结果，在 options.controller_root 配置的目录下开始查找，匹配对应用controller



#### 配置 options

| 参数                        | 类型     | 说明                          | 必须 |    缺省     |
| --------------------------- | -------- | ----------------------------- | :--: | :---------: |
| suffix                      | string   | 方法action的后缀              |  否  |     ''      |
| logger                      | function | 方法后缀，如 action_fuffix    |  否  | tofu.log.e  |
| controller_root             | string   | 控制器查找的根目录            |  否  | controller/ |
| controller_allow_underscore | bool     | 是否支持下划线`_`开头的控制器 |  否  |    false    |
| action_allow_underscore     | bool     | 是否支持下划线`_`开头的方法   |  否  |    false    |



#### 使用配置

``` lua
-- 配置文件 conf/middleware.lua

middleware = {
	'resty.tofu.middleware.controller',
}
```



#### 如何编写 controller

默认情况下controller中间件会从<应用>/lua/controller/ 目录按 module/path/controller.lua 规则查找文件。

我们可以使用 lua module 的方式/风格（推荐）来编写

``` lua
-- 
-- 文件 <应用>/lua/controller/api/user.lua
--

local _M = {}

-- 缺省方法 index
function _M.index()
    tofu.success()
end


-- 定义方法 info
-- 访问 /api/user/info 该方法将被调用
-- 请求参数
--		id ： 用户id
-- 
function _M.info()
    -- 业务样例代码
    -- --------------------------
    -- 获取参数
    local id = tofu.args('id')
    
    -- 从数据库中查询用户信息
    local info = tofu.model('user').get({id = id})
    
    -- 以json方式反回结果 {errno:0, errmsg:'', data:{id:, name:, ...}}
    tofu.success(info)
end

return _M
```



使用controller基类是一个很好的方案

``` lua
-- 按习惯，私有的把它命名为 _base.lua
-- 
local _M = {}
-- ... 方法 ...
return _M
```



``` lua
-- 这个controller 将"继承"上面的 _base

local _M = tofu.extends('_base') -- tofu.extends 提供相对于当前文件目录的查找方式
	-- .. 继承 _base 的方法..
return _M
```



#### 魔术方法

* `_enter()`  当进入`controller` 时自动调用
* `_leave()`  当退出`controller` 时自动调用



#### 中断流程

当` controller` 的方法明确 `return false` 时，会中断后面的中间件





## 内置扩展组件 / extend





### 配置扩展组件 / config

> resty.tofu.extend.config

使用lua语法作为配置文件，一体化，无需额外学习。借助lua的解析能力，代码即配置，轻松提供强大且可扩展的配置方案。按顺序覆盖，根据环境使用不同配置。



#### 配置 options

| 参数    | 类型   | 说明             | 必须 |   缺省   |
| ------- | ------ | ---------------- | :--: | :------: |
| env     | string | 当前环境         |  否  | 当前环境 |
| prefix  | string | 配置查找目录     |  否  |  conf/   |
| default | string | 默认配置文件名称 |  否  |  config  |



#### 使用配置

``` lua
-- 配置文件 conf/extend.lua

extend = {
	{
        named	= 'config',
        default	= {
            handle	= 'resty.tofu.extend.config',
            options	= {
                env		= tofu.env,
                prefix	= tofu.ROOT_PATH .. 'conf/'
            }
        }
    }
}
```



#### 添加自定义配置

配置文件在`options.prefix`（默认 <应用>/conf/）目录下添加, 如有 `jwt` 配置

``` lua
-- jwt.lua

jwt = {
    secret	= '5df7f1701b778d03d57456afea567922',
    passthrough = true,
}
```



#### 使用

``` lua
local jwt = tofu.config.jwt
tofu.log.d( jwt.secret )
```

>  `tofu.config.jwt` 按顺序合并和覆盖 config.lua <-- config.环境.lua <-- jwt.lua <-- jwt.环境.lua



#### 合并和覆盖

``` lua
-- 配置文件 config.lua
jwt = {
    secret = '5df7f1701b778d03d57456afea567922'
}

-- 配置文件 jwt.lua
jwt = {
    secret = 'abc123'
}

-- 配置文件 jwt.production.lua
jwt = {
    passthrough = true
}

-------------------------------------------
-- jwt配置的结果
--
jwt = {
 	secret = 'abc123',
    passthrough =
}

```





### 日志扩展组件 / log

> resty.tofu.extend.log

提供了 debug, info, notice, warn, error,等多个级别日志，输出方式提供了终端和文件方式



#### 配置 options

| 参数    | 类型     | 说明                                          | 必须 | 缺省  |
| ------- | -------- | --------------------------------------------- | :--: | :---: |
| level   | int      | 记录日志级别,低于设置级别会被忽略             |  否  | DEBUG |
| color   | bool     | 是否使用颜色,一般在终端环境时使用             |  否  | false |
| colors  | table    | 配色表                                        |  否  |       |
| printer | function | 记录器                                        |  否  |       |
| fmter   | string   | 日志格式化模板                                |  否  |       |
| pretty  | bool     | 是否格式化输出                                |  否  | false |
| trace   | bool     | 是否显示更详细信息(文件名，行号等)            |  否  | false |
| file    | string   | file日志记录器配置                            |  否  |       |
| rotate  | string   | file日志记录器配置, 切割间隔。目前只支持'day' |  否  |       |



#### 使用配置

``` lua
-- 配置文件 conf/extend.lua

local _log    = require 'resty.tofu.extend.log'
local _isdev  = 'development' == tofu.env

extend = {
	{
        named	= 'log',
        type	= _isdev and 'console' or 'file'
        
        -- 终端日志
        console	= {
            handle	= _log.console,
            options	= {
                level	= _log.levels.DEBUG,
                color	= true,
                pretty	= true,
            }
        },
        
        -- 文件日志
        file = {
            handle	= _log.file,
            options	= {
                level	= _log.levels.INFO,
                file	= 'logos/tofu.log',
                rotate	= 'day',
            }
        }
    }
}
```



#### Lua API

**tofu.log.d**(...)

debug 级别日志



**tofu.log.i**(...)

info级别日志



**tofu.log.n**(...)

notice级别日志



**tofu.log.w**(...)

warn级别日志



**tofu.log.e**(...)

error级别日志



``` lua
tofu.log.d('----- debug -----')
tofu.log.i('----- info -----')
tofu.log.n('----- notice -----')
tofu.log.w('----- warn -----')
tofu.log.e('----- error -----')
```





### session 扩展组件 /session

> resty.tofu.extend.session
>
> 依赖: [lua-resty-session](https://github.com/bungle/lua-resty-session)

#### 配置 options

| 参数    | 类型   | 说明                                                | 必须 |     缺省     |
| ------- | ------ | --------------------------------------------------- | :--: | :----------: |
| name    | string | session名称设置                                     |  否  | tofu_session |
| ttl     | int    | session有效时长(秒)                                 |  否  |     1200     |
| renewal | bool   | 是否自动续约ttl                                     |  否  |     true     |
| secret  | string | session安全码                                       |  否  |              |
| storage | string | session的存储方式,默认支持 cookie \| shm 等多种方式 |  否  |              |



#### 使用配置

``` lua
-- 配置文件 conf/extend.lua

extend = {
	{
        named	= 'session',
        default	= {
            handle	= 'resty.tofu.extend.session',
            options = {
                ttl	= 20 * 60, -- 过期时间(秒)
                
                -- 与 tofu.nginx.conf 中的 set $session_secret 相同
                secret = '5df7f1701b778d03d57456afea567922',
                
                -- -- cookie 方式
                -- storage	= 'cookie'
                -- cookie	= {}
                
                -- -- shm 方式
                storage = 'shm',
                shm = {
                    -- 匹配 tofu.nginx.conf 中的 lua_shared_dict
                    store = 'tofu_sessions'
                }
            }
        }
    }
    
}
```



``` nginx
##　 conf/tofu.nginx.conf

http {
    ## ...
    ## 上 conf/extend.lua 中 session 配置的shm store 名称相配
    lua_shared_dict tofu_sessions 10m;  
    
    ## ...
}
```



#### Lua API

**tofu.session.get(key)**

获取当前session的key的值

``` lua
local info = tofu.session.get('info')
```



**tofu.session.set(key, value)**

设置当前session的key的值 , 并返回旧的值

``` lua
tofu.session.set('info', {id=1, name='d'})
```



**tofu.session.destroy()**

删除当前session的所有值

``` lua
tofu.session.destroy()
```





### cache 扩展组件 / cache

> resty.tofu.extend.cache

使用ngx.shared.DICT作为缓存，不支持table, userdata类型



#### 配置 options

| 参数 | 类型   | 说明                | 必须 |      缺省       |
| ---- | ------ | ------------------- | :--: | :-------------: |
| ttl  | int    | 缓存时间(秒)        |  是  |      5400       |
| shm  | string | lua_shared_dice名称 |  是  | tofu_cache_dict |



#### 使用配置

``` lua
-- conf/extend.lua

extend = {
    {
        named = 'cache',
        default = {
            handle = 'resty.tofu.extend.cache',
            options = {
                ttl = 90 * 60,	-- 90 分钟
                shm = 'tofu_cache_dict',	--  lua_shared_dict 配置的名称
            }
        }
    }
}
```



#### Lua API

**tofu.cache.get(key [, init] [, ...])**

获得缓存,如果不存在则返回 init, 如果init 是 function,则执行 init(...), 只有值为非nil才会缓存。

初始化时会使用 resty.lock, 所以不会有缓存失效风暴



**tofu.cache.set(key, val [, ttl])**

设置缓存, val 不支持 table



**tofu.cache.del(key)**

删除缓存



**tofu.cache.incr(key, val [, init] [, ttl])**

累加器



### 视图扩展组件 / view

> resty.tofu.extend.view
>
> 依赖: [ lua-resty-template ]([bungle/lua-resty-template: Templating Engine (HTML) for Lua and OpenResty. (github.com)](https://github.com/bungle/lua-resty-template))

通过开启视图扩展组件，让应用有服务端渲染模板的能力。



#### 配置 options

| 参数          | 类型   | 说明         | 必须 | 缺省  |
| ------------- | ------ | ------------ | :--: | :---: |
| template_root | string | 模板搜索路径 |  否  | view/ |
| extname       | string | 模板后缀名称 |  否  | .html |
| cache         | bool   | 是否缓存     |  否  | false |



#### 使用配置

``` lua 
-- conf/extend.lua

extend = {
    {
        named = 'view',
        default = {
            handle 	= 'resty.tofu.extend.view',
            options	= {
                template_root = tofu.ROOT_PATH .. 'view/',
                extname = '.html',
                cache = true,
            }
        }
    }
}
```



#### Lua API

**tofu.view.assign(param [, val])**

关联变量到模板中使用

``` lua
-- 方式一
tofu.view.assign('name', '神探肥标')
tofu.view.assign('id', 123)

-- 方式二， 与上面等效
tofu.view.assign({
        name = '神探肥标',
        id = 123
    })
```



**tofu.view.render(tpl, param)**

渲染模板



**tofu.view.display(tpl, param)**

param 合并 assign所关联变量，并渲染模板到body

``` lua
-- 方式一
tofu.view.assign('name', '神探肥标')
tofu.view.assign('id', 123)
tofu.view.display()

-- 方式二, 可以使用链式风格
tofu.view
.assign('name', '神探肥标')
.assign('id', 123)
.assign({
        pic = '9527'
    })
.display()

```





### mysql 访问扩展组件 / model

> resty.tofu.extend.model

mysql 是一个较常见也很好用的关系弄数据，在开发中使用SQL操作数据库(CRUD: 增删改查)，还是比较麻烦，也容易造成 SQL 注入等安全问题。model 扩展组件提供了快速执行sql，和模型功能。



#### 配置 options

| 参数    | 类型                        | 说明                           | 必须 | 缺省 |
| ------- | --------------------------- | ------------------------------ | :--: | :--: |
| default | string \| table \| function | 指定缺省时的数据库options 配置 |  是  |      |

**数据库配置 options**

| 参数             | 类型   | 说明                       | 必须 |   缺省    |
| ---------------- | ------ | -------------------------- | :--: | :-------: |
| host             | string | 数据库地址(tcp/ip)         |  否  | 127.0.0.1 |
| port             | int    | 数据库端口                 |  否  |   3306    |
| path             | string | 数据库地址(unix socket)    |  否  |           |
| database         | string | 数据库名称                 |  否  |           |
| prefix           | string | 数据表前缀                 |  否  |    ''     |
| user             | string | 数据库用户                 |  否  |   root    |
| password         | string | 数据库密码                 |  否  |    ''     |
| charset          | string | 连接编码                   |  否  |   utf8    |
| timeout          | int    | 连接超时(毫秒)             |  否  |   5000    |
| max_package_size | int    | 最大结果集大小             |  否  |    2M     |
| pool_size        | int    | 连接池大小(每nginx worker) |  否  |    64     |
| logconnect       | bool   | 是否log连接                |  否  |   false   |
| logsql           | bool   | 是否log sql 语记           |  否  |   false   |



#### 使用配置

``` lua 
-- conf/extend.lua

local _isdev  = 'development' == tofu.env

extend = {
    {
        named = 'model',
        default = {
            handle 	= 'resty.tofu.extend.model',
            options	= {
            	host = '127.0.0.1',
            	user = 'root',
                password = '',
                database = 'test',
                
                logconnect = _isdev,
                logsql = _iddev,
            }
        }
    }
}
```



**多数据库配置**

``` lua
-- conf/extend.lua

local _isdev  = 'development' == tofu.env

extend = {
    {
        named = 'model',
        default = {
            handle 	= 'resty.tofu.extend.model',
            default = 'db1', -- 指定默认使用的数据配置
            -- 名为db1的数据库配置
            db1	= {
            	host = '192.168.0.1',
            	user = 'root',
                password = '',
                database = 'test',
                logconnect = _isdev,
                logsql = _iddev,
            },
            
            -- 名为db2的数据库配置
            db2	= {
            	host = '192.168.0.2',
            	user = 'root',
                password = '',
                database = 'test'，
                logconnect = _isdev,
                logsql = _iddev,
            },
            
            -- dbN
            -- ...
        }
    }
}
```



**运行时动态获取，如读写分离**

``` lua
-- conf/extend.lua

local _match = string.match
local _lower = string.lower

extend = {
    {
        named = 'model',
        default = {
            handle 	= 'resty.tofu.extend.model',
            
            -- 样例:根据sql，使用选择数据库配置
            default = function (sql)
                local op = _match(sql, '^%s-(%a+)')
                op = _lower(op)
                
                -- 只读数据库
                if 'select' == op then
                    return {
                        host = '192.168.0.1',
                        user = 'root',
                        password = '',
                        database = 'test',
                        logconnect = _isdev,
                        logsql = _iddev,
                    }
                 
                 -- 读写数据库
                 else
                    return {
                        host = '192.168.0.2',
                        user = 'root',
                        password = '',
                        database = 'test'，
                        logconnect = _isdev,
                        logsql = _iddev,
               		}
                end
        }
    }
}
```



#### Lua API

**tofu.model(name [ , opts])**

创建一个 model , 对于单表操作， 这是个利器，可以很方便地完成较复杂的操作。也可以直接执行sql语句。

`name` string 通常是表名, 先尝试加载`<应用>/lua/model/<name>.lua`,然后创建一个model。

`opts` string | table | function 可选参，数据库配置

``` lua
-- 创建一个model

-- 使用默认配置
local user = tofu.model('user')

-- 使用配置(遵循覆盖原则)
local user = tofu.model('user', { host='127.0.0.1' })

-- 使用名为 db2 的配置
local user = tofu.model('user', 'db2')

-- 使用一个函数的结果作为配置
-- function(sql) -> table
local user = tofu.model('user', function(sql) return { host='127.0.0.1' } end )

```



**model.exec(sql [, opts])**

使用 model 执行sql, 提供灵活的占位符操作

`sql`  string | table 

* **string 合法的sql语记**

  ``` lua
  local sql = 'select * from user limit 10'
  local result = tofu.model().exec(sql)
  ```

* **table {sql, param}**

  **{string, ...}, 占位符 ?**，安全占位符会根据参数类型，进行转换

  ``` lua
  local sql = 'select * from user where id=? and name=?'
  tofu.model().exec({sql, 123, '神探肥标'})
  
  -- 执行的sql: select * from user where id=123 and name='神探肥标'
  ```

  

  **{string, ...}, 占位符 ??**，==不安全占位符，不进行安全转换==

  ``` lua
  local sql = 'select ?? from user where id=?'
  tofu.model().exec({sql, 'name', 123})
  
  -- 执行的sql: select name from user where id=123
  ```

  

  **{string, {...}}, 有名占位符 :name**，安全占位符会根据参数类型，进行转换

  ``` lua
  local sql = 'select * from user where id=:id and name=:name'
  tofu.model().exec({sql, { id=123, name='神探肥标'})
  
  -- 执行的sql: select * from user where id=123 and name='神探肥标'
  ```

  

  **{string, ...}, 有名占位符 ::name**，==不安全占位符，不进行安全转换==

  ``` lua
  local sql = 'select ::field from user where id=:id'
  tofu.model().exec({sql, { field='id, name', id=123})
  
  -- 执行的sql: select id, name from user where id=123
  ```

`opts` table 可选参，数据库配置



**model.get(cond, opts)**

获取数据，默认只获取一条记录

`cond`  string | table 

sql 语句  where 后面的内容，支持 `?` | `??` | `:name` | `::name` 占位符格式。 可参考上面model.exec的样例

* string

  ``` lua
  
  local result = tofu.model('employees').get('emp_id=123')
  -- 执行的sql: select * from employees where emp_id=123
  ```

* table

  ``` lua
  -- 占位符 ?
  local result = tofu.model('employees').get({'emp_id=?', '123'})
  -- 执行的sql: select * from employees where emp_id='123'
  
  
  -- 占位符 ??
  local result = tofu.model('employees').get({'emp_id=??', '123'})
  -- 执行的sql: select * from employees where emp_id=123
  
  -- 有名占位符 :name 与 :name 同理
  ```

  

改变关系逻辑符, 逻辑符使用 cond[1] 控制, ==不作安全转换==，也就是任何内容都会原样插入

``` lua
-- 默认情况以 and 连接多个条件
tofu.model('employees').get({emp_id=123, name='神探肥标'})
-- 执行的sql: select * from employees where emp_id=123 and name='神探肥标'

-- 使用 or 连接
tofu.model('employees').get({'or', emp_id=123, name='神探肥标'})
-- 执行的sql: select * from employees where emp_id=123 or name='神探肥标'
```

当值为table即 key = { op,  val, ...}, `op`为操作符, ==不作安全转换==, `>` | `<` | `=` | `between` | `in` | `not in`等等合法的sql语法都支持。

下面只列举出model中特有的操作符

| 操作符 | 说明         |           关系            |
| ------ | ------------ | :-----------------------: |
| []     | 闭区间       | [a,b] = {x \| a ≤ x ≤ b}  |
| ()     | 开区间       | (a,b) = {x \| a < x < b}  |
| [)     | 半开半闭区间 | [a,b) = {x \|  a ≤ x < b} |
| (]     | 半开半闭区间 | (a,b] = {x \| a < x ≤ b}  |

样例

``` lua
-- 为减少内容影响，下面model.get调用 opts 参数:
local opts = { limit = false }

-- select * from employees where emp_id < 123
tofu.model('employees').get( {emp_id = {'<', 123} }, opts )

-- select * from employees where emp_id <= 123
tofu.model('employees').get( {emp_id = {'<=', 123} }, opts )

-- select * from employees where emp_id > 123 
tofu.model('employees').get( {emp_id = {'>', 123} }, opts )

-- select * from employees where emp_id >= 123 
tofu.model('employees').get( {emp_id = {'>=', 123} }, opts )

-- select * from employees where emp_id is null
tofu.model('employees').get( {emp_id = {'is null'} }, opts )

-- select * from employees where emp_id is not null
tofu.model('employees').get( {emp_id = {'is not null'} }, opts )

-- select * from `employees` where `emp_id` between 1 and 20 
tofu.model('employees').get( {emp_id = {'between', 1, 20 } }, opts )

-- select * from `employees` where `emp_id` in (1,20)
tofu.model('employees').get( {emp_id = {'in', 1, 20 } }, opts )

-- select * from `employees` where `emp_id` not in (1,20) 
tofu.model('employees').get( {emp_id = {'not in', 1, 20 } }, opts )

-- 
-- 区间操作符
-- 
-- select * from `employees` where 1 <= `emp_id` and `emp_id` <= 20
tofu.model('employees').get( {emp_id = {'[]', 1, 20 } }, opts )

-- select * from `employees` where 1 < `emp_id` and `emp_id` < 20
tofu.model('employees').get( {emp_id = {'()', 1, 20 } }, opts )

-- select * from `employees` where 1 <= `emp_id` and `emp_id` < 20
tofu.model('employees').get( {emp_id = {'[)', 1, 20 } }, opts )

-- select * from `employees` where 1 < `emp_id` and `emp_id` <= 20
tofu.model('employees').get( {emp_id = {'(]', 1, 20 } }, opts )
```



`opts` table 可选项

| 参数      | 类型                     | 说明                              | 缺省  |
| --------- | ------------------------ | --------------------------------- | :---: |
| filed     | string \| table          | 对应sql中的字段                   |   *   |
| limit     | number \| table \| false | 对应sql中的limit, false:关闭limit |   1   |
| orderby   | string                   | 对应sql中的 order by              |       |
| forupdate | bool                     | 对应sql中的 for update            | false |



model.set(cond, pair, add)

更新/添加数据

 `cond`  string | table

 参考上面model.get的样例。

`pair` table

需要更新或添加数据对, kv 结构，k为字段名称要求合乎sql规则，v可以tostring类型, 如果v是table 且table[1] 是 string,会按其值原样处理，==不作安全转换==

`add` bool | table

添加模式：将 cond 与 add  合并，进行添加操作, 如果存在则使用 pair 进行更新。所以要求 cond 与 add 的key与value 必须是合乎sql要的

return 

* 更新模式: 受影响数量

* 添加模式:  受影响数量, N 添加的id号, 0:更新。(mysql 的 @@innodb_autoinc_lock_mode 设置会影响结果)

* 错误: nil, error

样例

``` lua
--
-- 更新模式
--
-- sql: update `employees` set `emp_name`='神探肥标'  where emp_id = 1
tofu.model('employees').set({emp_id = 1}, {emp_name='神探肥标'})

-- sql: update `employees` set `salary`=salary+1  where emp_id = 1
tofu.model('employees').set({emp_id = 1}, {salary={'salary+1'} })

--
-- 添加模式, 先进行添加，如果存在则更新
--
-- sql: insert into `employees` (`emp_id`,`emp_name`) values (1,'蛋散')
--		on duplicate key update emp_name='神探肥标' 
tofu.model('employees').set({emp_id = 1}, {emp_name='神探肥标'}, {emp_name='蛋散'})
```



model.add(pair [, ...])

添加一条或多条数据

`pair` table

数据对 kv 结构，k为字段名称要求合乎sql规则，v可以tostring类型, 如果v是table 且table[1] 是 string,会按其值原样处理，==不作安全转换==.

如果是添加多条，由第一条数据结构决定字段数量

`return`

* id

  > 当添加多条数据时，仅是第一条数据的id

* nil, error

``` lua
-- sql: insert into `employees` (`emp_name`) values ('神探肥标')
tofu.model('employees').add({emp_name='神探肥标'})

-- sql: insert into `employees` (`emp_name`) values ('神探肥标'),('厨师废柴')
tofu.model('employees').add({emp_name='神探肥标'}, {emp_name='厨师废柴'})
```



model.del(cond)

删除数据

 `cond`  string | table

 参考上面model.get的cond参数。

return

* number 响应条数
* nil, error

``` lua
-- sql: delete from `employees`  where `emp_id`=99
tofu.model('employees').del({emp_id=99})
```



model.begin([opts])

主动开始事务

`opts` 数据库配置



model.rollback()

主动事件回滚



model.commit()

主动事务提交

``` lua
-- 
local m = tofu.model()
local ok = m.model('employees').add({emp_name = '神探肥标'})

if ok then
    m.commit()
else
    m.rollback()
end

```



model.trans(fn [, ...])

事务处理，自动执行 begin  commit / rollback

`fn`  function

业务处理函数

`...`  any

转递给 fn(...) 函数的参数

`return` 

返回 fn 的返回值

``` lua
local m = tofu.model()
local result = m.trans( function()
        local list = m.model('employees').get(nil, {limit = 10})
        if #list < 1 then
            return
        end
        --
        -- ... 业务处理
        --
        local it = list[1]
        return m.model('employees').del({emp_id = it.emp_id})
end)

-- 执行的 sql 
-- BEGIN
-- select * from `employees` limit 10
-- ...
-- delete from `employees`  where `emp_id`=21
-- COMMIT
--
```





### 定时任务扩展组件 / task

> resty.tofu.extend.task

该扩展组件熟于服务组件，提供了三种方式的定时任务

#### 配置 options

| 参数   | 类型            | 说明                                           | 必须 |       缺省       |
| ------ | --------------- | ---------------------------------------------- | :--: | :--------------: |
| worker | string \| int   | 绑定到nginx的worker上执行任务                  |  是  | privileged agent |
| task   | string \| table | 任务表或名称, 如果是名称,则在加载conf/名称.lua |  是  |       task       |



#### 使用配置

``` lua
-- 配置文件 conf/extend.lua

extend = {
    {
        named = 'task',
        default = {
        	handle = 'resty.touf.extend.task',
            options = {
                worker = 'privileged agent',
                task = 'task',
            }
        }
    },
}
```



#### task 任务配置

| 参数      | 类型               | 说明                                                 | 必须 | 缺省  |
| --------- | ------------------ | ---------------------------------------------------- | :--: | :---: |
| after     | int                | 延时执行定时器, 在设定的N秒后执行一次任务            |  否  |       |
| interval  | int                | 间隔执行定时器,每隔设定的N秒执行一次任务             |  否  |       |
| cron      | string             | 计划定时器, 格式 * * * * * 分别代表每 分 时 天 月 周 |  否  |       |
| handle    | string \| function | 要执行的函数或包名                                   |  否  |       |
| enable    | bool               | 是否开启该任务                                       |  否  | true  |
| immediate | bool               | 是否立即执行一次                                     |  否  | false |

task 配置格式

``` lua
-- conf/task.lua

task = {
    -- 延时执行定时器
    {
        after	= 3,
        handle	= function()
            		tofu.log.d('系统启动后，等待3了秒，然后执行了一次')
            	  end
    },
    
    -- 间隔执行定时器
    {
        interval 	= 5,
        handle		= function()
            			tofu.log.d('系统启动后，每隔5了秒，执行了一次')
            		  end
    },
    
    -- 计划执行定时器
    {
        cron = '0 3 * * *',		-- 每天在03:00时执行计划任务task.clean
        handle = 'task.clean'	
    }
    
}
```



### 内置方法扩展组件 / builtin

> resty.tofu.extend.builtin

内置扩展api, 直接使用 tofu.<api> 方式使用

#### 使用配置

``` lua
-- 配置文件 conf/extend.lua

extend = {
   'resty.tofu.extend.builtin'
}
```



#### Lua API

**tofu.response(errno, errmsg, data)**

响应请求，并默认以 Content-Type = application/json 方式回复

`errno` 状态号

`errmsg` 错误信息

`data` 有效数据

``` lua
tofu.response(0, '正确', {name='tofu(豆腐)'})

-- 响应body
-- {"errno":0, "errmsg"="正确", "data":{"name":"tofu(豆腐)"}}
```

> errno, errmsg, data 字段名称，可以在 conf/config.lua 中配置
>
> state_field
>
> message_field
>
> data_field



**tofu.success(data, msg)**

使用 default_state 响应请求(调用 tofu.response)

``` lua
tofu.success()
-- 响应body
-- {"errno":0, "errmsg":""}
```



**tofu.fail(errno, errmsg, data)**

响应错误请求(调用 tofu.response)

``` lua
tofu.fail(-1, "未知错误")
-- 响应body
-- {"errno":-1, "errmsg":"未知错误"}
```



### 文件监控扩展组件 / jili

> resty.tofu.extend.jili
>
> 依赖:系统 inotify 库

在开发过程中我们常常在修改->重启->出错->修改->重启，不断地重复。jili(吉利)组件是个文件监控组件，当检测到项目中的文件有改动，自动按规则进行重启或重新加载



#### 配置 options

| 参数  | 类型 | 说明                                 | 必须 | 缺省 |
| ----- | ---- | ------------------------------------ | :--: | :--: |
| trace | bool | 是否显示控加重新加载文件时的一些信息 |  否  | true |



#### 使用配置

``` lua
-- 配置文件 conf/extend.lua

extend = {
    {
        named = 'watcher',
        default = {
        	handle = 'resty.touf.extend.jili',
            options = {
                trace = true
            }
        }
    },
}
```







## 其它功能



### websocket

在tofu框架中使用websocket 非常简单，只需把普通的 controller "升级" 为wscontroller即可

#### 使用

``` lua
local _wsc = require 'resty.tofu.wscontroller'
```



#### Lua API

**upgrade(handler [, opts])**

* `handler` table, 事件接收处理器

| 事件方法                | 说明         | 必须 | 返回值 |
| ----------------------- | ------------ | :--: | ------ |
| _open(wb)               | 有新的连接   |  否  | state  |
| _close(wb , state)      | 连接断开     |  否  |        |
| _data(wb, data , state) | 有消息进入   |  否  |        |
| _ping(wb, data, state)  | 收到ping消息 |  否  |        |
| _pong(wb, data, state)  | 收到pong消息 |  否  |        |
| _timeout(wb, state)     | 超时         |  否  |        |

> `wb` [lua-resty-websocket](https://github.com/openresty/lua-resty-websocket) 对象
>
> `state` 保存当前用户状态,连接关闭后会被丢弃
>
> `data` 文本消息或binary消息



* `opts` table,  配置

| 参数            | 说明               | 必须 | 缺省  |
| --------------- | ------------------ | :--: | ----- |
| timeout         | 设置超时(秒)       |  否  | 5000  |
| max_payload_len | 最大消息长度(byte) |  否  | 65535 |



样例， ws://xxxx/ws 或 ws://xxxx/default/ws/index 进行连接

``` lua
-- lua/controller/default/ws

local _wsc = require 'resty.tofu.wscontroller'

local _M = {}

function _M.index()
    -- webscoket 握手处理，并设置接收websocket事件的处理
    _wsc.upgrade(_M)
end

--
-- websocket 事件处理
--
-- 当有连接完成时
function _M._open(wb)
    tofu.log.d('用户连接')
    local state = {}
    rturn state
end

-- 当连接断开时
function _M._close(web, state)
    tofu.log.d('断开连接')
end

-- 当有消息时
function _M._data(wb, data, state)
    tofu.log.d('接收数据:', data)
    wb:send_text(data)
end


return _M
```







### 参数验证器

tofu框架提供了一个简单的参数验证器 `resty.tofu.validation`。在tofu框架中推荐在guard阶断中使用，可以有效地验证参数，拦截请求，使得业务处理更新干净。

#### 使用

``` lua
local validation = require 'tofu.validation'
```



#### Lua API

**options(opts)**

设置

* `opts`

  | 参数   | 类型            | 说明                                                         | 缺省  |
  | ------ | --------------- | ------------------------------------------------------------ | :---: |
  | mode   | int             | 0:检测所有参数,1:当无效参数时立即返回(中断后面的参数检测流程) |   0   |
  | trim   | bool            | 是否去两端空白                                               | false |
  | amend  | bool            | 是否自动修正参数(需指定method), 如bool参可以是 true \| 1 'true' | false |
  | errmsg | string \| table | 缺省错误信息 优先级 指定>sgring>[0]                          |       |

  errmsg

  | 参数     | 类型   | 说明                                              | 缺省         |
  | -------- | ------ | ------------------------------------------------- | ------------ |
  | [0]      | string | 特殊的, 缺省信息,当没有指定错误信息时，使用该信息 | 参数错误     |
  | required | string | required参数的错误信息                            | 参数不参为空 |

  

**handle(rules)**

参数验证

* `rules`

  参数校验列表

  | 校验方法名   | 说明         | 区间{min, max} |      |
  | ------------ | ------------ | :------------: | ---- |
  | int          | 整型         |      支持      |      |
  | float        | 数值(number) |      支持      |      |
  | digit        | 纯数字串     |      支持      |      |
  | string       | 字符串       |      支持      |      |
  | date         | 日期         |                |      |
  | bool         | 布尔         |                |      |
  | alpha        | 字母         |                |      |
  | hex          | 十六进制     |                |      |
  | alphanumeric | 字母数字     |                |      |
  
  样例
  
  ``` lua
  -- <应用>lua/guard/default/index.lua
  
  local _validator = require 'resty.tofu.validation'.handle
  
  local _M = {}
  
  function _M.index()
      -- 验证用户帐号与用户密码
      local rules = {
          -- 参数名称 = { 验证规则 }
          -- 参数为必填, 字符串,长度限定在 [2, 20] 区间
          account = {required=true, string={min=2, max=20}, errmsg='帐号参数错误'},
  
          -- 参数为必填, 字符串,长度限定在 [6, 20] 区间
          password = {required=true, string={min=6, 20}, errmsg={ string='密码长度错误' }}
      }
      
      -- 如果参数有错误，则返回false 中断流程
      local ok, errs = _validator(rules)
      if not ok then
          tofu.log.d(errs)
          return tofu.fail(400, errs)
      end
  end
  
  return _M
  ```
  
  

**register(fs, f)**

注册新的/自定义验证器

* `fs`

  string 过滤器名称, table {string = function} 添加多个型式

  保留的方法/属性

  | 名称     | 说明                 | 缺省     |
  | -------- | -------------------- | -------- |
  | required | 是否必填参           | false    |
  | errmsg   | 错误信息             | 参数错误 |
  | value    | 获取值               |          |
  | default  | 缺省值               |          |
  | trim     | 是否去两端空白       | false    |
  | amend    | 是否自动修           | false    |
  | method   | 参数使用那种方法获取 |          |

  

* `f`

  function(value, cond) -> bool 验证器

  `value` 将要校验的值

  `cond` 校验条件

  当 value 合乎 cond 时返回 true

样例

``` lua

-- 增一个名为 mylist 的验证器
-- 作用：值必须存在列表中
local register = require 'tofu.validation'.register
register('mylist', function(v, cond)       
    if 'table' == type(cond) then
    	for _, c in ipairs(cond) do
        	if v == c then return true end
        end
   		return false
    end
        
    return false
end)
```

这个验证器有什么用，怎么用

``` lua
-- <应用>/lua/guard/default/test.lua

-- 有参数要求
-- y 年份, 必填，且只可以是 2019 2020 2021 的其中之一
-- m 月份, 可选，且只可以是 02 05 07 12 这四个月份的其中之一, 缺省为 07


local _validator = require 'resty.tofu.validation'.handle
local _M = {}

function _M.date()
    local rules = {
        -- 参数 y 
        y = { required = true, mylist = {'2019', '2020', '2021'}, errmsg='年份参数错误'},
        
        -- 参数 m
        m = { mylist = {'02', '05', '07', '08'}, default='07', errmsg = '月份参数错误'}
    }
    
    local ok, err = _validator(rules)
    if not ok then
        return tofu.fail(400, err)
    end
end


return _M
```

可以看到我们的验证器是可以通过简单的叠加，达到处理复杂的参数验证





### 工具箱

该包的api可以独立使用，也可以使用扩展组件方式集成到tofu中

#### 使用

``` lua
local _util = require 'resty.tofu.util'
```



#### Lua API

**split(str, delimiter)**

使有分隔符切分字符串，返回table(数组)

* `str` 要处理的字符串

* `delimiter` 分隔符号

  ``` lua
  local str = '蛋散,粉肠,茂梨,碌葛'
  local ret = _util.split(str, ',') 
  
  -- 结果: ret = {'蛋散‘,’粉肠‘,’茂梨‘,’碌葛'}
  ```

*　return table



**msplit(str, sep)**

使有分隔符切分字符串，返回table(数组)。与split不同，该方法支持多个分隔符

* `str` 要处理的字符串

* `sep` 分隔符号

  ``` lua
  local str = '蛋散,粉肠,茂梨,碌葛|神探肥标|厨师废柴'
  local ret = _util.msplit(str, ',|') 
  
  -- 结果: ret = {'蛋散‘,’粉肠‘,’茂梨‘,’碌葛',神探肥标','厨师废柴'}
  ```

* return string

  

**dirname(str)**

**getpath(str)**

切分路径，这两个函数作用一样

* `str`

  ``` lua
  local path = '/home/d/tofu/test.lua'
  local ret = _util.getpath(str)
  -- 结果: ret = '/home/d/tofu/'
  ```

* return string



**trim(str)**

去字符串两端空白

* `str` 要处理的字符串

  ``` lua
  local str = '           神探肥标  厨师废柴  '
  local ret = _util.trim(str)
  
  --结果: ret = '神探肥标  厨师废柴'
  ```

* return string



**bin_hex(s)**

把目标字符串，以二进制方式转换为十六进制字符串

* `s` 要处理的字符串

**hex_bin(s)**

把十六进制字符串，以二进制方式转换为字符串

* `s` 要处理的字符串

  ``` lua
  local str = 'hi tofu!'
  _util.hex_bin(str) -- 686920746f667521
  _util.bin_hex('686920746f667521') -- hi tofu!
  ```

* return string



**envsubstr(str, env)**

字符串模板中的变量`${}`替换

* `str` 字符串模板

* `env` 变量表

  ``` lua
  local str = 'hi ${name}!'
  local ret = _util.envsubstr(str, { name='tofu' })
  
  -- 结果: ret = 'hi tofu!'
  ```

* return string



**getusec()**

获取系统微秒级时间戳

* return int



**gettimezone()**

获取当前时区

* return int



**tosecond(str, tz)**

日期时间转换时间戳(秒)

* `str` 支持 yyyy-mm-dd hh:ii:ss | yyyy/m/d  | yyyy-m-d | hh:ii:ss 格式的日期时间字符串

* `tz` 时区 default: 0，如北京时间东8区

  ``` lua
  _util.tosecond('1970-01-01 08:00:00')	-- 28800 秒
  _util.tosecond('1970-01-01 08:00:00', 8)	-- 这是个北京时间字符串, 返回 0 秒
  ```

* return int



**isempty(obj)**

是否为空 '', {}, nil, ngx.null

* return bool

  

**isint(v)**

是否是int型

* return bool

  

**isfloat(v)**

是否是 float 型

* return bool

  

**iscallable(f)**

是否可调用

* return bool




