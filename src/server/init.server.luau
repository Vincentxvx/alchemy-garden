--!strict
-- Bootstraps all Services, in dependency order.

local Services = script.Services

local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)

DataService.Init()
PlotService.Init()

print("[Alchemy Garden] Server boot complete - Data, Plot")
