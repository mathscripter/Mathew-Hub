--[[
    HANS HUB | MM2 | v4.0
    NEW: Permanent role marking, Auto Kill All (murderer), 
         Skin as fake inventory tool (visual, disappears on unequip),
         Settings save/load via writefile
    FIX: Skin injector, role detection, sheriff auto shoot
    Toggle: INSERT
]]

-- Prevent duplicate
if getgenv().HansHubLoaded then
    if getgenv().HansHubGui then getgenv().HansHubGui:Destroy() end
end
getgenv().HansHubLoaded = true

-- ============================================================
--  SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local StarterGui       = game:GetService("StarterGui")
local HttpService      = game:GetService("HttpService")

local Camera      = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ============================================================
--  SETTINGS (with save/load)
-- ============================================================
local SAVE_FILE = "HansHub_Settings.json"

local DefaultSettings = {
    Role = {
        AutoStab     = false, StabRange  = 25,
        AutoShoot    = false, ShootRange = 80,
        SilentAim    = false, FOV        = 120,
        AutoKillAll  = false,  -- tp to each player and kill then tp to safe spot
        SafeSpotY    = 500,    -- Y height to tp to after killing all
    },
    Util = {
        AutoCollect  = false, CollectRange = 50,
        WalkSpeed    = false, Speed        = 32,
        JumpPower    = false, Power        = 60,
        Reach        = false, ReachRange   = 20,
        NoClip       = false,
        XRay         = false, XRayTrans    = 0.4,
    },
    ESP = {
        Enabled      = false,
        ShowMurderer = true,
        ShowSheriff  = true,
        ShowOthers   = true,
        Box          = true,
        Name         = true,
        Distance     = true,
    },
    Skin = {
        KnifeEnabled = false, KnifeSkin = "Default",
        GunEnabled   = false, GunSkin   = "Default",
    },
}

-- Deep copy
local function DeepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = type(v) == "table" and DeepCopy(v) or v
    end
    return copy
end

local S = DeepCopy(DefaultSettings)

-- Save settings
local function SaveSettings()
    pcall(function()
        writefile(SAVE_FILE, HttpService:JSONEncode(S))
    end)
end

-- Load settings
local function LoadSettings()
    pcall(function()
        if isfile(SAVE_FILE) then
            local data = HttpService:JSONDecode(readfile(SAVE_FILE))
            -- Merge loaded into S (preserve structure)
            for cat, vals in pairs(data) do
                if S[cat] then
                    for k, v in pairs(vals) do
                        S[cat][k] = v
                    end
                end
            end
        end
    end)
end

LoadSettings()

-- ============================================================
--  PERMANENT ROLE MARKERS  (survive round resets)
-- ============================================================
-- { [userId] = "Murderer" | "Sheriff" }
local PermanentRoles = {}

-- ============================================================
--  SKIN LISTS
-- ============================================================
local KNIFE_SKINS = {
    "Default","Rainbow","Gold","Neon Green","Void Black",
    "Crimson Red","Ice Blue","Sakura Pink","Toxic","Obsidian",
    "Electric Purple","Chroma","Laser","Galaxy","Tiger",
    "Dragon","Coral","Midnight","Sunrise","Arctic",
}
local GUN_SKINS = {
    "Default","Rainbow","Gold","Neon Green","Void Black",
    "Crimson Red","Ice Blue","Sakura Pink","Toxic","Obsidian",
    "Electric Purple","Chroma","Laser","Galaxy","Tiger",
    "Dragon","Coral","Midnight","Sunrise","Arctic",
}
local SKIN_COLORS = {
    ["Default"]         = Color3.fromRGB(180,180,180),
    ["Rainbow"]         = Color3.fromRGB(255,100,200),
    ["Gold"]            = Color3.fromRGB(255,200,50),
    ["Neon Green"]      = Color3.fromRGB(0,255,100),
    ["Void Black"]      = Color3.fromRGB(15,15,15),
    ["Crimson Red"]     = Color3.fromRGB(200,20,40),
    ["Ice Blue"]        = Color3.fromRGB(130,210,255),
    ["Sakura Pink"]     = Color3.fromRGB(255,160,190),
    ["Toxic"]           = Color3.fromRGB(100,255,50),
    ["Obsidian"]        = Color3.fromRGB(30,25,50),
    ["Electric Purple"] = Color3.fromRGB(160,50,255),
    ["Chroma"]          = Color3.fromRGB(255,50,255),
    ["Laser"]           = Color3.fromRGB(255,255,0),
    ["Galaxy"]          = Color3.fromRGB(80,0,120),
    ["Tiger"]           = Color3.fromRGB(255,140,0),
    ["Dragon"]          = Color3.fromRGB(200,30,10),
    ["Coral"]           = Color3.fromRGB(255,127,80),
    ["Midnight"]        = Color3.fromRGB(20,20,60),
    ["Sunrise"]         = Color3.fromRGB(255,180,60),
    ["Arctic"]          = Color3.fromRGB(200,240,255),
}

local rainbowHue = 0

-- ============================================================
--  STATE
-- ============================================================
local ESPObjects           = {}
local OriginalTransparency = {}
local XRayCache            = {}
local XRayCacheTimer       = 0
local XRayCacheInterval    = 3
local heartbeatStep        = 0
local ActiveCatBtn         = nil
local ActiveCatNameLbl     = nil
local CurrentCatKey        = "Role"

-- Fake skin tools (visual only — parented to character locally)
local FakeSkinTools = {}   -- { toolName = fakeToolInstance }
local OriginalSkinData = {} -- [part] = {Color, Material}

-- Auto kill state
local killingAll = false
local safeSpot   = nil  -- Vector3, set when kill-all starts

-- ============================================================
--  NOTIFY HELPER
-- ============================================================
local function Notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=dur or 3})
    end)
end

