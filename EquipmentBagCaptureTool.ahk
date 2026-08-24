#Requires AutoHotkey v2.0
#SingleInstance Force

SetTitleMatchMode 2
CoordMode "Mouse", "Screen"
SendMode "Event"

global APP_NAME := "Equipment Bag Capture Tool"
global CONFIG_FILE := A_ScriptDir . "\EquipmentBagCapture.ini"
global CHECKPOINT_FILE := A_ScriptDir . "\EquipmentBagCaptureCheckpoint.ini"

global MAPLE_TITLE := ""
global MapleHwnd := 0

global GRID_X := []
global GRID_Y := []
global ITEMS_PER_SCREEN := 12

global POPUP_CLOSE_X := 0
global POPUP_CLOSE_Y := 0

global DRAG_START_X := 0
global DRAG_START_Y := 0
global DRAG_SHORT_DISTANCE := 576
global DRAG_LONG_DISTANCE := 577
global DRAG_STEPS := 36
global STEP_DELAY := 20
global HOLD_DELAY := 700

global CALIBRATED_SCREEN_WIDTH := 0
global CALIBRATED_SCREEN_HEIGHT := 0

global RequestedItems := 0
global ExpectedMovements := 0
global CompletedScreenshots := 0
global CompletedMovements := 0
global CaptureRunning := false
global StopRequested := false
global StopPopupOpen := false

global SHAREX_POST_CAPTURE_DELAY := 850

SetTimer(ShowStartupMessage, -250)

F8::StartEquipmentCapture()
F9::ResumeSavedCapture()

Esc::
{
    global CaptureRunning
    global StopRequested

    if CaptureRunning
    {
        StopRequested := true
        UnlockUserMouse()
        ReleaseEverything()
        return
    }

    UnlockUserMouse()
    ToolTip
    ReleaseEverything()
    ExitApp
}

ShowStartupMessage()
{
    global APP_NAME
    global CHECKPOINT_FILE
    global SHAREX_POST_CAPTURE_DELAY

    checkpointText := ""

    if FileExist(CHECKPOINT_FILE)
    {
        try
        {
            requested := IniRead(CHECKPOINT_FILE, "Resume", "RequestedItems") + 0
            completed := IniRead(CHECKPOINT_FILE, "Resume", "CompletedScreenshots") + 0
            nextItem := IniRead(CHECKPOINT_FILE, "Resume", "NextItem") + 0
            movements := IniRead(CHECKPOINT_FILE, "Resume", "CompletedMovements") + 0

            checkpointText := (
                "`nSAVED RESUME CHECKPOINT FOUND:`n"
                . "Captured: " . completed . " / " . requested . "`n"
                . "Next item: " . nextItem . "`n"
                . "Movements completed: " . movements . "`n`n"
                . "Press F9 to resume.`n"
            )
        }
        catch
        {
            checkpointText := (
                "`nA checkpoint file exists but could not be read.`n"
                . "Press F8 to start a new capture and replace it.`n"
            )
        }
    }

    MsgBox(
        "Equipment Bag Capture Tool is ready.`n`n"
        . "Press F8 to start a NEW capture.`n"
        . "Press F9 to RESUME a saved safe-stop checkpoint.`n`n"
        . "During capture:`n"
        . "• Physical mouse movement is locked.`n"
        . "• A live counter appears in the top-left corner.`n"
        . "• Press Esc for a safe stop.`n"
        . "• The safe stop is saved to disk before the script exits.`n"
        . checkpointText
        . "`nShareX post-capture wait: "
        . SHAREX_POST_CAPTURE_DELAY . " ms",
        APP_NAME
    )
}

