// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.coreaddons as KCoreAddons
import org.kde.discover as Discover
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents

// App Store: macOS's App Store sidebar. The stoplights and the search field
// at the top, then Discover, the four themed shelves (Create, Work, Play,
// Develop: KDE's Graphics, Office, Games and Development categories),
// Categories and Updates in the accent colour, and the account at the
// bottom (your installed apps), with Settings beside it. Pinned open: the
// window leaves room for it, and paints its glass (StoreChrome).
Kirigami.OverlayDrawer {
    id: drawer

    required property var chrome

    // DiscoverDrawer's interface, used across the app.
    readonly property var currentSubMenu: null
    property string currentSearchText
    // The item last picked (its key): sections, "installed" or "sources".
    property string selectedKey: "discover"

    function resetMenu() {
    }

    function suggestSearchText(text) {
        searchField.text = text;
        forceSearchFieldFocus();
    }

    function forceSearchFieldFocus() {
        searchField.forceActiveFocus();
    }

    readonly property var sections: [
        { key: "discover", name: i18nc("@title the App Store's front page", "Discover"), glyph: "starred-symbolic",
          run: () => { window.currentTopLevel = ""; window.currentTopLevel = window.topBrowsingComp; } },
        { key: "create", name: i18nc("@title apps for making things", "Create"), glyph: "draw-brush-symbolic", category: "Graphics" },
        { key: "work", name: i18nc("@title apps for working", "Work"), glyph: "folder-documents-symbolic", category: "Office" },
        { key: "play", name: i18nc("@title games", "Play"), glyph: "input-gaming-symbolic", category: "Games" },
        { key: "develop", name: i18nc("@title apps for developers", "Develop"), glyph: "code-context-symbolic", category: "Development" },
        { key: "categories", name: i18nc("@title", "Categories"), glyph: "view-grid-symbolic",
          run: () => { window.currentTopLevel = ""; window.currentTopLevel = window.topCategoriesComp; } },
        { key: "updates", name: i18nc("@title", "Updates"), glyph: "update-none-symbolic", badge: true,
          run: () => { window.currentTopLevel = window.topUpdateComp; } },
    ]

    function open(section) {
        selectedKey = section.key;
        if (section.category) {
            Navigation.openCategory(Discover.CategoryModel.findCategoryByName(section.category));
        } else {
            section.run();
        }
    }

    // Follow pages opened from elsewhere (Updates from a notification…).
    Connections {
        target: window
        function onCurrentTopLevelChanged() {
            const keys = {
                [window.topBrowsingComp]: "discover",
                [window.topCategoriesComp]: "categories",
                [window.topUpdateComp]: "updates",
                [window.topInstalledComp]: "installed",
                [window.topSourcesComp]: "sources",
            };
            if (keys[window.currentTopLevel]) {
                drawer.selectedKey = keys[window.currentTopLevel];
            }
        }
    }

    edge: Qt.application.layoutDirection === Qt.RightToLeft ? Qt.RightEdge : Qt.LeftEdge
    modal: false
    drawerOpen: true
    handleVisible: false
    width: Kirigami.Units.gridUnit * 13
    padding: 0
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0
    // The window paints the glass (StoreChrome blurs behind it).
    background: Item {}

    contentItem: ColumnLayout {
        spacing: 0

        // The stoplights; empty space up here moves the window.
        Item {
            Layout.fillWidth: true
            implicitHeight: Kirigami.Units.gridUnit * 2.6

            MouseArea {
                anchors.fill: parent
                onPressed: drawer.chrome.startMove()
                onDoubleClicked: drawer.chrome.toggleMaximized()
            }
            MacStoplights {
                chrome: drawer.chrome
                x: Kirigami.Units.largeSpacing + 2
                y: Kirigami.Units.largeSpacing + 2.5
            }
        }

        SearchField {
            id: searchField
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.bottomMargin: Kirigami.Units.largeSpacing

            focus: !Kirigami.InputMethod.willShowOnActive
            page: window.leftPage

            onCurrentSearchTextChanged: {
                if (currentSearchText.length > 0) {
                    drawer.selectedKey = "";
                }
                const curr = window.leftPage;
                if (window.pageStack.depth > 1) {
                    window.pageStack.pop();
                }
                if (currentSearchText === "" && (!curr || !curr.hasOwnProperty("search") || !curr.category)) {
                    if (drawer.selectedKey === "") {
                        drawer.open(drawer.sections[0]);
                    }
                } else if (!curr || !curr.hasOwnProperty("search")) {
                    Navigation.clearStack();
                    Navigation.openApplicationList({ search: currentSearchText });
                } else {
                    curr.search = currentSearchText;
                    curr.forceActiveFocus();
                }
                drawer.currentSearchText = currentSearchText;
            }
            Keys.onDownPressed: list.forceActiveFocus(Qt.TabFocusReason)
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: drawer.sections
            keyNavigationEnabled: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: MacSidebarRow {
                id: row
                required property var modelData
                width: ListView.view.width
                selected: drawer.selectedKey === modelData.key
                text: modelData.name
                glyph: modelData.glyph
                badge: modelData.badge && Discover.ResourcesModel.updatesCount > 0 ? Discover.ResourcesModel.updatesCount : 0
                busy: modelData.badge === true && Discover.ResourcesModel.fetchingUpdatesProgress < 100
                onClicked: drawer.open(modelData)
            }
        }

        // Installs and updates in progress.
        QQC2.Control {
            Layout.fillWidth: true
            visible: Discover.TransactionModel.count > 0
            padding: Kirigami.Units.largeSpacing
            contentItem: ProgressView {}
        }

        // The account: your installed apps; Settings beside it.
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing * 2
            spacing: 0

            KCoreAddons.KUser {
                id: user
            }

            MacSidebarRow {
                id: account
                Layout.fillWidth: true
                implicitHeight: Kirigami.Units.gridUnit * 2.6
                inset: 0
                selected: drawer.selectedKey === "installed"
                onClicked: {
                    drawer.selectedKey = "installed";
                    window.currentTopLevel = window.topInstalledComp;
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                    anchors.rightMargin: Kirigami.Units.smallSpacing * 2
                    spacing: Kirigami.Units.largeSpacing

                    KirigamiComponents.Avatar {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
                        Layout.preferredHeight: Layout.preferredWidth
                        source: user.faceIconUrl
                        name: user.fullName || user.loginName
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: user.fullName || user.loginName
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            color: account.selected ? "white" : Kirigami.Theme.textColor
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: i18nc("@label under the user's name: their installed apps", "Your Apps")
                            font: Kirigami.Theme.smallFont
                            elide: Text.ElideRight
                            opacity: 0.7
                            color: account.selected ? "white" : Kirigami.Theme.textColor
                        }
                    }
                }
            }

            QQC2.ToolButton {
                icon.name: "configure-symbolic"
                display: QQC2.AbstractButton.IconOnly
                text: i18nc("@action:button", "Settings")
                checked: drawer.selectedKey === "sources"
                onClicked: {
                    drawer.selectedKey = "sources";
                    window.currentTopLevel = window.topSourcesComp;
                }
                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
    }
}
