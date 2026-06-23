//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// The origin of a ``WeightEntry``.
///
/// Stored on disk as its `rawValue` `String` so the model stays CloudKit-compatible
/// (CloudKit has no native enum support).
///
public enum EntrySource: String, Codable, CaseIterable, Sendable {

    /// Entered by hand by the user.
    case manual

    /// Imported from a Withings smart scale (reserved for a future sync feature).
    case withings

    /// A short, human-readable label suitable for display in lists and tables.
    public var label: String {
        switch self {
        case .manual: "Manual"
        case .withings: "Withings"
        }
    }

    /// An SF Symbol name representing the source.
    public var systemImage: String {
        switch self {
        case .manual: "hand.point.up.left"
        case .withings: "scalemass"
        }
    }
}
