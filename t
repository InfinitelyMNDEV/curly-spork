-- Load WindUI
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

-- Create custom Ocean theme for Orca Hub
WindUI:AddTheme({
    Name = "Ocean",
    Accent = Color3.fromHex("#1e90ff"),
    Background = Color3.fromHex("#0a1929"),
    Outline = Color3.fromHex("#4a9eff"),
    Text = Color3.fromHex("#ffffff"),
    Placeholder = Color3.fromHex("#7a9ab5"),
    Button = Color3.fromHex("#1565c0"),
    Icon = Color3.fromHex("#64b5f6"),
})

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ============================================================
-- CREATE WINDOW
-- ============================================================
local Window = WindUI:CreateWindow({
    Title        = "Orca Hub — Revamped",
    Author       = "By InfiniteMNDEV",
    Icon         = "fish", 
    Theme        = "Ocean",
    Folder       = "OrcaHub",

    Size         = UDim2.fromOffset(480, 340), 
    MinSize      = Vector2.new(420, 280),
    MaxSize      = Vector2.new(700, 480),

    Resizable    = true,
    AutoScale    = false,
    ToggleKey    = Enum.KeyCode.RightShift,
    SideBarWidth = 180,

    OpenButton = {
        Title     = "Orca Hub",
        Icon      = "power", 
        Enabled   = true,
        Draggable = true,
        Scale     = 1,
        Color     = ColorSequence.new(
            Color3.fromHex("#1e90ff"),
            Color3.fromHex("#1565c0")
        ),
    },
})

task.spawn(function()
    task.wait(0.2)
    WindUI:SetTheme("Ocean")
end)

WindUI:Notify({
    Title    = "🐬 Orca Hub",
    Content  = "Successfully loaded! Welcome to Orca Hub.",
    Icon     = "solar:star-bold",
    Duration = 5,
})

-- ============================================================
-- STATE & CONFIG (Aimbot Mobile)
-- ============================================================
local AimbotConfig = {
    Enabled      = false,
    Smoothness   = 0.15,
    FOVEnabled   = true,
    FOVRadius    = 150,
    WallCheck    = true,
    TeamCheck    = true,
    TargetTeams  = {},
}
local aimbotLocked = false
local aimbotTarget = nil
local aimbotConn = nil
local mobileButtonGui = nil
local mobileButton = nil
local crosshairParts = {}
local fovCircle = nil

-- ============================================================
-- STATE & CONFIG (Aimbot PC)
-- ============================================================
local PCAimbotConfig = {
    Enabled      = false,
    Smoothness   = 0.15,
    FOVEnabled   = true,
    FOVRadius    = 150,
    WallCheck    = true,
    TeamCheck    = true,
    TargetTeams  = {},
    Keybind      = Enum.KeyCode.Q,
}
local pcAimbotLocked = false
local pcAimbotTarget = nil
local pcAimbotConn = nil
local pcInputConn = nil
local pcCrosshairGui = nil
local pcCrosshairParts = {}
local pcFovCircle = nil

-- ============================================================
-- STATE & CONFIG (Reach)
-- ============================================================
local ReachConfig = {
    Enabled      = false,
    MaxDistance  = 25,
    ForwardOffset = 3.5,
    TargetTeams  = {},
    TargetPart   = "Arms" 
}
local reachTarget = nil
local reachActiveJoints = {}
local reachModifiedToolParts = {}
local reachConn = nil

-- ============================================================
-- STATE & CONFIG (Visuals / ESP)
-- ============================================================
local VisualsConfig = {
    Enabled             = false,
    FillTransparency    = 0.5,
    OutlineTransparency = 0,
    TargetTeams         = {}
}
local espHighlights = {}
local espConnections = {}

local BoxConfig = { Enabled = false, Thickness = 1, OutlineThickness = 3 }
local HealthConfig = { Enabled = false }
local TracerConfig = { Enabled = false }
local espDrawings = {}
local renderConn = nil

-- ============================================================
-- STATE & CONFIG (Movement)
-- ============================================================
local WalkSpeedConfig = { Enabled = false, Speed = 16 }
local walkSpeedConn = nil

local JumpConfig = {
    Enabled     = false,
    JumpHeight  = 50,
    JitterSteps = 5,
    JitterDelay = 0.01
}
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local isJumping = false
local jumpGui = nil
local jumpButton = nil
local jumpInputConn = nil
local jumpCharConn = nil

local TpwalkConfig = {
    Enabled = false,
    Speed   = 1
}
local tpwalkRenderName = "OrcaHub_Tpwalk"
local tpwalkCharAdded = nil
local tpwalkCharRemoving = nil
local tpChar, tpHum, tpRoot = nil, nil, nil

-- Stamina Config
local StaminaConfig = { Enabled = false }
local staminaConn = nil
local origPlayerHasEnergy = nil
local origGetPlayerEnergy = nil
local origSPRINT_MINIMUM_ENERGY = nil
local origSend = nil

-- Noclip Config
local NoclipConfig = { Enabled = false }
local noclipConn = nil

-- Float Config
local FloatConfig = { Enabled = false }
local floatPlatform = nil
local floatConn = nil
local floatCharConn = nil
local currentFloatHeight = 0
local floatName = "OrcaHub_FloatPlatform"

-- Silent Aim Configs
local TaserConfig = { Enabled = false }
local PepperConfig = { Enabled = false }

-- Taser Rifle Config
local TaserRifleConfig = {
    Enabled = false,
    MaxDistance = 300,
    ProjectileSpeed = 1500,
    PingCompensation = 0.05,
    FireDelay = 0
}
local oldRifleFire = nil
local rifleHooked = false
local RifleFireEvent = ReplicatedStorage:WaitForChild("Remote", 5):WaitForChild("RifleFireEvent", 5)

-- ============================================================
-- SHARED HELPER FUNCTIONS
-- ============================================================
local function getTeamNames()
    local names = {}
    for _, team in ipairs(Teams:GetTeams()) do
        table.insert(names, team.Name)
    end
    return names
end

local function isValidTarget(otherPlayer, config)
    if otherPlayer == player then return false end
    local char = otherPlayer.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end
    if config.TeamCheck and player.Team and otherPlayer.Team and player.Team == otherPlayer.Team then return false end
    if #config.TargetTeams > 0 then
        local teamName = otherPlayer.Team and otherPlayer.Team.Name
        if not teamName then return false end
        local found = false
        for _, name in ipairs(config.TargetTeams) do
            if name == teamName then found = true; break end
        end
        if not found then return false end
    end
    return true
end

