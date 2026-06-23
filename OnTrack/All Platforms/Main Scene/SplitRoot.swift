//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import AppDesign
import AppRouting

/// `NavigationSplitView`-based root used on iPad (regular width), macOS, and visionOS.
///
/// Shares the `Router<MainRouting>.activeSelectable` selection state with
/// `PhoneTabRoot`, so the user's selected item persists across iPad compact↔regular
/// layout transitions.
///
struct SplitRoot: View {

    @Environment(Router<MainRouting>.self) private var router

    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        @Bindable var router = router

        NavigationSplitView(columnVisibility: $columnVisibility) {
            Sidebar(selection: $router.activeSelectable)
        } detail: {
            detail(for: router.activeSelectable)
        }
    }

    @ViewBuilder
    private func detail(for selectable: MainRouting.Selectable) -> some View {
        switch selectable {
        case .overview: OverviewScreen()
        case .entries: EntriesScreen()
        case .statistics: StatisticsScreen()
        case .goals: GoalsScreen()
        case .settings:
            // macOS hosts settings in the native window (⌘,) and omits the sidebar item, so this
            // is only reached on iPad (regular width), where the in-app screen is shown.
            #if os(macOS)
            OverviewScreen()
            #else
            NavigationStack {
                SettingsScreen()
                    .mainPushableDestinations()
            }
            #endif
        }
    }
}

// MARK: - Preview

#Preview {
    SplitRoot()
        .appEnvironment(.mock())
}
