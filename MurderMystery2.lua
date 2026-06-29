--[[
╔══════════════════════════════════════════════════════════╗
║  MATHEW HUB  ⚡  MM2  ⚡  v9.0  RED EDITION              ║
║  Horizontal tab menu  |  RightCtrl = toggle              ║
║  Mobile: On-screen SHOOT MURD button                     ║
╚══════════════════════════════════════════════════════════╝
]]

-- ── Duplicate guard ──────────────────────────────────────
if getgenv().MathewHubV9 then
    pcall(function()
        if getgenv().MathewHubGui then getgenv().MathewHubGui:Destroy() end
    end)
end
getgenv().MathewHubV9 = true

-- ── Services ─────────────────────────────────────────────
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

-- ── Notify ───────────────────────────────────────────────
local function Notify(t, x, d)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=t,Text=x,Duration=d or 3})
    end)
end

-- ── Settings ─────────────────────────────────────────────
local SAVE_FILE = "MathewHub_v9.json"
local Defaults = {
    Combat = {
        AutoStab=false, StabRange=15,
        AutoShoot=false, ShootRange=200,
        SilentAim=false, FOV=120,
        LockAim=false,
        AutoKillAll=false, SafeSpotY=300,
        KnifeAura=false, KnifeAuraRange=15,
        AntiStab=false, AntiStabDist=12,
    },
    Hitbox = {Enabled=false, Size=10, Mode="Remote"},
    Fling = {
        Murder=false, Sheriff=false,
        Touch=false, AntiFling=false,
        Force=99999,
    },
    Teleport = {AutoGetGun=false},
    Visuals = {
        ESP=false, RoleColors=false,
        GunDropESP=false,
        Crosshair=false, CrosshairSize=8, CrosshairThick=2,
        XRay=false, XRayTrans=0.5,
    },
    AutoFarm = {AutoCoins=false, CoinRange=150, FarmSpeed=50, HighRole=false},
    Local = {
        WalkSpeed=false, Speed=32,
        JumpPower=false, Power=60,
        NoClip=false, Fly=false, FlySpeed=60,
    },
    Skin = {KnifeEnabled=false, KnifeSkin="Default Knife",
            GunEnabled=false, GunSkin="Default Gun"},
    Keys = {
        Menu="RightControl", Fly="F", GetGun="G",
        SafeSpot="H", Throw="T",
        AutoStab="None", AutoShoot="None",
        SilentAim="None", KillAll="None",
    },
}

local function DeepCopy(t)
    local c={}
    for k,v in pairs(t) do c[k]=type(v)=="table" and DeepCopy(v) or v end
    return c
end
local S = DeepCopy(Defaults)

local function Save()
    pcall(function() writefile(SAVE_FILE,HttpService:JSONEncode(S)) end)
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

-- ── MM2 Full Weapon List ──────────────────────────────────
local MM2_KNIVES = {
    "Default Knife","Green","Blue","Red","Yellow","Purple","Orange","Pink",
    "Cyan","White","Black","Checker","Marble","Graffiti","High Tech","Hardened",
    "Ocean","Space","Tiger","Leaf","Tribal","Retro","Pirate","Adurite","Copper",
    "Combat","Neon","Lovely","Pearl","Void","Prismatic","Fire","Lava","Nebula",
    "Galactic","Viper","Slasher","Fang","Deathshard","Saw","Tides","Flora",
    "Splat","Spring","Fox","Darkbringer","Lightbringer","Gemstone","Shark",
    "Laser","Heat","Rainbow","Elderwood","Corrupt","Seer","Luger","Batwing",
    "Spider","Clockwork","Candy","Blizzard","Vampire","Hallows","Ancient Blade",
    "Icedriller","Snowflake","Cane","Gingerblade","Boneblade","Swirly",
    "Makeshift","Candleflame","Phantom","Specter","Harvester","Bat",
    "Chroma Fang","Chroma Deathshard","Chroma Saw","Chroma Tides",
    "Chroma Slasher","Chroma Gemstone","Chroma Luger","Chroma Shark",
    "Chroma Laser","Chroma Heat","Chroma Darkbringer","Chroma Lightbringer",
    "Chroma Boneblade","Chroma Gingerblade","Chroma Evergreen",
    "Chroma Candleflame","Chroma Bauble","Nik's Scythe","Elderwood Scythe",
    "Eternal","Hallowscythe","Vampire Axe","Swirly Axe","Flowerwood",
    "Knifeception","Blue Flaming Knife","Green Flaming Knife",
    "Pink Flaming Knife","Flaming Knife","Ghostify","Heartify",
    "Chroma Vampire Gun","Evo Knife","Chroma Evo Knife",
    "Candy Cane Knife","Ice Dagger","Bone Dagger",
}
local MM2_GUNS = {
    "Default Gun","Green Gun","Blue Gun","Red Gun","Yellow Gun","Purple Gun",
    "Orange Gun","Pink Gun","Cyan Gun","White Gun","Black Gun","Checker Gun",
    "Adurite Gun","Copper Gun","Combat Gun","Marble Gun","Graffiti Gun",
    "High Tech Gun","Hardened Gun","Ocean Gun","Space Gun","Galactic",
    "Neon Gun","Lovely Gun","Pearl Gun","Void Gun","Prismatic Gun","Fire Gun",
    "Lava Gun","Nebula Gun","Viper Gun","Shark","Laser","Heat Gun",
    "Rainbow Gun","Luger","Blaster","Amerilaser","Plasmabeam",
    "Elderwood Revolver","Hallowgun","Red Luger","Green Luger",
    "Iceblaster","Swirlygun","Wavy","Chroma Luger","Chroma Shark",
    "Chroma Laser","Chroma Heat","Chroma Swirlygun","Chroma Evergun",
    "Sheriff Gun","Gun","Vampire Gun","Chroma Vampire Gun","Swirly Gun",
    "Flowerwood Gun","Ice Gun","Candy Cane Gun",
}

local SKIN_COLORS = {
    ["Default Knife"]=Color3.fromRGB(200,180,140),
    ["Default Gun"]=Color3.fromRGB(180,180,180),
    ["Shark"]=Color3.fromRGB(120,180,220),
    ["Laser"]=Color3.fromRGB(255,255,0),
    ["Heat"]=Color3.fromRGB(255,100,0),
    ["Elderwood"]=Color3.fromRGB(100,60,20),
    ["Luger"]=Color3.fromRGB(220,200,50),
    ["Darkbringer"]=Color3.fromRGB(60,0,100),
    ["Lightbringer"]=Color3.fromRGB(255,240,100),
    ["Rainbow"]=Color3.fromRGB(255,100,200),
    ["Gemstone"]=Color3.fromRGB(0,200,255),
    ["Chroma Fang"]=Color3.fromRGB(255,0,255),
    ["Chroma Luger"]=Color3.fromRGB(255,200,0),
    ["Nik's Scythe"]=Color3.fromRGB(255,0,0),
    ["Hallowscythe"]=Color3.fromRGB(255,100,0),
    ["Vampire Axe"]=Color3.fromRGB(150,0,20),
    ["Sheriff Gun"]=Color3.fromRGB(200,160,80),
    ["Neon"]=Color3.fromRGB(0,255,150),
    ["Void"]=Color3.fromRGB(20,0,40),
    ["Fire"]=Color3.fromRGB(255,80,0),
    ["Galactic"]=Color3.fromRGB(80,0,180),
    ["Vampire Gun"]=Color3.fromRGB(150,0,20),
}

-- ── State ────────────────────────────────────────────────
local rainbowHue      = 0
local ESPObjects      = {}
local OrigTransp      = {}
local XRayCache       = {}
local XRayCacheTimer  = 0
local heartStep       = 0
local FakeSkinTools   = {}
local PermanentRoles  = {}
local FlyConn         = nil
local FlyBV, FlyBG    = nil, nil
local carriedPlayer   = nil
local carryConn       = nil
local isGrabbingGun   = false
local autoGetGunTimer = 0
local CrossLines      = {}
local HitboxConns     = {}
local GunDropHighlight= nil
local lockedTarget    = nil  -- for lock aim