local function findAimbotTarget(config)
    local nearestTarget = nil
    local shortestDist = math.huge
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {player.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if isValidTarget(otherPlayer, config) then
            local char = otherPlayer.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
            local centerScreen = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
            
            local isInRange = false
            local currentDist = math.huge
            
            if config.FOVEnabled then
                if onScreen and screenDist <= config.FOVRadius then
                    isInRange = true
                    currentDist = screenDist
                end
            else
                local dist3D = (camera.CFrame.Position - root.Position).Magnitude
                if dist3D < shortestDist then
                    isInRange = true
                    currentDist = dist3D
                end
            end
            
            if isInRange and currentDist < shortestDist then
                if config.WallCheck then
                    local rayOrigin = camera.CFrame.Position
                    local rayDirection = (root.Position - rayOrigin)
                    local rayResult = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
                    if not rayResult or (rayResult.Instance and rayResult.Instance:IsDescendantOf(char)) then
                        nearestTarget = otherPlayer
                        shortestDist = currentDist
                    end
                else
                    nearestTarget = otherPlayer
                    shortestDist = currentDist
                end
            end
        end
    end
    return nearestTarget
end

-- ============================================================
-- SIDEBAR SECTION: General
-- ============================================================
Window:Section({ Title = "General" })

local HomeTab = Window:Tab({ Title = "Home", Icon = "house" })
local CreditsSection = HomeTab:Section({ Title = "Credits", Icon = "info", Box = false, Opened = true })
CreditsSection:Paragraph({ Title = "🛠 Developer — InfiniteMNDEV", Desc = "" })

local DiscordSection = HomeTab:Section({ Title = "Discord Server", Icon = "users", Box = false, Opened = true })
local CopyButton = DiscordSection:Button({
    Title    = "Copy Discord Link",
    Icon     = "copy",
    Callback = function()
        if setclipboard then setclipboard("https://discord.gg/NQFkG4MDZ") end
        WindUI:Notify({ Title = "📋 Copied!", Content = "Discord link copied to clipboard.", Icon = "solar:check-circle-bold", Duration = 4 })
    end,
})
pcall(function()
    local f = CopyButton.Frame
    f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    f.Size = UDim2.new(1, -20, 0, 38)
    for _, child in ipairs(f:GetDescendants()) do
        if child:IsA("TextLabel") then
            child.TextColor3 = Color3.fromRGB(0, 0, 0)
            child.TextXAlignment = Enum.TextXAlignment.Center
        end
    end
end)

local UpdatesTab = Window:Tab({ Title = "Updates", Icon = "history" })
local UpdatesSection = UpdatesTab:Section({ Title = "Updates Logs", Icon = "calendar-check", Box = false, Opened = true })
local UpdatePara = UpdatesSection:Paragraph({ Title = "Latest Changes", Desc = "• Orca Hub Return\n• Bugs fixes\n• Performance issues fixes" })
pcall(function()
    for _, desc in ipairs(UpdatePara.Frame:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            desc.TextColor3 = Color3.fromRGB(147, 112, 219)
        end
    end
end)

local SettingsTab = Window:Tab({ Title = "Settings", Icon = "wrench" })
local ThemeSection = SettingsTab:Section({ Title = "Theme Changer", Icon = "contrast", Box = false, Opened = true })
ThemeSection:Paragraph({ Title = "Choose from multiple UI themes", Desc = "" })
ThemeSection:Dropdown({
    Title    = "Select Theme",
    Icon     = "palette",
    Values   = (function()
        local names = {}
        for name in pairs(WindUI:GetThemes()) do table.insert(names, name) end
        table.sort(names)
        return names
    end)(),
    Value    = WindUI:GetCurrentTheme(),
    Flag     = "SelectedTheme",
    Callback = function(selected)
        WindUI:SetTheme(selected)
        WindUI:Notify({ Title = "🎨 Theme Changed", Content = "Applied theme: " .. selected, Icon = "solar:palette-bold", Duration = 3 })
    end,
})

local ConfigSection = SettingsTab:Section({ Title = "Configurations", Icon = "hammer", Box = false, Opened = true })
ConfigSection:Toggle({
    Title    = "Auto-Save configurations",
    Icon     = "save",
    Desc     = "Toggling this off will make your settings reset upon disconnecting.",
    Value    = true,
    Flag     = "AutoSaveToggle",
    Callback = function(state)
        if state then
            WindUI:Notify({ Title = "💾 Auto-Save Enabled", Content = "Your settings will be saved automatically.", Icon = "solar:check-circle-bold", Duration = 3 })
        else
            WindUI:Notify({ Title = "⚠️ Auto-Save Disabled", Content = "Your settings will reset upon disconnecting.", Icon = "solar:danger-bold", Duration = 3 })
        end
    end,
})
ConfigSection:Button({
    Title    = "Save Configuration",
    Icon     = "download",
    Desc     = "Manually save all current settings.",
    Callback = function()
        if Window.ConfigManager then
            local OrcaConfig = Window.ConfigManager:CreateConfig("OrcaHub")
            OrcaConfig:Save()
            WindUI:Notify({ Title = "💾 Saved", Content = "Configuration saved successfully.", Icon = "solar:check-circle-bold", Duration = 3 })
        end
    end,
})
ConfigSection:Button({
    Title    = "Load Configuration",
    Icon     = "upload",
    Desc     = "Manually load saved settings.",
    Callback = function()
        if Window.ConfigManager then
            local OrcaConfig = Window.ConfigManager:CreateConfig("OrcaHub")
            OrcaConfig:Load()
            WindUI:Notify({ Title = "📂 Loaded", Content = "Configuration loaded successfully.", Icon = "solar:check-circle-bold", Duration = 3 })
        end
    end,
})

-- ============================================================
-- SIDEBAR SECTION: Combat
-- ============================================================
Window:Section({ Title = "Combat" })

local AimbotTab = Window:Tab({ Title = "Aimbot", Icon = "crosshair" })
local LockOnSection = AimbotTab:Section({ Title = "Lock On (Mobile)", Icon = "smartphone", Box = false, Opened = true })

local function createMobileButton()
    if mobileButtonGui then return end
    mobileButtonGui = Instance.new("ScreenGui")
    mobileButtonGui.Name = "OrcaHub_LockOnUI_Mobile"
    mobileButtonGui.ResetOnSpawn = false
    mobileButtonGui.IgnoreGuiInset = true
    mobileButtonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mobileButtonGui.Parent = player:WaitForChild("PlayerGui")
    
    mobileButton = Instance.new("TextButton")
    mobileButton.Size = UDim2.new(0, 60, 0, 60)
    mobileButton.Position = UDim2.new(1, -80, 0.5, -30)
    mobileButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mobileButton.Text = ""
    mobileButton.AutoButtonColor = true
    mobileButton.Parent = mobileButtonGui
    
    local buttonCorner = Instance.new("UICorner", mobileButton)
    buttonCorner.CornerRadius = UDim.new(1, 0)
    local buttonStroke = Instance.new("UIStroke", mobileButton)
    buttonStroke.Thickness = 2
    buttonStroke.Color = Color3.fromRGB(255, 255, 255)
    
    crosshairParts = {}
    local function createLine(name, size, pos)
        local line = Instance.new("Frame")
        line.Name = name; line.Size = size; line.Position = pos
        line.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        line.BorderSizePixel = 0; line.Parent = mobileButton
        table.insert(crosshairParts, line)
    end
    createLine("Dot", UDim2.new(0, 2, 0, 2), UDim2.new(0.5, -1, 0.5, -1))
    createLine("Top", UDim2.new(0, 2, 0, 10), UDim2.new(0.5, -1, 0.5, -17))
    createLine("Bottom", UDim2.new(0, 2, 0, 10), UDim2.new(0.5, -1, 0.5, 7))
    createLine("Left", UDim2.new(0, 10, 0, 2), UDim2.new(0.5, -17, 0.5, -1))
    createLine("Right", UDim2.new(0, 10, 0, 2), UDim2.new(0.5, 7, 0.5, -1))
    
    fovCircle = Instance.new("Frame")
    fovCircle.Size = UDim2.new(0, AimbotConfig.FOVRadius * 2, 0, AimbotConfig.FOVRadius * 2)
    fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    fovCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fovCircle.BackgroundTransparency = 1
    fovCircle.Visible = AimbotConfig.FOVEnabled
    fovCircle.Parent = mobileButtonGui
    
    local fovCorner = Instance.new("UICorner", fovCircle)
    fovCorner.CornerRadius = UDim.new(1, 0)
    local fovStroke = Instance.new("UIStroke", fovCircle)
    fovStroke.Thickness = 1.5; fovStroke.Color = Color3.fromRGB(255, 255, 255); fovStroke.Transparency = 0.5
    
    mobileButton.Activated:Connect(function()
        aimbotLocked = not aimbotLocked
        local color = aimbotLocked and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 170, 255)
        for _, part in ipairs(crosshairParts) do part.BackgroundColor3 = color end
        if not aimbotLocked then aimbotTarget = nil end
    end)
end

local function removeMobileButton()
    if mobileButtonGui then
        mobileButtonGui:Destroy()
        mobileButtonGui = nil; mobileButton = nil; crosshairParts = {}; fovCircle = nil
    end
end

local function updateMobileFOVCircle()
    if fovCircle then
        fovCircle.Size = UDim2.new(0, AimbotConfig.FOVRadius * 2, 0, AimbotConfig.FOVRadius * 2)
        fovCircle.Visible = AimbotConfig.FOVEnabled
    end
end

local function startMobileAimbot()
    if aimbotConn then return end
    aimbotConn = RunService.RenderStepped:Connect(function()
        if not AimbotConfig.Enabled or not aimbotLocked then return end
        aimbotTarget = findAimbotTarget(AimbotConfig)
        if aimbotTarget and aimbotTarget.Character and aimbotTarget.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = aimbotTarget.Character.HumanoidRootPart.Position
            local currentLook = camera.CFrame.LookVector
            local targetLook = (targetPos - camera.CFrame.Position).Unit
            local newLook = currentLook:Lerp(targetLook, AimbotConfig.Smoothness)
            camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + newLook)
        end
    end)
end

local function stopMobileAimbot()
    if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
    aimbotLocked = false; aimbotTarget = nil
end

