--[[
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║          SURVIVE THE KILLER ULTIMATE SCRIPT V1.0                 ║
║          38+ Features | Rayfield UI | Professional               ║
║                                                                   ║
║  Game: Survive The Killer (Roblox)                               ║
║  Created: 2024                                                    ║
║  UI Library: Rayfield Premium                                    ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

FEATURES:
✅ 38+ Features
✅ 7 Tabs (Player, ESP, Environment, Automation, Teleport, Safety, Settings)
✅ Dynamic Map Detection
✅ Auto Farm Loot System
✅ Auto Escape with Timer Reading
✅ Auto Breakfree from Killer
✅ Complete ESP System
✅ Safety & Blacklist System
✅ Professional UI

WARNING: Use at your own risk!
]]

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--[[════════════════════════════════════════════════════════════════
    GLOBAL SETTINGS
════════════════════════════════════════════════════════════════]]

-- Player Settings
getgenv().SpeedEnabled = false
getgenv().SpeedValue = 16
getgenv().JumpEnabled = false
getgenv().JumpValue = 50
getgenv().InfiniteJumpEnabled = false
getgenv().NoclipEnabled = false
getgenv().AntiRagdollEnabled = false

-- ESP Settings
getgenv().ESPEnabled = false
getgenv().ESPLoot = false
getgenv().ESPExit = false
getgenv().ESPPlayers = false
getgenv().ESPKiller = false
getgenv().ESPVents = false
getgenv().ESPTeamCheck = true
getgenv().MaxESPDistance = 2000
getgenv().ShowTracers = false
getgenv().CrosshairEnabled = false

-- Environment Settings
getgenv().RemoveShadows = false
getgenv().RemoveFog = false
getgenv().Fullbright = false
getgenv().InvisibleMap = false

-- Automation Settings
getgenv().AutoFarmEnabled = false
getgenv().AutoEscapeEnabled = false
getgenv().AutoEscapeTimer = 30
getgenv().FarmDelay = 0.5
getgenv().AutoBreakfreeEnabled = false

-- Safety Settings
getgenv().Blacklist = {}
getgenv().DetectionDistance = 50
getgenv().AntiKillerEnabled = false
getgenv().SafeModeEnabled = false
getgenv().EmergencyTPEnabled = true

-- Colors
local TeamColor = Color3.fromRGB(0, 255, 0)
local EnemyColor = Color3.fromRGB(255, 0, 0)
local KillerColor = Color3.fromRGB(255, 0, 255)
local LootColor = Color3.fromRGB(255, 255, 0)
local ExitColor = Color3.fromRGB(0, 255, 255)
local VentColor = Color3.fromRGB(255, 165, 0)

--[[════════════════════════════════════════════════════════════════
    MAP DETECTION SYSTEM
════════════════════════════════════════════════════════════════]]

local knownMaps = {
    "SPACE_LAB", "BIGRED", "FACTORY", "HOSPITAL", "SCHOOL", 
    "MANSION", "PRISON", "CABIN", "MALL"
}

local function getCurrentMap()
    -- Method 1: Check known map names
    for _, mapName in pairs(knownMaps) do
        local map = workspace:FindFirstChild(mapName)
        if map and map:FindFirstChild("EXITS") then
            return map
        end
    end
    
    -- Method 2: Find any object with EXITS folder
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:FindFirstChild("EXITS") and obj:FindFirstChild("LOOTSPAWN") then
            return obj
        end
    end
    
    return nil
end

local function getMapName()
    local map = getCurrentMap()
    return map and map.Name or "Unknown"
end

--[[════════════════════════════════════════════════════════════════
    HELPER FUNCTIONS
════════════════════════════════════════════════════════════════]]

local function isBlacklisted(player)
    if not player then return false end
    local lowerName = string.lower(player.Name)
    for _, blk in ipairs(getgenv().Blacklist) do
        if string.find(lowerName, string.lower(blk), 1, true) then
            return true
        end
    end
    return false
end

local function isTeammate(player)
    if not LocalPlayer.Team then return false end
    if not player.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function getPlayerColor(player)
    if isBlacklisted(player) then
        return KillerColor
    elseif ESPTeamCheck and isTeammate(player) then
        return TeamColor
    else
        return EnemyColor
    end
end

local function findPlayerByPartial(text)
    local lower = string.lower(text)
    if lower == "" then return nil end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and string.find(string.lower(pl.Name), lower, 1, true) then
            if not isBlacklisted(pl) then
                return pl
            end
        end
    end
end

