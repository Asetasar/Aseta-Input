--!nocheck

local inputHandler = {
    Loaded = false,
}

local inputHandlerHolder = {
    GlobalActionTable = {},
    ReverseGlobalActionTable = {},
    KeyToActionTable = {}
}

local UserInputService = game:GetService("UserInputService")

local actionObjectModule = require("@self/ActionObject")
local types = require("@self/Types") ---@module Types

local serializedInputObjectTemplate: types.SerializedInputObject = {
    IsKeyDown = false,
    IsChanging = false,
    IsKeyCode = false,

    GameProcessedEvent = false,
    Position = Vector3.zero,
    Delta    = Vector3.zero,

    --// I was thinking why, but why not ¯_(ツ)_/¯
    KeyCode  = Enum.KeyCode.Unknown,
    TriggerInput = Enum.KeyCode.Unknown,
}

function inputHandlerHolder:GetActionObject(actionKey: string)
    return self.GlobalActionTable[actionKey]
end

function inputHandlerHolder:GetActionKeysByKeyCode(keyCode: EnumItem)
    return self.KeyToActionTable[keyCode]
end

function inputHandlerHolder:GlobalizeInput(inputObject: InputObject)
    --// I know there are edge-cases of None and such but
    --// It would make unnecessary complexity just to return early
    --// And there is also the argument that devs might want to analyze something on None input... ¯_(ツ)_/¯
    local isPureKeyCode = inputObject.KeyCode.Name ~= "Unknown"
    local triggerInput   =  isPureKeyCode and inputObject.KeyCode or inputObject.UserInputType

    return triggerInput, isPureKeyCode
end

function inputHandlerHolder:IsKeyDown(inputObject: InputObject)
    --// I know there is the cancel state but it has essentially same effect as ending so... ¯_(ツ)_/¯
    local isChanging = inputObject.UserInputState.Name == "Change"
    local isKeyDown  = inputObject.UserInputState.Name == "Begin" or isChanging and true or false

    return isKeyDown, isChanging
end

function inputHandlerHolder:SerializeInputObject(_inputObject: InputObject, gameProcessedEvent: boolean) : types.SerializedInputObject
    local inputObject = table.clone(serializedInputObjectTemplate)
    local isKeyDown, isChanging = self:IsKeyDown(_inputObject)
    local triggerInput, isPureKeyCode = self:GlobalizeInput(_inputObject)

    if isKeyDown then
        inputObject.IsKeyDown = true
        inputObject.IsChanging= isChanging
    end

    if isPureKeyCode then
        inputObject.IsKeyCode = true
    end

    inputObject.TriggerInput = triggerInput

    inputObject.GameProcessedEvent = gameProcessedEvent
    inputObject.Position = _inputObject.Position
    inputObject.Delta    = _inputObject.Delta

    return inputObject
end

function inputHandlerHolder:CheckActionObjectparameters(inputObject: types.SerializedInputObject, actionObject: types.ActionData)
    if actionObject.RespectGameProcessed and inputObject.GameProcessedEvent then
        return false
    end

    if not actionObject.SignalByChanged and inputObject.IsChanging then
        return false
    end

    return true
end

function inputHandlerHolder:InputChanged(inputObject: InputObject, gameProcessedEvent: boolean)
    inputObject = self:SerializeInputObject(inputObject, gameProcessedEvent)

    local actionKeys = self:GetActionKeysByKeyCode(inputObject.TriggerInput)

    if not actionKeys then
        return
    end

    for _, actionKey in actionKeys do
        local actionObjects = self:GetActionObject(actionKey)

        --// For multiple same action keys
        if #actionObjects > 0 then
            for _, actionObject in actionObjects do
                if not self:CheckActionObjectparameters(inputObject, actionObject) then
                    continue
                end
                actionObjects:Trigger(inputObject)
            end

            continue
        end

        if self:CheckActionObjectparameters(inputObject, actionObjects) then
            actionObjects:Trigger(inputObject)
        end
    end
end

function inputHandlerHolder:AddReverseLookupKeys(actionKey: string, nestedActionIndexCheck: string, lookupKeys: table)
    local ReverseLookup = self.KeyToActionTable
    --// I wont seperate logic for one key its worthless and messy
    for _, keyCode in lookupKeys do
        local reverseLookupValue = ReverseLookup[keyCode]

        if reverseLookupValue then
            if nestedActionIndexCheck and table.find(reverseLookupValue, actionKey) then
                continue
            end

            table.insert(reverseLookupValue, actionKey)
        else
            ReverseLookup[keyCode] = {actionKey}
        end
    end
end

function inputHandlerHolder:AddActionObjectToLookup(actionObject)
    local actionKey = actionObject.ActionKey

    local keyCodes = actionObject.KeyCodes
    local shouldNestedCheck = false

    local globalLookupValue = self:GetActionObject(actionKey)

    if globalLookupValue then
        if not actionObject.AllowSameActionKey then
            error(`Action {actionKey} already exists, and AllowSameActionKey is false.`)
        end

        if typeof(globalLookupValue) == "table" then
            table.insert(globalLookupValue, actionObject)
        else
            self.GlobalActionTable[actionKey] = {globalLookupValue, actionObject}
        end

        shouldNestedCheck = true
    else
        self.GlobalActionTable[actionKey] = actionObject
    end

    self.ReverseGlobalActionTable[actionObject] = actionKey

    self:AddReverseLookupKeys(actionKey, shouldNestedCheck, keyCodes)
end

function inputHandler:RegisterAction(_ActionData: types.UserActionData): types.ActionData
    local actionObject: types.ActionData = actionObjectModule.New(_ActionData)

    --// HACK: Makes array of bools keys and then makes their value true.
    --// Looks like: {[true] = true, [false] = true}
    local targetPressedStates = actionObject.TargetPressedState
    for index = #targetPressedStates, 1, -1 do
        targetPressedStates[targetPressedStates[index]] = true

        table.remove(targetPressedStates, index)
    end

    inputHandlerHolder:AddActionObjectToLookup(actionObject)

    return actionObject
end

function inputHandler:BindToAction(actionKey: string, callbackFunction: () -> (), priority: number)
    local actionObject = inputHandlerHolder:GetActionObject(actionKey)

    if not actionObject then
        error(`Action {actionObject} doesn't exist.`)
    end

    actionObject:BindFunction(callbackFunction, priority)
end

function inputHandlerHolder:ConnectEvents()
    UserInputService.InputChanged:Connect(function(...)
        self:InputChanged(...)
    end)
    UserInputService.InputBegan:Connect(function(...)
        self:InputChanged(...)
    end)
    UserInputService.InputEnded:Connect(function(...)
        self:InputChanged(...)
    end)
end

function inputHandlerHolder:Init()
    if inputHandler.Loaded then
        return
    end

    inputHandlerHolder:ConnectEvents()
    inputHandler.Loaded = true
end

--// I dont wanna create specific scripts which would just call init so here we are.
if not inputHandler.Loaded then
    inputHandlerHolder:Init()
end

return inputHandler