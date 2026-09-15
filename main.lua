local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local ObsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local Compile = loadstring or load
if type(Compile) ~= "function" then
    error("Pallet EIK: this executor does not provide loadstring/load, so the Obsidian UI library cannot be loaded.")
end
local LibrarySource
local HttpSuccess, HttpResult = pcall(function()
    return game:HttpGet(ObsidianRepo .. "Library.lua")
end)
if not HttpSuccess or type(HttpResult) ~= "string" or #HttpResult < 1000 then
    error("Pallet EIK: failed to download the Obsidian Library.lua file. HTTP result was invalid.")
end
LibrarySource = HttpResult
local LibraryChunk, LibraryCompileError = Compile(LibrarySource)
if type(LibraryChunk) ~= "function" then
    error("Pallet EIK: Obsidian Library.lua failed to compile: " .. tostring(LibraryCompileError))
end
local LibraryOk, LibraryResult = pcall(LibraryChunk)
if not LibraryOk then
    error("Pallet EIK: Obsidian Library.lua threw an error while loading: " .. tostring(LibraryResult))
end
local Library = LibraryResult
if type(Library) ~= "table" then
    error("Pallet EIK: Obsidian Library.lua returned an invalid value: " .. typeof(Library))
end
if type(Library.CreateWindow) ~= "function" then
    error("Pallet EIK: loaded Obsidian library does not expose CreateWindow. Use the official main branch Library.lua.")
end
local Options = Library.Options or {}
local Toggles = Library.Toggles or {}
Library.Options = Options
Library.Toggles = Toggles

local Window = Library:CreateWindow({
    Title = "Pallet EIK",
    Footer = "Beam Detection",
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
})

local MainTab = Window:AddTab("Main", "home")
local SettingsTab = Window:AddTab("Settings", "settings")
local TimeTab = Window:AddTab("Time", "sun")
local VisualsTab = Window:AddTab("Visuals", "eye")
local KeybindsTab = Window:AddTab("Keybinds", "keyboard")

local BeamSection = MainTab:AddLeftGroupbox("Beam Detection")
local UtilitySection = MainTab:AddRightGroupbox("Utility")
local PalletColorSection = MainTab:AddLeftGroupbox("Pallet Color")
local EIKSection = MainTab:AddRightGroupbox("Pallet Text")

local CameraSection = SettingsTab:AddLeftGroupbox("Camera")
local GrabLineSection = SettingsTab:AddRightGroupbox("Grab Line")
local GrabLineUtilitySection = SettingsTab:AddLeftGroupbox("Grab Line Utility")

local TimeSection = TimeTab:AddLeftGroupbox("Time")
local LightingSection = TimeTab:AddRightGroupbox("Lighting")

local WeatherSection = VisualsTab:AddLeftGroupbox("Weather")
local VisualSettingsSection = VisualsTab:AddRightGroupbox("Visual Settings")

local MenuKeySection = KeybindsTab:AddLeftGroupbox("Menu Key")
local ScriptSection = KeybindsTab:AddRightGroupbox("Script")

local TARGET_NAME = "PalletLightBrown"
local NORMAL_COLOR = Color3.fromRGB(234, 215, 198)
local PALLET_CHANGE_COLOR = Color3.fromRGB(0, 0, 0)
local FADE_TIME = 0.22
local RELEASE_CONFIRM_TIME = 0.12
local CHECK_INTERVAL = 0.08
local DETECTION_ENABLED = true

local EIK_SCALE = 1
local EIK_X = 0
local EIK_Y = 0
local EIK_Z = 0
local EIK_THICKNESS = 2
local EIK_TEXT = "EIK"
local EIK_TEXT_COLOR = Color3.fromRGB(255, 255, 255)

local DEFAULT_FOV = 70
local CurrentFOV = DEFAULT_FOV
local CurrentTime = Lighting.ClockTime
local CurrentBrightness = Lighting.Brightness
local CurrentExposure = Lighting.ExposureCompensation
local CurrentAmbient = Lighting.Ambient
local CurrentOutdoorAmbient = Lighting.OutdoorAmbient

local GreySkyEnabled = false
local SnowEnabled = false
local SnowRange = 100
local SnowAmount = 150
local SnowSpeed = 12

local Pallets = {}
local PalletState = {}
local EIK_DATA = {}
local BeamPart = nil
local CurrentBeam = nil
local SnowPart = nil
local SnowEmitter = nil

local SETTINGS_FILE = "EIK_Pallet_Settings.json"

local OriginalLighting = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    ExposureCompensation = Lighting.ExposureCompensation,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

local OriginalAtmosphereObject = Lighting:FindFirstChildOfClass("Atmosphere")
local OriginalAtmosphere = OriginalAtmosphereObject and {
    Object = OriginalAtmosphereObject,
    Color = OriginalAtmosphereObject.Color,
    Decay = OriginalAtmosphereObject.Decay,
    Density = OriginalAtmosphereObject.Density,
    Haze = OriginalAtmosphereObject.Haze,
    Glare = OriginalAtmosphereObject.Glare,
}

local function loadSettings()
    if not isfile or not readfile or not isfile(SETTINGS_FILE) then return end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(SETTINGS_FILE))
    end)
    if ok and type(data) == "table" and type(data.FOV) == "number" then
        CurrentFOV = math.clamp(data.FOV, 50, 120)
    end
end

local function saveSettings()
    if not writefile then return end
    pcall(function()
        writefile(SETTINGS_FILE, HttpService:JSONEncode({FOV = CurrentFOV}))
    end)
end

loadSettings()

local function applyFOV()
    local camera = Workspace.CurrentCamera
    if camera then camera.FieldOfView = CurrentFOV end
end

applyFOV()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() task.defer(applyFOV) end)

local function getBeamPart()
    local grabParts = Workspace:FindFirstChild("GrabParts")
    if not grabParts then return nil end
    local beamPart = grabParts:FindFirstChild("BeamPart")
    return beamPart and beamPart:IsA("BasePart") and beamPart or nil
end

local function getGrabBeam()
    local beamPart = getBeamPart()
    if not beamPart then return nil end
    local beam = beamPart:FindFirstChild("GrabBeam")
    return beam and beam:IsA("Beam") and beam or nil
end

local GrabLinePresets = {
    ["Low Quality"] = {Texture = "", TextureLength = 1, TextureSpeed = 0, Segments = 10, Width0 = .35, Width1 = .35, Transparency = NumberSequence.new(0)},
    ["Non-Gamepass"] = {Texture = "rbxassetid://8933346550", TextureLength = 2, TextureSpeed = -4, Segments = 20, Width0 = .35, Width1 = .35, Transparency = NumberSequence.new(0)},
    ["Gamepass"] = {Texture = "rbxassetid://8933355899", TextureLength = 2, TextureSpeed = -4, Segments = 20, Width0 = .35, Width1 = .35, Transparency = NumberSequence.new(0)},
    ["Chain"] = {Texture = "rbxassetid://81358145120405", TextureLength = 2.2, TextureSpeed = -4.5, Segments = 25, Width0 = .3, Width1 = .3, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.05,.05),NumberSequenceKeypoint.new(.95,.05),NumberSequenceKeypoint.new(1,1)})},
    ["Chain 2"] = {Texture = "rbxassetid://132910145874066", TextureLength = 2.2, TextureSpeed = -4.5, Segments = 25, Width0 = .3, Width1 = .3, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.05,.05),NumberSequenceKeypoint.new(.95,.05),NumberSequenceKeypoint.new(1,1)})},
    ["Chain 3"] = {Texture = "rbxassetid://128466395060514", TextureLength = 2, TextureSpeed = -5, Segments = 20, Width0 = .35, Width1 = .35, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.05,.1),NumberSequenceKeypoint.new(.95,.1),NumberSequenceKeypoint.new(1,1)})},
    ["Chain 4"] = {Texture = "rbxassetid://73368670987191", TextureLength = 2, TextureSpeed = -4, Segments = 20, Width0 = .35, Width1 = .35, Transparency = NumberSequence.new(0)},
    ["Rope"] = {Texture = "rbxassetid://78999022056924", TextureLength = 2.2, TextureSpeed = -4.5, Segments = 25, Width0 = .3, Width1 = .3, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.05,.05),NumberSequenceKeypoint.new(.95,.05),NumberSequenceKeypoint.new(1,1)})},
    ["Spring"] = {Texture = "rbxassetid://18837732116", TextureLength = 2.2, TextureSpeed = -4.5, Segments = 25, Width0 = .3, Width1 = .3, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.05,.05),NumberSequenceKeypoint.new(.95,.05),NumberSequenceKeypoint.new(1,1)})},
}

