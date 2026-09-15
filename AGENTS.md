# Agent Notes — WhereWindsMeet-AutoCode

## Project Type
Single-file AutoHotkey v2 script (`WhereWindsMeet-AutoCode.ahk`). No package manager, no tests, no linter, no formatter.

## How to verify changes
- Install [AutoHotkey v2](https://www.autohotkey.com/).
- Right-click `WhereWindsMeet-AutoCode.ahk` → **Run as administrator** (required for pixel color detection, mouse click and `Ctrl+A / Ctrl+V` to reach the game).
- The mini GUI will appear; set P1/P2/P3 with F1/F2/F3, paste a code list, press F5 to test.
- Press **ESC** to stop while running. When idle, ESC remains a normal game key (`#HotIf IsRunning`).

## Build & Release
- **No local build step.** The CI workflow (`.github/workflows/release.yml`) compiles `WhereWindsMeet-AutoCode.ahk` → `WhereWindsMeet-AutoCode.exe` on every push to `main` using Ahk2Exe.
- `WhereWindsMeet-AutoCode.exe` and `WWM_AutoCode.ini` are `.gitignore`d — **never commit them**.
- CI uses **Conventional Commits** to auto-bump semver (`feat` → minor, `fix/refactor/perf` → patch, `BREAKING CHANGE`/`!` → major) and creates a GitHub Release with the compiled `.exe`.

## Architecture notes
- `GAME_TITLE := "Where Winds Meet"` is the single source of truth. `SetTitleMatchMode 2` (substring match).
- Points are stored as **game-client coordinates** (screen minus client origin via `ClientToScreen`), persisted to `WWM_AutoCode.ini` (`[POINTS]` section). P1 also stores its reference pixel color (`P1COLOR`).
- Flow per code: `P1 → P2 → Ctrl+A + paste → P3 → WaitForP1NormalColor()`.
  - P1 color back to normal → next code starts from P1.
  - P1 color different (result popup still open) → next code skips P1 and starts directly at P2.
- `ClickGamePoint()` converts client coords back to screen via `ClientToScreen`, `MouseMove` + `Click Left`.
- `ReplaceInputWithCode()` backs up clipboard (`ClipboardAll()`), sets `A_Clipboard`, `SendEvent ^a / ^v`, then restores.
- `SleepSafe(ms)` sleeps in 50 ms slices so ESC/STOP stays responsive.
- Tunables at top of script: `DEFAULT_ACTION_DELAY` (350), `DEFAULT_LINE_DELAY` (400), `COLOR_TOLERANCE` (30), `COLOR_INITIAL_WAIT` (350), `COLOR_CHECK_TIMEOUT` (1200), `COLOR_CHECK_INTERVAL` (100).

## Assets folder
Contains `logo.ico` / `logo.png` (tray + GUI icon), `WhereWindsMeet-AutoCode.png` (empty GUI screenshot for README), `CodeFilled.PNG` (filled code list + set points screenshot for README), `CheckPoint1.png` (P1 — Exchange Code button), `CheckPoint2.png` (P2 — Exchange Rewards input box), `CheckPoint3.png` (P3 — Space Confirm button). Filenames are case-sensitive on GitHub — keep README references in sync.