-- ============================================================
--  THEME
-- ============================================================
local T = {
    BG      = Color3.fromRGB(12, 12, 20),
    Sidebar = Color3.fromRGB(20, 20, 34),
    Panel   = Color3.fromRGB(26, 26, 42),
    Card    = Color3.fromRGB(32, 32, 52),
    Accent  = Color3.fromRGB(75,160,255),
    ON      = Color3.fromRGB(70,220,120),
    OFF     = Color3.fromRGB(220,70,90),
    Text    = Color3.new(1,1,1),
    Sub     = Color3.fromRGB(170,170,200),
    Divider = Color3.fromRGB(50,50,80),
    Gold    = Color3.fromRGB(255,200,50),
    Red     = Color3.fromRGB(255,60,60),
}

-- ============================================================
--  GUI ROOT
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HansHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
getgenv().HansHubGui = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 510, 0, 475)
MainFrame.Position = UDim2.new(0.05, 0, 0.08, 0)
MainFrame.BackgroundColor3 = T.BG
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MStroke = Instance.new("UIStroke", MainFrame)
MStroke.Color = T.Accent
MStroke.Thickness = 1.5
MStroke.Transparency = 0.35

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = T.Sidebar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)
local TBFix = Instance.new("Frame")
TBFix.Size = UDim2.new(1,0,0.5,0)
TBFix.Position = UDim2.new(0,0,0.5,0)
TBFix.BackgroundColor3 = T.Sidebar
TBFix.BorderSizePixel = 0
TBFix.Parent = TitleBar

local TLAcc = Instance.new("Frame")
TLAcc.Size = UDim2.new(0,4,1,-12)
TLAcc.Position = UDim2.new(0,10,0,6)
TLAcc.BackgroundColor3 = T.Accent
TLAcc.BorderSizePixel = 0
TLAcc.Parent = TitleBar
Instance.new("UICorner", TLAcc).CornerRadius = UDim.new(0,3)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(0.72,0,1,0)
TitleLbl.Position = UDim2.new(0,22,0,0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "✨  HANS HUB  |  MM2"
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 14
TitleLbl.TextColor3 = T.Accent
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = TitleBar

local VerLbl = Instance.new("TextLabel")
VerLbl.Size = UDim2.new(0,68,0,18)
VerLbl.Position = UDim2.new(1,-112,0.5,-9)
VerLbl.BackgroundColor3 = Color3.fromRGB(25,55,110)
VerLbl.Text = "v4.0 FINAL"
VerLbl.Font = Enum.Font.GothamBold
VerLbl.TextSize = 10
VerLbl.TextColor3 = T.Accent
VerLbl.Parent = TitleBar
Instance.new("UICorner", VerLbl).CornerRadius = UDim.new(0,4)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,28,0,28)
CloseBtn.Position = UDim2.new(1,-36,0.5,-14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180,40,60)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.TextColor3 = T.Text
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,6)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0,148,1,-50)
Sidebar.Position = UDim2.new(0,6,0,46)
Sidebar.BackgroundColor3 = T.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0,8)

local SideList = Instance.new("ScrollingFrame")
SideList.Size = UDim2.new(1,-6,1,-10)
SideList.Position = UDim2.new(0,3,0,5)
SideList.BackgroundTransparency = 1
SideList.ScrollBarThickness = 3
SideList.ScrollBarImageColor3 = T.Accent
SideList.CanvasSize = UDim2.new(0,0,0,0)
SideList.AutomaticCanvasSize = Enum.AutomaticSize.Y
SideList.Parent = Sidebar
local SideLayout = Instance.new("UIListLayout", SideList)
SideLayout.Padding = UDim.new(0,5)
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", SideList).PaddingTop = UDim.new(0,5)

-- Right panel
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(1,-163,1,-50)
RightPanel.Position = UDim2.new(0,159,0,46)
RightPanel.BackgroundColor3 = T.Panel
RightPanel.BorderSizePixel = 0
RightPanel.Parent = MainFrame
Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0,8)

local PanelScroll = Instance.new("ScrollingFrame")
PanelScroll.Size = UDim2.new(1,-10,1,-10)
PanelScroll.Position = UDim2.new(0,5,0,5)
PanelScroll.BackgroundTransparency = 1
PanelScroll.ScrollBarThickness = 4
PanelScroll.ScrollBarImageColor3 = T.Accent
PanelScroll.CanvasSize = UDim2.new(0,0,0,0)
PanelScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PanelScroll.Parent = RightPanel
local PanelLayout = Instance.new("UIListLayout", PanelScroll)
PanelLayout.Padding = UDim.new(0,6)
PanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
local PPad = Instance.new("UIPadding", PanelScroll)
PPad.PaddingTop = UDim.new(0,6)
PPad.PaddingRight = UDim.new(0,4)

-- ============================================================
--  PANEL WIDGET HELPERS
-- ============================================================
local panelOrder = 0
local function NextOrder() panelOrder += 1 return panelOrder end

local function ClearPanel()
    for _, c in ipairs(PanelScroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    panelOrder = 0
end

local function MakeSection(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,22)
    l.BackgroundTransparency = 1
    l.Text = "  "..text
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextColor3 = T.Accent
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = NextOrder()
    l.Parent = PanelScroll
    local div = Instance.new("Frame")
    div.Size = UDim2.new(1,0,0,1)
    div.BackgroundColor3 = T.Divider
    div.BorderSizePixel = 0
    div.LayoutOrder = NextOrder()
    div.Parent = PanelScroll
end

local function MakeRow(h)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,h or 36)
    f.BackgroundColor3 = T.Card
    f.BorderSizePixel = 0
    f.LayoutOrder = NextOrder()
    f.Parent = PanelScroll
    Instance.new("UICorner",f).CornerRadius = UDim.new(0,6)
    return f
end