local CurrentGrabLineTexture = "Low Quality"

local function applyBeamSettings(beam, settings)
    if not beam or not beam.Parent then return end
    beam.Texture = settings.Texture
    beam.TextureMode = Enum.TextureMode.Wrap
    beam.TextureLength = settings.TextureLength
    beam.TextureSpeed = settings.TextureSpeed
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Segments = settings.Segments
    beam.Width0 = settings.Width0
    beam.Width1 = settings.Width1
    beam.Transparency = settings.Transparency
    beam.Color = ColorSequence.new(Color3.fromRGB(255,255,255))
    beam.FaceCamera = true
end

local function refreshGrabLine()
    BeamPart = getBeamPart()
    CurrentBeam = getGrabBeam()
    if CurrentBeam then applyBeamSettings(CurrentBeam, GrabLinePresets[CurrentGrabLineTexture]) end
end

local function watchGrabParts(grabParts)
    if not grabParts then return end
    task.spawn(function()
        local beamPart = grabParts:WaitForChild("BeamPart", 5)
        if not beamPart then return end
        local beam = beamPart:WaitForChild("GrabBeam", 5)
        if beam then task.defer(refreshGrabLine) end
    end)
end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "GrabParts" then watchGrabParts(child) end
end)
Workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "GrabParts" or obj.Name == "BeamPart" or obj.Name == "GrabBeam" then task.defer(refreshGrabLine) end
end)
Workspace.DescendantRemoving:Connect(function(obj)
    if obj == CurrentBeam or obj == BeamPart or obj.Name == "GrabBeam" or obj.Name == "BeamPart" or obj.Name == "GrabParts" then task.defer(refreshGrabLine) end
end)

local function isPallet(instance)
    return instance and instance:IsA("Model") and instance.Name == TARGET_NAME
end

local function getPalletFromPart(part)
    if not part then return nil end
    local current = part
    while current and current ~= Workspace do
        if current:IsA("Model") and current.Name == TARGET_NAME then return current end
        current = current.Parent
    end
end

