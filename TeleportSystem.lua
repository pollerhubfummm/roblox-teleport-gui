--[[
    ╔════════════════════════════════════════════════════════════════════╗
    ║         ROBLOX TELEPORT SYSTEM - ULTIMATE EDITION                 ║
    ║   Mit erweiterter GUI, Position-Speicherung, Shortcuts & mehr     ║
    ║                     ALLES IN EINEM SCRIPT!                        ║
    ╚════════════════════════════════════════════════════════════════════╝
]]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ===== KONFIGURATION =====
local CONFIG = {
    GUI_TOGGLE_KEY = Enum.KeyCode.P,
    MAX_SAVED_POSITIONS = 15,
    TELEPORT_SPEED = 100,
    GUI_TRANSPARENCY = 0.1,
    GUI_CORNER_RADIUS = 8,
    PRIMARY_COLOR = Color3.fromRGB(0, 120, 255),
    SECONDARY_COLOR = Color3.fromRGB(255, 85, 0),
    DANGER_COLOR = Color3.fromRGB(200, 50, 50),
    SUCCESS_COLOR = Color3.fromRGB(50, 150, 50),
    BACKGROUND_COLOR = Color3.fromRGB(20, 20, 30),
    TEXT_COLOR = Color3.fromRGB(255, 255, 255),
    ACCENT_COLOR = Color3.fromRGB(100, 200, 255),
}

-- ===== SPEICHERSYSTEM =====
local SaveManager = {}
SaveManager.Data = {}

function SaveManager:Load()
    local success, data = pcall(function()
        if player:FindFirstChild("TeleportData") then
            return HttpService:JSONDecode(player.TeleportData.Value)
        end
        return {}
    end)
    self.Data = success and data or {}
    return self.Data
end

function SaveManager:Save()
    local success = pcall(function()
        local jsonData = HttpService:JSONEncode(self.Data)
        local obj = player:FindFirstChild("TeleportData")
        if not obj then
            obj = Instance.new("StringValue")
            obj.Name = "TeleportData"
            obj.Parent = player
        end
        obj.Value = jsonData
    end)
    return success
end

function SaveManager:AddPosition(name, position, icon)
    if #self.Data >= CONFIG.MAX_SAVED_POSITIONS then
        table.remove(self.Data, 1)
    end
    
    table.insert(self.Data, {
        name = name or "Position_" .. os.time(),
        x = math.round(position.X * 100) / 100,
        y = math.round(position.Y * 100) / 100,
        z = math.round(position.Z * 100) / 100,
        icon = icon or "📍",
        timestamp = os.time(),
        visitCount = 0
    })
    
    self:Save()
    return true
end

function SaveManager:UpdatePosition(index, name, position)
    if self.Data[index] then
        self.Data[index].name = name
        self.Data[index].x = position.X
        self.Data[index].y = position.Y
        self.Data[index].z = position.Z
        self:Save()
        return true
    end
    return false
end

function SaveManager:DeletePosition(index)
    table.remove(self.Data, index)
    self:Save()
end

function SaveManager:IncrementVisitCount(index)
    if self.Data[index] then
        self.Data[index].visitCount = (self.Data[index].visitCount or 0) + 1
        self:Save()
    end
end

function SaveManager:ClearAll()
    self.Data = {}
    self:Save()
end

function SaveManager:ExportData()
    return HttpService:JSONEncode(self.Data)
end

function SaveManager:ImportData(jsonString)
    local success, data = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    if success and data then
        self.Data = data
        self:Save()
        return true
    end
    return false
end

-- ===== TELEPORT UTILITY =====
local TeleportUtil = {}

function TeleportUtil:TeleportTo(position, smooth)
    local char = player.Character
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    if smooth then
        local startPos = hrp.Position
        local distance = (position - startPos).Magnitude
        local duration = distance / CONFIG.TELEPORT_SPEED
        
        for i = 0, 1, 1 / (duration * 60) do
            if char:FindFirstChild("HumanoidRootPart") then
                hrp.CFrame = CFrame.new(startPos:Lerp(position, i) + Vector3.new(0, 3, 0))
            end
            RunService.RenderStepped:Wait()
        end
    end
    
    hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    return true
end

function TeleportUtil:GetCurrentPosition()
    return humanoidRootPart.Position
end

function TeleportUtil:GetFormattedPosition(pos)
    return string.format("X: %.1f | Y: %.1f | Z: %.1f", pos.X, pos.Y, pos.Z)
end

function TeleportUtil:CopyToClipboard(text)
    if setclipboard then
        setclipboard(text)
        return true
    end
    return false
end

-- ===== STATISTIK SYSTEM =====
local StatsManager = {}
StatsManager.TotalTeleports = 0
StatsManager.SessionStart = os.time()

