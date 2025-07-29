-- ✅ 白名单验证（来自 Gist 托管）
local whitelistUrl = "https://gist.githubusercontent.com/George78198/4e5e70a7ea774c94a634789d3340b37b/raw/3b81f2daf5b8f1e301cfe23369a59bd888a7faac/whitelist.json"
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local success, result = pcall(function()
    return HttpService:JSONDecode(game:HttpGet(whitelistUrl))
end)

if not success or not table.find(result, LocalPlayer.Name) then
    LocalPlayer:Kick("你不在白名单中，无法使用脚本")
    return
end

-- ✅ 验证通过，载入主脚本
print("✅ 白名单验证通过，开始运行脚本")

local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local HttpService = game:GetService("HttpService")

-- 目标物品
local TARGET_NAMES = {
    "Money print", "Void Gem", "Diamond",
    "Blue Candy Cane", "Red Candy Cane",
    "Golden Rose", "Black Rose",
    "Heart Balloon", "Golden Clover Balloon", "Bat Balloon"
}

-- 防止重复走动
local walking = false
local visitedServers = {}

local function walkForwardStep()
    if walking then return end
    walking = true
    VirtualInputManager:SendKeyEvent(true, "W", false, game)
    task.wait(0.5)
    VirtualInputManager:SendKeyEvent(false, "W", false, game)
    walking = false
end

local function teleportTo(position)
    if humanoidRootPart then
        humanoidRootPart.CFrame = position
        task.wait(0.2)
    end
end

local function findTargetPrompt()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and table.find(TARGET_NAMES, v.ObjectText) then
            return v
        end
    end
    return nil
end

local function scanAndPickup()
    local prompt = findTargetPrompt()
    if prompt then
        local item = prompt.Parent:IsA("Model") and prompt.Parent.PrimaryPart or prompt.Parent
        if item and item:IsA("BasePart") then
            teleportTo(item.CFrame * CFrame.new(0, 2, 0))
            prompt.HoldDuration = 0
            prompt.RequiresLineOfSight = false
            fireproximityprompt(prompt)
            task.wait(0.5)
            return true
        end
    end
    return false
end

-- 自动打开银行/保险箱（目标物品存在时）
local function openBankAndSafeIfNeeded()
    local bankDoor = workspace:FindFirstChild("BankDoor") or workspace:FindFirstChild("BankDoorModel")
    local safeBox = workspace:FindFirstChild("SafeBox") or workspace:FindFirstChild("SafeBoxModel")

    local function needOpen(container)
        if not container then return false end
        for _, v in pairs(container:GetDescendants()) do
            if v:IsA("ProximityPrompt") and table.find(TARGET_NAMES, v.ObjectText) then
                return true
            end
        end
        return false
    end

    if needOpen(bankDoor) then
        local prompt = bankDoor:FindFirstChildOfClass("ProximityPrompt")
        if prompt then fireproximityprompt(prompt) end
    end

    if needOpen(safeBox) then
        local prompt = safeBox:FindFirstChildOfClass("ProximityPrompt")
        if prompt then fireproximityprompt(prompt) end
    end
end

-- 换服逻辑（避免重复服务器）
local function hopServer()
    local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    if not success then return end

    local data = HttpService:JSONDecode(response)
    if not data or not data.data then return end

    local servers = data.data
    table.sort(servers, function(a, b) return a.playing < b.playing end)

    for _, server in ipairs(servers) do
        if server.playing >= 5 and server.id ~= game.JobId and not visitedServers[server.id] then
            visitedServers[server.id] = true
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, localPlayer)
            return
        end
    end
end

-- UI 中间动画 + 右下角服务器人数 + 信息标签
local ScreenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
ScreenGui.ResetOnSpawn = false

local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(0, 600, 0, 50)
TextLabel.Position = UDim2.new(0.5, -300, 0.4, 0)
TextLabel.BackgroundTransparency = 1
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.Font = Enum.Font.GothamBold
TextLabel.TextSize = 28
TextLabel.Text = ""
TextLabel.Parent = ScreenGui

local displayText = "快手细猫ohio印钞机脚本已开启准备换服"

local function animateText()
    TextLabel.Text = ""
    for i = 1, #displayText do
        TextLabel.Text = string.sub(displayText, 1, i)
        task.wait(0.02)  -- 速度加快
    end
end

local InfoFrame = Instance.new("Frame")
InfoFrame.Size = UDim2.new(0, 260, 0, 110)
InfoFrame.Position = UDim2.new(1, -270, 1, -120)
InfoFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
InfoFrame.BackgroundTransparency = 0.4
InfoFrame.BorderSizePixel = 0
InfoFrame.Parent = ScreenGui

local function createSmallLabel(text, posY)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, posY)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.Text = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = InfoFrame
    return label
end

createSmallLabel("脚本作者QQ：366118610", 5)
createSmallLabel("快手号：OvOximao", 30)
createSmallLabel("细猫QQ印钞脚本官方群：822130290", 55)
local serverPlayersLabel = createSmallLabel("服务器人数：0", 80)

local function updateServerPlayers()
    while true do
        local count = #Players:GetPlayers()
        serverPlayersLabel.Text = "服务器人数：" .. tostring(count)
        task.wait(3)
    end
end

task.spawn(updateServerPlayers)

-- 主循环
while true do
    task.spawn(animateText)
    walkForwardStep()
    openBankAndSafeIfNeeded()
    if scanAndPickup() then
        hopServer() -- ✅ 成功拾取后立即换服
    else
        task.wait(3)
        hopServer()
    end
    task.wait(2)
end
