Workspace = game:GetService("Workspace")
Players = game:GetService("Players")
RunService = game:GetService("RunService")
TweenService = game:GetService("TweenService")
Lighting = game:GetService("Lighting")
HttpService = game:GetService("HttpService")

LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    error("i forgot")
end
ObsidianUrl = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"
if type(loadstring) ~= "function" then
    error("wrong environment, probably not use on executor only")
end
Library = nil
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(ObsidianUrl))()
    end)
    if not ok then
        error("obs failed to load" .. tostring(result))
    end
    Library = result
end
if type(Library) ~= "table" then
    error("invalid lib object")
end
if type(Library.CreateWindow) ~= "function" then
    error("is this the wrong obsidian library, probably not ignore this")
end

Options = Library.Options
Toggles = Library.Toggles

function requireMethod(object, name, label)
    local method = object and object[name]
    if type(method) ~= "function" then
        error("did i use the wrong api " .. label .. ": " .. name)
    end
    return method
end

okWindow, Window = pcall(function()
    return Library:CreateWindow({
        Title = "I love huracan",
        Footer = "h-h-hothuracan",
        Center = true,
        AutoShow = true,
        Resizable = true,
        ShowCustomCursor = true,
    })
end)
if not okWindow then
    error("CreateWindow failed " .. tostring(Window))
end
if not Window then
    error("CreateWindow returning nil")
end

function addTab(name, icon)
    requireMethod(Window, "AddTab", "Window:AddTab")
    local ok, tab = pcall(function()
        return Window:AddTab(name, icon)
    end)
    if not ok or not tab then
        error("creating a tab failed or something " .. name .. ": " .. tostring(tab))
    end
    return tab
end

function addGroup(tab, side, name)
    local preferred = side == "Left" and "AddLeftGroupbox" or "AddRightGroupbox"
    if type(tab[preferred]) == "function" then
        local ok, group = pcall(function()
            return tab[preferred](tab, name)
        end)
        if ok and group then
            return group
        end
    end
    requireMethod(tab, "AddGroupbox", "Tab:AddGroupbox")
    local ok, group = pcall(function()
        return tab:AddGroupbox({Side = side, Name = name})
    end)
    if not ok or not group then
        error("groupbox failed to create " .. name .. ": " .. tostring(group))
    end
    return group
end

MainTab = addTab("Main", "home")
SettingsTab = addTab("Misc", "settings")
TimeTab = addTab("Time", "sun")
VisualsTab = addTab("Visuals", "eye")
KeybindsTab = addTab("Keybinds", "keyboard")
MenuSettingsTab = addTab("Menu Settings", "settings")

BeamSection = addGroup(MainTab, "Left", "Detection")
PalletColorSection = addGroup(MainTab, "Left", "Pallet Color")
MaterialSection = addGroup(MainTab, "Right", "Pallet Material")
PalletTextSection = addGroup(MainTab, "Right", "Pallet Text")
UtilitySection = addGroup(MainTab, "Right", "Restore")

CameraSection = addGroup(SettingsTab, "Left", "Camera")
GrabLineSection = addGroup(SettingsTab, "Right", "Grab Line")

TimeSection = addGroup(TimeTab, "Left", "Time")
LightingSection = addGroup(TimeTab, "Right", "Sky & Lighting")

WeatherSection = addGroup(VisualsTab, "Left", "Weather")
VisualSettingsSection = addGroup(VisualsTab, "Right", "World Visuals")

MenuKeySection = addGroup(KeybindsTab, "Left", "Menu")
ScriptSection = addGroup(KeybindsTab, "Right", "Script")

TARGET_NAME = "PalletLightBrown"
NORMAL_COLOR = Color3.fromRGB(234, 215, 198)
PALLET_CHANGE_COLOR = Color3.fromRGB(0, 0, 0)
FADE_TIME = 0.22
RELEASE_CONFIRM_TIME = 0.12
CHECK_INTERVAL = 0.08
DETECTION_ENABLED = true

PalletText_SCALE = 1
PalletText_X = 0
PalletText_Y = 0
PalletText_Z = 0
PalletText_THICKNESS = 2
PalletText_TEXT = "Pallet"
PalletText_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
PalletText_FONT = Enum.Font.GothamBlack
FontNames={}
for _,font in ipairs(Enum.Font:GetEnumItems()) do table.insert(FontNames,font.Name) end
table.sort(FontNames)
PalletTransparency = 0
PalletColorFadeIn = true
PalletMaterialFadeIn = false
PalletColorFadeInTime = 0.22
PalletMaterialFadeInTime = 0.5
PalletColorFadeOut = true
PalletMaterialFadeOut = true
PalletColorFadeOutTime = 0.22
PalletMaterialFadeOutTime = 0.5

DEFAULT_FOV = 70
CurrentFOV = DEFAULT_FOV
CurrentTime = Lighting.ClockTime
CurrentBrightness = Lighting.Brightness
CurrentExposure = Lighting.ExposureCompensation
CurrentAmbient = Lighting.Ambient
CurrentOutdoorAmbient = Lighting.OutdoorAmbient
PalletGlowOnGrab=false
PlayerAutoHideUI=false
PlayerOriginalFOV=nil
PlayerLowHealthEffect=nil

GreySkyEnabled = false
SnowEnabled = false
SnowRange = 100
SnowAmount = 150
SnowSpeed = 12
VignetteEnabled = false
CameraSwayEnabled = false
CameraSwayAmount = 1.2
CameraSwaySpeed = 1.5
NightModeEnabled = false
AutoRestoreOnRelease = false
PalletPulseEnabled = false
PalletPulseSpeed = 2
PalletRainbowEnabled = false
PalletRainbowSpeed = 1
PalletTextOnlyVisible = true
PalletTextOnlyOwnPallet = false
PalletTextBillboard = false
GrabLineWidth = 0.35
GrabLineTextureSpeed = -4
GrabLineTextureLength = 2
GrabLineSegments = 20
GrabLineBrightness = 1
GrabLineFaceCamera = true
GrabLineAutoApply = false
GrabLinePulse = false
TimeLockEnabled = false
TimeLockSpeed = 0
TimeAmbientIntensity = 1
TimeOutdoorIntensity = 1
TimeAtmosphereHaze = 0
TimeAtmosphereGlare = 0
TimeAtmosphereDensity = 0
FullbrightSaved = false
PalletGlowColor = Color3.fromRGB(255,210,80)
PalletGlowFill = 0.65
PalletGlowOutline = 0
FullbrightEnabled = false
FogDisabled = false
OriginalFog = nil

Pallets = {}
PalletState = {}
OriginalPalletState = {}
MaterialFadeOverlays = {}
MaterialAlwaysOn = false
RemovePalletText = false
DontChangePalletColor = false
PalletMaterial = "WoodPlanks"
PalletGlowEnabled = false
SunRaysIntensity = 0.08
SunRaysSpread = 0.5
PalletText_DATA = {}
BeamPart = nil
CurrentBeam = nil
SnowPart = nil
SnowEmitter = nil

SETTINGS_FILE = "ftapVIS.json"

OriginalLighting = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    ExposureCompensation = Lighting.ExposureCompensation,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

OriginalAtmosphereObject = Lighting:FindFirstChildOfClass("Atmosphere")
OriginalAtmosphere = OriginalAtmosphereObject and {
    Object = OriginalAtmosphereObject,
    Color = OriginalAtmosphereObject.Color,
    Decay = OriginalAtmosphereObject.Decay,
    Density = OriginalAtmosphereObject.Density,
    Haze = OriginalAtmosphereObject.Haze,
    Glare = OriginalAtmosphereObject.Glare,
}

function loadSettings()
    if not isfile or not readfile or not isfile(SETTINGS_FILE) then return end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(SETTINGS_FILE))
    end)
    if ok and type(data) == "table" and type(data.FOV) == "number" then
        CurrentFOV = math.clamp(data.FOV, 50, 120)
    end
end

function saveSettings()
    if not writefile then return end
    pcall(function()
        writefile(SETTINGS_FILE, HttpService:JSONEncode({FOV = CurrentFOV}))
    end)
end

loadSettings()

function applyFOV()
    local camera = Workspace.CurrentCamera
    if camera then camera.FieldOfView = CurrentFOV end
end

applyFOV()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() task.defer(applyFOV) end)

function getBeamPart()
    local grabParts = Workspace:FindFirstChild("GrabParts")
    if not grabParts then return nil end
    local beamPart = grabParts:FindFirstChild("BeamPart")
    return beamPart and beamPart:IsA("BasePart") and beamPart or nil
end

function getGrabBeam()
    local beamPart = getBeamPart()
    if not beamPart then return nil end
    local beam = beamPart:FindFirstChild("GrabBeam")
    return beam and beam:IsA("Beam") and beam or nil
end

