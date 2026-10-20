// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// App Store: the strip above the page, where macOS's App Store keeps its
// toolbar: ‹ back when a page was opened from another, the page's title
// (unless the page shows its own large one: macOwnTitle, isHome), and the
// page's actions at the right. Empty space moves the window, as a title bar.
Item {
    id: bar

    required property var chrome
    required property var pageStack

    readonly property Item page: pageStack.currentItem

    implicitHeight: Kirigami.Units.gridUnit * 2.6

    MouseArea {
        anchors.fill: parent
        onPressed: bar.chrome.startMove()
        onDoubleClicked: bar.chrome.toggleMaximized()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        QQC2.ToolButton {
            visible: bar.pageStack.depth > 1
            icon.name: Qt.application.layoutDirection === Qt.RightToLeft ? "go-next-symbolic" : "go-previous-symbolic"
            display: QQC2.AbstractButton.IconOnly
            text: i18nc("@action:button", "Back")
            onClicked: bar.pageStack.goBack()
            QQC2.ToolTip.text: text
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            text: bar.page && !bar.page.hasOwnProperty("isHome") && !bar.page.hasOwnProperty("macOwnTitle") ? bar.page.title : ""
            font.weight: Font.Bold
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
            elide: Text.ElideRight
        }

        Kirigami.ActionToolBar {
            Layout.fillWidth: true
            alignment: Qt.AlignRight
            flat: true
            actions: bar.page?.actions ?? []
        }
    }
}
