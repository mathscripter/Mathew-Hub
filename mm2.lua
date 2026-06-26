-- MM2 Hub | Name: HANNAH BANTOT | Organized Categories | Clean Transparent UI
getgenv().MM2_Settings = {
    RoleFeatures = {
        AutoStab = {Enabled = false, Range = 25},
        AutoShoot = {Enabled = false, Range = 80},
        SilentAim = {Enabled = false, FOV = 120, TeamCheck = true}
    },
    Utilities = {
        AutoCollect = {Enabled = false, Range = 50},
        WalkSpeed = {Enabled = false, Speed = 32},
        JumpPower = {Enabled = false, Power = 60},
        Reach = {Enabled = false, Range = 20},
        NoClip = {Enabled = false}
    },
    ESP = {
        Enabled = false,
        ShowMurderer = true,
        ShowSheriff = true,
        ShowOthers = true,
        Box = true,
        Name = true,
        Distance = true
    }
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ESP Storage
local ESPObjects = {}

-- UI Theme
local Theme = {
    Background = Color3.fromRGB(12, 12, 20),
    ElementBG = Color3.fromRGB(25, 25, 40),
    Accent = Color3.fromRGB(255, 85, 150),
    Text = Color3.new(1, 1, 1),
    ON = Color3.fromRGB(70, 220, 120),
    OFF = Color3.fromRGB(220, 70, 90),
    Transparency = 0.22
}

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HannahBantotHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 480)
MainFrame.Position = UDim2.new(0.05, 0, 0.12, 0)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BackgroundTransparency = Theme.Transparency
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Theme.Accent
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.4

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.BackgroundColor3 = Theme.ElementBG
TitleBar.BackgroundTransparency = Theme.Transparency
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 18, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "✨ HANNAH BANTOT ✨"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Theme.Accent
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Content Scrolling Area
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -14, 1, -58)
Content.Position = UDim2.new(0, 7, 0, 52)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness = 5
Content.ScrollBarImageColor3 = Theme.Accent
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = MainFrame

local Layout = Instance.new("UIListLayout", Content)
Layout.Padding = UDim.new(0, 9)
Layout.SortOrder = Enum.SortOrder.LayoutOrder

local Padding = Instance.new("UIPadding", Content)
Padding.PaddingTop = UDim.new(0, 6)
Padding.PaddingBottom = UDim.new(0, 6)

-- Helper Functions
local function AddCategory(name)
    local CatFrame = Instance.new("Frame")
    CatFrame.Size = UDim2.new(1, 0, 0, 30)
    CatFrame.BackgroundTransparency = 1
    CatFrame.Parent = Content

    local CatLabel = Instance.new("TextLabel")
    CatLabel.Size = UDim2.new(1, 0, 1, 0)
    CatLabel.BackgroundTransparency = 1
    CatLabel.Text = "▸ " .. name:upper()
    CatLabel.Font = Enum.Font.GothamBold
    CatLabel.TextSize = 14
    CatLabel.TextColor3 = Theme.Accent
    CatLabel.TextXAlignment = Enum.TextXAlignment.Left
    CatLabel.Parent = CatFrame
end

local function CreateToggle(name, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 38)
    Frame.BackgroundColor3 = Theme.ElementBG
    Frame.BackgroundTransparency = Theme.Transparency
    Frame.BorderSizePixel = 0
    Frame.Parent = Content
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.73, 0, 1, 0)
    Label.Position = UDim2.new(0, 14, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 52, 0, 26)
    Button.Position = UDim2.new(0.81, 0, 0.5, -13)
    Button.BackgroundColor3 = Theme.OFF
    Button.BackgroundTransparency = Theme.Transparency
    Button.Text = "OFF"
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 11
    Button.TextColor3 = Theme.Text
    Button.Parent = Frame
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 7)

    local Enabled = false
    Button.MouseButton1Click:Connect(function()
        Enabled = not Enabled
        Button.Text = Enabled and "ON" or "OFF"
        Button.BackgroundColor3 = Enabled and Theme.ON or Theme.OFF
        callback(Enabled)
    end)
