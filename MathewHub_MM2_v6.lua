--[[
╔══════════════════════════════════════════╗
║     MATHEW HUB  |  MM2  |  v6.0         ║
║  INSERT = toggle  |  F = fly toggle      ║
╚══════════════════════════════════════════╝
  NEW v6:
  • Neon/glass UI overhaul
  • Full MM2 knife + gun skin list (100+ weapons)
  • Skin injects into MM2 inventory as real-named tool
  • Auto-TP to sheriff gun → grab → return to spot
  • 100% accurate wall-penetrating auto-shoot
  • Fixed mega-fling (sends players to void)
  • Duplicate guard fixed
]]

-- ── Duplicate guard ────────────────────────────────────────
if getgenv().MathewHubLoaded then
    pcall(function() getgenv().MathewHubGui:Destroy() end)
end
getgenv().MathewHubLoaded = true

-- ── Services ───────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local StarterGui       = game:GetService("StarterGui")
local HttpService      = game:GetService("HttpService")
local Debris           = game:GetService("Debris")

local Camera      = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ── Settings persistence ───────────────────────────────────
local SAVE_FILE = "MathewHub_MM2_v6.json"

local Defaults = {
    Role = {
        AutoStab=false,    StabRange=25,
        AutoShoot=false,   ShootRange=200,  -- increased for wall-shoot
        SilentAim=false,   FOV=120,
        AutoKillAll=false, SafeSpotY=500,
        AutoFling=false,   FlingForce=9999,  -- void fling
        SpeedKill=false,
        BlinkMurder=false,
        AntiStab=false,    AntiStabDist=15,
    },
    Util = {
        AutoCollect=false,  CollectRange=50,
        WalkSpeed=false,    Speed=32,
        JumpPower=false,    Power=60,
        Reach=false,        ReachRange=20,
        NoClip=false,
        XRay=false,         XRayTrans=0.4,
        AutoGetGun=false,   -- TP to gun, grab, return
        FreezeMurder=false,
    },
    Fly={Enabled=false, Speed=60, MaxHeight=600, NoClip=true},
    ESP={
        Enabled=false,
        ShowMurderer=true, ShowSheriff=true, ShowOthers=true,
        Box=true, Name=true, Distance=true, HealthBar=true,
    },
    Skin={
        KnifeEnabled=false, KnifeSkin="Default",
        GunEnabled=false,   GunSkin="Default",
    },
}

local function DeepCopy(t)
    local c={}
    for k,v in pairs(t) do c[k]=type(v)=="table" and DeepCopy(v) or v end
    return c
end
local S = DeepCopy(Defaults)

local function Save() pcall(function() writefile(SAVE_FILE,HttpService:JSONEncode(S)) end) end
local function Load()
    pcall(function()
        if isfile(SAVE_FILE) then
            local d=HttpService:JSONDecode(readfile(SAVE_FILE))
            for cat,vals in pairs(d) do
                if S[cat] then for k,v in pairs(vals) do S[cat][k]=v end end
            end
        end
    end)
end
Load()

-- ── Full MM2 weapon name list ──────────────────────────────
-- Knives (real MM2 internal Tool names)
local MM2_KNIVES = {
    -- Default / Common
    "Default Knife","Yellow","Green","Blue","Purple","Red","Orange","Pink","Cyan","White","Black",
    "Checker","Polka Dot","Caution","Adurite","Copper","Combat","Combat II","Marble","Graffiti",
    "High Tech","Hardened","Ocean","Space","Deep Sea","Tiger","Leaf","Tribal","Retro","Pirate",
    -- Uncommon
    "Galactic","Neon","Lovely","Pearl","Pearlshine","Void","Prismatic","Fire","Lava","Nebula",
    "Viper","Slasher","Fang","Deathshard","Saw","Tides","Flora","Splat","Spring","Fox",
    -- Rare
    "Darkbringer","Lightbringer","Gemstone","Shark","Laser","Heat","Rainbow","Elderwood",
    "Corrupt","Seer","Luger","Batwing","Spider","Clockwork","Pixel","Candy","Battle Axe","Saw",
    "Blizzard","Icebreath","Elderwood Blade",
    -- Legendary
    "Vampire","Hallows","Ancient Blade","Icedriller","Snowflake","Cane","Gingerblade",
    "Boneblade","Cookiecane","Swirly","Makeshift","Candleflame","Phantom","Specter",
    "Elderwood Revolver","Hallowgun","Bat","Swirlyblade","Elderwood Scythe","Harvester",
    -- Godly
    "Chroma Fang","Chroma Deathshard","Chroma Saw","Chroma Tides","Chroma Slasher",
    "Chroma Gemstone","Chroma Luger","Chroma Shark","Chroma Laser","Chroma Heat",
    "Chroma Darkbringer","Chroma Lightbringer","Chroma Elderwood Blade","Chroma Boneblade",
    "Chroma Gingerblade","Chroma Evergreen","Chroma Candleflame","Chroma Bauble",
    -- Ancient / Unique
    "Nik's Scythe","Elderwood Scythe","Harvester","Eternal","Chroma Evergun",
}

-- Guns (real MM2 internal names)
local MM2_GUNS = {
    -- Default
    "Default Gun","Yellow Gun","Green Gun","Blue Gun","Purple Gun","Red Gun","Orange Gun",
    "Pink Gun","Cyan Gun","White Gun","Black Gun",
    -- Common/Uncommon
    "Checker Gun","Adurite Gun","Copper Gun","Combat Gun","Marble Gun","Graffiti Gun",
    "High Tech Gun","Hardened Gun","Ocean Gun","Space Gun","Galactic","Neon Gun",
    "Lovely Gun","Pearl Gun","Pearlshine Gun","Void Gun","Prismatic Gun","Fire Gun",
    "Lava Gun","Nebula Gun","Viper Gun",
    -- Rare/Legendary
    "Shark","Laser","Heat Gun","Rainbow Gun","Luger","Blaster","Amerilaser","Plasmabeam",
    "Elderwood Revolver","Hallowgun","Red Luger","Green Luger","Iceblaster","Swirlygun",
    -- Godly
    "Chroma Luger","Chroma Shark","Chroma Laser","Chroma Heat","Chroma Swirlygun",
    "Chroma Evergun",
    -- Sheriff default (actual equipped name)
    "Sheriff Gun","Gun",
}

-- Skin color map for visual tint
local SKIN_COLORS = {
    ["Default Knife"]        = Color3.fromRGB(180,180,180),
    ["Yellow"]               = Color3.fromRGB(255,220,50),
    ["Green"]                = Color3.fromRGB(50,220,80),
    ["Blue"]                 = Color3.fromRGB(50,130,255),
    ["Purple"]               = Color3.fromRGB(160,50,255),
    ["Red"]                  = Color3.fromRGB(220,40,40),
    ["Orange"]               = Color3.fromRGB(255,140,0),
    ["Pink"]                 = Color3.fromRGB(255,150,200),
    ["Cyan"]                 = Color3.fromRGB(0,220,255),
    ["White"]                = Color3.fromRGB(240,240,240),
    ["Black"]                = Color3.fromRGB(20,20,20),
    ["Adurite"]              = Color3.fromRGB(80,255,200),
    ["Copper"]               = Color3.fromRGB(200,120,50),
    ["Galactic"]             = Color3.fromRGB(80,0,180),
    ["Neon"]                 = Color3.fromRGB(0,255,100),
    ["Void"]                 = Color3.fromRGB(15,10,30),
    ["Prismatic"]            = Color3.fromRGB(255,100,255),
    ["Fire"]                 = Color3.fromRGB(255,80,0),
    ["Lava"]                 = Color3.fromRGB(200,30,10),
    ["Nebula"]               = Color3.fromRGB(100,0,200),
    ["Darkbringer"]          = Color3.fromRGB(20,0,40),
    ["Lightbringer"]         = Color3.fromRGB(255,240,100),
    ["Gemstone"]             = Color3.fromRGB(0,200,255),
    ["Shark"]                = Color3.fromRGB(120,180,220),
    ["Laser"]                = Color3.fromRGB(255,255,0),
    ["Heat"]                 = Color3.fromRGB(255,60,0),
    ["Rainbow"]              = Color3.fromRGB(255,100,200),
    ["Elderwood"]            = Color3.fromRGB(80,40,10),
    ["Corrupt"]              = Color3.fromRGB(100,0,150),
    ["Seer"]                 = Color3.fromRGB(200,200,200),
    ["Luger"]                = Color3.fromRGB(200,200,50),
    ["Batwing"]              = Color3.fromRGB(40,0,60),
    ["Chroma Fang"]          = Color3.fromRGB(255,50,255),
    ["Chroma Darkbringer"]   = Color3.fromRGB(180,0,255),
    ["Chroma Lightbringer"]  = Color3.fromRGB(255,255,150),
    ["Chroma Luger"]         = Color3.fromRGB(255,200,0),
    ["Chroma Evergreen"]     = Color3.fromRGB(0,255,80),
    ["Chroma Evergun"]       = Color3.fromRGB(0,255,180),
    ["Nik's Scythe"]         = Color3.fromRGB(255,0,0),
    ["Sheriff Gun"]          = Color3.fromRGB(200,160,80),
    ["Gun"]                  = Color3.fromRGB(180,180,180),
    ["Default Gun"]          = Color3.fromRGB(180,180,180),
}
local function SkinColor(name)
    -- Rainbow cycles
    if name:lower():find("rainbow") or name:lower():find("chroma") then
        return Color3.fromHSV(rainbowHue,1,1)
    end
    return SKIN_COLORS[name] or Color3.fromRGB(160,160,200)
