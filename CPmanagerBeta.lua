local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player           = Players.LocalPlayer

-- Const
local FRAME_W   = 250
local FRAME_H   = 350
local TOPBAR_H  = 30
local BOTTOM_H  = 65
local LIST_H    = FRAME_H - TOPBAR_H - BOTTOM_H   -- 255 px
local BTN_H     = 30
local BTN_PAD   = 4
local SIDE_W    = 22   -- icons width

local COL_BG         = Color3.fromRGB(59,  51,  65)
local COL_BAR        = Color3.fromRGB(45,  38,  50)
local COL_BTN        = Color3.fromRGB(80,  70,  90)
local COL_BTN_ACTIVE = Color3.fromRGB(130, 105, 160)
local COL_BTN_ADD    = Color3.fromRGB(80,  160, 90)
local COL_BTN_NAV    = Color3.fromRGB(65,  58,  78)
local COL_BTN_REN    = Color3.fromRGB(50,  100, 160)
local COL_BTN_DEL    = Color3.fromRGB(160, 55,  55)
local COL_BTN_WARN   = Color3.fromRGB(180, 130, 30)
local COL_BORDER     = Color3.fromRGB(196, 197, 180)
local COL_WHITE      = Color3.fromRGB(255, 255, 255)
local COL_PANEL      = Color3.fromRGB(35,  29,  42)

-- Перемени
local checkpoints   = {}   -- Vector3
local cpNames       = {}   -- string
local currentIndex  = 0
local renamingIndex = nil  -- Checkpoint index
local minimized     = false

-- forward declarations
local keybindPanel
local panelOpen = false
local ioPanel
local ioPanelOpen = false

-- binds
local binds = {
	{ id = "add",      label = "add checkpoint",       key = Enum.KeyCode.C },
	{ id = "teleport", label = "teleport",       key = Enum.KeyCode.V },
	{ id = "prev",     label = "previous",  key = Enum.KeyCode.Q },
	{ id = "next",     label = "next",  key = Enum.KeyCode.E },
}
local rebindingId = nil   -- контейнер для бинда

local function getBind(id)
	for _, b in ipairs(binds) do
		if b.id == id then return b.key end
	end
end

-- helpers
local function getHRP()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:WaitForChild("HumanoidRootPart")
end

local function safeInitPos()
	local cam = workspace.CurrentCamera
	local vp  = cam and cam.ViewportSize or Vector2.new(1280, 720)
	return UDim2.fromOffset(math.max(0, vp.X - FRAME_W - 10), math.max(0, vp.Y - FRAME_H - 10))
end

local function makeCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 4)
	c.Parent = parent
end

local function makeTextBtn(parent, text, bg, x, y, w, h, tSize, zIdx)
	local b = Instance.new("TextButton")
	b.Size             = UDim2.fromOffset(w, h)
	b.Position         = UDim2.fromOffset(x, y)
	b.Text             = text
	b.BackgroundColor3 = bg
	b.TextColor3       = COL_WHITE
	b.Font             = Enum.Font.SourceSansBold
	b.TextSize         = tSize or 13
	b.BorderSizePixel  = 0
	b.ZIndex           = zIdx or 4
	b.AutoButtonColor  = true
	makeCorner(b, 4)
	b.Parent = parent
	return b
end

-- Main GUI
local gui = Instance.new("ScreenGui")
gui.Name           = "CheckpointGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = player:WaitForChild("PlayerGui")

-- MainFrame
local frame = Instance.new("Frame")
frame.Size             = UDim2.fromOffset(FRAME_W, FRAME_H)
frame.Position         = safeInitPos()
frame.BackgroundColor3 = COL_BG
frame.BorderSizePixel  = 2
frame.BorderColor3     = COL_BORDER
frame.ClipsDescendants = true
frame.Parent           = gui

