-- Set the FX version and game type
fx_version "cerulean"
game "gta5"

-- Resource metadata
author "derPolarix"
description ""
version "1.0"
lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'shared/debug.lua',
    "config/shared.lua",
    "framework/shared.lua"
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    "framework/client.lua",
    "config/client.lua",
    "client/modules/*.lua",
    "client/*.lua",
    "client/nui/*.lua",
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
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
    "html/index.html"
}

ui_page "html/index.html"

-- ui_page "http://localhost:5050"

ox_libs {
    'locale',
    'math',
    'table',
}
