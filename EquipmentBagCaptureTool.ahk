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

; Phase 12: Maple window geometry recorded by calibration.
global CALIBRATED_WINDOW_LEFT := ""
global CALIBRATED_WINDOW_TOP := ""
global CALIBRATED_WINDOW_WIDTH := ""
global CALIBRATED_WINDOW_HEIGHT := ""

global CALIBRATED_WINDOW_DPI := ""
global RequestedItems := 0
global ExpectedMovements := 0
global CompletedScreenshots := 0
global CompletedMovements := 0
global CaptureRunning := false
global StopRequested := false
global StopPopupOpen := false
global PostMovementFirstItemPending := false
global RUN_LOG := A_ScriptDir . "\\EquipmentBagCapture_Run.log"

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
    global PostMovementFirstItemPending
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
    PostMovementFirstItemPending := false
    InitRunLog("NEW", 1)
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
    global PostMovementFirstItemPending
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

    ; If the checkpoint was taken after a completed movement but before the
    ; first item on the new screen was captured, re-arm the post-move fix.
    PostMovementFirstItemPending := (
        CompletedMovements > 0
        && CompletedScreenshots = (CompletedMovements * 12)
        && CompletedScreenshots < RequestedItems
    )

    InitRunLog("RESUME", CompletedScreenshots + 1, true)
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

    ; If Esc stopped immediately after a captured item, that item's popup
    ; is deliberately left open. Close it before resuming.
    if popupOpen
    {
        LowLevelClick(POPUP_CLOSE_X, POPUP_CLOSE_Y)
        Sleep 350
    }

    while CompletedScreenshots < RequestedItems
    {
        nextItem := CompletedScreenshots + 1

        ; The number of completed movements tells us which 12-item batch
        ; is currently visible. This keeps the original scroll path intact.
        batchStart := (CompletedMovements * 12) + 1
        batchRemaining := RequestedItems - batchStart + 1
        batchItems := Min(12, batchRemaining)
        batchEnd := batchStart + batchItems - 1

        ; Example: stopped after item 12 before the movement happened.
        ; The next item is beyond the current batch, so perform the same
        ; proven movement that the normal path would have performed.
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

        ; Preserve the normal final-screen bottom-clamp handling.
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
    global CALIBRATED_WINDOW_DPI

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

    ; DPI/scaling safety gate. Keep the same display scaling used during
    ; calibration rather than trying to scale the absolute coordinates.
    currentDpi := DllCall("user32\GetDpiForWindow", "Ptr", MapleHwnd, "UInt")
    if !currentDpi
        currentDpi := 96

    if CALIBRATED_WINDOW_DPI = ""
    {
        MsgBox(
            "CAPTURE BLOCKED - DPI/SCALING NOT RECORDED.`n`n"
            . "Run EquipmentBagCaptureCalibration.ahk once at the display "
            . "scaling you intend to use for capture.",
            APP_NAME,
            "Iconx"
        )
        return false
    }

    if currentDpi != (CALIBRATED_WINDOW_DPI + 0)
    {
        MsgBox(
            "CAPTURE BLOCKED - DISPLAY SCALING CHANGED.`n`n"
            . "Calibrated DPI: " . CALIBRATED_WINDOW_DPI . "`n"
            . "Current DPI: " . currentDpi . "`n`n"
            . "Restore the display scaling used during calibration or "
            . "run calibration again.`n`n"
            . "Coordinates are deliberately NOT auto-scaled.",
            APP_NAME,
            "Iconx"
        )
        return false
    }
    ; Phase 12 safety gate: absolute click calibration is only safe when
    ; Maple is at the same position and size used during calibration.
    if !ValidateMapleWindowPosition()
        return false

    return true
}

