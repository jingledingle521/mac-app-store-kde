pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.discover as Discover
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami
import org.kde.kirigami.delegates as KD

DiscoverPage {
    id: page

    property string search
    readonly property string name: title

    clip: true
    title: i18n("Settings")
    // App Store: the title is drawn large in the list (macOS's).
    readonly property bool macOwnTitle: true

    Kirigami.Action {
        id: configureUpdatesAction
        text: i18n("Configure Updates…")
        displayHint: Kirigami.DisplayHint.AlwaysHide
        onTriggered: {
            KCMUtils.KCMLauncher.openSystemSettings("kcm_updates");
        }
    }

    actions: feedbackLoader.item?.actions ?? [configureUpdatesAction]

    header: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        // App Store: the large title, above the list (sources that load
        // later are inserted at the list's top and would slide under a
        // list header).
        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit * 1.5
            Layout.rightMargin: Kirigami.Units.gridUnit * 1.5
            level: 1
            font.weight: Font.Bold
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 2.1
            text: page.title
            elide: Text.ElideRight
        }

        Repeater {
            model: Discover.SourcesModel.sources

            delegate: Kirigami.InlineMessage {
                id: delegate

                required property Discover.AbstractSourcesBackend modelData

                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                text: modelData.inlineAction?.toolTip ?? ""
                visible: modelData.inlineAction?.visible ?? false
                actions: Kirigami.Action {
                    icon.name: delegate.modelData.inlineAction?.iconName ?? ""
                    text: delegate.modelData.inlineAction?.text ?? ""
                    onTriggered: delegate.modelData.inlineAction?.trigger()
                }
            }
        }
    }

    ListView {
        id: sourcesView

        // App Store: a list isn't padded by the page; keep it off the sidebar.
        readonly property real innerWidth: width - leftMargin - rightMargin
        leftMargin: Kirigami.Units.gridUnit * 1.5
        rightMargin: Kirigami.Units.gridUnit * 1.5

        model: Discover.SourcesModel
        Component.onCompleted: Qt.callLater(Discover.SourcesModel.showingNow)
        // App Store: start at the title while the sources load, not wherever
        // the rows settle; until the user scrolls.
        property bool userScrolled: false
        onMovementStarted: userScrolled = true
        // (Sources load above the first ones too, and the list keeps what's
        // on screen in place by moving its origin.)
        onOriginYChanged: if (!userScrolled) {
            contentY = originY;
        }
        onContentHeightChanged: if (!userScrolled) {
            contentY = originY;
        }
        currentIndex: -1
        pixelAligned: true
        section.property: "sourceName"
        section.delegate: Kirigami.ListSectionHeader {
            id: backendItem

            required property string section

            height: Math.ceil(Math.max(Kirigami.Units.gridUnit * 2.5, contentItem.implicitHeight)) + topPadding
            topPadding: Kirigami.Units.gridUnit
            leftPadding: Kirigami.Units.smallSpacing
            rightPadding: 0

            readonly property Discover.AbstractSourcesBackend backend: Discover.SourcesModel.sourcesBackendByName(section)
            readonly property Discover.AbstractResourcesBackend resourcesBackend: backend.resourcesBackend
            readonly property bool isDefault: Discover.ResourcesModel.currentApplicationBackend === resourcesBackend

            width: sourcesView.innerWidth

            Connections {
                target: backendItem.backend
                function onPassiveMessage(message) {
                    window.showPassiveNotification(message)
                }
                function onProceedRequest(title, description) {
                    const dialog = sourceProceedDialog.createObject(window, {
                        sourcesBackend: backendItem.backend,
                        title,
                        description,
                    })
                    dialog.open()
                }
            }

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Heading {
                    text: resourcesBackend.displayName
                    level: 3
                    font.weight: Font.Bold
                }

                Kirigami.ActionToolBar {
                    id: actionBar

                    alignment: Qt.AlignRight

                    Kirigami.Action {
                        id: isDefaultbackendLabelAction

                        visible: backendItem.isDefault
                        displayHint: Kirigami.DisplayHint.KeepVisible
                        displayComponent: QQC2.Label {
                            text: i18n("Default Source")
                            opacity: 0.6
                        }
                    }

                    Kirigami.Action {
                        id: addSourceAction
                        text: i18n("Add Source…")
                        icon.name: "list-add"
                        visible: backendItem.backend && backendItem.backend.supportsAdding

                        onTriggered: {
                            const addSourceDialog = dialogComponent.createObject(window, {
                                displayName: backendItem.backend.resourcesBackend.displayName,
                            })
                            addSourceDialog.open()
                        }
                    }

                    Component {
                        id: dialogComponent
                        AddSourceDialog {
                            source: backendItem.backend

                            onClosed: {
                                destroy();
                            }
                        }
                    }

                    Kirigami.Action {
                        id: makeDefaultAction
                        visible: resourcesBackend && resourcesBackend.hasApplications && !backendItem.isDefault

                        text: i18n("Make Default")
                        icon.name: "favorite"
                        onTriggered: Discover.ResourcesModel.currentApplicationBackend = backendItem.backend.resourcesBackend
                    }

                    Component {
                        id: kirigamiAction
                        ConvertDiscoverAction {}
                    }

                    function mergeActions(moreActions) {
                        const actions = [
                            isDefaultbackendLabelAction,
                            makeDefaultAction,
                            addSourceAction
                        ]
                        for (const action of moreActions) {
                            actions.push(kirigamiAction.createObject(this, { action }))
                        }
                        return actions;
                    }
                    actions: mergeActions(backendItem.backend.actions)
                }
            }
        }

        Component {
            id: sourceProceedDialog
            Kirigami.OverlaySheet {
                id: sheet

                property Discover.AbstractSourcesBackend sourcesBackend
                property alias description: descriptionLabel.text
                property bool acted: false

                parent: page.QQC2.Overlay.overlay
                showCloseButton: false

                implicitWidth: Kirigami.Units.gridUnit * 30

                Kirigami.SelectableLabel {
                    id: descriptionLabel
                    width: parent.width
                    textFormat: TextEdit.RichText
                    wrapMode: TextEdit.Wrap
                }

                footer: QQC2.DialogButtonBox {
                    QQC2.Button {
                        QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole
                        text: i18n("Proceed")
                        icon.name: "dialog-ok"
                    }

                    QQC2.Button {
                        QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.RejectRole
                        text: i18n("Cancel")
                        icon.name: "dialog-cancel"
                    }

                    onAccepted: {
                        sheet.sourcesBackend.proceed()
                        sheet.acted = true
                        sheet.close()
                    }

                    onRejected: {
                        sheet.sourcesBackend.cancel()
                        sheet.acted = true
                        sheet.close()
                    }
                }

                onOpened: {
                    descriptionLabel.forceActiveFocus(Qt.PopupFocusReason);
                }

                onClosed: {
                    if (!acted) {
                        sourcesBackend.cancel()
                    }
                    destroy();
                }
            }
        }

        delegate: QQC2.ItemDelegate {
            id: delegate

            required property int index
            required property var model

            enabled: model.display.length > 0 && model.enabled
            highlighted: ListView.isCurrentItem
            visible: model.display.indexOf(page.search) >= 0
            height: visible ? implicitHeight : 0
            width: sourcesView.innerWidth
            leftPadding: Kirigami.Units.largeSpacing
            rightPadding: Kirigami.Units.largeSpacing
            topInset: 0
            bottomInset: 0
            leftInset: 0
            rightInset: 0

            // App Store: each source's rows share a rounded panel, as macOS's
            // settings group them; hairlines between rows.
            readonly property bool firstInGroup: ListView.previousSection !== ListView.section
            readonly property bool lastInGroup: ListView.nextSection !== ListView.section
            background: Kirigami.ShadowedRectangle {
                readonly property real r: 10
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                corners.topLeftRadius: delegate.firstInGroup ? r : 0
                corners.topRightRadius: delegate.firstInGroup ? r : 0
                corners.bottomLeftRadius: delegate.lastInGroup ? r : 0
                corners.bottomRightRadius: delegate.lastInGroup ? r : 0
                Rectangle {
                    visible: !delegate.lastInGroup
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Kirigami.Units.largeSpacing
                    anchors.rightMargin: Kirigami.Units.largeSpacing
                    height: 1
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
                }
            }

            Keys.onReturnPressed: enabledBox.clicked()
            Keys.onSpacePressed: enabledBox.clicked()
            // App Store: the row's actions in a ⋯ menu (macOS's), not swiped in.
            readonly property list<Kirigami.Action> rowActions: [
                Kirigami.Action {
                    icon.name: "go-up"
                    tooltip: i18n("Increase priority")
                    enabled: delegate.model.sourcesBackend.firstDisambiguatedSourceId !== delegate.model.disambiguatedSourceId
                    visible: delegate.model.sourcesBackend.canMoveSources
                    onTriggered: {
                        const ret = delegate.model.sourcesBackend.moveSource(delegate.model.disambiguatedSourceId, -1)
                        if (!ret) {
                            window.showPassiveNotification(i18n("Failed to increase '%1' preference", delegate.model.display))
                        }
                    }
                },
                Kirigami.Action {
                    icon.name: "go-down"
                    tooltip: i18n("Decrease priority")
                    enabled: delegate.model.sourcesBackend.lastDisambiguatedSourceId !== delegate.model.disambiguatedSourceId
                    visible: delegate.model.sourcesBackend.canMoveSources
                    onTriggered: {
                        const ret = delegate.model.sourcesBackend.moveSource(delegate.model.disambiguatedSourceId, +1)
                        if (!ret) {
                            window.showPassiveNotification(i18n("Failed to decrease '%1' preference", delegate.model.display))
                        }
                    }
                },
                Kirigami.Action {
                    icon.name: "edit-delete"
                    tooltip: i18n("Remove repository")
                    visible: delegate.model.sourcesBackend.supportsAdding
                    onTriggered: {
                        const backend = delegate.model.sourcesBackend
                        if (!backend.removeSource(delegate.model.disambiguatedSourceId)) {
                            console.warn("Failed to remove the source", delegate.model.display)
                        }
                    }
                },
                Kirigami.Action {
                    icon.name: delegate.mirrored ? "go-next-symbolic-rtl" : "go-next-symbolic"
                    tooltip: i18n("Show contents")
                    visible: delegate.model.sourcesBackend.canFilterSources
                    onTriggered: {
                        Navigation.openApplicationListSource(delegate.model.disambiguatedSourceId, delegate.model.display)
                    }
                }
            ]

            contentItem: RowLayout {
                spacing: Kirigami.Units.largeSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    Layout.bottomMargin: Kirigami.Units.smallSpacing
                    spacing: 0
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: delegate.model.display
                        elide: Text.ElideRight
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: delegate.model.toolTip ?? ""
                        font: Kirigami.Theme.smallFont
                        opacity: 0.6
                        elide: Text.ElideRight
                    }
                }
                QQC2.ToolButton {
                    id: moreButton
                    visible: delegate.rowActions.some(action => action.visible)
                    icon.name: "overflow-menu"
                    display: QQC2.AbstractButton.IconOnly
                    text: i18nc("@action:button", "More")
                    onClicked: rowMenu.popup(moreButton, 0, moreButton.height)
                    QQC2.Menu {
                        id: rowMenu
                        Repeater {
                            model: delegate.rowActions
                            delegate: QQC2.MenuItem {
                                required property Kirigami.Action modelData
                                visible: modelData?.visible ?? false
                                height: visible ? implicitHeight : 0
                                enabled: modelData?.enabled ?? false
                                icon.name: modelData?.icon.name ?? ""
                                text: modelData?.tooltip ?? ""
                                onTriggered: modelData?.trigger()
                            }
                        }
                    }
                }
                QQC2.Switch {
                    id: enabledBox

                    readonly property var idx: index !== -1 ? sourcesView.model.index(index, 0) : null
                    readonly property /*Qt::CheckState*/int modelChecked: delegate.model.checkState
                    checked: modelChecked !== Qt.Unchecked
                    enabled: idx && sourcesView.model.flags(idx) & Qt.ItemIsUserCheckable
                    onClicked: if (idx) {
                        sourcesView.model.setData(idx, checkState, Qt.CheckStateRole)
                        checked = Qt.binding(() => (modelChecked !== Qt.Unchecked))
                    }
                    QQC2.ToolTip.text: i18nc("@info:tooltip", "Enable this source")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
        }

        footer: ColumnLayout {
            spacing: 0
            width: sourcesView.innerWidth

            Kirigami.ListSectionHeader {
                Layout.fillWidth: true

                visible: back.count > 0
                text: i18n("Missing Backends")
            }

            Repeater {
                id: back
                model: Discover.ResourcesProxyModel {
                    extending: "org.kde.discover.desktop"
                    filterMinimumState: false
                    stateFilter: Discover.AbstractResource.None
                }
                delegate: QQC2.ItemDelegate {
                    id: delegate

                    required property int index
                    required property var model
                    required property string name

                    Layout.fillWidth: true
                    background: null
                    hoverEnabled: false
                    down: false

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        KD.IconTitleSubtitle {
                            title: name
                            icon.source: delegate.model.icon
                            subtitle: delegate.model.comment
                            Layout.fillWidth: true
                        }
                        InstallApplicationButton {
                            application: delegate.model.application
                        }
                    }
                }
            }
        }
    }
}