-- ── RED THEME ────────────────────────────────────────────
local T = {
    BG      = Color3.fromRGB(13,10,11),
    TopBg   = Color3.fromRGB(20,14,15),
    TabBg   = Color3.fromRGB(17,12,13),
    TabSel  = Color3.fromRGB(28,18,20),
    Panel   = Color3.fromRGB(15,10,12),
    Card    = Color3.fromRGB(22,15,17),
    CardHov = Color3.fromRGB(30,20,22),
    Accent  = Color3.fromRGB(210,35,55),
    Accent2 = Color3.fromRGB(255,75,95),
    Glow    = Color3.fromRGB(255,130,150),
    ON      = Color3.fromRGB(210,35,55),
    OFF     = Color3.fromRGB(50,35,38),
    Text    = Color3.new(1,1,1),
    Sub     = Color3.fromRGB(185,160,163),
    Dim     = Color3.fromRGB(105,80,83),
    Div     = Color3.fromRGB(48,32,35),
    Green   = Color3.fromRGB(0,210,100),
    Blue    = Color3.fromRGB(55,135,255),
    Gold    = Color3.fromRGB(255,200,50),
    Purple  = Color3.fromRGB(155,50,255),
}

-- ══════════════════════════════════════════════════════════
--  GUI  —  HORIZONTAL TAB LAYOUT
-- ══════════════════════════════════════════════════════════
local Gui = Instance.new("ScreenGui")
Gui.Name="MathewHub_v9"; Gui.ResetOnSpawn=false
Gui.IgnoreGuiInset=true; Gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
Gui.Parent=LocalPlayer:WaitForChild("PlayerGui")
getgenv().MathewHubGui=Gui

local Win=Instance.new("Frame",Gui)
Win.Size=UDim2.new(0,600,0,450)
Win.Position=UDim2.new(0.5,-300,0.5,-225)
Win.BackgroundColor3=T.BG; Win.BorderSizePixel=0
Win.Active=true; Win.Draggable=true
Instance.new("UICorner",Win).CornerRadius=UDim.new(0,10)
local WS=Instance.new("UIStroke",Win)
WS.Color=T.Accent; WS.Thickness=1.5; WS.Transparency=0.2

-- TOP BAR
local TopBar=Instance.new("Frame",Win)
TopBar.Size=UDim2.new(1,0,0,44); TopBar.BackgroundColor3=T.TopBg; TopBar.BorderSizePixel=0
Instance.new("UICorner",TopBar).CornerRadius=UDim.new(0,10)
local TFix=Instance.new("Frame",TopBar)
TFix.Size=UDim2.new(1,0,0.5,0); TFix.Position=UDim2.new(0,0,0.5,0)
TFix.BackgroundColor3=T.TopBg; TFix.BorderSizePixel=0
local TLine=Instance.new("Frame",TopBar)
TLine.Size=UDim2.new(1,0,0,2); TLine.Position=UDim2.new(0,0,1,-2)
TLine.BackgroundColor3=T.Accent; TLine.BorderSizePixel=0

-- Logo (anime face circle with ⚡)
local Logo=Instance.new("Frame",TopBar)
Logo.Size=UDim2.new(0,32,0,32); Logo.Position=UDim2.new(0,8,0.5,-16)
Logo.BackgroundColor3=T.Accent; Logo.BorderSizePixel=0
Instance.new("UICorner",Logo).CornerRadius=UDim.new(1,0)
local LogoS=Instance.new("UIStroke",Logo); LogoS.Color=T.Glow; LogoS.Thickness=2
local LogoTxt=Instance.new("TextLabel",Logo)
LogoTxt.Size=UDim2.new(1,0,1,0); LogoTxt.BackgroundTransparency=1
LogoTxt.Text="⚡"; LogoTxt.TextSize=16; LogoTxt.TextColor3=T.Text

local TitleLbl=Instance.new("TextLabel",TopBar)
TitleLbl.Size=UDim2.new(0,140,1,0); TitleLbl.Position=UDim2.new(0,46,0,0)
TitleLbl.BackgroundTransparency=1; TitleLbl.Text="MATHEW HUB"
TitleLbl.Font=Enum.Font.GothamBlack; TitleLbl.TextSize=14; TitleLbl.TextColor3=T.Accent2
TitleLbl.TextXAlignment=Enum.TextXAlignment.Left
local TLG=Instance.new("UIGradient",TitleLbl)
TLG.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,T.Glow),
    ColorSequenceKeypoint.new(0.5,T.Accent),
    ColorSequenceKeypoint.new(1,T.Accent2),
}

local VBadge=Instance.new("Frame",TopBar)
VBadge.Size=UDim2.new(0,48,0,20); VBadge.Position=UDim2.new(0,188,0.5,-10)
VBadge.BackgroundColor3=T.Accent; VBadge.BorderSizePixel=0
Instance.new("UICorner",VBadge).CornerRadius=UDim.new(1,0)
local VLbl=Instance.new("TextLabel",VBadge)
VLbl.Size=UDim2.new(1,0,1,0); VLbl.BackgroundTransparency=1
VLbl.Text="v9.0"; VLbl.Font=Enum.Font.GothamBold; VLbl.TextSize=9; VLbl.TextColor3=T.Text

-- Search box (like Overdrive H screenshot)
local SearchBox=Instance.new("TextBox",TopBar)
SearchBox.Size=UDim2.new(0,180,0,24); SearchBox.Position=UDim2.new(0,244,0.5,-12)
SearchBox.BackgroundColor3=Color3.fromRGB(10,7,8)
SearchBox.PlaceholderText="🔍 Search feature..."
SearchBox.PlaceholderColor3=T.Dim
SearchBox.Text=""; SearchBox.Font=Enum.Font.Gotham; SearchBox.TextSize=10
SearchBox.TextColor3=T.Sub; SearchBox.ClearTextOnFocus=false
Instance.new("UICorner",SearchBox).CornerRadius=UDim.new(0,5)
Instance.new("UIStroke",SearchBox).Color=T.Div
local SPad=Instance.new("UIPadding",SearchBox); SPad.PaddingLeft=UDim.new(0,6)

local HintL=Instance.new("TextLabel",TopBar)
HintL.Size=UDim2.new(0,110,1,0); HintL.Position=UDim2.new(1,-140,0,0)
HintL.BackgroundTransparency=1; HintL.Text="RightCtrl toggle"
HintL.Font=Enum.Font.Gotham; HintL.TextSize=8; HintL.TextColor3=T.Dim
HintL.TextXAlignment=Enum.TextXAlignment.Right

local CloseB=Instance.new("TextButton",TopBar)
CloseB.Size=UDim2.new(0,26,0,26); CloseB.Position=UDim2.new(1,-32,0.5,-13)
CloseB.BackgroundColor3=T.Accent; CloseB.Text="✕"
CloseB.Font=Enum.Font.GothamBold; CloseB.TextSize=12; CloseB.TextColor3=T.Text
Instance.new("UICorner",CloseB).CornerRadius=UDim.new(0,5)
CloseB.MouseButton1Click:Connect(function() Win.Visible=false end)

-- HORIZONTAL TAB BAR
local TabBar=Instance.new("Frame",Win)
TabBar.Size=UDim2.new(1,0,0,34); TabBar.Position=UDim2.new(0,0,0,44)
TabBar.BackgroundColor3=T.TabBg; TabBar.BorderSizePixel=0
local TabLayout=Instance.new("UIListLayout",TabBar)
TabLayout.FillDirection=Enum.FillDirection.Horizontal
TabLayout.Padding=UDim.new(0,0); TabLayout.SortOrder=Enum.SortOrder.LayoutOrder

-- Sliding red underline indicator
local TabLine=Instance.new("Frame",TabBar)
TabLine.Size=UDim2.new(0,75,0,2); TabLine.Position=UDim2.new(0,0,1,-2)
TabLine.BackgroundColor3=T.Accent; TabLine.BorderSizePixel=0; TabLine.ZIndex=5

-- CONTENT AREA
local ContentArea=Instance.new("Frame",Win)
ContentArea.Size=UDim2.new(1,0,1,-80); ContentArea.Position=UDim2.new(0,0,0,80)
ContentArea.BackgroundColor3=T.Panel; ContentArea.BorderSizePixel=0

