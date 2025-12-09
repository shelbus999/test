local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

if isMobile then
    local library = loadstring(readfile("informant.wtf Lib Source.lua"))(); library:init()
    
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local plr = Players.LocalPlayer

    getgenv().SecureMode = true

    local mechMod = ReplicatedStorage:FindFirstChild("Assets") 
        and ReplicatedStorage.Assets:FindFirstChild("Modules") 
        and ReplicatedStorage.Assets.Modules:FindFirstChild("Client") 
        and ReplicatedStorage.Assets.Modules.Client:FindFirstChild("Mechanics")
    
    if mechMod then
        mechMod = require(mechMod)
    end

    local ConnectionManager = {}
    ConnectionManager.connections = {}

    function ConnectionManager:Add(name, connection)
        if self.connections[name] then
            self.connections[name]:Disconnect()
        end
        self.connections[name] = connection
    end

    function ConnectionManager:Remove(name)
        if self.connections[name] then
            self.connections[name]:Disconnect()
            self.connections[name] = nil
        end
    end

    function ConnectionManager:CleanupAll()
        for name, conn in pairs(self.connections) do
            if conn then
                conn:Disconnect()
            end
        end
        self.connections = {}
    end

    local pullVectorEnabled = false
    local smoothPullEnabled = false
    local isPullingBall = false
    local isSmoothPulling = false
    local walkSpeedEnabled = false
    local jumpPowerEnabled = false
    local bigheadEnabled = false
    local tackleReachEnabled = false
    local playerHitboxEnabled = false
    local jumpBoostEnabled = false
    local jumpBoostTradeMode = false
    local diveBoostEnabled = false
    local autoFollowBallCarrierEnabled = false
    local pullButtonActive = false
    local legPullButtonActive = false
    local dragButtonsEnabled = false
    local CanDiveBoost = true
    local CanBoost = true
    local isSprinting = false
    
    local offsetDistance = 15
    local magnetSmoothness = 0.20
    local customWalkSpeed = 25
    local customJumpPower = 50
    local bigheadSize = 1
    local bigheadTransparency = 0.5
    local tackleReachDistance = 5
    local playerHitboxSize = 5
    local maxPullDistance = 35
    local autoFollowBlatancy = 0.5
    local BOOST_FORCE_Y = 32
    local BALL_DETECTION_RADIUS = 10
    local BOOST_COOLDOWN = 1
    local DIVE_BOOST_POWER = 15
    local DIVE_BOOST_COOLDOWN = 2

    local jumpConnection = nil
    local bigheadConnection = nil
    local tackleReachConnection = nil
    local playerHitboxConnection = nil
    local walkSpeedConnection = nil
    local autoFollowConnection = nil
    local mobileInputMethod = "Buttons" 
    local isParkMatch = Workspace:FindFirstChild("ParkMatchMap") ~= nil

    local character = plr.Character or plr.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    local head = character:WaitForChild("Head")
    local defaultHeadSize = head.Size
    local defaultHeadTransparency = head.Transparency

    local function onCharacterAdded(char)
        character = char
        humanoidRootPart = char:WaitForChild("HumanoidRootPart")
        humanoid = char:WaitForChild("Humanoid")
        head = char:WaitForChild("Head")
        defaultHeadSize = head.Size
        defaultHeadTransparency = head.Transparency
    end

    ConnectionManager:Add("CharacterAdded", plr.CharacterAdded:Connect(onCharacterAdded))

    local function getFootball()
        local parkMap = Workspace:FindFirstChild("ParkMap")
        if parkMap and parkMap:FindFirstChild("Replicated") then
            local fields = parkMap.Replicated:FindFirstChild("Fields")
            if fields then
                local parkFields = {
                    fields:FindFirstChild("LeftField"),
                    fields:FindFirstChild("RightField"),
                    fields:FindFirstChild("BLeftField"),
                    fields:FindFirstChild("BRightField"),
                    fields:FindFirstChild("HighField"),
                    fields:FindFirstChild("TLeftField"),
                    fields:FindFirstChild("TRightField")
                }
                
                for _, field in ipairs(parkFields) do
                    if field and field:FindFirstChild("Replicated") then
                        local football = field.Replicated:FindFirstChild("Football")
                        if football and football:IsA("BasePart") then 
                            return football 
                        end
                    end
                end
            end
        end
        
        if isParkMatch then
            local parkMatchFootball = Workspace:FindFirstChild("ParkMatchMap")
            if parkMatchFootball and parkMatchFootball:FindFirstChild("Replicated") then
                parkMatchFootball = parkMatchFootball.Replicated:FindFirstChild("Fields")
                if parkMatchFootball and parkMatchFootball:FindFirstChild("MatchField") then
                    parkMatchFootball = parkMatchFootball.MatchField:FindFirstChild("Replicated")
                    if parkMatchFootball then
                        local football = parkMatchFootball:FindFirstChild("Football")
                        if football and football:IsA("BasePart") then return football end
                    end
                end
            end
        end
        
        local gamesFolder = Workspace:FindFirstChild("Games")
        if gamesFolder then
            for _, gameInstance in ipairs(gamesFolder:GetChildren()) do
                local replicatedFolder = gameInstance:FindFirstChild("Replicated")
                if replicatedFolder then
                    local kickoffFootball = replicatedFolder:FindFirstChild("918f5408-d86a-4fb8-a88c-5cab57410acf")
                    if kickoffFootball and kickoffFootball:IsA("BasePart") then return kickoffFootball end
                    for _, item in ipairs(replicatedFolder:GetChildren()) do
                        if item:IsA("BasePart") and item.Name == "Football" then return item end
                    end
                end
            end
        end
        return nil
    end

    local function getBallCarrier()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= plr and player.Character then
                local football = player.Character:FindFirstChild("Football")
                if football then
                    return player
                end
            end
        end
        return nil
    end

    local function teleportToBall()
        local ball = getFootball()
        if ball and humanoidRootPart then
            if Workspace:FindFirstChild("ParkMap") then
                local distance = (ball.Position - humanoidRootPart.Position).Magnitude
                
                if distance > maxPullDistance then
                    return
                end
            end
            
            local ballVelocity = ball.Velocity
            local ballPosition = ball.Position
            local direction = ballVelocity.Unit
            local targetPosition = ballPosition + (direction * 12) - Vector3.new(0, 1.5, 0) + Vector3.new(0, 5.197499752044678 / 6, 0)
            local lookDirection = (ballPosition - humanoidRootPart.Position).Unit
            humanoidRootPart.CFrame = CFrame.new(targetPosition, targetPosition + lookDirection)
        end
    end

    local function smoothTeleportToBall()
        local ball = getFootball()
        if ball and humanoidRootPart then
            if Workspace:FindFirstChild("ParkMap") then
                local distance = (ball.Position - humanoidRootPart.Position).Magnitude
                if distance > maxPullDistance then return end
            end
            
            local ballVelocity = ball.Velocity
            local ballSpeed = ballVelocity.Magnitude
            local offset = (ballSpeed > 0) and (ballVelocity.Unit * offsetDistance) or Vector3.new(0, 0, 0)
            local targetPosition = ball.Position + offset + Vector3.new(0, 3, 0)
            local lookDirection = (ball.Position - humanoidRootPart.Position).Unit
            humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(CFrame.new(targetPosition, targetPosition + lookDirection), magnetSmoothness)
        end
    end

    local function applyJumpBoost(rootPart)
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, BOOST_FORCE_Y, 0)
        bv.MaxForce = Vector3.new(0, math.huge, 0)
        bv.P = 5000
        bv.Parent = rootPart
        game:GetService("Debris"):AddItem(bv, 0.2)
    end

    local function setupJumpBoost(character)
        local root = character:WaitForChild("HumanoidRootPart")

        ConnectionManager:Add("JumpBoostTouch", root.Touched:Connect(function(hit)
            if not jumpBoostEnabled or not CanBoost then return end
            if root.Velocity.Y >= -2 then return end

            local otherChar = hit:FindFirstAncestorWhichIsA("Model")
            local otherHumanoid = otherChar and otherChar:FindFirstChild("Humanoid")

            if otherChar and otherChar ~= character and otherHumanoid then
                if jumpBoostTradeMode then
                    CanBoost = false
                    applyJumpBoost(root)
                    task.delay(BOOST_COOLDOWN, function()
                        CanBoost = true
                    end)
                else
                    local football = getFootball()
                    if football then
                        local distance = (football.Position - root.Position).Magnitude
                        if distance <= BALL_DETECTION_RADIUS then
                            CanBoost = false
                            applyJumpBoost(root)
                            task.delay(BOOST_COOLDOWN, function()
                                CanBoost = true
                            end)
                        end
                    end
                end
            end
        end))
    end

    local function updateDivePower()
        if not diveBoostEnabled then return end
        
        local gameId = plr:FindFirstChild("Replicated") and plr.Replicated:FindFirstChild("GameID")
        if not gameId then return end
        
        local gid = gameId.Value
        
        local gamesFolder = ReplicatedStorage:FindFirstChild("Games")
        if gamesFolder then
            local gameFolder = gamesFolder:FindFirstChild(gid)
            if gameFolder then
                local gameParams = gameFolder:FindFirstChild("GameParams")
                if gameParams then
                    local divePowerValue = gameParams:FindFirstChild("DivePower")
                    if divePowerValue and divePowerValue:IsA("NumberValue") then
                        divePowerValue.Value = diveBoostPower
                    end
                end
            end
        end
        
        local miniGamesFolder = ReplicatedStorage:FindFirstChild("MiniGames")
        if miniGamesFolder then
            local gameFolder = miniGamesFolder:FindFirstChild(gid)
            if gameFolder then
                local gameParams = gameFolder:FindFirstChild("GameParams")
                if gameParams then
                    local divePowerValue = gameParams:FindFirstChild("DivePower")
                    if divePowerValue and divePowerValue:IsA("NumberValue") then
                        divePowerValue.Value = diveBoostPower
                    end
                end
            end
        end
    end

    local pullButtonGui = Instance.new("ScreenGui")
    pullButtonGui.Name = "PullButtonGui"
    pullButtonGui.ResetOnSpawn = false
    pullButtonGui.Parent = plr:WaitForChild("PlayerGui")
    
    local pullContainer = Instance.new("Frame")
    pullContainer.Name = "PullContainer"
    pullContainer.Size = UDim2.new(0, 100, 0, 100)
    pullContainer.Position = UDim2.new(0.85, 0, 0.7, 0)
    pullContainer.BackgroundTransparency = 1
    pullContainer.Active = true
    pullContainer.Draggable = false
    pullContainer.Parent = pullButtonGui
    
    local pullButton = Instance.new("TextButton")
    pullButton.Size = UDim2.new(0, 70, 0, 70)
    pullButton.Position = UDim2.new(0, 15, 0, 15)
    pullButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    pullButton.BorderSizePixel = 0
    pullButton.Text = "Pull"
    pullButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    pullButton.Font = Enum.Font.GothamBold
    pullButton.TextSize = 16
    pullButton.Parent = pullContainer
    
    local pullCorner = Instance.new("UICorner")
    pullCorner.CornerRadius = UDim.new(1, 0)
    pullCorner.Parent = pullButton
    
    local legPullContainer = Instance.new("Frame")
    legPullContainer.Size = UDim2.new(0, 100, 0, 100)
    legPullContainer.Position = UDim2.new(0.85, 0, 0.55, 0)
    legPullContainer.BackgroundTransparency = 1
    legPullContainer.Active = true
    legPullContainer.Draggable = false
    legPullContainer.Parent = pullButtonGui
    
    local legPullButton = Instance.new("TextButton")
    legPullButton.Size = UDim2.new(0, 70, 0, 70)
    legPullButton.Position = UDim2.new(0, 15, 0, 15)
    legPullButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    legPullButton.BorderSizePixel = 0
    legPullButton.Text = "Legit"
    legPullButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    legPullButton.Font = Enum.Font.GothamBold
    legPullButton.TextSize = 16
    legPullButton.Parent = legPullContainer
    
    local legPullCorner = Instance.new("UICorner")
    legPullCorner.CornerRadius = UDim.new(1, 0)
    legPullCorner.Parent = legPullButton
    
    pullButton.MouseButton1Down:Connect(function()
        if pullVectorEnabled then
            isPullingBall = true
            pullButtonActive = true
            pullButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
            spawn(function()
                while isPullingBall and pullVectorEnabled do
                    teleportToBall()
                    wait(0.05)
                end
            end)
        end
    end)
    
    pullButton.MouseButton1Up:Connect(function()
        isPullingBall = false
        pullButtonActive = false
        pullButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)
    
    legPullButton.MouseButton1Down:Connect(function()
        if smoothPullEnabled then
            isSmoothPulling = true
            legPullButtonActive = true
            legPullButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
            spawn(function()
                while legPullButtonActive and smoothPullEnabled do
                    smoothTeleportToBall()
                    wait(0.01)
                end
            end)
        end
    end)
    
    legPullButton.MouseButton1Up:Connect(function()
        isSmoothPulling = false
        legPullButtonActive = false
        legPullButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)
    
    UserInputService.TouchEnded:Connect(function(touch, gameProcessed)
        if pullButtonActive then
            isPullingBall = false
            pullButtonActive = false
            pullButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
        if legPullButtonActive then
            isSmoothPulling = false
            legPullButtonActive = false
            legPullButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if pullVectorEnabled then
            pullButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            pullButton.Text = "Pull âœ“"
        elseif not pullButtonActive then
            pullButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            pullButton.Text = "Pull"
        end
        
        if smoothPullEnabled then
            legPullButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            legPullButton.Text = "Legit âœ“"
        elseif not legPullButtonActive then
            legPullButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            legPullButton.Text = "Legit"
        end
        
        if mobileInputMethod == "Tapping" then
            pullButton.Visible = false
            legPullButton.Visible = false
        elseif mobileInputMethod == "Buttons" or mobileInputMethod == "Both" then
            pullButton.Visible = pullVectorEnabled
            legPullButton.Visible = smoothPullEnabled
        end
    end)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonR2 then
            if pullVectorEnabled then
                isPullingBall = true
                pullButtonActive = true
                pullButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
                spawn(function()
                    while isPullingBall and pullVectorEnabled do
                        teleportToBall()
                        wait(0.05)
                    end
                end)
            end
            if smoothPullEnabled then
                isSmoothPulling = true
                legPullButtonActive = true
                legPullButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
                spawn(function()
                    while legPullButtonActive and smoothPullEnabled do
                        smoothTeleportToBall()
                        wait(0.01)
                    end
                end)
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonR2 then
            if pullButtonActive then
                isPullingBall = false
                pullButtonActive = false
                pullButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            end
            if legPullButtonActive then
                isSmoothPulling = false
                legPullButtonActive = false
                legPullButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            end
        end
    end)
    
    local function getPlayerTeam(player)
        local menuGui = plr:FindFirstChild("PlayerGui") -- Use local player's GUI
        if menuGui then
            local menu = menuGui:FindFirstChild("Menu")
            if menu then
                local basis = menu:FindFirstChild("Basis")
                if basis then
                    local window = basis:FindFirstChild("Window")
                    if window then
                        local addFriends = window:FindFirstChild("AddFriends")
                        if addFriends then
                            local frame = addFriends:FindFirstChild("Basis")
                            if frame then
                                frame = frame:FindFirstChild("Frame")
                                if frame then
                                    local homeTeam = frame:FindFirstChild("HomeTeam")
                                    local awayTeam = frame:FindFirstChild("AwayTeam")
                                    
                                    -- Check if the player is in HomeTeam
                                    if homeTeam and homeTeam:FindFirstChild("Frame") then
                                        if homeTeam.Frame:FindFirstChild(player.Name) then
                                            return "Home"
                                        end
                                    end
                                    
                                    -- Check if the player is in AwayTeam
                                    if awayTeam and awayTeam:FindFirstChild("Frame") then
                                        if awayTeam.Frame:FindFirstChild(player.Name) then
                                            return "Away"
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    local Window = library.NewWindow({
        title = "Kali Hub | NFL Universe [Mobile]",
        size = UDim2.new(0, 525, 0, 650),
        position = UDim2.new(0, 250, 0, 150)
    })
    Window:SetOpen(true)
    
    local MainTab = Window:AddTab("âš¡ Main", 1)
    
    local ButtonSection = MainTab:AddSection("Button Controls", 1, 1)
    
    ButtonSection:AddToggle({
        text = "Draggable Buttons",
        value = false,
        flag = "DragButtons",
        callback = function(Value)
            dragButtonsEnabled = Value
            
            pullContainer.Draggable = Value
            legPullContainer.Draggable = Value
            
            if Value then
                pullContainer.BackgroundTransparency = 0.8
                pullContainer.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                legPullContainer.BackgroundTransparency = 0.8
                legPullContainer.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            else
                pullContainer.BackgroundTransparency = 1
                legPullContainer.BackgroundTransparency = 1
            end
        end,
    })
    
    ButtonSection:AddList({
        text = "Mobile Input Method",
        values = {"Buttons", "Tapping", "Both"},
        value = "Buttons",
        flag = "InputMethod",
        callback = function(Option)
            mobileInputMethod = Option
            
            if mobileInputMethod == "Tapping" then
                pullButton.Visible = false
                legPullButton.Visible = false
            elseif mobileInputMethod == "Buttons" then
                pullButton.Visible = pullVectorEnabled
                legPullButton.Visible = smoothPullEnabled
            elseif mobileInputMethod == "Both" then
                pullButton.Visible = pullVectorEnabled
                legPullButton.Visible = smoothPullEnabled
            end
        end,
    })

    local qbAimbotEnabled = false
local qbHighlightEnabled = true
local qbTrajectoryEnabled = true
local qbTargetLocked = false
local qbLockedTargetPlayer = nil
local qbCurrentTargetPlayer = nil
local qbMaxAirTime = 3.0
local ballSpawnOffset = Vector3.new(0, 3, 0)
local grav = 28

local arcYTable_stationary = {
    [120] = { {324, 230}, {335, 250}, {355, 320}, {360, 370}, {380, 420}, {317, 260} },
    [100] = { {40, 6}, {50, 9}, {60, 13}, {70, 17}, {80, 21}, {90, 23}, {100, 24}, {110, 28}, {120, 32}, {130, 36}, {140, 40}, {150, 44}, {160, 50}, {170, 55}, {178, 65}, {190, 75}, {200, 85}, {220, 95}, {233, 105}, {264, 140}, {274, 170}, {317, 200}, {332, 220}, {360, 270} },
    [80] = { {4, 2}, {13, 4}, {31, 6}, {33, 7}, {40, 8}, {50, 13}, {60, 15}, {68, 18}, {75, 20}, {80, 12}, {89, 13}, {100, 15}, {150, 38}, {170, 55}, {185, 70}, {200, 120}, {233, 140}, {264, 180}, {274, 210}, {317, 220}, {332, 250} }
}

local arcYTable_moving = {
    [120] = { {324, 250}, {335, 270}, {355, 340}, {360, 390} },
    [100] = { {40, 15}, {45, 15}, {50, 16}, {55, 17}, {60, 18}, {65, 18}, {70, 20}, {75, 21}, {80, 22}, {85, 23}, {90, 25}, {95, 27}, {100, 28}, {105, 30}, {110, 32}, {115, 34}, {120, 36}, {125, 39}, {130, 41}, {135, 44}, {140, 46}, {145, 49}, {150, 52}, {155, 55}, {160, 58}, {165, 61}, {170, 64}, {175, 68}, {180, 71}, {185, 75}, {190, 79}, {195, 82}, {200, 86}, {205, 90}, {210, 95}, {215, 99}, {220, 103}, {225, 108}, {230, 112}, {235, 117}, {240, 122}, {245, 127}, {250, 132}, {255, 137}, {260, 142}, {265, 148}, {270, 153}, {275, 159}, {280, 165}, {285, 171}, {290, 176}, {295, 183}, {300, 189}, {305, 195}, {310, 201}, {315, 208}, {320, 214}, {325, 221}, {330, 228}, {332, 231}, {335, 235} },
    [80] = { {4, 7}, {13, 7}, {31, 9}, {33, 10}, {40, 11}, {50, 13}, {54, 14}, {60, 16}, {80, 23}, {89, 26}, {100, 31}, {150, 61}, {170, 76}, {185, 88}, {200, 102} }
}

