-- WIX VISUALS v1.5.0 | меню: RightShift | без ESP
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local HS = game:GetService("HttpService")
local SS = game:GetService("SoundService")
local WS = game:GetService("Workspace")
local LP = Players.LocalPlayer
local TI = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

if getgenv().WixVisuals then pcall(function() getgenv().WixVisuals:Destroy() end) end
for _, o in ipairs(Lighting:GetChildren()) do if o.Name:sub(1,3)=="WX_" then pcall(function() o:Destroy() end) end end
for _, o in ipairs(WS:GetChildren()) do if o.Name:sub(1,3)=="WX_" then pcall(function() o:Destroy() end) end end
for _, o in ipairs(SS:GetChildren()) do if o.Name:sub(1,3)=="WX_" then pcall(function() o:Destroy() end) end end

local cfg = {
 sky={enforce=true,clock=14.5,brightness=2,exposure=0,ambient=Color3.fromRGB(70,70,80),outdoor=Color3.fromRGB(110,110,120),top=Color3.fromRGB(120,170,255),bottom=Color3.fromRGB(240,244,255),fogStart=100,fogEnd=4000,fogColor=Color3.fromRGB(205,220,240),density=0.28,haze=1,glare=0,atmoColor=Color3.fromRGB(205,220,240),stars=3000,sunSize=12,moonSize=8},
 weather={mode="Нет",intensity=60,wind=20,thunder=true},
 post={bloom=0.4,bloomSize=24,threshold=1.1,rays=0,dof=0,focus=60,ccBright=0,contrast=0.06,sat=0.12,tint=Color3.fromRGB(255,255,255)},
 graphics={level=10},
 ui={key="RightShift",font="Gotham",menuFont="Gotham",scale=1,accent=Color3.fromRGB(124,92,255)},
}
local C={bg=Color3.fromRGB(14,14,18),bg2=Color3.fromRGB(21,21,27),bg3=Color3.fromRGB(29,29,38),line=Color3.fromRGB(46,46,58),text=Color3.fromRGB(232,232,242),dim=Color3.fromRGB(138,138,158)}
local FONTS={"Gotham","GothamMedium","GothamBold","GothamBlack","SourceSans","SourceSansBold","Roboto","RobotoMono","Code","Oswald","Ubuntu","Nunito","Jura","Sarpanch","TitilliumWeb","Michroma","Merriweather","Bangers","Creepster","FredokaOne"}
local MODES={"Нет","Дождь","Гроза","Снег","Метель","Туман"}

local function inst(c,p,par) local o=Instance.new(c) for k,v in pairs(p) do o[k]=v end if par then o.Parent=par end return o end
local function lerp(a,b,t) return a+(b-a)*t end
local function lerpC(a,b,t) return a:Lerp(b,t) end
local function fmtNum(v,s) if type(v)~="number" then return "—" end return ((v%1==0) and tostring(v) or string.format("%.2f",v))..(s or "") end

