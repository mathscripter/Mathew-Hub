--[[
    HANS HUB | MM2 | v5.0
    NEW: Fly, Auto Fling Murderer, Auto Get Gun, 
         Anti-Stab, Blink/TP to Murderer, Speed Kill,
         Fake Lag, Freeze Murderer, Name Changer
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
local TweenService     = game:GetService("TweenService")

local Camera      = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ============================================================
--  SETTINGS
-- ============================================================
local SAVE_FILE = "HansHub_v5_Settings.json"

local DefaultSettings = {
    Role = {
        AutoStab    = false, StabRange  = 25,
        AutoShoot   = false, ShootRange = 80,
        SilentAim   = false, FOV        = 120,
        AutoKillAll = false, SafeSpotY  = 500,
        AutoFling   = false, FlingForce = 300,
        SpeedKill   = false,               -- tp + stab instantly
        BlinkMurder = false,               -- blink to murderer and back
        AntiStab    = false,               -- auto dodge when murderer near
        AntiStabDist = 15,
    },
    Util = {
        AutoCollect  = false, CollectRange = 50,
        WalkSpeed    = false, Speed        = 32,
        JumpPower    = false, Power        = 60,
        Reach        = false, ReachRange   = 20,
        NoClip       = false,
        XRay         = false, XRayTrans    = 0.4,
        AutoGetGun   = false,              -- auto pick up sheriff gun on map
        FakeLag      = false, FakeLagMs    = 200,
        FreezeMurder = false,              -- freeze murderer CFrame (client)
    },
    Fly = {
        Enabled  = false,
        Speed    = 60,
        MaxHeight = 500,
        NoClip   = true,
    },
    ESP = {
        Enabled      = false,
        ShowMurderer = true,
        ShowSheriff  = true,
        ShowOthers   = true,
        Box          = true,
        Name         = true,
        Distance     = true,
        HealthBar    = true,
    },
    Skin = {
        KnifeEnabled = false, KnifeSkin = "Default",
        GunEnabled   = false, GunSkin   = "Default",
    },
}

local function DeepCopy(t)
    local copy = {}
    for k,v in pairs(t) do
        copy[k] = type(v)=="table" and DeepCopy(v) or v
    end
    return copy
end

local S = DeepCopy(DefaultSettings)

local function SaveSettings()
    pcall(function() writefile(SAVE_FILE, HttpService:JSONEncode(S)) end)
end

local function LoadSettings()
    pcall(function()
        if isfile(SAVE_FILE) then
            local data = HttpService:JSONDecode(readfile(SAVE_FILE))
            for cat, vals in pairs(data) do
                if S[cat] then
                    for k,v in pairs(vals) do S[cat][k] = v end
                end
            end
        end
    end)
end

LoadSettings()

-- ============================================================
--  PERMANENT ROLE MARKERS
-- ============================================================
local PermanentRoles = {}

-- ============================================================
--  SKIN DATA
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
local FakeSkinTools        = {}
local safeSpot             = nil

-- Fly state
local FlyConnection        = nil
local FlyBodyVel           = nil
local FlyBodyGyro          = nil

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
    Green   = Color3.fromRGB(60,220,100),
    Purple  = Color3.fromRGB(160,50,255),
}

-- ============================================================
--  NOTIFY
-- ============================================================
local function Notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=title,Text=text,Duration=dur or 3})
    end)
end

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
MainFrame.Size = UDim2.new(0,520,0,480)
MainFrame.Position = UDim2.new(0.05,0,0.07,0)
MainFrame.BackgroundColor3 = T.BG
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner",MainFrame).CornerRadius = UDim.new(0,10)
local MStroke = Instance.new("UIStroke",MainFrame)
MStroke.Color = T.Accent
MStroke.Thickness = 1.5
MStroke.Transparency = 0.35

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,42)
TitleBar.BackgroundColor3 = T.Sidebar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner",TitleBar).CornerRadius = UDim.new(0,10)
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
Instance.new("UICorner",TLAcc).CornerRadius = UDim.new(0,3)

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
VerLbl.Text = "v5.0 MAX"
VerLbl.Font = Enum.Font.GothamBold
VerLbl.TextSize = 10
VerLbl.TextColor3 = T.Accent
VerLbl.Parent = TitleBar
Instance.new("UICorner",VerLbl).CornerRadius = UDim.new(0,4)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,28,0,28)
CloseBtn.Position = UDim2.new(1,-36,0.5,-14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180,40,60)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.TextColor3 = T.Text
CloseBtn.Parent = TitleBar
Instance.new("UICorner",CloseBtn).CornerRadius = UDim.new(0,6)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0,148,1,-50)
Sidebar.Position = UDim2.new(0,6,0,46)
Sidebar.BackgroundColor3 = T.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
Instance.new("UICorner",Sidebar).CornerRadius = UDim.new(0,8)