function StatsManager:GetStats()
    return {
        totalTeleports = self.TotalTeleports,
        sessionDuration = os.time() - self.SessionStart,
        savedPositions = #SaveManager.Data
    }
end

function StatsManager:IncrementTeleports()
    self.TotalTeleports = self.TotalTeleports + 1
end

-- ===== GUI MANAGER =====
local UIManager = {}
UIManager.MainGui = nil
UIManager.IsOpen = false
UIManager.CurrentNotifications = 0

function UIManager:CreateMainGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleportGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- ===== MAIN PANEL =====
    local mainPanel = Instance.new("Frame")
    mainPanel.Name = "MainPanel"
    mainPanel.Size = UDim2.new(0, 450, 0, 700)
    mainPanel.Position = UDim2.new(0.5, -225, 0.5, -350)
    mainPanel.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    mainPanel.BackgroundTransparency = CONFIG.GUI_TRANSPARENCY
    mainPanel.BorderSizePixel = 0
    mainPanel.Parent = screenGui
    mainPanel.Draggable = true
    mainPanel.Active = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, CONFIG.GUI_CORNER_RADIUS)
    corner.Parent = mainPanel
    
    local shadow = Instance.new("UIStroke")
    shadow.Color = CONFIG.PRIMARY_COLOR
    shadow.Thickness = 3
    shadow.Transparency = 0.3
    shadow.Parent = mainPanel
    
    -- ===== HEADER =====
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = CONFIG.PRIMARY_COLOR
    header.BorderSizePixel = 0
    header.Parent = mainPanel
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, CONFIG.GUI_CORNER_RADIUS)
    headerCorner.Parent = header
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -80, 0.5, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🚀 TELEPORT SYSTEM"
    titleLabel.TextColor3 = CONFIG.TEXT_COLOR
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header
    
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(1, -80, 0.5, 0)
    subtitleLabel.Position = UDim2.new(0, 15, 0.5, 0)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "⌨️ Drücke 'P' zum Umschalten"
    subtitleLabel.TextColor3 = CONFIG.ACCENT_COLOR
    subtitleLabel.TextSize = 11
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.Parent = header
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 40, 1, 0)
    closeBtn.Position = UDim2.new(1, -40, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = CONFIG.TEXT_COLOR
    closeBtn.TextSize = 22
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    closeBtn.MouseButton1Click:Connect(function()
        self:ToggleGui()
    end)
    
    closeBtn.MouseEnter:Connect(function()
        closeBtn.TextColor3 = CONFIG.SECONDARY_COLOR
    end)
    
    closeBtn.MouseLeave:Connect(function()
        closeBtn.TextColor3 = CONFIG.TEXT_COLOR
    end)
    
    -- ===== CONTENT AREA =====
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, 0, 1, -60)
    contentFrame.Position = UDim2.new(0, 0, 0, 60)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainPanel
    
    -- ===== TAB SYSTEM =====
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, 0, 0, 40)
    tabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = contentFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = tabContainer
    
    local tabs = {
        {name = "Positionen", id = "positions", icon = "📍"},
        {name = "Tools", id = "tools", icon = "⚙️"},
        {name = "Stats", id = "stats", icon = "📊"}
    }
    
    local tabButtons = {}
    local tabPanels = {}
    
    for _, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tab.id
        tabBtn.Size = UDim2.new(1, 0, 1, 0)
        tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        tabBtn.BackgroundTransparency = 0.5
        tabBtn.Text = tab.icon .. " " .. tab.name
        tabBtn.TextColor3 = CONFIG.TEXT_COLOR
        tabBtn.TextSize = 13
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabContainer
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = tabBtn
        
        -- Tab Panel
        local panel = Instance.new("Frame")
        panel.Name = tab.id .. "Panel"
        panel.Size = UDim2.new(1, 0, 1, -40)
        panel.Position = UDim2.new(0, 0, 0, 40)
        panel.BackgroundTransparency = 1
        panel.Visible = (tab.id == "positions")
        panel.Parent = contentFrame
        
        tabButtons[tab.id] = tabBtn
        tabPanels[tab.id] = panel
        
        tabBtn.MouseButton1Click:Connect(function()
            for _, p in pairs(tabPanels) do
                p.Visible = false
            end
            for _, b in pairs(tabButtons) do
                b.BackgroundTransparency = 0.5
            end
            panel.Visible = true
            tabBtn.BackgroundTransparency = 0.1
        end)
        
        tabBtn.MouseEnter:Connect(function()
            if panel.Visible then
                tabBtn.BackgroundTransparency = 0.05
            else
                tabBtn.BackgroundTransparency = 0.3
            end
        end)
        
        tabBtn.MouseLeave:Connect(function()
            if not panel.Visible then
                tabBtn.BackgroundTransparency = 0.5
            end
        end)
    end
    
    -- Set initial tab active
    tabButtons["positions"].BackgroundTransparency = 0.1
    
    -- ===== POSITIONS TAB =====
    local posPanel = tabPanels["positions"]
    
    local buttonArea = Instance.new("Frame")
    buttonArea.Name = "ButtonArea"
    buttonArea.Size = UDim2.new(1, 0, 0, 110)
    buttonArea.BackgroundTransparency = 1
    buttonArea.Parent = posPanel
    
    -- Position anzeigen
    local posBtn = self:CreateButton("📍 POSITION", buttonArea, UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -7, 0, 28))
    posBtn.MouseButton1Click:Connect(function()
        local pos = TeleportUtil:GetCurrentPosition()
        self:ShowNotification("Position: " .. TeleportUtil:GetFormattedPosition(pos))
    end)
    
    -- Speichern
    local saveBtn = self:CreateButton("💾 SPEICHERN", buttonArea, UDim2.new(0.5, 7, 0, 10), UDim2.new(0.5, -7, 0, 28))
    saveBtn.MouseButton1Click:Connect(function()
        self:ShowInputDialog("Name der Position:", function(name)
            if name and name ~= "" then
                SaveManager:AddPosition(name, TeleportUtil:GetCurrentPosition(), "📍")
                self:RefreshPositionList()
                self:ShowNotification("✅ Position '" .. name .. "' gespeichert!")
            end
        end)
    end)
    
    -- Teleportieren (alle)
    local tpBtn = self:CreateButton("⚡ TELEPORTIEREN", buttonArea, UDim2.new(0, 10, 0, 45), UDim2.new(1, -20, 0, 28))
    tpBtn.BackgroundColor3 = CONFIG.SECONDARY_COLOR
    tpBtn.MouseButton1Click:Connect(function()
        self:ShowNotification("⏳ Wähle eine Position...")
    end)
    
    -- Letzter Ort
    local lastPosBtn = self:CreateButton("🔙 LETZTE POSITION", buttonArea, UDim2.new(0, 10, 0, 78), UDim2.new(0.5, -7, 0, 28))
    if #SaveManager.Data > 0 then
        lastPosBtn.MouseButton1Click:Connect(function()
            local lastPos = SaveManager.Data[#SaveManager.Data]
            TeleportUtil:TeleportTo(Vector3.new(lastPos.x, lastPos.y, lastPos.z))
            StatsManager:IncrementTeleports()
            SaveManager:IncrementVisitCount(#SaveManager.Data)
            self:ShowNotification("✅ Zu " .. lastPos.name .. " teleportiert!")
        end)
    end
    
    -- Alles löschen
    local deleteAllBtn = self:CreateButton("🗑️ ALLE LÖSCHEN", buttonArea, UDim2.new(0.5, 7, 0, 78), UDim2.new(0.5, -7, 0, 28))
    deleteAllBtn.BackgroundColor3 = CONFIG.DANGER_COLOR
    deleteAllBtn.MouseButton1Click:Connect(function()
        self:ShowConfirmDialog("Alle Positionen wirklich löschen?", function(confirmed)
            if confirmed then
                SaveManager:ClearAll()
                self:RefreshPositionList()
                self:ShowNotification("🗑️ Alle Positionen gelöscht!")
            end
        end)
    end)
    
    -- ===== POSITIONS LIST =====
    local listLabel = Instance.new("TextLabel")
    listLabel.Name = "ListLabel"
    listLabel.Size = UDim2.new(1, 0, 0, 25)
    listLabel.Position = UDim2.new(0, 10, 0, 115)
    listLabel.BackgroundTransparency = 1
    listLabel.Text = "📋 Gespeicherte Positionen (" .. #SaveManager.Data .. ")"
    listLabel.TextColor3 = CONFIG.PRIMARY_COLOR
    listLabel.TextSize = 13
    listLabel.Font = Enum.Font.GothamBold
    listLabel.TextXAlignment = Enum.TextXAlignment.Left
    listLabel.Parent = posPanel
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "PositionList"
    scrollFrame.Size = UDim2.new(1, -20, 1, -145)
    scrollFrame.Position = UDim2.new(0, 10, 0, 140)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    scrollFrame.BackgroundTransparency = 0.3
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = posPanel
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = scrollFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.Parent = scrollFrame
    
    self.MainGui = screenGui
    self.ListFrame = scrollFrame
    self.ListLayout = listLayout
    self.ListLabel = listLabel
    self.PositionPanel = posPanel
    
    -- ===== TOOLS TAB =====
    local toolsPanel = tabPanels["tools"]
    
    local toolsScroll = Instance.new("ScrollingFrame")
    toolsScroll.Name = "ToolsScroll"
    toolsScroll.Size = UDim2.new(1, -20, 1, 0)
    toolsScroll.Position = UDim2.new(0, 10, 0, 0)
    toolsScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    toolsScroll.BackgroundTransparency = 0.3
    toolsScroll.BorderSizePixel = 0
    toolsScroll.ScrollBarThickness = 6
    toolsScroll.Parent = toolsPanel
    
    local toolsCorner = Instance.new("UICorner")
    toolsCorner.CornerRadius = UDim.new(0, 6)
    toolsCorner.Parent = toolsScroll
    
    local toolsLayout = Instance.new("UIListLayout")
    toolsLayout.Padding = UDim.new(0, 8)
    toolsLayout.Parent = toolsScroll
    
    -- Copy Koordinaten
    local copyBtn = self:CreateToolButton("📋 Koordinaten kopieren", toolsScroll, UDim2.new(1, -20, 0, 45))
    copyBtn.MouseButton1Click:Connect(function()
        local pos = TeleportUtil:GetCurrentPosition()
        local text = pos.X .. ", " .. pos.Y .. ", " .. pos.Z
        if TeleportUtil:CopyToClipboard(text) then
            self:ShowNotification("✅ Koordinaten kopiert!")
        else
            self:ShowNotification("❌ Kopieren nicht unterstützt")
        end
    end)
    
    -- GPS Anzeige
    local gpsBtn = self:CreateToolButton("🧭 GPS Koordinaten anzeigen", toolsScroll, UDim2.new(1, -20, 0, 45))
    gpsBtn.MouseButton1Click:Connect(function()
        local pos = TeleportUtil:GetCurrentPosition()
        self:ShowLargeDialog("📍 GPS KOORDINATEN", TeleportUtil:GetFormattedPosition(pos))
    end)
    
    -- Position Code
    local codeBtn = self:CreateToolButton("💾 Position als Code", toolsScroll, UDim2.new(1, -20, 0, 45))
    codeBtn.MouseButton1Click:Connect(function()
        local pos = TeleportUtil:GetCurrentPosition()
        local code = string.format("Vector3.new(%d, %d, %d)", pos.X, pos.Y, pos.Z)
        if TeleportUtil:CopyToClipboard(code) then
            self:ShowNotification("✅ Code kopiert!")
        end
    end)
    
    -- Export
    local exportBtn = self:CreateToolButton("📤 EXPORT (JSON)", toolsScroll, UDim2.new(1, -20, 0, 45))
    exportBtn.MouseButton1Click:Connect(function()
        local data = SaveManager:ExportData()
        if TeleportUtil:CopyToClipboard(data) then
            self:ShowNotification("✅ Daten exportiert!")
        end
    end)
    
    -- Import
    local importBtn = self:CreateToolButton("📥 IMPORT (JSON)", toolsScroll, UDim2.new(1, -20, 0, 45))
    importBtn.MouseButton1Click:Connect(function()
        self:ShowInputDialog("JSON Code eingeben:", function(code)
            if SaveManager:ImportData(code) then
                self:RefreshPositionList()
                self:ShowNotification("✅ Daten importiert!")
            else
                self:ShowNotification("❌ Import fehlgeschlagen!")
            end
        end)
    end)
    
    toolsScroll.CanvasSize = UDim2.new(0, 0, 0, toolsLayout.AbsoluteContentSize.Y + 20)
    
    -- ===== STATS TAB =====
    local statsPanel = tabPanels["stats"]
    
    local statsScroll = Instance.new("ScrollingFrame")
    statsScroll.Name = "StatsScroll"
    statsScroll.Size = UDim2.new(1, -20, 1, 0)
    statsScroll.Position = UDim2.new(0, 10, 0, 0)
    statsScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    statsScroll.BackgroundTransparency = 0.3
    statsScroll.BorderSizePixel = 0
    statsScroll.ScrollBarThickness = 6
    statsScroll.Parent = statsPanel
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 6)
    statsCorner.Parent = statsScroll
    
    -- Statistik Boxen
    local statBox1 = self:CreateStatBox("⚡ Teleports", "0", statsScroll, CONFIG.PRIMARY_COLOR)
    local statBox2 = self:CreateStatBox("💾 Positionen", tostring(#SaveManager.Data), statsScroll, CONFIG.SECONDARY_COLOR)
    local statBox3 = self:CreateStatBox("⏱️ Session", "0s", statsScroll, CONFIG.ACCENT_COLOR)
    
    -- Update Stats regelmäßig
    RunService.Heartbeat:Connect(function()
        local stats = StatsManager:GetStats()
        statBox1:FindFirstChild("Value").Text = tostring(stats.totalTeleports)
        statBox2:FindFirstChild("Value").Text = tostring(stats.savedPositions)
        statBox3:FindFirstChild("Value").Text = tostring(stats.sessionDuration) .. "s"
    end)
    
    return screenGui
end

function UIManager:CreateButton(text, parent, position, size)
    local button = Instance.new("TextButton")
    button.Name = text
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = CONFIG.PRIMARY_COLOR
    button.BackgroundTransparency = 0.1
    button.Text = text
    button.TextColor3 = CONFIG.TEXT_COLOR
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.Parent = parent
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button
    
    button.MouseEnter:Connect(function()
        button.BackgroundTransparency = 0.05
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundTransparency = 0.1
    end)
    
    return button
end

function UIManager:CreateToolButton(text, parent, size)
    local btn = Instance.new("TextButton")
    btn.Name = text
    btn.Size = size
    btn.BackgroundColor3 = CONFIG.PRIMARY_COLOR
    btn.BackgroundTransparency = 0.15
    btn.Text = text
    btn.TextColor3 = CONFIG.TEXT_COLOR
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundTransparency = 0.05
    end)
    
    btn.MouseLeave:Connect(function()
        btn.BackgroundTransparency = 0.15
    end)
    
    return btn
end

function UIManager:CreateStatBox(label, value, parent, color)
    local box = Instance.new("Frame")
    box.Name = label
    box.Size = UDim2.new(1, -20, 0, 80)
    box.BackgroundColor3 = color
    box.BackgroundTransparency = 0.2
    box.BorderSizePixel = 0
    box.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = box
    
    local labelText = Instance.new("TextLabel")
    labelText.Name = "Label"
    labelText.Size = UDim2.new(1, 0, 0.4, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = color
    labelText.TextSize = 12
    labelText.Font = Enum.Font.GothamBold
    labelText.Parent = box
    
    local valueText = Instance.new("TextLabel")
    valueText.Name = "Value"
    valueText.Size = UDim2.new(1, 0, 0.6, 0)
    valueText.Position = UDim2.new(0, 0, 0.4, 0)
    valueText.BackgroundTransparency = 1
    valueText.Text = value
    valueText.TextColor3 = CONFIG.TEXT_COLOR
    valueText.TextSize = 24
    valueText.Font = Enum.Font.GothamBold
    valueText.Parent = box
    
    return box
end

function UIManager:RefreshPositionList()
    for _, child in ipairs(self.ListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    SaveManager:Load()
    self.ListLabel.Text = "📋 Gespeicherte Positionen (" .. #SaveManager.Data .. ")"
    
    for index, posData in ipairs(SaveManager.Data) do
        local posFrame = Instance.new("Frame")
        posFrame.Name = "PositionFrame_" .. index
        posFrame.Size = UDim2.new(1, -10, 0, 70)
        posFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        posFrame.BorderSizePixel = 0
        posFrame.Parent = self.ListFrame
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 5)
        frameCorner.Parent = posFrame
        
        -- Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(0.65, 0, 0.4, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = posData.icon .. " " .. posData.name
        nameLabel.TextColor3 = CONFIG.PRIMARY_COLOR
        nameLabel.TextSize = 12
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = posFrame
        
        -- Visits
        local visitLabel = Instance.new("TextLabel")
        visitLabel.Name = "VisitLabel"
        visitLabel.Size = UDim2.new(0.35, 0, 0.4, 0)
        visitLabel.Position = UDim2.new(0.65, 0, 0, 5)
        visitLabel.BackgroundTransparency = 1
        visitLabel.Text = "🔄 " .. (posData.visitCount or 0)
        visitLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
        visitLabel.TextSize = 10
        visitLabel.Font = Enum.Font.Gotham
        visitLabel.TextXAlignment = Enum.TextXAlignment.Right
        visitLabel.Parent = posFrame
        
        -- Koordinaten
        local coordsLabel = Instance.new("TextLabel")
        coordsLabel.Name = "CoordsLabel"
        coordsLabel.Size = UDim2.new(1, -20, 0.4, 0)
        coordsLabel.Position = UDim2.new(0, 10, 0.4, 2)
        coordsLabel.BackgroundTransparency = 1
        coordsLabel.Text = TeleportUtil:GetFormattedPosition(Vector3.new(posData.x, posData.y, posData.z))
        coordsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        coordsLabel.TextSize = 10
        coordsLabel.Font = Enum.Font.Gotham
        coordsLabel.TextXAlignment = Enum.TextXAlignment.Left
        coordsLabel.Parent = posFrame
        
        -- Teleport Button
        local tpBtn = Instance.new("TextButton")
        tpBtn.Name = "TeleportBtn"
        tpBtn.Size = UDim2.new(0, 48, 0, 60)
        tpBtn.Position = UDim2.new(1, -60, 0.05, 0)
        tpBtn.BackgroundColor3 = CONFIG.SECONDARY_COLOR
        tpBtn.BackgroundTransparency = 0.15
        tpBtn.Text = "⚡"
        tpBtn.TextColor3 = CONFIG.TEXT_COLOR
        tpBtn.TextSize = 20
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.BorderSizePixel = 0
        tpBtn.Parent = posFrame
        
        local tpCorner = Instance.new("UICorner")
        tpCorner.CornerRadius = UDim.new(0, 4)
        tpCorner.Parent = tpBtn
        
        tpBtn.MouseButton1Click:Connect(function()
            TeleportUtil:TeleportTo(Vector3.new(posData.x, posData.y, posData.z))
            StatsManager:IncrementTeleports()
            SaveManager:IncrementVisitCount(index)
            self:ShowNotification("✅ Zu " .. posData.name .. " teleportiert!")
            self:RefreshPositionList()
        end)
        
        tpBtn.MouseEnter:Connect(function()
            tpBtn.BackgroundTransparency = 0.05
        end)
        
        tpBtn.MouseLeave:Connect(function()
            tpBtn.BackgroundTransparency = 0.15
        end)
        
        -- Delete Button
        local delBtn = Instance.new("TextButton")
        delBtn.Name = "DeleteBtn"
        delBtn.Size = UDim2.new(0, 48, 0, 60)
        delBtn.Position = UDim2.new(1, -110, 0.05, 0)
        delBtn.BackgroundColor3 = CONFIG.DANGER_COLOR
        delBtn.BackgroundTransparency = 0.2
        delBtn.Text = "🗑️"
        delBtn.TextColor3 = CONFIG.TEXT_COLOR
        delBtn.TextSize = 16
        delBtn.Font = Enum.Font.GothamBold
        delBtn.BorderSizePixel = 0
        delBtn.Parent = posFrame
        
        local delCorner = Instance.new("UICorner")
        delCorner.CornerRadius = UDim.new(0, 4)
        delCorner.Parent = delBtn
        
        delBtn.MouseButton1Click:Connect(function()
            SaveManager:DeletePosition(index)
            self:RefreshPositionList()
            self:ShowNotification("🗑️ Position gelöscht!")
        end)
        
        delBtn.MouseEnter:Connect(function()
            delBtn.BackgroundTransparency = 0.1
        end)
        
        delBtn.MouseLeave:Connect(function()
            delBtn.BackgroundTransparency = 0.2
        end)
    end
    
    self.ListFrame.CanvasSize = UDim2.new(0, 0, 0, self.ListLayout.AbsoluteContentSize.Y + 15)
end

function UIManager:ShowNotification(message)
    self.CurrentNotifications = self.CurrentNotifications + 1
    local index = self.CurrentNotifications
    
    local notif = Instance.new("TextLabel")
    notif.Name = "Notification"
    notif.Size = UDim2.new(0, 320, 0, 55)
    notif.Position = UDim2.new(0.5, -160, 0, 10 + (index - 1) * 65)
    notif.BackgroundColor3 = CONFIG.PRIMARY_COLOR
    notif.BackgroundTransparency = 0.2
    notif.Text = message
    notif.TextColor3 = CONFIG.TEXT_COLOR
    notif.TextSize = 13
    notif.Font = Enum.Font.Gotham
    notif.TextWrapped = true
    notif.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.PRIMARY_COLOR
    stroke.Thickness = 1
    stroke.Transparency = 0.3
    stroke.Parent = notif
    
    Debris:AddItem(notif, 3)
    
    game:GetService("Debris"):AddItem(notif, 3)
    self.CurrentNotifications = self.CurrentNotifications - 1
end

function UIManager:ShowInputDialog(prompt, callback)
    local dialog = Instance.new("ScreenGui")
    dialog.Name = "InputDialog"
    dialog.ResetOnSpawn = false
    dialog.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    dialog.Parent = playerGui
    
    local bgFrame = Instance.new("Frame")
    bgFrame.Name = "Background"
    bgFrame.Size = UDim2.new(1, 0, 1, 0)
    bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    bgFrame.BackgroundTransparency = 0.5
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = dialog
    
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 380, 0, 160)
    panel.Position = UDim2.new(0.5, -190, 0.5, -80)
    panel.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    panel.BorderSizePixel = 0
    panel.Parent = bgFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = panel
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.PRIMARY_COLOR
    stroke.Thickness = 2
    stroke.Parent = panel
    
    local promptLabel = Instance.new("TextLabel")
    promptLabel.Size = UDim2.new(1, -20, 0, 30)
    promptLabel.Position = UDim2.new(0, 10, 0, 10)
    promptLabel.BackgroundTransparency = 1
    promptLabel.Text = prompt
    promptLabel.TextColor3 = CONFIG.TEXT_COLOR
    promptLabel.TextSize = 14
    promptLabel.Font = Enum.Font.Gotham
    promptLabel.TextWrapped = true
    promptLabel.Parent = panel
    
    local textbox = Instance.new("TextBox")
    textbox.Name = "InputBox"
    textbox.Size = UDim2.new(1, -20, 0, 38)
    textbox.Position = UDim2.new(0, 10, 0, 45)
    textbox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    textbox.BackgroundTransparency = 0.2
    textbox.Text = ""
    textbox.TextColor3 = CONFIG.TEXT_COLOR
    textbox.TextSize = 14
    textbox.Font = Enum.Font.Gotham
    textbox.PlaceholderText = "Text eingeben..."
    textbox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    textbox.Parent = panel
    
    local textCorner = Instance.new("UICorner")
    textCorner.CornerRadius = UDim.new(0, 5)
    textCorner.Parent = textbox
    
    local okBtn = Instance.new("TextButton")
    okBtn.Name = "OKButton"
    okBtn.Size = UDim2.new(0, 110, 0, 32)
    okBtn.Position = UDim2.new(0, 10, 1, -42)
    okBtn.BackgroundColor3 = CONFIG.SUCCESS_COLOR
    okBtn.BackgroundTransparency = 0.15
    okBtn.Text = "✓ OK"
    okBtn.TextColor3 = CONFIG.TEXT_COLOR
    okBtn.TextSize = 12
    okBtn.Font = Enum.Font.GothamBold
    okBtn.BorderSizePixel = 0
    okBtn.Parent = panel
    
    local okCorner = Instance.new("UICorner")
    okCorner.CornerRadius = UDim.new(0, 5)
    okCorner.Parent = okBtn
    
    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Name = "CancelButton"
    cancelBtn.Size = UDim2.new(0, 110, 0, 32)
    cancelBtn.Position = UDim2.new(1, -120, 1, -42)
    cancelBtn.BackgroundColor3 = CONFIG.DANGER_COLOR
    cancelBtn.BackgroundTransparency = 0.15
    cancelBtn.Text = "✕ CANCEL"
    cancelBtn.TextColor3 = CONFIG.TEXT_COLOR
    cancelBtn.TextSize = 12
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Parent = panel
    
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 5)
    cancelCorner.Parent = cancelBtn
    
    local function closeDialog()
        dialog:Destroy()
    end
    
    okBtn.MouseButton1Click:Connect(function()
        if textbox.Text ~= "" then
            callback(textbox.Text)
            closeDialog()
        end
    end)
    
    cancelBtn.MouseButton1Click:Connect(function()
        closeDialog()
    end)
    
    textbox:CaptureFocus()
    textbox.FocusLost:Connect(function(enterPressed)
        if enterPressed and textbox.Text ~= "" then
            callback(textbox.Text)
            closeDialog()
        end
    end)
end

function UIManager:ShowConfirmDialog(message, callback)
    local dialog = Instance.new("ScreenGui")
    dialog.Name = "ConfirmDialog"
    dialog.ResetOnSpawn = false
    dialog.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    dialog.Parent = playerGui
    
    local bgFrame = Instance.new("Frame")
    bgFrame.Name = "Background"
    bgFrame.Size = UDim2.new(1, 0, 1, 0)
    bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    bgFrame.BackgroundTransparency = 0.5
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = dialog
    
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 340, 0, 140)
    panel.Position = UDim2.new(0.5, -170, 0.5, -70)
    panel.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    panel.BorderSizePixel = 0
    panel.Parent = bgFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = panel
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.PRIMARY_COLOR
    stroke.Thickness = 2
    stroke.Parent = panel
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 0, 50)
    messageLabel.Position = UDim2.new(0, 10, 0, 10)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = CONFIG.TEXT_COLOR
    messageLabel.TextSize = 14
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextWrapped = true
    messageLabel.Parent = panel
    
    local yesBtn = Instance.new("TextButton")
    yesBtn.Name = "YesButton"
    yesBtn.Size = UDim2.new(0, 100, 0, 32)
    yesBtn.Position = UDim2.new(0, 10, 1, -42)
    yesBtn.BackgroundColor3 = CONFIG.SUCCESS_COLOR
    yesBtn.BackgroundTransparency = 0.15
    yesBtn.Text = "✓ JA"
    yesBtn.TextColor3 = CONFIG.TEXT_COLOR
    yesBtn.TextSize = 12
    yesBtn.Font = Enum.Font.GothamBold
    yesBtn.BorderSizePixel = 0
    yesBtn.Parent = panel
    
    local yesCorner = Instance.new("UICorner")
    yesCorner.CornerRadius = UDim.new(0, 5)
    yesCorner.Parent = yesBtn
    
    local noBtn = Instance.new("TextButton")
    noBtn.Name = "NoButton"
    noBtn.Size = UDim2.new(0, 100, 0, 32)
    noBtn.Position = UDim2.new(1, -110, 1, -42)
    noBtn.BackgroundColor3 = CONFIG.DANGER_COLOR
    noBtn.BackgroundTransparency = 0.15
    noBtn.Text = "✕ NEIN"
    noBtn.TextColor3 = CONFIG.TEXT_COLOR
    noBtn.TextSize = 12
    noBtn.Font = Enum.Font.GothamBold
    noBtn.BorderSizePixel = 0
    noBtn.Parent = panel
    
    local noCorner = Instance.new("UICorner")
    noCorner.CornerRadius = UDim.new(0, 5)
    noCorner.Parent = noBtn
    
    yesBtn.MouseButton1Click:Connect(function()
        callback(true)
        dialog:Destroy()
    end)
    
    noBtn.MouseButton1Click:Connect(function()
        callback(false)
        dialog:Destroy()
    end)
