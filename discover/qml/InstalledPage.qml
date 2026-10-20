import QtQuick
import QtQuick.Layouts
import org.kde.discover as Discover
import org.kde.discover.app as DiscoverApp

ApplicationsListPage {
    id: page

    stateFilter: Discover.AbstractResource.Installed
    allBackends: true
    sortProperty: "installedPageSorting"
    sortRole: DiscoverApp.DiscoverSettings.installedPageSorting

    // App Store: the account's apps, as the sidebar calls them.
    name: i18nc("@title the apps you installed", "Your Apps")
    showRating: false
    showSize: true
    canNavigate: false
    canCategorize: true
}