-- TopBar
local topBar = Instance.new("Frame")
topBar.Size             = UDim2.new(1, 0, 0, TOPBAR_H)
topBar.BackgroundColor3 = COL_BAR
topBar.BorderSizePixel  = 0
topBar.ZIndex           = 3
topBar.Parent           = frame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(1, -112, 1, 0)
titleLabel.Position           = UDim2.fromOffset(6, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text               = "0_0 CPManager"
titleLabel.TextColor3         = COL_WHITE
titleLabel.Font               = Enum.Font.SourceSansBold
titleLabel.TextSize           = 18
titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
titleLabel.ZIndex             = 4
titleLabel.Parent             = topBar

local indexLabel = Instance.new("TextLabel")
indexLabel.Size               = UDim2.fromOffset(40, TOPBAR_H)
indexLabel.Position           = UDim2.new(1, -104, 0, 0)
indexLabel.BackgroundTransparency = 1
indexLabel.Text               = "0 / 0"
indexLabel.TextColor3         = Color3.fromRGB(196, 197, 180)
indexLabel.Font               = Enum.Font.SourceSans
indexLabel.TextSize           = 15
indexLabel.TextXAlignment     = Enum.TextXAlignment.Right
indexLabel.ZIndex             = 4
indexLabel.Parent             = topBar

-- Settings Button
local settingsBtn = Instance.new("ImageButton")
settingsBtn.Size             = UDim2.fromOffset(26, 26)
settingsBtn.Position         = UDim2.new(1, -61, 0.5, -13)
settingsBtn.BackgroundColor3 = COL_BTN_NAV
settingsBtn.BorderSizePixel  = 0
settingsBtn.Image            = "" -- сюда ебну потом картинку
settingsBtn.ZIndex           = 5
settingsBtn.Parent           = topBar
makeCorner(settingsBtn, 5)

-- D
local settingsIcon = Instance.new("TextLabel")
settingsIcon.Size                = UDim2.fromScale(1, 1)
settingsIcon.BackgroundTransparency = 1
settingsIcon.Text                = "⚙"
settingsIcon.TextColor3          = COL_WHITE
settingsIcon.Font                = Enum.Font.SourceSansBold
settingsIcon.TextSize            = 15
settingsIcon.ZIndex              = 6
settingsIcon.Parent              = settingsBtn

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size             = UDim2.fromOffset(26, 26)
minimizeBtn.Position         = UDim2.new(1, -29, 0.5, -13)
minimizeBtn.Text             = "▼"
minimizeBtn.BackgroundColor3 = COL_BTN_NAV
minimizeBtn.TextColor3       = COL_WHITE
minimizeBtn.Font             = Enum.Font.SourceSansBold
minimizeBtn.TextSize         = 13
minimizeBtn.BorderSizePixel  = 0
minimizeBtn.ZIndex           = 5
minimizeBtn.Parent           = topBar
makeCorner(minimizeBtn, 5)

-- SCROLLING frame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size                 = UDim2.new(1, 0, 0, LIST_H)
scrollFrame.Position             = UDim2.fromOffset(0, TOPBAR_H)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel      = 0
scrollFrame.ScrollBarThickness   = 5
scrollFrame.ScrollBarImageColor3 = COL_BORDER
scrollFrame.CanvasSize           = UDim2.fromOffset(0, 0)
scrollFrame.AutomaticCanvasSize  = Enum.AutomaticSize.Y
scrollFrame.ElasticBehavior      = Enum.ElasticBehavior.Never
scrollFrame.ZIndex               = 2
scrollFrame.Parent               = frame

local listPad = Instance.new("UIPadding")
listPad.PaddingTop    = UDim.new(0, 5)
listPad.PaddingBottom = UDim.new(0, 5)
listPad.PaddingLeft   = UDim.new(0, 5)
listPad.PaddingRight  = UDim.new(0, 12)
listPad.Parent        = scrollFrame

local layout = Instance.new("UIListLayout")
layout.Parent        = scrollFrame
layout.Padding       = UDim.new(0, BTN_PAD)
layout.SortOrder     = Enum.SortOrder.LayoutOrder
layout.FillDirection = Enum.FillDirection.Vertical

-- BottomBar
local bottomBar = Instance.new("Frame")
bottomBar.Size             = UDim2.new(1, 0, 0, BOTTOM_H)
bottomBar.Position         = UDim2.fromOffset(0, TOPBAR_H + LIST_H)
bottomBar.BackgroundColor3 = COL_BAR
bottomBar.BorderSizePixel  = 0
bottomBar.ZIndex           = 3
bottomBar.Parent           = frame

do
	local d = Instance.new("Frame")
	d.Size             = UDim2.new(1, 0, 0, 1)
	d.BackgroundColor3 = COL_BORDER
	d.BorderSizePixel  = 0
	d.ZIndex           = 3
	d.Parent           = bottomBar
end

local BW = math.floor((FRAME_W - 18) / 2)
-- addBtn gets narrower to fit two small icons (22px each + 4 gap each)
local IO_BTN_W = 22
local addBtn  = makeTextBtn(bottomBar, "+ Checkpoint", COL_BTN_ADD, 6, 6, FRAME_W - 12 - (IO_BTN_W + 4), 26)
local exportBtn = makeTextBtn(bottomBar, "↑", Color3.fromRGB(100, 80, 160),
	FRAME_W - 12 - (IO_BTN_W + 4) + 6 + 4, 6, IO_BTN_W, 26, 16)
local prevBtn = makeTextBtn(bottomBar, "◀ Prev",          COL_BTN_NAV, 6, 36, BW,         24)
local nextBtn = makeTextBtn(bottomBar, "Next ▶",          COL_BTN_NAV, 6+BW+6, 36, BW,    24)

--  Draggable
do
	local dragging  = false
	local dragStart = Vector3.new()
	local startPos  = UDim2.fromOffset(0, 0)

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end

		-- ignore drag if button is touched
		local mp = input.Position
		local sp = settingsBtn.AbsolutePosition
		local ss = settingsBtn.AbsoluteSize
		if mp.X >= sp.X and mp.X <= sp.X + ss.X
			and mp.Y >= sp.Y and mp.Y <= sp.Y + ss.Y then return end
		local mp2 = minimizeBtn.AbsolutePosition
		local ms2 = minimizeBtn.AbsoluteSize
		if mp.X >= mp2.X and mp.X <= mp2.X + ms2.X
			and mp.Y >= mp2.Y and mp.Y <= mp2.Y + ms2.Y then return end

		dragging  = true
		dragStart = input.Position
		startPos  = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position - dragStart
		local vp    = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
			or Vector2.new(1280, 720)
		local newX  = math.clamp(startPos.X.Offset + delta.X, 0, vp.X - FRAME_W)
		local newY  = math.clamp(startPos.Y.Offset + delta.Y, 0, vp.Y - (minimized and TOPBAR_H or FRAME_H))
		frame.Position = UDim2.fromOffset(newX, newY)
	end)
