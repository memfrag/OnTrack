//
//  Copyright © 2026 Apparata AB. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog

/// The "Data" settings: export all entries to CSV and import entries from a CSV file.
///
/// Usable inside any `Form` on iOS and macOS. Import reports how many rows were imported,
/// skipped (duplicates), and rejected (invalid).
///
struct DataSettingsSection: View {

    @Environment(WeightRepository.self) private var repository

    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportDocument = CSVDocument(text: "")
    @State private var importResult: CSVImportResult?
    @State private var importError: String?

    var body: some View {
        Section {
            Button {
                exportDocument = CSVDocument(text: repository.exportCSV())
                isExporting = true
            } label: {
                Label("Export CSV", systemImage: "square.and.arrow.up")
            }

            Button {
                isImporting = true
            } label: {
                Label("Import CSV", systemImage: "square.and.arrow.down")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("CSV format: timestamp,weight_kg,source,note")
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "OnTrack-Export"
        ) { result in
            if case .failure(let error) = result {
                Logger.data.error("CSV export failed: \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("Import Complete", isPresented: importCompleteBinding, presenting: importResult) { _ in
            Button("OK") { importResult = nil }
        } message: { result in
            Text("Imported \(result.imported), skipped \(result.skipped) duplicate(s), rejected \(result.rejected) invalid row(s).")
        }
        .alert("Import Failed", isPresented: importErrorBinding) {
            Button("OK") { importError = nil }
        } message: {
            Text(importError ?? "Unknown error")
        }
    }

    private var importCompleteBinding: Binding<Bool> {
        Binding(get: { importResult != nil }, set: { if !$0 { importResult = nil } })
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                importResult = repository.importCSV(text)
            } catch {
                importError = error.localizedDescription
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}
