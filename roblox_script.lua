--====================================================================
-- [MASTER ACADEMIC BUILD] ULTRA HIGH-PERFORMANCE SECURITY FRAMEWORK
-- Fully Synced with Anti-Admin Detection, Fruit Vacuum, One-Shot, and ESP.
-- Optimized for Long-Term Non-Detection within Certified Testing Environments.
--====================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- Obfuscation Header Emulation Array
local _0x7A9B = { [1] = 0x99, [2] = 0xFF }

local Services = {
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    VirtualUser = game:GetService("VirtualUser"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    TeleportService = game:GetService("TeleportService")
}

local LP = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

local Config = {
    AutoFarm = true,
    AutoQuest = true,
    Speed = 160,
    SafeYOffset = 12,
    HitboxExpansion = 15,
    BringMobs = true,
    InfiniteJump = true,
    JumpPower = 60,
    GachaSpam = true,
    OneShot = true,
    ShowESP = true
}

local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() and self:IsA("BasePart") and key == "CFrame" then
        if self.Name == "HumanoidRootPart" and self:IsDescendantOf(LP.Character) then
            return CFrame.new(self.Position.X, 9999, self.Position.Z)
        end
    end
    return oldIndex(self, key)
end)

local Remotes = {}
local function ScanRemotes()
    for _, obj in pairs(Services.ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("quest") then Remotes.Quest = obj
            elseif name:find("combat") or name:find("attack") or name:find("damage") then Remotes.Combat = obj
            elseif name:find("gacha") or name:find("roll") or name:find("fruit") then Remotes.Gacha = obj
            end
        end
    end
end
ScanRemotes()

local ZoneMap = {
    { MinLvl = 1, MaxLvl = 10, Mobs = {"Bandit", "Monkey"}, Loc = "Jungle", NPC = Vector3.new(-1200, 15, -500) },
    { MinLvl = 10, MaxLvl = 30, Mobs = {"Gorilla", "Brawler"}, Loc = "Jungle", NPC = Vector3.new(-1200, 15, -500) },
    { MinLvl = 30, MaxLvl = 60, Mobs = {"DesertBandit", "Snake"}, Loc = "Desert", NPC = Vector3.new(1500, 15, 2000) }
}

local function GetPlayerLevel()
    local stats = LP:FindFirstChild("Stats") or LP:FindFirstChild("leaderstats")
    if stats and stats:FindFirstChild("Level") then return stats.Level.Value end
    return 1
end

local function GetCurrentZone()
    local lvl = GetPlayerLevel()
    for _, z in pairs(ZoneMap) do
        if lvl >= z.MinLvl and lvl <= z.MaxLvl then return z end
    end
    return ZoneMap[1]
end

local isTweening = false
local function safeTweenToPosition(targetCFrame)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    if isTweening then return end

    isTweening = true
    local hrp = char.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local duration = distance / Config.Speed

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = Services.TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    tween:Play()

    tween.Completed:Connect(function()
        isTweening = false
    end)
    return tween
end

local TargetList = {}
local function refreshTargets(mobName)
    TargetList = {}
    if not mobName then return end
    for _, obj in pairs(Services.Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name:find(mobName) then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            local hum = obj:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                table.insert(TargetList, {Object = obj, HRP = hrp, Humanoid = hum})
            end
        end
    end
end

local hasQuest = false
local function TakeQuest()
    if not Config.AutoQuest or hasQuest or isTweening then return end
    local zone = GetCurrentZone()
    if not zone or not Remotes.Quest then return end

    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local dist = (zone.NPC - char.HumanoidRootPart.Position).Magnitude
    if dist > 25 then
        safeTweenToPosition(CFrame.new(zone.NPC + Vector3.new(0, Config.SafeYOffset, 0)))
        return
    end

    Remotes.Quest:FireServer("StartQuest", zone.Loc)
    hasQuest = true
end

local function secureBringAndExpandMobs(targetHRP, mobName)
    if not Config.BringMobs then return end
    refreshTargets(mobName)

    for _, enemy in pairs(TargetList) do
        enemy.HRP.Size = Vector3.new(Config.HitboxExpansion, Config.HitboxExpansion, Config.HitboxExpansion)
        enemy.HRP.CanCollide = false

        local dist = (enemy.HRP.Position - targetHRP.Position).Magnitude
        if dist > 5 and dist < 200 then
            enemy.HRP.CFrame = targetHRP.CFrame * CFrame.new(0, -Config.SafeYOffset, 0)
        end
    end
end

if Config.OneShot then
    local oldNC
    oldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        local args = {...}
        if m == "FireServer" or m == "InvokeServer" then
            local objName = tostring(self):lower()
            if objName:find("damage") or objName:find("combat") or objName:find("hit") then
                for i, arg in pairs(args) do
                    if type(arg) == "number" then args[i] = 9e9 end
                end
                return oldNC(self, unpack(args))
            end
        end
        return oldNC(self, ...)
    end)
end

local function applyESP(model)
    if not Config.ShowESP or model:FindFirstChild("ESPHits") then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESPHits"
    box.Size = model:GetExtentsSize()
    box.Color3 = Color3.fromRGB(0, 255, 0)
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Adornee = model
    box.Parent = model
end

Services.UserInputService.JumpRequest:Connect(function()
    if not Config.InfiniteJump then return end
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.Velocity = Vector3.new(char.HumanoidRootPart.Velocity.X, Config.JumpPower, char.HumanoidRootPart.Velocity.Z)
    end
end)

LP.Idled:Connect(function()
    Services.VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
    task.wait(1)
    Services.VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
end)

Services.Players.PlayerAdded:Connect(function(player)
    if player:GetRankInGroup(4356824) >= 200 or player.Name:lower():find("admin") then
        print("[🚨] Admin detected! Initiating emergency server transit protocol...")
        pcall(function()
            local endpoint = "https://roblox.com"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            local rawData = game:HttpGet(endpoint)
            local servers = Services.HttpService:JSONDecode(rawData)
            if servers and servers.data then
                Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, servers.data[math.random(1, #servers.data)].id)
            end
        end)
    end
end)

local function secureNetworkFire(remote, ...)
    task.wait(math.random(15, 45) / 1000)
    if remote then remote:FireServer(...) end
end

local function vacuumAllDroppedFruits()
    for _, item in ipairs(Services.Workspace:GetChildren()) do
        if item:IsA("Tool") and (item.Name:find("Fruit") or item:FindFirstChild("FruitValue")) then
            local handle = item:FindFirstChild("Handle") or item:FindFirstChildOfClass("BasePart")
            if handle and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                firetouchinterest(LP.Character.HumanoidRootPart, handle, 0)
                task.wait(0.05)
                firetouchinterest(LP.Character.HumanoidRootPart, handle, 1)
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(15)
        if Config.GachaSpam and Remotes.Gacha then
            pcall(function() Remotes.Gacha:InvokeServer("Buy Fruit") end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.05)

        if Config.AutoFarm then
            vacuumAllDroppedFruits()

            local char = LP.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                local zone = GetCurrentZone()
                refreshTargets(zone.Mobs[1])

                if #TargetList == 0 then
                    hasQuest = false
                    TakeQuest()
                else
                    local activeTarget = TargetList[1]
                    local safeHoverCFrame = activeTarget.HRP.CFrame * CFrame.new(0, Config.SafeYOffset, 0)

                    if not isTweening then
                        local travelTween = safeTweenToPosition(safeHoverCFrame)
                        if travelTween then travelTween.Completed:Wait() end
                    end

                    char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    applyESP(activeTarget.Object)
                    secureBringAndExpandMobs(char.HumanoidRootPart, zone.Mobs[1])

                    local tool = char:FindFirstChildOfClass("Tool") or LP.Backpack:FindFirstChildOfClass("Tool")
                    if tool then
                        if not char:FindFirstChild(tool.Name) then char.Humanoid:EquipTool(tool) end
                        tool:Activate()
                        if Remotes.Combat then
                            secureNetworkFire(Remotes.Combat, "Attack", activeTarget.HRP.Position)
                        end
                    end
                end
            end
        end
    end
end)

print("[+] Premium Vulnerability Framework Fully Initialized.")