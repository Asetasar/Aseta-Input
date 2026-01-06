local actionObjectModule = {}

local actionObjectHolder = {}
actionObjectHolder.__index = actionObjectHolder

local types = require(script.Parent.Types) ---@module types

local ActionDataTemplate: types.ActionData = {
    ActionKey = "",
    KeyCodes = {},
    AbideGameProcessed = true,

    TriggerByChanged = false,

    AllowSameActionKey = true,
    TargetPressedState = {true, false}, --// Target IsKeyDown = true, false
    PressCounter = 0,

    IsKeyDown = false,
    IsSingleKey = true,

    KeyToPressTimestamp = {},
    KeysPressedInOrder = {},
    CallbackFunctions = {}
}

function actionObjectHolder:GenerateReturnObject(inputObject: types.SerialInputObject)
    local returnObject = {
        PressCount = self.PressCounter,
        MainSelf = self,
    }

    function returnObject:IsSameKeyPress()
        return self.PressCount == self.MainSelf.PressCounter
    end

    function returnObject:IsStillHolding()
        return self:IsSameKeyPress() and self.MainSelf.IsKeyDown
    end

    return returnObject
end

function actionObjectHolder:AreKeysPressedInOrder()
	local keyOrder = self.KeyCodes
	local keyTimestamps = self.KeyToPressTimestamp

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

function actionObjectHolder:Trigger(inputObject: types.SerialInputObject)
    --// Set timestamp of when key is down if not make it -1
    local keyCode = inputObject.GlobalInput
    self.KeyToPressTimestamp[keyCode] = inputObject.IsKeyDown and os.clock() or -1

    if not self.IsSingleKey and not self.LastKeyPressed then
        --// If all keys are pressed in order of timestamps then LastKeyPressed == true\
        --// Cant use tenary as I only want to set it to true so it doesnt get set to false when changes happen
        --// I need to know that everything was pressed, because last key can be triggered if the state is up/down
        if self:AreKeysPressedInOrder() then
            self.IsKeyDown = true
            self.LastKeyPressed = true
        else
            self.IsKeyDown = false
        end
    else
        self.IsKeyDown = inputObject.IsKeyDown
        --// Will set existing true to true when code above doesn't get ran as it already detected full press.
        self.LastKeyPressed = true
    end

    if self.TargetPressedState[inputObject.IsKeyDown] and self.LastKeyPressed then
        self.PressCounter += 1
        --// For return object to check if player if player is still holding key from other check

        self.CallbackFunction(self:GenerateReturnObject(inputObject))

        if inputObject.IsKeyDown and self.TargetPressedState[false] then
            return
        end

        self.LastKeyPressed = false
    elseif self.IsSingleKey and self.TargetPressedState[inputObject.IsKeyDown] then
        self.PressCounter += 1
        --// For return object to check if player if player is still holding key from other check

        self:CallCallbackFunctions(self:GenerateReturnObject(inputObject))
    end
end

--// Funny :P
function actionObjectHolder:CallCallbackFunctions(...)
    for _, callbackFunction in self.CallbackFunctions do
        pcall(callbackFunction, ...)
    end
end

function actionObjectHolder:BindFunction(callbackFunction: () -> (), priority: number)
    local callbackFunctions = self.CallbackFunctions

    if not priority then
        table.insert(callbackFunctions, callbackFunction)

        return
    end

    local storedValue = callbackFunctions[priority]

    if not storedValue then 
        table.insert(self.CallbackFunctions, priority, callbackFunction)

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
        print(targetDataTemplate)
        local correctTypeof = typeof(targetDataTemplate[key])
        local recvTypeof = typeof(value)
    
        print(correctTypeof, key, value)

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

    actionObjectModule:ValidateDataAndMerge(actionObject, _ActionData)

    if #actionObject.KeyCodes == 0 then
        error("No keycodes provided.")
    end

    actionObject.IsSingleKey = #actionObject.KeyCodes == 1

    return actionObject
end

return actionObjectModule