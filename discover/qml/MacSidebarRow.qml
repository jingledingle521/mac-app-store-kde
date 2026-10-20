// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// App Store: a sidebar row, as macOS's: a glyph in the accent colour and a
// name, on a rounded selection in the accent colour (glyph and name turn
// white). A badge counts (updates); `busy` spins instead while fetching.
// Children replace the glyph and name (the account row).
MouseArea {
    id: row

    property bool selected: false
    property string text
    property string glyph
    property int badge: 0
    property bool busy: false
    // Space between the window edge and the selection.
    property real inset: Kirigami.Units.smallSpacing * 2

    implicitHeight: Kirigami.Units.gridUnit * 1.75
    hoverEnabled: true
    Accessible.role: Accessible.ListItem
    Accessible.name: text

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: row.inset
        anchors.rightMargin: row.inset
        radius: 6
        color: row.selected ? Kirigami.Theme.focusColor
             : row.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.07)
             : "transparent"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: row.inset + Kirigami.Units.smallSpacing * 2
        anchors.rightMargin: row.inset + Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.mediumSpacing
        visible: row.text.length > 0

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Layout.preferredWidth
            source: row.glyph
            isMask: true
            color: row.selected ? "white" : Kirigami.Theme.focusColor
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: row.text
            elide: Text.ElideRight
            color: row.selected ? "white" : Kirigami.Theme.textColor
        }
        QQC2.BusyIndicator {
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Layout.preferredWidth
            visible: row.busy
            running: visible
        }
        // macOS's count: a small gray capsule.
        Rectangle {
            visible: row.badge > 0 && !row.busy
            implicitWidth: Math.max(height, count.implicitWidth + 10)
            implicitHeight: count.implicitHeight + 2
            radius: height / 2
            color: row.selected ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            QQC2.Label {
                id: count
                anchors.centerIn: parent
                text: row.badge
                font: Kirigami.Theme.smallFont
                color: row.selected ? "white" : Kirigami.Theme.textColor
            }
        }
    }
}