StartEquipmentCapture()
{
    global APP_NAME
    global CONFIG_FILE
    global CHECKPOINT_FILE
    global MAPLE_TITLE
    global MapleHwnd
    global ITEMS_PER_SCREEN
    global RequestedItems
    global ExpectedMovements
    global CompletedScreenshots
    global CompletedMovements
    global CaptureRunning
    global StopRequested
    global StopPopupOpen
    global CALIBRATED_SCREEN_WIDTH
    global CALIBRATED_SCREEN_HEIGHT
    global SHAREX_POST_CAPTURE_DELAY

    if CaptureRunning
        return

    if FileExist(CHECKPOINT_FILE)
    {
        answer := MsgBox(
            "A saved resume checkpoint already exists.`n`n"
            . "Starting a new capture will DELETE that checkpoint.`n`n"
            . "Continue with a new capture?",
            APP_NAME,
            "YesNo Icon!"
        )

        if answer != "Yes"
            return

        DeleteCheckpoint()
    }

    if !PrepareEnvironment()
        return

    itemInput := InputBox(
        "Enter the total number of equipment items to capture.",
        APP_NAME,
        "w420 h150",
        "12"
    )

    if itemInput.Result != "OK"
        return

    itemText := Trim(itemInput.Value)

    if !RegExMatch(itemText, "^\d+$")
    {
        MsgBox("Enter a whole number greater than zero.", APP_NAME)
        return
    }

    RequestedItems := itemText + 0

    if RequestedItems < 1
    {
        MsgBox("Enter a whole number greater than zero.", APP_NAME)
        return
    }

    requiredScreens := Ceil(RequestedItems / ITEMS_PER_SCREEN)
    ExpectedMovements := Max(0, requiredScreens - 1)

    answer := MsgBox(
        "Ready to capture the equipment bag.`n`n"
        . "Equipment items: " . RequestedItems . "`n"
        . "Items per screen: " . ITEMS_PER_SCREEN . "`n"
        . "Required movements: " . ExpectedMovements . "`n"
        . "ShareX wait: " . SHAREX_POST_CAPTURE_DELAY . " ms`n`n"
        . "Before starting:`n"
        . "• ShareX is ready to capture the saved popup region.`n"
        . "• The 3-column equipment bag view is open.`n"
        . "• The correct equipment category is selected.`n"
        . "• The equipment list is at the absolute top.`n"
        . "• No equipment popup is currently open.`n"
        . "• Maple is in its calibrated position and size.`n`n"
        . "During capture, physical mouse movement is locked.`n"
        . "Press Esc if you need to stop safely.`n`n"
        . "After a safe stop, DO NOT move or scroll the bag.`n"
        . "Restart this same script and press F9 to resume.",
        APP_NAME,
        "OKCancel Icon!"
    )

    if answer != "OK"
        return

    KeyWait "F8"

    CompletedScreenshots := 0
    CompletedMovements := 0
    StopRequested := false
    StopPopupOpen := false
    CaptureRunning := true

    LockUserMouse()
    UpdateProgress("NEW CAPTURE")

    if !ActivateMaple()
    {
        CaptureRunning := false
        UnlockUserMouse()
        ToolTip
        MsgBox("Maple could not be activated.", APP_NAME)
        return
    }

    Sleep 300
    remainingItems := RequestedItems
    screenNumber := 1

    while remainingItems > 0
    {
        itemsThisScreen := Min(ITEMS_PER_SCREEN, remainingItems)
        startGridRow := 1

        if screenNumber > 1 && remainingItems < ITEMS_PER_SCREEN
        {
            rowsNeeded := Ceil(itemsThisScreen / 3)
            startGridRow := 5 - rowsNeeded
        }

        StopPopupOpen := false

        if !CaptureItems(itemsThisScreen, startGridRow)
        {
            CaptureRunning := false
            UnlockUserMouse()
            ToolTip
            return
        }

        if StopRequested
        {
            HandleSafeStop(StopPopupOpen)
            return
        }

        remainingItems -= itemsThisScreen

        if remainingItems > 0
        {
            StopPopupOpen := false

            if !MoveOnce()
            {
                CaptureRunning := false
                UnlockUserMouse()
                ToolTip
                return
            }

            if StopRequested
            {
                HandleSafeStop(false)
                return
            }

            screenNumber += 1
        }
    }

    CaptureRunning := false
    UnlockUserMouse()
    ToolTip
    DeleteCheckpoint()
    ShowCompletionReport(false)
}