local function pickRandomPlayer()
    local list = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and not isBlacklisted(pl) then
            table.insert(list, pl)
        end
    end
    if #list > 0 then 
        return list[math.random(1, #list)] 
    end
end

local function safeTeleport(position)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = position
        return true
    end
    return false
end

--[[════════════════════════════════════════════════════════════════
    LOOT SYSTEM
════════════════════════════════════════════════════════════════]]

local function getAllLoot()
    local lootItems = {}
    
    -- Get COINS
    local coinsFolder = workspace:FindFirstChild("COINS")
    if coinsFolder then
        for _, coin in pairs(coinsFolder:GetChildren()) do
            if coin:IsA("BasePart") or coin:IsA("Model") then
                table.insert(lootItems, coin)
            end
        end
    end
    
    -- Get COLLECTABLES
    local collectablesFolder = workspace:FindFirstChild("COLLECTABLES")
    if collectablesFolder then
        for _, item in pairs(collectablesFolder:GetChildren()) do
            if item:IsA("BasePart") or item:IsA("Model") then
                table.insert(lootItems, item)
            end
        end
    end
    
    return lootItems
end

local function getNearestLoot()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local hrp = char.HumanoidRootPart
    local lootItems = getAllLoot()
    local nearest = nil
    local minDist = math.huge
    
    for _, loot in pairs(lootItems) do
        local lootPos = loot:IsA("Model") and loot:GetPivot().Position or loot.Position
        local dist = (hrp.Position - lootPos).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = loot
        end
    end
    
    return nearest
end

--[[════════════════════════════════════════════════════════════════
    EXIT SYSTEM
════════════════════════════════════════════════════════════════]]

local function getExitGateways()
    local currentMap = getCurrentMap()
    if not currentMap then return {} end
    
    local exitsFolder = currentMap:FindFirstChild("EXITS")
    if not exitsFolder then return {} end
    
    local exits = {}
    for _, exit in pairs(exitsFolder:GetChildren()) do
        if exit.Name == "EXITGATEWAY" then
            table.insert(exits, exit)
        end
    end
    
    return exits
end

local function getNearestExit()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local hrp = char.HumanoidRootPart
    local exits = getExitGateways()
    local nearest = nil
    local minDist = math.huge
    
    for _, exit in pairs(exits) do
        local exitEffect = exit:FindFirstChild("EXITEFFECT")
        local exitPos = exitEffect and exitEffect.Position or exit:GetPivot().Position
        local dist = (hrp.Position - exitPos).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = exit
        end
    end
    
    return nearest
end

--[[════════════════════════════════════════════════════════════════
    VENT SYSTEM
════════════════════════════════════════════════════════════════]]

local function getAllVents()
    local currentMap = getCurrentMap()
    if not currentMap then return {} end
    
    local wallsFolder = currentMap:FindFirstChild("WALLS")
    if not wallsFolder then return {} end
    
    local vents = {}
    for _, wall in pairs(wallsFolder:GetDescendants()) do
        if wall.Name == "TRIGGER" and wall:IsA("BasePart") then
            table.insert(vents, wall)
        end
    end
    
    return vents
end

local function getNearestVent()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local hrp = char.HumanoidRootPart
    local vents = getAllVents()
    local nearest = nil
    local minDist = math.huge
    
    for _, vent in pairs(vents) do
        local dist = (hrp.Position - vent.Position).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = vent
        end
    end
    
    return nearest
end

--[[════════════════════════════════════════════════════════════════
    TIMER SYSTEM
════════════════════════════════════════════════════════════════]]

local function getTimeRemaining()
    local timerUI = LocalPlayer.PlayerGui:FindFirstChild("TOPBAR")
    if not timerUI then return 999 end
    
    local roundTimer = timerUI:FindFirstChild("ROUNDTIMER")
    if not roundTimer then return 999 end
    
    local min1 = roundTimer:FindFirstChild("MINUTE1")
    local min2 = roundTimer:FindFirstChild("MINUTE2")
    local sec1 = roundTimer:FindFirstChild("SECOND1")
    local sec2 = roundTimer:FindFirstChild("SECOND2")
    
    if min1 and min2 and sec1 and sec2 then
        local minutes = tonumber(min1.Text .. min2.Text) or 0
        local seconds = tonumber(sec1.Text .. sec2.Text) or 0
        return (minutes * 60) + seconds
    end
    
    return 999
end

--[[════════════════════════════════════════════════════════════════
    ESP SYSTEM
════════════════════════════════════════════════════════════════]]

local ESPObjects = {
    Players = {},
    Loot = {},
    Exits = {},
    Vents = {}
}

-- Drawing Crosshair
local Crosshair = {
    Horizontal = Drawing.new("Line"),
    Vertical = Drawing.new("Line")
}

Crosshair.Horizontal.Thickness = 2
Crosshair.Horizontal.Color = Color3.fromRGB(255, 255, 255)
Crosshair.Horizontal.Transparency = 1
Crosshair.Vertical.Thickness = 2
Crosshair.Vertical.Color = Color3.fromRGB(255, 255, 255)
Crosshair.Vertical.Transparency = 1

local function updateCrosshair()
    if CrosshairEnabled then
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        Crosshair.Horizontal.From = Vector2.new(center.X - 10, center.Y)
        Crosshair.Horizontal.To = Vector2.new(center.X + 10, center.Y)
        Crosshair.Vertical.From = Vector2.new(center.X, center.Y - 10)
        Crosshair.Vertical.To = Vector2.new(center.X, center.Y + 10)
        Crosshair.Horizontal.Visible = true
        Crosshair.Vertical.Visible = true
    else
        Crosshair.Horizontal.Visible = false
        Crosshair.Vertical.Visible = false
    end
end

-- Player ESP
local function createPlayerESP(player)
    if player == LocalPlayer then return end
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Thickness = 2
    box.Transparency = 1
    box.Filled = false
    
    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Size = 15
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameTag.Font = 2
    
    local distanceTag = Drawing.new("Text")
    distanceTag.Visible = false
    distanceTag.Color = Color3.fromRGB(200, 200, 200)
    distanceTag.Size = 13
    distanceTag.Center = true
    distanceTag.Outline = true
    distanceTag.OutlineColor = Color3.fromRGB(0, 0, 0)
    distanceTag.Font = 2
    
    local healthBarBG = Drawing.new("Square")
    healthBarBG.Visible = false
    healthBarBG.Color = Color3.fromRGB(20, 20, 20)
    healthBarBG.Thickness = 1
    healthBarBG.Transparency = 0.8
    healthBarBG.Filled = true
    
    local healthBar = Drawing.new("Square")
    healthBar.Visible = false
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Thickness = 1
    healthBar.Transparency = 1
    healthBar.Filled = true
    
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Color3.fromRGB(255, 255, 255)
    tracer.Thickness = 1
    tracer.Transparency = 1
    
    ESPObjects.Players[player] = {
        Box = box,
        Name = nameTag,
        Distance = distanceTag,
        HealthBarBG = healthBarBG,
        HealthBar = healthBar,
        Tracer = tracer
    }
end

local function removePlayerESP(player)
    if ESPObjects.Players[player] then
        ESPObjects.Players[player].Box:Remove()
        ESPObjects.Players[player].Name:Remove()
        ESPObjects.Players[player].Distance:Remove()
        ESPObjects.Players[player].HealthBarBG:Remove()
        ESPObjects.Players[player].HealthBar:Remove()
        ESPObjects.Players[player].Tracer:Remove()
        ESPObjects.Players[player] = nil
    end
end

local function updatePlayerESP()
    for player, espData in pairs(ESPObjects.Players) do
        if not player or not player.Parent or not player.Character then
            removePlayerESP(player)
            continue
        end
        
        local character = player.Character
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        
        if not rootPart or not humanoid or not head then
            espData.Box.Visible = false
            espData.Name.Visible = false
            espData.Distance.Visible = false
            espData.HealthBarBG.Visible = false
            espData.HealthBar.Visible = false
            espData.Tracer.Visible = false
            continue
        end
        
        -- Team Check
        if ESPTeamCheck and isTeammate(player) then
            espData.Box.Visible = false
            espData.Name.Visible = false
            espData.Distance.Visible = false
            espData.HealthBarBG.Visible = false
            espData.HealthBar.Visible = false
            espData.Tracer.Visible = false
            continue
        end
        
        local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
        
        if distance > MaxESPDistance then
            espData.Box.Visible = false
            espData.Name.Visible = false
            espData.Distance.Visible = false
            espData.HealthBarBG.Visible = false
            espData.HealthBar.Visible = false
            espData.Tracer.Visible = false
            continue
        end
        
        local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        local rootPos = Camera:WorldToViewportPoint(rootPart.Position)
        
        if not onScreen or not ESPEnabled or not ESPPlayers then
            espData.Box.Visible = false
            espData.Name.Visible = false
            espData.Distance.Visible = false
            espData.HealthBarBG.Visible = false
            espData.HealthBar.Visible = false
            espData.Tracer.Visible = false
            continue
        end
        
        local boxSize = Vector2.new(2000 / distance, 2500 / distance)
        local playerColor = getPlayerColor(player)
        
        -- Box
        espData.Box.Size = boxSize
        espData.Box.Position = Vector2.new(rootPos.X - boxSize.X / 2, rootPos.Y - boxSize.Y / 2)
        espData.Box.Color = playerColor
        espData.Box.Visible = true
        
        -- Name
        espData.Name.Text = player.Name
        espData.Name.Position = Vector2.new(headPos.X, headPos.Y - 35)
        espData.Name.Color = playerColor
        espData.Name.Visible = true
        
        -- Distance
        espData.Distance.Text = string.format("[%.0fm]", distance)
        espData.Distance.Position = Vector2.new(rootPos.X, rootPos.Y + boxSize.Y / 2 + 20)
        espData.Distance.Visible = true
        
        -- Health Bar
        if humanoid then
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barWidth = 3
            local barHeight = boxSize.Y
            
            espData.HealthBarBG.Size = Vector2.new(barWidth, barHeight)
            espData.HealthBarBG.Position = Vector2.new(rootPos.X - boxSize.X / 2 - 5, rootPos.Y - boxSize.Y / 2)
            espData.HealthBarBG.Visible = true
            
            local healthColor = Color3.fromRGB(
                math.floor(255 * (1 - healthPercent)),
                math.floor(255 * healthPercent),
                0
            )
            espData.HealthBar.Size = Vector2.new(barWidth, barHeight * healthPercent)
            espData.HealthBar.Position = Vector2.new(
                rootPos.X - boxSize.X / 2 - 5,
                rootPos.Y - boxSize.Y / 2 + barHeight * (1 - healthPercent)
            )
            espData.HealthBar.Color = healthColor
            espData.HealthBar.Visible = true
        end
        
        -- Tracers
        if ShowTracers then
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            espData.Tracer.From = screenCenter
            espData.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            espData.Tracer.Color = playerColor
            espData.Tracer.Visible = true
        else
            espData.Tracer.Visible = false
        end
    end
end

-- Loot ESP
local function updateLootESP()
    -- Clear old ESP
    for _, esp in pairs(ESPObjects.Loot) do
        esp.Billboard:Destroy()
    end
    ESPObjects.Loot = {}
    
    if not ESPEnabled or not ESPLoot then return end
    
    local lootItems = getAllLoot()
    for _, loot in pairs(lootItems) do
        local lootPos = loot:IsA("Model") and loot:GetPivot().Position or loot.Position
        local distance = (lootPos - Camera.CFrame.Position).Magnitude
        
        if distance <= MaxESPDistance then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "LootESP"
            billboard.Size = UDim2.new(0, 100, 0, 50)
            billboard.Adornee = loot:IsA("Model") and loot.PrimaryPart or loot
            billboard.AlwaysOnTop = true
            billboard.Parent = loot
            
            local label = Instance.new("TextLabel", billboard)
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = LootColor
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            label.TextStrokeTransparency = 0
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 14
            label.Text = string.format("💰 [%.0fm]", distance)
            
            ESPObjects.Loot[loot] = {Billboard = billboard}
        end
    end
end

-- Exit ESP
local function updateExitESP()
    -- Clear old ESP
    for _, esp in pairs(ESPObjects.Exits) do
        if esp.Highlight then esp.Highlight:Destroy() end
        if esp.Billboard then esp.Billboard:Destroy() end
    end
    ESPObjects.Exits = {}
    
    if not ESPEnabled or not ESPExit then return end
    
    local exits = getExitGateways()
    for _, exit in pairs(exits) do
        -- Highlight
        local highlight = Instance.new("Highlight")
        highlight.Parent = exit
        highlight.Adornee = exit
        highlight.FillColor = ExitColor
        highlight.OutlineColor = ExitColor
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        
        -- Billboard
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ExitESP"
        billboard.Size = UDim2.new(0, 150, 0, 50)
        billboard.Adornee = exit:FindFirstChild("EXITEFFECT") or exit.PrimaryPart
        billboard.AlwaysOnTop = true
        billboard.Parent = exit
        
        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = ExitColor
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 16
        label.Text = "🚪 EXIT"
        
        ESPObjects.Exits[exit] = {Highlight = highlight, Billboard = billboard}
    end
end

-- Vent ESP
local function updateVentESP()
    -- Clear old ESP
    for _, esp in pairs(ESPObjects.Vents) do
        esp.Billboard:Destroy()
    end
    ESPObjects.Vents = {}
    
    if not ESPEnabled or not ESPVents then return end
    
    local vents = getAllVents()
    for _, vent in pairs(vents) do
        local distance = (vent.Position - Camera.CFrame.Position).Magnitude
        
        if distance <= MaxESPDistance then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "VentESP"
            billboard.Size = UDim2.new(0, 120, 0, 50)
            billboard.Adornee = vent
            billboard.AlwaysOnTop = true
            billboard.Parent = vent
            
            local label = Instance.new("TextLabel", billboard)
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = VentColor
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            label.TextStrokeTransparency = 0
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 14
            label.Text = string.format("🚪 VENT [%.0fm]", distance)
            
            ESPObjects.Vents[vent] = {Billboard = billboard}
        end
    end
end

--[[════════════════════════════════════════════════════════════════
    AUTOMATION FUNCTIONS
════════════════════════════════════════════════════════════════]]

-- Auto Farm Loot
local autoFarmCoroutine = nil
local function autoFarmLoot()
    while AutoFarmEnabled do
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then 
            wait(1) 
            continue 
        end
        
        local hrp = char.HumanoidRootPart
        local lootItems = getAllLoot()
        
        for _, loot in pairs(lootItems) do
            if not AutoFarmEnabled then break end
            
            local lootPos = loot:IsA("Model") and loot:GetPivot().Position or loot.Position
            hrp.CFrame = CFrame.new(lootPos + Vector3.new(0, 3, 0))
            wait(FarmDelay)
        end
        
        wait(1)
    end
end

-- Auto Escape
local autoEscapeCoroutine = nil
local function autoEscape()
    while AutoEscapeEnabled do
        local timeLeft = getTimeRemaining()
        
        if timeLeft <= AutoEscapeTimer then
            local exits = getExitGateways()
            if #exits > 0 then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local nearestExit = exits[1]:FindFirstChild("EXITEFFECT") or exits[1]
                    local exitPos = nearestExit:IsA("BasePart") and nearestExit.Position or nearestExit:GetPivot().Position
                    safeTeleport(CFrame.new(exitPos + Vector3.new(0, 3, 0)))
                    wait(2)
                end
            end
        end
        
        wait(1)
    end
end

-- Auto Breakfree
local autoBreakfreeCoroutine = nil
local function autoBreakfree()
    while AutoBreakfreeEnabled do
        local breakfreeRemote = ReplicatedStorage:FindFirstChild("BreakFree")
        if breakfreeRemote then
            pcall(function()
                breakfreeRemote:FireServer()
            end)
        end
        wait(0.1)
    end
end

--[[════════════════════════════════════════════════════════════════
    MOVEMENT SYSTEM
════════════════════════════════════════════════════════════════]]

-- Noclip
local noclipConnection = nil
local noclipParts = {}

local function enableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
    end
    
    noclipConnection = RunService.Stepped:Connect(function()
        if not NoclipEnabled then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if not noclipParts[part] then
                    noclipParts[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    task.wait(0.1)
    
    local char = LocalPlayer.Character
    if char then
        for part, originalState in pairs(noclipParts) do
            if part and part.Parent then
                part.CanCollide = originalState
            end
        end
        noclipParts = {}
    end
end

-- Speed & Jump
local function updateMovement()
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    if SpeedEnabled then
        humanoid.WalkSpeed = SpeedValue
    end
    
    if JumpEnabled then
        humanoid.JumpPower = JumpValue
    end
end

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- Anti-Ragdoll
local function updateAntiRagdoll()
    if AntiRagdollEnabled then
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            end
        end
    end
end

--[[════════════════════════════════════════════════════════════════
    ENVIRONMENT FUNCTIONS
════════════════════════════════════════════════════════════════]]

local originalTransparency = {}

local function removeShadows()
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CastShadow = false
        end
    end
    
    for _, light in pairs(Lighting:GetChildren()) do
        if light:IsA("Light") then
            light.ShadowSoftness = 1
        end
    end
end

local function removeFog()
    Lighting.FogStart = 0
    Lighting.FogEnd = 100000
end

local function enableFullbright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
end

local function toggleInvisibleMap()
    if InvisibleMap then
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsDescendantOf(LocalPlayer.Character) then
                local isPlayerPart = false
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr.Character and part:IsDescendantOf(plr.Character) then
                        isPlayerPart = true
                        break
                    end
                end
                
                if not isPlayerPart then
                    originalTransparency[part] = part.Transparency
                    part.Transparency = 1
                end
            end
        end
    else
        for part, trans in pairs(originalTransparency) do
            if part and part.Parent then
                part.Transparency = trans
            end
        end
        originalTransparency = {}
    end
end

--[[════════════════════════════════════════════════════════════════
    SAFETY SYSTEM
════════════════════════════════════════════════════════════════]]

-- Anti-Killer Detection
local function antiKillerCheck()
    if not AntiKillerEnabled then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if isBlacklisted(player) then
                local distance = (hrp.Position - player.Character.HumanoidRootPart.Position).Magnitude
                
                if distance <= DetectionDistance then
                    -- Teleport away
                    local randomPlayer = pickRandomPlayer()
                    if randomPlayer and randomPlayer.Character and randomPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        safeTeleport(randomPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(10, 0, 0))
                    else
                        -- Teleport to random exit
                        local exits = getExitGateways()
                        if #exits > 0 then
                            local randomExit = exits[math.random(1, #exits)]
                            local exitEffect = randomExit:FindFirstChild("EXITEFFECT")
                            local exitPos = exitEffect and exitEffect.Position or randomExit:GetPivot().Position
                            safeTeleport(CFrame.new(exitPos + Vector3.new(0, 3, 0)))
                        end
                    end
                    break
                end
            end
        end
    end
end

-- Emergency Teleport (X Key)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.X and EmergencyTPEnabled then
        local exits = getExitGateways()
        if #exits > 0 then
            local nearestExit = getNearestExit()
            if nearestExit then
                local exitEffect = nearestExit:FindFirstChild("EXITEFFECT")
                local exitPos = exitEffect and exitEffect.Position or nearestExit:GetPivot().Position
                safeTeleport(CFrame.new(exitPos + Vector3.new(0, 3, 0)))
                
                Rayfield:Notify({
                    Title = "Emergency Teleport",
                    Content = "Teleported to nearest exit!",
                    Duration = 3,
                    Image = 4483362458,
                })
            end
        end
    end
end)

--[[════════════════════════════════════════════════════════════════
    MAIN LOOP
════════════════════════════════════════════════════════════════]]

RunService.RenderStepped:Connect(function()
    -- Update Player ESP
    if ESPEnabled and ESPPlayers then
        updatePlayerESP()
    end
    
    -- Update Crosshair
    updateCrosshair()
    
    -- Update Movement
    if SpeedEnabled or JumpEnabled then
        updateMovement()
    end
    
    -- Anti-Ragdoll
    if AntiRagdollEnabled then
        updateAntiRagdoll()
    end
    
    -- Anti-Killer
    if AntiKillerEnabled then
        antiKillerCheck()
    end
end)

-- ESP Update Loop (slower for performance)
task.spawn(function()
    while wait(2) do
        if ESPEnabled then
            if ESPLoot then updateLootESP() end
            if ESPExit then updateExitESP() end
            if ESPVents then updateVentESP() end
        end
    end
end)

-- Player Management
Players.PlayerAdded:Connect(function(player)
    if ESPEnabled and ESPPlayers then
        createPlayerESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayerESP(player)
end)

--[[════════════════════════════════════════════════════════════════
    RAYFIELD UI CREATION
════════════════════════════════════════════════════════════════]]

local Window = Rayfield:CreateWindow({
   Name = "STK Ultimate Script V1.0",
   LoadingTitle = "Survive The Killer Script",
   LoadingSubtitle = "38+ Features | Professional",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "STKUltimate",
      FileName = "Config"
   },
   Discord = {
      Enabled = false,
   },
   KeySystem = false,
})

Rayfield:Notify({
   Title = "STK Script Loaded!",
   Content = "38+ Features Ready | Press Right CTRL to toggle",
   Duration = 5,
   Image = 4483362458,
})

--[[════════════════════════════════════════════════════════════════
    TAB 1: PLAYER
════════════════════════════════════════════════════════════════]]

local PlayerTab = Window:CreateTab("👤 Player", 4483362458)
local PlayerSection = PlayerTab:CreateSection("Movement Hacks")

PlayerTab:CreateToggle({
   Name = "Speed Hack",
   CurrentValue = false,
   Flag = "SpeedHack",
   Callback = function(Value)
       getgenv().SpeedEnabled = Value
       if not Value then
           local char = LocalPlayer.Character
           if char then
               local humanoid = char:FindFirstChildOfClass("Humanoid")
               if humanoid then
                   humanoid.WalkSpeed = 16
               end
           end
       end
   end,
})

PlayerTab:CreateSlider({
   Name = "Speed Value",
   Range = {16, 200},
   Increment = 1,
   Suffix = "",
   CurrentValue = 16,
   Flag = "SpeedValue",
   Callback = function(Value)
       getgenv().SpeedValue = Value
   end,
})

PlayerTab:CreateToggle({
   Name = "Jump Hack",
   CurrentValue = false,
   Flag = "JumpHack",
   Callback = function(Value)
       getgenv().JumpEnabled = Value
       if not Value then
           local char = LocalPlayer.Character
           if char then
               local humanoid = char:FindFirstChildOfClass("Humanoid")
               if humanoid then
                   humanoid.JumpPower = 50
               end
           end
       end
   end,
})

PlayerTab:CreateSlider({
   Name = "Jump Power",
   Range = {50, 300},
   Increment = 5,
   Suffix = "",
   CurrentValue = 50,
   Flag = "JumpValue",
   Callback = function(Value)
       getgenv().JumpValue = Value
   end,
})

PlayerTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfiniteJump",
   Callback = function(Value)
       getgenv().InfiniteJumpEnabled = Value
   end,
})

PlayerTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "Noclip",
   Callback = function(Value)
       getgenv().NoclipEnabled = Value
       if Value then
           enableNoclip()
       else
           disableNoclip()
       end
   end,
})