-- CreateToggle: returns setter function
local function CreateToggle(label, initVal, onChange)
    local f = MakeRow(36)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.72,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,50,0,24)
    btn.Position = UDim2.new(1,-58,0.5,-12)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = T.Text
    btn.Parent = f
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,5)

    local state = initVal or false
    local function Refresh()
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and T.ON or T.OFF
    end
    Refresh()
    btn.MouseButton1Click:Connect(function()
        state = not state
        Refresh()
        onChange(state)
        SaveSettings()
    end)
    return function(v) state=v Refresh() end
end

local function CreateInput(label, initVal, onChange)
    local f = MakeRow(36)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0,72,0,24)
    box.Position = UDim2.new(1,-80,0.5,-12)
    box.BackgroundColor3 = Color3.fromRGB(18,18,38)
    box.Text = tostring(initVal)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextColor3 = T.Accent
    box.ClearTextOnFocus = false
    box.Parent = f
    Instance.new("UICorner",box).CornerRadius = UDim.new(0,5)
    Instance.new("UIStroke",box).Color = T.Accent

    box.FocusLost:Connect(function()
        local v = math.clamp(tonumber(box.Text) or initVal, 1, 9999)
        box.Text = tostring(v)
        onChange(v)
        SaveSettings()
    end)
end

