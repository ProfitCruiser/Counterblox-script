-- ProfitCruiser — Neon UI (FULL, Custom Key Gate)
-- Rainbow Title • Aimbot (wall-check fix) • Recoil Control v2
-- ESP (color pickers) • Crosshair • Config Profiles

----------------------------------------------------------------
-- Rayfield (use existing if present)
----------------------------------------------------------------
local Rayfield = rawget(_G,"Rayfield") or (getgenv and rawget(getgenv(),"Rayfield")) or Rayfield
if not Rayfield then
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and lib then
        Rayfield = lib
        _G.Rayfield = lib
    else
        error("[ProfitCruiser] Rayfield missing and couldn't be loaded.")
    end
end

----------------------------------------------------------------
-- Neon Theme
----------------------------------------------------------------
local NeonTheme = {
    TextColor = Color3.fromRGB(245,245,255),
    Background = Color3.fromRGB(10,10,14),
    Topbar     = Color3.fromRGB(16,18,26),
    Shadow     = Color3.fromRGB(12,12,16),

    NotificationBackground = Color3.fromRGB(14,14,18),
    NotificationActionsBackground = Color3.fromRGB(230,230,240),

    TabBackground = Color3.fromRGB(24,26,40),
    TabStroke = Color3.fromRGB(60,70,140),
    TabBackgroundSelected = Color3.fromRGB(220,230,255),
    TabTextColor = Color3.fromRGB(220,230,255),
    SelectedTabTextColor = Color3.fromRGB(20,24,34),

    ElementBackground = Color3.fromRGB(18,20,30),
    ElementBackgroundHover = Color3.fromRGB(22,26,38),
    SecondaryElementBackground = Color3.fromRGB(14,16,24),
    ElementStroke = Color3.fromRGB(70,120,255),
    SecondaryElementStroke = Color3.fromRGB(50,90,220),

    SliderBackground = Color3.fromRGB(0,190,255),
    SliderProgress   = Color3.fromRGB(0,255,170),
    SliderStroke     = Color3.fromRGB(0,225,255),

    ToggleBackground = Color3.fromRGB(20,22,30),
    ToggleEnabled    = Color3.fromRGB(0,255,170),
    ToggleDisabled   = Color3.fromRGB(120,120,130),
    ToggleEnabledStroke = Color3.fromRGB(0,200,255),
    ToggleDisabledStroke = Color3.fromRGB(140,140,150),
    ToggleEnabledOuterStroke=Color3.fromRGB(40,60,120),
    ToggleDisabledOuterStroke=Color3.fromRGB(40,40,50),

    DropdownSelected = Color3.fromRGB(24,28,44),
    DropdownUnselected = Color3.fromRGB(16,18,28),

    InputBackground = Color3.fromRGB(18,20,30),
    InputStroke     = Color3.fromRGB(70,120,255),
    PlaceholderColor= Color3.fromRGB(170,180,210)
}

----------------------------------------------------------------
-- WINDOW  (Rayfield KeySystem OFF – using our own neon gate)
----------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "ProfitCruiser — Counter Blox",
    Icon = 0,
    LoadingTitle = "PROFITCRUISER",
    LoadingSubtitle = "",
    ShowText = "",
    Theme = NeonTheme,
    ToggleUIKeybind = "K",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ProfitCruiser",
        FileName = "PF_Config"
    },

    Discord = { Enabled = true, Invite = "7ECZwyRS8j", RememberJoins = true },

    KeySystem = false -- IMPORTANT
})

-- Rainbow neon on topbar title
task.spawn(function()
    local cg = game:GetService("CoreGui")
    for _=1,200 do task.wait(0.01) end
    local rf = cg:FindFirstChild("Rayfield")
    if rf and rf.Main and rf.Main.Topbar then
        local title = rf.Main.Topbar.Title
        local hue = 0
        while title and title.Parent do
            hue = (hue + 1) % 360
            title.TextColor3 = Color3.fromHSV(hue/360, 1, 1)
            task.wait(0.05)
        end
    end
end)

local function notify(t,c,d) pcall(function() Rayfield:Notify({ Title = t, Content = c, Duration = d or 4 }) end) end

