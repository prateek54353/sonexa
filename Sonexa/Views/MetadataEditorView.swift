import SwiftUI

struct MetadataEditorView: View {
    let track: Track
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title: String
    @State private var artist: String
    @State private var album: String
    @State private var albumArtist: String
    @State private var genre: String
    @State private var year: String
    @State private var composer: String
    @State private var trackNumber: String
    @State private var totalTracks: String
    @State private var discNumber: String
    @State private var totalDiscs: String
    
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    
    init(track: Track) {
        self.track = track
        _title = State(initialValue: track.title)
        _artist = State(initialValue: track.artist)
        _album = State(initialValue: track.album)
        _albumArtist = State(initialValue: track.albumArtist ?? "")
        _genre = State(initialValue: track.genre ?? "")
        _year = State(initialValue: track.year.map(String.init) ?? "")
        _composer = State(initialValue: track.composer ?? "")
        _trackNumber = State(initialValue: track.trackNumber.map(String.init) ?? "")
        _totalTracks = State(initialValue: track.totalTracks.map(String.init) ?? "")
        _discNumber = State(initialValue: track.discNumber.map(String.init) ?? "")
        _totalDiscs = State(initialValue: track.totalDiscs.map(String.init) ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Title", text: $title)
                    TextField("Artist", text: $artist)
                    TextField("Album", text: $album)
                    TextField("Album Artist", text: $albumArtist)
                }
                
                Section("Details") {
                    TextField("Genre", text: $genre)
                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)
                    TextField("Composer", text: $composer)
                }
                
                Section("Track & Disc") {
                    HStack {
                        TextField("Track #", text: $trackNumber)
                            .keyboardType(.numberPad)
                        TextField("of", text: $totalTracks)
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        TextField("Disc #", text: $discNumber)
                            .keyboardType(.numberPad)
                        TextField("of", text: $totalDiscs)
                            .keyboardType(.numberPad)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(Colors.error)
                    }
                }
                
                Section {
                    Button(action: {
                        saveChanges()
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                            }
                            Text("Save Changes")
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .navigationTitle("Edit Metadata")
            .background(Colors.background)
            .scrollContentBackground(.hidden)
        }
    }
    
    private func saveChanges() {
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                // Update track in memory
                track.title = title
                track.artist = artist
                track.album = album
                track.albumArtist = albumArtist.isEmpty ? nil : albumArtist
                track.genre = genre.isEmpty ? nil : genre
                track.year = Int(year)
                track.composer = composer.isEmpty ? nil : composer
                track.trackNumber = Int(trackNumber)
                track.totalTracks = Int(totalTracks)
                track.discNumber = Int(discNumber)
                track.totalDiscs = Int(totalDiscs)
                
                // TODO: Write to file
                // Note: AVFoundation does not support writing metadata directly
                // This would require a third-party library or custom implementation
                // For now, we'll save the changes to the database only
                
                try modelContext.save()
                
                dismiss()
                
            } catch {
                errorMessage = "Failed to save changes: \(error.localizedDescription)"
            }
            
            isSaving = false
        }
    }
}