PlayerTab:CreateToggle({
   Name = "Anti-Ragdoll",
   CurrentValue = false,
   Flag = "AntiRagdoll",
   Callback = function(Value)
       getgenv().AntiRagdollEnabled = Value
   end,
})

--[[════════════════════════════════════════════════════════════════
    TAB 2: ESP & VISUALS
════════════════════════════════════════════════════════════════]]

local ESPTab = Window:CreateTab("🔍 ESP & Visuals", 4483362458)
local ESPMainSection = ESPTab:CreateSection("ESP Controls")

ESPTab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = false,
   Flag = "EnableESP",
   Callback = function(Value)
       getgenv().ESPEnabled = Value
       
       if Value then
           for _, player in pairs(Players:GetPlayers()) do
               if player ~= LocalPlayer then
                   createPlayerESP(player)
               end
           end
       else
           for player, _ in pairs(ESPObjects.Players) do
               removePlayerESP(player)
           end
           
           -- Clear all ESP
           for _, esp in pairs(ESPObjects.Loot) do
               esp.Billboard:Destroy()
           end
           ESPObjects.Loot = {}
           
           for _, esp in pairs(ESPObjects.Exits) do
               if esp.Highlight then esp.Highlight:Destroy() end
               if esp.Billboard then esp.Billboard:Destroy() end
           end
           ESPObjects.Exits = {}
           
           for _, esp in pairs(ESPObjects.Vents) do
               esp.Billboard:Destroy()
           end
           ESPObjects.Vents = {}
       end
   end,
})

