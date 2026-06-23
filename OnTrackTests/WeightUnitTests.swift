//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import Testing
import Foundation
@testable import OnTrack

struct WeightUnitTests {

    @Test func kilogramsAreIdentity() {
        #expect(WeightUnit.kg.value(fromKg: 72.4) == 72.4)
        #expect(WeightUnit.kg.kg(fromValue: 72.4) == 72.4)
    }

    @Test func poundConversionRoundTrips() {
        let kg = 72.4
        let lb = WeightUnit.lb.value(fromKg: kg)
        let backToKg = WeightUnit.lb.kg(fromValue: lb)
        #expect(abs(backToKg - kg) < 0.0000001)
    }

    @Test func knownPoundConversion() {
        // 100 kg ≈ 220.462 lb
        let lb = WeightUnit.lb.value(fromKg: 100)
        #expect(abs(lb - 220.462) < 0.01)
    }

    @Test func displayValueRoundsToOneDecimal() {
        // 72.46 kg → displayed as 72.5 kg
        #expect(WeightUnit.kg.displayValue(fromKg: 72.46) == 72.5)
        #expect(WeightUnit.kg.formatted(fromKg: 72.4) == "72.4")
    }

    @Test func formattedWithSymbolIncludesUnit() {
        #expect(WeightUnit.kg.formattedWithSymbol(fromKg: 72.4) == "72.4 kg")
    }

    @Test func deltaFormattingShowsSign() {
        #expect(WeightUnit.kg.formattedDeltaWithSymbol(fromKg: -1.2) == "-1.2 kg")
        #expect(WeightUnit.kg.formattedDeltaWithSymbol(fromKg: 0.4) == "+0.4 kg")
    }
}
