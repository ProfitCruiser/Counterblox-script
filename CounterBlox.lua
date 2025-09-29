--====================================================--
-- AURORA PANEL — ProfitCruiser (fixed key→panel flow)
-- Full redesign: Compact 2-col layout + sections + gating
-- Clean shell prepared for upcoming Autofarm module
--====================================================--

--// Services
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local Players           = game:GetService("Players")
local GuiService        = game:GetService("GuiService")
local HttpService       = game:GetService("HttpService")
local TextService       = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- forward-declare Root so click handlers can access it before it's created
local Root

pcall(function()
    GuiService.AutoSelectGuiEnabled = false
    GuiService.SelectedObject = nil
end)

--// Gate / links
local KEY_CHECK_URL = "https://pastebin.com/raw/QgqAaumb"
local GET_KEY_URL   = "https://pastebin.com/raw/QgqAaumb"
local DISCORD_URL   = "https://discord.gg/Pgn4NMWDH8"

--// Theme
local T = {
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

local function safeParent()
    local ok, ui = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
    return (ok and ui) or LocalPlayer:WaitForChild("PlayerGui")
end

--// Utils
local function corner(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=o end
local function stroke(o,col,th,tr) local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=th or 1; s.Transparency=tr or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=o end
local function pad(o,p) local x=Instance.new("UIPadding"); x.PaddingTop=UDim.new(0,p); x.PaddingBottom=UDim.new(0,p); x.PaddingLeft=UDim.new(0,p); x.PaddingRight=UDim.new(0,p); x.Parent=o end
local function trim(s) s=tostring(s or ""):gsub("\r",""):gsub("\n",""):gsub("%s+$",""):gsub("^%s+",""); return s end
local function setInteractable(frame, on)
    for _,v in ipairs(frame:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            v.TextTransparency = on and 0 or 0.45
            if v:IsA("TextButton") then v.AutoButtonColor = on end
        elseif v:IsA("Frame") then
            v.BackgroundColor3 = on and v.BackgroundColor3 or T.Ink
        end
    end
    frame.Active = on
end

--==================== ACCESS OVERLAY ====================--
local Blur = Instance.new("BlurEffect"); Blur.Enabled=false; Blur.Size=0; Blur.Parent=Lighting

local Gate = Instance.new("ScreenGui")
Gate.Name="PC_Gate"; Gate.IgnoreGuiInset=true; Gate.ResetOnSpawn=false; Gate.ZIndexBehavior=Enum.ZIndexBehavior.Global
Gate.DisplayOrder=100; Gate.Parent=safeParent()

local Dim = Instance.new("Frame", Gate)
Dim.BackgroundColor3=Color3.new(0,0,0); Dim.BackgroundTransparency=0.35; Dim.Size=UDim2.fromScale(1,1)

local Card = Instance.new("Frame", Gate)
Card.Size=UDim2.fromOffset(600, 360); Card.AnchorPoint=Vector2.new(0.5,0.5); Card.Position=UDim2.fromScale(0.5,0.5)
Card.BackgroundColor3=T.Card; stroke(Card,T.Stroke,1,0.45); corner(Card,18); pad(Card,22)

local CardLayout = Instance.new("UIListLayout", Card)
CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
CardLayout.Padding   = UDim.new(0, 12)

local Hero = Instance.new("Frame", Card)
Hero.Name = "Hero"; Hero.Size = UDim2.new(1,0,0,128); Hero.LayoutOrder = 1; Hero.BackgroundColor3 = T.Accent; Hero.BackgroundTransparency = 0.7
Hero.ZIndex = 2; Hero.ClipsDescendants = true; corner(Hero,16); stroke(Hero,T.Stroke,1,0.28)

local heroGradient = Instance.new("UIGradient", Hero)
heroGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, T.Accent),
    ColorSequenceKeypoint.new(1, T.Neon)
})
heroGradient.Rotation = 28
heroGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.22),
    NumberSequenceKeypoint.new(1, 0.32)
})

local heroPad = Instance.new("UIPadding", Hero)
heroPad.PaddingTop = UDim.new(0, 18); heroPad.PaddingBottom = UDim.new(0, 18)
heroPad.PaddingLeft = UDim.new(0, 20); heroPad.PaddingRight = UDim.new(0, 20)

local heroLayout = Instance.new("UIListLayout", Hero)
heroLayout.SortOrder = Enum.SortOrder.LayoutOrder; heroLayout.Padding = UDim.new(0, 8)

local Pill = Instance.new("TextLabel", Hero)
Pill.BackgroundTransparency = 0.2; Pill.BackgroundColor3 = T.Ink; Pill.LayoutOrder = 1
Pill.Size = UDim2.new(0, 150, 0, 26); Pill.Font = Enum.Font.GothamBold; Pill.TextSize = 13
Pill.Text = "ACCESS PASS"; Pill.TextColor3 = T.Text; Pill.TextXAlignment = Enum.TextXAlignment.Center
Pill.ZIndex = 3
corner(Pill, 13); stroke(Pill, T.Stroke, 1, 0.5)

local Title = Instance.new("TextLabel", Hero)
Title.BackgroundTransparency=1; Title.Text="ProfitCruiser — Access Portal"; Title.Font=Enum.Font.GothamBlack; Title.TextSize=24; Title.TextColor3=T.Text
Title.Size=UDim2.new(1,0,0,34); Title.TextXAlignment=Enum.TextXAlignment.Left; Title.LayoutOrder = 2; Title.ZIndex = 3

local Hint = Instance.new("TextLabel", Hero)
Hint.BackgroundTransparency=1; Hint.Text="Paste your private key to unlock Aurora. Grab a new key or meet the crew on Discord for instant drops."; Hint.Font=Enum.Font.Gotham
Hint.TextSize=14; Hint.TextColor3=T.Text; Hint.TextWrapped=true; Hint.TextXAlignment=Enum.TextXAlignment.Left; Hint.TextYAlignment=Enum.TextYAlignment.Top
Hint.Size=UDim2.new(1,0,0,44); Hint.LayoutOrder = 3; Hint.ZIndex = 3

local Features = Instance.new("TextLabel", Hero)
Features.BackgroundTransparency = 1; Features.Text = "⚡ Rapid updates    🛡️ Anti-ban shielding    🎯 Elite aim assist"
Features.Font = Enum.Font.Gotham; Features.TextSize = 13; Features.TextColor3 = T.Subtle; Features.TextXAlignment = Enum.TextXAlignment.Left
Features.Size = UDim2.new(1,0,0,22); Features.LayoutOrder = 4; Features.ZIndex = 3

local InputSection = Instance.new("Frame", Card)
InputSection.BackgroundColor3 = T.Panel; InputSection.BackgroundTransparency = 0.05; InputSection.Size = UDim2.new(1,0,0,120)
InputSection.LayoutOrder = 2; corner(InputSection,14); stroke(InputSection,T.Stroke,1,0.28)

local inputPad = Instance.new("UIPadding", InputSection)
inputPad.PaddingTop = UDim.new(0, 14); inputPad.PaddingBottom = UDim.new(0, 14)
inputPad.PaddingLeft = UDim.new(0, 18); inputPad.PaddingRight = UDim.new(0, 18)

local inputLayout = Instance.new("UIListLayout", InputSection)
inputLayout.SortOrder = Enum.SortOrder.LayoutOrder; inputLayout.Padding = UDim.new(0, 8)

local KeyLabel = Instance.new("TextLabel", InputSection)
KeyLabel.BackgroundTransparency = 1; KeyLabel.Text = "Master Key"; KeyLabel.Font = Enum.Font.GothamMedium; KeyLabel.TextSize = 15
KeyLabel.TextColor3 = T.Text; KeyLabel.TextXAlignment = Enum.TextXAlignment.Left; KeyLabel.Size = UDim2.new(1,0,0,22)
KeyLabel.LayoutOrder = 1

