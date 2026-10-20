// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// App Store: a shelf of apps, as on macOS's Discover page: a bold title
// with See All at the right, then apps in columns (as many as fit, rows of
// `rows`), each a MacAppRow. `model` gives apps in the `application` role.
ColumnLayout {
    id: shelf

    property string title
    property alias model: repeater.model
    property int rows: 3
    // Called by See All; none hides it.
    property var seeAll: null

    readonly property int columns: Math.max(1, Math.min(3, Math.floor((width + grid.columnSpacing) / (Kirigami.Units.gridUnit * 14 + grid.columnSpacing))))
    readonly property alias count: repeater.count
    readonly property int shown: Math.min(repeater.count, columns * rows)

    visible: repeater.count > 0
    spacing: Kirigami.Units.smallSpacing

    // A hairline above, as between macOS's shelves.
    Rectangle {
        Layout.fillWidth: true
        Layout.bottomMargin: Kirigami.Units.largeSpacing
        implicitHeight: 1
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
    }

    RowLayout {
        Layout.fillWidth: true
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 2
            font.weight: Font.Bold
            text: shelf.title
            elide: Text.ElideRight
        }
        QQC2.Label {
            visible: shelf.seeAll !== null
            text: i18nc("@action:button show all apps of a shelf", "See All")
            color: Kirigami.Theme.focusColor
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: shelf.seeAll()
            }
        }
    }

    GridLayout {
        id: grid
        Layout.fillWidth: true
        columns: shelf.columns
        columnSpacing: Kirigami.Units.gridUnit * 1.5
        rowSpacing: 0
        // Down each column, then across, as macOS fills its shelves.
        flow: GridLayout.TopToBottom
        rows: Math.ceil(shelf.shown / shelf.columns)

        Repeater {
            id: repeater
            delegate: MacAppRow {
                required property int index
                required property var model
                application: model.application
                visible: index < shelf.shown
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                separator: (index + 1) % grid.rows !== 0 && index < shelf.shown - 1
            }
        }
    }
}