ESPTab:CreateSection("ESP Features")

ESPTab:CreateToggle({
   Name = "ESP Loot (Coins & Items)",
   CurrentValue = false,
   Flag = "ESPLoot",
   Callback = function(Value)
       getgenv().ESPLoot = Value
       if Value and ESPEnabled then
           updateLootESP()
       else
           for _, esp in pairs(ESPObjects.Loot) do
               esp.Billboard:Destroy()
           end
           ESPObjects.Loot = {}
       end
   end,
})

ESPTab:CreateToggle({
   Name = "ESP Exit (Doors)",
   CurrentValue = false,
   Flag = "ESPExit",
   Callback = function(Value)
       getgenv().ESPExit = Value
       if Value and ESPEnabled then
           updateExitESP()
       else
           for _, esp in pairs(ESPObjects.Exits) do
               if esp.Highlight then esp.Highlight:Destroy() end
               if esp.Billboard then esp.Billboard:Destroy() end
           end
           ESPObjects.Exits = {}
       end
   end,
})

ESPTab:CreateToggle({
   Name = "ESP Players",
   CurrentValue = false,
   Flag = "ESPPlayers",
   Callback = function(Value)
       getgenv().ESPPlayers = Value
   end,
})

ESPTab:CreateToggle({
   Name = "ESP Vents (Hiding Spots)",
   CurrentValue = false,
   Flag = "ESPVents",
   Callback = function(Value)
       getgenv().ESPVents = Value
       if Value and ESPEnabled then
           updateVentESP()
       else
           for _, esp in pairs(ESPObjects.Vents) do
               esp.Billboard:Destroy()
           end
           ESPObjects.Vents = {}
       end
   end,
})

