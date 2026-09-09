--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║    ROBLOX TELEPORT SYSTEM - Professional Edition            ║
    ║    Mit erweiterter GUI, Position-Speicherung & Features      ║
    ╚══════════════════════════════════════════════════════════════╝
]]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ===== CONFIGURATION =====
local CONFIG = {
    GUI_TOGGLE_KEY = Enum.KeyCode.P,
    MAX_SAVED_POSITIONS = 10,
    TELEPORT_SPEED = 100,
    GUI_TRANSPARENCY = 0.1,
    GUI_CORNER_RADIUS = 8,
    PRIMARY_COLOR = Color3.fromRGB(0, 120, 255),
    SECONDARY_COLOR = Color3.fromRGB(255, 85, 0),
    BACKGROUND_COLOR = Color3.fromRGB(20, 20, 30),
    TEXT_COLOR = Color3.fromRGB(255, 255, 255),
}

-- ===== SPEICHERSYSTEM =====
local SaveManager = {}
SaveManager.SaveKey = "TeleportPositions_" .. player.UserId
SaveManager.Data = {}

function SaveManager:Load()
    local success, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(
            player:FindFirstChild("TeleportData") and player.TeleportData.Value or "{}"
        )
    end)
    self.Data = success and data or {}
    return self.Data
end

function SaveManager:Save()
    local success = pcall(function()
        local jsonData = game:GetService("HttpService"):JSONEncode(self.Data)
        if not player:FindFirstChild("TeleportData") then
            local obj = Instance.new("StringValue")
            obj.Name = "TeleportData"
            obj.Parent = player
        end
        player.TeleportData.Value = jsonData
    end)
    return success
end

function SaveManager:AddPosition(name, position)
    if #self.Data >= CONFIG.MAX_SAVED_POSITIONS then
        table.remove(self.Data, 1)
    end
    
    table.insert(self.Data, {
        name = name or "Position_" .. os.time(),
        x = math.round(position.X * 100) / 100,
        y = math.round(position.Y * 100) / 100,
        z = math.round(position.Z * 100) / 100,
        timestamp = os.time()
    })
    
    self:Save()
end

function SaveManager:DeletePosition(index)
    table.remove(self.Data, index)
    self:Save()
end

function SaveManager:ClearAll()
    self.Data = {}
    self:Save()
end

-- ===== TELEPORT UTILITY =====
local TeleportUtil = {}

function TeleportUtil:TeleportTo(position)
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    end
end

function TeleportUtil:GetCurrentPosition()
    return humanoidRootPart.Position
end

-- ===== GUI BUILDER =====
local UIManager = {}
UIManager.MainGui = nil
UIManager.IsOpen = false

