# Changelog

## v1.0.2 — 2026-08-22

Faster capture and safer unattended runs.

- Reduced the ShareX post-capture wait from **1400 ms to 850 ms** while preserving the proven two-click item-selection and scrolling behaviour.
- Added a physical mouse-movement lock during capture so accidental mouse movement cannot pull the pointer away from the scripted coordinates.
- Added a safe `Esc` stop path that unlocks the mouse and reports completed screenshots, completed movements and the next item number as a checkpoint.
- Retains the live top-left capture/movement counter.
- Keeps the validated human-tolerant `Lv.` calibration and alternating **576 / 577 px** scrolling unchanged.
- Validated the faster **850 ms** timing with a **242-item** run completing **242 screenshot commands and 20 movements**.
- Validated **850 ms + mouse-movement lock** with a **201-item** run completing **201 screenshot commands and 16 movements**.
- Verified that 201-item run at file level: **201 PNG files saved and 0 duplicate CRC32 groups**.
- Automatic resume is not implemented; the safe-stop next-item number is a checkpoint only.

## v1.0.1 — 2026-08-18

Calibration, scrolling and usability improvements.

- Reworked calibration around the consistent `Lv.` dot landmark.
- Added large `Lv.` prompts and Enter-friendly calibration dialogs.
- Added human-tolerant calibration using averaging and normalization around the validated 2560x1440 layout.
- Added popup close-position calculation from the popup `Lv.` reference.
- Uses the verified row-5 / column-3 grab point for equipment-list movement.
- Uses alternating 576 / 577 px movement distances on the validated layout to minimise cumulative drift.
- Added a live capture progress counter showing captured items and movement progress.
- Preserves the proven two-click equipment selection, ShareX capture and held stepped-drag behaviour.
- Validated with a 36-item multi-screen test and a 134-item full capture requiring 11 movements.
- Subsequently stress-tested with a **300+ item full equipment bag** to validate long-run scrolling and cumulative-drift behaviour.
- Improved handling and documentation for incomplete final screens and bottom-of-list bounce-back behaviour.
- Updated README calibration and testing instructions.

## v1.0.0 — 2026-08-15

First stable release.

- Proven against a 249-item equipment bag.
- 249 screenshot commands completed successfully.
- 20 equipment-list movements completed successfully.
- Uses the final proven MapleRingTest capture behaviour:
  - two item-selection clicks per equipment item;
  - ShareX capture via `Ctrl+Shift+Z`;
  - one held stepped drag for each equipment-list movement;
  - 800 ms pause after each movement.
- Includes configurable screen-coordinate calibration through `EquipmentBagCapture.ini`.
- Includes the in-game navigation path to the 3-column equipment bag view.
- Includes ShareX setup, mandatory 12-item and 36-item test instructions, troubleshooting and safety notes.
- Personal calibration files are excluded from Git with `.gitignore`.
