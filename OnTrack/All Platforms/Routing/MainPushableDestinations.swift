//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import AppRouting

extension View {

    /// Installs the app's shared pushable-destination handler on a navigation stack.
    ///
    /// Several tabs can push the same destinations (e.g. the full-screen chart or the
    /// attributions screen), so the mapping from `MainRouting.Pushable` to a view lives in
    /// one place rather than being duplicated per screen.
    ///
    func mainPushableDestinations() -> some View {
        pushableDestination(for: MainRouting.self) { destination in
            switch destination {
            case .chart:
                ChartScreen()
            case .attributions:
                OpenSourceAttributions()
            }
        }
    }
}
