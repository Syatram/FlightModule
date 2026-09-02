--!strict
export type FlightModuleType = {
	New : (Player, Camera) -> FlightModuleType,
	Toggle : (FlightModuleType) -> nil,
	Destroy : (FlightModuleType) -> nil,
	
	Player : Player,
	Humanoid : Humanoid?,
	HumanoidRootPart : BasePart?,
	Camera : Camera,
	RenderSteppedConnection : RBXScriptConnection?,
	CharacterAddedConnection : RBXScriptConnection?,
	Enabled : boolean,
}

local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local Players = game:GetService("Players")

local FlightModule = {}
FlightModule.__index = FlightModule

local GRAVITY = workspace.Gravity

-- Table of inputs and what direction they move in
FlightModule.INPUT_DIRECTION_TABLE = {
	[Enum.KeyCode.W] = Vector3.new(1 , 0, 0),
	[Enum.KeyCode.S] = Vector3.new(-1, 0, 0),
	[Enum.KeyCode.A] = Vector3.new(0, 0, -1),
	[Enum.KeyCode.D] = Vector3.new(0, 0, 1),
	[Enum.KeyCode.Space] = Vector3.new(0, 1, 0),
	[Enum.KeyCode.Q] = Vector3.new(0, -1, 0),
}

-- Table of speed multipliers of different speeds
FlightModule.SPEED_MULT_TABLE = {
	[Enum.KeyCode.LeftShift] = 3,
	[Enum.KeyCode.E] = 0.5,
}

FlightModule.BASE_SPEED = 77

function FlightModule.New(Player : Player, Camera : Camera)
	local self = setmetatable({}, FlightModule) :: FlightModuleType
	
	self.Player = Player
	self.Camera = Camera
	self.Enabled = false
	
	self.CharacterAddedConnection = self.Player.CharacterAdded:Connect(function(Character)
		local Humanoid = Character:WaitForChild('Humanoid')
		local HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')

		assert(Humanoid:IsA("Humanoid"), "Instance is not a Humanoid")
		assert(HumanoidRootPart:IsA("Part"), "Instance is not a Part")

		self.Humanoid = Humanoid
		self.HumanoidRootPart = HumanoidRootPart
		
		if self.Enabled then
			Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end
	end)
	
	return self 
end

function FlightModule.CalculateWorldMoveDirection()
	local MD_W = Vector3.zero

	for k, d in FlightModule.INPUT_DIRECTION_TABLE do
		MD_W += UserInputService:IsKeyDown(k) and d or Vector3.zero
	end

	return MD_W
end

function FlightModule.CalculateSpeed() : number
	for k, s in FlightModule.SPEED_MULT_TABLE do
		if UserInputService:IsKeyDown(k) then
			return s * FlightModule.BASE_SPEED
		end
	end

	return FlightModule.BASE_SPEED
end

function FlightModule.Disable(FM : FlightModuleType)
	if FM.Humanoid then
		FM.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	
	FM.RenderSteppedConnection:Disconnect()
	FM.RenderSteppedConnection = nil
	
	workspace.Gravity = GRAVITY
	FM.Enabled = false
end

function FlightModule.Enable(FM : FlightModuleType)
	if FM.RenderSteppedConnection ~= nil then
		error("Flight module already enabled")
		return
	end
	
	if FM.Humanoid then
		FM.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end
	
	FM.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		-- These get checked later on but the linter doesn't understand
		-- So, I cast them here to make the linter fuck off
		local Humanoid = FM.Humanoid :: Humanoid
		local HumanoidRootPart = FM.HumanoidRootPart :: Part
		
		-- Do nothing if Humanoid and HumanoidRootPart aren't found
		if (Humanoid == nil or HumanoidRootPart == nil) and FM.RenderSteppedConnection ~= nil then
			print(Humanoid == nil or HumanoidRootPart == nil)
			return
		end
		
		local C = FM.Camera.CFrame
		-- Lock character rotation with camera's 
		HumanoidRootPart.CFrame = CFrame.lookAlong(HumanoidRootPart.Position, C.LookVector)

		local MD_W = FlightModule.CalculateWorldMoveDirection()

		local L = C.LookVector
		local R = C.RightVector

		local MD_R = MD_W.X * L + MD_W.Y * Vector3.new(0, 1, 0) + MD_W.Z * R

		MD_R = Vector3.new(
			math.clamp(MD_R.X, -1, 1),
			math.clamp(MD_R.Y, -1, 1),
			math.clamp(MD_R.Z, -1, 1)
		)

		HumanoidRootPart.AssemblyLinearVelocity = MD_R * FlightModule.CalculateSpeed()
		HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
	end)
	
	workspace.Gravity = 0
	FM.Enabled = true
end

function FlightModule.Toggle(self : FlightModuleType)
	if self.Enabled then
		FlightModule.Disable(self)
		return
	end
	
	FlightModule.Enable(self)
end

function FlightModule.Destroy(self : FlightModuleType)
	FlightModule.Disable(self)
	self.CharacterAddedConnection:Disconnect()
end

return FlightModule
