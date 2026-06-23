//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftData
import AppRouting

/// An application-wide environment container.
///
/// This type centralizes access to shared app state and dependencies that are safe to
/// read from anywhere in the app, such as `AppSettings`. Prefer injecting instances via
/// SwiftUI's `@Environment`.
///
/// Use ``AppEnvironment/shared`` for the process-global environment that is created
/// lazily at launch based on build configuration and the `APP_ENVIRONMENT` process
/// environment variable.
///
/// - Important: Avoid creating your own instances unless you are writing previews or tests.
///
public final class AppEnvironment {

    // MARK: - Properties

    /// Meta router
    @MainActor public let metaRouter: MetaRouter

    /// Application settings used throughout the app.
    public let appSettings: AppSettings

    /// The SwiftData container backing all persisted models. Attach to the view hierarchy
    /// with `.modelContainer(_:)` so `@Query` works in views.
    public let modelContainer: ModelContainer

    /// Centralized owner of all weight-data mutations (add / edit / delete / goal / CSV).
    public let weightRepository: WeightRepository

    /// Auth service
    internal let authService: AuthService

    /// Engineering mode
    internal let engineeringMode: EngineeringMode

    // MARK: - Init

    /// Creates an environment with the provided dependencies.
    ///
    /// - Parameters:
    ///    - metaRouter: The app wide meta router.
    ///    - appSettings: The application settings to expose.
    /// - Note: Use ``live()``/``mock()`` rather than this initializer.
    ///
    internal init(
        metaRouter: MetaRouter,
        appSettings: AppSettings,
        modelContainer: ModelContainer,
        weightRepository: WeightRepository,
        authService: AuthService,
        engineeringMode: EngineeringMode
    ) {
        self.metaRouter = metaRouter
        self.appSettings = appSettings
        self.modelContainer = modelContainer
        self.weightRepository = weightRepository
        self.authService = authService
        self.engineeringMode = engineeringMode
    }
}
