//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

#if os(iOS)

import SwiftUI
import AppDesign
import AppRouting

/// `TabView`-based root used on iPhone and on iPad in compact horizontal size class.
struct PhoneTabRoot: View {

    @Environment(Router<MainRouting>.self) private var router

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.activeSelectable) {
            Tab("Overview", systemImage: "chart.line.uptrend.xyaxis", value: .overview) {
                OverviewScreen()
            }
            Tab("Entries", systemImage: "list.bullet", value: .entries) {
                EntriesScreen()
            }
            Tab("Statistics", systemImage: "chart.bar", value: .statistics) {
                StatisticsScreen()
            }
            Tab("Goals", systemImage: "target", value: .goals) {
                GoalsScreen()
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                NavigationStack(path: $router[.settings]) {
                    SettingsScreen()
                        .mainPushableDestinations()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PhoneTabRoot()
        .appEnvironment(.mock())
}

#endif
