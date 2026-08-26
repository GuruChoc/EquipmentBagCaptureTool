#Requires AutoHotkey v2.0
#SingleInstance Force

SetTitleMatchMode 2

global APP_NAME := "Position Maple for Capture"
global CONFIG_FILE := A_ScriptDir . "\EquipmentBagCapture.ini"
global REPORT_DIR := "C:\MapleProjects\Downloads"
global REPORT_FILE := REPORT_DIR . "\Position_Maple_For_Capture_Report.txt"

DirCreate(REPORT_DIR)
try FileDelete(REPORT_FILE)

Log("Position Maple for Capture Report")
Log("=================================")
Log("")
Log("Started: " . FormatTime(, "yyyy-MM-dd HH:mm:ss"))
Log("")

if !FileExist(CONFIG_FILE)
    Fail("EquipmentBagCapture.ini was not found beside this helper.")

try
{
    left := IniRead(CONFIG_FILE, "General", "WindowLeft", "")
    top := IniRead(CONFIG_FILE, "General", "WindowTop", "")
    width := IniRead(CONFIG_FILE, "General", "WindowWidth", "")
    height := IniRead(CONFIG_FILE, "General", "WindowHeight", "")
}
catch as error
{
    Fail("Could not read calibration INI: " . error.Message)
}

if (left = "" || top = "" || width = "" || height = "")
    Fail(
        "The calibration INI does not contain saved Maple window geometry.`n"
        . "Run EquipmentBagCaptureCalibration_PHASE12.ahk first."
    )

mapleHwnd := WinExist("MapleIdleRPG")
if !mapleHwnd
    Fail("MapleIdleRPG window was not found. Start Maple first.")

WinGetPos &beforeLeft, &beforeTop, &beforeWidth, &beforeHeight,
    "ahk_id " . mapleHwnd

Log(
    "BEFORE: Left=" . beforeLeft
    . ", Top=" . beforeTop
    . ", Width=" . beforeWidth
    . ", Height=" . beforeHeight
)
Log(
    "TARGET: Left=" . left
    . ", Top=" . top
    . ", Width=" . width
    . ", Height=" . height
)

try DllCall("user32\ShowWindow", "Ptr", mapleHwnd, "Int", 9)
Sleep 250

flags := 0x0004 | 0x0010 | 0x0040

result := DllCall(
    "user32\SetWindowPos",
    "Ptr", mapleHwnd,
    "Ptr", 0,
    "Int", left + 0,
    "Int", top + 0,
    "Int", width + 0,
    "Int", height + 0,
    "UInt", flags,
    "Int"
)

Log("SetWindowPos returned: " . result)
Sleep 600

WinGetPos &afterLeft, &afterTop, &afterWidth, &afterHeight,
    "ahk_id " . mapleHwnd

Log(
    "AFTER:  Left=" . afterLeft
    . ", Top=" . afterTop
    . ", Width=" . afterWidth
    . ", Height=" . afterHeight
)

pass := (
    afterLeft = left + 0
    && afterTop = top + 0
    && afterWidth = width + 0
    && afterHeight = height + 0
)

if !pass
    Fail("Maple did not end at the exact saved calibration position.")

Log("PASS - Maple matches the saved calibration geometry exactly.")
Log("")
Log("Finished: " . FormatTime(, "yyyy-MM-dd HH:mm:ss"))

try Run('explorer.exe /select,"' . REPORT_FILE . '"')

MsgBox(
    "PASS - Maple restored to the saved capture position.`n`n"
    . "Left=" . afterLeft . ", Top=" . afterTop . "`n"
    . "Width=" . afterWidth . ", Height=" . afterHeight . "`n`n"
    . "Report:`n" . REPORT_FILE,
    APP_NAME,
    "Iconi"
)
ExitApp

Log(message)
{
    global REPORT_FILE
    try FileAppend(message . "`n", REPORT_FILE, "UTF-8")
}

Fail(message)
{
    global APP_NAME
    global REPORT_FILE

    Log("")
    Log("FAIL - " . StrReplace(message, "`n", " "))
    Log("")
    Log("Finished: " . FormatTime(, "yyyy-MM-dd HH:mm:ss"))

    try Run('explorer.exe /select,"' . REPORT_FILE . '"')

    MsgBox(
        "FAIL`n`n" . message . "`n`n"
        . "Report:`n" . REPORT_FILE,
        APP_NAME,
        "Iconx"
    )
    ExitApp
}
