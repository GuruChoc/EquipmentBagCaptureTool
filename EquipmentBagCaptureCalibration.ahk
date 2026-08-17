#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Screen"

global APP_NAME := "Equipment Bag Capture Calibration"
global CONFIG_FILE := A_ScriptDir . "\EquipmentBagCapture.ini"

; Validated reference setup.
global REFERENCE_X_PITCH := 131
global REFERENCE_Y_PITCH := 140
global POPUP_CLOSE_DX := 382
global POPUP_CLOSE_DY := -163
global REFERENCE_SCROLL_SHORT := 576
global REFERENCE_SCROLL_LONG := 577

; Human-friendly tolerance. A calibration click can easily be a pixel or two
; off even when the user is aiming at the correct Lv. dot. Measurements inside
; these ranges are treated as the validated reference geometry instead of
; changing capture/scroll behaviour because of tiny hand-placement variation.
global X_PITCH_MIN := 129
global X_PITCH_MAX := 133
global Y_PITCH_MIN := 138
global Y_PITCH_MAX := 142

SetTimer(StartCalibration, -250)

Esc::ExitApp

StartCalibration()
{
    global APP_NAME
    global CONFIG_FILE
    global REFERENCE_X_PITCH
    global REFERENCE_Y_PITCH
    global POPUP_CLOSE_DX
    global POPUP_CLOSE_DY
    global REFERENCE_SCROLL_SHORT
    global REFERENCE_SCROLL_LONG
    global X_PITCH_MIN
    global X_PITCH_MAX
    global Y_PITCH_MIN
    global Y_PITCH_MAX

    IntroPrompt()

    topLeftRef := CaptureLvPoint(
        "Grid reference 1 of 3",
        "TOP-LEFT equipment item"
    )

    topMiddleRef := CaptureLvPoint(
        "Grid reference 2 of 3",
        "TOP-MIDDLE equipment item"
    )

    secondRowLeftRef := CaptureLvPoint(
        "Grid reference 3 of 3",
        "LEFT equipment item in the SECOND ROW"
    )

    rawXSpacing := topMiddleRef[1] - topLeftRef[1]
    rawYSpacing := secondRowLeftRef[2] - topLeftRef[2]

    if rawXSpacing < 40 || rawYSpacing < 40
    {
        MsgBox(
            "The recorded grid spacing is too small.`n`n"
            . "Run calibration again and place the glove fingertip "
            . "directly on the requested Lv. dots.",
            APP_NAME
        )
        ExitApp
    }

    xSpacing := rawXSpacing
    ySpacing := rawYSpacing
    xNormalized := false
    yNormalized := false

    if rawXSpacing >= X_PITCH_MIN && rawXSpacing <= X_PITCH_MAX
    {
        xSpacing := REFERENCE_X_PITCH
        xNormalized := true
    }

    if rawYSpacing >= Y_PITCH_MIN && rawYSpacing <= Y_PITCH_MAX
    {
        ySpacing := REFERENCE_Y_PITCH
        yNormalized := true
    }

    gridX1 := topLeftRef[1]
    gridX2 := topMiddleRef[1]
    gridX3 := gridX2 + xSpacing

    gridY1 := topLeftRef[2]
    gridY2 := secondRowLeftRef[2]
    gridY3 := gridY2 + ySpacing
    gridY4 := gridY3 + ySpacing

    PopupPrepPrompt()

    popupLvRef := CaptureLvPoint(
        "Popup reference",
        "Lv. text INSIDE THE OPEN EQUIPMENT POPUP"
    )

    popupCloseX := popupLvRef[1] + Round(POPUP_CLOSE_DX * xSpacing / REFERENCE_X_PITCH)
    popupCloseY := popupLvRef[2] + Round(POPUP_CLOSE_DY * ySpacing / REFERENCE_Y_PITCH)

    dragStartX := gridX3
    dragStartY := gridY4 + ySpacing

    scrollShort := Round(REFERENCE_SCROLL_SHORT * ySpacing / REFERENCE_Y_PITCH)
    scrollLong := Round(REFERENCE_SCROLL_LONG * ySpacing / REFERENCE_Y_PITCH)

    IniWrite("MapleIdleRPG", CONFIG_FILE, "General", "WindowTitle")
    IniWrite(A_ScreenWidth, CONFIG_FILE, "General", "ScreenWidth")
    IniWrite(A_ScreenHeight, CONFIG_FILE, "General", "ScreenHeight")

    IniWrite(gridX1, CONFIG_FILE, "Grid", "X1")
    IniWrite(gridX2, CONFIG_FILE, "Grid", "X2")
    IniWrite(gridX3, CONFIG_FILE, "Grid", "X3")
    IniWrite(gridY1, CONFIG_FILE, "Grid", "Y1")
    IniWrite(gridY2, CONFIG_FILE, "Grid", "Y2")
    IniWrite(gridY3, CONFIG_FILE, "Grid", "Y3")
    IniWrite(gridY4, CONFIG_FILE, "Grid", "Y4")
    IniWrite(rawXSpacing, CONFIG_FILE, "Grid", "RawXSpacing")
    IniWrite(rawYSpacing, CONFIG_FILE, "Grid", "RawYSpacing")
    IniWrite(xSpacing, CONFIG_FILE, "Grid", "EffectiveXSpacing")
    IniWrite(ySpacing, CONFIG_FILE, "Grid", "EffectiveYSpacing")

    IniWrite(popupLvRef[1], CONFIG_FILE, "Popup", "LvRefX")
    IniWrite(popupLvRef[2], CONFIG_FILE, "Popup", "LvRefY")
    IniWrite(popupCloseX, CONFIG_FILE, "Popup", "CloseX")
    IniWrite(popupCloseY, CONFIG_FILE, "Popup", "CloseY")

    IniWrite(dragStartX, CONFIG_FILE, "Movement", "StartX")
    IniWrite(dragStartY, CONFIG_FILE, "Movement", "StartY")
    IniWrite(scrollShort, CONFIG_FILE, "Movement", "ShortDistance")
    IniWrite(scrollLong, CONFIG_FILE, "Movement", "LongDistance")
    IniWrite(36, CONFIG_FILE, "Movement", "Steps")
    IniWrite(20, CONFIG_FILE, "Movement", "StepDelay")
    IniWrite(700, CONFIG_FILE, "Movement", "HoldDelay")

    IniWrite(dragStartX, CONFIG_FILE, "Movement", "EndX")
    IniWrite(dragStartY - scrollShort, CONFIG_FILE, "Movement", "EndY")

    xNote := xNormalized
        ? rawXSpacing . " px measured -> normalized to " . xSpacing . " px"
        : rawXSpacing . " px measured -> used as measured"

    yNote := yNormalized
        ? rawYSpacing . " px measured -> normalized to " . ySpacing . " px"
        : rawYSpacing . " px measured -> used as measured"

    summary := (
        "Calibration saved successfully.`n`n"
        . "Horizontal pitch: " . xNote . "`n"
        . "Vertical pitch: " . yNote . "`n`n"
        . "Grid reference columns: "
        . gridX1 . ", " . gridX2 . ", " . gridX3 . "`n"
        . "Grid reference rows: "
        . gridY1 . ", " . gridY2 . ", "
        . gridY3 . ", " . gridY4 . "`n`n"
        . "Popup Lv. reference: "
        . popupLvRef[1] . ", " . popupLvRef[2] . "`n"
        . "Calculated popup close: "
        . popupCloseX . ", " . popupCloseY . "`n`n"
        . "Calculated row-5 grab point: "
        . dragStartX . ", " . dragStartY . "`n"
        . "Alternating movement distances: "
        . scrollShort . " / " . scrollLong . " px`n"
        . "Average movement: "
        . Round((scrollShort + scrollLong) / 2, 3) . " px`n`n"
        . "Configuration file:`n"
        . CONFIG_FILE . "`n`n"
        . "Small calibration differences around the validated layout are "
        . "normalized automatically to reduce human-placement error.`n`n"
        . "Run EquipmentBagCaptureTool.ahk and perform a small multi-screen "
        . "test before a full bag."
    )

    A_Clipboard := summary

    MsgBox(
        summary
        . "`n`nThe summary has been copied to the clipboard."
        . "`n`nPress Enter or click OK to close this calibration script.",
        APP_NAME
    )

    ExitApp
}