local function findTopPart(pallet)
    local bestPart
    local bestArea = -math.huge
    for _, obj in ipairs(pallet:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:GetAttribute("EIK_Carrier") then
            local area = obj.Size.X * obj.Size.Z
            if area > bestArea then bestArea, bestPart = area, obj end
        end
    end
    return bestPart
end

local function getBaseParts(pallet)
    local parts = {}
    for _, obj in ipairs(pallet:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:GetAttribute("EIK_Carrier") then table.insert(parts, obj) end
    end
    return parts
end

local function destroyEIK(pallet)
    local data = EIK_DATA[pallet]
    if data then
        if data.carrier and data.carrier.Parent then data.carrier:Destroy() end
        EIK_DATA[pallet] = nil
    end
    local old = pallet:FindFirstChild("EIK_Carrier")
    if old then old:Destroy() end
end

local function updateEIK(pallet)
    local data = EIK_DATA[pallet]
    if not data or not data.carrier or not data.carrier.Parent or not data.weld or not data.weld.Parent then return end
    local topPart = data.topPart
    if not topPart or not topPart.Parent then return end
    data.weld.C0 = CFrame.new(EIK_X, (topPart.Size.Y / 2) + .02 + EIK_Y, EIK_Z)
    data.uiScale.Scale = EIK_SCALE
    data.text.Text = EIK_TEXT
    data.text.TextColor3 = EIK_TEXT_COLOR
    data.stroke.Thickness = EIK_THICKNESS
end

local function createEIK(pallet)
    if not pallet or not pallet.Parent then return end
    local topPart = findTopPart(pallet)
    if not topPart then return end
    local oldData = EIK_DATA[pallet]
    if oldData and oldData.topPart == topPart and oldData.carrier and oldData.carrier.Parent then updateEIK(pallet) return end
    destroyEIK(pallet)

    local carrier = Instance.new("Part")
    carrier.Name = "EIK_Carrier"
    carrier:SetAttribute("EIK_Carrier", true)
    carrier.Size = Vector3.new(math.max(topPart.Size.X,.1),.025,math.max(topPart.Size.Z,.1))
    carrier.Transparency = 1
    carrier.CanCollide = false
    carrier.CanTouch = false
    carrier.CanQuery = false
    carrier.CastShadow = false
    carrier.Massless = true
    carrier.Anchored = false
    carrier.CFrame = topPart.CFrame * CFrame.new(EIK_X,(topPart.Size.Y/2)+.02+EIK_Y,EIK_Z)
    carrier.Parent = pallet

    local weld = Instance.new("Weld")
    weld.Name = "EIK_Weld"
    weld.Part0 = topPart
    weld.Part1 = carrier
    weld.C0 = CFrame.new(EIK_X,(topPart.Size.Y/2)+.02+EIK_Y,EIK_Z)
    weld.C1 = CFrame.new()
    weld.Parent = carrier

    local surface = Instance.new("SurfaceGui")
    surface.Name = "EIK_Surface"
    surface.Face = Enum.NormalId.Top
    surface.AlwaysOnTop = true
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 100
    surface.Parent = carrier

    local text = Instance.new("TextLabel")
    text.Name = "EIK"
    text.AnchorPoint = Vector2.new(.5,.5)
    text.Position = UDim2.fromScale(.5,.5)
    text.Size = UDim2.fromScale(.72,.72)
    text.BackgroundTransparency = 1
    text.Text = EIK_TEXT
    text.TextColor3 = EIK_TEXT_COLOR
    text.Font = Enum.Font.GothamBlack
    text.TextScaled = true
    text.TextWrapped = false
    text.Parent = surface

    local stroke = Instance.new("UIStroke")
    stroke.Name = "EIKStroke"
    stroke.Thickness = EIK_THICKNESS
    stroke.Color = EIK_TEXT_COLOR
    stroke.Parent = text

    local uiScale = Instance.new("UIScale")
    uiScale.Name = "EIKScale"
    uiScale.Scale = EIK_SCALE
    uiScale.Parent = text

    EIK_DATA[pallet] = {topPart=topPart,carrier=carrier,weld=weld,text=text,stroke=stroke,uiScale=uiScale}
    updateEIK(pallet)
end

local function refreshAllEIK()
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then destroyEIK(pallet) task.defer(createEIK,pallet) end
    end
end

local function updateAllEIK()
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then updateEIK(pallet) end
    end
end

local function tweenPalletColor(pallet,color)
    if not pallet or not pallet.Parent then return end
    local state = PalletState[pallet]
    if not state or state.targetColor == color then return end
    state.targetColor = color
    state.tweenId = state.tweenId + 1
    local id = state.tweenId
    for _, part in ipairs(getBaseParts(pallet)) do
        if part and part.Parent then
            TweenService:Create(part,TweenInfo.new(FADE_TIME,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Color=color}):Play()
        end
    end
    task.delay(FADE_TIME+.03,function()
        local latest = PalletState[pallet]
        if not latest or latest.tweenId ~= id then return end
        for _, part in ipairs(getBaseParts(pallet)) do if part and part.Parent then part.Color=color end end
    end)
end

local function restorePallet(pallet)
    if not pallet or not pallet.Parent then return end
    local state = PalletState[pallet]
    if state then state.releaseTime=nil state.touching=false end
    tweenPalletColor(pallet,NORMAL_COLOR)
end

local function restoreAll()
    for pallet in pairs(Pallets) do if pallet and pallet.Parent then restorePallet(pallet) end end
end

local function registerPallet(pallet)
    if not isPallet(pallet) or Pallets[pallet] then return end
    Pallets[pallet]=true
    PalletState[pallet]={touching=false,releaseTime=nil,targetColor=nil,tweenId=0}
    for _, part in ipairs(getBaseParts(pallet)) do part.Color=NORMAL_COLOR end
    task.defer(function() if pallet and pallet.Parent then createEIK(pallet) end end)
end

local function unregisterPallet(pallet)
    if not Pallets[pallet] then return end
    destroyEIK(pallet)
    Pallets[pallet]=nil
    PalletState[pallet]=nil
end

for _, obj in ipairs(Workspace:GetDescendants()) do if isPallet(obj) then registerPallet(obj) end end

Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") and obj.Name==TARGET_NAME then task.defer(function() registerPallet(obj) end) return end
    if obj:IsA("BasePart") then
        local pallet=getPalletFromPart(obj)
        if pallet and Pallets[pallet] then task.defer(function() if pallet.Parent then createEIK(pallet) end end) end
    end
end)

Workspace.DescendantRemoving:Connect(function(obj)
    if Pallets[obj] then unregisterPallet(obj) return end
    if obj:IsA("BasePart") then
        local pallet=getPalletFromPart(obj)
        if pallet and Pallets[pallet] then task.defer(function() if pallet.Parent then createEIK(pallet) end end) end
    end
end)

local overlapParams=OverlapParams.new()
overlapParams.FilterType=Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances={Workspace}

local function getOverlappingPallets()
    local result={}
    if not BeamPart or not BeamPart.Parent then BeamPart=getBeamPart() end
    if not BeamPart then return result end
    for _, part in ipairs(Workspace:GetPartsInPart(BeamPart,overlapParams)) do
        if part~=BeamPart then
            local pallet=getPalletFromPart(part)
            if pallet and Pallets[pallet] then result[pallet]=true end
        end
    end
    return result
end

task.spawn(function()
    while true do
        if DETECTION_ENABLED then
            BeamPart=getBeamPart()
            local touching=getOverlappingPallets()
            local now=os.clock()
            for pallet in pairs(Pallets) do
                if not pallet.Parent then
                    unregisterPallet(pallet)
                else
                    local state=PalletState[pallet]
                    if state then
                        if touching[pallet] then
                            state.releaseTime=nil
                            if not state.touching then state.touching=true tweenPalletColor(pallet,PALLET_CHANGE_COLOR) elseif state.targetColor~=PALLET_CHANGE_COLOR then tweenPalletColor(pallet,PALLET_CHANGE_COLOR) end
                        elseif state.touching then
                            state.releaseTime=state.releaseTime or now
                            if now-state.releaseTime>=RELEASE_CONFIRM_TIME then state.touching=false state.releaseTime=nil tweenPalletColor(pallet,NORMAL_COLOR) end
                        end
                    end
                end
            end
        end
        task.wait(CHECK_INTERVAL)
    end
end)

local function getAtmosphere()
    local atmosphere=Lighting:FindFirstChild("PalletEIK_Atmosphere")
    if atmosphere and atmosphere:IsA("Atmosphere") then return atmosphere end
    atmosphere=Instance.new("Atmosphere")
    atmosphere.Name="PalletEIK_Atmosphere"
    atmosphere.Parent=Lighting
    return atmosphere
end

local function restoreLighting()
    Lighting.ClockTime=OriginalLighting.ClockTime
    Lighting.Brightness=OriginalLighting.Brightness
    Lighting.ExposureCompensation=OriginalLighting.ExposureCompensation
    Lighting.Ambient=OriginalLighting.Ambient
    Lighting.OutdoorAmbient=OriginalLighting.OutdoorAmbient
    CurrentTime=OriginalLighting.ClockTime
    CurrentBrightness=OriginalLighting.Brightness
    CurrentExposure=OriginalLighting.ExposureCompensation
    CurrentAmbient=OriginalLighting.Ambient
    CurrentOutdoorAmbient=OriginalLighting.OutdoorAmbient
    if OriginalAtmosphere and OriginalAtmosphere.Object and OriginalAtmosphere.Object.Parent then
        local a=OriginalAtmosphere.Object
        a.Color=OriginalAtmosphere.Color
        a.Decay=OriginalAtmosphere.Decay
        a.Density=OriginalAtmosphere.Density
        a.Haze=OriginalAtmosphere.Haze
        a.Glare=OriginalAtmosphere.Glare
    else
        local a=Lighting:FindFirstChild("PalletEIK_Atmosphere")
        if a then a:Destroy() end
    end
end

local function applyGreySky()
    local a=getAtmosphere()
    if GreySkyEnabled then
        a.Color=Color3.fromRGB(135,135,135)
        a.Decay=Color3.fromRGB(80,80,80)
        a.Density=.35
        a.Haze=2
        a.Glare=0
    else
        restoreLighting()
    end
end

local function updateSnow()
    if not SnowPart or not SnowPart.Parent then
        SnowPart=Instance.new("Part")
        SnowPart.Name="PalletEIK_Snow"
        SnowPart.Anchored=true
        SnowPart.CanCollide=false
        SnowPart.CanTouch=false
        SnowPart.CanQuery=false
        SnowPart.Transparency=1
        SnowPart.Parent=Workspace
        SnowEmitter=Instance.new("ParticleEmitter")
        SnowEmitter.Name="Snow"
        SnowEmitter.Texture="rbxasset://textures/particles/sparkles_main.dds"
        SnowEmitter.Lifetime=NumberRange.new(4,7)
        SnowEmitter.SpreadAngle=Vector2.new(180,180)
        SnowEmitter.Rotation=NumberRange.new(0,360)
        SnowEmitter.RotSpeed=NumberRange.new(-30,30)
        SnowEmitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.08),NumberSequenceKeypoint.new(.5,.13),NumberSequenceKeypoint.new(1,.05)})
        SnowEmitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(.8,.2),NumberSequenceKeypoint.new(1,1)})
        SnowEmitter.Color=ColorSequence.new(Color3.fromRGB(255,255,255))
        SnowEmitter.LightEmission=.8
        SnowEmitter.Parent=SnowPart
    end
    local camera=Workspace.CurrentCamera
    if camera then SnowPart.CFrame=CFrame.new(camera.CFrame.Position+Vector3.new(0,25,0)) end
    SnowPart.Size=Vector3.new(math.max(SnowRange,10),1,math.max(SnowRange,10))
    SnowEmitter.Rate=SnowAmount
    SnowEmitter.Speed=NumberRange.new(3,SnowSpeed)
    SnowEmitter.Enabled=SnowEnabled
end

RunService.RenderStepped:Connect(function() if SnowEnabled then updateSnow() end end)

local State = {
    Enabled = true,
    MenuVisible = true,
    Destroyed = false,
    Connections = {},
    CreatedInstances = {},
    Defaults = {},
    Runtime = {},
}

local function pushConnection(connection)
    if connection then
        table.insert(State.Connections, connection)
    end
    return connection
end

local function trackInstance(instance)
    if instance then
        table.insert(State.CreatedInstances, instance)
    end
    return instance
end

local function disconnectAll()
    for i = #State.Connections, 1, -1 do
        local connection = State.Connections[i]
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
        State.Connections[i] = nil
    end
end

local function destroyTrackedInstances()
    for i = #State.CreatedInstances, 1, -1 do
        local instance = State.CreatedInstances[i]
        if instance and instance.Parent then
            pcall(function()
                instance:Destroy()
            end)
        end
        State.CreatedInstances[i] = nil
    end
end

local function safeSet(instance, property, value)
    if not instance then
        return false
    end
    local ok = pcall(function()
        instance[property] = value
    end)
    return ok
end

local function safeGet(instance, property, fallback)
    if not instance then
        return fallback
    end
    local ok, value = pcall(function()
        return instance[property]
    end)
    if ok then
        return value
    end
    return fallback
end

local function clampNumber(value, minimum, maximum, fallback)
    value = tonumber(value)
    if not value then
        value = fallback or minimum
    end
    return math.clamp(value, minimum, maximum)
end

local function copyColor(color)
    if typeof(color) ~= "Color3" then
        return Color3.new(1, 1, 1)
    end
    return Color3.new(color.R, color.G, color.B)
end

