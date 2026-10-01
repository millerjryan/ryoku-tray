# Tray

A collapsible system tray for the QS Bar. Apps that publish a
StatusNotifierItem (most tray-capable Linux apps: Discord, Steam, Signal,
syncthing, network managers, etc.) show up here instead of nowhere.

## What it does

- **Collapsed by default.** The bar glyph is just a small chevron plus
  whatever you've pinned. Click the chevron to open the panel and see every
  app currently publishing a tray icon.
- **Pin an icon** from the panel (the "PIN" / "★ PINNED" mark on each row) to
  keep it visible on the bar at all times, even while the tray is collapsed.
  Pins are written to `~/.config/ryoku/plugins.json` through
  `pluginApi.saveSetting`, so they survive a plugin reload, a shell restart,
  and a reboot — the app doesn't even need to be running yet; its icon just
  reappears once it registers again.
- **Left-click** an icon (on the bar or in the panel) to run the app's
  default tray action (`StatusNotifierItem.Activate`). **Right-click** opens
  the app's native context menu (its real DBusMenu, rendered via Quickshell's
  `QsMenuAnchor`), falling back to the secondary action (`SecondaryActivate`)
  for apps that don't publish one. **Scroll** on a pinned bar icon forwards
  the wheel delta to the app (`Scroll`).

## What it reads and writes

- Reads: Quickshell's `Quickshell.Services.SystemTray` singleton, which
  watches the standard `org.kde.StatusNotifierWatcher` DBus service that
  tray-capable apps register with. No extra command or network access is
  needed or declared.
- Writes: only the `pinnedIds` setting, through `pluginApi.saveSetting`
  (R5/R8) — no other files are touched.

## Settings

| key       | type | default | description                                                                                                                            |
| --------- | ---- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| pinnedIds | text | `[]`    | JSON array of pinned StatusNotifierItem ids. Managed by the pin buttons in the panel; edit by hand only if you know what you're doing. |
| maxPinned | int  | 6       | Caps how many pinned icons can show on the bar at once.                                                                                 |

## Known limitations (v0.1)

- Context menus come straight from each app's DBusMenu tree via
  `QsMenuAnchor`; a handful of apps that render their own custom menu
  surface (instead of publishing a standard DBusMenu) will still just get
  `SecondaryActivate`.

## Preview

Capture a real screenshot of the widget and save it as
`assets/preview-widget.png`, then list it under `files` in `manifest.json`.

## Build, check, install

```
ryoku plugin validate .
ryoku plugin add . --bar --yes
```

It lists under **Community** in QS Bar Settings. Publish it only when you want
to share it: `ryoku plugin share tray`.

## Author

Josh <josh@example.com>: this plugin is community-made (`official` is false).
