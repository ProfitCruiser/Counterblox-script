--====================================================--
-- AURORA PANEL — Restaurant Tycoon 3 Autofarm Shell
-- Cleaned menu shell that keeps the original look
-- while exposing the new RT3 automation controls.
--====================================================--

--// Services
local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--// Theme (kept from the original Aurora panel)
local Theme = {
    BG      = Color3.fromRGB(10, 9, 18),
    Panel   = Color3.fromRGB(18, 16, 31),
    Card    = Color3.fromRGB(24, 21, 40),
    Ink     = Color3.fromRGB(34, 30, 52),
    Stroke  = Color3.fromRGB(82, 74, 120),
    Neon    = Color3.fromRGB(160, 105, 255),
    Accent  = Color3.fromRGB(116, 92, 220),
    Text    = Color3.fromRGB(240, 240, 252),
    Subtle  = Color3.fromRGB(188, 182, 210),
    Good    = Color3.fromRGB(80, 210, 140),
    Warn    = Color3.fromRGB(255, 183, 77),
    Off     = Color3.fromRGB(100, 94, 130),
}

--// Utils ------------------------------------------------
local function safeParent()
    local ok, ui = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if ok and ui then return ui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function corner(o, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = o
end

local function stroke(o, col, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = col
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o
    return s
end

local function pad(o, px)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, px)
    p.PaddingBottom = UDim.new(0, px)
    p.PaddingLeft = UDim.new(0, px)
    p.PaddingRight = UDim.new(0, px)
    p.Parent = o
end

local function trim(str)
    str = tostring(str or "")
    return str:gsub("%s+$", ""):gsub("^%s+", "")
end

local function tween(obj, info, props)
    TweenService:Create(obj, info, props):Play()
end

local function makeShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.fromScale(0.5, 0.5)
    shadow.Size = UDim2.new(1, 46, 1, 46)
    shadow.ZIndex = -1
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.48
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Parent = parent
end

--// Key system defaults ---------------------------------
local DEFAULT_KEY = "FREE" -- change via getgenv().AuroraKey
local KEY_LINK    = "https://discord.gg/Pgn4NMWDH8"

local function resolveExternalKey()
    local ok, env = pcall(function()
        return getgenv and getgenv()
    end)
    if ok and type(env) == "table" and env.AuroraKey ~= nil then
        return env.AuroraKey
    end
    if type(shared) == "table" and shared.AuroraKey ~= nil then
        return shared.AuroraKey
    end
    if type(_G) == "table" and _G.AuroraKey ~= nil then
        return _G.AuroraKey
    end
    return nil
end

local function expectedKey()
    local key = resolveExternalKey()
    if key == nil then
        return DEFAULT_KEY
    end
    return key
end

local function gateHint()
    local exp = expectedKey()
    if exp == false then
        return "Nøkkel deaktivert via AuroraKey = false"
    elseif exp == "" then
        return "Skriv hvilken som helst tekst for å låse opp"
    end

    local value = tostring(exp)
    if value:lower() == tostring(DEFAULT_KEY):lower() then
        return "Standard nøkkel: " .. value
    end
    return "Tilpasset nøkkel: " .. value
end

local function checkKey(input)
    local expected = expectedKey()
    if expected == false then
        return true
    elseif expected == "" then
        return trim(input) ~= ""
    end
    return trim(input):lower() == tostring(expected):lower()
end

--// Automation backend ----------------------------------
local Auto = {
    Tycoon = nil,
    Surface = nil,
    Tables = {},
    TableList = {},
    SelectedTable = nil,
    GroupId = "1",
    CookVariant = 1,
    Running = false,
    StatusChanged = nil,
}

local TaskCompleted = nil
local Interacted = nil
local CookInput = nil
local GrabFood = nil

local function waitPath(root, path)
    local node = root
    for part in string.gmatch(path, "[^/]+") do
        node = node:WaitForChild(part)
    end
    return node
end

local function getRoot()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart"), char:WaitForChild("Humanoid")
end

local function dist(a, b)
    local ap = (a:IsA("BasePart") and a.Position) or (a.PrimaryPart and a.PrimaryPart.Position)
    local bp = (b:IsA("BasePart") and b.Position) or (b.PrimaryPart and b.PrimaryPart.Position)
    if not ap or not bp then
        return 0
    end
    return (ap - bp).Magnitude
end

local function near(a, b, maxD)
    maxD = maxD or 18
    return dist(a, b) <= maxD
end

local function pcallRetry(fn, tries, delaySec)
    tries = tries or 3
    delaySec = delaySec or 0.25
    local ok, res
    for _ = 1, tries do
        ok, res = pcall(fn)
        if ok then
            return true, res
        end
        task.wait(delaySec)
    end
    return false, res
end

local function getMyTycoon()
    local tycoons = workspace:FindFirstChild("Tycoons")
    if not tycoons then return nil end
    for _, t in ipairs(tycoons:GetChildren()) do
        local matchOwner = t:FindFirstChild("Owner")
        local matchUser = t:FindFirstChild("OwnerUserId")
        if (matchOwner and matchOwner.Value == LocalPlayer.Name)
            or (matchUser and tostring(matchUser.Value) == tostring(LocalPlayer.UserId)) then
            return t
        end
    end
    local ok, hrp = pcall(function()
        local root = getRoot()
        return root
    end)
    local nearest, best
    if ok and typeof(hrp) == "Instance" then
        for _, t in ipairs(tycoons:GetChildren()) do
            local p = t.PrimaryPart or t:FindFirstChildWhichIsA("BasePart")
            if p then
                local d = (p.Position - hrp.Position).Magnitude
                if not best or d < best then
                    best = d
                    nearest = t
                end
            end
        end
    end
    return nearest
end

local function discoverTables(surface)
    local tables = {}
    local names = {}
    if not surface then return tables, names end
    for _, child in ipairs(surface:GetChildren()) do
        local name = child.Name:lower()
        if name:match("^t%d+") or name:find("table") then
            tables[#tables + 1] = child
            names[#names + 1] = child.Name
        elseif child:FindFirstChild("Trash") and child.Trash:FindFirstChild("Food") then
            tables[#tables + 1] = child
            names[#names + 1] = child.Name
        end
    end
    table.sort(names)
    return tables, names
end

local function getSeatIds(tableModel)
    local ids = {}
    if not tableModel then return ids end
    local count = 0
    for _, d in ipairs(tableModel:GetDescendants()) do
        if d:IsA("Seat") or d.Name:lower():find("seat") then
            count += 1
        end
    end
    count = math.max(count, 2)
    for i = 1, count do
        ids[#ids + 1] = tostring(i)
    end
    return ids
end

local function getOrderSlipIds()
    local tmp = workspace:FindFirstChild("Temp")
    local ids = {}
    if tmp and tmp:FindFirstChild("Part") then
        for _, ch in ipairs(tmp.Part:GetChildren()) do
            if tonumber(ch.Name) then
                ids[#ids + 1] = ch.Name
            end
        end
    end
    if #ids == 0 then
        ids = {"0", "1"}
    end
    table.sort(ids, function(a, b)
        return tonumber(a) < tonumber(b)
    end)
    return ids
end

local function findStation(surface, hints, fallback)
    if not surface then return fallback end
    for _, h in ipairs(hints) do
        local m = surface:FindFirstChild(h)
        if m then return m end
    end
    for _, child in ipairs(surface:GetChildren()) do
        local lower = child.Name:lower()
        for _, hint in ipairs(hints) do
            if lower:find(hint:lower()) then
                return child
            end
        end
    end
    return fallback
end

local CookVariants = {
    { {"Kitchen", "Interact"}, {"Kitchen", "Complete"} },
    { {"Kitchen", "Interact"}, {"Kitchen", "Complete"}, {"Oven", "Interact"}, {"Oven", "Complete", false} },
    { {"Kitchen", "Interact"}, {"Kitchen", "Complete"}, {"Oven", "Interact"}, {"Oven", "Complete", false}, {"Kitchen", "Interact"}, {"Kitchen", "Complete"} }
}

local function buildTask(fields)
    local t = { Name = assert(fields.Name, "missing Name"), Tycoon = Auto.Tycoon }
    if fields.GroupId then t.GroupId = tostring(fields.GroupId) end
    if fields.FurnitureModel then t.FurnitureModel = fields.FurnitureModel end
    if fields.CustomerId then t.CustomerId = tostring(fields.CustomerId) end
    if fields.FoodModel then t.FoodModel = fields.FoodModel end
    return { t }
end

local function buildCounterPayload(id, counter)
    local tmp = workspace:FindFirstChild("Temp")
    local part = tmp and tmp:FindFirstChild("Part")
    local prompt = part and part:FindFirstChild(id)
    return Auto.Tycoon, {
        WorldPosition   = (part and part.Position) or Vector3.zero,
        HoldDuration    = 0.375,
        Part            = part or Instance.new("Part"),
        TemporaryPart   = part or Instance.new("Part"),
        Model           = counter,
        InteractionType = "OrderCounter",
        Prompt          = prompt or Instance.new("ProximityPrompt"),
        ActionText      = "Cook",
        Id              = tostring(id)
    }
end

local function foodModelFor(tableModel)
    if not tableModel then return nil end
    local ok, res = pcall(function()
        return tableModel.Trash.Food
    end)
    if ok and res then return res end
    for _, d in ipairs(tableModel:GetDescendants()) do
        if d.Name == "Food" then
            return d
        end
    end
    return nil
end

local function doTask(fields)
    return pcallRetry(function()
        TaskCompleted:FireServer(unpack(buildTask(fields)))
    end)
end

local function doCounter(id, counter)
    local a1, a2 = buildCounterPayload(id, counter)
    return pcallRetry(function()
        Interacted:FireServer(a1, a2)
    end)
end

local function cookStep(model, kind, action, flag)
    return pcallRetry(function()
        if action == "Interact" then
            CookInput:FireServer("Interact", model, kind)
        else
            if flag == nil then
                CookInput:FireServer("CompleteTask", model, kind)
            else
                CookInput:FireServer("CompleteTask", model, kind, flag)
            end
        end
    end)
end

local function grabFood(tableModel)
    local food = foodModelFor(tableModel)
    if not food then
        return false, "No food model"
    end
    return pcallRetry(function()
        return GrabFood:InvokeServer(food)
    end)
end

local function safeWait(t)
    local start = os.clock()
    while os.clock() - start < t do
        if not Auto.Running then return end
        RunService.Heartbeat:Wait()
    end
end

local function setStatus(text)
    if Auto.StatusChanged then
        Auto.StatusChanged(text)
    end
end

local function runVariant(variant, kitchen, oven)
    for _, step in ipairs(variant) do
        if not Auto.Running then return false end
        local kind, action, flag = step[1], step[2], step[3]
        local model = (kind == "Kitchen" and kitchen) or (kind == "Oven" and oven) or kitchen
        local ok = cookStep(model, kind, action, flag)
        if not ok then
            return false
        end
        safeWait(0.35)
    end
    return true
end

local function runTableFlow(tableModel, groupId, kitchen, oven, counter)
    if not tableModel then return end
    local seatIds = getSeatIds(tableModel)
    setStatus(string.format("Seating %s (G%s)", tableModel.Name, groupId))
    doTask({ Name = "SendToTable", GroupId = groupId, FurnitureModel = tableModel })
    safeWait(0.35)

    for _, seat in ipairs(seatIds) do
        if not Auto.Running then return end
        setStatus(string.format("Taking order %s:%s", groupId, seat))
        doTask({ Name = "TakeOrder", GroupId = groupId, CustomerId = seat })
        safeWait(0.25)
    end

    setStatus("Collecting order slips")
    for _, id in ipairs(getOrderSlipIds()) do
        if not Auto.Running then return end
        doCounter(id, counter)
        safeWait(0.2)
    end

    setStatus("Cooking")
    local variants = { CookVariants[Auto.CookVariant], CookVariants[2], CookVariants[3] }
    for _, variant in ipairs(variants) do
        if variant and runVariant(variant, kitchen, oven) then
            break
        end
        safeWait(0.25)
    end

    for _, seat in ipairs(seatIds) do
        if not Auto.Running then return end
        setStatus(string.format("Serving %s:%s", groupId, seat))
        grabFood(tableModel)
        safeWait(0.12)
        doTask({
            Name = "Serve",
            GroupId = groupId,
            CustomerId = seat,
            FurnitureModel = tableModel,
            FoodModel = foodModelFor(tableModel)
        })
        safeWait(0.2)
    end

    setStatus("Collecting bill")
    doTask({ Name = "CollectBill", FurnitureModel = tableModel })
    safeWait(0.2)
    doTask({ Name = "CollectDishes", FurnitureModel = tableModel })
    safeWait(0.2)
end

local function refreshTycoon()
    local tycoon = getMyTycoon()
    Auto.Tycoon = tycoon
    if not tycoon then
        Auto.Surface = nil
        Auto.Tables = {}
        Auto.TableList = {}
        return false
    end

    Auto.Surface = tycoon:FindFirstChild("Items") and tycoon.Items:FindFirstChild("Surface")
    Auto.Tables, Auto.TableList = discoverTables(Auto.Surface)
    if not table.find(Auto.Tables, Auto.SelectedTable) then
        Auto.SelectedTable = Auto.Tables[1]
    end
    return true
end

local function ensureRemotes()
    TaskCompleted = TaskCompleted or waitPath(RS, "Events/Restaurant/TaskCompleted")
    Interacted = Interacted or waitPath(RS, "Events/Restaurant/Interactions/Interacted")
    CookInput = CookInput or waitPath(RS, "Events/Cook/CookInputRequested")
    GrabFood = GrabFood or waitPath(RS, "Events/Restaurant/GrabFood")
end

local AutoThread

local function startAuto()
    if Auto.Running then return end
    ensureRemotes()
    if not refreshTycoon() then
        setStatus("Tycoon not found")
        return
    end

    if not Auto.SelectedTable then
        Auto.SelectedTable = Auto.Tables[1]
    end

    if not Auto.SelectedTable then
        setStatus("No tables detected")
        return
    end

    local kitchen = (Auto.Surface and (
        Auto.Surface:FindFirstChild("K15")
        or findStation(Auto.Surface, {"K15", "kitchen", "prep", "grill", "pan"})
        or Auto.Surface:FindFirstChildWhichIsA("Model")
    )) or Auto.SelectedTable

    local oven = (Auto.Surface and (
        Auto.Surface:FindFirstChild("K28")
        or findStation(Auto.Surface, {"K28", "oven", "bake"})
    )) or kitchen

    local counter = (Auto.Surface and (
        Auto.Surface:FindFirstChild("K16")
        or findStation(Auto.Surface, {"K16", "counter", "order"})
        or Auto.Surface
    )) or Auto.SelectedTable or Auto.Surface

    Auto.Running = true
    setStatus("Running")

    AutoThread = task.spawn(function()
        while Auto.Running do
            runTableFlow(Auto.SelectedTable, Auto.GroupId, kitchen, oven, counter)
            safeWait(0.5)
        end
        setStatus("Stopped")
    end)
end

local function stopAuto()
    Auto.Running = false
end

--// UI helpers -----------------------------------------
local RootGui = Instance.new("ScreenGui")
RootGui.Name = "AuroraRT3"
RootGui.DisplayOrder = 200
RootGui.IgnoreGuiInset = true
RootGui.ResetOnSpawn = false
RootGui.Parent = safeParent()

local Blur = Instance.new("BlurEffect")
Blur.Size = 12
Blur.Enabled = true
Blur.Parent = Lighting

-- Access Gate -------------------------------------------
local GateGui = Instance.new("ScreenGui")
GateGui.Name = "AuroraGate"
GateGui.IgnoreGuiInset = true
GateGui.ResetOnSpawn = false
GateGui.DisplayOrder = 999
GateGui.Parent = safeParent()

local Dim = Instance.new("Frame")
Dim.BackgroundColor3 = Color3.new(0, 0, 0)
Dim.BackgroundTransparency = 0.35
Dim.Size = UDim2.fromScale(1, 1)
Dim.Parent = GateGui

local Card = Instance.new("Frame")
Card.Size = UDim2.fromOffset(620, 360)
Card.AnchorPoint = Vector2.new(0.5, 0.5)
Card.Position = UDim2.fromScale(0.5, 0.5)
Card.BackgroundColor3 = Theme.Card
Card.Parent = GateGui
corner(Card, 18)
stroke(Card, Theme.Stroke, 1, 0.35)
pad(Card, 20)
makeShadow(Card)

local CardLayout = Instance.new("UIListLayout", Card)
CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
CardLayout.Padding = UDim.new(0, 14)

local Hero = Instance.new("Frame", Card)
Hero.BackgroundColor3 = Theme.Accent
Hero.BackgroundTransparency = 0.45
Hero.Size = UDim2.new(1, 0, 0, 120)
Hero.LayoutOrder = 1
Hero.ZIndex = 2
corner(Hero, 14)
stroke(Hero, Theme.Stroke, 1, 0.4)

local HeroPad = Instance.new("UIPadding", Hero)
HeroPad.PaddingTop = UDim.new(0, 16)
HeroPad.PaddingBottom = UDim.new(0, 16)
HeroPad.PaddingLeft = UDim.new(0, 18)
HeroPad.PaddingRight = UDim.new(0, 18)

local HeroLayout = Instance.new("UIListLayout", Hero)
HeroLayout.SortOrder = Enum.SortOrder.LayoutOrder
HeroLayout.Padding = UDim.new(0, 10)

local Pill = Instance.new("TextLabel", Hero)
Pill.Size = UDim2.fromOffset(160, 26)
Pill.BackgroundColor3 = Theme.Ink
Pill.BackgroundTransparency = 0.2
Pill.Text = "AURORA ACCESS"
Pill.Font = Enum.Font.GothamBold
Pill.TextSize = 13
Pill.TextColor3 = Theme.Text
Pill.TextXAlignment = Enum.TextXAlignment.Center
Pill.LayoutOrder = 1
Pill.ZIndex = 3
corner(Pill, 13)
stroke(Pill, Theme.Stroke, 1, 0.5)

local HeroTitle = Instance.new("TextLabel", Hero)
HeroTitle.BackgroundTransparency = 1
HeroTitle.Text = "ProfitCruiser — Restaurant Toolkit"
HeroTitle.Font = Enum.Font.GothamBlack
HeroTitle.TextSize = 24
HeroTitle.TextColor3 = Theme.Text
HeroTitle.TextXAlignment = Enum.TextXAlignment.Left
HeroTitle.Size = UDim2.new(1, 0, 0, 38)
HeroTitle.LayoutOrder = 2
HeroTitle.ZIndex = 3

local HeroSub = Instance.new("TextLabel", Hero)
HeroSub.BackgroundTransparency = 1
HeroSub.Text = "Lås opp menyen med nøkkelen din og styr den nye RT3-autofarmen."
HeroSub.Font = Enum.Font.Gotham
HeroSub.TextSize = 14
HeroSub.TextColor3 = Theme.Text
HeroSub.TextTransparency = 0.08
HeroSub.TextXAlignment = Enum.TextXAlignment.Left
HeroSub.Size = UDim2.new(1, 0, 0, 26)
HeroSub.LayoutOrder = 3
HeroSub.ZIndex = 3

local Field = Instance.new("Frame", Card)
Field.BackgroundColor3 = Theme.Panel
Field.Size = UDim2.new(1, 0, 0, 140)
Field.LayoutOrder = 2
corner(Field, 14)
stroke(Field, Theme.Stroke, 1, 0.42)
pad(Field, 16)

local FieldLayout = Instance.new("UIListLayout", Field)
FieldLayout.SortOrder = Enum.SortOrder.LayoutOrder
FieldLayout.Padding = UDim.new(0, 12)

local KeyLabel = Instance.new("TextLabel", Field)
KeyLabel.BackgroundTransparency = 1
KeyLabel.Text = "Skriv inn nøkkel"
KeyLabel.Font = Enum.Font.GothamSemibold
KeyLabel.TextSize = 16
KeyLabel.TextColor3 = Theme.Text
KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
KeyLabel.LayoutOrder = 1

local InputHolder = Instance.new("Frame", Field)
InputHolder.BackgroundColor3 = Theme.Ink
InputHolder.Size = UDim2.new(1, 0, 0, 40)
InputHolder.LayoutOrder = 2
corner(InputHolder, 12)
local InputStroke = stroke(InputHolder, Theme.Stroke, 1, 0.45)

local KeyBox = Instance.new("TextBox", InputHolder)
KeyBox.BackgroundTransparency = 1
KeyBox.Size = UDim2.new(1, -16, 1, 0)
KeyBox.Position = UDim2.fromOffset(8, 0)
KeyBox.ClearTextOnFocus = false
KeyBox.Text = ""
KeyBox.PlaceholderText = "Key"
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 16
KeyBox.TextColor3 = Theme.Text
KeyBox.TextXAlignment = Enum.TextXAlignment.Left

local ButtonRow = Instance.new("Frame", Field)
ButtonRow.BackgroundTransparency = 1
ButtonRow.Size = UDim2.new(1, 0, 0, 34)
ButtonRow.LayoutOrder = 3

local ButtonLayout = Instance.new("UIListLayout", ButtonRow)
ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
ButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
ButtonLayout.Padding = UDim.new(0, 10)

local function makeButton(parent, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(150, 34)
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.TextColor3 = Theme.Text
    btn.BackgroundColor3 = Theme.Accent
    btn.AutoButtonColor = false
    corner(btn, 12)
stroke(btn, Theme.Stroke, 1, 0.35)
    btn.Parent = parent
    return btn
end

local UnlockBtn = makeButton(ButtonRow, "Unlock")
local CopyBtn = makeButton(ButtonRow, "Copy Key Link")
CopyBtn.BackgroundColor3 = Theme.Ink

local StatusLabel = Instance.new("TextLabel", Field)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14
StatusLabel.LayoutOrder = 4

local function updateGateStatus(text, state)
    StatusLabel.Text = text or ""
    if state == "success" then
        StatusLabel.TextColor3 = Theme.Good
    elseif state == "error" then
        StatusLabel.TextColor3 = Theme.Warn
    else
        StatusLabel.TextColor3 = Theme.Subtle
    end
end

local function refreshKeyHint()
    updateGateStatus(gateHint())
    local expected = expectedKey()
    if expected == false then
        KeyBox.PlaceholderText = "Ingen nøkkel kreves"
    elseif expected == "" then
        KeyBox.PlaceholderText = "Valgfritt – skriv noe"
    else
        KeyBox.PlaceholderText = tostring(expected)
    end
end

CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(KEY_LINK)
        updateGateStatus("Lenke kopiert til utklippstavlen", "success")
    else
        updateGateStatus("Kan ikke kopiere i denne executoren", "error")
    end
    task.delay(2, function()
        if GateGui.Enabled then
            refreshKeyHint()
        end
    end)
end)

local function openPanel()
    GateGui.Enabled = false
    Blur.Enabled = false
    Blur.Size = 0
    RootGui.Enabled = true
end

local function setInputFeedback(state)
    local bg = Theme.Ink
    local strokeColor = Theme.Stroke
    if state == "success" then
        strokeColor = Theme.Good
    elseif state == "error" then
        bg = Color3.fromRGB(58, 24, 38)
        strokeColor = Theme.Warn
    end
    tween(InputHolder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = bg})
    if InputStroke then
        tween(InputStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = strokeColor})
    end
end

local function attemptUnlock()
    local input = KeyBox.Text
    if checkKey(input) then
        setInputFeedback("success")
        updateGateStatus("Godkjent!", "success")
        KeyBox.Text = ""
        tween(Card, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 1})
        Blur.Enabled = true
        Blur.Size = 12
        task.delay(0.32, openPanel)
    else
        setInputFeedback("error")
        updateGateStatus("Feil nøkkel. Prøv igjen.", "error")
        task.delay(0.4, function()
            if GateGui.Enabled then
                setInputFeedback()
                refreshKeyHint()
            end
        end)
    end
end

UnlockBtn.MouseButton1Click:Connect(attemptUnlock)

KeyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        attemptUnlock()
    end
end)

refreshKeyHint()
if expectedKey() == false then
    task.defer(attemptUnlock)
end

--// Main panel -----------------------------------------
RootGui.Enabled = false

local Panel = Instance.new("Frame", RootGui)
Panel.Name = "Panel"
Panel.AnchorPoint = Vector2.new(0.5, 0.5)
Panel.Position = UDim2.fromScale(0.5, 0.52)
Panel.Size = UDim2.fromOffset(880, 460)
Panel.BackgroundColor3 = Theme.Panel
Panel.BorderSizePixel = 0
corner(Panel, 20)
stroke(Panel, Theme.Stroke, 1, 0.38)
makeShadow(Panel)

local PanelPad = Instance.new("UIPadding", Panel)
PanelPad.PaddingTop = UDim.new(0, 18)
PanelPad.PaddingBottom = UDim.new(0, 18)
PanelPad.PaddingLeft = UDim.new(0, 18)
PanelPad.PaddingRight = UDim.new(0, 18)

local PanelLayout = Instance.new("UIListLayout", Panel)
PanelLayout.FillDirection = Enum.FillDirection.Vertical
PanelLayout.Padding = UDim.new(0, 16)
PanelLayout.SortOrder = Enum.SortOrder.LayoutOrder

local Header = Instance.new("Frame", Panel)
Header.Name = "Header"
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, 0, 0, 48)
Header.LayoutOrder = 1

local HeaderLayout = Instance.new("UIListLayout", Header)
HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
HeaderLayout.Padding = UDim.new(0, 12)
HeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local TitleLabel = Instance.new("TextLabel", Header)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(0, 280, 1, 0)
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 26
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextColor3 = Theme.Text
TitleLabel.Text = "Aurora — RT3"
TitleLabel.LayoutOrder = 1

local Nav = Instance.new("Frame", Header)
Nav.Size = UDim2.new(1, -320, 1, 0)
Nav.BackgroundTransparency = 1
Nav.LayoutOrder = 2

local NavLayout = Instance.new("UIListLayout", Nav)
NavLayout.FillDirection = Enum.FillDirection.Horizontal
NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NavLayout.Padding = UDim.new(0, 10)

local function makeNavButton(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(120, 34)
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.TextColor3 = Theme.Subtle
    btn.BackgroundColor3 = Theme.Ink
    btn.AutoButtonColor = false
    corner(btn, 12)
stroke(btn, Theme.Stroke, 1, 0.4)
    btn.Parent = Nav
    return btn
end

local Tabs = {}
local ActiveTab = nil

local Body = Instance.new("Frame", Panel)
Body.Name = "Body"
Body.BackgroundTransparency = 1
Body.Size = UDim2.new(1, 0, 1, -80)
Body.LayoutOrder = 2

local BodyLayout = Instance.new("UIListLayout", Body)
BodyLayout.FillDirection = Enum.FillDirection.Horizontal
BodyLayout.Padding = UDim.new(0, 18)
BodyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

local function makeTab(name)
    local frame = Instance.new("Frame", Body)
    frame.Name = name
    frame.BackgroundColor3 = Theme.Card
    frame.Size = UDim2.new(0.5, -9, 1, 0)
    frame.Visible = false
    corner(frame, 18)
stroke(frame, Theme.Stroke, 1, 0.45)
pad(frame, 18)

    local layout = Instance.new("UIListLayout", frame)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)

    Tabs[name] = frame
    return frame
end

local function switchTab(name)
    if ActiveTab == name then return end
    for tabName, frame in pairs(Tabs) do
        frame.Visible = (tabName == name)
    end
    ActiveTab = name
    for _, btn in ipairs(Nav:GetChildren()) do
        if btn:IsA("TextButton") then
            if btn.Text == name then
                btn.TextColor3 = Theme.Text
                btn.BackgroundColor3 = Theme.Accent
            else
                btn.TextColor3 = Theme.Subtle
                btn.BackgroundColor3 = Theme.Ink
            end
        end
    end
end

local AutofarmTab = makeTab("Autofarm")
local SettingsTab = makeTab("UI")
local InfoTab = makeTab("Info")

local AutoBtn = makeNavButton("Autofarm")
local SettingsBtn = makeNavButton("UI")
local InfoBtn = makeNavButton("Info")

AutoBtn.MouseButton1Click:Connect(function() switchTab("Autofarm") end)
SettingsBtn.MouseButton1Click:Connect(function() switchTab("UI") end)
InfoBtn.MouseButton1Click:Connect(function() switchTab("Info") end)

switchTab("Autofarm")

-- Autofarm controls -------------------------------------
local function makeSection(parent, title)
    local section = Instance.new("Frame", parent)
    section.BackgroundTransparency = 1
    section.LayoutOrder = #parent:GetChildren() + 1
    section.Size = UDim2.new(1, 0, 0, 36)

    local label = Instance.new("TextLabel", section)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 24)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 18
    label.TextColor3 = Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = title

    local line = Instance.new("Frame", section)
    line.BackgroundColor3 = Theme.Stroke
    line.BackgroundTransparency = 0.35
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.fromOffset(0, 28)

    return section
end

local function makeRow(parent, labelText)
    local row = Instance.new("Frame", parent)
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 44)

    local layout = Instance.new("UIListLayout", row)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 10)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center

    local label = Instance.new("TextLabel", row)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.45, 0, 1, 0)
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.TextColor3 = Theme.Subtle
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText

    return row, label
