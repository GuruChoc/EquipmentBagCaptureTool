#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Screen"

global APP_NAME := "Equipment Bag Capture Calibration"
global CONFIG_FILE := A_ScriptDir . "\EquipmentBagCapture.ini"

; Validated reference setup.
global REFERENCE_SCREEN_WIDTH := 2560
global REFERENCE_SCREEN_HEIGHT := 1440
global REFERENCE_X_PITCH := 131
global REFERENCE_Y_PITCH := 140
global POPUP_CLOSE_DX := 382
global POPUP_CLOSE_DY := -163
global REFERENCE_SCROLL_SHORT := 576
global REFERENCE_SCROLL_LONG := 577

; Human-friendly tolerance for the validated 2560x1440 layout.
; The Maple glove fingertip is several pixels wide, so two correct-looking
; clicks can differ by several pixels in opposite directions. These ranges
; intentionally absorb that hand-placement error instead of changing geometry.
global X_PITCH_MIN := 123
global X_PITCH_MAX := 139
global Y_PITCH_MIN := 132
global Y_PITCH_MAX := 148

SetTimer(StartCalibration, -250)

Esc::ExitApp

StartCalibration()
{
    global APP_NAME
    global CONFIG_FILE
    global REFERENCE_SCREEN_WIDTH
    global REFERENCE_SCREEN_HEIGHT
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

    ; Average same-row / same-column observations before measuring pitch.
    ; This reduces the effect of a single fat-finger placement error.
    measuredCol1X := Round((topLeftRef[1] + secondRowLeftRef[1]) / 2)
    measuredRow1Y := Round((topLeftRef[2] + topMiddleRef[2]) / 2)

    rawXSpacing := topMiddleRef[1] - measuredCol1X
    rawYSpacing := secondRowLeftRef[2] - measuredRow1Y

    if rawXSpacing < 40 || rawYSpacing < 40
    {
        MsgBox(
            "The recorded grid spacing is too small.`n`n"
            . "Run calibration again and place the glove fingertip "
            . "on the requested Lv. dots.",
            APP_NAME
        )
        ExitApp
    }

    xSpacing := rawXSpacing
    ySpacing := rawYSpacing
    xNormalized := false
    yNormalized := false

    referenceScreen := (
        A_ScreenWidth = REFERENCE_SCREEN_WIDTH
        && A_ScreenHeight = REFERENCE_SCREEN_HEIGHT
    )

    ; Use the validated geometry when the screen is the reference resolution
    ; and the measured pitch is inside a deliberately generous human-error band.
    if referenceScreen
        && rawXSpacing >= X_PITCH_MIN
        && rawXSpacing <= X_PITCH_MAX
    {
        xSpacing := REFERENCE_X_PITCH
        xNormalized := true
    }

    if referenceScreen
        && rawYSpacing >= Y_PITCH_MIN
        && rawYSpacing <= Y_PITCH_MAX
    {
        ySpacing := REFERENCE_Y_PITCH
        yNormalized := true
    }

    ; Rebuild consistent grid anchors from all three observations.
    ; Each captured point votes for where row 1 / column 1 should be.
    inferredX1FromMiddle := topMiddleRef[1] - xSpacing
    gridX1 := Round((
        topLeftRef[1]
        + secondRowLeftRef[1]
        + inferredX1FromMiddle
    ) / 3)
    gridX2 := gridX1 + xSpacing
    gridX3 := gridX1 + (xSpacing * 2)

    inferredY1FromSecondRow := secondRowLeftRef[2] - ySpacing
    gridY1 := Round((
        topLeftRef[2]
        + topMiddleRef[2]
        + inferredY1FromSecondRow
    ) / 3)
    gridY2 := gridY1 + ySpacing
    gridY3 := gridY1 + (ySpacing * 2)
    gridY4 := gridY1 + (ySpacing * 3)

    PopupPrepPrompt()

    popupLvRef := CaptureLvPoint(
        "Popup reference",
        "Lv. text INSIDE THE OPEN EQUIPMENT POPUP"
    )

    popupCloseX := popupLvRef[1] + Round(
        POPUP_CLOSE_DX * xSpacing / REFERENCE_X_PITCH
    )
    popupCloseY := popupLvRef[2] + Round(
        POPUP_CLOSE_DY * ySpacing / REFERENCE_Y_PITCH
    )

    dragStartX := gridX3
    dragStartY := gridY4 + ySpacing

    scrollShort := Round(
        REFERENCE_SCROLL_SHORT * ySpacing / REFERENCE_Y_PITCH
    )
    scrollLong := Round(
        REFERENCE_SCROLL_LONG * ySpacing / REFERENCE_Y_PITCH
    )

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
        . "Calibration points are averaged and small differences around the "
        . "validated layout are normalized automatically to reduce human-placement error.`n`n"
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
    introGui.AddText(
        "w560 Center",
        "Use the TIP OF THE MAPLE GLOVE FINGER on the DOT in"
    )
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
        . "You do NOT need to be pixel-perfect. Aim the glove fingertip at "
        . "the Lv. dot as consistently as you comfortably can. The wizard "
        . "averages the calibration points and absorbs normal hand-placement error.`n`n"
        . "Press Enter or click Continue."
    )

    continueBtn := introGui.AddButton(
        "Default w120 x220 y+12", "Continue"
    )
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
    prepGui.AddText(
        "w540 Center",
        "Open any equipment popup and LEAVE IT OPEN."
    )
    prepGui.AddText(
        "w540 Center y+10",
        "The next point is NOT the X close button."
    )
    prepGui.AddText(
        "w540 Center y+10",
        "Use the same glove-fingertip landmark on"
    )
    prepGui.SetFont("s28 Bold", "Segoe UI")
    prepGui.AddText("w540 Center y+2", "Lv.")
    prepGui.SetFont("s11", "Segoe UI")
    prepGui.AddText(
        "w540 Center y+6",
        "inside the equipment popup."
    )
    prepGui.AddText(
        "w540 Center y+10",
        "Press Enter or click Continue."
    )

    continueBtn := prepGui.AddButton(
        "Default w120 x210 y+14", "Continue"
    )
    continueBtn.OnEvent("Click", (*) => prepGui.Destroy())
    prepGui.OnEvent("Close", (*) => ExitApp())

    prepGui.Show("AutoSize Center")
    WinWaitClose("ahk_id " . prepGui.Hwnd)
}

CaptureLvPoint(pointName, targetDescription)
{
    global APP_NAME

    instructionGui := Gui(
        "+AlwaysOnTop",
        APP_NAME . " - " . pointName
    )
    instructionGui.SetFont("s11", "Segoe UI")
    instructionGui.AddText(
        "w520 Center",
        "Place the TIP OF THE GLOVE FINGER directly on the DOT in"
    )
    instructionGui.SetFont("s30 Bold", "Segoe UI")
    instructionGui.AddText("w520 Center y+2", "Lv.")
    instructionGui.SetFont("s11", "Segoe UI")
    instructionGui.AddText(
        "w520 Center y+8",
        targetDescription
    )
    instructionGui.AddText(
        "w520 Center y+14",
        "Press Enter or click Continue to close this window."
    )
    instructionGui.AddText(
        "w520 Center y+6",
        "Then move the glove into position and press T."
    )
    instructionGui.AddText(
        "w520 Center y+6",
        "Close enough is fine; the calibration averages normal hand wobble."
    )
    instructionGui.AddText(
        "w520 Center y+6",
        "Press Esc to cancel."
    )

    continueBtn := instructionGui.AddButton(
        "Default w120 x200 y+14", "Continue"
    )
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
