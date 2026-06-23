--[[
🔒 STABED AIM LOCK + BLATANT AUTO FARM
👤 MADE BY: MATHEW
👉 AIM: HOLD RIGHT MOUSE BUTTON
🤖 AUTO FARM: TP BEHIND + STAB UNTIL DEAD
🛡️ SAFE: IF NO ENEMY → TP FAR AWAY
🎨 UI: SOLO LEVELING / JINWOO THEME | SEMI-TRANSPARENT
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- Local Player
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart", 10)

-- Prevent duplicate
if getgenv().MathewStabedHub then return end
getgenv().MathewStabedHub = true

-- ⚙️ SETTINGS
local Settings = {
    -- Aim Lock
    AimEnabled = true,
    AimKey = Enum.UserInputType.MouseButton2,
    FOV = 150,
    LockSpeed = 0.95,
    TeamCheck = false,
    ShowFOV = true,

    -- Auto Farm
    AutoFarmEnabled = false,
    TeleportBehind = 2.5,
    StabDelay = 0.15,
    SafeDistance = 500,
}

-- 🎯 AUTO FARM STATE
local CurrentTarget = nil
local NoEnemyTimer = 0

-- 🎨 FOV CIRCLE
local FOV = Drawing.new("Circle")
FOV.Visible = true
FOV.Color = Color3.new(1, 0, 0)
FOV.Thickness = 2
FOV.Transparency = 0.6
FOV.Filled = false

-- Update FOV
local function UpdateFOV()
    FOV.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOV.Radius = Settings.FOV
    FOV.Visible = Settings.AimEnabled and Settings.ShowFOV
end

-- 🎯 GET TARGET (STICK UNTIL DEAD)
local function GetTarget()
    if CurrentTarget then
        local hum = CurrentTarget.Parent:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            NoEnemyTimer = 0
            return CurrentTarget
        else
            CurrentTarget = nil
        end
    end

    local closest = nil
    local bestDist = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, Plr in ipairs(Players:GetPlayers()) do
        if Plr == LocalPlayer then continue end
        if Settings.TeamCheck and Plr.Team == LocalPlayer.Team then continue end

        local Char = Plr.Character
        if not Char then continue end
        local Hum = Char:FindFirstChildOfClass("Humanoid")
        local Root = Char:FindFirstChild("HumanoidRootPart")
        if not Hum or not Root or Hum.Health <= 0 then continue end

        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
        if not OnScreen or ScreenPos.Z < 1 then continue end

        local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - center).Magnitude
        if Dist > Settings.FOV then continue end

        if Dist < bestDist then
            bestDist = Dist
            closest = Root
        end
    end

    CurrentTarget = closest
    return CurrentTarget
end

-- 🔒 AIM LOCK
local function AimAt(Target)
    if not Target then return end
    local CamPos = Camera.CFrame.Position
    local NewCF = CFrame.new(CamPos, Target.Position)
    Camera.CFrame = Camera.CFrame:Lerp(NewCF, Settings.LockSpeed)
end

-- 🤖 AUTO FARM LOGIC
local function AutoFarmEnemy(Target)
    if not Target or not Settings.AutoFarmEnabled then return end
    local BehindPos = Target.CFrame * CFrame.new(0, 0, Settings.TeleportBehind)
    RootPart.CFrame = BehindPos
    task.wait(0.02)
    mouse1press()
    task.wait(Settings.StabDelay)
    mouse1release()
end

-- 🛡️ SAFE TELEPORT WHEN NO ENEMY
local function TeleportToSafeSpot()
    if not Settings.AutoFarmEnabled or CurrentTarget then return end
    NoEnemyTimer += task.wait()
    if NoEnemyTimer >= 2 then
        local SafePos = RootPart.Position + Vector3.new(math.random(-Settings.SafeDistance, Settings.SafeDistance), 5, math.random(-Settings.SafeDistance, Settings.SafeDistance))
        RootPart.CFrame = CFrame.new(SafePos)
        NoEnemyTimer = 0
    end
end

-- 🔄 MAIN LOOP
RunService.RenderStepped:Connect(function()
    if not Character or not Character:FindFirstChild("Humanoid") or Character.Humanoid.Health <= 0 then
        FOV.Visible = false
        CurrentTarget = nil
        NoEnemyTimer = 0
        return
    end

    UpdateFOV()
    local Target = GetTarget()

    if Settings.AimEnabled and UserInputService:IsMouseButtonPressed(Settings.AimKey) then
        AimAt(Target)
    end

    if Settings.AutoFarmEnabled then
        if Target then
            AutoFarmEnemy(Target)
        else
            TeleportToSafeSpot()
        end
    end
end)

-- Reset on respawn
LocalPlayer.CharacterAdded:Connect(function(NewChar)
    Character = NewChar
    RootPart = NewChar:WaitForChild("HumanoidRootPart", 10)
    CurrentTarget = nil
    NoEnemyTimer = 0
end)

-- ======================================
-- 🎨 NEW UI - MADE BY MATHEW | JINWOO THEME
-- ======================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "MathewHub"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 480)
MainFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.new(0.07, 0.07, 0.14)
MainFrame.BackgroundTransparency = 0.28 -- Semi-transparent
MainFrame.BorderColor3 = Color3.new(0.55, 0.25, 0.95)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = Gui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.new(0.18, 0.08, 0.35)
TitleBar.BackgroundTransparency = 0.15
TitleBar.BorderColor3 = Color3.new(0.55, 0.25, 0.95)
TitleBar.BorderSizePixel = 1
TitleBar.Parent = MainFrame

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, 0, 1, 0)
TitleText.Text = "🌑 MATHEW HUB • SOLO LEVELING"
TitleText.Font = Enum.Font.GothamBold
TitleText.TextColor3 = Color3.new(0.95, 0.9, 1)
TitleText.BackgroundTransparency = 1
TitleText.Parent = TitleBar

