local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- CONFIG
local C = {
    GUI_KEY = Enum.KeyCode.P,
    MAX_POS = 15,
    PC = Color3.fromRGB(0, 120, 255),
    SC = Color3.fromRGB(255, 85, 0),
    DC = Color3.fromRGB(200, 50, 50),
    GC = Color3.fromRGB(20, 20, 30),
    TC = Color3.fromRGB(255, 255, 255),
}

-- SAVE
local SM = {}
SM.Data = {}

function SM:L()
    local s, d = pcall(function()
        if player:FindFirstChild("TD") then
            return HttpService:JSONDecode(player.TD.Value)
        end
        return {}
    end)
    self.Data = s and d or {}
    return self.Data
end

function SM:S()
    pcall(function()
        local j = HttpService:JSONEncode(self.Data)
        local o = player:FindFirstChild("TD")
        if not o then
            o = Instance.new("StringValue")
            o.Name = "TD"
            o.Parent = player
        end
        o.Value = j
    end)
end

function SM:A(n, p, ic)
    if #self.Data >= C.MAX_POS then
        table.remove(self.Data, 1)
    end
    table.insert(self.Data, {
        n = n or "Pos_" .. os.time(),
        x = math.round(p.X * 100) / 100,
        y = math.round(p.Y * 100) / 100,
        z = math.round(p.Z * 100) / 100,
        ic = ic or "📍",
        t = os.time(),
        v = 0
    })
    self:S()
end

function SM:D(i)
    table.remove(self.Data, i)
    self:S()
end

function SM:C()
    self.Data = {}
    self:S()
end

-- TELEPORT
local TU = {}

function TU:T(p)
    local c = player.Character
    if not c then return false end
    local h = c:FindFirstChild("HumanoidRootPart")
    if h then
        h.CFrame = CFrame.new(p + Vector3.new(0, 3, 0))
    end
    return true
end

function TU:G()
    return humanoidRootPart.Position
end

function TU:F(p)
    return string.format("X: %.1f | Y: %.1f | Z: %.1f", p.X, p.Y, p.Z)
end

-- STATS
local ST = {}
ST.TT = 0
ST.SS = os.time()

function ST:I()
    self.TT = self.TT + 1
end

-- UI
local UM = {}
UM.MainGui = nil
UM.IsOpen = false

local function CreateButton(txt, par, pos, siz, col)
    local b = Instance.new("TextButton")
    b.Name = txt
    b.Size = siz
    b.Position = pos
    b.BackgroundColor3 = col or C.PC
    b.BackgroundTransparency = 0.1
    b.Text = txt
    b.TextColor3 = C.TC
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = par
    local cor = Instance.new("UICorner")
    cor.CornerRadius = UDim.new(0, 6)
    cor.Parent = b
    b.MouseEnter:Connect(function()
        b.BackgroundTransparency = 0.05
    end)
    b.MouseLeave:Connect(function()
        b.BackgroundTransparency = 0.1
    end)
    return b
end

local function ShowNotif(msg)
    local n = Instance.new("TextLabel")
    n.Name = "Notif"
    n.Size = UDim2.new(0, 300, 0, 50)
    n.Position = UDim2.new(0.5, -150, 0, 20)
    n.BackgroundColor3 = C.PC
    n.BackgroundTransparency = 0.2
    n.Text = msg
    n.TextColor3 = C.TC
    n.TextSize = 13
    n.Font = Enum.Font.Gotham
    n.Parent = playerGui
    local cor = Instance.new("UICorner")
    cor.CornerRadius = UDim.new(0, 8)
    cor.Parent = n
    Debris:AddItem(n, 2.5)
end

