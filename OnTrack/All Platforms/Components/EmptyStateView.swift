//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// A friendly empty-state placeholder with an optional call-to-action.
///
/// Used across Overview, Entries, Statistics, and Goals when there is no data to show.
/// Built on `ContentUnavailableView` for native styling and accessibility.
///
struct EmptyStateView: View {

    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EmptyStateView(
        title: "No Entries Yet",
        message: "Add your first weight to start tracking your trend.",
        systemImage: "list.bullet.clipboard",
        actionTitle: "Add Weight"
    ) {}
}
