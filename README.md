# MacKeyMapper

A macOS keyboard visualizer + system-wide remapping tool.

## Install (recommended)
```
./scripts/install.sh
```
Builds the release and installs it to `/Applications/MacKeyMapper.app`. After that you can
launch it without rebuilding by double-clicking in Launchpad/Applications. (`open -a MacKeyMapper`)

## Build/Run (development)
- Test: `swift test`
- Build the app bundle only: `./scripts/make-app.sh` → `open build/MacKeyMapper.app`
- Quick compile check during development: `swift run MacKeyMapper`

> Key detection (the event tap) reliably binds the Input Monitoring permission to a **code-signed app bundle**.
> So for real usage and testing, prefer running the `.app` built with `make-app.sh` rather than `swift run`.
> (A temporary binary launched via `swift run` may not retain the permission, so highlighting may not work.)

## Permissions
Key detection requires the **Input Monitoring** permission (Privacy & Security → Input Monitoring) —
a listen-only keyboard tap needs Input Monitoring, not Accessibility. On first launch, click 'Open
Settings' in the banner to grant it, then click 'Re-check'. (If it doesn't take effect, relaunch the app.)

Note: rebuilding the app re-signs it ad-hoc, which resets its permission — re-grant Input Monitoring
after each rebuild.

## How it works
- Test mode: pressed keys are highlighted on the layout (left/right modifiers distinguished).
- Remap mode: map by clicking source key → target key. Applied instantly via `hidutil`, and persisted across logins with a LaunchAgent.
- Reset All: removes all mappings and the LaunchAgent.

## Storage locations
- Mappings: `~/Library/Application Support/MacKeyMapper/mappings.json`
- Persistence: `~/Library/LaunchAgents/com.mackeymapper.remap.plist`