function UIManager:CreateMainGui()
    -- Hauptcontainer
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleportGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Main Panel
    local mainPanel = Instance.new("Frame")
    mainPanel.Name = "MainPanel"
    mainPanel.Size = UDim2.new(0, 400, 0, 600)
    mainPanel.Position = UDim2.new(0.5, -200, 0.5, -300)
    mainPanel.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    mainPanel.BackgroundTransparency = CONFIG.GUI_TRANSPARENCY
    mainPanel.BorderSizePixel = 0
    mainPanel.Parent = screenGui
    
    -- Eckenradius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, CONFIG.GUI_CORNER_RADIUS)
    corner.Parent = mainPanel
    
    -- Shadow Effekt
    local shadow = Instance.new("UIStroke")
    shadow.Color = CONFIG.PRIMARY_COLOR
    shadow.Thickness = 2
    shadow.Transparency = 0.5
    shadow.Parent = mainPanel
    
    -- HEADER
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = CONFIG.PRIMARY_COLOR
    header.BorderSizePixel = 0
    header.Parent = mainPanel
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, CONFIG.GUI_CORNER_RADIUS)
    headerCorner.Parent = header
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🚀 TELEPORT SYSTEM"
    titleLabel.TextColor3 = CONFIG.TEXT_COLOR
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 50, 1, 0)
    closeBtn.Position = UDim2.new(1, -50, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = CONFIG.TEXT_COLOR
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    closeBtn.MouseButton1Click:Connect(function()
        self:ToggleGui()
    end)
    
    -- CONTENT AREA
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, 0, 1, -50)
    contentFrame.Position = UDim2.new(0, 0, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainPanel
    
    -- BUTTON AREA
    local buttonArea = Instance.new("Frame")
    buttonArea.Name = "ButtonArea"
    buttonArea.Size = UDim2.new(1, 0, 0, 90)
    buttonArea.BackgroundTransparency = 1
    buttonArea.Parent = contentFrame
    
    -- Current Position Button
    local posBtn = self:CreateButton("📍 AKTUELLE POSITION", buttonArea, UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -5, 0, 30))
    posBtn.MouseButton1Click:Connect(function()
        local pos = TeleportUtil:GetCurrentPosition()
        self:ShowNotification(string.format("Position: X=%.2f, Y=%.2f, Z=%.2f", pos.X, pos.Y, pos.Z))
    end)
    
    -- Save Position Button
    local saveBtn = self:CreateButton("💾 SPEICHERN", buttonArea, UDim2.new(0.5, 5, 0, 10), UDim2.new(0.5, -5, 0, 30))
    saveBtn.MouseButton1Click:Connect(function()
        self:ShowInputDialog("Positionsname eingeben:", function(name)
            SaveManager:AddPosition(name, TeleportUtil:GetCurrentPosition())
            self:RefreshPositionList()
            self:ShowNotification("✅ Position gespeichert!")
        end)
    end)
    
    -- Teleport Button
    local tpBtn = self:CreateButton("⚡ TELEPORTIEREN", buttonArea, UDim2.new(0, 10, 0, 45), UDim2.new(1, -20, 0, 30))
    tpBtn.BackgroundColor3 = CONFIG.SECONDARY_COLOR
    tpBtn.MouseButton1Click:Connect(function()
        self:ShowNotification("⏳ Bitte Ziel wählen...")
    end)
    
    -- DELETE ALL Button
    local deleteAllBtn = self:CreateButton("🗑️ ALLE LÖSCHEN", buttonArea, UDim2.new(0, 10, 0, 80), UDim2.new(1, -20, 0, 25))
    deleteAllBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    deleteAllBtn.MouseButton1Click:Connect(function()
        if self:ShowConfirmDialog("Alle Positionen löschen?") then
            SaveManager:ClearAll()
            self:RefreshPositionList()
            self:ShowNotification("🗑️ Alle Positionen gelöscht!")
        end
    end)
    
    -- POSITION LIST AREA
    local listLabel = Instance.new("TextLabel")
    listLabel.Name = "ListLabel"
    listLabel.Size = UDim2.new(1, 0, 0, 25)
    listLabel.Position = UDim2.new(0, 10, 0, 105)
    listLabel.BackgroundTransparency = 1
    listLabel.Text = "📋 Gespeicherte Positionen:"
    listLabel.TextColor3 = CONFIG.PRIMARY_COLOR
    listLabel.TextSize = 14
    listLabel.Font = Enum.Font.GothamBold
    listLabel.TextXAlignment = Enum.TextXAlignment.Left
    listLabel.Parent = contentFrame
    
    -- ScrollingFrame für Positionen
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "PositionList"
    scrollFrame.Size = UDim2.new(1, -20, 1, -140)
    scrollFrame.Position = UDim2.new(0, 10, 0, 130)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    scrollFrame.BackgroundTransparency = 0.3
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = contentFrame
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = scrollFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = scrollFrame
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    self.MainGui = screenGui
    self.ListFrame = scrollFrame
    self.ListLayout = listLayout
    
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
    
    -- Hover Effekt
    button.MouseEnter:Connect(function()
        button.BackgroundTransparency = 0.05
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundTransparency = 0.1
    end)
    
    return button
end

