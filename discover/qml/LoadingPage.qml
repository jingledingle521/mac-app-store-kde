import org.kde.kirigami as Kirigami

Kirigami.Page {
    readonly property bool isHome: true

    title: placeholder.text
    // App Store: the window paints the background.
    background: null

    Kirigami.LoadingPlaceholder {
        id: placeholder
        anchors.centerIn: parent
    }
}
