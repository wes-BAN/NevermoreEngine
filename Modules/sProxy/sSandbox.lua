-- A system by Seranok to sandbox methods in ROBLOX.
-- https://github.com/matthewdean/sandbox.lua/blob/master/examples/sandbox.lua

-- Modified by Quenty

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NevermoreEngine   = require(ReplicatedStorage:WaitForChild("NevermoreEngine"))
local LoadCustomLibrary = NevermoreEngine.LoadLibrary

local qSystems          = LoadCustomLibrary("qSystems")
local FilteredProxy     = LoadCustomLibrary("FilteredProxy")

qSystems:Import(getfenv(0))

local lib = {}

local function MakeExecuter(Source, Options)
	--- Executes code and creates an "executer" object.
	-- @param Source A String, the source of the code to execute.  
	-- @param Options A table filled with Options, in this case, organized like this:
	--[[
	Options = {
		metatable = {
			-- Your common metatable, here. Must be lowercase named. 
			-- Added to each "Child" of each ROBLOX item. 
			__index = function(self, Index)
				-- @param self The real object
				-- @param Index The indexed item

				print(Index)
			end;
			__newindex = ...
		};
		environment = {
			-- Standard environment, if empty will set no initial environments
			-- environments must be lower case.
			-- "print" will be overriden. 
		};
		chunk = "ChunkName";
		Filter = function(Value)
			if Type.isAnInstance(Value) and Value.Name == "Quenty" then -- Filter out anything named "Quenty"
				return true
			end
		end
	}
	--]]

	local Executer = {}
	Executer.TimeStamp = tick() 
	Executer.Output = CreateSignal() -- Fires (Output)
		-- @param Output A string
	Executer.Finished = CreateSignal() -- Fires (Success, Error)
		-- @param Boolean, true if it executed without error.
		-- @param Error The error if it happened. 

	Options = Options or {}

	-- local result = {}
	-- result.output = {}
	local function Execute()
		Spawn(function()
			local oldPrint = print
			local function print(...)
				oldPrint(...)
				local t = {...}
				for i = 1, select('#', ...) do
					t[i] = tostring(t[i])
				end

				Executer.Output:fire(table.concat(t, ' '))
			end
			
			local ExecuteFunction, err = loadstring(Source, Options.chunk or "chunk")
			if ExecuteFunction == nil then
				Executer.Finished:fire(false, err)
			else
				Options.environment = Options.environment or getfenv(0);--{_G,_VERSION,assert,collectgarbage,dofile,error,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,xpcall,coroutine,math,string,table,game,Game,workspace,Workspace,delay,Delay,LoadLibrary,printidentity,Spawn,tick,time,version,Version,Wait,wait,PluginManager,crash__,LoadRobloxLibrary,settings,Stats,stats,UserSettings,Enum,Color3,BrickColor,Vector2,Vector3,Vector3int16,CFrame,UDim,UDim2,Ray,Axes,Faces,Instance,Region3,Region3int16 = _G,_VERSION,assert,collectgarbage,dofile,error,getfenv,getmetatable,ipairs,load,loadfile,loadstring,next,pairs,pcall,print,rawequal,rawget,rawset,select,setfenv,setmetatable,tonumber,tostring,type,unpack,xpcall,coroutine,math,string,table,game,Game,workspace,Workspace,delay,Delay,LoadLibrary,printidentity,Spawn,tick,time,version,Version,Wait,wait,PluginManager,crash__,LoadRobloxLibrary,settings,Stats,stats,UserSettings,Enum,Color3,BrickColor,Vector2,Vector3,Vector3int16,CFrame,UDim,UDim2,Ray,Axes,Faces,Instance,Region3,Region3int16}
				Options.environment.print = print

				setfenv(ExecuteFunction, FilteredProxy.new(Options))
				
				local SuccessfulExecution, err = ypcall(ExecuteFunction)
				if not SuccessfulExecution then
					-- if err == "Game script timout" then
					-- 	wait() --FIXME hack
					-- end
					Executer.Finished:fire(false, err)
				else
					Executer.Finished:fire(true)
				end
			end
		end)
	end
	Executer.Execute = Execute
	Executer.execute = Execute

	return Executer
end
lib.MakeExecuter = MakeExecuter
lib.makeExecuter = MakeExecuter

return lib