end

local function CreateInput(name, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 38)
    Frame.BackgroundColor3 = Theme.ElementBG
    Frame.BackgroundTransparency = Theme.Transparency
    Frame.BorderSizePixel = 0
    Frame.Parent = Content
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.59, 0, 1, 0)
    Label.Position = UDim2.new(0, 14, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(0, 80, 0, 26)
    Box.Position = UDim2.new(0.7, 0, 0.5, -13)
    Box.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    Box.BackgroundTransparency = Theme.Transparency
    Box.Text = tostring(default)
    Box.Font = Enum.Font.Gotham
    Box.TextSize = 12
    Box.TextColor3 = Theme.Accent
    Box.ClearTextOnFocus = false
    Box.Parent = Frame
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 7)

    Box.FocusLost:Connect(function()
        local val = tonumber(Box.Text) or default
        val = math.clamp(val, 1, 999)
        Box.Text = tostring(val)
        callback(val)
    end)
end

-- Add Features
AddCategory("ROLE FEATURES")
CreateToggle("🔪 Auto Stab", function(v) MM2_Settings.RoleFeatures.AutoStab.Enabled = v end)
CreateInput("Stab Range", 25, function(v) MM2_Settings.RoleFeatures.AutoStab.Range = v end)

CreateToggle("🔫 Auto Shoot", function(v) MM2_Settings.RoleFeatures.AutoShoot.Enabled = v end)
CreateInput("Shoot Range", 80, function(v) MM2_Settings.RoleFeatures.AutoShoot.Range = v end)

CreateToggle("🎯 Silent Aim", function(v) MM2_Settings.RoleFeatures.SilentAim.Enabled = v end)
CreateInput("FOV Size", 120, function(v) MM2_Settings.RoleFeatures.SilentAim.FOV = v end)

AddCategory("UTILITIES")
CreateToggle("💎 Auto Collect Items", function(v) MM2_Settings.Utilities.AutoCollect.Enabled = v end)
CreateInput("Collect Range", 50, function(v) MM2_Settings.Utilities.AutoCollect.Range = v end)

CreateToggle("🏃 Walk Speed", function(v)
    MM2_Settings.Utilities.WalkSpeed.Enabled = v
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)
CreateInput("Speed Value", 32, function(v) MM2_Settings.Utilities.WalkSpeed.Speed = v end)

CreateToggle("🦘 Jump Power", function(v)
    MM2_Settings.Utilities.JumpPower.Enabled = v
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = 50
    end
end)
CreateInput("Jump Value", 60, function(v) MM2_Settings.Utilities.JumpPower.Power = v end)

CreateToggle("📏 Reach", function(v) MM2_Settings.Utilities.Reach.Enabled = v end)
CreateInput("Reach Range", 20, function(v) MM2_Settings.Utilities.Reach.Range = v end)

CreateToggle("🚫 No Clip", function(v) MM2_Settings.Utilities.NoClip.Enabled = v end)

AddCategory("ESP")
CreateToggle("👁 Enable ESP", function(v) MM2_Settings.ESP.Enabled = v end)

