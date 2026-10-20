/*
 *   SPDX-FileCopyrightText: 2015 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
 *   SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
 *
 *   SPDX-License-Identifier: LGPL-2.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.discover as Discover
import org.kde.discover.app as DiscoverApp

DiscoverPage {
    id: page

    title: i18nc("@title:window the name of a top-level 'home' page", "Discover")
    objectName: "featured"

    actions: window.wideScreen ? [ searchAction ] : []

    header: DiscoverInlineMessage {
        id: message

        inlineMessage: Discover.ResourcesModel.inlineMessage ? Discover.ResourcesModel.inlineMessage : app.homePageMessage
    }

    readonly property bool isHome: true

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    DiscoverApp.FeaturedModel {
        id: featuredModel
    }

    Kirigami.LoadingPlaceholder {
        visible: featuredModel.isFetching
        anchors.centerIn: parent
    }

    Loader {
        active: !featuredModel.isFetching && featuredModel.count === 0 && popShelf.count === 0

        anchors.centerIn: parent
        width: parent.width - (Kirigami.Units.largeSpacing * 4)
        sourceComponent: Kirigami.PlaceholderMessage {
            readonly property Discover.InlineMessage helpfulError: featuredModel.currentApplicationBackend?.explainDysfunction() ?? null

            icon.name: helpfulError?.iconName ?? ""
            text: i18n("Unable to load applications")
            explanation: helpfulError?.message ?? ""

            Repeater {
                model: helpfulError?.actions ?? null
                delegate: QQC2.Button {
                    id: delegate

                    required property Discover.DiscoverAction modelData

                    Layout.alignment: Qt.AlignHCenter

                    action: ConvertDiscoverAction {
                        action: delegate.modelData
                    }
                }
            }
        }
    }

    signal clearSearch()

    // App Store: macOS's Discover page. A large title, a row of large
    // editorial cards (the featured apps), then shelves of apps with a
    // See All each.
    ColumnLayout {
        id: apps

        readonly property bool ready: !featuredModel.isFetching
        readonly property int pageSize: 9

        spacing: Kirigami.Units.gridUnit * 1.5

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 1
            font.weight: Font.Bold
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 2.1
            text: i18nc("@title the App Store's front page", "Discover")
        }

        // The featured apps, two to a view, scrolled sideways.
        Item {
            Layout.fillWidth: true
            implicitHeight: Kirigami.Units.gridUnit * 14
            visible: featuredRep.count > 0 && apps.ready

            ListView {
                id: featuredRep
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: Kirigami.Units.gridUnit
                snapMode: ListView.SnapToItem
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                model: featuredModel
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: width
                highlightMoveDuration: Kirigami.Units.longDuration
                delegate: MacFeatureCard {
                    required property var model
                    application: model.application
                    width: Math.max(Kirigami.Units.gridUnit * 18, (featuredRep.width - featuredRep.spacing) / 2)
                    height: featuredRep.height
                }
            }

            component Arrow: QQC2.RoundButton {
                property int step
                anchors.verticalCenter: parent.verticalCenter
                width: Kirigami.Units.gridUnit * 1.8
                height: width
                icon.name: step > 0 ? "go-next-symbolic" : "go-previous-symbolic"
                opacity: arrowsHover.hovered ? 1 : 0
                visible: step > 0 ? featuredRep.currentIndex < featuredRep.count - 1 : featuredRep.currentIndex > 0
                onClicked: featuredRep.currentIndex = Math.max(0, Math.min(featuredRep.count - 1, featuredRep.currentIndex + step))
                Behavior on opacity {
                    NumberAnimation { duration: Kirigami.Units.shortDuration }
                }
            }
            HoverHandler {
                id: arrowsHover
            }
            Arrow {
                step: -1
                anchors.left: parent.left
                anchors.leftMargin: Kirigami.Units.smallSpacing
            }
            Arrow {
                step: 1
                anchors.right: parent.right
                anchors.rightMargin: Kirigami.Units.smallSpacing
            }
        }

        MacShelf {
            id: popShelf
            Layout.fillWidth: true
            visible: count > 0 && apps.ready
            title: i18nc("@title:group", "Most Popular")
            model: DiscoverApp.LimitedRowCountProxyModel {
                pageSize: apps.pageSize
                sourceModel: DiscoverApp.OdrsAppsModel {
                }
            }
            seeAll: () => Navigation.openCategory(Discover.CategoryModel.findCategoryByName("All Applications"))
        }

        MacShelf {
            Layout.fillWidth: true
            visible: count > 0 && apps.ready
            title: i18nc("@title:group", "New & Updated")
            model: recentlyUpdatedModelInstantiator.object
        }

        Instantiator {
            id: recentlyUpdatedModelInstantiator

            active: {
                const backend = Discover.ResourcesModel.currentApplicationBackend;
                if (!backend) {
                    return false;
                }
                // TODO: Add packagekit-backend of rolling distros
                return [
                    "flatpak-backend",
                    "snap-backend",
                ].includes(backend.name);
            }

            DiscoverApp.LimitedRowCountProxyModel {
                pageSize: apps.pageSize
                sourceModel: Discover.ResourcesProxyModel {
                    filteredCategoryName: "All Applications"
                    backendFilter: Discover.ResourcesModel.currentApplicationBackend
                    sortRole: Discover.ResourcesProxyModel.ReleaseDateRole
                    sortOrder: Qt.DescendingOrder
                }
            }
        }

        // The themed shelves, as in the sidebar.
        Repeater {
            model: [
                { title: i18nc("@title:group", "Top Games"), category: "Games" },
                { title: i18nc("@title:group", "Create"), category: "Graphics" },
                { title: i18nc("@title:group", "Work"), category: "Office" },
                { title: i18nc("@title:group", "Developer Tools"), category: "Development" },
            ]
            delegate: MacShelf {
                id: themed
                required property var modelData
                Layout.fillWidth: true
                visible: count > 0 && apps.ready
                title: modelData.title
                model: DiscoverApp.LimitedRowCountProxyModel {
                    pageSize: apps.pageSize
                    sourceModel: Discover.ResourcesProxyModel {
                        filteredCategoryName: themed.modelData.category
                        backendFilter: Discover.ResourcesModel.currentApplicationBackend
                        sortRole: Discover.ResourcesProxyModel.SortableRatingRole
                        sortOrder: Qt.DescendingOrder
                    }
                }
                seeAll: () => Navigation.openCategory(Discover.CategoryModel.findCategoryByName(themed.modelData.category))
            }
        }
    }
}
