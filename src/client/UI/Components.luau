--!strict
-- UI factory module: buttons, panels, toasts, and reusable tween presets, all built from
-- UITheme's locked tokens. Scale-based sizing only (UDim2 scale + UIListLayout/UIGridLayout;
-- no fixed pixel positions) - the one exception is a UISizeConstraint floor on buttons, which
-- guarantees the >=44px touch target without hardcoding an actual layout size.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)

local PRESS_TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SLIDE_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local Components = {}

-- ===== Tween presets =====

local Tweens = {}

-- Press-bounce feedback via a UIScale so it never fights whatever layout/AnchorPoint the
-- caller chose for the button itself.
local function bindPressFeedback(button: GuiButton)
	local scale = Instance.new("UIScale")
	scale.Parent = button

	local function animate(target: number, tweenInfo: TweenInfo)
		TweenService:Create(scale, tweenInfo, { Scale = target }):Play()
	end

	button.MouseButton1Down:Connect(function()
		animate(0.94, PRESS_TWEEN_INFO)
	end)
	local function release()
		animate(1, RELEASE_TWEEN_INFO)
	end
	button.MouseButton1Up:Connect(release)
	button.MouseLeave:Connect(release)
end

-- Springy scale-in, e.g. for a panel just opened.
function Tweens.Pop(instance: GuiObject)
	local scale = instance:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = instance
	scale.Scale = 0.7
	TweenService:Create(scale, POP_TWEEN_INFO, { Scale = 1 }):Play()
end

-- Slides an instance in from `fromPosition` to whatever Position it already has.
function Tweens.SlideIn(instance: GuiObject, fromPosition: UDim2)
	local target = instance.Position
	instance.Position = fromPosition
	TweenService:Create(instance, SLIDE_TWEEN_INFO, { Position = target }):Play()
end

-- Weak-keyed so an in-flight count-up on a destroyed label can't leak, and a newer call on
-- the same label cancels whatever count-up was already running there.
local countUpTokens: { [TextLabel]: number } = setmetatable({}, { __mode = "k" }) :: any

function Tweens.CountUp(label: TextLabel, fromValue: number, toValue: number, duration: number?)
	local dur = duration or 0.5
	local token = (countUpTokens[label] or 0) + 1
	countUpTokens[label] = token

	if dur <= 0 then
		label.Text = tostring(toValue)
		return
	end

	local startTime = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function()
		if countUpTokens[label] ~= token then
			connection:Disconnect()
			return
		end
		local alpha = math.clamp((os.clock() - startTime) / dur, 0, 1)
		label.Text = tostring(math.floor(fromValue + (toValue - fromValue) * alpha + 0.5))
		if alpha >= 1 then
			connection:Disconnect()
		end
	end)
end

Components.Tweens = Tweens

-- ===== MakeButton =====

export type ButtonProps = {
	Name: string?,
	Text: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Color: Color3?,
	TextColor: Color3?,
	LayoutOrder: number?,
	OnActivated: (() -> ())?,
}

function Components.MakeButton(props: ButtonProps): TextButton
	local button = Instance.new("TextButton")
	button.Name = props.Name or "Button"
	button.Size = props.Size or UDim2.fromScale(0.3, 0.08)
	button.Position = props.Position or UDim2.fromScale(0, 0)
	button.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	button.LayoutOrder = props.LayoutOrder or 0
	button.BackgroundColor3 = props.Color or UITheme.Colors.Primary
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Text = props.Text or ""
	button.TextColor3 = props.TextColor or UITheme.Colors.White
	button.Font = UITheme.Font
	button.TextScaled = true

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UITheme.CornerRadius
	corner.Parent = button

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(UITheme.MinTouchSize, UITheme.MinTouchSize)
	sizeConstraint.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.08, 0)
	padding.PaddingRight = UDim.new(0.08, 0)
	padding.PaddingTop = UDim.new(0.1, 0)
	padding.PaddingBottom = UDim.new(0.1, 0)
	padding.Parent = button

	bindPressFeedback(button)

	if props.OnActivated ~= nil then
		button.Activated:Connect(props.OnActivated)
	end

	return button
end

-- ===== MakePanel =====

export type PanelProps = {
	Name: string?,
	Title: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	ShowClose: boolean?, -- default true
	OnClose: (() -> ())?,
}

export type Panel = {
	Frame: Frame,
	Content: Frame,
	Close: () -> (),
}

function Components.MakePanel(props: PanelProps): Panel
	local frame = Instance.new("Frame")
	frame.Name = props.Name or "Panel"
	frame.Size = props.Size or UDim2.fromScale(0.88, 0.78)
	frame.Position = props.Position or UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = UITheme.Colors.Surface
	frame.BorderSizePixel = 0
	frame.ZIndex = 5
	frame.Visible = false

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UITheme.CornerRadius
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = UITheme.Colors.Primary
	stroke.Thickness = 3
	stroke.Parent = frame

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.fromScale(1, 0.12)
	titleBar.BackgroundTransparency = 1
	titleBar.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.fromScale(0.8, 1)
	titleLabel.Position = UDim2.fromScale(0.04, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = props.Title or ""
	titleLabel.Font = UITheme.Font
	titleLabel.TextColor3 = UITheme.Colors.Ink
	titleLabel.TextScaled = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.fromScale(1, 0.88)
	content.Position = UDim2.fromScale(0, 0.12)
	content.BackgroundTransparency = 1
	content.Parent = frame

	local function close()
		frame.Visible = false
		if props.OnClose ~= nil then
			props.OnClose()
		end
	end

	if props.ShowClose ~= false then
		local closeButton = Components.MakeButton({
			Name = "Close",
			Text = "X",
			Size = UDim2.fromScale(0.14, 0.8),
			Position = UDim2.fromScale(0.99, 0.5),
			AnchorPoint = Vector2.new(1, 0.5),
			Color = UITheme.Colors.Primary,
			OnActivated = close,
		})
		closeButton.Parent = titleBar
	end

	return { Frame = frame, Content = content, Close = close }
end

-- ===== MakeToast =====

export type ToastProps = {
	Text: string,
	Color: Color3?,
}

function Components.MakeToast(props: ToastProps): Frame
	local toast = Instance.new("Frame")
	toast.Name = "Toast"
	toast.Size = UDim2.fromScale(0.7, 0.07)
	toast.BackgroundColor3 = props.Color or UITheme.Colors.Primary
	toast.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UITheme.CornerRadius
	corner.Parent = toast

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.04, 0)
	padding.PaddingRight = UDim.new(0.04, 0)
	padding.Parent = toast

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = props.Text
	label.Font = UITheme.Font
	label.TextColor3 = UITheme.Colors.White
	label.TextScaled = true
	label.Parent = toast

	return toast
end

return Components
