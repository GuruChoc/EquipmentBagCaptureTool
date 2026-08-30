## v1.0.4 - 2026-08-30

- Record Maple window DPI during calibration.
- Block capture when Windows display scaling/DPI differs from calibration.
- Keep calibrated absolute coordinates unchanged; no auto-scaling.
- Preserve tested 576/577 px movement and 850 ms ShareX post-capture delay.

# Changelog

## v1.0.3 — 2026-08-26

Corrective publication/hygiene release; tested capture mechanics are unchanged from v1.0.2.

- Normalises the local calibration INI to strict UTF-8 while keeping it excluded from Git and release assets.
- Rebuilds README from the known-good v1.0.2 documentation base.
- Removes stale diagnostic-version wording and UTF-8 mojibake.
- Keeps the 850 ms timing, 576 / 577 px movement, input lock, Esc checkpoint, F9 resume, post-movement recovery and position-safety behaviour unchanged.
- Requires the all-project UTF-8/mojibake gate to pass before publication.

## v1.0.2 — 2026-08-26

- Reduced ShareX post-capture wait to 850 ms after long-run validation.
- Added physical mouse-movement lock during capture.
- Added safe Esc stop with persistent checkpoint and F9 resume.
- Added post-movement first-item settle/reclick recovery.
- Added Maple window position/size safety checks and standalone reposition helper.
- Preserved validated alternating 576 / 577 px equipment-list movement.

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
