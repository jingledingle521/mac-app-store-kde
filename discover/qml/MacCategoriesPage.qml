// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.discover as Discover
import org.kde.kirigami as Kirigami

// App Store: macOS's Categories page. A large title, then a tile for each
// category: its glyph in white on a colour of its own, and its name.
// Clicking one lists its apps.
DiscoverPage {
    id: page

    title: i18nc("@title", "Categories")
    readonly property bool macOwnTitle: true

    // macOS's category colours, in turn.
    readonly property var tints: ["#0a84ff", "#ff9f0a", "#30d158", "#bf5af2", "#ff375f", "#64d2ff", "#ffd60a", "#5e5ce6", "#ff453a", "#63e6e2", "#ac8e68"]

    ColumnLayout {
        spacing: Kirigami.Units.gridUnit * 1.5

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 1
            font.weight: Font.Bold
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 2.1
            text: page.title
        }

        GridLayout {
            id: grid
            Layout.fillWidth: true
            columns: Math.max(1, Math.floor((width + columnSpacing) / (Kirigami.Units.gridUnit * 13 + columnSpacing)))
            columnSpacing: Kirigami.Units.gridUnit
            rowSpacing: Kirigami.Units.gridUnit

            Repeater {
                model: Discover.CategoryModel.rootCategories
                delegate: MouseArea {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property Discover.Category category: Discover.CategoryModel.get(modelData)
                    readonly property color tint: page.tints[index % page.tints.length]

                    visible: category?.visible ?? false
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: Kirigami.Units.gridUnit * 4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: category?.name ?? ""
                    onClicked: Navigation.openCategory(modelData)

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, tile.containsMouse ? 0.1 : 0.06)
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Units.largeSpacing

                        Rectangle {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.4
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: width * 0.23
                            color: tile.tint
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: parent.width * 0.6
                                height: width
                                source: (tile.category?.icon ?? "") + "-symbolic"
                                fallback: tile.category?.icon ?? ""
                                isMask: true
                                color: "white"
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: tile.category?.name ?? ""
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }
                    }
                }
            }
        }
    }
}
