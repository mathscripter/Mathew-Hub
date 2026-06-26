-- MM2 Hub | Name: HANS HUB | Split Layout: Left Menu / Right Settings
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
        NoClip = {Enabled = false},
        XRay = {Enabled = false, Transparency = 0.3}
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

-- ESP & Storage
local ESPObjects = {}
local OriginalTransparency = {}
local CurrentCategory = "RoleFeatures"

-- UI Theme
local Theme = {
    Background = Color3.fromRGB(12, 12, 20),
    SidebarBG = Color3.fromRGB(22, 22, 35),
    PanelBG = Color3.fromRGB(28, 28, 45),
    Accent = Color3.fromRGB(75, 160, 255),
    Text = Color3.new(1, 1, 1),
    TextDim = Color3.fromRGB(180, 180, 200),
    ON = Color3.fromRGB(70, 220, 120),
    OFF = Color3.fromRGB(220, 70, 90),
    Transparency = 0.2
}

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HansHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 450)
MainFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BackgroundTransparency = Theme.Transparency
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Theme.Accent
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.35

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Theme.SidebarBG
TitleBar.BackgroundTransparency = Theme.Transparency
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "✨ HANS HUB"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.TextColor3 = Theme.Accent
Title.Parent = TitleBar

-- Left Sidebar (Categories)
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -45)
Sidebar.Position = UDim2.new(0, 5, 0, 42)
Sidebar.BackgroundColor3 = Theme.SidebarBG
Sidebar.BackgroundTransparency = Theme.Transparency
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

local SidebarLayout = Instance.new("UIListLayout", Sidebar)
SidebarLayout.Padding = UDim.new(0, 6)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.PaddingTop = UDim.new(0, 8)

-- Right Settings Panel
local SettingsPanel = Instance.new("Frame")
SettingsPanel.Size = UDim2.new(1, -155, 1, -45)
SettingsPanel.Position = UDim2.new(0, 150, 0, 42)
SettingsPanel.BackgroundColor3 = Theme.PanelBG
SettingsPanel.BackgroundTransparency = Theme.Transparency
SettingsPanel.BorderSizePixel = 0
SettingsPanel.Parent = MainFrame
Instance.new("UICorner", SettingsPanel).CornerRadius = UDim.new(0, 8)

local PanelScroll = Instance.new("ScrollingFrame")
PanelScroll.Size = UDim2.new(1, -10, 1, -10)
PanelScroll.Position = UDim2.new(0, 5, 0, 5)
PanelScroll.BackgroundTransparency = 1
PanelScroll.ScrollBarThickness = 4
PanelScroll.ScrollBarImageColor3 = Theme.Accent
PanelScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PanelScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PanelScroll.Parent = SettingsPanel

local PanelLayout = Instance.new("UIListLayout", PanelScroll)
PanelLayout.Padding = UDim.new(0, 8)
PanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
local PanelPadding = Instance.new("UIPadding", PanelScroll)
PanelPadding.PaddingTop = UDim.new(0, 6)

-- Helper Functions
local function ClearPanel()
    for _, child in ipairs(PanelScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

local function CreateCategoryButton(name, key)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -10, 0, 34)
    Btn.BackgroundColor3 = Theme.PanelBG
    Btn.BackgroundTransparency = Theme.Transparency
    Btn.BorderSizePixel = 0
    Btn.Text = "  " .. name
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 13
    Btn.TextColor3 = Theme.TextDim
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.Parent = Sidebar
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    Btn.MouseEnter:Connect(function() if CurrentCategory ~= key then Btn.BackgroundTransparency = 0.15 end end)
    Btn.MouseLeave:Connect(function() if CurrentCategory ~= key then Btn.BackgroundTransparency = Theme.Transparency end end)

    Btn.MouseButton1Click:Connect(function()
        CurrentCategory = key
        -- Reset all button styles
        for _, b in ipairs(Sidebar:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundColor3 = Theme.PanelBG
                b.TextColor3 = Theme.TextDim
            end
        end
        -- Highlight selected
        Btn.BackgroundColor3 = Theme.Accent
        Btn.TextColor3 = Color3.new(1,1,1)
        ClearPanel()
        LoadCategorySettings(key)
    end)
end

local function CreateToggle(name, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 36)
    Frame.BackgroundColor3 = Theme.SidebarBG
    Frame.BackgroundTransparency = Theme.Transparency
    Frame.BorderSizePixel = 0
    Frame.Parent = PanelScroll
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 46, 0, 24)
    Button.Position = UDim2.new(0.82, 0, 0.5, -12)
    Button.BackgroundColor3 = Theme.OFF
    Button.BackgroundTransparency = Theme.Transparency
    Button.Text = "OFF"
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 11
    Button.TextColor3 = Color3.new(1,1,1)
    Button.Parent = Frame
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)

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
    Frame.Size = UDim2.new(1, 0, 0, 36)
    Frame.BackgroundColor3 = Theme.SidebarBG
    Frame.BackgroundTransparency = Theme.Transparency
    Frame.BorderSizePixel = 0
    Frame.Parent = PanelScroll
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.55, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(0, 70, 0, 24)
    Box.Position = UDim2.new(0.7, 0, 0.5, -12)
    Box.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    Box.BackgroundTransparency = Theme.Transparency
    Box.Text = tostring(default)
    Box.Font = Enum.Font.Gotham
    Box.TextSize = 12
    Box.TextColor3 = Theme.Accent
    Box.ClearTextOnFocus = false
    Box.Parent = Frame
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)

    Box.FocusLost:Connect(function()
        local val = tonumber(Box.Text) or default
        val = math.clamp(val, 1, 999)
        Box.Text = tostring(val)
        callback(val)
    end)