----------------------------------------------------------------
-- CUSTOM NEON KEY GATE (Get Key + Discord + Paste + validation)
----------------------------------------------------------------
do
    local PASTE_RAW_KEY_URL = "https://pastebin.com/raw/QgqAaumb"
    local GET_KEY_URL       = "https://link-hub.net/1386339/FR3iYI9WV3ld"
    local DISCORD_URL       = "https://discord.gg/7ECZwyRS8j"

    local CoreGui  = game:GetService("CoreGui")
    local Lighting = game:GetService("Lighting")

    local EXPECTED = ""
    pcall(function() EXPECTED = (game:HttpGet(PASTE_RAW_KEY_URL) or ""):gsub("^%s+",""):gsub("%s+$","") end)

    local function openUrl(u)
        local req = (syn and syn.request) or (http and http.request) or request or http_request
        if typeof(req) == "function" then pcall(function() req({Url=u, Method="GET"}) end) end
        if setclipboard then pcall(function() setclipboard(u) end) end
    end

    local blur = Instance.new("BlurEffect")
    blur.Name = "PC_Key_Blur"; blur.Size = 18; blur.Parent = Lighting

    local gui = Instance.new("ScreenGui")
    gui.Name = "PC_KeyGate"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = CoreGui

    local dim = Instance.new("Frame", gui)
    dim.BackgroundColor3 = Color3.new(0,0,0)
    dim.BackgroundTransparency = 0.35
    dim.Size = UDim2.fromScale(1,1)

    local panel = Instance.new("Frame", gui)
    panel.Size = UDim2.fromOffset(620, 250)
    panel.AnchorPoint, panel.Position = Vector2.new(0.5,0.5), UDim2.fromScale(0.5,0.5)
    panel.BackgroundColor3 = Color3.fromRGB(14,16,24)
    panel.BackgroundTransparency = 0.15
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0,18)

    local stroke = Instance.new("UIStroke", panel)
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(70,120,255)

    local okGlow = pcall(function()
        local g = Instance.new("ImageLabel", panel)
        g.BackgroundTransparency = 1
        g.Image = "rbxassetid://5028857084"
        g.ImageTransparency = 0.6
        g.Size = UDim2.fromScale(1.35,1.35)
        g.AnchorPoint, g.Position = Vector2.new(0.5,0.5), UDim2.fromScale(0.5,0.5)
    end)
    if not okGlow then warn("[PC] glow image failed to load; continuing") end

    local title = Instance.new("TextLabel", panel)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "🔑 Counter Blox — Access Key"
    title.TextColor3 = Color3.fromRGB(235,242,255)
    title.Size, title.Position = UDim2.fromOffset(560,28), UDim2.fromOffset(20,16)

    local note = Instance.new("TextLabel", panel)
    note.BackgroundTransparency = 1
    note.Font = Enum.Font.Gotham
    note.TextSize = 14
    note.TextXAlignment = Enum.TextXAlignment.Left
    note.TextColor3 = Color3.fromRGB(175,185,210)
    note.Text = "Paste your key • Click Get Key or join Discord"
    note.Size, note.Position = UDim2.fromOffset(560,20), UDim2.fromOffset(20,44)

    local cap = Instance.new("TextLabel", panel)
    cap.BackgroundTransparency = 1
    cap.Font = Enum.Font.Gotham
    cap.TextSize = 12
    cap.TextXAlignment = Enum.TextXAlignment.Left
    cap.TextColor3 = Color3.fromRGB(216,224,238)
    cap.Text = "Key"
    cap.Position, cap.Size = UDim2.fromOffset(20,80), UDim2.fromOffset(540,14)

    local box = Instance.new("TextBox", panel)
    box.Font = Enum.Font.Gotham
    box.TextSize = 16
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.PlaceholderText = "Enter key"
    box.PlaceholderColor3 = Color3.fromRGB(210,220,238)
    box.BackgroundColor3 = Color3.fromRGB(22,26,38)
    box.Position, box.Size = UDim2.fromOffset(20,100), UDim2.fromOffset(420,36)
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,10)
    local bxStroke = Instance.new("UIStroke", box)
    bxStroke.Color, bxStroke.Thickness, bxStroke.Transparency = Color3.fromRGB(0,200,255), 2, 0.2

    local function mkBtn(txt, x)
        local b = Instance.new("TextButton", panel)
        b.AutoButtonColor = false
        b.Text = txt
        b.Font = Enum.Font.GothamBold
        b.TextSize = 14
        b.TextColor3 = Color3.new(1,1,1)
        b.BackgroundColor3 = Color3.fromRGB(22,28,38)
        b.Position, b.Size = UDim2.fromOffset(x,150), UDim2.fromOffset(120,36)
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,12)
        local s = Instance.new("UIStroke", b)
        s.Color, s.Thickness, s.Transparency = Color3.fromRGB(0,180,210), 2, 0.2
        b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(26,34,50) end)
        b.MouseLeave:Connect(function() b.BackgroundColor3 = Color3.fromRGB(22,28,38) end)
        return b
    end

    local btnGetKey  = mkBtn("Get Key",  20)
    local btnDiscord = mkBtn("Discord",  150)
    local btnUnlock  = mkBtn("Unlock",   280)
    local btnPaste   = mkBtn("Paste",    450)

    btnGetKey.MouseButton1Click:Connect(function()
        openUrl(GET_KEY_URL)
        notify("Get Key","Link opened/copied.",3)
    end)
    btnDiscord.MouseButton1Click:Connect(function()
        openUrl(DISCORD_URL)
        notify("Discord","Invite opened/copied.",3)
    end)
    btnPaste.MouseButton1Click:Connect(function()
        if getclipboard then
            local c = getclipboard()
            if c and c ~= "" then box.Text = c end
        end
    end)

    local function wrong()
        box.Position = box.Position + UDim2.fromOffset(-3,0); task.wait(0.04)
        box.Position = box.Position + UDim2.fromOffset( 6,0); task.wait(0.04)
        box.Position = box.Position + UDim2.fromOffset(-3,0)
        bxStroke.Color = Color3.fromRGB(255,85,85)
        task.delay(0.4,function() bxStroke.Color = Color3.fromRGB(0,200,255) end)
        notify("Key","Invalid key.",2)
    end
    local function tryUnlock()
        local typed = (box.Text or ""):gsub("^%s+",""):gsub("%s+$","")
        if typed ~= "" and EXPECTED ~= "" and typed == EXPECTED then
            gui:Destroy(); pcall(function() blur:Destroy() end)
            notify("Access","Key accepted.",3)
        else
            wrong()
        end
    end
    btnUnlock.MouseButton1Click:Connect(tryUnlock)
    box.FocusLost:Connect(function(enter) if enter then tryUnlock() end end)
