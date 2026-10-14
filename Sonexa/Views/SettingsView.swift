import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var libraryManager: LibraryManager
    @State private var isSelectingFolder: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                // Appearance
                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { settingsManager.currentTheme },
                        set: { settingsManager.setTheme($0) }
                    )) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                }
                
                // Audio
                Section("Audio") {
                    Toggle("Haptics", isOn: Binding(
                        get: { settingsManager.hapticsEnabled },
                        set: { settingsManager.setHapticsEnabled($0) }
                    ))
                    
                    Toggle("Animated Artwork", isOn: Binding(
                        get: { settingsManager.animatedArtworkEnabled },
                        set: { settingsManager.setAnimatedArtworkEnabled($0) }
                    ))
                }
                
                // Lyrics
                Section("Lyrics") {
                    Toggle("Auto-fetch Lyrics", isOn: Binding(
                        get: { settingsManager.autoFetchLyrics },
                        set: { settingsManager.setAutoFetchLyrics($0) }
                    ))
                    
                    NavigationLink {
                        LyricsProviderSettingsView()
                    } label: {
                        Text("Lyrics Providers")
                    }
                }
                
                // Last.fm
                Section("Last.fm") {
                    if settingsManager.lastFmConnected {
                        HStack {
                            Text("Connected as")
                            Spacer()
                            Text(settingsManager.lastFmCredentials?.username ?? "")
                                .foregroundColor(Colors.secondaryText)
                        }
                        
                        Button("Disconnect") {
                            settingsManager.disconnectLastFm()
                        }
                    } else {
                        NavigationLink {
                            LastFmLoginView()
                        } label: {
                            Text("Connect Last.fm")
                        }
                    }
                    
                    Toggle("Scrobbling", isOn: Binding(
                        get: { settingsManager.scrobbleEnabled },
                        set: { settingsManager.setScrobbleEnabled($0) }
                    ))
                }
                
                // Library
                Section("Library") {
                    Toggle("Auto-import from Folder", isOn: Binding(
                        get: { settingsManager.autoImportFolderEnabled },
                        set: { settingsManager.setAutoImportFolderEnabled($0) }
                    ))
                    
                    if settingsManager.autoImportFolderEnabled {
                        Button(settingsManager.autoImportFolderBookmark != nil ? "Change Folder" : "Select Folder") {
                            isSelectingFolder = true
                        }
                        
                        if settingsManager.autoImportFolderBookmark != nil {
                            Button("Clear Folder") {
                                settingsManager.clearAutoImportFolder()
                            }
                            .foregroundColor(Colors.error)
                        }
                    }
                    
                    Button("Rescan Library") {
                        Task {
                            try? await libraryManager.rescanLibrary()
                        }
                    }
                    
                    Button("Clear Library") {
                        libraryManager.clearLibrary()
                    }
                    .foregroundColor(Colors.error)
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(Colors.secondaryText)
                    }
                }
            }
            .navigationTitle("Settings")
            .background(Colors.background)
            .scrollContentBackground(.hidden)
            .fileImporter(
                isPresented: $isSelectingFolder,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        settingsManager.setAutoImportFolder(url: url)
                    }
                case .failure(let error):
                    print("Folder selection failed: \(error)")
                }
            }
        }
    }
}

struct LyricsProviderSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        List {
            Section("Provider Order") {
                ForEach(settingsManager.lyricsProviderOrder, id: \.self) { provider in
                    HStack {
                        Text(provider.capitalized)
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(Colors.secondaryText)
                    }
                }
            }
            
            Section("Providers") {
                Text("BiniLyrics")
                Text("Musixmatch")
                Text("LRCLIB")
            }
        }
        .navigationTitle("Lyrics Providers")
        .background(Colors.background)
        .scrollContentBackground(.hidden)
    }
}

struct LastFmLoginView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.openURL) private var openURL
    @State private var isLoading: Bool = false
    @State private var authorizationStarted: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section {
                Text("Connect Sonexa to Last.fm in your browser. After granting access, return here to finish connecting.")
                    .foregroundColor(Colors.secondaryText)
            }
            
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(Colors.error)
                }
            }
            
            Section {
                Button {
                    if authorizationStarted {
                        finishAuthorization()
                    } else {
                        startAuthorization()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                        }
                        Text(authorizationStarted ? "I Authorized Sonexa" : "Authorize with Last.fm")
                    }
                }
                .disabled(isLoading)
            }
        }
        .navigationTitle("Connect Last.fm")
        .background(Colors.background)
        .scrollContentBackground(.hidden)
    }
    
    private func startAuthorization() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let url = try await LastFmService.shared.beginAuthentication()
                authorizationStarted = true
                openURL(url)
            } catch {
                errorMessage = message(for: error)
            }
            isLoading = false
        }
    }

    private func finishAuthorization() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let session = try await LastFmService.shared.completeAuthentication()
                settingsManager.connectLastFm(username: session.username, sessionKey: session.sessionKey)
            } catch {
                errorMessage = "Last.fm has not authorized the app yet. Complete the browser prompt and try again."
            }
            isLoading = false
        }
    }

    private func message(for error: Error) -> String {
        if case LastFmError.missingConfiguration = error {
            return "Add LastFmAPIKey and LastFmSharedSecret to the app configuration before connecting."
        }
        return "Could not start Last.fm authorization."
    }
}
