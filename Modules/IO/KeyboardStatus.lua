local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local NevermoreEngine   = require(ReplicatedStorage:WaitForChild("NevermoreEngine"))
local LoadCustomLibrary = NevermoreEngine.LoadLibrary

local qSystems          = LoadCustomLibrary('qSystems')
local Table             = LoadCustomLibrary('Table')

local lib = {}

qSystems:import(getfenv(0));

-- KeyboardStatus.lua
-- @author Quenty
-- Last Modified February 3rd, 2014
-- TODO: Modify this to make it use Enums et cetera. 

local KeyChart = {
	-- Chart of all the keys, so we can do keys.A to get the byte code of it. Nice and efficient, coding wise... :D
	["a"]             = string.char(97);
	["b"]             = string.char(98);
	["c"]             = string.char(99);
	["d"]             = string.char(100);
	["e"]             = string.char(101);
	["f"]             = string.char(102);
	["g"]             = string.char(103);
	["h"]             = string.char(104);
	["i"]             = string.char(105);
	["j"]             = string.char(106);
	["k"]             = string.char(107);
	["l"]             = string.char(108);
	["m"]             = string.char(109);
	["n"]             = string.char(110);
	["o"]             = string.char(111);
	["p"]             = string.char(112);
	["q"]             = string.char(113);
	["r"]             = string.char(114);
	["s"]             = string.char(115);
	["t"]             = string.char(116);
	["u"]             = string.char(117);
	["v"]             = string.char(118);
	["w"]             = string.char(119);
	["x"]             = string.char(120);
	["y"]             = string.char(121);
	["z"]             = string.char(122);
	["arrowKeyUp"]    = string.char(17);
	["arrowKeyDown"]  = string.char(18);
	["arrowKeyRight"] = string.char(19);
	["arrowKeyLeft"]  = string.char(20);
	["home"]          = string.char(22);
	["end"]           = string.char(23);
	["f2"]            = string.char(27);
	["f4"]            = string.char(29);
	["f5"]            = string.char(30);
	["esc"]           = string.char(27);
	["tab"]           = string.char( 9);
	["enter"]         = string.char(13);
		["enterKey"]      = string.char(13);
	["space"]         = string.char(32);
		["spaceBar"]      = string.char(32);
	["ctrl"]          = string.char(50);
		["ctrlLeft"]      = string.char(50);
		["ctrlRight"]     = string.char(49);
	["alt"]           = string.char(52);
		["altLeft"]       = string.char(52);
		["altRight"]      = string.char(51);
	["windows"]       = string.char(54);
		["windowsLeft"]   = string.char(54);
		["windowsRight"]  = string.char(53);
	["backspace"]     = string.char(8);
	["shift"]         = string.char(48);
		["shiftRight"]    = string.char(47);
		["shiftLeft"]     = string.char(48);
	["esc"] = string.char(27);
	["`"] = string.char(96);
	["~"] = string.char(96);
	["1"]             = string.char(49);
	["2"]             = string.char(50);
	["3"]             = string.char(51);
	["4"]             = string.char(52);
	["5"]             = string.char(53);
	["6"]             = string.char(54);
	["7"]             = string.char(55);
	["8"]             = string.char(56);
	["9"]             = string.char(57);
	["0"]             = string.char(48);
	["mousebutton1"]  = "mousebutton1";
	["mousebutton2"]  = "mousebutton2";
}

lib.Keys = KeyChart
lib.KeyChart = KeyChart

-- This system ends up working a lot like regex javascript objects, I guess...
-- It tracks all down keys, and setups up statuses and stuff. 

--[[

Sample Usage:

	local KeyboardStatus = LoadCustomLibrary('KeyboardStatus')
	local Keys           = KeyboardStatus.KeyChart

	local Input = KeyboardStatus.MakeKeyboardStatus(LocalPlayer:GetMouse())

	if Input.GetKeyStatus(Keys.q) then
		TargetZoom = TargetZoom - 25;
	end
	if Input.GetKeyStatus(Keys.e) then
		TargetZoom = TargetZoom + 25;
	end
	
	------ OR -------

	local NightVisionToggle = Input.MakeCombinationsEvent(Input.KeyDown, Input.MultipleCombinationStatus, {
		{Keys.q;};
	})

	local NightVisionUp = Input.MakeCombinationsEvent(Input.KeyUp, Input.MultipleCombinationStatus, {
		{Keys.q;};
	})

	local FlashlightToggle = Input.MakeCombinationsEvent(Input.KeyDown, Input.MultipleCombinationStatus, {
		{Keys.f;};
	})

	local MenuOpen = Input.MakeCombinationsEvent(Input.KeyDown, Input.MultipleCombinationStatus, {
		{Keys.m;};
	})

	NightVisionToggle.Event:connect(function()
		if HasTag(LocalPlayer, "Playing") and not CutscenePlayer.CutscenePlaying then
			if not IsBeast.Value then
				if not VisionEnabled then
					VisionEnabled = true;
					Spawn(function()
						while VisionEnabled do
							if CheckCharacter(LocalPlayer) then
								LocalPlayer.Character.Humanoid:TakeDamage(1);
							end
							wait(0.5)
						end
					end)
					SetToLightingCurrent(0.25)
					NightVisionUp.Event:wait()
					VisionEnabled = false;
					SetToLightingCurrent(0.25)
				end
			end
		end
	end)

	-- You should also be able to connect directly

	FlashlightToggle:connect(function()
		Flashlight.Toggle(not Flashlight.Toggled)
	end)
--]]

