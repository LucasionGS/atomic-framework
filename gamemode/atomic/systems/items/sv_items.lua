-- Create a table for the generic item template
ATOMIC.Items = ATOMIC.Items or {} -- Table of items, indexed by their ID
ATOMIC.ItemsByIdentifier = ATOMIC.ItemsByIdentifier or {} -- Table of items, indexed by their identifierName
ITEM = {}
ITEM.__index = ITEM

-- Create a new item instance
function ITEM:New(data)
    local self = setmetatable({}, ITEM)
    self.identifierName = data.identifierName
    self.name = data.name
    self.description = data.description
    self.itemWidth = data.itemWidth
    self.itemHeight = data.itemHeight
    self.weight = data.weight
    self.data = type(data.data) == "string" and util.JSONToTable(data.data) or data.data
    self.type = data.type
    if not self.identifierName then
        ATOMIC:Raise("ITEM:New() - identifierName is required")
        return
    end

    -- Add the item to the global items tables
    table.insert(ATOMIC.Items, self)
    ATOMIC.ItemsByIdentifier[self.identifierName] = self

    -- Functions

    return self
end