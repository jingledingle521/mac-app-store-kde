/*
 *   SPDX-FileCopyrightText: 2012 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
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

    readonly property var model: appsModel
    property alias category: appsModel.filteredCategory
    property alias sortRole: appsModel.sortRole
    property alias sortOrder: appsModel.sortOrder
    property alias originFilter: appsModel.originFilter
    property alias mimeTypeFilter: appsModel.mimeTypeFilter
    property alias stateFilter: appsModel.stateFilter
    property alias extending: appsModel.extending
    property alias search: appsModel.search
    property alias resourcesUrl: appsModel.resourcesUrl
    property alias busy: appsModel.busy
    property alias allBackends: appsModel.allBackends
    property alias count: appsView.count
    property alias listHeader: appsView.header
    property int listHeaderPositioning: ListView.InlineHeader // unused: a GridView here
    property string sortProperty: "appsListPageSorting"
    property bool showRating: true
    property bool showSize: false
    property bool searchPage: false

    property bool canNavigate: true
    readonly property alias subcategories: appsModel.subcategories
    readonly property Discover.Category categoryObject: Discover.CategoryModel.get(page.category)

    property bool canCategorize: false
    // App Store: the apps are a grid, which can't group them by type.
    readonly property bool categorize: false

    function stripHtml(input) {
        var regex = /(<([^>]+)>)/ig
        return input.replace(regex, "");
    }

    property string name: categoryObject?.name ?? ""

    // App Store: the category's name, or what was searched for, as a
    // large title above the apps (macOwnTitle: not in the toolbar too).
    title: {
        if (search.length > 0) {
            return i18nc("@title %1 is what was searched for", "Results for “%1”", stripHtml(search));
        }
        return name.length > 0 ? name : i18n("Search");
    }
    readonly property bool macOwnTitle: true

    signal clearSearch()

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    onSearchChanged: {
        if (search.length > 0) {
            appsModel.tempSortRole = Discover.ResourcesProxyModel.SearchRelevanceRole
        } else {
            appsModel.tempSortRole = -1
        }
    }

    supportsRefreshing: true
    onRefreshingChanged: if (refreshing) {
        appsModel.invalidateFilter()
        refreshing = false
    }

    QQC2.ActionGroup {
        id: sortGroup
        exclusive: true
    }

    actions: [
        Kirigami.Action {
            text: i18n("Sort: %1", sortGroup.checkedAction.text)
            icon.name: "view-sort"
            Kirigami.Action {
                visible: appsModel.search.length > 0
                QQC2.ActionGroup.group: sortGroup
                text: i18nc("Search results most relevant to the search query", "Relevance")
                icon.name: "file-search-symbolic"
                onTriggered: {
                    // Do *not* save the sort role on searches
                    appsModel.tempSortRole = Discover.ResourcesProxyModel.SearchRelevanceRole
                }
                checkable: true
                checked: appsModel.sortRole === Discover.ResourcesProxyModel.SearchRelevanceRole
            }
            Kirigami.Action {
                QQC2.ActionGroup.group: sortGroup
                text: i18n("Name")
                icon.name: "sort-name"
                onTriggered: {
                    DiscoverApp.DiscoverSettings[page.sortProperty] = Discover.ResourcesProxyModel.NameRole
                    appsModel.tempSortRole = -1
                }
                checkable: true
                checked: appsModel.sortRole === Discover.ResourcesProxyModel.NameRole
            }
            Kirigami.Action {
                QQC2.ActionGroup.group: sortGroup
                text: i18n("Number of reviews")
                icon.name: "view-pages-overview-symbolic"
                onTriggered: {
                    DiscoverApp.DiscoverSettings[page.sortProperty] = Discover.ResourcesProxyModel.RatingCountRole
                    appsModel.tempSortRole = -1
                }
                checkable: true
                checked: appsModel.sortRole === Discover.ResourcesProxyModel.RatingCountRole
            }
            Kirigami.Action {
                QQC2.ActionGroup.group: sortGroup
                text: i18nc("@item:inmenu sort by highest-rated apps", "Rating")
                icon.name: "rating"
                onTriggered: {
                    DiscoverApp.DiscoverSettings[page.sortProperty] = Discover.ResourcesProxyModel.SortableRatingRole
                    appsModel.tempSortRole = -1
                }
                checkable: true
                checked: appsModel.sortRole === Discover.ResourcesProxyModel.SortableRatingRole
            }
            Kirigami.Action {
                QQC2.ActionGroup.group: sortGroup
                text: i18n("Size")
                icon.name: "download"
                onTriggered: {
                    DiscoverApp.DiscoverSettings[page.sortProperty] = Discover.ResourcesProxyModel.SizeRole
                    appsModel.tempSortRole = -1
                }
                checkable: true
                checked: appsModel.sortRole === Discover.ResourcesProxyModel.SizeRole
            }
            Kirigami.Action {
                QQC2.ActionGroup.group: sortGroup
                text: i18n("Release date")
                icon.name: "change-date-symbolic"
                onTriggered: {
                    DiscoverApp.DiscoverSettings[page.sortProperty] = Discover.ResourcesProxyModel.ReleaseDateRole
                    appsModel.tempSortRole = -1
                }
                checkable: true
                checked: appsModel.sortRole === Discover.ResourcesProxyModel.ReleaseDateRole
            }
            Kirigami.Action {
                separator: true
                visible: false
            }
            Kirigami.Action {
                id: categorizeAction
                visible: false
                text: i18nc("@info", "Group by Type")
                checkable: true
                checked: DiscoverApp.DiscoverSettings.installedPageCategorize
                onToggled: DiscoverApp.DiscoverSettings.installedPageCategorize = checked
            }
        }
    ]

    // App Store: apps in columns, as macOS lists a category or a search.
    GridView {
        id: appsView

        // A grid isn't padded by the page; keep it off the sidebar.
        readonly property real innerWidth: width - leftMargin - rightMargin
        readonly property int columns: Math.max(1, Math.min(3, Math.floor(innerWidth / (Kirigami.Units.gridUnit * 14))))

        leftMargin: Kirigami.Units.gridUnit * 1.5
        rightMargin: Kirigami.Units.gridUnit * 1.5
        cellWidth: Math.floor(innerWidth / columns)
        cellHeight: Kirigami.Units.gridUnit * 4.6
        activeFocusOnTab: true
        currentIndex: -1
        focus: true
        keyNavigationEnabled: true
        boundsBehavior: Flickable.StopAtBounds

        header: Kirigami.Heading {
            width: appsView.innerWidth
            bottomPadding: Kirigami.Units.gridUnit
            level: 1
            font.weight: Font.Bold
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 2.1
            text: page.title
            elide: Text.ElideRight
        }
        footer: Item {
            id: appViewFooter
            height: appsModel.busy ? Kirigami.Units.gridUnit * 8 : Kirigami.Units.gridUnit
            width: appsView.innerWidth
        }
        onActiveFocusChanged: if (activeFocus && currentIndex === -1) {
            currentIndex = 0;
        }

        model: Discover.ResourcesProxyModel {
            id: appsModel
            property int tempSortRole: -1
            sortRole: tempSortRole >= 0 ? tempSortRole : DiscoverApp.DiscoverSettings.appsListPageSorting
            sortOrder: sortRole === Discover.ResourcesProxyModel.NameRole ? Qt.AscendingOrder : Qt.DescendingOrder
            categorize: page.categorize

            onBusyChanged: {
                if (busy) {
                    appsView.currentIndex = -1
                }
            }
        }

        delegate: Item {
            id: cell
            required property int index
            required property Discover.AbstractResource application

            width: appsView.cellWidth
            height: appsView.cellHeight

            MacAppRow {
                anchors.fill: parent
                anchors.rightMargin: (cell.index % appsView.columns) < appsView.columns - 1 ? Kirigami.Units.gridUnit * 1.5 : 0
                application: cell.application
                detail: page.showSize ? cell.application.sizeDescription : cell.application.comment
                focus: appsView.currentIndex === cell.index
            }
        }

        Item {
            readonly property bool nothingFound: appsView.count == 0 && !appsModel.busy && !Discover.ResourcesModel.isInitializing && (!page.searchPage || appsModel.search.length > 0)

            anchors.fill: parent
            opacity: nothingFound ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad } }

            Kirigami.PlaceholderMessage {
                visible: !searchedForThingNotFound.visible
                anchors.centerIn: visible ? parent : undefined
                width: parent.width - (Kirigami.Units.largeSpacing * 8)

                icon.name: "edit-none"
                text: i18n("Nothing found")
            }

            Kirigami.PlaceholderMessage {
                id: searchedForThingNotFound

                Kirigami.Action {
                    id: searchAllCategoriesAction
                    text: i18nc("@action:button", "Search in All Categories")
                    icon.name: "search"
                    onTriggered: {
                        window.globalDrawer.resetMenu();
                        Navigation.clearStack()
                        Navigation.openApplicationList({ search: page.search });
                    }
                }
                Kirigami.Action {
                    id: searchTheWebAction
                    text: i18nc("@action:button %1 is the name of an application", "Search the Web for \"%1\"", appsModel.search)
                    icon.name: "internet-web-browser"
                    onTriggered: {
                        const searchTerm = encodeURIComponent(Qt.platform.os + " " + appsModel.search);
                        Qt.openUrlExternally(app.searchUrl(searchTerm));
                    }
                }

                anchors.centerIn: parent
                width: parent.width - (Kirigami.Units.largeSpacing * 8)

                visible: appsModel.search.length > 0 && stateFilter !== Discover.AbstractResource.Installed

                icon.name: "edit-none"
                text: page.categoryObject ? i18nc("@info:placeholder %1 is the name of an application; %2 is the name of a category of apps or add-ons",
                                            "\"%1\" was not found in the \"%2\" category", appsModel.search, page.categoryObject.name)
                                    : i18nc("@info:placeholder %1 is the name of an application",
                                            "\"%1\" was not found in the available sources", appsModel.search)
                explanation: page.categoryObject ? "" : i18nc("@info:placeholder %1 is the name of an application", "\"%1\" may be available on the web. Software acquired from the web has not been reviewed by your distributor for functionality or stability. Use with caution.", appsModel.search)

                // If we're in a category, first direct the user to search globally,
                // because they might not have realized they were in a category and
                // therefore the results were limited to just what was in the category
                helpfulAction: page.categoryObject ? searchAllCategoriesAction : searchTheWebAction
            }
        }

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - (Kirigami.Units.largeSpacing * 4)

            visible: opacity !== 0
            opacity: appsView.count === 0 && page.searchPage && appsModel.search.length === 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.InOutQuad } }

            icon.name: "search"
            text: i18n("Search")
        }

        Item {
            id: loadingHolder
            parent: appsView.count === 0 ? appsView : appsView.footerItem
            anchors.fill: parent
            visible: appsModel.busy && (appsView.count === 0 || appsView.atYEnd)
            ColumnLayout {
                anchors.centerIn: parent
                opacity: parent.visible ? 0.5 : 0
                Kirigami.Heading {
                    id: headingText
                    Layout.alignment: Qt.AlignCenter
                    level: 2
                    text: i18n("Still looking…")
                }
                QQC2.BusyIndicator {
                    id: busyIndicator
                    Layout.alignment: Qt.AlignCenter
                    running: parent.visible
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                }
                Behavior on opacity {
                    PropertyAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad }
                }
            }
        }
    }
}
