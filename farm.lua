-- ==========================================================
-- MM2 UNDERGROUND AUTO FARM (MULTI-ACCOUNT EDITION v9.0)
-- Оптимизировано под 9+ аккаунтов. Мгновенный уход под карту при спавне.
-- ==========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-------------------------------------------------------------
-- НАСТРОЙКИ
-------------------------------------------------------------
local SETTINGS = {
    RUN_SPEED = 40,         -- Скорость движения под полом (40-45 идеально)
    COLLECT_DELAY = 0.2,    -- Задержка после сбора конфеты (в секундах)
    MAX_CANDIES = 60,       -- Лимит конфет за раунд
    UNDER_OFFSET = 1.4,     -- Дистанция под конфетой при сборе
    WAIT_DEPTH = 16.0,      -- Глубина сидения под картой во время 10с таймера
    TARGET_MODE = "Nearest",-- "Nearest" или "Random"
    ANTI_AFK = true         -- Защита от AFK-кика
}
-------------------------------------------------------------

-- Система Anti-AFK
task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        if SETTINGS.ANTI_AFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end)
end)

-- UI Скрипта
local function createUI()
    pcall(function()
        if CoreGui:FindFirstChild("MM2AutoFarmUI") then
            CoreGui.MM2AutoFarmUI:Destroy()
        end

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MM2AutoFarmUI"
        screenGui.Parent = CoreGui
        screenGui.ResetOnSpawn = false

        local mainFrame = Instance.new("Frame")
        mainFrame.Size = UDim2.new(0, 220, 0, 220)
        mainFrame.Position = UDim2.new(1, -240, 0, 20)
        mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
        mainFrame.Parent = screenGui

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = mainFrame

        local topBar = Instance.new("Frame")
        topBar.Size = UDim2.new(1, 0, 0, 35)
        topBar.BackgroundTransparency = 1
        topBar.Parent = mainFrame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -40, 1, 0)
        title.Position = UDim2.new(0, 10, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "MM2 Underground v9.0"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 13
        title.Font = Enum.Font.SourceSansBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = topBar

        local minimizeBtn = Instance.new("TextButton")
        minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
        minimizeBtn.Position = UDim2.new(1, -32, 0, 5)
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        minimizeBtn.Text = "-"
        minimizeBtn.TextSize = 16
        minimizeBtn.Font = Enum.Font.SourceSansBold
        minimizeBtn.Parent = topBar

        local minCorner = Instance.new("UICorner")
        minCorner.CornerRadius = UDim.new(0, 4)
        minCorner.Parent = minimizeBtn

        local contentContainer = Instance.new("Frame")
        contentContainer.Size = UDim2.new(1, 0, 1, -35)
        contentContainer.Position = UDim2.new(0, 0, 0, 35)
        contentContainer.BackgroundTransparency = 1
        contentContainer.Parent = mainFrame

        local dragging, dragStart, startPos
        topBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = mainFrame.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        local isMinimized = false
        minimizeBtn.MouseButton1Click:Connect(function()
            isMinimized = not isMinimized
            contentContainer.Visible = not isMinimized
            mainFrame.Size = isMinimized and UDim2.new(0, 220, 0, 35) or UDim2.new(0, 220, 0, 220)
            minimizeBtn.Text = isMinimized and "+" or "-"
        end)

        local function createSettingRow(name, defaultVal, yPos, callback)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0, 120, 0, 30)
            label.Position = UDim2.new(0, 10, 0, yPos)
            label.BackgroundTransparency = 1
            label.Text = name
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            label.TextSize = 13
            label.Font = Enum.Font.SourceSans
            label.Parent = contentContainer

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0, 60, 0, 26)
            box.Position = UDim2.new(0, 140, 0, yPos + 2)
            box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            box.TextColor3 = Color3.fromRGB(255, 255, 255)
            box.Text = tostring(defaultVal)
            box.TextSize = 13
            box.Font = Enum.Font.SourceSansBold
            box.Parent = contentContainer

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 4)
            boxCorner.Parent = box

            box.FocusLost:Connect(function()
                local num = tonumber(box.Text)
                if num then callback(num) else box.Text = tostring(defaultVal) end
            end)
        end

        createSettingRow("Задержка (с):", SETTINGS.COLLECT_DELAY, 10, function(val) SETTINGS.COLLECT_DELAY = val end)
        createSettingRow("Лимит конфет:", SETTINGS.MAX_CANDIES, 45, function(val) SETTINGS.MAX_CANDIES = val end)

        local modeBtn = Instance.new("TextButton")
        modeBtn.Size = UDim2.new(0, 190, 0, 26)
        modeBtn.Position = UDim2.new(0, 15, 0, 82)
        modeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
        modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        modeBtn.Text = "Режим: " .. (SETTINGS.TARGET_MODE == "Nearest" and "Ближайшая" or "Случайная")
        modeBtn.TextSize = 12
        modeBtn.Font = Enum.Font.SourceSansBold
        modeBtn.Parent = contentContainer

        local modeBtnCorner = Instance.new("UICorner")
        modeBtnCorner.CornerRadius = UDim.new(0, 4)
        modeBtnCorner.Parent = modeBtn

        modeBtn.MouseButton1Click:Connect(function()
            if SETTINGS.TARGET_MODE == "Nearest" then
                SETTINGS.TARGET_MODE = "Random"
                modeBtn.Text = "Режим: Случайная"
            else
                SETTINGS.TARGET_MODE = "Nearest"
                modeBtn.Text = "Режим: Ближайшая"
            end
        end)
    end)