local alive=true
local conns={}
local function bind(sig,fn) local c=sig:Connect(function(...) if not alive then return end fn(...) end) conns[#conns+1]=c return c end

local fontTargets={} local painters={} local widgetPaints={} local accentTargets={} local fontOrig={}
local function regFont(o) fontTargets[#fontTargets+1]=o return o end
local function accent(o,p) accentTargets[#accentTargets+1]={o=o,p=p} end
local function repaintAccent() for _,f in ipairs(painters) do pcall(f) end end

local fontQueue={}
local function queueFonts(c) pcall(function() for _,d in ipairs(c:GetDescendants()) do if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then fontQueue[#fontQueue+1]=d end end end) end
local function applyMenuFont() local f=Enum.Font[cfg.ui.menuFont] or Enum.Font.Gotham for _,o in ipairs(fontTargets) do pcall(function() o.Font=f end) end end
local function applyGameFont() queueFonts(LP:FindFirstChild("PlayerGui") or LP) end
local function restoreGameFonts()
 for o,f in pairs(fontOrig) do if o and o.Parent then pcall(function() o.Font=f end) end end
 for i=#fontQueue,1,-1 do fontQueue[i]=nil end
end

local FX={}
local function host(c,n) local o=Lighting:FindFirstChild("WX_"..n) if o and o.Parent then return o end return inst(c,{Name="WX_"..n},Lighting) end
local function ensureFX()
 FX.CC=host("ColorCorrectionEffect","CC") FX.BL=host("BloomEffect","Bloom") FX.SR=host("SunRaysEffect","Rays")
 FX.DOF=host("DepthOfFieldEffect","DOF") FX.ATM=host("Atmosphere","Atmo") FX.SKY=host("Sky","Sky")
 FX.SKY.CelestialBodiesShown=true
 FX.SR.Enabled=false
 FX.DOF.Enabled=false
 FX.DOF.FarIntensity=0
 FX.DOF.NearIntensity=0
end
ensureFX()
local ORIG={ClockTime=Lighting.ClockTime,Brightness=Lighting.Brightness,ExposureCompensation=Lighting.ExposureCompensation,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,ColorShift_Top=Lighting.ColorShift_Top,ColorShift_Bottom=Lighting.ColorShift_Bottom,FogColor=Lighting.FogColor,FogStart=Lighting.FogStart,FogEnd=Lighting.FogEnd,GlobalShadows=Lighting.GlobalShadows,ShadowSoftness=Lighting.ShadowSoftness}

local rig local rain local snow local splash local flashLvl=0 local nextBolt=0
local thunder=inst("Sound",{Name="WX_Thunder",Volume=0.55,RollOffMode=Enum.RollOffMode.Inverse,SoundId="rbxassetid://131961136",Parent=SS})

local function ensureWeather()
 if rig and rig.Parent then return end
 rig=inst("Part",{Name="WX_WeatherRig",Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false,Transparency=1,Size=Vector3.new(220,60,220),Parent=WS})
 rain=inst("ParticleEmitter",{Name="WX_Rain",Texture="",Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward,Size=NumberSequence.new(0.3,0.22),Squash=NumberSequence.new(9,6),Transparency=NumberSequence.new(0.15),Lifetime=NumberRange.new(0.7),Speed=NumberRange.new(160),Rate=0,SpreadAngle=Vector2.new(0,0),Acceleration=Vector3.new(0,-220,0),EmissionDirection=Enum.NormalId.Bottom,LockedToPart=true,LightEmission=0.5,Drag=0.1},rig)
 snow=inst("ParticleEmitter",{Name="WX_Snow",Texture="",Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward,Size=NumberSequence.new(0.45,0.3),Squash=NumberSequence.new(1),Transparency=NumberSequence.new(0.1),Lifetime=NumberRange.new(6),Speed=NumberRange.new(10),Rate=0,SpreadAngle=Vector2.new(0,0),Acceleration=Vector3.new(0,-4,0),EmissionDirection=Enum.NormalId.Bottom,LockedToPart=true,LightEmission=0.35,Drag=1,RotSpeed=NumberRange.new(-35,35),Rotation=NumberRange.new(0,360)},rig)
 splash=inst("ParticleEmitter",{Name="WX_Splash",Texture="",Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward,Size=NumberSequence.new(0.22,0.1),Squash=NumberSequence.new(1),Transparency=NumberSequence.new(0.3),Lifetime=NumberRange.new(0.28),Speed=NumberRange.new(14,22),Rate=0,SpreadAngle=Vector2.new(45,45),Acceleration=Vector3.new(0,-70,0),EmissionDirection=Enum.NormalId.Top,LockedToPart=true,LightEmission=0.4,Drag=1},rig)
 rain.Enabled=false snow.Enabled=false splash.Enabled=false
end
ensureWeather()

local function setQuality(l) pcall(function() local s=settings() if s and s.Rendering then s.Rendering.QualityLevel=math.clamp(l,1,21) end end) end

local acc=0
local function tickVisuals(dt)
 acc=acc+dt if acc<0.05 then return end acc=0
 ensureFX() ensureWeather()
 local s=cfg.sky local w=cfg.weather local mode=w.mode
 local isRain=mode=="Дождь" or mode=="Гроза"
 local isSnow=mode=="Снег" or mode=="Метель"
 local storm=mode=="Гроза" or mode=="Метель"
 local foggy=mode=="Туман"
 flashLvl=math.max(0,flashLvl-dt*4.5)

 if s.enforce then
  local cur=Lighting.ClockTime local diff=((s.clock-cur+12)%24)-12
  Lighting.ClockTime=(cur+diff*0.18)%24
  Lighting.Brightness=lerp(Lighting.Brightness,s.brightness+flashLvl*7,flashLvl>0.02 and 0.6 or 0.18)
  Lighting.ExposureCompensation=lerp(Lighting.ExposureCompensation,s.exposure+flashLvl*1.1,0.3)
  Lighting.Ambient=lerpC(Lighting.Ambient,s.ambient:Lerp(Color3.new(1,1,1),flashLvl*0.5),0.2)
  Lighting.OutdoorAmbient=lerpC(Lighting.OutdoorAmbient,s.outdoor,0.18)
  Lighting.ColorShift_Top=lerpC(Lighting.ColorShift_Top,s.top,0.18)
  Lighting.ColorShift_Bottom=lerpC(Lighting.ColorShift_Bottom,s.bottom,0.18)
  Lighting.FogColor=lerpC(Lighting.FogColor,s.fogColor,0.18)
  local fogEndT=s.fogEnd local densT=s.density
  if foggy then fogEndT=math.min(s.fogEnd,340) densT=math.min(1,s.density+0.35)
  elseif storm then fogEndT=math.min(s.fogEnd,isRain and 900 or 620) densT=math.min(1,s.density+0.15) end
  Lighting.FogStart=lerp(Lighting.FogStart,math.min(s.fogStart,fogEndT*0.3),0.18)
  Lighting.FogEnd=lerp(Lighting.FogEnd,fogEndT,0.18)
  Lighting.GlobalShadows=true
  Lighting.ShadowSoftness=cfg.graphics.level>18 and 0.45 or 0.2
  FX.ATM.Density=lerp(FX.ATM.Density,densT,0.18)
  FX.ATM.Haze=lerp(FX.ATM.Haze,s.haze,0.18)
  FX.ATM.Glare=lerp(FX.ATM.Glare,s.glare,0.18)
  FX.ATM.Color=lerpC(FX.ATM.Color,s.atmoColor,0.18)
  FX.ATM.Offset=lerp(FX.ATM.Offset,0.25,0.18)
  FX.SKY.StarCount=math.floor(s.stars) FX.SKY.SunAngularSize=s.sunSize FX.SKY.MoonAngularSize=s.moonSize
 end

 local p=cfg.post
 FX.CC.Enabled=true FX.BL.Enabled=true FX.SR.Enabled=p.rays>0
 FX.DOF.Enabled=p.dof>0
 FX.DOF.NearIntensity=p.dof>0 and (p.dof/100)*0.6 or 0
 FX.CC.Brightness=lerp(FX.CC.Brightness,p.ccBright,0.18)
 FX.CC.Contrast=lerp(FX.CC.Contrast,p.contrast,0.18)
 FX.CC.Saturation=lerp(FX.CC.Saturation,p.sat,0.18)
 FX.CC.TintColor=lerpC(FX.CC.TintColor,p.tint,0.18)
 FX.BL.Intensity=lerp(FX.BL.Intensity,p.bloom,0.18)
 FX.BL.Size=lerp(FX.BL.Size,p.bloomSize,0.18)
 FX.BL.Threshold=lerp(FX.BL.Threshold,p.threshold,0.18)
 FX.SR.Intensity=lerp(FX.SR.Intensity,p.rays/100,0.18)
 FX.DOF.FarIntensity=lerp(FX.DOF.FarIntensity,p.dof/100,0.18)
 FX.DOF.FocusDistance=lerp(FX.DOF.FocusDistance,p.focus,0.18)
 setQuality(math.max(1,math.min(cfg.graphics.level,21)))

 local cam=WS.CurrentCamera
 if cam and rig then rig.CFrame=CFrame.new(cam.CFrame.Position+cam.CFrame.LookVector*55) end
 local boost=1+math.max(0,cfg.graphics.level-21)*0.35
 local wm=storm and 2.4 or 1
 rain.Enabled=isRain snow.Enabled=isSnow splash.Enabled=isRain
 rain.Rate=isRain and (w.intensity*11*boost*(storm and 1.7 or 1)) or 0
 snow.Rate=isSnow and (w.intensity*3*boost*(storm and 1.8 or 1)) or 0
 splash.Rate=isRain and (w.intensity*4*boost) or 0
 rain.Acceleration=Vector3.new(w.wind*3*wm,-220,0)
 snow.Acceleration=Vector3.new(w.wind*1.4*wm,-4,0)
 snow.Speed=NumberRange.new(10,10+w.wind*wm*0.6)

 if mode=="Гроза" and w.thunder and tick()>nextBolt then
  nextBolt=tick()+math.random(4,10) flashLvl=1
  task.delay(math.random(4,14)/10,function()
   if alive and cfg.weather.mode=="Гроза" and cfg.weather.thunder then pcall(function() thunder:Play() end) end
  end)
 end
end
local FOLDER="WixVisuals"
local hasFS=type(writefile)=="function" and type(isfolder)=="function"
if hasFS then pcall(function() if not isfolder(FOLDER) then makefolder(FOLDER) end end) end

local function packC(t) local o={} for k,v in pairs(t) do if typeof(v)=="Color3" then o[k]={r=v.R,g=v.G,b=v.B} elseif type(v)=="table" then o[k]=packC(v) else o[k]=v end end return o end
local function unpackC(t,into) for k,v in pairs(t) do if type(v)=="table" and v.r then into[k]=Color3.new(v.r,v.g,v.b) elseif type(v)=="table" and type(into[k])=="table" then unpackC(v,into[k]) else into[k]=v end end end

local parentGui=(gethui and gethui()) or LP:WaitForChild("PlayerGui")
local gui=inst("ScreenGui",{Name="WixVisuals",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=999,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Enabled=true},parentGui)

-- модальный блокер: перехватывает весь ввод, пока меню открыто
local blocker=inst("TextButton",{Name="WX_Blocker",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,Text="",AutoButtonColor=false,Active=true,ZIndex=0},gui)

local root=inst("Frame",{Size=UDim2.fromOffset(1040,620),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),BackgroundColor3=C.bg,BackgroundTransparency=0.04,BorderSizePixel=0,Visible=true,Active=true,ZIndex=1},gui)
inst("UICorner",{CornerRadius=UDim.new(0,14)},root)
inst("UIStroke",{Color=C.line,Thickness=1},root)
local uis=inst("UIScale",{Scale=1},root)

local function rescale()
 local cam=WS.CurrentCamera
 if not cam then return end
 local vp=cam.ViewportSize
 if vp.X<200 or vp.Y<200 then return end
 local sc=math.min(1,(vp.X-60)/1040,(vp.Y-60)/620)
 uis.Scale=math.max(0.45,sc*cfg.ui.scale)
end
rescale()
task.spawn(function()
 for _=1,40 do
  if not alive then return end
  rescale()
  if uis.Scale>0.45 then break end
  task.wait(0.15)
 end
end)

local header=inst("Frame",{Size=UDim2.new(1,0,0,52),BackgroundTransparency=1,Active=true},root)
regFont(inst("TextLabel",{Size=UDim2.fromOffset(400,20),Position=UDim2.fromOffset(20,11),BackgroundTransparency=1,Text="WIX VISUALS",Font=Enum.Font.GothamBlack,TextSize=16,TextColor3=C.text,TextXAlignment=Enum.TextXAlignment.Left},header))
regFont(inst("TextLabel",{Size=UDim2.fromOffset(400,16),Position=UDim2.fromOffset(20,29),BackgroundTransparency=1,Text="визуалы, погода, пост-обработка",Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.dim,TextXAlignment=Enum.TextXAlignment.Left},header))
inst("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,52),BackgroundColor3=C.line,BorderSizePixel=0},root)

local closeBtn=inst("TextButton",{Size=UDim2.fromOffset(26,26),Position=UDim2.new(1,-38,0,13),BackgroundColor3=C.bg3,BorderSizePixel=0,Text="×",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.text,AutoButtonColor=false},header)
inst("UICorner",{CornerRadius=UDim.new(0,8)},closeBtn)
local unloadBtn=inst("TextButton",{Size=UDim2.fromOffset(92,26),Position=UDim2.new(1,-138,0,13),BackgroundColor3=C.bg3,BorderSizePixel=0,Text="выгрузить",Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=Color3.fromRGB(235,120,120),AutoButtonColor=false},header)
inst("UICorner",{CornerRadius=UDim.new(0,8)},unloadBtn)
inst("UIStroke",{Color=Color3.fromRGB(120,60,60),Thickness=1,Transparency=0.4},unloadBtn)

local dragging=false local dragStart local startPos
bind(header.InputBegan,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true dragStart=i.Position startPos=root.Position end end)
bind(UIS.InputChanged,function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-dragStart root.Position=UDim2.fromOffset(startPos.X.Offset+d.X,startPos.Y.Offset+d.Y) end end)
bind(UIS.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false resc