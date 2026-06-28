--[[
╔══════════════════════════════════════════════════════════╗
║   MATHEW HUB  ★  MM2  ★  v9.0  RED EDITION             ║
║   Horizontal tab menu  |  RightCtrl = toggle             ║
║                                                          ║
║  Features: Fling, Skin Spawner, Hitbox, Silent Aim,     ║
║  ESP, Carry, Auto Shoot, Keybinds, Save/Load             ║
╚══════════════════════════════════════════════════════════╝
]]

-- ── Duplicate guard ────────────────────────────────────────
if getgenv().MathewHubV9 then
    pcall(function() getgenv().MathewHubV9:Destroy() end)
end
getgenv().MathewHubV9 = true

-- ── Services ───────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local StarterGui       = game:GetService("StarterGui")
local HttpService      = game:GetService("HttpService")
local Debris           = game:GetService("Debris")
local TweenService     = game:GetService("TweenService")

local Camera      = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ── Notify ─────────────────────────────────────────────────
local function Notify(t, x, d)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=t, Text=x, Duration=d or 3})
    end)
end

-- ── Settings ───────────────────────────────────────────────
local SAVE_FILE = "MathewHub_v9.json"

local Defaults = {
    Combat = {
        AutoStab=false,    StabRange=15,
        AutoShoot=false,   ShootRange=200,
        SilentAim=false,   FOV=120,
        AutoKillAll=false, SafeSpotY=300,
        KnifeAura=false,   KnifeAuraRange=15,
        AntiStab=false,    AntiStabDist=12,
    },
    Hitbox = {
        Enabled=false,  Size=10,
        Mode="Local",   -- "Local" = expand your own, "Remote" = expand targets
        Visualize=false,
    },
    Teleport = {
        AutoGetGun=false,
        CarryEnabled=false,
    },
    Visuals = {
        ESP=false,
        RoleColors=false,
        Crosshair=false,    CrosshairSize=8, CrosshairThick=2,
        XRay=false,         XRayTrans=0.5,
        NameTags=false,
    },
    AutoFarm = {
        AutoCoins=false, CoinRange=150,
        HighRole=false,
    },
    Local = {
        WalkSpeed=false, Speed=32,
        JumpPower=false, Power=60,
        NoClip=false,
        Fly=false,       FlySpeed=60,
    },
    Skin = {
        -- Skin spawner: choose any knife/gun and add to inventory
        KnifeEnabled=false, KnifeSkin="Default Knife",
        GunEnabled=false,   GunSkin="Default Gun",
    },
    Keys = {
        Menu="RightControl",
        Fly="F",
        GetGun="G",
        SafeSpot="H",
        Throw="T",
        AutoStab="None",
        AutoShoot="None",
        SilentAim="None",
        KillAll="None",
        Fling="None",
    },
}

local function DeepCopy(t)
    local c={}
    for k,v in pairs(t) do c[k]=type(v)=="table" and DeepCopy(v) or v end
    return c
end
local S = DeepCopy(Defaults)

local function Save()
    pcall(function() writefile(SAVE_FILE, HttpService:JSONEncode(S)) end)
end
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

-- ── Full MM2 Knife + Gun Lists (from wiki) ────────────────
local MM2_KNIVES = {
    -- Default
    "Default Knife",
    -- Common
    "Green","Blue","Red","Yellow","Purple","Orange","Pink","Cyan","White","Black",
    "Checker","Caution","Marble","Graffiti","High Tech","Hardened","Ocean","Space",
    "Tiger","Leaf","Tribal","Retro","Pirate","Adurite","Copper","Combat",
    -- Uncommon
    "Neon","Lovely","Pearl","Pearlshine","Void","Prismatic","Fire","Lava","Nebula",
    "Galactic","Viper","Slasher","Fang","Deathshard","Saw","Tides","Flora",
    "Splat","Spring","Fox",
    -- Rare
    "Darkbringer","Lightbringer","Gemstone","Shark","Laser","Heat","Rainbow",
    "Elderwood","Corrupt","Seer","Luger","Batwing","Spider","Clockwork","Pixel",
    "Candy","Blizzard","Icebreath",
    -- Legendary
    "Vampire","Hallows","Ancient Blade","Icedriller","Snowflake","Cane",
    "Gingerblade","Boneblade","Cookiecane","Swirly","Makeshift","Candleflame",
    "Phantom","Specter","Bat","Swirlyblade","Harvester",
    -- Godly
    "Chroma Fang","Chroma Deathshard","Chroma Saw","Chroma Tides","Chroma Slasher",
    "Chroma Gemstone","Chroma Luger","Chroma Shark","Chroma Laser","Chroma Heat",
    "Chroma Darkbringer","Chroma Lightbringer","Chroma Elderwood Blade",
    "Chroma Boneblade","Chroma Gingerblade","Chroma Evergreen","Chroma Candleflame",
    "Chroma Bauble",
    -- Vintage / Ancient
    "Nik's Scythe","Elderwood Scythe","Harvester","Eternal","Hallows Eve Blade",
    -- Seasonal
    "Hallowscythe","Ice Dagger","Cane Knife","Bone Dagger","Candy Cane",
    -- Evo
    "Evo Knife","Evo Deathshard","Evo Luger","Evo Fang",
    -- Shop / Effects
    "Knifeception","Blue Flaming Knife","Green Flaming Knife","Pink Flaming Knife",
    "Flaming Knife","Ghostify","Musical Knife","Heartify",
    -- Chroma Evo
    "Chroma Evo Knife",
}

local MM2_GUNS = {
    "Default Gun",
    -- Common
    "Green Gun","Blue Gun","Red Gun","Yellow Gun","Purple Gun","Orange Gun",
    "Pink Gun","Cyan Gun","White Gun","Black Gun","Checker Gun","Adurite Gun",
    "Copper Gun","Combat Gun","Marble Gun","Graffiti Gun","High Tech Gun",
    "Hardened Gun","Ocean Gun","Space Gun",
    -- Uncommon
    "Galactic","Neon Gun","Lovely Gun","Pearl Gun","Pearlshine Gun","Void Gun",
    "Prismatic Gun","Fire Gun","Lava Gun","Nebula Gun","Viper Gun",
    -- Rare
    "Shark","Laser","Heat Gun","Rainbow Gun","Luger","Blaster","Amerilaser",
    "Plasmabeam","Elderwood Revolver","Hallowgun","Red Luger","Green Luger",
    "Iceblaster","Swirlygun","Wavy",
    -- Godly
    "Chroma Luger","Chroma Shark","Chroma Laser","Chroma Heat","Chroma Swirlygun",
    "Chroma Evergun",
    -- Special
    "Sheriff Gun","Gun","Hallows Eve Gun","Ice Gun",
}

local SKIN_COLORS = {
    ["Default Knife"]=Color3.fromRGB(200,180,140),["Default Gun"]=Color3.fromRGB(180,180,180),
    ["Shark"]=Color3.fromRGB(120,180,220),["Laser"]=Color3.fromRGB(255,255,0),
    ["Heat"]=Color3.fromRGB(255,100,0),["Elderwood"]=Color3.fromRGB(100,60,20),
    ["Luger"]=Color3.fromRGB(220,200,50),["Darkbringer"]=Color3.fromRGB(60,0,100),
    ["Lightbringer"]=Color3.fromRGB(255,240,100),["Rainbow"]=Color3.fromRGB(255,100,200),
    ["Gemstone"]=Color3.fromRGB(0,200,255),["Chroma Fang"]=Color3.fromRGB(255,0,255),
    ["Chroma Luger"]=Color3.fromRGB(255,200,0),["Nik's Scythe"]=Color3.fromRGB(255,0,0),
    ["Hallowscythe"]=Color3.fromRGB(255,100,0),["Sheriff Gun"]=Color3.fromRGB(200,160,80),
    ["Plasmabeam"]=Color3.fromRGB(0,200,255),["Wavy"]=Color3.fromRGB(200,100,255),
    ["Neon"]=Color3.fromRGB(0,255,150),["Void"]=Color3.fromRGB(20,0,40),
    ["Fire"]=Color3.fromRGB(255,80,0),["Lava"]=Color3.fromRGB(200,30,10),
    ["Galactic"]=Color3.fromRGB(80,0,180),["Prismatic"]=Color3.fromRGB(255,100,255),
    ["Vampire"]=Color3.fromRGB(150,0,0),["Eternal"]=Color3.fromRGB(200,200,255),
    ["Blizzard"]=Color3.fromRGB(180,220,255),["Ice Dagger"]=Color3.fromRGB(150,220,255),
}

-- ── State ──────────────────────────────────────────────────
local rainbowHue      = 0
local ESPObjects      = {}
local OrigTransp      = {}
local XRayCache       = {}
local XRayCacheTimer  = 0
local heartStep       = 0
local FakeSkinTools   = {}
local PermanentRoles  = {}
local FlyConn         = nil
local FlyBV           = nil
local FlyBG           = nil
local carriedPlayer   = nil
local carryConn       = nil
local isGrabbingGun   = false
local autoGetGunTimer = 0
local CrossLines      = {}
-- Hitbox visuals
local HitboxPart      = nil