local function CreateDropdown(label, list, getVal, setVal)
    local f = MakeRow(36)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.44,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0.49,0,0,24)
    dropBtn.Position = UDim2.new(0.49,0,0.5,-12)
    dropBtn.BackgroundColor3 = Color3.fromRGB(30,50,100)
    dropBtn.Text = getVal()
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.TextSize = 10
    dropBtn.TextColor3 = T.Accent
    dropBtn.ClipsDescendants = true
    dropBtn.Parent = f
    Instance.new("UICorner",dropBtn).CornerRadius = UDim.new(0,5)

    local listFrame = Instance.new("Frame")
    listFrame.BackgroundColor3 = Color3.fromRGB(18,18,38)
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.LayoutOrder = NextOrder()
    listFrame.Size = UDim2.new(1,0,0,0)
    listFrame.Parent = PanelScroll
    Instance.new("UICorner",listFrame).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke",listFrame).Color = T.Accent

    local inner = Instance.new("ScrollingFrame")
    inner.Size = UDim2.new(1,-4,1,-4)
    inner.Position = UDim2.new(0,2,0,2)
    inner.BackgroundTransparency = 1
    inner.ScrollBarThickness = 3
    inner.ScrollBarImageColor3 = T.Accent
    inner.CanvasSize = UDim2.new(0,0,0,#list*26)
    inner.Parent = listFrame
    Instance.new("UIListLayout",inner).Padding = UDim.new(0,2)

    for _, item in ipairs(list) do
        local ib = Instance.new("TextButton")
        ib.Size = UDim2.new(1,0,0,24)
        ib.BackgroundTransparency = 1
        ib.Text = "  "..item
        ib.Font = Enum.Font.Gotham
        ib.TextSize = 11
        ib.TextColor3 = T.Sub
        ib.TextXAlignment = Enum.TextXAlignment.Left
        ib.Parent = inner
        ib.MouseButton1Click:Connect(function()
            setVal(item)
            dropBtn.Text = item
            listFrame.Visible = false
            listFrame.Size = UDim2.new(1,0,0,0)
            SaveSettings()
        end)
        ib.MouseEnter:Connect(function() ib.TextColor3 = T.Accent end)
        ib.MouseLeave:Connect(function() ib.TextColor3 = T.Sub end)
    end

    local open = false
    dropBtn.MouseButton1Click:Connect(function()
        open = not open
        listFrame.Visible = open
        listFrame.Size = open and UDim2.new(1,0,0,math.min(#list*26,160)) or UDim2.new(1,0,0,0)
    end)
end

local function MakeBtn(text, color, onClick)
    local f = MakeRow(34)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9,0,0,26)
    btn.Position = UDim2.new(0.05,0,0.5,-13)
    btn.BackgroundColor3 = color or T.Accent
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = T.Text
    btn.Parent = f
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,5)
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

-- ============================================================
--  ROLE DETECTION  (with permanent marking)
-- ============================================================
local function GetPlayerRole(p)
    -- Check permanent markers FIRST
    local uid = p.UserId
    if PermanentRoles[uid] then
        return PermanentRoles[uid]
    end

    -- Live detection
    if p.Team then
        local tn = p.Team.Name:lower()
        if tn:find("murder")  then
            PermanentRoles[uid] = "Murderer"
            return "Murderer"
        end
        if tn:find("sheriff") then
            PermanentRoles[uid] = "Sheriff"
            return "Sheriff"
        end
    end
    local ls = p:FindFirstChild("leaderstats")
    if ls then
        local role = ls:FindFirstChild("Role") or ls:FindFirstChild("role")
        if role then
            local rv = tostring(role.Value):lower()
            if rv:find("murder") then
                PermanentRoles[uid] = "Murderer"
                return "Murderer"
            end
            if rv:find("sheriff") then
                PermanentRoles[uid] = "Sheriff"
                return "Sheriff"
            end
        end
    end
    if p.Character then
        -- If they visibly hold a knife → permanently mark Murderer
        if p.Character:FindFirstChild("Knife") then
            PermanentRoles[uid] = "Murderer"
            return "Murderer"
        end
        if p.Character:FindFirstChild("Sheriff Gun") or p.Character:FindFirstChild("Gun") then
            PermanentRoles[uid] = "Sheriff"
            return "Sheriff"
        end
    end
    return "Innocent"
end

-- Clear permanent roles each new round (when everyone respawns)
-- We detect a new round when our own character resets
LocalPlayer.CharacterAdded:Connect(function()
    PermanentRoles = {}
end)

-- ============================================================
--  SKIN SYSTEM  (fake tool in character — visual only)
-- ============================================================
local function GetSkinColor(name)
    if name == "Rainbow" then return Color3.fromHSV(rainbowHue,1,1) end
    return SKIN_COLORS[name] or Color3.fromRGB(180,180,180)
end

-- Creates a fake visual tool parented to character (client-side only)
local function CreateFakeTool(baseName, skinName)
    local char = LocalPlayer.Character
    if not char then return end

    -- Remove old fake if exists
    if FakeSkinTools[baseName] then
        pcall(function() FakeSkinTools[baseName]:Destroy() end)
        FakeSkinTools[baseName] = nil
    end

    local color = GetSkinColor(skinName)

    -- Build a fake tool that visually resembles the real weapon
    local fakeTool = Instance.new("Tool")
    fakeTool.Name = baseName  -- same name as real tool so it looks real
    fakeTool.RequiresHandle = true
    fakeTool.CanBeDropped = false

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = baseName == "Knife" and Vector3.new(0.15, 1.2, 0.08) or Vector3.new(0.3, 1.0, 0.15)
    handle.BrickColor = BrickColor.new("Medium stone grey")
    handle.Material = Enum.Material.SmoothPlastic
    handle.CanCollide = false
    handle.CastShadow = false
    handle.Parent = fakeTool

    -- Blade/barrel (the colored part)
    local blade = Instance.new("Part")
    blade.Name = "Blade"
    blade.Size = baseName == "Knife" and Vector3.new(0.05, 0.9, 0.04) or Vector3.new(0.15, 0.8, 0.1)
    blade.Color = color
    blade.Material = Enum.Material.Neon
    blade.CanCollide = false
    blade.CastShadow = false
    blade.Parent = fakeTool

    -- Weld blade to handle
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = blade
    weld.Parent = handle
    blade.CFrame = handle.CFrame * CFrame.new(0, 0.5, 0)

    -- Tag it so we know it's ours
    local tag = Instance.new("StringValue")
    tag.Name = "_HansHubFakeSkin"
    tag.Value = skinName
    tag.Parent = fakeTool

    -- Parent to backpack so it shows in hotbar
    fakeTool.Parent = LocalPlayer.Backpack

    FakeSkinTools[baseName] = fakeTool
    return fakeTool
end

local function RemoveFakeTool(baseName)
    if FakeSkinTools[baseName] then
        pcall(function() FakeSkinTools[baseName]:Destroy() end)
        FakeSkinTools[baseName] = nil
    end
end

local function UpdateFakeSkinColor(baseName, skinName)
    local tool = FakeSkinTools[baseName]
    if not tool then return end
    local color = GetSkinColor(skinName)
    local blade = tool:FindFirstChild("Blade")
    if blade then blade.Color = color end
    local tag = tool:FindFirstChild("_HansHubFakeSkin")
    if tag then tag.Value = skinName end
end

-- ============================================================
--  CATEGORY LOADERS
-- ============================================================
local function LoadRole()
    ClearPanel()
    MakeSection("⚔  ROLE FEATURES")

    CreateToggle("🔪 Auto Stab (Murderer)", S.Role.AutoStab,
        function(v) S.Role.AutoStab = v end)
    CreateInput("  Stab Range", S.Role.StabRange,
        function(v) S.Role.StabRange = v end)

    CreateToggle("🔫 Auto Shoot (Sheriff)", S.Role.AutoShoot,
        function(v) S.Role.AutoShoot = v end)
    CreateInput("  Shoot Range", S.Role.ShootRange,
        function(v) S.Role.ShootRange = v end)

    CreateToggle("🎯 Silent Aim", S.Role.SilentAim,
        function(v) S.Role.SilentAim = v end)
    CreateInput("  FOV Size", S.Role.FOV,
        function(v) S.Role.FOV = v end)

    MakeSection("💀  AUTO KILL ALL  (Murderer only)")

    -- Info
    local infoRow = MakeRow(38)
    infoRow.BackgroundColor3 = Color3.fromRGB(40,15,15)
    local il = Instance.new("TextLabel")
    il.Size = UDim2.new(1,-10,1,0)
    il.Position = UDim2.new(0,8,0,0)
    il.BackgroundTransparency = 1
    il.Text = "⚠ TPs to each player, activates knife, then TPs to safe height"
    il.Font = Enum.Font.Gotham
    il.TextSize = 10
    il.TextColor3 = T.Red
    il.TextXAlignment = Enum.TextXAlignment.Left
    il.TextWrapped = true
    il.Parent = infoRow

    CreateToggle("☠ Enable Auto Kill All", S.Role.AutoKillAll,
        function(v) S.Role.AutoKillAll = v end)
    CreateInput("  Safe Spot Height (Y)", S.Role.SafeSpotY,
        function(v) S.Role.SafeSpotY = v end)

    MakeBtn("☠  KILL ALL NOW (manual)", T.Red, function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChild("Humanoid")
        if not root or not hum then
            Notify("Kill All","No character found!",2) return
        end
        -- Save safe spot before killing
        safeSpot = root.Position + Vector3.new(0, S.Role.SafeSpotY, 0)
        local knife = char:FindFirstChild("Knife")
            or LocalPlayer.Backpack:FindFirstChild("Knife")
        if not knife then
            Notify("Kill All","No knife found in inventory!",2) return
        end
        if knife.Parent == LocalPlayer.Backpack then hum:EquipTool(knife) end

        local killed = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                local pHum  = p.Character:FindFirstChild("Humanoid")
                if pRoot and pHum and pHum.Health > 0 then
                    -- TP to target
                    root.CFrame = CFrame.new(pRoot.Position + Vector3.new(0,2,0))
                    task.wait(0.05)
                    -- Face and activate
                    root.CFrame = CFrame.new(root.Position, pRoot.Position)
                    pcall(function() knife:Activate() end)
                    task.wait(0.1)
                    killed += 1
                end
            end
        end
        -- TP to safe spot
        root.CFrame = CFrame.new(safeSpot)
        Notify("Kill All","Killed "..killed.." players! Teleported to safe spot.",3)
    end)
end

local function LoadUtil()
    ClearPanel()
    MakeSection("🛠  UTILITIES")

    CreateToggle("💎 Auto Collect", S.Util.AutoCollect,
        function(v) S.Util.AutoCollect = v end)
    CreateInput("  Collect Range", S.Util.CollectRange,
        function(v) S.Util.CollectRange = v end)

    CreateToggle("🏃 Walk Speed", S.Util.WalkSpeed,
        function(v)
            S.Util.WalkSpeed = v
            if not v then
                local c = LocalPlayer.Character
                if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = 16 end
            end
        end)
    CreateInput("  Speed Value", S.Util.Speed,
        function(v) S.Util.Speed = v end)

    CreateToggle("🦘 Jump Power", S.Util.JumpPower,
        function(v)
            S.Util.JumpPower = v
            if not v then
                local c = LocalPlayer.Character
                if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower = 50 end
            end
        end)
    CreateInput("  Jump Value", S.Util.Power,
        function(v) S.Util.Power = v end)

    CreateToggle("📏 Reach", S.Util.Reach,
        function(v) S.Util.Reach = v end)
    CreateInput("  Reach Range", S.Util.ReachRange,
        function(v) S.Util.ReachRange = v end)

    CreateToggle("👁 X-Ray (walls see-thru)", S.Util.XRay,
        function(v)
            S.Util.XRay = v
            if not v then
                for obj, orig in pairs(OriginalTransparency) do
                    if obj and obj.Parent then obj.Transparency = orig end
                end
                OriginalTransparency = {}
                XRayCache = {}
                XRayCacheTimer = 0
            else
                XRayCacheTimer = XRayCacheInterval
            end
        end)

    CreateToggle("🚫 No Clip", S.Util.NoClip,
        function(v) S.Util.NoClip = v end)
end

local function LoadESP()
    ClearPanel()
    MakeSection("📡  ESP  (permanent role markers ON)")

    CreateToggle("✅ Enable ESP", S.ESP.Enabled,
        function(v)
            S.ESP.Enabled = v
            if not v then
                for _, data in pairs(ESPObjects) do
                    for _, d in pairs(data) do pcall(function() d.Visible=false end) end
                end
            end
        end)
    CreateToggle("Show Murderer", S.ESP.ShowMurderer, function(v) S.ESP.ShowMurderer=v end)
    CreateToggle("Show Sheriff",  S.ESP.ShowSheriff,  function(v) S.ESP.ShowSheriff=v  end)
    CreateToggle("Show Others",   S.ESP.ShowOthers,   function(v) S.ESP.ShowOthers=v   end)
    CreateToggle("Draw Box",      S.ESP.Box,           function(v) S.ESP.Box=v          end)
    CreateToggle("Draw Name",     S.ESP.Name,          function(v) S.ESP.Name=v         end)
    CreateToggle("Draw Distance", S.ESP.Distance,      function(v) S.ESP.Distance=v     end)

    MakeBtn("🗑  Clear Role Memory", Color3.fromRGB(120,40,40), function()
        PermanentRoles = {}
        Notify("ESP","Role memory cleared.",2)
    end)
end

local function LoadSkin()
    ClearPanel()
    MakeSection("🎨  VISUAL SKIN INJECTOR")

    local infoRow = MakeRow(36)
    infoRow.BackgroundColor3 = Color3.fromRGB(20,40,80)
    local il = Instance.new("TextLabel")
    il.Size = UDim2.new(1,-10,1,0)
    il.Position = UDim2.new(0,8,0,0)
    il.BackgroundTransparency = 1
    il.Text = "ℹ  Adds fake tool to YOUR inventory visually. Disappears when disabled."
    il.Font = Enum.Font.Gotham
    il.TextSize = 10
    il.TextColor3 = T.Accent
    il.TextXAlignment = Enum.TextXAlignment.Left
    il.TextWrapped = true
    il.Parent = infoRow

    MakeSection("🔪  KNIFE SKIN")
    CreateToggle("Enable Knife Skin", S.Skin.KnifeEnabled,
        function(v)
            S.Skin.KnifeEnabled = v
            if v then
                CreateFakeTool("Knife", S.Skin.KnifeSkin)
                Notify("Skin","Fake knife added to inventory!",2)
            else
                RemoveFakeTool("Knife")
                Notify("Skin","Fake knife removed.",2)
            end
        end)

    CreateDropdown("Knife Skin", KNIFE_SKINS,
        function() return S.Skin.KnifeSkin end,
        function(v)
            S.Skin.KnifeSkin = v
            if S.Skin.KnifeEnabled then
                -- Recreate with new skin
                CreateFakeTool("Knife", v)
            end
        end)

    MakeBtn("🔪  Apply / Refresh Knife", T.Accent, function()
        if S.Skin.KnifeEnabled then
            CreateFakeTool("Knife", S.Skin.KnifeSkin)
            Notify("Skin","Knife skin refreshed: "..S.Skin.KnifeSkin,2)
        else
            Notify("Skin","Enable Knife Skin first!",2)
        end
    end)

    MakeSection("🔫  GUN SKIN")
    CreateToggle("Enable Gun Skin", S.Skin.GunEnabled,
        function(v)
            S.Skin.GunEnabled = v
            if v then
                CreateFakeTool("Sheriff Gun", S.Skin.GunSkin)
                Notify("Skin","Fake gun added to inventory!",2)
            else
                RemoveFakeTool("Sheriff Gun")
                Notify("Skin","Fake gun removed.",2)
            end
        end)

    CreateDropdown("Gun Skin", GUN_SKINS,
        function() return S.Skin.GunSkin end,
        function(v)
            S.Skin.GunSkin = v
            if S.Skin.GunEnabled then
                CreateFakeTool("Sheriff Gun", v)
            end
        end)

    MakeBtn("🔫  Apply / Refresh Gun", Color3.fromRGB(60,180,100), function()
        if S.Skin.GunEnabled then
            CreateFakeTool("Sheriff Gun", S.Skin.GunSkin)
            Notify("Skin","Gun skin refreshed: "..S.Skin.GunSkin,2)
        else
            Notify("Skin","Enable Gun Skin first!",2)
        end
    end)

    MakeSection("🔄  RESET")
    MakeBtn("↩  Remove All Fake Skins", Color3.fromRGB(160,40,60), function()
        RemoveFakeTool("Knife")
        RemoveFakeTool("Sheriff Gun")
        S.Skin.KnifeEnabled = false
        S.Skin.GunEnabled   = false
        SaveSettings()
        Notify("Skin","All fake skins removed.",2)
    end)
end

local function LoadConfig()
    ClearPanel()
    MakeSection("💾  SETTINGS CONFIG")

    local infoRow = MakeRow(44)
    infoRow.BackgroundColor3 = Color3.fromRGB(15,35,15)
    local il = Instance.new("TextLabel")
    il.Size = UDim2.new(1,-10,1,0)
    il.Position = UDim2.new(0,8,0,0)
    il.BackgroundTransparency = 1
    il.Text = "✅ Settings auto-save when you toggle anything.\nFile: HansHub_Settings.json"
    il.Font = Enum.Font.Gotham
    il.TextSize = 10
    il.TextColor3 = T.ON
    il.TextXAlignment = Enum.TextXAlignment.Left
    il.TextWrapped = true
    il.Parent = infoRow

    MakeBtn("💾  Save Settings Now", T.ON, function()
        SaveSettings()
        Notify("Config","Settings saved!",2)
    end)

    MakeBtn("📂  Reload Settings", T.Accent, function()
        LoadSettings()
        Notify("Config","Settings reloaded from file!",2)
    end)

    MakeBtn("🗑  Reset to Defaults", Color3.fromRGB(160,40,60), function()
        S = DeepCopy(DefaultSettings)
        SaveSettings()
        Notify("Config","Reset to defaults!",2)
    end)

    -- Show current save status
    MakeSection("📋  CURRENT SAVED VALUES")
    local function ShowRow(label, val)
        local f = MakeRow(28)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.6,0,1,0)
        l.Position = UDim2.new(0,10,0,0)
        l.BackgroundTransparency = 1
        l.Text = label
        l.Font = Enum.Font.Gotham
        l.TextSize = 11
        l.TextColor3 = T.Sub
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f
        local v = Instance.new("TextLabel")
        v.Size = UDim2.new(0.38,0,1,0)
        v.Position = UDim2.new(0.6,0,0,0)
        v.BackgroundTransparency = 1
        v.Text = tostring(val)
        v.Font = Enum.Font.GothamBold
        v.TextSize = 11
        v.TextColor3 = (val == true or val == "true") and T.ON or T.Accent
        v.TextXAlignment = Enum.TextXAlignment.Right
        v.Parent = f
    end

    ShowRow("Auto Stab",     S.Role.AutoStab)
    ShowRow("Auto Shoot",    S.Role.AutoShoot)
    ShowRow("Silent Aim",    S.Role.SilentAim)
    ShowRow("Auto Kill All", S.Role.AutoKillAll)
    ShowRow("Walk Speed",    S.Util.WalkSpeed)
    ShowRow("Speed",         S.Util.Speed)
    ShowRow("Jump Power",    S.Util.JumpPower)
    ShowRow("No Clip",       S.Util.NoClip)
    ShowRow("X-Ray",         S.Util.XRay)
    ShowRow("ESP",           S.ESP.Enabled)
    ShowRow("Knife Skin",    S.Skin.KnifeSkin)
    ShowRow("Gun Skin",      S.Skin.GunSkin)
