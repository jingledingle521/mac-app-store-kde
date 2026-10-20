// SPDX-FileCopyrightText: 2026 Brhett
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.discover as Discover

// App Store: MAC_TEST_TOUR=<dir> visits the main pages and saves a picture
// of the window for each (StoreChrome.snap), then quits. For checking the
// look without touching the mouse or keyboard. MAC_TEST_TOUR_ONLY=<a,b>
// limits it to those pictures.
Timer {
    id: tour

    required property var chrome
    required property var drawer

    readonly property var only: chrome.testTourOnly()
    readonly property var steps: [
        ["home", () => drawer.openSection(drawer.sections[0])],
        ["create", () => drawer.openSection(drawer.sections[1])],
        ["categories", () => drawer.openSection(drawer.sections[5])],
        ["category-link", () => app.openCategory("Games")],
        ["app", () => app.openApplication("appstream://org.kde.krita")],
        ["search", () => drawer.search("paint")],
        ["updates", () => { drawer.search(""); drawer.openSection(drawer.sections[6]); }],
        ["installed", () => { drawer.selectedKey = "installed"; window.currentTopLevel = window.topInstalledComp; }],
        ["sources", () => { drawer.selectedKey = "sources"; window.currentTopLevel = window.topSourcesComp; }],
    ].filter(step => only.length === 0 || only.includes(step[0]))
    property int step: -1

    interval: 9000 // let the backends load first
    running: true
    repeat: true
    onTriggered: {
        if (step >= 0) {
            chrome.snap(steps[step][0]);
        }
        step++;
        if (step >= steps.length) {
            running = false;
            Qt.quit();
            return;
        }
        steps[step][1]();
        interval = 4500;
    }
}
