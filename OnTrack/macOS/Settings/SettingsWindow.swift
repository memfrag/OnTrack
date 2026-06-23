//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

#if os(macOS)

import SwiftUI

/// Show settings window by using a SettingsLink SwiftUI view.
struct SettingsWindow: Scene {

    private enum Tabs: Hashable {
        case general
        case data
    }

    var body: some Scene {
        Settings {
            tabs
                // The Settings scene is separate from the main window, so it needs the shared
                // environment injected. `AppEnvironment.default` is the same singleton instance.
                .appEnvironment(.default)
        }
    }

    @ViewBuilder var tabs: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)

            DataSettingsTab()
                .tabItem {
                    Label("Data", systemImage: "tray.and.arrow.up")
                }
                .tag(Tabs.data)
        }
        .frame(width: 420, height: 260)
    }
}

#endif
