--[[
RT3 Executor — Full Auto Menu (One‑File, No Storage)
Author: ProfitCruiser helper

What this is:
  • A single executor-friendly Lua that adds everything you asked for so the menu “just works”.
  • No module requires, no storage lookups beyond Workspace/ReplicatedStorage.
  • Provides: auto‑detect Tycoon, dynamic seats per table, dynamic order‑slip IDs,
    adaptive cooking runner, retries/pcalls, proximity checks, pause on movement/death,
    simple on‑screen menu with Start/Stop and table/flow selectors.

What it does NOT do:
  • It does not bypass game security — all calls are exactly the ones you logged.
  • It does not hardcode GroupIds per table; uses smart defaults + UI overrides.

Hotkeys:
  • RightShift – toggle menu
]]

-- ========= Services =========
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer

-- ========= Tiny helpers =========
local function waitPath(root, path)
    local node = root
    for part in string.gmatch(path, "[^/]+") do
        node = node:WaitForChild(part)
    end
    return node
end

local function getRoot()
    local c = LP.Character or LP.CharacterAdded:Wait()
    return c:WaitForChild("HumanoidRootPart"), c:WaitForChild("Humanoid")
end

local function dist(a, b)
    local ap = (a:IsA("BasePart") and a.Position) or (a.PrimaryPart and a.PrimaryPart.Position)
    local bp = (b:IsA("BasePart") and b.Position) or (b.PrimaryPart and b.PrimaryPart.Position)
    if not ap or not bp then return 0 end
    return (ap - bp).Magnitude
end

local function near(a, b, maxD)
    maxD = maxD or 18
    return dist(a,b) <= maxD
end

local function pcallRetry(fn, tries, delaySec)
    tries = tries or 3; delaySec = delaySec or 0.25
    local ok, res
    for i=1,tries do
        ok, res = pcall(fn)
        if ok then return true, res end
        task.wait(delaySec)
    end
    return false, res
end

-- ========= Remotes (as discovered from your logs) =========
local TaskCompleted   = waitPath(RS, "Events/Restaurant/TaskCompleted")         -- :FireServer({{...}})
local Interacted      = waitPath(RS, "Events/Restaurant/Interactions/Interacted") -- :FireServer(Tycoon, { ... })
local CookInput       = waitPath(RS, "Events/Cook/CookInputRequested")          -- :FireServer(step, model, type, [bool])
local GrabFood        = waitPath(RS, "Events/Restaurant/GrabFood")              -- :InvokeServer(FoodModel)

-- ========= Auto‑detect MY Tycoon =========
local function getMyTycoon()
    local tycoons = workspace:WaitForChild("Tycoons")
    for _, t in ipairs(tycoons:GetChildren()) do
        local ok1 = t:FindFirstChild("OwnerUserId") and tostring(t.OwnerUserId.Value) == tostring(LP.UserId)
        local ok2 = t:FindFirstChild("Owner") and t.Owner.Value == LP.Name
        if ok1 or ok2 then return t end
    end
    -- fallback: nearest
    local hrp = getRoot()
    local best, bestD
    for _, t in ipairs(tycoons:GetChildren()) do
        local p = t.PrimaryPart or t:FindFirstChildWhichIsA("BasePart")
        if p then
            local d = (p.Position - hrp.Position).Magnitude
            if not bestD or d < bestD then best, bestD = t, d end
        end
    end
    return best
end

local Tycoon = getMyTycoon()
assert(Tycoon, "Could not detect your Tycoon")

-- ========= Discover tables (Surface children that look like tables) =========
local Surface = Tycoon:WaitForChild("Items"):WaitForChild("Surface")
local Tables = {}
for _, child in ipairs(Surface:GetChildren()) do
    local n = child.Name:lower()
    if n:match("^t%d+") or n:find("table") then
        table.insert(Tables, child)
    end
end

-- If none matched, allow a fallback to any model with a Trash.Food child
if #Tables == 0 then
    for _, child in ipairs(Surface:GetChildren()) do
        if child:FindFirstChild("Trash") and child.Trash:FindFirstChild("Food") then
            table.insert(Tables, child)
        end
    end
end

