//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Foundation

/// The unit used to display and enter weights.
///
/// Weights are always *stored* in kilograms at full precision; this type converts
/// to and from the user's chosen display unit. Displayed values are rounded to one
/// decimal place, but the underlying stored kilograms are never mutated by viewing in
/// another unit.
///
public enum WeightUnit: String, Codable, CaseIterable, Sendable, Identifiable {

    case kg
    case lb

    public var id: Self { self }

    /// Kilograms per pound.
    private static let kgPerLb = 0.45359237

    /// The unit's abbreviation, e.g. `"kg"` or `"lb"`.
    public var symbol: String {
        switch self {
        case .kg: "kg"
        case .lb: "lb"
        }
    }

    /// A display label for pickers.
    public var label: String {
        switch self {
        case .kg: "Kilograms (kg)"
        case .lb: "Pounds (lb)"
        }
    }

    /// Converts a canonical kilogram value into this unit's value (unrounded).
    public func value(fromKg kg: Double) -> Double {
        switch self {
        case .kg: kg
        case .lb: kg / Self.kgPerLb
        }
    }

    /// Converts a value expressed in this unit back into canonical kilograms.
    public func kg(fromValue value: Double) -> Double {
        switch self {
        case .kg: value
        case .lb: value * Self.kgPerLb
        }
    }

    /// The display value for a kilogram amount, rounded to one decimal place in this unit.
    public func displayValue(fromKg kg: Double) -> Double {
        (value(fromKg: kg) * 10).rounded() / 10
    }

    /// A formatted string for a kilogram amount, e.g. `"72.4"` (no unit symbol).
    public func formatted(fromKg kg: Double) -> String {
        String(format: "%.1f", displayValue(fromKg: kg))
    }

    /// A formatted string including the unit symbol, e.g. `"72.4 kg"`.
    public func formattedWithSymbol(fromKg kg: Double) -> String {
        "\(formatted(fromKg: kg)) \(symbol)"
    }

    /// A formatted signed delta including the unit symbol, e.g. `"-1.2 kg"` / `"+0.4 lb"`.
    ///
    /// The delta is provided in kilograms and converted (not rounded-then-subtracted) so
    /// the sign reflects the true change.
    public func formattedDeltaWithSymbol(fromKg deltaKg: Double) -> String {
        let value = value(fromKg: deltaKg)
        let rounded = (value * 10).rounded() / 10
        let sign = rounded > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", rounded)) \(symbol)"
    }
}
