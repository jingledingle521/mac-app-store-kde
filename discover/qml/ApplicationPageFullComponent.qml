/*
 *   SPDX-FileCopyrightText: 2012 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
 *   SPDX-FileCopyrightText: 2022 Nate Graham <nate@kde.org>
 *   SPDX-FileCopyrightText: 2023 ivan tkachenko <me@ratijas.tk>
 *   SPDX-FileCopyrightText: 2026 Oliver Beard <olib141@outlook.com>
 *
 *   SPDX-License-Identifier: LGPL-2.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.discover as Discover

Kirigami.Padding {
    id: fullComponent

    required property Discover.AbstractResource application

    required property bool availableFromOnlySingleSource

    required property bool isOfflineUpgrade

    required property bool isTechnicalPackage

    required property var colorForLicenseType

    signal openContentRatingDialog()
    signal openLicenseDetailsDialog(licenseType: string)
    signal openAllLicensesSheet()

    padding: Kirigami.Units.gridUnit

    // App Store: macOS's app page header. The icon, large; the name, the
    // description and the author beside it, with the Get button (and ⋯ for
    // Uninstall); then the strip of facts across the page: ratings, age,
    // size, developer, licence, version.
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.gridUnit * 1.5

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.gridUnit * 1.2

            MacAppIcon {
                id: appIcon
                Layout.alignment: Qt.AlignTop
                implicitWidth: Kirigami.Units.gridUnit * 7
                implicitHeight: implicitWidth
                application: fullComponent.application
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 2

                QQC2.Label {
                    Layout.fillWidth: true
                    text: fullComponent.application.name
                    font.weight: Font.Bold
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 2
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: fullComponent.isOfflineUpgrade ? fullComponent.application.upgradeText : fullComponent.application.comment
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
                    opacity: 0.6
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
                RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    visible: !fullComponent.isOfflineUpgrade
                    QQC2.Label {
                        text: fullComponent.application.author.length > 0 ? fullComponent.application.author
                            : i18nc("As in 'this app is made by an unknown author'", "Unknown author")
                        color: Kirigami.Theme.focusColor
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                    Kirigami.ContextualHelpButton {
                        visible: toolTipText.length > 0
                        icon.name: fullComponent.application.verifiedIconName
                        toolTipText: fullComponent.application.verifiedMessage
                    }
                }

                RowLayout {
                    Layout.topMargin: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.largeSpacing

                    MacGetButton {
                        application: fullComponent.application
                        prominent: true
                    }
                    QQC2.Label {
                        visible: !fullComponent.availableFromOnlySingleSource || fullComponent.application.displayOrigin.length > 0
                        text: fullComponent.application.displayOrigin
                        font: Kirigami.Theme.smallFont
                        opacity: 0.55
                    }
                    // ⋯: what macOS keeps out of the way.
                    QQC2.ToolButton {
                        visible: fullComponent.application.isInstalled && fullComponent.application.isRemovable
                        icon.name: "overflow-menu"
                        display: QQC2.AbstractButton.IconOnly
                        text: i18nc("@action:button more actions", "More")
                        onClicked: moreMenu.popup()
                        QQC2.Menu {
                            id: moreMenu
                            QQC2.MenuItem {
                                text: i18nc("@action:inmenu", "Uninstall")
                                icon.name: "edit-delete"
                                onTriggered: Discover.ResourcesModel.removeApplication(fullComponent.application)
                            }
                        }
                    }
                }
            }
        }

        // The facts, across the page, between hairlines.
        RowLayout {
            Layout.fillWidth: true
            visible: !fullComponent.isOfflineUpgrade
            spacing: 0

            component Fact: MouseArea {
                id: fact
                property string label
                property string value
                property string detail
                // An icon in place of the value (the developer's).
                property string glyph
                property bool first: false
                property var action: null

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: factColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
                visible: value.length > 0 || glyph.length > 0
                cursorShape: action ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (action) action()

                Rectangle {
                    visible: !fact.first
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: parent.height * 0.6
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                }
                ColumnLayout {
                    id: factColumn
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.largeSpacing * 2
                    spacing: 1
                    QQC2.Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: fact.label
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.weight: Font.DemiBold
                        font.capitalization: Font.AllUppercase
                        opacity: 0.5
                        elide: Text.ElideRight
                    }
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        visible: fact.glyph.length > 0
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        implicitHeight: implicitWidth
                        source: fact.glyph
                        isMask: true
                        color: Kirigami.Theme.textColor
                        opacity: 0.75
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        visible: fact.glyph.length === 0
                        horizontalAlignment: Text.AlignHCenter
                        text: fact.value
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.35
                        font.weight: Font.Bold
                        opacity: 0.75
                        elide: Text.ElideRight
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: fact.detail
                        font: Kirigami.Theme.smallFont
                        opacity: 0.5
                        elide: Text.ElideRight
                    }
                }
            }

            Fact {
                first: true
                visible: !fullComponent.isTechnicalPackage
                label: fullComponent.application.rating && fullComponent.application.rating.ratingCount > 0
                    ? i18ncp("@label number of ratings", "%1 Rating", "%1 Ratings", fullComponent.application.rating.ratingCount)
                    : i18nc("@label", "Ratings")
                value: fullComponent.application.rating && fullComponent.application.rating.ratingCount > 0
                    ? (fullComponent.application.rating.rating / 2).toFixed(1) : "–"
                detail: {
                    const r = fullComponent.application.rating ? Math.round(fullComponent.application.rating.rating / 2) : 0;
                    return r > 0 ? "★".repeat(r) + "☆".repeat(5 - r) : i18nc("@info", "Not enough ratings");
                }
            }
            Fact {
                visible: !fullComponent.isTechnicalPackage
                label: i18nc("@label the app's content rating", "Age")
                value: fullComponent.application.contentRatingMinimumAge === 0 ? i18nc("@item suitable for everyone", "4+")
                     : i18nc("@item %1 is an age", "%1+", fullComponent.application.contentRatingMinimumAge)
                detail: i18nc("@label under an age", "Years Old")
                action: fullComponent.application.contentRatingDescription.length > 0 ? () => fullComponent.openContentRatingDialog() : null
            }
            Fact {
                label: i18nc("@label", "Size")
                value: fullComponent.application.sizeDescription
                detail: fullComponent.application.isInstalled ? i18nc("@label", "Installed") : i18nc("@label", "Download")
            }
            Fact {
                label: i18nc("@label", "Developer")
                glyph: "user-symbolic"
                detail: fullComponent.application.author
                visible: fullComponent.application.author.length > 0
            }
            Fact {
                readonly property var licence: fullComponent.application.licenses.length > 0 ? fullComponent.application.licenses[0] : null
                label: i18nc("@label", "License")
                value: licence ? licence.name : i18nc("The app does not provide any licenses", "Unknown")
                detail: licence ? (licence.licenseType === "free" ? i18nc("@label free software", "Free Software")
                                 : licence.licenseType === "proprietary" ? i18nc("@label", "Proprietary") : i18nc("@label", "Non-free"))
                                : ""
                action: () => {
                    if (fullComponent.application.licenses.length > 1) {
                        fullComponent.openAllLicensesSheet();
                    } else if (!licence || licence.licenseType !== "free") {
                        fullComponent.openLicenseDetailsDialog(licence ? licence.licenseType : "unknown");
                    } else if (licence.url) {
                        Qt.openUrlExternally(licence.url);
                    }
                }
            }
            Fact {
                label: i18nc("@label", "Version")
                value: fullComponent.application.versionString
            }
        }
    }
}