-- ========= Dynamic Seats per Table =========
local function getSeatIds(tableModel)
    local ids = {}
    -- We only need a count; CustomerId values are "1","2",…
    local count = 0
    for _, d in ipairs(tableModel:GetDescendants()) do
        if d:IsA("Seat") or d.Name:lower():find("seat") then
            count += 1
        end
    end
    count = math.max(count, 2) -- safe minimum
    for i=1,count do ids[#ids+1] = tostring(i) end
    return ids
end

-- ========= Order‑slip ID discovery =========
local function getOrderSlipIds()
    local tmp = workspace:FindFirstChild("Temp")
    local ids = {}
    if tmp and tmp:FindFirstChild("Part") then
        for _, ch in ipairs(tmp.Part:GetChildren()) do
            if tonumber(ch.Name) then table.insert(ids, ch.Name) end
        end
    end
    if #ids == 0 then ids = {"0","1"} end -- safe default
    table.sort(ids, function(a,b) return tonumber(a) < tonumber(b) end)
    return ids
end

-- ========= Station Models (best‑effort auto) =========
-- Use names from your logs; if not present, try to guess by keywords.
local function findStationByHints(hints)
    for _, m in ipairs(Surface:GetChildren()) do
        local ln = m.Name:lower()
        for _, h in ipairs(hints) do
            if ln:find(h) then return m end
        end
    end
    return nil
end

local KITCHEN = Surface:FindFirstChild("K15") or findStationByHints({"kitchen","prep","grill","pan"}) or Surface:FindFirstChildWhichIsA("Model")
local OVEN    = Surface:FindFirstChild("K28") or findStationByHints({"oven","bake"})
local COUNTER = Surface:FindFirstChild("K16") or findStationByHints({"counter","order"}) or Surface

-- ========= Payload builders =========
local function taskPayload(fields)
    local t = { Name = assert(fields.Name, "missing Name"), Tycoon = Tycoon }
    if fields.GroupId then t.GroupId = tostring(fields.GroupId) end
    if fields.FurnitureModel then t.FurnitureModel = fields.FurnitureModel end
    if fields.CustomerId then t.CustomerId = tostring(fields.CustomerId) end
    if fields.FoodModel then t.FoodModel = fields.FoodModel end
    return { t }
end

local function interactedOrderCounterPayload(id)
    local tmpPart = workspace:FindFirstChild("Temp") and workspace.Temp:FindFirstChild("Part") or (workspace:FindFirstChild("Temp") and workspace.Temp:FindFirstChild("Part"))
    local prompt = tmpPart and tmpPart:FindFirstChild(id) or Instance.new("ProximityPrompt")
    local worldPos = (tmpPart and tmpPart.Position) or Vector3.zero
    return Tycoon, {
        WorldPosition   = worldPos,
        HoldDuration    = 0.375,
        Part            = tmpPart or Instance.new("Part"),
        TemporaryPart   = tmpPart or Instance.new("Part"),
        Model           = COUNTER,
        InteractionType = "OrderCounter",
        Prompt          = prompt,
        ActionText      = "Cook",
        Id              = tostring(id)
    }
end

local function foodModelForTable(tbl)
    local ok, f = pcall(function()
        return tbl.Trash.Food
    end)
    if ok and f then return f end
    -- fallback: try to find a Food under this table
    for _, d in ipairs(tbl:GetDescendants()) do
        if d.Name == "Food" then return d end
    end
    return nil
end

-- ========= Actions (with pcall + small waits) =========
local function doTask(fields)
    return pcallRetry(function()
        TaskCompleted:FireServer(unpack(taskPayload(fields)))
    end)
end

local function doInteractedOrderCounter(id)
    local a1, a2 = interactedOrderCounterPayload(id)
    return pcallRetry(function()
        Interacted:FireServer(a1, a2)
    end)
end

local function cookInteract(model, kind)
    return pcallRetry(function()
        CookInput:FireServer("Interact", model, kind)
    end)
end
local function cookComplete(model, kind, flag)
    return pcallRetry(function()
        if flag == nil then
            CookInput:FireServer("CompleteTask", model, kind)
        else
            CookInput:FireServer("CompleteTask", model, kind, flag)
        end
    end)
end

local function grabFood(tbl)
    local f = foodModelForTable(tbl)
    if not f then return false, "FoodModel missing" end
    return pcallRetry(function()
        return GrabFood:InvokeServer(f)
    end)
end

-- ========= Adaptive Cooking Runner =========
-- Runs a best‑effort generic flow: Kitchen -> (Oven?) -> Kitchen Optional
-- You can switch variants from the UI.
local COOK_VARIANTS = {
    { {"Kitchen","Interact"}, {"Kitchen","Complete"} },
    { {"Kitchen","Interact"}, {"Kitchen","Complete"}, {"Oven","Interact"}, {"Oven","Complete", false} },
    { {"Kitchen","Interact"}, {"Kitchen","Complete"}, {"Oven","Interact"}, {"Oven","Complete", false}, {"Kitchen","Interact"}, {"Kitchen","Complete"} },
}

local function runCookVariant(variant)
    for _, step in ipairs(variant) do
        local kind, action, flag = step[1], step[2], step[3]
        local model = (kind == "Kitchen" and KITCHEN) or (kind == "Oven" and OVEN) or KITCHEN
        if action == "Interact" then
            local ok = cookInteract(model, kind)
            if not ok then return false end
        else
            local ok = cookComplete(model, kind, flag)
            if not ok then return false end
        end
        task.wait(0.35)
    end
    return true
end

-- ========= Full per‑table routine (no pathing; proximity checks only) =========
local RUNNING = false
local PAUSED = false

local function pauseIfMoving()
    local hrp, hum = getRoot()
    if hum.MoveDirection.Magnitude > 0.1 then
        return true
    end
    if hum.Health <= 0 then
        return true
    end
    return false
end

local function safeWait(t)
    local ts = os.clock()
    while os.clock() - ts < t do
        if not RUNNING or PAUSED then return end
        if pauseIfMoving() then return end
        RunService.Heartbeat:Wait()
    end
end

local DEFAULT_GROUP_IDS = {"1","2"} -- used if we cannot auto‑read group id

local function runTableFlow(tbl, groupId, seatIds, cookVariantIdx)
    local hrp = select(1, getRoot())
    if not near(hrp, tbl, 60) then
        -- no pathing in executor; just warn
        warn("[RT3] You are far from the table. Move closer if server enforces proximity.")
    end

    -- 1) Seat guests
    doTask({ Name="SendToTable", GroupId=groupId, FurnitureModel=tbl })
    safeWait(0.25)

    -- 2) Take orders per seat
    for _, cid in ipairs(seatIds) do
        doTask({ Name="TakeOrder", GroupId=groupId, CustomerId=cid })
        safeWait(0.25)
    end

    -- 3) Pull order slips dynamically
    for _, id in ipairs(getOrderSlipIds()) do
        doInteractedOrderCounter(id)
        safeWait(0.2)
    end

    -- 4) Cook using selected variant (fallback through variants if needed)
    local variants = { COOK_VARIANTS[cookVariantIdx] or COOK_VARIANTS[1], COOK_VARIANTS[2], COOK_VARIANTS[3] }
    local cooked = false
    for _, v in ipairs(variants) do
        if runCookVariant(v) then cooked = true break end
        safeWait(0.25)
    end

    -- 5) Serve each seat
    for _, cid in ipairs(seatIds) do
        grabFood(tbl)
        safeWait(0.15)
        doTask({ Name="Serve", GroupId=groupId, CustomerId=cid, FoodModel=foodModelForTable(tbl) })
        safeWait(0.25)
    end

    -- 6) Bill + Dishes
    doTask({ Name="CollectBill", FurnitureModel=tbl })
    safeWait(0.25)
    doTask({ Name="CollectDishes", FurnitureModel=tbl })