function UIManager:RefreshPositionList()
    -- Alle alten Einträge löschen
    for _, child in ipairs(self.ListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    SaveManager:Load()
    
    for index, posData in ipairs(SaveManager.Data) do
        local posFrame = Instance.new("Frame")
        posFrame.Name = "PositionFrame_" .. index
        posFrame.Size = UDim2.new(1, -10, 0, 60)
        posFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        posFrame.BorderSizePixel = 0
        posFrame.Parent = self.ListFrame
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 5)
        frameCorner.Parent = posFrame
        
        -- Position Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = posData.name
        nameLabel.TextColor3 = CONFIG.PRIMARY_COLOR
        nameLabel.TextSize = 12
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = posFrame
        
        -- Koordinaten
        local coordsLabel = Instance.new("TextLabel")
        coordsLabel.Name = "CoordsLabel"
        coordsLabel.Size = UDim2.new(1, -20, 0.45, 0)
        coordsLabel.Position = UDim2.new(0, 10, 0.5, 2)
        coordsLabel.BackgroundTransparency = 1
        coordsLabel.Text = string.format("X: %.1f | Y: %.1f | Z: %.1f", posData.x, posData.y, posData.z)
        coordsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        coordsLabel.TextSize = 10
        coordsLabel.Font = Enum.Font.Gotham
        coordsLabel.TextXAlignment = Enum.TextXAlignment.Left
        coordsLabel.Parent = posFrame
        
        -- Teleport Button
        local tpBtn = Instance.new("TextButton")
        tpBtn.Name = "TeleportBtn"
        tpBtn.Size = UDim2.new(0, 50, 0, 50)
        tpBtn.Position = UDim2.new(1, -55, 0, 5)
        tpBtn.BackgroundColor3 = CONFIG.SECONDARY_COLOR
        tpBtn.BackgroundTransparency = 0.1
        tpBtn.Text = "TP"
        tpBtn.TextColor3 = CONFIG.TEXT_COLOR
        tpBtn.TextSize = 11
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.BorderSizePixel = 0
        tpBtn.Parent = posFrame
        
        local tpCorner = Instance.new("UICorner")
        tpCorner.CornerRadius = UDim.new(0, 4)
        tpCorner.Parent = tpBtn
        
        tpBtn.MouseButton1Click:Connect(function()
            TeleportUtil:TeleportTo(Vector3.new(posData.x, posData.y, posData.z))
            self:ShowNotification("✅ Teleportiert!")
        end)
        
        -- Delete Button
        local delBtn = Instance.new("TextButton")
        delBtn.Name = "DeleteBtn"
        delBtn.Size = UDim2.new(0, 50, 0, 50)
        delBtn.Position = UDim2.new(1, -55, 0, 5)
        delBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        delBtn.BackgroundTransparency = 0.1
        delBtn.Text = "❌"
        delBtn.TextColor3 = CONFIG.TEXT_COLOR
        delBtn.TextSize = 14
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
    end
    
    self.ListFrame.CanvasSize = UDim2.new(0, 0, 0, self.ListLayout.AbsoluteContentSize.Y + 10)
end

function UIManager:ShowNotification(message)
    local notif = Instance.new("TextLabel")
    notif.Name = "Notification"
    notif.Size = UDim2.new(0, 300, 0, 50)
    notif.Position = UDim2.new(0.5, -150, 0, 20)
    notif.BackgroundColor3 = CONFIG.PRIMARY_COLOR
    notif.BackgroundTransparency = 0.2
    notif.Text = message
    notif.TextColor3 = CONFIG.TEXT_COLOR
    notif.TextSize = 14
    notif.Font = Enum.Font.Gotham
    notif.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif
    
    game:GetService("Debris"):AddItem(notif, 2)
end

