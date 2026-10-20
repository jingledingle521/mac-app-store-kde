// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.discover as Discover
import org.kde.kirigami as Kirigami

// App Store: an app in a list, as macOS's: its icon, name and one-line
// description, the Get button at the right, and a hairline under the text
// (`separator`). Clicking anywhere else opens the app's page.
MouseArea {
    id: row

    required property Discover.AbstractResource application
    property bool separator: true
    // Under the name: the description, or (Your Apps) the size.
    property string detail: application.comment

    implicitHeight: Kirigami.Units.gridUnit * 4
    hoverEnabled: true
    activeFocusOnTab: true
    Accessible.role: Accessible.ListItem
    Accessible.name: application.name
    Accessible.onPressAction: open()

    function open() {
        Navigation.openApplication(application);
    }

    onClicked: open()
    Keys.onReturnPressed: open()
    Keys.onEnterPressed: open()

    RowLayout {
        id: content
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            id: icon
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3.2
            Layout.preferredHeight: Layout.preferredWidth
            source: row.application.icon
            animated: false
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            QQC2.Label {
                Layout.fillWidth: true
                text: row.application.name
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
                textFormat: Text.PlainText
            }
            QQC2.Label {
                Layout.fillWidth: true
                text: row.detail
                font: Kirigami.Theme.smallFont
                opacity: 0.6
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
                textFormat: Text.PlainText
            }
        }

        MacGetButton {
            Layout.alignment: Qt.AlignVCenter
            application: row.application
        }
    }

    // Keyboard focus: a soft ring around the row.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -Kirigami.Units.smallSpacing
        visible: row.activeFocus
        radius: 8
        color: "transparent"
        border.width: 2
        border.color: Kirigami.Theme.focusColor
    }

    Rectangle {
        visible: row.separator
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        x: icon.width + content.spacing
        width: parent.width - x
        height: 1
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
    }
}