local KeyBox = Instance.new("TextBox", InputSection)
KeyBox.Size=UDim2.new(1,0,0,40); KeyBox.Text=""; KeyBox.PlaceholderText="Paste key or drop to auto-fill…"
KeyBox.ClearTextOnFocus=false; KeyBox.Font=Enum.Font.Gotham; KeyBox.TextSize=16; KeyBox.TextColor3=T.Text
KeyBox.BackgroundColor3=T.Ink; stroke(KeyBox,T.Stroke,1,0.35); corner(KeyBox,12); KeyBox.LayoutOrder = 2

local KeyNote = Instance.new("TextLabel", InputSection)
KeyNote.BackgroundTransparency = 1; KeyNote.Text = "Keys rotate fast — confirm before the cycle resets. Discord pings fire instantly."
KeyNote.Font = Enum.Font.Gotham; KeyNote.TextSize = 12; KeyNote.TextColor3 = T.Subtle; KeyNote.TextWrapped = true
KeyNote.TextXAlignment = Enum.TextXAlignment.Left; KeyNote.TextYAlignment = Enum.TextYAlignment.Top
KeyNote.Size = UDim2.new(1,0,0,32); KeyNote.LayoutOrder = 3

local Divider = Instance.new("Frame", Card)
Divider.BackgroundColor3 = T.Stroke; Divider.BackgroundTransparency = 0.55; Divider.Size = UDim2.new(1,0,0,1); Divider.LayoutOrder = 3

local Row = Instance.new("Frame", Card)
Row.BackgroundTransparency=1; Row.Size=UDim2.new(1,0,0,48); Row.LayoutOrder = 4

local rowLayout = Instance.new("UIListLayout", Row)
rowLayout.FillDirection = Enum.FillDirection.Horizontal; rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center; rowLayout.Padding = UDim.new(0, 14)

local function btn(text, style)
    local b=Instance.new("TextButton", Row); b.Text=text; b.Font=Enum.Font.GothamMedium; b.TextSize=15; b.TextColor3=T.Text
    b.AutoButtonColor=false; b.Size=UDim2.new(0,172,0,42); b.LayoutOrder = style == "primary" and 3 or 1
    local isPrimary = style == "primary"
    local baseColor = isPrimary and T.Accent or T.Ink
    local hoverColor = isPrimary and T.Neon or Color3.fromRGB(58, 52, 88)
    b.BackgroundColor3=baseColor; stroke(b,T.Stroke,1,0.35); corner(b,12)
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=hoverColor}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=baseColor}):Play() end)
    return b
end

local GetKey = btn("Get Key Link")
local Discord = btn("Join Discord")
local Confirm = btn("Unlock Panel", "primary")

local Status = Instance.new("TextLabel", Card)
Status.BackgroundColor3 = T.Ink; Status.BackgroundTransparency = 0.6; Status.Text=""; Status.Font=Enum.Font.Gotham
Status.TextSize=13; Status.TextColor3=T.Subtle; Status.Size=UDim2.new(1,0,0,28); Status.LayoutOrder = 5
Status.TextXAlignment=Enum.TextXAlignment.Center; Status.TextYAlignment = Enum.TextYAlignment.Center; corner(Status,12)

local function updateStatus(text, color)
    Status.Text = text
    Status.TextColor3 = color or T.Subtle
end

updateStatus("Paste your key to unlock ProfitCruiser.")

-- Success overlay in its own GUI so it survives hiding Gate
local SuccessGui = Instance.new("ScreenGui")
SuccessGui.Name = "PC_Success"; SuccessGui.IgnoreGuiInset = true; SuccessGui.ResetOnSpawn = false
SuccessGui.ZIndexBehavior = Enum.ZIndexBehavior.Global; SuccessGui.DisplayOrder = 110
SuccessGui.Parent = safeParent()

local Success = Instance.new("Frame", SuccessGui)
Success.Visible=false; Success.Size=UDim2.fromScale(1,1); Success.BackgroundTransparency=1
local Center = Instance.new("Frame", Success)
Center.Size=UDim2.fromOffset(420,220); Center.AnchorPoint=Vector2.new(0.5,0.5); Center.Position=UDim2.fromScale(0.5,0.5); Center.BackgroundColor3=T.Card
corner(Center,16); stroke(Center,T.Good,2,0)
local GG = Instance.new("TextLabel", Center)
GG.BackgroundTransparency=1; GG.Size=UDim2.fromScale(1,1); GG.Text="ACCESS GRANTED ✨"; GG.TextColor3=T.Good; GG.Font=Enum.Font.GothamBold; GG.TextSize=28

-- FLAG: only allow reveal of Root after overlay finished
local allowReveal = false

local function fetchRemoteKey()
    local ok,res=pcall(game.HttpGet,game,KEY_CHECK_URL)
    if not ok then return nil,res end
    local cleaned=trim(res); if #cleaned==0 then return nil,"empty" end
    return cleaned
end

GetKey.MouseButton1Click:Connect(function()
    if typeof(setclipboard)=="function" then
        setclipboard(GET_KEY_URL)
        updateStatus("Key link copied to clipboard.", T.Neon)
    else
        updateStatus("Key link: "..GET_KEY_URL)
    end
end)
Discord.MouseButton1Click:Connect(function()
    if typeof(setclipboard)=="function" then setclipboard(DISCORD_URL) end
    updateStatus("Discord invite copied — we'll see you inside!", T.Neon)
    if syn and syn.request then pcall(function() syn.request({Url=DISCORD_URL,Method="GET"}) end) end
end)

-- new showGranted supports callback after hide
local function showGranted(seconds, after)
    Success.Visible = true
    task.delay(seconds or 2.0, function()
        Success.Visible = false
        if after then pcall(after) end
    end)
end

Confirm.MouseButton1Click:Connect(function()
    updateStatus("Checking key…", T.Text)
    local expected,err = fetchRemoteKey()
    if not expected then updateStatus("Fetch failed: "..tostring(err or ""), T.Warn) return end

    if trim(KeyBox.Text) == expected then
        updateStatus("Accepted!", T.Good)

        -- Immediately hide the gate UI so the key box is gone
        Gate.Enabled = false

        -- Ensure Root is hidden while we show the success overlay
        if Root then Root.Visible = false end

        -- Show blur and keep it while overlay is visible
        Blur.Enabled = true
        TweenService:Create(Blur, TweenInfo.new(0.2), {Size = 8}):Play()

        -- Show the granted overlay for 2s, then remove blur and reveal the panel
        showGranted(2.0, function()
            -- animate blur out
            TweenService:Create(Blur, TweenInfo.new(0.2), {Size = 0}):Play()
            task.delay(0.2, function() Blur.Enabled = false end)

            -- mark that reveal is allowed and show Root
            allowReveal = true
            if Root then Root.Visible = true end
        end)

    else
        updateStatus("Wrong key.", T.Warn)
    end
end)

Gate.Enabled=true
Blur.Enabled=true; TweenService:Create(Blur,TweenInfo.new(0.2),{Size=8}):Play()

--==================== MAIN APP ====================--
local App = Instance.new("ScreenGui")
App.Name="AuroraPanel"; App.IgnoreGuiInset=true; App.ResetOnSpawn=false; App.ZIndexBehavior=Enum.ZIndexBehavior.Global
App.DisplayOrder=50; App.Parent=safeParent()

Root = Instance.new("Frame", App)
Root.Size=UDim2.fromOffset(980, 600); Root.AnchorPoint=Vector2.new(0.5,0.5); Root.Position=UDim2.fromScale(0.5,0.5)
Root.BackgroundColor3=T.Card; corner(Root,16); stroke(Root,T.Stroke,1,0.45); pad(Root,12)
Root.Visible=false

