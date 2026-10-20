// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.discover as Discover
import org.kde.kirigami as Kirigami

// App Store: one of the large editorial cards at the top of macOS's
// Discover page: the app's first screenshot (or its icon's colour) behind a
// darkening at the bottom, a small caption, the app's name and description
// in white, its icon and the Get button. Clicking opens the app's page.
MouseArea {
    id: card

    required property Discover.AbstractResource application
    property string caption: i18nc("@label on a featured app", "Editors' Choice")
    property url shot

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    Accessible.role: Accessible.Button
    Accessible.name: application.name
    onClicked: Navigation.openApplication(application)

    Discover.ScreenshotsModel {
        id: shots
        application: card.application
    }
    Instantiator {
        model: shots
        delegate: QtObject {
            required property int index
            required property url large_image_url
            Component.onCompleted: if (index === 0) card.shot = large_image_url
        }
    }
    Kirigami.ImageColors {
        id: colors
        source: card.application.icon
    }

    // The picture, rounded; the icon's colour until (or without) one.
    Kirigami.ShadowedRectangle {
        anchors.fill: parent
        radius: 12
        color: Qt.darker(colors.dominant, 1.6)
        shadow.size: card.containsMouse ? 18 : 10
        shadow.yOffset: 3
        shadow.color: Qt.rgba(0, 0, 0, 0.35)
    }
    Kirigami.ShadowedTexture {
        anchors.fill: parent
        radius: 12
        visible: picture.status === Image.Ready
        source: Image {
            id: picture
            source: card.shot
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: card.width * 1.5
        }
    }
    // Darker towards the bottom, under the text.
    Rectangle {
        anchors.fill: parent
        radius: 12
        gradient: Gradient {
            GradientStop { position: 0.3; color: "transparent" }
            GradientStop { position: 0.62; color: Qt.rgba(0, 0, 0, 0.6) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.88) }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.gridUnit
        spacing: 2

        Item {
            Layout.fillHeight: true
        }
        QQC2.Label {
            text: card.caption
            font.weight: Font.Bold
            font.capitalization: Font.AllUppercase
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: Qt.rgba(1, 1, 1, 0.7)
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.8
                Layout.preferredHeight: Layout.preferredWidth
                source: card.application.icon
                animated: false
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                QQC2.Label {
                    Layout.fillWidth: true
                    text: card.application.name
                    color: "white"
                    font.weight: Font.Bold
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.35
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    text: card.application.comment
                    color: Qt.rgba(1, 1, 1, 0.8)
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }
            MacGetButton {
                application: card.application
                onDark: true
            }
        }
    }
}
