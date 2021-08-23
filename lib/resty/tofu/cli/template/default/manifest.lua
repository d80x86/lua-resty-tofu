--
-- default 模板清单
--
name		= 'default tofu project template'
author	= 'd'
version	= '0.1.1'


list = {
	-- {src, dest, method}
	{'gitignore', '.gitignore'},
	{'tofu.package.lua', 'tofu.package.lua'},

	{'conf', 'conf'},
	{'conf/config.lua', 'conf/config.lua'},
	{'conf/extend.lua', 'conf/extend.lua'},
	{'conf/middleware.lua', 'conf/middleware.lua'},
	{'conf/task.lua', 'conf/task.lua'},
	{'conf/tofu.nginx.conf', 'conf/tofu.nginx.conf', 'macro'},
	-- {'conf/mime.types.conf', 'conf/mime.types.conf'},

	{'lua/controller/default', 'lua/controller/default'},
	{'lua/controller/default/_base.lua', 'lua/controller/default/_base.lua'},
	{'lua/controller/default/index.lua', 'lua/controller/default/index.lua'},

	{'lua/guard/default', 'lua/guard/default'},
	{'lua/guard/default/_base.lua', 'lua/guard/default/_base.lua'},
	{'lua/guard/default/index.lua', 'lua/guard/default/index.lua'},

	{'view/default', 'view/default'},
	{'view/default/_layout.html', 'view/default/_layout.html'},
	{'view/default/index_index.html', 'view/default/index_index.html'},

	{'www', 'www'},
	{'www/gitkeep', 'www/.gitkeep'},
}



