local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local TextService      = game:GetService("TextService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local function Create(Class, Properties)
	local Inst = Instance.new(Class)
	for Key, Value in pairs(Properties) do
		Inst[Key] = Value
	end
	return Inst
end

local Library = {}
Library.Flags    = {}
Library.Registry = {}
Library.WindowKeybind = Enum.KeyCode.RightControl
Library.WindowOpen    = true

Library.Theme = {
	Main          = Color3.fromRGB(8,   8,  12),
	Secondary     = Color3.fromRGB(12,  12, 18),
	Stroke        = Color3.fromRGB(30,  35, 50),
	Accent        = Color3.fromRGB(50, 130, 255),
	AccentAlt     = Color3.fromRGB(80, 170, 255),
	TextMain      = Color3.fromRGB(230, 235, 255),
	TextDim       = Color3.fromRGB(100, 115, 150),
	ElementBg     = Color3.fromRGB(16,  18,  28),
	ElementStroke = Color3.fromRGB(40,  50,  75),
	SubTitleBg    = Color3.fromRGB(20,  25,  45),
	NavBarBg      = Color3.fromRGB(14,  16,  24),
	Font          = Enum.Font.GothamSemibold,
	FontBold      = Enum.Font.GothamBold,
	AnimationSpeed = 1
}

local Assets = {
	Button       = "rbxassetid://12967326152",
	Dropdown     = "rbxassetid://12967775051",
	Textbox      = "rbxassetid://12975591097",
	Keybind      = "rbxassetid://12974370712",
	PickerCursor = "rbxassetid://10709798174",
}

local function GetDarkerColor(c)
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, s, v * 0.55)
end

local function GT(t)
	return t / Library.Theme.AnimationSpeed
end

local function QT(obj, t, props, style, dir)
	TweenService:Create(obj,
		TweenInfo.new(GT(t), style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
		props
	):Play()
end

local function BindColor(obj, prop, key)
	local val = Library.Theme[key]
	if typeof(val) == "Color3" then
		obj[prop] = val
		table.insert(Library.Registry, {Object=obj, Property=prop, ThemeKey=key, Type="Property"})
	end
	return obj
end

local function ApplyGradient(parent, color)
	parent.BackgroundColor3 = Color3.new(1,1,1)
	local ex = parent:FindFirstChildOfClass("UIGradient")
	if ex then
		if ex.Name == "ActiveGradient" then return ex end
		ex:Destroy()
	end
	return Create("UIGradient", {
		Parent=parent, Rotation=90,
		Color=ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(1, GetDarkerColor(color))
		})
	})
end

local function BindGradient(obj, key)
	local val = Library.Theme[key]
	if typeof(val) ~= "Color3" then return end
	ApplyGradient(obj, val)
	table.insert(Library.Registry, {Object=obj, ThemeKey=key, Type="Gradient"})
end

local function TweenGrad(obj, targetColor, t)
	local grad = obj:FindFirstChildOfClass("UIGradient")
	if not grad then return end
	local cv = Instance.new("Color3Value")
	cv.Value  = grad.Color.Keypoints[1].Value
	cv.Parent = obj
	local tw  = TweenService:Create(cv, TweenInfo.new(GT(t), Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Value=targetColor})
	local conn
	conn = cv:GetPropertyChangedSignal("Value"):Connect(function()
		if not grad or not grad.Parent then conn:Disconnect(); cv:Destroy(); return end
		grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,cv.Value), ColorSequenceKeypoint.new(1,GetDarkerColor(cv.Value))})
	end)
	tw.Completed:Connect(function() conn:Disconnect(); cv:Destroy() end)
	tw:Play()
end

local function GlowStroke(parent, color, thick)
	return Create("UIStroke", {Parent=parent, Thickness=thick or 1, Color=color or Library.Theme.Accent, Transparency=0.55})
end

local function ClickFX(obj)
	TweenGrad(obj, Library.Theme.Accent, 0.12)
	task.delay(GT(0.12), function() TweenGrad(obj, Library.Theme.ElementBg, 0.22) end)
end

function Library:GetTheme() return Library.Theme end

function Library:SetTheme(new)
	for k, v in pairs(new) do Library.Theme[k] = v end
	for _, item in ipairs(Library.Registry) do
		if not (item.Object and item.Object.Parent) then continue end
		local val = Library.Theme[item.ThemeKey]
		if typeof(val) ~= "Color3" then continue end
		if item.Type == "Property" then
			QT(item.Object, 0.5, {[item.Property]=val})
		elseif item.Type == "Gradient" then
			TweenGrad(item.Object, val, 0.5)
		elseif item.Type == "ActiveGradient" then
			local g = item.Object
			if not (g and g.Parent) then continue end
			local cv = Instance.new("Color3Value"); cv.Value=g.Color.Keypoints[1].Value; cv.Parent=g.Parent
			local tw = TweenService:Create(cv, TweenInfo.new(GT(0.5),Enum.EasingStyle.Quart,Enum.EasingDirection.Out), {Value=val})
			local conn; conn=cv:GetPropertyChangedSignal("Value"):Connect(function()
				if not g or not g.Parent then conn:Disconnect(); cv:Destroy(); return end
				g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,cv.Value),ColorSequenceKeypoint.new(1,GetDarkerColor(cv.Value))})
			end)
			tw.Completed:Connect(function() conn:Disconnect(); cv:Destroy() end); tw:Play()
		end
	end
end

function Library:SetWindowKeybind(key) Library.WindowKeybind = key end

