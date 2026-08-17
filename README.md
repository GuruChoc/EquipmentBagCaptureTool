# Equipment Bag Capture Tool

Equipment Bag Capture Tool automates screenshot capture of equipment detail popups in the MapleStory: Idle RPG PC client using AutoHotkey v2 and ShareX.

It works with the equipment bag displayed as a **3-column x 4-row grid** and processes items left-to-right, top-to-bottom. It automatically moves the bag after each group of 12 items and correctly handles incomplete final screens clamped to the bottom of the list.

## Important warning

This tool sends automated mouse and keyboard input to the game client. It does not modify the game, read game memory, bypass security, or communicate with Nexon's servers directly. Automated input may still be restricted by Nexon's current rules. Check the current rules yourself before using or distributing the tool. Use is at your own risk.

Do not begin with a full bag on a new setup. Run the 12-item and 36-item tests first.

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

## 2. Get to the correct 3-column equipment bag view

Before calibrating or capturing:

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

1. Open the correct 3-column bag view described above.
2. Select a category containing at least **6 items**.
3. Put the list at the absolute top.
4. Keep the Maple window in the exact position and size you will use later.
5. Double-click `EquipmentBagCaptureCalibration.ahk`.
6. Follow each prompt and press `T` to record the requested point.
7. The wizard creates `EquipmentBagCapture.ini` beside the scripts.

For every equipment reference point, aim precisely at the **bottom-right corner of the tier badge**. The badge may show **T1, T2, T3 or T4** depending on the equipment; the tier value does not matter.

Calibration records only:

- bottom-right corner of the tier badge on the top-left equipment item
- bottom-right corner of the tier badge on the top-middle equipment item
- bottom-right corner of the tier badge on the second-row left equipment item
- popup close button

The first three tier-badge corners provide the equipment click positions and the horizontal/vertical grid spacing. The remaining grid click positions are calculated automatically from that measured spacing.

### How scrolling is calculated

The movement distance is **not manually calibrated**. The script calculates it from the measured grid geometry:

- drag X = calculated right-hand equipment column
- drag end Y = measured top-row Y
- drag start Y = top-row Y + **4 × measured row spacing**

That means one movement is always exactly four equipment-row spacings. For example, if calibration measures a row spacing of 139 px, the movement distance is `4 × 139 = 556 px`.

Because the row and column spacing are measured on the current PC during calibration, this method is not tied to one fixed resolution. A different resolution or scaling can produce different pixel spacing and the calculation will use those measured values. **Recalibrate whenever resolution, Windows display scaling, Maple window size, Maple window position or the relevant game layout changes.**

## 4. Mandatory test sequence

1. Start ShareX.
2. Double-click `EquipmentBagCaptureTool.ahk`.
3. Read the startup message, then press `F8` to start a capture.
4. Put the equipment list at the absolute top with no popup open.
5. Enter `12`.
6. Confirm exactly 12 screenshots were saved and all are unique.
7. Reset the list to the absolute top.
8. Press `F8` and enter `36`.
9. Confirm exactly 36 screenshots were saved and two movements occurred.
10. Check the screenshots for duplicates or skipped items before attempting a full bag.

**Important:** pressing `Esc` at any time stops the current run **and closes `EquipmentBagCaptureTool.ahk` completely**. If you press `Esc`, restart `EquipmentBagCaptureTool.ahk` before trying another test or capture.

## 5. Capture a full equipment bag

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

The release uses the behaviour from the final successful `MapleRingTest.ahk` test script rather than the earlier experimental movement logic:

- each equipment item is clicked **twice**, with a pause between clicks
- ShareX is triggered with `SendEvent "^+z"`
- list movement uses a **single held drag**: `Click "Down"` → stepped movement → `Click "Up"`
- the script waits **800 ms after each movement** before continuing
- the movement routine passed **60 consecutive movement tests**

The successful full-bag test reported:

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
- make sure the first three calibration points are placed precisely on the requested tier-badge corners

### Movement is wrong

- make sure the first three tier-badge reference points were marked accurately
- make sure the bag was at the absolute top during calibration
- recalibrate after any resolution, scaling, Maple window size or position change
- rerun the 36-item test before attempting another full bag

### I pressed Esc and F8 no longer works

`Esc` exits `EquipmentBagCaptureTool.ahk` completely. Double-click `EquipmentBagCaptureTool.ahk` again, dismiss the startup message, then press `F8` when you are ready to start another capture.

### A screenshot is duplicated

The game did not accept the equipment selection before ShareX captured the popup. Treat the batch as incomplete, reset the bag to the top and rerun it. The current release deliberately uses the proven two-click item-selection routine.

## Known limitations

- Windows only
- coordinate-based automation depends on stable window placement/scaling
- assumes a 3-column x 4-row equipment capture grid
- assumes one calculated four-row movement advances to the next group of items
- uses ShareX `Ctrl+Shift+Z`
- does not inspect screenshot contents while running
- does not perform OCR or analyse equipment

## License

MIT License.

This is an unofficial community utility and is not affiliated with Nexon.