LockOnSection:Toggle({
    Title    = "Lock On", Desc = "Show the mobile lock-on button. Tap it to lock onto nearby players.",
    Icon     = "crosshair", Value = false, Flag = "AimbotEnabled",
    Callback = function(state)
        AimbotConfig.Enabled = state
        if state then createMobileButton(); startMobileAimbot()
        else stopMobileAimbot(); removeMobileButton() end
    end,
})
LockOnSection:Input({ Title = "Smoothness (0.0 - 1.0)", Desc = "Lower = slower/smoother tracking. 1 = instant snapping.", Placeholder = "Default: 0.15", Flag = "AimbotSmoothness", Callback = function(value) local n = tonumber(value) if n and n >= 0 and n <= 1 then AimbotConfig.Smoothness = n end end })
LockOnSection:Input({ Title = "FOV Radius (pixels)", Desc = "Radius of the FOV circle. Only targets players inside this circle.", Placeholder = "Default: 150", Flag = "AimbotFOVRadius", Callback = function(value) local n = tonumber(value) if n and n > 0 then AimbotConfig.FOVRadius = n; updateMobileFOVCircle() end end })
LockOnSection:Toggle({ Title = "Enable FOV Circle", Desc = "If on, only targets players inside the FOV circle. If off, targets nearest player globally.", Icon = "circle", Value = true, Flag = "AimbotFOVEnabled", Callback = function(state) AimbotConfig.FOVEnabled = state; updateMobileFOVCircle() end })
LockOnSection:Toggle({ Title = "Wall Check", Desc = "If on, will not target players behind walls.", Icon = "eye-off", Value = true, Flag = "AimbotWallCheck", Callback = function(state) AimbotConfig.WallCheck = state end })
LockOnSection:Toggle({ Title = "Team Check", Desc = "If on, will not target players on your team.", Icon = "users", Value = true, Flag = "AimbotTeamCheck", Callback = function(state) AimbotConfig.TeamCheck = state end })
local TeamDropdown = LockOnSection:Dropdown({ Title = "Target Teams", Desc = "Select which teams to target. Leave empty to target all teams.", Icon = "shield", Values = getTeamNames(), Value = {}, Multi = true, AllowNone = true, Flag = "AimbotTargetTeams", Callback = function(selected) AimbotConfig.TargetTeams = {} if type(selected) == "table" then for _, n in pairs(selected) do table.insert(AimbotConfig.TargetTeams, n) end elseif type(selected) == "string" and selected ~= "" then table.insert(AimbotConfig.TargetTeams, selected) end end })
Teams.ChildAdded:Connect(function(c) if c:IsA("Team") then task.wait(0.1); TeamDropdown:Refresh(getTeamNames()) end end)
Teams.ChildRemoved:Connect(function(c) if c:IsA("Team") then AimbotConfig.TargetTeams = {}; TeamDropdown:Refresh(getTeamNames()) end end)

local LockOnPCSection = AimbotTab:Section({ Title = "Lock On (Computer)", Icon = "laptop", Box = false, Opened = true })

local function createPCCrosshair()
    if pcCrosshairGui then return end
    pcCrosshairGui = Instance.new("ScreenGui")
    pcCrosshairGui.Name = "OrcaHub_LockOnUI_PC"
    pcCrosshairGui.ResetOnSpawn = false
    pcCrosshairGui.IgnoreGuiInset = true
    pcCrosshairGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcCrosshairGui.Parent = player:WaitForChild("PlayerGui")
    
    local crosshairContainer = Instance.new("Frame")
    crosshairContainer.Size = UDim2.new(0, 60, 0, 60)
    crosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    crosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    crosshairContainer.BackgroundTransparency = 1
    crosshairContainer.Parent = pcCrosshairGui
    
    pcCrosshairParts = {}
    local function createLine(name, size, pos)
        local line = Instance.new("Frame")
        line.Name = name; line.Size = size; line.Position = pos
        line.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        line.BorderSizePixel = 0; line.Parent = crosshairContainer
        table.insert(pcCrosshairParts, line)
    end
    createLine("Dot", UDim2.new(0, 2, 0, 2), UDim2.new(0.5, -1, 0.5, -1))
    createLine("Top", UDim2.new(0, 2, 0, 10), UDim2.new(0.5, -1, 0.5, -17))
    createLine("Bottom", UDim2.new(0, 2, 0, 10), UDim2.new(0.5, -1, 0.5, 7))
    createLine("Left", UDim2.new(0, 10, 0, 2), UDim2.new(0.5, -17, 0.5, -1))
    createLine("Right", UDim2.new(0, 10, 0, 2), UDim2.new(0.5, 7, 0.5, -1))
    
    pcFovCircle = Instance.new("Frame")
    pcFovCircle.Size = UDim2.new(0, PCAimbotConfig.FOVRadius * 2, 0, PCAimbotConfig.FOVRadius * 2)
    pcFovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    pcFovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    pcFovCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    pcFovCircle.BackgroundTransparency = 1
    pcFovCircle.Visible = PCAimbotConfig.FOVEnabled
    pcFovCircle.Parent = pcCrosshairGui
    
    local fovCorner = Instance.new("UICorner", pcFovCircle)
    fovCorner.CornerRadius = UDim.new(1, 0)
    local fovStroke = Instance.new("UIStroke", pcFovCircle)
    fovStroke.Thickness = 1.5; fovStroke.Color = Color3.fromRGB(255, 255, 255); fovStroke.Transparency = 0.5
end

local function removePCCrosshair()
    if pcCrosshairGui then
        pcCrosshairGui:Destroy()
        pcCrosshairGui = nil; pcCrosshairParts = {}; pcFovCircle = nil
    end
end

local function updatePCFOVCircle()
    if pcFovCircle then
        pcFovCircle.Size = UDim2.new(0, PCAimbotConfig.FOVRadius * 2, 0, PCAimbotConfig.FOVRadius * 2)
        pcFovCircle.Visible = PCAimbotConfig.FOVEnabled
    end
end

local function startPCInputListener()
    if pcInputConn then pcInputConn:Disconnect() end
    pcInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == PCAimbotConfig.Keybind then
            pcAimbotLocked = not pcAimbotLocked
            local color = pcAimbotLocked and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 170, 255)
            for _, part in ipairs(pcCrosshairParts) do part.BackgroundColor3 = color end
            if not pcAimbotLocked then pcAimbotTarget = nil end
        end
    end)
end

local function startPCAimbot()
    if pcAimbotConn then return end
    pcAimbotConn = RunService.RenderStepped:Connect(function()
        if not PCAimbotConfig.Enabled or not pcAimbotLocked then return end
        pcAimbotTarget = findAimbotTarget(PCAimbotConfig)
        if pcAimbotTarget and pcAimbotTarget.Character and pcAimbotTarget.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = pcAimbotTarget.Character.HumanoidRootPart.Position
            local currentLook = camera.CFrame.LookVector
            local targetLook = (targetPos - camera.CFrame.Position).Unit
            local newLook = currentLook:Lerp(targetLook, PCAimbotConfig.Smoothness)
            camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + newLook)
        end
    end)
end

local function stopPCAimbot()
    if pcAimbotConn then pcAimbotConn:Disconnect(); pcAimbotConn = nil end
    if pcInputConn then pcInputConn:Disconnect(); pcInputConn = nil end
    pcAimbotLocked = false; pcAimbotTarget = nil
end

LockOnPCSection:Toggle({
    Title    = "Lock On", Desc = "Show the PC crosshair. Press your keybind to lock onto nearby players.",
    Icon     = "crosshair", Value = false, Flag = "PCAimbotEnabled",
    Callback = function(state)
        PCAimbotConfig.Enabled = state
        if state then createPCCrosshair(); startPCInputListener(); startPCAimbot()
        else stopPCAimbot(); removePCCrosshair() end
    end,
})
LockOnPCSection:Keybind({ Title = "Toggle Keybind", Desc = "Press this key to toggle the lock-on.", Icon = "keyboard", Value = Enum.KeyCode.Q, Flag = "PCAimbotKeybind", Callback = function(key) if typeof(key) == "EnumItem" then PCAimbotConfig.Keybind = key end end })
LockOnPCSection:Input({ Title = "Smoothness (0.0 - 1.0)", Desc = "Lower = slower/smoother tracking. 1 = instant snapping.", Placeholder = "Default: 0.15", Flag = "PCAimbotSmoothness", Callback = function(value) local n = tonumber(value) if n and n >= 0 and n <= 1 then PCAimbotConfig.Smoothness = n end end })
LockOnPCSection:Input({ Title = "FOV Radius (pixels)", Desc = "Radius of the FOV circle. Only targets players inside this circle.", Placeholder = "Default: 150", Flag = "PCAimbotFOVRadius", Callback = function(value) local n = tonumber(value) if n and n > 0 then PCAimbotConfig.FOVRadius = n; updatePCFOVCircle() end end })
LockOnPCSection:Toggle({ Title = "Enable FOV Circle", Desc = "If on, only targets players inside the FOV circle. If off, targets nearest player globally.", Icon = "circle", Value = true, Flag = "PCAimbotFOVEnabled", Callback = function(state) PCAimbotConfig.FOVEnabled = state; updatePCFOVCircle() end })
LockOnPCSection:Toggle({ Title = "Wall Check", Desc = "If on, will not target players behind walls.", Icon = "eye-off", Value = true, Flag = "PCAimbotWallCheck", Callback = function(state) PCAimbotConfig.WallCheck = state end })
LockOnPCSection:Toggle({ Title = "Team Check", Desc = "If on, will not target players on your team.", Icon = "users", Value = true, Flag = "PCAimbotTeamCheck", Callback = function(state) PCAimbotConfig.TeamCheck = state end })
local PCTeamDropdown = LockOnPCSection:Dropdown({ Title = "Target Teams", Desc = "Select which teams to target. Leave empty to target all teams.", Icon = "shield", Values = getTeamNames(), Value = {}, Multi = true, AllowNone = true, Flag = "PCAimbotTargetTeams", Callback = function(selected) PCAimbotConfig.TargetTeams = {} if type(selected) == "table" then for _, n in pairs(selected) do table.insert(PCAimbotConfig.TargetTeams, n) end elseif type(selected) == "string" and selected ~= "" then table.insert(PCAimbotConfig.TargetTeams, selected) end end })
Teams.ChildAdded:Connect(function(c) if c:IsA("Team") then task.wait(0.1); PCTeamDropdown:Refresh(getTeamNames()) end end)
Teams.ChildRemoved:Connect(function(c) if c:IsA("Team") then PCAimbotConfig.TargetTeams = {}; PCTeamDropdown:Refresh(getTeamNames()) end end)

