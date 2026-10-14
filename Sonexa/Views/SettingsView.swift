import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var libraryManager: LibraryManager
    
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
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section {
                TextField("Username", text: $username)
                SecureField("Password", text: $password)
            }
            
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(Colors.error)
                }
            }
            
            Section {
                Button(action: {
                    login()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                        }
                        Text("Connect")
                    }
                }
                .disabled(username.isEmpty || password.isEmpty || isLoading)
            }
        }
        .navigationTitle("Connect Last.fm")
        .background(Colors.background)
        .scrollContentBackground(.hidden)
    }
    
    private func login() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let success = try await LastFmService.shared.authenticate(username: username, password: password)
                
                if success {
                    // TODO: Get session key from service
                    settingsManager.connectLastFm(username: username, sessionKey: "")
                }
            } catch {
                errorMessage = "Authentication failed"
            }
            
            isLoading = false
        }
    }
}
