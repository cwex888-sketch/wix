-- WIX VISUALS v1.7.4 | меню: RightShift или кнопка W | без ESP | PC
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local SS = game:GetService("SoundService")
local WS = game:GetService("Workspace")
local LP = Players.LocalPlayer

local ENV = (getgenv and getgenv()) or _G
local function log(m) pcall(function() warn("[WIX] " .. tostring(m)) end) end

local function containers()
	local list = {}
	pcall(function() local h = gethui and gethui() if h then list[#list + 1] = h end end)
	pcall(function() local pg = LP:FindFirstChildOfClass("PlayerGui") if pg then list[#list + 1] = pg end end)
	pcall(function() list[#list + 1] = game:GetService("CoreGui") end)
	return list
end
local function purgeWix()
	local n = 0
	for _, c in ipairs(containers()) do
		for _, o in ipairs(c:GetChildren()) do
			if o:IsA("ScreenGui") and tostring(o.Name):match("^WixVisuals") then
				if pcall(function() o:Destroy() end) then n = n + 1 end
			end
		end
	end
	return n
end
purgeWix()
ENV.WixVisuals = nil
for _, svc in ipairs({Lighting, WS, SS}) do
	for _, o in ipairs(svc:GetChildren()) do
		if o.Name:sub(1, 3) == "WX_" then pcall(function() o:Destroy() end) end
	end
end

local cfg = {
	sky = {enforce = true, clock = 14.5, brightness = 2, exposure = 0, ambient = Color3.fromRGB(70, 70, 80), outdoor = Color3.fromRGB(110, 110, 120), top = Color3.fromRGB(120, 170, 255), bottom = Color3.fromRGB(240, 244, 255), fogStart = 100, fogEnd = 4000, fogColor = Color3.fromRGB(205, 220, 240), density = 0.28, haze = 1, glare = 0, atmoColor = Color3.fromRGB(205, 220, 240), stars = 3000, sunSize = 12, moonSize = 8},
	weather = {mode = "Нет", intensity = 60, wind = 20, thunder = true},
	post = {bloom = 0.4, bloomSize = 24, threshold = 1.1, rays = 0, dof = 0, focus = 60, ccBright = 0, contrast = 0.06, sat = 0.12, tint = Color3.fromRGB(255, 255, 255)},
	graphics = {level = 10},
	ui = {menuFont = "Gotham", scale = 1, accent = Color3.fromRGB(124, 92, 255)},
}
local C = {bg = Color3.fromRGB(14, 14, 18), bg2 = Color3.fromRGB(21, 21, 27), bg3 = Color3.fromRGB(29, 29, 38), line = Color3.fromRGB(46, 46, 58), text = Color3.fromRGB(232, 232, 242), dim = Color3.fromRGB(138, 138, 158), acc = cfg.ui.accent}
local FONTS = {"Gotham", "GothamMedium", "GothamBold", "GothamBlack", "SourceSans", "SourceSansBold", "Roboto", "RobotoMono", "Code", "Oswald", "Ubuntu", "Nunito", "Jura", "Sarpanch", "TitilliumWeb", "Michroma", "Merriweather", "Bangers", "Creepster", "FredokaOne"}
local MODES = {"Нет", "Дождь", "Гроза", "Снег", "Метель", "Туман"}

local function inst(c, p, par)
	local o = Instance.new(c)
	if p then for k, v in pairs(p) do pcall(function() o[k] = v end) end end
	if par then o.Parent = par end
	return o
end
local function lerp(a, b, t) return a + (b - a) * t end
local function lerpC(a, b, t) return a:Lerp(b, t) end
local function fmtNum(v, s)
	if type(v) ~= "number" then return "—" end
	return ((v % 1 == 0) and tostring(v) or string.format("%.2f", v)) .. (s or "")
end

local alive = true
local conns = {}
local function bind(sig, fn)
	local c = sig:Connect(function(...) if not alive then return end fn(...) end)
	conns[#conns + 1] = c
	return c
end

local fontTargets, paints, fontQueue, fontOrig = {}, {}, {}, {}
local renderers = {}
local function regFont(o) fontTargets[#fontTargets + 1] = o return o end
local function paint(fn) paints[#paints + 1] = fn pcall(fn) end
local function repaint() for _, f in ipairs(paints) do pcall(f) end end
local function reg(w) renderers[#renderers + 1] = w return w end
local function rerenderAll() for _, w in ipairs(renderers) do pcall(w.render) end end
local function applyMenuFont()
	local f = Enum.Font[cfg.ui.menuFont] or Enum.Font.Gotham
	for _, o in ipairs(fontTargets) do pcall(function() o.Font = f end) end
end
local function queueFonts(c)
	pcall(function()
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
				if not fontOrig[d] then fontOrig[d] = d.Font end
				fontQueue[#fontQueue + 1] = d
			end
		end
	end)
end
local function restoreGameFonts()
	for o, f in pairs(fontOrig) do if o and o.Parent then pcall(function() o.Font = f end) end end
	for i = #fontQueue, 1, -1 do fontQueue[i] = nil end
end

-- ===== эффекты =====
local FX = {}
local function host(c, n)
	local o = Lighting:FindFirstChild("WX_" .. n)
	if o and o.Parent then return o end
	return inst(c, {Name = "WX_" .. n}, Lighting)
end
local function ensureFX()
	FX.CC = host("ColorCorrectionEffect", "CC")
	FX.BL = host("BloomEffect", "Bloom")
	FX.SR = host("SunRaysEffect", "Rays")
	FX.DOF = host("DepthOfFieldEffect", "DOF")
	FX.ATM = host("Atmosphere", "Atmo")
	FX.SKY = host("Sky", "Sky")
	pcall(function() FX.SKY.CelestialBodiesShown = true end)
	FX.SR.Enabled = false
	FX.DOF.Enabled = false
	FX.DOF.FarIntensity = 0
	FX.DOF.NearIntensity = 0
end
ensureFX()

local ORIG = {
	ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, ExposureCompensation = Lighting.ExposureCompensation,
	Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, ColorShift_Top = Lighting.ColorShift_Top,
	ColorShift_Bottom = Lighting.ColorShift_Bottom, FogColor = Lighting.FogColor, FogStart = Lighting.FogStart,
	FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows, ShadowSoftness = Lighting.ShadowSoftness,
}
local origQuality
pcall(function() origQuality = settings().Rendering.QualityLevel end)

local rig, rain, snow, splash, flashLvl, nextBolt = nil, nil, nil, nil, 0, 0
local thunder = inst("Sound", {Name = "WX_Thunder", Volume = 0.55, RollOffMode = Enum.RollOffMode.Inverse, SoundId = "rbxassetid://131961136", Parent = SS})

local function ensureWeather()
	if rig and rig.Parent then return end
	rig = inst("Part", {Name = "WX_WeatherRig", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Transparency = 1, Size = Vector3.new(220, 60, 220), Parent = WS})
	rain = inst("ParticleEmitter", {Name = "WX_Rain", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Size = NumberSequence.new(0.3, 0.22), Squash = NumberSequence.new(9, 6), Transparency = NumberSequence.new(0.15), Lifetime = NumberRange.new(0.7), Speed = NumberRange.new(160), Rate = 0, SpreadAngle = Vector2.new(0, 0), Acceleration = Vector3.new(0, -220, 0), EmissionDirection = Enum.NormalId.Bottom, LockedToPart = true, LightEmission = 0.5, Drag = 0.1}, rig)
	snow = inst("ParticleEmitter", {Name = "WX_Snow", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Size = NumberSequence.new(0.45, 0.3), Squash = NumberSequence.new(1), Transparency = NumberSequence.new(0.1), Lifetime = NumberRange.new(6), Speed = NumberRange.new(10), Rate = 0, SpreadAngle = Vector2.new(0, 0), Acceleration = Vector3.new(0, -4, 0), EmissionDirection = Enum.NormalId.Bottom, LockedToPart = true, LightEmission = 0.35, Drag = 1, RotSpeed = NumberRange.new(-35, 35), Rotation = NumberRange.new(0, 360)}, rig)
	splash = inst("ParticleEmitter", {Name = "WX_Splash", Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, Size = NumberSequence.new(0.22, 0.1), Squash = NumberSequence.new(1), Transparency = NumberSequence.new(0.3), Lifetime = NumberRange.new(0.28), Speed = NumberRange.new(14, 22), Rate = 0, SpreadAngle = Vector2.new(45, 45), Acceleration = Vector3.new(0, -70, 0), EmissionDirection = Enum.NormalId.Top, LockedToPart = true, LightEmission = 0.4, Drag = 1}, rig)
	rain.Enabled, snow.Enabled, splash.Enabled = false, false, false
end
ensureWeather()

local function setQuality(l)
	pcall(function()
		local s = settings()
		if s and s.Rendering then s.Rendering.QualityLevel = math.clamp(l, 1, 21) end
	end)
end

local acc = 0
local function stepVisuals(dt)
	local s, w = cfg.sky, cfg.weather
	local mode = w.mode
	local isRain = mode == "Дождь" or mode == "Гроза"
	local isSnow = mode == "Снег" or mode == "Метель"
	local storm = mode == "Гроза" or mode == "Метель"
	local foggy = mode == "Туман"
	flashLvl = math.max(0, flashLvl - dt * 4.5)

	if s.enforce then
		local cur = Lighting.ClockTime
		local diff = ((s.clock - cur + 12) % 24) - 12
		Lighting.ClockTime = (cur + diff * 0.18) % 24
		Lighting.Brightness = lerp(Lighting.Brightness, s.brightness + flashLvl * 7, flashLvl > 0.02 and 0.6 or 0.18)
		Lighting.ExposureCompensation = lerp(Lighting.ExposureCompensation, s.exposure + flashLvl * 1.1, 0.3)
		Lighting.Ambient = lerpC(Lighting.Ambient, s.ambient:Lerp(Color3.new(1, 1, 1), flashLvl * 0.5), 0.2)
		Lighting.OutdoorAmbient = lerpC(Lighting.OutdoorAmbient, s.outdoor, 0.18)
		Lighting.ColorShift_Top = lerpC(Lighting.ColorShift_Top, s.top, 0.18)
		Lighting.ColorShift_Bottom = lerpC(Lighting.ColorShift_Bottom, s.bottom, 0.18)
		Lighting.FogColor = lerpC(Lighting.FogColor, s.fogColor, 0.18)
		local fogEndT, densT = s.fogEnd, s.density
		if foggy then
			fogEndT, densT = math.min(s.fogEnd, 340), math.min(1, s.density + 0.35)
		elseif storm then
			fogEndT, densT = math.min(s.fogEnd, isRain and 900 or 620), math.min(1, s.density + 0.15)
		end
		Lighting.FogStart = lerp(Lighting.FogStart, math.min(s.fogStart, fogEndT * 0.3), 0.18)
		Lighting.FogEnd = lerp(Lighting.FogEnd, fogEndT, 0.18)
		Lighting.GlobalShadows = true
		pcall(function() Lighting.ShadowSoftness = cfg.graphics.level > 18 and 0.45 or 0.2 end)
		FX.ATM.Density = lerp(FX.ATM.Density, densT, 0.18)
		FX.ATM.Haze = lerp(FX.ATM.Haze, s.haze, 0.18)
		FX.ATM.Glare = lerp(FX.ATM.Glare, s.glare, 0.18)
		FX.ATM.Color = lerpC(FX.ATM.Color, s.atmoColor, 0.18)
		FX.ATM.Offset = lerp(FX.ATM.Offset, 0.25, 0.18)
		pcall(function()
			FX.SKY.StarCount = math.floor(s.stars)
			FX.SKY.SunAngularSize = s.sunSize
			FX.SKY.MoonAngularSize = s.moonSize
		end)
	end

	local p = cfg.post
	FX.CC.Enabled, FX.BL.Enabled = true, true
	FX.SR.Enabled = p.rays > 0
	FX.DOF.Enabled = p.dof > 0
	FX.DOF.NearIntensity = p.dof > 0 and (p.dof / 100) * 0.6 or 0
	FX.CC.Brightness = lerp(FX.CC.Brightness, p.ccBright, 0.18)
	FX.CC.Contrast = lerp(FX.CC.Contrast, p.contrast, 0.18)
	FX.CC.Saturation = lerp(FX.CC.Saturation, p.sat, 0.18)
	FX.CC.TintColor = lerpC(FX.CC.TintColor, p.tint, 0.18)
	FX.BL.Intensity = lerp(FX.BL.Intensity, p.bloom, 0.18)
	FX.BL.Size = lerp(FX.BL.Size, p.bloomSize, 0.18)
	FX.BL.Threshold = lerp(FX.BL.Threshold, p.threshold, 0.18)
	FX.SR.Intensity = lerp(FX.SR.Intensity, p.rays / 100, 0.18)
	FX.DOF.FarIntensity = lerp(FX.DOF.FarIntensity, p.dof / 100, 0.18)
	FX.DOF.FocusDistance = lerp(FX.DOF.FocusDistance, p.focus, 0.18)
	setQuality(math.clamp(cfg.graphics.level, 1, 21))

	local cam = WS.CurrentCamera
	if cam and rig and rig.Parent then
		pcall(function() rig.CFrame = CFrame.new(cam.CFrame.Position + cam.CFrame.LookVector * 55) end)
	end
	local wm = storm and 2.4 or 1
	rain.Enabled, snow.Enabled, splash.Enabled = isRain, isSnow, isRain
	rain.Rate = isRain and (w.intensity * 11 * (storm and 1.7 or 1)) or 0
	snow.Rate = isSnow and (w.intensity * 3 * (storm and 1.8 or 1)) or 0
	splash.Rate = isRain and (w.intensity * 4) or 0
	rain.Acceleration = Vector3.new(w.wind * 3 * wm, -220, 0)
	snow.Acceleration = Vector3.new(w.wind * 1.4 * wm, -4, 0)
	snow.Speed = NumberRange.new(10, 10 + w.wind * wm * 0.6)

	if mode == "Гроза" and w.thunder and tick() > nextBolt then
		nextBolt = tick() + math.random(4, 10)
		flashLvl = 1
		task.delay(math.random(4, 14) / 10, function()
			if alive and cfg.weather.mode == "Гроза" and cfg.weather.thunder then
				pcall(function() thunder:Play() end)
			end
		end)
	end
end
local function tickVisuals(dt)
	acc = acc + dt
	if acc < 0.05 then return end
	acc = 0
	ensureFX()
	ensureWeather()
	local ok, err = pcall(stepVisuals, dt)
	if not ok then log(err) end
end

-- ===== конфиг =====
local FOLDER = "WixVisuals"
local hasFS = type(writefile) == "function" and type(isfolder) == "function" and type(readfile) == "function"
if hasFS then pcall(function() if not isfolder(FOLDER) then makefolder(FOLDER) end end) end
local function packC(t)
	local o = {}
	for k, v in pairs(t) do
		if typeof(v) == "Color3" then o[k] = {r = v.R, g = v.G, b = v.B}
		elseif type(v) == "table" then o[k] = packC(v)
		else o[k] = v end
	end
	return o
end
local function unpackC(t, into)
	for k, v in pairs(t) do
		if type(v) == "table" and v.r then into[k] = Color3.new(v.r, v.g, v.b)
		elseif type(v) == "table" and type(into[k]) == "table" then unpackC(v, into[k])
		else into[k] = v end
	end
end

-- ===== главное =====
local function main()
	local parentGui = containers()[1]
	if not parentGui then log("нет контейнера для GUI") return end

	local gui = inst("ScreenGui", {Name = "WixVisuals", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = true}, parentGui)
	ENV.WixVisuals = gui

	local blocker = inst("TextButton", {Name = "WX_Blocker", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Active = true, ZIndex = 1}, gui)

	local root = inst("Frame", {Size = UDim2.fromOffset(1120, 640), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = true, ZIndex = 10}, gui)
	local bg = inst("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, BackgroundTransparency = 0.03, BorderSizePixel = 0, ZIndex = 1}, root)
	inst("UICorner", {CornerRadius = UDim.new(0, 14)}, bg)
	inst("UIStroke", {Color = C.line, Thickness = 1}, bg)
	local uis = inst("UIScale", {Scale = 1}, root)

	local function rescale()
		local cam = WS.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		if vp.X < 200 or vp.Y < 200 then return end
		local sc = math.min(1, (vp.X - 60) / 1120, (vp.Y - 60) / 640)
		uis.Scale = math.max(0.4, sc * cfg.ui.scale)
	end
	rescale()
	bind(WS:GetPropertyChangedSignal("CurrentCamera"), rescale)

	-- шапка
	local header = inst("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Active = true, ZIndex = 5}, root)
	regFont(inst("TextLabel", {Size = UDim2.fromOffset(400, 20), Position = UDim2.fromOffset(20, 11), BackgroundTransparency = 1, Text = "WIX VISUALS", Font = Enum.Font.GothamBlack, TextSize = 16, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5}, header))
	regFont(inst("TextLabel", {Size = UDim2.fromOffset(400, 16), Position = UDim2.fromOffset(20, 29), BackgroundTransparency = 1, Text = "визуалы, погода, пост-обработка", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5}, header))
	inst("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 52), BackgroundColor3 = C.line, BorderSizePixel = 0, ZIndex = 5}, root)

	local closeBtn = inst("TextButton", {Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -38, 0, 13), BackgroundColor3 = C.bg3, BorderSizePixel = 0, Text = "×", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.text, AutoButtonColor = false, ZIndex = 6}, header)
	inst("UICorner", {CornerRadius = UDim.new(0, 8)}, closeBtn)
	local unloadBtn = inst("TextButton", {Size = UDim2.fromOffset(92, 26), Position = UDim2.new(1, -138, 0, 13), BackgroundColor3 = C.bg3, BorderSizePixel = 0, Text = "выгрузить", Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Color3.fromRGB(235, 120, 120), AutoButtonColor = false, ZIndex = 6}, header)
	inst("UICorner", {CornerRadius = UDim.new(0, 8)}, unloadBtn)
	inst("UIStroke", {Color = Color3.fromRGB(120, 60, 60), Thickness = 1, Transparency = 0.4}, unloadBtn)

	-- перетаскивание
	local dragging, dragStart, startPos = false, nil, nil
	bind(header.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, i.Position, root.Position
		end
	end)
	bind(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			root.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
		end
	end)
	bind(UIS.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)

	-- панель и тело
	local sidebar = inst("Frame", {Size = UDim2.fromOffset(190, 518), Position = UDim2.fromOffset(14, 62), BackgroundTransparency = 1, ZIndex = 5}, root)
	inst("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
	local body = inst("Frame", {Size = UDim2.fromOffset(890, 518), Position = UDim2.fromOffset(214, 62), BackgroundTransparency = 1, ZIndex = 5}, root)

	-- всплывающая подпись
	local toast = regFont(inst("TextLabel", {Size = UDim2.fromOffset(600, 16), Position = UDim2.new(0, 16, 1, -26), BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 6}, root))
	local toastN = 0
	local function status(m)
		log(m)
		toastN = toastN + 1
		local n = toastN
		pcall(function()
			toast.Text = tostring(m)
			toast.TextTransparency = 0
		end)
		task.delay(2.5, function()
			if n == toastN then pcall(function() toast.TextTransparency = 1 end) end
		end)
	end

	local pages, tabs = {}, {}
	local function show(i)
		for k, p in ipairs(pages) do p.frame.Visible = (k == i) end
		for k, t in ipairs(tabs) do
			local on = (k == i)
			t.btn.TextColor3 = on and C.text or C.dim
			t.btn.BackgroundColor3 = on and C.bg3 or C.bg2
			t.bar.Visible = on
		end
	end
	local function newTab(text)
		local b = regFont(inst("TextButton", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.bg2, BorderSizePixel = 0, Text = text, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.dim, AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5}, sidebar))
		inst("UICorner", {CornerRadius = UDim.new(0, 8)}, b)
		inst("UIPadding", {PaddingLeft = UDim.new(0, 14)}, b)
		local bar = inst("Frame", {Size = UDim2.fromOffset(3, 16), Position = UDim2.fromOffset(5, 9), BackgroundColor3 = C.acc, BorderSizePixel = 0, Visible = false, ZIndex = 6}, b)
		inst("UICorner", {CornerRadius = UDim.new(1, 0)}, bar)
		paint(function() bar.BackgroundColor3 = C.acc end)
		tabs[#tabs + 1] = {btn = b, bar = bar}
		local idx = #tabs
		b.MouseButton1Click:Connect(function() show(idx) end)
		return b
	end
	local function newPage()
		local fr = inst("Frame", {Size = UDim2.fromOffset(890, 518), BackgroundTransparency = 1, Visible = false, ZIndex = 5}, body)
		local cols = {}
		for i = 1, 2 do
			local c = inst("Frame", {Size = UDim2.fromOffset(430, 518), Position = UDim2.fromOffset(i == 1 and 0 or 446, 0), BackgroundTransparency = 1, ZIndex = 5}, fr)
			inst("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, c)
			cols[i] = c
		end
		local pg = {frame = fr, cols = cols, n = 0}
		pages[#pages + 1] = pg
		return pg
	end
	local function slot(pg)
		pg.n = pg.n + 1
		return pg.cols[(pg.n % 2) + 1]
	end

	-- выгрузка
	local function unload()
		if not alive then return end
		alive = false
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		pcall(restoreGameFonts)
		for k, v in pairs(ORIG) do pcall(function() Lighting[k] = v end) end
		if origQuality then setQuality(origQuality) end
		for _, svc in ipairs({Lighting, WS, SS}) do
			for _, o in ipairs(svc:GetChildren()) do
				if o.Name:sub(1, 3) == "WX_" then pcall(function() o:Destroy() end) end
			end
		end
		pcall(purgeWix)
		ENV.WixVisuals = nil
	end
	unloadBtn.MouseButton1Click:Connect(unload)
	ENV.WixUnload = unload

	-- открытие/закрытие
	local open = true
	local fab
	local function setOpen(v)
		open = v
		root.Visible = v
		blocker.Visible = v
		if fab then fab.Visible = not v end
	end
	closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
	fab = inst("TextButton", {Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 20, 0.5, -23), BackgroundColor3 = C.acc, BorderSizePixel = 0, Text = "W", Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = C.text, AutoButtonColor = false, Visible = false, ZIndex = 20}, gui)
	inst("UICorner", {CornerRadius = UDim.new(1, 0)}, fab)
	fab.MouseButton1Click:Connect(function() setOpen(true) end)
	paint(function() fab.BackgroundColor3 = C.acc end)
	bind(UIS.InputBegan, function(i)
		if i.KeyCode == Enum.KeyCode.RightShift and not UIS:GetFocusedTextBox() then setOpen(not open) end
	end)

	-- виджеты
	local function rowLabel(parent, text)
		return regFont(inst("TextLabel", {Size = UDim2.fromOffset(370, 18), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6}, parent))
	end

	local function slider(parent, label, min, max, get, set, suffix, step)
		local row = inst("Frame", {Size = UDim2.fromOffset(430, 40), BackgroundTransparency = 1, ZIndex = 6}, parent)
		rowLabel(row, label)
		local val = regFont(inst("TextLabel", {Size = UDim2.fromOffset(56, 18), Position = UDim2.fromOffset(374, 0), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.dim, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6}, row))
		local bar = inst("TextButton", {Size = UDim2.fromOffset(430, 6), Position = UDim2.fromOffset(0, 28), BackgroundColor3 = C.bg3, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 6}, row)
		inst("UICorner", {CornerRadius = UDim.new(1, 0)}, bar)
		local fill = inst("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.acc, BorderSizePixel = 0, ZIndex = 6}, bar)
		inst("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
		local function render()
			local v = get()
			local a = (max > min) and math.clamp((v - min) / (max - min), 0, 1) or 0
			fill.Size = UDim2.new(a, 0, 1, 0)
			val.Text = fmtNum(v, suffix)
		end
		local function apply(input)
			local a = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			local v = min + (max - min) * a
			if step then v = math.floor(v / step + 0.5) * step end
			set(math.clamp(v, min, max))
			render()
		end
		local held = false
		bind(bar.InputBegan, function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				held = true
				apply(i)
			end
		end)
		bind(UIS.InputChanged, function(i)
			if held and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then apply(i) end
		end)
		bind(UIS.InputEnded, function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then held = false end
		end)
		paint(function() fill.BackgroundColor3 = C.acc end)
		render()
		return reg({render = render})
	end

	local function toggle(parent, label, get, set)
		local row = inst("Frame", {Size = UDim2.fromOffset(430, 30), BackgroundTransparency = 1, ZIndex = 6}, parent)
		rowLabel(row, label)
		local pill = inst("TextButton", {Size = UDim2.fromOffset(44, 22), Position = UDim2.fromOffset(386, 4), BackgroundColor3 = C.bg3, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 6}, row)
		inst("UICorner", {CornerRadius = UDim.new(1, 0)}, pill)
		local dot = inst("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.text, BorderSizePixel = 0, ZIndex = 7}, pill)
		inst("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
		local function render()
			local on = get() and true or false
			pill.BackgroundColor3 = on and C.acc or C.bg3
			dot.Position = UDim2.fromOffset(on and 25 or 3, 3)
		end
		pill.MouseButton1Click:Connect(function() set(not get()) render() end)
		paint(render)
		render()
		return reg({render = render})
	end

	local function cycle(parent, label, list, get, set)
		local row = inst("Frame", {Size = UDim2.fromOffset(430, 30), BackgroundTransparency = 1, ZIndex = 6}, parent)
		rowLabel(row, label)
		local btn = inst("TextButton", {Size = UDim2.fromOffset(140, 26), Position = UDim2.fromOffset(290, 2), BackgroundColor3 = C.bg3, BorderSizePixel = 0, Text = tostring(get()), Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.text, AutoButtonColor = false, ZIndex = 6}, row)
		inst("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
		local function render() btn.Text = tostring(get()) end
		btn.MouseButton1Click:Connect(function()
			local idx = 1
			for k, v in ipairs(list) do if v == get() then idx = k break end end
			set(list[(idx % #list) + 1])
			render()
		end)
		return reg({render = render})
	end

	local function colorRow(parent, label, get, set)
		local row = inst("Frame", {Size = UDim2.fromOffset(430, 24), BackgroundTransparency = 1, ZIndex = 6}, parent)
		rowLabel(row, label)
		local sw = inst("Frame", {Size = UDim2.fromOffset(30, 16), Position = UDim2.fromOffset(400, 4), BackgroundColor3 = get(), BorderSizePixel = 0, ZIndex = 6}, row)
		inst("UICorner", {CornerRadius = UDim.new(0, 4)}, sw)
		reg({render = function() sw.BackgroundColor3 = get() end})
		for i, ch in ipairs({"R", "G", "B"}) do
			slider(parent, "   " .. ch, 0, 255, function()
				local c = get()
				return c[ch] * 255
			end, function(v)
				local c = get()
				local t = {c.R * 255, c.G * 255, c.B * 255}
				t[i] = v
				set(Color3.fromRGB(t[1], t[2], t[3]))
				sw.BackgroundColor3 = get()
			end, "", 1)
		end
	end

	local function button(parent, text, fn, color)
		local b = inst("TextButton", {Size = UDim2.fromOffset(430, 30), BackgroundColor3 = C.bg3, BorderSizePixel = 0, Text = text, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = color or C.text, AutoButtonColor = false, ZIndex = 6}, parent)
		inst("UICorner", {CornerRadius = UDim.new(0, 8)}, b)
		b.MouseButton1Click:Connect(fn)
		return b
	end

	local errCount = 0
	local function W(fn, ...)
		local ok, e = pcall(fn, ...)
		if not ok then
			errCount = errCount + 1
			log(e)
		end
	end

	local pSky = newPage() newTab("Небо")
	local pWx = newPage() newTab("Погода")
	local pPost = newPage() newTab("Пост")
	local pGfx = newPage() newTab("Графика")
	local pUi = newPage() newTab("Интерфейс")

	W(toggle, slot(pSky), "принудительный визуал", function() return cfg.sky.enforce end, function(v) cfg.sky.enforce = v end)
	W(slider, slot(pSky), "время", 0, 24, function() return cfg.sky.clock end, function(v) cfg.sky.clock = v end, " ч", 0.5)
	W(slider, slot(pSky), "яркость", 0, 6, function() return cfg.sky.brightness end, function(v) cfg.sky.brightness = v end, "", 0.1)
	W(slider, slot(pSky), "экспозиция", -3, 3, function() return cfg.sky.exposure end, function(v) cfg.sky.exposure = v end, "", 0.1)
	W(slider, slot(pSky), "туман: начало", 0, 500, function() return cfg.sky.fogStart end, function(v) cfg.sky.fogStart = v end, "", 5)
	W(slider, slot(pSky), "туман: конец", 200, 8000, function() return cfg.sky.fogEnd end, function(v) cfg.sky.fogEnd = v end, "", 50)
	W(slider, slot(pSky), "плотность воздуха", 0, 1, function() return cfg.sky.density end, function(v) cfg.sky.density = v end, "", 0.01)
	W(slider, slot(pSky), "дымка", 0, 4, function() return cfg.sky.haze end, function(v) cfg.sky.haze = v end, "", 0.05)
	W(slider, slot(pSky), "блики", 0, 2, function() return cfg.sky.glare end, function(v) cfg.sky.glare = v end, "", 0.05)
	W(slider, slot(pSky), "звёзды", 0, 10000, function() return cfg.sky.stars end, function(v) cfg.sky.stars = v end, "", 50)
	W(slider, slot(pSky), "размер солнца", 0, 30, function() return cfg.sky.sunSize end, function(v) cfg.sky.sunSize = v end, "", 0.5)
	W(slider, slot(pSky), "размер луны", 0, 30, function() return cfg.sky.moonSize end, function(v) cfg.sky.moonSize = v end, "", 0.5)
	W(colorRow, slot(pSky), "цвет неба", function() return cfg.sky.top end, function(c) cfg.sky.top = c end)
	W(colorRow, slot(pSky), "цвет тумана", function() return cfg.sky.fogColor end, function(c) cfg.sky.fogColor = c cfg.sky.atmoColor = c end)

	W(cycle, slot(pWx), "режим", MODES, function() return cfg.weather.mode end, function(v) cfg.weather.mode = v end)
	W(slider, slot(pWx), "интенсивность", 0, 100, function() return cfg.weather.intensity end, function(v) cfg.weather.intensity = v end, " %", 1)
	W(slider, slot(pWx), "ветер", -100, 100, function() return cfg.weather.wind end, function(v) cfg.weather.wind = v end, "", 1)
	W(toggle, slot(pWx), "гром", function() return cfg.weather.thunder end, function(v) cfg.weather.thunder = v end)

	W(slider, slot(pPost), "bloom", 0, 3, function() return cfg.post.bloom end, function(v) cfg.post.bloom = v end, "", 0.01)
	W(slider, slot(pPost), "размер bloom", 0, 56, function() return cfg.post.bloomSize end, function(v) cfg.post.bloomSize = v end, "", 1)
	W(slider, slot(pPost), "порог bloom", 0, 3, function() return cfg.post.threshold end, function(v) cfg.post.threshold = v end, "", 0.01)
	W(slider, slot(pPost), "лучи", 0, 100, function() return cfg.post.rays end, function(v) cfg.post.rays = v end, "", 1)
	W(slider, slot(pPost), "глубина резкости", 0, 100, function() return cfg.post.dof end, function(v) cfg.post.dof = v end, "", 1)
	W(slider, slot(pPost), "фокус", 0, 500, function() return cfg.post.focus end, function(v) cfg.post.focus = v end, "", 5)
	W(slider, slot(pPost), "яркость", -1, 1, function() return cfg.post.ccBright end, function(v) cfg.post.ccBright = v end, "", 0.01)
	W(slider, slot(pPost), "контраст", -1, 1, function() return cfg.post.contrast end, function(v) cfg.post.contrast = v end, "", 0.01)
	W(slider, slot(pPost), "насыщенность", -1, 1, function() return cfg.post.sat end, function(v) cfg.post.sat = v end, "", 0.01)
	W(colorRow, slot(pPost), "оттенок", function() return cfg.post.tint end, function(c) cfg.post.tint = c end)

	W(slider, slot(pGfx), "уровень графики", 1, 21, function() return cfg.graphics.level end, function(v) cfg.graphics.level = v setQuality(v) end, "", 1)
	W(button, slot(pGfx), "применить качество", function() setQuality(cfg.graphics.level) end)

	W(cycle, slot(pUi), "шрифт меню", FONTS, function() return cfg.ui.menuFont end, function(v) cfg.ui.menuFont = v applyMenuFont() end)
	W(slider, slot(pUi), "масштаб меню", 0.5, 1.5, function() return cfg.ui.scale end, function(v) cfg.ui.scale = v rescale() end, "x", 0.05)
	W(colorRow, slot(pUi), "акцент", function() return cfg.ui.accent end, function(c) cfg.ui.accent = c C.acc = c repaint() end)
	W(button, slot(pUi), "применить шрифт к игре", function() queueFonts(LP:FindFirstChildOfClass("PlayerGui") or LP) end)
	W(button, slot(pUi), "вернуть шрифты игры", restoreGameFonts)
	W(button, slot(pUi), "сохранить конфиг", function()
		if not hasFS then status("нет writefile") return end
		pcall(function() writefile(FOLDER .. "/config.json", game:GetService("HttpService"):JSONEncode(packC(cfg))) end)
		status("конфиг сохранён")
	end)
	W(button, slot(pUi), "загрузить конфиг", function()
		if not hasFS then status("нет readfile") return end
		local ok, data = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(FOLDER .. "/config.json")) end)
		if ok and type(data) == "table" then
			unpackC(data, cfg)
			C.acc = cfg.ui.accent
			repaint()
			rerenderAll()
			applyMenuFont()
			rescale()
			status("конфиг загружен")
		else
			status("конфиг не прочитан")
		end
	end)

	show(1)
	bind(RS.RenderStepped, function(dt) tickVisuals(math.min(dt, 0.1)) end)
	applyMenuFont()
	status("wix visuals загружен")
end

local okk, errr = pcall(main)
if not okk then log(errr) end