ValidateMapleWindowPosition()
{
    global APP_NAME
    global MapleHwnd
    global CONFIG_FILE
    global CALIBRATED_WINDOW_LEFT
    global CALIBRATED_WINDOW_TOP
    global CALIBRATED_WINDOW_WIDTH
    global CALIBRATED_WINDOW_HEIGHT
    global CALIBRATED_WINDOW_DPI

    if (
        CALIBRATED_WINDOW_LEFT = ""
        || CALIBRATED_WINDOW_TOP = ""
        || CALIBRATED_WINDOW_WIDTH = ""
        || CALIBRATED_WINDOW_HEIGHT = ""
    )
    {
        MsgBox(
            "CAPTURE BLOCKED - NO SAVED MAPLE WINDOW POSITION.`n`n"
            . "This calibration predates the Phase 12 position-safety check.`n`n"
            . "Run EquipmentBagCaptureCalibration.ahk once to record "
            . "the Maple window position and size used for calibration.`n`n"
            . "Capture will not continue with unknown window geometry.",
            APP_NAME,
            "Iconx"
        )
        return false
    }

    WinGetPos &currentLeft, &currentTop, &currentWidth, &currentHeight,
        "ahk_id " . MapleHwnd

    savedLeft := CALIBRATED_WINDOW_LEFT + 0
    savedTop := CALIBRATED_WINDOW_TOP + 0
    savedWidth := CALIBRATED_WINDOW_WIDTH + 0
    savedHeight := CALIBRATED_WINDOW_HEIGHT + 0

    if (
        currentLeft = savedLeft
        && currentTop = savedTop
        && currentWidth = savedWidth
        && currentHeight = savedHeight
    )
        return true

    answer := MsgBox(
        "MAPLE HAS MOVED SINCE CALIBRATION.`n`n"
        . "Saved capture position:`n"
        . "  Left=" . savedLeft . ", Top=" . savedTop . "`n"
        . "  Width=" . savedWidth . ", Height=" . savedHeight . "`n`n"
        . "Current Maple position:`n"
        . "  Left=" . currentLeft . ", Top=" . currentTop . "`n"
        . "  Width=" . currentWidth . ", Height=" . currentHeight . "`n`n"
        . "The capture uses absolute screen coordinates, so continuing "
        . "from this position is unsafe.`n`n"
        . "YES = reposition Maple to the calibrated position and re-check.`n"
        . "NO = cancel capture.",
        APP_NAME,
        "YesNo Icon!"
    )

    if answer != "Yes"
        return false

    if !RepositionMapleToCalibration()
    {
        MsgBox(
            "CAPTURE BLOCKED.`n`n"
            . "Maple could not be restored to the calibrated position.",
            APP_NAME,
            "Iconx"
        )
        return false
    }

    WinGetPos &currentLeft, &currentTop, &currentWidth, &currentHeight,
        "ahk_id " . MapleHwnd

    if (
        currentLeft != savedLeft
        || currentTop != savedTop
        || currentWidth != savedWidth
        || currentHeight != savedHeight
    )
    {
        MsgBox(
            "CAPTURE BLOCKED.`n`n"
            . "The reposition command ran, but Maple still does not exactly "
            . "match the saved calibration geometry.",
            APP_NAME,
            "Iconx"
        )
        return false
    }

    MsgBox(
        "Maple has been restored to the calibrated capture position.`n`n"
        . "Position safety check: PASS.",
        APP_NAME,
        "Iconi"
    )

    return true
}

