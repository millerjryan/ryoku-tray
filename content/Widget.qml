import QtQuick
import Quickshell
import Quickshell.Widgets
import Ryoku.PluginKit.Singletons

// content/Widget.qml: the bar glyph. Pinned tray icons render inline so they
// are always visible; a chevron beside them opens the panel (never a bar
// click mutates anything itself) where the rest of the tray and the pin
// controls live. If nothing is pinned yet, only the chevron shows.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var pinned: service ? service.pinnedItems() : []
    readonly property int liveCount: service ? service.liveItems.length : 0
    // Apps only reachable through the panel, i.e. not already pinned inline.
    readonly property int collapsedCount: service ? service.unpinnedItems().length : 0

    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(row.implicitHeight, 18 * root.s)

    // Native context menu surface, shared by every pinned icon: only one can
    // be open at a time, so a single anchor is reused rather than one per
    // delegate. Falls back to secondaryActivate() for apps with no DBusMenu.
    QsMenuAnchor {
        id: ctxMenu
    }

    function showContextMenu(trayItem, atItem) {
        if (trayItem.hasMenu && trayItem.menu) {
            ctxMenu.anchor.item = atItem;
            ctxMenu.menu = trayItem.menu;
            ctxMenu.open();
        } else {
            trayItem.secondaryActivate();
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6 * root.s

        Repeater {
            model: root.pinned

            delegate: Item {
                id: iconSlot
                required property var modelData

                width: 16 * root.s
                height: 16 * root.s
                anchors.verticalCenter: parent.verticalCenter

                IconImage {
                    anchors.fill: parent
                    source: iconSlot.modelData.icon
                    asynchronous: true
                    smooth: true
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            root.showContextMenu(iconSlot.modelData, iconSlot);
                        else
                            iconSlot.modelData.activate();
                    }
                    onWheel: wheel => iconSlot.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }

        // The collapse/expand mark. Always present (even with zero pinned
        // icons) so a tray with nothing pinned is still reachable. The bar
        // is a fixed-height layer-shell surface, so a popup/tooltip hanging
        // outside this item's bounds would just be clipped by the window
        // itself; instead the glyph grows in place on hover to show the
        // collapsed count inline, which the host already re-measures live.
        Item {
            id: chevronSlot
            width: chevron.implicitWidth + 4 * root.s
            height: 18 * root.s

            property bool hovered: false

            Text {
                id: chevron
                anchors.centerIn: parent
                // Plain ASCII caret: reliable across fonts, unlike dingbat
                // triangle codepoints that some fonts substitute oddly.
                text: {
                    const mark = root.active ? "^" : "v";
                    return chevronSlot.hovered && !root.active
                        ? mark + " " + root.collapsedCount
                        : mark;
                }
                color: root.liveCount > 0 ? (root.active ? Theme.accent : Theme.bright) : Theme.dim
                font.family: Theme.font
                font.bold: true
                font.pixelSize: 13 * root.s
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: chevronSlot.hovered = true
                onExited: chevronSlot.hovered = false
                onClicked: if (root.pluginApi) root.pluginApi.togglePanel()
            }
        }
    }
}
