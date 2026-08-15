# Changelog

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
