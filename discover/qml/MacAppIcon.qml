// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.discover as Discover
import org.kde.kirigami as Kirigami

// App Store: an app's icon, from the icon theme by its AppStream id when the
// theme has one (macOS-styled themes like WhiteSur restyle app icons; and
// Fedora's Flatpak catalog leaves some apps without one), else Discover's.
Item {
    id: root

    required property Discover.AbstractResource application
    property bool animated: false

    implicitWidth: Kirigami.Units.iconSizes.large
    implicitHeight: implicitWidth

    readonly property string themeName: root.application.appstreamId.replace(/\.desktop$/, "")
    readonly property bool themed: app.hasThemeIcon(themeName)

    Kirigami.Icon {
        anchors.fill: parent
        visible: root.themed
        source: visible ? root.themeName : ""
        animated: root.animated
    }
    Kirigami.Icon {
        anchors.fill: parent
        visible: !root.themed
        source: root.application.icon
        animated: root.animated
    }
}
