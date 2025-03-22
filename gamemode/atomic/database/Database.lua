include("mysqloo.lua")
Database = {} -- Global for database functions

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

    print("Executing query: " .. query, values and "with values" or "")
    
    function q:onSuccess(data)
        print("Successful query: " .. query)
        if callback then callback(data) end
    end

    function q:onError(err)
        print("Query failed: " .. err)
    end

    q:start()

    return q;
end

function Database:CreateTable(tableName, columns)
    local query = "CREATE TABLE IF NOT EXISTS " .. tableName .. " ("
    for k, v in pairs(columns) do
        query = query .. v .. ","
    end
    query = query:sub(1, -2) .. ")"
    Database:Query(query, function(data)
        print("Table " .. tableName .. " created.")
    end)
end

--[[
    Create a query object for constructing a query with an elegant API.
]]
function Database:CreateQueryInterface()
    local queryObject = {}

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

    function queryObject:AddInsert(...)
        self.insertData = self.insertData or {}
        table.Merge(self.insertData, {...})
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

    function queryObject:Run()
        if (self.selectColumns and self.fromTable) then
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
            self.currentQuery = Database:Query(query, #values > 0 and values or nil, function(data)
                print("Query result:")
                PrintTable(data)
            end)

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
            self.currentQuery = Database:Query(query, #values > 0 and values or nil)
        end

        return self
    end


    function queryObject:Wait()
        self.currentQuery:wait()
        return self
    end

    return queryObject
end