local PanelScale = Instance.new("UIScale", Root)
PanelScale.Scale = 1

local Top = Instance.new("Frame", Root)
Top.Size=UDim2.new(1, -16, 0, 46); Top.Position=UDim2.new(0,8,0,8); Top.BackgroundColor3=T.Panel; corner(Top,12); stroke(Top,T.Stroke,1,0.45); pad(Top,10)

local TitleLbl = Instance.new("TextLabel", Top)
TitleLbl.Size=UDim2.new(0.6,0,1,0); TitleLbl.BackgroundTransparency=1; TitleLbl.TextXAlignment=Enum.TextXAlignment.Left
TitleLbl.Text="ProfitCruiser — Aurora Panel"; TitleLbl.Font=Enum.Font.GothamBold; TitleLbl.TextSize=18; TitleLbl.TextColor3=T.Text

-- drag
local draggingEnabled = true
local dragging,rel=false,Vector2.zero
Top.InputBegan:Connect(function(i) if draggingEnabled and i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; rel=Root.AbsolutePosition-UserInputService:GetMouseLocation() end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
RunService.RenderStepped:Connect(function()
    if dragging then
        local vp=Camera.ViewportSize; local m=UserInputService:GetMouseLocation()
        local nx=math.clamp(m.X+rel.X,8,vp.X-Root.AbsoluteSize.X-8); local ny=math.clamp(m.Y+rel.Y,8,vp.Y-Root.AbsoluteSize.Y-8)
        Root.Position=UDim2.fromOffset(nx,ny)
    end
end)

-- sidebar
local Side = Instance.new("Frame", Root)
Side.Size=UDim2.new(0, 210, 1, -70); Side.Position=UDim2.new(0,8,0,62)
Side.BackgroundColor3=T.Panel; corner(Side,12); stroke(Side,T.Stroke,1,0.45); pad(Side,8)
-- ensure tab buttons stack vertically (fix: only Aimbot showing)
local SideList = Instance.new("UIListLayout", Side)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Padding   = UDim.new(0,8)

local Content = Instance.new("Frame", Root)
Content.Size=UDim2.new(1, -234, 1, -70); Content.Position=UDim2.new(0, 226, 0, 62); Content.BackgroundTransparency=1
Content.ClipsDescendants = true

-- two-column grid inside pages
local function newPage(name)
    local p = Instance.new("ScrollingFrame", Content)
    p.Name = name
    p.Size = UDim2.fromScale(1, 1)
    p.Visible = false
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ClipsDescendants = true
    p.Active = true
    p.ScrollingEnabled = true
    p.ScrollBarThickness = 4
    p.ScrollBarImageColor3 = T.Subtle
    p.ScrollBarImageTransparency = 0.15
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.ScrollingDirection = Enum.ScrollingDirection.Y

    local padding = Instance.new("UIPadding", p)
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 12)

    local grid = Instance.new("UIGridLayout", p)
    grid.CellPadding = UDim2.new(0, 12, 0, 12)
    grid.CellSize = UDim2.new(0.5, -6, 0, 64)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Left

    local function syncCanvas()
        local contentY = grid.AbsoluteContentSize.Y
        local viewportY = p.AbsoluteSize.Y
        local paddingY = padding.PaddingTop.Offset + padding.PaddingBottom.Offset
        local totalY = math.max(contentY + paddingY, viewportY)
        p.CanvasSize = UDim2.new(0, 0, 0, totalY)

        -- clamp current scroll position so we can always scroll back up
        local maxScroll = math.max(0, totalY - viewportY)
        local current = p.CanvasPosition
        if current.Y > maxScroll or current.Y < 0 then
            p.CanvasPosition = Vector2.new(current.X, math.clamp(current.Y, 0, maxScroll))
        end
    end

    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(syncCanvas)
    p:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncCanvas)
    task.defer(syncCanvas)

    return p
end

local function tabButton(text, page)
    local b=Instance.new("TextButton", Side)
    b.Size=UDim2.new(1,0,0,40); b.Text=text; b.Font=Enum.Font.Gotham; b.TextSize=15; b.TextColor3=T.Text
    b.BackgroundColor3=T.Ink; b.AutoButtonColor=false; corner(b,10); stroke(b,T.Stroke,1,0.35)
    local bar=Instance.new("Frame", b); bar.Size=UDim2.new(0,0,1,0); bar.Position=UDim2.new(0,0,0,0); bar.BackgroundColor3=T.Neon; corner(bar,10)
    b.MouseButton1Click:Connect(function()
        for _,c in ipairs(Content:GetChildren()) do
            if c:IsA("GuiObject") then
                c.Visible = false
            end
        end
        for _,x in ipairs(Side:GetChildren()) do
            if x:IsA("TextButton") then
                TweenService:Create(x,TweenInfo.new(0.12),{BackgroundColor3=T.Ink}):Play()
                local f=x:FindFirstChildOfClass("Frame"); if f then TweenService:Create(f,TweenInfo.new(0.12),{Size=UDim2.new(0,0,1,0)}):Play() end
            end
        end
        page.Visible=true
        if page:IsA("ScrollingFrame") then page.CanvasPosition = Vector2.new(0,0) end
        TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=T.Accent}):Play()
        TweenService:Create(bar,TweenInfo.new(0.12),{Size=UDim2.new(0,4,1,0)}):Play()
    end)
    return b
end

-- floating tooltip bubble for control descriptions
local Tooltip = Instance.new("Frame", App)
Tooltip.Name = "ControlTooltip"
Tooltip.Visible = false
Tooltip.Active = false
Tooltip.ZIndex = 200
Tooltip.BackgroundColor3 = T.Panel
Tooltip.BackgroundTransparency = 0.05
Tooltip.Size = UDim2.fromOffset(220, 64)
Tooltip.ClipsDescendants = false
corner(Tooltip, 10)
stroke(Tooltip, T.Stroke, 1, 0.2)

local tooltipPad = Instance.new("UIPadding", Tooltip)
tooltipPad.PaddingTop = UDim.new(0, 8)
tooltipPad.PaddingBottom = UDim.new(0, 8)
tooltipPad.PaddingLeft = UDim.new(0, 12)
tooltipPad.PaddingRight = UDim.new(0, 12)

local tooltipText = Instance.new("TextLabel", Tooltip)
tooltipText.BackgroundTransparency = 1
tooltipText.Size = UDim2.new(1, 0, 1, 0)
tooltipText.Font = Enum.Font.Gotham
tooltipText.TextSize = 13
tooltipText.TextColor3 = T.Text
tooltipText.TextWrapped = true
tooltipText.TextXAlignment = Enum.TextXAlignment.Left
tooltipText.TextYAlignment = Enum.TextYAlignment.Top
tooltipText.ZIndex = Tooltip.ZIndex + 1

local tooltipOwner = nil
local tooltipBounds = Vector2.new(Tooltip.Size.X.Offset, Tooltip.Size.Y.Offset)

local function updateTooltipPosition(x, y)
    local vp = Camera.ViewportSize
    local width = tooltipBounds.X
    local height = tooltipBounds.Y
    local px = math.clamp(x + 16, 8, vp.X - width - 8)
    local py = math.clamp(y + 20, 8, vp.Y - height - 8)
    Tooltip.Position = UDim2.fromOffset(px, py)
end

local function openTooltip(owner, text)
    tooltipOwner = owner
    tooltipText.Text = text
    local bounds = TextService:GetTextSize(text, tooltipText.TextSize, tooltipText.Font, Vector2.new(280, 800))
    local width = math.clamp(bounds.X + 24, 160, 320)
    local height = math.clamp(bounds.Y + 16, 32, 220)
    tooltipBounds = Vector2.new(width, height)
    Tooltip.Size = UDim2.fromOffset(width, height)
    Tooltip.Visible = true
    local mouse = UserInputService:GetMouseLocation()
    updateTooltipPosition(mouse.X, mouse.Y)