-- ── RED THEME ──────────────────────────────────────────────
local T = {
    BG      = Color3.fromRGB(14, 10, 12),
    TopBg   = Color3.fromRGB(20, 14, 16),
    TabBg   = Color3.fromRGB(18, 12, 14),
    TabSel  = Color3.fromRGB(28, 16, 18),
    Panel   = Color3.fromRGB(16, 11, 13),
    Card    = Color3.fromRGB(22, 15, 17),
    CardHov = Color3.fromRGB(30, 20, 22),
    Accent  = Color3.fromRGB(220, 40,  60),   -- main red
    Accent2 = Color3.fromRGB(255, 80, 100),   -- bright red
    Glow    = Color3.fromRGB(255, 120, 140),  -- glow
    ON      = Color3.fromRGB(220, 40, 60),
    OFF     = Color3.fromRGB(55, 38, 42),
    Text    = Color3.new(1, 1, 1),
    Sub     = Color3.fromRGB(190, 160, 165),
    Dim     = Color3.fromRGB(110, 80, 85),
    Div     = Color3.fromRGB(50, 32, 36),
    Green   = Color3.fromRGB(0, 210, 100),
    Blue    = Color3.fromRGB(60, 140, 255),
    Gold    = Color3.fromRGB(255, 200, 50),
    Purple  = Color3.fromRGB(160, 50, 255),
}

-- ══════════════════════════════════════════════════════════
--   GUI  ─  HORIZONTAL TAB MENU
-- ══════════════════════════════════════════════════════════
local Gui = Instance.new("ScreenGui")
Gui.Name="MathewHub_v9"; Gui.ResetOnSpawn=false
Gui.IgnoreGuiInset=true; Gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
Gui.Parent=LocalPlayer:WaitForChild("PlayerGui")
getgenv().MathewHubGui=Gui

-- Main window
local Win = Instance.new("Frame", Gui)
Win.Size=UDim2.new(0,580,0,440); Win.Position=UDim2.new(0.5,-290,0.5,-220)
Win.BackgroundColor3=T.BG; Win.BorderSizePixel=0
Win.Active=true; Win.Draggable=true
Instance.new("UICorner",Win).CornerRadius=UDim.new(0,10)
local WS=Instance.new("UIStroke",Win); WS.Color=T.Accent; WS.Thickness=1.5; WS.Transparency=0.2

-- ── TOP BAR ────────────────────────────────────────────────
local TopBar=Instance.new("Frame",Win)
TopBar.Size=UDim2.new(1,0,0,44); TopBar.BackgroundColor3=T.TopBg; TopBar.BorderSizePixel=0
Instance.new("UICorner",TopBar).CornerRadius=UDim.new(0,10)
local TFix=Instance.new("Frame",TopBar)
TFix.Size=UDim2.new(1,0,0.5,0); TFix.Position=UDim2.new(0,0,0.5,0)
TFix.BackgroundColor3=T.TopBg; TFix.BorderSizePixel=0
-- Red accent bottom line
local TLine=Instance.new("Frame",TopBar)
TLine.Size=UDim2.new(1,0,0,2); TLine.Position=UDim2.new(0,0,1,-2)
TLine.BackgroundColor3=T.Accent; TLine.BorderSizePixel=0

-- Anime face logo circle (red with ★ symbol as placeholder for anime boy logo)
local LogoCircle=Instance.new("Frame",TopBar)
LogoCircle.Size=UDim2.new(0,32,0,32); LogoCircle.Position=UDim2.new(0,8,0.5,-16)
LogoCircle.BackgroundColor3=T.Accent; LogoCircle.BorderSizePixel=0
Instance.new("UICorner",LogoCircle).CornerRadius=UDim.new(1,0)
-- Inner ring
local LogoRing=Instance.new("UIStroke",LogoCircle); LogoRing.Color=T.Glow; LogoRing.Thickness=2
-- Logo text (⚡ as anime-like icon — you can swap with an ImageLabel if you have an asset ID)
local LogoTxt=Instance.new("TextLabel",LogoCircle)
LogoTxt.Size=UDim2.new(1,0,1,0); LogoTxt.BackgroundTransparency=1
LogoTxt.Text="⚡"; LogoTxt.TextSize=16; LogoTxt.TextColor3=Color3.new(1,1,1)

-- Script name
local TitleL=Instance.new("TextLabel",TopBar)
TitleL.Size=UDim2.new(0,130,1,0); TitleL.Position=UDim2.new(0,46,0,0)
TitleL.BackgroundTransparency=1; TitleL.Text="MATHEW HUB"
TitleL.Font=Enum.Font.GothamBlack; TitleL.TextSize=14; TitleL.TextColor3=T.Accent2
TitleL.TextXAlignment=Enum.TextXAlignment.Left
-- Gradient on title
local TLG=Instance.new("UIGradient",TitleL)
TLG.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,T.Glow),
    ColorSequenceKeypoint.new(0.5,T.Accent),
    ColorSequenceKeypoint.new(1,T.Accent2),
}

-- Version badge
local VBadge=Instance.new("Frame",TopBar)
VBadge.Size=UDim2.new(0,50,0,20); VBadge.Position=UDim2.new(0,178,0.5,-10)
VBadge.BackgroundColor3=T.Accent; VBadge.BorderSizePixel=0
Instance.new("UICorner",VBadge).CornerRadius=UDim.new(1,0)
local VLbl=Instance.new("TextLabel",VBadge)
VLbl.Size=UDim2.new(1,0,1,0); VLbl.BackgroundTransparency=1
VLbl.Text="v9.0"; VLbl.Font=Enum.Font.GothamBold; VLbl.TextSize=9; VLbl.TextColor3=T.Text

-- Hint
local HintL=Instance.new("TextLabel",TopBar)
HintL.Size=UDim2.new(0,200,1,0); HintL.Position=UDim2.new(1,-230,0,0)
HintL.BackgroundTransparency=1; HintL.Text="RightCtrl = toggle menu"
HintL.Font=Enum.Font.Gotham; HintL.TextSize=9; HintL.TextColor3=T.Dim
HintL.TextXAlignment=Enum.TextXAlignment.Right

-- Close button
local CloseB=Instance.new("TextButton",TopBar)
CloseB.Size=UDim2.new(0,26,0,26); CloseB.Position=UDim2.new(1,-32,0.5,-13)
CloseB.BackgroundColor3=T.Accent; CloseB.Text="✕"
CloseB.Font=Enum.Font.GothamBold; CloseB.TextSize=12; CloseB.TextColor3=T.Text
Instance.new("UICorner",CloseB).CornerRadius=UDim.new(0,5)
CloseB.MouseButton1Click:Connect(function() Win.Visible=false end)

-- ── HORIZONTAL TAB BAR ─────────────────────────────────────
local TabBar=Instance.new("Frame",Win)
TabBar.Size=UDim2.new(1,0,0,36); TabBar.Position=UDim2.new(0,0,0,44)
TabBar.BackgroundColor3=T.TabBg; TabBar.BorderSizePixel=0

local TabLayout=Instance.new("UIListLayout",TabBar)
TabLayout.FillDirection=Enum.FillDirection.Horizontal
TabLayout.Padding=UDim.new(0,0); TabLayout.SortOrder=Enum.SortOrder.LayoutOrder

-- Red underline indicator (slides under active tab)
local TabIndicator=Instance.new("Frame",TabBar)
TabIndicator.Size=UDim2.new(0,70,0,2); TabIndicator.Position=UDim2.new(0,0,1,-2)
TabIndicator.BackgroundColor3=T.Accent; TabIndicator.BorderSizePixel=0
TabIndicator.ZIndex=5

-- ── CONTENT AREA ───────────────────────────────────────────
local ContentArea=Instance.new("Frame",Win)
ContentArea.Size=UDim2.new(1,0,1,-82); ContentArea.Position=UDim2.new(0,0,0,82)
ContentArea.BackgroundColor3=T.Panel; ContentArea.BorderSizePixel=0

local ContentScroll=Instance.new("ScrollingFrame",ContentArea)
ContentScroll.Size=UDim2.new(1,-6,1,-6); ContentScroll.Position=UDim2.new(0,3,0,3)
ContentScroll.BackgroundTransparency=1; ContentScroll.BorderSizePixel=0
ContentScroll.ScrollBarThickness=3; ContentScroll.ScrollBarImageColor3=T.Accent
ContentScroll.CanvasSize=UDim2.new(0,0,0,0); ContentScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
local CL=Instance.new("UIListLayout",ContentScroll)
CL.Padding=UDim.new(0,4); CL.SortOrder=Enum.SortOrder.LayoutOrder
Instance.new("UIPadding",ContentScroll).PaddingTop=UDim.new(0,6)

-- ── WIDGET HELPERS ─────────────────────────────────────────
local wOrder=0
local function WO() wOrder+=1 return wOrder end

local function ClearContent()
    for _,c in ipairs(ContentScroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    wOrder=0
end

local function SecHdr(txt,col)
    local f=Instance.new("Frame",ContentScroll)
    f.Size=UDim2.new(1,0,0,24); f.BackgroundTransparency=1; f.LayoutOrder=WO()
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-12,1,0); l.Position=UDim2.new(0,12,0,0)
    l.BackgroundTransparency=1; l.Text=txt:upper()
    l.Font=Enum.Font.GothamBold; l.TextSize=10; l.TextColor3=col or T.Accent
    l.TextXAlignment=Enum.TextXAlignment.Left
    -- divider line
    local dv=Instance.new("Frame",f)
    dv.Size=UDim2.new(1,-12,0,1); dv.Position=UDim2.new(0,12,1,-1)
    dv.BackgroundColor3=col or T.Accent; dv.BorderSizePixel=0
    local dvg=Instance.new("UIGradient",dv)
    dvg.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,col or T.Accent),
        ColorSequenceKeypoint.new(0.6,T.Div),
        ColorSequenceKeypoint.new(1,Color3.new(0,0,0)),
    }
end

