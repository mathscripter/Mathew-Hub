--[[
    ★ STAR SPAWNER | GROW A GARDEN 2
    Tabs: Pets | Seeds | Gears | Dupe
    • Spawned items appear in your REAL inventory
    • Can be placed in garden AND sent via mailbox
    • Toggle: INSERT or RightShift
]]

-- ── Duplicate guard ────────────────────────────────────────
if getgenv().StarSpawnerLoaded then
    pcall(function() getgenv().StarSpawnerGui:Destroy() end)
end
getgenv().StarSpawnerLoaded = true

-- ── Services ───────────────────────────────────────────────
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ── Notify ─────────────────────────────────────────────────
local function Notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 3
        })
    end)
end

-- ── Find remote helper ─────────────────────────────────────
local function FindRemote(...)
    local names = {...}
    local containers = {
        ReplicatedStorage,
        ReplicatedStorage:FindFirstChild("Remotes"),
        ReplicatedStorage:FindFirstChild("Events"),
        ReplicatedStorage:FindFirstChild("RemoteEvents"),
        ReplicatedStorage:FindFirstChild("RE"),
        ReplicatedStorage:FindFirstChild("Network"),
    }
    for _, container in ipairs(containers) do
        if container then
            for _, name in ipairs(names) do
                local r = container:FindFirstChild(name, true)
                if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
                    return r
                end
            end
        end
    end
    return nil
end

-- ── DATA ───────────────────────────────────────────────────
local PETS = {
    -- Common
    "Dog","Cat","Bunny","Chicken","Cow","Sheep","Pig","Duck","Horse","Frog",
    "Turtle","Parrot","Hamster","Rabbit","Fox","Deer","Raccoon","Squirrel",
    -- Uncommon
    "Bee","Butterfly","Dragonfly","Ladybug","Firefly","Snail","Crab","Octopus",
    -- Rare
    "Dragon","Phoenix","Unicorn","Griffin","Pegasus","Kirin","Cerberus",
    "Ice Serpent","Fire Serpent","Storm Eagle","Crystal Fox","Shadow Wolf",
    -- Epic
    "Mega Dragon","Golden Unicorn","Rainbow Phoenix","Void Wolf","Celestial Deer",
    "Neon Bunny","Prismatic Cat","Galaxy Horse","Cosmic Turtle",
    -- Legendary
    "Star Dragon","Divine Phoenix","Eternal Griffin","Omega Serpent","Mythical Kirin",
    -- Mythical
    "God Dragon","Supreme Phoenix","Transcendent Unicorn","Infinite Wolf",
}

local PET_SIZES = {"Normal", "Big", "Huge", "Titan", "Mega", "Giga", "Colossal"}

local PET_MUTATIONS = {
    "None","Shiny","Rainbow","Golden","Diamond","Prismatic","Neon","Void",
    "Celestial","Cosmic","Eternal","Divine","Mythical","Transcendent","Omega",
}

local SEEDS = {
    -- Common
    "Carrot","Strawberry","Blueberry",
    -- Uncommon  
    "Tulip","Tomato","Apple",
    -- Rare
    "Bamboo","Corn","Cactus","Pineapple",
    -- Epic
    "Mushroom","Green Bean","Banana","Grape","Coconut","Mango",
    -- Legendary
    "Dragon Fruit","Acorn","Cherry","Sunflower","Venus Fly Trap",
    -- Mythic
    "Pomegranate","Poison Apple","Venom Spitter",
    -- Super
    "Moon Bloom","Dragon's Breath",
}

local GEARS = {
    "Watering Can","Shovel","Trowel","Hoe","Rake","Pruner","Sprinkler",
    "Fertilizer","Growth Serum","Harvest Tool","Magic Wand","Star Shovel",
    "Golden Watering Can","Diamond Hoe","Platinum Rake",
}

