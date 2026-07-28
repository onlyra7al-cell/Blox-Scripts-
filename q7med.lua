if not game:IsLoaded() then game.Loaded:Wait() end

local S = {
    Players = game:GetService("Players"), WS = game:GetService("Workspace"),
    RS = game:GetService("ReplicatedStorage"), UIS = game:GetService("UserInputService"),
    Run = game:GetService("RunService"), VU = game:GetService("VirtualUser"),
    Tween = game:GetService("TweenService"), Http = game:GetService("HttpService"),
    Teleport = game:GetService("TeleportService"), Debris = game:GetService("Debris"),
    SG = game:GetService("StarterGui"), CoreGui = game:GetService("CoreGui"),
    Lighting = game:GetService("Lighting"), Teams = game:GetService("Teams"),
    Market = game:GetService("MarketplaceService")
}
local LP = S.Players.LocalPlayer
local Camera = S.WS.CurrentCamera
local LPname = LP.Name

local function Char() return LP.Character end
local function HRP() local c=Char() return c and c:FindFirstChild("HumanoidRootPart") end
local function Hum() local c=Char() return c and c:FindFirstChild("Humanoid") end
local function IsAlive() local h=Hum() return h and h.Health>0 end
local function Rnd(a,b) return a+math.random()*(b-a) end
local function RndI(a,b) return math.random(a,b) end
local KillCount = 0; local TotalXP = 0
local Boat; local RaidActive = false
local LastRealPos; local RubberbandCount = 0
local HooksIntact = true

local PlayerLevel = 1
local function UpdateLevel() FindLevel() end

-- === CONFIG ===
local C = {
    Farm = {Enabled=false, Mode="Melee", QuestMode="Auto", Target="Nearest",
            Bring=true, BringAll=true, Hitbox=20, SafeY=12, FastAtk=true, AtkSpd=0.008,
            AutoStore=false, AutoRaid=false, AutoBoss=false, AutoMastery=false, AutoCollectMats=false},
    Combat = {UseMelee=true, UseSword=true, UseGun=true, UseFruit=true, SkillMode="Spam",
              OneShot=false, ClickDly=8, SkillDly=25, RealDmg=true, DistanceCheck=true},
    Move = {Spd=180, SpdOn=false, JumpP=75, InfJump=false, AntiFall=true, Fly=false,
            Bypass=true, Jitter=3, VelMode=false, AdaptiveAtk=true},
    Player = {AutoStat=false, StatMode="Melee", AutoHaki=false, AutoObs=false, AutoKen=false,
              AutoBuso=false},
    ESP = {On=false, Mobs=true, Players=true, Chests=true, Fruits=true, Islands=true, Colors=true, ShowKills=true},
    Misc = {AntiAFK=true, Gacha=false, Collect=true, AntiBan=true, AntiAdmin=true,
            SeaTravel=false, HopWhenAdmin=true, WhiteScreen=false, CloudRemotes=true,
            BruteForce=false, HookCheck=true, RubberDetect=true},
    Spy = false,
    Manual = {}
}

-- === MULTI-PATH FINDER (Stats/Mobs everywhere) ===
local function FindLevel()
    local paths = {"Stats","leaderstats","Data","PlayerData","StatsFolder","LevelSystem"}
    for _,p in ipairs(paths) do
        local f = LP:FindFirstChild(p)
        if f then
            local lv = f:FindFirstChild("Level")
            if lv then PlayerLevel = lv.Value; return end
            for _,c in pairs(f:GetChildren()) do
                if c.Name:find("Level") or c.Name:find("Lvl") then PlayerLevel = c.Value; return end
            end
        end
    end
end

-- === MANUAL REMOTE OVERRIDE ===
local function SetManualRemote(cat, name)
    if not cat or not name then return end
    local obj = S.RS:FindFirstChild(name, true)
    if obj and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
        if not Remotes[cat] then Remotes[cat] = {} end
        table.insert(Remotes[cat], obj)
        print("[QF] Manual "..cat.." -> "..obj:GetFullName())
        return true
    end
    -- Try searching all services
    for _,sv in pairs({S.RS, LP:FindFirstChild("PlayerGui"), S.WS}) do
        obj = sv:FindFirstChild(name, true)
        if obj and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            if not Remotes[cat] then Remotes[cat] = {} end
            table.insert(Remotes[cat], obj)
            print("[QF] Manual "..cat.." -> "..obj:GetFullName())
            return true end end
    warn("[QF] Remote not found: "..name)
    return false
end

-- === BRUTE FORCE REMOTE FINDER ===
local function BruteForceRemotes()
    if not C.Misc.BruteForce then return end
    print("[QF] Brute force scanning all remotes...")
    if #Remotes.All == 0 then
        -- Rescan if nothing found
        ScanRemotes()
    end
    -- Assign ALL remotes to every category as fallback
    for _,r in ipairs(Remotes.All) do
        for _,cat in ipairs({"Combat","Quest","Gacha","Skill","Stats","Haki","Teleport"}) do
            if not Remotes[cat] then Remotes[cat] = {} end
            table.insert(Remotes[cat], r)
        end
    end
    print("[QF] Brute force: "..#Remotes.All.." remotes assigned to all categories")
end

-- === FALLBACK GUI (Instance.new, no HTTP needed) ===
local FallbackGUI
local function BuildFallbackGUI()
    if Fluent then return end
    print("[QF] Building fallback GUI (no HTTP)")
    local sc = Instance.new("ScreenGui")
    sc.Name = "QuantumForgeGUI"; sc.ResetOnSpawn = false
    sc.Parent = S.CoreGui

    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 400, 0, 500); f.Position = UDim2.new(0.5, -200, 0.5, -250)
    f.BackgroundColor3 = Color3.new(0.05,0.05,0.05); f.BorderSizePixel = 0
    f.Active = true; f.Draggable = true; f.Parent = sc

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30); title.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
    title.Text = "Quantum Forge+"; title.TextColor3 = Color3.new(0,1,0.5)
    title.Font = Enum.Font.SourceSansBold; title.TextSize = 18; title.Parent = f

    local y = 40
    local function AddToggle(lbl, key, tbl)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1,-10,0,25); b.Position = UDim2.new(0,5,0,y)
        b.BackgroundColor3 = tbl[key] and Color3.new(0,0.5,0) or Color3.new(0.2,0.2,0.2)
        b.Text = lbl..": "..tostring(tbl[key])
        b.TextColor3 = Color3.new(1,1,1); b.BorderSizePixel = 0
        b.Parent = f
        b.MouseButton1Click:Connect(function()
            tbl[key] = not tbl[key]
            b.BackgroundColor3 = tbl[key] and Color3.new(0,0.5,0) or Color3.new(0.2,0.2,0.2)
            b.Text = lbl..": "..tostring(tbl[key]) end)
        y = y + 28
    end
    local function AddLabel(txt)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1,-10,0,20); l.Position = UDim2.new(0,5,0,y)
        l.BackgroundTransparency = 1; l.Text = txt
        l.TextColor3 = Color3.new(0.7,0.7,0.7); l.TextSize = 12; l.Parent = f
        y = y + 22
    end

    AddLabel("=== AUTO FARM ===")
    AddToggle("Auto Farm", "Enabled", C.Farm)
    AddToggle("Bring Mobs", "Bring", C.Farm)
    AddToggle("Fast Attack", "FastAtk", C.Farm)
    AddToggle("Auto Store", "AutoStore", C.Farm)
    AddToggle("Auto Boss", "AutoBoss", C.Farm)
    AddLabel("=== COMBAT ===")
    AddToggle("One Shot", "OneShot", C.Combat)
    AddToggle("Real Dmg", "RealDmg", C.Combat)
    AddLabel("=== MOVEMENT ===")
    AddToggle("Walk Speed", "SpdOn", C.Move)
    AddToggle("Infinite Jump", "InfJump", C.Move)
    AddToggle("Anti Fall", "AntiFall", C.Move)
    AddToggle("Bypass Tween", "Bypass", C.Move)
    AddToggle("Velocity Mode", "VelMode", C.Move)
    AddLabel("=== MISC ===")
    AddToggle("Anti AFK", "AntiAFK", C.Misc)
    AddToggle("Anti Admin", "AntiAdmin", C.Misc)
    AddToggle("Collect Fruits", "Collect", C.Misc)
    AddToggle("Gacha Roll", "Gacha", C.Misc)

    local remBtn = Instance.new("TextButton")
    remBtn.Size = UDim2.new(1,-10,0,25); remBtn.Position = UDim2.new(0,5,0,y)
    remBtn.BackgroundColor3 = Color3.new(0.2,0.2,0.5); remBtn.Text = "Print Remotes"
    remBtn.TextColor3 = Color3.new(1,1,1); remBtn.BorderSizePixel = 0; remBtn.Parent = f
    remBtn.MouseButton1Click:Connect(PrintRemotes)

    FallbackGUI = sc