function UIManager:ShowInputDialog(prompt, callback)
    local dialog = Instance.new("ScreenGui")
    dialog.Name = "InputDialog"
    dialog.ResetOnSpawn = false
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
    panel.Size = UDim2.new(0, 350, 0, 150)
    panel.Position = UDim2.new(0.5, -175, 0.5, -75)
    panel.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    panel.BorderSizePixel = 0
    panel.Parent = bgFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = panel
    
    local promptLabel = Instance.new("TextLabel")
    promptLabel.Size = UDim2.new(1, -20, 0, 30)
    promptLabel.Position = UDim2.new(0, 10, 0, 10)
    promptLabel.BackgroundTransparency = 1
    promptLabel.Text = prompt
    promptLabel.TextColor3 = CONFIG.TEXT_COLOR
    promptLabel.TextSize = 14
    promptLabel.Font = Enum.Font.Gotham
    promptLabel.Parent = panel
    
    local textbox = Instance.new("TextBox")
    textbox.Name = "InputBox"
    textbox.Size = UDim2.new(1, -20, 0, 35)
    textbox.Position = UDim2.new(0, 10, 0, 45)
    textbox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    textbox.BackgroundTransparency = 0.3
    textbox.Text = ""
    textbox.TextColor3 = CONFIG.TEXT_COLOR
    textbox.TextSize = 14
    textbox.Font = Enum.Font.Gotham
    textbox.Parent = panel
    
    local textCorner = Instance.new("UICorner")
    textCorner.CornerRadius = UDim.new(0, 5)
    textCorner.Parent = textbox
    
    local okBtn = Instance.new("TextButton")
    okBtn.Name = "OKButton"
    okBtn.Size = UDim2.new(0, 100, 0, 30)
    okBtn.Position = UDim2.new(0, 10, 1, -40)
    okBtn.BackgroundColor3 = CONFIG.PRIMARY_COLOR
    okBtn.BackgroundTransparency = 0.1
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
    cancelBtn.Size = UDim2.new(0, 100, 0, 30)
    cancelBtn.Position = UDim2.new(1, -110, 1, -40)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    cancelBtn.BackgroundTransparency = 0.1
    cancelBtn.Text = "✕ CANCEL"
    cancelBtn.TextColor3 = CONFIG.TEXT_COLOR
    cancelBtn.TextSize = 12
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Parent = panel
    
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 5)
    cancelCorner.Parent = cancelBtn
    
    okBtn.MouseButton1Click:Connect(function()
        if textbox.Text ~= "" then
            callback(textbox.Text)
            dialog:Destroy()
        end
    end)
    
    cancelBtn.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
    
    textbox:CaptureFocus()
    textbox.FocusLost:Connect(function(enterPressed)
        if enterPressed and textbox.Text ~= "" then
            callback(textbox.Text)
            dialog:Destroy()
        end
    end)
end

function UIManager:ShowConfirmDialog(message)
    local result = false
    local dialog = Instance.new("ScreenGui")
    dialog.Name = "ConfirmDialog"
    dialog.ResetOnSpawn = false
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
    panel.Size = UDim2.new(0, 300, 0, 130)
    panel.Position = UDim2.new(0.5, -150, 0.5, -65)
    panel.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    panel.BorderSizePixel = 0
    panel.Parent = bgFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = panel
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 0, 40)
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
    yesBtn.Size = UDim2.new(0, 85, 0, 30)
    yesBtn.Position = UDim2.new(0, 10, 1, -40)
    yesBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    yesBtn.BackgroundTransparency = 0.1
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
    noBtn.Size = UDim2.new(0, 85, 0, 30)
    noBtn.Position = UDim2.new(1, -95, 1, -40)
    noBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    noBtn.BackgroundTransparency = 0.1
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
        result = true
        dialog:Destroy()
    end)
    
    noBtn.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
    
    return result
end

function UIManager:ToggleGui()
    self.IsOpen = not self.IsOpen
    self.MainGui.Enabled = self.IsOpen
end

-- ===== HAUPTPROGRAMM =====
local function Initialize()
    print("🚀 Teleport System wird initialisiert...")
    
    SaveManager:Load()
    UIManager:CreateMainGui()
    UIManager.MainGui.Enabled = false
    UIManager:RefreshPositionList()
    
    -- Tastaturkürzel
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == CONFIG.GUI_TOGGLE_KEY then
            UIManager:ToggleGui()
        end
    end)
    
    -- Character respawn handling
    player.CharacterAdded:Connect(function(newCharacter)
        character = newCharacter
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    end)
    
    print("✅ Teleport System erfolgreich geladen!")
    print("📌 Drücke 'P' um das GUI zu öffnen!")
end

Initialize()