end

-- Minimize / Expand
local function setMinimized(state)
	minimized = state
	if minimized then
		scrollFrame.Visible = false
		bottomBar.Visible   = false
		frame.Size          = UDim2.fromOffset(FRAME_W, TOPBAR_H)
		minimizeBtn.Text    = "▲"
		-- сlosing keybind panel
		if panelOpen then
			panelOpen = false
			keybindPanel.Visible = false
		end
	else
		scrollFrame.Visible = true
		bottomBar.Visible   = true
		frame.Size          = UDim2.fromOffset(FRAME_W, FRAME_H)
		minimizeBtn.Text    = "▼"
	end
end

minimizeBtn.MouseButton1Click:Connect(function()
	setMinimized(not minimized)
end)

local PANEL_W   = 240
local PANEL_ROW = 40   -- 1 line row (16 label + 22 btn + 2 gap)
local PANEL_H   = 34 + #binds * PANEL_ROW + 8

keybindPanel = Instance.new("Frame")
keybindPanel.Size             = UDim2.fromOffset(PANEL_W, PANEL_H)
keybindPanel.BackgroundColor3 = COL_PANEL
keybindPanel.BorderSizePixel  = 2
keybindPanel.BorderColor3     = COL_BORDER
keybindPanel.Visible          = false
keybindPanel.ZIndex           = 20
keybindPanel.Parent           = gui
makeCorner(keybindPanel, 6)

