# Equipment Bag Capture Tool

**Current release: v1.0.4**

Equipment Bag Capture Tool automates screenshot capture of equipment detail popups in the MapleStory: Idle RPG PC client using AutoHotkey v2 and ShareX.

It works with the equipment bag displayed as a **3-column x 4-row grid** and processes items left-to-right, top-to-bottom. It automatically moves the bag after each group of 12 items and handles incomplete final screens clamped to the bottom of the list.

## Important warning

This tool sends automated mouse and keyboard input to the game client. It does not modify the game, read game memory, bypass security, or communicate with Nexon's servers directly. Automated input may still be restricted by Nexon's current rules. Check the current rules yourself before using or distributing the tool. Use is at your own risk.

## Requirements

- Windows 10 64-bit or Windows 11
- MapleStory: Idle RPG PC client
- AutoHotkey v2
- ShareX
- Fixed Maple window position, size and Windows display scaling while capturing

Useful official sources:

- MapleStory: Idle RPG: https://forum.nexon.com/maplestoryidle/main
- AutoHotkey releases: https://github.com/AutoHotkey/AutoHotkey/releases
- ShareX: https://getsharex.com/

Optional installation through Windows Package Manager:

```powershell
winget install --id AutoHotkey.AutoHotkey --exact
winget install --id ShareX.ShareX --exact
```

## Files

- `EquipmentBagCaptureTool.ahk` — main capture script
- `EquipmentBagCaptureCalibration.ahk` — coordinate calibration wizard
- `Position_Maple_For_Capture.ahk` — restores Maple to the window geometry saved during calibration
- `Check_Screenshot_Folder_CRC.bat` — optional post-run screenshot count and CRC32 duplicate checker
- `EquipmentBagCapture.ini` — generated local calibration file
- `EquipmentBagCaptureCheckpoint.ini` — generated local safe-stop/resume checkpoint

Both INI files are deliberately excluded from the repository because they contain local runtime state specific to one PC/run.

## 1. Prepare ShareX

1. Open ShareX.
2. Set `Ctrl+Shift+Z` to capture the same saved region each time. In current ShareX versions this is typically **Capture last region**.
3. Open one equipment details popup in Maple.
4. Manually capture the full popup region once.
5. Confirm the screenshot saves automatically to the intended folder.
6. Make sure the captured popup includes the equipment name, level, lock state, main stats, all substats and the complete bottom stat line.
7. Avoid ShareX actions that open an editor, confirmation window or upload dialog. The script expects silent saving.

Before a real run, empty or change the destination folder so old screenshots cannot be mixed with the new batch.

## 2. Open the correct equipment-bag view

1. Open MapleStory: Idle RPG.
2. Open the **hamburger menu**.
3. Select **Preset**.
4. Go to **Chapter → Chapter Hunt**.
5. Click **Edit Preset**.
6. In the **Manage Equipment** box, click the symbol in the **bottom-right corner**.
7. Confirm that the equipment bag is displayed as a **3-column grid**.
8. Select the equipment category you want to capture.
9. Put the equipment list at the absolute top.

The tool is designed specifically for this view.

## 3. Calibrate

Double-click `EquipmentBagCaptureCalibration.ahk` and follow the prompts.

The calibration uses one repeatable landmark throughout: place the **tip of the Maple glove cursor finger directly on the dot in `Lv.`**.

The wizard records:

- top-left equipment item `Lv.` dot
- top-middle equipment item `Lv.` dot
- second-row left equipment item `Lv.` dot
- `Lv.` dot inside an open equipment popup

The calibration prompts display a large bold **`Lv.`** target. Press **Enter** or click **Continue** to close each instruction window, then position the glove and press **T** to record the point.

### Human-friendly calibration tolerance

The calibration is deliberately designed so users do **not** have to be perfectly accurate to a single pixel every time.

The validated layout uses approximately:

- horizontal pitch: **131 px**
- vertical pitch: **140 px**

Small hand-placement differences are automatically normalized. Measurements around the validated layout are treated as the known-good geometry so tiny human placement variation does not change the scrolling maths.

The popup-close position is calculated from the popup `Lv.` landmark, so the user no longer has to manually target the popup X during calibration.

Recalibrate whenever resolution, Windows display scaling, Maple window size, Maple window position or the relevant game layout changes.

## 4. Scrolling behaviour

The mouse-down point is the calculated **row 5 / column 3 `Lv.` position**: one effective row pitch below the fourth visible row.

