//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import SwiftData

/// Lightweight, app-wide bookkeeping about syncing and importing.
///
/// Currently records when the last CSV import happened. Reserved for future
/// Withings / CloudKit sync coordination. CloudKit-compatible.
///
@Model
public final class SyncMetadata {

    /// The last time any sync ran (reserved for future use).
    public var lastSyncDate: Date?

    /// The last time data was successfully imported (e.g. via CSV).
    public var lastImportDate: Date?

    public init(lastSyncDate: Date? = nil, lastImportDate: Date? = nil) {
        self.lastSyncDate = lastSyncDate
        self.lastImportDate = lastImportDate
    }
}