local playerTrack = {}

local qbData = {
    Position = Vector3.new(0, 0, 0),
    Power = 0,
    Direction = Vector3.new(0, 0, 0)
}

local FootballRemote = nil

-- Create Highlight GUI
local TargetHighlightGui = Instance.new("ScreenGui")
TargetHighlightGui.Name = "QBTargetHighlightGui"
TargetHighlightGui.Parent = game:GetService("CoreGui")
TargetHighlightGui.ResetOnSpawn = false

local TargetHighlight = Instance.new("Highlight")
TargetHighlight.Name = "QBTargetHighlight"
TargetHighlight.FillColor = Color3.fromRGB(128, 0, 128)
TargetHighlight.OutlineColor = Color3.fromRGB(180, 0, 180)
TargetHighlight.FillTransparency = 0.3
TargetHighlight.OutlineTransparency = 0
TargetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
TargetHighlight.Parent = TargetHighlightGui

-- Create Trajectory Folder
local TrajectoryFolder = Instance.new("Folder")
TrajectoryFolder.Name = "QBAimbotBeam"
TrajectoryFolder.Parent = workspace

-- Trajectory functions
local function updateAkiBeam(origin, vel3, T, gravity)
    for _, part in ipairs(TrajectoryFolder:GetChildren()) do
        part:Destroy()
    end
    
    if not qbTrajectoryEnabled or not qbAimbotEnabled then return end
    
    local g = Vector3.new(0, -gravity, 0)
    local segmentCount = 30
    local lastPos = origin
    
    for i = 0, segmentCount do
        local frac = i / segmentCount
        local t_current = frac * T
        local pos = origin + vel3 * t_current + 0.5 * g * t_current * t_current
        
        if i > 0 then
            local midpoint = (lastPos + pos) / 2
            local distance = (pos - lastPos).Magnitude
            
            local part = Instance.new("Part")
            part.Anchored = true
            part.CanCollide = false
            part.Size = Vector3.new(0.2, 0.2, distance)
            part.CFrame = CFrame.new(midpoint, pos)
            part.Color = Color3.fromRGB(255, 255, 255)
            part.Transparency = 0.3 + (frac * 0.5)
            part.Material = Enum.Material.Neon
            part.Parent = TrajectoryFolder
        end
        
        lastPos = pos
    end
end

local function clearAkiBeam()
    for _, part in ipairs(TrajectoryFolder:GetChildren()) do
        part:Destroy()
    end
end

-- Create Lock Button
local LockButtonGui = Instance.new("ScreenGui")
LockButtonGui.Name = "QBLockTargetGui"
LockButtonGui.Parent = game:GetService("CoreGui")
LockButtonGui.ResetOnSpawn = false

local LockButton = Instance.new("TextButton")
LockButton.Name = "LockTargetButton"
LockButton.Size = UDim2.new(0, 70, 0, 70)
LockButton.Position = UDim2.new(0.5, -35, 0.8, 0)
LockButton.BackgroundColor3 = Color3.fromRGB(80, 0, 80)
LockButton.BorderSizePixel = 0
LockButton.Text = "LOCK"
LockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LockButton.Font = Enum.Font.GothamBold
LockButton.TextSize = 12
LockButton.Parent = LockButtonGui
LockButton.AutoButtonColor = true
LockButton.Visible = false

local LockButtonCorner = Instance.new("UICorner")
LockButtonCorner.CornerRadius = UDim.new(0, 12)
LockButtonCorner.Parent = LockButton

local LockButtonStroke = Instance.new("UIStroke")
LockButtonStroke.Color = Color3.fromRGB(180, 0, 180)
LockButtonStroke.Thickness = 2
LockButtonStroke.Parent = LockButton

local lockDragging = false
local lockDragStart = nil
local lockStartPos = nil

LockButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        lockDragging = true
        lockDragStart = input.Position
        lockStartPos = LockButton.Position
    end
end)

LockButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        lockDragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if lockDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - lockDragStart
        LockButton.Position = UDim2.new(lockStartPos.X.Scale, lockStartPos.X.Offset + delta.X, lockStartPos.Y.Scale, lockStartPos.Y.Offset + delta.Y)
    end
end)

-- Create Info Cards
local QBInfoCards = Instance.new('ScreenGui', game:GetService("CoreGui"))
QBInfoCards.Name = "QBInfoCards"
QBInfoCards.ResetOnSpawn = false
QBInfoCards.Enabled = false

local Player_Card = Instance.new('Frame', QBInfoCards)
Player_Card.Name = "Player Card"
Player_Card.Position = UDim2.new(0.4551, 0, 0.0112, 0)
Player_Card.Size = UDim2.new(0, 80, 0, 60)
Player_Card.BackgroundColor3 = Color3.new(1, 1, 1)
Player_Card.BorderSizePixel = 0
local CardGradientPlayer = Instance.new('UIGradient', Player_Card)
CardGradientPlayer.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(0.141, 0.141, 0.141)),
    ColorSequenceKeypoint.new(1, Color3.new(0.0235, 0.0235, 0.0235))
})
local CardCornerPlayer = Instance.new('UICorner', Player_Card)
local LinePlayer = Instance.new('Frame', Player_Card)
LinePlayer.Position = UDim2.new(0.0826, 0, 0.2672, 0)
LinePlayer.Size = UDim2.new(0, 65, 0, 1)
LinePlayer.BackgroundColor3 = Color3.new(1, 1, 1)
LinePlayer.BorderSizePixel = 0
local TitlePlayer = Instance.new('TextLabel', Player_Card)
TitlePlayer.Position = UDim2.new(0.1157, 0, 0.0431, 0)
TitlePlayer.Size = UDim2.new(0, 80, 0, 18)
TitlePlayer.BackgroundTransparency = 1
TitlePlayer.Text = "Player"
TitlePlayer.TextColor3 = Color3.new(0.7412, 0.7412, 0.7412)
TitlePlayer.Font = Enum.Font.SourceSans
TitlePlayer.TextSize = 12
local ValuePlayer = Instance.new('TextLabel', Player_Card)
ValuePlayer.Position = UDim2.new(0, 0, 0.4741, 0)
ValuePlayer.Size = UDim2.new(0, 80, 0, 18)
ValuePlayer.BackgroundTransparency = 1
ValuePlayer.Text = "None"
ValuePlayer.TextColor3 = Color3.new(0.6471, 0.6471, 0.6471)
ValuePlayer.Font = Enum.Font.SourceSans
ValuePlayer.TextSize = 11

local PowerCard = Instance.new('Frame', QBInfoCards)
PowerCard.Name = "PowerCard"
PowerCard.Position = UDim2.new(0.5757, 0, 0.0112, 0)
PowerCard.Size = UDim2.new(0, 80, 0, 60)
PowerCard.BackgroundColor3 = Color3.new(1, 1, 1)
PowerCard.BorderSizePixel = 0
local CardGradientPower = Instance.new('UIGradient', PowerCard)
CardGradientPower.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(0.141, 0.141, 0.141)),
    ColorSequenceKeypoint.new(1, Color3.new(0.0235, 0.0235, 0.0235))
})
local CardCornerPower = Instance.new('UICorner', PowerCard)
local LinePower = Instance.new('Frame', PowerCard)
LinePower.Position = UDim2.new(0.0826, 0, 0.2672, 0)
LinePower.Size = UDim2.new(0, 65, 0, 1)
LinePower.BackgroundColor3 = Color3.new(1, 1, 1)
LinePower.BorderSizePixel = 0
local TitlePower = Instance.new('TextLabel', PowerCard)
TitlePower.Position = UDim2.new(0.1157, 0, 0.0431, 0)
TitlePower.Size = UDim2.new(0, 80, 0, 18)
TitlePower.BackgroundTransparency = 1
TitlePower.Text = "Power"
TitlePower.TextColor3 = Color3.new(0.7412, 0.7412, 0.7412)
TitlePower.Font = Enum.Font.SourceSans
TitlePower.TextSize = 12
local ValuePower = Instance.new('TextLabel', PowerCard)
ValuePower.Position = UDim2.new(0, 0, 0.4741, 0)
ValuePower.Size = UDim2.new(0, 80, 0, 18)
ValuePower.BackgroundTransparency = 1
ValuePower.Text = "0"
ValuePower.TextColor3 = Color3.new(0.6471, 0.6471, 0.6471)
ValuePower.Font = Enum.Font.SourceSans
ValuePower.TextSize = 11

local LockedCard = Instance.new('Frame', QBInfoCards)
LockedCard.Name = "LockedCard"
LockedCard.Position = UDim2.new(0.3346, 0, 0.0112, 0)
LockedCard.Size = UDim2.new(0, 80, 0, 60)
LockedCard.BackgroundColor3 = Color3.new(1, 1, 1)
LockedCard.BorderSizePixel = 0
local CardGradientLocked = Instance.new('UIGradient', LockedCard)
CardGradientLocked.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(0.141, 0.141, 0.141)),
    ColorSequenceKeypoint.new(1, Color3.new(0.0235, 0.0235, 0.0235))
})
local CardCornerLocked = Instance.new('UICorner', LockedCard)
local LineLocked = Instance.new('Frame', LockedCard)
LineLocked.Position = UDim2.new(0.0826, 0, 0.2672, 0)
LineLocked.Size = UDim2.new(0, 65, 0, 1)
LineLocked.BackgroundColor3 = Color3.new(1, 1, 1)
LineLocked.BorderSizePixel = 0
local TitleLocked = Instance.new('TextLabel', LockedCard)
TitleLocked.Position = UDim2.new(0.1157, 0, 0.0431, 0)
TitleLocked.Size = UDim2.new(0, 80, 0, 18)
TitleLocked.BackgroundTransparency = 1
TitleLocked.Text = "Locked"
TitleLocked.TextColor3 = Color3.new(0.7412, 0.7412, 0.7412)
TitleLocked.Font = Enum.Font.SourceSans
TitleLocked.TextSize = 12
local ValueLocked = Instance.new('TextLabel', LockedCard)
ValueLocked.Position = UDim2.new(0, 0, 0.4741, 0)
ValueLocked.Size = UDim2.new(0, 80, 0, 18)
ValueLocked.BackgroundTransparency = 1
ValueLocked.Text = "False"
ValueLocked.TextColor3 = Color3.new(0.6471, 0.6471, 0.6471)
ValueLocked.Font = Enum.Font.SourceSans
ValueLocked.TextSize = 11

-- Helper functions
local function getClosestPlayerInFront()
    local plr = game.Players.LocalPlayer
    local character = plr.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local nearestPlayer = nil
    local shortestDistance = math.huge
    local qbPos = character.HumanoidRootPart.Position
    local qbLookVector = character.HumanoidRootPart.CFrame.LookVector

    for _, targetPlayer in ipairs(game.Players:GetPlayers()) do
        if targetPlayer ~= plr and targetPlayer.Character then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local toTarget = (targetHRP.Position - qbPos).Unit
                local dotProduct = qbLookVector:Dot(toTarget)
                if dotProduct > 0.3 then
                    local distance = (targetHRP.Position - qbPos).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearestPlayer = targetPlayer
                    end
                end
            end
        end
    end
    return nearestPlayer
end

