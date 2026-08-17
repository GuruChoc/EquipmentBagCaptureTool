#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Screen"

global APP_NAME := "Equipment Bag Capture Calibration"
global CONFIG_FILE := A_ScriptDir . "\EquipmentBagCapture.ini"

SetTimer(StartCalibration, -250)

Esc::ExitApp

StartCalibration()
{
    global APP_NAME
    global CONFIG_FILE

    answer := MsgBox(
        "This wizard records the screen positions used by the "
        . "Equipment Bag Capture Tool.`n`n"
        . "Before continuing:`n"
        . "• Open the MapleStory: Idle RPG PC client.`n"
        . "• Open the hamburger menu → Preset.`n"
        . "• Go to Chapter → Chapter Hunt.`n"
        . "• Click Edit Preset.`n"
        . "• In Manage Equipment, click the symbol in the bottom-right corner.`n"
        . "• Confirm the equipment bag is shown in 3 columns.`n"
        . "• Select an equipment category with at least 15 items.`n"
        . "• Put the equipment list at the absolute top.`n"
        . "• Keep Maple in the position and size you will use later.`n`n"
        . "For each point, move the mouse to the requested position "
        . "and press T.`n`n"
        . "Press Esc at any time to cancel.",
        APP_NAME,
        "OKCancel Icon!"
    )

    if answer != "OK"
        ExitApp

    topLeft := CapturePoint(
        "Grid point 1 of 3",
        "Place the mouse in the CENTRE of the top-left equipment item."
    )

    topMiddle := CapturePoint(
        "Grid point 2 of 3",
        "Place the mouse in the CENTRE of the top-middle equipment item."
    )

    secondRowLeft := CapturePoint(
        "Grid point 3 of 3",
        "Place the mouse in the CENTRE of the left equipment item "
        . "in the second row."
    )

    xSpacing := topMiddle[1] - topLeft[1]
    ySpacing := secondRowLeft[2] - topLeft[2]

    if xSpacing < 40 || ySpacing < 40
    {
        MsgBox(
            "The recorded grid spacing is too small.`n`n"
            . "Run calibration again and select the centres of "
            . "the requested equipment items.",
            APP_NAME
        )
        ExitApp
    }

    gridX1 := topLeft[1]
    gridX2 := topMiddle[1]
    gridX3 := gridX2 + xSpacing

    gridY1 := topLeft[2]
    gridY2 := secondRowLeft[2]
    gridY3 := gridY2 + ySpacing
    gridY4 := gridY3 + ySpacing

    popupClose := CapturePoint(
        "Equipment popup close button",
        "First, manually click any equipment item so its details popup opens.`n`n"
        . "Then place the mouse in the CENTRE of the popup's X close button."
    )

    topRightLock := CapturePoint(
        "Top-right padlock",
        "First, manually close the equipment popup and make sure the list "
        . "is still at the absolute top.`n`n"
        . "Place the mouse in the CENTRE of the padlock on the TOP-RIGHT "
        . "equipment tile.`n`n"
        . "The padlock may be red or black."
    )

    bottomRightLock := CapturePoint(
        "Bottom-right / 15th-item padlock",
        "Place the mouse in the CENTRE of the padlock on the BOTTOM-RIGHT "
        . "equipment tile (the 15th item).`n`n"
        . "The padlock may be red or black.`n"
        . "Do not drag the list. Only position the pointer and press T."
    )

    dragStart := bottomRightLock
    dragEnd := topRightLock

    if dragEnd[2] >= dragStart[2]
    {
        MsgBox(
            "The top-right padlock must be above the bottom-right padlock.`n`n"
            . "No configuration was saved. Run calibration again.",
            APP_NAME
        )
        ExitApp
    }

    movementDistance := dragStart[2] - dragEnd[2]

    if movementDistance < (ySpacing * 3)
    {
        MsgBox(
            "The measured padlock distance looks too small.`n`n"
            . "Top-right and bottom-right padlocks should be about four "
            . "equipment rows apart.`n`n"
            . "No configuration was saved. Run calibration again.",
            APP_NAME
        )
        ExitApp
    }

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

    IniWrite(popupClose[1], CONFIG_FILE, "Popup", "CloseX")
    IniWrite(popupClose[2], CONFIG_FILE, "Popup", "CloseY")

    IniWrite(dragStart[1], CONFIG_FILE, "Movement", "StartX")
    IniWrite(dragStart[2], CONFIG_FILE, "Movement", "StartY")
    IniWrite(dragEnd[1], CONFIG_FILE, "Movement", "EndX")
    IniWrite(dragEnd[2], CONFIG_FILE, "Movement", "EndY")
    IniWrite(36, CONFIG_FILE, "Movement", "Steps")
    IniWrite(20, CONFIG_FILE, "Movement", "StepDelay")
    IniWrite(700, CONFIG_FILE, "Movement", "HoldDelay")

    summary := (
        "Calibration saved successfully.`n`n"
        . "Grid columns: "
        . gridX1 . ", " . gridX2 . ", " . gridX3 . "`n"
        . "Grid rows: "
        . gridY1 . ", " . gridY2 . ", "
        . gridY3 . ", " . gridY4 . "`n"
        . "Popup close: "
        . popupClose[1] . ", " . popupClose[2] . "`n"
        . "Top-right padlock: "
        . topRightLock[1] . ", " . topRightLock[2] . "`n"
        . "Bottom-right padlock: "
        . bottomRightLock[1] . ", " . bottomRightLock[2] . "`n"
        . "Calculated drag: "
        . dragStart[1] . ", " . dragStart[2]
        . " to " . dragEnd[1] . ", " . dragEnd[2] . "`n"
        . "Movement distance: " . movementDistance . " px`n`n"
        . "Configuration file:`n"
        . CONFIG_FILE . "`n`n"
        . "Run EquipmentBagCaptureTool.ahk and perform a 12-item test first."
    )

    A_Clipboard := summary

    MsgBox(
        summary
        . "`n`nThe summary has been copied to the clipboard."
        . "`n`nPress Enter (or click OK) to close this window before performing any other tasks.",
        APP_NAME
    )

    ExitApp
}

CapturePoint(pointName, instructions)
{
    global APP_NAME

    MsgBox(
        instructions . "`n`n"
        . "After closing this message, press T to record the point.",
        APP_NAME . " - " . pointName
    )

    ToolTip(
        pointName . "`n"
        . "Move the pointer into position and press T.`n"
        . "Press Esc to cancel.",
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