end

function UIManager:ShowLargeDialog(title, content)
    local dialog = Instance.new("ScreenGui")
    dialog.Name = "LargeDialog"
    dialog.ResetOnSpawn = false
    dialog.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    dialog.Parent = playerGui
    
    local bgFrame = Instance.new("Frame")
    bgFrame.Name = "Background"
    bgFrame.Size = UDim2.new(1, 0, 1, 0)
    bgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    bgFrame.BackgroundTransparency = 0.5
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = dialog
    
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 400, 0, 250)
    panel.Position = UDim2.new(0.5, -200, 0.5, -125)
    panel.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    panel.BorderSizePixel = 0
    panel.Parent = bgFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = panel
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = CONFIG.PRIMARY_COLOR
    stroke.Thickness = 2
    stroke.Parent = panel
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.BackgroundColor3 = CONFIG.PRIMARY_COLOR
    titleLabel.BackgroundTransparency = 0.2
    titleLabel.Text = title
    titleLabel.TextColor3 = CONFIG.TEXT_COLOR
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.BorderSizePixel = 0
    titleLabel.Parent = panel
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleLabel
    
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Name = "Content"
    contentLabel.Size = UDim2.new(1, -20, 1, -90)
    contentLabel.Position = UDim2.new(0, 10, 0, 45)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Text = content
    contentLabel.TextColor3 = CONFIG.TEXT_COLOR
    contentLabel.TextSize = 14
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextWrapped = true
    contentLabel.TextXAlignment = Enum.TextXAlignment.Center
    contentLabel.TextYAlignment = Enum.TextYAlignment.Center
    contentLabel.Parent = panel
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0.6, 0, 0, 35)
    closeBtn.Position = UDim2.new(0.2, 0, 1, -40)
    closeBtn.BackgroundColor3 = CONFIG.PRIMARY_COLOR
    closeBtn.BackgroundTransparency = 0.15
    closeBtn.Text = "✓ OK"
    closeBtn.TextColor3 = CONFIG.TEXT_COLOR
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = panel
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
    
    bgFrame.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
