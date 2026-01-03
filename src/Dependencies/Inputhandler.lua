local inputHandlerLib = {
	OnInputFunctions = {},
	Isloaded = false
}

local inputHandlerHolder = {}
inputHandlerHolder.__index = inputHandlerHolder

local function globalizeInputScope(inputObject)
	-- //Weird naming, but it shall work!
	return inputObject.KeyCode.Name ~= "Unknown" and inputObject.KeyCode or
		inputObject.UserInputType.Name ~= "None" and inputObject.UserInputType
end

function inputHandlerHolder:Disconnect()
	inputHandlerLib:RemoveFromGlobalArray(self.OnInputFunction)
end

function inputHandlerHolder:FindKeyCodeInKeyOrder(keyCode)
	return table.find(self._KeysInOrderPressed, keyCode)
end

function inputHandlerHolder:GetKeysCount()
	return #self._KeysInOrderPressed
end

function inputHandlerHolder:AreInputsPressedInOrder()
	local keyOrder = self._KeysInOrderPressed
	local keyRegistry = self._KeysRegistry

	local previousPressedTimestamp = 0

	for _, keyCode in keyOrder do
		local keyPressedTimeStamp = keyRegistry[keyCode]
		local isPressed = keyPressedTimeStamp > 0

		if not isPressed or (previousPressedTimestamp > keyPressedTimeStamp) then
			return false
		end

		previousPressedTimestamp = keyPressedTimeStamp
	end
	
	self.LastKeyPressed = true

	return true
end

function inputHandlerHolder:ProcessInput(inputObject, gameProcessedEvent)
	local keyCode = globalizeInputScope(inputObject)
	local isPressedDown = (inputObject.UserInputState == Enum.UserInputState.Begin)

	local keyOrderIndex = self:FindKeyCodeInKeyOrder(keyCode)

	if not keyOrderIndex then
		return
	end
	
	self._KeysRegistry[keyCode] = isPressedDown and os.clock() or -1

	if (self:GetKeysCount() == keyOrderIndex) then
		if (not isPressedDown) and self.LastKeyPressed then
			self.LastKeyPressed = false
	
			self.CallbackFunction(gameProcessedEvent, false)
			
			return
		end
	end

	if self:AreInputsPressedInOrder() then
		self.CallbackFunction(gameProcessedEvent, isPressedDown)
	end
end

function inputHandlerLib.New(keyCodes, callbackFunction)
	assert(typeof(keyCodes) == "table", `Table expected, got {typeof(keyCodes)}.`)
	assert(typeof(callbackFunction) == "function", `Function expected, got {typeof(callbackFunction)}.`)

	for _, keyCode in keyCodes do
		assert(typeof(keyCode) == "EnumItem", `EnumItem expected, got {typeof(keyCode)}.`)
	end

	local _inputHandlerHolder = {}
	setmetatable(_inputHandlerHolder, inputHandlerHolder)

	_inputHandlerHolder.CallbackFunction = callbackFunction
	_inputHandlerHolder._KeysInOrderPressed = keyCodes
	_inputHandlerHolder._KeysRegistry = table.create(#keyCodes, 0)

	_inputHandlerHolder.LastKeyPressed = false
	
	local function onInput(inputObject, gameProcessedEvent)
		_inputHandlerHolder:ProcessInput(inputObject, gameProcessedEvent)
	end
	
	_inputHandlerHolder.OnInputFunction = onInput
	inputHandlerLib:InsertFunctionToGlobalArray(_inputHandlerHolder.OnInputFunction)
	
	return _inputHandlerHolder
end

function inputHandlerLib:RemoveFromGlobalArray(func)
	local onInputFunctions = self.OnInputFunctions

	table.remove(onInputFunctions, table.find(onInputFunctions, func))
end

function inputHandlerLib:InsertFunctionToGlobalArray(func)
	table.insert(inputHandlerLib.OnInputFunctions, func)
end

function inputHandlerLib:InitialSetup()
	local UserInputService = game:GetService("UserInputService")
	
	local onInputFunctions = self.OnInputFunctions
	
	local function onInputBegan(...)
		for index = 1, #onInputFunctions do
			onInputFunctions[index](...)
		end
	end	
	local function onInputEnded(...)
		for index = 1, #onInputFunctions do
			onInputFunctions[index](...)
		end
	end	

	UserInputService["InputBegan"]:Connect(onInputBegan)
	UserInputService["InputEnded"]:Connect(onInputBegan)
	
	self.Isloaded = true
end

if not inputHandlerLib.Isloaded then
	inputHandlerLib:InitialSetup()
end

return inputHandlerLib