do
	local pt = Instance.new("TextLabel")
	pt.Size               = UDim2.new(1, -12, 0, 28)
	pt.Position           = UDim2.fromOffset(10, 4)
	pt.BackgroundTransparency = 1
	pt.Text               = "🛠️ Rebinding menu"
	pt.TextColor3         = COL_WHITE
	pt.Font               = Enum.Font.SourceSansBold
	pt.TextSize           = 14
	pt.TextXAlignment     = Enum.TextXAlignment.Left
	pt.ZIndex             = 21
	pt.Parent             = keybindPanel

end

-- Bind Buttons
local bindKeyBtns = {}   -- id

for i, bind in ipairs(binds) do
	local rowY = 32 + (i - 1) * PANEL_ROW

	local lbl = Instance.new("TextLabel")
	lbl.Size               = UDim2.fromOffset(PANEL_W - 20, 15)
	lbl.Position           = UDim2.fromOffset(10, rowY)
	lbl.BackgroundTransparency = 1
	lbl.Text               = bind.label
	lbl.TextColor3         = Color3.fromRGB(196, 197, 180)
	lbl.Font               = Enum.Font.SourceSans
	lbl.TextSize           = 12
	lbl.TextXAlignment     = Enum.TextXAlignment.Left
	lbl.ZIndex             = 21
	lbl.Parent             = keybindPanel

	local kb = Instance.new("TextButton")
	kb.Size             = UDim2.fromOffset(PANEL_W - 20, 22)
	kb.Position         = UDim2.fromOffset(10, rowY + 16)
	kb.Text             = bind.key.Name
	kb.BackgroundColor3 = COL_BTN_NAV
	kb.TextColor3       = COL_WHITE
	kb.Font             = Enum.Font.SourceSansBold
	kb.TextSize         = 13
	kb.BorderSizePixel  = 0
	kb.ZIndex           = 22
	kb.Parent           = keybindPanel
	makeCorner(kb, 4)
	bindKeyBtns[bind.id] = kb

	local cid = bind.id
	kb.MouseButton1Click:Connect(function()
		rebindingId = (rebindingId == cid) and nil or cid
		-- update
		for _, b in ipairs(binds) do
			local btn = bindKeyBtns[b.id]
			if btn then
				btn.Text             = (rebindingId == b.id) and "[ Press button ]" or b.key.Name
				btn.BackgroundColor3 = (rebindingId == b.id) and COL_BTN_WARN or COL_BTN_NAV
			end
		end
	end)
end

local function updatePanelPos()
	local fp = frame.Position
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
		or Vector2.new(1280, 720)
	local px = fp.X.Offset - PANEL_W - 6
	if px < 0 then px = fp.X.Offset + FRAME_W + 6 end
	local py = math.clamp(fp.Y.Offset + TOPBAR_H, 0, vp.Y - PANEL_H)
	keybindPanel.Position = UDim2.fromOffset(px, py)
end

settingsBtn.MouseButton1Click:Connect(function()
	panelOpen = not panelOpen
	if panelOpen then updatePanelPos() end
	keybindPanel.Visible = panelOpen
end)

-- panel (Import / Export)
local IO_PANEL_W = 300
local IO_PANEL_H = 310

ioPanel = Instance.new("Frame")
ioPanel.Size             = UDim2.fromOffset(IO_PANEL_W, IO_PANEL_H)
ioPanel.BackgroundColor3 = COL_PANEL
ioPanel.BorderSizePixel  = 2
ioPanel.BorderColor3     = COL_BORDER
ioPanel.Visible          = false
ioPanel.ZIndex           = 20
ioPanel.Parent           = gui
makeCorner(ioPanel, 6)

