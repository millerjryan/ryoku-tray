import QtQuick
import Quickshell
import Quickshell.Widgets
import Ryoku.PluginKit.Singletons

// content/Panel.qml: the full tray list. Every live tray icon shows here with
// its name and a pin toggle; pinning moves it (also) onto the bar glyph and
// persists, so it survives a restart or reboot. Left-clicking a row activates
// the app's default tray action, right-clicking opens its native context menu
// (falling back to secondaryActivate() for apps with no DBusMenu).
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 320
    property bool active: false

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var liveItems: service ? service.liveItems : []
    readonly property var pinnedIds: service ? service.pinnedIds : []

    // Shared native context-menu surface; see Widget.qml for rationale.
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

    readonly property real rowHeight: 34 * root.s
    readonly property real headerHeight: headerCol.implicitHeight
    readonly property real listHeight: Math.max(root.rowHeight, Math.min(root.liveItems.length, 7) * root.rowHeight)

    implicitWidth: root.widthBudget
    implicitHeight: root.headerHeight + root.listHeight + 36 * root.s

    Column {
        id: headerCol
        x: 12 * root.s
        y: 12 * root.s
        width: root.width - 24 * root.s
        spacing: 2 * root.s

        Text {
            text: "Tray"
            color: Theme.bright
            font.family: Theme.display
            font.pixelSize: 16 * root.s
        }

        Text {
            text: root.liveItems.length === 0
                ? "No apps are publishing a tray icon right now."
                : "Pin an icon to keep it on the bar."
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    Flickable {
        id: list
        x: 12 * root.s
        y: headerCol.y + headerCol.implicitHeight + 8 * root.s
        width: root.width - 24 * root.s
        height: root.listHeight
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: list.width

            Repeater {
                model: root.liveItems

                delegate: Rectangle {
                    id: rowItem
                    required property var modelData

                    readonly property bool pinned: root.pinnedIds.indexOf(modelData.id) !== -1

                    width: col.width
                    height: root.rowHeight
                    radius: Theme.radius
                    color: rowArea.pressed ? Theme.cardBot : "transparent"

                    Item {
                        id: iconWrap
                        width: 18 * root.s
                        height: 18 * root.s
                        anchors.left: parent.left
                        anchors.leftMargin: 6 * root.s
                        anchors.verticalCenter: parent.verticalCenter

                        IconImage {
                            anchors.fill: parent
                            source: rowItem.modelData.icon
                            asynchronous: true
                            smooth: true
                        }
                    }

                    Text {
                        anchors.left: iconWrap.right
                        anchors.leftMargin: 8 * root.s
                        anchors.right: pinMark.left
                        anchors.rightMargin: 8 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: rowItem.modelData.tooltipTitle || rowItem.modelData.title || rowItem.modelData.id
                        color: Theme.bright
                        font.family: Theme.font
                        font.pixelSize: 12 * root.s
                        elide: Text.ElideRight
                    }

                    Text {
                        id: pinMark
                        anchors.right: parent.right
                        anchors.rightMargin: 6 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: rowItem.pinned ? "PINNED" : "PIN"
                        color: rowItem.pinned ? Theme.accent : Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6 * root.s
                            onClicked: if (root.service) root.service.togglePin(rowItem.modelData.id)
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.left: parent.left
                        anchors.right: pinMark.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton)
                                root.showContextMenu(rowItem.modelData, rowArea);
                            else
                                rowItem.modelData.activate();
                        }
                    }
                }
            }
        }
    }
}
