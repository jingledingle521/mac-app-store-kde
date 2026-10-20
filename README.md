# mac-app-store-kde

**App Store for KDE Plasma**: KDE's
[Discover](https://invent.kde.org/plasma/discover) laid out and styled like
macOS's App Store.

Based on Discover 6.7.5. Every change is a commit on top of the `v6.7.5`
tag, and the upstream code is marked `App Store:` where it was changed. The
backends (PackageKit, Flatpak, firmware, Plasma add-ons) are Discover's own,
so it installs, updates and removes the same software stock Discover does.

## What's different from Discover

- **Window**: frameless, rounded, with stoplights (close, minimize, zoom)
  in the corner, a native shadow, and a translucent glass sidebar that runs
  to the top of the window. Drag empty space at the top to move;
  double-click to zoom.
- **Sidebar**: a search field, then Discover, Create, Work, Play, Develop
  (KDE's Graphics, Office, Games and Development categories), Categories and
  Updates with a count badge; your account at the bottom (your installed
  apps), with Settings beside it. The selection follows whatever page is
  open, however it was opened.
- **Discover**: a large title, a row of big feature cards (screenshot, name,
  Get button), then shelves of apps in columns: Most Popular, New &
  Updated, Top Games, Create, Work, Developer Tools, each with See All.
- **Get button**: a capsule reading GET or OPEN; while installing, a ring
  filling up around a stop square (click to cancel).
- **App pages**: a big icon, name, description and developer, a filled GET
  button with Uninstall behind ⋯, and a strip of Ratings, Age, Size,
  Developer, License and Version above the screenshots.
- **Categories, search and Your Apps**: a large title and apps in columns;
  Categories is a grid of coloured tiles.
- **Updates**: "Available" with the count and size and an Update All pill.
- **Settings** (sources): grouped panels with switches, actions behind ⋯.
- **Icons**: taken from your icon theme by the app's id when it has one, so
  a macOS-styled theme (WhiteSur) restyles them like the dock.
- Colours follow your accent colour.

The macOS controls come from the MacGlass widget style in
[kde-mac-glass](https://github.com/jingledingle521/kde-mac-glass), which this
is part of.

## Install

```sh
sudo dnf builddep plasma-discover            # first time (Fedora)
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$HOME/.local/opt/appstore -DBUILD_TESTING=OFF
ninja -C build install
```

It installs next to the stock app. To have the desktop open it (the
launcher, update notifications), put a `plasma-discover` ahead of
`/usr/bin` in your `PATH`; it needs the backends' plugin folder:

```sh
cat > ~/.local/bin/plasma-discover <<'EOF'
#!/bin/sh
QT_PLUGIN_PATH="$HOME/.local/opt/appstore/lib64/plugins${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}" \
    exec "$HOME/.local/opt/appstore/bin/plasma-discover" "$@"
EOF
chmod +x ~/.local/bin/plasma-discover
```

Delete that file to go back to the stock app. kde-mac-glass's
`./install.sh --appstore` does all of this and names the menu entry
"App Store".

`MAC_TEST_TOUR=<dir> plasma-discover` visits the main pages, saves a
picture of each in `<dir>` and quits (`MAC_TEST_TOUR_ONLY=home,updates,…`
for some).

## Upstream

Discover is © the KDE community, and this keeps its licenses
(GPL-2.0-or-later and others; see [LICENSES](LICENSES)). The window frame is
shared with [finder-kde](https://github.com/jingledingle521/finder-kde) and
[mac-settings-kde](https://github.com/jingledingle521/mac-settings-kde). Not
affiliated with KDE or Apple.
