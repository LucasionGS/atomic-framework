-- Create a table for the generic item template
ATOMIC.Items = ATOMIC.Items or {} -- Table of items, indexed by their ID
ATOMIC.ItemsById = ATOMIC.ItemsById or {} -- Table of items, indexed by their Id
ATOMIC.ItemsByIdentifier = ATOMIC.ItemsByIdentifier or {} -- Table of items, indexed by their identifierName
ITEM = {}
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

    -- Add the item to the global items tables
    table.insert(ATOMIC.Items, self)
    ATOMIC.ItemsById[self.id] = self
    if self.identifierName then
        ATOMIC.ItemsByIdentifier[self.identifierName] = self
    end

    return self
end

-- Insert a new or existing item into the database
function ITEM:Save(data, callback)
    local model = Database.Models["items"]
    data = table.Copy(data)

    data.data = type(data.data) == "table" and util.TableToJSON(data.data) or data.data
    
    return model:Upsert(data):Run(callback);
end