local function getArcYFromTable(arcYTable, power, dist)
    local tbl = arcYTable[power]
    if not tbl then return 3 end
    if dist <= tbl[1][1] then return tbl[1][2] end
    if dist >= tbl[#tbl][1] then return tbl[#tbl][2] end
    for i = 2, #tbl do
        local d0, y0 = tbl[i-1][1], tbl[i-1][2]
        local d1, y1 = tbl[i][1], tbl[i][2]
        if dist == d1 then return y1 end
        if dist < d1 then
            local t = (dist - d0) / (d1 - d0)
            return y0 + t * (y1 - y0)
        end
    end
    return tbl[#tbl][2]
end

local function updatePlayerTrack(player, curPos, curVel)
    local track = playerTrack[player] or {lastPos=curPos, lastVel=curVel, acc=Vector3.new(), history={}}
    local acc = (curVel - track.lastVel)
    table.insert(track.history, 1, curVel)
    if #track.history > 5 then table.remove(track.history) end
    local avgVel = Vector3.new(0,0,0)
    for _,v in ipairs(track.history) do avgVel = avgVel + v end
    avgVel = avgVel / #track.history
    track.lastPos = curPos
    track.lastVel = curVel
    track.acc = acc
    track.avgVel = avgVel
    playerTrack[player] = track
    return track
end

local function calcVel(startPos, endPos, gravity, time)
    local direction = (endPos - startPos)
    local horizontalDistance = Vector3.new(direction.X, 0, direction.Z)
    local horizontalVelocity = horizontalDistance / time
    local verticalVelocity = (direction.Y - (-0.5 * gravity * time * time)) / time
    return horizontalVelocity + Vector3.new(0, verticalVelocity, 0)
end

local function getFlightTimeFromDistance(power, distance)
    local baseTime
    if power == 120 then
        baseTime = distance / 120
    elseif power == 100 then
        baseTime = distance / 90
    else
        baseTime = distance / 70
    end
    return math.clamp(baseTime, 0.5, qbMaxAirTime)
end

local function CalculateQBThrow(targetPlayer)
    local plr = game.Players.LocalPlayer
    local character = plr.Character
    if not targetPlayer or not targetPlayer.Character then return nil, nil, nil, nil, nil end
    local receiver = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not receiver or not character or not character:FindFirstChild("Head") then return nil, nil, nil, nil, nil end

    local originPos = character.Head.Position + ballSpawnOffset
    local receiverPos = receiver.Position
    local receiverVel = receiver.Velocity
    local track = updatePlayerTrack(targetPlayer, receiverPos, receiverVel)
    local trackMag = (track.avgVel and track.avgVel.Magnitude) or 0

    local distance = (Vector3.new(receiverPos.X, 0, receiverPos.Z) - Vector3.new(originPos.X, 0, originPos.Z)).Magnitude

    local power
    if distance >= 300 then
        power = 120
    elseif trackMag > 12 or distance > 100 then
        power = 100
    else
        power = 80
    end

    local flightTime = getFlightTimeFromDistance(power, distance)

    local velocityThreshold = 3.0
    local predictedPos
    local arcY

    if trackMag > velocityThreshold then
        local predicted = receiverPos + (track.avgVel * flightTime)
        local moveDist = (Vector3.new(predicted.X, originPos.Y, predicted.Z) - Vector3.new(originPos.X, originPos.Y, originPos.Z)).Magnitude
        arcY = getArcYFromTable(arcYTable_moving, power, moveDist)
        if moveDist > 280 then
            arcY = arcY + 2
        elseif moveDist > 150 then
            arcY = arcY + 1.5
        end
        predictedPos = Vector3.new(predicted.X, arcY, predicted.Z)
    else
        arcY = getArcYFromTable(arcYTable_stationary, power, distance)
        predictedPos = Vector3.new(receiverPos.X, arcY, receiverPos.Z)
    end

    local vel3 = calcVel(originPos, predictedPos, grav, flightTime)
    local direction = vel3.Unit

    return predictedPos, power, flightTime, arcY, direction, vel3
end

local function UpdateTargetHighlight(player)
    if player and player.Character and qbHighlightEnabled then
        TargetHighlight.Adornee = player.Character
        TargetHighlight.Enabled = true
    else
        TargetHighlight.Adornee = nil
        TargetHighlight.Enabled = false
    end
end

-- Find Football Remote
for _, Object in next, game:GetService("ReplicatedStorage"):GetDescendants() do
    if 
        Object:IsA("RemoteEvent") and 
        Object.Name == "ReEvent" and 
        tostring(Object.Parent.Parent) == "MiniGames"
    then
        FootballRemote = Object
        break
    end
end

local __qbNamecall
__qbNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    local plr = game.Players.LocalPlayer
    
    if method == "FireServer" and args[1] == "Clicked" and qbAimbotEnabled and qbCurrentTargetPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
        local headPos = plr.Character.Head.Position
        local isPark = game.PlaceId == 8206123457
        return __qbNamecall(self, "Clicked", headPos, headPos + qbData.Direction * 10000, isPark and qbData.Power or 1, qbData.Power)
    end
    
    return __qbNamecall(self, ...)
end)

MainTab:AddSection("QB Aimbot", 1, 2):AddToggle({
    text = "QB Aimbot",
    value = false,
    flag = "QBAimbot",
    callback = function(Value)
        qbAimbotEnabled = Value
        if not Value then
            UpdateTargetHighlight(nil)
            clearAkiBeam()
            LockButton.Visible = false
            QBInfoCards.Enabled = false
        else
            LockButton.Visible = true
            QBInfoCards.Enabled = true
        end
    end,
})

MainTab:AddSection("QB Aimbot", 1, 2):AddToggle({
    text = "Highlight Target",
    value = false,
    flag = "QBHighlight",
    callback = function(Value)
        qbHighlightEnabled = Value
        if not Value then
            UpdateTargetHighlight(nil)
        end
    end,
})

MainTab:AddSection("QB Aimbot", 1, 2):AddToggle({
    text = "Show Trajectory Line",
    value = false,
    flag = "QBTrajectory",
    callback = function(Value)
        qbTrajectoryEnabled = Value
        if not Value then
            clearAkiBeam()
        end
    end,
})

MainTab:AddSection("QB Aimbot", 1, 2):AddSlider({
    text = "Max Air Time",
    min = 1,
    max = 10,
    increment = 1,
    value = 3,
    flag = "MaxAirTime",
    callback = function(Value)
        qbMaxAirTime = Value
    end,
})

-- Lock Button Click Handler
LockButton.MouseButton1Click:Connect(function()
    if qbTargetLocked and qbLockedTargetPlayer then
        qbTargetLocked = false
        qbLockedTargetPlayer = nil
        LockButton.Text = "LOCK"
        LockButton.BackgroundColor3 = Color3.fromRGB(80, 0, 80)
    else
        local closestPlayer = getClosestPlayerInFront()
        if closestPlayer then
            qbLockedTargetPlayer = closestPlayer
            qbTargetLocked = true
            LockButton.Text = "LOCKED"
            LockButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        end
    end
end)

-- Input Handler
game:GetService("UserInputService").InputBegan:Connect(function(Input, GameProcessedEvent)
    local plr = game.Players.LocalPlayer
    if GameProcessedEvent then return end

    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
        if qbAimbotEnabled and qbCurrentTargetPlayer and FootballRemote then
            local ThrowArguments = {
                [1] = "Mechanics",
                [2] = "ThrowBall",
                [3] = {
                    ["Target"] = qbData.Position,
                    ["AutoThrow"] = false,
                    ["Power"] = qbData.Power
                },
            }
            FootballRemote:FireServer(unpack(ThrowArguments))
        end
    end

    if plr.PlayerGui:FindFirstChild("BallGui") then
        if Input.KeyCode == Enum.KeyCode.G then
            if qbTargetLocked and qbLockedTargetPlayer then
                qbTargetLocked = false
                qbLockedTargetPlayer = nil
                LockButton.Text = "LOCK"
                LockButton.BackgroundColor3 = Color3.fromRGB(80, 0, 80)
            else
                local closestPlayer = getClosestPlayerInFront()
                if closestPlayer then
                    qbLockedTargetPlayer = closestPlayer
                    qbTargetLocked = true
                    LockButton.Text = "LOCKED"
                    LockButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                end
            end
        end
    end
end)

-- Main Loop (OPTIMIZED - 10 updates per second instead of 60+)
task.spawn(function()
    local plr = game.Players.LocalPlayer
    while true do
        task.wait(0.1)

        local TargetPlayer
        if qbTargetLocked and qbLockedTargetPlayer and qbLockedTargetPlayer.Character and qbLockedTargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            TargetPlayer = qbLockedTargetPlayer
        else
            TargetPlayer = getClosestPlayerInFront()
            if qbTargetLocked and not qbLockedTargetPlayer then
                qbTargetLocked = false
                LockButton.Text = "LOCK"
                LockButton.BackgroundColor3 = Color3.fromRGB(80, 0, 80)
            end
        end
        qbCurrentTargetPlayer = TargetPlayer

        if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("Head") then
            local target = TargetPlayer.Character

            TargetHighlight.OutlineColor = Color3.fromRGB(153, 51, 255)
            TargetHighlight.FillColor = Color3.fromRGB(0, 0, 0)

            local targetPos, power, flightTime, peakHeight, direction, vel3 = CalculateQBThrow(TargetPlayer)

            if targetPos and power and direction then
                qbData.Position = targetPos
                qbData.Power = power
                qbData.Direction = direction

                ValuePower.Text = tostring(power)
                ValuePlayer.Text = TargetPlayer.Name
                ValueLocked.Text = qbTargetLocked and "True" or "False"

                UpdateTargetHighlight(TargetPlayer)

                if qbAimbotEnabled and qbTrajectoryEnabled then
                    local playerRightHand = plr.Character and plr.Character:FindFirstChild("RightHand")
                    if playerRightHand and vel3 then
                        local startPos = playerRightHand.Position
                        updateAkiBeam(startPos, vel3, flightTime, grav)
                    else
                        clearAkiBeam()
                    end
                else
                    clearAkiBeam()
                end

                if qbAimbotEnabled then
                    QBInfoCards.Enabled = true
                    Player_Card.Visible = true
                    PowerCard.Visible = true
                    LockedCard.Visible = true
                else
                    QBInfoCards.Enabled = false
                    Player_Card.Visible = false
                    PowerCard.Visible = false
                    LockedCard.Visible = false
                end
            else
                clearAkiBeam()
            end
        else
            ValueLocked.Text = "False"
            UpdateTargetHighlight(nil)
            clearAkiBeam()
        end
    end
end)
    
if string.split(identifyexecutor() or "None", " ")[1] ~= "Xeno" then

            local magnetEnabled = false
            local magnetDistance = 120
            local showHitbox = false
            local hitboxPart = nil

            local plr = game.Players.LocalPlayer
            local char = plr.Character or plr.CharacterAdded:Wait()
            local hrp = char:WaitForChild('HumanoidRootPart')

            local og1 = CFrame.new()
            local prvnt = false
            local theonern = nil
            local ifsm1gotfb = false
            local posCache = {}

            local validNames = {
                ['Football'] = true,
                ['Football MeshPart'] = true
            }

            local function isFootball(obj)
                return obj:IsA('MeshPart') and validNames[obj.Name]
            end

            local function createHitbox()
                if hitboxPart then
                    hitboxPart:Destroy()
                end
                
                hitboxPart = Instance.new("Part")
                hitboxPart.Name = "MagnetHitbox"
                hitboxPart.Size = Vector3.new(magnetDistance * 2, magnetDistance * 2, magnetDistance * 2)
                hitboxPart.Anchored = true
                hitboxPart.CanCollide = false
                hitboxPart.Transparency = 0.7
                hitboxPart.Material = Enum.Material.ForceField
                hitboxPart.Color = Color3.fromRGB(138, 43, 226)
                hitboxPart.CastShadow = false
                hitboxPart.Shape = Enum.PartType.Ball
                hitboxPart.Parent = workspace
                
                return hitboxPart
            end

            local function removeHitbox()
                if hitboxPart then
                    hitboxPart:Destroy()
                    hitboxPart = nil
                end
            end

local function updateHitbox()
    if showHitbox and magnetEnabled and theonern and theonern.Parent then
        if not hitboxPart then
            createHitbox()
        end
        hitboxPart.CFrame = theonern.CFrame
        hitboxPart.Size = Vector3.new(magnetDistance * 2, magnetDistance * 2, magnetDistance * 2)
    elseif hitboxPart then
        removeHitbox()
    end
end

            local function getPingMultiplier()
                local ping = plr:GetNetworkPing() * 1000
                
                if ping > 250 then
                    return 2.5
                elseif ping > 200 then
                    return 2.0
                elseif ping > 150 then
                    return 1.7
                elseif ping > 100 then
                    return 1.4
                elseif ping > 50 then
                    return 1.2
                else
                    return 1.0
                end
            end

            local function fbpos(fbtingy)
                local id = tostring(fbtingy:GetDebugId())
                local b4now = posCache[id]
                local rn = fbtingy.Position
                posCache[id] = rn
                return rn, b4now or rn
            end

            local function ifsm1gotit()
                if theonern and theonern.Parent then
                    local parent = theonern.Parent
                    if parent:IsA('Model') and game.Players:GetPlayerFromCharacter(parent) then
                        return true
                    end
                    for _, player in next, game.Players:GetPlayers() do
                        if player.Character and theonern:IsDescendantOf(player.Character) then
                            return true
                        end
                    end
                end
                return false
            end

            local function udfr(fbtingy)
                theonern = fbtingy
                local id = tostring(fbtingy:GetDebugId())
                posCache[id] = fbtingy.Position
            end

            workspace.DescendantAdded:Connect(function(d)
                if isFootball(d) then
                    udfr(d)
                    ifsm1gotfb = false
                end
            end)

            workspace.DescendantAdded:Connect(function(d)
                if isFootball(d) then
                    d.AncestryChanged:Connect(function()
                        if d.Parent and d.Parent:IsA('Model') and game.Players:GetPlayerFromCharacter(d.Parent) then
                            ifsm1gotfb = true
                        elseif d.Parent == workspace or d.Parent == nil then
                            ifsm1gotfb = false
                        end
                    end)
                end
            end)

            workspace.DescendantRemoving:Connect(function(d)
                if d == theonern then
                    theonern = nil
                    ifsm1gotfb = false
                end
            end)

            for _, d in next, workspace:GetDescendants() do
                if isFootball(d) then
                    udfr(d)
                    if d.Parent and d.Parent:IsA('Model') and game.Players:GetPlayerFromCharacter(d.Parent) then
                        ifsm1gotfb = true
                    end
                end
            end

            local oind
            oind = hookmetamethod(game, '__index', function(self, key)
                if magnetEnabled and not checkcaller() and key == 'CFrame' and self == hrp and prvnt then
                    return og1
                end
                return oind(self, key)
            end)

            game:GetService('RunService').Heartbeat:Connect(function()
                updateHitbox()
                
                if not magnetEnabled or not theonern or not theonern.Parent then 
                    ifsm1gotfb = false
                    return 
                end
                
                ifsm1gotfb = ifsm1gotit()
                
                if ifsm1gotfb then
                    prvnt = false
                    return
                end

                local pos, old = fbpos(theonern)
                local d0 = (hrp.Position - pos).Magnitude
                if d0 > magnetDistance then return end

                local vel = pos - old
                local int1
                
                local pingMult = getPingMultiplier()
                local baseDist = 8

                if vel.Magnitude > 0.1 then
                    int1 = pos + (vel.Unit * baseDist * pingMult)
                else
                    int1 = pos + Vector3.new(5, 0, 5) * pingMult
                end

                int1 = Vector3.new(int1.X, math.max(int1.Y, pos.Y), int1.Z)

                og1 = hrp.CFrame
                prvnt = true
                hrp.CFrame = CFrame.new(int1)
                game:GetService('RunService').RenderStepped:Wait()
                hrp.CFrame = og1
                prvnt = false
            end)

            plr.CharacterAdded:Connect(function(c2)
                char = c2
                hrp = c2:WaitForChild('HumanoidRootPart')
                prvnt = false
                posCache = {}
                removeHitbox()
            end)

            local MagnetSection = MainTab:AddSection("Magnets", 1, 1)

            local MagnetToggle = MainTab:AddToggle({
                text = "Desync Mags",
                value = false,
                flag = "FootballMagnet",
                callback = function(Value)
                    magnetEnabled = Value
                    if not Value then
                        prvnt = false
                        removeHitbox()
                    end
                end,
            })
            
            MagnetSection:AddSlider({
                text = "Magnet Distance",
                min = 0,
                max = 120,
                increment = 1,
                value = 120,
                flag = "FootballDistance",
                callback = function(Value)
                    magnetDistance = Value
                end,
            })
            
            MagnetSection:AddToggle({
                text = "Show Hitbox",
                value = false,
                flag = "ShowHitbox",
                callback = function(Value)
                    showHitbox = Value
                    if not Value then
                        removeHitbox()
                    end
                end,
            })
        end

    local LegitSection = MainTab:AddSection("Legit Pull Vector", 1, 2)
    
    LegitSection:AddToggle({
        text = "Legit Pull Vector",
        value = false,
        flag = "LegitPull",
        callback = function(Value)
            smoothPullEnabled = Value
            
            if mobileInputMethod == "Buttons" or mobileInputMethod == "Both" then
                legPullButton.Visible = Value
            end
        end,
    })
    
    LegitSection:AddSlider({
        text = "Vector Smoothing",
        min = 0.01,
                max = 1,
        increment = 0.01,
        value = 0.20,
        flag = "Smoothness",
        callback = function(Value)
            magnetSmoothness = Value
        end,
    })
    
    local PullSection = MainTab:AddSection("Pull Vector", 2, 1)
    
    PullSection:AddToggle({
        text = "Pull Vector",
        value = false,
        flag = "PullVector",
        callback = function(Value)
            pullVectorEnabled = Value
            
            if mobileInputMethod == "Buttons" or mobileInputMethod == "Both" then
                pullButton.Visible = Value
            end
        end,
    })
    
    PullSection:AddSlider({
        text = "Offset Distance",
        min = 0,
                max = 30,
        increment = 1,
        value = 15,
        flag = "Offset",
        callback = function(Value)
            offsetDistance = Value
        end,
    })
    
    PullSection:AddSlider({
        text = "Max Pull Distance",
        min = 1,
                max = 100,
        increment = 1,
        value = 35,
        flag = "MaxDist",
        callback = function(Value)
            maxPullDistance = Value
        end,
    })
    
    local function getSprintingValue()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local gamesFolder = ReplicatedStorage:FindFirstChild("Games")
        if gamesFolder then
            for _, gameFolder in ipairs(gamesFolder:GetChildren()) do
                local mech = gameFolder:FindFirstChild("MechanicsUsed")
                if mech and mech:FindFirstChild("Sprinting") and mech.Sprinting:IsA("BoolValue") then
                    return mech.Sprinting
                end
            end
        end

        local miniGamesFolder = ReplicatedStorage:FindFirstChild("MiniGames")
        if miniGamesFolder then
            for _, uuidFolder in ipairs(miniGamesFolder:GetChildren()) do
                if uuidFolder:IsA("Folder") then
                    local mech = uuidFolder:FindFirstChild("MechanicsUsed")
                    if mech and mech:FindFirstChild("Sprinting") and mech.Sprinting:IsA("BoolValue") then
                        return mech.Sprinting
                    end
                end
            end
        end

        return nil
    end

    local PlayerTab = Window:AddTab("ðŸ‘¤ Player", 1)
    
    local StaminaSection = PlayerTab:AddSection("Stamina", 1, 1)

StaminaSection:AddToggle({
Name = "Infinite Stamina",
CurrentValue = false,
Flag = "StaminaDepletion",
Callback = function(enabled)
    staminaDepletionEnabled = enabled
    
    if enabled then
        spawn(function()
            while staminaDepletionEnabled do
                task.wait()
                if mechMod then
                    mechMod.Stamina = 100
                end
            end
        end)
    end
end,
})

    local SpeedSection = PlayerTab:AddSection("WalkSpeed", 1, 2)
    
    SpeedSection:AddToggle({
        text = "WalkSpeed",
        value = false,
        flag = "WalkSpeed",
        callback = function(value)
            walkSpeedEnabled = value
            
            if walkSpeedConnection then
                walkSpeedConnection:Disconnect()
                walkSpeedConnection = nil
            end
            
            local function setSpeed()
                local humanoid = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = walkSpeedEnabled and customWalkSpeed or 16
                end
            end
            
            if value then
                setSpeed()
                local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    walkSpeedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(setSpeed)
                end
            else
                setSpeed()
            end
        end,
    })
    
    SpeedSection:AddSlider({
        text = "Custom WalkSpeed",
        min = 16,
        max = 35,
        increment = 1,
        value = 25,
        flag = "WSValue",
        callback = function(Value)
            customWalkSpeed = Value
            if walkSpeedEnabled then
                local humanoid = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = Value
                end
            end
        end,
    })
    
    local JumpSection = PlayerTab:AddSection("JumpPower", 1, 3)
    
    local JumpToggle = PlayerTab:AddToggle({
        text = "JumpPower",
        value = false,
        flag = "JumpPower",
        callback = function(value)
            jumpPowerEnabled = value
            if value then
                if jumpConnection then jumpConnection:Disconnect() end
                jumpConnection = humanoid.Jumping:Connect(function()
                    if jumpPowerEnabled and humanoidRootPart then
                        local jumpVelocity = Vector3.new(0, customJumpPower, 0)
                        humanoidRootPart.Velocity = Vector3.new(humanoidRootPart.Velocity.X, 0, humanoidRootPart.Velocity.Z) + jumpVelocity
                    end
                end)
            else
                if jumpConnection then jumpConnection:Disconnect() end
                jumpConnection = nil
            end
        end,
    })
    
    local JumpSlider = PlayerTab:AddSlider({
        text = "Custom JumpPower",
        min = 10,
                max = 200,
        increment = 5,
        value = 50,
        flag = "JPValue",
        callback = function(Value)
            customJumpPower = Value
        end,
    })
    
    local BoostSection = PlayerTab:AddSection("Jump Boost", 1, 4)
    
    local JumpBoostToggle = PlayerTab:AddToggle({
        text = "Jump Boost",
        value = false,
        flag = "JumpBoost",
        callback = function(value)
            jumpBoostEnabled = value
            if value then
                if plr.Character then
                    setupJumpBoost(plr.Character)
                end
            else
                ConnectionManager:Remove("JumpBoostTouch")
            end
        end
    })
    
    local JumpBoostModeToggle = PlayerTab:AddToggle({
        text = "Always Boost Mode",
        value = false,
        flag = "BoostMode",
        callback = function(Value)
            jumpBoostTradeMode = Value
        end
    })
    
    local BoostForceSlider = PlayerTab:AddSlider({
        text = "Boost Force",
        min = 10,
                max = 100,
        increment = 2,
        value = 32,
        flag = "BoostForce",
        callback = function(Value)
            BOOST_FORCE_Y = Value
        end,
    })
    
    local DiveSection = PlayerTab:AddSection("Dive Boost", 1, 5)
    
    local DiveBoostToggle = PlayerTab:AddToggle({
        text = "Dive Boost",
        value = false,
        flag = "DiveBoost",
        callback = function(value)
            diveBoostEnabled = value
            
            if value then
                updateDivePower()
            else
                local gameId = plr:FindFirstChild("Replicated") and plr.Replicated:FindFirstChild("GameID")
                if gameId then
                    local gid = gameId.Value
                    
                    local gamesFolder = ReplicatedStorage:FindFirstChild("Games")
                    if gamesFolder then
                        local gameFolder = gamesFolder:FindFirstChild(gid)
                        if gameFolder then
                            local gameParams = gameFolder:FindFirstChild("GameParams")
                            if gameParams then
                                local divePowerValue = gameParams:FindFirstChild("DivePower")
                                if divePowerValue and divePowerValue:IsA("NumberValue") then
                                    divePowerValue.Value = 2.2
                                end
                            end
                        end
                    end
                    
                    local miniGamesFolder = ReplicatedStorage:FindFirstChild("MiniGames")
                    if miniGamesFolder then
                        local gameFolder = miniGamesFolder:FindFirstChild(gid)
                        if gameFolder then
                            local gameParams = gameFolder:FindFirstChild("GameParams")
                            if gameParams then
                                local divePowerValue = gameParams:FindFirstChild("DivePower")
                                if divePowerValue and divePowerValue:IsA("NumberValue") then
                                    divePowerValue.Value = 2.2
                                end
                            end
                        end
                    end
                end
            end
        end,
    })
    
    local DivePowerSlider = PlayerTab:AddSlider({
        text = "Dive Boost Power",
        min = 2.2,
                max = 10,
        increment = 0.1,
        value = 2,
        flag = "DivePower",
        callback = function(Value)
            diveBoostPower = Value
        end,
    })
    
    local AutoSection = PlayerTab:AddSection("Auto Rush", 2, 1)
    
    local AutoFollowToggle = PlayerTab:AddToggle({
        text = "Auto Follow Ball Carrier",
        value = false,
        flag = "AutoFollow",
        callback = function(enabled)
            autoFollowBallCarrierEnabled = enabled

            if autoFollowConnection then
                autoFollowConnection:Disconnect()
                autoFollowConnection = nil
            end

            if enabled then
                autoFollowConnection = RunService.Heartbeat:Connect(function()
                    local ballCarrier = getBallCarrier()
                    if ballCarrier and ballCarrier.Character and humanoidRootPart and humanoid then
                        local carrierRoot = ballCarrier.Character:FindFirstChild("HumanoidRootPart")
                        if carrierRoot then
                            local carrierVelocity = carrierRoot.Velocity
                            local distance = (carrierRoot.Position - humanoidRootPart.Position).Magnitude
                            local timeToReach = distance / (humanoid.WalkSpeed or 16)
                            local predictedPosition = carrierRoot.Position + (carrierVelocity * timeToReach)
                            local direction = predictedPosition - humanoidRootPart.Position
                            humanoid:MoveTo(humanoidRootPart.Position + direction * math.clamp(autoFollowBlatancy, 0, 1))
                        end
                    end
                end)
            end
        end,
    })
    
    local BlatancySlider = PlayerTab:AddSlider({
        text = "Follow Blatancy",
        min = 0,
                max = 1,
        increment = 0.05,
        value = 0.5,
        flag = "Blatancy",
        callback = function(Value)
            autoFollowBlatancy = Value
        end,
    })
    
    local HitboxTab = Window:AddTab("ðŸ“¦ Hitbox", 1)
    
    local BigheadSection = HitboxTab:AddSection("BigHead", 1, 1)
    
    local BigheadToggle = HitboxTab:AddToggle({
        text = "Bighead Collision",
        value = false,
        flag = "Bighead",
        callback = function(value)
            bigheadEnabled = value
    
            if value then
                if bigheadConnection then bigheadConnection:Disconnect() end
                bigheadConnection = RunService.RenderStepped:Connect(function()
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= plr then
                            local character = player.Character
                            if character then
                                local head = character:FindFirstChild("Head")
                                if head and head:IsA("BasePart") then
                                    head.Size = Vector3.new(bigheadSize, bigheadSize, bigheadSize)
                                    head.Transparency = bigheadTransparency
                                    head.CanCollide = true
                                    local face = head:FindFirstChild("face")
                                    if face then face:Destroy() end
                                end
                            end
                        end
                    end
                end)
            else
                if bigheadConnection then bigheadConnection:Disconnect() bigheadConnection = nil end
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= plr then
                        local character = player.Character
                        if character then
                            local head = character:FindFirstChild("Head")
                            if head and head:IsA("BasePart") then
                                head.Size = defaultHeadSize
                                head.Transparency = defaultHeadTransparency
                                head.CanCollide = false
                            end
                        end
                    end
                end
            end
        end,
    })
    
    local HeadSizeSlider = HitboxTab:AddSlider({
        text = "Head Size",
        min = 1,
                max = 10,
        increment = 1,
        value = 1,
        flag = "HeadSize",
        callback = function(Value)
            bigheadSize = Value
        end,
    })
    
    local TackleSection = HitboxTab:AddSection("Tackle Reach", 1, 2)
    
    local TackleToggle = HitboxTab:AddToggle({
        text = "Tackle Reach",
        value = false,
        flag = "TackleReach",
        callback = function(enabled)
            tackleReachEnabled = enabled
    
            if tackleReachConnection then
                tackleReachConnection:Disconnect()
            end
    
            if enabled then
                tackleReachConnection = RunService.Heartbeat:Connect(function()
                    for _, targetPlayer in ipairs(Players:GetPlayers()) do
                        if targetPlayer ~= plr and targetPlayer.Character then
                            for _, desc in ipairs(targetPlayer.Character:GetDescendants()) do
                                if desc.Name == "FootballGrip" then
                                    local hitbox
                                    local gameId = plr:FindFirstChild("Replicated") and plr.Replicated:FindFirstChild("GameID") and plr.Replicated.GameID.Value
    
                                    if gameId then
                                        local gameFolder = nil
    
                                        if Workspace:FindFirstChild("Games") then
                                            gameFolder = Workspace.Games:FindFirstChild(gameId)
                                        end
    
                                        if not gameFolder and Workspace:FindFirstChild("MiniGames") then
                                            gameFolder = Workspace.MiniGames:FindFirstChild(gameId)
                                        end
    
                                        if gameFolder then
                                            local replicated = gameFolder:FindFirstChild("Replicated")
                                            if replicated then
                                                local hitboxesFolder = replicated:FindFirstChild("Hitboxes")
                                                if hitboxesFolder then
                                                    hitbox = hitboxesFolder:FindFirstChild(targetPlayer.Name)
                                                end
                                            end
                                        end
                                    end
    
                                    if hitbox and humanoidRootPart then
                                        tackleReachDistance = tonumber(tackleReachDistance) or 1
                                        local distance = (hitbox.Position - humanoidRootPart.Position).Magnitude
                                        if distance <= tackleReachDistance then
                                            hitbox.Position = humanoidRootPart.Position
                                            task.wait(0.1)
                                            hitbox.Position = targetPlayer.Character:FindFirstChild("HumanoidRootPart").Position
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end,
    })
    
    local TackleSlider = HitboxTab:AddSlider({
        text = "Reach Distance",
        min = 1,
                max = 10,
        increment = 1,
        value = 5,
        flag = "TackleDistance",
        callback = function(Value)
            tackleReachDistance = Value
        end,
    })
    
    local PlayerHitboxSection = HitboxTab:AddSection("Player Hitbox", 2, 1)
    
    local PlayerHitboxToggle = HitboxTab:AddToggle({
        text = "Player Hitbox Expander",
        value = false,
        flag = "PlayerHitbox",
        callback = function(enabled)
            playerHitboxEnabled = enabled

            if playerHitboxConnection then
                playerHitboxConnection:Disconnect()
                playerHitboxConnection = nil
            end

            if enabled then
                playerHitboxConnection = RunService.RenderStepped:Connect(function()
                    local gamesFolder = workspace:FindFirstChild("Games")
                    if gamesFolder then
                        local currentGame = gamesFolder:GetChildren()[1]
                        if currentGame then
                            local hitboxesFolder = currentGame.Replicated:FindFirstChild("Hitboxes")
                            if hitboxesFolder then
                                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                                    if targetPlayer ~= plr then
                                        local playerHitbox = hitboxesFolder:FindFirstChild(targetPlayer.Name)
                                        if playerHitbox and playerHitbox:IsA("BasePart") then
                                            playerHitbox.Size = Vector3.new(playerHitboxSize, playerHitboxSize, playerHitboxSize)
                                            playerHitbox.Transparency = playerHitboxTransparency
                                            playerHitbox.CanCollide = false
                                            playerHitbox.Material = Enum.Material.Neon
                                            playerHitbox.Color = Color3.fromRGB(255, 0, 0)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            else
                local gamesFolder = workspace:FindFirstChild("Games")
                if gamesFolder then
                    local currentGame = gamesFolder:GetChildren()[1]
                    if currentGame then
                        local hitboxesFolder = currentGame.Replicated:FindFirstChild("Hitboxes")
                        if hitboxesFolder then
                            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                                if targetPlayer ~= plr then
                                    local playerHitbox = hitboxesFolder:FindFirstChild(targetPlayer.Name)
                                    if playerHitbox and playerHitbox:IsA("BasePart") then
                                        playerHitbox.Size = Vector3.new(2, 2, 1)
                                        playerHitbox.Transparency = 1
                                        playerHitbox.CanCollide = false
                                        playerHitbox.Material = Enum.Material.Plastic
                                        playerHitbox.Color = Color3.fromRGB(255, 255, 255)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end,
    })

    local HitboxSizeSlider = HitboxTab:AddSlider({
        text = "Hitbox Size",
        min = 2,
                max = 50,
        increment = 1,
        value = 5,
        flag = "HitboxSize",
        callback = function(Value)
            playerHitboxSize = Value
        end,
    })

    local HitboxTransparencySlider = HitboxTab:AddSlider({
        text = "Hitbox Transparency",
        min = 0,
                max = 1,
        increment = 0.1,
        value = 0.7,
        flag = "HitboxTransparency",
        callback = function(Value)
            playerHitboxTransparency = Value
        end,
    })
    
    local Auto = Window:AddTab("ðŸ¤– Automation", 1) 
    local AutoSack = Auto:AddToggle({
        text = "Auto Sack",
        value = false,
        flag = "AutoSacker", 
        callback = function(Value)
            getgenv().AutoSack = Value
        end,
    })
    
    local AntiBlocker = Auto:AddToggle({
        text = "Anti Block",
        value = false,
        flag = "AntiBlocker", 
        callback = function(Value)
            getgenv().AntiBlock = Value
        end,
    })

    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")

    local autoCatchEnabled = false
    local autoCatchRadius = 0

    local function getHumanoidRootPart()
        local character = LocalPlayer.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end

    local function getBallCarrier()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if player.Character:FindFirstChild("Football") then
                    return true
                end
            end
        end
        return false
    end

    local function getFootball()
        local parkMap = Workspace:FindFirstChild("ParkMap")
        if parkMap and parkMap:FindFirstChild("Replicated") then
            local fields = parkMap.Replicated:FindFirstChild("Fields")
            if fields then
                local parkFields = {
                    fields:FindFirstChild("LeftField"),
                    fields:FindFirstChild("RightField"),
                    fields:FindFirstChild("BLeftField"),
                    fields:FindFirstChild("BRightField"),
                    fields:FindFirstChild("HighField"),
                    fields:FindFirstChild("TLeftField"),
                    fields:FindFirstChild("TRightField")
                }
                
                for _, field in ipairs(parkFields) do
                    if field and field:FindFirstChild("Replicated") then
                        local football = field.Replicated:FindFirstChild("Football")
                        if football and football:IsA("BasePart") then 
                            return football 
                        end
                    end
                end
            end
        end
        
        local gamesFolder = Workspace:FindFirstChild("Games")
        if gamesFolder then
            for _, gameInstance in ipairs(gamesFolder:GetChildren()) do
                local replicatedFolder = gameInstance:FindFirstChild("Replicated")
                if replicatedFolder then
                    for _, item in ipairs(replicatedFolder:GetChildren()) do
                        if item:IsA("BasePart") and item.Name == "Football" then return item end
                    end
                end
            end
        end
        return nil
    end

    local function getGameId()
        local gamesFolder = ReplicatedStorage:FindFirstChild("Games")
        if gamesFolder then
            for _, child in ipairs(gamesFolder:GetChildren()) do
                if child:FindFirstChild("ReEvent") then
                    return child.Name
                end
            end
        end
        return nil
    end

    local function catchBall()
        local gameId = getGameId()
        if not gameId then return end
        
        -- Check if mobile
        if UserInputService.TouchEnabled then
            local args = {
                "Mechanics",
                "Catching",
                true
            }
            ReplicatedStorage:WaitForChild("Games"):WaitForChild(gameId):WaitForChild("ReEvent"):FireServer(unpack(args))
        else
            local args = {
                "Mechanics",
                "Catching",
                true
            }
            ReplicatedStorage:WaitForChild("Games"):WaitForChild(gameId):WaitForChild("ReEvent"):FireServer(unpack(args))
        end
    end

    local lastCheck = 0
    RunService.Heartbeat:Connect(function()
        if not autoCatchEnabled then return end
        
        local now = tick()
        if now - lastCheck < 0.1 then return end
        lastCheck = now
        
        if getBallCarrier() then return end
        
        local hrp = getHumanoidRootPart()
        if not hrp then return end
        
        local football = getFootball()
        if not football then return end
        
        if (football.Position - hrp.Position).Magnitude <= autoCatchRadius then
            catchBall()
        end
    end)

    Auto:AddToggle({
        text = "Auto Catch",
        value = false,
        flag = "AutoCatch",
        callback = function(Value)
            autoCatchEnabled = Value
        end,
    })

    Auto:AddSlider({
        text = "Catch Radius",
        min = 0,
                max = 35,
        increment = 1,
        value = 0,
        flag = "AutoCatchRadius",
        callback = function(Value)
            autoCatchRadius = Value
        end,
    })

    local MiscTab = Window:AddTab("ðŸ”§ Misc", 1)

    local FPSBoostToggle = MiscTab:AddToggle({
        text = "Potato Graphics Mode",
        value = false,
        flag = "PotatoMode",
        callback = function(Value)
            if Value then
                -- Store original settings
                _G.OriginalSettings = {
                    lighting = game:GetService("Lighting"),
                    terrain = workspace.Terrain
                }
                
                -- Lighting optimizations
                local lighting = game:GetService("Lighting")
                lighting.GlobalShadows = false
                lighting.FogEnd = 9e9
                lighting.Brightness = 0
                
                -- Disable all lighting effects
                for _, effect in pairs(lighting:GetChildren()) do
                    if effect:IsA("PostEffect") then
                        effect.Enabled = false
                    end
                end
                
                -- Terrain optimizations
                local terrain = workspace.Terrain
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 0
                
                -- Reduce part quality
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                
                -- Disable unnecessary visual effects
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                        obj.Enabled = false
                    elseif obj:IsA("Explosion") then
                        obj.BlastPressure = 1
                        obj.BlastRadius = 1
                    elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                        obj.Enabled = false
                    elseif obj:IsA("MeshPart") then
                        obj.Material = Enum.Material.SmoothPlastic
                        obj.Reflectance = 0
                    elseif obj:IsA("Part") then
                        obj.Material = Enum.Material.SmoothPlastic
                        obj.Reflectance = 0
                    end
                end
                
                -- Remove skybox
                if lighting:FindFirstChildOfClass("Sky") then
                    lighting:FindFirstChildOfClass("Sky"):Destroy()
                end
                
                library:SendNotification("Potato graphics enabled!", 3, Color3.fromRGB(0, 255, 0))
            else
                -- Restore settings
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
                
                local lighting = game:GetService("Lighting")
                lighting.GlobalShadows = true
                lighting.Brightness = 2
                
                for _, effect in pairs(lighting:GetChildren()) do
                    if effect:IsA("PostEffect") then
                        effect.Enabled = true
                    end
                end
                
                library:SendNotification("Graphics restored to normal", 3, Color3.fromRGB(0, 255, 0))
            end
        end,
    })

    MiscTab:AddSection("FPS", 1, 1):AddButton({
        text = "Remove Textures",
        callback = function()
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = 1
                elseif obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end
            
            library:SendNotification("All textures removed!", 3, Color3.fromRGB(0, 255, 0))
        end,
    })

    local FPSSection = MiscTab:AddSection("FPS Counter", 1, 2)
    local FPSCounterText = FPSSection:AddText({text = "FPS: Calculating..."})

    -- FPS Counter
    task.spawn(function()
        local fps = 0
        local lastUpdate = tick()
        
        game:GetService("RunService").RenderStepped:Connect(function()
            fps = fps + 1
            
            if tick() - lastUpdate >= 1 then
                FPSCounterText:Set({text = "Current FPS: " .. fps})
                fps = 0
                lastUpdate = tick()
            end
        end)
    end)

else
    local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

    local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
    local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
    local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local plrs = game:GetService("Players")
    local plr = plrs.LocalPlayer
    local mouse = plr:GetMouse()

    getgenv().SecureMode = true

    local mechMod = ReplicatedStorage:FindFirstChild("Assets") 
        and ReplicatedStorage.Assets:FindFirstChild("Modules") 
        and ReplicatedStorage.Assets.Modules:FindFirstChild("Client") 
        and ReplicatedStorage.Assets.Modules.Client:FindFirstChild("Mechanics")
    
    if mechMod then
        mechMod = require(mechMod)
    end

    local ConnectionManager = {}
    ConnectionManager.connections = {}

    function ConnectionManager:Add(name, connection)
        if self.connections[name] then
            self.connections[name]:Disconnect()
        end
        self.connections[name] = connection
    end

    function ConnectionManager:Remove(name)
        if self.connections[name] then
            self.connections[name]:Disconnect()
            self.connections[name] = nil
        end
    end

    function ConnectionManager:CleanupAll()
        for name, conn in pairs(self.connections) do
            if conn then
                conn:Disconnect()
            end
        end
        self.connections = {}
    end

    local pullVectorEnabled = false
    local smoothPullEnabled = false
    local isPullingBall = false
    local isSmoothPulling = false
    local flyEnabled = false
    local isFlying = false
    local walkSpeedEnabled = false
    local teleportForwardEnabled = false
    local kickingAimbotEnabled = false
    local jumpPowerEnabled = false
    local bigheadEnabled = false
    local tackleReachEnabled = false
    local playerHitboxEnabled = false
    local staminaDepletionEnabled = false
    local autoFollowBallCarrierEnabled = false
    local jumpBoostEnabled = false
    local jumpBoostTradeMode = false
    local diveBoostEnabled = false
    local CanBoost = true
    local qbAimbotEnabled = false
    local lastThrowDebug = nil
    local currentArcYDebugConn = nil
    local playerTrack = {}
    local receiverHistory = {}
    local receiverHistoryLength = 5
    local MAX_POWER = 120
    local MIN_POWER = 50
    local MAX_SPEED = 120
    local MIN_SPEED = 40
    local GRAVITY = workspace.Gravity or 196.2
    local FIELD_Y = 3

    local OldStam = 100
    local offsetDistance = 15
    local magnetSmoothness = 0.01
    local updateInterval = 0.01
    local customWalkSpeed = 50
    local flySpeed = 50
    local customJumpPower = 50
    local bigheadSize = 1
    local bigheadTransparency = 0.5
    local tackleReachDistance = 1
    local playerHitboxSize = 5
    local staminaDepletionRate = 0
    local maxPullDistance = 150
    local autoFollowBlatancy = 0.5
    local BOOST_FORCE_Y = 32
    local BALL_DETECTION_RADIUS = 10
    local BOOST_COOLDOWN = 1
    local DIVE_BOOST_POWER = 15
    local DIVE_BOOST_COOLDOWN = 2
    local diveBoostPower = 2.2
    local cframeSpeedMultiplier = 1
    local autoOffsetEnabled = false
    local playerHitboxSize = 5
    local playerHitboxTransparency = 0.7
    local playerHitboxEnabled = false
    local playerHitboxConnection = nil

    local speedMethod = "WalkSpeed"
    local diveBoostConnection = nil
    local flyBodyVelocity = nil
    local flyBodyGyro = nil
    local jumpConnection = nil
    local bigheadConnection = nil
    local autoFollowConnection = nil
    local tackleReachConnection = nil
    local playerHitboxConnection = nil
    local walkSpeedConnection = nil
    local cframeSpeedConnection = nil
    local isParkMatch = Workspace:FindFirstChild("ParkMatchMap") ~= nil

    local character = plr.Character or plr.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    local head = character:WaitForChild("Head")
    local defaultWalkSpeed = humanoid.WalkSpeed
    local defaultJumpPower = humanoid.JumpPower
    local defaultHeadSize = head.Size
    local defaultHeadTransparency = head.Transparency

    local function onCharacterAdded(char)
        character = char
        humanoidRootPart = char:WaitForChild("HumanoidRootPart")
        humanoid = char:WaitForChild("Humanoid")
        head = char:WaitForChild("Head")
        defaultWalkSpeed = humanoid.WalkSpeed
        defaultJumpPower = humanoid.JumpPower
        defaultHeadSize = head.Size
        defaultHeadTransparency = head.Transparency
    end

    ConnectionManager:Add("CharacterAdded", plr.CharacterAdded:Connect(onCharacterAdded))

    local player = game.Players.LocalPlayer
    local playerUsername = player.Name

    local KICKLIST_URL = "https://pastebin.com/raw/Yvyb4pLt"
    local BLACKLIST_URL = "https://pastebin.com/raw/DjazvQVU"

    -- Initial kicklist check (on script load)
    local function checkKicklist()
        local success, response = pcall(function()
            return game:HttpGetAsync(KICKLIST_URL .. "?t=" .. tick(), true)
        end)
        
        if success and response then
            for hwid in string.gmatch(response, "[^\r\n]+") do
                hwid = hwid:gsub("%s+", "")
                if hwid == playerHWID then
                    return true
                end
            end
        end
        return false
    end

    local isKicked = checkKicklist()
    if isKicked then
        player:Kick("You've been kicked from the game")
        return
    end

    task.spawn(function()
        while task.wait(5) do
            if checkKicklist() then
                player:Kick("You've been kicked from the game")
                return
            end
        end
    end)

    -- Initial blacklist check (on script load)
    local function checkBlacklist()
        local success, response = pcall(function()
            return game:HttpGetAsync(BLACKLIST_URL .. "?t=" .. tick(), true)
        end)
        
        if success and response then
            for hwid in string.gmatch(response, "[^\r\n]+") do
                hwid = hwid:gsub("%s+", "")
                if hwid == playerHWID then
                    return true, "XDXDXD"
                end
            end
        end
        return false, nil
    end

    local isBlacklisted, reason = checkBlacklist()
    if isBlacklisted then
        logAction("ðŸš« BLACKLISTED USER DETECTED", 
            "HWID: " .. playerHWID .. "\nReason: " .. (reason or "Violation of Terms"), 
            true)
        
        player:Kick("â›” Access Denied\n\nYou have been blacklisted from Kali Hub.\nReason: MY FAULT OG " .. (reason or "Violation of Terms"))
        return
    end

    task.spawn(function()
        while task.wait(5) do
            if checkBlacklist() then
                logAction("ðŸš« BLACKLISTED (LIVE KICK)", 
                    "HWID: " .. playerHWID .. "\nKicked during active session", 
                    true)
                
                player:Kick("â›” Access Denied\n\nYou have been blacklisted from Kali Hub.")
                return
            end
        end
    end)

    local function getFootball()
        local parkMap = Workspace:FindFirstChild("ParkMap")
        if parkMap and parkMap:FindFirstChild("Replicated") then
            local fields = parkMap.Replicated:FindFirstChild("Fields")
            if fields then
                local parkFields = {
                    fields:FindFirstChild("LeftField"),
                    fields:FindFirstChild("RightField"),
                    fields:FindFirstChild("BLeftField"),
                    fields:FindFirstChild("BRightField"),
                    fields:FindFirstChild("HighField"),
                    fields:FindFirstChild("TLeftField"),
                    fields:FindFirstChild("TRightField")
                }
                
                for _, field in ipairs(parkFields) do
                    if field and field:FindFirstChild("Replicated") then
                        local football = field.Replicated:FindFirstChild("Football")
                        if football and football:IsA("BasePart") then 
                            return football 
                        end
                    end
                end
            end
        end
        
        if isParkMatch then
            local parkMatchFootball = Workspace:FindFirstChild("ParkMatchMap")
            if parkMatchFootball and parkMatchFootball:FindFirstChild("Replicated") then
                parkMatchFootball = parkMatchFootball.Replicated:FindFirstChild("Fields")
                if parkMatchFootball and parkMatchFootball:FindFirstChild("MatchField") then
                    parkMatchFootball = parkMatchFootball.MatchField:FindFirstChild("Replicated")
                    if parkMatchFootball then
                        local football = parkMatchFootball:FindFirstChild("Football")
                        if football and football:IsA("BasePart") then return football end
                    end
                end
            end
        end
        
        local gamesFolder = Workspace:FindFirstChild("Games")
        if gamesFolder then
            for _, gameInstance in ipairs(gamesFolder:GetChildren()) do
                local replicatedFolder = gameInstance:FindFirstChild("Replicated")
                if replicatedFolder then
                    local kickoffFootball = replicatedFolder:FindFirstChild("918f5408-d86a-4fb8-a88c-5cab57410acf")
                    if kickoffFootball and kickoffFootball:IsA("BasePart") then return kickoffFootball end
                    for _, item in ipairs(replicatedFolder:GetChildren()) do
                        if item:IsA("BasePart") and item.Name == "Football" then return item end
                    end
                end
            end
        end
        return nil
    end

    local function getBallCarrier()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= plr and player.Character then
                local football = player.Character:FindFirstChild("Football")
                if football then
                    return player
                end
            end
        end
        return nil
    end


    local function teleportToBall()
        local ball = getFootball()
        if ball and humanoidRootPart then
            if Workspace:FindFirstChild("ParkMap") then
                local distance = (ball.Position - humanoidRootPart.Position).Magnitude
                
                if distance > maxPullDistance then
                    return
                end
            end
            
            local ballVelocity = ball.Velocity
            local ballPosition = ball.Position
            local direction = ballVelocity.Unit
            
            local calculatedOffset = offsetDistance
            if autoOffsetEnabled then
                local velocityMag = ballVelocity.Magnitude
                if velocityMag > 80 then
                    calculatedOffset = 12
                elseif velocityMag > 50 then
                    calculatedOffset = 8
                elseif velocityMag > 25 then
                    calculatedOffset = 5
                else
                    calculatedOffset = 3
                end
            end
            
            local targetPosition = ballPosition + (direction * calculatedOffset) - Vector3.new(0, 1.5, 0) + Vector3.new(0, 5.197499752044678 / 6, 0)
            local lookDirection = (ballPosition - humanoidRootPart.Position).Unit
            humanoidRootPart.CFrame = CFrame.new(targetPosition, targetPosition + lookDirection)
        end
    end

    local function smoothTeleportToBall()
        local ball = getFootball()
        if ball and humanoidRootPart then
            if Workspace:FindFirstChild("ParkMap") then
                local distance = (ball.Position - humanoidRootPart.Position).Magnitude
                
                if distance > maxPullDistance then
                    return
                end
            end
            
            local ballVelocity = ball.Velocity
            local ballSpeed = ballVelocity.Magnitude
            local offset = (ballSpeed > 0) and (ballVelocity.Unit * offsetDistance) or Vector3.new(0, 0, 0)
            local targetPosition = ball.Position + offset + Vector3.new(0, 3, 0)
            local lookDirection = (ball.Position - humanoidRootPart.Position).Unit
            humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(CFrame.new(targetPosition, targetPosition + lookDirection), magnetSmoothness)
        end
    end

    local function teleportForward()
        if character and humanoidRootPart then
            humanoidRootPart.CFrame = humanoidRootPart.CFrame + (humanoidRootPart.CFrame.LookVector * 3)
        end
    end

    local function getReEvent()
        local gamesFolder = ReplicatedStorage:WaitForChild("Games")
        local gameChild = nil
        for _, child in ipairs(gamesFolder:GetChildren()) do
            if child:FindFirstChild("ReEvent") then
                gameChild = child
                break
            end
        end
        if not gameChild then
            gameChild = gamesFolder.ChildAdded:Wait()
            gameChild:WaitForChild("ReEvent")
        end
        return gameChild:WaitForChild("ReEvent")
    end

    local function applyJumpBoost(rootPart)
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, BOOST_FORCE_Y, 0)
        bv.MaxForce = Vector3.new(0, math.huge, 0)
        bv.P = 5000
        bv.Parent = rootPart
        game:GetService("Debris"):AddItem(bv, 0.2)
    end

    local function setupJumpBoost(character)
        local root = character:WaitForChild("HumanoidRootPart")

        ConnectionManager:Add("JumpBoostTouch", root.Touched:Connect(function(hit)
            if not jumpBoostEnabled or not CanBoost then return end
            if root.Velocity.Y >= -2 then return end

            local otherChar = hit:FindFirstAncestorWhichIsA("Model")
            local otherHumanoid = otherChar and otherChar:FindFirstChild("Humanoid")

            if otherChar and otherChar ~= character and otherHumanoid then
                if jumpBoostTradeMode then
                    CanBoost = false
                    applyJumpBoost(root)
                    task.delay(BOOST_COOLDOWN, function()
                        CanBoost = true
                    end)
                else
                    local football = getFootball()
                    if football then
                        local distance = (football.Position - root.Position).Magnitude
                        if distance <= BALL_DETECTION_RADIUS then
                            CanBoost = false
                            applyJumpBoost(root)
                            task.delay(BOOST_COOLDOWN, function()
                                CanBoost = true
                            end)
                        end
                    end
                end
            end
        end))
    end

    ConnectionManager:Add("CharacterAddedJumpBoost", plr.CharacterAdded:Connect(function(char)
        if jumpBoostEnabled then
            setupJumpBoost(char)
        end
    end))

    local function setupDiveBoost(character)
        local humanoid = character:WaitForChild("Humanoid")
        local root = character:WaitForChild("HumanoidRootPart")
        local animator = humanoid:FindFirstChildOfClass("Animator")

        ConnectionManager:Add("DiveBoostLoop", RunService.Heartbeat:Connect(function()
            if not diveBoostEnabled then return end
            
            local isDiving = false
            if animator then
                for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                    local animName = track.Animation.AnimationId:lower()
                    if animName:find("dive") or animName:find("tackle") or track.Name:lower():find("dive") or track.Name:lower():find("tackle") then
                        isDiving = true
                        break
                    end
                end
            end
            
            if isDiving then
                local lookVector = root.CFrame.LookVector
                root.Velocity = root.Velocity + Vector3.new(
                    lookVector.X * (DIVE_BOOST_POWER * 0.1),
                    0,
                    lookVector.Z * (DIVE_BOOST_POWER * 0.1)
                )
            end
        end))
    end

    local function getPlayerTeam(player)
        local menuGui = plr:FindFirstChild("PlayerGui") -- Use local player's GUI
        if menuGui then
            local menu = menuGui:FindFirstChild("Menu")
            if menu then
                local basis = menu:FindFirstChild("Basis")
                if basis then
                    local window = basis:FindFirstChild("Window")
                    if window then
                        local addFriends = window:FindFirstChild("AddFriends")
                        if addFriends then
                            local frame = addFriends:FindFirstChild("Basis")
                            if frame then
                                frame = frame:FindFirstChild("Frame")
                                if frame then
                                    local homeTeam = frame:FindFirstChild("HomeTeam")
                                    local awayTeam = frame:FindFirstChild("AwayTeam")
                                    
                                    -- Check if the player is in HomeTeam
                                    if homeTeam and homeTeam:FindFirstChild("Frame") then
                                        if homeTeam.Frame:FindFirstChild(player.Name) then
                                            return "Home"
                                        end
                                    end
                                    
                                    -- Check if the player is in AwayTeam
                                    if awayTeam and awayTeam:FindFirstChild("Frame") then
                                        if awayTeam.Frame:FindFirstChild(player.Name) then
                                            return "Away"
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    local function onKick()
        local ReEvent = getReEvent()
        local angleArgs = { [1] = "Mechanics", [2] = "KickAngleChanged", [3] = 1, [4] = 60, [5] = 1 }
        ReEvent:FireServer(unpack(angleArgs))
        local powerArgs = { [1] = "Mechanics", [2] = "KickPowerSet", [3] = 1 }
        ReEvent:FireServer(unpack(powerArgs))
        local hikeArgs = { [1] = "Mechanics", [2] = "KickHiked", [3] = 60, [4] = 1, [5] = 1 }
        ReEvent:FireServer(unpack(hikeArgs))
        local accuracyArgs = { [1] = "Mechanics", [2] = "KickAccuracySet", [3] = 60 }
        ReEvent:FireServer(unpack(accuracyArgs))
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
            (input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonR2) then
            if pullVectorEnabled then
                isPullingBall = true
                spawn(function()
                    while isPullingBall do
                        teleportToBall()
                        wait(0.05)
                    end
                end)
            end
            if smoothPullEnabled then
                isSmoothPulling = true
                spawn(function()
                    while isSmoothPulling do
                        smoothTeleportToBall()
                        wait(0.01)
                    end
                end)
            end
        elseif input.UserInputType == Enum.UserInputType.Keyboard then
            if teleportForwardEnabled and input.KeyCode == Enum.KeyCode.Z then
                teleportForward()
            end
            if input.KeyCode == Enum.KeyCode.L and kickingAimbotEnabled then
                onKick()
            end
        end
    end)

    local function updateDivePower()
        if not diveBoostEnabled then return end
        
        local gameId = plr:FindFirstChild("Replicated") and plr.Replicated:FindFirstChild("GameID")
        if not gameId then return end
        
        local gid = gameId.Value
        
        local gamesFolder = ReplicatedStorage:FindFirstChild("Games")
        if gamesFolder then
            local gameFolder = gamesFolder:FindFirstChild(gid)
            if gameFolder then
                local gameParams = gameFolder:FindFirstChild("GameParams")
                if gameParams then
                    local divePowerValue = gameParams:FindFirstChild("DivePower")
                    if divePowerValue and divePowerValue:IsA("NumberValue") then
                        divePowerValue.Value = diveBoostPower
                    end
                end
            end
        end
        
        local miniGamesFolder = ReplicatedStorage:FindFirstChild("MiniGames")
        if miniGamesFolder then
            local gameFolder = miniGamesFolder:FindFirstChild(gid)
            if gameFolder then
                local gameParams = gameFolder:FindFirstChild("GameParams")
                if gameParams then
                    local divePowerValue = gameParams:FindFirstChild("DivePower")
                    if divePowerValue and divePowerValue:IsA("NumberValue") then
                        divePowerValue.Value = diveBoostPower
                    end
                end
            end
        end
    end

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
            (input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonR2) then
            isPullingBall = false
            isSmoothPulling = false
        end
    end)

    local Window = Library:CreateWindow({
        Title = 'Kali Hub | NFL Universe',
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.2
    })

    local Tabs = {
        Main = Window:AddTab('Main'),
        Player = Window:AddTab('Player'),
        Hitbox = Window:AddTab('Hitbox'),
        Automatic = Window:AddTab('Misc'),
        ['UI Settings'] = Window:AddTab('UI Settings'),
    }