GrabLinePresets = {
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

CurrentGrabLineTexture = "Low Quality"
CurrentGrabLineColor = Color3.fromRGB(255,255,255)
GrabLineModified = false
OriginalBeamState = nil
OriginalBeamInstance = nil

function captureBeamState(beam, force)
    if not beam or not beam:IsA("Beam") then return end
    if not force and OriginalBeamState and OriginalBeamInstance == beam then return end
    local state={}
    local props={"Texture","TextureMode","TextureLength","TextureSpeed","LightEmission","LightInfluence","Segments","Width0","Width1","Transparency","Color","FaceCamera","Enabled","Brightness","CurveSize0","CurveSize1","ZOffset"}
    for _,name in ipairs(props) do
        local ok,value=pcall(function() return beam[name] end)
        if ok then state[name]=value end
    end
    OriginalBeamState=state
    OriginalBeamInstance=beam
end

function restoreOriginalBeam()
    local beam=getGrabBeam()
    if not beam then return false end
    if OriginalBeamInstance ~= beam then
        captureBeamState(beam, true)
        return false
    end
    if not OriginalBeamState then
        captureBeamState(beam, true)
        return false
    end
    for name,value in pairs(OriginalBeamState) do pcall(function() beam[name]=value end) end
    GrabLineModified=false
    return true
end

function applyBeamSettings(beam, settings)
    if not beam or not beam.Parent then return end
    captureBeamState(beam, false)
    beam.Texture = settings.Texture
    beam.TextureMode = Enum.TextureMode.Wrap
    beam.TextureLength = GrabLineTextureLength ~= nil and GrabLineTextureLength or settings.TextureLength
    beam.TextureSpeed = GrabLineTextureSpeed ~= nil and GrabLineTextureSpeed or settings.TextureSpeed
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Segments = GrabLineSegments ~= nil and GrabLineSegments or settings.Segments
    beam.Width0 = GrabLineWidth ~= nil and GrabLineWidth or settings.Width0
    beam.Width1 = GrabLineWidth ~= nil and GrabLineWidth or settings.Width1
    beam.Transparency = settings.Transparency
    beam.Color = ColorSequence.new(copyColor(CurrentGrabLineColor))
    beam.FaceCamera = GrabLineFaceCamera
    beam.Brightness = GrabLineBrightness
    GrabLineModified=true
end

function setGrabLineColor(color)
    CurrentGrabLineColor = copyColor(color)
    local beam = getGrabBeam()
    if beam and GrabLineModified then
        beam.Color = ColorSequence.new(copyColor(CurrentGrabLineColor))
    end
end

function applySelectedGrabLine()
    local beam=getGrabBeam()
    if not beam then return false end
    captureBeamState(beam, false)
    local preset=GrabLinePresets[CurrentGrabLineTexture]
    if not preset then return false end
    applyBeamSettings(beam,preset)
    return true
end

function refreshGrabLine()
    local beam=getGrabBeam()
    if not beam then return false end
    if OriginalBeamInstance ~= beam or not OriginalBeamState then
        captureBeamState(beam,true)
        GrabLineModified=false
    end
    return restoreOriginalBeam()
end

function watchGrabParts(grabParts)
    if not grabParts then return end
    task.spawn(function()
        local beamPart = grabParts:WaitForChild("BeamPart", 5)
        if not beamPart then return end
        local beam = beamPart:WaitForChild("GrabBeam", 5)
        if beam then task.defer(function() BeamPart=beamPart CurrentBeam=beam captureBeamState(beam,true) if GrabLineModified then applySelectedGrabLine() end end) end
    end)
end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "GrabParts" then watchGrabParts(child) end
end)
Workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "GrabParts" or obj.Name == "BeamPart" or obj.Name == "GrabBeam" then task.defer(function() local beam=getGrabBeam() if beam then captureBeamState(beam,true) if GrabLineModified then applySelectedGrabLine() end end end) end
end)
Workspace.DescendantRemoving:Connect(function(obj)
    if obj == CurrentBeam or obj == BeamPart or obj.Name == "GrabBeam" or obj.Name == "BeamPart" or obj.Name == "GrabParts" then task.defer(function() local beam=getGrabBeam() if beam then captureBeamState(beam,true) if GrabLineModified then applySelectedGrabLine() end end end) end
end)

function isPallet(instance)
    return instance and instance:IsA("Model") and instance.Name == TARGET_NAME
end

function getPalletFromPart(part)
    if not part then return nil end
    local current = part
    while current and current ~= Workspace do
        if current:IsA("Model") and current.Name == TARGET_NAME then return current end
        current = current.Parent
    end
end