-- Toggle (pill style, red theme)
local function Toggle(label, desc, init, onChange)
    local row=Instance.new("Frame",ContentScroll)
    row.Size=UDim2.new(1,0,0,52); row.BackgroundColor3=T.Card
    row.BorderSizePixel=0; row.LayoutOrder=WO()
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.76,0,0,22); lbl.Position=UDim2.new(0,12,0,6)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=12
    lbl.TextColor3=T.Text; lbl.TextXAlignment=Enum.TextXAlignment.Left

    if desc then
        local dl=Instance.new("TextLabel",row)
        dl.Size=UDim2.new(0.85,0,0,18); dl.Position=UDim2.new(0,12,0,28)
        dl.BackgroundTransparency=1; dl.Text=desc
        dl.Font=Enum.Font.Gotham; dl.TextSize=9
        dl.TextColor3=T.Sub; dl.TextXAlignment=Enum.TextXAlignment.Left
        dl.TextWrapped=true
    end

    -- Pill toggle
    local pill=Instance.new("Frame",row)
    pill.Size=UDim2.new(0,38,0,22); pill.Position=UDim2.new(1,-50,0.5,-11)
    pill.BorderSizePixel=0
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)

    local dot=Instance.new("Frame",pill)
    dot.Size=UDim2.new(0,18,0,18); dot.Position=UDim2.new(0,2,0.5,-9)
    dot.BorderSizePixel=0
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    dot.BackgroundColor3=T.Text

    local st=init or false
    local function Ref()
        pill.BackgroundColor3=st and T.ON or T.OFF
        TweenService:Create(dot,TweenInfo.new(0.14),
            {Position=st and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)}):Play()
    end
    Ref()

    local clickBtn=Instance.new("TextButton",row)
    clickBtn.Size=UDim2.new(1,0,1,0); clickBtn.BackgroundTransparency=1; clickBtn.Text=""
    clickBtn.MouseButton1Click:Connect(function()
        st=not st; Ref(); onChange(st); Save()
    end)
    row.MouseEnter:Connect(function() row.BackgroundColor3=T.CardHov end)
    row.MouseLeave:Connect(function() row.BackgroundColor3=T.Card end)
    return function(v) st=v Ref() end
end

local function MkInput(label, init, minV, maxV, onChange)
    local row=Instance.new("Frame",ContentScroll)
    row.Size=UDim2.new(1,0,0,40); row.BackgroundColor3=T.Card
    row.BorderSizePixel=0; row.LayoutOrder=WO()
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.65,0,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextColor3=T.Sub
    lbl.TextXAlignment=Enum.TextXAlignment.Left

    local box=Instance.new("TextBox",row)
    box.Size=UDim2.new(0,60,0,26); box.Position=UDim2.new(1,-70,0.5,-13)
    box.BackgroundColor3=Color3.fromRGB(12,8,10); box.Text=tostring(init)
    box.Font=Enum.Font.Gotham; box.TextSize=11; box.TextColor3=T.Accent2
    box.ClearTextOnFocus=false
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,5)
    local bs=Instance.new("UIStroke",box); bs.Color=T.Div

    box.FocusLost:Connect(function()
        local v=math.clamp(tonumber(box.Text) or init, minV or 1, maxV or 9999)
        box.Text=tostring(v); onChange(v); Save()
    end)
end

local function MkDropdown(label, list, getV, setV)
    local row=Instance.new("Frame",ContentScroll)
    row.Size=UDim2.new(1,0,0,40); row.BackgroundColor3=T.Card
    row.BorderSizePixel=0; row.LayoutOrder=WO()
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.32,0,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextColor3=T.Sub
    lbl.TextXAlignment=Enum.TextXAlignment.Left

    local dBtn=Instance.new("TextButton",row)
    dBtn.Size=UDim2.new(0.62,0,0,28); dBtn.Position=UDim2.new(0.36,0,0.5,-14)
    dBtn.BackgroundColor3=Color3.fromRGB(12,8,10); dBtn.Text=getV()
    dBtn.Font=Enum.Font.Gotham; dBtn.TextSize=9; dBtn.TextColor3=T.Accent2
    dBtn.ClipsDescendants=true
    Instance.new("UICorner",dBtn).CornerRadius=UDim.new(0,5)
    Instance.new("UIStroke",dBtn).Color=T.Div

    local lf=Instance.new("Frame",ContentScroll)
    lf.BackgroundColor3=Color3.fromRGB(12,8,10); lf.BorderSizePixel=0
    lf.Visible=false; lf.LayoutOrder=WO(); lf.Size=UDim2.new(1,0,0,0)
    Instance.new("UICorner",lf).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",lf).Color=T.Accent

    local inner=Instance.new("ScrollingFrame",lf)
    inner.Size=UDim2.new(1,-4,1,-4); inner.Position=UDim2.new(0,2,0,2)
    inner.BackgroundTransparency=1; inner.ScrollBarThickness=3
    inner.ScrollBarImageColor3=T.Accent; inner.CanvasSize=UDim2.new(0,0,0,#list*22)
    Instance.new("UIListLayout",inner).Padding=UDim.new(0,1)

    for _,item in ipairs(list) do
        local ib=Instance.new("TextButton",inner)
        ib.Size=UDim2.new(1,0,0,22); ib.BackgroundTransparency=1
        ib.Text="  "..item; ib.Font=Enum.Font.Gotham; ib.TextSize=10
        ib.TextColor3=T.Sub; ib.TextXAlignment=Enum.TextXAlignment.Left
        ib.MouseButton1Click:Connect(function()
            setV(item); dBtn.Text=item
            lf.Visible=false; lf.Size=UDim2.new(1,0,0,0); Save()
        end)
        ib.MouseEnter:Connect(function() ib.TextColor3=T.Accent2 end)
        ib.MouseLeave:Connect(function() ib.TextColor3=T.Sub end)
    end

    local open=false
    dBtn.MouseButton1Click:Connect(function()
        open=not open; lf.Visible=open
        lf.Size=open and UDim2.new(1,0,0,math.min(#list*22,140)) or UDim2.new(1,0,0,0)
    end)
end

local function MkBtn(label, desc, col, fn)
    local row=Instance.new("Frame",ContentScroll)
    row.Size=UDim2.new(1,0,0,44); row.BackgroundColor3=T.Card
    row.BorderSizePixel=0; row.LayoutOrder=WO()
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.66,0,0,22); lbl.Position=UDim2.new(0,12,0,5)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=12
    lbl.TextColor3=T.Text; lbl.TextXAlignment=Enum.TextXAlignment.Left

    if desc then
        local dl=Instance.new("TextLabel",row)
        dl.Size=UDim2.new(0.8,0,0,16); dl.Position=UDim2.new(0,12,0,25)
        dl.BackgroundTransparency=1; dl.Text=desc
        dl.Font=Enum.Font.Gotham; dl.TextSize=9
        dl.TextColor3=T.Sub; dl.TextXAlignment=Enum.TextXAlignment.Left
    end

    local b=Instance.new("TextButton",row)
    b.Size=UDim2.new(0,64,0,28); b.Position=UDim2.new(1,-74,0.5,-14)
    b.BackgroundColor3=col or T.Accent; b.Text="RUN"
    b.Font=Enum.Font.GothamBold; b.TextSize=10; b.TextColor3=T.Text
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    b.MouseButton1Click:Connect(fn)

    local ghost=Instance.new("TextButton",row)
    ghost.Size=UDim2.new(0.66,0,1,0); ghost.BackgroundTransparency=1; ghost.Text=""
    ghost.MouseButton1Click:Connect(fn)
    row.MouseEnter:Connect(function() row.BackgroundColor3=T.CardHov end)
    row.MouseLeave:Connect(function() row.BackgroundColor3=T.Card end)
end

-- Keybind widget
local KCODE_LIST={
    "None","F","G","H","J","K","L","N","B","V","C","X","Z",
    "Q","E","R","T","Y","U","I","O","P",
    "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10",
    "One","Two","Three","Four","Five","Six","Seven","Eight","Nine",
    "Delete","Home","End","Insert","PageUp","PageDown",
}

local function MkKeybind(label, settingKey)
    local row=Instance.new("Frame",ContentScroll)
    row.Size=UDim2.new(1,0,0,38); row.BackgroundColor3=T.Card
    row.BorderSizePixel=0; row.LayoutOrder=WO()
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.6,0,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextColor3=T.Sub
    lbl.TextXAlignment=Enum.TextXAlignment.Left

    local kBtn=Instance.new("TextButton",row)
    kBtn.Size=UDim2.new(0.34,0,0,26); kBtn.Position=UDim2.new(0.64,0,0.5,-13)
    kBtn.BackgroundColor3=Color3.fromRGB(12,8,10)
    kBtn.Text="["..S.Keys[settingKey].."]"
    kBtn.Font=Enum.Font.GothamBold; kBtn.TextSize=10; kBtn.TextColor3=T.Gold
    Instance.new("UICorner",kBtn).CornerRadius=UDim.new(0,5)
    Instance.new("UIStroke",kBtn).Color=T.Div

    local listening=false
    kBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening=true; kBtn.Text="..."; kBtn.TextColor3=T.Accent2
        local conn
        conn=UserInputService.InputBegan:Connect(function(inp,gpe)
            if gpe then return end
            local kn=inp.KeyCode.Name
            local ok=false
            for _,k in ipairs(KCODE_LIST) do if k==kn then ok=true break end end
            S.Keys[settingKey]=ok and kn or "None"
            kBtn.Text="["..S.Keys[settingKey].."]"; kBtn.TextColor3=T.Gold
            listening=false; Save(); conn:Disconnect()
        end)
    end)
end

-- 2-column row for player list
local function PlayerRow(p, onCarry, onFling)
    local role=GetRole(p)
    local rcol=role=="Murderer" and T.Accent or role=="Sheriff" and T.Blue or T.Sub

    local row=Instance.new("Frame",ContentScroll)
    row.Size=UDim2.new(1,0,0,36); row.BackgroundColor3=T.Card
    row.BorderSizePixel=0; row.LayoutOrder=WO()
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local nl=Instance.new("TextLabel",row)
    nl.Size=UDim2.new(0.44,0,1,0); nl.Position=UDim2.new(0,12,0,0)
    nl.BackgroundTransparency=1; nl.Text=p.Name
    nl.Font=Enum.Font.GothamSemibold; nl.TextSize=11
    nl.TextColor3=rcol; nl.TextXAlignment=Enum.TextXAlignment.Left

    local rl=Instance.new("TextLabel",row)
    rl.Size=UDim2.new(0.24,0,1,0); rl.Position=UDim2.new(0.44,0,0,0)
    rl.BackgroundTransparency=1; rl.Text="["..role.."]"
    rl.Font=Enum.Font.Gotham; rl.TextSize=9; rl.TextColor3=rcol
    rl.TextXAlignment=Enum.TextXAlignment.Left

    local cb=Instance.new("TextButton",row)
    cb.Size=UDim2.new(0,44,0,24); cb.Position=UDim2.new(1,-98,0.5,-12)
    cb.BackgroundColor3=T.Accent; cb.Text="Carry"
    cb.Font=Enum.Font.GothamBold; cb.TextSize=9; cb.TextColor3=T.Text
    Instance.new("UICorner",cb).CornerRadius=UDim.new(0,4)
    cb.MouseButton1Click:Connect(onCarry)

    local fb=Instance.new("TextButton",row)
    fb.Size=UDim2.new(0,44,0,24); fb.Position=UDim2.new(1,-50,0.5,-12)
    fb.BackgroundColor3=Color3.fromRGB(40,20,20); fb.Text="Fling"
    fb.Font=Enum.Font.GothamBold; fb.TextSize=9; fb.TextColor3=T.Accent2
    Instance.new("UICorner",fb).CornerRadius=UDim.new(0,4)
    Instance.new("UIStroke",fb).Color=T.Accent
    fb.MouseButton1Click:Connect(onFling)
end

-- ── HORIZONTAL TAB SYSTEM ──────────────────────────────────
local ActiveTabBtn=nil
local TABS={}

local function MakeTab(label, icon, order, fn)
    local btn=Instance.new("TextButton",TabBar)
    btn.Size=UDim2.new(0,72,1,0); btn.BackgroundColor3=T.TabBg
    btn.BackgroundTransparency=1; btn.Text=""
    btn.LayoutOrder=order; btn.BorderSizePixel=0

    local iconL=Instance.new("TextLabel",btn)
    iconL.Size=UDim2.new(1,0,0,16); iconL.Position=UDim2.new(0,0,0,4)
    iconL.BackgroundTransparency=1; iconL.Text=icon; iconL.TextSize=13
    iconL.TextColor3=T.Dim

    local nameL=Instance.new("TextLabel",btn)
    nameL.Size=UDim2.new(1,0,0,14); nameL.Position=UDim2.new(0,0,0,20)
    nameL.BackgroundTransparency=1; nameL.Text=label
    nameL.Font=Enum.Font.GothamSemibold; nameL.TextSize=9
    nameL.TextColor3=T.Dim; nameL.TextXAlignment=Enum.TextXAlignment.Center

    local function Select()
        if ActiveTabBtn and ActiveTabBtn~=btn then
            ActiveTabBtn.BackgroundTransparency=1
            local prevIcon=ActiveTabBtn:FindFirstChildOfClass("TextLabel")
            if prevIcon then prevIcon.TextColor3=T.Dim end
            -- dim all labels in prev
            for _,l in ipairs(ActiveTabBtn:GetChildren()) do
                if l:IsA("TextLabel") then l.TextColor3=T.Dim end
            end
        end
        ActiveTabBtn=btn
        btn.BackgroundColor3=T.TabSel; btn.BackgroundTransparency=0
        iconL.TextColor3=T.Accent; nameL.TextColor3=T.Accent2
        -- Slide indicator
        TweenService:Create(TabIndicator,TweenInfo.new(0.15,Enum.EasingStyle.Quad),
            {Size=UDim2.new(0,72,0,2),
             Position=UDim2.new(0,(order-1)*72,1,-2)}):Play()
        ClearContent(); fn()
    end

    btn.MouseButton1Click:Connect(Select)
    btn.MouseEnter:Connect(function()
        if ActiveTabBtn~=btn then btn.BackgroundTransparency=0.8 btn.BackgroundColor3=T.TabSel end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTabBtn~=btn then btn.BackgroundTransparency=1 end
    end)

    table.insert(TABS,{btn=btn,select=Select})
    return btn,Select
end

-- ══════════════════════════════════════════════════════════
--   GAME LOGIC FUNCTIONS
-- ══════════════════════════════════════════════════════════

-- Role detection
function GetRole(p)
    local uid=p.UserId
    if PermanentRoles[uid] then return PermanentRoles[uid] end
    if p.Team then
        local tn=p.Team.Name:lower()
        if tn:find("murder") then PermanentRoles[uid]="Murderer" return "Murderer" end
        if tn:find("sheriff") then PermanentRoles[uid]="Sheriff" return "Sheriff" end
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
        if p.Character:FindFirstChild("Knife") and not p.Character.Knife:FindFirstChild("_MathHub") then
            PermanentRoles[uid]="Murderer" return "Murderer"
        end
        if (p.Character:FindFirstChild("Sheriff Gun") or p.Character:FindFirstChild("Gun")) then
            local g=p.Character:FindFirstChild("Sheriff Gun") or p.Character:FindFirstChild("Gun")
            if g and not g:FindFirstChild("_MathHub") then
                PermanentRoles[uid]="Sheriff" return "Sheriff"
            end
        end
    end
    return "Innocent"
end

-- Hook existing + new players for instant role detection
local function HookPlayer(p)
    local function hookChar(char)
        char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") and not c:FindFirstChild("_MathHub") then
                local n=c.Name:lower()
                if n:find("knife") then PermanentRoles[p.UserId]="Murderer" end
                if n:find("gun") or n:find("sheriff") then PermanentRoles[p.UserId]="Sheriff" end
            end
        end)
    end
    if p.Character then hookChar(p.Character) end
    p.CharacterAdded:Connect(hookChar)