end

local function closeTooltip(owner)
    if tooltipOwner ~= owner then return end
    tooltipOwner = nil
    Tooltip.Visible = false
end

local function trackTooltip(owner, x, y)
    if tooltipOwner ~= owner then return end
    updateTooltipPosition(x, y)
end

Root:GetPropertyChangedSignal("Visible"):Connect(function()
    if not Root.Visible then
        tooltipOwner = nil
        Tooltip.Visible = false
    end
end)

-- Controls factory (compact, reused)
local function rowBase(parent, name, desc)
    local infoText = trim(desc or "")
    local hasDesc = infoText ~= ""
    local r = Instance.new("Frame", parent)
    r.BackgroundColor3 = T.Card
    r.Size = UDim2.new(0.5, -6, 0, 64)
    corner(r, 10)
    stroke(r, T.Stroke, 1, 0.25)

    local labelOffset = hasDesc and 54 or 18
    local labelWidth = hasDesc and -210 or -176

    local l = Instance.new("TextLabel", r)
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0, labelOffset, 0, 0)
    l.Size = UDim2.new(1, labelWidth, 1, 0)
    l.Text = name
    l.TextColor3 = T.Text
    l.Font = Enum.Font.Gotham
    l.TextSize = 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextWrapped = true

    if hasDesc then
        local infoButton = Instance.new("TextButton", r)
        infoButton.Name = "Info"
        infoButton.Size = UDim2.fromOffset(26, 26)
        infoButton.Position = UDim2.new(0, 18, 0.5, -13)
        infoButton.BackgroundColor3 = T.Ink
        infoButton.AutoButtonColor = false
        infoButton.Text = "?"
        infoButton.Font = Enum.Font.GothamBold
        infoButton.TextSize = 16
        infoButton.TextColor3 = T.Subtle
        infoButton.ZIndex = 3
        corner(infoButton, 13)
        stroke(infoButton, T.Stroke, 1, 0.45)

        local baseColor = infoButton.BackgroundColor3
        local baseText = infoButton.TextColor3

        infoButton.MouseEnter:Connect(function()
            TweenService:Create(infoButton, TweenInfo.new(0.12), {
                BackgroundColor3 = T.Accent,
                TextColor3 = T.Text,
            }):Play()
            openTooltip(infoButton, infoText)
        end)

        infoButton.MouseLeave:Connect(function()
            TweenService:Create(infoButton, TweenInfo.new(0.12), {
                BackgroundColor3 = baseColor,
                TextColor3 = baseText,
            }):Play()
            closeTooltip(infoButton)
        end)

        infoButton.MouseButton1Click:Connect(function()
            openTooltip(infoButton, infoText)
        end)

        infoButton.MouseMoved:Connect(function(x, y)
            trackTooltip(infoButton, x, y)
        end)
    end

    return r, l
end

local function mkToggle(parent, name, default, cb, desc)
    local r,_=rowBase(parent,name,desc)
    local sw=Instance.new("Frame", r); sw.Size=UDim2.new(0,68,0,28); sw.Position=UDim2.new(1,-84,0.5,-14); sw.BackgroundColor3=T.Ink; corner(sw,16); stroke(sw,T.Stroke,1,0.35)
    local k=Instance.new("Frame", sw); k.Size=UDim2.new(0,24,0,24); k.Position=UDim2.new(0,2,0.5,-12); k.BackgroundColor3=Color3.fromRGB(235,235,245); corner(k,12)
    local state = default
    local function set(v)
        state=v
        TweenService:Create(k,TweenInfo.new(0.12),{Position=v and UDim2.new(1,-26,0.5,-12) or UDim2.new(0,2,0.5,-12)}):Play()
        TweenService:Create(sw,TweenInfo.new(0.12),{BackgroundColor3=v and T.Neon or T.Ink}):Play()
        if cb then cb(v,r) end
    end
    sw.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then set(not state) end end)
    set(state)
    return {Row=r, Set=set, Get=function() return state end}
end

local function mkSlider(parent, name, min, max, default, cb, unit, desc)
    local r,l=rowBase(parent,name,desc)
    local hasDesc = trim(desc or "") ~= ""
    local sliderLeft = hasDesc and 54 or 18
    local valueWidth = 110
    local rightPadding = 28

    l.Position = UDim2.new(0, sliderLeft, 0, 6)
    l.Size = UDim2.new(1, -(sliderLeft + valueWidth + rightPadding), 0, 26)
    l.TextYAlignment = Enum.TextYAlignment.Top

    local v=Instance.new("TextLabel", r); v.BackgroundTransparency=1; v.Size=UDim2.new(0,valueWidth,0,24); v.Position=UDim2.new(1,-valueWidth-18,0,6)
    v.Text=""; v.TextColor3=T.Subtle; v.Font=Enum.Font.Gotham; v.TextSize=14; v.TextXAlignment=Enum.TextXAlignment.Right
    v.TextYAlignment = Enum.TextYAlignment.Top

    local bar=Instance.new("Frame", r); bar.Size=UDim2.new(1, -(sliderLeft + valueWidth + rightPadding), 0, 6); bar.Position=UDim2.new(0,sliderLeft,0,38); bar.BackgroundColor3=T.Ink; corner(bar,4)
    local fill=Instance.new("Frame", bar); fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=T.Neon; corner(fill,4)

    local val=math.clamp(default or min, min, max)
    local function render()
        local a=(val-min)/(max-min)
        fill.Size=UDim2.new(a,0,1,0)
        local u = unit and (" "..unit) or ""
        v.Text = (math.floor(val*100+0.5)/100)..u
    end
    local dragging=false
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local m=UserInputService:GetMouseLocation().X; local x=bar.AbsolutePosition.X; local w=bar.AbsoluteSize.X
            local a=math.clamp((m-x)/w,0,1); val=min + a*(max-min); render(); if cb then cb(val,r) end
        end
    end)
    render()
    return {Row=r, Set=function(x) val=math.clamp(x,min,max); render(); if cb then cb(val,r) end end, Get=function() return val end}
end

-- simple button control (used for Kill Menu)
local function mkButton(parent, name, onClick, opts, desc)
    local r,_ = rowBase(parent, name, desc)
    -- make the label take full width, then place a button pill on the right
    local btn = Instance.new("TextButton", r)
    btn.Size = UDim2.new(0, 120, 0, 30)
    btn.Position = UDim2.new(1, -132, 0.5, -15)
    opts = opts or {}
    local danger = opts.danger
    local buttonText = opts.buttonText or (danger and "Kill Menu" or "Run")
    local baseColor = opts.backgroundColor or (danger and Color3.fromRGB(170, 60, 70) or T.Ink)
    local hoverColor = opts.hoverColor or (danger and Color3.fromRGB(200, 75, 85) or T.Accent)
    local textColor = opts.textColor or (danger and Color3.fromRGB(255,235,235) or T.Text)
    btn.Text = buttonText
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.TextColor3 = textColor
    btn.BackgroundColor3 = baseColor
    btn.AutoButtonColor = false
    corner(btn, 10)
    stroke(btn, (danger and Color3.fromRGB(200,80,90)) or opts.strokeColor or T.Stroke, 1, 0.35)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = baseColor}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if onClick then onClick(r) end
    end)
    return {Row=r, Button=btn}
end