local ContentScroll=Instance.new("ScrollingFrame",ContentArea)
ContentScroll.Size=UDim2.new(1,-6,1,-6); ContentScroll.Position=UDim2.new(0,3,0,3)
ContentScroll.BackgroundTransparency=1; ContentScroll.BorderSizePixel=0
ContentScroll.ScrollBarThickness=3; ContentScroll.ScrollBarImageColor3=T.Accent
ContentScroll.CanvasSize=UDim2.new(0,0,0,0); ContentScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
local CL=Instance.new("UIListLayout",ContentScroll)
CL.Padding=UDim.new(0,4); CL.SortOrder=Enum.SortOrder.LayoutOrder
Instance.new("UIPadding",ContentScroll).PaddingTop=UDim.new(0,6)

-- ── Widget helpers ───────────────────────────────────────
local wO=0
local function WO() wO+=1 return wO end

-- Store all created rows for search filtering
local AllRows={}

local function ClearContent()
    for _,c in ipairs(ContentScroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    wO=0; AllRows={}
end

-- Search filter
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q=SearchBox.Text:lower()
    for _,row in ipairs(AllRows) do
        if row and row.Parent then
            local lbl=row:FindFirstChildOfClass("TextLabel")
            if lbl then
                local match=q=="" or lbl.Text:lower():find(q,1,true)
                row.Visible=match~=nil and match~=false
            end
        end
    end
end)

local function SecHdr(txt,col)
    local f=Instance.new("Frame",ContentScroll)
    f.Size=UDim2.new(1,0,0,22); f.BackgroundTransparency=1; f.LayoutOrder=WO()
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-14,1,0); l.Position=UDim2.new(0,14,0,0)
    l.BackgroundTransparency=1; l.Text=txt:upper()
    l.Font=Enum.Font.GothamBold; l.TextSize=10; l.TextColor3=col or T.Accent
    l.TextXAlignment=Enum.TextXAlignment.Left
    local dv=Instance.new("Frame",f)
    dv.Size=UDim2.new(1,-14,0,1); dv.Position=UDim2.new(0,14,1,-1)
    dv.BackgroundColor3=col or T.Accent; dv.BorderSizePixel=0
    local dvg=Instance.new("UIGradient",dv)
    dvg.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,col or T.Accent),
        ColorSequenceKeypoint.new(0.55,T.Div),
        ColorSequenceKeypoint.new(1,Color3.new(0,0,0)),
    }
end

