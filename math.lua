--[[
    HANS HUB | MM2 | v3.1
    Toggle: INSERT
    NEW: Visual Skin Injector (knife/gun skins, visual only)
    FIX: X-Ray no longer lags (throttled + part cache)
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

local Camera      = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ============================================================
--  SETTINGS
-- ============================================================
local S = {
    Role = {
        AutoStab  = {Enabled = false, Range = 25},
        AutoShoot = {Enabled = false, Range = 80},
        SilentAim = {Enabled = false, FOV = 120},
    },
    Util = {
        AutoCollect = {Enabled = false, Range = 50},
        WalkSpeed   = {Enabled = false, Speed = 32},
        JumpPower   = {Enabled = false, Power = 60},
        Reach       = {Enabled = false, Range = 20},
        NoClip      = {Enabled = false},
        XRay        = {Enabled = false, Transparency = 0.4},
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
        KnifeEnabled = false,
        GunEnabled   = false,
        KnifeSkin    = "Default",
        GunSkin      = "Default",
    },
}

-- ============================================================
--  SKIN LISTS  (visual names — applied as BrickColor/Texture)
-- ============================================================
local KNIFE_SKINS = {
    "Default",
    "Rainbow",
    "Gold",
    "Neon Green",
    "Void Black",
    "Crimson Red",
    "Ice Blue",
    "Sakura Pink",
    "Toxic",
    "Obsidian",
    "Electric Purple",
    "Chroma",
    "Laser",
    "Galaxy",
    "Tiger",
    "Dragon",
    "Coral",
    "Midnight",
    "Sunrise",
    "Arctic",
}

local GUN_SKINS = {
    "Default",
    "Rainbow",
    "Gold",
    "Neon Green",
    "Void Black",
    "Crimson Red",
    "Ice Blue",
    "Sakura Pink",
    "Toxic",
    "Obsidian",
    "Electric Purple",
    "Chroma",
    "Laser",
    "Galaxy",
    "Tiger",
    "Dragon",
    "Coral",
    "Midnight",
    "Sunrise",
    "Arctic",
}

-- Skin → Color3 map (visual color applied to parts)
local SKIN_COLORS = {
    ["Default"]         = Color3.fromRGB(180, 180, 180),
    ["Rainbow"]         = Color3.fromRGB(255, 100, 200),  -- cycles in loop
    ["Gold"]            = Color3.fromRGB(255, 200, 50),
    ["Neon Green"]      = Color3.fromRGB(0,   255, 100),
    ["Void Black"]      = Color3.fromRGB(15,  15,  15),
    ["Crimson Red"]     = Color3.fromRGB(200, 20,  40),
    ["Ice Blue"]        = Color3.fromRGB(130, 210, 255),
    ["Sakura Pink"]     = Color3.fromRGB(255, 160, 190),
    ["Toxic"]           = Color3.fromRGB(100, 255, 50),
    ["Obsidian"]        = Color3.fromRGB(30,  25,  50),
    ["Electric Purple"] = Color3.fromRGB(160, 50,  255),
    ["Chroma"]          = Color3.fromRGB(255, 50,  255),
    ["Laser"]           = Color3.fromRGB(255, 255, 0),
    ["Galaxy"]          = Color3.fromRGB(80,  0,   120),
    ["Tiger"]           = Color3.fromRGB(255, 140, 0),
    ["Dragon"]          = Color3.fromRGB(200, 30,  10),
    ["Coral"]           = Color3.fromRGB(255, 127, 80),
    ["Midnight"]        = Color3.fromRGB(20,  20,  60),
    ["Sunrise"]         = Color3.fromRGB(255, 180, 60),
    ["Arctic"]          = Color3.fromRGB(200, 240, 255),
}

-- Rainbow hue cycling
local rainbowHue = 0

-- ============================================================
--  STATE
-- ============================================================
local ESPObjects           = {}
local OriginalTransparency = {}
local XRayCache            = {}   -- cached list of parts for xray (rebuilt rarely)
local XRayCacheTimer       = 0
local XRayCacheInterval    = 3    -- rebuild xray part list every 3 seconds only
local xrayThrottle         = 0    -- heartbeat throttle
local CurrentCatKey        = "Role"
local ActiveCatBtn         = nil
local ActiveCatNameLbl     = nil

-- ============================================================
--  THEME
-- ============================================================
local T = {
    BG      = Color3.fromRGB(12,  12,  20),
    Sidebar = Color3.fromRGB(20,  20,  34),
    Panel   = Color3.fromRGB(26,  26,  42),
    Card    = Color3.fromRGB(32,  32,  52),
    Accent  = Color3.fromRGB(75, 160, 255),
    ON      = Color3.fromRGB(70, 220, 120),
    OFF     = Color3.fromRGB(220, 70,  90),
    Text    = Color3.new(1,1,1),
    Sub     = Color3.fromRGB(170,170,200),
    Divider = Color3.fromRGB(50,  50,  80),
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
MainFrame.Size = UDim2.new(0, 500, 0, 470)
MainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
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
TBFix.Size = UDim2.new(1, 0, 0.5, 0)
TBFix.Position = UDim2.new(0, 0, 0.5, 0)
TBFix.BackgroundColor3 = T.Sidebar
TBFix.BorderSizePixel = 0
TBFix.Parent = TitleBar

local TLAcc = Instance.new("Frame")
TLAcc.Size = UDim2.new(0, 4, 1, -12)
TLAcc.Position = UDim2.new(0, 10, 0, 6)
TLAcc.BackgroundColor3 = T.Accent
TLAcc.BorderSizePixel = 0
TLAcc.Parent = TitleBar
Instance.new("UICorner", TLAcc).CornerRadius = UDim.new(0, 3)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(0.75, 0, 1, 0)
TitleLbl.Position = UDim2.new(0, 22, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "✨  HANS HUB  |  MM2"
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 14
TitleLbl.TextColor3 = T.Accent
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = TitleBar

local VerLbl = Instance.new("TextLabel")
VerLbl.Size = UDim2.new(0, 68, 0, 18)
VerLbl.Position = UDim2.new(1, -112, 0.5, -9)
VerLbl.BackgroundColor3 = Color3.fromRGB(25, 55, 110)
VerLbl.Text = "v3.1 SKINS"
VerLbl.Font = Enum.Font.GothamBold
VerLbl.TextSize = 10
VerLbl.TextColor3 = T.Accent
VerLbl.Parent = TitleBar
Instance.new("UICorner", VerLbl).CornerRadius = UDim.new(0, 4)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 60)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.TextColor3 = T.Text
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 148, 1, -50)
Sidebar.Position = UDim2.new(0, 6, 0, 46)
Sidebar.BackgroundColor3 = T.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

local SideList = Instance.new("ScrollingFrame")
SideList.Size = UDim2.new(1, -6, 1, -10)
SideList.Position = UDim2.new(0, 3, 0, 5)
SideList.BackgroundTransparency = 1
SideList.ScrollBarThickness = 3
SideList.ScrollBarImageColor3 = T.Accent
SideList.CanvasSize = UDim2.new(0, 0, 0, 0)
SideList.AutomaticCanvasSize = Enum.AutomaticSize.Y
SideList.Parent = Sidebar
local SideLayout = Instance.new("UIListLayout", SideList)
SideLayout.Padding = UDim.new(0, 5)
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", SideList).PaddingTop = UDim.new(0, 5)

-- Right panel
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(1, -163, 1, -50)
RightPanel.Position = UDim2.new(0, 159, 0, 46)
RightPanel.BackgroundColor3 = T.Panel
RightPanel.BorderSizePixel = 0
RightPanel.Parent = MainFrame
Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0, 8)

local PanelScroll = Instance.new("ScrollingFrame")
PanelScroll.Size = UDim2.new(1, -10, 1, -10)
PanelScroll.Position = UDim2.new(0, 5, 0, 5)
PanelScroll.BackgroundTransparency = 1
PanelScroll.ScrollBarThickness = 4
PanelScroll.ScrollBarImageColor3 = T.Accent
PanelScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PanelScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PanelScroll.Parent = RightPanel
local PanelLayout = Instance.new("UIListLayout", PanelScroll)
PanelLayout.Padding = UDim.new(0, 6)
PanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
local PPad = Instance.new("UIPadding", PanelScroll)
PPad.PaddingTop = UDim.new(0, 6)
PPad.PaddingRight = UDim.new(0, 4)

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
    l.Size = UDim2.new(1, 0, 0, 22)
    l.BackgroundTransparency = 1
    l.Text = "  " .. text
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextColor3 = T.Accent
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = NextOrder()
    l.Parent = PanelScroll
    local div = Instance.new("Frame")
    div.Size = UDim2.new(1, 0, 0, 1)
    div.BackgroundColor3 = T.Divider
    div.BorderSizePixel = 0
    div.LayoutOrder = NextOrder()
    div.Parent = PanelScroll
end

local function MakeRow(h)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, h or 36)
    f.BackgroundColor3 = T.Card
    f.BorderSizePixel = 0
    f.LayoutOrder = NextOrder()
    f.Parent = PanelScroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    return f