local ReachTab = Window:Tab({ Title = "Reach", Icon = "ruler" })
local ReachSection = ReachTab:Section({ Title = "Reach Functions", Icon = "hand", Box = false, Opened = true })

local function restoreReachLimbs(p)
    if reachModifiedToolParts[p] then
        for part, state in pairs(reachModifiedToolParts[p]) do
            if part and part.Parent then
                part.CanCollide = state.CanCollide
                part.CanTouch = state.CanTouch
            end
        end
        reachModifiedToolParts[p] = nil
    end
    if reachActiveJoints[p] then
        local data = reachActiveJoints[p]
        if data.LeftShoulder and data.LeftShoulder.Parent then data.LeftShoulder.Enabled = true end
        if data.RightShoulder and data.RightShoulder.Parent then data.RightShoulder.Enabled = true end
        if data.Neck and data.Neck.Parent then data.Neck.Enabled = true end
        reachActiveJoints[p] = nil
    end
end

local function getClosestReachTarget()
    local closest = nil
    local shortest = ReachConfig.MaxDistance
    local myChar = player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, p in ipairs(Players:GetPlayers()) do
        if isValidTarget(p, ReachConfig) then
            local root = p.Character.HumanoidRootPart
            local dist = (myRoot.Position - root.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = p
            end
        end
    end
    return closest
end

local function startReach()
    if reachConn then return end
    reachConn = RunService.RenderStepped:Connect(function()
        if not ReachConfig.Enabled then return end
        local myChar = player.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        
        local targetPlayer = getClosestReachTarget()
        if targetPlayer ~= reachTarget then
            if reachTarget then restoreReachLimbs(reachTarget) end
            reachTarget = targetPlayer
        end
        
        if targetPlayer then
            local tChar = targetPlayer.Character
            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
            if tHum and tHum.Health > 0 then
                if not reachModifiedToolParts[targetPlayer] then reachModifiedToolParts[targetPlayer] = {} end
                local equippedTool = tChar:FindFirstChildOfClass("Tool")
                if equippedTool then
                    for _, desc in ipairs(equippedTool:GetDescendants()) do
                        if desc:IsA("BasePart") then
                            if not reachModifiedToolParts[targetPlayer][desc] then
                                reachModifiedToolParts[targetPlayer][desc] = { CanCollide = desc.CanCollide, CanTouch = desc.CanTouch }
                            end
                            desc.CanCollide = false
                            desc.CanTouch = false
                        end
                    end
                end
                
                local targetCFrame = myRoot.CFrame * CFrame.new(0, 0, -ReachConfig.ForwardOffset)
                if ReachConfig.TargetPart == "Arms" then
                    local tTorso = tChar:FindFirstChild("Torso") or tChar:FindFirstChild("UpperTorso")
                    local tLeftArm = tChar:FindFirstChild("Left Arm") or tChar:FindFirstChild("LeftHand")
                    local tRightArm = tChar:FindFirstChild("Right Arm") or tChar:FindFirstChild("RightHand")
                    if tTorso and tLeftArm and tRightArm then
                        local leftShoulder = tTorso:FindFirstChild("Left Shoulder") or tTorso:FindFirstChild("LeftShoulder")
                        local rightShoulder = tTorso:FindFirstChild("Right Shoulder") or tTorso:FindFirstChild("RightShoulder")
                        if leftShoulder and rightShoulder then
                            if not reachActiveJoints[targetPlayer] then
                                reachActiveJoints[targetPlayer] = { LeftShoulder = leftShoulder, RightShoulder = rightShoulder }
                            end
                            leftShoulder.Enabled = false
                            rightShoulder.Enabled = false
                            tLeftArm.CFrame = targetCFrame * CFrame.new(-0.6, 0, 0)
                            tRightArm.CFrame = targetCFrame * CFrame.new(0.6, 0, 0)
                        end
                    end
                elseif ReachConfig.TargetPart == "Head" then
                    local tHead = tChar:FindFirstChild("Head")
                    local neckMotor = nil
                    for _, desc in ipairs(tChar:GetDescendants()) do
                        if desc:IsA("Motor6D") and desc.Name == "Neck" then neckMotor = desc break end
                    end
                    if tHead and neckMotor then
                        if not reachActiveJoints[targetPlayer] then reachActiveJoints[targetPlayer] = { Neck = neckMotor } end
                        neckMotor.Enabled = false
                        tHead.CFrame = targetCFrame
                    end
                end
            else
                restoreReachLimbs(targetPlayer)
                reachTarget = nil
            end
        end
    end)
end

local function stopReach()
    if reachConn then reachConn:Disconnect(); reachConn = nil end
    if reachTarget then restoreReachLimbs(reachTarget); reachTarget = nil end
end

ReachSection:Toggle({
    Title    = "Enable Reach", Desc = "Pull the closest player's arms/head into your weapon range.",
    Icon     = "hand", Value = false, Flag = "ReachEnabled",
    Callback = function(state)
        ReachConfig.Enabled = state
        if state then startReach() else stopReach() end
    end,
})
ReachSection:Dropdown({
    Title     = "Target Part", Desc = "Choose which part of the player to pull towards you.",
    Icon      = "body", Values = { "Arms", "Head" }, Value = "Arms", Multi = false, AllowNone = false, Flag = "ReachTargetPart",
    Callback  = function(selected) ReachConfig.TargetPart = selected if reachTarget then restoreReachLimbs(reachTarget); reachTarget = nil end end,
})
ReachSection:Input({ Title = "Max Distance", Desc = "Maximum range to pull someone's parts (default: 25).", Placeholder = "Default: 25", Flag = "ReachMaxDistance", Callback = function(value) local num = tonumber(value) if num and num > 0 then ReachConfig.MaxDistance = num end end })
ReachSection:Input({ Title = "Forward Offset", Desc = "How far in front of you the parts float (default: 3.5).", Placeholder = "Default: 3.5", Flag = "ReachForwardOffset", Callback = function(value) local num = tonumber(value) if num and num > 0 then ReachConfig.ForwardOffset = num end end })
local ReachTeamDropdown = ReachSection:Dropdown({ Title = "Target Teams", Desc = "Select which teams to target. Leave empty to target all teams.", Icon = "shield", Values = getTeamNames(), Value = {}, Multi = true, AllowNone = true, Flag = "ReachTargetTeams", Callback = function(selected) ReachConfig.TargetTeams = {} if type(selected) == "table" then for _, n in pairs(selected) do table.insert(ReachConfig.TargetTeams, n) end elseif type(selected) == "string" and selected ~= "" then table.insert(ReachConfig.TargetTeams, selected) end if reachTarget then restoreReachLimbs(reachTarget); reachTarget = nil end end })
Teams.ChildAdded:Connect(function(c) if c:IsA("Team") then task.wait(0.1); ReachTeamDropdown:Refresh(getTeamNames()) end end)
Teams.ChildRemoved:Connect(function(c) if c:IsA("Team") then ReachConfig.TargetTeams = {}; ReachTeamDropdown:Refresh(getTeamNames()) end end)
ReachSection:Button({ Title = "Reset Reach Settings", Desc = "Disable reach and restore all defaults.", Icon = "refresh-cw", Callback = function() stopReach() ReachConfig.MaxDistance = 25 ReachConfig.ForwardOffset = 3.5 ReachConfig.TargetPart = "Arms" ReachConfig.TargetTeams = {} WindUI:Notify({ Title = "⚔️ Reach Reset", Content = "Reach stopped and settings restored.", Icon = "solar:refresh-bold", Duration = 3 }) end })

local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
local OutlineSection = VisualsTab:Section({ Title = "Outline Functions", Icon = "eye-off", Box = false, Opened = true })

local function isESPValidTarget(p)
    if p == player then return false end
    if #VisualsConfig.TargetTeams > 0 then
        local tName = p.Team and p.Team.Name
        if not tName then return false end
        local found = false
        for _, n in ipairs(VisualsConfig.TargetTeams) do if n == tName then found = true break end end
        if not found then return false end
    end
    return true
end

local function updateESPColor(p)
    local hl = espHighlights[p]
    if not hl then return end
    if p.Team then
        hl.FillColor = p.TeamColor.Color
        hl.OutlineColor = p.TeamColor.Color
    else
        hl.FillColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    end
end

local function updateESPProperties()
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then
            hl.FillTransparency = VisualsConfig.FillTransparency
            hl.OutlineTransparency = VisualsConfig.OutlineTransparency
        end
    end
end

local function applyESP(p, char)
    if not isESPValidTarget(p) then return end
    local hl = espHighlights[p]
    if not hl or not hl.Parent then
        if hl then hl:Destroy() end
        hl = Instance.new("Highlight")
        hl.Name = "OrcaHub_ESP"
        hl.Adornee = char
        hl.Parent = char
        espHighlights[p] = hl
    end
    hl.FillTransparency = VisualsConfig.FillTransparency
    hl.OutlineTransparency = VisualsConfig.OutlineTransparency
    updateESPColor(p)
end

local function removeESP(p)
    if espHighlights[p] then
        espHighlights[p]:Destroy()
        espHighlights[p] = nil
    end
end

local function refreshESPTargets()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            if isESPValidTarget(p) then
                if p.Character then applyESP(p, p.Character) end
            else
                removeESP(p)
            end
        end
    end
end

local function setupESPPlayer(p)
    if p == player then return end
    if espConnections[p] then return end
    local function onCharAdded(char) task.wait(0.1) if VisualsConfig.Enabled then applyESP(p, char) end end
    local function onCharRemoving(char) removeESP(p) end
    espConnections[p] = {
        p.CharacterAdded:Connect(onCharAdded),
        p.CharacterRemoving:Connect(onCharRemoving),
        p:GetPropertyChangedSignal("Team"):Connect(function()
            if isESPValidTarget(p) then if p.Character then applyESP(p, p.Character) end updateESPColor(p) else removeESP(p) end
        end),
        p:GetPropertyChangedSignal("TeamColor"):Connect(function() updateESPColor(p) end)
    }
    if p.Character then task.spawn(onCharAdded, p.Character) end
end

local function startESP()
    if VisualsConfig.Enabled then return end
    VisualsConfig.Enabled = true
    for _, p in ipairs(Players:GetPlayers()) do setupESPPlayer(p) end
end

local function stopESP()
    VisualsConfig.Enabled = false
    for p, conns in pairs(espConnections) do for _, c in ipairs(conns) do c:Disconnect() end end
    espConnections = {}
    for p, hl in pairs(espHighlights) do hl:Destroy() end
    espHighlights = {}
end

OutlineSection:Toggle({
    Title    = "Highlight Players", Desc = "Toggle ESP on or off. Zero performance impact when off.",
    Icon     = "eye", Value = false, Flag = "ESPEnabled",
    Callback = function(state) if state then startESP() else stopESP() end end,
})
OutlineSection:Input({ Title = "Fill Transparency (0.0 - 1.0)", Desc = "0 = Solid color, 1 = Completely invisible fill.", Placeholder = "Default: 0.5", Flag = "ESPFillTransparency", Callback = function(value) local num = tonumber(value) if num and num >= 0 and num <= 1 then VisualsConfig.FillTransparency = num updateESPProperties() end end })
OutlineSection:Input({ Title = "Outline Transparency (0.0 - 1.0)", Desc = "0 = Solid outline, 1 = Invisible outline.", Placeholder = "Default: 0", Flag = "ESPOutlineTransparency", Callback = function(value) local num = tonumber(value) if num and num >= 0 and num <= 1 then VisualsConfig.OutlineTransparency = num updateESPProperties() end end })
local ESPTeamDropdown = OutlineSection:Dropdown({ Title = "Target Teams", Desc = "Select which teams to highlight. Leave empty to target all teams.", Icon = "shield", Values = getTeamNames(), Value = {}, Multi = true, AllowNone = true, Flag = "ESPTargetTeams", Callback = function(selected) VisualsConfig.TargetTeams = {} if type(selected) == "table" then for _, name in pairs(selected) do table.insert(VisualsConfig.TargetTeams, name) end elseif type(selected) == "string" and selected ~= "" then table.insert(VisualsConfig.TargetTeams, selected) end if VisualsConfig.Enabled then refreshESPTargets() end end })
Teams.ChildAdded:Connect(function(c) if c:IsA("Team") then task.wait(0.1); ESPTeamDropdown:Refresh(getTeamNames()) end end)
Teams.ChildRemoved:Connect(function(c) if c:IsA("Team") then VisualsConfig.TargetTeams = {}; ESPTeamDropdown:Refresh(getTeamNames()) end end)

local BoxSection = VisualsTab:Section({ Title = "Boxes ESP", Icon = "square-dashed", Box = false, Opened = true })
local HealthSection = VisualsTab:Section({ Title = "Health Bar", Icon = "heart-plus", Box = false, Opened = true })
local TracerSection = VisualsTab:Section({ Title = "Hostile Trace", Icon = "map-pin", Box = false, Opened = true })

local function createDrawings(p)
    if espDrawings[p] then return end
    local esp = {}
    esp.BoxOutline = Drawing.new("Square") esp.BoxOutline.Visible = false esp.BoxOutline.Color = Color3.fromRGB(0, 0, 0) esp.BoxOutline.Thickness = 3 esp.BoxOutline.Transparency = 1 esp.BoxOutline.Filled = false
    esp.Box = Drawing.new("Square") esp.Box.Visible = false esp.Box.Color = Color3.fromRGB(255, 255, 255) esp.Box.Thickness = 1 esp.Box.Transparency = 1 esp.Box.Filled = false
    esp.HealthOutline = Drawing.new("Square") esp.HealthOutline.Visible = false esp.HealthOutline.Color = Color3.fromRGB(0, 0, 0) esp.HealthOutline.Thickness = 1 esp.HealthOutline.Transparency = 1 esp.HealthOutline.Filled = true
    esp.HealthBar = Drawing.new("Square") esp.HealthBar.Visible = false esp.HealthBar.Color = Color3.fromRGB(0, 255, 0) esp.HealthBar.Thickness = 1 esp.HealthBar.Transparency = 1 esp.HealthBar.Filled = true
    esp.HealthText = Drawing.new("Text") esp.HealthText.Visible = false esp.HealthText.Color = Color3.fromRGB(255, 255, 255) esp.HealthText.Size = 13 esp.HealthText.Center = true esp.HealthText.Outline = true esp.HealthText.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.TracerOutline = Drawing.new("Line") esp.TracerOutline.Visible = false esp.TracerOutline.Color = Color3.fromRGB(0, 0, 0) esp.TracerOutline.Thickness = 3 esp.TracerOutline.Transparency = 1
    esp.Tracer = Drawing.new("Line") esp.Tracer.Visible = false esp.Tracer.Color = Color3.fromRGB(255, 0, 0) esp.Tracer.Thickness = 1 esp.Tracer.Transparency = 1
    espDrawings[p] = esp
end

local function removeDrawings(p)
    if espDrawings[p] then
        for _, d in pairs(espDrawings[p]) do pcall(function() d:Remove() end) end
        espDrawings[p] = nil
    end
end

local function updateRenderConnection()
    if BoxConfig.Enabled or HealthConfig.Enabled or TracerConfig.Enabled then
        if not renderConn then
            renderConn = RunService.RenderStepped:Connect(function()
                local viewportSize = camera.ViewportSize
                local tracerOrigin = Vector2.new(viewportSize.X / 2, viewportSize.Y)
                for p, esp in pairs(espDrawings) do
                    if p == player then continue end
                    local char = p.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local distance = (camera.CFrame.Position - hrp.Position).Magnitude
                            local sizeX = math.clamp(2000 / distance, 10, 300)
                            local sizeY = math.clamp(3000 / distance, 15, 450)
                            local boxPos = Vector2.new(screenPos.X - (sizeX / 2), screenPos.Y - (sizeY / 2))
                            if BoxConfig.Enabled then
                                esp.Box.Size = Vector2.new(sizeX, sizeY) esp.Box.Position = boxPos esp.Box.Thickness = BoxConfig.Thickness esp.Box.Visible = true
                                esp.BoxOutline.Size = Vector2.new(sizeX, sizeY) esp.BoxOutline.Position = boxPos esp.BoxOutline.Thickness = BoxConfig.OutlineThickness esp.BoxOutline.Visible = true
                            else esp.Box.Visible = false esp.BoxOutline.Visible = false end
                            if HealthConfig.Enabled then
                                local hum = char:FindFirstChildOfClass("Humanoid") local health = hum and hum.Health or 0 local maxHealth = hum and hum.MaxHealth or 100 local healthPercent = math.clamp(health / maxHealth, 0, 1)
                                local barWidth = 4 local barHeight = sizeY local barLeftOffset = 6 local barPos = Vector2.new(boxPos.X - barLeftOffset, boxPos.Y)
                                esp.HealthOutline.Size = Vector2.new(barWidth, barHeight) esp.HealthOutline.Position = barPos esp.HealthOutline.Visible = true
                                local currentBarHeight = barHeight * healthPercent esp.HealthBar.Size = Vector2.new(barWidth - 2, currentBarHeight - 2) esp.HealthBar.Position = Vector2.new(barPos.X + 1, barPos.Y + (barHeight - currentBarHeight) + 1) esp.HealthBar.Visible = health > 0
                                esp.HealthText.Text = string.format("%d", math.floor(health)) esp.HealthText.Position = Vector2.new(barPos.X - 10, barPos.Y + (barHeight - currentBarHeight) - 7) esp.HealthText.Visible = true
                            else esp.HealthOutline.Visible = false esp.HealthBar.Visible = false esp.HealthText.Visible = false end
                            if TracerConfig.Enabled then
                                if p.Team and p.Team.Name == "PATIENT" and p:GetAttribute("IsTagged") == true then
                                    local targetPoint = Vector2.new(screenPos.X, screenPos.Y)
                                    esp.TracerOutline.From = tracerOrigin esp.TracerOutline.To = targetPoint esp.TracerOutline.Visible = true
                                    esp.Tracer.From = tracerOrigin esp.Tracer.To = targetPoint esp.Tracer.Visible = true
                                else esp.TracerOutline.Visible = false esp.Tracer.Visible = false end
                            else esp.TracerOutline.Visible = false esp.Tracer.Visible = false end
                        else
                            esp.Box.Visible = false esp.BoxOutline.Visible = false esp.HealthOutline.Visible = false esp.HealthBar.Visible = false esp.HealthText.Visible = false esp.TracerOutline.Visible = false esp.Tracer.Visible = false
                        end
                    else
                        esp.Box.Visible = false esp.BoxOutline.Visible = false esp.HealthOutline.Visible = false esp.HealthBar.Visible = false esp.HealthText.Visible = false esp.TracerOutline.Visible = false esp.Tracer.Visible = false
                    end
                end
            end)
        end
    else
        if renderConn then
            renderConn:Disconnect()
            renderConn = nil
            for _, esp in pairs(espDrawings) do
                esp.Box.Visible = false esp.BoxOutline.Visible = false esp.HealthOutline.Visible = false esp.HealthBar.Visible = false esp.HealthText.Visible = false esp.TracerOutline.Visible = false esp.Tracer.Visible = false
            end
        end
    end
end

for _, p in ipairs(Players:GetPlayers()) do createDrawings(p) end
Players.PlayerAdded:Connect(function(p) createDrawings(p) end)
Players.PlayerRemoving:Connect(function(p) removeDrawings(p) end)

BoxSection:Toggle({ Title = "Enable Box ESP", Desc = "Draw a 2D box around every player on screen.", Icon = "square", Value = false, Flag = "BoxESPEnabled", Callback = function(state) BoxConfig.Enabled = state updateRenderConnection() end })
BoxSection:Input({ Title = "Box Thickness", Desc = "Thickness of the main box line (default: 1).", Placeholder = "Default: 1", Flag = "BoxThickness", Callback = function(value) local num = tonumber(value) if num and num > 0 then BoxConfig.Thickness = num end end })
BoxSection:Input({ Title = "Outline Thickness", Desc = "Thickness of the black outline around the box (default: 3).", Placeholder = "Default: 3", Flag = "BoxOutlineThickness", Callback = function(value) local num = tonumber(value) if num and num > 0 then BoxConfig.OutlineThickness = num end end })

HealthSection:Toggle({ Title = "Enable Health Bar", Desc = "Show a health bar beside each player's box.", Icon = "heart-pulse", Value = false, Flag = "HealthBarEnabled", Callback = function(state) HealthConfig.Enabled = state updateRenderConnection() end })

TracerSection:Toggle({ Title = "Trace Hostiles", Desc = "Draw a tracer line to tagged PATIENT team hostiles.", Icon = "map-pin", Value = false, Flag = "TracerEnabled", Callback = function(state) TracerConfig.Enabled = state updateRenderConnection() end })

local MovementTab = Window:Tab({ Title = "Movement", Icon = "gauge" })

local WalkSpeedSection = MovementTab:Section({ Title = "WalkSpeed Modifier", Icon = "footprints", Box = false, Opened = true })

local function applyWalkSpeed(char)
    if WalkSpeedConfig.Enabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = WalkSpeedConfig.Speed end
    end
end

local function startWalkSpeed()
    if walkSpeedConn then return end
    WalkSpeedConfig.Enabled = true
    if player.Character then applyWalkSpeed(player.Character) end
    walkSpeedConn = player.CharacterAdded:Connect(function(char) task.wait(0.5) applyWalkSpeed(char) end)
end

local function stopWalkSpeed()
    WalkSpeedConfig.Enabled = false
    if walkSpeedConn then walkSpeedConn:Disconnect(); walkSpeedConn = nil end
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

WalkSpeedSection:Toggle({
    Title    = "Activate WalkSpeed", Desc = "Toggle to apply your custom walk speed to your character.",
    Icon     = "fast-forward", Value = false, Flag = "WalkSpeedEnabled",
    Callback = function(state) if state then startWalkSpeed() else stopWalkSpeed() end end,
})

WalkSpeedSection:Input({
    Title       = "Speed", Desc = "Enter your desired walk speed (default: 16).",
    Placeholder = "Default: 16", Flag = "WalkSpeedValue",
    Callback    = function(value)
        local num = tonumber(value)
        if num and num >= 0 then WalkSpeedConfig.Speed = num if WalkSpeedConfig.Enabled and player.Character then applyWalkSpeed(player.Character) end
        elseif value == "" then WalkSpeedConfig.Speed = 16 if WalkSpeedConfig.Enabled and player.Character then applyWalkSpeed(player.Character) end end
    end,
})

local JumpSection = MovementTab:Section({ Title = "JumpPower Modification", Icon = "rabbit", Box = false, Opened = true })

local function performJitterJump(char)
    if isJumping or not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if humanoid and hrp and humanoid.FloorMaterial ~= Enum.Material.Air then
        isJumping = true
        local stepPower = JumpConfig.JumpHeight / JumpConfig.JitterSteps
        task.spawn(function()
            for i = 1, JumpConfig.JitterSteps do
                if hrp and hrp.Parent and hrp.AssemblyLinearVelocity then
                    local currentVel = hrp.AssemblyLinearVelocity
                    hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, currentVel.Y + stepPower, currentVel.Z)
                end
                task.wait(JumpConfig.JitterDelay)
            end
            isJumping = false
        end)
    end