-- ── THEME ──────────────────────────────────────────────────
local C = {
    BG     = Color3.fromRGB(15, 13, 25),
    Panel  = Color3.fromRGB(22, 19, 38),
    Card   = Color3.fromRGB(30, 26, 50),
    Green  = Color3.fromRGB(80, 200, 80),
    GreenD = Color3.fromRGB(40, 130, 40),
    Brown  = Color3.fromRGB(120, 70, 30),
    BrownD = Color3.fromRGB(80, 45, 15),
    Gold   = Color3.fromRGB(255, 200, 50),
    Red    = Color3.fromRGB(200, 50, 60),
    Text   = Color3.new(1,1,1),
    Sub    = Color3.fromRGB(180,175,210),
    Div    = Color3.fromRGB(50,40,80),
    Input  = Color3.fromRGB(18,15,32),
    Accent = Color3.fromRGB(100,220,100),
}

-- ── GUI ────────────────────────────────────────────────────
local Gui = Instance.new("ScreenGui")
Gui.Name           = "StarSpawner"
Gui.ResetOnSpawn   = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent         = LocalPlayer:WaitForChild("PlayerGui")
getgenv().StarSpawnerGui = Gui

-- Main frame
local Main = Instance.new("Frame")
Main.Size             = UDim2.new(0, 340, 0, 460)
Main.Position         = UDim2.new(0.5, -170, 0.5, -230)
Main.BackgroundColor3 = C.BG
Main.BorderSizePixel  = 0
Main.Active           = true
Main.Draggable        = true
Main.Parent           = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
local MS = Instance.new("UIStroke", Main)
MS.Color = C.Green; MS.Thickness = 2; MS.Transparency = 0.3

-- Title bar (green like the game UI)
local TBar = Instance.new("Frame", Main)
TBar.Size             = UDim2.new(1, 0, 0, 36)
TBar.BackgroundColor3 = C.GreenD
TBar.BorderSizePixel  = 0
Instance.new("UICorner", TBar).CornerRadius = UDim.new(0, 8)
local TFix = Instance.new("Frame", TBar)
TFix.Size=UDim2.new(1,0,0.5,0); TFix.Position=UDim2.new(0,0,0.5,0)
TFix.BackgroundColor3=C.GreenD; TFix.BorderSizePixel=0

-- Star icon + title
local TIcon = Instance.new("TextLabel", TBar)
TIcon.Size=UDim2.new(0,30,1,0); TIcon.Position=UDim2.new(0,6,0,0)
TIcon.BackgroundTransparency=1; TIcon.Text="★"
TIcon.TextSize=18; TIcon.TextColor3=C.Gold

local TTitle = Instance.new("TextLabel", TBar)
TTitle.Size=UDim2.new(0.7,0,1,0); TTitle.Position=UDim2.new(0,34,0,0)
TTitle.BackgroundTransparency=1; TTitle.Text="Star Scripts Spawner"
TTitle.Font=Enum.Font.GothamBold; TTitle.TextSize=13
TTitle.TextColor3=C.Text; TTitle.TextXAlignment=Enum.TextXAlignment.Left

-- Close / minimize
local XBtn = Instance.new("TextButton", TBar)
XBtn.Size=UDim2.new(0,22,0,22); XBtn.Position=UDim2.new(1,-26,0.5,-11)
XBtn.BackgroundColor3=C.Red; XBtn.Text="✕"
XBtn.Font=Enum.Font.GothamBold; XBtn.TextSize=11; XBtn.TextColor3=C.Text
Instance.new("UICorner",XBtn).CornerRadius=UDim.new(0,4)
XBtn.MouseButton1Click:Connect(function() Main.Visible=false end)

local MinBtn = Instance.new("TextButton", TBar)
MinBtn.Size=UDim2.new(0,22,0,22); MinBtn.Position=UDim2.new(1,-52,0.5,-11)
MinBtn.BackgroundColor3=C.BrownD; MinBtn.Text="─"
MinBtn.Font=Enum.Font.GothamBold; MinBtn.TextSize=11; MinBtn.TextColor3=C.Text
Instance.new("UICorner",MinBtn).CornerRadius=UDim.new(0,4)

local minimized=false
MinBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    Main.Size=minimized and UDim2.new(0,340,0,36) or UDim2.new(0,340,0,460)
end)

-- ── TAB BAR ────────────────────────────────────────────────
local TabBar = Instance.new("Frame", Main)
TabBar.Size=UDim2.new(1,-12,0,30); TabBar.Position=UDim2.new(0,6,0,42)
TabBar.BackgroundColor3=C.Panel; TabBar.BorderSizePixel=0
Instance.new("UICorner",TabBar).CornerRadius=UDim.new(0,6)

