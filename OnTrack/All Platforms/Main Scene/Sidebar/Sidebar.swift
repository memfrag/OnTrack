//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// Sidebar list backing `SplitRoot`'s NavigationSplitView leading column.
///
/// Selection drives the detail column via the shared
/// `Router<MainRouting>.activeSelectable` binding.
///
struct Sidebar: View {

    @Binding var selection: MainRouting.Selectable

    private var items: [(MainRouting.Selectable, String, String)] {
        var items: [(MainRouting.Selectable, String, String)] = [
            (.overview, "Overview", "chart.line.uptrend.xyaxis"),
            (.entries, "Entries", "list.bullet"),
            (.statistics, "Statistics", "chart.bar"),
            (.goals, "Goals", "target")
        ]
        // macOS hosts settings in the native Settings window (⌘,); iPad shows it in the sidebar.
        #if !os(macOS)
        items.append((.settings, "Settings", "gearshape"))
        #endif
        return items
    }

    var body: some View {
        List(selection: Binding(
            get: { Optional(selection) },
            set: { if let new = $0 { selection = new } }
        )) {
            ForEach(items, id: \.0) { item in
                NavigationLink(value: item.0) {
                    Label(item.1, systemImage: item.2)
                }
            }
        }
        .navigationTitle(Bundle.main.appName)
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        .safeAreaInset(edge: .bottom) {
            SidebarSummary()
        }
        #endif
    }
}

private extension Bundle {
    var appName: String {
        (object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? "App"
    }
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        Sidebar(selection: .constant(.overview))
    } detail: {
        Text("Detail")
    }
    .appEnvironment(.mock())
}