local function mkCycle(parent, name, options, default, cb, desc)
    local r,_ = rowBase(parent, name, desc)
    local btn = Instance.new("TextButton", r)
    btn.Size = UDim2.new(0, 120, 0, 30)
    btn.Position = UDim2.new(1, -132, 0.5, -15)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.TextColor3 = T.Text
    btn.BackgroundColor3 = T.Ink
    btn.AutoButtonColor = false
    corner(btn, 10)
    stroke(btn, T.Stroke, 1, 0.35)

    local normalized = {}
    for i,opt in ipairs(options) do
        if typeof(opt) == "table" then
            normalized[i] = {
                label = opt.label or opt.text or tostring(opt.value),
                value = opt.value,
            }
        else
            normalized[i] = {label = tostring(opt), value = opt}
        end
    end

    local function findIndexByValue(val)
        for i,opt in ipairs(normalized) do
            if opt.value == val then return i end
        end
        return nil
    end

    local idx = 1
    if default ~= nil then
        if typeof(default) == "number" and normalized[default] then
            idx = default
        else
            idx = findIndexByValue(default) or idx
        end
    end

    local function apply(index)
        if #normalized == 0 then return end
        idx = ((index - 1) % #normalized) + 1
        local opt = normalized[idx]
        btn.Text = opt.label
        if cb then cb(opt.value, r) end
    end

    btn.MouseButton1Click:Connect(function()
        apply(idx + 1)
    end)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = T.Accent}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = T.Ink}):Play()
    end)

    apply(idx)

    return {
        Row = r,
        Set = function(value)
            local targetIndex
            if typeof(value) == "number" and normalized[value] then
                targetIndex = value
            else
                targetIndex = findIndexByValue(value)
            end
            if targetIndex then
                apply(targetIndex)
            end
        end,
        Get = function()
            if normalized[idx] then return normalized[idx].value end
        end,
    }
end

--==================== AUTOFARM STATE ====================--
local AutoFarm = {
    Enabled = false,
    Status = "Idle",
    StatusLabel = nil,
}

local function setAutoFarmStatus(text, color)
    AutoFarm.Status = text or AutoFarm.Status
    local label = AutoFarm.StatusLabel
    if label then
        label.Text = AutoFarm.Status
        if color and label.TextColor3 ~= color then
            label.TextColor3 = color
        elseif not color then
            label.TextColor3 = T.Neon
        end
    end
end

--==================== RESTAURANT TYCOON 3 TOOLKIT ====================--
local function waitPath(root, path, timeout)
    timeout = timeout or 8
    local node = root
    local traversed = {}
    for part in string.gmatch(path or "", "[^/]+") do
        if not node then
            return nil, string.format("Mangler startnode for sti '%s'", path)
        end
        local nextNode = node:WaitForChild(part, timeout)
        if not nextNode then
            local parentName = node.GetFullName and node:GetFullName() or tostring(node)
            local prefix = #traversed > 0 and table.concat(traversed, "/") or parentName
            return nil, string.format("Fant ikke '%s' under %s", part, prefix)
        end
        table.insert(traversed, part)
        node = nextNode
    end
    return node
end

local function firstFoodChild(folder)
    if not folder then return nil end
    local direct = folder:FindFirstChild("Food")
    if direct then return direct end
    local modelChild = folder:FindFirstChildWhichIsA("Model")
    if modelChild then return modelChild end
    local basePartChild = folder:FindFirstChildWhichIsA("BasePart")
    if basePartChild then return basePartChild end
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") then
            return child
        end
    end
end

local function findTycoonModel(config, waitTimeout)
    waitTimeout = waitTimeout or 8
    local tycoonPath = config.TycoonPath
    if tycoonPath and tycoonPath ~= "" then
        local tycoon = select(1, waitPath(workspace, tycoonPath, waitTimeout))
        if tycoon then return tycoon end
        warn(string.format("[RT3 Toolkit] Fant ikke tycoon via '%s' – prøver å autodetektere.", tycoonPath))
    end

    local tycoonFolder = workspace:FindFirstChild("Tycoons")
    if not tycoonFolder then
        return nil, "Fant ikke 'Tycoons' i workspace"
    end

    local player = Players.LocalPlayer
    local playerName = player and player.Name and player.Name:lower()

    local function matchesOwner(model)
        if not model or not model:IsA("Model") then return false end
        if playerName and string.find(model.Name:lower(), playerName, 1, true) then
            return true
        end

        local ownerAttr = model:GetAttribute("Owner")
        if ownerAttr then
            if typeof(ownerAttr) == "Instance" and ownerAttr == player then
                return true
            end
            if typeof(ownerAttr) == "string" and playerName and ownerAttr:lower() == playerName then
                return true
            end
        end

        local ownerValue = model:FindFirstChild("Owner")
        if ownerValue then
            local ok, value = pcall(function() return ownerValue.Value end)
            if ok and value then
                if value == player then return true end
                if typeof(value) == "string" and playerName and value:lower() == playerName then
                    return true
                end
                if typeof(value) == "Instance" and value:IsA("Player") and value == player then
                    return true
                end
            end
        end
        return false
    end

    local fallback
    for _, child in ipairs(tycoonFolder:GetChildren()) do
        if child:IsA("Model") then
            if not fallback and child:FindFirstChild("Items") then
                fallback = child
            end
            if matchesOwner(child) then
                return child
            end
        end
    end

    if fallback then
        return fallback
    end

    return nil, "Fant ikke spillerens tycoon"
end