-- TOGGLE with pill slider + adjustable number input on same row
local function Toggle(label, desc, init, onChange)
    local row=Instance.new("Frame",ContentScroll)
    row.Size=UDim2.new(1,0,0,desc and 52 or 40)
    row.BackgroundColor3=T.Card; row.BorderSizePixel=0; row.LayoutOrder=WO()
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    table.insert(AllRows,row)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.75,0,0,20); lbl.Position=UDim2.new(0,12,0,desc and 6 or 0)
    lbl.AnchorPoint=desc and Vector2.new(0,0) or Vector2.new(0,0.5)
    if not desc then lbl.Position=UDim2.new(0,12,0.5,-10) end
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=12
    lbl.TextColor3=T.Text; lbl.TextXAlignment=Enum.TextXAlignment.Left

    if desc then
        local dl=Instance.new("TextLabel",row)
        dl.Size=UDim2.new(0.82,0,0,16); dl.Position=UDim2.new(0,12,0,26)
        dl.BackgroundTransparency=1; dl.Text=desc
        dl.Font=Enum.Font.Gotham; dl.TextSize=9; dl.TextColor3=T.Sub
        dl.TextXAlignment=Enum.TextXAlignment.Left; dl.TextWrapped=true
    end

    -- Pill toggle
    local pill=Instance.new("Frame",row)
    pill.Size=UDim2.new(0,38,0,22); pill.Position=UDim2.new(1,-50,0.5,-11)
    pill.BorderSizePixel=0
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local dot=Instance.new("Frame",pill)
    dot.Size=UDim2.new(0,18,0,18); dot.BorderSizePixel=0
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    dot.BackgroundColor3=T.Text

    local st=init or false
    local function Ref()
        pill.BackgroundColor3=st and T.ON or T.OFF
        TweenService:Create(dot,TweenInfo.new(0.13),
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

-- SLIDER (adjustable 1-100 with drag + number display like MoonHub screenshot)
local function Slider(label, init, minV, maxV, onChange)
    local row=Instance.new("Frame",ContentScroll)
    row.Size=UDim2.new(1,0,0,52); row.BackgroundColor3=T.Card
    row.BorderSizePixel=0; row.LayoutOrder=WO()
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    table.insert(AllRows,row)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.65,0,0,20); lbl.Position=UDim2.new(0,12,0,4)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextColor3=T.Sub
    lbl.TextXAlignment=Enum.TextXAlignment.Left

    -- Value display (blue like MoonHub)
    local valDisp=Instance.new("Frame",row)
    valDisp.Size=UDim2.new(0,38,0,20); valDisp.Position=UDim2.new(1,-50,0,4)
    valDisp.BackgroundColor3=T.Blue; valDisp.BorderSizePixel=0
    Instance.new("UICorner",valDisp).CornerRadius=UDim.new(0,4)
    local valLbl=Instance.new("TextLabel",valDisp)
    valLbl.Size=UDim2.new(1,0,1,0); valLbl.BackgroundTransparency=1
    valLbl.Font=Enum.Font.GothamBold; valLbl.TextSize=11; valLbl.TextColor3=T.Text
    valLbl.Text=tostring(init)

    -- Slider track
    local track=Instance.new("Frame",row)
    track.Size=UDim2.new(1,-24,0,6); track.Position=UDim2.new(0,12,0,36)
    track.BackgroundColor3=T.OFF; track.BorderSizePixel=0
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((init-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=T.Accent; fill.BorderSizePixel=0
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.new(0,14,0,14); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((init-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3=T.Text; knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local KS=Instance.new("UIStroke",knob); KS.Color=T.Accent; KS.Thickness=2

    local current=init
    local dragging=false

    local function SetVal(v)
        v=math.clamp(math.round(v),minV,maxV)
        current=v
        local pct=(v-minV)/(maxV-minV)
        fill.Size=UDim2.new(pct,0,1,0)
        knob.Position=UDim2.new(pct,0,0.5,0)
        valLbl.Text=tostring(v)
        onChange(v); Save()
    end

    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then dragging=true end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch then
            local trackAbs=track.AbsolutePosition
            local pct=math.clamp((inp.Position.X-trackAbs.X)/track.AbsoluteSize.X,0,1)
            SetVal(minV+pct*(maxV-minV))
        end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            local pct=math.clamp((inp.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            SetVal(minV+pct*(maxV-minV))
            dragging=true
        end
    end)
    return SetVal
end

local function MkDropdown(label, list, getV, setV)
    local row=Instance.new("Frame",ContentScroll)
    row.Size=UDim2.new(1,0,0,40); row.BackgroundColor3=T.Card
    row.BorderSizePixel=0; row.LayoutOrder=WO()
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    table.insert(AllRows,row)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.3,0,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextColor3=T.Sub
    lbl.TextXAlignment=Enum.TextXAlignment.Left

    local dBtn=Instance.new("TextButton",row)
    dBtn.Size=UDim2.new(0.65,0,0,28); dBtn.Position=UDim2.new(0.33,0,0.5,-14)
    dBtn.BackgroundColor3=Color3.fromRGB(10,7,8); dBtn.Text=getV()
    dBtn.Font=Enum.Font.Gotham; dBtn.TextSize=9; dBtn.TextColor3=T.Accent2
    dBtn.ClipsDescendants=true
    Instance.new("UICorner",dBtn).CornerRadius=UDim.new(0,5)
    Instance.new("UIStroke",dBtn).Color=T.Div

    local lf=Instance.new("Frame",ContentScroll)
    lf.BackgroundColor3=Color3.fromRGB(10,7,8); lf.BorderSizePixel=0
    lf.Visible=false; lf.LayoutOrder=WO(); lf.Size=UDim2.new(1,0,0,0)
    Instance.new("UICorner",lf).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",lf).Color=T.Accent

    -- Search inside dropdown
    local dsb=Instance.new("TextBox",lf)
    dsb.Size=UDim2.new(1,-8,0,24); dsb.Position=UDim2.new(0,4,0,4)
    dsb.BackgroundColor3=Color3.fromRGB(8,5,6)
    dsb.PlaceholderText="Search..."; dsb.PlaceholderColor3=T.Dim
    dsb.Text=""; dsb.Font=Enum.Font.Gotham; dsb.TextSize=10; dsb.TextColor3=T.Sub
    dsb.ClearTextOnFocus=false
    Instance.new("UICorner",dsb).CornerRadius=UDim.new(0,4)
    local dp2=Instance.new("UIPadding",dsb); dp2.PaddingLeft=UDim.new(0,5)

    local inner=Instance.new("ScrollingFrame",lf)
    inner.Size=UDim2.new(1,-4,1,-36); inner.Position=UDim2.new(0,2,0,32)
    inner.BackgroundTransparency=1; inner.ScrollBarThickness=3
    inner.ScrollBarImageColor3=T.Accent; inner.CanvasSize=UDim2.new(0,0,0,#list*22)
    local ibl=Instance.new("UIListLayout",inner); ibl.Padding=UDim.new(0,1)

    local itemBtns={}
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
        table.insert(itemBtns,{btn=ib,name=item:lower()})
    end

    -- Filter inside dropdown
    dsb:GetPropertyChangedSignal("Text"):Connect(function()
        local q=dsb.Text:lower()
        local vis=0
        for _,ib in ipairs(itemBtns) do
            local show=q=="" or ib.name:find(q,1,true)
            ib.btn.Visible=show~=nil and show~=false
            if show then vis+=1 end
        end
        inner.CanvasSize=UDim2.new(0,0,0,vis*22)
    end)

    local open=false
    dBtn.MouseButton1Click:Connect(function()
        open=not open; lf.Visible=open
        lf.Size=open and UDim2.new(1,0,0,math.min(#list*22+36,180)) or UDim2.new(1,0,0,0)
    end)
end

local function MkBtn(label, desc, col, fn)
    local row=Instance.new("Frame",ContentScroll)
    row.Size=UDim2.new(1,0,0,desc and 46 or 38)
    row.BackgroundColor3=T.Card; row.BorderSizePixel=0; row.LayoutOrder=WO()
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    table.insert(AllRows,row)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.66,0,0,20); lbl.Position=UDim2.new(0,12,0,desc and 5 or 0)
    if not desc then lbl.Position=UDim2.new(0,12,0.5,-10) end
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=12
    lbl.TextColor3=T.Text; lbl.TextXAlignment=Enum.TextXAlignment.Left
    if desc then
        local dl=Instance.new("TextLabel",row)
        dl.Size=UDim2.new(0.8,0,0,15); dl.Position=UDim2.new(0,12,0,25)
        dl.BackgroundTransparency=1; dl.Text=desc
        dl.Font=Enum.Font.Gotham; dl.TextSize=9; dl.TextColor3=T.Sub
        dl.TextXAlignment=Enum.TextXAlignment.Left
    end
    local b=Instance.new("TextButton",row)
    b.Size=UDim2.new(0,64,0,26); b.Position=UDim2.new(1,-74,0.5,-13)
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

local KCODE_LIST={
    "None","F","G","H","J","K","L","N","B","V","C","X","Z",
    "Q","E","R","T","Y","U","I","O","P",
    "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10",
    "One","Two","Three","Four","Five","Six","Seven","Eight","Nine",
    "Delete","Home","End","Insert","PageUp","PageDown",
}

local function MkKeybind(label, settingKey)
    local row=Instance.new("Frame",ContentScroll)
    row.Size=UDim2.new(1,0,0,36); row.BackgroundColor3=T.Card
    row.BorderSizePixel=0; row.LayoutOrder=WO()
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    table.insert(AllRows,row)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.6,0,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextColor3=T.Sub
    lbl.TextXAlignment=Enum.TextXAlignment.Left

    local kBtn=Instance.new("TextButton",row)
    kBtn.Size=UDim2.new(0.34,0,0,26); kBtn.Position=UDim2.new(0.64,0,0.5,-13)
    kBtn.BackgroundColor3=Color3.fromRGB(10,7,8)
    kBtn.Text="["..S.Keys[settingKey].."]"
    kBtn.Font=Enum.Font.GothamBold; kBtn.TextSize=10; kBtn.TextColor3=T.Gold
    Instance.new("UICorner",kBtn).CornerRadius=UDim.new(0,5)
    Instance.new("UIStroke",kBtn).Color=T.Div

    local listening=false
    kBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening=true; kBtn.Text="[...]"; kBtn.TextColor3=T.Accent2
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

-- Player row (for fling/carry)
local function PlayerRow(p, onCarry, onFling, onTP)
    local role=GetRole(p)
    local rcol=role=="Murderer" and T.Accent or role=="Sheriff" and T.Blue or T.Green

    local row=Instance.new("Frame",ContentScroll)
    row.Size=UDim2.new(1,0,0,36); row.BackgroundColor3=T.Card
    row.BorderSizePixel=0; row.LayoutOrder=WO()
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    table.insert(AllRows,row)

    local nl=Instance.new("TextLabel",row)
    nl.Size=UDim2.new(0.38,0,1,0); nl.Position=UDim2.new(0,12,0,0)
    nl.BackgroundTransparency=1; nl.Text=p.Name
    nl.Font=Enum.Font.GothamSemibold; nl.TextSize=11
    nl.TextColor3=rcol; nl.TextXAlignment=Enum.TextXAlignment.Left

    local rl=Instance.new("TextLabel",row)
    rl.Size=UDim2.new(0.22,0,1,0); rl.Position=UDim2.new(0.38,0,0,0)
    rl.BackgroundTransparency=1; rl.Text="["..role.."]"
    rl.Font=Enum.Font.Gotham; rl.TextSize=9; rl.TextColor3=rcol
    rl.TextXAlignment=Enum.TextXAlignment.Left

    local function SmBtn(lbl2,col2,xPos,fn2)
        local b=Instance.new("TextButton",row)
        b.Size=UDim2.new(0,44,0,24); b.Position=UDim2.new(1,xPos,0.5,-12)
        b.BackgroundColor3=col2; b.Text=lbl2
        b.Font=Enum.Font.GothamBold; b.TextSize=8; b.TextColor3=T.Text
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
        b.MouseButton1Click:Connect(fn2)
    end
    SmBtn("TP",T.Blue,-148,onTP)
    SmBtn("Carry",T.Accent,-100,onCarry)
    SmBtn("Fling",Color3.fromRGB(35,15,15),-50,onFling)
    Instance.new("UIStroke",row:FindFirstChild("Fling") or row).Color=T.Accent
end

-- ── TAB SYSTEM ───────────────────────────────────────────
local ActiveTabBtn=nil
local ActiveTabSel=nil

local function MakeTab(label,icon,order,fn)
    local btn=Instance.new("TextButton",TabBar)
    btn.Size=UDim2.new(0,75,1,0); btn.BackgroundTransparency=1
    btn.Text=""; btn.LayoutOrder=order; btn.BorderSizePixel=0

    local iL=Instance.new("TextLabel",btn)
    iL.Size=UDim2.new(1,0,0,14); iL.Position=UDim2.new(0,0,0,3)
    iL.BackgroundTransparency=1; iL.Text=icon; iL.TextSize=12; iL.TextColor3=T.Dim

    local nL=Instance.new("TextLabel",btn)
    nL.Size=UDim2.new(1,0,0,13); nL.Position=UDim2.new(0,0,0,18)
    nL.BackgroundTransparency=1; nL.Text=label
    nL.Font=Enum.Font.GothamSemibold; nL.TextSize=8
    nL.TextColor3=T.Dim; nL.TextXAlignment=Enum.TextXAlignment.Center

    local function Select()
        if ActiveTabBtn and ActiveTabBtn~=btn then
            ActiveTabBtn.BackgroundTransparency=1
            for _,l in ipairs(ActiveTabBtn:GetChildren()) do
                if l:IsA("TextLabel") then l.TextColor3=T.Dim end
            end
        end
        ActiveTabBtn=btn
        btn.BackgroundColor3=T.TabSel; btn.BackgroundTransparency=0
        iL.TextColor3=T.Accent; nL.TextColor3=T.Accent2
        TweenService:Create(TabLine,TweenInfo.new(0.14,Enum.EasingStyle.Quad),
            {Size=UDim2.new(0,75,0,2),
             Position=UDim2.new(0,(order-1)*75,1,-2)}):Play()
        ClearContent(); fn()
    end

    btn.MouseButton1Click:Connect(Select)
    btn.MouseEnter:Connect(function()
        if ActiveTabBtn~=btn then btn.BackgroundTransparency=0.75 btn.BackgroundColor3=T.TabSel end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTabBtn~=btn then btn.BackgroundTransparency=1 end
    end)
    return btn,Select
end

-- ══════════════════════════════════════════════════════════
--  LOGIC FUNCTIONS
-- ══════════════════════════════════════════════════════════

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
        if p.Character:FindFirstChild("Knife") and not p.Character.Knife:FindFirstChild("_MH") then
            PermanentRoles[uid]="Murderer" return "Murderer"
        end
        local g=p.Character:FindFirstChild("Sheriff Gun") or p.Character:FindFirstChild("Gun")
        if g and not g:FindFirstChild("_MH") then
            PermanentRoles[uid]="Sheriff" return "Sheriff"
        end
    end
    return "Innocent"
end

local function HookChar(p,char)
    char.ChildAdded:Connect(function(c)
        if c:IsA("Tool") and not c:FindFirstChild("_MH") then
            local n=c.Name:lower()
            if n:find("knife") then PermanentRoles[p.UserId]="Murderer" end
            if n:find("gun") or n:find("sheriff") then PermanentRoles[p.UserId]="Sheriff" end
        end
    end)
end

for _,p in ipairs(Players:GetPlayers()) do
    if p~=LocalPlayer then
        if p.Character then HookChar(p,p.Character) end
        p.CharacterAdded:Connect(function(c) HookChar(p,c) end)
    end
end
Players.PlayerAdded:Connect(function(p)
    if p~=LocalPlayer then
        p.CharacterAdded:Connect(function(c) HookChar(p,c) end)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    PermanentRoles={}
    task.wait(1)
    if S.Skin.KnifeEnabled then SpawnFakeSkin("Knife",S.Skin.KnifeSkin) end
    if S.Skin.GunEnabled then SpawnFakeSkin("Sheriff Gun",S.Skin.GunSkin) end
end)

-- FLY
local function StopFly()
    S.Local.Fly=false
    if FlyConn then FlyConn:Disconnect() FlyConn=nil end
    local c=LocalPlayer.Character; if not c then return end
    local h=c:FindFirstChild("Humanoid"); local r=c:FindFirstChild("HumanoidRootPart")
    if h then h.PlatformStand=false end
    if r then
        if FlyBV then FlyBV:Destroy() FlyBV=nil end
        if FlyBG then FlyBG:Destroy() FlyBG=nil end
        r.AssemblyLinearVelocity=Vector3.zero
    end
end

local function StartFly()
    local c=LocalPlayer.Character; if not c then return end
    local r=c:FindFirstChild("HumanoidRootPart"); local h=c:FindFirstChild("Humanoid")
    if not r or not h then return end
    h.PlatformStand=true
    FlyBV=Instance.new("BodyVelocity")
    FlyBV.MaxForce=Vector3.new(1e5,1e5,1e5); FlyBV.Velocity=Vector3.zero; FlyBV.Parent=r
    FlyBG=Instance.new("BodyGyro")
    FlyBG.MaxTorque=Vector3.new(1e5,1e5,1e5); FlyBG.P=1e4; FlyBG.CFrame=r.CFrame; FlyBG.Parent=r
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
            for _,p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end
    end)
end

-- SKIN SPAWNER
local function GetSkinColor(name)
    if name:lower():find("chroma") or name:lower():find("rainbow") then
        return Color3.fromHSV(rainbowHue,1,1)
    end
    return SKIN_COLORS[name] or Color3.fromRGB(180,160,120)
end

function SpawnFakeSkin(weaponName,skinName)
    if FakeSkinTools[weaponName] then
        pcall(function() FakeSkinTools[weaponName]:Destroy() end)
        FakeSkinTools[weaponName]=nil
    end
    if not LocalPlayer.Character then return end
    local color=GetSkinColor(skinName)
    local isKnife=not weaponName:lower():find("gun")
    local tool=Instance.new("Tool")
    tool.Name=weaponName; tool.RequiresHandle=true; tool.CanBeDropped=false
    tool.ToolTip="["..skinName.."] Mathew Hub"
    local handle=Instance.new("Part",tool); handle.Name="Handle"
    handle.Size=isKnife and Vector3.new(0.12,1.4,0.06) or Vector3.new(0.28,0.9,0.14)
    handle.Color=Color3.fromRGB(40,30,25); handle.Material=Enum.Material.SmoothPlastic
    handle.CanCollide=false; handle.CastShadow=false
    local blade=Instance.new("Part",tool); blade.Name=isKnife and "Blade" or "Barrel"
    blade.Size=isKnife and Vector3.new(0.04,1.0,0.03) or Vector3.new(0.12,0.7,0.09)
    blade.Color=color; blade.Material=Enum.Material.Neon
    blade.CanCollide=false; blade.CastShadow=false
    local w=Instance.new("WeldConstraint",handle); w.Part0=handle; w.Part1=blade
    blade.CFrame=handle.CFrame*CFrame.new(0,isKnife and 0.6 or 0.4,0)
    local tip=Instance.new("Part",tool); tip.Name="Tip"
    tip.Size=Vector3.new(0.06,0.06,0.06); tip.Color=color; tip.Material=Enum.Material.Neon
    tip.CanCollide=false; tip.CastShadow=false
    local w2=Instance.new("WeldConstraint",blade); w2.Part0=blade; w2.Part1=tip
    tip.CFrame=blade.CFrame*CFrame.new(0,isKnife and 0.52 or 0.36,0)
    local pl=Instance.new("PointLight",tip); pl.Brightness=5; pl.Color=color; pl.Range=7
    local tag=Instance.new("StringValue",tool); tag.Name="_MH"; tag.Value=skinName
    tool.Parent=LocalPlayer.Backpack
    FakeSkinTools[weaponName]=tool
end

local function RemoveFakeSkin(name)
    if FakeSkinTools[name] then
        pcall(function() FakeSkinTools[name]:Destroy() end)
        FakeSkinTools[name]=nil
    end
end

-- FLING (massive instant velocity to void like in your video)
local function FlingPlayer(target)
    local tRoot=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    pcall(function()
        local bv=Instance.new("BodyVelocity")
        bv.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
        bv.Velocity=Vector3.new(math.random(-500,500),S.Fling.Force,math.random(-500,500))
        bv.Parent=tRoot
        Debris:AddItem(bv,0.05)
    end)
end

-- CARRY & THROW
local function StartCarry(target)
    if not target.Character then Notify("Carry","No char!",2) return end
    if carryConn then carryConn:Disconnect() carryConn=nil end
    carriedPlayer=target
    Notify("Carry","Carrying "..target.Name.." | T=throw",3)
    carryConn=RunService.Heartbeat:Connect(function()
        if not carriedPlayer or not carriedPlayer.Character then
            carryConn:Disconnect() carryConn=nil carriedPlayer=nil return
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
    if not carriedPlayer then Notify("Carry","Nobody carried!",2) return end
    FlingPlayer(carriedPlayer)
    Notify("Throw","💥 "..carriedPlayer.Name.." flung!",3)
    if carryConn then carryConn:Disconnect() carryConn=nil end
    carriedPlayer=nil
end

-- AUTO GET GUN: detect → highlight → TP → grab → return
local function FindDroppedGun()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and not obj:FindFirstChild("_MH") then
            local n=obj.Name:lower()
            local parent=obj.Parent
            local dropped=true
            for _,p in ipairs(Players:GetPlayers()) do
                if parent==p.Backpack or parent==p.Character then dropped=false break end
            end
            if dropped and (n:find("gun") or n:find("sheriff")) then
                local h=obj:FindFirstChild("Handle"); if h then return h,obj end
            end
        end
    end
    return nil,nil
end

local function TryGetGun()
    if isGrabbingGun then return end
    local c=LocalPlayer.Character; local root=c and c:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local function hasRealGun()
        local function real(g) return g and not g:FindFirstChild("_MH") end
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
        Notify("Gun","✓ Got gun & returned!",2)
    end)
end

-- GUN DROP ESP: red line from player to gun
local GunDropLine=nil
local function UpdateGunDropESP()
    if GunDropLine then pcall(function() GunDropLine:Remove() end) GunDropLine=nil end
    if not S.Visuals.GunDropESP then return end
    local _,gunObj=FindDroppedGun()
    if not gunObj then return end
    local h=gunObj:FindFirstChild("Handle"); if not h then return end
    local c=LocalPlayer.Character; local root=c and c:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local wp=Camera:WorldToViewportPoint(h.Position)
    local rp=Camera:WorldToViewportPoint(root.Position)
    GunDropLine=Drawing.new("Line")
    GunDropLine.From=Vector2.new(rp.X,rp.Y)
    GunDropLine.To=Vector2.new(wp.X,wp.Y)
    GunDropLine.Color=Color3.fromRGB(255,200,0)
    GunDropLine.Thickness=2; GunDropLine.Transparency=0; GunDropLine.Visible=true
end

-- MAGIC BULLET
local function MagicShoot(myRoot,murder)
    local mRoot=murder.Character and murder.Character:FindFirstChild("HumanoidRootPart")
    local mHum=murder.Character and murder.Character:FindFirstChildOfClass("Humanoid")
    if not mRoot or not mHum or mHum.Health<=0 then return end
    local c=LocalPlayer.Character; local hum=c and c:FindFirstChild("Humanoid"); if not hum then return end
    local gun=c:FindFirstChild("Sheriff Gun") or c:FindFirstChild("Gun")
        or LocalPlayer.Backpack:FindFirstChild("Sheriff Gun")
        or LocalPlayer.Backpack:FindFirstChild("Gun")
    if not gun or gun:FindFirstChild("_MH") then return end
    if gun.Parent==LocalPlayer.Backpack then hum:EquipTool(gun) end
    local saved=myRoot.CFrame
    myRoot.CFrame=CFrame.new(mRoot.Position+Vector3.new(0,1,0))
    Camera.CFrame=CFrame.new(Camera.CFrame.Position,mRoot.Position+Vector3.new(0,1.5,0))
    pcall(function() gun:Activate() end)
    myRoot.CFrame=saved
end

-- HITBOX
local function UpdateHitbox()
    for _,c in ipairs(HitboxConns) do c:Disconnect() end
    HitboxConns={}
    if not S.Hitbox.Enabled then
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local hrp=p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() hrp.Size=Vector3.new(2,2,1) end) end
            end
        end
        return
    end
    local conn=RunService.Heartbeat:Connect(function()
        if not S.Hitbox.Enabled then return end
        if S.Hitbox.Mode=="Remote" then
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character then
                    local hrp=p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then pcall(function() hrp.Size=Vector3.new(S.Hitbox.Size,S.Hitbox.Size,S.Hitbox.Size) end) end
                end
            end
        else
            local c=LocalPlayer.Character; if not c then return end
            local hrp=c:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function() hrp.Size=Vector3.new(S.Hitbox.Size,S.Hitbox.Size,S.Hitbox.Size) end) end
        end
    end)
    table.insert(HitboxConns,conn)
end

-- CROSSHAIR (gap style with center dot)
local function RebuildCrosshair()
    for _,l in ipairs(CrossLines) do pcall(function() l:Remove() end) end
    CrossLines={}
    if not S.Visuals.Crosshair then return end
    local col=T.Accent
    local sz=S.Visuals.CrosshairSize; local th=S.Visuals.CrosshairThick
    local cx=Camera.ViewportSize.X/2; local cy=Camera.ViewportSize.Y/2
    local gap=4
    local function L(a,b)
        local ln=Drawing.new("Line")
        ln.From=a; ln.To=b; ln.Color=col; ln.Thickness=th
        ln.Transparency=0; ln.Visible=true
        table.insert(CrossLines,ln)
    end
    L(Vector2.new(cx-sz,cy),Vector2.new(cx-gap,cy))
    L(Vector2.new(cx+gap,cy),Vector2.new(cx+sz,cy))
    L(Vector2.new(cx,cy-sz),Vector2.new(cx,cy-gap))
    L(Vector2.new(cx,cy+gap),Vector2.new(cx,cy+sz))
    local dot=Drawing.new("Circle")
    dot.Position=Vector2.new(cx,cy); dot.Radius=1.5
    dot.Color=col; dot.Filled=true; dot.Transparency=0; dot.Visible=true
    table.insert(CrossLines,dot)
end

-- ESP
local function MkESP(p)
    if not ESPObjects[p] then
        local e={
            Box=Drawing.new("Square"),Name=Drawing.new("Text"),
            Role=Drawing.new("Text"),Dist=Drawing.new("Text"),
            HpBg=Drawing.new("Square"),HpFg=Drawing.new("Square"),
        }
        e.Box.Filled=false; e.Box.Thickness=1.8
        e.Name.Size=14; e.Name.Center=true; e.Name.Outline=true; e.Name.OutlineColor=Color3.new(0,0,0)
        e.Role.Size=12; e.Role.Center=true; e.Role.Outline=true; e.Role.OutlineColor=Color3.new(0,0,0)
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
--  TAB PAGES
-- ══════════════════════════════════════════════════════════

local function PageCombat()
    SecHdr("AUTO COMBAT",T.Accent)
    Toggle("Auto Stab","Stab players in range as Murderer",S.Combat.AutoStab,function(v) S.Combat.AutoStab=v end)
    Slider("Stab Range",S.Combat.StabRange,1,100,function(v) S.Combat.StabRange=v end)
    Toggle("Auto Shoot (Magic Bullet)","TP to murderer → shoot → return. Works through walls",
        S.Combat.AutoShoot,function(v) S.Combat.AutoShoot=v end)
    Slider("Shoot Range",S.Combat.ShootRange,10,500,function(v) S.Combat.ShootRange=v end)

    SecHdr("AIM",T.Accent)
    Toggle("Silent Aim","Auto-aim camera at nearest player in FOV circle",
        S.Combat.SilentAim,function(v) S.Combat.SilentAim=v end)
    Toggle("Lock Aim (AimBot)","Lock camera + silent aim on nearest target",
        S.Combat.LockAim,function(v) S.Combat.LockAim=v end)
    Slider("FOV Radius",S.Combat.FOV,10,400,function(v) S.Combat.FOV=v end)

    SecHdr("KNIFE AURA",T.Accent)
    Toggle("Knife Aura","Auto-hit nearby players when holding knife",
        S.Combat.KnifeAura,function(v) S.Combat.KnifeAura=v end)
    Slider("Aura Range",S.Combat.KnifeAuraRange,3,60,function(v) S.Combat.KnifeAuraRange=v end)

    SecHdr("KILL & DEFENSE",T.Accent)
    Toggle("Auto Kill All","Continuous TP+stab all players",
        S.Combat.AutoKillAll,function(v) S.Combat.AutoKillAll=v end)
    Slider("Safe Spot Height",S.Combat.SafeSpotY,50,2000,function(v) S.Combat.SafeSpotY=v end)
    Toggle("Anti-Stab Dodge","Jump away when murderer is close",
        S.Combat.AntiStab,function(v) S.Combat.AntiStab=v end)
    Slider("Dodge Distance",S.Combat.AntiStabDist,5,40,function(v) S.Combat.AntiStabDist=v end)

    SecHdr("MANUAL",T.Gold)
    MkBtn("Kill All NOW","TP+stab all then safe-spot",T.Accent,function()
        local c=LocalPlayer.Character
        local root=c and c:FindFirstChild("HumanoidRootPart")
        local hum=c and c:FindFirstChild("Humanoid")
        if not root or not hum then Notify("KA","No char!",2) return end
        local safe=root.Position+Vector3.new(0,S.Combat.SafeSpotY,0)
        local knife=c:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if not knife or knife:FindFirstChild("_MH") then Notify("KA","No real knife!",2) return end
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
        root.CFrame=CFrame.new(safe); Notify("Kill All","Killed "..n.."!",3)
    end)
end

local function PageHitbox()
    SecHdr("HITBOX EXPANDER",T.Accent)
    Toggle("Enable Hitbox","Expand hitboxes for easier hits",
        S.Hitbox.Enabled,function(v) S.Hitbox.Enabled=v UpdateHitbox() end)
    Slider("Hitbox Size",S.Hitbox.Size,2,100,function(v) S.Hitbox.Size=v UpdateHitbox() end)

    -- Mode buttons
    local mRow=Instance.new("Frame",ContentScroll)
    mRow.Size=UDim2.new(1,0,0,42); mRow.BackgroundColor3=T.Card
    mRow.BorderSizePixel=0; mRow.LayoutOrder=WO()
    Instance.new("UICorner",mRow).CornerRadius=UDim.new(0,6)
    local ml=Instance.new("TextLabel",mRow)
    ml.Size=UDim2.new(0.3,0,1,0); ml.Position=UDim2.new(0,12,0,0)
    ml.BackgroundTransparency=1; ml.Text="Mode"
    ml.Font=Enum.Font.Gotham; ml.TextSize=11; ml.TextColor3=T.Sub
    ml.TextXAlignment=Enum.TextXAlignment.Left

    local function MB(lbl2,val2,xPos)
        local b=Instance.new("TextButton",mRow)
        b.Size=UDim2.new(0,80,0,28); b.Position=UDim2.new(0,xPos,0.5,-14)
        b.BackgroundColor3=S.Hitbox.Mode==val2 and T.Accent or Color3.fromRGB(10,7,8)
        b.Text=lbl2; b.Font=Enum.Font.GothamBold; b.TextSize=10; b.TextColor3=T.Text
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
        b.MouseButton1Click:Connect(function()
            S.Hitbox.Mode=val2; Save(); UpdateHitbox()
            for _,c2 in ipairs(mRow:GetChildren()) do
                if c2:IsA("TextButton") then c2.BackgroundColor3=Color3.fromRGB(10,7,8) end
            end
            b.BackgroundColor3=T.Accent
            Notify("Hitbox","Mode: "..val2,2)
        end)
        return b
    end
    MB("Local Mode",  "Local",  140)
    MB("Remote Mode", "Remote", 230)

    local inf=Instance.new("TextLabel",ContentScroll)
    inf.Size=UDim2.new(1,0,0,44); inf.BackgroundColor3=T.Card
    inf.BorderSizePixel=0; inf.LayoutOrder=WO()
    Instance.new("UICorner",inf).CornerRadius=UDim.new(0,6)
    inf.Text="  Local = your hitbox is bigger (easier to knife)\n  Remote = all enemy hitboxes bigger (easier to shoot/knife them)"
    inf.Font=Enum.Font.Gotham; inf.TextSize=9; inf.TextColor3=T.Sub
    inf.TextWrapped=true; inf.TextXAlignment=Enum.TextXAlignment.Left
    local ip=Instance.new("UIPadding",inf); ip.PaddingLeft=UDim.new(0,10); ip.PaddingTop=UDim.new(0,6)
end

local function PageFling()
    SecHdr("FLING CONTROLS",T.Accent)
    Toggle("Fling Murderer","Auto-fling murderer every few frames",
        S.Fling.Murder,function(v) S.Fling.Murder=v end)
    Toggle("Fling Sheriff","Auto-fling sheriff every few frames",
        S.Fling.Sheriff,function(v) S.Fling.Sheriff=v end)
    Toggle("Touch Fling","Fling any player who touches you",
        S.Fling.Touch,function(v) S.Fling.Touch=v end)
    Toggle("Anti-Fling (Anti-Void)","Prevent yourself from being flung",
        S.Fling.AntiFling,function(v) S.Fling.AntiFling=v end)
    Slider("Fling Force",S.Fling.Force,1000,99999,function(v) S.Fling.Force=v end)

    SecHdr("PLAYER LIST — CARRY & FLING",T.Accent)
    MkBtn("Throw Carried Player","T key or click to throw to void",T.Accent,function() ThrowCarried() end)
    MkBtn("Release Carry",nil,T.Dim,function()
        if carryConn then carryConn:Disconnect() carryConn=nil end
        carriedPlayer=nil; Notify("Carry","Released",2)
    end)
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            local pRef=p
            PlayerRow(p,
                function() StartCarry(pRef) end,
                function() FlingPlayer(pRef) Notify("Fling","💥 "..pRef.Name,2) end,
                function()
                    local c=LocalPlayer.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
                    local pr2=pRef.Character and pRef.Character:FindFirstChild("HumanoidRootPart")
                    if r and pr2 then r.CFrame=CFrame.new(pr2.Position+Vector3.new(3,0,0))
                        Notify("TP","→ "..pRef.Name,2) end
                end
            )
        end
    end
    MkBtn("↻ Refresh List",nil,T.Dim,function()
        ClearContent(); PageFling()
    end)
end

local function PageVisuals()
    SecHdr("ESP",T.Blue)
    Toggle("Enable ESP","Red=Murder, Blue=Sheriff, Green=Innocent",
        S.Visuals.ESP,function(v) S.Visuals.ESP=v end)
    Toggle("Role Body Colors","Color entire character body by role",
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
    Toggle("Gun Drop ESP","Draw line from you to dropped gun",
        S.Visuals.GunDropESP,function(v) S.Visuals.GunDropESP=v end)

    SecHdr("CROSSHAIR (gap style)",T.Accent)
    Toggle("Custom Crosshair",nil,S.Visuals.Crosshair,function(v)
        S.Visuals.Crosshair=v; RebuildCrosshair()
    end)
    Slider("Size",S.Visuals.CrosshairSize,2,50,function(v)
        S.Visuals.CrosshairSize=v; RebuildCrosshair()
    end)
    Slider("Thickness",S.Visuals.CrosshairThick,1,6,function(v)
        S.Visuals.CrosshairThick=v; RebuildCrosshair()
    end)

    SecHdr("X-RAY (no lag)",T.Sub)
    Toggle("X-Ray Walls","Cached every 3s, applied every 6 frames — no lag",
        S.Visuals.XRay,function(v)
            S.Visuals.XRay=v
            if not v then
                for obj,orig in pairs(OrigTransp) do
                    if obj and obj.Parent then obj.Transparency=orig end
                end
                OrigTransp={}; XRayCache={}; XRayCacheTimer=0
            end
        end)
    Slider("Wall Transparency",math.floor(S.Visuals.XRayTrans*10),1,9,function(v)
        S.Visuals.XRayTrans=v/10
    end)
end

local function PageAutoFarm()
    SecHdr("AUTO FARM",T.Gold)
    Toggle("Auto Collect Coins","TP to nearest coin (scans every 10 frames, no lag)",
        S.AutoFarm.AutoCoins,function(v) S.AutoFarm.AutoCoins=v end)
    Slider("Coin Range",S.AutoFarm.CoinRange,20,500,function(v) S.AutoFarm.CoinRange=v end)
    Slider("Farm Speed (scan interval)",S.AutoFarm.FarmSpeed,1,100,function(v) S.AutoFarm.FarmSpeed=v end)

    SecHdr("ROLE BIAS",T.Accent)
    Toggle("High Chance of Murderer/Sheriff","Fires role-related remotes at round start",
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

local function PageTeleport()
    SecHdr("GUN SYSTEM",T.Green)
    Toggle("Auto Get Gun","Detects sheriff death → TP grab → return to spot",
        S.Teleport.AutoGetGun,function(v) S.Teleport.AutoGetGun=v end)
    MkBtn("Get Gun NOW","Instant grab + auto-return",T.Green,function() TryGetGun() end)
    MkBtn("TP to Safety","TP upward to safe height",T.Blue,function()
        local c=LocalPlayer.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame=CFrame.new(r.Position+Vector3.new(0,S.Combat.SafeSpotY,0))
            Notify("Safe","TP!",2) end
    end)
    MkBtn("Fake Death","TP underground",Color3.fromRGB(50,15,15),function()
        local c=LocalPlayer.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame=CFrame.new(r.Position+Vector3.new(0,-300,0)) Notify("Fake","Done",2) end
    end)
end

local function PageLocal()
    SecHdr("MOVEMENT",T.Green)
    Toggle("Walk Speed",nil,S.Local.WalkSpeed,function(v)
        S.Local.WalkSpeed=v
        if not v then local c=LocalPlayer.Character
            if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=16 end
        end
    end)
    Slider("Speed",S.Local.Speed,16,200,function(v) S.Local.Speed=v end)
    Toggle("Jump Power",nil,S.Local.JumpPower,function(v)
        S.Local.JumpPower=v
        if not v then local c=LocalPlayer.Character
            if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower=50 end
        end
    end)
    Slider("Power",S.Local.Power,50,300,function(v) S.Local.Power=v end)
    Toggle("No Clip","Walk through walls",S.Local.NoClip,function(v) S.Local.NoClip=v end)
    Toggle("Fly  (F key)",nil,S.Local.Fly,function(v)
        S.Local.Fly=v; if v then StartFly() else StopFly() end
    end)
    Slider("Fly Speed",S.Local.FlySpeed,10,500,function(v) S.Local.FlySpeed=v end)
end

local function PageSkins()
    SecHdr("ITEM SPAWNER — KNIFE",T.Gold)
    Toggle("Enable Knife Skin","Adds selected knife to MM2 inventory",
        S.Skin.KnifeEnabled,function(v)
            S.Skin.KnifeEnabled=v
            if v then SpawnFakeSkin("Knife",S.Skin.KnifeSkin) Notify("Skin",S.Skin.KnifeSkin,2)
            else RemoveFakeSkin("Knife") Notify("Skin","Removed",2) end
        end)
    MkDropdown("Knife",MM2_KNIVES,function() return S.Skin.KnifeSkin end,function(v)
        S.Skin.KnifeSkin=v
        if S.Skin.KnifeEnabled then SpawnFakeSkin("Knife",v) end
    end)
    MkBtn("Apply / Refresh",nil,T.Gold,function()
        if S.Skin.KnifeEnabled then SpawnFakeSkin("Knife",S.Skin.KnifeSkin) Notify("Skin","Applied",2)
        else Notify("Skin","Enable first!",2) end
    end)

    SecHdr("ITEM SPAWNER — GUN",T.Blue)
    Toggle("Enable Gun Skin","Adds selected gun to MM2 inventory",
        S.Skin.GunEnabled,function(v)
            S.Skin.GunEnabled=v
            if v then SpawnFakeSkin("Sheriff Gun",S.Skin.GunSkin) Notify("Skin",S.Skin.GunSkin,2)
            else RemoveFakeSkin("Sheriff Gun") Notify("Skin","Removed",2) end
        end)
    MkDropdown("Gun",MM2_GUNS,function() return S.Skin.GunSkin end,function(v)
        S.Skin.GunSkin=v
        if S.Skin.GunEnabled then SpawnFakeSkin("Sheriff Gun",v) end
    end)
    MkBtn("Apply / Refresh",nil,T.Blue,function()
        if S.Skin.GunEnabled then SpawnFakeSkin("Sheriff Gun",S.Skin.GunSkin) Notify("Skin","Applied",2)
        else Notify("Skin","Enable first!",2) end
    end)
    MkBtn("Remove All Skins",nil,T.Accent,function()
        RemoveFakeSkin("Knife"); RemoveFakeSkin("Sheriff Gun")
        S.Skin.KnifeEnabled=false; S.Skin.GunEnabled=false; Save()
        Notify("Skin","All removed",2)
    end)
end

local function PageConfig()
    SecHdr("KEYBINDS  (click to rebind)",T.Gold)
    MkKeybind("Toggle Menu",   "Menu")
    MkKeybind("Fly",           "Fly")
    MkKeybind("Get Gun",       "GetGun")
    MkKeybind("Safe Spot",     "SafeSpot")
    MkKeybind("Throw Carried", "Throw")
    MkKeybind("Auto Stab",     "AutoStab")
    MkKeybind("Auto Shoot",    "AutoShoot")
    MkKeybind("Silent Aim",    "SilentAim")
    MkKeybind("Kill All",      "KillAll")
    SecHdr("SAVE / LOAD",T.Green)
    MkBtn("Save Settings",nil,T.Green,function() Save() Notify("Config","Saved!",2) end)
    MkBtn("Reload Settings",nil,T.Blue,function() Load() Notify("Config","Reloaded!",2) end)
    MkBtn("Reset Defaults",nil,T.Accent,function()
        S=DeepCopy(Defaults); Save(); Notify("Config","Reset!",2)
    end)
end

-- ── Build tabs ───────────────────────────────────────────
local tab1,sel1=MakeTab("Combat",  "⚔",1,PageCombat)
local tab2,sel2=MakeTab("Hitbox",  "📐",2,PageHitbox)
local tab3,sel3=MakeTab("Fling",   "💥",3,PageFling)
local tab4,sel4=MakeTab("Visuals", "👁",4,PageVisuals)
local tab5,sel5=MakeTab("AutoFarm","💰",5,PageAutoFarm)
local tab6,sel6=MakeTab("Teleport","📍",6,PageTeleport)
local tab7,sel7=MakeTab("Local",   "🧍",7,PageLocal)
local tab8,sel8=MakeTab("Skins",   "🎨",8,PageSkins)

-- ── MOBILE: SHOOT MURD button (visible on-screen, always) ─
local ShootMurdBtn=Instance.new("TextButton",Gui)
ShootMurdBtn.Size=UDim2.new(0,100,0,80); ShootMurdBtn.Position=UDim2.new(0,10,0.6,0)
ShootMurdBtn.BackgroundColor3=Color3.fromRGB(25,10,12)
ShootMurdBtn.Text="🔫\nSHOOT\nMURD"
ShootMurdBtn.Font=Enum.Font.GothamBold; ShootMurdBtn.TextSize=11; ShootMurdBtn.TextColor3=T.Accent2
ShootMurdBtn.TextWrapped=true; ShootMurdBtn.Active=true
Instance.new("UICorner",ShootMurdBtn).CornerRadius=UDim.new(0,10)
local SBS=Instance.new("UIStroke",ShootMurdBtn); SBS.Color=T.Accent; SBS.Thickness=2
ShootMurdBtn.MouseButton1Click:Connect(function()
    -- Find murderer and shoot immediately
    local murder=nil
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and GetRole(p)=="Murderer" then murder=p break end
    end
    if murder then
        local c=LocalPlayer.Character; local root=c and c:FindFirstChild("HumanoidRootPart")
        if root then MagicShoot(root,murder)
            Notify("Shoot Murd","💥 Shot "..murder.Name,2)
        end
    else Notify("Shoot Murd","No murderer detected!",2) end
end)

-- GET GUN mobile button
local GetGunBtn=Instance.new("TextButton",Gui)
GetGunBtn.Size=UDim2.new(0,80,0,60); GetGunBtn.Position=UDim2.new(0,120,0.6,0)
GetGunBtn.BackgroundColor3=Color3.fromRGB(10,20,12)
GetGunBtn.Text="🔫\nGET\nGUN"
GetGunBtn.Font=Enum.Font.GothamBold; GetGunBtn.TextSize=10; GetGunBtn.TextColor3=T.Green
GetGunBtn.TextWrapped=true; GetGunBtn.Active=true
Instance.new("UICorner",GetGunBtn).CornerRadius=UDim.new(0,8)
local GBS=Instance.new("UIStroke",GetGunBtn); GBS.Color=T.Green; GBS.Thickness=2
GetGunBtn.MouseButton1Click:Connect(function() TryGetGun() end)

tab1:FireButton1Click()  -- select Combat by default

-- ══════════════════════════════════════════