IntroPrompt()
{
    global APP_NAME

    introGui := Gui("+AlwaysOnTop", APP_NAME)
    introGui.SetFont("s11", "Segoe UI")
    introGui.AddText("w560 Center", "Use the TIP OF THE MAPLE GLOVE FINGER on the DOT in")
    introGui.SetFont("s30 Bold", "Segoe UI")
    introGui.AddText("w560 Center y+2", "Lv.")
    introGui.SetFont("s10", "Segoe UI")
    introGui.AddText(
        "w560 y+12",
        "Before continuing:`n"
        . "• Open MapleStory: Idle RPG.`n"
        . "• Open Preset → Chapter → Chapter Hunt → Edit Preset.`n"
        . "• Open the 3-column equipment bag.`n"
        . "• Select a category with at least 6 items.`n"
        . "• Put the equipment list at the absolute top.`n"
        . "• Keep Maple in the exact position and size you will use later.`n`n"
        . "You do not need to be pixel-perfect. Aim carefully at the Lv. dot; "
        . "small 1-2 pixel pitch differences are normalized automatically.`n`n"
        . "Press Enter or click Continue."
    )

    continueBtn := introGui.AddButton("Default w120 x220 y+12", "Continue")
    continueBtn.OnEvent("Click", (*) => introGui.Destroy())
    introGui.OnEvent("Close", (*) => ExitApp())

    introGui.Show("AutoSize Center")
    WinWaitClose("ahk_id " . introGui.Hwnd)
}

