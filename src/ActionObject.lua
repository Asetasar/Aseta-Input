local actionObjectModule = {}

local actionObjectHolder = {}
actionObjectHolder.__index = actionObjectHolder

local types = require(script.Parent.Types) ---@module Types

local ActionDataTemplate: types.ActionData = {
    ActionKey = "",
    KeyCodes = {},
    RespectGameProcessed = true,

    SignalByChanged = false,

    AllowSameActionKey = true,
    TargetPressedState = {true, false}, --// Target IsKeyDown = true, false
    _PressCounter = 0,

    _IsKeyDown = false,
    _IsSingleKey = true,

    _KeyToPressTimestamp = {},
    _CallbackFunctions = {}
}

function actionObjectHolder:GenerateReturnObject(inputObject: types.SerializedInputObject) : types.ReturnInputObject
    local returnObject: types.ReturnInputObject = table.clone(inputObject)
    returnObject.CurrentPressCount = self._PressCounter
    returnObject.ActionObject = self

    function returnObject:IsSameKeyPress()
        return self.CurrentPressCount == self.ActionObject._PressCounter
    end

    function returnObject:IsStillHolding()
        return self:IsSameKeyPress() and self.ActionObject._IsKeyDown
    end

    return returnObject
end

function actionObjectHolder:AreKeysPressedInOrder()
	local keyOrder = self.KeyCodes
	local keyTimestamps = self._KeyToPressTimestamp

	local previousPressedTimestamp = 0

    --// Iterates through provided keycodes from data
	for _, keyCode in keyOrder do
		local keyPressedTimeStamp = keyTimestamps[keyCode] or -1
		local isPressed = keyPressedTimeStamp > 0

        --// previousTimestamp is timestamp of key press before current one
        --// if previousTimestamp > keyPressedTimeStamp
        --// previousTimestamp is newer than current one (previous key has newer key press), therefore order no good!
		if not isPressed or (previousPressedTimestamp > keyPressedTimeStamp) then
			return false
		end

		previousPressedTimestamp = keyPressedTimeStamp
	end

	return true
end

function actionObjectHolder:Trigger(inputObject: types.SerializedInputObject)
    --// Set timestamp of when key is down if not make it -1
    local triggerInput = inputObject.TriggerInput
    self._KeyToPressTimestamp[triggerInput] = inputObject.IsKeyDown and os.clock() or -1

    if not self._IsSingleKey and not self.LastKeyPressed then
        --// If all keys are pressed in order of timestamps then LastKeyPressed == true\
        --// Cant use tenary as I only want to set it to true so it doesnt get set to false when changes happen
        --// I need to know that everything was pressed, because last key can be triggered if the state is up/down
        if self:AreKeysPressedInOrder() then
            self._IsKeyDown = true
            self.LastKeyPressed = true
        else
            self._IsKeyDown = false
        end
    else
        self._IsKeyDown = inputObject._IsKeyDown
        --// Will set existing true to true when code above doesn't get ran as it already detected full press.
        self.LastKeyPressed = true
    end

    if self.TargetPressedState[inputObject._IsKeyDown] and self.LastKeyPressed then
        self._PressCounter += 1
        --// For return object to check if player if player is still holding key from other check

        self:CallCallbackFunctions(self:GenerateReturnObject(inputObject))

        if inputObject.IsKeyDown and self.TargetPressedState[false] then
            return
        end

        self.LastKeyPressed = false
    elseif self._IsSingleKey and self.TargetPressedState[inputObject.IsKeyDown] then
        self._PressCounter += 1
        --// For return object to check if player if player is still holding key from other check

        self:CallCallbackFunctions(self:GenerateReturnObject(inputObject))
    end
end

--// Funny :P
function actionObjectHolder:CallCallbackFunctions(...)
    for _, callbackFunction in self._CallbackFunctions do
        pcall(callbackFunction, ...)
    end
end

function actionObjectHolder:BindFunction(callbackFunction: () -> (), priority: number)
    local callbackFunctions = self._CallbackFunctions

    if not priority then
        table.insert(callbackFunctions, callbackFunction)

        return
    end

    local storedValue = callbackFunctions[priority]

    if not storedValue then
        table.insert(self._CallbackFunctions, priority, callbackFunction)

        return
    end

    local storedTypeOf = typeof(storedValue)

    if storedTypeOf == "function" then
        callbackFunctions[priority] = {storedValue, callbackFunction}
    else
        table.insert(storedValue, callbackFunction)
    end
end

function actionObjectModule:ValidateDataAndMerge(targetDataTemplate: types.ActionData, validatedDataTable: types.UserActionData)
    for key, value in validatedDataTable do
        local correctTypeof = typeof(targetDataTemplate[key])
        local recvTypeof = typeof(value)

        if correctTypeof ~= recvTypeof and recvTypeof ~= nil then
            error(`[{key}] {correctTypeof} expected, got {recvTypeof}.`)
        end

        targetDataTemplate[key] = value
    end
end

function actionObjectModule.New(_ActionData: types.UserActionData) : types.ActionData
    local actionObject = setmetatable(
        table.clone(ActionDataTemplate),
        actionObjectHolder
    )

    --// SUUUPER IMPORTANT!! Even if I clone table at doing setmetatable it would only store refference to already existing table
    --// You can imagine how long it took me to debug (it actually wasn't that hard, im just kinda... teehee)
    for key, value in actionObject do
        if typeof(value) == "table" then
            actionObject[key] = table.clone(actionObject[key])
        end
    end

    actionObjectModule:ValidateDataAndMerge(actionObject, _ActionData)

    if #actionObject.KeyCodes == 0 then
        error("No keycodes provided.")
    end

    actionObject._IsSingleKey = #actionObject.KeyCodes == 1

    return actionObject
end

return actionObjectModule