On the validated 140 px layout, repeated tests found the stable scrolling sweet spot at **576 and 577 px**, alternating on successive movements:

`576, 577, 576, 577, ...`

This averages **576.5 px** over an even number of movements and reduces cumulative drift across long equipment bags.

The movement routine remains the proven single held drag:

- move to the row-5 grab point
- mouse button down
- stepped upward movement
- mouse button up
- wait 800 ms for Maple to settle

At the bottom of a list Maple may elastically bounce back slightly when there is no more content to scroll. The capture tool never performs an unnecessary movement after the final batch. On an incomplete final screen it captures the new items from the bottom rows after Maple settles.

## 5. Faster capture in v1.0.2

The ShareX post-capture wait has been reduced from **1400 ms to 850 ms**. The two-click item selection, popup handling, calibration and equipment-list scrolling remain unchanged.

The 850 ms timing was validated with:

- **242 requested items** → 242 screenshot commands and 20 movements completed
- **201 requested items** → 201 screenshot commands and 16 movements completed with mouse-movement lock enabled
- file-level verification of that 201-item run → **201 PNG files and 0 duplicate CRC32 groups**

The shorter delay saves significant time on large bags without changing the proven click/scroll mechanics.

## 6. Mouse-movement lock, safe Esc stop and F9 resume

During capture, physical mouse movement is locked so an accidental mouse movement cannot pull the pointer away from the scripted coordinates. The script's own mouse movement and clicks continue normally.

Do not deliberately click the mouse or use other keyboard keys while a capture is running.

### Safe stop

Press **Esc** if you need to stop. The tool:

- safely stops at the current checkpoint
- unlocks physical mouse movement
- reports screenshot commands completed
- reports movements completed
- reports the next item number
- records whether the last equipment popup is still open
- saves the checkpoint to `EquipmentBagCaptureCheckpoint.ini`
- closes the script after you dismiss the report

### Resume

After pressing Esc:

1. **Do not move or scroll the Maple equipment bag.**
2. Do not manually close the equipment popup left by the safe stop.
3. Leave the same equipment category selected.
4. Restart `EquipmentBagCaptureTool.ahk`.
5. The startup message will show the saved checkpoint.
6. Press **F9**.
7. Confirm the resume details.
8. Leave the mouse and keyboard alone while the capture continues.

The tool resumes from the saved next item, continues the existing movement sequence and clears `EquipmentBagCaptureCheckpoint.ini` after a successful completion.

If you press **F8** while a checkpoint exists, the tool warns that starting a new capture will delete the saved checkpoint and asks for confirmation first.

Resume depends on Maple still being at the same equipment category and scroll position left by the safe stop. If that state has changed, do not resume; start a clean capture from the absolute top instead.

## 7. Test before a full run

After calibrating, use a small category first.

1. Start ShareX.
2. Start `EquipmentBagCaptureTool.ahk`.
3. Put the equipment list at the absolute top.
4. Press `F8` and enter `12` to confirm item clicking and ShareX capture.
5. Reset the list to the absolute top.
6. Run a multi-screen test such as `36` items and check for duplicates or skipped items.
7. For a resume test, press `Esc` partway through a multi-screen run, leave Maple untouched, restart the script and press `F9`.

## 8. Capture a full equipment bag

1. Start ShareX and confirm its save folder.
2. Start `EquipmentBagCaptureTool.ahk`.
3. Open the required equipment category in the correct 3-column bag view.
4. Count the exact number of equipment items in the category.
5. Put the list at the absolute top.
6. Close any open equipment popup.
7. Press `F8`.
8. Enter the exact item count.
9. Read the summary and press **OK**.
10. Leave the mouse and keyboard alone until the completion message appears, unless you need to press **Esc** to stop safely.

A live counter in the top-left corner shows captured items and movement progress.

## Proven capture behaviour

The capture side retains the behaviour from the successful `MapleRingTest.ahk` testing:

- each equipment item is clicked **twice**, with a pause between clicks
- ShareX is triggered with `SendEvent "^+z"`
- list movement uses a **single held drag**
- the script waits **800 ms after each movement** before continuing

Validation history includes:

- **36-item** multi-screen test
- **134-item** full capture requiring **11 movements**
- **300+ item** full-bag stress test for long-run scrolling and cumulative drift
- earlier successful **249-item** capture with **20 movements**
- v1.0.2 faster-timing **242-item** test with **20 movements**
- v1.0.2 input-lock **201-item** test with **16 movements** and **0 duplicate CRC32 groups**
- v1.0.2 persistent resume test: stopped after item **19**, saved item **20** as the next checkpoint, closed/reopened the script, resumed with `F9`, and finished **36/36 screenshots with 2/2 movements**
- combined stop/resume output verification: **36 PNG files and 0 duplicate CRC32 groups**

