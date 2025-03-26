-- Create a table for the generic item template
ATOMIC.Items = ATOMIC.Items or {} -- Table of items, indexed by their ID
ATOMIC.ItemsByIdentifier = ATOMIC.ItemsByIdentifier or {} -- Table of items, indexed by their identifierName
local ITEM = {}
ITEM.__index = ITEM

-- Create a new item instance
function ITEM:New(data)
    local self = setmetatable({}, ITEM)
    self.id = data.id
    self.identifierName = data.identifierName
    self.name = data.name
    self.description = data.description
    self.itemWidth = data.itemWidth
    self.itemHeight = data.itemHeight
    self.weight = data.weight
    self.data = type(data.data) == "string" and util.JSONToTable(data.data) or data.data
    self.type = data.type
    self.script = data.script
    self.createdAt = data.createdAt

    ATOMIC.Items[self.id] = self
    if self.identifierName then
        ATOMIC.ItemsByIdentifier[self.identifierName] = self
    end

    return self
end

-- Insert a new item into the database
function ITEM:Create(data, callback)
    local model = Database.Models["items"]

    data.data = type(data.data) == "table" and util.TableToJSON(data.data) or data.data
    return model:Insert(data):Run(callback);
end