ResumeSavedCapture()
{
    global APP_NAME
    global CHECKPOINT_FILE
    global RequestedItems
    global ExpectedMovements
    global CompletedScreenshots
    global CompletedMovements
    global CaptureRunning
    global StopRequested
    global StopPopupOpen
    global POPUP_CLOSE_X
    global POPUP_CLOSE_Y

    if CaptureRunning
        return

    if !FileExist(CHECKPOINT_FILE)
    {
        MsgBox(
            "No saved resume checkpoint was found.`n`n"
            . "Press F8 to start a new capture.",
            APP_NAME
        )
        return
    }

    if !PrepareEnvironment()
        return

    try
    {
        RequestedItems := IniRead(CHECKPOINT_FILE, "Resume", "RequestedItems") + 0
        ExpectedMovements := IniRead(CHECKPOINT_FILE, "Resume", "ExpectedMovements") + 0
        CompletedScreenshots := IniRead(CHECKPOINT_FILE, "Resume", "CompletedScreenshots") + 0
        CompletedMovements := IniRead(CHECKPOINT_FILE, "Resume", "CompletedMovements") + 0
        nextItem := IniRead(CHECKPOINT_FILE, "Resume", "NextItem") + 0
        popupOpen := IniRead(CHECKPOINT_FILE, "Resume", "PopupOpen") + 0
    }
    catch as error
    {
        MsgBox(
            "The saved checkpoint could not be read.`n`n"
            . error.Message,
            APP_NAME
        )
        return
    }

    if (
        RequestedItems < 1
        || CompletedScreenshots < 0
        || CompletedScreenshots > RequestedItems
        || nextItem != CompletedScreenshots + 1
        || CompletedMovements < 0
        || CompletedMovements > ExpectedMovements
    )
    {
        MsgBox(
            "The saved checkpoint is invalid or inconsistent.`n`n"
            . "Do not resume from it.",
            APP_NAME
        )
        return
    }

    if CompletedScreenshots >= RequestedItems
    {
        MsgBox(
            "The saved checkpoint already shows the capture as complete.`n`n"
            . "Delete the checkpoint by starting a new capture with F8.",
            APP_NAME
        )
        return
    }

    answer := MsgBox(
        "Resume saved capture?`n`n"
        . "Requested items: " . RequestedItems . "`n"
        . "Already captured: " . CompletedScreenshots . "`n"
        . "Next item: " . nextItem . "`n"
        . "Movements completed: "
        . CompletedMovements . " / " . ExpectedMovements . "`n`n"
        . "IMPORTANT:`n"
        . "Maple must still be on the SAME equipment category and at the SAME scroll position left by Esc.`n"
        . "Do not manually close the popup or move the list before resuming.`n`n"
        . "Press OK to continue from item " . nextItem . ".",
        APP_NAME,
        "OKCancel Icon!"
    )

    if answer != "OK"
        return

    KeyWait "F9"

    StopRequested := false
    StopPopupOpen := false
    CaptureRunning := true
    LockUserMouse()
    UpdateProgress("RESUME")

    if !ActivateMaple()
    {
        CaptureRunning := false
        UnlockUserMouse()
        ToolTip
        MsgBox("Maple could not be activated.", APP_NAME)
        return
    }

    if popupOpen
    {
        LowLevelClick(POPUP_CLOSE_X, POPUP_CLOSE_Y)
        Sleep 350
    }

    while CompletedScreenshots < RequestedItems
    {
        nextItem := CompletedScreenshots + 1
        batchStart := (CompletedMovements * 12) + 1
        batchRemaining := RequestedItems - batchStart + 1
        batchItems := Min(12, batchRemaining)
        batchEnd := batchStart + batchItems - 1

        if nextItem > batchEnd
        {
            StopPopupOpen := false

            if !MoveOnce()
            {
                CaptureRunning := false
                UnlockUserMouse()
                ToolTip
                return
            }

            if StopRequested
            {
                HandleSafeStop(false)
                return
            }

            continue
        }

        startGridRow := 1

        if CompletedMovements > 0 && batchItems < 12
        {
            rowsNeeded := Ceil(batchItems / 3)
            startGridRow := 5 - rowsNeeded
        }

        startPosition := nextItem - batchStart + 1
        itemsToCapture := batchEnd - nextItem + 1

        StopPopupOpen := false

        if !CaptureResumeRange(startPosition, itemsToCapture, startGridRow)
        {
            CaptureRunning := false
            UnlockUserMouse()
            ToolTip
            return
        }

        if StopRequested
        {
            HandleSafeStop(StopPopupOpen)
            return
        }
    }

    CaptureRunning := false
    UnlockUserMouse()
    ToolTip
    DeleteCheckpoint()
    ShowCompletionReport(true)
}