end
-- === END Custom Key Gate ===

----------------------------------------------------------------
-- Tabs (use valid Lucide icon name)
----------------------------------------------------------------
local AimbotTab = Window:CreateTab("Aimbot", "target")
local ESPTab    = Window:CreateTab("ESP")
local VisualsTab= Window:CreateTab("Visuals")
local MiscTab   = Window:CreateTab("Misc")
local ConfigTab = Window:CreateTab("Config")
local InfoTab   = Window:CreateTab("Info")

----------------------------------------------------------------
-- Services
----------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

----------------------------------------------------------------
-- AIMBOT (with wall-check fix)
----------------------------------------------------------------
AimbotTab:CreateSection("Recoil Control")
local RC = { Enabled=false, OnlyWhileShooting=true, VerticalStrength=0.6, HorizontalStrength=0.0, Smooth=0.35 }
AimbotTab:CreateToggle({ Name="Enable Recoil Control", CurrentValue=RC.Enabled, Flag="PC_RC_Enable", Callback=function(v) RC.Enabled=v end })
AimbotTab:CreateToggle({ Name="Only while shooting (LMB)", CurrentValue=RC.OnlyWhileShooting, Flag="PC_RC_OnlyShoot", Callback=function(v) RC.OnlyWhileShooting=v end })
AimbotTab:CreateSlider({ Name="Vertical Strength", Range={0,3}, Increment=0.01, CurrentValue=RC.VerticalStrength, Flag="PC_RC_Vert", Callback=function(v) RC.VerticalStrength=v end })
AimbotTab:CreateSlider({ Name="Horizontal Strength", Range={0,3}, Increment=0.01, CurrentValue=RC.HorizontalStrength, Flag="PC_RC_Horz", Callback=function(v) RC.HorizontalStrength=v end })
AimbotTab:CreateSlider({ Name="Smooth", Range={0.05,1}, Increment=0.01, CurrentValue=RC.Smooth, Flag="PC_RC_Smooth", Callback=function(v) RC.Smooth=v end })

local function applyRecoilCompensation(dt)
    if not RC.Enabled then return end
    if RC.OnlyWhileShooting and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
    local vDegPerSec = RC.VerticalStrength * 12
    local hDegPerSec = RC.HorizontalStrength * 12
    local xPitchDown = -math.rad(vDegPerSec * dt)
    local yYawLeft   = -math.rad(hDegPerSec * dt)
    local desired = Camera.CFrame * CFrame.Angles(xPitchDown, yYawLeft, 0)
    local alpha = math.clamp(RC.Smooth, 0.05, 1)
    Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
end

AimbotTab:CreateSection("Aim Assist / Aimbot Settings")
local AA = { Enabled=false, Strength=0.15, PartName="Head", ShowFOV=true, FOVRadiusPx=180, MaxDistance=250, RequireRMB=false, WallCheck=true }

local AA_GUI = Instance.new("ScreenGui")
AA_GUI.Name="PC_AA_UI"; AA_GUI.ResetOnSpawn=false; AA_GUI.IgnoreGuiInset=true
AA_GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")

