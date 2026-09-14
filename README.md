# Apple Music Deduplicator

A native macOS app for finding songs shared across Apple Music playlists and choosing where to keep them. Removals affect playlist entries only; the songs remain in your Music library.

## Requirements

- macOS 14 or later.
- The Music app with playlists in your library.
- Xcode with Swift 6 support to build from source.

## Build and Run

From the repository root:

```sh
./script/build_and_run.sh
```

This builds and launches the Debug app at `DerivedData/Build/Products/Debug/AppleMusicDeduplicator.app`. You can also open `AppleMusicDeduplicator.xcodeproj` in Xcode, select the `AppleMusicDeduplicator` scheme, and press **Command-R**.

Allow the app to control Music when macOS requests Automation access. If access is denied, enable it under **System Settings > Privacy & Security > Automation**, then click **Reload Playlists**. Music opens automatically in the background when needed.

## Review and Remove Duplicates

1. Select at least two playlists in the sidebar. Use **Filter playlists** to find them by name.
2. Click **Scan**, or press **Command-R**, to find songs shared by the selected playlists.
3. Review each song and the playlists containing it. Every **Keep** checkbox starts checked. Clear it for each playlist you want to remove the song from.
4. Use the target button beside a playlist to keep the song only in that editable playlist and any locked playlists. **Keep All** resets all pending choices.
5. Click **Apply Removals** to make the changes in Music. The app shows progress and any failures, then rescans after entries are removed to show remaining duplicates.

At least one playlist must remain checked for each song. Changes take effect when you click **Apply Removals**. Use **Reload Playlists** to refresh the sidebar after changing playlists in Music.

### How Matching Works

- Two entries match when they refer to the same Music library item, identified by its `database ID`. Separate library items with identical titles or other metadata count as different songs.
- A song must appear in at least two selected playlists to appear in the results. Repeated entries within a single playlist alone do not qualify.
- Removing a song from a playlist removes all entries for that library item in that playlist.
- Smart, Genius, and system playlists can be scanned, but their entries are locked against removal. Playlist folders are excluded from selection.

### Listen While Reviewing

Click **Play** beside a song to play it once through Music. **Pause Music** pauses whatever is currently playing. Playback uses Music's volume and audio output and is available for songs in locked playlists.

Streaming songs may take a few seconds to buffer and must be playable in Music with your current account.

## Development

The app and tests are written in Swift 6. The interface uses SwiftUI and Observation, and Music automation uses Foundation Apple events.

Build without launching:

```sh
xcodebuild build \
  -project AppleMusicDeduplicator.xcodeproj \
  -scheme AppleMusicDeduplicator \
  -destination 'platform=macOS' \
  -derivedDataPath DerivedData
```

### Tests

Run the default test suite:

```sh
xcodebuild test \
  -project AppleMusicDeduplicator.xcodeproj \
  -scheme AppleMusicDeduplicator \
  -destination 'platform=macOS' \
  -derivedDataPath DerivedData
```

The suite covers duplicate matching, Music automation, playback, removal behavior, and review state using simulated Music responses. Tests that interact directly with Music are opt-in:

| Environment variable | Live test behavior |
| --- | --- |
| `TEST_RUNNER_AMD_RUN_LIVE_STARTUP_TEST=1` | Quits paused Music, checks automatic startup, and checks reuse of the running app. Skips if Music is playing. |
| `TEST_RUNNER_AMD_RUN_LIVE_PLAYBACK_TEST=1` | Plays a different library song, verifies playback advances, then pauses Music. |
| `TEST_RUNNER_AMD_RUN_LIVE_PLAYLIST_TEST=1` | Creates two temporary playlists, tests scanning and removal, checks that the library song remains, then deletes the temporary playlists. |

Live tests require Automation access; playback and playlist tests also require suitable songs in the library. Pause Music before running the startup test. Enable the tests you want using their environment variables and disable parallel testing. For example, to run all three:

```sh
TEST_RUNNER_AMD_RUN_LIVE_STARTUP_TEST=1 \
TEST_RUNNER_AMD_RUN_LIVE_PLAYBACK_TEST=1 \
TEST_RUNNER_AMD_RUN_LIVE_PLAYLIST_TEST=1 \
xcodebuild test \
  -project AppleMusicDeduplicator.xcodeproj \
  -scheme AppleMusicDeduplicator \
  -destination 'platform=macOS' \
  -parallel-testing-enabled NO \
  -derivedDataPath DerivedData
```

See [CHANGELOG.md](CHANGELOG.md) for release history.

## Attribution

This project was created with OpenAI Codex from requirements, review, and testing feedback provided by Hunter. It should not be represented as a hand-written project authored entirely without AI assistance.