PrepareEnvironment()
{
    global APP_NAME
    global CONFIG_FILE
    global MAPLE_TITLE
    global MapleHwnd
    global CALIBRATED_SCREEN_WIDTH
    global CALIBRATED_SCREEN_HEIGHT

    if !FileExist(CONFIG_FILE)
    {
        MsgBox(
            "EquipmentBagCapture.ini was not found.`n`n"
            . "Run EquipmentBagCaptureCalibration.ahk first.",
            APP_NAME
        )
        return false
    }

    try
        LoadConfiguration()
    catch as error
    {
        MsgBox(
            "The calibration file could not be read.`n`n"
            . error.Message . "`n`n"
            . "Run EquipmentBagCaptureCalibration.ahk again.",
            APP_NAME
        )
        return false
    }

    if (
        A_ScreenWidth != CALIBRATED_SCREEN_WIDTH
        || A_ScreenHeight != CALIBRATED_SCREEN_HEIGHT
    )
    {
        answer := MsgBox(
            "The current screen size differs from the calibration.`n`n"
            . "Calibrated: "
            . CALIBRATED_SCREEN_WIDTH . " x "
            . CALIBRATED_SCREEN_HEIGHT . "`n"
            . "Current: "
            . A_ScreenWidth . " x "
            . A_ScreenHeight . "`n`n"
            . "Continuing may click the wrong locations.`n`n"
            . "Continue anyway?",
            APP_NAME,
            "YesNo Icon!"
        )

        if answer != "Yes"
            return false
    }

    if !ProcessExist("ShareX.exe")
    {
        MsgBox("ShareX is not running.", APP_NAME)
        return false
    }

    MapleHwnd := WinExist(MAPLE_TITLE)

    if !MapleHwnd
    {
        MsgBox(
            "The MapleStory: Idle RPG PC client could not be found.",
            APP_NAME
        )
        return false
    }

    return true
}

