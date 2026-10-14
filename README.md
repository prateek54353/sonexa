# Sonexa

A premium, offline-first native iOS music player built with Swift and SwiftUI.

## Features

- **Local Music Playback**: Play MP3, AAC, M4A, ALAC, WAV, AIFF, and FLAC files from your device
- **Full Library Management**: Browse songs, albums, artists, genres, and playlists
- **Advanced Playback Controls**: Play, pause, seek, shuffle, repeat, and queue management
- **Background Playback**: Continue listening while using other apps or when the screen is locked
- **Now Playing Info**: Lock screen and control center integration
- **Lyrics Support**:
  - Embedded lyrics from audio files
  - Local LRC file import
  - Online lyrics from multiple providers (BiniLyrics, Musixmatch, LRCLIB)
  - Synchronized lyrics with karaoke-style display
  - Manual lyrics editing
- **Last.fm Integration**: Account connection, now-playing updates, and scrobbling
- **Animated Artwork**: Apple Music-style animated album artwork when available
- **Metadata Editing**: Edit track information and save to files
- **Playlists**: Create, rename, delete, and manage playlists
- **Favourites**: Mark and browse favourite tracks
- **Search**: Full-library search across songs, albums, and artists
- **Customization**: Dark/light themes, haptics, audio enhancements
- **Offline Operation**: Core features work without internet connection

## Requirements

- iOS 17.0 or later
- Xcode 15.4 or later
- Swift 5.9 or later

## Installation

1. Clone the repository
2. Open `Sonexa.xcodeproj` in Xcode
3. Select a simulator or connected device
4. Build and run (⌘R)

## Project Structure

```
Sonexa/
├── App/                      # Application entry point
│   ├── SonexaApp.swift
│   ├── SceneDelegate.swift
│   └── AppDelegate.swift
├── DesignSystem/             # UI design system
│   └── DesignSystem.swift
├── Models/                   # Data models
│   ├── Track.swift
│   ├── Album.swift
│   ├── Artist.swift
│   ├── Playlist.swift
│   ├── PlaybackQueue.swift
│   ├── Lyrics.swift
│   ├── UserPreferences.swift
│   └── ArtworkCache.swift
├── Services/                 # Business logic
│   ├── PlaybackEngine.swift
│   ├── LibraryManager.swift
│   ├── MetadataReader.swift
│   ├── SettingsManager.swift
│   ├── Lyrics/
│   │   ├── LyricsProvider.swift
│   │   ├── MusixmatchLyricsProvider.swift
│   │   ├── LRCLIBLyricsProvider.swift
│   │   ├── BiniLyricsProvider.swift
│   │   └── LyricsManager.swift
│   ├── LastFm/
│   │   └── LastFmService.swift
│   └── Artwork/
│       └── AnimatedArtworkService.swift
├── Views/                    # SwiftUI views
│   ├── ContentView.swift
│   ├── HomeView.swift
│   ├── LibraryView.swift
│   ├── SearchView.swift
│   ├── SettingsView.swift
│   ├── NowPlayingView.swift
│   ├── LyricsView.swift
│   ├── MetadataEditorView.swift
│   └── FileImporterView.swift
└── Info.plist               # App configuration
```

## Configuration

### Last.fm

To enable Last.fm scrobbling:

1. Obtain an API key and shared secret from [Last.fm API](https://www.last.fm/api/account/create)
2. Configure the credentials in `LastFmService.swift` (replace placeholder values)
3. Connect your account in the Settings screen

**Important**: Do not commit API keys to source control. Use environment variables or secure configuration for production builds.

### Musixmatch

The Musixmatch integration uses the community API wrapper from [Strvm/musicxmatch-api](https://github.com/Strvm/musicxmatch-api). This is a reverse-engineered integration and may be subject to limitations or changes.

The community API key is included in the implementation but should be treated as potentially unreliable. The integration includes proper error handling and fallback to other providers.

### Animated Artwork

Animated artwork is sourced from the [apple-music-animated-artworks](https://github.com/m8tec/apple-music-animated-artworks) service. This feature can be disabled in Settings if preferred.

## Supported File Formats

- MP3
- AAC/M4A
- ALAC (Apple Lossless)
- WAV
- AIFF
- FLAC (when decoder is available)

Note: FLAC support depends on iOS codec availability. Not all devices support FLAC natively.

## Architecture

Sonexa uses MVVM architecture with:

- **SwiftData** for local persistence
- **AVFoundation** for audio playback
- **MediaPlayer** for Now Playing info and remote commands
- **SwiftUI** for the user interface
- **Combine** for reactive state management
- **URLSession** for network requests

### Key Components

- **PlaybackEngine**: Manages audio playback, queue, and controls
- **LibraryManager**: Handles file import, library indexing, and search
- **LyricsManager**: Coordinates lyrics providers and caching
- **MetadataReader**: Reads metadata from audio files
- **SettingsManager**: Manages user preferences and app settings

## Testing

Run tests in Xcode with ⌘U or use:

```bash
xcodebuild test -scheme Sonexa -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Known Limitations

1. **Metadata Writing**: AVFoundation does not support writing metadata directly to audio files. The current implementation saves metadata changes to the database only. Full file writing would require a third-party library or custom implementation.

2. **FLAC Support**: FLAC codec availability varies by device. The app attempts to play FLAC files but may fail on unsupported devices.

3. **BiniLyrics**: The BiniLyrics API requires further investigation. The current implementation is a placeholder that falls back to other providers.

4. **Folder Selection**: iOS file picker limitations prevent full folder selection on all iOS versions. Individual file selection is always supported.

5. **Beat Detection Haptics**: Reliable beat detection without degrading playback performance is challenging. The current implementation focuses on interaction haptics.

6. **Spatial Audio**: True spatial audio requires specific hardware and capabilities not available to all third-party apps. The implementation includes supported audio enhancements where technically feasible.

## Privacy

- Sonexa does not upload your music files to any online service
- Lyrics providers receive only track metadata (title, artist, album) for lookup
- Credentials are stored securely in the device Keychain
- No user analytics or tracking

## License

This project includes code from:

- [Strvm/musicxmatch-api](https://github.com/Strvm/musicxmatch-api) - MIT License
- [apple-music-animated-artworks](https://github.com/m8tec/apple-music-animated-artworks) - See repository for terms

The main Sonexa codebase is provided as-is for educational and personal use.

## Contributing

This is a complete implementation task. The codebase is organized for maintainability and extensibility. Consider the following when making changes:

1. Follow existing code style and patterns
2. Update tests when adding features
3. Document external API dependencies
4. Test on multiple iOS versions where applicable
5. Preserve offline functionality

## GitHub Actions

Sonexa includes GitHub Actions workflows for automated building and testing. You can trigger these workflows manually from the GitHub website without needing a local macOS environment.

### Available Workflows

1. **Build and Test** (`.github/workflows/build.yml`)
   - Manual trigger with customizable options
   - Builds the project for selected simulator
   - Runs tests (optional)
   - Uploads build archive as artifact
   - Uploads build logs on failure

2. **Run Tests** (`.github/workflows/test.yml`)
   - Manual trigger or automatic on push/PR
   - Runs unit tests on selected simulator
   - Generates test summary

3. **Code Quality Check** (`.github/workflows/lint.yml`)
   - Manual trigger or automatic on push/PR
   - Runs SwiftLint for code quality
   - Runs SwiftFormat for code formatting check

### Triggering Workflows from GitHub

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. Select the workflow you want to run (e.g., "Build and Test Sonexa")
4. Click **Run workflow**
5. Configure the options:
   - **Run tests**: Toggle to enable/disable tests
   - **Clean build**: Toggle to clean build folder
   - **Destination**: Choose simulator (iPhone 15, iPhone 15 Pro, iPad, etc.)
6. Click **Run workflow**

### Workflow Options

**Build and Test Workflow:**
- `run_tests`: Run unit tests after build (default: true)
- `clean_build`: Clean build folder before building (default: false)
- `destination`: Target simulator (default: iPhone 15)

**Test Workflow:**
- `destination`: Target simulator for tests (default: iPhone 15)

### Downloading Build Artifacts

After a successful build:
1. Go to the Actions tab
2. Click on the completed workflow run
3. Scroll to the **Artifacts** section
4. Download the `Sonexa-Archive` artifact

### CI/CD Configuration

The workflows use:
- **macOS 14** runner with Xcode 15.4
- **Code signing disabled** for CI builds
- **Debug configuration** by default
- **Multiple simulator destinations** supported

## Local Build Verification

To verify the build locally on macOS:

```bash
# Clean build folder
xcodebuild clean -scheme Sonexa

# Build for simulator
xcodebuild build -scheme Sonexa -destination 'platform=iOS Simulator,name=iPhone 15'

# Run tests
xcodebuild test -scheme Sonexa -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Troubleshooting

### Build Errors

- Ensure Xcode 15.4 or later is installed
- Verify iOS deployment target is 17.0
- Check that all Swift files are included in the project

### Playback Issues

- Verify file permissions and security-scoped access
- Check audio session configuration
- Ensure background audio capability is enabled
- Test with different file formats

### Lyrics Not Loading

- Check network connectivity
- Verify provider configuration in Settings
- Check provider service status
- Try manual provider selection

## Roadmap

Potential future enhancements:

- Enhanced metadata writing with third-party library integration
- Improved FLAC support across all devices
- BiniLyrics API implementation (pending investigation)
- Advanced visualizations
- Equalizer presets
- Playlist import/export (M3U, PLS)
- Cloud sync for playlists and preferences
- Additional lyrics providers
- Advanced haptic patterns

## Support

For issues, questions, or contributions, please refer to the project documentation or create an issue in the repository.