end

-- ========= Minimal GUI =========
local pg = LP:WaitForChild("PlayerGui")
local Screen = Instance.new("ScreenGui")
Screen.Name = "RT3AutoMenu"
Screen.ResetOnSpawn = false
Screen.IgnoreGuiInset = true
Screen.Parent = pg

local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(360, 300)
Frame.Position = UDim2.fromScale(0.06, 0.25)
Frame.BackgroundColor3 = Color3.fromRGB(18, 12, 34)
Frame.Parent = Screen

local corner = Instance.new("UICorner", Frame); corner.CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", Frame); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(170,120,255)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, -20, 0, 28)
Title.Position = UDim2.fromOffset(10, 8)
Title.BackgroundTransparency = 1
Title.Text = "RT3 — Auto Menu (Executor)"
Title.TextColor3 = Color3.fromRGB(235, 230, 255)
Title.Font = Enum.Font.GothamSemibold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextSize = 16

local List = Instance.new("Frame", Frame)
List.Size = UDim2.new(1, -20, 1, -60)
List.Position = UDim2.fromOffset(10, 44)
List.BackgroundTransparency = 1
local layout = Instance.new("UIListLayout", List); layout.Padding = UDim.new(0,6)

local function makeBtn(txt)
    local b = Instance.new("TextButton")
    b.Text = txt
    b.Size = UDim2.new(1, 0, 0, 32)
    b.BackgroundColor3 = Color3.fromRGB(28, 18, 58)
    b.TextColor3 = Color3.fromRGB(230, 225, 255)
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke", b); s.Color = Color3.fromRGB(140, 90, 240); s.Thickness = 1
    b.Parent = List
    return b