end

-- === RUBBERBANDING DETECTOR ===
local function CheckRubberband()
    if not C.Misc.RubberDetect then return end
    local r = HRP()
    if not r then return end
    local pos = r.Position
    if LastRealPos then
        local dist = (pos - LastRealPos).Magnitude
        if dist > 500 then
            RubberbandCount = RubberbandCount + 1
            warn("[QF] Rubberband detected! Server rejected movement #"..RubberbandCount)
            if RubberbandCount > 5 then
                C.Move.Bypass = false
                C.Move.VelMode = false
                print("[QF] Movement bypass disabled due to rubberbanding")
            end
        else
            RubberbandCount = math.max(0, RubberbandCount - 1)
        end
    end
    LastRealPos = pos
end

-- === HOOK INTEGRITY CHECK ===
local function CheckHooks()
    if not C.Misc.HookCheck then return end
    local nc = debug.getmetatable(game).__namecall
    if not nc or nc == nil then
        warn("[QF] __namecall hook lost! Reinstalling...")
        InitHooks()
    end
end
local Remotes = {All={}}
local function ScanRemotes()
    Remotes = {All={}}
    local cats = {
        Quest={"quest","mission","story","npc","task","give"}, 
        Combat={"combat","attack","damage","melee","sword","gun","punch","hit","fight","click","swing","bullet"},
        Gacha={"gacha","roll","fruit","shop","purchase","buy","store","product","code"},
        Teleport={"teleport","tele","travel","sail","ship","boat","gate","sea","island"},
        Skill={"skill","ability","move","power","cast","spell","blast","ability"},
        Stats={"stat","point","levelup","upgrade","level"},
        Haki={"haki","ken","observation","armament","buso","aura","geppo","soru"},
        Event={"event","handler","main","core","manager"},
        Network={"network","sync","update","client","server","packet"},
        Char={"character","spawn","load","humanoid","player","animation"}
    }
    local seen = {}
    local function sc(f,d)
        if d>8 then return end
        for _,o in pairs(f:GetChildren()) do
            if seen[o] then continue end
            seen[o] = true
            if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
                table.insert(Remotes.All, o)
                local n = o.Name:lower()
                for c,ps in pairs(cats) do
                    for _,p in ipairs(ps) do
                        if n:find(p) then
                            if not Remotes[c] then Remotes[c] = {} end
                            table.insert(Remotes[c], o); break end end end end
            if o:IsA("Folder") or o:IsA("Configuration") or o:IsA("ScreenGui") then sc(o,d+1) end end end
    sc(S.RS,0)
end
ScanRemotes()

-- Cloud remote name loader (fallback + override)
local CloudNames = nil
local function LoadCloudRemotes()
    if not C.Misc.CloudRemotes then return end
    local urls = {
        "https://pastebin.com/raw/EXAMPLE1",
        "https://raw.githubusercontent.com/QuantumForge/remotes/main/bloxfruits.json"
    }
    for _,url in ipairs(urls) do
        local ok, data = pcall(function() return game:HttpGet(url) end)
        if ok and data then
            local parsed = pcall(function() return S.Http:JSONDecode(data) end)
            if parsed then
                CloudNames = parsed
                print("[QF] Cloud remotes loaded from "..url)
                return
            end
        end
    end
end
task.spawn(LoadCloudRemotes)

local function R(c) local l=Remotes[c]; if l and #l>0 then return l end end

local function PrintRemotes()
    print("=== REMOTE DUMP ===")
    for _,r in ipairs(Remotes.All) do
        local pts={}; local p=r; while p do table.insert(pts,1,p.Name); p=p.Parent end
        print("  "..table.concat(pts,".")) end
    for c,l in pairs(Remotes) do
        if c~="All" then for _,r in ipairs(l) do print("  ["..c.."] "..r.Name) end end end
end

