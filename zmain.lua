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

-- 示例逻辑（你可以在下面写入完整主脚本内容）
game.StarterGui:SetCore("SendNotification", {
    Title = "细猫脚本",
    Text = "白名单验证成功，正在加载主脚本！",
    Duration = 5
})