local function buildRT3Toolkit(config)
    local waitTimeout = config.WaitTimeout or 8

    local function fetch(root, path, label)
        local node, err = waitPath(root, path, waitTimeout)
        if not node then
            return nil, string.format("%s (%s)", label or path, err or "ukjent feil")
        end
        return node
    end

    local TaskCompleted, err = fetch(ReplicatedStorage, "Events/Restaurant/TaskCompleted", "TaskCompleted-remote")
    if not TaskCompleted then return nil, err end
    local Interacted, err = fetch(ReplicatedStorage, "Events/Restaurant/Interactions/Interacted", "Interacted-remote")
    if not Interacted then return nil, err end
    local CookInput, err = fetch(ReplicatedStorage, "Events/Cook/CookInputRequested", "CookInput-remote")
    if not CookInput then return nil, err end
    local GrabFood, err = fetch(ReplicatedStorage, "Events/Restaurant/GrabFood", "GrabFood-remote")
    if not GrabFood then return nil, err end

    local Tycoon, err = findTycoonModel(config, waitTimeout)
    if not Tycoon then return nil, err end

    local function fetchTycoon(path, label)
        return fetch(Tycoon, path, label)
    end

    local OrderCounterModel, err = fetchTycoon(config.OrderCounterPath, "OrderCounter-modellen")
    if not OrderCounterModel then return nil, err end
    local KitchenModel, err = fetchTycoon(config.KitchenPath, "Kitchen-modellen")
    if not KitchenModel then return nil, err end
    local OvenModel, err = fetchTycoon(config.OvenPath, "Oven-modellen")
    if not OvenModel then return nil, err end

    local globalFoodFolder
    if config.GlobalFoodFolderPath and config.GlobalFoodFolderPath ~= "" then
        globalFoodFolder = select(1, waitPath(Tycoon, config.GlobalFoodFolderPath, waitTimeout))
    end
    if not globalFoodFolder then
        local objectsFolder = Tycoon:FindFirstChild("Objects")
        if objectsFolder then
            globalFoodFolder = objectsFolder:FindFirstChild("Food")
        end
    end

    local tableEntries = {}
    local tableModels = {}
    for _, tbl in ipairs(config.Tables) do
        local model, tableErr = waitPath(Tycoon, tbl.ModelPath, waitTimeout)
        if not model then
            warn(string.format("[RT3 Toolkit] Fant ikke bord '%s': %s", tbl.Name, tableErr or "ukjent feil"))
        end
        local entry = {
            Name = tbl.Name,
            Model = model,
            Config = tbl,
        }
        tableEntries[tbl.Name] = entry
        tableModels[tbl.Name] = model
    end

    local function resolveFoodModel(entry)
        if not entry then return nil end
        local cfg = entry.Config or {}

        if cfg.FoodModelPath and cfg.FoodModelPath ~= "" then
            local foodModel = select(1, waitPath(Tycoon, cfg.FoodModelPath, waitTimeout))
            if foodModel then
                return foodModel
            end
        end

        local tableModel = entry.Model
        if tableModel then
            local container
            if cfg.FoodContainerPath and cfg.FoodContainerPath ~= "" then
                container = select(1, waitPath(tableModel, cfg.FoodContainerPath, waitTimeout))
            else
                container = tableModel:FindFirstChild("Trash")
            end
            local candidate = firstFoodChild(container)
            if candidate then
                return candidate
            end
        end

        if cfg.FoodFolderPath and cfg.FoodFolderPath ~= "" then
            local folder = select(1, waitPath(Tycoon, cfg.FoodFolderPath, waitTimeout))
            local candidate = firstFoodChild(folder)
            if candidate then
                return candidate
            end
        end

        if globalFoodFolder then
            local candidate = firstFoodChild(globalFoodFolder)
            if candidate then
                return candidate
            end
        end

        return nil
    end

    local function near(a, b, maxDist)
        maxDist = maxDist or 18
        local ap = (a:IsA("BasePart") and a.Position) or (a.PrimaryPart and a.PrimaryPart.Position)
        local bp = (b:IsA("BasePart") and b.Position) or (b.PrimaryPart and b.PrimaryPart.Position)
        if not ap or not bp then return true end
        return (ap - bp).Magnitude <= maxDist
    end

    local function myRoot()
        local plr = Players.LocalPlayer
        local character = plr.Character or plr.CharacterAdded:Wait()
        return character:WaitForChild("HumanoidRootPart")
    end

    local function buildTaskPayload(fields)
        local payload = {}
        payload.Name = assert(fields.Name, "Task name missing")
        payload.Tycoon = fields.Tycoon or Tycoon
        if fields.GroupId then payload.GroupId = tostring(fields.GroupId) end
        if fields.FurnitureModel then payload.FurnitureModel = fields.FurnitureModel end
        if fields.CustomerId then payload.CustomerId = tostring(fields.CustomerId) end
        if fields.FoodModel then payload.FoodModel = fields.FoodModel end
        return { payload }
    end

    local function buildInteractedOrderCounter(args)
        local rootPart = workspace:FindFirstChild("Temp") and workspace.Temp:FindFirstChild("Part")
        local prompt = rootPart and rootPart:FindFirstChild(args.Id or "0")
        local fallbackPart = rootPart or Instance.new("Part")
        local fallbackPrompt = prompt or Instance.new("ProximityPrompt")
        return Tycoon, {
            WorldPosition   = (fallbackPart and fallbackPart.Position) or Vector3.new(),
            HoldDuration    = 0.375,
            Part            = fallbackPart,
            TemporaryPart   = fallbackPart,
            Model           = args.Model or OrderCounterModel,
            InteractionType = "OrderCounter",
            Prompt          = fallbackPrompt,
            ActionText      = "Cook",
            Id              = tostring(args.Id or "0"),
        }
    end

    local function findTableEntry(tableOrName)
        if typeof(tableOrName) == "table" then
            return tableOrName
        end
        if typeof(tableOrName) == "string" then
            return tableEntries[tableOrName]
        end
    end

    local Actions = {}

    function Actions.SendToTable(groupId, tableModel)
        TaskCompleted:FireServer(table.unpack(buildTaskPayload({
            Name = "SendToTable",
            GroupId = groupId,
            FurnitureModel = tableModel,
        })))
    end

    function Actions.TakeOrder(groupId, customerId)
        TaskCompleted:FireServer(table.unpack(buildTaskPayload({
            Name = "TakeOrder",
            GroupId = groupId,
            CustomerId = customerId,
        })))
    end

    function Actions.PullOrderSlip(idStr)
        local a1, a2 = buildInteractedOrderCounter({ Id = idStr })
        Interacted:FireServer(a1, a2)
    end

    function Actions.KitchenInteract()
        CookInput:FireServer("Interact", KitchenModel, "Kitchen")
    end

    function Actions.KitchenComplete()
        CookInput:FireServer("CompleteTask", KitchenModel, "Kitchen")
    end

    function Actions.OvenInteract()
        CookInput:FireServer("Interact", OvenModel, "Oven")
    end

    function Actions.OvenComplete(didBurnFlag)
        CookInput:FireServer("CompleteTask", OvenModel, "Oven", didBurnFlag == true)
    end

    function Actions.GrabFood(tableRef)
        local entry = findTableEntry(tableRef)
        if not entry then
            warn("[RT3 Toolkit] Fant ikke borddata for GrabFood.")
            return nil
        end
        local food = resolveFoodModel(entry)
        if not food then
            warn(string.format("[RT3 Toolkit] Fant ikke matmodell for bord '%s'", entry.Name))
            return nil
        end
        local ok, errMsg = pcall(function()
            return GrabFood:InvokeServer(food)
        end)
        if not ok then
            warn(string.format("[RT3 Toolkit] GrabFood-feil for bord '%s': %s", entry.Name, errMsg))
        end
        return food
    end

    function Actions.Serve(groupId, customerId, tableRef, foodModel)
        local entry = findTableEntry(tableRef)
        if not entry then
            warn("[RT3 Toolkit] Fant ikke borddata for Serve.")
            return
        end
        local payload = buildTaskPayload({
            Name = "Serve",
            GroupId = groupId,
            CustomerId = customerId,
            FoodModel = foodModel,
        })
        TaskCompleted:FireServer(table.unpack(payload))
    end

    function Actions.CollectBill(tableModel)
        TaskCompleted:FireServer(table.unpack(buildTaskPayload({
            Name = "CollectBill",
            FurnitureModel = tableModel,
        })))
    end

    function Actions.CollectDishes(tableModel)
        TaskCompleted:FireServer(table.unpack(buildTaskPayload({
            Name = "CollectDishes",
            FurnitureModel = tableModel,
        })))
    end

    local toolkit = {
        Tycoon = Tycoon,
        Models = {
            OrderCounter = OrderCounterModel,
            Kitchen = KitchenModel,
            Oven = OvenModel,
        },
        Tables = tableModels,
        TableEntries = tableEntries,
        FoodFolder = globalFoodFolder,
        Actions = Actions,
        Near = near,
        MyRoot = myRoot,
    }

    getgenv().RT3 = toolkit

    return toolkit
end

local AutoFarmConfig = {
    TycoonPath = "Tycoons/Tycoon",
    OrderCounterPath = "Items/Surface/K16",
    KitchenPath = "Items/Surface/K15",
    OvenPath = "Items/Surface/K28",
    GlobalFoodFolderPath = "Objects/Food",
    Tables = {
        {
            Name = "T10",
            ModelPath = "Items/Surface/T10",
            GroupIds = {"1", "2"},
            SeatIds = {"1", "2"},
            OrderSlipIds = {"0", "1"},
            FoodFolderPath = "Objects/Food",
            CookingSteps = {
                {"KitchenInteract"},
                {"Delay", 0.35},
                {"KitchenComplete"},
                {"OvenInteract"},
                {"Delay", 0.4},
                {"OvenComplete", false},
                {"KitchenInteract"},
                {"Delay", 0.35},
                {"KitchenComplete"},
            },
        },
    },
    Delays = {
        BetweenActions = 0.3,
        BetweenOrders = 0.25,
        BetweenSlips = 0.35,
        BetweenServes = 0.45,
        BetweenGroups = 0.6,
        AfterCleanup = 0.5,
        CyclePause = 1.5,
        WaitNear = 0.25,
    },
    ProximityRange = 24,
}

