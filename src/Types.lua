export type UserActionData = {
    Actionkey: string?,
    KeyCodes: {Enum.KeyCode | Enum.UserInputType}?,
    AbideGameProcessed: boolean?,
    TriggerByChanged: boolean?,
    AllowSameActionKey: boolean?,
    TargetPressedState: {boolean}?,
}

export type ActionData = {
    ActionKey: string?,

    KeyCodes: {Enum.KeyCode}?,

    AbideGameProcessed: boolean?,
    TriggerByChanged: boolean?,
    AllowSameActionKey: boolean?,

    TargetPressedState: {boolean}?,

    PressCounter: number?,
    IsKeyDown: boolean?,
    IsSingleKey: boolean?,

    KeyToPressTimestamp: {[Enum.KeyCode]: number}?,
    KeysPressedInOrder: {Enum.KeyCode}?,
    CallbackFunctions: (() -> ()) | {() -> ()}?
}

export type SerialInputObject = {
    IsKeyDown: boolean,
    IsChanging: boolean,
    IsKeyCode: boolean,

    GameProcessedEvent: boolean,
    Position: Vector3,
    Delta:    Vector3,

    --// I was thinking why, but why not ¯_(ツ)_/¯
    KeyCode: Enum.KeyCode,
    GlobalInput: Enum.KeyCode | Enum.UserInputType,
}

return {}