//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

#if os(macOS)

import SwiftUI

/// The Data tab of the macOS Settings window: CSV export and import.
struct DataSettingsTab: View {
    var body: some View {
        Form {
            DataSettingsSection()
        }
        .formStyle(.grouped)
        .padding(20)
    }
}

#Preview {
    DataSettingsTab()
        .appEnvironment(.mock())
}

#endif