LoadConfiguration()
{
    global CONFIG_FILE
    global MAPLE_TITLE
    global GRID_X
    global GRID_Y
    global POPUP_CLOSE_X
    global POPUP_CLOSE_Y
    global DRAG_START_X
    global DRAG_START_Y
    global DRAG_SHORT_DISTANCE
    global DRAG_LONG_DISTANCE
    global DRAG_STEPS
    global STEP_DELAY
    global HOLD_DELAY
    global CALIBRATED_SCREEN_WIDTH
    global CALIBRATED_SCREEN_HEIGHT

    MAPLE_TITLE := IniRead(CONFIG_FILE, "General", "WindowTitle")
    CALIBRATED_SCREEN_WIDTH := IniRead(CONFIG_FILE, "General", "ScreenWidth") + 0
    CALIBRATED_SCREEN_HEIGHT := IniRead(CONFIG_FILE, "General", "ScreenHeight") + 0

    GRID_X := [
        IniRead(CONFIG_FILE, "Grid", "X1") + 0,
        IniRead(CONFIG_FILE, "Grid", "X2") + 0,
        IniRead(CONFIG_FILE, "Grid", "X3") + 0
    ]

    GRID_Y := [
        IniRead(CONFIG_FILE, "Grid", "Y1") + 0,
        IniRead(CONFIG_FILE, "Grid", "Y2") + 0,
        IniRead(CONFIG_FILE, "Grid", "Y3") + 0,
        IniRead(CONFIG_FILE, "Grid", "Y4") + 0
    ]

    POPUP_CLOSE_X := IniRead(CONFIG_FILE, "Popup", "CloseX") + 0
    POPUP_CLOSE_Y := IniRead(CONFIG_FILE, "Popup", "CloseY") + 0

    DRAG_START_X := IniRead(CONFIG_FILE, "Movement", "StartX") + 0
    DRAG_START_Y := IniRead(CONFIG_FILE, "Movement", "StartY") + 0
    DRAG_SHORT_DISTANCE := IniRead(CONFIG_FILE, "Movement", "ShortDistance", 576) + 0
    DRAG_LONG_DISTANCE := IniRead(CONFIG_FILE, "Movement", "LongDistance", 577) + 0
    DRAG_STEPS := IniRead(CONFIG_FILE, "Movement", "Steps", 36) + 0
    STEP_DELAY := IniRead(CONFIG_FILE, "Movement", "StepDelay", 20) + 0
    HOLD_DELAY := IniRead(CONFIG_FILE, "Movement", "HoldDelay", 700) + 0
}

CaptureItems(itemsToCapture, startGridRow := 1)
{
    global APP_NAME
    global GRID_X
    global GRID_Y
    global POPUP_CLOSE_X
    global POPUP_CLOSE_Y
    global CompletedScreenshots
    global StopRequested
    global StopPopupOpen

    Loop itemsToCapture
    {
        itemOnScreen := A_Index
        row := startGridRow + Floor((itemOnScreen - 1) / 3)
        column := Mod(itemOnScreen - 1, 3) + 1

        if !ActivateMaple()
        {
            MsgBox(
                "Maple could not be activated before item "
                . (CompletedScreenshots + 1) . ".",
                APP_NAME
            )
            return false
        }

        ReliableItemClick(GRID_X[column], GRID_Y[row])

        if itemOnScreen = 1
            Sleep 750
        else
            Sleep 600

        TriggerShareX()
        CompletedScreenshots += 1
        UpdateProgress("NEW CAPTURE")

        if StopRequested
        {
            StopPopupOpen := true
            return true
        }
    }

    if !ActivateMaple()
    {
        MsgBox(
            "Maple could not be activated to close the equipment popup.",
            APP_NAME
        )
        return false
    }

    LowLevelClick(POPUP_CLOSE_X, POPUP_CLOSE_Y)
    Sleep 350
    StopPopupOpen := false
    return true
}

CaptureResumeRange(startPosition, itemsToCapture, startGridRow)
{
    global APP_NAME
    global GRID_X
    global GRID_Y
    global POPUP_CLOSE_X
    global POPUP_CLOSE_Y
    global CompletedScreenshots
    global StopRequested
    global StopPopupOpen

    Loop itemsToCapture
    {
        position := startPosition + A_Index - 1
        row := startGridRow + Floor((position - 1) / 3)
        column := Mod(position - 1, 3) + 1

        if !ActivateMaple()
        {
            MsgBox(
                "Maple could not be activated before item "
                . (CompletedScreenshots + 1) . ".",
                APP_NAME
            )
            return false
        }

        ReliableItemClick(GRID_X[column], GRID_Y[row])

        if A_Index = 1
            Sleep 750
        else
            Sleep 600

        TriggerShareX()
        CompletedScreenshots += 1
        UpdateProgress("RESUME")

        if StopRequested
        {
            StopPopupOpen := true
            return true
        }
    }

    if !ActivateMaple()
    {
        MsgBox(
            "Maple could not be activated to close the equipment popup.",
            APP_NAME
        )
        return false
    }

    LowLevelClick(POPUP_CLOSE_X, POPUP_CLOSE_Y)
    Sleep 350
    StopPopupOpen := false
    return true
}