local MobDB = {
    {Min=1,Max=10,Mobs={"Bandit","Monkey"},Loc="Jungle",Pos=Vector3.new(-1200,15,-500)},
    {Min=10,Max=30,Mobs={"Gorilla","Brawler"},Loc="Jungle",Pos=Vector3.new(-1200,15,-500)},
    {Min=30,Max=60,Mobs={"DesertBandit","Snake"},Loc="Desert",Pos=Vector3.new(1500,15,2000)},
    {Min=60,Max=100,Mobs={"SnowBandit","Yeti"},Loc="Snow",Pos=Vector3.new(2500,15,3000)},
    {Min=100,Max=150,Mobs={"Viking","Pirate"},Loc="Marine",Pos=Vector3.new(-2500,15,-3000)},
    {Min=150,Max=200,Mobs={"SkyBandit","SkyMonkey"},Loc="Sky",Pos=Vector3.new(-5000,500,-5000)},
    {Min=200,Max=300,Mobs={"Dragon","Samurai"},Loc="Kingdom",Pos=Vector3.new(5000,15,5000)},
    {Min=300,Max=500,Mobs={"SeaBeast","Fishman"},Loc="Fishman",Pos=Vector3.new(8000,15,8000)},
    {Min=500,Max=700,Mobs={"Wraith","Skeleton"},Loc="Haunted",Pos=Vector3.new(-8000,15,-8000)},
    {Min=700,Max=1000,Mobs={"Demon","Angel"},Loc="Hell",Pos=Vector3.new(12000,15,12000)},
    {Min=1000,Max=1500,Mobs={"GodGuardian","Titan"},Loc="Heaven",Pos=Vector3.new(-15000,500,-15000)},
    {Min=1500,Max=2000,Mobs={"VoidCreature","Cosmic"},Loc="Void",Pos=Vector3.new(20000,15,20000)},
    {Min=2000,Max=3000,Mobs={"Celestial","Ethereal"},Loc="Celestial",Pos=Vector3.new(-25000,15,-25000)},
    {Min=3000,Max=5000,Mobs={"Ancient","Primordial"},Loc="Ancient",Pos=Vector3.new(35000,15,35000)},
    {Min=5000,Max=99999,Mobs={"Universe","Multiverse"},Loc="End",Pos=Vector3.new(-50000,15,-50000)}
}
local BossDB = {"Boss","Lord","King","Chief","Dragon","SeaKing","Ghost","Soul","RipIndra","NPC"}

local function GetZone()
    UpdateLevel()
    for _,z in ipairs(MobDB) do if PlayerLevel>=z.Min and PlayerLevel<=z.Max then return z end end
    return MobDB[1]
end

-- === ADAPTIVE RATE LIMITER (Ping-based throttling) ===
local PingTracker = {count=0, last=0, avg=50}
local function UpdatePing()
    PingTracker.count = PingTracker.count + 1
    if PingTracker.count % 10 == 0 then
        local sp = game:GetService("Stats")
        if sp and sp.Network and sp.Network.ServerStatsItem then
            local ping = sp.Network.ServerStatsItem:GetValue()
            if ping and ping > 0 then
                PingTracker.avg = PingTracker.avg * 0.7 + ping * 0.3
            end
        end
    end
end
local function AdaptiveDelay(base)
    local ping = PingTracker.avg
    if ping > 200 then return base * 3
    elseif ping > 100 then return base * 2
    elseif ping > 50 then return base * 1.5
    end
    return base
end

-- === VELOCITY-BASED MOVEMENT (Physics Simulation bypass) ===
local function VelocityMove(targetPos, cb)
    local r = HRP(); local h = Hum()
    if not r or not h then if cb then task.spawn(cb) end return end
    if TweenLock then if cb then task.spawn(cb) end return end
    TweenLock = true
    local dist = (r.Position - targetPos).Magnitude
    if dist < 5 then TweenLock=false; if cb then task.spawn(cb) end return end
    local dir = (targetPos - r.Position).Unit
    local vel = C.Move.Spd or 180
    r.Velocity = dir * vel
    h.AutoRotate = true; h.PlatformStand = false
    local check; check = S.Run.Heartbeat:Connect(function()
        local r2 = HRP()
        if not r2 or not IsAlive() then
            TweenLock=false; check:Disconnect(); if cb then task.spawn(cb) end; return end
        local d = (r2.Position - targetPos).Magnitude
        if d < 5 then
            r2.Velocity = Vector3.new(0,0,0); r2.CFrame = CFrame.new(targetPos)
            TweenLock=false; check:Disconnect(); if cb then task.spawn(cb) end
        else
            local dir2 = (targetPos - r2.Position).Unit
            r2.Velocity = Vector3.Lerp(r2.Velocity, dir2 * vel, 0.3)
        end
    end)
end

-- === REMOTE LOG (frequency tracking, integrated into hook chain) ===
local RemoteLog = {}

-- === MOVEMENT: Bypass Tween with Waypoints ===
local TweenLock = false
local function BypassTween(targetCF, cb)
    if TweenLock then if cb then task.spawn(cb) end return end
    local r = HRP()
    if not r then if cb then task.spawn(cb) end return end
    TweenLock = true

    local startPos = r.Position
    local dist = (startPos-targetCF.Position).Magnitude
    if dist < 5 then TweenLock=false; if cb then task.spawn(cb) end return end

    local nwp = math.max(4, math.floor(dist/40))
    local wps = {}
    for i=1,nwp do
        local t = i/(nwp+1)
        local base = startPos:Lerp(targetCF.Position, t)
        local j = C.Move.Jitter or 3
        table.insert(wps, CFrame.new(base + Vector3.new(Rnd(-j,j), Rnd(-1,2), Rnd(-j,j))))
    end
    table.insert(wps, targetCF)

    local function go(idx)
        if not IsAlive() or not HRP() then TweenLock=false; if cb then task.spawn(cb) end return end
        if idx > #wps then TweenLock=false; if cb then task.spawn(cb) end return end
        local r2 = HRP()
        if not r2 then TweenLock=false; if cb then task.spawn(cb) end return end
        local d = (r2.Position-wps[idx].Position).Magnitude
        if d < 2 then go(idx+1); return end
        local dur = math.max(0.05, d/(C.Move.Spd or 160))
        local t = S.Tween:Create(r2, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame=wps[idx]})
        t.Completed:Connect(function()
            if IsAlive() and HRP() then task.wait(Rnd(0.005,0.02)); go(idx+1)
            else TweenLock=false; if cb then task.spawn(cb) end end end)
        t:Play()
    end
    go(1)
end

-- === MOB TARGETING: Map-wide ===
local Targets = {}
local function ScanMobs(mobNames, includeBosses)
    Targets = {}
    if not mobNames then return end
    local ns = type(mobNames)=="table" and mobNames or {mobNames}
    if includeBosses then for _,b in ipairs(BossDB) do table.insert(ns, b) end end
    for _,o in pairs(S.WS:GetDescendants()) do
        if o:IsA("Model") and o:FindFirstChild("HumanoidRootPart") and o:FindFirstChild("Humanoid") then
            for _,n in ipairs(ns) do
                if o.Name:find(n) then
                    local r=o.HumanoidRootPart; local h=o.Humanoid
                    if h.Health>0 then table.insert(Targets, {Obj=o, HRP=r, Hum=h}) end
                    break end end end end
    local mp = HRP() and HRP().Position or Vector3.new()
    table.sort(Targets, function(a,b) return (a.HRP.Position-mp).Magnitude < (b.HRP.Position-mp).Magnitude end)
end