-- Main Logic
RunService.RenderStepped:Connect(function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local Root = LocalPlayer.Character.HumanoidRootPart
    local Humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not Humanoid or Humanoid.Health <= 0 then return end

    -- Speed & Jump
    if MM2_Settings.Utilities.WalkSpeed.Enabled then
        Humanoid.WalkSpeed = MM2_Settings.Utilities.WalkSpeed.Speed
    end
    if MM2_Settings.Utilities.JumpPower.Enabled then
        Humanoid.JumpPower = MM2_Settings.Utilities.JumpPower.Power
    end

    -- No Clip
    if MM2_Settings.Utilities.NoClip.Enabled then
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end

    -- Find Roles
    local Murderer, Sheriff = nil, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if p.Team and p.Team.Name == "Murderer" then Murderer = p end
            if p.Team and p.Team.Name == "Sheriff" then Sheriff = p end
        end
    end

    -- Auto Stab
    if MM2_Settings.RoleFeatures.AutoStab.Enabled and LocalPlayer.Team and LocalPlayer.Team.Name == "Murderer" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (Root.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < MM2_Settings.RoleFeatures.AutoStab.Range and p.Team.Name ~= "Murderer" then
                    pcall(function()
                        Mouse.Target = p.Character.HumanoidRootPart
                        Mouse:Button1Down()
                        task.wait(0.03)
                        Mouse:Button1Up()
                    end)
                end
            end
        end
    end

    -- Auto Shoot
    if MM2_Settings.RoleFeatures.AutoShoot.Enabled and LocalPlayer.Team and LocalPlayer.Team.Name == "Sheriff" and Murderer then
        if Murderer.Character and Murderer.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (Root.Position - Murderer.Character.HumanoidRootPart.Position).Magnitude
            if dist < MM2_Settings.RoleFeatures.AutoShoot.Range then
                pcall(function()
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, Murderer.Character.HumanoidRootPart.Position)
                    Mouse:Button1Down()
                    task.wait(0.03)
                    Mouse:Button1Up()
                end)
            end
        end
    end

    -- Auto Collect
    if MM2_Settings.Utilities.AutoCollect.Enabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if (obj.Name == "Knife" or obj.Name == "Gun" or obj.Name == "Coin" or obj.Name == "Medkit") and obj:IsA("BasePart") then
                local dist = (Root.Position - obj.Position).Magnitude
                if dist < MM2_Settings.Utilities.AutoCollect.Range then
                    Root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 2.5, 0))
                    task.wait(0.05)
                end
            end
        end
    end

    -- ESP Logic
    if MM2_Settings.ESP.Enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
                local color = p.Team.Name == "Murderer" and Color3.new(1, 0.3, 0.3) or p.Team.Name == "Sheriff" and Color3.new(0.3, 1, 0.4) or Color3.new(0.9, 0.9, 0.9)

                if vis then
                    if not ESPObjects[p] then
                        ESPObjects[p] = {
                            Box = Drawing.new("Square"),
                            Name = Drawing.new("Text"),
                            Dist = Drawing.new("Text")
                        }
                    end
                    local box = ESPObjects[p].Box
                    local name = ESPObjects[p].Name
                    local dist = ESPObjects[p].Dist
                    local size = Vector2.new(2200 / pos.Z, 3000 / pos.Z)

                    box.Visible = true
                    box.Position = Vector2.new(pos.X - size.X/2, pos.Y - size.Y/2)
                    box.Size = size
                    box.Color = color
                    box.Thickness = 1
                    box.Transparency = 0.7

                    name.Visible = true
                    name.Position = Vector2.new(pos.X, pos.Y - size.Y/2 - 16)
                    name.Text = p.Name .. " [" .. p.Team.Name .. "]"
                    name.Color = color
                    name.Size = 13
                    name.Center = true

                    dist.Visible = true
                    dist.Position = Vector2.new(pos.X, pos.Y + size.Y/2 + 6)
                    dist.Text = math.floor((Root.Position - hrp.Position).Magnitude) .. "m"
                    dist.Color = color
                    dist.Size = 11
                    dist.Center = true
                else
                    if ESPObjects[p] then
                        ESPObjects[p].Box.Visible = false
                        ESPObjects[p].Name.Visible = false
                        ESPObjects[p].Dist.Visible = false
                    end
                end
            end
        end
    else
        for _, obj in pairs(ESPObjects) do
            obj.Box.Visible = false
            obj.Name.Visible = false
            obj.Dist.Visible = false
        end
    end
end)

-- Toggle Menu
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Load Notification
StarterGui:SetCore("SendNotification", {
    Title = "✨ HANNAH BANTOT",
    Text = "Hub loaded successfully | Press INSERT to open/close",
    Duration = 4
})