local FOVFrame = Instance.new("Frame")
FOVFrame.AnchorPoint=Vector2.new(0.5,0.5); FOVFrame.Position=UDim2.fromScale(0.5,0.5)
FOVFrame.BackgroundTransparency=1; FOVFrame.Size=UDim2.fromOffset(AA.FOVRadiusPx*2, AA.FOVRadiusPx*2)
FOVFrame.Visible=AA.ShowFOV; FOVFrame.Parent=AA_GUI
local FOVStroke = Instance.new("UIStroke"); FOVStroke.Thickness=2; FOVStroke.Transparency=0.15; FOVStroke.Color=Color3.fromRGB(0,255,140); FOVStroke.Parent=FOVFrame
Instance.new("UICorner", FOVFrame).CornerRadius = UDim.new(1,0)

local function isEnemy(plr: Player) if plr==LocalPlayer then return false end if LocalPlayer.Team and plr.Team then return LocalPlayer.Team~=plr.Team end return true end
local function getAimPart(char: Model) local p=char:FindFirstChild(AA.PartName) if not(p and p:IsA("BasePart")) then p=char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") end return (p and p:IsA("BasePart")) and p or nil end
local function hasLineOfSight(targetPart: BasePart, targetChar: Model)
    if not AA.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local params = RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={LocalPlayer.Character, targetChar}; params.IgnoreWater=true
    return workspace:Raycast(origin, direction, params) == nil
end
local function getTarget()
    local myChar=LocalPlayer.Character; local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart"); if not(myHRP and Camera) then return nil end
    local cx,cy=Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2; local best,bestScore
    for _,plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) and plr.Character then
            local aimPart=getAimPart(plr.Character); local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
            if aimPart and hrp then
                local dist=(hrp.Position - myHRP.Position).Magnitude
                if dist<=AA.MaxDistance then
                    local sp,onScreen=Camera:WorldToViewportPoint(aimPart.Position)
                    if onScreen then
                        local dx,dy=sp.X-cx, sp.Y-cy; local pixelDist=(dx*dx+dy*dy)^0.5
                        if pixelDist<=AA.FOVRadiusPx and hasLineOfSight(aimPart, plr.Character) then
                            local score=pixelDist + dist*0.02
                            if not best or score<bestScore then best,bestScore=aimPart,score end
                        end
                    end
                end
            end
        end
    end
    return best
end

AimbotTab:CreateToggle({ Name="Enable AimBot", CurrentValue=AA.Enabled, Flag="PC_Aim_Enabled", Callback=function(v) AA.Enabled=v end })
AimbotTab:CreateDropdown({ Name="Target Body Part", Options={"Head","UpperTorso","HumanoidRootPart"}, CurrentOption=AA.PartName, Flag="PC_Aim_Part", Callback=function(opt) AA.PartName=(typeof(opt)=="table" and opt[1]) or opt end })
AimbotTab:CreateSlider({ Name="Strength (lower = stronger)", Range={0.05,0.40}, Increment=0.01, CurrentValue=AA.Strength, Flag="PC_Aim_Strength", Callback=function(v) AA.Strength=v end })
AimbotTab:CreateToggle({ Name="Show FOV", CurrentValue=AA.ShowFOV, Flag="PC_Aim_ShowFOV", Callback=function(v) AA.ShowFOV=v end })
AimbotTab:CreateSlider({ Name="FOV Radius (px)", Range={40,500}, Increment=5, CurrentValue=AA.FOVRadiusPx, Flag="PC_Aim_FOVPx", Callback=function(v) AA.FOVRadiusPx=math.floor(v) end })
AimbotTab:CreateSlider({ Name="Max Distance (studs)", Range={50,1000}, Increment=10, CurrentValue=AA.MaxDistance, Flag="PC_Aim_Distance", Callback=function(v) AA.MaxDistance=v end })
AimbotTab:CreateToggle({ Name="Require Right Mouse (hold)", CurrentValue=AA.RequireRMB, Flag="PC_Aim_RequireRMB", Callback=function(v) AA.RequireRMB=v end })
AimbotTab:CreateToggle({ Name="Wall Check (line of sight)", CurrentValue=AA.WallCheck, Flag="PC_Aim_WallCheck", Callback=function(v) AA.WallCheck=v end })

