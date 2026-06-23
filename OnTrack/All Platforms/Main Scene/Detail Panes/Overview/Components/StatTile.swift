//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import AppDesign

/// A compact card showing a labeled metric with an optional secondary line.
///
/// Reused on the Overview and Statistics screens. The optional `trend` tints the
/// secondary line green/red to indicate good/bad movement.
///
struct StatTile: View {

    enum Trend {
        case good
        case bad
        case neutral

        var color: Color {
            switch self {
            case .good: .green
            case .bad: .red
            case .neutral: .secondary
            }
        }
    }

    let title: String
    let value: String
    var caption: String?
    var systemImage: String?
    var trend: Trend = .neutral

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .contentTransition(.numericText())
            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(trend == .neutral ? AnyShapeStyle(.secondary) : AnyShapeStyle(trend.color))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
        StatTile(title: "Trend", value: "72.2 kg", caption: "▼ 1.2 kg / week", systemImage: "chart.line.flattrend.xyaxis", trend: .good)
        StatTile(title: "Lowest", value: "71.8 kg")
        StatTile(title: "Average", value: "72.6 kg", caption: "Last 30 days")
        StatTile(title: "Change", value: "+0.4 kg", caption: "This week", trend: .bad)
    }
    .padding()
}