end

local function onJumpCharAdded(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 0
        humanoid.JumpHeight = 0
    end
end

local function startJumpMod()
    JumpConfig.Enabled = true
    if isMobile then
        if not jumpGui then
            jumpGui = Instance.new("ScreenGui")
            jumpGui.Name = "OrcaHub_JumpUI"
            jumpGui.ResetOnSpawn = false
            jumpGui.Parent = player:WaitForChild("PlayerGui")
            
            jumpButton = Instance.new("TextButton")
            jumpButton.Size = UDim2.new(0, 90, 0, 90)
            jumpButton.Position = UDim2.new(1, -120, 1, -120)
            jumpButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            jumpButton.BackgroundTransparency = 0.5
            jumpButton.Text = "▲"
            jumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            jumpButton.TextTransparency = 0.2
            jumpButton.TextScaled = true
            jumpButton.Font = Enum.Font.GothamBold
            jumpButton.AutoButtonColor = true
            jumpButton.Parent = jumpGui
            
            local corner = Instance.new("UICorner", jumpButton)
            corner.CornerRadius = UDim.new(1, 0)
            local stroke = Instance.new("UIStroke", jumpButton)
            stroke.Thickness = 2; stroke.Color = Color3.fromRGB(255, 255, 255); stroke.Transparency = 0.3
            local pad = Instance.new("UIPadding", jumpButton)
            pad.PaddingTop = UDim.new(0.2, 0); pad.PaddingBottom = UDim.new(0.2, 0)
            pad.PaddingLeft = UDim.new(0.2, 0); pad.PaddingRight = UDim.new(0.2, 0)
            
            jumpButton.Activated:Connect(function()
                performJitterJump(player.Character)
            end)
        end
        jumpGui.Enabled = true
    else
        if not jumpInputConn then
            jumpInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end 
                if input.KeyCode == Enum.KeyCode.Space then
                    performJitterJump(player.Character)
                end
            end)
        end
    end
    
    if player.Character then onJumpCharAdded(player.Character) end
    jumpCharConn = player.CharacterAdded:Connect(onJumpCharAdded)