-- Status Display
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.9, 0, 0, 26)
Status.Position = UDim2.new(0.05, 0, 0.12, 0)
Status.BackgroundTransparency = 1
Status.Text = "✅ READY | Hold Right Click to Aim"
Status.TextColor3 = Color3.new(0.25, 1, 0.65)
Status.Font = Enum.Font.GothamSemibold
Status.Parent = MainFrame

-- ======================================
-- 🤖 AUTO FARM SECTION
-- ======================================
local AutoFarmSection = Instance.new("Frame")
AutoFarmSection.Size = UDim2.new(0.9, 0, 0, 170)
AutoFarmSection.Position = UDim2.new(0.05, 0, 0.20, 0)
AutoFarmSection.BackgroundColor3 = Color3.new(0.11, 0.11, 0.21)
AutoFarmSection.BackgroundTransparency = 0.32
AutoFarmSection.BorderColor3 = Color3.new(0.45, 0.2, 0.85)
AutoFarmSection.BorderSizePixel = 1
AutoFarmSection.Parent = MainFrame

local AutoFarmTitle = Instance.new("TextLabel")
AutoFarmTitle.Size = UDim2.new(1, 0, 0, 28)
AutoFarmTitle.Position = UDim2.new(0, 0, 0.02, 0)
AutoFarmTitle.Text = "🤖 AUTO FARM"
AutoFarmTitle.Font = Enum.Font.GothamBold
AutoFarmTitle.TextColor3 = Color3.new(0.75, 0.55, 1)
AutoFarmTitle.BackgroundTransparency = 1
AutoFarmTitle.Parent = AutoFarmSection

-- Auto Farm Toggle
local AutoFarmBtn = Instance.new("TextButton")
AutoFarmBtn.Size = UDim2.new(0.92, 0, 0, 32)
AutoFarmBtn.Position = UDim2.new(0.04, 0, 0.22, 0)
AutoFarmBtn.BackgroundColor3 = Color3.new(0.65, 0.2, 0.2)
AutoFarmBtn.BackgroundTransparency = 0.2
AutoFarmBtn.Text = "🔴 AUTO FARM: OFF"
AutoFarmBtn.TextColor3 = Color3.new(1,1,1)
AutoFarmBtn.Font = Enum.Font.GothamBold
AutoFarmBtn.Parent = AutoFarmSection