local function BringAll(center, mobNames, includeBosses)
    if not C.Farm.Bring or not center then return end
    ScanMobs(mobNames, includeBosses)
    local rad = C.Farm.BringAll and 99999 or 300
    for _,e in ipairs(Targets) do
        local d = (e.HRP.Position-center.Position).Magnitude
        if d>4 and d<rad then
            pcall(function()
                if sethiddenproperty then
                    sethiddenproperty(e.HRP, "NetworkOwnership", Enum.NetworkOwnership.Owner)
                end
                e.HRP.Size = Vector3.new(C.Farm.Hitbox, C.Farm.Hitbox, C.Farm.Hitbox)
                e.HRP.CanCollide = false
                e.HRP.Transparency = 0.5
                e.HRP.Material = Enum.Material.Neon
                e.HRP.BrickColor = BrickColor.new("Really red")
                e.HRP.CFrame = center.CFrame * CFrame.new(Rnd(-3,3), -C.Farm.SafeY+Rnd(-2,2), Rnd(-3,3))
                e.HRP.Velocity = Vector3.new(0,0,0); e.HRP.RotVelocity = Vector3.new(0,0,0)
                if e.Hum then e.Hum.WalkSpeed=0; e.Hum.JumpPower=0; e.Hum.AutoRotate=false end
                e.Obj.PrimaryPart = e.HRP
            end)
        end
    end
end

-- === FAST ATTACK ENGINE ===
local AtkLock = false
local function FastAtk(remote, tgtPos, count)
    if AtkLock or not remote then return end
    AtkLock = true
    count = count or RndI(6,15)
    for i=1,count do
        if not IsAlive() or not HRP() then break end
        pcall(function()
            remote:FireServer(tgtPos)
            remote:FireServer("Attack", tgtPos)
            remote:FireServer(unpack({tgtPos, tick(), RndI(1,5)}))
        end)
        task.wait(C.Combat.ClickDly/1000)
    end
    AtkLock = false
end