ReliableItemClick(clickX, clickY)
{
    LowLevelClick(clickX, clickY)
    Sleep 300
    LowLevelClick(clickX, clickY)
}

MoveOnce()
{
    global APP_NAME
    global CompletedMovements
    global StopRequested
    global DRAG_SHORT_DISTANCE
    global DRAG_LONG_DISTANCE

    if StopRequested
        return true

    if !ActivateMaple()
    {
        MsgBox(
            "Maple could not be activated before movement.",
            APP_NAME
        )
        return false
    }

    ; DO NOT CHANGE:
    ; movement 1 = 576, movement 2 = 577, then alternate.
    movementNumber := CompletedMovements + 1
    movementDistance := Mod(movementNumber, 2) = 1
        ? DRAG_SHORT_DISTANCE
        : DRAG_LONG_DISTANCE

    PerformDrag(movementDistance)
    CompletedMovements += 1
    UpdateProgress("CAPTURE")
    Sleep 800
    return true
}

PerformDrag(movementDistance)
{
    global DRAG_START_X
    global DRAG_START_Y
    global DRAG_STEPS
    global STEP_DELAY
    global HOLD_DELAY

    endX := DRAG_START_X
    endY := DRAG_START_Y - movementDistance

    ReleaseMouse()
    MouseMove(DRAG_START_X, DRAG_START_Y, 0)
    Sleep 500
    Click "Down"
    Sleep 250

    Loop DRAG_STEPS
    {
        fraction := A_Index / DRAG_STEPS
        nextX := Round(DRAG_START_X + ((endX - DRAG_START_X) * fraction))
        nextY := Round(DRAG_START_Y + ((endY - DRAG_START_Y) * fraction))
        MouseMove(nextX, nextY, 0)
        Sleep STEP_DELAY
    }

    Sleep HOLD_DELAY
    Click "Up"
    Sleep 300
}

UpdateProgress(mode := "CAPTURE")
{
    global RequestedItems
    global ExpectedMovements
    global CompletedScreenshots
    global CompletedMovements
    global SHAREX_POST_CAPTURE_DELAY

    ToolTip(
        mode . "`n"
        . "Captured: " . CompletedScreenshots . " / " . RequestedItems . "`n"
        . "Movements: " . CompletedMovements . " / " . ExpectedMovements . "`n"
        . "ShareX: " . SHAREX_POST_CAPTURE_DELAY . " ms",
        20,
        20
    )
}

ActivateMaple()
{
    global MapleHwnd

    ReleaseEverything()
    WinActivate "ahk_id " . MapleHwnd
    startTime := A_TickCount

    while !WinActive("ahk_id " . MapleHwnd)
    {
        if A_TickCount - startTime > 2000
            return false
        Sleep 50
    }

    Sleep 150
    return true
}

TriggerShareX()
{
    global SHAREX_POST_CAPTURE_DELAY

    ReleaseKeyboard()
    Sleep 100
    SendEvent "^+z"
    Sleep SHAREX_POST_CAPTURE_DELAY
    ReleaseKeyboard()
}

LowLevelClick(clickX, clickY)
{
    ReleaseMouse()
    DllCall("SetCursorPos", "Int", clickX, "Int", clickY)
    Sleep 100
    DllCall(
        "mouse_event", "UInt", 0x0002,
        "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0
    )
    Sleep 220
    DllCall(
        "mouse_event", "UInt", 0x0004,
        "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0
    )
    Sleep 120
}

LockUserMouse()
{
    BlockInput "MouseMove"
}

UnlockUserMouse()
{
    try BlockInput "MouseMoveOff"
}

HandleSafeStop(popupOpen)
{
    global APP_NAME
    global CaptureRunning

    CaptureRunning := false
    UnlockUserMouse()
    ToolTip

    SaveCheckpoint(popupOpen)
    ShowStoppedReport(popupOpen)

    ReleaseEverything()
    ExitApp
}