end
for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then HookPlayer(p) end end
Players.PlayerAdded:Connect(function(p) if p~=LocalPlayer then HookPlayer(p) end end)

LocalPlayer.CharacterAdded:Connect(function()
    PermanentRoles={}
    task.wait(1)
    if S.Skin.KnifeEnabled then SpawnFakeSkin("Knife",S.Skin.KnifeSkin) end
    if S.Skin.GunEnabled   then SpawnFakeSkin("Sheriff Gun",S.Skin.GunSkin) end
end)

-- Fly
local function StopFly()
    S.Local.Fly=false
    if FlyConn then FlyConn:Disconnect() FlyConn=nil end
    local c=LocalPlayer.Character
    if c then
        local h=c:FindFirstChild("Humanoid"); local r=c:FindFirstChild("HumanoidRootPart")
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
    local r=c:FindFirstChild("HumanoidRootPart"); local h=c:FindFirstChild("Humanoid")
    if not r or not h then return end
    h.PlatformStand=true
    FlyBV=Instance.new("BodyVelocity"); FlyBV.MaxForce=Vector3.new(1e5,1e5,1e5); FlyBV.Velocity=Vector3.zero; FlyBV.Parent=r
    FlyBG=Instance.new("BodyGyro"); FlyBG.MaxTorque=Vector3.new(1e5,1e5,1e5); FlyBG.P=1e4; FlyBG.CFrame=r.CFrame; FlyBG.Parent=r
    FlyConn=RunService.RenderStepped:Connect(function()
        if not S.Local.Fly then StopFly() return end
        local spd=S.Local.FlySpeed; local dir=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir-=Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then spd=spd*2.5 end
        FlyBV.Velocity=dir.Magnitude>0 and dir.Unit*spd or Vector3.zero
        FlyBG.CFrame=Camera.CFrame
        if S.Local.NoClip then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end
    end)
end

-- Skin Spawner: creates a fake Tool with correct name and colored appearance
local function GetSkinColor(name)
    if name:lower():find("chroma") or name:lower():find("rainbow") then
        return Color3.fromHSV(rainbowHue,1,1)
    end
    return SKIN_COLORS[name] or Color3.fromRGB(180,160,120)
end

function SpawnFakeSkin(weaponName, skinName)
    if FakeSkinTools[weaponName] then
        pcall(function() FakeSkinTools[weaponName]:Destroy() end)
        FakeSkinTools[weaponName]=nil
    end
    local c=LocalPlayer.Character; if not c then return end
    local color=GetSkinColor(skinName)
    local isKnife=not weaponName:lower():find("gun")

    local tool=Instance.new("Tool")
    tool.Name=weaponName; tool.RequiresHandle=true; tool.CanBeDropped=false
    tool.ToolTip=skinName.." [Mathew Hub Skin]"

    local handle=Instance.new("Part",tool); handle.Name="Handle"
    handle.Size=isKnife and Vector3.new(0.12,1.4,0.06) or Vector3.new(0.28,0.9,0.14)
    handle.Color=Color3.fromRGB(40,30,25); handle.Material=Enum.Material.SmoothPlastic
    handle.CanCollide=false; handle.CastShadow=false

    local blade=Instance.new("Part",tool); blade.Name=isKnife and "Blade" or "Barrel"
    blade.Size=isKnife and Vector3.new(0.04,1.0,0.03) or Vector3.new(0.12,0.7,0.09)
    blade.Color=color; blade.Material=Enum.Material.Neon
    blade.CanCollide=false; blade.CastShadow=false

    local weld=Instance.new("WeldConstraint",handle); weld.Part0=handle; weld.Part1=blade
    blade.CFrame=handle.CFrame*CFrame.new(0,isKnife and 0.6 or 0.4,0)

    local tip=Instance.new("Part",tool); tip.Name="Tip"
    tip.Size=Vector3.new(0.06,0.06,0.06); tip.Color=color; tip.Material=Enum.Material.Neon
    tip.CanCollide=false; tip.CastShadow=false
    local w2=Instance.new("WeldConstraint",blade); w2.Part0=blade; w2.Part1=tip
    tip.CFrame=blade.CFrame*CFrame.new(0,isKnife and 0.52 or 0.36,0)

    local pl=Instance.new("PointLight",tip); pl.Brightness=5; pl.Color=color; pl.Range=7

    -- Tag so we never mistake it for real
    local tag=Instance.new("StringValue",tool); tag.Name="_MathHub"; tag.Value=skinName

    tool.Parent=LocalPlayer.Backpack
    FakeSkinTools[weaponName]=tool
    return tool