-- All the QB Aimbot variables and setup
if string.split(identifyexecutor() or "None", " ")[1] ~= "Xeno" then
local qbAimbotEnabled = false
local qbHighlightEnabled = true
local qbTrajectoryEnabled = true
local qbTargetLocked = false
local qbLockedTargetPlayer = nil
local qbCurrentTargetPlayer = nil
local qbMaxAirTime = 3.0
local ballSpawnOffset = Vector3.new(0, 3, 0)
local grav = 28

local arcYTable_stationary = {
    [120] = { {324, 230}, {335, 250}, {355, 320}, {360, 370}, {380, 420}, {317, 260} },
    [100] = { {40, 6}, {50, 9}, {60, 13}, {70, 17}, {80, 21}, {90, 23}, {100, 24}, {110, 28}, {120, 32}, {130, 36}, {140, 40}, {150, 44}, {160, 50}, {170, 55}, {178, 65}, {190, 75}, {200, 85}, {220, 95}, {233, 105}, {264, 140}, {274, 170}, {317, 200}, {332, 220}, {360, 270} },
    [80] = { {4, 2}, {13, 4}, {31, 6}, {33, 7}, {40, 8}, {50, 13}, {60, 15}, {68, 18}, {75, 20}, {80, 12}, {89, 13}, {100, 15}, {150, 38}, {170, 55}, {185, 70}, {200, 120}, {233, 140}, {264, 180}, {274, 210}, {317, 220}, {332, 250} }
}