end

local function CreateToggle(label, initVal, onChange)
    local f = MakeRow(36)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 24)
    btn.Position = UDim2.new(1, -58, 0.5, -12)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = T.Text
    btn.Parent = f
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

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
    end)
    return function(v) state = v Refresh() end
end

local function CreateInput(label, initVal, onChange)
    local f = MakeRow(36)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 72, 0, 24)
    box.Position = UDim2.new(1, -80, 0.5, -12)
    box.BackgroundColor3 = Color3.fromRGB(18, 18, 38)
    box.Text = tostring(initVal)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextColor3 = T.Accent
    box.ClearTextOnFocus = false
    box.Parent = f
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
    Instance.new("UIStroke", box).Color = T.Accent

    box.FocusLost:Connect(function()
        local v = math.clamp(tonumber(box.Text) or initVal, 1, 9999)
        box.Text = tostring(v)
        onChange(v)
    end)
end

-- Dropdown widget
local function CreateDropdown(label, list, getVal, setVal)
    local f = MakeRow(36)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0.48, 0, 0, 24)
    dropBtn.Position = UDim2.new(0.5, 0, 0.5, -12)
    dropBtn.BackgroundColor3 = Color3.fromRGB(30, 50, 100)
    dropBtn.Text = getVal()
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.TextSize = 10
    dropBtn.TextColor3 = T.Accent
    dropBtn.ClipsDescendants = true
    dropBtn.Parent = f
    Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 5)

    -- Dropdown list
    local listFrame = Instance.new("Frame")
    listFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 38)
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.LayoutOrder = NextOrder()
    listFrame.Size = UDim2.new(1, 0, 0, 0)
    listFrame.Parent = PanelScroll
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", listFrame).Color = T.Accent

    local innerScroll = Instance.new("ScrollingFrame")
    innerScroll.Size = UDim2.new(1, -4, 1, -4)
    innerScroll.Position = UDim2.new(0, 2, 0, 2)
    innerScroll.BackgroundTransparency = 1
    innerScroll.ScrollBarThickness = 3
    innerScroll.ScrollBarImageColor3 = T.Accent
    innerScroll.CanvasSize = UDim2.new(0, 0, 0, #list * 26)
    innerScroll.Parent = listFrame
    Instance.new("UIListLayout", innerScroll).Padding = UDim.new(0, 2)

    for _, item in ipairs(list) do
        local itemBtn = Instance.new("TextButton")
        itemBtn.Size = UDim2.new(1, 0, 0, 24)
        itemBtn.BackgroundTransparency = 1
        itemBtn.Text = "  " .. item
        itemBtn.Font = Enum.Font.Gotham
        itemBtn.TextSize = 11
        itemBtn.TextColor3 = T.Sub
        itemBtn.TextXAlignment = Enum.TextXAlignment.Left
        itemBtn.Parent = innerScroll

        itemBtn.MouseButton1Click:Connect(function()
            setVal(item)
            dropBtn.Text = item
            listFrame.Visible = false
            listFrame.Size = UDim2.new(1, 0, 0, 0)
        end)
        itemBtn.MouseEnter:Connect(function() itemBtn.TextColor3 = T.Accent end)
        itemBtn.MouseLeave:Connect(function() itemBtn.TextColor3 = T.Sub end)
    end

    local open = false
    dropBtn.MouseButton1Click:Connect(function()
        open = not open
        listFrame.Visible = open
        listFrame.Size = open and UDim2.new(1, 0, 0, math.min(#list * 26, 160)) or UDim2.new(1, 0, 0, 0)
    end)
end

-- Colour preview swatch (shows chosen skin color)
local skinPreviewKnife = nil
local skinPreviewGun   = nil

local function CreateColorSwatch(color)
    local f = MakeRow(28)
    f.BackgroundColor3 = T.Card

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Preview Color:"
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextColor3 = T.Sub
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f

    local swatch = Instance.new("Frame")
    swatch.Size = UDim2.new(0, 80, 0, 18)
    swatch.Position = UDim2.new(0.55, 0, 0.5, -9)
    swatch.BackgroundColor3 = color or Color3.new(1,1,1)
    swatch.BorderSizePixel = 0
    swatch.Parent = f
    Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 5)
    Instance.new("UIStroke", swatch).Color = T.Accent

    return swatch
end

-- ============================================================
--  SKIN APPLIER
-- ============================================================
local OriginalSkinColors = {}   -- [part] = {Color3, Material}

local function GetSkinColor(skinName)
    if skinName == "Rainbow" then
        return Color3.fromHSV(rainbowHue, 1, 1)
    end
    return SKIN_COLORS[skinName] or Color3.fromRGB(180, 180, 180)
end

local function ApplySkinToTool(toolName, skinName)
    -- Find the tool in character or backpack
    local char = LocalPlayer.Character
    local tool = (char and char:FindFirstChild(toolName))
        or LocalPlayer.Backpack:FindFirstChild(toolName)
    if not tool then return false end

    local color = GetSkinColor(skinName)

    for _, part in ipairs(tool:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("UnionOperation") or part:IsA("MeshPart") or part:IsA("SpecialMesh") then
            if not OriginalSkinColors[part] then
                OriginalSkinColors[part] = {Color = part.Color, Material = part.Material}
            end
            -- Apply color — keep handles grey to look natural
            if part.Name ~= "Handle" then
                part.Color = color
                part.Material = Enum.Material.Neon
            else
                part.Color = color
            end
        end
    end
    return true
end

local function RestoreSkin(toolName)
    local char = LocalPlayer.Character
    local tool = (char and char:FindFirstChild(toolName))
        or LocalPlayer.Backpack:FindFirstChild(toolName)
    if not tool then return end

    for _, part in ipairs(tool:GetDescendants()) do
        if OriginalSkinColors[part] then
            part.Color    = OriginalSkinColors[part].Color
            part.Material = OriginalSkinColors[part].Material
            OriginalSkinColors[part] = nil
        end
    end
end

-- ============================================================
--  CATEGORY LOADERS
-- ============================================================
local function LoadRole()
    ClearPanel()
    MakeSection("⚔  ROLE FEATURES")
    CreateToggle("🔪 Auto Stab (Murderer)", S.Role.AutoStab.Enabled,
        function(v) S.Role.AutoStab.Enabled = v end)
    CreateInput("  Stab Range", S.Role.AutoStab.Range,
        function(v) S.Role.AutoStab.Range = v end)
    CreateToggle("🔫 Auto Shoot (Sheriff)", S.Role.AutoShoot.Enabled,
        function(v) S.Role.AutoShoot.Enabled = v end)
    CreateInput("  Shoot Range", S.Role.AutoShoot.Range,
        function(v) S.Role.AutoShoot.Range = v end)
    CreateToggle("🎯 Silent Aim", S.Role.SilentAim.Enabled,
        function(v) S.Role.SilentAim.Enabled = v end)
    CreateInput("  FOV Size", S.Role.SilentAim.FOV,
        function(v) S.Role.SilentAim.FOV = v end)
end

local function LoadUtil()
    ClearPanel()
    MakeSection("🛠  UTILITIES")
    CreateToggle("💎 Auto Collect", S.Util.AutoCollect.Enabled,
        function(v) S.Util.AutoCollect.Enabled = v end)
    CreateInput("  Collect Range", S.Util.AutoCollect.Range,
        function(v) S.Util.AutoCollect.Range = v end)
    CreateToggle("🏃 Walk Speed", S.Util.WalkSpeed.Enabled,
        function(v)
            S.Util.WalkSpeed.Enabled = v
            if not v then
                local c = LocalPlayer.Character
                if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = 16 end
            end
        end)
    CreateInput("  Speed Value", S.Util.WalkSpeed.Speed,
        function(v) S.Util.WalkSpeed.Speed = v end)
    CreateToggle("🦘 Jump Power", S.Util.JumpPower.Enabled,
        function(v)
            S.Util.JumpPower.Enabled = v
            if not v then
                local c = LocalPlayer.Character
                if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower = 50 end
            end
        end)
    CreateInput("  Jump Value", S.Util.JumpPower.Power,
        function(v) S.Util.JumpPower.Power = v end)
    CreateToggle("📏 Reach", S.Util.Reach.Enabled,
        function(v) S.Util.Reach.Enabled = v end)
    CreateInput("  Reach Range", S.Util.Reach.Range,
        function(v) S.Util.Reach.Range = v end)

    -- X-RAY with improved description
    CreateToggle("👁 X-Ray  (walls see-thru)", S.Util.XRay.Enabled,
        function(v)
            S.Util.XRay.Enabled = v
            if not v then
                -- Restore immediately
                for obj, orig in pairs(OriginalTransparency) do
                    if obj and obj.Parent then obj.Transparency = orig end
                end
                OriginalTransparency = {}
                XRayCache = {}
                XRayCacheTimer = 0
            else
                -- Rebuild cache immediately on enable
                XRayCacheTimer = XRayCacheInterval
            end
        end)

    CreateToggle("🚫 No Clip", S.Util.NoClip.Enabled,
        function(v) S.Util.NoClip.Enabled = v end)
end

local function LoadESP()
    ClearPanel()
    MakeSection("📡  ESP")
    CreateToggle("✅ Enable ESP", S.ESP.Enabled,
        function(v)
            S.ESP.Enabled = v
            if not v then
                for _, data in pairs(ESPObjects) do
                    for _, d in pairs(data) do pcall(function() d.Visible = false end) end
                end
            end
        end)
    CreateToggle("Show Murderer", S.ESP.ShowMurderer, function(v) S.ESP.ShowMurderer = v end)
    CreateToggle("Show Sheriff",  S.ESP.ShowSheriff,  function(v) S.ESP.ShowSheriff  = v end)
    CreateToggle("Show Others",   S.ESP.ShowOthers,   function(v) S.ESP.ShowOthers   = v end)
    CreateToggle("Draw Box",      S.ESP.Box,           function(v) S.ESP.Box      = v end)
    CreateToggle("Draw Name",     S.ESP.Name,          function(v) S.ESP.Name     = v end)
    CreateToggle("Draw Distance", S.ESP.Distance,      function(v) S.ESP.Distance = v end)
end

-- ============================================================
--  SKIN INJECTOR CATEGORY
-- ============================================================
local function LoadSkin()
    ClearPanel()
    MakeSection("🎨  VISUAL SKIN INJECTOR  (only YOU see this)")

    -- Info row
    local infoRow = MakeRow(30)
    infoRow.BackgroundColor3 = Color3.fromRGB(20, 40, 80)
    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(1, -10, 1, 0)
    infoLbl.Position = UDim2.new(0, 8, 0, 0)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text = "ℹ  Colors apply to your knife/gun visually on your screen only"
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 10
    infoLbl.TextColor3 = T.Accent
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.TextWrapped = true
    infoLbl.Parent = infoRow

    MakeSection("🔪  KNIFE SKIN")
    CreateToggle("Enable Knife Skin", S.Skin.KnifeEnabled, function(v)
        S.Skin.KnifeEnabled = v
        if not v then RestoreSkin("Knife") end
    end)
    CreateDropdown("Knife Skin", KNIFE_SKINS,
        function() return S.Skin.KnifeSkin end,
        function(v)
            S.Skin.KnifeSkin = v
            if S.Skin.KnifeEnabled then
                ApplySkinToTool("Knife", v)
            end
        end)

    -- Knife color preview
    skinPreviewKnife = CreateColorSwatch(GetSkinColor(S.Skin.KnifeSkin))

    -- Apply knife now button
    local applyKnifeRow = MakeRow(34)
    local applyKnifeBtn = Instance.new("TextButton")
    applyKnifeBtn.Size = UDim2.new(0.9, 0, 0, 26)
    applyKnifeBtn.Position = UDim2.new(0.05, 0, 0.5, -13)
    applyKnifeBtn.BackgroundColor3 = T.Accent
    applyKnifeBtn.Text = "🔪  Apply Knife Skin Now"
    applyKnifeBtn.Font = Enum.Font.GothamBold
    applyKnifeBtn.TextSize = 11
    applyKnifeBtn.TextColor3 = T.Text
    applyKnifeBtn.Parent = applyKnifeRow
    Instance.new("UICorner", applyKnifeBtn).CornerRadius = UDim.new(0, 5)
    applyKnifeBtn.MouseButton1Click:Connect(function()
        local ok = ApplySkinToTool("Knife", S.Skin.KnifeSkin)
        if skinPreviewKnife then skinPreviewKnife.BackgroundColor3 = GetSkinColor(S.Skin.KnifeSkin) end
        local n = ok and ("Applied " .. S.Skin.KnifeSkin .. " skin to Knife!") or "Knife not found in inventory!"
        pcall(function() StarterGui:SetCore("SendNotification", {Title="Skin Injector", Text=n, Duration=2}) end)
    end)

    MakeSection("🔫  GUN SKIN")
    CreateToggle("Enable Gun Skin", S.Skin.GunEnabled, function(v)
        S.Skin.GunEnabled = v
        if not v then
            RestoreSkin("Sheriff Gun")
            RestoreSkin("Gun")
        end
    end)
    CreateDropdown("Gun Skin", GUN_SKINS,
        function() return S.Skin.GunSkin end,
        function(v)
            S.Skin.GunSkin = v
            if S.Skin.GunEnabled then
                ApplySkinToTool("Sheriff Gun", v)
                ApplySkinToTool("Gun", v)
            end
        end)

    skinPreviewGun = CreateColorSwatch(GetSkinColor(S.Skin.GunSkin))

    local applyGunRow = MakeRow(34)
    local applyGunBtn = Instance.new("TextButton")
    applyGunBtn.Size = UDim2.new(0.9, 0, 0, 26)
    applyGunBtn.Position = UDim2.new(0.05, 0, 0.5, -13)
    applyGunBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
    applyGunBtn.Text = "🔫  Apply Gun Skin Now"
    applyGunBtn.Font = Enum.Font.GothamBold
    applyGunBtn.TextSize = 11
    applyGunBtn.TextColor3 = T.Text
    applyGunBtn.Parent = applyGunRow
    Instance.new("UICorner", applyGunBtn).CornerRadius = UDim.new(0, 5)
    applyGunBtn.MouseButton1Click:Connect(function()
        local ok1 = ApplySkinToTool("Sheriff Gun", S.Skin.GunSkin)
        local ok2 = ApplySkinToTool("Gun", S.Skin.GunSkin)
        if skinPreviewGun then skinPreviewGun.BackgroundColor3 = GetSkinColor(S.Skin.GunSkin) end
        local n = (ok1 or ok2) and ("Applied " .. S.Skin.GunSkin .. " to Gun!") or "Gun not found in inventory!"
        pcall(function() StarterGui:SetCore("SendNotification", {Title="Skin Injector", Text=n, Duration=2}) end)
    end)

    MakeSection("🔄  RESET SKINS")
    local resetRow = MakeRow(34)
    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(0.9, 0, 0, 26)
    resetBtn.Position = UDim2.new(0.05, 0, 0.5, -13)
    resetBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 60)
    resetBtn.Text = "↩  Reset All Skins to Default"
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 11
    resetBtn.TextColor3 = T.Text
    resetBtn.Parent = resetRow
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 5)
    resetBtn.MouseButton1Click:Connect(function()
        RestoreSkin("Knife")
        RestoreSkin("Sheriff Gun")
        RestoreSkin("Gun")
        OriginalSkinColors = {}
        pcall(function() StarterGui:SetCore("SendNotification", {Title="Skin Injector", Text="Skins reset to default.", Duration=2}) end)
    end)
end

-- ============================================================
--  SIDEBAR CATEGORY BUTTONS  (fixed switching)
-- ============================================================
local catLoaders = {
    Role = LoadRole,
    Util = LoadUtil,
    ESP  = LoadESP,
    Skin = LoadSkin,
}

local function CreateCatBtn(icon, label, key, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 36)
    btn.BackgroundColor3 = T.Card
    btn.Text = ""
    btn.LayoutOrder = order
    btn.Parent = SideList
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local iconL = Instance.new("TextLabel")
    iconL.Size = UDim2.new(0, 28, 1, 0)
    iconL.Position = UDim2.new(0, 6, 0, 0)
    iconL.BackgroundTransparency = 1
    iconL.Text = icon
    iconL.TextSize = 15
    iconL.Parent = btn

    local nameL = Instance.new("TextLabel")
    nameL.Size = UDim2.new(1, -38, 1, 0)
    nameL.Position = UDim2.new(0, 36, 0, 0)
    nameL.BackgroundTransparency = 1
    nameL.Text = label
    nameL.Font = Enum.Font.GothamSemibold
    nameL.TextSize = 11
    nameL.TextColor3 = T.Sub
    nameL.TextXAlignment = Enum.TextXAlignment.Left
    nameL.Parent = btn

    btn.MouseButton1Click:Connect(function()
        -- Deselect old
        if ActiveCatBtn and ActiveCatBtn ~= btn then
            ActiveCatBtn.BackgroundColor3 = T.Card
        end
        if ActiveCatNameLbl and ActiveCatNameLbl ~= nameL then
            ActiveCatNameLbl.TextColor3 = T.Sub
        end
        -- Select new
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

local btn1, lbl1 = CreateCatBtn("⚔",  "Role Features", "Role", 1)
local btn2, lbl2 = CreateCatBtn("🛠",  "Utilities",     "Util", 2)
local btn3, lbl3 = CreateCatBtn("📡", "ESP",           "ESP",  3)
local btn4, lbl4 = CreateCatBtn("🎨", "Skin Injector", "Skin", 4)

-- Default select Role
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
FOVCircle.Color = Color3.fromRGB(255, 100, 100)
FOVCircle.Transparency = 0.6
FOVCircle.Filled = false

-- ============================================================
--  ROLE DETECTION
-- ============================================================
local function GetPlayerRole(p)
    if p.Team then
        local tn = p.Team.Name:lower()
        if tn:find("murder")   then return "Murderer" end
        if tn:find("sheriff")  then return "Sheriff"  end
        if tn:find("innocent") then return "Innocent" end
    end
    local ls = p:FindFirstChild("leaderstats")
    if ls then
        local role = ls:FindFirstChild("Role") or ls:FindFirstChild("role")
        if role then
            local rv = tostring(role.Value):lower()
            if rv:find("murder")  then return "Murderer" end
            if rv:find("sheriff") then return "Sheriff"  end
        end
    end
    if p.Character then
        if p.Character:FindFirstChild("Knife") then return "Murderer" end
        if p.Character:FindFirstChild("Sheriff Gun") or p.Character:FindFirstChild("Gun") then return "Sheriff" end
    end
    return "Innocent"
end

-- ============================================================
--  SILENT AIM
-- ============================================================
local function GetClosestInFOV()
    local best, bestDist = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local pos, vis = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if vis then
                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if d < S.Role.SilentAim.FOV and d < bestDist then
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
        local e = {
            Box  = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Dist = Drawing.new("Text"),
        }
        e.Box.Filled = false
        e.Box.Thickness = 1.5
        e.Name.Size = 14; e.Name.Center = true; e.Name.Outline = true
        e.Dist.Size = 12; e.Dist.Center = true; e.Dist.Outline = true
        ESPObjects[p] = e
    end
    return ESPObjects[p]
end

local function HideESP(data)
    if not data then return end
    for _, d in pairs(data) do pcall(function() d.Visible = false end) end
end

Players.PlayerRemoving:Connect(function(p)
    if ESPObjects[p] then
        for _, d in pairs(ESPObjects[p]) do pcall(function() d:Remove() end) end
        ESPObjects[p] = nil
    end
end)

-- ============================================================
--  MAIN HEARTBEAT LOOP
-- ============================================================
local heartbeatStep = 0  -- used to alternate heavy tasks

RunService.Heartbeat:Connect(function(dt)
    local char = LocalPlayer.Character
    if not char then return end
    local Root = char:FindFirstChild("HumanoidRootPart")
    local Hum  = char:FindFirstChild("Humanoid")
    if not Root or not Hum or Hum.Health <= 0 then return end

    heartbeatStep += 1

    -- WALK SPEED
    if S.Util.WalkSpeed.Enabled then Hum.WalkSpeed = S.Util.WalkSpeed.Speed end

    -- JUMP POWER
    if S.Util.JumpPower.Enabled then Hum.JumpPower = S.Util.JumpPower.Power end

    -- NO CLIP
    if S.Util.NoClip.Enabled then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end

    -- ========================================================
    --  X-RAY  FIXED: throttled + part cache
    --  Only rebuilds part list every 3s, only runs every 4 frames
    -- ========================================================
    if S.Util.XRay.Enabled then
        XRayCacheTimer += dt

        -- Rebuild cache every XRayCacheInterval seconds
        if XRayCacheTimer >= XRayCacheInterval then
            XRayCacheTimer = 0
            XRayCache = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj:IsDescendantOf(char) then
                    -- Only cache solid walls/floors (skip tiny parts & character parts)
                    if obj.Size.Magnitude > 2 then
                        table.insert(XRayCache, obj)
                    end
                end
            end
        end

        -- Apply xray only every 4 heartbeat frames to avoid lag
        if heartbeatStep % 4 == 0 then
            local tgt = S.Util.XRay.Transparency
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
    if S.Util.AutoCollect.Enabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.CanCollide then
                local n = obj.Name
                if n == "Knife" or n == "Gun" or n:find("Coin") or n == "Medkit" then
                    if (Root.Position - obj.Position).Magnitude < S.Util.AutoCollect.Range then
                        Root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0))
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
    if S.Role.AutoStab.Enabled and myRole == "Murderer" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local pHum  = p.Character:FindFirstChild("Humanoid")
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if pHum and pRoot and pHum.Health > 0 then
                    if (Root.Position - pRoot.Position).Magnitude < S.Role.AutoStab.Range
                    and GetPlayerRole(p) ~= "Murderer" then
                        pcall(function()
                            local knife = char:FindFirstChild("Knife")
                                or LocalPlayer.Backpack:FindFirstChild("Knife")
                            if knife then
                                if knife.Parent == LocalPlayer.Backpack then
                                    Hum:EquipTool(knife)
                                end
                                Root.CFrame = CFrame.new(Root.Position, pRoot.Position)
                                knife:Activate()
                            end
                        end)
                    end
                end
            end
        end
    end

    -- AUTO SHOOT
    if S.Role.AutoShoot.Enabled and myRole == "Sheriff" and Murderer then
        local mRoot = Murderer.Character and Murderer.Character:FindFirstChild("HumanoidRootPart")
        local mHum  = Murderer.Character and Murderer.Character:FindFirstChild("Humanoid")
        if mRoot and mHum and mHum.Health > 0 then
            if (Root.Position - mRoot.Position).Magnitude < S.Role.AutoShoot.Range then
                pcall(function()
                    local gun = char:FindFirstChild("Sheriff Gun")
                        or char:FindFirstChild("Gun")
                        or LocalPlayer.Backpack:FindFirstChild("Sheriff Gun")
                        or LocalPlayer.Backpack:FindFirstChild("Gun")
                    if gun then
                        if gun.Parent == LocalPlayer.Backpack then Hum:EquipTool(gun) end
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, mRoot.Position)
                        gun:Activate()
                    end
                end)
            end
        end
    end

    -- REACH
    if S.Util.Reach.Enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if pRoot and (Root.Position - pRoot.Position).Magnitude < S.Util.Reach.Range then
                    local dir = (pRoot.Position - Root.Position).Unit
                    Root.CFrame = Root.CFrame + dir * 0.5
                end
            end
        end
    end

    -- SKIN: keep reapplying every 30 frames so equip changes don't lose skin
    if heartbeatStep % 30 == 0 then
        if S.Skin.KnifeEnabled then
            ApplySkinToTool("Knife", S.Skin.KnifeSkin)
        end
        if S.Skin.GunEnabled then
            ApplySkinToTool("Sheriff Gun", S.Skin.GunSkin)
            ApplySkinToTool("Gun",         S.Skin.GunSkin)
        end
        -- Rainbow hue cycle
        rainbowHue = (rainbowHue + 0.02) % 1
    end
