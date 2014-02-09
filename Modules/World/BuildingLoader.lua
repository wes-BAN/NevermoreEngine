local ReplicatedStorage       = game:GetService("ReplicatedStorage")

local NevermoreEngine         = require(ReplicatedStorage:WaitForChild("NevermoreEngine"))
local LoadCustomLibrary       = NevermoreEngine.LoadLibrary

local qSystems                = LoadCustomLibrary("qSystems")
local qInstance               = LoadCustomLibrary("qInstance")
local qCFrame                 = LoadCustomLibrary("qCFrame")
local OverriddenConfiguration = LoadCustomLibrary("OverriddenConfiguration")

qSystems:Import(getfenv(0));

-- BuidingLoader.lua
-- Handles building loading and management. Handles it server-side. 

local lib = {}

local MakeGridManager = Class(function(GridManager, Center, StudsPerGridSquare, Rows, Columns)
	local Grid = {}

	-- Generate grid.
	for Row = 1, Rows do
		Grid[Row] = {}
	end

	local function GetOpenSlotPosition()
		--- Return's a Vector2 of the location that is open, if one is open
		--  Otherwise, return's nil

		for Row = 1, Rows do
			local RowData = Grid[Row]
			for Column = 1, Columns do
				if RowData[Column] == nil then
					return Vector2.new(Row, Column)
				end
			end
		end
		return nil
	end
	GridManager.GetOpenSlotPosition = GetOpenSlotPosition
	GridManager.getOpenSlotPosition = GetOpenSlotPosition

	local function GetListOfFilledSlots()
		--- Get's a list of all filled slots

		local List = {}

		for Row = 1, Rows do
			local RowData = Grid[Row]
			for Column = 1, Columns do
				if RowData[Column] ~= nil then
					List[#List+1] = RowData[Column]
				end
			end
		end

		return List
	end
	GridManager.GetListOfFilledSlots = GetListOfFilledSlots
	GridManager.getListOfFilledSlots = GetListOfFilledSlots

	local function GetListOfOpenSlots()
		-- Return's list of slots that are open

		local List = {}

		for Row = 1, Rows do
			local RowData = Grid[Row]
			for Column = 1, Columns do
				if RowData[Column] == nil then
					List[#List+1] = RowData[Column]
				end
			end
		end

		return List
	end
	GridManager.GetListOfOpenSlots = GetListOfOpenSlots
	GridManager.getListOfOpenSlots = GetListOfOpenSlots

	local function SlotInBounds(SlotLocation)
		local RowIndex = SlotLocation.X
		local ColumnIndex = SlotLocation.Y

		if RowIndex >= 1 and RowIndex <= Rows then
			if ColumnIndex >= 1 and ColumnIndex <= Columns then
				return true
			end
		end

		return false
	end
	GridManager.SlotInBounds = SlotInBounds
	GridManager.slotInBounds = SlotInBounds

	local function IsSlotOpen(SlotLocation)
		-- @param SlotLocation Vector2, the location of the slot.

		if SlotInBounds(SlotLocation) then
			return Grid[SlotLocation.X][SlotLocation.Y] ~= nil
		else
			return false
		end
	end
	GridManager.IsSlotOpen = IsSlotOpen
	GridManager.isSlotOpen = IsSlotOpen

	local function AddItemToSlot(SlotLocation, Item)
		--- Adds the item to the slot. 
		-- @param SlotLocation Vector2, the location of the slot.
		-- @param Item The item to add to it. Can be anything except nil.

		if IsSlotOpen(SlotLocation) then
			Grid[SlotLocation.X][SlotLocation.Y] = Item
			return true
		else
			error("[GridManager] - Slot is not open, cannot add to it")
			return false
		end
	end
	GridManager.AddItemToSlot = AddItemToSlot
	GridManager.addItemToSlot = AddItemToSlot

	local function RemoteItemFromSlot(SlotLocation)
		if SlotInBounds(SlotLocation) then
			if IsSlotOpen(SlotLocation) then
				local Removed = Grid[SlotLocation.X][SlotLocation.Y]
				if Removed then
					Grid[SlotLocation.X][SlotLocation.Y] = nil
					return Removed
				else
					error("[GridManager] - Slot did not have any content!")
				end
			end
		else
			error("[GridManager] - Slot is not in bounds. Obviously cannot remove from it.")
		end
	end
	GridManager.RemoteItemFromSlot = RemoteItemFromSlot
	GridManager.remoteItemFromSlot = RemoteItemFromSlot

	local function SlotLocationToWorldLocation(SlotLocation)
		local CenteredSlotLocation = (SlotLocation - (Vector2.new(Rows, Columns)/2))
		return (Center + Vector3.new(CenteredSlotLocation.X, 0, CenteredSlotLocation.Y))
	end
	GridManager.SlotLocationToWorldLocation = SlotLocationToWorldLocation
	GridManager.slotLocationToWorldLocation = SlotLocationToWorldLocation
end)

local MakeGateConnection = Class(function(GateConnection, BaseGate, DestinationID)
	--- Represents the connection between a gate and a Area
	-- @param BaseGate The gateway in, BasePart
	-- @param DestinationGateRender The rendering function to use if GateOut fails. ()

	GateConnection.BaseGate              = BaseGate
	GateConnection.DestinationID         = DestinationID
	GateConnection.DestinationGat        = nil
end)

local MakeAreaHandler = Class(function(AreaHandler, Configuration, BuildingList)
	local Configuration = OverriddenConfiguration.new(Configuration, {
		StudsPerGridSquare = 100;
		RenderHeight       = 10000;
		GridSize           = 20; -- 400 should be enough, no?
	})

	local Grid = MakeGridManager(Vector3.new(0, Configuration.RenderHeight, 0), Configuration.StudsPerGridSquare, Configuration.GridSize, Configuration.GridSize)
	local DestinationIDToRender = {}
	local Gateways = {}

	local function AddDestiation(DestinationID, DestinatinoRender)
		--- Adds a destination to the render handler. 
		-- @param DestinationID String, the ID of the destination available.
		-- @param DestinatinoRender Function that returns the model to use as the destination.

		DestinationID = DestinationID:lower()
		DestinationIDToRender[DestinationID] = DestinatinoRender
	end
	AreaHandler.AddDestiation = AddDestiation
	AreaHandler.addDestiation = AddDestiation

	local function SetupGateway(GatewayIn, DestinationID)
		-- @param GatewayIn The gateway model going in
		-- @param DestinationID The destination ID (already registered) to where this gateway goes. Will probably be generated based on parent-child structure.

		DestinationID = DestinationID:lower()

		if DestinationIDToRender[DestinationID] then

		else
			error("[AreaHandler] - Destination '" .. DestinationID .. "' does not exist")
		end
	end
	AreaHandler.SetupGateway = SetupGateway
	AreaHandler.setupGateway = SetupGateway



	local function LoadNewArea(Parent, Area)
		local NewLocation = GridManager.GetOpenSlotPosition()
		if NewLocation then
			local NewSpawnLocation = GridManager.SlotLocationToWorldLocation(NewLocation)

			local NewArea = {}
			NewArea.ActiveCharacterCount = 0
			NewArea.GridLocation         = NewLocation
			NewArea.WorldLocation        = NewSpawnLocation

			local NewModel = Make 'Model' {
				Parent     = Parent
				Name       = Area.Name .. "Cloned";
				Archivable = false;
				Area;
			}
			NewArea.Model = Model

			local CharacterBin = Make 'Model' { -- We'll presume it ONLY stores children
				Parent     = Parent
				Name       = "CharacterBin";
				Archivable = false;
			}
			NewArea.CharacterBin = CharacterBin

			local function UpdateCount()
				--- TODO: Integrate GC with this.
				
				local Children = CharacterBin:GetChildren()
				NewArea.ActiveCharacterCount = #Children
			end
			NewArea.UpdateCount = UpdateCount
			NewArea.updateCount = UpdateCount

			CharacterBin.ChildAdded:connect(function(Child)
				UpdateCount()
			end)		

			return NewArea
		else
			print("[AreaHandler] - Unable to find open slot. D:")
			return nil
		end
	end
	AreaHandler.LoadNewArea = LoadNewArea
	AreaHandler.loadNewArea = LoadNewArea


end)


return lib