end

task.spawn(createUI)

-- Полный фриз физики и анимаций
local function freezeCompletely(character)
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.AutoRotate = false
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end
    
    local animate = character:FindFirstChild("Animate")
    if animate then animate:Destroy() end
end

-- Поиск конфет на карте
local function getValidCandies()
    local targets = {}
    -- Проверяем сначала карты MM2, если они есть в Workspace
    local container = Workspace:FindFirstChild("Normal") or Workspace
    
    for _, obj in ipairs(container:GetDescendants()) do
        if obj and obj.Parent then
            local name = obj.Name:lower()
            if name:find("candy") or name:find("drop") or name:find("token") or (name:find("coin") and not name:find("container")) then
                local part = obj:IsA("BasePart") and obj or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
                if part and part.Transparency < 1 then
                    table.insert(targets, part)
                end
            end
        end
    end
    return targets
end

-- Выбор следующей цели
local function getTargetCandy(candies, hrpPos, collectedPositions)
    local uncollected = {}

    for _, candy in ipairs(candies) do
        if candy and candy.Parent then
            local alreadyCollected = false
            for _, pos in ipairs(collectedPositions) do
                if (Vector2.new(candy.Position.X, candy.Position.Z) - Vector2.new(pos.X, pos.Z)).Magnitude < 1.5 then
                    alreadyCollected = true
                    break
                end
            end
            if not alreadyCollected then
                table.insert(uncollected, candy)
            end
        end
    end

    if #uncollected == 0 then return nil end

    if SETTINGS.TARGET_MODE == "Random" then
        return uncollected[math.random(1, #uncollected)]
    else
        local nearestCandy = nil
        local shortestDistance = math.huge
        for _, candy in ipairs(uncollected) do
            local dist = (candy.Position - hrpPos).Magnitude
            if dist < shortestDistance then
                shortestDistance = dist
                nearestCandy = candy
            end
        end
        return nearestCandy
    end
end

-- Плавное подземное перемещение
local function fastMoveUnderFloor(hrp, humanoid, targetPos)
    if not hrp or not humanoid then return end
    
    hrp.Anchored = false
    humanoid.PlatformStand = false
    
    local startPos = hrp.Position
    local distance = (startPos - targetPos).Magnitude
    local duration = math.clamp(distance / SETTINGS.RUN_SPEED, 0.03, 0.8)
    
    local startTime = tick()
    while tick() - startTime < duration do
        if not hrp or not hrp.Parent then break end
        local alpha = (tick() - startTime) / duration
        hrp.CFrame = CFrame.new(startPos:Lerp(targetPos, alpha))
        RunService.Heartbeat:Wait()
    end
    
    if hrp and hrp.Parent then
        hrp.CFrame = CFrame.new(targetPos)
        hrp.Velocity = Vector3.new(0, 0, 0)
    end
end

-- Основная логика раунда
local function handleCharacterLogic(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not humanoid or not hrp then return end

    freezeCompletely(character)

    local initialLobbyPos = hrp.Position

    -- 1. ДЕТЕКТОР ТЕЛЕПОРТАЦИИ НА КАРТУ (Мгновенный уход под землю)
    while character and character.Parent and humanoid.Health > 0 do
        -- Как только дистанция от точки спавна в Лобби становится больше 25 блоков = Игрок Телепортировался на карту!
        local currentPos = hrp.Position
        if (currentPos - initialLobbyPos).Magnitude > 25 then
            -- МГНОВЕННО прячем персонажа под карту до окончания 10-секундного таймера
            hrp.CFrame = CFrame.new(currentPos.X, currentPos.Y - SETTINGS.WAIT_DEPTH, currentPos.Z)
            hrp.Anchored = true
            freezeCompletely(character)
            break
        end
        task.wait(0.05) -- Быстрый опрос состояния каждые 50мс
    end

    if not character.Parent or humanoid.Health <= 0 then return end

    -- 2. ОЖИДАНИЕ СПАВНА КОНФЕТ (Пока идет 10с таймер)
    -- Мы уже висим ПОД картой безопасным образом
    while character and character.Parent and humanoid.Health > 0 do
        local candies = getValidCandies()
        if #candies > 0 then
            break -- Спавн конфет начался, переходим к автофарму!
        end
        task.wait(0.3)
    end

    if not character.Parent or humanoid.Health <= 0 then return end

    -- 3. ЦИКЛ АВТОФАРМА
    local collectedPositions = {}
    local totalCollectedCount = 0
    local lastHistoryClear = tick()
    local lastCandyCountCheck = #getValidCandies()

    while character and character.Parent and humanoid.Health > 0 do
        local currentCandies = getValidCandies()

        -- Сброс счетчика, если карты обновились
        if #currentCandies > lastCandyCountCheck + 5 then
            totalCollectedCount = 0
            collectedPositions = {}
        end
        lastCandyCountCheck = #currentCandies

        if totalCollectedCount >= SETTINGS.MAX_CANDIES then
            task.wait(2)
            totalCollectedCount = 0
            continue
        end

        if tick() - lastHistoryClear > 8 then
            collectedPositions = {}
            lastHistoryClear = tick()
        end
        
        if #currentCandies == 0 then
            task.wait(0.3)
            continue
        end

        local targetCandy = getTargetCandy(currentCandies, hrp.Position, collectedPositions)

        if not targetCandy then
            collectedPositions = {}
            task.wait(0.2)
            continue
        end

        table.insert(collectedPositions, targetCandy.Position)
        if #collectedPositions > 15 then
            table.remove(collectedPositions, 1)
        end

        local targetPos = Vector3.new(
            targetCandy.Position.X, 
            targetCandy.Position.Y - SETTINGS.UNDER_OFFSET, 
            targetCandy.Position.Z
        )
        
        fastMoveUnderFloor(hrp, humanoid, targetPos)
        
        freezeCompletely(character)
        totalCollectedCount = totalCollectedCount + 1
        
        -- Рандомизация микро-задержки для стабильности фарма с 9 аккаунтов
        task.wait(SETTINGS.COLLECT_DELAY + (math.random(1, 5) / 100))
    end
end

-- Отслеживание спавна
LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.2)
    handleCharacterLogic(newChar)
end)

if LocalPlayer.Character then
    task.spawn(function()
        handleCharacterLogic(LocalPlayer.Character)
    end)
end