end

local function stopJumpMod()
    JumpConfig.Enabled = false
    if jumpInputConn then jumpInputConn:Disconnect(); jumpInputConn = nil end
    if jumpCharConn then jumpCharConn:Disconnect(); jumpCharConn = nil end
    if jumpGui then jumpGui.Enabled = false end
    
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = 50
            hum.JumpHeight = 7.2
        end
    end
end

JumpSection:Toggle({
    Title    = "Activate JumpPower", Desc = "Toggle to apply the custom jitter jump system.",
    Icon     = "rabbit", Value = false, Flag = "JumpEnabled",
    Callback = function(state)
        if state then startJumpMod() else stopJumpMod() end
    end,
})

JumpSection:Input({
    Title       = "Jump Height", Desc = "The total upward velocity to apply (default: 50).",
    Placeholder = "Default: 50", Flag = "JumpHeightValue",
    Callback    = function(value)
        local num = tonumber(value)
        if num and num > 0 then JumpConfig.JumpHeight = num end
    end,
})

JumpSection:Input({
    Title       = "Jitter Steps", Desc = "How many times to split the jump into (default: 5).",
    Placeholder = "Default: 5", Flag = "JitterStepsValue",
    Callback    = function(value)
        local num = tonumber(value)
        if num and num > 0 then JumpConfig.JitterSteps = math.floor(num) end
    end,
})