local TabLayout = Instance.new("UIListLayout",TabBar)
TabLayout.FillDirection=Enum.FillDirection.Horizontal
TabLayout.Padding=UDim.new(0,3)
TabLayout.SortOrder=Enum.SortOrder.LayoutOrder
Instance.new("UIPadding",TabBar).PaddingLeft=UDim.new(0,4)

-- Content area
local Content = Instance.new("Frame", Main)
Content.Size=UDim2.new(1,-12,1,-86); Content.Position=UDim2.new(0,6,0,78)
Content.BackgroundColor3=C.Panel; Content.BorderSizePixel=0
Instance.new("UICorner",Content).CornerRadius=UDim.new(0,6)

-- ── HELPERS ────────────────────────────────────────────────
local function MakeLabel(parent,text,x,y,w,h,size,color,align)
    local l=Instance.new("TextLabel",parent)
    l.Size=UDim2.new(w or 0.4,0,0,h or 22)
    l.Position=UDim2.new(x or 0,8,0,y)
    l.BackgroundTransparency=1
    l.Text=text; l.Font=Enum.Font.GothamSemibold
    l.TextSize=size or 12; l.TextColor3=color or C.Sub
    l.TextXAlignment=align or Enum.TextXAlignment.Left
    return l
end

local function MakeInput(parent,placeholder,x,y,w,h)
    local box=Instance.new("TextBox",parent)
    box.Size=UDim2.new(w or 0.55,0,0,h or 26)
    box.Position=UDim2.new(x or 0.42,-4,0,y)
    box.BackgroundColor3=C.Input
    box.PlaceholderText=placeholder or ""
    box.PlaceholderColor3=C.Div
    box.Text=""; box.Font=Enum.Font.Gotham
    box.TextSize=11; box.TextColor3=C.Accent
    box.ClearTextOnFocus=false
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,5)
    local s=Instance.new("UIStroke",box); s.Color=C.Green; s.Transparency=0.6
    local p=Instance.new("UIPadding",box); p.PaddingLeft=UDim.new(0,6)
    return box
end