local function ShowDialog(title, msg, callback)
    local d = Instance.new("ScreenGui")
    d.Name = "Dialog"
    d.ResetOnSpawn = false
    d.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    d.Parent = playerGui
    
    local bg = Instance.new("Frame")
    bg.Name = "BG"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.new(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.BorderSizePixel = 0
    bg.Parent = d
    
    local p = Instance.new("Frame")
    p.Name = "P"
    p.Size = UDim2.new(0, 360, 0, 150)
    p.Position = UDim2.new(0.5, -180, 0.5, -75)
    p.BackgroundColor3 = C.GC
    p.BorderSizePixel = 0
    p.Parent = bg
    
    local cor = Instance.new("UICorner")
    cor.CornerRadius = UDim.new(0, 10)
    cor.Parent = p
    
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, -20, 0, 30)
    tl.Position = UDim2.new(0, 10, 0, 10)
    tl.BackgroundTransparency = 1
    tl.Text = title
    tl.TextColor3 = C.TC
    tl.TextSize = 14
    tl.Font = Enum.Font.GothamBold
    tl.Parent = p
    
    local tb = Instance.new("TextBox")
    tb.Name = "TB"
    tb.Size = UDim2.new(1, -20, 0, 35)
    tb.Position = UDim2.new(0, 10, 0, 45)
    tb.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    tb.BackgroundTransparency = 0.2
    tb.Text = ""
    tb.TextColor3 = C.TC
    tb.TextSize = 13
    tb.Font = Enum.Font.Gotham
    tb.Parent = p
    
    local tbc = Instance.new("UICorner")
    tbc.CornerRadius = UDim.new(0, 5)
    tbc.Parent = tb
    
    local ok = Instance.new("TextButton")
    ok.Name = "OK"
    ok.Size = UDim2.new(0, 100, 0, 28)
    ok.Position = UDim2.new(0, 10, 1, -38)
    ok.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    ok.BackgroundTransparency = 0.15
    ok.Text = "✓ OK"
    ok.TextColor3 = C.TC
    ok.TextSize = 11
    ok.Font = Enum.Font.GothamBold
    ok.BorderSizePixel = 0
    ok.Parent = p
    
    local okc = Instance.new("UICorner")
    okc.CornerRadius = UDim.new(0, 5)
    okc.Parent = ok
    
    local can = Instance.new("TextButton")
    can.Name = "CAN"
    can.Size = UDim2.new(0, 100, 0, 28)
    can.Position = UDim2.new(1, -110, 1, -38)
    can.BackgroundColor3 = C.DC
    can.BackgroundTransparency = 0.15
    can.Text = "✕ CANCEL"
    can.TextColor3 = C.TC
    can.TextSize = 11
    can.Font = Enum.Font.GothamBold
    can.BorderSizePixel = 0
    can.Parent = p
    
    local canc = Instance.new("UICorner")
    canc.CornerRadius = UDim.new(0, 5)
    canc.Parent = can
    
    ok.MouseButton1Click:Connect(function()
        if tb.Text ~= "" then
            callback(tb.Text)
            d:Destroy()
        end
    end)
    
    can.MouseButton1Click:Connect(function()
        d:Destroy()
    end)
    
    tb:CaptureFocus()
end