JumpSection:Input({
    Title       = "Jitter Delay", Desc = "Delay between jitter steps in seconds (default: 0.01).",
    Placeholder = "Default: 0.01", Flag = "JitterDelayValue",
    Callback    = function(value)
        local num = tonumber(value)
        if num and num >= 0 then JumpConfig.JitterDelay = num end
    end,
})

local TpwalkSection = MovementTab:Section({ Title = "Tpwalk Modification", Icon = "hand-fist", Box = false, Opened = true })

local function startTpwalk()
    if TpwalkConfig.Enabled then return end
    TpwalkConfig.Enabled = true
    
    local function updateRefs(char)
        tpChar = char
        tpHum = char:WaitForChild("Humanoid", 5)
        tpRoot = char:WaitForChild("HumanoidRootPart", 5)
    end

    if player.Character then updateRefs(player.Character) end
    
    tpwalkCharAdded = player.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        updateRefs(char)
    end)
    
    tpwalkCharRemoving = player.CharacterRemoving:Connect(function()
        tpChar, tpHum, tpRoot = nil, nil, nil
    end)

    RunService:BindToRenderStep(tpwalkRenderName, Enum.RenderPriority.Camera.Value - 1, function(dt)
        if not (tpChar and tpHum and tpRoot) then return end
        local camCF = camera.CFrame
        local moveVel = tpHum:GetMoveVelocity()
        local camMove = camCF:VectorToObjectSpace(moveVel)
        local worldMove = camCF:VectorToWorldSpace(camMove)
        tpRoot.CFrame = tpRoot.CFrame + worldMove * dt * TpwalkConfig.Speed
    end)
end

local function stopTpwalk()
    TpwalkConfig.Enabled = false
    pcall(function() RunService:UnbindFromRenderStep(tpwalkRenderName) end)
    if tpwalkCharAdded then tpwalkCharAdded:Disconnect(); tpwalkCharAdded = nil end
    if tpwalkCharRemoving then tpwalkCharRemoving:Disconnect(); tpwalkCharRemoving = nil end
    tpChar, tpHum, tpRoot = nil, nil, nil
end

TpwalkSection:Toggle({
    Title    = "Activate Tpwalk",
    Desc     = "Toggle to teleport your character smoothly in the movement direction.",
    Icon     = "hand-fist",
    Value    = false,
    Flag     = "TpwalkEnabled",
    Callback = function(state)
        if state then startTpwalk() else stopTpwalk() end
    end,
})

TpwalkSection:Input({
    Title       = "Speed",
    Desc        = "Movement speed multiplier for Tpwalk (default: 1).",
    Placeholder = "Default: 1",
    Flag        = "TpwalkSpeed",
    Callback    = function(value)
        local num = tonumber(value)
        if num and num > 0 then 
            TpwalkConfig.Speed = num 
        elseif value == "" then 
            TpwalkConfig.Speed = 1 
        end
    end,
})

local LocalPlayerSection = MovementTab:Section({ Title = "Local Player", Icon = "leaf", Box = false, Opened = true })

local function startStamina()
    if StaminaConfig.Enabled then return end
    StaminaConfig.Enabled = true
    
    pcall(function()
        local movementShared = require(ReplicatedStorage:WaitForChild("Features", 5):WaitForChild("Movement", 5):WaitForChild("MovementShared", 5))
        local v5 = require(ReplicatedStorage:WaitForChild("Service", 5):WaitForChild("Namespaces", 5))
        local replicateMovement = v5.GeneralReplication.packets.replicateMovement
        
        origPlayerHasEnergy = movementShared.playerHasEnergy
        origGetPlayerEnergy = movementShared.getPlayerEnergy
        origSPRINT_MINIMUM_ENERGY = movementShared.SPRINT_MINIMUM_ENERGY
        origSend = replicateMovement.send
        
        movementShared.playerHasEnergy = function() return true end
        movementShared.getPlayerEnergy = function() return 999999 end
        movementShared.SPRINT_MINIMUM_ENERGY = 0
        
        replicateMovement.send = function(dataTable)
            if type(dataTable) == "table" then
                dataTable[1] = true
                dataTable[2] = true
                dataTable[3] = true
            end
            return origSend(dataTable)
        end
        
        staminaConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                movementShared.setPlayerEnergy(999999)
                movementShared.incrementEnergy(999999)
                movementShared.setPlayerMaximumEnergy(999999)
            end)
        end)
    end)
end

local function stopStamina()
    StaminaConfig.Enabled = false
    if staminaConn then staminaConn:Disconnect(); staminaConn = nil end
    
    pcall(function()
        local movementShared = require(ReplicatedStorage:FindFirstChild("Features"):FindFirstChild("Movement"):FindFirstChild("MovementShared"))
        local v5 = require(ReplicatedStorage:FindFirstChild("Service"):FindFirstChild("Namespaces"))
        local replicateMovement = v5.GeneralReplication.packets.replicateMovement
        
        if origPlayerHasEnergy then movementShared.playerHasEnergy = origPlayerHasEnergy end
        if origGetPlayerEnergy then movementShared.getPlayerEnergy = origGetPlayerEnergy end
        if origSPRINT_MINIMUM_ENERGY then movementShared.SPRINT_MINIMUM_ENERGY = origSPRINT_MINIMUM_ENERGY end
        if origSend then replicateMovement.send = origSend end
    end)
end

LocalPlayerSection:Toggle({
    Title    = "Infinite Stamina",
    Desc     = "Permanently overrides the sprint energy system so you never run out of stamina.",
    Icon     = "battery-charging",
    Value    = false,
    Flag     = "StaminaEnabled",
    Callback = function(state)
        if state then startStamina() else stopStamina() end
    end,
})

local function startNoclip()
    if NoclipConfig.Enabled then return end
    NoclipConfig.Enabled = true
    
    noclipConn = RunService.Stepped:Connect(function()
        local char = player.Character
        if char then
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
    end)
end

local function stopNoclip()
    NoclipConfig.Enabled = false
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    
    local char = player.Character
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                v.CanCollide = true
            end
        end
    end
end

LocalPlayerSection:Toggle({
    Title    = "Activate Noclip",
    Desc     = "Walk through walls and terrain.",
    Icon     = "ghost",
    Value    = false,
    Flag     = "NoclipEnabled",
    Callback = function(state)
        if state then startNoclip() else stopNoclip() end
    end,
})

local function startFloat()
    if FloatConfig.Enabled then return end
    FloatConfig.Enabled = true
    
    if workspace:FindFirstChild(floatName) then
        workspace[floatName]:Destroy()
    end

    floatPlatform = Instance.new("Part")
    floatPlatform.Name = floatName
    floatPlatform.Size = Vector3.new(10, 0.5, 10)
    floatPlatform.Color = Color3.fromRGB(0, 255, 255)
    floatPlatform.Transparency = 0.85
    floatPlatform.Material = Enum.Material.ForceField
    floatPlatform.Anchored = true
    floatPlatform.CanCollide = true
    floatPlatform.Parent = workspace

    local function setupChar(char)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if root then
            currentFloatHeight = root.Position.Y - 3.25
        end
    end

    if player.Character then setupChar(player.Character) end
    floatCharConn = player.CharacterAdded:Connect(setupChar)

    floatConn = RunService.RenderStepped:Connect(function()
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and floatPlatform and floatPlatform.Parent then
                local velY = root.AssemblyLinearVelocity.Y
                if velY > 0.1 then
                    currentFloatHeight = root.Position.Y - 3.25
                end
                floatPlatform.CFrame = CFrame.new(root.Position.X, currentFloatHeight, root.Position.Z)
            end
        end
    end)
end

local function stopFloat()
    FloatConfig.Enabled = false
    if floatConn then floatConn:Disconnect(); floatConn = nil end
    if floatCharConn then floatCharConn:Disconnect(); floatCharConn = nil end
    if floatPlatform then floatPlatform:Destroy(); floatPlatform = nil end
    if workspace:FindFirstChild(floatName) then
        workspace[floatName]:Destroy()
    end
end

LocalPlayerSection:Toggle({
    Title    = "Activate Float",
    Desc     = "Summon a transparent platform beneath you that keeps you floating.",
    Icon     = "cloud",
    Value    = false,
    Flag     = "FloatEnabled",
    Callback = function(state)
        if state then startFloat() else stopFloat() end
    end,
})

-- ============================================================
-- SIDEBAR SECTION: Teams
-- ============================================================
Window:Section({ Title = "Teams" })

local OrderlyTab = Window:Tab({ Title = "Orderly", Icon = "shield" })

-- ── Section: Silent Aim ───────────────────────────────────
local SilentAimSection = OrderlyTab:Section({ Title = "Silent Aim", Icon = "ear-off", Box = false, Opened = true })

