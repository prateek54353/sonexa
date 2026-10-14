import SwiftUI
import UniformTypeIdentifiers

struct FileImporterView: View {
    @EnvironmentObject var libraryManager: LibraryManager
    @State private var isImporting: Bool = false
    
    var body: some View {
        Button(action: {
            isImporting = true
        }) {
            Label("Import Music", systemImage: "square.and.arrow.down")
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [
                .mp3,
                .mpeg4Audio,
                .wav,
                .aiff,
                .audio
            ],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    do {
                        try await libraryManager.importFiles(urls: urls)
                    } catch {
                        print("Import failed: \(error)")
                    }
                }
            case .failure(let error):
                print("File picker failed: \(error)")
            }
        }
    }
}
