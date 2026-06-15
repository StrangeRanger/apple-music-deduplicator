# Apple Music Deduplicator

A native macOS utility for finding songs that appear in more than one selected Apple Music playlist and removing only the playlist entries you choose.

## Attribution

This project was created with OpenAI Codex from requirements, review, and testing feedback provided by Hunter. It should not be represented as a hand-written project authored entirely without AI assistance.

## Design Choices

- Songs are matched by Music's `database ID`, which Apple documents as the shared unique ID when tracks in different playlists point to the same library item.
- The app scans user playlists and excludes playlist folders from selection.
- Smart, Genius, and system playlists can be scanned, but removal controls are locked when Music does not allow direct edits.
- Applying removals deletes playlist entries only. It does not delete tracks from your Apple Music library.

## Build

```sh
tuist generate
xcodebuild test -project AppleMusicDeduplicator.xcodeproj -scheme AppleMusicDeduplicator -destination 'platform=macOS' -derivedDataPath DerivedData
```

Open `AppleMusicDeduplicator.xcodeproj` in Xcode and run the `AppleMusicDeduplicator` scheme.

The first scan will trigger macOS Automation permission for Music. If access is denied, enable it in System Settings > Privacy & Security > Automation.