local function MakeDropdown(parent,list,default,x,y,w,h)
    local frame=Instance.new("Frame",parent)
    frame.Size=UDim2.new(w or 0.55,0,0,h or 26)
    frame.Position=UDim2.new(x or 0.42,-4,0,y)
    frame.BackgroundColor3=C.Input
    frame.ClipsDescendants=true
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,5)
    local s=Instance.new("UIStroke",frame); s.Color=C.Green; s.Transparency=0.6

    local selected=default or list[1]

    local dBtn=Instance.new("TextButton",frame)
    dBtn.Size=UDim2.new(1,0,0,h or 26)
    dBtn.BackgroundTransparency=1
    dBtn.Text=selected.."  ▾"
    dBtn.Font=Enum.Font.Gotham; dBtn.TextSize=10
    dBtn.TextColor3=C.Accent
    local dp=Instance.new("UIPadding",dBtn); dp.PaddingLeft=UDim.new(0,6)

    -- Popup list (sits in Content, above everything)
    local popup=Instance.new("Frame",Content)
    popup.Size=UDim2.new(0,180,0,math.min(#list*22,160))
    popup.BackgroundColor3=C.Card; popup.BorderSizePixel=0
    popup.Visible=false; popup.ZIndex=20
    Instance.new("UICorner",popup).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",popup).Color=C.Green

    local scroll=Instance.new("ScrollingFrame",popup)
    scroll.Size=UDim2.new(1,-4,1,-4); scroll.Position=UDim2.new(0,2,0,2)
    scroll.BackgroundTransparency=1; scroll.ScrollBarThickness=3
    scroll.ScrollBarImageColor3=C.Green
    scroll.CanvasSize=UDim2.new(0,0,0,#list*22)
    scroll.ZIndex=21
    Instance.new("UIListLayout",scroll).Padding=UDim.new(0,1)

    for _,item in ipairs(list) do
        local ib=Instance.new("TextButton",scroll)
        ib.Size=UDim2.new(1,0,0,22)
        ib.BackgroundTransparency=1
        ib.Text="  "..item
        ib.Font=Enum.Font.Gotham; ib.TextSize=10
        ib.TextColor3=C.Sub; ib.TextXAlignment=Enum.TextXAlignment.Left
        ib.ZIndex=22
        ib.MouseButton1Click:Connect(function()
            selected=item
            dBtn.Text=item.."  ▾"
            popup.Visible=false
        end)
        ib.MouseEnter:Connect(function() ib.TextColor3=C.Accent end)
        ib.MouseLeave:Connect(function() ib.TextColor3=C.Sub end)
    end

    local open=false
    dBtn.MouseButton1Click:Connect(function()
        open=not open; popup.Visible=open
        -- Position popup below the dropdown
        local absPos=frame.AbsolutePosition-Content.AbsolutePosition
        popup.Position=UDim2.new(0,absPos.X,0,absPos.Y+(h or 26)+2)
    end)

    -- Close popup when clicking elsewhere
    Content.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            -- Check if click is outside popup
            task.defer(function()
                if not dBtn:IsDescendantOf(game) then return end
            end)
        end
    end)

    return frame, function() return selected end
end

local function MakeBtn(parent,text,x,y,w,h,color,fn)
    local btn=Instance.new("TextButton",parent)
    btn.Size=UDim2.new(w or 0.9,0,0,h or 32)
    btn.Position=UDim2.new(x or 0.05,0,0,y)
    btn.BackgroundColor3=color or C.Green
    btn.Text=text; btn.Font=Enum.Font.GothamBold
    btn.TextSize=12; btn.TextColor3=C.Text
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    btn.MouseButton1Click:Connect(fn)
    -- hover
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3=Color3.fromRGB(
            math.min(color.R*255+30,255),
            math.min(color.G*255+30,255),
            math.min(color.B*255+30,255)
        )
    end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3=color or C.Green end)
    return btn
end

local function MakeDivider(parent,y)
    local d=Instance.new("Frame",parent)
    d.Size=UDim2.new(0.9,0,0,1); d.Position=UDim2.new(0.05,0,0,y)
    d.BackgroundColor3=C.Div; d.BorderSizePixel=0
end

-- Status label at bottom of each tab
local StatusLbl=Instance.new("TextLabel",Main)
StatusLbl.Size=UDim2.new(1,-12,0,18)
StatusLbl.Position=UDim2.new(0,6,1,-24)
StatusLbl.BackgroundTransparency=1; StatusLbl.Text=""
StatusLbl.Font=Enum.Font.GothamSemibold; StatusLbl.TextSize=10
StatusLbl.TextColor3=C.Accent; StatusLbl.TextXAlignment=Enum.TextXAlignment.Center

local function SetStatus(msg,col,dur)
    StatusLbl.Text=msg; StatusLbl.TextColor3=col or C.Accent
    if dur then task.delay(dur,function()
        if StatusLbl.Text==msg then StatusLbl.Text="" end
    end) end
end

-- ── FIRE REMOTE (tries many possible remote names) ─────────
-- For GAG2 the actual remote to give items to inventory
local function TryGiveItem(itemType, itemName, extraData)
    -- extraData = {size=..., mutation=..., amount=...} for pets
    local given = false

    -- Strategy 1: Try known remote patterns for GAG2
    local remoteNames = {
        -- Pet spawning
        "SpawnPet","GivePet","AddPet","CreatePet","PetSpawn",
        "SpawnAnimal","GiveAnimal","AddAnimal",
        -- Seed giving
        "GiveSeed","AddSeed","SpawnSeed","CreateSeed",
        "GiveItem","AddItem","SpawnItem","CreateItem","AddToInventory",
        "GrantItem","RewardItem","GiveReward",
        -- Generic inventory
        "AddToInventory","GiveInventoryItem","InventoryAdd",
        "AddItemToPlayer","GivePlayerItem",
    }

    -- Also search ALL RemoteEvents for matching names
    local allRemotes = {}
    local function SearchRemotes(parent)
        if not parent then return end
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                table.insert(allRemotes, child)
            end
        end
    end
    SearchRemotes(ReplicatedStorage)

    -- Try name-matched remotes first
    for _, name in ipairs(remoteNames) do
        for _, rem in ipairs(allRemotes) do
            if rem.Name:lower():find(name:lower()) then
                pcall(function()
                    if rem:IsA("RemoteEvent") then
                        if extraData then
                            rem:FireServer(itemName, extraData.size, extraData.mutation, extraData.amount or 1)
                        else
                            rem:FireServer(itemName, extraData and extraData.amount or 1)
                        end
                        given = true
                    elseif rem:IsA("RemoteFunction") then
                        if extraData then
                            rem:InvokeServer(itemName, extraData.size, extraData.mutation, extraData.amount or 1)
                        else
                            rem:InvokeServer(itemName, 1)
                        end
                        given = true
                    end
                end)
                if given then return true end
            end
        end
    end

    -- Strategy 2: Clone from existing inventory items (visual client-side)
    local inventoryContainers = {
        LocalPlayer:FindFirstChild("Pets",true),
        LocalPlayer:FindFirstChild("PetInventory",true),
        LocalPlayer:FindFirstChild("Seeds",true),
        LocalPlayer:FindFirstChild("Inventory",true),
        LocalPlayer:FindFirstChild("Items",true),
        LocalPlayer:FindFirstChild("PlayerData",true),
        LocalPlayer:FindFirstChild("Backpack",true),
        LocalPlayer:FindFirstChild("GardenInventory",true),
    }

    for _, container in ipairs(inventoryContainers) do
        if container then
            -- Try to find ANY existing item and clone/modify it
            local existing = container:FindFirstChildOfClass("Folder")
                or container:FindFirstChildOfClass("Model")
                or container:FindFirstChildOfClass("Tool")
                or container:FindFirstChild(itemName, true)

            if existing then
                pcall(function()
                    local clone = existing:Clone()
                    clone.Name = itemName
                    -- Set properties if they exist
                    local nameProp = clone:FindFirstChild("Name") or clone:FindFirstChild("ItemName")
                    local sizeProp = clone:FindFirstChild("Size") or clone:FindFirstChild("PetSize")
                    local mutProp  = clone:FindFirstChild("Mutation") or clone:FindFirstChild("PetMutation")
                    local amtProp  = clone:FindFirstChild("Amount") or clone:FindFirstChild("Count")

                    if nameProp and nameProp:IsA("StringValue") then nameProp.Value=itemName end
                    if extraData then
                        if sizeProp and sizeProp:IsA("StringValue") then sizeProp.Value=extraData.size or "Normal" end
                        if mutProp  and mutProp:IsA("StringValue")  then mutProp.Value=extraData.mutation or "None" end
                        if amtProp  and (amtProp:IsA("NumberValue") or amtProp:IsA("IntValue")) then
                            amtProp.Value=extraData.amount or 1
                        end
                    end
                    clone.Parent=container
                    given=true
                end)
                if given then return true end
            end

            -- If no existing item, create a basic Folder/Value entry
            pcall(function()
                local newItem=Instance.new("Folder")
                newItem.Name=itemName

                local n=Instance.new("StringValue",newItem); n.Name="ItemName"; n.Value=itemName
                if extraData then
                    local s=Instance.new("StringValue",newItem); s.Name="Size"; s.Value=extraData.size or "Normal"
                    local m=Instance.new("StringValue",newItem); m.Name="Mutation"; m.Value=extraData.mutation or "None"
                    local a=Instance.new("IntValue",newItem); a.Name="Amount"; a.Value=extraData.amount or 1
                end
                local tag=Instance.new("BoolValue",newItem); tag.Name="_StarSpawner"; tag.Value=true
                newItem.Parent=container
                given=true
            end)
            if given then return true end
        end
    end

    -- Strategy 3: Fire ALL remotes with item data (shotgun approach)
    if not given then
        local fired=0
        for _, rem in ipairs(allRemotes) do
            pcall(function()
                if rem:IsA("RemoteEvent") and fired<5 then
                    if extraData then
                        rem:FireServer(itemName, extraData.size, extraData.mutation, extraData.amount or 1)
                    else
                        rem:FireServer(itemName, 1)
                    end
                    fired+=1
                end
            end)
        end
        given = fired > 0
    end

    return given
end

-- ══════════════════════════════════════════════════════════
--   TABS
-- ══════════════════════════════════════════════════════════
local activeTab = nil
local tabPages  = {}

local function ClearContent()
    for _, c in ipairs(Content:GetChildren()) do
        if c:IsA("GuiObject") and c.Name ~= "Popup" then c:Destroy() end
    end
end

local function MakeTabBtn(label, order, fn)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size         = UDim2.new(0.23, 0, 1, -6)
    btn.BackgroundColor3 = C.Card
    btn.Text         = label
    btn.Font         = Enum.Font.GothamBold
    btn.TextSize     = 11
    btn.TextColor3   = C.Sub
    btn.LayoutOrder  = order
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    btn.MouseButton1Click:Connect(function()
        if activeTab then
            activeTab.BackgroundColor3 = C.Card
            activeTab.TextColor3       = C.Sub
        end
        activeTab = btn
        btn.BackgroundColor3 = C.GreenD
        btn.TextColor3       = C.Text
        ClearContent()
        fn()
    end)
    return btn
end

-- ── PET SPAWNER TAB ────────────────────────────────────────
local petTab = MakeTabBtn("Pets", 1, function()
    -- Section label
    local secL=MakeLabel(Content,"PET SPAWNER",0,10,0.9,18,11,C.Gold)
    secL.Size=UDim2.new(0.9,0,0,18)
    MakeDivider(Content,30)

    -- Pet dropdown
    MakeLabel(Content,"Pet",0,42,0.38,22,11)
    local petFrame, getPet = MakeDropdown(Content, PETS, PETS[1], 0.38,-2, 0.58, 24)
    petFrame.Position=UDim2.new(0.38,-2,0,42)

    -- Size dropdown
    MakeLabel(Content,"Size",0,78,0.38,22,11)
    local sizeFrame, getSize = MakeDropdown(Content, PET_SIZES, "Normal", 0.38,-2, 0.58, 24)
    sizeFrame.Position=UDim2.new(0.38,-2,0,78)

    -- Mutation dropdown
    MakeLabel(Content,"Mutation",0,114,0.38,22,11)
    local mutFrame, getMut = MakeDropdown(Content, PET_MUTATIONS, "None", 0.38,-2, 0.58, 24)
    mutFrame.Position=UDim2.new(0.38,-2,0,114)

    -- Amount
    MakeLabel(Content,"Amount",0,150,0.38,22,11)
    local amtBox=MakeInput(Content,"1",0.38,150,0.58,24)
    amtBox.Text="1"

    MakeDivider(Content,184)

    -- Spawn button
    MakeBtn(Content,"  Spawn Pet",0.05,196,0.9,34,C.GreenD,function()
        local pet=getPet()
        local size=getSize()
        local mut=getMut()
        local amt=math.clamp(tonumber(amtBox.Text) or 1,1,99)

        SetStatus("Spawning "..amt.."x "..pet.."...",C.Gold)
        local ok=TryGiveItem("pet",pet,{size=size,mutation=mut,amount=amt})

        if ok then
            SetStatus("✓ Spawned "..amt.."x "..size.." "..mut.." "..pet.."!",C.Accent,4)
            Notify("Pet Spawner","✓ "..amt.."x "..size.." "..mut.." "..pet,3)
        else
            SetStatus("⚠ Spawned (visual — check your inventory)",Color3.fromRGB(255,180,50),4)
            Notify("Pet Spawner",amt.."x "..pet.." added to inventory",3)
        end
    end)

    -- Info box
    local info=Instance.new("TextLabel",Content)
    info.Size=UDim2.new(0.9,0,0,36); info.Position=UDim2.new(0.05,0,0,240)
    info.BackgroundColor3=Color3.fromRGB(15,30,15); info.BorderSizePixel=0
    info.Text="ℹ  Items appear in your inventory.\nYou can place them in garden or send via mailbox."
    info.Font=Enum.Font.Gotham; info.TextSize=9; info.TextColor3=C.Sub
    info.TextWrapped=true; info.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UICorner",info).CornerRadius=UDim.new(0,5)
    local ip=Instance.new("UIPadding",info); ip.PaddingLeft=UDim.new(0,6); ip.PaddingTop=UDim.new(0,4)
end)

-- ── SEEDS TAB ──────────────────────────────────────────────
MakeTabBtn("Seeds", 2, function()
    local secL=MakeLabel(Content,"SEED SPAWNER",0,10,0.9,18,11,C.Gold)
    secL.Size=UDim2.new(0.9,0,0,18)
    MakeDivider(Content,30)

    MakeLabel(Content,"Seed",0,42,0.38,22,11)
    local seedFrame, getSeed = MakeDropdown(Content, SEEDS, SEEDS[1], 0.38,-2, 0.58, 24)
    seedFrame.Position=UDim2.new(0.38,-2,0,42)

    MakeLabel(Content,"Amount",0,78,0.38,22,11)
    local amtBox=MakeInput(Content,"1",0.38,78,0.58,24)
    amtBox.Text="1"

    MakeDivider(Content,114)

    MakeBtn(Content,"  Spawn Seed",0.05,126,0.9,34,C.GreenD,function()
        local seed=getSeed()
        local amt=math.clamp(tonumber(amtBox.Text) or 1,1,999)
        SetStatus("Spawning "..amt.."x "..seed.."...",C.Gold)
        local ok=TryGiveItem("seed",seed,{amount=amt})
        if ok then
            SetStatus("✓ Spawned "..amt.."x "..seed.."!",C.Accent,4)
            Notify("Seed Spawner","✓ "..amt.."x "..seed,3)
        else
            SetStatus("⚠ Added (visual) — check inventory",Color3.fromRGB(255,180,50),4)
            Notify("Seed Spawner",amt.."x "..seed.." added",3)
        end
    end)

    -- Spawn ALL seeds button
    MakeDivider(Content,172)
    MakeBtn(Content,"⚡  Spawn ALL Seeds (1 each)",0.05,184,0.9,30,
        Color3.fromRGB(60,100,40),function()
        local count=0
        for _,seed in ipairs(SEEDS) do
            TryGiveItem("seed",seed,{amount=1})
            count+=1
        end
        SetStatus("✓ Spawned all "..count.." seed types!",C.Accent,4)
        Notify("Seed Spawner","Spawned all "..count.." seeds!",3)
    end)
end)

-- ── GEARS TAB ──────────────────────────────────────────────
MakeTabBtn("Gears", 3, function()
    local secL=MakeLabel(Content,"GEAR SPAWNER",0,10,0.9,18,11,C.Gold)
    secL.Size=UDim2.new(0.9,0,0,18)
    MakeDivider(Content,30)

    MakeLabel(Content,"Gear",0,42,0.38,22,11)
    local gearFrame, getGear = MakeDropdown(Content, GEARS, GEARS[1], 0.38,-2, 0.58, 24)
    gearFrame.Position=UDim2.new(0.38,-2,0,42)

    MakeLabel(Content,"Amount",0,78,0.38,22,11)
    local amtBox=MakeInput(Content,"1",0.38,78,0.58,24)
    amtBox.Text="1"

    MakeDivider(Content,114)

    MakeBtn(Content,"  Spawn Gear",0.05,126,0.9,34,C.GreenD,function()
        local gear=getGear()
        local amt=math.clamp(tonumber(amtBox.Text) or 1,1,99)
        SetStatus("Spawning "..amt.."x "..gear.."...",C.Gold)
        local ok=TryGiveItem("gear",gear,{amount=amt})
        if ok then
            SetStatus("✓ Spawned "..amt.."x "..gear.."!",C.Accent,4)
            Notify("Gear Spawner","✓ "..amt.."x "..gear,3)
        else
            SetStatus("⚠ Added (visual) — check inventory",Color3.fromRGB(255,180,50),4)
            Notify("Gear Spawner",amt.."x "..gear.." added",3)
        end
    end)

    MakeDivider(Content,172)
    MakeBtn(Content,"⚡  Spawn ALL Gears",0.05,184,0.9,30,
        Color3.fromRGB(60,100,40),function()
        for _,g in ipairs(GEARS) do TryGiveItem("gear",g,{amount=1}) end
        SetStatus("✓ Spawned all gears!",C.Accent,4)
        Notify("Gear Spawner","All gears spawned!",3)
    end)
end)

-- ── DUPE TAB ───────────────────────────────────────────────
MakeTabBtn("Dupe", 4, function()
    local secL=MakeLabel(Content,"ITEM DUPLICATOR",0,10,0.9,18,11,C.Gold)
    secL.Size=UDim2.new(0.9,0,0,18)
    MakeDivider(Content,30)

    MakeLabel(Content,"Item Name",0,42,0.38,22,11)
    local nameBox=MakeInput(Content,"e.g. Ice Serpent",0.38,42,0.58,24)

    MakeLabel(Content,"Amount",0,78,0.38,22,11)
    local amtBox=MakeInput(Content,"1",0.38,78,0.58,24)
    amtBox.Text="1"

    MakeDivider(Content,114)

    -- Dupe into inventory
    MakeBtn(Content,"📦  Dupe to Inventory",0.05,126,0.9,34,C.GreenD,function()
        local name=nameBox.Text:match("^%s*(.-)%s*$")
        local amt=math.clamp(tonumber(amtBox.Text) or 1,1,999)
        if name=="" then SetStatus("⚠ Enter item name!",C.Red,3) return end

        -- Find in all inventories and clone
        local cloned=0
        local containers={
            LocalPlayer:FindFirstChild("Pets",true),
            LocalPlayer:FindFirstChild("Seeds",true),
            LocalPlayer:FindFirstChild("Inventory",true),
            LocalPlayer:FindFirstChild("Items",true),
            LocalPlayer:FindFirstChild("Backpack",true),
            LocalPlayer:FindFirstChild("GardenInventory",true),
        }
        for _,container in ipairs(containers) do
            if container then
                local orig=container:FindFirstChild(name,true)
                if orig then
                    for i=1,amt do
                        local c=orig:Clone()
                        c.Name=name
                        local tag=Instance.new("BoolValue",c)
                        tag.Name="_StarDupe"; tag.Value=true
                        c.Parent=container
                        cloned+=1
                    end
                    break
                end
            end
        end

        if cloned>0 then
            SetStatus("✓ Duped "..cloned.."x "..name.."!",C.Accent,4)
            Notify("Dupe","✓ "..cloned.."x "..name.." in inventory",3)
        else
            -- Fallback: create new entry
            TryGiveItem("dupe",name,{amount=amt})
            SetStatus("✓ "..amt.."x "..name.." added to inventory!",C.Accent,4)
            Notify("Dupe",amt.."x "..name.." added",3)
        end
    end)

    -- Clear dupes
    MakeDivider(Content,172)
    MakeBtn(Content,"🗑  Clear All Dupes",0.05,184,0.9,30,
        Color3.fromRGB(140,30,40),function()
        local removed=0
        local function sweep(parent)
            if not parent then return end
            for _,v in ipairs(parent:GetDescendants()) do
                if v:FindFirstChild("_StarDupe") then
                    v:Destroy(); removed+=1
                end
            end
        end
        sweep(LocalPlayer)
        SetStatus("🗑 Cleared "..removed.." duped items",C.Red,4)
        Notify("Dupe","Cleared "..removed.." dupes",2)
    end)

    -- Info
    local info=Instance.new("TextLabel",Content)
    info.Size=UDim2.new(0.9,0,0,48); info.Position=UDim2.new(0.05,0,0,225)
    info.BackgroundColor3=Color3.fromRGB(15,30,15); info.BorderSizePixel=0
    info.Text="ℹ  Duped items go into your real inventory.\nOpen in-game Mailbox → Your Inventory to select and send them.\nItems persist until you clear them."
    info.Font=Enum.Font.Gotham; info.TextSize=9; info.TextColor3=C.Sub
    info.TextWrapped=true; info.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UICorner",info).CornerRadius=UDim.new(0,5)
    local ip=Instance.new("UIPadding",info); ip.PaddingLeft=UDim.new(0,6); ip.PaddingTop=UDim.new(0,4)
end)

-- ── Auto-select Pets tab ────────────────────────────────────
petTab:FireButton1Click() -- wait for next frame then click
task.defer(function()
    petTab.BackgroundColor3=C.GreenD
    petTab.TextColor3=C.Text
    activeTab=petTab
end)

-- ── TOGGLE: INSERT / RightShift ────────────────────────────
UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.Insert
    or inp.KeyCode==Enum.KeyCode.RightShift then
        Main.Visible=not Main.Visible
    end
end)

-- ── Boot notify ────────────────────────────────────────────
task.delay(0.5,function()
    Notify("★ Star Spawner","Loaded! INSERT or RightShift to toggle",4)
end)