local function deepCopyTables(configTables, toolkit)
    local copies = {}
    for _, tbl in ipairs(configTables) do
        local entry = toolkit.TableEntries and toolkit.TableEntries[tbl.Name]
        table.insert(copies, {
            Name = tbl.Name,
            Model = entry and entry.Model or nil,
            Entry = entry,
            GroupIds = tbl.GroupIds,
            SeatIds = tbl.SeatIds,
            OrderSlipIds = tbl.OrderSlipIds,
            CookingSteps = tbl.CookingSteps,
        })
    end
    return copies
end

AutoFarm.Config = AutoFarmConfig
AutoFarm.RuntimeToken = 0
AutoFarm.Running = false
AutoFarm.Toolkit = nil

function AutoFarm:IsActive(token)
    return self.Enabled and self.RuntimeToken == token
end

function AutoFarm:ResetToolkit()
    self.Toolkit = nil
end

function AutoFarm:ensureToolkit()
    if self.Toolkit then return self.Toolkit end
    setAutoFarmStatus("Setter opp RT3-toolkit…")
    local toolkit, err = buildRT3Toolkit(self.Config)
    if not toolkit then
        local message = "Toolkit-feil: " .. trim(err or "ukjent")
        setAutoFarmStatus(message, T.Warn)
        warn("[Autofarm] " .. message)
        return nil
    end
    self.Toolkit = toolkit
    return toolkit
end

function AutoFarm:waitForActive(token, duration)
    duration = duration or self.Config.Delays.BetweenActions
    local elapsed = 0
    while elapsed < duration do
        if not self:IsActive(token) then return false end
        local step = math.min(0.1, duration - elapsed)
        elapsed += step
        task.wait(step)
    end
    return self:IsActive(token)
end

function AutoFarm:ensureProximity(token, toolkit, model, label)
    if not model then
        setAutoFarmStatus("Fant ikke modell for " .. (label or "ukjent") .. ".", T.Warn)
        return "missing"
    end
    if not self:IsActive(token) then return false end
    while self:IsActive(token) and not toolkit.Near(toolkit.MyRoot(), model, self.Config.ProximityRange) do
        setAutoFarmStatus("Venter til du står nær " .. (label or model.Name) .. "…", T.Warn)
        if not self:waitForActive(token, self.Config.Delays.WaitNear) then
            return false
        end
    end
    return self:IsActive(token)
end

function AutoFarm:runCooking(token, actions, steps)
    for _, step in ipairs(steps or {}) do
        if not self:IsActive(token) then return false end
        local action = step[1]
        if action == "Delay" then
            if not self:waitForActive(token, step[2] or self.Config.Delays.BetweenActions) then
                return false
            end
        else
            local fn = actions[action]
            if fn then
                fn(step[2])
            end
            if not self:waitForActive(token, self.Config.Delays.BetweenActions) then
                return false
            end
        end
    end
    return self:IsActive(token)
end

function AutoFarm:runGroupPipeline(token, toolkit, tableProfile)
    local actions = toolkit.Actions
    local delays = self.Config.Delays
    local tableModel = tableProfile.Model
    local tableEntry = tableProfile.Entry

    if not tableEntry then
        setAutoFarmStatus("Fant ikke borddata for " .. tableProfile.Name .. ".", T.Warn)
        return false
    end

    for _, groupId in ipairs(tableProfile.GroupIds or {}) do
        if not self:IsActive(token) then return false end
        setAutoFarmStatus("Plasserer gruppe " .. groupId .. " ved " .. tableProfile.Name .. "…")
        actions.SendToTable(groupId, tableModel)
        if not self:waitForActive(token, delays.BetweenActions) then return false end

        setAutoFarmStatus("Tar ordre for gruppe " .. groupId .. "…")
        for _, seatId in ipairs(tableProfile.SeatIds or {}) do
            if not self:IsActive(token) then return false end
            actions.TakeOrder(groupId, seatId)
            if not self:waitForActive(token, delays.BetweenOrders) then return false end
        end

        setAutoFarmStatus("Henter lapper for " .. tableProfile.Name .. "…")
        for _, slipId in ipairs(tableProfile.OrderSlipIds or {}) do
            if not self:IsActive(token) then return false end
            actions.PullOrderSlip(slipId)
            if not self:waitForActive(token, delays.BetweenSlips) then return false end
        end

        setAutoFarmStatus("Tilbereder retter for " .. tableProfile.Name .. "…")
        if not self:runCooking(token, actions, tableProfile.CookingSteps) then
            return false
        end

        setAutoFarmStatus("Serverer gruppe " .. groupId .. "…")
        for _, seatId in ipairs(tableProfile.SeatIds or {}) do
            if not self:IsActive(token) then return false end
            local foodModel = actions.GrabFood(tableEntry)
            if not foodModel then
                setAutoFarmStatus("Fant ikke mat for " .. tableProfile.Name .. ".", T.Warn)
                return false
            end
            if not self:waitForActive(token, delays.BetweenActions) then return false end
            actions.Serve(groupId, seatId, tableEntry, foodModel)
            if not self:waitForActive(token, delays.BetweenServes) then return false end
        end

        setAutoFarmStatus("Tar betaling på " .. tableProfile.Name .. "…")
        actions.CollectBill(tableModel)
        if not self:waitForActive(token, delays.BetweenActions) then return false end

        setAutoFarmStatus("Rydder " .. tableProfile.Name .. "…")
        actions.CollectDishes(tableModel)
        if not self:waitForActive(token, delays.AfterCleanup) then return false end

        if not self:waitForActive(token, delays.BetweenGroups) then return false end
    end

    return self:IsActive(token)
end

function AutoFarm:runLoop(token)
    local toolkit
    local tableProfiles
    while self:IsActive(token) do
        if not self.Toolkit then
            toolkit = self:ensureToolkit()
            if toolkit then
                tableProfiles = deepCopyTables(self.Config.Tables, toolkit)
            else
                tableProfiles = nil
            end
        elseif toolkit ~= self.Toolkit then
            toolkit = self.Toolkit
            if toolkit then
                tableProfiles = deepCopyTables(self.Config.Tables, toolkit)
            else
                tableProfiles = nil
            end
        end
        if not toolkit then
            setAutoFarmStatus("Toolkit mangler — stoppet.", T.Warn)
            break
        end
        for _, profile in ipairs(tableProfiles or {}) do
            if not self:IsActive(token) then break end
            local proximity = self:ensureProximity(token, toolkit, profile.Model, profile.Name)
            local skipProfile = false
            if proximity == "missing" then
                skipProfile = true
                if not self:waitForActive(token, self.Config.Delays.CyclePause) then
                    break
                end
            elseif not proximity then
                break
            end
            if not skipProfile then
                if not self:IsActive(token) then break end
                local ok = self:runGroupPipeline(token, toolkit, profile)
                if not ok then break end
            end
        end
        if not self:IsActive(token) then break end
        setAutoFarmStatus("Syklus ferdig — venter…")
        if not self:waitForActive(token, self.Config.Delays.CyclePause) then
            break
        end
    end
end

function AutoFarm:Start()
    if self.Running then return end
    self.Enabled = true
    self.RuntimeToken += 1
    local token = self.RuntimeToken
    self.Running = true
    task.spawn(function()
        local hadError = false
        local ok, err = pcall(function()
            setAutoFarmStatus("Initialiserer…")
            self:runLoop(token)
        end)
        if not ok then
            hadError = true
            setAutoFarmStatus("Feil: " .. trim(err), T.Warn)
        end
        if self.RuntimeToken == token then
            self.Enabled = false
        end
        self.Running = false
        if not self.Enabled then
            if hadError then
                task.delay(2.5, function()
                    if not self.Enabled and not self.Running then
                        setAutoFarmStatus("Idle")
                    end
                end)
            else
                setAutoFarmStatus("Idle")
            end
        end
    end)
end

