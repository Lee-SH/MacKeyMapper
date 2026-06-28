# Scan Tab — Guided Keyboard Capture (Design)

Date: 2026-06-29
Status: Approved

## Goal

Let any user "see their own keyboard." A new **Scan** tab (left of Test) walks the
user through a guided scan: the app highlights template slots one at a time, the user
presses the matching physical key (or skips keys their keyboard lacks), and the app
draws the resulting keyboard. Each captured key shows its **Mac-equivalent name**
plus the **raw value the key actually sends** (virtual key code + produced character).

This matters because the typical user's keyboard is a Windows/Korean board with keys
that have no Mac equivalent (한/영, 한자, Windows, Menu, right Ctrl). The feature must
be reusable by anyone who downloads the source — no hardcoded per-user layout.

## Key constraint

macOS exposes no API for a keyboard's physical geometry. The app only learns, per
keypress, the **virtual key code** and the **character produced**. The design works
around this: a predefined template provides *positions and ordering*; the scan only
*captures key code + character* and binds them to template slots.

## UX flow

- `AppMode` gains a `.scan` case. Picker order becomes `Scan | Test | Remap`.
  Default mode stays `.test`.
- **No saved scan**: template renders dimmed (placeholders) with a "Start scan" button.
- **Scanning**: the current slot is highlighted with a prompt "Press this key (or Skip)".
  - Pressing a physical key captures `(keyCode, character)` for that slot and auto-advances.
  - "Skip" marks the slot absent and advances (key not on this keyboard).
  - "Back" re-does the previous slot.
  - Reaching the last slot finishes and saves automatically.
- **Viewing a saved scan**: only captured (present) slots are drawn. Each key shows the
  Mac name as the primary label and the captured raw value (key code / character) as a
  secondary line. Pressing a physical key live-highlights the slot whose captured key
  code matches (this is the "see my key values" experience). A "Re-scan" button restarts.

## Components (isolated, testable)

- **`ScanTemplate`** (Core, pure data): ordered list of slots providing prompt order and
  layout positions. Slot = `{ id, macLabel, macName?, row, width }`. Rows 0–4 reuse the
  existing `KeyCatalog` (Mac) positions and Mac names. Row 5 is a PC-style bottom row plus
  extra PC/Korean slots. It does **not** touch `KeyCatalog`/`hidUsage` used for remapping.
- **`ScanSession`** (Core, pure logic, unit-tested): holds the current slot index and the
  accumulated captures. API: `record(keyCode:character:)`, `skip()`, `back()`,
  `currentSlot`, `isComplete`, `result` → `ScannedKeyboard`. No SwiftUI dependency.
- **`ScannedKeyboard` + `ScanStore`** (Core): result model mapping slot id →
  `{ keyCode: UInt16, character: String, present: Bool }`, with Codable JSON save/load
  following the `RemapStore` pattern. Stored at
  `~/Library/Application Support/MacKeyMapper/scanned-keyboard.json`.
- **`ScanView`** (App, SwiftUI): renders the template, drives scan-progress UI, and does
  live highlighting. Reuses/extends `KeyCapView`.
- **`AppState`** (App): holds the loaded `ScannedKeyboard` and an optional active
  `ScanSession`. While scanning, key events (`keyDown` / `flagsChanged`) are routed into
  the session to capture and advance; on completion the result is saved. While viewing,
  key events flow to `pressedKeyCodes` and matching slots highlight.

## Data flow

Reuses the existing `KeyEventMonitor` (listen-only CGEventTap).

- Scanning: key event → `ScanSession.record` → next slot → (on complete) `ScanStore.save`.
- Viewing: key event → `AppState.pressedKeyCodes` → slots whose captured `keyCode` matches
  are highlighted.

## Mac-name mapping

The Mac-equivalent name is carried by the **template slot**, never inferred from the
captured key code. Examples: `Win → ⌘ command`, `Alt → ⌥ option`, `right Ctrl → ⌃ control`,
`Backspace → ⌫ delete`, `Enter → ⏎ return`. Keys with no Mac equivalent (`Menu`, `한/영`,
`한자`) keep their own label plus a "(no Mac equivalent)" note.

## Row 5 (PC bottom row) composition

Default left→right: `left Ctrl`, `Win` (→⌘), `left Alt` (→⌥), `한자`, `space`, `한/영`,
`right Alt` (→⌥), `Win` (→⌘), `Menu`, `right Ctrl`. Widths approximate a PC board; exact
widths refined during implementation. Other rows match the current Mac template.

## Testing

- `ScanSession`: advance on record, skip marks absent, back re-does previous slot,
  completion after last slot, `result` reflects captures.
- `ScanStore`: save/load round-trip preserves captures.
- Permission/event-tap behavior verified manually (consistent with the rest of the app).

## Out of scope

- True physical geometry / per-key sizes beyond the template approximation.
- Drag-to-arrange custom layout editing.
- Remapping integration of PC-only keys (this tab is visualization only).
