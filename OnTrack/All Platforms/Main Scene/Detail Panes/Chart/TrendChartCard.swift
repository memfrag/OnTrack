//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import AppRouting

/// A compact trend-chart card embedded on the Overview, tappable to open the full chart.
struct TrendChartCard: View {

    let entries: [WeightEntry]
    let unit: WeightUnit

    @Environment(Router<MainRouting>.self) private var router

    private var series: ChartSeries {
        ChartSeries(entries: entries, range: .quarter)
    }

    var body: some View {
        Button {
            router.push(.chart)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Weight Chart")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                ChartLegend()
                TrendChartView(series: series, unit: unit)
                    .frame(height: 160)
            }
            .padding(16)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
