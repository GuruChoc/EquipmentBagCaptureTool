# Changelog

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
