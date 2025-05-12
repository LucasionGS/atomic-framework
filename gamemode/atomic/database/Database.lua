include("mysqloo.lua")
Database = {} -- Global for database functions

Database.PrimaryKey = ATOMIC.Config.DatabasePrimaryKey or "id"
Database.Models = Database.Models or {}

--[[
    Executes a query on the database and calls the callback function with the data.
]]
function Database:Query(query, values, callback, onErrorCallback)
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

    ATOMIC:Debug("EXECUTING: " .. query, values and "with values" or "")
    
    function q:onSuccess(data)
        ATOMIC:Debug(ATOMIC.Config.Colors.Success, "SUCCESS:   ", ATOMIC.Config.Colors.OffWhite, query)
        if callback then callback(data) end
    end

    function q:onError(err)
        ATOMIC:Debug(ATOMIC.Config.Colors.Error, "FAILED: ", ATOMIC.Config.Colors.OffWhite, err)
        if onErrorCallback then onErrorCallback(err) end
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
    
    return Database:Query(query, callback)
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
        if #self.selectColumns == 0 then
            self.selectColumns = {"*"}
        end
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

    function queryObject:Update(...)
        self.updateData = {...}
        return self
    end

    function queryObject:Delete()
        self.delete = true
        return self
    end

    function queryObject:UpdateEntry(primaryKey, ...)
        self.updateData = {...}
        self.where = self.where or {}
        self.where[Database.PrimaryKey] = primaryKey
        return self
    end

    function queryObject:Table(tableName)
        self.fromTable = tableName
        return self
    end

    function queryObject:Limit(offset, limit)
        self.limit = { offset }
        if limit ~= nil then
            self.limit = { offset, limit }
        end
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
            local whereClause, values = GenerateWhereClause(self.where)
            local query = "SELECT " .. table.concat(self.selectColumns, ", ") .. " FROM `" .. self.fromTable .. "` " .. whereClause
            if self.limit then
                query = query .. " LIMIT " .. table.concat(self.limit, ", ")
            end
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
            local whereClause, values = GenerateWhereClause(self.where)
            for k, v in pairs(self.updateData) do
                PrintTable(self.updateData)
                if type(v) == "table" then
                    print(v[1])
                    query = query .. v[1] .. ", "
                    for i = 2, #v do
                        table.insert(values, v[i])
                    end
                else
                    query = query .. v .. ", "
                end
            end
            query = query:sub(1, -3) .. " " .. whereClause
            if self.limit then
                query = query .. " LIMIT " .. table.concat(self.limit, ", ")
            end
            self.currentQuery = Database:Query(query, #values > 0 and values or nil, callback)
        elseif (self.delete and self.fromTable) then
            -- Delete query
            local whereClause, values = GenerateWhereClause(self.where)
            local query = "DELETE FROM `" .. self.fromTable .. "` " .. whereClause
            if self.limit then
                query = query .. " LIMIT " .. table.concat(self.limit, ", ")
            end
            self.currentQuery = Database:Query(query, #values > 0 and values or nil, callback)
        else
            ATOMIC:Raise("No valid query was created.")
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
            "WHERE table_schema = '" .. "atomic" .. "' AND table_name = '" .. self.tableName .. "' " ..
            "LIMIT 1"
        ):Transform(function(data)
            return data[1].exists == 1
        end):Run(callback)
    end

    function model:RowExists(column, value, callback)
        return Database:CreateQueryInterface(self.tableName):Where({column .. " = ?", value}):Limit(1):Select():Transform(function(data)
            return #data > 0
        end):Run(callback)
    end

    function model:Delete(...)
        return Database:CreateQueryInterface(self.tableName):Where(...):Delete()
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
    
    function model:UpdateEntry(primaryKey, ...)
        return Database:CreateQueryInterface(self.tableName):UpdateEntry(primaryKey, ...)
    end

    function model:Upsert(data)
        local int = Database:CreateQueryInterface(self.tableName)
        if (data[Database.PrimaryKey]) then
            int:UpdateEntry(data[Database.PrimaryKey], data)
        else
            int:Insert(data)
        end
        return int
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

-- Helper functions
function GenerateWhereClause(where)
    local values = {}
    
    if where == nil or #where == 0 then
        return "", values
    end
    
    local whereClause = "WHERE "
    
    for k, v in pairs(where) do
        if type(v) == "table" then
            whereClause = whereClause .. v[1] .. " AND "
            for i = 2, #v do
                table.insert(values, v[i])
            end
        else
            whereClause = whereClause .. k .. " = '" .. SQL:escape(v) .. "' AND "
        end
    end
    return whereClause:sub(1, -5), values
end

include("models.lua")