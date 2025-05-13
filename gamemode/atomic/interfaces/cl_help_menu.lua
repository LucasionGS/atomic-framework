-- Help menu for Atomic Framework

local helpPages = {
    {
        title = "Getting Started",
        content = [[
<h2>Welcome to Atomic Framework!</h2>

<p>This roleplay framework provides a rich experience with many features to enhance your gameplay. Here are the basics to get you started:</p>

<h3>Basic Commands</h3>
<ul>
    <li><b>/help</b> - Opens this help menu</li>
    <li><b>/ooc [message]</b> - Talk in out-of-character chat</li>
    <li><b>/me [action]</b> - Perform an action in roleplay</li>
    <li><b>/roll [number]</b> - Roll a dice with specified number of sides</li>
    <li><b>/dropmoney [amount]</b> - Drop specified amount of money</li>
</ul>

<h3>Character Creation</h3>
<p>You can create up to 5 characters per player account. Each character has their own inventory, attributes, and skills.</p>
]]
    },
    {
        title = "Attribute System",
        content = [[
<h2>Character Attributes</h2>

<p>The Attribute System consists of both Skills and Stats:</p>

<h3>Skills</h3>
<p>Skills improve as you use them and provide various bonuses:</p>
<ul>
    <li><b>Strength</b> - Affects carrying capacity and physical damage</li>
    <li><b>Agility</b> - Affects movement speed and jumping ability</li>
    <li><b>Endurance</b> - Affects health and stamina regeneration</li>
    <li><b>Intelligence</b> - Affects crafting abilities and specialized tasks</li>
    <li><b>Crafting</b> - Determines your ability to craft items efficiently</li>
    <li><b>Cooking</b> - Affects the quality and effects of food you prepare</li>
    <li><b>Medical</b> - Improves healing abilities and medical crafting</li>
    <li><b>Lockpicking</b> - Affects your ability to pick locks</li>
    <li><b>Hacking</b> - Affects your ability to hack electronic devices</li>
</ul>

<h3>Stats</h3>
<p>Stats are vital metrics that affect your character's condition:</p>
<ul>
    <li><b>Health</b> - Your character's physical condition</li>
    <li><b>Stamina</b> - Ability to sprint and perform physical actions</li>
    <li><b>Hunger</b> - Your character's hunger level (needs food)</li>
    <li><b>Thirst</b> - Your character's thirst level (needs drinks)</li>
</ul>

<h3>Improving Skills</h3>
<p>Skills improve naturally as you perform related actions. For example:
<ul>
    <li>Running improves Agility</li>
    <li>Crafting items improves Crafting skill</li>
    <li>Using medical items improves Medical skill</li>
</ul>

<h3>Commands</h3>
<ul>
    <li><b>/atomic_attributes</b> - Opens the attributes menu</li>
</ul>
]]
    },
    {
        title = "Survival System",
        content = [[
<h2>Survival Mechanics</h2>

<p>Atomic Framework includes a survival system with hunger and thirst mechanics:</p>

<h3>Hunger & Thirst</h3>
<p>Your character needs to eat and drink regularly:</p>
<ul>
    <li>Hunger decreases over time and requires food to replenish</li>
    <li>Thirst decreases faster than hunger and requires drinks</li>
    <li>If either stat drops too low, you will begin taking damage</li>
    <li>At extremely low levels, your character may die from starvation or dehydration</li>
</ul>

<h3>Food & Drinks</h3>
<p>Various consumable items exist in the world:</p>
<ul>
    <li>Basic foods like apples and bread restore small amounts of hunger</li>
    <li>More substantial foods like burgers and steaks restore larger amounts</li>
    <li>Water bottles are essential for maintaining hydration</li>
    <li>Some items like energy drinks provide special effects</li>
</ul>

<h3>Effects of Low Stats</h3>
<ul>
    <li>Low hunger reduces movement speed and jump height</li>
    <li>Low thirst affects stamina regeneration and causes dizziness</li>
    <li>Extremely low levels of either cause health damage over time</li>
</ul>

<p>Keep an eye on your HUD to monitor these stats!</p>
]]
    },
    {
        title = "Crafting System",
        content = [[
<h2>Crafting System</h2>

<p>The crafting system allows you to create items from raw materials:</p>

<h3>How to Craft</h3>
<ul>
    <li>Open the crafting menu with <b>/atomic_crafting</b> command</li>
    <li>Browse available recipes by category</li>
    <li>Select a recipe to view required ingredients and skill levels</li>
    <li>If you have all requirements, click "Craft" to create the item</li>
</ul>

<h3>Skill Requirements</h3>
<p>Some recipes require minimum skill levels to craft:</p>
<ul>
    <li>Basic items typically have no skill requirements</li>
    <li>More advanced or valuable items require higher skill levels</li>
    <li>Specialized items may require specific skills (Medical, Cooking, etc.)</li>
</ul>

<h3>Crafting Benefits</h3>
<ul>
    <li>Higher crafting skills reduce crafting time</li>
    <li>Successfully crafting items has a chance to improve related skills</li>
    <li>Self-crafted items may have better properties than purchased ones</li>
</ul>

<h3>Material Gathering</h3>
<p>Raw materials can be:</p>
<ul>
    <li>Purchased from NPC vendors</li>
    <li>Found throughout the world</li>
    <li>Obtained by breaking down other items</li>
</ul>
]]
    }
}