function findTopPart(pallet)
    local bestPart
    local bestArea = -math.huge
    for _, obj in ipairs(pallet:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:GetAttribute("PalletText_Carrier") and not obj:GetAttribute("PalletMaterialFadeOverlay") then
            local area = obj.Size.X * obj.Size.Z
            if area > bestArea then bestArea, bestPart = area, obj end
        end
    end
    return bestPart
end

function getBaseParts(pallet)
    local parts = {}
    for _, obj in ipairs(pallet:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:GetAttribute("PalletText_Carrier") and not obj:GetAttribute("PalletMaterialFadeOverlay") then table.insert(parts, obj) end
    end
    return parts
end

function destroyPalletText(pallet)
    local data = PalletText_DATA[pallet]
    if data then
        if data.carrier and data.carrier.Parent then data.carrier:Destroy() end
        PalletText_DATA[pallet] = nil
    end
    local old = pallet:FindFirstChild("PalletText_Carrier")
    if old then old:Destroy() end
end

function updatePalletText(pallet)
    if RemovePalletText then
        destroyPalletText(pallet)
        return
    end
    local data = PalletText_DATA[pallet]
    if not data or not data.carrier or not data.carrier.Parent or not data.weld or not data.weld.Parent then return end
    local topPart = data.topPart
    if not topPart or not topPart.Parent then return end
    data.weld.C0 = CFrame.new(PalletText_X, (topPart.Size.Y / 2) + .02 + PalletText_Y, PalletText_Z)
    data.uiScale.Scale = PalletText_SCALE
    data.text.Text = PalletText_TEXT
    data.text.TextColor3 = PalletText_TEXT_COLOR
    data.text.Font = PalletText_FONT
    data.stroke.Thickness = PalletText_THICKNESS
    data.text.BackgroundColor3 = Color3.new(0,0,0)
    data.text.BackgroundTransparency = 1
    data.surface.AlwaysOnTop = not PalletTextOnlyVisible
    local show=true
    if PalletTextOnlyOwnPallet then
        local state=PalletState[pallet]
        show=state and state.touching==true or false
    end
    if show and PalletTextOnlyVisible and type(isPalletVisibleFromCamera)=="function" then
        show=isPalletVisibleFromCamera(pallet,data.carrier)
    end
    data.text.Visible=show
end

function createPalletText(pallet)
    if not pallet or not pallet.Parent then return end
    if RemovePalletText then
        destroyPalletText(pallet)
        return
    end
    local topPart = findTopPart(pallet)
    if not topPart then return end
    local oldData = PalletText_DATA[pallet]
    if oldData and oldData.topPart == topPart and oldData.carrier and oldData.carrier.Parent then updatePalletText(pallet) return end
    destroyPalletText(pallet)

    local carrier = Instance.new("Part")
    carrier.Name = "PalletText_Carrier"
    carrier:SetAttribute("PalletText_Carrier", true)
    carrier.Size = Vector3.new(math.max(topPart.Size.X,.1),.025,math.max(topPart.Size.Z,.1))
    carrier.Transparency = 1
    carrier.CanCollide = false
    carrier.CanTouch = false
    carrier.CanQuery = false
    carrier.CastShadow = false
    carrier.Massless = true
    carrier.Anchored = false
    carrier.CFrame = topPart.CFrame * CFrame.new(PalletText_X,(topPart.Size.Y/2)+.02+PalletText_Y,PalletText_Z)
    carrier.Parent = pallet

    local weld = Instance.new("Weld")
    weld.Name = "PalletText_Weld"
    weld.Part0 = topPart
    weld.Part1 = carrier
    weld.C0 = CFrame.new(PalletText_X,(topPart.Size.Y/2)+.02+PalletText_Y,PalletText_Z)
    weld.C1 = CFrame.new()
    weld.Parent = carrier

    local surface = Instance.new("SurfaceGui")
    surface.Name = "PalletText_Surface"
    surface.Face = Enum.NormalId.Top
    surface.AlwaysOnTop = true
    surface.LightInfluence = 0
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 100
    surface.Parent = carrier

    local text = Instance.new("TextLabel")
    text.Name = "PalletText"
    text.AnchorPoint = Vector2.new(.5,.5)
    text.Position = UDim2.fromScale(.5,.5)
    text.Size = UDim2.fromScale(.72,.72)
    text.BackgroundTransparency = 1
    text.Text = PalletText_TEXT
    text.TextColor3 = PalletText_TEXT_COLOR
    text.Font = PalletText_FONT
    text.TextScaled = true
    text.TextWrapped = false
    text.Parent = surface

    local stroke = Instance.new("UIStroke")
    stroke.Name = "PalletTextStroke"
    stroke.Thickness = PalletText_THICKNESS
    stroke.Color = PalletText_TEXT_COLOR
    stroke.Parent = text

    local uiScale = Instance.new("UIScale")
    uiScale.Name = "PalletTextScale"
    uiScale.Scale = PalletText_SCALE
    uiScale.Parent = text

    PalletText_DATA[pallet] = {pallet=pallet,topPart=topPart,carrier=carrier,weld=weld,text=text,stroke=stroke,uiScale=uiScale,surface=surface}
    updatePalletText(pallet)
end

function refreshAllPalletText()
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then
            destroyPalletText(pallet)
            if not RemovePalletText then task.defer(createPalletText,pallet) end
        end
    end
end

function setRemovePalletText(value)
    RemovePalletText=value==true
    if RemovePalletText then
        for pallet in pairs(Pallets) do
            if pallet and pallet.Parent then destroyPalletText(pallet) end
        end
    else
        refreshAllPalletText()
    end
end

function rebuildPalletText()
    PalletText_TEXT="Pallet"
    if Options and Options.PalletTextText then pcall(function() Options.PalletTextText:SetValue("Pallet") end) end
    refreshAllPalletText()
end

function updateAllPalletText()
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then updatePalletText(pallet) end
    end
end

function tweenPalletColor(pallet,color,duration,onComplete)
    if not pallet or not pallet.Parent then return end
    local state=PalletState[pallet]
    if not state then return end
    state.tweenId=state.tweenId+1
    local id=state.tweenId
    duration=math.max(0,tonumber(duration) or 0)
    if duration<=0 then
        for _,part in ipairs(getBaseParts(pallet)) do
            if part and part.Parent then part.Color=copyColor(color) end
        end
        if onComplete then onComplete() end
        return
    end
    local tweens={}
    for _,part in ipairs(getBaseParts(pallet)) do
        if part and part.Parent then
            tweens[#tweens+1]=TweenService:Create(part,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Color=copyColor(color)})
            tweens[#tweens]:Play()
        end
    end
    task.delay(duration+.03,function()
        local latest=PalletState[pallet]
        if not latest or latest.tweenId~=id or not pallet.Parent then return end
        for _,part in ipairs(getBaseParts(pallet)) do
            if part and part.Parent then part.Color=copyColor(color) end
        end
        if onComplete then onComplete() end
    end)
end

function destroyMaterialFadeOverlays(pallet)
    local list=MaterialFadeOverlays[pallet]
    if list then
        for _,overlay in ipairs(list) do
            if overlay and overlay.Parent then overlay:Destroy() end
        end
    end
    MaterialFadeOverlays[pallet]=nil
end

function makeMaterialFadeOverlay(pallet,part,material,color)
    if not part or not part.Parent then return nil end
    local overlay
    local ok=pcall(function() overlay=part:Clone() end)
    if not ok or not overlay then return nil end
    for _,child in ipairs(overlay:GetChildren()) do
        if not (child:IsA("SpecialMesh") or child:IsA("SurfaceAppearance") or child:IsA("Texture") or child:IsA("Decal")) then
            child:Destroy()
        end
    end
    overlay.Name="PalletMaterialFadeOverlay"
    overlay:SetAttribute("PalletMaterialFadeOverlay",true)
    overlay.Material=material
    overlay.MaterialVariant=""
    overlay.Color=copyColor(color)
    overlay.Transparency=1
    overlay.LocalTransparencyModifier=0
    overlay.CanCollide=false
    overlay.CanTouch=false
    overlay.CanQuery=false
    overlay.Massless=true
    overlay.CastShadow=false
    overlay.Anchored=false
    -- Put the temporary surface just outside the real one to prevent z-fighting.
    overlay.Size=part.Size+Vector3.new(.01,.01,.01)
    overlay.CFrame=part.CFrame
    overlay.Parent=pallet
    local weld=Instance.new("WeldConstraint")
    weld.Part0=part
    weld.Part1=overlay
    weld.Parent=overlay
    return overlay
end

function startMaterialFadeIn(pallet,duration)
    local state=PalletState[pallet]
    local original=OriginalPalletState[pallet]
    local material=Enum.Material[PalletMaterial]
    if not pallet or not pallet.Parent or not state or not original or not material then return end
    state.materialFadeId=(state.materialFadeId or 0)+1
    local id=state.materialFadeId
    destroyMaterialFadeOverlays(pallet)
    if duration<=0 then
        for part in pairs(original.Parts) do
            if part and part.Parent then part.Material=material part.MaterialVariant="" end
        end
        return
    end
    local list={}
    MaterialFadeOverlays[pallet]=list
    for part,values in pairs(original.Parts) do
        if part and part.Parent then
            local overlayColor=DontChangePalletColor and part.Color or PALLET_CHANGE_COLOR
            local overlay=makeMaterialFadeOverlay(pallet,part,material,overlayColor)
            if overlay then
                list[#list+1]=overlay
                TweenService:Create(overlay,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transparency=values.Transparency}):Play()
            else
                part.Material=material
                part.MaterialVariant=""
            end
        end
    end
    task.delay(duration,function()
        local latest=PalletState[pallet]
        if not latest or latest.materialFadeId~=id or not latest.touching or not pallet.Parent then return end
        for part in pairs(original.Parts) do
            if part and part.Parent then part.Material=material part.MaterialVariant="" end
        end
        RunService.RenderStepped:Wait()
        latest=PalletState[pallet]
        if not latest or latest.materialFadeId~=id or not latest.touching then return end
        destroyMaterialFadeOverlays(pallet)
    end)
end

function startMaterialFadeOut(pallet,duration,releaseId)
    local state=PalletState[pallet]
    local original=OriginalPalletState[pallet]
    if not pallet or not pallet.Parent or not state or not original then return end
    state.materialFadeId=(state.materialFadeId or 0)+1
    local id=state.materialFadeId
    destroyMaterialFadeOverlays(pallet)
    if duration<=0 then
        for part,values in pairs(original.Parts) do
            if part and part.Parent then part.Material=values.Material part.MaterialVariant=values.MaterialVariant end
        end
        return
    end
    local list={}
    MaterialFadeOverlays[pallet]=list
    for part,values in pairs(original.Parts) do
        if part and part.Parent then
            local overlay=makeMaterialFadeOverlay(pallet,part,part.Material,part.Color)
            if overlay then
                overlay.Transparency=part.Transparency
                list[#list+1]=overlay
                TweenService:Create(overlay,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transparency=1}):Play()
            end
            part.Material=values.Material
            part.MaterialVariant=values.MaterialVariant
        end
    end
    task.delay(duration,function()
        local latest=PalletState[pallet]
        if not latest or latest.materialFadeId~=id or latest.touching or latest.tweenId~=releaseId or not pallet.Parent then return end
        destroyMaterialFadeOverlays(pallet)
    end)
end

function applyGrabbedPalletMaterial(pallet)
    if not pallet or not pallet.Parent then return end
    local state=PalletState[pallet]
    if not state or not state.touching then return end
    rememberPalletState(pallet)
    local material=Enum.Material[PalletMaterial]
    if not material then return end
    destroyMaterialFadeOverlays(pallet)
    for _,part in ipairs(getBaseParts(pallet)) do
        if part and part.Parent then part.Material=material part.MaterialVariant="" end
    end
end

function restoreOriginalMaterialOnly(pallet)
    local original=OriginalPalletState[pallet]
    if not original then return end
    for part,values in pairs(original.Parts) do
        if part and part.Parent then part.Material=values.Material part.MaterialVariant=values.MaterialVariant end
    end
end

function applyGrabbedEffects(pallet)
    if not pallet or not pallet.Parent then return end
    local state=PalletState[pallet]
    if not state or not state.touching then return end
    rememberPalletState(pallet)
    state.targetColor=DontChangePalletColor and nil or copyColor(PALLET_CHANGE_COLOR)
    state.materialFadeId=(state.materialFadeId or 0)+1
    destroyMaterialFadeOverlays(pallet)
    if MaterialAlwaysOn then
        applyPalletMaterial(pallet,PalletMaterial)
    else
        startMaterialFadeIn(pallet,PalletMaterialFadeInTime)
    end
    if DontChangePalletColor then
        local original=OriginalPalletState[pallet]
        if original then
            for part,values in pairs(original.Parts) do
                if part and part.Parent then part.Color=copyColor(values.Color) end
            end
        end
    else
        tweenPalletColor(pallet,PALLET_CHANGE_COLOR,PalletColorFadeInTime)
    end
end

function restorePallet(pallet)
    if not pallet or not pallet.Parent then return end
    local state=PalletState[pallet]
    if state then
        state.releaseTime=nil
        state.touching=false
        state.targetColor=nil
        state.tweenId=state.tweenId+1
        state.materialFadeId=(state.materialFadeId or 0)+1
    end
    local original=OriginalPalletState[pallet]
    if not original then return end
    destroyMaterialFadeOverlays(pallet)
    local releaseId=state and state.tweenId or 0

    if MaterialAlwaysOn then
        applyPalletMaterial(pallet,PalletMaterial)
    elseif PalletMaterialFadeOutTime>0 then
        startMaterialFadeOut(pallet,PalletMaterialFadeOutTime,releaseId)
    else
        restoreOriginalMaterialOnly(pallet)
    end

    for part,values in pairs(original.Parts) do
        if part and part.Parent then
            safeSet(part,"Transparency",values.Transparency)
            safeSet(part,"LocalTransparencyModifier",values.LocalTransparencyModifier)
            safeSet(part,"Reflectance",values.Reflectance)
        end
    end

    if DontChangePalletColor or PalletColorFadeOutTime<=0 then
        for part,values in pairs(original.Parts) do
            if part and part.Parent then part.Color=copyColor(values.Color) end
        end
    else
        for part,values in pairs(original.Parts) do
            if part and part.Parent then
                TweenService:Create(part,TweenInfo.new(PalletColorFadeOutTime,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Color=copyColor(values.Color)}):Play()
            end
        end
        task.delay(PalletColorFadeOutTime+.03,function()
            local latest=PalletState[pallet]
            if not latest or latest.touching or latest.tweenId~=releaseId or not pallet.Parent then return end
            for part,values in pairs(original.Parts) do
                if part and part.Parent then part.Color=copyColor(values.Color) end
            end
        end)
    end
end

function setMaterialAlwaysOn(value)
    MaterialAlwaysOn=value==true
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then
            local state=PalletState[pallet]
            if state then state.materialFadeId=(state.materialFadeId or 0)+1 end
            destroyMaterialFadeOverlays(pallet)
            if MaterialAlwaysOn then
                applyPalletMaterial(pallet,PalletMaterial)
            elseif state and state.touching then
                applyGrabbedEffects(pallet)
            else
                restoreOriginalMaterialOnly(pallet)
            end
        end
    end
end

function setDontChangePalletColor(value)
    DontChangePalletColor=value==true
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then
            local state=PalletState[pallet]
            local original=OriginalPalletState[pallet]
            if DontChangePalletColor and original then
                if state then state.tweenId=state.tweenId+1 state.targetColor=nil end
                for part,values in pairs(original.Parts) do
                    if part and part.Parent then part.Color=copyColor(values.Color) end
                end
            elseif state and state.touching then
                tweenPalletColor(pallet,PALLET_CHANGE_COLOR,PalletColorFadeInTime)
            end
        end
    end
end

function setPalletMaterialSelection(value)
    local name=tostring(value or "WoodPlanks")
    if not Enum.Material[name] then return end
    PalletMaterial=name
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then
            local state=PalletState[pallet]
            if state then state.materialFadeId=(state.materialFadeId or 0)+1 end
            destroyMaterialFadeOverlays(pallet)
            if MaterialAlwaysOn then
                applyPalletMaterial(pallet,PalletMaterial)
            elseif state and state.touching then
                applyGrabbedEffects(pallet)
            else
                restoreOriginalMaterialOnly(pallet)
            end
        end
    end
end

function setPalletFadeSettings()
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then
            local state=PalletState[pallet]
            if state and state.touching then applyGrabbedEffects(pallet) end
        end
    end
end

function restoreAll()
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then restorePallet(pallet) end
    end
end

function registerPallet(pallet)
    if not isPallet(pallet) or Pallets[pallet] then return end
    Pallets[pallet]=true
    PalletState[pallet]={touching=false,releaseTime=nil,targetColor=nil,tweenId=0}
    rememberPalletState(pallet)
    task.defer(function() if pallet and pallet.Parent then createPalletText(pallet) updatePalletGlow() end end)
end

function unregisterPallet(pallet)
    if not Pallets[pallet] then return end
    destroyPalletText(pallet)
    Pallets[pallet]=nil
    PalletState[pallet]=nil
end

task.defer(function() for _, obj in ipairs(Workspace:GetDescendants()) do if isPallet(obj) then registerPallet(obj) end end end)

Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") and obj.Name==TARGET_NAME then task.defer(function() registerPallet(obj) end) return end
    if obj:IsA("BasePart") and not obj:GetAttribute("PalletMaterialFadeOverlay") then
        local pallet=getPalletFromPart(obj)
        if pallet and Pallets[pallet] then task.defer(function() if pallet.Parent then createPalletText(pallet) end end) end
    end
end)

Workspace.DescendantRemoving:Connect(function(obj)
    if Pallets[obj] then unregisterPallet(obj) return end
    if obj:IsA("BasePart") and not obj:GetAttribute("PalletMaterialFadeOverlay") then
        local pallet=getPalletFromPart(obj)
        if pallet and Pallets[pallet] then task.defer(function() if pallet.Parent then createPalletText(pallet) end end) end
    end
end)

overlapParams=OverlapParams.new()
overlapParams.FilterType=Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances={Workspace}

function getOverlappingPallets()
    local result={}
    if not BeamPart or not BeamPart.Parent then BeamPart=getBeamPart() end
    if not BeamPart then return result end
    local size=BeamPart.Size+Vector3.new(.35,.35,.35)
    local ok,parts=pcall(function() return Workspace:GetPartBoundsInBox(BeamPart.CFrame,size,overlapParams) end)
    if not ok or type(parts)~="table" then return result end
    for _,part in ipairs(parts) do
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
                            if not state.touching then activatePallet(pallet) elseif state.targetColor~=PALLET_CHANGE_COLOR then applyGrabbedEffects(pallet) end
                        elseif state.touching then
                            state.releaseTime=state.releaseTime or now
                            if now-state.releaseTime>=RELEASE_CONFIRM_TIME then
                                restorePallet(pallet)
                            end
                        end
                    end
                end
            end
        end
        task.wait(CHECK_INTERVAL)
    end
end)

function getAtmosphere()
    local atmosphere=Lighting:FindFirstChild("Pallet_Atmosphere")
    if atmosphere and atmosphere:IsA("Atmosphere") then return atmosphere end
    atmosphere=Instance.new("Atmosphere")
    atmosphere.Name="Pallet_Atmosphere"
    atmosphere.Parent=Lighting
    return atmosphere
end

function restoreLighting()
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
        local a=Lighting:FindFirstChild("Pallet_Atmosphere")
        if a then a:Destroy() end
    end
end

function applyGreySky()
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

function updateSnow()
    if not SnowPart or not SnowPart.Parent then
        SnowPart=Instance.new("Part")
        SnowPart.Name="Pallet_Snow"
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

State = {
    Enabled = true,
    MenuVisible = true,
    Destroyed = false,
    Connections = {},
    CreatedInstances = {},
    Defaults = {},
    Runtime = {},
}

function pushConnection(connection)
    if connection then
        table.insert(State.Connections, connection)
    end
    return connection
end

function trackInstance(instance)
    if instance then
        table.insert(State.CreatedInstances, instance)
    end
    return instance
end

function disconnectAll()
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

function destroyTrackedInstances()
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

function safeSet(instance, property, value)
    if not instance then
        return false
    end
    local ok = pcall(function()
        instance[property] = value
    end)
    return ok
end

function safeGet(instance, property, fallback)
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

function clampNumber(value, minimum, maximum, fallback)
    value = tonumber(value)
    if not value then
        value = fallback or minimum
    end
    return math.clamp(value, minimum, maximum)
end

function copyColor(color)
    if typeof(color) ~= "Color3" then
        return Color3.new(1, 1, 1)
    end
    return Color3.new(color.R, color.G, color.B)
end

function copyColorSequence(sequence)
    if typeof(sequence) ~= "ColorSequence" then
        return ColorSequence.new(Color3.new(1, 1, 1))
    end
    local points = {}
    for _, point in ipairs(sequence.Keypoints) do
        table.insert(points, ColorSequenceKeypoint.new(point.Time, copyColor(point.Value)))
    end
    return ColorSequence.new(points)
end

function copyNumberSequence(sequence)
    if typeof(sequence) ~= "NumberSequence" then
        return NumberSequence.new(0)
    end
    local points = {}
    for _, point in ipairs(sequence.Keypoints) do
        table.insert(points, NumberSequenceKeypoint.new(point.Time, point.Value, point.Envelope))
    end
    return NumberSequence.new(points)
end

function vectorMagnitude(vector)
    if typeof(vector) ~= "Vector3" then
        return 0
    end
    return vector.Magnitude
end

function getCamera()
    return Workspace.CurrentCamera
end

function getCharacter()
    return LocalPlayer.Character
end

function getHumanoid()
    local character = getCharacter()
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end

function getRootPart()
    local character = getCharacter()
    if not character then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart")
end

function getPalletDistance(pallet)
    local root = getRootPart()
    local target = pallet and pallet.PrimaryPart
    if not root or not target then
        return math.huge
    end
    return vectorMagnitude(root.Position - target.Position)
end

function isValidInstance(instance)
    return instance ~= nil and instance.Parent ~= nil
end

function isBasePart(instance)
    return instance ~= nil and instance:IsA("BasePart")
end

function isTextLabel(instance)
    return instance ~= nil and instance:IsA("TextLabel")
end

function getOrCreateFolder(parent, name)
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

function getOrCreateBoolValue(parent, name, value)
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

function getOrCreateNumberValue(parent, name, value)
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

function getOrCreateStringValue(parent, name, value)
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

function setAttributeSafe(instance, name, value)
    if not instance then
        return false
    end
    local ok = pcall(function()
        instance:SetAttribute(name, value)
    end)
    return ok
end

function getAttributeSafe(instance, name, fallback)
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

function setPalletTextLabelText(label, text)
    if not isTextLabel(label) then
        return
    end
    label.Text = tostring(text or "PalletText")
end

function setPalletTextLabelColor(label, color)
    if not isTextLabel(label) then
        return
    end
    label.TextColor3 = copyColor(color)
end

function setPalletTextLabelStroke(label, thickness, color)
    if not isTextLabel(label) then
        return
    end
    local stroke = label:FindFirstChild("PalletTextStroke")
    if not stroke then
        stroke = trackInstance(Instance.new("UIStroke"))
        stroke.Name = "PalletTextStroke"
        stroke.Parent = label
    end
    stroke.Thickness = clampNumber(thickness, 0, 10, 2)
    stroke.Color = copyColor(color or label.TextColor3)
    stroke.Transparency = 0
end

function setPalletTextScale(label, scale)
    if not isTextLabel(label) then
        return
    end
    local uiScale = label:FindFirstChild("PalletTextScale")
    if not uiScale then
        uiScale = trackInstance(Instance.new("UIScale"))
        uiScale.Name = "PalletTextScale"
        uiScale.Parent = label
    end
    uiScale.Scale = clampNumber(scale, 0, 100, 1)
end

function setPalletTextPosition(carrier, x, y, z)
    if not isValidInstance(carrier) or not carrier:IsA("BasePart") then
        return
    end
    carrier:SetAttribute("PalletText_X", x)
    carrier:SetAttribute("PalletText_Y", y)
    carrier:SetAttribute("PalletText_Z", z)
    local weld = carrier:FindFirstChild("PalletText_Weld")
    if weld and weld:IsA("Weld") then
        weld.C0 = CFrame.new(x, y, z)
    end
end

function isPalletVisibleFromCamera(pallet, topPart)
    local camera=getCamera()
    if not camera or not pallet or not topPart then return false end
    local origin=camera.CFrame.Position
    local target=topPart.Position
    local direction=target-origin
    if direction.Magnitude<=0.01 then return true end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    local ignore={pallet}
    local character=getCharacter()
    if character then table.insert(ignore,character) end
    params.FilterDescendantsInstances=ignore
    local hit=Workspace:Raycast(origin,direction,params)
    return hit==nil
end

function updateOnePalletTextData(data)
    if not data then return end
    if RemovePalletText then
        if data.pallet then destroyPalletText(data.pallet) end
        return
    end
    local label=data.text
    local pallet=data.pallet
    if not label or not label.Parent or not pallet or not pallet.Parent then return end
    local show=true
    if PalletTextOnlyOwnPallet then
        local state=PalletState[pallet]
        show=state and state.touching==true or false
    end
    if show and PalletTextOnlyVisible then
        show=isPalletVisibleFromCamera(pallet,data.carrier or data.topPart)
    end
    label.Visible=show
    local carrier=data.carrier
    if carrier and carrier.Parent then
        setPalletTextPosition(carrier,PalletText_X,PalletText_Y,PalletText_Z)
    end
    setPalletTextLabelText(label,PalletText_TEXT)
    setPalletTextLabelColor(label,PalletText_TEXT_COLOR)
    setPalletTextLabelStroke(label,PalletText_THICKNESS,PalletText_TEXT_COLOR)
    setPalletTextScale(label,PalletText_SCALE)
    label.BackgroundTransparency=1
    if data.surface then data.surface.AlwaysOnTop=not PalletTextOnlyVisible end
end

function updateEveryPalletText()
    for _, data in pairs(PalletText_DATA) do
        updateOnePalletTextData(data)
    end
end

function getNearestPallet(maxDistance)
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


function clearPalletState(pallet)
    if pallet then
        destroyMaterialFadeOverlays(pallet)
        PalletState[pallet] = nil
        OriginalPalletState[pallet] = nil
        PalletText_DATA[pallet] = nil
    end
end

function rememberPalletState(pallet)
    if not pallet then return end
    local state=OriginalPalletState[pallet]
    if not state then
        state={Parts={}}
        OriginalPalletState[pallet]=state
    end
    for _,part in ipairs(getBaseParts(pallet)) do
        if not state.Parts[part] then
            state.Parts[part]={
                Color=copyColor(part.Color),
                Transparency=part.Transparency,
                LocalTransparencyModifier=part.LocalTransparencyModifier,
                Material=part.Material,
                MaterialVariant=part.MaterialVariant,
                Reflectance=part.Reflectance,
            }
        end
    end
end

function restoreRememberedPalletState(pallet)
    local state = OriginalPalletState[pallet]
    if not state then return end
    for part, values in pairs(state.Parts) do
        if part and part.Parent then
            safeSet(part, "Color", values.Color)
            safeSet(part, "Transparency", values.Transparency)
            safeSet(part, "LocalTransparencyModifier", values.LocalTransparencyModifier)
            safeSet(part, "Material", values.Material)
            safeSet(part, "MaterialVariant", values.MaterialVariant)
            safeSet(part, "Reflectance", values.Reflectance)
        end
    end
end

function applyPalletColor(pallet, color)
    if not pallet then
        return
    end
    rememberPalletState(pallet)
    for _, part in ipairs(getBaseParts(pallet)) do
        part.Color = copyColor(color)
    end
end

function applyPalletTransparency(pallet, transparency)
    if not pallet then
        return
    end
    for _, part in ipairs(getBaseParts(pallet)) do
        part.Transparency = clampNumber(transparency, 0, 1, 0)
    end
end

function setAllPalletsColor(color)
    for pallet in pairs(Pallets) do
        if isValidInstance(pallet) then
            applyPalletColor(pallet, color)
        end
    end
end

function setAllPalletsTransparency(transparency)
    for pallet in pairs(Pallets) do
        if isValidInstance(pallet) then
            applyPalletTransparency(pallet, transparency)
        end
    end
end

function setPalletTransparency(value)
    PalletTransparency = clampNumber(value, 0, 25, 0)
    local amount = PalletTransparency / 25
    for pallet in pairs(Pallets) do
        if isValidInstance(pallet) then
            rememberPalletState(pallet)
            local state=OriginalPalletState[pallet]
            for _,part in ipairs(getBaseParts(pallet)) do
                local original=state and state.Parts[part]
                local target=original and original.Transparency or 0
                if amount > 0 then target=target + ((1-target)*amount) end
                safeSet(part,"Transparency",target)
            end
        end
    end
end

function resetAllRememberedPallets()
    for pallet in pairs(OriginalPalletState) do
        if isValidInstance(pallet) then restoreRememberedPalletState(pallet) end
    end
    table.clear(OriginalPalletState)
end

function makeBeamTransparency(strength)
    local value = math.clamp(1 - strength, 0, 1)
    return NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.05, value),
        NumberSequenceKeypoint.new(0.95, value),
        NumberSequenceKeypoint.new(1, 1),
    })