end

local function RemoveFakeSkin(name)
    if FakeSkinTools[name] then
        pcall(function() FakeSkinTools[name]:Destroy() end)
        FakeSkinTools[name]=nil
    end
end

-- FLING  (like the video — massive velocity burst sends player to void/sky)
local function FlingPlayer(target)
    local tRoot=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    -- Apply instant void-velocity
    pcall(function()
        -- Method 1: BodyVelocity with infinite force
        local bv=Instance.new("BodyVelocity")
        bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
        -- Random horizontal + extreme upward = sends to void and death
        bv.Velocity=Vector3.new(
            math.random(-1,1)*3000,
            50000,   -- extreme Y = instant void
            math.random(-1,1)*3000
        )
        bv.Parent=tRoot
        Debris:AddItem(bv,0.05)
    end)
    pcall(function()
        -- Method 2: zero gravity briefly so they can't return
        local bg=Instance.new("BodyGyro")
        bg.MaxTorque=Vector3.zero; bg.Parent=tRoot
        Debris:AddItem(bg,0.05)
    end)
end

-- CARRY  (magnetize to above your character)
local function StartCarry(target)
    if not target.Character then Notify("Carry","No character!",2) return end
    if carryConn then carryConn:Disconnect() carryConn=nil end
    carriedPlayer=target
    Notify("Carry","Carrying "..target.Name.." | Press T to throw",3)
    carryConn=RunService.Heartbeat:Connect(function()
        if not carriedPlayer or not carriedPlayer.Character then
            carryConn:Disconnect(); carryConn=nil; carriedPlayer=nil; return
        end
        local myR=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local tR=carriedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myR and tR then
            tR.CFrame=CFrame.new(myR.Position+Vector3.new(0,5,0))
            tR.AssemblyLinearVelocity=Vector3.zero
        end
    end)
end

local function ThrowCarried()
    if not carriedPlayer then Notify("Carry","Nobody being carried!",2) return end
    local tRoot=carriedPlayer.Character and carriedPlayer.Character:FindFirstChild("HumanoidRootPart")
    if tRoot then
        FlingPlayer(carriedPlayer)
        Notify("Throw","💥 Thrown "..carriedPlayer.Name.." to void!",3)
    end
    if carryConn then carryConn:Disconnect() carryConn=nil end
    carriedPlayer=nil
end

-- AUTO GET GUN → TP → grab → return
local function FindDroppedGun()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and not obj:FindFirstChild("_MathHub") then
            local n=obj.Name:lower()
            local parent=obj.Parent
            -- Not in any player's backpack or character
            local notPlayer=true
            for _,p in ipairs(Players:GetPlayers()) do
                if parent==p.Backpack or parent==p.Character then
                    notPlayer=false break
                end
            end
            if notPlayer and (n:find("gun") or n:find("sheriff")) then
                local h=obj:FindFirstChild("Handle"); if h then return h end
            end
        end
    end
end

local function TryGetGun()
    if isGrabbingGun then return end
    local c=LocalPlayer.Character; local root=c and c:FindFirstChild("HumanoidRootPart")
    if not root then return end
    -- Already have real gun?
    local function hasRealGun()
        local function real(g) return g and not g:FindFirstChild("_MathHub") end
        return real(c:FindFirstChild("Sheriff Gun")) or real(c:FindFirstChild("Gun"))
            or real(LocalPlayer.Backpack:FindFirstChild("Sheriff Gun"))
            or real(LocalPlayer.Backpack:FindFirstChild("Gun"))
    end
    if hasRealGun() then return end
    local h=FindDroppedGun(); if not h then return end
    isGrabbingGun=true
    local savedCF=root.CFrame
    root.CFrame=CFrame.new(h.Position+Vector3.new(0,3,0))
    task.delay(0.3,function()
        root.CFrame=savedCF; isGrabbingGun=false
        Notify("Gun","✓ Grabbed & returned!",2)
    end)
end

-- MAGIC BULLET  (TP to murderer → fire → return instantly)
local function MagicShoot(myRoot,murder)
    local mRoot=murder.Character and murder.Character:FindFirstChild("HumanoidRootPart")
    local mHum=murder.Character and murder.Character:FindFirstChildOfClass("Humanoid")
    if not mRoot or not mHum or mHum.Health<=0 then return end
    local c=LocalPlayer.Character; local hum=c and c:FindFirstChild("Humanoid"); if not hum then return end
    local gun=c:FindFirstChild("Sheriff Gun") or c:FindFirstChild("Gun")
        or LocalPlayer.Backpack:FindFirstChild("Sheriff Gun")
        or LocalPlayer.Backpack:FindFirstChild("Gun")
    if not gun or gun:FindFirstChild("_MathHub") then return end
    if gun.Parent==LocalPlayer.Backpack then hum:EquipTool(gun) end
    local saved=myRoot.CFrame
    myRoot.CFrame=CFrame.new(mRoot.Position+Vector3.new(0,1,0))
    Camera.CFrame=CFrame.new(Camera.CFrame.Position,mRoot.Position+Vector3.new(0,1.5,0))
    pcall(function() gun:Activate() end)
    myRoot.CFrame=saved
end

-- HITBOX EXPANDER (expand target or self hitbox)
local HitboxConnections={}

local function UpdateHitbox()
    -- Clear old
    for _,conn in ipairs(HitboxConnections) do conn:Disconnect() end
    HitboxConnections={}
    if HitboxPart then pcall(function() HitboxPart:Destroy() end) HitboxPart=nil end

    if not S.Hitbox.Enabled then
        -- Restore all players' HRP sizes
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local hrp=p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() hrp.Size=Vector3.new(2,2,1) end) end
            end
        end
        return
    end

    if S.Hitbox.Mode=="Remote" then
        -- Expand all OTHER players' hitboxes client-side
        local conn=RunService.Heartbeat:Connect(function()
            if not S.Hitbox.Enabled then return end
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character then
                    local hrp=p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        pcall(function() hrp.Size=Vector3.new(S.Hitbox.Size,S.Hitbox.Size,S.Hitbox.Size) end)
                    end
                end
            end
        end)
        table.insert(HitboxConnections,conn)
    else
        -- Local mode: expand own HRP
        local conn=RunService.Heartbeat:Connect(function()
            if not S.Hitbox.Enabled then return end
            local c=LocalPlayer.Character; if not c then return end
            local hrp=c:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function() hrp.Size=Vector3.new(S.Hitbox.Size,S.Hitbox.Size,S.Hitbox.Size) end) end
        end)
        table.insert(HitboxConnections,conn)
    end
end

-- CROSSHAIR
local function RebuildCrosshair()
    for _,l in ipairs(CrossLines) do pcall(function() l:Remove() end) end
    CrossLines={}
    if not S.Visuals.Crosshair then return end
    local col=T.Accent
    local sz=S.Visuals.CrosshairSize; local th=S.Visuals.CrosshairThick
    local cx=Camera.ViewportSize.X/2; local cy=Camera.ViewportSize.Y/2
    local function L(a,b)
        local ln=Drawing.new("Line")
        ln.From=a; ln.To=b; ln.Color=col; ln.Thickness=th
        ln.Transparency=0; ln.Visible=true
        table.insert(CrossLines,ln)
    end
    local gap=4  -- center gap
    L(Vector2.new(cx-sz,cy),Vector2.new(cx-gap,cy))
    L(Vector2.new(cx+gap,cy),Vector2.new(cx+sz,cy))
    L(Vector2.new(cx,cy-sz),Vector2.new(cx,cy-gap))
    L(Vector2.new(cx,cy+gap),Vector2.new(cx,cy+sz))
    -- dot
    local dot=Drawing.new("Circle")
    dot.Position=Vector2.new(cx,cy); dot.Radius=1.5
    dot.Color=col; dot.Filled=true; dot.Transparency=0; dot.Visible=true
    table.insert(CrossLines,dot)
end

-- ESP helper
local function MkESP(p)
    if not ESPObjects[p] then
        local e={
            Box=Drawing.new("Square"),Name=Drawing.new("Text"),
            Role=Drawing.new("Text"),Dist=Drawing.new("Text"),
            HpBg=Drawing.new("Square"),HpFg=Drawing.new("Square"),
        }
        e.Box.Filled=false; e.Box.Thickness=1.5
        e.Name.Size=13; e.Name.Center=true; e.Name.Outline=true
        e.Role.Size=11; e.Role.Center=true; e.Role.Outline=true
        e.Dist.Size=11; e.Dist.Center=true; e.Dist.Outline=true
        e.HpBg.Filled=true; e.HpBg.Color=Color3.fromRGB(30,30,30); e.HpBg.Transparency=0.3
        e.HpFg.Filled=true; e.HpFg.Transparency=0.1
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
    if carriedPlayer==p then
        if carryConn then carryConn:Disconnect() carryConn=nil end
        carriedPlayer=nil
    end
end)

-- ══════════════════════════════════════════════════════════
--   TAB PAGES
-- ══════════════════════════════════════════════════════════

