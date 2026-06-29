//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import SwiftData
import AppRouting

extension AppEnvironment {

    // MARK: - Mock AppEnvironment

    /// Builds a mock environment configured for development and preview usage.
    ///
    /// Available in all configurations because `#Preview` bodies compile into Release builds too.
    ///
    /// - Returns: A new ``AppEnvironment`` instance with mocked dependencies.
    ///
    internal static func mock() -> AppEnvironment {
        let modelContainer = ModelContainer.makeMock()
        return AppEnvironment(
            metaRouter: MetaRouter(tree: appRoutingTree),
            appSettings: AppSettings.mock(),
            modelContainer: modelContainer,
            weightRepository: WeightRepository(modelContext: modelContainer.mainContext),
            authService: AuthService.mock(),
            engineeringMode: EngineeringMode.shared
        )
    }
}
