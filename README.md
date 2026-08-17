# Equipment Bag Capture Tool

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
- `EquipmentBagCapture.ini` — generated local calibration file

`EquipmentBagCapture.ini` is deliberately excluded from this repository because its coordinates are specific to one PC/setup.

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
7. Confirm the equipment bag is displayed as a **3-column grid**.
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

Small hand-placement differences are automatically normalized:

- measured horizontal pitch from **129 to 133 px** is treated as **131 px**
- measured vertical pitch from **138 to 142 px** is treated as **140 px**

So a user measuring 139 px on one calibration and 140 px on the next does not suddenly get different scrolling behaviour. The raw measurement and the effective normalized measurement are both stored in the local INI for troubleshooting.

If the measured pitch is clearly outside those tolerance ranges, the tool assumes the layout, resolution or scaling is genuinely different and uses/scales from the actual measured pitch instead.

The popup-close position is calculated from the popup `Lv.` landmark, so the user no longer has to manually target the popup X during calibration.

Recalibrate whenever resolution, Windows display scaling, Maple window size, Maple window position or the relevant game layout changes.

## 4. Scrolling behaviour

The mouse-down point is the calculated **row 5 / column 3 `Lv.` position**: one effective row pitch below the fourth visible row.

Testing showed that a geometric four-row drag was slightly short because Maple does not translate mouse travel into list movement perfectly one-for-one. On the validated 140 px layout, repeated tests found the stable sweet spot at **576 and 577 px**, alternating on successive movements:

`576, 577, 576, 577, ...`

This averages **576.5 px** over an even number of movements and reduces cumulative drift across long equipment bags.

Because the calibration now normalizes small 1-2 pixel human variation around the validated 140 px row pitch, measurements such as 138, 139, 140, 141 or 142 px all retain the proven literal **576 / 577 px** movement pattern. The distances are scaled only when the measured layout is clearly different from the validated geometry.

The movement routine itself remains the proven single held drag:

- move to the row-5 grab point
- mouse button down
- stepped upward movement
- mouse button up
- wait 800 ms for Maple to settle

At the bottom of a list Maple may elastically bounce back slightly when there is no more content to scroll. The capture tool never performs an unnecessary movement after the final batch. On an incomplete final screen it captures the new items from the bottom rows after Maple settles.

## 5. Test before a full run

After calibrating, use a small category first.

1. Start ShareX.
2. Start `EquipmentBagCaptureTool.ahk`.
3. Put the equipment list at the absolute top.
4. Press `F8` and enter `12` to confirm item clicking and ShareX capture still work.
5. Reset the list to the absolute top.
6. Run a multi-screen test such as `36` items and check for duplicates or skipped items.

The screenshot side uses the previously proven two-click selection and ShareX behaviour; movement uses the verified row-5 grab point and alternating short/long drag distances.

## 6. Capture a full equipment bag

1. Start ShareX and confirm its save folder.
2. Start `EquipmentBagCaptureTool.ahk`.
3. Open the required equipment category in the correct 3-column bag view.
4. Count the exact number of equipment items in the category.
5. Put the list at the absolute top.
6. Close any open equipment popup.
7. Press `F8`.
8. Enter the exact item count.
9. Read the summary and press **OK**.
10. Do not touch the mouse or keyboard until the completion message appears.

Press `Esc` to stop immediately. **Esc closes the AutoHotkey script completely**, so restart `EquipmentBagCaptureTool.ahk` before another run.

## Proven capture behaviour

The capture side retains the behaviour from the final successful `MapleRingTest.ahk` test:

- each equipment item is clicked **twice**, with a pause between clicks
- ShareX is triggered with `SendEvent "^+z"`
- list movement uses a **single held drag**
- the script waits **800 ms after each movement** before continuing

The historical successful full-bag test reported:

- Requested equipment items: **249**
- Screenshot commands sent: **249**
- Expected movements: **20**
- Movements performed: **20**
- The run reached the bottom of the bag correctly

## What the completion report proves

The completion report confirms only:

- number of screenshot hotkey commands sent
- number of movement commands performed

It cannot prove that ShareX saved every image or that every in-game click was accepted. After an important capture, check the output file count and verify the batch for duplicates.

## Troubleshooting

### AutoHotkey reports a version error

Install AutoHotkey v2. The scripts are not compatible with AutoHotkey v1.

### ShareX is not running

Start ShareX before pressing `F8`.

### No screenshots are saved

- manually press `Ctrl+Shift+Z` and confirm ShareX saves one image
- check that ShareX is using the saved/last-region capture
- check the destination folder
- disable editing/confirmation steps that interrupt automatic saving

### The pointer clicks beside an item

- restore Maple to the calibrated position and size
- restore the calibrated resolution/display scaling
- rerun calibration
- aim carefully at the requested `Lv.` dots; tiny 1-2 px pitch variation is normalized automatically

### Movement is wrong

- make sure the list was at the absolute top during calibration and at the start of the run
- recalibrate after any resolution, scaling, Maple window size or position change
- check the calibration summary: on the validated layout, small pitch variation should normalize to **131 x 140 px** and movement should remain **576 / 577 px**
- test a small multi-screen category before a full bag

### I pressed Esc and F8 no longer works

`Esc` exits `EquipmentBagCaptureTool.ahk` completely. Double-click `EquipmentBagCaptureTool.ahk` again, dismiss the startup message, then press `F8` when ready.

### A screenshot is duplicated

The game did not accept the equipment selection before ShareX captured the popup. Treat the batch as incomplete, reset the bag to the top and rerun it. The tool deliberately uses the proven two-click item-selection routine.

## Known limitations

- Windows only
- coordinate-based automation depends on stable window placement/scaling
- assumes a 3-column x 4-row equipment capture grid
- the validated calibration tolerance is centered on the 131 x 140 px layout; substantially different layouts are scaled from their measured pitch and should be tested before a full run
- uses ShareX `Ctrl+Shift+Z`
- does not inspect screenshot contents while running
- does not perform OCR or analyse equipment

## License

MIT License.

This is an unofficial community utility and is not affiliated with Nexon.