local function PageCombat()
    SecHdr("AUTO COMBAT", T.Accent)
    Toggle("Auto Stab","TP + stab when you are Murderer",S.Combat.AutoStab,
        function(v) S.Combat.AutoStab=v end)
    MkInput("Stab Range",S.Combat.StabRange,5,50,function(v) S.Combat.StabRange=v end)
    Toggle("Auto Shoot (Magic Bullet)","TP to murderer → shoot through walls → return",
        S.Combat.AutoShoot,function(v) S.Combat.AutoShoot=v end)
    MkInput("Shoot Range",S.Combat.ShootRange,10,500,function(v) S.Combat.ShootRange=v end)
    Toggle("Silent Aim","Auto-aim camera at nearest player in FOV circle",
        S.Combat.SilentAim,function(v) S.Combat.SilentAim=v end)
    MkInput("FOV Radius",S.Combat.FOV,20,400,function(v) S.Combat.FOV=v end)
    Toggle("Auto Kill All","Continuous TP+stab every alive player",
        S.Combat.AutoKillAll,function(v) S.Combat.AutoKillAll=v end)
    MkInput("Safe Height",S.Combat.SafeSpotY,50,2000,function(v) S.Combat.SafeSpotY=v end)
    SecHdr("KNIFE AURA", T.Accent)
    Toggle("Knife Aura","Auto-hit nearby players when holding knife",
        S.Combat.KnifeAura,function(v) S.Combat.KnifeAura=v end)
    MkInput("Aura Range",S.Combat.KnifeAuraRange,3,50,function(v) S.Combat.KnifeAuraRange=v end)
    SecHdr("DEFENSE", T.Blue)
    Toggle("Anti-Stab Dodge","Auto dodge when murderer too close",
        S.Combat.AntiStab,function(v) S.Combat.AntiStab=v end)
    MkInput("Dodge Distance",S.Combat.AntiStabDist,5,30,function(v) S.Combat.AntiStabDist=v end)
    SecHdr("MANUAL", T.Gold)
    MkBtn("Kill All NOW","Stab every player then TP to safe height",T.Accent,function()
        local c=LocalPlayer.Character; local root=c and c:FindFirstChild("HumanoidRootPart")
        local hum=c and c:FindFirstChild("Humanoid")
        if not root or not hum then Notify("KillAll","No char!",2) return end
        local safe=root.Position+Vector3.new(0,S.Combat.SafeSpotY,0)
        local knife=c:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if not knife or knife:FindFirstChild("_MathHub") then Notify("KillAll","No real knife!",2) return end
        if knife.Parent==LocalPlayer.Backpack then hum:EquipTool(knife) end
        local n=0
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character then
                local pr=p.Character:FindFirstChild("HumanoidRootPart")
                local ph=p.Character:FindFirstChild("Humanoid")
                if pr and ph and ph.Health>0 then
                    root.CFrame=CFrame.new(pr.Position+Vector3.new(0,2,0))
                    task.wait(0.05); root.CFrame=CFrame.new(root.Position,pr.Position)
                    pcall(function() knife:Activate() end); task.wait(0.08); n+=1
                end
            end
        end
        root.CFrame=CFrame.new(safe); Notify("KillAll","Killed "..n.." → safe!",3)
    end)
end

local function PageHitbox()
    SecHdr("HITBOX EXPANDER", T.Accent)
    Toggle("Enable Hitbox Expander","Makes hitboxes larger for easier hits",
        S.Hitbox.Enabled,function(v)
            S.Hitbox.Enabled=v; UpdateHitbox()
        end)
    MkInput("Hitbox Size",S.Hitbox.Size,2,100,function(v) S.Hitbox.Size=v UpdateHitbox() end)
    -- Mode selector (two buttons)
    local modeRow=Instance.new("Frame",ContentScroll)
    modeRow.Size=UDim2.new(1,0,0,40); modeRow.BackgroundColor3=T.Card
    modeRow.BorderSizePixel=0; modeRow.LayoutOrder=WO()
    Instance.new("UICorner",modeRow).CornerRadius=UDim.new(0,6)
    local ml=Instance.new("TextLabel",modeRow)
    ml.Size=UDim2.new(0.3,0,1,0); ml.Position=UDim2.new(0,12,0,0)
    ml.BackgroundTransparency=1; ml.Text="Mode"; ml.Font=Enum.Font.Gotham
    ml.TextSize=11; ml.TextColor3=T.Sub; ml.TextXAlignment=Enum.TextXAlignment.Left

    local function ModeBtn(lbl,val,x)
        local b=Instance.new("TextButton",modeRow)
        b.Size=UDim2.new(0,72,0,26); b.Position=UDim2.new(x,0,0.5,-13)
        b.BackgroundColor3=S.Hitbox.Mode==val and T.Accent or Color3.fromRGB(12,8,10)
        b.Text=lbl; b.Font=Enum.Font.GothamBold; b.TextSize=10; b.TextColor3=T.Text
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
        b.MouseButton1Click:Connect(function()
            S.Hitbox.Mode=val; Save(); UpdateHitbox()
            b.BackgroundColor3=T.Accent
            Notify("Hitbox","Mode: "..val,2)
        end)
    end
    ModeBtn("Local",  "Local",  0.35)
    ModeBtn("Remote", "Remote", 0.62)

    SecHdr("ABOUT HITBOX", T.Sub)
    local info=Instance.new("TextLabel",ContentScroll)
    info.Size=UDim2.new(1,0,0,50); info.BackgroundColor3=T.Card
    info.BorderSizePixel=0; info.LayoutOrder=WO()
    Instance.new("UICorner",info).CornerRadius=UDim.new(0,6)
    info.Text="  Local: expands YOUR hitbox (easier for others to knife you)\n  Remote: expands ALL other players' hitboxes (easier for you to hit them)"
    info.Font=Enum.Font.Gotham; info.TextSize=9; info.TextColor3=T.Sub
    info.TextWrapped=true; info.TextXAlignment=Enum.TextXAlignment.Left
end

local function PageTeleport()
    SecHdr("GUN SYSTEM", T.Green)
    Toggle("Auto Get Gun","Detects dropped gun → TPs to grab → returns to spot",
        S.Teleport.AutoGetGun,function(v) S.Teleport.AutoGetGun=v end)
    MkBtn("Get Gun NOW","Instant grab + return",T.Green,function() TryGetGun() end)
    MkBtn("TP to Safety","TP upward to safe height",T.Blue,function()
        local c=LocalPlayer.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame=CFrame.new(r.Position+Vector3.new(0,S.Combat.SafeSpotY,0))
            Notify("Safe","Teleported!",2) end
    end)
    MkBtn("Fake Death","TP underground",Color3.fromRGB(60,20,20),function()
        local c=LocalPlayer.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame=CFrame.new(r.Position+Vector3.new(0,-300,0)) Notify("Fake","Done",2) end
    end)

    SecHdr("CARRY & FLING  (pick players below)", T.Accent)
    MkBtn("Throw Carried","Instantly fling carried player to void",T.Accent,function() ThrowCarried() end)
    MkBtn("Release Carry","Stop carrying current player",T.Sub,function()
        if carryConn then carryConn:Disconnect() carryConn=nil end
        carriedPlayer=nil; Notify("Carry","Released",2)
    end)

    local divRow=Instance.new("Frame",ContentScroll)
    divRow.Size=UDim2.new(1,0,0,4); divRow.BackgroundTransparency=1; divRow.LayoutOrder=WO()

    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            local pRef=p
            PlayerRow(p,
                function() StartCarry(pRef) end,
                function()
                    -- direct fling without carry
                    FlingPlayer(pRef)
                    Notify("Fling","💥 Flung "..pRef.Name.." to void!",3)
                end
            )
        end
    end
    MkBtn("↻ Refresh List","Reload player list",T.Dim,function()
        -- re-open page
        PageTeleport and TABS[3] and TABS[3].select and TABS[3].select()
    end)
end

