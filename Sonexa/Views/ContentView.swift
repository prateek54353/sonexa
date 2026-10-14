import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var playbackEngine: PlaybackEngine
    @EnvironmentObject var libraryManager: LibraryManager
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State private var selectedTab: MainTab = .home
    
    enum MainTab: String, CaseIterable {
        case home = "Home"
        case library = "Library"
        case search = "Search"
        case settings = "Settings"
        
        var systemImage: String {
            switch self {
            case .home: return "house.fill"
            case .library: return "music.note.list"
            case .search: return "magnifyingglass"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(MainTab.home.rawValue, systemImage: MainTab.home.systemImage)
                }
                .tag(MainTab.home)
            
            LibraryView()
                .tabItem {
                    Label(MainTab.library.rawValue, systemImage: MainTab.library.systemImage)
                }
                .tag(MainTab.library)
            
            SearchView()
                .tabItem {
                    Label(MainTab.search.rawValue, systemImage: MainTab.search.systemImage)
                }
                .tag(MainTab.search)
            
            SettingsView()
                .tabItem {
                    Label(MainTab.settings.rawValue, systemImage: MainTab.settings.systemImage)
                }
                .tag(MainTab.settings)
        }
        .onAppear {
            setupManagers()
        }
        .overlay(alignment: .bottom) {
            if playbackEngine.currentTrack != nil {
                MiniPlayer()
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.lg)
            }
        }
    }
    
    private func setupManagers() {
        libraryManager.setModelContext(modelContext)
        settingsManager.setModelContext(modelContext)
        LyricsManager.shared.setModelContext(modelContext)
        AnimatedArtworkService.shared.setModelContext(modelContext)
    }
}