function Library:Window(opts)
	local Title    = opts.Title    or "Stellar"
	local SubTitle = opts.SubTitle or "v2.1"
	local Status   = opts.Status   or ""

	local SG = Create("ScreenGui", {Name="StellarUI", Parent=CoreGui, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, ResetOnSpawn=false})

	local Popup = Create("Frame", {Name="PopupContainer", Parent=SG, ZIndex=200, Visible=false, AutomaticSize=Enum.AutomaticSize.Y, ClipsDescendants=true, Size=UDim2.new(0,0,0,0), BorderSizePixel=0})
	BindColor(Popup, "BackgroundColor3", "Main")
	Create("UICorner", {Parent=Popup, CornerRadius=UDim.new(0,7)})
	GlowStroke(Popup, Library.Theme.Accent, 1)
	Create("UIPadding", {Parent=Popup, PaddingTop=UDim.new(0,2), PaddingBottom=UDim.new(0,2), PaddingLeft=UDim.new(0,2), PaddingRight=UDim.new(0,2)})
	Create("UIListLayout", {Parent=Popup, SortOrder=Enum.SortOrder.LayoutOrder})

	local PopupOwner, PopupConn = nil, nil

	local function ClosePopup()
		if not Popup.Visible then return end
		local cy = Popup.AbsoluteSize.Y
		local tw = TweenService:Create(Popup, TweenInfo.new(GT(0.22),Enum.EasingStyle.Quart,Enum.EasingDirection.Out), {Size=UDim2.new(0,0,0,cy)})
		tw:Play()
		tw.Completed:Connect(function() if Popup.Size.X.Offset==0 then Popup.Visible=false; PopupOwner=nil end end)
		if PopupConn then PopupConn:Disconnect(); PopupConn=nil end
	end

	local function OpenPopup(owner, builder)
		if Popup.Visible and PopupOwner==owner then ClosePopup(); return end
		for _, c in ipairs(Popup:GetChildren()) do
			if not (c:IsA("UIListLayout") or c:IsA("UICorner") or c:IsA("UIStroke") or c:IsA("UIPadding")) then c:Destroy() end
		end
		Popup.Size=UDim2.new(0,0,0,0); Popup.Visible=true; builder(Popup); PopupOwner=owner
		local mf=SG:FindFirstChild("MainFrame"); local mp=mf.AbsolutePosition; local ms=mf.AbsoluteSize
		Popup.Position=UDim2.new(0,mp.X+ms.X+10,0,owner.AbsolutePosition.Y)
		TweenService:Create(Popup, TweenInfo.new(GT(0.28),Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=UDim2.new(0,152,0,0)}):Play()
		if PopupConn then PopupConn:Disconnect() end
		PopupConn=UserInputService.InputBegan:Connect(function(inp)
			if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.MouseButton2 then return end
			local mp2=Vector2.new(inp.Position.X,inp.Position.Y)
			local function ins(f) local p,s=f.AbsolutePosition,f.AbsoluteSize; return mp2.X>=p.X and mp2.X<=p.X+s.X and mp2.Y>=p.Y and mp2.Y<=p.Y+s.Y end
			local cpf=SG:FindFirstChild("ColorPickerPopup")
			if not ins(Popup) and not ins(owner) and not (cpf and cpf.Visible and ins(cpf)) then ClosePopup() end
		end)
	end

	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

	local WIN_W = isMobile and 440 or 460
	local WIN_H = isMobile and 300 or 310

	-- Main window frame
	local MF = Create("CanvasGroup", {Name="MainFrame", Parent=SG, BorderSizePixel=0,
		Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),
		Size=UDim2.new(0,WIN_W,0,WIN_H), GroupTransparency=0})
	MF.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
	Create("UICorner", {Parent=MF, CornerRadius=UDim.new(0,10)})

	-- Animated border stroke
	local MainStroke = Create("UIStroke", {Parent=MF, Thickness=1,
		ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
		Color=Library.Theme.Accent, Transparency=0.35})

	-- Thin top accent line
	local TopLine = Create("Frame", {Parent=MF, BorderSizePixel=0,
		Size=UDim2.new(1,0,0,1), BackgroundColor3=Library.Theme.Accent,
		BackgroundTransparency=0.3, ZIndex=4})
	Create("UIGradient", {Parent=TopLine, Transparency=NumberSequence.new({
		NumberSequenceKeypoint.new(0,   1),
		NumberSequenceKeypoint.new(0.2, 0),
		NumberSequenceKeypoint.new(0.8, 0),
		NumberSequenceKeypoint.new(1,   1),
	})})
	Create("UICorner", {Parent=TopLine, CornerRadius=UDim.new(0,10)})

	local function DoOpen()
		MF.Visible=true; MF.GroupTransparency=1
		MF.Size=UDim2.new(0,WIN_W,0,WIN_H-18); MainStroke.Enabled=false
		QT(MF,0.32,{GroupTransparency=0,Size=UDim2.new(0,WIN_W,0,WIN_H)},Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		task.delay(GT(0.32),function() if Library.WindowOpen then MainStroke.Enabled=true end end)
	end
	local function DoClose()
		MainStroke.Enabled=false
		QT(MF,0.24,{GroupTransparency=1,Size=UDim2.new(0,WIN_W,0,WIN_H-20)})
		task.delay(GT(0.24),function() if not Library.WindowOpen then MF.Visible=false end end)
	end
	UserInputService.InputBegan:Connect(function(inp,gpe)
		if not gpe and inp.KeyCode==Library.WindowKeybind then
			Library.WindowOpen=not Library.WindowOpen
			if Library.WindowOpen then DoOpen() else DoClose() end
		end
	end)

	-- ── Header (38px, clean) ──────────────────────────────────────────────
	local Header = Create("Frame", {Name="Header", Parent=MF, BorderSizePixel=0,
		Size=UDim2.new(1,0,0,38), BackgroundColor3=Color3.fromRGB(16,16,22), ZIndex=2})
	Create("UICorner", {Parent=Header, CornerRadius=UDim.new(0,10)})

	-- Bottom separator (very subtle)
	local HSep = Create("Frame", {Parent=Header, BorderSizePixel=0,
		Position=UDim2.new(0,0,1,-1), Size=UDim2.new(1,0,0,1),
		BackgroundColor3=Library.Theme.Accent, BackgroundTransparency=0.7, ZIndex=3})

	-- Drag
	local dragging, dragStart, startPos = false, nil, nil
	local function onDragStart(pos) dragging=true; dragStart=pos; startPos=MF.Position end
	local function onDragMove(pos)
		if not dragging then return end
		local d=pos-dragStart
		MF.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
	end
	local function onDragEnd() dragging=false end
	Header.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then onDragStart(Vector2.new(inp.Position.X,inp.Position.Y)) end
	end)
	Header.InputChanged:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then onDragMove(Vector2.new(inp.Position.X,inp.Position.Y)) end
	end)
	Header.InputEnded:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then onDragEnd() end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then onDragMove(Vector2.new(inp.Position.X,inp.Position.Y)) end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then onDragEnd() end
	end)

	-- Title
	local TitleLbl = Create("TextLabel", {Parent=Header, BackgroundTransparency=1,
		Position=UDim2.new(0,14,0,0), Size=UDim2.new(0.55,0,1,0),
		Font=Library.Theme.FontBold, Text=Title, TextSize=14,
		TextXAlignment=Enum.TextXAlignment.Left, TextColor3=Color3.fromRGB(235,238,255), ZIndex=3})

	-- Subtitle (dimmed, right next to title)
	local SubLbl = Create("TextLabel", {Parent=Header, BackgroundTransparency=1,
		Position=UDim2.new(0,14,0,0), Size=UDim2.new(1,-80,1,0),
		Font=Library.Theme.Font, Text=SubTitle, TextSize=11,
		TextXAlignment=Enum.TextXAlignment.Left, TextColor3=Color3.fromRGB(70,85,130),
		ZIndex=3})
	-- Offset subtitle after title using TextBounds
	task.defer(function()
		SubLbl.Position = UDim2.new(0, 14 + TitleLbl.TextBounds.X + 8, 0, 0)
	end)

	-- Control buttons (×  –)
	local CtrlBtns = Create("Frame", {Parent=Header, BackgroundTransparency=1,
		AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
		Size=UDim2.new(0,52,0,22), ZIndex=3})
	Create("UIListLayout",{Parent=CtrlBtns, FillDirection=Enum.FillDirection.Horizontal,
		HorizontalAlignment=Enum.HorizontalAlignment.Right,
		VerticalAlignment=Enum.VerticalAlignment.Center, Padding=UDim.new(0,5)})

	local function MakeCtrl(sym, hoverCol)
		local btn = Create("TextButton", {
			Parent=CtrlBtns, Text=sym, Size=UDim2.new(0,20,0,20),
			BackgroundColor3=Color3.fromRGB(22,22,32),
			AutoButtonColor=false, BorderSizePixel=0,
			Font=Enum.Font.GothamBold, TextSize=11,
			TextColor3=Color3.fromRGB(80,90,130), ZIndex=3
		})
		Create("UICorner",{Parent=btn, CornerRadius=UDim.new(0,5)})
		btn.MouseEnter:Connect(function() QT(btn,0.12,{BackgroundColor3=hoverCol,TextColor3=Color3.new(1,1,1)}) end)
		btn.MouseLeave:Connect(function() QT(btn,0.12,{BackgroundColor3=Color3.fromRGB(22,22,32),TextColor3=Color3.fromRGB(80,90,130)}) end)
		return btn
	end

	local MinBtn = MakeCtrl("–", Color3.fromRGB(200,160,30))
	local ClsBtn = MakeCtrl("×", Color3.fromRGB(190,45,45))

	ClsBtn.MouseButton1Click:Connect(function()
		Library.WindowOpen=false; MainStroke.Enabled=false
		local rot,conn=0,nil
		conn=RunService.RenderStepped:Connect(function(dt) rot=rot+dt*280; if MF and MF.Parent then MF.Rotation=rot end end)
		QT(MF,0.28,{GroupTransparency=1,Size=UDim2.new(0,60,0,60)},Enum.EasingStyle.Back,Enum.EasingDirection.In)
		task.delay(0.28,function() conn:Disconnect(); MF.Visible=false; MF.Rotation=0; MF.Size=UDim2.new(0,WIN_W,0,WIN_H) end)
	end)
	-- ─────────────────────────────────────────────────────────────────────

	local Body = Create("Frame", {Name="Body", Parent=MF, BackgroundTransparency=1,
		Position=UDim2.new(0,0,0,38), Size=UDim2.new(1,0,1,-38)})

	-- ── Animated gradient engine ──────────────────────────────────────────
	local g1, g2 = 0, 90
	Library._ActiveTabBtns = Library._ActiveTabBtns or {}

	RunService.RenderStepped:Connect(function(dt)
		if not MF or not MF.Parent then return end
		g1 = (g1 + dt * 40) % 360
		g2 = (g2 + dt * 18) % 360
		local t1 = (math.sin(math.rad(g1)) + 1) / 2
		local t2 = (math.sin(math.rad(g2)) + 1) / 2

		-- Border: subtle blue shift
		MainStroke.Color = Color3.fromRGB(
			math.floor(25 + t1*40),
			math.floor(70 + t1*80),
			math.floor(200 + t1*55)
		)
		MainStroke.Transparency = 0.25 + t2 * 0.2

		-- Top accent line color
		TopLine.BackgroundColor3 = Color3.fromRGB(
			math.floor(20 + t1*50),
			math.floor(80 + t1*90),
			255
		)

		-- Header separator subtle shift
		HSep.BackgroundColor3 = Color3.fromRGB(
			math.floor(30 + t1*35),
			math.floor(60 + t1*60),
			math.floor(150 + t1*60)
		)

		-- Active tab subtle glow
		for _, btn in ipairs(Library._ActiveTabBtns) do
			if btn and btn.Parent then
				btn.BackgroundColor3 = Color3.fromRGB(
					math.floor(22 + t1*18),
					math.floor(35 + t1*28),
					math.floor(80 + t1*40)
				)
			end
		end
	end)
	-- ─────────────────────────────────────────────────────────────────────

	-- ── Sidebar ───────────────────────────────────────────────────────────
	local Sidebar = Create("Frame", {Name="Sidebar", Parent=Body, BorderSizePixel=0,
		Size=UDim2.new(0,148,1,0), ClipsDescendants=true,
		BackgroundColor3=Color3.fromRGB(11,11,16)})

	-- Sidebar right border (1px barely visible)
	Create("Frame",{Parent=Sidebar, BorderSizePixel=0, AnchorPoint=Vector2.new(1,0),
		Position=UDim2.new(1,0,0,0), Size=UDim2.new(0,1,1,0),
		BackgroundColor3=Color3.fromRGB(30,35,58), BackgroundTransparency=0, ZIndex=2})

	local TabList = Create("Frame", {Name="TabList", Parent=Sidebar,
		BackgroundTransparency=1, Size=UDim2.new(1,0,1,0)})
	Create("UIPadding",{Parent=TabList, PaddingTop=UDim.new(0,8),
		PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6), PaddingBottom=UDim.new(0,8)})
	Create("UIListLayout",{Parent=TabList, SortOrder=Enum.SortOrder.LayoutOrder,
		Padding=UDim.new(0,2), VerticalAlignment=Enum.VerticalAlignment.Top,
		FillDirection=Enum.FillDirection.Vertical, HorizontalAlignment=Enum.HorizontalAlignment.Center})

	local ContentArea = Create("Frame", {Name="ContentArea", Parent=Body,
		BackgroundTransparency=1, Position=UDim2.new(0,148,0,0),
		Size=UDim2.new(1,-148,1,0), ClipsDescendants=true})


	local StatusLbl = Create("TextLabel", {Parent=MF, Visible=false}) -- stub for :SetStatus()

	local Minimized = false
	MinBtn.MouseButton1Click:Connect(function()
		Minimized = not Minimized
		if Minimized then
			-- Hide everything except header
			Body.Visible    = false
			TopLine.Visible = false
			HSep.Visible    = false
			MinBtn.Text = "+"
			QT(MF, 0.22, {Size=UDim2.new(0,WIN_W,0,38)}, Enum.EasingStyle.Quart)
		else
			MinBtn.Text = "–"
			QT(MF, 0.32, {Size=UDim2.new(0,WIN_W,0,WIN_H)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			task.delay(GT(0.18), function()
				Body.Visible    = true
				TopLine.Visible = true
				HSep.Visible    = true
			end)
		end
	end)

	local WF = {}
	local Tabs = {}
	local FirstTab     = true
	local ActiveTab    = nil
	local ActiveTabIdx = 1

	function WF:SetStatus(txt) StatusLbl.Text = txt end

	local TabOrderCounter = 0

	function WF:Tab(opts2)
		local TabTitle = opts2.Title    or "Tab"
		local Sections = opts2.Sections or {}

		TabOrderCounter = TabOrderCounter + 1
		local TBtn = Create("TextButton", {Parent=TabList, BorderSizePixel=0,
			Size=UDim2.new(1,0,0,28), AutoButtonColor=false, Text="",
			BackgroundColor3=Color3.fromRGB(16,16,24), LayoutOrder=TabOrderCounter})
		Create("UICorner",{Parent=TBtn, CornerRadius=UDim.new(0,6)})
		local TBtnLbl = Create("TextLabel", {Parent=TBtn, BackgroundTransparency=1,
			Position=UDim2.new(0,10,0,0), Size=UDim2.new(1,-10,1,0),
			Font=Library.Theme.Font, Text=TabTitle,
			TextColor3=Color3.fromRGB(75,85,120), TextSize=12,
			TextXAlignment=Enum.TextXAlignment.Left, ZIndex=2})
		local TBtnActive = false

		TBtn.MouseEnter:Connect(function()
			if not TBtnActive then QT(TBtnLbl,0.12,{TextColor3=Color3.fromRGB(160,170,220)}) end
		end)
		TBtn.MouseLeave:Connect(function()
			if not TBtnActive then QT(TBtnLbl,0.12,{TextColor3=Color3.fromRGB(75,85,120)}) end
		end)

		local TContent = Create("Frame", {Parent=ContentArea, BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Visible=false})
		Create("UIPadding",{Parent=TContent, PaddingTop=UDim.new(0,14), PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14), PaddingBottom=UDim.new(0,14)})

		local TopBar, SecContainer

		if #Sections > 0 then
			TopBar = Create("Frame",{Parent=TContent, BackgroundTransparency=1, Size=UDim2.new(1,0,0,30)})
			Create("UIListLayout",{Parent=TopBar, FillDirection=Enum.FillDirection.Horizontal, VerticalAlignment=Enum.VerticalAlignment.Center, Padding=UDim.new(0,6)})
			SecContainer = Create("Frame",{Parent=TContent, BackgroundTransparency=1, Position=UDim2.new(0,0,0,44), Size=UDim2.new(1,0,1,-44), ClipsDescendants=true})
		else
			SecContainer = Create("Frame",{Parent=TContent, BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), ClipsDescendants=true})
		end

		local SecStorage = {}
		local ActiveSec, ActiveSecIdx = nil, 1

		local function ShowSec(name, idx)
			local nf=SecStorage[name]; if not nf or ActiveSec==nf then return end
			if ActiveSec then
				local old=ActiveSec; local d=(idx>ActiveSecIdx) and -1 or 1
				QT(old,0.32,{Position=UDim2.new(d,0,0,0)})
				task.delay(GT(0.32),function() if ActiveSec~=old then old.Visible=false end end)
				nf.Visible=true; nf.Position=UDim2.new(-d,0,0,0); QT(nf,0.32,{Position=UDim2.new(0,0,0,0)})
			end
			ActiveSec=nf; ActiveSecIdx=idx
		end

		local function CreateElements(ScrollFrame)
			local Elems = {}

			local Cont = Create("Frame",{Parent=ScrollFrame, BackgroundColor3=Library.Theme.ElementBg, BackgroundTransparency=0.5, BorderSizePixel=0, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y})
			Create("UIPadding",{Parent=Cont, PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4)})
			Create("UICorner",{Parent=Cont, CornerRadius=UDim.new(0,8)})
			Create("UIStroke",{Parent=Cont, Thickness=1, Color=Library.Theme.ElementStroke, Transparency=0.15})
			Create("UIListLayout",{Parent=Cont, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,0)})

			local TAccLine=Create("Frame",{Parent=Cont, BorderSizePixel=0, Size=UDim2.new(1,0,0,1), BackgroundColor3=Library.Theme.Accent, BackgroundTransparency=0.82, ZIndex=2})
			Create("UIGradient",{Parent=TAccLine, Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.18,0),NumberSequenceKeypoint.new(0.82,0),NumberSequenceKeypoint.new(1,1)})})
			Create("UICorner",{Parent=TAccLine, CornerRadius=UDim.new(0,8)})

			local function MakeRow(title, desc)
				local Row=Create("Frame",{Parent=Cont, BackgroundTransparency=1, Size=UDim2.new(1,0,0,38), BorderSizePixel=0})
				Create("UIPadding",{Parent=Row, PaddingLeft=UDim.new(0,10)})
				Create("Frame",{Parent=Row, BorderSizePixel=0, AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,0), Size=UDim2.new(1,0,0,1), BackgroundColor3=Library.Theme.ElementStroke, BackgroundTransparency=0.6, ZIndex=2})
				local Hl=Create("Frame",{Parent=Row, BorderSizePixel=0, Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,1,0), BackgroundColor3=Library.Theme.Accent, BackgroundTransparency=1, ZIndex=1})
				local RB=Create("TextButton",{Parent=Row, BackgroundTransparency=1, Size=UDim2.new(0.55,0,1,0), Text="", ZIndex=3})
				RB.MouseEnter:Connect(function() QT(Hl,0.14,{BackgroundTransparency=0.87}) end)
				RB.MouseLeave:Connect(function() QT(Hl,0.14,{BackgroundTransparency=1}) end)
				local TC=Create("Frame",{Parent=Row, BackgroundTransparency=1, Size=UDim2.new(0.55,0,1,0)})
				Create("UIPadding",{Parent=TC, PaddingLeft=UDim.new(0,10)})
				Create("UIListLayout",{Parent=TC, VerticalAlignment=Enum.VerticalAlignment.Center, Padding=UDim.new(0,2)})
				local TL=Create("TextLabel",{Parent=TC, BackgroundTransparency=1, Size=UDim2.new(1,0,0,16), Font=Library.Theme.Font, Text=title, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left})
				BindColor(TL,"TextColor3","TextMain")
				local DL=Create("TextLabel",{Parent=TC, BackgroundTransparency=1, Size=UDim2.new(1,0,0,12), Font=Library.Theme.Font, Text=desc, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd})
				BindColor(DL,"TextColor3","TextDim")
				Row.Position = UDim2.new(0, 0, 0, 8)
				task.defer(function()
					QT(Row, 0.22, {Position=UDim2.new(0,0,0,0)}, Enum.EasingStyle.Quart)
				end)
				return Row
			end

			local function MakeAttachments(RightFrame, toggleCb)
				local A = {}

				-- Улучшенная функция бинда
				function A:Bind(bo)
					local defKey = bo.Default
					local mode   = bo.Mode or "Toggle"
					local bindCb = bo.Callback or function() end
					
					local BB = Create("TextButton", {Parent=RightFrame, Size=UDim2.new(0,0,0,20), AutomaticSize=Enum.AutomaticSize.X, Text="", AutoButtonColor=false, LayoutOrder=5})
					BindColor(BB, "BackgroundColor3", "ElementBg")
					Create("UIPadding", {Parent=BB, PaddingLeft=UDim.new(0,7), PaddingRight=UDim.new(0,7)})
					Create("UICorner", {Parent=BB, CornerRadius=UDim.new(0,4)})
					ApplyGradient(BB, Library.Theme.ElementBg)
					GlowStroke(BB, Library.Theme.Accent, 1)

					local IC = Create("Frame", {Parent=BB, BackgroundTransparency=1, Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X})
					Create("UIListLayout", {Parent=IC, FillDirection=Enum.FillDirection.Horizontal, VerticalAlignment=Enum.VerticalAlignment.Center, Padding=UDim.new(0,4)})
					
					local textName = "None"
					if defKey then
						if type(defKey) == "string" then textName = defKey 
						elseif defKey.EnumType == Enum.KeyCode then textName = defKey.Name
						elseif defKey.EnumType == Enum.UserInputType then textName = string.gsub(defKey.Name, "MouseButton", "MB") end
					end

					local BL = Create("TextLabel", {Parent=IC, BackgroundTransparency=1, Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X, Font=Library.Theme.Font, Text=textName, TextSize=11, LayoutOrder=1})
					BindColor(BL, "TextColor3", "TextMain")
					local BI = Create("ImageLabel", {Parent=IC, BackgroundTransparency=1, Size=UDim2.new(0,10,0,10), Image=Assets.Keybind, LayoutOrder=2})
					BindColor(BI, "ImageColor3", "Accent")

					local key = defKey
					local binding = false

					BB.MouseButton1Click:Connect(function()
						binding = true
						BL.Text = "..."
					end)

					BB.MouseButton2Click:Connect(function()
						OpenPopup(BB, function(P)
							local sf = Create("ScrollingFrame", {Parent=P, BackgroundTransparency=1, Size=UDim2.new(0,0,0,88), AutomaticSize=Enum.AutomaticSize.X, CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=0})
							Create("UIListLayout", {Parent=sf, SortOrder=Enum.SortOrder.LayoutOrder})
							for _, m in ipairs({"Toggle", "Hold", "Always"}) do
								local ob = Create("TextButton", {Parent=sf, BackgroundTransparency=1, Size=UDim2.new(0,149,0,29), Text=m, Font=Library.Theme.Font, TextColor3=(mode==m) and Library.Theme.Accent or Library.Theme.TextDim, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, AutoButtonColor=false})
								Create("UIPadding", {Parent=ob, PaddingLeft=UDim.new(0,10)})
								ob.MouseButton1Click:Connect(function() mode = m; ClosePopup() end)
							end
						end)
					end)

					local function SetKey(nk)
						key = nk
						if nk == nil then
							BL.Text = "None"
						elseif type(nk) == "string" then
							BL.Text = nk
						elseif nk.EnumType == Enum.KeyCode then
							BL.Text = nk.Name
						elseif nk.EnumType == Enum.UserInputType then
							BL.Text = string.gsub(nk.Name, "MouseButton", "MB")
						end
						bindCb(nk)
					end

					UserInputService.InputBegan:Connect(function(inp, gp)
						if binding then
							binding = false
							if inp.UserInputType == Enum.UserInputType.Keyboard then
								if inp.KeyCode == Enum.KeyCode.Escape or inp.KeyCode == Enum.KeyCode.Backspace then
									SetKey(nil)
								else
									SetKey(inp.KeyCode)
								end
							elseif inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2 or inp.UserInputType == Enum.UserInputType.MouseButton3 then
								SetKey(inp.UserInputType)
							else
								binding = true; return
							end
							ClickFX(BB)
						elseif key and toggleCb and not gp then
							local tri = false
							if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == key then tri = true end
							if (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2 or inp.UserInputType == Enum.UserInputType.MouseButton3) and inp.UserInputType == key then tri = true end
							
							if tri then
								if mode == "Toggle" then
									toggleCb("Toggle")
								elseif mode == "Hold" then
									toggleCb(true)
								end
							end
						end
					end)

					UserInputService.InputEnded:Connect(function(inp, gp)
						if key and toggleCb and mode == "Hold" and not gp then
							local tri = false
							if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == key then tri = true end
							if (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2 or inp.UserInputType == Enum.UserInputType.MouseButton3) and inp.UserInputType == key then tri = true end
							
							if tri then
								toggleCb(false)
							end
						end
					end)

					local obj = {}
					obj.GetValue = function() return key end
					obj.SetValue = function(_, v) SetKey(v) end
					obj.GetMode = function() return mode end
					obj.SetMode = function(_, v) mode = v end
					obj.GetComponentType = function() return "Bind" end
					if bo.Flag then Library.Flags[bo.Flag] = obj end
					return A
				end

				function A:Colorpicker(cp)
					cp=cp or {}; local defC=cp.Default or Color3.fromRGB(255,255,255); local cpCb=cp.Callback or function() end
					local curC=defC; local curA=1; local hsv={Color3.toHSV(curC)}
					local CB=Create("TextButton",{Parent=RightFrame, Text="", Size=UDim2.new(0,15,0,15), BackgroundColor3=curC, AutoButtonColor=false, LayoutOrder=2})
					Create("UICorner",{Parent=CB, CornerRadius=UDim.new(1,0)}); GlowStroke(CB,Library.Theme.Accent,1.5)
					local PF=Create("Frame",{Name="ColorPickerPopup", Parent=SG, BorderSizePixel=0, Size=UDim2.new(0,220,0,222), Visible=false, ZIndex=3000})
					BindColor(PF,"BackgroundColor3","Main"); Create("UICorner",{Parent=PF,CornerRadius=UDim.new(0,10)}); GlowStroke(PF,Library.Theme.Accent,1.5)
					Create("UIPadding",{Parent=PF,PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10)}); Create("UIDragDetector",{Parent=PF})
					local CM=Create("TextButton",{Parent=PF,Size=UDim2.new(1,0,0,115),BackgroundColor3=Color3.fromHSV(hsv[1],1,1),AutoButtonColor=false,Text="",ZIndex=3001}); Create("UICorner",{Parent=CM,CornerRadius=UDim.new(0,6)})
					local SO=Create("Frame",{Parent=CM,Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1),ZIndex=3002,BorderSizePixel=0}); Create("UIGradient",{Parent=SO,Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}})
					local VO=Create("Frame",{Parent=CM,Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),ZIndex=3003,BorderSizePixel=0}); Create("UIGradient",{Parent=VO,Rotation=90,Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}})
					local MM=Create("ImageLabel",{Parent=CM,Size=UDim2.new(0,13,0,13),BackgroundTransparency=1,Image=Assets.PickerCursor,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(hsv[2],0,1-hsv[3],0),ZIndex=3004})
					local function MkS(lbl)
						local sf=Create("Frame",{Parent=PF,BackgroundTransparency=1,Size=UDim2.new(1,0,0,33)}); local tp=Create("Frame",{Parent=sf,BackgroundTransparency=1,Size=UDim2.new(1,0,0,13)})
						local tl2=Create("TextLabel",{Parent=tp,Text=lbl,Size=UDim2.new(1,-32,1,0),BackgroundTransparency=1,Font=Library.Theme.Font,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left}); BindColor(tl2,"TextColor3","TextDim")
						local vl=Create("TextLabel",{Parent=tp,Text="0",Size=UDim2.new(0,32,1,0),Position=UDim2.new(1,-32,0,0),BackgroundTransparency=1,Font=Library.Theme.Font,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right}); BindColor(vl,"TextColor3","Accent")
						local tr=Create("TextButton",{Parent=sf,BackgroundColor3=Color3.fromRGB(16,18,28),BorderSizePixel=0,Position=UDim2.new(0,0,0,17),Size=UDim2.new(1,0,0,4),Text="",AutoButtonColor=false}); Create("UICorner",{Parent=tr,CornerRadius=UDim.new(0,2)})
						local fl=Create("Frame",{Parent=tr,BorderSizePixel=0,Size=UDim2.new(0,0,1,0)}); BindColor(fl,"BackgroundColor3","Accent"); Create("UICorner",{Parent=fl,CornerRadius=UDim.new(0,2)})
						local th=Create("Frame",{Parent=tr,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.new(0,11,0,11),BackgroundTransparency=1}); BindColor(th,"BackgroundColor3","Accent"); Create("UICorner",{Parent=th,CornerRadius=UDim.new(1,0)})
						local it=Create("Frame",{Parent=th,BorderSizePixel=0,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(0,5,0,5),BackgroundTransparency=1}); BindColor(it,"BackgroundColor3","Main"); Create("UICorner",{Parent=it,CornerRadius=UDim.new(1,0)})
						tr.MouseEnter:Connect(function() QT(th,0.18,{BackgroundTransparency=0}); QT(it,0.18,{BackgroundTransparency=0}) end)
						tr.MouseLeave:Connect(function() QT(th,0.18,{BackgroundTransparency=1}); QT(it,0.18,{BackgroundTransparency=1}) end)
						return{Frame=sf,Track=tr,Fill=fl,Thumb=th,Label=vl}
					end
					Create("UIListLayout",{Parent=PF,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5)}); CM.LayoutOrder=1
					local HS=MkS("Hue"); HS.Frame.LayoutOrder=2; local AS=MkS("Opacity"); AS.Frame.LayoutOrder=3
					local function UV()
						CB.BackgroundColor3=curC; CM.BackgroundColor3=Color3.fromHSV(hsv[1],1,1)
						QT(MM,0.04,{Position=UDim2.new(hsv[2],0,1-hsv[3],0)})
						QT(HS.Fill,0.04,{Size=UDim2.new(hsv[1],0,1,0)}); QT(HS.Thumb,0.04,{Position=UDim2.new(hsv[1],0,0.5,0)}); HS.Label.Text=tostring(math.floor(hsv[1]*360))
						QT(AS.Fill,0.04,{Size=UDim2.new(curA,0,1,0)}); QT(AS.Thumb,0.04,{Position=UDim2.new(curA,0,0.5,0)}); AS.Label.Text=tostring(math.floor(curA*100)).."%"
						cpCb(curC,curA)
					end
					local function HI(go,tp,inp)
						local function U(pos)
							local px=math.clamp(pos.X-go.AbsolutePosition.X,0,go.AbsoluteSize.X)/go.AbsoluteSize.X
							local py=math.clamp(pos.Y-go.AbsolutePosition.Y,0,go.AbsoluteSize.Y)/go.AbsoluteSize.Y
							if tp=="Map" then hsv[2]=px; hsv[3]=1-py elseif tp=="Hue" then hsv[1]=px elseif tp=="Alpha" then curA=px end
							curC=Color3.fromHSV(hsv[1],hsv[2],hsv[3]); UV()
						end
						U(inp.Position)
						local mc=UserInputService.InputChanged:Connect(function(mv) if mv.UserInputType==Enum.UserInputType.MouseMovement or mv.UserInputType==Enum.UserInputType.Touch then U(mv.Position) end end)
						local ec; ec=UserInputService.InputEnded:Connect(function(e) if e.UserInputType==Enum.UserInputType.MouseButton1 or e.UserInputType==Enum.UserInputType.Touch then mc:Disconnect(); ec:Disconnect() end end)
					end
					CM.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then HI(CM,"Map",i) end end)
					HS.Track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then HI(HS.Track,"Hue",i) end end)
					AS.Track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then HI(AS.Track,"Alpha",i) end end)
					CB.MouseButton1Click:Connect(function()
						if PF.Visible then PF.Visible=false; return end; ClosePopup()
						local bp=CB.AbsolutePosition; local ss=SG.AbsoluteSize
						local x=bp.X-228; local y=bp.Y+22
						if x<0 then x=bp.X+32 end; if y+222>ss.Y then y=ss.Y-227 end
						PF.Position=UDim2.new(0,x,0,y); PF.Visible=true
					end)
					UserInputService.InputBegan:Connect(function(inp)
						if inp.UserInputType==Enum.UserInputType.MouseButton1 and PF.Visible then
							local mp=Vector2.new(inp.Position.X,inp.Position.Y)
							local function ins(f) local p,s=f.AbsolutePosition,f.AbsoluteSize; return mp.X>=p.X and mp.X<=p.X+s.X and mp.Y>=p.Y and mp.Y<=p.Y+s.Y end
							if not ins(PF) and not ins(CB) then PF.Visible=false end
						end
					end)
					local cpo={}; cpo.GetValue=function() return curC end; cpo.SetValue=function(_,v) curC=v; hsv={Color3.toHSV(v)}; UV() end; cpo.GetTransparency=function() return curA end; cpo.SetTransparency=function(_,v) curA=v; UV() end; cpo.GetComponentType=function() return "Colorpicker" end
					if cp.Flag then Library.Flags[cp.Flag]=cpo end; UV(); return A
				end
				return A
			end

			-- НОВАЯ ФУНКЦИЯ ДЛЯ ОТДЕЛЬНЫХ БИНДОВ
			function Elems:Keybind(o)
				local title = o.Title or "Keybind"
				local desc = o.Description or ""
				local def = o.Default
				local cb = o.Callback or function() end
				
				local Row = MakeRow(title, desc)
				local RS = Create("Frame", {Parent=Row, BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0), Size=UDim2.new(0,108,1,0), ZIndex=5})
				Create("UIListLayout", {Parent=RS, FillDirection=Enum.FillDirection.Horizontal, HorizontalAlignment=Enum.HorizontalAlignment.Right, VerticalAlignment=Enum.VerticalAlignment.Center, Padding=UDim.new(0,7)})
				
				local atts = MakeAttachments(RS, function(state) if state == "Toggle" then cb() else cb(state) end end)
				atts:Bind({Default = def, Mode = o.Mode, Flag = o.Flag, Callback = cb})
				
				return atts
			end

			function Elems:Toggle(o)
				local title=o.Title or "Toggle"; local desc=o.Description or ""; local def=o.Default or false; local cb=o.Callback or function() end
				local Row=MakeRow(title,desc); local state=def
				local RS=Create("Frame",{Parent=Row, BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0), Size=UDim2.new(0,108,1,0), ZIndex=5})
				Create("UIListLayout",{Parent=RS, FillDirection=Enum.FillDirection.Horizontal, HorizontalAlignment=Enum.HorizontalAlignment.Right, VerticalAlignment=Enum.VerticalAlignment.Center, Padding=UDim.new(0,7)})
				
				local SW=Create("TextButton",{Parent=RS, BorderSizePixel=0, Size=UDim2.new(0,38,0,20), Text="", AutoButtonColor=false, LayoutOrder=10})
				Create("UICorner",{Parent=SW, CornerRadius=UDim.new(1,0)})
				local SWS=GlowStroke(SW,Library.Theme.Accent,1); SWS.Transparency=0.75
				ApplyGradient(SW, state and Library.Theme.Accent or Library.Theme.ElementBg)
				local CL=Create("Frame",{Parent=SW, BackgroundColor3=state and Color3.new(1,1,1) or Color3.fromRGB(80,95,130), Position=state and UDim2.new(1,-18,0,3) or UDim2.new(0,3,0,3), Size=UDim2.new(0,14,0,14)})
				Create("UICorner",{Parent=CL, CornerRadius=UDim.new(1,0)})
				local CHK=Create("Frame",{Parent=CL, BackgroundTransparency=state and 0 or 1, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(0,5,0,5), BackgroundColor3=Library.Theme.Accent})
				Create("UICorner",{Parent=CHK, CornerRadius=UDim.new(1,0)})
				
				local function SetState(ns)
					if ns=="Toggle" then ns=not state end; if ns==state then return end; state=ns
					ApplyGradient(SW, Library.Theme[state and "Accent" or "ElementBg"])
					TweenGrad(SW, Library.Theme[state and "Accent" or "ElementBg"], 0.22)
					QT(CL,0.22,{BackgroundColor3=state and Color3.new(1,1,1) or Color3.fromRGB(80,95,130), Position=state and UDim2.new(1,-18,0,3) or UDim2.new(0,3,0,3)})
					QT(CHK,0.18,{BackgroundTransparency=state and 0 or 1}); QT(SWS,0.22,{Transparency=state and 0.15 or 0.75}); cb(state)
				end
				
				SW.MouseButton1Click:Connect(function() SetState("Toggle") end)
				
				local atts = MakeAttachments(RS, SetState)
				
				-- ИНТЕГРАЦИЯ БИНДОВ
				if o.Keybind ~= nil or o.HasBind then
					atts:Bind({
						Default = typeof(o.Keybind) == "EnumItem" and o.Keybind or nil,
						Callback = o.BindCallback,
						Flag = o.BindFlag
					})
				end
				
				local tobj={}; tobj.GetValue=function() return state end; tobj.SetValue=function(_,v) SetState(v) end; tobj.GetComponentType=function() return "Toggle" end
				if o.Flag then Library.Flags[o.Flag]=tobj end
				
				return atts
			end

			function Elems:Label(o)
				local Row=MakeRow(o.Title or "Label", o.Description or "")
				local RS=Create("Frame",{Parent=Row, BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0), Size=UDim2.new(0,108,1,0), ZIndex=5})
				Create("UIListLayout",{Parent=RS, FillDirection=Enum.FillDirection.Horizontal, HorizontalAlignment=Enum.HorizontalAlignment.Right, VerticalAlignment=Enum.VerticalAlignment.Center, Padding=UDim.new(0,7)})
				return MakeAttachments(RS)
			end

			function Elems:Slider(o)
				local title=o.Title or "Slider"; local desc=o.Description or ""; local min=o.Min or 0; local max=o.Max or 100
				local def=o.Default or min; local prefix=o.Prefix or ""; local suffix=o.Suffix or ""; local dual=o.Dual or false
				local decPrec=o.Decimal and 10^o.Decimal or 1; local zero=o.ZeroNumber; local cb=o.Callback or function() end
				local cv=def; local cmin=min; local cmax=max
				if dual then if type(def)=="table" then cmin=def.Min or min; cmax=def.Max or max else cmin=min; cmax=def or max end end
				local SR=Create("TextButton",{Parent=Cont, BackgroundTransparency=1, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, Text="", AutoButtonColor=false})
				local SC=Create("Frame",{Parent=SR, BackgroundTransparency=1, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y})
				Create("UIPadding",{Parent=SC, PaddingTop=UDim.new(0,9), PaddingBottom=UDim.new(0,11), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10)})
				Create("UIListLayout",{Parent=SC, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,5)})
				local TR=Create("Frame",{Parent=SC, BackgroundTransparency=1, Size=UDim2.new(1,0,0,16), LayoutOrder=1})
				local TL2=Create("TextLabel",{Parent=TR, BackgroundTransparency=1, Size=UDim2.new(1,-68,1,0), Font=Library.Theme.Font, Text=title, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left}); BindColor(TL2,"TextColor3","TextMain")
				local VL2=Create("TextLabel",{Parent=TR, BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,0,0,0), Size=UDim2.new(0,68,1,0), Font=Library.Theme.Font, Text="", TextSize=13, TextXAlignment=Enum.TextXAlignment.Right}); BindColor(VL2,"TextColor3","Accent")
				if desc~="" then local DL2=Create("TextLabel",{Parent=SC, BackgroundTransparency=1, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, Font=Library.Theme.Font, Text=desc, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, LayoutOrder=2}); BindColor(DL2,"TextColor3","TextDim") end
				local TC2=Create("Frame",{Parent=SC, BackgroundTransparency=1, Size=UDim2.new(1,0,0,10), LayoutOrder=3})
				local TRK=Create("Frame",{Parent=TC2, BackgroundColor3=Color3.fromRGB(16,18,28), BorderSizePixel=0, AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,0,0.5,0), Size=UDim2.new(1,0,0,4)}); Create("UICorner",{Parent=TRK, CornerRadius=UDim.new(0,2)})
				local FL=Create("Frame",{Parent=TRK, BorderSizePixel=0, Size=UDim2.new(0,0,1,0)}); BindColor(FL,"BackgroundColor3","Accent"); Create("UICorner",{Parent=FL, CornerRadius=UDim.new(0,2)})
				local FG=Create("Frame",{Parent=TRK, BorderSizePixel=0, Size=UDim2.new(0,0,0,7), AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,0,0.5,0), BackgroundColor3=Library.Theme.Accent, BackgroundTransparency=0.85, ZIndex=0}); Create("UICorner",{Parent=FG, CornerRadius=UDim.new(0,2)})
				local THX=Create("Frame",{Parent=TRK, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Size=UDim2.new(0,13,0,13), BackgroundTransparency=1}); BindColor(THX,"BackgroundColor3","Accent"); Create("UICorner",{Parent=THX, CornerRadius=UDim.new(1,0)})
				local ITX=Create("Frame",{Parent=THX, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(0,5,0,5), BackgroundTransparency=1}); BindColor(ITX,"BackgroundColor3","Main"); Create("UICorner",{Parent=ITX, CornerRadius=UDim.new(1,0)})
				local THN,ITN
				if dual then
					THN=Create("Frame",{Parent=TRK, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Size=UDim2.new(0,13,0,13), BackgroundTransparency=1}); BindColor(THN,"BackgroundColor3","Accent"); Create("UICorner",{Parent=THN, CornerRadius=UDim.new(1,0)})
					ITN=Create("Frame",{Parent=THN, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(0,5,0,5), BackgroundTransparency=1}); BindColor(ITN,"BackgroundColor3","Main"); Create("UICorner",{Parent=ITN, CornerRadius=UDim.new(1,0)})
				end
				local function Rnd(n) return math.floor(n*decPrec+0.5)/decPrec end
				local function UpdS()
					if dual then
						local pm=math.clamp((cmin-min)/(max-min),0,1); local px=math.clamp((cmax-min)/(max-min),0,1)
						QT(FL,0.04,{Position=UDim2.new(pm,0,0,0),Size=UDim2.new(px-pm,0,1,0)}); QT(FG,0.04,{Position=UDim2.new(pm,0,0.5,0),Size=UDim2.new(px-pm,0,0,7)})
						QT(THN,0.04,{Position=UDim2.new(pm,0,0.5,0)}); QT(THX,0.04,{Position=UDim2.new(px,0,0.5,0)}); VL2.Text=prefix..Rnd(cmin).." – "..Rnd(cmax)..suffix
					else
						local sv=zero or min; local pv=math.clamp((cv-min)/(max-min),0,1); local pz=math.clamp((sv-min)/(max-min),0,1)
						QT(FL,0.04,{Position=UDim2.new(math.min(pz,pv),0,0,0),Size=UDim2.new(math.abs(pv-pz),0,1,0)}); QT(FG,0.04,{Position=UDim2.new(math.min(pz,pv),0,0.5,0),Size=UDim2.new(math.abs(pv-pz),0,0,7)})
						QT(THX,0.04,{Position=UDim2.new(pv,0,0.5,0)}); VL2.Text=prefix..Rnd(cv)..suffix
					end
				end
				UpdS()
				local dragging=false; local dragT="Max"
				local function US(inp) local pct=math.clamp((inp.Position.X-TRK.AbsolutePosition.X)/TRK.AbsoluteSize.X,0,1); local val=Rnd(min+(max-min)*pct); if dual then if dragT=="Min" then cmin=math.min(val,cmax) else cmax=math.max(val,cmin) end; UpdS(); cb(cmin,cmax) else cv=val; UpdS(); cb(cv) end end
				local function TV(t) QT(THX,0.18,{BackgroundTransparency=t}); QT(ITX,0.18,{BackgroundTransparency=t}); if THN then QT(THN,0.18,{BackgroundTransparency=t}); QT(ITN,0.18,{BackgroundTransparency=t}) end end
				SR.MouseEnter:Connect(function() TV(0) end); SR.MouseLeave:Connect(function() TV(1) end)
				SR.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; if dual then local mx=inp.Position.X; dragT=math.abs(mx-THN.AbsolutePosition.X)<=math.abs(mx-THX.AbsolutePosition.X) and "Min" or "Max" else dragT="Max" end; US(inp) end end)
				UserInputService.InputChanged:Connect(function(inp) if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then US(inp) end end)
				UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
				local sobj={}; sobj.GetValue=function() return dual and {Min=cmin,Max=cmax} or cv end; sobj.SetValue=function(_,v) if dual and type(v)=="table" then cmin=v.Min or min; cmax=v.Max or max; UpdS() elseif not dual then cv=v; UpdS() end end; sobj.GetComponentType=function() return "Slider" end
				if o.Flag then Library.Flags[o.Flag]=sobj end
			end

			function Elems:Dropdown(o)
				local title=o.Title or "Dropdown"; local desc=o.Description or ""; local opts=o.Options or {}; local def=o.Default or (o.Multi and {}) or "Select..."; local multi=o.Multi or false; local cb=o.Callback or function() end
				local Row=MakeRow(title,desc)
				local BX=Create("TextButton",{Parent=Row, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0), Size=UDim2.new(0,150,0,26), Text="", AutoButtonColor=false, BorderSizePixel=0})
				BindColor(BX,"BackgroundColor3","ElementBg"); Create("UICorner",{Parent=BX, CornerRadius=UDim.new(0,5)}); ApplyGradient(BX,Library.Theme.ElementBg); GlowStroke(BX,Library.Theme.Accent,1)
				local CL2=Create("TextLabel",{Parent=BX, BackgroundTransparency=1, Position=UDim2.new(0,9,0,0), Size=UDim2.new(1,-28,1,0), Font=Library.Theme.Font, Text="", TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}); BindColor(CL2,"TextColor3","TextMain")
				local DI=Create("ImageLabel",{Parent=BX, BackgroundTransparency=1, Position=UDim2.new(1,-21,0.5,-7), Size=UDim2.new(0,14,0,14), Image=Assets.Dropdown}); BindColor(DI,"ImageColor3","Accent")
				local sel=multi and (type(def)=="table" and def or {}) or def
				local function UT() local t=multi and (#sel==0 and "Select..." or table.concat(sel,", ")) or tostring(sel); CL2.Text=t; local ts=TextService:GetTextSize(t,12,Library.Theme.Font,Vector2.new(1000,24)).X; local tw=math.clamp(ts+40,150,258); QT(BX,0.18,{Size=UDim2.new(0,tw,0,26),AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0)}) end; UT()
				local function RL(cont) for _,c in ipairs(cont:GetChildren()) do if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end end; for i,opt in ipairs(opts) do local is=multi and (function() for _,s in ipairs(sel) do if s==opt then return true end end; return false end)() or (sel==opt); local ob=Create("TextButton",{Parent=cont, BackgroundTransparency=1, Size=UDim2.new(0,150,0,27), Text=opt, Font=Library.Theme.Font, TextColor3=is and Library.Theme.Accent or Library.Theme.TextDim, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, AutoButtonColor=false}); Create("UIPadding",{Parent=ob, PaddingLeft=UDim.new(0,9)}); ob.MouseEnter:Connect(function() QT(ob,0.14,{TextColor3=Library.Theme.TextMain}) end); ob.MouseLeave:Connect(function() local s2=multi and (function() for _,s in ipairs(sel) do if s==opt then return true end end; return false end)() or (sel==opt); QT(ob,0.14,{TextColor3=s2 and Library.Theme.Accent or Library.Theme.TextDim}) end); if i<#opts then local sep=Create("Frame",{Parent=ob, BorderSizePixel=0, Size=UDim2.new(1,-18,0,1), Position=UDim2.new(0,9,1,-1)}); BindColor(sep,"BackgroundColor3","ElementStroke") end; ob.MouseButton1Click:Connect(function() if multi then local found=false; for idx,s in ipairs(sel) do if s==opt then table.remove(sel,idx); found=true; break end end; if not found then table.insert(sel,opt) end; UT(); cb(sel) else sel=opt; UT(); cb(opt); ClosePopup() end end) end end
				BX.MouseButton1Click:Connect(function() OpenPopup(BX,function(cont) local sf=Create("ScrollingFrame",{Parent=cont, BackgroundTransparency=1, Size=UDim2.new(1,0,0,math.min(#opts*27,230)), AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=2, BorderSizePixel=0}); Create("UIListLayout",{Parent=sf, SortOrder=Enum.SortOrder.LayoutOrder}); RL(sf) end) end)
				local dobj={}; dobj.GetValue=function() return sel end; dobj.SetValue=function(_,v) sel=v; UT() end; dobj.GetOptions=function() return opts end; dobj.SetOptions=function(_,v) opts=v end; dobj.GetComponentType=function() return "Dropdown" end
				if o.Flag then Library.Flags[o.Flag]=dobj end
			end

			function Elems:Textbox(o)
				local title=o.Title or "Textbox"; local desc=o.Description or ""; local ph=o.Placeholder or "Type here..."; local def2=o.Default or ""; local cof=o.ClearOnFocus; local cb=o.Callback or function() end
				local Row=MakeRow(title,desc)
				local BX2=Create("Frame",{Parent=Row, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0), Size=UDim2.new(0,150,0,26), ClipsDescendants=true, BorderSizePixel=0})
				BindColor(BX2,"BackgroundColor3","ElementBg"); Create("UICorner",{Parent=BX2, CornerRadius=UDim.new(0,5)}); ApplyGradient(BX2,Library.Theme.ElementBg); local BS=GlowStroke(BX2,Library.Theme.Accent,1); BS.Transparency=0.72
				local INP=Create("TextBox",{Parent=BX2, BackgroundTransparency=1, Position=UDim2.new(0,9,0,0), Size=UDim2.new(1,-26,1,0), Font=Library.Theme.Font, Text=def2, PlaceholderText=ph, TextColor3=Library.Theme.TextMain, PlaceholderColor3=Library.Theme.TextDim, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=cof, TextTruncate=Enum.TextTruncate.AtEnd})
				Create("ImageLabel",{Parent=BX2, BackgroundTransparency=1, Position=UDim2.new(1,-18,0.5,-5), Size=UDim2.new(0,10,0,10), Image=Assets.Textbox}):ClearAllChildren()
				local TI=Create("ImageLabel",{Parent=BX2, BackgroundTransparency=1, Position=UDim2.new(1,-18,0.5,-5), Size=UDim2.new(0,10,0,10), Image=Assets.Textbox}); BindColor(TI,"ImageColor3","Accent")
				INP.Focused:Connect(function() QT(BS,0.18,{Transparency=0.15}) end); INP.FocusLost:Connect(function() QT(BS,0.18,{Transparency=0.72}); cb(INP.Text); ClickFX(BX2) end)
				local function UW() local ts=TextService:GetTextSize(INP.Text,12,Library.Theme.Font,Vector2.new(1000,24)).X; local tw=math.clamp(ts+20,150,258); QT(BX2,0.18,{Size=UDim2.new(0,tw,0,26),AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0)}) end
				INP:GetPropertyChangedSignal("Text"):Connect(UW)
				local tobj2={}; tobj2.GetValue=function() return INP.Text end; tobj2.SetValue=function(_,v) INP.Text=v; UW() end; tobj2.GetComponentType=function() return "Textbox" end
				if o.Flag then Library.Flags[o.Flag]=tobj2 end
			end

			function Elems:Button(o)
				local title=o.Title or "Button"; local desc=o.Description or ""; local action=o.Action or "Execute"; local cb=o.Callback or function() end
				local onBindSet = o.OnBindSet or function() end
				local Row=MakeRow(title,desc)
				-- Right frame holds: bind chip + action button
				local RS=Create("Frame",{Parent=Row, BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0), Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X, ZIndex=5})
				Create("UIListLayout",{Parent=RS, FillDirection=Enum.FillDirection.Horizontal, HorizontalAlignment=Enum.HorizontalAlignment.Right, VerticalAlignment=Enum.VerticalAlignment.Center, Padding=UDim.new(0,6)})

				-- Built-in keybind button (LayoutOrder=9)
				local _bKey=nil; local _bWait=false
				local KBtn=Create("TextButton",{Parent=RS, Text="bind", Size=UDim2.new(0,0,0,20), AutomaticSize=Enum.AutomaticSize.X, AutoButtonColor=false, BorderSizePixel=0, Font=Library.Theme.Font, TextSize=10, LayoutOrder=9, ZIndex=6})
				Create("UIPadding",{Parent=KBtn, PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6)})
				Create("UICorner",{Parent=KBtn, CornerRadius=UDim.new(0,4)})
				BindColor(KBtn,"BackgroundColor3","ElementBg"); BindColor(KBtn,"TextColor3","TextDim")
				GlowStroke(KBtn, Library.Theme.ElementStroke, 1)
				local function KBRefresh()
					if _bKey then
						local n=(_bKey.EnumType==Enum.KeyCode and _bKey.Name) or (_bKey==Enum.UserInputType.MouseButton1 and "MB1") or (_bKey==Enum.UserInputType.MouseButton2 and "MB2") or "MB3"
						KBtn.Text=n; KBtn.BackgroundColor3=Library.Theme.Accent; KBtn.TextColor3=Color3.new(1,1,1)
					else
						KBtn.Text="bind"; KBtn.BackgroundColor3=Library.Theme.ElementBg; KBtn.TextColor3=Library.Theme.TextDim
					end
				end
				-- Load default bind if provided
				if o.DefaultBind and o.DefaultBind ~= "None" then
					local ok, key = pcall(function() return Enum.KeyCode[o.DefaultBind] end)
					if ok and key then _bKey = key; KBRefresh() end
				end
				KBtn.MouseButton1Click:Connect(function()
					if _bWait then return end
					_bWait=true; KBtn.Text="..."; KBtn.BackgroundColor3=Library.Theme.AccentAlt; KBtn.TextColor3=Color3.new(0,0,0)
				end)
				KBtn.MouseButton2Click:Connect(function()
					OpenPopup(KBtn,function(P)
						local sf=Create("ScrollingFrame",{Parent=P, BackgroundTransparency=1, Size=UDim2.new(0,0,0,58), AutomaticSize=Enum.AutomaticSize.X, CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=0})
						Create("UIListLayout",{Parent=sf, SortOrder=Enum.SortOrder.LayoutOrder})
						local reset=Create("TextButton",{Parent=sf, BackgroundTransparency=1, Size=UDim2.new(0,149,0,29), Text="  ✖ Clear bind", Font=Library.Theme.Font, TextColor3=Color3.fromRGB(255,80,80), TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, AutoButtonColor=false})
						Create("UIPadding",{Parent=reset, PaddingLeft=UDim.new(0,10)})
						reset.MouseButton1Click:Connect(function() _bKey=nil; KBRefresh(); onBindSet(nil); ClosePopup() end)
					end)
				end)
				-- Declare BX3 upvalue before InputBegan so the closure can reference it
				local BX3
				UserInputService.InputBegan:Connect(function(inp)
					if _bWait then
						_bWait=false
						if inp.UserInputType==Enum.UserInputType.Keyboard then
							if inp.KeyCode==Enum.KeyCode.Escape then _bKey=nil else _bKey=inp.KeyCode end
						elseif inp.UserInputType==Enum.UserInputType.MouseButton1 then _bKey=Enum.UserInputType.MouseButton1
						elseif inp.UserInputType==Enum.UserInputType.MouseButton2 then _bKey=Enum.UserInputType.MouseButton2
						else _bWait=true; return end
						-- Flash KBtn (no UIGradient on it, use tween on BackgroundColor3)
						KBtn.BackgroundColor3 = Library.Theme.Accent
						task.delay(0.18, function() KBtn.BackgroundColor3 = Library.Theme.ElementBg; KBRefresh() end)
						KBRefresh(); onBindSet(_bKey); return
					end
					if _bKey and BX3 then
						local hit=(inp.UserInputType==Enum.UserInputType.Keyboard and inp.KeyCode==_bKey) or (inp.UserInputType==_bKey)
						if hit then ClickFX(BX3); task.spawn(cb) end
					end
				end)

				-- Action button (LayoutOrder=10)
				BX3=Create("TextButton",{Parent=RS, AnchorPoint=Vector2.new(1,0.5), Size=UDim2.new(0,0,0,26), AutomaticSize=Enum.AutomaticSize.X, Text="", AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=10})
				BindColor(BX3,"BackgroundColor3","ElementBg"); Create("UICorner",{Parent=BX3, CornerRadius=UDim.new(0,5)}); ApplyGradient(BX3,Library.Theme.ElementBg); local BS2=GlowStroke(BX3,Library.Theme.Accent,1); BS2.Transparency=0.72
				Create("UIPadding",{Parent=BX3, PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12)}); local BL2=Create("TextLabel",{Parent=BX3, BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Font=Library.Theme.Font, Text=action, TextSize=12, TextXAlignment=Enum.TextXAlignment.Center, AutomaticSize=Enum.AutomaticSize.X}); BindColor(BL2,"TextColor3","TextDim")
				BX3.MouseEnter:Connect(function() QT(BL2,0.18,{TextColor3=Library.Theme.TextMain}); QT(BS2,0.18,{Transparency=0.25}) end); BX3.MouseLeave:Connect(function() QT(BL2,0.18,{TextColor3=Library.Theme.TextDim}); QT(BS2,0.18,{Transparency=0.72}) end)
				BX3.MouseButton1Click:Connect(function()
					ClickFX(BX3)
					local R=Create("Frame",{Parent=BX3, BackgroundColor3=Library.Theme.Accent, BackgroundTransparency=0.55, BorderSizePixel=0, AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0), Size=UDim2.new(0,0,0,0), ZIndex=5}); Create("UICorner",{Parent=R, CornerRadius=UDim.new(1,0)})
					QT(R,0.38,{Size=UDim2.new(2,0,2,0),BackgroundTransparency=1}); task.delay(0.38,function() if R and R.Parent then R:Destroy() end end); task.spawn(cb)
				end)
			end

			function Elems:Notice(o)
				local txt=o.Text or ""; local ntype=o.Type or "Info"
				local tc={Info=Color3.fromRGB(50,130,255),Warning=Color3.fromRGB(255,190,30),Error=Color3.fromRGB(255,55,70),Success=Color3.fromRGB(30,210,100)}
				local nc=tc[ntype] or tc.Info
				local NF=Create("Frame",{Parent=Cont, BackgroundTransparency=1, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y})
				Create("UIPadding",{Parent=NF, PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4), PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6)})
				Create("Frame",{Parent=NF, BorderSizePixel=0, Size=UDim2.new(0,3,1,0), BackgroundColor3=nc})
				local NI=Create("Frame",{Parent=NF, BorderSizePixel=0, BackgroundColor3=nc, BackgroundTransparency=0.88, Position=UDim2.new(0,10,0,0), Size=UDim2.new(1,-10,1,0), AutomaticSize=Enum.AutomaticSize.Y})
				Create("UICorner",{Parent=NI, CornerRadius=UDim.new(0,5)}); Create("UIPadding",{Parent=NI, PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8), PaddingTop=UDim.new(0,6), PaddingBottom=UDim.new(0,6)})
				Create("TextLabel",{Parent=NI, BackgroundTransparency=1, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, Font=Library.Theme.Font, Text=txt, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, TextColor3=nc})
			end

			return Elems
		end

		if #Sections > 0 then
			for i, sname in ipairs(Sections) do
				local SBtn=Create("TextButton",{Parent=TopBar, BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, Size=UDim2.new(0,0,1,0), AutoButtonColor=false, Text="", AutomaticSize=Enum.AutomaticSize.X})
				Create("UIPadding",{Parent=SBtn, PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14)}); Create("UICorner",{Parent=SBtn, CornerRadius=UDim.new(0,5)})
				local SBL=Create("TextLabel",{Parent=SBtn, BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Font=Library.Theme.Font, Text=sname, TextColor3=(i==1) and Color3.new(0,0,0) or Library.Theme.TextDim, TextSize=13, ZIndex=2})
				ApplyGradient(SBtn,Library.Theme.ElementBg)
				local SAG=Create("UIGradient",{Name="ActiveGradient", Parent=SBtn, Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Library.Theme.Accent),ColorSequenceKeypoint.new(1,GetDarkerColor(Library.Theme.Accent))}), Rotation=90, Enabled=(i==1)})
				table.insert(Library.Registry,{Object=SAG, ThemeKey="Accent", Type="ActiveGradient"})
			local SF=Create("ScrollingFrame",{Parent=SecContainer, BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), ScrollBarThickness=4, ScrollBarImageColor3=Library.Theme.Accent, ScrollBarImageTransparency=0.6, Visible=(i==1), AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0), ScrollingEnabled=true, ElasticBehavior=Enum.ElasticBehavior.Always})
				local sbFade; SF:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
					SF.ScrollBarImageTransparency = 0.1
					if sbFade then sbFade:Cancel() end
					sbFade = TweenService:Create(SF, TweenInfo.new(1.2, Enum.EasingStyle.Quart), {ScrollBarImageTransparency=0.6})
					sbFade:Play()
				end)
				Create("UIPadding",{Parent=SF, PaddingRight=UDim.new(0,2), PaddingLeft=UDim.new(0,2), PaddingTop=UDim.new(0,6)})
				Create("UIListLayout",{Parent=SF, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)})
				SecStorage[sname]=SF
				if i==1 then
					local ng=SBtn:FindFirstChildOfClass("UIGradient"); if ng and ng.Name~="ActiveGradient" then ng.Enabled=false end
					ActiveSec=SF
				end
				SBtn.MouseButton1Click:Connect(function()
					for _,b in ipairs(TopBar:GetChildren()) do if b:IsA("TextButton") then local ng=b:FindFirstChildOfClass("UIGradient"); if ng and ng.Name~="ActiveGradient" then ng.Enabled=true end; if b:FindFirstChild("TextLabel") then b.TextLabel.TextColor3=Library.Theme.TextDim end; if b:FindFirstChild("ActiveGradient") then b.ActiveGradient.Enabled=false end end end
					local ng=SBtn:FindFirstChildOfClass("UIGradient"); if ng and ng.Name~="ActiveGradient" then ng.Enabled=false end
					if SBtn:FindFirstChild("ActiveGradient") then SBtn.ActiveGradient.Enabled=true end
					if SBtn:FindFirstChild("TextLabel") then SBtn.TextLabel.TextColor3=Color3.new(0,0,0) end
					ShowSec(sname,i)
				end)
			end
		else
			local DF=Create("ScrollingFrame",{Parent=SecContainer, BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), ScrollBarThickness=4, ScrollBarImageColor3=Library.Theme.Accent, ScrollBarImageTransparency=0.6, AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0), ScrollingEnabled=true, ElasticBehavior=Enum.ElasticBehavior.Always})
			local dfFade; DF:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
				DF.ScrollBarImageTransparency = 0.1
				if dfFade then dfFade:Cancel() end
				dfFade = TweenService:Create(DF, TweenInfo.new(1.2, Enum.EasingStyle.Quart), {ScrollBarImageTransparency=0.6})
				dfFade:Play()
			end)
			Create("UIPadding",{Parent=DF, PaddingRight=UDim.new(0,2), PaddingLeft=UDim.new(0,2), PaddingTop=UDim.new(0,6)})
			Create("UIListLayout",{Parent=DF, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)})
			SecStorage["Default"]=DF; ActiveSec=DF
		end

		local TF = {}
		function TF:GetSection(name)
			local sf=SecStorage[name] or SecStorage["Default"]
			if sf then return CreateElements(sf) end
		end
		if #Sections==0 then
			local de=CreateElements(SecStorage["Default"])
			for fn,f in pairs(de) do
				if type(f)=="function" then
					TF[fn]=function(_, ...) return f(de, ...) end
				end
			end
		end

		local tabEntry = {Btn=TBtn, Content=TContent, Lbl=TBtnLbl}
		table.insert(Tabs, tabEntry)
		local thisIdx = #Tabs

		local function DeactivateAll()
			Library._ActiveTabBtns = {}
			for _, t in ipairs(Tabs) do
				t.Active = false
				t.Btn.BackgroundColor3 = Color3.fromRGB(16,16,24)
				t.Lbl.Font = Library.Theme.Font
				QT(t.Lbl, 0.15, {TextColor3=Color3.fromRGB(75,85,120)})
			end
		end

		local function ActivateThis()
			DeactivateAll()
			TBtnActive = true
			table.insert(Library._ActiveTabBtns, TBtn)
			TBtnLbl.Font = Library.Theme.FontBold
			QT(TBtnLbl, 0.15, {TextColor3=Color3.fromRGB(200,210,255)})
		end

		local function FadeInContent(content)
			local rows = {}
			local function collect(f)
				for _, c in ipairs(f:GetChildren()) do
					if c:IsA("Frame") and c.Size.Y.Offset == 38 then
						table.insert(rows, c)
					elseif c:IsA("Frame") or c:IsA("ScrollingFrame") then
						collect(c)
					end
				end
			end
			collect(content)
			for i, row in ipairs(rows) do
				row.Position = UDim2.new(0, 0, 0, 12)
				task.delay((i-1) * 0.035, function()
					if row and row.Parent then
						QT(row, 0.28, {Position=UDim2.new(0,0,0,0)}, Enum.EasingStyle.Quart)
					end
				end)
			end
		end

		TBtn.MouseButton1Click:Connect(function()
			if ActiveTab == TContent then return end
			ActivateThis()
			if ActiveTab then
				local old = ActiveTab
				local dir = (thisIdx > ActiveTabIdx) and -1 or 1
				QT(old, 0.35, {Position=UDim2.new(0,0,dir,0)})
				task.delay(GT(0.35), function() if ActiveTab ~= old then old.Visible = false end end)
				ActiveTab = TContent; ActiveTabIdx = thisIdx
				TContent.Visible = true
				TContent.Position = UDim2.new(0,0,-dir,0)
				QT(TContent, 0.35, {Position=UDim2.new(0,0,0,0)})
				task.delay(0.1, function() FadeInContent(TContent) end)
			else
				ActiveTab = TContent; ActiveTabIdx = thisIdx; TContent.Visible = true
				FadeInContent(TContent)
			end
		end)

		if FirstTab then
			ActivateThis()
			TContent.Visible = true; ActiveTab = TContent; ActiveTabIdx = thisIdx; FirstTab = false
			task.defer(function() FadeInContent(TContent) end)
		end

		return TF
	end

	return WF