ESPTab:CreateToggle({
   Name = "Show Tracers",
   CurrentValue = false,
   Flag = "ShowTracers",
   Callback = function(Value)
       getgenv().ShowTracers = Value
   end,
})

ESPTab:CreateToggle({
   Name = "Crosshair",
   CurrentValue = false,
   Flag = "Crosshair",
   Callback = function(Value)
       getgenv().CrosshairEnabled = Value
   end,
})

ESPTab:CreateSection("ESP Settings")

ESPTab:CreateToggle({
   Name = "Team Check (Hide Teammates)",
   CurrentValue = true,
   Flag = "ESPTeamCheck",
   Callback = function(Value)
       getgenv().ESPTeamCheck = Value
   end,
})

ESPTab:CreateSlider({
   Name = "Max ESP Distance",
   Range = {500, 5000},
   Increment = 100,
   Suffix = "m",
   CurrentValue = 2000,
   Flag = "MaxESPDistance",
   Callback = function(Value)
       getgenv().MaxESPDistance = Value
   end,
})

--[[════════════════════════════════════════════════════════════════
    TAB 3: ENVIRONMENT
════════════════════════════════════════════════════════════════]]

local EnvTab = Window:CreateTab("🌍 Environment", 4483362458)
local EnvSection = EnvTab:CreateSection("Visual Enhancements")

