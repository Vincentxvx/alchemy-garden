--!strict
-- Bootstraps all Services, in dependency order.

local Services = script.Services

local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)
local GardenService = require(Services.GardenService)

DataService.Init()
PlotService.Init()
GardenService.Init()

print("[Alchemy Garden] Server boot complete - Data, Plot, Garden")