end

-- Load settings into panel based on selected category
function LoadCategorySettings(cat)
    if cat == "RoleFeatures" then
        CreateToggle("🔪 Auto Stab", function(v) MM2_Settings.RoleFeatures.AutoStab.Enabled = v end)
        CreateInput("Stab Range", 25, function(v) MM2_Settings.RoleFeatures.AutoStab.Range = v end)
        CreateToggle("🔫 Auto Shoot", function(v) MM2_Settings.RoleFeatures.AutoShoot.Enabled = v end)
        CreateInput("Shoot Range", 80, function(v) MM2_Settings.RoleFeatures.AutoShoot.Range = v end)
        CreateToggle("🎯 Silent Aim", function(v) MM2_Settings.RoleFeatures.SilentAim.Enabled = v end)
        CreateInput("FOV Size", 120, function(v) MM2_Settings.RoleFeatures.SilentAim.FOV = v end)
    elseif cat == "Utilities" then
        CreateToggle("💎 Auto Collect", function(v) MM2_Settings.Utilities.AutoCollect.Enabled = v end)
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
        CreateToggle("👁 X-Ray", function(v) MM2_Settings.Utilities.XRay.Enabled = v end)
        CreateToggle("🚫 No Clip", function(v) MM2_Settings.Utilities.NoClip.Enabled = v end)
    elseif cat == "ESP" then
        CreateToggle("✅ Enable ESP", function(v) MM2_Settings.ESP.Enabled = v end)
        CreateToggle("Show Murderer", function(v) MM2_Settings.ESP.ShowMurderer = v end)
        CreateToggle("Show Sheriff", function(v) MM2_Settings.ESP.ShowSheriff = v end)
        CreateToggle("Show Others", function(v) MM2_Settings.ESP.ShowOthers = v end)
        CreateToggle("Draw Box", function(v) MM2_Settings.ESP.Box = v end)
        CreateToggle("Draw Name", function(v) MM2_Settings.ESP.Name = v end)
        CreateToggle("Draw Distance", function(v) MM2_Settings.ESP.Distance = v end)
    end
end

-- Create Category Buttons
CreateCategoryButton("Role Features", "RoleFeatures")
CreateCategoryButton("Utilities", "Utilities")
CreateCategoryButton("ESP", "ESP")