function AutoFarm:Stop()
    if not self.Enabled and not self.Running then
        setAutoFarmStatus("Idle")
        return
    end
    self.Enabled = false
    self.RuntimeToken += 1
    setAutoFarmStatus("Stopper…")
    task.spawn(function()
        while self.Running do
            task.wait(0.1)
        end
        setAutoFarmStatus("Idle")
    end)
end

--==================== PAGES & CONTROLS ====================--
local AutoFarmP = newPage("Autofarm")
local UiP      = newPage("UI")
local InfoP    = newPage("Info")

tabButton("Autofarm", AutoFarmP)
tabButton("UI", UiP)
tabButton("Info", InfoP)
AutoFarmP.Visible = true

-- Autofarm overview
mkToggle(AutoFarmP, "Enable Autofarm", AutoFarm.Enabled, function(v)
    if v then
        AutoFarm:Start()
    else
        AutoFarm:Stop()
    end
end, "Starter/stopper for den komplette Restaurant Tycoon 3-autofarmen.")

local statusRow, statusLabel = rowBase(AutoFarmP, "Autofarm Status", "Shows whether the automation core is running.")
statusLabel.Text = "Autofarm Status"

local statusValue = Instance.new("TextLabel", statusRow)
statusValue.BackgroundTransparency = 1
statusValue.Position = UDim2.new(1, -160, 0.5, -14)
statusValue.Size = UDim2.new(0, 140, 0, 28)
statusValue.Font = Enum.Font.GothamBold
statusValue.Text = AutoFarm.Status
statusValue.TextColor3 = T.Neon
statusValue.TextSize = 14
statusValue.TextXAlignment = Enum.TextXAlignment.Right
statusValue.TextYAlignment = Enum.TextYAlignment.Center

AutoFarm.StatusLabel = statusValue

local refreshButton = mkButton(AutoFarmP, "Oppdater tycoon-referanser", function()
    AutoFarm:ResetToolkit()
    setAutoFarmStatus("Toolkit oppdatert — bygges på nytt i neste syklus.")
end, {buttonText = "Oppdater"}, "Rescanner tycoonen for bord/stasjoner hvis du har redesignet layouten din.")

RunService.RenderStepped:Connect(function()
    setInteractable(refreshButton.Row, not AutoFarm.Running)
end)

-- UI helpers
local function killMenu()
    if Root then Root.Visible = false end
    if Gate then Gate.Enabled = false end
    if SuccessGui then SuccessGui.Enabled = false end
    TweenService:Create(Blur, TweenInfo.new(0.15), {Size = 0}):Play()
    Blur.Enabled = false
end

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.K then
        Root.Visible = not Root.Visible
    elseif input.KeyCode == Enum.KeyCode.P then
        killMenu()
    end
end)

mkToggle(UiP,"Press K to toggle UI", true, function() end, "Reminder that K toggles the panel visibility.")
local dragToggle = mkToggle(UiP,"Allow Dragging", true, function(v)
    draggingEnabled = v
    if not v then dragging=false end
end, "Locks or unlocks the ability to drag the window around.")
local centerBtn = mkButton(UiP, "Center Panel", function()
    Root.Position = UDim2.fromScale(0.5,0.5)
    dragging = false
end, {buttonText="Center"}, "Recenters the panel on your screen.")
local scaleSlider = mkSlider(UiP,"UI Scale", 0.85, 1.25, PanelScale.Scale, function(x) PanelScale.Scale=x end,"x", "Changes the overall size of the menu UI.")
mkButton(UiP, "Kill Menu (remove UI)", function() killMenu() end, {danger=true, buttonText="Kill Menu"}, "Completely closes the UI until you rerun the script.")

-- Info / credits
local creditCard = Instance.new("Frame", InfoP)
creditCard.Name = "CreditsCard"
creditCard.BackgroundColor3 = T.Card
creditCard.Size = UDim2.new(0.5, -6, 0, 64)
corner(creditCard, 10)
stroke(creditCard, T.Stroke, 1, 0.25)

local creditPadding = Instance.new("UIPadding", creditCard)
creditPadding.PaddingLeft = UDim.new(0, 18)
creditPadding.PaddingRight = UDim.new(0, 18)
creditPadding.PaddingTop = UDim.new(0, 12)
creditPadding.PaddingBottom = UDim.new(0, 12)

local creditTitle = Instance.new("TextLabel", creditCard)
creditTitle.BackgroundTransparency = 1
creditTitle.Position = UDim2.new(0, 0, 0, 0)
creditTitle.Size = UDim2.new(1, -140, 0, 22)
creditTitle.Font = Enum.Font.GothamBold
creditTitle.Text = "ProfitCruiser Menu Shell"
creditTitle.TextColor3 = T.Text
creditTitle.TextSize = 15
creditTitle.TextXAlignment = Enum.TextXAlignment.Left
creditTitle.TextYAlignment = Enum.TextYAlignment.Top

local creditSub = Instance.new("TextLabel", creditCard)
creditSub.BackgroundTransparency = 1
creditSub.Position = UDim2.new(0, 0, 0, 24)
creditSub.Size = UDim2.new(1, -140, 1, -28)
creditSub.Font = Enum.Font.Gotham
creditSub.Text = "Restaurant Tycoon 3 autofarmen er live — juster tabellen i AutoFarm.Config om du har andre bord."
creditSub.TextColor3 = T.Subtle
creditSub.TextSize = 12
creditSub.TextWrapped = true
creditSub.TextXAlignment = Enum.TextXAlignment.Left
creditSub.TextYAlignment = Enum.TextYAlignment.Top

local discordBtn = Instance.new("TextButton", creditCard)
discordBtn.Name = "DiscordCopy"
discordBtn.AutoButtonColor = false
discordBtn.Size = UDim2.new(0, 120, 0, 34)
discordBtn.Position = UDim2.new(1, -132, 0.5, -17)
discordBtn.Font = Enum.Font.GothamBold
discordBtn.Text = "Discord"
discordBtn.TextColor3 = T.Text
discordBtn.TextSize = 14
discordBtn.BackgroundColor3 = T.Accent
corner(discordBtn, 12)
stroke(discordBtn, T.Stroke, 1, 0.3)

local discordHover = T.Neon
local discordBase = discordBtn.BackgroundColor3
discordBtn.MouseEnter:Connect(function()
    TweenService:Create(discordBtn, TweenInfo.new(0.12), {BackgroundColor3 = discordHover}):Play()
end)
discordBtn.MouseLeave:Connect(function()
    TweenService:Create(discordBtn, TweenInfo.new(0.12), {BackgroundColor3 = discordBase}):Play()
end)

local defaultSubText = creditSub.Text
local copySignal = 0
discordBtn.MouseButton1Click:Connect(function()
    copySignal += 1
    local ticket = copySignal
    local success = false
    if setclipboard then
        success = pcall(function()
            setclipboard(DISCORD_URL)
        end)
        success = success == true
    end
    if success then
        creditSub.Text = "Discord link copied"
        creditSub.TextColor3 = T.Good
    else
        creditSub.Text = "Kunne ikke kopiere automatisk — bruk lenken: " .. DISCORD_URL
        creditSub.TextColor3 = T.Warn
    end
    TweenService:Create(creditSub, TweenInfo.new(0.12), {TextTransparency = 0}):Play()
    task.delay(1.6, function()
        if copySignal == ticket then
            creditSub.Text = defaultSubText
            creditSub.TextColor3 = T.Subtle
        end
    end)
end)

-- Show panel when gate closes (only if allowed by flow)
Gate:GetPropertyChangedSignal("Enabled"):Connect(function()
    local on = Gate.Enabled
    TweenService:Create(Blur, TweenInfo.new(0.2), {Size = on and 8 or 0}):Play()
    Blur.Enabled = on or (not on and not allowReveal)
    -- Only reveal Root if gate closed AND the reveal flag was set (set after overlay finishes)
    if (not on) and allowReveal and Root then
        Root.Visible = true
    end
end)
