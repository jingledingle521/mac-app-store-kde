// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Shapes
import org.kde.discover as Discover
import org.kde.kirigami as Kirigami

// App Store: macOS's Get button. A capsule reading Get (not installed),
// Open (installed, can be launched) or Installed; while installing, a ring
// filling with progress around a stop square (click to cancel). In lists it
// is gray with the label in the accent colour; `prominent` (an app's page)
// fills it with the accent and the label turns white.
Item {
    id: root

    required property Discover.AbstractResource application
    property bool prominent: false
    // Over a picture: a light, translucent capsule with a white label.
    property bool onDark: false

    readonly property alias listener: listener
    readonly property bool busy: listener.isActive
    readonly property bool broken: application.state === Discover.AbstractResource.Broken
    readonly property bool canOpen: application.isInstalled && application.canExecute

    readonly property string label: {
        if (broken) {
            return i18nc("@action:button the app's state is still being fetched", "…");
        }
        if (!application.isInstalled) {
            return i18nc("@action:button install an app", "Get");
        }
        return canOpen ? i18nc("@action:button launch an app", "Open")
                       : i18nc("@info the app is installed", "Installed");
    }

    function click() {
        if (busy) {
            if (listener.isCancellable) {
                listener.cancel();
            }
        } else if (!application.isInstalled) {
            Discover.ResourcesModel.installApplication(application);
        } else if (canOpen) {
            application.invokeApplication();
        }
    }

    implicitWidth: busy ? ring.width : Math.max(Kirigami.Units.gridUnit * 3.6, text.implicitWidth + Kirigami.Units.gridUnit * 1.4)
    implicitHeight: Math.round(text.implicitHeight + Kirigami.Units.smallSpacing * 2.2)

    Accessible.role: Accessible.Button
    Accessible.name: busy ? i18nc("@action:button", "Stop") : label
    Accessible.onPressAction: click()

    Discover.TransactionListener {
        id: listener
        resource: root.application
    }

    // The capsule.
    Rectangle {
        anchors.fill: parent
        visible: !root.busy
        radius: height / 2
        color: {
            if (root.onDark) {
                return Qt.rgba(1, 1, 1, mouse.pressed ? 0.4 : mouse.containsMouse ? 0.32 : 0.24);
            }
            const t = Kirigami.Theme.textColor;
            if (root.prominent && !root.application.isInstalled) {
                return mouse.pressed ? Qt.darker(Kirigami.Theme.focusColor, 1.15) : Kirigami.Theme.focusColor;
            }
            return Qt.rgba(t.r, t.g, t.b, mouse.pressed ? 0.22 : mouse.containsMouse ? 0.17 : 0.12);
        }
        opacity: root.broken ? 0.5 : 1

        QQC2.Label {
            id: text
            anchors.centerIn: parent
            text: root.label
            font.weight: Font.Bold
            font.capitalization: Font.AllUppercase
            color: root.onDark || (root.prominent && !root.application.isInstalled) ? "white"
                 : root.application.isInstalled && !root.canOpen ? Kirigami.Theme.disabledTextColor
                 : Kirigami.Theme.focusColor
        }
    }

    // Installing: a ring filling up around a stop square.
    Item {
        id: ring
        anchors.centerIn: parent
        visible: root.busy
        width: root.height
        height: width

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                strokeWidth: 2.5
                fillColor: "transparent"
                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: ring.width / 2 - 2
                    radiusY: radiusX
                    startAngle: 0
                    sweepAngle: 360
                }
            }
            ShapePath {
                strokeColor: Kirigami.Theme.focusColor
                strokeWidth: 2.5
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: ring.width / 2 - 2
                    radiusY: radiusX
                    startAngle: -90
                    sweepAngle: 360 * Math.max(0.02, listener.progress / 100)
                }
            }
        }
        Rectangle {
            anchors.centerIn: parent
            visible: listener.isCancellable
            width: ring.width * 0.3
            height: width
            radius: 1.5
            color: Kirigami.Theme.focusColor
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.broken && (root.busy || !root.application.isInstalled || root.canOpen)
        onClicked: root.click()
    }

    QQC2.ToolTip.text: listener.statusText
    QQC2.ToolTip.visible: root.busy && mouse.containsMouse
    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
}