local SideList = Instance.new("ScrollingFrame")
SideList.Size = UDim2.new(1,-6,1,-10)
SideList.Position = UDim2.new(0,3,0,5)
SideList.BackgroundTransparency = 1
SideList.ScrollBarThickness = 3
SideList.ScrollBarImageColor3 = T.Accent
SideList.CanvasSize = UDim2.new(0,0,0,0)
SideList.AutomaticCanvasSize = Enum.AutomaticSize.Y
SideList.Parent = Sidebar
local SideLayout = Instance.new("UIListLayout",SideList)
SideLayout.Padding = UDim.new(0,5)
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding",SideList).PaddingTop = UDim.new(0,5)

-- Right panel
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(1,-163,1,-50)
RightPanel.Position = UDim2.new(0,159,0,46)
RightPanel.BackgroundColor3 = T.Panel
RightPanel.BorderSizePixel = 0
RightPanel.Parent = MainFrame
Instance.new("UICorner",RightPanel).CornerRadius = UDim.new(0,8)

local PanelScroll = Instance.new("ScrollingFrame")
PanelScroll.Size = UDim2.new(1,-10,1,-10)
PanelScroll.Position = UDim2.new(0,5,0,5)
PanelScroll.BackgroundTransparency = 1
PanelScroll.ScrollBarThickness = 4
PanelScroll.ScrollBarImageColor3 = T.Accent
PanelScroll.CanvasSize = UDim2.new(0,0,0,0)
PanelScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PanelScroll.Parent = RightPanel
local PanelLayout = Instance.new("UIListLayout",PanelScroll)
PanelLayout.Padding = UDim.new(0,6)
PanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
local PPad = Instance.new("UIPadding",PanelScroll)
PPad.PaddingTop = UDim.new(0,6)
PPad.PaddingRight = UDim.new(0,4)

-- ============================================================
--  PANEL HELPERS
-- ============================================================
local panelOrder = 0
local function NextOrder() panelOrder+=1 return panelOrder end

