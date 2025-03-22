-- https://github.com/FredyH/MySQLOO/releases
-- "gmsv_mysqloo_*.dll" should be put in garrysmod/lua/bin/
require("mysqloo")
include("../../config/mysql.lua") -- Load mysql credentials

-- In case "gamemode/config/mysql.local.lua" exists, load it. 
-- This is useful for keeping your database credentials out of your public repository or for local testing.
if file.Exists(ATOMIC.Config.GamemodeFolderName .. "/gamemode/config/mysql.local.lua", "LUA") then include("../../config/mysql.local.lua") end

local hostname = MYSQL_HOSTNAME or "localhost"
local username = MYSQL_USERNAME or "atomic"
local password = MYSQL_PASSWORD or "atomic"
local database = MYSQL_DATABASE or "atomic"
local socket   = MYSQL_SOCKET   or "/var/run/mysqld/mysqld.sock"
local port     = MYSQL_PORT     or  3306
SQL = mysqloo.connect(hostname, username, password, database, port, socket)

function SQL:onConnected()
    print("Connected to the MySQL database!")
end

function SQL:onConnectionFailed(err)
    print("Failed to connect to the MySQL database:")
    print(err)
end

SQL:connect()