-- Title
local ioTitle = Instance.new("TextLabel")
ioTitle.Size               = UDim2.new(1, -44, 0, 28)
ioTitle.Position           = UDim2.fromOffset(10, 5)
ioTitle.BackgroundTransparency = 1
ioTitle.Text               = "📋 Import / Export"
ioTitle.TextColor3         = COL_WHITE
ioTitle.Font               = Enum.Font.SourceSansBold
ioTitle.TextSize           = 24
ioTitle.TextXAlignment     = Enum.TextXAlignment.Left
ioTitle.ZIndex             = 21
ioTitle.Parent             = ioPanel

-- Close button
local ioCloseBtn = makeTextBtn(ioPanel, "✕", COL_BTN_DEL,
	IO_PANEL_W - 32, 5, 26, 22, 13, 22)

-- Hint label
local ioHint = Instance.new("TextLabel")
ioHint.Size               = UDim2.new(1, -12, 0, 28)
ioHint.Position           = UDim2.fromOffset(6, 40)
ioHint.BackgroundTransparency = 1
ioHint.Text               = "Copy for export. For import paste and press button"
ioHint.TextColor3         = Color3.fromRGB(180, 175, 190)
ioHint.Font               = Enum.Font.SourceSans
ioHint.TextSize           = 10
ioHint.TextXAlignment     = Enum.TextXAlignment.Left
ioHint.TextWrapped        = true
ioHint.ZIndex             = 21
ioHint.Parent             = ioPanel

-- TextBox (multiline, scrollable)
local ioBox = Instance.new("TextBox")
ioBox.Size             = UDim2.fromOffset(IO_PANEL_W - 12, 200)
ioBox.Position         = UDim2.fromOffset(6, 64)
ioBox.BackgroundColor3 = Color3.fromRGB(28, 22, 36)
ioBox.TextColor3       = Color3.fromRGB(200, 230, 200)
ioBox.Font             = Enum.Font.Code
ioBox.TextSize         = 12
ioBox.TextXAlignment   = Enum.TextXAlignment.Left
ioBox.TextYAlignment   = Enum.TextYAlignment.Top
ioBox.MultiLine        = true
ioBox.ClearTextOnFocus = false
ioBox.Text             = ""
ioBox.BorderSizePixel  = 1
ioBox.BorderColor3     = COL_BORDER
ioBox.ZIndex           = 22
ioBox.Parent           = ioPanel
makeCorner(ioBox, 4)
do
	local p = Instance.new("UIPadding")
	p.PaddingLeft   = UDim.new(0, 6)
	p.PaddingTop    = UDim.new(0, 4)
	p.Parent        = ioBox
end

-- Export / Import buttons
local ioBtnW = math.floor((IO_PANEL_W - 18) / 2)

local exportActionBtn = makeTextBtn(ioPanel, "↑ Export", Color3.fromRGB(100, 80, 160),
	6, 272, ioBtnW, 28, 13, 22)
local importActionBtn = makeTextBtn(ioPanel, "↓ Import", Color3.fromRGB(50, 120, 180),
	6 + ioBtnW + 6, 272, ioBtnW, 28, 13, 22)

-- Serialisation format is one checkpoint per line
local SEP = "|"

local function serializeCheckpoints()
	local lines = {}
	for i, pos in ipairs(checkpoints) do
		local name = cpNames[i] or ("Checkpoint " .. i)
		-- names required to include SEP, changing to space
		name = name:gsub(SEP, " ")
		table.insert(lines, string.format("CP%s%s%s%.4f%s%.4f%s%.4f",
			SEP, name, SEP, pos.X, SEP, pos.Y, SEP, pos.Z))
	end
	return table.concat(lines, "\n")
end