end

-- ============================================================
--  SIDEBAR BUTTONS
-- ============================================================
local catLoaders = {
    Role   = LoadRole,
    Util   = LoadUtil,
    ESP    = LoadESP,
    Skin   = LoadSkin,
    Config = LoadConfig,
}

local function CreateCatBtn(icon, label, key, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-6,0,36)
    btn.BackgroundColor3 = T.Card
    btn.Text = ""
    btn.LayoutOrder = order
    btn.Parent = SideList
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,7)

    local iconL = Instance.new("TextLabel")
    iconL.Size = UDim2.new(0,28,1,0)
    iconL.Position = UDim2.new(0,6,0,0)
    iconL.BackgroundTransparency = 1
    iconL.Text = icon
    iconL.TextSize = 15
    iconL.Parent = btn

    local nameL = Instance.new("TextLabel")
    nameL.Size = UDim2.new(1,-38,1,0)
    nameL.Position = UDim2.new(0,36,0,0)
    nameL.BackgroundTransparency = 1
    nameL.Text = label
    nameL.Font = Enum.Font.GothamSemibold
    nameL.TextSize = 11
    nameL.TextColor3 = T.Sub
    nameL.TextXAlignment = Enum.TextXAlignment.Left
    nameL.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if ActiveCatBtn and ActiveCatBtn ~= btn then
            ActiveCatBtn.BackgroundColor3 = T.Card
        end
        if ActiveCatNameLbl and ActiveCatNameLbl ~= nameL then
            ActiveCatNameLbl.TextColor3 = T.Sub
        end
        ActiveCatBtn     = btn
        ActiveCatNameLbl = nameL
        btn.BackgroundColor3 = T.Accent
        nameL.TextColor3     = T.Text
        CurrentCatKey = key
        catLoaders[key]()
    end)
    btn.MouseEnter:Connect(function()
        if ActiveCatBtn ~= btn then btn.BackgroundColor3 = Color3.fromRGB(38,35,62) end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveCatBtn ~= btn then btn.BackgroundColor3 = T.Card end
    end)
    return btn, nameL
