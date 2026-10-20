// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

// The window's close, minimize and zoom buttons, as on macOS: glyphs on
// hover, gray while the window is inactive. Sized like the window
// decorations' (MacSequoia draws ~22 px circles 35 px apart at 1.5×), so
// all windows' stoplights match (Settings, Finder).
Row {
    id: lights

    required property var chrome

    spacing: 8.8
    readonly property bool lit: chrome.active || lightsHover.hovered

    HoverHandler {
        id: lightsHover
    }

    Repeater {
        model: [
            { color: "#ff5f57", kind: "close", action: () => lights.chrome.close() },
            { color: "#febc2e", kind: "minimize", action: () => lights.chrome.minimize() },
            { color: "#28c840", kind: "zoom", action: () => lights.chrome.toggleMaximized() }
        ]
        delegate: Rectangle {
            id: light
            required property var modelData
            width: 14.5
            height: width
            radius: width / 2
            color: !lights.lit ? "#505054" : lightMouse.pressed ? Qt.darker(modelData.color, 1.25) : modelData.color
            border.width: 0.5
            border.color: Qt.rgba(0, 0, 0, 0.2)

            // The glyph, drawn (a font's ×, − and + never sit quite in the
            // middle): ×, −, and the zoom's two arrows, as Finder.
            Shape {
                id: glyph
                anchors.fill: parent
                visible: lightsHover.hovered
                preferredRendererType: Shape.CurveRenderer
                readonly property real c: light.width / 2
                readonly property real k: 2.6 * light.width / 12

                ShapePath {
                    strokeColor: light.modelData.kind === "zoom" ? "transparent" : Qt.rgba(0, 0, 0, 0.6)
                    strokeWidth: 1.4
                    fillColor: light.modelData.kind === "zoom" ? Qt.rgba(0, 0, 0, 0.6) : "transparent"
                    capStyle: ShapePath.RoundCap
                    PathSvg {
                        readonly property real c: glyph.c
                        readonly property real k: glyph.k
                        readonly property real t: 3.2 * light.width / 12
                        readonly property real u: 1.2 * light.width / 12
                        path: light.modelData.kind === "close"
                            ? `M ${c - k} ${c - k} L ${c + k} ${c + k} M ${c - k} ${c + k} L ${c + k} ${c - k}`
                            : light.modelData.kind === "minimize"
                            ? `M ${c - k - 0.4} ${c} L ${c + k + 0.4} ${c}`
                            : `M ${c - t} ${c - t} L ${c + u} ${c - t} L ${c - t} ${c + u} Z M ${c + t} ${c + t} L ${c - u} ${c + t} L ${c + t} ${c - u} Z`
                    }
                }
            }
            MouseArea {
                id: lightMouse
                anchors.fill: parent
                anchors.margins: -3
                onClicked: light.modelData.action()
            }
        }
    }
}