EnvTab:CreateButton({
   Name = "Remove Shadows",
   Callback = function()
       removeShadows()
       Rayfield:Notify({
           Title = "Shadows Removed",
           Content = "All shadows have been removed!",
           Duration = 3,
           Image = 4483362458,
       })
   end,
})

EnvTab:CreateButton({
   Name = "Remove Fog",
   Callback = function()
       removeFog()
       Rayfield:Notify({
           Title = "Fog Removed",
           Content = "Fog has been removed!",
           Duration = 3,
           Image = 4483362458,
       })
   end,
})

EnvTab:CreateButton({
   Name = "Fullbright",
   Callback = function()
       enableFullbright()
       Rayfield:Notify({
           Title = "Fullbright Enabled",
           Content = "Map is now fully bright!",
           Duration = 3,
           Image = 4483362458,
       })
   end,
})

EnvTab:CreateSection("Lighting Modes")

EnvTab:CreateButton({
   Name = "Day Mode",
   Callback = function()
       Lighting.ClockTime = 14
       Lighting.Brightness = 2
       Lighting.Ambient = Color3.fromRGB(255, 255, 255)
       Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
       Rayfield:Notify({
           Title = "Day Mode",
           Content = "Lighting set to daytime!",
           Duration = 3,
           Image = 4483362458,
       })
   end,
})

EnvTab:CreateButton({
   Name = "Afternoon Mode",
   Callback = function()
       Lighting.ClockTime = 15
       Lighting.Brightness = 2
       Lighting.Ambient = Color3.fromRGB(255, 255, 255)
       Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
       Rayfield:Notify({
           Title = "Afternoon Mode",
           Content = "Lighting set to afternoon!",
           Duration = 3,
           Image = 4483362458,
       })
   end,
})

EnvTab:CreateButton({
   Name = "Evening Mode",
   Callback = function()
       Lighting.ClockTime = 0
       Lighting.Brightness = 1
       Lighting.Ambient = Color3.fromRGB(50, 50, 50)
       Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 20)
       Rayfield:Notify({
           Title = "Evening Mode",
           Content = "Lighting set to evening!",
           Duration = 3,
           Image = 4483362458,
       })
   end,
})

EnvTab:CreateButton({
   Name = "Normal Lighting",
   Callback = function()
       Lighting.ClockTime = 15
       Lighting.Brightness = 2
       Lighting.Ambient = Color3.fromRGB(255, 255, 255)
       Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
       Rayfield:Notify({
           Title = "Normal Lighting",
           Content = "Lighting reset to normal!",
           Duration = 3,
           Image = 4483362458,
       })
   end,
})

EnvTab:CreateSection("Map Visibility")

EnvTab:CreateToggle({
   Name = "Invisible Map",
   CurrentValue = false,
   Flag = "InvisibleMap",
   Callback = function(Value)
       getgenv().InvisibleMap = Value
       toggleInvisibleMap()
   end,
})

--[[════════════════════════════════════════════════════════════════
    TAB 4: AUTOMATION
════════════════════════════════════════════════════════════════]]

local AutoTab = Window:CreateTab("🚀 Automation", 4483362458)
local AutoSection = AutoTab:CreateSection("Auto Features")

AutoTab:CreateToggle({
   Name = "Auto Farm Loot",
   CurrentValue = false,
   Flag = "AutoFarm",
   Callback = function(Value)
       getgenv().AutoFarmEnabled = Value
       
       if Value then
           autoFarmCoroutine = task.spawn(autoFarmLoot)
           Rayfield:Notify({
               Title = "Auto Farm Enabled",
               Content = "Farming loot automatically!",
               Duration = 3,
               Image = 4483362458,
           })
       else
           if autoFarmCoroutine then
               task.cancel(autoFarmCoroutine)
           end
           Rayfield:Notify({
               Title = "Auto Farm Disabled",
               Content = "Stopped farming loot",
               Duration = 3,
               Image = 4483362458,
           })
       end
   end,
})

AutoTab:CreateSlider({
   Name = "Farm Speed (Delay)",
   Range = {0.3, 2},
   Increment = 0.1,
   Suffix = "s",
   CurrentValue = 0.5,
   Flag = "FarmDelay",
   Callback = function(Value)
       getgenv().FarmDelay = Value
   end,
})

AutoTab:CreateSection("Auto Escape")