local function UseSkills(target)
    local list = R("Skill")
    if not list then return end
    for i=1,math.min(6,#list) do
        pcall(function()
            list[i]:FireServer(i, target.HRP.Position)
            task.wait(0.015)
            list[i]:FireServer(i, target.HRP.Position, tick())
        end)
        task.wait(C.Combat.SkillDly/1000)
    end
end

-- === AUTO COLLECT ===
local function Collect()
    if not C.Misc.Collect then return end
    local me = HRP()
    if not me then return end
    for _,item in pairs(S.WS:GetChildren()) do
        if item:IsA("Tool") and (item.Name:find("Fruit") or item:FindFirstChild("FruitValue")) then
            local h = item:FindFirstChild("Handle") or item:FindFirstChildOfClass("BasePart") or item:FindFirstChildWhichIsA("BasePart")
            if h then
                firetouchinterest(me, h, 0); task.wait(0.008)
                firetouchinterest(me, h, 1)
                h.CFrame = me.CFrame * CFrame.new(0,-3,0)
            end
        end
    end
end

-- === AUTO STORE FRUITS ===
local function AutoStore()
    if not C.Farm.AutoStore then return end
    local bp = LP:FindFirstChild("Backpack")
    if not bp then return end
    for _,t in pairs(bp:GetChildren()) do
        if t:IsA("Tool") and (t.Name:find("Fruit") or t:FindFirstChild("FruitValue")) then
            local r = R("Gacha")
            if r then
                for _,rr in ipairs(r) do
                    pcall(function() rr:InvokeServer("Store", t) end)
                    pcall(function() rr:InvokeServer("StoreFruit", t) end)
                end
            end
        end
    end
end

-- === QUEST ENGINE ===
local QuestActive = false
local function AcceptQuest()
    if QuestActive or C.Farm.QuestMode~="Auto" then return end
    local zone = GetZone()
    if not zone then return end
    local me = HRP()
    if not me then return end

    local npc, npcHRP
    for _,v in pairs(S.WS:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if (v.HumanoidRootPart.Position-zone.Pos).Magnitude < 150 then
                npc=v; npcHRP=v.HumanoidRootPart; break end end end

    if npc and npcHRP then
        if (me.Position-npcHRP.Position).Magnitude > 15 then
            BypassTween(npcHRP.CFrame*CFrame.new(0,C.Farm.SafeY,0))
            return end
        local rmt = R("Quest")
        if rmt then
            for _,r in ipairs(rmt) do
                pcall(function()
                    r:FireServer(zone.Loc); task.wait(0.05)
                    r:FireServer(zone.Mobs[1]); task.wait(0.05)
                    r:FireServer("StartQuest", zone.Loc, zone.Mobs[1])
                end)
            end
        end
        if npc:FindFirstChild("ClickDetector") then
            pcall(function() fireclickdetector(npc.ClickDetector) end)
        end
        QuestActive = true
    else
        BypassTween(CFrame.new(zone.Pos+Vector3.new(0,C.Farm.SafeY,0)))
    end
end

-- === AUTO HAKI ===
local function AutoHaki()
    if not C.Player.AutoHaki then return end
    local list = R("Haki")
    if not list then return end
    for _,r in ipairs(list) do
        pcall(function()
            if C.Player.AutoBuso then r:InvokeServer("Buso") end
            if C.Player.AutoObs then r:InvokeServer("Observation") end
            if C.Player.AutoKen then r:InvokeServer("Ken") end
        end)
    end
end

-- === EQUIP ===
local function EquipTool(t)
    if not t then return end
    local c = Char()
    if not c then return end
    if not c:FindFirstChild(t.Name) and c:FindFirstChild("Humanoid") then c.Humanoid:EquipTool(t) end
end

local function EquipBest(mode)
    local c = Char(); if not c then return end
    local bp = LP:FindFirstChild("Backpack"); if not bp then return end
    local pri
    if mode=="Melee" then pri={"Melee","Combat","Blackbeard","DarkStep","Electro","Water","DragonTalon","Superhuman","DeathStep","Sharkman","ElectricClaw","DragonBreath"}
    elseif mode=="Sword" then pri={"Sword","Katana","Saber","Cutlass","Blade","Dual","Rengoku","Yama","Spikey","Buddy","Canvander","Dark","True"}
    elseif mode=="Gun" then pri={"Gun","Pistol","Musket","Shotgun","Refined","Venom","Serpent","Acidum","Soul","Bizarre"}
    elseif mode=="Fruit" then pri={"Fruit","Blox","Mera","Magma","Flame","Ice","Dark","Dragon","Venom","Soul","Dough","Leopard"} end
    if not pri then return end
    for _,n in ipairs(pri) do
        local t=bp:FindFirstChild(n)
        if not t then for _,o in pairs(bp:GetChildren()) do if o:IsA("Tool") and o.Name:find(n) then t=o end end end
        if t then EquipTool(t); return t end end
    local f=bp:FindFirstChildOfClass("Tool"); if f then EquipTool(f) end; return f
end

-- === AUTO STAT ===
local function AutoStat()
    if not C.Player.AutoStat then return end
    local s = LP:FindFirstChild("Stats"); if not s then return end
    local p = s:FindFirstChild("Points"); if not p or p.Value<1 then return end
    local map = {Melee="Strength", Defense="Defense", Sword="Sword", Gun="Gun", Fruit="BloxFruit"}
    local t = map[C.Player.StatMode]; if not t then return end
    local r = R("Stats")
    if r then for _,rr in ipairs(r) do pcall(function() rr:InvokeServer("AddPoint",t,p.Value) end) end end
end

-- === AUTO COLLECT MATERIALS (Bones, Fragments, etc) ===
local function CollectMats()
    if not C.Farm.AutoCollectMats then return end
    local me = HRP()
    if not me then return end
    local matNames = {"Bone", "Fragment", "Chest", "Gem", "Key", "Piece", "Essence", "Core", "Coin", "Token", "Drop"}
    for _,o in pairs(S.WS:GetDescendants()) do
        if o:IsA("Tool") or (o:IsA("BasePart") and o:FindFirstChild("TouchInterest")) then
            for _,n in ipairs(matNames) do
                if o.Name:find(n) then
                    local touch = o:IsA("Tool") and (o:FindFirstChild("Handle") or o:FindFirstChildOfClass("BasePart")) or o
                    if touch then
                        pcall(function()
                            local dist = (me.Position-touch.Position).Magnitude
                            if dist<50 then
                                firetouchinterest(me, touch, 0); task.wait(0.005)
                                firetouchinterest(me, touch, 1)
                                touch.CFrame = me.CFrame * CFrame.new(0,-2,0)
                            end
                        end)
                    end
                    break
                end
            end
        end
    end
end

-- === KILL TRACKER ===
local function TrackKills()
    for _,t in ipairs(Targets) do
        if t.Hum and t.Hum.Health<=0 then
            KillCount = KillCount + 1
            local xp = t.Hum:FindFirstChild("Level") or t.Obj:FindFirstChild("Level")
            if xp and xp:IsA("NumberValue") then TotalXP = TotalXP + xp.Value end
        end
    end
end

-- === SEA TRAVEL ===
local function SeaTravelFunc()
    if not C.Misc.SeaTravel then return end
    local me = HRP()
    if not me then return end
    local zone = GetZone()
    if not zone then return end
    -- Find nearest boat
    local boat, seat
    for _,o in pairs(S.WS:GetChildren()) do
        if o:IsA("Model") and (o.Name:find("Boat") or o.Name:find("Ship") or o:FindFirstChild("VehicleSeat")) then
            local vs = o:FindFirstChild("VehicleSeat") or o:FindFirstChildWhichIsA("VehicleSeat")
            if vs then boat=o; seat=vs; break end
        end
    end
    if boat and seat then
        local dist = (me.Position-boat:GetPrimaryPartCFrame().Position).Magnitude
        if dist>30 then
            BypassTween(boat:GetPrimaryPartCFrame() * CFrame.new(0,5,-10))
            return
        end
        -- Sit in boat
        if seat and not seat:FindFirstChild("Occupant") then
            seat:FireServer(me.Position)
            task.wait(0.5)
        end
        -- Set throttle toward next island
        local nextZone
        for i,z in ipairs(MobDB) do
            if z==zone and i<#MobDB then nextZone=MobDB[i+1]; break end
        end
        if nextZone then
            local dir = (nextZone.Pos - me.Position).Unit
            local throttle = Instance.new("NumberValue")
            throttle.Value = 1
            -- Fire boat remote if exists
            local boatR = R("Teleport")
            if boatR then
                for _,r in ipairs(boatR) do
                    pcall(function()
                        r:FireServer(boat, nextZone.Pos)
                        r:FireServer("Sail", nextZone.Pos)
                    end)
                end
            end
        end
    end
end

-- === RAID (Basic) ===
local function RaidFunc()
    if not C.Farm.AutoRaid then return end
    if RaidActive then return end
    local zone = GetZone()
    if not zone then return end
    -- Try to find raid NPC or entrance
    for _,o in pairs(S.WS:GetDescendants()) do
        if o:IsA("Part") and (o.Name:find("Raid") or o.Name:find("Teleport") or o.Name:find("Portal")) then
            local me = HRP()
            if me then
                local d = (me.Position-o.Position).Magnitude
                if d>15 then BypassTween(o.CFrame * CFrame.new(0,5,0)); return end
                -- Activate raid
                local rmt = R("Event")
                if rmt then
                    for _,r in ipairs(rmt) do
                        pcall(function() r:FireServer("StartRaid") end)
                        pcall(function() r:FireServer("EnterRaid") end)
                    end
                end
                if o:FindFirstChild("ClickDetector") then fireclickdetector(o.ClickDetector) end
                RaidActive = true
            end
            break
        end
    end
end

-- === ESP PRO ===
local function ESPApply(obj, color, label)
    if not C.ESP.On or obj:FindFirstChild("__ESP") then return end
    local b = Instance.new("BoxHandleAdornment")
    b.Name="__ESP"; b.Size=obj:GetExtentsSize()*1.3; b.Color3=color or Color3.new(0,1,0)
    b.AlwaysOnTop=true; b.Adornee=obj; b.Parent=obj
    local hl = Instance.new("Highlight")
    hl.Name="__ESP_G"; hl.Adornee=obj; hl.FillColor=color or Color3.new(0,1,0)
    hl.FillTransparency=0.55; hl.OutlineTransparency=0.15; hl.Parent=obj
    if label and obj:FindFirstChild("HumanoidRootPart") then
        for _,n in pairs(obj:GetChildren()) do if n.Name=="__ESP_L" then n:Destroy() end end
        local bg = Instance.new("BillboardGui")
        bg.Name="__ESP_L"; bg.Size=UDim2.new(0,250,0,60); bg.Adornee=obj.HumanoidRootPart
        bg.AlwaysOnTop=true; bg.StudsOffset=Vector3.new(0,4,0)
        local tx = Instance.new("TextLabel")
        tx.Size=UDim2.new(1,0,1,0); tx.BackgroundTransparency=1; tx.TextColor3=Color3.new(1,1,1)
        tx.TextStrokeTransparency=0; tx.TextStrokeColor3=Color3.new(0,0,0)
        tx.Text = label or obj.Name; tx.TextScaled=true
        tx.Parent = bg; bg.Parent = obj
        if obj:FindFirstChild("Humanoid") then
            task.spawn(function()
                while bg and obj and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") do
                    local h = obj.Humanoid
                    local d = HRP() and math.floor((HRP().Position-obj.HumanoidRootPart.Position).Magnitude) or 0
                    local kills = C.ESP.ShowKills and (" | Kills: "..KillCount) or ""
                    tx.Text = obj.Name.."\nHP: "..math.floor(h.Health).."/"..math.floor(h.MaxHealth).." | "..d.."m"..kills
                    task.wait(0.3)
                end
            end)
        end
    end
end

local function ESPClear()
    for _,o in pairs(S.WS:GetDescendants()) do
        local b=o:FindFirstChild("__ESP"); if b then b:Destroy() end
        local g=o:FindFirstChild("__ESP_G"); if g then g:Destroy() end
        local l=o:FindFirstChild("__ESP_L"); if l then l:Destroy() end end
    for _,p in pairs(S.Players:GetPlayers()) do
        if p.Character then
            local b=p.Character:FindFirstChild("__ESP"); if b then b:Destroy() end
            local g=p.Character:FindFirstChild("__ESP_G"); if g then g:Destroy() end
            local l=p.Character:FindFirstChild("__ESP_L"); if l then l:Destroy() end end end
end

-- === ANTI ADMIN / SERVER HOP ===
local function HopServer()
    pcall(function()
        local ep = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        local raw = game:HttpGet(ep)
        local data = S.Http:JSONDecode(raw)
        if data and data.data and #data.data>0 then
            local servers = data.data
            local chosen = servers[RndI(1,#servers)]
            if chosen and chosen.id then
                S.Teleport:TeleportToPlaceInstance(game.PlaceId, chosen.id)
            end
        end
    end)
end

S.Players.PlayerAdded:Connect(function(player)
    if not C.Misc.AntiAdmin then return end
    local name = player.Name:lower()
    if name:find("admin") or name:find("mod") or name:find("owner") then
        if C.Misc.HopWhenAdmin then
            warn("[QF] Admin detected: "..player.Name..". Hopping...")
            HopServer()
        end
    end
end)

-- === UNIFIED HOOK SYSTEM (Spy + OneShot + __index Spoof) ===
local function InitHooks()
    local chain_nc = {}
    local orig_nc

    -- Remote Spy + Learning
    if C.Spy then
        table.insert(chain_nc, function(next, self, ...)
            local m = getnamecallmethod()
            if m=="FireServer" or m=="InvokeServer" then
                local pts={}; local o=self
                while o do table.insert(pts,1,o.Name); o=o.Parent end
                local path = table.concat(pts,".")
                RemoteLog[path] = (RemoteLog[path] or 0) + 1
                local a={...}; local s=""
                for i=1,math.min(6,#a) do local v=a[i]
                    if type(v)=="string" then s=s..v..", "
                    elseif type(v)=="number" then s=s..string.format("%.1f",v)..", "
                    elseif type(v)=="Vector3" then s=s..string.format("V3(%.0f,%.0f,%.0f)",v.X,v.Y,v.Z)..", "
                    else s=s..type(v)..", " end end
                if RemoteLog[path] <= 3 or RemoteLog[path] % 50 == 0 then
                    print("[Spy]["..RemoteLog[path].."] "..m.." | "..path.." | "..s) end end
            return next(self,...) end)
    end

    -- OneShot with Realistic Damage
    if C.Combat.OneShot then
        table.insert(chain_nc, function(next, self, ...)
            local m = getnamecallmethod()
            if m=="FireServer" or m=="InvokeServer" then
                local a={...}; local n=tostring(self):lower()
                if n:find("damage") or n:find("combat") or n:find("hit") then
                    for i,v in pairs(a) do
                        if type(v)=="number" then
                            a[i] = C.Combat.RealDmg and math.min(PlayerLevel*50, math.max(v*3, v+PlayerLevel*10)) or 9e9
                        end end
                    return next(self, unpack(a)) end end
            return next(self, ...) end)
    end

    -- Install __namecall chain
    if #chain_nc>0 then
        orig_nc = hookmetamethod(game, "__namecall", function(self, ...)
            local i=0; local function cn(s,...) i=i+1; if chain_nc[i] then return chain_nc[i](cn,s,...) end return orig_nc(s,...) end
            return cn(self,...) end)
    end

    -- __index spoof (merged: humanoid + position)
    local oldIdx
    oldIdx = hookmetamethod(game, "__index", function(self, idx)
        if self:IsA("Humanoid") and self.Parent and self.Parent==Char() then
            if idx=="WalkSpeed" and C.Move.SpdOn then return 16 end
            if idx=="JumpPower" then return 50 end end
        if self:IsA("BasePart") and self.Parent and self.Parent==Char() then
            if idx=="Velocity" then return Vector3.new(0,0,0) end end
        if self==HRP() and not TweenLock and C.Move.Bypass then
            if idx=="Position" and C.Farm.Enabled then
                -- Don't spoof during farming so distance checks work
            elseif idx=="Position" then return Vector3.new(0,50,0) end
            if idx=="CFrame" and not C.Farm.Enabled then return CFrame.new(0,50,0) end end
        return oldIdx(self, idx) end)

    -- __newindex spoof (block speed/gravity writes)
    local oldNewIdx
    oldNewIdx = hookmetamethod(game, "__newindex", function(self, idx, val)
        if self:IsA("Humanoid") and self.Parent and self.Parent==Char() then
            if idx=="WalkSpeed" and C.Move.SpdOn then return end
            if idx=="JumpPower" then return end end
        return oldNewIdx(self, idx, val) end)
end

-- === GUI ===
local Fluent
local function LoadGUI()
    local ok, F = pcall(function()
        return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/Fluent.lua"))()
    end)
    if not ok or not F then warn("[QF] Headless mode"); return end
    Fluent = F
    local Win = Fluent:CreateWindow({
        Title="Quantum Forge+ • "..LPname, SubTitle="Blox Fruits | Premium",
        TabWidth=160, Size=UDim2.fromOffset(580,460), Acrylic=true, Theme="Darker"})
    local T = {}
    for _,n in ipairs({"Farm","Combat","Move","Player","ESP","Misc","Remotes","Stats"}) do
        T[n] = Win:AddTab({Title=n, Icon="sword"}) end

    local function mk(tab,sec,cfg,items)
        tab:AddSection(sec)
        for _,it in ipairs(items) do
            if it.t=="tog" then
                tab:AddToggle(it.k,{Title=it.ti,Default=cfg[it.key],Callback=function(v)cfg[it.key]=v end})
            elseif it.t=="drop" then
                tab:AddDropdown(it.k,{Title=it.ti,Values=it.vs,Default=cfg[it.key],Callback=function(v)cfg[it.key]=v end})
            elseif it.t=="sli" then
                tab:AddSlider(it.k,{Title=it.ti,Default=cfg[it.key],Min=it.mn or 0,Max=it.mx or 100,Rounding=it.r or 1,Callback=function(v)cfg[it.key]=v end}) end end end

    mk(T.Farm,"Auto Farm",C.Farm,{
        {k="f_on",t="tog",ti="Auto Farm",key="Enabled"},
        {k="f_mode",t="drop",ti="Mode",key="Mode",vs={"Melee","Sword","Gun","Fruit"}},
        {k="f_quest",t="drop",ti="Quests",key="QuestMode",vs={"Auto","None"}},
        {k="f_target",t="drop",ti="Target",key="Target",vs={"Nearest","Low HP","High HP"}},
        {k="f_bring",t="tog",ti="Bring Mobs",key="Bring"},
        {k="f_bringall",t="tog",ti="Bring All Map",key="BringAll"},
        {k="f_hitbox",t="sli",ti="Hitbox",key="Hitbox",mn=5,mx=60,r=5},
        {k="f_fast",t="tog",ti="Fast Attack",key="FastAtk"},
        {k="f_atkspd",t="sli",ti="Atk Speed",key="AtkSpd",mn=0.001,mx=0.5,r=0.001},
        {k="f_store",t="tog",ti="Auto Store Fruits",key="AutoStore"},
        {k="f_raid",t="tog",ti="Auto Raid",key="AutoRaid"},
        {k="f_boss",t="tog",ti="Auto Boss",key="AutoBoss"},
        {k="f_mast",t="tog",ti="Auto Mastery",key="AutoMastery"},
        {k="f_mats",t="tog",ti="Collect Materials",key="AutoCollectMats"}})

    mk(T.Combat,"Combat",C.Combat,{
        {k="c_melee",t="tog",ti="Melee",key="UseMelee"},
        {k="c_sword",t="tog",ti="Sword",key="UseSword"},
        {k="c_gun",t="tog",ti="Gun",key="UseGun"},
        {k="c_fruit",t="tog",ti="Fruit",key="UseFruit"},
        {k="c_one",t="tog",ti="One Shot",key="OneShot"},
        {k="c_real",t="tog",ti="Realistic Dmg",key="RealDmg"},
        {k="c_dist",t="tog",ti="Distance Check",key="DistanceCheck"},
        {k="c_skill",t="drop",ti="Skill Mode",key="SkillMode",vs={"Spam","Smart","Combo"}},
        {k="c_click",t="sli",ti="Click ms",key="ClickDly",mn=1,mx=100,r=1},
        {k="c_skilld",t="sli",ti="Skill ms",key="SkillDly",mn=5,mx=300,r=5}})

    mk(T.Move,"Movement",C.Move,{
        {k="m_spd",t="tog",ti="WalkSpeed",key="SpdOn"},
        {k="m_spdv",t="sli",ti="Speed",key="Spd",mn=16,mx=350,r=5},
        {k="m_jump",t="tog",ti="Infinite Jump",key="InfJump"},
        {k="m_jp",t="sli",ti="Jump Power",key="JumpP",mn=30,mx=250,r=10},
        {k="m_fall",t="tog",ti="Anti Fall",key="AntiFall"},
        {k="m_bypass",t="tog",ti="Bypass Tween",key="Bypass"},
        {k="m_jit",t="sli",ti="Jitter",key="Jitter",mn=0,mx=15,r=1},
        {k="m_vel",t="tog",ti="Velocity Mode (Physics)",key="VelMode"},
        {k="m_adp",t="tog",ti="Adaptive Attack Speed",key="AdaptiveAtk"}})

    mk(T.Player,"Player",C.Player,{
        {k="p_stat",t="tog",ti="Auto Stats",key="AutoStat"},
        {k="p_statm",t="drop",ti="Priority",key="StatMode",vs={"Melee","Defense","Sword","Gun","Fruit"}},
        {k="p_haki",t="tog",ti="Auto Haki",key="AutoHaki"},
        {k="p_buso",t="tog",ti="Auto Buso",key="AutoBuso"},
        {k="p_obs",t="tog",ti="Auto Observation",key="AutoObs"},
        {k="p_ken",t="tog",ti="Auto Ken",key="AutoKen"}})

    mk(T.ESP,"ESP",C.ESP,{
        {k="e_on",t="tog",ti="Enable",key="On"},
        {k="e_mobs",t="tog",ti="Mobs",key="Mobs"},
        {k="e_players",t="tog",ti="Players",key="Players"},
        {k="e_chests",t="tog",ti="Chests",key="Chests"},
        {k="e_fruits",t="tog",ti="Fruits",key="Fruits"},
        {k="e_colors",t="tog",ti="Colors",key="Colors"},
        {k="e_kills",t="tog",ti="Show Kills",key="ShowKills"}})

    mk(T.Misc,"Misc",C.Misc,{
        {k="x_afk",t="tog",ti="Anti AFK",key="AntiAFK"},
        {k="x_gacha",t="tog",ti="Gacha Roll",key="Gacha"},
        {k="x_collect",t="tog",ti="Collect Fruits",key="Collect"},
        {k="x_aadmin",t="tog",ti="Anti Admin",key="AntiAdmin"},
        {k="x_hop",t="tog",ti="Hop on Admin",key="HopWhenAdmin"},
        {k="x_se",t="tog",ti="Sea Travel",key="SeaTravel"},
        {k="x_cloud",t="tog",ti="Cloud Remotes",key="CloudRemotes"},
        {k="x_brute",t="tog",ti="Brute Force Remotes",key="BruteForce"},
        {k="x_hook",t="tog",ti="Hook Integrity Check",key="HookCheck"},
        {k="x_rubber",t="tog",ti="Rubberband Detect",key="RubberDetect"},
        {k="x_ban",t="tog",ti="Anti Ban",key="AntiBan"}})

    T.Misc:AddButton({Title="Print Remotes", Description="Dump to F9", Callback=PrintRemotes})
    T.Misc:AddButton({Title="Server Hop", Description="Hop to another server", Callback=HopServer})
    T.Misc:AddButton({Title="Clear ESP", Description="Remove all ESP objects", Callback=ESPClear})

    T.Remotes:AddToggle("rspy",{Title="Remote Spy + Learning",Description="Log + record remotes for analysis",Default=false,
        Callback=function(v)C.Spy=v;Fluent:Notify({Title="Spy",Content="Restart to apply",Duration=3})end})
    T.Remotes:AddButton({Title="Rescan Remotes",Callback=function()ScanRemotes();PrintRemotes();Fluent:Notify({Title="Remotes",Content="Done",Duration=2})end})
    T.Remotes:AddParagraph("ri",{Title="Info",Content="See console (F9) for remote dump"})

    local SL = T.Stats:AddParagraph("live",{Title="Stats",Content="Loading..."})
    task.spawn(function()
        while task.wait(2.5) do
            UpdateLevel()
            local st=LP:FindFirstChild("Stats") or LP:FindFirstChild("leaderstats")
            local inf="Level: "..PlayerLevel
            if st then for _,c in pairs(st:GetChildren()) do
                if (c:IsA("NumberValue") or c:IsA("IntValue")) and c.Name~="Level" then inf=inf.."\n"..c.Name..": "..tostring(c.Value) end end end
            local p=st and st:FindFirstChild("Points"); if p then inf=inf.."\nPoints: "..p.Value end
            local b=LP:FindFirstChild("Data") and LP.Data:FindFirstChild("Beli"); if b then inf=inf.."\nBeli: "..b.Value end
            inf=inf.."\n\n[Session]\nKills: "..KillCount.."\nXP Gained: "..TotalXP
            SL:Set(inf)
        end end)
    Fluent:Notify({Title="Quantum Forge+",Content="Premium loaded. F9 for remotes.",Duration=4})
end

-- === RUBBERBAND + HOOK CHECK LOOPS ===
task.spawn(function() while task.wait(2) do CheckRubberband(); CheckHooks() end end)

-- === BACKGROUND LOOPS ===
if C.Misc.AntiAFK then
    LP.Idled:Connect(function()
        S.VU:Button2Down(Vector2.new(0,0),Camera.CFrame); task.wait(1)
        S.VU:Button2Up(Vector2.new(0,0),Camera.CFrame) end)
end

S.UIS.JumpRequest:Connect(function()
    if C.Move.InfJump then local r=HRP(); if r then r.Velocity=Vector3.new(r.Velocity.X,C.Move.JumpP,r.Velocity.Z) end end end)

task.spawn(function() while task.wait(0.2) do
    if C.Move.AntiFall and IsAlive() then local r=HRP(); if r and r.Position.Y<-80 then r.CFrame=CFrame.new(r.Position.X,80,r.Position.Z) end end end end)

task.spawn(function() while task.wait(0.08) do
    if C.Move.SpdOn and IsAlive() then local h=Hum(); if h then h.WalkSpeed=C.Move.Spd end end end end)

task.spawn(function() while task.wait(4) do if C.Player.AutoStat then AutoStat() end end end)

task.spawn(function() while task.wait(15) do if C.Player.AutoHaki then AutoHaki() end end end)

task.spawn(function() while task.wait(8) do if C.Misc.Gacha then local r=R("Gacha"); if r then for _,rr in ipairs(r) do pcall(function() rr:InvokeServer("Buy Fruit") end) end end end end end)

task.spawn(function() while task.wait(1) do
    if not C.ESP.On then ESPClear() end
    if C.ESP.On then
        for _,p in pairs(S.Players:GetPlayers()) do
            if p~=LP and p.Character then ESPApply(p.Character, C.ESP.Colors and Color3.new(1,0,0) or Color3.new(0,1,0), p.Name) end end
        for _,o in pairs(S.WS:GetDescendants()) do
            if o:IsA("Model") and o:FindFirstChild("Humanoid") and o.Humanoid.Health>0 then
                if C.ESP.Mobs then ESPApply(o, C.ESP.Colors and Color3.new(1,0.5,0) or Color3.new(0,1,0), o.Name) end end
            if C.ESP.Fruits and o:IsA("Tool") and o.Name:find("Fruit") then ESPApply(o, Color3.new(1,0,1)) end
            if C.ESP.Chests and o:IsA("BasePart") and o.Name:find("Chest") then ESPApply(o, Color3.new(1,1,0)) end end end end end)

-- === MAIN LOOP ===
local function FarmLoop()
    while task.wait(C.Farm.AtkSpd) do
        if not C.Farm.Enabled then task.wait(0.5) continue end
        if not IsAlive() then task.wait(3) continue end
        local me = HRP(); if not me then continue end
        local zone = GetZone(); if not zone then continue end

        Collect()
        CollectMats()
        if C.Farm.AutoStore then AutoStore() end
        if C.Farm.AutoRaid then RaidFunc() end
        if C.Misc.SeaTravel then SeaTravelFunc() end

        ScanMobs(zone.Mobs, C.Farm.AutoBoss)
        TrackKills()
        local combat = R("Combat")
        local cRemote = combat and combat[1]

        if #Targets==0 then
            QuestActive = false
            if C.Farm.QuestMode=="Auto" then AcceptQuest()
            elseif C.Move.Bypass then
                local d = (me.Position-zone.Pos).Magnitude
                if d>80 then BypassTween(CFrame.new(zone.Pos+Vector3.new(0,C.Farm.SafeY,0))) end end
        else
            local target = Targets[1]
            if C.Farm.Target=="Low HP" then
                for _,t in ipairs(Targets) do if t.Hum.Health<target.Hum.Health then target=t end end
            elseif C.Farm.Target=="High HP" then
                for _,t in ipairs(Targets) do if t.Hum.Health>target.Hum.Health then target=t end end end

            local d = (me.Position-target.HRP.Position).Magnitude

            if d>8 then
                local hov = target.HRP.CFrame * CFrame.new(Rnd(-3,3), C.Farm.SafeY+Rnd(-2,2), Rnd(-3,3))
                if C.Move.VelMode then VelocityMove(hov.Position)
                elseif C.Move.Bypass then BypassTween(hov)
                else if HRP() then HRP().CFrame=hov end end
            else
                me.Velocity = Vector3.new(0,0,0)
                if C.Farm.Bring then BringAll(me, zone.Mobs, C.Farm.AutoBoss) end

                -- Distance Prediction: verify target is actually near before attacking
                local distCheck = (me.Position-target.HRP.Position).Magnitude
                if C.Combat.DistanceCheck and distCheck>25 then
                    if C.Move.Bypass then BypassTween(target.HRP.CFrame*CFrame.new(0,C.Farm.SafeY,0)) end
                    continue
                end

                local tool = EquipBest(C.Farm.Mode)

                if C.Farm.FastAtk and cRemote then
                    local atkCount = RndI(8,20)
                    for atk=1,atkCount do
                        if not IsAlive() or not target.HRP or target.Hum.Health<=0 then break end
                        UpdatePing()
                        pcall(function()
                            cRemote:FireServer(target.HRP.Position)
                            cRemote:FireServer("Attack", target.HRP.Position)
                            cRemote:FireServer(target.HRP.Position, tick())
                            if tool then tool:Activate() end
                        end)
                        local delay = C.Move.AdaptiveAtk and AdaptiveDelay(C.Farm.AtkSpd) or C.Farm.AtkSpd
                        task.wait(delay)
                    end
                    UseSkills(target)
                else
                    if tool then tool:Activate() end
                    if cRemote then
                        pcall(function()
                            cRemote:FireServer(target.HRP.Position)
                            cRemote:FireServer("Attack", target.HRP.Position)
                        end)
                    end
                end

                if C.Misc.AntiBan then task.wait(Rnd(0.001,0.008)) end
            end
        end
    end
end

-- === INIT ===
local function Init()
    print("Initializing Quantum Forge+...")
    -- Multi-path level find
    FindLevel()
    -- Brute force remotes as fallback
    BruteForceRemotes()
    -- Install hooks
    InitHooks()
    -- Apply manual remote overrides
    for cat, name in pairs(C.Manual) do SetManualRemote(cat, name) end
    -- Start farm loop
    task.spawn(FarmLoop)
    -- Try GUI (Fluent first, fallback if fails)
    xpcall(LoadGUI, function(e)
        warn("[QF] Fluent GUI:", e)
        xpcall(BuildFallbackGUI, function(e2) warn("[QF] Fallback GUI:", e2) end)
    end)
    print("=== QUANTUM FORGE+ v2 ACTIVE ===")
    print("Hooks + Integrity | BruteForce | Multi-Path | Rubberband Detect | Fallback GUI")
    print("Fast Atk+Adaptive | Velocity Move | Sea Travel | Raid | Kill Track | Cloud Remotes")
    PrintRemotes()
end

Init()
