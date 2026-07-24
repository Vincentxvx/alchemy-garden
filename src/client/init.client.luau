--!strict
-- Bootstraps all Controllers.

local Controllers = script.Controllers

local GardenController = require(Controllers.GardenController)

GardenController.Init()

print("[Alchemy Garden] Client boot complete - Garden")