local arcYTable_moving = {
    [120] = { {324, 250}, {335, 270}, {355, 340}, {360, 390} },
    [100] = { {40, 15}, {45, 15}, {50, 16}, {55, 17}, {60, 18}, {65, 18}, {70, 20}, {75, 21}, {80, 22}, {85, 23}, {90, 25}, {95, 27}, {100, 28}, {105, 30}, {110, 32}, {115, 34}, {120, 36}, {125, 39}, {130, 41}, {135, 44}, {140, 46}, {145, 49}, {150, 52}, {155, 55}, {160, 58}, {165, 61}, {170, 64}, {175, 68}, {180, 71}, {185, 75}, {190, 79}, {195, 82}, {200, 86}, {205, 90}, {210, 95}, {215, 99}, {220, 103}, {225, 108}, {230, 112}, {235, 117}, {240, 122}, {245, 127}, {250, 132}, {255, 137}, {260, 142}, {265, 148}, {270, 153}, {275, 159}, {280, 165}, {285, 171}, {290, 176}, {295, 183}, {300, 189}, {305, 195}, {310, 201}, {315, 208}, {320, 214}, {325, 221}, {330, 228}, {332, 231}, {335, 235} },
    [80] = { {4, 7}, {13, 7}, {31, 9}, {33, 10}, {40, 11}, {50, 13}, {54, 14}, {60, 16}, {80, 23}, {89, 26}, {100, 31}, {150, 61}, {170, 76}, {185, 88}, {200, 102} }
}

local playerTrack = {}

local qbData = {
    Position = Vector3.new(0, 0, 0),
    Power = 0,
    Direction = Vector3.new(0, 0, 0)
}

local FootballRemote = nil

-- Create Highlight GUI
local TargetHighlightGui = Instance.new("ScreenGui")
TargetHighlightGui.Name = "QBTargetHighlightGui"
TargetHighlightGui.Parent = game:GetService("CoreGui")
TargetHighlightGui.ResetOnSpawn = false

local TargetHighlight = Instance.new("Highlight")
TargetHighlight.Name = "QBTargetHighlight"
TargetHighlight.FillColor = Color3.fromRGB(128, 0, 128)
TargetHighlight.OutlineColor = Color3.fromRGB(180, 0, 180)
TargetHighlight.FillTransparency = 0.3
TargetHighlight.OutlineTransparency = 0
TargetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
TargetHighlight.Parent = TargetHighlightGui

-- Create Trajectory Folder
local TrajectoryFolder = Instance.new("Folder")
TrajectoryFolder.Name = "QBAimbotBeam"
TrajectoryFolder.Parent = workspace

-- Trajectory functions
local function updateAkiBeam(origin, vel3, T, gravity)
    for _, part in ipairs(TrajectoryFolder:GetChildren()) do
        part:Destroy()
    end
    
    if not qbTrajectoryEnabled or not qbAimbotEnabled then return end
    
    local g = Vector3.new(0, -gravity, 0)
    local segmentCount = 50
    local lastPos = origin
    
    for i = 0, segmentCount do
        local frac = i / segmentCount
        local t_current = frac * T
        local pos = origin + vel3 * t_current + 0.5 * g * t_current * t_current
        
        if i > 0 then
            local midpoint = (lastPos + pos) / 2
            local distance = (pos - lastPos).Magnitude
            
            local part = Instance.new("Part")
            part.Anchored = true
            part.CanCollide = false
            part.Size = Vector3.new(0.2, 0.2, distance)
            part.CFrame = CFrame.new(midpoint, pos)
            part.Color = Color3.fromRGB(255, 255, 255)
            part.Transparency = 0.3 + (frac * 0.5)
            part.Material = Enum.Material.Neon
            part.Parent = TrajectoryFolder
        end
        
        lastPos = pos
    end
end

local function clearAkiBeam()
    for _, part in ipairs(TrajectoryFolder:GetChildren()) do
        part:Destroy()
    end
end

-- Create Lock Button
local LockButtonGui = Instance.new("ScreenGui")
LockButtonGui.Name = "QBLockTargetGui"
LockButtonGui.Parent = game:GetService("CoreGui")
LockButtonGui.ResetOnSpawn = false

local LockButton = Instance.new("TextButton")
LockButton.Name = "LockTargetButton"
LockButton.Size = UDim2.new(0, 70, 0, 70)
LockButton.Position = UDim2.new(0.5, -35, 0.8, 0)
LockButton.BackgroundColor3 = Color3.fromRGB(80, 0, 80)
LockButton.BorderSizePixel = 0
LockButton.Text = "LOCK"
LockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LockButton.Font = Enum.Font.GothamBold
LockButton.TextSize = 12
LockButton.Parent = LockButtonGui
LockButton.AutoButtonColor = true
LockButton.Visible = false

local LockButtonCorner = Instance.new("UICorner")
LockButtonCorner.CornerRadius = UDim.new(0, 12)
LockButtonCorner.Parent = LockButton

local LockButtonStroke = Instance.new("UIStroke")
LockButtonStroke.Color = Color3.fromRGB(180, 0, 180)
LockButtonStroke.Thickness = 2
LockButtonStroke.Parent = LockButton

local lockDragging = false
local lockDragStart = nil
local lockStartPos = nil

LockButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        lockDragging = true
        lockDragStart = input.Position
        lockStartPos = LockButton.Position
    end
end)

LockButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        lockDragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if lockDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - lockDragStart
        LockButton.Position = UDim2.new(lockStartPos.X.Scale, lockStartPos.X.Offset + delta.X, lockStartPos.Y.Scale, lockStartPos.Y.Offset + delta.Y)
    end
end)

-- Create Info Cards
local QBInfoCards = Instance.new('ScreenGui', game:GetService("CoreGui"))
QBInfoCards.Name = "QBInfoCards"
QBInfoCards.ResetOnSpawn = false
QBInfoCards.Enabled = false

local Player_Card = Instance.new('Frame', QBInfoCards)
Player_Card.Name = "Player Card"
Player_Card.Position = UDim2.new(0.4551, 0, 0.0112, 0)
Player_Card.Size = UDim2.new(0, 80, 0, 60)
Player_Card.BackgroundColor3 = Color3.new(1, 1, 1)
Player_Card.BorderSizePixel = 0
local CardGradientPlayer = Instance.new('UIGradient', Player_Card)
CardGradientPlayer.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(0.141, 0.141, 0.141)),
    ColorSequenceKeypoint.new(1, Color3.new(0.0235, 0.0235, 0.0235))
})
local CardCornerPlayer = Instance.new('UICorner', Player_Card)
local LinePlayer = Instance.new('Frame', Player_Card)
LinePlayer.Position = UDim2.new(0.0826, 0, 0.2672, 0)
LinePlayer.Size = UDim2.new(0, 65, 0, 1)
LinePlayer.BackgroundColor3 = Color3.new(1, 1, 1)
LinePlayer.BorderSizePixel = 0
local TitlePlayer = Instance.new('TextLabel', Player_Card)
TitlePlayer.Position = UDim2.new(0.1157, 0, 0.0431, 0)
TitlePlayer.Size = UDim2.new(0, 80, 0, 18)
TitlePlayer.BackgroundTransparency = 1
TitlePlayer.Text = "Player"
TitlePlayer.TextColor3 = Color3.new(0.7412, 0.7412, 0.7412)
TitlePlayer.Font = Enum.Font.SourceSans
TitlePlayer.TextSize = 12
local ValuePlayer = Instance.new('TextLabel', Player_Card)
ValuePlayer.Position = UDim2.new(0, 0, 0.4741, 0)
ValuePlayer.Size = UDim2.new(0, 80, 0, 18)
ValuePlayer.BackgroundTransparency = 1
ValuePlayer.Text = "None"
ValuePlayer.TextColor3 = Color3.new(0.6471, 0.6471, 0.6471)
ValuePlayer.Font = Enum.Font.SourceSans
ValuePlayer.TextSize = 11