RepositionMapleToCalibration()
{
    global MapleHwnd
    global CALIBRATED_WINDOW_LEFT
    global CALIBRATED_WINDOW_TOP
    global CALIBRATED_WINDOW_WIDTH
    global CALIBRATED_WINDOW_HEIGHT

    left := CALIBRATED_WINDOW_LEFT + 0
    top := CALIBRATED_WINDOW_TOP + 0
    width := CALIBRATED_WINDOW_WIDTH + 0
    height := CALIBRATED_WINDOW_HEIGHT + 0

    ; Restore first in case Maple is minimized/maximized.
    try DllCall("user32\ShowWindow", "Ptr", MapleHwnd, "Int", 9)

    ; Same Win32 method that successfully repositioned Maple in our manual test.
    flags := 0x0004 | 0x0010 | 0x0040  ; NOZORDER | NOACTIVATE | SHOWWINDOW

    result := DllCall(
        "user32\SetWindowPos",
        "Ptr", MapleHwnd,
        "Ptr", 0,
        "Int", left,
        "Int", top,
        "Int", width,
        "Int", height,
        "UInt", flags,
        "Int"
    )

    Sleep 500
    return result != 0
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
    global CALIBRATED_WINDOW_LEFT
    global CALIBRATED_WINDOW_TOP
    global CALIBRATED_WINDOW_WIDTH
    global CALIBRATED_WINDOW_HEIGHT

    MAPLE_TITLE := IniRead(CONFIG_FILE, "General", "WindowTitle")
    CALIBRATED_SCREEN_WIDTH := IniRead(CONFIG_FILE, "General", "ScreenWidth") + 0
    CALIBRATED_SCREEN_HEIGHT := IniRead(CONFIG_FILE, "General", "ScreenHeight") + 0

    ; Older calibration files do not contain window geometry. Treat them as
    ; unsafe until the Phase 12 calibration wrapper has recorded it.
    CALIBRATED_WINDOW_LEFT := IniRead(CONFIG_FILE, "General", "WindowLeft", "")
    CALIBRATED_WINDOW_TOP := IniRead(CONFIG_FILE, "General", "WindowTop", "")
    CALIBRATED_WINDOW_WIDTH := IniRead(CONFIG_FILE, "General", "WindowWidth", "")
    CALIBRATED_WINDOW_HEIGHT := IniRead(CONFIG_FILE, "General", "WindowHeight", "")

    CALIBRATED_WINDOW_DPI := IniRead(CONFIG_FILE, "General", "WindowDPI", "")
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

        ClickItemForCapture(GRID_X[column], GRID_Y[row], CompletedScreenshots + 1)

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

        ClickItemForCapture(GRID_X[column], GRID_Y[row], CompletedScreenshots + 1)

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

ClickItemForCapture(clickX, clickY, itemNumber)
{
    global PostMovementFirstItemPending

    if !PostMovementFirstItemPending
    {
        ReliableItemClick(clickX, clickY)
        return
    }

    ; POST-MOVEMENT FIX:
    ; The long-run CRC test showed one identical transition/non-equipment
    ; screenshot per movement. Do not alter the proven 576/577 drag or the
    ; normal 850 ms ShareX delay. Instead, give Maple a short extra settle,
    ; perform the normal reliable two-click selection, then confirm the same
    ; item once more before the normal pre-capture wait.
    LogRun(
        "POST-MOVE FIRST ITEM | item=" . itemNumber
        . " | extra settle/reclick starting"
    )

    Sleep 350
    ReliableItemClick(clickX, clickY)
    Sleep 450
    LowLevelClick(clickX, clickY)
    Sleep 300

    PostMovementFirstItemPending := false

    LogRun(
        "POST-MOVE FIRST ITEM | item=" . itemNumber
        . " | extra settle/reclick complete"
    )
}

MoveOnce()
{
    global APP_NAME
    global CompletedScreenshots
    global CompletedMovements
    global StopRequested
    global PostMovementFirstItemPending
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

    nextItem := CompletedScreenshots + 1

    LogRun(
        "BEFORE MOVEMENT | movement=" . movementNumber
        . " | next item=" . nextItem
        . " | screenshots=" . CompletedScreenshots
        . " | distance=" . movementDistance
    )

    PerformDrag(movementDistance)
    CompletedMovements += 1

    ; Arm a one-shot recovery sequence for the first item after this movement.
    PostMovementFirstItemPending := true

    LogRun(
        "AFTER MOVEMENT | movement=" . CompletedMovements
        . " | next item=" . nextItem
        . " | screenshots=" . CompletedScreenshots
        . " | post-move first-item fix=ARMED"
    )

    UpdateProgress("CAPTURE")

    ; Keep the proven movement settle unchanged.
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

InitRunLog(mode, nextItem, append := false)
{
    global RUN_LOG
    global RequestedItems
    global CompletedScreenshots
    global CompletedMovements
    global SHAREX_POST_CAPTURE_DELAY

    if !append
    {
        try FileDelete(RUN_LOG)
    }

    LogRun(
        "RUN START | mode=" . mode
        . " | requested=" . RequestedItems
        . " | completed screenshots=" . CompletedScreenshots
        . " | completed movements=" . CompletedMovements
        . " | next item=" . nextItem
        . " | ShareX wait=" . SHAREX_POST_CAPTURE_DELAY . " ms"
    )
}

LogRun(message)
{
    global RUN_LOG

    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    try FileAppend(timestamp . " | " . message . "`n", RUN_LOG, "UTF-8")
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
        . "Resume checkpoint cleared: Yes`n`n"
        . "Run log: " . RUN_LOG
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