AutoTab:CreateToggle({
   Name = "Auto Escape (Exit When Timer Low)",
   CurrentValue = false,
   Flag = "AutoEscape",
   Callback = function(Value)
       getgenv().AutoEscapeEnabled = Value
       
       if Value then
           autoEscapeCoroutine = task.spawn(autoEscape)
           Rayfield:Notify({
               Title = "Auto Escape Enabled",
               Content = "Will auto-escape when timer is low!",
               Duration = 3,
               Image = 4483362458,
           })
       else
           if autoEscapeCoroutine then
               task.cancel(autoEscapeCoroutine)
           end
           Rayfield:Notify({
               Title = "Auto Escape Disabled",
               Content = "Stopped auto-escape",
               Duration = 3,
               Image = 4483362458,
           })
       end
   end,
})

AutoTab:CreateSlider({
   Name = "Escape Timer (Seconds Remaining)",
   Range = {5, 60},
   Increment = 5,
   Suffix = "s",
   CurrentValue = 30,
   Flag = "AutoEscapeTimer",
   Callback = function(Value)
       getgenv().AutoEscapeTimer = Value
   end,
})

AutoTab:CreateSection("Auto Breakfree")

AutoTab:CreateToggle({
   Name = "Auto Breakfree (Escape Killer Grab)",
   CurrentValue = false,
   Flag = "AutoBreakfree",
   Callback = function(Value)
       getgenv().AutoBreakfreeEnabled = Value
       
       if Value then
           autoBreakfreeCoroutine = task.spawn(autoBreakfree)
           Rayfield:Notify({
               Title = "Auto Breakfree Enabled",
               Content = "Will spam breakfree when grabbed!",
               Duration = 3,
               Image = 4483362458,
           })
       else
           if autoBreakfreeCoroutine then
               task.cancel(autoBreakfreeCoroutine)
           end
           Rayfield:Notify({
               Title = "Auto Breakfree Disabled",
               Content = "Stopped auto-breakfree",
               Duration = 3,
               Image = 4483362458,
           })
       end
   end,
})

--[[════════════════════════════════════════════════════════════════
    TAB 5: TELEPORT
════════════════════════════════════════════════════════════════]]

local TeleTab = Window:CreateTab("📍 Teleport", 4483362458)
local TeleSection = TeleTab:CreateSection("Quick Teleports")

TeleTab:CreateButton({
   Name = "Teleport to Nearest Exit",
   Callback = function()
       local exit = getNearestExit()
       if exit then
           local exitEffect = exit:FindFirstChild("EXITEFFECT")
           local exitPos = exitEffect and exitEffect.Position or exit:GetPivot().Position
           safeTeleport(CFrame.new(exitPos + Vector3.new(0, 3, 0)))
           Rayfield:Notify({
               Title = "Teleported",
               Content = "Teleported to nearest exit!",
               Duration = 3,
               Image = 4483362458,
           })
       else
           Rayfield:Notify({
               Title = "Error",
               Content = "No exits found!",
               Duration = 3,
               Image = 4483362458,
           })
       end
   end,
})

TeleTab:CreateButton({
   Name = "Teleport to Nearest Loot",
   Callback = function()
       local loot = getNearestLoot()
       if loot then
           local lootPos = loot:IsA("Model") and loot:GetPivot().Position or loot.Position
           safeTeleport(CFrame.new(lootPos + Vector3.new(0, 3, 0)))
           Rayfield:Notify({
               Title = "Teleported",
               Content = "Teleported to nearest loot!",
               Duration = 3,
               Image = 4483362458,
           })
       else
           Rayfield:Notify({
               Title = "Error",
               Content = "No loot found!",
               Duration = 3,
               Image = 4483362458,
           })
       end
   end,
})

TeleTab:CreateButton({
   Name = "Teleport to Nearest Vent",
   Callback = function()
       local vent = getNearestVent()
       if vent then
           safeTeleport(CFrame.new(vent.Position + Vector3.new(0, 3, 0)))
           Rayfield:Notify({
               Title = "Teleported",
               Content = "Teleported to nearest vent!",
               Duration = 3,
               Image = 4483362458,
           })
       else
           Rayfield:Notify({
               Title = "Error",
               Content = "No vents found!",
               Duration = 3,
               Image = 4483362458,
           })
       end
   end,
})

TeleTab:CreateButton({
   Name = "Teleport to Lobby",
   Callback = function()
       safeTeleport(CFrame.new(-9.22, 267.96, -5.39))
       Rayfield:Notify({
           Title = "Teleported",
           Content = "Teleported to lobby!",
           Duration = 3,
           Image = 4483362458,
       })
   end,
})

TeleTab:CreateSection("Player Teleport")

local playerNameInput = TeleTab:CreateInput({
   Name = "Player Name",
   PlaceholderText = "Enter player name...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       -- Store the text
   end,
})

TeleTab:CreateButton({
   Name = "Teleport to Player",
   Callback = function()
       local playerName = playerNameInput.CurrentValue
       local targetPlayer = findPlayerByPartial(playerName)
       
       if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
           safeTeleport(targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(5, 0, 0))
           Rayfield:Notify({
               Title = "Teleported",
               Content = "Teleported to " .. targetPlayer.Name,
               Duration = 3,
               Image = 4483362458,
           })
       else
           Rayfield:Notify({
               Title = "Error",
               Content = "Player not found or blacklisted!",
               Duration = 3,
               Image = 4483362458,
           })
       end
   end,
})

TeleTab:CreateButton({
   Name = "Teleport to Random Player",
   Callback = function()
       local randomPlayer = pickRandomPlayer()
       
       if randomPlayer and randomPlayer.Character and randomPlayer.Character:FindFirstChild("HumanoidRootPart") then
           safeTeleport(randomPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(5, 0, 0))
           Rayfield:Notify({
               Title = "Teleported",
               Content = "Teleported to " .. randomPlayer.Name,
               Duration = 3,
               Image = 4483362458,
           })
       else
           Rayfield:Notify({
               Title = "Error",
               Content = "No valid players found!",
               Duration = 3,
               Image = 4483362458,
           })
       end
   end,
})

--[[════════════════════════════════════════════════════════════════
    TAB 6: SAFETY
════════════════════════════════════════════════════════════════]]