local function PageVisuals()
    SecHdr("ESP", T.Blue)
    Toggle("Enable ESP","Show boxes, names, roles, HP bars through walls",
        S.Visuals.ESP,function(v) S.Visuals.ESP=v end)
    Toggle("Role Body Colors","Color character: Murderer=Red, Sheriff=Blue, Innocent=Green",
        S.Visuals.RoleColors,function(v)
            S.Visuals.RoleColors=v
            if not v then
                for _,p in ipairs(Players:GetPlayers()) do
                    if p~=LocalPlayer and p.Character then
                        for _,part in ipairs(p.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                pcall(function() part.BrickColor=BrickColor.Gray() end)
                            end
                        end
                    end
                end
            end
        end)
    SecHdr("CROSSHAIR", T.Accent)
    Toggle("Custom Crosshair (red + gap)",nil,S.Visuals.Crosshair,function(v)
        S.Visuals.Crosshair=v; RebuildCrosshair()
    end)
    MkInput("Size",S.Visuals.CrosshairSize,2,50,function(v) S.Visuals.CrosshairSize=v RebuildCrosshair() end)
    MkInput("Thickness",S.Visuals.CrosshairThick,1,6,function(v) S.Visuals.CrosshairThick=v RebuildCrosshair() end)
    SecHdr("X-RAY  (optimized no-lag)", T.Sub)
    Toggle("X-Ray Walls","See through walls — cached every 3s, runs every 6 frames",
        S.Visuals.XRay,function(v)
            S.Visuals.XRay=v
            if not v then
                for obj,orig in pairs(OrigTransp) do
                    if obj and obj.Parent then obj.Transparency=orig end
                end
                OrigTransp={}; XRayCache={}; XRayCacheTimer=0
            end
        end)
    MkInput("Wall Transparency",S.Visuals.XRayTrans*10,1,9,function(v)
        S.Visuals.XRayTrans=v/10
    end)
end

local function PageAutoFarm()
    SecHdr("COIN FARMING", T.Gold)
    Toggle("Auto Collect Coins","TP to nearest coin every 10 frames — very low lag",
        S.AutoFarm.AutoCoins,function(v) S.AutoFarm.AutoCoins=v end)
    MkInput("Coin Range",S.AutoFarm.CoinRange,20,500,function(v) S.AutoFarm.CoinRange=v end)
    SecHdr("ROLE BIAS", T.Accent)
    Toggle("High Role Chance","Attempts to fire role-selection remotes at round start",
        S.AutoFarm.HighRole,function(v)
            S.AutoFarm.HighRole=v
            if v then
                task.spawn(function()
                    for _,rem in ipairs(game:GetDescendants()) do
                        if rem:IsA("RemoteEvent") then
                            local n=rem.Name:lower()
                            if n:find("role") or n:find("murder") or n:find("sheriff") or n:find("select") then
                                pcall(function() rem:FireServer() end)
                            end
                        end
                    end
                end)
            end
        end)
end

local function PageLocal()
    SecHdr("MOVEMENT", T.Green)
    Toggle("Walk Speed",nil,S.Local.WalkSpeed,function(v)
        S.Local.WalkSpeed=v
        if not v then local c=LocalPlayer.Character
            if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=16 end
        end
    end)
    MkInput("Speed",S.Local.Speed,16,300,function(v) S.Local.Speed=v end)
    Toggle("Jump Power",nil,S.Local.JumpPower,function(v)
        S.Local.JumpPower=v
        if not v then local c=LocalPlayer.Character
            if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower=50 end
        end
    end)
    MkInput("Power",S.Local.Power,50,400,function(v) S.Local.Power=v end)
    Toggle("No Clip","Walk through walls",S.Local.NoClip,function(v) S.Local.NoClip=v end)
    Toggle("Fly  (F key)","W/A/S/D + Space/Ctrl. Shift = 2.5× speed",S.Local.Fly,function(v)
        S.Local.Fly=v; if v then StartFly() else StopFly() end
    end)
    MkInput("Fly Speed",S.Local.FlySpeed,10,500,function(v) S.Local.FlySpeed=v end)
end

local function PageSkins()
    SecHdr("SKIN SPAWNER  — KNIFE", T.Gold)
    Toggle("Enable Knife Skin","Adds fake knife to your MM2 inventory",
        S.Skin.KnifeEnabled,function(v)
            S.Skin.KnifeEnabled=v
            if v then SpawnFakeSkin("Knife",S.Skin.KnifeSkin) Notify("Skin","Knife: "..S.Skin.KnifeSkin,2)
            else RemoveFakeSkin("Knife") Notify("Skin","Removed",2) end
        end)
    MkDropdown("Knife",MM2_KNIVES,function() return S.Skin.KnifeSkin end,function(v)
        S.Skin.KnifeSkin=v
        if S.Skin.KnifeEnabled then SpawnFakeSkin("Knife",v) end
    end)
    MkBtn("Apply / Refresh Knife",nil,T.Gold,function()
        if S.Skin.KnifeEnabled then SpawnFakeSkin("Knife",S.Skin.KnifeSkin) Notify("Skin","Refreshed",2)
        else Notify("Skin","Enable first!",2) end
    end)

    SecHdr("SKIN SPAWNER  — GUN", T.Blue)
    Toggle("Enable Gun Skin","Adds fake gun to your MM2 inventory",
        S.Skin.GunEnabled,function(v)
            S.Skin.GunEnabled=v
            if v then SpawnFakeSkin("Sheriff Gun",S.Skin.GunSkin) Notify("Skin","Gun: "..S.Skin.GunSkin,2)
            else RemoveFakeSkin("Sheriff Gun") Notify("Skin","Removed",2) end
        end)
    MkDropdown("Gun",MM2_GUNS,function() return S.Skin.GunSkin end,function(v)
        S.Skin.GunSkin=v
        if S.Skin.GunEnabled then SpawnFakeSkin("Sheriff Gun",v) end
    end)
    MkBtn("Apply / Refresh Gun",nil,T.Blue,function()
        if S.Skin.GunEnabled then SpawnFakeSkin("Sheriff Gun",S.Skin.GunSkin) Notify("Skin","Refreshed",2)
        else Notify("Skin","Enable first!",2) end
    end)
    MkBtn("Remove All Skins",nil,T.Accent,function()
        RemoveFakeSkin("Knife"); RemoveFakeSkin("Sheriff Gun")
        S.Skin.KnifeEnabled=false; S.Skin.GunEnabled=false; Save()
        Notify("Skin","All removed",2)
    end)
end

local function PageConfig()
    SecHdr("KEYBINDS  (click to rebind)", T.Gold)
    MkKeybind("Toggle Menu",   "Menu")
    MkKeybind("Fly",           "Fly")
    MkKeybind("Get Gun",       "GetGun")
    MkKeybind("Safe Spot",     "SafeSpot")
    MkKeybind("Throw Carried", "Throw")
    MkKeybind("Auto Stab",     "AutoStab")
    MkKeybind("Auto Shoot",    "AutoShoot")
    MkKeybind("Silent Aim",    "SilentAim")
    MkKeybind("Kill All",      "KillAll")
    MkKeybind("Fling Target",  "Fling")
    SecHdr("SAVE / LOAD", T.Green)
    MkBtn("Save Settings","Write settings to file",T.Green,function() Save() Notify("Config","Saved!",2) end)
    MkBtn("Reload Settings","Load from file",T.Blue,function() Load() Notify("Config","Reloaded!",2) end)
    MkBtn("Reset to Defaults","Clear all settings",T.Accent,function()
        S=DeepCopy(Defaults); Save(); Notify("Config","Reset!",2)
    end)
end

-- ── BUILD HORIZONTAL TABS ──────────────────────────────────
local tab1,sel1=MakeTab("Combat",   "⚔",1,PageCombat)
local tab2,sel2=MakeTab("Hitbox",   "📐",2,PageHitbox)
local tab3,sel3=MakeTab("Teleport", "📍",3,PageTeleport)
local tab4,sel4=MakeTab("Visuals",  "👁",4,PageVisuals)
local tab5,sel5=MakeTab("AutoFarm", "💰",5,PageAutoFarm)
local tab6,sel6=MakeTab("Local",    "🧍",6,PageLocal)
local tab7,sel7=MakeTab("Skins",    "🎨",7,PageSkins)
local tab8,sel8=MakeTab("Config",   "⚙",8,PageConfig)

-- Select Combat by default
task.defer(sel1)

-- ══════════════════════════════════════════════════════════
--   SILENT AIM CIRCLE
-- ══════════════════════════════════════════════════════════
local FOVCircle=Drawing.new("Circle")
FOVCircle.Visible=false; FOVCircle.Thickness=1.5
FOVCircle.Color=T.Accent; FOVCircle.Transparency=0.5; FOVCircle.Filled=false

local function GetFOVTarget()
    local best,bDist=nil,math.huge
    local ctr=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local h=p.Character:FindFirstChild("Humanoid"); if not h or h.Health<=0 then continue end
            local pos,vis=Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if vis then
                local d=(Vector2.new(pos.X,pos.Y)-ctr).Magnitude
                if d<S.Combat.FOV and d<bDist then bDist=d best=p end
            end
        end
    end
    return best
end

-- ══════════════════════════════════════════════════════════
--   MAIN HEARTBEAT
-- ══════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function(dt)
    local c=LocalPlayer.Character; if not c then return end
    local Root=c:FindFirstChild("HumanoidRootPart")
    local Hum=c:FindFirstChild("Humanoid")
    if not Root or not Hum or Hum.Health<=0 then return end
    heartStep+=1

    -- Movement
    if S.Local.WalkSpeed then Hum.WalkSpeed=S.Local.Speed end
    if S.Local.JumpPower  then Hum.JumpPower=S.Local.Power end
    if S.Local.NoClip and not S.Local.Fly then
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end

    -- X-Ray (throttled: cache every 3s, apply every 6 frames)
    if S.Visuals.XRay then
        XRayCacheTimer+=dt
        if XRayCacheTimer>=3 then
            XRayCacheTimer=0; XRayCache={}
            for _,obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj:IsDescendantOf(c) and obj.Size.Magnitude>3 then
                    table.insert(XRayCache,obj)
                end
            end
        end
        if heartStep%6==0 then
            local tgt=S.Visuals.XRayTrans
            for _,obj in ipairs(XRayCache) do
                if obj and obj.Parent and not obj:IsDescendantOf(c) then
                    if not OrigTransp[obj] then OrigTransp[obj]=obj.Transparency end
                    if obj.Transparency<tgt then obj.Transparency=tgt end
                end
            end
        end
    end

    -- Auto Coins (scan every 10 frames, find nearest, TP once)
    if S.AutoFarm.AutoCoins and heartStep%10==0 then
        local bestCoin,bestDist=nil,S.AutoFarm.CoinRange
        for _,obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name=="Coin" or obj.Name:lower():find("coin")) then
                local d=(Root.Position-obj.Position).Magnitude
                if d<bestDist then bestDist=d bestCoin=obj end
            end
        end
        if bestCoin then Root.CFrame=CFrame.new(bestCoin.Position+Vector3.new(0,2,0)) end
    end

    -- Auto Get Gun timer
    if S.Teleport.AutoGetGun then
        autoGetGunTimer+=dt
        if autoGetGunTimer>=2 then autoGetGunTimer=0 TryGetGun() end
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

    -- Anti stab
    if S.Combat.AntiStab and Murder and Murder.Character then
        local mr=Murder.Character:FindFirstChild("HumanoidRootPart")
        if mr and (Root.Position-mr.Position).Magnitude<S.Combat.AntiStabDist then
            Root.CFrame=Root.CFrame+(Root.Position-mr.Position).Unit*14; Hum.Jump=true
        end
    end

    -- Auto Stab
    if S.Combat.AutoStab and myRole=="Murderer" then
        local knife=c:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if knife and not knife:FindFirstChild("_MathHub") then
            if knife.Parent==LocalPlayer.Backpack then Hum:EquipTool(knife) end
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character then
                    local ph=p.Character:FindFirstChild("Humanoid")
                    local pr=p.Character:FindFirstChild("HumanoidRootPart")
                    if ph and pr and ph.Health>0 and GetRole(p)~="Murderer" then
                        if (Root.Position-pr.Position).Magnitude<S.Combat.StabRange then
                            Root.CFrame=CFrame.new(Root.Position,pr.Position)
                            pcall(function() knife:Activate() end)
                        end
                    end
                end
            end
        end
    end

    -- Knife Aura
    if S.Combat.KnifeAura and myRole=="Murderer" and heartStep%8==0 then
        local knife=c:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if knife and not knife:FindFirstChild("_MathHub") then
            if knife.Parent==LocalPlayer.Backpack then Hum:EquipTool(knife) end
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character then
                    local pr=p.Character:FindFirstChild("HumanoidRootPart")
                    local ph=p.Character:FindFirstChild("Humanoid")
                    if pr and ph and ph.Health>0 and (Root.Position-pr.Position).Magnitude<S.Combat.KnifeAuraRange then
                        pcall(function() knife:Activate() end)
                    end
                end
            end
        end
    end

    -- Auto Kill All
    if S.Combat.AutoKillAll and myRole=="Murderer" and heartStep%6==0 then
        local knife=c:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if knife and not knife:FindFirstChild("_MathHub") then
            if knife.Parent==LocalPlayer.Backpack then Hum:EquipTool(knife) end
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character then
                    local ph=p.Character:FindFirstChild("Humanoid")
                    local pr=p.Character:FindFirstChild("HumanoidRootPart")
                    if ph and pr and ph.Health>0 then
                        Root.CFrame=CFrame.new(pr.Position+Vector3.new(0,2,0))
                        Root.CFrame=CFrame.new(Root.Position,pr.Position)
                        pcall(function() knife:Activate() end); break
                    end
                end
            end
        end
    end

    -- Auto Shoot (magic bullet, every 18 frames)
    if S.Combat.AutoShoot and myRole=="Sheriff" and Murder and heartStep%18==0 then
        local mr=Murder.Character and Murder.Character:FindFirstChild("HumanoidRootPart")
        local mh=Murder.Character and Murder.Character:FindFirstChild("Humanoid")
        if mr and mh and mh.Health>0 and (Root.Position-mr.Position).Magnitude<S.Combat.ShootRange then
            MagicShoot(Root,Murder)
        end
    end

    -- Role body colors (every 30 frames, low overhead)
    if S.Visuals.RoleColors and heartStep%30==0 then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character then
                local role=GetRole(p)
                local col=role=="Murderer" and "Bright red"
                    or role=="Sheriff" and "Bright blue"
                    or "Bright green"
                for _,part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
                        pcall(function() part.BrickColor=BrickColor.new(col) end)
                    end
                end
            end
        end
    end

    -- Rainbow skin cycle
    if heartStep%16==0 then
        rainbowHue=(rainbowHue+0.05)%1
        for _,wname in ipairs({"Knife","Sheriff Gun"}) do
            local t=FakeSkinTools[wname]
            if t then
                local skinName=wname=="Knife" and S.Skin.KnifeSkin or S.Skin.GunSkin
                if skinName:lower():find("chroma") or skinName:lower():find("rainbow") then
                    for _,p in ipairs(t:GetDescendants()) do
                        if p:IsA("BasePart") and p.Name~="Handle" then
                            p.Color=Color3.fromHSV(rainbowHue,1,1)
                        end
                    end
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════
--   RENDER STEPPED: Silent Aim + ESP
-- ══════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    local c=LocalPlayer.Character
    local Root=c and c:FindFirstChild("HumanoidRootPart")

    -- Silent Aim
    if S.Combat.SilentAim then
        local ctr=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
        FOVCircle.Position=ctr; FOVCircle.Radius=S.Combat.FOV; FOVCircle.Visible=true
        local tgt=GetFOVTarget()
        if tgt and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart") then
            Camera.CFrame=CFrame.new(Camera.CFrame.Position,
                tgt.Character.HumanoidRootPart.Position+Vector3.new(0,1.5,0))
        end
    else FOVCircle.Visible=false end

    -- ESP
    if not S.Visuals.ESP then
        for _,d in pairs(ESPObjects) do HideE(d) end return
    end

    for _,p in ipairs(Players:GetPlayers()) do
        if p==LocalPlayer then continue end
        local pc=p.Character
        local pr=pc and pc:FindFirstChild("HumanoidRootPart")
        local ph=pc and pc:FindFirstChildOfClass("Humanoid")
        if not pr or not ph or ph.Health<=0 then HideE(ESPObjects[p]) continue end
        local pos,vis=Camera:WorldToViewportPoint(pr.Position)
        if not vis then HideE(ESPObjects[p]) continue end

        local role=GetRole(p)
        local col=role=="Murderer" and Color3.fromRGB(255,60,60)
             or   role=="Sheriff"  and Color3.fromRGB(60,140,255)
             or                        Color3.fromRGB(60,210,80)

        local e=MkESP(p)
        local szX,szY=2200/pos.Z,3000/pos.Z
        local scr=Vector2.new(pos.X,pos.Y)

        e.Box.Visible=true; e.Box.Position=Vector2.new(scr.X-szX/2,scr.Y-szY/2)
        e.Box.Size=Vector2.new(szX,szY); e.Box.Color=col; e.Box.Transparency=0.4

        e.Name.Visible=true; e.Name.Position=Vector2.new(scr.X,scr.Y-szY/2-28)
        e.Name.Text=p.Name; e.Name.Color=col

        e.Role.Visible=true; e.Role.Position=Vector2.new(scr.X,scr.Y-szY/2-16)
        e.Role.Text="["..role.."]"; e.Role.Color=col

        if Root then
            e.Dist.Visible=true; e.Dist.Position=Vector2.new(scr.X,scr.Y+szY/2+4)
            e.Dist.Text=math.floor((Root.Position-pr.Position).Magnitude).."st"
            e.Dist.Color=col
        end

        local hp=ph.Health/ph.MaxHealth
        local bW,bH=4,szY; local bX=scr.X-szX/2-bW-3; local bY=scr.Y-szY/2
        e.HpBg.Visible=true; e.HpBg.Position=Vector2.new(bX,bY); e.HpBg.Size=Vector2.new(bW,bH)
        e.HpFg.Visible=true; e.HpFg.Position=Vector2.new(bX,bY+bH*(1-hp))
        e.HpFg.Size=Vector2.new(bW,bH*hp)
        e.HpFg.Color=Color3.fromRGB(math.floor(255*(1-hp)),math.floor(255*hp),0)
    end