end

function makeBeamColor(color)
    return ColorSequence.new(copyColor(color))
end

function setBeamColor(beam, color)
    if beam and beam:IsA("Beam") then
        beam.Color = makeBeamColor(color)
    end
end

function setBeamWidth(beam, width)
    if not beam or not beam:IsA("Beam") then
        return
    end
    local value = clampNumber(width, 0, 10, 0.35)
    beam.Width0 = value
    beam.Width1 = value
end

function setBeamSpeed(beam, speed)
    if beam and beam:IsA("Beam") then
        beam.TextureSpeed = tonumber(speed) or 0
    end
end

function setBeamLength(beam, length)
    if beam and beam:IsA("Beam") then
        beam.TextureLength = math.max(0.01, tonumber(length) or 1)
    end
end

function setBeamSegments(beam, segments)
    if beam and beam:IsA("Beam") then
        beam.Segments = math.clamp(math.floor(tonumber(segments) or 10), 1, 100)
    end
end

function setBeamEnabled(beam, enabled)
    if beam and beam:IsA("Beam") then
        beam.Enabled = enabled == true
    end
end

function setCurrentBeamEnabled(enabled)
    setBeamEnabled(getGrabBeam(), enabled)
end

function refreshAllBeamProperties()
    local beam = getGrabBeam()
    if not beam then
        return
    end
    local preset = GrabLinePresets[CurrentGrabLineTexture]
    if preset then
        applyBeamSettings(beam, preset)
    end