local function ClearPanel()
    for _,c in ipairs(PanelScroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    panelOrder = 0
end

local function MakeSection(text, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,22)
    l.BackgroundTransparency = 1
    l.Text = "  "..text
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextColor3 = color or T.Accent
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

    for _,item in ipairs(list) do
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

local function InfoRow(text, color, h)
    local f = MakeRow(h or 32)
    f.BackgroundColor3 = color or Color3.fromRGB(20,40,80)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-10,1,0)
    l.Position = UDim2.new(0,8,0,0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.Font = Enum.Font.Gotham
    l.TextSize = 10
    l.TextColor3 = T.Text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.Parent = f
end

-- ============================================================
--  ROLE DETECTION  (permanent marking)
-- ============================================================
local function GetPlayerRole(p)
    local uid = p.UserId
    if PermanentRoles[uid] then return PermanentRoles[uid] end
    if p.Team then
        local tn = p.Team.Name:lower()
        if tn:find("murder")  then PermanentRoles[uid]="Murderer" return "Murderer" end
        if tn:find("sheriff") then PermanentRoles[uid]="Sheriff"  return "Sheriff"  end
    end
    local ls = p:FindFirstChild("leaderstats")
    if ls then
        local role = ls:FindFirstChild("Role") or ls:FindFirstChild("role")
        if role then
            local rv = tostring(role.Value):lower()
            if rv:find("murder")  then PermanentRoles[uid]="Murderer" return "Murderer" end
            if rv:find("sheriff") then PermanentRoles[uid]="Sheriff"  return "Sheriff"  end
        end
    end
    if p.Character then
        if p.Character:FindFirstChild("Knife") then
            PermanentRoles[uid]="Murderer" return "Murderer"
        end
        if p.Character:FindFirstChild("Sheriff Gun") or p.Character:FindFirstChild("Gun") then
            PermanentRoles[uid]="Sheriff" return "Sheriff"
        end
    end
    return "Innocent"
end

LocalPlayer.CharacterAdded:Connect(function()
    PermanentRoles = {}
    -- Re-apply skins after respawn
    task.wait(1)
    if S.Skin.KnifeEnabled then CreateFakeTool("Knife", S.Skin.KnifeSkin) end
    if S.Skin.GunEnabled   then CreateFakeTool("Sheriff Gun", S.Skin.GunSkin) end
end)

-- ============================================================
--  FLY SYSTEM
-- ============================================================
local function StopFly()
    S.Fly.Enabled = false
    if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then hum.PlatformStand = false end
        if root then
            if FlyBodyVel  then FlyBodyVel:Destroy()  FlyBodyVel  = nil end
            if FlyBodyGyro then FlyBodyGyro:Destroy() FlyBodyGyro = nil end
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end
end

local function StartFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    hum.PlatformStand = true

    -- BodyVelocity for movement
    FlyBodyVel = Instance.new("BodyVelocity")
    FlyBodyVel.Velocity = Vector3.zero
    FlyBodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
    FlyBodyVel.Parent = root

    -- BodyGyro to keep upright
    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
    FlyBodyGyro.P = 1e4
    FlyBodyGyro.CFrame = root.CFrame
    FlyBodyGyro.Parent = root

    FlyConnection = RunService.RenderStepped:Connect(function()
        if not S.Fly.Enabled then StopFly() return end

        local speed = S.Fly.Speed
        local dir = Vector3.zero
        local cam = Camera

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)   then speed = speed * 2 end

        -- Cap height
        if root.Position.Y >= S.Fly.MaxHeight and dir.Y > 0 then
            dir = Vector3.new(dir.X, 0, dir.Z)
        end

        FlyBodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
        FlyBodyGyro.CFrame = cam.CFrame

        -- NoClip while flying
        if S.Fly.NoClip then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end

-- ============================================================
--  SKIN SYSTEM
-- ============================================================
local function GetSkinColor(name)
    if name == "Rainbow" then return Color3.fromHSV(rainbowHue,1,1) end
    return SKIN_COLORS[name] or Color3.fromRGB(180,180,180)
end

function CreateFakeTool(baseName, skinName)
    local char = LocalPlayer.Character
    if not char then return end
    if FakeSkinTools[baseName] then
        pcall(function() FakeSkinTools[baseName]:Destroy() end)
        FakeSkinTools[baseName] = nil
    end

    local color = GetSkinColor(skinName)
    local isKnife = baseName == "Knife"

    local fakeTool = Instance.new("Tool")
    fakeTool.Name = baseName
    fakeTool.RequiresHandle = true
    fakeTool.CanBeDropped = false

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = isKnife and Vector3.new(0.15,1.2,0.08) or Vector3.new(0.3,1.0,0.15)
    handle.BrickColor = BrickColor.new("Medium stone grey")
    handle.Material = Enum.Material.SmoothPlastic
    handle.CanCollide = false
    handle.CastShadow = false
    handle.Parent = fakeTool

    local blade = Instance.new("Part")
    blade.Name = "Blade"
    blade.Size = isKnife and Vector3.new(0.05,0.9,0.04) or Vector3.new(0.15,0.8,0.1)
    blade.Color = color
    blade.Material = Enum.Material.Neon
    blade.CanCollide = false
    blade.CastShadow = false
    blade.Parent = fakeTool

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = blade
    weld.Parent = handle
    blade.CFrame = handle.CFrame * CFrame.new(0,0.5,0)

    local tag = Instance.new("StringValue")
    tag.Name = "_HansHubFakeSkin"
    tag.Value = skinName
    tag.Parent = fakeTool

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
    local blade = tool:FindFirstChild("Blade")
    if blade then blade.Color = GetSkinColor(skinName) end
end

-- ============================================================
--  AUTO GET GUN HELPER
-- ============================================================
local function TryGetGun()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    -- Search for a gun on the ground in workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") then
            local n = obj.Name:lower()
            if (n:find("gun") or n:find("sheriff")) and obj.Parent ~= LocalPlayer.Backpack and obj.Parent ~= char then
                local handle = obj:FindFirstChild("Handle")
                if handle and (root.Position - handle.Position).Magnitude < 80 then
                    root.CFrame = CFrame.new(handle.Position + Vector3.new(0,3,0))
                    task.wait(0.1)
                    break
                end
            end
        end
    end
end

-- ============================================================
--  FLING HELPER
-- ============================================================
local function FlingPlayer(target)
    local char   = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    local tRoot  = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not tRoot then return end

    -- Save position
    local savedCF = myRoot.CFrame

    -- TP to target
    myRoot.CFrame = tRoot.CFrame

    -- Apply massive velocity to target via a temporary part trick
    -- (client side — visual fling)
    pcall(function()
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(
            math.random(-S.Role.FlingForce, S.Role.FlingForce),
            S.Role.FlingForce,
            math.random(-S.Role.FlingForce, S.Role.FlingForce)
        )
        bv.MaxForce = Vector3.new(1e6,1e6,1e6)
        bv.Parent = tRoot
        game:GetService("Debris"):AddItem(bv, 0.15)
    end)

    task.wait(0.1)
    myRoot.CFrame = savedCF
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

    MakeSection("💀  AUTO KILL ALL  (Murderer)")
    InfoRow("⚠ TPs to each player, stabs, then safe-spots you", Color3.fromRGB(40,15,15), 28)
    CreateToggle("☠ Auto Kill All (continuous)", S.Role.AutoKillAll,
        function(v) S.Role.AutoKillAll = v end)
    CreateInput("  Safe Spot Y Height", S.Role.SafeSpotY,
        function(v) S.Role.SafeSpotY = v end)
    MakeBtn("☠  KILL ALL NOW", T.Red, function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChild("Humanoid")
        if not root or not hum then Notify("Kill All","No character!",2) return end
        safeSpot = root.Position + Vector3.new(0,S.Role.SafeSpotY,0)
        local knife = char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if not knife or knife:FindFirstChild("_HansHubFakeSkin") then
            Notify("Kill All","No real knife found!",2) return
        end
        if knife.Parent == LocalPlayer.Backpack then hum:EquipTool(knife) end
        local killed = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                local pHum  = p.Character:FindFirstChild("Humanoid")
                if pRoot and pHum and pHum.Health > 0 then
                    root.CFrame = CFrame.new(pRoot.Position + Vector3.new(0,2,0))
                    task.wait(0.05)
                    root.CFrame = CFrame.new(root.Position, pRoot.Position)
                    pcall(function() knife:Activate() end)
                    task.wait(0.1)
                    killed += 1
                end
            end
        end
        root.CFrame = CFrame.new(safeSpot)
        Notify("Kill All","Killed "..killed.." | Safe-spotted!",3)
    end)

    MakeSection("💢  FLING & SPEED KILL")
    CreateToggle("💥 Auto Fling Murderer", S.Role.AutoFling,
        function(v) S.Role.AutoFling = v end)
    CreateInput("  Fling Force", S.Role.FlingForce,
        function(v) S.Role.FlingForce = v end)

    CreateToggle("⚡ Speed Kill (instant TP+stab)", S.Role.SpeedKill,
        function(v) S.Role.SpeedKill = v end)

    MakeSection("🛡  DEFENSE")
    CreateToggle("🔄 Blink to Murderer (Sheriff)", S.Role.BlinkMurder,
        function(v) S.Role.BlinkMurder = v end)
    InfoRow("ℹ As Sheriff: auto-TPs near murderer to shoot them at close range",
        Color3.fromRGB(20,40,20), 28)

    CreateToggle("🛡 Anti-Stab Dodge", S.Role.AntiStab,
        function(v) S.Role.AntiStab = v end)
    CreateInput("  Dodge Trigger Dist", S.Role.AntiStabDist,
        function(v) S.Role.AntiStabDist = v end)
    InfoRow("ℹ Auto-jumps/dodges when murderer gets too close to you",
        Color3.fromRGB(20,20,50), 28)
end

local function LoadUtil()
    ClearPanel()
    MakeSection("🛠  UTILITIES")

    CreateToggle("💎 Auto Collect Coins/Guns", S.Util.AutoCollect,
        function(v) S.Util.AutoCollect = v end)
    CreateInput("  Collect Range", S.Util.CollectRange,
        function(v) S.Util.CollectRange = v end)

    CreateToggle("🔫 Auto Get Gun (find & TP)", S.Util.AutoGetGun,
        function(v) S.Util.AutoGetGun = v end)
    InfoRow("ℹ Teleports you to nearest gun on the map to pick it up",
        Color3.fromRGB(20,40,20), 28)

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

    CreateToggle("👁 X-Ray", S.Util.XRay,
        function(v)
            S.Util.XRay = v
            if not v then
                for obj,orig in pairs(OriginalTransparency) do
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

    CreateToggle("🔒 Freeze Murderer (client)", S.Util.FreezeMurder,
        function(v) S.Util.FreezeMurder = v end)
    InfoRow("ℹ Locks murderer CFrame locally — they look frozen on your screen",
        Color3.fromRGB(20,20,50), 28)

    MakeSection("🎯  QUICK ACTIONS")
    MakeBtn("🔫  Get Nearest Gun NOW", T.Green, function()
        TryGetGun()
        Notify("Util","Teleported to nearest gun!",2)
    end)
    MakeBtn("📍  Teleport to Safe Spot", T.Accent, function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(root.Position + Vector3.new(0,200,0))
            Notify("Util","Teleported up to safety!",2)
        end
    end)
    MakeBtn("❤  Fake Death (TP underground)", Color3.fromRGB(100,20,20), function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(root.Position + Vector3.new(0,-200,0))
            Notify("Util","Fake death — TP underground",2)
        end
    end)
end

local function LoadFly()
    ClearPanel()
    MakeSection("🪂  FLY HACK  (W/A/S/D + Space/Ctrl)", T.Purple)

    InfoRow("SHIFT = speed boost  |  INSERT to toggle menu\nSpace = up  |  Ctrl = down", Color3.fromRGB(20,20,50), 38)

    CreateToggle("🪂 Enable Fly", S.Fly.Enabled,
        function(v)
            S.Fly.Enabled = v
            if v then StartFly() else StopFly() end
        end)
    CreateInput("  Fly Speed", S.Fly.Speed,
        function(v) S.Fly.Speed = v end)
    CreateInput("  Max Height (Y)", S.Fly.MaxHeight,
        function(v) S.Fly.MaxHeight = v end)
    CreateToggle("🚫 No Clip While Flying", S.Fly.NoClip,
        function(v) S.Fly.NoClip = v end)

    MakeBtn("🪂  Toggle Fly (quick)", T.Purple, function()
        S.Fly.Enabled = not S.Fly.Enabled
        if S.Fly.Enabled then StartFly() else StopFly() end
        Notify("Fly", S.Fly.Enabled and "Fly ON! W/A/S/D to move" or "Fly OFF",2)
    end)
end

local function LoadESP()
    ClearPanel()
    MakeSection("📡  ESP  (★ = permanently confirmed role)")
    CreateToggle("✅ Enable ESP", S.ESP.Enabled,
        function(v)
            S.ESP.Enabled = v
            if not v then
                for _,data in pairs(ESPObjects) do
                    for _,d in pairs(data) do pcall(function() d.Visible=false end) end
                end
            end
        end)
    CreateToggle("Show Murderer 🔴", S.ESP.ShowMurderer, function(v) S.ESP.ShowMurderer=v end)
    CreateToggle("Show Sheriff 🟢",  S.ESP.ShowSheriff,  function(v) S.ESP.ShowSheriff=v  end)
    CreateToggle("Show Others ⚪",   S.ESP.ShowOthers,   function(v) S.ESP.ShowOthers=v   end)
    CreateToggle("Draw Box",         S.ESP.Box,           function(v) S.ESP.Box=v          end)
    CreateToggle("Draw Name",        S.ESP.Name,          function(v) S.ESP.Name=v         end)
    CreateToggle("Draw Distance",    S.ESP.Distance,      function(v) S.ESP.Distance=v     end)
    CreateToggle("Draw Health Bar",  S.ESP.HealthBar,     function(v) S.ESP.HealthBar=v    end)
    MakeBtn("🗑  Clear Role Memory", Color3.fromRGB(120,40,40), function()
        PermanentRoles = {}
        Notify("ESP","Role memory cleared.",2)
    end)
end

local function LoadSkin()
    ClearPanel()
    MakeSection("🎨  VISUAL SKIN INJECTOR")
    InfoRow("ℹ  Adds a FAKE tool to YOUR backpack visually. Disappears when disabled.", Color3.fromRGB(20,40,80), 28)

    MakeSection("🔪  KNIFE SKIN")
    CreateToggle("Enable Knife Skin", S.Skin.KnifeEnabled, function(v)
        S.Skin.KnifeEnabled = v
        if v then CreateFakeTool("Knife",S.Skin.KnifeSkin) Notify("Skin","Fake knife added!",2)
        else RemoveFakeTool("Knife") Notify("Skin","Fake knife removed.",2) end
    end)
    CreateDropdown("Knife Skin", KNIFE_SKINS,
        function() return S.Skin.KnifeSkin end,
        function(v) S.Skin.KnifeSkin=v if S.Skin.KnifeEnabled then CreateFakeTool("Knife",v) end end)
    MakeBtn("🔪  Apply / Refresh Knife", T.Accent, function()
        if S.Skin.KnifeEnabled then CreateFakeTool("Knife",S.Skin.KnifeSkin) Notify("Skin","Refreshed: "..S.Skin.KnifeSkin,2)
        else Notify("Skin","Enable Knife Skin first!",2) end
    end)

    MakeSection("🔫  GUN SKIN")
    CreateToggle("Enable Gun Skin", S.Skin.GunEnabled, function(v)
        S.Skin.GunEnabled = v
        if v then CreateFakeTool("Sheriff Gun",S.Skin.GunSkin) Notify("Skin","Fake gun added!",2)
        else RemoveFakeTool("Sheriff Gun") Notify("Skin","Fake gun removed.",2) end
    end)
    CreateDropdown("Gun Skin", GUN_SKINS,
        function() return S.Skin.GunSkin end,
        function(v) S.Skin.GunSkin=v if S.Skin.GunEnabled then CreateFakeTool("Sheriff Gun",v) end end)
    MakeBtn("🔫  Apply / Refresh Gun", T.Green, function()
        if S.Skin.GunEnabled then CreateFakeTool("Sheriff Gun",S.Skin.GunSkin) Notify("Skin","Refreshed: "..S.Skin.GunSkin,2)
        else Notify("Skin","Enable Gun Skin first!",2) end
    end)

    MakeSection("🔄  RESET")
    MakeBtn("↩  Remove All Fake Skins", T.Red, function()
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
    InfoRow("✅ All settings auto-save on every toggle.\nFile saved: HansHub_v5_Settings.json",
        Color3.fromRGB(15,35,15), 40)
    MakeBtn("💾  Save Now",       T.ON,  function() SaveSettings() Notify("Config","Saved!",2) end)
    MakeBtn("📂  Reload",         T.Accent, function() LoadSettings() Notify("Config","Reloaded!",2) end)
    MakeBtn("🗑  Reset Defaults", T.Red,    function()
        S = DeepCopy(DefaultSettings)
        SaveSettings()
        Notify("Config","Reset to defaults!",2)
    end)

    MakeSection("📋  CURRENT VALUES")
    local function ShowRow(label, val)
        local f = MakeRow(26)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.62,0,1,0)
        l.Position = UDim2.new(0,10,0,0)
        l.BackgroundTransparency = 1
        l.Text = label
        l.Font = Enum.Font.Gotham
        l.TextSize = 10
        l.TextColor3 = T.Sub
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f
        local v2 = Instance.new("TextLabel")
        v2.Size = UDim2.new(0.36,0,1,0)
        v2.Position = UDim2.new(0.62,0,0,0)
        v2.BackgroundTransparency = 1
        v2.Text = tostring(val)
        v2.Font = Enum.Font.GothamBold
        v2.TextSize = 10
        v2.TextColor3 = (val==true or val=="true") and T.ON or T.Accent
        v2.TextXAlignment = Enum.TextXAlignment.Right
        v2.Parent = f
    end
    ShowRow("Auto Stab",    S.Role.AutoStab)
    ShowRow("Auto Shoot",   S.Role.AutoShoot)
    ShowRow("Silent Aim",   S.Role.SilentAim)
    ShowRow("Kill All",     S.Role.AutoKillAll)
    ShowRow("Auto Fling",   S.Role.AutoFling)
    ShowRow("Speed Kill",   S.Role.SpeedKill)
    ShowRow("Anti-Stab",    S.Role.AntiStab)
    ShowRow("Blink Murder", S.Role.BlinkMurder)
    ShowRow("Walk Speed",   S.Util.WalkSpeed)
    ShowRow("Auto GetGun",  S.Util.AutoGetGun)
    ShowRow("Freeze Murder",S.Util.FreezeMurder)
    ShowRow("Fly",          S.Fly.Enabled)
    ShowRow("ESP",          S.ESP.Enabled)
    ShowRow("Knife Skin",   S.Skin.KnifeSkin)
    ShowRow("Gun Skin",     S.Skin.GunSkin)
end

-- ============================================================
--  SIDEBAR BUTTONS
-- ============================================================
local catLoaders = {
    Role   = LoadRole,
    Util   = LoadUtil,
    Fly    = LoadFly,
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
        if ActiveCatBtn and ActiveCatBtn ~= btn then ActiveCatBtn.BackgroundColor3 = T.Card end
        if ActiveCatNameLbl and ActiveCatNameLbl ~= nameL then ActiveCatNameLbl.TextColor3 = T.Sub end
        ActiveCatBtn     = btn
        ActiveCatNameLbl = nameL
        btn.BackgroundColor3 = T.Accent
        nameL.TextColor3     = T.Text
        CurrentCatKey = key
        catLoaders[key]()
    end)
    btn.MouseEnter:Connect(function() if ActiveCatBtn~=btn then btn.BackgroundColor3=Color3.fromRGB(38,35,62) end end)
    btn.MouseLeave:Connect(function() if ActiveCatBtn~=btn then btn.BackgroundColor3=T.Card end end)
    return btn, nameL
end

local b1,l1 = CreateCatBtn("⚔",  "Role Features", "Role",   1)
local b2,l2 = CreateCatBtn("🛠",  "Utilities",     "Util",   2)
local b3,l3 = CreateCatBtn("🪂", "Fly",           "Fly",    3)
local b4,l4 = CreateCatBtn("📡", "ESP",           "ESP",    4)
local b5,l5 = CreateCatBtn("🎨", "Skin Injector", "Skin",   5)
local b6,l6 = CreateCatBtn("💾", "Config / Save", "Config", 6)

ActiveCatBtn     = b1
ActiveCatNameLbl = l1
b1.BackgroundColor3 = T.Accent
l1.TextColor3       = T.Text
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
                    if d < S.Role.FOV and d < bestDist then bestDist=d best=p end
                end
            end
        end
    end
    return best
end

-- ============================================================
--  ESP DRAWINGS
-- ============================================================
local function GetOrMakeESP(p)
    if not ESPObjects[p] then
        local e = {
            Box    = Drawing.new("Square"),
            Name   = Drawing.new("Text"),
            Dist   = Drawing.new("Text"),
            HpBar  = Drawing.new("Square"),
            HpFill = Drawing.new("Square"),
        }
        e.Box.Filled=false e.Box.Thickness=1.5
        e.Name.Size=14 e.Name.Center=true e.Name.Outline=true
        e.Dist.Size=12 e.Dist.Center=true e.Dist.Outline=true
        e.HpBar.Filled=true e.HpBar.Color=Color3.fromRGB(50,50,50) e.HpBar.Transparency=0.4
        e.HpFill.Filled=true e.HpFill.Transparency=0.2
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
end)

-- ============================================================
--  MAIN HEARTBEAT LOOP
-- ============================================================
local autoGetGunTimer = 0

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
    if S.Util.NoClip and not S.Fly.Enabled then
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
                if obj:IsA("BasePart") and not obj:IsDescendantOf(char) and obj.Size.Magnitude > 2 then
                    table.insert(XRayCache, obj)
                end
            end
        end
        if heartbeatStep % 4 == 0 then
            local tgt = S.Util.XRayTrans
            for _, obj in ipairs(XRayCache) do
                if obj and obj.Parent and not obj:IsDescendantOf(char) then
                    if not OriginalTransparency[obj] then OriginalTransparency[obj] = obj.Transparency end
                    if obj.Transparency < tgt then obj.Transparency = tgt end
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

    -- AUTO GET GUN (every 3 seconds)
    if S.Util.AutoGetGun then
        autoGetGunTimer += dt
        if autoGetGunTimer >= 3 then
            autoGetGunTimer = 0
            -- Only try if we don't already have a gun
            local hasGun = char:FindFirstChild("Sheriff Gun") or char:FindFirstChild("Gun")
                or LocalPlayer.Backpack:FindFirstChild("Sheriff Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
            if not hasGun then TryGetGun() end
        end
    end

    -- Find murderer & sheriff
    local Murderer, Sheriff = nil, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local r = GetPlayerRole(p)
            if r=="Murderer" then Murderer=p end
            if r=="Sheriff"  then Sheriff=p  end
        end
    end

    local myRole = GetPlayerRole(LocalPlayer)

    -- FREEZE MURDERER (client-side CFrame lock)
    if S.Util.FreezeMurder and Murderer and Murderer.Character then
        local mRoot = Murderer.Character:FindFirstChild("HumanoidRootPart")
        if mRoot then
            mRoot.AssemblyLinearVelocity = Vector3.zero
            mRoot.AssemblyAngularVelocity = Vector3.zero
        end
    end

    -- ANTI-STAB DODGE (jump + sidestep when murderer close)
    if S.Role.AntiStab and Murderer and Murderer.Character then
        local mRoot = Murderer.Character:FindFirstChild("HumanoidRootPart")
        if mRoot then
            local dist = (Root.Position - mRoot.Position).Magnitude
            if dist < S.Role.AntiStabDist then
                -- Jump away
                local awayDir = (Root.Position - mRoot.Position).Unit
                Root.CFrame = Root.CFrame + awayDir * 8
                Hum.Jump = true
            end
        end
    end

    -- AUTO FLING MURDERER
    if S.Role.AutoFling and Murderer then
        local mRoot = Murderer.Character and Murderer.Character:FindFirstChild("HumanoidRootPart")
        if mRoot and heartbeatStep % 10 == 0 then -- every 10 frames
            pcall(function()
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.new(
                    math.random(-1,1)*S.Role.FlingForce,
                    S.Role.FlingForce,
                    math.random(-1,1)*S.Role.FlingForce
                )
                bv.MaxForce = Vector3.new(1e6,1e6,1e6)
                bv.Parent = mRoot
                game:GetService("Debris"):AddItem(bv, 0.2)
            end)
        end
    end

    -- BLINK TO MURDERER (Sheriff auto-TP to shoot up close)
    if S.Role.BlinkMurder and myRole == "Sheriff" and Murderer then
        local mRoot = Murderer.Character and Murderer.Character:FindFirstChild("HumanoidRootPart")
        local mHum  = Murderer.Character and Murderer.Character:FindFirstChild("Humanoid")
        if mRoot and mHum and mHum.Health > 0 and heartbeatStep % 30 == 0 then
            local dist = (Root.Position - mRoot.Position).Magnitude
            if dist > 20 then
                Root.CFrame = CFrame.new(mRoot.Position + Vector3.new(0,3,0))
            end
        end
    end

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

    -- SPEED KILL (TP + instant stab every player)
    if S.Role.SpeedKill and myRole == "Murderer" and heartbeatStep % 20 == 0 then
        local knife = char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if knife and not knife:FindFirstChild("_HansHubFakeSkin") then
            if knife.Parent == LocalPlayer.Backpack then Hum:EquipTool(knife) end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local pHum  = p.Character:FindFirstChild("Humanoid")
                    local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    if pHum and pRoot and pHum.Health > 0 then
                        Root.CFrame = CFrame.new(pRoot.Position + Vector3.new(0,1,0))
                        pcall(function() knife:Activate() end)
                    end
                end
            end
        end
    end

    -- AUTO KILL ALL (continuous)
    if S.Role.AutoKillAll and myRole == "Murderer" and heartbeatStep % 5 == 0 then
        local knife = char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
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
                        break
                    end
                end
            end
        end
    end

    -- AUTO SHOOT
    if S.Role.AutoShoot and myRole == "Sheriff" and Murderer then
        local mRoot = Murderer.Character and Murderer.Character:FindFirstChild("HumanoidRootPart")
        local mHum  = Murderer.Character and Murderer.Character:FindFirstChild("Humanoid")
        if mRoot and mHum and mHum.Health > 0 then
            if (Root.Position-mRoot.Position).Magnitude < S.Role.ShootRange then
                pcall(function()
                    local gun = char:FindFirstChild("Sheriff Gun") or char:FindFirstChild("Gun")
                        or LocalPlayer.Backpack:FindFirstChild("Sheriff Gun")
                        or LocalPlayer.Backpack:FindFirstChild("Gun")
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
                    Root.CFrame = Root.CFrame + (pRoot.Position-Root.Position).Unit * 0.5
                end
            end
        end
    end

    -- RAINBOW HUE CYCLE
    if heartbeatStep % 20 == 0 then
        rainbowHue = (rainbowHue + 0.03) % 1
        if S.Skin.KnifeEnabled and S.Skin.KnifeSkin=="Rainbow" then UpdateFakeSkinColor("Knife","Rainbow") end
        if S.Skin.GunEnabled   and S.Skin.GunSkin=="Rainbow"   then UpdateFakeSkinColor("Sheriff Gun","Rainbow") end
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
        for _,data in pairs(ESPObjects) do HideESP(data) end
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
        local isMarked = PermanentRoles[p.UserId] ~= nil
        local col = role=="Murderer" and Color3.fromRGB(255,60,60)
                 or role=="Sheriff"  and Color3.fromRGB(60,220,100)
                 or                      Color3.fromRGB(220,220,220)

        local szX,szY = 2200/pos.Z, 3000/pos.Z
        local scr = Vector2.new(pos.X, pos.Y)

        -- Box
        e.Box.Visible = S.ESP.Box
        e.Box.Position = Vector2.new(scr.X-szX/2, scr.Y-szY/2)
        e.Box.Size = Vector2.new(szX,szY)
        e.Box.Color = col
        e.Box.Transparency = 0.5

        -- Name (★ for confirmed)
        e.Name.Visible = S.ESP.Name
        e.Name.Position = Vector2.new(scr.X, scr.Y-szY/2-18)
        e.Name.Text = string.format("%s[%s] %s", isMarked and "★ " or "", role, p.Name)
        e.Name.Color = col

        -- Distance
        if Root then
            e.Dist.Visible = S.ESP.Distance
            e.Dist.Position = Vector2.new(scr.X, scr.Y+szY/2+6)
            e.Dist.Text = string.format("%.0f studs", (Root.Position-pRoot.Position).Magnitude)
            e.Dist.Color = col
        end

        -- Health bar (left side of box)
        if S.ESP.HealthBar then
            local hp = pHum.Health / pHum.MaxHealth
            local barH = szY
            local barW = 4
            local barX = scr.X - szX/2 - barW - 2
            local barY = scr.Y - szY/2

            e.HpBar.Visible = true
            e.HpBar.Position = Vector2.new(barX, barY)
            e.HpBar.Size = Vector2.new(barW, barH)

            e.HpFill.Visible = true
            e.HpFill.Position = Vector2.new(barX, barY + barH*(1-hp))
            e.HpFill.Size = Vector2.new(barW, barH*hp)
            e.HpFill.Color = Color3.fromRGB(
                math.floor(255*(1-hp)),
                math.floor(255*hp),
                0
            )
        else
            e.HpBar.Visible = false
            e.HpFill.Visible = false
        end
    end
end)

-- ============================================================
--  INSERT TOGGLE  |  F key = quick fly toggle
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
    -- F key = toggle fly quick
    if input.KeyCode == Enum.KeyCode.F then
        S.Fly.Enabled = not S.Fly.Enabled
        if S.Fly.Enabled then StartFly() else StopFly() end
        Notify("Fly", S.Fly.Enabled and "Fly ON (W/A/S/D + Space/Ctrl)" or "Fly OFF", 2)
    end
end)

-- ============================================================
--  CLEANUP
-- ============================================================
ScreenGui.AncestryChanged:Connect(function()
    RemoveFakeTool("Knife")
    RemoveFakeTool("Sheriff Gun")
    StopFly()
end)

task.delay(0.5, function()
    Notify("✨ Hans Hub v5.0","Loaded! INSERT = menu | F = fly toggle",4)
end)