end)

-- ══════════════════════════════════════════════════════════
--   KEYBIND HANDLER
-- ══════════════════════════════════════════════════════════
local function KM(keyName,inp)
    if keyName=="None" or keyName=="" then return false end
    local ok,res=pcall(function() return inp.KeyCode==Enum.KeyCode[keyName] end)
    return ok and res
end

UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    local k=inp.KeyCode

    if KM(S.Keys.Menu,inp) or k==Enum.KeyCode.RightControl then
        Win.Visible=not Win.Visible
    end
    if KM(S.Keys.Fly,inp) or k==Enum.KeyCode.F then
        S.Local.Fly=not S.Local.Fly
        if S.Local.Fly then StartFly() else StopFly() end
        Notify("Fly",S.Local.Fly and "ON" or "OFF",2)
    end
    if KM(S.Keys.GetGun,inp)   then TryGetGun() end
    if KM(S.Keys.SafeSpot,inp) then
        local c=LocalPlayer.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame=CFrame.new(r.Position+Vector3.new(0,S.Combat.SafeSpotY,0))
            Notify("Safe","TP!",2) end
    end
    if KM(S.Keys.Throw,inp) then ThrowCarried() end
    if KM(S.Keys.AutoStab,inp) then
        S.Combat.AutoStab=not S.Combat.AutoStab; Save()
        Notify("Auto Stab",S.Combat.AutoStab and "ON" or "OFF",2)
    end
    if KM(S.Keys.AutoShoot,inp) then
        S.Combat.AutoShoot=not S.Combat.AutoShoot; Save()
        Notify("Auto Shoot",S.Combat.AutoShoot and "ON" or "OFF",2)
    end
    if KM(S.Keys.SilentAim,inp) then
        S.Combat.SilentAim=not S.Combat.SilentAim; Save()
        Notify("Silent Aim",S.Combat.SilentAim and "ON" or "OFF",2)
    end
    if KM(S.Keys.KillAll,inp) then
        S.Combat.AutoKillAll=not S.Combat.AutoKillAll; Save()
        Notify("Kill All",S.Combat.AutoKillAll and "ON" or "OFF",2)
    end
end)

-- ══════════════════════════════════════════════════════════
--   CLEANUP
-- ══════════════════════════════════════════════════════════
Gui.AncestryChanged:Connect(function()
    RemoveFakeSkin("Knife"); RemoveFakeSkin("Sheriff Gun"); StopFly()
    for _,l in ipairs(CrossLines) do pcall(function() l:Remove() end) end
    for _,d in pairs(ESPObjects) do for _,x in pairs(d) do pcall(function() x:Remove() end) end end
    if carryConn then carryConn:Disconnect() end
    for _,conn in ipairs(HitboxConnections) do conn:Disconnect() end
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
end)

RebuildCrosshair()

task.delay(0.5, function()
    Notify("⚡ Mathew Hub v9","RightCtrl=menu | F=fly | G=gun | H=safe | T=throw",4)
end)