end

function getSkyAtmosphere()
    return Lighting:FindFirstChildOfClass("Atmosphere")
end

function setAtmosphereColor(color)
    local atmosphere = getSkyAtmosphere()
    if atmosphere then
        atmosphere.Color = copyColor(color)
    end
end

function setAtmosphereDensity(value)
    local atmosphere = getSkyAtmosphere()
    if atmosphere then
        atmosphere.Density = clampNumber(value, 0, 1, 0)
    end
end

function setAtmosphereHaze(value)
    local atmosphere = getSkyAtmosphere()
    if atmosphere then
        atmosphere.Haze = clampNumber(value, 0, 10, 0)
    end
end

function setAtmosphereGlare(value)
    local atmosphere = getSkyAtmosphere()
    if atmosphere then
        atmosphere.Glare = clampNumber(value, 0, 10, 0)
    end
end

function setLightingClock(value)
    CurrentTime = clampNumber(value, 0, 24, CurrentTime)
    Lighting.ClockTime = CurrentTime
end

function setLightingBrightness(value)
    CurrentBrightness = clampNumber(value, 0, 5, CurrentBrightness)
    Lighting.Brightness = CurrentBrightness
end

function setLightingExposure(value)
    CurrentExposure = clampNumber(value, -5, 5, CurrentExposure)
    Lighting.ExposureCompensation = CurrentExposure
end

function setLightingAmbient(color)
    CurrentAmbient = copyColor(color)
    Lighting.Ambient = CurrentAmbient
end

function setLightingOutdoorAmbient(color)
    CurrentOutdoorAmbient = copyColor(color)
    Lighting.OutdoorAmbient = CurrentOutdoorAmbient
end

function setGreySkyState(enabled)
    GreySkyEnabled = enabled == true
    applyGreySky()
end

function setSnowState(enabled)
    SnowEnabled = enabled == true
    updateSnow()
end

function setSnowRange(value)
    SnowRange = clampNumber(value, 0, 1000, SnowRange)
    updateSnow()
end

function setSnowAmount(value)
    SnowAmount = clampNumber(value, 0, 500, SnowAmount)
    updateSnow()
end

function setSnowSpeed(value)
    SnowSpeed = clampNumber(value, 1, 30, SnowSpeed)
    updateSnow()
end

function removeSnow()
    SnowEnabled = false
    if SnowPart then
        SnowPart:Destroy()
        SnowPart = nil
        SnowEmitter = nil
    end
end

function resetCamera()
    CurrentFOV = DEFAULT_FOV
    applyFOV()
    if Options and Options.FOV then pcall(function() Options.FOV:SetValue(DEFAULT_FOV) end) end
end

function setCameraFOV(value)
    CurrentFOV = clampNumber(value, 50, 120, DEFAULT_FOV)
    applyFOV()
end


function setPalletTextFont(value)
    local name=tostring(value or "GothamBlack")
    local font=Enum.Font[name]
    if font then
        PalletText_FONT=font
        updateAllPalletText()
    end
end

function setPalletTextText(value)
    value = tostring(value or "")
    if value == "" then
        value = "Pallet"
    end
    PalletText_TEXT = value
    updateAllPalletText()
end

function setPalletTextTextColor(color)
    PalletText_TEXT_COLOR = copyColor(color)
    updateAllPalletText()
end

function setPalletTextScaleValue(value)
    PalletText_SCALE = clampNumber(value, 0, 100, 1)
    updateAllPalletText()
end

function setPalletTextThicknessValue(value)
    PalletText_THICKNESS = clampNumber(value, 0, 10, 2)
    updateAllPalletText()
end

function setPalletTextX(value)
    PalletText_X = clampNumber(value, -5, 5, 0)
    updateAllPalletText()
end

function setPalletTextY(value)
    PalletText_Y = clampNumber(value, -2, 2, 0)
    updateAllPalletText()
end

function setPalletTextZ(value)
    PalletText_Z = clampNumber(value, -5, 5, 0)
    updateAllPalletText()
end

function resetPalletTextValues()
    PalletText_SCALE = 1
    PalletText_THICKNESS = 2
    PalletText_X = 0
    PalletText_Y = 0
    PalletText_Z = 0
    PalletText_TEXT = "Pallet"
    PalletText_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
    PalletText_FONT = Enum.Font.GothamBlack
    updateAllPalletText()
end

function getPalletTextData(pallet)
    return pallet and PalletText_DATA[pallet] or nil
end

function getPalletTextTextLabel(pallet)
    local data = getPalletTextData(pallet)
    return data and data.text or nil
end

function getPalletTextCarrier(pallet)
    local data = getPalletTextData(pallet)
    return data and data.carrier or nil
end

function updatePalletTextVisible(pallet)
    if not pallet or not pallet.Parent then
        return
    end
    local data = PalletText_DATA[pallet]
    if data then
        updateOnePalletTextData(data)
    end
end

function updateVisiblePalletText()
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then
            updatePalletTextVisible(pallet)
        end
    end
end

function getPalletCount()
    local count = 0
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then
            count += 1
        end
    end
    return count
end

function getProcessedPalletCount()
    local count = 0
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent and PalletState[pallet] then
            count += 1
        end
    end
    return count
end

function getActivePalletTextCount()
    local count = 0
    for pallet, data in pairs(PalletText_DATA) do
        if pallet and pallet.Parent and data then
            count += 1
        end
    end
    return count
end

function cleanupDeadPallets()
    for pallet in pairs(Pallets) do
        if not pallet or not pallet.Parent then
            Pallets[pallet] = nil
            PalletState[pallet] = nil
            OriginalPalletState[pallet] = nil
            PalletText_DATA[pallet] = nil
        end
    end
end

function restoreEverything()
    State.Enabled=true
    DETECTION_ENABLED=true
    MaterialAlwaysOn=false
    RemovePalletText=false
    PalletTextOnlyOwnPallet=false
    PalletTextOnlyVisible=true
    DontChangePalletColor=false
    PalletMaterial="WoodPlanks"
    PalletTransparency=0
    PalletColorFadeInTime=0.22
    PalletColorFadeOutTime=0.22
    PalletMaterialFadeInTime=0.5
    PalletMaterialFadeOutTime=0.5
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then
            local state=PalletState[pallet]
            if state then
                state.touching=false
                state.releaseTime=nil
                state.targetColor=nil
                state.tweenId=state.tweenId+1
                state.materialFadeId=(state.materialFadeId or 0)+1
            end
            destroyMaterialFadeOverlays(pallet)
            restoreRememberedPalletState(pallet)
        end
    end
    restoreOriginalBeam()
    GrabLineModified=false
    CurrentGrabLineTexture="Low Quality"
    CurrentGrabLineColor=Color3.fromRGB(255,255,255)
    CurrentFOV=DEFAULT_FOV
    applyFOV()
    resetPalletTextValues()
    restoreLighting()
    removeSnow()
    PalletGlowEnabled=false
    updatePalletGlow()
    setFullbright(false)
    setFogDisabled(false)
    GreySkyEnabled=false
    NightModeEnabled=false
    TimeLockEnabled=false
    TimeLockSpeed=0
    local function setOption(name,value)
        local option=Options and Options[name]
        if option then pcall(function() option:SetValue(value) end) end
    end
    local function setToggle(name,value)
        local toggle=Toggles and Toggles[name]
        if toggle then pcall(function() toggle:SetValue(value) end) end
    end
    setToggle("BeamDetection",true)
    setToggle("MaterialAlwaysOn",false)
    setToggle("RemovePalletText",false)
    setToggle("PalletTextOnlyOwnPallet",false)
    setToggle("PalletTextOnlyVisible",true)
    setToggle("DontChangePalletColor",false)
    setToggle("NightMode",false)
    setToggle("TimeLock",false)
    setToggle("GreySky",false)
    setToggle("Snow",false)
    setToggle("PalletGlow",false)
    setToggle("Fullbright",false)
    setToggle("NoFog",false)
    setOption("PalletMaterial","WoodPlanks")
    setOption("PalletTransparency",0)
    setOption("PalletColorFadeInTime",0.22)
    setOption("PalletColorFadeOutTime",0.22)
    setOption("PalletMaterialFadeInTime",0.5)
    setOption("PalletMaterialFadeOutTime",0.5)
    setOption("PalletTextText","Pallet")
    setOption("PalletTextFont","GothamBlack")
    if Options and Options.PalletTextTextColor then pcall(function() Options.PalletTextTextColor:SetValueRGB(Color3.fromRGB(255,255,255)) end) end
    setOption("PalletTextScale",1)
    setOption("PalletTextThickness",2)
    setOption("PalletTextPositionX",0)
    setOption("PalletTextPositionY",0)
    setOption("PalletTextPositionZ",0)
    setOption("FOV",DEFAULT_FOV)
    setOption("GrabLineTexture","Low Quality")
    setOption("Time",OriginalLighting.ClockTime)
    setOption("TimeLockSpeed",0)
    setOption("Brightness",OriginalLighting.Brightness)
    setOption("Exposure",OriginalLighting.ExposureCompensation)
    refreshAllPalletText()
    if updateMaterialFadeVisibility then updateMaterialFadeVisibility() end
    if updateColorFadeVisibility then updateColorFadeVisibility() end
