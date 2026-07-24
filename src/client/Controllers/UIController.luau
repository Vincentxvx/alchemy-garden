--!strict
-- Owns the single MainGui ScreenGui, caches the latest StateSync snapshot for every UI module
-- to read, and manages which one main panel (Shop/Inventory/Grimoire/Alchemy/...) is open at
-- a time. Screens register themselves; the bottom-right HUD stack calls Toggle by name.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local Components = require(script.Parent.Parent.UI.Components)

local localPlayer = Players.LocalPlayer

local UIController = {}

export type ScreenEntry = {
	Frame: Frame,
	OnOpen: (() -> ())?,
	OnClose: (() -> ())?,
}

local screenGui: ScreenGui? = nil
local screens: { [string]: ScreenEntry } = {}
local currentOpen: string? = nil

local latestData: Types.PlayerData? = nil
local dataChangedCallbacks: { (Types.PlayerData) -> () } = {}

function UIController.GetGui(): ScreenGui
	assert(screenGui ~= nil, "UIController.Init() must run before GetGui()")
	return screenGui :: ScreenGui
end

function UIController.GetData(): Types.PlayerData?
	return latestData
end

-- Fires immediately if a snapshot has already arrived, then again on every future StateSync.
function UIController.OnDataChanged(callback: (Types.PlayerData) -> ())
	table.insert(dataChangedCallbacks, callback)
	if latestData ~= nil then
		callback(latestData)
	end
end

function UIController.RegisterScreen(name: string, entry: ScreenEntry)
	screens[name] = entry
	entry.Frame.Visible = false
	entry.Frame.Parent = UIController.GetGui()
end

function UIController.Close(name: string)
	local screen = screens[name]
	if screen == nil then
		return
	end

	screen.Frame.Visible = false
	if currentOpen == name then
		currentOpen = nil
	end
	if screen.OnClose ~= nil then
		screen.OnClose()
	end
end

function UIController.Open(name: string)
	local screen = screens[name]
	if screen == nil then
		return
	end

	if currentOpen ~= nil and currentOpen ~= name then
		UIController.Close(currentOpen)
	end

	screen.Frame.Visible = true
	Components.Tweens.Pop(screen.Frame)
	currentOpen = name

	if screen.OnOpen ~= nil then
		screen.OnOpen()
	end
end

function UIController.Toggle(name: string)
	if currentOpen == name then
		UIController.Close(name)
	else
		UIController.Open(name)
	end
end

local function onStateSync(data: Types.PlayerData)
	latestData = data
	for _, callback in dataChangedCallbacks do
		callback(data)
	end
end

function UIController.Init()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "MainGui"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	screenGui = gui

	Remotes.StateSync.OnClientEvent:Connect(onStateSync)
end

return UIController
