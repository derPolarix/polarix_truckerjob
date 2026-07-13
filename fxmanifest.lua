fx_version "cerulean"
game "gta5"

author "derPolarix"
description ""
version "1.0.0"
lua54 'yes'
use_experimental_fxv2_oal 'yes'
this_is_a_map 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/debug.lua',
    'shared/cargo.lua',
    'shared/locale.lua',
    "config/shared.lua",
    "framework/qbox/shared.lua",
    "framework/qb-core/shared.lua",
    "framework/esx/shared.lua",
    "framework/shared.lua"
}

client_scripts {
    "framework/qbox/client.lua",
    "framework/qb-core/client.lua",
    "framework/esx/client.lua",
    "framework/client.lua",
    "config/client.lua",
    "client/modules/*.lua",
    "client/*.lua",
    "client/nui/*.lua",
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    "framework/qbox/server.lua",
    "framework/qb-core/server.lua",
    "framework/esx/server.lua",
    "framework/server.lua",
    "config/server.lua",
    "server/modules/*.lua",
    "server/*.lua",
}

files {
    'locales/*.json',
    "html/*",
    "html/assets/*",
    "html/img/*",
    "html/index.html",
    'stream/sm3d_prop_pallets_def.ytyp',
	'stream/sm3d_prop_logi_shelf_def.ytyp'
}

ui_page "html/index.html"

-- ui_page "http://localhost:5050"

ox_libs {
    'locale',
    'math',
    'table',
}

data_file 'DLC_ITYP_REQUEST' 'stream/sm3d_prop_pallets_def.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/sm3d_prop_logi_shelf_def.ytyp'