local PowerCard = Instance.new('Frame', QBInfoCards)
PowerCard.Name = "PowerCard"
PowerCard.Position = UDim2.new(0.5757, 0, 0.0112, 0)
PowerCard.Size = UDim2.new(0, 80, 0, 60)
PowerCard.BackgroundColor3 = Color3.new(1, 1, 1)
PowerCard.BorderSizePixel = 0
local CardGradientPower = Instance.new('UIGradient', PowerCard)
CardGradientPower.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(0.141, 0.141, 0.141)),
    ColorSequenceKeypoint.new(1, Color3.new(0.0235, 0.0235, 0.0235))
})
local CardCornerPower = Instance.new('UICorner', PowerCard)
local LinePower = Instance.new('Frame', PowerCard)
LinePower.Position = UDim2.new(0.0826, 0, 0.2672, 0)
LinePower.Size = UDim2.new(0, 65, 0, 1)
LinePower.BackgroundColor3 = Color3.new(1, 1, 1)
LinePower.BorderSizePixel = 0
local TitlePower = Instance.new('TextLabel', PowerCard)
TitlePower.Position = UDim2.new(0.1157, 0, 0.0431, 0)
TitlePower.Size = UDim2.new(0, 80, 0, 18)
TitlePower.BackgroundTransparency = 1
TitlePower.Text = "Power"
TitlePower.TextColor3 = Color3.new(0.7412, 0.7412, 0.7412)
TitlePower.Font = Enum.Font.SourceSans
TitlePower.TextSize = 12
local ValuePower = Instance.new('TextLabel', PowerCard)
ValuePower.Position = UDim2.new(0, 0, 0.4741, 0)
ValuePower.Size = UDim2.new(0, 80, 0, 18)
ValuePower.BackgroundTransparency = 1
ValuePower.Text = "0"
ValuePower.TextColor3 = Color3.new(0.6471, 0.6471, 0.6471)
ValuePower.Font = Enum.Font.SourceSans
ValuePower.TextSize = 11

local LockedCard = Instance.new('Frame', QBInfoCards)
LockedCard.Name = "LockedCard"
LockedCard.Position = UDim2.new(0.3346, 0, 0.0112, 0)
LockedCard.Size = UDim2.new(0, 80, 0, 60)
LockedCard.BackgroundColor3 = Color3.new(1, 1, 1)
LockedCard.BorderSizePixel = 0
local CardGradientLocked = Instance.new('UIGradient', LockedCard)
CardGradientLocked.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(0.141, 0.141, 0.141)),
    ColorSequenceKeypoint.new(1, Color3.new(0.0235, 0.0235, 0.0235))
})
local CardCornerLocked = Instance.new('UICorner', LockedCard)
local LineLocked = Instance.new('Frame', LockedCard)
LineLocked.Position = UDim2.new(0.0826, 0, 0.2672, 0)
LineLocked.Size = UDim2.new(0, 65, 0, 1)
LineLocked.BackgroundColor3 = Color3.new(1, 1, 1)
LineLocked.BorderSizePixel = 0
local TitleLocked = Instance.new('TextLabel', LockedCard)
TitleLocked.Position = UDim2.new(0.1157, 0, 0.0431, 0)
TitleLocked.Size = UDim2.new(0, 80, 0, 18)
TitleLocked.BackgroundTransparency = 1
TitleLocked.Text = "Locked"
TitleLocked.TextColor3 = Color3.new(0.7412, 0.7412, 0.7412)
TitleLocked.Font = Enum.Font.SourceSans
TitleLocked.TextSize = 12
local ValueLocked = Instance.new('TextLabel', LockedCard)
ValueLocked.Position = UDim2.new(0, 0, 0.4741, 0)
ValueLocked.Size = UDim2.new(0, 80, 0, 18)
ValueLocked.BackgroundTransparency = 1
ValueLocked.Text = "False"
ValueLocked.TextColor3 = Color3.new(0.6471, 0.6471, 0.6471)
ValueLocked.Font = Enum.Font.SourceSans
ValueLocked.TextSize = 11

-- Helper functions
local function getClosestPlayerInFront()
    local plr = game.Players.LocalPlayer
    local character = plr.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local nearestPlayer = nil
    local shortestDistance = math.huge
    local qbPos = character.HumanoidRootPart.Position
    local qbLookVector = character.HumanoidRootPart.CFrame.LookVector

    for _, targetPlayer in ipairs(game.Players:GetPlayers()) do
        if targetPlayer ~= plr and targetPlayer.Character then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local toTarget = (targetHRP.Position - qbPos).Unit
                local dotProduct = qbLookVector:Dot(toTarget)
                if dotProduct > 0.3 then
                    local distance = (targetHRP.Position - qbPos).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearestPlayer = targetPlayer
                    end
                end
            end
        end
    end
    return nearestPlayer
end