local function copyColorSequence(sequence)
    if typeof(sequence) ~= "ColorSequence" then
        return ColorSequence.new(Color3.new(1, 1, 1))
    end
    local points = {}
    for _, point in ipairs(sequence.Keypoints) do
        table.insert(points, ColorSequenceKeypoint.new(point.Time, copyColor(point.Value)))
    end
    return ColorSequence.new(points)
end

local function copyNumberSequence(sequence)
    if typeof(sequence) ~= "NumberSequence" then
        return NumberSequence.new(0)
    end
    local points = {}
    for _, point in ipairs(sequence.Keypoints) do
        table.insert(points, NumberSequenceKeypoint.new(point.Time, point.Value, point.Envelope))
    end
    return NumberSequence.new(points)
end

local function vectorMagnitude(vector)
    if typeof(vector) ~= "Vector3" then
        return 0
    end
    return vector.Magnitude
end

local function getCamera()
    return Workspace.CurrentCamera
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local character = getCharacter()
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
    local character = getCharacter()
    if not character then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart")
end

local function getPalletDistance(pallet)
    local root = getRootPart()
    local target = pallet and pallet.PrimaryPart
    if not root or not target then
        return math.huge
    end
    return vectorMagnitude(root.Position - target.Position)
end

local function isValidInstance(instance)
    return instance ~= nil and instance.Parent ~= nil
end

local function isBasePart(instance)
    return instance ~= nil and instance:IsA("BasePart")
end

local function isTextLabel(instance)
    return instance ~= nil and instance:IsA("TextLabel")
end

local function getOrCreateFolder(parent, name)
    if not parent then
        return nil
    end
    local existing = parent:FindFirstChild(name)
    if existing then
        return existing
    end
    local folder = trackInstance(Instance.new("Folder"))
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function getOrCreateBoolValue(parent, name, value)
    local object = parent and parent:FindFirstChild(name)
    if object and object:IsA("BoolValue") then
        object.Value = value
        return object
    end
    object = trackInstance(Instance.new("BoolValue"))
    object.Name = name
    object.Value = value
    object.Parent = parent
    return object
end

local function getOrCreateNumberValue(parent, name, value)
    local object = parent and parent:FindFirstChild(name)
    if object and object:IsA("NumberValue") then
        object.Value = value
        return object
    end
    object = trackInstance(Instance.new("NumberValue"))
    object.Name = name
    object.Value = value
    object.Parent = parent
    return object
end

local function getOrCreateStringValue(parent, name, value)
    local object = parent and parent:FindFirstChild(name)
    if object and object:IsA("StringValue") then
        object.Value = value
        return object
    end
    object = trackInstance(Instance.new("StringValue"))
    object.Name = name
    object.Value = value
    object.Parent = parent
    return object
end

local function setAttributeSafe(instance, name, value)
    if not instance then
        return false
    end
    local ok = pcall(function()
        instance:SetAttribute(name, value)
    end)
    return ok
end

local function getAttributeSafe(instance, name, fallback)
    if not instance then
        return fallback
    end
    local ok, value = pcall(function()
        return instance:GetAttribute(name)
    end)
    if ok and value ~= nil then
        return value
    end
    return fallback
end

local function setEIKLabelText(label, text)
    if not isTextLabel(label) then
        return
    end
    label.Text = tostring(text or "EIK")
end

local function setEIKLabelColor(label, color)
    if not isTextLabel(label) then
        return
    end
    label.TextColor3 = copyColor(color)
end

local function setEIKLabelStroke(label, thickness, color)
    if not isTextLabel(label) then
        return
    end
    local stroke = label:FindFirstChild("EIKStroke")
    if not stroke then
        stroke = trackInstance(Instance.new("UIStroke"))
        stroke.Name = "EIKStroke"
        stroke.Parent = label
    end
    stroke.Thickness = clampNumber(thickness, 0, 10, 2)
    stroke.Color = copyColor(color or label.TextColor3)
    stroke.Transparency = 0
end

local function setEIKScale(label, scale)
    if not isTextLabel(label) then
        return
    end
    local uiScale = label:FindFirstChild("EIKScale")
    if not uiScale then
        uiScale = trackInstance(Instance.new("UIScale"))
        uiScale.Name = "EIKScale"
        uiScale.Parent = label
    end
    uiScale.Scale = clampNumber(scale, 0, 100, 1)
end

local function setEIKPosition(carrier, x, y, z)
    if not isValidInstance(carrier) or not carrier:IsA("BasePart") then
        return
    end
    carrier:SetAttribute("EIK_X", x)
    carrier:SetAttribute("EIK_Y", y)
    carrier:SetAttribute("EIK_Z", z)
    local weld = carrier:FindFirstChild("EIKWeld")
    if weld and weld:IsA("Weld") then
        weld.C0 = CFrame.new(x, y, z)
    end
end

local function updateOneEIKData(data)
    if not data then
        return
    end
    local label = data.text
    local carrier = data.carrier
    if label and label.Parent then
        setEIKLabelText(label, EIK_TEXT)
        setEIKLabelColor(label, EIK_TEXT_COLOR)
        setEIKLabelStroke(label, EIK_THICKNESS, Color3.new(0, 0, 0))
        setEIKScale(label, EIK_SCALE)
    end
    if carrier and carrier.Parent then
        setEIKPosition(carrier, EIK_X, EIK_Y, EIK_Z)
    end
end

local function updateEveryEIK()
    for _, data in pairs(EIK_DATA) do
        updateOneEIKData(data)
    end
end

local function getNearestPallet(maxDistance)
    local nearest = nil
    local nearestDistance = maxDistance or math.huge
    for pallet in pairs(Pallets) do
        if isValidInstance(pallet) then
            local distance = getPalletDistance(pallet)
            if distance < nearestDistance then
                nearest = pallet
                nearestDistance = distance
            end
        end
    end
    return nearest, nearestDistance
end

local function clearPalletState(pallet)
    if pallet then
        PalletState[pallet] = nil
        EIK_DATA[pallet] = nil
    end
end

local function rememberPalletState(pallet)
    if not pallet or PalletState[pallet] then
        return
    end
    local state = {
        Parts = {},
        Attributes = {},
    }
    for _, part in ipairs(getBaseParts(pallet)) do
        state.Parts[part] = {
            Color = copyColor(part.Color),
            Transparency = part.Transparency,
            LocalTransparencyModifier = part.LocalTransparencyModifier,
            Material = part.Material,
            Reflectance = part.Reflectance,
        }
    end
    PalletState[pallet] = state
end

local function restoreRememberedPalletState(pallet)
    local state = PalletState[pallet]
    if not state then
        return
    end
    for part, values in pairs(state.Parts) do
        if part and part.Parent then
            safeSet(part, "Color", values.Color)
            safeSet(part, "Transparency", values.Transparency)
            safeSet(part, "LocalTransparencyModifier", values.LocalTransparencyModifier)
            safeSet(part, "Material", values.Material)
            safeSet(part, "Reflectance", values.Reflectance)
        end
    end
end

local function applyPalletColor(pallet, color)
    if not pallet then
        return
    end
    rememberPalletState(pallet)
    for _, part in ipairs(getBaseParts(pallet)) do
        part.Color = copyColor(color)
    end
end

local function applyPalletTransparency(pallet, transparency)
    if not pallet then
        return
    end
    for _, part in ipairs(getBaseParts(pallet)) do
        part.Transparency = clampNumber(transparency, 0, 1, 0)
    end
end

local function setAllPalletsColor(color)
    for pallet in pairs(Pallets) do
        if isValidInstance(pallet) then
            applyPalletColor(pallet, color)
        end
    end
end

local function setAllPalletsTransparency(transparency)
    for pallet in pairs(Pallets) do
        if isValidInstance(pallet) then
            applyPalletTransparency(pallet, transparency)
        end
    end
end

local function resetSinglePallet(pallet)
    if not pallet then
        return
    end
    restoreRememberedPalletState(pallet)
    clearPalletState(pallet)
end

local function resetAllRememberedPallets()
    for pallet in pairs(PalletState) do
        if isValidInstance(pallet) then
            restoreRememberedPalletState(pallet)
        end
    end
    table.clear(PalletState)
end

local function makeBeamTransparency(strength)
    local value = math.clamp(1 - strength, 0, 1)
    return NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.05, value),
        NumberSequenceKeypoint.new(0.95, value),
        NumberSequenceKeypoint.new(1, 1),
    })