-- Teleport Behind Input
local DistLabel = Instance.new("TextLabel")
DistLabel.Size = UDim2.new(0.45, 0, 0, 22)
DistLabel.Position = UDim2.new(0.04, 0, 0.52, 0)
DistLabel.Text = "TP Behind:"
DistLabel.TextColor3 = Color3.new(0.8,0.8,0.9)
DistLabel.BackgroundTransparency = 1
DistLabel.Font = Enum.Font.GothamSemibold
DistLabel.Parent = AutoFarmSection

local DistBox = Instance.new("TextBox")
DistBox.Size = UDim2.new(0.45, 0, 0, 28)
DistBox.Position = UDim2.new(0.51, 0, 0.52, 0)
DistBox.BackgroundColor3 = Color3.new(0.2,0.2,0.3)
DistBox.BackgroundTransparency = 0.2
DistBox.TextColor3 = Color3.new(1,1,1)
DistBox.Text = "2.5"
DistBox.PlaceholderText = "Distance"
DistBox.Font = Enum.Font.GothamSemibold
DistBox.Parent = AutoFarmSection

-- Safe TP Distance Input
local SafeLabel = Instance.new("TextLabel")
SafeLabel.Size = UDim2.new(0.45, 0, 0, 22)
SafeLabel.Position = UDim2.new(0.04, 0, 0.78, 0)
SafeLabel.Text = "Safe TP:"
SafeLabel.TextColor3 = Color3.new(0.8,0.8,0.9)
SafeLabel.BackgroundTransparency = 1
SafeLabel.Font = Enum.Font.GothamSemibold
SafeLabel.Parent = AutoFarmSection

local SafeBox = Instance.new("TextBox")
SafeBox.Size = UDim2.new(0.45, 0, 0, 28)
SafeBox.Position = UDim2.new(0.51, 0, 0.78, 0)
SafeBox.BackgroundColor3 = Color3.new(0.2,0.2,0.3)
SafeBox.BackgroundTransparency = 0.2
SafeBox.TextColor3 = Color3.new(1,1,1)
SafeBox.Text = "500"
SafeBox.PlaceholderText = "Studs"
SafeBox.Font = Enum.Font.GothamSemibold
SafeBox.Parent = AutoFarmSection

-- ======================================
-- 🔒 AIM SETTINGS SECTION
-- ======================================
local AimSection = Instance.new("Frame")
AimSection.Size = UDim2.new(0.9, 0, 0, 140)
AimSection.Position = UDim2.new(0.05, 0, 0.60, 0)
AimSection.BackgroundColor3 = Color3.new(0.11, 0.11, 0.21)
AimSection.BackgroundTransparency = 0.32
AimSection.BorderColor3 = Color3.new(0.45, 0.2, 0.85)
AimSection.BorderSizePixel = 1
AimSection.Parent = MainFrame

local AimTitle = Instance.new("TextLabel")
AimTitle.Size = UDim2.new(1, 0, 0, 28)
AimTitle.Position = UDim2.new(0, 0, 0.02, 0)
AimTitle.Text = "🔒 AIM SETTINGS"
AimTitle.Font = Enum.Font.GothamBold
AimTitle.TextColor3 = Color3.new(0.75, 0.55, 1)
AimTitle.BackgroundTransparency = 1
AimTitle.Parent = AimSection

-- FOV Input
local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(0.45, 0, 0, 22)
FOVLabel.Position = UDim2.new(0.04, 0, 0.28, 0)
FOVLabel.Text = "FOV Size:"
FOVLabel.TextColor3 = Color3.new(0.8,0.8,0.9)
FOVLabel.BackgroundTransparency = 1
FOVLabel.Font = Enum.Font.GothamSemibold
FOVLabel.Parent = AimSection

local FOVBox = Instance.new("TextBox")
FOVBox.Size = UDim2.new(0.45, 0, 0, 28)
FOVBox.Position = UDim2.new(0.51, 0, 0.28, 0)
FOVBox.BackgroundColor3 = Color3.new(0.2,0.2,0.3)
FOVBox.BackgroundTransparency = 0.2
FOVBox.TextColor3 = Color3.new(1,1,1)
FOVBox.Text = "150"
FOVBox.PlaceholderText = "Range"
FOVBox.Font = Enum.Font.GothamSemibold
FOVBox.Parent = AimSection

