//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI

/// The shared legend for the trend chart: a faint dot for raw weight and a line for the trend.
struct ChartLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.secondary.opacity(0.35))
                    .frame(width: 8, height: 8)
                Text("Weight")
            }
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.accentColor)
                    .frame(width: 16, height: 3)
                Text("7-Day Moving Average")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
