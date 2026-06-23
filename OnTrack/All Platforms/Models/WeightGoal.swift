//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation
import SwiftData

/// The user's single active weight goal.
///
/// A goal can be in either direction: `targetWeightKg` may be below the start weight
/// (weight loss) or above it (weight gain). The direction is inferred from
/// `startWeightKg` versus `targetWeightKg`. Editing replaces the active goal; there is
/// no goal history.
///
/// All weights are stored in kilograms. CloudKit-compatible (defaulted/optional properties,
/// no uniqueness constraints).
///
@Model
public final class WeightGoal {

    /// The weight the user wants to reach, in kilograms.
    public var targetWeightKg: Double = 0

    /// An optional date by which the user hopes to reach the target.
    public var targetDate: Date?

    /// The user's weight, in kilograms, when the goal was created. Used to compute progress.
    public var startWeightKg: Double = 0

    /// When the goal period started.
    public var startDate: Date = Date.now

    /// When the goal record was created.
    public var createdAt: Date = Date.now

    public init(
        targetWeightKg: Double,
        targetDate: Date? = nil,
        startWeightKg: Double,
        startDate: Date = .now,
        createdAt: Date = .now
    ) {
        self.targetWeightKg = targetWeightKg
        self.targetDate = targetDate
        self.startWeightKg = startWeightKg
        self.startDate = startDate
        self.createdAt = createdAt
    }

    /// Whether the goal represents weight loss (`true`) or weight gain (`false`).
    /// A goal with equal start and target is treated as loss by convention.
    public var isLoss: Bool {
        targetWeightKg <= startWeightKg
    }

    /// The total weight change required to go from start to target, in kilograms (always ≥ 0).
    public var totalChangeKg: Double {
        abs(startWeightKg - targetWeightKg)
    }

    /// Fraction of the goal completed for a given current weight, clamped to `0...1`.
    ///
    /// - Parameter currentWeightKg: The current (typically trend) weight in kilograms.
    /// - Returns: Progress in the range `0...1`. Returns `1` when start equals target.
    ///
    public func progress(currentWeightKg: Double) -> Double {
        guard totalChangeKg > 0 else { return 1 }
        let achieved = abs(startWeightKg - currentWeightKg)
        return min(max(achieved / totalChangeKg, 0), 1)
    }

    /// The remaining weight change to reach the target from a current weight, in kilograms.
    /// Positive means there is still distance to go; `0` or negative means reached/passed.
    ///
    /// - Parameter currentWeightKg: The current (typically trend) weight in kilograms.
    ///
    public func remainingKg(currentWeightKg: Double) -> Double {
        if isLoss {
            return max(currentWeightKg - targetWeightKg, 0)
        } else {
            return max(targetWeightKg - currentWeightKg, 0)
        }
    }
}