end

-- ============================================================
-- ScaleUI: рекурсивный масштаб всего дерева UI
-- ============================================================
Library._UIScaleTargets = {}

local function _collectOriginals(frame, store)
	for _, child in ipairs(frame:GetDescendants()) do
		local data = {}
		local hasData = false
		if child:IsA("GuiObject") then
			data.sxo=child.Size.X.Offset; data.sxs=child.Size.X.Scale
			data.syo=child.Size.Y.Offset; data.sys=child.Size.Y.Scale
			data.pxo=child.Position.X.Offset; data.pxs=child.Position.X.Scale
			data.pyo=child.Position.Y.Offset; data.pys=child.Position.Y.Scale
			hasData=true
		end
		if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
			data.ts=child.TextSize; hasData=true
		end
		if child:IsA("UIPadding") then
			data.pt=child.PaddingTop.Offset; data.pb=child.PaddingBottom.Offset
			data.pl=child.PaddingLeft.Offset; data.pr=child.PaddingRight.Offset
			hasData=true
		end
		if child:IsA("UIStroke") then data.stk=child.Thickness; hasData=true end
		if hasData then store[child]=data end
	end
	store[frame]={
		sxo=frame.Size.X.Offset, sxs=frame.Size.X.Scale,
		syo=frame.Size.Y.Offset, sys=frame.Size.Y.Scale,
		pxo=frame.Position.X.Offset, pxs=frame.Position.X.Scale,
		pyo=frame.Position.Y.Offset, pys=frame.Position.Y.Scale,
		_isRoot=true
	}