-- Load default category on start
task.wait()
LoadCategorySettings("RoleFeatures")
-- Highlight default button
Sidebar:GetChildren()[2].BackgroundColor3 = Theme.Accent
Sidebar:GetChildren()[2].TextColor3 = Color3.new(1,1,1)

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
    else
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
        end
    end

    -- X-Ray
    if MM2_Settings.Utilities.XRay.Enabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character) and obj.Transparency < 1 then
                if not OriginalTransparency[obj] then OriginalTransparency[obj] = obj.Transparency end
                obj.Transparency = math.max(MM2_Settings.Utilities.XRay.Transparency, OriginalTransparency[obj])
            end
        end
    else
        for obj, trans in pairs(OriginalTransparency) do
            if obj and obj:IsDescendantOf(Workspace) then obj.Transparency = trans end
        end
        OriginalTransparency = {}
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
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") and p.Character.Humanoid.Health > 0 then
                local dist = (Root.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < MM2_Settings.RoleFeatures.AutoStab.Range and p.Team.Name ~= "Murderer" then
                    pcall(function()
                        Mouse.Target = p.Character.HumanoidRootPart
                        Mouse:Button1Down()
                        task.wait(0.02)
                        Mouse:Button1Up()
                    end)
                end
            end
        end
    end

    -- Auto Shoot
    if MM2_Settings.RoleFeatures.AutoShoot.Enabled and LocalPlayer.Team and LocalPlayer.Team.Name == "Sheriff" and Murderer then
        if Murderer.Character and Murderer.Character:FindFirstChild("HumanoidRootPart") and Murderer.Character:FindFirstChildOfClass("Humanoid") and Murderer.Character.Humanoid.Health > 0 then
            local dist = (Root.Position - Murderer.Character.HumanoidRootPart.Position).Magnitude
            if dist < MM2_Settings.RoleFeatures.AutoShoot.Range then
                pcall(function()
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, Murderer.Character.HumanoidRootPart.Position)
                    Mouse:Button1Down()
                    task.wait(0.02)
                    Mouse:Button1Up()
                end)
            end
        end
    end

    -- Auto Collect
    if MM2_Settings.Utilities.AutoCollect.Enabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if (obj.Name == "Knife" or obj.Name == "Gun" or obj.Name == "Coin" or obj.Name == "Medkit") and obj:IsA("BasePart") and obj.CanCollide then
                local dist = (Root.Position - obj.Position).Magnitude
                if dist < MM2_Settings.Utilities.AutoCollect.Range then
                    Root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 2.5, 0))
                    task.wait(0.05)
                end
            end
        end
    end

    -- ESP
    if MM2_Settings.ESP.Enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") and p.Character.Humanoid.Health > 0 then
                local hrp = p.Character.HumanoidRootPart
                local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
                local team = p.Team and p.Team.Name or ""

                if not vis then
                    if ESPObjects[p] then
                        for _, d in pairs(ESPObjects[p]) do d.Visible = false end
                    end
                    continue
                end

                -- Filter by ESP settings
                if (team == "Murderer" and not MM2_Settings.ESP.ShowMurderer)
                or (team == "Sheriff" and not MM2_Settings.ESP.ShowSheriff)
                or (team ~= "Murderer" and team ~= "Sheriff" and not MM2_Settings.ESP.ShowOthers) then
                    if ESPObjects[p] then
                        for _, d in pairs(ESPObjects[p]) do d.Visible = false end
                    end
                    continue
                end

                if not ESPObjects[p] then
                    ESPObjects[p] = {
                        Box = Drawing.new("Square"),
                        Name = Drawing.new("Text"),
                        Dist = Drawing.new("Text")
                    }
                end

                local color = team == "Murderer" and Color3.new(1,0.2,0.2) or team == "Sheriff" and Color3.new(0.2,1,0.3) or Color3.new(0.9,0.9,0.9)
                local box = ESPObjects[p].Box
                local name = ESPObjects[p].Name
                local dist = ESPObjects[p].Dist
                local size = Vector2.new(2200 / pos.Z, 3000 / pos.Z)

                box.Visible = MM2_Settings.ESP.Box
                box.Position = Vector2.new(pos.X - size.X/2, pos.Y - size.Y/2)
                box.Size = size
                box.Color = color
                box.Thickness = 1.2
                box.Transparency = 0.6
                box.Filled = false

                name.Visible = MM2_Settings.ESP.Name
                name.Position = Vector2.new(pos.X, pos.Y - size.Y/2 - 18)
                name.Text = string.format("%s [%s]", p.Name, team ~= "" and team or "None")
                name.Color = color
                name.Size = 14
                name.Center = true
                name.Outline = true

                dist.Visible = MM2_Settings.ESP.Distance
                dist.Position = Vector2.new(pos.X, pos.Y + size.Y/2 + 8)
                dist.Text = string.format("%.0fm", (Root.Position - hrp.Position).Magnitude)
                dist.Color = color
                dist.Size = 12
                dist.Center = true
                dist.Outline = true
            end
        end
    else
        for _, data in pairs(ESPObjects) do
            for _, d in pairs(data) do d.Visible = false end
        end
    end
end)

-- Cleanup
LocalPlayer.OnRemoving:Connect(function()
    for _, data in pairs(ESPObjects) do
        for _, d in pairs(data) do d:Remove() end
    end
end)

-- Toggle Menu
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Notification
StarterGui:SetCore("SendNotification", {
    Title = "✨ HANS HUB",
    Text = "Loaded successfully | Press INSERT to open/close",
    Duration = 4
})