end

function disableEverything()
    restoreEverything()
    DETECTION_ENABLED=false
    State.Enabled=false
    if Toggles and Toggles.BeamDetection then pcall(function() Toggles.BeamDetection:SetValue(false) end) end
    pcall(function() if Library.Unload then Library:Unload() end end)
end

function unregisterPallet(pallet)
    if not pallet then
        return
    end
    destroyPalletText(pallet)
    PalletState[pallet] = nil
    Pallets[pallet] = nil
end

function registerExistingPallets()
    for _, object in ipairs(Workspace:GetDescendants()) do
        if isPallet(object) then registerPallet(object) end
    end
end

function getPalletPartsCount(pallet)
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

function getPalletBounds(pallet)
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

function getPalletTopHeight(pallet)
    local _, size = getPalletBounds(pallet)
    return size and size.Y or 0
end

function isPalletNearPlayer(pallet, distance)
    return getPalletDistance(pallet) <= (distance or 20)
end

function playerTouchesPallet(pallet)
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

function activatePallet(pallet)
    if not pallet or not Pallets[pallet] then return end
    local state=PalletState[pallet]
    if not state then return end
    state.touching=true
    state.releaseTime=nil
    applyGrabbedEffects(pallet)
end

function touchCheckAllPallets()
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

function maintainRuntime()
    cleanupDeadPallets()
    updateVisiblePalletText()
    updatePalletGlow()
end

function setMenuVisible(visible)
    State.MenuVisible = visible == true
    pcall(function()
        Window:SetVisible(State.MenuVisible)
    end)
end

function toggleMenuVisible()
    setMenuVisible(not State.MenuVisible)
end

function makeColor(r, g, b)
    return Color3.fromRGB(math.clamp(math.floor(r or 0), 0, 255), math.clamp(math.floor(g or 0), 0, 255), math.clamp(math.floor(b or 0), 0, 255))
end

function colorToTable(color)
    color = copyColor(color)
    return {
        R = color.R,
        G = color.G,
        B = color.B,
    }
end

function tableToColor(value, fallback)
    if type(value) ~= "table" then
        return copyColor(fallback or Color3.new(1, 1, 1))
    end
    return Color3.new(
        clampNumber(value.R, 0, 1, 1),
        clampNumber(value.G, 0, 1, 1),
        clampNumber(value.B, 0, 1, 1)
    )
end

function saveRuntimeSnapshot()
    State.Defaults.FOV = CurrentFOV
    State.Defaults.ClockTime = CurrentTime
    State.Defaults.Brightness = CurrentBrightness
    State.Defaults.Exposure = CurrentExposure
    State.Defaults.Ambient = copyColor(CurrentAmbient)
    State.Defaults.OutdoorAmbient = copyColor(CurrentOutdoorAmbient)
    State.Defaults.PalletTextText = PalletText_TEXT
    State.Defaults.PalletTextScale = PalletText_SCALE
    State.Defaults.PalletTextThickness = PalletText_THICKNESS
    State.Defaults.PalletTextColor = copyColor(PalletText_TEXT_COLOR)
end

function restoreRuntimeSnapshot()
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
    if defaults.PalletTextText then
        PalletText_TEXT = defaults.PalletTextText
    end
    if defaults.PalletTextScale then
        PalletText_SCALE = defaults.PalletTextScale
    end
    if defaults.PalletTextThickness then
        PalletText_THICKNESS = defaults.PalletTextThickness
    end
    if defaults.PalletTextColor then
        PalletText_TEXT_COLOR = copyColor(defaults.PalletTextColor)
    end
    applyFOV()
    updateAllPalletText()
end

saveRuntimeSnapshot()

task.spawn(function()
    while not State.Destroyed do
        if State.Enabled then
            touchCheckAllPallets()
            maintainRuntime()
        end
        task.wait(CHECK_INTERVAL)
    end
end)

MaterialNames = {}
for _,material in ipairs(Enum.Material:GetEnumItems()) do table.insert(MaterialNames,material.Name) end
table.sort(MaterialNames)

function applyPalletMaterial(pallet,materialName)
    if not pallet or not pallet.Parent then return end
    rememberPalletState(pallet)
    local material=Enum.Material[materialName]
    if not material then return end
    for _,part in ipairs(getBaseParts(pallet)) do
        if part and part.Parent then part.Material=material part.MaterialVariant="" end
    end
end

function setPalletColorFadeInTime(value)
    PalletColorFadeInTime=clampNumber(value,0,2,0.22)
end

function setPalletMaterialFadeInTime(value)
    PalletMaterialFadeInTime=clampNumber(value,0,2,0.5)
end

function setPalletColorFadeOutTime(value)
    PalletColorFadeOutTime=clampNumber(value,0,2,0.22)
end

function setPalletMaterialFadeOutTime(value)
    PalletMaterialFadeOutTime=clampNumber(value,0,2,0.5)
end

function refreshPalletText()
    rebuildPalletText()
end

SunTextureId=""
function setSunTexture(value)
    SunTextureId=tostring(value or "")
    local sky=Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky=Instance.new("Sky")
        sky.Name="HuracanSky"
        sky.Parent=Lighting
    end
    sky.SunTextureId=SunTextureId
end

SkyPresetNames={"Default","HD","Clear","Sunset","Night","Foggy","Grey"}
function applySkyPreset(name)
    name=tostring(name or "Default")
    if name=="Default" then restoreLighting() return end
    local a=getAtmosphere()
    if name=="HD" then
        Lighting.Brightness=2.2
        Lighting.ExposureCompensation=0.25
        Lighting.Ambient=Color3.fromRGB(150,150,150)
        Lighting.OutdoorAmbient=Color3.fromRGB(185,185,185)
        a.Color=Color3.fromRGB(205,220,255)
        a.Decay=Color3.fromRGB(120,135,170)
        a.Density=0.08
        a.Haze=0.15
        a.Glare=0.15
    elseif name=="Clear" then
        Lighting.Brightness=2
        Lighting.ExposureCompensation=0
        Lighting.Ambient=Color3.fromRGB(180,180,180)
        Lighting.OutdoorAmbient=Color3.fromRGB(200,200,200)
        a.Color=Color3.fromRGB(220,235,255)
        a.Decay=Color3.fromRGB(170,190,220)
        a.Density=0.02
        a.Haze=0
        a.Glare=0.05
    elseif name=="Sunset" then
        Lighting.ClockTime=18.3
        Lighting.Brightness=1.4
        Lighting.ExposureCompensation=0
        Lighting.Ambient=Color3.fromRGB(105,65,55)
        Lighting.OutdoorAmbient=Color3.fromRGB(150,90,65)
        a.Color=Color3.fromRGB(255,170,120)
        a.Decay=Color3.fromRGB(170,80,50)
        a.Density=0.12
        a.Haze=1.2
        a.Glare=0.35
    elseif name=="Night" then
        Lighting.ClockTime=0
        Lighting.Brightness=.5
        Lighting.ExposureCompensation=-1
        Lighting.Ambient=Color3.fromRGB(8,10,18)
        Lighting.OutdoorAmbient=Color3.fromRGB(3,5,12)
        a.Color=Color3.fromRGB(20,25,50)
        a.Decay=Color3.fromRGB(8,10,25)
        a.Density=.2
        a.Haze=1
        a.Glare=0
    elseif name=="Foggy" then
        Lighting.Brightness=1
        Lighting.ExposureCompensation=0
        Lighting.Ambient=Color3.fromRGB(125,125,125)
        Lighting.OutdoorAmbient=Color3.fromRGB(145,145,145)
        a.Color=Color3.fromRGB(185,185,185)
        a.Decay=Color3.fromRGB(125,125,125)
        a.Density=.55
        a.Haze=4
        a.Glare=0
    elseif name=="Grey" then
        Lighting.Brightness=1.2
        Lighting.ExposureCompensation=0
        Lighting.Ambient=Color3.fromRGB(100,100,100)
        Lighting.OutdoorAmbient=Color3.fromRGB(110,110,110)
        a.Color=Color3.fromRGB(135,135,135)
        a.Decay=Color3.fromRGB(80,80,80)
        a.Density=.35
        a.Haze=2
        a.Glare=0
    end
end

function getPalletHighlight(pallet)
    if not pallet then return nil end
    local h=pallet:FindFirstChild("HuracanPalletGlow")
    if h and h:IsA("Highlight") then return h end
    return nil
end

function updatePalletGlow()
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then
            local h=getPalletHighlight(pallet)
            if PalletGlowEnabled then
                if not h then
                    h=Instance.new("Highlight")
                    h.Name="HuracanPalletGlow"
                    h.DepthMode=Enum.HighlightDepthMode.Occluded
                    h.Parent=pallet
                end
                h.Enabled=true
                h.FillColor=copyColor(PalletGlowColor)
                h.OutlineColor=copyColor(PalletGlowColor)
                h.FillTransparency=PalletGlowFill
                h.OutlineTransparency=PalletGlowOutline
            elseif h then
                h:Destroy()
            end
        end
    end
end

function setPalletGlowEnabled(value)
    PalletGlowEnabled=value==true
    updatePalletGlow()
end

function setPalletGlowColor(value)
    PalletGlowColor=copyColor(value)
    updatePalletGlow()
end

function setPalletGlowFill(value)
    PalletGlowFill=clampNumber(value,0,1,.65)
    updatePalletGlow()
end

function setPalletGlowOutline(value)
    PalletGlowOutline=clampNumber(value,0,1,0)
    updatePalletGlow()
end

function setFullbright(value)
    FullbrightEnabled=value==true
    if FullbrightEnabled then
        if not FullbrightSaved then
            FullbrightSaved={Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,Exposure=Lighting.ExposureCompensation}
        end
        Lighting.Brightness=3
        Lighting.Ambient=Color3.new(1,1,1)
        Lighting.OutdoorAmbient=Color3.new(1,1,1)
        Lighting.ExposureCompensation=1
    elseif FullbrightSaved then
        Lighting.Brightness=FullbrightSaved.Brightness
        Lighting.Ambient=FullbrightSaved.Ambient
        Lighting.OutdoorAmbient=FullbrightSaved.OutdoorAmbient
        Lighting.ExposureCompensation=FullbrightSaved.Exposure
        FullbrightSaved=nil
    end