end

local function _applyScale(store, scale)
	for obj, data in pairs(store) do
		if not (obj and obj.Parent) then continue end
		if obj:IsA("GuiObject") then
			obj.Size=UDim2.new(data.sxs,math.round(data.sxo*scale),data.sys,math.round(data.syo*scale))
			if not data._isRoot then
				obj.Position=UDim2.new(data.pxs,math.round(data.pxo*scale),data.pys,math.round(data.pyo*scale))
			end
		end
		if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) and data.ts then
			obj.TextSize=math.max(6,math.round(data.ts*scale))
		end
		if obj:IsA("UIPadding") then
			obj.PaddingTop=UDim.new(0,math.round(data.pt*scale))
			obj.PaddingBottom=UDim.new(0,math.round(data.pb*scale))
			obj.PaddingLeft=UDim.new(0,math.round(data.pl*scale))
			obj.PaddingRight=UDim.new(0,math.round(data.pr*scale))
		end
		if obj:IsA("UIStroke") and data.stk then
			obj.Thickness=math.max(0.5,data.stk*scale)
		end
	end
end

function Library:RegisterScaleTarget(key, frame, baseW, baseH, extraCb)
	local originals={}
	_collectOriginals(frame,originals)
	Library._UIScaleTargets[key]={frame=frame,baseW=baseW,baseH=baseH,originals=originals,extraCb=extraCb}
end

function Library:ScaleUI(key, scale)
	local t=Library._UIScaleTargets[key]
	if not t then return end
	local f=t.frame
	if not (f and f.Parent) then return end
	_applyScale(t.originals,scale)
	if t.extraCb then t.extraCb(f,scale,math.round(t.baseW*scale),math.round(t.baseH*scale)) end
end

return Library
