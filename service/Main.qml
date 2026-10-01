pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray

// service/Main.qml: the tray's logic, no UI. Quickshell's SystemTray singleton
// already does the DBus StatusNotifierItem watching for the whole shell; this
// just tracks which ids are "pinned" so they always render on the bar, even
// before the owning app has launched this session. Pins persist through
// pluginApi.saveSetting, which writes into ~/.config/ryoku/plugins.json, so
// they survive a plugin reload, a shell restart, and a reboot (R5, R8).
Item {
    id: svc

    // Set by the host after this loads.
    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

    // The live tray: every app currently publishing a StatusNotifierItem.
    // SystemTray.items is a Quickshell ObjectModel; .values is the plain
    // array of live StatusNotifierItem objects, kept in sync by the daemon.
    readonly property var liveItems: SystemTray.items ? SystemTray.items.values : []

    // Pinned ids, parsed from the persisted JSON array string. Re-parsed
    // whenever the persisted settings change (e.g. another monitor's copy of
    // this plugin pinned something).
    property var pinnedIds: svc._parsePinned()

    readonly property int maxPinned: {
        var n = svc.settings ? svc.settings.maxPinned : 6;
        return (typeof n === "number" && n > 0) ? n : 6;
    }

    onSettingsChanged: svc.pinnedIds = svc._parsePinned()

    function _parsePinned() {
        var raw = svc.settings ? svc.settings.pinnedIds : "[]";
        try {
            var arr = JSON.parse(raw || "[]");
            return Array.isArray(arr) ? arr : [];
        } catch (e) {
            return [];
        }
    }

    function isPinned(id) {
        return svc.pinnedIds.indexOf(id) !== -1;
    }

    // Toggle a pin and persist it immediately. id is the StatusNotifierItem's
    // stable id (survives the icon/title changing, unlike title text).
    function togglePin(id) {
        if (!svc.pluginApi || !id)
            return;
        var next = svc.pinnedIds.slice();
        var at = next.indexOf(id);
        if (at !== -1)
            next.splice(at, 1);
        else
            next.push(id);
        svc.pluginApi.saveSetting("pinnedIds", JSON.stringify(next));
        svc.pinnedIds = next;
    }

    // Pinned items that are currently live, in the order they were pinned,
    // capped to maxPinned so a pinning spree can't flood the bar.
    function pinnedItems() {
        var out = [];
        for (var i = 0; i < svc.pinnedIds.length && out.length < svc.maxPinned; i++) {
            var item = svc._findLive(svc.pinnedIds[i]);
            if (item)
                out.push(item);
        }
        return out;
    }

    // Every live item not currently pinned (shown in the panel's "more" list).
    function unpinnedItems() {
        var out = [];
        var vals = svc.liveItems;
        for (var i = 0; i < vals.length; i++) {
            if (vals[i] && svc.pinnedIds.indexOf(vals[i].id) === -1)
                out.push(vals[i]);
        }
        return out;
    }

    function _findLive(id) {
        var vals = svc.liveItems;
        for (var i = 0; i < vals.length; i++) {
            if (vals[i] && vals[i].id === id)
                return vals[i];
        }
        return null;
    }
}