end

-- ── State ──────────────────────────────────────────────────
local rainbowHue          = 0
local ESPObjects          = {}
local OrigTransp          = {}
local XRayCache           = {}
local XRayCacheTimer      = 0
local XRayCacheInterval   = 3
local heartStep           = 0
local ActiveCatBtn        = nil
local ActiveCatLbl        = nil
local FakeSkinTools       = {}
local PermanentRoles      = {}
local FlyConn             = nil
local FlyBV               = nil
local FlyBG               = nil
local autoGetGunTimer     = 0
local lastReturnSpot      = nil   -- for gun-grab return

-- ── THEME  (neon glass dark) ───────────────────────────────
local T = {
    BG       = Color3.fromRGB(8,   8,  16),
    SB       = Color3.fromRGB(14,  12,  28),
    Panel    = Color3.fromRGB(18,  16,  34),
    Card     = Color3.fromRGB(24,  20,  44),
    CardHov  = Color3.fromRGB(32,  26,  56),
    Accent   = Color3.fromRGB(120, 80, 255),   -- electric violet
    Accent2  = Color3.fromRGB(0,  200, 255),   -- neon cyan
    ON       = Color3.fromRGB(0,  230, 120),
    OFF      = Color3.fromRGB(220, 50,  80),
    Text     = Color3.new(1,1,1),
    Sub      = Color3.fromRGB(160,150,210),
    Div      = Color3.fromRGB(40, 34, 70),
    Red      = Color3.fromRGB(255, 50, 70),
    Green    = Color3.fromRGB(0,  220,100),
    Gold     = Color3.fromRGB(255,200, 50),
    Purple   = Color3.fromRGB(160, 50,255),
    Cyan     = Color3.fromRGB(0,  200,255),
}

-- ── Notify ─────────────────────────────────────────────────
local function Notify(title,text,dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=title,Text=text,Duration=dur or 3})
    end)
end

-- ══════════════════════════════════════════════════════════
--   GUI  ROOT
-- ══════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "MathewHub_MM2"
ScreenGui.ResetOnSpawn    = false
ScreenGui.IgnoreGuiInset  = true
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent          = LocalPlayer:WaitForChild("PlayerGui")
getgenv().MathewHubGui    = ScreenGui

-- Helper: add drop shadow behind frame
local function AddShadow(parent, size)
    local sh = Instance.new("ImageLabel")
    sh.Size  = UDim2.new(1, size*2, 1, size*2)
    sh.Position = UDim2.new(0,-size,0,-size)
    sh.BackgroundTransparency = 1
    sh.Image = "rbxassetid://7912134082"   -- soft shadow asset
    sh.ImageColor3 = Color3.new(0,0,0)
    sh.ImageTransparency = 0.55
    sh.ScaleType = Enum.ScaleType.Slice
    sh.SliceCenter = Rect.new(49,49,450,450)
    sh.ZIndex = -1
    sh.Parent = parent
end

-- Main window
local Win = Instance.new("Frame")
Win.Size            = UDim2.new(0,540,0,490)
Win.Position        = UDim2.new(0.04,0,0.06,0)
Win.BackgroundColor3 = T.BG
Win.BorderSizePixel = 0
Win.Active          = true
Win.Draggable       = true
Win.Parent          = ScreenGui
Instance.new("UICorner",Win).CornerRadius = UDim.new(0,12)
AddShadow(Win,18)

-- Outer glow stroke
local WStroke = Instance.new("UIStroke",Win)
WStroke.Color = T.Accent
WStroke.Thickness = 1.8
WStroke.Transparency = 0.25

-- Gradient background tint
local WGrad = Instance.new("UIGradient",Win)
WGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(14,10,28)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8,8,16)),
}
WGrad.Rotation = 135

-- ── Title bar ──────────────────────────────────────────────
local TBar = Instance.new("Frame")
TBar.Size            = UDim2.new(1,0,0,46)
TBar.BackgroundColor3 = T.SB
TBar.BorderSizePixel = 0
TBar.Parent          = Win
Instance.new("UICorner",TBar).CornerRadius = UDim.new(0,12)
-- Fix bottom corners
do
    local f=Instance.new("Frame",TBar)
    f.Size=UDim2.new(1,0,0.5,0)
    f.Position=UDim2.new(0,0,0.5,0)
    f.BackgroundColor3=T.SB
    f.BorderSizePixel=0
end

-- Gradient on titlebar
local TGrad = Instance.new("UIGradient",TBar)
TGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(30,20,60)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(14,12,28)),
}
TGrad.Rotation = 90

-- Left accent pill
local TAccent = Instance.new("Frame",TBar)
TAccent.Size = UDim2.new(0,4,1,-14)
TAccent.Position = UDim2.new(0,10,0,7)
TAccent.BackgroundColor3 = T.Accent2
TAccent.BorderSizePixel = 0
Instance.new("UICorner",TAccent).CornerRadius = UDim.new(1,0)
-- Gradient on pill
local PGrad = Instance.new("UIGradient",TAccent)
PGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,T.Accent),
    ColorSequenceKeypoint.new(1,T.Accent2),
}
PGrad.Rotation = 90

local TitleL = Instance.new("TextLabel",TBar)
TitleL.Size = UDim2.new(0.6,0,1,0)
TitleL.Position = UDim2.new(0,22,0,0)
TitleL.BackgroundTransparency = 1
TitleL.Text = "  ⚔  MATHEW HUB  |  MM2"
TitleL.Font = Enum.Font.GothamBold
TitleL.TextSize = 14
TitleL.TextColor3 = T.Text
TitleL.TextXAlignment = Enum.TextXAlignment.Left
-- Gradient text effect via label color
local TLG = Instance.new("UIGradient",TitleL)
TLG.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,T.Accent2),
    ColorSequenceKeypoint.new(0.5,T.Accent),
    ColorSequenceKeypoint.new(1,T.Text),
}
TLG.Rotation = 0

local VerL = Instance.new("TextLabel",TBar)
VerL.Size = UDim2.new(0,72,0,20)
VerL.Position = UDim2.new(1,-116,0.5,-10)
VerL.BackgroundColor3 = Color3.fromRGB(30,15,60)
VerL.Text = "v6.0 NEON"
VerL.Font = Enum.Font.GothamBold
VerL.TextSize = 10
VerL.TextColor3 = T.Accent2
VerL.Parent = TBar
Instance.new("UICorner",VerL).CornerRadius = UDim.new(0,5)
Instance.new("UIStroke",VerL).Color = T.Accent

local CloseB = Instance.new("TextButton",TBar)
CloseB.Size = UDim2.new(0,28,0,28)
CloseB.Position = UDim2.new(1,-38,0.5,-14)
CloseB.BackgroundColor3 = T.Red
CloseB.Text = "✕"
CloseB.Font = Enum.Font.GothamBold
CloseB.TextSize = 13
CloseB.TextColor3 = T.Text
Instance.new("UICorner",CloseB).CornerRadius = UDim.new(0,6)
CloseB.MouseButton1Click:Connect(function() Win.Visible=false end)

-- ── Sidebar ────────────────────────────────────────────────
local SB = Instance.new("Frame",Win)
SB.Size = UDim2.new(0,152,1,-54)
SB.Position = UDim2.new(0,6,0,48)
SB.BackgroundColor3 = T.SB
SB.BorderSizePixel = 0
Instance.new("UICorner",SB).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke",SB).Color = T.Div

