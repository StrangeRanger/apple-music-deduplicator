# Changelog

Notable changes to Apple Music Deduplicator are recorded here by version.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and version numbers follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

History through 1.1.1 was reconstructed from Git commits. No Git tags or GitHub releases were available, so dates identify commit-based version milestones rather than verified publication dates.

## [Unreleased]

## [1.1.1] - 2026-09-05

macOS build: 4.

### Changed

- Read track IDs and song metadata from Music in bulk to reduce per-track automation calls during duplicate scans and post-removal verification.
- Identify duplicate IDs before requesting song metadata, fetch metadata only from the playlists needed to describe those duplicates, and retain only the duplicate details between batches.
- Group integer track IDs by playlist instead of building a metadata record for every playlist entry.

### Fixed

- Report incomplete metadata responses and detected playlist ID or ordering changes during metadata loading as scan errors requiring a rescan.

## [1.1.0] - 2026-06-21

macOS build: 3.

### Added

- A dedicated post-removal verification state showing when the app is checking playlists again and how many duplicate songs remain.
- A build-and-run script with debugger, log streaming, and launch-verification options.

### Changed

- Group removal requests by playlist and index each affected playlist's tracks once, avoiding repeated full-playlist reads for each removal.
- Adopt Swift Observation and split the playlist sidebar and duplicate review into separate view components.

### Fixed

- Disable playlist selection and review changes while loading, scanning, removing entries, or verifying results.
- Clear stale duplicate results and keep selections when reloading playlists or starting a new scan.
- Preserve the playlist selection associated with an operation and discard scan results if that selection no longer matches.
- Distinguish successful removals followed by a failed refresh from removal failures, clear stale results after either failure, and indicate when a rescan is required.
- Ignore late removal-progress updates after the removal phase has finished.

## [1.0.0] - 2026-06-20

macOS build: 1. This entry groups initial development from June 15 through June 20, 2026, before the changes included in 1.1.0.

### Added

- A native macOS app for finding songs shared by two or more selected Apple Music playlists, using Music's database IDs to match library items.
- A playlist browser with filtering, track counts, playlist types, and multiple selection.
- Duplicate review with song details, per-playlist keep choices, a Keep All reset, and a shortcut to keep a song in one editable playlist while retaining locked occurrences.
- Removal of selected playlist entries, with progress, failure details, and an automatic rescan after entries are removed.
- Scanning of Smart, Genius, and system playlists with removal controls locked for noneditable playlists; playlist folders are excluded from selection.
- Music Automation permission guidance and unit tests for duplicate detection and removal selection.

### Changed

- Use the checked-in Xcode project with generated Info.plist files for building and running the app directly in Xcode or with `xcodebuild`.
- Enable App Sandbox and configure Music scripting permissions; disable incoming and outgoing network access and unused resource permissions in the project settings.

### Removed

- The Tuist project-generation dependency, configuration files, and generated workspace.