-- Create the help menu
function ATOMIC:OpenHelpMenu()
    if IsValid(self.HelpMenu) then
        self.HelpMenu:Remove()
    end
    
    -- Create main frame
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Atomic Framework - Help")
    frame:SetSize(800, 600)
    frame:Center()
    frame:MakePopup()
    
    -- Create horizontal divider
    local divider = vgui.Create("DHorizontalDivider", frame)
    divider:Dock(FILL)
    divider:SetLeftWidth(200)
    divider:SetLeftMin(150)
    divider:SetRightMin(400)
    
    -- Create category list
    local categoryList = vgui.Create("DListView")
    categoryList:AddColumn("Topics")
    divider:SetLeft(categoryList)
    
    -- Add all help pages to the list
    for i, page in ipairs(helpPages) do
        categoryList:AddLine(page.title)
    end
    
    -- Create content panel with HTML
    local contentPanel = vgui.Create("DHTML")
    divider:SetRight(contentPanel)
    contentPanel:SetHTML([[
        <html>
            <head>
                <style>
                    body {
                        font-family: Arial, sans-serif;
                        margin: 10px;
                        color: #CCCCCC;
                        background-color: #2D2D2D;
                    }
                    h2 {
                        color: #729FCF;
                        border-bottom: 1px solid #729FCF;
                        padding-bottom: 5px;
                    }
                    h3 {
                        color: #8AE234;
                        margin-top: 15px;
                    }
                    ul {
                        margin-left: 20px;
                    }
                    li {
                        margin-bottom: 5px;
                    }
                    b {
                        color: #EEEEEE;
                    }
                </style>
            </head>
            <body>
                <h2>Welcome to Atomic Framework!</h2>
                <p>Select a topic from the list to view help information.</p>
            </body>
        </html>
    ]])
    
    -- Handle category selection
    categoryList.OnRowSelected = function(panel, rowIndex, row)
        local page = helpPages[rowIndex]
        if page then
            contentPanel:SetHTML([[
                <html>
                    <head>
                        <style>
                            body {
                                font-family: Arial, sans-serif;
                                margin: 10px;
                                color: #CCCCCC;
                                background-color: #2D2D2D;
                            }
                            h2 {
                                color: #729FCF;
                                border-bottom: 1px solid #729FCF;
                                padding-bottom: 5px;
                            }
                            h3 {
                                color: #8AE234;
                                margin-top: 15px;
                            }
                            ul {
                                margin-left: 20px;
                            }
                            li {
                                margin-bottom: 5px;
                            }
                            b {
                                color: #EEEEEE;
                            }
                        </style>
                    </head>
                    <body>
                        ]] .. page.content .. [[
                    </body>
                </html>
            ]])
        end
    end
    
    -- Select first item by default
    categoryList:SelectItem(categoryList:GetLine(1))
    
    self.HelpMenu = frame
    return frame
end

-- Add command to open help menu
concommand.Add("atomic_help", function()
    ATOMIC:OpenHelpMenu()
end)

-- Add chat command
hook.Add("OnPlayerChat", "ATOMIC:HelpCommand", function(ply, text)
    if text:lower() == "/help" or text:lower() == "!help" then
        if ply == LocalPlayer() then
            ATOMIC:OpenHelpMenu()
        end
        return true
    end
end)

-- Add to F1 menu
hook.Add("ATOMIC:BuildF1Menu", "ATOMIC:AddHelpToF1", function(panel, sheet)
    local helpTab = vgui.Create("DPanel")
    
    local button = vgui.Create("DButton", helpTab)
    button:SetText("Open Help Menu")
    button:SetSize(200, 40)
    button:Center()
    button.DoClick = function()
        ATOMIC:OpenHelpMenu()
    end
    
    sheet:AddSheet("Help", helpTab, "icon16/help.png")
end)