PopupPrepPrompt()
{
    global APP_NAME

    prepGui := Gui("+AlwaysOnTop", APP_NAME . " - Popup reference")
    prepGui.SetFont("s11", "Segoe UI")
    prepGui.AddText("w540 Center", "Open any equipment popup and LEAVE IT OPEN.")
    prepGui.AddText("w540 Center y+10", "The next point is NOT the X close button.")
    prepGui.AddText("w540 Center y+10", "Use the same glove-fingertip landmark on")
    prepGui.SetFont("s28 Bold", "Segoe UI")
    prepGui.AddText("w540 Center y+2", "Lv.")
    prepGui.SetFont("s11", "Segoe UI")
    prepGui.AddText("w540 Center y+6", "inside the equipment popup.")
    prepGui.AddText("w540 Center y+10", "Press Enter or click Continue.")

    continueBtn := prepGui.AddButton("Default w120 x210 y+14", "Continue")
    continueBtn.OnEvent("Click", (*) => prepGui.Destroy())
    prepGui.OnEvent("Close", (*) => ExitApp())

    prepGui.Show("AutoSize Center")
    WinWaitClose("ahk_id " . prepGui.Hwnd)
}

CaptureLvPoint(pointName, targetDescription)
{
    global APP_NAME

    instructionGui := Gui("+AlwaysOnTop", APP_NAME . " - " . pointName)
    instructionGui.SetFont("s11", "Segoe UI")
    instructionGui.AddText(
        "w520 Center",
        "Place the TIP OF THE GLOVE FINGER directly on the DOT in"
    )
    instructionGui.SetFont("s30 Bold", "Segoe UI")
    instructionGui.AddText("w520 Center y+2", "Lv.")
    instructionGui.SetFont("s11", "Segoe UI")
    instructionGui.AddText("w520 Center y+8", targetDescription)
    instructionGui.AddText(
        "w520 Center y+14",
        "Press Enter or click Continue to close this window."
    )
    instructionGui.AddText(
        "w520 Center y+6",
        "Then move the glove into position and press T."
    )
    instructionGui.AddText("w520 Center y+6", "Press Esc to cancel.")

    continueBtn := instructionGui.AddButton("Default w120 x200 y+14", "Continue")
    continueBtn.OnEvent("Click", (*) => instructionGui.Destroy())
    instructionGui.OnEvent("Close", (*) => ExitApp())

    instructionGui.Show("AutoSize Center")
    WinWaitClose("ahk_id " . instructionGui.Hwnd)

    ToolTip(
        pointName . "`n"
        . targetDescription . "`n"
        . "Put the glove fingertip on the Lv. dot and press T.",
        20,
        20
    )

    KeyWait "t"
    KeyWait "t", "D"

    MouseGetPos &pointX, &pointY

    KeyWait "t"
    ToolTip

    Sleep 200

    return [pointX, pointY]
}