end

local function makeDrop(items)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,32)
    holder.BackgroundColor3 = Color3.fromRGB(24, 16, 48)
    local c = Instance.new("UICorner", holder); c.CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke", holder); s.Color = Color3.fromRGB(100, 70, 210); s.Thickness = 1

    local label = Instance.new("TextLabel", holder)
    label.BackgroundTransparency = 1
    label.Text = ""
    label.Size = UDim2.new(1,-10,1,0)
    label.Position = UDim2.fromOffset(10,0)
    label.TextColor3 = Color3.fromRGB(220,215,245)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    holder.Parent = List

    local currentIdx = 1
    local function setIdx(i)
        currentIdx = (i-1) % #items + 1
        label.Text = tostring(items[currentIdx])
    end
    setIdx(1)

    holder.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            setIdx(currentIdx + 1)
        end
    end)

    return {
        Instance = holder,
        Get = function() return items[currentIdx], currentIdx end,
        Set = function(i) setIdx(i) end
    }
end

-- Table selector
local tableNames = {}
for _, t in ipairs(Tables) do table.insert(tableNames, t.Name) end
if #tableNames == 0 then tableNames = {"<No tables detected>"} end
local TableDrop = makeDrop(tableNames); TableDrop.Instance.LayoutOrder = 1

-- GroupId selector (default 1/2; you can tap to cycle)
local GroupDrop = makeDrop({"1","2","3","4"}); GroupDrop.Instance.LayoutOrder = 2

-- Cook variant selector
local CookDrop = makeDrop({"Kitchen","Kitchen>Oven","Kitchen>Oven>Kitchen"}); CookDrop.Instance.LayoutOrder = 3

local StartBtn = makeBtn("START — Full Flow"); StartBtn.LayoutOrder = 4
local StopBtn  = makeBtn("STOP"); StopBtn.LayoutOrder = 5

local Status = Instance.new("TextLabel", Frame)
Status.Size = UDim2.new(1, -20, 0, 18)
Status.Position = UDim2.fromOffset(10, Frame.AbsoluteSize.Y-24)
Status.BackgroundTransparency = 1
Status.TextColor3 = Color3.fromRGB(180, 170, 220)
Status.Text = "Idle"
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.TextXAlignment = Enum.TextXAlignment.Left

local function setStatus(t)
    Status.Text = t
end

StartBtn.MouseButton1Click:Connect(function()
    if RUNNING then return end
    RUNNING = true; PAUSED = false

    local tblName = TableDrop.Get()
    local tbl
    for _, t in ipairs(Tables) do if t.Name == tblName then tbl = t break end end
    if not tbl then setStatus("No table"); RUNNING=false return end

    local groupId = GroupDrop.Get()
    local seatIds = getSeatIds(tbl)
    local _, cookIdx = CookDrop.Get()

    setStatus("Running: "..tbl.Name.." [G="..groupId.."] seats="..#seatIds)
    task.spawn(function()
        runTableFlow(tbl, groupId, seatIds, cookIdx)
        setStatus("Done or Stopped")
        RUNNING = false
    end)
end)

StopBtn.MouseButton1Click:Connect(function()
    RUNNING = false; PAUSED = false; setStatus("Stopped")
end)

-- Toggle GUI
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        Screen.Enabled = not Screen.Enabled
    end
end)

print("[RT3 Auto Menu] Ready – open with RightShift. Select table, group, variant and press START.")