SaveCheckpoint(popupOpen)
{
    global CHECKPOINT_FILE
    global RequestedItems
    global ExpectedMovements
    global CompletedScreenshots
    global CompletedMovements

    nextItem := CompletedScreenshots + 1

    if FileExist(CHECKPOINT_FILE)
        FileDelete CHECKPOINT_FILE

    IniWrite RequestedItems, CHECKPOINT_FILE, "Resume", "RequestedItems"
    IniWrite ExpectedMovements, CHECKPOINT_FILE, "Resume", "ExpectedMovements"
    IniWrite CompletedScreenshots, CHECKPOINT_FILE, "Resume", "CompletedScreenshots"
    IniWrite CompletedMovements, CHECKPOINT_FILE, "Resume", "CompletedMovements"
    IniWrite nextItem, CHECKPOINT_FILE, "Resume", "NextItem"
    IniWrite (popupOpen ? 1 : 0), CHECKPOINT_FILE, "Resume", "PopupOpen"
}

DeleteCheckpoint()
{
    global CHECKPOINT_FILE

    if FileExist(CHECKPOINT_FILE)
        FileDelete CHECKPOINT_FILE
}

ShowStoppedReport(popupOpen)
{
    global APP_NAME
    global RequestedItems
    global CompletedScreenshots
    global CompletedMovements
    global ExpectedMovements
    global SHAREX_POST_CAPTURE_DELAY
    global CHECKPOINT_FILE

    nextItem := CompletedScreenshots + 1

    report := (
        "CAPTURE STOPPED SAFELY.`n`n"
        . "Requested equipment items: " . RequestedItems . "`n"
        . "Screenshot commands completed: " . CompletedScreenshots . "`n"
        . "Next item number: " . nextItem . "`n`n"
        . "Expected movements: " . ExpectedMovements . "`n"
        . "Movements completed: " . CompletedMovements . "`n`n"
        . "ShareX post-capture wait: " . SHAREX_POST_CAPTURE_DELAY . " ms`n`n"
        . "Resume checkpoint SAVED.`n"
        . "Popup open at checkpoint: " . (popupOpen ? "Yes" : "No") . "`n`n"
        . "DO NOT move or scroll the Maple equipment bag.`n"
        . "Restart this same script and press F9 to resume.`n`n"
        . "Checkpoint file:`n" . CHECKPOINT_FILE
    )

    A_Clipboard := report

    MsgBox(
        report
        . "`n`nThe stop report has been copied to the clipboard."
        . "`n`nPress OK to close the script.",
        APP_NAME
    )
}

ShowCompletionReport(wasResumed := false)
{
    global APP_NAME
    global RequestedItems
    global CompletedScreenshots
    global CompletedMovements
    global ExpectedMovements
    global SHAREX_POST_CAPTURE_DELAY

    report := (
        (wasResumed ? "RESUMED CAPTURE FINISHED." : "Finished.") . "`n`n"
        . "Requested equipment items: " . RequestedItems . "`n"
        . "Screenshot commands sent: " . CompletedScreenshots . "`n`n"
        . "Expected movements: " . ExpectedMovements . "`n"
        . "Movements performed: " . CompletedMovements . "`n`n"
        . "ShareX post-capture wait: " . SHAREX_POST_CAPTURE_DELAY . " ms`n"
        . "Resume checkpoint cleared: Yes"
    )

    A_Clipboard := report

    MsgBox(
        report
        . "`n`nThe result has been copied to the clipboard."
        . "`n`nFor an important run, verify the screenshot file count and CRCs.",
        APP_NAME
    )
}

ReleaseMouse()
{
    DllCall(
        "mouse_event", "UInt", 0x0004,
        "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0
    )
    SendEvent "{LButton up}{RButton up}{MButton up}"
}

ReleaseKeyboard()
{
    SendEvent("{Ctrl up}{Shift up}{Alt up}{LWin up}{RWin up}")
}

ReleaseEverything()
{
    ReleaseMouse()
    ReleaseKeyboard()
}