end

local function makeCycler(parent, options, default)
    local button = Instance.new("TextButton", parent)
    button.Size = UDim2.new(0.55, 0, 1, -6)
    button.BackgroundColor3 = Theme.Ink
    button.TextColor3 = Theme.Text
    button.Font = Enum.Font.Gotham
    button.TextSize = 16
    button.AutoButtonColor = false
    corner(button, 12)
    stroke(button, Theme.Stroke, 1, 0.4)

    local list = options or {"-"}
    local index = 1
    local onChanged = nil

    local function setIndex(i)
        if #list == 0 then
            button.Text = "-"
            index = 0
            return
        end
        index = ((i - 1) % #list) + 1
        button.Text = list[index]
        if onChanged then
            pcall(onChanged, list[index], index)
        end
    end

    local function setOptions(new)
        list = (new and #new > 0) and new or {"-"}
        if default then
            local idx = table.find(list, default)
            if idx then
                setIndex(idx)
                return
            end
        end
        setIndex(1)
    end

    button.MouseButton1Click:Connect(function()
        setIndex(index + 1)
    end)

    setOptions(options)

    return {
        Button = button,
        Get = function()
            return list[index], index
        end,
        SetOptions = setOptions,
        Set = function(value)
            local idx = table.find(list, value)
            if idx then setIndex(idx) end
        end,
        OnChanged = function(cb)
            onChanged = cb
        end
    }
end

makeSection(AutofarmTab, "RT3 Autofarm")

local TycoonRow, TycoonLabel = makeRow(AutofarmTab, "Tycoon status")
TycoonLabel.TextColor3 = Theme.Subtle
TycoonLabel.Text = "Ikke oppdaget"
TycoonLabel.Size = UDim2.new(1, 0, 1, 0)

local TableRow = Instance.new("Frame", AutofarmTab)
TableRow.BackgroundTransparency = 1
TableRow.Size = UDim2.new(1, 0, 0, 44)
local TableRowLayout = Instance.new("UIListLayout", TableRow)
TableRowLayout.FillDirection = Enum.FillDirection.Horizontal
TableRowLayout.Padding = UDim.new(0, 10)
TableRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local TableLabel = Instance.new("TextLabel", TableRow)
TableLabel.BackgroundTransparency = 1
TableLabel.Size = UDim2.new(0.45, 0, 1, 0)
TableLabel.Font = Enum.Font.Gotham
TableLabel.TextSize = 16
TableLabel.TextColor3 = Theme.Subtle
TableLabel.TextXAlignment = Enum.TextXAlignment.Left
TableLabel.Text = "Bord"

local TableCycler = makeCycler(TableRow, {"-"})
TableCycler.OnChanged(function(name)
    for _, tbl in ipairs(Auto.Tables) do
        if tbl.Name == name then
            Auto.SelectedTable = tbl
            break
        end
    end
end)

local GroupRow, GroupLabel = makeRow(AutofarmTab, "GroupId")
local GroupCycler = makeCycler(GroupRow, {"1", "2", "3", "4"})
GroupCycler.Set("1")
GroupCycler.OnChanged(function(value)
    Auto.GroupId = value
end)

local CookRow, CookLabel = makeRow(AutofarmTab, "Oppskrift")
local CookCycler = makeCycler(CookRow, {"Kitchen", "Kitchen>Oven", "Kitchen>Oven>Kitchen"}, "Kitchen")
CookCycler.OnChanged(function(_, index)
    Auto.CookVariant = index
end)

local ButtonRow2 = Instance.new("Frame", AutofarmTab)
ButtonRow2.BackgroundTransparency = 1
ButtonRow2.Size = UDim2.new(1, 0, 0, 44)
local ButtonRow2Layout = Instance.new("UIListLayout", ButtonRow2)
ButtonRow2Layout.FillDirection = Enum.FillDirection.Horizontal
ButtonRow2Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
ButtonRow2Layout.Padding = UDim.new(0, 12)
ButtonRow2Layout.VerticalAlignment = Enum.VerticalAlignment.Center

local StartBtn = makeButton(ButtonRow2, "Start")
local StopBtn = makeButton(ButtonRow2, "Stop")
StopBtn.BackgroundColor3 = Theme.Ink
StopBtn.TextColor3 = Theme.Text

local RefreshBtn = makeButton(ButtonRow2, "Refresh")
RefreshBtn.BackgroundColor3 = Theme.Ink

local AutoStatus = Instance.new("TextLabel", AutofarmTab)
AutoStatus.BackgroundTransparency = 1
AutoStatus.Size = UDim2.new(1, 0, 0, 24)
AutoStatus.Font = Enum.Font.Gotham
AutoStatus.TextSize = 14
AutoStatus.TextXAlignment = Enum.TextXAlignment.Left
AutoStatus.TextColor3 = Theme.Subtle
AutoStatus.Text = "Status: Idle"

Auto.StatusChanged = function(text)
    AutoStatus.TextColor3 = Theme.Text
    AutoStatus.Text = "Status: " .. tostring(text)
end

local function syncTycoon()
    if refreshTycoon() then
        TycoonLabel.Text = Auto.Tycoon and ("Funnet: " .. Auto.Tycoon.Name) or "Ikke oppdaget"
        TycoonLabel.TextColor3 = Theme.Good
        TableCycler.SetOptions(Auto.TableList)
        if Auto.SelectedTable then
            TableCycler.Set(Auto.SelectedTable.Name)
        end
    else
        TycoonLabel.Text = "Fant ikke tycoonen din"
        TycoonLabel.TextColor3 = Theme.Warn
        TableCycler.SetOptions({"-"})
    end
end

RefreshBtn.MouseButton1Click:Connect(function()
    syncTycoon()
    AutoStatus.TextColor3 = Theme.Subtle
    AutoStatus.Text = "Status: Oppdatert"
end)

StartBtn.MouseButton1Click:Connect(function()
    if Auto.Running then
        AutoStatus.TextColor3 = Theme.Warn
        AutoStatus.Text = "Status: Kjører allerede"
        return
    end

    local tableName = TableCycler.Get()
    if not tableName or tableName == "-" then
        AutoStatus.TextColor3 = Theme.Warn
        AutoStatus.Text = "Status: Ingen bord valgt"
        return
    end

    for _, tbl in ipairs(Auto.Tables) do
        if tbl.Name == tableName then
            Auto.SelectedTable = tbl
            break
        end
    end

    Auto.GroupId = GroupCycler.Get()
    Auto.CookVariant = select(2, CookCycler.Get())
    AutoStatus.TextColor3 = Theme.Text
    AutoStatus.Text = "Status: Starter"
    startAuto()
end)

StopBtn.MouseButton1Click:Connect(function()
    stopAuto()
    AutoStatus.TextColor3 = Theme.Subtle
    AutoStatus.Text = "Status: Stoppet"
end)

-- UI tab -------------------------------------------------
makeSection(SettingsTab, "Grensesnitt")

local Hint = Instance.new("TextLabel", SettingsTab)
Hint.BackgroundTransparency = 1
Hint.Size = UDim2.new(1, 0, 0, 48)
Hint.Font = Enum.Font.Gotham
Hint.TextSize = 14
Hint.TextColor3 = Theme.Subtle
Hint.TextWrapped = true
Hint.Text = "Denne menyen er en ren skallversjon av Aurora-panelet. Alle gamle aimbot/ESP-funksjoner er fjernet slik at du kan fokusere på Restaurant Tycoon 3-autofarmen."

local HideKeybind = Instance.new("TextLabel", SettingsTab)
HideKeybind.BackgroundTransparency = 1
HideKeybind.Size = UDim2.new(1, 0, 0, 24)
HideKeybind.Font = Enum.Font.GothamSemibold
HideKeybind.TextSize = 16
HideKeybind.TextColor3 = Theme.Text
HideKeybind.TextXAlignment = Enum.TextXAlignment.Left
HideKeybind.Text = "RightShift — vis/skjul"

local function togglePanel()
    if GateGui.Enabled then return end
    RootGui.Enabled = not RootGui.Enabled
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        togglePanel()
    end
end)

-- Info tab ----------------------------------------------
makeSection(InfoTab, "Om denne builden")

local InfoText = Instance.new("TextLabel", InfoTab)
InfoText.BackgroundTransparency = 1
InfoText.Size = UDim2.new(1, 0, 0, 120)
InfoText.Font = Enum.Font.Gotham
InfoText.TextSize = 14
InfoText.TextColor3 = Theme.Subtle
InfoText.TextWrapped = true
InfoText.Text = [[Denne utgaven av Aurora-panelet er strippet for aimbot/ESP og andre Counter Blox-funksjoner. Alt fokus ligger på Restaurant Tycoon 3-automasjon.

• Bruk "Refresh" for å auto-oppdage tycoonen og bordene dine.
• Start-knappen kjører den innebygde RT3-rutinen til du trykker Stop.
• Nøkkel-systemet kan endres med getgenv().AuroraKey før du laster scriptet.]]

makeSection(InfoTab, "Kontakter")

local Contact = Instance.new("TextLabel", InfoTab)
Contact.BackgroundTransparency = 1
Contact.Size = UDim2.new(1, 0, 0, 32)
Contact.Font = Enum.Font.Gotham
Contact.TextSize = 14
Contact.TextColor3 = Theme.Subtle
Contact.TextXAlignment = Enum.TextXAlignment.Left
Contact.Text = "Discord: ProfitCruiser helper"

-- Initial state
syncTycoon()

print("[Aurora RT3] Menu loaded. Unlock with your key to access the autofarm shell.")