end

local function makeBeamColor(color)
    return ColorSequence.new(copyColor(color))
end

local function setBeamColor(beam, color)
    if beam and beam:IsA("Beam") then
        beam.Color = makeBeamColor(color)
    end
end

local function setBeamWidth(beam, width)
    if not beam or not beam:IsA("Beam") then
        return
    end
    local value = clampNumber(width, 0, 10, 0.35)
    beam.Width0 = value
    beam.Width1 = value
end

local function setBeamSpeed(beam, speed)
    if beam and beam:IsA("Beam") then
        beam.TextureSpeed = tonumber(speed) or 0
    end
end

local function setBeamLength(beam, length)
    if beam and beam:IsA("Beam") then
        beam.TextureLength = math.max(0.01, tonumber(length) or 1)
    end
end

local function setBeamSegments(beam, segments)
    if beam and beam:IsA("Beam") then
        beam.Segments = math.clamp(math.floor(tonumber(segments) or 10), 1, 100)
    end
end

local function setBeamEnabled(beam, enabled)
    if beam and beam:IsA("Beam") then
        beam.Enabled = enabled == true
    end
end

local function setCurrentBeamEnabled(enabled)
    setBeamEnabled(getGrabBeam(), enabled)
end

local function refreshAllBeamProperties()
    local beam = getGrabBeam()
    if not beam then
        return
    end
    local preset = GrabLinePresets[CurrentGrabLineTexture]
    if preset then
        applyBeamSettings(beam, preset)
    end
end

local function getSkyAtmosphere()
    return Lighting:FindFirstChildOfClass("Atmosphere")
end

local function setAtmosphereColor(color)
    local atmosphere = getSkyAtmosphere()
    if atmosphere then
        atmosphere.Color = copyColor(color)
    end
end

local function setAtmosphereDensity(value)
    local atmosphere = getSkyAtmosphere()
    if atmosphere then
        atmosphere.Density = clampNumber(value, 0, 1, 0)
    end
end

local function setAtmosphereHaze(value)
    local atmosphere = getSkyAtmosphere()
    if atmosphere then
        atmosphere.Haze = clampNumber(value, 0, 10, 0)
    end
end

local function setAtmosphereGlare(value)
    local atmosphere = getSkyAtmosphere()
    if atmosphere then
        atmosphere.Glare = clampNumber(value, 0, 10, 0)
    end
end

local function setLightingClock(value)
    CurrentTime = clampNumber(value, 0, 24, CurrentTime)
    Lighting.ClockTime = CurrentTime
end

local function setLightingBrightness(value)
    CurrentBrightness = clampNumber(value, 0, 5, CurrentBrightness)
    Lighting.Brightness = CurrentBrightness
end

local function setLightingExposure(value)
    CurrentExposure = clampNumber(value, -5, 5, CurrentExposure)
    Lighting.ExposureCompensation = CurrentExposure
end

local function setLightingAmbient(color)
    CurrentAmbient = copyColor(color)
    Lighting.Ambient = CurrentAmbient
end

local function setLightingOutdoorAmbient(color)
    CurrentOutdoorAmbient = copyColor(color)
    Lighting.OutdoorAmbient = CurrentOutdoorAmbient
end

local function setGreySkyState(enabled)
    GreySkyEnabled = enabled == true
    applyGreySky()
end

local function setSnowState(enabled)
    SnowEnabled = enabled == true
    updateSnow()
end

local function setSnowRange(value)
    SnowRange = clampNumber(value, 0, 1000, SnowRange)
    updateSnow()
end

local function setSnowAmount(value)
    SnowAmount = clampNumber(value, 0, 500, SnowAmount)
    updateSnow()
end

local function setSnowSpeed(value)
    SnowSpeed = clampNumber(value, 1, 30, SnowSpeed)
    updateSnow()
end

local function removeSnow()
    SnowEnabled = false
    if SnowPart then
        SnowPart:Destroy()
        SnowPart = nil
        SnowEmitter = nil
    end
end

local function resetCamera()
    CurrentFOV = DEFAULT_FOV
    applyFOV()
    saveSettings()
end

local function setCameraFOV(value)
    CurrentFOV = clampNumber(value, 50, 120, DEFAULT_FOV)
    applyFOV()
    saveSettings()
end

local function setEIKText(value)
    value = tostring(value or "")
    if value == "" then
        value = "EIK"
    end
    EIK_TEXT = value
    updateAllEIK()
end

local function setEIKTextColor(color)
    EIK_TEXT_COLOR = copyColor(color)
    updateAllEIK()
end

local function setEIKScaleValue(value)
    EIK_SCALE = clampNumber(value, 0, 100, 1)
    updateAllEIK()
end

local function setEIKThicknessValue(value)
    EIK_THICKNESS = clampNumber(value, 0, 10, 2)
    updateAllEIK()
end

local function setEIKX(value)
    EIK_X = clampNumber(value, -5, 5, 0)
    updateAllEIK()
end

local function setEIKY(value)
    EIK_Y = clampNumber(value, -2, 2, 0)
    updateAllEIK()
end

local function setEIKZ(value)
    EIK_Z = clampNumber(value, -5, 5, 0)
    updateAllEIK()
end

local function resetEIKValues()
    EIK_SCALE = 1
    EIK_THICKNESS = 2
    EIK_X = 0
    EIK_Y = 0
    EIK_Z = 0
    EIK_TEXT = "EIK"
    EIK_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
    updateAllEIK()
end

local function getEIKData(pallet)
    return pallet and EIK_DATA[pallet] or nil
end

local function getEIKTextLabel(pallet)
    local data = getEIKData(pallet)
    return data and data.text or nil
end

local function getEIKCarrier(pallet)
    local data = getEIKData(pallet)
    return data and data.carrier or nil
end

local function updatePalletEIK(pallet)
    if not pallet or not pallet.Parent then
        return
    end
    local data = EIK_DATA[pallet]
    if data then
        updateOneEIKData(data)
    end
end

local function updateVisiblePalletEIK()
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then
            updatePalletEIK(pallet)
        end
    end
end

local function getPalletCount()
    local count = 0
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then
            count += 1
        end
    end
    return count
end

local function getProcessedPalletCount()
    local count = 0
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent and PalletState[pallet] then
            count += 1
        end
    end
    return count
end

local function getActiveEIKCount()
    local count = 0
    for pallet, data in pairs(EIK_DATA) do
        if pallet and pallet.Parent and data then
            count += 1
        end
    end
    return count
end

local function cleanupDeadPallets()
    for pallet in pairs(Pallets) do
        if not pallet or not pallet.Parent then
            Pallets[pallet] = nil
            PalletState[pallet] = nil
            EIK_DATA[pallet] = nil
        end
    end
end

local function restoreEverything()
    DETECTION_ENABLED = true
    restoreAll()
    resetAllRememberedPallets()
    resetEIKValues()
    resetCamera()
    restoreLighting()
    removeSnow()
    GreySkyEnabled = false
    State.Enabled = true
end

local function disableEverything()
    DETECTION_ENABLED = false
    State.Enabled = false
    SnowEnabled = false
    GreySkyEnabled = false
    restoreAll()
    resetAllRememberedPallets()
    restoreLighting()
    removeSnow()
    setCurrentBeamEnabled(false)
end

local function registerPallet(pallet)
    if not pallet or not pallet:IsA("Model") or pallet.Name ~= TARGET_NAME then
        return false
    end
    if Pallets[pallet] then
        return false
    end
    Pallets[pallet] = true
    return true
end

local function unregisterPallet(pallet)
    if not pallet then
        return
    end
    destroyEIK(pallet)
    PalletState[pallet] = nil
    Pallets[pallet] = nil
end

local function registerExistingPallets()
    for _, object in ipairs(Workspace:GetDescendants()) do
        if isPallet(object) then
            if not Pallets[object] then
                Pallets[object] = true
            end
        end
    end
end

local function getPalletPartsCount(pallet)
    local count = 0
    if not pallet then
        return count
    end
    for _, object in ipairs(pallet:GetDescendants()) do
        if object:IsA("BasePart") then
            count += 1
        end
    end
    return count