local function deserializeCheckpoints(raw)
	local newCPs   = {}
	local newNames = {}
	local errors   = 0
	for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
		line = line:match("^%s*(.-)%s*$")  -- trim
		if line == "" then continue end
		-- format is CP|name|x|y|z
		local tag, name, sx, sy, sz = line:match("^(CP)" .. SEP .. "(.+)" .. SEP .. "(%-?[%d%.]+)" .. SEP .. "(%-?[%d%.]+)" .. SEP .. "(%-?[%d%.]+)$")
		if tag == "CP" then
			local x, y, z = tonumber(sx), tonumber(sy), tonumber(sz)
			if x and y and z then
				table.insert(newCPs, Vector3.new(x, y, z))
				table.insert(newNames, name)
			else
				errors = errors + 1
			end
		else
			errors = errors + 1
		end
	end
	return newCPs, newNames, errors
end

-- Status label (Export result)
local ioStatus = Instance.new("TextLabel")
ioStatus.Size               = UDim2.new(1, -12, 0, 18)
ioStatus.Position           = UDim2.fromOffset(6, 30)
ioStatus.BackgroundTransparency = 1
ioStatus.Text               = ""
ioStatus.TextColor3         = Color3.fromRGB(140, 220, 140)
ioStatus.Font               = Enum.Font.SourceSans
ioStatus.TextSize           = 14
ioStatus.TextXAlignment     = Enum.TextXAlignment.Left
ioStatus.ZIndex             = 23
ioStatus.Visible            = false
ioStatus.Parent             = ioPanel

local statusClearTask = nil
local function showStatus(msg, ok)
	ioStatus.Text      = msg
	ioStatus.TextColor3 = ok and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(230, 100, 100)
	ioStatus.Visible   = true
	if statusClearTask then task.cancel(statusClearTask) end
	statusClearTask = task.delay(3, function()
		ioStatus.Visible = false
	end)
end