end

local btn1,lbl1 = CreateCatBtn("⚔",  "Role Features", "Role",   1)
local btn2,lbl2 = CreateCatBtn("🛠",  "Utilities",     "Util",   2)
local btn3,lbl3 = CreateCatBtn("📡", "ESP",           "ESP",    3)
local btn4,lbl4 = CreateCatBtn("🎨", "Skin Injector", "Skin",   4)
local btn5,lbl5 = CreateCatBtn("💾", "Config / Save", "Config", 5)

ActiveCatBtn     = btn1
ActiveCatNameLbl = lbl1
btn1.BackgroundColor3 = T.Accent
lbl1.TextColor3       = T.Text
task.defer(LoadRole)

-- ============================================================
--  SILENT AIM FOV CIRCLE
-- ============================================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(255,100,100)
FOVCircle.Transparency = 0.6
FOVCircle.Filled = false

local function GetClosestInFOV()
    local best, bestDist = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local pos, vis = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if vis then
                    local d = (Vector2.new(pos.X,pos.Y)-center).Magnitude
                    if d < S.Role.FOV and d < bestDist then
                        bestDist = d
                        best = p
                    end
                end
            end
        end
    end
    return best
end

-- ============================================================
--  ESP
-- ============================================================
local function GetOrMakeESP(p)
    if not ESPObjects[p] then
        local e = {Box=Drawing.new("Square"), Name=Drawing.new("Text"), Dist=Drawing.new("Text")}
        e.Box.Filled=false e.Box.Thickness=1.5
        e.Name.Size=14 e.Name.Center=true e.Name.Outline=true
        e.Dist.Size=12 e.Dist.Center=true e.Dist.Outline=true
        ESPObjects[p] = e
    end
    return ESPObjects[p]