end

function UIManager:ToggleGui()
    self.IsOpen = not self.IsOpen
    self.MainGui.Enabled = self.IsOpen
end

-- ===== INITIALIZATION =====
local function Initialize()
    print("=" .. string.rep("=", 60) .. "=")
    print("🚀 ROBLOX TELEPORT SYSTEM - ULTIMATE EDITION")
    print("=" .. string.rep("=", 60) .. "=")
    print("")
    print("✅ System wird initialisiert...")
    
    SaveManager:Load()
    UIManager:CreateMainGui()
    UIManager.MainGui.Enabled = false
    UIManager:RefreshPositionList()
    
    -- Keyboard Shortcuts
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == CONFIG.GUI_TOGGLE_KEY then
            UIManager:ToggleGui()
        end
    end)
    
    -- Character Respawn Handler
    player.CharacterAdded:Connect(function(newCharacter)
        character = newCharacter
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    end)
    
    print("")
    print("🎉 SYSTEM ERFOLGREICH GELADEN!")
    print("📌 Drücke 'P' um das GUI zu öffnen/schließen!")
    print("💾 Du kannst bis zu " .. CONFIG.MAX_SAVED_POSITIONS .. " Positionen speichern!")
    print("")
    print("=" .. string.rep("=", 60) .. "=")
    
    UIManager:ShowNotification("🚀 Teleport System geladen! Drücke 'P'")
end

Initialize()
