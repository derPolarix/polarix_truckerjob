-- Framework adapter - shared (client + server)
-- Loaded before all other scripts. Defines framework-agnostic globals.
-- Active framework is set in config/shared.lua -> Framework (e.g. "qbox", "qb-core", "esx")
local config = require("config.shared")

Framework = {}