local MakeKeyboardStatus = Class(function(KeyboardStatus, Mouse)
	-- Tracks keys and mouse input

	local KeysDown = {} -- Table of keys down.  Keys are direct, but lowercase. 

	local KeyDown  = Make 'BindableEvent' {
		Name       = "KeyDown";
		Archivable = false;
	}

	KeyboardStatus.KeyDown = KeyDown
	local KeyUp  = Make 'BindableEvent' {
		Name       = "KeyUp";
		Archivable = false;
	}
	KeyboardStatus.KeyUp = KeyUp

	local function GetKeyStatus(Key)
		return KeysDown[Key:lower()]
	end
	KeyboardStatus.GetKeyStatus = GetKeyStatus

	local function GetCombinationStatus(Combination)
		-- Returns the if all the keys in the combination list are down. 

		for _, Key in pairs(Combination) do
			if not GetKeyStatus(Key) then
				return false
			end
		end
		return true;
	end
	KeyboardStatus.GetCombinationStatus = GetCombinationStatus

	local function GetCombinationMatch(Combination)
		-- Returns true only if the keys down match the combination down. 
		-- So if the keydown, is say, including another key, it won't fire.

		local CombinationCopy = Table.Copy(Combination)

		for Index, Key in pairs(Combination) do
			CombinationCopy[Index] = nil
			if not GetKeyStatus(Key) then
				return false
			end
		end

		if Table.Count(CombinationCopy) == 0 then
			return true;
		else
			return false
		end
	end
	KeyboardStatus.GetCombinationMatch = GetCombinationMatch

	local function MultipleCombinationStatus(Combinations)
		-- In case more than one key combo exists, it'll go through each combination and return true or false.

		for _, Combination in pairs(Combinations) do
			if GetCombinationStatus(Combination) then
				return true
			end
		end
		return false
	end
	KeyboardStatus.MultipleCombinationStatus = MultipleCombinationStatus

	local function MultipleCombinationMatch(Combinations)
		-- In case more than one key combo exists, it'll go through each combination and return true or false, but if and only if those
		-- are enabled.

		for _, Combination in pairs(Combinations) do
			if GetCombinationMatch(Combination) then
				return true
			end
		end
		return false
	end
	KeyboardStatus.MultipleCombinationMatch = MultipleCombinationMatch

	local function MakeCombinationsEvent(BindableEvent, Checker, Combinations)
		--- Rather tricky to use, but basically, pick your event object, pick your checker function, and then pick your combinations... >:D
		-- @param BindableEvent An event included in the KeyboardStatus, either KeyDown or KeyUp, in which this event should be checked
		-- @param Checker This is the checker function, in this class. Probably use MultipleCombinationMatch, as the other one requires ONLY those
		--        keys down
		-- @param Combinations a table with ... more tables! In this case, each combination 
		-- @return Class, which can be used to connect

		local Class = {}
		local BindableEventLocal = Make 'BindableEvent' {
			Name       = "KeyDown";
			Archivable = false;
		}
		Class.Event        = BindableEventLocal.Event
		Class.Combinations = Combinations
		Class.connect      = function(self, ...)
			BindableEventLocal.Event:connect(...)
		end

		BindableEvent.Event:connect(function()
			if Checker(Combinations) then
				BindableEventLocal:Fire()
			end
		end)

		function Class:Fire()
			-- Manualy fires the event

			BindableEventLocal:Fire()
		end

		function Class:Destroy()
			-- Destroy's the class

			BindableEvent:Destroy()
			Class.Event        = nil
			Class.Fire         = nil
			Class.Destroy      = nil
			Class.Combinations = nil
			Class.connect      = nil
			Class              = nil
		end

		return Class
	end
	KeyboardStatus.MakeCombinationsEvent = MakeCombinationsEvent

	local Events = {}

	local function SetupMouse(Mouse)
		print("[KeyboardStatus] - Setting up mouse events")

		if Events then
			for _, Event in pairs(Events) do
				Event:disconnect()
			end
			Events = {}
		end

		Events[#Events+1] = Mouse.KeyDown:connect(function(Key)
			--print("[KeyboardStatus] - KeyDownEvent")
			KeysDown[Key:lower()] = true;
			KeyDown:Fire(KeysDown)
		end)

		Events[#Events+1] = Mouse.KeyUp:connect(function(Key)
			--print("[KeyboardStatus] - KeyUpEvent")
			KeyUp:Fire(KeysDown)
			KeysDown[Key:lower()] = nil;
		end)

		Events[#Events+1] = Mouse.Button1Down:connect(function(Key)
			KeysDown["mousebutton1"] = true;
			KeyDown:Fire(KeysDown)
		end)

		Events[#Events+1] = Mouse.Button1Up:connect(function(Key)
			KeyUp:Fire(KeysDown)
			KeysDown["mousebutton1"] = nil;
		end)

		Events[#Events+1] = Mouse.Button2Down:connect(function(Key)
			KeysDown["mousebutton2"] = true;
			KeyDown:Fire(KeysDown)
		end)

		Events[#Events+1] = Mouse.Button2Up:connect(function(Key)
			KeyUp:Fire(KeysDown)
			KeysDown["mousebutton2"] = nil;
			
		end)
	end

	while not CheckPlayer(Players.LocalPlayer) do
		wait(0)
		print("[KeyboardStatus] - Waiting for Players.LocalPlayer to validate")
	end

	SetupMouse(Mouse)

	--SetupMouse(Players.LocalPlayer:GetMouse())
	KeyboardStatus.SetupMouse = SetupMouse
	--[[Players.LocalPlayer.CharacterAdded:connect(function()
		print("[KeyboardStatus] - Character added")
		SetupMouse(Players.LocalPlayer:GetMouse())
	end)--]]
end)

lib.MakeKeyboardStatus = MakeKeyboardStatus
lib.makeKeyboardStatus = MakeKeyboardStatus

return lib