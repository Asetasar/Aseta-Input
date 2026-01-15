export type UserActionData = {
    Actionkey: string?,
    KeyCodes: {Enum.KeyCode | Enum.UserInputType}?,
    RespectGameProcessed: boolean?,
    SignalByChanged: boolean?,
    AllowSameActionKey: boolean?,
    TargetPressedState: {boolean}?,
}

export type ActionData = {
    ActionKey: string,

    KeyCodes: {Enum.KeyCode},

    RespectGameProcessed: boolean,
    SignalByChanged: boolean,
    AllowSameActionKey: boolean,

    TargetPressedState: {boolean},

    _PressCounter: number,
    _IsKeyDown: boolean,
    _IsSingleKey: boolean,
    _LastKeyPressed: boolean,

    _KeyToPressTimestamp: {[Enum.KeyCode]: number},
    _CallbackFunctions: (() -> ()) | {() -> ()}
}

export type SerializedInputObject = {
    IsKeyDown: boolean,
    IsChanging: boolean,
    IsKeyCode: boolean,

    GameProcessedEvent: boolean,
    Position: Vector3,
    Delta:    Vector3,

    TriggerInput: Enum.KeyCode | Enum.UserInputType,
}

export type ReturnInputObject = {
    IsKeyDown: boolean,
    IsChanging: boolean,
    IsKeyCode: boolean,

    GameProcessedEvent: boolean,
    Position: Vector3,
    Delta:    Vector3,

    TriggerInput: Enum.KeyCode | Enum.UserInputType,

    CurrentPressCount: number,
    ActionObject: ActionData
}


return {}