end

local function getPalletBounds(pallet)
    if not pallet then
        return nil, nil
    end
    local ok, cf, size = pcall(function()
        return pallet:GetBoundingBox()
    end)
    if not ok then
        return nil, nil
    end
    return cf, size
end

local function getPalletTopHeight(pallet)
    local _, size = getPalletBounds(pallet)
    return size and size.Y or 0
end

local function isPalletNearPlayer(pallet, distance)
    return getPalletDistance(pallet) <= (distance or 20)
end

local function playerTouchesPallet(pallet)
    if not pallet or not pallet.Parent then
        return false
    end
    local character = getCharacter()
    if not character then
        return false
    end
    if pallet:IsDescendantOf(character) then
        return true
    end
    local cf, size = getPalletBounds(pallet)
    if not cf or not size then
        return false
    end
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {character}
    local expanded = size + Vector3.new(0.35, 0.35, 0.35)
    local parts = Workspace:GetPartBoundsInBox(cf, expanded, params)
    return #parts > 0
end

local function touchCheckAllPallets()
    if not DETECTION_ENABLED then
        return
    end
    local character = getCharacter()
    if not character then
        return
    end
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent and not PalletState[pallet] then
            if playerTouchesPallet(pallet) then
                activatePallet(pallet)
            end
        end
    end
end

local function maintainRuntime()
    cleanupDeadPallets()
    updateVisiblePalletEIK()
    refreshGrabLine()
end

local function setMenuVisible(visible)
    State.MenuVisible = visible == true
    pcall(function()
        Window:SetVisible(State.MenuVisible)
    end)
end

local function toggleMenuVisible()
    setMenuVisible(not State.MenuVisible)
end

local function makeColor(r, g, b)
    return Color3.fromRGB(math.clamp(math.floor(r or 0), 0, 255), math.clamp(math.floor(g or 0), 0, 255), math.clamp(math.floor(b or 0), 0, 255))
end

local function colorToTable(color)
    color = copyColor(color)
    return {
        R = color.R,
        G = color.G,
        B = color.B,
    }
end

local function tableToColor(value, fallback)
    if type(value) ~= "table" then
        return copyColor(fallback or Color3.new(1, 1, 1))
    end
    return Color3.new(
        clampNumber(value.R, 0, 1, 1),
        clampNumber(value.G, 0, 1, 1),
        clampNumber(value.B, 0, 1, 1)
    )
end

local function saveRuntimeSnapshot()
    State.Defaults.FOV = CurrentFOV
    State.Defaults.ClockTime = CurrentTime
    State.Defaults.Brightness = CurrentBrightness
    State.Defaults.Exposure = CurrentExposure
    State.Defaults.Ambient = copyColor(CurrentAmbient)
    State.Defaults.OutdoorAmbient = copyColor(CurrentOutdoorAmbient)
    State.Defaults.EIKText = EIK_TEXT
    State.Defaults.EIKScale = EIK_SCALE
    State.Defaults.EIKThickness = EIK_THICKNESS
    State.Defaults.EIKColor = copyColor(EIK_TEXT_COLOR)
end

local function restoreRuntimeSnapshot()
    local defaults = State.Defaults
    if defaults.FOV then
        CurrentFOV = defaults.FOV
    end
    if defaults.ClockTime then
        CurrentTime = defaults.ClockTime
    end
    if defaults.Brightness then
        CurrentBrightness = defaults.Brightness
    end
    if defaults.Exposure then
        CurrentExposure = defaults.Exposure
    end
    if defaults.Ambient then
        CurrentAmbient = copyColor(defaults.Ambient)
    end
    if defaults.OutdoorAmbient then
        CurrentOutdoorAmbient = copyColor(defaults.OutdoorAmbient)
    end
    if defaults.EIKText then
        EIK_TEXT = defaults.EIKText
    end
    if defaults.EIKScale then
        EIK_SCALE = defaults.EIKScale
    end
    if defaults.EIKThickness then
        EIK_THICKNESS = defaults.EIKThickness
    end
    if defaults.EIKColor then
        EIK_TEXT_COLOR = copyColor(defaults.EIKColor)
    end
    applyFOV()
    updateAllEIK()
end

saveRuntimeSnapshot()

local function EIKUtility_1(value)
    if value == nil then
        return 1
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 1)
    end
    return value
end

local function EIKUtility_2(value)
    if value == nil then
        return 2
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 2)
    end
    return value
end

local function EIKUtility_3(value)
    if value == nil then
        return 3
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 3)
    end
    return value
end

local function EIKUtility_4(value)
    if value == nil then
        return 4
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 4)
    end
    return value
end

local function EIKUtility_5(value)
    if value == nil then
        return 5
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 5)
    end
    return value
end

local function EIKUtility_6(value)
    if value == nil then
        return 6
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 6)
    end
    return value
end

local function EIKUtility_7(value)
    if value == nil then
        return 7
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 7)
    end
    return value
end

local function EIKUtility_8(value)
    if value == nil then
        return 8
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 8)
    end
    return value
end

local function EIKUtility_9(value)
    if value == nil then
        return 9
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 9)
    end
    return value
end

local function EIKUtility_10(value)
    if value == nil then
        return 10
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 10)
    end
    return value
end

local function EIKUtility_11(value)
    if value == nil then
        return 11
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 11)
    end
    return value
end

local function EIKUtility_12(value)
    if value == nil then
        return 12
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 12)
    end
    return value
end

local function EIKUtility_13(value)
    if value == nil then
        return 13
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 13)
    end
    return value
end

local function EIKUtility_14(value)
    if value == nil then
        return 14
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 14)
    end
    return value
end

local function EIKUtility_15(value)
    if value == nil then
        return 15
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 15)
    end
    return value
end

local function EIKUtility_16(value)
    if value == nil then
        return 16
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 16)
    end
    return value
end

local function EIKUtility_17(value)
    if value == nil then
        return 17
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 17)
    end
    return value
end

local function EIKUtility_18(value)
    if value == nil then
        return 18
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 18)
    end
    return value
end

local function EIKUtility_19(value)
    if value == nil then
        return 19
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 19)
    end
    return value
end

local function EIKUtility_20(value)
    if value == nil then
        return 20
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 20)
    end
    return value
end

local function EIKUtility_21(value)
    if value == nil then
        return 21
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 21)
    end
    return value
end

local function EIKUtility_22(value)
    if value == nil then
        return 22
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 22)
    end
    return value
end

local function EIKUtility_23(value)
    if value == nil then
        return 23
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 23)
    end
    return value
end

local function EIKUtility_24(value)
    if value == nil then
        return 24
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 24)
    end
    return value
end

local function EIKUtility_25(value)
    if value == nil then
        return 25
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 25)
    end
    return value
end

local function EIKUtility_26(value)
    if value == nil then
        return 26
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 26)
    end
    return value
end

local function EIKUtility_27(value)
    if value == nil then
        return 27
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 27)
    end
    return value
end

local function EIKUtility_28(value)
    if value == nil then
        return 28
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 28)
    end
    return value
end

local function EIKUtility_29(value)
    if value == nil then
        return 29
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 29)
    end
    return value
end

local function EIKUtility_30(value)
    if value == nil then
        return 30
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 30)
    end
    return value
end

local function EIKUtility_31(value)
    if value == nil then
        return 31
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 31)
    end
    return value
end

local function EIKUtility_32(value)
    if value == nil then
        return 32
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 32)
    end
    return value
end

local function EIKUtility_33(value)
    if value == nil then
        return 33
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 33)
    end
    return value
end

local function EIKUtility_34(value)
    if value == nil then
        return 34
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 34)
    end
    return value
end

local function EIKUtility_35(value)
    if value == nil then
        return 35
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 35)
    end
    return value
end

local function EIKUtility_36(value)
    if value == nil then
        return 36
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 36)
    end
    return value
end

local function EIKUtility_37(value)
    if value == nil then
        return 37
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 37)
    end
    return value
end

local function EIKUtility_38(value)
    if value == nil then
        return 38
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 38)
    end
    return value
end

local function EIKUtility_39(value)
    if value == nil then
        return 39
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 39)
    end
    return value
