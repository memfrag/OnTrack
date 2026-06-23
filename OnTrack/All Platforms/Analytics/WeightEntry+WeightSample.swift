//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// `WeightEntry` already exposes `timestamp` and `weightKg`, so it satisfies ``WeightSample``
/// directly. This lets the pure ``AnalyticsEngine`` operate on persisted entries without
/// depending on SwiftData.
extension WeightEntry: WeightSample {}
