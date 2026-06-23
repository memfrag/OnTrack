//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import AppRouting

/// A reusable toolbar button that presents the Add Weight sheet.
///
/// Used from the Overview, Entries, and (on macOS) the sidebar.
///
struct AddWeightToolbarButton: View {

    @Environment(Router<MainRouting>.self) private var router

    var body: some View {
        Button {
            router.presentSheet(.addWeight)
        } label: {
            Label("Add Weight", systemImage: "plus")
        }
    }
}
