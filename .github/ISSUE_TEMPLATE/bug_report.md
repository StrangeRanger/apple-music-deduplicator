---
name: Bug report
about: Report a problem with Apple Music Deduplicator.
title: ""
labels: ""
assignees: ""
---

<!-- Search existing issues before submitting. Replace the prompts below with your answers. -->

## What happened?

Describe the problem and which part of the app is affected: launching, loading playlists, scanning, reviewing Keep choices, playback, applying removals, or verifying results.

## Steps to reproduce

1.
2.
3.

## Expected and actual behavior

**Expected:**

**Actual:**

**Frequency:** Always / Sometimes / Once

## Environment

- Apple Music Deduplicator version and build (or Git commit):
- macOS version:
- Music app version:
- Installation method: Built in Xcode / Build-and-run script / Other
- For build problems, Xcode version and failing command:
- Music state when the problem occurred: Closed / Open and paused / Playing
- Automation access to Music: Allowed / Denied / Not prompted / Unsure

## Playlist and song context

<!-- Complete what applies; approximate counts and anonymized names are fine. -->

- Number of selected playlists and approximate songs per playlist:
- Playlist types involved: Regular / Smart / Genius / System
- Song source, if relevant: Local file / Apple Music streaming / Downloaded / Other
- Were playlists changed in Music during the operation?

<!--
For matching problems: the app matches the same Music library item by database ID
across at least two selected playlists. Separate library items with identical
metadata do not match; repetitions in just one playlist do not qualify.

For removal problems: describe the Keep choices, which playlist entries you
expected to remove, what remained in Music, and the result of the automatic
rescan. Removing an item removes all its entries in that playlist; the library
song should remain. Smart, Genius, and system playlists are locked for removal.
-->

## Error messages and supporting details

Paste the exact error text (including any OSStatus code), relevant logs, or screenshots. For removal failures, include the progress/failure details and whether the problem occurred during removal or the subsequent verification.

<!-- Remove personal information from logs and screenshots before sharing. -->