exportActionBtn.MouseButton1Click:Connect(function()
	if #checkpoints == 0 then
		showStatus("⚠ No Checkpoints!", false)
		return
	end
	ioBox.Text = serializeCheckpoints()
	showStatus("✓ Exported " .. #checkpoints .. " checkpoints. Copy text", true)
	task.defer(function() ioBox:CaptureFocus() end)
end)

importActionBtn.MouseButton1Click:Connect(function()
	local raw = ioBox.Text
	if raw:match("^%s*$") then
		showStatus("⚠ Text field is empty!", false)
		return
	end
	local newCPs, newNames, errs = deserializeCheckpoints(raw)
	if #newCPs == 0 then
		showStatus("✗ Checkpoint detection failed.", false)
		return
	end
	checkpoints   = newCPs
	cpNames       = newNames
	currentIndex  = math.min(currentIndex, #checkpoints)
	if currentIndex == 0 and #checkpoints > 0 then currentIndex = 1 end
	renamingIndex = nil
	local msg = "✓ Loaded: " .. #newCPs .. " checkpoints"
	if errs > 0 then msg = msg .. " (" .. errs .. " lines missed)" end
	showStatus(msg, true)
	refreshUI()
end)

ioCloseBtn.MouseButton1Click:Connect(function()
	ioPanelOpen = false
	ioPanel.Visible = false
end)

local function updateIOPanelPos()
	local fp = frame.Position
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
		or Vector2.new(1280, 720)
	local px = fp.X.Offset - IO_PANEL_W - 6
	if px < 0 then px = fp.X.Offset + FRAME_W + 6 end
	local py = math.clamp(fp.Y.Offset, 0, vp.Y - IO_PANEL_H)
	ioPanel.Position = UDim2.fromOffset(px, py)
end

exportBtn.MouseButton1Click:Connect(function()
	ioPanelOpen = not ioPanelOpen
	if ioPanelOpen then
		updateIOPanelPos()
		-- sudently exporting
		if #checkpoints > 0 then
		end
	end
	ioPanel.Visible = ioPanelOpen
end)

--  refresh
local refreshUI

refreshUI = function()
	-- delete all strings
	for _, v in ipairs(scrollFrame:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end

	indexLabel.Text = currentIndex .. " / " .. #checkpoints

	for i = 1, #checkpoints do
		local isActive   = (i == currentIndex)
		local isRenaming = (i == renamingIndex)
		local cpPos      = checkpoints[i]
		local cpName     = cpNames[i] or ("Checkpoint " .. i)

		-- String-Container
		local row = Instance.new("Frame")
		row.Size             = UDim2.new(1, 0, 0, BTN_H)
		row.LayoutOrder      = i
		row.BackgroundTransparency = 1
		row.ZIndex           = 2
		row.Parent           = scrollFrame

		-- Delete Button
		local delBtn = Instance.new("TextButton")
		delBtn.Size             = UDim2.fromOffset(SIDE_W, BTN_H - 4)
		delBtn.Position         = UDim2.new(1, -SIDE_W, 0.5, -(BTN_H-4)/2)
		delBtn.Text             = "X"
		delBtn.BackgroundColor3 = COL_BTN_DEL
		delBtn.TextColor3       = COL_WHITE
		delBtn.Font             = Enum.Font.SourceSansBold
		delBtn.TextSize         = 13
		delBtn.BorderSizePixel  = 0
		delBtn.ZIndex           = 4
		delBtn.Parent           = row
		makeCorner(delBtn, 4)

		-- Rename Button
		local renBtn = Instance.new("TextButton")
		renBtn.Size             = UDim2.fromOffset(SIDE_W, BTN_H - 4)
		renBtn.Position         = UDim2.new(1, -(SIDE_W*2 + 3), 0.5, -(BTN_H-4)/2)
		renBtn.Text             = "R"
		renBtn.BackgroundColor3 = isRenaming and COL_BTN_WARN or COL_BTN_REN
		renBtn.TextColor3       = COL_WHITE
		renBtn.Font             = Enum.Font.SourceSansBold
		renBtn.TextSize         = 13
		renBtn.BorderSizePixel  = 0
		renBtn.ZIndex           = 4
		renBtn.Parent           = row
		makeCorner(renBtn, 4)

		-- main element width
		local nameW = -(SIDE_W * 2 + 3 + 4)  -- бзыки от корнера

		if isRenaming then
			-- renaming textbox
			local tb = Instance.new("TextBox")
			tb.Size             = UDim2.new(1, nameW, 1, -4)
			tb.Position         = UDim2.fromOffset(0, 2)
			tb.Text             = cpName
			tb.BackgroundColor3 = Color3.fromRGB(50, 44, 58)
			tb.TextColor3       = COL_WHITE
			tb.Font             = Enum.Font.SourceSans
			tb.TextSize         = 13
			tb.BorderSizePixel  = 1
			tb.BorderColor3     = COL_BORDER
			tb.ClearTextOnFocus = false
			tb.ZIndex           = 4
			tb.Parent           = row
			makeCorner(tb, 4)

			local p = Instance.new("UIPadding")
			p.PaddingLeft = UDim.new(0, 6)
			p.Parent      = tb

			-- renaming func
			task.defer(function() tb:CaptureFocus() end)

			tb.FocusLost:Connect(function()
				local trimmed = tb.Text:match("^%s*(.-)%s*$")
				if trimmed ~= "" then cpNames[i] = trimmed end
				renamingIndex = nil
				refreshUI()
			end)
		else
			-- just button
			local nameBtn = Instance.new("TextButton")
			nameBtn.Size             = UDim2.new(1, nameW, 1, -4)
			nameBtn.Position         = UDim2.fromOffset(0, 2)
			nameBtn.Text             = cpName
			nameBtn.BackgroundColor3 = isActive and COL_BTN_ACTIVE or COL_BTN
			nameBtn.TextColor3       = COL_WHITE
			nameBtn.Font             = isActive and Enum.Font.SourceSansBold or Enum.Font.SourceSans
			nameBtn.TextSize         = 13
			nameBtn.BorderSizePixel  = 0
			nameBtn.TextXAlignment   = Enum.TextXAlignment.Left
			nameBtn.ZIndex           = 3
			nameBtn.Parent           = row
			makeCorner(nameBtn, 4)

			local p = Instance.new("UIPadding")
			p.PaddingLeft = UDim.new(0, 6)
			p.Parent      = nameBtn

			nameBtn.MouseButton1Click:Connect(function()
				local char = player.Character or player.CharacterAdded:Wait()
				local hrp  = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame   = CFrame.new(cpPos)
					currentIndex = i
					refreshUI()
				end
			end)
		end

		-- Callbacks
		local ci = i

		renBtn.MouseButton1Click:Connect(function()
			renamingIndex = (renamingIndex == ci) and nil or ci
			refreshUI()
		end)

		delBtn.MouseButton1Click:Connect(function()
			table.remove(checkpoints, ci)
			table.remove(cpNames, ci)
			-- correcting current index
			if currentIndex > #checkpoints then
				currentIndex = #checkpoints
			elseif currentIndex >= ci and currentIndex > 0 then
				currentIndex = currentIndex - 1
			end
			-- correcting renamingIndex
			if renamingIndex == ci then
				renamingIndex = nil
			elseif renamingIndex and renamingIndex > ci then
				renamingIndex = renamingIndex - 1
			end
			refreshUI()
		end)
	end

	-- Autoscroll in active string
	if currentIndex > 0 then
		local targetY = (currentIndex - 1) * (BTN_H + BTN_PAD) + 5
		scrollFrame.CanvasPosition = Vector2.new(0, math.max(0, targetY - LIST_H / 2))
	end

	-- sync panel position
	if panelOpen then updatePanelPos() end
end

-- Main Logic
local function teleportTo(index)
	if not checkpoints[index] then return end
	local hrp    = getHRP()
	hrp.CFrame   = CFrame.new(checkpoints[index])
	currentIndex = index
	refreshUI()
end

local function addCheckpoint()
	local hrp = getHRP()
	table.insert(checkpoints, hrp.Position)
	local name = "Checkpoint " .. #checkpoints
	table.insert(cpNames, name)
	currentIndex = #checkpoints
	refreshUI()
end

local function nextCheckpoint()
	if #checkpoints == 0 then return end
	teleportTo((currentIndex % #checkpoints) + 1)
end

local function prevCheckpoint()
	if #checkpoints == 0 then return end
	teleportTo(((currentIndex - 2) % #checkpoints) + 1)
end

-- BottomBar buttons (Mobile support XD)
addBtn.MouseButton1Click:Connect(addCheckpoint)
prevBtn.MouseButton1Click:Connect(prevCheckpoint)
nextBtn.MouseButton1Click:Connect(nextCheckpoint)

-- input handler
UserInputService.InputBegan:Connect(function(input, gp)

	-- Rebind mode (Checking)
	if rebindingId and input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode ~= Enum.KeyCode.Escape then
			for _, b in ipairs(binds) do
				if b.id == rebindingId then
					b.key = input.KeyCode
					break
				end
			end
		end
		rebindingId = nil
		-- updater
		for _, b in ipairs(binds) do
			local btn = bindKeyBtns[b.id]
			if btn then
				btn.Text             = b.key.Name
				btn.BackgroundColor3 = COL_BTN_NAV
			end
		end
		return
	end

	if gp then return end

	local key = input.KeyCode
	if     key == getBind("add")      then addCheckpoint()
	elseif key == getBind("teleport") then
		if #checkpoints > 0 then
			if currentIndex == 0 then currentIndex = 1 end
			teleportTo(currentIndex)
		end
	elseif key == getBind("next")     then nextCheckpoint()
	elseif key == getBind("prev")     then prevCheckpoint()
	end
end)

-- Refresher
refreshUI()