-- Lock Speed Input
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0.45, 0, 0, 22)
SpeedLabel.Position = UDim2.new(0.04, 0, 0.60, 0)
SpeedLabel.Text = "Lock Speed:"
SpeedLabel.TextColor3 = Color3.new(0.8,0.8,0.9)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Font = Enum.Font.GothamSemibold
SpeedLabel.Parent = AimSection

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(0.45, 0, 0, 28)
SpeedBox.Position = UDim2.new(0.51, 0, 0.60, 0)
SpeedBox.BackgroundColor3 = Color3.new(0.2,0.2,0.3)
SpeedBox.BackgroundTransparency = 0.2
SpeedBox.TextColor3 = Color3.new(1,1,1)
SpeedBox.Text = "0.95"
SpeedBox.PlaceholderText = "0.1 - 1"
SpeedBox.Font = Enum.Font.GothamSemibold
SpeedBox.Parent = AimSection

-- ======================================
-- BOTTOM BUTTONS
-- ======================================
local ApplyBtn = Instance.new("TextButton")
ApplyBtn.Size = UDim2.new(0.44, 0, 0, 32)
ApplyBtn.Position = UDim2.new(0.05, 0, 0.90, 0)
ApplyBtn.BackgroundColor3 = Color3.new(0.15, 0.7, 0.35)
ApplyBtn.BackgroundTransparency = 0.2
ApplyBtn.Text = "✅ APPLY"
ApplyBtn.TextColor3 = Color3.new(1,1,1)
ApplyBtn.Font = Enum.Font.GothamBold
ApplyBtn.Parent = MainFrame

local BgBtn = Instance.new("TextButton")
BgBtn.Size = UDim2.new(0.44, 0, 0, 32)
BgBtn.Position = UDim2.new(0.51, 0, 0.90, 0)
BgBtn.BackgroundColor3 = Color3.new(0.55, 0.25, 0.95)
BgBtn.BackgroundTransparency = 0.2
BgBtn.Text = "🎨 BG TOGGLE"
BgBtn.TextColor3 = Color3.new(1,1,1)
BgBtn.Font = Enum.Font.GothamBold
BgBtn.Parent = MainFrame

-- ======================================
-- FUNCTIONS
-- ======================================

-- Auto Farm Toggle
AutoFarmBtn.MouseButton1Click:Connect(function()
    Settings.AutoFarmEnabled = not Settings.AutoFarmEnabled
    if Settings.AutoFarmEnabled then
        AutoFarmBtn.Text = "🟢 AUTO FARM: ON"
        AutoFarmBtn.BackgroundColor3 = Color3.new(0.15, 0.7, 0.35)
        Status.Text = "🤖 FARMING | Mathew Hub Active"
    else
        AutoFarmBtn.Text = "🔴 AUTO FARM: OFF"
        AutoFarmBtn.BackgroundColor3 = Color3.new(0.65, 0.2, 0.2)
        Status.Text = "✅ HOLD RIGHT CLICK TO AIM"
        CurrentTarget = nil
        NoEnemyTimer = 0
    end
end)

-- Apply Settings
ApplyBtn.MouseButton1Click:Connect(function()
    Settings.FOV = math.clamp(tonumber(FOVBox.Text) or 150, 50, 300)
    Settings.LockSpeed = math.clamp(tonumber(SpeedBox.Text) or 0.95, 0.1, 1)
    Settings.TeleportBehind = math.clamp(tonumber(DistBox.Text) or 2.5, 1, 5)
    Settings.SafeDistance = math.clamp(tonumber(SafeBox.Text) or 500, 100, 1000)
    Status.Text = "✅ SETTINGS SAVED!"
    task.wait(1)
    Status.Text = Settings.AutoFarmEnabled and "🤖 FARMING | Mathew Hub" or "✅ READY | Hold Right Click"
end)

-- Background Transparency Toggle
local BgTransparency = 0.28
BgBtn.MouseButton1Click:Connect(function()
    BgTransparency = BgTransparency == 0.28 and 0.7 or 0.28
    MainFrame.BackgroundTransparency = BgTransparency
    AutoFarmSection.BackgroundTransparency = BgTransparency + 0.04
    AimSection.BackgroundTransparency = BgTransparency + 0.04
end)

-- Hide/Show Menu
UserInputService.InputBegan:Connect(function(Input, GP)
    if GP then return end
    if Input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)