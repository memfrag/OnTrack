//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import AppRouting

struct MainRouting: Routing {

    // MARK: - Selectable

    /// Views that can be selected, i.e. tabs (iOS) or sidebar items (iPad/macOS).
    ///
    /// - Note: macOS hosts settings in the native Settings window (⌘,), so `settings`
    ///   is not shown in the macOS sidebar — only on iOS.
    nonisolated enum Selectable: SelectableDestination {
        case overview
        case entries
        case statistics
        case goals
        case settings
    }

    // MARK: - Pushable

    /// Views that can be pushed onto a navigation stack.
    nonisolated enum Pushable: PushableDestination {
        /// The full-screen trend chart, reached from Overview.
        case chart

        // MARK: Settings
        case attributions
    }

    // MARK: - Presentable

    /// Views that can be presented, i.e. sheets and other modals.
    nonisolated enum Presentable: PresentableDestination {
        /// Add a new weigh-in.
        case addWeight
        /// Edit an existing entry, identified by its stable id.
        case editEntry(UUID)
        /// Create or edit the active goal.
        case editGoal
    }
}