RunService.RenderStepped:Connect(function(dt)
    FOVFrame.Visible = AA.ShowFOV
    FOVFrame.Size = UDim2.fromOffset(AA.FOVRadiusPx*2, AA.FOVRadiusPx*2)
    if AA.Enabled then
        if not (AA.RequireRMB and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
            local target = getTarget()
            if target then
                local camPos = Camera.CFrame.Position
                local desired = CFrame.lookAt(camPos, target.Position)
                local t = math.clamp(AA.Strength + dt * 0.5, 0, 1)
                Camera.CFrame = Camera.CFrame:Lerp(desired, t)
            end
        end
    end
    applyRecoilCompensation(dt)
end)

----------------------------------------------------------------
-- ESP (logic unchanged + color pickers)
----------------------------------------------------------------
ESPTab:CreateSection("ESP")
local MAX_DISTANCE, espEnabled, espEnemiesOnly, espUseDistance = 500, true, false, true
local FRIEND_COLOR, ENEMY_COLOR, NEUTRAL_COLOR = Color3.fromRGB(0,255,140), Color3.fromRGB(255,70,70), Color3.fromRGB(255,255,0)

local function getOrCreateHighlight(model)
    local h = model:FindFirstChild("_HL_"); if not h then h = Instance.new("Highlight"); h.Name="_HL_"; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.FillTransparency=0.8; h.OutlineTransparency=0; h.Parent=model end
    return h
end
local function isEnemyESP(targetPlayer) if not LocalPlayer.Team or not targetPlayer.Team then return nil end return LocalPlayer.Team ~= targetPlayer.Team end
local function distanceToCharacter(character) local hrp=character and character:FindFirstChild("HumanoidRootPart"); local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if hrp and myHRP then return (hrp.Position - myHRP.Position).Magnitude end return math.huge end
local function updateHighlightFor(player)
    if player==LocalPlayer then return end
    local char=player.Character; if not char then return end
    local h=getOrCreateHighlight(char)
    local show=espEnabled
    if show and espEnemiesOnly then local enemy=isEnemyESP(player); show=(enemy==true) end
    if show and espUseDistance then show=distanceToCharacter(char) <= MAX_DISTANCE end
    h.Enabled=show; if not show then return end
    local enemy=isEnemyESP(player)
    if enemy==true then h.FillColor=ENEMY_COLOR; h.OutlineColor=ENEMY_COLOR
    elseif enemy==false then h.FillColor=FRIEND_COLOR; h.OutlineColor=FRIEND_COLOR
    else h.FillColor=NEUTRAL_COLOR; h.OutlineColor=NEUTRAL_COLOR end
end
RunService.RenderStepped:Connect(function() for _,plr in ipairs(Players:GetPlayers()) do updateHighlightFor(plr) end end)
local function hookPlayer(p) p.CharacterAdded:Connect(function() task.wait(0.2); updateHighlightFor(p) end) end
for _,p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(hookPlayer)

ESPTab:CreateToggle({ Name="Enable ESP", CurrentValue=espEnabled, Flag="PC_ESP_Enabled", Callback=function(v) espEnabled=v end })
ESPTab:CreateToggle({ Name="Enemies Only", CurrentValue=espEnemiesOnly, Flag="PC_ESP_EnemiesOnly", Callback=function(v) espEnemiesOnly=v end })
ESPTab:CreateToggle({ Name="Use Distance Limit", CurrentValue=espUseDistance, Flag="PC_ESP_UseDistance", Callback=function(v) espUseDistance=v end })
ESPTab:CreateSlider({ Name="Max Distance", Range={50,2000}, Increment=50, CurrentValue=MAX_DISTANCE, Flag="PC_ESP_Distance", Callback=function(v) MAX_DISTANCE=v end })
if ESPTab.CreateColorPicker then
    ESPTab:CreateSection("Colors")
    ESPTab:CreateColorPicker({ Name="Enemy Color",   Color=ENEMY_COLOR,  Flag="PC_ESP_Color_Enemy",   Callback=function(c) ENEMY_COLOR=c end })
    ESPTab:CreateColorPicker({ Name="Teammate Color",Color=FRIEND_COLOR, Flag="PC_ESP_Color_Friend",  Callback=function(c) FRIEND_COLOR=c end })
    ESPTab:CreateColorPicker({ Name="Neutral/Unknown Color", Color=NEUTRAL_COLOR, Flag="PC_ESP_Color_Neutral", Callback=function(c) NEUTRAL_COLOR=c end })
else
    ESPTab:CreateParagraph({ Title="Colors", Content="Update Rayfield to enable ESP color pickers." })
end

----------------------------------------------------------------
-- VISUALS (crosshair)
----------------------------------------------------------------
VisualsTab:CreateSection("Crosshair")
local VX = { Crosshair=false, CrossColor=Color3.fromRGB(0,255,200), CrossOpacity=0.9, CrossSize=8, CrossGap=4, CrossThickness=2, CenterDot=false, DotSize=2, DotOpacity=1 }
local hasDraw, lines, centerDot = false, {}, nil
do
    local ok = pcall(function()
        local function newLine() local l=Drawing.new("Line"); l.Thickness=VX.CrossThickness; l.Transparency=VX.CrossOpacity; l.Color=VX.CrossColor; l.Visible=false; return l end
        lines={newLine(),newLine(),newLine(),newLine()}
        centerDot=Drawing.new("Square"); centerDot.Filled=true; centerDot.Size=Vector2.new(VX.DotSize,VX.DotSize); centerDot.Color=VX.CrossColor; centerDot.Transparency=VX.DotOpacity; centerDot.Visible=false
        hasDraw=true
    end)
    if not ok then
        local CoreGui=game:GetService("CoreGui")
        local cg=Instance.new("ScreenGui"); cg.Name="PC_Crosshair_GUI"; cg.ResetOnSpawn=false; cg.IgnoreGuiInset=true; cg.DisplayOrder=9999; cg.ZIndexBehavior=Enum.ZIndexBehavior.Global; cg.Parent=CoreGui
        local function part() local f=Instance.new("Frame"); f.BorderSizePixel=0; f.BackgroundColor3=VX.CrossColor; f.BackgroundTransparency=1-VX.CrossOpacity; f.Visible=false; f.Parent=cg; return f end
        lines={part(),part(),part(),part()}
        local dot=Instance.new("Frame"); dot.BorderSizePixel=0; dot.BackgroundColor3=VX.CrossColor; dot.BackgroundTransparency=1-VX.DotOpacity; dot.Visible=false; dot.Parent=cg; centerDot=dot
    end
end
local function updateCrosshair()
    if not VX.Crosshair then for _,l in ipairs(lines) do l.Visible=false end if centerDot then centerDot.Visible=false end return end
    local vp=Camera.ViewportSize; local cx,cy=vp.X*0.5,vp.Y*0.5; local g,s,t=VX.CrossGap,VX.CrossSize,VX.CrossThickness
    if hasDraw then
        lines[1].From=Vector2.new(cx,cy-g); lines[1].To=Vector2.new(cx,cy-g-s)
        lines[2].From=Vector2.new(cx,cy+g); lines[2].To=Vector2.new(cx,cy+g+s)
        lines[3].From=Vector2.new(cx-g,cy); lines[3].To=Vector2.new(cx-g-s,cy)
        lines[4].From=Vector2.new(cx+g,cy); lines[4].To=Vector2.new(cx+g+s,cy)
        for _,l in ipairs(lines) do l.Color=VX.CrossColor; l.Thickness=t; l.Transparency=VX.CrossOpacity; l.Visible=true end
        if centerDot then centerDot.Size=Vector2.new(VX.DotSize,VX.DotSize); centerDot.Position=Vector2.new(cx - VX.DotSize/2, cy - VX.DotSize/2); centerDot.Color=VX.CrossColor; centerDot.Transparency=VX.DotOpacity; centerDot.Visible=VX.CenterDot end
    else
        lines[1].Size=UDim2.fromOffset(t,s); lines[1].Position=UDim2.fromOffset(cx - t/2, cy - g - s)
        lines[2].Size=UDim2.fromOffset(t,s); lines[2].Position=UDim2.fromOffset(cx - t/2, cy + g)
        lines[3].Size=UDim2.fromOffset(s,t); lines[3].Position=UDim2.fromOffset(cx - g - s, cy - t/2)
        lines[4].Size=UDim2.fromOffset(s,t); lines[4].Position=UDim2.fromOffset(cx + g, cy - t/2)
        for _,f in ipairs(lines) do f.BackgroundColor3=VX.CrossColor; f.BackgroundTransparency=1 - VX.CrossOpacity; f.Visible=true end
        if centerDot then centerDot.Size=UDim2.fromOffset(VX.DotSize,VX.DotSize); centerDot.Position=UDim2.fromOffset(cx - VX.DotSize/2, cy - VX.DotSize/2); centerDot.BackgroundColor3=VX.CrossColor; centerDot.BackgroundTransparency=1 - VX.DotOpacity; centerDot.Visible=VX.CenterDot end
    end
end
RunService.RenderStepped:Connect(updateCrosshair)
VisualsTab:CreateToggle({ Name="Crosshair", CurrentValue=VX.Crosshair, Flag="PC_VIS_Cross", Callback=function(v) VX.Crosshair=v; updateCrosshair() end })
if VisualsTab.CreateColorPicker then VisualsTab:CreateColorPicker({ Name="Crosshair Color", Color=VX.CrossColor, Flag="PC_VIS_CrossCol", Callback=function(c) VX.CrossColor=c; updateCrosshair() end }) end
VisualsTab:CreateSlider({ Name="Opacity", Range={0.1,1}, Increment=0.05, CurrentValue=VX.CrossOpacity, Flag="PC_VIS_CrossOp", Callback=function(v) VX.CrossOpacity=v; updateCrosshair() end })
VisualsTab:CreateSlider({ Name="Size", Range={4,24}, Increment=1, CurrentValue=VX.CrossSize, Flag="PC_VIS_CrossSize", Callback=function(v) VX.CrossSize=v; updateCrosshair() end })
VisualsTab:CreateSlider({ Name="Gap", Range={2,20}, Increment=1, CurrentValue=VX.CrossGap, Flag="PC_VIS_CrossGap", Callback=function(v) VX.CrossGap=v; updateCrosshair() end })
VisualsTab:CreateSlider({ Name="Thickness", Range={1,6}, Increment=1, CurrentValue=VX.CrossThickness, Flag="PC_VIS_CrossTh", Callback=function(v) VX.CrossThickness=v; updateCrosshair() end })
VisualsTab:CreateToggle({ Name="Center Dot", CurrentValue=VX.CenterDot, Flag="PC_VIS_Dot", Callback=function(v) VX.CenterDot=v; updateCrosshair() end })
VisualsTab:CreateSlider({ Name="Dot Size", Range={1,6}, Increment=1, CurrentValue=VX.DotSize, Flag="PC_VIS_DotSize", Callback=function(v) VX.DotSize=v; updateCrosshair() end })
VisualsTab:CreateSlider({ Name="Dot Opacity", Range={0.1,1}, Increment=0.05, CurrentValue=VX.DotOpacity, Flag="PC_VIS_DotOp", Callback=function(v) VX.DotOpacity=v; updateCrosshair() end })

----------------------------------------------------------------
-- MISC
----------------------------------------------------------------
MiscTab:CreateSection("UI")

-- Robust keybind (fixes 'string expected, got EnumItem' on some builds)
local function safeCreateKeybind()
    local ok = pcall(function()
        MiscTab:CreateKeybind({
            Name = "Toggle UI",
            CurrentKeybind = Enum.KeyCode.K, -- try Enum
            HoldToInteract = false,
            Flag = "PC_UI_Toggle",
            Callback = function() if Rayfield.Toggle then Rayfield:Toggle() end end
        })
    end)
    if not ok then
        MiscTab:CreateKeybind({
            Name = "Toggle UI",
            CurrentKeybind = "K",            -- fallback to string
            HoldToInteract = false,
            Flag = "PC_UI_Toggle",
            Callback = function() if Rayfield.Toggle then Rayfield:Toggle() end end
        })
    end
end
safeCreateKeybind()

MiscTab:CreateSection("Social")
MiscTab:CreateButton({
    Name = "Copy Discord Invite",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/7ECZwyRS8j")
            notify("Discord", "Invite copied to clipboard!", 3)
        else
            notify("Discord", "Clipboard not supported", 4)
        end
    end
})

----------------------------------------------------------------
-- CONFIG — Profiles (FS or memory fallback)
----------------------------------------------------------------
ConfigTab:CreateSection("Profiles")
ConfigTab:CreateParagraph({ Title = "Profiles", Content = "Save & load your UI settings here." })

local BASE_FOLDER = "ProfitCruiser"
local PROF_FOLDER = BASE_FOLDER .. "/Profiles"
local STORAGE_MODE = "memory"
local MEM_STORE = rawget(_G, "PC_ProfileStore") or {}
_G.PC_ProfileStore = MEM_STORE

local function ensureFolders()
    if makefolder then
        local ok1 = true
        if not (isfolder and isfolder(BASE_FOLDER)) then ok1 = pcall(function() makefolder(BASE_FOLDER) end) end
        local ok2 = true
        if not (isfolder and isfolder(PROF_FOLDER)) then ok2 = pcall(function() makefolder(PROF_FOLDER) end) end
        return ok1 and ok2
    end
    return false
end
if ensureFolders() and writefile and readfile then STORAGE_MODE = "filesystem" end

local function gatherState()
    local flags = {}
    if Rayfield and Rayfield.Flags then
        for k,v in pairs(Rayfield.Flags) do
            flags[k] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
        end
    end
    return { Flags = flags }
end
local function applyState(state)
    if state and state.Flags and Rayfield and Rayfield.Flags then
        for name,val in pairs(state.Flags) do
            local f = Rayfield.Flags[name]
            if f and f.Set then pcall(function() f:Set(val) end) end
        end
    end
end

local function saveProfile(name)
    local ok, data = pcall(function() return HttpService:JSONEncode(gatherState()) end)
    if not ok then return false, "encode failed" end
    if STORAGE_MODE == "filesystem" then
        local path = PROF_FOLDER .. ("/%s.json"):format(name)
        local s,err = pcall(function() writefile(path, data) end)
        return s, (s and nil or tostring(err))
    else
        MEM_STORE[name] = data
        return true
    end
end
local function loadProfile(name)
    if STORAGE_MODE == "filesystem" then
        local path = PROF_FOLDER .. ("/%s.json"):format(name)
        if not (isfile and isfile(path)) then return false, "file missing" end
        local ok, raw = pcall(function() return readfile(path) end)
        if not ok then return false, "read error" end
        local ok2, tbl = pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok2 then return false, "decode error" end
        applyState(tbl); return true
    else
        local raw = MEM_STORE[name]
        if not raw then return false, "profile missing" end
        local ok2, tbl = pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok2 then return false, "decode error" end
        applyState(tbl); return true
    end
end

ConfigTab:CreateButton({
    Name = "Save Default",
    Callback = function()
        local ok,err = saveProfile("Default")
        if ok then notify("Config","Saved Default ("..STORAGE_MODE..")",2)
        else notify("Config","Save failed: "..tostring(err),3) end
    end
})
ConfigTab:CreateButton({
    Name = "Load Default",
    Callback = function()
        local ok,err = loadProfile("Default")
        if ok then notify("Config","Loaded Default",2)
        else notify("Config","Load failed: "..tostring(err),3) end
    end
})

if ConfigTab.CreateDropdown and ConfigTab.CreateInput then
    ConfigTab:CreateSection("Advanced Profiles")

    local currentProfile = "Default"
    local existing = { "Default" }
    if STORAGE_MODE == "filesystem" and listfiles then
        pcall(function()
            for _,p in ipairs(listfiles(PROF_FOLDER)) do
                local name = string.match(p, "/([%w%._%-]+)%.json$") or string.match(p, "\\([%w%._%-]+)%.json$")
                if name and name ~= "Default" then table.insert(existing, name) end
            end
        end)
    else
        for name,_ in pairs(MEM_STORE) do if name ~= "Default" then table.insert(existing, name) end end
    end

    local ProfileDropdown = ConfigTab:CreateDropdown({
        Name = "Select Profile",
        Options = existing,
        CurrentOption = "Default",
        Flag = "PC_Config_Profile",
        Callback = function(opt)
            currentProfile = (typeof(opt)=="table" and opt[1]) or opt
            notify("Config","Selected: "..currentProfile,2)
        end
    })

    ConfigTab:CreateButton({
        Name = "Save Selected",
        Callback = function()
            local ok,err = saveProfile(currentProfile)
            if ok then
                notify("Config","Saved: "..currentProfile,2)
                if ProfileDropdown and ProfileDropdown.Set then
                    local found=false
                    for _,o in ipairs(existing) do if o==currentProfile then found=true break end end
                    if not found then table.insert(existing, currentProfile) end
                    ProfileDropdown:Set(currentProfile, existing)
                end
            else
                notify("Config","Save failed: "..tostring(err),3)
            end
        end
    })
    ConfigTab:CreateButton({
        Name = "Load Selected",
        Callback = function()
            local ok,err = loadProfile(currentProfile)
            if ok then notify("Config","Loaded: "..currentProfile,2)
            else notify("Config","Load failed: "..tostring(err),3) end
        end
    })
    ConfigTab:CreateInput({
        Name = "New Profile Name",
        PlaceholderText = "e.g. Sniper, Rifle",
        RemoveTextAfterFocusLost = true,
        Callback = function(txt)
            if not txt or txt=="" then return end
            currentProfile = txt
            if ProfileDropdown and ProfileDropdown.Set then
                local found=false
                for _,o in ipairs(existing) do if o==txt then found=true break end end
                if not found then table.insert(existing, txt) end
                ProfileDropdown:Set(txt, existing)
            end
            notify("Config","Profile ready: "..txt.." (press Save Selected)",3)
        end
    })
else
    ConfigTab:CreateParagraph({
        Title = "Profiles (basic mode)",
        Content = "Your Rayfield build doesn’t support dropdown/input.\nUse Save/Load above. Storage: "..STORAGE_MODE.."."
    })
end

----------------------------------------------------------------
-- INFO
----------------------------------------------------------------
InfoTab:CreateSection("ProfitCruiser")
InfoTab:CreateParagraph({
    Title="Neon UI",
    Content="Tabs: Aimbot / ESP / Visuals / Misc / Config.\nWallCheck fixed. ESP color pickers. Recoil Control v2.\nConfig: profiles with filesystem/memory fallback.\nDiscord: https://discord.gg/ukb5AqhBwK"
})

notify("Script Executed", "ProfitCruiser loaded — Aimbot, ESP, Recoil v2 & Config ready.", 4)