end

local function EIKUtility_40(value)
    if value == nil then
        return 40
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 40)
    end
    return value
end

local function EIKUtility_41(value)
    if value == nil then
        return 41
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 41)
    end
    return value
end

local function EIKUtility_42(value)
    if value == nil then
        return 42
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 42)
    end
    return value
end

local function EIKUtility_43(value)
    if value == nil then
        return 43
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 43)
    end
    return value
end

local function EIKUtility_44(value)
    if value == nil then
        return 44
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 44)
    end
    return value
end

local function EIKUtility_45(value)
    if value == nil then
        return 45
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 45)
    end
    return value
end

local function EIKUtility_46(value)
    if value == nil then
        return 46
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 46)
    end
    return value
end

local function EIKUtility_47(value)
    if value == nil then
        return 47
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 47)
    end
    return value
end

local function EIKUtility_48(value)
    if value == nil then
        return 48
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 48)
    end
    return value
end

local function EIKUtility_49(value)
    if value == nil then
        return 49
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 49)
    end
    return value
end

local function EIKUtility_50(value)
    if value == nil then
        return 50
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 50)
    end
    return value
end

local function EIKUtility_51(value)
    if value == nil then
        return 51
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 51)
    end
    return value
end

local function EIKUtility_52(value)
    if value == nil then
        return 52
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 52)
    end
    return value
end

local function EIKUtility_53(value)
    if value == nil then
        return 53
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 53)
    end
    return value
end

local function EIKUtility_54(value)
    if value == nil then
        return 54
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 54)
    end
    return value
end

local function EIKUtility_55(value)
    if value == nil then
        return 55
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 55)
    end
    return value
end

local function EIKUtility_56(value)
    if value == nil then
        return 56
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 56)
    end
    return value
end

local function EIKUtility_57(value)
    if value == nil then
        return 57
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 57)
    end
    return value
end

local function EIKUtility_58(value)
    if value == nil then
        return 58
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 58)
    end
    return value
end

local function EIKUtility_59(value)
    if value == nil then
        return 59
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 59)
    end
    return value
end

local function EIKUtility_60(value)
    if value == nil then
        return 60
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 60)
    end
    return value
end

local function EIKUtility_61(value)
    if value == nil then
        return 61
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 61)
    end
    return value
end

local function EIKUtility_62(value)
    if value == nil then
        return 62
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 62)
    end
    return value
end

local function EIKUtility_63(value)
    if value == nil then
        return 63
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 63)
    end
    return value
end

local function EIKUtility_64(value)
    if value == nil then
        return 64
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 64)
    end
    return value
end

local function EIKUtility_65(value)
    if value == nil then
        return 65
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 65)
    end
    return value
end

local function EIKUtility_66(value)
    if value == nil then
        return 66
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 66)
    end
    return value
end

local function EIKUtility_67(value)
    if value == nil then
        return 67
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 67)
    end
    return value
end

local function EIKUtility_68(value)
    if value == nil then
        return 68
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 68)
    end
    return value
end

local function EIKUtility_69(value)
    if value == nil then
        return 69
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 69)
    end
    return value
end

local function EIKUtility_70(value)
    if value == nil then
        return 70
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 70)
    end
    return value
end

local function EIKUtility_71(value)
    if value == nil then
        return 71
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 71)
    end
    return value
end

local function EIKUtility_72(value)
    if value == nil then
        return 72
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 72)
    end
    return value
end

local function EIKUtility_73(value)
    if value == nil then
        return 73
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 73)
    end
    return value
end

local function EIKUtility_74(value)
    if value == nil then
        return 74
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 74)
    end
    return value
end

local function EIKUtility_75(value)
    if value == nil then
        return 75
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 75)
    end
    return value
end

local function EIKUtility_76(value)
    if value == nil then
        return 76
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 76)
    end
    return value
end

local function EIKUtility_77(value)
    if value == nil then
        return 77
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 77)
    end
    return value
end

local function EIKUtility_78(value)
    if value == nil then
        return 78
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 78)
    end
    return value
end

local function EIKUtility_79(value)
    if value == nil then
        return 79
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 79)
    end
    return value
end

local function EIKUtility_80(value)
    if value == nil then
        return 80
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 80)
    end
    return value
end

local function EIKUtility_81(value)
    if value == nil then
        return 81
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 81)
    end
    return value
end

local function EIKUtility_82(value)
    if value == nil then
        return 82
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 82)
    end
    return value
end

local function EIKUtility_83(value)
    if value == nil then
        return 83
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 83)
    end
    return value
end

local function EIKUtility_84(value)
    if value == nil then
        return 84
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 84)
    end
    return value
end

local function EIKUtility_85(value)
    if value == nil then
        return 85
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 85)
    end
    return value
end

local function EIKUtility_86(value)
    if value == nil then
        return 86
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 86)
    end
    return value
end

local function EIKUtility_87(value)
    if value == nil then
        return 87
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 87)
    end
    return value
end

local function EIKUtility_88(value)
    if value == nil then
        return 88
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 88)
    end
    return value
end

local function EIKUtility_89(value)
    if value == nil then
        return 89
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 89)
    end
    return value
end

local function EIKUtility_90(value)
    if value == nil then
        return 90
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 90)
    end
    return value
end

local function EIKUtility_91(value)
    if value == nil then
        return 91
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 91)
    end
    return value
end

local function EIKUtility_92(value)
    if value == nil then
        return 92
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 92)
    end
    return value
end

local function EIKUtility_93(value)
    if value == nil then
        return 93
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 93)
    end
    return value
end

local function EIKUtility_94(value)
    if value == nil then
        return 94
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 94)
    end
    return value
end

local function EIKUtility_95(value)
    if value == nil then
        return 95
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 95)
    end
    return value
end

local function EIKUtility_96(value)
    if value == nil then
        return 96
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 96)
    end
    return value
end

local function EIKUtility_97(value)
    if value == nil then
        return 97
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 97)
    end
    return value
end

local function EIKUtility_98(value)
    if value == nil then
        return 98
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 98)
    end
    return value
end

local function EIKUtility_99(value)
    if value == nil then
        return 99
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 99)
    end
    return value
end

local function EIKUtility_100(value)
    if value == nil then
        return 100
    end
    if type(value) == "number" then
        return clampNumber(value, -100000, 100000, 100)
    end
    return value
end

task.spawn(function()
    while not State.Destroyed do
        if State.Enabled then
            touchCheckAllPallets()
            maintainRuntime()
        end
        task.wait(CHECK_INTERVAL)
    end
end)

BeamSection:AddToggle("BeamDetection",{Text="Beam Detection",Default=true,Callback=function(v) DETECTION_ENABLED=v if not v then restoreAll() end end})
BeamSection:AddSlider("CheckInterval",{Text="Check Interval",Default=CHECK_INTERVAL,Min=.03,Max=.3,Rounding=2,Suffix="s",Callback=function(v) CHECK_INTERVAL=v end})

local palletColorLabel=PalletColorSection:AddLabel("Grabbed Color")
palletColorLabel:AddColorPicker("PalletChangeColor",{Default=PALLET_CHANGE_COLOR,Title="Grabbed Color",Callback=function(v) PALLET_CHANGE_COLOR=v end})
PalletColorSection:AddButton({Text="Restore Pallet Colors",Func=restoreAll})

UtilitySection:AddButton({Text="Restore All",Func=restoreAll})
UtilitySection:AddButton({Text="Refresh EIK",Func=refreshAllEIK})

EIKSection:AddInput("EIKText",{Text="Custom Pallet Text",Default="EIK",Placeholder="EIK",Numeric=false,Finished=true,Callback=function(v) EIK_TEXT=tostring(v) if EIK_TEXT=="" then EIK_TEXT="EIK" end updateAllEIK() end})
EIKSection:AddSlider("EIKScale",{Text="Scale",Default=EIK_SCALE,Min=0,Max=100,Rounding=2,Callback=function(v) EIK_SCALE=v updateAllEIK() end})
EIKSection:AddSlider("EIKThickness",{Text="Thickness",Default=EIK_THICKNESS,Min=0,Max=10,Rounding=2,Callback=function(v) EIK_THICKNESS=v updateAllEIK() end})