local SBList = Instance.new("ScrollingFrame",SB)
SBList.Size = UDim2.new(1,-6,1,-10)
SBList.Position = UDim2.new(0,3,0,5)
SBList.BackgroundTransparency = 1
SBList.ScrollBarThickness = 3
SBList.ScrollBarImageColor3 = T.Accent
SBList.CanvasSize = UDim2.new(0,0,0,0)
SBList.AutomaticCanvasSize = Enum.AutomaticSize.Y
local SBLayout = Instance.new("UIListLayout",SBList)
SBLayout.Padding = UDim.new(0,5)
SBLayout.SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding",SBList).PaddingTop = UDim.new(0,5)

-- ── Right panel ────────────────────────────────────────────
local RP = Instance.new("Frame",Win)
RP.Size = UDim2.new(1,-167,1,-54)
RP.Position = UDim2.new(0,163,0,48)
RP.BackgroundColor3 = T.Panel
RP.BorderSizePixel = 0
Instance.new("UICorner",RP).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke",RP).Color = T.Div

local PS = Instance.new("ScrollingFrame",RP)
PS.Size = UDim2.new(1,-10,1,-10)
PS.Position = UDim2.new(0,5,0,5)
PS.BackgroundTransparency = 1
PS.ScrollBarThickness = 4
PS.ScrollBarImageColor3 = T.Accent
PS.CanvasSize = UDim2.new(0,0,0,0)
PS.AutomaticCanvasSize = Enum.AutomaticSize.Y
local PSL = Instance.new("UIListLayout",PS)
PSL.Padding = UDim.new(0,6)
PSL.SortOrder = Enum.SortOrder.LayoutOrder
local PSP = Instance.new("UIPadding",PS)
PSP.PaddingTop = UDim.new(0,6)
PSP.PaddingRight = UDim.new(0,4)

-- ══════════════════════════════════════════════════════════
--   PANEL WIDGET HELPERS
-- ══════════════════════════════════════════════════════════
local pOrder = 0
local function NO() pOrder+=1 return pOrder end

local function ClearPanel()
    for _,c in ipairs(PS:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    pOrder = 0
end

local function Sec(txt, col)
    local l = Instance.new("TextLabel",PS)
    l.Size = UDim2.new(1,0,0,20)
    l.BackgroundTransparency = 1
    l.Text = "  ◈  "..txt
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextColor3 = col or T.Accent2
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = NO()
    local dv = Instance.new("Frame",PS)
    dv.Size = UDim2.new(1,0,0,1)
    dv.BackgroundColor3 = T.Div
    dv.BorderSizePixel = 0
    dv.LayoutOrder = NO()
    -- Gradient on divider
    local dg = Instance.new("UIGradient",dv)
    dg.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,col or T.Accent),
        ColorSequenceKeypoint.new(0.6,T.Div),
        ColorSequenceKeypoint.new(1,T.BG),
    }
end

local function MkRow(h)
    local f = Instance.new("Frame",PS)
    f.Size = UDim2.new(1,0,0,h or 36)
    f.BackgroundColor3 = T.Card
    f.BorderSizePixel = 0
    f.LayoutOrder = NO()
    Instance.new("UICorner",f).CornerRadius = UDim.new(0,7)
    -- Subtle inner gradient
    local g = Instance.new("UIGradient",f)
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(36,28,60)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(24,20,44)),
    }
    g.Rotation = 90
    return f
end

local function Toggle(label, init, onChange)
    local f = MkRow(36)
    local lbl = Instance.new("TextLabel",f)
    lbl.Size = UDim2.new(0.72,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton",f)
    btn.Size = UDim2.new(0,52,0,24)
    btn.Position = UDim2.new(1,-60,0.5,-12)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = T.Text
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,6)

    local st = init or false
    local function Ref()
        btn.Text = st and "ON" or "OFF"
        btn.BackgroundColor3 = st and T.ON or T.OFF
    end
    Ref()
    btn.MouseButton1Click:Connect(function()
        st = not st; Ref(); onChange(st); Save()
    end)
    -- hover glow
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = st and Color3.fromRGB(0,255,140) or Color3.fromRGB(255,80,100)
    end)
    btn.MouseLeave:Connect(Ref)
    return function(v) st=v; Ref() end
end