## Verify a completed screenshot folder

For an important capture, run `Check_Screenshot_Folder_CRC.bat` and enter the screenshot folder path.

It creates `Screenshot_Check_Report_CRC.txt` containing:

- PNG/JPG/JPEG counts
- chronological image list
- file sizes
- CRC32 for every image
- groups of exact duplicate CRC32 values, if any

CRC32 is useful for identifying byte-for-byte duplicate screenshots. Different CRC32 values do not prove the screenshots show different equipment, so visual/OCR validation may still be useful for critical runs.

## What the completion report proves

The completion report confirms only:

- number of screenshot hotkey commands sent
- number of movement commands performed

It cannot prove that ShareX saved every image or that every in-game click was accepted. After an important capture, check the output file count and optionally run the CRC checker.

## Troubleshooting

### AutoHotkey reports a version error

Install AutoHotkey v2. The scripts are not compatible with AutoHotkey v1.

### ShareX is not running

Start ShareX before pressing `F8` or `F9`.

### No screenshots are saved

- manually press `Ctrl+Shift+Z` and confirm ShareX saves one image
- check that ShareX is using the saved/last-region capture
- check the destination folder
- disable editing/confirmation steps that interrupt automatic saving

### The pointer clicks beside an item

- restore Maple to the calibrated position and size
- restore the calibrated resolution/display scaling
- rerun calibration
- aim carefully at the requested `Lv.` dots; small human placement variation is normalized automatically

### Movement is wrong

- make sure the list was at the absolute top during calibration and at the start of a new run
- recalibrate after any resolution, scaling, Maple window size or position change
- on the validated layout, movement should remain **576 / 577 px**
- test a small multi-screen category before a full bag

### I pressed Esc

Esc safely stops the run, unlocks mouse movement, saves the resume checkpoint and displays the next item number. Leave Maple untouched, restart the same AHK and press **F9** to resume.

### F9 says there is no checkpoint

A successful completion clears the checkpoint automatically. A new F8 capture also deletes an old checkpoint after confirmation. If the checkpoint is gone, reset the bag to the absolute top and start a new capture.

### I moved or scrolled Maple after pressing Esc

Do not use F9 resume from a changed game state. Reset the bag to the absolute top and start a new F8 capture instead.

### A screenshot is duplicated

The game may not have accepted an equipment selection before ShareX captured the popup. Treat the batch as incomplete and rerun it. `Check_Screenshot_Folder_CRC.bat` can identify exact duplicate image files.

## Known limitations

- Windows only
- coordinate-based automation depends on stable window placement/scaling
- assumes a 3-column x 4-row equipment capture grid
- uses ShareX `Ctrl+Shift+Z`
- physical mouse movement is locked during capture, but users should still avoid clicking or other keyboard input
- resume requires the same Maple equipment category and scroll position to remain unchanged after safe stop
- does not inspect screenshot contents while running
- does not perform OCR or analyse equipment

## License

MIT License.

This is an unofficial community utility and is not affiliated with Nexon.

## Position safety

Calibration records the exact Maple window position and size used for coordinate calibration. Before both a new F8 capture and an F9 resume, the Capture Tool compares the current Maple window geometry with those saved values.

If Maple has moved or been resized, capture is blocked from blindly continuing. The warning can restore Maple to the saved calibrated position and then re-check the geometry before capture continues.

`Position_Maple_For_Capture.ahk` provides the same restore action as a standalone helper and verifies the before/after geometry.

## Current capture behaviour

- ShareX post-capture wait remains **850 ms**.
- Equipment-list movement remains the validated alternating **576 / 577 px**.
- Physical mouse-movement lock remains enabled during capture.
- The live capture/movement counter remains enabled.
- `Esc` performs the safe-stop/checkpoint path.
- `F9` resumes a saved checkpoint.
- The first item after each movement uses the validated post-movement settle/reclick sequence before ShareX capture.

## Display scaling / DPI safety

Calibration records the Maple window DPI used for the saved absolute screen
coordinates. Capture is blocked if Windows display scaling/DPI later differs
from calibration. The tool deliberately does not mathematically rescale the
tested coordinates; recalibrate after changing display scaling.