-- Shared Silent Aim Logic
local PatientTeam = Teams:FindFirstChild("PATIENT")
if not PatientTeam then
    task.spawn(function()
        PatientTeam = Teams:WaitForChild("PATIENT", 10)
    end)
end

local function isHostilePatient(p)
    if not p or p == player then return false end
    if not PatientTeam or p.Team ~= PatientTeam then return false end
    if p:GetAttribute("IsTagged") ~= true then return false end
    local char = p.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not root then return false end
    return true
end

local function getClosestHostile(maxDist)
    local closest = nil
    local shortest = maxDist or 300
    local myChar = player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, p in ipairs(Players:GetPlayers()) do
        if isHostilePatient(p) then
            local root = p.Character.HumanoidRootPart
            local dist = (myRoot.Position - root.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = root
            end
        end
    end
    return closest
end

-- Shared Hook Engine (Optimized to prevent double hooks)
local engineHooked = false
local oldGetMouseHit = nil
local oldIndex = nil
local rawMeta = nil

local function silentAimActive()
    return TaserConfig.Enabled or PepperConfig.Enabled
end

local function hookEngine()
    if engineHooked then return end
    engineHooked = true

    pcall(function()
        oldGetMouseHit = hookfunction(UserInputService.GetMouseHit, function(self, ...)
            if silentAimActive() then
                local part = getClosestHostile(300)
                if part then return CFrame.new(part.Position) end
            end
            return oldGetMouseHit(self, ...)
        end)
    end)

    pcall(function()
        rawMeta = getrawmetatable(game)
        if setreadonly then setreadonly(rawMeta, false) end
        oldIndex = rawMeta.__index
        rawMeta.__index = newcclosure(function(self, key)
            if silentAimActive() and (key == "Hit" or key == "hit") and self:IsA("Mouse") then
                local part = getClosestHostile(300)
                if part then return CFrame.new(part.Position) end
            end
            return oldIndex(self, key)
        end)
        if setreadonly then setreadonly(rawMeta, true) end
    end)
end

-- Peppergun Custom Module Hook
local pepperCustomHooked = false
local oldCustomGetMouseHit = nil

local function hookPepperCustom()
    if pepperCustomHooked then return end
    pepperCustomHooked = true
    task.spawn(function()
        local serviceFolder = ReplicatedStorage:WaitForChild("Service", 10)
        if serviceFolder then
            local customUISModule = serviceFolder:WaitForChild("UserInputService", 5)
            if customUISModule then
                local customUIS = require(customUISModule)
                if customUIS and customUIS.GetMouseHit then
                    oldCustomGetMouseHit = customUIS.GetMouseHit
                    customUIS.GetMouseHit = function(...)
                        if PepperConfig.Enabled then
                            local part = getClosestHostile(300)
                            if part then return CFrame.new(part.Position) end
                        end
                        return oldCustomGetMouseHit(...)
                    end
                end
            end
        end
    end)
end

-- Taser Toggle
SilentAimSection:Toggle({
    Title    = "Taser Silent Aim",
    Desc     = "Silently redirect taser shots to the closest hostile PATIENT.",
    Icon     = "zap",
    Value    = false,
    Flag     = "TaserSilentAimEnabled",
    Callback = function(state)
        TaserConfig.Enabled = state
        if state then hookEngine() end
    end,
})

-- Peppergun Toggle
SilentAimSection:Toggle({
    Title    = "Peppergun Silent Aim",
    Desc     = "Silently redirect peppergun shots to the closest hostile PATIENT.",
    Icon     = "flame",
    Value    = false,
    Flag     = "PepperSilentAimEnabled",
    Callback = function(state)
        PepperConfig.Enabled = state
        if state then 
            hookEngine()
            hookPepperCustom()
        end
    end,
})

-- ── Section: Taser Rifle ──────────────────────────────────
local RifleSection = OrderlyTab:Section({ Title = "Taser Rifle", Icon = "bow-arrow", Box = false, Opened = true })

local function hookRifle()
    if rifleHooked then return end
    rifleHooked = true
    
    local function applyPrediction(args)
        if TaserRifleConfig.Enabled then
            local target = getClosestHostile(TaserRifleConfig.MaxDistance)
            if target then
                local head = player.Character and player.Character:FindFirstChild("Head")
                if head then
                    if TaserRifleConfig.FireDelay > 0 then
                        task.wait(TaserRifleConfig.FireDelay)
                    end
                    local targetPos = target.Position
                    local velocity = target.AssemblyLinearVelocity
                    local targetHum = target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
                    if targetHum and targetHum.FloorMaterial ~= Enum.Material.Air then
                        velocity = Vector3.new(velocity.X, 0, velocity.Z)
                    end
                    local distance = (head.Position - targetPos).Magnitude
                    local travelTime = (distance / TaserRifleConfig.ProjectileSpeed) + TaserRifleConfig.PingCompensation
                    targetPos = targetPos + (velocity * travelTime)
                    args[1] = (targetPos - head.Position).Unit
                end
            end
        end
        return args
    end

    pcall(function()
        oldRifleFire = hookfunction(RifleFireEvent.FireServer, function(self, ...)
            local args = applyPrediction({...})
            return oldRifleFire(self, unpack(args))
        end)
    end)
end

RifleSection:Toggle({
    Title    = "Taser Rifle Silent Aim",
    Desc     = "Hooks the Taser Rifle fire event to redirect shots with prediction.",
    Icon     = "crosshair",
    Value    = false,
    Flag     = "TaserRifleSilentAimEnabled",
    Callback = function(state)
        TaserRifleConfig.Enabled = state
        if state then hookRifle() end
    end,
})

RifleSection:Input({
    Title       = "Max Distance",
    Desc        = "Maximum range to acquire a target (default: 300).",
    Placeholder = "Default: 300",
    Flag        = "TaserRifleMaxDistance",
    Callback    = function(value)
        local num = tonumber(value)
        if num and num > 0 then TaserRifleConfig.MaxDistance = num end
    end,
})

RifleSection:Input({
    Title       = "Projectile Speed",
    Desc        = "Speed of the projectile for prediction (default: 1500).",
    Placeholder = "Default: 1500",
    Flag        = "TaserRifleProjectileSpeed",
    Callback    = function(value)
        local num = tonumber(value)
        if num and num > 0 then TaserRifleConfig.ProjectileSpeed = num end
    end,
})

RifleSection:Input({
    Title       = "Ping Compensation",
    Desc        = "Delay added to travel time for network ping (default: 0.05).",
    Placeholder = "Default: 0.05",
    Flag        = "TaserRiflePingComp",
    Callback    = function(value)
        local num = tonumber(value)
        if num and num >= 0 then TaserRifleConfig.PingCompensation = num end
    end,
})

RifleSection:Input({
    Title       = "Fire Delay",
    Desc        = "Seconds to wait after clicking before firing (default: 0).",
    Placeholder = "Default: 0",
    Flag        = "TaserRifleFireDelay",
    Callback    = function(value)
        local num = tonumber(value)
        if num and num >= 0 then TaserRifleConfig.FireDelay = num end
    end,
})

local EPUTab = Window:Tab({ Title = "EPU", Icon = "shield-check" })

-- ── Section: Work in Progress ─────────────────────────────
local EPUSection = EPUTab:Section({ Title = "Work in Progress", Icon = "briefcase-business", Box = false, Opened = true })
EPUSection:Paragraph({ Title = "Coming Soon", Desc = "We're going to add more awesome features for this tab someday soon." })

local PatientTab = Window:Tab({ Title = "Patient", Icon = "square-user-round" })
local MedicalTab = Window:Tab({ Title = "Medical", Icon = "pill" })

-- ============================================================
-- CONFIG LOAD & CLEANUP
-- ============================================================
task.spawn(function()
    task.wait(1)
    if Window.ConfigManager then
        local OrcaConfig = Window.ConfigManager:CreateConfig("OrcaHub")
        pcall(function() OrcaConfig:Load() end)
        task.wait(0.2)
        updateRenderConnection()
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if p == player then
        pcall(function()
            if AimbotConfig.Enabled then stopMobileAimbot(); removeMobileButton() end
            if PCAimbotConfig.Enabled then stopPCAimbot(); removePCCrosshair() end
            if ReachConfig.Enabled then stopReach() end
            if VisualsConfig.Enabled then stopESP() end
            if renderConn then renderConn:Disconnect(); renderConn = nil end
            if WalkSpeedConfig.Enabled then stopWalkSpeed() end
            if JumpConfig.Enabled then stopJumpMod() end
            if TpwalkConfig.Enabled then stopTpwalk() end
            if StaminaConfig.Enabled then stopStamina() end
            if NoclipConfig.Enabled then stopNoclip() end
            if FloatConfig.Enabled then stopFloat() end
        end)
    else
        if espConnections[p] then
            for _, c in ipairs(espConnections[p]) do c:Disconnect() end
            espConnections[p] = nil
        end
        removeESP(p)
        removeDrawings(p)
    end
end)

Players.PlayerAdded:Connect(function(p)
    if VisualsConfig.Enabled then setupESPPlayer(p) end
    createDrawings(p)
end)