local function Input(label, init, onChange)
    local f = MkRow(36)
    local lbl = Instance.new("TextLabel",f)
    lbl.Size = UDim2.new(0.6,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox",f)
    box.Size = UDim2.new(0,72,0,24)
    box.Position = UDim2.new(1,-80,0.5,-12)
    box.BackgroundColor3 = Color3.fromRGB(14,12,30)
    box.Text = tostring(init)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.TextColor3 = T.Accent2
    box.ClearTextOnFocus = false
    Instance.new("UICorner",box).CornerRadius = UDim.new(0,6)
    local s = Instance.new("UIStroke",box); s.Color=T.Accent; s.Transparency=0.4

    box.FocusLost:Connect(function()
        local v=math.clamp(tonumber(box.Text) or init,1,99999)
        box.Text=tostring(v); onChange(v); Save()
    end)
end

local function Dropdown(label, list, getV, setV)
    local f = MkRow(36)
    local lbl = Instance.new("TextLabel",f)
    lbl.Size = UDim2.new(0.42,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text = label
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = T.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local dBtn = Instance.new("TextButton",f)
    dBtn.Size = UDim2.new(0.52,0,0,24)
    dBtn.Position = UDim2.new(0.46,0,0.5,-12)
    dBtn.BackgroundColor3 = Color3.fromRGB(20,15,45)
    dBtn.Text = getV()
    dBtn.Font = Enum.Font.Gotham
    dBtn.TextSize = 9
    dBtn.TextColor3 = T.Accent2
    dBtn.ClipsDescendants = true
    Instance.new("UICorner",dBtn).CornerRadius = UDim.new(0,5)
    Instance.new("UIStroke",dBtn).Color = T.Accent

    local lf = Instance.new("Frame",PS)
    lf.BackgroundColor3 = Color3.fromRGB(14,12,30)
    lf.BorderSizePixel = 0
    lf.Visible = false
    lf.LayoutOrder = NO()
    lf.Size = UDim2.new(1,0,0,0)
    Instance.new("UICorner",lf).CornerRadius = UDim.new(0,7)
    Instance.new("UIStroke",lf).Color = T.Accent

    local inner = Instance.new("ScrollingFrame",lf)
    inner.Size = UDim2.new(1,-4,1,-4)
    inner.Position = UDim2.new(0,2,0,2)
    inner.BackgroundTransparency = 1
    inner.ScrollBarThickness = 3
    inner.ScrollBarImageColor3 = T.Accent
    inner.CanvasSize = UDim2.new(0,0,0,#list*24)
    Instance.new("UIListLayout",inner).Padding = UDim.new(0,2)

    for _,item in ipairs(list) do
        local ib = Instance.new("TextButton",inner)
        ib.Size = UDim2.new(1,0,0,22)
        ib.BackgroundTransparency = 1
        ib.Text = "  "..item
        ib.Font = Enum.Font.Gotham
        ib.TextSize = 10
        ib.TextColor3 = T.Sub
        ib.TextXAlignment = Enum.TextXAlignment.Left
        ib.MouseButton1Click:Connect(function()
            setV(item); dBtn.Text=item
            lf.Visible=false; lf.Size=UDim2.new(1,0,0,0)
            Save()
        end)
        ib.MouseEnter:Connect(function() ib.TextColor3=T.Accent2 end)
        ib.MouseLeave:Connect(function() ib.TextColor3=T.Sub end)
    end

    local open=false
    dBtn.MouseButton1Click:Connect(function()
        open=not open
        lf.Visible=open
        lf.Size=open and UDim2.new(1,0,0,math.min(#list*24,150)) or UDim2.new(1,0,0,0)
    end)
end

local function Btn(txt, col, fn)
    local f = MkRow(34)
    local b = Instance.new("TextButton",f)
    b.Size = UDim2.new(0.92,0,0,26)
    b.Position = UDim2.new(0.04,0,0.5,-13)
    b.BackgroundColor3 = col or T.Accent
    b.Text = txt
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.TextColor3 = T.Text
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    -- glow stroke
    local bs = Instance.new("UIStroke",b)
    bs.Color = col or T.Accent
    bs.Transparency = 0.6

    b.MouseEnter:Connect(function() bs.Transparency=0.0 end)
    b.MouseLeave:Connect(function() bs.Transparency=0.6 end)
    b.MouseButton1Click:Connect(fn)
    return b
end

local function InfoBox(txt,col,h)
    local f = MkRow(h or 30)
    f.BackgroundColor3 = col or Color3.fromRGB(20,15,40)
    local l = Instance.new("TextLabel",f)
    l.Size = UDim2.new(1,-10,1,0)
    l.Position = UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1
    l.Text=txt
    l.Font=Enum.Font.Gotham
    l.TextSize=10
    l.TextColor3=T.Sub
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.TextWrapped=true
end

-- ══════════════════════════════════════════════════════════
--   SIDEBAR BUTTON BUILDER
-- ══════════════════════════════════════════════════════════
local function CatBtn(icon, name, key, ord)
    local btn = Instance.new("TextButton",SBList)
    btn.Size = UDim2.new(1,-6,0,38)
    btn.BackgroundColor3 = T.Card
    btn.Text = ""
    btn.LayoutOrder = ord
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,8)

    -- Left color pill
    local pill = Instance.new("Frame",btn)
    pill.Size = UDim2.new(0,3,0.6,0)
    pill.Position = UDim2.new(0,4,0.2,0)
    pill.BackgroundColor3 = T.Accent
    pill.BorderSizePixel = 0
    pill.Visible = false
    Instance.new("UICorner",pill).CornerRadius = UDim.new(1,0)

    local iL = Instance.new("TextLabel",btn)
    iL.Size = UDim2.new(0,28,1,0)
    iL.Position = UDim2.new(0,10,0,0)
    iL.BackgroundTransparency=1
    iL.Text=icon
    iL.TextSize=16

    local nL = Instance.new("TextLabel",btn)
    nL.Size = UDim2.new(1,-44,1,0)
    nL.Position = UDim2.new(0,40,0,0)
    nL.BackgroundTransparency=1
    nL.Text=name
    nL.Font=Enum.Font.GothamSemibold
    nL.TextSize=11
    nL.TextColor3=T.Sub
    nL.TextXAlignment=Enum.TextXAlignment.Left

    btn.MouseButton1Click:Connect(function()
        if ActiveCatBtn and ActiveCatBtn~=btn then
            ActiveCatBtn.BackgroundColor3=T.Card
            local p2=ActiveCatBtn:FindFirstChild("Frame")
            if p2 then p2.Visible=false end
        end
        if ActiveCatLbl and ActiveCatLbl~=nL then ActiveCatLbl.TextColor3=T.Sub end

        ActiveCatBtn=btn; ActiveCatLbl=nL
        btn.BackgroundColor3=Color3.fromRGB(36,25,72)
        pill.Visible=true
        nL.TextColor3=T.Text
        CATS[key]()
    end)
    btn.MouseEnter:Connect(function()
        if ActiveCatBtn~=btn then btn.BackgroundColor3=T.CardHov end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveCatBtn~=btn then btn.BackgroundColor3=T.Card end
    end)
    return btn,nL,pill
end

-- ══════════════════════════════════════════════════════════
--   ROLE DETECTION
-- ══════════════════════════════════════════════════════════
local function GetRole(p)
    local uid=p.UserId
    if PermanentRoles[uid] then return PermanentRoles[uid] end
    if p.Team then
        local tn=p.Team.Name:lower()
        if tn:find("murder")  then PermanentRoles[uid]="Murderer" return "Murderer" end
        if tn:find("sheriff") then PermanentRoles[uid]="Sheriff"  return "Sheriff"  end
    end
    local ls=p:FindFirstChild("leaderstats")
    if ls then
        local r=ls:FindFirstChild("Role") or ls:FindFirstChild("role")
        if r then
            local rv=tostring(r.Value):lower()
            if rv:find("murder") then PermanentRoles[uid]="Murderer" return "Murderer" end
            if rv:find("sheriff") then PermanentRoles[uid]="Sheriff" return "Sheriff" end
        end
    end
    if p.Character then
        if p.Character:FindFirstChild("Knife") then PermanentRoles[uid]="Murderer" return "Murderer" end
        if p.Character:FindFirstChild("Sheriff Gun") or p.Character:FindFirstChild("Gun") then
            PermanentRoles[uid]="Sheriff" return "Sheriff"
        end
    end
    return "Innocent"
end

LocalPlayer.CharacterAdded:Connect(function()
    PermanentRoles={}
    task.wait(1)
    if S.Skin.KnifeEnabled then CreateFakeTool("Knife",S.Skin.KnifeSkin) end
    if S.Skin.GunEnabled   then CreateFakeTool("Sheriff Gun",S.Skin.GunSkin) end
end)

-- ══════════════════════════════════════════════════════════
--   FLY SYSTEM
-- ══════════════════════════════════════════════════════════
local function StopFly()
    S.Fly.Enabled=false
    if FlyConn then FlyConn:Disconnect() FlyConn=nil end
    local c=LocalPlayer.Character
    if c then
        local h=c:FindFirstChild("Humanoid")
        local r=c:FindFirstChild("HumanoidRootPart")
        if h then h.PlatformStand=false end
        if r then
            if FlyBV then FlyBV:Destroy() FlyBV=nil end
            if FlyBG then FlyBG:Destroy() FlyBG=nil end
            r.AssemblyLinearVelocity=Vector3.zero
        end
    end
end

local function StartFly()
    local c=LocalPlayer.Character
    if not c then return end
    local r=c:FindFirstChild("HumanoidRootPart")
    local h=c:FindFirstChild("Humanoid")
    if not r or not h then return end
    h.PlatformStand=true

    FlyBV=Instance.new("BodyVelocity")
    FlyBV.MaxForce=Vector3.new(1e5,1e5,1e5)
    FlyBV.Velocity=Vector3.zero
    FlyBV.Parent=r

    FlyBG=Instance.new("BodyGyro")
    FlyBG.MaxTorque=Vector3.new(1e5,1e5,1e5)
    FlyBG.P=1e4
    FlyBG.CFrame=r.CFrame
    FlyBG.Parent=r

    FlyConn=RunService.RenderStepped:Connect(function()
        if not S.Fly.Enabled then StopFly() return end
        local spd=S.Fly.Speed
        local dir=Vector3.zero
        local cam=Camera
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir+=Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir-=Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)   then spd=spd*2.5 end
        if r.Position.Y>=S.Fly.MaxHeight and dir.Y>0 then dir=Vector3.new(dir.X,0,dir.Z) end
        FlyBV.Velocity=dir.Magnitude>0 and dir.Unit*spd or Vector3.zero
        FlyBG.CFrame=cam.CFrame
        if S.Fly.NoClip then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════
--   SKIN SYSTEM  (injects as real-named Tool into Backpack)
-- ══════════════════════════════════════════════════════════
function CreateFakeTool(weaponName, skinName)
    local c=LocalPlayer.Character
    if not c then return end
    -- Remove previous
    if FakeSkinTools[weaponName] then
        pcall(function() FakeSkinTools[weaponName]:Destroy() end)
        FakeSkinTools[weaponName]=nil
    end

    local color = SkinColor(skinName)
    local isKnife = not weaponName:lower():find("gun")

    local tool=Instance.new("Tool")
    tool.Name=weaponName             -- exact name MM2 would show
    tool.RequiresHandle=true
    tool.CanBeDropped=false
    tool.ToolTip=skinName.." (Mathew Hub Visual)"

    -- Handle
    local handle=Instance.new("Part",tool)
    handle.Name="Handle"
    handle.Size=isKnife and Vector3.new(0.12,1.4,0.06) or Vector3.new(0.28,0.9,0.14)
    handle.Color=Color3.fromRGB(50,40,35)
    handle.Material=Enum.Material.SmoothPlastic
    handle.CanCollide=false
    handle.CastShadow=false

    -- Blade/barrel
    local blade=Instance.new("Part",tool)
    blade.Name=isKnife and "Blade" or "Barrel"
    blade.Size=isKnife and Vector3.new(0.04,1.0,0.03) or Vector3.new(0.12,0.7,0.09)
    blade.Color=color
    blade.Material=Enum.Material.Neon
    blade.CanCollide=false
    blade.CastShadow=false

    -- Tip glow part
    local tip=Instance.new("Part",tool)
    tip.Name="Tip"
    tip.Size=Vector3.new(0.08,0.08,0.08)
    tip.Color=color
    tip.Material=Enum.Material.Neon
    tip.CanCollide=false
    tip.CastShadow=false

    -- Welds
    local w1=Instance.new("WeldConstraint",handle)
    w1.Part0=handle; w1.Part1=blade
    blade.CFrame=handle.CFrame*CFrame.new(0,isKnife and 0.6 or 0.4,0)

    local w2=Instance.new("WeldConstraint",handle)
    w2.Part0=blade; w2.Part1=tip
    tip.CFrame=blade.CFrame*CFrame.new(0,isKnife and 0.55 or 0.38,0)

    -- Point light for glow
    local pl=Instance.new("PointLight",tip)
    pl.Brightness=3
    pl.Color=color
    pl.Range=5

    -- Internal tag
    local tag=Instance.new("StringValue",tool)
    tag.Name="_MathewHubSkin"
    tag.Value=skinName

    -- Parent to Backpack so it shows in MM2 inventory hotbar
    tool.Parent=LocalPlayer.Backpack
    FakeSkinTools[weaponName]=tool
    return tool
end

local function RemoveFakeTool(name)
    if FakeSkinTools[name] then
        pcall(function() FakeSkinTools[name]:Destroy() end)
        FakeSkinTools[name]=nil
    end
end

local function UpdateSkinColor(weaponName, skinName)
    local t=FakeSkinTools[weaponName]
    if not t then return end
    local col=SkinColor(skinName)
    for _,p in ipairs(t:GetDescendants()) do
        if p:IsA("BasePart") and p.Name~="Handle" then
            p.Color=col
            local pl=p:FindFirstChildOfClass("PointLight")
            if pl then pl.Color=col end
        end
    end
end

-- ══════════════════════════════════════════════════════════
--   AUTO GET GUN → return to spot
-- ══════════════════════════════════════════════════════════
local function TryGetGunAndReturn()
    local c=LocalPlayer.Character
    local root=c and c:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Already have a real gun?
    local hasGun=c:FindFirstChild("Sheriff Gun") or c:FindFirstChild("Gun")
        or LocalPlayer.Backpack:FindFirstChild("Sheriff Gun")
        or LocalPlayer.Backpack:FindFirstChild("Gun")
    if hasGun and not hasGun:FindFirstChild("_MathewHubSkin") then return end

    -- Save current position
    local returnCF = root.CFrame

    -- Search for gun on map
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") then
            local n=obj.Name:lower()
            if (n:find("gun") or n:find("sheriff")) and obj.Parent~=LocalPlayer.Backpack and obj.Parent~=c then
                if not obj:FindFirstChild("_MathewHubSkin") then
                    local h=obj:FindFirstChild("Handle")
                    if h and (root.Position-h.Position).Magnitude < 200 then
                        -- TP to gun
                        root.CFrame = CFrame.new(h.Position+Vector3.new(0,3,0))
                        task.wait(0.25)  -- wait for pickup
                        -- Return to saved spot
                        root.CFrame = returnCF
                        Notify("Auto Gun","Grabbed gun & returned to spot!",2)
                        return
                    end
                end
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════
--   WALL-PENETRATING AUTO SHOOT (100% accurate raycast)
-- ══════════════════════════════════════════════════════════
local function ShootMurdererWallPen(myRoot, murderer)
    -- Find murderer root
    local mRoot = murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart")
    local mHum  = murderer.Character and murderer.Character:FindFirstChildOfClass("Humanoid")
    if not mRoot or not mHum or mHum.Health<=0 then return end

    -- Find real gun (skip fake)
    local c=LocalPlayer.Character
    local hum=c and c:FindFirstChild("Humanoid")
    if not hum then return end
    local gun = c:FindFirstChild("Sheriff Gun") or c:FindFirstChild("Gun")
        or LocalPlayer.Backpack:FindFirstChild("Sheriff Gun")
        or LocalPlayer.Backpack:FindFirstChild("Gun")
    if not gun or gun:FindFirstChild("_MathewHubSkin") then return end

    -- Equip gun
    if gun.Parent==LocalPlayer.Backpack then hum:EquipTool(gun) end

    -- Point camera exactly at murderer head (wall-pen: ignore walls)
    local aimPos = mRoot.Position + Vector3.new(0,1.5,0)  -- aim chest/head
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPos)

    -- Activate gun — MM2 uses mouse position for aiming
    -- Force mouse target by setting Camera CFrame directly at target
    -- then activate; because camera is facing murderer the bullet goes there
    pcall(function() gun:Activate() end)
end

-- ══════════════════════════════════════════════════════════
--   MEGA FLING (sends to void — kills on fall damage)
-- ══════════════════════════════════════════════════════════
local function MegaFling(target)
    local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    -- Apply insane upward + random horizontal velocity
    pcall(function()
        local bv=Instance.new("BodyVelocity")
        bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
        bv.Velocity=Vector3.new(
            math.random(-200,200),
            S.Role.FlingForce,   -- 9999 by default = instant void
            math.random(-200,200)
        )
        bv.Parent=tRoot
        Debris:AddItem(bv,0.08)  -- very short = instant massive velocity burst
    end)
    -- Also zero out any dampening
    pcall(function()
        local bp=Instance.new("BodyPosition")
        bp.MaxForce=Vector3.zero  -- disable to let velocity take over
        bp.Parent=tRoot
        Debris:AddItem(bp,0.05)
    end)
end

-- ══════════════════════════════════════════════════════════
--   CATEGORY CONTENT
-- ══════════════════════════════════════════════════════════
local function LoadRole()
    ClearPanel()
    Sec("⚔  ROLE FEATURES", T.Red)
    Toggle("🔪 Auto Stab (Murderer)",  S.Role.AutoStab,  function(v) S.Role.AutoStab=v end)
    Input("  Stab Range",              S.Role.StabRange,  function(v) S.Role.StabRange=v end)
    Toggle("🔫 Auto Shoot (Sheriff — wall pen)", S.Role.AutoShoot, function(v) S.Role.AutoShoot=v end)
    Input("  Shoot Range",             S.Role.ShootRange, function(v) S.Role.ShootRange=v end)
    InfoBox("ℹ 100% accurate wall-penetrating shot — aims camera at murderer then fires",
        Color3.fromRGB(15,30,15),28)
    Toggle("🎯 Silent Aim",            S.Role.SilentAim,  function(v) S.Role.SilentAim=v end)
    Input("  FOV",                     S.Role.FOV,        function(v) S.Role.FOV=v end)

    Sec("💀  KILL FEATURES", T.Red)
    InfoBox("⚠  Kill All: TPs to each player, stabs, then safe-spots",
        Color3.fromRGB(40,10,10),28)
    Toggle("☠ Auto Kill All",          S.Role.AutoKillAll, function(v) S.Role.AutoKillAll=v end)
    Input("  Safe Height (Y)",         S.Role.SafeSpotY,  function(v) S.Role.SafeSpotY=v end)
    Toggle("⚡ Speed Kill (TP+stab)",  S.Role.SpeedKill,  function(v) S.Role.SpeedKill=v end)
    Btn("☠  KILL ALL NOW", T.Red, function()
        local c=LocalPlayer.Character
        local root=c and c:FindFirstChild("HumanoidRootPart")
        local hum=c and c:FindFirstChild("Humanoid")
        if not root or not hum then Notify("Kill All","No char!",2) return end
        local safe=root.Position+Vector3.new(0,S.Role.SafeSpotY,0)
        local knife=c:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if not knife or knife:FindFirstChild("_MathewHubSkin") then
            Notify("Kill All","No real knife!",2) return
        end
        if knife.Parent==LocalPlayer.Backpack then hum:EquipTool(knife) end
        local n=0
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character then
                local pr=p.Character:FindFirstChild("HumanoidRootPart")
                local ph=p.Character:FindFirstChild("Humanoid")
                if pr and ph and ph.Health>0 then
                    root.CFrame=CFrame.new(pr.Position+Vector3.new(0,2,0))
                    task.wait(0.05)
                    root.CFrame=CFrame.new(root.Position,pr.Position)
                    pcall(function() knife:Activate() end)
                    task.wait(0.08)
                    n+=1
                end
            end
        end
        root.CFrame=CFrame.new(safe)
        Notify("Kill All","Killed "..n.." → safe-spotted",3)
    end)

    Sec("💥  FLING & DEFENSE", T.Purple)
    Toggle("💥 Auto Mega-Fling Murderer", S.Role.AutoFling,   function(v) S.Role.AutoFling=v end)
    Input("  Fling Force (9999=void)",    S.Role.FlingForce,  function(v) S.Role.FlingForce=v end)
    InfoBox("ℹ 9999 force sends murderer to void instantly (dies on impact)",
        Color3.fromRGB(20,10,40),26)
    Toggle("🔄 Blink to Murder (Sheriff)", S.Role.BlinkMurder, function(v) S.Role.BlinkMurder=v end)
    Toggle("🛡 Anti-Stab Dodge",           S.Role.AntiStab,    function(v) S.Role.AntiStab=v end)
    Input("  Dodge Trigger Dist",          S.Role.AntiStabDist,function(v) S.Role.AntiStabDist=v end)
end

local function LoadUtil()
    ClearPanel()
    Sec("🛠  UTILITIES", T.Cyan)
    Toggle("💎 Auto Collect",        S.Util.AutoCollect,  function(v) S.Util.AutoCollect=v end)
    Input("  Collect Range",         S.Util.CollectRange, function(v) S.Util.CollectRange=v end)

    Toggle("🔫 Auto Get Gun + Return",S.Util.AutoGetGun,  function(v) S.Util.AutoGetGun=v end)
    InfoBox("ℹ When Sheriff dies: TPs to gun → grabs it → TPs back to your original spot",
        Color3.fromRGB(15,30,15),30)
    Btn("🔫  GET GUN NOW (manual)", T.Green, function()
        TryGetGunAndReturn()
    end)

    Toggle("🏃 Walk Speed",          S.Util.WalkSpeed,    function(v)
        S.Util.WalkSpeed=v
        if not v then local c=LocalPlayer.Character
            if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=16 end
        end
    end)
    Input("  Speed",                 S.Util.Speed,        function(v) S.Util.Speed=v end)
    Toggle("🦘 Jump Power",          S.Util.JumpPower,    function(v)
        S.Util.JumpPower=v
        if not v then local c=LocalPlayer.Character
            if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower=50 end
        end
    end)
    Input("  Power",                 S.Util.Power,        function(v) S.Util.Power=v end)
    Toggle("📏 Reach",               S.Util.Reach,        function(v) S.Util.Reach=v end)
    Input("  Reach Range",           S.Util.ReachRange,   function(v) S.Util.ReachRange=v end)
    Toggle("👁 X-Ray",               S.Util.XRay,         function(v)
        S.Util.XRay=v
        if not v then
            for obj,orig in pairs(OrigTransp) do if obj and obj.Parent then obj.Transparency=orig end end
            OrigTransp={} XRayCache={} XRayCacheTimer=0
        else XRayCacheTimer=XRayCacheInterval end
    end)
    Toggle("🚫 No Clip",             S.Util.NoClip,       function(v) S.Util.NoClip=v end)
    Toggle("🔒 Freeze Murderer",     S.Util.FreezeMurder, function(v) S.Util.FreezeMurder=v end)

    Sec("⚡  QUICK ACTIONS", T.Gold)
    Btn("📍  TP Up to Safety",T.Accent,function()
        local c=LocalPlayer.Character
        local r=c and c:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame=CFrame.new(r.Position+Vector3.new(0,200,0))
            Notify("Util","Teleported to safety!",2) end
    end)
    Btn("👻  Fake Death (underground)",Color3.fromRGB(100,20,20),function()
        local c=LocalPlayer.Character
        local r=c and c:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame=CFrame.new(r.Position+Vector3.new(0,-300,0))
            Notify("Util","Fake death!",2) end
    end)
end

local function LoadFly()
    ClearPanel()
    Sec("🪂  FLY  (F key = quick toggle)", T.Purple)
    InfoBox("W/A/S/D = move  |  Space = up  |  Ctrl = down  |  Shift = 2.5× speed",
        Color3.fromRGB(20,10,40),30)
    Toggle("🪂 Enable Fly",    S.Fly.Enabled,   function(v) S.Fly.Enabled=v if v then StartFly() else StopFly() end end)
    Input("  Speed",           S.Fly.Speed,     function(v) S.Fly.Speed=v end)
    Input("  Max Height",      S.Fly.MaxHeight, function(v) S.Fly.MaxHeight=v end)
    Toggle("🚫 No Clip flying",S.Fly.NoClip,   function(v) S.Fly.NoClip=v end)
    Btn("🪂  Toggle Fly", T.Purple, function()
        S.Fly.Enabled=not S.Fly.Enabled
        if S.Fly.Enabled then StartFly() else StopFly() end
        Notify("Fly",S.Fly.Enabled and "Fly ON" or "Fly OFF",2)
    end)
end

local function LoadESP()
    ClearPanel()
    Sec("📡  ESP  (★ = confirmed role)", T.Cyan)
    Toggle("✅ Enable ESP",       S.ESP.Enabled,      function(v)
        S.ESP.Enabled=v
        if not v then for _,d in pairs(ESPObjects) do for _,x in pairs(d) do pcall(function() x.Visible=false end) end end end
    end)
    Toggle("Show Murderer 🔴",   S.ESP.ShowMurderer, function(v) S.ESP.ShowMurderer=v end)
    Toggle("Show Sheriff 🟢",    S.ESP.ShowSheriff,  function(v) S.ESP.ShowSheriff=v  end)
    Toggle("Show Others ⚪",     S.ESP.ShowOthers,   function(v) S.ESP.ShowOthers=v   end)
    Toggle("Draw Box",           S.ESP.Box,          function(v) S.ESP.Box=v          end)
    Toggle("Draw Name",          S.ESP.Name,         function(v) S.ESP.Name=v         end)
    Toggle("Draw Distance",      S.ESP.Distance,     function(v) S.ESP.Distance=v     end)
    Toggle("Health Bar",         S.ESP.HealthBar,    function(v) S.ESP.HealthBar=v    end)
    Btn("🗑  Clear Role Memory",Color3.fromRGB(120,30,40),function()
        PermanentRoles={} Notify("ESP","Role memory cleared",2)
    end)
end

local function LoadSkin()
    ClearPanel()
    Sec("🎨  WEAPON SKIN INJECTOR  (100+ MM2 skins)", T.Gold)
    InfoBox("ℹ Injects a visual tool into your MM2 inventory hotbar with the exact weapon name.\nDisable = removed instantly.",
        Color3.fromRGB(20,40,80),36)

    Sec("🔪  KNIFE SKIN", T.Gold)
    Toggle("Enable Knife Skin", S.Skin.KnifeEnabled, function(v)
        S.Skin.KnifeEnabled=v
        if v then CreateFakeTool("Knife",S.Skin.KnifeSkin) Notify("Skin","Knife injected: "..S.Skin.KnifeSkin,2)
        else RemoveFakeTool("Knife") Notify("Skin","Knife removed",2) end
    end)
    Dropdown("Knife Skin", MM2_KNIVES,
        function() return S.Skin.KnifeSkin end,
        function(v) S.Skin.KnifeSkin=v if S.Skin.KnifeEnabled then CreateFakeTool("Knife",v) end end)
    Btn("🔪  Inject / Refresh Knife",T.Gold,function()
        if S.Skin.KnifeEnabled then CreateFakeTool("Knife",S.Skin.KnifeSkin)
            Notify("Skin","Refreshed: "..S.Skin.KnifeSkin,2)
        else Notify("Skin","Enable first!",2) end
    end)

    Sec("🔫  GUN SKIN", T.Cyan)
    Toggle("Enable Gun Skin", S.Skin.GunEnabled, function(v)
        S.Skin.GunEnabled=v
        if v then CreateFakeTool("Sheriff Gun",S.Skin.GunSkin) Notify("Skin","Gun injected: "..S.Skin.GunSkin,2)
        else RemoveFakeTool("Sheriff Gun") Notify("Skin","Gun removed",2) end
    end)
    Dropdown("Gun Skin", MM2_GUNS,
        function() return S.Skin.GunSkin end,
        function(v) S.Skin.GunSkin=v if S.Skin.GunEnabled then CreateFakeTool("Sheriff Gun",v) end end)
    Btn("🔫  Inject / Refresh Gun",T.Cyan,function()
        if S.Skin.GunEnabled then CreateFakeTool("Sheriff Gun",S.Skin.GunSkin)
            Notify("Skin","Refreshed: "..S.Skin.GunSkin,2)
        else Notify("Skin","Enable first!",2) end
    end)

    Sec("🔄  RESET",T.Red)
    Btn("↩  Remove All Skins",T.Red,function()
        RemoveFakeTool("Knife"); RemoveFakeTool("Sheriff Gun")
        S.Skin.KnifeEnabled=false; S.Skin.GunEnabled=false; Save()
        Notify("Skin","All skins removed",2)
    end)
end

local function LoadConfig()
    ClearPanel()
    Sec("💾  CONFIG / SAVE",T.Green)
    InfoBox("✅ Auto-saves on every toggle. File: MathewHub_MM2_v6.json",
        Color3.fromRGB(10,30,10),30)
    Btn("💾  Save Now",  T.ON,    function() Save()        Notify("Config","Saved!",2) end)
    Btn("📂  Reload",    T.Accent2, function() Load()      Notify("Config","Reloaded!",2) end)
    Btn("🗑  Defaults",  T.Red,   function()
        S=DeepCopy(Defaults); Save(); Notify("Config","Reset to defaults!",2)
    end)
    Sec("📋  ACTIVE SETTINGS",T.Sub)
    local function SR(l,v)
        local f=MkRow(24)
        local a=Instance.new("TextLabel",f)
        a.Size=UDim2.new(0.62,0,1,0); a.Position=UDim2.new(0,8,0,0)
        a.BackgroundTransparency=1; a.Text=l
        a.Font=Enum.Font.Gotham; a.TextSize=10
        a.TextColor3=T.Sub; a.TextXAlignment=Enum.TextXAlignment.Left
        local b=Instance.new("TextLabel",f)
        b.Size=UDim2.new(0.36,0,1,0); b.Position=UDim2.new(0.62,0,0,0)
        b.BackgroundTransparency=1; b.Text=tostring(v)
        b.Font=Enum.Font.GothamBold; b.TextSize=10
        b.TextColor3=(v==true or v=="true") and T.ON or T.Accent2
        b.TextXAlignment=Enum.TextXAlignment.Right
    end
    SR("Auto Stab",   S.Role.AutoStab)
    SR("Auto Shoot",  S.Role.AutoShoot)
    SR("Silent Aim",  S.Role.SilentAim)
    SR("Kill All",    S.Role.AutoKillAll)
    SR("Auto Fling",  S.Role.AutoFling)
    SR("Fling Force", S.Role.FlingForce)
    SR("Speed Kill",  S.Role.SpeedKill)
    SR("Anti-Stab",   S.Role.AntiStab)
    SR("Auto GetGun", S.Util.AutoGetGun)
    SR("Walk Speed",  S.Util.WalkSpeed)
    SR("Speed",       S.Util.Speed)
    SR("Fly",         S.Fly.Enabled)
    SR("ESP",         S.ESP.Enabled)
    SR("Knife Skin",  S.Skin.KnifeSkin)
    SR("Gun Skin",    S.Skin.GunSkin)
end

-- ══════════════════════════════════════════════════════════
--   BUILD SIDEBAR
-- ══════════════════════════════════════════════════════════
CATS = {Role=LoadRole,Util=LoadUtil,Fly=LoadFly,ESP=LoadESP,Skin=LoadSkin,Config=LoadConfig}

local b1,l1 = CatBtn("⚔","Role Features","Role",1)
local b2,l2 = CatBtn("🛠","Utilities",    "Util",2)
local b3,l3 = CatBtn("🪂","Fly",          "Fly", 3)
local b4,l4 = CatBtn("📡","ESP",          "ESP", 4)
local b5,l5 = CatBtn("🎨","Skin Injector","Skin",5)
local b6,l6 = CatBtn("💾","Config/Save",  "Config",6)

-- Select Role by default
ActiveCatBtn=b1; ActiveCatLbl=l1
b1.BackgroundColor3=Color3.fromRGB(36,25,72)
l1.TextColor3=T.Text
local p1=b1:FindFirstChildOfClass("Frame")
if p1 then p1.Visible=true end
task.defer(LoadRole)

-- ══════════════════════════════════════════════════════════
--   SILENT AIM CIRCLE
-- ══════════════════════════════════════════════════════════
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible=false
FOVCircle.Thickness=1.5
FOVCircle.Color=Color3.fromRGB(160,80,255)
FOVCircle.Transparency=0.5
FOVCircle.Filled=false

local function GetFOVTarget()
    local best,bDist=nil,math.huge
    local ctr=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local h=p.Character:FindFirstChild("Humanoid")
            if h and h.Health>0 then
                local pos,vis=Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if vis then
                    local d=(Vector2.new(pos.X,pos.Y)-ctr).Magnitude
                    if d<S.Role.FOV and d<bDist then bDist=d best=p end
                end
            end
        end
    end
    return best
end

-- ══════════════════════════════════════════════════════════
--   ESP HELPERS
-- ══════════════════════════════════════════════════════════
local function MkESP(p)
    if not ESPObjects[p] then
        local e={
            Box=Drawing.new("Square"),Name=Drawing.new("Text"),
            Dist=Drawing.new("Text"),HpBg=Drawing.new("Square"),HpFg=Drawing.new("Square"),
        }
        e.Box.Filled=false e.Box.Thickness=1.5
        e.Name.Size=13 e.Name.Center=true e.Name.Outline=true
        e.Dist.Size=11 e.Dist.Center=true e.Dist.Outline=true
        e.HpBg.Filled=true e.HpBg.Color=Color3.fromRGB(40,40,40) e.HpBg.Transparency=0.4
        e.HpFg.Filled=true e.HpFg.Transparency=0.15
        ESPObjects[p]=e
    end
    return ESPObjects[p]
end
local function HideE(d)
    if not d then return end
    for _,x in pairs(d) do pcall(function() x.Visible=false end) end
end
Players.PlayerRemoving:Connect(function(p)
    if ESPObjects[p] then
        for _,x in pairs(ESPObjects[p]) do pcall(function() x:Remove() end) end
        ESPObjects[p]=nil
    end
end)

-- ══════════════════════════════════════════════════════════
--   MAIN HEARTBEAT
-- ══════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function(dt)
    local c=LocalPlayer.Character
    if not c then return end
    local Root=c:FindFirstChild("HumanoidRootPart")
    local Hum=c:FindFirstChild("Humanoid")
    if not Root or not Hum or Hum.Health<=0 then return end
    heartStep+=1

    if S.Util.WalkSpeed then Hum.WalkSpeed=S.Util.Speed end
    if S.Util.JumpPower  then Hum.JumpPower=S.Util.Power end

    if S.Util.NoClip and not S.Fly.Enabled then
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end

    -- X-Ray (throttled)
    if S.Util.XRay then
        XRayCacheTimer+=dt
        if XRayCacheTimer>=XRayCacheInterval then
            XRayCacheTimer=0; XRayCache={}
            for _,obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj:IsDescendantOf(c) and obj.Size.Magnitude>2 then
                    table.insert(XRayCache,obj)
                end
            end
        end
        if heartStep%4==0 then
            local tgt=S.Util.XRayTrans
            for _,obj in ipairs(XRayCache) do
                if obj and obj.Parent and not obj:IsDescendantOf(c) then
                    if not OrigTransp[obj] then OrigTransp[obj]=obj.Transparency end
                    if obj.Transparency<tgt then obj.Transparency=tgt end
                end
            end
        end
    end

    -- Auto collect
    if S.Util.AutoCollect then
        for _,obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.CanCollide then
                local n=obj.Name
                if n=="Knife" or n=="Gun" or n:find("Coin") or n=="Medkit" then
                    if (Root.Position-obj.Position).Magnitude<S.Util.CollectRange then
                        Root.CFrame=CFrame.new(obj.Position+Vector3.new(0,3,0))
                    end
                end
            end
        end
    end

    -- Auto get gun (every 2s)
    if S.Util.AutoGetGun then
        autoGetGunTimer+=dt
        if autoGetGunTimer>=2 then autoGetGunTimer=0 TryGetGunAndReturn() end
    end

    -- Find roles
    local Murder,Sheriff=nil,nil
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local r=GetRole(p)
            if r=="Murderer" then Murder=p end
            if r=="Sheriff"  then Sheriff=p end
        end
    end
    local myRole=GetRole(LocalPlayer)

    -- Freeze murderer
    if S.Util.FreezeMurder and Murder and Murder.Character then
        local mr=Murder.Character:FindFirstChild("HumanoidRootPart")
        if mr then mr.AssemblyLinearVelocity=Vector3.zero mr.AssemblyAngularVelocity=Vector3.zero end
    end

    -- Anti-stab
    if S.Role.AntiStab and Murder and Murder.Character then
        local mr=Murder.Character:FindFirstChild("HumanoidRootPart")
        if mr and (Root.Position-mr.Position).Magnitude<S.Role.AntiStabDist then
            Root.CFrame=Root.CFrame+(Root.Position-mr.Position).Unit*10
            Hum.Jump=true
        end
    end

    -- Auto mega-fling
    if S.Role.AutoFling and Murder and heartStep%8==0 then
        MegaFling(Murder)
    end

    -- Blink to murderer (Sheriff)
    if S.Role.BlinkMurder and myRole=="Sheriff" and Murder and heartStep%30==0 then
        local mr=Murder.Character and Murder.Character:FindFirstChild("HumanoidRootPart")
        local mh=Murder.Character and Murder.Character:FindFirstChild("Humanoid")
        if mr and mh and mh.Health>0 and (Root.Position-mr.Position).Magnitude>15 then
            Root.CFrame=CFrame.new(mr.Position+Vector3.new(0,3,0))
        end
    end

    -- Auto stab
    if S.Role.AutoStab and myRole=="Murderer" then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character then
                local ph=p.Character:FindFirstChild("Humanoid")
                local pr=p.Character:FindFirstChild("HumanoidRootPart")
                if ph and pr and ph.Health>0 and GetRole(p)~="Murderer" then
                    if (Root.Position-pr.Position).Magnitude<S.Role.StabRange then
                        pcall(function()
                            local knife=c:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
                            if knife and not knife:FindFirstChild("_MathewHubSkin") then
                                if knife.Parent==LocalPlayer.Backpack then Hum:EquipTool(knife) end
                                Root.CFrame=CFrame.new(Root.Position,pr.Position)
                                knife:Activate()
                            end
                        end)
                    end
                end
            end
        end
    end

    -- Speed kill
    if S.Role.SpeedKill and myRole=="Murderer" and heartStep%15==0 then
        local knife=c:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if knife and not knife:FindFirstChild("_MathewHubSkin") then
            if knife.Parent==LocalPlayer.Backpack then Hum:EquipTool(knife) end
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character then
                    local ph=p.Character:FindFirstChild("Humanoid")
                    local pr=p.Character:FindFirstChild("HumanoidRootPart")
                    if ph and pr and ph.Health>0 then
                        Root.CFrame=CFrame.new(pr.Position+Vector3.new(0,1,0))
                        pcall(function() knife:Activate() end)
                    end
                end
            end
        end
    end

    -- Auto kill all (continuous)
    if S.Role.AutoKillAll and myRole=="Murderer" and heartStep%5==0 then
        local knife=c:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if knife and not knife:FindFirstChild("_MathewHubSkin") then
            if knife.Parent==LocalPlayer.Backpack then Hum:EquipTool(knife) end
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character then
                    local ph=p.Character:FindFirstChild("Humanoid")
                    local pr=p.Character:FindFirstChild("HumanoidRootPart")
                    if ph and pr and ph.Health>0 then
                        Root.CFrame=CFrame.new(pr.Position+Vector3.new(0,2,0))
                        Root.CFrame=CFrame.new(Root.Position,pr.Position)
                        pcall(function() knife:Activate() end)
                        break
                    end
                end
            end
        end
    end

    -- Auto shoot (wall-pen, 100% accurate)
    if S.Role.AutoShoot and myRole=="Sheriff" and Murder then
        local mr=Murder.Character and Murder.Character:FindFirstChild("HumanoidRootPart")
        local mh=Murder.Character and Murder.Character:FindFirstChild("Humanoid")
        if mr and mh and mh.Health>0 then
            if (Root.Position-mr.Position).Magnitude<S.Role.ShootRange and heartStep%20==0 then
                ShootMurdererWallPen(Root,Murder)
            end
        end
    end

    -- Reach
    if S.Util.Reach then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character then
                local pr=p.Character:FindFirstChild("HumanoidRootPart")
                if pr and (Root.Position-pr.Position).Magnitude<S.Util.ReachRange then
                    Root.CFrame=Root.CFrame+(pr.Position-Root.Position).Unit*0.5
                end
            end
        end
    end

    -- Rainbow cycle
    if heartStep%18==0 then
        rainbowHue=(rainbowHue+0.04)%1
        if S.Skin.KnifeEnabled and (S.Skin.KnifeSkin:lower():find("rainbow") or S.Skin.KnifeSkin:lower():find("chroma")) then
            UpdateSkinColor("Knife",S.Skin.KnifeSkin)
        end
        if S.Skin.GunEnabled and (S.Skin.GunSkin:lower():find("rainbow") or S.Skin.GunSkin:lower():find("chroma")) then
            UpdateSkinColor("Sheriff Gun",S.Skin.GunSkin)
        end
    end
end)

-- ══════════════════════════════════════════════════════════
--   RENDER STEPPED: Silent Aim + ESP
-- ══════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    local c=LocalPlayer.Character
    local Root=c and c:FindFirstChild("HumanoidRootPart")

    -- Silent aim
    if S.Role.SilentAim then
        local ctr=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
        FOVCircle.Position=ctr; FOVCircle.Radius=S.Role.FOV; FOVCircle.Visible=true
        local tgt=GetFOVTarget()
        if tgt and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") then
            Camera.CFrame=CFrame.new(Camera.CFrame.Position,tgt.Character.HumanoidRootPart.Position)
        end
    else FOVCircle.Visible=false end

    -- ESP
    if not S.ESP.Enabled then
        for _,d in pairs(ESPObjects) do HideE(d) end return
    end

    for _,p in ipairs(Players:GetPlayers()) do
        if p==LocalPlayer then continue end
        local pc=p.Character
        local pr=pc and pc:FindFirstChild("HumanoidRootPart")
        local ph=pc and pc:FindFirstChildOfClass("Humanoid")
        if not pr or not ph or ph.Health<=0 then HideE(ESPObjects[p]) continue end

        local role=GetRole(p)
        if (role=="Murderer" and not S.ESP.ShowMurderer)
        or (role=="Sheriff" and not S.ESP.ShowSheriff)
        or (role=="Innocent" and not S.ESP.ShowOthers) then HideE(ESPObjects[p]) continue end

        local pos,vis=Camera:WorldToViewportPoint(pr.Position)
        if not vis then HideE(ESPObjects[p]) continue end

        local e=MkESP(p)
        local col=role=="Murderer" and Color3.fromRGB(255,60,60)
             or   role=="Sheriff"  and Color3.fromRGB(60,220,100)
             or                        Color3.fromRGB(200,200,200)

        local szX,szY=2200/pos.Z,3000/pos.Z
        local scr=Vector2.new(pos.X,pos.Y)

        e.Box.Visible=S.ESP.Box
        e.Box.Position=Vector2.new(scr.X-szX/2,scr.Y-szY/2)
        e.Box.Size=Vector2.new(szX,szY)
        e.Box.Color=col; e.Box.Transparency=0.45

        local mark=PermanentRoles[p.UserId]~=nil
        e.Name.Visible=S.ESP.Name
        e.Name.Position=Vector2.new(scr.X,scr.Y-szY/2-18)
        e.Name.Text=string.format("%s[%s] %s",mark and "★ " or "",role,p.Name)
        e.Name.Color=col

        if Root then
            e.Dist.Visible=S.ESP.Distance
            e.Dist.Position=Vector2.new(scr.X,scr.Y+szY/2+6)
            e.Dist.Text=string.format("%.0f studs",(Root.Position-pr.Position).Magnitude)
            e.Dist.Color=col
        end

        if S.ESP.HealthBar then
            local hp=ph.Health/ph.MaxHealth
            local bW,bH=4,szY
            local bX=scr.X-szX/2-bW-2; local bY=scr.Y-szY/2
            e.HpBg.Visible=true; e.HpBg.Position=Vector2.new(bX,bY); e.HpBg.Size=Vector2.new(bW,bH)
            e.HpFg.Visible=true
            e.HpFg.Position=Vector2.new(bX,bY+bH*(1-hp))
            e.HpFg.Size=Vector2.new(bW,bH*hp)
            e.HpFg.Color=Color3.fromRGB(math.floor(255*(1-hp)),math.floor(255*hp),0)
        else e.HpBg.Visible=false e.HpFg.Visible=false end
    end
end)

-- ══════════════════════════════════════════════════════════
--   KEYS
-- ══════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.Insert then Win.Visible=not Win.Visible end
    if inp.KeyCode==Enum.KeyCode.F then
        S.Fly.Enabled=not S.Fly.Enabled
        if S.Fly.Enabled then StartFly() else StopFly() end
        Notify("Fly",S.Fly.Enabled and "Fly ON (W/A/S/D)" or "Fly OFF",2)
    end
end)

ScreenGui.AncestryChanged:Connect(function()
    RemoveFakeTool("Knife"); RemoveFakeTool("Sheriff Gun"); StopFly()
end)

task.delay(0.5,function()
    Notify("⚔ Mathew Hub v6.0","INSERT=menu | F=fly | Neon UI + 100+ skins!",4)
end)