local SafetyTab = Window:CreateTab("🛡️ Safety", 4483362458)
local SafetySection = SafetyTab:CreateSection("Blacklist System")

local blacklistInput = SafetyTab:CreateInput({
   Name = "Player Name to Blacklist",
   PlaceholderText = "Enter player name...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       -- Store the text
   end,
})

SafetyTab:CreateButton({
   Name = "Add to Blacklist",
   Callback = function()
       local playerName = blacklistInput.CurrentValue
       if playerName and playerName ~= "" then
           table.insert(getgenv().Blacklist, playerName)
           Rayfield:Notify({
               Title = "Blacklist Updated",
               Content = "Added " .. playerName .. " to blacklist!",
               Duration = 3,
               Image = 4483362458,
           })
       end
   end,
})

SafetyTab:CreateButton({
   Name = "Clear Blacklist",
   Callback = function()
       getgenv().Blacklist = {}
       Rayfield:Notify({
           Title = "Blacklist Cleared",
           Content = "All blacklisted players removed!",
           Duration = 3,
           Image = 4483362458,
       })
   end,
})

SafetyTab:CreateSection("Safety Features")

SafetyTab:CreateToggle({
   Name = "Anti-Killer Mode",
   CurrentValue = false,
   Flag = "AntiKiller",
   Callback = function(Value)
       getgenv().AntiKillerEnabled = Value
       
       if Value then
           Rayfield:Notify({
               Title = "Anti-Killer Enabled",
               Content = "Will auto-teleport away from blacklisted players!",
               Duration = 3,
               Image = 4483362458,
           })
       end
   end,
})

SafetyTab:CreateSlider({
   Name = "Detection Distance",
   Range = {25, 100},
   Increment = 5,
   Suffix = " studs",
   CurrentValue = 50,
   Flag = "DetectionDistance",
   Callback = function(Value)
       getgenv().DetectionDistance = Value
   end,
})

SafetyTab:CreateToggle({
   Name = "Emergency Teleport (X Key)",
   CurrentValue = true,
   Flag = "EmergencyTP",
   Callback = function(Value)
       getgenv().EmergencyTPEnabled = Value
   end,
})

SafetyTab:CreateSection("Safe Mode")

SafetyTab:CreateToggle({
   Name = "Safe Mode (Enable All Safety)",
   CurrentValue = false,
   Flag = "SafeMode",
   Callback = function(Value)
       getgenv().SafeModeEnabled = Value
       
       if Value then
           getgenv().AntiKillerEnabled = true
           getgenv().EmergencyTPEnabled = true
           getgenv().AntiRagdollEnabled = true
           
           Rayfield:Notify({
               Title = "Safe Mode Enabled",
               Content = "All safety features activated!",
               Duration = 3,
               Image = 4483362458,
           })
       end
   end,
})

--[[════════════════════════════════════════════════════════════════
    TAB 7: SETTINGS
════════════════════════════════════════════════════════════════]]

local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
local SettingsSection = SettingsTab:CreateSection("Script Controls")

SettingsTab:CreateButton({
   Name = "Destroy Script",
   Callback = function()
       -- Clear all ESP
       for player, _ in pairs(ESPObjects.Players) do
           removePlayerESP(player)
       end
       
       for _, esp in pairs(ESPObjects.Loot) do
           if esp.Billboard then esp.Billboard:Destroy() end
       end
       
       for _, esp in pairs(ESPObjects.Exits) do
           if esp.Highlight then esp.Highlight:Destroy() end
           if esp.Billboard then esp.Billboard:Destroy() end
       end
       
       for _, esp in pairs(ESPObjects.Vents) do
           if esp.Billboard then esp.Billboard:Destroy() end
       end
       
       -- Disable noclip
       if NoclipEnabled then
           disableNoclip()
       end
       
       Rayfield:Notify({
           Title = "Script Destroyed",
           Content = "STK Ultimate Script unloaded!",
           Duration = 3,
           Image = 4483362458,
       })
       
       wait(1)
       Rayfield:Destroy()
   end,
})

SettingsTab:CreateSection("Notifications")

SettingsTab:CreateToggle({
   Name = "Enable Notifications",
   CurrentValue = true,
   Flag = "Notifications",
   Callback = function(Value)
       -- This would control notification settings
   end,
})

SettingsTab:CreateSection("Information")
SettingsTab:CreateLabel("Script: STK Ultimate Script")
SettingsTab:CreateLabel("Version: 1.0")
SettingsTab:CreateLabel("Features: 38+")
SettingsTab:CreateLabel("Status: ✅ Active")
SettingsTab:CreateLabel("")
SettingsTab:CreateLabel("Current Map: " .. getMapName())
SettingsTab:CreateLabel("")
SettingsTab:CreateLabel("Controls:")
SettingsTab:CreateLabel("• Toggle UI: Right CTRL")
SettingsTab:CreateLabel("• Emergency TP: X Key")
SettingsTab:CreateLabel("• Drag UI: Hold title bar")
SettingsTab:CreateLabel("")
SettingsTab:CreateLabel("⚠️ Warning:")
SettingsTab:CreateLabel("Use at your own risk!")
SettingsTab:CreateLabel("High detection risk with speed hacks")

SettingsTab:CreateSection("Credits")
SettingsTab:CreateLabel("Created by: Community")
SettingsTab:CreateLabel("UI Library: Rayfield")
SettingsTab:CreateLabel("Game: Survive The Killer")

--[[════════════════════════════════════════════════════════════════
    FINAL INITIALIZATION
════════════════════════════════════════════════════════════════]]

Rayfield:LoadConfiguration()

print("╔═══════════════════════════════════════════════════╗")
print("║                                                   ║")
print("║     STK ULTIMATE SCRIPT V1.0 - LOADED ✅          ║")
print("║     38+ Features Ready                            ║")
print("║     Rayfield UI Premium                           ║")
print("║                                                   ║")
print("╚═══════════════════════════════════════════════════╝")
print("")
print("✅ All systems active!")
print("✅ Current Map:", getMapName())
print("✅ Press Right CTRL to toggle UI")
print("✅ Press X for emergency teleport")
print("")
print("⚠️  Use at your own risk!")
print("════════════════════════════════════════════════════")