function UM:CreateGui()
    local sg = Instance.new("ScreenGui")
    sg.Name = "TeleportGui"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = playerGui
    
    local mp = Instance.new("Frame")
    mp.Name = "MainPanel"
    mp.Size = UDim2.new(0, 420, 0, 650)
    mp.Position = UDim2.new(0.5, -210, 0.5, -325)
    mp.BackgroundColor3 = C.GC
    mp.BackgroundTransparency = 0.1
    mp.BorderSizePixel = 0
    mp.Parent = sg
    mp.Draggable = true
    mp.Active = true
    
    local mcor = Instance.new("UICorner")
    mcor.CornerRadius = UDim.new(0, 8)
    mcor.Parent = mp
    
    local msh = Instance.new("UIStroke")
    msh.Color = C.PC
    msh.Thickness = 2
    msh.Transparency = 0.3
    msh.Parent = mp
    
    -- HEADER
    local hd = Instance.new("Frame")
    hd.Name = "Header"
    hd.Size = UDim2.new(1, 0, 0, 55)
    hd.BackgroundColor3 = C.PC
    hd.BorderSizePixel = 0
    hd.Parent = mp
    
    local hdcor = Instance.new("UICorner")
    hdcor.CornerRadius = UDim.new(0, 8)
    hdcor.Parent = hd
    
    local tl = Instance.new("TextLabel")
    tl.Name = "Title"
    tl.Size = UDim2.new(1, -60, 1, 0)
    tl.Position = UDim2.new(0, 10, 0, 0)
    tl.BackgroundTransparency = 1
    tl.Text = "🚀 TELEPORT SYSTEM"
    tl.TextColor3 = C.TC
    tl.TextSize = 16
    tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.Parent = hd
    
    local cl = Instance.new("TextButton")
    cl.Name = "Close"
    cl.Size = UDim2.new(0, 50, 1, 0)
    cl.Position = UDim2.new(1, -50, 0, 0)
    cl.BackgroundTransparency = 1
    cl.Text = "✕"
    cl.TextColor3 = C.TC
    cl.TextSize = 18
    cl.Font = Enum.Font.GothamBold
    cl.Parent = hd
    
    cl.MouseButton1Click:Connect(function()
        self:ToggleGui()
    end)
    
    -- CONTENT
    local cf = Instance.new("Frame")
    cf.Name = "Content"
    cf.Size = UDim2.new(1, 0, 1, -55)
    cf.Position = UDim2.new(0, 0, 0, 55)
    cf.BackgroundTransparency = 1
    cf.Parent = mp
    
    -- BUTTONS
    local ba = Instance.new("Frame")
    ba.Name = "ButtonArea"
    ba.Size = UDim2.new(1, 0, 0, 100)
    ba.BackgroundTransparency = 1
    ba.Parent = cf
    
    local posBtn = CreateButton("📍 POSITION", ba, UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -7, 0, 28))
    posBtn.MouseButton1Click:Connect(function()
        local p = TU:G()
        ShowNotif("Position: " .. TU:F(p))
    end)
    
    local saveBtn = CreateButton("💾 SPEICHERN", ba, UDim2.new(0.5, 7, 0, 10), UDim2.new(0.5, -7, 0, 28))
    saveBtn.MouseButton1Click:Connect(function()
        ShowDialog("Positionsname:", "Gib einen Namen ein", function(name)
            SM:A(name, TU:G(), "📍")
            UM:RefreshList()
            ShowNotif("✅ Position gespeichert!")
        end)
    end)
    
    local tpBtn = CreateButton("⚡ TELEPORTIEREN", ba, UDim2.new(0, 10, 0, 45), UDim2.new(1, -20, 0, 28), C.SC)
    
    local lastBtn = CreateButton("🔙 LETZTE", ba, UDim2.new(0, 10, 0, 80), UDim2.new(0.5, -7, 0, 15))
    if #SM.Data > 0 then
        lastBtn.MouseButton1Click:Connect(function()
            local last = SM.Data[#SM.Data]
            TU:T(Vector3.new(last.x, last.y, last.z))
            ST:I()
            ShowNotif("✅ Zu " .. last.n .. " teleportiert!")
        end)
    end
    
    local delBtn = CreateButton("🗑️ LÖSCHEN", ba, UDim2.new(0.5, 7, 0, 80), UDim2.new(0.5, -7, 0, 15), C.DC)
    delBtn.MouseButton1Click:Connect(function()
        SM:C()
        UM:RefreshList()
        ShowNotif("🗑️ Alles gelöscht!")
    end)
    
    -- LIST
    local ll = Instance.new("TextLabel")
    ll.Name = "ListLabel"
    ll.Size = UDim2.new(1, 0, 0, 20)
    ll.Position = UDim2.new(0, 10, 0, 105)
    ll.BackgroundTransparency = 1
    ll.Text = "📋 Positionen (" .. #SM.Data .. ")"
    ll.TextColor3 = C.PC
    ll.TextSize = 12
    ll.Font = Enum.Font.GothamBold
    ll.TextXAlignment = Enum.TextXAlignment.Left
    ll.Parent = cf
    
    local sf = Instance.new("ScrollingFrame")
    sf.Name = "List"
    sf.Size = UDim2.new(1, -20, 1, -130)
    sf.Position = UDim2.new(0, 10, 0, 125)
    sf.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    sf.BackgroundTransparency = 0.3
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 6
    sf.Parent = cf
    
    local sfcor = Instance.new("UICorner")
    sfcor.CornerRadius = UDim.new(0, 6)
    sfcor.Parent = sf
    
    local sl = Instance.new("UIListLayout")
    sl.Padding = UDim.new(0, 5)
    sl.Parent = sf
    
    self.MainGui = sg
    self.ListFrame = sf
    self.ListLayout = sl
    self.ListLabel = ll
    
    return sg
end

function UM:RefreshList()
    for _, child in ipairs(self.ListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    SM:L()
    self.ListLabel.Text = "📋 Positionen (" .. #SM.Data .. ")"
    
    for index, posData in ipairs(SM.Data) do
        local pf = Instance.new("Frame")
        pf.Name = "PosFrame_" .. index
        pf.Size = UDim2.new(1, -10, 0, 65)
        pf.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        pf.BorderSizePixel = 0
        pf.Parent = self.ListFrame
        
        local pfcor = Instance.new("UICorner")
        pfcor.CornerRadius = UDim.new(0, 5)
        pfcor.Parent = pf
        
        local nl = Instance.new("TextLabel")
        nl.Name = "Name"
        nl.Size = UDim2.new(0.65, 0, 0.4, 0)
        nl.Position = UDim2.new(0, 8, 0, 5)
        nl.BackgroundTransparency = 1
        nl.Text = posData.ic .. " " .. posData.n
        nl.TextColor3 = C.PC
        nl.TextSize = 11
        nl.Font = Enum.Font.GothamBold
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Parent = pf
        
        local cl = Instance.new("TextLabel")
        cl.Name = "Coords"
        cl.Size = UDim2.new(1, -16, 0.4, 0)
        cl.Position = UDim2.new(0, 8, 0.4, 2)
        cl.BackgroundTransparency = 1
        cl.Text = TU:F(Vector3.new(posData.x, posData.y, posData.z))
        cl.TextColor3 = Color3.fromRGB(150, 150, 150)
        cl.TextSize = 9
        cl.Font = Enum.Font.Gotham
        cl.TextXAlignment = Enum.TextXAlignment.Left
        cl.Parent = pf
        
        local tpb = Instance.new("TextButton")
        tpb.Name = "TP"
        tpb.Size = UDim2.new(0, 45, 0, 55)
        tpb.Position = UDim2.new(1, -53, 0.05, 0)
        tpb.BackgroundColor3 = C.SC
        tpb.BackgroundTransparency = 0.15
        tpb.Text = "⚡"
        tpb.TextColor3 = C.TC
        tpb.TextSize = 18
        tpb.Font = Enum.Font.GothamBold
        tpb.BorderSizePixel = 0
        tpb.Parent = pf
        
        local tpbcor = Instance.new("UICorner")
        tpbcor.CornerRadius = UDim.new(0, 4)
        tpbcor.Parent = tpb
        
        tpb.MouseButton1Click:Connect(function()
            TU:T(Vector3.new(posData.x, posData.y, posData.z))
            ST:I()
            ShowNotif("✅ Teleportiert!")
            posData.v = (posData.v or 0) + 1
            SM:S()
        end)
        
        local db = Instance.new("TextButton")
        db.Name = "DEL"
        db.Size = UDim2.new(0, 45, 0, 55)
        db.Position = UDim2.new(1, -104, 0.05, 0)
        db.BackgroundColor3 = C.DC
        db.BackgroundTransparency = 0.2
        db.Text = "🗑️"
        db.TextColor3 = C.TC
        db.TextSize = 16
        db.Font = Enum.Font.GothamBold
        db.BorderSizePixel = 0
        db.Parent = pf
        
        local dbcor = Instance.new("UICorner")
        dbcor.CornerRadius = UDim.new(0, 4)
        dbcor.Parent = db
        
        db.MouseButton1Click:Connect(function()
            SM:D(index)
            self:RefreshList()
            ShowNotif("🗑️ Gelöscht!")
        end)
    end
    
    self.ListFrame.CanvasSize = UDim2.new(0, 0, 0, self.ListLayout.AbsoluteContentSize.Y + 10)
end

function UM:ToggleGui()
    self.IsOpen = not self.IsOpen
    self.MainGui.Enabled = self.IsOpen
end

-- INIT
local function Init()
    print("🚀 Teleport System wird geladen...")
    SM:L()
    UM:CreateGui()
    UM.MainGui.Enabled = false
    UM:RefreshList()
    
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == C.GUI_KEY then
            UM:ToggleGui()
        end
    end)
    
    player.CharacterAdded:Connect(function(nc)
        character = nc
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    end)
    
    print("✅ Teleport System geladen!")
    print("📌 Drücke 'P' um das GUI zu öffnen!")
    ShowNotif("🚀 Teleport System geladen! Drücke P")
end

Init()