end

local function HideESP(data)
    if not data then return end
    for _,d in pairs(data) do pcall(function() d.Visible=false end) end
end

Players.PlayerRemoving:Connect(function(p)
    if ESPObjects[p] then
        for _,d in pairs(ESPObjects[p]) do pcall(function() d:Remove() end) end
        ESPObjects[p] = nil
    end
    -- Keep permanent role — intentionally don't remove from PermanentRoles
end)

-- ============================================================
--  MAIN HEARTBEAT
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
    local char = LocalPlayer.Character
    if not char then return end
    local Root = char:FindFirstChild("HumanoidRootPart")
    local Hum  = char:FindFirstChild("Humanoid")
    if not Root or not Hum or Hum.Health <= 0 then return end

    heartbeatStep += 1

    -- SPEED / JUMP
    if S.Util.WalkSpeed then Hum.WalkSpeed = S.Util.Speed end
    if S.Util.JumpPower  then Hum.JumpPower = S.Util.Power end

    -- NO CLIP
    if S.Util.NoClip then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end

    -- X-RAY (throttled + cached)
    if S.Util.XRay then
        XRayCacheTimer += dt
        if XRayCacheTimer >= XRayCacheInterval then
            XRayCacheTimer = 0
            XRayCache = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj:IsDescendantOf(char) then
                    if obj.Size.Magnitude > 2 then
                        table.insert(XRayCache, obj)
                    end
                end
            end
        end
        if heartbeatStep % 4 == 0 then
            local tgt = S.Util.XRayTrans
            for _, obj in ipairs(XRayCache) do
                if obj and obj.Parent and not obj:IsDescendantOf(char) then
                    if not OriginalTransparency[obj] then
                        OriginalTransparency[obj] = obj.Transparency
                    end
                    if obj.Transparency < tgt then
                        obj.Transparency = tgt
                    end
                end
            end
        end
    end

    -- AUTO COLLECT
    if S.Util.AutoCollect then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.CanCollide then
                local n = obj.Name
                if n=="Knife" or n=="Gun" or n:find("Coin") or n=="Medkit" then
                    if (Root.Position-obj.Position).Magnitude < S.Util.CollectRange then
                        Root.CFrame = CFrame.new(obj.Position+Vector3.new(0,3,0))
                    end
                end
            end
        end
    end

    -- Find roles
    local Murderer, Sheriff = nil, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local r = GetPlayerRole(p)
            if r == "Murderer" then Murderer = p end
            if r == "Sheriff"  then Sheriff  = p end
        end
    end

    local myRole = GetPlayerRole(LocalPlayer)

    -- AUTO STAB
    if S.Role.AutoStab and myRole == "Murderer" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local pHum  = p.Character:FindFirstChild("Humanoid")
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if pHum and pRoot and pHum.Health > 0 then
                    if (Root.Position-pRoot.Position).Magnitude < S.Role.StabRange
                    and GetPlayerRole(p) ~= "Murderer" then
                        pcall(function()
                            local knife = char:FindFirstChild("Knife")
                                or LocalPlayer.Backpack:FindFirstChild("Knife")
                            if knife and not knife:FindFirstChild("_HansHubFakeSkin") then
                                if knife.Parent == LocalPlayer.Backpack then Hum:EquipTool(knife) end
                                Root.CFrame = CFrame.new(Root.Position, pRoot.Position)
                                knife:Activate()
                            end
                        end)
                    end
                end
            end
        end
    end

    -- AUTO KILL ALL (continuous — tp to next alive enemy each frame)
    if S.Role.AutoKillAll and myRole == "Murderer" then
        local knife = char:FindFirstChild("Knife")
            or LocalPlayer.Backpack:FindFirstChild("Knife")
        if knife and not knife:FindFirstChild("_HansHubFakeSkin") then
            if knife.Parent == LocalPlayer.Backpack then Hum:EquipTool(knife) end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local pHum  = p.Character:FindFirstChild("Humanoid")
                    local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    if pHum and pRoot and pHum.Health > 0 then
                        Root.CFrame = CFrame.new(pRoot.Position + Vector3.new(0,2,0))
                        Root.CFrame = CFrame.new(Root.Position, pRoot.Position)
                        pcall(function() knife:Activate() end)
                        break -- one per frame so it doesn't freeze
                    end
                end
            end
        end
    end

    -- AUTO SHOOT (Sheriff → Murderer)
    if S.Role.AutoShoot and myRole == "Sheriff" and Murderer then
        local mRoot = Murderer.Character and Murderer.Character:FindFirstChild("HumanoidRootPart")
        local mHum  = Murderer.Character and Murderer.Character:FindFirstChild("Humanoid")
        if mRoot and mHum and mHum.Health > 0 then
            if (Root.Position-mRoot.Position).Magnitude < S.Role.ShootRange then
                pcall(function()
                    local gun = char:FindFirstChild("Sheriff Gun")
                        or char:FindFirstChild("Gun")
                        or LocalPlayer.Backpack:FindFirstChild("Sheriff Gun")
                        or LocalPlayer.Backpack:FindFirstChild("Gun")
                    -- Skip fake skin tools
                    if gun and not gun:FindFirstChild("_HansHubFakeSkin") then
                        if gun.Parent == LocalPlayer.Backpack then Hum:EquipTool(gun) end
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, mRoot.Position)
                        gun:Activate()
                    end
                end)
            end
        end
    end

    -- REACH
    if S.Util.Reach then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if pRoot and (Root.Position-pRoot.Position).Magnitude < S.Util.ReachRange then
                    local dir = (pRoot.Position-Root.Position).Unit
                    Root.CFrame = Root.CFrame + dir * 0.5
                end
            end
        end
    end

    -- Rainbow hue cycle every 20 frames
    if heartbeatStep % 20 == 0 then
        rainbowHue = (rainbowHue + 0.03) % 1
        -- Update rainbow skin color on fake tools live
        if S.Skin.KnifeEnabled and S.Skin.KnifeSkin == "Rainbow" then
            UpdateFakeSkinColor("Knife", "Rainbow")
        end
        if S.Skin.GunEnabled and S.Skin.GunSkin == "Rainbow" then
            UpdateFakeSkinColor("Sheriff Gun", "Rainbow")
        end
    end