local eikColorLabel=EIKSection:AddLabel("Text Color")
eikColorLabel:AddColorPicker("EIKTextColor",{Default=EIK_TEXT_COLOR,Title="Text Color",Callback=function(v) EIK_TEXT_COLOR=v for _,data in pairs(EIK_DATA) do if data.text then data.text.TextColor3=v end if data.stroke then data.stroke.Color=v end end end})

EIKSection:AddSlider("EIKPositionX",{Text="Position X",Default=EIK_X,Min=-5,Max=5,Rounding=2,Callback=function(v) EIK_X=v updateAllEIK() end})
EIKSection:AddSlider("EIKPositionY",{Text="Position Y",Default=EIK_Y,Min=-2,Max=2,Rounding=2,Callback=function(v) EIK_Y=v updateAllEIK() end})
EIKSection:AddSlider("EIKPositionZ",{Text="Position Z",Default=EIK_Z,Min=-5,Max=5,Rounding=2,Callback=function(v) EIK_Z=v updateAllEIK() end})
EIKSection:AddButton({Text="Reset EIK",Func=function()
    EIK_SCALE=1 EIK_THICKNESS=2 EIK_X=0 EIK_Y=0 EIK_Z=0 EIK_TEXT="EIK"
    if Options.EIKScale then Options.EIKScale:SetValue(1) end
    if Options.EIKThickness then Options.EIKThickness:SetValue(2) end
    if Options.EIKPositionX then Options.EIKPositionX:SetValue(0) end
    if Options.EIKPositionY then Options.EIKPositionY:SetValue(0) end
    if Options.EIKPositionZ then Options.EIKPositionZ:SetValue(0) end
    if Options.EIKText then Options.EIKText:SetValue("EIK") end
    updateAllEIK()
end})

CameraSection:AddSlider("FOV",{Text="FOV",Default=CurrentFOV,Min=50,Max=120,Rounding=0,Callback=function(v) CurrentFOV=v applyFOV() saveSettings() end})
CameraSection:AddButton({Text="Reset FOV",Func=function() CurrentFOV=DEFAULT_FOV if Options.FOV then Options.FOV:SetValue(DEFAULT_FOV) end applyFOV() saveSettings() end})

GrabLineSection:AddDropdown("GrabLineTexture",{Text="Texture",Values={"Low Quality","Non-Gamepass","Gamepass","Chain","Chain 2","Chain 3","Chain 4","Rope","Spring"},Default=CurrentGrabLineTexture,Multi=false,Callback=function(v) CurrentGrabLineTexture=v refreshGrabLine() end})
GrabLineUtilitySection:AddButton({Text="Refresh Grab Line",Func=refreshGrabLine})
GrabLineUtilitySection:AddButton({Text="Low Quality",Func=function() CurrentGrabLineTexture="Low Quality" if Options.GrabLineTexture then Options.GrabLineTexture:SetValue("Low Quality") end refreshGrabLine() end})

TimeSection:AddSlider("Time",{Text="Day Time",Default=CurrentTime,Min=0,Max=24,Rounding=1,Suffix="h",Callback=function(v) CurrentTime=v Lighting.ClockTime=v end})
TimeSection:AddButton({Text="Night Time",Func=function()
    CurrentTime=0 CurrentBrightness=.5 CurrentExposure=-1 CurrentAmbient=Color3.fromRGB(8,10,18) CurrentOutdoorAmbient=Color3.fromRGB(3,5,12)
    Lighting.ClockTime=0 Lighting.Brightness=.5 Lighting.ExposureCompensation=-1 Lighting.Ambient=CurrentAmbient Lighting.OutdoorAmbient=CurrentOutdoorAmbient
    local a=getAtmosphere() a.Color=Color3.fromRGB(20,25,50) a.Density=.2 a.Haze=1 a.Glare=0
    if Options.Time then Options.Time:SetValue(0) end
    if Options.Brightness then Options.Brightness:SetValue(.5) end
    if Options.Exposure then Options.Exposure:SetValue(-1) end
end})
TimeSection:AddButton({Text="Restore Lighting",Func=restoreLighting})

local skyLabel=LightingSection:AddLabel("Sky Color")
skyLabel:AddColorPicker("SkyColor",{Default=Color3.fromRGB(199,199,199),Title="Sky Color",Callback=function(v) getAtmosphere().Color=v end})
local ambientLabel=LightingSection:AddLabel("Ambient")
ambientLabel:AddColorPicker("Ambient",{Default=CurrentAmbient,Title="Ambient",Callback=function(v) CurrentAmbient=v Lighting.Ambient=v end})
local outdoorLabel=LightingSection:AddLabel("Outdoor Ambient")
outdoorLabel:AddColorPicker("OutdoorAmbient",{Default=CurrentOutdoorAmbient,Title="Outdoor Ambient",Callback=function(v) CurrentOutdoorAmbient=v Lighting.OutdoorAmbient=v end})
LightingSection:AddSlider("Brightness",{Text="Brightness",Default=CurrentBrightness,Min=0,Max=5,Rounding=2,Callback=function(v) CurrentBrightness=v Lighting.Brightness=v end})
LightingSection:AddSlider("Exposure",{Text="Exposure",Default=CurrentExposure,Min=-3,Max=3,Rounding=2,Callback=function(v) CurrentExposure=v Lighting.ExposureCompensation=v end})
LightingSection:AddSlider("AtmosphereDensity",{Text="Atmosphere Density",Default=0,Min=0,Max=1,Rounding=2,Callback=function(v) getAtmosphere().Density=v end})

VisualSettingsSection:AddToggle("GreySky",{Text="Grey Sky",Default=false,Callback=function(v) GreySkyEnabled=v applyGreySky() end})
VisualSettingsSection:AddButton({Text="Reset Visuals",Func=function() GreySkyEnabled=false if Toggles.GreySky then Toggles.GreySky:SetValue(false) end restoreLighting() end})
WeatherSection:AddToggle("Snow",{Text="Snow",Default=false,Callback=function(v) SnowEnabled=v updateSnow() end})
WeatherSection:AddSlider("SnowRange",{Text="Snow Range",Default=SnowRange,Min=0,Max=1000,Rounding=0,Suffix=" studs",Callback=function(v) SnowRange=v updateSnow() end})
WeatherSection:AddSlider("SnowAmount",{Text="Snow Amount",Default=SnowAmount,Min=0,Max=500,Rounding=0,Callback=function(v) SnowAmount=v updateSnow() end})
WeatherSection:AddSlider("SnowSpeed",{Text="Snow Speed",Default=SnowSpeed,Min=1,Max=30,Rounding=1,Callback=function(v) SnowSpeed=v updateSnow() end})

MenuKeySection:AddLabel("Menu Key"):AddKeyPicker("MenuKeybind",{Default="RightShift",Text="Menu Key",NoUI=false})
ScriptSection:AddButton({Text="Restore Everything",Func=function() DETECTION_ENABLED=true SnowEnabled=false GreySkyEnabled=false restoreAll() restoreLighting() if SnowEmitter then SnowEmitter.Enabled=false end end})
ScriptSection:AddButton({Text="Disable All & Close",Func=function()
    DETECTION_ENABLED=false SnowEnabled=false GreySkyEnabled=false restoreAll() restoreLighting()
    if SnowPart then SnowPart:Destroy() SnowPart=nil SnowEmitter=nil end
    pcall(function() Library:Unload() end)
end})

task.defer(function()
    local grabParts=Workspace:FindFirstChild("GrabParts")
    if grabParts then watchGrabParts(grabParts) end
    for pallet in pairs(Pallets) do if pallet and pallet.Parent then createEIK(pallet) end end
    refreshGrabLine()
end)

if type(Library.OnUnload) == "function" then
Library:OnUnload(function()
    DETECTION_ENABLED=false SnowEnabled=false restoreAll() restoreLighting()
    if SnowPart then SnowPart:Destroy() SnowPart=nil SnowEmitter=nil end
    for pallet in pairs(Pallets) do if pallet and pallet.Parent then destroyEIK(pallet) end end
    table.clear(EIK_DATA)
    table.clear(Pallets)
    table.clear(PalletState)
end)
end