end)

-- ============================================================
--  RENDER STEPPED: Silent Aim + ESP
-- ============================================================
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local Root = char and char:FindFirstChild("HumanoidRootPart")

    -- SILENT AIM
    if S.Role.SilentAim.Enabled then
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Position = center
        FOVCircle.Radius   = S.Role.SilentAim.FOV
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
        if (role == "Murderer" and not S.ESP.ShowMurderer)
        or (role == "Sheriff"  and not S.ESP.ShowSheriff)
        or (role == "Innocent" and not S.ESP.ShowOthers) then
            HideESP(ESPObjects[p]) continue
        end

        local pos, vis = Camera:WorldToViewportPoint(pRoot.Position)
        if not vis then HideESP(ESPObjects[p]) continue end

        local e = GetOrMakeESP(p)
        local col = role == "Murderer" and Color3.fromRGB(255,60,60)
                 or role == "Sheriff"  and Color3.fromRGB(60,220,100)
                 or                        Color3.fromRGB(220,220,220)
        local szX, szY = 2200/pos.Z, 3000/pos.Z
        local scr = Vector2.new(pos.X, pos.Y)

        e.Box.Visible = S.ESP.Box
        e.Box.Position = Vector2.new(scr.X - szX/2, scr.Y - szY/2)
        e.Box.Size = Vector2.new(szX, szY)
        e.Box.Color = col
        e.Box.Transparency = 0.5

        e.Name.Visible = S.ESP.Name
        e.Name.Position = Vector2.new(scr.X, scr.Y - szY/2 - 18)
        e.Name.Text = string.format("[%s] %s", role, p.Name)
        e.Name.Color = col

        if Root then
            e.Dist.Visible = S.ESP.Distance
            e.Dist.Position = Vector2.new(scr.X, scr.Y + szY/2 + 6)
            e.Dist.Text = string.format("%.0f studs", (Root.Position - pRoot.Position).Magnitude)
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

task.delay(0.5, function()
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "✨ Hans Hub v3.1",
            Text  = "Loaded! INSERT to toggle. Skin Injector added!",
            Duration = 4,
        })
    end)
end)