end)

-- ============================================================
--  RENDER STEPPED: Silent Aim + ESP
-- ============================================================
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local Root = char and char:FindFirstChild("HumanoidRootPart")

    -- SILENT AIM
    if S.Role.SilentAim then
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Position = center
        FOVCircle.Radius   = S.Role.FOV
        FOVCircle.Visible  = true
        local tgt = GetClosestInFOV()
        if tgt and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, tgt.Character.HumanoidRootPart.Position)
        end
    else
        FOVCircle.Visible = false
    end

    -- ESP
    if not S.ESP.Enabled then
        for _, data in pairs(ESPObjects) do HideESP(data) end
        return
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local pChar = p.Character
        local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
        local pHum  = pChar and pChar:FindFirstChildOfClass("Humanoid")
        if not pRoot or not pHum or pHum.Health <= 0 then HideESP(ESPObjects[p]) continue end

        local role = GetPlayerRole(p)
        if (role=="Murderer" and not S.ESP.ShowMurderer)
        or (role=="Sheriff"  and not S.ESP.ShowSheriff)
        or (role=="Innocent" and not S.ESP.ShowOthers) then
            HideESP(ESPObjects[p]) continue
        end

        local pos, vis = Camera:WorldToViewportPoint(pRoot.Position)
        if not vis then HideESP(ESPObjects[p]) continue end

        local e = GetOrMakeESP(p)
        -- Murderer = red, Sheriff = green, Innocent = white
        -- Permanently marked = add ★ to name
        local isMarked = PermanentRoles[p.UserId] ~= nil
        local col = role=="Murderer" and Color3.fromRGB(255,60,60)
                 or role=="Sheriff"  and Color3.fromRGB(60,220,100)
                 or                      Color3.fromRGB(220,220,220)

        local szX,szY = 2200/pos.Z, 3000/pos.Z
        local scr = Vector2.new(pos.X, pos.Y)

        e.Box.Visible = S.ESP.Box
        e.Box.Position = Vector2.new(scr.X-szX/2, scr.Y-szY/2)
        e.Box.Size = Vector2.new(szX,szY)
        e.Box.Color = col
        e.Box.Transparency = 0.5

        e.Name.Visible = S.ESP.Name
        e.Name.Position = Vector2.new(scr.X, scr.Y-szY/2-18)
        -- ★ prefix if permanently confirmed role
        local prefix = isMarked and "★ " or ""
        e.Name.Text = string.format("%s[%s] %s", prefix, role, p.Name)
        e.Name.Color = col

        if Root then
            e.Dist.Visible = S.ESP.Distance
            e.Dist.Position = Vector2.new(scr.X, scr.Y+szY/2+6)
            e.Dist.Text = string.format("%.0f studs", (Root.Position-pRoot.Position).Magnitude)
            e.Dist.Color = col
        end
    end
end)

-- ============================================================
--  INSERT TOGGLE
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- ============================================================
--  CLEANUP on exit — remove fake tools
-- ============================================================
ScreenGui.AncestryChanged:Connect(function()
    RemoveFakeTool("Knife")
    RemoveFakeTool("Sheriff Gun")
end)

task.delay(0.5, function()
    Notify("✨ Hans Hub v4.0","Loaded! INSERT to toggle. Settings auto-saved!",4)
end)
