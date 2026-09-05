# Apple Music Deduplicator

A native macOS utility for finding songs that appear in more than one selected Apple Music playlist and removing only the playlist entries you choose.

## Attribution

This project was created with OpenAI Codex from requirements, review, and testing feedback provided by Hunter. It should not be represented as a hand-written project authored entirely without AI assistance.

## Design Choices

- Songs are matched by Music's `database ID`, which Apple documents as the shared unique ID when tracks in different playlists point to the same library item.
- The app scans user playlists and excludes playlist folders from selection.
- Smart, Genius, and system playlists can be scanned, but removal controls are locked when Music does not allow direct edits.
- Applying removals deletes playlist entries only. It does not delete tracks from your Apple Music library.

## Audition Songs

After scanning playlists, click **Play** beside a duplicate song to play it through Music. Music is asked to play that song once and then stop. Use **Pause Music** in the toolbar to pause whatever is currently playing in Music. Playback uses Music's volume and audio output, and works for songs in locked playlists too.

Songs streamed from Apple Music may take a few seconds to buffer before audio starts. They must also be playable directly in Music with your current account.

## Build

Build and launch the app through the project entrypoint:

```sh
./script/build_and_run.sh
```

The script updates missing or older icon sizes from the approved 1024-pixel asset, builds the Debug app, refreshes its macOS registration, and launches that exact app bundle. The registration refresh helps macOS pick up icon changes when rebuilding at the same path. The source icon is `Sources/AppleMusicDeduplicator/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png`.

Build the application:

```sh
xcodebuild build -project AppleMusicDeduplicator.xcodeproj -scheme AppleMusicDeduplicator -destination 'platform=macOS' -derivedDataPath DerivedData
```

Run the unit tests:

```sh
xcodebuild test -project AppleMusicDeduplicator.xcodeproj -scheme AppleMusicDeduplicator -destination 'platform=macOS' -derivedDataPath DerivedData
```

The live playback regression test is skipped by default. To run it, set `TEST_RUNNER_AMD_RUN_LIVE_PLAYBACK_TEST=1` before the test command above. It plays a different song from your Music library, verifies that Music switches to that song and its playback position advances, then pauses Music. It requires Music access and a playable song in the library.

Alternatively, open `AppleMusicDeduplicator.xcodeproj` in Xcode. Press Command-B to build or Command-R to build and run the `AppleMusicDeduplicator` scheme.

The first scan will trigger macOS Automation permission for Music. If access is denied, enable it in System Settings > Privacy & Security > Automation.
