include("mysqloo.lua")
Database = {} -- Global for database functions

Database.PrimaryKey = ATOMIC.Config.DatabasePrimaryKey or "id"
Database.Models = Database.Models or {}
Database.Debug = ATOMIC.Config.Debug or false

--[[
    Executes a query on the database and calls the callback function with the data.
]]
function Database:Query(query, values, callback)
    if type(values) == "function" then
        callback = values
        values = nil
    end
    
    -- Escape and replace values in the query
    if values then
        for k, v in pairs(values) do
            if type(v) == "string" then
                query = query:gsub("?", "'" .. SQL:escape(v) .. "'", 1)
            else
                query = query:gsub("?", v, 1)
            end
        end
    end

    local q = SQL:query(query)

    ATOMIC:Debug("Executing query: " .. query, values and "with values" or "")
    
    function q:onSuccess(data)
        ATOMIC:Debug("Successful query: " .. query)
        if callback then callback(data) end
    end

    function q:onError(err)
        ATOMIC:Debug("Query failed: " .. err)
    end

    q:start()

    return q;
end

function Database:CreateTable(tableName, columns, callback)
    local query = "CREATE TABLE IF NOT EXISTS " .. tableName .. " ("
    for k, v in pairs(columns) do
        query = query .. v .. ","
    end
    query = query:sub(1, -2) .. ")"
    Database:Query(query, callback)
end

--[[
    Create a query object for constructing a query with an elegant API.
]]
function Database:CreateQueryInterface(tableName)
    local queryObject = {}

    function queryObject:Raw(query)
        self.rawQuery = query
        return self
    end

    function queryObject:Select(...)
        self.selectColumns = {...}
        return self
    end

    --[[
        The format of the parameters is (example):
            {
                { id = 1, name = "John" },
                { id = 2, name = "Jane" }
            }
    ]]
    function queryObject:Insert(...)
        self.insertData = {...}
        return self
    end

    function queryObject:InsertInto(tableName, ...)
        self:Table(tableName)
        self:Insert(...)
        return self
    end

    function queryObject:AddInsert(...)
        self.insertData = self.insertData or {}
        table.Merge(self.insertData, {...})
        return self
    end

    function queryObject:Update(tableName, ...)
        self:Table(tableName)
        self.updateData = {...}
        return self
    end

    function queryObject:Table(tableName)
        self.fromTable = tableName
        return self
    end

    --[[
        The format of the parameters is:
            {
                "column1 = 'value'",
                { "column2 = ?", value },
                { "column3 = ? OR column4 = ?", value, value }
            }
        Each entry is joined with "AND".
    ]]
    function queryObject:Where(...)
        self.where = {...}
        return self
    end

    function queryObject:Run(callback)

        if type(callback) == "function" and type(self.transformCallback) == "function" then
            local ogCallback = callback
            callback = function(data)
                return ogCallback(self.transformCallback(data))
            end
        end

        if (self.rawQuery) then
            self.currentQuery = Database:Query(self.rawQuery, callback)
        elseif (self.selectColumns and self.fromTable) then
            -- Select query
            local query = "SELECT " .. table.concat(self.selectColumns, ", ") .. " FROM `" .. self.fromTable .. "` WHERE ("
            local values = {}
            for k, v in pairs(self.where) do
                if type(v) == "table" then
                    query = query .. v[1] .. " AND "
                    for i = 2, #v do
                        table.insert(values, v[i])
                    end
                else
                    query = query .. v .. " AND "
                end
            end
            query = query:sub(1, -5) .. ")"
            self.currentQuery = Database:Query(query, #values > 0 and values or nil, callback)

        elseif (self.insertData and self.fromTable) then
            -- Insert query
            local query = "INSERT INTO `" .. self.fromTable .. "` "
            local values = {}
            local orderValues = nil
            for i, v in ipairs(self.insertData) do
                if orderValues == nil then
                    orderValues = {}
                    for k, _ in pairs(v) do
                        table.insert(orderValues, k)
                    end

                    local columnString = "("
                    for k, _ in pairs(v) do
                        columnString = columnString .. k .. ","
                    end
                    query = query .. columnString:sub(1, -2) .. ") VALUES "
                end
                
                local valueString = "("
                for k, _ in pairs(v) do
                    valueString = valueString .. "?,"
                    table.insert(values, v[k])
                end
                valueString = valueString:sub(1, -2) .. "),"
                query = query .. valueString
            end

            query = query:sub(1, -2)
            self.currentQuery = Database:Query(query, #values > 0 and values or nil, callback)
        elseif (self.updateData and self.fromTable) then
            -- Update query
            local query = "UPDATE `" .. self.fromTable .. "` SET "
            local values = {}
            for k, v in pairs(self.updateData) do
                if type(v) == "table" then
                    query = query .. v[1] .. ", "
                    for i = 2, #v do
                        table.insert(values, v[i])
                    end
                else
                    query = query .. v .. ", "
                end
            end
            query = query:sub(1, -3) .. " WHERE ("
            for k, v in pairs(self.where) do
                if type(v) == "table" then
                    query = query .. v[1] .. " AND "
                    for i = 2, #v do
                        table.insert(values, v[i])
                    end
                else
                    query = query .. v .. " AND "
                end
            end
            query = query:sub(1, -5) .. ")"
            self.currentQuery = Database:Query(query, #values > 0 and values or nil, callback)
        end

        return self
    end


    function queryObject:Wait()
        self.currentQuery:wait()
        local data = self.currentQuery:getData();
        if self.transformCallback then
            return self.transformCallback(data)
        else
            return data
        end
    end

    -- Transforms the output via callback or Wait() function
    function queryObject:Transform(callback)
        queryObject.transformCallback = callback
        return queryObject
    end

    -- Constructor
    if tableName then
        queryObject:Table(tableName)
    end

    return queryObject
end


-- Models for easy database access

function Database:CreateModel(tableName, columnsOrder, columnsDefinition)
    local model = {}

    model.tableName = tableName
    model.columnsOrder = columnsOrder
    model.columnsDefinition = columnsDefinition

    function model:CreateTable(callback)
        return Database:CreateTable(self.tableName, self.columnsDefinition, callback)
    end

    function model:TableExists(callback)
        return Database:CreateQueryInterface():Raw(
            "SELECT COUNT(*) AS 'exists' " ..
            "FROM information_schema.tables " ..
            "WHERE table_schema = '" .. "atomic" .. "' AND table_name = '" .. self.tableName .. "'"
        ):Transform(function(data)
            return data[1].exists == 1
        end):Run(callback)
    end

    function model:Select(...)
        return Database:CreateQueryInterface(self.tableName):Select(...)
    end

    function model:Insert(...)
        return Database:CreateQueryInterface(self.tableName):Insert(...)
    end

    function model:Update(...)
        return Database:CreateQueryInterface(self.tableName):Update(...)
    end

    function model:Where(...)
        return Database:CreateQueryInterface(self.tableName):Where(...)
    end

    Database.Models[tableName] = model
    
    return model
end

function Database:Model(tableName)
    return Database.Models[tableName]
end

include("models.lua")