end

function setFogDisabled(value)
    FogDisabled=value==true
    local a=getSkyAtmosphere()
    if not a then return end
    if FogDisabled then
        if OriginalFog==nil then OriginalFog={Density=a.Density,Haze=a.Haze,Glare=a.Glare} end
        a.Density=0
        a.Haze=0
        a.Glare=0
    elseif OriginalFog then
        a.Density=OriginalFog.Density
        a.Haze=OriginalFog.Haze
        a.Glare=OriginalFog.Glare
        OriginalFog=nil
    end
end

function setCameraSwayEnabled(value) CameraSwayEnabled=value==true end
function setCameraSwayAmount(value) CameraSwayAmount=clampNumber(value,0,5,1.2) end
function setCameraSwaySpeed(value) CameraSwaySpeed=clampNumber(value,.1,5,1.5) end

function setSunRaysEnabled(value)
    local e=Lighting:FindFirstChild("HuracanSunRays")
    if not e then e=Instance.new("SunRaysEffect") e.Name="HuracanSunRays" e.Parent=Lighting end
    e.Enabled=value==true
    e.Intensity=SunRaysIntensity
    e.Spread=SunRaysSpread
end

function setSunRaysIntensity(value)
    SunRaysIntensity=clampNumber(value,0,1,0.08)
    local e=Lighting:FindFirstChild("HuracanSunRays")
    if e then e.Intensity=SunRaysIntensity end
end

function setSunRaysSpread(value)
    SunRaysSpread=clampNumber(value,0,1,0.5)
    local e=Lighting:FindFirstChild("HuracanSunRays")
    if e then e.Spread=SunRaysSpread end
end
function setNightMode(value)
    NightModeEnabled=value==true
    if NightModeEnabled then
        CurrentTime=0 CurrentBrightness=.5 CurrentExposure=-1
        CurrentAmbient=Color3.fromRGB(8,10,18)
        CurrentOutdoorAmbient=Color3.fromRGB(3,5,12)
        Lighting.ClockTime=0 Lighting.Brightness=.5 Lighting.ExposureCompensation=-1
        Lighting.Ambient=CurrentAmbient Lighting.OutdoorAmbient=CurrentOutdoorAmbient
        local a=getAtmosphere() a.Color=Color3.fromRGB(20,25,50) a.Density=.2 a.Haze=1 a.Glare=0
    else
        restoreLighting()
    end
end
function setTimeLock(value) TimeLockEnabled=value==true end
function setTimeLockSpeed(value) TimeLockSpeed=clampNumber(value,-10,10,0) end
function setAmbientIntensity(value)
    TimeAmbientIntensity=clampNumber(value,0,2,1)
    Lighting.Ambient=Color3.new(CurrentAmbient.R*TimeAmbientIntensity,CurrentAmbient.G*TimeAmbientIntensity,CurrentAmbient.B*TimeAmbientIntensity)
end
function setOutdoorIntensity(value)
    TimeOutdoorIntensity=clampNumber(value,0,2,1)
    Lighting.OutdoorAmbient=Color3.new(CurrentOutdoorAmbient.R*TimeOutdoorIntensity,CurrentOutdoorAmbient.G*TimeOutdoorIntensity,CurrentOutdoorAmbient.B*TimeOutdoorIntensity)
end
function setAtmosphereHazeExtra(value) TimeAtmosphereHaze=clampNumber(value,0,5,0) getAtmosphere().Haze=TimeAtmosphereHaze end
function setAtmosphereGlareExtra(value) TimeAtmosphereGlare=clampNumber(value,0,2,0) getAtmosphere().Glare=TimeAtmosphereGlare end
function setAtmosphereDensityExtra(value) TimeAtmosphereDensity=clampNumber(value,0,1,0) getAtmosphere().Density=TimeAtmosphereDensity end

RunService.Heartbeat:Connect(function(dt)
    if TimeLockEnabled and TimeLockSpeed~=0 then
        CurrentTime=(CurrentTime+TimeLockSpeed*dt)%24
        Lighting.ClockTime=CurrentTime
    end
end)


BeamSection:AddToggle("BeamDetection",{Text="Beam Detection",Default=true,Callback=function(v) DETECTION_ENABLED=v==true if not DETECTION_ENABLED then restoreAll() end end})
BeamSection:AddSlider("CheckInterval",{Text="Detection Interval",Default=CHECK_INTERVAL,Min=.03,Max=.3,Rounding=2,Suffix="s",Callback=function(v) CHECK_INTERVAL=v end})

PalletColorSection:AddToggle("DontChangePalletColor",{Text="Don't Change Pallet Color",Default=DontChangePalletColor,Callback=function(v) setDontChangePalletColor(v) if updateColorFadeVisibility then updateColorFadeVisibility() end end})
local palletColorLabel=PalletColorSection:AddLabel("Grabbed Color")
palletColorLabel:AddColorPicker("PalletChangeColor",{Default=PALLET_CHANGE_COLOR,Title="Grabbed Color",Callback=function(v) PALLET_CHANGE_COLOR=v if not DontChangePalletColor then setPalletFadeSettings() end end})
PalletColorSection:AddSlider("PalletTransparency",{Text="Transparency",Default=PalletTransparency,Min=0,Max=25,Rounding=1,Callback=setPalletTransparency})
ColorFadeInSlider=PalletColorSection:AddSlider("PalletColorFadeInTime",{Text="Color Fade In",Default=PalletColorFadeInTime,Min=0,Max=2,Rounding=2,Suffix="s",Callback=setPalletColorFadeInTime})
ColorFadeOutSlider=PalletColorSection:AddSlider("PalletColorFadeOutTime",{Text="Color Fade Out",Default=PalletColorFadeOutTime,Min=0,Max=2,Rounding=2,Suffix="s",Callback=setPalletColorFadeOutTime})
function updateColorFadeVisibility()
    local visible=DontChangePalletColor==true
    if ColorFadeInSlider then pcall(function() ColorFadeInSlider:SetVisible(visible) end) end
    if ColorFadeOutSlider then pcall(function() ColorFadeOutSlider:SetVisible(visible) end) end
end
updateColorFadeVisibility()

MaterialSection:AddDropdown("PalletMaterial",{Text="Material",Values=MaterialNames,Default="WoodPlanks",Searchable=true,Callback=setPalletMaterialSelection})
MaterialSection:AddToggle("MaterialAlwaysOn",{Text="Material Always On",Default=MaterialAlwaysOn,Callback=function(v) setMaterialAlwaysOn(v) if updateMaterialFadeVisibility then updateMaterialFadeVisibility() end end})
MaterialFadeInSlider=MaterialSection:AddSlider("PalletMaterialFadeInTime",{Text="Material Fade In",Default=PalletMaterialFadeInTime,Min=0,Max=2,Rounding=2,Suffix="s",Callback=setPalletMaterialFadeInTime})
MaterialFadeOutSlider=MaterialSection:AddSlider("PalletMaterialFadeOutTime",{Text="Material Fade Out",Default=PalletMaterialFadeOutTime,Min=0,Max=2,Rounding=2,Suffix="s",Callback=setPalletMaterialFadeOutTime})
function updateMaterialFadeVisibility()
    local visible=not MaterialAlwaysOn
    if MaterialFadeInSlider then pcall(function() MaterialFadeInSlider:SetVisible(visible) end) end
    if MaterialFadeOutSlider then pcall(function() MaterialFadeOutSlider:SetVisible(visible) end) end
end
updateMaterialFadeVisibility()
MaterialSection:AddButton({Text="Restore Original Material",Func=function() MaterialAlwaysOn=false if Toggles.MaterialAlwaysOn then Toggles.MaterialAlwaysOn:SetValue(false) end for pallet in pairs(Pallets) do if pallet and pallet.Parent then destroyMaterialFadeOverlays(pallet) restoreOriginalMaterialOnly(pallet) end end end})

PalletTextSection:AddToggle("RemovePalletText",{Text="Remove Pallet Text",Default=RemovePalletText,Callback=setRemovePalletText})
PalletTextSection:AddToggle("PalletTextOnlyOwnPallet",{Text="Only Show Text On Held Pallet",Default=PalletTextOnlyOwnPallet,Callback=function(value) PalletTextOnlyOwnPallet=value==true updateVisiblePalletText() end})
PalletTextSection:AddToggle("PalletTextOnlyVisible",{Text="Visible Check Text",Default=PalletTextOnlyVisible,Callback=function(value) PalletTextOnlyVisible=value==true updateVisiblePalletText() end})
PalletTextSection:AddInput("PalletTextText",{Text="Pallet Text",Default=PalletText_TEXT,Placeholder="Pallet",Numeric=false,Finished=true,Callback=setPalletTextText})
PalletTextSection:AddDropdown("PalletTextFont",{Text="Font",Values=FontNames,Default="GothamBlack",Searchable=true,Callback=setPalletTextFont})
PalletTextSection:AddSlider("PalletTextScale",{Text="Scale",Default=PalletText_SCALE,Min=0,Max=100,Rounding=2,Callback=setPalletTextScaleValue})
PalletTextSection:AddSlider("PalletTextThickness",{Text="Thickness",Default=PalletText_THICKNESS,Min=0,Max=10,Rounding=2,Callback=setPalletTextThicknessValue})
local textColorLabel=PalletTextSection:AddLabel("Text Color")
textColorLabel:AddColorPicker("PalletTextTextColor",{Default=PalletText_TEXT_COLOR,Title="Text Color",Callback=setPalletTextTextColor})
PalletTextSection:AddSlider("PalletTextPositionX",{Text="Position X",Default=PalletText_X,Min=-5,Max=5,Rounding=2,Callback=setPalletTextX})
PalletTextSection:AddSlider("PalletTextPositionY",{Text="Position Y",Default=PalletText_Y,Min=-2,Max=2,Rounding=2,Callback=setPalletTextY})
PalletTextSection:AddSlider("PalletTextPositionZ",{Text="Position Z",Default=PalletText_Z,Min=-5,Max=5,Rounding=2,Callback=setPalletTextZ})
PalletTextSection:AddButton({Text="Rebuild Pallet Text",Func=rebuildPalletText})
PalletTextSection:AddButton({Text="Reset Text Styling",Func=function() resetPalletTextValues() refreshAllPalletText() end})

UtilitySection:AddButton({Text="Restore All",Func=restoreEverything})
UtilitySection:AddButton({Text="Re-register Pallets",Func=registerExistingPallets})

CameraSection:AddSlider("FOV",{Text="FOV",Default=CurrentFOV,Min=50,Max=120,Rounding=0,Callback=setCameraFOV})
CameraSection:AddButton({Text="Reset FOV",Func=resetCamera})

