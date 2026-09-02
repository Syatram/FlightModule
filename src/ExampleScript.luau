--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local FlightModule = require("./FlightModule")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

assert(Player ~= nil, "LocalPlayer is nil")
assert(Camera ~= nil, "Camera is nil")

local Flight = FlightModule.New(Player, Camera)

UserInputService.InputBegan:Connect(function(input : InputObject)
	if input.KeyCode == Enum.KeyCode.F then
		Flight:Toggle()
	end
end)

