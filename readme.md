# lua-resty-tofu

tofu(豆腐) 是一个api/web framework, 开箱即用，使得基于openresty开发应用时更加丝般顺滑



## 状态

alpha 阶段, 目前仅支持 linux/unix 环境



## 特性

* 基于openresty
* middleware方式流程处理
* 所有功能使用extend方式
* 内置常用工具包脚手架等,方便开发



## 开速开始

openresty 在提供脚手架方面非常有限，请确保环境已安装好  openresty 与 opm [安装]([OpenResty - Installation](http://openresty.org/en/installation.html))



### 创建项目目录

> 创建一个普通的目录，并进入该目录中

```sh
## 创建一个项目目录
mkdir project_name
cd project_name

## 使用opm，仅安装tofu在当前项目,并软连接到当前目录
mkdir -p lua_modules/resty
opm --install-path=lua_modules/resty install d80x86/lua-resty-tofu
ln -s lua_modules/resty/lualib/resty/tofu/cli/tofu tofu

## 使用tofu脚手架初始化目录, 因为当前目录已存在，这里会提示:目录已存在是否覆盖
## 选择 y 覆盖即可
./tofu new

```



### 安装依赖

```sh
./tofu install
```

> 内置的 view session 等组件依赖了第三方库



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

```
./tofu start
```



更多命令

```shell
./tofu help
```

执行后会看到下面的信息

```sh
usage:tofu COMMADN [OPTIONS]...

the available commands are:
console		start service (development)
help			help
install		install deps to current resty_module
new				create a new project in the directory
reload		reload nginx.conf
start			start service (production)
stop			stop service
version		show version information

```

> 如想查看某命令的使用方式
>
> ./tofu help console



### 依赖管理

许多时候我们都有比较好的第三方库或解决方案选择，我们直接下载使用即可，无需做过多的重复情工作。tofu一些内置组件 view , session 等有第三方依赖，如我们需要使用，只需添加相关组件配置和安装依赖即可使用。安装依赖tofu也提供简单的管理方案,只需要:

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
				{'luarocks', 'lua-resty-jwt'} -- 指定 luarocks 方式
}
```

2. #### 然后执行

```sh
./tofu install
```

tofu 会根据 ```tofu.package.lua``` 文件中所配置 ```deps={...}``` 列表使用opm或luarocks进行安装所需要的依赖.

相关依赖安装在当前目录```lua_modules```中.（默认情况下tofu已将该目录添加到 lua_package_path 中了）

下面是安装依赖包的过程信息

```sh
install bungle/lua-resty-template
* Fetching bungle/lua-resty-template  
  Downloading https://opm.openresty.org/api/pkg/tarball/bungle/lua-resty-template-2.0.opm.tar.gz
	  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
		                                 Dload  Upload   Total   Spent    Left  Speed
																		 100 40890  100 40890    0     0  62267      0 --:--:-- --:--:-- --:--:-- 62237
																		 Package bungle/lua-resty-template 2.0 installed successfully under 

																		 install bungle/lua-resty-session
																		 * Fetching bungle/lua-resty-session  
																		   Downloading https://opm.openresty.org/api/pkg/tarball/bungle/lua-resty-session-3.8.opm.tar.gz
																			   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
																				                                  Dload  Upload   Total   Spent    Left  Speed
																																					100 48825  100 48825    0     0  87871      0 --:--:-- --:--:-- --:--:-- 87814
																																					* Fetching openresty/lua-resty-string  
																																					  Downloading https://opm.openresty.org/api/pkg/tarball/openresty/lua-resty-string-0.11.opm.tar.gz
																																						  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
																																							                                 Dload  Upload   Total   Spent    Left  Speed
																																																							 100  6144  100  6144    0     0  17539      0 --:--:-- --:--:-- --:--:-- 17554
																																																							 Package openresty/lua-resty-string 0.11 installed successfully under /

																																																							 Package bungle/lua-resty-session 3.8 installed successfully under 

																																																							 install lua-resty-jwt
																																																							 Warning: falling back to wget - install luasec to get native HTTPS support
																																																							 Installing https://luarocks.org/lua-resty-jwt-0.2.3-0.src.rock
																																																							 Missing dependencies for lua-resty-jwt 0.2.3-0:
																																																							    lua-resty-openssl >= 0.6.8 (not installed)

																																																									...
																																																									```




