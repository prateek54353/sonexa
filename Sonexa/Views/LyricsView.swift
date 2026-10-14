import SwiftUI

struct LyricsView: View {
    @EnvironmentObject var playbackEngine: PlaybackEngine
    @EnvironmentObject var lyricsManager: LyricsManager
    @State private var isEditing: Bool = false
    @State private var editedLyrics: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isEditing {
                    editingView
                } else {
                    displayView
                }
            }
            .navigationTitle("Lyrics")
            .background(Colors.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if isEditing {
                            saveEdits()
                        } else {
                            startEditing()
                        }
                    }) {
                        Text(isEditing ? "Save" : "Edit")
                    }
                }
            }
            .onAppear {
                loadLyrics()
            }
        }
    }
    
    private var displayView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let syncedLyrics = lyricsManager.parsedLyrics() {
                    syncedLyricsView(syncedLyrics)
                } else if let plainLyrics = lyricsManager.plainLyrics() {
                    plainLyricsView(plainLyrics)
                } else if lyricsManager.isLoading {
                    ProgressView("Loading lyrics...")
                        .foregroundColor(Colors.secondaryText)
                } else if let error = lyricsManager.errorMessage {
                    Text(error)
                        .foregroundColor(Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    Text("No lyrics available")
                        .foregroundColor(Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    private func syncedLyricsView(_ lyrics: [LyricsLine]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            ForEach(lyrics) { line in
                Text(line.text)
                    .font(Typography.body)
                    .foregroundColor(Colors.primaryText)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let track = playbackEngine.currentTrack {
                            let offset = line.startTime
                            playbackEngine.seek(to: offset)
                        }
                    }
            }
        }
    }
    
    private func plainLyricsView(_ lyrics: String) -> some View {
        Text(lyrics)
            .font(Typography.body)
            .foregroundColor(Colors.primaryText)
    }
    
    private var editingView: some View {
        VStack(spacing: 0) {
            TextEditor(text: $editedLyrics)
                .font(Typography.body)
                .foregroundColor(Colors.primaryText)
                .padding()
                .background(Colors.background)
        }
    }
    
    private func loadLyrics() {
        guard let track = playbackEngine.currentTrack else { return }
        
        Task {
            await lyricsManager.fetchLyrics(for: track)
        }
    }
    
    private func startEditing() {
        if let plainLyrics = lyricsManager.plainLyrics() {
            editedLyrics = plainLyrics
        } else if let syncedLyrics = lyricsManager.parsedLyrics() {
            // Convert synced lyrics to plain text for editing
            editedLyrics = syncedLyrics.map { $0.text }.joined(separator: "\n")
        }
        
        isEditing = true
    }
    
    private func saveEdits() {
        guard let track = playbackEngine.currentTrack else { return }
        
        lyricsManager.editLyrics(editedLyrics, for: track)
        isEditing = false
    }
}