GrabLineSection:AddDropdown("GrabLineTexture",{Text="Texture",Values={"Low Quality","Non-Gamepass","Gamepass","Chain","Chain 2","Chain 3","Chain 4","Rope","Spring"},Default=CurrentGrabLineTexture,Searchable=false,Callback=function(v) CurrentGrabLineTexture=v applySelectedGrabLine() end})
local grabLineColorLabel=GrabLineSection:AddLabel("Line Color")
grabLineColorLabel:AddColorPicker("GrabLineColor",{Default=CurrentGrabLineColor,Title="Grab Line Color",Callback=setGrabLineColor})
GrabLineSection:AddSlider("GrabLineWidth",{Text="Width",Default=GrabLineWidth,Min=.05,Max=2,Rounding=2,Callback=function(v) GrabLineWidth=v local b=getGrabBeam() if b and GrabLineModified then b.Width0=v b.Width1=v end end})
GrabLineSection:AddSlider("GrabLineTextureSpeed",{Text="Texture Speed",Default=GrabLineTextureSpeed,Min=-20,Max=20,Rounding=1,Callback=function(v) GrabLineTextureSpeed=v local b=getGrabBeam() if b and GrabLineModified then b.TextureSpeed=v end end})
GrabLineSection:AddSlider("GrabLineTextureLength",{Text="Texture Length",Default=GrabLineTextureLength,Min=.1,Max=10,Rounding=1,Callback=function(v) GrabLineTextureLength=v local b=getGrabBeam() if b and GrabLineModified then b.TextureLength=v end end})
GrabLineSection:AddSlider("GrabLineSegments",{Text="Segments",Default=GrabLineSegments,Min=1,Max=50,Rounding=0,Callback=function(v) GrabLineSegments=v local b=getGrabBeam() if b and GrabLineModified then b.Segments=v end end})
GrabLineSection:AddSlider("GrabLineBrightness",{Text="Brightness",Default=GrabLineBrightness,Min=0,Max=5,Rounding=1,Callback=function(v) GrabLineBrightness=v local b=getGrabBeam() if b and GrabLineModified then b.Brightness=v end end})
GrabLineSection:AddButton({Text="Apply Selected Line",Func=applySelectedGrabLine})
GrabLineSection:AddButton({Text="Restore Original Line",Func=refreshGrabLine})

TimeSection:AddSlider("Time",{Text="Day Time",Default=CurrentTime,Min=0,Max=24,Rounding=1,Suffix="h",Callback=setLightingClock})
TimeSection:AddToggle("NightMode",{Text="Night Preset",Default=NightModeEnabled,Callback=setNightMode})
TimeSection:AddToggle("TimeLock",{Text="Animate Time",Default=TimeLockEnabled,Callback=setTimeLock})
TimeSection:AddSlider("TimeLockSpeed",{Text="Time Speed",Default=TimeLockSpeed,Min=-10,Max=10,Rounding=2,Callback=setTimeLockSpeed})
TimeSection:AddButton({Text="Restore Lighting",Func=restoreLighting})

local skyLabel=LightingSection:AddLabel("Sky Color")
skyLabel:AddColorPicker("SkyColor",{Default=Color3.fromRGB(199,199,199),Title="Sky Color",Callback=function(v) local a=getAtmosphere() a.Color=v a.Decay=v:Lerp(Color3.new(0,0,0),.35) end})
local ambientLabel=LightingSection:AddLabel("Ambient")
ambientLabel:AddColorPicker("Ambient",{Default=CurrentAmbient,Title="Ambient",Callback=setLightingAmbient})
local outdoorLabel=LightingSection:AddLabel("Outdoor Ambient")
outdoorLabel:AddColorPicker("OutdoorAmbient",{Default=CurrentOutdoorAmbient,Title="Outdoor Ambient",Callback=setLightingOutdoorAmbient})
LightingSection:AddSlider("Brightness",{Text="Brightness",Default=CurrentBrightness,Min=0,Max=5,Rounding=2,Callback=setLightingBrightness})
LightingSection:AddSlider("Exposure",{Text="Exposure",Default=CurrentExposure,Min=-3,Max=3,Rounding=2,Callback=setLightingExposure})
LightingSection:AddInput("SunTexture",{Text="Sun Texture ID",Default=SunTextureId,Finished=true,Callback=setSunTexture})
LightingSection:AddToggle("SunRays",{Text="Sun Rays",Default=false,Callback=setSunRaysEnabled})
LightingSection:AddSlider("SunRaysIntensity",{Text="Sun Rays Intensity",Default=SunRaysIntensity,Min=0,Max=1,Rounding=2,Callback=setSunRaysIntensity})
LightingSection:AddSlider("SunRaysSpread",{Text="Sun Rays Spread",Default=SunRaysSpread,Min=0,Max=1,Rounding=2,Callback=setSunRaysSpread})

SkyPresetNames={"Default","HD","Clear","Sunset","Night","Foggy","Grey"}
VisualSettingsSection:AddDropdown("SkyPreset",{Text="Sky Preset",Values=SkyPresetNames,Default="Default",Searchable=false,Callback=applySkyPreset})
VisualSettingsSection:AddToggle("GreySky",{Text="Grey Sky",Default=false,Callback=setGreySkyState})
VisualSettingsSection:AddToggle("PalletGlow",{Text="Pallet Glow",Default=PalletGlowEnabled,Callback=setPalletGlowEnabled})
local glowColorLabel=VisualSettingsSection:AddLabel("Glow Color")
glowColorLabel:AddColorPicker("PalletGlowColor",{Default=PalletGlowColor,Title="Glow Color",Callback=setPalletGlowColor})
VisualSettingsSection:AddSlider("PalletGlowFill",{Text="Glow Fill",Default=PalletGlowFill,Min=0,Max=1,Rounding=2,Callback=setPalletGlowFill})
VisualSettingsSection:AddSlider("PalletGlowOutline",{Text="Glow Outline",Default=PalletGlowOutline,Min=0,Max=1,Rounding=2,Callback=setPalletGlowOutline})
VisualSettingsSection:AddToggle("Fullbright",{Text="Fullbright",Default=FullbrightEnabled,Callback=setFullbright})
VisualSettingsSection:AddToggle("NoFog",{Text="No Fog",Default=FogDisabled,Callback=setFogDisabled})
VisualSettingsSection:AddButton({Text="Reset Visuals",Func=function() GreySkyEnabled=false restoreLighting() PalletGlowEnabled=false updatePalletGlow() setFullbright(false) setFogDisabled(false) if Toggles.GreySky then Toggles.GreySky:SetValue(false) end if Toggles.PalletGlow then Toggles.PalletGlow:SetValue(false) end if Toggles.Fullbright then Toggles.Fullbright:SetValue(false) end if Toggles.NoFog then Toggles.NoFog:SetValue(false) end end})

WeatherSection:AddToggle("Snow",{Text="Snow",Default=false,Callback=setSnowState})
WeatherSection:AddSlider("SnowRange",{Text="Snow Range",Default=SnowRange,Min=0,Max=1000,Rounding=0,Suffix=" studs",Callback=setSnowRange})
WeatherSection:AddSlider("SnowAmount",{Text="Snow Amount",Default=SnowAmount,Min=0,Max=500,Rounding=0,Callback=setSnowAmount})
WeatherSection:AddSlider("SnowSpeed",{Text="Snow Speed",Default=SnowSpeed,Min=1,Max=30,Rounding=1,Callback=setSnowSpeed})

MenuKeySection:AddLabel("Menu Key"):AddKeyPicker("MenuKeybind",{Default="RightShift",Text="Menu Key",Mode="Toggle",NoUI=false})
if Options.MenuKeybind then Library.ToggleKeybind=Options.MenuKeybind end
ScriptSection:AddButton({Text="Restore All",Func=restoreEverything})
ScriptSection:AddButton({Text="Disable All & Close",Func=disableEverything})

ThemeManager=nil
SaveManager=nil
do
    local okTheme,theme=pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))() end)
    if okTheme and type(theme)=="table" then ThemeManager=theme end
    local okSave,save=pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))() end)
    if okSave and type(save)=="table" then SaveManager=save end
end
if ThemeManager then
    pcall(function()
        ThemeManager:SetLibrary(Library)
        ThemeManager:SetFolder("I_Love_Huracan")
        ThemeManager:ApplyToTab(MenuSettingsTab)
    end)
end
if SaveManager then
    pcall(function()
        SaveManager:SetLibrary(Library)
        SaveManager:SetFolder("I_Love_Huracan")
        SaveManager:SetLoadingOrder(true,{"Toggle","Dropdown","ColorPicker","Slider","Input","KeyPicker"})
        SaveManager:BuildConfigSection(MenuSettingsTab)
    end)
    task.defer(function() pcall(function() SaveManager:LoadAutoloadConfig() end) end)
end

task.defer(function()
    local grabParts=Workspace:FindFirstChild("GrabParts")
    if grabParts then watchGrabParts(grabParts) end
    for pallet in pairs(Pallets) do if pallet and pallet.Parent then createPalletText(pallet) end end
    local beam=getGrabBeam()
    if beam then captureBeamState(beam,true) end
end)

task.spawn(function()
    while task.wait(.05) do
        local t=os.clock()
        for pallet in pairs(Pallets) do
            if pallet and pallet.Parent then
                if PalletPulseEnabled or PalletRainbowEnabled then
                    for _,part in ipairs(getBaseParts(pallet)) do
                        if PalletRainbowEnabled then
                            part.Color=Color3.fromHSV((t*PalletRainbowSpeed)%1,0.75,1)
                        elseif PalletPulseEnabled then
                            local pulse=(math.sin(t*PalletPulseSpeed)+1)/2
                            local base=PALLET_CHANGE_COLOR
                            part.Color=base:Lerp(Color3.new(1,1,1),pulse*.35)
                        end
                    end
                end
            end
        end
    end
end)

if type(Library.OnUnload) == "function" then
Library:OnUnload(function()
    DETECTION_ENABLED=false
    SnowEnabled=false
    for pallet in pairs(Pallets) do
        if pallet and pallet.Parent then
            destroyMaterialFadeOverlays(pallet)
            restoreRememberedPalletState(pallet)
            destroyPalletText(pallet)
        end
    end
    restoreOriginalBeam()
    restoreLighting()
    if SnowPart then SnowPart:Destroy() SnowPart=nil SnowEmitter=nil end
    PalletGlowEnabled=false
    updatePalletGlow()
    setFullbright(false)
    setFogDisabled(false)
    table.clear(PalletText_DATA)
    table.clear(Pallets)
    table.clear(PalletState)
    table.clear(OriginalPalletState)
end)
end