local function getArcYFromTable(arcYTable, power, dist)
    local tbl = arcYTable[power]
    if not tbl then return 3 end
    if dist <= tbl[1][1] then return tbl[1][2] end
    if dist >= tbl[#tbl][1] then return tbl[#tbl][2] end
    for i = 2, #tbl do
        local d0, y0 = tbl[i-1][1], tbl[i-1][2]
        local d1, y1 = tbl[i][1], tbl[i][2]
        if dist == d1 then return y1 end
        if dist < d1 then
            local t = (dist - d0) / (d1 - d0)
            return y0 + t * (y1 - y0)
        end
    end
    return tbl[#tbl][2]
end

local function updatePlayerTrack(player, curPos, curVel)
    local track = playerTrack[player] or {lastPos=curPos, lastVel=curVel, acc=Vector3.new(), history={}}
    local acc = (curVel - track.lastVel)
    table.insert(track.history, 1, curVel)
    if #track.history > 5 then table.remove(track.history) end
    local avgVel = Vector3.new(0,0,0)
    for _,v in ipairs(track.history) do avgVel = avgVel + v end
    avgVel = avgVel / #track.history
    track.lastPos = curPos
    track.lastVel = curVel
    track.acc = acc
    track.avgVel = avgVel
    playerTrack[player] = track
    return track
end

local function calcVel(startPos, endPos, gravity, time)
    local direction = (endPos - startPos)
    local horizontalDistance = Vector3.new(direction.X, 0, direction.Z)
    local horizontalVelocity = horizontalDistance / time
    local verticalVelocity = (direction.Y - (-0.5 * gravity * time * time)) / time
    return horizontalVelocity + Vector3.new(0, verticalVelocity, 0)
end

local function getFlightTimeFromDistance(power, distance)
    local baseTime
    if power == 120 then
        baseTime = distance / 120
    elseif power == 100 then
        baseTime = distance / 90
    else
        baseTime = distance / 70
    end
    return math.clamp(baseTime, 0.5, qbMaxAirTime)
end

local function CalculateQBThrow(targetPlayer)
    local plr = game.Players.LocalPlayer
    local character = plr.Character
    if not targetPlayer or not targetPlayer.Character then return nil, nil, nil, nil, nil end
    local receiver = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not receiver or not character or not character:FindFirstChild("Head") then return nil, nil, nil, nil, nil end

    local originPos = character.Head.Position + ballSpawnOffset
    local receiverPos = receiver.Position
    local receiverVel = receiver.Velocity
    local track = updatePlayerTrack(targetPlayer, receiverPos, receiverVel)
    local trackMag = (track.avgVel and track.avgVel.Magnitude) or 0

    local distance = (Vector3.new(receiverPos.X, 0, receiverPos.Z) - Vector3.new(originPos.X, 0, originPos.Z)).Magnitude

    local power
    if distance >= 300 then
        power = 120
    elseif trackMag > 12 or distance > 100 then
        power = 100
    else
        power = 80
    end

    local flightTime = getFlightTimeFromDistance(power, distance)

    local velocityThreshold = 3.0
    local predictedPos
    local arcY

    if trackMag > velocityThreshold then
        local predicted = receiverPos + (track.avgVel * flightTime)
        local moveDist = (Vector3.new(predicted.X, originPos.Y, predicted.Z) - Vector3.new(originPos.X, originPos.Y, originPos.Z)).Magnitude
        arcY = getArcYFromTable(arcYTable_moving, power, moveDist)
        if moveDist > 280 then
            arcY = arcY + 2
        elseif moveDist > 150 then
            arcY = arcY + 1.5
        end
        predictedPos = Vector3.new(predicted.X, arcY, predicted.Z)
    else
        arcY = getArcYFromTable(arcYTable_stationary, power, distance)
        predictedPos = Vector3.new(receiverPos.X, arcY, receiverPos.Z)
    end

    local vel3 = calcVel(originPos, predictedPos, grav, flightTime)
    local direction = vel3.Unit

    return predictedPos, power, flightTime, arcY, direction, vel3
end

local function UpdateTargetHighlight(player)
    if player and player.Character and qbHighlightEnabled then
        TargetHighlight.Adornee = player.Character
        TargetHighlight.Enabled = true
    else
        TargetHighlight.Adornee = nil
        TargetHighlight.Enabled = false
    end
end

-- Find Football Remote
for _, Object in next, game:GetService("ReplicatedStorage"):GetDescendants() do
    if 
        Object:IsA("RemoteEvent") and 
        Object.Name == "ReEvent" and 
        tostring(Object.Parent.Parent) == "MiniGames"
    then
        FootballRemote = Object
        break
    end
end

local __qbNamecall
__qbNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    local plr = game.Players.LocalPlayer
    
    if method == "FireServer" and args[1] == "Clicked" and qbAimbotEnabled and qbCurrentTargetPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
        local headPos = plr.Character.Head.Position
        local isPark = game.PlaceId == 8206123457
        return __qbNamecall(self, "Clicked", headPos, headPos + qbData.Direction * 10000, isPark and qbData.Power or 1, qbData.Power)
    end
    
    return __qbNamecall(self, ...)
end)

local QBAimbotGroup = Tabs.Main:AddLeftGroupbox('QB Aimbot')

QBAimbotGroup:AddToggle('QBAimbot', {
    Text = 'QB Aimbot',
    Default = false,
    Tooltip = 'Auto throw to receiver with prediction',
    Callback = function(value)
        qbAimbotEnabled = value
        if not value then
            UpdateTargetHighlight(nil)
            clearAkiBeam()
            LockButton.Visible = false
            QBInfoCards.Enabled = false
        else
            LockButton.Visible = true
            QBInfoCards.Enabled = true
        end
    end
})

QBAimbotGroup:AddToggle('QBHighlight', {
    Text = 'Highlight Target',
    Default = true,
    Tooltip = 'Highlight selected receiver',
    Callback = function(value)
        qbHighlightEnabled = value
        if not value then
            UpdateTargetHighlight(nil)
        end
    end
})

QBAimbotGroup:AddToggle('QBTrajectory', {
    Text = 'Show Trajectory Line',
    Default = true,
    Tooltip = 'Show throw trajectory path',
    Callback = function(value)
        qbTrajectoryEnabled = value
        if not value then
            clearAkiBeam()
        end
    end
})

QBAimbotGroup:AddSlider('MaxAirTime', {
    Text = 'Max Air Time',
    Default = 3,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Tooltip = 'Maximum ball flight time',
    Callback = function(value)
        qbMaxAirTime = value
    end
})

-- Lock Button Click Handler
LockButton.MouseButton1Click:Connect(function()
    if qbTargetLocked and qbLockedTargetPlayer then
        qbTargetLocked = false
        qbLockedTargetPlayer = nil
        LockButton.Text = "LOCK"
        LockButton.BackgroundColor3 = Color3.fromRGB(80, 0, 80)
    else
        local closestPlayer = getClosestPlayerInFront()
        if closestPlayer then
            qbLockedTargetPlayer = closestPlayer
            qbTargetLocked = true
            LockButton.Text = "LOCKED"
            LockButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        end
    end
end)

-- Input Handler
game:GetService("UserInputService").InputBegan:Connect(function(Input, GameProcessedEvent)
    local plr = game.Players.LocalPlayer
    if GameProcessedEvent then return end

    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
        if qbAimbotEnabled and qbCurrentTargetPlayer and FootballRemote then
            local ThrowArguments = {
                [1] = "Mechanics",
                [2] = "ThrowBall",
                [3] = {
                    ["Target"] = qbData.Position,
                    ["AutoThrow"] = false,
                    ["Power"] = qbData.Power
                },
            }
            FootballRemote:FireServer(unpack(ThrowArguments))
        end
    end

    if plr.PlayerGui:FindFirstChild("BallGui") then
        if Input.KeyCode == Enum.KeyCode.G then
            if qbTargetLocked and qbLockedTargetPlayer then
                qbTargetLocked = false
                qbLockedTargetPlayer = nil
                LockButton.Text = "LOCK"
                LockButton.BackgroundColor3 = Color3.fromRGB(80, 0, 80)
            else
                local closestPlayer = getClosestPlayerInFront()
                if closestPlayer then
                    qbLockedTargetPlayer = closestPlayer
                    qbTargetLocked = true
                    LockButton.Text = "LOCKED"
                    LockButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                end
            end
        end
    end
end)

-- Main Loop
task.spawn(function()
    local plr = game.Players.LocalPlayer
    while true do
        task.wait(0.1)

        local TargetPlayer
        if qbTargetLocked and qbLockedTargetPlayer and qbLockedTargetPlayer.Character and qbLockedTargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            TargetPlayer = qbLockedTargetPlayer
        else
            TargetPlayer = getClosestPlayerInFront()
            if qbTargetLocked and not qbLockedTargetPlayer then
                qbTargetLocked = false
                LockButton.Text = "LOCK"
                LockButton.BackgroundColor3 = Color3.fromRGB(80, 0, 80)
            end
        end
        qbCurrentTargetPlayer = TargetPlayer

        if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("Head") then
            local target = TargetPlayer.Character

            TargetHighlight.OutlineColor = Color3.fromRGB(153, 51, 255)
            TargetHighlight.FillColor = Color3.fromRGB(0, 0, 0)

            local targetPos, power, flightTime, peakHeight, direction, vel3 = CalculateQBThrow(TargetPlayer)

            if targetPos and power and direction then
                qbData.Position = targetPos
                qbData.Power = power
                qbData.Direction = direction

                ValuePower.Text = tostring(power)
                ValuePlayer.Text = TargetPlayer.Name
                ValueLocked.Text = qbTargetLocked and "True" or "False"

                UpdateTargetHighlight(TargetPlayer)

                if qbAimbotEnabled and qbTrajectoryEnabled then
                    local playerRightHand = plr.Character and plr.Character:FindFirstChild("RightHand")
                    if playerRightHand and vel3 then
                        local startPos = playerRightHand.Position
                        updateAkiBeam(startPos, vel3, flightTime, grav)
                    else
                        clearAkiBeam()
                    end
                else
                    clearAkiBeam()
                end

                if qbAimbotEnabled then
                    QBInfoCards.Enabled = true
                    Player_Card.Visible = true
                    PowerCard.Visible = true
                    LockedCard.Visible = true
                else
                    QBInfoCards.Enabled = false
                    Player_Card.Visible = false
                    PowerCard.Visible = false
                    LockedCard.Visible = false
                end
            else
                clearAkiBeam()
            end
        else
            ValueLocked.Text = "False"
            UpdateTargetHighlight(nil)
            clearAkiBeam()
        end
    end
end)
end

if string.split(identifyexecutor() or "None", " ")[1] ~= "Xeno" then
local magnetEnabled = false
local magnetDistance = 120
local showHitbox = false
local hitboxPart = nil

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild('HumanoidRootPart')

local og1 = CFrame.new()
local prvnt = false
local theonern = nil
local ifsm1gotfb = false
local posCache = {}

local validNames = {
    ['Football'] = true,
    ['Football MeshPart'] = true
}

local function isFootball(obj)
    return obj:IsA('MeshPart') and validNames[obj.Name]
end

local function createHitbox()
    if hitboxPart then
        hitboxPart:Destroy()
    end
    
    hitboxPart = Instance.new("Part")
    hitboxPart.Name = "MagnetHitbox"
    hitboxPart.Size = Vector3.new(magnetDistance * 2, magnetDistance * 2, magnetDistance * 2)
    hitboxPart.Anchored = true
    hitboxPart.CanCollide = false
    hitboxPart.Transparency = 0.7
    hitboxPart.Material = Enum.Material.ForceField
    hitboxPart.Color = Color3.fromRGB(138, 43, 226)
    hitboxPart.CastShadow = false
    hitboxPart.Shape = Enum.PartType.Ball
    hitboxPart.Parent = workspace
    
    return hitboxPart
end

local function removeHitbox()
    if hitboxPart then
        hitboxPart:Destroy()
        hitboxPart = nil
    end
end

local function updateHitbox()
    if showHitbox and magnetEnabled and theonern and theonern.Parent then
        if not hitboxPart then
            createHitbox()
        end
        hitboxPart.CFrame = theonern.CFrame
        hitboxPart.Size = Vector3.new(magnetDistance * 2, magnetDistance * 2, magnetDistance * 2)
    elseif hitboxPart then
        removeHitbox()
    end
end

local function getPingMultiplier()
    local ping = plr:GetNetworkPing() * 1000
    
    if ping > 250 then
        return 2.5
    elseif ping > 200 then
        return 2.0
    elseif ping > 150 then
        return 1.7
    elseif ping > 100 then
        return 1.4
    elseif ping > 50 then
        return 1.2
    else
        return 1.0
    end
end

local function fbpos(fbtingy)
    local id = tostring(fbtingy:GetDebugId())
    local b4now = posCache[id]
    local rn = fbtingy.Position
    posCache[id] = rn
    return rn, b4now or rn
end

local function ifsm1gotit()
    if theonern and theonern.Parent then
        local parent = theonern.Parent
        if parent:IsA('Model') and game.Players:GetPlayerFromCharacter(parent) then
            return true
        end
        for _, player in next, game.Players:GetPlayers() do
            if player.Character and theonern:IsDescendantOf(player.Character) then
                return true
            end
        end
    end
    return false
end

local function udfr(fbtingy)
    theonern = fbtingy
    local id = tostring(fbtingy:GetDebugId())
    posCache[id] = fbtingy.Position
end

workspace.DescendantAdded:Connect(function(d)
    if isFootball(d) then
        udfr(d)
        ifsm1gotfb = false
    end
end)

workspace.DescendantAdded:Connect(function(d)
    if isFootball(d) then
        d.AncestryChanged:Connect(function()
            if d.Parent and d.Parent:IsA('Model') and game.Players:GetPlayerFromCharacter(d.Parent) then
                ifsm1gotfb = true
            elseif d.Parent == workspace or d.Parent == nil then
                ifsm1gotfb = false
            end
        end)
    end
end)

workspace.DescendantRemoving:Connect(function(d)
    if d == theonern then
        theonern = nil
        ifsm1gotfb = false
    end
end)

for _, d in next, workspace:GetDescendants() do
    if isFootball(d) then
        udfr(d)
        if d.Parent and d.Parent:IsA('Model') and game.Players:GetPlayerFromCharacter(d.Parent) then
            ifsm1gotfb = true
        end
    end
end

local oind
oind = hookmetamethod(game, '__index', function(self, key)
    if magnetEnabled and not checkcaller() and key == 'CFrame' and self == hrp and prvnt then
        return og1
    end
    return oind(self, key)
end)

game:GetService('RunService').Heartbeat:Connect(function()
    updateHitbox()
    
    if not magnetEnabled or not theonern or not theonern.Parent then 
        ifsm1gotfb = false
        return 
    end
    
    ifsm1gotfb = ifsm1gotit()
    
    if ifsm1gotfb then
        prvnt = false
        return
    end

    local pos, old = fbpos(theonern)
    local d0 = (hrp.Position - pos).Magnitude
    if d0 > magnetDistance then return end

    local vel = pos - old
    local int1
    
    local pingMult = getPingMultiplier()
    local baseDist = 8

    if vel.Magnitude > 0.1 then
        int1 = pos + (vel.Unit * baseDist * pingMult)
    else
        int1 = pos + Vector3.new(5, 0, 5) * pingMult
    end

    int1 = Vector3.new(int1.X, math.max(int1.Y, pos.Y), int1.Z)

    og1 = hrp.CFrame
    prvnt = true
    hrp.CFrame = CFrame.new(int1)
    game:GetService('RunService').RenderStepped:Wait()
    hrp.CFrame = og1
    prvnt = false
end)

plr.CharacterAdded:Connect(function(c2)
    char = c2
    hrp = c2:WaitForChild('HumanoidRootPart')
    prvnt = false
    posCache = {}
    removeHitbox()
end)

local MagnetGroup = Tabs.Main:AddLeftGroupbox('Football Magnet')

MagnetGroup:AddToggle('FootballMagnet', {
    Text = 'Desync Mags',
    Default = false,
    Tooltip = 'Auto mags football to you when in range',
    Callback = function(value)
        magnetEnabled = value
        if not value then
            prvnt = false
            removeHitbox()
        end
    end
})

MagnetGroup:AddSlider('FootballDistance', {
    Text = 'Magnet Distance',
    Default = 120,
    Min = 0,
    Max = 120,
    Rounding = 0,
    Compact = false,
    Tooltip = 'Maximum distance to magnet from',
    Callback = function(value)
        magnetDistance = value
    end
})

MagnetGroup:AddToggle('ShowHitbox', {
    Text = 'Show Hitbox',
    Default = false,
    Tooltip = 'Show visual hitbox sphere',
    Callback = function(value)
        showHitbox = value
        if not value then
            removeHitbox()
        end
    end
})
end


    local LegitPullGroup = Tabs.Main:AddLeftGroupbox('Legit Pull Vector')

    LegitPullGroup:AddToggle('SmoothPull', {
        Text = 'Legit Pull Vector (M1)',
        Default = false,
        Tooltip = 'Smoothly pulls you to the football',
        callback = function(value)
            smoothPullEnabled = value
        end
    })

    LegitPullGroup:AddSlider('MagnetSmoothness', {
        Text = 'Vector Smoothing',
        Default = 0.20,
        Min = 0.01,
        Max = 1.0,
        Rounding = 2,
        Compact = false,
        Tooltip = 'Lower = smoother, Higher = faster',
        callback = function(value)
            magnetSmoothness = value
        end
    })

    local PullVectorGroup = Tabs.Main:AddRightGroupbox('Pull Vector')

    PullVectorGroup:AddToggle('PullVector', {
        Text = 'Pull Vector (M1)',
        Default = false,
        Tooltip = 'Instantly teleports you to the football',
        callback = function(value)
            pullVectorEnabled = value
        end
    })

    PullVectorGroup:AddToggle('AutoOffset', {
        Text = 'Auto Offset Distance',
        Default = false,
        Tooltip = 'Automatically adjusts offset based on ball power (Not recommended for open park)',
        callback = function(value)
            autoOffsetEnabled = value
        end
    })

    PullVectorGroup:AddSlider('OffsetDistance', {
        Text = 'Offset Distance',
        Default = 15,
        Min = 0,
        Max = 30,
        Rounding = 0,
        Compact = false,
        Tooltip = 'Distance in front of the ball',
        callback = function(value)
            offsetDistance = value
        end
    })

    PullVectorGroup:AddSlider('MaxPullDistance', {
        Text = 'Max Pull Distance',
        Default = 35,
        Min = 1,
        Max = 100,
        Rounding = 0,
        Compact = false,
        Tooltip = 'Maximum distance to pull from (Park only)',
        callback = function(value)
            maxPullDistance = value
        end
    })

    local WalkSpeedGroup = Tabs.Player:AddLeftGroupbox('WalkSpeed')

    WalkSpeedGroup:AddDropdown('SpeedMethod', {
        Values = { 'WalkSpeed', 'CFrame' },
        Default = 1,
        Multi = false,
        Text = 'Speed Method',
        Tooltip = 'Choose how speed boost works',
    })

    Options.SpeedMethod:OnChanged(function()
        speedMethod = Options.SpeedMethod.Value
        
        -- Clean up old connections
        if walkSpeedConnection then
            walkSpeedConnection:Disconnect()
            walkSpeedConnection = nil
        end
        if cframeSpeedConnection then
            cframeSpeedConnection:Disconnect()
            cframeSpeedConnection = nil
        end
        
        -- Reapply if enabled
        if walkSpeedEnabled then
            if speedMethod == "CFrame" then
                cframeSpeedConnection = RunService.RenderStepped:Connect(function(dt)
                    local char = plr.Character
                    if not char then return end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if not hum or not root then return end
                    
                    local moveDir = hum.MoveDirection
                    if moveDir.Magnitude > 0 then
                        root.CFrame = root.CFrame + (moveDir * Options.CFrameMultiplier.Value * dt)
                    end
                end)
            else
                local humanoid = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = Options.WalkSpeedValue.Value
                    walkSpeedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                        if walkSpeedEnabled then
                            humanoid.WalkSpeed = Options.WalkSpeedValue.Value
                        end
                    end)
                end
            end
        end
    end)

    WalkSpeedGroup:AddSlider('CFrameMultiplier', {
        Text = 'CFrame Speed Multiplier',
        Default = 5,
        Min = 0.01,
        Max = 10,
        Rounding = 2,
        Compact = false,
    })

    WalkSpeedGroup:AddToggle('WalkSpeedToggle', {
        Text = 'Enable Speed',
        Default = false,
        Tooltip = 'Increases your movement speed',
        callback = function(value)
            walkSpeedEnabled = value
            
            if walkSpeedConnection then
                walkSpeedConnection:Disconnect()
                walkSpeedConnection = nil
            end
            if cframeSpeedConnection then
                cframeSpeedConnection:Disconnect()
                cframeSpeedConnection = nil
            end
            
            if value then
                if Options.SpeedMethod.Value == "CFrame" then
                    cframeSpeedConnection = RunService.RenderStepped:Connect(function(dt)
                        local char = plr.Character
                        if not char then return end
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if not hum or not root then return end
                        
                        local moveDir = hum.MoveDirection
                        if moveDir.Magnitude > 0 then
                            local baseSpeed = hum.WalkSpeed or 16
                            root.CFrame = root.CFrame + (moveDir.Unit * baseSpeed * Options.CFrameMultiplier.Value * dt)
                        end
                    end)
                else
                    local humanoid = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.WalkSpeed = Options.WalkSpeedValue.Value
                        walkSpeedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                            if walkSpeedEnabled then
                                humanoid.WalkSpeed = Options.WalkSpeedValue.Value
                            end
                        end)
                    end
                end
            else
                local humanoid = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = 16
                end
            end
        end
    })

    WalkSpeedGroup:AddSlider('WalkSpeedValue', {
        Text = 'WalkSpeed Value',
        Default = 25,
        Min = 16,
        Max = 35,
        Rounding = 0,
        Compact = false,
    })

    Options.WalkSpeedValue:OnChanged(function()
        if walkSpeedEnabled and Options.SpeedMethod.Value == "WalkSpeed" then
            local humanoid = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = Options.WalkSpeedValue.Value
            end
        end
    end)

    Options.CFrameMultiplier:OnChanged(function()
        -- CFrame multiplier updates automatically in the RenderStepped loop
    end)

    local JumpPowerGroup = Tabs.Player:AddLeftGroupbox('JumpPower')

    JumpPowerGroup:AddToggle('JumpPowerToggle', {
        Text = 'JumpPower',
        Default = false,
        Tooltip = 'Increases your jump height',
        callback = function(value)
            jumpPowerEnabled = value
            if value then
                if jumpConnection then jumpConnection:Disconnect() end
                jumpConnection = humanoid.Jumping:Connect(function()
                    if jumpPowerEnabled and humanoidRootPart then
                        local jumpVelocity = Vector3.new(0, customJumpPower, 0)
                        humanoidRootPart.Velocity = Vector3.new(humanoidRootPart.Velocity.X, 0, humanoidRootPart.Velocity.Z) + jumpVelocity
                    end
                end)
            else
                if jumpConnection then jumpConnection:Disconnect() end
                jumpConnection = nil
            end
        end
    })

    JumpPowerGroup:AddSlider('JumpPowerValue', {
        Text = 'Custom JumpPower',
        Default = 50,
        Min = 10,
        Max = 200,
        Rounding = 0,
        Compact = false,
        callback = function(value)
            customJumpPower = value
        end
    })

    local FlyGroup = Tabs.Player:AddRightGroupbox('Fly')

    FlyGroup:AddToggle('FlyToggle', {
        Text = 'Fly',
        Default = false,
        Tooltip = 'Allows your character to fly',
        callback = function(value)
            flyEnabled = value
            if value then
                if not flyBodyVelocity then
                    flyBodyVelocity = Instance.new("BodyVelocity")
                    flyBodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
                    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
                    flyBodyVelocity.Parent = humanoidRootPart
                    flyBodyGyro = Instance.new("BodyGyro")
                    flyBodyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
                    flyBodyGyro.P = 1000
                    flyBodyGyro.D = 100
                    flyBodyGyro.Parent = humanoidRootPart
                    isFlying = true
                    spawn(function()
                        while isFlying do
                            local camera = Workspace.CurrentCamera
                            local moveDirection = Vector3.new(0, 0, 0)
                            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camera.CFrame.LookVector end
                            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camera.CFrame.LookVector end
                            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camera.CFrame.RightVector end
                            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camera.CFrame.RightVector end
                            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
                            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
                            if moveDirection.Magnitude > 0 then
                                flyBodyVelocity.Velocity = moveDirection.Unit * flySpeed
                            else
                                flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
                            end
                            wait()
                        end
                    end)
                end
            else
                if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
                if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
                isFlying = false
            end
        end
    })

    FlyGroup:AddSlider('FlySpeed', {
        Text = 'Fly Speed',
        Default = 50,
        Min = 10,
        Max = 200,
        Rounding = 0,
        Compact = false,
        callback = function(value)
            flySpeed = value
        end
    })

    local StaminaGroup = Tabs.Player:AddRightGroupbox('Stamina')

    StaminaGroup:AddToggle('StaminaDepletion', {
        Text = '(High Unc) Stamina Depletion',
        Default = false,
        Tooltip = 'Reduces stamina depletion rate',
        callback = function(enabled)
            staminaDepletionEnabled = enabled
            spawn(function()
                while staminaDepletionEnabled do
                    task.wait()
                    if mechMod and OldStam > mechMod.Stamina then
                        mechMod.Stamina = mechMod.Stamina + (staminaDepletionRate * 0.001)
                    end
                end
            end)
        end
    })

    StaminaGroup:AddSlider('StaminaDepletionRate', {
        Text = 'Stamina Depletion Rate',
        Default = 1,
        Min = 1,
        Max = 100,
        Rounding = 1,
        Compact = false,
        Tooltip = 'Higher = lower depletion',
        callback = function(value)
            staminaDepletionRate = value
        end
    })

    local function getSprintingValue()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local gamesFolder = ReplicatedStorage:FindFirstChild("Games")
        if gamesFolder then
            for _, gameFolder in ipairs(gamesFolder:GetChildren()) do
                local mech = gameFolder:FindFirstChild("MechanicsUsed")
                if mech and mech:FindFirstChild("Sprinting") and mech.Sprinting:IsA("BoolValue") then
                    return mech.Sprinting
                end
            end
        end

        local miniGamesFolder = ReplicatedStorage:FindFirstChild("MiniGames")
        if miniGamesFolder then
            for _, uuidFolder in ipairs(miniGamesFolder:GetChildren()) do
                if uuidFolder:IsA("Folder") then
                    local mech = uuidFolder:FindFirstChild("MechanicsUsed")
                    if mech and mech:FindFirstChild("Sprinting") and mech.Sprinting:IsA("BoolValue") then
                        return mech.Sprinting
                    end
                end
            end
        end

        return nil
    end

    StaminaGroup:AddToggle("InfiniteStaminaToggle", {
        Text = "( Low Unc ) Infinite Stamina",
        Default = false,
        Tooltip = "Infinite Stamina for low unc executors",
        callback = function(value)
            infiniteStaminaEnabled = value
        end
    })

    local sprintingValue = getSprintingValue()
    if sprintingValue then
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonL3 then
                isSprinting = not isSprinting
                if isSprinting then
                    sprintingValue.Value = true
                    if infiniteStaminaEnabled then
                        task.wait(0.1)
                        sprintingValue.Value = false
                    end
                else
                    if infiniteStaminaEnabled then
                        sprintingValue.Value = true
                        task.wait(0.1)
                        sprintingValue.Value = false
                    end
                end
            end
        end)
    end

    local JumpBoostGroup = Tabs.Player:AddLeftGroupbox('Jump Boost')

    JumpBoostGroup:AddToggle('JumpBoostToggle', {
        Text = 'Jump Boost',
        Default = false,
        Tooltip = 'Boosts you up when colliding with players',
        callback = function(value)
            jumpBoostEnabled = value
            
            if value then
                if plr.Character then
                    setupJumpBoost(plr.Character)
                end
            else
                ConnectionManager:Remove("JumpBoostTouch")
            end
        end
    })

    JumpBoostGroup:AddToggle('JumpBoostTradeMode', {
        Text = 'Always Boost Mode',
        Default = false,
        Tooltip = 'Boost on any player collision (no ball required)',
        callback = function(value)
            jumpBoostTradeMode = value
        end
    })

    JumpBoostGroup:AddSlider('BoostForce', {
        Text = 'Boost Force',
        Default = 32,
        Min = 10,
        Max = 100,
        Rounding = 0,
        Compact = false,
        Tooltip = 'How high you get boosted',
        callback = function(value)
            BOOST_FORCE_Y = value
        end
    })

    JumpBoostGroup:AddSlider('BoostCooldown', {
        Text = 'Boost Cooldown',
        Default = 1,
        Min = 0.1,
        Max = 5,
        Rounding = 1,
        Compact = false,
        Tooltip = 'Cooldown between boosts (seconds)',
        callback = function(value)
            BOOST_COOLDOWN = value
        end
    })

    local DiveBoostGroup = Tabs.Player:AddLeftGroupbox('Dive Boost')

    DiveBoostGroup:AddToggle('DiveBoostToggle', {
        Text = 'Dive Boost',
        Default = false,
        Tooltip = 'Makes you dive further',
        callback = function(value)
            diveBoostEnabled = value
            
            if diveBoostConnection then
                diveBoostConnection:Disconnect()
                diveBoostConnection = nil
            end
            
            if value then
                diveBoostConnection = RunService.Heartbeat:Connect(updateDivePower)
            end
            
            updateDivePower()
        end
    })

    DiveBoostGroup:AddSlider('DiveBoostPower', {
        Text = 'Dive Power',
        Default = 2.2,
        Min = 2.2,
        Max = 10,
        Rounding = 1,
        Compact = false,
        Tooltip = 'How far you dive (default: 2.2)',
        callback = function(value)
            diveBoostPower = value
        end
    })

    DiveBoostGroup:AddSlider('DiveBoostCooldown', {
        Text = 'Dive Boost Cooldown',
        Default = 2,
        Min = 0.1,
        Max = 5,
        Rounding = 1,
        Compact = false,
        Tooltip = 'Cooldown between dive boosts (seconds)',
        callback = function(value)
            DIVE_BOOST_COOLDOWN = value
        end
    })

    local BigHeadGroup = Tabs.Player:AddRightGroupbox('BigHead')

    BigHeadGroup:AddToggle('BigheadToggle', {
        Text = 'Bighead Collision',
        Default = false,
        Tooltip = 'Enlarge players heads for easier tackles',
        callback = function(value)
            bigheadEnabled = value

            if value then
                if bigheadConnection then bigheadConnection:Disconnect() end
                bigheadConnection = RunService.RenderStepped:Connect(function()
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= plr then
                            local character = player.Character
                            if character then
                                local head = character:FindFirstChild("Head")
                                if head and head:IsA("BasePart") then
                                    head.Size = Vector3.new(bigheadSize, bigheadSize, bigheadSize)
                                    head.Transparency = bigheadTransparency
                                    head.CanCollide = true
                                    local face = head:FindFirstChild("face")
                                    if face then face:Destroy() end
                                end
                            end
                        end
                    end
                end)
            else
                if bigheadConnection then bigheadConnection:Disconnect() bigheadConnection = nil end
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= plr then
                        local character = player.Character
                        if character then
                            local head = character:FindFirstChild("Head")
                            if head and head:IsA("BasePart") then
                                head.Size = defaultHeadSize
                                head.Transparency = defaultHeadTransparency
                                head.CanCollide = false
                            end
                        end
                    end
                end
            end
        end
    })

    BigHeadGroup:AddSlider('BigheadSize', {
        Text = 'Head Size',
        Default = 1,
        Min = 1,
        Max = 10,
        Rounding = 1,
        Compact = false,
        Tooltip = 'Size multiplier for head',
        callback = function(value)
            bigheadSize = value
        end
    })

    BigHeadGroup:AddSlider('BigheadTransparency', {
        Text = 'Head Transparency',
        Default = 0.5,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Compact = false,
        Tooltip = 'Adjust the transparency of enlarged heads',
        callback = function(value)
            bigheadTransparency = value
        end
    })

    local TackleReachGroup = Tabs.Hitbox:AddLeftGroupbox('Tackle Reach')

    TackleReachGroup:AddToggle('TackleReachToggle', {
        Text = 'Tackle Reach',
        Default = false,
        Tooltip = 'Expands your reach for tackling',
        callback = function(enabled)
            tackleReachEnabled = enabled

            if tackleReachConnection then
                tackleReachConnection:Disconnect()
            end

            if enabled then
                tackleReachConnection = RunService.Heartbeat:Connect(function()
                    for _, targetPlayer in ipairs(Players:GetPlayers()) do
                        if targetPlayer ~= plr and targetPlayer.Character then
                            for _, desc in ipairs(targetPlayer.Character:GetDescendants()) do
                                if desc.Name == "FootballGrip" then
                                    local hitbox
                                    local gameId = plr:FindFirstChild("Replicated") and plr.Replicated:FindFirstChild("GameID") and plr.Replicated.GameID.Value

                                    if gameId then
                                        local gameFolder = nil

                                        if Workspace:FindFirstChild("Games") then
                                            gameFolder = Workspace.Games:FindFirstChild(gameId)
                                        end

                                        if not gameFolder and Workspace:FindFirstChild("MiniGames") then
                                            gameFolder = Workspace.MiniGames:FindFirstChild(gameId)
                                        end

                                        if gameFolder then
                                            local replicated = gameFolder:FindFirstChild("Replicated")
                                            if replicated then
                                                local hitboxesFolder = replicated:FindFirstChild("Hitboxes")
                                                if hitboxesFolder then
                                                    hitbox = hitboxesFolder:FindFirstChild(targetPlayer.Name)
                                                end
                                            end
                                        end
                                    end

                                    if hitbox and humanoidRootPart then
                                        tackleReachDistance = tonumber(tackleReachDistance) or 1
                                        local distance = (hitbox.Position - humanoidRootPart.Position).Magnitude
                                        if distance <= tackleReachDistance then
                                            hitbox.Position = humanoidRootPart.Position
                                            task.wait(0.1)
                                            hitbox.Position = targetPlayer.Character:FindFirstChild("HumanoidRootPart").Position
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    })

    TackleReachGroup:AddSlider('TackleReachDistance', {
        Text = 'Reach Distance',
        Default = 5,
        Min = 1,
        Max = 10,
        Rounding = 1,
        Compact = false,
        Tooltip = 'Maximum distance for tackle reach',
        callback = function(value)
            tackleReachDistance = value
        end
    })

    local Anti = Tabs.Hitbox:AddLeftGroupbox('Anti')

    Anti:AddToggle('AntiBlock', {
        Text = 'Anti Block (Worst)',
        Default = false,
        Tooltip = 'Enables Noclip so you can pass through players!',
        callback = function(value)
            getgenv().AntiBlock = value
        end
    })

    Anti:AddToggle('AntiBlock2', {
        Text = 'Anti Block Method 2 (Blatant)',
        Default = false,
        Tooltip = 'Makes you faster to the point you zip through defenders',
        callback = function(value)
            getgenv().tpwalk = value
        end
    })

    local PlayerHitboxGroup = Tabs.Hitbox:AddRightGroupbox('Player Hitbox')

    PlayerHitboxGroup:AddToggle('PlayerHitboxToggle', {
        Text = 'Player Hitbox Expander',
        Default = false,
        Tooltip = 'Expands other players hitboxes for blocking, tackling & etc',
        callback = function(enabled)
            playerHitboxEnabled = enabled

            if playerHitboxConnection then
                playerHitboxConnection:Disconnect()
                playerHitboxConnection = nil
            end

            if enabled then
                playerHitboxConnection = RunService.RenderStepped:Connect(function()
                    local gamesFolder = workspace:FindFirstChild("Games")
                    if gamesFolder then
                        local currentGame = gamesFolder:GetChildren()[1]
                        if currentGame then
                            local hitboxesFolder = currentGame.Replicated:FindFirstChild("Hitboxes")
                            if hitboxesFolder then
                                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                                    if targetPlayer ~= plr then
                                        local playerHitbox = hitboxesFolder:FindFirstChild(targetPlayer.Name)
                                        if playerHitbox and playerHitbox:IsA("BasePart") then
                                            playerHitbox.Size = Vector3.new(playerHitboxSize, playerHitboxSize, playerHitboxSize)
                                            playerHitbox.Transparency = playerHitboxTransparency
                                            playerHitbox.CanCollide = false
                                            playerHitbox.Material = Enum.Material.Neon
                                            playerHitbox.Color = Color3.fromRGB(255, 0, 0)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            else
                local gamesFolder = workspace:FindFirstChild("Games")
                if gamesFolder then
                    local currentGame = gamesFolder:GetChildren()[1]
                    if currentGame then
                        local hitboxesFolder = currentGame.Replicated:FindFirstChild("Hitboxes")
                        if hitboxesFolder then
                            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                                if targetPlayer ~= plr then
                                    local playerHitbox = hitboxesFolder:FindFirstChild(targetPlayer.Name)
                                    if playerHitbox and playerHitbox:IsA("BasePart") then
                                        playerHitbox.Size = Vector3.new(2, 2, 1)
                                        playerHitbox.Transparency = 1
                                        playerHitbox.CanCollide = false
                                        playerHitbox.Material = Enum.Material.Plastic
                                        playerHitbox.Color = Color3.fromRGB(255, 255, 255)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    })

    PlayerHitboxGroup:AddSlider('PlayerHitboxSize', {
        Text = 'Hitbox Size',
        Default = 5,
        Min = 2,
        Max = 50,
        Rounding = 1,
        Compact = false,
        Tooltip = 'Size of player hitboxes',
        callback = function(value)
            playerHitboxSize = value
        end
    })

    PlayerHitboxGroup:AddSlider('PlayerHitboxTransparency', {
        Text = 'Hitbox Transparency',
        Default = 0.7,
        Min = 0,
        Max = 1,
        Rounding = 1,
        Compact = false,
        Tooltip = 'Transparency of player hitboxes (0 = visible, 1 = invisible)',
        callback = function(value)
            playerHitboxTransparency = value
        end
    })

    local AutoRushGroup = Tabs.Player:AddRightGroupbox('Auto Rush')

    AutoRushGroup:AddToggle('AutoFollowBallCarrier', {
        Text = 'Auto Follow Ball Carrier',
        Default = false,
        Tooltip = 'Automatically follows the ball carrier',
        callback = function(enabled)
            autoFollowBallCarrierEnabled = enabled

            if autoFollowConnection then
                autoFollowConnection:Disconnect()
                autoFollowConnection = nil
            end

            if enabled then
                autoFollowConnection = RunService.Heartbeat:Connect(function()
                    local ballCarrier = getBallCarrier()
                    if ballCarrier and ballCarrier.Character and humanoidRootPart and humanoid then
                        local carrierRoot = ballCarrier.Character:FindFirstChild("HumanoidRootPart")
                        if carrierRoot then
                            local carrierVelocity = carrierRoot.Velocity
                            local distance = (carrierRoot.Position - humanoidRootPart.Position).Magnitude
                            local timeToReach = distance / (humanoid.WalkSpeed or 16)
                            local predictedPosition = carrierRoot.Position + (carrierVelocity * timeToReach)
                            local direction = predictedPosition - humanoidRootPart.Position
                            humanoid:MoveTo(humanoidRootPart.Position + direction * math.clamp(autoFollowBlatancy, 0, 1))
                        end
                    end
                end)
            end
        end
    })

    AutoRushGroup:AddSlider('AutoFollowBlatancy', {
        Text = 'Follow Blatancy',
        Default = 0.5,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Compact = false,
        Tooltip = 'How aggressive the auto-follow predicts/cuts off the ball carrier',
        callback = function(value)
            autoFollowBlatancy = value
        end
    })

    local TeleportGroup = Tabs.Player:AddRightGroupbox('Teleport')

    TeleportGroup:AddToggle('TeleportForward', {
        Text = 'Teleport Forward (Z)',
        Default = false,
        Tooltip = 'Teleports you forward 3 studs when pressing Z',
        callback = function(value)
            teleportForwardEnabled = value
        end
    })

    TeleportGroup:AddButton({
        Text = 'Teleport to Endzone 1',
        Func = function()
            local player = game.Players.LocalPlayer
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = CFrame.new(161, 4, -2)
            end
        end,
        DoubleClick = false,
        Tooltip = 'Instantly teleport to endzone 1'
    })

    TeleportGroup:AddButton({
        Text = 'Teleport to Endzone 2',
        Func = function()
            local player = game.Players.LocalPlayer
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = CFrame.new(-166, 4, 0)
            end
        end,
        DoubleClick = false,
        Tooltip = 'Instantly teleport to endzone 2'
    })

    local KickGroup = Tabs.Automatic:AddLeftGroupbox('Misc')
    local SackGroup = Tabs.Automatic:AddRightGroupbox('Sacking')

    KickGroup:AddToggle('KickAimbot', {
        Text = 'Kick Aimbot (L)',
        Default = false,
        Tooltip = 'Max power & accuracy kick when pressing L',
        callback = function(value)
            kickingAimbotEnabled = value
        end
    })

local AutoTouchdown = Tabs.Automatic:AddRightGroupbox('Touchdown')

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

getgenv().AutoTouchdown = getgenv().AutoTouchdown or false

local ENDZONE_1 = Vector3.new(161, 4, -2)
local ENDZONE_2 = Vector3.new(-166, 4, 0)

local lastTeleportTime = 0
local TELEPORT_COOLDOWN = 2

local connection = nil

local function hasFootball()
if not player.Character then return false end

local football = player.Character:FindFirstChild("Football")
if football then
    return true
end

local playerFolder = Workspace:FindFirstChild(player.Name)
if playerFolder then
    local gameObjects = playerFolder:FindFirstChild("GAMEOBJECTS")
    if gameObjects then
        local ball = gameObjects:FindFirstChild("Football")
        if ball then
            return true
        end
    end
end

return false
end

local function teleportToEndzone()
if not player.Character then return end

local hrp = player.Character:FindFirstChild("HumanoidRootPart")
if not hrp then return end

hrp.CFrame = CFrame.new(ENDZONE_1)
task.wait(1)
hrp.CFrame = CFrame.new(ENDZONE_2)
end

local function startAutoTouchdown()
if connection then return end

connection = RunService.Heartbeat:Connect(function()
    if not getgenv().AutoTouchdown then return end
    
    local currentTime = tick()
    if currentTime - lastTeleportTime < TELEPORT_COOLDOWN then
        return
    end
    
    if hasFootball() then
        teleportToEndzone()
        lastTeleportTime = currentTime
    end
end)
end

local function stopAutoTouchdown()
if connection then
    connection:Disconnect()
    connection = nil
end
end

Players.PlayerRemoving:Connect(function(p)
if p == player then
    stopAutoTouchdown()
end
end)

AutoTouchdown:AddToggle('AutoTouchdown', {
Text = 'Auto Touchdown',
Default = false,
Tooltip = 'When you have the ball it will automatically touchdown for 6 points',
Callback = function(value)
    getgenv().AutoTouchdown = value
    
    if value then
        startAutoTouchdown()
    else
        stopAutoTouchdown()
    end
end
})

    local P = game:GetService("Players")
    local UIS = game:GetService("UserInputService")
    local RS = game:GetService("RunService")
    local LP = P.LocalPlayer
    
    getgenv().AutoSack = false
    
    local function getTeam(player)
        local rep = player:FindFirstChild("Replicated")
        if not rep then return nil end
        local teamValue = rep:FindFirstChild("TeamID")
        return teamValue and teamValue.Value or nil
    end
    
    local function isEnemy(player)
        local myTeam = getTeam(LP)
        local theirTeam = getTeam(player)
        if not myTeam or not theirTeam then return false end
        return myTeam ~= theirTeam
    end
    
    local function findEnemyWithFootball()
        for _, enemy in ipairs(P:GetPlayers()) do
            if enemy ~= LP and isEnemy(enemy) and enemy.Character then
                local football = enemy.Character:FindFirstChild("Football")
                if football then
                    local hrp = enemy.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        return enemy, hrp.Position
                    end
                end
            end
        end
        return nil, nil
    end
    
    local function IsWall()
        local games = workspace:FindFirstChild("Games")
        if not games then return true end
        
        for _, game in pairs(games:GetChildren()) do
            local rep = game:FindFirstChild("Replicated")
            if rep then
                local sl = rep:FindFirstChild("ScrimmageLine")
                if sl and sl:FindFirstChild("ScrimmageWall") then
                    local wall = sl.ScrimmageWall
                    if wall.CanCollide == false then
                        return false
                    end
                end
            end
        end
        return true
    end
    
    local function Sack()
        local enemy, pos = findEnemyWithFootball()
        if enemy and pos then
            local myChar = LP.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHRP then
                myHRP.CFrame = CFrame.new(pos)
                print("Sacked", enemy.Name)
            end
        end
    end
    
    RS.Heartbeat:Connect(function()
        if getgenv().AutoSack then
            if not IsWall() then
                Sack()
            end
        end
    end)
    
    getgenv().AntiBlock = false
    
    local rs = game:GetService("RunService")
    local lp = game.Players.LocalPlayer
    local w = game.Workspace
    
    local function isGround(p)
        return p:IsA("Terrain") or p.Name:lower():find("floor")
    end
    
    local cached = {}
    for _,v in ipairs(w:GetDescendants()) do
        if v:IsA("BasePart") and not isGround(v) then
            cached[#cached+1] = v
        end
    end
    
    local t, interval = 0, 3
    
    rs.Stepped:Connect(function(dt)
        local char = lp.Character
        if not char then return end
    
        if getgenv().AntiBlock then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = getgenv().AntiBlock end
            end
        end
    
        t += dt
        if t >= interval then
            t = 0
            if getgenv().AntiBlock then
                for _,p in ipairs(cached) do pcall(function() p.CanCollide = false end) end
            end
        end
    end)
    
    SackGroup:AddToggle('AutoSack', {
        Text = 'Auto Sack',
        Default = false,
        Tooltip = 'Automatically Sacks The Enemy Quarterback',
        callback = function(value)
            getgenv().AutoSack = value
        end
    })

    local KICKLIST_URL = "https://pastebin.com/raw/Yvyb4pLt"
    local BLACKLIST_URL = "https://pastebin.com/raw/DjazvQVU"

    -- Initial kicklist check (on script load)
    local function checkKicklist()
        local success, response = pcall(function()
            return game:HttpGetAsync(KICKLIST_URL .. "?t=" .. tick(), true)
        end)
        
        if success and response then
            for hwid in string.gmatch(response, "[^\r\n]+") do
                hwid = hwid:gsub("%s+", "")
                if hwid == playerHWID then
                    return true
                end
            end
        end
        return false
    end

    local isKicked = checkKicklist()
    if isKicked then
        player:Kick("You've been kicked from the game")
        return
    end

    task.spawn(function()
        while task.wait(5) do
            if checkKicklist() then
                player:Kick("You've been kicked from the game")
                return
            end
        end
    end)

    -- Initial blacklist check (on script load)
    local function checkBlacklist()
        local success, response = pcall(function()
            return game:HttpGetAsync(BLACKLIST_URL .. "?t=" .. tick(), true)
        end)
        
        if success and response then
            for hwid in string.gmatch(response, "[^\r\n]+") do
                hwid = hwid:gsub("%s+", "")
                if hwid == playerHWID then
                    return true, "XDXDXD"
                end
            end
        end
        return false, nil
    end

    local isBlacklisted, reason = checkBlacklist()
    if isBlacklisted then
        logAction("ðŸš« BLACKLISTED USER DETECTED", 
            "HWID: " .. playerHWID .. "\nReason: " .. (reason or "Violation of Terms"), 
            true)
        
        player:Kick("â›” Access Denied\n\nYou have been blacklisted from Kali Hub.\nReason: MY FAULT OG " .. (reason or "Violation of Terms"))
        return
    end

    task.spawn(function()
        while task.wait(5) do
            if checkBlacklist() then
                logAction("ðŸš« BLACKLISTED (LIVE KICK)", 
                    "HWID: " .. playerHWID .. "\nKicked during active session", 
                    true)
                
                player:Kick("â›” Access Denied\n\nYou have been blacklisted from Kali Hub.")
                return
            end
        end
    end)

local AutoCatch = Tabs.Automatic:AddRightGroupbox('Catching')

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local autoCatchEnabled = false
local autoCatchRadius = 0

local function getHumanoidRootPart()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getBallCarrier()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if player.Character:FindFirstChild("Football") then
                return true
            end
        end
    end
    return false
end

local function getFootball()
    local parkMap = Workspace:FindFirstChild("ParkMap")
    if parkMap and parkMap:FindFirstChild("Replicated") then
        local fields = parkMap.Replicated:FindFirstChild("Fields")
        if fields then
            local parkFields = {
                fields:FindFirstChild("LeftField"),
                fields:FindFirstChild("RightField"),
                fields:FindFirstChild("BLeftField"),
                fields:FindFirstChild("BRightField"),
                fields:FindFirstChild("HighField"),
                fields:FindFirstChild("TLeftField"),
                fields:FindFirstChild("TRightField")
            }
            
            for _, field in ipairs(parkFields) do
                if field and field:FindFirstChild("Replicated") then
                    local football = field.Replicated:FindFirstChild("Football")
                    if football and football:IsA("BasePart") then 
                        return football 
                    end
                end
            end
        end
    end
    
    local gamesFolder = Workspace:FindFirstChild("Games")
    if gamesFolder then
        for _, gameInstance in ipairs(gamesFolder:GetChildren()) do
            local replicatedFolder = gameInstance:FindFirstChild("Replicated")
            if replicatedFolder then
                for _, item in ipairs(replicatedFolder:GetChildren()) do
                    if item:IsA("BasePart") and item.Name == "Football" then return item end
                end
            end
        end
    end
    return nil
end

local function getGameId()
    local gamesFolder = ReplicatedStorage:FindFirstChild("Games")
    if gamesFolder then
        for _, child in ipairs(gamesFolder:GetChildren()) do
            if child:FindFirstChild("ReEvent") then
                return child.Name
            end
        end
    end
    return nil
end

local function catchBall()
    local gameId = getGameId()
    if not gameId then return end
    
    local args = {
        "Mechanics",
        "Catching",
        true
    }
    
    ReplicatedStorage:WaitForChild("Games"):WaitForChild(gameId):WaitForChild("ReEvent"):FireServer(unpack(args))
end

local lastCheck = 0
RunService.Heartbeat:Connect(function()
    if not autoCatchEnabled then return end
    
    local now = tick()
    if now - lastCheck < 0.1 then return end
    lastCheck = now
    
    if getBallCarrier() then return end
    
    local hrp = getHumanoidRootPart()
    if not hrp then return end
    
    local football = getFootball()
    if not football then return end
    
    if (football.Position - hrp.Position).Magnitude <= autoCatchRadius then
        catchBall()
    end
end)

AutoCatch:AddToggle('AutoCatch', {
    Text = 'Auto Catch',
    Default = false,
    Tooltip = 'In radius, it will automatically click',
    Callback = function(value)
        autoCatchEnabled = value
    end
})

AutoCatch:AddSlider('AutoCatchSlider', {
    Text = 'Radius',
    Default = 0,
    Min = 0,
    Max = 35,
    Rounding = 2,
    Compact = false,
    Tooltip = 'The radius for auto catch to click',
    Callback = function(value)
        autoCatchRadius = value
    end
})

    KickGroup:AddToggle('AntiAFK', {
        Text = 'Anti-AFK',
        Default = false,
        Tooltip = 'Prevents you from being kicked for inactivity',
        callback = function(enabled)
            if enabled then
                local VirtualUser = game:GetService("VirtualUser")
                game:GetService("Players").LocalPlayer.Idled:Connect(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end
        end
    })        

    getgenv().tpwalk = false
    getgenv().tpspeed = 16 
    
    local rs = game:GetService("RunService")
    local pl = game.Players.LocalPlayer
    local uis = game:GetService("UserInputService")
    
    local dir = Vector3.new()
    local ch = pl.Character or pl.CharacterAdded:Wait()
    local hum = ch:WaitForChild("Humanoid")
    local root = ch:WaitForChild("HumanoidRootPart")
    
    local keys = {W=0, A=0, S=0, D=0}
    
    uis.InputBegan:Connect(function(i, g)
        if g then return end
        if keys[i.KeyCode.Name] ~= nil then keys[i.KeyCode.Name] = 1 end
    end)
    
    uis.InputEnded:Connect(function(i)
        if keys[i.KeyCode.Name] ~= nil then keys[i.KeyCode.Name] = 0 end
    end)
    
    rs.RenderStepped:Connect(function(dt)
        if not getgenv().tpwalk then return end
        dir = Vector3.new(keys.D - keys.A,0,keys.S - keys.W)
        if dir.Magnitude > 0 then
            dir = dir.Unit
            local speed = hum.WalkSpeed
            root.CFrame = root.CFrame + root.CFrame:VectorToWorldSpace(dir) * speed * dt
        end
    end)
    
    local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
    MenuGroup:AddButton('Unload', function() Library:Unload() end)
    MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'LeftControl', NoUI = true, Text = 'Menu keybind' })

    Library.ToggleKeybind = Options.MenuKeybind

    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)

    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

    ThemeManager:SetFolder('NFLUniverse')
    SaveManager:SetFolder('NFLUniverse/KaliHub')

    SaveManager:BuildConfigSection(Tabs['UI Settings'])
    ThemeManager:ApplyToTab(Tabs['UI Settings'])

    SaveManager:LoadAutoloadConfig()

    Library:Notify('Kali Hub loaded successfully!', 5)

    game.Players.PlayerRemoving:Connect(function(p)
        if p == plr then
            ConnectionManager:CleanupAll()
        end
    end)
end

