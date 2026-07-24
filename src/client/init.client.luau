--!strict
-- Bootstraps all Controllers.

local Controllers = script.Controllers
local UI = script.UI

local GardenController = require(Controllers.GardenController)
local UIController = require(Controllers.UIController)
local HUD = require(UI.HUD)
local Shop = require(UI.Shop)
local Inventory = require(UI.Inventory)

GardenController.Init()
UIController.Init()
HUD.Init()
Shop.Init()
Inventory.Init()

print("[Alchemy Garden] Client boot complete - Garden, UI")
